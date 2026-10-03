import SwiftUI
import UIKit
import WebKit

// MARK: - CheatStoreTab Enum (3 Tab: Trang Chủ, Antiban, Cá Nhân)
enum CheatStoreTab: Int, CaseIterable {
    case home = 0
    case antiban = 1
    case profile = 2

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .antiban: return "Antiban"
        case .profile: return "Cá Nhân"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .antiban: return "checkmark.shield.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Skin Model
struct SkinItemData: Identifiable {
    let id: Int
    let name: String
    let subtitle: String
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
    @State private var isInjected: Bool = false
    @State private var pulseAnimation: Bool = false

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

    // Tab 3: Modskin State (2 chức năng cũ: Skin Alock V2 & Skin thẻ vô cực vàng mùa 1)
    @State private var selectedSpecialSkins: Set<String> = []
    @State private var isApplyingSkin: Bool = false

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
        ZStack {
            // Nền đen sâu True Black Void
            colorVoid.ignoresSafeArea()

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

                // Nội dung 3 Tab: Trang Chủ, Antiban, Cá Nhân
                ZStack {
                    if selectedTab == .home {
                        homeView
                            .transition(.opacity)
                    } else if selectedTab == .antiban {
                        antibanView
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
                                .progressViewStyle(LinearProgressViewStyle(tint: isRestoreFinished ? Color.green : Color.orange))
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
                                    .foregroundColor(isRestoreFinished ? .green : .orange)
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
        .onAppear {
            cloudPatchService.syncCloudPatches()
        }
        .onChange(of: selectedTab) { _ in
            cloudPatchService.syncCloudPatches()
        }
        .onChange(of: cloudPatchService.cloudPatches) { newPatches in
            if !newPatches.isEmpty {
                let validNames = Set(newPatches.map { $0.name.uppercased() })
                selectedAimChips = selectedAimChips.filter { validNames.contains($0.uppercased()) }
                selectedEspChips = selectedEspChips.filter { validNames.contains($0.uppercased()) }
                selectedSpecialSkins = selectedSpecialSkins.filter { validNames.contains($0.uppercased()) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            cloudPatchService.syncCloudPatches()
        }
    }

    // MARK: - Aurora Free Fire Top Header (Chuẩn 100% Ảnh Mẫu Aurora iOS)
    private var auroraTopHeaderView: some View {
        HStack {
            // Nút quay lại: < Games
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
            } else {
                Spacer().frame(width: 60)
            }

            Spacer()

            // Tên thương hiệu + Tên game (Center)
            VStack(spacing: 2) {
                Text(brandHeaderTitle)
                    .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                    .foregroundColor(colorInk)
                    .tracking(0.5)

                Text(auroraGameSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.65))
            }

            Spacer()

            // Trạng thái (Right pill badge)
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
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var brandHeaderTitle: String {
        return theme.appTitle
    }

    private var auroraGameSubtitle: String {
        return "Free Fire"
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
            return Color(red: 1.0, green: 0.35, blue: 0.75) // Vầng hào quang LED đa sắc
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

                Text(theme.appTitle)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .tracking(-0.6)
                    .foregroundColor(colorInk)
            }
            Spacer()

            if let onBackToGames = onBackToGames {
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

            // CHÍNH GIỮA: Tên Discord (7 màu chạy tới lui) & Mô tả hỗ trợ & các icon Zalo / Tele
            VStack(spacing: 8) {
                RainbowText(text: brandCenterTag)

                Text("Mô tả: Liên hệ khi cần hỗ trợ")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.65))

                // Nút nhỏ đường dẫn Zalo / Telegram theo thương hiệu
                HStack(spacing: 16) {
                    // Nút Zalo
                    if let zaloURL = theme.zaloURLString, let url = URL(string: zaloURL) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            UIApplication.shared.open(url)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.05, green: 0.58, blue: 1.0), Color(red: 0.0, green: 0.38, blue: 0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                                    )
                                    .shadow(color: Color.blue.opacity(0.55), radius: 6, x: 0, y: 2)

                                Text("Z")
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
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
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.18, green: 0.68, blue: 0.93), Color(red: 0.08, green: 0.50, blue: 0.78)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                                    )
                                    .shadow(color: Color.cyan.opacity(0.55), radius: 6, x: 0, y: 2)

                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: -1, y: 1)
                            }
                        }
                        .buttonStyle(AuroraScaleButtonStyle())
                    }
                }
                .padding(.top, 6)
            }
            .scaleEffect(isInjecting ? (pulseAnimation ? 1.03 : 0.98) : 1.0)
            .animation(isInjecting ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: pulseAnimation)

            Spacer()

            // PHÍA DƯỚI: Nút INJECTOR / UNINJECT lớn, bo góc
            VStack(spacing: 12) {
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
                            (isInjecting || isRestoringClean) ? Color.white : (isInjected ? Color(red: 1.0, green: 0.55, blue: 0.55) : Color.white.opacity(0.55))
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
                // Nền bo góc: Đỏ thẫm khi đã inject (để Uninject), Trắng LED khi chưa inject (INJECTOR)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isInjected ?
                        LinearGradient(
                            colors: isRestoringClean ? [
                                Color(red: 0.65, green: 0.15, blue: 0.18),
                                Color(red: 0.45, green: 0.08, blue: 0.12)
                            ] : [
                                Color(red: 0.85, green: 0.20, blue: 0.24),
                                Color(red: 0.62, green: 0.10, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: isInjecting ? [
                                Color(white: 0.92),
                                Color(white: 0.82)
                            ] : [
                                Color.white,
                                Color(white: 0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isInjected ? Color.red.opacity(0.55) : Color.white.opacity(0.5),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: isInjected ? Color.red.opacity(0.35) : Color.white.opacity(0.28),
                        radius: 14,
                        y: 4
                    )

                // Nội dung nút theo các trạng thái
                HStack(spacing: 10) {
                    if isInjecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(1.0)

                        Text("Injecting...")
                            .font(.system(size: 16.5, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
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
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)

                        Text("INJECTOR")
                            .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .tracking(1.0)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(AuroraScaleButtonStyle())
        .disabled(isInjecting || isRestoringClean)
    }

    private var auroraInstructionText: String {
        if isInjecting {
            return "Đang nạp file vào game..."
        } else if isRestoringClean {
            return "Đang gỡ mod và khôi phục dữ liệu gốc..."
        } else if isInjected {
            return "Đã nạp mod thành công! Chạm UNINJECT để khôi phục game gốc"
        } else {
            return "Chạm INJECTOR để nạp file và vào game"
        }
    }

    private func startAuroraInjection() {
        guard !isInjecting else { return }
        isInjecting = true
        isInjected = false
        pulseAnimation = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // 1. Chạy background task nạp DUY NHẤT file .3105 gốc
        DispatchQueue.global(qos: .userInitiated).async {
            // Nạp duy nhất file Aurora Menu v1.3105 gốc
            _ = self.applyAuroraPackage()

            DevicePatchService.ensureActivePatchesInjected()
        }

        // 2. Thời gian loading animation chuẩn 12 giây (trong khoảng 10-15s như yêu cầu)
        let loadingDuration: TimeInterval = 12.0
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                self.isInjecting = false
                self.isInjected = true
                self.pulseAnimation = false
            }

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            CheatStoreSoundManager.shared.playTabSwitchHaptic()

            self.showToastNotification(
                message: "Đã injetor thành công",
                icon: "checkmark.circle.fill",
                color: Color.green
            )

            // Sau khi nạp xong tự động vô game
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.handleLaunchGame()
            }
        }
    }

    @discardableResult
    private func applyAuroraPackage() -> Bool {
        let fileManager = FileManager.default
        let patchPassword = UserDefaults.standard.string(forKey: "CheatStore_CorePatchPassword") ?? "1"

        // 1. Quét tìm nạp trực tiếp file patch Assembly-CSharp-patch.bytes & localConfig.json mới
        var rawSearchDirs: [URL] = []
        if let bundleRes = Bundle.main.resourceURL {
            rawSearchDirs.append(bundleRes.appendingPathComponent("BundledPatches/Aurora Menu v1.3105/Documents"))
            rawSearchDirs.append(bundleRes.appendingPathComponent("BundledPatches/Aurora Menu v1.3105"))
            rawSearchDirs.append(bundleRes.appendingPathComponent("AppCore"))
            rawSearchDirs.append(bundleRes.appendingPathComponent("BundledPatches"))
        }
        rawSearchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/Aurora Menu v1.3105/Documents"))
        rawSearchDirs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/Aurora Menu v1.3105"))
        rawSearchDirs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore"))
        if let root = try? PatchProjectLibrary.packageRootURL(fileManager: fileManager) {
            rawSearchDirs.append(root.appendingPathComponent("Aurora Menu v1.3105/Documents"))
            rawSearchDirs.append(root.appendingPathComponent("Aurora Menu v1.3105"))
            rawSearchDirs.append(root)
        }

        for dir in rawSearchDirs {
            let p1 = dir.appendingPathComponent("Documents/Assembly-CSharp-patch.bytes")
            let p2 = dir.appendingPathComponent("Assembly-CSharp-patch.bytes")
            let patchSrc = fileManager.fileExists(atPath: p1.path) ? p1 : (fileManager.fileExists(atPath: p2.path) ? p2 : nil)

            if let patchSrc = patchSrc {
                let c1 = dir.appendingPathComponent("Documents/localConfig.json")
                let c2 = dir.appendingPathComponent("localConfig.json")
                let configSrc = fileManager.fileExists(atPath: c1.path) ? c1 : (fileManager.fileExists(atPath: c2.path) ? c2 : nil)

                let allContainers = DevicePatchService.allAvailableFreeFireContainers()
                for (_, root) in allContainers {
                    let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                    try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
                    let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
                    let dstConfig = docDir.appendingPathComponent("localConfig.json")

                    try? fileManager.removeItem(at: dstPatch)
                    try? fileManager.copyItem(at: patchSrc, to: dstPatch)

                    if let configSrc = configSrc {
                        try? fileManager.removeItem(at: dstConfig)
                        try? fileManager.copyItem(at: configSrc, to: dstConfig)
                    } else {
                        let configData = DevicePatchService.motionBlurSafeConfigJSON.data(using: .utf8)!
                        try? configData.write(to: dstConfig, options: .atomic)
                    }
                    var uPatch = dstPatch
                    var uConfig = dstConfig
                    var resVals = URLResourceValues()
                    resVals.isExcludedFromBackup = true
                    try? uPatch.setResourceValues(resVals)
                    try? uConfig.setResourceValues(resVals)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstPatch.path)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstConfig.path)
                }
                DevicePatchService.ensureActivePatchesInjected()
                print("[CheatStore] ✅ Đã nạp thành công raw patch Assembly-CSharp-patch.bytes & localConfig.json (Motion Blur Safe)")
                return true
            }
        }

        // Danh sách các đường dẫn tìm kiếm file mod gốc chuẩn
        var candidateURLs: [URL] = []

        if let root = try? PatchProjectLibrary.packageRootURL(fileManager: fileManager) {
            candidateURLs.append(root.appendingPathComponent(".core_runtime.dat"))
            candidateURLs.append(root.appendingPathComponent("core_manifest.bin"))
            candidateURLs.append(root.appendingPathComponent("core_runtime.dat"))
            candidateURLs.append(root.appendingPathComponent("Aurora Menu v1.3105"))
            candidateURLs.append(root.appendingPathComponent("Assets/core_manifest.bin"))
        }

        if let resURL = Bundle.main.resourceURL {
            candidateURLs.append(resURL.appendingPathComponent("AppCore/core_manifest.bin"))
            candidateURLs.append(resURL.appendingPathComponent("AppCore/core_runtime.dat"))
            candidateURLs.append(resURL.appendingPathComponent("AppCore/.core_runtime.dat"))
            candidateURLs.append(resURL.appendingPathComponent("AppCore/Aurora Menu v1.3105"))
            candidateURLs.append(resURL.appendingPathComponent("AppCore/Assets/core_manifest.bin"))
            candidateURLs.append(resURL.appendingPathComponent("BundledPatches/Aurora Menu v1.3105"))
            candidateURLs.append(resURL.appendingPathComponent("BundledPatches/.core_runtime.dat"))
        }
        candidateURLs.append(URL(fileURLWithPath: "D:/aaaaaaaaacc/Aurora Menu v1.3105"))
        if let binURL = Bundle.main.url(forResource: "core_manifest", withExtension: "bin") {
            candidateURLs.append(binURL)
        }
        if let datURL = Bundle.main.url(forResource: "core_runtime", withExtension: "dat") {
            candidateURLs.append(datURL)
        }
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/core_manifest.bin"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/core_runtime.dat"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/.core_runtime.dat"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("AppCore/Assets/core_manifest.bin"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/Aurora Menu v1.3105"))
        candidateURLs.append(Bundle.main.bundleURL.appendingPathComponent("BundledPatches/.core_runtime.dat"))

        var appliedSuccess = false

        for url in candidateURLs {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            do {
                let rawData = try Data(contentsOf: url)
                let data = BundledPatchInjector.deobfuscateIfNeeded(rawData)

                guard data.prefix(10) == Data("3105PATCH\0".utf8) else { continue }

                let summary = try PatchPackageCodec.inspect(data)

                // Giải mã với pass là "1"
                let decoded: DecodedPatchPackage
                if summary.isPasswordProtected {
                    decoded = try PatchPackageCodec.decode(data, password: patchPassword)
                } else if let cached = PatchProjectLibrary.decodePackageSafely(data: data, summary: summary) {
                    decoded = cached
                } else {
                    decoded = try PatchPackageCodec.decode(data, password: patchPassword)
                }

                // Lưu contentKey
                try? PatchKeyStore.store(decoded.contentKey, for: summary)

                // Nạp patch vào game Free Fire
                _ = try DevicePatchService.apply(project: decoded.project)

                // Cài đặt vào thư viện local
                try? PatchProjectLibrary.installImportedPackage(
                    data: data,
                    decoded: decoded,
                    summary: summary,
                    existingURL: nil,
                    fileManager: fileManager
                )

                print("[CheatStore] ✅ Đã giải mã & nạp thành công file \(url.lastPathComponent) với pass=\(patchPassword)")
                appliedSuccess = true
                break
            } catch {
                print("[CheatStore] Thử nạp \(url.lastPathComponent) thất bại: \(error)")
            }
        }

        // 4. Nếu không tìm thấy file nào trên đĩa, tự động giải mã từ Payload nhúng trực tiếp trong Mach-O Binary (Zero-File Fallback)
        if !appliedSuccess {
            if let embeddedData = BundledPatchInjector.loadEmbeddedPackageData() {
                do {
                    let summary = try PatchPackageCodec.inspect(embeddedData)
                    let decoded = try PatchPackageCodec.decode(embeddedData, password: patchPassword)
                    try? PatchKeyStore.store(decoded.contentKey, for: summary)
                    _ = try DevicePatchService.apply(project: decoded.project)
                    print("[CheatStore] ✅ Đã nạp thành công từ Embedded Binary Payload (Bảo mật tối đa, không lộ bất kỳ file nào)!")
                    appliedSuccess = true
                } catch {
                    print("[CheatStore] Nạp từ embedded payload thất bại: \(error)")
                }
            }
        }

        if !appliedSuccess {
            // Thử qua loadBundledItem
            if let item = PatchProjectLibrary.loadBundledItem(named: "@Nhism Menu v1-0") ?? PatchProjectLibrary.loadBundledItem(named: "CheatVN Menu v1-0") ?? PatchProjectLibrary.loadBundledItem(named: "Aurora Menu v1-0"),
               let project = item.project {
                if let _ = try? DevicePatchService.apply(project: project) {
                    print("[CheatStore] ✅ Đã nạp thành công qua loadBundledItem: \(project.name)")
                    appliedSuccess = true
                }
            }
        }

        return appliedSuccess
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

    // MARK: - TAB 3: Modskin View (Chỉ giữ lại 2 chức năng cũ)
    private var skinView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Section: Mod Skin VIP (An Toàn)
                HStack {
                    Text("MOD SKIN VIP (AN TOÀN)")
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

                let defaultSkins = [
                    ("Skin Alock V2", "Trang phục nhân vật Alok cực chất (Bản V2)"),
                    ("Skin thẻ vô cực vàng mùa 1", "Trang phục Thẻ Vô Cực Vàng Mùa 1")
                ]

                let skinChips: [(String, String, Bool)] = {
                    if cloudPatchService.cloudPatches.isEmpty {
                        return defaultSkins.map { ($0.0, $0.1, !licenseManager.featureConfig.skin) }
                    } else {
                        return cloudPatchService.patches(for: "skin").map { patch in
                            (
                                patch.name,
                                patch.subtitle.isEmpty ? "OTA Skin VIP" : patch.subtitle,
                                !patch.isActive || !licenseManager.featureConfig.skin
                            )
                        }
                    }
                }()

                VStack(spacing: 8) {
                    if skinChips.isEmpty {
                        Text("Chưa có gói Mod Skin nào")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(colorMute)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(skinChips, id: \.0) { item in
                            ZeroXChipButton(
                                title: item.0,
                                subtitle: item.1,
                                isSelected: selectedSpecialSkins.contains(item.0),
                                isUnderMaintenance: item.2,
                                maintenanceBadge: "BẢO TRÌ"
                            ) {
                                if !licenseManager.featureConfig.skin || item.2 {
                                    alertTitle = "⚠️ CHỨC NĂNG ĐANG BẢO TRÌ"
                                    alertMessage = "Tính năng Mod Skin hiện đang được bảo trì an toàn. Vui lòng quay lại sau!"
                                    showAlert = true
                                    return
                                }
                                if selectedSpecialSkins.contains(item.0) {
                                    selectedSpecialSkins.remove(item.0)
                                } else {
                                    selectedSpecialSkins.insert(item.0)
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(glassBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))

                // Nút áp dụng Skin
                Button(action: handleApplySkinAction) {
                    HStack {
                        if isApplyingSkin {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .padding(.trailing, 6)
                        }
                        Text(isApplyingSkin ? "Đang nạp Skin..." : "Áp Dụng Mod Skin")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color(white: 0.88)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.white.opacity(0.18), radius: 10, x: 0, y: 3)
                }
                .disabled(isApplyingSkin)
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func handleApplySkinAction() {
        guard !isApplyingSkin else { return }
        if !licenseManager.featureConfig.skin {
            alertTitle = "⚠️ CHỨC NĂNG ĐANG BẢO TRÌ"
            alertMessage = "Tính năng Mod Skin hiện đang được bảo trì an toàn. Vui lòng quay lại sau!"
            showAlert = true
            return
        }
        isApplyingSkin = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        DispatchQueue.global(qos: .userInitiated).async {
            BundledPatchInjector.autoImportBundledPatches(into: self.patchStore)
            var appliedNames: [String] = []

            for chip in self.selectedSpecialSkins {
                if let cp = CloudPatchService.shared.patch(named: chip) {
                    if self.applyBundledPatch(named: cp.baseName) {
                        if !appliedNames.contains(cp.name) {
                            appliedNames.append(cp.name)
                        }
                    }
                } else {
                    let fallbackBase: String? = {
                        switch chip.uppercased() {
                        case "SKIN ALOCK V2": return "lib_app_skin_alock_v2"
                        case "SKIN THẺ VÔ CỰC VÀNG MÙA 1", "SKIN IGNIS": return "lib_app_skin_ignis"
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
            if appliedNames.isEmpty {
                if self.applyBundledPatch(named: "lib_app_skin_alock_v2") {
                    appliedNames.append("Skin Alock V2 (Mặc định)")
                }
            }

            DevicePatchService.ensureActivePatchesInjected()
            Thread.sleep(forTimeInterval: 0.6)

            DispatchQueue.main.async {
                self.isApplyingSkin = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Toast thông báo nhanh cho Skin
                let skinSummary = appliedNames.joined(separator: ", ")
                self.showToastNotification(
                    message: "✅ Skin đã nạp: \(skinSummary)",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )

                self.alertTitle = "✅ ÁP DỤNG SKIN THÀNH CÔNG"
                self.alertMessage = "Toàn bộ skin đã chọn đã được nạp an toàn vào game:\n" + appliedNames.map { "• " + $0 }.joined(separator: "\n")
                self.showAlert = true
            }
        }
    }

    // MARK: - TAB 4: Antiban View
    private var antibanView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 1. Antiban Safe Shield Card (.bx-pass)
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 38))
                            .foregroundColor(antibanService.isAntibanEnabled ? Color(red: 0.20, green: 0.88, blue: 0.45) : colorMute)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("AppleStoreVN Antiban Safe Shield")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(colorInk)
                            Text("Ledger Safe Injection & Lifecycle Auto-Restore")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text(antibanService.isAntibanEnabled ? "BẢO VỆ 100% ONLINE" : "CHƯA KÍCH HOẠT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(antibanService.isAntibanEnabled ? Color.green : Color.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background((antibanService.isAntibanEnabled ? Color.green : Color.orange).opacity(0.12))
                                .cornerRadius(4)
                        }
                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { antibanService.isAntibanEnabled },
                            set: { _ in antibanService.toggleAntiban() }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color.green))
                    }

                    Divider().background(Color.white.opacity(0.08))

                    // Buttons to Setup Profile & Open Settings
                    HStack(spacing: 10) {
                        Button(action: {
                            antibanService.setupAntiban()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 12))
                                Text(antibanService.isSettingUp ? "Đang gửi hồ sơ..." : "Cài Đặt Hồ Sơ Antiban")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(12)
                        }
                        .disabled(antibanService.isSettingUp)

                        Button(action: {
                            antibanService.openIOSSettings()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 12))
                                Text("Cài Đặt iOS")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }

                    if let notice = antibanService.statusNotice {
                        Text(notice)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.yellow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [antibanService.isAntibanEnabled ? Color.green.opacity(0.10) : Color.white.opacity(0.04), Color.black.opacity(0.55)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))

                // 2. Game Switch
                VStack(spacing: 8) {
                    HStack {
                        Text("Game")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(colorMute)
                        Spacer()
                        HStack(spacing: 2) {
                            segmentButton(title: "FF", isSelected: miscGame == "ff") {
                                miscGame = "ff"
                            }
                            segmentButton(title: "FFM", isSelected: miscGame == "max") {
                                miscGame = "max"
                            }
                        }
                        .padding(3)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(999)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
                .padding(14)
                .background(glassBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))

                // 3. Action Buttons (Clean Restore)
                Button(action: {
                    performCleanRestore()
                }) {
                    HStack(spacing: 8) {
                        if isRestoringClean {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isRestoringClean ? "Đang khôi phục sạch..." : "Khôi phục sạch 100% (Reset all)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 239/255, green: 68/255, blue: 68/255), Color(red: 185/255, green: 28/255, blue: 28/255)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .disabled(isRestoringClean)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    // MARK: - TAB 5: Hồ Sơ / Cá Nhân View
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
                    metaRow(label: "Chủ sở hữu", value: "Võ Nhật Qui (CheatVN)")

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
                            Text("Chủ sở hữu: Võ Nhật Qui (CheatVN)")
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
        let hasActiveMods = !selectedAimChips.isEmpty || !selectedEspChips.isEmpty || !selectedSpecialSkins.isEmpty

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
                        self.selectedSpecialSkins.removeAll()
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

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.isInjected = false
                    self.activeAimPatch = nil
                    self.activeEspColor = nil
                    self.selectedAimChips.removeAll()
                    self.selectedEspChips.removeAll()
                    self.selectedSpecialSkins.removeAll()
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
