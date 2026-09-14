import Foundation

enum DevicePatchService {
    // MARK: - Concurrency & Synchronization
    /// Serial Queue đảm bảo các thao tác Apply / Restore / Cleanup diễn ra tuần tự, triệt tiêu hoàn toàn Race Condition
    private static let serialQueue = DispatchQueue(label: "com.threeoneosfive.devicepatch.serial", qos: .userInitiated)

    /// In-memory cache lưu trạng thái các project đã kích hoạt để UI kiểm tra tức thì, không gây lag đọc ổ đĩa
    private static var appliedProjectsCache: Set<UUID>? = nil
    private static let cacheLock = NSLock()

    // MARK: - Golden Snapshots (Bản sao lưu nguyên bản vĩnh viễn)
    /// Thư mục lưu trữ bản sao lưu nguyên bản (Golden Snapshots) của game Free Fire sạch trước khi mod
    private static func goldenSnapshotsDirectory(fileManager: FileManager = .default) throws -> URL {
        let backupRoot = try PatchProjectLibrary.backupRootURL(fileManager: fileManager)
        let goldenDir = backupRoot.appendingPathComponent("GoldenSnapshots", isDirectory: true)
        if !fileManager.fileExists(atPath: goldenDir.path) {
            try fileManager.createDirectory(at: goldenDir, withIntermediateDirectories: true)
        }
        return goldenDir
    }

    private static func snapshotKey(bundleID: String, relativePath: String) -> String {
        let safePath = relativePath.replacingOccurrences(of: "/", with: "___")
        return "\(bundleID)___\(safePath)"
    }

    /// Chụp lại bản sao lưu nguyên bản (Golden Snapshot) trước khi bất kỳ mod nào can thiệp
    static func captureGoldenSnapshotIfNeeded(
        targetURL: URL,
        bundleID: String,
        relativePath: String,
        replacementData: Data?,
        fileManager: FileManager = .default
    ) {
        do {
            let goldenDir = try goldenSnapshotsDirectory(fileManager: fileManager)
            let key = snapshotKey(bundleID: bundleID, relativePath: relativePath)
            let goldenFileURL = goldenDir.appendingPathComponent("\(key).golden")
            let notExistedMarkerURL = goldenDir.appendingPathComponent("\(key).not_existed")

            // Nếu đã từng lưu snapshot nguyên bản thì KHÔNG BAO GIỜ ghi đè, bảo tồn vĩnh viễn
            if fileManager.fileExists(atPath: goldenFileURL.path) || fileManager.fileExists(atPath: notExistedMarkerURL.path) {
                return
            }

            if fileManager.fileExists(atPath: targetURL.path) {
                // Kiểm tra xem file hiện tại có phải là file mod bị kẹt từ trước không
                if let modData = replacementData, let currentData = try? Data(contentsOf: targetURL) {
                    if currentData == modData {
                        // File hiện tại đã là file mod! Đánh dấu ban đầu nó KHÔNG TỒN TẠI ở game sạch
                        try? "".write(to: notExistedMarkerURL, atomically: true, encoding: .utf8)
                        log("patch: [GoldenSnapshot] File \(relativePath) hiện tại là mod, đánh dấu not_existed")
                        return
                    }
                }
                // File này nguyên bản sạch, lưu vào Golden Snapshot
                try? fileManager.copyItem(at: targetURL, to: goldenFileURL)
                log("patch: [GoldenSnapshot] Đã chụp thành công file gốc: \(relativePath)")
            } else {
                // File gốc vốn không tồn tại trong game sạch (ví dụ Assembly-CSharp-patch.bytes, config.bin)
                try? "".write(to: notExistedMarkerURL, atomically: true, encoding: .utf8)
                log("patch: [GoldenSnapshot] Đánh dấu file mới không tồn tại ở game gốc: \(relativePath)")
            }
        } catch {
            log("patch: [GoldenSnapshot] Lỗi chụp snapshot: \(error)")
        }
    }

