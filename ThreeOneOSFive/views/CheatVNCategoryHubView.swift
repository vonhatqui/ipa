import SwiftUI
import UIKit

/// CheatVNCategoryEnum: 2 Danh mục chức năng chính theo yêu cầu
enum CheatVNCategoryItem: String, CaseIterable, Identifiable {
    case cheatVNExternal = "cheatvn_external"
    case espAimSilent = "esp_aim_silent"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cheatVNExternal:
            return "CheatVN External"
        case .espAimSilent:
            return "ESP & AIM SILENT"
        }
    }

    var badge: String {
        switch self {
        case .cheatVNExternal:
            return "HEADLESS • EXTERNAL MENU"
        case .espAimSilent:
            return "AIM SILENT 40% • ESP PLAYER"
        }
    }

    var description: String {
        switch self {
        case .cheatVNExternal:
            return "Bộ điều khiển External VIP Suite cao cấp với 4 phân hệ (Aimbot, Visual ESP, Misc, Setting), bảo vệ an toàn 100%."
        case .espAimSilent:
            return "Nạp gói hotfix Aim Silent 40% & ESP Player không giật tâm, đã tinh chỉnh nhãn hiệu CheatVN External verified chuẩn 5 file."
        }
    }

    var logoImageName: String {
        switch self {
        case .cheatVNExternal:
            return "cheatvn_logo"
        case .espAimSilent:
            return "esp_aimsilent_logo"
        }
    }

    var accentColor: Color {
        switch self {
        case .cheatVNExternal:
            return Color(red: 0/255, green: 210/255, blue: 255/255)
        case .espAimSilent:
            return Color(red: 0/255, green: 230/255, blue: 118/255)
        }
    }
}

/// CheatVNCategoryHubView: Màn hình Danh Mục xuất hiện ngay sau khi chọn Free Fire
struct CheatVNCategoryHubView: View {
    @AppStorage("cheatstore_selected_game_version") private var selectedGameVersionRaw: String = FreeFireGameVersion.standard.rawValue
    @ObservedObject var patchService = CheatVNPatchService.shared

    var onBackToGameSelection: () -> Void

    // Điều hướng vào chi tiết từng danh mục
    @State private var activeCategory: CheatVNCategoryItem? = nil
    @State private var showSettings: Bool = false

    // Colors
    private let bgVoid = Color(red: 11/255, green: 12/255, blue: 15/255)
    private let cardBg = Color(red: 20/255, green: 21/255, blue: 27/255)
    private let cardBorder = Color(red: 35/255, green: 37/255, blue: 47/255)
    private let textPrimary = Color(red: 242/255, green: 242/255, blue: 247/255)
    private let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)

    private var currentGameVersion: FreeFireGameVersion {
        FreeFireGameVersion(rawValue: selectedGameVersionRaw) ?? .standard
    }

    var body: some View {
        ZStack {
            if let active = activeCategory {
                // Hiển thị màn hình chi tiết của danh mục được chọn
                switch active {
                case .cheatVNExternal:
                    CheatStoreExternalDashboardView(onBackToGames: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeCategory = nil
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                case .espAimSilent:
                    EspAimSilentDetailDashboardView(onBackToCategories: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeCategory = nil
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            } else {
                // Màn hình chính DANH MỤC
                categoryListView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .sheet(isPresented: $showSettings) {
            DeltaStyleSettingsView()
        }
    }

    // MARK: - Category List View
    private var categoryListView: some View {
        ZStack {
            // Nền đen True Dark kết hợp Snapchat Fluid Background nhẹ
            bgVoid.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (Nút quay lại chọn game + Tiêu đề + Nút Cài đặt)
                topHeaderView
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Thanh thông số game đang chọn
                selectedGameStatusRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Tiêu đề danh mục
                        HStack {
                            Text("DANH MỤC CHỨC NĂNG (2)")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .tracking(1.8)
                                .foregroundColor(Color.white.opacity(0.65))

                            Spacer()

                            Text("CHỌN ĐỂ MỞ")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0/255, green: 210/255, blue: 255/255))
                        }
                        .padding(.horizontal, 4)

                        // 1. Thẻ Danh Mục: CheatVN External
                        categoryCardView(item: .cheatVNExternal)

                        // 2. Thẻ Danh Mục: ESP & AIM SILENT
                        categoryCardView(item: .espAimSilent)

                        // Banner nhắc nhở an toàn
                        safetyGuideBanner
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
            }
        }
    }

    // MARK: - Top Header
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onBackToGameSelection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Đổi Game")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("CHEATVN HUB")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(textPrimary)
                Text("Trung Tâm Danh Mục")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(textSecondary)
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Selected Game Status
    private var selectedGameStatusRow: some View {
        HStack(spacing: 12) {
            FreeFireAppIconView(size: 38, cornerRadius: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text(currentGameVersion == .standard ? "Free Fire (Bản Thường)" : "Free Fire MAX (Bản Cao Cấp)")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(currentGameVersion == .standard ? "com.dts.freefireth" : "com.dts.freefiremax")
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0/255, green: 230/255, blue: 118/255))
                    .frame(width: 7, height: 7)

                Text("ĐÃ KẾT NỐI")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0/255, green: 230/255, blue: 118/255))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(red: 0/255, green: 230/255, blue: 118/255).opacity(0.12))
            .cornerRadius(8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 22/255, green: 24/255, blue: 32/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Category Card View
    private func categoryCardView(item: CheatVNCategoryItem) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                activeCategory = item
            }
        }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    CategoryLogoView(name: item.logoImageName, fallbackIcon: "folder.fill", size: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundColor(textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.4))
                        }

                        Text(item.badge)
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(item.accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(item.accentColor.opacity(0.15))
                            .cornerRadius(6)
                    }
                }

                Text(item.description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(item.accentColor)
                        Text(item == .espAimSilent ? (patchService.isPatchApplied ? "Đang Hoạt Động" : "Sẵn Sàng Nạp") : "External Overlay Sẵn Sàng")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(item == .espAimSilent && patchService.isPatchApplied ? Color.green : textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Vào Chức Năng")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(item.accentColor)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(item.accentColor)
                    }
                }
                .padding(.top, 2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [cardBg, Color(red: 16/255, green: 17/255, blue: 23/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(item.accentColor.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
        }
    }

    // MARK: - Safety Banner
    private var safetyGuideBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(red: 0/255, green: 210/255, blue: 255/255))

            VStack(alignment: .leading, spacing: 2) {
                Text("Hướng Dẫn Nạp Đúng Logic:")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Chọn danh mục 'ESP & AIM SILENT' để nạp trực tiếp patch vào game Free Fire hoặc 'CheatVN External' để cấu hình menu.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
            }
        }
        .padding(14)
        .background(Color(red: 18/255, green: 24/255, blue: 34/255))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0/255, green: 210/255, blue: 255/255).opacity(0.2), lineWidth: 1))
    }
}
