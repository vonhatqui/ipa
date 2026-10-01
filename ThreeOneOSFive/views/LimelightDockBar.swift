import SwiftUI
import UIKit

/// Thanh điều hướng Dock Limelight lơ lửng cao cấp (Chuẩn kích thước 56pt, không bị giãn chiều cao)
struct LimelightDockBar: View {
    @Binding var selectedTab: CheatStoreTab
    @ObservedObject var licenseManager: CheatStoreLicenseManager
    @Namespace private var limelightNamespace

    // Theme Black & White LED Glow
    private let ledWhite = Color.white
    private let dockBackground = Color(red: 14/255, green: 14/255, blue: 16/255).opacity(0.96)

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
                                                Color.white.opacity(0.18),
                                                Color.white.opacity(0.06)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                                    )
                                    .shadow(color: Color.white.opacity(0.22), radius: 8, x: 0, y: 0)

                                // Vệt sáng LED rọi dưới chân icon
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 2.5)
                                    .shadow(color: Color.white, radius: 5, x: 0, y: -1)
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
                                            ? Color.white
                                            : Color.white.opacity(0.45)
                                    )
                                    .shadow(color: isSelected ? Color.white.opacity(0.9) : .clear, radius: 8, x: 0, y: 0)
                                    .scaleEffect(isSelected ? 1.06 : 1.0)

                                // Badge trạng thái bảo trì nếu có
                                if (tab == .esp && !licenseManager.featureConfig.esp) || (tab == .skin && !licenseManager.featureConfig.skin) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 6, height: 6)
                                        .shadow(color: Color.orange.opacity(0.8), radius: 3)
                                        .offset(x: 6, y: -2)
                                }

                                // Badge trạng thái Antiban đang bật
                                if tab == .antiban && AntibanProfileService.shared.isAntibanEnabled {
                                    Circle()
                                        .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                                        .frame(width: 6, height: 6)
                                        .shadow(color: Color.green.opacity(0.9), radius: 3)
                                        .offset(x: 6, y: -2)
                                }
                            }
                            .frame(height: 20)

                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.48))
                                .shadow(color: isSelected ? Color.white.opacity(0.55) : .clear, radius: 4)
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

                // Ánh sáng LED trắng dạ quang viền
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
            }
            .shadow(color: Color.black.opacity(0.75), radius: 14, x: 0, y: 6)
            .shadow(color: Color.white.opacity(0.12), radius: 18, x: 0, y: 0)
        )
        .padding(.horizontal, 16)
    }
}
