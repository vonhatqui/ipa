import Foundation
import Security
import UIKit
import CommonCrypto

/// Cấu hình quản lý bảo trì & mở khoá tính năng từ xa qua Server API
public struct FeatureMaintenanceConfig: Codable {
    public var aimneck: Bool = false           // Mặc định tạm bảo trì cho đến khi Server mở
    public var esp: Bool = false               // Mặc định tạm bảo trì cho đến khi Server mở
    public var skin: Bool = false              // Mặc định tạm bảo trì cho đến khi Server mở
    public var applestore_prime: Bool = true   // APPLESTORE PRIME luôn mở ổn định
    public var maintenance_message: String? = nil

    public init(
        aimneck: Bool = false,
        esp: Bool = false,
        skin: Bool = false,
        applestore_prime: Bool = true,
        maintenance_message: String? = nil
    ) {
        self.aimneck = aimneck
        self.esp = esp
        self.skin = skin
        self.applestore_prime = applestore_prime
        self.maintenance_message = maintenance_message
    }
}

/// Cấu trúc phản hồi chuẩn từ API Server CheatStore
struct LicenseAPIResponse: Codable {
    let status: String
    let code: String?
    let message: String?
    let key: String?
    let package: String?
    let device_id: String?
    let activated_at: String?
    let expires_at: String?
    let seconds_left: Double?
    let days_left: Double?

    var isSuccess: Bool {
        status.lowercased() == "success" || code?.uppercased() == "KEY_VALID"
    }
}

final class CheatStoreLicenseManager: ObservableObject {
    static let shared = CheatStoreLicenseManager()

    @Published var isActivated: Bool = false
    @Published var activeKey: String = ""
    @Published var planName: String = ""
    @Published var expirationDate: Date?
    @Published var expiresAtString: String = ""
    @Published var activatedAtString: String = ""
    @Published var secondsLeft: Double = 0
    @Published var daysLeft: Double = 0
    @Published var isVerifying: Bool = false
    @Published var isAutoChecking: Bool = false
    @Published var errorMessage: String?

    // CHẾ ĐỘ BẢO TRÌ MÁY CHỦ (HTTP 503)
    @Published var isMaintenanceActive: Bool = false
    @Published var maintenanceInfo: AppMaintenanceInfo?

    // QUẢN LÝ BẢO TRÌ TÍNH NĂNG TỪ XA QUA SERVER API
    @Published var featureConfig: FeatureMaintenanceConfig

    // 1. THÔNG TIN KẾT NỐI API
    private let apiBaseURL = "https://cheatingenginexyz.online/api.php"
    private let fixedAction = "verify"
    private let hmacSecret = "CheatStoreVN_Secret_2026"

    // Các key lưu trữ trong UserDefaults
    private let storageKeyActivation = "cheatstore_is_activated"
    private let storageKeyLicense = "cheatstore_license_key"
    private let storageKeyPlan = "cheatstore_plan_name"
    private let storageKeyExpiry = "cheatstore_expiry_timestamp"
    private let storageKeyExpiryStr = "cheatstore_expiry_date_str"
    private let storageKeyDaysLeft = "cheatstore_days_left"
    private let storageKeySecondsLeft = "cheatstore_seconds_left"
    private let storageKeyDeviceID = "cheatstore_device_id"
    private let storageKeyRememberKey = "cheatstore_remember_key"
    private let storageKeyFeatureConfig = "cheatstore_remote_feature_config"

    /// Tùy chọn Ghi Nhớ Key: Khi bật sẽ điền sẵn key vào ô đăng nhập, người dùng bấm Login để vào
    @Published var rememberKey: Bool {
        didSet {
            UserDefaults.standard.set(rememberKey, forKey: storageKeyRememberKey)
            if !rememberKey {
                UserDefaults.standard.removeObject(forKey: storageKeyLicense)
                Self.deleteKeychainString(key: Self.keychainLicenseKey)
            }
        }
    }

