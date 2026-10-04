import SwiftUI

/// Hiệu ứng quét tia sáng Neon kim loại lấp lánh (Tái tạo 100% shiny-text.js từ bản IPA)
struct ShinyTextView: View {
    let text: String
    var font: Font = .system(size: 20, weight: .bold, design: .rounded)
    var baseColor: Color = Color.white.opacity(0.85)
    var shineColor: Color = BlossomTheme.sakuraLight
    var duration: Double = 2.2
    var tracking: CGFloat = 0.5

    @State private var shineOffset: CGFloat = -1.0

    var body: some View {
        Text(text)
            .font(font)
            .tracking(tracking)
            .foregroundStyle(baseColor)
            .overlay(
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [
                            Color.clear,
                            shineColor.opacity(0.3),
                            Color.white,
                            shineColor.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: max(40, width * 0.45))
                    .offset(x: shineOffset * (width + 60) - 30)
                    .blendMode(.screen)
                }
                .mask(
                    Text(text)
                        .font(font)
                        .tracking(tracking)
                )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    shineOffset = 1.6
                }
            }
    }
}

// MARK: - View Modifier tiện lợi
extension View {
    func shinyShimmer(color: Color = BlossomTheme.sakuraLight, duration: Double = 2.4) -> some View {
        self.overlay(
            GeometryReader { geo in
                let width = geo.size.width
                LinearGradient(
                    colors: [
                        Color.clear,
                        color.opacity(0.4),
                        Color.white.opacity(0.9),
                        color.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: max(35, width * 0.4))
                .offset(x: -width * 0.5)
            }
            .mask(self)
        )
    }
}
