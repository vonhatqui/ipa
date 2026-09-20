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

    private func isApplestorePrimeItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("applestore") || name.contains("prime") || filename.contains("applestore")
    }

    private func isCpanelItem(_ item: PatchLibraryItem) -> Bool {
        if isApplestorePrimeItem(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("cpanel") || name.contains("leaked") || filename.contains("cpanel")
    }

    private func isSkinItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("skin") || name.contains("vô cực") || name.contains("vo cuc") || name.contains("mùa 1") || name.contains("mua 1") || name.contains("ignis") || name.contains("alock") || name.contains("alok") || name.contains("nạ cỏ") || name.contains("na co") || name.contains("đá bóng") || name.contains("da bong") || filename.contains("skin")
    }

    private func isAimItem(_ item: PatchLibraryItem) -> Bool {
        if isAimneckVipItem(item) || isEspAimheadV3Item(item) || isEspItem(item) || isCpanelItem(item) || isSkinItem(item) || isApplestorePrimeItem(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("aim") || name.contains("drag") || filename.contains("system")
    }

    private var aimneckVipItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isAimneckVipItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_aimneck_vip")
    }

    private var espAimheadV3Item: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isEspAimheadV3Item($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_esp_aimhead_v3")
    }

    private var aimItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isAimItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_system")
    }

    private var applestorePrimeItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isApplestorePrimeItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_applestore_prime")
    }

    private var cpanelItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isCpanelItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_cpanel")
    }

    private var espItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isEspItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_network")
    }

    private var skinItems: [PatchLibraryItem] {
        let list = patchStore.items.filter { isSkinItem($0) }
        if !list.isEmpty { return list }
        return [
            PatchProjectLibrary.loadBundledItem(named: "lib_app_skin_ignis"),
            PatchProjectLibrary.loadBundledItem(named: "lib_app_skin_naco")
        ].compactMap { $0 }
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

                // DANH MỤC 2: LỰA CHỌN 2 (APPLESTORE PRIME & Cpanel Leaked)
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

                // CẢ 2 CHỨC NĂNG: APPLESTORE PRIME & Cpanel Leaked
                VStack(spacing: 14) {
                    ApplestorePrimeCard(
                        item: applestorePrimeItem,
                        isApplied: applestorePrimeItem != nil && appliedProjectIDs.contains(applestorePrimeItem!.id),
                        isWorking: applestorePrimeItem != nil && workingPatchID == applestorePrimeItem!.id,
                        brandBlue: brandBlue,
                        onToggle: { enable in
                            if let item = applestorePrimeItem {
                                handleToggle(item: item, enable: enable)
                            } else if let loaded = PatchProjectLibrary.loadBundledItem(named: "lib_app_applestore_prime") {
                                handleToggle(item: loaded, enable: enable)
                            }
                        }
                    )

                    if let cp = cpanelItem {
                        CpanelItemCard(
                            item: cp,
                            isApplied: appliedProjectIDs.contains(cp.id),
                            isWorking: workingPatchID == cp.id,
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleToggle(item: cp, enable: enable)
                            }
                        )
                    } else if let loaded = PatchProjectLibrary.loadBundledItem(named: "lib_app_cpanel") {
                        CpanelItemCard(
                            item: loaded,
                            isApplied: appliedProjectIDs.contains(loaded.id),
                            isWorking: workingPatchID == loaded.id,
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleToggle(item: loaded, enable: enable)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

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
                            Text("BẢNG ĐIỀU KHIỂN ĐỊNH VỊ")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(brandBlue)
                                .tracking(1.1)

                            Text("VIP")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.85, green: 0.20, blue: 0.65), brandBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }

                        Text("Định Vị Xuyên Tường • Khóa Đầu Chuẩn Xác 100%")
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

                // 2. Chức Năng ESP 2.0 (Nếu Có)
                if let item = espItem, item.id != espAimheadV3Item?.id {
                    VStack(spacing: 14) {
                        EspItemCard(
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

                if espAimheadV3Item == nil && espItem == nil {
                    emptyEspStateView
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

                        Text("Gạt BẬT [ĐỊNH VỊ + AIMHEAD V3] trước khi vào game > Bấm [MỞ] Free Fire bên dưới. Bạn có thể sang tab Trang Chủ bật thêm AIMBOT!")
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
                .padding(.top, 4)
            }
            .padding(.bottom, 24)
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
                .frame(height: 38)
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
                        .frame(height: 40)
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
                        .frame(height: 40)
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
                    .frame(height: 38)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(cardBackground.opacity(0.96))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
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
                    // Xử lý xung đột file: Cpanel Leaked, ESP 2.0, ESP+AimHead V3 và APPLESTORE PRIME cùng sửa Assembly-CSharp & localConfig
                    if self.isCpanelItem(item) || self.isEspItem(item) || self.isEspAimheadV3Item(item) || self.isApplestorePrimeItem(item) {
                        let assemblyMods = [self.espItem, self.cpanelItem, self.espAimheadV3Item, self.applestorePrimeItem].compactMap { $0 }
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
        if name.contains("vô cực") || name.contains("vo cuc") || name.contains("mùa 1") || name.contains("mua 1") || name.contains("vàng") {
            previewSkinInfo = SkinPreviewInfo(
                title: "Skin thẻ vô cực vàng mùa 1",
                subtitle: "Trang phục Thẻ Vô Cực Vàng Mùa 1 Huyền Thoại",
                imageURL: "https://files.catbox.moe/0kjz3x.jpeg",
                localImageName: "skin_vocuc"
            )
        } else if name.contains("ignis") {
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
        if isApplestorePrimeItem(item) {
            return "APPLESTORE PRIME"
        }
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

// MARK: - PulsingLedTag (Thẻ Tag PRIME Màu ĐỎ Có Đèn LED Đổi Màu Rực Rỡ)
private struct PulsingLedTag: View {
    let text: String
    @State private var isPulsing: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            // Đèn LED tròn nhấp nháy phát sáng
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color(red: 1.0, green: 0.25, blue: 0.35)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 3
                    )
                )
                .frame(width: 5, height: 5)
                .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.3), radius: isPulsing ? 5 : 2)
                .opacity(isPulsing ? 1.0 : 0.65)

            Text(text)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .tracking(1.0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(
            LinearGradient(
                colors: isPulsing ? [
                    Color(red: 1.0, green: 0.18, blue: 0.22),
                    Color(red: 1.0, green: 0.35, blue: 0.10),
                    Color(red: 0.88, green: 0.05, blue: 0.30)
                ] : [
                    Color(red: 0.90, green: 0.06, blue: 0.15),
                    Color(red: 0.82, green: 0.18, blue: 0.05),
                    Color(red: 0.75, green: 0.02, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(
                    LinearGradient(
                        colors: isPulsing ? [
                            Color(red: 1.0, green: 0.6, blue: 0.6),
                            Color(red: 1.0, green: 0.9, blue: 0.3),
                            Color(red: 1.0, green: 0.4, blue: 0.7)
                        ] : [
                            Color(red: 0.9, green: 0.3, blue: 0.3),
                            Color(red: 0.9, green: 0.6, blue: 0.2),
                            Color(red: 0.8, green: 0.2, blue: 0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(
            color: Color(red: 1.0, green: 0.15, blue: 0.25).opacity(isPulsing ? 0.95 : 0.45),
            radius: isPulsing ? 9 : 4,
            x: 0,
            y: 0
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - FeatureLogoView (Fallback hỗ trợ tương thích)
private struct FeatureLogoView: View {
    let name: String
    var size: CGFloat = 50
    var cornerRadius: CGFloat = 13
    var isApplied: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.08, blue: 0.25),
                            Color(red: 0.08, green: 0.04, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: "bolt.shield.fill")
                .font(.system(size: size * 0.45))
                .foregroundStyle(BlossomTheme.sakura)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    isApplied ? BlossomTheme.sakuraLight : Color.white.opacity(0.12),
                    lineWidth: isApplied ? 1.8 : 1
                )
                .frame(width: size, height: size)
        }
    }
}

// MARK: - ApplestorePrimeCard (Chức Năng Lựa Chọn 2: APPLESTORE PRIME - Royal Neon Purple)
private struct ApplestorePrimeCard: View {
    let item: PatchLibraryItem?
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    @State private var isLedActive: Bool = false

    var body: some View {
        HStack(spacing: 11) {
            // Icon code AppleStore Prime vector quả táo phát sáng LED tím pulsing neon
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.26, green: 0.08, blue: 0.44),
                                Color(red: 0.12, green: 0.03, blue: 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                BlossomTheme.sakuraLight
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: BlossomTheme.sakura.opacity(isApplied ? 0.95 : 0.6), radius: isApplied ? 7 : 3.5)

                // Viền LED tím pulsing neon hoàng gia đổi màu nhấp nháy phát sáng
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isLedActive ? [
                                BlossomTheme.sakuraLight,
                                BlossomTheme.sakura,
                                BlossomTheme.sakuraDeep
                            ] : [
                                BlossomTheme.sakuraDeep,
                                BlossomTheme.branch,
                                BlossomTheme.sakura
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isApplied ? 1.8 : 1.2
                    )
                    .frame(width: 42, height: 42)
            }
            .shadow(color: BlossomTheme.sakura.opacity(isApplied ? 0.60 : (isLedActive ? 0.40 : 0.20)), radius: isLedActive ? 7 : 3.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isLedActive = true
                }
            }

            // Thông tin chức năng
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text("APPLESTORE PRIME")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Tag PRIME Tím Neon
                    PulsingLedTag(text: "PRIME")
                }

                Text("Menu Mod Độc Quyền AppleStore • Ổn Định Tuyệt Đối")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BlossomTheme.sakuraLight)
                    .lineLimit(1)

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Nút Switch Bật / Tắt (thu gọn 15-20%)
            if isWorking {
                ProgressView()
                    .tint(BlossomTheme.sakura)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(BlossomTheme.sakura)
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(
                    isApplied
                        ? BlossomTheme.sakura.opacity(0.85)
                        : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .shadow(color: isApplied ? BlossomTheme.sakura.opacity(0.35) : Color.clear, radius: 7)
    }
}

// MARK: - AimneckVipCard (Chức Năng Trang Chủ: AIMNECK VIP với Icon Code)
private struct AimneckVipCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 11) {
            // Icon Code Vector: Tâm ngắm scope với viền hoa anh đào tím Sakura rực rỡ
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.08, blue: 0.38),
                                Color(red: 0.12, green: 0.04, blue: 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "scope")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BlossomTheme.sakuraLight, Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: BlossomTheme.sakura.opacity(isApplied ? 0.95 : 0.5), radius: isApplied ? 7 : 3.5)

                // Viền hoa anh đào tím Sakura rực rỡ
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                BlossomTheme.sakuraLight,
                                BlossomTheme.sakura,
                                BlossomTheme.sakuraDeep
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isApplied ? 1.8 : 1.2
                    )
                    .frame(width: 42, height: 42)
            }
            .shadow(color: BlossomTheme.sakura.opacity(isApplied ? 0.5 : 0.25), radius: 5)

            // Thông tin chức năng
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text("AIMNECK VIP")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Tag LOCK CỔ (Màu Tím Hoa Anh Đào Sakura)
                    Text("LOCK CỔ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [BlossomTheme.sakuraDeep, BlossomTheme.sakura],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(3.5)
                        .shadow(color: BlossomTheme.sakura.opacity(0.4), radius: 3)
                }

                Text("Khóa Cổ Siêu Dính • Kéo Tâm Mượt")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BlossomTheme.sakuraLight)

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Nút Bật / Tắt Switch (thu gọn 15-20%)
            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(brandBlue)
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(isApplied ? BlossomTheme.sakuraLight.opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? BlossomTheme.sakura.opacity(0.25) : Color.clear, radius: 7)
    }
}

