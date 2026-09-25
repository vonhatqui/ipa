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
    @State private var showCleanRestoreConfirm = false
    @State private var isRestoringClean = false



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

    private func isEspItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        if name.contains("aimhead") || filename.contains("aimhead") { return false }
        return name.contains("định vị") || name.contains("dinh vi") || name.contains("dinhvi") || name.contains("esp") || name.contains("blue") || filename.contains("network")
    }

    private func isAppleIpaV2Item(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("apple ipa") || name.contains("apple_ipa") || filename.contains("apple_ipa") || filename.contains("lib_app_apple_ipa_v2")
    }

    private func isInternalItem(_ item: PatchLibraryItem) -> Bool {
        if isAppleIpaV2Item(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("internal") || filename.contains("internal")
    }

    private func isApplestorePrimeItem(_ item: PatchLibraryItem) -> Bool {
        if isAppleIpaV2Item(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("applestore") || name.contains("prime") || filename.contains("applestore")
    }

    private func isSkinItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        if name.contains("alock") || name.contains("alok") || name.contains("nạ cỏ") || name.contains("na co") || name.contains("đá bóng") || name.contains("da bong") || filename.contains("naco") {
            return false
        }
        return name.contains("skin") || name.contains("vô cực") || name.contains("vo cuc") || name.contains("mùa 1") || name.contains("mua 1") || name.contains("ignis") || filename.contains("skin")
    }

    private func isAimItem(_ item: PatchLibraryItem) -> Bool {
        if isAimneckVipItem(item) || isEspItem(item) || isSkinItem(item) || isApplestorePrimeItem(item) || isAppleIpaV2Item(item) || isInternalItem(item) { return false }
        let name = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent).lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("aim") || name.contains("drag") || filename.contains("system")
    }

    /// Kiểm tra tính năng có đang bị khoá bảo trì từ xa từ Server API không
    private func isItemUnderMaintenance(_ item: PatchLibraryItem) -> Bool {
        let cfg = licenseManager.featureConfig
        if !cfg.is_app_safe { return true }
        if isAppleIpaV2Item(item) {
            return !cfg.apple_ipa
        }
        if isInternalItem(item) {
            return !cfg.internal_mod
        }
        if isApplestorePrimeItem(item) {
            return !cfg.applestore_prime
        }
        if isAimneckVipItem(item) {
            return !cfg.aimneck
        }
        if isAimItem(item) {
            return !cfg.aim_auto
        }
        if isEspItem(item) {
            return !cfg.esp
        }
        if isSkinItem(item) {
            return !cfg.skin
        }
        return false
    }

    private func isItemSafe(_ item: PatchLibraryItem) -> Bool {
        return !isItemUnderMaintenance(item)
    }

    private var aimneckVipItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isAimneckVipItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_aimneck_vip")
    }

    private var aimItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isAimItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_system")
    }

    private var appleIpaV2Item: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isAppleIpaV2Item($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_apple_ipa_v2")
    }

    private var internalItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isInternalItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_internal")
    }

    private var applestorePrimeItem: PatchLibraryItem? {
        if let found = patchStore.items.first(where: { isApplestorePrimeItem($0) }) {
            return found
        }
        return PatchProjectLibrary.loadBundledItem(named: "lib_app_applestore_prime")
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
            PatchProjectLibrary.loadBundledItem(named: "lib_app_skin_ignis")
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

                // Dock Mở Game Nhanh (Chuyên biệt Free Fire)
                if selectedTab != .profile {
                    quickLaunchCardView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Thanh Dashboard điều hướng phía dưới
                bottomTabBar
                    .padding(.bottom, 4)

                // Footer trạng thái thiết bị & iOS (to hơn 15%)
                deviceStatusFooterView
                    .padding(.bottom, 6)
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
        .confirmationDialog(
            "Khôi phục sạch dữ liệu Free Fire?",
            isPresented: $showCleanRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button("Khôi phục sạch 100% file gốc", role: .destructive) {
                performCleanRestore()
            }
            Button("Hủy", role: .cancel) { }
        } message: {
            Text("Toàn bộ file mod sẽ được dọn sạch và hoàn nguyên 100% về file gốc ban đầu từ Golden Snapshot cho Free Fire.")
        }
        .sheet(item: $patchStore.passwordRequest, onDismiss: patchStore.cancelUnlock) { request in
            PatchUnlockView(store: patchStore, request: request)
        }
        .onAppear {
            DevicePatchService.preferredVersion = .standard
            appliedProjectIDs = DevicePatchService.allAppliedProjectIDs()
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)
            Task {
                await licenseManager.fetchRemoteFeatureConfig()
            }
        }
    }

    // MARK: - Top Header
    private var topHeaderView: some View {
        HStack(spacing: 8) {
            if let onBack = onBackToGames {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onBack()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text("Ứng Dụng")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(brandBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(brandBlue.opacity(0.12))
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(brandBlue.opacity(0.25), lineWidth: 0.8)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            CheatStoreLogoView(size: 34, cornerRadius: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text("CheatStore VN")
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(brandBlue)
                        .frame(width: 5.5, height: 5.5)
                        .shadow(color: brandBlue.opacity(0.8), radius: 3)
                    ShinyTextView(
                        text: "VIP ĐÃ KÍCH HOẠT",
                        font: .system(size: 9.5, weight: .bold, design: .rounded),
                        baseColor: brandBlue,
                        shineColor: BlossomTheme.sakuraLight,
                        duration: 2.5
                    )
                }
            }

            Spacer()

            // Nút Khôi Phục Sạch trên Header
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showCleanRestoreConfirm = true
            } label: {
                HStack(spacing: 4) {
                    if isRestoringClean {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.65)
                    } else {
                        Image(systemName: "arrow.counterclockwise.shield.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.50))
                    }

                    Text("Khôi phục")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.65, green: 0.08, blue: 0.22).opacity(0.35))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.35, blue: 0.50).opacity(0.7),
                                    Color(red: 0.8, green: 0.15, blue: 0.3).opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.red.opacity(0.2), radius: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isRestoringClean)

            // Nút Làm mới
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                BundledPatchInjector.autoImportBundledPatches(into: patchStore)
                Task {
                    await licenseManager.fetchRemoteFeatureConfig()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(brandBlue)
                    .frame(width: 30, height: 30)
                    .background(brandBlue.opacity(0.12))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(brandBlue.opacity(0.3), lineWidth: 0.8)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(darkBackground.opacity(0.92))
    }

    // MARK: - Tab 1: Trang Chủ (Hiện Aim & Mod)
    private var homeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // DANH MỤC 1: APPLESTORE PRIME - HOẠT ĐỘNG CHÍNH (CHỐNG VĂNG GAME)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("APPLESTORE PRIME")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BlossomTheme.sakura)
                                .tracking(1.0)

                            Text("ĐANG HOẠT ĐỘNG")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Color.green)
                                .cornerRadius(4)
                        }

                        Text("Menu Mod Độc Quyền • Ổn định tuyệt đối chống văng")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Thẻ APPLE IPA V2 & APPLESTORE PRIME nổi bật hàng đầu
                VStack(spacing: 14) {
                    AppleIpaV2Card(
                        item: appleIpaV2Item,
                        isApplied: appleIpaV2Item != nil && appliedProjectIDs.contains(appleIpaV2Item!.id),
                        isWorking: appleIpaV2Item != nil && workingPatchID == appleIpaV2Item!.id,
                        isUnderMaintenance: appleIpaV2Item != nil ? isItemUnderMaintenance(appleIpaV2Item!) : !licenseManager.featureConfig.apple_ipa,
                        brandBlue: brandBlue,
                        onToggle: { enable in
                            let itemToToggle = appleIpaV2Item ?? PatchProjectLibrary.loadBundledItem(named: "lib_app_apple_ipa_v2")
                            if let item = itemToToggle {
                                handleMaintenanceToggle(item: item, enable: enable)
                            }
                        }
                    )

                    ApplestorePrimeCard(
                        item: applestorePrimeItem,
                        isApplied: applestorePrimeItem != nil && appliedProjectIDs.contains(applestorePrimeItem!.id),
                        isWorking: applestorePrimeItem != nil && workingPatchID == applestorePrimeItem!.id,
                        isUnderMaintenance: applestorePrimeItem != nil ? isItemUnderMaintenance(applestorePrimeItem!) : !licenseManager.featureConfig.applestore_prime,
                        brandBlue: brandBlue,
                        onToggle: { enable in
                            let itemToToggle = applestorePrimeItem ?? PatchProjectLibrary.loadBundledItem(named: "lib_app_applestore_prime")
                            if let item = itemToToggle {
                                handleMaintenanceToggle(item: item, enable: enable)
                            }
                        }
                    )

                    InternalCard(
                        item: internalItem,
                        isApplied: internalItem != nil && appliedProjectIDs.contains(internalItem!.id),
                        isWorking: internalItem != nil && workingPatchID == internalItem!.id,
                        isUnderMaintenance: internalItem != nil ? isItemUnderMaintenance(internalItem!) : !licenseManager.featureConfig.internal_mod,
                        brandBlue: brandBlue,
                        onToggle: { enable in
                            let itemToToggle = internalItem ?? PatchProjectLibrary.loadBundledItem(named: "lib_app_internal")
                            if let item = itemToToggle {
                                handleMaintenanceToggle(item: item, enable: enable)
                            }
                        }
                    )
                }
                .padding(.horizontal, 20)

                // DANH MỤC 2: CÁC CHỨC NĂNG BỔ TRỢ & AN TOÀN
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(licenseManager.featureConfig.aimneck ? "CHỨC NĂNG BỔ TRỢ" : "CẢNH BÁO RỦI RO QUÉT")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(licenseManager.featureConfig.aimneck ? BlossomTheme.sakura : Color(red: 1.0, green: 0.35, blue: 0.45))
                                .tracking(1.0)

                            if licenseManager.featureConfig.aimneck {
                                Text("🟢 AN TOÀN")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Color.green)
                                    .cornerRadius(4)
                            } else {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .font(.system(size: 7))
                                    Text("🔴 KHÔNG AN TOÀN")
                                        .font(.system(size: 8, weight: .black))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2.5)
                                .background(Color.red)
                                .cornerRadius(4)
                            }
                        }

                        Text(licenseManager.featureConfig.aimneck ? "Hỗ trợ ngắm bắn và cảm ứng độ nhạy • Sẵn sàng sử dụng" : "Phát hiện nguy cơ quét từ máy chủ game • Tạm ngắt an toàn")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Danh sách các thẻ chức năng trong Trang Chủ:
                VStack(spacing: 14) {
                    // 1. AIMNECK VIP
                    if let vipItem = aimneckVipItem {
                        AimneckVipCard(
                            item: vipItem,
                            isApplied: appliedProjectIDs.contains(vipItem.id),
                            isWorking: workingPatchID == vipItem.id,
                            isUnderMaintenance: isItemUnderMaintenance(vipItem),
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleMaintenanceToggle(item: vipItem, enable: enable)
                            }
                        )
                    }

                    // 2. AIMDRAG PRO
                    if let item = aimItem, item.id != aimneckVipItem?.id {
                        CheatItemCard(
                            item: item,
                            isApplied: appliedProjectIDs.contains(item.id),
                            isWorking: workingPatchID == item.id,
                            isUnderMaintenance: isItemUnderMaintenance(item),
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleMaintenanceToggle(item: item, enable: enable)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Gợi Ý Nhanh
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BlossomTheme.sakura)

                    Text("Mẹo: Bật [AppleStore Prime] trước khi vào game để chống văng 100%.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(cardBackground.opacity(0.85))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BlossomTheme.sakura.opacity(0.2), lineWidth: 0.8)
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Tab 2: Định Vị (Bảng Điều Khiển ESP Riêng Biệt)
    private var espView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Tiêu đề danh mục: ĐỊNH VỊ (ESP)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("ĐỊNH VỊ (ESP)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BlossomTheme.sakura)
                                .tracking(1.0)

                            Text(licenseManager.featureConfig.esp ? "🟢 AN TOÀN" : "🔴 KHÔNG AN TOÀN")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(licenseManager.featureConfig.esp ? Color.blue : Color.orange)
                                .cornerRadius(4)
                        }

                        Text("Quét tọa độ 3D • Hỗ trợ tâm ngắm & cảnh báo kẻ địch")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Banner Bảo Trì Định Vị (Chỉ hiển thị khi hệ thống định vị đang tạm bảo trì)
                if !licenseManager.featureConfig.esp {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.orange)

                            Text("HỆ THỐNG ĐỊNH VỊ ĐANG BẢO TRÌ")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)

                            Spacer()

                            Text("BẢO TRÌ")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }

                        Text("Hệ thống Định Vị đang được bảo trì nhằm nâng cấp thuật toán giới hạn 50m và tối ưu hóa giải phóng RAM chống văng game.\n\n👉 Hiện tại, quý khách vui lòng sang [Trang Chủ] để bật tính năng APPLESTORE PRIME!")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(3)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .home
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "apple.logo")
                                Text("Chuyển sang Trang Chủ (Bật APPLESTORE PRIME)")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                LinearGradient(
                                    colors: [BlossomTheme.sakuraDeep, BlossomTheme.sakura],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: BlossomTheme.sakura.opacity(0.4), radius: 5)
                        }
                        .padding(.top, 2)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                // Chức Năng Định Vị Người (ESP)
                if let item = espItem {
                    VStack(spacing: 14) {
                        EspItemCard(
                            item: item,
                            isApplied: appliedProjectIDs.contains(item.id),
                            isWorking: workingPatchID == item.id,
                            isUnderMaintenance: isItemUnderMaintenance(item),
                            brandBlue: brandBlue,
                            onToggle: { enable in
                                handleMaintenanceToggle(item: item, enable: enable)
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }

                if espItem == nil {
                    emptyEspStateView
                }
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
                // Tiêu đề danh mục: MOD SKIN VIP
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("MOD SKIN VIP")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BlossomTheme.sakura)
                                .tracking(1.0)

                            Text(licenseManager.featureConfig.skin ? "🟢 AN TOÀN" : "🔴 KHÔNG AN TOÀN")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(licenseManager.featureConfig.skin ? Color.purple : Color.orange)
                                .cornerRadius(4)
                        }

                        Text("Gói trang phục bản quyền • Hiệu ứng súng & nhân vật")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Banner Bảo Trì Mod Skin (Chỉ hiển thị khi hệ thống skin đang tạm bảo trì)
                if !licenseManager.featureConfig.skin {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.orange)

                            Text("HỆ THỐNG MOD SKIN ĐANG BẢO TRÌ")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)

                            Spacer()

                            Text("BẢO TRÌ")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }

                        Text("Hệ thống Mod Skin đang tạm bảo trì để cập nhật gói tài nguyên chống xung đột avatar.\n\n👉 Quý khách vui lòng sang [Trang Chủ] để bật tính năng APPLESTORE PRIME!")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(3)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .home
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "apple.logo")
                                Text("Chuyển sang Trang Chủ (Bật APPLESTORE PRIME)")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                LinearGradient(
                                    colors: [BlossomTheme.sakuraDeep, BlossomTheme.sakura],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: BlossomTheme.sakura.opacity(0.4), radius: 5)
                        }
                        .padding(.top, 2)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                // Danh Sách Bản Mod Skin
                if !skinItems.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(skinItems) { item in
                            SkinItemCard(
                                item: item,
                                isApplied: appliedProjectIDs.contains(item.id),
                                isWorking: workingPatchID == item.id,
                                isUnderMaintenance: isItemUnderMaintenance(item),
                                brandBlue: brandBlue,
                                onToggle: { enable in
                                    handleMaintenanceToggle(item: item, enable: enable)
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

    // MARK: - Footer thông tin thiết bị & iOS (To hơn 15%)
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
        HStack(spacing: 9) {
            HStack(spacing: 5) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(brandBlue)

                Text(AppInfo.hardwareDisplayName)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(Color.gray.opacity(0.45))

            HStack(spacing: 5) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                Text("iOS \(AppInfo.osVersion)")
                    .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if isDeviceSupported {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))

                    Text("Có hỗ trợ")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                }
                .padding(.horizontal, 8.5)
                .padding(.vertical, 3.8)
                .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.14))
                .cornerRadius(7)
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))

                    Text("Không hỗ trợ")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))
                }
                .padding(.horizontal, 8.5)
                .padding(.vertical, 3.8)
                .background(Color(red: 1.00, green: 0.28, blue: 0.28).opacity(0.14))
                .cornerRadius(7)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7.5)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.05, green: 0.08, blue: 0.14).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brandBlue.opacity(0.22), lineWidth: 0.9)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Thanh Dashboard Dưới (Limelight Nav Dock Bar Chuẩn IPA)
    private var bottomTabBar: some View {
        LimelightDockBar(selectedTab: $selectedTab, licenseManager: licenseManager)
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

    // MARK: - Maintenance Toggle Action
    private func handleMaintenanceToggle(item: PatchLibraryItem, enable: Bool) {
        if isItemUnderMaintenance(item) {
            if enable {
                let defaultMsg = "Chức năng '\(displayName(for: item))' hiện đang trong trạng thái KHÔNG AN TOÀN do hệ thống phát hiện rủi ro quét từ máy chủ game.\n\n👉 Để bảo vệ an toàn tuyệt đối cho tài khoản, vui lòng tạm dừng sử dụng hoặc bật [APPLESTORE PRIME] để bảo vệ!"
                let msg = (licenseManager.featureConfig.unsafe_message?.isEmpty ?? true)
                    ? ((licenseManager.featureConfig.maintenance_message?.isEmpty ?? true) ? defaultMsg : licenseManager.featureConfig.maintenance_message!)
                    : licenseManager.featureConfig.unsafe_message!
                alertMessage = "⚠️ CẢNH BÁO AN TOÀN:\n\n\(msg)"
                showAlert = true
            } else {
                handleToggle(item: item, enable: false)
            }
        } else {
            handleToggle(item: item, enable: enable)
        }
    }

    // MARK: - Toggle Mod Action
    private func handleToggle(item: PatchLibraryItem, enable: Bool) {
        // CHẶN BẬT nếu tính năng đang trong trạng thái không an toàn:
        if enable && isItemUnderMaintenance(item) {
            DispatchQueue.main.async {
                let defaultMsg = "Chức năng '\(self.displayName(for: item))' đang được đánh dấu KHÔNG AN TOÀN do nguy cơ quét từ máy chủ game.\n\n👉 Quý khách vui lòng BẬT tính năng [APPLESTORE PRIME] để bảo vệ tài khoản!"
                let msg = (self.licenseManager.featureConfig.unsafe_message?.isEmpty ?? true)
                    ? ((self.licenseManager.featureConfig.maintenance_message?.isEmpty ?? true) ? defaultMsg : self.licenseManager.featureConfig.maintenance_message!)
                    : self.licenseManager.featureConfig.unsafe_message!
                self.alertMessage = "⚠️ CẢNH BÁO AN TOÀN:\n\n\(msg)"
                self.showAlert = true
            }
            return
        }

        let currentID = item.id
        workingPatchID = currentID
        let modName = displayName(for: item)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if enable {
                    // BẬT chức năng (Apply)
                    // Khi bật APPLE IPA V2 hoặc APPLESTORE PRIME, tự động dọn dẹp sạch tất cả các mod khác để chống xung đột & văng game
                    if self.isAppleIpaV2Item(item) || self.isApplestorePrimeItem(item) {
                        let allOtherMods = [self.appleIpaV2Item, self.applestorePrimeItem, self.internalItem, self.espItem, self.aimneckVipItem, self.aimItem].compactMap { $0 } + self.skinItems
                        for other in allOtherMods where other.id != item.id && self.appliedProjectIDs.contains(other.id) {
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
                        CheatStoreSoundManager.shared.playSuccessSound()
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
        } else {
            previewSkinInfo = SkinPreviewInfo(
                title: "Mod Skin Ignis",
                subtitle: "Trang phục Đạo Sĩ Đỏ cực ngầu cho tướng Ignis",
                imageURL: "https://files.catbox.moe/0kjz3x.jpeg",
                localImageName: "skin_ignis"
            )
        }
    }

    private func displayName(for item: PatchLibraryItem) -> String {
        if isAppleIpaV2Item(item) {
            return "APPLE IPA V2"
        }
        if isApplestorePrimeItem(item) {
            return "APPLESTORE PRIME"
        }
        if isInternalItem(item) {
            return "INTERNAL"
        }
        if isAimneckVipItem(item) {
            return "AIMNECK VIP"
        }
        if isEspItem(item) {
            return "ĐỊNH VỊ NGƯỜI (ESP)"
        }
        if isSkinItem(item) {
            return item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
        }
        return "AIM DRAG (BẬT SẢNH)"
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

    // MARK: - Thực Thi 1-Chạm Khôi Phục Sạch
    private func performCleanRestore() {
        guard !isRestoringClean else { return }
        isRestoringClean = true

        DispatchQueue.global(qos: .userInitiated).async {
            // Phục hồi 100% file gốc từ Golden Snapshot và dọn sạch receipts
            DevicePatchService.cleanRestoreAllModifications()

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.appliedProjectIDs.removeAll()
                    self.workingPatchID = nil
                    self.isRestoringClean = false
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.alertMessage = "✅ ĐÃ KHÔI PHỤC SẠCH 100%!\n\nToàn bộ file gốc của Free Fire đã được phục hồi nguyên bản an toàn. Đã gỡ bỏ toàn bộ trạng thái mod."
                self.showAlert = true
            }
        }
    }

    // MARK: - Khởi Chạy Nhanh Game Free Fire
    private var isAnyModActive: Bool {
        !appliedProjectIDs.isEmpty
    }

    private var isAppOrAnyActiveModUnsafe: Bool {
        if !licenseManager.featureConfig.is_app_safe {
            return true
        }
        let allMods = [
            appleIpaV2Item,
            applestorePrimeItem,
            internalItem,
            aimneckVipItem,
            aimItem,
            espItem
        ].compactMap { $0 } + skinItems
        for item in allMods {
            if appliedProjectIDs.contains(item.id) && isItemUnderMaintenance(item) {
                return true
            }
        }
        return false
    }

    private var quickLaunchCardView: some View {
        Button {
            launchFreeFire()
        } label: {
            HStack(spacing: 13) {
                // Icon Free Fire bo góc có viền LED sáng (phóng to 10% từ 38 lên 42)
                ZStack {
                    FreeFireAppIconView(size: 42, cornerRadius: 11)

                    if isAnyModActive {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: isAppOrAnyActiveModUnsafe
                                        ? [Color.red, Color.orange]
                                        : [BlossomTheme.sakuraLight, brandBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.8
                            )
                            .frame(width: 42, height: 42)
                    }
                }
                .shadow(color: isAnyModActive ? (isAppOrAnyActiveModUnsafe ? Color.red.opacity(0.6) : brandBlue.opacity(0.6)) : Color.clear, radius: 6)

                VStack(alignment: .leading, spacing: 2.5) {
                    HStack(spacing: 6) {
                        Text("Free Fire")
                            .font(.system(size: 15.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if isAppOrAnyActiveModUnsafe {
                            Text("KHÔNG AN TOÀN")
                                .font(.system(size: 8.5, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.red)
                                .cornerRadius(3.5)
                        } else if isAnyModActive {
                            Text("SẴN SÀNG")
                                .font(.system(size: 8.5, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.green)
                                .cornerRadius(3.5)
                        } else {
                            Text("GỐC")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.gray)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(3.5)
                        }
                    }

                    Text(
                        isAppOrAnyActiveModUnsafe
                            ? "Cảnh báo quét: Tạm thời không an toàn"
                            : (isAnyModActive ? "Dữ liệu mod đã nạp • Sẵn sàng chiến" : "Chạm để vào Free Fire ngay")
                    )
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(
                        isAppOrAnyActiveModUnsafe
                            ? Color.red.opacity(0.9)
                            : (isAnyModActive ? BlossomTheme.sakuraLight : Color.gray)
                    )
                    .lineLimit(1)
                }

                Spacer()

                // Nút VÀO GAME / KHÔNG AN TOÀN (thiết kế vuông bo góc nhẹ 9px)
                HStack(spacing: 5) {
                    if isAppOrAnyActiveModUnsafe {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("KHÔNG AN TOÀN")
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("VÀO GAME")
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: isAppOrAnyActiveModUnsafe
                            ? [Color.red, Color(red: 0.82, green: 0.12, blue: 0.15)]
                            : [BlossomTheme.sakuraDeep, brandBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                )
                .shadow(
                    color: isAppOrAnyActiveModUnsafe
                        ? Color.red.opacity(0.55)
                        : brandBlue.opacity(0.55),
                    radius: 6,
                    x: 0,
                    y: 2
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.13, green: 0.06, blue: 0.22),
                                cardBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isAppOrAnyActiveModUnsafe
                            ? Color.red.opacity(0.7)
                            : (isAnyModActive ? BlossomTheme.sakuraLight.opacity(0.65) : brandBlue.opacity(0.2)),
                        lineWidth: (isAppOrAnyActiveModUnsafe || isAnyModActive) ? 1.4 : 0.8
                    )
            )
            .shadow(
                color: isAppOrAnyActiveModUnsafe
                    ? Color.red.opacity(0.3)
                    : (isAnyModActive ? brandBlue.opacity(0.25) : Color.black.opacity(0.25)),
                radius: 8,
                y: 3
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func launchFreeFire() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let targetSchemes = ["freefireth://", "freefire://", "dtsfreefire://"]

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

        if let primaryURL = URL(string: "freefireth://") {
            UIApplication.shared.open(primaryURL, options: [:]) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.alertMessage = "Đã nạp mod thành công! Thiết bị không hỗ trợ chuyển tiếp tự động, bạn vui lòng mở game Free Fire từ màn hình chính."
                        self.showAlert = true
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

// MARK: - ElectricAppLogoTile (Logo App với Hiệu Ứng Điện Quanh App & Phóng Sét Xuyên Qua App)
private struct ElectricAppLogoTile: View {
    var imageName: String? = nil
    var size: CGFloat = 42
    var cornerRadius: CGFloat = 11
    var isApplied: Bool = false
    var isUnderMaintenance: Bool = false
    var customGlowColor: Color? = nil

    @State private var electricAngle1: Double = 0
    @State private var electricAngle2: Double = 0
    @State private var lightningSweep: CGFloat = -1.2
    @State private var auraPulse: CGFloat = 1.0
    @State private var sparkFlash: Double = 0.8

    // Bảng màu xung điện tương tác thông minh
    private var coreGlow: Color {
        if let custom = customGlowColor { return custom }
        if isUnderMaintenance { return Color.red }
        if isApplied { return Color(red: 0.15, green: 0.95, blue: 0.55) } // High-voltage Overclock Green
        return BlossomTheme.sakura
    }

    private var electricCyan: Color {
        Color(red: 0.20, green: 0.90, blue: 1.0)
    }

    private var resolvedImage: UIImage? {
        if let name = imageName {
            if let img = UIImage(named: name) {
                return img
            }
            if let resPath = Bundle.main.resourcePath {
                let appCoreAssets = (resPath as NSString).appendingPathComponent("AppCore/Assets")
                let candidates = [name, "\(name).jpg", "\(name).png", "\(name).jpeg"]
                for c in candidates {
                    let p = (appCoreAssets as NSString).appendingPathComponent(c)
                    if let img = UIImage(contentsOfFile: p) { return img }
                }
            }
            if let path = Bundle.main.path(forResource: name, ofType: "jpg") ??
                          Bundle.main.path(forResource: name, ofType: "png") ??
                          Bundle.main.path(forResource: name, ofType: "jpeg"),
               let img = UIImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }

    var body: some View {
        ZStack {
            // 1. Quầng hào quang xung điện Tesla tỏa nền (Electric Plasma Halo)
            RoundedRectangle(cornerRadius: cornerRadius + 2, style: .continuous)
                .fill(coreGlow.opacity(isApplied ? 0.36 : (isUnderMaintenance ? 0.25 : 0.18)))
                .frame(width: size + 6, height: size + 6)
                .blur(radius: isApplied ? 5.5 : 3.5)
                .scaleEffect(auraPulse)

            // 2. Vòng tia điện ngoài xoay quanh viền Squircle (Outer Clockwise Electric Arc Ring)
            RoundedRectangle(cornerRadius: cornerRadius + 1.5, style: .continuous)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            coreGlow.opacity(0.95),
                            Color.white,
                            electricCyan.opacity(0.9),
                            Color.clear,
                            Color.clear,
                            coreGlow.opacity(0.7)
                        ]),
                        center: .center,
                        startAngle: .degrees(electricAngle1),
                        endAngle: .degrees(electricAngle1 + 360)
                    ),
                    lineWidth: isApplied ? 2.0 : 1.4
                )
                .frame(width: size + 3, height: size + 3)

            // 3. Vòng tia điện thứ 2 xoay ngược chiều tạo hiệu ứng cộng hưởng hồ quang (Counter-Clockwise Tesla Arc)
            RoundedRectangle(cornerRadius: cornerRadius + 1, style: .continuous)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.95),
                            isUnderMaintenance ? Color.yellow : electricCyan,
                            Color.clear,
                            coreGlow.opacity(0.6)
                        ]),
                        center: .center,
                        startAngle: .degrees(electricAngle2),
                        endAngle: .degrees(electricAngle2 + 360)
                    ),
                    lineWidth: 1.1
                )
                .frame(width: size + 1.5, height: size + 1.5)

            // 4. Logo App bên trong (App Core Identity)
            Group {
                if let uiImg = resolvedImage {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(coreGlow.opacity(0.6), lineWidth: 1.0)
                        )
                } else {
                    CheatStoreLogoView(size: size, cornerRadius: cornerRadius)
                }
            }
            .overlay(
                // 5. Tia điện & Chùm Laser cắt chéo xuyên qua app
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    ZStack {
                        // Chùm tia điện cắt chéo 45 độ xuyên tâm app
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.95),
                                        isUnderMaintenance ? Color.yellow.opacity(0.9) : (isApplied ? Color(red: 0.20, green: 0.98, blue: 0.65).opacity(0.9) : electricCyan.opacity(0.9)),
                                        Color.white.opacity(0.95),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 5, height: h * 1.6)
                            .rotationEffect(.degrees(45))
                            .offset(x: lightningSweep * (w * 1.35))
                            .blur(radius: 0.8)
                            .blendMode(.screen)

                        // Hạt vi chớp sáng điện tích phóng ngang tâm
                        Circle()
                            .fill(Color.white)
                            .frame(width: 2.8, height: 2.8)
                            .blur(radius: 0.6)
                            .offset(x: lightningSweep * (w * 0.7), y: lightningSweep * (h * 0.7))
                            .opacity(sparkFlash)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )

            // 6. Viền vòm kính phản chiếu trong suốt chống lóa
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.08),
                            coreGlow.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .frame(width: size, height: size)
        }
        .frame(width: size + 8, height: size + 8)
        .drawingGroup() // Tối ưu GPU Metal 60-90 FPS
        .onAppear {
            withAnimation(.linear(duration: isApplied ? 2.2 : 3.6).repeatForever(autoreverses: false)) {
                electricAngle1 = 360
            }
            withAnimation(.linear(duration: isApplied ? 2.8 : 4.6).repeatForever(autoreverses: false)) {
                electricAngle2 = -360
            }
            withAnimation(.easeInOut(duration: isApplied ? 1.4 : 2.2).repeatForever(autoreverses: false)) {
                lightningSweep = 1.2
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                auraPulse = isApplied ? 1.06 : 1.02
                sparkFlash = 0.25
            }
        }
    }
}

