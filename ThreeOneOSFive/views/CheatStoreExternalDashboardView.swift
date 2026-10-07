import SwiftUI
import UIKit

// MARK: - CheatStore External Tab Enum (4 Tab: Aimbot, Visual, Misc, Setting)
enum ExternalCheatTab: Int, CaseIterable {
    case aimbot = 0
    case visual = 1
    case misc = 2
    case setting = 3

    var title: String {
        switch self {
        case .aimbot: return "Aimbot"
        case .visual: return "Visual"
        case .misc: return "Misc"
        case .setting: return "Setting"
        }
    }

    var icon: String {
        switch self {
        case .aimbot: return "scope"
        case .visual: return "eye.fill"
        case .misc: return "bolt.fill"
        case .setting: return "gearshape.fill"
        }
    }
}

// MARK: - CheatStore External ESP Dashboard View
/// Giao diện điều khiển External ESP chuẩn Headless 1:1 theo ảnh mẫu dành riêng cho CheatStore VN
struct CheatStoreExternalDashboardView: View {
    @ObservedObject var espService = ExternalESPConfigService.shared
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    var onBackToGames: (() -> Void)? = nil

    // Tab đang chọn (Mặc định là Visual theo đúng ảnh mẫu)
    @State private var selectedTab: ExternalCheatTab = .visual

