import Foundation
import UIKit
import Combine

/// Dịch vụ quản lý cấu hình và Inject External ESP (Only ESP Headless Engine) cho CheatStore VN
/// Điều khiển độc lập từng tính năng thông qua file nhị phân .pdata và Preferences của Free Fire
public final class ExternalESPConfigService: ObservableObject {
    public static let shared = ExternalESPConfigService()

    // MARK: - Đường dẫn tương đối file cấu hình trong game
    private static let pdataRelativePath = "contentcache/Compulsory/ios/gameassetbundles/ingame/.pdata"

    // MARK: - Keys lưu trữ UserDefaults
    private enum Keys {
        static let espMaster = "ext_esp_master"
        static let espLine = "ext_esp_line"
        static let espBox = "ext_esp_box"
        static let boxType = "ext_esp_box_type"
        static let espName = "ext_esp_name"
        static let espDistance = "ext_esp_distance"
        static let espHealth = "ext_esp_health"
        static let healthType = "ext_esp_health_type"
        static let espSkeleton = "ext_esp_skeleton"
        static let drawCountEnemies = "ext_esp_count_enemies"
        static let textSize = "ext_esp_text_size"
        static let thicknessSize = "ext_esp_thickness_size"
        static let isInjected = "ext_esp_is_injected"
        static let targetGame = "ext_esp_target_game" // "ff" or "max"
        static let autoSync = "ext_esp_auto_sync"

        // Aimbot & Misc states
        static let aimMaster = "ext_aim_master"
        static let aimBone = "ext_aim_bone"
        static let aimMode = "ext_aim_mode"
        static let aimFov = "ext_aim_fov"
        static let aimSmooth = "ext_aim_smooth"
        static let silentAim = "ext_aim_silent"
        static let autoFire = "ext_aim_autofire"
        static let antibanMaster = "ext_misc_antiban"
        static let safeMode = "ext_misc_safemode"
        static let fastMedikit = "ext_misc_fastmed"
        static let fastParachute = "ext_misc_fastpara"
        static let wallThrough = "ext_misc_wallthrough"
    }

    // MARK: - Published Properties cho UI binding (Visual Tab)
    @Published public var espMaster: Bool {
        didSet {
            UserDefaults.standard.set(espMaster, forKey: Keys.espMaster)
            syncIfInjected()
        }
    }
    @Published public var espLine: Bool {
        didSet {
            UserDefaults.standard.set(espLine, forKey: Keys.espLine)
            syncIfInjected()
        }
    }
    @Published public var espBox: Bool {
        didSet {
            UserDefaults.standard.set(espBox, forKey: Keys.espBox)
            syncIfInjected()
        }
    }
    @Published public var boxType: Int { // 0: Cornered, 1: 2D Bounding
        didSet {
            UserDefaults.standard.set(boxType, forKey: Keys.boxType)
            syncIfInjected()
        }
    }
    @Published public var espName: Bool {
        didSet {
            UserDefaults.standard.set(espName, forKey: Keys.espName)
            syncIfInjected()
        }
    }
    @Published public var espDistance: Bool {
        didSet {
            UserDefaults.standard.set(espDistance, forKey: Keys.espDistance)
            syncIfInjected()
        }
    }
    @Published public var espHealth: Bool {
        didSet {
            UserDefaults.standard.set(espHealth, forKey: Keys.espHealth)
            syncIfInjected()
        }
    }
    @Published public var healthType: Int { // 0: Right, 1: Left
        didSet {
            UserDefaults.standard.set(healthType, forKey: Keys.healthType)
            syncIfInjected()
        }
    }
    @Published public var espSkeleton: Bool {
        didSet {
            UserDefaults.standard.set(espSkeleton, forKey: Keys.espSkeleton)
            syncIfInjected()
        }
    }
    @Published public var drawCountEnemies: Bool {
        didSet {
            UserDefaults.standard.set(drawCountEnemies, forKey: Keys.drawCountEnemies)
            syncIfInjected()
        }
    }
    @Published public var textSize: Float {
        didSet {
            UserDefaults.standard.set(textSize, forKey: Keys.textSize)
            syncIfInjected()
        }
    }
    @Published public var thicknessSize: Float {
        didSet {
            UserDefaults.standard.set(thicknessSize, forKey: Keys.thicknessSize)
            syncIfInjected()
        }
    }

