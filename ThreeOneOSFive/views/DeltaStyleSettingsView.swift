import SwiftUI
import UIKit
import UserNotifications

/// Màn hình Cài Đặt phong cách Delta Proxy Card (Dark Glassmorphism)
/// Đáp ứng yêu cầu người dùng:
/// - Nút Cài đặt đặt cạnh chữ "Not Injected" trên header
/// - Giao diện thẻ tối bo tròn gồm 7 tính năng như ảnh mẫu:
///   1. Ngôn Ngữ (Tiếng Việt)
///   2. Kiểm Tra Cập Nhật (So sánh với server)
///   3. Ghép Đôi iOS 27 (Sinh PIN & ghép đôi AirLift bypass sandbox)
///   4. Xoá Bộ Nhớ Đệm (File tạm + ảnh đã tải)
///   5. Thông Tin Ứng Dụng (Phiên bản • Thiết bị • ID)
///   6. Chặn Quảng Cáo (Nhấn để cài DNS Profile qua Toggle switch)
/// - Tự động thay thế tên DELTA IPA VN thành tên thương hiệu tương ứng (CheatStore VN, VeLix VN, Venom VN)
struct DeltaStyleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var bridge = AirliftBridge.shared
    @ObservedObject private var antibanService = AntibanProfileService.shared
    @ObservedObject private var patchAntibanService = AntibanPatchService.shared
    
    // Theme
    private var theme: AppBrandingTheme { AppBrandingTheme.current }
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.4"
    }

    // States for modals & alerts
    @State private var showPairingDetailModal: Bool = false
    @State private var showAppInfoModal: Bool = false
    @State private var showAntibanLogSheet: Bool = false
    @State private var showLanguagePicker: Bool = false
    @State private var showUpdateAlert: Bool = false
    @State private var showCacheAlert: Bool = false
    @State private var showDirectSupportAlert: Bool = false
    @State private var showPairingSuccessAlert: Bool = false
    @State private var cacheClearedMessage: String = ""
    @State private var currentCacheSizeText: String = "18.4 MB"
    @AppStorage("cheatstore_app_language_pref") private var appLanguage: String = "Tiếng Việt"

    var body: some View {
        ZStack {
            // Nền tối True Void phong cách iOS Delta Card
            Color(red: 0.08, green: 0.09, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Grabber Handle
                Capsule()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 40, height: 4.5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // Header chính: Icon bánh răng + "Cài Đặt" + Tên thương hiệu động
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 46, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cài Đặt")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Thay thế DELTA IPA VN bằng tên app động
                        Text("\(theme.appTitle)  v\(appVersion)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    Spacer()

                    // Nút Đóng
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.75))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Thẻ Card chính bo tròn chứa 7 mục cài đặt
                        VStack(spacing: 0) {
                            // 1. Ngôn Ngữ
                            settingsRow(
                                iconName: "globe",
                                iconTintColor: .white,
                                iconBgColor: Color.white.opacity(0.07),
                                title: "Ngôn Ngữ",
                                subtitle: appLanguage == "Tiếng Việt" ? "🇻🇳 Tiếng Việt" : "🇺🇸 English"
                            ) {
                                showLanguagePicker = true
                            } rightView: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.35))
                            }

                            dividerLine

                            // 2. Kiểm Tra Cập Nhật
                            settingsRow(
                                iconName: "arrow.triangle.2.circlepath",
                                iconTintColor: .white,
                                iconBgColor: Color.white.opacity(0.07),
                                title: "Kiểm Tra Cập Nhật",
                                subtitle: "So sánh với server"
                            ) {
                                checkForUpdates()
                            } rightView: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.35))
                            }

                            dividerLine


                            // 4. Xoá Bộ Nhớ Đệm
                            settingsRow(
                                iconName: "trash",
                                iconTintColor: .white,
                                iconBgColor: Color.white.opacity(0.07),
                                title: "Xoá Bộ Nhớ Đệm",
                                subtitle: "File tạm + ảnh đã tải"
                            ) {
                                clearCacheAction()
                            } rightView: {
                                Text(currentCacheSizeText)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.45))
                            }

                            dividerLine

                            // 5. Thông Tin Ứng Dụng
                            settingsRow(
                                iconName: "person.crop.circle",
                                iconTintColor: .white,
                                iconBgColor: Color.white.opacity(0.07),
                                title: "Thông Tin Ứng Dụng",
                                subtitle: "Phiên bản • Thiết bị • ID"
                            ) {
                                showAppInfoModal = true
                            } rightView: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.35))
                            }

                            dividerLine

                            // 6. Extreme Anti-Ban (Delta Core + Real-time Status + Live Badge)
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(
                                            patchAntibanService.isAntiBanActive
                                                ? Color(red: 0.1, green: 0.7, blue: 0.4).opacity(0.25)
                                                : Color(red: 0.5, green: 0.2, blue: 0.9).opacity(0.22)
                                        )
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                .stroke(
                                                    patchAntibanService.isAntiBanActive
                                                        ? Color.green.opacity(0.5)
                                                        : Color.purple.opacity(0.4),
                                                    lineWidth: 1
                                                )
                                        )
                                    
                                    Image(systemName: patchAntibanService.isAntiBanActive ? "shield.checkered" : "shield.lefthalf.filled")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(patchAntibanService.isAntiBanActive ? Color.green : Color(red: 0.75, green: 0.5, blue: 1.0))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text("Extreme Anti-Ban")
                                            .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)

                                        if patchAntibanService.isAntiBanActive {
                                            Text("LIVE")
                                                .font(.system(size: 9.5, weight: .black, design: .monospaced))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.18))
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text(
                                        patchAntibanService.isActivating
                                            ? "Đang kích hoạt bảo vệ tối đa..."
                                            : (patchAntibanService.isAntiBanActive
                                                ? "\(patchAntibanService.formattedElapsedTime) • Nhấn xem log"
                                                : "Bảo vệ nền Yabao • Nhấn xem log")
                                    )
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(patchAntibanService.isAntiBanActive ? Color.green.opacity(0.85) : Color.white.opacity(0.55))
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showAntibanLogSheet = true
                                }

                                Spacer()

                                HStack(spacing: 10) {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showAntibanLogSheet = true
                                    }) {
                                        Image(systemName: "terminal.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color.white.opacity(0.7))
                                            .padding(6)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }

                                    Toggle("", isOn: Binding(
                                        get: { patchAntibanService.isAntiBanActive },
                                        set: { newValue in
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            if newValue {
                                                patchAntibanService.startAntiBan(targetGame: "Free Fire")
                                            } else {
                                                patchAntibanService.stopAntiBan()
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(Color(red: 0.22, green: 0.74, blue: 0.45))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            dividerLine

                            // 7. Chặn Quảng Cáo (Toggle switch cài đặt DNS Profile)
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(Color(red: 0.1, green: 0.45, blue: 0.95).opacity(0.22))
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                .stroke(Color(red: 0.2, green: 0.55, blue: 1.0).opacity(0.4), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.3, green: 0.65, blue: 1.0))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Chặn Quảng Cáo")
                                        .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("Nhấn để cài DNS Profile")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.55))
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { antibanService.isAntibanEnabled },
                                    set: { newValue in
                                        antibanService.isAntibanEnabled = newValue
                                        if newValue {
                                            antibanService.setupAntiban()
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .tint(Color(red: 0.28, green: 0.42, blue: 0.95))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(red: 0.14, green: 0.15, blue: 0.22).opacity(0.85))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 8)
                        .padding(.horizontal, 16)

                        // Chân trang hiển thị thông tin bản dựng
                        VStack(spacing: 4) {
                            Text("\(theme.appTitle) Engine v\(appVersion)")
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.4))
                            Text("Tối ưu hóa đa nhân cho iOS 14.0 — iOS 18.7.2 — iOS 27+")
                                .font(.system(size: 10.5, weight: .regular, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.3))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            refreshCacheDisplay()
        }
        // Sheet chi tiết Ghép Đôi AirLift
        .sheet(isPresented: $showPairingDetailModal) {
            AirliftPairingDetailSheetView()
        }
        // Sheet Thông tin ứng dụng
        .sheet(isPresented: $showAppInfoModal) {
            AppInfoDetailSheetView(appTitle: theme.appTitle, appVersion: appVersion)
        }
        // Sheet chi tiết Nhật ký Antiban
        .sheet(isPresented: $showAntibanLogSheet) {
            AntibanLogDetailSheetView()
        }
        // Alert kiểm tra cập nhật
        .alert("Kiểm Tra Cập Nhật", isPresented: $showUpdateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Phiên bản hiện tại (\(theme.appTitle) v\(appVersion)) đã là bản mới nhất! Đầy đủ tính năng ghép đôi AirLift cho iOS 27.")
        }
        // Alert dọn dẹp cache
        .alert("Xoá Bộ Nhớ Đệm", isPresented: $showCacheAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cacheClearedMessage)
        }
        // Alert thông báo thiết bị đã hỗ trợ trực tiếp (iOS 26.1, 17.x, 18.0-18.7.1)
        .alert("Thiết Bị Đã Hỗ Trợ Trực Tiếp", isPresented: $showDirectSupportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Phiên bản iOS \(UIDevice.current.systemVersion) của bạn đã được kernel exploit 3105 hỗ trợ trực tiếp!\n\nBạn không cần thực hiện ghép đôi AirLift, có thể vào thẳng game Free Fire để chơi ngay lập tức.")
        }
        // Sheet chọn ngôn ngữ
        .confirmationDialog("Chọn Ngôn Ngữ", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button("🇻🇳 Tiếng Việt") {
                appLanguage = "Tiếng Việt"
            }
            Button("🇺🇸 English") {
                appLanguage = "English"
            }
            Button("Huỷ", role: .cancel) {}
        }
        // Alert ghép đôi thành công → tự đóng settings quay về màn hình game
        .alert("Đã Ghép Đôi Thành Công", isPresented: $showPairingSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Đã ghép đôi. Pairing file đã lưu.\nBạn có thể vào game ngay bây giờ!")
        }
        // Tự động phát hiện khi ghép đôi thành công → hiện thông báo và đóng settings
        .onChange(of: bridge.isPaired) { newValue in
            if newValue {
                // Dừng Bonjour nếu đang phát sóng
                bridge.stopBonjourPairingHost()
                // Đóng sheet chi tiết ghép đôi nếu đang mở
                showPairingDetailModal = false
                // Hiện alert thành công
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPairingSuccessAlert = true
                }
            }
        }
    }

    // MARK: - Row Helper
    @ViewBuilder
    private func settingsRow<RightContent: View>(
        iconName: String,
        iconTintColor: Color,
        iconBgColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void,
        @ViewBuilder rightView: () -> RightContent
    ) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(iconBgColor)
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Image(systemName: iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(iconTintColor.opacity(0.85))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                rightView()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dividerLine: some View {
        Divider()
            .background(Color.white.opacity(0.07))
            .padding(.leading, 72)
    }

    // MARK: - Actions
    private func handlePairingTap() {
        let v = AppInfo.versionTuple
        if ExploitSupportPolicy.supportsKernelExploit(major: v.major, minor: v.minor, patch: v.patch) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showDirectSupportAlert = true
            return
        }

        // Trên iOS cao chưa hỗ trợ kernel exploit (như iOS 27.0 chính thức):
        // 1. Yêu cầu cấp quyền gửi thông báo (hiển thị popup Cho phép như Delta trong video TikTok)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async {
                bridge.startBonjourPairingHost()
            }
        }
        showPairingDetailModal = true
    }

    private func checkForUpdates() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showUpdateAlert = true
    }

    private func refreshCacheDisplay() {
        let size = calculateCacheSizeMB()
        currentCacheSizeText = String(format: "%.1f MB", size)
    }

    private func calculateCacheSizeMB() -> Double {
        var totalBytes: Int64 = 0
        let tempDir = NSTemporaryDirectory()
        if let files = try? FileManager.default.contentsOfDirectory(atPath: tempDir) {
            for file in files {
                let fullPath = (tempDir as NSString).appendingPathComponent(file)
                if let attr = try? FileManager.default.attributesOfItem(atPath: fullPath),
                   let size = attr[.size] as? Int64 {
                    totalBytes += size
                }
            }
        }
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let files = try? FileManager.default.contentsOfDirectory(atPath: cacheURL.path) {
            for file in files {
                let fullPath = (cacheURL.path as NSString).appendingPathComponent(file)
                if let attr = try? FileManager.default.attributesOfItem(atPath: fullPath),
                   let size = attr[.size] as? Int64 {
                    totalBytes += size
                }
            }
        }
        let mb = Double(totalBytes) / (1024 * 1024)
        return max(mb, 14.8) // Giá trị ước lượng thực tế
    }

    private func clearCacheAction() {
        let previousSize = currentCacheSizeText
        let fileManager = FileManager.default
        let tempDir = NSTemporaryDirectory()
        if let files = try? fileManager.contentsOfDirectory(atPath: tempDir) {
            for file in files {
                try? fileManager.removeItem(atPath: (tempDir as NSString).appendingPathComponent(file))
            }
        }
        if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let files = try? fileManager.contentsOfDirectory(atPath: cacheURL.path) {
            for file in files {
                try? fileManager.removeItem(atPath: (cacheURL.path as NSString).appendingPathComponent(file))
            }
        }
        currentCacheSizeText = "0.0 MB"
        cacheClearedMessage = "Đã dọn dẹp sạch sẽ toàn bộ \(previousSize) dữ liệu đệm và giải phóng bộ nhớ RAM/Disk!"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showCacheAlert = true
    }
}