    // Toast & Alert states
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = Color.green
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    // Màu sắc giao diện Dark Mode chuẩn ảnh mẫu
    private let bgVoid = Color(red: 11/255, green: 12/255, blue: 15/255)
    private let cardBg = Color(red: 20/255, green: 21/255, blue: 27/255)
    private let cardBorder = Color(red: 35/255, green: 37/255, blue: 47/255)
    private let tabBarBg = Color(red: 24/255, green: 25/255, blue: 33/255)
    private let tabActiveBg = Color(red: 40/255, green: 43/255, blue: 56/255)
    private let textPrimary = Color(red: 242/255, green: 242/255, blue: 247/255)
    private let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)
    private let segBg = Color(red: 32/255, green: 34/255, blue: 43/255)
    private let segActiveBg = Color(red: 55/255, green: 58/255, blue: 72/255)

    var body: some View {
        ZStack {
            // Nền đen sâu True Dark
            bgVoid.ignoresSafeArea()

            VStack(spacing: 0) {
                // Thanh 4 Tab trên đỉnh (Aimbot, Visual, Misc, Setting)
                topTabBarView
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Nội dung các Tab cuộn mượt mà
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        switch selectedTab {
                        case .visual:
                            visualTabContent
                        case .aimbot:
                            aimbotTabContent
                        case .misc:
                            miscTabContent
                        case .setting:
                            settingTabContent
                        }

                        // Nút Inject & Launch game ở dưới cùng
                        bottomActionSection
                            .padding(.top, 6)
                            .padding(.bottom, 36)
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Toast overlay
            if showToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: toastIcon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(toastColor)

                        Text(toastMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showToast = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(textSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 26/255, green: 27/255, blue: 34/255).opacity(0.98))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(toastColor.opacity(0.4), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.6), radius: 10, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đóng"))
            )
        }
    }

    // MARK: - Top Tab Bar (Pill Container 4 Tabs Chuẩn Ảnh Mẫu)
    private var topTabBarView: some View {
        HStack(spacing: 4) {
            ForEach(ExternalCheatTab.allCases, id: \.self) { tab in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))

                        Text(tab.title)
                            .font(.system(size: 13.5, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                    }
                    .foregroundColor(selectedTab == tab ? .white : textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedTab == tab ? tabActiveBg : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedTab == tab ? Color.white.opacity(0.18) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(tabBarBg)
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(cardBorder, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    // MARK: - TAB 2: VISUAL (Chuẩn 1:1 Ảnh Mẫu Của Khách)
    private var visualTabContent: some View {
        VStack(spacing: 14) {
            // CARD 1: ESP MAIN
            VStack(alignment: .leading, spacing: 14) {
                // Header: eye icon + "ESP MAIN"
                HStack(spacing: 7) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("ESP MAIN")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }
                .padding(.bottom, 2)

                // Row: ESP Master
                toggleRow(title: "ESP Master", isOn: $espService.espMaster, hasDot: false)

                // Row: ESP Line
                toggleRow(title: "ESP Line", isOn: $espService.espLine, hasDot: true)

                // Row: ESP Box
                toggleRow(title: "ESP Box", isOn: $espService.espBox, hasDot: true)

                // Row: Box Type: [Cornered] [2D Bounding]
                VStack(alignment: .leading, spacing: 8) {
                    Text("Box Type:")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)

                    HStack(spacing: 6) {
                        segmentedOptionButton(
                            title: "Cornered",
                            isSelected: espService.boxType == 0
                        ) {
                            espService.boxType = 0
                        }

                        segmentedOptionButton(
                            title: "2D Bounding",
                            isSelected: espService.boxType == 1
                        ) {
                            espService.boxType = 1
                        }
                    }
                    .padding(3)
                    .background(segBg)
                    .cornerRadius(10)
                }

                // Row: ESP Name
                toggleRow(title: "ESP Name", isOn: $espService.espName, hasDot: true)

                // Row: ESP Distance
                toggleRow(title: "ESP Distance", isOn: $espService.espDistance, hasDot: true)

                // Row: ESP Health (Không có dot tròn theo ảnh mẫu)
                toggleRow(title: "ESP Health", isOn: $espService.espHealth, hasDot: false)

                // Row: Health Type: [Right] [Left]
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Type:")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)

                    HStack(spacing: 6) {
                        segmentedOptionButton(
                            title: "Right",
                            isSelected: espService.healthType == 0
                        ) {
                            espService.healthType = 0
                        }

                        segmentedOptionButton(
                            title: "Left",
                            isSelected: espService.healthType == 1
                        ) {
                            espService.healthType = 1
                        }
                    }
                    .padding(3)
                    .background(segBg)
                    .cornerRadius(10)
                }

                // Row: ESP Skeleton
                toggleRow(title: "ESP Skeleton", isOn: $espService.espSkeleton, hasDot: true)

                // Row: Draw Count Enemies
                toggleRow(title: "Draw Count Enemies", isOn: $espService.drawCountEnemies, hasDot: true)
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))

            // CARD 2: VISUAL SLIDERS
            VStack(alignment: .leading, spacing: 14) {
                // Header: Slider icon + "VISUAL SLIDERS"
                HStack(spacing: 7) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("VISUAL SLIDERS")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }
                .padding(.bottom, 2)

                // Slider 1: Text Size
                VStack(spacing: 6) {
                    HStack {
                        Text("Text Size")
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)

                        Spacer()

                        Text(String(format: "%.1f", espService.textSize))
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Slider(value: $espService.textSize, in: 0.5...3.0, step: 0.1)
                        .accentColor(Color.white)
                }

                // Slider 2: Thickness Size
                VStack(spacing: 6) {
                    HStack {
                        Text("Thickness Size")
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)

                        Spacer()

                        Text(String(format: "%.1f", espService.thicknessSize))
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Slider(value: $espService.thicknessSize, in: 0.5...3.0, step: 0.1)
                        .accentColor(Color.white)
                }
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        }
    }

    // MARK: - TAB 1: AIMBOT
    private var aimbotTabContent: some View {
        VStack(spacing: 14) {
            // CARD: AIMBOT MAIN
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "scope")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("AIMBOT CONFIG")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }
                .padding(.bottom, 2)

                toggleRow(title: "Aimbot Master", isOn: $espService.aimMaster, hasDot: false)

                // Vị trí khóa (Bone)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Bone:")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)

                    HStack(spacing: 6) {
                        segmentedOptionButton(title: "Đầu (Head)", isSelected: espService.aimBone == 0) {
                            espService.aimBone = 0
                        }
                        segmentedOptionButton(title: "Cổ (Neck)", isSelected: espService.aimBone == 1) {
                            espService.aimBone = 1
                        }
                        segmentedOptionButton(title: "Ngực (Chest)", isSelected: espService.aimBone == 2) {
                            espService.aimBone = 2
                        }
                    }
                    .padding(3)
                    .background(segBg)
                    .cornerRadius(10)
                }

                // Chế độ khóa (Aim Mode)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aim Trigger:")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)

                    HStack(spacing: 6) {
                        segmentedOptionButton(title: "Auto Lock", isSelected: espService.aimMode == 0) {
                            espService.aimMode = 0
                        }
                        segmentedOptionButton(title: "Khi Ngắm", isSelected: espService.aimMode == 1) {
                            espService.aimMode = 1
                        }
                        segmentedOptionButton(title: "Khi Bắn", isSelected: espService.aimMode == 2) {
                            espService.aimMode = 2
                        }
                    }
                    .padding(3)
                    .background(segBg)
                    .cornerRadius(10)
                }

                // Slider FOV
                VStack(spacing: 6) {
                    HStack {
                        Text("FOV Range")
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)
                        Spacer()
                        Text("\(Int(espService.aimFov))°")
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Slider(value: $espService.aimFov, in: 30...180, step: 5)
                        .accentColor(Color.white)
                }

                // Slider Smooth
                VStack(spacing: 6) {
                    HStack {
                        Text("Smoothness")
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)
                        Spacer()
                        Text(String(format: "%.1f", espService.aimSmooth))
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Slider(value: $espService.aimSmooth, in: 1.0...10.0, step: 0.5)
                        .accentColor(Color.white)
                }
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))

            // CARD 2: SILENT AIM
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("SILENT AIM & TRIGGER")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }

                toggleRow(title: "Silent Aim 100% (Đạn Ma)", isOn: $espService.silentAim, hasDot: false)
                toggleRow(title: "Auto Fire (Tự Động Bắn)", isOn: $espService.autoFire, hasDot: false)
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        }
    }

    // MARK: - TAB 3: MISC & ANTIBAN
    private var miscTabContent: some View {
        VStack(spacing: 14) {
            // CARD 1: ANTIBAN PROTECTION
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("MISC & PROTECTION")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }

                toggleRow(title: "Antiban Master 100% (Yabao Core)", isOn: $espService.antibanMaster, hasDot: false)
                toggleRow(title: "Safe Mode Bypass Anti-Cheat", isOn: $espService.safeMode, hasDot: false)
                toggleRow(title: "Fast Medikit (Bơm Máu Chạy)", isOn: $espService.fastMedikit, hasDot: false)
                toggleRow(title: "Fast Parachute (Dù Siêu Tốc)", isOn: $espService.fastParachute, hasDot: false)
                toggleRow(title: "Wall Through / Fake Lag", isOn: $espService.wallThrough, hasDot: false)
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))

            // CARD 2: TIỆN ÍCH GAME
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("TIỆN ÍCH HỆ THỐNG")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    resetGuestAccount()
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Reset Guest Account (Xóa Tài Khoản Khách)")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(Color(red: 255/255, green: 100/255, blue: 100/255))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.10))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    cleanGameCache()
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Xóa Cache Bộ Nhớ Game (Clean Memory)")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        }
    }

    // MARK: - TAB 4: SETTING
    private var settingTabContent: some View {
        VStack(spacing: 14) {
            // CARD 1: CẤU HÌNH GAME
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("CẤU HÌNH GAME MỤC TIÊU")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phiên Bản Game:")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)

                    HStack(spacing: 6) {
                        segmentedOptionButton(title: "Free Fire TH", isSelected: espService.targetGame == "ff") {
                            espService.targetGame = "ff"
                        }
                        segmentedOptionButton(title: "Free Fire MAX", isSelected: espService.targetGame == "max") {
                            espService.targetGame = "max"
                        }
                    }
                    .padding(3)
                    .background(segBg)
                    .cornerRadius(10)
                }

                toggleRow(title: "Tự Động Đồng Bộ Real-time", isOn: $espService.autoSync, hasDot: false)
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))

            // CARD 2: BẢN QUYỀN & LIÊN HỆ
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textSecondary)

                    Text("BẢN QUYỀN & HỖ TRỢ")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(textSecondary)

                    Spacer()
                }

                infoRow(label: "Thương hiệu", value: "CheatVN External")
                infoRow(label: "Chủ sở hữu", value: "Võ Nhật Qui (CheatVN)")
                infoRow(label: "Key kích hoạt", value: licenseManager.activeKey.isEmpty ? "VĨNH VIỄN" : licenseManager.activeKey)
                infoRow(label: "Thời hạn", value: licenseManager.formattedRemainingTime)
                infoRow(label: "Trạng thái Key", value: "Hoạt Động 100% (Hợp Lệ)")

                // Nút Liên Hệ Zalo & Telegram
                HStack(spacing: 10) {
                    Button(action: {
                        if let url = URL(string: "https://zalo.me/0365829172") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("Z")
                                .font(.system(size: 16, weight: .black))
                            Text("Zalo Admin")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(red: 0/255, green: 130/255, blue: 250/255))
                        .cornerRadius(10)
                    }

                    Button(action: {
                        if let url = URL(string: "https://t.me/vassco911") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 13))
                            Text("Telegram")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(red: 25/255, green: 165/255, blue: 235/255))
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 4)

                // Nút Khôi Phục Game Gốc
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    performCleanRestore()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.shield.fill")
                            .font(.system(size: 14))
                        Text("Khôi Phục Game Gốc (Làm Sạch Dữ Liệu)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.35), lineWidth: 1))
                }

                // Nút Đăng Xuất Key
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    licenseManager.deactivate()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                        Text("Đăng Xuất Key Bản Quyền")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(Color(red: 255/255, green: 90/255, blue: 90/255))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color.red.opacity(0.10))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Bottom Action Section (Nút INJECT & MỞ GAME Chuẩn Đẳng Cấp)
    private var bottomActionSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                handleMainAction()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            espService.isInjected
                                ? LinearGradient(colors: [Color(red: 22/255, green: 160/255, blue: 90/255), Color(red: 16/255, green: 120/255, blue: 68/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(red: 35/255, green: 38/255, blue: 50/255), Color(red: 18/255, green: 20/255, blue: 26/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(espService.isInjected ? Color.green.opacity(0.5) : Color.white.opacity(0.25), lineWidth: 1.2)
                        )
                        .shadow(color: espService.isInjected ? Color.green.opacity(0.3) : Color.black.opacity(0.6), radius: 12, y: 3)

                    HStack(spacing: 9) {
                        if espService.isInjecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                            Text("Đang nạp cấu hình...")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        } else if espService.isInjected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)

                            Text("MỞ GAME NGAY (ĐÃ INJECT)")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.5)
                        } else {
                            Image(systemName: "syringe.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Text("INJECT VÀO GAME")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.8)
                        }
                    }
                }
                .frame(height: 52)
            }
            .disabled(espService.isInjecting)

            // Nút phụ: Uninject nếu đã inject
            if espService.isInjected {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    espService.uninjectExternal()
                    showBanner(message: "Đã gỡ bỏ bản mod, game về nguyên bản sạch 100%", icon: "arrow.counterclockwise", color: .orange)
                }) {
                    Text("GỠ BỎ CHEAT (UNINJECT)")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.red.opacity(0.85))
                        .padding(.vertical, 6)
                }
            }

            // Dòng chú thích nhỏ
            Text("Bản quyền CheatStore VN • Only ESP Headless Engine v3.105")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textSecondary.opacity(0.7))
        }
    }

    // MARK: - Logic Xử Lý Inject & Mở Game
    private func handleMainAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if espService.isInjected {
            // Đã inject rồi -> Cập nhật live rồi mở game
            espService.updateLiveConfiguration()
            espService.launchGame()
            showBanner(message: "Đang mở Free Fire...", icon: "play.fill", color: .green)
        } else {
            // Nạp Only ESP vào game
            let ok = espService.applyConfigurationAndLaunch(launchAfterInject: true)
            if ok {
                showBanner(message: "Inject thành công! Đang mở Free Fire...", icon: "checkmark.circle.fill", color: .green)
            } else {
                showBanner(message: espService.lastStatusMessage.isEmpty ? "Lỗi nạp cấu hình" : espService.lastStatusMessage, icon: "exclamationmark.triangle.fill", color: .red)
            }
        }
    }

    // MARK: - Subviews & Reusable Components
    private func toggleRow(title: String, isOn: Binding<Bool>, hasDot: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .foregroundColor(textPrimary)

            Spacer()

            if hasDot {
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .padding(.trailing, 8)
            }

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.white))
        }
    }

    private func segmentedOptionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? segActiveBg : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.white.opacity(0.14) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tiện ích
    private func resetGuestAccount() {
        let containers = DevicePatchService.allAvailableFreeFireContainers()
        for (_, root) in containers {
            let docDir = root.appendingPathComponent("Documents")
            try? FileManager.default.removeItem(at: docDir.appendingPathComponent("g_id.dat"))
            try? FileManager.default.removeItem(at: docDir.appendingPathComponent("guest.dat"))
        }
        showBanner(message: "Đã xóa tài khoản khách (Guest) thành công", icon: "checkmark.circle.fill", color: .green)
    }

    private func cleanGameCache() {
        let containers = DevicePatchService.allAvailableFreeFireContainers()
        for (_, root) in containers {
            let cacheDir = root.appendingPathComponent("Library/Caches")
            try? FileManager.default.removeItem(at: cacheDir)
        }
        showBanner(message: "Đã dọn dẹp sạch sẽ cache bộ nhớ game", icon: "checkmark.circle.fill", color: .green)
    }

    private func performCleanRestore() {
        espService.uninjectExternal()
        showBanner(message: "Đã khôi phục game gốc sạch sẽ 100%", icon: "checkmark.shield.fill", color: .green)
    }

    private func showBanner(message: String, icon: String, color: Color) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                if toastMessage == message {
                    showToast = false
                }
            }
        }
    }
}
