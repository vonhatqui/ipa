import SwiftUI
import UIKit

struct GameSelectionView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared

    let onSelectFreeFire: () -> Void

    @State private var isLoading = false
    @State private var loadingStep = "Khởi tạo nhân 3105 Kernel Bypass..."
    @State private var loadProgress: Double = 0.0
    @State private var ringRotation1: Double = 0
    @State private var ringRotation2: Double = 360
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4

    // Theme: Blossom Dark Sakura (blossom.re)
    private let brandBlue = BlossomTheme.sakura
    private let brandCyan = BlossomTheme.sakuraLight
    private let darkBackground = BlossomTheme.bgBottom
    private let cardBackground = Color(red: 0.082, green: 0.043, blue: 0.137)

    var body: some View {
        ZStack {
            // Nền hoa anh đào Blossom
            BlossomBackgroundView(showParticles: true)

            VStack(spacing: 0) {
                // Thanh Header trên cùng
                topHeaderView

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Tiêu đề mục: ỨNG DỤNG (1) theo đúng ảnh mẫu
                        HStack {
                            Text("ỨNG DỤNG (1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.75))
                                .tracking(1.0)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)

                        // Thẻ game Free Fire (com.dts.freefireth)
                        freeFireCardView
                            .padding(.horizontal, 20)

                        // Gợi ý sử dụng
                        instructionCardView
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 30)
                }

                Spacer(minLength: 0)

                // Footer thông tin thiết bị & phiên bản iOS
                deviceStatusFooterView
            }

            // Màn hình loading cyberpunk cao cấp khi bắt đầu nạp file
            if isLoading {
                loadingOverlayView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
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

            // Nút đăng xuất nếu muốn đổi key
            Button {
                licenseManager.deactivate()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.red.opacity(0.85))
                    .padding(8)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(darkBackground.opacity(0.85))
    }

    // MARK: - Thẻ Game Free Fire (Khớp 100% ảnh mẫu)
    private var freeFireCardView: some View {
        Button {
            startGameLoading()
        } label: {
            HStack(spacing: 11) {
                // Icon Free Fire
                FreeFireAppIconView(size: 42, cornerRadius: 11)

                // Thông tin Game
                VStack(alignment: .leading, spacing: 2.5) {
                    Text("Free Fire")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("com.dts.freefireth")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer()

                // Nút / Huy hiệu READY
                HStack(spacing: 6) {
                    Text("READY")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(brandCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(brandCyan.opacity(0.10))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(brandCyan, lineWidth: 1.1)
                        )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(cardBackground)
            .cornerRadius(13)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(brandBlue.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Gợi ý hướng dẫn
    private var instructionCardView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(brandBlue)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Hướng dẫn khởi động:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Text("Chạm vào game Free Fire để hệ thống tự động giải mã và nạp danh sách file mod bản quyền. Sau đó bạn có thể bật/tắt chức năng tuỳ ý.")
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
                .stroke(brandBlue.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Biểu tượng động của từng bước
    private var currentStepIcon: String {
        if loadProgress < 0.25 {
            return "cpu.fill"
        } else if loadProgress < 0.55 {
            return "lock.shield.fill"
        } else if loadProgress < 0.85 {
            return "scope"
        } else if loadProgress < 1.0 {
            return "bolt.shield.fill"
        } else {
            return "checkmark.seal.fill"
        }
    }

    // MARK: - Loading Overlay Nâng Cấp Hologram Cyberpunk
    private var loadingOverlayView: some View {
        ZStack {
            // Nền đen mờ AMOLED sâu
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Vầng hào quang neon tỏa trung tâm
            RadialGradient(
                colors: [brandCyan.opacity(0.22), brandBlue.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 10,
                endRadius: 240
            )
            .ignoresSafeArea()

            // Thẻ HUD Loading Hologram
            VStack(spacing: 24) {
                // Vòng xoay Radar Hologram Đa Tầng & Icon Free Fire
                ZStack {
                    // Sóng xung kích Radar thở (Pulse Glow)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [brandCyan.opacity(0.35), brandBlue.opacity(0.10), Color.clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 75
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .opacity(glowOpacity)

                    // Vòng ngoài 1: Xoay thuận kim đồng hồ với góc quét neon
                    Circle()
                        .trim(from: 0.08, to: 0.85)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    brandCyan,
                                    brandBlue,
                                    Color(red: 0.45, green: 0.20, blue: 1.00),
                                    brandCyan
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 106, height: 106)
                        .rotationEffect(.degrees(ringRotation1))

                    // Vòng giữa 2: Xoay ngược kim đồng hồ nét đứt Cyberpunk
                    Circle()
                        .stroke(
                            brandBlue.opacity(0.40),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 8])
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(ringRotation2))

                    // Điểm sáng vệ tinh xoay quanh quỹ đạo
                    Circle()
                        .fill(brandCyan)
                        .frame(width: 6, height: 6)
                        .shadow(color: brandCyan, radius: 4)
                        .offset(x: 53)
                        .rotationEffect(.degrees(ringRotation1))

                    // Icon Free Fire ở tâm với viền phát sáng
                    ZStack {
                        FreeFireAppIconView(size: 54, cornerRadius: 14)
                            .shadow(color: brandBlue.opacity(0.7), radius: 12)

                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [brandCyan, brandBlue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 54, height: 54)
                    }
                }
                .frame(height: 115)

                // Nội dung HUD & Thanh Tiến Trình
                VStack(spacing: 14) {
                    VStack(spacing: 4) {
                        Text("ĐANG NẠP DỮ LIỆU FREE FIRE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(1.4)

                        // Số phần trăm hiển thị phong cách HUD điện tử
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(loadProgress * 100))")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, brandCyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(brandCyan)
                        }
                    }

                    // Thanh tiến trình Neon Cyberpunk
                    GeometryReader { geo in
                        let barWidth = geo.size.width
                        ZStack(alignment: .leading) {
                            // Rãnh thanh tối
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)

                            // Lớp fill phát sáng neon
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [brandBlue, brandCyan, Color.white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, barWidth * CGFloat(loadProgress)), height: 8)
                                .shadow(color: brandCyan.opacity(0.85), radius: 6, x: 0, y: 0)

                            // Đầu dẫn sáng (Glow Tip)
                            if loadProgress > 0.05 && loadProgress < 0.99 {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: brandCyan, radius: 5)
                                    .offset(x: barWidth * CGFloat(loadProgress) - 5)
                            }
                        }
                    }
                    .frame(height: 8)
                    .frame(width: 230)

                    // Huy hiệu hiển thị trạng thái động với icon
                    HStack(spacing: 7) {
                        Image(systemName: currentStepIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(brandCyan)

                        Text(loadingStep)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(brandCyan.opacity(0.25), lineWidth: 0.8)
                    )
                    .animation(.easeInOut(duration: 0.25), value: loadingStep)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.07, green: 0.11, blue: 0.20),
                                Color(red: 0.04, green: 0.06, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [brandCyan.opacity(0.65), brandBlue.opacity(0.25), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: brandBlue.opacity(0.35), radius: 32, x: 0, y: 12)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Bắt đầu quá trình nạp file đa tầng Cyberpunk
    private func startGameLoading() {
        // Haptic phản hồi khi ấn
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        loadProgress = 0.0
        loadingStep = "Khởi tạo nhân 3105 Kernel Bypass..."
        ringRotation1 = 0
        ringRotation2 = 360
        pulseScale = 1.0
        glowOpacity = 0.4

        withAnimation(.easeInOut(duration: 0.25)) {
            isLoading = true
        }

        // Bắt đầu vòng quay liên tục
        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
            ringRotation1 = 360
        }
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            ringRotation2 = 0
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
            glowOpacity = 0.80
        }

        // Thực thi nạp file ngầm
        BundledPatchInjector.autoImportBundledPatches(into: patchStore)

        // Giai đoạn 1: 0% -> 28%
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.35)) {
                self.loadProgress = 0.28
            }
        }

        // Giai đoạn 2: 28% -> 58%
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.loadingStep = "Bảo mật chứng chỉ & giải mã sandbox..."
            withAnimation(.easeOut(duration: 0.40)) {
                self.loadProgress = 0.58
            }
        }

        // Giai đoạn 3: 58% -> 88%
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.00) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.loadingStep = "Nạp module Định Vị 50m Chống Văng & AimNeck..."
            withAnimation(.easeOut(duration: 0.35)) {
                self.loadProgress = 0.88
            }
        }

        // Giai đoạn 4: 88% -> 100%
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.40) {
            self.loadingStep = "Đồng bộ Free Fire an toàn • Sẵn sàng!"
            withAnimation(.easeOut(duration: 0.25)) {
                self.loadProgress = 1.0
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        // Hoàn tất và chuyển sang Dashboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.80) {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.isLoading = false
                self.onSelectFreeFire()
            }
        }
    }

    // MARK: - Footer thông tin thiết bị
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
                .stroke(brandBlue.opacity(0.2), lineWidth: 0.8)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}

// MARK: - FreeFireAppIconView (Load từ Asset hoặc File png)
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
        if let img = UIImage(named: "FreeFireIcon") {
            return img
        }
        if let img = UIImage(named: "freefire") {
            return img
        }
        if let path = Bundle.main.path(forResource: "FreeFireIcon", ofType: "png"),
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
