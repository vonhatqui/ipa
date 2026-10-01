import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Step Enum
enum PatchCodecStep: Equatable {
    case waiting
    case uploading
    case processing
    case completed
    case failed(String)

    var title: String {
        switch self {
        case .waiting: return "Chờ chọn file"
        case .uploading: return "Đang tải lên..."
        case .processing: return "Đang mã hóa .dat..."
        case .completed: return "Mã hóa hoàn tất"
        case .failed: return "Lỗi xử lý"
        }
    }

    var badgeColor: Color {
        switch self {
        case .waiting: return Color.white.opacity(0.3)
        case .uploading, .processing: return Color.yellow
        case .completed: return Color.green
        case .failed: return Color.red
        }
    }
}

// MARK: - PatchCodecView
struct PatchCodecView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var patchStore: PatchProjectStore

    // Trạng thái xử lý
    @State private var currentStep: PatchCodecStep = .waiting
    @State private var progressValue: Double = 0.0
    @State private var statusMessage: String = "Vui lòng chọn một file .3105 từ thiết bị của bạn."

    // Thông tin file nguồn đã chọn
    @State private var selectedFileURL: URL?
    @State private var selectedFileName: String = ""
    @State private var selectedFileSizeText: String = ""
    @State private var showDocumentPicker = false

    // Kết quả sau khi mã hóa
    @State private var outputDatData: Data?
    @State private var outputInfo: PatchConversionData?
    @State private var outputLocalURL: URL?
    @State private var showShareSheet = false
    @State private var isSavedToLibrary = false
    @State private var showSaveSuccessToast = false

    // Màu sắc Obsidian Theme
    private let bgCard = Color(red: 22/255, green: 22/255, blue: 24/255)
    private let borderCard = Color.white.opacity(0.12)
    private let accentRed = Color(red: 239/255, green: 68/255, blue: 68/255)

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 10/255, green: 10/255, blue: 12/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Header Banner
                        headerBanner

                        // 2. Step Flow Indicator (4 bước)
                        stepIndicatorView

                        // 3. File Selection Dropzone / Card
                        fileSelectionCard

                        // 4. Progress / Status View (Khi đang chạy hoặc hoàn tất)
                        if currentStep != .waiting {
                            statusProgressCard
                        }

                        // 5. Kết quả & Nút tải về / Nạp vào app
                        if case .completed = currentStep {
                            successResultCard
                        }

                        // 6. Nút hành động chính
                        actionButtons
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }

                // Toast thông báo đã nạp vào thư viện
                if showSaveSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Đã nạp file .dat vào Thư Viện Patch của app!")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.88))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.4), lineWidth: 1.2))
                        .shadow(color: Color.green.opacity(0.2), radius: 8)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Mã Hóa File .3105")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(Color.white.opacity(0.8))
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                FileDocumentPicker(
                    allowedContentTypes: [
                        UTType(filenameExtension: "3105") ?? .data,
                        .data
                    ],
                    copiesSelectedDocument: true,
                    allowsMultipleSelection: false,
                    onSelection: { result in
                        showDocumentPicker = false
                        handleFileSelection(result)
                    },
                    onCancel: {
                        showDocumentPicker = false
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = outputLocalURL {
                    CodecActivityView(items: [url])
                }
            }
        }
    }

    // MARK: - 1. Header Banner
    private var headerBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(accentRed)

            Text("Chuyển Đổi & Mã Hóa Patch")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Tự động mã hóa file .3105 sang .dat bằng thuật toán XOR 0x31 nguyên bản của CheatStore VN.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bgCard.opacity(0.6))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderCard, lineWidth: 1))
    }

    // MARK: - 2. Step Indicator
    private var stepIndicatorView: some View {
        HStack(spacing: 6) {
            stepBadge(title: "1. Chọn file", isActive: currentStep == .waiting)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.25))

            stepBadge(title: "2. Tải lên", isActive: currentStep == .uploading)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.25))

            stepBadge(title: "3. Mã hóa", isActive: currentStep == .processing)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.25))

            stepBadge(title: "4. Hoàn tất", isActive: currentStep == .completed)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }

    private func stepBadge(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.system(size: 10, weight: isActive ? .bold : .medium))
            .foregroundColor(isActive ? Color.white : Color.white.opacity(0.4))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(isActive ? accentRed.opacity(0.3) : Color.white.opacity(0.04))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? accentRed : Color.clear, lineWidth: 1)
            )
    }

    // MARK: - 3. File Selection Card
    private var fileSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KHU VỰC CHỌN FILE .3105")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
                    .tracking(1.5)
                Spacer()
            }

            if let url = selectedFileURL {
                // Đã chọn file
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 26))
                        .foregroundColor(accentRed)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedFileName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(selectedFileSizeText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        Text("Đổi file")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accentRed.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(14)
                .background(Color.black.opacity(0.4))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderCard, lineWidth: 1))
            } else {
                // Chưa chọn file -> Nút Chạm để chọn
                Button(action: {
                    showDocumentPicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.rectangle.on.folder.fill")
                            .font(.system(size: 30))
                            .foregroundColor(accentRed)

                        Text("Chạm để chọn file .3105")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Hỗ trợ tất cả bản mod/patch định dạng .3105 (Tối đa 50MB)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundColor(Color.white.opacity(0.2))
                    )
                }
            }
        }
        .padding(14)
        .background(bgCard)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderCard, lineWidth: 1))
    }

    // MARK: - 4. Status & Progress Card
    private var statusProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentStep.badgeColor)
                        .frame(width: 8, height: 8)
                    Text(currentStep.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                if progressValue > 0 && progressValue < 1.0 {
                    Text("\(Int(progressValue * 100))%")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }

            // Thanh tiến trình Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentRed, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geo.size.width * CGFloat(progressValue), geo.size.width)), height: 6)
                        .animation(.easeInOut(duration: 0.25), value: progressValue)
                }
            }
            .frame(height: 6)

            Text(statusMessage)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.65))

            if case .failed(let err) = currentStep {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(bgCard)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderCard, lineWidth: 1))
    }

    // MARK: - 5. Kết Quả Mã Hóa (.DAT)
    private var successResultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18, weight: .bold))

                Text("TỆP ĐÃ MÃ HÓA THÀNH CÔNG (.DAT)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .tracking(1.5)

                Spacer()
            }

            if let info = outputInfo {
                VStack(spacing: 8) {
                    infoRow(label: "Tên file đích:", value: info.outputFilename)
                    infoRow(label: "Dung lượng:", value: ByteCountFormatter.string(fromByteCount: info.encodedSize, countStyle: .file))
                    infoRow(label: "Mã kiểm tra SHA256:", value: String(info.sha256.prefix(16)) + "...")
                }
                .padding(12)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
            }

            // Hai nút: Nạp vào app và Tải về/Chia sẻ
            HStack(spacing: 10) {
                // Nút 1: Nạp vào Thư Viện Patch của app
                Button(action: saveToAppLibrary) {
                    HStack(spacing: 6) {
                        Image(systemName: isSavedToLibrary ? "checkmark" : "arrow.down.doc.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(isSavedToLibrary ? "Đã nạp vào app" : "Nạp vào Thư Viện")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(isSavedToLibrary ? .green : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(isSavedToLibrary ? Color.white.opacity(0.12) : Color.white)
                    .cornerRadius(10)
                }
                .disabled(isSavedToLibrary)

                // Nút 2: Tải về / Chia sẻ
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .bold))
                        Text("Chia sẻ / Xuất")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.white.opacity(0.14))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(bgCard)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.green.opacity(0.3), lineWidth: 1.2))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }

    // MARK: - 6. Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            if currentStep == .waiting || currentStep == .uploading || currentStep == .processing {
                Button(action: startConversionProcess) {
                    HStack(spacing: 8) {
                        if currentStep == .uploading || currentStep == .processing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .bold))
                        }

                        Text(actionButtonText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(selectedFileURL != nil ? accentRed : Color.white.opacity(0.15))
                    .cornerRadius(14)
                    .shadow(color: selectedFileURL != nil ? accentRed.opacity(0.3) : Color.clear, radius: 8, y: 2)
                }
                .disabled(selectedFileURL == nil || currentStep == .uploading || currentStep == .processing)
            } else if case .failed = currentStep {
                Button(action: {
                    currentStep = .waiting
                    progressValue = 0.0
                    statusMessage = "Vui lòng thử lại hoặc chọn file khác."
                }) {
                    Text("Thử lại")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(accentRed)
                        .cornerRadius(14)
                }
            } else if case .completed = currentStep {
                Button(action: {
                    resetForm()
                }) {
                    Text("Mã hóa file .3105 khác")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                }
            }
        }
    }

    private var actionButtonText: String {
        switch currentStep {
        case .waiting: return "Bắt đầu Mã Hóa (.3105 ➔ .dat)"
        case .uploading: return "Đang tải file lên máy chủ..."
        case .processing: return "Đang mã hóa trên máy chủ..."
        case .completed: return "Đã hoàn tất"
        case .failed: return "Thử lại"
        }
    }

    // MARK: - Logic Xử Lý File
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }

            self.selectedFileURL = url
            self.selectedFileName = url.lastPathComponent
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                self.selectedFileSizeText = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            } else {
                self.selectedFileSizeText = "Kích thước không xác định"
            }

            self.currentStep = .waiting
            self.progressValue = 0.0
            self.statusMessage = "Sẵn sàng mã hóa tệp: \(url.lastPathComponent)"
            self.isSavedToLibrary = false
            self.outputDatData = nil
            self.outputInfo = nil
            self.outputLocalURL = nil

        case .failure(let error):
            self.currentStep = .failed(error.localizedDescription)
            self.statusMessage = "Không thể đọc file: \(error.localizedDescription)"
        }
    }

    private func startConversionProcess() {
        guard let fileURL = selectedFileURL else { return }

        currentStep = .uploading
        progressValue = 0.15
        statusMessage = "Đang kết nối tới server..."

        Task {
            do {
                let result = try await PatchCodecAPIService.shared.convertPatch(
                    sourceURL: fileURL,
                    onProgress: { prog, msg in
                        DispatchQueue.main.async {
                            self.progressValue = prog
                            self.statusMessage = msg
                            if prog < 0.5 {
                                self.currentStep = .uploading
                            } else if prog < 0.8 {
                                self.currentStep = .processing
                            }
                        }
                    }
                )

                DispatchQueue.main.async {
                    self.outputDatData = result.data
                    self.outputInfo = result.info
                    self.outputLocalURL = result.localDestinationURL
                    self.currentStep = .completed
                    self.progressValue = 1.0
                    self.statusMessage = "Mã hóa hoàn tất thành công! Đã tạo file \(result.info.outputFilename)."
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                DispatchQueue.main.async {
                    self.currentStep = .failed(error.localizedDescription)
                    self.statusMessage = error.localizedDescription
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }

    private func saveToAppLibrary() {
        guard let data = outputDatData, let info = outputInfo else { return }

        do {
            let root = try PatchProjectLibrary.packageRootURL()
            let destURL = root.appendingPathComponent(info.outputFilename)
            try data.write(to: destURL, options: .atomic)

            // Cập nhật lại thư viện patch trên UI
            patchStore.reload()

            isSavedToLibrary = true
            showSaveSuccessToast = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showSaveSuccessToast = false
            }
        } catch {
            statusMessage = "Lỗi khi lưu vào Thư Viện Patch: \(error.localizedDescription)"
        }
    }

    private func resetForm() {
        currentStep = .waiting
        progressValue = 0.0
        statusMessage = "Vui lòng chọn một file .3105 từ thiết bị của bạn."
        selectedFileURL = nil
        selectedFileName = ""
        selectedFileSizeText = ""
        outputDatData = nil
        outputInfo = nil
        outputLocalURL = nil
        isSavedToLibrary = false
    }
}

// MARK: - Activity View Representable (Chia sẻ file .dat)
private struct CodecActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
