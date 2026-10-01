import Foundation
import Combine

// MARK: - Cloud Patch Data Model
public struct CloudPatchItem: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let category: String     // "home", "esp", "skin"
    public let filename: String
    public let downloadUrl: String
    public let size: Int64
    public let sha256: String
    public let isActive: Bool
    public let isCore: Bool?
    public let version: String?

    enum CodingKeys: String, CodingKey {
        case id, name, subtitle, category, filename, size, sha256, version
        case downloadUrl = "download_url"
        case isActive = "is_active"
        case isCore = "is_core"
    }

    public var baseName: String {
        (filename as NSString).deletingPathExtension
    }
}

private struct CloudPatchesResponse: Codable {
    let status: String
    let code: String?
    let count: Int?
    let patches: [CloudPatchItem]
}

// MARK: - Cloud Patch Synchronization Service
@MainActor
public final class CloudPatchService: ObservableObject {
    public static let shared = CloudPatchService()

    @Published public private(set) var cloudPatches: [CloudPatchItem] = []
    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var lastSyncDate: Date? = nil

    private let apiBaseURL = "https://cheatingenginexyz.online"
    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 120
        self.urlSession = URLSession(configuration: config)
    }

    /// Lấy danh sách patch theo danh mục ("home_aim", "home_core", "esp", "skin", hoặc legacy "home")
    public func patches(for category: String) -> [CloudPatchItem] {
        let target = category.lowercased()
        return cloudPatches.filter { p in
            let pc = p.category.lowercased()
            let pn = p.name.lowercased()
            if target == "home_aim" {
                if pc == "home_aim" { return true }
                if pc == "home" {
                    return pn.contains("aim") || pn.contains("drag") || pn.contains("neck")
                }
                return false
            }
            if target == "home_core" {
                if pc == "home_core" { return true }
                if pc == "home" {
                    return !pn.contains("aim") && !pn.contains("drag") && !pn.contains("neck")
                }
                return false
            }
            if target == "home" {
                return pc == "home" || pc == "home_aim" || pc == "home_core"
            }
            if target == "esp" {
                return pc == "esp" || pn.contains("esp") || pn.contains("định vị")
            }
            if target == "skin" {
                return pc == "skin" || pn.contains("skin")
            }
            return pc == target
        }
    }

    /// Tìm patch theo tên chức năng
    public func patch(named name: String) -> CloudPatchItem? {
        cloudPatches.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Tìm patch theo tên file (có hoặc không có đuôi .dat)
    public func patch(forFilename filename: String) -> CloudPatchItem? {
        let clean = filename.lowercased().replacingOccurrences(of: ".dat", with: "")
        return cloudPatches.first { $0.baseName.lowercased() == clean }
    }

    /// Đồng bộ OTA các patch từ Server về máy trong nền
    public func syncCloudPatches(completion: (() -> Void)? = nil) {
        guard !isSyncing else {
            completion?()
            return
        }
        isSyncing = true

        Task {
            do {
                guard let requestURL = URL(string: "\(apiBaseURL)/api.php?action=get_cloud_patches") else {
                    self.isSyncing = false
                    completion?()
                    return
                }

                var request = URLRequest(url: requestURL)
                request.cachePolicy = .reloadIgnoringLocalCacheData

                let (data, response) = try await urlSession.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    self.isSyncing = false
                    completion?()
                    return
                }

                let decoded = try JSONDecoder().decode(CloudPatchesResponse.self, from: data)
                let fetchedPatches = decoded.patches

                // Cập nhật danh sách trên Main thread
                self.cloudPatches = fetchedPatches
                self.lastSyncDate = Date()
                self.isSyncing = false

                // Tải ngầm các file .dat còn thiếu về máy
                Task.detached(priority: .background) {
                    await self.downloadMissingPatchFiles(fetchedPatches)
                }

                completion?()
            } catch {
                print("[CloudPatchService] Sync error: \(error.localizedDescription)")
                self.isSyncing = false
                completion?()
            }
        }
    }

    /// Tải ngầm các tệp .dat vào sandbox nếu chưa có & dọn dẹp file bị xóa
    private func downloadMissingPatchFiles(_ patches: [CloudPatchItem]) async {
        guard let targetRoot = try? PatchProjectLibrary.packageRootURL() else { return }
        let fileManager = FileManager.default

        // 1. Dọn dẹp các tệp .dat mồ côi đã bị xóa trên Web Admin
        let validFilenames = Set(patches.map { $0.filename.lowercased() })
        if let existingFiles = try? fileManager.contentsOfDirectory(atPath: targetRoot.path) {
            for f in existingFiles {
                if f.lowercased().hasSuffix(".dat") && !validFilenames.contains(f.lowercased()) {
                    let fileToDelete = targetRoot.appendingPathComponent(f)
                    try? fileManager.removeItem(at: fileToDelete)
                    print("[CloudPatchService] Đã xóa file không còn trên server: \(f)")
                }
            }
        }

        // 2. Tải các file mới
        for patch in patches {
            let destURL = targetRoot.appendingPathComponent(patch.filename)

            // Nếu file đã tồn tại và đúng kích thước thì bỏ qua
            if fileManager.fileExists(atPath: destURL.path) {
                if let attrs = try? fileManager.attributesOfItem(atPath: destURL.path),
                   let localSize = attrs[.size] as? Int64,
                   patch.size <= 0 || localSize == patch.size {
                    continue
                }
            }

            // Xây dựng URL tải file
            let downloadFullURLStr: String
            if patch.downloadUrl.hasPrefix("http") {
                downloadFullURLStr = patch.downloadUrl
            } else {
                downloadFullURLStr = "\(apiBaseURL)\(patch.downloadUrl)"
            }

            guard let downloadURL = URL(string: downloadFullURLStr) else { continue }

            do {
                let (fileData, resp) = try await urlSession.data(from: downloadURL)
                if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode), !fileData.isEmpty {
                    try fileData.write(to: destURL, options: .atomic)
                    print("[CloudPatchService] Đã tải ngầm OTA: \(patch.filename) (\(patch.name))")
                }
            } catch {
                print("[CloudPatchService] Lỗi tải \(patch.filename): \(error.localizedDescription)")
            }
        }
    }
}
