import Foundation
import UIKit

/// =========================================================================
/// ContainerManager - Quản lý container ứng dụng & nạp/hủy cấu hình độc lập
/// =========================================================================
public final class ContainerManager {
    public static let shared = ContainerManager()

    public enum InjectionResult {
        case success(count: Int)
        case noContainerFound
        case missingPayload
        case failure(String)
    }

    private let targetBundleIDs = [
        "com.dts.freefireth",
        "com.dts.freefiremax",
        "com.dts.freefire",
        "com.dts.freefirevn"
    ]

    private var goldenSnapshots: [URL: Data] = [:]

    // MARK: - Resolve Available Containers
    public func resolveContainers() -> [URL] {
        var resolved: [URL] = []
        let fm = FileManager.default

        // Method 1: Private API LSApplicationWorkspace
        if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
           let defaultWorkspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? NSObject,
           let apps = defaultWorkspace.perform(NSSelectorFromString("allApplications"))?.takeUnretainedValue() as? [NSObject] {
            for app in apps {
                if let bid = app.perform(NSSelectorFromString("bundleIdentifier"))?.takeUnretainedValue() as? String,
                   let containerURL = app.perform(NSSelectorFromString("containerURL"))?.takeUnretainedValue() as? URL {
                    let lower = bid.lowercased()
                    for target in targetBundleIDs {
                        if lower == target || lower.contains("freefire") {
                            if !resolved.contains(containerURL) {
                                resolved.append(containerURL)
                            }
                        }
                    }
                }
            }
        }

        // Method 2: Quét thư mục Data Application chuẩn iOS nếu có quyền truy cập
        let dataAppPath = "/var/mobile/Containers/Data/Application"
        if fm.fileExists(atPath: dataAppPath), let enumerator = try? fm.contentsOfDirectory(atPath: dataAppPath) {
            for folder in enumerator {
                let candidateURL = URL(fileURLWithPath: dataAppPath).appendingPathComponent(folder)
                let metadataPlist = candidateURL.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
                if fm.fileExists(atPath: metadataPlist.path),
                   let dict = NSDictionary(contentsOf: metadataPlist) as? [String: Any],
                   let bid = dict["MCMMetadataIdentifier"] as? String {
                    let lower = bid.lowercased()
                    for target in targetBundleIDs {
                        if lower == target || lower.contains("freefire") {
                            if !resolved.contains(candidateURL) {
                                resolved.append(candidateURL)
                            }
                        }
                    }
                }
            }
        }

        // Method 3: Fallback Sandbox Documents (chế độ độc lập / giả lập)
        if resolved.isEmpty {
            if let docURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                resolved.append(docURL)
            }
        }

        return resolved
    }

    // MARK: - Perform Injection
    public func injectPatchAndConfig(configData: Data, patchData: Data?) -> InjectionResult {
        let containers = resolveContainers()
        guard !containers.isEmpty else {
            return .noContainerFound
        }

        let fm = FileManager.default
        var successCount = 0

        for root in containers {
            let docDir = root.path.hasSuffix("Documents") ? root : root.appendingPathComponent("Documents", isDirectory: true)
            try? fm.createDirectory(at: docDir, withIntermediateDirectories: true)

            let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let dstConfig = docDir.appendingPathComponent("localConfig.json")

            // 1. Sao lưu file gốc trước khi ghi nếu chưa từng lưu
            if goldenSnapshots[dstConfig] == nil, let originalConfig = try? Data(contentsOf: dstConfig) {
                goldenSnapshots[dstConfig] = originalConfig
            }
            if let pData = patchData, goldenSnapshots[dstPatch] == nil, let originalPatch = try? Data(contentsOf: dstPatch) {
                goldenSnapshots[dstPatch] = originalPatch
            }

            // 2. Ghi đè localConfig.json
            try? fm.removeItem(at: dstConfig)
            let configWritten = (try? configData.write(to: dstConfig, options: .atomic)) != nil
            if configWritten {
                try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstConfig.path)
            }

            // 3. Ghi đè Assembly-CSharp-patch.bytes nếu có
            var patchWritten = true
            if let pData = patchData {
                try? fm.removeItem(at: dstPatch)
                patchWritten = (try? pData.write(to: dstPatch, options: .atomic)) != nil
                if patchWritten {
                    try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstPatch.path)
                }
            }

            if configWritten && patchWritten {
                successCount += 1
            }
        }

        if successCount > 0 {
            return .success(count: successCount)
        } else {
            return .failure("Không thể ghi file vào thư mục game")
        }
    }

    // MARK: - Perform Uninject & Cleanup
    public func uninjectAndClean() -> Bool {
        let containers = resolveContainers()
        let fm = FileManager.default

        for root in containers {
            let docDir = root.path.hasSuffix("Documents") ? root : root.appendingPathComponent("Documents", isDirectory: true)
            let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let dstConfig = docDir.appendingPathComponent("localConfig.json")

            // Khôi phục bản gốc nếu có, hoặc xóa hoàn toàn
            if let origConfig = goldenSnapshots[dstConfig] {
                try? origConfig.write(to: dstConfig, options: .atomic)
            } else {
                try? fm.removeItem(at: dstConfig)
            }

            if let origPatch = goldenSnapshots[dstPatch] {
                try? origPatch.write(to: dstPatch, options: .atomic)
            } else {
                try? fm.removeItem(at: dstPatch)
            }
        }

        goldenSnapshots.removeAll()
        return true
    }
}
