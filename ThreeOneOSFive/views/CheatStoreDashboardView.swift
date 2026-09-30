import SwiftUI
import UIKit

/// Màn hình điều khiển chính: APPLE IPA V2 (Main 2)
/// Tối ưu sạch sẽ 100%: Loại bỏ toàn bộ banner giới thiệu rườm rà.
/// Đưa toàn bộ chức năng từ menu trong game ra ngoài app thành 5 công tắc (Toggles) độc lập.
/// Dưới cùng là nút INJECTOR 1-chạm cực kỳ chuẩn chỉ.
struct CheatStoreDashboardView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    @ObservedObject private var antibanService = AntibanProfileService.shared
    @StateObject private var injector = AppleIpaV2Injector.shared

    var onBackToGames: (() -> Void)? = nil

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCleanConfirm = false
    @State private var showGameMenuTip = false

    // Theme: Blossom Dark Sakura (#c084fc & Midnight Purple)
    private let brandSakura = BlossomTheme.sakura
    private let brandSakuraLight = BlossomTheme.sakuraLight
    private let brandSakuraDeep = BlossomTheme.sakuraDeep
    private let cardBackground = Color(red: 0.082, green: 0.043, blue: 0.137) // #150b23

    var body: some View {
        ZStack {
            // Nền hoa anh đào chuyển động
            BlossomBackgroundView(showParticles: true)

            VStack(spacing: 0) {
                // Header thanh trên gọn gàng
                topHeaderBar
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Thẻ Thông Tin Nhận Diện Game & Chế Độ Không Menu
                        gameStatusBannerCard

                        // Khung Danh Sách 5 Tính Năng Toggles Độc Lập
                        featuresToggleSection

                        // Khung Hướng Dẫn / Trạng Thái Nạp
                        statusNoticeBox

                        // Nút INJECTOR 1-CHẠM & Khởi Chạy
                        actionButtonsSection
                            .padding(.top, 4)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                }

                // Footer trạng thái thiết bị tối giản
                minimalFooterView
                    .padding(.bottom, 6)
            }
        }
        .onAppear {
            injector.refreshStatus()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Thông báo"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
        .confirmationDialog(
            "Khôi phục sạch dữ liệu gốc Free Fire?",
            isPresented: $showCleanConfirm,
            titleVisibility: .visible
        ) {
            Button("Khôi phục sạch 100% file gốc", role: .destructive) {
                injector.performCleanRestore { result in
                    switch result {
                    case .success:
                        self.alertMessage = "Đã khôi phục sạch 100% dữ liệu gốc của Free Fire!"
                        self.showAlert = true
                    case .failure(let err):
                        self.alertMessage = "Lỗi khôi phục: \(err.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
            Button("Hủy", role: .cancel) { }
        }
    }

    // MARK: - 1. Top Header Bar
    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            if let onBack = onBackToGames {
                Button {
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                        Text("Game")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(brandSakura)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(brandSakura.opacity(0.12))
                    .cornerRadius(8)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("APPLE IPA V2")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.white, brandSakuraLight], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: brandSakura.opacity(0.6), radius: 6, x: 0, y: 0)

                    Text("MAIN 2")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 1.0, green: 0.85, blue: 0.3))
                        .cornerRadius(4)
                }

                Text("Apple IPA V2 • Giao Diện Menu Mới Đậm Nét")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Badge trạng thái nạp
            HStack(spacing: 5) {
                Circle()
                    .fill(injector.isInjected ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                    .shadow(color: (injector.isInjected ? Color.green : Color.orange).opacity(0.8), radius: 4)

                Text(injector.isInjected ? "ĐÃ NẠP" : "CHƯA NẠP")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(injector.isInjected ? .green : .orange)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4.5)
            .background((injector.isInjected ? Color.green : Color.orange).opacity(0.12))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke((injector.isInjected ? Color.green : Color.orange).opacity(0.3), lineWidth: 0.8)
            )
        }
    }

    // MARK: - 2. Thẻ Trạng Thái Nhận Diện Game
    private var gameStatusBannerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(brandSakura.opacity(0.18))
                    .frame(width: 40, height: 40)

                Image(systemName: "shield.checkered")
                    .font(.system(size: 20))
                    .foregroundColor(brandSakura)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(injector.detectedGameTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    if injector.hasDetectedGame {
                        Text("SẴN SÀNG")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }

                Text("Menu nổi trong game đã vẽ lại UI mới: màu sắc tương phản cao, chữ +20%, dễ bấm.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(cardBackground.opacity(0.92))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(brandSakura.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - 3. Khung 5 Tính Năng Toggles Độc Lập
    private var featuresToggleSection: some View {
        VStack(spacing: 11) {
            // Tiêu đề danh mục
            HStack {
                Text("CÁC CHỨC NĂNG MENU NỔI TRONG GAME")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(brandSakura)
                    .tracking(0.8)

                Spacer()

                Text("Tùy biến trong trận")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)

            // 1. Khóa Tâm Aimbot
            FeatureToggleRow(
                title: "Khóa Tâm Aimbot",
                subtitle: "Tự động khóa tâm vào Cổ & Đầu địch khi ngắm bắn",
                iconName: "scope",
                iconColor: Color(red: 0.95, green: 0.25, blue: 0.45),
                isOn: $injector.isAimbotEnabled,
                brandSakura: brandSakura
            )

            // 2. Đạn Ma Thuật Silent Aim
            FeatureToggleRow(
                title: "Đạn Ma Thuật Silent Aim",
                subtitle: "Bẻ hướng quỹ đạo đường đạn trúng mục tiêu gần nhất",
                iconName: "bolt.fill",
                iconColor: Color(red: 1.0, green: 0.78, blue: 0.20),
                isOn: $injector.isSilentAimEnabled,
                brandSakura: brandSakura
            )

            // 3. Chống Giật Súng No Recoil
            FeatureToggleRow(
                title: "Chống Giật Súng No Recoil",
                subtitle: "Triệt tiêu 100% độ tản đạn & giật của mọi loại súng",
                iconName: "shield.lefthalf.filled",
                iconColor: Color(red: 0.25, green: 0.88, blue: 0.45),
                isOn: $injector.isNoRecoilEnabled,
                brandSakura: brandSakura
            )

            // 4. Định Vị ESP Box & Line
            FeatureToggleRow(
                title: "Định Vị ESP Box & Line",
                subtitle: "Vẽ khung chữ nhật và tia định vị đối thủ sắc nét",
                iconName: "viewfinder",
                iconColor: Color(red: 0.75, green: 0.40, blue: 1.0),
                isOn: $injector.isEspBoxLineEnabled,
                brandSakura: brandSakura
            )

            // 5. Tên Địch & Khoảng Cách
            FeatureToggleRow(
                title: "Tên Địch & Khoảng Cách",
                subtitle: "Hiện tên đối thủ và số mét khoảng cách chính xác",
                iconName: "person.text.rectangle.fill",
                iconColor: Color(red: 0.25, green: 0.75, blue: 1.0),
                isOn: $injector.isEspNameDistEnabled,
                brandSakura: brandSakura
            )
        }
    }

    // MARK: - 4. Khung Thông Báo Trạng Thái
    private var statusNoticeBox: some View {
        HStack(spacing: 8) {
            Image(systemName: injector.isInjected ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(injector.isInjected ? .green : brandSakura)

            Text(injector.statusMessage)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.85))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(cardBackground.opacity(0.85))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke((injector.isInjected ? Color.green : brandSakura).opacity(0.3), lineWidth: 0.8)
        )
    }

    // MARK: - 5. Khung Nút Bấm INJECTOR 1-Chạm
    private var actionButtonsSection: some View {
        VStack(spacing: 11) {
            // Nút INJECTOR Chính (1-Chạm)
            Button {
                CheatStoreSoundManager.shared.playTabSwitchHaptic()
                injector.performInject { result in
                    switch result {
                    case .success(let msg):
                        self.alertMessage = msg
                        self.showAlert = true
                    case .failure(let err):
                        self.alertMessage = "Lỗi nạp: \(err.localizedDescription)"
                        self.showAlert = true
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: injector.isInjected
                                    ? [Color(red: 0.15, green: 0.75, blue: 0.35), Color(red: 0.10, green: 0.55, blue: 0.25)]
                                    : [brandSakura, brandSakuraDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: (injector.isInjected ? Color.green : brandSakura).opacity(0.6),
                            radius: 10,
                            x: 0,
                            y: 2
                        )

                    HStack(spacing: 8) {
                        if injector.isWorking {
                            ProgressView()
                                .tint(.white)
                            Text("ĐANG NẠP DỮ LIỆU...")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: injector.isInjected ? "arrow.clockwise.circle.fill" : "bolt.shield.fill")
                                .font(.system(size: 17, weight: .black))
                                .foregroundColor(.white)

                            Text(injector.isInjected ? "CẬP NHẬT LẠI INJECTOR" : "⚡ KÍCH HOẠT INJECTOR (1-CHẠM)")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .tracking(0.5)
                        }
                    }
                    .padding(.vertical, 14)
                }
            }
            .buttonStyle(.plain)
            .disabled(injector.isWorking)

            // Hàng Nút Phụ: Mở Game & Khôi Phục Sạch
            HStack(spacing: 10) {
                // Nút Mở Game Trực Tiếp
                Button {
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                    injector.launchGame()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 13))
                        Text("Vào Game Ngay")
                            .font(.system(size: 12.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10.5)
                    .background(Color.white.opacity(0.10))
                    .cornerRadius(11)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)

                // Nút Khôi Phục Sạch
                Button {
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                    self.showCleanConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("Khôi Phục Gốc")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.50))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10.5)
                    .background(Color(red: 1.0, green: 0.35, blue: 0.40).opacity(0.12))
                    .cornerRadius(11)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color(red: 1.0, green: 0.35, blue: 0.40).opacity(0.3), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .disabled(injector.isWorking)
            }
        }
    }

    // MARK: - 6. Footer Tối Giản
    private var minimalFooterView: some View {
        HStack(spacing: 6) {
            Text("VeLix VN • Apple IPA V2 Engine")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray.opacity(0.8))

            Text("•")
                .foregroundColor(.gray.opacity(0.5))

            Text("iOS \(AppInfo.osVersion)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(brandSakura.opacity(0.9))
        }
    }
}

// MARK: - Feature Toggle Row Component
private struct FeatureToggleRow: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    @Binding var isOn: Bool
    let brandSakura: Color

    var body: some View {
        HStack(spacing: 12) {
            // Icon tròn với vầng sáng màu
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.16))
                    .frame(width: 38, height: 38)

                Image(systemName: iconName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(iconColor)
            }

            // Tên & mô tả
            VStack(alignment: .leading, spacing: 2.5) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 10.8))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Công tắc Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconColor)
                .scaleEffect(0.85)
                .onChange(of: isOn) { _ in
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10.5)
        .background(Color(red: 0.082, green: 0.043, blue: 0.137).opacity(0.92))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOn ? iconColor.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.18), value: isOn)
    }
}
