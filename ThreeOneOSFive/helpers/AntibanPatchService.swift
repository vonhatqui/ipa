import Foundation
import SwiftUI
import Combine

/// Dịch vụ quản lý riêng biệt cho Patch Antiban Yabao (Standalone Antiban Patch Service)
/// Chứa toàn bộ logic Neutral Seed 322B, Timed Exposure Wipe và bảo vệ chống quét đĩa của Yabao
final class AntibanPatchService: ObservableObject {
    static let shared = AntibanPatchService()

    @Published var isAntibanPatchApplied: Bool = false
    @Published var isNeutralized: Bool = false
    @Published var isProcessing: Bool = false
    @Published var statusNotice: String? = nil

    /// Mảng byte chuẩn 322-byte Neutral Seed IFix của YABAO (SHA-256: 4c2c13744bc558fb16400aeaf0ef59c2b4c4b9cde41446ff0c6e51aa2f96c49e)
    static let neutralSeedBytes: Data = {
        var raw: [UInt8] = [
            0xcb, 0xa2, 0xb4, 0x0d, 0xb2, 0x19, 0xa3, 0x66, 0x64, 0x49, 0x46, 0x69, 0x78, 0x2e, 0x49, 0x4c,
            0x46, 0x69, 0x78, 0x49, 0x6e, 0x74, 0x65, 0x72, 0x66, 0x61, 0x63, 0x65, 0x42, 0x72, 0x69, 0x64,
            0x67, 0x65, 0x2c, 0x20, 0x41, 0x73, 0x73, 0x65, 0x6d, 0x62, 0x6c, 0x79, 0x2d, 0x43, 0x53, 0x68,
            0x61, 0x72, 0x70, 0x2c, 0x20, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x3d, 0x30, 0x2e, 0x38,
            0x36, 0x2e, 0x30, 0x2e, 0x35, 0x31, 0x38, 0x2c, 0x20, 0x43, 0x75, 0x6c, 0x74, 0x75, 0x72, 0x65,
            0x3d, 0x6e, 0x65, 0x75, 0x74, 0x72, 0x61, 0x6c, 0x2c, 0x20, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x63,
            0x4b, 0x65, 0x79, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x3d, 0x6e, 0x75, 0x6c, 0x6c
        ]
        raw.append(contentsOf: Array(repeating: 0x00, count: 28))
        let part2: [UInt8] = [
            0x63, 0x49, 0x46, 0x69, 0x78, 0x2e, 0x57, 0x72, 0x61, 0x70, 0x70, 0x65, 0x72, 0x73, 0x4d, 0x61,
            0x6e, 0x61, 0x67, 0x65, 0x72, 0x49, 0x6d, 0x70, 0x6c, 0x2c, 0x20, 0x41, 0x73, 0x73, 0x65, 0x6d,
            0x62, 0x6c, 0x79, 0x2d, 0x43, 0x53, 0x68, 0x61, 0x72, 0x70, 0x2c, 0x20, 0x56, 0x65, 0x72, 0x73,
            0x69, 0x6f, 0x6e, 0x3d, 0x30, 0x2e, 0x38, 0x36, 0x2e, 0x30, 0x2e, 0x35, 0x31, 0x38, 0x2c, 0x20,
            0x43, 0x75, 0x6c, 0x74, 0x75, 0x72, 0x65, 0x3d, 0x6e, 0x65, 0x75, 0x74, 0x72, 0x61, 0x6c, 0x2c,
            0x20, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x63, 0x4b, 0x65, 0x79, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x3d,
            0x6e, 0x75, 0x6c, 0x6c, 0x4b, 0x2c, 0x20, 0x41, 0x73, 0x73, 0x65, 0x6d, 0x62, 0x6c, 0x79, 0x2d,
            0x43, 0x53, 0x68, 0x61, 0x72, 0x70, 0x2c, 0x20, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x3d,
            0x30, 0x2e, 0x38, 0x36, 0x2e, 0x30, 0x2e, 0x35, 0x31, 0x38, 0x2c, 0x20, 0x43, 0x75, 0x6c, 0x74,
            0x75, 0x72, 0x65, 0x3d, 0x6e, 0x65, 0x75, 0x74, 0x72, 0x61, 0x6c, 0x2c, 0x20, 0x50, 0x75, 0x62,
            0x6c, 0x69, 0x63, 0x4b, 0x65, 0x79, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x3d, 0x6e, 0x75, 0x6c, 0x6c
        ]
        raw.append(contentsOf: part2)
        raw.append(contentsOf: Array(repeating: 0x00, count: 9))
        return Data(raw)
    }()

