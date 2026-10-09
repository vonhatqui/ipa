import Foundation
import SwiftUI
import Combine

/// Dịch vụ quản lý riêng biệt cho Patch Antiban Yabao & Delta Core (Standalone Antiban Service)
/// Chứa toàn bộ logic Neutral Seed 322B, Timed Exposure Wipe, Active Telemetry Sweeper (38 paths),
/// và quản lý trạng thái thời gian thực (LIVE Timer & Real-time Session Logs) chuẩn Delta Client.
final class AntibanPatchService: ObservableObject {
    static let shared = AntibanPatchService()

    // MARK: - Trạng Thái Cốt Lõi (State Machine)
    @Published var isAntibanPatchApplied: Bool = false
    @Published var isNeutralized: Bool = false
    @Published var isProcessing: Bool = false
    @Published var statusNotice: String? = nil

    // Trạng thái Real-time chuẩn Delta Client
    @Published var isAntiBanActive: Bool = false
    @Published var isActivating: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var startTime: Date? = nil
    @Published var activeGameTarget: String = "Free Fire"
    @Published var bgRunsCount: Int = UserDefaults.standard.integer(forKey: "delta.antiban.bgruns")
    @Published var logs: [String] = []

    private var liveTimer: Timer? = nil

    /// Định dạng thời gian bảo vệ trôi qua (hh:mm:ss hoặc mm:ss)
    var formattedElapsedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Danh Sách 38 Đường Dẫn Telemetry / Anti-Cheat Sweeper (Trích xuất từ Delta Mach-O)
    static let telemetryPaths: [String] = [
        // 1. File báo cáo, Crash Dump & Telemetry Logs
        "Documents/report",
        "Documents/analytics",
        "Documents/crash_dump",
        "Documents/beacon",
        "Documents/feedback",
        "Documents/GCloud",
        "Documents/MidasLog",
        "Documents/shadow_tracker",
        "Documents/tencent_tdid",
        "Documents/anti_cheat_logs",
        "Documents/vng_log",
        "Documents/msdk_log",
        "Documents/garena_log",
        "Documents/gvoice",
        "Documents/dp_log",
        "Documents/oss_log",
        "Documents/upload",
        "Documents/pending_reports",

        // 2. Thư mục Cache phân tích hành vi & crash SDK
        "Library/Caches/Analytics",
        "Library/Caches/CrashReporter",
        "Library/Caches/com.crashlytics.data",
        "Library/Caches/crashes",
        "Library/Caches/GCloud",
        "Library/Caches/GVoice",
        "Library/Caches/com.google.firebase",
        "Library/Caches/com.appsflyer",
        "Library/Caches/adjust-sdk",
        "Library/Caches/bugly",
        "Library/Caches/Snapshots",

        // 3. File Hash kiểm tra tính toàn vẹn (Content Cache Database)
        "Documents/contentcache/res_version.hash",
        "Documents/contentcache/file_hash.bin",
        "Documents/contentcache/verify_cache.dat",
        "Documents/contentcache/crc_cache.bin",
        "Documents/contentcache/asset_verify.db",
        "Documents/contentcache/patch_verify.dat",
        "Documents/contentcache/resource_manifest.json",
        "Documents/contentcache/checksum.bin",
        "Documents/contentcache/integrity_db.sqlite",
        "Documents/contentcache",

        // 4. Preferences SDK Bugly
        "Library/Preferences/com.tencent.bugly"
    ]

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

    // MARK: - Quản Lý Log Thời Gian Thực
    func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let formattedLine = "[\(timestamp)] \(message)"

