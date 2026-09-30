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

// MARK: - Purple Matrix Digital Rain & Floating Glyphs Component ("Hiệu ứng matrix bay bay full màu tím")
struct PurpleMatrixRainView: View {
    @State private var animate = false

    private struct MatrixStream: Identifiable {
        let id: Int
        let xRatio: CGFloat
        let characters: [String]
        let fontSize: CGFloat
        let duration: Double
        let delay: Double
        let opacity: Double
    }

    private struct FloatingGlyph: Identifiable {
        let id: Int
        let char: String
        let xRatio: CGFloat
        let yStart: CGFloat
        let size: CGFloat
        let duration: Double
        let delay: Double
        let opacity: Double
    }

    private let streams: [MatrixStream] = [
        .init(id: 0, xRatio: 0.03, characters: ["0", "1", "X", "7", "Z", "A", "9", "F"], fontSize: 11, duration: 6.2, delay: 0.0, opacity: 0.70),
        .init(id: 1, xRatio: 0.07, characters: ["ｱ", "ｳ", "ｴ", "3", "1", "0", "5", "ﾜ"], fontSize: 12, duration: 7.8, delay: 1.2, opacity: 0.75),
        .init(id: 2, xRatio: 0.12, characters: ["F", "F", "M", "A", "X", "1", "0", "8", "X"], fontSize: 10, duration: 5.5, delay: 0.6, opacity: 0.60),
        .init(id: 3, xRatio: 0.16, characters: ["ｶ", "ｷ", "ｹ", "8", "4", "F", "C", "9"], fontSize: 13, duration: 8.5, delay: 2.0, opacity: 0.80),
        .init(id: 4, xRatio: 0.21, characters: ["1", "0", "1", "1", "0", "1", "0", "1", "1"], fontSize: 11, duration: 6.8, delay: 0.3, opacity: 0.65),
        .init(id: 5, xRatio: 0.25, characters: ["ｻ", "ｼ", "ｽ", "V", "E", "L", "I", "X"], fontSize: 12, duration: 6.0, delay: 1.5, opacity: 0.72),
        .init(id: 6, xRatio: 0.30, characters: ["A", "I", "M", "B", "O", "T", "9", "9", "Z"], fontSize: 11, duration: 8.2, delay: 2.4, opacity: 0.68),
        .init(id: 7, xRatio: 0.35, characters: ["E", "S", "P", "B", "O", "X", "1", "2"], fontSize: 12, duration: 5.3, delay: 0.4, opacity: 0.75),
        .init(id: 8, xRatio: 0.39, characters: ["ﾀ", "ﾂ", "ﾃ", "3", "1", "0", "5", "Z"], fontSize: 10, duration: 7.5, delay: 1.0, opacity: 0.62),
        .init(id: 9, xRatio: 0.44, characters: ["0", "X", "F", "F", "2", "8", "4", "A", "9"], fontSize: 13, duration: 8.8, delay: 2.8, opacity: 0.80),
        .init(id: 10, xRatio: 0.49, characters: ["ﾊ", "ﾋ", "ﾎ", "N", "E", "O", "N", "V"], fontSize: 11, duration: 6.5, delay: 0.8, opacity: 0.70),
        .init(id: 11, xRatio: 0.53, characters: ["1", "1", "0", "0", "1", "0", "1", "0"], fontSize: 12, duration: 7.6, delay: 1.8, opacity: 0.65),
        .init(id: 12, xRatio: 0.58, characters: ["ﾏ", "ﾐ", "ﾑ", "C", "O", "R", "E", "1", "0"], fontSize: 11, duration: 5.7, delay: 1.3, opacity: 0.72),
        .init(id: 13, xRatio: 0.62, characters: ["V", "I", "P", "7", "7", "7", "X", "0"], fontSize: 12, duration: 7.2, delay: 0.2, opacity: 0.78),
        .init(id: 14, xRatio: 0.67, characters: ["ﾗ", "ﾘ", "ﾙ", "H", "E", "A", "D", "8"], fontSize: 11, duration: 6.9, delay: 2.2, opacity: 0.68),
        .init(id: 15, xRatio: 0.71, characters: ["0", "1", "0", "X", "M", "A", "T", "R", "I", "X"], fontSize: 12, duration: 8.0, delay: 1.6, opacity: 0.74),
        .init(id: 16, xRatio: 0.76, characters: ["S", "I", "L", "E", "N", "T", "9", "9"], fontSize: 10, duration: 5.8, delay: 0.5, opacity: 0.62),
        .init(id: 17, xRatio: 0.80, characters: ["ﾅ", "ﾆ", "ﾇ", "3", "1", "0", "5", "P"], fontSize: 13, duration: 8.6, delay: 2.5, opacity: 0.82),
        .init(id: 18, xRatio: 0.85, characters: ["R", "E", "C", "O", "I", "L", "0", "0"], fontSize: 11, duration: 6.3, delay: 0.9, opacity: 0.70),
        .init(id: 19, xRatio: 0.89, characters: ["ｷ", "ｮ", "ｳ", "F", "I", "X", "2", "8"], fontSize: 12, duration: 7.4, delay: 1.9, opacity: 0.75),
        .init(id: 20, xRatio: 0.93, characters: ["0", "1", "1", "0", "F", "F", "3", "1"], fontSize: 10, duration: 5.6, delay: 0.7, opacity: 0.65),
        .init(id: 21, xRatio: 0.97, characters: ["V", "I", "O", "L", "E", "T", "9", "X"], fontSize: 12, duration: 8.3, delay: 2.1, opacity: 0.76)
    ]

