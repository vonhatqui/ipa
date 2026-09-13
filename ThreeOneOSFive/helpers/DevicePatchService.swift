import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let bundleIDs = orderedBundleIdentifiers(in: project)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.apply(
                project: project,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
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

    static func restore(
        receipt: PatchTransactionReceipt,
        allowChangedTargets: Bool = true
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
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

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    static func isProjectApplied(projectID: UUID) -> Bool {
        latestReceipt(projectID: projectID) != nil
    }

    /// Xoá sạch toàn bộ journal/receipt cũ bị kẹt của project để tránh lỗi projectAlreadyApplied
    static func forceCleanupReceipts(projectID: UUID) {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return }
        let projectDirectory = backupRoot.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: projectDirectory)
    }

    /// Phục hồi cưỡng chế khi restore bình thường bị lỗi (file bị khóa, game đang mở, digest thay đổi, container thay đổi)
    static func forceRestoreAndCleanup(receipt: PatchTransactionReceipt?, project: PatchProject?) {
        let fileManager = FileManager.default
        let transactionDir = receipt?.journalURL.deletingLastPathComponent()

        if let project {
            let bundleIDs = project.allBundleIdentifiers
            let roots = (try? withResolvedContainers(bundleIDs: bundleIDs) { $0 }) ?? [:]

            for rule in project.rules {
                guard let root = roots[rule.bundleID] else { continue }
                guard let target = try? PatchPathValidator.resolveContainedTargetURL(
                    relativePath: rule.relativePath,
                    containerRoot: root
                ) else { continue }

                // Kiểm tra xem có file backup trong transaction directory không
                var restoredFromBackup = false
                if let transactionDir {
                    let backupURL = transactionDir.appendingPathComponent("\(rule.id.uuidString).original")
                    if fileManager.fileExists(atPath: backupURL.path) {
                        try? fileManager.removeItem(at: target)
                        try? fileManager.copyItem(at: backupURL, to: target)
                        restoredFromBackup = true
                    }
                }

                // Nếu không có backup (hoặc file gốc lúc trước không tồn tại), xoá file mod đi để game tải lại mặc định
                if !restoredFromBackup && fileManager.fileExists(atPath: target.path) {
                    try? fileManager.removeItem(at: target)
                }
            }
        }

        // Xoá sạch receipt kẹt
        if let project {
            forceCleanupReceipts(projectID: project.id)
        } else if let receipt {
            forceCleanupReceipts(projectID: receipt.projectID)
        }
    }

    /// Dọn dẹp sạch file mod khi không tìm thấy receipt
    static func forceCleanup(project: PatchProject?) {
        guard let project else { return }
        let fileManager = FileManager.default
        let bundleIDs = project.allBundleIdentifiers
        let roots = (try? withResolvedContainers(bundleIDs: bundleIDs) { $0 }) ?? [:]

        for rule in project.rules {
            guard let root = roots[rule.bundleID] else { continue }
            guard let target = try? PatchPathValidator.resolveContainedTargetURL(
                relativePath: rule.relativePath,
                containerRoot: root
            ) else { continue }

            if fileManager.fileExists(atPath: target.path) {
                try? fileManager.removeItem(at: target)
            }
        }
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
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
        return try operation(roots)
    }
}
