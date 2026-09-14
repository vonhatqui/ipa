import SwiftUI

struct EspSettingsSheetView: View {
    @ObservedObject var espManager = EspConfigManager.shared
    @Environment(\.dismiss) private var dismiss

    var onSaveAndApply: () -> Void

    private let brandBlue = Color(red: 0.00, green: 0.72, blue: 1.00)
    private let brandBlueDark = Color(red: 0.00, green: 0.45, blue: 0.90)
    private let darkBackground = Color(red: 0.04, green: 0.06, blue: 0.11)
    private let cardBackground = Color(red: 0.07, green: 0.10, blue: 0.18)

    @State private var showSavedToast = false

    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Nhóm 1: Các Công Tắc Tính Năng
                        featureTogglesSection

                        // Nhóm 2: Khoảng Cách Quét
                        distanceSliderSection

                        // Nhóm 3: Chọn Màu Sắc ESP
                        colorPickerSection

                        // Nhóm 4: Nút Lưu & Khôi Phục
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 24)
                }
            }

            // Toast thông báo đã lưu
            if showSavedToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("Đã lưu và áp dụng cấu hình ESP!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.08, green: 0.14, blue: 0.22))
                    .cornerRadius(20)
                    .overlay(
                        Capsule().stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.green.opacity(0.3), radius: 10)
                    .padding(.top, 16)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(brandBlue)
                    Text("CÀI ĐẶT ĐỊNH VỊ ESP 2.0")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("Tùy chỉnh tính năng hiển thị trực tiếp trong game")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.gray.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .background(Color(red: 0.05, green: 0.07, blue: 0.13))
    }

    // MARK: - Section 1: Công Tắc Bật / Tắt
    private var featureTogglesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CÁC THÀNH PHẦN HIỂN THỊ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(brandBlue)
                .tracking(1)

            VStack(spacing: 1) {
                toggleRow(
                    icon: "viewfinder",
                    title: "Khung Box 2D",
                    subtitle: "Hiện khung vuông bao quanh vị trí địch",
                    isOn: $espManager.isBoxEnabled
                )

                Divider().background(Color.white.opacity(0.06))

                toggleRow(
                    icon: "person.text.rectangle.fill",
                    title: "Tên Địch (Player Name)",
                    subtitle: "Hiện tên game nhân vật trên đầu",
                    isOn: $espManager.isNameEnabled
                )

                Divider().background(Color.white.opacity(0.06))

                toggleRow(
                    icon: "heart.fill",
                    title: "Thanh Máu (Player HP)",
                    subtitle: "Hiện thanh hiển thị lượng máu còn lại",
                    isOn: $espManager.isHPEnabled
                )

                Divider().background(Color.white.opacity(0.06))

                toggleRow(
                    icon: "ruler.fill",
                    title: "Số Mét Khoảng Cách",
                    subtitle: "Hiện khoảng cách chính xác tới địch",
                    isOn: $espManager.isDistanceTextEnabled
                )

                Divider().background(Color.white.opacity(0.06))

                toggleRow(
                    icon: "scope",
                    title: "Ghim Tâm (AimNeck 2.0)",
                    subtitle: "Hỗ trợ kéo tâm tự động vào vùng cổ",
                    isOn: $espManager.isAimEnabled
                )

                Divider().background(Color.white.opacity(0.06))

                toggleRow(
                    icon: "point.topleft.down.curvedto.point.bottomright.up",
                    title: "Đường Kẻ Line (Tia Chỉ Hướng)",
                    subtitle: "Khuyên TẮT để chống lag và văng game",
                    warningBadge: "Dễ lag",
                    isOn: $espManager.isLineEnabled
                )
            }
            .padding(14)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        warningBadge: String? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isOn.wrappedValue ? brandBlue : Color.gray.opacity(0.5))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    if let badge = warningBadge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.14))
                            .cornerRadius(4)
                    }
                }

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(brandBlue)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Section 2: Slider Khoảng Cách
    private var distanceSliderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KHOẢNG CÁCH QUÉT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(brandBlue)
                    .tracking(1)

                Spacer()

                HStack(spacing: 3) {
                    Text("\(Int(espManager.scanDistance))")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(brandBlue)
                    Text("Mét")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(brandBlue.opacity(0.12))
                .cornerRadius(8)
            }

            VStack(spacing: 10) {
                Slider(
                    value: $espManager.scanDistance,
                    in: 50...150,
                    step: 5
                )
                .tint(brandBlue)

                HStack {
                    Text("50m (Gần)")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)

                    Spacer()

                    Text("90m (Chuẩn)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(brandBlue)

                    Spacer()

                    Text("150m (Xa)")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }

                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.yellow)

                    Text("Khuyên dùng: 80 - 100m để mượt mà nhất và không bị giật.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(8)
            }
            .padding(14)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Section 3: Chọn Màu Sắc
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MÀU SẮC KHUNG BOX & ESP")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(brandBlue)
                .tracking(1)

            HStack(spacing: 12) {
                ForEach(espManager.colorOptions) { option in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            espManager.colorIndex = option.id
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 38, height: 38)
                                    .shadow(color: option.color.opacity(espManager.colorIndex == option.id ? 0.8 : 0.2), radius: 6)

                                if espManager.colorIndex == option.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundStyle(.black)
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: espManager.colorIndex == option.id ? 2.5 : 0)
                            )

                            Text(option.name)
                                .font(.system(size: 10, weight: espManager.colorIndex == option.id ? .bold : .medium))
                                .foregroundStyle(espManager.colorIndex == option.id ? .white : .gray)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(14)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Section 4: Nút Hành Động
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            // Nút Lưu & Áp Dụng
            Button {
                espManager.syncDirectlyToGameContainer()
                onSaveAndApply()
                withAnimation {
                    showSavedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation {
                        showSavedToast = false
                    }
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("LƯU & ÁP DỤNG NGAY")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [brandBlue, brandBlueDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: brandBlue.opacity(0.4), radius: 10)
            }

            // Nút Khôi Phục Mặc Định
            Button {
                withAnimation {
                    espManager.resetToDefaults()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Khôi Phục Cấu Hình Chuẩn (Khuyên Dùng)")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
            }
        }
        .padding(.top, 8)
    }
}
