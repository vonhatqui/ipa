import Foundation
import SwiftUI
import UIKit
#if canImport(Darwin)
import Darwin
#endif

// MARK: - Local Embedded HTTP Server for MobileConfig Delivery
final class AntibanLocalServer {
    static let shared = AntibanLocalServer()
    private var listeningSocket: Int32 = -1
    private var isRunning = false
    private let serverQueue = DispatchQueue(label: "vn.applestorevn.antiban.localserver", qos: .userInitiated)
    let port: UInt16 = 28085

    private init() {}

    func start(profileData: Data) {
        serverQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isRunning {
                self.stop()
            }
            self.runServer(profileData: profileData)
        }
    }

    func stop() {
        isRunning = false
        #if canImport(Darwin)
        if listeningSocket >= 0 {
            close(listeningSocket)
            listeningSocket = -1
        }
        #endif
    }

    private func runServer(profileData: Data) {
        #if canImport(Darwin)
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else {
            print("[AntibanServer] Failed to create socket")
            return
        }
        self.listeningSocket = sock

        var reuse: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(sock, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            print("[AntibanServer] Failed to bind socket on port \(port), errno: \(errno)")
            close(sock)
            self.listeningSocket = -1
            return
        }

        guard listen(sock, 5) == 0 else {
            print("[AntibanServer] Failed to listen on socket, errno: \(errno)")
            close(sock)
            self.listeningSocket = -1
            return
        }

        self.isRunning = true
        print("[AntibanServer] Listening on http://127.0.0.1:\(port)")

        while self.isRunning {
            var clientAddr = sockaddr_in()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

            let clientSock = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    accept(sock, sockaddrPtr, &clientAddrLen)
                }
            }

            guard clientSock >= 0 else {
                if !self.isRunning { break }
                continue
            }

            // Handle connection asynchronously
            DispatchQueue.global(qos: .userInitiated).async {
                self.handleClient(clientSock: clientSock, profileData: profileData)
            }
        }
        #endif
    }

    private func handleClient(clientSock: Int32, profileData: Data) {
        #if canImport(Darwin)
        defer {
            close(clientSock)
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = recv(clientSock, &buffer, buffer.count, 0)
        guard bytesRead > 0 else { return }

        // Response headers required for iOS to treat payload as a Configuration Profile
        let headerString = """
        HTTP/1.1 200 OK\r\n\
        Content-Type: application/x-apple-aspen-config\r\n\
        Content-Disposition: attachment; filename="antiban.mobileconfig"\r\n\
        Content-Length: \(profileData.count)\r\n\
        Connection: close\r\n\
        Cache-Control: no-cache, no-store, must-revalidate\r\n\
        \r\n
        """

        guard let headerData = headerString.data(using: .utf8) else { return }
        var fullResponse = headerData
        fullResponse.append(profileData)

        _ = fullResponse.withUnsafeBytes { rawBuffer in
            send(clientSock, rawBuffer.baseAddress, rawBuffer.count, 0)
        }
        #endif
    }
}

// MARK: - Antiban Profile Manager Service
@MainActor
final class AntibanProfileService: ObservableObject {
    static let shared = AntibanProfileService()

    @AppStorage("applestorevn_antiban_enabled") var isAntibanEnabled: Bool = false
    @AppStorage("applestorevn_antiban_installed") var hasConfiguredProfile: Bool = false
    @Published var isSettingUp: Bool = false
    @Published var setupSuccess: Bool = false
    @Published var statusNotice: String? = nil

    private let localServer = AntibanLocalServer.shared
    let serverURLString = "http://127.0.0.1:28085/antiban.mobileconfig"

    private init() {}

    /// Tải dữ liệu file profile .mobileconfig từ Bundle hoặc bộ dự phòng AppleStoreVN
    func getProfileData() -> Data {
        if let bundleUrl = Bundle.main.url(forResource: "antiban", withExtension: "mobileconfig"),
           let data = try? Data(contentsOf: bundleUrl), !data.isEmpty {
            return data
        }
        return fallbackMobileConfigXML.data(using: .utf8) ?? Data()
    }

