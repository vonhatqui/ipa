import SwiftUI
import UIKit

enum CheatStoreTab: Int, CaseIterable {
    case home = 0
    case esp = 1
    case skin = 2
    case profile = 3

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .esp: return "Định Vị"
        case .skin: return "Mod Skin"
        case .profile: return "Cá Nhân"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .esp: return "location.viewfinder"
        case .skin: return "tshirt.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Skin Preview Info Model
struct SkinPreviewInfo: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageURL: String
    let localImageName: String
}

struct CheatStoreDashboardView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    var onBackToGames: (() -> Void)? = nil

    @State private var selectedTab: CheatStoreTab = .home
    @State private var workingPatchID: UUID?
    @State private var appliedProjectIDs: Set<UUID> = []
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var copiedKey = false
    @State private var copiedDeviceID = false
    @State private var previewSkinInfo: SkinPreviewInfo? = nil

    // Cài đặt Định Vị (ESP) & Chế độ Chống Văng 50m
    @AppStorage("esp_distance_mode") private var espDistanceMode: Int = 0 // 0: 50m (Chống Văng), 1: 100m, 2: Toàn Map
    @AppStorage("esp_show_hp") private var espShowHp: Bool = true
    @AppStorage("esp_show_distance") private var espShowDistance: Bool = true
    @AppStorage("esp_show_name") private var espShowName: Bool = true
    @AppStorage("esp_box_type") private var espBoxType: Int = 0 // 0: Khung Box 2D, 1: Tia Snapline
    @State private var selectedEspEngine: Int = 0 // 0: V6 Box 2D (Chống Văng), 1: Laser 2.0
    @State private var isCleaningMemory: Bool = false
    @State private var memoryCleanSuccess: Bool = false

    // Theme: Blossom Dark Sakura (#c084fc & Midnight Purple)
    private let brandBlue = BlossomTheme.sakura         // #c084fc
    private let brandBlueDark = BlossomTheme.sakuraDeep // #a855f7
    private let darkBackground = BlossomTheme.bgBottom  // #09040f
    private let cardBackground = Color(red: 0.082, green: 0.043, blue: 0.137) // #150b23
    private let discordRenewalURL = "https://discord.gg/A3wS4ZPFQn"

    // Phân loại mod
    private func isAimneckVipItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("aimneck") || filename.contains("aimneck") || name.contains("aim neck")
    }

    private func isEspAimheadV3Item(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("aimhead") || filename.contains("aimhead")
    }

    private func isEspItem(_ item: PatchLibraryItem) -> Bool {
        if isEspAimheadV3Item(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("định vị") || name.contains("dinh vi") || name.contains("dinhvi") || name.contains("esp") || name.contains("blue") || filename.contains("network")
    }

    private func isCpanelItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("cpanel") || name.contains("leaked") || filename.contains("cpanel")
    }

    private func isSkinItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("skin") || name.contains("ignis") || name.contains("alock") || name.contains("alok") || name.contains("nạ cỏ") || name.contains("na co") || name.contains("đá bóng") || name.contains("da bong") || filename.contains("skin")
    }

    private func isAimItem(_ item: PatchLibraryItem) -> Bool {
        if isAimneckVipItem(item) || isEspAimheadV3Item(item) || isEspItem(item) || isCpanelItem(item) || isSkinItem(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("aim") || name.contains("drag") || filename.contains("system")
    }

    private var aimneckVipItem: PatchLibraryItem? {
        patchStore.items.first(where: { isAimneckVipItem($0) })
    }

    private var espAimheadV3Item: PatchLibraryItem? {
        patchStore.items.first(where: { isEspAimheadV3Item($0) })
    }

    private var aimItem: PatchLibraryItem? {
        patchStore.items.first(where: { isAimItem($0) })
    }

    private var cpanelItem: PatchLibraryItem? {
        patchStore.items.first(where: { isCpanelItem($0) })
    }

    private var espItem: PatchLibraryItem? {
        patchStore.items.first(where: { isEspItem($0) })
    }

    private var activeEspItem: PatchLibraryItem? {
        if selectedEspEngine == 0 {
            return cpanelItem ?? espItem
        } else {
            return espItem ?? cpanelItem
        }
    }

    private var skinItems: [PatchLibraryItem] {
        patchStore.items.filter { isSkinItem($0) }
    }

    private var aimItems: [PatchLibraryItem] {
        patchStore.items.filter { isAimItem($0) }
    }

    private var espItems: [PatchLibraryItem] {
        patchStore.items.filter { isEspItem($0) }
    }

    var body: some View {
        ZStack {
            // Nền hoa anh đào Blossom chuyển động
            BlossomBackgroundView(showParticles: true)

            VStack(spacing: 0) {
                // Header thanh trên
                topHeaderView

                // Nội dung theo Tab đã chọn
                ZStack {
                    switch selectedTab {
                    case .home:
                        homeView
                    case .esp:
                        espView
                    case .skin:
                        skinView
                    case .profile:
                        profileView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Nút Mở Game Free Fire Nằm Ngay Trên Thanh Dashboard Điều Hướng
                if selectedTab == .home || selectedTab == .esp || selectedTab == .skin {
                    quickLaunchCardView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Thanh Dashboard điều hướng phía dưới
                bottomTabBar

                // Footer thông tin thiết bị & phiên bản iOS & trạng thái hỗ trợ
                deviceStatusFooterView
            }

            // Modal xem trước ảnh Skin
            if let preview = previewSkinInfo {
                SkinImagePreviewModal(
                    info: preview,
                    brandBlue: brandBlue,
                    onClose: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            previewSkinInfo = nil
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Thông báo"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
        .sheet(item: $patchStore.passwordRequest, onDismiss: patchStore.cancelUnlock) { request in
            PatchUnlockView(store: patchStore, request: request)
        }
        .onAppear {
            appliedProjectIDs = DevicePatchService.allAppliedProjectIDs()
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)
        }
    }

    // MARK: - Top Header
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            if let onBackToGames {
                Button {
                    onBackToGames()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text("Ứng Dụng")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(brandBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(brandBlue.opacity(0.12))
                    .cornerRadius(12)
                }
            } else {
                CheatStoreLogoView(size: 34, cornerRadius: 9)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("CheatStore VN")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(brandBlue)
                        .frame(width: 6, height: 6)
                    Text("VIP ĐÃ KÍCH HOẠT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(brandBlue)
                }
            }

            Spacer()

            if selectedTab == .home || selectedTab == .esp || selectedTab == .skin {
                Button {
                    BundledPatchInjector.autoImportBundledPatches(into: patchStore)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(brandBlue)
                        .padding(8)
                        .background(brandBlue.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(darkBackground.opacity(0.85))
    }

    // MARK: - Tab 1: Trang Chủ (Hiện Aim & Mod)
    private var homeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Banner Tiêu Đề
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BẢNG ĐIỀU KHIỂN AIMBOT")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.1)

                        Text("Bật / Tắt AIMDRAG PRO (Bật Sảnh)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // 1. AIMNECK VIP (Chức Năng Trang Chủ Mới Nhất)
                if let vipItem = aimneckVipItem {
                    VStack(spacing: 14) {
                        AimneckVipCard(
                            item: vipItem,
                            isApplied: appliedProjectIDs.contains(vipItem.id),
                            isWorking: workingPatchID == vipItem.id,
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleToggle(item: vipItem, enable: enable)
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }

                // 2. Chức Năng AIMBOT Cổ Điển (AIMDRAG PRO nếu có)
                if let item = aimItem, item.id != aimneckVipItem?.id {
                    VStack(spacing: 14) {
                        CheatItemCard(
                            item: item,
                            isApplied: appliedProjectIDs.contains(item.id),
                            isWorking: workingPatchID == item.id,
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleToggle(item: item, enable: enable)
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                } else if aimneckVipItem == nil {
                    emptyStateView
                }

                // DANH MỤC 2: LỰA CHỌN 2
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LỰA CHỌN 2")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.1)

                        Text("Chức năng bổ trợ chống văng game")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)

                // Danh Sách Bản Mod (Cpanel Leaked)
                if let item = cpanelItem {
                    VStack(spacing: 14) {
                        CpanelItemCard(
                            item: item,
                            isApplied: appliedProjectIDs.contains(item.id),
                            isWorking: workingPatchID == item.id,
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleToggle(item: item, enable: enable)
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }

                // Ghi Chú An Toàn
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 16))
                        .foregroundStyle(brandBlue)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quy trình chuẩn:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Vào game Free Fire > Tại sảnh chờ, gạt BẬT [AIMDRAG PRO] > Bấm [MỞ] Free Fire bên dưới. Bạn có thể sang tab Định Vị để bật song song ESP 2.0!")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                            .lineSpacing(2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brandBlue.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Tab 2: Định Vị (Bảng Điều Khiển ESP Riêng Biệt)
    private var espView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Tiêu đề phần Định Vị
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("BẢNG ĐIỀU KHIỂN ĐỊNH VỊ (ESP PRO)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(brandBlue)
                                .tracking(1.1)

                            Text("V6 AN TOÀN")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.20, green: 0.88, blue: 0.45))
                                .cornerRadius(4)
                        }

                        Text("Bản Nâng Cấp 50m Chống Văng • Hiện Máu & Khoảng Cách")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // 1. ĐỊNH VỊ + AIMHEAD V3 (Chức Năng Định Vị Mới Nhất)
                if let v3Item = espAimheadV3Item {
                    VStack(spacing: 14) {
                        EspAimheadV3Card(
                            item: v3Item,
                            isApplied: appliedProjectIDs.contains(v3Item.id),
                            isWorking: workingPatchID == v3Item.id,
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleToggle(item: v3Item, enable: enable)
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }

                // Banner thông báo Chế độ 50m chống văng
                HStack(spacing: 10) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CHẾ ĐỘ 50M: ĐÃ KÍCH HOẠT CHỐNG VĂNG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))

                        Text("Chỉ quét cự ly giao tranh <= 50m, ngắt lệnh vẽ xa 1000m, triệt tiêu 85% RAM chống văng sau 5-10p.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // Bộ chọn Engine Định Vị
                espEngineSelectorView
                    .padding(.horizontal, 20)

                // Thẻ Kích Hoạt Chính
                if let item = activeEspItem {
                    VStack(spacing: 14) {
                        EspItemCard(
                            item: item,
                            isApplied: appliedProjectIDs.contains(item.id),
                            isWorking: workingPatchID == item.id,
                            brandBlue: brandBlue,
                            selectedEngine: selectedEspEngine,
                            distanceMode: espDistanceMode,
                            showHp: espShowHp,
                            showDistance: espShowDistance,
                            boxType: espBoxType,
                            onToggle: { enable in
                                handleToggle(item: item, enable: enable)
                            }
                        )
                    }
                    .padding(.horizontal, 20)

                    // Widget Mô Phỏng Màn Hình Trận Đấu Trực Quan (Live HUD Simulation)
                    espLiveHUDPreview
                        .padding(.horizontal, 20)

                    // Bộ Lọc Khoảng Cách Quét (Distance Filter Culling)
                    espDistanceSelectorView
                        .padding(.horizontal, 20)

                    // Bộ Tùy Chọn Thành Phần Hiển Thị (Display Customizer)
                    espDisplayOptionsView
                        .padding(.horizontal, 20)

                    // Trình Giám Sát RAM & Nút Xả Bộ Nhớ Đệm Chống Văng (RAM Shield)
                    espRamShieldView
                        .padding(.horizontal, 20)

                    // Hướng Dẫn Quy Trình Chuẩn
                    espSafeWorkflowView
                        .padding(.horizontal, 20)
                } else {
                    emptyEspStateView
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Bộ Chọn Động Cơ Định Vị (Engine Selector)
    private var espEngineSelectorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LỰA CHỌN ĐỘNG CƠ ĐỊNH VỊ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.gray)
                .tracking(0.8)

            HStack(spacing: 8) {
                // Engine 0: V6 Box 2D Chống Văng (Recommended)
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedEspEngine = 0
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 10))
                            Text("Engine V6 Box 2D")
                                .font(.system(size: 11, weight: .bold))
                            Spacer()
                            Text("KHUYÊN DÙNG")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color(red: 0.20, green: 0.88, blue: 0.45))
                                .cornerRadius(3)
                        }
                        Text("Hiện Máu • Khoảng cách • Chống văng")
                            .font(.system(size: 9))
                            .foregroundStyle(selectedEspEngine == 0 ? .white.opacity(0.8) : .gray)
                    }
                    .padding(10)
                    .background(
                        selectedEspEngine == 0
                            ? brandBlue.opacity(0.18)
                            : Color.white.opacity(0.02)
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedEspEngine == 0 ? brandBlue : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Engine 1: Laser 2.0
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedEspEngine = 1
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.viewfinder")
                                .font(.system(size: 10))
                            Text("Engine Laser 2.0")
                                .font(.system(size: 11, weight: .bold))
                            Spacer()
                        }
                        Text("Tia laser truyền thống (Dưới 10p)")
                            .font(.system(size: 9))
                            .foregroundStyle(selectedEspEngine == 1 ? .white.opacity(0.8) : .gray)
                    }
                    .padding(10)
                    .background(
                        selectedEspEngine == 1
                            ? brandBlue.opacity(0.18)
                            : Color.white.opacity(0.02)
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedEspEngine == 1 ? brandBlue : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(brandBlue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Mô phỏng HUD Trận Đấu (Live In-Game HUD Simulation)
    private var espLiveHUDPreview: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("MÔ PHỎNG MÀN HÌNH TRONG TRẬN (HUD ESP)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.8)
                }
                Spacer()
                Text("CỰ LY: 32M <= 50M")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.15))
                    .cornerRadius(4)
            }

            // Game Screen Mockup Frame
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.04, green: 0.02, blue: 0.07))
                    .frame(height: 180)

                // Background radar grid lines
                VStack {
                    Divider().background(Color.white.opacity(0.04))
                    Spacer()
                    Divider().background(Color.white.opacity(0.04))
                    Spacer()
                    Divider().background(Color.white.opacity(0.04))
                }
                .padding(.horizontal, 10)

                // Center crosshair
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.2))

                // Simulated Enemy Target in 32m range
                VStack(spacing: 3) {
                    // 1. Tag Tên & Khoảng cách
                    if espShowName || espShowDistance {
                        HStack(spacing: 4) {
                            if espShowName {
                                Text("Sát Thủ Booyah")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            if espShowDistance {
                                Text("32m")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Color(red: 0.00, green: 0.88, blue: 0.95))
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(4)
                    }

                    // 2. Thanh Máu HP Bar (0 - 200)
                    if espShowHp {
                        VStack(spacing: 1) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 80, height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.20, green: 0.88, blue: 0.45), Color.yellow],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 72, height: 6)
                            }
                            HStack {
                                Text("HP: 180/200")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                                Spacer()
                            }
                            .frame(width: 80)
                        }
                    }

                    // 3. Khung Box 2D hoặc Tia Snapline
                    ZStack {
                        if espBoxType == 0 {
                            // 2D Box
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(red: 0.00, green: 0.88, blue: 0.95), brandBlue],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: 55, height: 75)
                                .background(Color.purple.opacity(0.06))
                        } else {
                            // Snapline
                            VStack {
                                LineShape()
                                    .stroke(Color(red: 0.00, green: 0.88, blue: 0.95), lineWidth: 1.5)
                                    .frame(width: 2, height: 60)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                            }
                            .frame(height: 75)
                        }

                        // Simulated Enemy Figure silhouette
                        Image(systemName: "figure.walk")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                }

                // Top-Left Radar mini badge
                VStack {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "radar")
                                .font(.system(size: 10))
                            Text(espDistanceMode == 0 ? "Bán kính: 50m" : (espDistanceMode == 1 ? "Bán kính: 100m" : "Toàn Map"))
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(brandBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(cardBackground.opacity(0.85))
                        .cornerRadius(6)

                        Spacer()

                        // RAM Shield indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(espDistanceMode == 0 ? Color.green : Color.yellow)
                                .frame(width: 5, height: 5)
                            Text(espDistanceMode == 0 ? "RAM: 320MB (Mượt)" : (espDistanceMode == 1 ? "RAM: 750MB" : "RAM: 1.8GB!"))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(espDistanceMode == 0 ? Color.green : Color.yellow)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(cardBackground.opacity(0.85))
                        .cornerRadius(6)
                    }
                    Spacer()
                }
                .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(brandBlue.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(14)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandBlue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Bộ Chọn Bán Kính Quét (Khoảng Cách Giới Hạn 50m)
    private var espDistanceSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(brandBlue)

                Text("GIỚI HẠN KHOẢNG CÁCH QUÉT (CHỐNG VĂNG)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                // Option 0: 50m (Chế độ máy yếu - Khuyên dùng)
                distanceOptionButton(
                    mode: 0,
                    title: "⚡ 50m - Tiết Kiệm RAM (Máy Yếu) [KHUYÊN DÙNG]",
                    subtitle: "Chỉ quét trong 50m giao tranh. Giảm 85% RAM, chống văng tuyệt đối!",
                    isRecommended: true
                )

                // Option 1: 100m
                distanceOptionButton(
                    mode: 1,
                    title: "🎯 100m - Cân Bằng (Tầm Trung)",
                    subtitle: "Quét bán kính tầm trung, phù hợp máy từ 4GB RAM trở lên.",
                    isRecommended: false
                )

                // Option 2: Full Map
                distanceOptionButton(
                    mode: 2,
                    title: "🔥 Toàn Map - Tầm Xa (Máy Cấu Hình Cao)",
                    subtitle: "⚠️ Cảnh báo: Máy yếu có nguy cơ văng game sau 5-10 phút khi nạp cả map.",
                    isRecommended: false
                )
            }
        }
        .padding(14)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private func distanceOptionButton(mode: Int, title: String, subtitle: String, isRecommended: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                espDistanceMode = mode
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(espDistanceMode == mode ? brandBlue : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 18, height: 18)

                    if espDistanceMode == mode {
                        Circle()
                            .fill(brandBlue)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(espDistanceMode == mode ? .white : .white.opacity(0.85))

                        if isRecommended {
                            Text("AN TOÀN")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1.5)
                                .background(Color(red: 0.20, green: 0.88, blue: 0.45))
                                .cornerRadius(3)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(espDistanceMode == mode ? Color.gray.opacity(0.9) : Color.gray.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(10)
            .background(
                espDistanceMode == mode
                    ? brandBlue.opacity(0.12)
                    : Color.white.opacity(0.02)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(espDistanceMode == mode ? brandBlue.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bộ Tùy Chọn Thành Phần Hiển Thị (Máu, Khoảng cách, Tên)
    private var espDisplayOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(brandBlue)

                Text("TÙY CHỈNH THÀNH PHẦN ĐỊNH VỊ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                // Toggle Máu
                espToggleRow(
                    icon: "heart.fill",
                    iconColor: Color.red,
                    title: "Hiện Thanh Máu & Chỉ Số HP (0 - 200)",
                    subtitle: "Thanh máu trực quan trên đầu mục tiêu, cập nhật theo thời gian thực",
                    isOn: $espShowHp
                )

                Divider().background(Color.white.opacity(0.06))

                // Toggle Khoảng Cách
                espToggleRow(
                    icon: "ruler.fill",
                    iconColor: Color(red: 0.00, green: 0.88, blue: 0.95),
                    title: "Hiện Khoảng Cách Mét (<= 50m)",
                    subtitle: "Hiện số mét chính xác theo từng bước chân (Ví dụ: 12m, 35m, 48m)",
                    isOn: $espShowDistance
                )

                Divider().background(Color.white.opacity(0.06))

                // Toggle Tên
                espToggleRow(
                    icon: "person.text.rectangle.fill",
                    iconColor: brandBlue,
                    title: "Hiện Tên Kẻ Địch (Player Tag)",
                    subtitle: "Nhận diện tên và ID của kẻ địch xuyên vật cản",
                    isOn: $espShowName
                )

                Divider().background(Color.white.opacity(0.06))

                // Kiểu Dáng: Box 2D vs Snapline
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: espBoxType == 0 ? "viewfinder" : "line.diagonal")
                            .font(.system(size: 14))
                            .foregroundStyle(brandBlue)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Kiểu Dáng Hiển Thị")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                            Text(espBoxType == 0 ? "Khung Hộp 2D Box (Gọn nhẹ)" : "Tia Dẫn Đường (Snapline)")
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                        }
                    }

                    Spacer()

                    Picker("", selection: $espBoxType) {
                        Text("Box 2D").tag(0)
                        Text("Tia Line").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private func espToggleRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(brandBlue)
        }
    }

    // MARK: - Trình Giám Sát RAM Shield & Tối Ưu Tức Thì
    private var espRamShieldView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))

                Text("TRÌNH BẢO VỆ BỘ NHỚ RAM (RAM SHIELD)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("60 FPS MƯỢT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
            }

            // So sánh RAM cũ vs mới
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chế độ Cũ (Full Map):")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.gray)
                    Text("~1.85 GB RAM ❌")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))
                    Text("Nguy cơ văng sau 5-10p")
                        .font(.system(size: 9))
                        .foregroundStyle(.gray.opacity(0.8))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chế độ Mới (<= 50m):")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.gray)
                    Text("~320 MB RAM ✅")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                    Text("An toàn tuyệt đối 100%")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.8))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.08))
                .cornerRadius(8)
            }

            // Nút Xả Bộ Nhớ Đệm RAM
            Button {
                cleanRamAction()
            } label: {
                HStack(spacing: 8) {
                    if isCleaningMemory {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: memoryCleanSuccess ? "checkmark.circle.fill" : "bolt.fill")
                            .font(.system(size: 13, weight: .bold))
                    }

                    Text(memoryCleanSuccess ? "ĐÃ XẢ BỘ NHỚ RAM THÀNH CÔNG!" : "XẢ BỘ NHỚ ĐỆM & TỐI ƯU RAM NGAY")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(memoryCleanSuccess ? Color.green : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    memoryCleanSuccess
                        ? Color.green.opacity(0.15)
                        : brandBlue.opacity(0.2)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(memoryCleanSuccess ? Color.green.opacity(0.5) : brandBlue.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isCleaningMemory)
        }
        .padding(14)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private func cleanRamAction() {
        isCleaningMemory = true
        memoryCleanSuccess = false
        URLCache.shared.removeAllCachedResponses()
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 0.8)
            DispatchQueue.main.async {
                withAnimation {
                    self.isCleaningMemory = false
                    self.memoryCleanSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        self.memoryCleanSuccess = false
                    }
                }
            }
        }
    }

    // MARK: - Quy Trình Chuẩn Chống Văng Game
    private var espSafeWorkflowView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 16))
                .foregroundStyle(brandBlue)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Quy trình chuẩn cho máy yếu:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Text("1. Thoát hẳn Free Fire khỏi đa nhiệm.\n2. Chọn chế độ [⚡ 50m Chống Văng] > Bấm [Xả RAM] > Bật [ESP PRO].\n3. Bấm nút [MỞ] Free Fire bên dưới để vào trận mượt mà không lo bị văng!")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(brandBlue.opacity(0.25), lineWidth: 1)
        )
    }

    private func featureBullet(text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 0.00, green: 0.88, blue: 0.95))
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var emptyEspStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(brandBlue.opacity(0.15))
                    .frame(width: 110, height: 110)
                    .blur(radius: 20)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardBackground)
                    .frame(width: 86, height: 86)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(brandBlue.opacity(0.4), lineWidth: 1.5)
                    )

                Image(systemName: "location.viewfinder")
                    .font(.system(size: 40))
                    .foregroundStyle(brandBlue)
            }

            VStack(spacing: 8) {
                Text("ĐỊNH VỊ (ESP)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Đang kiểm tra và tải cấu hình tài nguyên hệ thống. Vui lòng bấm Quét lại hoặc khởi động lại app.")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
            }

            Button {
                BundledPatchInjector.autoImportBundledPatches(into: patchStore)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Quét lại dữ liệu")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 46)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(
                        colors: [brandBlue, brandBlueDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: brandBlue.opacity(0.4), radius: 8)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding(.horizontal, 20)
    }



    // MARK: - Tab 3: Mod Skin (Trang Phục VIP Độc Quyền)
    private var skinView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Tiêu đề phần Mod Skin
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BẢNG ĐIỀU KHIỂN MOD TRANG PHỤC")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.1)

                        Text("Bật / Tắt Skin VIP Độc Quyền • Vào Game Là Có Ngay")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Danh Sách Bản Mod Skin
                if !skinItems.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(skinItems) { item in
                            SkinItemCard(
                                item: item,
                                isApplied: appliedProjectIDs.contains(item.id),
                                isWorking: workingPatchID == item.id,
                                brandBlue: brandBlue,
                                onToggle: { enable in
                                    handleToggle(item: item, enable: enable)
                                },
                                onPreview: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        previewSkin(for: item)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    emptySkinStateView
                }

                // Thông tin tính năng Mod Skin
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(brandBlue)

                        Text("Đặc Quyền Mod Skin VIP")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        featureBullet(text: "Kích hoạt hiệu ứng trang phục đặc biệt trong trận đấu")
                        featureBullet(text: "Mỗi skin tác động tệp avatar độc lập, có thể bật cùng lúc")
                        featureBullet(text: "Tương thích 100% khi bật song song với AIMDRAG & ESP / Cpanel")
                        featureBullet(text: "Cơ chế Golden Snapshot bảo vệ & phục hồi dữ liệu gốc an toàn")
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brandBlue.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)

                // Hướng dẫn quy trình
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 16))
                        .foregroundStyle(brandBlue)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quy trình chuẩn:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Gạt BẬT Skin mong muốn > Bấm nút [MỞ] Free Fire bên dưới. Bạn có thể bật song song cả 2 skin và kết hợp cùng Aim/ESP mượt mà!")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                            .lineSpacing(2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brandBlue.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
    }

    private var emptySkinStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "tshirt")
                .font(.system(size: 40))
                .foregroundStyle(.gray)
                .padding(.top, 30)

            Text("Đang tải dữ liệu Mod Skin...")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Button {
                BundledPatchInjector.autoImportBundledPatches(into: patchStore)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Quét lại skin")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(brandBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(brandBlue.opacity(0.12))
                .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Tab 4: Cá Nhân (Thời Hạn Key, Gia Hạn, Đăng Xuất)
    private var profileView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Cá Nhân
                VStack(spacing: 12) {
                    CheatStoreLogoView(size: 76, cornerRadius: 20)
                        .padding(.top, 10)

                    Text("TÀI KHOẢN CHEATSTORE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(brandBlue)
                            .frame(width: 8, height: 8)
                        Text(licenseManager.planName.isEmpty ? "GÓI VIP" : licenseManager.planName.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(brandBlue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(brandBlue.opacity(0.12))
                    .cornerRadius(20)
                }

                // Card Chi Tiết Bản Quyền
                VStack(spacing: 14) {
                    // Thời hạn sử dụng
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THỜI HẠN SỬ DỤNG")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.gray)

                            if let expiry = licenseManager.expirationDate {
                                Text(formattedDate(expiry))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Thời hạn còn lại: \(licenseManager.formattedRemainingTime)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(brandBlue)
                            } else {
                                Text("Đã Kích Hoạt")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 24))
                            .foregroundStyle(brandBlue)
                    }

                    Divider().background(Color.white.opacity(0.08))

                    // Mã Key hiện tại
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MÃ KEY ĐANG DÙNG")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.gray)

                            Text(licenseManager.activeKey)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = licenseManager.activeKey
                            copiedKey = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.copiedKey = false
                            }
                        } label: {
                            Text(copiedKey ? "Đã chép" : "Sao chép")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(brandBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(brandBlue.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }

                    Divider().background(Color.white.opacity(0.08))

                    // Mã Thiết Bị (Device ID)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MÃ THIẾT BỊ (DEVICE ID)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.gray)

                            Text(licenseManager.deviceID)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = licenseManager.deviceID
                            copiedDeviceID = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.copiedDeviceID = false
                            }
                        } label: {
                            Text(copiedDeviceID ? "Đã chép" : "Sao chép")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(brandBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(brandBlue.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                    Divider().background(Color.white.opacity(0.08))

                    // Thiết Bị Đang Dùng
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THIẾT BỊ ĐANG DÙNG")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.gray)

                            Text(AppInfo.hardwareDisplayName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 20))
                            .foregroundStyle(brandBlue)
                    }

                    Divider().background(Color.white.opacity(0.08))

                    // Phiên bản iOS & Hỗ trợ
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PHIÊN BẢN HỆ ĐIỀU HÀNH")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.gray)

                            Text("iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        if isDeviceSupported {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Có hỗ trợ")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.12))
                            .cornerRadius(8)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Không hỗ trợ")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 1.00, green: 0.28, blue: 0.28).opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
                .background(cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(brandBlue.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // Nút Gia Hạn Key Qua Zalo & Discord
                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "https://zalo.me/0365829172") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "message.fill")
                            Text("Gia Hạn Zalo")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [brandBlue, brandBlueDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: brandBlue.opacity(0.4), radius: 8)
                    }

                    Button {
                        if let url = URL(string: discordRenewalURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Discord")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)

                // Nút Đăng Xuất Key
                Button {
                    licenseManager.deactivate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Đăng Xuất Khỏi Thiết Bị")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Thanh Dashboard Dưới (Bottom Navigation Bar)
    private var bottomTabBar: some View {
        HStack {
            ForEach(CheatStoreTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: selectedTab == tab ? .bold : .regular))
                            .foregroundStyle(selectedTab == tab ? brandBlue : Color.gray.opacity(0.6))
                            .shadow(color: selectedTab == tab ? brandBlue.opacity(0.8) : .clear, radius: 6)

                        Text(tab.title)
                            .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(selectedTab == tab ? .white : Color.gray.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? brandBlue.opacity(0.12)
                            : Color.clear
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardBackground.opacity(0.96))
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(brandBlue.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    // MARK: - Footer: Thông Tin Thiết Bị & Phiên Bản iOS & Trạng Thái Hỗ Trợ
    private var isDeviceSupported: Bool {
        let v = AppInfo.versionTuple
        return ExploitSupportPolicy.isSupported(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
    }

        private var deviceStatusFooterView: some View {
        HStack(spacing: 8) {
            // Tên máy hiện tại (Ví dụ: iPhone 13 Pro Max)
            HStack(spacing: 4) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(brandBlue)

                Text(AppInfo.hardwareDisplayName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            if isDeviceSupported {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Có hỗ trợ")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.12))
                .cornerRadius(6)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Không hỗ trợ")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(red: 1.00, green: 0.28, blue: 0.28).opacity(0.12))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 1.00, green: 0.28, blue: 0.28).opacity(0.3), lineWidth: 0.8)
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardBackground.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [brandBlue.opacity(0.25), Color.white.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 0.8
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.gray)
                .padding(.top, 30)

            Text("Chưa tìm thấy bản mod nào")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text("Đang kiểm tra và tải cấu hình tài nguyên hệ thống. Vui lòng bấm Quét lại hoặc khởi động lại app.")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button {
                BundledPatchInjector.autoImportBundledPatches(into: patchStore)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Quét lại bản mod")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(brandBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(brandBlue.opacity(0.12))
                .cornerRadius(20)
            }
            .padding(.top, 6)
        }
    }

    private func resolveProject(for item: PatchLibraryItem) -> PatchProject? {
        if let project = item.project {
            return project
        }
        let candidatePasswords: [String?] = [nil, "Canhcupin", "Canhcubin", "canhcupin", "canhcubin", "CanhCuPin", "CanhCuBin"]

        // 1. Thử giải mã từ packageURL của item
        if let data = try? PatchProjectLibrary.readPackage(at: item.packageURL) {
            for pwd in candidatePasswords {
                if let decoded = try? PatchPackageCodec.decode(data, password: pwd) {
                    try? PatchKeyStore.store(decoded.contentKey, for: item.summary)
                    return decoded.project
                }
            }
        }

        // 2. Thử quét tìm trong AppCore của Bundle
        var candidateURLs: [URL] = []
        let coreDir1 = Bundle.main.bundleURL.appendingPathComponent("AppCore")
        if let files = try? FileManager.default.contentsOfDirectory(at: coreDir1, includingPropertiesForKeys: nil) {
            candidateURLs.append(contentsOf: files)
        }
        if let resURL = Bundle.main.resourceURL?.appendingPathComponent("AppCore"), resURL != coreDir1 {
            if let files = try? FileManager.default.contentsOfDirectory(at: resURL, includingPropertiesForKeys: nil) {
                candidateURLs.append(contentsOf: files)
            }
        }
        for file in candidateURLs where ["dat", "bin", "3105"].contains(file.pathExtension.lowercased()) {
            if let data = try? PatchProjectLibrary.readPackage(at: file) {
                for pwd in candidatePasswords {
                    if let decoded = try? PatchPackageCodec.decode(data, password: pwd),
                       decoded.project.id == item.id || decoded.project.name.lowercased().contains(item.id.uuidString.lowercased()) {
                        try? PatchKeyStore.store(decoded.contentKey, for: item.summary)
                        return decoded.project
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Toggle Mod Action
    private func handleToggle(item: PatchLibraryItem, enable: Bool) {
        let currentID = item.id
        workingPatchID = currentID
        let modName = displayName(for: item)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if enable {
                    // BẬT chức năng (Apply)
                    // Xử lý xung đột file: Cpanel Leaked, ESP 2.0 và ESP+AimHead V3 cùng sửa Assembly-CSharp & localConfig
                    if self.isCpanelItem(item) || self.isEspItem(item) || self.isEspAimheadV3Item(item) {
                        let assemblyMods = [self.espItem, self.cpanelItem, self.espAimheadV3Item].compactMap { $0 }
                        for other in assemblyMods where other.id != item.id && self.appliedProjectIDs.contains(other.id) {
                            let otherProj = self.resolveProject(for: other)
                            if let receipt = DevicePatchService.latestReceipt(projectID: other.id) {
                                _ = try? DevicePatchService.restore(receipt: receipt, project: otherProj, allowChangedTargets: true)
                            } else {
                                DevicePatchService.forceCleanup(project: otherProj)
                            }
                        }
                    }

                    let targetProject = self.resolveProject(for: item)

                    guard let project = targetProject else {
                        throw PatchPackageError.unsupportedFormat
                    }

                    // Thực hiện Apply bản mod vào game (tự động chụp Golden Snapshot bảo vệ dữ liệu gốc)
                    _ = try DevicePatchService.apply(project: project)

                    DispatchQueue.main.async {
                        guard self.workingPatchID == currentID else { return }
                        self.appliedProjectIDs = DevicePatchService.allAppliedProjectIDs()
                        self.patchStore.reload()
                        self.workingPatchID = nil
                        self.alertMessage = "Đã BẬT thành công: \(modName)\n\n⚠️ LƯU Ý: Hãy vuốt tắt hẳn game Free Fire trong đa nhiệm rồi mở lại để vào trận mượt mà không văng game!"
                        self.showAlert = true
                    }
                } else {
                    // TẮT chức năng (Restore 100% dữ liệu gốc sạch)
                    let restoreProject = self.resolveProject(for: item)

                    let receipt = DevicePatchService.latestReceipt(projectID: item.id)
                    if let receipt = receipt {
                        do {
                            try DevicePatchService.restore(receipt: receipt, project: restoreProject, allowChangedTargets: true)
                        } catch {
                            // Fallback phục hồi cưỡng chế từ Golden Snapshots
                            DevicePatchService.forceRestoreAndCleanup(receipt: receipt, project: restoreProject)
                        }
                    } else {
                        // Không tìm thấy receipt nhưng bấm tắt -> khôi phục sạch qua Golden Snapshots
                        DevicePatchService.forceCleanup(project: restoreProject)
                    }

                    DispatchQueue.main.async {
                        guard self.workingPatchID == currentID else { return }
                        self.appliedProjectIDs = DevicePatchService.allAppliedProjectIDs()
                        self.patchStore.reload()
                        self.workingPatchID = nil
                        self.alertMessage = "Đã TẮT và khôi phục an toàn 100%: \(modName)"
                        self.showAlert = true
                    }
                }
            } catch {
                // Tự động hoàn tác về trạng thái gốc sạch nếu quá trình bật gặp sự cố
                if enable {
                    let fallbackProject = self.resolveProject(for: item) ?? item.project
                    DevicePatchService.forceRestoreAndCleanup(receipt: nil, project: fallbackProject)
                }

                DispatchQueue.main.async {
                    guard self.workingPatchID == currentID else { return }
                    self.appliedProjectIDs = DevicePatchService.allAppliedProjectIDs()
                    self.patchStore.reload()
                    self.workingPatchID = nil
                    let friendlyError = self.userFriendlyErrorMessage(error)
                    self.alertMessage = "Thao tác thất bại: \(friendlyError)"
                    self.showAlert = true
                }
            }
        }
    }

    private func previewSkin(for item: PatchLibraryItem) {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        if name.contains("ignis") {
            previewSkinInfo = SkinPreviewInfo(
                title: "Mod Skin Ignis",
                subtitle: "Trang phục Đạo Sĩ Đỏ cực ngầu cho tướng Ignis",
                imageURL: "https://files.catbox.moe/0kjz3x.jpeg",
                localImageName: "skin_ignis"
            )
        } else {
            previewSkinInfo = SkinPreviewInfo(
                title: "Mod Skin Alock Thất tỉnh",
                subtitle: "Bộ trang phục Alock Thất Tỉnh (Nạ Cỏ - Áo Đá Bóng)",
                imageURL: "https://files.catbox.moe/6cit3j.png",
                localImageName: "skin_naco"
            )
        }
    }

    private func displayName(for item: PatchLibraryItem) -> String {
        if isAimneckVipItem(item) {
            return "AIMNECK VIP"
        }
        if isEspAimheadV3Item(item) {
            return "ĐỊNH VỊ + AIMHEAD V3"
        }
        if isEspItem(item) {
            return "ESP 2.0"
        }
        if isCpanelItem(item) {
            return "Cpanel Leaked"
        }
        if isSkinItem(item) {
            return item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
        }
        return "AIMDRAG PRO"
    }

    private func userFriendlyErrorMessage(_ error: Error) -> String {
        if let patchError = error as? PatchPackageError {
            switch patchError {
            case .targetAppUnavailable(let bundleID):
                return "Không tìm thấy dữ liệu game Free Fire (\(bundleID)). Vui lòng kiểm tra đã cài game Free Fire hoặc Free Fire MAX và đã mở game ít nhất một lần!"
            case .projectAlreadyApplied:
                return "Chức năng này đã được áp dụng trước đó. Vui lòng tắt đi rồi bật lại."
            case .applyFailed:
                return "Không thể ghi dữ liệu mod vào game. Vui lòng mở game Free Fire một lần trước hoặc khởi động lại thiết bị rồi thử lại!"
            case .restoreFailed:
                return "Đã xảy ra lỗi khi khôi phục, hệ thống đã tự động dọn dẹp sạch bản mod an toàn."
            case .restoreTargetsChanged:
                return "File game đã được cập nhật khi chơi. Hệ thống đã khôi phục bản sạch an toàn."
            case .unsupportedFormat:
                return "Dữ liệu cấu hình mod không hợp lệ hoặc đang bị khoá."
            default:
                return patchError.localizedDescription
            }
        }
        return error.localizedDescription
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Khởi Chạy Nhanh Game Free Fire
    private var isAnyModActive: Bool {
        !appliedProjectIDs.isEmpty
    }

    private var quickLaunchCardView: some View {
        Button {
            launchFreeFire()
        } label: {
            HStack(spacing: 14) {
                // Icon Free Fire với hiệu ứng viền phát sáng
                ZStack {
                    FreeFireAppIconView(size: 48, cornerRadius: 12)

                    if isAnyModActive {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [BlossomTheme.sakuraLight, brandBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 48, height: 48)
                    }
                }
                .shadow(color: isAnyModActive ? brandBlue.opacity(0.6) : Color.clear, radius: 8)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Free Fire")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)

                        if isAnyModActive {
                            Text("SẴN SÀNG")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        } else {
                            Text("OFFLINE")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(Color.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(4)
                        }
                    }

                    Text(isAnyModActive ? "Dữ liệu mod đã nạp • Sẵn sàng chiến" : "Chưa nạp dữ liệu mod • Vào game thường")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isAnyModActive ? BlossomTheme.sakuraLight : Color.gray)
                        .lineLimit(1)
                }

                Spacer()

                // Nút MỞ thay thế cho mũi tên theo yêu cầu
                Text("MỞ")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [BlossomTheme.sakuraDeep, brandBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: brandBlue.opacity(0.55), radius: 6, x: 0, y: 2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.07, blue: 0.23),
                                cardBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isAnyModActive
                            ? BlossomTheme.sakuraLight.opacity(0.7)
                            : brandBlue.opacity(0.25),
                        lineWidth: isAnyModActive ? 1.5 : 1
                    )
            )
            .shadow(color: isAnyModActive ? brandBlue.opacity(0.3) : Color.black.opacity(0.3), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func launchFreeFire() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let targetSchemes = [
            "freefire://",
            "freefireth://",
            "freefiremax://",
            "dtsfreefire://"
        ]

        for scheme in targetSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("[CheatStore VN] Đã mở Free Fire qua: \(scheme)")
                    }
                }
                return
            }
        }

        // Nếu canOpenURL chưa bắt được do policy iOS, thử mở trực tiếp freefire://
        if let defaultURL = URL(string: "freefire://") {
            UIApplication.shared.open(defaultURL, options: [:]) { success in
                if success { return }

                // Thử mở Free Fire MAX
                if let maxURL = URL(string: "freefiremax://") {
                    UIApplication.shared.open(maxURL, options: [:]) { maxSuccess in
                        if !maxSuccess {
                            DispatchQueue.main.async {
                                self.alertMessage = "Đã nạp mod thành công! Thiết bị không hỗ trợ chuyển tiếp tự động, bạn vui lòng bấm mở Free Fire từ màn hình chính."
                                self.showAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - FeatureImageView (Tải ảnh sắc nét từ Assets.xcassets hoặc AppCore/Assets)
private struct FeatureImageView: View {
    let name: String
    var cornerRadius: CGFloat = 16

    private var uiImage: UIImage? {
        if let img = UIImage(named: name) {
            return img
        }
        if let resPath = Bundle.main.resourcePath {
            let appCoreAssets = (resPath as NSString).appendingPathComponent("AppCore/Assets")
            let extList = ["jpg", "jpeg", "png"]
            for ext in extList {
                let p = (appCoreAssets as NSString).appendingPathComponent("\(name).\(ext)")
                if let img = UIImage(contentsOfFile: p) { return img }
            }
        }
        if let path = Bundle.main.path(forResource: name, ofType: "jpg") ??
                      Bundle.main.path(forResource: name, ofType: "jpeg") ??
                      Bundle.main.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    var body: some View {
        if let img = uiImage {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(cornerRadius)
        } else {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color(red: 0.14, green: 0.07, blue: 0.23)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(cornerRadius)
        }
    }
}

// MARK: - AimneckVipCard (Chức Năng Trang Chủ VIP)
private struct AimneckVipCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner Ảnh Tạo Mới Cực Đẹp
            ZStack(alignment: .topTrailing) {
                FeatureImageView(name: "aimneck_vip", cornerRadius: 16)
                    .frame(height: 155)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.2),
                                Color(red: 0.082, green: 0.043, blue: 0.137)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Badges Góc Phải
                HStack(spacing: 6) {
                    Text("BẬT SẢNH")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(6)

                    Text("VIP EDITION")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [BlossomTheme.sakuraDeep, brandBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                }
                .padding(10)
            }

            // Nội dung điều khiển
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("AIMNECK VIP")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Circle()
                                .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                                .frame(width: 8, height: 8)

                            Text(isApplied ? "ĐÃ NẠP" : "CHƯA NẠP")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isApplied ? Color.green : .gray)
                        }

                        Text("Khóa Cổ Siêu Dính • Kéo Tâm Mượt • An Toàn")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(brandBlue.opacity(0.9))
                    }

                    Spacer()

                    // Nút Bật/Tắt Switch
                    if isWorking {
                        ProgressView()
                            .tint(brandBlue)
                            .frame(width: 50)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { isApplied },
                            set: { newValue in onToggle(newValue) }
                        ))
                        .labelsHidden()
                        .tint(brandBlue)
                    }
                }

                // Chi tiết tính năng tags
                HStack(spacing: 8) {
                    Label("Ghim Tâm", systemImage: "scope")
                    Label("Bật Sảnh", systemImage: "bolt.fill")
                    Label("Anti-Ban", systemImage: "shield.fill")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
            }
            .padding(14)
        }
        .background(Color(red: 0.082, green: 0.043, blue: 0.137))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isApplied
                        ? LinearGradient(colors: [BlossomTheme.sakuraLight, brandBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: isApplied ? 1.8 : 1
                )
        )
        .shadow(color: isApplied ? brandBlue.opacity(0.35) : Color.black.opacity(0.25), radius: 10, y: 4)
    }
}

// MARK: - EspAimheadV3Card (Chức Năng Định Vị + AimHead V3)
private struct EspAimheadV3Card: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner Ảnh Radar HUD Mới Cực Đẹp
            ZStack(alignment: .topTrailing) {
                FeatureImageView(name: "esp_aimhead_v3", cornerRadius: 16)
                    .frame(height: 155)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.2),
                                Color(red: 0.082, green: 0.043, blue: 0.137)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Badges Góc Phải
                HStack(spacing: 6) {
                    Text("HOT V3")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.9))
                        .cornerRadius(6)

                    Text("BẬT NGOÀI GAME")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.85, green: 0.20, blue: 0.65), brandBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                }
                .padding(10)
            }

            // Nội dung điều khiển
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("ĐỊNH VỊ + AIMHEAD V3")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Circle()
                                .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                                .frame(width: 8, height: 8)

                            Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isApplied ? Color.green : .gray)
                        }

                        Text("Khung Định Vị Head 3D • Khóa Đầu Chuẩn Xác 100%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(brandBlue.opacity(0.9))
                    }

                    Spacer()

                    // Nút Bật/Tắt Switch
                    if isWorking {
                        ProgressView()
                            .tint(brandBlue)
                            .frame(width: 50)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { isApplied },
                            set: { newValue in onToggle(newValue) }
                        ))
                        .labelsHidden()
                        .tint(brandBlue)
                    }
                }

                // Chi tiết tính năng tags
                HStack(spacing: 8) {
                    Label("ESP Head 3D", systemImage: "viewfinder")
                    Label("Auto AimHead", systemImage: "target")
                    Label("Ngoài Game", systemImage: "iphone")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
            }
            .padding(14)
        }
        .background(Color(red: 0.082, green: 0.043, blue: 0.137))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isApplied
                        ? LinearGradient(colors: [Color(red: 0.85, green: 0.20, blue: 0.65), brandBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: isApplied ? 1.8 : 1
                )
        )
        .shadow(color: isApplied ? brandBlue.opacity(0.35) : Color.black.opacity(0.25), radius: 10, y: 4)
    }
}

