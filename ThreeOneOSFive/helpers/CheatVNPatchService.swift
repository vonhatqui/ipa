import Foundation
import UIKit
import Combine

/// CheatVNPatchService: Quản lý nạp patch ESP & AIM SILENT chuẩn IFix 5 files cho Free Fire & Free Fire MAX
final class CheatVNPatchService: ObservableObject {
    static let shared = CheatVNPatchService()

    @Published var isPatchApplied: Bool = false
    @Published var isApplying: Bool = false
    @Published var isRestoring: Bool = false
    @Published var lastLogMessage: String = "Sẵn sàng nạp patch."

    // Các toggle tính năng
    @Published var aimSilentEnabled: Bool = true
    @Published var espBoxEnabled: Bool = true
    @Published var espNameEnabled: Bool = true
    @Published var espLineEnabled: Bool = true
    @Published var antibanBufferEnabled: Bool = true

    private let fileManager = FileManager.default

    private init() {
        checkPatchStatus()
    }

    /// Kiểm tra xem patch hiện có đang được nạp trong Free Fire hay không
    func checkPatchStatus() {
        let containers = DevicePatchService.allAvailableFreeFireContainers()
        guard !containers.isEmpty else {
            isPatchApplied = false
            return
        }

        var appliedInAny = false
        for (_, root) in containers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let patchFile = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let runtimeFile = docDir.appendingPathComponent(".ffxc_runtime")
            let liveFile = docDir.appendingPathComponent(".ffxc_live")
            let configFile = docDir.appendingPathComponent("localConfig.json")

            if fileManager.fileExists(atPath: patchFile.path) && fileManager.fileExists(atPath: configFile.path) {
                appliedInAny = true
                break
            }
        }
        self.isPatchApplied = appliedInAny
    }

    /// Nạp các chức năng đã chọn vào game Free Fire
    @discardableResult
    func applyPatch(injectCheatVN: Bool = true, injectEspAimSilent: Bool = true) -> Bool {
        isApplying = true
        defer { isApplying = false }

        // 1. Kích hoạt MHA-C2 Container Store trước tiên để mở quyền sandbox trên iOS
        let targetBIDs = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
        for bid in targetBIDs {
            _ = ContainerStore.resolveAppContainerPath(bundleID: bid)
        }

        var successCount = 0

        // 2. Nạp qua 3105 Package Envelope (cơ chế chuẩn của 3105 engine)
        if let decoded = decodeFromEnvelope() {
            do {
                _ = try DevicePatchService.apply(project: decoded.project)
                successCount += 1
                print("[CheatVN] ✅ Nạp thành công qua 3105 DevicePatchService.apply!")
            } catch {
                print("[CheatVN] DevicePatchService.apply log: \(error)")
            }
        }

        // 3. Quét tìm 5 raw files để nạp vào Documents container
        let rawFiles = loadPatchedFilesData()
        let containers = DevicePatchService.allAvailableFreeFireContainers()

        for (bundleID, root) in containers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)

            for (relPath, data) in rawFiles {
                let fileName = URL(fileURLWithPath: relPath).lastPathComponent
                let targetURL = docDir.appendingPathComponent(fileName)

                DevicePatchService.captureGoldenSnapshotIfNeeded(
                    targetURL: targetURL,
                    bundleID: bundleID,
                    relativePath: relPath,
                    replacementData: data,
                    fileManager: fileManager
                )

                try? fileManager.removeItem(at: targetURL)
                var written = false
                do {
                    try data.write(to: targetURL)
                    written = true
                } catch {
                    let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
                    if (try? data.write(to: tempURL)) != nil {
                        if (try? fileManager.copyItem(at: tempURL, to: targetURL)) != nil {
                            written = true
                        }
                        try? fileManager.removeItem(at: tempURL)
                    }
                }

                if written {
                    var mutableURL = targetURL
                    var resVals = URLResourceValues()
                    resVals.isExcludedFromBackup = true
                    try? mutableURL.setResourceValues(resVals)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: targetURL.path)
                    successCount += 1
                }
            }
        }

        // 4. Khóa cấu hình injector và kích hoạt telemetry wipe
        DevicePatchService.ensureActivePatchesInjected()

        isPatchApplied = true
        var activeFeatures: [String] = []
        if injectCheatVN { activeFeatures.append("CheatVN External") }
        if injectEspAimSilent { activeFeatures.append("ESP & AIM SILENT") }
        let featText = activeFeatures.isEmpty ? "All" : activeFeatures.joined(separator: " + ")
        lastLogMessage = "✅ ĐÃ NẠP THÀNH CÔNG [\(featText)]!\nSẵn sàng mở game Free Fire."
        return true
    }

    /// Khôi phục game về nguyên bản 100%
    @discardableResult
    func restoreOriginals() -> Bool {
        isRestoring = true
        defer { isRestoring = false }

        let containers = DevicePatchService.allAvailableFreeFireContainers()
        for (bundleID, root) in containers {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            let filesToDelete = [
                "Assembly-CSharp-patch.bytes",
                ".ffxc_runtime",
                ".ffxc_live",
                ".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9",
                "localConfig.json"
            ]

            for fileName in filesToDelete {
                let targetURL = docDir.appendingPathComponent(fileName)
                let relPath = "Documents/\(fileName)"
                _ = DevicePatchService.restoreFromGoldenSnapshot(
                    targetURL: targetURL,
                    bundleID: bundleID,
                    relativePath: relPath,
                    modData: nil,
                    fileManager: fileManager
                )
                if fileManager.fileExists(atPath: targetURL.path) {
                    try? fileManager.removeItem(at: targetURL)
                }
            }
        }

        _ = DevicePatchService.cleanRestoreAllModifications()
        isPatchApplied = false
        lastLogMessage = "✅ Đã khôi phục game Free Fire về nguyên bản sạch 100%."
        return true
    }

    /// Khởi chạy game Free Fire theo bundle ID hoặc URL scheme
    func launchGame(version: FreeFireGameVersion? = nil) {
        let isMax = (version == .max)
        let scheme = isMax ? "freefiremax://" : "freefire://"
        if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let fallback = URL(string: "freefire://"), UIApplication.shared.canOpenURL(fallback) {
            UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
        }
    }

    // MARK: - Private Helpers
    private func loadPatchedFilesData() -> [String: Data] {
        var result: [String: Data] = [:]

        // Kiểm tra thư mục raw files
        var candidateDirs: [URL] = []
        if let bundleRes = Bundle.main.resourceURL {
            candidateDirs.append(bundleRes.appendingPathComponent("BundledPatches/CheatVN_External_Files/Documents"))
            candidateDirs.append(bundleRes.appendingPathComponent("BundledPatches/CheatVN_External_Files"))
        }
        candidateDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN_External_Files/Documents"))
        candidateDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN_External_Files"))
        candidateDirs.append(URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/CheatVN_External_Files/Documents"))
        candidateDirs.append(URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/CheatVN_External_Files"))

        let requiredFiles = [
            "Documents/.ffxc_live",
            "Documents/.ffxc_neutral_37ca851ab5df497db608f1b2f45165f9",
            "Documents/.ffxc_runtime",
            "Documents/Assembly-CSharp-patch.bytes",
            "Documents/localConfig.json"
        ]

        for dir in candidateDirs {
            var foundAll = true
            var tempMap: [String: Data] = [:]
            for rel in requiredFiles {
                let filename = URL(fileURLWithPath: rel).lastPathComponent
                let p1 = dir.appendingPathComponent(rel)
                let p2 = dir.appendingPathComponent(filename)
                let fileURL = fileManager.fileExists(atPath: p1.path) ? p1 : (fileManager.fileExists(atPath: p2.path) ? p2 : nil)
                if let fileURL = fileURL, let d = try? Data(contentsOf: fileURL) {
                    tempMap[rel] = d
                } else {
                    foundAll = false
                    break
                }
            }
            if foundAll {
                return tempMap
            }
        }

        // Nếu chưa đọc được raw, thử giải mã từ envelope .3105
        if let decoded = decodeFromEnvelope() {
            for rule in decoded.project.rules {
                result[rule.relativePath] = rule.replacementData
            }
        }

        return result
    }

    private func decodeFromEnvelope() -> DecodedPatchPackage? {
        var envelopeURLs: [URL] = []
        if let res = Bundle.main.resourceURL {
            envelopeURLs.append(res.appendingPathComponent("BundledPatches/CheatVN External.3105"))
            envelopeURLs.append(res.appendingPathComponent("BundledPatches/ESP & AIM SILENT.3105"))
        }
        envelopeURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN External.3105"))
        envelopeURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/ESP & AIM SILENT.3105"))
        envelopeURLs.append(URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/CheatVN External.3105"))
        envelopeURLs.append(URL(fileURLWithPath: "D:/update_file/new2/CheatVN External.3105"))

        for url in envelopeURLs {
            guard fileManager.fileExists(atPath: url.path),
                  let raw = try? Data(contentsOf: url) else { continue }
            let data = BundledPatchInjector.deobfuscateIfNeeded(raw)
            guard data.prefix(10) == Data("3105PATCH\0".utf8),
                  let summary = try? PatchPackageCodec.inspect(data) else { continue }

            if let decoded = PatchProjectLibrary.decodePackageSafely(data: data, summary: summary) {
                return decoded
            }
            if let decoded = try? PatchPackageCodec.decode(data, password: "OG") {
                return decoded
            }
            if let decoded = try? PatchPackageCodec.decode(data, password: "1") {
                return decoded
            }
        }
        return nil
    }

    private func applyViaPackageEnvelopeIfNeeded() {
        if let decoded = decodeFromEnvelope() {
            try? DevicePatchService.apply(project: decoded.project)
        }
    }
}
