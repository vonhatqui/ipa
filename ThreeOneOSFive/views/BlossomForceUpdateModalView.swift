import SwiftUI
import UIKit

/// Bảng thông báo BẮT BUỘC CẬP NHẬT (Force Update) dành riêng cho các phiên bản cũ
/// Bản mới nhất sẽ KHÔNG bao giờ nhìn thấy bảng này.
struct BlossomForceUpdateModalView: View {
    let info: RemoteAppUpdateInfo

    @State private var isCopied: Bool = false
    @State private var isCheckingAgain: Bool = false
    @State private var isPulsing: Bool = false

    private var targetURL: URL? {
        URL(string: info.update_url)
    }

    var body: some View {
        ZStack {
            // Lớp nền đen mờ bao phủ toàn bộ màn hình, khóa mọi tương tác bên dưới
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            // Thẻ thông báo kính mờ Blossom Glassmorphism
            VStack(spacing: 16) {
                // Header: Biểu tượng cập nhật LED đỏ neon phát sáng
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.20, blue: 0.35).opacity(0.35),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isPulsing ? 1.15 : 0.95)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.30, green: 0.05, blue: 0.10),
                                    Color(red: 0.12, green: 0.02, blue: 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.25, blue: 0.35),
                                            Color(red: 1.0, green: 0.60, blue: 0.20)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(red: 1.0, green: 0.85, blue: 0.90)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.red.opacity(0.8), radius: 6)
                }
                .padding(.top, 4)

                // Tiêu đề thông báo CheatStore Update
                VStack(spacing: 8) {
                    Text("CheatStore Update")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(red: 1.0, green: 0.85, blue: 0.90)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.red.opacity(0.6), radius: 8)

                    // Huy hiệu hiển thị phiên bản & Bắt buộc
                    HStack(spacing: 6) {
                        Text("PHIÊN BẢN v\(info.latest_version)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.18))
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.45), lineWidth: 1)
                            )

                        Text("BẮT BUỘC")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(6)
                    }

                    // Huy hiệu so sánh phiên bản (Bản cũ -> Bản mới)
                    HStack(spacing: 8) {
                        Text("Bản cũ: v\(AppUpdateChecker.currentVersion)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(6)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray)

                        Text("Bản mới: v\(info.latest_version)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.18))
                            .cornerRadius(6)
                    }
                }

                // Dải phân cách gradient
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.6),
                        Color.orange.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)

                // Nội dung thông điệp
                Text(info.message ?? "Phiên bản bạn đang sử dụng đã cũ và đã bị ngắt kết nối. Vui lòng cập nhật lên bản mới nhất để tiếp tục sử dụng CheatStore!")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)

                // Danh sách tính năng mới trong bản cập nhật
                if let changelog = info.changelog, !changelog.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Điểm mới trong bản cập nhật:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.3))

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(changelog, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.green)
                                        .padding(.top, 1.5)

                                    Text(item)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }

                // Nút hành động chính: UPDATE NOW
                Button {
                    if let url = targetURL {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18, weight: .black))

                            Text("UPDATE NOW")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(0.8)
                        }

                        Text("Nhấn để chuyển đến trang tải IPA mới nhất")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.15, blue: 0.25),
                                Color(red: 1.0, green: 0.45, blue: 0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.red.opacity(0.55), radius: 10, y: 3)
                }
                .padding(.top, 4)

                // 2 nút phụ: Sao Chép Link & Kiểm Tra Lại
                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = info.update_url
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                isCopied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Đã sao chép link!" : "Sao Chép Link")
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(isCopied ? Color.green : Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }

                    Button {
                        isCheckingAgain = true
                        Task {
                            await AppUpdateChecker.shared.checkForUpdates()
                            await MainActor.run {
                                isCheckingAgain = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isCheckingAgain {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Kiểm Tra Lại")
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                }

                // Cảnh báo chân trang
                Text("⚠️ Phiên bản cũ không còn được hỗ trợ. Vui lòng cài bản mới để vào app.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                Color(red: 0.082, green: 0.043, blue: 0.137)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.20, blue: 0.35).opacity(0.8),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .cornerRadius(22)
            .shadow(color: Color.red.opacity(0.3), radius: 20)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
