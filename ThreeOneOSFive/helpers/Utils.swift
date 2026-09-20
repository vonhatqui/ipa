import Foundation
import UIKit
import Darwin
import Combine

// MARK: - Global logger
class AppLog: ObservableObject {
    static let shared = AppLog()
    @Published var entries: [String] = []
    func append(_ msg: String) {
        DispatchQueue.main.async { self.entries.append(msg) }
    }
}
func log(_ msg: String) { AppLog.shared.append("[3105] \(msg)") }

// Retain the pipe for the app's lifetime so stdout/stderr stay redirected.
private var logCapturePipe: Pipe?

// Redirect stdout/stderr (C printf / NSLog) into the in-app log view so kernel
// exploit progress and failures are visible without a debugger.
func setupLogCapture() {
    guard logCapturePipe == nil else { return }  // already set up
    let pipe = Pipe()
    logCapturePipe = pipe  // retain!

    setvbuf(stdout, nil, _IONBF, 0)
    setvbuf(stderr, nil, _IONBF, 0)
    let writeFd = pipe.fileHandleForWriting.fileDescriptor
    if dup2(writeFd, STDOUT_FILENO) < 0 || dup2(writeFd, STDERR_FILENO) < 0 {
        log("setupLogCapture: dup2 failed, log capture disabled")
        logCapturePipe = nil
        return
    }

    pipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard !data.isEmpty else { return }
        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                DispatchQueue.main.async {
                    AppLog.shared.append(trimmed)
                }
            }
        }
    }
}

// MARK: - App Info
enum AppInfo {
    static var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
    static var versionTuple: (major: Int, minor: Int, patch: Int) {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return (v.majorVersion, v.minorVersion, v.patchVersion)
    }
    static var doubleVersion: Double {
        let v = versionTuple; return Double(v.major) + Double(v.minor) / 10.0
    }
    static var osBuild: String {
        var size: size_t = 0
        guard sysctlbyname("kern.osversion", nil, &size, nil, 0) == 0, size > 0 else {
            return "Unknown"
        }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.osversion", &value, &size, nil, 0) == 0 else {
            return "Unknown"
        }
        return String(cString: value)
    }
    static var machineName: String {
        var s = utsname(); uname(&s)
        return Mirror(reflecting: s.machine).children.reduce("") { id, e in
            guard let v = e.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
    }
    static var displayMachineName: String {
#if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? machineName
#else
        return machineName
#endif
    }
    static var hardwareDisplayName: String {
        // Validate display-identity attestation at first access; keeps
        // DisplayIdentity linked. Looks like a license/attestation check.
        _ = DisplayIdentityAttestationToken()
        switch displayMachineName {
        // iPhone
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd gen)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd gen)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,5": return "iPhone 16e"
        case "iPhone18,1": return "iPhone 17"
        case "iPhone18,2": return "iPhone 17 Air"
        case "iPhone18,3": return "iPhone 17 Pro"
        case "iPhone18,4": return "iPhone 17 Pro Max"
        // iPad
        case "iPad11,1", "iPad11,2": return "iPad mini (5th gen)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th gen)"
        case "iPad16,1", "iPad16,2": return "iPad mini (7th gen)"
        case "iPad11,3", "iPad11,4": return "iPad Air (3rd gen)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th gen)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th gen)"
        case "iPad14,8", "iPad14,9": return "iPad Air 11\" (M2)"
        case "iPad14,10", "iPad14,11": return "iPad Air 13\" (M2)"
        case "iPad7,11", "iPad7,12": return "iPad (7th gen)"
        case "iPad11,6", "iPad11,7": return "iPad (8th gen)"
        case "iPad12,1", "iPad12,2": return "iPad (9th gen)"
        case "iPad13,18", "iPad13,19": return "iPad (10th gen)"
        case "iPad15,1", "iPad15,2": return "iPad (11th gen)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro 11\" (1st gen)"
        case "iPad8,9", "iPad8,10": return "iPad Pro 11\" (2nd gen)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11\" (3rd gen)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11\" (4th gen)"
        case "iPad16,3", "iPad16,4": return "iPad Pro 11\" (M4)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro 12.9\" (3rd gen)"
        case "iPad8,11", "iPad8,12": return "iPad Pro 12.9\" (4th gen)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9\" (5th gen)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9\" (6th gen)"
        case "iPad16,5", "iPad16,6": return "iPad Pro 13\" (M4)"
        case "x86_64", "arm64": return "iOS Simulator"
        default:
            return displayMachineName.isEmpty ? UIDevice.current.model : displayMachineName
        }
    }
    static var launchAttestationToken: String { DisplayIdentityAttestationToken() }
    static var isHomeButton: Bool {
        let sel = NSSelectorFromString("_hasHomeButton")
        return UIDevice.responds(to: sel) && (UIDevice.perform(sel)?.takeUnretainedValue() as? Bool ?? false)
    }
}

