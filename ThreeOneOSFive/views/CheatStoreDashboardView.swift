import SwiftUI
import UIKit
import WebKit

// MARK: - CheatStoreTab Enum (2 Tab: Trang Chủ, Cá Nhân)
enum CheatStoreTab: Int, CaseIterable {
    case home = 0
    case profile = 1

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .profile: return "Cá Nhân"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Reusable 0xCheats Checkbox Chip Button (.chip với .box 18x18 chuẩn 100%)
struct ZeroXChipButton: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    var isUnderMaintenance: Bool = false
    var maintenanceBadge: String? = "BẢO TRÌ"
    var accentColor: Color = Color(red: 255/255, green: 48/255, blue: 48/255)
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        isUnderMaintenance: Bool = false,
        maintenanceBadge: String? = "BẢO TRÌ",
        accentColor: Color = Color(red: 255/255, green: 48/255, blue: 48/255),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isUnderMaintenance = isUnderMaintenance
        self.maintenanceBadge = maintenanceBadge
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            if isUnderMaintenance {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            action()
        }) {
            HStack(spacing: 9) {
                // Nếu đang bảo trì/lỗi: Ẩn ô vuông đi, thay bằng icon biển báo tam giác chấm than màu đỏ!
                if isUnderMaintenance {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255))
                        .frame(width: 18, height: 18)
                } else {
                    // Square .box (18x18, border 1.5, radius 6)
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                isSelected ? Color(red: 244/255, green: 241/255, blue: 234/255) : Color(red: 244/255, green: 241/255, blue: 234/255).opacity(0.22),
                                lineWidth: 1.5
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isSelected ? Color(red: 244/255, green: 241/255, blue: 234/255) : Color.clear)
                            )
                            .frame(width: 18, height: 18)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(Color(red: 17/255, green: 17/255, blue: 17/255))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                isUnderMaintenance
                                    ? Color(red: 239/255, green: 68/255, blue: 68/255)
                                    : (isSelected ? Color(red: 244/255, green: 241/255, blue: 234/255) : Color(red: 244/255, green: 241/255, blue: 234/255).opacity(0.82))
                            )
                            .lineLimit(1)

                        if isUnderMaintenance, let badge = maintenanceBadge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.85))
                                .cornerRadius(4)
                        }
                    }

                    if let sub = subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(
                                isUnderMaintenance
                                    ? Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.75)
                                    : Color(red: 141/255, green: 136/255, blue: 128/255)
                            )
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: subtitle == nil ? 46 : 52)
            .background(
                isUnderMaintenance
                    ? Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.08)
                    : (isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isUnderMaintenance
                            ? Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.4)
                            : (isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ZeroXScaleButtonStyle())
    }
}

