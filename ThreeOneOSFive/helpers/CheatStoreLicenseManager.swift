import Foundation
import UIKit

final class CheatStoreLicenseManager: ObservableObject {
    static let shared = CheatStoreLicenseManager()

    @Published var isActivated: Bool = false
    @Published var activeKey: String = ""
    @Published var planName: String = ""
    @Published var expirationDate: Date?
    @Published var isVerifying: Bool = false
    @Published var errorMessage: String?

    private let endpointURL = URL(string: "https://cheatingenginexyz.online/api.php")!
    private let botApiKey = "cheatstore_bot_secret_token_2026"
    private let storageKeyActivation = "cheatstore_is_activated"
    private let storageKeyLicense = "cheatstore_license_key"
    private let storageKeyPlan = "cheatstore_plan_name"
    private let storageKeyExpiry = "cheatstore_expiry_timestamp"
    private let storageKeyDeviceID = "cheatstore_device_id"

    var deviceID: String {
        if let stored = UserDefaults.standard.string(forKey: storageKeyDeviceID), !stored.isEmpty {
            return stored
        }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: storageKeyDeviceID)
        return id
    }

    init() {
        loadSavedState()
    }

    private func loadSavedState() {
        let savedKey = UserDefaults.standard.string(forKey: storageKeyLicense) ?? ""
        let savedPlan = UserDefaults.standard.string(forKey: storageKeyPlan) ?? "VIP"
        let savedExpiryTimestamp = UserDefaults.standard.double(forKey: storageKeyExpiry)
        let savedActivated = UserDefaults.standard.bool(forKey: storageKeyActivation)

        if savedActivated, !savedKey.isEmpty {
            if savedExpiryTimestamp > 0 {
                let expiry = Date(timeIntervalSince1970: savedExpiryTimestamp)
                if expiry < Date() {
                    deactivate(withReason: "Key bản quyền của bạn đã hết hạn!")
                    return
                }
                self.expirationDate = expiry
            }
            self.activeKey = savedKey
            self.planName = savedPlan
            self.isActivated = true
        }
    }

    func activateKey(_ keyInput: String) async -> Bool {
        let trimmedKey = keyInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedKey.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Vui lòng nhập mã Key của bạn!"
            }
            return false
        }

        await MainActor.run {
            self.isVerifying = true
            self.errorMessage = nil
        }

        defer {
            Task { @MainActor in
                self.isVerifying = false
            }
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let postBody = [
            "api_key=\(botApiKey)",
            "action=check",
            "key=\(trimmedKey)",
            "hwid=\(deviceID)"
        ].joined(separator: "&")

        request.httpBody = postBody.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.errorMessage = "Không thể kết nối đến máy chủ xác thực!"
                }
                return false
            }

            if httpResponse.statusCode != 200 {
                await MainActor.run {
                    self.errorMessage = "Máy chủ phản hồi lỗi (Mã: \(httpResponse.statusCode))"
                }
                return false
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let status = json["status"] as? String ?? ""
                if status == "success" {
                    let plan = json["plan"] as? String ?? "Gói VIP"
                    let name = json["name"] as? String ?? plan
                    let duration = json["duration"] as? String ?? "1 Ngày"
                    
                    await MainActor.run {
                        self.saveActivation(key: trimmedKey, plan: name, durationText: duration)
                        self.isActivated = true
                        self.activeKey = trimmedKey
                        self.planName = name
                    }
                    return true
                } else {
                    let msg = json["message"] as? String ?? "Mã Key không chính xác hoặc đã hết hạn!"
                    await MainActor.run {
                        self.errorMessage = msg
                    }
                    return false
                }
            } else {
                await MainActor.run {
                    self.saveActivation(key: trimmedKey, plan: "Gói VIP 30 Ngày", durationText: "30 Ngày")
                    self.isActivated = true
                    self.activeKey = trimmedKey
                    self.planName = "Gói VIP"
                }
                return true
            }
        } catch {
            if self.isActivated && self.activeKey == trimmedKey {
                return true
            }
            await MainActor.run {
                self.errorMessage = "Lỗi kết nối mạng: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func saveActivation(key: String, plan: String, durationText: String) {
        var days: Double = 30
        let lower = durationText.lowercased()
        if lower.contains("1 ngày") || lower.contains("1ngay") {
            days = 1
        } else if lower.contains("7 ngày") || lower.contains("7ngay") {
            days = 7
        } else if lower.contains("1 tháng") || lower.contains("1thang") || lower.contains("30 ngày") {
            days = 30
        } else if lower.contains("3 tháng") || lower.contains("3thang") || lower.contains("90 ngày") {
            days = 90
        }

        let expiry = Date().addingTimeInterval(days * 86400)
        self.expirationDate = expiry

        UserDefaults.standard.set(true, forKey: storageKeyActivation)
        UserDefaults.standard.set(key, forKey: storageKeyLicense)
        UserDefaults.standard.set(plan, forKey: storageKeyPlan)
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: storageKeyExpiry)
    }

    func deactivate(withReason reason: String? = nil) {
        self.isActivated = false
        self.activeKey = ""
        self.planName = ""
        self.expirationDate = nil
        self.errorMessage = reason

        UserDefaults.standard.removeObject(forKey: storageKeyActivation)
        UserDefaults.standard.removeObject(forKey: storageKeyLicense)
        UserDefaults.standard.removeObject(forKey: storageKeyPlan)
        UserDefaults.standard.removeObject(forKey: storageKeyExpiry)
    }
}
