import SwiftUI
import UIKit

public struct HyperXMainView: View {
    @ObservedObject var injectionManager = HyperXInjectionManager.shared
    @ObservedObject var authManager = HyperXAuthManager.shared
    @State private var alertMessage: String?
    @State private var showAlert = false

    public init() {}

    // MARK: - Auto-Sweep Sentinel Binding (Nút Bật / Tắt Quét File Độc Lập)

    private var autoSweepBinding: Binding<Bool> {
        Binding(
            get: { injectionManager.isAutoSweepActive },
            set: { enabled in
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                if enabled {
                    injectionManager.startAutoSweep()
                } else {
                    // Khoa: khong cho tat sau khi Inject
                    guard !injectionManager.isAutoSweepLocked else { return }
                    injectionManager.stopAutoSweep()
                }
            }
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Nền sáng / light mode hiện đại, giao diện sạch sẽ chuẩn iOS
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // TOP STATUS BAR
                    topStatusBar

                    // MAIN SCROLL CONTENT
                    ScrollView {
                        VStack(spacing: 16) {
                            if injectionManager.buttonState == .loader && injectionManager.features.isEmpty {
                                if injectionManager.isLoading {
                                    loadingServerView
                                } else {
                                    initialLoaderView
                                }
                            } else {
                                // 1. CÔNG TẮC BẬT / TẮT QUÉT FILE TỰ ĐỘNG (AUTO-SWEEP SENTINEL)
                                sentinelControlCard

                                // 2. DANH SÁCH CHỨC NĂNG (MỖI CHỨC NĂNG CÓ LOGO TỰ CHIA X)
                                loadedFeaturesView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 110) // Khoảng trống cho thanh điều khiển bên dưới
                    }

                    Spacer(minLength: 0)
                }

                // BOTTOM ACTION BAR (STICKY)
                VStack {
                    Spacer()
                    bottomActionBar
                }

                // FLOATING ANTIBAN V2 HUD BANNER (THEO CHUẨN PAO)
                if injectionManager.showAntibanBanner, let summary = injectionManager.antibanSummary {
                    VStack {
                        antibanFloatingBanner(summary: summary)
                            .padding(.top, 12)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .navigationTitle("Main")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        if let img = UIImage(named: "HyperXLogo") ?? UIImage(named: "AppIcon60x60") {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        Text("HyperXSpace")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(uiColor: .label))
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Thông Báo"),
                    message: Text(alertMessage ?? ""),
                    dismissButton: .default(Text("Đã Hiểu"))
                )
            }
        }
    }

    // MARK: - Top Status Bar

