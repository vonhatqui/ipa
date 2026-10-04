import Foundation

public struct PatchConversionResponse: Decodable {
    public let status: String
    public let code: String
    public let message: String
    public let data: PatchConversionData?
}

public struct PatchConversionData: Decodable {
    public let originalName: String
    public let outputFilename: String
    public let originalSize: Int64
    public let encodedSize: Int64
    public let token: String
    public let downloadUrl: String
    public let sha256: String

    enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case outputFilename = "output_filename"
        case originalSize = "original_size"
        case encodedSize = "encoded_size"
        case token
        case downloadUrl = "download_url"
        case sha256
    }
}

public enum PatchCodecAPIError: LocalizedError {
    case invalidSourceFile
    case fileTooLarge
    case serverError(String)
    case networkError(Error)
    case downloadFailed
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSourceFile:
            return "File .3105 không hợp lệ hoặc không thể đọc được."
        case .fileTooLarge:
            return "File vượt quá giới hạn dung lượng 50MB."
        case .serverError(let msg):
            return "Lỗi máy chủ: \(msg)"
        case .networkError(let err):
            return "Lỗi kết nối mạng: \(err.localizedDescription)"
        case .downloadFailed:
            return "Không thể tải file .dat từ máy chủ sau khi mã hóa."
        case .decodingFailed:
            return "Dữ liệu phản hồi từ máy chủ không hợp lệ."
        }
    }
}

public final class PatchCodecAPIService {
    public static let shared = PatchCodecAPIService()

    private var apiBaseURL: String { "\(CheatStoreServerConfig.apiBaseURL)/api.php" }
    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: config)
    }

    /// Mã hóa file .3105 sang định dạng .dat qua API backend
    public func convertPatch(
        sourceURL: URL,
        onProgress: @escaping (Double, String) -> Void
    ) async throws -> (data: Data, info: PatchConversionData, localDestinationURL: URL) {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        guard let fileData = try? Data(contentsOf: sourceURL) else {
            throw PatchCodecAPIError.invalidSourceFile
        }

        let filename = sourceURL.lastPathComponent
        guard filename.lowercased().hasSuffix(".3105") else {
            throw PatchCodecAPIError.invalidSourceFile
        }

        if fileData.count > 52428800 {
            throw PatchCodecAPIError.fileTooLarge
        }

        onProgress(0.25, "Đang gửi dữ liệu lên máy chủ...")

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "\(apiBaseURL)?action=convert_3105")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        onProgress(0.55, "Máy chủ đang thực hiện mã hóa byte-stream XOR...")

        let (responseData, response): (Data, URLResponse)
        do {
            (responseData, response) = try await urlSession.data(for: request)
        } catch {
            throw PatchCodecAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PatchCodecAPIError.serverError("Máy chủ không phản hồi HTTP hợp lệ.")
        }

        let decodedResponse: PatchConversionResponse
        do {
            decodedResponse = try JSONDecoder().decode(PatchConversionResponse.self, from: responseData)
        } catch {
            let errorText = String(data: responseData, encoding: .utf8) ?? "Mã lỗi HTTP \(httpResponse.statusCode)"
            throw PatchCodecAPIError.serverError("Phản hồi lỗi (\(httpResponse.statusCode)): \(errorText)")
        }

        guard decodedResponse.status == "success", let info = decodedResponse.data else {
            throw PatchCodecAPIError.serverError(decodedResponse.message)
        }

        onProgress(0.85, "Mã hóa thành công! Đang tải file .dat kết quả...")

        let downloadAbsoluteURL: URL
        if info.downloadUrl.hasPrefix("http") {
            downloadAbsoluteURL = URL(string: info.downloadUrl)!
        } else {
            downloadAbsoluteURL = URL(string: CheatStoreServerConfig.apiBaseURL + info.downloadUrl)!
        }

        let (datData, datResp) = try await urlSession.data(from: downloadAbsoluteURL)
        guard let datHttp = datResp as? HTTPURLResponse, (200..<300).contains(datHttp.statusCode), !datData.isEmpty else {
            throw PatchCodecAPIError.downloadFailed
        }

        let tempDir = FileManager.default.temporaryDirectory
        let localDestURL = tempDir.appendingPathComponent(info.outputFilename)
        try datData.write(to: localDestURL, options: .atomic)

        onProgress(1.0, "Hoàn tất mã hóa thành công!")
        return (datData, info, localDestURL)
    }
}
