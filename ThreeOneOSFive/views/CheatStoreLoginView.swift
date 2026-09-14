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

    // Theme: Xanh Dương Đen (Cyber Blue & AMOLED Dark)
    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00) // Electric Cyan #00b8ff
    private let brandBlueDark = Color(red: 0.00, green: 0.45, blue: 0.90)
    private let darkBackground = Color(red: 0.03, green: 0.05, blue: 0.09)

    var body: some View {
        ZStack {
            // Nền AMOLED Dark
            darkBackground
                .ignoresSafeArea()

            // Vòng tròn phát sáng hiệu ứng Cyberpunk Neon Xanh Dương
            Circle()
                .fill(brandBlue.opacity(0.15))
                .blur(radius: 70)
                .frame(width: 260, height: 260)
                .offset(y: -180)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Logo & Tên Shop
                    VStack(spacing: 12) {
                        CheatStoreLogoView(size: 84, cornerRadius: 22)
                            .padding(.top, 40)

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

                        // Nút Kích Hoạt
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
                                    Text("Kích Hoạt Ngay")
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
                            if let url = URL(string: "https://cheatingenginexyz.online") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "cart.fill")
                                Text("Mua Key Tại Web")
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
        }
    }
}

struct CheatStoreLogoView: View {
    var size: CGFloat = 84
    var cornerRadius: CGFloat = 22

    private var loadedImage: UIImage? {
        if let img = UIImage(named: "CheatLogo") {
            return img
        }
        if let path = Bundle.main.path(forResource: "CheatLogo", ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        if let path = Bundle.main.path(forResource: "CheatStoreLogo", ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        if let path = Bundle.main.path(forResource: "CheatStoreLogo", ofType: "jpg"),
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
                        .stroke(Color(red: 0.00, green: 0.72, blue: 1.00).opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.00, green: 0.72, blue: 1.00).opacity(0.35), radius: 10)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.00, green: 0.72, blue: 1.00).opacity(0.16))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(red: 0.00, green: 0.72, blue: 1.00).opacity(0.5), lineWidth: 1.5)
                    )

                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(Color(red: 0.00, green: 0.72, blue: 1.00))
            }
        }
    }
}

// MARK: - CÁC TRẠNG THÁI THÔNG BÁO NHẬP KEY
enum KeyNotificationType {
    case success(plan: String, remaining: String, expiry: String)
    case error(message: String)
}

// MARK: - POPUP MODAL THÔNG BÁO HIỆU ỨNG CYBERPUNK (CÓ NÚT ĐÓNG)
struct KeyNotificationModalView: View {
    let notification: KeyNotificationType
    let onDismiss: () -> Void
    let onConfirmSuccess: () -> Void

    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00)
    private let brandBlueDark = Color(red: 0.00, green: 0.45, blue: 0.90)
    private let brandGreen = Color(red: 0.10, green: 0.85, blue: 0.55)
    private let brandRed = Color(red: 1.00, green: 0.30, blue: 0.35)

    var body: some View {
        ZStack {
            // Nền tối mờ hiệu ứng Blur
            Color.black.opacity(0.68)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 18) {
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
                .padding(.top, 16)
                .padding(.trailing, 16)

                switch notification {
                case .success(let plan, let remaining, let expiry):
                    // Biểu tượng thành công với hiệu ứng Glow
                    ZStack {
                        Circle()
                            .fill(brandGreen.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .blur(radius: 12)

                        Circle()
                            .stroke(brandGreen.opacity(0.6), lineWidth: 2)
                            .frame(width: 72, height: 72)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [brandGreen, brandBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text("KÍCH HOẠT THÀNH CÔNG")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(brandGreen)
                            .tracking(1.5)

                        Text("Chào mừng bạn!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Bản quyền CheatStore VN đã sẵn sàng sử dụng.")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    // Card chi tiết gói
                    VStack(spacing: 10) {
                        HStack {
                            Text("Gói bản quyền:")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(plan)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Divider().background(Color.white.opacity(0.1))

                        HStack {
                            Text("Thời hạn:")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(remaining)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(brandBlue)
                        }

                        if !expiry.isEmpty {
                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Text("Hạn sử dụng:")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(expiry)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(brandGreen.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // Các nút thao tác (Vào Ứng Dụng + Đóng)
                    VStack(spacing: 10) {
                        Button {
                            onConfirmSuccess()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Vào Ứng Dụng")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: [brandBlue, brandBlueDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .shadow(color: brandBlue.opacity(0.4), radius: 8, y: 3)
                        }

                        Button {
                            onDismiss()
                        } label: {
                            Text("Đóng")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                case .error(let message):
                    // Biểu tượng thất bại với hiệu ứng Glow
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(brandRed.opacity(0.3), lineWidth: 1)
                            )
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
                                if let url = URL(string: "https://cheatingenginexyz.online") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("Mua Key Tại Web")
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
            .frame(maxWidth: min(UIScreen.main.bounds.width - 48, 380))
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.08, blue: 0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        notificationBorderGradient,
                        lineWidth: 1.5
                    )
            )
            .shadow(color: notificationShadowColor, radius: 24, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private var notificationBorderGradient: LinearGradient {
        switch notification {
        case .success:
            return LinearGradient(
                colors: [brandGreen.opacity(0.8), brandBlue.opacity(0.5)],
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
