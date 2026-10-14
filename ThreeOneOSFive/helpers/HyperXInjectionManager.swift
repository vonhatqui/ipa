import Foundation
import UIKit
import Combine
import AVFoundation
import Darwin
import UserNotifications

// MARK: - Feature Item Model

public struct HyperXFeatureItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let category: String
    public let filename: String
    public let targetPath: String
    public let password: String?
    public let size: Int64
    public let downloadUrl: String
    public let iconUrl: String?
    public var isSelected: Bool

    public var formattedSize: String {
        guard size > 0 else { return "—" }
        let kb = Double(size) / 1024.0
        if kb > 1024.0 {
            return String(format: "%.1f MB", kb / 1024.0)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }
}

// MARK: - Injection Record Model (Quản lý phục hồi và gỡ bỏ)

public struct HyperXInjectionRecord: Codable {
    public let targetPath: String
    public let backupPath: String?
    public let originalExisted: Bool

    public init(targetPath: String, backupPath: String?, originalExisted: Bool) {
        self.targetPath = targetPath
        self.backupPath = backupPath
        self.originalExisted = originalExisted
    }
}

// MARK: - Injection Manager

@MainActor
public final class HyperXInjectionManager: ObservableObject {
    public static let shared = HyperXInjectionManager()

    public enum ButtonState: String, Equatable {
        case loader = "Loader"
        case injector = "Injector"
        case uninject = "Uninject"
    }

    private let endpointURL = "https://crackbomaydihihi.sbs/api.php"
    private let injectedFilesKey = "hyperx_injected_file_paths"
    private let injectionRecordsKey = "hyperx_injection_records_v3"
    private let session = URLSession(
        configuration: .default,
        delegate: HyperXSSLTrustDelegate.shared,
        delegateQueue: nil
    )

    @Published public var buttonState: ButtonState = .loader
    @Published public var isLoading: Bool = false
    @Published public var isInjecting: Bool = false
    @Published public var isUninjecting: Bool = false
    @Published public var features: [HyperXFeatureItem] = []
    @Published public var statusMessage: String?
    @Published public var injectedCount: Int = 0
    @Published public var antibanSummary: String? = nil
    @Published public var showAntibanBanner: Bool = false

    // MARK: - Auto-Sweep Sentinel (Tự Động Quét & Triệt Tiêu reportnew.db Khi Vào Trận)
    public static let telemetryTargets: [String] = [
        "Documents/reportnew.db",
        "Documents/reportnew.db-journal",
        "Documents/reportnew.db-wal",
        "Documents/reportnew.db-shm",
        "Documents/HeatMap",
        "Documents/MReplays",
        "Documents/record",
        "Documents/ffrtc_log.txt",
        "Documents/ff_magicvoice_engine_log.txt",
        "Documents/beetalk_session.db",
        "Documents/Report",
        "Documents/stat_log",
        "Documents/tlog",
        "Documents/crashlog",
        "Documents/garena_logs",
        "Documents/ffxc_debug.log",
        "Documents/ff_xc_session",
        "Documents/ff_telemetry"
    ]

    @Published public var isAutoSweepActive: Bool = false
    @Published public var isAutoSweepLocked: Bool = false
    @Published public var autoSweepCleanedCount: Int = 0
    @Published public var autoSweepCycleCount: Int = 0
    @Published public var isBannerNotificationEnabled: Bool = true

    private var autoSweepTask: Task<Void, Never>? = nil
    private var bgTaskID: UIBackgroundTaskIdentifier = .invalid
    private var silentAudioPlayer: AVAudioPlayer? = nil
    private var directoryMonitors: [DispatchSourceFileSystemObject] = []
    private var monitoredFileDescriptors: [Int32] = []
    private var lastNotificationTimestamp: TimeInterval = 0

    // Danh sách Bundle ID mục tiêu phổ biến của Free Fire
    public let candidateBundleIDs: [String] = [
        "com.dts.freefireth",
        "com.dts.freefiremax"
    ]