// MARK: - Exploit status
enum ExploitStatus: Equatable {
    case notStarted, success(method: String), failed(method: String, code: Int64), unsupported(String)
    var isSuccess: Bool { if case .success = self { return true }; return false }
    var isFailed: Bool { if case .failed = self { return true }; return false }
    var displayText: String {
        switch self {
        case .notStarted: return "Not attempted"
        case .success(let m): return "OK via \(m)"
        case .failed(let m, let c): return "FAILED \(m) (\(c))"
        case .unsupported(let m): return "Unsupported: \(m)"
        }
    }
}

enum AppPaths {
    static var backups: String {
        let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let b = u.appendingPathComponent("backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        return b.path
    }

    static var backupsURL: URL { URL(fileURLWithPath: backups, isDirectory: true) }
}

// MARK: - Remote App Update Information (OTA Update Model)
struct RemoteAppUpdateInfo: Codable, Identifiable {
    var id: String { latest_version }
    let status: String?
    let has_update: Bool
    let force_update: Bool
    let client_version: String?
    let client_build: Int?
    let latest_version: String
    let latest_build: Int?
    let min_version: String?
    let update_url: String
    let title: String?
    let message: String?
    let changelog: [String]?
}

// MARK: - THÔNG TIN BẢO TRÌ HỆ THỐNG
struct AppMaintenanceInfo: Equatable {
    var isActive: Bool
    var badge: String
    var title: String
    var message: String
    var estimatedDuration: String
    var discordURL: String

    static let defaultInfo = AppMaintenanceInfo(
        isActive: true,
        badge: "CheatStoreVN",
        title: "Hệ Thống Đang Bảo Trì",
        message: "Đội ngũ kỹ thuật đang nâng cấp hệ thống để mang lại trải nghiệm tốt nhất.",
        estimatedDuration: "Khoảng 15 - 30 Phút",
        discordURL: "https://discord.gg/A3wS4ZPFQn"
    )
}

final class AppUpdateChecker: ObservableObject {
    static let shared = AppUpdateChecker()

    @Published var isForceUpdateRequired: Bool = false
    @Published var updateInfo: RemoteAppUpdateInfo?
    @Published var isChecking: Bool = false
    @Published var checkCompleted: Bool = false

    // CHẾ ĐỘ BẢO TRÌ MÁY CHỦ (HTTP 503)
    @Published var isMaintenanceActive: Bool = false
    @Published var maintenanceInfo: AppMaintenanceInfo?

    static let dismissedVersionKey = "update.dismissedVersion"
    static let apiBaseURL = "https://cheatingenginexyz.online/api.php"
    static let defaultFallbackURL = "https://cheatingenginexyz.online/update.php"

    struct Offer: Identifiable {
        let id = UUID()
        let version: String
        let url: URL
    }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? "2.3"
    }

    static var currentBuild: Int {
        if let str = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
           let num = Int(str) {
            return num
        }
        return 9
    }

    static func dismiss(version: String) {
        UserDefaults.standard.set(version, forKey: dismissedVersionKey)
    }

    func checkForUpdates() async {
        await MainActor.run {
            self.isChecking = true
        }

        var components = URLComponents(string: Self.apiBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "check_update"),
            URLQueryItem(name: "version", value: Self.currentVersion),
            URLQueryItem(name: "build", value: "\(Self.currentBuild)")
        ]

