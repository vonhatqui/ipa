import SwiftUI
import UIKit

@main
struct CheatStoreVNApp: App {
    @StateObject private var licenseManager = LicenseManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Khởi tạo và dọn dẹp các file lộ trong thư mục Documents
        LocalConfigManager.shared.cleanExposedDocumentsFiles()

        // Auto Lifecycle Restore: Tự động dọn dẹp và hoàn trả file gốc khi ứng dụng bị tắt
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { _ in
            _ = ContainerManager.shared.uninjectAndClean()
            LocalConfigManager.shared.cleanExposedDocumentsFiles()
        }
    }

    @ViewBuilder
    private var rootContentView: some View {
        if licenseManager.isActivated {
            MainDashboardView()
        } else {
            LoginView(licenseManager: licenseManager)
        }
    }

    var body: some Scene {
        WindowGroup {
            rootContentView
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        LocalConfigManager.shared.cleanExposedDocumentsFiles()
                    }
                }
        }
    }
}
