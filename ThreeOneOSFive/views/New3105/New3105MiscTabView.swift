import SwiftUI

/// =========================================================================
/// New3105MiscTabView
/// Tab 3: MISC (Quản lý các cấu hình phụ trợ theo mục 5)
/// - NoRecoil (Switch)
/// - CamXaFloat (Slider số thực 1.0 - 5.0)
/// - SpeedHack (Lựa chọn hệ số 1 - 5)
/// - CamXa, FastParachute, GhostMode, ShowGuestBtn, BuffDame
/// - Đánh dấu minh bạch: Không can thiệp tiến trình bộ nhớ, nêu rõ thành phần tích hợp runtime còn thiếu.
/// =========================================================================
public struct New3105MiscTabView: View {
    @ObservedObject var configManager: LocalConfigManager

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Nhóm 1: Các Trường Đã Xác Minh (NoRecoil, CamXaFloat, SpeedHack)
                verifiedMiscSection

                // Nhóm 2: Các Trường Bổ Trợ Khác
                additionalFlagsSection

                // Nhóm 3: Thông Báo Kỹ Thuật (Tuân thủ mục 5)
                runtimeNoticeCard

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
                Text("MISC CONFIGURATION")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Cấu hình thông số phụ trợ trong localConfig.json")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Verified Misc Section
    private var verifiedMiscSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "CÁC TRƯỜNG THIẾT LẬP XÁC MINH")

            VStack(spacing: 16) {
                // NoRecoil Switch
                toggleRow(
                    title: "NoRecoil",
                    subtitle: "Cấu hình giảm độ giật của súng (NoRecoil)",
                    isOn: $configManager.noRecoil
                )

                dividerLine

                // CamXaFloat Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CamXaFloat")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1fx", configManager.camXaFloat))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }

                    Text("Hệ số khoảng cách camera góc nhìn rộng (Phạm vi: 1.0 - 5.0)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))

                    Slider(value: $configManager.camXaFloat, in: 1.0...5.0, step: 0.1)
                        .accentColor(Color.white)
                }
                .padding(.horizontal, 14)

                dividerLine

                // SpeedHack Stepper / Selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SpeedHack")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Tốc độ x\(configManager.speedHack)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Text("Hệ số tốc độ di chuyển trong cấu hình (1x đến 5x)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))

                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { speed in
                            speedOptionButton(speed: speed)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
    }

    // MARK: - Additional Flags Section
    private var additionalFlagsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "CÁC TRƯỜNG BỔ TRỢ KHÁC TỪ FILE")

            VStack(spacing: 0) {
                toggleRow(
                    title: "CamXa",
                    subtitle: "Kích hoạt chức năng Camera xa (CamXa)",
                    isOn: $configManager.camXa
                )

                dividerLine

                toggleRow(
                    title: "FastParachute",
                    subtitle: "Cấu hình nhảy dù nhanh (FastParachute)",
                    isOn: $configManager.fastParachute
                )

                dividerLine

                toggleRow(
                    title: "GhostMode",
                    subtitle: "Cấu hình chế độ tàng hình/bóng ma (GhostMode)",
                    isOn: $configManager.ghostMode
                )

                dividerLine

                toggleRow(
                    title: "ShowGuestBtn",
                    subtitle: "Hiển thị nút khách đăng nhập (ShowGuestBtn)",
                    isOn: $configManager.showGuestBtn
                )

                dividerLine

                toggleRow(
                    title: "BuffDame",
                    subtitle: "Cấu hình tăng sát thương (BuffDame)",
                    isOn: $configManager.buffDame
                )
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
    }

    // MARK: - Runtime Notice Card (Tuân thủ mục 5)
    private var runtimeNoticeCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "shield.slash")
                .foregroundColor(Color(white: 0.7))
                .font(.system(size: 14))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("GIỚI HẠN VÀ THÀNH PHẦN THIẾU")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Ứng dụng chỉ đóng vai trò trình đọc/ghi cấu hình file localConfig.json và chuẩn bị patch. Ứng dụng KHÔNG tự can thiệp tiến trình game, không sửa đổi bộ nhớ runtime trực tiếp và không bypass anti-cheat.\n\nThành phần còn thiếu để thực thi in-game: Runtime InjectFix (IFix) hoặc Dynamic Library trong game để nạp Assembly-CSharp-patch.bytes.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(white: 0.05))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.15), lineWidth: 1))
    }

    // MARK: - Helpers
    private func speedOptionButton(speed: Int) -> some View {
        let isSelected = configManager.speedHack == speed
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                configManager.speedHack = speed
            }
        }) {
            Text("\(speed)x")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
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