/// ButtonStyle tạo hiệu ứng đàn hồi nảy êm ái phong cách Aurora iOS
private struct AuroraScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Main Dashboard View
struct CheatStoreDashboardView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    @ObservedObject private var antibanService = AntibanProfileService.shared
    @ObservedObject private var cloudPatchService = CloudPatchService.shared
    var onBackToGames: (() -> Void)? = nil

    // Tab state
    @State private var selectedTab: CheatStoreTab = .home

    // Tab 1: Trang Chủ State
    @State private var selectedGame: String = "ff"           // "ff" or "max"
    @State private var activeAimPatch: String? = nil
    @State private var selectedAimChips: Set<String> = []
    @State private var isInjecting: Bool = false
    @AppStorage("cheatstore_selected_game_version") private var selectedGameVersionRaw: String = FreeFireGameVersion.standard.rawValue
    @AppStorage("cheatstore_selected_menu_feature") private var selectedMenuFeature: String = "cheatvn_external"
    @State private var isInjected: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var injectionProgress: Int = 0
    @State private var injectionStatusText: String = "Đang nạp patching..."

    private var currentAimDisplayText: String {
        let activeMods = Array(selectedAimChips)
        if activeMods.isEmpty {
            return "Chưa bật"
        }
        return activeMods.joined(separator: " + ")
    }

    // Tab 2: Định Vị State (chỉ 1 gói lib_app_esp_aimhead_v3)
    @State private var activeEspColor: String? = nil
    @State private var selectedEspChips: Set<String> = []
    @State private var isInjectingEsp: Bool = false

    // Tab 4: Antiban State
    @State private var miscGame: String = "ff"
    @State private var miscToggles: [Int: Bool] = [
        1: true,
        8: true
    ]

    // Tab 5: Cá Nhân State (Chi tiết & Sang trọng)
    @State private var copiedKey: Bool = false
    @State private var copiedHWID: Bool = false
    @State private var enableHaptic: Bool = true
    @State private var autoCleanOnExit: Bool = true
    @State private var selectedLanguage: String = "Tiếng Việt"
    @State private var showCompatList: Bool = false
    @State private var showDeltaSettingsSheet: Bool = false
    @State private var showOriginal3105View: Bool = false
    @ObservedObject private var antibanPatchService = AntibanPatchService.shared

    // Common Alerts & Status
    @State private var alertTitle: String = ""
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    @State private var isRestoringClean: Bool = false
    @State private var isRestoringForGameSwitch: Bool = false

    // Toast Notification State
    @State private var toastMessage: String = ""
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = Color.green
    @State private var showToast: Bool = false

    // Detailed Restore Progress Modal State
    @State private var showRestoreProgressModal: Bool = false
    @State private var restoreProgressValue: Double = 0.0
    @State private var restoreCurrentStepTitle: String = ""
    @State private var restoreCompletedSteps: [String] = []
    @State private var isRestoreFinished: Bool = false

    // Multi-Brand Dynamic Theme (CheatStore VN, VeLix VN, Venom VN)
    private var theme: AppBrandingTheme { AppBrandingTheme.current }
    private var colorVoid: Color { theme.colorVoid }
    private var colorPanel: Color { theme.colorPanel }
    private var colorInk: Color { theme.colorInk }
    private var colorMute: Color { theme.colorMute }
    private var glassBg: Color { theme.glassBg }
    private var glassBorder: Color { theme.glassBorder }

    var body: some View {
        legacyMultiBrandDashboardView
    }

    private var legacyMultiBrandDashboardView: some View {
        ZStack {
            // Nền đen sâu True Black Void
            colorVoid.ignoresSafeArea()

            // Nền chất lỏng Snapchat Ferrofluid sống động
            SnapchatFluidLiquidBackgroundView()
                .ignoresSafeArea()
                .opacity(0.85)

            // Vầng sáng LED Ambient rực rỡ theo chủ đề
            RadialGradient(
                gradient: Gradient(colors: theme.ambientGlowGradient),
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header thanh trên: nếu ở Dashboard (home) thì hiển thị Aurora Header chuẩn ảnh mẫu, các tab khác giữ nguyên
                if selectedTab == .home {
                    auroraTopHeaderView
                } else {
                    topHeaderView
                }

                // Nội dung 2 Tab: Trang Chủ, Cá Nhân
                ZStack {
                    if selectedTab == .home {
                        homeView
                            .transition(.opacity)
                    } else if selectedTab == .profile {
                        profileView
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Limelight Dock Bar Navigation
                LimelightDockBar(selectedTab: $selectedTab, licenseManager: licenseManager)
                    .padding(.bottom, 2)

                if selectedTab != .home {
                    // Thanh Thông Tin Thiết Bị Dưới Dashboard
                    dashboardDeviceFooterView
                        .padding(.bottom, 4)
                }
            }

            // Toast Notification Banner (overlay phía trên)
            if showToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: toastIcon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(toastColor)

                        Text(toastMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(colorInk)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showToast = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(colorMute)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 28/255, green: 28/255, blue: 32/255).opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(toastColor.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: toastColor.opacity(0.2), radius: 12, y: 4)
                    .shadow(color: Color.black.opacity(0.5), radius: 8, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }

            // Loading overlay khi đang khôi phục cho đổi game
            if isRestoringForGameSwitch {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Đang khôi phục dữ liệu gốc...")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Vui lòng chờ trong giây lát")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(colorMute)
                    }
                    .padding(28)
                    .background(Color(red: 22/255, green: 22/255, blue: 26/255))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }
                .transition(.opacity)
                .zIndex(1000)
            }

            // MODAL LOADING CHI TIẾT KHI KHÔI PHỤC GỐC AN TOÀN 100%
            if showRestoreProgressModal {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()

                    VStack(spacing: 16) {
                        // Header Icon Khiên / Mũi Tên Hoàn Tác
                        ZStack {
                            Circle()
                                .fill(isRestoreFinished ? Color.green.opacity(0.18) : Color.orange.opacity(0.15))
                                .frame(width: 58, height: 58)

                            Image(systemName: isRestoreFinished ? "checkmark.shield.fill" : "arrow.counterclockwise.shield.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(isRestoreFinished ? .green : .orange)
                        }

                        VStack(spacing: 4) {
                            Text(isRestoreFinished ? "KHÔI PHỤC HOÀN TẤT 100%" : "ĐANG KHÔI PHỤC DỮ LIỆU GỐC")
                                .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text(isRestoreFinished ? "Game đã trở về trạng thái nguyên bản sạch sẽ an toàn" : "Hệ thống đang tiến hành làm sạch theo quy trình chuẩn")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                                .multilineTextAlignment(.center)
                        }

                        // Thanh Progress Bar
                        VStack(spacing: 6) {
                            ProgressView(value: restoreProgressValue, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.white))
                                .scaleEffect(x: 1, y: 2.2, anchor: .center)
                                .clipShape(Capsule())

                            HStack {
                                Text(restoreCurrentStepTitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(colorMute)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(restoreProgressValue * 100))%")
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white)
                            }
                        }
                        .padding(.horizontal, 4)

                        Divider().background(Color.white.opacity(0.1))

                        // Danh Sách Các Bước Đã Khôi Phục Cho Khách Thấy Rõ
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CÁC MỤC ĐÃ KHÔI PHỤC AN TOÀN:")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.5)
                                .foregroundColor(colorMute.opacity(0.85))

                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(restoreCompletedSteps, id: \.self) { step in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
                                                .padding(.top, 1)

                                            Text(step)
                                                .font(.system(size: 11.5, weight: .medium))
                                                .foregroundColor(colorInk.opacity(0.92))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 130)
                        }

                        // Nút Đóng Khi Hoàn Tất
                        if isRestoreFinished {
                            Button {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showRestoreProgressModal = false
                                }
                            } label: {
                                Text("HOÀN TẤT & ĐÓNG")
                                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.white.opacity(0.25), radius: 8, y: 2)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(20)
                    .background(Color(red: 22/255, green: 22/255, blue: 26/255))
                    .cornerRadius(22)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1.2))
                    .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 8)
                    .padding(.horizontal, 24)
                }
                .zIndex(1001)
                .transition(.opacity)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle.isEmpty ? "Thông báo" : alertTitle),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("Đóng"))
            )
        }
        .sheet(isPresented: $showCompatList) {
            IOSCompatibilityListView()
        }
        .sheet(isPresented: $showDeltaSettingsSheet) {
            DeltaStyleSettingsView()
        }
        .fullScreenCover(isPresented: $showOriginal3105View) {
            Original3105WorkspaceView()
                .environmentObject(patchDraftCoordinator)
                .environmentObject(patchStore)
                .environmentObject(repositoryStore)
                .environmentObject(appState)
                .environmentObject(fileOperationCoordinator)
        }
        .onAppear {
            cloudPatchService.syncCloudPatches()
        }
        .onChange(of: selectedTab) { _ in
            cloudPatchService.syncCloudPatches()
        }
        .onReceive(cloudPatchService.$cloudPatches) { newPatches in
            if !newPatches.isEmpty {
                let validNames = Set(newPatches.map { $0.name.uppercased() })
                selectedAimChips = selectedAimChips.filter { validNames.contains($0.uppercased()) }
                selectedEspChips = selectedEspChips.filter { validNames.contains($0.uppercased()) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            cloudPatchService.syncCloudPatches()
        }
    }

    // MARK: - Aurora Free Fire Top Header (Chuẩn 100% Ảnh Mẫu Aurora iOS)
    private var auroraTopHeaderView: some View {
        HStack {
            // Nút quay lại: < Games + Nút mở 3105 bé bé kế nút đổi game (kiểu mở website)
            HStack(spacing: 6) {
                if let onBackToGames = onBackToGames {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        handleBackToGames(onBackToGames)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Games")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.white)
                    }
                    .disabled(isRestoringForGameSwitch || isInjecting)
                }

                // Nút mở 3105 bé bé kế nút đổi game (kiểu mở website)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showOriginal3105View = true
                }) {
                    HStack(spacing: 3) {
                        Text("3105")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8.5, weight: .bold))
                    }
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.10))
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                    )
                }
            }

            Spacer()

            // Tên thương hiệu + Tên game (Center)
            VStack(spacing: 2) {
                Text(brandHeaderTitle)
                    .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                    .foregroundColor(colorInk)
                    .tracking(0.5)

                Text(auroraGameSubtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.92))
                    .shadow(color: Color.white.opacity(0.65), radius: 6, x: 0, y: 0)
            }

            Spacer()

            // Trạng thái (Right pill badge) + Nút Cài Đặt bên phải cạnh chữ Not Injected
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    if isInjecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.65)
                        Text("Injecting...")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else if isInjected {
                        Circle()
                            .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                            .frame(width: 6, height: 6)
                            .shadow(color: Color.green.opacity(0.8), radius: 3)
                        Text("Injected")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
                    } else {
                        Text("Not Injected")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(
                            isInjected ? Color.green.opacity(0.4) :
                            (isInjecting ? Color.white.opacity(0.5) : Color.white.opacity(0.18)),
                            lineWidth: 1
                        )
                )

                // Nút Cài Đặt (Settings button) nằm ngay bên phải cạnh chữ Not Injected
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showDeltaSettingsSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                }
                .buttonStyle(AuroraScaleButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var brandHeaderTitle: String {
        return theme.appTitle
    }

    private var auroraGameSubtitle: String {
        return "Cheat External"
    }

    private var brandCenterTag: String {
        return theme.discordTag
    }

// MARK: - Rainbow Animated Text (Chữ 7 màu dạ quang huyền bí đồng bộ theo thương hiệu)
struct RainbowText: View {
    let text: String
    @State private var animateGradient: Bool = false

    private var rainbowColors: [Color] {
        AppBrandingTheme.current.rainbowColors
    }

    private var glowColor: Color {
        switch AppBrandingTheme.current {
        case .cheatStore:
            return Color.white // Vầng hào quang trắng phát sáng
        case .veLix:
            return AppBrandingTheme.current.accentColor
        case .venom:
            return AppBrandingTheme.current.accentColor
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 23, weight: .black, design: .rounded))
            .foregroundColor(.clear)
            .overlay(
                LinearGradient(
                    colors: rainbowColors,
                    startPoint: animateGradient ? UnitPoint(x: -0.7, y: 0.5) : UnitPoint(x: 0.7, y: 0.5),
                    endPoint: animateGradient ? UnitPoint(x: 0.5, y: 0.5) : UnitPoint(x: 1.9, y: 0.5)
                )
                .mask(
                    Text(text)
                        .font(.system(size: 23, weight: .black, design: .rounded))
                )
            )
            .shadow(color: glowColor.opacity(0.65), radius: 14, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.8), radius: 6, x: 0, y: 3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.6)
                    .repeatForever(autoreverses: true)
                ) {
                    animateGradient = true
                }
            }
    }
}

    // MARK: - Top Header (.main-head bx-head)
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            CheatStoreLogoView(size: 40, cornerRadius: 11)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(theme.accentColor.opacity(0.55), lineWidth: 1.2)
                )
                .shadow(color: theme.accentColor.opacity(0.45), radius: 8, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedTab.title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(3.2)
                    .foregroundColor(theme.accentColor.opacity(0.85))

                ShinyTextView(
                    text: theme.appTitle,
                    font: .system(size: 22, weight: .heavy, design: .rounded),
                    baseColor: colorInk,
                    shineColor: theme.accentColor,
                    duration: 2.2,
                    tracking: -0.5
                )
            }
            Spacer()

            if let onBackToGames = onBackToGames {
                HStack(spacing: 6) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        handleBackToGames(onBackToGames)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 12))
                            Text("Đổi Game")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(colorInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(glassBorder, lineWidth: 1))
                    }
                    .disabled(isRestoringForGameSwitch)

                    // Nút mở 3105 bé bé kế nút đổi game (kiểu mở website)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showOriginal3105View = true
                    }) {
                        HStack(spacing: 3) {
                            Text("3105")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8.5, weight: .bold))
                        }
                        .foregroundColor(colorInk.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(glassBorder, lineWidth: 0.8))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    // MARK: - TAB 1: Aurora Free Fire Dashboard View (Chuẩn 100% Ảnh Mẫu Aurora iOS)
    private var homeView: some View {
        VStack(spacing: 0) {
            Spacer()

            // CHÍNH GIỮA: Discord: @jinwwostore.vn (Chữ trắng phát sáng) + Nút Zalo / Tele
            VStack(spacing: 8) {
                Text(theme.discordTag)
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.9), radius: 14, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.8), radius: 6, x: 0, y: 3)

                Text("Mô tả: Liên hệ khi cần hỗ trợ")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.65))

                // Các nút hỗ trợ Zalo / Telegram
                if theme.zaloURLString != nil || theme.telegramURLString != nil {
                    HStack(spacing: 16) {
                        // Nút Zalo
                        if let zaloURL = theme.zaloURLString, let url = URL(string: zaloURL) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                UIApplication.shared.open(url)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.10))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                                        )
                                        .shadow(color: Color.white.opacity(0.25), radius: 6, x: 0, y: 0)

                                    Text("Z")
                                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(AuroraScaleButtonStyle())
                        }

                        // Nút Telegram (tự động ẩn nếu thương hiệu không có tele)
                        if let teleURL = theme.telegramURLString, let url = URL(string: teleURL) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                UIApplication.shared.open(url)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.10))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                                        )
                                        .shadow(color: Color.white.opacity(0.25), radius: 6, x: 0, y: 0)

                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: -1, y: 1)
                                }
                            }
                            .buttonStyle(AuroraScaleButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .scaleEffect(isInjecting ? (pulseAnimation ? 1.03 : 0.98) : 1.0)
            .animation(isInjecting ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: pulseAnimation)

            Spacer()

            // PHÍA DƯỚI: Chọn Chức Năng + Nút INJECTOR / UNINJECT lớn
            VStack(spacing: 12) {
                featureSelectorCards
                auroraInjectorButton

                // Dòng trạng thái và hướng dẫn bên dưới nút (hiển thị spinner khi đang tiến hành)
                HStack(spacing: 7) {
                    if isInjecting || isRestoringClean {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    }

                    Text(auroraInstructionText)
                        .font(.system(size: 13.5, weight: (isInjecting || isRestoringClean) ? .semibold : .medium, design: .rounded))
                        .foregroundColor(
                            (isInjecting || isRestoringClean) ? Color.white : (isInjected ? Color(red: 1.0, green: 0.55, blue: 0.55) : Color.white.opacity(0.70))
                        )
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var auroraInjectorButton: some View {
        Button(action: {
            if isInjected {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                performCleanRestore()
            } else if !isInjecting && !isRestoringClean {
                startAuroraInjection()
            }
        }) {
            ZStack {
                // Nền nút: Đen tuyền sang trọng khi chưa inject (INJECTOR) | Đỏ thẫm khi đã inject (UNINJECT)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isInjected ?
                        LinearGradient(
                            colors: isRestoringClean ? [
                                Color(red: 0.55, green: 0.08, blue: 0.10),
                                Color(red: 0.38, green: 0.05, blue: 0.08)
                            ] : [
                                Color(red: 0.72, green: 0.10, blue: 0.14),
                                Color(red: 0.50, green: 0.06, blue: 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: isInjecting ? [
                                Color(red: 0.12, green: 0.12, blue: 0.15),
                                Color(red: 0.05, green: 0.05, blue: 0.07)
                            ] : [
                                Color(red: 0.07, green: 0.07, blue: 0.09),
                                Color(red: 0.02, green: 0.02, blue: 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isInjected
                                    ? Color.red.opacity(0.45)
                                    : Color.white.opacity(0.24),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: isInjected
                            ? Color.red.opacity(0.30)
                            : Color.black.opacity(0.70),
                        radius: 14,
                        y: 4
                    )

                // Dải LED sáng sang chảnh chạy ngang qua nút (như nút Launch ở màn hình login)
                if !isInjected {
                    AuroraButtonLedSweep(cornerRadius: 18)
                }

                // Nội dung nút theo các trạng thái
                HStack(spacing: 10) {
                    if isInjecting {
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)

                                Text("\(injectionStatusText) (\(injectionProgress)%)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(injectionProgress) / 100.0)), height: 4)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, 24)
                        }
                    } else if isRestoringClean {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.0)

                        Text("Uninjecting...")
                            .font(.system(size: 16.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else if isInjected {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("UNINJECT")
                            .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.0)
                    } else {
                        Image(systemName: "syringe.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)

                        ShinyTextView(
                            text: "INJECTOR",
                            font: .system(size: 16.5, weight: .heavy, design: .rounded),
                            baseColor: .white,
                            shineColor: .white,
                            duration: 2.2,
                            tracking: 1.5
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(AuroraScaleButtonStyle())
        .disabled(isInjecting || isRestoringClean)
    }

    // MARK: - Chọn Chức Năng Menu (CheatVN External & DeltaX Enternal xếp trên dưới banner ngang)
    @ViewBuilder
    private var featureSelectorCards: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("CHỌN MENU CHỨC NĂNG")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(Color.white.opacity(0.60))

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5.5, height: 5.5)
                    Text("CHỌN TRƯỚC KHI INJECT")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.green.opacity(0.9))
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                // Chức năng 1 (Trên): CheatVN External - Banner ngang dài
                featureCard(
                    id: "cheatvn_external",
                    title: "CheatVN External",
                    logoImageName: "cheatvn_external",
                    assetImageName: "CheatVNExternal",
                    badgeText: "V1.3105",
                    accentGlow: Color(red: 1.0, green: 0.25, blue: 0.25)
                )

                // Chức năng 2 (Dưới): DeltaX Enternal - Banner ngang dài
                featureCard(
                    id: "deltax_enternal",
                    title: "DeltaX Enternal",
                    logoImageName: "deltax_enternal",
                    assetImageName: "DeltaXEnternal",
                    badgeText: "NO KEY",
                    accentGlow: Color(red: 0.20, green: 0.75, blue: 1.0)
                )
            }
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private func featureCard(
        id: String,
        title: String,
        logoImageName: String,
        assetImageName: String,
        badgeText: String,
        accentGlow: Color
    ) -> some View {
        let isSelected = (selectedMenuFeature == id)

        Button(action: {
            guard !isInjecting && !isRestoringClean else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            CheatStoreSoundManager.shared.playTabSwitchHaptic()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedMenuFeature = id
            }
        }) {
            ZStack {
                // Nền thẻ dài ngang: Sáng rực rỡ khi được chọn, nền tối mờ khi chưa chọn
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.17, green: 0.18, blue: 0.24),
                                Color(red: 0.08, green: 0.09, blue: 0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(red: 0.07, green: 0.07, blue: 0.09),
                                Color(red: 0.03, green: 0.03, blue: 0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(
                                isSelected ?
                                LinearGradient(
                                    colors: [accentGlow, Color.white, accentGlow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 1.8 : 1.0
                            )
                    )
                    .shadow(
                        color: isSelected ? accentGlow.opacity(0.60) : Color.black.opacity(0.4),
                        radius: isSelected ? 12 : 3,
                        x: 0,
                        y: isSelected ? 0 : 2
                    )

                // Dải LED sáng chạy ngang khi được chọn (hiện sáng sang trọng)
                if isSelected {
                    AuroraButtonLedSweep(cornerRadius: 15)
                }

                // Nội dung thẻ xếp ngang: Logo + Tên Chức Năng (Không có mô tả) + Badge & Checkmark
                HStack(spacing: 12) {
                    // Logo chức năng bo góc
                    featureLogo(logoName: logoImageName, assetName: assetImageName, fallbackIcon: "bolt.shield.fill")

                    // Tên chức năng (KHÔNG CÓ BẤT KỲ MÔ TẢ NÀO)
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    // Badge phiên bản
                    Text(badgeText)
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(isSelected ? accentGlow.opacity(0.25) : Color.white.opacity(0.08))
                        .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.60))
                        .cornerRadius(6)

                    // Icon chọn
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(accentGlow)
                            .shadow(color: accentGlow.opacity(0.8), radius: 6)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(AuroraScaleButtonStyle())
    }

    @ViewBuilder
    private func featureLogo(logoName: String, assetName: String, fallbackIcon: String) -> some View {
        if let uiImg = UIImage(named: assetName) ?? UIImage(named: logoName) ?? loadLogoFromDisk(named: logoName) {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: fallbackIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private func loadLogoFromDisk(named: String) -> UIImage? {
        let nameWithPng = named.hasSuffix(".png") ? named : "\(named).png"
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent(nameWithPng).path,
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent(nameWithPng).path,
            Bundle.main.bundleURL.appendingPathComponent("AppCore/Assets").appendingPathComponent(nameWithPng).path,
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/Assets").appendingPathComponent(nameWithPng).path,
            "ThreeOneOSFive/\(nameWithPng)",
            "assets/brands/\(nameWithPng)"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path), let img = UIImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }

    private var auroraInstructionText: String {
        let featureTitle = selectedMenuFeature == "deltax_enternal" ? "DeltaX Enternal" : "CheatVN External"
        if isInjecting {
            return "\(injectionStatusText) (\(injectionProgress)%)"
        } else if isRestoringClean {
            return "Đang gỡ mod và khôi phục dữ liệu gốc..."
        } else if isInjected {
            return "Đã nạp \(featureTitle) vào game thành công!"
        } else {
            return "Chạm INJECTOR để nạp \(featureTitle) và vào game"
        }
    }

    private func startAuroraInjection() {
        guard !isInjecting else { return }
        isInjecting = true
        isInjected = false
        pulseAnimation = true
        injectionProgress = 1
        injectionStatusText = "Đang nạp patching..."
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // 1. Chạy background task nạp gói patch theo menu được chọn
        DispatchQueue.global(qos: .userInitiated).async {
            let ok: Bool
            if self.selectedMenuFeature == "deltax_enternal" {
                ok = self.applyDeltaXPackage()
            } else {
                ok = self.applyAuroraPackage()
            }
            DevicePatchService.ensureActivePatchesInjected()
            print("[CheatStore] Nạp hoàn tất (\(self.selectedMenuFeature)): \(ok)")
        }

        // 2. Chạy timer tăng tiến độ 1% -> 100% mượt mà
        // 1-40%: Đang nạp patching...
        // 41-80%: Đang bypass anti-cheat...
        // 81-100%: Đang chuẩn bị vào game...
        let stepInterval: TimeInterval = 0.04
        Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            if self.injectionProgress < 100 {
                self.injectionProgress += 1
                if self.injectionProgress <= 40 {
                    self.injectionStatusText = "Đang nạp patching..."
                } else if self.injectionProgress <= 80 {
                    self.injectionStatusText = "Đang bypass anti-cheat..."
                } else {
                    self.injectionStatusText = "Đang chuẩn bị vào game..."
                }
            } else {
                timer.invalidate()
                self.injectionStatusText = "Hoàn tất! Đang vào game..."
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    self.isInjecting = false
                    self.isInjected = true
                    self.pulseAnimation = false
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                CheatStoreSoundManager.shared.playTabSwitchHaptic()

                let featTitle = self.selectedMenuFeature == "deltax_enternal" ? "DeltaX Enternal" : "CheatVN External"
                self.showToastNotification(
                    message: "Đã nạp \(featTitle) thành công! Đang vào game...",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )

                // Vào thẳng game luôn!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.handleLaunchGame()
                }
            }
        }
    }

    /// Nạp file CheatVN External (Assembly-CSharp-patch.bytes, localConfig.json, .ffxc_live, .ffxc_neutral, .ffxc_runtime)
    @discardableResult
    private func applyAuroraPackage() -> Bool {
        let fileManager = FileManager.default
        let patchPassword = UserDefaults.standard.string(forKey: "CheatStore_CorePatchPassword") ?? "1"

        // 1. Kích hoạt và tìm tất cả container của Free Fire (cả Standard lẫn MAX)
        let targets = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
        var targetContainerRoots: [URL] = []
        for bID in targets {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bID) {
                let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
                if !targetContainerRoots.contains(url) {
                    targetContainerRoots.append(url)
                }
            }
        }
        for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
            let canonical = PatchPathValidator.canonicalFileURL(root)
            if !targetContainerRoots.contains(canonical) {
                targetContainerRoots.append(canonical)
            }
        }
        if let ffPath = findFreeFireContainerPath() {
            let canonical = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: ffPath, isDirectory: true))
            if !targetContainerRoots.contains(canonical) {
                targetContainerRoots.append(canonical)
            }
        }
        // Quét trực tiếp thư mục /var/mobile/Containers/Data/Application để phát hiện cả FF và FF MAX
        for rootPath in ["/private/var/mobile/Containers/Data/Application", "/var/mobile/Containers/Data/Application"] {
            if let dirs = try? fileManager.contentsOfDirectory(atPath: rootPath) {
                for d in dirs {
                    let full = (rootPath as NSString).appendingPathComponent(d)
                    let chk1 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefireth.plist")
                    let chk2 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
                    let chk3 = (full as NSString).appendingPathComponent("Documents/contentcache")
                    if fileManager.fileExists(atPath: chk1) || fileManager.fileExists(atPath: chk2) || fileManager.fileExists(atPath: chk3) {
                        let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: full, isDirectory: true))
                        if !targetContainerRoots.contains(url) {
                            targetContainerRoots.append(url)
                        }
                    }
                }
            }
        }

        print("[CheatStore] 🎯 Đã tìm thấy \(targetContainerRoots.count) container Free Fire:")
        for r in targetContainerRoots {
            print("[CheatStore]  -> \(r.path)")
        }

        // 2. Thu thập đầy đủ 5 file Hotfix IFix chuẩn của CheatVN External:
        //    - Assembly-CSharp-patch.bytes
        //    - localConfig.json
        //    - .ffxc_live
        //    - .ffxc_neutral_37ca851ab5df497db608f1b2f45165f9
        //    - .ffxc_runtime
        var searchDirs: [URL] = []
        if let bundleRes = Bundle.main.resourceURL {
            searchDirs.append(bundleRes.appendingPathComponent("AppCore"))
            searchDirs.append(bundleRes.appendingPathComponent("BundledPatches/CheatVN_External_Files/Documents"))
            searchDirs.append(bundleRes.appendingPathComponent("BundledPatches/CheatVN External/Documents"))
            searchDirs.append(bundleRes.appendingPathComponent("BundledPatches/OG MENU FFTH/Documents"))
            searchDirs.append(bundleRes.appendingPathComponent("BundledPatches"))
        }
        searchDirs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore"))
        searchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN_External_Files/Documents"))
        searchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN External/Documents"))
        searchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/OG MENU FFTH/Documents"))
        searchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches"))
        searchDirs.append(URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/CheatVN_External_Files/Documents"))
        searchDirs.append(URL(fileURLWithPath: "ThreeOneOSFive/AppCore"))
        searchDirs.append(URL(fileURLWithPath: "D:/update_file/new1111"))
        searchDirs.append(URL(fileURLWithPath: "D:/update_file/new3"))

        var assemblyData: Data? = nil
        var configData: Data = "{\"testCodePatch\":true,\"resetGuest\":true}\n".data(using: .utf8)!
        var liveData: Data? = nil
        var neutralData: Data? = nil
        var runtimeData: Data? = nil

        for dir in searchDirs {
            let p1 = dir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let p2 = dir.appendingPathComponent("Documents/Assembly-CSharp-patch.bytes")
            if assemblyData == nil {
                if fileManager.fileExists(atPath: p1.path), let d = try? Data(contentsOf: p1) { assemblyData = d }
                else if fileManager.fileExists(atPath: p2.path), let d = try? Data(contentsOf: p2) { assemblyData = d }
            }

            let c1 = dir.appendingPathComponent("localConfig.json")
            let c2 = dir.appendingPathComponent("Documents/localConfig.json")
            if fileManager.fileExists(atPath: c1.path), let d = try? Data(contentsOf: c1) { configData = d }
            else if fileManager.fileExists(atPath: c2.path), let d = try? Data(contentsOf: c2) { configData = d }

            let l1 = dir.appendingPathComponent(".ffxc_live")
            let l2 = dir.appendingPathComponent("Documents/.ffxc_live")
            if liveData == nil {
                if fileManager.fileExists(atPath: l1.path), let d = try? Data(contentsOf: l1) { liveData = d }
                else if fileManager.fileExists(atPath: l2.path), let d = try? Data(contentsOf: l2) { liveData = d }
            }

            let n1 = dir.appendingPathComponent(".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9")
            let n2 = dir.appendingPathComponent("Documents/.ffxc_neutral_37ca851ab5df497db608f1b2f45165f9")
            if neutralData == nil {
                if fileManager.fileExists(atPath: n1.path), let d = try? Data(contentsOf: n1) { neutralData = d }
                else if fileManager.fileExists(atPath: n2.path), let d = try? Data(contentsOf: n2) { neutralData = d }
            }

            let r1 = dir.appendingPathComponent(".ffxc_runtime")
            let r2 = dir.appendingPathComponent("Documents/.ffxc_runtime")
            if runtimeData == nil {
                if fileManager.fileExists(atPath: r1.path), let d = try? Data(contentsOf: r1) { runtimeData = d }
                else if fileManager.fileExists(atPath: r2.path), let d = try? Data(contentsOf: r2) { runtimeData = d }
            }
        }

        // Dự phòng tĩnh nếu file IFix chưa tìm thấy trên đĩa:
        if liveData == nil {
            liveData = "FFXCLIVE2\n37ca851ab5df497db608f1b2f45165f9\n2\n704807167\n201775153\n120\n286c910f8c2a7798a5be7b2fc66e4f0\n".data(using: .utf8)
        }
        if neutralData == nil {
            neutralData = AntibanPatchService.neutralSeedBytes
        }
        if runtimeData == nil {
            runtimeData = "FFXC2\n37ca851ab5df497db608f1b2f45165f9\n15\n704807167\n201775153\n173d5b9b9cdded8652d2c5726b0b2740e03ad6\n".data(using: .utf8)
        }

        // Thử giải mã thêm từ envelope CheatVN External.3105 nếu assemblyData vẫn rỗng
        if assemblyData == nil {
            let envCandidates = [
                Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN External.3105"),
                Bundle.main.bundleURL.appendingPathComponent("AppCore/CheatVN External.3105"),
                (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("BundledPatches/CheatVN External.3105"),
                URL(fileURLWithPath: "D:/update_file/new1111/CheatVN External.3105")
            ]
            for envURL in envCandidates {
                if fileManager.fileExists(atPath: envURL.path),
                   let raw = try? Data(contentsOf: envURL),
                   let summary = try? PatchPackageCodec.inspect(raw) {
                    if let decoded = PatchProjectLibrary.decodePackageSafely(data: raw, summary: summary) {
                        for rule in decoded.project.rules {
                            if rule.relativePath.contains("Assembly-CSharp-patch.bytes") {
                                assemblyData = rule.replacementData
                                break
                            }
                        }
                    }
                }
                if assemblyData != nil { break }
            }
        }

        var filesMap: [String: Data] = [:]
        if let ass = assemblyData { filesMap["Assembly-CSharp-patch.bytes"] = ass }
        filesMap["localConfig.json"] = configData
        if let live = liveData { filesMap[".ffxc_live"] = live }
        if let neutral = neutralData { filesMap[".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9"] = neutral }
        if let runtime = runtimeData { filesMap[".ffxc_runtime"] = runtime }

        print("[CheatStore] 📦 Chuẩn bị ghi \(filesMap.count) file patch:")
        for (name, data) in filesMap {
            print("[CheatStore]  -> \(name): \(data.count) bytes")
        }

        // 3. Nạp trước qua 3105 Engine (nếu khả dụng)
        var appliedVia3105 = false
        var envelopeURLs: [URL] = []
        let envNames = ["CheatVN External.3105", "OG MENU FFTH.3105", "DELTAX FFTH .3105", ".core_runtime.dat"]
        if let resURL = Bundle.main.resourceURL {
            for e in envNames {
                envelopeURLs.append(resURL.appendingPathComponent("AppCore/\(e)"))
                envelopeURLs.append(resURL.appendingPathComponent("BundledPatches/\(e)"))
            }
        }
        for e in envNames {
            envelopeURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/\(e)"))
            envelopeURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/\(e)"))
        }
        envelopeURLs.append(URL(fileURLWithPath: "D:/update_file/new1111/CheatVN External.3105"))
        envelopeURLs.append(URL(fileURLWithPath: "D:/update_file/new3/CheatVN External.3105"))

        for envURL in envelopeURLs {
            guard fileManager.fileExists(atPath: envURL.path) else { continue }
            do {
                let rawData = try Data(contentsOf: envURL)
                let data = BundledPatchInjector.deobfuscateIfNeeded(rawData)
                guard data.prefix(10) == Data("3105PATCH\0".utf8) else { continue }
                let summary = try PatchPackageCodec.inspect(data)
                let decoded: DecodedPatchPackage
                if !summary.isPasswordProtected {
                    decoded = try PatchPackageCodec.decode(data, password: "")
                } else {
                    var decResult: DecodedPatchPackage? = nil
                    for pwd in ["OG", patchPassword, "1", ""] {
                        if let d = try? PatchPackageCodec.decode(data, password: pwd) { decResult = d; break }
                    }
                    guard let d = decResult else { continue }
                    decoded = d
                }
                try? PatchKeyStore.store(decoded.contentKey, for: summary)
                _ = try? DevicePatchService.apply(project: decoded.project)
                appliedVia3105 = true
                print("[CheatStore] ✅ Đã nạp thành công qua 3105 DevicePatchService: \(envURL.lastPathComponent)")
                break
            } catch {
                print("[CheatStore] Thử nạp envelope \(envURL.lastPathComponent): \(error)")
            }
        }

        // 4. Ghi TRỰC TIẾP toàn bộ 5 files vào Documents của TẤT CẢ các containers
        var writeSuccessCount = 0
        for root in targetContainerRoots {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docDir.path)

            // Dọn dẹp cache verify cũ của game để IFix nạp ngay file mới không bị chặn
            let cleanCaches = [
                "Documents/contentcache/res_version.hash",
                "Documents/contentcache/file_hash.bin",
                "Documents/contentcache/verify_cache.dat",
                "Documents/contentcache/crc_cache.bin",
                "Documents/contentcache/asset_verify.db",
                "Documents/contentcache/patch_verify.dat",
                "Documents/pending_reports"
            ]
            for cl in cleanCaches {
                let p = root.appendingPathComponent(cl)
                if fileManager.fileExists(atPath: p.path) {
                    try? fileManager.removeItem(at: p)
                }
            }

            for (fileName, data) in filesMap {
                let dst = docDir.appendingPathComponent(fileName)
                try? fileManager.removeItem(at: dst)
                var written = false
                do {
                    try data.write(to: dst)
                    written = true
                } catch {
                    let tmp = fileManager.temporaryDirectory.appendingPathComponent(fileName)
                    if (try? data.write(to: tmp)) != nil {
                        if (try? fileManager.copyItem(at: tmp, to: dst)) != nil { written = true }
                        try? fileManager.removeItem(at: tmp)
                    }
                }
                if written {
                    var u = dst
                    var resVals = URLResourceValues()
                    resVals.isExcludedFromBackup = true
                    try? u.setResourceValues(resVals)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dst.path)
                    writeSuccessCount += 1
                }
            }

            // Ghi thêm bản sao dự phòng vào Library/Application Support nếu có
            let appSupport = root.appendingPathComponent("Library/Application Support", isDirectory: true)
            if fileManager.fileExists(atPath: appSupport.path) {
                if let ass = filesMap["Assembly-CSharp-patch.bytes"] {
                    let dst = appSupport.appendingPathComponent("Assembly-CSharp-patch.bytes")
                    try? fileManager.removeItem(at: dst)
                    try? ass.write(to: dst)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dst.path)
                }
            }
        }

        // 5. Khóa cấu hình và đảm bảo localConfig luôn duy trì
        DevicePatchService.ensureActivePatchesInjected()

        let totalSuccess = writeSuccessCount > 0 || appliedVia3105
        print("[CheatStore] 🏁 Kết quả nạp CheatVN External: \(totalSuccess ? "THÀNH CÔNG" : "THẤT BẠI") (\(writeSuccessCount) files written)")
        return totalSuccess
    }

    /// Nạp file DeltaX Enternal (Hỗ trợ cả FFTH và FFMAX, Motion Blur Safe)
    @discardableResult
    private func applyDeltaXPackage() -> Bool {
        let fileManager = FileManager.default

        // 1. Kích hoạt và tìm tất cả container của Free Fire
        let targets = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
        var targetContainerRoots: [URL] = []
        for bID in targets {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bID) {
                let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
                if !targetContainerRoots.contains(url) { targetContainerRoots.append(url) }
            }
        }
        for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
            let canonical = PatchPathValidator.canonicalFileURL(root)
            if !targetContainerRoots.contains(canonical) { targetContainerRoots.append(canonical) }
        }
        if let ffPath = findFreeFireContainerPath() {
            let canonical = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: ffPath, isDirectory: true))
            if !targetContainerRoots.contains(canonical) { targetContainerRoots.append(canonical) }
        }
        for rootPath in ["/private/var/mobile/Containers/Data/Application", "/var/mobile/Containers/Data/Application"] {
            if let dirs = try? fileManager.contentsOfDirectory(atPath: rootPath) {
                for d in dirs {
                    let full = (rootPath as NSString).appendingPathComponent(d)
                    let chk1 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefireth.plist")
                    let chk2 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
                    let chk3 = (full as NSString).appendingPathComponent("Documents/contentcache")
                    if fileManager.fileExists(atPath: chk1) || fileManager.fileExists(atPath: chk2) || fileManager.fileExists(atPath: chk3) {
                        let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: full, isDirectory: true))
                        if !targetContainerRoots.contains(url) { targetContainerRoots.append(url) }
                    }
                }
            }
        }

        // 2. Quét tìm nạp file patch Assembly-CSharp-patch.bytes & localConfig.json của DeltaX Enternal
        var rawSearchDirs: [URL] = []
        if let bundleRes = Bundle.main.resourceURL {
            rawSearchDirs.append(bundleRes.appendingPathComponent("BundledPatches/DeltaX Enternal/Documents"))
            rawSearchDirs.append(bundleRes.appendingPathComponent("BundledPatches/DeltaX Enternal"))
            rawSearchDirs.append(bundleRes.appendingPathComponent("AppCore/DeltaX"))
            rawSearchDirs.append(bundleRes.appendingPathComponent("BundledPatches"))
        }
        rawSearchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/DeltaX Enternal/Documents"))
        rawSearchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/DeltaX Enternal"))
        rawSearchDirs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/DeltaX"))
        rawSearchDirs.append(URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/DeltaX Enternal/Documents"))
        rawSearchDirs.append(URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/DeltaX Enternal"))
        rawSearchDirs.append(URL(fileURLWithPath: "D:/update_file/aklo"))

        var deltaXAssembly: Data? = nil
        var deltaXConfig: Data = "{\"testCodePatch\":true,\"resetGuest\":true}\n".data(using: .utf8)!

        for dir in rawSearchDirs {
            let p1 = dir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let p2 = dir.appendingPathComponent("Documents/Assembly-CSharp-patch.bytes")
            if deltaXAssembly == nil {
                if fileManager.fileExists(atPath: p1.path), let d = try? Data(contentsOf: p1) { deltaXAssembly = d }
                else if fileManager.fileExists(atPath: p2.path), let d = try? Data(contentsOf: p2) { deltaXAssembly = d }
            }
            let c1 = dir.appendingPathComponent("localConfig.json")
            let c2 = dir.appendingPathComponent("Documents/localConfig.json")
            if fileManager.fileExists(atPath: c1.path), let d = try? Data(contentsOf: c1) { deltaXConfig = d }
            else if fileManager.fileExists(atPath: c2.path), let d = try? Data(contentsOf: c2) { deltaXConfig = d }
        }

        // 3. Nạp qua envelope 3105 DeltaX nếu có
        var candidateURLs: [URL] = []
        if let resURL = Bundle.main.resourceURL {
            candidateURLs.append(resURL.appendingPathComponent("BundledPatches/DeltaX Enternal.3105"))
            candidateURLs.append(resURL.appendingPathComponent("BundledPatches/DELTAX FFM .3105"))
            candidateURLs.append(resURL.appendingPathComponent("BundledPatches/DELTAX FFTH .3105"))
            candidateURLs.append(resURL.appendingPathComponent("AppCore/DeltaX Enternal.3105"))
            candidateURLs.append(resURL.appendingPathComponent("AppCore/.deltax_runtime.dat"))
        }
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/DeltaX Enternal.3105"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/DELTAX FFM .3105"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/DELTAX FFTH .3105"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/DeltaX Enternal.3105"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/.deltax_runtime.dat"))

        for url in candidateURLs {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            do {
                let rawData = try Data(contentsOf: url)
                let data = BundledPatchInjector.deobfuscateIfNeeded(rawData)
                guard data.prefix(10) == Data("3105PATCH\0".utf8) else { continue }
                let summary = try PatchPackageCodec.inspect(data)
                let decoded: DecodedPatchPackage
                if summary.isPasswordProtected {
                    decoded = try PatchPackageCodec.decode(data, password: "1")
                } else if let cached = PatchProjectLibrary.decodePackageSafely(data: data, summary: summary) {
                    decoded = cached
                } else {
                    decoded = try PatchPackageCodec.decode(data, password: "1")
                }
                if deltaXAssembly == nil {
                    for r in decoded.project.rules {
                        if r.relativePath.contains("Assembly-CSharp-patch.bytes") { deltaXAssembly = r.replacementData; break }
                    }
                }
                try? PatchKeyStore.store(decoded.contentKey, for: summary)
                _ = try? DevicePatchService.apply(project: decoded.project)
                break
            } catch {
                print("[CheatStore] Nạp DeltaX envelope thất bại: \(error)")
            }
        }

        // 4. Ghi trực tiếp vào toàn bộ container
        var writtenCount = 0
        if let ass = deltaXAssembly {
            for root in targetContainerRoots {
                let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docDir.path)

                let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
                let dstConfig = docDir.appendingPathComponent("localConfig.json")

                try? fileManager.removeItem(at: dstPatch)
                try? ass.write(to: dstPatch)
                var uPatch = dstPatch
                var resPatch = URLResourceValues()
                resPatch.isExcludedFromBackup = true
                try? uPatch.setResourceValues(resPatch)
                try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstPatch.path)

                try? fileManager.removeItem(at: dstConfig)
                try? deltaXConfig.write(to: dstConfig)
                var uConfig = dstConfig
                var resConfig = URLResourceValues()
                resConfig.isExcludedFromBackup = true
                try? uConfig.setResourceValues(resConfig)
                try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstConfig.path)

                writtenCount += 1
            }
        }

        DevicePatchService.ensureActivePatchesInjected()
        return writtenCount > 0
    }

    private var heroTagText: String {
        return selectedGame == "ff" ? "Free Fire (FF)" : "Free Fire MAX (FFM)"
    }

    private func applyBundledPatch(named name: String) -> Bool {
        guard let item = PatchProjectLibrary.loadBundledItem(named: name),
              let project = item.project else {
            print("[CheatStore] Không tìm thấy bundled item: \(name)")
            return false
        }
        do {
            _ = try DevicePatchService.apply(project: project)
            return true
        } catch {
            print("[CheatStore] Lỗi nạp \(name): \(error)")
            return false
        }
    }

    private func handleLaunchGame() {
        let scheme = selectedGame == "max" ? "freefiremax://" : "freefire://"
        if let url = URL(string: scheme) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else if let fallback = URL(string: selectedGame == "max" ? "freefire://" : "freefiremax://"),
                      UIApplication.shared.canOpenURL(fallback) {
                UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        DispatchQueue.main.async {
                            self.alertTitle = "⚠️ Chưa cài đặt Free Fire"
                            self.alertMessage = "Không tìm thấy game Free Fire trên thiết bị này. Vui lòng cài đặt trước!"
                            self.showAlert = true
                        }
                    }
                }
            }
        }
    }

    private func toggleAimChip(_ chip: String) {
        let coreNames: Set<String> = ["APPLE IPA V2", "SWIFT IOS", "INTERNAL MOD", "APPLESTORE PRIME"]
        if coreNames.contains(chip) {
            if selectedAimChips.contains(chip) {
                selectedAimChips.remove(chip)
            } else {
                for c in coreNames { selectedAimChips.remove(c) }
                selectedAimChips.insert(chip)
            }
        } else {
            if chip == "AIMNECK VIP" && !licenseManager.featureConfig.aimneck {
                alertTitle = "⚠️ CẢNH BÁO AN TOÀN"
                alertMessage = "Chức năng AimNeck VIP hiện đang được đánh dấu KHÔNG AN TOÀN do nguy cơ quét từ máy chủ game.\n\n👉 Quý khách vui lòng BẬT tính năng [APPLESTORE PRIME] để bảo vệ tài khoản!"
                showAlert = true
                return
            }
            if selectedAimChips.contains(chip) {
                selectedAimChips.remove(chip)
                if activeAimPatch == chip {
                    activeAimPatch = selectedAimChips.first
                }
            } else {
                selectedAimChips.insert(chip)
                activeAimPatch = chip
            }
        }
    }

    private func handleInjectAction() {
        guard !isInjecting else { return }
        isInjecting = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // Capture MainActor state before entering background thread for Swift 6 safety
        let chips = self.selectedAimChips
        let snapshotPatches = CloudPatchService.shared.cloudPatches
        let store = self.patchStore

        DispatchQueue.global(qos: .userInitiated).async {
            BundledPatchInjector.autoImportBundledPatches(into: store)
            var appliedNames: [String] = []

            for chip in chips {
                if let cp = snapshotPatches.first(where: { $0.name.caseInsensitiveCompare(chip) == .orderedSame || $0.baseName.caseInsensitiveCompare(chip) == .orderedSame }) {
                    if self.applyBundledPatch(named: cp.baseName) {
                        if !appliedNames.contains(cp.name) {
                            appliedNames.append(cp.name)
                        }
                    }
                } else {
                    let fallbackBase: String? = {
                        switch chip.uppercased() {
                        case "APPLE IPA V2": return "lib_app_apple_ipa_v2"
                        case "SWIFT IOS": return "lib_app_swift_ios"
                        case "APPLESTORE PRIME": return "lib_app_applestore_prime"
                        case "INTERNAL MOD": return "lib_app_internal"
                        case "AIM + ESP": return "lib_app_aim_esp"
                        case "AIMNECK VIP": return "lib_app_aimneck_vip"
                        case "AIM DRAG", "DRAG": return "lib_app_system"
                        default: return nil
                        }
                    }()
                    if let fb = fallbackBase, self.applyBundledPatch(named: fb) {
                        if !appliedNames.contains(chip) {
                            appliedNames.append(chip)
                        }
                    }
                }
            }

            DevicePatchService.ensureActivePatchesInjected()

            Thread.sleep(forTimeInterval: 0.6)

            DispatchQueue.main.async {
                self.isInjecting = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Toast thông báo nhanh
                let quickSummary = appliedNames.isEmpty ? "Tối ưu dữ liệu" : appliedNames.joined(separator: ", ")
                self.showToastNotification(
                    message: "✅ Inject thành công: \(quickSummary)",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )

                self.alertTitle = "✅ INJECT THÀNH CÔNG"
                let summary = appliedNames.isEmpty ? "Đã tối ưu hóa dữ liệu game!" : appliedNames.map { "• " + $0 }.joined(separator: "\n")
                self.alertMessage = "Đã nạp mod thành công vào Free Fire (\(self.selectedGame.uppercased())):\n\(summary)\n\nBấm 'Vào Game' để trải nghiệm ngay!"
                self.showAlert = true
            }
        }
    }

    // MARK: - TAB 2: Định Vị (ESP) View
    private var espView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero Status Card ESP
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Free Fire · Visual Engine V3")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(colorInk.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(999)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gói Định Vị")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text("ESP AIMHEAD V3")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.cyan)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .frame(height: 32)
                            .background(Color.white.opacity(0.1))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trạng Thái")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text(!licenseManager.featureConfig.esp ? "BẢO TRÌ" : ((selectedEspChips.contains("ESP AIMHEAD V3") || selectedEspChips.contains("AIM + ESP")) ? "ĐÃ BẬT" : "SẴN SÀNG"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(!licenseManager.featureConfig.esp ? Color.red : ((selectedEspChips.contains("ESP AIMHEAD V3") || selectedEspChips.contains("AIM + ESP")) ? Color.green : colorMute))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.45))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))

                // 1. ESP Items (.bx-section)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("MODULE ĐỊNH VỊ (VISUAL ENGINE)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2.4)
                            .foregroundColor(colorMute)
                        Spacer()
                        if cloudPatchService.isSyncing {
                            ProgressView()
                                .scaleEffect(0.65)
                        }
                    }
                    .padding(.horizontal, 4)

                    let defaultEspList = [
                        ("AIM + ESP", "Menu VIP Aimbot + Định vị xuyên tường", false),
                        ("ESP AIMHEAD V3", "Định vị xuyên tường, khoảng cách & ghim đầu", !licenseManager.featureConfig.esp)
                    ]

                    let espChips: [(String, String, Bool)] = {
                        if cloudPatchService.cloudPatches.isEmpty {
                            return defaultEspList
                        } else {
                            return cloudPatchService.patches(for: "esp").map { patch in
                                (
                                    patch.name,
                                    patch.subtitle.isEmpty ? "Định vị xuyên tường & Visual" : patch.subtitle,
                                    !patch.isActive || !licenseManager.featureConfig.esp
                                )
                            }
                        }
                    }()

                    VStack(spacing: 8) {
                        if espChips.isEmpty {
                            Text("Chưa có gói định vị nào")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colorMute)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(espChips, id: \.0) { item in
                                ZeroXChipButton(
                                    title: item.0,
                                    subtitle: item.1,
                                    isSelected: selectedEspChips.contains(item.0),
                                    isUnderMaintenance: item.2,
                                    maintenanceBadge: "BẢO TRÌ"
                                ) {
                                    if !licenseManager.featureConfig.esp || item.2 {
                                        alertTitle = "⚠️ CHỨC NĂNG ĐANG BẢO TRÌ"
                                        alertMessage = "Hệ thống Định Vị ESP hiện đang bảo trì để nâng cấp thuật toán giải phóng RAM chống văng game. Vui lòng quay lại sau!"
                                        showAlert = true
                                        return
                                    }
                                    toggleEspChip(item.0)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 2. Clean ESP Card
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedEspChips.removeAll()
                    activeEspColor = nil
                    DispatchQueue.global(qos: .userInitiated).async {
                        DevicePatchService.cleanRestoreAllModifications()
                        DispatchQueue.main.async {
                            alertTitle = "✅ ĐÃ TẮT ĐỊNH VỊ"
                            alertMessage = "Toàn bộ hiệu ứng định vị Visual đã được gỡ bỏ an toàn."
                            showAlert = true
                        }
                    }
                }) {
                    HStack(spacing: 16) {
                        Text("◈")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Clean ESP")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(colorInk)
                            Text("Xóa định vị & gỡ bỏ visuals")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colorMute)
                        }
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(colorMute.opacity(0.6))
                    }
                    .padding(16)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 3. Inject Button
                Button(action: handleInjectEspAction) {
                    HStack {
                        if isInjectingEsp {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .padding(.trailing, 6)
                        }
                        Text(isInjectingEsp ? "Đang nạp ESP..." : "Inject Định Vị")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color(white: 0.88)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.white.opacity(0.18), radius: 12, x: 0, y: 3)
                }
                .disabled(isInjectingEsp)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func toggleEspChip(_ chip: String) {
        if selectedEspChips.contains(chip) {
            selectedEspChips.remove(chip)
            if activeEspColor == chip {
                activeEspColor = selectedEspChips.first
            }
        } else {
            selectedEspChips.insert(chip)
            activeEspColor = chip
        }
    }

    private func handleInjectEspAction() {
        guard !isInjectingEsp else { return }
        isInjectingEsp = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        DispatchQueue.global(qos: .userInitiated).async {
            BundledPatchInjector.autoImportBundledPatches(into: self.patchStore)
            var appliedEspList: [String] = []
            for chip in self.selectedEspChips {
                if let cp = CloudPatchService.shared.patch(named: chip) {
                    if self.applyBundledPatch(named: cp.baseName) {
                        if !appliedEspList.contains(cp.name) {
                            appliedEspList.append(cp.name)
                        }
                    }
                } else {
                    let fallbackBase: String? = {
                        switch chip.uppercased() {
                        case "AIM + ESP": return "lib_app_aim_esp"
                        case "ESP AIMHEAD V3", "ĐỊNH VỊ V3": return "lib_app_esp_aimhead_v3"
                        default: return nil
                        }
                    }()
                    if let fb = fallbackBase, self.applyBundledPatch(named: fb) {
                        if !appliedEspList.contains(chip) {
                            appliedEspList.append(chip)
                        }
                    }
                }
            }
            let success = !appliedEspList.isEmpty || self.applyBundledPatch(named: "lib_app_esp_aimhead_v3")
            DevicePatchService.ensureActivePatchesInjected()

            Thread.sleep(forTimeInterval: 0.6)

            DispatchQueue.main.async {
                self.isInjectingEsp = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Toast thông báo nhanh cho ESP
                self.showToastNotification(
                    message: success ? "✅ Định vị ESP đã nạp thành công!" : "⚠️ Không tìm thấy gói định vị",
                    icon: success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    color: success ? Color.green : Color.orange
                )

                self.alertTitle = success ? "✅ NẠP ĐỊNH VỊ THÀNH CÔNG" : "⚠️ THÔNG BÁO"
                let espInfo = self.activeEspColor ?? "Visual ESP V3"
                self.alertMessage = success
                    ? "Đã kích hoạt định vị Visual vào Free Fire (\(self.selectedGame.uppercased())):\n• Chế độ: \(espInfo)\n• Bộ lọc: Xuyên tường & Khung xương\n\nBấm 'Vào Game' để trải nghiệm!"
                    : "Không tìm thấy gói định vị tương ứng trong hệ thống."
                self.showAlert = true
            }
        }
    }

    // MARK: - TAB 2: Hồ Sơ / Cá Nhân View
    private var profileView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. Thẻ Thông Tin Ứng Dụng & Key
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        CheatStoreLogoView(size: 48, cornerRadius: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(theme.accentColor.opacity(0.4), lineWidth: 1.2)
                            )
                            .shadow(color: theme.accentColor.opacity(0.35), radius: 8, x: 0, y: 0)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(theme.appTitle)
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundColor(colorInk)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }

                            Text("Bản quyền: \(theme.appTitle)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                        }

                        Spacer()
                    }

                    Divider().background(Color.white.opacity(0.08))

                    // Tên App
                    metaRow(label: "Tên App", value: "\(theme.appTitle) (v2.4)")

                    Divider().background(Color.white.opacity(0.08))

                    // Chủ sở hữu
                    metaRow(label: "Chủ sở hữu", value: theme.ownerName)

                    Divider().background(Color.white.opacity(0.08))

                    // Key bản quyền
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Key")
                                .font(.system(size: 14))
                                .foregroundColor(colorMute)
                            let key = licenseManager.activeKey
                            let maskedKey = key.count > 4 ? "KEY: ••••••••" + String(key.suffix(4)) : "KEY: ••••••••3105"
                            Text(maskedKey)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(colorInk)
                        }

                        Spacer()

                        Button(action: {
                            UIPasteboard.general.string = licenseManager.activeKey
                            copiedKey = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedKey = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: copiedKey ? "checkmark" : "doc.on.doc.fill")
                                    .font(.system(size: 11))
                                Text(copiedKey ? "Đã chép" : "Sao chép")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(copiedKey ? Color.green.opacity(0.35) : Color.white.opacity(0.12))
                            .cornerRadius(999)
                        }
                    }
                }
                .padding(16)
                .background(glassBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))

                // 2. Thẻ Thông Tin Thiết Bị & Hệ Thống
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("THIẾT BỊ & HỆ THỐNG")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2.4)
                            .foregroundColor(colorMute)
                            .padding(.horizontal, 4)

                        Spacer()

                        // Nút nhỏ danh sách tương thích CheatStoreVN
                        Button {
                            showCompatList = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 10))
                                Text("Danh sách tương thích")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(theme.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.accentColor.opacity(0.12))
                            .cornerRadius(999)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(theme.accentColor.opacity(0.35), lineWidth: 0.8)
                            )
                        }
                    }

                    let isDeviceCompat = ExploitSupportPolicy.isSupported(
                        major: AppInfo.versionTuple.major,
                        minor: AppInfo.versionTuple.minor,
                        patch: AppInfo.versionTuple.patch,
                        build: AppInfo.osBuild
                    )

                    VStack(spacing: 12) {
                        // Dòng Máy iPhone Thật
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dòng máy (iPhone)")
                                    .font(.system(size: 14))
                                    .foregroundColor(colorMute)
                                Text(AppInfo.hardwareDisplayName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isDeviceCompat ? Color(red: 0.20, green: 0.88, blue: 0.45) : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(isDeviceCompat ? "Tương thích" : "Không tương thích")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(isDeviceCompat ? Color(red: 0.20, green: 0.88, blue: 0.45) : Color.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background((isDeviceCompat ? Color.green : Color.red).opacity(0.12))
                            .cornerRadius(8)
                        }

                        Divider().background(Color.white.opacity(0.08))

                        // Tên Thiết Bị
                        metaRow(label: "Tên Thiết Bị", value: UIDevice.current.name)

                        Divider().background(Color.white.opacity(0.08))

                        // Hệ điều hành ios
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hệ điều hành iOS")
                                    .font(.system(size: 14))
                                    .foregroundColor(colorMute)
                                Text("iOS " + UIDevice.current.systemVersion + " (\(AppInfo.osBuild))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(colorInk)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: isDeviceCompat ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(isDeviceCompat ? "Được hỗ trợ" : "Chưa hỗ trợ")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(isDeviceCompat ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((isDeviceCompat ? Color.green : Color.red).opacity(0.1))
                            .cornerRadius(6)
                        }

                        Divider().background(Color.white.opacity(0.08))

                        // Mã phần cứng
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mã phần cứng")
                                    .font(.system(size: 14))
                                    .foregroundColor(colorMute)
                                let hwid = UIDevice.current.identifierForVendor?.uuidString ?? "VN-3105-PRO"
                                Text(String(hwid.prefix(16)) + "...")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(colorInk.opacity(0.85))
                            }

                            Spacer()

                            Button(action: {
                                UIPasteboard.general.string = UIDevice.current.identifierForVendor?.uuidString ?? "VN-3105-PRO"
                                copiedHWID = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedHWID = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedHWID ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 10))
                                    Text(copiedHWID ? "Đã chép" : "Chép")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(16)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 3. Tùy Chỉnh Tiếng Việt - Tiếng Anh
                VStack(alignment: .leading, spacing: 10) {
                    Text("TUỲ CHỈNH NGÔN NGỮ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    HStack {
                        Text("Ngôn ngữ giao diện")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorInk)

                        Spacer()

                        HStack(spacing: 4) {
                            Button(action: {
                                selectedLanguage = "Tiếng Việt"
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text("Tiếng Việt")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(selectedLanguage == "Tiếng Việt" ? .black : colorMute)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedLanguage == "Tiếng Việt" ? Color.white : Color.clear)
                                    .cornerRadius(10)
                            }

                            Button(action: {
                                selectedLanguage = "English"
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text("English")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(selectedLanguage == "English" ? .black : colorMute)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedLanguage == "English" ? Color.white : Color.clear)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                    }
                    .padding(14)
                    .background(glassBg)
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(glassBorder, lineWidth: 1))
                }

                // 4. Nút Liên Hệ ZL: 0365829172
                Button(action: {
                    if let url = URL(string: "https://zalo.me/0365829172") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.cyan)
                            .frame(width: 38, height: 38)
                            .background(Color.cyan.opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Liên hệ Zalo: 0365829172")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(colorInk)
                            Text("Chủ sở hữu: \(theme.ownerName)")
                                .font(.system(size: 11))
                                .foregroundColor(colorMute)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.cyan)
                    }
                    .padding(14)
                    .background(glassBg)
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                }

                // 5. Nút Đăng Xuất
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    licenseManager.deactivate()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .bold))
                        Text("Đăng Xuất")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 1))
                }
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func statusRow(icon: String, iconColor: Color, title: String, subtitle: String, status: String, statusColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(colorInk)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(colorMute)
            }

            Spacer()

            Text(status)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12))
                .cornerRadius(6)
        }
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(colorMute)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(colorInk)
        }
    }

    // MARK: - Reusable UI Components
    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? colorInk : colorMute)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.white.opacity(0.16) : Color.clear)
                .cornerRadius(999)
        }
    }

    // MARK: - Toast Notification Helper
    private func showToastNotification(message: String, icon: String = "checkmark.circle.fill", color: Color = Color.green) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showToast = true
        }
        // Tự ẩn toast sau 3.5 giây
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
            }
        }
    }

    // MARK: - Đổi Game với Auto-Restore
    private func handleBackToGames(_ callback: @escaping () -> Void) {
        // Kiểm tra xem có mod nào đang active không
        let hasActiveMods = !selectedAimChips.isEmpty || !selectedEspChips.isEmpty

        if hasActiveMods {
            // Có mod active → hiện loading overlay, khôi phục, rồi đổi game
            withAnimation(.easeInOut(duration: 0.2)) {
                isRestoringForGameSwitch = true
            }

            DispatchQueue.global(qos: .userInitiated).async {
                DevicePatchService.cleanRestoreAllModifications()

                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.activeAimPatch = nil
                        self.activeEspColor = nil
                        self.selectedAimChips.removeAll()
                        self.selectedEspChips.removeAll()
                        self.isRestoringForGameSwitch = false
                    }

                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.showToastNotification(
                        message: "Đã khôi phục dữ liệu gốc. Đang chuyển game...",
                        icon: "arrow.triangle.2.circlepath",
                        color: Color.cyan
                    )

                    // Delay nhẹ để toast hiện trước khi chuyển
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        callback()
                    }
                }
            }
        } else {
            // Không có mod active → chuyển game luôn
            callback()
        }
    }

    // MARK: - Ledger Restore Cleanup Action (Hiện Loading Chi Tiết Cho Khách Thấy Rõ)
    func performCleanRestore() {
        guard !isRestoringClean else { return }
        isRestoringClean = true
        restoreProgressValue = 0.05
        restoreCurrentStepTitle = "Khởi tạo quy trình khôi phục an toàn 100%..."
        restoreCompletedSteps.removeAll()
        isRestoreFinished = false
        withAnimation(.easeInOut(duration: 0.25)) {
            showRestoreProgressModal = true
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.global(qos: .userInitiated).async {
            _ = DevicePatchService.cleanRestoreWithProgress { stepIndex, stepTitle, progress in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.restoreProgressValue = progress
                        self.restoreCurrentStepTitle = stepTitle
                        if !self.restoreCompletedSteps.contains(stepTitle) {
                            self.restoreCompletedSteps.append(stepTitle)
                        }
                    }
                }
            }

            self.antibanPatchService.stopAntiBan()

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.isInjected = false
                    self.activeAimPatch = nil
                    self.activeEspColor = nil
                    self.selectedAimChips.removeAll()
                    self.selectedEspChips.removeAll()
                    self.isRestoringClean = false
                    self.isRestoreFinished = true
                    self.restoreProgressValue = 1.0
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Hiện toast thành công
                self.showToastNotification(
                    message: "✅ Đã khôi phục sạch 100% dữ liệu game!",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )
            }
        }
    }

    // MARK: - Dashboard Footer View (Hiện Tên Máy + iOS + Có hỗ trợ hay không, to lên 10%)
    private var dashboardDeviceFooterView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(colorInk.opacity(0.9))
                Text(AppInfo.hardwareDisplayName)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(colorInk)
            }

            Text("•")
                .foregroundColor(colorMute.opacity(0.5))

            Text("iOS \(UIDevice.current.systemVersion)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(colorMute)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                    .frame(width: 7, height: 7)
                    .shadow(color: Color.green.opacity(0.8), radius: 3)
                Text("ĐƯỢC HỖ TRỢ")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Color.green.opacity(0.12))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.28), lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