        DispatchQueue.main.async {
            self.logs.append(formattedLine)
            if self.logs.count > 120 {
                self.logs.removeFirst()
            }
        }
        log("[AntibanPatchService] \(message)")
    }

    // MARK: - Bộ Dọn Dẹp Telemetry & Báo Cáo Gian Lận (38 Paths)
    /// Quét và làm sạch 38 file/thư mục log nhạy cảm trong container game
    @discardableResult
    func cleanTelemetryAndLogs(in root: URL) -> Int {
        let fileManager = FileManager.default
        var wipedCount = 0

        for relativePath in Self.telemetryPaths {
            let targetURL = root.appendingPathComponent(relativePath)
            if fileManager.fileExists(atPath: targetURL.path) {
                do {
                    try fileManager.removeItem(at: targetURL)
                    wipedCount += 1
                } catch {
                    if let contents = try? fileManager.contentsOfDirectory(at: targetURL, includingPropertiesForKeys: nil) {
                        for subItem in contents {
                            try? fileManager.removeItem(at: subItem)
                            wipedCount += 1
                        }
                    }
                }
            }
        }
        return wipedCount
    }

    // MARK: - Kích Hoạt Antiban Real-time (Chuẩn Delta Client Flow)

    /// Bật bảo vệ Antiban thời gian thực: Dọn sạch telemetry, nạp Neutral Seed và đếm giờ
    func startAntiBan(targetGame: String = "Free Fire") {
        guard !isAntiBanActive else { return }

        isActivating = true
        isProcessing = true
        activeGameTarget = targetGame
        addLog("Đang kích hoạt bảo vệ tối đa: \(targetGame)...")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let allContainers = DevicePatchService.allAvailableFreeFireContainers()
            guard !allContainers.isEmpty else {
                DispatchQueue.main.async {
                    self.isActivating = false
                    self.isProcessing = false
                    self.statusNotice = "Không tìm thấy thư mục game \(targetGame)"
                    self.addLog("LỖI: Không tìm thấy thư mục sandbox của \(targetGame)")
                }
                return
            }

            self.addLog("Đã tìm thấy \(allContainers.count) container game. Đang quét...")
            var totalWiped = 0
            var successPatch = false

            for (bundleID, root) in allContainers {
                let wiped = self.cleanTelemetryAndLogs(in: root)
                totalWiped += wiped

                let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                try? FileManager.default.createDirectory(at: docDir, withIntermediateDirectories: true)

                let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
                let dstConfig = docDir.appendingPathComponent("localConfig.json")

                do {
                    try Self.neutralSeedBytes.write(to: dstPatch, options: .atomic)
                    try Self.safeConfigData.write(to: dstConfig, options: .atomic)
                    successPatch = true
                    self.addLog("[\(bundleID)] Đã dọn \(wiped) telemetry & nạp file patch Neutral Seed 322B")
                } catch {
                    self.addLog("[\(bundleID)] Lỗi khi nạp file patch: \(error.localizedDescription)")
                }
            }

            // Tăng số lần chạy bảo vệ nền (delta.antiban.bgruns)
            let currentRuns = UserDefaults.standard.integer(forKey: "delta.antiban.bgruns") + 1
            UserDefaults.standard.set(currentRuns, forKey: "delta.antiban.bgruns")

            DispatchQueue.main.async {
                self.bgRunsCount = currentRuns
                self.isProcessing = false
                self.isActivating = false

                if successPatch {
                    self.isAntiBanActive = true
                    self.isAntibanPatchApplied = true
                    self.isNeutralized = true
                    self.startTime = Date()
                    self.elapsedSeconds = 0

                    // Khởi chạy Timer đếm giây
                    self.liveTimer?.invalidate()
                    self.liveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                        guard let self = self else { return }
                        self.elapsedSeconds += 1
                    }

                    self.addLog("Active Protection: \(targetGame) (LIVE)")
                    self.addLog("Maximum Safety • \(currentRuns) lượt bảo vệ nền")
                    self.statusNotice = "Active Protection: \(targetGame) (LIVE)"
                } else {
                    self.statusNotice = "Kích hoạt Antiban thất bại"
                }
            }
        }
    }

    /// Tắt bảo vệ Antiban và xuất log tổng kết
    func stopAntiBan() {
        let stoppedDuration = formattedElapsedTime
        liveTimer?.invalidate()
        liveTimer = nil

        _ = removeAntibanPatch()

        DispatchQueue.main.async {
            self.isAntiBanActive = false
            self.isActivating = false
            self.isAntibanPatchApplied = false
            self.isNeutralized = false
            self.addLog("Anti-Ban Stopped (\(stoppedDuration))")
            self.statusNotice = "Anti-Ban Stopped (\(stoppedDuration))"
        }
    }

    // MARK: - Core Antiban Patch Actions (Tương Thích Ngược)

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
            _ = cleanTelemetryAndLogs(in: root)
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
        addLog("Bắt đầu đếm ngược \(Int(delaySeconds))s trung hoà file chống quét...")
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
            guard let self = self else { return }
            let ok = self.applyStandaloneAntibanPatch()
            if ok {
                self.isNeutralized = true
                self.statusNotice = "Antiban Yabao: Đã trung hoà file đĩa (322B Active)!"
                self.addLog("[WIPE] Hoàn tất trung hoà file đĩa chống quét (322B Active)")
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