    /// Kích hoạt cài đặt Antiban Profile qua Local HTTP Server và Safari
    func setupAntiban() {
        isSettingUp = true
        statusNotice = nil

        let data = getProfileData()
        localServer.start(profileData: data)

        // Độ trễ 150ms để socket hoàn tất bind & listen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            guard let url = URL(string: self.serverURLString) else {
                self.statusNotice = "Không tạo được đường dẫn cài đặt."
                self.isSettingUp = false
                return
            }

            UIApplication.shared.open(url, options: [:]) { success in
                DispatchQueue.main.async {
                    self.isSettingUp = false
                    if success {
                        self.hasConfiguredProfile = true
                        self.setupSuccess = true
                        self.statusNotice = "Đã gửi hồ sơ qua Safari! Hãy nhấn 'Cho phép' và vào Cài đặt để kích hoạt."
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        self.statusNotice = "Không thể mở Safari để tải hồ sơ. Vui lòng thử lại."
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            }
        }
    }

    /// Mở trang Quản lý Cấu hình Profile trong Cài Đặt iPhone
    func openIOSSettings() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        let settingsURLs = [
            "App-Prefs:root=General&path=ManagedConfigurationList",
            "App-Prefs:root=General",
            UIApplication.openSettingsURLString
        ]

        for urlString in settingsURLs {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }

        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }

    /// Bật hoặc Tắt trạng thái Antiban
    func toggleAntiban() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isAntibanEnabled.toggle()
    }
}

// MARK: - Chuỗi XML Dự phòng Đầy đủ của AppleStoreVN Antiban Profile
private let fallbackMobileConfigXML = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>PayloadDisplayName</key>
    <string>AppleStoreVN Antiban DNS</string>
    <key>PayloadDescription</key>
    <string>Cấu hình Antiban AppleStoreVN - Chặn máy chủ phát hiện gian lận và bảo vệ an toàn game.</string>
    <key>PayloadIdentifier</key>
    <string>vn.applestore.antiban.profile</string>
    <key>PayloadScope</key>
    <string>System</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>A1E2F262-DB73-40F6-BD22-2E42A43A3C94.applestorevn</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
    <key>PayloadOrganization</key>
    <string>AppleStoreVN</string>
    <key>PayloadContent</key>
    <array>
      <dict>
        <key>DNSSettings</key>
        <dict>
          <key>DNSProtocol</key>
          <string>HTTPS</string>
          <key>ServerURL</key>
          <string>https://apple.dns.nextdns.io/a5b645</string>
        </dict>
        <key>OnDemandRules</key>
        <array>
          <dict>
            <key>Action</key>
            <string>EvaluateConnection</string>
            <key>ActionParameters</key>
            <array>
              <dict>
                <key>DomainAction</key>
                <string>NeverConnect</string>
                <key>Domains</key>
                <array>
                  <string>captive.apple.com</string>
                  <string>3gppnetwork.org</string>
                  <string>dav.orange.fr</string>
                  <string>vvm.mobistar.be</string>
                  <string>vvm.mstore.msg.t-mobile.com</string>
                  <string>tma.vvm.mone.pan-net.eu</string>
                  <string>vvm.ee.co.uk</string>
                </array>
              </dict>
            </array>
          </dict>
          <dict>
            <key>Action</key>
            <string>Connect</string>
          </dict>
        </array>
        <key>PayloadType</key>
        <string>com.apple.dnsSettings.managed</string>
        <key>PayloadIdentifier</key>
        <string>vn.applestore.antiban.profile.dnsSettings.managed</string>
        <key>PayloadUUID</key>
        <string>A1E2F262-DB73-40F6-BD22-2E42A43A3C94.applestorevn.dnsSettings.managed</string>
        <key>PayloadDisplayName</key>
        <string>AppleStoreVN DNS Engine</string>
        <key>PayloadOrganization</key>
        <string>AppleStoreVN</string>
        <key>PayloadDescription</key>
        <string>AppleStoreVN DNS Engine - Bảo vệ hệ thống và ngăn chặn phát hiện mod.</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
      </dict>
    </array>
  </dict>
</plist>
"""
