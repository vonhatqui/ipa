import SwiftUI
import UIKit

public struct HyperXLoginView: View {
    @ObservedObject var authManager = HyperXAuthManager.shared
    @State private var inputKey: String = ""
    @State private var showCopiedHWIDToast = false

    public init() {
        _inputKey = State(initialValue: HyperXAuthManager.shared.licenseKey)
    }

    public var body: some View {
        ZStack {
            // Nền trắng tinh tế, phong cách hiện đại không LED
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // LOGO & TIÊU ĐỀ
                VStack(spacing: 12) {
                    Group {
                        if let img = UIImage(named: "HyperXLogo") ?? UIImage(named: "AppIcon60x60") {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                        }
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

                    VStack(spacing: 4) {
                        Text("HyperXSpace")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(uiColor: .label))

                        Text("Hệ Thống Tiện Ích & Mod Trực Tuyến")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .padding(.bottom, 32)

                if authManager.isKeyVerified {
                    // MÀN HÌNH XÁC THỰC THÀNH CÔNG
                    VStack(spacing: 24) {
                        // ICON DẤU TÍCH XANH LÁ & CHỮ XÁC THỰC THÀNH CÔNG
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(Color(red: 0.18, green: 0.80, blue: 0.44))
                                .shadow(color: Color(red: 0.18, green: 0.80, blue: 0.44).opacity(0.25), radius: 12, x: 0, y: 6)

                            Text("Xác Thực Thành Công")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(uiColor: .label))
                        }
                        .padding(.top, 8)

                        // PHẦN THÔNG TIN
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Thông tin")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))

                            Divider()

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Mã Key:")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                                    Spacer()
                                    Text(authManager.licenseKey)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(uiColor: .label))
                                }

                                HStack {
                                    Text("Thiết Bị:")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                                    Spacer()
                                    Text(authManager.deviceModel)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color(uiColor: .label))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("HWID:")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                                    Text(authManager.hwid)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.8)
                        )

                        // NÚT MỞ CHEAT (icon dấu tích hướng 13h)
                        Button {
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            haptic.impactOccurred()
                            authManager.enterApp()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Mở Cheat")
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(red: 0.14, green: 0.42, blue: 0.96))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(red: 0.14, green: 0.42, blue: 0.96).opacity(0.3), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)

                        Button {
                            authManager.isKeyVerified = false
                        } label: {
                            Text("Đổi mã Key khác")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(24)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
                    .padding(.horizontal, 20)
                } else {
                    // FORM NHẬP LICENSE KEY
                    VStack(spacing: 20) {
                        // Ô NHẬP LICENSE KEY
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MÃ BẢN QUYỀN (LICENSE KEY)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))

                            HStack(spacing: 10) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))

                                TextField("Nhập mã key tại đây...", text: $inputKey)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()

                                if !inputKey.isEmpty {
                                    Button {
                                        inputKey = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    if let pasted = UIPasteboard.general.string {
                                        inputKey = pasted.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                                        let haptic = UIImpactFeedbackGenerator(style: .light)
                                        haptic.impactOccurred()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Dán")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 0.14, green: 0.42, blue: 0.96).opacity(0.10))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.8)
                            )
                        }

                        // HIỂN THỊ THÔNG BÁO LỖI NẾU CÓ
                        if let err = authManager.errorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.red)
                                Text(err)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.red)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // NÚT ĐĂNG NHẬP / XÁC THỰC
                        Button {
                            Task {
                                let haptic = UIImpactFeedbackGenerator(style: .medium)
                                haptic.impactOccurred()
                                _ = await authManager.verifyKey(inputKey: inputKey)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Xác Thực Key & Vào App")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Color(red: 0.14, green: 0.42, blue: 0.96)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(red: 0.14, green: 0.42, blue: 0.96).opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(authManager.isLoading || inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(authManager.isLoading || inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)

                        // THÔNG TIN HWID MÁY
                        VStack(spacing: 6) {
                            HStack {
                                Text("HWID Máy:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(uiColor: .secondaryLabel))
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
                                        Text(showCopiedHWIDToast ? "Đã chép!" : "Sao chép HWID")
                                        Image(systemName: showCopiedHWIDToast ? "checkmark" : "doc.on.doc")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.14, green: 0.42, blue: 0.96))
                                }
                            }

                            Text(authManager.hwid)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.8)
                        )
                    }
                    .padding(24)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)

                // FOOTER
                Text("HyperXSpace © 2026 — Bảo Vệ Bản Quyền Thiết Bị")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            if !authManager.licenseKey.isEmpty {
                inputKey = authManager.licenseKey
            }
        }
    }
}