// MARK: - Extension Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Scale Button Style
private struct ZeroXScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - React Bits Ferrofluid WebGL Background
struct FerrofluidBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isUserInteractionEnabled = false

        webView.loadHTMLString(FerrofluidShaderSource.html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

private enum FerrofluidShaderSource {
    static let html: String = #"""
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: 100%; height: 100%; overflow: hidden; background: transparent; }
canvas { display: block; width: 100%; height: 100%; pointer-events: none; }
</style>
</head>
<body>
<canvas id="glcanvas"></canvas>
<script>
(function() {
  const canvas = document.getElementById('glcanvas');
  const gl = canvas.getContext('webgl', { alpha: true, antialias: false, powerPreference: 'high-performance' });
  if (!gl) return;

  const vsSource = `
    attribute vec2 position;
    varying vec2 vUv;
    void main() {
      vUv = (position + 1.0) * 0.5;
      gl_Position = vec4(position, 0.0, 1.0);
    }
  `;

  const fsSource = `
    precision highp float;
    uniform vec3  iResolution;
    uniform vec2  iMouse;
    uniform float iTime;

    uniform vec3  uColor0;
    uniform vec3  uColor1;
    uniform vec3  uColor2;

    uniform vec2  uFlow;
    uniform float uSpeed;
    uniform float uScale;
    uniform float uTurbulence;
    uniform float uFluidity;
    uniform float uRimWidth;
    uniform float uSharpness;
    uniform float uShimmer;
    uniform float uGlow;
    uniform float uOpacity;
    uniform float uMouseEnabled;
    uniform float uMouseStrength;
    uniform float uMouseRadius;

    varying vec2 vUv;

    #define PI 3.14159265

    vec3 palette(float h) {
      if (h < 0.5) return mix(uColor0, uColor1, h * 2.0);
      return mix(uColor1, uColor2, (h - 0.5) * 2.0);
    }

    float hash(vec3 p3) {
      p3 = fract(p3 * 0.1031);
      p3 += dot(p3, p3.zyx + 33.33);
      return fract((p3.x + p3.y) * p3.z);
    }

    float smin(float a, float b, float k) {
      float r = exp2(-a / k) + exp2(-b / k);
      return -k * log2(r);
    }

    float sinlerp(float a, float b, float w) {
      return mix(a, b, (sin(w * PI - PI / 2.0) + 1.0) / 2.0);
    }

    float vn(vec2 p, float s, float seed) {
      vec2 cellp = floor(p / s);
      vec2 relp = mod(p, s);
      float g1 = hash(vec3(cellp, seed));
      float g2 = hash(vec3(cellp.x + 1.0, cellp.y, seed));
      float g3 = hash(vec3(cellp.x + 1.0, cellp.y + 1.0, seed));
      float g4 = hash(vec3(cellp.x, cellp.y + 1.0, seed));
      float bx = sinlerp(g1, g2, relp.x / s);
      float tx = sinlerp(g4, g3, relp.x / s);
      return sinlerp(bx, tx, relp.y / s);
    }

    float dbn(vec2 p, float s, float seed) {
      float o = s / 2.0;
      float n0 = vn(p, s, seed);
      float n1 = vn(p + vec2(o, o), s, seed + 0.1);
      float n2 = vn(p + vec2(-o, o), s, seed + 0.2);
      float n3 = vn(p + vec2(o, -o), s, seed + 0.3);
      float n4 = vn(p + vec2(-o, -o), s, seed + 0.4);
      return (2.0 * n0 + 1.5 * n1 + 1.25 * n2 + 1.125 * n3 + n4) / 7.0;
    }

    void main() {
      vec2 fragCoord = vUv * iResolution.xy;
      float ref = 700.0 / max(uScale, 0.05);
      vec2 p = fragCoord / iResolution.y * ref;

      float spd = 200.0 * uSpeed;
      float t = iTime;

      vec2 dir = uFlow;
      vec2 perp = vec2(-dir.y, dir.x);

      float distort1 = vn(p + perp * (t * spd), 60.0, 10.0) * 50.0 * uTurbulence;
      float distort2 = vn(p - perp * (t * spd), 120.0, 15.0) * 100.0 * uTurbulence;

      float peaks = dbn(p + distort1 + dir * (t * spd * 0.5), 40.0, 1.0);
      float peaks2 = dbn(p + distort2 - dir * (t * spd * 0.5), 40.0, 0.0);

      float mapeaks = smin(peaks, peaks2, max(uFluidity, 0.001));

      float mGlow = 0.0;
      if (uMouseEnabled > 0.5) {
        vec2 mp = iMouse / iResolution.y * ref;
        float md = length(p - mp) / ref;
        float rr = max(uMouseRadius, 0.02);
        mGlow = exp(-md * md / (rr * rr)) * uMouseStrength;
      }

      float band = (uRimWidth - abs((mapeaks - 0.4) * 2.0)) * 5.0;
      float ltn = clamp(band - vn(p + dir * (t * spd * 0.5), 60.0, 12.0) * uShimmer, 0.0, 1.0);
      ltn = pow(max(ltn, 0.0001), uSharpness) * uGlow;
      ltn *= clamp(1.0 - mGlow, 0.0, 1.0);

      float h = clamp(0.5 + (peaks - peaks2) * 0.8, 0.0, 1.0);
      vec3 col = palette(h);

      vec3 outc = col * ltn;
      float a = clamp(max(outc.r, max(outc.g, outc.b)), 0.0, 1.0);
      gl_FragColor = vec4(outc, a * uOpacity);
    }
  `;

  function createShader(gl, type, source) {
    const s = gl.createShader(type);
    gl.shaderSource(s, source);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      console.error(gl.getShaderInfoLog(s));
      gl.deleteShader(s);
      return null;
    }
    return s;
  }

  const vs = createShader(gl, gl.VERTEX_SHADER, vsSource);
  const fs = createShader(gl, gl.FRAGMENT_SHADER, fsSource);
  const prog = gl.createProgram();
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);

  const posBuf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, posBuf);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);

  const posLoc = gl.getAttribLocation(prog, 'position');
  gl.enableVertexAttribArray(posLoc);
  gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0);

  gl.useProgram(prog);

  // Exact React Bits parameters:
  // Colors: #f20606, #de0606, #f07777
  gl.uniform3f(gl.getUniformLocation(prog, 'uColor0'), 0.949, 0.024, 0.024);
  gl.uniform3f(gl.getUniformLocation(prog, 'uColor1'), 0.871, 0.024, 0.024);
  gl.uniform3f(gl.getUniformLocation(prog, 'uColor2'), 0.941, 0.467, 0.467);
  gl.uniform2f(gl.getUniformLocation(prog, 'uFlow'), 0.0, -1.0);
  gl.uniform1f(gl.getUniformLocation(prog, 'uSpeed'), 0.50);
  gl.uniform1f(gl.getUniformLocation(prog, 'uScale'), 1.60);
  gl.uniform1f(gl.getUniformLocation(prog, 'uTurbulence'), 1.00);
  gl.uniform1f(gl.getUniformLocation(prog, 'uFluidity'), 0.10);
  gl.uniform1f(gl.getUniformLocation(prog, 'uRimWidth'), 0.20);
  gl.uniform1f(gl.getUniformLocation(prog, 'uSharpness'), 2.50);
  gl.uniform1f(gl.getUniformLocation(prog, 'uShimmer'), 1.50);
  gl.uniform1f(gl.getUniformLocation(prog, 'uGlow'), 2.0);
  gl.uniform1f(gl.getUniformLocation(prog, 'uOpacity'), 0.88);
  gl.uniform1f(gl.getUniformLocation(prog, 'uMouseEnabled'), 1.0);
  gl.uniform1f(gl.getUniformLocation(prog, 'uMouseStrength'), 1.0);
  gl.uniform1f(gl.getUniformLocation(prog, 'uMouseRadius'), 0.35);

  const uResLoc = gl.getUniformLocation(prog, 'iResolution');
  const uTimeLoc = gl.getUniformLocation(prog, 'iTime');
  const uMouseLoc = gl.getUniformLocation(prog, 'iMouse');

  function resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const w = window.innerWidth || 375;
    const h = window.innerHeight || 812;
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.uniform3f(uResLoc, canvas.width, canvas.height, 1.0);
  }
  window.addEventListener('resize', resize);
  resize();

  let start = performance.now();
  function render() {
    const t = (performance.now() - start) * 0.001;
    gl.uniform1f(uTimeLoc, t);
    
    // Gentle autonomous drifting motion
    const angle = t * 0.6;
    const mx = (0.5 + Math.sin(angle) * 0.25) * canvas.width;
    const my = (0.5 + Math.cos(angle * 1.2) * 0.25) * canvas.height;
    gl.uniform2f(uMouseLoc, mx, my);

    gl.drawArrays(gl.TRIANGLES, 0, 3);
    requestAnimationFrame(render);
  }
  requestAnimationFrame(render);
})();
</script>
</body>
</html>
"""#
}

// MARK: - Original 3105 Workspace View (Tích hợp All-in-One giải quyết bài toán dùng chung)
struct Original3105WorkspaceView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            // Thanh điều hướng trên cùng với nút quay lại CheatStore
            HStack(spacing: 12) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text("CheatStore")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.0, green: 0.90, blue: 0.46))
                    Text("3105 v2.0 (Gốc)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color(red: 18/255, green: 18/255, blue: 24/255))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .bottom
            )

            ContentView()
                .environmentObject(patchDraftCoordinator)
                .environmentObject(patchStore)
                .environmentObject(repositoryStore)
                .environmentObject(appState)
                .environmentObject(fileOperationCoordinator)
                .environment(\.appLanguage, language)
                .environment(\.locale, language.locale)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