    // MARK: - Published Properties (Aimbot & Misc Tabs)
    @Published public var aimMaster: Bool {
        didSet { UserDefaults.standard.set(aimMaster, forKey: Keys.aimMaster) }
    }
    @Published public var aimBone: Int { // 0: Đầu, 1: Cổ, 2: Ngực
        didSet { UserDefaults.standard.set(aimBone, forKey: Keys.aimBone) }
    }
    @Published public var aimMode: Int { // 0: Auto Lock, 1: Ngắm Mới Khóa, 2: Bắn Mới Khóa
        didSet { UserDefaults.standard.set(aimMode, forKey: Keys.aimMode) }
    }
    @Published public var aimFov: Float {
        didSet { UserDefaults.standard.set(aimFov, forKey: Keys.aimFov) }
    }
    @Published public var aimSmooth: Float {
        didSet { UserDefaults.standard.set(aimSmooth, forKey: Keys.aimSmooth) }
    }
    @Published public var silentAim: Bool {
        didSet { UserDefaults.standard.set(silentAim, forKey: Keys.silentAim) }
    }
    @Published public var autoFire: Bool {
        didSet { UserDefaults.standard.set(autoFire, forKey: Keys.autoFire) }
    }
    @Published public var antibanMaster: Bool {
        didSet { UserDefaults.standard.set(antibanMaster, forKey: Keys.antibanMaster) }
    }
    @Published public var safeMode: Bool {
        didSet { UserDefaults.standard.set(safeMode, forKey: Keys.safeMode) }
    }
    @Published public var fastMedikit: Bool {
        didSet { UserDefaults.standard.set(fastMedikit, forKey: Keys.fastMedikit) }
    }
    @Published public var fastParachute: Bool {
        didSet { UserDefaults.standard.set(fastParachute, forKey: Keys.fastParachute) }
    }
    @Published public var wallThrough: Bool {
        didSet { UserDefaults.standard.set(wallThrough, forKey: Keys.wallThrough) }
    }

    // MARK: - Trạng thái hệ thống
    @Published public var isInjected: Bool {
        didSet { UserDefaults.standard.set(isInjected, forKey: Keys.isInjected) }
    }
    @Published public var targetGame: String { // "ff" or "max"
        didSet { UserDefaults.standard.set(targetGame, forKey: Keys.targetGame) }
    }
    @Published public var autoSync: Bool {
        didSet { UserDefaults.standard.set(autoSync, forKey: Keys.autoSync) }
    }
    @Published public var isInjecting: Bool = false
    @Published public var lastStatusMessage: String = ""

