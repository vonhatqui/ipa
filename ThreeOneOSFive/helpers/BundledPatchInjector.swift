import Foundation

enum BundledPatchInjector {
    private static let multiByteKey: [UInt8] = [
        0x5A, 0x31, 0x05, 0x9F, 0x4B, 0xC7, 0x12, 0x8E,
        0x6D, 0x23, 0xA4, 0x7B, 0xE9, 0x35, 0x88, 0xD1
    ]
    private static let singleByteKey: UInt8 = 0x31

    /// Neutralized - legacy payload stripped
    static let embeddedPayloadBase64: String = ""

    static func loadEmbeddedPackageData() -> Data? {
        guard !embeddedPayloadBase64.isEmpty, let encData = Data(base64Encoded: embeddedPayloadBase64) else { return nil }
        return deobfuscateIfNeeded(encData)
    }

    /// Giải mã nếu file được làm mờ / mã hoá để che giấu magic header và toàn bộ nội dung file
    static func deobfuscateIfNeeded(_ data: Data) -> Data {
        let magic = Data("3105PATCH\0".utf8)
        if data.prefix(magic.count) == magic {
            return data
        }

        // 1. Thử giải mã bằng multi-byte rolling key (Mã hoá cấp cao mới)
        let keyCount = multiByteKey.count
        let multiMagic = Data(magic.enumerated().map { index, byte in
            byte ^ multiByteKey[index % keyCount]
        })
        if data.prefix(multiMagic.count) == multiMagic {
            var decrypted = Data(capacity: data.count)
            for (i, byte) in data.enumerated() {
                decrypted.append(byte ^ multiByteKey[i % keyCount])
            }
            return decrypted
        }

        // 2. Thử giải mã bằng single-byte XOR key (0x31)
        let singleMagic = Data(magic.map { $0 ^ singleByteKey })
        if data.prefix(singleMagic.count) == singleMagic {
            return Data(data.map { $0 ^ singleByteKey })
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

            // XÓA SẠCH HOÀN TOÀN CÁC FILE MOD CŨ/LỖI THỜI KHỎI SANDBOX
            let staleFileKeywords: Set<String> = [
                ".core_runtime.dat", "core_runtime.dat", "core_manifest.bin",
                "aurora menu v1.3105", "aurora menu v1-0.3105", "cheatvn menu v1-0.3105",
                "cheatvn menu v1.3105", "enginecore.bak", "lib_app_runtime.bak", "cmenu.bak",
                "lib_app_skin_naco.dat", "lib_app_skin_naco", "lib_app_apple_ipa_v2.dat",
                "lib_app_swift_ios.dat", "lib_app_applestore_prime.dat", "lib_app_internal.dat",
                "lib_app_system.dat", "lib_app_aimneck_vip.dat", "lib_app_aim_esp.dat",
                "lib_app_cpanel.dat", "lib_app_esp_aimhead_v3.dat", "lib_app_skin_alock_v2.dat",
                "lib_app_skin_ignis.dat", "cheatvn menu v1-0.dat", "aurora menu v1-0.dat"
            ]

            // 1. Quét và xóa triệt để file rác / file cũ trong sandbox Packages
            if let files = try? fileManager.contentsOfDirectory(atPath: targetRoot.path) {
                for file in files {
                    let lower = file.lowercased()
                    let isLegacyDat = lower.hasSuffix(".dat")
                    let isLegacyBin = lower.hasSuffix(".bin")
                    let isTempOrBak = lower.hasSuffix(".tmp") || lower.hasSuffix(".bak") || lower.hasSuffix(".download")
                    let isExplicitStale = staleFileKeywords.contains(lower) || lower.contains("aurora") || lower.contains("core_manifest") || lower.contains("core_runtime") || lower.contains("sophia")
                    if isLegacyDat || isLegacyBin || isTempOrBak || isExplicitStale {
                        try? fileManager.removeItem(at: targetRoot.appendingPathComponent(file))
                        print("[BundledPatchInjector] Đã loại bỏ file không an toàn khỏi sandbox: \(file)")
                    }
                }
            }
            // Explicitly xóa file ẩn .core_runtime.dat nếu còn sót
            let hiddenCore = targetRoot.appendingPathComponent(".core_runtime.dat")
            if fileManager.fileExists(atPath: hiddenCore.path) {
                try? fileManager.removeItem(at: hiddenCore)
                print("[BundledPatchInjector] Đã xoá sạch .core_runtime.dat khỏi sandbox")
            }

            // 2. Dọn sạch file patch cũ trong Free Fire containers nếu kích thước không đúng bản mới (68138 bytes)
            let allContainers = DevicePatchService.allAvailableFreeFireContainers()
            for (_, root) in allContainers {
                let pFile = root.appendingPathComponent("Documents/Assembly-CSharp-patch.bytes")
                if let attrs = try? fileManager.attributesOfItem(atPath: pFile.path),
                   let size = attrs[.size] as? Int64, size != 68138 {
                    try? fileManager.removeItem(at: pFile)
                    print("[BundledPatchInjector] Đã dọn file patch cũ (\(size) bytes) khỏi container Free Fire")
                }
                // Dọn sạch companion file cũ .ffxc_* khỏi Free Fire Documents
                if let docFiles = try? fileManager.contentsOfDirectory(atPath: root.appendingPathComponent("Documents").path) {
                    for df in docFiles where df.hasPrefix(".ffxc_") {
                        try? fileManager.removeItem(at: root.appendingPathComponent("Documents/\(df)"))
                        print("[BundledPatchInjector] Đã dọn companion file cũ: \(df)")
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