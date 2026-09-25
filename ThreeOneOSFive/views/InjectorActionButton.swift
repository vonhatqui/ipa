import SwiftUI
import UIKit

/// ButtonStyle tạo hiệu ứng nhấn nhẹ cho nút Inject/Un-inject
private struct InjectorScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Nút bấm chuyển trạng thái INJECT / UN-INJECT phong cách Gaming Tool chuyên nghiệp
struct InjectorActionButton: View {
    let isApplied: Bool
    let isWorking: Bool
    var isUnderMaintenance: Bool = false
    let onToggle: (Bool) -> Void

    @ViewBuilder
    var body: some View {
        if isWorking {
            HStack(spacing: 5) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: BlossomTheme.sakura))
                    .scaleEffect(0.7)
                Text(isApplied ? "Đang gỡ..." : "Injecting...")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(BlossomTheme.sakura)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(BlossomTheme.sakura.opacity(0.12))
            .clipShape(Capsule())
        } else if isUnderMaintenance {
            if isApplied {
                // Nếu đang bảo trì mà trước đó đã lỡ Inject -> Cho phép Un-inject để cứu an toàn
                Button {
                    CheatStoreSoundManager.shared.playTabSwitchHaptic()
                    onToggle(false)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9.5))
                        Text("GỠ BỎ")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.85))
                    .clipShape(Capsule())
                }
                .buttonStyle(InjectorScaleButtonStyle())
            } else {
                // Đang bảo trì
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 9))
                    Text("BẢO TRÌ")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.gray.opacity(0.8))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
        } else if isApplied {
            // ĐÃ INJECT -> Nút UN-INJECT (Khôi phục / Gỡ bỏ)
            Button {
                CheatStoreSoundManager.shared.playTabSwitchHaptic()
                onToggle(false)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 10.5, weight: .bold))
                    Text("UN-INJECT")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.45))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.16))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.red.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: Color.red.opacity(0.25), radius: 5)
            }
            .buttonStyle(InjectorScaleButtonStyle())
        } else {
            // CHƯA INJECT -> Nút INJECT (Bơm vào game)
            Button {
                CheatStoreSoundManager.shared.playTabSwitchHaptic()
                onToggle(true)
            } label: {
                HStack(spacing: 4.5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("INJECT")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [BlossomTheme.sakura, BlossomTheme.sakuraDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: BlossomTheme.sakura.opacity(0.45), radius: 6, x: 0, y: 2)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                )
            }
            .buttonStyle(InjectorScaleButtonStyle())
        }
    }
}
