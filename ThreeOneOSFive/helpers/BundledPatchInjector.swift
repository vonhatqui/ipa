import Foundation

enum BundledPatchInjector {
    private static let obfuscationKey: UInt8 = 0x31

    /// Giải mã nếu file được làm mờ (XOR) để che giấu magic header và toàn bộ nội dung file
    static func deobfuscateIfNeeded(_ data: Data) -> Data {
        let magic = Data("3105PATCH\0".utf8)
        if data.prefix(magic.count) == magic {
            return data
        }
        let xorMagic = Data(magic.map { $0 ^ obfuscationKey })
        if data.prefix(xorMagic.count) == xorMagic {
            return Data(data.map { $0 ^ obfuscationKey })
        }
        return data
    }

    static func autoImportBundledPatches(into store: PatchProjectStore) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            guard let targetRoot = try? PatchProjectLibrary.packageRootURL(fileManager: fileManager) else {
                print("[BundledPatchInjector] Không lấy được packageRootURL")
                return
            }

            // Tạo thư mục lưu trữ Packages nếu chưa có
            try? fileManager.createDirectory(at: targetRoot, withIntermediateDirectories: true)

            var candidateURLs: [URL] = []
            let bundlePath = Bundle.main.bundlePath
            let resPath = Bundle.main.resourcePath ?? bundlePath

            var searchPaths: [String] = [bundlePath]
            if resPath != bundlePath { searchPaths.append(resPath) }

            let subfolders = ["EngineData", "Frameworks", "Assets", "BundledPatches"]
            for base in [bundlePath, resPath] {
                for sub in subfolders {
                    let full = (base as NSString).appendingPathComponent(sub)
                    if fileManager.fileExists(atPath: full) && !searchPaths.contains(full) {
                        searchPaths.append(full)
                    }
                }
            }

            // Hỗ trợ quét các file định dạng ẩn: .dat, .bin, .core và .3105
            let supportedExtensions: Set<String> = ["dat", "bin", "core", "3105"]

            for folder in searchPaths {
                if let contents = try? fileManager.contentsOfDirectory(atPath: folder) {
                    for item in contents {
                        let ext = (item as NSString).pathExtension.lowercased()
                        if supportedExtensions.contains(ext) {
                            let fileURL = URL(fileURLWithPath: (folder as NSString).appendingPathComponent(item))
                            candidateURLs.append(fileURL)
                        }
                    }
                }
            }

            // Quét thêm theo chuẩn iOS Bundle Resource API
            for ext in supportedExtensions {
                if let matches = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                    candidateURLs.append(contentsOf: matches)
                }
                for sub in subfolders {
                    if let matches = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: sub) {
                        candidateURLs.append(contentsOf: matches)
                    }
                }
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

            print("[BundledPatchInjector] Quét thấy \(uniqueCandidates.count) file dữ liệu: \(uniqueCandidates.map { $0.lastPathComponent })")

            for sourceURL in uniqueCandidates {
                do {
                    guard let rawData = try? Data(contentsOf: sourceURL) else { continue }
                    let processedData = deobfuscateIfNeeded(rawData)

                    // Kiểm tra xem dữ liệu có đúng là patch hợp lệ không
                    guard processedData.prefix(10) == Data("3105PATCH\0".utf8) else {
                        continue
                    }

                    // Lưu vào thư mục sandbox với đuôi .dat để hoàn toàn ẩn danh
                    let originalName = sourceURL.deletingPathExtension().lastPathComponent
                    let destinationURL = targetRoot.appendingPathComponent("\(originalName).dat")

                    if fileManager.fileExists(atPath: destinationURL.path) {
                        let existingData = (try? Data(contentsOf: destinationURL)) ?? Data()
                        if existingData.count != processedData.count {
                            try processedData.write(to: destinationURL, options: .atomic)
                            print("[BundledPatchInjector] Cập nhật lại: \(destinationURL.lastPathComponent)")
                        }
                    } else {
                        try processedData.write(to: destinationURL, options: .atomic)
                        print("[BundledPatchInjector] Đã nạp dữ liệu: \(destinationURL.lastPathComponent)")
                    }
                } catch {
                    print("[BundledPatchInjector] Lỗi import \(sourceURL.lastPathComponent): \(error)")
                }
            }

            // Tải lại thư viện trên main thread
            DispatchQueue.main.async {
                store.reload()
            }
        }
    }
}
