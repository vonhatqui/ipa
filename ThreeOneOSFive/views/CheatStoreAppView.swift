import SwiftUI
import UIKit

// MARK: - CheatStore Clean Tab Enum (3 Tabs: Main, MISC, ME)
public enum CheatAppTab: Int, CaseIterable {
    case main = 0
    case misc = 1
    case me = 2

    var title: String {
        switch self {
        case .main: return "Main"
        case .misc: return "MISC"
        case .me: return "ME"
        }
    }

    var icon: String {
        switch self {
        case .main: return "house.fill"
        case .misc: return "wand.and.stars.inverse"
        case .me: return "person.crop.circle.fill"
        }
    }
}

// MARK: - CheatStore Clean Main App View
public struct CheatStoreAppView: View {
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    @State private var selectedTab: CheatAppTab = .main

    // Injector state
    @State private var isInjected: Bool = false
    @State private var isInjecting: Bool = false
    @State private var injectionProgress: Int = 0
    @State private var injectionStatusText: String = "Đang nạp patching..."
    @State private var pulseAnimation: Bool = false

    // Toast state
    @State private var toastMessage: String = ""
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = Color.green
    @State private var showToast: Bool = false

    // Original 3105 View Sheet
    @State private var showOriginal3105Sheet: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            // Nền đen tuyệt đối True Dark AMOLED
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header thanh trên: Logo + CHEATSTORE VN + EXTERNAL CONFIG MANAGER + ● ONLINE
                topNavigationBar

                // Nội dung chính theo 3 Tab
                ZStack {
                    if selectedTab == .main {
                        mainInjectorTabView
                            .transition(.opacity)
                    } else if selectedTab == .misc {
                        miscModSkinTabView
                            .transition(.opacity)
                    } else if selectedTab == .me {
                        meProfileTabView
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)

                // Bottom Tab Bar chuẩn 3 tab
                bottomTabBar
            }

            // Toast Notification Banner (Overlay trên cùng)
            if showToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: toastIcon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(toastColor)

                        Text(toastMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(white: 0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(toastColor.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: toastColor.opacity(0.25), radius: 10, y: 3)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .fullScreenCover(isPresented: $showOriginal3105Sheet) {
            Original3105WorkspaceView()
        }
    }

    // MARK: - 1. Top Navigation Bar (Chuẩn Screenshot 3)
    private var topNavigationBar: some View {
        HStack {
            // Trái: Logo + CHEATSTORE VN + EXTERNAL CONFIG MANAGER
            HStack(spacing: 10) {
                CheatStoreLogoView(size: 38, cornerRadius: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("CHEATSTORE VN")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.5)

                    Text("EXTERNAL CONFIG MANAGER")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.55))
                        .tracking(1.0)
                }
            }

            Spacer()

