import SwiftUI

public struct MiscTabView: View {
    @ObservedObject var configManager: LocalConfigManager

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Tab
                headerSection

                // Section 1: Hỗ Trợ Chiến Đấu
                VStack(spacing: 10) {
                    SectionHeaderView(title: "HỖ TRỢ CHIẾN ĐẤU")
                    CardContainer {
                        SettingToggleRow(
                            title: "Giảm Giật Súng (NoRecoil)",
                            subtitle: "Tâm súng cố định, giảm rung giật khi xả đạn",
                            isOn: $configManager.noRecoil
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Tăng Sát Thương (BuffDame)",
                            subtitle: "Khuếch đại dame đạn chạm mục tiêu",
                            isOn: $configManager.buffDame
                        )
                    }
                }

                // Section 2: Góc Nhìn Camera
                VStack(spacing: 10) {
                    SectionHeaderView(title: "GÓC NHÌN & CAMERA")
                    CardContainer {
                        SettingToggleRow(
                            title: "Camera Xa Góc Rộng (CamXa)",
                            subtitle: "Mở rộng góc nhìn toàn cảnh chiến trường",
                            isOn: $configManager.camXa
                        )
                        if configManager.camXa {
                            CardDivider()
                            SettingSliderRow(
                                title: "Độ Cao Camera (CamXaFloat)",
                                subtitle: "Tỷ lệ zoom out camera ngoại cảnh",
                                value: $configManager.camXaFloat,
                                range: 1.0...2.5,
                                step: 0.1,
                                unit: "x"
                            )
                        }
                    }
                }

                // Section 3: Di Chuyển & Tiện Ích
                VStack(spacing: 10) {
                    SectionHeaderView(title: "TIỆN ÍCH & TỐC ĐỘ")
                    CardContainer {
                        speedHackRow
                        CardDivider()
                        SettingToggleRow(
                            title: "Hạ Dù Nhanh (FastParachute)",
                            subtitle: "Rút ngắn thời gian tiếp đất từ máy bay",
                            isOn: $configManager.fastParachute
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Chế Độ Tàng Hình (GhostMode)",
                            subtitle: "Ẩn danh chuyển động khi giao tranh",
                            isOn: $configManager.ghostMode
                        )
                        CardDivider()
                        SettingToggleRow(
                            title: "Nút Đăng Nhập Khách (ShowGuestBtn)",
                            subtitle: "Hiển thị nút Guest ID tại sảnh đăng nhập",
                            isOn: $configManager.showGuestBtn
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
                Text("MISC")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Tùy chỉnh góc nhìn camera, tốc độ và hỗ trợ chiến đấu")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var speedHackRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tốc Độ Di Chuyển (SpeedHack)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Hệ số gia tốc nhân vật")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                speedOptionButton(title: "1x (Chuẩn)", value: 1)
                speedOptionButton(title: "2x (Nhanh)", value: 2)
                speedOptionButton(title: "3x (VIP)", value: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func speedOptionButton(title: String, value: Int) -> some View {
        let isSelected = configManager.speedHack == value
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                configManager.speedHack = value
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
