import SwiftUI
import UIKit

// MARK: - Reusable Luxury UI Components (Theo đúng Design Language AMOLED của ThreeOneOSFive)

/// Nút gạt công tắc tuỳ biến Capsule dạ quang chuẩn phong cách AMOLED sang trọng của App
public struct LuxuryFeatureToggleRow: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let iconColor: Color
    @Binding public var isOn: Bool

    @State private var isPressing: Bool = false

    public init(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                // Icon Neon Dạ Quang
                ZStack {
                    Circle()
                        .fill(isOn ? iconColor.opacity(0.18) : Color.white.opacity(0.04))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(isOn ? iconColor.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isOn ? iconColor : Color.white.opacity(0.40))
                        .shadow(color: isOn ? iconColor.opacity(0.8) : .clear, radius: 6)
                }

                // Tiêu đề & Mô tả
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(isOn ? .white : Color.white.opacity(0.75))

                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(2)
                }

                Spacer()

                // Custom Switch Capsule (Thay thế Toggle chuẩn iOS)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? iconColor.opacity(0.30) : Color.white.opacity(0.08))
                        .frame(width: 48, height: 26)
                        .overlay(
                            Capsule()
                                .stroke(isOn ? iconColor.opacity(0.85) : Color.white.opacity(0.15), lineWidth: 1.2)
                        )
                        .shadow(color: isOn ? iconColor.opacity(0.45) : .clear, radius: 6)

                    Circle()
                        .fill(isOn ? Color.white : Color.white.opacity(0.55))
                        .frame(width: 20, height: 20)
                        .padding(.horizontal, 3)
                        .shadow(color: Color.black.opacity(0.4), radius: 3, y: 1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isOn ? Color(red: 22/255, green: 24/255, blue: 32/255) : Color.white.opacity(0.02))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Thanh trượt Slider tuỳ chỉnh với Value Pill hiển thị số động thời gian thực
public struct LuxurySliderRow: View {
    public let title: String
    public let icon: String
    public let iconColor: Color
    public let unit: String
    public let range: ClosedRange<Double>
    public let step: Double
    @Binding public var value: Double

    public init(
        title: String,
        icon: String,
        iconColor: Color,
        unit: String,
        range: ClosedRange<Double>,
        step: Double = 1.0,
        value: Binding<Double>
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.unit = unit
        self.range = range
        self.step = step
        self._value = value
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.85))

                Spacer()

                // Value Pill Badge
                Text(formatValue(value) + " " + unit)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(iconColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(iconColor.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(iconColor.opacity(0.35), lineWidth: 0.8))
            }

            Slider(value: $value, in: range, step: step)
                .accentColor(iconColor)
                .onChange(of: value) { _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 20/255, green: 22/255, blue: 28/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func formatValue(_ v: Double) -> String {
        if step >= 1.0 {
            return String(format: "%.0f", v)
        } else {
            return String(format: "%.1f", v)
        }
    }
}

/// Bộ chọn Segmented Picker dạng Chip bo tròn cao cấp
public struct LuxurySegmentedPicker: View {
    public let title: String
    public let options: [String]
    public let accentColor: Color
    @Binding public var selection: String

    public init(
        title: String,
        options: [String],
        accentColor: Color,
        selection: Binding<String>
    ) {
        self.title = title
        self.options = options
        self.accentColor = accentColor
        self._selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(1.0)
                .padding(.horizontal, 2)

            HStack(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    let isSelected = (selection == opt)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                            selection = opt
                        }
                    } label: {
                        Text(opt)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .black : Color.white.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                isSelected
                                    ? accentColor
                                    : Color.white.opacity(0.05)
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? accentColor : Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: isSelected ? accentColor.opacity(0.4) : .clear, radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 20/255, green: 22/255, blue: 28/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - ESP Live Radar Simulation Box (Khung mô phỏng trực quan thời gian thực)
public struct ESPLivePreviewBox: View {
    @ObservedObject var store = ZrxFeaturesConfigStore.shared

    private let cyanAccent = Color(red: 0/255, green: 215/255, blue: 255/255)
    private let greenAccent = Color(red: 0/255, green: 230/255, blue: 118/255)
    private let redAccent = Color(red: 255/255, green: 75/255, blue: 75/255)

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(store.espMaster ? greenAccent : Color.red)
                        .frame(width: 7, height: 7)
                    Text(store.espMaster ? "RADAR SIMULATION LIVE" : "RADAR ĐANG TẮT")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(store.espMaster ? greenAccent : Color.red)
                }

                Spacer()

                Text("PREVIEW 60 FPS")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 10)

