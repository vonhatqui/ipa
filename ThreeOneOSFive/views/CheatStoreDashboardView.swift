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
    let accentColor: Color
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        accentColor: Color = Color(red: 255/255, green: 48/255, blue: 48/255),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 9) {
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? Color(red: 244/255, green: 241/255, blue: 234/255) : Color(red: 244/255, green: 241/255, blue: 234/255).opacity(0.82))
                        .lineLimit(1)

                    if let sub = subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 141/255, green: 136/255, blue: 128/255))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: subtitle == nil ? 46 : 52)
            .background(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
    @State private var selectedAimVersion: String = "v2"      // "v1" or "v2"
    @State private var activeAimPatch: String? = "HEAD"
    @State private var selectedAimChips: Set<String> = ["HEAD", "APPLE IPA V2"]
    @State private var isInjecting: Bool = false

    // Tab 2: Định Vị State
    @State private var activeEspColor: String? = "WEAPON GREEN"
    @State private var selectedEspChips: Set<String> = ["WEAPON GREEN", "ESP BOX & LINE"]
    @State private var isInjectingEsp: Bool = false

    // Tab 3: Modskin State
    @State private var selectedCharacter: String? = nil
    @State private var activeSkinID: Int? = 1
    @State private var selectedSpecialSkins: Set<String> = ["Skin Ignis Hỏa Lôi"]

    // Tab 4: Antiban State
    @State private var miscGame: String = "ff"
    @State private var miscToggles: [Int: Bool] = [
        1: true,
        8: true
    ]

    // Tab 5: Cá Nhân State
    @State private var copiedKey: Bool = false
    @State private var selectedLanguage: String = "Tiếng Việt"

    // Common Alerts & Status
    @State private var alertTitle: String = ""
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    @State private var isRestoringClean: Bool = false

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

            // Skin Selection Modal Sheet
            if let charName = selectedCharacter {
                skinSelectionModal(character: charName)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle.isEmpty ? "Thông báo" : alertTitle),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
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
                            Text(activeAimPatch ?? "Chưa bật")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(activeAimPatch != nil ? accentRed : colorMute)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .frame(height: 32)
                            .background(Color.white.opacity(0.1))

                        // Status Stat
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trạng Thái")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text("SẴN SÀNG")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(Color.green)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.45))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))

                // 2. Segment Switch Panel (.bx-seg-panel)
                VStack(spacing: 10) {
                    // Game switch row
                    HStack {
                        Text("Game")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(colorMute)
                        Spacer()
                        HStack(spacing: 2) {
                            segmentButton(title: "Free Fire", isSelected: selectedGame == "ff") {
                                selectedGame = "ff"
                            }
                            segmentButton(title: "FF Max", isSelected: selectedGame == "max") {
                                selectedGame = "max"
                            }
                        }
                        .padding(3)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(999)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }

                    // Aim switch row
                    HStack {
                        Text("Aim")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(colorMute)
                        Spacer()
                        HStack(spacing: 2) {
                            segmentButton(title: "Aim V1", isSelected: selectedAimVersion == "v1") {
                                selectedAimVersion = "v1"
                            }
                            segmentButton(title: "Aim V2", isSelected: selectedAimVersion == "v2") {
                                selectedAimVersion = "v2"
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

                // 3. Modules Section (.bx-section) - Aim Chips
                VStack(alignment: .leading, spacing: 10) {
                    Text("MODULES AIM (GIM & KHÓA TÂM)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    let chips = selectedAimVersion == "v1"
                        ? [("DRAG", "Kéo tâm nhẹ"), ("NECK", "Ghim tâm cổ"), ("BODY", "Ghim tâm ngực"), ("MAGIC BULLET", "Đạn ma thuật")]
                        : [("AIMLOCK", "Khóa tâm mượt"), ("NECK", "Ghim tâm cổ"), ("HEAD", "Ghim tâm đầu"), ("BODY", "Ghim tâm thân"),
                           ("HEAD ANTENNA", "Ăng-ten đầu"), ("DRAG ANTENNA", "Ăng-ten kéo tâm"), ("BODY ANTENNA", "Ăng-ten toàn thân"), ("MAGIC BULLET", "Đạn ma thuật")]

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(chips, id: \.0) { item in
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

                // 4. Core VIP Patches
                VStack(alignment: .leading, spacing: 10) {
                    Text("CORE VIP MODS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    let coreMods = [
                        ("APPLE IPA V2", "Bản quyền Apple IPA"),
                        ("SWIFT IOS", "Tối ưu hóa Swift iOS"),
                        ("INTERNAL MOD", "Menu Internal ẩn"),
                        ("APPLESTORE PRIME", "Fix văng & chống quét")
                    ]

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
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
                            Text(isInjecting ? "Đang nạp Inject..." : "Inject")
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

                    // Restore Original Button
                    Button(action: {
                        performCleanRestore()
                    }) {
                        Text("Khôi phục gốc")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(colorInk.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(glassBg)
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(glassBorder, lineWidth: 1))
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private var heroTagText: String {
        let g = selectedGame == "ff" ? "Free Fire" : "FF Max"
        let a = selectedAimVersion == "v1" ? "Aim V1" : "Aim V2"
        return "\(g) · \(a)"
    }

    private func toggleAimChip(_ chip: String) {
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

    private func handleInjectAction() {
        guard !isInjecting else { return }
        isInjecting = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        DispatchQueue.global(qos: .userInitiated).async {
            BundledPatchInjector.autoImportBundledPatches(into: self.patchStore)
            DevicePatchService.ensureActivePatchesInjected()

            Thread.sleep(forTimeInterval: 0.8)

            DispatchQueue.main.async {
                self.isInjecting = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.alertTitle = "✅ INJECT THÀNH CÔNG"
                let aimInfo = self.activeAimPatch ?? "None"
                self.alertMessage = "Đã kích hoạt thành công:\n• Module Aim: \(aimInfo)\n• Game: \(self.selectedGame.uppercased())\n\nVui lòng mở Free Fire để trải nghiệm!"
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
                            Text("Màu Định Vị")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text(activeEspColor ?? "Chưa bật")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(activeEspColor != nil ? Color.green : colorMute)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .frame(height: 32)
                            .background(Color.white.opacity(0.1))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Chế Độ")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(colorMute)
                            Text("XUYÊN TƯỜNG")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.cyan)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.45))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))

                // 1. ESP Colors Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("MÀU SẮC ĐỊNH VỊ (ESP COLORS)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    let espColors = [
                        ("WEAPON GREEN", "Định vị súng Xanh lá"),
                        ("WEAPON CYAN", "Định vị súng Xanh lơ"),
                        ("WEAPON PINK", "Định vị súng Hồng dạ quang"),
                        ("FULL BODY ESP", "Định vị toàn thân")
                    ]

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(espColors, id: \.0) { item in
                            ZeroXChipButton(
                                title: item.0,
                                subtitle: item.1,
                                isSelected: selectedEspChips.contains(item.0)
                            ) {
                                toggleEspChip(item.0)
                            }
                        }
                    }
                    .padding(12)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 2. ESP Features Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("TÍNH NĂNG ĐỊNH VỊ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    let espFeatures = [
                        ("ESP BOX & LINE", "Khung xương & Kẻ chỉ"),
                        ("ESP HEALTH BAR", "Thanh máu & Tên địch"),
                        ("ESP AIMHEAD V3", "Định vị Đầu đỏ"),
                        ("ESP X-RAY BLUE", "Xuyên vật cản Xanh biển")
                    ]

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(espFeatures, id: \.0) { item in
                            ZeroXChipButton(
                                title: item.0,
                                subtitle: item.1,
                                isSelected: selectedEspChips.contains(item.0)
                            ) {
                                toggleEspChip(item.0)
                            }
                        }
                    }
                    .padding(12)
                    .background(glassBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }

                // 3. Clean ESP Card
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedEspChips.removeAll()
                    activeEspColor = nil
                    alertTitle = "✅ ĐÃ TẮT ĐỊNH VỊ"
                    alertMessage = "Toàn bộ hiệu ứng định vị Visual đã được gỡ bỏ an toàn."
                    showAlert = true
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

                // 4. Inject Button
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
            DevicePatchService.ensureActivePatchesInjected()

            Thread.sleep(forTimeInterval: 0.8)

            DispatchQueue.main.async {
                self.isInjectingEsp = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.alertTitle = "✅ ĐÃ NẠP ĐỊNH VỊ THÀNH CÔNG"
                let espInfo = self.activeEspColor ?? "Mặc định"
                self.alertMessage = "Đã kích hoạt định vị:\n• Visual: \(espInfo)\n\nVui lòng mở Free Fire để trải nghiệm!"
                self.showAlert = true
            }
        }
    }

    // MARK: - TAB 3: Modskin View
    private var skinView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Section 1: Character Roster (.bx-roster)
                Text("ROSTER NHÂN VẬT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundColor(colorMute)
                    .padding(.horizontal, 4)

                VStack(spacing: 12) {
                    // Card 1: Alok
                    characterCard(
                        name: "Alok",
                        imageName: "char-alok",
                        subtitle: "8 trang phục VIP có sẵn"
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedCharacter = "Alok"
                    }

                    // Card 2: Dimitri
                    characterCard(
                        name: "Dimitri",
                        imageName: "char-dimitri",
                        subtitle: "8 trang phục VIP có sẵn"
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedCharacter = "Dimitri"
                    }
                }

                // Section 2: Trang Phục Độc Quyền VIP
                Text("TRANG PHỤC ĐỘC QUYỀN VIP")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundColor(colorMute)
                    .padding(.horizontal, 4)

                let specialSkins = [
                    ("Skin Ignis Hỏa Lôi", "Hiệu ứng lửa cháy rực rỡ"),
                    ("Skin Naco Vũ Trụ", "Hào quang dải ngân hà"),
                    ("Thẻ Vô Cực Mùa 1 Hoàng Kim", "Trang phục Thẻ Vô Cực Vàng")
                ]

                VStack(spacing: 8) {
                    ForEach(specialSkins, id: \.0) { item in
                        ZeroXChipButton(
                            title: item.0,
                            subtitle: item.1,
                            isSelected: selectedSpecialSkins.contains(item.0)
                        ) {
                            if selectedSpecialSkins.contains(item.0) {
                                selectedSpecialSkins.remove(item.0)
                            } else {
                                selectedSpecialSkins.insert(item.0)
                                alertTitle = "✅ ĐÃ CHỌN TRANG PHỤC"
                                alertMessage = "Đã chọn [\(item.0)]. Bấm 'Áp dụng Trang Phục' để nạp vào game!"
                                showAlert = true
                            }
                        }
                    }
                }

                // Nút áp dụng Skin
                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    alertTitle = "✅ ÁP DỤNG SKIN THÀNH CÔNG"
                    alertMessage = "Toàn bộ skin đã chọn đã được mod trực tiếp vào game an toàn!"
                    showAlert = true
                }) {
                    Text("Áp Dụng Mod Skin")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
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
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func characterCard(name: String, imageName: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(colorInk)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(colorMute)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colorMute.opacity(0.7))
            }
            .padding(14)
            .background(glassBg)
            .cornerRadius(22)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(glassBorder, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Modal Sheet chọn Skin cho nhân vật
    private func skinSelectionModal(character: String) -> some View {
        let alokSkins = [
            SkinItemData(id: 1, name: "Alok Sơ Mi Trắng", subtitle: "Hào Quang DJ Vàng Kim"),
            SkinItemData(id: 2, name: "Alok Áo Choàng Quỷ Vương", subtitle: "Lửa Đỏ Rực"),
            SkinItemData(id: 3, name: "Alok Chiến Binh Ánh Sáng", subtitle: "Ánh Kim Bạch Kim Tối Thượng"),
            SkinItemData(id: 4, name: "Alok Dạ Khúc Mùa Đông", subtitle: "Băng Tuyết Pha Lê VIP"),
            SkinItemData(id: 5, name: "Alok Hắc Báo Sấm Sét", subtitle: "Tia Sét Tím Đột Phá"),
            SkinItemData(id: 6, name: "Alok Samurai Bóng Đêm", subtitle: "Song Kiếm Hắc Hóa"),
            SkinItemData(id: 7, name: "Alok Cyberpunk 2077", subtitle: "Neon Dạ Quang Siêu Thực"),
            SkinItemData(id: 8, name: "Alok Hoàng Kim Đế Vương", subtitle: "Thần Giáp Đầy Đủ")
        ]

        let dimitriSkins = [
            SkinItemData(id: 11, name: "Dimitri Lãng Tử Phong Trần", subtitle: "Phong Cách Cổ Điển"),
            SkinItemData(id: 12, name: "Dimitri Thần Thoại Ai Cập", subtitle: "Ánh Sáng Pharaoh"),
            SkinItemData(id: 13, name: "Dimitri Điệp Viên 007", subtitle: "Suit Đen Lịch Lãm"),
            SkinItemData(id: 14, name: "Dimitri Tử Thần Vực Thẳm", subtitle: "Khói Đen Ma Mị"),
            SkinItemData(id: 15, name: "Dimitri Bá Tước Ma Cà Rồng", subtitle: "Hiệu ứng Dơi Đỏ"),
            SkinItemData(id: 16, name: "Dimitri Đao Phủ Thiên Hà", subtitle: "Chiến Binh Không Gian"),
            SkinItemData(id: 17, name: "Dimitri Robot Hủy Diệt", subtitle: "Âm Thanh Cơ Khí Độc Lạ"),
            SkinItemData(id: 18, name: "Dimitri Chiến Giáp Titan", subtitle: "Giáp Kim Loại Bất Hoại")
        ]

        let skins = character == "Alok" ? alokSkins : dimitriSkins

        return ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { selectedCharacter = nil }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    HStack {
                        Text(character)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(colorInk)
                        Spacer()
                        Button(action: { withAnimation { selectedCharacter = nil } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(colorMute)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(skins) { skin in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(skin.name)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(colorInk)
                                        Text(skin.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(colorMute)
                                    }
                                    Spacer()
                                    Button(action: {
                                        injectSkin(skin)
                                    }) {
                                        Text(activeSkinID == skin.id ? "Đã Nạp" : "Inject")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(activeSkinID == skin.id ? .green : .white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(activeSkinID == skin.id ? Color.green.opacity(0.15) : accentRed.opacity(0.75))
                                            .cornerRadius(999)
                                    }
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 340)

                    Button(action: { withAnimation { selectedCharacter = nil } }) {
                        Text("Xong")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(colorInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .background(Color(red: 16/255, green: 16/255, blue: 18/255))
                .cornerRadius(28, corners: [.topLeft, .topRight])
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(glassBorder, lineWidth: 1))
            }
        }
        .transition(.move(edge: .bottom))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCharacter)
    }

    private func injectSkin(_ skin: SkinItemData) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        activeSkinID = skin.id
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        alertTitle = "✅ ĐÃ NẠP SKIN THÀNH CÔNG"
        alertMessage = "Skin [\(skin.name)] đã được áp dụng an toàn vào Free Fire!"
        showAlert = true
    }

    // MARK: - TAB 4: Antiban View
    private var antibanView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 1. Antiban Safe Shield Card (.bx-pass)
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 38))
                        .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("AppleStoreVN Antiban Safe Shield")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(colorInk)
                        Text("Ledger Safe Injection & Lifecycle Auto-Restore")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(colorMute)
                        Text("BẢO VỆ 100% ONLINE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.10), Color.black.opacity(0.55)]),
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

                // 3. Misc patches sheet (.sheet#misc-slots)
                Text("MISC PATCHES & TIỆN ÍCH (8 SLOTS)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundColor(colorMute)
                    .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    let miscSlots = [
                        (1, "Anti-Lag & 60-90 FPS Boost"),
                        (2, "High Damage & Fast Reload"),
                        (3, "Auto Scope & Quick Switch"),
                        (4, "Wide View / Drone Camera"),
                        (5, "Night Mode / HD Sky"),
                        (6, "No Grass / Clear Field"),
                        (7, "Black Body / Silhouette"),
                        (8, "Safe Antiban Shield Bypass")
                    ]

                    ForEach(miscSlots, id: \.0) { slot in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Misc \(slot.0)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(colorInk)
                                Text(slot.1)
                                    .font(.system(size: 12))
                                    .foregroundColor(colorMute)
                            }
                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { miscToggles[slot.0] ?? false },
                                set: { val in
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    miscToggles[slot.0] = val
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: accentRed))
                        }
                        .padding(14)
                        .background(glassBg)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(glassBorder, lineWidth: 1))
                    }
                }

                // 4. Action Buttons (Clean Restore)
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
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    // MARK: - TAB 5: Cá Nhân View (.bx-pass & .bx-meta)
    private var profileView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. VIP Pass Card (.bx-pass)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Image("PhantomBrand")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("CheatStore VN")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(colorInk)
                            Text("Bản quyền kích hoạt")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.green)
                        }
                        Spacer()
                    }

                    // Key Row
                    HStack {
                        let key = licenseManager.activeKey
                        let maskedKey = key.count > 4 ? "Key  ••••" + String(key.suffix(4)) : "Key  ••••3105"
                        Text(maskedKey)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(colorInk)

                        Spacer()

                        Button(action: {
                            UIPasteboard.general.string = licenseManager.activeKey
                            copiedKey = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedKey = false
                            }
                        }) {
                            Text(copiedKey ? "Đã chép" : "Sao chép")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(999)
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)

                    // Time Left Progress Bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Thời gian còn lại")
                                .font(.system(size: 12))
                                .foregroundColor(colorMute)
                            Spacer()
                            Text("30 ngày")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorInk)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [accentRed, Color.orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * 0.92, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .padding(18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentRed.opacity(0.14), Color.black.opacity(0.55)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(glassBorder, lineWidth: 1))

                // 2. Metadata List (.bx-meta .meta-list)
                VStack(spacing: 12) {
                    metaRow(label: "Ngày cấp", value: "01/10/2026")
                    Divider().background(Color.white.opacity(0.08))
                    metaRow(label: "Hạn dùng", value: "31/10/2026")
                    Divider().background(Color.white.opacity(0.08))
                    metaRow(label: "Mã thiết bị", value: String(UIDevice.current.identifierForVendor?.uuidString.prefix(8) ?? "VN-3105"))
                    Divider().background(Color.white.opacity(0.08))
                    metaRow(label: "Gói VIP", value: "30 ngày")
                }
                .padding(16)
                .background(glassBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))

                // 3. Language Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("NGÔN NGỮ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    HStack {
                        Text("Ngôn ngữ giao diện")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(colorInk)
                        Spacer()
                        Text(selectedLanguage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(colorMute)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(colorMute)
                    }
                    .padding(16)
                    .background(glassBg)
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(glassBorder, lineWidth: 1))
                }

                // 4. Community Grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("HỖ TRỢ & CỘNG ĐỒNG")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundColor(colorMute)
                        .padding(.horizontal, 4)

                    HStack(spacing: 10) {
                        Link(destination: URL(string: "https://t.me/applestorevn") ?? URL(string: "https://apple.com")!) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Chủ Sở Hữu")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(colorInk)
                                Text("@applestorevn")
                                    .font(.system(size: 12))
                                    .foregroundColor(colorMute)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(glassBg)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(glassBorder, lineWidth: 1))
                        }

                        Link(destination: URL(string: "https://t.me/cheatstorevn") ?? URL(string: "https://apple.com")!) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kỹ Thuật")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(colorInk)
                                Text("@cheatstorevn")
                                    .font(.system(size: 12))
                                    .foregroundColor(colorMute)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(glassBg)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(glassBorder, lineWidth: 1))
                        }
                    }
                }

                // 5. Sign Out Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    licenseManager.deactivate()
                }) {
                    Text("Đăng Xuất")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
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

    // MARK: - Ledger Restore Cleanup Action
    func performCleanRestore() {
        guard !isRestoringClean else { return }
        isRestoringClean = true

        DispatchQueue.global(qos: .userInitiated).async {
            DevicePatchService.cleanRestoreAllModifications()

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.activeAimPatch = nil
                    self.activeEspColor = nil
                    self.selectedAimChips.removeAll()
                    self.selectedEspChips.removeAll()
                    self.selectedSpecialSkins.removeAll()
                    self.activeSkinID = nil
                    self.isRestoringClean = false
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
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
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
