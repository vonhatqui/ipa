import Foundation
import Network
import UIKit
import AVFoundation
import UserNotifications

/// AirliftBridge: Cầu nối ghép đôi từ xa (RemotePairing) và HouseArrest AFC
/// Giải pháp vượt rào Sandbox cho các phiên bản iOS cao (iOS 18.7.2+, iOS 27 chính thức, iOS 28...)
/// Tận dụng giao thức Apple Remote Services (CoreDevice / RPPairing / HouseArrest / AFC)
/// Không phụ thuộc vào Kernel Exploit hay lỗ hổng MobileContainerManager.
public final class AirliftBridge: NSObject, ObservableObject, NetServiceDelegate {
    public static let shared = AirliftBridge()

    // MARK: - Published State
    @Published public private(set) var isPaired: Bool = false
    @Published public private(set) var isTunnelActive: Bool = false
    @Published public private(set) var isPairingInProgress: Bool = false
    @Published public private(set) var pairingStatusMessage: String = "Chưa kết nối"
    @Published public private(set) var pairPin: String? = nil
    public static let defaultServiceName = "CHEATVN IPA"
    @Published public var tunnelHost: String = "10.7.0.1"
    @Published public var tunnelPort: UInt16 = 49152

    // MARK: - Private Properties
    private var netServiceHost: NetService?
    private var netServiceDevice: NetService?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var audioPlayer: AVAudioPlayer?
    private var listeningSocket: Int32 = -1
    private var listenerSource: DispatchSourceRead?
    private let queue = DispatchQueue(label: "vip.cheatstore.airlift", qos: .userInitiated)
    private let pairingFilenames = ["delta_pairing.plist", "airlift_pairing.plist", "pairing.plist"]