// MARK: - ModernCleanCardRow (Thẻ Chức Năng Gọn Gàng, Chuyên Nghiệp, Nhỏ Lại 10% & Mượt Mà 60-90 FPS)
private struct ModernCleanCardRow: View {
    let title: String
    var subtitle: String? = nil
    var imageName: String? = "CheatLogo"
    var glowColor: Color = BlossomTheme.sakura
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = false
    let brandBlue: Color
    let onToggle: (Bool) -> Void
    var onIconTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            // 1. Icon Logo App đồng bộ với hiệu ứng điện quanh app & chùm laser (-10% nhỏ gọn 38pt)
            Button {
                if let onIconTap = onIconTap {
                    onIconTap()
                } else if !isWorking && !isUnderMaintenance {
                    onToggle(!isApplied)
                }
            } label: {
                ElectricAppLogoTile(
                    imageName: imageName ?? "CheatLogo",
                    size: 38,
                    cornerRadius: 10,
                    isApplied: isApplied,
                    isUnderMaintenance: isUnderMaintenance,
                    customGlowColor: isUnderMaintenance ? Color.red : glowColor
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // 2. Nội dung: Tên ở trên, mô tả nhỏ ở dưới
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 9.8, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            Spacer(minLength: 8)

            // 3. Vị trí nút bật/tắt: Khi KHÔNG AN TOÀN thì thay thế hoàn toàn công tắc bằng nhãn "KHÔNG AN TOÀN"
            if isWorking {
                ProgressView()
                    .tint(brandBlue)
                    .scaleEffect(0.8)
                    .frame(width: 44, height: 26)
            } else if isUnderMaintenance {
                // Nhãn KHÔNG AN TOÀN thay thế hoàn toàn vị trí nút bật tắt
                Text("KHÔNG AN TOÀN")
                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4.5)
                    .background(Color.red.opacity(0.92))
                    .cornerRadius(5.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.5)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                    .shadow(color: Color.red.opacity(0.4), radius: 4)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newVal in
                        onToggle(newVal)
                    }
                ))
                .labelsHidden()
                .tint(brandBlue)
                .scaleEffect(0.9) // Tối ưu nhỏ lại 10%
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8) // Tối ưu nhỏ lại 10%
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.05, blue: 0.22).opacity(0.92),
                    Color(red: 0.07, green: 0.03, blue: 0.14).opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(11)
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(
                    isApplied
                        ? glowColor.opacity(0.9)
                        : (isUnderMaintenance ? Color.red.opacity(0.3) : Color.white.opacity(0.08)),
                    lineWidth: isApplied ? 1.4 : 0.9
                )
        )
        .shadow(
            color: isApplied ? glowColor.opacity(0.32) : Color.clear,
            radius: 6
        )
        .contentShape(RoundedRectangle(cornerRadius: 11))
        .onTapGesture {
            if !isWorking && !isUnderMaintenance {
                onToggle(!isApplied)
            }
        }
    }
}

