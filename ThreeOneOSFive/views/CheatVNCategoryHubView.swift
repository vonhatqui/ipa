import SwiftUI
import UIKit

/// CheatVNCategoryHubView: Giao diện Chọn Chức Năng & INJECTOR Chuẩn Full Black AMOLED
struct CheatVNCategoryHubView: View {
    @AppStorage("cheatstore_selected_game_version") private var selectedGameVersionRaw: String = FreeFireGameVersion.standard.rawValue
    @ObservedObject var patchService = CheatVNPatchService.shared

    var onBackToGameSelection: () -> Void

    // 2 Chức Năng được tích chọn
    @State private var isCheatVNExternalSelected: Bool = true
    @State private var isEspAimSilentSelected: Bool = true

    @State private var showSettings: Bool = false
    @State private var showRestoreConfirm: Bool = false

    // Màu đen tuyệt đối True AMOLED Black
    private let bgVoid = Color.black
    private let cardBg = Color(red: 14/255, green: 14/255, blue: 18/255)
    private let cardBorderInactive = Color.white.opacity(0.12)
    private let cyanAccent = Color(red: 0/255, green: 210/255, blue: 255/255)
    private let greenAccent = Color(red: 0/255, green: 230/255, blue: 118/255)

    private var currentGameVersion: FreeFireGameVersion {
        FreeFireGameVersion(rawValue: selectedGameVersionRaw) ?? .standard
    }

    private var selectedCount: Int {
        (isCheatVNExternalSelected ? 1 : 0) + (isEspAimSilentSelected ? 1 : 0)
    }

