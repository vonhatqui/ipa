import SwiftUI
import UIKit

struct CheatStoreLoginView: View {
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @State private var inputKey: String = ""
    @State private var copiedDeviceID = false
    @State private var showShopWeb = false

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

                        // Thông báo lỗi nếu có
                        if let error = licenseManager.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.red)
                            }
                        }

                        // Nút Kích Hoạt
                        Button {
                            Task {
                                _ = await licenseManager.activateKey(inputKey)
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

                        // Nút mở Popup Alert Controller nhập Key theo yêu cầu
                        Button {
                            presentKeyEntryPopup()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                Text("Mở Hộp Thoại Nhập Key (Popup)")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(brandBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(brandBlue.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(brandBlue.opacity(0.3), lineWidth: 1)
                            )
                        }
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
        }
        .onAppear {
            // Tự động bật Popup Alert nhập key nếu chưa kích hoạt và chưa có key
            if !licenseManager.isActivated && licenseManager.activeKey.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.presentKeyEntryPopup()
                }
            }
        }
    }

    // MARK: - Hộp Thoại Popup (Alert Controller) Nhập Key
    private func presentKeyEntryPopup(promptMessage: String? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let alert = UIAlertController(
            title: "KÍCH HOẠT BẢN QUYỀN",
            message: promptMessage ?? "Vui lòng nhập mã key 16 ký tự của bạn để kích hoạt CheatStore VN:",
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = "Nhập mã key (16 ký tự)..."
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            if !self.inputKey.isEmpty {
                tf.text = self.inputKey
            } else if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !clip.isEmpty, clip.count <= 32 {
                tf.text = clip
            }
        }

        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Kích Hoạt", style: .default) { _ in
            guard let key = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !key.isEmpty else {
                self.presentKeyEntryPopup(promptMessage: "Mã key không được để trống! Vui lòng nhập lại:")
                return
            }

            self.inputKey = key
            Task {
                let success = await self.licenseManager.activateKey(key)
                if !success {
                    let errMsg = self.licenseManager.errorMessage ?? "Mã key không hợp lệ hoặc đã hết hạn!"
                    await MainActor.run {
                        // Hiển thị thông báo lỗi từ server và yêu cầu nhập lại, không cho vào app
                        self.presentKeyEntryPopup(promptMessage: "\(errMsg)\nVui lòng kiểm tra và nhập lại mã key:")
                    }
                }
            }
        })

        topVC.present(alert, animated: true)
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