// MARK: - EspAimheadV3Card (Chức Năng Định Vị: ĐỊNH VỊ + AIMHEAD V3 với Icon Code)
private struct EspAimheadV3Card: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 11) {
            // Icon Code Vector: Kính ngắm 3D viewfinder với viền xanh Cyan Neon
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.02, green: 0.28, blue: 0.40),
                                Color(red: 0.01, green: 0.12, blue: 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "viewfinder")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.00, green: 0.95, blue: 1.0), Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.0, green: 0.90, blue: 1.0).opacity(isApplied ? 0.95 : 0.5), radius: isApplied ? 7 : 3.5)

                // Viền xanh Cyan Neon rực rỡ
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.00, green: 0.98, blue: 1.0),
                                Color(red: 0.00, green: 0.68, blue: 0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isApplied ? 1.8 : 1.2
                    )
                    .frame(width: 42, height: 42)
            }
            .shadow(color: Color(red: 0.00, green: 0.88, blue: 0.95).opacity(isApplied ? 0.5 : 0.25), radius: 5)

            // Thông tin chức năng
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text("ĐỊNH VỊ + AIMHEAD V3")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Tag ESP + AIM (Màu Cyan Neon)
                    Text("ESP + AIM")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.98, blue: 1.0), Color(red: 0.00, green: 0.72, blue: 0.90)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(3.5)
                        .shadow(color: Color(red: 0.00, green: 0.95, blue: 1.0).opacity(0.4), radius: 3)
                }

                Text("Khung Định Vị Head 3D • Khóa Đầu Chuẩn Xác")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(red: 0.00, green: 0.88, blue: 0.95))

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.00, green: 0.85, blue: 0.95))
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(isApplied ? Color(red: 0.00, green: 0.88, blue: 0.95).opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? Color(red: 0.00, green: 0.88, blue: 0.95).opacity(0.25) : Color.clear, radius: 7)
    }
}