    // MARK: - Initializer với giá trị mặc định chuẩn từ ảnh mẫu
    private init() {
        let defaults = UserDefaults.standard
        self.espMaster = defaults.object(forKey: Keys.espMaster) != nil ? defaults.bool(forKey: Keys.espMaster) : true
        self.espLine = defaults.object(forKey: Keys.espLine) != nil ? defaults.bool(forKey: Keys.espLine) : true
        self.espBox = defaults.object(forKey: Keys.espBox) != nil ? defaults.bool(forKey: Keys.espBox) : true
        self.boxType = defaults.integer(forKey: Keys.boxType) // 0: Cornered, 1: 2D Bounding
        self.espName = defaults.object(forKey: Keys.espName) != nil ? defaults.bool(forKey: Keys.espName) : true
        self.espDistance = defaults.object(forKey: Keys.espDistance) != nil ? defaults.bool(forKey: Keys.espDistance) : true
        self.espHealth = defaults.object(forKey: Keys.espHealth) != nil ? defaults.bool(forKey: Keys.espHealth) : true
        self.healthType = defaults.integer(forKey: Keys.healthType) // 0: Right, 1: Left
        self.espSkeleton = defaults.object(forKey: Keys.espSkeleton) != nil ? defaults.bool(forKey: Keys.espSkeleton) : true
        self.drawCountEnemies = defaults.object(forKey: Keys.drawCountEnemies) != nil ? defaults.bool(forKey: Keys.drawCountEnemies) : true

        let savedTextSize = defaults.float(forKey: Keys.textSize)
        self.textSize = savedTextSize > 0 ? savedTextSize : 1.0
        let savedThickness = defaults.float(forKey: Keys.thicknessSize)
        self.thicknessSize = savedThickness > 0 ? savedThickness : 1.0

        self.aimMaster = defaults.object(forKey: Keys.aimMaster) != nil ? defaults.bool(forKey: Keys.aimMaster) : true
        self.aimBone = defaults.integer(forKey: Keys.aimBone)
        self.aimMode = defaults.integer(forKey: Keys.aimMode)
        let savedFov = defaults.float(forKey: Keys.aimFov)
        self.aimFov = savedFov > 0 ? savedFov : 90.0
        let savedSmooth = defaults.float(forKey: Keys.aimSmooth)
        self.aimSmooth = savedSmooth > 0 ? savedSmooth : 5.0
        self.silentAim = defaults.bool(forKey: Keys.silentAim)
        self.autoFire = defaults.bool(forKey: Keys.autoFire)

        self.antibanMaster = defaults.object(forKey: Keys.antibanMaster) != nil ? defaults.bool(forKey: Keys.antibanMaster) : true
        self.safeMode = defaults.object(forKey: Keys.safeMode) != nil ? defaults.bool(forKey: Keys.safeMode) : true
        self.fastMedikit = defaults.bool(forKey: Keys.fastMedikit)
        self.fastParachute = defaults.bool(forKey: Keys.fastParachute)
        self.wallThrough = defaults.bool(forKey: Keys.wallThrough)

        self.isInjected = defaults.bool(forKey: Keys.isInjected)
        self.targetGame = defaults.string(forKey: Keys.targetGame) ?? "ff"
        self.autoSync = defaults.object(forKey: Keys.autoSync) != nil ? defaults.bool(forKey: Keys.autoSync) : true
    }

    // MARK: - Tự động đồng bộ cấu hình nếu đã inject
    private func syncIfInjected() {
        guard autoSync && isInjected else { return }
        updateLiveConfiguration()
    }

    // MARK: - Ghi cấu hình Live cực nhanh (.pdata + PlayerPrefs)
    @discardableResult
    public func updateLiveConfiguration() -> Bool {
        let allContainers = DevicePatchService.allAvailableFreeFireContainers()
        guard !allContainers.isEmpty else { return false }

        let pdataBytes = buildPDataBuffer()
        let pdataData = Data(pdataBytes)
        let fileManager = FileManager.default

        for (_, root) in allContainers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let pdataDir = docDir.appendingPathComponent("contentcache/Compulsory/ios/gameassetbundles/ingame", isDirectory: true)
            try? fileManager.createDirectory(at: pdataDir, withIntermediateDirectories: true)
            let pdataDst = pdataDir.appendingPathComponent(".pdata")

            try? pdataData.write(to: pdataDst, options: .atomic)
            try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: pdataDst.path)

