import SwiftUI
import UIKit

/// ExternalCheat1706View: Giao diện Menu chi tiết tái hiện chuẩn 100% phong cách "1706 Cheat (FFExternal)"
/// Bao gồm đầy đủ các nhóm FOV & Aimbot, ESP Visuals, Movement & Combat, Game Picker và Action Button
public struct ExternalCheat1706View: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = Cheat1706Settings.shared
    @StateObject private var antibanService = AntibanPatchService.shared

    // Trạng thái thao tác
    @State private var isInjecting: Bool = false
    @State private var showSuccessToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastColor: Color = .green

    // Bảng màu chuẩn phong cách 1706 Dark Neon & Obsidian
    private let bgVoid = Color(red: 9/255, green: 10/255, blue: 15/255)
    private let cardBg = Color(red: 17/255, green: 19/255, blue: 27/255).opacity(0.88)
    private let cardBorder = Color.white.opacity(0.08)
    private let accentNeon = Color(red: 0/255, green: 140/255, blue: 255/255)       // Electric Blue 1706
    private let accentCyan = Color(red: 0/255, green: 225/255, blue: 255/255)       // Cyan Neon
    private let accentGreen = Color(red: 34/255, green: 197/255, blue: 94/255)      // Emerald Active
    private let textMute = Color(red: 140/255, green: 145/255, blue: 165/255)

    public init() {}

    public var body: some View {
        ZStack {
            // Nền đen sâu Obsidian với vầng sáng Gradient tinh tế
            bgVoid.ignoresSafeArea()

            RadialGradient(
                colors: [accentNeon.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Top Navigation Bar
                navBarHeaderView

                // 2. Nội dung cuộn chính
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Thẻ bản quyền VIP & License Status
                        licenseCardView

                        // Bộ chọn phiên bản game (Free Fire / FF MAX)
                        gameSelectorPillView

                        // Mục 1: FOV & AIMBOT
                        fovAimbotSectionView

                        // Mục 2: ESP VISUALS
                        espSectionView

                        // Mục 3: MOVEMENT & COMBAT
                        movementCombatSectionView

                        // Mục 4: STREAMPROOF & AN TOÀN
                        streamproofSectionView

                        // Nút khôi phục mặc định
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            settings.resetToDefaults()
                            showToast("Đã đặt lại toàn bộ cài đặt mặc định 1706!", color: .orange)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Đặt lại cấu hình mặc định")
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(textMute)
                            .padding(.vertical, 8)
                        }

                        Spacer().frame(height: 110) // Khoảng trống cho thanh nút bấm ghim dưới
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }

            // 3. Nút hành động Ghim dưới đáy (Bottom Action Bar)
            VStack {
                Spacer()
                bottomInjectActionBar
            }
            .ignoresSafeArea(edges: .bottom)

            // 4. Toast thông báo trạng thái
            if showSuccessToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(toastColor)
                            .font(.system(size: 18, weight: .bold))
                        Text(toastMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color(red: 22/255, green: 24/255, blue: 34/255))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(toastColor.opacity(0.4), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.6), radius: 16, y: 6)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }

    // MARK: - 1. Navigation Bar
    private var navBarHeaderView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [accentNeon, accentCyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Text("17")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("1706 EXTERNAL")
                        .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)
                    Text("Cheat Engine v1.0.0 (MHA-C2)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(textMute)
                }
            }

            Spacer()

            // Nút đóng
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(red: 12/255, green: 13/255, blue: 18/255).opacity(0.95))
        .overlay(Divider().background(Color.white.opacity(0.08)), alignment: .bottom)
    }

    // MARK: - 2. License Card
    private var licenseCardView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accentGreen)
                        .frame(width: 8, height: 8)
                        .shadow(color: accentGreen, radius: 4)
                    Text("VIP LICENSE ACTIVE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(accentGreen)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(accentGreen.opacity(0.12))
                .cornerRadius(999)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text("29 Ngày 23 Giờ")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color.white.opacity(0.75))
            }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MÃ BẢN QUYỀN (HWID LOCKED)")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textMute)
                    Text("1706-VIP-9988-****-PASS")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "shield.checkmark.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentNeon)
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - 3. Game Selector Pill
    private var gameSelectorPillView: some View {
        HStack(spacing: 8) {
            gameButton(idx: 0, title: "Free Fire Thường", icon: "flame.fill")
            gameButton(idx: 1, title: "Free Fire MAX", icon: "bolt.fill")
        }
    }

    private func gameButton(idx: Int, title: String, icon: String) -> some View {
        let isSelected = settings.selectedGameIndex == idx
        return Button(action: {
            UIImpactFeedbackGenerator(style: .selection).impactOccurred()
            settings.selectedGameIndex = idx
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                LinearGradient(colors: [accentNeon, Color(red: 0/255, green: 100/255, blue: 220/255)], startPoint: .top, endPoint: .bottom) :
                LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(isSelected ? .white : textMute)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentCyan.opacity(0.4) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    // MARK: - 4. Section 1: FOV & AIMBOT
    private var fovAimbotSectionView: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "FOV & AIMBOT", icon: "scope", badge: "HOT")

            VStack(spacing: 14) {
                toggleRow(title: "Aimbot Tự Động", sub: "Khóa mục tiêu khi khai hỏa", isOn: $settings.aimbot)
                toggleRow(title: "AimSilent (Đạn Đuổi Kín)", sub: "Đạn bẻ cong âm thầm trúng địch", isOn: $settings.aimSilent)

                // Vị trí khóa ngắm
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vị trí ưu tiên ngắm")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Picker("Target", selection: $settings.aimbotTargetRaw) {
                        Text("🎯 Đầu (Head)").tag(0)
                        Text("🎯 Cổ (Neck)").tag(1)
                        Text("🎯 Ngực (Chest)").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                sliderRow(title: "Độ chuẩn xác (Aimbot Strength)", value: $settings.aimbotStrength, range: 30...100, unit: "%")
                sliderRow(title: "Tỷ lệ Headshot (Headshot Rate)", value: $settings.headshotRate, range: 50...100, unit: "%")

                Divider().background(Color.white.opacity(0.06))

                toggleRow(title: "Vòng tròn FOV Circle", sub: "Hiển thị bán kính kích hoạt ngắm", isOn: $settings.fovCircle)
                if settings.fovCircle {
                    sliderRow(title: "Bán kính vòng ngắm (FOV Radius)", value: $settings.fovRadius, range: 40...360, unit: "px")
                }

                toggleRow(title: "Bỏ qua kẻ địch gục (Ignore Knocked)", sub: "Ưu tiên địch còn sống", isOn: $settings.ignoreKnocked)
                toggleRow(title: "Chỉ ngắm khi thấy địch (Visible Only)", sub: "Chống bắn vào tường rào", isOn: $settings.visibleOnly)
                toggleRow(title: "Đường kẻ chỉ hướng (Target Line)", sub: "Vẽ tia laser từ tâm tới mục tiêu", isOn: $settings.targetLine)
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - 5. Section 2: ESP VISUALS
    private var espSectionView: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "ESP VISUALS (XUYÊN TƯỜNG)", icon: "eye.fill", badge: "ACTIVE")

            VStack(spacing: 14) {
                toggleRow(title: "Box ESP (Hộp khung chữ nhật)", sub: "Bao quanh vị trí đối thủ", isOn: $settings.espBox)
                toggleRow(title: "Skeleton ESP (Bộ xương 3D)", sub: "Vẽ khung xương khớp người", isOn: $settings.espSkeleton)
                toggleRow(title: "Line ESP (Dây định vị)", sub: "Tia nối từ mép màn hình đến địch", isOn: $settings.espLine)
                toggleRow(title: "Health Bar (Thanh máu)", sub: "Hiển thị chỉ số HP đối phương", isOn: $settings.espHealth)
                toggleRow(title: "Name ESP (Tên người chơi)", sub: "Hiện tên tài khoản kẻ địch", isOn: $settings.espName)
                toggleRow(title: "Distance Tag (Khoảng cách mét)", sub: "Đo cự ly chính xác tới mục tiêu", isOn: $settings.espDistance)

                Divider().background(Color.white.opacity(0.06))

                toggleRow(title: "Enemy Counter (Đếm số địch xung quanh)", sub: "Cảnh báo số lượng kẻ địch lân cận", isOn: $settings.enemyCounter)
                toggleRow(title: "Cảnh báo 360° (Radar 360 Alert)", sub: "Hiện mũi tên khi có địch áp sát sau lưng", isOn: $settings.enemyAlert360)
                if settings.enemyAlert360 {
                    sliderRow(title: "Bán kính phát hiện địch", value: $settings.enemyAlertRange, range: 50...300, unit: "m")
                }
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - 6. Section 3: MOVEMENT & COMBAT
    private var movementCombatSectionView: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "MOVEMENT & COMBAT", icon: "bolt.badge.clock.fill", badge: "144 FPS")

            VStack(spacing: 14) {
                toggleRow(title: "Tốc biến chạy nhanh (Speed Hack)", sub: "Tăng tốc độ di chuyển nhân vật", isOn: $settings.speedHack)
                if settings.speedHack {
                    sliderRow(title: "Hệ số tăng tốc (Multiplier)", value: $settings.speedMultiplier, range: 1.1...2.5, unit: "x", step: 0.1)
                }

                toggleRow(title: "Tốc độ sấy đạn (Fast Fire)", sub: "Tối đa hóa tốc độ nhả đạn", isOn: $settings.fastFire)
                toggleRow(title: "Chống giật súng (No Recoil)", sub: "Đạn bắn thẳng tâm không rung giật", isOn: $settings.noRecoil)
                toggleRow(title: "Tốc độ đạn tức thì (Bullet Speed)", sub: "Đạn trúng đích không có độ trễ bay", isOn: $settings.bulletSpeed)
                toggleRow(title: "Mở khóa 144 FPS Mượt mà", sub: "Mở khóa giới hạn khung hình iOS", isOn: $settings.fps144)
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - 7. Section 4: STREAMPROOF
    private var streamproofSectionView: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "STREAMPROOF & AN TOÀN", icon: "video.badge.checkmark", badge: "BYPASS")

            VStack(spacing: 14) {
                toggleRow(title: "Ẩn ESP khi Quay video / Live Stream", sub: "Bảo vệ tài khoản an toàn khi quay màn hình", isOn: $settings.streamproof)

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(accentGreen)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bảo Vệ Antiban Yabao 322B")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Tự động trung hòa seed đĩa chống quét sau khi nạp")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(textMute)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - 8. Bottom Action Bar (Ghim dưới đáy)
    private var bottomInjectActionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Nút Khôi Phục Gốc (Clean)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    handleCleanGame()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.shield.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("KHÔI PHỤC")
                            .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.85))
                    .frame(width: 130, height: 52)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }

                // Nút Áp Dụng Cấu Hình & Nạp (INJECT)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    handleApplyAndInject()
                }) {
                    HStack(spacing: 8) {
                        if isInjecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16, weight: .black))
                        }

                        Text(isInjecting ? "ĐANG NẠP..." : "ÁP DỤNG CẤU HÌNH (INJECT)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [accentNeon, Color(red: 0/255, green: 90/255, blue: 230/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: accentNeon.opacity(0.4), radius: 10, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accentCyan.opacity(0.6), lineWidth: 1)
                    )
                }
                .disabled(isInjecting)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color(red: 11/255, green: 12/255, blue: 17/255)
                .opacity(0.96)
                .ignoresSafeArea()
        )
        .overlay(Divider().background(Color.white.opacity(0.08)), alignment: .top)
    }

    // MARK: - Logic Nạp cấu hình vào game
    private func handleApplyAndInject() {
        guard !isInjecting else { return }
        isInjecting = true

        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Tạo file localConfig.json từ toàn bộ các Toggle & Slider
            let configData = self.settings.generateLocalConfigData()
            let bundleID = self.settings.selectedGameBundleID
            let fileManager = FileManager.default

            // 2. Nạp dữ liệu vào Container của Game (Documents/localConfig.json)
            let allContainers = DevicePatchService.allAvailableFreeFireContainers()
            for (id, root) in allContainers where id == bundleID || bundleID.isEmpty {
                let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
                let dstConfig = docDir.appendingPathComponent("localConfig.json")
                try? fileManager.removeItem(at: dstConfig)
                try? configData.write(to: dstConfig, options: .atomic)
                try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstConfig.path)
            }

            // 3. Đảm bảo file mã gốc Assembly-CSharp-patch.bytes được đồng bộ
            DevicePatchService.ensureActivePatchesInjected()

            // 4. Kích hoạt lớp trung hòa Antiban Yabao
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.antibanService.executeTimedAntibanFlow(bundleID: bundleID)

                self.isInjecting = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.showToast("Đã áp dụng cấu hình 1706 thành công vào \(self.settings.selectedGameDisplayName)!", color: self.accentGreen)
            }
        }
    }

    // MARK: - Logic Khôi phục sạch sẽ
    private func handleCleanGame() {
        _ = DevicePatchService.cleanRestoreAllModifications()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Đã khôi phục game \(settings.selectedGameDisplayName) về trạng thái sạch sẽ!", color: .orange)
    }

    private func showToast(_ msg: String, color: Color) {
        toastMessage = msg
        toastColor = color
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuccessToast = false
            }
        }
    }

    // MARK: - Helper UI Components
    private func sectionHeader(title: String, icon: String, badge: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accentNeon)

            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(0.5)

            Spacer()

            Text(badge)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundColor(accentCyan)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(accentCyan.opacity(0.12))
                .cornerRadius(6)
        }
    }

    private func toggleRow(title: String, sub: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(textMute)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: accentNeon))
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, step: Double? = nil) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.85))
                Spacer()
                Text(step != nil ? String(format: "%.1f %@", value.wrappedValue, unit) : "\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(accentCyan)
            }

            if let step = step {
                Slider(value: value, in: range, step: step)
                    .accentColor(accentNeon)
            } else {
                Slider(value: value, in: range)
                    .accentColor(accentNeon)
            }
        }
        .padding(.vertical, 2)
    }
}
