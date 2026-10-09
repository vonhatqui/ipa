import SwiftUI
import UIKit
import WebKit
import ImageIO

struct CheatStoreLoginView: View {
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @State private var inputKey: String = ""
    @State private var isSecured: Bool = true
    @State private var inlineErrorMessage: String? = nil
    @State private var showLoginSuccessSplash: Bool = false
    @State private var showCopiedDeviceID: Bool = false

    init(licenseManager: CheatStoreLicenseManager = .shared) {
        self.licenseManager = licenseManager
    }

    var body: some View {
        ZStack {
            // Nền đen tuyệt đối True Dark AMOLED
            Color.black
                .ignoresSafeArea()

            // Panel Đăng Nhập Chuẩn 100% Full Đen (.auth-panel)
            VStack(spacing: 0) {
                Spacer()

                authCardContent
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 24)

                Spacer()

                deviceIDFooter
            }

            // HIỆU ỨNG INTRO ĐĂNG NHẬP THÀNH CÔNG (0XCHEATS VERIFIED)
            if showLoginSuccessSplash {
                LoginSuccessIntroView(
                    planName: licenseManager.planName,
                    remainingTime: licenseManager.formattedRemainingTime,
                    deviceID: licenseManager.deviceID,
                    onFinished: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showLoginSuccessSplash = false
                            licenseManager.confirmActivation()
                        }
                    }
                )
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .onAppear {
            if inputKey.isEmpty && !licenseManager.activeKey.isEmpty {
                inputKey = licenseManager.activeKey
            }
        }
    }

    // MARK: - Auth Card Subviews

    private var authCardContent: some View {
        VStack(spacing: 0) {
            // GIF Banner từ https://files.catbox.moe/qhq1ot.gif
            LoginGifBannerView()
                .frame(width: 250, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.7), radius: 14, y: 6)
                .padding(.bottom, 20)

            brandHeaderSection
            titlesSection
            inputFieldSection
            rememberRowSection
            launchButtonSection
            statusMessageSection
        }
    }

    // 1. .auth-brand: Logo + ShinyText Brand Name
    private var brandHeaderSection: some View {
        HStack(spacing: 12) {
            CheatStoreLogoView(size: 44, cornerRadius: 12)

            ShinyTextView(
                text: AppBrandingTheme.current.appTitle,
                font: .system(size: 21, weight: .bold, design: .rounded),
                baseColor: Color(red: 0.78, green: 0.78, blue: 0.82),
                shineColor: .white,
                duration: 2.5,
                tracking: 0.5
            )
        }
        .padding(.bottom, 24)
    }

    // 2. .auth-title: Sign In & 3. .auth-sub: iOS • External
    private var titlesSection: some View {
        VStack(spacing: 6) {
            Text("Sign In")
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundStyle(Color(red: 0.96, green: 0.95, blue: 0.92))

            Text(licenseManager.featureConfig.app_subtitle.isEmpty ? "iOS • External" : licenseManager.featureConfig.app_subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.55, green: 0.53, blue: 0.50))
        }
        .padding(.bottom, 28)
    }

    // 4. .glass-input-wrap (.glass-input)
    private var inputFieldSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.65))
                .padding(.leading, 16)

            if isSecured {
                SecureField("License key", text: $inputKey)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color(red: 0.96, green: 0.95, blue: 0.92))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .frame(height: 48)
            } else {
                TextField("License key", text: $inputKey)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color(red: 0.96, green: 0.95, blue: 0.92))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .frame(height: 48)
            }

            Button {
                isSecured.toggle()
            } label: {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.65))
                    .padding(.trailing, 16)
            }
        }
        .frame(height: 52)
        .background(
            Capsule()
                .fill(Color(red: 16/255, green: 16/255, blue: 20/255))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 16, y: 8)
        .padding(.bottom, 12)
    }

    // 5. .auth-row: Remember (Trái) & Paste key (Phải)
    private var rememberRowSection: some View {
        HStack {
            Button {
                licenseManager.rememberKey.toggle()
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(licenseManager.rememberKey ? Color(red: 0.0, green: 0.82, blue: 1.0) : Color(red: 22/255, green: 22/255, blue: 26/255))
                            .frame(width: 16, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(licenseManager.rememberKey ? Color(red: 0.0, green: 0.82, blue: 1.0) : Color.white.opacity(0.25), lineWidth: 1)
                            )

                        if licenseManager.rememberKey {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Text("Remember")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                if let text = UIPasteboard.general.string {
                    inputKey = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Text("Paste key")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 22)
    }

    // 6. .rainbow-btn: Launch Button (Full Black Luxury Glowing AMOLED)
    private var launchButtonSection: some View {
        Button {
            executeLaunch()
        } label: {
            HStack(spacing: 8) {
                if licenseManager.isVerifying {
                    ProgressView()
                        .tint(.white)
                    Text("Verifying...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    ShinyTextView(
                        text: "Launch",
                        font: .system(size: 16, weight: .bold),
                        baseColor: .white,
                        shineColor: Color(red: 0.8, green: 0.8, blue: 0.9),
                        duration: 2.2,
                        tracking: 0.4
                    )

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 18/255, green: 18/255, blue: 24/255))
            )
            .shadow(color: Color.black.opacity(0.5), radius: 12, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
            )
        }
        .disabled(licenseManager.isVerifying || inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((licenseManager.isVerifying || inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
    }

    // 7. .auth-status: Trạng thái & thông báo lỗi
    private var statusMessageSection: some View {
        Group {
            if let err = inlineErrorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(err)
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.35))
                .padding(.top, 14)
                .transition(.opacity)
            } else {
                Text("Enter your license key to continue")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .padding(.top, 14)
            }
        }
    }

    // Footer: Device ID
    private var deviceIDFooter: some View {
        Button {
            UIPasteboard.general.string = licenseManager.deviceID
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showCopiedDeviceID = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedDeviceID = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showCopiedDeviceID ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                Text(showCopiedDeviceID ? "Device ID Copied" : "Device ID: \(String(licenseManager.deviceID.prefix(14)))...")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(Color.white.opacity(0.45))
            .padding(.bottom, 24)
        }
        .buttonStyle(.plain)
    }

    private func executeLaunch() {
        inlineErrorMessage = nil
        Task {
            let success = await licenseManager.activateKey(inputKey)
            await MainActor.run {
                if success {
                    CheatStoreSoundManager.shared.playSuccessSound()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLoginSuccessSplash = true
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    let msg = licenseManager.errorMessage ?? "Invalid license key"
                    withAnimation(.easeOut(duration: 0.25)) {
                        inlineErrorMessage = msg
                    }
                }
            }
        }
    }
}


struct CheatStoreLogoView: View {
    var size: CGFloat = 84
    var cornerRadius: CGFloat = 22

    private var loadedImage: UIImage? {
        let theme = AppBrandingTheme.current
        if let resPath = Bundle.main.resourcePath {
            let appCoreAssets = (resPath as NSString).appendingPathComponent("AppCore/Assets")

            // Nếu là bản clone (VeLix hoặc Venom), ưu tiên các file icon/logo được cloner thay thế
            let candidates: [String]
            if theme != .cheatStore {
                candidates = [
                    "CustomLogo.png",
                    "BrandLogo.png",
                    "AppIcon60x60@3x.png",
                    "AppIcon60x60@2x.png",
                    "CheatStoreLogo.jpg",
                    "PhantomBrand.png",
                    "CheatLogo.png",
                    "CheatStoreLogo.png"
                ]
            } else {
                candidates = [
                    "PhantomBrand.png",
                    "CheatLogo.png",
                    "CheatStoreLogo.png",
                    "CheatStoreLogo.jpg",
                    "AppIcon60x60@3x.png",
                    "AppIcon60x60@2x.png"
                ]
            }

            // 1. Thử trong thư mục gốc app bundle trước (nơi Cloner thay icon chính xác nhất)
            for name in candidates {
                let p = (resPath as NSString).appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: p) { return img }
            }
            // 2. Thử trong thư mục AppCore/Assets
            for name in candidates {
                let p = (appCoreAssets as NSString).appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: p) { return img }
            }
        }
        if theme == .cheatStore {
            if let img = UIImage(named: "PhantomBrand") ?? UIImage(named: "CheatLogo") ?? UIImage(named: "CheatStoreLogo") {
                return img
            }
        }
        return nil
    }

    var body: some View {
        if let image = loadedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AppBrandingTheme.current.accentColor.opacity(0.4), lineWidth: 1.2)
                )
                .shadow(color: AppBrandingTheme.current.accentColor.opacity(0.25), radius: 8)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppBrandingTheme.current.accentColor.opacity(0.4), lineWidth: 1.2)
                    )

                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(AppBrandingTheme.current.accentColor)
            }
        }
    }
}

