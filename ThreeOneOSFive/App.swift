import SwiftUI
import UIKit

@main
struct ThreeOneOSFiveApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @StateObject private var patchStore = PatchProjectStore()
    @StateObject private var repositoryStore = PackageRepositoryStore()
    @StateObject private var licenseManager = CheatStoreLicenseManager.shared
    @StateObject private var updateChecker = AppUpdateChecker.shared
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var showOnboarding = false
    @State private var showAttribution = false
    @State private var updateOffer: AppUpdateChecker.Offer?
    @State private var isGameLoaded = false
    @State private var isSplashActive = true
    @State private var mainUIAppeared = false
    @State private var showPostSplashNotice = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        setupLogCapture()
        log("app: CheatStore VN launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild)) \(AppInfo.machineName)")
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    private func checkForUpdate() {
        Task {
            await updateChecker.checkForUpdates()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Khung giao diện chính (Áp dụng hiệu ứng Entrance Transition chuẩn .main-container của blossom.re)
                Group {
                    if licenseManager.isActivated {
                        if isGameLoaded {
                            CheatStoreDashboardView(onBackToGames: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isGameLoaded = false
                                }
                            })
                            .environmentObject(appState)
                            .environmentObject(patchDraftCoordinator)
                            .environmentObject(fileOperationCoordinator)
                            .environmentObject(patchStore)
                            .environmentObject(repositoryStore)
                            .environment(\.appLanguage, language)
                            .environment(\.locale, language.locale)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                        } else {
                            GameSelectionView(onSelectFreeFire: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isGameLoaded = true
                                }
                            })
                            .environmentObject(patchStore)
                            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    } else {
                        CheatStoreLoginView(licenseManager: licenseManager)
                            .zIndex(2)
                    }
                }
                .scaleEffect(mainUIAppeared ? 1.0 : 0.96)
                .offset(y: mainUIAppeared ? 0 : 35)
                .blur(radius: mainUIAppeared ? 0 : 4)
                .opacity(mainUIAppeared ? 1.0 : 0.0)

                // Hiệu ứng Intro Splash Screen chuẩn 100% blossom.re khi vừa ấn icon mở app
                if isSplashActive {
                    BlossomSplashView(onFinished: {
                        withAnimation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 1.2)) {
                            mainUIAppeared = true
                        }
                        withAnimation(.easeOut(duration: 0.6)) {
                            isSplashActive = false
                        }
                        // Hiện thông báo đồng bộ với app sau khi load xong các chữ
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                                showPostSplashNotice = true
                            }
                        }
                    })
                    .zIndex(999)
                    .transition(.opacity)
                }

                // Thông báo CheatStore Vn đồng bộ phong cách xuất hiện sau khi load xong chữ Splash
                if showPostSplashNotice {
                    BlossomNoticeModalView(
                        onDiscord: {
                            if let url = URL(string: "https://discord.gg/A3wS4ZPFQn") {
                                UIApplication.shared.open(url)
                            }
                        },
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showPostSplashNotice = false
                            }
                        }
                    )
                    .zIndex(1000)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.92)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }

                // Popup Cập Nhật Bắt Buộc (OTA) - Chỉ hiện cho các phiên bản cũ và khóa chặt app
                if updateChecker.isForceUpdateRequired, let info = updateChecker.updateInfo {
                    BlossomForceUpdateModalView(info: info)
                        .zIndex(99999)
                        .transition(AnyTransition.opacity)
                }
            }
            .onChange(of: licenseManager.isActivated) { activated in
                if !activated {
                    isGameLoaded = false
                }
            }
            .tint(AppTheme.accent)
            .displayIdentityAttribution(isPresented: $showAttribution, enabled: !showOnboarding)
            .sheet(isPresented: $showAttribution) {
                DisplayAttributionSheet()
            }
            .alert(item: $updateOffer) { offer in
                Alert(
                    title: Text(language.text("update.title")),
                    message: Text(language.text("update.message", offer.version)),
                    primaryButton: .default(Text(language.text("update.agree"))) {
                        UIApplication.shared.open(offer.url)
                    },
                    secondaryButton: .cancel(Text(language.text("update.dismiss"))) {
                        AppUpdateChecker.dismiss(version: offer.version)
                    }
                )
            }
            .onAppear {
                if !showOnboarding {
                    appState.detectSupport()
                    checkForUpdate()
                }
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active, !showOnboarding else { return }
                appState.detectSupport()
                checkForUpdate()
            }
            .onOpenURL { url in
                patchDraftCoordinator.presentImport(url)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?
    @Published var kernelExploitRunning = false

    private var autoRunAttempted = false

    var kernelExploitApplicable: Bool {
        KernelExploit.isApplicable(
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            build: AppInfo.osBuild
        )
    }

    var isSupported: Bool { unsupportedMessage == nil }

    func detectSupport() {
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--simulate-access") {
            exploitStatus = .success(method: "Simulator preview")
        }
#endif

        unsupportedMessage = supported ? nil : "iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))"
        if let unsupportedMessage {
            exploitStatus = .unsupported(unsupportedMessage)
            return
        }

        let applicable = KernelExploit.isApplicable(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
        guard applicable else { return }

        refreshKernelExploitStatus()
        maybeAutoRunKernelExploit()
    }

    private func maybeAutoRunKernelExploit() {
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed,
              !autoRunAttempted else { return }
        autoRunAttempted = true
        log("app: starting kernel exploit automatically")
        runKernelExploitIfNeeded()
    }

    private func refreshKernelExploitStatus() {
        guard !kernelExploitRunning else { return }

        // iOS < 26: kernel R/W success persists (no sandbox probe)
        // iOS >= 26: verify full sandbox escape is still active
        if KernelExploit.requiresSandboxEscape {
            if KernelExploit.hasSandboxAccess() {
                if !exploitStatus.isSuccess {
                    exploitStatus = .success(method: "kexploit")
                    log("app: existing sandbox access is still active; skipping kernel exploit")
                }
            } else if exploitStatus.isSuccess {
                exploitStatus = .notStarted
                log("app: sandbox access is no longer active")
            }
        }
    }

    func runKernelExploitIfNeeded() {
        refreshKernelExploitStatus()
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed else { return }
        kernelExploitRunning = true
        exploitStatus = .notStarted
        log("app: running kernel exploit on background...")
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                if ok {
                    self.exploitStatus = .success(method: "kexploit")
                    if KernelExploit.requiresSandboxEscape {
                        log("app: kernel exploit success — sandbox access verified")
                    } else {
                        log("app: kernel exploit success — kernel access active")
                    }
                } else {
                    self.exploitStatus = .failed(method: "kexploit", code: -1)
                    log("app: kernel exploit failed — relaunch the app before retrying")
                }
            }
        }
    }
}