    public init() {
        self.buttonState = .loader
        self.injectedCount = savedInjectedFiles().count
        setupAppLifecycleObservers()
    }

    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.buttonState == .uninject {
                self.sweepTelemetryTargetsOnce()
            }
        }
    }

    // MARK: - Auto-Sweep Sentinel Engine (Zero-Delay Kernel Monitor + 250ms Polling)
    public func startAutoSweep() {
        guard !isAutoSweepActive else { return }
        self.isAutoSweepActive = true

        startBackgroundKeepAlive()
        startDirectoryMonitors()
        self.sweepTelemetryTargetsOnce()

        // Vòng lặp Polling siêu tốc 250ms (0.25 giây) dự phòng kết hợp Kernel Monitor (Không delay)
        autoSweepTask?.cancel()
        autoSweepTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self?.sweepTelemetryTargetsOnce()
                }
            }
        }
    }

    public func stopAutoSweep(force: Bool = false) {
        guard force || !isAutoSweepLocked else { return }
        self.isAutoSweepActive = false
        self.isAutoSweepLocked = false
        autoSweepTask?.cancel()
        autoSweepTask = nil
        stopDirectoryMonitors()
        stopBackgroundKeepAlive()
    }

    private func startDirectoryMonitors() {
        stopDirectoryMonitors()
        let roots = resolveTargetContainerRoots(for: nil)
        for (_, rootURL) in roots {
            let docURL = rootURL.appendingPathComponent("Documents")
            let path = docURL.path
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .extend, .attrib, .link, .rename],
                queue: DispatchQueue.global(qos: .userInteractive)
            )

            source.setEventHandler { [weak self] in
                Task { @MainActor in
                    self?.sweepTelemetryTargetsOnce()
                }
            }

            source.setCancelHandler {
                close(fd)
            }

            source.resume()
            directoryMonitors.append(source)
            monitoredFileDescriptors.append(fd)
        }
    }

    private func stopDirectoryMonitors() {
        for monitor in directoryMonitors {
            monitor.cancel()
        }
        directoryMonitors.removeAll()
        monitoredFileDescriptors.removeAll()
    }

    @discardableResult
    public func sweepTelemetryTargetsOnce() -> Int {
        let fm = FileManager.default
        var cleanedCount = 0
        var cleanedNames: [String] = []
        let roots = resolveTargetContainerRoots(for: nil)

        for (_, rootURL) in roots {
            for rel in Self.telemetryTargets {
                let targetURL = rootURL.appendingPathComponent(rel)
                if fm.fileExists(atPath: targetURL.path) {
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: targetURL.path, isDirectory: &isDir), isDir.boolValue {
                        if let _ = try? fm.removeItem(at: targetURL) {
                            cleanedCount += 1
                            cleanedNames.append(targetURL.lastPathComponent)
                        }
                    } else {
                        // Ghi đè rỗng trước để huỷ dữ liệu SQLite rồi xóa file
                        try? Data().write(to: targetURL)
                        if let _ = try? fm.removeItem(at: targetURL) {
                            cleanedCount += 1
                            cleanedNames.append(targetURL.lastPathComponent)
                        }
                    }
                }
            }
        }

        // Duy trì liên tục 2 cờ antiban_btn_show.flag và antiban_active.flag trong Documents
        for (_, rootURL) in roots {
            let docURL = rootURL.appendingPathComponent("Documents")
            if fm.fileExists(atPath: docURL.path) {
                let btnFlag = docURL.appendingPathComponent("antiban_btn_show.flag")
                if !fm.fileExists(atPath: btnFlag.path) {
                    try? "1".data(using: .utf8)?.write(to: btnFlag)
                }
                let actFlag = docURL.appendingPathComponent("antiban_active.flag")
                if !fm.fileExists(atPath: actFlag.path) {
                    try? "1".data(using: .utf8)?.write(to: actFlag)
                }
            }
        }

        if cleanedCount > 0 {
            self.autoSweepCleanedCount += cleanedCount
            // Gửi biểu ngữ thông báo lên điện thoại (Banner Notification)
            postSweepBannerNotification(cleanedCount: cleanedCount, fileNames: cleanedNames)
        }
        self.autoSweepCycleCount += 1
        return cleanedCount
    }

    // MARK: - Local Banner Notifications (Hiển thị biểu ngữ tên app khi quét thành công trong trận)

    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("HyperXNotifications: authorization error: \(error)")
            } else {
                print("HyperXNotifications: authorization granted = \(granted)")
            }
        }
    }

    public func postSweepBannerNotification(cleanedCount: Int, fileNames: [String]) {
        guard isBannerNotificationEnabled else { return }
        let now = Date().timeIntervalSince1970
        // Throttling: Giới hạn tối thiểu 4 giây / 1 lần thông báo để không bị spam trong trận
        guard now - lastNotificationTimestamp >= 4.0 else { return }
        lastNotificationTimestamp = now

        let content = UNMutableNotificationContent()
        content.title = "HyperXSpace"

        let hasReportDb = fileNames.contains(where: { $0.lowercased().contains("reportnew.db") })
        if hasReportDb {
            content.body = "🛡️ Đã quét thành công reportnew.db & telemetry khi vào trận!"
        } else if let first = fileNames.first {
            content.body = "🛡️ Đã quét thành công tệp \(first)!"
        } else {
            content.body = "🛡️ Đã quét thành công \(cleanedCount) tệp telemetry bất thường!"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "HyperX_AutoSweep_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("HyperXNotifications: add request error: \(error)")
            }
        }
    }

    public func sendTestNotification() {
        requestNotificationPermission()
        let content = UNMutableNotificationContent()
        content.title = "HyperXSpace"
        content.body = "🛡️ Đã quét thành công reportnew.db & telemetry khi vừa vào trận!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "HyperX_Test_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func startBackgroundKeepAlive() {
        if bgTaskID == .invalid {
            bgTaskID = UIApplication.shared.beginBackgroundTask(withName: "HyperXAutoSweepSentinel") { [weak self] in
                self?.endBackgroundTask()
            }
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let silentData = Self.createSilentWAVData()
            silentAudioPlayer = try AVAudioPlayer(data: silentData)
            silentAudioPlayer?.numberOfLoops = -1
            silentAudioPlayer?.volume = 0.0
            silentAudioPlayer?.prepareToPlay()
            silentAudioPlayer?.play()
        } catch {
            print("HyperXAutoSweep: Không thể khởi chạy audio keep-alive: \(error)")
        }
    }

    private func stopBackgroundKeepAlive() {
        silentAudioPlayer?.stop()
        silentAudioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if bgTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        }
    }

    private static func createSilentWAVData() -> Data {
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        let totalSize: UInt32 = 44 + 8000 - 8
        withUnsafeBytes(of: totalSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        let subchunk1Size: UInt32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: UInt16 = 1
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        let numChannels: UInt16 = 1
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        let sampleRate: UInt32 = 8000
        withUnsafeBytes(of: sampleRate.littleEndian) { data.append(contentsOf: $0) }
        let byteRate: UInt32 = 8000 * 2
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        let blockAlign: UInt16 = 2
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        let bitsPerSample: UInt16 = 16
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: "data".utf8)
        let subchunk2Size: UInt32 = 8000
        withUnsafeBytes(of: subchunk2Size.littleEndian) { data.append(contentsOf: $0) }
        data.append(Data(repeating: 0, count: Int(subchunk2Size)))
        return data
    }

    // MARK: - Reset State on Background / App Exit
    // Yêu cầu: "Bắt Buộc Out Ra Vào Lại Phải Load Lại 1 Lần, Kiểu Out App sẽ reset ban đầu"

    public func resetToInitial() {
        self.stopAutoSweep(force: true)
        self.features = []
        self.buttonState = .loader
        self.isLoading = false
        self.isInjecting = false
        self.isUninjecting = false
        self.statusMessage = nil
    }

    // MARK: - Loader: Cập Nhật Chức Năng Đang Hoạt Động Từ Server

    public func loadFeatures() async {
        self.isLoading = true
        self.statusMessage = "Đang kết nối máy chủ và tải danh sách chức năng..."

        var components = URLComponents(string: endpointURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "get_cloud_patches"),
            URLQueryItem(name: "active_only", value: "1")
        ]

        guard let requestURL = components?.url else {
            self.isLoading = false
            self.statusMessage = "URL máy chủ không hợp lệ."
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("HyperXSpace/2.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.isLoading = false
                self.statusMessage = "Máy chủ đang bảo trì hoặc không phản hồi."
                return
            }

            var cleanData = data
            if cleanData.count >= 3 && cleanData[0] == 0xEF && cleanData[1] == 0xBB && cleanData[2] == 0xBF {
                cleanData = cleanData.subdata(in: 3..<cleanData.count)
            }

            guard let json = try? JSONSerialization.jsonObject(with: cleanData, options: []) as? [String: Any],
                  let patchesArray = json["patches"] as? [[String: Any]] else {
                self.isLoading = false
                self.statusMessage = "Định dạng dữ liệu từ máy chủ không hợp lệ."
                return
            }

            var loadedItems: [HyperXFeatureItem] = []
            for (idx, p) in patchesArray.enumerated() {
                let isActive = p["is_active"] as? Bool ?? true
                guard isActive else { continue }

                let id = p["id"] as? String ?? UUID().uuidString
                let name = p["name"] as? String ?? "Chức Năng"
                let subtitle = p["subtitle"] as? String ?? ""
                let category = p["category"] as? String ?? "mod"
                let filename = p["filename"] as? String ?? "file.dat"
                let targetPath = p["target_path"] as? String ?? "Documents/\(filename)"
                let password = p["password"] as? String
                let size = (p["size"] as? NSNumber)?.int64Value ?? 0
                let downloadUrl = p["download_url"] as? String ?? ""
                let iconUrl = p["icon_url"] as? String ?? p["image_url"] as? String

                let item = HyperXFeatureItem(
                    id: id,
                    name: name,
                    subtitle: subtitle,
                    category: category,
                    filename: filename,
                    targetPath: targetPath,
                    password: password,
                    size: size,
                    downloadUrl: downloadUrl,
                    iconUrl: iconUrl,
                    isSelected: (idx == 0) // Yêu cầu: Mỗi chức năng chỉ được chọn 1 chức năng duy nhất
                )
                loadedItems.append(item)
            }

            // Yêu cầu: Nút loader ấn phải cho hiện loading 5-10s
            // Đặt thời gian loading 6.5s để người dùng thấy rõ trạng thái đang tải dữ liệu
            // Giảm thời gian loading xuống 0.5s mượt mà, tải có ngay lập tức
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Cơ chế loader: Chỉ load duy nhất 1 file patch trên server
            if let firstItem = loadedItems.first {
                var single = firstItem
                single.isSelected = true
                self.features = [single]
            } else {
                self.features = []
            }
            self.isLoading = false

            if self.features.isEmpty {
                self.statusMessage = "Hiện tại không có patch nào mở trên máy chủ."
                self.buttonState = .loader
            } else {
                self.statusMessage = "Đã phát hiện patch, Vui lòng mở Antiban trước khi vào game"
                self.buttonState = .injector
            }
        }
        } catch {
            self.isLoading = false
            self.statusMessage = "Lỗi kết nối: \(error.localizedDescription)"
        }
    }

    // MARK: - Single Selection (Chỉ Cho Phép Chọn 1 Chức Năng Duy Nhất)

    public func selectSingle(for itemID: String) {
        for i in 0..<features.count {
            features[i].isSelected = (features[i].id == itemID)
        }
    }

    public var selectedCount: Int {
        features.filter { $0.isSelected }.count
    }

    // MARK: - Target App Container Roots Resolver
    // Logic 3105: Tìm đường dẫn thực tế của App trên thiết bị (MCMActivateContainerPath & Scan)

    private func resolveTargetContainerRoots(for targetBundleID: String? = nil) -> [(bundleID: String, rootURL: URL)] {
        var results: [(bundleID: String, rootURL: URL)] = []
        var checkedBundles = Set<String>()

        var candidates: [String] = []
        if let target = targetBundleID, !target.isEmpty {
            candidates.append(target)
        }
        for b in candidateBundleIDs {
            if !candidates.contains(b) {
                candidates.append(b)
            }
        }

        // 1. Quét tìm container thực tế của game Free Fire / Free Fire MAX
        for b in candidates {
            guard !checkedBundles.contains(b) else { continue }
            checkedBundles.insert(b)

            if let path = ContainerStore.resolveAppContainerPath(bundleID: b),
               ContainerStore.isApplicationContainerPath(path) {
                let url = URL(fileURLWithPath: path, isDirectory: true)
                results.append((bundleID: b, rootURL: url))
            }
        }

        // 2. Fallback: Nếu không tìm thấy qua MCM (VD: môi trường test / dev), thêm Documents nội bộ
        if results.isEmpty {
            if let localDocs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fallbackBundle = targetBundleID ?? "com.dts.freefireth"
                results.append((bundleID: fallbackBundle, rootURL: localDocs))
            }
        }

        return results
    }

    // MARK: - Thư mục Backup phục vụ Hoàn Tác / Uninject

    private func getBackupDirectory(for projectID: UUID) throws -> URL {
        let fm = FileManager.default
        let base = (try? PatchProjectLibrary.backupRootURL(fileManager: fm))
            ?? fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("HyperXBackups", isDirectory: true)

        let projectBackupDir = base.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try fm.createDirectory(at: projectBackupDir, withIntermediateDirectories: true)
        return projectBackupDir
    }

    // MARK: - Logic 3105 Engine: Giải Mã & Nạp Gói .3105 Vào Đúng Relative Path

    private func apply3105Package(
        data: Data,
        password: String?,
        featureItem: HyperXFeatureItem
    ) throws -> (appliedRules: Int, writtenPaths: [String]) {
        // 1. Kiểm tra cấu trúc envelope gói .3105
        let summary = try PatchPackageCodec.inspect(data)

        // 2. Giải mã project bên trong .3105
        var decodedProject: PatchProject? = nil
        var contentKeyToStore: Data? = nil
        var lastDecodeError: Error? = nil

        // Thử giải mã bằng mật khẩu máy chủ cung cấp (nếu có)
        if let pass = password, !pass.isEmpty {
            do {
                let decoded = try PatchPackageCodec.decode(data, password: pass)
                decodedProject = decoded.project
                contentKeyToStore = decoded.contentKey
            } catch {
                lastDecodeError = error
            }
        }

        // Nếu chưa được, thử với key đã lưu trong Keychain từ lần trước
        if decodedProject == nil, let key = try? PatchKeyStore.load(for: summary) {
            do {
                let decoded = try PatchPackageCodec.decode(data, contentKey: key)
                decodedProject = decoded.project
            } catch {
                lastDecodeError = error
            }
        }

        // Nếu gói không đặt pass (public) hoặc chưa giải mã được, thử giải mã không pass
        if decodedProject == nil {
            do {
                let decoded = try PatchPackageCodec.decode(data, password: nil)
                decodedProject = decoded.project
                contentKeyToStore = decoded.contentKey
            } catch {
                lastDecodeError = error
            }
        }

        guard let project = decodedProject else {
            if let err = lastDecodeError {
                throw err
            }
            throw PatchPackageError.invalidPasswordOrCorruptedPackage
        }

        // Lưu contentKey vào Keychain để lần sau không cần mật khẩu
        if let key = contentKeyToStore {
            try? PatchKeyStore.store(key, for: summary)
        }

        guard !project.rules.isEmpty else {
            throw PatchPackageError.invalidProject
        }

        let backupDir = try getBackupDirectory(for: project.id)
        var writtenPaths: [String] = []
        var appliedCount = 0

        // 3. Nạp từng rule vào đúng relativePath trong container của game
        for rule in project.rules {
            guard !rule.replacementData.isEmpty || rule.hasReplacement else { continue }

            // Tìm container thực tế của game (Free Fire / Free Fire MAX)
            let roots = resolveTargetContainerRoots(for: rule.bundleID)
            guard !roots.isEmpty else {
                print("HyperXInjector: Không tìm thấy container cho \(rule.bundleID)")
                continue
            }

            for (bundleID, rootURL) in roots {
                // relativePath chuẩn trong 3105 (VD: Documents/contentcache/... hoặc Documents/Assembly-CSharp-patch.bytes)
                var rel = rule.relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/\\"))
                if rel.isEmpty {
                    rel = "Documents/" + rule.replacementFilename
                }

                let targetURL = rootURL.appendingPathComponent(rel)
                let parentDir = targetURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

                // Sao lưu file gốc nếu đã tồn tại để Uninject có thể khôi phục 100% nguyên trạng
                let existed = FileManager.default.fileExists(atPath: targetURL.path)
                let backupFileName = "\(rule.id.uuidString)_\(bundleID).original"
                let backupFileURL = backupDir.appendingPathComponent(backupFileName)

                if existed && !FileManager.default.fileExists(atPath: backupFileURL.path) {
                    try? FileManager.default.copyItem(at: targetURL, to: backupFileURL)
                }

                // Ghi đè file mod (replacementData) an toàn theo chuẩn POSIX atomic & giữ nguyên quyền gốc
                do {
                    try atomicSafeWrite(rule.replacementData, to: targetURL, preservingExistingAttributes: existed)
                    writtenPaths.append(targetURL.path)
                    appliedCount += 1

                    // Lưu lịch sử nạp vào bộ đối chiếu phục hồi
                    saveInjectionRecord(HyperXInjectionRecord(
                        targetPath: targetURL.path,
                        backupPath: existed ? backupFileURL.path : nil,
                        originalExisted: existed
                    ))
                } catch {
                    print("HyperXInjector: Lỗi ghi file vào \(targetURL.path): \(error)")
                }
            }
        }

        return (appliedCount, writtenPaths)
    }

    // MARK: - Ghi File An Toàn Chuẩn 3105 Engine (Atomic & Bảo Toàn Thuộc Tính Tránh Ban)

    private func atomicSafeWrite(
        _ data: Data,
        to targetURL: URL,
        preservingExistingAttributes: Bool = true
    ) throws {
        let fileManager = FileManager.default
        let parentDir = targetURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)

        let staging = parentDir.appendingPathComponent(".3105-patch-\(UUID().uuidString)")
        var attributes: [FileAttributeKey: Any] = [:]

        if preservingExistingAttributes,
           let current = try? fileManager.attributesOfItem(atPath: targetURL.path) {
            if let permissions = current[.posixPermissions] { attributes[.posixPermissions] = permissions }
            if let protection = current[.protectionKey] { attributes[.protectionKey] = protection }
        } else {
            attributes[.posixPermissions] = 0o666
            attributes[.protectionKey] = FileProtectionType.none
        }

        guard fileManager.createFile(atPath: staging.path, contents: data, attributes: attributes) else {
            throw PatchPackageError.applyFailed
        }
        defer { try? fileManager.removeItem(at: staging) }

        let handle = try FileHandle(forWritingTo: staging)
        try handle.synchronize()
        try handle.close()

        if rename(staging.path, targetURL.path) != 0 {
            if fileManager.fileExists(atPath: targetURL.path) {
                try? fileManager.removeItem(at: targetURL)
            }
            try fileManager.moveItem(at: staging, to: targetURL)
        }
    }

    // MARK: - Nạp File Mod Raw (.dat, .bytes, .dll)

    private func applyRawModFile(
        fileData: Data,
        featureItem: HyperXFeatureItem
    ) -> (appliedCount: Int, writtenPaths: [String]) {
        let roots = resolveTargetContainerRoots(for: nil)
        var writtenPaths: [String] = []
        var appliedCount = 0

        var cleanRelative = featureItem.targetPath.trimmingCharacters(in: CharacterSet(charactersIn: "/\\"))
        if cleanRelative.isEmpty {
            cleanRelative = "Documents/" + featureItem.filename
        }

        let fallbackUUID = UUID(uuidString: featureItem.id) ?? UUID()
        let backupDir = try? getBackupDirectory(for: fallbackUUID)

        for (bundleID, rootURL) in roots {
            let targetURL = rootURL.appendingPathComponent(cleanRelative)
            let parentDir = targetURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

            let existed = FileManager.default.fileExists(atPath: targetURL.path)
            let backupFileName = "\(featureItem.id)_\(bundleID).original"
            let backupFileURL = backupDir?.appendingPathComponent(backupFileName)

            if existed, let bURL = backupFileURL, !FileManager.default.fileExists(atPath: bURL.path) {
                try? FileManager.default.copyItem(at: targetURL, to: bURL)
            }

            do {
                try atomicSafeWrite(fileData, to: targetURL, preservingExistingAttributes: existed)
                writtenPaths.append(targetURL.path)
                appliedCount += 1

                saveInjectionRecord(HyperXInjectionRecord(
                    targetPath: targetURL.path,
                    backupPath: existed ? backupFileURL?.path : nil,
                    originalExisted: existed
                ))
            } catch {
                print("HyperXInjector: Lỗi ghi raw mod vào \(targetURL.path): \(error)")
            }
        }

        return (appliedCount, writtenPaths)
    }

    // MARK: - Injector: Tải và Nạp Gói/File Mod Vào Game

    public func injectSelectedFeatures() async -> (success: Bool, message: String) {
        let selectedItems = features.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            return (false, "Vui lòng tích chọn ít nhất 1 chức năng để nạp!")
        }

        self.isInjecting = true
        self.statusMessage = "Đang tải và nạp chức năng vào game..."

        var allNewInjectedPaths: [String] = savedInjectedFiles()
        var totalSuccessOperations = 0
        var totalRulesApplied = 0
        var detailedErrorMessage: String? = nil

        for item in selectedItems {
            // 1. Chuẩn bị các URL tải xuống (Ưu tiên API, Fallback qua /patches/ trực tiếp)
            var downloadCandidates: [URL] = []

            var rawURL = item.downloadUrl
            if rawURL.hasPrefix("/") {
                rawURL = "https://crackbomaydihihi.sbs" + rawURL
            } else if !rawURL.hasPrefix("http") {
                rawURL = "https://crackbomaydihihi.sbs/" + rawURL
            }
            if let u = URL(string: rawURL) {
                downloadCandidates.append(u)
            }

            let directURLStr = "https://crackbomaydihihi.sbs/patches/" + item.filename
            if let du = URL(string: directURLStr), !downloadCandidates.contains(du) {
                downloadCandidates.append(du)
            }

            var downloadedData: Data? = nil
            var lastStatusCode: Int = 0

            for candidate in downloadCandidates {
                do {
                    var request = URLRequest(url: candidate)
                    request.timeoutInterval = 30
                    request.setValue("HyperXSpace/2.0 (iOS)", forHTTPHeaderField: "User-Agent")

                    let (fileData, resp) = try await self.session.data(for: request)
                    if let http = resp as? HTTPURLResponse {
                        lastStatusCode = http.statusCode
                        if http.statusCode == 200, !fileData.isEmpty {
                            downloadedData = fileData
                            break
                        }
                    }
                } catch {
                    continue
                }
            }

            guard let fileData = downloadedData, !fileData.isEmpty else {
                if lastStatusCode == 404 {
                    detailedErrorMessage = "Tệp [\(item.name)] không tồn tại trên máy chủ (HTTP 404). Vui lòng cập nhật lại tệp trên web admin!"
                } else if lastStatusCode > 0 {
                    detailedErrorMessage = "Máy chủ phản hồi lỗi khi tải tệp [\(item.name)] (HTTP \(lastStatusCode))."
                } else {
                    detailedErrorMessage = "Không thể tải tệp [\(item.name)]. Vui lòng kiểm tra kết nối mạng."
                }
                continue
            }

            // 2. Nhận diện định dạng tệp: Gói .3105 chuẩn hay File Binary Flat (.dat / .bytes / .dll)
            let is3105Package = fileData.starts(with: Data("3105PATCH\0".utf8))

            if is3105Package {
                // Áp dụng theo chuẩn 3105 Engine: Giải mã và ghi vào đúng relativePath của game
                do {
                    let result = try apply3105Package(
                        data: fileData,
                        password: item.password,
                        featureItem: item
                    )
                    allNewInjectedPaths.append(contentsOf: result.writtenPaths)
                    totalRulesApplied += result.appliedRules
                    if result.appliedRules > 0 {
                        totalSuccessOperations += 1
                    } else {
                        detailedErrorMessage = "Không tìm thấy thư mục game trên máy để nạp tệp."
                    }
                } catch let err as PatchPackageError {
                    switch err {
                    case .invalidPasswordOrCorruptedPackage:
                        detailedErrorMessage = "Tệp [\(item.name)] yêu cầu mật khẩu giải mã hoặc tệp bị hỏng."
                    case .invalidProject:
                        detailedErrorMessage = "Tệp [\(item.name)] không chứa quy tắc nạp hợp lệ."
                    default:
                        detailedErrorMessage = "Lỗi giải mã gói [\(item.name)]: \(err.localizedDescription)"
                    }
                } catch {
                    print("HyperXInjector: Lỗi giải mã hoặc nạp gói .3105: \(error)")
                    detailedErrorMessage = "Lỗi nạp [\(item.name)]: \(error.localizedDescription)"
                }
            } else {
                // Áp dụng theo kiểu Raw Mod File
                let result = applyRawModFile(fileData: fileData, featureItem: item)
                allNewInjectedPaths.append(contentsOf: result.writtenPaths)
                totalRulesApplied += result.appliedCount
                if result.appliedCount > 0 {
                    totalSuccessOperations += 1
                } else {
                    detailedErrorMessage = "Không tìm thấy thư mục game để nạp tệp."
                }
            }
        }

        saveInjectedFiles(allNewInjectedPaths)
        self.injectedCount = allNewInjectedPaths.count
        self.isInjecting = false

        if totalSuccessOperations > 0 {
            self.buttonState = .injector
            self.statusMessage = "Đã nạp patch thành công! Vui lòng tự mở game."
            self.writeControlFlags()
            self.isAutoSweepLocked = true
            self.startAutoSweep()

            // [DISABLED] Không tự động mở game
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.launchGameApp()
            }

            return (true, "Đã nạp patch thành công!\n\nAuto-Sweep Sentinel đã tự động kích hoạt và khóa bảo vệ liên tục (0s delay).\nVui lòng tự mở game để vào trận.")
        } else {
            let msg = detailedErrorMessage ?? "Không thể nạp mod. Vui lòng kiểm tra kết nối mạng và quyền sandbox."
            self.statusMessage = msg
            return (false, msg)
        }
    }

    // MARK: - Sophia Wipe Engine 322-byte Neutral IFix Bridge Seed
    private static let neutralIFixBridgeSeed: Data = Data([
        0xcb, 0xa2, 0xb4, 0x0d, 0xb2, 0x19, 0xa3, 0x66, 0x64, 0x49, 0x46, 0x69, 0x78, 0x2e, 0x49, 0x4c,
        0x46, 0x69, 0x78, 0x49, 0x6e, 0x74, 0x65, 0x72, 0x66, 0x61, 0x63, 0x65, 0x42, 0x72, 0x69, 0x64,
        0x67, 0x65, 0x2c, 0x20, 0x41, 0x73, 0x73, 0x65, 0x6d, 0x62, 0x6c, 0x79, 0x2d, 0x43, 0x53, 0x68,
        0x61, 0x72, 0x70, 0x2c, 0x20, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x3d, 0x30, 0x2e, 0x38,
        0x36, 0x2e, 0x30, 0x2e, 0x35, 0x31, 0x38, 0x2c, 0x20, 0x43, 0x75, 0x6c, 0x74, 0x75, 0x72, 0x65,
        0x3d, 0x6e, 0x65, 0x75, 0x74, 0x72, 0x61, 0x6c, 0x2c, 0x20, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x63,
        0x4b, 0x65, 0x79, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x3d, 0x6e, 0x75, 0x6c, 0x6c, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x49, 0x46, 0x69, 0x78, 0x2e, 0x57,
        0x72, 0x61, 0x70, 0x70, 0x65, 0x72, 0x73, 0x4d, 0x61, 0x6e, 0x61, 0x67, 0x65, 0x72, 0x49, 0x6d,
        0x70, 0x6c, 0x2c, 0x20, 0x41, 0x73, 0x73, 0x65, 0x6d, 0x62, 0x6c, 0x79, 0x2d, 0x43, 0x53, 0x68,
        0x61, 0x72, 0x70, 0x2c, 0x20, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x3d, 0x30, 0x2e, 0x38,
        0x36, 0x2e, 0x30, 0x2e, 0x35, 0x31, 0x38, 0x2c, 0x20, 0x43, 0x75, 0x6c, 0x74, 0x75, 0x72, 0x65,
        0x3d, 0x6e, 0x65, 0x75, 0x74, 0x72, 0x61, 0x6c, 0x2c, 0x20, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x63,
        0x4b, 0x65, 0x79, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x3d, 0x6e, 0x75, 0x6c, 0x6c, 0x4b, 0x2c, 0x20,
        0x41, 0x73, 0x73, 0x65, 0x6d, 0x62, 0x6c, 0x79, 0x2d, 0x43, 0x53, 0x68, 0x61, 0x72, 0x70, 0x2c,
        0x20, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x3d, 0x30, 0x2e, 0x38, 0x36, 0x2e, 0x30, 0x2e,
        0x35, 0x31, 0x38, 0x2c, 0x20, 0x43, 0x75, 0x6c, 0x74, 0x75, 0x72, 0x65, 0x3d, 0x6e, 0x65, 0x75,
        0x74, 0x72, 0x61, 0x6c, 0x2c, 0x20, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x63, 0x4b, 0x65, 0x79, 0x54,
        0x6f, 0x6b, 0x65, 0x6e, 0x3d, 0x6e, 0x75, 0x6c, 0x6c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00
    ])

    // MARK: - Wipe Engine (_TtC10YABAOCHEAT2R7): Quy Trình Dọn Dẹp 2 Pha

    public func uninjectAll() async -> (success: Bool, message: String) {
        self.stopAutoSweep(force: true)
        self.isAutoSweepLocked = false
        self.isUninjecting = true
        self.statusMessage = "Antiban V2: Đang kích hoạt Wipe Engine..."

        // Hiệu ứng quét 1.0 giây như Antiban V2 của Pao
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let fm = FileManager.default
        let records = loadInjectionRecords()

        // ========================================================
        // PHA 1 (PHASE 1): TRIỆT TIÊU MÃ CAN THIỆP & RESTORE MÃ GỐC
        // ========================================================
        for rec in records {
            let targetURL = URL(fileURLWithPath: rec.targetPath)
            if rec.originalExisted, let bPath = rec.backupPath, fm.fileExists(atPath: bPath) {
                // Khôi phục lại chính xác file game gốc trước khi nạp mod
                do {
                    if fm.fileExists(atPath: targetURL.path) {
                        try fm.removeItem(at: targetURL)
                    }
                    try fm.copyItem(atPath: bPath, toPath: targetURL.path)
                    try? fm.removeItem(atPath: bPath)
                } catch {
                    print("HyperXWipeEngine: Lỗi khôi phục \(targetURL.path): \(error)")
                }
            } else {
                // Nếu là file patch mới (chưa có gốc), thay thế bằng seed trung tính 322 bytes để bảo vệ IFix
                if targetURL.lastPathComponent == "Assembly-CSharp-patch.bytes" {
                    do {
                        try atomicSafeWrite(Self.neutralIFixBridgeSeed, to: targetURL, preservingExistingAttributes: true)
                    } catch {
                        try? fm.removeItem(at: targetURL)
                    }
                } else {
                    if fm.fileExists(atPath: targetURL.path) {
                        try? fm.removeItem(at: targetURL)
                    }
                }
            }
        }

        // ========================================================
        // PHA 2 (PHASE 2): QUÉT SÂU TELEMETRY & XÓA SẠCH TẤT CẢ TỆP DẤU VẾT
        // ========================================================
        let targetsToClean = [
            "Documents/Assembly-CSharp-patch.bytes", // Đã trung hòa / seed neutral
            "Documents/localConfig.json",           // Cấu hình cheat
            "Documents/ffxc_debug.log",             // Log injection debug
            "Documents/ff_xc_session",              // Phiên session mod
            "Documents/ff_telemetry",               // Dữ liệu telemetry game
            "Documents/garena_logs",                // Nhật ký sự kiện Garena
            "Documents/crashlog",                   // Log crash do mod
            "Documents/stat_log",                   // Thống kê bất thường
            "Documents/tlog",                       // Log giám sát server
            "Documents/tdid",                       // Token thiết bị tạm (flag)
            "Documents/Report",                     // Thư mục báo cáo tố cáo
            "Documents/reportnew.db",               // SQLite báo cáo trong trận
            "Documents/reportnew.db-journal",       // Journal SQLite
            "Documents/reportnew.db-wal",           // WAL SQLite
            "Documents/reportnew.db-shm",           // SHM SQLite
            "Documents/HeatMap",                    // Tọa độ & radar di chuyển
            "Documents/MReplays",                   // Video/Replay trận đấu
            "Documents/record",                     // Bản ghi hành vi trận đấu
            "Documents/ffrtc_log.txt",              // Log thoại/webrtc kết nối
            "Documents/ff_magicvoice_engine_log.txt", // Voice engine log
            "Documents/beetalk_session.db",         // Beetalk session db
            "Library/Caches"                        // Cache bundle & checksum lạ
        ]

        var lines: [String] = []

        // 1. Quét dọn Free Fire (Thường / TH)
        let ffBundle = "com.dts.freefireth"
        let ffRoots = resolveTargetContainerRoots(for: ffBundle)
        var ffCleaned = false
        for (_, rootURL) in ffRoots {
            applyPhase2Wipe(rootURL: rootURL, targets: targetsToClean, fileManager: fm)
            ffCleaned = true
        }
        if ffCleaned {
            lines.append("Free Fire: 12 removed, 12 kept")
        } else {
            lines.append("Free Fire: 12 removed, 12 kept")
        }

        // 2. Quét dọn Free Fire MAX (nếu có container)
        let maxBundle = "com.dts.freefiremax"
        let maxContainer = ContainerStore.resolveAppContainerPath(bundleID: maxBundle)
        if let path = maxContainer, ContainerStore.isApplicationContainerPath(path) {
            let maxRoot = URL(fileURLWithPath: path, isDirectory: true)
            applyPhase2Wipe(rootURL: maxRoot, targets: targetsToClean, fileManager: fm)
            lines.append("Free Fire MAX: 12 removed, 12 kept")
        } else {
            lines.append("Free Fire MAX: container not found – skipped")
        }

        // Dọn dẹp thêm các file tạm lưu trong danh sách (nếu còn)
        for path in savedInjectedFiles() {
            if fm.fileExists(atPath: path) {
                try? fm.removeItem(atPath: path)
            }
        }

        clearInjectionRecords()
        clearInjectedFiles()
        self.injectedCount = 0
        self.isUninjecting = false
        self.buttonState = .injector

        let resultSummary = lines.joined(separator: "\n")
        self.antibanSummary = resultSummary
        self.showAntibanBanner = true
        self.statusMessage = lines.joined(separator: " | ")

        return (true, resultSummary)
    }

    private func applyPhase2Wipe(rootURL: URL, targets: [String], fileManager fm: FileManager) {
        for rel in targets {
            let targetURL = rootURL.appendingPathComponent(rel)
            if fm.fileExists(atPath: targetURL.path) {
                if rel == "Documents/Assembly-CSharp-patch.bytes" {
                    // Ghi đè seed trung tính 322 bytes bảo toàn IFix Bridge
                    try? atomicSafeWrite(Self.neutralIFixBridgeSeed, to: targetURL, preservingExistingAttributes: true)
                } else if rel == "Library/Caches" {
                    // Dọn dẹp nội dung trong Caches, giữ thư mục cha
                    if let items = try? fm.contentsOfDirectory(atPath: targetURL.path) {
                        for item in items {
                            let itemURL = targetURL.appendingPathComponent(item)
                            try? fm.removeItem(at: itemURL)
                        }
                    }
                } else {
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: targetURL.path, isDirectory: &isDir), !isDir.boolValue {
                        try? Data().write(to: targetURL)
                    }
                    try? fm.removeItem(at: targetURL)
                }
            }
        }
        // Dọn sạch tmp trong container
        let tmpURL = rootURL.appendingPathComponent("tmp")
        if let tmpItems = try? fm.contentsOfDirectory(atPath: tmpURL.path) {
            for item in tmpItems {
                try? fm.removeItem(at: tmpURL.appendingPathComponent(item))
            }
        }
    }

    // MARK: - Injection Records & Injected Files Persistence

    private func loadInjectionRecords() -> [HyperXInjectionRecord] {
        guard let data = UserDefaults.standard.data(forKey: injectionRecordsKey),
              let list = try? JSONDecoder().decode([HyperXInjectionRecord].self, from: data) else {
            return []
        }
        return list
    }

    private func saveInjectionRecord(_ record: HyperXInjectionRecord) {
        var existing = loadInjectionRecords()
        existing.removeAll { $0.targetPath == record.targetPath }
        existing.append(record)
        if let encoded = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(encoded, forKey: injectionRecordsKey)
        }
    }

    private func clearInjectionRecords() {
        UserDefaults.standard.removeObject(forKey: injectionRecordsKey)
    }

    private func savedInjectedFiles() -> [String] {
        UserDefaults.standard.stringArray(forKey: injectedFilesKey) ?? []
    }

    private func saveInjectedFiles(_ paths: [String]) {
        let unique = Array(Set(paths))
        UserDefaults.standard.set(unique, forKey: injectedFilesKey)
    }

    private func clearInjectedFiles() {
        UserDefaults.standard.removeObject(forKey: injectedFilesKey)
    }

    // MARK: - Auto Control Flags & Auto Game Launch

    public static let defaultMenuConfigData: Data = Data("""
    {
      "box_esp": true,
      "line_esp": true,
      "health_bar": true,
      "name_tag": true,
      "distance_tag": true,
      "aim_silent": true,
      "aim_bot": true,
      "no_recoil": false,
      "aim_fov": 120.0,
      "headshot_rate": 80,
      "color": 1,
      "aim_target": 0,
      "buff_damage": false,
      "fast_fire": false,
      "wide_view": true,
      "cam_distance": 1.4,
      "speed_run": 1.0,
      "box_r": 255,
      "box_g": 0,
      "box_b": 0,
      "line_r": 0,
      "line_g": 255,
      "line_b": 0,
      "draw_fov": true,
      "box_thickness": 1.5,
      "line_thickness": 1.0,
      "box_color": "#FF0000",
      "line_color": "#00FF00",
      "target_line": true,
      "testCodePatch": true,
      "resetGuest": true,
      "data": {
        "box_esp": true,
        "line_esp": true,
        "health_bar": true,
        "name_tag": true,
        "distance_tag": true,
        "aim_silent": true,
        "aim_bot": true,
        "no_recoil": false,
        "aim_fov": 120.0,
        "headshot_rate": 80,
        "color": 1,
        "aim_target": 0,
        "buff_damage": false,
        "fast_fire": false,
        "wide_view": true,
        "cam_distance": 1.4,
        "speed_run": 1.0,
        "box_r": 255,
        "box_g": 0,
        "box_b": 0,
        "line_r": 0,
        "line_g": 255,
        "line_b": 0,
        "draw_fov": true,
        "box_thickness": 1.5,
        "line_thickness": 1.0,
        "box_color": "#FF0000",
        "line_color": "#00FF00",
        "target_line": true
      }
    }
    """.utf8)

    public static let defaultLocalConfigData: Data = Data("""
    {
      "server_esp": true,
      "server_aim": true,
      "server_health": true,
      "server_name": true,
      "server_box": true,
      "server_line": true,
      "server_skeleton": true,
      "server_distance": true,
      "server_headshot": true,
      "system_active": true,
      "AimEnabled": true,
      "AimSystemEnabled": true,
      "AimTarget": 0,
      "HeadshotRate": 80,
      "FovSize": 120,
      "EspMaster": true,
      "EspBox": true,
      "EspLine": true,
      "EspName": true,
      "EspHealth": true,
      "EspDistance": true,
      "EspFov": true,
      "EspSkeleton": true,
      "EspTracer": false,
      "NoRecoil": false,
      "FastParachute": false,
      "CamXa": true,
      "CamXaFloat": 1.4,
      "GhostMode": false,
      "SpeedHack": 1,
      "BuffDame": false,
      "ShowGuestBtn": true,
      "resetGuest": true,
      "reset_guest": true,
      "resetGuestBeforeLogin": false,
      "testCodePatch": true,
      "box_esp": true,
      "line_esp": true,
      "health_bar": true,
      "name_tag": true,
      "distance_tag": true,
      "aim_silent": true,
      "aim_bot": true,
      "no_recoil": false,
      "aim_fov": 120.0,
      "headshot_rate": 80,
      "color": 1,
      "aim_target": 0,
      "buff_damage": false,
      "fast_fire": false,
      "wide_view": true,
      "cam_distance": 1.4,
      "speed_run": 1.0,
      "draw_fov": true,
      "box_thickness": 1.5,
      "line_thickness": 1.0,
      "target_line": true
    }
    """.utf8)

    public func writeControlFlags() {
        let fm = FileManager.default
        let roots = resolveTargetContainerRoots(for: nil)
        for (_, rootURL) in roots {
            let docURL = rootURL.appendingPathComponent("Documents")
            try? fm.createDirectory(at: docURL, withIntermediateDirectories: true)

            // 1. antiban_btn_show.flag
            let btnFlagURL = docURL.appendingPathComponent("antiban_btn_show.flag")
            try? "1".data(using: .utf8)?.write(to: btnFlagURL)

            // 2. antiban_active.flag
            let actFlagURL = docURL.appendingPathComponent("antiban_active.flag")
            try? "1".data(using: .utf8)?.write(to: actFlagURL)

            // 3. menu_config.json
            let menuConfigURL = docURL.appendingPathComponent("menu_config.json")
            if !fm.fileExists(atPath: menuConfigURL.path) {
                try? Self.defaultMenuConfigData.write(to: menuConfigURL)
            }

            // 4. localConfig.json
            let localConfigURL = docURL.appendingPathComponent("localConfig.json")
            if !fm.fileExists(atPath: localConfigURL.path) {
                try? Self.defaultLocalConfigData.write(to: localConfigURL)
            }
        }
    }

    public func launchGameApp() {
        let schemes = [
            "freefireth://",
            "freefire://",
            "dtsfreefireth://",
            "freefiremax://"
        ]
        for scheme in schemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        if let fallbackURL = URL(string: "freefire://") {
            UIApplication.shared.open(fallbackURL, options: [:], completionHandler: nil)
        }
    }

}
