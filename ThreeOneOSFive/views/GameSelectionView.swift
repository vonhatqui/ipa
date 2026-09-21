import SwiftUI
import UIKit

struct GameSelectionView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared

    let onSelectFreeFire: () -> Void

    @State private var isLoading = false
    @State private var loadProgress: Double = 0.0
    @State private var currentStepIndex: Int = 0
    @State private var stepCardOpacity: Double = 1.0
    @State private var stepCardOffsetY: CGFloat = 0.0
    @State private var isFinalReady: Bool = false

    private let loadingSteps: [String] = [
        "Loading Free Fire",
        "Bypass Anti-cheat",
        "Inject 3105 Kernel Driver",
        "Sync AimAssist & Memory ESP",
        "All Systems Ready • Launching..."
    ]

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

    private var currentStepTitle: String {
        if currentStepIndex < loadingSteps.count {
            return loadingSteps[currentStepIndex]
        }
        return loadingSteps.last ?? "All Systems Ready • Launching..."
    }

    // MARK: - Loading Overlay Blossom Mẫu 1 (Hiện từng câu kèm icon xanh, xong biến mất)
    private var loadingOverlayView: some View {
        ZStack {
            // Nền tối sẫm Blossom AMOLED
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            BlossomTheme.bgBottom
                .opacity(0.85)
                .ignoresSafeArea()

            BlossomTheme.backgroundGradient
                .opacity(0.75)
                .ignoresSafeArea()

            // Hạt cánh hoa anh đào rơi nhẹ
            BlossomPetalParticlesView()
                .opacity(0.35)
                .ignoresSafeArea()

            // Viền sáng neon bao quanh mép màn hình (Screen Inset Glow)
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            BlossomTheme.sakura.opacity(0.65),
                            BlossomTheme.sakuraDeep.opacity(0.25),
                            Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP: Icon Free Fire & Thương hiệu
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(BlossomTheme.sakura.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)

                        FreeFireAppIconView(size: 72, cornerRadius: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [BlossomTheme.sakuraLight, BlossomTheme.sakura.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: BlossomTheme.sakura.opacity(0.5), radius: 18)
                    }

                    VStack(spacing: 3) {
                        Text("CHEATSTORE VN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(5)
                            .foregroundStyle(Color.white.opacity(0.45))

                        Text("FREE FIRE OS")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, BlossomTheme.sakuraLight, BlossomTheme.sakura],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .padding(.top, 40)

                Spacer()

                // CENTER SPOTLIGHT: Thanh ngang nằm ngang đúng dáng thanh ngang như ban đầu
                HStack(spacing: 12) {
                    // Dấu tích xanh neon
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.3))
                            .frame(width: 32, height: 32)
                            .blur(radius: 6)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                            .shadow(color: Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.9), radius: 8)
                    }

                    // Dòng chữ chính to rõ
                    Text(currentStepTitle)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer()

                    // Badge OK / READY
                    Text(isFinalReady ? "READY" : "OK")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.35), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.04, blue: 0.14).opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isFinalReady
                                ? LinearGradient(colors: [Color(red: 0.20, green: 0.88, blue: 0.45), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [BlossomTheme.sakura.opacity(0.45), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: isFinalReady ? Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.3) : BlossomTheme.sakura.opacity(0.25), radius: 20)
                .padding(.horizontal, 22)
                .opacity(stepCardOpacity)
                .offset(y: stepCardOffsetY)

                Spacer()

                // BOTTOM: Tiến trình % & Nút vào ngay
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                                .frame(width: 7, height: 7)
                            Text(isFinalReady ? "BẢO MẬT HOÀN TẤT" : "ĐANG XÁC THỰC...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        Spacer()
                        Text("\(Int(loadProgress * 100))%")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.20, green: 0.88, blue: 0.45))
                    }
                    .padding(.horizontal, 4)

                    // Thanh tiến trình
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [BlossomTheme.sakura, Color(red: 0.20, green: 0.88, blue: 0.45)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * CGFloat(loadProgress)), height: 8)
                                .shadow(color: Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.85), radius: 6)
                        }
                    }
                    .frame(height: 8)

                    Button {
                        finishImmediately()
                    } label: {
                        Text("Chạm để vào game ngay")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 36)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            finishImmediately()
        }
    }

    // MARK: - Bắt đầu quá trình nạp file Mẫu 1 (Hiện từng câu rồi biến mất)
    private func startGameLoading() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        loadProgress = 0.0
        currentStepIndex = 0
        isFinalReady = false
        stepCardOpacity = 1.0
        stepCardOffsetY = 0.0

        withAnimation(.easeInOut(duration: 0.25)) {
            isLoading = true
        }

        // Thực thi nạp file ngầm
        BundledPatchInjector.autoImportBundledPatches(into: patchStore)

        // Bắt đầu chuỗi bước
        animateStep(index: 0)
    }

    private func animateStep(index: Int) {
        guard isLoading else { return }

        if index >= loadingSteps.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isFinalReady = true
                loadProgress = 1.0
                stepCardOpacity = 1.0
                stepCardOffsetY = 0
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                finishImmediately()
            }
            return
        }

        currentStepIndex = index
        let targetProgress = Double(index + 1) / Double(loadingSteps.count)

        // 1. Enter: Trượt vào mượt mà
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            stepCardOpacity = 1.0
            stepCardOffsetY = 0
            loadProgress = targetProgress
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // 2. Dừng hiển thị ~0.65s, sau đó bay lên biến mất để nhường cho câu tiếp theo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard isLoading else { return }
            if index < loadingSteps.count - 1 {
                withAnimation(.easeIn(duration: 0.32)) {
                    stepCardOpacity = 0.0
                    stepCardOffsetY = -26
                }
                // Chuyển sang bước tiếp theo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    animateStep(index: index + 1)
                }
            } else {
                animateStep(index: index + 1)
            }
        }
    }

    private func finishImmediately() {
        guard isLoading else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
            onSelectFreeFire()
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