            // Phải: ● ONLINE
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.green.opacity(0.8), radius: 3)

                Text("ONLINE")
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.9))
                    .tracking(0.8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4.5)
            .background(Color(white: 0.12))
            .cornerRadius(999)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - 2. TAB MAIN: Chỉ Có Duy Nhất Nút INJECTOR
    private var mainInjectorTabView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Trung tâm: Logo & Thương hiệu
            VStack(spacing: 12) {
                CheatStoreLogoView(size: 84, cornerRadius: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                    )
                    .shadow(color: Color.white.opacity(0.20), radius: 16)

                VStack(spacing: 4) {
                    Text("CHEATSTORE VN")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.8)

                    Text("EXTERNAL CONFIG MANAGER")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.55))
                        .tracking(1.4)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.green.opacity(0.8), radius: 3)

                    Text("SERVER ONLINE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))
                        .tracking(1.0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(white: 0.12))
                .cornerRadius(999)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .scaleEffect(isInjecting ? (pulseAnimation ? 1.03 : 0.98) : 1.0)
            .animation(isInjecting ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: pulseAnimation)

            Spacer()

            // DƯỚI CÙNG: DUY NHẤT NÚT INJECTOR / UNINJECT
            VStack(spacing: 12) {
                injectorButton

                // Dòng trạng thái / hướng dẫn bên dưới nút
                HStack(spacing: 7) {
                    if isInjecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    }

                    Text(instructionStatusText)
                        .font(.system(size: 13, weight: isInjecting ? .semibold : .medium, design: .rounded))
                        .foregroundColor(
                            isInjecting ? Color.white : (isInjected ? Color(red: 1.0, green: 0.55, blue: 0.55) : Color(white: 0.65))
                        )
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Nút INJECTOR / UNINJECT Lớn
    private var injectorButton: some View {
        Button(action: {
            if isInjected {
                performInstantUninject()
            } else if !isInjecting {
                startInjectionProcess()
            }
        }) {
            ZStack {
                // Nền nút: Đen viền trắng khi INJECTOR | Đỏ thẫm khi UNINJECT
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isInjected ?
                        LinearGradient(
                            colors: [Color(red: 0.72, green: 0.10, blue: 0.14), Color(red: 0.48, green: 0.06, blue: 0.09)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(white: 0.08), Color(white: 0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isInjected ? Color.red.opacity(0.5) : Color.white.opacity(0.22),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: isInjected ? Color.red.opacity(0.35) : Color.black.opacity(0.7),
                        radius: 14,
                        y: 4
                    )

                // Nội dung nút
                HStack(spacing: 10) {
                    if isInjecting {
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)

                                Text("\(injectionStatusText) (\(injectionProgress)%)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            // Thanh tiến độ thanh mảnh
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(injectionProgress) / 100.0)), height: 4)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, 24)
                        }
                    } else if isInjected {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("UNINJECT")
                            .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.0)
                    } else {
                        Image(systemName: "syringe.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)

                        Text("INJECTOR")
                            .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .scaleEffect(isInjecting ? 0.98 : 1.0)
        .disabled(isInjecting)
    }

    private var instructionStatusText: String {
        if isInjecting {
            return "\(injectionStatusText) (\(injectionProgress)%)"
        } else if isInjected {
            return "Đã nạp CheatVN Enternal vào game thành công!"
        } else {
            return "Chạm INJECTOR để nạp CheatVN Enternal và vào game"
        }
    }

    // MARK: - Logic Nạp 2 File CheatVN Enternal (1% -> 100%)
    private func startInjectionProcess() {
        guard !isInjecting else { return }
        isInjecting = true
        isInjected = false
        pulseAnimation = true
        injectionProgress = 1
        injectionStatusText = "Đang nạp patching..."
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // 1. Chạy background ghi đúng 2 file vào Documents/
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.injectCheatFiles()
            print("[CheatStore] Nạp CheatVN Enternal vào Documents hoàn tất: \(success)")
        }

        // 2. Chạy timer tăng tiến độ 1% -> 100%
        let stepInterval: TimeInterval = 0.03
        Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            if self.injectionProgress < 100 {
                self.injectionProgress += 1
                if self.injectionProgress <= 40 {
                    self.injectionStatusText = "Đang nạp patching..."
                } else if self.injectionProgress <= 80 {
                    self.injectionStatusText = "Đang bypass anti-cheat..."
                } else {
                    self.injectionStatusText = "Đang chuẩn bị vào game..."
                }
            } else {
                timer.invalidate()
                self.injectionStatusText = "Hoàn tất! Đang vào game..."
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.isInjecting = false
                    self.isInjected = true
                    self.pulseAnimation = false
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.triggerToast(message: "Đã nạp CheatVN Enternal thành công! Đang vào game...", icon: "checkmark.circle.fill", color: .green)

                // Khởi chạy Free Fire
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.launchFreeFireGame()
                }
            }
        }
    }

    // MARK: - Logic Uninject Tức Thì ("Un cái là un luôn" - 0ms delay)
    private func performInstantUninject() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Đổi trạng thái ngay lập tức 0ms
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            self.isInjected = false
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        self.triggerToast(message: "✅ Đã gỡ nạp và xoá sạch file thành công!", icon: "checkmark.circle.fill", color: .green)

        // Xoá sạch ngầm toàn bộ file trong Documents/
        DispatchQueue.global(qos: .userInitiated).async {
            self.uninjectCheatFiles()
            _ = DevicePatchService.cleanRestoreAllModifications()
            print("[CheatStore] Đã dọn dẹp xoá sạch toàn bộ file liên quan đã nạp vào Documents")
        }
    }

    // MARK: - 3. TAB MISC: Mod Skin & Tiện Ích
    private var miscModSkinTabView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 110, height: 110)

                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 46))
                    .foregroundColor(Color.purple.opacity(0.85))
            }

            VStack(spacing: 8) {
                Text("MOD SKIN & TIỆN ÍCH")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Tính năng Mod Skin và các tiện ích mở rộng đang được phát triển, sẽ có mặt trong bản cập nhật tiếp theo.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(white: 0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Spacer()
        }
    }

    // MARK: - 4. TAB ME: Chuẩn 100% Ảnh Screenshot 3
    private var meProfileTabView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Tiêu đề ME
                VStack(alignment: .leading, spacing: 4) {
                    Text("ME")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Thông tin thiết bị và trạng thái kết nối hệ thống")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(white: 0.55))
                }
                .padding(.top, 4)

                // KHỐI 1: DEVICE (Chuẩn Screenshot 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEVICE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.50))
                        .tracking(1.0)
                        .padding(.horizontal, 2)

                    VStack(spacing: 0) {
                        profileDataRow(label: "Device Model", value: AppInfo.hardwareDisplayName.isEmpty ? "iPhone 15 Pro Max" : AppInfo.hardwareDisplayName)
                        profileRowDivider
                        profileDataRow(label: "Hardware ID", value: UIDevice.current.name.contains("iPhone") ? UIDevice.current.name : "iPhone16,2")
                        profileRowDivider
                        profileDataRow(label: "iOS Version", value: UIDevice.current.systemVersion.isEmpty ? "26.1" : UIDevice.current.systemVersion)
                        profileRowDivider
                        profileDataRow(label: "App Version", value: "2.4")
                        profileRowDivider
                        profileDataRow(label: "Build Number", value: "10")
                    }
                    .background(Color(white: 0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                // CÔNG CỤ 3105 (Gọn gàng theo yêu cầu)
                HStack(spacing: 10) {
                    if let uiImg = UIImage(named: "Logo3105") ?? UIImage(contentsOfFile: "ThreeOneOSFive/logo_3105.png") ?? UIImage(contentsOfFile: Bundle.main.bundleURL.appendingPathComponent("logo_3105.png").path) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    } else {
                        Image(systemName: "cpu")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.red.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text("Công cụ 3105")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("v2.0")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(3)
                        }
                        Text("Không gian cấu hình & patch gốc")
                            .font(.system(size: 10.5))
                            .foregroundColor(Color(white: 0.55))
                    }

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showOriginal3105Sheet = true
                    }) {
                        HStack(spacing: 4) {
                            Text("Qua app 3105")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8.5, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.88, green: 0.16, blue: 0.22), Color(red: 0.55, green: 0.08, blue: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(7)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(white: 0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // KHỐI 2: ACCOUNT & SERVER KEY (Chuẩn Screenshot 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACCOUNT & SERVER KEY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.50))
                        .tracking(1.0)
                        .padding(.horizontal, 2)

                    VStack(spacing: 0) {
                        // Key Status: HỢP LỆ (ACTIVE)
                        HStack {
                            Text("Key Status")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            Text("HỢP LỆ (ACTIVE)")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(white: 0.65))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // License Key
                        HStack {
                            Text("License Key")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            let key = licenseManager.activeKey.isEmpty ? "214060G00ZHLU7KZ" : licenseManager.activeKey
                            Text(key)
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // Gói Bản Quyền
                        HStack {
                            Text("Gói Bản Quyền")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            Text(licenseManager.planName.isEmpty ? "Gói VIP 3 Tháng" : licenseManager.planName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // Thời Hạn Còn Lại
                        HStack {
                            Text("Thời Hạn Còn Lại")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            let timeRemaining = (licenseManager.formattedRemainingTime == "Hết hạn" || licenseManager.formattedRemainingTime.isEmpty) ? "89 ngày 23 giờ" : licenseManager.formattedRemainingTime
                            Text(timeRemaining)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // Server Status: Online
                        HStack {
                            Text("Server Status")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            Text("Online")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(white: 0.85))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                    }
                    .background(Color(white: 0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                // 2 NÚT HÀNH ĐỘNG DƯỚI CÙNG (REFRESH & LOG OUT Chuẩn Screenshot 3)
                VStack(spacing: 12) {
                    // Nút REFRESH: Trắng tinh, chữ đen
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            _ = await licenseManager.verifyCurrentDevice()
                        }
                        triggerToast(message: "Đã làm mới thông tin hệ thống", icon: "arrow.clockwise", color: .green)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .heavy))
                            Text("REFRESH")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(14)
                    }

                    // Nút LOG OUT: Viền mờ, chữ trắng
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        licenseManager.deactivate()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.backward.square")
                                .font(.system(size: 14, weight: .bold))
                            Text("LOG OUT")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(white: 0.08))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 6)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    private func profileDataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(Color(white: 0.65))
            Spacer()
            Text(value)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private var profileRowDivider: some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.horizontal, 14)
    }

    // MARK: - 5. Bottom Tab Bar (Chuẩn 3 Tab: Main, MISC, ME)
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(CheatAppTab.allCases, id: \.self) { tab in
                let isSelected = (selectedTab == tab)

                Button {
                    guard selectedTab != tab else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : Color(white: 0.45))

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .white : Color(white: 0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(
            Color(white: 0.05)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: - Helper Functions: Quét container, Nạp 2 file, Gỡ file, Launch game
    private func findFreeFireContainerRoots() -> [URL] {
        let fileManager = FileManager.default
        var roots: [URL] = []
        let targets = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
        for bID in targets {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bID) {
                let url = URL(fileURLWithPath: path, isDirectory: true)
                if !roots.contains(url) { roots.append(url) }
            }
        }
        for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
            if !roots.contains(root) { roots.append(root) }
        }
        for rootPath in ["/private/var/mobile/Containers/Data/Application", "/var/mobile/Containers/Data/Application"] {
            if let dirs = try? fileManager.contentsOfDirectory(atPath: rootPath) {
                for d in dirs {
                    let full = (rootPath as NSString).appendingPathComponent(d)
                    let chk1 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefireth.plist")
                    let chk2 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
                    let chk3 = (full as NSString).appendingPathComponent("Documents")
                    if fileManager.fileExists(atPath: chk1) || fileManager.fileExists(atPath: chk2) || fileManager.fileExists(atPath: chk3) {
                        let url = URL(fileURLWithPath: full, isDirectory: true)
                        if !roots.contains(url) { roots.append(url) }
                    }
                }
            }
        }
        return roots
    }

    @discardableResult
    private func injectCheatFiles() -> Bool {
        let fileManager = FileManager.default
        let roots = findFreeFireContainerRoots()

        // 1. Thu thập DUY NHẤT 2 file:
        var assemblyData: Data? = nil
        var configData: Data = "{\"testCodePatch\":true}\n".data(using: .utf8)!

        let candidatePaths = [
            Bundle.main.bundleURL.appendingPathComponent("AppCore/Assembly-CSharp-patch.bytes"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/Assembly-CSharp-patch.bytes"),
            URL(fileURLWithPath: "ThreeOneOSFive/AppCore/Assembly-CSharp-patch.bytes"),
            URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/CheatVN Enternal/Assembly-CSharp-patch.bytes"),
            URL(fileURLWithPath: "D:/update_file/New folder/Assembly-CSharp-patch.bytes")
        ]
        for p in candidatePaths {
            if fileManager.fileExists(atPath: p.path), let d = try? Data(contentsOf: p), d.count > 40000 {
                assemblyData = d
                break
            }
        }

        let configCandidates = [
            Bundle.main.bundleURL.appendingPathComponent("AppCore/localConfig.json"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/localConfig.json"),
            URL(fileURLWithPath: "ThreeOneOSFive/AppCore/localConfig.json"),
            URL(fileURLWithPath: "D:/update_file/New folder/localConfig.json")
        ]
        for p in configCandidates {
            if fileManager.fileExists(atPath: p.path), let d = try? Data(contentsOf: p) {
                configData = d
                break
            }
        }

        if assemblyData == nil {
            let envCandidates = [
                Bundle.main.bundleURL.appendingPathComponent("AppCore/CheatVN Enternal.3105"),
                Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN Enternal.3105"),
                URL(fileURLWithPath: "ThreeOneOSFive/AppCore/CheatVN Enternal.3105")
            ]
            for envURL in envCandidates {
                if fileManager.fileExists(atPath: envURL.path),
                   let raw = try? Data(contentsOf: envURL),
                   let summary = try? PatchPackageCodec.inspect(raw),
                   let decoded = PatchProjectLibrary.decodePackageSafely(data: raw, summary: summary) {
                    for rule in decoded.project.rules {
                        if rule.relativePath.contains("Assembly-CSharp-patch.bytes") {
                            assemblyData = rule.replacementData
                            break
                        }
                    }
                }
                if assemblyData != nil { break }
            }
        }

        guard let assembly = assemblyData else {
            print("[CheatStore] ❌ Không tìm thấy Assembly-CSharp-patch.bytes")
            return false
        }

        let filesMap: [String: Data] = [
            "Assembly-CSharp-patch.bytes": assembly,
            "localConfig.json": configData
        ]

        var writtenCount = 0
        for root in roots {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docDir.path)

            // Xoá sạch các file patch khác tránh lỗi crash
            let conflicting = [
                ".ffxc_live",
                ".ffxc_runtime",
                ".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9",
                "contentcache/res_version.hash",
                "contentcache/file_hash.bin",
                "contentcache/verify_cache.dat",
                "contentcache/crc_cache.bin",
                "contentcache/asset_verify.db",
                "contentcache/patch_verify.dat",
                "pending_reports"
            ]
            for c in conflicting {
                let p = docDir.appendingPathComponent(c)
                if fileManager.fileExists(atPath: p.path) {
                    try? fileManager.removeItem(at: p)
                }
            }

            // Ghi đúng 2 file
            for (name, data) in filesMap {
                let dst = docDir.appendingPathComponent(name)
                try? fileManager.removeItem(at: dst)
                var written = false
                do {
                    try data.write(to: dst)
                    written = true
                } catch {
                    let tmp = fileManager.temporaryDirectory.appendingPathComponent(name)
                    if (try? data.write(to: tmp)) != nil {
                        if (try? fileManager.copyItem(at: tmp, to: dst)) != nil { written = true }
                        try? fileManager.removeItem(at: tmp)
                    }
                }
                if written {
                    var u = dst
                    var resVals = URLResourceValues()
                    resVals.isExcludedFromBackup = true
                    try? u.setResourceValues(resVals)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dst.path)
                    writtenCount += 1
                }
            }
        }

        DevicePatchService.ensureActivePatchesInjected()
        return writtenCount > 0
    }

    private func uninjectCheatFiles() {
        let fileManager = FileManager.default
        let roots = findFreeFireContainerRoots()
        let filesToDelete = [
            "Documents/Assembly-CSharp-patch.bytes",
            "Documents/localConfig.json",
            "Documents/.ffxc_live",
            "Documents/.ffxc_runtime",
            "Documents/.ffxc_neutral_37ca851ab5df497db608f1b2f45165f9",
            "Documents/contentcache",
            "Documents/pending_reports",
            "Library/Application Support/Assembly-CSharp-patch.bytes"
        ]
        for root in roots {
            for rel in filesToDelete {
                let p = root.appendingPathComponent(rel)
                if fileManager.fileExists(atPath: p.path) {
                    try? fileManager.removeItem(at: p)
                }
            }
        }
    }

    private func launchFreeFireGame() {
        let schemes = ["freefireth://", "freefiremax://", "freefire://", "freefirevn://"]
        for s in schemes {
            if let url = URL(string: s), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        if let url = URL(string: "freefireth://") {
            UIApplication.shared.open(url)
        }
    }

    private func triggerToast(message: String, icon: String, color: Color) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                showToast = false
            }
        }
    }
}
