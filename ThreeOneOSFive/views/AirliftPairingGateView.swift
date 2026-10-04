import SwiftUI
import UIKit

/// Màn hình Cổng Ghép Đôi AirLift bắt buộc cho các phiên bản iOS cao (iOS 18.7.2+, iOS 27 chính thức, iOS 28...)
/// Đáp ứng yêu cầu:
/// 1. Sau khi nhập Key hợp lệ, trên iOS cao SẼ KHÔNG HIỆN Free Fire cho đến khi ghép đôi thành công.
/// 2. Khi nhấn "Bắt đầu ghép đôi", hiển thị thông báo "Cho phép", tự động sao chép mã PIN và mở Cài đặt -> Chế độ nhà phát triển.
/// 3. Hiển thị đúng tên App thương hiệu (CheatStore VN, VeLix VN, Venom VN) để người dùng chọn ghép đôi trong Cài đặt iOS.
struct AirliftPairingGateView: View {
    @ObservedObject private var bridge = AirliftBridge.shared
    @ObservedObject private var licenseManager = CheatStoreLicenseManager.shared

    private var theme: AppBrandingTheme { AppBrandingTheme.current }
    private var osDisplay: String { "iOS \(AppInfo.osVersion)" }

    @State private var showPromptAlert: Bool = false
    @State private var showCheckAlert: Bool = false
    @State private var checkAlertMessage: String = ""
    @State private var isChecking: Bool = false
    @State private var copiedPIN: Bool = false

