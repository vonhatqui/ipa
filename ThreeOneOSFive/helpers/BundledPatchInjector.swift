import Foundation

enum BundledPatchInjector {
    static func autoImportBundledPatches(into store: PatchProjectStore) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            guard let targetRoot = try? PatchProjectLibrary.packageRootURL(fileManager: fileManager) else { return }

            var candidateURLs: [URL] = []

            // 1. Quét file .3105 ở thư mục gốc Bundle
            if let rootMatches = Bundle.main.urls(forResourcesWithExtension: "3105", subdirectory: nil) {
                candidateURLs.append(contentsOf: rootMatches)
            }

            // 2. Quét thư mục BundledPatches trong Bundle
            if let folderMatches = Bundle.main.urls(forResourcesWithExtension: "3105", subdirectory: "BundledPatches") {
                candidateURLs.append(contentsOf: folderMatches)
            }

            // 3. Quét trực tiếp Resource path nếu có
            if let resourcePath = Bundle.main.resourcePath {
                let bundledFolderPath = (resourcePath as NSString).appendingPathComponent("BundledPatches")
                if let contents = try? fileManager.contentsOfDirectory(atPath: bundledFolderPath) {
                    for filename in contents where filename.lowercased().hasSuffix(".3105") {
                        let fullPath = (bundledFolderPath as NSString).appendingPathComponent(filename)
                        candidateURLs.append(URL(fileURLWithPath: fullPath))
                    }
                }
            }

            // Loại bỏ các đường dẫn trùng lặp
            let uniqueCandidates = Array(Set(candidateURLs))

            for sourceURL in uniqueCandidates {
                do {
                    let filename = sourceURL.lastPathComponent
                    let destinationURL = targetRoot.appendingPathComponent(filename)

                    // Nếu chưa tồn tại trong thư viện máy thì copy vào
                    if !fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    }
                } catch {
                    print("Lỗi khi nạp bundled patch \(sourceURL.lastPathComponent): \(error)")
                }
            }

            // Tải lại thư viện patch trên main thread
            DispatchQueue.main.async {
                store.reload()
            }
        }
    }
}
