import SwiftUI

/// SnapchatFluidLiquidBackgroundView: Hiệu ứng nền chảy chảy (Liquid Mesh / Flowing Aurora Blobs)
/// Tái tạo phong cách nền chuyển động lượn sóng huyền ảo của Snapchat/iOS luxury:
/// - 4 vùng ánh sáng quang học (Cyan, Electric Purple, Cobalt, Emerald)
/// - Chuyển động lơ lửng, biến đổi vị trí và độ co giãn (scale & offset) liên tục
/// - Siêu mượt 60fps/120fps trên GPU Metal mà không tốn pin
public struct SnapchatFluidLiquidBackgroundView: View {
    @State private var isFlowing: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            // Nền tối sẫm không gian sâu chuẩn Image 3
            Color(red: 0.05, green: 0.06, blue: 0.09)
                .ignoresSafeArea()

            // Vùng chảy 1 (Cyan / Ice Neon) - Trôi từ góc trên bên trái sang giữa
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.75, blue: 1.0).opacity(0.32),
                            Color(red: 0.0, green: 0.45, blue: 0.95).opacity(0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 240
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: isFlowing ? -90 : 70, y: isFlowing ? -220 : -100)
                .scaleEffect(isFlowing ? 1.2 : 0.85)
                .blur(radius: 65)

            // Vùng chảy 2 (Electric Violet / Purple) - Trôi từ góc giữa bên phải sang trái
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.65, green: 0.22, blue: 1.0).opacity(0.26),
                            Color(red: 0.42, green: 0.12, blue: 0.90).opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 25,
                        endRadius: 260
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: isFlowing ? 110 : -50, y: isFlowing ? 30 : 160)
                .scaleEffect(isFlowing ? 0.9 : 1.25)
                .blur(radius: 75)

            // Vùng chảy 3 (Deep Cobalt Blue) - Trôi góc dưới đáy
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.12, green: 0.38, blue: 0.95).opacity(0.25),
                            Color(red: 0.05, green: 0.18, blue: 0.65).opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 250
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: isFlowing ? -70 : 80, y: isFlowing ? 300 : 190)
                .scaleEffect(isFlowing ? 1.15 : 0.9)
                .blur(radius: 70)

            // Vùng chảy 4 (Neon Mint / Emerald) - Điểm xuyết ánh quang xanh dương bảo mật
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.15, green: 0.88, blue: 0.70).opacity(0.18),
                            Color(red: 0.05, green: 0.60, blue: 0.50).opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 190
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: isFlowing ? 60 : -100, y: isFlowing ? -60 : 70)
                .scaleEffect(isFlowing ? 1.05 : 0.8)
                .blur(radius: 60)

            // Lớp phủ Vignette kính mờ bảo vệ độ tương phản chữ
            Color.black.opacity(0.25)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6.5)
                .repeatForever(autoreverses: true)
            ) {
                isFlowing.toggle()
            }
        }
    }
}