    // Các ký tự Matrix lơ lửng bay bay (Matrix Flying Embers)
    private let floatingGlyphs: [FloatingGlyph] = [
        .init(id: 0, char: "0", xRatio: 0.08, yStart: 0.85, size: 14, duration: 6.5, delay: 0.0, opacity: 0.55),
        .init(id: 1, char: "1", xRatio: 0.22, yStart: 0.70, size: 16, duration: 7.2, delay: 1.2, opacity: 0.65),
        .init(id: 2, char: "ｱ", xRatio: 0.38, yStart: 0.90, size: 13, duration: 8.0, delay: 0.5, opacity: 0.50),
        .init(id: 3, char: "X", xRatio: 0.52, yStart: 0.75, size: 15, duration: 6.8, delay: 2.0, opacity: 0.60),
        .init(id: 4, char: "9", xRatio: 0.65, yStart: 0.80, size: 12, duration: 7.5, delay: 0.8, opacity: 0.55),
        .init(id: 5, char: "ｶ", xRatio: 0.82, yStart: 0.65, size: 14, duration: 8.2, delay: 1.5, opacity: 0.60),
        .init(id: 6, char: "0", xRatio: 0.91, yStart: 0.88, size: 16, duration: 6.0, delay: 0.3, opacity: 0.70),
        .init(id: 7, char: "1", xRatio: 0.15, yStart: 0.60, size: 13, duration: 7.8, delay: 2.5, opacity: 0.45),
        .init(id: 8, char: "V", xRatio: 0.44, yStart: 0.82, size: 15, duration: 7.0, delay: 1.8, opacity: 0.58),
        .init(id: 9, char: "P", xRatio: 0.74, yStart: 0.72, size: 14, duration: 6.7, delay: 0.9, opacity: 0.62)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Lớp 1: Dòng thác số Matrix Neon Tím đổ dọc
                ForEach(streams) { stream in
                    VStack(spacing: 3) {
                        ForEach(0..<stream.characters.count, id: \.self) { idx in
                            let char = stream.characters[idx]
                            let isHead = (idx == stream.characters.count - 1)

                            Text(char)
                                .font(.system(size: stream.fontSize, weight: isHead ? .black : .bold, design: .monospaced))
                                .foregroundColor(
                                    isHead
                                        ? Color(red: 0.98, green: 0.90, blue: 1.0)
                                        : Color(red: 0.80, green: 0.40, blue: 1.0).opacity(Double(idx + 1) / Double(stream.characters.count))
                                )
                                .shadow(
                                    color: isHead
                                        ? Color(red: 0.95, green: 0.55, blue: 1.0).opacity(0.95)
                                        : Color(red: 0.70, green: 0.25, blue: 0.98).opacity(0.45),
                                    radius: isHead ? 7 : 2
                                )
                        }
                    }
                    .opacity(stream.opacity)
                    .position(
                        x: geo.size.width * stream.xRatio,
                        y: animate ? geo.size.height + 160 : -160
                    )
                    .animation(
                        Animation.linear(duration: stream.duration)
                            .repeatForever(autoreverses: false)
                            .delay(stream.delay),
                        value: animate
                    )
                }

                // Lớp 2: Ký tự Matrix bay bay lơ lửng full màu tím (Matrix Floating Glyphs)
                ForEach(floatingGlyphs) { g in
                    Text(g.char)
                        .font(.system(size: g.size, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.88, green: 0.52, blue: 1.0))
                        .shadow(color: Color(red: 0.80, green: 0.35, blue: 1.0).opacity(0.85), radius: 5)
                        .opacity(g.opacity)
                        .position(
                            x: geo.size.width * g.xRatio,
                            y: animate ? (geo.size.height * g.yStart) - 180 : (geo.size.height * g.yStart) + 120
                        )
                        .animation(
                            Animation.easeInOut(duration: g.duration)
                                .repeatForever(autoreverses: true)
                                .delay(g.delay),
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

// MARK: - Petal Particles Component
struct BlossomPetalParticlesView: View {
    @State private var animate = false

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