// MARK: - CÁC TRẠNG THÁI THÔNG BÁO NHẬP KEY
enum KeyNotificationType {
    case success(plan: String, remaining: String, expiry: String)
    case error(message: String)
}

// MARK: - MẪU 1: HIỆU ỨNG DẤU TÍCH APPLE PAY GLASS (iOS 18)
struct AppleCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = rect.minX + rect.width * 0.16
        let startY = rect.minY + rect.height * 0.52

        let midX = rect.minX + rect.width * 0.44
        let midY = rect.minY + rect.height * 0.82

        let endX = rect.minX + rect.width * 0.94
        let endY = rect.minY + rect.height * 0.22

        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: midX, y: midY))
        path.addLine(to: CGPoint(x: endX, y: endY))
        return path
    }
}

struct ApplePayCheckmarkView: View {
    @State private var circleProgress: CGFloat = 0.0
    @State private var checkProgress: CGFloat = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var checkScale: CGFloat = 0.75

    private let appleGreen = Color(red: 0.20, green: 0.88, blue: 0.45)

    var body: some View {
        ZStack {
            // Hào quang lan tỏa
            Circle()
                .fill(appleGreen.opacity(glowOpacity))
                .frame(width: 84, height: 84)
                .blur(radius: 16)

            // Vòng tròn track nền mờ
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 3.5)
                .frame(width: 80, height: 80)

            // Vòng tròn vẽ nét SVG động (0 -> 100%)
            Circle()
                .trim(from: 0.0, to: circleProgress)
                .stroke(
                    appleGreen,
                    style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            // Dấu checkmark thanh mảnh Apple Pay
            AppleCheckmarkShape()
                .trim(from: 0.0, to: checkProgress)
                .stroke(
                    appleGreen,
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 44, height: 44)
                .scaleEffect(checkScale)
        }
        .onAppear {
            // 1. Vẽ vòng tròn khép kín mượt mà
            withAnimation(.easeInOut(duration: 0.52)) {
                circleProgress = 1.0
            }
            // 2. Kích hoạt hào quang
            withAnimation(.easeOut(duration: 0.8).delay(0.35)) {
                glowOpacity = 0.35
            }
            // 3. Nét vẽ dấu tích bung nhịp Spring của Apple
            withAnimation(.spring(response: 0.38, dampingFraction: 0.65).delay(0.40)) {
                checkProgress = 1.0
                checkScale = 1.0
            }
            // Rung haptic Apple Pay
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - BIỂU TƯỢNG TẢI XUỐNG VỚI HIỆU ỨNG LÊN XUỐNG NHẸ NHÀNG
struct AnimatedDownloadIconView: View {
    @State private var isFloating = false
    private let whiteLed = Color.white
    private let cyan = Color.white.opacity(0.9)

    var body: some View {
        ZStack {
            // Glow nền tròn đa tầng
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 46
                    )
                )
                .frame(width: 88, height: 88)
                .blur(radius: 14)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 74, height: 74)

            Circle()
                .fill(Color(red: 0.08, green: 0.04, blue: 0.14))
                .frame(width: 66, height: 66)

            // Icon download với hiệu ứng nhấp nhô lên xuống nhẹ nhàng
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.65), radius: 8, y: 2)
                .offset(y: isFloating ? -5 : 5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}

// MARK: - MẪU 4: DARK MECH TITANIUM BẢO TRÌ HỆ THỐNG
struct RotatingMechGearsView: View {
    @State private var isSpinning = false
    private let violetNeon = Color(red: 0.65, green: 0.35, blue: 0.98)
    private let deepIndigo = Color(red: 0.35, green: 0.20, blue: 0.75)

