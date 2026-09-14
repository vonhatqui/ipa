import SwiftUI
import UIKit

struct GameSelectionView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared

    let onSelectFreeFire: () -> Void

    @State private var isLoading = false
    @State private var loadingStep = "Đang nạp dữ liệu file..."

    // Cyber Blue & AMOLED Dark
    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00)
    private let brandCyan = Color(red: 0.00, green: 0.88, blue: 0.95)
    private let darkBackground = Color(red: 0.03, green: 0.05, blue: 0.09)
    private let cardBackground = Color(red: 0.06, green: 0.09, blue: 0.16)

    var body: some View {
        ZStack {
            // Nền đen xanh AMOLED
            darkBackground.ignoresSafeArea()

            // Vầng sáng neon xanh dương phía trên
            Circle()
                .fill(brandBlue.opacity(0.12))
                .blur(radius: 90)
                .frame(width: 300, height: 300)
                .offset(x: 0, y: -260)

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

            // Màn hình loading khi bắt đầu nạp file
            if isLoading {
                loadingOverlayView
                    .transition(.opacity)
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
            HStack(spacing: 14) {
                // Icon Free Fire
                FreeFireAppIconView(size: 52, cornerRadius: 12)

                // Thông tin Game
                VStack(alignment: .leading, spacing: 3) {
                    Text("Free Fire")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("com.dts.freefireth")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer()

                // Nút / Huy hiệu READY
                HStack(spacing: 8) {
                    Text("READY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(brandCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(brandCyan.opacity(0.10))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(brandCyan, lineWidth: 1.2)
                        )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .padding(14)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(brandBlue.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
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

    // MARK: - Loading Overlay khi bấm Free Fire
    private var loadingOverlayView: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(brandBlue.opacity(0.2), lineWidth: 4)
                        .frame(width: 76, height: 76)

                    Circle()
                        .trim(from: 0.0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [brandBlue, brandCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isLoading)

                    FreeFireAppIconView(size: 44, cornerRadius: 10)
                }

                VStack(spacing: 6) {
                    Text("ĐANG NẠP DỮ LIỆU FILE")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(1.1)

                    Text(loadingStep)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(brandCyan)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.10, blue: 0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(brandBlue.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: brandBlue.opacity(0.3), radius: 24)
        }
    }

    // MARK: - Bắt đầu quá trình nạp file
    private func startGameLoading() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isLoading = true
            loadingStep = "Đang giải mã và nạp file mod..."
        }

        // Thực thi nạp file ngầm
        BundledPatchInjector.autoImportBundledPatches(into: patchStore)

        // Sau 1.2s chuyển sang bảng điều khiển
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.loadingStep = "Đồng bộ môi trường Free Fire..."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
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
