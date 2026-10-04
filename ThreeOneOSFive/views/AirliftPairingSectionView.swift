import SwiftUI

/// Giao diện quản lý ghép nối AirLift (RemotePairing / Loopback Tunnel)
/// Giúp người dùng trên iOS 18.7.2+, iOS 27 chính thức, iOS 28... kích hoạt quyền can thiệp container game
struct AirliftPairingSectionView: View {
    @ObservedObject private var bridge = AirliftBridge.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Trạng thái ghép đôi (Pairing status)
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chứng chỉ ghép đôi")
                            .font(.subheadline.weight(.semibold))
                        Text(bridge.isPaired ? "Đã ghép đôi (Sẵn sàng)" : "Chưa ghép đôi (Cần thiết lập)")
                            .font(.caption)
                            .foregroundStyle(bridge.isPaired ? .green : .secondary)
                    }
                } icon: {
                    Image(systemName: bridge.isPaired ? "link.badge.plus" : "link.slash")
                        .foregroundStyle(bridge.isPaired ? .green : .orange)
                        .font(.title3)
                }
                Spacer()
                if bridge.isPaired {
                    Button(role: .destructive) {
                        try? bridge.deletePairingRecord()
                    } label: {
                        Text("Xóa")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Nút ghép đôi
            if bridge.isPairingInProgress {
                Button(role: .cancel) {
                    bridge.stopBonjourPairingHost()
                } label: {
                    Label("Dừng ghép đôi", systemImage: "xmark.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else if !bridge.isPaired {
                Button {
                    bridge.startBonjourPairingHost()
                } label: {
                    Label("Bắt đầu ghép đôi", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