    var body: some View {
        ZStack {
            // Glow aura ánh tím
            Circle()
                .fill(violetNeon.opacity(0.18))
                .frame(width: 96, height: 96)
                .blur(radius: 16)

            // Vòng tròn viền Titanium
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [violetNeon.opacity(0.8), deepIndigo.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 80, height: 80)

            // Bánh răng lớn xoay xuôi chiều kim đồng hồ
            Image(systemName: "gearshape.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [violetNeon, deepIndigo],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(isSpinning ? 360 : 0))

            // Bánh răng nhỏ bên trong xoay ngược chiều
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
                .rotationEffect(.degrees(isSpinning ? -360 : 0))

            // Biểu tượng mỏ lết / công cụ trung tâm
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(color: violetNeon, radius: 4)
        }
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
    }
}

struct DarkMechMaintenanceModalView: View {
    let info: AppMaintenanceInfo
    var onRefresh: (() -> Void)? = nil

    private let violetNeon = Color(red: 0.65, green: 0.35, blue: 0.98)
    private let deepIndigo = Color(red: 0.35, green: 0.20, blue: 0.75)

    var body: some View {
        ZStack {
            // Nền mờ tối chống bấm can thiệp
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Biểu tượng bánh răng cơ khí Titan chuyển động xoay
                RotatingMechGearsView()
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    // Badge CheatStoreVN (yêu cầu riêng của bạn)
                    HStack(spacing: 4) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 11, weight: .bold))
                        Text(info.badge.isEmpty ? "CheatStoreVN" : info.badge)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(violetNeon)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(violetNeon.opacity(0.18))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(violetNeon.opacity(0.4), lineWidth: 1)
                    )

