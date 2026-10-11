import SwiftUI

public struct MeTabView: View {
    @ObservedObject var configManager: LocalConfigManager
    @ObservedObject var licenseManager: LicenseManager = .shared
    @State private var profile: DeviceProfileInfo = DeviceProfileService.shared.getCurrentProfile()
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Tab
                headerSection

                // Section 1: Thông Tin Thiết Bị (DEVICE)
                VStack(spacing: 10) {
                    SectionHeaderView(title: "THÔNG TIN THIẾT BỊ")
                    CardContainer {
                        infoRow(label: "Dòng Máy", value: profile.marketingName)
                        CardDivider()
                        infoRow(label: "Mã Phần Cứng", value: profile.modelIdentifier)
                        CardDivider()
                        infoRow(label: "Phiên Bản iOS", value: profile.osVersion)
                        CardDivider()
                        infoRow(label: "Phiên Bản App", value: profile.appVersion)
                        CardDivider()
                        infoRow(label: "Build Number", value: profile.buildNumber)
                    }
                }

                // Section 2: Tài Khoản & Bản Quyền (ACCOUNT)
                VStack(spacing: 10) {
                    SectionHeaderView(title: "TÀI KHOẢN & BẢN QUYỀN")
                    CardContainer {
                        infoRow(label: "Trạng Thái Key", value: licenseManager.isActivated ? "ĐÃ KÍCH HOẠT" : "CHƯA KÍCH HOẠT", isHighlight: licenseManager.isActivated)
                        CardDivider()
                        infoRow(label: "Gói Dịch Vụ", value: licenseManager.planName)
                        CardDivider()
                        infoRow(label: "Thời Hạn Còn Lại", value: licenseManager.formattedRemainingTime)
                        CardDivider()
                        infoRow(label: "Trạng Thái Máy Chủ", value: "ONLINE", isSuccess: true)
                    }
                }

                // Section 3: Quản Lý Cấu Hình & Sao Lưu
                VStack(spacing: 10) {
                    SectionHeaderView(title: "QUẢN LÝ CẤU HÌNH")
                    CardContainer {
                        Button(action: handleRestoreBackup) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Khôi Phục Cấu Hình Từ Bản Sao Lưu")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                }

                // Section 4: Nút Thao Tác (Refresh & Logout)
                VStack(spacing: 10) {
                    Button(action: refreshProfile) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                            Text("LÀM MỚI THÔNG TIN")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(white: 0.12))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.25), lineWidth: 1))
                    }

                    Button(action: handleLogout) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .bold))
                            Text("ĐĂNG XUẤT KEY")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        }
                        .foregroundColor(AppTheme.dangerRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(red: 0.18, green: 0.05, blue: 0.05))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.dangerRed.opacity(0.4), lineWidth: 1))
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ME")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Thông tin thiết bị, hồ sơ bản quyền và khôi phục sao lưu")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func infoRow(label: String, value: String, isHighlight: Bool = false, isSuccess: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            if isSuccess {
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppTheme.successGreen)
                        .frame(width: 6, height: 6)
                    Text(value)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(AppTheme.successGreen)
                }
            } else {
                Text(value)
                    .font(.system(size: 13, weight: isHighlight ? .heavy : .semibold, design: .monospaced))
                    .foregroundColor(isHighlight ? .white : AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func refreshProfile() {
        profile = DeviceProfileService.shared.getCurrentProfile()
        if !licenseManager.activeKey.isEmpty {
            licenseManager.verifyKey(key: licenseManager.activeKey) { _ in }
        }
        alertTitle = "Đã Làm Mới"
        alertMessage = "Thông tin thiết bị và hệ thống đã được cập nhật mới nhất."
        showingAlert = true
    }

    private func handleRestoreBackup() {
        if configManager.restoreFromBackup() {
            alertTitle = "Thành Công"
            alertMessage = "Đã khôi phục thành công cấu hình từ bản sao lưu dự phòng."
        } else {
            alertTitle = "Thông Báo"
            alertMessage = configManager.errorMessage ?? "Không tìm thấy bản sao lưu trước đó."
        }
        showingAlert = true
    }

    private func handleLogout() {
        licenseManager.logout()
    }
}
