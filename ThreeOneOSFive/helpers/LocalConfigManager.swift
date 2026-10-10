import Foundation
import Combine

/// =========================================================================
/// LocalConfigManager
/// Quản lý file localConfig.json an toàn, bảo vệ toàn vẹn dữ liệu:
/// 1. Đọc và phân tích JSON chuẩn [String: Any].
/// 2. Giữ nguyên 100% các trường không chỉnh sửa, token, chữ ký sig, server flags.
/// 3. Sao lưu tự động (localConfig.json.bak) trước mỗi lần ghi.
/// 4. Ghi nguyên tử (Atomic write) chống hỏng file khi ứng dụng bị ngắt đột ngột.
/// 5. Xác thực JSON hợp lệ trước và sau khi ghi.
/// 6. Hỗ trợ khôi phục từ bản sao lưu dự phòng (Restore from Backup).
/// =========================================================================
public final class LocalConfigManager: ObservableObject {
    public static let shared = LocalConfigManager()

    // MARK: - Published State
    @Published public private(set) var rawConfig: [String: Any] = [:]
    @Published public var errorMessage: String? = nil
    @Published public var successMessage: String? = nil
    @Published public private(set) var lastSavedTime: Date? = nil
    @Published public private(set) var hasBackup: Bool = false
    @Published public private(set) var isLoaded: Bool = false

    // MARK: - Strongly-typed Published Properties for UI Binding
    // AIM Tab
    @Published public var fovSize: Double = 314 { didSet { updateField(key: "FovSize", value: Int(fovSize)) } }
    @Published public var aimTarget: Int = 0 { didSet { updateField(key: "AimTarget", value: aimTarget) } }
    @Published public var aimEnabled: Bool = false { didSet { updateField(key: "AimEnabled", value: aimEnabled) } }
    @Published public var aimSystemEnabled: Bool = false { didSet { updateField(key: "AimSystemEnabled", value: aimSystemEnabled) } }
    @Published public var headshotRate: Double = 60 { didSet { updateField(key: "HeadshotRate", value: Int(headshotRate)) } }

    // ESP Tab
    @Published public var espMaster: Bool = false { didSet { updateField(key: "EspMaster", value: espMaster) } }
    @Published public var espName: Bool = false { didSet { updateField(key: "EspName", value: espName) } }
    @Published public var espDistance: Bool = false { didSet { updateField(key: "EspDistance", value: espDistance) } }
    @Published public var espBox: Bool = false { didSet { updateField(key: "EspBox", value: espBox) } }
    @Published public var espHealth: Bool = false { didSet { updateField(key: "EspHealth", value: espHealth) } }
    @Published public var espSkeleton: Bool = false { didSet { updateField(key: "EspSkeleton", value: espSkeleton) } }
    @Published public var espTracer: Bool = false { didSet { updateField(key: "EspTracer", value: espTracer) } }
    @Published public var espLine: Bool = false { didSet { updateField(key: "EspLine", value: espLine) } }
    @Published public var espFov: Bool = false { didSet { updateField(key: "EspFov", value: espFov) } }

    // MISC Tab
    @Published public var noRecoil: Bool = false { didSet { updateField(key: "NoRecoil", value: noRecoil) } }
    @Published public var camXa: Bool = false { didSet { updateField(key: "CamXa", value: camXa) } }
    @Published public var camXaFloat: Double = 1.4 { didSet { updateField(key: "CamXaFloat", value: camXaFloat) } }
    @Published public var speedHack: Int = 1 { didSet { updateField(key: "SpeedHack", value: speedHack) } }
    @Published public var fastParachute: Bool = false { didSet { updateField(key: "FastParachute", value: fastParachute) } }
    @Published public var ghostMode: Bool = false { didSet { updateField(key: "GhostMode", value: ghostMode) } }
    @Published public var showGuestBtn: Bool = true { didSet { updateField(key: "ShowGuestBtn", value: showGuestBtn) } }
    @Published public var buffDame: Bool = false { didSet { updateField(key: "BuffDame", value: buffDame) } }

