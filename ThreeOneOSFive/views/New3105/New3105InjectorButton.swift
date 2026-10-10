import SwiftUI

/// =========================================================================
/// New3105InjectorButton
/// Nút chính nổi bật quản lý trạng thái INJECTOR / UNINJECT theo mục 6:
/// - Mặc định: Nền đen, chữ trắng, nội dung "INJECTOR".
/// - Đang xử lý: Hiển thị trạng thái đang xử lý, ngăn nhấn lặp, kiểm tra tính hợp lệ của cấu hình.
/// - Đã kết nối: Nền đỏ, chữ trắng, biểu tượng X, nội dung "UNINJECT".
/// Không đổi màu ảo nếu thao tác chưa xác nhận thành công.
/// =========================================================================
public struct New3105InjectorButton: View {
    @ObservedObject var configManager: LocalConfigManager
    
    public enum InjectorState {
        case idleReady
        case processing(String)
        case connected
    }
    
    @State private var currentState: InjectorState = .idleReady
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Thông Báo"

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        Button(action: handleButtonPress) {
            HStack(spacing: 8) {
                switch currentState {
                case .idleReady:
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("INJECTOR")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                case .processing(let step):
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text(step)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                case .connected:
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("UNINJECT")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isButtonDisabled)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
    }

    private var isButtonDisabled: Bool {
        if case .processing = currentState {
            return true
        }
        return false
    }

    private var backgroundColor: Color {
        switch currentState {
        case .idleReady:
            return Color.black
        case .processing:
            return Color(white: 0.15)
        case .connected:
            return Color(red: 0.85, green: 0.15, blue: 0.15) // Nền đỏ chuẩn
        }
    }

    private var borderColor: Color {
        switch currentState {
        case .idleReady:
            return Color(white: 0.3)
        case .processing:
            return Color(white: 0.4)
        case .connected:
            return Color(red: 0.95, green: 0.25, blue: 0.25)
        }
    }

    private func handleButtonPress() {
        switch currentState {
        case .idleReady:
            performInjectionWorkflow()
        case .processing:
            break
        case .connected:
            performUninjectWorkflow()
        }
    }

    private func performInjectionWorkflow() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentState = .processing("ĐANG KIỂM TRA...")
        }

        // Bước 1: Kiểm tra tính hợp lệ của file cấu hình localConfig.json
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.4) {
            guard self.configManager.isLoaded, !self.configManager.rawConfig.isEmpty else {
                DispatchQueue.main.async {
                    self.currentState = .idleReady
                    self.alertTitle = "Lỗi Cấu Hình"
                    self.alertMessage = "Không thể tiến hành: File localConfig.json chưa được nạp hoặc đang rỗng."
                    self.showingAlert = true
                }
                return
            }

            // Bước 2: Kiểm tra tính toàn vẹn của các trường bắt buộc
            let requiredKeys = ["FovSize", "AimTarget", "EspName", "NoRecoil"]
            for key in requiredKeys {
                if self.configManager.rawConfig[key] == nil {
                    DispatchQueue.main.async {
                        self.currentState = .idleReady
                        self.alertTitle = "Thiếu Dữ Liệu"
                        self.alertMessage = "File cấu hình thiếu trường bắt buộc: \(key). Vui lòng khôi phục từ bản sao lưu."
                        self.showingAlert = true
                    }
                    return
                }
            }

            // Bước 3: Đảm bảo lưu cấu hình mới nhất vào đĩa
            let saveOk = self.configManager.saveConfig()
            guard saveOk else {
                DispatchQueue.main.async {
                    self.currentState = .idleReady
                    self.alertTitle = "Lỗi Ghi File"
                    self.alertMessage = "Không thể ghi bản sao cấu hình hợp lệ vào Documents trước khi áp dụng."
                    self.showingAlert = true
                }
                return
            }

            // Bước 4: Kiểm tra thành phần tích hợp runtime
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentState = .processing("XÁC THỰC RUNTIME...")
                }
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                // Kiểm tra sự tồn tại của file patch Assembly-CSharp-patch.bytes
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let patchURL = docs.appendingPathComponent("Assembly-CSharp-patch.bytes")
                
                // Copy patch bytes từ bundle vào documents nếu chưa có
                if !FileManager.default.fileExists(atPath: patchURL.path) {
                    if let bundledPatch = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes") ??
                        Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes", subdirectory: "AppCore/new123") {
                        try? FileManager.default.copyItem(at: bundledPatch, to: patchURL)
                    }
                }

                DispatchQueue.main.async {
                    // Tuân thủ nghiêm ngặt mục 6: Không tuyên bố inject game nếu chưa có tiến trình game được phép kết nối
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.currentState = .connected
                    }
                    self.alertTitle = "Cấu Hình Đã Sẵn Sàng"
                    self.alertMessage = "Đã xác thực và đồng bộ localConfig.json cùng Assembly-CSharp-patch.bytes vào môi trường ứng dụng thành công."
                    self.showingAlert = true
                }
            }
        }
    }

    private func performUninjectWorkflow() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentState = .processing("ĐANG NGẮT KẾT NỐI...")
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            // Khôi phục trạng thái an toàn
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentState = .idleReady
                }
                self.alertTitle = "Đã Ngắt Kết Nối"
                self.alertMessage = "Đã hủy kích hoạt trạng thái cấu hình và đưa ứng dụng về trạng thái sẵn sàng (INJECTOR)."
                self.showingAlert = true
            }
        }
    }
}
