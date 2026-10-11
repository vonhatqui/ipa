import SwiftUI

public struct AimTabView: View {
    @ObservedObject var configManager: LocalConfigManager

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Tab
                headerSection

                // Section 1: Hệ Thống Aim
                VStack(spacing: 10) {
                    SectionHeaderView(title: "HỆ THỐNG AIM")
                    CardContainer {
                        SettingToggleRow(
                            title: "Aim System Enabled",
                            subtitle: "Bật/Tắt toàn bộ hệ thống ngắm (AimSystemEnabled)",
                            isOn: $configManager.aimSystemEnabled
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Aim Enabled (Silent Aim)",
                            subtitle: "Khóa mục tiêu tự động (AimEnabled)",
                            isOn: $configManager.aimEnabled
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Vòng Tròn FOV (EspFov)",
                            subtitle: "Hiển thị phạm vi ngắm trên màn hình (EspFov)",
                            isOn: $configManager.espFov
                        )
                    }
                }

                // Section 2: Thông Số Ngắm
                VStack(spacing: 10) {
                    SectionHeaderView(title: "THÔNG SỐ NGẮM BẮN")
                    CardContainer {
                        SettingSliderRow(
                            title: "Kích Thước Vòng FOV",
                            subtitle: "Phạm vi quét mục tiêu (FovSize)",
                            value: $configManager.fovSize,
                            range: 10...500,
                            step: 1,
                            unit: " px"
                        )
                        CardDivider()
                        aimTargetSelectorRow
                        CardDivider()
                        SettingSliderRow(
                            title: "Tỷ Lệ Trúng Đầu (Headshot)",
                            subtitle: "Tần suất đạn vào đầu (HeadshotRate)",
                            value: $configManager.headshotRate,
                            range: 0...100,
                            step: 5,
                            unit: "%"
                        )
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AIM")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Cấu hình thông số ngắm bắn tự động từ localConfig.json")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var aimTargetSelectorRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vị Trí Khóa Mục Tiêu")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Bộ phận ưu tiên khóa đạn (AimTarget)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                targetOptionButton(title: "ĐẦU", index: 0)
                targetOptionButton(title: "CỔ", index: 1)
                targetOptionButton(title: "NGỰC", index: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func targetOptionButton(title: String, index: Int) -> some View {
        let isSelected = configManager.aimTarget == index
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                configManager.aimTarget = index
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .heavy : .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.white : Color(white: 0.14))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.white : Color(white: 0.25), lineWidth: 1)
                )
        }
    }
}
