import SwiftUI
import UIKit

/// Thanh điều hướng Dock Limelight lơ lửng cao cấp (Chuẩn kích thước 56pt, không bị giãn chiều cao)
struct LimelightDockBar: View {
    @Binding var selectedTab: CheatStoreTab
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @Namespace private var limelightNamespace

    // Multi-Brand Dynamic Theme (CheatStore VN, VeLix VN, Venom VN)
    private var theme: AppBrandingTheme { AppBrandingTheme.current }
    private var ledColor: Color { theme.dockLedColor }
    private var highlightColor: Color { theme.dockHighlightColor }
    private var secondaryColor: Color { theme.dockSecondaryColor }
    private var dockBackground: Color { theme.dockBackground }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CheatStoreTab.allCases, id: \.self) { tab in
                let isSelected = (selectedTab == tab)

                Button {
                    guard selectedTab != tab else { return }
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        // Vệt sáng dạ quang Limelight trượt theo tab (Matched Geometry)
                        if isSelected {
                            ZStack(alignment: .bottom) {
                                // Vầng sáng dạ quang nền tab active
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                ledColor.opacity(0.24),
                                                secondaryColor.opacity(0.08)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(ledColor.opacity(0.40), lineWidth: 1)
                                    )
                                    .shadow(color: ledColor.opacity(0.32), radius: 8, x: 0, y: 0)

                                // Vệt sáng LED rọi dưới chân icon
                                Capsule()
                                    .fill(highlightColor)
                                    .frame(width: 22, height: 2.5)
                                    .shadow(color: ledColor, radius: 6, x: 0, y: -1)
                                    .padding(.bottom, 3)
                            }
                            .frame(height: 48)
                            .matchedGeometryEffect(id: "DOCK_LIMELIGHT_BAR", in: limelightNamespace)
                        }

                        // Nội dung Icon & Tiêu đề
                        VStack(spacing: 2) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: isSelected ? 17.5 : 16, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(
                                        isSelected
                                            ? highlightColor
                                            : Color.white.opacity(0.45)
                                    )
                                    .shadow(color: isSelected ? ledColor.opacity(0.85) : .clear, radius: 8, x: 0, y: 0)
                                    .scaleEffect(isSelected ? 1.06 : 1.0)

                                // Tab icon
                            }
                            .frame(height: 20)

                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? highlightColor : Color.white.opacity(0.48))
                                .shadow(color: isSelected ? ledColor.opacity(0.55) : .clear, radius: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            ZStack {
                // Kính mờ siêu mượt Blur Material
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(dockBackground)

                // Ánh sáng LED rực rỡ dạ quang viền theo chủ đề
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: theme.dockBorderGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
            }
            .shadow(color: Color.black.opacity(0.75), radius: 14, x: 0, y: 6)
            .shadow(color: ledColor.opacity(0.20), radius: 18, x: 0, y: 0)
        )
        .padding(.horizontal, 16)
    }
}
