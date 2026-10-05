import Foundation

/// Chính sách tương thích iOS cho exploit 3105
/// Nguồn: https://github.com/YangJiiii/3105 (đồng bộ chính xác với repo gốc)
enum ExploitSupportPolicy {

    // MARK: - Verified iOS Ranges (hiển thị trong UI)
    static let verifiedIOS17Range = "17.0–17.7.x"
    static let verifiedIOS18Range = "18.0–18.7.1"
    static let verifiedIOS26Range = "26.0–26.6.1"

    // MARK: - iOS 27 Beta builds (đúng theo yangyii GitHub, beta 1-4)
    static let verifiedIOS27Builds: [(beta: Int, publicBeta: Int?, build: String)] = [
        (1, nil, "24A5355q"),
        (2, nil, "24A5370h"),
        (3, 1,   "24A5380h"),
        (4, 2,   "24A5390f")
    ]

    // MARK: - iOS 27 beta lookup
    static func iOS27BetaNumber(for build: String) -> Int? {
        verifiedIOS27Builds.first { $0.build == build }?.beta
    }

    static func iOS27PublicBetaNumber(for build: String) -> Int? {
        verifiedIOS27Builds.first { $0.build == build }?.publicBeta
    }

    // MARK: - Kernel exploit support (iOS 17 & 18)
    static func supportsKernelExploit(major: Int, minor: Int, patch: Int) -> Bool {
        guard minor >= 0, patch >= 0 else { return false }

        if major == 17 {
            return minor <= 7
        }

        if major == 18 {
            return minor < 7 || (minor == 7 && patch <= 1)
        }

        return false
    }

    /// Alias hỗ trợ trực tiếp không cần ghép đôi
    static func supportsDirectExploit(major: Int, minor: Int, patch: Int) -> Bool {
        return supportsKernelExploit(major: major, minor: minor, patch: patch)
    }

    // MARK: - isSupported (iOS 17, 18, 26, 27 beta)
    static func isSupported(major: Int, minor: Int, patch: Int, build: String) -> Bool {
        if supportsKernelExploit(major: major, minor: minor, patch: patch) {
            return true
        }

        if major == 26 {
            guard minor >= 0, patch >= 0 else { return false }
            return minor < 6 || (minor == 6 && patch <= 1)
        }

        guard major == 27, minor == 0, patch == 0 else { return false }
        return iOS27BetaNumber(for: build) != nil
    }

    // MARK: - Danh sách tất cả range tương thích (dùng cho UI CheatStoreVN)
    struct SupportRange: Identifiable {
        let id = UUID()
        let label: String
        let range: String
        let isStaticSupport: Bool
    }

    static var allRanges: [SupportRange] {
        [
            SupportRange(label: "iOS 17", range: verifiedIOS17Range, isStaticSupport: true),
            SupportRange(label: "iOS 18", range: verifiedIOS18Range, isStaticSupport: true),
            SupportRange(label: "iOS 26", range: verifiedIOS26Range, isStaticSupport: true),
            SupportRange(label: "iOS 27", range: "27.0 Beta 1–4",   isStaticSupport: true)
        ]
    }

    /// Kiểm tra thiết bị hiện tại có trong range tương thích không
    static func compatibilityStatus(major: Int, minor: Int, patch: Int, build: String) -> String {
        if isSupported(major: major, minor: minor, patch: patch, build: build) {
            if major == 17 { return "Tương thích (\(verifiedIOS17Range))" }
            if major == 18 { return "Tương thích (\(verifiedIOS18Range))" }
            if major == 26 { return "Tương thích (\(verifiedIOS26Range))" }
            if major == 27 { return "Tương thích (iOS 27.0 Beta 1–4)" }
            return "Tương thích"
        }
        return "Không tương thích"
    }
}
