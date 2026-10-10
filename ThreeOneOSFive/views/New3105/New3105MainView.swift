import SwiftUI

/// =========================================================================
/// New3105MainView
/// Giao diện chính của ứng dụng 3105-New theo mục 2:
/// - Nền đen toàn màn hình (True Dark AMOLED).
/// - Chữ trắng, điểm nhấn xám, thiết kế tối giản, hiện đại.
/// - Thanh điều hướng 4 Tab dưới cùng: AIM / ESP / MISC / ME.
/// - Nút INJECTOR / UNINJECT nổi bật ở thanh tiêu đề trên cùng.
/// - Giữ nguyên trạng thái cấu hình khi chuyển tab.
/// =========================================================================
public struct New3105MainView: View {
    @StateObject private var configManager = LocalConfigManager.shared
    
    public enum TabSelection: Int, CaseIterable {
        case aim = 0
        case esp = 1
        case misc = 2
        case me = 3
        
        var title: String {
            switch self {
            case .aim: return "AIM"
            case .esp: return "ESP"
            case .misc: return "MISC"
            case .me: return "ME"
            }
        }
        
        var icon: String {
            switch self {
            case .aim: return "scope"
            case .esp: return "viewfinder"
            case .misc: return "slider.horizontal.3"
            case .me: return "person.crop.circle"
            }
        }
    }
    
    @State private var selectedTab: TabSelection = .aim

    public init() {}

    public var body: some View {
        ZStack {
            // Nền đen tuyệt đối AMOLED
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                topNavigationBar

                // Nội dung Tab chính
                TabView(selection: $selectedTab) {
                    New3105AimTabView(configManager: configManager)
                        .tag(TabSelection.aim)

                    New3105EspTabView(configManager: configManager)
                        .tag(TabSelection.esp)

                    New3105MiscTabView(configManager: configManager)
                        .tag(TabSelection.misc)

                    New3105MeTabView(configManager: configManager)
                        .tag(TabSelection.me)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Bottom Tab Bar tối giản chuẩn mục 2
                bottomTabBar
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("3105-New")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text("CONFIG MANAGER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            // Nút INJECTOR / UNINJECT
            New3105InjectorButton(configManager: configManager)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.04))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(white: 0.12)),
            alignment: .bottom
        )
    }

    // MARK: - Bottom Navigation Bar (4 Tabs)
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : Color(white: 0.4))

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .heavy : .medium, design: .monospaced))
                            .foregroundColor(isSelected ? .white : Color(white: 0.4))

                        // Điểm nhấn viền dưới tab được chọn
                        Rectangle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(height: 2)
                            .padding(.horizontal, 12)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                }
            }
        }
        .background(Color(white: 0.05))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(white: 0.15)),
            alignment: .top
        )
    }
}