                    // Tiêu đề
                    Text(info.title.isEmpty ? "Hệ Thống Đang Bảo Trì" : info.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    // Lời nhắn chi tiết (đã cập nhật theo yêu cầu)
                    Text(info.message.isEmpty ? "Đội ngũ kỹ thuật đang nâng cấp hệ thống để mang lại trải nghiệm tốt nhất." : info.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(red: 0.88, green: 0.88, blue: 0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 12)
                }

                // Hộp thời gian dự kiến (đã bỏ thanh tiến trình theo yêu cầu)
                VStack(spacing: 4) {
                    Text("DỰ KIẾN HOÀN TẤT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(violetNeon)
                    Text(info.estimatedDuration.isEmpty ? "Khoảng 15 - 30 Phút" : info.estimatedDuration)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 0.12, green: 0.08, blue: 0.20))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(violetNeon.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 14)

                // Các nút hành động
                VStack(spacing: 10) {
                    // Nút Discord
                    Button {
                        let targetURL = info.discordURL.isEmpty ? "https://discord.gg/A3wS4ZPFQn" : info.discordURL
                        if let url = URL(string: targetURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Tham Gia Discord Cập Nhật")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [violetNeon, deepIndigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                        .shadow(color: violetNeon.opacity(0.4), radius: 10, y: 4)
                    }

                    // Nút Kiểm Tra Lại
                    if let refreshAction = onRefresh {
                        Button {
                            refreshAction()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Kiểm Tra Lại")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.13),
                        Color(red: 0.04, green: 0.03, blue: 0.07)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(violetNeon.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: violetNeon.opacity(0.25), radius: 30, y: 10)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - MÀN HÌNH XÁC NHẬN BẢN QUYỀN SAU KHI NHẬP KEY (CLEAN VOID BLACK • SHINY WHITE GLOW)
struct LoginSuccessIntroView: View {
    var planName: String = ""
    var remainingTime: String = ""
    var deviceID: String = ""
    let onFinished: () -> Void

    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0.0
    @State private var showCopiedDeviceID: Bool = false

    private var currentDeviceID: String {
        if !deviceID.isEmpty { return deviceID }
        return CheatStoreLicenseManager.shared.deviceID
    }

    private var displayExpiry: String {
        if !remainingTime.isEmpty { return remainingTime }
        let mgr = CheatStoreLicenseManager.shared
        if !mgr.formattedRemainingTime.isEmpty && mgr.formattedRemainingTime != "Hết hạn" {
            return mgr.formattedRemainingTime
        }
        return "30 Ngày (Hạn dùng: 31/10/2026)"
    }

    private var deviceHardwareDisplay: String {
        "\(AppInfo.hardwareDisplayName) (iOS \(UIDevice.current.systemVersion))"
    }

    var body: some View {
        ZStack {
            // Nền tối mờ True Black
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            // Vầng sáng trắng phát sáng dịu nhẹ (White ambient glow)
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.10), Color.clear]),
                center: .center,
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 18) {
                    // 1. Header: Icon Nhận Diện + Tên Brand Trắng Phát Sáng + Badge Thành Công
                    headerSection

                    // 2. Thẻ Thông Tin Clean: Hạn Key • Thiết Bị • Mã Máy
                    infoCardSection

                    // 3. Nút "VÀO APP" Chữ Trắng Phát Sáng Nổi Bật Sang Trọng
                    enterAppButton
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color(red: 0.04, green: 0.04, blue: 0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.white.opacity(0.12), radius: 24, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.7), radius: 32, x: 0, y: 16)
                .frame(maxWidth: 340)
                .padding(.horizontal, 20)
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 10) {
            CheatStoreLogoView(size: 60, cornerRadius: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.38), lineWidth: 1.2)
                )
                .shadow(color: Color.white.opacity(0.22), radius: 12, x: 0, y: 0)

            VStack(spacing: 4) {
                ShinyTextView(
                    text: AppBrandingTheme.current.appTitle,
                    font: .system(size: 23, weight: .heavy, design: .rounded),
                    baseColor: Color(white: 0.88),
                    shineColor: .white,
                    duration: 2.2,
                    tracking: -0.3
                )

                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
                    Text("XÁC THỰC KEY THÀNH CÔNG")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 4.5)
                .background(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.12))
                .cornerRadius(999)
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.20, green: 0.88, blue: 0.45).opacity(0.28), lineWidth: 0.8)
                )
            }
        }
    }

    private var infoCardSection: some View {
        VStack(spacing: 11) {
            // Hàng 1: Hạn Key
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.white.opacity(0.75))
                    Text("Hạn Key")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                Text(displayExpiry)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
            }

            Divider().background(Color.white.opacity(0.08))

            // Hàng 2: Thiết Bị
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.white.opacity(0.75))
                    Text("Thiết Bị")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                Text(deviceHardwareDisplay)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Divider().background(Color.white.opacity(0.08))

            // Hàng 3: Mã Máy
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.white.opacity(0.75))
                    Text("Mã Máy")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = currentDeviceID
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showCopiedDeviceID = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedDeviceID = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(String(currentDeviceID.prefix(12)) + "...")
                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.85))
                        Image(systemName: showCopiedDeviceID ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(showCopiedDeviceID ? Color(red: 0.20, green: 0.88, blue: 0.45) : Color.white.opacity(0.6))
                        if showCopiedDeviceID {
                            Text("Đã chép")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 0.20, green: 0.88, blue: 0.45))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var enterAppButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeOut(duration: 0.25)) {
                cardOpacity = 0.0
                cardScale = 0.92
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onFinished()
            }
        }) {
            HStack(spacing: 8) {
                ShinyTextView(
                    text: "VÀO APP",
                    font: .system(size: 16, weight: .heavy, design: .rounded),
                    baseColor: Color(white: 0.90),
                    shineColor: .white,
                    duration: 2.0,
                    tracking: 1.0
                )

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [Color(white: 0.16), Color(white: 0.07)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1.2)
            )
            .shadow(color: Color.white.opacity(0.22), radius: 10, y: 0)
        }
    }
}