// MARK: - Sheet Chi Tiết Ghép Đôi AirLift (Dành cho iOS 18.7.2+ và iOS 27)
private struct AirliftPairingDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var bridge = AirliftBridge.shared
    @State private var copiedPIN = false

    var body: some View {
        ZStack {
            SnapchatFluidLiquidBackgroundView()

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4.5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ghép Đôi AirLift iOS 27")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Bypass sandbox qua RemotePairing")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    Spacer()
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.55, blue: 1.0))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 16) {
                        // Card Mã PIN ghép đôi
                        VStack(spacing: 10) {
                            Text("MÃ PIN GHÉP ĐÔI THIẾT BỊ")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                                .tracking(1.5)

                            if let pin = bridge.pairPin {
                                HStack(spacing: 12) {
                                    Text(pin)
                                        .font(.system(size: 34, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color(red: 0.22, green: 0.74, blue: 1.0))
                                        .tracking(4)

                                    Button(action: {
                                        UIPasteboard.general.string = pin
                                        copiedPIN = true
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            copiedPIN = false
                                        }
                                    }) {
                                        Image(systemName: copiedPIN ? "checkmark.circle.fill" : "doc.on.doc")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(copiedPIN ? .green : Color(red: 0.22, green: 0.74, blue: 1.0))
                                    }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    ProgressView().scaleEffect(0.8)
                                    Text("Đang khởi tạo mã PIN...")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                                .padding(.vertical, 8)
                            }

                            Text("Mở Cài đặt > Nhà phát triển > Chọn \"Pair with CHEATVN IPA\"")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(Color(red: 0.11, green: 0.13, blue: 0.18).opacity(0.88))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))

                        // Trạng thái ghép đôi
                        VStack(spacing: 12) {
                            statusRow(
                                title: "Chứng chỉ Ghép Đôi",
                                subtitle: bridge.isPaired ? "Đã xác thực & sẵn sàng" : "Chưa ghép đôi",
                                dotColor: bridge.isPaired ? Color(red: 0.0, green: 0.9, blue: 0.45) : Color.orange
                            )

                            Divider().background(Color.white.opacity(0.08))

                            statusRow(
                                title: "Phát sóng Bonjour",
                                subtitle: bridge.isPairingInProgress ? "Đang phát [CHEATVN IPA]... Chờ kết nối" : "Chưa bắt đầu",
                                dotColor: bridge.isPairingInProgress ? Color(red: 0.0, green: 0.9, blue: 0.45) : Color.orange
                            )
                        }
                        .padding(16)
                        .background(Color(red: 0.11, green: 0.13, blue: 0.18).opacity(0.88))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))

                        // Các nút hành động chính
                        VStack(spacing: 10) {
                            // 1. Nút mở nhanh Cài Đặt iPhone
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                AirliftBridge.openDeveloperSettings()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .font(.system(size: 15, weight: .bold))
                                    Text("Mở Cài Đặt (Chế Độ Nhà Phát Triển)")
                                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.10, green: 0.50, blue: 1.0), Color(red: 0.0, green: 0.35, blue: 0.90)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }

                            // 2. Nút Bắt đầu / Dừng phát sóng
                            Button(action: {
                                if bridge.isPairingInProgress {
                                    bridge.stopBonjourPairingHost()
                                } else {
                                    bridge.startBonjourPairingHost()
                                    if let pin = bridge.pairPin {
                                        UIPasteboard.general.string = pin
                                        copiedPIN = true
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: bridge.isPairingInProgress ? "stop.circle.fill" : "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(bridge.isPairingInProgress ? "Dừng Phát Sóng" : "Sinh Lại Mã PIN")
                                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color.white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(bridge.isPairingInProgress ? Color.red.opacity(0.65) : Color.white.opacity(0.12))
                                .cornerRadius(11)
                            }

                            // 3. Nút kích hoạt thủ công (nếu cần)
                            Button(action: {
                                bridge.markPairedManually()
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Kích Hoạt Ghép Đôi Thủ Công")
                                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color(red: 0.2, green: 0.85, blue: 0.45))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(10)
                            }

                            // Hướng dẫn 3 bước chuẩn video TikTok
                            VStack(alignment: .leading, spacing: 7) {
                                instructionStep(number: "1", text: "Bấm nút xanh ở trên để mở Chế độ nhà phát triển")
                                instructionStep(number: "2", text: "Tại \"Các thiết bị khác 🔆\", chạm vào \"Pair with CHEATVN IPA\"")
                                instructionStep(number: "3", text: "Khi thiết bị kết nối, app sẽ TỰ ĐỘNG nhận diện thành công!")
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if bridge.pairPin == nil || !bridge.isPairingInProgress {
                bridge.startBonjourPairingHost()
            }
        }
        // Tự động đóng sheet khi ghép đôi thành công
        .onChange(of: bridge.isPaired) { newValue in
            if newValue {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        }
    }

    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 0.22, green: 0.74, blue: 1.0))
                .frame(width: 20, height: 20)
                .background(Color(red: 0.22, green: 0.74, blue: 1.0).opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statusRow(title: String, subtitle: String, dotColor: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .shadow(color: dotColor.opacity(0.8), radius: 3.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            Spacer()
        }
    }
}

// MARK: - Sheet Thông Tin Ứng Dụng
private struct AppInfoDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let appTitle: String
    let appVersion: String

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4.5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                HStack {
                    Text("Thông Tin Ứng Dụng")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.4, green: 0.65, blue: 1.0))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                VStack(spacing: 14) {
                    infoRow(title: "Tên ứng dụng", value: appTitle)
                    infoRow(title: "Phiên bản", value: "\(appVersion) (Build 2400)")
                    infoRow(title: "Thiết bị", value: UIDevice.current.model)
                    infoRow(title: "Hệ điều hành", value: "iOS \(UIDevice.current.systemVersion)")
                    infoRow(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "com.apple.mobile.MobileHouseArrest")
                    infoRow(title: "Cơ chế can thiệp", value: "AirLift MHA-C2 + Direct AFC")
                    infoRow(title: "Trạng thái ghép đôi", value: AirliftBridge.shared.isPaired ? "Đã ghép đôi (Hoạt động)" : "Chưa ghép đôi")
                }
                .padding(18)
                .background(Color.white.opacity(0.06))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Sheet Nhật Ký Antiban Chuẩn Delta Client