    /// Chuỗi hiển thị thời hạn còn lại (VD: 1 ngày 0 giờ, hoặc 23 giờ 45 phút)
    var formattedRemainingTime: String {
        let remainingSeconds: Double
        if secondsLeft > 0 {
            remainingSeconds = secondsLeft
        } else if let exp = expirationDate {
            remainingSeconds = max(0, exp.timeIntervalSince(Date()))
        } else {
            remainingSeconds = 0
        }

        if remainingSeconds <= 0 {
            return "Hết hạn"
        }

        let totalSec = Int(remainingSeconds)
        let days = totalSec / 86400
        let hours = (totalSec % 86400) / 3600
        let minutes = (totalSec % 3600) / 60

        if days > 0 {
            if hours > 0 {
                return "\(days) ngày \(hours) giờ"
            } else {
                return "\(days) ngày"
            }
        } else if hours > 0 {
            if minutes > 0 {
                return "\(hours) giờ \(minutes) phút"
            } else {
                return "\(hours) giờ"
            }
        } else {
            return "\(max(1, minutes)) phút"
        }
    }

    /// Nội dung tóm tắt hiển thị thông báo sau khi nhập key thành công
    var successAlertSummary: String {
        var lines: [String] = []
        if !planName.isEmpty {
            lines.append("• Gói bản quyền: \(planName)")
        }
        lines.append("• Thời hạn còn lại: \(formattedRemainingTime)")
        if !expiresAtString.isEmpty {
            lines.append("• Hạn dùng đến: \(expiresAtString)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Keychain Persistence
    private static let keychainService = "com.cheatstore.vn.auth"
    private static let keychainDeviceIDKey = "unique_device_id"
    private static let keychainLicenseKey = "saved_license_key"

    private static func loadKeychainString(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }

    private static func saveKeychainString(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }

        var newItem = query
        attributes.forEach { newItem[$0.key] = $0.value }
        _ = SecItemAdd(newItem as CFDictionary, nil)
    }

    private static func deleteKeychainString(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Mã định danh duy nhất của thiết bị iOS (IDFV + Keychain persistence)
    var deviceID: String {
        // 1. Kiểm tra Keychain trước (không bị mất khi xóa và cài lại app)
        if let kcID = Self.loadKeychainString(key: Self.keychainDeviceIDKey), !kcID.isEmpty {
            if UserDefaults.standard.string(forKey: storageKeyDeviceID) != kcID {
                UserDefaults.standard.set(kcID, forKey: storageKeyDeviceID)
            }
            return kcID
        }
        // 2. Kiểm tra UserDefaults
        if let stored = UserDefaults.standard.string(forKey: storageKeyDeviceID), !stored.isEmpty {
            Self.saveKeychainString(key: Self.keychainDeviceIDKey, value: stored)
            return stored
        }
        // 3. Tạo mới nếu chưa có
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: storageKeyDeviceID)
        Self.saveKeychainString(key: Self.keychainDeviceIDKey, value: id)
        return id
    }

    init() {
        self.rememberKey = UserDefaults.standard.object(forKey: storageKeyRememberKey) as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "cheatstore_remote_feature_config"),
           let saved = try? JSONDecoder().decode(FeatureMaintenanceConfig.self, from: data) {
            self.featureConfig = saved
        } else {
            self.featureConfig = FeatureMaintenanceConfig()
        }
        loadSavedStateAndAutoLogin()
    }

    // MARK: - 3.1. Khi mở App (Điền sẵn key nếu ghi nhớ, yêu cầu bấm Login để xác thực)
    private func loadSavedStateAndAutoLogin() {
        var savedKey = ""
        if rememberKey {
            savedKey = UserDefaults.standard.string(forKey: storageKeyLicense)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // Phục hồi từ Keychain nếu UserDefaults bị mất (ví dụ khi cài lại app)
            if savedKey.isEmpty, let kcKey = Self.loadKeychainString(key: Self.keychainLicenseKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !kcKey.isEmpty {
                savedKey = kcKey
            }
        }

        let savedPlan = UserDefaults.standard.string(forKey: storageKeyPlan) ?? "Gói VIP"
        let savedExpiryTimestamp = UserDefaults.standard.double(forKey: storageKeyExpiry)
        let savedExpiryStr = UserDefaults.standard.string(forKey: storageKeyExpiryStr) ?? ""
        let savedDaysLeft = UserDefaults.standard.double(forKey: storageKeyDaysLeft)
        let savedSecondsLeft = UserDefaults.standard.double(forKey: storageKeySecondsLeft)

        // Nếu có lưu key cũ, chỉ nạp vào bộ nhớ để điền sẵn vào ô đăng nhập
        if !savedKey.isEmpty {
            self.activeKey = savedKey
            self.planName = savedPlan
            self.daysLeft = savedDaysLeft
            self.secondsLeft = savedSecondsLeft
            self.expiresAtString = savedExpiryStr
            if savedExpiryTimestamp > 0 {
                self.expirationDate = Date(timeIntervalSince1970: savedExpiryTimestamp)
            }
        }

        // Luôn để isActivated = false khi khởi động app:
        // Key được tự động điền sẵn trong ô nhập, người dùng bấm nút Đăng Nhập để gửi verify lên server
        self.isActivated = false
    }

    /// Kiểm tra ngầm trạng thái key với máy chủ khi mở ứng dụng
    @MainActor
    func performSilentAutoVerification(key: String) async {
        self.isAutoChecking = true
        defer { self.isAutoChecking = false }

        let success = await verifyWithServer(key: key, isSilent: true)
        if !success {
            print("[CheatStoreLicense] Auto-login ngầm không hợp lệ, đã chuyển về màn hình nhập key.")
        } else {
            print("[CheatStoreLicense] Auto-login ngầm thành công với key: \(key)")
        }
    }

    // MARK: - 3.2. Xác thực thiết bị hiện tại (dùng cho nút Kiểm tra lại khi bảo trì)
    @MainActor
    func verifyCurrentDevice() async -> Bool {
        var keyToCheck = activeKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if keyToCheck.isEmpty {
            keyToCheck = UserDefaults.standard.string(forKey: storageKeyLicense)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        if keyToCheck.isEmpty {
            keyToCheck = Self.loadKeychainString(key: Self.keychainLicenseKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        if !keyToCheck.isEmpty {
            return await verifyWithServer(key: keyToCheck, isSilent: true)
        }
        return false
    }

    // MARK: - 3.3. Khi người dùng kích hoạt Key
    func activateKey(_ keyInput: String) async -> Bool {
        await verifyWithServer(key: keyInput, isSilent: false)
    }

    /// Gửi request đến API kèm theo mã key và IDFV của máy
    @discardableResult
    func verifyWithServer(key keyInput: String, isSilent: Bool) async -> Bool {
        let trimmedKey = keyInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedKey.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Vui lòng nhập mã key!"
            }
            return false
        }

        if !isSilent {
            await MainActor.run {
                self.isVerifying = true
                self.errorMessage = nil
            }
        }

        defer {
            if !isSilent {
                Task { @MainActor in
                    self.isVerifying = false
                }
            }
        }

        // Tạo URL GET: https://cheatingenginexyz.online/api.php?action=verify&key=...&device_id=...&app_version=...
        var components = URLComponents(string: apiBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: fixedAction),
            URLQueryItem(name: "key", value: trimmedKey),
            URLQueryItem(name: "device_id", value: deviceID),
            URLQueryItem(name: "app_version", value: AppUpdateChecker.currentVersion)
        ]

        guard let requestURL = components?.url else {
            await MainActor.run {
                self.errorMessage = "Đường dẫn máy chủ không hợp lệ!"
            }
            return false
        }

        // 1. Kiểm tra chống Proxy Bypass nếu có proxy đang nghe lén
        if Self.isSystemProxyDetected() {
            print("[CheatStoreLicense] Cảnh báo: Phát hiện System Proxy đang hoạt động trên máy.")
        }

        // 2. Chữ ký HMAC-SHA256
        let timestamp = Int64(Date().timeIntervalSince1970)
        let signature = Self.generateHMACSignature(key: trimmedKey, deviceID: deviceID, timestamp: timestamp, secret: hmacSecret)

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("CheatStore/\(AppUpdateChecker.currentVersion) (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Timestamp")
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-Id")

        do {
            let (data, response) = try await secureURLSession.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            // Giải mã JSON từ phản hồi server (kể cả khi statusCode = 400, 403, 404, 426)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Tự động đồng bộ trạng thái mở khoá / bảo trì tính năng từ server
                self.updateFeatureConfig(from: json)
                let status = (json["status"] as? String ?? "").lowercased()
                let code = json["code"] as? String ?? ""
                let message = json["message"] as? String

                // Kiểm tra nếu server yêu cầu cập nhật phiên bản (chặn bản cũ)
                if statusCode == 426 || code.uppercased() == "UPDATE_REQUIRED" {
                    let updateURL = json["update_url"] as? String ?? "https://cheatingenginexyz.online/update.php"
                    let msg = message ?? "Phiên bản bạn đang sử dụng đã cũ và đã ngừng hỗ trợ. Vui lòng tải bản cập nhật mới nhất!"
                    await MainActor.run {
                        self.errorMessage = msg
                        AppUpdateChecker.shared.isForceUpdateRequired = true
                        AppUpdateChecker.shared.updateInfo = RemoteAppUpdateInfo(
                            status: "error",
                            has_update: true,
                            force_update: true,
                            client_version: AppUpdateChecker.currentVersion,
                            client_build: AppUpdateChecker.currentBuild,
                            latest_version: (json["latest_version"] as? String) ?? "2.3",
                            latest_build: nil,
                            min_version: nil,
                            update_url: updateURL,
                            title: "Yêu Cầu Cập Nhật Phiên Bản Mới",
                            message: msg,
                            changelog: nil
                        )
                        self.deactivate(withReason: msg)
                    }
                    return false
                }

                // Kiểm tra nếu server đang BẢO TRÌ (HTTP 503 hoặc code == "SERVER_MAINTENANCE" hoặc status == "maintenance")
                if statusCode == 503 || code.uppercased() == "SERVER_MAINTENANCE" || status == "maintenance" {
                    let title = json["title"] as? String ?? "Hệ Thống Đang Bảo Trì"
                    let badge = json["badge"] as? String ?? "CheatStoreVN"
                    let msg = message ?? "Đội ngũ kỹ thuật đang nâng cấp hệ thống để mang lại trải nghiệm tốt nhất."
                    let duration = json["estimated_duration"] as? String ?? "Khoảng 15 - 30 Phút"
                    let discord = json["discord_url"] as? String ?? "https://discord.gg/A3wS4ZPFQn"

                    await MainActor.run {
                        let info = AppMaintenanceInfo(
                            isActive: true,
                            badge: badge,
                            title: title,
                            message: msg,
                            estimatedDuration: duration,
                            discordURL: discord
                        )
                        self.maintenanceInfo = info
                        self.isMaintenanceActive = true
                        self.errorMessage = msg
                        AppUpdateChecker.shared.isMaintenanceActive = true
                        AppUpdateChecker.shared.maintenanceInfo = info
                    }
                    return false
                }

                if status == "success" || code.uppercased() == "KEY_VALID" {
                    // a. Khi KEY HỢP LỆ (Status Code 200)
                    let package = json["package"] as? String ?? "Gói VIP"
                    let expiresAtStr = json["expires_at"] as? String ?? ""
                    let activatedAtStr = json["activated_at"] as? String ?? ""
                    let secondsLeft = (json["seconds_left"] as? NSNumber)?.doubleValue
                        ?? Double("\(json["seconds_left"] ?? "")") ?? 0
                    let daysLeftVal = (json["days_left"] as? NSNumber)?.doubleValue
                        ?? Double("\(json["days_left"] ?? "")") ?? (secondsLeft > 0 ? (secondsLeft / 86400.0) : 0)

                    let expiryDate = parseExpiryDate(expiresAtStr: expiresAtStr, secondsLeft: secondsLeft)

                    await MainActor.run {
                        self.saveSuccessfulActivation(
                            key: trimmedKey,
                            package: package,
                            expiryDate: expiryDate,
                            expiresAtStr: expiresAtStr,
                            activatedAtStr: activatedAtStr,
                            secondsLeft: secondsLeft,
                            daysLeft: daysLeftVal,
                            activateImmediately: isSilent
                        )
                    }
                    return true
                } else {
                    // b. Khi BỊ LỖI HOẶC TỪ CHỐI (KEY_BANNED, DEVICE_MISMATCH, KEY_EXPIRED, INVALID_KEY, MISSING_KEY,...)
                    let detailedMsg = message ?? self.mapErrorCodeToMessage(code: code)
                    await MainActor.run {
                        if isSilent {
                            // Server trả về "error" (hết hạn hoặc bị thu hồi): Xóa key cũ khỏi máy và yêu cầu nhập key mới
                            self.deactivate(withReason: detailedMsg)
                        } else {
                            self.errorMessage = detailedMsg
                        }
                    }
                    return false
                }
            } else {
                let errorMsg = (statusCode == 200)
                    ? "Dữ liệu máy chủ không đúng định dạng!"
                    : "Máy chủ phản hồi lỗi (Mã: \(statusCode))"
                await MainActor.run {
                    if isSilent {
                        self.deactivate(withReason: errorMsg)
                    } else {
                        self.errorMessage = errorMsg
                    }
                }
                return false
            }
        } catch {
            // Lỗi kết nối mạng
            await MainActor.run {
                if isSilent {
                    // Nếu đang auto-login ngầm mà mất mạng, kiểm tra thời hạn lưu trước đó
                    if let exp = self.expirationDate, exp > Date() {
                        print("[CheatStoreLicense] Mất mạng tạm thời khi auto-login, dùng bản quyền lưu trong máy.")
                    } else {
                        self.deactivate(withReason: "Không thể kết nối máy chủ xác thực. Vui lòng kiểm tra mạng!")
                    }
                } else {
                    self.errorMessage = "Lỗi kết nối máy chủ: \(error.localizedDescription)"
                }
            }
            return false
        }
    }

    private func parseExpiryDate(expiresAtStr: String?, secondsLeft: Double?) -> Date {
        if let expiresAtStr = expiresAtStr, !expiresAtStr.isEmpty {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            df.locale = Locale(identifier: "en_US_POSIX")
            if let d = df.date(from: expiresAtStr) {
                return d
            }
        }
        if let secondsLeft = secondsLeft, secondsLeft > 0 {
            return Date().addingTimeInterval(secondsLeft)
        }
        return Date().addingTimeInterval(86400)
    }

    private func mapErrorCodeToMessage(code: String) -> String {
        switch code.uppercased() {
        case "KEY_BANNED":
            return "Key đã bị Admin thu hồi."
        case "DEVICE_MISMATCH":
            return "Key đã kích hoạt trên máy khác (liên hệ Admin để reset máy)."
        case "KEY_EXPIRED":
            return "Key đã hết hạn sử dụng."
        case "INVALID_KEY":
            return "Mã key không tồn tại trong kho hệ thống."
        case "MISSING_KEY":
            return "Thiếu mã key gửi lên máy chủ."
        case "MISSING_DEVICE":
            return "Thiếu mã định danh thiết bị (IDFV)."
        default:
            return "Xác thực không thành công (Mã: \(code))."
        }
    }

    @MainActor
    private func saveSuccessfulActivation(
        key: String,
        package: String,
        expiryDate: Date,
        expiresAtStr: String,
        activatedAtStr: String,
        secondsLeft: Double,
        daysLeft: Double,
        activateImmediately: Bool
    ) {
        if activateImmediately {
            self.isActivated = true
        }
        self.activeKey = key
        self.planName = package
        self.expirationDate = expiryDate
        self.expiresAtString = expiresAtStr
        self.activatedAtString = activatedAtStr
        self.secondsLeft = secondsLeft
        self.daysLeft = daysLeft
        self.errorMessage = nil

        UserDefaults.standard.set(true, forKey: storageKeyActivation)
        if rememberKey {
            UserDefaults.standard.set(key, forKey: storageKeyLicense)
            Self.saveKeychainString(key: Self.keychainLicenseKey, value: key)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKeyLicense)
            Self.deleteKeychainString(key: Self.keychainLicenseKey)
        }
        UserDefaults.standard.set(package, forKey: storageKeyPlan)
        UserDefaults.standard.set(expiryDate.timeIntervalSince1970, forKey: storageKeyExpiry)
        UserDefaults.standard.set(expiresAtStr, forKey: storageKeyExpiryStr)
        UserDefaults.standard.set(daysLeft, forKey: storageKeyDaysLeft)
        UserDefaults.standard.set(secondsLeft, forKey: storageKeySecondsLeft)
    }