    /// Khôi phục 100% dữ liệu nguyên bản từ Golden Snapshot
    static func restoreFromGoldenSnapshot(
        targetURL: URL,
        bundleID: String,
        relativePath: String,
        modData: Data?,
        fileManager: FileManager = .default
    ) -> Bool {
        guard let goldenDir = try? goldenSnapshotsDirectory(fileManager: fileManager) else { return false }
        let key = snapshotKey(bundleID: bundleID, relativePath: relativePath)
        let goldenFileURL = goldenDir.appendingPathComponent("\(key).golden")
        let notExistedMarkerURL = goldenDir.appendingPathComponent("\(key).not_existed")

        if fileManager.fileExists(atPath: goldenFileURL.path) {
            // File gốc có tồn tại -> Khôi phục đè lại file gốc sạch
            try? fileManager.removeItem(at: targetURL)
            let parent = targetURL.deletingLastPathComponent()
            try? fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
            do {
                try fileManager.copyItem(at: goldenFileURL, to: targetURL)
                log("patch: [GoldenSnapshot] Đã phục hồi 100% file gốc: \(relativePath)")
                return true
            } catch {
                log("patch: [GoldenSnapshot] Lỗi copy file gốc: \(error)")
            }
        } else if fileManager.fileExists(atPath: notExistedMarkerURL.path) {
            // File gốc vốn không tồn tại -> Xoá sạch file mod
            if fileManager.fileExists(atPath: targetURL.path) {
                try? fileManager.removeItem(at: targetURL)
                log("patch: [GoldenSnapshot] Đã xoá bỏ hoàn toàn file inject: \(relativePath)")
            }
            return true
        } else {
            // Chưa có marker, nhưng nếu file hiện tại giống modData -> Xoá đi
            if let modData = modData, let currentData = try? Data(contentsOf: targetURL), currentData == modData {
                try? fileManager.removeItem(at: targetURL)
                log("patch: [GoldenSnapshot] Xoá file trùng khớp mod: \(relativePath)")
                return true
            }
        }
        return false
    }

    // MARK: - Quản lý Container Cả Hai Bản Free Fire & Free Fire MAX
    /// Lấy danh sách tất cả thư mục container của Free Fire (cả Standard lẫn MAX)
    static func allAvailableFreeFireContainers() -> [String: URL] {
        var result: [String: URL] = [:]
        let targets = ["com.dts.freefireth", "com.dts.freefiremax"]
        for bID in targets {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bID),
               ContainerStore.isApplicationContainerPath(path) {
                result[bID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
            }
        }
        return result
    }

