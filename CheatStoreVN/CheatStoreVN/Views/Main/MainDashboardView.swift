import SwiftUI

public struct MainDashboardView: View {
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
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                topNavigationBar

                // Tab Content View
                TabView(selection: $selectedTab) {
                    AimTabView(configManager: configManager)
                        .tag(TabSelection.aim)

                    EspTabView(configManager: configManager)
                        .tag(TabSelection.esp)

                    MiscTabView(configManager: configManager)
                        .tag(TabSelection.misc)

                    MeTabView(configManager: configManager)
                        .tag(TabSelection.me)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Thanh ngang INJETTOR nổi bật toàn màn hình nằm trên Tab Bar
                InjectorBarButton(configManager: configManager)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .background(Color(white: 0.04))

                // Bottom Tab Bar
                bottomTabBar
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(alignment: .center, spacing: 10) {
            CheatStoreLogoView(size: 32, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("CHEATSTORE VN")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                Text("EXTERNAL CONFIG MANAGER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Server Indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(AppTheme.successGreen)
                    .frame(width: 6, height: 6)
                Text("ONLINE")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(white: 0.12))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.22), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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

                        Rectangle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(height: 2)
                            .padding(.horizontal, 14)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                }
            }
        }
        .background(Color(white: 0.04))
    }
}
