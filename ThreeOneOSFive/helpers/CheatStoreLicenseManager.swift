import Foundation
import UIKit

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

    // 1. THÔNG TIN KẾT NỐI API
    private let apiBaseURL = "https://cheatingenginexyz.online/api.php"
    private let fixedAction = "verify"

    // Các key lưu trữ trong UserDefaults
    private let storageKeyActivation = "cheatstore_is_activated"
    private let storageKeyLicense = "cheatstore_license_key"
    private let storageKeyPlan = "cheatstore_plan_name"
    private let storageKeyExpiry = "cheatstore_expiry_timestamp"
    private let storageKeyExpiryStr = "cheatstore_expiry_date_str"
    private let storageKeyDaysLeft = "cheatstore_days_left"
    private let storageKeySecondsLeft = "cheatstore_seconds_left"
    private let storageKeyDeviceID = "cheatstore_device_id"

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

    /// Mã định danh duy nhất của thiết bị iOS (IDFV)
    var deviceID: String {
        if let stored = UserDefaults.standard.string(forKey: storageKeyDeviceID), !stored.isEmpty {
            return stored
        }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: storageKeyDeviceID)
        return id
    }

    init() {
        loadSavedStateAndAutoLogin()
    }

    // MARK: - 3.1. Khi mở App (Auto-login ngầm)
    private func loadSavedStateAndAutoLogin() {
        let savedKey = UserDefaults.standard.string(forKey: storageKeyLicense)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let savedPlan = UserDefaults.standard.string(forKey: storageKeyPlan) ?? "Gói VIP"
        let savedExpiryTimestamp = UserDefaults.standard.double(forKey: storageKeyExpiry)
        let savedExpiryStr = UserDefaults.standard.string(forKey: storageKeyExpiryStr) ?? ""
        let savedActivated = UserDefaults.standard.bool(forKey: storageKeyActivation)
        let savedDaysLeft = UserDefaults.standard.double(forKey: storageKeyDaysLeft)
        let savedSecondsLeft = UserDefaults.standard.double(forKey: storageKeySecondsLeft)

        // Kiểm tra trong bộ nhớ máy xem có lưu key cũ hay không
        if savedActivated, !savedKey.isEmpty {
            self.activeKey = savedKey
            self.planName = savedPlan
            self.daysLeft = savedDaysLeft
            self.secondsLeft = savedSecondsLeft
            self.expiresAtString = savedExpiryStr
            if savedExpiryTimestamp > 0 {
                self.expirationDate = Date(timeIntervalSince1970: savedExpiryTimestamp)
            }
            self.isActivated = true

            // ĐÃ CÓ KEY: Tự động gửi API kiểm tra ngầm với máy chủ
            Task { @MainActor in
                await self.performSilentAutoVerification(key: savedKey)
            }
        } else {
            // CHƯA CÓ KEY: Chưa kích hoạt
            self.isActivated = false
        }
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

    // MARK: - 3.2. Khi người dùng kích hoạt Key
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

        // Tạo URL GET: https://cheatingenginexyz.online/api.php?action=verify&key=...&device_id=...
        var components = URLComponents(string: apiBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: fixedAction),
            URLQueryItem(name: "key", value: trimmedKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]

        guard let requestURL = components?.url else {
            await MainActor.run {
                self.errorMessage = "Đường dẫn máy chủ không hợp lệ!"
            }
            return false
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("CheatStore/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            // Giải mã JSON từ phản hồi server (kể cả khi statusCode = 400, 403, 404)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let status = (json["status"] as? String ?? "").lowercased()
                let code = json["code"] as? String ?? ""
                let message = json["message"] as? String

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
        UserDefaults.standard.set(key, forKey: storageKeyLicense)
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
        self.activeKey = ""
        self.planName = ""
        self.expirationDate = nil
        self.expiresAtString = ""
        self.activatedAtString = ""
        self.secondsLeft = 0
        self.daysLeft = 0
        self.errorMessage = reason

        UserDefaults.standard.removeObject(forKey: storageKeyActivation)
        UserDefaults.standard.removeObject(forKey: storageKeyLicense)
        UserDefaults.standard.removeObject(forKey: storageKeyPlan)
        UserDefaults.standard.removeObject(forKey: storageKeyExpiry)
        UserDefaults.standard.removeObject(forKey: storageKeyExpiryStr)
        UserDefaults.standard.removeObject(forKey: storageKeyDaysLeft)
        UserDefaults.standard.removeObject(forKey: storageKeySecondsLeft)
    }
}
