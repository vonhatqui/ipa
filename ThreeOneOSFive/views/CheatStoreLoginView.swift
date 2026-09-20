import SwiftUI
import UIKit

struct CheatStoreLoginView: View {
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @State private var inputKey: String = ""
    @State private var copiedDeviceID = false
    @State private var showShopWeb = false
    @State private var keyNotification: KeyNotificationType? = nil

    init(licenseManager: CheatStoreLicenseManager = .shared) {
        self.licenseManager = licenseManager
    }

    // Theme: Blossom Luxury Sakura Purple (Chuẩn 100% blossom.re)
    private let brandBlue = BlossomTheme.sakura
    private let brandBlueDark = BlossomTheme.sakuraDeep
    private let darkBackground = BlossomTheme.bgBottom

    var body: some View {
        ZStack {
            // Nền hoa anh đào đêm và hạt bay rơi nhẹ chuẩn blossom.re
            BlossomBackgroundView(showParticles: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Logo với vòng xoay Conic Rings đa chiều (.brand-icon-ring của blossom.re)
                    VStack(spacing: 16) {
                        BlossomLogoRingView(size: 84, cornerRadius: 22) {
                            CheatStoreLogoView(size: 84, cornerRadius: 22)
                        }
                        .padding(.top, 36)

                        Text("CheatStore VN")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Hệ Thống Phân Phối Tiện Ích & Mod Game iOS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.gray)
                    }

                    // Card Nhập Key
                    VStack(alignment: .leading, spacing: 18) {
                        Text("KÍCH HOẠT BẢN QUYỀN")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .tracking(1.2)

                        // Ô Nhập Key
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(brandBlue)
                                .frame(width: 24)

                            TextField("Nhập mã key của bạn...", text: $inputKey)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .foregroundStyle(.white)
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))

                            if !inputKey.isEmpty {
                                Button {
                                    inputKey = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray)
                                }
                            }

                            Button {
                                if let text = UIPasteboard.general.string {
                                    inputKey = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            } label: {
                                Text("Dán")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(brandBlue.opacity(0.2))
                                    .foregroundStyle(brandBlue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(brandBlue.opacity(0.3), lineWidth: 1)
                        )

                        // Tùy chọn Ghi Nhớ Mã Key trên thiết bị
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                licenseManager.rememberKey.toggle()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(licenseManager.rememberKey ? brandBlue.opacity(0.2) : Color.white.opacity(0.05))
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(licenseManager.rememberKey ? brandBlue : Color.white.opacity(0.25), lineWidth: 1.5)
                                        )

                                    if licenseManager.rememberKey {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(brandBlue)
                                    }
                                }

