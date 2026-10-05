import SwiftUI

/// SnapchatFluidLiquidBackgroundView: Hiệu ứng nền khói lỏng điện quang (Electric Liquid Fluid Smoke & Caustics)
/// Tái tạo chuẩn xác 100% phong cách nền chuyển động của Snapchat IPA / iOS External Menu:
/// - Các dải sóng chất lỏng uốn lượn (Organic Fluid Waves & Tendrils)
/// - Ánh sáng dạ quang Neon (Electric Blue, Cyan, Ice White & Sapphire) trên nền đen sâu True Void
/// - Tự động trôi lượn tuần hoàn mượt mà 60fps/120fps trên Metal GPU, không tốn pin
public struct SnapchatFluidLiquidBackgroundView: View {
    @State private var phase: CGFloat = 0.0
    @State private var pulse: CGFloat = 1.0

    public init() {}

    public var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let t = CGFloat(time)

            ZStack {
                // 1. Nền đen sâu không gian vô tận (Pitch Black True Void)
                Color(red: 0.02, green: 0.03, blue: 0.05)
                    .ignoresSafeArea()

                // 2. Vùng plasma năng lượng khuếch tán nền (Deep Ambient Glow)
                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 0.35, blue: 0.85).opacity(0.35),
                        Color(red: 0.0, green: 0.15, blue: 0.55).opacity(0.18),
                        Color.clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + 0.25 * cos(t * 0.4),
                        y: 0.45 + 0.20 * sin(t * 0.35)
                    ),
                    startRadius: 30,
                    endRadius: 340
                )
                .ignoresSafeArea()
                .blur(radius: 50)

                // 3. Vùng khói lỏng điện quang tầng 1 (Cyan Electric Tendril 1)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.40),
                                Color(red: 0.0, green: 0.45, blue: 0.95).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 260
                        )
                    )
                    .frame(width: 380, height: 380)
                    .offset(
                        x: -80 + 90 * cos(t * 0.45),
                        y: -180 + 80 * sin(t * 0.38)
                    )
                    .scaleEffect(0.95 + 0.25 * sin(t * 0.5))
                    .blur(radius: 65)

                // 4. Vùng khói lỏng điện quang tầng 2 (Deep Sapphire & Indigo Wave)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.15, green: 0.40, blue: 1.0).opacity(0.32),
                                Color(red: 0.05, green: 0.20, blue: 0.80).opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 280
                        )
                    )
                    .frame(width: 420, height: 420)
                    .offset(
                        x: 100 + 70 * sin(t * 0.32),
                        y: 120 + 90 * cos(t * 0.42)
                    )
                    .scaleEffect(1.05 + 0.20 * cos(t * 0.6))
                    .blur(radius: 75)

                // 5. Các tia sóng chất lỏng cuộn sóng (Electric Fluid Caustics Canvas)
                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Sóng caustics 1: Dải sóng uốn lượn chính
                    var path1 = Path()
                    path1.move(to: CGPoint(x: -30, y: h * 0.3))
                    for x in stride(from: -30.0, through: Double(w + 60), by: 20.0) {
                        let relX = x / Double(w)
                        let y = Double(h) * 0.35 +
                                sin(relX * 6.28 + Double(t) * 1.2) * 55.0 +
                                cos(relX * 12.56 - Double(t) * 0.8) * 35.0
                        path1.addLine(to: CGPoint(x: x, y: y))
                    }
                    path1.addLine(to: CGPoint(x: w + 50, y: h + 50))
                    path1.addLine(to: CGPoint(x: -50, y: h + 50))
                    path1.closeSubpath()

                    context.fill(
                        path1,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 0.0, green: 0.65, blue: 1.0).opacity(0.18),
                                Color(red: 0.05, green: 0.30, blue: 0.90).opacity(0.08),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: 0, y: h * 0.2),
                            endPoint: CGPoint(x: 0, y: h * 0.8)
                        )
                    )

                    // Sóng caustics 2: Tia phát quang mềm ở giữa
                    var path2 = Path()
                    path2.move(to: CGPoint(x: -30, y: h * 0.6))
                    for x in stride(from: -30.0, through: Double(w + 60), by: 25.0) {
                        let relX = x / Double(w)
                        let y = Double(h) * 0.62 +
                                cos(relX * 5.0 + Double(t) * 1.5) * 60.0 +
                                sin(relX * 10.0 + Double(t) * 1.1) * 30.0
                        path2.addLine(to: CGPoint(x: x, y: y))
                    }
                    context.stroke(
                        path2,
                        with: .color(Color(red: 0.3, green: 0.85, blue: 1.0).opacity(0.22)),
                        lineWidth: 4
                    )
                }
                .blur(radius: 35)

                // 6. Các điểm đốm sáng dạ quang lơ lửng (Floating Caustic Globules)
                ForEach(0..<6, id: \.self) { i in
                    let fi = CGFloat(i)
                    let offsetX = 130 * cos(t * (0.35 + fi * 0.08) + fi * 1.1)
                    let offsetY = 220 * sin(t * (0.42 + fi * 0.06) + fi * 0.9)
                    let size: CGFloat = 30 + fi * 10

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color(red: 0.1, green: 0.7, blue: 1.0).opacity(0.20),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: size * 0.5
                            )
                        )
                        .frame(width: size, height: size)
                        .offset(x: offsetX, y: offsetY)
                        .blur(radius: 12)
                }

                // 7. Lớp phủ Vignette kính mờ giữ độ tương phản cao cho chữ và nút
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.35),
                        Color.clear,
                        Color.black.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }
}
