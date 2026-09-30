import Foundation
import UIKit

/// Dịch vụ Injector đơn lập và tinh gọn dành riêng cho Apple IPA V2 (Main 2)
/// Hỗ trợ nạp độc lập từng chức năng trực tiếp từ bên ngoài mà không cần mở Menu trong game.
@MainActor
final class AppleIpaV2Injector: ObservableObject {
    static let shared = AppleIpaV2Injector()

    static let projectUUID = UUID(uuidString: "40F75F5F-E17F-4F24-8721-0870E7304A94")!

    // MARK: - 5 Chức Năng Độc Lập (Lưu bền vững qua UserDefaults)
    @Published var isAimbotEnabled: Bool {
        didSet { UserDefaults.standard.set(isAimbotEnabled, forKey: "cs_aimbot_enabled") }
    }
    @Published var isSilentAimEnabled: Bool {
        didSet { UserDefaults.standard.set(isSilentAimEnabled, forKey: "cs_silent_aim_enabled") }
    }
    @Published var isNoRecoilEnabled: Bool {
        didSet { UserDefaults.standard.set(isNoRecoilEnabled, forKey: "cs_no_recoil_enabled") }
    }
    @Published var isEspBoxLineEnabled: Bool {
        didSet { UserDefaults.standard.set(isEspBoxLineEnabled, forKey: "cs_esp_box_line_enabled") }
    }
    @Published var isEspNameDistEnabled: Bool {
        didSet { UserDefaults.standard.set(isEspNameDistEnabled, forKey: "cs_esp_name_dist_enabled") }
    }

    // MARK: - Trạng thái Hoạt Động
    @Published var isInjected: Bool = false
    @Published var isWorking: Bool = false
    @Published var statusMessage: String = "Sẵn sàng nạp vào game"
    @Published var detectedGameTitle: String = "Đang kiểm tra game..."
    @Published var hasDetectedGame: Bool = false

    private init() {
        self.isAimbotEnabled = UserDefaults.standard.object(forKey: "cs_aimbot_enabled") as? Bool ?? true
        self.isSilentAimEnabled = UserDefaults.standard.object(forKey: "cs_silent_aim_enabled") as? Bool ?? true
        self.isNoRecoilEnabled = UserDefaults.standard.object(forKey: "cs_no_recoil_enabled") as? Bool ?? true
        self.isEspBoxLineEnabled = UserDefaults.standard.object(forKey: "cs_esp_box_line_enabled") as? Bool ?? true
        self.isEspNameDistEnabled = UserDefaults.standard.object(forKey: "cs_esp_name_dist_enabled") as? Bool ?? true

        refreshStatus()
    }

    func refreshStatus() {
        let appliedIDs = DevicePatchService.allAppliedProjectIDs()
        self.isInjected = appliedIDs.contains(Self.projectUUID)

        let containers = DevicePatchService.allAvailableFreeFireContainers()
        if containers["com.dts.freefireth"] != nil && containers["com.dts.freefiremax"] != nil {
            self.detectedGameTitle = "Đã nhận Free Fire & Free Fire MAX"
            self.hasDetectedGame = true
        } else if containers["com.dts.freefiremax"] != nil {
            self.detectedGameTitle = "Đã nhận Free Fire MAX"
            self.hasDetectedGame = true
        } else if containers["com.dts.freefireth"] != nil {
            self.detectedGameTitle = "Đã nhận Free Fire (Bản chuẩn)"
            self.hasDetectedGame = true
        } else {
            self.detectedGameTitle = "Chưa phát hiện (Mở game 1 lần trước)"
            self.hasDetectedGame = false
        }
    }

    // MARK: - Ghi Bytecode Nhị Phân Chuẩn Little-Endian
    private static func writeInt32(_ data: inout Data, offset: Int, value: Int32) {
        guard offset + 4 <= data.count else { return }
        var leValue = value.littleEndian
        withUnsafeBytes(of: &leValue) { rawBuffer in
            data.replaceSubrange(offset..<(offset + 4), with: rawBuffer)
        }
    }

    /// Sử dụng trực tiếp dữ liệu nhị phân chuẩn đã được vẽ lại UI sắc nét
    static func generateCustomPatchData(
        from baseData: Data,
        aimbot: Bool,
        silentAim: Bool,
        noRecoil: Bool,
        espBoxLine: Bool,
        espNameDist: Bool
    ) -> Data {
        return baseData
    }