                                Text("Ghi nhớ mã key trên thiết bị này")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(licenseManager.rememberKey ? .white : .gray)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)

                        // Nút Kích Hoạt / Đăng Nhập
                        Button {
                            Task {
                                let success = await licenseManager.activateKey(inputKey)
                                await MainActor.run {
                                    if success {
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                                            keyNotification = .success(
                                                plan: licenseManager.planName.isEmpty ? "Gói VIP" : licenseManager.planName,
                                                remaining: licenseManager.formattedRemainingTime,
                                                expiry: licenseManager.expiresAtString
                                            )
                                        }
                                    } else {
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.error)
                                        let msg = licenseManager.errorMessage ?? "Kích hoạt không thành công. Vui lòng thử lại!"
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                                            keyNotification = .error(message: msg)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if licenseManager.isVerifying {
                                    ProgressView()
                                        .tint(.black)
                                        .padding(.trailing, 4)
                                    Text("Đang kiểm tra...")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.black)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text(!licenseManager.activeKey.isEmpty && inputKey == licenseManager.activeKey ? "Đăng Nhập Ngay" : "Kích Hoạt Ngay")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [brandBlue, brandBlueDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                            .shadow(color: brandBlue.opacity(0.4), radius: 8, y: 4)
                        }
                        .disabled(licenseManager.isVerifying || inputKey.isEmpty)
                        .opacity((licenseManager.isVerifying || inputKey.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(20)
                    .background(Color(red: 0.06, green: 0.09, blue: 0.16))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(brandBlue.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // Thông tin thiết bị (Device ID)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MÃ THIẾT BỊ (DEVICE ID)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray)

                        HStack {
                            Text(licenseManager.deviceID)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Button {
                                UIPasteboard.general.string = licenseManager.deviceID
                                copiedDeviceID = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.copiedDeviceID = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedDeviceID ? "checkmark" : "doc.on.doc")
                                    Text(copiedDeviceID ? "Đã chép" : "Sao chép")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(copiedDeviceID ? brandBlue : .gray)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 24)

                    // Nút Hỗ trợ / Mua Key
                    HStack(spacing: 14) {
                        Button {
                            if let url = URL(string: "https://zalo.me/0365829172") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "message.fill")
                                Text("Mua Key Zalo")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(brandBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(brandBlue.opacity(0.12))
                            .cornerRadius(12)
                        }

                        Button {
                            if let url = URL(string: "https://discord.gg/A3wS4ZPFQn") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Hỗ Trợ Admin")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.bottom, 40)
            }

            // POPUP MODAL THÔNG BÁO KẾT QUẢ NHẬP KEY (HIỆU ỨNG CYBERPUNK CÓ NÚT ĐÓNG)
            if let notif = keyNotification {
                KeyNotificationModalView(
                    notification: notif,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.22)) {
                            keyNotification = nil
                        }
                    },
                    onConfirmSuccess: {
                        withAnimation {
                            keyNotification = nil
                            licenseManager.confirmActivation()
                        }
                    }
                )
                .transition(.scale(scale: 0.86).combined(with: .opacity))
                .zIndex(50)
            }

            // POPUP MODAL THÔNG BÁO BẢO TRÌ (MẪU 4: DARK MECH TITANIUM)
            if licenseManager.isMaintenanceActive || AppUpdateChecker.shared.isMaintenanceActive {
                let info = licenseManager.maintenanceInfo ?? AppUpdateChecker.shared.maintenanceInfo ?? AppMaintenanceInfo.defaultInfo
                DarkMechMaintenanceModalView(
                    info: info,
                    onRefresh: {
                        Task {
                            await AppUpdateChecker.shared.checkForUpdates()
                            _ = await licenseManager.verifyCurrentDevice()
                        }
                    }
                )
                .transition(.scale(scale: 0.86).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onAppear {
            if inputKey.isEmpty && !licenseManager.activeKey.isEmpty {
                inputKey = licenseManager.activeKey
            }
        }
    }
}

struct CheatStoreLogoView: View {
    var size: CGFloat = 84
    var cornerRadius: CGFloat = 22

    private var loadedImage: UIImage? {
        if let img = UIImage(named: "CheatLogo") ?? UIImage(named: "CheatStoreLogo") {
            return img
        }
        if let resPath = Bundle.main.resourcePath {
            let appCoreAssets = (resPath as NSString).appendingPathComponent("AppCore/Assets")
            let candidates = ["CheatLogo.png", "CheatStoreLogo.jpg", "CheatStoreLogo.png"]
            for name in candidates {
                let p = (appCoreAssets as NSString).appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: p) { return img }
            }
        }
        if let path = Bundle.main.path(forResource: "CheatLogo", ofType: "png") ??
                      Bundle.main.path(forResource: "CheatStoreLogo", ofType: "png") ??
                      Bundle.main.path(forResource: "CheatStoreLogo", ofType: "jpg"),
           let img = UIImage(contentsOfFile: path) {
            return img
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
                        .stroke(BlossomTheme.sakura.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: BlossomTheme.sakura.opacity(0.4), radius: 10)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(BlossomTheme.sakura.opacity(0.16))
                    .frame(width: size, height: size)
                    .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(BlossomTheme.sakura.opacity(0.6), lineWidth: 1.5)
                    )

                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(BlossomTheme.sakura)
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
    private let sakura = BlossomTheme.sakura
    private let cyan = Color(red: 0.00, green: 0.88, blue: 1.00)

    var body: some View {
        ZStack {
            // Glow nền tròn đa tầng
            Circle()
                .fill(
                    RadialGradient(
                        colors: [cyan.opacity(0.35), sakura.opacity(0.20), Color.clear],
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
                        colors: [cyan, sakura.opacity(0.7)],
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
                        colors: [cyan, sakura],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: cyan.opacity(0.65), radius: 8, y: 2)
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

// MARK: - POPUP MODAL THÔNG BÁO NHẬP KEY (APPLE PAY GLASS MODAL)
struct KeyNotificationModalView: View {
    let notification: KeyNotificationType
    let onDismiss: () -> Void
    let onConfirmSuccess: () -> Void

    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00)
    private let brandGreen = Color(red: 0.20, green: 0.88, blue: 0.45)
    private let brandRed = Color(red: 1.00, green: 0.30, blue: 0.35)
    private let sakura = BlossomTheme.sakura

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
                                let downloadUrl = AppUpdateChecker.shared.updateInfo?.update_url ?? "https://cheatingenginexyz.online/update.php"
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
                                        colors: [sakura, BlossomTheme.sakuraDeep],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .cornerRadius(14)
                                .shadow(color: sakura.opacity(0.45), radius: 10, y: 4)
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
