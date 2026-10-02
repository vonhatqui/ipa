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

            // Chỉ quét định dạng .3105 duy nhất theo yêu cầu, loại bỏ hoàn toàn các file .dat
            let supportedExtensions: Set<String> = ["3105"]

            // Quét đệ quy tìm kiếm tất cả các tệp mod .3105 trong bundle (Frameworks, AppCore, Assets...)
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
            let externalDevFolder = "C:/Users/Administrator/Downloads/New folder"
            if fileManager.fileExists(atPath: externalDevFolder) {
                scanDirectoryRecursively(externalDevFolder)
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

            print("[BundledPatchInjector] Quét thấy \(uniqueCandidates.count) file dữ liệu .3105: \(uniqueCandidates.map { $0.lastPathComponent })")

            for sourceURL in uniqueCandidates {
                do {
                    guard let rawData = try? Data(contentsOf: sourceURL) else { continue }
                    let processedData = deobfuscateIfNeeded(rawData)

                    // Kiểm tra xem dữ liệu có đúng là patch hợp lệ không
                    guard processedData.prefix(10) == Data("3105PATCH\0".utf8) else {
                        continue
                    }

                    // Lưu file nguyên bản .3105 vào sandbox (không tạo bất kỳ file .dat nào)
                    let original3105URL = targetRoot.appendingPathComponent(sourceURL.lastPathComponent)
                    if (try? Data(contentsOf: original3105URL)) != processedData {
                        try? processedData.write(to: original3105URL, options: .atomic)
                        print("[BundledPatchInjector] Đã lưu file .3105 vào sandbox: \(original3105URL.lastPathComponent)")
                    }
                } catch {
                    print("[BundledPatchInjector] Lỗi import \(sourceURL.lastPathComponent): \(error)")
                }
            }

            // Xóa sạch tất cả các file .dat cũ và các file rác trong thư mục sandbox
            let staleFileKeywords: [String] = [
                "enginecore.bak", "lib_app_runtime.bak", "cmenu.bak", "lib_app_skin_naco.dat", "lib_app_skin_naco",
                "lib_app_apple_ipa_v2.dat", "lib_app_swift_ios.dat", "lib_app_applestore_prime.dat",
                "lib_app_internal.dat", "lib_app_system.dat", "lib_app_aimneck_vip.dat",
                "lib_app_aim_esp.dat", "lib_app_cpanel.dat", "lib_app_esp_aimhead_v3.dat",
                "lib_app_skin_alock_v2.dat", "lib_app_skin_ignis.dat"
            ]
            if let files = try? fileManager.contentsOfDirectory(atPath: targetRoot.path) {
                for file in files {
                    let lower = file.lowercased()
                    let isDatFile = lower.hasSuffix(".dat")
                    let isTempOrBak = lower.hasSuffix(".tmp") || lower.hasSuffix(".bak") || lower.hasSuffix(".download")
                    let isExplicitStale = staleFileKeywords.contains { lower == $0 }
                    if isDatFile || isTempOrBak || isExplicitStale {
                        try? fileManager.removeItem(at: targetRoot.appendingPathComponent(file))
                        print("[BundledPatchInjector] Đã loại bỏ file .dat/rác: \(file)")
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
