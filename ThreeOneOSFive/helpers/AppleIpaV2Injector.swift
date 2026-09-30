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

    /// Tùy biến mã máy IL bytecode trực tiếp theo đúng 5 cờ chức năng được bật/tắt (Thread-safe)
    static func generateCustomPatchData(
        from baseData: Data,
        aimbot: Bool,
        silentAim: Bool,
        noRecoil: Bool,
        espBoxLine: Bool,
        espNameDist: Bool
    ) -> Data {
        var bytes = baseData
        guard bytes.count >= 40600 else { return baseData }

        // 1. LOẠI BỎ MENU TRONG GAME (100% không còn menu GUI, nút bấm hay watermark)
        // Instruction 1376 tại byte offset 20895: Đổi thành Opcode 136 (Ret), Operand 0
        writeInt32(&bytes, offset: 20895, value: 136) // Ret
        writeInt32(&bytes, offset: 20899, value: 0)

        // 2. CHỐNG GIẬT SÚNG NO RECOIL (Method #3 tại byte offset 9439)
        if noRecoil {
            // Ldc_R4 0.0f; Ret 1 (Triệt tiêu độ tản đạn & giật = 0.0f)
            writeInt32(&bytes, offset: 9439, value: 3)   // Ldc_R4
            writeInt32(&bytes, offset: 9443, value: 0)   // 0.0f
            writeInt32(&bytes, offset: 9447, value: 136) // Ret
            writeInt32(&bytes, offset: 9451, value: 1)   // 1 value
        } else {
            // Ldc_R4 1.0f; Ret 1 (Độ giật bình thường 1.0f)
            writeInt32(&bytes, offset: 9439, value: 3)          // Ldc_R4
            writeInt32(&bytes, offset: 9443, value: 1065353216) // 1.0f bit pattern
            writeInt32(&bytes, offset: 9447, value: 136)        // Ret
            writeInt32(&bytes, offset: 9451, value: 1)          // 1 value
        }

        // 3. ĐẠN MA THUẬT SILENT AIM (Method #13 tại byte offset 32903)
        if !silentAim {
            // ldnull; Ret 1 (Tắt hoàn toàn silent aim, đạn bay tự nhiên)
            writeInt32(&bytes, offset: 32903, value: 28)  // ldnull
            writeInt32(&bytes, offset: 32907, value: 0)
            writeInt32(&bytes, offset: 32911, value: 136) // Ret
            writeInt32(&bytes, offset: 32915, value: 1)
        } else {
            // Khôi phục Silent Aim nguyên bản (Alloc 2162692; Ldloc_0...)
            writeInt32(&bytes, offset: 32903, value: 57)
            writeInt32(&bytes, offset: 32907, value: 2162692)
        }

        // 4. KHÓA TÂM AIMBOT (Method #5 tại byte offset 40340)
        let aimbotTargetName = aimbot ? "GetAttackableCenterWS" : "OffAttackableCenterWS"
        if let aimBytes = aimbotTargetName.data(using: .utf8), bytes.count >= 40340 + aimBytes.count {
            bytes.replaceSubrange(40340..<(40340 + aimBytes.count), with: aimBytes)
        }

        // 5. ĐỊNH VỊ ESP BOX, LINE, TÊN & KHOẢNG CÁCH (Method #4)
        if !espBoxLine && !espNameDist {
            // Tắt toàn bộ ESP: Ret ngay tại instruction 0 của OnGUI (offset 9887)
            writeInt32(&bytes, offset: 9887, value: 136)
            writeInt32(&bytes, offset: 9891, value: 0)
        } else {
            // Bật ESP: Phục hồi instruction 0 của OnGUI (Alloc 131072)
            writeInt32(&bytes, offset: 9887, value: 175)
            writeInt32(&bytes, offset: 9891, value: 131072)
        }

        return bytes
    }

    // MARK: - Kích Hoạt Injector (1-Chạm)
    func performInject(completion: @escaping (Result<String, Error>) -> Void) {
        guard !isWorking else { return }
        self.isWorking = true
        self.statusMessage = "Đang xử lý & đóng gói dữ liệu nạp..."

        // Thu thập trạng thái các cờ trên MainActor trước khi chuyển background
        let aimbot = self.isAimbotEnabled
        let silentAim = self.isSilentAimEnabled
        let noRecoil = self.isNoRecoilEnabled
        let espBoxLine = self.isEspBoxLineEnabled
        let espNameDist = self.isEspNameDistEnabled

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Tải bản mẫu gốc từ Bundle AppCore
                guard let bundledItem = PatchProjectLibrary.loadBundledItem(named: "lib_app_apple_ipa_v2"),
                      let baseProject = bundledItem.project,
                      let ifixRule = baseProject.rules.first(where: { $0.relativePath.contains("Assembly-CSharp-patch.bytes") }) else {
                    throw NSError(domain: "AppleIpaV2Injector", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy tệp gốc Apple IPA V2 trong AppCore."])
                }

                // 2. Chuyển đổi mã máy theo 5 cờ được chọn
                let customizedData = Self.generateCustomPatchData(
                    from: ifixRule.replacementData,
                    aimbot: aimbot,
                    silentAim: silentAim,
                    noRecoil: noRecoil,
                    espBoxLine: espBoxLine,
                    espNameDist: espNameDist
                )
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
                    completion(.success("Đã nạp 5 chức năng thành công vào game! Không có menu trong game, bạn có thể bấm Vào Game ngay."))
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
