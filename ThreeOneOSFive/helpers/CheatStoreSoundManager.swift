import Foundation
import AVFoundation
import UIKit

/// Trình quản lý âm thanh tương tác cao cấp (Apple Pay Sound & Haptic Feedback)
final class CheatStoreSoundManager: ObservableObject {
    static let shared = CheatStoreSoundManager()

    private var audioPlayer: AVAudioPlayer?
    private var isAudioSessionConfigured = false

    private init() {
        configureAudioSession()
        prepareAudioPlayer()
    }

    private func configureAudioSession() {
        guard !isAudioSessionConfigured else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            isAudioSessionConfigured = true
        } catch {
            print("[SoundManager] Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func prepareAudioPlayer() {
        // Tìm file applepay.mp3 hoặc applepay.wav trong bundle
        let soundURL = Bundle.main.url(forResource: "applepay", withExtension: "mp3") ??
                       Bundle.main.url(forResource: "applepay", withExtension: "wav")

        guard let url = soundURL else {
            print("[SoundManager] applepay sound file not found in main bundle")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 0.95
        } catch {
            print("[SoundManager] Failed to init AVAudioPlayer: \(error.localizedDescription)")
        }
    }

    /// Phát âm thanh Apple Pay thành công cùng phản hồi rung xúc giác (Haptic)
    func playSuccessSound() {
        // Rung Haptic phản hồi cao cấp chuẩn Apple
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // Phát âm thanh
        if audioPlayer == nil {
            prepareAudioPlayer()
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.audioPlayer else { return }
            if player.isPlaying {
                player.stop()
            }
            player.currentTime = 0
            player.play()
        }
    }

    /// Rung nhẹ khi chuyển tab (Tương tự Limelight Dock haptic)
    func playTabSwitchHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
    }
}