// MARK: - CheatItemCard (AIMDRAG PRO với Icon Code)
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
        HStack(spacing: 11) {
            // Icon code vector: Tâm kéo cross.fill với viền tím Cyber
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.10, blue: 0.42),
                                Color(red: 0.08, green: 0.04, blue: 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "cross.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.75, green: 0.50, blue: 1.0), Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.60, green: 0.35, blue: 1.0).opacity(isApplied ? 0.95 : 0.5), radius: isApplied ? 7 : 3.5)

                // Viền tím Cyber
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.75, green: 0.35, blue: 1.0),
                                Color(red: 0.45, green: 0.15, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isApplied ? 1.8 : 1.2
                    )
                    .frame(width: 42, height: 42)
            }
            .shadow(color: Color(red: 0.65, green: 0.30, blue: 1.0).opacity(isApplied ? 0.5 : 0.25), radius: 5)

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text(displayName)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Tag PRO (Màu Tím Cyber)
                    Text("PRO")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.68, green: 0.25, blue: 0.98), Color(red: 0.42, green: 0.15, blue: 0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(3.5)
                        .shadow(color: Color(red: 0.65, green: 0.25, blue: 0.95).opacity(0.4), radius: 3)
                }

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(red: 0.75, green: 0.60, blue: 1.0))

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.65, green: 0.35, blue: 1.0))
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(isApplied ? Color(red: 0.65, green: 0.35, blue: 1.0).opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? Color(red: 0.65, green: 0.35, blue: 1.0).opacity(0.25) : Color.clear, radius: 7)
    }
}

