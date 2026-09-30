import SwiftUI

// MARK: - Blossom Intro / Splash Screen Component (Tái tạo 100% kịch bản blossom.re)
struct BlossomSplashView: View {
    let onFinished: () -> Void

    // Animation States
    @State private var textGroupOffsetY: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffsetY: CGFloat = 15
    @State private var overlayOpacity: Double = 1.0
    @State private var borderGlowOpacity: Double = 0.0
    @State private var isDismissed = false

    var body: some View {
        ZStack {
            // Lớp phủ tối mờ toàn màn hình (#introOverlay của blossom.re)
            ZStack {
                BlossomTheme.bgBottom
                    .opacity(0.92)
                    .ignoresSafeArea()

                // Nền gradient tím sẫm hòa quyện
                BlossomTheme.backgroundGradient
                    .opacity(0.85)
                    .ignoresSafeArea()

                // Viền sáng mờ quanh mép màn hình (Screen Inset Neon Glow)
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                BlossomTheme.sakura.opacity(0.5),
                                BlossomTheme.sakuraDeep.opacity(0.2),
                                BlossomTheme.sakuraLight.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .padding(8)
                    .ignoresSafeArea()
                    .opacity(borderGlowOpacity)
            }

            // Cụm chữ Typography trung tâm
            VStack(spacing: 12) {
                // Tiêu đề chính "CHEATSTORE"
                Text("CHEATSTORE")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(12)
                    .foregroundStyle(BlossomTheme.textGradient)
                    .shadow(color: BlossomTheme.sakura.opacity(0.75), radius: 24, x: 0, y: 0)
                    .shadow(color: BlossomTheme.sakuraDeep.opacity(0.45), radius: 40, x: 0, y: 0)
                    .opacity(titleOpacity)

                // Tiêu đề phụ "PRESENTS"
                Text("PRESENTS")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(8)
                    .foregroundStyle(BlossomTheme.sakuraLight.opacity(0.92))
                    .shadow(color: BlossomTheme.sakura.opacity(0.5), radius: 12, x: 0, y: 0)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffsetY)
            }
            .offset(y: textGroupOffsetY)

            // Dòng gợi ý chạm để bỏ qua nhẹ nhàng ở đáy
            VStack {
                Spacer()
                Text("Chạm để bỏ qua")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BlossomTheme.textDim.opacity(0.4))
                    .padding(.bottom, 32)
                    .opacity(titleOpacity > 0.5 ? 0.8 : 0)
            }
        }
        .opacity(overlayOpacity)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissImmediately()
        }
        .onAppear {
            startBlossomTimeline()
        }
    }

    // MARK: - Timeline Animation 5 Giai Đoạn Chuẩn Blossom.re
    private func startBlossomTimeline() {
        // Giai đoạn 0: Viền neon sáng dần
        withAnimation(.easeIn(duration: 0.8)) {
            borderGlowOpacity = 1.0
        }

        // Giai đoạn 1 (t=0.2s): "CHEATSTORE" trượt từ dưới lên & hiện rõ mượt mà
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard !isDismissed else { return }
            withAnimation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 1.3)) {
                titleOpacity = 1.0
                textGroupOffsetY = 0
            }
        }

        // Giai đoạn 2 (t=1.3s): Cụm chữ nâng nhẹ lên, "PRESENTS" trượt vào bên dưới
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            guard !isDismissed else { return }
            withAnimation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 1.2)) {
                textGroupOffsetY = -16
                subtitleOpacity = 1.0
                subtitleOffsetY = 0
            }
        }

        // Giai đoạn 3 (t=2.5s): Cụm chữ tăng tốc trượt lên và mờ dần
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard !isDismissed else { return }
            withAnimation(.easeIn(duration: 0.7)) {
                textGroupOffsetY = -60
                titleOpacity = 0.0
                subtitleOpacity = 0.0
            }
        }

        // Giai đoạn 4 (t=2.9s): Lớp phủ mờ nền tan biến
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            guard !isDismissed else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                overlayOpacity = 0.0
            }
        }

        // Giai đoạn 5 (t=3.3s): Hoàn tất và kích hoạt giao diện chính
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            guard !isDismissed else { return }
            isDismissed = true
            onFinished()
        }
    }

    // Chạm để bỏ qua tức thì (Fast-forward)
    private func dismissImmediately() {
        guard !isDismissed else { return }
        isDismissed = true
        withAnimation(.easeOut(duration: 0.35)) {
            textGroupOffsetY = -40
            titleOpacity = 0.0
            subtitleOpacity = 0.0
            overlayOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onFinished()
        }
    }
}

