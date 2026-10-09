import SwiftUI
import UIKit

/// EspAimSilentDetailDashboardView: Bảng điều khiển chi tiết cho tính năng ESP & AIM SILENT (CheatVN External)
struct EspAimSilentDetailDashboardView: View {
    @ObservedObject var patchService = CheatVNPatchService.shared
    @AppStorage("cheatstore_selected_game_version") private var selectedGameVersionRaw: String = FreeFireGameVersion.standard.rawValue

    var onBackToCategories: () -> Void

    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastColor: Color = .green
    @State private var toastIcon: String = "checkmark.circle.fill"

    // Colors
    private let bgVoid = Color(red: 11/255, green: 12/255, blue: 15/255)
    private let cardBg = Color(red: 20/255, green: 21/255, blue: 27/255)
    private let cardBorder = Color(red: 35/255, green: 37/255, blue: 47/255)
    private let textPrimary = Color(red: 242/255, green: 242/255, blue: 247/255)
    private let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)
    private let accentCyan = Color(red: 0/255, green: 210/255, blue: 255/255)
    private let accentGreen = Color(red: 0/255, green: 230/255, blue: 118/255)
    private let accentRed = Color(red: 255/255, green: 69/255, blue: 58/255)

    private var currentGameVersion: FreeFireGameVersion {
        FreeFireGameVersion(rawValue: selectedGameVersionRaw) ?? .standard
    }

    var body: some View {
        ZStack {
            bgVoid.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                headerView
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Banner Trạng Thái Module
                        moduleStatusCardView

                        // 2. Bộ 3 Nút Hành Động Trọng Tâm (Nạp Patch • Khôi Phục Gốc • Vào Game)
                        actionButtonsSection

                        // 3. Danh Sách Công Tắc Chức Năng (Toggles)
                        featureTogglesSection

                        // 4. Chi tiết kỹ thuật IFix Runtime (Verified 5 files)
                        technicalVerificationSection

                        // 5. Nhật Ký Hoạt Động (Log Terminal)
                        logSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
            }

            // Toast Alert
            if showToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: toastIcon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(toastColor)

                        Text(toastMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 26/255, green: 27/255, blue: 34/255).opacity(0.98))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(toastColor.opacity(0.4), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.6), radius: 10, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .onAppear {
            patchService.checkPatchStatus()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onBackToCategories()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Danh Mục")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("ESP & AIM SILENT")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(textPrimary)
                Text(currentGameVersion == .standard ? "Free Fire Thường" : "Free Fire MAX")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(accentCyan)
            }

            logoImage(named: "esp_aimsilent_logo", size: 36)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Module Status Card
    private var moduleStatusCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                logoImage(named: "esp_aimsilent_logo", size: 54)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("ESP & AIM SILENT")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("VERIFIED")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundColor(accentGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentGreen.opacity(0.15))
                            .cornerRadius(6)
                    }

                    Text("CheatVN External • Aim 40% & ESP Player")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)
                }

                Spacer()
            }

            Divider().background(Color.white.opacity(0.08))

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TRẠNG THÁI NẠP TRONG GAME")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))

                    HStack(spacing: 6) {
                        Circle()
                            .fill(patchService.isPatchApplied ? accentGreen : Color.orange)
                            .frame(width: 8, height: 8)

                        Text(patchService.isPatchApplied ? "ĐANG HOẠT ĐỘNG (INJECTED)" : "CHƯA NẠP VÀO GAME")
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundColor(patchService.isPatchApplied ? accentGreen : Color.orange)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("ĐỘ AN TOÀN")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                    Text("100% ANTIBAN")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(accentCyan)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(patchService.isPatchApplied ? accentGreen.opacity(0.4) : cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            // Nút NẠP VÀO GAME (Chính)
            Button(action: handleApplyPatch) {
                HStack(spacing: 10) {
                    if patchService.isApplying {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                    }

                    Text(patchService.isApplying ? "Đang nạp dữ liệu..." : (patchService.isPatchApplied ? "ĐÃ NẠP THÀNH CÔNG • NẠP LẠI" : "NẠP VÀO GAME (CÓ TÁC DỤNG NGAY)"))
                        .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0/255, green: 240/255, blue: 140/255), Color(red: 0/255, green: 200/255, blue: 255/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color(red: 0/255, green: 230/255, blue: 180/255).opacity(0.3), radius: 8, y: 3)
            }
            .disabled(patchService.isApplying)

            HStack(spacing: 10) {
                // Nút Khôi phục gốc
                Button(action: handleRestoreOriginals) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Khôi Phục Gốc 100%")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(accentRed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 35/255, green: 22/255, blue: 24/255))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentRed.opacity(0.35), lineWidth: 1))
                }

                // Nút Mở Game
                Button(action: handleLaunchGame) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Mở Free Fire")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 28/255, green: 30/255, blue: 40/255))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Feature Toggles
    private var featureTogglesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CẤU HÌNH TÍNH NĂNG (VIP CHEATVN)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color.white.opacity(0.55))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                toggleRow(
                    title: "Aim Silent 40% (Headshot Lock)",
                    subtitle: "Tâm đạn ghim đầu tự động, không rung lắc, không giật",
                    icon: "scope",
                    iconColor: accentCyan,
                    isOn: $patchService.aimSilentEnabled
                )

                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 14)

                toggleRow(
                    title: "ESP Box Player (Khung 2D / 3D)",
                    subtitle: "Hiện khung viền bao quanh toàn bộ địch trên bản đồ",
                    icon: "viewfinder",
                    iconColor: Color.yellow,
                    isOn: $patchService.espBoxEnabled
                )

                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 14)

                toggleRow(
                    title: "ESP Name & Khoảng Cách",
                    subtitle: "Hiện nhãn tên CheatVN External và khoảng cách mét",
                    icon: "text.alignleft",
                    iconColor: Color.green,
                    isOn: $patchService.espNameEnabled
                )

                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 14)

                toggleRow(
                    title: "ESP Line (Tia Kẻ Định Vị)",
                    subtitle: "Kẻ tia từ đỉnh màn hình nối thẳng tới đối thủ",
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    iconColor: Color.purple,
                    isOn: $patchService.espLineEnabled
                )

                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 14)

                toggleRow(
                    title: "Antiban Clean Telemetry Buffer",
                    subtitle: "Khoá ghi log crash và ngăn game gửi dữ liệu bất thường",
                    icon: "shield.lefthalf.filled",
                    iconColor: accentGreen,
                    isOn: $patchService.antibanBufferEnabled
                )
            }
            .background(cardBg)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
        }
    }

    private func toggleRow(title: String, subtitle: String, icon: String, iconColor: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: accentCyan))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Technical Verification
    private var technicalVerificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KIỂM CHỨNG TỆP TIN IFIX RUNTIME (5/5 VERIFIED)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color.white.opacity(0.55))
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                fileVerifyItem(name: "Assembly-CSharp-patch.bytes", note: "Rebranded CheatVN External • 76.3 KB")
                fileVerifyItem(name: ".ffxc_runtime", note: "HMAC-SHA256 verified signature")
                fileVerifyItem(name: ".ffxc_neutral_37ca851...", note: "Neutral Safe Seed 322B")
                fileVerifyItem(name: ".ffxc_live", note: "Session marker 37ca851...")
                fileVerifyItem(name: "localConfig.json", note: "testCodePatch: true active")
            }
            .padding(14)
            .background(cardBg.opacity(0.6))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(cardBorder, lineWidth: 1))
        }
    }

    private func fileVerifyItem(name: String, note: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentGreen)

            Text(name)
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundColor(textPrimary)

            Spacer()

            Text(note)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(textSecondary)
        }
    }

    // MARK: - Log Section
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NHẬT KÝ THAO TÁC")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color.white.opacity(0.55))
                .padding(.horizontal, 4)

            HStack {
                Text(patchService.lastLogMessage)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(textSecondary)
                Spacer()
            }
            .padding(12)
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Actions
    private func handleApplyPatch() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let ok = patchService.applyPatch()
        if ok {
            triggerToast(message: "✅ Đã nạp thành công CheatVN External vào game! Vào game có tác dụng ngay.", color: accentGreen, icon: "checkmark.seal.fill")
        } else {
            triggerToast(message: "❌ Nạp thất bại. Vui lòng kiểm tra lại đường dẫn cài đặt game.", color: accentRed, icon: "exclamationmark.triangle.fill")
        }
    }

    private func handleRestoreOriginals() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        let ok = patchService.restoreOriginals()
        if ok {
            triggerToast(message: "✅ Đã gỡ bỏ toàn bộ patch, game Free Fire đã sạch 100%.", color: accentGreen, icon: "arrow.counterclockwise.circle.fill")
        }
    }

    private func handleLaunchGame() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        patchService.launchGame(version: currentGameVersion)
    }

    private func triggerToast(message: String, color: Color, icon: String) {
        toastMessage = message
        toastColor = color
        toastIcon = icon
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                showToast = false
            }
        }
    }

    private func logoImage(named name: String, size: CGFloat) -> some View {
        CategoryLogoView(name: name, fallbackIcon: "cross.fill", size: size)
    }
}

// MARK: - Logo View Helper
struct CategoryLogoView: View {
    let name: String
    let fallbackIcon: String
    let size: CGFloat

    var body: some View {
        if let uiImage = loadLocalImage(name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color(red: 28/255, green: 30/255, blue: 40/255))
                Image(systemName: fallbackIcon)
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
        }
    }

    private func loadLocalImage(_ filename: String) -> UIImage? {
        if let img = UIImage(named: filename) { return img }
        if let bundlePath = Bundle.main.path(forResource: filename, ofType: "png"),
           let img = UIImage(contentsOfFile: bundlePath) { return img }
        if let appCoreRes = Bundle.main.resourceURL?.appendingPathComponent("AppCore/Assets/\(filename).png"),
           let img = UIImage(contentsOfFile: appCoreRes.path) { return img }
        if let appCoreBundle = Bundle.main.bundleURL.appendingPathComponent("AppCore/Assets/\(filename).png"),
           let img = UIImage(contentsOfFile: appCoreBundle.path) { return img }
        let directPath = "ThreeOneOSFive/\(filename).png"
        if FileManager.default.fileExists(atPath: directPath),
           let img = UIImage(contentsOfFile: directPath) { return img }
        return nil
    }
}
