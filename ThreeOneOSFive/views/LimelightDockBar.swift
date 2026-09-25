import SwiftUI
import UIKit

/// Thanh điều hướng Dock Limelight lơ lửng cao cấp (Tái tạo 100% limelight-nav.js từ bản IPA)
struct LimelightDockBar: View {
    @Binding var selectedTab: CheatStoreTab
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @Namespace private var limelightNamespace

    // Theme Blossom Dark Sakura
    private let brandSakura = BlossomTheme.sakura
    private let brandSakuraLight = BlossomTheme.sakuraLight
    private let brandSakuraDeep = BlossomTheme.sakuraDeep
    private let dockBackground = Color(red: 0.065, green: 0.035, blue: 0.115).opacity(0.92)

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CheatStoreTab.allCases, id: \.self) { tab in
                let isSelected = (selectedTab == tab)

                Button {
                    guard selectedTab != tab else { return }
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        // Vệt sáng dạ quang Limelight trượt theo tab (Matched Geometry)
                        if isSelected {
                            ZStack {
                                // Vầng sáng dạ quang tỏa nền
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                brandSakuraDeep.opacity(0.42),
                                                brandSakura.opacity(0.20)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: brandSakura.opacity(0.55), radius: 10, x: 0, y: 0)

                                // Vệt sáng đèn rọi chiếu ngược lên icon (Spotlight beam)
                                VStack {
                                    Spacer()
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [brandSakuraLight, brandSakura],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 24, height: 3)
                                        .shadow(color: brandSakuraLight, radius: 4, x: 0, y: -1)
                                        .padding(.bottom, 3)
                                }
                            }
                            .matchedGeometryEffect(id: "DOCK_LIMELIGHT_BAR", in: limelightNamespace)
                        }

                        // Nội dung Icon & Tiêu đề
                        VStack(spacing: 3) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: isSelected ? 18.5 : 17, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(
                                        isSelected
                                            ? LinearGradient(colors: [Color.white, brandSakuraLight], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .shadow(color: isSelected ? brandSakura.opacity(0.85) : .clear, radius: 8, x: 0, y: 0)
                                    .scaleEffect(isSelected ? 1.08 : 1.0)

                                // Badge trạng thái bảo trì nếu có
                                if (tab == .esp && !licenseManager.featureConfig.esp) || (tab == .skin && !licenseManager.featureConfig.skin) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 6.5, height: 6.5)
                                        .shadow(color: Color.orange.opacity(0.8), radius: 3)
                                        .offset(x: 7, y: -2)
                                }
                            }
                            .frame(height: 22)

                            Text(tab.title)
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.48))
                                .shadow(color: isSelected ? brandSakura.opacity(0.5) : .clear, radius: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            ZStack {
                // Kính mờ siêu mượt Blur Material
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(dockBackground)

                // Ánh sáng tím sâu dạ quang viền
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                brandSakura.opacity(0.35),
                                brandSakuraDeep.opacity(0.18),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .shadow(color: Color.black.opacity(0.65), radius: 18, x: 0, y: 8)
            .shadow(color: brandSakuraDeep.opacity(0.22), radius: 24, x: 0, y: 0)
        )
        .padding(.horizontal, 18)
    }
}
