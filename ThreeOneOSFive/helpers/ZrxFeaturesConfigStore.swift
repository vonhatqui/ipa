import SwiftUI
import Combine

/// Quản lý toàn bộ cấu hình tính năng Aimbot, ESP, Misc chuẩn từ Zrxipa
public final class ZrxFeaturesConfigStore: ObservableObject {
    public static let shared = ZrxFeaturesConfigStore()

    // MARK: - AIMBOT SETTINGS (Chuẩn Zrxipa)
    @AppStorage("zrx_aimbot_type") public var aimbotType: String = "Aimbot Silent" // Aimbot Silent, Aimbot Vector, Aim Silent
    @AppStorage("zrx_auto_head") public var autoHead: Bool = true
    @AppStorage("zrx_auto_pull_aim") public var autoPullAim: Bool = true
    @AppStorage("zrx_aim_bone") public var aimBone: String = "Đầu (Head)" // Đầu (Head), Cổ (Neck), Ngực (Chest)
    @AppStorage("zrx_fov_enabled") public var fovEnabled: Bool = true
    @AppStorage("zrx_fov_radius") public var fovRadius: Double = 120.0 // 30 - 360 px
    @AppStorage("zrx_fov_style") public var fovStyle: String = "Liền (Solid)" // Liền (Solid), Nét đứt (Dashed), Chấm (Dots)
    @AppStorage("zrx_hit_chance") public var hitChance: Double = 95.0 // 50% - 100%
    @AppStorage("zrx_head_pull_delay") public var headPullDelay: Double = 15.0 // 0 - 200 ms
    @AppStorage("zrx_head_pull_time") public var headPullTime: Double = 160.0 // 50 - 500 ms
    @AppStorage("zrx_aimbot_distance") public var aimbotDistance: Double = 160.0 // 20 - 300 m
    @AppStorage("zrx_ignore_knocked") public var ignoreKnocked: Bool = true

    // MARK: - ESP / VISUAL SETTINGS (Chuẩn Zrxipa)
    @AppStorage("zrx_esp_master") public var espMaster: Bool = true
    @AppStorage("zrx_esp_line") public var espLine: Bool = true
    @AppStorage("zrx_line_from") public var lineFrom: String = "Trên (Top)" // Trên (Top), Dưới (Bottom)
    @AppStorage("zrx_esp_box") public var espBox: Bool = true
    @AppStorage("zrx_esp_box_fill") public var espBoxFill: Bool = true
    @AppStorage("zrx_esp_name") public var espName: Bool = true
    @AppStorage("zrx_esp_health") public var espHealth: Bool = true
    @AppStorage("zrx_health_type") public var healthType: String = "Thanh Máu (Bar)" // Thanh Máu (Bar), Số % (Text)
    @AppStorage("zrx_esp_skeleton") public var espSkeleton: Bool = true
    @AppStorage("zrx_esp_distance") public var espDistance: Bool = true
    @AppStorage("zrx_max_distance") public var maxDistance: Double = 260.0 // 50 - 500 m
    @AppStorage("zrx_text_size") public var textSize: Double = 13.0 // 10 - 22
    @AppStorage("zrx_thickness_size") public var thicknessSize: Double = 2.0 // 1.0 - 4.5

    // MARK: - MISC FEATURES (Chuẩn Zrxipa)
    @AppStorage("zrx_no_recoil") public var noRecoil: Bool = true
    @AppStorage("zrx_no_reload") public var noReload: Bool = false
    @AppStorage("zrx_rapid_fire") public var rapidFire: Bool = true
    @AppStorage("zrx_speed_hacks") public var speedHacks: Bool = false
    @AppStorage("zrx_fast_medkit") public var fastMedkit: Bool = true
    @AppStorage("zrx_stream_proof") public var streamProof: Bool = true
    @AppStorage("zrx_anti_ban_mode") public var antiBanMode: Bool = true

    private init() {}

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
}