    /// Xác nhận vào ứng dụng sau khi đã xem thông báo bản quyền thành công
    @MainActor
    func confirmActivation() {
        self.isActivated = true
    }

    func deactivate(withReason reason: String? = nil) {
        self.isActivated = false
        if !rememberKey {
            self.activeKey = ""
            UserDefaults.standard.removeObject(forKey: storageKeyLicense)
            Self.deleteKeychainString(key: Self.keychainLicenseKey)
        }
        self.planName = ""
        self.expirationDate = nil
        self.expiresAtString = ""
        self.activatedAtString = ""
        self.secondsLeft = 0
        self.daysLeft = 0
        self.errorMessage = reason

        UserDefaults.standard.removeObject(forKey: storageKeyActivation)
        UserDefaults.standard.removeObject(forKey: storageKeyPlan)
        UserDefaults.standard.removeObject(forKey: storageKeyExpiry)
        UserDefaults.standard.removeObject(forKey: storageKeyExpiryStr)
        UserDefaults.standard.removeObject(forKey: storageKeyDaysLeft)
        UserDefaults.standard.removeObject(forKey: storageKeySecondsLeft)
    }

    // MARK: - BẢO MẬT API (Chống Proxy Bypass & Chữ Ký HMAC-SHA256)
    /// URLSession Ephemeral vô hiệu hoá Proxy hệ thống (Chống can thiệp gói tin bằng Charles, HTTP Toolkit, Mitmproxy)
    private var secureURLSession: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.connectionProxyDictionary = [:] // Tắt hoàn toàn Proxy cấp OS
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 15
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }

    /// Phát hiện xem thiết bị có đang bị can thiệp bởi Proxy hệ thống không
    static func isSystemProxyDetected() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        if let httpEnable = proxySettings["HTTPEnable"] as? Int, httpEnable == 1 { return true }
        if let httpProxy = proxySettings["HTTPProxy"] as? String, !httpProxy.isEmpty { return true }
        if let httpsProxy = proxySettings["HTTPSProxy"] as? String, !httpsProxy.isEmpty { return true }
        if let pacEnable = proxySettings["ProxyAutoConfigEnable"] as? Int, pacEnable == 1 { return true }
        if let scoped = proxySettings["__SCOPED__"] as? [String: Any] {
            for (_, v) in scoped {
                if let dict = v as? [String: Any] {
                    if (dict["HTTPEnable"] as? Int == 1) || (dict["HTTPProxy"] != nil) || (dict["HTTPSProxy"] != nil) {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Tạo chữ ký bảo mật HMAC-SHA256 chống giả mạo request và chống Replay Attack
    static func generateHMACSignature(key: String, deviceID: String, timestamp: Int64, secret: String = "CheatStoreVN_Secret_2026") -> String {
        let payload = "\(key)|\(deviceID)|\(timestamp)"
        let keyData = secret.data(using: .utf8) ?? Data()
        let msgData = payload.data(using: .utf8) ?? Data()
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            msgData.withUnsafeBytes { msgBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyBytes.baseAddress, keyData.count,
                       msgBytes.baseAddress, msgData.count,
                       &hmac)
            }
        }
        return hmac.map { String(format: "%02hhx", $0) }.joined()
    }

    /// Cập nhật cấu hình tính năng & bảo trì từ phản hồi của máy chủ
    func updateFeatureConfig(from json: [String: Any]) {
        var updated = self.featureConfig
        var didChange = false

        if let features = json["features"] as? [String: Any] {
            if let v = features["aimneck"] as? Bool ?? features["aim"] as? Bool {
                updated.aimneck = v
                didChange = true
            }
            if let v = features["esp"] as? Bool {
                updated.esp = v
                didChange = true
            }
            if let v = features["skin"] as? Bool {
                updated.skin = v
                didChange = true
            }
            if let v = features["applestore_prime"] as? Bool ?? features["prime"] as? Bool {
                updated.applestore_prime = v
                didChange = true
            }
            if let msg = json["maintenance_message"] as? String {
                updated.maintenance_message = msg
                didChange = true
            }
        } else if let maint = json["maintenance"] as? [String: Any] {
            if let v = maint["aimneck"] as? Bool ?? maint["aim"] as? Bool {
                updated.aimneck = !v
                didChange = true
            }
            if let v = maint["esp"] as? Bool {
                updated.esp = !v
                didChange = true
            }
            if let v = maint["skin"] as? Bool {
                updated.skin = !v
                didChange = true
            }
            if let v = maint["applestore_prime"] as? Bool ?? maint["prime"] as? Bool {
                updated.applestore_prime = !v
                didChange = true
            }
            if let msg = json["maintenance_message"] as? String {
                updated.maintenance_message = msg
                didChange = true
            }
        }

        if didChange {
            Task { @MainActor in
                self.featureConfig = updated
                if let encoded = try? JSONEncoder().encode(updated) {
                    UserDefaults.standard.set(encoded, forKey: self.storageKeyFeatureConfig)
                }
            }
        }
    }

    /// Lấy cấu hình tính năng từ xa từ Server
    func fetchRemoteFeatureConfig() async {
        guard let url = URL(string: "\(apiBaseURL)?action=config&device_id=\(deviceID)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 8
        req.setValue("CheatStore/\(AppUpdateChecker.currentVersion) (iOS)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let (data, _) = try? await secureURLSession.data(for: req),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            self.updateFeatureConfig(from: json)
        }
    }
}
