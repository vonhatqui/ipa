import Foundation
import UIKit
import Combine

// MARK: - License Models

public struct HyperXLicenseInfo: Codable, Equatable {
    public let key: String
    public let package: String
    public let duration: String
    public let activatedAt: String?
    public let expiresAt: String?
    public let daysLeft: String
    public let secondsLeft: Int
    public let deviceCurrent: Int
    public let deviceMax: Int
    public let isAppSafe: Bool
    public let safetyStatus: String
    public let message: String?
}

// MARK: - SSL Trust Delegate (Hỗ trợ chứng chỉ bảo mật và tự ký SSL)
final class HyperXSSLTrustDelegate: NSObject, URLSessionDelegate {
    static let shared = HyperXSSLTrustDelegate()
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Auth Manager

@MainActor
public final class HyperXAuthManager: ObservableObject {
    public static let shared = HyperXAuthManager()

    private let storageKey = "hyperx_saved_license_key"
    private let hwidKey = "hyperx_device_hwid"
    private let endpointURL = "https://crackbomaydihihi.sbs/api.php"
    private let session = URLSession(
        configuration: .default,
        delegate: HyperXSSLTrustDelegate.shared,
        delegateQueue: nil
    )

    @Published public var isAuthenticated: Bool = false
    @Published public var isKeyVerified: Bool = false
    @Published public var licenseKey: String = ""
    @Published public var licenseInfo: HyperXLicenseInfo?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    public init() {
        if let savedKey = UserDefaults.standard.string(forKey: storageKey), !savedKey.isEmpty {
            self.licenseKey = savedKey
        }
    }

    // MARK: - Hardware & System Information

    public var hwid: String {
        if let existing = UserDefaults.standard.string(forKey: hwidKey), !existing.isEmpty {
            return existing
        }
        let vendor = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let cleanVendor = vendor.replacingOccurrences(of: "-", with: "").prefix(16)
        let generatedHWID = "HX-\(AppInfo.machineName)-\(cleanVendor)"
        UserDefaults.standard.set(generatedHWID, forKey: hwidKey)
        return generatedHWID
    }

    public var deviceModel: String {
        AppInfo.hardwareDisplayName
    }

    public var iosVersion: String {
        "iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))"
    }

    // MARK: - API Verification

    public func verifyKey(inputKey: String) async -> Bool {
        let cleanedKey = inputKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanedKey.isEmpty else {
            self.errorMessage = "Vui lòng nhập mã License Key!"
            return false
        }

        self.isLoading = true
        self.errorMessage = nil

        var components = URLComponents(string: endpointURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "app_verify"),
            URLQueryItem(name: "key", value: cleanedKey),
            URLQueryItem(name: "device_id", value: self.hwid),
            URLQueryItem(name: "hwid", value: self.hwid)
        ]

        guard let requestURL = components?.url else {
            self.isLoading = false
            self.errorMessage = "URL máy chủ không hợp lệ!"
            return false
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("HyperXSpace/2.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                self.isLoading = false
                self.errorMessage = "Không nhận được phản hồi từ máy chủ."
                return false
            }

            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                self.isLoading = false
                self.errorMessage = "Máy chủ phản hồi định dạng không hợp lệ."
                return false
            }

            let status = json["status"] as? String ?? ""
            let code = json["code"] as? String ?? ""
            let message = json["message"] as? String

            if httpResponse.statusCode == 200, status == "success" || code == "KEY_VALID" {
                let package = json["package"] as? String ?? "HyperX VIP"
                let duration = json["duration"] as? String ?? "Không xác định"
                let activatedAt = json["activated_at"] as? String
                let expiresAt = json["expires_at"] as? String
                let secondsLeft = json["seconds_left"] as? Int ?? 0

                let daysLeftStr: String
                if let daysVal = json["days_left"] {
                    daysLeftStr = "\(daysVal)"
                } else {
                    daysLeftStr = "—"
                }

                let deviceCurrent = json["device_current"] as? Int ?? 1
                let deviceMax = json["device_max"] as? Int ?? 1
                let isAppSafe = json["is_app_safe"] as? Bool ?? true
                let safetyStatus = json["safety_status"] as? String ?? "safe"

                let info = HyperXLicenseInfo(
                    key: cleanedKey,
                    package: package,
                    duration: duration,
                    activatedAt: activatedAt,
                    expiresAt: expiresAt,
                    daysLeft: daysLeftStr,
                    secondsLeft: secondsLeft,
                    deviceCurrent: deviceCurrent,
                    deviceMax: deviceMax,
                    isAppSafe: isAppSafe,
                    safetyStatus: safetyStatus,
                    message: message
                )

                self.licenseKey = cleanedKey
                self.licenseInfo = info
                self.isKeyVerified = true
                self.isLoading = false
                UserDefaults.standard.set(cleanedKey, forKey: self.storageKey)
                return true
            } else {
                self.isLoading = false
                self.errorMessage = message ?? "Mã Key không hợp lệ hoặc đã hết hạn!"
                return false
            }
        } catch {
            self.isLoading = false
            self.errorMessage = "Lỗi kết nối máy chủ: \(error.localizedDescription)"
            return false
        }
    }

    public func autoValidateSavedKey() async {
        guard !licenseKey.isEmpty else { return }
        _ = await verifyKey(inputKey: licenseKey)
    }

    public func enterApp() {
        self.isAuthenticated = true
    }

    public func logout() {
        self.isAuthenticated = false
        self.isKeyVerified = false
        self.licenseInfo = nil
        self.licenseKey = ""
        self.errorMessage = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
