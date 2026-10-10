import SwiftUI

/// =========================================================================
/// New3105MeTabView
/// Tab 4: ME (Trang hồ sơ thiết bị và trạng thái hệ thống theo mục 7)
/// Bố cục chuẩn:
/// ME
/// DEVICE
/// Device Model       ... (lấy thật từ kernel)
/// iOS Version        ...
/// App Version        ...
/// Build Number       ...
/// ACCOUNT
/// Key Status         NOT CONFIGURED
/// Expiration         NOT CONFIGURED
/// Server Status      OFFLINE
/// [ REFRESH ]
/// [ LOG OUT ]
/// =========================================================================
public struct New3105MeTabView: View {
    @ObservedObject var configManager: LocalConfigManager
    @ObservedObject var licenseManager: CheatStoreLicenseManager = .shared
    @State private var profile: DeviceProfileInfo = DeviceProfileService.shared.getCurrentProfile()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header ME
                headerSection

                // Khối DEVICE
                deviceInfoCard

                // Khối ACCOUNT
                accountInfoCard

                // Khối Action Buttons: [ REFRESH ] & [ LOG OUT ]
                actionButtonsSection

                // Khối Quản Lý File Cấu Hình (Khôi phục sao lưu)
                configManagementCard

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            refreshProfileSilently()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ME")
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                Text("Thông tin thiết bị và trạng thái kết nối hệ thống")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - DEVICE Card
    private var deviceInfoCard: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "DEVICE")

            VStack(spacing: 0) {
                infoRow(label: "Device Model", value: profile.marketingName)
                dividerLine
                infoRow(label: "Hardware ID", value: profile.modelIdentifier)
                dividerLine
                infoRow(label: "iOS Version", value: profile.osVersion)
                dividerLine
                infoRow(label: "App Version", value: profile.appVersion)
                dividerLine
                infoRow(label: "Build Number", value: profile.buildNumber)
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
    }

    // MARK: - ACCOUNT Card
    private var accountInfoCard: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "ACCOUNT & SERVER KEY")

            VStack(spacing: 0) {
                infoRow(label: "Key Status", value: licenseManager.isActivated ? "HỢP LỆ (ACTIVE)" : "CHƯA KÍCH HOẠT", isStatus: true)
                dividerLine
                infoRow(label: "License Key", value: licenseManager.activeKey.isEmpty ? "CHƯA CÓ KEY" : licenseManager.activeKey)
                dividerLine
                infoRow(label: "Gói Bản Quyền", value: licenseManager.planName.isEmpty ? "Gói VIP" : licenseManager.planName)
                dividerLine
                infoRow(label: "Thời Hạn Còn Lại", value: licenseManager.formattedRemainingTime)
                dividerLine
                infoRow(label: "Server Status", value: "Online", isStatus: true)
            }
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
    }

    // MARK: - Action Buttons [ REFRESH ] & [ LOG OUT ]
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            // [ REFRESH ]
            Button(action: refreshProfileExplicitly) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                    Text("REFRESH")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
            }

            // [ LOG OUT ]
            Button(action: handleLogout) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("LOG OUT")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color(white: 0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(white: 0.12))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.25), lineWidth: 1))
            }
        }
    }

    // MARK: - Config Management Card
    private var configManagementCard: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "QUẢN LÝ LOCALCONFIG.JSON")

            VStack(spacing: 12) {
                HStack {
                    Text("Bản sao lưu (.bak):")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.7))
                    Spacer()
                    Text(configManager.hasBackup ? "CÓ SẴN" : "CHƯA TẠO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(configManager.hasBackup ? Color.white : Color(white: 0.4))
                }

                if let lastSaved = configManager.lastSavedTime {
                    HStack {
                        Text("Lần lưu gần nhất:")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.7))
                        Spacer()
                        Text(formatDate(lastSaved))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(white: 0.6))
                    }
                }

                HStack(spacing: 10) {
                    Button(action: {
                        let ok = configManager.saveConfig()
                        alertTitle = ok ? "Thành Công" : "Lỗi"
                        alertMessage = ok ? "Đã lưu và đồng bộ localConfig.json an toàn." : (configManager.errorMessage ?? "Lưu thất bại.")
                        showingAlert = true
                    }) {
                        Text("LƯU NGAY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(white: 0.15))
                            .cornerRadius(6)
                    }

                    Button(action: {
                        let ok = configManager.restoreFromBackup()
                        alertTitle = ok ? "Thành Công" : "Lỗi"
                        alertMessage = ok ? "Đã khôi phục cấu hình từ file localConfig.json.bak." : (configManager.errorMessage ?? "Khôi phục thất bại.")
                        showingAlert = true
                    }) {
                        Text("KHÔI PHỤC BẢN SAO")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(configManager.hasBackup ? .white : Color(white: 0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(configManager.hasBackup ? Color(white: 0.2) : Color(white: 0.08))
                            .cornerRadius(6)
                    }
                    .disabled(!configManager.hasBackup)
                }
            }
            .padding(14)
            .background(Color(white: 0.06))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.18), lineWidth: 1))
        }
    }

    // MARK: - Actions & Helpers
    private func refreshProfileSilently() {
        self.profile = DeviceProfileService.shared.getCurrentProfile()
        _ = configManager.loadConfig()
        Task {
            _ = await licenseManager.verifyCurrentDevice()
        }
    }

    private func refreshProfileExplicitly() {
        self.profile = DeviceProfileService.shared.getCurrentProfile()
        _ = configManager.loadConfig()
        Task {
            let ok = await licenseManager.verifyCurrentDevice()
            await MainActor.run {
                alertTitle = ok ? "Đã Làm Mới" : "Thông Báo"
                alertMessage = ok ? "Đã cập nhật trạng thái bản quyền mới nhất từ máy chủ." : (licenseManager.errorMessage ?? "Key đã hết hạn hoặc không hợp lệ.")
                showingAlert = true
            }
        }
    }

    private func handleLogout() {
        licenseManager.deactivate(withReason: "Đã đăng xuất tài khoản.")
        refreshProfileSilently()
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }

    private func infoRow(label: String, value: String, isStatus: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(white: 0.7))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: isStatus ? .bold : .regular, design: .monospaced))
                .foregroundColor(isStatus ? Color(white: 0.5) : .white)
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

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .medium
        f.dateStyle = .none
        return f.string(from: date)
    }
}