    var body: some View {
        ZStack {
            // Nền đen tuyệt đối True Dark AMOLED
            bgVoid.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header (Quay lại + Tiêu đề + Cài đặt)
                topHeaderView
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                // Thanh trạng thái & chuyển đổi Game (Standard / MAX)
                gameVersionSelectorView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Tiêu đề chọn chức năng
                        HStack {
                            Text("CHỌN CHỨC NĂNG (\(selectedCount)/2)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundColor(Color.white.opacity(0.7))

                            Spacer()

                            Text("TÍCH CHỌN RỒI ẤN INJECTOR")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(cyanAccent)
                        }
                        .padding(.horizontal, 4)

                        // 1. Chức năng: CheatVN External
                        featureCard(
                            title: "CheatVN External",
                            badge: "MENU EXTERNAL • V2.4",
                            description: "Menu overlay điều khiển ngoài game, hỗ trợ tuỳ biến Aimbot, ESP & độ nhạy thời gian thực.",
                            logoName: "cheatvn_logo",
                            accentColor: cyanAccent,
                            isSelected: $isCheatVNExternalSelected
                        )

                        // 2. Chức năng: ESP & AIM SILENT
                        featureCard(
                            title: "ESP & AIM SILENT",
                            badge: "HOTFIX IFIX 5 FILES • BYPASS",
                            description: "Nạp chuẩn Tencent IFix: Ghim tâm Aim Silent, ESP Box, ESP Line, ESP Name, chống quét telemetry 100%.",
                            logoName: "esp_aimsilent_logo",
                            accentColor: greenAccent,
                            isSelected: $isEspAimSilentSelected
                        )

                        // Thanh trạng thái Log / Status
                        statusLogBanner
                            .padding(.top, 4)

                        // Khu vực nút INJECTOR & Khởi Chạy Game
                        actionButtonsSection
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            DeltaStyleSettingsView()
        }
        .alert(isPresented: $showRestoreConfirm) {
            Alert(
                title: Text("Khôi Phục Game Gốc?"),
                message: Text("Toàn bộ file mod sẽ được xoá sạch khỏi container Free Fire và trả về game nguyên bản."),
                primaryButton: .destructive(Text("Khôi Phục Gốc")) {
                    patchService.restoreOriginals()
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }

    // MARK: - Header
    private var topHeaderView: some View {
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onBackToGameSelection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("Chọn Game")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(red: 22/255, green: 22/255, blue: 28/255))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("CheatVN External")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("iOS Injector • True Dark AMOLED")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.45))
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(red: 22/255, green: 22/255, blue: 28/255))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Game Selector Row
    private var gameVersionSelectorView: some View {
        HStack(spacing: 10) {
            Button(action: {
                selectedGameVersionRaw = FreeFireGameVersion.standard.rawValue
                patchService.checkPatchStatus()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentGameVersion == .standard ? cyanAccent : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Text("Free Fire Thường")
                        .font(.system(size: 12.5, weight: currentGameVersion == .standard ? .bold : .medium, design: .rounded))
                        .foregroundColor(currentGameVersion == .standard ? .white : Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(red: 16/255, green: 16/255, blue: 22/255))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(currentGameVersion == .standard ? cyanAccent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
            }

            Button(action: {
                selectedGameVersionRaw = FreeFireGameVersion.max.rawValue
                patchService.checkPatchStatus()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentGameVersion == .max ? greenAccent : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Text("Free Fire MAX")
                        .font(.system(size: 12.5, weight: currentGameVersion == .max ? .bold : .medium, design: .rounded))
                        .foregroundColor(currentGameVersion == .max ? .white : Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(red: 16/255, green: 16/255, blue: 22/255))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(currentGameVersion == .max ? greenAccent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Feature Card with Checkbox
    private func featureCard(
        title: String,
        badge: String,
        description: String,
        logoName: String,
        accentColor: Color,
        isSelected: Binding<Bool>
    ) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isSelected.wrappedValue.toggle()
            }
        }) {
            HStack(spacing: 14) {
                // Logo chức năng
                CategoryLogoView(name: logoName, fallbackIcon: "shield.fill", size: 54)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        // Checkbox tích chọn
                        ZStack {
                            Circle()
                                .fill(isSelected.wrappedValue ? accentColor : Color.white.opacity(0.06))
                                .frame(width: 26, height: 26)

                            if isSelected.wrappedValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.black)
                            } else {
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                                    .frame(width: 26, height: 26)
                            }
                        }
                    }

                    Text(badge)
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(accentColor.opacity(0.14))
                        .cornerRadius(6)

                    Text(description)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                }
            }
            .padding(14)
            .background(cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected.wrappedValue ? accentColor.opacity(0.7) : cardBorderInactive, lineWidth: isSelected.wrappedValue ? 1.5 : 1)
            )
            .shadow(color: isSelected.wrappedValue ? accentColor.opacity(0.2) : Color.black.opacity(0.4), radius: isSelected.wrappedValue ? 8 : 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Banner
    private var statusLogBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(patchService.isPatchApplied ? greenAccent : (patchService.isApplying ? Color.orange : Color.white.opacity(0.3)))
                .frame(width: 9, height: 9)
                .shadow(color: (patchService.isPatchApplied ? greenAccent : Color.orange).opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(patchService.isPatchApplied ? "TRẠNG THÁI: ĐÃ NẠP SẴN SÀNG" : (patchService.isApplying ? "ĐANG NẠP PATCH..." : "TRẠNG THÁI: CHƯA NẠP"))
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(patchService.isPatchApplied ? greenAccent : (patchService.isApplying ? Color.orange : Color.white.opacity(0.6)))

                Text(patchService.lastLogMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(red: 16/255, green: 16/255, blue: 20/255))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Nút INJECTOR Chính
            Button(action: {
                guard selectedCount > 0 else { return }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                patchService.applyPatch(
                    injectCheatVN: isCheatVNExternalSelected,
                    injectEspAimSilent: isEspAimSilentSelected
                )
            }) {
                HStack(spacing: 10) {
                    if patchService.isApplying {
                        ProgressView()
                            .tint(.black)
                        Text("ĐANG NẠP VÀO GAME...")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.black)

                        Text("INJECTOR (\(selectedCount) CHỨC NĂNG)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: selectedCount > 0 ? [Color.white, Color(red: 0.9, green: 0.9, blue: 0.95)] : [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
                .shadow(color: selectedCount > 0 ? Color.white.opacity(0.25) : Color.clear, radius: 10, y: 4)
            }
            .disabled(selectedCount == 0 || patchService.isApplying)

            // Nút MỞ GAME (Launch Free Fire)
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                patchService.launchGame(version: currentGameVersion)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("MỞ GAME \(currentGameVersion == .standard ? "FREE FIRE" : "FREE FIRE MAX")")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(red: 22/255, green: 24/255, blue: 32/255))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
            }

            // Nút Khôi Phục Gốc
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showRestoreConfirm = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .bold))
                    Text("Khôi phục game gốc (Gỡ patch sạch)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color.white.opacity(0.55))
                .padding(.top, 4)
            }
        }
    }
}
