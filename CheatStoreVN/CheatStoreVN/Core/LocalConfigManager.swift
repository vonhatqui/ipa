import Foundation
import Combine

/// =========================================================================
/// LocalConfigManager - Quản lý cấu hình localConfig.json an toàn & độc lập
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

    // MARK: - AIM Tab Properties
    @Published public var fovSize: Double = 314 { didSet { updateField(key: "FovSize", value: Int(fovSize)) } }
    @Published public var aimTarget: Int = 0 { didSet { updateField(key: "AimTarget", value: aimTarget) } }
    @Published public var aimEnabled: Bool = false { didSet { updateField(key: "AimEnabled", value: aimEnabled) } }
    @Published public var aimSystemEnabled: Bool = false { didSet { updateField(key: "AimSystemEnabled", value: aimSystemEnabled) } }
    @Published public var headshotRate: Double = 60 { didSet { updateField(key: "HeadshotRate", value: Int(headshotRate)) } }

    // MARK: - ESP Tab Properties
    @Published public var espMaster: Bool = false { didSet { updateField(key: "EspMaster", value: espMaster) } }
    @Published public var espName: Bool = false { didSet { updateField(key: "EspName", value: espName) } }
    @Published public var espDistance: Bool = false { didSet { updateField(key: "EspDistance", value: espDistance) } }
    @Published public var espBox: Bool = false { didSet { updateField(key: "EspBox", value: espBox) } }
    @Published public var espHealth: Bool = false { didSet { updateField(key: "EspHealth", value: espHealth) } }
    @Published public var espSkeleton: Bool = false { didSet { updateField(key: "EspSkeleton", value: espSkeleton) } }
    @Published public var espTracer: Bool = false { didSet { updateField(key: "EspTracer", value: espTracer) } }
    @Published public var espLine: Bool = false { didSet { updateField(key: "EspLine", value: espLine) } }
    @Published public var espFov: Bool = false { didSet { updateField(key: "EspFov", value: espFov) } }

    // MARK: - MISC Tab Properties
    @Published public var noRecoil: Bool = false { didSet { updateField(key: "NoRecoil", value: noRecoil) } }
    @Published public var camXa: Bool = false { didSet { updateField(key: "CamXa", value: camXa) } }
    @Published public var camXaFloat: Double = 1.4 { didSet { updateField(key: "CamXaFloat", value: camXaFloat) } }
    @Published public var speedHack: Int = 1 { didSet { updateField(key: "SpeedHack", value: speedHack) } }
    @Published public var fastParachute: Bool = false { didSet { updateField(key: "FastParachute", value: fastParachute) } }
    @Published public var ghostMode: Bool = false { didSet { updateField(key: "GhostMode", value: ghostMode) } }
    @Published public var showGuestBtn: Bool = true { didSet { updateField(key: "ShowGuestBtn", value: showGuestBtn) } }
    @Published public var buffDame: Bool = false { didSet { updateField(key: "BuffDame", value: buffDame) } }

    private var isUpdatingFromDisk: Bool = false

    // MARK: - Storage URLs
    public var configURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CheatStoreVN", isDirectory: true)
        try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(".localConfig.json")
    }

    public var backupURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CheatStoreVN", isDirectory: true)
        try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(".localConfig.json.bak")
    }

    public var bundledSeedURL: URL? {
        Bundle.main.url(forResource: "localConfig", withExtension: "json")
    }

    // MARK: - Initialization
    public init() {
        cleanExposedDocumentsFiles()
        loadConfig()
    }

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
                try? fm.removeItem(at: u)
            }
        }
    }

    // MARK: - Load Configuration
    public func loadConfig() {
        isUpdatingFromDisk = true
        defer { isUpdatingFromDisk = false }

        let fm = FileManager.default
        var data: Data? = nil

        if fm.fileExists(atPath: configURL.path) {
            data = try? Data(contentsOf: configURL)
        }

        if data == nil, let seedURL = bundledSeedURL, fm.fileExists(atPath: seedURL.path) {
            data = try? Data(contentsOf: seedURL)
            if let d = data {
                try? d.write(to: configURL, options: .atomic)
            }
        }

        hasBackup = fm.fileExists(atPath: backupURL.path)

        guard let validData = data else {
            rawConfig = [:]
            isLoaded = true
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: validData, options: []) as? [String: Any] {
                rawConfig = json
                applyRawToProperties(json)
                isLoaded = true
            }
        } catch {
            errorMessage = "Lỗi đọc file cấu hình: \(error.localizedDescription)"
            isLoaded = true
        }
    }

    private func applyRawToProperties(_ json: [String: Any]) {
        // AIM
        if let v = json["FovSize"] as? Double { fovSize = v }
        else if let v = json["FovSize"] as? Int { fovSize = Double(v) }

        if let v = json["AimTarget"] as? Int { aimTarget = v }
        if let v = json["AimEnabled"] as? Bool { aimEnabled = v }
        if let v = json["AimSystemEnabled"] as? Bool { aimSystemEnabled = v }

        if let v = json["HeadshotRate"] as? Double { headshotRate = v }
        else if let v = json["HeadshotRate"] as? Int { headshotRate = Double(v) }

        // ESP
        if let v = json["EspMaster"] as? Bool { espMaster = v }
        if let v = json["EspName"] as? Bool { espName = v }
        if let v = json["EspDistance"] as? Bool { espDistance = v }
        if let v = json["EspBox"] as? Bool { espBox = v }
        if let v = json["EspHealth"] as? Bool { espHealth = v }
        if let v = json["EspSkeleton"] as? Bool { espSkeleton = v }
        if let v = json["EspTracer"] as? Bool { espTracer = v }
        if let v = json["EspLine"] as? Bool { espLine = v }
        if let v = json["EspFov"] as? Bool { espFov = v }

        // MISC
        if let v = json["NoRecoil"] as? Bool { noRecoil = v }
        if let v = json["CamXa"] as? Bool { camXa = v }
        if let v = json["CamXaFloat"] as? Double { camXaFloat = v }
        if let v = json["SpeedHack"] as? Int { speedHack = v }
        if let v = json["FastParachute"] as? Bool { fastParachute = v }
        if let v = json["GhostMode"] as? Bool { ghostMode = v }
        if let v = json["ShowGuestBtn"] as? Bool { showGuestBtn = v }
        if let v = json["BuffDame"] as? Bool { buffDame = v }
    }

    private func updateField(key: String, value: Any) {
        guard !isUpdatingFromDisk else { return }
        rawConfig[key] = value
    }

    // MARK: - Save Configuration
    public func saveConfig() -> Bool {
        let fm = FileManager.default
        errorMessage = nil
        successMessage = nil

        if fm.fileExists(atPath: configURL.path) {
            try? fm.removeItem(at: backupURL)
            try? fm.copyItem(at: configURL, to: backupURL)
            hasBackup = true
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: rawConfig, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: configURL, options: .atomic)
            try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: configURL.path)

            lastSavedTime = Date()
            successMessage = "Đã lưu cấu hình thành công"
            return true
        } catch {
            errorMessage = "Lỗi lưu cấu hình: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore from Backup
    public func restoreFromBackup() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: backupURL.path) else {
            errorMessage = "Không tìm thấy bản sao lưu dự phòng"
            return false
        }

        do {
            try? fm.removeItem(at: configURL)
            try fm.copyItem(at: backupURL, to: configURL)
            loadConfig()
            successMessage = "Đã khôi phục thành công từ bản sao lưu"
            return true
        } catch {
            errorMessage = "Lỗi khôi phục sao lưu: \(error.localizedDescription)"
            return false
        }
    }
}
