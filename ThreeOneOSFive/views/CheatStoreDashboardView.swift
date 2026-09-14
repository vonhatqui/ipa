import SwiftUI
import UIKit

enum CheatStoreTab: Int, CaseIterable {
    case home = 0
    case modSkin = 1
    case profile = 2

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .modSkin: return "ModSkin"
        case .profile: return "Cá Nhân"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .modSkin: return "tshirt.fill"
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

    @State private var selectedTab: CheatStoreTab = .home
    @State private var workingPatchID: UUID?
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var copiedKey = false
    @State private var copiedDeviceID = false
    @State private var showEspSettings = false

    // Theme: Xanh Dương Đen (Cyber Blue & AMOLED Dark)
    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00) // Electric Cyan #00b8ff
    private let brandBlueDark = Color(red: 0.00, green: 0.45, blue: 0.90)
    private let darkBackground = Color(red: 0.03, green: 0.05, blue: 0.09) // Deep AMOLED Navy
    private let cardBackground = Color(red: 0.06, green: 0.09, blue: 0.16)
    private let discordRenewalURL = "https://discord.gg/A3wS4ZPFQn"

    // Phân loại mod
    private var aimItems: [PatchLibraryItem] {
        patchStore.items.filter { !isSkinItem($0) }
    }

    private var skinItems: [PatchLibraryItem] {
        patchStore.items.filter { isSkinItem($0) }
    }

    private func isSkinItem(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? "").lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("skin") || name.contains("ignis") || name.contains("avatar")
            || filename.contains("skin") || filename.contains("ignis")
    }

    var body: some View {
        ZStack {
            // Nền đen xanh AMOLED
            darkBackground.ignoresSafeArea()

            // Vầng sáng neon xanh dương
            Circle()
                .fill(brandBlue.opacity(0.12))
                .blur(radius: 80)
                .frame(width: 280, height: 280)
                .offset(x: 0, y: -240)

            VStack(spacing: 0) {
                // Header thanh trên
                topHeaderView

                // Nội dung theo Tab đã chọn
                ZStack {
                    switch selectedTab {
                    case .home:
                        homeView
                    case .modSkin:
                        modSkinView
                    case .profile:
                        profileView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .sheet(isPresented: $showEspSettings) {
            EspSettingsSheetView {
                if let espItem = aimItems.first {
                    handleSaveEspSettings(item: espItem)
                }
            }
        }
        .onAppear {
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)
        }
    }

    // MARK: - Top Header
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            CheatStoreLogoView(size: 34, cornerRadius: 9)

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

            if selectedTab == .home {
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
            VStack(spacing: 18) {
                // Banner Tiêu Đề
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BẢNG ĐIỀU KHIỂN CHỨC NĂNG")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.1)

                        Text("Bật / Tắt Mod & Tiện Ích Trực Tiếp")
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
                                isWorking: workingPatchID == item.id,
                                brandBlue: brandBlue,
                                onToggle: { enable in
                                    handleToggle(item: item, enable: enable)
                                },
                                onOpenSettings: {
                                    showEspSettings = true
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

                        Text("Thoát hẳn game Free Fire > Bật mod trong CheatStore VN > Mở game vào trận. Khi không chơi nữa, hãy tắt mod để an toàn 100%.")
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

    // MARK: - Tab 2: ModSkin (Kho Mod Skin VIP)
    private var modSkinView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Tiêu đề phần ModSkin
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KHO MOD SKIN TRANG PHỤC")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.1)

                        Text("Bật / Tắt Skin Trực Tiếp Trước Khi Vào Trận")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                if skinItems.isEmpty {
                    modSkinEmptyView
                } else {
                    VStack(spacing: 14) {
                        ForEach(skinItems) { item in
                            ModSkinItemCard(
                                item: item,
                                isWorking: workingPatchID == item.id,
                                brandBlue: brandBlue,
                                onToggle: { enable in
                                    handleToggle(item: item, enable: enable)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Hướng dẫn đổi skin
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(brandBlue)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quy trình đổi skin:")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Thoát hẳn game Free Fire > Bật skin mong muốn trong CheatStore VN > Mở game để thưởng thức hiệu ứng skin. Tắt mod khi muốn trở về mặc định.")
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
                    .padding(.top, 8)

                    // Yêu cầu skin qua Discord
                    Button {
                        if let url = URL(string: discordRenewalURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Yêu Cầu Thêm Skin Mới (Discord)")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(brandBlue.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var modSkinEmptyView: some View {
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

                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(brandBlue)
            }

            VStack(spacing: 8) {
                Text("MOD SKIN TRANG PHỤC")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("ĐANG CẬP NHẬT THÊM")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(20)

                Text("Đang hoàn thiện thêm các gói Mod Skin súng & trang phục tự động. Vui lòng theo dõi Discord CheatStore để nhận bản update mới nhất!")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
            }

            Button {
                if let url = URL(string: discordRenewalURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Tham Gia Discord Nhận Tin")
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

    // MARK: - Tab 3: Cá Nhân (Thời Hạn Key, Gia Hạn, Đăng Xuất)
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
        .background(Color(red: 0.05, green: 0.08, blue: 0.14).opacity(0.96))
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
                .fill(Color(red: 0.05, green: 0.08, blue: 0.14).opacity(0.92))
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

    // MARK: - Toggle Mod Action
    private func handleToggle(item: PatchLibraryItem, enable: Bool) {
        workingPatchID = item.id
        let modName = displayName(for: item)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if enable {
                    // BẬT chức năng (Apply)
                    guard var project = item.project else {
                        throw PatchPackageError.unsupportedFormat
                    }

                    // Tự động nạp cấu hình tùy chỉnh ESP của người dùng
                    if isAimOrEsp(item) {
                        EspConfigManager.shared.applyConfiguration(to: &project)
                    }

                    // 1. Dọn dẹp sạch receipt cũ bị kẹt nếu có để không bị lỗi projectAlreadyApplied
                    DevicePatchService.forceCleanupReceipts(projectID: item.id)

                    // 2. Thực hiện Apply bản mod vào game
                    _ = try DevicePatchService.apply(project: project)

                    DispatchQueue.main.async {
                        self.patchStore.reload()
                        self.workingPatchID = nil
                        self.alertMessage = "Đã BẬT thành công: \(modName)"
                        self.showAlert = true
                    }
                } else {
                    // TẮT chức năng (Restore)
                    let receipt = DevicePatchService.latestReceipt(projectID: item.id)
                    if let receipt {
                        do {
                            try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                        } catch {
                            // Fallback phục hồi cưỡng chế: trả lại file gốc hoặc xoá mod file
                            DevicePatchService.forceRestoreAndCleanup(receipt: receipt, project: item.project)
                        }
                    } else {
                        // Không tìm thấy receipt nhưng bấm tắt -> dọn dẹp sạch file mod trong game
                        DevicePatchService.forceCleanup(project: item.project)
                        DevicePatchService.forceCleanupReceipts(projectID: item.id)
                    }

                    DispatchQueue.main.async {
                        self.patchStore.reload()
                        self.workingPatchID = nil
                        self.alertMessage = "Đã TẮT và khôi phục an toàn: \(modName)"
                        self.showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.patchStore.reload()
                    self.workingPatchID = nil
                    let friendlyError = self.userFriendlyErrorMessage(error)
                    self.alertMessage = "Thao tác thất bại: \(friendlyError)"
                    self.showAlert = true
                }
            }
        }
    }

    private func handleSaveEspSettings(item: PatchLibraryItem) {
        // 1. Ghi đè cấu hình mới trực tiếp vào container game nếu máy đã cài game
        EspConfigManager.shared.syncDirectlyToGameContainer()

        // 2. Nếu mod đang BẬT, re-apply project với cấu hình mới
        if DevicePatchService.isProjectApplied(projectID: item.id) {
            workingPatchID = item.id
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard var project = item.project else { return }
                    EspConfigManager.shared.applyConfiguration(to: &project)
                    DevicePatchService.forceCleanupReceipts(projectID: item.id)
                    _ = try DevicePatchService.apply(project: project)
                    DispatchQueue.main.async {
                        self.patchStore.reload()
                        self.workingPatchID = nil
                        self.alertMessage = "Đã lưu và kích hoạt cấu hình ESP mới vào game!"
                        self.showAlert = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.workingPatchID = nil
                    }
                }
            }
        }
    }

    private func isAimOrEsp(_ item: PatchLibraryItem) -> Bool {
        let name = (item.project?.name ?? "").lowercased()
        let filename = item.packageURL.lastPathComponent.lowercased()
        return name.contains("esp") || name.contains("aim") || filename.contains("esp") || filename.contains("core") || name.isEmpty
    }

    private func displayName(for item: PatchLibraryItem) -> String {
        let name = item.project?.name ?? ""
        if name.lowercased().contains("esp") || name.lowercased().contains("aim") || name.isEmpty {
            return "Định Vị & AimNeck 2.0"
        }
        if name.lowercased().contains("ignis") {
            return "IGNIS ĐẠO SĨ ĐỎ"
        }
        return name
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
                return "Dữ liệu cấu hình mod không hợp lệ."
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
}

// MARK: - CheatItemCard (Định Vị & AimNeck 2.0)
private struct CheatItemCard: View {
    let item: PatchLibraryItem
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void
    var onOpenSettings: (() -> Void)? = nil

    // Đổi tên chức năng thành "Định Vị & AimNeck 2.0" theo yêu cầu
    private var displayName: String {
        let name = item.project?.name ?? ""
        if name.lowercased().contains("esp") || name.lowercased().contains("aim") || name.isEmpty {
            return "Định Vị & AimNeck 2.0"
        }
        return name
    }

    // Mô tả chữ nhỏ ở dưới: "Antiban - No Backlist"
    private var subtitle: String {
        "Antiban - No Backlist"
    }

    private var isApplied: Bool {
        DevicePatchService.isProjectApplied(projectID: item.id)
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
                Text(displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

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

                // Nút Mở Menu Cài Đặt ESP
                if let onOpen = onOpenSettings {
                    Button {
                        onOpen()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 10, weight: .bold))
                            Text("Cài Đặt ESP")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(brandBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(brandBlue.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(brandBlue.opacity(0.35), lineWidth: 0.8)
                        )
                    }
                    .padding(.top, 3)
                }
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
        .background(Color(red: 0.06, green: 0.09, blue: 0.16))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? brandBlue.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - ModSkinItemCard (Kho Mod Skin VIP)
private struct ModSkinItemCard: View {
    let item: PatchLibraryItem
    let isWorking: Bool
    let brandBlue: Color
    let onToggle: (Bool) -> Void

    private var displayName: String {
        let name = item.project?.name ?? ""
        if name.lowercased().contains("ignis") {
            return "IGNIS ĐẠO SĨ ĐỎ"
        }
        return name.isEmpty ? "MOD SKIN VIP" : name
    }

    private var subtitle: String {
        "Skin Trang Phục VIP • Antiban"
    }

    private var isApplied: Bool {
        DevicePatchService.isProjectApplied(projectID: item.id)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon Skin với hiệu ứng ngọn lửa neon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                (isApplied ? Color.red : brandBlue).opacity(0.2),
                                Color(red: 0.05, green: 0.07, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isApplied ? Color.red : brandBlue.opacity(0.4), lineWidth: 1.5)
                    )

                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isApplied ? Color.red : brandBlue)
            }

            // Tên và thông tin Skin
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("VIP")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
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
        .background(Color(red: 0.06, green: 0.09, blue: 0.16))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? brandBlue.opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