// MARK: - AppleIpaV2Card
private struct AppleIpaV2Card: View {
    let item: PatchLibraryItem?
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = false
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "APPLE IPA V2",
            subtitle: "Menu iOS V2",
            imageName: "CheatLogo",
            glowColor: BlossomTheme.sakura,
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle
        )
    }
}

// MARK: - InternalCard
private struct InternalCard: View {
    let item: PatchLibraryItem?
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = false
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "INTERNAL",
            subtitle: "Menu internal",
            imageName: "CheatLogo",
            glowColor: Color(red: 0.20, green: 0.90, blue: 1.0),
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle
        )
    }
}

// MARK: - ApplestorePrimeCard
private struct ApplestorePrimeCard: View {
    let item: PatchLibraryItem?
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = false
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "AppleStore PRIME",
            subtitle: "Menu CheatStoreVN",
            imageName: "CheatLogo",
            glowColor: Color(red: 0.95, green: 0.25, blue: 0.45),
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle
        )
    }
}

// MARK: - AimneckVipCard
private struct AimneckVipCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = true
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "AimNeck VIP",
            subtitle: "Ghim cổ chống soi",
            imageName: "CheatLogo",
            glowColor: Color(red: 0.70, green: 0.40, blue: 1.0),
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle
        )
    }
}