            ZStack {
                // Nền radar không gian đen
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 10/255, green: 11/255, blue: 15/255))
                    .frame(height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                // Lưới Radar mờ
                VStack {
                    Divider().background(Color.white.opacity(0.04))
                    Spacer()
                    Divider().background(Color.white.opacity(0.04))
                    Spacer()
                    Divider().background(Color.white.opacity(0.04))
                }
                .padding(.vertical, 10)

                if store.espMaster {
                    // Đối thủ 1: Bên trái
                    mockPlayerTarget(
                        xOffset: -75,
                        yOffset: 10,
                        name: "BOT_01_PRO",
                        dist: "48m",
                        hp: 0.95,
                        color: cyanAccent
                    )

                    // Đối thủ 2: Ở giữa/phải
                    mockPlayerTarget(
                        xOffset: 65,
                        yOffset: -12,
                        name: "ENEMY_VIP",
                        dist: "112m",
                        hp: 0.60,
                        color: redAccent
                    )
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("Bật ESP Master để xem mô phỏng định vị")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
            }
            .frame(height: 140)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 15/255, green: 16/255, blue: 22/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func mockPlayerTarget(xOffset: CGFloat, yOffset: CGFloat, name: String, dist: String, hp: CGFloat, color: Color) -> some View {
        ZStack {
            // Tia kẻ ESP Line
            if store.espLine {
                let fromTop = store.lineFrom.contains("Top") || store.lineFrom.contains("Trên")
                Path { path in
                    let startY: CGFloat = fromTop ? -65 : 65
                    path.move(to: CGPoint(x: 0, y: startY))
                    path.addLine(to: CGPoint(x: xOffset, y: yOffset - 25))
                }
                .stroke(color.opacity(0.85), lineWidth: CGFloat(store.thicknessSize * 0.7))
            }

            VStack(spacing: 2) {
                // Tên & Khoảng cách
                if store.espName || store.espDistance {
                    HStack(spacing: 3) {
                        if store.espName {
                            Text(name)
                                .font(.system(size: CGFloat(store.textSize * 0.65), weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        if store.espDistance {
                            Text("[\(dist)]")
                                .font(.system(size: CGFloat(store.textSize * 0.60), weight: .bold, design: .monospaced))
                                .foregroundColor(color)
                        }
                    }
                    .padding(.horizontal, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(3)
                }

                // Thanh máu ESP Health
                if store.espHealth {
                    if store.healthType.contains("Bar") || store.healthType.contains("Thanh") {
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.5)).frame(width: 32, height: 3.5)
                            Capsule().fill(hp > 0.4 ? greenAccent : redAccent).frame(width: 32 * hp, height: 3.5)
                        }
                    } else {
                        Text("\(Int(hp * 100))%")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(hp > 0.4 ? greenAccent : redAccent)
                    }
                }

                // Khung ESP Box & Fill
                ZStack {
                    if store.espBoxFill {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color.opacity(0.20))
                            .frame(width: 30, height: 50)
                    }

                    if store.espBox {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(color, lineWidth: CGFloat(store.thicknessSize * 0.8))
                            .frame(width: 30, height: 50)
                    }

                    if store.espSkeleton {
                        // Vẽ khung xương nhân vật mini
                        VStack(spacing: 0) {
                            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1).frame(width: 8, height: 8)
                            Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1, height: 16)
                            HStack(spacing: 8) {
                                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1, height: 16)
                                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1, height: 16)
                            }
                        }
                    }
                }
            }
            .offset(x: xOffset, y: yOffset)
        }
    }
}