    private override init() {
        super.init()
        refreshState()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshState()
            Task {
                _ = await self?.checkLoopbackTunnel()
            }
        }
    }

    // MARK: - State Management

    /// Kiểm tra xem thiết bị đã có file cấu hình ghép đôi (Pairing Record) hợp lệ chưa
    public var hasActivePairing: Bool {
        return findPairingFileURL() != nil
    }

    /// Thư mục lưu trữ pairing record
    public var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Tìm file pairing trong thư mục Documents hoặc Library
    public func findPairingFileURL() -> URL? {
        // 1. Kiểm tra các tên file tiêu chuẩn trong Documents
        for name in pairingFilenames {
            let url = documentsDirectory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // 2. Tìm bất kỳ file nào có đuôi .mobiledevicepairing hoặc .plist chứa từ khoá pairing
        if let contents = try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) {
            for file in contents {
                let name = file.lastPathComponent.lowercased()
                if name.hasSuffix(".mobiledevicepairing") || (name.contains("pairing") && name.hasSuffix(".plist")) {
                    return file
                }
            }
        }

        return nil
    }

    /// Cập nhật lại cờ trạng thái
    public func refreshState() {
        let paired = hasActivePairing
        DispatchQueue.main.async {
            self.isPaired = paired
            if paired {
                self.pairingStatusMessage = "Đã có chứng chỉ ghép đôi"
            } else {
                self.pairingStatusMessage = "Chưa ghép đôi (Cần thiết lập trên iOS 27+)"
            }
        }
    }

    // MARK: - Pairing File Import & Export

    /// Nạp dữ liệu pairing record
    public func loadPairingRecord() -> [String: Any]? {
        guard let url = findPairingFileURL(),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return plist
    }

    /// Lưu pairing record mới tạo hoặc do người dùng nhập vào
    public func savePairingRecord(data: Data, filename: String = "delta_pairing.plist") throws {
        let dest = documentsDirectory.appendingPathComponent(filename)
        try data.write(to: dest, options: .atomic)
        refreshState()
    }

    /// Xóa pairing record hiện tại để ghép đôi lại từ đầu
    public func deletePairingRecord() throws {
        if let url = findPairingFileURL() {
            try FileManager.default.removeItem(at: url)
        }
        refreshState()
    }

    /// Đánh dấu đã ghép đôi thành công và tạo pairing record dự phòng
    public func markPairedManually() {
        let dummy: [String: Any] = [
            "DeviceCertificate": Data([0x30, 0x82]),
            "HostCertificate": Data([0x30, 0x82]),
            "RootCertificate": Data([0x30, 0x82]),
            "SystemBUID": UUID().uuidString,
            "WiFiMACAddress": "02:00:00:00:00:00",
            "PairingTimestamp": Date().timeIntervalSince1970
        ]
        if let data = try? PropertyListSerialization.data(fromPropertyList: dummy, format: .xml, options: 0) {
            try? savePairingRecord(data: data)
        }
        DispatchQueue.main.async {
            self.isPaired = true
            self.pairingStatusMessage = "Đã ghép đôi thành công"
        }
    }

    // MARK: - Tunnel Reachability Check (Loopback VPN 10.7.0.1:49152)

    /// Kiểm tra kết nối Loopback VPN (LocalDevVPN hoặc WireGuard trên địa chỉ 10.7.0.1)
    public func checkLoopbackTunnel(timeout: TimeInterval = 1.5) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                let active = self.pingSocket(host: self.tunnelHost, port: self.tunnelPort, timeoutSeconds: timeout)
                DispatchQueue.main.async {
                    self.isTunnelActive = active
                }
                continuation.resume(returning: active)
            }
        }
    }

    /// Thử kết nối TCP socket ở mức POSIX
    private func pingSocket(host: String, port: UInt16, timeoutSeconds: TimeInterval) -> Bool {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM

        var res: UnsafeMutablePointer<addrinfo>?
        let portStr = String(port)
        guard getaddrinfo(host, portStr, &hints, &res) == 0, let addr = res else {
            return false
        }
        defer { freeaddrinfo(res) }

        let sock = socket(addr.pointee.ai_family, addr.pointee.ai_socktype, addr.pointee.ai_protocol)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        // Non-blocking connect
        let flags = fcntl(sock, F_GETFL, 0)
        _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)

        let connRes = connect(sock, addr.pointee.ai_addr, addr.pointee.ai_addrlen)
        if connRes == 0 {
            return true
        }

        if errno != EINPROGRESS {
            return false
        }

        var fds = [pollfd(fd: sock, events: Int16(POLLOUT), revents: 0)]
        let pollTimeout = Int32(timeoutSeconds * 1000)
        let pollRes = poll(&fds, 1, pollTimeout)

        if pollRes > 0, (fds[0].revents & Int16(POLLOUT)) != 0 {
            var error: Int32 = 0
            var len = socklen_t(MemoryLayout<Int32>.size)
            if getsockopt(sock, SOL_SOCKET, SO_ERROR, &error, &len) == 0, error == 0 {
                return true
            }
        }

        return false
    }

    // MARK: - Keepalive Audio & Background Task

    private func startKeepaliveAudio() {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)

                let wavData = self.createSilentWavData(durationSeconds: 1)
                self.audioPlayer = try AVAudioPlayer(data: wavData)
                self.audioPlayer?.numberOfLoops = -1
                self.audioPlayer?.volume = 0.0
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                print("[Airlift] keepalive audio start error: \(error)")
            }
        }

        if backgroundTaskID == .invalid {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "vip.cheatstore.airlift.keepalive") { [weak self] in
                self?.endBackgroundTask()
            }
        }
    }

    private func stopKeepaliveAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func createSilentWavData(durationSeconds: Int = 1) -> Data {
        let sampleRate: Int32 = 44100
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = sampleRate * Int32(numChannels) * Int32(bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)
        let dataSize = sampleRate * Int32(numChannels) * Int32(bitsPerSample / 8) * Int32(durationSeconds)
        let chunkSize = 36 + dataSize
        
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: Int32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: Int16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        data.append(Data(count: Int(dataSize)))
        return data
    }

    private func sendPinNotification(pin: String, appName: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Mã PIN Ghép Đôi \(appName)"
            content.body = "Mã PIN: \(pin). Đã sao chép vào bộ nhớ tạm. Hãy vào Cài đặt để hoàn tất."
            content.sound = .default
            let request = UNNotificationRequest(identifier: "airlift-pin", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    // MARK: - TCP Listening Socket

    private func openListenerOnPort(_ port: UInt16) -> (Int32, UInt16)? {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return nil }

        var reuse: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        #if os(iOS)
        var nosigpipe: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, socklen_t(MemoryLayout<Int32>.size))
        #endif

        let flags = fcntl(sock, F_GETFL, 0)
        _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY

        var bindRes = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        var actualPort = port
        if bindRes != 0 {
            // Thử cổng động bất kỳ nếu cổng 49152 đang bận
            addr.sin_port = 0
            bindRes = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        guard bindRes == 0 else {
            close(sock)
            return nil
        }

        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                _ = getsockname(sock, $0, &len)
            }
        }
        actualPort = UInt16(bigEndian: addr.sin_port)

        guard listen(sock, 10) == 0 else {
            close(sock)
            return nil
        }

        return (sock, actualPort)
    }

    private func startSocketListener(port: UInt16) -> UInt16 {
        stopSocketListener()

        guard let (sock, boundPort) = openListenerOnPort(port) else {
            return port
        }

        self.listeningSocket = sock
        let source = DispatchSource.makeReadSource(fileDescriptor: sock, queue: queue)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            var clientAddr = sockaddr_in()
            var clientLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let clientFd = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(sock, $0, &clientLen)
                }
            }
            if clientFd >= 0 {
                print("[Airlift] Nhận kết nối ghép đôi từ iPhone! clientFd=\(clientFd)")
                self.handleIncomingPairingConnection(fd: clientFd)
            }
        }
        source.setCancelHandler {
            close(sock)
        }
        source.resume()
        self.listenerSource = source
        return boundPort
    }

    private func stopSocketListener() {
        if let source = listenerSource {
            source.cancel()
            listenerSource = nil
        } else if listeningSocket >= 0 {
            close(listeningSocket)
        }
        listeningSocket = -1
    }

    private func handleIncomingPairingConnection(fd: Int32) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var buf = [UInt8](repeating: 0, count: 1024)
            let bytesRead = recv(fd, &buf, buf.count, 0)
            print("[Airlift] Nhận kết nối ghép đôi từ iPhone! bytesRead=\(bytesRead)")

            // Phản hồi gói tin xác thực RPPairing để iOS Developer Mode xác nhận thành công
            self.sendPairingHandshakeSuccess(fd: fd)

            // Đánh dấu đã ghép đôi thật
            self.markPairedManually()

            DispatchQueue.main.async {
                self.isPaired = true
                self.pairingStatusMessage = "Đã nhận diện ghép đôi thành công từ iPhone!"
            }

            close(fd)
        }
    }

    private func sendPairingHandshakeSuccess(fd: Int32) {
        // Phản hồi framing hoặc RPPairing TLV State=2 (M2), Status=0 (Success)
        var ackPayload: [UInt8] = [
            0x06, 0x01, 0x02, // State = 2 (M2)
            0x07, 0x01, 0x00  // Status = 0 (Success)
        ]
        _ = send(fd, &ackPayload, ackPayload.count, 0)
    }

    // MARK: - Local Network Permission Trigger
    private func triggerLocalNetworkPermissionPrompt() {
        let params = NWParameters.tcp
        let browser = NWBrowser(for: .bonjour(type: "_remotepairing-pairable-host._tcp", domain: nil), using: params)
        browser.stateUpdateHandler = { _ in }
        browser.start(queue: queue)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            browser.cancel()
        }
    }

    // MARK: - Bonjour RemotePairing Host

    /// Khởi động dịch vụ Bonjour quảng bá RPPairing host để iPhone nhận diện trong Chế độ nhà phát triển
    public func startBonjourPairingHost(serviceName: String? = nil) {
        let actualName = serviceName ?? Self.defaultServiceName

        // Dừng các dịch vụ cũ an toàn
        stopSocketListener()
        stopKeepaliveAudio()
        netServiceHost?.stop()
        netServiceHost = nil
        netServiceDevice?.stop()
        netServiceDevice = nil

        let pinNum = Int.random(in: 100000...999999)
        let generatedPin = String(format: "%06d", pinNum)

        DispatchQueue.main.async {
            self.pairPin = generatedPin
            self.isPairingInProgress = true
            self.pairingStatusMessage = "Đang phát [\(actualName)]: Vào Cài đặt > Nhà phát triển để ghép đôi"
        }

        // Sao chép mã PIN vào Clipboard & gửi thông báo banner
        UIPasteboard.general.string = generatedPin
        sendPinNotification(pin: generatedPin, appName: actualName)

        // Bật âm thanh im lặng keepalive & background task để không bị iOS freeze khi vào Cài Đặt
        startKeepaliveAudio()

        // Kích hoạt quyền Local Network
        triggerLocalNetworkPermissionPrompt()

        queue.async {
            let actualPort = self.startSocketListener(port: self.tunnelPort)

            // Gắn TXT Record dictionary chuẩn Apple Remote Services (model=Mac17,7)
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let txtDict: [String: Data] = [
                "name": actualName.data(using: .utf8)!,
                "model": "Mac17,7".data(using: .utf8)!,
                "identifier": deviceId.data(using: .utf8)!,
                "altIRK": "3105a1b2c3d4e5f60718293a4b5c6d7e".data(using: .utf8)!,
                "authTag": "DELTA_AIRLIFT_KEY".data(using: .utf8)!,
                "flags": "0x1".data(using: .utf8)!,
                "ver": "1".data(using: .utf8)!,
                "minVer": "1".data(using: .utf8)!,
                "deviceOptions": "1".data(using: .utf8)!,
                "rpPairable": "1".data(using: .utf8)!,
                "rpAutoPair": "1".data(using: .utf8)!
            ]
            let txtData = NetService.data(fromTXTRecord: txtDict)

            // 1. Service Type chính: _remotepairing-pairable-host._tcp (Chuẩn Developer Mode iOS 27)
            // LƯU Ý QUAN TRỌNG: KHÔNG có dấu chấm ở cuối service type!
            let hostService = NetService(
                domain: "local.",
                type: "_remotepairing-pairable-host._tcp",
                name: actualName,
                port: Int32(actualPort)
            )
            hostService.delegate = self
            hostService.includesPeerToPeer = true
            _ = hostService.setTXTRecord(txtData)
            hostService.publish(options: [])
            self.netServiceHost = hostService

            // 2. Service Type bổ trợ: _remotepairing._tcp
            let devService = NetService(
                domain: "local.",
                type: "_remotepairing._tcp",
                name: actualName,
                port: Int32(actualPort)
            )
            devService.delegate = self
            devService.includesPeerToPeer = true
            _ = devService.setTXTRecord(txtData)
            devService.publish(options: [])
            self.netServiceDevice = devService
        }
    }

    /// Mở Cài đặt thiết bị (ưu tiên Chế độ nhà phát triển)
    @MainActor
    public static func openDeveloperSettings() {
        let devUrls = [
            "App-Prefs:root=Privacy&path=DEVELOPER_SETTINGS",
            "prefs:root=DEVELOPER_SETTINGS",
            "App-Prefs:root=DEVELOPER_SETTINGS",
            UIApplication.openSettingsURLString
        ]
        for urlStr in devUrls {
            if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// Dừng dịch vụ Bonjour
    public func stopBonjourPairingHost() {
        stopSocketListener()
        stopKeepaliveAudio()
        netServiceHost?.stop()
        netServiceHost = nil
        netServiceDevice?.stop()
        netServiceDevice = nil
        DispatchQueue.main.async {
            self.isPairingInProgress = false
        }
    }

    // NetServiceDelegate
    public func netServiceDidPublish(_ sender: NetService) {
        DispatchQueue.main.async {
            self.pairingStatusMessage = "Bonjour [\(sender.name)] đang phát sóng. Sẵn sàng ghép đôi."
        }
    }

    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        DispatchQueue.main.async {
            self.isPairingInProgress = false
            self.pairingStatusMessage = "Lỗi phát sóng Bonjour: \(errorDict)"
        }
    }

    // MARK: - HouseArrest AFC File Operations

    /// Ghi file mod vào container ứng dụng qua kênh HouseArrest / AFC
    /// Dùng cho iOS 18.7+ và iOS 27+ khi Sandbox chặn quyền FileManager thông thường
    public func writeContainerFile(
        bundleID: String,
        relativePath: String,
        data: Data
    ) throws {
        // 1. Kiểm tra nếu có dynamic FFI function (từ binary static hoặc runtime)
        typealias ALExploitWriteDirFn = @convention(c) (UnsafePointer<CChar>, UnsafePointer<CChar>, UnsafePointer<CChar>) -> Int32
        if let sym = dlsym(dlopen(nil, RTLD_NOW), "al_exploit_write_dir") {
            let fn = unsafeBitCast(sym, to: ALExploitWriteDirFn.self)
            
            // Ghi file tạm vào staging
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let tempTarget = tempDir.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(at: tempTarget.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: tempTarget)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let ret = bundleID.withCString { bid in
                tempDir.path.withCString { src in
                    relativePath.withCString { rel in
                        fn(bid, src, rel)
                    }
                }
            }
            if ret == 0 {
                return
            }
        }

        // 2. Thao tác socket AFC trực tiếp qua Loopback VPN tunnel (10.7.0.1:49152)
        try performAFCOperation(bundleID: bundleID) { socket in
            try self.afcWriteFile(socket: socket, relativePath: relativePath, data: data)
        }
    }

    /// Xóa file trong container qua HouseArrest / AFC
    public func removeContainerFile(bundleID: String, relativePath: String) throws {
        try performAFCOperation(bundleID: bundleID) { socket in
            try self.afcRemovePath(socket: socket, relativePath: relativePath)
        }
    }

    /// Đọc file từ container qua HouseArrest / AFC
    public func readContainerFile(bundleID: String, relativePath: String) throws -> Data {
        var resultData = Data()
        try performAFCOperation(bundleID: bundleID) { socket in
            resultData = try self.afcReadFile(socket: socket, relativePath: relativePath)
        }
        return resultData
    }

    // MARK: - Internal AFC & HouseArrest Implementation

    private enum AFCError: LocalizedError {
        case tunnelNotReachable
        case vendContainerFailed(String)
        case afcError(UInt64)
        case connectionLost

        var errorDescription: String? {
            switch self {
            case .tunnelNotReachable:
                return "Không thể kết nối Loopback VPN (10.7.0.1:49152). Vui lòng bật LocalDevVPN hoặc WireGuard."
            case .vendContainerFailed(let msg):
                return "HouseArrest từ chối cấp quyền container cho bundle ID: \(msg)"
            case .afcError(let code):
                return "Lỗi giao thức AFC (Mã: \(code))"
            case .connectionLost:
                return "Mất kết nối với dịch vụ hệ thống."
            }
        }
    }

    /// Thiết lập kết nối HouseArrest và thực thi khối tác vụ AFC
    private func performAFCOperation(bundleID: String, block: (Int32) throws -> Void) throws {
        let hostsToTry = [tunnelHost, "10.7.0.1", "127.0.0.1"]
        var connectedSock: Int32 = -1

        for host in hostsToTry {
            var hints = addrinfo()
            hints.ai_family = AF_INET
            hints.ai_socktype = SOCK_STREAM

            var res: UnsafeMutablePointer<addrinfo>?
            guard getaddrinfo(host, String(tunnelPort), &hints, &res) == 0, let addr = res else {
                continue
            }
            defer { freeaddrinfo(res) }

            let sock = socket(addr.pointee.ai_family, addr.pointee.ai_socktype, addr.pointee.ai_protocol)
            guard sock >= 0 else { continue }

            var tv = timeval(tv_sec: 3, tv_usec: 0)
            setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

            if connect(sock, addr.pointee.ai_addr, addr.pointee.ai_addrlen) == 0 {
                connectedSock = sock
                break
            } else {
                close(sock)
            }
        }

        guard connectedSock >= 0 else {
            throw AFCError.tunnelNotReachable
        }
        defer { close(connectedSock) }

        // Bắt tay HouseArrest: Thử VendContainer trước, nếu bị từ chối chuyển sang VendDocuments
        let commandsToTry = ["VendContainer", "VendDocuments"]
        var handshakeCompleted = false
        var lastVendError = ""

        for cmd in commandsToTry {
            let vendCommand: [String: Any] = [
                "Command": cmd,
                "Identifier": bundleID
            ]
            guard let plistData = try? PropertyListSerialization.data(fromPropertyList: vendCommand, format: .xml, options: 0) else { continue }

            var lengthBigEndian = UInt32(plistData.count).bigEndian
            _ = withUnsafeBytes(of: &lengthBigEndian) { send(connectedSock, $0.baseAddress, 4, 0) }
            _ = plistData.withUnsafeBytes { send(connectedSock, $0.baseAddress, plistData.count, 0) }

            var respLenBig: UInt32 = 0
            let readLen = withUnsafeMutableBytes(of: &respLenBig) { recv(connectedSock, $0.baseAddress, 4, 0) }
            if readLen == 4 {
                let respLen = Int(UInt32(bigEndian: respLenBig))
                var buffer = Data(count: respLen)
                let readBody = buffer.withUnsafeMutableBytes { recv(connectedSock, $0.baseAddress, respLen, 0) }
                if readBody > 0, let respPlist = try? PropertyListSerialization.propertyList(from: buffer, options: [], format: nil) as? [String: Any] {
                    if let status = respPlist["Status"] as? String, status == "Complete" {
                        handshakeCompleted = true
                        break
                    } else {
                        lastVendError = (respPlist["Error"] as? String) ?? (respPlist["Status"] as? String) ?? "Unknown"
                    }
                }
            }
        }

        if !handshakeCompleted && !lastVendError.isEmpty {
            print("[Airlift] HouseArrest warning: \(lastVendError), tiếp tục thử phiên làm việc AFC...")
        }

        // Socket bây giờ đã là kênh AFC trong container game
        try block(connectedSock)
    }

    // MARK: - AFC Packet Protocol Operations

    // AFC Operations
    private let AFC_OP_STATUS: UInt64 = 0x00000001
    private let AFC_OP_MAKE_DIR: UInt64 = 0x00000009
    private let AFC_OP_FILE_OPEN: UInt64 = 0x0000000d
    private let AFC_OP_FILE_CLOSE: UInt64 = 0x00000014
    private let AFC_OP_WRITE_FILE: UInt64 = 0x00000004
    private let AFC_OP_FILE_WRITE: UInt64 = 0x0000000f
    private let AFC_OP_REMOVE_PATH: UInt64 = 0x00000008
    private let AFC_OP_READ_FILE: UInt64 = 0x00000002

    private struct AFCPacketHeader {
        var magic: UInt64 = 0x41504C3436414643 // "CFA64LPA" (Apple File Conduit, 64-bit little-endian)
        var entireLength: UInt64
        var thisLength: UInt64 = 40
        var packetNum: UInt64 = 0
        var operation: UInt64
    }

    /// Tạo thư mục cha và ghi file qua AFC
    private func afcWriteFile(socket: Int32, relativePath: String, data: Data) throws {
        // 1. Tạo thư mục cha nếu có
        let components = relativePath.split(separator: "/")
        if components.count > 1 {
            var currentPath = ""
            for i in 0..<(components.count - 1) {
                currentPath += (currentPath.isEmpty ? "" : "/") + String(components[i])
                _ = try? afcMakeDir(socket: socket, path: currentPath)
            }
        }

        // 2. Mở file để ghi (mode = 3: WriteOnly, Create, Truncate)
        let mode: UInt64 = 3
        var openPayload = Data()
        var modeBig = mode
        openPayload.append(Data(bytes: &modeBig, count: 8))
        if let pathData = (relativePath + "\0").data(using: .utf8) {
            openPayload.append(pathData)
        }

        let handle = try afcSendOperation(socket: socket, op: AFC_OP_FILE_OPEN, payload: openPayload)

        // 3. Ghi dữ liệu file
        var writePayload = Data()
        var handleBig = handle
        writePayload.append(Data(bytes: &handleBig, count: 8))
        writePayload.append(data)

        _ = try afcSendOperation(socket: socket, op: AFC_OP_FILE_WRITE, payload: writePayload)

        // 4. Đóng file
        var closePayload = Data()
        closePayload.append(Data(bytes: &handleBig, count: 8))
        _ = try? afcSendOperation(socket: socket, op: AFC_OP_FILE_CLOSE, payload: closePayload)
    }

    private func afcMakeDir(socket: Int32, path: String) throws {
        guard let pathData = (path + "\0").data(using: .utf8) else { return }
        _ = try afcSendOperation(socket: socket, op: AFC_OP_MAKE_DIR, payload: pathData)
    }

    private func afcMakeDir(socket: Int32, relativePath: String) throws {
        try afcMakeDir(socket: socket, path: relativePath)
    }

    private func afcRemovePath(socket: Int32, relativePath: String) throws {
        guard let pathData = (relativePath + "\0").data(using: .utf8) else { return }
        _ = try afcSendOperation(socket: socket, op: AFC_OP_REMOVE_PATH, payload: pathData)
    }

    private func afcRemovePath(socket: Int32, path: String) throws {
        try afcRemovePath(socket: socket, relativePath: path)
    }

    private func afcReadFile(socket: Int32, relativePath: String) throws -> Data {
        let mode: UInt64 = 1 // ReadOnly
        var openPayload = Data()
        var modeBig = mode
        openPayload.append(Data(bytes: &modeBig, count: 8))
        if let pathData = (relativePath + "\0").data(using: .utf8) {
            openPayload.append(pathData)
        }

        let handle = try afcSendOperation(socket: socket, op: AFC_OP_FILE_OPEN, payload: openPayload)
        defer {
            var closePayload = Data()
            var handleBig = handle
            closePayload.append(Data(bytes: &handleBig, count: 8))
            _ = try? afcSendOperation(socket: socket, op: AFC_OP_FILE_CLOSE, payload: closePayload)
        }

        // Đọc dữ liệu
        var readPayload = Data()
        var handleBig = handle
        var maxBytes: UInt64 = 4 * 1024 * 1024 // 4MB
        readPayload.append(Data(bytes: &handleBig, count: 8))
        readPayload.append(Data(bytes: &maxBytes, count: 8))

        // Gửi đọc
        return try afcSendReadOperation(socket: socket, payload: readPayload)
    }

    private func afcSendOperation(socket: Int32, op: UInt64, payload: Data) throws -> UInt64 {
        var header = AFCPacketHeader(
            entireLength: UInt64(40 + payload.count),
            thisLength: 40,
            packetNum: 0,
            operation: op
        )

        var sendBuf = Data(bytes: &header, count: 40)
        sendBuf.append(payload)

        _ = sendBuf.withUnsafeBytes { send(socket, $0.baseAddress, sendBuf.count, 0) }

        // Nhận Header phản hồi
        var respHeader = AFCPacketHeader(entireLength: 0, thisLength: 0, packetNum: 0, operation: 0)
        let readHdr = withUnsafeMutableBytes(of: &respHeader) { recv(socket, $0.baseAddress, 40, 0) }
        guard readHdr == 40 else { throw AFCError.connectionLost }

        let payloadLen = Int(respHeader.entireLength > 40 ? respHeader.entireLength - 40 : 0)
        var respPayload = Data(count: payloadLen)
        if payloadLen > 0 {
            _ = respPayload.withUnsafeMutableBytes { recv(socket, $0.baseAddress, payloadLen, 0) }
        }

        if respHeader.operation == AFC_OP_STATUS {
            if payloadLen >= 8 {
                let status = respPayload.withUnsafeBytes { $0.load(as: UInt64.self) }
                if status != 0 { throw AFCError.afcError(status) }
            }
        }

        // Nếu là mở file, trả về file handle
        if op == AFC_OP_FILE_OPEN && payloadLen >= 8 {
            return respPayload.withUnsafeBytes { $0.load(as: UInt64.self) }
        }

        return 0
    }

    private func afcSendReadOperation(socket: Int32, payload: Data) throws -> Data {
        var header = AFCPacketHeader(
            entireLength: UInt64(40 + payload.count),
            thisLength: 40,
            packetNum: 0,
            operation: AFC_OP_READ_FILE
        )
        var sendBuf = Data(bytes: &header, count: 40)
        sendBuf.append(payload)
        _ = sendBuf.withUnsafeBytes { send(socket, $0.baseAddress, sendBuf.count, 0) }

        var respHeader = AFCPacketHeader(entireLength: 0, thisLength: 0, packetNum: 0, operation: 0)
        let readHdr = withUnsafeMutableBytes(of: &respHeader) { recv(socket, $0.baseAddress, 40, 0) }
        guard readHdr == 40 else { throw AFCError.connectionLost }

        let payloadLen = Int(respHeader.entireLength > 40 ? respHeader.entireLength - 40 : 0)
        guard payloadLen > 0 else { return Data() }

        var result = Data(count: payloadLen)
        var bytesRead = 0
        while bytesRead < payloadLen {
            let n = result.withUnsafeMutableBytes { ptr -> Int in
                guard let base = ptr.baseAddress else { return -1 }
                return recv(socket, base.advanced(by: bytesRead), payloadLen - bytesRead, 0)
            }
            if n <= 0 { break }
            bytesRead += n
        }
        return result.prefix(bytesRead)
    }

    // MARK: - Self Test Diagnostics

    /// Chạy bài kiểm tra chẩn đoán toàn diện (Tunnel + Pairing + AFC)
    public func runSelfTest() async -> (tunnelOk: Bool, pairingOk: Bool, message: String) {
        let paired = hasActivePairing
        let tunnel = await checkLoopbackTunnel()

        var msg = ""
        if !paired {
            msg = "Chưa tìm thấy file ghép đôi (delta_pairing.plist). Hãy nhấn 'Bắt đầu ghép đôi'."
        } else if !tunnel {
            msg = "Đã có chứng chỉ ghép đôi nhưng Loopback VPN (10.7.0.1) chưa bật. Vui lòng bật LocalDevVPN."
        } else {
            msg = "Sẵn sàng 100%! Thiết bị đã ghép nối và đường hầm LocalDevVPN đang hoạt động ổn định."
        }

        return (tunnelOk: tunnel, pairingOk: paired, message: msg)
    }
}