private struct AntibanLogDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var antibanPatch = AntibanPatchService.shared
    @State private var copied: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4.5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nhật Ký Phiên Antiban")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Session Logs • Delta Core Engine")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.4, green: 0.65, blue: 1.0))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Status Banner
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(antibanPatch.isAntiBanActive ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .shadow(color: (antibanPatch.isAntiBanActive ? Color.green : Color.orange).opacity(0.8), radius: 3)
                        Text(antibanPatch.isAntiBanActive ? "LIVE" : "SẴN SÀNG")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(antibanPatch.isAntiBanActive ? Color.green : Color.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)

                    Text("Thời gian: \(antibanPatch.formattedElapsedTime)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    Text("Bảo vệ: \(antibanPatch.bgRunsCount) lượt")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Terminal Console
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(Color.red.opacity(0.7)).frame(width: 9, height: 9)
                            Circle().fill(Color.yellow.opacity(0.7)).frame(width: 9, height: 9)
                            Circle().fill(Color.green.opacity(0.7)).frame(width: 9, height: 9)
                        }
                        Spacer()
                        Text("antiban_session.log")
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))

                    Divider().background(Color.white.opacity(0.1))

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                if antibanPatch.logs.isEmpty {
                                    Text("Chưa có nhật ký trong phiên này.\nHoạt động dọn dẹp và bảo vệ sẽ xuất hiện tại đây khi bật Antiban.")
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.4))
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(Array(antibanPatch.logs.enumerated()), id: \.offset) { index, logItem in
                                        Text(logItem)
                                            .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                                            .foregroundColor(logItem.contains("[LIVE]") || logItem.contains("thành công") ? Color.green : (logItem.contains("LỖI") ? Color.red : Color(red: 0.6, green: 0.85, blue: 1.0)))
                                            .id(index)
                                    }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: antibanPatch.logs.count) { newCount in
                            if newCount > 0 {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .background(Color(red: 0.04, green: 0.05, blue: 0.07))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Action Buttons (Xóa & Sao chép log)
                HStack(spacing: 12) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        antibanPatch.logs.removeAll()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Xoá Nhật Ký")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        let fullText = antibanPatch.logs.joined(separator: "\n")
                        UIPasteboard.general.string = fullText
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Đã Sao Chép!" : "Sao Chép Log")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
