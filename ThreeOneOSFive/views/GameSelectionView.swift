import SwiftUI
import UIKit

struct GameSelectionView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared

    let onSelectFreeFire: () -> Void

    @AppStorage("cheatstore_selected_game_version") private var selectedGameVersionRaw: String = FreeFireGameVersion.standard.rawValue
    @State private var isLaunchingGame: Bool = false
    @State private var launchingVersionTitle: String = ""

    private var currentGameVersion: FreeFireGameVersion {
        FreeFireGameVersion(rawValue: selectedGameVersionRaw) ?? .standard
    }

    // Design Tokens (Obsidian Luxury • Black & White LED Glow)
    private let colorVoid = Color.black
    private let colorInk = Color(red: 244/255, green: 241/255, blue: 234/255)
    private let colorMute = Color(red: 160/255, green: 160/255, blue: 165/255)
    private let glassBg = Color.white.opacity(0.04)
    private let glassBorder = Color.white.opacity(0.12)
    private let greenBadge = Color(red: 0.20, green: 0.88, blue: 0.45)

    var body: some View {
        ZStack {
            // Nền đen sâu True Black Void
            colorVoid.ignoresSafeArea()

            // Vầng sáng Ambient Glow Trắng LED Luxury (Black & White Theme)
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.08), Color.clear]),
                center: .top,
                startRadius: 20,
                endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header thanh trên
                topHeaderView

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Tiêu đề mục
                        HStack {
                            Text("PHIÊN BẢN GAME")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(2.4)
                                .foregroundColor(Color.white.opacity(0.75))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Duy nhất 1 game Free Fire theo yêu cầu
                        gameCardView(version: .standard)
                            .padding(.horizontal, 20)

                        // Thông tin bảo mật Antiban
                        instructionCardView
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                    }
                    .padding(.bottom, 24)
                }

                Spacer(minLength: 0)

                // Footer thông tin thiết bị & phiên bản iOS
                deviceStatusFooterView
            }

            // Loading overlay khi chọn game
            if isLaunchingGame {
                ZStack {
                    Color.black.opacity(0.75).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Đang nạp dữ liệu \(launchingVersionTitle)...")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color(red: 22/255, green: 22/255, blue: 26/255))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(glassBorder, lineWidth: 1))
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Top Header
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            CheatStoreLogoView(size: 38, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(licenseManager.featureConfig.app_name.isEmpty ? "Venom VN" : licenseManager.featureConfig.app_name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(colorInk)

                HStack(spacing: 4) {
                    Circle()
                        .fill(greenBadge)
                        .frame(width: 6, height: 6)
                    Text("VIP ĐÃ KÍCH HOẠT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(greenBadge)
                }
            }

            Spacer()

            // Nút đăng xuất
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                licenseManager.deactivate()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("Đổi Key")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.25), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.4))
    }

    // MARK: - Thẻ Game Card
    private func gameCardView(version: FreeFireGameVersion) -> some View {
        let isSelected = (currentGameVersion == version)
        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedGameVersionRaw = version.rawValue
            DevicePatchService.preferredVersion = version
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)

            launchingVersionTitle = version.fullTitle
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
                FreeFireAppIconView(size: 46, cornerRadius: 12)

                // Thông tin Game
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(version.fullTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(colorInk)

                        if isSelected {
                            Text("MẶC ĐỊNH")
                                .font(.system(size: 8.5, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .cornerRadius(4)
                        }
                    }

                    Text(version.primaryBundleID)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(colorMute)
                }

                Spacer()

                // Nút / Huy hiệu SẴN SÀNG
                HStack(spacing: 6) {
                    Text("SẴN SÀNG")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colorMute.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(glassBg)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.white.opacity(0.6) : glassBorder, lineWidth: 1.2)
            )
            .shadow(color: isSelected ? Color.white.opacity(0.20) : Color.black.opacity(0.3), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Gợi ý hướng dẫn / Bảo vệ
    private var instructionCardView: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Bảo Vệ Antiban Active")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(colorInk)

                Text("Chạm vào game Free Fire để hệ thống tự động nạp cấu hình và mở bảng điều khiển mod. Toàn bộ file gốc sẽ được hoàn trả an toàn khi thoát.")
                    .font(.system(size: 11.5))
                    .foregroundColor(colorMute)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(glassBorder, lineWidth: 1)
        )
    }

    // MARK: - Footer thông tin thiết bị
    private var deviceStatusFooterView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(colorInk.opacity(0.85))
                Text(AppInfo.hardwareDisplayName)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(colorInk)
            }

            Text("•")
                .foregroundColor(colorMute.opacity(0.5))

            Text("iOS \(UIDevice.current.systemVersion)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(colorMute)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                    .frame(width: 7, height: 7)
                    .shadow(color: Color.green.opacity(0.8), radius: 3)
                Text("ĐƯỢC HỖ TRỢ")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Color.green.opacity(0.12))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.28), lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(Color.black.opacity(0.4))
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
