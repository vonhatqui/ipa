import SwiftUI
import UIKit

/// GameSelectionView: Màn hình chọn ứng dụng phong cách Delta Proxy (Đồng bộ chuẩn 100% với clip TikTok)
/// Logic ghép đôi:
/// - iOS được hỗ trợ trực tiếp (iOS 26.1, 17.0–17.7, 18.0–18.7.1, 27 Beta 1–4):
///   -> Hiển thị ỨNG DỤNG (2) gồm Free Fire Max & Free Fire ngay lập tức sau khi nhập key, KHÔNG hiện ghép đôi!
/// - iOS cao chưa hỗ trợ exploit (iOS 18.7.2+, iOS 27 chính thức, iOS 28+):
///   -> Hiển thị ỨNG DỤNG (0), ẩn Free Fire cho đến khi ghép đôi thành công qua Cài đặt ⚙️ > Ghép Đôi iOS 27.
struct GameSelectionView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    @ObservedObject var bridge = AirliftBridge.shared

    let onSelectFreeFire: () -> Void

    @AppStorage("cheatstore_selected_game_version") private var selectedGameVersionRaw: String = FreeFireGameVersion.standard.rawValue
    @State private var isLaunchingGame: Bool = false
    @State private var launchingVersionTitle: String = ""
    @State private var showSettings: Bool = false

    private var currentGameVersion: FreeFireGameVersion {
        FreeFireGameVersion(rawValue: selectedGameVersionRaw) ?? .standard
    }

    private var theme: AppBrandingTheme {
        AppBrandingTheme.current
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.4"
    }

    // Kiểm tra xem game có sẵn sàng hiển thị không (Bỏ ghép đôi - luôn hiển thị sẵn sàng)
    private var isGameAvailable: Bool {
        return true
    }

    // Design Tokens (Đồng bộ chuẩn Theme CheatStore / Obsidian Dark Luxury)
    private var colorVoid: Color { theme.colorVoid }
    private var colorCardBg: Color { theme.colorPanel }
    private var colorCardBorder: Color { theme.glassBorder }
    private var colorInk: Color { theme.colorInk }
    private var colorMute: Color { theme.colorMute }
    private let greenBadge = Color(red: 0.0, green: 0.90, blue: 0.46) // Neon Green • Có Hỗ Trợ
    private var accentBadgeColor: Color {
        theme == .cheatStore ? Color(red: 0.0, green: 0.90, blue: 0.46) : theme.accentColor
    }

    var body: some View {
        ZStack {
            // Nền chảy Snapchat Liquid Mesh Gradient lượn sóng huyền ảo
            SnapchatFluidLiquidBackgroundView()

            VStack(spacing: 0) {
                // 1. Header thanh trên (Logo + Tên App + Nút Cài đặt ⚙️)
                topHeaderView

                // 2. Bộ 3 thẻ trạng thái hệ thống (Thiết bị • Hệ điều hành • Tương thích)
                systemStatsRowView

                // 3. Danh sách ứng dụng (Luôn hiển thị 2 bản Free Fire)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Tiêu đề mục: ỨNG DỤNG (2)
                        HStack {
                            Text("ỨNG DỤNG (2)")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .tracking(1.8)
                                .foregroundColor(Color.white.opacity(0.65))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        // Cả 2 bản Free Fire Max & Free Fire Thường đều sẵn sàng
                        gameCardView(
                            title: "Free Fire Max",
                            bundleId: "com.dts.freefiremax",
                            version: .max
                        )
                        .padding(.horizontal, 16)

                        gameCardView(
                            title: "Free Fire",
                            bundleId: "com.dts.freefireth",
                            version: .standard
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 20)
                }

                Spacer(minLength: 0)

                // 4. Thanh Ticker Marquee ("... Mãi Đỉnh, Em Yêu ... <3")
                marqueeBannerView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // 5. Thanh Key Info Bar dưới cùng
                keyStatusBarView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            // Loading overlay khi nạp game
            if isLaunchingGame {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Đang nạp dữ liệu \(launchingVersionTitle)...")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(26)
                    .background(Color(red: 22/255, green: 22/255, blue: 28/255))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(colorCardBorder, lineWidth: 1))
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSettings) {
            DeltaStyleSettingsView()
        }
        .onAppear {
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)
        }
    }

    // MARK: - Top Header
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            CheatStoreLogoView(size: 34, cornerRadius: 9)

            HStack(spacing: 6) {
                ShinyTextView(
                    text: theme.appTitle,
                    font: .system(size: 16, weight: .heavy, design: .rounded),
                    baseColor: colorInk,
                    shineColor: theme.accentColor,
                    duration: 2.4,
                    tracking: 0.2
                )

                Text("v\(appVersion)")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }

            Spacer()

            // Nút Cài đặt (Gear shape) mở Modal 7 mục chuẩn Delta
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - Thanh thông số hệ thống liền khối cao cấp (Thiết bị • Hệ điều hành • Tương thích)
    private var systemStatsRowView: some View {
        HStack(spacing: 0) {
            statItem(
                title: "THIẾT BỊ",
                value: AppInfo.hardwareDisplayName,
                valueColor: colorInk
            )

            Divider()
                .frame(width: 1, height: 26)
                .background(Color.white.opacity(0.12))

            statItem(
                title: "HỆ ĐIỀU HÀNH",
                value: "iOS \(UIDevice.current.systemVersion)",
                valueColor: colorInk
            )

            Divider()
                .frame(width: 1, height: 26)
                .background(Color.white.opacity(0.12))

            statItem(
                title: "TƯƠNG THÍCH",
                value: "• Sẵn Sàng",
                valueColor: greenBadge
            )
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorCardBg.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorCardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func statItem(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundColor(Color.white.opacity(0.55))

            Text(value)
                .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Game Card View (Free Fire Max / Free Fire - Đồng bộ màu App)
    private func gameCardView(title: String, bundleId: String, version: FreeFireGameVersion) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedGameVersionRaw = version.rawValue
            DevicePatchService.preferredVersion = version
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)

            launchingVersionTitle = title
            withAnimation(.easeInOut(duration: 0.2)) {
                isLaunchingGame = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isLaunchingGame = false
                onSelectFreeFire()
            }
        } label: {
            HStack(spacing: 14) {
                // Icon Free Fire
                FreeFireAppIconView(size: 52, cornerRadius: 13)

                // Tên & Bundle ID
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(colorInk)

                    Text(bundleId)
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .foregroundColor(colorMute)
                }

                Spacer()

                // Huy hiệu READY chuẩn phong cách App
                Text("READY")
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundColor(accentBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accentBadgeColor.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentBadgeColor.opacity(0.40), lineWidth: 1)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorCardBg.opacity(0.96),
                                Color(red: 14/255, green: 14/255, blue: 20/255).opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 12, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Banner Marquee Ticker
    private var marqueeBannerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 12))
                .foregroundColor(accentBadgeColor)

            Text("\(theme.appTitle) Mãi Đỉnh, Em Yêu \(theme.appTitle) <3")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(colorInk.opacity(0.85))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Key Status Bar
    private var keyStatusBarView: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(greenBadge)
                .frame(width: 8, height: 8)
                .shadow(color: greenBadge.opacity(0.8), radius: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text("KEY: \(maskedKey)")
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text(licenseManager.formattedRemainingTime.isEmpty ? "Còn 30 ngày 0 giờ" : licenseManager.formattedRemainingTime)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(greenBadge)
            }

            Spacer()

            Image(systemName: "shield.fill")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))

            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                licenseManager.deactivate()
            } label: {
                Text("Đổi Key")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.12, green: 0.13, blue: 0.18).opacity(0.95))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(colorCardBorder, lineWidth: 1))
    }

    private var maskedKey: String {
        let k = licenseManager.activeKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard k.count >= 8 else {
            return k.isEmpty ? "VIP••••2026" : k
        }
        let prefix = String(k.prefix(4))
        let suffix = String(k.suffix(4))
        return "\(prefix)••••\(suffix)"
    }
}

// MARK: - FreeFireAppIconView
struct FreeFireAppIconView: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let img = loadIconImage() {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "flame.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func loadIconImage() -> UIImage? {
        if let img = UIImage(named: "FreeFireIcon") ?? UIImage(named: "freefire") {
            return img
        }
        if let path = Bundle.main.path(forResource: "FreeFireIcon", ofType: "png") ??
                      Bundle.main.path(forResource: "FreeFireIcon", ofType: "jpg"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        return nil
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
