import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var showCompatList = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 3) {
                            Text("CheatStore VN").font(.headline)
                            Text(language.text("common.version", appVersion))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Nút nhỏ danh sách tương thích CheatStoreVN
                        Button {
                            showCompatList = true
                        } label: {
                            Label("iOS", systemImage: "checkmark.shield.fill")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(appState.isSupported ? Color.green.opacity(0.18) : Color.red.opacity(0.18), in: Capsule())
                                .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                                .overlay(Capsule().stroke(appState.isSupported ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Danh sách tương thích CheatStoreVN")
                    }
                    .padding(.vertical, 4)
                }
                .sheet(isPresented: $showCompatList) {
                    IOSCompatibilityListView()
                }

                Section(language.text("settings.language")) {
                    Picker(language.text("settings.language"), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section {
                    Toggle(isOn: $cleanerEnabled) {
                        Label(language.text("tab.cleaner"), systemImage: "sparkles")
                    }
                    Toggle(isOn: $developerModeEnabled) {
                        Label(
                            language.text("settings.developer_mode"),
                            systemImage: "hammer.fill"
                        )
                    }
                } header: {
                    Text(language.text("dashboard.features"))
                } footer: {
                    Text(language.text("settings.developer_mode_footer"))
                }

                if WallpaperFeatureSupportPolicy.isSupported(
                    major: AppInfo.versionTuple.major
                ) {
                    Section {
                        NavigationLink {
                            WallpaperResetSettingsView()
                        } label: {
                            Label(
                                language.text("wallpaper.reset"),
                                systemImage: "arrow.counterclockwise"
                            )
                        }
                    } header: {
                        Text(language.text("tab.wallpapers"))
                    } footer: {
                        Text(language.text("wallpaper.reset_settings_footer"))
                    }
                }

                Section {
                    AirliftPairingSectionView()
                } header: {
                    Text("Ghép nối thiết bị (iOS 18.7+ / iOS 27+)")
                } footer: {
                    Text("Bật LocalDevVPN hoặc WireGuard (10.7.0.1) trên máy để vượt rào Sandbox trên các phiên bản iOS cao.")
                }

                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                Section {
                    // Trạng thái thiết bị hiện tại
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Label(
                            language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"),
                            systemImage: appState.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }

                    // iOS 17: 17.0 – 17.7.x (tương thích)
                    iosRangeRow(
                        label: "iOS 17",
                        range: ExploitSupportPolicy.verifiedIOS17Range,
                        compatible: true
                    )
                    // iOS 18: 18.0 – 18.7.1 (tương thích)
                    iosRangeRow(
                        label: "iOS 18",
                        range: ExploitSupportPolicy.verifiedIOS18Range,
                        compatible: true
                    )
                    // iOS 18.7.2+: Ghép nối AirLift
                    iosRangeRow(
                        label: "iOS 18.7.2+",
                        range: "Ghép nối (AirLift)",
                        compatible: true
                    )
                    // iOS 19 – 25: không hỗ trợ
                    iosRangeRow(
                        label: "iOS 19–25",
                        range: "Không hỗ trợ",
                        compatible: false
                    )
                    // iOS 26: 26.0 – 26.6.1 (tương thích)
                    iosRangeRow(
                        label: "iOS 26",
                        range: ExploitSupportPolicy.verifiedIOS26Range,
                        compatible: true
                    )
                    // iOS 27 Beta: 27.0 Beta 1–4 (tương thích)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("iOS 27 Beta", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.green)
                            Spacer()
                            Text("27.0 Beta 1–4")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                            Text(versionLabel(version))
                                .font(.caption.monospaced())
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 22)
                        }
                    }
                    .padding(.vertical, 2)

                    // iOS 27 Chính thức: Ghép nối AirLift
                    iosRangeRow(
                        label: "iOS 27 Chính thức",
                        range: "Ghép nối (AirLift)",
                        compatible: true
                    )
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }

                Section(language.text("settings.social_media")) {
                    creditsRow(
                        name: "GitHub",
                        role: language.text("social.github_role"),
                        url: "https://github.com/YangJiiii/3105"
                    )
                    creditsRow(
                        name: "Cộng Đồng IOSVN",
                        role: language.text("social.iosvn_role"),
                        url: "https://t.me/ioscrackvn"
                    )
                }

                Section(language.text("settings.credits")) {
                    creditsRow(
                        name: "YangJiii",
                        role: language.text("credit.yangjiii"),
                        url: "https://x.com/duongduong0908"
                    )
                    creditsRow(
                        name: "0xjohnnydev",
                        role: language.text("credit.filzaslop"),
                        url: "https://github.com/0xjohnnydev/FilzaSlop"
                    )
                    creditsRow(
                        name: "LeminLimez",
                        role: language.text("credit.pocket_poster"),
                        url: "https://github.com/leminlimez/Pocket-Poster"
                    )
                    creditsRow(
                        name: "CrazyMind90",
                        role: language.text("credit.sandbox_escape"),
                        url: "https://github.com/CrazyMind90"
                    )
                    creditsRow(
                        name: "forcequitOS",
                        role: language.text("credit.forcequit"),
                        url: "https://github.com/forcequitOS"
                    )
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(language.text("accessibility.open_profile", name))
        }
    }

    /// Row hiển thị một iOS range với badge tương thích / không tương thích
    @ViewBuilder
    private func iosRangeRow(label: String, range: String, compatible: Bool) -> some View {
        HStack {
            Label(label, systemImage: compatible ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(compatible ? Color.green : Color.red)
            Spacer()
            Text(range)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - IOSCompatibilityListView

/// Sheet hiển thị toàn bộ danh sách iOS tương thích / không tương thích với CheatStoreVN
struct IOSCompatibilityListView: View {
    @Environment(\.dismiss) private var dismiss

    private let rows: [(label: String, range: String, compatible: Bool)] = [
        ("iOS 17.0–17.7.x",   "Tương thích",          true),
        ("iOS 18.0–18.7.1",   "Tương thích",          true),
        ("iOS 18.7.2–18.8",   "Ghép nối (AirLift)",   true),
        ("iOS 19–25",         "Không hỗ trợ",         false),
        ("iOS 26.0–26.6.1",   "Tương thích",          true),
        ("iOS 27.0 Beta 1–4", "Tương thích",          true),
        ("iOS 27 Chính thức", "Ghép nối (AirLift)",   true),
        ("iOS 28+",           "Ghép nối (AirLift)",   true)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rows, id: \.label) { row in
                        HStack {
                            Label(row.label, systemImage: row.compatible ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(row.compatible ? Color.green : Color.red)
                                .font(.subheadline)
                            Spacer()
                            Text(row.range)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Danh sách tương thích CheatStoreVN")
                } footer: {
                    Text("Dựa trên exploit 3105 của YangJiii. Chỉ các phiên bản được liệt kê mới được hỗ trợ.")
                }
            }
            .navigationTitle("Tương thích iOS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
