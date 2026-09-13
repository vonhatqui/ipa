import Foundation

enum BundledPatchInjector {
    static func autoImportBundledPatches(into store: PatchProjectStore) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            guard let targetRoot = try? PatchProjectLibrary.packageRootURL(fileManager: fileManager) else {
                print("[BundledPatchInjector] Không lấy được packageRootURL")
                return
            }

            // Tạo thư mục Packages nếu chưa có
            try? fileManager.createDirectory(at: targetRoot, withIntermediateDirectories: true)

            var candidateURLs: [URL] = []

            // 1. Quét trực tiếp thư mục gốc Bundle .app
            let bundlePath = Bundle.main.bundlePath
            if let rootContents = try? fileManager.contentsOfDirectory(atPath: bundlePath) {
                for item in rootContents where item.lowercased().hasSuffix(".3105") {
                    let fullPath = (bundlePath as NSString).appendingPathComponent(item)
                    candidateURLs.append(URL(fileURLWithPath: fullPath))
                }
            }

            // 2. Quét thư mục BundledPatches bên trong .app
            let bundledPatchesPath = (bundlePath as NSString).appendingPathComponent("BundledPatches")
            if let folderContents = try? fileManager.contentsOfDirectory(atPath: bundledPatchesPath) {
                for item in folderContents where item.lowercased().hasSuffix(".3105") {
                    let fullPath = (bundledPatchesPath as NSString).appendingPathComponent(item)
                    candidateURLs.append(URL(fileURLWithPath: fullPath))
                }
            }

            // 3. Quét resourcePath nếu khác bundlePath
            if let resPath = Bundle.main.resourcePath, resPath != bundlePath {
                if let resContents = try? fileManager.contentsOfDirectory(atPath: resPath) {
                    for item in resContents where item.lowercased().hasSuffix(".3105") {
                        let fullPath = (resPath as NSString).appendingPathComponent(item)
                        candidateURLs.append(URL(fileURLWithPath: fullPath))
                    }
                }
                let resBundledPath = (resPath as NSString).appendingPathComponent("BundledPatches")
                if let resBundledContents = try? fileManager.contentsOfDirectory(atPath: resBundledPath) {
                    for item in resBundledContents where item.lowercased().hasSuffix(".3105") {
                        let fullPath = (resBundledPath as NSString).appendingPathComponent(item)
                        candidateURLs.append(URL(fileURLWithPath: fullPath))
                    }
                }
            }

            // 4. Quét theo Bundle resource API chuẩn của iOS
            if let rootMatches = Bundle.main.urls(forResourcesWithExtension: "3105", subdirectory: nil) {
                candidateURLs.append(contentsOf: rootMatches)
            }
            if let folderMatches = Bundle.main.urls(forResourcesWithExtension: "3105", subdirectory: "BundledPatches") {
                candidateURLs.append(contentsOf: folderMatches)
            }

            // Lọc các đường dẫn trùng lặp
            var seenPaths = Set<String>()
            var uniqueCandidates: [URL] = []
            for url in candidateURLs {
                let path = url.standardizedFileURL.path
                if !seenPaths.contains(path) {
                    seenPaths.insert(path)
                    uniqueCandidates.append(url)
                }
            }

            print("[BundledPatchInjector] Tìm thấy \(uniqueCandidates.count) file mod bundle: \(uniqueCandidates.map { $0.lastPathComponent })")

            for sourceURL in uniqueCandidates {
                do {
                    let filename = sourceURL.lastPathComponent
                    let destinationURL = targetRoot.appendingPathComponent(filename)

                    if fileManager.fileExists(atPath: destinationURL.path) {
                        let srcSize = (try? fileManager.attributesOfItem(atPath: sourceURL.path)[.size] as? Int64) ?? 0
                        let dstSize = (try? fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64) ?? 0
                        if dstSize == 0 || dstSize != srcSize {
                            try? fileManager.removeItem(at: destinationURL)
                            try fileManager.copyItem(at: sourceURL, to: destinationURL)
                            print("[BundledPatchInjector] Cập nhật lại mod \(filename) (size: \(srcSize))")
                        }
                    } else {
                        try fileManager.copyItem(at: sourceURL, to: destinationURL)
                        print("[BundledPatchInjector] Đã nạp mod mới \(filename)")
                    }
                } catch {
                    print("[BundledPatchInjector] Lỗi copy mod \(sourceURL.lastPathComponent): \(error)")
                }
            }

            // Tải lại thư viện patch trên main thread
            DispatchQueue.main.async {
                store.reload()
            }
        }
    }
}
