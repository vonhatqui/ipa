import SwiftUI
import UIKit

public struct LoginView: View {
    @ObservedObject var licenseManager: LicenseManager
    @State private var inputKey: String = ""
    @State private var isSecured: Bool = true
    @State private var inlineErrorMessage: String? = nil
    @State private var showCopiedDeviceID: Bool = false
    @State private var showSuccessVerification: Bool = false

    public init(licenseManager: LicenseManager = .shared) {
        self.licenseManager = licenseManager
    }

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // 1. Top Brand Header
                    brandHeaderSection

                    // 2. Auth Card: Nhập Key & Kích Hoạt
                    authCardContent
                        .frame(maxWidth: 380)

                    // 3. Hardware Device ID Card
                    deviceHardwareCard
                        .frame(maxWidth: 380)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }

            // MODAL XÁC THỰC THÀNH CÔNG SANG TRỌNG (AMOLED Style, Không tiếng ồn)
            if showSuccessVerification {
                verificationSuccessOverlay
                    .zIndex(100)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if inputKey.isEmpty && !licenseManager.activeKey.isEmpty {
                inputKey = licenseManager.activeKey
            }
        }
    }

    // MARK: - Brand Header
    private var brandHeaderSection: some View {
        VStack(spacing: 12) {
            CheatStoreLogoView(size: 64, cornerRadius: 14)

            VStack(spacing: 4) {
                Text("HYPERK EXTERNAL")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                Text("EXTERNAL CONFIG MANAGER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
            }

            // Server Indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(AppTheme.successGreen)
                    .frame(width: 6, height: 6)
                Text("SERVER ONLINE")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(white: 0.12))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.22), lineWidth: 1))
        }
    }

    // MARK: - Auth Card Content
    private var authCardContent: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Text("XÁC THỰC BẢN QUYỀN")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)

                // Input Field
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(AppTheme.textMuted)
                        .font(.system(size: 14))

                    if isSecured {
                        SecureField("Nhập mã key bản quyền...", text: $inputKey)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    } else {
                        TextField("Nhập mã key bản quyền...", text: $inputKey)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    Button(action: { isSecured.toggle() }) {
                        Image(systemName: isSecured ? "eye.slash" : "eye")
                            .foregroundColor(AppTheme.textSecondary)
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(white: 0.12))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.22), lineWidth: 1))

                // Error Message
                if let err = inlineErrorMessage ?? licenseManager.lastErrorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.dangerRed)
                            .font(.system(size: 12))
                        Text(err)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.dangerRed)
                    }
                }

                // Activate Button
                Button(action: handleActivate) {
                    HStack {
                        if licenseManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                            Text("ĐANG XÁC THỰC...")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("KÍCH HOẠT BẢN QUYỀN")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.35), lineWidth: 1))
                }
                .disabled(licenseManager.isLoading)
            }
            .padding(16)
        }
    }

    // MARK: - Device Hardware Card
    private var deviceHardwareCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("HARDWARE ID (THIẾT BỊ)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    if showCopiedDeviceID {
                        Text("ĐÃ SAO CHÉP")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(AppTheme.successGreen)
                    }
                }

                Button(action: copyDeviceID) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(AppTheme.textSecondary)
                            .font(.system(size: 13))
                        Text(licenseManager.deviceID)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(AppTheme.textSecondary)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.12))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.22), lineWidth: 1))
                }
            }
            .padding(16)
        }
    }

    // MARK: - Verification Success Overlay
    private var verificationSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundColor(AppTheme.successGreen)

                Text("XÁC THỰC THÀNH CÔNG")
                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)

                VStack(spacing: 6) {
                    Text("GÓI: \(licenseManager.planName)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("THỜI HẠN: \(licenseManager.formattedRemainingTime)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .padding(32)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorderFocused, lineWidth: 1.5))
            .shadow(color: Color.black, radius: 20)
        }
    }

    private func handleActivate() {
        inlineErrorMessage = nil
        let trimmed = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            inlineErrorMessage = "Vui lòng nhập mã key bản quyền"
            return
        }

        licenseManager.verifyKey(key: trimmed) { success in
            if success {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.showSuccessVerification = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.showSuccessVerification = false
                        self.licenseManager.confirmActivation()
                    }
                }
            }
        }
    }

    private func copyDeviceID() {
        UIPasteboard.general.string = licenseManager.deviceID
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedDeviceID = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedDeviceID = false
            }
        }
    }
}
