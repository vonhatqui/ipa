import SwiftUI
import UIKit

public struct HyperXRootView: View {
    @ObservedObject var authManager = HyperXAuthManager.shared
    @ObservedObject var injectionManager = HyperXInjectionManager.shared
    @Environment(\.appLanguage) private var language

    @State private var selectedTab: Int = 0
    @State private var filesSession = FilesTabSession()
    @State private var showSettings = false
    @State private var showLogs = false

    public init() {}

    public var body: some View {
        Group {
            if !authManager.isAuthenticated {
                HyperXLoginView()
                    .transition(.opacity)
            } else {
                mainTabStructure
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
        .tint(Color(red: 0.14, green: 0.42, blue: 0.96))
        .onAppear {
            Task {
                await authManager.autoValidateSavedKey()
            }
        }
    }

    // MARK: - 3 TABS: MAIN - TỆP - CÁ NHÂN

    private var mainTabStructure: some View {
        TabView(selection: $selectedTab) {
            // TAB 1: MAIN (LOADER -> CHECKBOXES -> INJECTOR -> UNINJECT)
            HyperXMainView()
                .tabItem {
                    Label("Main", systemImage: "house.fill")
                }
                .tag(0)

            // TAB 2: TỆP (DỮ LIỆU ỨNG DỤNG TRÊN ĐIỆN THOẠI CỦA 3105)
            AppDataBrowserView(
                tabSession: $filesSession,
                onOpenSettings: { showSettings = true },
                onOpenLogs: { showLogs = true }
            )
            .tabItem {
                Label("Tệp", systemImage: "folder.fill")
            }
            .tag(1)

            // TAB 3: CÁ NHÂN (THỜI GIAN KEY, PHIÊN BẢN IOS, THIẾT BỊ, HWID)
            HyperXProfileView()
                .tabItem {
                    Label("Cá Nhân", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
    }
}
