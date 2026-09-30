import SwiftUI

// MARK: - Blossom Design Tokens (Trích xuất 100% từ blossom.re)
enum BlossomTheme {
    // Colors - Đậm sâu, phát sáng và rực rỡ hơn (Rich Neon Purple Aesthetic)
    static let bgTop = Color(red: 0.055, green: 0.024, blue: 0.098)       // #0e0619 (Đậm sâu hơn)
    static let bgBottom = Color(red: 0.020, green: 0.008, blue: 0.038)    // #05020a (Đậm sâu hơn)
    static let sakura = Color(red: 0.812, green: 0.478, blue: 1.000)      // #cf7aff (Sáng rực rỡ và đậm đà hơn)
    static let sakuraLight = Color(red: 0.957, green: 0.898, blue: 1.000) // #f4e5ff (Highlight siêu sáng)
    static let sakuraDeep = Color(red: 0.627, green: 0.235, blue: 0.980)  // #a03cfa (Tím đậm sâu phát sáng)
    static let petal = Color(red: 0.886, green: 0.706, blue: 1.000)       // #e2b4ff
    static let branch = Color(red: 0.380, green: 0.125, blue: 0.725)      // #6120b9
    static let cardBackground = Color(red: 0.078, green: 0.039, blue: 0.141).opacity(0.82) // Đậm đặc tương phản hơn
    static let cardBorder = Color(red: 0.812, green: 0.478, blue: 1.000).opacity(0.20)     // Viền tím neon sắc sảo
    static let textPrimary = Color(red: 0.984, green: 0.980, blue: 1.000) // #fafaff
    static let textDim = Color(red: 0.741, green: 0.620, blue: 0.980)     // #bd9efa

    // Gradients
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: bgTop, location: 0.0),
                .init(color: bgBottom, location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var textGradient: LinearGradient {
        LinearGradient(
            colors: [sakuraLight, sakura, sakuraDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [sakura, sakuraDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Animated Floating Sakura Petals Background
struct BlossomBackgroundView: View {
    var showParticles: Bool = true

    var body: some View {
        ZStack {
            // Nền tối sẫm gradient hoa anh đào 165 độ
            BlossomTheme.backgroundGradient
                .ignoresSafeArea()

            // Vầng sáng neon mờ tím huyền ảo ở tâm và góc
            Circle()
                .fill(BlossomTheme.sakura.opacity(0.22))
                .blur(radius: 90)
                .frame(width: 330, height: 330)
                .offset(x: -80, y: -220)

            Circle()
                .fill(BlossomTheme.sakuraDeep.opacity(0.18))
                .blur(radius: 110)
                .frame(width: 300, height: 300)
                .offset(x: 100, y: 260)

            // Hiệu ứng hạt cánh hoa anh đào rơi nhẹ nhàng
            if showParticles {
                BlossomPetalParticlesView()
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Petal Particles Component
struct BlossomPetalParticlesView: View {
    @State private var animate = false

    // Tạo tập hạt cố định giả lập hiệu ứng Canvas particles của blossom.re
    private struct PetalParticle: Identifiable {
        let id = UUID()
        let xRatio: CGFloat
        let size: CGFloat
        let opacity: Double
        let duration: Double
        let delay: Double
        let swayAmount: CGFloat
    }

    private let particles: [PetalParticle] = [
        .init(xRatio: 0.12, size: 5.0, opacity: 0.45, duration: 8.5, delay: 0.0, swayAmount: 14),
        .init(xRatio: 0.28, size: 3.5, opacity: 0.35, duration: 11.0, delay: 1.5, swayAmount: -10),
        .init(xRatio: 0.45, size: 6.0, opacity: 0.50, duration: 7.8, delay: 0.8, swayAmount: 18),
        .init(xRatio: 0.62, size: 4.0, opacity: 0.40, duration: 9.2, delay: 2.2, swayAmount: -12),
        .init(xRatio: 0.78, size: 5.5, opacity: 0.42, duration: 8.0, delay: 1.0, swayAmount: 16),
        .init(xRatio: 0.88, size: 3.8, opacity: 0.30, duration: 12.0, delay: 2.8, swayAmount: -15),
        .init(xRatio: 0.20, size: 4.5, opacity: 0.48, duration: 9.8, delay: 3.5, swayAmount: 11),
        .init(xRatio: 0.52, size: 5.2, opacity: 0.52, duration: 7.2, delay: 2.0, swayAmount: -18),
        .init(xRatio: 0.72, size: 3.2, opacity: 0.38, duration: 10.5, delay: 4.0, swayAmount: 13),
        .init(xRatio: 0.94, size: 4.8, opacity: 0.44, duration: 8.8, delay: 1.2, swayAmount: -14)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(BlossomTheme.petal)
                        .frame(width: p.size, height: p.size)
                        .blur(radius: 0.5)
                        .opacity(p.opacity)
                        .offset(
                            x: (geo.size.width * p.xRatio) + (animate ? p.swayAmount : -p.swayAmount),
                            y: animate ? geo.size.height + 20 : -20
                        )
                        .animation(
                            Animation.linear(duration: p.duration)
                                .repeatForever(autoreverses: false)
                                .delay(p.delay),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
    }
}

// MARK: - Animated Conic Rings Around Logo (Chuẩn .brand-icon-ring của blossom.re)
struct BlossomLogoRingView<Content: View>: View {
    let size: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0

    var body: some View {
        ZStack {
            // Vòng quay ngoài 1 (Thuận chiều kim đồng hồ)
            RoundedRectangle(cornerRadius: cornerRadius + 6, style: .continuous)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            BlossomTheme.sakura.opacity(0.85),
                            BlossomTheme.sakuraLight,
                            Color.clear,
                            Color.clear,
                            BlossomTheme.sakuraDeep.opacity(0.6),
                            BlossomTheme.sakura.opacity(0.85)
                        ]),
                        center: .center,
                        startAngle: .degrees(rotation1),
                        endAngle: .degrees(rotation1 + 360)
                    ),
                    lineWidth: 1.8
                )
                .frame(width: size + 16, height: size + 16)
                .blur(radius: 0.5)
                .shadow(color: BlossomTheme.sakura.opacity(0.4), radius: 8)

            // Vòng quay trong 2 (Ngược chiều kim đồng hồ)
            RoundedRectangle(cornerRadius: cornerRadius + 3, style: .continuous)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            BlossomTheme.sakuraLight.opacity(0.9),
                            BlossomTheme.sakura.opacity(0.7),
                            Color.clear,
                            BlossomTheme.petal.opacity(0.5)
                        ]),
                        center: .center,
                        startAngle: .degrees(rotation2),
                        endAngle: .degrees(rotation2 + 360)
                    ),
                    lineWidth: 1.2
                )
                .frame(width: size + 8, height: size + 8)

            // Nội dung logo bên trong
            content()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .onAppear {
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                rotation2 = -360
            }
        }
    }
}

// MARK: - Glassmorphism Card Modifier
struct BlossomCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(BlossomTheme.cardBackground)
            )
            .overlay(
                // Vệt sáng highlight chạy ngang mép đỉnh thẻ (.card::after của blossom.re)
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(BlossomTheme.cardBorder, lineWidth: 1)

                    LinearGradient(
                        colors: [
                            Color.clear,
                            BlossomTheme.sakuraLight.opacity(0.45),
                            BlossomTheme.sakura.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1.5)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 25, y: 12)
            .shadow(color: BlossomTheme.sakura.opacity(0.08), radius: 30)
    }
}

extension View {
    func blossomGlassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(BlossomCardModifier(cornerRadius: cornerRadius))
    }
}
