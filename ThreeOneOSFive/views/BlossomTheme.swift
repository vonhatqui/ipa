import SwiftUI

// MARK: - 0xCheats Luxury Theme Tokens (Dark Obsidian & Electric Cyan)
enum BlossomTheme {
    // Colors - Deep Void Obsidian & Electric Cyan
    static let bgTop = Color(red: 0.045, green: 0.052, blue: 0.072)       // #0b0d12
    static let bgBottom = Color(red: 0.015, green: 0.018, blue: 0.025)    // #040506
    static let sakura = Color(red: 0.00, green: 0.72, blue: 1.00)         // #00b8ff Electric Cyan
    static let sakuraLight = Color(red: 0.45, green: 0.88, blue: 1.00)    // #73e0ff Ice Glow
    static let sakuraDeep = Color(red: 0.08, green: 0.42, blue: 0.95)     // #146bf2 Royal Cobalt
    static let petal = Color(red: 0.25, green: 0.75, blue: 1.00)
    static let branch = Color(red: 0.12, green: 0.28, blue: 0.55)
    static let cardBackground = Color(red: 0.075, green: 0.085, blue: 0.115).opacity(0.88)
    static let cardBorder = Color(red: 0.00, green: 0.72, blue: 1.00).opacity(0.24)
    static let textPrimary = Color(red: 0.96, green: 0.97, blue: 1.00)
    static let textDim = Color(red: 0.58, green: 0.65, blue: 0.78)

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

// MARK: - 0xCheats Ambient Luxury Spotlight Background
struct BlossomBackgroundView: View {
    var showParticles: Bool = true

    var body: some View {
        ZStack {
            // Nền tối sẫm không gian sâu
            BlossomTheme.backgroundGradient
                .ignoresSafeArea()

            // Vầng sáng spotlight cyan ở đỉnh trên
            Circle()
                .fill(Color(red: 0.0, green: 0.72, blue: 1.0).opacity(0.14))
                .blur(radius: 95)
                .frame(width: 320, height: 320)
                .offset(x: -60, y: -200)

            // Vầng sáng cobalt huyền ảo ở góc dưới
            Circle()
                .fill(Color(red: 0.08, green: 0.42, blue: 0.95).opacity(0.12))
                .blur(radius: 110)
                .frame(width: 290, height: 290)
                .offset(x: 90, y: 240)
        }
    }
}

// MARK: - Animated Conic Rings Around Logo (Chuẩn 0xCheats Luxury Cyan Glow)
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
                .shadow(color: BlossomTheme.sakura.opacity(0.35), radius: 8)

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
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
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
                // Vệt sáng highlight chạy ngang mép đỉnh thẻ
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


// Backward compatibility helper
struct BlossomPetalParticlesView: View {
    var body: some View {
        EmptyView()
    }
}