// MARK: - CheatItemCard (Định Vị & AimNeck 2.0)
private struct CheatItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    private var displayName: String {
        "AIMDRAG PRO"
    }

    private var subtitle: String {
        "Kéo Tâm Siêu Chuẩn • Bật Ngay Tại Sảnh"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon chức năng với logo CheatStore
            ZStack {
                CheatStoreLogoView(size: 48, cornerRadius: 12)

                if isApplied {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brandBlue, lineWidth: 2)
                        .frame(width: 48, height: 48)
                }
            }

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("PRO")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [BlossomTheme.sakuraDeep, Color(red: 0.45, green: 0.20, blue: 0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }

                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(brandBlue)

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 6, height: 6)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Nút Bật / Tắt Switch
            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 50)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(brandBlue)
            }
        }
        .padding(14)
        .background(Color(red: 0.082, green: 0.043, blue: 0.137))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? brandBlue.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - LineShape Helper
private struct LineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - EspItemCard (Định Vị Xuyên Tường VIP)
private struct EspItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    var selectedEngine: Int = 0
    var distanceMode: Int = 0
    var showHp: Bool = true
    var showDistance: Bool = true
    var boxType: Int = 0
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                // Radar Icon với hiệu ứng phát sáng
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    BlossomTheme.sakuraLight.opacity(isApplied ? 0.25 : 0.12),
                                    brandBlue.opacity(isApplied ? 0.2 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isApplied
                                        ? BlossomTheme.sakuraLight
                                        : brandBlue.opacity(0.4),
                                    lineWidth: isApplied ? 1.8 : 1
                                )
                        )

                    Image(systemName: "location.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isApplied ? BlossomTheme.sakuraLight : brandBlue)
                }

                // Tên và thông tin chức năng
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(selectedEngine == 0 ? "ESP V6 PRO" : "ESP 2.0")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(selectedEngine == 0 ? "50M CHỐNG VĂNG" : "LASER XUYÊN TƯỜNG")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: selectedEngine == 0
                                        ? [Color(red: 0.20, green: 0.88, blue: 0.45), brandBlue]
                                        : [Color(red: 0.00, green: 0.88, blue: 0.95), brandBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(4)
                    }

                    Text(selectedEngine == 0 ? "Khung Box 2D • Hiện Máu • Khoảng Cách Mét" : "Tia Dẫn Đường • Định Vị Xuyên Bản Đồ")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.00, green: 0.88, blue: 0.95))

                    // Trạng thái Bật / Tắt
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                            .frame(width: 6, height: 6)

                        Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isApplied ? Color.green : .gray)
                    }
                    .padding(.top, 1)
                }

                Spacer()

                // Nút Bật / Tắt Switch
                if isWorking {
                    ProgressView()
                        .tint(brandBlue)
                        .frame(width: 50)
                } else {
                    Toggle("", isOn: Binding(
                        get: { isApplied },
                        set: { newValue in
                            onToggle(newValue)
                        }
                    ))
                    .labelsHidden()
                    .tint(brandBlue)
                }
            }

            // Badges trạng thái cấu hình hiện tại
            HStack(spacing: 6) {
                // Cự ly badge
                HStack(spacing: 3) {
                    Image(systemName: "ruler")
                        .font(.system(size: 8))
                    Text(distanceMode == 0 ? "Cự ly 50m (Chống Văng)" : (distanceMode == 1 ? "Cự ly 100m" : "Toàn Map"))
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(distanceMode == 0 ? Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.15) : Color.white.opacity(0.06))
                .foregroundStyle(distanceMode == 0 ? Color(red: 0.20, green: 0.88, blue: 0.45) : .gray)
                .cornerRadius(4)

                if showHp {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                        Text("Hiện Máu HP")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(Color.red)
                    .cornerRadius(4)
                }

                if showDistance {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text("Khoảng Cách Mét")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color(red: 0.00, green: 0.88, blue: 0.95).opacity(0.12))
                    .foregroundStyle(Color(red: 0.00, green: 0.88, blue: 0.95))
                    .cornerRadius(4)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color(red: 0.082, green: 0.043, blue: 0.137))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? BlossomTheme.sakura.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? brandBlue.opacity(0.2) : .clear, radius: 8)
    }
}