// MARK: - EspItemCard (ESP 2.0 Tối Giản với Icon Code Laser Cyan)
private struct EspItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 11) {
            // Radar Icon Code: Biểu tượng radar location.viewfinder Laser Cyan
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.02, green: 0.25, blue: 0.35),
                                Color(red: 0.01, green: 0.10, blue: 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "location.viewfinder")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.00, green: 0.95, blue: 1.0), Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.00, green: 0.90, blue: 1.0).opacity(isApplied ? 0.95 : 0.5), radius: isApplied ? 7 : 3.5)

                // Viền Laser Cyan
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.00, green: 0.95, blue: 1.0),
                                Color(red: 0.00, green: 0.60, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isApplied ? 1.8 : 1.2
                    )
                    .frame(width: 42, height: 42)
            }
            .shadow(color: Color(red: 0.00, green: 0.88, blue: 0.95).opacity(isApplied ? 0.5 : 0.25), radius: 5)

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text("ESP 2.0")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Tag ESP (Màu Laser Cyan)
                    Text("ESP")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.85, blue: 0.95), Color(red: 0.00, green: 0.55, blue: 0.80)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(3.5)
                        .shadow(color: Color(red: 0.00, green: 0.85, blue: 0.95).opacity(0.4), radius: 3)
                }

                Text("Tia Dẫn Đường • Định Vị Xuyên Bản Đồ")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(red: 0.00, green: 0.88, blue: 0.95))

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.00, green: 0.85, blue: 0.95))
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(isApplied ? Color(red: 0.00, green: 0.88, blue: 0.95).opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? Color(red: 0.00, green: 0.88, blue: 0.95).opacity(0.25) : Color.clear, radius: 7)
    }
}

