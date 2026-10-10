import SwiftUI

/// =========================================================================
/// New3105AimTabView
/// Tab 1: AIM (Quản lý cấu hình ngắm bắn theo mục 3)
/// - FovSize (Slider số, phạm vi 10 - 500)
/// - AimTarget (Lựa chọn 0: Đầu, 1: Cổ, 2: Ngực)
/// - AimEnabled, AimSystemEnabled, HeadshotRate
/// - Phần cấu hình chưa xác minh (Unverified configuration)
/// =========================================================================
public struct New3105AimTabView: View {
    @ObservedObject var configManager: LocalConfigManager

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header tóm tắt Tab
                headerSection

                // Nhóm 1: Tính Năng Chính
                mainControlsSection

                // Nhóm 2: Thông Số Ngắm (FovSize & AimTarget)
                aimParametersSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AIM CONFIGURATION")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Điều chỉnh thông số ngắm bắn từ localConfig.json")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Main Controls
    private var mainControlsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "HỆ THỐNG AIM")

            VStack(spacing: 0) {
                toggleRow(
                    title: "Aim System Enabled",
                    subtitle: "Bật/Tắt toàn bộ hệ thống ngắm (AimSystemEnabled)",
                    isOn: $configManager.aimSystemEnabled
                )

                dividerLine

                toggleRow(
                    title: "Aim Enabled",
                    subtitle: "Kích hoạt chức năng khóa mục tiêu (AimEnabled)",
                    isOn: $configManager.aimEnabled
                )
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
    }

    // MARK: - Aim Parameters
    private var aimParametersSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "THÔNG SỐ ĐIỀU CHỈNH")

            VStack(spacing: 16) {
                // FovSize Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("FovSize")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(configManager.fovSize)) px")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }

                    Text("Bán kính vòng tròn ngắm FOV (Phạm vi: 10 - 500)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))

                    Slider(value: $configManager.fovSize, in: 10...500, step: 1)
                        .accentColor(Color.white)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                dividerLine

                // AimTarget Selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("AimTarget")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text(targetName(for: configManager.aimTarget))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Text("Vị trí ưu tiên khóa mục tiêu trên cơ thể nhân vật")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))

                    HStack(spacing: 8) {
                        targetOptionButton(title: "0 • ĐẦU (HEAD)", targetIndex: 0)
                        targetOptionButton(title: "1 • CỔ (NECK)", targetIndex: 1)
                        targetOptionButton(title: "2 • NGỰC (BODY)", targetIndex: 2)
                    }
                }
                .padding(.horizontal, 14)

                dividerLine

                // HeadshotRate Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("HeadshotRate")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(configManager.headshotRate))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }

                    Text("Tỉ lệ ưu tiên kéo tâm vào đầu (0% - 100%)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))

                    Slider(value: $configManager.headshotRate, in: 0...100, step: 5)
                        .accentColor(Color.white)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
    }

    // MARK: - Helpers
    private func targetName(for index: Int) -> String {
        switch index {
        case 0: return "Đầu (Head)"
        case 1: return "Cổ (Neck)"
        case 2: return "Ngực (Chest/Body)"
        default: return "Custom (\(index))"
        }
    }

    private func targetOptionButton(title: String, targetIndex: Int) -> some View {
        let isSelected = configManager.aimTarget == targetIndex
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                configManager.aimTarget = targetIndex
            }
        }) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : Color(white: 0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color(white: 0.12))
                .cornerRadius(6)
        }
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.white))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color(white: 0.15))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}