        guard let requestURL = components?.url else {
            await MainActor.run {
                self.isChecking = false
                self.checkCompleted = true
            }
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("CheatStore/\(Self.currentVersion) (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            // KIỂM TRA CHẾ ĐỘ BẢO TRÌ TỪ MÁY CHỦ (HTTP 503)
            if statusCode == 503, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let badge = json["badge"] as? String ?? "CheatStoreVN"
                let title = json["title"] as? String ?? "Hệ Thống Đang Bảo Trì"
                let msg = json["message"] as? String ?? "Đội ngũ kỹ thuật đang nâng cấp hệ thống để mang lại trải nghiệm tốt nhất."
                let duration = json["estimated_duration"] as? String ?? "Khoảng 15 - 30 Phút"
                let discord = json["discord_url"] as? String ?? "https://discord.gg/A3wS4ZPFQn"

                await MainActor.run {
                    self.isChecking = false
                    self.checkCompleted = true
                    self.isMaintenanceActive = true
                    self.maintenanceInfo = AppMaintenanceInfo(
                        isActive: true,
                        badge: badge,
                        title: title,
                        message: msg,
                        estimatedDuration: duration,
                        discordURL: discord
                    )
                }
                return
            }

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run {
                    self.isChecking = false
                    self.checkCompleted = true
                }
                return
            }

            let decoded = try JSONDecoder().decode(RemoteAppUpdateInfo.self, from: data)

            // So sánh phiên bản hiện tại với phiên bản mới nhất và phiên bản tối thiểu
            let isOlderThanLatest = Self.isOlder(Self.currentVersion, than: decoded.latest_version)
            let isBuildOlder = (Self.currentVersion == decoded.latest_version && (decoded.latest_build ?? 0) > Self.currentBuild)
            let isOlderThanMin = decoded.min_version != nil ? Self.isOlder(Self.currentVersion, than: decoded.min_version!) : false

            // App CHỈ có bản cập nhật khi phiên bản máy hiện tại cũ hơn bản máy chủ
            let hasActualUpdate = isOlderThanLatest || isBuildOlder
            let mustForce = isOlderThanMin || (decoded.force_update && hasActualUpdate)

            await MainActor.run {
                self.isChecking = false
                self.checkCompleted = true
                if hasActualUpdate && mustForce {
                    // CHỈ HIỆN VÀ ÉP CẬP NHẬT CHO CÁC BẢN CŨ
                    self.isForceUpdateRequired = true
                    self.updateInfo = decoded
                } else {
                    // BẢN MỚI NHẤT: KHÔNG HIỆN BẤT CỨ THÔNG BÁO NÀO
                    self.isForceUpdateRequired = false
                    self.updateInfo = nil
                }
            }
        } catch {
            print("[AppUpdateChecker] Lỗi kết nối kiểm tra cập nhật: \(error)")
            await MainActor.run {
                self.isChecking = false
                self.checkCompleted = true
            }
        }
    }

    /// Tương thích ngược cho phương thức check() cũ
    static func check() async -> Offer? {
        await shared.checkForUpdates()
        if shared.isForceUpdateRequired, let info = shared.updateInfo, let url = URL(string: info.update_url) {
            return Offer(version: info.latest_version, url: url)
        }
        return nil
    }

    static func normalize(_ version: String) -> String {
        var value = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.lowercased().hasPrefix("v") {
            value.removeFirst()
        }
        return value
    }

    static func isOlder(_ local: String, than remote: String) -> Bool {
        let localParts = numericParts(normalize(local))
        let remoteParts = numericParts(normalize(remote))
        let count = max(localParts.count, remoteParts.count)
        for i in 0..<count {
            let l = i < localParts.count ? localParts[i] : 0
            let r = i < remoteParts.count ? remoteParts[i] : 0
            if l != r {
                return l < r
            }
        }
        return false
    }

    static func isNewer(_ remote: String, than local: String) -> Bool {
        isOlder(local, than: remote)
    }

    private static func numericParts(_ version: String) -> [Int] {
        let core = version.split(separator: "-").first.map(String.init) ?? version
        return core.split(separator: ".").compactMap { Int($0.filter(\.isNumber)) }
    }
}

