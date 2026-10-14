import SwiftUI
import UIKit

public struct HyperXProfileView: View {
    @ObservedObject var authManager = HyperXAuthManager.shared
    @State private var showCopiedHWIDToast = false
    @State private var isRefreshing = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Nền trắng tinh khôi, light mode thanh lịch
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // HEADER USER & GÓI KEY
                        profileHeaderCard

                        // CARD 1: THỜI GIAN KEY
                        licenseTimeCard

                        // CARD 2: THIẾT BỊ & PHIÊN BẢN IOS
                        deviceInfoCard

                        // CARD 3: HWID MÁY
                        hwidCard

                        // CARD 4: CÁC NÚT THAO TÁC
                        actionButtonsCard

                        // VERSION & CREDITS
                        VStack(spacing: 4) {
                            Text("HyperXSpace Version 2.0 (Build 8)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            Text("Bảo mật & Tối ưu hoá cho iOS")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Cá Nhân")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            isRefreshing = true
                            let haptic = UIImpactFeedbackGenerator(style: .light)
                            haptic.impactOccurred()
                            _ = await authManager.verifyKey(inputKey: authManager.licenseKey)
                            isRefreshing = false
                        }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile Header Card

    private var profileHeaderCard: some View {
        HStack(spacing: 14) {
            Group {
                if let img = UIImage(named: "HyperXLogo") ?? UIImage(named: "AppIcon60x60") {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(authManager.licenseInfo?.package ?? "HyperX VIP")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.emerald400)
                        .frame(width: 7, height: 7)
                    Text("Đang Kích Hoạt • \(authManager.licenseInfo?.duration ?? "VIP")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }

            Spacer()

            Text("VIP")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(red: 0.14, green: 0.42, blue: 0.96).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Card 1: Thời Gian Key

    private var licenseTimeCard: some View {
        VStack(spacing: 12) {
            cardHeader(title: "THỜI GIAN & BẢN QUYỀN KEY", icon: "key.fill")

            VStack(spacing: 10) {
                infoRow(label: "Gói Sử Dụng", value: authManager.licenseInfo?.package ?? "VIP")
                Divider()
                infoRow(label: "Thời Hạn Gói", value: authManager.licenseInfo?.duration ?? "Không giới hạn")
                Divider()
                infoRow(label: "Ngày Kích Hoạt", value: authManager.licenseInfo?.activatedAt ?? "Hôm nay")
                Divider()
                infoRow(label: "Ngày Hết Hạn", value: authManager.licenseInfo?.expiresAt ?? "Vĩnh Viễn")
                Divider()
                infoRow(
                    label: "Thời Gian Còn Lại",
                    value: "\(authManager.licenseInfo?.daysLeft ?? "—") ngày",
                    highlight: true
                )
                Divider()
                infoRow(
                    label: "Giới Hạn Máy",
                    value: "\(authManager.licenseInfo?.deviceCurrent ?? 1)/\(authManager.licenseInfo?.deviceMax ?? 1) thiết bị"
                )
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Card 2: Thiết Bị & Phiên Bản iOS

    private var deviceInfoCard: some View {
        VStack(spacing: 12) {
            cardHeader(title: "THIẾT BỊ & HỆ ĐIỀU HÀNH", icon: "iphone")

            VStack(spacing: 10) {
                infoRow(label: "Thiết Bị Sử Dụng", value: authManager.deviceModel)
                Divider()
                infoRow(label: "Mã Phần Cứng", value: AppInfo.machineName)
                Divider()
                infoRow(label: "Phiên Bản iOS", value: authManager.iosVersion)
                Divider()
                infoRow(label: "Trạng Thái Sandbox", value: "Hoạt động bình thường")
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Card 3: HWID Máy

    private var hwidCard: some View {
        VStack(spacing: 12) {
            HStack {
                cardHeader(title: "HWID MÁY (DEVICE IDENTIFIER)", icon: "cpu")
                Spacer()
                Button {
                    UIPasteboard.general.string = authManager.hwid
                    showCopiedHWIDToast = true
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedHWIDToast = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedHWIDToast ? "checkmark" : "doc.on.doc")
                        Text(showCopiedHWIDToast ? "Đã sao chép!" : "Sao chép HWID")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.14, green: 0.42, blue: 0.96).opacity(0.10))
                    .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(authManager.hwid)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("HWID dùng để liên kết License Key duy nhất với iPhone này. Khi cần gia hạn hoặc reset máy, vui lòng gửi mã này cho Admin.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            .padding(12)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Card 4: Action Buttons

    private var actionButtonsCard: some View {
        VStack(spacing: 10) {
            // Nút đồng bộ lại License
            Button {
                Task {
                    isRefreshing = true
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    _ = await authManager.verifyKey(inputKey: authManager.licenseKey)
                    isRefreshing = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Đồng Bộ & Làm Mới Thời Gian Key")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.14, green: 0.42, blue: 0.96).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            // Nút Đăng xuất Key
            Button {
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.warning)
                authManager.logout()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Đăng Xuất Key (Đổi Key Khác)")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Views

    private func cardHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
    }

    private func infoRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: highlight ? .bold : .semibold))
                .foregroundStyle(highlight ? Color(red: 0.14, green: 0.42, blue: 0.96) : Color(uiColor: .label))
        }
    }
}
