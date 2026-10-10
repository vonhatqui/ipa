import SwiftUI

/// =========================================================================
/// New3105EspTabView
/// Tab 2: ESP (Quản lý cấu hình hiển thị định vị theo mục 4)
/// - EspName, EspDistance, EspBox, EspHealth, EspSkeleton, EspTracer
/// - EspMaster, EspLine, EspFov
/// - Cập nhật an toàn vào bộ nhớ và file localConfig.json
/// - Minh bạch về trạng thái runtime in-game
/// =========================================================================
public struct New3105EspTabView: View {
    @ObservedObject var configManager: LocalConfigManager

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Công tắc tổng ESP Master
                masterControlSection

                // Danh sách tính năng ESP chính
                espElementsSection

                // Phần phụ trợ (Line & Fov)
                espAuxSection

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
                Text("ESP")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text("Điều chỉnh các trường định vị visual trong localConfig.json")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Master Control
    private var masterControlSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "CÔNG TẮC TỔNG")

            VStack(spacing: 0) {
                toggleRow(
                    title: "ESP Master Switch",
                    subtitle: "Bật/Tắt đồng loạt toàn bộ hiển thị ESP (EspMaster)",
                    isOn: $configManager.espMaster,
                    isMaster: true
                )
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.25), lineWidth: 1))
        }
    }

    // MARK: - Main ESP Elements
    private var espElementsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "CÁC TRƯỜNG ĐỊNH VỊ CỐT LÕI")

            VStack(spacing: 0) {
                toggleRow(
                    title: "EspBox",
                    subtitle: "Hộp khung viền quanh mục tiêu (EspBox)",
                    isOn: $configManager.espBox
                )

                dividerLine

                toggleRow(
                    title: "EspName",
                    subtitle: "Hiển thị tên người chơi / bot (EspName)",
                    isOn: $configManager.espName
                )

                dividerLine

                toggleRow(
                    title: "EspDistance",
                    subtitle: "Hiển thị khoảng cách theo mét (EspDistance)",
                    isOn: $configManager.espDistance
                )

                dividerLine

                toggleRow(
                    title: "EspHealth",
                    subtitle: "Thanh máu hoặc phần trăm HP (EspHealth)",
                    isOn: $configManager.espHealth
                )

                dividerLine

                toggleRow(
                    title: "EspSkeleton",
                    subtitle: "Khung xương giải phẫu các khớp (EspSkeleton)",
                    isOn: $configManager.espSkeleton
                )

                dividerLine

                toggleRow(
                    title: "EspTracer",
                    subtitle: "Tia định hướng từ nhân vật tới mục tiêu (EspTracer)",
                    isOn: $configManager.espTracer
                )
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
            .opacity(configManager.espMaster ? 1.0 : 0.5)
            .disabled(!configManager.espMaster)
        }
    }

    // MARK: - Aux Section
    private var espAuxSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "TÙY CHỌN BỔ TRỢ")

            VStack(spacing: 0) {
                toggleRow(
                    title: "EspLine",
                    subtitle: "Đường kẻ chỉ định vị trí (EspLine)",
                    isOn: $configManager.espLine
                )

                dividerLine

                toggleRow(
                    title: "EspFov",
                    subtitle: "Vòng tròn giới hạn tầm nhìn FOV (EspFov)",
                    isOn: $configManager.espFov
                )
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
            .opacity(configManager.espMaster ? 1.0 : 0.5)
            .disabled(!configManager.espMaster)
        }
    }

    // MARK: - Helpers
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>, isMaster: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: isMaster ? .bold : .semibold))
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