    // MARK: - Kích Hoạt Injector (1-Chạm)
    func performInject(completion: @escaping (Result<String, Error>) -> Void) {
        guard !isWorking else { return }
        self.isWorking = true
        self.statusMessage = "Đang xử lý & đóng gói dữ liệu nạp..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Tải bản mẫu gốc từ Bundle AppCore (đã vẽ lại UI menu nổi đẹp mắt)
                guard let bundledItem = PatchProjectLibrary.loadBundledItem(named: "lib_app_apple_ipa_v2"),
                      let baseProject = bundledItem.project,
                      let ifixRule = baseProject.rules.first(where: { $0.relativePath.contains("Assembly-CSharp-patch.bytes") }) else {
                    throw NSError(domain: "AppleIpaV2Injector", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy tệp gốc Apple IPA V2 trong AppCore."])
                }

                // 2. Lấy dữ liệu mã máy chuẩn giao diện mới đã biên dịch sẵn
                let customizedData = ifixRule.replacementData
                let localConfigData = "{\"testCodePatch\":true}".data(using: .utf8)!

                // 3. Cập nhật Project Patch tiêu chuẩn
                var project = baseProject
                project.id = Self.projectUUID
                project.name = "Apple IPA V2"
                project.author = "@AppleStoreVN"
                project.bundleIdentifiers = ["com.dts.freefireth"]
                project.rules = [
                    PatchRule(
                        id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                        bundleID: "com.dts.freefireth",
                        relativePath: "Documents/Assembly-CSharp-patch.bytes",
                        replacementFilename: "Assembly-CSharp-patch.bytes",
                        replacementData: customizedData
                    ),
                    PatchRule(
                        id: UUID(uuidString: "66666666-7777-8888-9999-000000000000")!,
                        bundleID: "com.dts.freefireth",
                        relativePath: "Documents/localConfig.json",
                        replacementFilename: "localConfig.json",
                        replacementData: localConfigData
                    )
                ]

                // 4. Áp dụng patch qua DevicePatchService (Tự động chụp Golden Snapshot và đồng bộ Free Fire MAX)
                _ = try DevicePatchService.apply(project: project)

                // 5. Đảm bảo khóa quyền bảo vệ file và chống reset khi vào trận
                DevicePatchService.ensureActivePatchesInjected()

                DispatchQueue.main.async {
                    self.isWorking = false
                    self.isInjected = true
                    self.statusMessage = "ĐÃ NẠP THÀNH CÔNG VÀO GAME!"
                    CheatStoreSoundManager.shared.playSuccessSound()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    completion(.success("Đã nạp thành công vào Free Fire! Khi vào trận, menu nổi thiết kế mới sẽ xuất hiện ở góc màn hình để bạn tự do bật/tắt."))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.statusMessage = "Lỗi khi nạp: \(error.localizedDescription)"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Khôi Phục Sạch (Gỡ Mod)
    func performCleanRestore(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isWorking else { return }
        self.isWorking = true
        self.statusMessage = "Đang khôi phục dữ liệu gốc..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let bundledItem = PatchProjectLibrary.loadBundledItem(named: "lib_app_apple_ipa_v2"),
                   let project = bundledItem.project {
                    if let receipt = DevicePatchService.latestReceipt(projectID: Self.projectUUID) {
                        try DevicePatchService.restore(receipt: receipt, project: project, allowChangedTargets: true)
                    } else {
                        DevicePatchService.forceCleanup(project: project)
                    }
                }

                // Dọn dẹp sạch các tệp mod trong container
                let containers = DevicePatchService.allAvailableFreeFireContainers()
                let fileManager = FileManager.default
                for (_, rootURL) in containers {
                    let docDir = rootURL.appendingPathComponent("Documents", isDirectory: true)
                    let patchFile = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
                    let cfgFile = docDir.appendingPathComponent("localConfig.json")
                    try? fileManager.removeItem(at: patchFile)
                    try? fileManager.removeItem(at: cfgFile)
                }

                DispatchQueue.main.async {
                    self.isWorking = false
                    self.isInjected = false
                    self.statusMessage = "Đã khôi phục sạch 100% dữ liệu gốc."
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.statusMessage = "Lỗi khôi phục: \(error.localizedDescription)"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Mở Game Trực Tiếp
    func launchGame() {
        let schemeStrings = ["freefire://", "freefireth://", "freefiremax://"]
        for scheme in schemeStrings {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        // Thử mở URL scheme cơ bản
        if let defaultURL = URL(string: "freefire://") {
            UIApplication.shared.open(defaultURL, options: [:], completionHandler: nil)
        }
    }
}
