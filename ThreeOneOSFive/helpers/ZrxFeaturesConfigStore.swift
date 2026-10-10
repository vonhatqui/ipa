import SwiftUI
import Combine
import UIKit

/// Quản lý toàn bộ cấu hình tính năng Aimbot, ESP, Misc chuẩn từ Zrxipa
/// Tích hợp cầu nối Real-Time Engine Hook vào Free Fire (.pdata, Preferences, localConfig.json, Assembly-CSharp-patch)
public final class ZrxFeaturesConfigStore: ObservableObject {
    public static let shared = ZrxFeaturesConfigStore()

    // MARK: - AIMBOT SETTINGS (Chuẩn Zrxipa)
    @AppStorage("zrx_aimbot_type") public var aimbotType: String = "Aimbot Silent" {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_auto_head") public var autoHead: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_auto_pull_aim") public var autoPullAim: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_aim_bone") public var aimBone: String = "Đầu (Head)" {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_fov_enabled") public var fovEnabled: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_fov_radius") public var fovRadius: Double = 120.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_fov_style") public var fovStyle: String = "Liền (Solid)" {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_hit_chance") public var hitChance: Double = 95.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_head_pull_delay") public var headPullDelay: Double = 15.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_head_pull_time") public var headPullTime: Double = 160.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_aimbot_distance") public var aimbotDistance: Double = 160.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_ignore_knocked") public var ignoreKnocked: Bool = true {
        didSet { syncToGameEngine() }
    }

    // MARK: - ESP / VISUAL SETTINGS (Chuẩn Zrxipa)
    @AppStorage("zrx_esp_master") public var espMaster: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_line") public var espLine: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_line_from") public var lineFrom: String = "Trên (Top)" {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_box") public var espBox: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_box_fill") public var espBoxFill: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_name") public var espName: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_health") public var espHealth: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_health_type") public var healthType: String = "Thanh Máu (Bar)" {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_skeleton") public var espSkeleton: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_esp_distance") public var espDistance: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_max_distance") public var maxDistance: Double = 260.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_text_size") public var textSize: Double = 13.0 {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_thickness_size") public var thicknessSize: Double = 2.0 {
        didSet { syncToGameEngine() }
    }

    // MARK: - MISC FEATURES (Chuẩn Zrxipa)
    @AppStorage("zrx_no_recoil") public var noRecoil: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_no_reload") public var noReload: Bool = false {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_rapid_fire") public var rapidFire: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_speed_hacks") public var speedHacks: Bool = false {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_fast_medkit") public var fastMedkit: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_stream_proof") public var streamProof: Bool = true {
        didSet { syncToGameEngine() }
    }
    @AppStorage("zrx_anti_ban_mode") public var antiBanMode: Bool = true {
        didSet { syncToGameEngine() }
    }

    // MARK: - Status
    @Published public var isInjecting: Bool = false
    @Published public var lastSyncMessage: String = "Sẵn sàng kết nối"
    @Published public var isEngineSynced: Bool = true

    private init() {
        // Đồng bộ lần đầu khi khởi động
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.syncToGameEngine()
        }
    }

    // MARK: - Thống kê trạng thái tính năng
    public var activeAimbotCount: Int {
        var count = 0
        if autoHead { count += 1 }
        if autoPullAim { count += 1 }
        if fovEnabled { count += 1 }
        if ignoreKnocked { count += 1 }
        return count
    }

    public var totalAimbotCount: Int { 4 }

    public var activeEspCount: Int {
        guard espMaster else { return 0 }
        var count = 0
        if espLine { count += 1 }
        if espBox { count += 1 }
        if espBoxFill { count += 1 }
        if espName { count += 1 }
        if espHealth { count += 1 }
        if espSkeleton { count += 1 }
        if espDistance { count += 1 }
        return count
    }

    public var totalEspCount: Int { 7 }

    public var activeMiscCount: Int {
        var count = 0
        if noRecoil { count += 1 }
        if noReload { count += 1 }
        if rapidFire { count += 1 }
        if speedHacks { count += 1 }
        if fastMedkit { count += 1 }
        if streamProof { count += 1 }
        if antiBanMode { count += 1 }
        return count
    }

    public var totalMiscCount: Int { 7 }

    // MARK: - Đồng bộ Live vào Game Engine (.pdata, Preferences, localConfig.json)
    public func syncToGameEngine() {
        let espService = ExternalESPConfigService.shared

        // 1. Ánh xạ sang ExternalESPConfigService
        espService.espMaster = espMaster
        espService.espLine = espLine
        espService.espBox = espBox
        espService.boxType = espBoxFill ? 1 : 0
        espService.espName = espName
        espService.espDistance = espDistance
        espService.espHealth = espHealth
        espService.healthType = healthType.contains("Bar") ? 0 : 1
        espService.espSkeleton = espSkeleton
        espService.drawCountEnemies = true
        espService.textSize = Float(textSize)
        espService.thicknessSize = Float(thicknessSize)

        // Aimbot settings
        espService.aimMaster = (autoHead || autoPullAim)
        espService.silentAim = (aimbotType.contains("Silent"))
        espService.aimBone = aimBone.contains("Cổ") ? 1 : (aimBone.contains("Ngực") ? 2 : 0)
        espService.aimFov = Float(fovRadius)
        espService.aimSmooth = Float(headPullDelay)

        // Misc settings
        espService.antibanMaster = antiBanMode
        espService.safeMode = streamProof
        espService.fastMedikit = fastMedkit

        // Cập nhật Live binary buffer .pdata và Plist Preferences
        _ = espService.updateLiveConfiguration()

        // 2. Ghi đè localConfig.json vào Documents của toàn bộ containers
        writeStructuredLocalConfig()

        DispatchQueue.main.async {
            self.isEngineSynced = true
            self.lastSyncMessage = "Đã đồng bộ Live (.pdata + localConfig)"
        }
    }

    // MARK: - Ghi cấu hình localConfig.json chi tiết
    private func writeStructuredLocalConfig() {
        let fileManager = FileManager.default
        let containers = DevicePatchService.allAvailableFreeFireContainers()

        let configDict: [String: Any] = [
            "testCodePatch": true,
            "resetGuest": true,
            "aimbot": [
                "enabled": autoHead || autoPullAim,
                "type": aimbotType,
                "autoHead": autoHead,
                "autoPull": autoPullAim,
                "bone": aimBone,
                "fovRadius": fovRadius,
                "fovStyle": fovStyle,
                "hitChance": hitChance,
                "delay": headPullDelay,
                "pullTime": headPullTime,
                "distance": aimbotDistance,
                "ignoreKnocked": ignoreKnocked
            ],
            "esp": [
                "master": espMaster,
                "line": espLine,
                "lineFrom": lineFrom,
                "box": espBox,
                "boxFill": espBoxFill,
                "name": espName,
                "health": espHealth,
                "healthType": healthType,
                "skeleton": espSkeleton,
                "distance": espDistance,
                "maxDistance": maxDistance,
                "textSize": textSize,
                "thickness": thicknessSize
            ],
            "misc": [
                "noRecoil": noRecoil,
                "noReload": noReload,
                "rapidFire": rapidFire,
                "speedHacks": speedHacks,
                "fastMedkit": fastMedkit,
                "streamProof": streamProof,
                "antiBan": antiBanMode
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: configDict, options: [.prettyPrinted]) else {
            return
        }

        for (_, root) in containers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
            let configURL = docDir.appendingPathComponent("localConfig.json")

            try? fileManager.removeItem(at: configURL)
            try? jsonData.write(to: configURL, options: .atomic)

            var uConfig = configURL
            var resVals = URLResourceValues()
            resVals.isExcludedFromBackup = true
            try? uConfig.setResourceValues(resVals)
            try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: configURL.path)
        }
    }

    // MARK: - Nạp toàn bộ tính năng và Payload Patch vào Free Fire
    @discardableResult
    public func applyAndInjectAllToGame(completion: ((Bool, String) -> Void)? = nil) -> Bool {
        isInjecting = true
        defer { isInjecting = false }

        // Mở container permissions
        let targetBIDs = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
        for bid in targetBIDs {
            _ = ContainerStore.resolveAppContainerPath(bundleID: bid)
        }

        // 1. Đồng bộ cấu hình Live
        syncToGameEngine()

        // 2. Nạp Patch qua CheatVNPatchService
        let patchOK = CheatVNPatchService.shared.applyPatch(injectCheatVN: true, injectEspAimSilent: true)

        // 3. Nạp Only ESP runtime nếu cần
        _ = ExternalESPConfigService.shared.applyConfigurationAndLaunch(launchAfterInject: false)

        // 4. Khóa bảo vệ Active Patches
        DevicePatchService.ensureActivePatchesInjected()

        let msg = patchOK ? "✅ Đã nạp thành công toàn bộ chức năng Zrxipa vào game!" : "⚠️ Nạp xong với cảnh báo (vui lòng kiểm tra quyền container)."
        DispatchQueue.main.async {
            self.lastSyncMessage = msg
            completion?(patchOK, msg)
        }
        return patchOK
    }

    // MARK: - Mở game Free Fire
    public func launchFreeFire() {
        let schemes = ["freefire://", "freefiremax://"]
        for s in schemes {
            if let url = URL(string: s), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        if let fallback = URL(string: "freefire://") {
            UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
        }
    }
}
