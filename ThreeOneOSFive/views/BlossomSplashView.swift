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
