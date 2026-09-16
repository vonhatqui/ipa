import SwiftUI
import UIKit

enum CheatStoreTab: Int, CaseIterable {
    case home = 0
    case esp = 1
    case profile = 2

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .esp: return "Định Vị"
        case .profile: return "Cá Nhân"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .esp: return "location.viewfinder"
        case .profile: return "person.crop.circle.fill"
        }
    }
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

    // Theme: Blossom Dark Sakura (#c084fc & Midnight Purple)
    private let brandBlue = BlossomTheme.sakura         // #c084fc
    private let brandBlueDark = BlossomTheme.sakuraDeep // #a855f7
    private let darkBackground = BlossomTheme.bgBottom  // #09040f
    private let cardBackground = Color(red: 0.082, green: 0.043, blue: 0.137) // #150b23
    private let discordRenewalURL = "https://discord.gg/A3wS4ZPFQn"

    // Phân loại mod: AIMDRAG PRO ở Trang Chủ, ESP 2.0 ở Tab Định Vị
    private func isEspItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? "").lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("định vị") || name.contains("dinh vi") || name.contains("dinhvi") || name.contains("esp") || name.contains("blue") || filename.contains("network")
    }

    private func isAimItem(_ item: PatchLibraryItem) -> Bool {
        return !isEspItem(item)
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
                    case .profile:
                        profileView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Nút Mở Game Free Fire Nằm Ngay Trên Thanh Dashboard Điều Hướng
                if selectedTab == .home || selectedTab == .esp {
                    quickLaunchCardView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Thanh Dashboard điều hướng phía dưới
                bottomTabBar

                // Footer thông tin thiết bị & phiên bản iOS & trạng thái hỗ trợ
                deviceStatusFooterView
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

            if selectedTab == .home || selectedTab == .esp {
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

                // Danh Sách Bản Mod
                if aimItems.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 14) {
                        ForEach(aimItems) { item in
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
                        Text("BẢNG ĐIỀU KHIỂN ĐỊNH VỊ (ESP)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.1)

                        Text("Bật / Tắt ESP 2.0 Xuyên Tường Trực Tiếp")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                if espItems.isEmpty {
                    emptyEspStateView
                } else {
                    VStack(spacing: 14) {
                        ForEach(espItems) { item in
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
                    }
                    .padding(.horizontal, 20)

                    // Thông tin tính năng Định Vị
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.viewfinder")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(brandBlue)

                            Text("Tính năng Định Vị (ESP)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            featureBullet(text: "Hiển thị vị trí kẻ địch xuyên vật cản và địa hình")
                            featureBullet(text: "Hiện khoảng cách chính xác theo thời gian thực")
                            featureBullet(text: "Tương thích 100% khi bật song song với AIMDRAG PRO")
                            featureBullet(text: "Bảo vệ tài khoản với cơ chế chống phát hiện Antiban")
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

                            Text("Thoát hẳn Free Fire khỏi đa nhiệm > Bật [ESP 2.0] > Bấm nút [MỞ] Free Fire bên dưới để vào trận mượt mà.")
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
                    .lineLimit(1)
            }

            Text("•")
                .font(.system(size: 10))
                .foregroundStyle(Color.gray.opacity(0.4))

            // Phiên bản iOS (Ví dụ: iOS 17.5.1)
            HStack(spacing: 4) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))

                Text("iOS \(AppInfo.osVersion)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Trạng thái Hỗ trợ: Tích xanh có hỗ trợ / Dấu X đỏ không hỗ trợ
            if isDeviceSupported {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))

                    Text("Có hỗ trợ")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.12))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.3), lineWidth: 0.8)
                )
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))

                    Text("Không hỗ trợ")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 1.00, green: 0.28, blue: 0.28))
                }
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

    private func displayName(for item: PatchLibraryItem) -> String {
        if isEspItem(item) {
            return "ESP 2.0"
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

// MARK: - EspItemCard (Định Vị Xuyên Tường VIP)
private struct EspItemCard: View {
    let item: PatchLibraryItem
    let isApplied: Bool
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    var body: some View {
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        isApplied
                            ? BlossomTheme.sakuraLight
                            : brandBlue
                    )
                    .shadow(color: isApplied ? BlossomTheme.sakuraLight.opacity(0.8) : .clear, radius: 6)
            }

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("ESP 2.0")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("ESP 2.0")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [BlossomTheme.sakura, BlossomTheme.sakuraDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }

                Text("Định Vị Người Chơi • Xuyên Tường")
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
                .stroke(isApplied ? BlossomTheme.sakura.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isApplied ? brandBlue.opacity(0.2) : .clear, radius: 8)
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
