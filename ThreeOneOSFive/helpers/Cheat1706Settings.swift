import Foundation
import SwiftUI
import Combine

/// Mô hình cấu hình chi tiết tái hiện chuẩn 100% từ cấu trúc CheatSettings của app "1706 Cheat (FFExternal)"
public final class Cheat1706Settings: ObservableObject {
    public static let shared = Cheat1706Settings()

    // MARK: - 1. AIMBOT & FOV SETTINGS
    @AppStorage("c1706_aimbot") public var aimbot: Bool = true
    @AppStorage("c1706_aimSilent") public var aimSilent: Bool = true
    @AppStorage("c1706_aimbotTarget") public var aimbotTargetRaw: Int = 0 // 0: Đầu (Head), 1: Cổ (Neck), 2: Ngực (Chest)
    @AppStorage("c1706_aimbotStrength") public var aimbotStrength: Double = 85.0
    @AppStorage("c1706_headshotRate") public var headshotRate: Double = 100.0
    @AppStorage("c1706_fovCircle") public var fovCircle: Bool = true
    @AppStorage("c1706_fovRadius") public var fovRadius: Double = 90.0
    @AppStorage("c1706_autoFire") public var autoFire: Bool = false
    @AppStorage("c1706_ignoreKnocked") public var ignoreKnocked: Bool = true
    @AppStorage("c1706_visibleOnly") public var visibleOnly: Bool = true
    @AppStorage("c1706_targetLine") public var targetLine: Bool = false

    // MARK: - 2. ESP VISUALS SETTINGS
    @AppStorage("c1706_espBox") public var espBox: Bool = true
    @AppStorage("c1706_espSkeleton") public var espSkeleton: Bool = true
    @AppStorage("c1706_espLine") public var espLine: Bool = true
    @AppStorage("c1706_espHealth") public var espHealth: Bool = true
    @AppStorage("c1706_espName") public var espName: Bool = true
    @AppStorage("c1706_espDistance") public var espDistance: Bool = true
    @AppStorage("c1706_tracerBottom") public var tracerBottom: Bool = false
    @AppStorage("c1706_enemyCounter") public var enemyCounter: Bool = true
    @AppStorage("c1706_enemyAlert360") public var enemyAlert360: Bool = true
    @AppStorage("c1706_enemyAlertRange") public var enemyAlertRange: Double = 150.0

    // MARK: - 3. MOVEMENT & COMBAT SETTINGS
    @AppStorage("c1706_speedHack") public var speedHack: Bool = false
    @AppStorage("c1706_speedMultiplier") public var speedMultiplier: Double = 1.3
    @AppStorage("c1706_fastFire") public var fastFire: Bool = true
    @AppStorage("c1706_noRecoil") public var noRecoil: Bool = true
    @AppStorage("c1706_bulletSpeed") public var bulletSpeed: Bool = true
    @AppStorage("c1706_fps144") public var fps144: Bool = true
    @AppStorage("c1706_buffDamage") public var buffDamage: Bool = false
    @AppStorage("c1706_ghostControl") public var ghostControl: Bool = false

    // MARK: - 4. STREAMPROOF & SECURITY
    @AppStorage("c1706_streamproof") public var streamproof: Bool = true

    // MARK: - Selected Target Game
    @AppStorage("c1706_selectedGameIndex") public var selectedGameIndex: Int = 0 // 0: Free Fire, 1: Free Fire MAX

    public var selectedGameBundleID: String {
        selectedGameIndex == 0 ? "com.dts.freefireth" : "com.dts.freefiremax"
    }

    public var selectedGameDisplayName: String {
        selectedGameIndex == 0 ? "Free Fire" : "Free Fire MAX"
    }

    public init() {}

    /// Xuất toàn bộ giá trị các nút gạt/thanh trượt thành file localConfig.json chuẩn
    public func generateLocalConfigData() -> Data {
        let dict: [String: Any] = [
            "aimbot": aimbot,
            "aimSilent": aimSilent,
            "aimbotTarget": aimbotTargetRaw == 0 ? "Head" : (aimbotTargetRaw == 1 ? "Neck" : "Chest"),
            "aimbotStrength": Int(aimbotStrength),
            "headshotRate": Int(headshotRate),
            "fovCircle": fovCircle,
            "fovRadius": Int(fovRadius),
            "autoFire": autoFire,
            "ignoreKnocked": ignoreKnocked,
            "visibleOnly": visibleOnly,
            "targetLine": targetLine,

            "espBox": espBox,
            "espSkeleton": espSkeleton,
            "espLine": espLine,
            "espHealth": espHealth,
            "espName": espName,
            "espDistance": espDistance,
            "tracerBottom": tracerBottom,
            "enemyCounter": enemyCounter,
            "enemyAlert360": enemyAlert360,
            "enemyAlertRange": Int(enemyAlertRange),

            "speedHack": speedHack,
            "speedMultiplier": speedMultiplier,
            "fastFire": fastFire,
            "noRecoil": noRecoil,
            "bulletSpeed": bulletSpeed,
            "fps144": fps144,
            "buffDamage": buffDamage,
            "ghostControl": ghostControl,
            "streamproof": streamproof,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) {
            return data
        }
        return Data("{\"testCodePatch\":true}\n".utf8)
    }

    /// Đặt lại toàn bộ cài đặt về mặc định
    public func resetToDefaults() {
        aimbot = true
        aimSilent = true
        aimbotTargetRaw = 0
        aimbotStrength = 85.0
        headshotRate = 100.0
        fovCircle = true
        fovRadius = 90.0
        autoFire = false
        ignoreKnocked = true
        visibleOnly = true
        targetLine = false

        espBox = true
        espSkeleton = true
        espLine = true
        espHealth = true
        espName = true
        espDistance = true
        tracerBottom = false
        enemyCounter = true
        enemyAlert360 = true
        enemyAlertRange = 150.0

        speedHack = false
        speedMultiplier = 1.3
        fastFire = true
        noRecoil = true
        bulletSpeed = true
        fps144 = true
        buffDamage = false
        ghostControl = false
        streamproof = true
    }
}
