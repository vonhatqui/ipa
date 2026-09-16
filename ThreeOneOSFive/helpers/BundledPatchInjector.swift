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

            // Hỗ trợ quét các định dạng ẩn
            let supportedExtensions: Set<String> = ["dat", "bin", "core", "sys", "3105"]

            // Quét đệ quy tìm kiếm tất cả các tệp mod trong bundle (Frameworks, AppCore, Assets...)
            func scanDirectoryRecursively(_ dirPath: String, depth: Int = 0) {
                if depth > 4 { return }
                guard let items = try? fileManager.contentsOfDirectory(atPath: dirPath) else { return }
                for item in items {
                    if item.hasSuffix(".lproj") || item.hasPrefix(".") || item == "_CodeSignature" {
                        continue
                    }
                    let fullPath = (dirPath as NSString).appendingPathComponent(item)
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: fullPath, isDirectory: &isDir) {
                        if isDir.boolValue {
                            scanDirectoryRecursively(fullPath, depth: depth + 1)
                        } else {
                            let ext = (item as NSString).pathExtension.lowercased()
                            if supportedExtensions.contains(ext) {
                                candidateURLs.append(URL(fileURLWithPath: fullPath))
                            }
                        }
                    }
                }
            }

            scanDirectoryRecursively(bundlePath)
            if resPath != bundlePath {
                scanDirectoryRecursively(resPath)
            }

            // Quét thêm theo chuẩn iOS Bundle Resource API
            for ext in supportedExtensions {
                if let matches = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                    candidateURLs.append(contentsOf: matches)
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

                    let existingData = (try? Data(contentsOf: destinationURL)) ?? Data()
                    if existingData != processedData {
                        try processedData.write(to: destinationURL, options: .atomic)
                        print("[BundledPatchInjector] Đã nạp/cập nhật dữ liệu mới: \(destinationURL.lastPathComponent)")
                    }
                } catch {
                    print("[BundledPatchInjector] Lỗi import \(sourceURL.lastPathComponent): \(error)")
                }
            }

            // Dọn dẹp sạch mọi file mod cũ không còn dùng và các file có tên lộ liễu
            let staleFileKeywords: [String] = [
                "aimlock", "enginecore", "only aim", "dragantena", "esp-20ffth",
                "aimneck", "aimdrag", "dinhvi", "modskin",
                "lib_app_runtime", "lib_app_resources"
            ]
            if let files = try? fileManager.contentsOfDirectory(atPath: targetRoot.path) {
                for file in files {
                    let lower = file.lowercased()
                    let isStale = staleFileKeywords.contains { lower.contains($0) }
                    if lower.hasSuffix(".3105") || isStale {
                        try? fileManager.removeItem(at: targetRoot.appendingPathComponent(file))
                        print("[BundledPatchInjector] Đã loại bỏ file mod cũ: \(file)")
                    }
                }
            }

            // Tải lại thư viện trên main thread
            DispatchQueue.main.async {
                store.reload()
            }
        }
    }
}
