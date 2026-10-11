import SwiftUI

public struct InjectorBarButton: View {
    @ObservedObject var configManager: LocalConfigManager
    
    public enum InjectorState {
        case idleReady
        case processing(String)
        case connected
    }
    
    @State private var currentState: InjectorState = .idleReady
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        Button(action: handleAction) {
            HStack(spacing: 10) {
                switch currentState {
                case .idleReady:
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("INJETTOR")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                case .processing(let step):
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                    Text(step)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                case .connected:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("HỦY NẠP (UNINJECT)")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(buttonBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(buttonBorder, lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)
        }
        .disabled(isProcessing)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
    }

    private var isProcessing: Bool {
        if case .processing = currentState { return true }
        return false
    }

    private var buttonBackground: Color {
        switch currentState {
        case .idleReady:
            return Color(white: 0.10)
        case .processing:
            return Color(white: 0.18)
        case .connected:
            return AppTheme.dangerRed
        }
    }

    private var buttonBorder: Color {
        switch currentState {
        case .idleReady:
            return Color.white.opacity(0.35)
        case .processing:
            return Color(white: 0.5)
        case .connected:
            return Color.white.opacity(0.6)
        }
    }

    private func handleAction() {
        switch currentState {
        case .idleReady:
            performInject()
        case .processing:
            break
        case .connected:
            performUninject()
        }
    }

    private func performInject() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentState = .processing("ĐANG ĐỒNG BỘ CẤU HÌNH...")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.configManager.saveConfig()

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentState = .processing("ĐANG NẠP VÀO GAME...")
                }
            }

            // Lấy dữ liệu config
            let configData: Data
            if let d = try? JSONSerialization.data(withJSONObject: self.configManager.rawConfig, options: [.prettyPrinted, .sortedKeys]) {
                configData = d
            } else if let localD = try? Data(contentsOf: self.configManager.configURL) {
                configData = localD
            } else {
                configData = Data("{}".utf8)
            }

            // Lấy dữ liệu patch Assembly-CSharp-patch.bytes
            var patchData: Data? = nil
            if let patchURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes") {
                patchData = try? Data(contentsOf: patchURL)
            }

            let result = ContainerManager.shared.injectPatchAndConfig(configData: configData, patchData: patchData)

            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.currentState = .connected
                    }
                    self.alertTitle = "Nạp Cấu Hình Thành Công"
                    self.alertMessage = "Đã nạp Assembly-CSharp-patch.bytes và localConfig.json vào \(count) container Free Fire.\nSẵn sàng mở game."
                case .noContainerFound:
                    self.currentState = .idleReady
                    self.alertTitle = "Không Tìm Thấy Game"
                    self.alertMessage = "Chưa tìm thấy game Free Fire trên thiết bị. Cấu hình đã được lưu nội bộ."
                case .missingPayload:
                    self.currentState = .idleReady
                    self.alertTitle = "Thiếu File Patch"
                    self.alertMessage = "Không tìm thấy file Assembly-CSharp-patch.bytes trong ứng dụng."
                case .failure(let msg):
                    self.currentState = .idleReady
                    self.alertTitle = "Lỗi Nạp Cấu Hình"
                    self.alertMessage = msg
                }
                self.showingAlert = true
            }
        }
    }

    private func performUninject() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentState = .processing("ĐANG DỌN DẸP & HỦY NẠP...")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            _ = ContainerManager.shared.uninjectAndClean()
            self.configManager.cleanExposedDocumentsFiles()

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.currentState = .idleReady
                }
                self.alertTitle = "Đã Hủy Nạp Hoàn Toàn"
                self.alertMessage = "Đã dọn dẹp sạch sẽ toàn bộ file mod trong thư mục game Free Fire và khôi phục trạng thái an toàn."
                self.showingAlert = true
            }
        }
    }
}