// MARK: - CpanelItemCard (Lựa Chọn 2: Cpanel Leaked với Icon Amber-Violet)
private struct CpanelItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 11) {
            // Icon Code Vector: Biểu tượng slider.horizontal.3 Amber-Violet
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.30, green: 0.15, blue: 0.10),
                                Color(red: 0.18, green: 0.07, blue: 0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.72, blue: 0.25),
                                Color(red: 0.88, green: 0.45, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.15).opacity(isApplied ? 0.95 : 0.5), radius: isApplied ? 7 : 3.5)

                // Viền Amber-Violet
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.62, blue: 0.18),
                                Color(red: 0.78, green: 0.28, blue: 0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isApplied ? 1.8 : 1.2
                    )
                    .frame(width: 42, height: 42)
            }
            .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.15).opacity(isApplied ? 0.5 : 0.25), radius: 5)

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text("Cpanel Leaked")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Tag LEAKED (Amber-Violet)
                    Text("LEAKED")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.55, blue: 0.15), Color(red: 0.70, green: 0.20, blue: 0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(3.5)
                        .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.4), radius: 3)
                }

                Text("Chống văng game hiệu quả • Ổn định trận đấu")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.40))
                    .lineLimit(1)

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            if isWorking {
                ProgressView()
                    .tint(Color.orange)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.95, green: 0.55, blue: 0.15))
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(isApplied ? Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.25) : .clear, radius: 7)
    }
}

