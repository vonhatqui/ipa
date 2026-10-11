import SwiftUI

public struct EspTabView: View {
    @ObservedObject var configManager: LocalConfigManager

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Tab
                headerSection

                // Section 1: Công Tắc Tổng ESP
                VStack(spacing: 10) {
                    SectionHeaderView(title: "CÔNG TẮC TỔNG")
                    CardContainer {
                        SettingToggleRow(
                            title: "ESP Master Switch",
                            subtitle: "Bật/Tắt toàn bộ hiển thị địch (EspMaster)",
                            isOn: $configManager.espMaster
                        )
                    }
                }

                // Section 2: Nhận Diện & Định Vị (ESP Visuals)
                VStack(spacing: 10) {
                    SectionHeaderView(title: "ĐỊNH VỊ ĐỊCH (RED HIGHLIGHT)")
                    CardContainer {
                        SettingToggleRow(
                            title: "Khung Bao Quát (EspBox)",
                            subtitle: "Vẽ hộp 2D bao quanh kẻ địch",
                            isOn: $configManager.espBox
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Đường Kẻ Chỉ Hướng (EspLine)",
                            subtitle: "Đường kẻ đỏ từ đỉnh/đáy màn hình tới địch",
                            isOn: $configManager.espLine
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Tia Ngắm Địch (EspTracer)",
                            subtitle: "Hiển thị hướng nhìn và tia đạn của địch",
                            isOn: $configManager.espTracer
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Bộ Khung Xương (EspSkeleton)",
                            subtitle: "Hiển thị khung xương chuyển động cơ thể",
                            isOn: $configManager.espSkeleton
                        )
                    }
                }

                // Section 3: Thông Tin Kẻ Địch
                VStack(spacing: 10) {
                    SectionHeaderView(title: "THÔNG TIN KẺ ĐỊCH")
                    CardContainer {
                        SettingToggleRow(
                            title: "Tên Kẻ Địch (EspName)",
                            subtitle: "Hiển thị tên người chơi màu đỏ (+10% kích thước)",
                            isOn: $configManager.espName
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Khoảng Cách (EspDistance)",
                            subtitle: "Hiển thị số mét cự ly tới mục tiêu",
                            isOn: $configManager.espDistance
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Thanh Máu (EspHealth)",
                            subtitle: "Hiển thị lượng HP hiện tại của kẻ địch",
                            isOn: $configManager.espHealth
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
                Text("ESP")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Điều chỉnh định vị xuyên tường và nhận diện kẻ thù")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