    /// File localConfig an toàn chống crash
    static let safeConfigData: Data = Data("{\"testCodePatch\":true}\n".utf8)

    private init() {
        refreshStatus()
    }

    // MARK: - Core Antiban Patch Actions

    /// 1. Nạp file Patch Antiban riêng biệt (Neutral Seed 322B + Safe Config)
    @discardableResult
    func applyStandaloneAntibanPatch() -> Bool {
        isProcessing = true
        defer { isProcessing = false }

        let fileManager = FileManager.default
        let allContainers = DevicePatchService.allAvailableFreeFireContainers()
        guard !allContainers.isEmpty else {
            statusNotice = "Không tìm thấy thư mục game Free Fire để nạp Antiban"
            return false
        }

        var successCount = 0
        for (_, root) in allContainers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)

            let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let dstConfig = docDir.appendingPathComponent("localConfig.json")

            do {
                try Self.neutralSeedBytes.write(to: dstPatch, options: .atomic)
                try Self.safeConfigData.write(to: dstConfig, options: .atomic)
                successCount += 1
            } catch {
                log("[AntibanPatchService] Lỗi khi ghi patch: \(error)")
            }
        }

        let ok = successCount > 0
        DispatchQueue.main.async {
            self.isAntibanPatchApplied = ok
            self.isNeutralized = ok
            self.statusNotice = ok ? "Đã nạp file Antiban Yabao 322B thành công!" : "Lỗi khi nạp file Antiban"
        }
        return ok
    }

    /// 2. Kích hoạt bộ đếm thời gian trung hòa file sau khi vào game (Timed Exposure Wipe chuẩn Yabao)
    func startTimedExposureWipe(delaySeconds: TimeInterval = 8.0) {
        log("[AntibanPatchService] Bắt đầu hẹn giờ trung hoà file đĩa sau \(delaySeconds)s...")
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
            guard let self = self else { return }
            let ok = self.applyStandaloneAntibanPatch()
            if ok {
                self.isNeutralized = true
                self.statusNotice = "Antiban Yabao: Đã trung hoà file đĩa (322B Active)!"
                log("[AntibanPatchService] [WIPE] Hoàn tất trung hoà file đĩa chống quét!")
            }
        }
    }

    /// 3. Gỡ bỏ hoàn toàn file patch Antiban khỏi thư mục game
    @discardableResult
    func removeAntibanPatch() -> Bool {
        isProcessing = true
        defer { isProcessing = false }

        let fileManager = FileManager.default
        let allContainers = DevicePatchService.allAvailableFreeFireContainers()

        for (_, root) in allContainers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let dstConfig = docDir.appendingPathComponent("localConfig.json")

            try? fileManager.removeItem(at: dstPatch)
            try? fileManager.removeItem(at: dstConfig)
        }

        DispatchQueue.main.async {
            self.isAntibanPatchApplied = false
            self.isNeutralized = false
            self.statusNotice = "Đã gỡ sạch file Antiban khỏi game"
        }
        return true
    }

    /// 4. Làm mới trạng thái kiểm tra file trên đĩa
    func refreshStatus() {
        let fileManager = FileManager.default
        let allContainers = DevicePatchService.allAvailableFreeFireContainers()

        var found322 = false
        for (_, root) in allContainers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            if let data = try? Data(contentsOf: dstPatch), data.count == 322 {
                found322 = true
                break
            }
        }

        DispatchQueue.main.async {
            self.isAntibanPatchApplied = found322
            self.isNeutralized = found322
        }
    }
}