// MARK: - POPUP MODAL THÔNG BÁO NHẬP KEY (APPLE PAY GLASS MODAL)
struct KeyNotificationModalView: View {
    let notification: KeyNotificationType
    let onDismiss: () -> Void
    let onConfirmSuccess: () -> Void

    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00)
    private let brandGreen = Color(red: 0.20, green: 0.88, blue: 0.45)
    private let brandRed = Color(red: 1.00, green: 0.30, blue: 0.35)
    private let sakura = Color.white

    var body: some View {
        ZStack {
            // Nền tối mờ hiệu ứng Blur
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 16) {
                // Header góc phải có nút Đóng (X)
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.top, 14)
                .padding(.trailing, 14)

                switch notification {
                case .success(let plan, let remaining, let expiry):
                    // Biểu tượng thành công Mẫu 1: Apple Pay Glass Checkmark
                    ApplePayCheckmarkView()
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    VStack(spacing: 8) {
                        // Badge Bản quyền AppleStore (icon trái táo)
                        HStack(spacing: 4) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 10, weight: .bold))
                            Text("Bản quyền AppleStore")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(brandGreen)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(brandGreen.opacity(0.15))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(brandGreen.opacity(0.35), lineWidth: 1)
                        )

                        Text("Kích Hoạt Thành Công")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Chào mừng bạn! Bản quyền VIP CheatStore VN đã sẵn sàng trên thiết bị.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                    }

                    // Card chi tiết gói phong cách Glass
                    VStack(spacing: 10) {
                        HStack {
                            Text("Gói bản quyền:")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(plan.uppercased())
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.98, green: 0.88, blue: 0.35), sakura],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }

                        Divider().background(Color.white.opacity(0.08))

                        HStack {
                            Text("Thời hạn:")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(remaining)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(brandGreen)
                        }

                        if !expiry.isEmpty {
                            Divider().background(Color.white.opacity(0.08))

                            HStack {
                                Text("Hạn sử dụng:")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(expiry)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 18)

                    // Các nút thao tác (Tiếp tục vào game + Đóng)
                    VStack(spacing: 10) {
                        Button {
                            onConfirmSuccess()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Tiếp Tục Vào Game")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.10, green: 0.85, blue: 0.55),
                                        Color(red: 0.05, green: 0.65, blue: 0.40)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                            .shadow(color: brandGreen.opacity(0.4), radius: 10, y: 4)
                        }

                        Button {
                            onDismiss()
                        } label: {
                            Text("Đóng")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)

                case .error(let message):
                    let isUpdate = message.lowercased().contains("cũ")
                        || message.lowercased().contains("cập nhật")
                        || message.lowercased().contains("phiên bản")
                        || message.lowercased().contains("update")
                        || message.lowercased().contains("tải xuống")
                        || AppUpdateChecker.shared.isForceUpdateRequired

                    if isUpdate {
                        // 1. Biểu tượng Download với hiệu ứng lên xuống nhẹ nhàng
                        AnimatedDownloadIconView()
                            .padding(.top, 4)

                        VStack(spacing: 8) {
                            // Badge Phiên bản mới
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .black))
                                Text("CẬP NHẬT BẢN MỚI")
                                    .font(.system(size: 10, weight: .black))
                            }
                            .foregroundStyle(sakura)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(sakura.opacity(0.16))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(sakura.opacity(0.4), lineWidth: 1)
                            )

                            // Tiêu đề thay thế: "CheatStore đã có phiên bản mới nhất"
                            Text("CheatStore đã có phiên bản mới nhất")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            // Nội dung thông báo
                            VStack(spacing: 5) {
                                Text("Vui lòng ấn Tải Xuống cập nhật mới nhé.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.92))
                                Text("Thanks You !")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(sakura)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(sakura.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)

                        // Nút Tải Xuống & Nút Đóng & Các lựa chọn hỗ trợ
                        VStack(spacing: 12) {
                            // Nút TẢI XUỐNG to, nổi bật
                            Button {
                                let downloadUrl = AppUpdateChecker.shared.updateInfo?.update_url ?? CheatStoreServerConfig.updateURL
                                if let url = URL(string: downloadUrl) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Tải Xuống")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    LinearGradient(
                                        colors: [Color.white, Color(white: 0.88)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .foregroundStyle(.black)
                                .cornerRadius(14)
                                .shadow(color: Color.white.opacity(0.35), radius: 10, y: 2)
                            }

                            // Nút Đóng
                            Button {
                                onDismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                    Text("Đóng")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                            }

                            // 2 nút phụ Hỗ trợ & Mua key
                            HStack(spacing: 12) {
                                Button {
                                    if let url = URL(string: "https://zalo.me/0365829172") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "message.fill")
                                        Text("Mua Key Zalo")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(brandBlue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(brandBlue.opacity(0.12))
                                    .cornerRadius(10)
                                }

                                Button {
                                    if let url = URL(string: "https://discord.gg/A3wS4ZPFQn") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Text("Hỗ Trợ Admin")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        // Biểu tượng thất bại với hiệu ứng Glow (Lỗi sai key, hết hạn, bị khóa...)
                        ZStack {
                            Circle()
                                .fill(brandRed.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .blur(radius: 12)

                            Circle()
                                .stroke(brandRed.opacity(0.6), lineWidth: 2)
                                .frame(width: 72, height: 72)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [brandRed, Color.orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(spacing: 8) {
                            Text("KÍCH HOẠT THẤT BÀI")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(brandRed)
                                .tracking(1.5)

                            Text("Không Thể Xác Thực Key")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)

                            Text(message)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(brandRed.opacity(0.12))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)

                        // Nút Đóng & Các lựa chọn hỗ trợ
                        VStack(spacing: 12) {
                            Button {
                                onDismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark")
                                    Text("Đóng")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.1))
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }

                            HStack(spacing: 12) {
                                Button {
                                    if let url = URL(string: "https://zalo.me/0365829172") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "message.fill")
                                        Text("Mua Key Zalo")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(brandBlue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(brandBlue.opacity(0.12))
                                    .cornerRadius(10)
                                }

                                Button {
                                    if let url = URL(string: "https://discord.gg/A3wS4ZPFQn") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Text("Hỗ Trợ Admin")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: min(UIScreen.main.bounds.width - 48, 380))
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.035, blue: 0.12).opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        notificationBorderGradient,
                        lineWidth: 1.2
                    )
            )
            .shadow(color: notificationShadowColor, radius: 26, y: 10)
            .padding(.horizontal, 24)
        }
    }

    private var notificationBorderGradient: LinearGradient {
        switch notification {
        case .success:
            return LinearGradient(
                colors: [Color.white.opacity(0.25), brandGreen.opacity(0.5), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [brandRed.opacity(0.8), Color.orange.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var notificationShadowColor: Color {
        switch notification {
        case .success:
            return brandGreen.opacity(0.3)
        case .error:
            return brandRed.opacity(0.3)
        }
    }
}

// MARK: - Login GIF Banner View (Siêu tốc độ với UIImageView & CGImageSource Native Cache)
final class BannerGifCache {
    static let shared = BannerGifCache()
    var cachedImage: UIImage? = nil
    private var isFetching = false

    init() {
        loadFast()
    }

    func loadFast(completion: ((UIImage?) -> Void)? = nil) {
        if let cached = cachedImage {
            completion?(cached)
            return
        }

        // 1. Quét tìm file local trong AppCore / Bundle / Documents
        let candidateURLs = [
            Bundle.main.url(forResource: "login_banner", withExtension: "gif"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/login_banner.gif"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/Assets/login_banner.gif"),
            Bundle.main.bundleURL.appendingPathComponent("AppCore/login_banner.gif"),
            Bundle.main.bundleURL.appendingPathComponent("login_banner.gif"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("login_banner.gif"),
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("login_banner.gif"),
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("login_banner.gif"),
            URL(fileURLWithPath: "ThreeOneOSFive/login_banner.gif")
        ].compactMap { $0 }

        for url in candidateURLs {
            if FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url), !data.isEmpty,
               let animImg = Self.decodeGif(data: data) {
                self.cachedImage = animImg
                completion?(animImg)
                return
            }
        }

        // 2. Nếu chưa có trên đĩa, tải ngay từ link catbox và lưu cache
        guard !isFetching else { return }
        isFetching = true
        DispatchQueue.global(qos: .userInteractive).async {
            defer { self.isFetching = false }
            guard let remoteURL = URL(string: "https://files.catbox.moe/qhq1ot.gif"),
                  let data = try? Data(contentsOf: remoteURL), !data.isEmpty,
                  let animImg = Self.decodeGif(data: data) else { return }

            DispatchQueue.main.async {
                self.cachedImage = animImg
                completion?(animImg)
            }

            if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let cacheFile = cacheDir.appendingPathComponent("login_banner.gif")
                try? data.write(to: cacheFile)
            }
        }
    }

    static func decodeGif(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var images: [UIImage] = []
        var duration: Double = 0.0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))

                var frameDuration: Double = 0.05
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                    if let unclamped = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0.01 {
                        frameDuration = unclamped
                    } else if let delay = gifInfo[kCGImagePropertyGIFDelayTime] as? Double, delay > 0.01 {
                        frameDuration = delay
                    }
                }
                duration += frameDuration
            }
        }

        if images.count == 1 {
            return images.first
        }
        return UIImage.animatedImage(with: images, duration: duration > 0 ? duration : Double(count) * 0.06)
    }
}

struct LoginGifBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18
        imageView.backgroundColor = UIColor(white: 0.1, alpha: 0.2)

        if let cached = BannerGifCache.shared.cachedImage {
            imageView.image = cached
        } else {
            BannerGifCache.shared.loadFast { img in
                imageView.image = img
            }
        }
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        if uiView.image == nil, let cached = BannerGifCache.shared.cachedImage {
            uiView.image = cached
        }
    }
}