// MARK: - CpanelItemCard (Lựa Chọn 2: Cpanel Leaked)
private struct CpanelItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon chức năng
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                BlossomTheme.sakuraLight.opacity(isApplied ? 0.25 : 0.12),
                                brandBlue.opacity(isApplied ? 0.2 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isApplied
                                    ? BlossomTheme.sakuraLight
                                    : brandBlue.opacity(0.4),
                                lineWidth: isApplied ? 1.8 : 1
                            )
                    )

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isApplied ? BlossomTheme.sakuraLight : brandBlue)
            }

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Cpanel Leaked")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("LEAKED")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.40, blue: 0.20), BlossomTheme.sakuraDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }

                Text("không muốn văng game thì cùng cái này nhé.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BlossomTheme.sakuraLight)
                    .lineLimit(1)

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 6, height: 6)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Nút Bật / Tắt Switch
            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 50)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(brandBlue)
            }
        }
        .padding(14)
        .background(Color(red: 0.082, green: 0.043, blue: 0.137))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? BlossomTheme.sakura.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? brandBlue.opacity(0.2) : .clear, radius: 8)
    }
}

// MARK: - SkinItemCard (Mod Skin VIP)
private struct SkinItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void
    let onPreview: () -> Void

    private var skinTitle: String {
        item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
    }

    private var skinSubtitle: String {
        let n = skinTitle.lowercased()
        if n.contains("ignis") {
            return "Trang phục Đạo Sĩ Đỏ cực ngầu cho tướng Ignis"
        } else if n.contains("alock") || n.contains("alok") || n.contains("nạ cỏ") || n.contains("đá bóng") {
            return "Bộ trang phục Alock Thất Tỉnh (Nạ Cỏ - Áo Đá Bóng)"
        }
        return "Trang phục VIP độc quyền trong trận"
    }

    private var skinBadge: String {
        let n = skinTitle.lowercased()
        if n.contains("ignis") {
            return "HOT SKIN"
        }
        return "VIP SKIN"
    }

    private var localImageName: String {
        let n = skinTitle.lowercased()
        if n.contains("ignis") { return "skin_ignis" }
        return "skin_naco"
    }

    private var localUIImage: UIImage? {
        if let img = UIImage(named: localImageName) ??
                     UIImage(named: localImageName == "skin_ignis" ? "SkinIgnis" : "SkinNaco") {
            return img
        }
        if let resPath = Bundle.main.resourcePath {
            let appCoreAssets = (resPath as NSString).appendingPathComponent("AppCore/Assets")
            let extList = ["jpeg", "png", "jpg"]
            for ext in extList {
                let p = (appCoreAssets as NSString).appendingPathComponent("\(localImageName).\(ext)")
                if let img = UIImage(contentsOfFile: p) { return img }
            }
        }
        if let path = Bundle.main.path(forResource: localImageName, ofType: "jpeg") ??
                      Bundle.main.path(forResource: localImageName, ofType: "png") ??
                      Bundle.main.path(forResource: localImageName, ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail / Icon với hiệu ứng viền phát sáng (Bấm vào xem trước)
            Button {
                onPreview()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    BlossomTheme.sakuraLight.opacity(isApplied ? 0.25 : 0.12),
                                    brandBlue.opacity(isApplied ? 0.2 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    if let thumb = localUIImage {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(isApplied ? BlossomTheme.sakuraLight : brandBlue)
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isApplied
                                ? BlossomTheme.sakuraLight
                                : brandBlue.opacity(0.4),
                            lineWidth: isApplied ? 1.8 : 1
                        )
                        .frame(width: 48, height: 48)
                }
            }
            .buttonStyle(ScaleButtonStyle())

            // Tên và thông tin skin
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(skinTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(skinBadge)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.30, blue: 0.45), BlossomTheme.sakuraDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }

                Text(skinSubtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BlossomTheme.sakuraLight)
                    .lineLimit(1)

                // Trạng thái Bật / Tắt & Nút Xem Ảnh
                HStack(spacing: 8) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 6, height: 6)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray.opacity(0.4))

                    Button {
                        onPreview()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("Xem ảnh")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(brandBlue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(brandBlue.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(brandBlue.opacity(0.3), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.top, 1)
            }

            Spacer()

            // Nút Bật / Tắt Switch
            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 50)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(brandBlue)
            }
        }
        .padding(14)
        .background(Color(red: 0.082, green: 0.043, blue: 0.137))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? BlossomTheme.sakura.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? brandBlue.opacity(0.2) : .clear, radius: 8)
    }
}