// MARK: - SkinItemCard (Mod Skin VIP với Icon Code & Thẻ Tag Chuẩn)
private struct SkinItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void
    let onPreview: () -> Void

    private var isGoldenSeason1: Bool {
        let raw = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        return raw.contains("vô cực") || raw.contains("vo cuc") || raw.contains("mùa 1") || raw.contains("mua 1") || raw.contains("vàng") || raw.contains("gold")
    }

    private var skinTitle: String {
        let raw = item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
        if isGoldenSeason1 {
            return "Skin Thẻ Vô Cực Vàng Mùa 1"
        }
        if raw.lowercased().contains("alock") || raw.lowercased().contains("naco") {
            return "Mod Skin Alock Thất Tỉnh"
        }
        return raw
    }

    private var skinSubtitle: String {
        if isGoldenSeason1 {
            return "Trang phục Thẻ Vô Cực Vàng Mùa 1 Hoàng Kim"
        } else {
            return "Bộ trang phục Alock Thất Tỉnh (Nạ Cỏ - Áo Đá Bóng)"
        }
    }

    var body: some View {
        HStack(spacing: 11) {
            // Icon Code Vector: Vương miện Hoàng Gia Gold hoặc Trang phục hồng tím Neon
            Button {
                onPreview()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isGoldenSeason1
                                    ? [Color(red: 0.35, green: 0.25, blue: 0.05), Color(red: 0.15, green: 0.10, blue: 0.02)]
                                    : [Color(red: 0.32, green: 0.08, blue: 0.28), Color(red: 0.14, green: 0.03, blue: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: isGoldenSeason1 ? "crown.fill" : "tshirt.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isGoldenSeason1
                                    ? [Color(red: 1.0, green: 0.90, blue: 0.35), Color(red: 0.95, green: 0.68, blue: 0.10)]
                                    : [Color(red: 1.0, green: 0.40, blue: 0.85), Color(red: 0.75, green: 0.25, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: isGoldenSeason1
                                ? Color(red: 1.0, green: 0.8, blue: 0.2).opacity(isApplied ? 0.95 : 0.5)
                                : Color(red: 0.95, green: 0.30, blue: 0.80).opacity(isApplied ? 0.95 : 0.5),
                            radius: isApplied ? 7 : 3.5
                        )

                    // Viền vàng Gold óng ánh hoặc hồng tím Neon
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isGoldenSeason1
                                    ? [Color(red: 1.0, green: 0.88, blue: 0.30), Color(red: 0.88, green: 0.62, blue: 0.10)]
                                    : [Color(red: 1.0, green: 0.38, blue: 0.88), Color(red: 0.65, green: 0.18, blue: 0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isApplied ? 1.8 : 1.2
                        )
                        .frame(width: 42, height: 42)
                }
                .shadow(
                    color: isGoldenSeason1
                        ? Color(red: 1.0, green: 0.8, blue: 0.2).opacity(isApplied ? 0.5 : 0.25)
                        : Color(red: 0.95, green: 0.30, blue: 0.80).opacity(isApplied ? 0.5 : 0.25),
                    radius: 5
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Tên và thông tin skin
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text(skinTitle)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if isGoldenSeason1 {
                        // Tag GOLD (Màu Vàng Gold Óng Ánh)
                        Text("GOLD")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.90, blue: 0.30), Color(red: 0.95, green: 0.65, blue: 0.05)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(3.5)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.4), radius: 3)
                    } else {
                        // Tag VIP SKIN (Màu Hồng Tím Neon)
                        Text("VIP SKIN")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.25, blue: 0.70), Color(red: 0.65, green: 0.15, blue: 0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(3.5)
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.70).opacity(0.4), radius: 3)
                    }
                }

                Text(skinSubtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isGoldenSeason1 ? Color(red: 1.0, green: 0.84, blue: 0.3) : Color(red: 0.95, green: 0.55, blue: 0.85))

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 5.5, height: 5.5)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(isApplied ? Color.green : .gray)
                }
                .padding(.top, 1)
            }

            Spacer()

            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .frame(width: 44)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(isGoldenSeason1 ? Color(red: 1.0, green: 0.75, blue: 0.1) : Color(red: 0.90, green: 0.25, blue: 0.65))
                .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(
                    isApplied
                        ? (isGoldenSeason1 ? Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.85) : Color(red: 0.95, green: 0.35, blue: 0.80).opacity(0.85))
                        : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isApplied
                ? (isGoldenSeason1 ? Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.3) : Color(red: 0.95, green: 0.35, blue: 0.80).opacity(0.3))
                : Color.clear,
            radius: 7
        )
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