// MARK: - TAB 1: AIMBOT SETTINGS VIEW (Chuẩn Chức Năng Zrxipa + UI AMOLED ThreeOneOSFive)
public struct AimbotTabContentView: View {
    @ObservedObject var store = ZrxFeaturesConfigStore.shared

    private let cyanAccent = Color(red: 0/255, green: 215/255, blue: 255/255)
    private let cardBg = Color(red: 16/255, green: 17/255, blue: 23/255)
    private let cardBorder = Color.white.opacity(0.10)

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Banner Tiêu Đề Aimbot VIP
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(cyanAccent.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(cyanAccent.opacity(0.4), lineWidth: 1))

                        Image(systemName: "scope")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(cyanAccent)
                            .shadow(color: cyanAccent.opacity(0.8), radius: 8)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("AIMBOT SETTINGS")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("VIP SUITE")
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(cyanAccent)
                                .cornerRadius(6)
                        }

                        Text("Đang kích hoạt \(store.activeAimbotCount)/\(store.totalAimbotCount) tính năng ghim tâm")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                    }

                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(cyanAccent.opacity(0.25), lineWidth: 1))

                // 1. Phân Loại Aimbot & Xương Ghim
                VStack(spacing: 10) {
                    LuxurySegmentedPicker(
                        title: "LOẠI AIMBOT (AIMBOT TYPE)",
                        options: ["Aimbot Silent", "Aimbot Vector", "Aim Silent"],
                        accentColor: cyanAccent,
                        selection: $store.aimbotType
                    )

                    LuxurySegmentedPicker(
                        title: "VỊ TRÍ GHIM XƯƠNG (BONE SELECTION)",
                        options: ["Đầu (Head)", "Cổ (Neck)", "Ngực (Chest)"],
                        accentColor: cyanAccent,
                        selection: $store.aimBone
                    )
                }

                // 2. Chế Độ Kích Hoạt Ghim Tâm
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHẾ ĐỘ TỰ ĐỘNG (AIMBOT MODES)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 1) {
                        LuxuryFeatureToggleRow(
                            title: "AutoHead (Tự Động Ghim Đầu)",
                            subtitle: "Tâm súng tự động dịch chuyển trúng đầu đối thủ khi bấm bắn",
                            icon: "target",
                            iconColor: cyanAccent,
                            isOn: $store.autoHead
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "Auto Pull Aim (Tự Kéo Tâm Mượt)",
                            subtitle: "Tạo lực kéo tâm hỗ trợ nhẹ nhàng, chống rung lắc màn hình",
                            icon: "arrow.up.and.down.and.sparkles",
                            iconColor: cyanAccent,
                            isOn: $store.autoPullAim
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "Bỏ Qua Người Đã Gục (Ignore Knocked)",
                            subtitle: "Không khóa tâm vào kẻ địch đã ngã, ưu tiên mục tiêu sống",
                            icon: "person.crop.circle.badge.xmark",
                            iconColor: Color.yellow,
                            isOn: $store.ignoreKnocked
                        )
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                }

                // 3. Vòng Bán Kính FOV (Field Of View)
                VStack(alignment: .leading, spacing: 8) {
                    Text("VÒNG BÁN KÍNH QUÉT (FOV RADAR)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        LuxuryFeatureToggleRow(
                            title: "Bật Vòng Tròn FOV",
                            subtitle: "Hiển thị vòng tròn giới hạn bán kính ghim tâm trên màn hình",
                            icon: "circle.circle.fill",
                            iconColor: cyanAccent,
                            isOn: $store.fovEnabled
                        )

                        if store.fovEnabled {
                            LuxurySliderRow(
                                title: "Bán Kính Quét FOV",
                                icon: "ruler",
                                iconColor: cyanAccent,
                                unit: "px",
                                range: 30.0...360.0,
                                step: 5.0,
                                value: $store.fovRadius
                            )

                            LuxurySegmentedPicker(
                                title: "KIỂU VIỀN VÒNG FOV (FOV STYLE)",
                                options: ["Liền (Solid)", "Nét đứt (Dashed)", "Chấm (Dots)"],
                                accentColor: cyanAccent,
                                selection: $store.fovStyle
                            )
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                }

                // 4. Thông Số Chi Tiết Kéo Tâm
                VStack(alignment: .leading, spacing: 8) {
                    Text("THÔNG SỐ GHIM TÂM NÂNG CAO")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        LuxurySliderRow(
                            title: "Tỉ Lệ Trúng Đạn (Hit Chance)",
                            icon: "percent",
                            iconColor: Color.green,
                            unit: "%",
                            range: 50.0...100.0,
                            step: 1.0,
                            value: $store.hitChance
                        )

                        LuxurySliderRow(
                            title: "Khoảng Cách Khóa Tâm",
                            icon: "arrow.left.and.right",
                            iconColor: cyanAccent,
                            unit: "m",
                            range: 20.0...300.0,
                            step: 5.0,
                            value: $store.aimbotDistance
                        )

                        LuxurySliderRow(
                            title: "Độ Trễ Kéo Tâm (Head Pull Delay)",
                            icon: "timer",
                            iconColor: Color.orange,
                            unit: "ms",
                            range: 0.0...200.0,
                            step: 5.0,
                            value: $store.headPullDelay
                        )

                        LuxurySliderRow(
                            title: "Thời Gian Giữ Tâm (Head Pull Time)",
                            icon: "hourglass",
                            iconColor: Color.purple,
                            unit: "ms",
                            range: 50.0...500.0,
                            step: 10.0,
                            value: $store.headPullTime
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - TAB 2: VISUAL ESP SETTINGS VIEW (Chuẩn Zrxipa + UI AMOLED)
public struct VisualEspTabContentView: View {
    @ObservedObject var store = ZrxFeaturesConfigStore.shared

    private let greenAccent = Color(red: 0/255, green: 230/255, blue: 118/255)
    private let cardBg = Color(red: 16/255, green: 17/255, blue: 23/255)
    private let cardBorder = Color.white.opacity(0.10)

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Banner Tiêu Đề ESP VIP
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(greenAccent.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(greenAccent.opacity(0.4), lineWidth: 1))

                        Image(systemName: "viewfinder")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(greenAccent)
                            .shadow(color: greenAccent.opacity(0.8), radius: 8)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("ESP VISUAL SETTINGS")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("X-RAY 3D")
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(greenAccent)
                                .cornerRadius(6)
                        }

                        Text(store.espMaster ? "Đang bật \(store.activeEspCount)/\(store.totalEspCount) module định vị" : "Định vị đang tạm tắt")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                    }

                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(greenAccent.opacity(0.25), lineWidth: 1))

                // Khung mô phỏng Radar trực quan thời gian thực (Live Preview)
                ESPLivePreviewBox()

                // Master Toggle Switch
                LuxuryFeatureToggleRow(
                    title: "ESP MASTER (BẬT TỔNG ĐỊNH VỊ)",
                    subtitle: "Bật hoặc tắt toàn bộ tất cả các module nhìn xuyên tường",
                    icon: "power.circle.fill",
                    iconColor: greenAccent,
                    isOn: $store.espMaster
                )
                .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(store.espMaster ? greenAccent.opacity(0.4) : cardBorder, lineWidth: 1))

                // Danh Sách Các Module Định Vị
                VStack(alignment: .leading, spacing: 8) {
                    Text("CÁC MODULE ĐỊNH VỊ (VISUAL MODULES)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 1) {
                        LuxuryFeatureToggleRow(
                            title: "ESP Line (Tia Kẻ Định Vị)",
                            subtitle: "Tia laser màu nối thẳng từ màn hình tới vị trí đối thủ",
                            icon: "point.topleft.down.to.point.bottomright.curvepath",
                            iconColor: Color.purple,
                            isOn: $store.espLine
                        )

                        if store.espLine {
                            LuxurySegmentedPicker(
                                title: "ĐIỂM XUẤT PHÁT TIA KẺ (LINE FROM)",
                                options: ["Trên (Top)", "Dưới (Bottom)"],
                                accentColor: Color.purple,
                                selection: $store.lineFrom
                            )
                            .padding(.horizontal, 6)
                            .padding(.bottom, 6)
                        }

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "ESP Box (Khung Hộp 2D/3D)",
                            subtitle: "Vẽ khung viền bao quanh toàn bộ cơ thể đối thủ",
                            icon: "squareshape.dashed",
                            iconColor: Color.yellow,
                            isOn: $store.espBox
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "ESP Box Fill (Tô Nền Box Mờ)",
                            subtitle: "Đổ bóng nền mờ trong khung hộp để nhìn địch rõ nét hơn",
                            icon: "square.fill",
                            iconColor: Color.orange,
                            isOn: $store.espBoxFill
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "ESP Name (Tên Người Chơi & Bot)",
                            subtitle: "Hiển thị tên thật và đánh dấu phân biệt người chơi/bot",
                            icon: "text.alignleft",
                            iconColor: greenAccent,
                            isOn: $store.espName
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "ESP Health (Thanh Máu Đối Thủ)",
                            subtitle: "Hiển thị lượng HP hiện tại của mục tiêu để phán đoán",
                            icon: "heart.fill",
                            iconColor: Color.red,
                            isOn: $store.espHealth
                        )

                        if store.espHealth {
                            LuxurySegmentedPicker(
                                title: "KIỂU HIỂN THỊ MÁU (HEALTH STYLE)",
                                options: ["Thanh Máu (Bar)", "Số % (Text)"],
                                accentColor: Color.red,
                                selection: $store.healthType
                            )
                            .padding(.horizontal, 6)
                            .padding(.bottom, 6)
                        }

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "ESP Skeleton (Khung Xương Nhân Vật)",
                            subtitle: "Vẽ toàn bộ khớp xương chuyển động khi đối thủ di chuyển",
                            icon: "figure.walk",
                            iconColor: Color.cyan,
                            isOn: $store.espSkeleton
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "ESP Distance (Khoảng Cách Mét)",
                            subtitle: "Hiện số mét chính xác từ vị trí của bạn tới đối thủ",
                            icon: "location.north.circle.fill",
                            iconColor: Color.blue,
                            isOn: $store.espDistance
                        )
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                }

                // Tùy Chỉnh Kích Thước & Nét Vẽ
                VStack(alignment: .leading, spacing: 8) {
                    Text("TÙY CHỈNH KÍCH THƯỚC & NÉT VẼ")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        LuxurySliderRow(
                            title: "Khoảng Cách Định Vị Tối Đa",
                            icon: "eye.fill",
                            iconColor: greenAccent,
                            unit: "m",
                            range: 50.0...500.0,
                            step: 10.0,
                            value: $store.maxDistance
                        )

                        LuxurySliderRow(
                            title: "Cỡ Chữ Nhãn ESP (Text Size)",
                            icon: "textformat.size",
                            iconColor: Color.yellow,
                            unit: "pt",
                            range: 10.0...22.0,
                            step: 1.0,
                            value: $store.textSize
                        )

                        LuxurySliderRow(
                            title: "Độ Dày Nét Vẽ (Line Thickness)",
                            icon: "lineweight",
                            iconColor: Color.purple,
                            unit: "px",
                            range: 1.0...4.5,
                            step: 0.2,
                            value: $store.thicknessSize
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - TAB 3: MISC FEATURES VIEW (Chuẩn Zrxipa + UI AMOLED)
public struct MiscFeaturesTabContentView: View {
    @ObservedObject var store = ZrxFeaturesConfigStore.shared

    private let amberAccent = Color(red: 255/255, green: 180/255, blue: 0/255)
    private let cardBg = Color(red: 16/255, green: 17/255, blue: 23/255)
    private let cardBorder = Color.white.opacity(0.10)

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Banner Tiêu Đề Misc Features
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(amberAccent.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(amberAccent.opacity(0.4), lineWidth: 1))

                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(amberAccent)
                            .shadow(color: amberAccent.opacity(0.8), radius: 8)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("MISC FEATURES")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("BUFF VIP")
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(amberAccent)
                                .cornerRadius(6)
                        }

                        Text("Đang kích hoạt \(store.activeMiscCount)/\(store.totalMiscCount) tính năng hỗ trợ chiến đấu")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                    }

                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(amberAccent.opacity(0.25), lineWidth: 1))

                // Nhóm 1: Tính Năng Tác Chiến Súng (Combat Weapon Buffs)
                VStack(alignment: .leading, spacing: 8) {
                    Text("TÍNH NĂNG VŨ KHÍ & CHIẾN ĐẤU (WEAPON BUFFS)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 1) {
                        LuxuryFeatureToggleRow(
                            title: "No Recoil (Không Giật Tâm 100%)",
                            subtitle: "Triệt tiêu độ nảy của mọi khẩu súng, đường đạn chụm 1 điểm",
                            icon: "scope",
                            iconColor: amberAccent,
                            isOn: $store.noRecoil
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "No Reload (Bắn Không Cần Nạp Đạn)",
                            subtitle: "Duy trì băng đạn liên tục, không bị ngắt quãng giữa combat",
                            icon: "bolt.badge.a.fill",
                            iconColor: Color.yellow,
                            isOn: $store.noReload
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "Rapid Fire (Bắn Siêu Nhanh x2)",
                            subtitle: "Tăng gấp đôi tốc độ nhả đạn, hạ gục đối thủ trong 0.5 giây",
                            icon: "flame.fill",
                            iconColor: Color.red,
                            isOn: $store.rapidFire
                        )
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                }

                // Nhóm 2: Tính Năng Di Chuyển & Sinh Tồn (Movement & Survival)
                VStack(alignment: .leading, spacing: 8) {
                    Text("DI CHUYỂN & SINH TỒN (SURVIVAL MODS)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 1) {
                        LuxuryFeatureToggleRow(
                            title: "Speed Hacks (Tăng Tốc Chạy 1.8x)",
                            subtitle: "Gia tăng tốc độ chạy bộ và né đạn linh hoạt trong giao tranh",
                            icon: "figure.run.square.stack.fill",
                            iconColor: Color.cyan,
                            isOn: $store.speedHacks
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "Fast Medkit (Bơm Máu Siêu Tốc 1s)",
                            subtitle: "Hồi đầy thanh máu với túi cứu thương chỉ trong tích tắc",
                            icon: "cross.case.fill",
                            iconColor: Color.green,
                            isOn: $store.fastMedkit
                        )
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                }

                // Nhóm 3: Bảo Mật & Quay Màn Hình (Security & Stream Proof)
                VStack(alignment: .leading, spacing: 8) {
                    Text("BẢO MẬT & QUAY PHIM (STREAM PROOF & SECURITY)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(1.0)
                        .padding(.horizontal, 4)

                    VStack(spacing: 1) {
                        LuxuryFeatureToggleRow(
                            title: "Stream Proof (Chống Lộ Menu)",
                            subtitle: "Tự động ẩn toàn bộ giao diện hack khi quay clip màn hình hoặc livestream",
                            icon: "video.slash.fill",
                            iconColor: Color.purple,
                            isOn: $store.streamProof
                        )

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 10)

                        LuxuryFeatureToggleRow(
                            title: "Anti-Ban Safe Telemetry Buffer",
                            subtitle: "Khóa gửi log crash, chống quét file bất thường từ hệ thống kiểm tra",
                            icon: "shield.checkered",
                            iconColor: Color(red: 0/255, green: 230/255, blue: 118/255),
                            isOn: $store.antiBanMode
                        )
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }
}