    // Internal lock to avoid circular updates when reading from disk
    private var isUpdatingFromDisk: Bool = false

    // MARK: - Paths (Bảo vệ bí mật trong Application Support, không để lộ ra Documents/Files app)
    public var configURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CheatStore", isDirectory: true)
        try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(".localConfig.json")
    }

    public var backupURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CheatStore", isDirectory: true)
        try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(".localConfig.json.bak")
    }

    public var bundledSeedURL: URL? {
        if let url = Bundle.main.url(forResource: "localConfig", withExtension: "json") {
            return url
        }
        if let url = Bundle.main.url(forResource: "localConfig", withExtension: "json", subdirectory: "AppCore/new123") {
            return url
        }
        return nil
    }

    // MARK: - Initialization
    public init() {
        cleanExposedDocumentsFiles()
        loadConfig()
    }

    /// Dọn sạch triệt để các file nhạy cảm và thư mục Patches khỏi Documents để tránh bị Files app quét thấy
    public func cleanExposedDocumentsFiles() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let exposedFiles = [
            "Assembly-CSharp-patch.bytes",
            "localConfig.json",
            "localConfig.json.bak",
            "localConfig_temp.json"
        ]
        
        for f in exposedFiles {
            let u = docs.appendingPathComponent(f)
            if fm.fileExists(atPath: u.path) {
                // Nếu config mới chưa có, di chuyển từ docs sang app support an toàn
                if f == "localConfig.json" && !fm.fileExists(atPath: configURL.path) {
                    try? fm.copyItem(at: u, to: configURL)
                }
                try? fm.removeItem(at: u)
            }
        }
        
        // Xóa thư mục Patches lạ
        let patchesDir = docs.appendingPathComponent("Patches")
        if fm.fileExists(atPath: patchesDir.path) {
            try? fm.removeItem(at: patchesDir)
        }
    }

    // MARK: - Load Configuration
    @discardableResult
    public func loadConfig() -> Bool {
        let fm = FileManager.default
        let targetURL = configURL

        // Check if file exists in Documents, otherwise seed from Bundle
        if !fm.fileExists(atPath: targetURL.path) {
            if let seed = bundledSeedURL, let seedData = try? Data(contentsOf: seed) {
                do {
                    try seedData.write(to: targetURL, options: .atomic)
                    print("[LocalConfigManager] Seeding initial localConfig.json to Documents from bundle.")
                } catch {
                    self.errorMessage = "Không thể tạo file cấu hình ban đầu: \(error.localizedDescription)"
                    return false
                }
            } else {
                self.errorMessage = "Không tìm thấy file localConfig.json trong hệ thống."
                return false
            }
        }

        // Check backup existence
        self.hasBackup = fm.fileExists(atPath: backupURL.path)

        do {
            let data = try Data(contentsOf: targetURL)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                self.errorMessage = "Dữ liệu localConfig.json không phải định dạng JSON Dictionary hợp lệ."
                return false
            }

            self.isUpdatingFromDisk = true
            self.rawConfig = json
            syncFieldsFromRaw(json)
            self.isUpdatingFromDisk = false

            self.isLoaded = true
            self.errorMessage = nil
            print("[LocalConfigManager] Đã tải thành công \(json.count) trường từ localConfig.json.")
            return true
        } catch {
            self.errorMessage = "Lỗi khi đọc file cấu hình: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Save Configuration Safely
    @discardableResult
    public func saveConfig() -> Bool {
        guard !rawConfig.isEmpty else {
            self.errorMessage = "Không thể lưu: Dữ liệu cấu hình đang rỗng."
            return false
        }

        let targetURL = configURL
        let backup = backupURL
        let fm = FileManager.default

        // 1. Tạo bản sao dự phòng (Backup) nếu file gốc đã tồn tại
        if fm.fileExists(atPath: targetURL.path) {
            do {
                if fm.fileExists(atPath: backup.path) {
                    try fm.removeItem(at: backup)
                }
                try fm.copyItem(at: targetURL, to: backup)
                self.hasBackup = true
            } catch {
                print("[LocalConfigManager] Cảnh báo tạo bản sao dự phòng: \(error.localizedDescription)")
            }
        }

        // 2. Kiểm tra JSON hợp lệ trước khi ghi (Pre-write validation)
        guard JSONSerialization.isValidJSONObject(rawConfig) else {
            self.errorMessage = "Cấu trúc dữ liệu không hợp lệ để mã hoá JSON."
            return false
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: rawConfig, options: [.prettyPrinted, .sortedKeys])
            
            // 3. Ghi file nguyên tử (Atomic write qua temporary file)
            let tempURL = targetURL.deletingLastPathComponent().appendingPathComponent("localConfig_temp.json")
            try data.write(to: tempURL, options: .atomic)

            // 4. Kiểm tra JSON sau khi ghi (Post-write verification)
            let verifyData = try Data(contentsOf: tempURL)
            let verifiedJSON = try JSONSerialization.jsonObject(with: verifyData, options: []) as? [String: Any]
            guard verifiedJSON != nil else {
                try? fm.removeItem(at: tempURL)
                self.errorMessage = "Xác thực sau khi ghi thất bại: File bị sai định dạng."
                return false
            }

            // Hoán đổi file tạm vào file chính thức
            _ = try fm.replaceItemAt(targetURL, withItemAt: tempURL)
            
            // Tự động đẩy cấu hình sang container Free Fire đang hoạt động trong thời gian thực
            syncToActiveGameContainers()

            self.lastSavedTime = Date()
            self.errorMessage = nil
            self.successMessage = "Đã lưu cấu hình thành công lúc \(formattedTime(Date()))"
            return true
        } catch {
            self.errorMessage = "Lỗi khi ghi file localConfig.json: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Real-Time Container Auto-Sync
    /// Tự động cập nhật trực tiếp vào thư mục Documents của game Free Fire
    /// Người dùng thay đổi bất kỳ thông số nào thì game nhận ngay lập tức, không cần out game hay nạp lại.
    public func syncToActiveGameContainers() {
        let currentRaw = self.rawConfig
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? JSONSerialization.data(withJSONObject: currentRaw, options: [.prettyPrinted, .sortedKeys]) else { return }
            let fm = FileManager.default
            var targetContainers: [URL] = []
            let targetBIDs = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
            for bid in targetBIDs {
                if let p = ContainerStore.resolveAppContainerPath(bundleID: bid) {
                    let u = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: p, isDirectory: true))
                    if !targetContainers.contains(u) { targetContainers.append(u) }
                }
            }
            for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
                if !targetContainers.contains(root) { targetContainers.append(root) }
            }
            if let ffPath = findFreeFireContainerPath() {
                let canonical = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: ffPath, isDirectory: true))
                if !targetContainers.contains(canonical) { targetContainers.append(canonical) }
            }

            for root in targetContainers {
                let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                let dstConfig = docDir.appendingPathComponent("localConfig.json")
                if fm.fileExists(atPath: docDir.path) {
                    try? data.write(to: dstConfig, options: .atomic)
                    try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstConfig.path)
                }
            }
        }
    }

    // MARK: - Restore from Backup
    @discardableResult
    public func restoreFromBackup() -> Bool {
        let fm = FileManager.default
        let targetURL = configURL
        let backup = backupURL

        guard fm.fileExists(atPath: backup.path) else {
            self.errorMessage = "Không có bản sao dự phòng để khôi phục."
            return false
        }

        do {
            let backupData = try Data(contentsOf: backup)
            guard let json = try JSONSerialization.jsonObject(with: backupData, options: []) as? [String: Any] else {
                self.errorMessage = "Bản sao dự phòng bị hỏng hoặc không đúng định dạng JSON."
                return false
            }

            // Sao chép đè bản sao dự phòng vào file chính
            if fm.fileExists(atPath: targetURL.path) {
                try fm.removeItem(at: targetURL)
            }
            try fm.copyItem(at: backup, to: targetURL)

            self.isUpdatingFromDisk = true
            self.rawConfig = json
            syncFieldsFromRaw(json)
            self.isUpdatingFromDisk = false

            // Đẩy bản sao lưu sang container game ngay lập tức
            syncToActiveGameContainers()

            self.errorMessage = nil
            self.successMessage = "Đã khôi phục cấu hình từ bản sao lưu dự phòng thành công."
            return true
        } catch {
            self.errorMessage = "Lỗi khi khôi phục từ bản sao dự phòng: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Field Synchronization
    private func updateField(key: String, value: Any) {
        guard !isUpdatingFromDisk else { return }
        rawConfig[key] = value
        // Tự động lưu an toàn khi người dùng tương tác
        saveConfig()
    }

    private func syncFieldsFromRaw(_ json: [String: Any]) {
        // AIM
        if let v = json["FovSize"] as? NSNumber { self.fovSize = v.doubleValue }
        if let v = json["AimTarget"] as? NSNumber { self.aimTarget = v.intValue }
        if let v = json["AimEnabled"] as? Bool { self.aimEnabled = v }
        if let v = json["AimSystemEnabled"] as? Bool { self.aimSystemEnabled = v }
        if let v = json["HeadshotRate"] as? NSNumber { self.headshotRate = v.doubleValue }

        // ESP
        if let v = json["EspMaster"] as? Bool { self.espMaster = v }
        if let v = json["EspName"] as? Bool { self.espName = v }
        if let v = json["EspDistance"] as? Bool { self.espDistance = v }
        if let v = json["EspBox"] as? Bool { self.espBox = v }
        if let v = json["EspHealth"] as? Bool { self.espHealth = v }
        if let v = json["EspSkeleton"] as? Bool { self.espSkeleton = v }
        if let v = json["EspTracer"] as? Bool { self.espTracer = v }
        if let v = json["EspLine"] as? Bool { self.espLine = v }
        if let v = json["EspFov"] as? Bool { self.espFov = v }

        // MISC
        if let v = json["NoRecoil"] as? Bool { self.noRecoil = v }
        if let v = json["CamXa"] as? Bool { self.camXa = v }
        if let v = json["CamXaFloat"] as? NSNumber { self.camXaFloat = v.doubleValue }
        if let v = json["SpeedHack"] as? NSNumber { self.speedHack = v.intValue }
        if let v = json["FastParachute"] as? Bool { self.fastParachute = v }
        if let v = json["GhostMode"] as? Bool { self.ghostMode = v }
        if let v = json["ShowGuestBtn"] as? Bool { self.showGuestBtn = v }
        if let v = json["BuffDame"] as? Bool { self.buffDame = v }
    }

    // MARK: - Unverified & Protected Fields Inspection
    /// Danh sách các trường nhạy cảm hoặc chưa xác minh để hiển thị trung thực trong UI
    public var unverifiedFields: [(key: String, value: String)] {
        let knownManagedKeys: Set<String> = [
            "FovSize", "AimTarget", "AimEnabled", "AimSystemEnabled", "HeadshotRate",
            "EspMaster", "EspName", "EspDistance", "EspBox", "EspHealth", "EspSkeleton", "EspTracer", "EspLine", "EspFov",
            "NoRecoil", "CamXa", "CamXaFloat", "SpeedHack", "FastParachute", "GhostMode", "ShowGuestBtn", "BuffDame"
        ]

        var list: [(key: String, value: String)] = []
        for (k, v) in rawConfig where !knownManagedKeys.contains(k) {
            list.append((key: k, value: "\(v)"))
        }
        return list.sorted { $0.key < $1.key }
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .medium
        return f.string(from: date)
    }
}