// MARK: - Skin Image View (Hỗ trợ nạp Offline & Online Fallback)
private struct SkinImageView: View {
    let info: SkinPreviewInfo

    private var localUIImage: UIImage? {
        if let img = UIImage(named: info.localImageName) {
            return img
        }
        if let path = Bundle.main.path(forResource: info.localImageName, ofType: "jpeg") ??
                      Bundle.main.path(forResource: info.localImageName, ofType: "png") ??
                      Bundle.main.path(forResource: info.localImageName, ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    var body: some View {
        Group {
            if let uiImage = localUIImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if let url = URL(string: info.imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        VStack(spacing: 10) {
                            ProgressView()
                                .tint(.white)
                            Text("Đang tải ảnh xem trước...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 30))
                                .foregroundStyle(.orange)
                            Text("Không tải được ảnh xem trước")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
            }
        }
    }
}

// MARK: - Skin Image Preview Modal (Cửa sổ bật lên xem ảnh sắc nét)
private struct SkinImagePreviewModal: View {
    let info: SkinPreviewInfo
    let brandBlue: Color
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Lớp nền đen mờ bao quanh, chạm vào để đóng
            Color.black.opacity(0.82)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            VStack(spacing: 14) {
                // Header thanh tiêu đề & Nút đóng
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(info.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("XEM TRƯỚC")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(brandBlue)
                                .cornerRadius(4)
                        }

                        Text(info.subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Khung ảnh xem trước bo góc phát sáng
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.05, green: 0.02, blue: 0.09))

                    SkinImageView(info: info)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxHeight: 360)
                .padding(.horizontal, 14)

                // Nút Đóng phía dưới
                Button {
                    onClose()
                } label: {
                    Text("Đóng xem trước")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [BlossomTheme.sakuraDeep, brandBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: brandBlue.opacity(0.4), radius: 6)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(red: 0.10, green: 0.05, blue: 0.17))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(brandBlue.opacity(0.45), lineWidth: 1.5)
            )
            .shadow(color: brandBlue.opacity(0.35), radius: 24)
            .padding(.horizontal, 22)
        }
    }
}

// MARK: - Scale Button Style
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

