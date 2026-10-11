import Foundation
import Security
import UIKit
import CommonCrypto

// MARK: - Server Response Models
public struct LicenseAPIResponse: Codable {
    public let status: String
    public let code: String?
    public let message: String?
    public let key: String?
    public let package: String?
    public let device_id: String?
    public let activated_at: String?
    public let expires_at: String?
    public let seconds_left: Double?
    public let days_left: Double?

    public var isSuccess: Bool {
        status.lowercased() == "success" || code?.uppercased() == "KEY_VALID"
    }
}

// MARK: - License Manager
public final class LicenseManager: ObservableObject {
    public static let shared = LicenseManager()

    // MARK: - Published Properties
    @Published public var isActivated: Bool = false
    @Published public var activeKey: String = ""
    @Published public var planName: String = "VIP LIFETIME"
    @Published public var expirationDateText: String = "KHÔNG GIỚI HẠN"
    @Published public var remainingSeconds: Double = 0
    @Published public var isLoading: Bool = false
    @Published public var lastErrorMessage: String? = nil
    @Published public var isServerOnline: Bool = true

    public static let apiEndpoint = "https://cheatingenginexyz.online/api.php"
    private let keychainService = "com.cheatstore.external.license"
    private let keychainAccount = "active_license_key"

    public var deviceID: String {
        if let savedID = UserDefaults.standard.string(forKey: "CS_DEVICE_HWID"), !savedID.isEmpty {
            return savedID
        }
        let rawID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let generatedHWID = "CS-" + rawID.replacingOccurrences(of: "-", with: "").prefix(16).uppercased()
        UserDefaults.standard.set(generatedHWID, forKey: "CS_DEVICE_HWID")
        return generatedHWID
    }

    public var formattedRemainingTime: String {
        if remainingSeconds <= 0 {
            return expirationDateText
        }
        let days = Int(remainingSeconds) / 86400
        let hours = (Int(remainingSeconds) % 86400) / 3600
        let minutes = (Int(remainingSeconds) % 3600) / 60
        if days > 0 {
            return "\(days) ngày \(hours) giờ"
        } else if hours > 0 {
            return "\(hours) giờ \(minutes) phút"
        } else {
            return "\(minutes) phút"
        }
    }

    // MARK: - Initialization
    public init() {
        if let storedKey = loadKeyFromKeychain(), !storedKey.isEmpty {
            self.activeKey = storedKey
            // Silent validation in background
            verifyKey(key: storedKey, isAutoLogin: true) { _ in }
        }
    }

    // MARK: - Verify Key with Server
    public func verifyKey(key: String, isAutoLogin: Bool = false, completion: @escaping (Bool) -> Void) {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            DispatchQueue.main.async {
                self.lastErrorMessage = "Vui lòng nhập mã bản quyền (Key)"
                completion(false)
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.lastErrorMessage = nil
        }

        guard let url = URL(string: Self.apiEndpoint) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastErrorMessage = "Lỗi đường dẫn máy chủ"
                completion(false)
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let postParams = [
            "action": "verify_key",
            "key": cleanKey,
            "device_id": deviceID,
            "hwid": deviceID,
            "app": "CheatStoreVN",
            "version": "1.0.0"
        ]

        let postBody = postParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")" }.joined(separator: "&")
        request.httpBody = postBody.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.isServerOnline = false
                    // Nếu là auto-login từ trước và offline, vẫn cho phép tiếp tục phiên
                    if isAutoLogin && !self.activeKey.isEmpty {
                        self.isActivated = true
                        completion(true)
                        return
                    }
                    self.lastErrorMessage = "Không thể kết nối máy chủ: \(error.localizedDescription)"
                    completion(false)
                    return
                }

                self.isServerOnline = true

                guard let data = data else {
                    self.lastErrorMessage = "Máy chủ không phản hồi dữ liệu"
                    completion(false)
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let apiResp = try decoder.decode(LicenseAPIResponse.self, from: data)

                    if apiResp.isSuccess {
                        self.activeKey = cleanKey
                        self.saveKeyToKeychain(key: cleanKey)
                        self.planName = apiResp.package ?? "VIP EXTERNAL"
                        if let exp = apiResp.expires_at {
                            self.expirationDateText = exp
                        }
                        if let secs = apiResp.seconds_left {
                            self.remainingSeconds = secs
                        }
                        self.isActivated = true
                        completion(true)
                    } else {
                        self.lastErrorMessage = apiResp.message ?? "Mã bản quyền không hợp lệ hoặc đã hết hạn"
                        completion(false)
                    }
                } catch {
                    // Fallback JSON parse
                    if let rawStr = String(data: data, encoding: .utf8), rawStr.lowercased().contains("success") || rawStr.contains("VALID") {
                        self.activeKey = cleanKey
                        self.saveKeyToKeychain(key: cleanKey)
                        self.isActivated = true
                        completion(true)
                    } else {
                        self.lastErrorMessage = "Phản hồi máy chủ không hợp lệ"
                        completion(false)
                    }
                }
            }
        }.resume()
    }

    public func confirmActivation() {
        self.isActivated = true
    }

    public func logout() {
        self.isActivated = false
        self.activeKey = ""
        deleteKeyFromKeychain()
    }

    // MARK: - Keychain Helper
    private func saveKeyToKeychain(key: String) {
        guard let data = key.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    private func loadKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