    var body: some View {
        ZStack {
            // Nền đen sâu True Black Void
            Color.black.ignoresSafeArea()

            // Vầng sáng LED Ambient Gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.12),
                    Color.clear
                ]),
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header thanh trên: Logo + Tên App + Nút Đổi Key
                headerBarView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Huy hiệu cảnh báo yêu cầu ghép đôi cho iOS cao
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.orange)

                            Text("\(osDisplay.uppercased()) • YÊU CẦU GHÉP ĐÔI THIẾT BỊ")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.orange)
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(999)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        .padding(.top, 10)

                        // Tiêu đề & Giải thích
                        VStack(spacing: 6) {
                            Text("Kích Hoạt Quyền Container")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text("Thiết bị của bạn đang chạy \(osDisplay). Để vượt rào Sandbox và nạp mod vào Free Fire an toàn, bạn cần hoàn tất ghép đôi thiết bị một lần duy nhất.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }

                        // Thẻ Card hiển thị Mã PIN ghép đôi lớn
                        VStack(spacing: 12) {
                            HStack {
                                Text("MÃ PIN GHÉP ĐÔI TỰ ĐỘNG")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .tracking(1.5)
                                Spacer()
                                if bridge.isPairingInProgress {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                        Text("Đang phát sóng")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.green)
                                    }
                                }
                            }

                            HStack(spacing: 14) {
                                Text(bridge.pairPin ?? "------")
                                    .font(.system(size: 38, weight: .black, design: .monospaced))
                                    .foregroundColor(Color(red: 0.35, green: 0.82, blue: 1.0))
                                    .tracking(6)

                                Button(action: {
                                    if let pin = bridge.pairPin {
                                        UIPasteboard.general.string = pin
                                        copiedPIN = true
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            copiedPIN = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedPIN ? "checkmark.circle.fill" : "doc.on.doc")
                                        Text(copiedPIN ? "Đã chép" : "Sao chép")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(copiedPIN ? .green : .white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            Text("Mã PIN này dùng để xác nhận trong mục Chế độ nhà phát triển của iPhone")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1.2))
                        .padding(.horizontal, 20)

                        // Nút chính: BẮT ĐẦU GHÉP ĐÔI (Mở alert Cho Phép & Vào Cài đặt)
                        Button(action: {
                            handleStartPairing()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Bắt Đầu Ghép Đôi")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.65, blue: 1.0),
                                        Color(red: 0.0, green: 0.45, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.0, green: 0.55, blue: 1.0).opacity(0.4), radius: 14, y: 5)
                        }
                        .padding(.horizontal, 20)

                        // Hướng dẫn 4 bước trực quan đúng như Delta Proxy
                        VStack(alignment: .leading, spacing: 14) {
                            Text("HƯỚNG DẪN 4 BƯỚC GHÉP ĐÔI NHANH")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.7))
                                .tracking(1.2)

                            guideStepRow(
                                step: "1",
                                title: "Nhấn \"Bắt đầu ghép đôi\"",
                                detail: "Hệ thống sẽ tự động sao chép mã PIN 6 số vào bộ nhớ tạm của bạn."
                            )

                            guideStepRow(
                                step: "2",
                                title: "Nhấn \"Cho phép\" mở Cài đặt",
                                detail: "Hệ thống sẽ chuyển hướng bạn trực tiếp vào ứng dụng Cài đặt của iPhone."
                            )

                            guideStepRow(
                                step: "3",
                                title: "Vào Chế độ nhà phát triển",
                                detail: "Mở Quyền riêng tư & Bảo mật > Chế độ nhà phát triển (hoặc mục Nhà phát triển)."
                            )

                            guideStepRow(
                                step: "4",
                                title: "Chọn \"\(theme.appTitle)\" & Nhập PIN",
                                detail: "Tìm tên ứng dụng \"\(theme.appTitle)\" trong danh sách ghép đôi từ xa và dán mã PIN."
                            )
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // Nút phụ: KIỂM TRA KẾT NỐI / ĐÃ GHÉP ĐÔI XONG
                        Button(action: {
                            checkPairingStatus()
                        }) {
                            HStack(spacing: 8) {
                                if isChecking {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(Color.green)
                                }
                                Text("Tôi Đã Ghép Đôi Xong (Kiểm Tra)")
                                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                        }
                        .disabled(isChecking)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            if bridge.pairPin == nil && !bridge.isPaired {
                bridge.startBonjourPairingHost()
            }
            Task {
                _ = await bridge.checkLoopbackTunnel()
            }
        }
        // Alert Cho Phép Mở Cài Đặt
        .alert("Yêu Cầu Ghép Đôi Thiết Bị", isPresented: $showPromptAlert) {
            Button("Cho Phép & Mở Cài Đặt", role: .none) {
                if let pin = bridge.pairPin {
                    UIPasteboard.general.string = pin
                }
                AirliftBridge.openDeveloperSettings()
            }
            Button("Để Sau", role: .cancel) {}
        } message: {
            let pinStr = bridge.pairPin ?? ""
            Text("Mã PIN ghép đôi của bạn là: \(pinStr) (Đã được tự động sao chép).\n\nVui lòng vào Cài đặt > Quyền riêng tư & Bảo mật > Chế độ nhà phát triển (hoặc mục Nhà phát triển), chọn \"\(theme.appTitle)\" và dán mã PIN để hoàn tất ghép đôi.")
        }
        // Alert kết quả kiểm tra
        .alert("Trạng Thái Ghép Đôi", isPresented: $showCheckAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(checkAlertMessage)
        }
    }

    // MARK: - Header Bar
    private var headerBarView: some View {
        HStack(spacing: 12) {
            CheatStoreLogoView(size: 38, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.appTitle)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.white)

                Text("AirLift Gatekeeper • \(osDisplay)")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.orange)
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                licenseManager.deactivate()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("Đổi Key")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.4))
    }

    // MARK: - Helper Guide Step
    private func guideStepRow(step: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.55, blue: 1.0).opacity(0.2))
                    .frame(width: 26, height: 26)
                Text(step)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    // MARK: - Actions
    private func handleStartPairing() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if bridge.pairPin == nil || !bridge.isPairingInProgress {
            bridge.startBonjourPairingHost()
        }
        if let pin = bridge.pairPin {
            UIPasteboard.general.string = pin
            copiedPIN = true
        }
        showPromptAlert = true
    }

    private func checkPairingStatus() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isChecking = true
        bridge.refreshState()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isChecking = false
            if bridge.isPaired {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                checkAlertMessage = "Ghép đôi thiết bị thành công! Quyền can thiệp container Free Fire đã sẵn sàng."
                showCheckAlert = true
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                checkAlertMessage = "Chưa phát hiện file ghép đôi từ hệ thống. Hãy đảm bảo bạn đã mở Cài đặt > Chế độ nhà phát triển, nhấn vào \"\(theme.appTitle)\" và nhập mã PIN: \(bridge.pairPin ?? "")."
                showCheckAlert = true
            }
        }
    }
}
