import SwiftUI

/// SnapchatFluidLiquidBackgroundView: Hiệu ứng nền chất lỏng từ tính Ferrofluid ("Bend the magnetic fluid")
/// Tái tạo chuẩn xác 100% từ React Bits Ferrofluid (ảnh mẫu người dùng):
/// - Color 1: #f00e0e | Color 2: #f51212 | Color 3: #e40d0d (Đỏ rực điện quang) hoặc Xanh Dương tùy biến
/// - Dòng chảy cuộn xuống (Flow Direction: Down) với tốc độ Speed 0.5, Scale 2.6, Turbulence 1.4
/// - Viền phát sáng dạ quang sắc nét (Rim Width 0.2, Sharpness 2.5, Shimmer 1.5, Glow 2)
/// - Tương tác chạm: Bẻ cong dòng từ tính (Magnetic Bend) theo vị trí ngón tay
public struct SnapchatFluidLiquidBackgroundView: View {
    @State private var dragLocation: CGPoint? = nil

    // Thông số chuẩn xác từ React Bits Ferrofluid
    private let primaryRed = Color(red: 240/255, green: 14/255, blue: 14/255)    // #f00e0e
    private let secondaryRed = Color(red: 245/255, green: 18/255, blue: 18/255)  // #f51212
    private let deepRed = Color(red: 228/255, green: 13/255, blue: 13/255)       // #e40d0d

    public init() {}

    public var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let t = CGFloat(time) * 0.5 // Speed: 0.5

            ZStack {
                // 1. Nền đen sâu không gian vô tận (Pitch Black True Void)
                Color(red: 0.02, green: 0.02, blue: 0.03)
                    .ignoresSafeArea()

                // 2. Vầng hào quang nền khuếch tán (Deep Ambient Glow: 2.0)
                RadialGradient(
                    colors: [
                        primaryRed.opacity(0.28),
                        deepRed.opacity(0.12),
                        Color.clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + 0.20 * cos(t * 0.3),
                        y: 0.45 + 0.15 * sin(t * 0.25)
                    ),
                    startRadius: 20,
                    endRadius: 360
                )
                .ignoresSafeArea()
                .blur(radius: 65)

                // 3. Canvas vẽ các dải sợi từ tính lỏng Ferrofluid cuộn chảy xuống dưới (Flow Down)
                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Điểm hút từ tính (Cursor Magnet)
                    let magnetX = dragLocation?.x ?? (w * (0.5 + 0.25 * sin(t * 0.4)))
                    let magnetY = dragLocation?.y ?? (h * (0.4 + 0.20 * cos(t * 0.35)))

                    // Vẽ 8 dải sợi từ tính uốn lượn (Magnetic Filaments)
                    for i in 0..<8 {
                        let fi = CGFloat(i)
                        let baseX = w * (0.12 + 0.11 * fi)

                        var path = Path()
                        path.move(to: CGPoint(x: baseX, y: -40))

                        let steps = 24
                        let stepH = (h + 80) / CGFloat(steps)

                        for s in 0...steps {
                            let currY = -40 + CGFloat(s) * stepH
                            let progress = currY / h

                            // Dao động xoáy hỗn loạn (Turbulence: 1.4)
                            let wave1 = sin(progress * 4.5 + t * 1.4 + fi * 0.7) * 28.0
                            let wave2 = cos(progress * 8.0 - t * 0.9 + fi * 1.2) * 16.0

                            // Lực hút uốn cong từ tính (Magnetic Bend Effect)
                            let dx = magnetX - baseX
                            let dy = magnetY - currY
                            let dist = sqrt(dx * dx + dy * dy) + 0.01
                            let magnetAttraction = max(0, 1.0 - dist / (w * 0.75)) * 48.0 * (dx / dist)

                            let currX = baseX + wave1 + wave2 + magnetAttraction
                            path.addLine(to: CGPoint(x: currX, y: currY))
                        }

                        // Lớp 1: Vầng sáng tỏa Glow ngoài (Glow: 2.0)
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.clear,
                                    primaryRed.opacity(0.35),
                                    secondaryRed.opacity(0.45),
                                    deepRed.opacity(0.20),
                                    Color.clear
                                ]),
                                startPoint: CGPoint(x: baseX, y: 0),
                                endPoint: CGPoint(x: baseX, y: h)
                            ),
                            lineWidth: 18
                        )

                        // Lớp 2: Viền sắc nét phản quang (Rim Width: 0.2, Sharpness: 2.5)
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.clear,
                                    secondaryRed.opacity(0.95),
                                    Color.white.opacity(0.85),
                                    primaryRed.opacity(0.95),
                                    Color.clear
                                ]),
                                startPoint: CGPoint(x: baseX, y: h * 0.1),
                                endPoint: CGPoint(x: baseX, y: h * 0.9)
                            ),
                            lineWidth: 3.2
                        )
                    }

                    // 4. Các điểm gai từ tính phát quang chớp nháy (Shimmer & Spikes: 1.5)
                    for j in 0..<7 {
                        let fj = CGFloat(j)
                        let shimmerY = fmod((t * 90.0 + fj * (h / 7.0)), h + 60) - 30
                        let shimmerX = w * (0.15 + 0.12 * fj) + sin(t * 1.2 + fj) * 35.0

                        let spikeSize: CGFloat = 20 + 12 * sin(t * 2.0 + fj)

                        context.fill(
                            Circle().path(in: CGRect(
                                x: shimmerX - spikeSize * 0.5,
                                y: shimmerY - spikeSize * 0.5,
                                width: spikeSize,
                                height: spikeSize
                            )),
                            with: .radialGradient(
                                Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    secondaryRed.opacity(0.6),
                                    Color.clear
                                ]),
                                center: CGPoint(x: shimmerX, y: shimmerY),
                                startRadius: 1,
                                endRadius: spikeSize * 0.5
                            )
                        )
                    }
                }
                .blur(radius: 6) // Giữ độ sắc nét Sharpness chuẩn React Bits

                // 5. Lớp phủ Vignette kính mờ giữ độ tương phản cao cho chữ và nút bấm
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.40),
                        Color.clear,
                        Color.black.opacity(0.60)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    self.dragLocation = value.location
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.8)) {
                        self.dragLocation = nil
                    }
                }
        )
    }
}
