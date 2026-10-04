import CryptoKit
import Foundation
import Security

enum PatchKeyStore {
    private static var service: String {
        Bundle.main.bundleIdentifier ?? "com.cheatstore.patch-keys"
    }

    private static var memoryCache: [String: Data] = [:]
    private static let lock = NSLock()

    private static func fallbackDirectoryURL() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent(".Keys", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func account(for summary: PatchPackageSummary) -> String {
        let fingerprint = summary.keyFingerprint.map { String(format: "%02x", $0) }.joined()
        return "\(summary.packageID.uuidString).\(fingerprint)"
    }

    static func store(_ contentKey: Data, for summary: PatchPackageSummary) throws {
        guard contentKey.count == 32,
              Data(SHA256.hash(data: contentKey)) == summary.keyFingerprint else {
            throw PatchPackageError.keychainFailed
        }
        let account = account(for: summary)

        // 1. Lưu vào Memory Cache
        lock.lock()
        memoryCache[account] = contentKey
        lock.unlock()

        // 2. Lưu vào Fallback File trong Application Support (đảm bảo hoạt động trên thiết bị sideload/free dev cert)
        if let dir = fallbackDirectoryURL() {
            let fileURL = dir.appendingPathComponent("\(account).key")
            try? contentKey.write(to: fileURL, options: .atomic)
        }

        // 3. Cố gắng lưu vào iOS Keychain (nếu có entitlement)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: contentKey,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }

        var newItem = query
        attributes.forEach { newItem[$0.key] = $0.value }
        _ = SecItemAdd(newItem as CFDictionary, nil)
    }

    static func load(for summary: PatchPackageSummary) throws -> Data? {
        let account = account(for: summary)

        // 1. Kiểm tra Memory Cache trước tiên
        lock.lock()
        if let cached = memoryCache[account],
           cached.count == 32,
           Data(SHA256.hash(data: cached)) == summary.keyFingerprint {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // 2. Kiểm tra Fallback File
        if let dir = fallbackDirectoryURL() {
            let fileURL = dir.appendingPathComponent("\(account).key")
            if let fileData = try? Data(contentsOf: fileURL),
               fileData.count == 32,
               Data(SHA256.hash(data: fileData)) == summary.keyFingerprint {
                lock.lock()
                memoryCache[account] = fileData
                lock.unlock()
                return fileData
            }
        }

        // 3. Kiểm tra iOS Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let data = result as? Data,
           data.count == 32,
           Data(SHA256.hash(data: data)) == summary.keyFingerprint {
            lock.lock()
            memoryCache[account] = data
            lock.unlock()
            return data
        }

        // Nếu không tìm thấy hoặc Keychain không khả dụng (ví dụ lỗi -34018 missing entitlement),
        // trả về nil để hệ thống tiếp tục kiểm tra hoặc giải mã public content key, TUYỆT ĐỐI không throw lỗi crash package!
        return nil
    }

    static func delete(for summary: PatchPackageSummary) throws {
        let account = account(for: summary)

        lock.lock()
        memoryCache.removeValue(forKey: account)
        lock.unlock()

        if let dir = fallbackDirectoryURL() {
            let fileURL = dir.appendingPathComponent("\(account).key")
            try? FileManager.default.removeItem(at: fileURL)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        _ = SecItemDelete(query as CFDictionary)
    }
}