// MARK: - CheatItemCard (AIM DRAG)
private struct CheatItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = false
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "Aim Drag",
            subtitle: "Trợ lực ghì tâm sảnh",
            imageName: "CheatLogo",
            glowColor: Color(red: 0.98, green: 0.55, blue: 0.20),
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle
        )
    }
}

// MARK: - EspItemCard (ĐỊNH VỊ NGƯỜI ESP)
private struct EspItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = true
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "Định Vị ESP",
            subtitle: "Hiện khung & khoảng cách",
            imageName: "CheatLogo",
            glowColor: Color(red: 0.20, green: 0.85, blue: 0.45),
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle
        )
    }
}

// MARK: - SkinItemCard (MOD SKIN IGNIS / THẺ VÔ CỰC MÙA 1)
private struct SkinItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = true
    let brandBlue: Color
    let onToggle: (Bool) -> Void
    let onPreview: () -> Void

    var body: some View {
        ModernCleanCardRow(
            title: "Mod Skin IGNIS",
            subtitle: "Trang phục VIP & Hiệu ứng sảnh",
            imageName: "CheatLogo",
            glowColor: Color(red: 1.0, green: 0.85, blue: 0.25),
            isApplied: isApplied,
            isWorking: isWorking,
            isUnderMaintenance: isUnderMaintenance,
            brandBlue: brandBlue,
            onToggle: onToggle,
            onIconTap: onPreview
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