    // MARK: - Apply (Bật chức năng)
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        try serialQueue.sync {
            let bundleIDs = orderedBundleIdentifiers(in: project)
            let roots = try resolveContainers(bundleIDs: bundleIDs)
            let fileManager = FileManager.default
            let allContainers = allAvailableFreeFireContainers()

            // 1. Chụp Golden Snapshot cho TOÀN BỘ file mục tiêu trước khi áp dụng
            for rule in project.rules {
                for (bID, root) in allContainers {
                    if let target = try? PatchPathValidator.resolveContainedTargetURL(
                        relativePath: rule.relativePath,
                        containerRoot: root
                    ) {
                        captureGoldenSnapshotIfNeeded(
                            targetURL: target,
                            bundleID: bID,
                            relativePath: rule.relativePath,
                            replacementData: rule.replacementData,
                            fileManager: fileManager
                        )
                    }
                }
            }

            // Đồng thời chụp Golden Snapshot cho cả com.dts.freefiremax.plist nếu có
            for (_, root) in allContainers {
                let maxPlist = root.appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
                captureGoldenSnapshotIfNeeded(
                    targetURL: maxPlist,
                    bundleID: "com.dts.freefiremax",
                    relativePath: "Library/Preferences/com.dts.freefiremax.plist",
                    replacementData: nil,
                    fileManager: fileManager
                )
            }

            // 2. Tự động chuyển đổi thông minh: Nếu có project khác đang chiếm target file trùng lặp, tự động khôi phục project đó trước
            let backupRoot = try PatchProjectLibrary.backupRootURL()
            let occupied = PatchTransaction.appliedTargetKeys(backupRoot: backupRoot, excludingProjectID: project.id, fileManager: fileManager)
            var conflictingPIDs = Set<UUID>()
            for rule in project.rules {
                let key = rule.bundleID + "\0" + rule.relativePath
                if occupied.contains(key) {
                    if let entries = try? fileManager.contentsOfDirectory(atPath: backupRoot.path) {
                        for entry in entries {
                            if let otherPID = UUID(uuidString: entry), otherPID != project.id {
                                conflictingPIDs.insert(otherPID)
                            }
                        }
                    }
                }
            }
            for conflictPID in conflictingPIDs {
                if let conflictReceipt = PatchTransaction.latestReceipt(projectID: conflictPID, backupRoot: backupRoot) {
                    try? PatchTransaction.restore(receipt: conflictReceipt, allowChangedTargets: true, containerResolver: { bID in
                        roots[bID] ?? URL(fileURLWithPath: "/")
                    })
                }
                forceCleanupReceipts(projectID: conflictPID)
                setProjectAppliedInMemory(projectID: conflictPID, applied: false)
            }

            // Nếu chính project này có receipt cũ, dọn sạch trước khi apply lại
            if let existingReceipt = PatchTransaction.latestReceipt(projectID: project.id, backupRoot: backupRoot) {
                try? PatchTransaction.restore(receipt: existingReceipt, allowChangedTargets: true, containerResolver: { bID in
                    guard let r = roots[bID] else { throw PatchPackageError.targetAppUnavailable(bID) }
                    return r
                })
            }
            // Dọn dẹp receipt cũ
            forceCleanupReceipts(projectID: project.id)

            // 3. Thực hiện Apply chuẩn qua PatchTransaction
            let receipt = try PatchTransaction.apply(
                project: project,
                backupRoot: backupRoot,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )

            // 4. Đồng bộ file sang Free Fire MAX nếu máy cài cả hai bản
            if let maxRoot = allContainers["com.dts.freefiremax"], roots["com.dts.freefireth"] != nil {
                for rule in project.rules {
                    if let maxTarget = try? PatchPathValidator.resolveContainedTargetURL(
                        relativePath: rule.relativePath,
                        containerRoot: maxRoot
                    ) {
                        let parent = maxTarget.deletingLastPathComponent()
                        try? fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
                        try? rule.replacementData.write(to: maxTarget, options: .atomic)
                    }
                }
                // Đồng bộ plist
                if let thRoot = roots["com.dts.freefireth"] {
                    let thPlist = thRoot.appendingPathComponent("Library/Preferences/com.dts.freefireth.plist")
                    let maxPlist = maxRoot.appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
                    if fileManager.fileExists(atPath: thPlist.path) {
                        try? fileManager.removeItem(at: maxPlist)
                        try? fileManager.copyItem(at: thPlist, to: maxPlist)
                    }
                }
            }

            // Cập nhật in-memory cache
            setProjectAppliedInMemory(projectID: project.id, applied: true)
            return receipt
        }
    }

    // MARK: - Restore & Rollback (Tắt chức năng)
    static func restore(
        receipt: PatchTransactionReceipt,
        project: PatchProject? = nil,
        allowChangedTargets: Bool = true
    ) throws {
        try serialQueue.sync {
            let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
            let roots = (try? resolveContainers(bundleIDs: bundleIDs)) ?? [:]

            // 1. Thử restore chuẩn qua PatchTransaction
            do {
                try PatchTransaction.restore(
                    receipt: receipt,
                    allowChangedTargets: allowChangedTargets,
                    containerResolver: { bundleID in
                        guard let root = roots[bundleID] else {
                            throw PatchPackageError.targetAppUnavailable(bundleID)
                        }
                        return root
                    }
                )
            } catch {
                log("patch: PatchTransaction.restore gặp lỗi: \(error), tiến hành khôi phục sâu qua Golden Snapshots...")
            }

            // 2. PHỤC HỒI TRIỆT ĐỂ: Chỉ khôi phục các file thuộc về project này từ Golden Snapshot
            let resolvedProject = project ?? (try? PatchProjectLibrary.load(fileManager: FileManager.default).first(where: { $0.id == receipt.projectID }))?.project
            restoreAllGoldenSnapshots(for: resolvedProject)

            // 3. Dọn dẹp receipt & cập nhật cache
            forceCleanupReceipts(projectID: receipt.projectID)
            setProjectAppliedInMemory(projectID: receipt.projectID, applied: false)
        }
    }

    /// Khôi phục toàn bộ các file từ Golden Snapshot
    static func restoreAllGoldenSnapshots(for project: PatchProject? = nil) {
        let fileManager = FileManager.default
        let allContainers = allAvailableFreeFireContainers()

        if let project = project {
            for rule in project.rules {
                for (bID, root) in allContainers {
                    if let target = try? PatchPathValidator.resolveContainedTargetURL(
                        relativePath: rule.relativePath,
                        containerRoot: root
                    ) {
                        _ = restoreFromGoldenSnapshot(
                            targetURL: target,
                            bundleID: bID,
                            relativePath: rule.relativePath,
                            modData: rule.replacementData,
                            fileManager: fileManager
                        )
                    }
                }
            }
        } else {
            guard let goldenDir = try? goldenSnapshotsDirectory(fileManager: fileManager),
                  let items = try? fileManager.contentsOfDirectory(atPath: goldenDir.path) else { return }

            for item in items {
                let isGolden = item.hasSuffix(".golden")
                let isNotExisted = item.hasSuffix(".not_existed")
                guard isGolden || isNotExisted else { continue }

                let filenameWithoutExt = (item as NSString).deletingPathExtension
                let parts = filenameWithoutExt.components(separatedBy: "___")
                guard parts.count >= 2 else { continue }

                let bID = parts[0]
                let relativePath = parts.dropFirst().joined(separator: "/")

                guard let root = allContainers[bID] else { continue }
                guard let target = try? PatchPathValidator.resolveContainedTargetURL(
                    relativePath: relativePath,
                    containerRoot: root
                ) else { continue }

                _ = restoreFromGoldenSnapshot(
                    targetURL: target,
                    bundleID: bID,
                    relativePath: relativePath,
                    modData: nil,
                    fileManager: fileManager
                )
            }
        }

        // Đảm bảo phục hồi cả com.dts.freefiremax.plist
        if let maxRoot = allContainers["com.dts.freefiremax"] {
            let maxPlist = maxRoot.appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
            _ = restoreFromGoldenSnapshot(
                targetURL: maxPlist,
                bundleID: "com.dts.freefiremax",
                relativePath: "Library/Preferences/com.dts.freefiremax.plist",
                modData: nil,
                fileManager: fileManager
            )
        }
    }

    /// Phục hồi cưỡng chế khi restore bình thường bị lỗi (file bị khóa, game đang mở, digest thay đổi, container thay đổi)
    static func forceRestoreAndCleanup(receipt: PatchTransactionReceipt?, project: PatchProject?) {
        serialQueue.sync {
            let projectID = project?.id ?? receipt?.projectID

            // 1. Nếu có receipt, thử restore
            if let receipt = receipt {
                let bundleIDs = (try? PatchTransaction.requiredBundleIdentifiers(for: receipt)) ?? []
                if let roots = try? resolveContainers(bundleIDs: bundleIDs) {
                    try? PatchTransaction.restore(
                        receipt: receipt,
                        allowChangedTargets: true,
                        containerResolver: { roots[$0] ?? URL(fileURLWithPath: "/") }
                    )
                }
            }

            // 2. Khôi phục từ Golden Snapshots cho mọi rule của project
            restoreAllGoldenSnapshots(for: project)

            // 3. Xoá receipt & cập nhật cache
            if let projectID = projectID {
                forceCleanupReceipts(projectID: projectID)
                setProjectAppliedInMemory(projectID: projectID, applied: false)
            }
        }
    }

    /// Dọn dẹp sạch file mod khi không tìm thấy receipt
    static func forceCleanup(project: PatchProject?) {
        serialQueue.sync {
            restoreAllGoldenSnapshots(for: project)
            if let project = project {
                forceCleanupReceipts(projectID: project.id)
                setProjectAppliedInMemory(projectID: project.id, applied: false)
            }
        }
    }

    static func inspectRestore(receipt: PatchTransactionReceipt) throws -> PatchRestoreInspection {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.inspectRestore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func resetToAppliedState(
        receipt: PatchTransactionReceipt,
        project: PatchProject
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.resetToAppliedState(
                receipt: receipt,
                fallbackProject: project,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    // MARK: - State Tracking (In-Memory & Disk)
    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    static func isProjectApplied(projectID: UUID) -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cache = appliedProjectsCache {
            return cache.contains(projectID)
        }

        // Khởi tạo cache từ disk lần đầu
        var set = Set<UUID>()
        if let backupRoot = try? PatchProjectLibrary.backupRootURL() {
            if let entries = try? FileManager.default.contentsOfDirectory(atPath: backupRoot.path) {
                for entry in entries {
                    if let pid = UUID(uuidString: entry),
                       PatchTransaction.latestReceipt(projectID: pid, backupRoot: backupRoot) != nil {
                        set.insert(pid)
                    }
                }
            }
        }
        appliedProjectsCache = set
        return set.contains(projectID)
    }

    private static func setProjectAppliedInMemory(projectID: UUID, applied: Bool) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if appliedProjectsCache == nil {
            appliedProjectsCache = Set<UUID>()
        }
        if applied {
            appliedProjectsCache?.insert(projectID)
        } else {
            appliedProjectsCache?.remove(projectID)
        }
    }

    static func invalidateAppliedCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        appliedProjectsCache = nil
    }

    /// Xoá sạch toàn bộ journal/receipt cũ bị kẹt của project để tránh lỗi projectAlreadyApplied
    static func forceCleanupReceipts(projectID: UUID) {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return }
        let projectDirectory = backupRoot.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: projectDirectory)
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    static func resolveContainers(bundleIDs: [String]) throws -> [String: URL] {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
               ContainerStore.isApplicationContainerPath(path) {
                roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
            } else if let alt = ContainerStore.alternativeBundleID(for: bundleID),
                      let path = ContainerStore.resolveAppContainerPath(bundleID: alt),
                      ContainerStore.isApplicationContainerPath(path) {
                log("patch: mapped \(bundleID) to alternative container \(alt)")
                roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
            } else {
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
        }
        return roots
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        let roots = try resolveContainers(bundleIDs: bundleIDs)
        return try operation(roots)
    }
}