            // Cập nhật Preferences plist
            updatePreferences(containerRoot: root)
        }
        return true
    }

    // MARK: - Nạp toàn bộ Engine Only ESP và khởi động Game
    @discardableResult
    public func applyConfigurationAndLaunch(launchAfterInject: Bool = true) -> Bool {
        DispatchQueue.main.async { self.isInjecting = true }

        let fileManager = FileManager.default
        let allContainers = DevicePatchService.allAvailableFreeFireContainers()
        guard !allContainers.isEmpty else {
            let msg = "Không tìm thấy thư mục game Free Fire hoặc Free Fire MAX"
            print("[ExternalESP] ⚠️ \(msg)")
            DispatchQueue.main.async {
                self.isInjecting = false
                self.lastStatusMessage = msg
            }
            return false
        }

        // 1. Chuẩn bị file patch Only ESP (51,976 bytes)
        guard let patchSourceURL = findOnlyESPPatchURL() else {
            let msg = "Không tìm thấy file patch Only ESP trong ứng dụng"
            print("[ExternalESP] ⚠️ \(msg)")
            DispatchQueue.main.async {
                self.isInjecting = false
                self.lastStatusMessage = msg
            }
            return false
        }

        let configSourceURL = findOnlyESPConfigURL()
        let pdataData = Data(buildPDataBuffer())
        var totalSuccess = 0

        for (bundleID, root) in allContainers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let patchDst = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let configDst = docDir.appendingPathComponent("localConfig.json")

            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)

            // Copy file patch
            try? fileManager.removeItem(at: patchDst)
            do {
                try fileManager.copyItem(at: patchSourceURL, to: patchDst)
                if let cfg = configSourceURL {
                    try? fileManager.removeItem(at: configDst)
                    try? fileManager.copyItem(at: cfg, to: configDst)
                } else {
                    let defaultCfg = Data("{\"testCodePatch\":true}\n".utf8)
                    try? defaultCfg.write(to: configDst, options: .atomic)
                }
            } catch {
                print("[ExternalESP] Lỗi copy patch vào \(bundleID): \(error)")
                continue
            }

            // Ghi file .pdata
            let pdataDir = docDir.appendingPathComponent("contentcache/Compulsory/ios/gameassetbundles/ingame", isDirectory: true)
            try? fileManager.createDirectory(at: pdataDir, withIntermediateDirectories: true)
            let pdataDst = pdataDir.appendingPathComponent(".pdata")

            try? pdataData.write(to: pdataDst, options: .atomic)

            // Cập nhật Preferences plist
            updatePreferences(containerRoot: root)

            // Quyền hạn & Chống iCloud backup
            var uPatch = patchDst
            var uConfig = configDst
            var uPdata = pdataDst
            var resVals = URLResourceValues()
            resVals.isExcludedFromBackup = true
            try? uPatch.setResourceValues(resVals)
            try? uConfig.setResourceValues(resVals)
            try? uPdata.setResourceValues(resVals)
            try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: patchDst.path)
            try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: configDst.path)
            try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: pdataDst.path)

            totalSuccess += 1
            print("[ExternalESP] ✅ Đã nạp thành công vào \(bundleID)")
        }

        let success = totalSuccess > 0
        DispatchQueue.main.async {
            self.isInjecting = false
            self.isInjected = success
            self.lastStatusMessage = success
                ? "Inject thành công vào \(totalSuccess) game! Đang mở Free Fire..."
                : "Không thể nạp dữ liệu vào game"
        }

        if success && launchAfterInject {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.launchGame()
            }
        }

        return success
    }

    // MARK: - Khôi phục sạch sẽ game (Uninject)
    @discardableResult
    public func uninjectExternal() -> Bool {
        let fileManager = FileManager.default
        let allContainers = DevicePatchService.allAvailableFreeFireContainers()
        var cleanedCount = 0

        for (_, root) in allContainers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let patchDst = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let configDst = docDir.appendingPathComponent("localConfig.json")
            let pdataDst = docDir.appendingPathComponent("contentcache/Compulsory/ios/gameassetbundles/ingame/.pdata")

            try? fileManager.removeItem(at: patchDst)
            try? fileManager.removeItem(at: configDst)
            try? fileManager.removeItem(at: pdataDst)

            // Tắt các giá trị ESP trong Plist
            clearPreferences(containerRoot: root)
            cleanedCount += 1
        }

        DispatchQueue.main.async {
            self.isInjected = false
            self.lastStatusMessage = "Đã gỡ bỏ toàn bộ cheat, game sạch 100%"
        }
        return cleanedCount > 0
    }

    // MARK: - Mở Game (Free Fire TH hoặc Free Fire MAX)
    public func launchGame() {
        let scheme = (targetGame == "max") ? "freefiremax://" : "freefire://"
        if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            let fallbackScheme = (targetGame == "max") ? "freefire://" : "freefiremax://"
            if let url = URL(string: fallbackScheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    // MARK: - Xây dựng buffer nhị phân 64-byte cho file .pdata
    private func buildPDataBuffer() -> [UInt8] {
        var pdataBytes = [UInt8](repeating: 0, count: 64)

        // Magic header: "PDAT"
        pdataBytes[0] = 0x50
        pdataBytes[1] = 0x44
        pdataBytes[2] = 0x41
        pdataBytes[3] = 0x54

        if espMaster {
            // Colors default: RGB White
            pdataBytes[4] = 255
            pdataBytes[5] = 255
            pdataBytes[6] = 255
            pdataBytes[7] = 255

            // Byte 8: Line Toggle (esp_lt)
            pdataBytes[8] = espLine ? 1 : 0

            // Byte 9: Skeleton Toggle (esp_sk)
            pdataBytes[9] = espSkeleton ? 1 : 0

            // Byte 10: Box Type (esp_bt: 1 = Cornered, 2 = 2D Bounding)
            pdataBytes[10] = espBox ? UInt8(boxType == 0 ? 1 : 2) : 0

            // Byte 11: Box Toggle
            pdataBytes[11] = espBox ? 1 : 0

            // Byte 14: Name Toggle (esp_nt)
            pdataBytes[14] = espName ? 1 : 0

            // Byte 15: Distance Toggle
            pdataBytes[15] = espDistance ? 1 : 0

            // Byte 16: Health Toggle
            pdataBytes[16] = espHealth ? 1 : 0

            // Byte 17: Health Type (0 = Right, 1 = Left)
            pdataBytes[17] = UInt8(healthType)

            // Byte 18: Skeleton secondary
            pdataBytes[18] = espSkeleton ? 1 : 0

            // Byte 19: Count Enemies Toggle (esp_neg)
            pdataBytes[19] = drawCountEnemies ? 1 : 0

            // Byte 39: Thickness Size (esp_r8, giá trị nhân 10)
            let clampedThickness = max(5, min(50, Int(thicknessSize * 10)))
            pdataBytes[39] = UInt8(clampedThickness)

            // Byte 40: Text Size (esp_tv, giá trị nhân 10)
            let clampedText = max(5, min(50, Int(textSize * 10)))
            pdataBytes[40] = UInt8(clampedText)
        }

        return pdataBytes
    }

    // MARK: - Cập nhật Preferences Plist
    private func updatePreferences(containerRoot: URL) {
        let prefsDir = containerRoot.appendingPathComponent("Library/Preferences", isDirectory: true)
        try? FileManager.default.createDirectory(at: prefsDir, withIntermediateDirectories: true)

        let plistTargets = [
            prefsDir.appendingPathComponent("com.dts.freefireth.plist"),
            prefsDir.appendingPathComponent("com.dts.freefiremax.plist"),
            prefsDir.appendingPathComponent("com.dts.freefire.plist")
        ]

        for plistURL in plistTargets {
            var dict: [String: Any] = (NSDictionary(contentsOf: plistURL) as? [String: Any]) ?? [:]

            if espMaster {
                dict["esp_lt"] = espLine ? 1.0 : 0.0
                dict["esp_bt"] = espBox ? (boxType == 0 ? 1.0 : 2.0) : 0.0
                dict["esp_nt"] = espName ? 1.0 : 0.0
                dict["esp_sk"] = espSkeleton ? 1.0 : 0.0
                dict["esp_neg"] = drawCountEnemies ? 1.0 : 0.0
                dict["esp_tv"] = textSize
                dict["esp_r8"] = thicknessSize
                dict["esp_ca"] = 1.0
                dict["esp_cb"] = 1.0
                dict["esp_cc"] = 1.0
                dict["esp_cd"] = 1.0
            } else {
                dict["esp_lt"] = 0.0
                dict["esp_bt"] = 0.0
                dict["esp_nt"] = 0.0
                dict["esp_sk"] = 0.0
                dict["esp_neg"] = 0.0
            }

            let nsDict = NSDictionary(dictionary: dict)
            nsDict.write(to: plistURL, atomically: true)
        }
    }

    // MARK: - Xóa sạch Preferences khi Uninject
    private func clearPreferences(containerRoot: URL) {
        let prefsDir = containerRoot.appendingPathComponent("Library/Preferences", isDirectory: true)
        let plistTargets = [
            prefsDir.appendingPathComponent("com.dts.freefireth.plist"),
            prefsDir.appendingPathComponent("com.dts.freefiremax.plist"),
            prefsDir.appendingPathComponent("com.dts.freefire.plist")
        ]

        for plistURL in plistTargets {
            guard var dict = (NSDictionary(contentsOf: plistURL) as? [String: Any]) else { continue }
            dict["esp_lt"] = 0.0
            dict["esp_bt"] = 0.0
            dict["esp_nt"] = 0.0
            dict["esp_sk"] = 0.0
            dict["esp_neg"] = 0.0
            dict.removeValue(forKey: "esp_tv")
            dict.removeValue(forKey: "esp_r8")
            let nsDict = NSDictionary(dictionary: dict)
            nsDict.write(to: plistURL, atomically: true)
        }
    }

    // MARK: - Tìm kiếm file patch Only ESP trong Bundle
    private func findOnlyESPPatchURL() -> URL? {
        let fileManager = FileManager.default
        var searchURLs: [URL] = []

        if let resURL = Bundle.main.resourceURL {
            searchURLs.append(resURL.appendingPathComponent("BundledPatches/OnlyESP/Documents/Assembly-CSharp-patch.bytes"))
            searchURLs.append(resURL.appendingPathComponent("BundledPatches/OnlyESP/Assembly-CSharp-patch.bytes"))
            searchURLs.append(resURL.appendingPathComponent("AppCore/OnlyESP/Assembly-CSharp-patch.bytes"))
            searchURLs.append(resURL.appendingPathComponent("AppCore/Assembly-CSharp-patch.bytes"))
        }

        searchURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/OnlyESP/Documents/Assembly-CSharp-patch.bytes"))
        searchURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/OnlyESP/Assembly-CSharp-patch.bytes"))
        searchURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/OnlyESP/Assembly-CSharp-patch.bytes"))
        searchURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/Assembly-CSharp-patch.bytes"))

        // Thư mục cục bộ dự phòng
        searchURLs.append(URL(fileURLWithPath: "D:/appmoi/only esp.3105"))
        searchURLs.append(URL(fileURLWithPath: "D:/update_file/ipa-main/ThreeOneOSFive/BundledPatches/OnlyESP/Assembly-CSharp-patch.bytes"))

        for url in searchURLs {
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    private func findOnlyESPConfigURL() -> URL? {
        let fileManager = FileManager.default
        var searchURLs: [URL] = []

        if let resURL = Bundle.main.resourceURL {
            searchURLs.append(resURL.appendingPathComponent("BundledPatches/OnlyESP/Documents/localConfig.json"))
            searchURLs.append(resURL.appendingPathComponent("BundledPatches/OnlyESP/localConfig.json"))
        }

        searchURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/OnlyESP/Documents/localConfig.json"))
        searchURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/OnlyESP/localConfig.json"))
        searchURLs.append(URL(fileURLWithPath: "D:/update_file/ipa-main/ThreeOneOSFive/BundledPatches/OnlyESP/localConfig.json"))

        for url in searchURLs {
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }
}
