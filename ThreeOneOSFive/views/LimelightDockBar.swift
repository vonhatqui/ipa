import SwiftUI
import UIKit

/// Thanh điều hướng Dock Limelight lơ lửng cao cấp (Chuẩn kích thước 56pt, không bị giãn chiều cao)
struct LimelightDockBar: View {
    @Binding var selectedTab: CheatStoreTab
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @Namespace private var limelightNamespace

    // Theme Blossom Dark Sakura
    private let brandSakura = BlossomTheme.sakura
    private let brandSakuraLight = BlossomTheme.sakuraLight
    private let brandSakuraDeep = BlossomTheme.sakuraDeep
    private let dockBackground = Color(red: 0.065, green: 0.035, blue: 0.115).opacity(0.94)

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
                                                brandSakuraDeep.opacity(0.42),
                                                brandSakura.opacity(0.20)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: brandSakura.opacity(0.55), radius: 8, x: 0, y: 0)

                                // Vệt sáng đèn rọi dưới chân icon
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [brandSakuraLight, brandSakura],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 22, height: 3)
                                    .shadow(color: brandSakuraLight, radius: 4, x: 0, y: -1)
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
                                            ? LinearGradient(colors: [Color.white, brandSakuraLight], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .shadow(color: isSelected ? brandSakura.opacity(0.85) : .clear, radius: 6, x: 0, y: 0)
                                    .scaleEffect(isSelected ? 1.06 : 1.0)

                                // Badge trạng thái bảo trì nếu có
                                if (tab == .esp && !licenseManager.featureConfig.esp) || (tab == .skin && !licenseManager.featureConfig.skin) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 6, height: 6)
                                        .shadow(color: Color.orange.opacity(0.8), radius: 3)
                                        .offset(x: 6, y: -2)
                                }
                            }
                            .frame(height: 20)

                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.48))
                                .shadow(color: isSelected ? brandSakura.opacity(0.4) : .clear, radius: 3)
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

                // Ánh sáng tím sâu dạ quang viền
                RoundedRectangle(cornerRadius: 22, style: .continuous)
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
                        lineWidth: 1.1
                    )
            }
            .shadow(color: Color.black.opacity(0.65), radius: 14, x: 0, y: 6)
            .shadow(color: brandSakuraDeep.opacity(0.2), radius: 18, x: 0, y: 0)
        )
        .padding(.horizontal, 16)
    }
}
