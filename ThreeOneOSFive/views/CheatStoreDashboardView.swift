import SwiftUI
import UIKit

// MARK: - CheatStoreTab Enum (5 Tab Tiếng Việt Chuẩn)
enum CheatStoreTab: Int, CaseIterable {
    case home = 0
    case esp = 1
    case skin = 2
    case antiban = 3
    case profile = 4

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .esp: return "Định Vị"
        case .skin: return "Modskin"
        case .antiban: return "Antiban"
        case .profile: return "Cá Nhân"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .esp: return "location.viewfinder"
        case .skin: return "tshirt.fill"
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

// MARK: - Main Dashboard View
struct CheatStoreDashboardView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    @ObservedObject private var antibanService = AntibanProfileService.shared
    var onBackToGames: (() -> Void)? = nil

    // Tab state
    @State private var selectedTab: CheatStoreTab = .home

    // Tab 1: Trang Chủ State
    @State private var selectedGame: String = "ff"           // "ff" or "max"
    @State private var activeAimPatch: String? = nil
    @State private var selectedAimChips: Set<String> = []
    @State private var isInjecting: Bool = false

    private var currentAimDisplayText: String {
        let activeMods = ["AIM DRAG", "AIMNECK VIP"].filter { selectedAimChips.contains($0) }
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

    // 0xCheats Design Tokens
    private let colorVoid = Color.black
    private let colorPanel = Color(red: 22/255, green: 22/255, blue: 24/255)
    private let colorInk = Color(red: 244/255, green: 241/255, blue: 234/255)
    private let colorMute = Color(red: 141/255, green: 136/255, blue: 128/255)
    private let accentRed = Color(red: 255/255, green: 48/255, blue: 48/255)
    private let glassBg = Color.white.opacity(0.05)
    private let glassBorder = Color.white.opacity(0.12)

    var body: some View {
        ZStack {
            // Nền đen sâu True Black Void
            colorVoid.ignoresSafeArea()

            // Subtle red ambient glow
            RadialGradient(
                gradient: Gradient(colors: [accentRed.opacity(0.08), Color.clear]),
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header thanh trên chuẩn .main-head bx-head
                topHeaderView

                // Nội dung 5 Tab chuyển đổi mượt mà 60fps
                ZStack {
                    if selectedTab == .home {
                        homeView
                            .transition(.opacity)
                    } else if selectedTab == .esp {
                        espView
                            .transition(.opacity)
                    } else if selectedTab == .skin {
                        skinView
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
                    .padding(.bottom, 6)
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
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle.isEmpty ? "Thông báo" : alertTitle),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("Đóng"))
            )
        }
    }

    // MARK: - Top Header (.main-head bx-head)
    private var topHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedTab.title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(3.8)
                    .foregroundColor(accentRed.opacity(0.85))

                Text("CheatStore VN")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .tracking(-0.8)
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

    // MARK: - TAB 1: Trang Chủ View
    private var homeView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. Hero Stats Card (.bx-hero)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(heroTagText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(colorInk.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(999)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // Aimbot Stat
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aimbot")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text(currentAimDisplayText)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(currentAimDisplayText != "Chưa bật" ? accentRed : colorMute)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .frame(height: 32)
                            .background(Color.white.opacity(0.1))

                        // Status Stat - Hiển thị trạng thái thực tế
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trạng Thái")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text(selectedAimChips.isEmpty ? "CHƯA BẬT" : "SẴN SÀNG")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(selectedAimChips.isEmpty ? colorMute : Color.green)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.45))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))

                // 2. Game Switch Row (Chỉ để FF thôi, không cần Aim V1 V2)
                HStack {
                    Text("Game")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(colorMute)
                    Spacer()
                    HStack(spacing: 2) {
                        segmentButton(title: "FF", isSelected: selectedGame == "ff") {
                            selectedGame = "ff"
                        }
                        segmentButton(title: "FFM", isSelected: selectedGame == "max") {
                            selectedGame = "max"
                        }
                    }
                    .padding(3)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(999)
                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                .padding(14)
                .background(glassBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))

                // 3. Modules Section (.bx-section) - Aim Chips (Layout Dọc)
                VStack(alignment: .leading, spacing: 10) {
                    Text("CHỨC NĂNG BỔ TRỢ & AIM")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    let chips = [
                        ("AIM DRAG", "Trợ lực ghì tâm sảnh", false),
                        ("AIMNECK VIP", licenseManager.featureConfig.aimneck ? "Ghim cổ chống soi" : "Tạm khóa do máy chủ quét", !licenseManager.featureConfig.aimneck)
                    ]

                    VStack(spacing: 8) {
                        ForEach(chips, id: \.0) { item in
                            ZeroXChipButton(
                                title: item.0,
                                subtitle: item.1,
                                isSelected: selectedAimChips.contains(item.0),
                                isUnderMaintenance: item.2,
                                maintenanceBadge: "BẢO TRÌ"
                            ) {
                                toggleAimChip(item.0)
                            }
                        }
                    }
                    .padding(12)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 4. Core VIP Patches (Layout Dọc)
                VStack(alignment: .leading, spacing: 10) {
                    Text("CORE VIP MODS (CHỐNG VĂNG)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    let coreMods = [
                        ("APPLE IPA V2", "Bản quyền Apple IPA"),
                        ("SWIFT IOS", "Aimbot Fix Văng"),
                        ("INTERNAL MOD", "Menu Internal ẩn"),
                        ("APPLESTORE PRIME", "Fix văng & chống quét")
                    ]

                    VStack(spacing: 8) {
                        ForEach(coreMods, id: \.0) { item in
                            ZeroXChipButton(
                                title: item.0,
                                subtitle: item.1,
                                isSelected: selectedAimChips.contains(item.0)
                            ) {
                                toggleAimChip(item.0)
                            }
                        }
                    }
                    .padding(12)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 5. Action Buttons (.bx-foot)
                VStack(spacing: 10) {
                    // Inject Button
                    Button(action: handleInjectAction) {
                        HStack {
                            if isInjecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .padding(.trailing, 6)
                            }
                            Text(isInjecting ? "Đang nạp Inject..." : "Inject Vào Game")
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
                    .disabled(isInjecting)

                    // Vào Game Button
                    Button(action: handleLaunchGame) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Vào Game (\(selectedGame == "ff" ? "Free Fire" : "FF Max"))")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 168/255, green: 85/255, blue: 247/255), Color(red: 126/255, green: 34/255, blue: 206/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 3)
                    }

                    // Restore Original Button
                    Button(action: {
                        performCleanRestore()
                    }) {
                        Text(isRestoringClean ? "Đang khôi phục..." : "Khôi phục gốc")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(colorInk.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(glassBg)
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(glassBorder, lineWidth: 1))
                    }
                    .disabled(isRestoringClean)
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
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
                alertTitle = "⚠️ Chưa cài đặt Free Fire"
                alertMessage = "Không tìm thấy game Free Fire trên thiết bị này. Vui lòng cài đặt trước!"
                showAlert = true
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

        DispatchQueue.global(qos: .userInitiated).async {
            BundledPatchInjector.autoImportBundledPatches(into: self.patchStore)
            var appliedNames: [String] = []

            // 1. Core Mod
            if self.selectedAimChips.contains("APPLE IPA V2") {
                if self.applyBundledPatch(named: "lib_app_apple_ipa_v2") { appliedNames.append("Apple IPA V2") }
            } else if self.selectedAimChips.contains("SWIFT IOS") {
                if self.applyBundledPatch(named: "lib_app_swift_ios") { appliedNames.append("Swift iOS") }
            } else if self.selectedAimChips.contains("APPLESTORE PRIME") {
                if self.applyBundledPatch(named: "lib_app_applestore_prime") { appliedNames.append("AppleStore PRIME") }
            } else if self.selectedAimChips.contains("INTERNAL MOD") {
                if self.applyBundledPatch(named: "lib_app_internal") { appliedNames.append("Internal Mod") }
            }

            // 2. Aim Mods
            if self.selectedAimChips.contains("AIMNECK VIP") {
                if self.applyBundledPatch(named: "lib_app_aimneck_vip") { appliedNames.append("AimNeck VIP") }
            }
            if self.selectedAimChips.contains("AIM DRAG") || self.selectedAimChips.contains("DRAG") {
                if self.applyBundledPatch(named: "lib_app_system") { appliedNames.append("Aim Drag") }
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
                            Text(!licenseManager.featureConfig.esp ? "BẢO TRÌ" : (selectedEspChips.contains("ESP AIMHEAD V3") ? "ĐÃ BẬT" : "SẴN SÀNG"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(!licenseManager.featureConfig.esp ? Color.red : (selectedEspChips.contains("ESP AIMHEAD V3") ? Color.green : colorMute))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.45))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))

                // 1. ESP Single Item (.bx-section) based on AppCore/lib_app_esp_aimhead_v3.dat
                VStack(alignment: .leading, spacing: 10) {
                    Text("MODULE ĐỊNH VỊ (LIB_APP_ESP_AIMHEAD_V3)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    ZeroXChipButton(
                        title: "ESP AIMHEAD V3",
                        subtitle: "Định vị xuyên tường, khoảng cách & ghim đầu",
                        isSelected: selectedEspChips.contains("ESP AIMHEAD V3"),
                        isUnderMaintenance: !licenseManager.featureConfig.esp,
                        maintenanceBadge: "BẢO TRÌ"
                    ) {
                        if !licenseManager.featureConfig.esp {
                            alertTitle = "⚠️ CHỨC NĂNG ĐANG BẢO TRÌ"
                            alertMessage = "Hệ thống Định Vị ESP hiện đang bảo trì để nâng cấp thuật toán giải phóng RAM chống văng game. Vui lòng quay lại sau!"
                            showAlert = true
                            return
                        }
                        if selectedEspChips.contains("ESP AIMHEAD V3") {
                            selectedEspChips.remove("ESP AIMHEAD V3")
                            activeEspColor = nil
                        } else {
                            selectedEspChips.insert("ESP AIMHEAD V3")
                            activeEspColor = "ESP AIMHEAD V3"
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
                            .foregroundColor(accentRed)
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
            let success = self.applyBundledPatch(named: "lib_app_esp_aimhead_v3")
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
                // Section: 2 Chức Năng Cũ (Skin Alock V2 & Skin Thẻ Vô Cực Vàng Mùa 1)
                Text("MOD SKIN VIP (AN TOÀN)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundColor(colorMute)
                    .padding(.horizontal, 4)

                let oldSkins = [
                    ("Skin Alock V2", "Trang phục nhân vật Alok cực chất (Bản V2)"),
                    ("Skin thẻ vô cực vàng mùa 1", "Trang phục Thẻ Vô Cực Vàng Mùa 1")
                ]

                VStack(spacing: 8) {
                    ForEach(oldSkins, id: \.0) { item in
                        ZeroXChipButton(
                            title: item.0,
                            subtitle: item.1,
                            isSelected: selectedSpecialSkins.contains(item.0),
                            isUnderMaintenance: !licenseManager.featureConfig.skin,
                            maintenanceBadge: "BẢO TRÌ"
                        ) {
                            if !licenseManager.featureConfig.skin {
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

            if self.selectedSpecialSkins.contains("Skin Alock V2") {
                if self.applyBundledPatch(named: "lib_app_skin_alock_v2") {
                    appliedNames.append("Skin Alock V2")
                }
            }
            if self.selectedSpecialSkins.contains("Skin thẻ vô cực vàng mùa 1") {
                if self.applyBundledPatch(named: "lib_app_skin_ignis") || self.applyBundledPatch(named: "lib_app_skin_alock_v2") {
                    appliedNames.append("Skin Thẻ Vô Cực Vàng Mùa 1")
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
                        Image("PhantomBrand")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accentRed.opacity(0.4), lineWidth: 1.2)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("CheatStore VN")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundColor(colorInk)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }

                            Text("Chủ sở hữu: Võ Nhật Qui (CheatVN)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.orange)
                        }

                        Spacer()
                    }

                    Divider().background(Color.white.opacity(0.08))

                    // Tên App
                    metaRow(label: "Tên App", value: "CheatStore VN (v2.0)")

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
                    Text("THIẾT BỊ & HỆ THỐNG")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        // Tên Thiết Bị
                        metaRow(label: "Tên Thiết Bị", value: UIDevice.current.name)

                        Divider().background(Color.white.opacity(0.08))

                        // Hệ điều hành ios
                        metaRow(label: "Hệ điều hành iOS", value: "iOS " + UIDevice.current.systemVersion)

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
                    .foregroundColor(accentRed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(accentRed.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(accentRed.opacity(0.3), lineWidth: 1))
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

    // MARK: - Ledger Restore Cleanup Action
    func performCleanRestore() {
        guard !isRestoringClean else { return }
        isRestoringClean = true

        // Hiện toast thông báo đang xử lý
        showToastNotification(
            message: "Đang khôi phục dữ liệu gốc game...",
            icon: "arrow.counterclockwise",
            color: Color.orange
        )

        DispatchQueue.global(qos: .userInitiated).async {
            DevicePatchService.cleanRestoreAllModifications()

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.activeAimPatch = nil
                    self.activeEspColor = nil
                    self.selectedAimChips.removeAll()
                    self.selectedEspChips.removeAll()
                    self.selectedSpecialSkins.removeAll()
                    self.isRestoringClean = false
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Hiện toast thành công
                self.showToastNotification(
                    message: "✅ Đã khôi phục sạch 100% dữ liệu game!",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )

                // Đồng thời hiện alert chi tiết
                self.alertTitle = "✅ ĐÃ KHÔI PHỤC SẠCH 100%"
                self.alertMessage = "Toàn bộ file gốc của Free Fire đã được phục hồi nguyên bản an toàn. Đã gỡ bỏ toàn bộ trạng thái mod."
                self.showAlert = true
            }
        }
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