// MARK: - Blossom Notice Modal Component (Thông báo chào mừng đồng bộ CheatStore Vn)
struct BlossomNoticeModalView: View {
    var onDiscord: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Lớp nền mờ tối sẫm (Backdrop Blur)
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Hộp thoại thông báo kính mờ Blossom Glassmorphism
            VStack(spacing: 18) {
                // Header: Icon dấu tích nhỏ + CheatStore Vn
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BlossomTheme.sakuraLight, BlossomTheme.sakura],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: BlossomTheme.sakura.opacity(0.8), radius: 8)

                    Text("CheatStore Vn")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }

                // Dải kẻ ngang gradient tinh tế
                LinearGradient(
                    colors: [
                        BlossomTheme.sakura.opacity(0.6),
                        BlossomTheme.sakuraDeep.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)

                // Nội dung thông báo
                Text("Chúng tôi luôn cung cấp những thứ an toàn, chất lượng đến các bạn và những cập nhật mang tính an toàn, tự bảo về tài khoản của bạn nhé")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 2 Nút Hành Động: Discord - Đóng
                HStack(spacing: 12) {
                    // Nút Discord
                    Button {
                        onDiscord()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Discord")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(BlossomTheme.buttonGradient)
                        .cornerRadius(12)
                        .shadow(color: BlossomTheme.sakuraDeep.opacity(0.4), radius: 8, y: 3)
                    }

                    // Nút Đóng
                    Button {
                        onDismiss()
                    } label: {
                        Text("Đóng")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 4)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.082, green: 0.043, blue: 0.137).opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                BlossomTheme.sakura.opacity(0.65),
                                BlossomTheme.sakuraDeep.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: BlossomTheme.sakura.opacity(0.25), radius: 24, y: 8)
            .shadow(color: Color.black.opacity(0.6), radius: 30, y: 15)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - CheatStore Force Update Component (OTA Update Modal)

/// Bảng thông báo BẮT BUỘC CẬP NHẬT (Force Update) dành riêng cho các phiên bản cũ
/// Bản mới nhất sẽ KHÔNG bao giờ nhìn thấy bảng này.
struct BlossomForceUpdateModalView: View {
    let info: RemoteAppUpdateInfo

    @State private var isCopied: Bool = false
    @State private var isCheckingAgain: Bool = false
    @State private var isPulsing: Bool = false
    @State private var isFloating: Bool = false

    private var targetURL: URL? {
        URL(string: info.update_url)
    }

    var body: some View {
        ZStack {
            // Lớp nền đen mờ bao phủ toàn bộ màn hình, khóa mọi tương tác bên dưới
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            // Thẻ thông báo kính mờ Blossom Glassmorphism
            VStack(spacing: 16) {
                // Header: Biểu tượng download với hiệu ứng nhấp nhô nhẹ nhàng
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.00, green: 0.88, blue: 1.00).opacity(0.35),
                                    BlossomTheme.sakura.opacity(0.20),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 44
                            )
                        )
                        .frame(width: 84, height: 84)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.88, blue: 1.00), BlossomTheme.sakura],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 68, height: 68)

                    Circle()
                        .fill(Color(red: 0.12, green: 0.04, blue: 0.18))
                        .frame(width: 60, height: 60)

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.88, blue: 1.00), BlossomTheme.sakura],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.00, green: 0.88, blue: 1.00).opacity(0.6), radius: 8)
                        .offset(y: isFloating ? -5 : 5)
                }
                .padding(.top, 4)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        isFloating = true
                    }
                }

                // Tiêu đề thông báo CheatStore Update
                VStack(spacing: 8) {
                    Text("CheatStore Update")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(red: 1.0, green: 0.85, blue: 0.90)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.red.opacity(0.6), radius: 8)

                    // Huy hiệu hiển thị phiên bản & Bắt buộc
                    HStack(spacing: 6) {
                        Text("PHIÊN BẢN v\(info.latest_version)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.18))
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.45), lineWidth: 1)
                            )

                        Text("BẮT BUỘC")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(6)
                    }

                    // Huy hiệu so sánh phiên bản (Bản cũ -> Bản mới)
                    HStack(spacing: 8) {
                        Text("Bản cũ: v\(AppUpdateChecker.currentVersion)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(6)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray)

                        Text("Bản mới: v\(info.latest_version)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.18))
                            .cornerRadius(6)
                    }
                }

                // Dải phân cách gradient
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.6),
                        Color.orange.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)

                // Nội dung thông điệp
                Text(info.message ?? "Phiên bản bạn đang sử dụng đã cũ và đã bị ngắt kết nối. Vui lòng cập nhật lên bản mới nhất để tiếp tục sử dụng CheatStore!")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)

                // Danh sách tính năng mới trong bản cập nhật
                if let changelog = info.changelog, !changelog.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Điểm mới trong bản cập nhật:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.3))

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(changelog, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.green)
                                        .padding(.top, 1.5)

                                    Text(item)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }

                // Nút hành động chính: UPDATE NOW
                Button {
                    if let url = targetURL {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18, weight: .black))

                            Text("TẢI XUỐNG NGAY")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(0.8)
                        }

                        Text("Nhấn để chuyển đến trang tải IPA mới nhất")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.15, blue: 0.25),
                                Color(red: 1.0, green: 0.45, blue: 0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.red.opacity(0.55), radius: 10, y: 3)
                }
                .padding(.top, 4)

                // 2 nút phụ: Sao Chép Link & Kiểm Tra Lại
                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = info.update_url
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                isCopied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Đã sao chép link!" : "Sao Chép Link")
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(isCopied ? Color.green : Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }

                    Button {
                        isCheckingAgain = true
                        Task {
                            await AppUpdateChecker.shared.checkForUpdates()
                            await MainActor.run {
                                isCheckingAgain = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isCheckingAgain {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Kiểm Tra Lại")
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                }

                // Cảnh báo chân trang
                Text("⚠️ Phiên bản cũ không còn được hỗ trợ. Vui lòng cài bản mới để vào app.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                Color(red: 0.082, green: 0.043, blue: 0.137)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.20, blue: 0.35).opacity(0.8),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .cornerRadius(22)
            .shadow(color: Color.red.opacity(0.3), radius: 20)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