    private var topStatusBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.emerald400)
                    .frame(width: 8, height: 8)
                Text("Máy Chủ Hoạt Động")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            Spacer()

            if let pkg = authManager.licenseInfo?.package {
                Text(pkg)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.08, green: 0.72, blue: 0.22))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.08, green: 0.72, blue: 0.22).opacity(0.10))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemBackground))
        .overlay(
            Divider().opacity(0.5), alignment: .bottom
        )
    }

    // MARK: - Initial Loader & Loading Views

    private var initialLoaderView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.08, green: 0.72, blue: 0.22).opacity(0.08))
                        .frame(width: 68, height: 68)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color(red: 0.08, green: 0.72, blue: 0.22))
                }

                Text("Ấn nút Loader để Load Chức Năng Từ Server !")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        }
        .padding(.top, 24)
    }

    private var loadingServerView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.08, green: 0.72, blue: 0.22)))
                .scaleEffect(1.4)
                .padding(.bottom, 4)

            Text("Đang Tải Dữ Liệu Từ Server...")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .label))
        }
        .padding(.vertical, 44)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        .padding(.top, 24)
    }

    // MARK: - Sentinel Control Card (Nút Bật / Tắt Quét File Tự Động 0s Delay)

    private var sentinelControlCard: some View {
        VStack(spacing: 12) {
            // Hàng công tắc Bật / Tắt chính
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(injectionManager.isAutoSweepActive ? Color.emerald400.opacity(0.18) : Color.gray.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(injectionManager.isAutoSweepActive ? Color.emerald400 : Color.gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Tự Động Quét File")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(uiColor: .label))

                        if injectionManager.isAutoSweepActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.emerald400)
                                    .frame(width: 6, height: 6)
                                Text("0s DELAY")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(Color.emerald400)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.emerald400.opacity(0.12))
                            .clipShape(Capsule())
                        } else {
                            Text("ĐÃ TẮT")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(Color.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text(injectionManager.isAutoSweepActive ? "Kernel Event + 250ms triệt tiêu reportnew.db liên tục" : "Bật công tắc để tự động quét triệt tiêu log khi vào trận")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .lineLimit(1)
                }

                Spacer()

                // CÔNG TẮC BẬT / TẮT QUÉT FILE ĐỘC LẬP (KHÔNG ẢNH HƯỞNG INJECTOR)
                Toggle("", isOn: autoSweepBinding)
                    .labelsHidden()
                    .tint(Color.emerald400)
                    .disabled(injectionManager.isAutoSweepLocked)
            }

            Divider()

            // Thống kê quét thực tế
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Đã Triệt Tiêu")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    Text("\(injectionManager.autoSweepCleanedCount) tệp")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.emerald400)
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("Mục Tiêu Trọng Yếu")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    Text("reportnew.db / HeatMap")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(uiColor: .label))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Chu Kỳ Quét")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    Text("\(injectionManager.autoSweepCycleCount) vòng")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.08, green: 0.72, blue: 0.22))
                }
            }
            .padding(.horizontal, 4)

            Divider()

            // Hàng tuỳ chọn thông báo & quét ngay thủ công
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.emerald400)
                    Text("Biểu Ngữ (Banner)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .label))
                }

                Spacer()

                // Nút thử thông báo
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    injectionManager.sendTestNotification()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 9))
                        Text("Thử Thông Báo")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.emerald400)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.emerald400.opacity(0.12))
                    .clipShape(Capsule())
                }

                Toggle("", isOn: $injectionManager.isBannerNotificationEnabled)
                    .labelsHidden()
                    .tint(Color.emerald400)
                    .onChange(of: injectionManager.isBannerNotificationEnabled) { enabled in
                        if enabled {
                            injectionManager.requestNotificationPermission()
                        }
                    }

                // Nút quét ngay thủ công
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    injectionManager.sweepTelemetryTargetsOnce()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.emerald400)
                        .padding(7)
                        .background(Color.emerald400.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(injectionManager.isAutoSweepActive ? Color.emerald400.opacity(0.35) : Color(uiColor: .separator).opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Loaded Features View (Danh Sách Tính Năng Kèm Logo Tự Chia X)

    private var loadedFeaturesView: some View {
        VStack(spacing: 14) {
            // Thanh tiêu đề danh sách chức năng (Mỗi lần chỉ chọn 1 chức năng duy nhất)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DANH SÁCH CHỨC NĂNG")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    if let selected = injectionManager.features.first(where: { $0.isSelected }) {
                        Text("Đang chọn: \(selected.name)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(red: 0.08, green: 0.72, blue: 0.22))
                    } else {
                        Text("Vui lòng chọn 1 chức năng")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }

                Spacer()

                Text("Chỉ Chọn 1 Mục")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            // Danh sách các thẻ tính năng (Chọn 1 mục duy nhất)
            ForEach(injectionManager.features) { feature in
                featureRow(feature: feature)
            }

            // Card nhắc nhở Chống Ban Tài Khoản
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.08, green: 0.72, blue: 0.22))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cơ Chế Hoạt Động & Chống Ban")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(uiColor: .label))
                    Text("1. Chọn chức năng bạn muốn rồi ấn [Injector] để nạp.\n2. Công tắc [Tự Động Quét File] ở trên sẽ luôn triệt tiêu reportnew.db 0s delay khi vào trận.\n3. Khi muốn nghỉ chơi hoặc dọn dẹp, bạn có thể ấn [Antiban V2] bên dưới.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .lineSpacing(2)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.72, blue: 0.22).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Feature Row With Logo (Tự Chia X / Auto Aspect Ratio)

    private func featureRow(feature: HyperXFeatureItem) -> some View {
        Button {
            injectionManager.selectSingle(for: feature.id)
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
        } label: {
            HStack(spacing: 12) {
                // Ô TÍCH CHỌN DUY NHẤT (SINGLE CHOICE)
                ZStack {
                    Circle()
                        .fill(feature.isSelected ? Color(red: 0.08, green: 0.72, blue: 0.22) : Color(uiColor: .tertiarySystemGroupedBackground))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(feature.isSelected ? Color.clear : Color(uiColor: .separator), lineWidth: 1.2)
                        )

                    if feature.isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // LOGO / ẢNH CHỨC NĂNG (TỰ CHIA TỶ LỆ X)
                featureLogoView(feature: feature)

                // THÔNG TIN CHỨC NĂNG
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(feature.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(uiColor: .label))

                        categoryTag(category: feature.category)
                    }

                    if !feature.subtitle.isEmpty {
                        Text(feature.subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        Text(feature.targetPath)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            .lineLimit(1)

                        if feature.size > 0 {
                            Text("• \(feature.formattedSize)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(feature.isSelected ? Color(red: 0.08, green: 0.72, blue: 0.22).opacity(0.35) : Color.clear, lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(feature.isSelected ? 0.04 : 0.02), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logo / Ảnh Chức Năng (Tự Chia Tỷ Lệ X - Auto Aspect Ratio Scale)

    @ViewBuilder
    private func featureLogoView(feature: HyperXFeatureItem) -> some View {
        if let urlStr = feature.iconUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlStr.isEmpty,
           let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            .frame(width: 44, height: 44)
                        ProgressView()
                            .scaleEffect(0.65)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit() // Tự chia x (giữ đúng tỉ lệ ảnh, vừa vặn khung hình 44x44)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 0.8)
                        )
                case .failure:
                    defaultFeatureIcon(category: feature.category)
                @unknown default:
                    defaultFeatureIcon(category: feature.category)
                }
            }
        } else {
            defaultFeatureIcon(category: feature.category)
        }
    }

    private func defaultFeatureIcon(category: String) -> some View {
        let iconName: String
        let iconColor: Color
        switch category.lowercased() {
        case "home_aim":
            iconName = "scope"
            iconColor = Color.indigo
        case "esp":
            iconName = "eye.fill"
            iconColor = Color.teal
        case "skin":
            iconName = "tshirt.fill"
            iconColor = Color.purple
        case "assembly":
            iconName = "cpu.fill"
            iconColor = Color.orange
        default:
            iconName = "cube.fill"
            iconColor = Color(red: 0.08, green: 0.72, blue: 0.22)
        }

        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(iconColor.opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(iconColor.opacity(0.25), lineWidth: 0.8)
        )
    }

    private func categoryTag(category: String) -> some View {
        let label: String
        let color: Color
        switch category.lowercased() {
        case "home_aim":
            label = "Aim"
            color = Color.indigo
        case "esp":
            label = "ESP"
            color = Color.teal
        case "skin":
            label = "Skin"
            color = Color.purple
        case "assembly":
            label = "DLL"
            color = Color.orange
        default:
            label = "Core"
            color = Color.blue
        }

        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Bottom Action Bar (Loader Hoặc [Antiban V2] + [Injector] Đồng Thời)

    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            if let status = injectionManager.statusMessage {
                Text(status)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineLimit(1)
            }

            if injectionManager.buttonState == .loader && injectionManager.features.isEmpty {
                // NÚT 1: LOADER (Khi chưa tải danh sách tính năng)
                Button {
                    Task {
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                        await injectionManager.loadFeatures()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if injectionManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Đang Tải Dữ Liệu Từ Server...")
                                .font(.system(size: 14, weight: .bold))
                        } else {
                            Text("Loader")
                                .font(.system(size: 16, weight: .heavy))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(red: 0.08, green: 0.72, blue: 0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.08, green: 0.72, blue: 0.22).opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(0.85)
                .disabled(injectionManager.isLoading)
            } else {
                // NÚT 2 & 3: [ANTIBAN V2] VÀ [INJECTOR] NẰM CẠNH NHAU (KHÔNG BAO GIỜ BỊ KHÓA GIAO DIỆN)
                HStack(spacing: 12) {
                    // Nút Antiban V2 (Quét Dọn & Gỡ Mod)
                    Button {
                        Task {
                            let haptic = UINotificationFeedbackGenerator()
                            haptic.notificationOccurred(.warning)
                            let res = await injectionManager.uninjectAll()
                            alertMessage = res.message
                            showAlert = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if injectionManager.isUninjecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            Text(injectionManager.isUninjecting ? "Đang Quét..." : "Antiban V2")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.08, green: 0.65, blue: 0.40))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color(red: 0.08, green: 0.65, blue: 0.40).opacity(0.35), radius: 6, x: 0, y: 3)
                    }
                    .disabled(injectionManager.isUninjecting)

                    // Nút Injector chính (Nạp Chức Năng Đang Chọn)
                    Button {
                        Task {
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            haptic.impactOccurred()
                            let res = await injectionManager.injectSelectedFeatures()
                            alertMessage = res.message
                            showAlert = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if injectionManager.isInjecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Đang Nạp...")
                                    .font(.system(size: 15, weight: .bold))
                            } else {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Injector")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(injectionManager.selectedCount > 0 ? Color(red: 0.08, green: 0.72, blue: 0.22) : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color(red: 0.08, green: 0.72, blue: 0.22).opacity(injectionManager.selectedCount > 0 ? 0.3 : 0), radius: 8, x: 0, y: 3)
                    }
                    .disabled(injectionManager.isInjecting || injectionManager.selectedCount == 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(uiColor: .systemBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
        )
    }

    // MARK: - Floating Antiban V2 Banner (Theo Chuẩn Thông Báo Của Pao)

    private func antibanFloatingBanner(summary: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(red: 0.20, green: 0.83, blue: 0.60))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(summary.components(separatedBy: "\n"), id: \.self) { line in
                    Text(line)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 0.86, green: 0.90, blue: 0.94))
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    injectionManager.showAntibanBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(6)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.13).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 14)
    }
}

// MARK: - Color Extension

extension Color {
    static let emerald400 = Color(red: 0.20, green: 0.78, blue: 0.50)
}
