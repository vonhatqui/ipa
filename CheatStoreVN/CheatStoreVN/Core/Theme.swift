import SwiftUI

// MARK: - App Design System & Colors
public struct AppTheme {
    public static let background = Color.black
    public static let cardBackground = Color(red: 0.07, green: 0.07, blue: 0.08)
    public static let cardSecondary = Color(red: 0.10, green: 0.10, blue: 0.12)
    public static let cardBorder = Color(white: 0.18)
    public static let cardBorderFocused = Color(white: 0.35)
    
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.60)
    public static let textMuted = Color(white: 0.38)
    
    public static let accent = Color.white
    public static let successGreen = Color(red: 0.19, green: 0.82, blue: 0.35)
    public static let dangerRed = Color(red: 0.90, green: 0.22, blue: 0.22)
    public static let warningYellow = Color(red: 0.95, green: 0.77, blue: 0.25)
    public static let infoBlue = Color(red: 0.20, green: 0.55, blue: 0.95)
}

// MARK: - Logo View Component
public struct CheatStoreLogoView: View {
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(size: CGFloat = 36, cornerRadius: CGFloat = 8) {
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            if let uiImage = UIImage(named: "CheatStoreLogo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let bundleImage = loadLogoFromBundle() {
                Image(uiImage: bundleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(white: 0.12)
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: size * 0.55, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(white: 0.25), lineWidth: 1)
        )
    }
    
    private func loadLogoFromBundle() -> UIImage? {
        if let path = Bundle.main.path(forResource: "CheatStoreLogo", ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}
