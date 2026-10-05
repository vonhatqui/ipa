import SwiftUI
import UIKit

/// Hệ thống chủ đề giao diện đồng bộ đa thương hiệu (CheatStore VN, VeLix VN, Venom VN)
/// Tự động nhận diện giao diện, dải màu, logo và liên hệ hỗ trợ dựa theo Bundle ID và CFBundleDisplayName
enum AppBrandingTheme {
    case cheatStore
    case veLix
    case venom

    static var current: AppBrandingTheme {
        let name = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ??
                   (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? ""
        let bundleID = Bundle.main.bundleIdentifier ?? ""

        if name.localizedCaseInsensitiveContains("velix") || bundleID.contains("velix") {
            return .veLix
        } else if name.localizedCaseInsensitiveContains("venom") || bundleID.contains("venom") {
            return .venom
        } else {
            return .cheatStore
        }
    }

    var appTitle: String {
        switch self {
        case .cheatStore: return "CheatStore VN"
        case .veLix: return "VeLix VN"
        case .venom: return "Venom VN"
        }
    }

    var ownerName: String {
        switch self {
        case .cheatStore: return "Võ Nhật Qui (CheatVN)"
        case .veLix: return "Quốc Đại"
        case .venom: return "Trương Thành Trọng"
        }
    }

    var discordTag: String {
        switch self {
        case .cheatStore: return "Discord: @jinwwostore.vn"
        case .veLix: return "Discord: @fsmediateam"
        case .venom: return "Discord: @Venomvn01"
        }
    }

    var zaloURLString: String? {
        switch self {
        case .cheatStore: return "https://zalo.me/0365829172"
        case .veLix: return "https://zalo.me/0796668836"
        case .venom: return "https://zalo.me/095826667"
        }
    }

    var telegramURLString: String? {
        switch self {
        case .cheatStore: return "https://t.me/vassco911"
        case .veLix: return "https://t.me/TNQDai"
        case .venom: return nil // Venom VN: tele không có
        }
    }

    var colorVoid: Color {
        switch self {
        case .cheatStore: return Color.black
        case .veLix: return Color(red: 2/255, green: 5/255, blue: 18/255)
        case .venom: return Color(red: 8/255, green: 3/255, blue: 18/255)
        }
    }

    var colorPanel: Color {
        switch self {
        case .cheatStore: return Color(red: 16/255, green: 16/255, blue: 22/255)
        case .veLix: return Color(red: 8/255, green: 16/255, blue: 34/255)
        case .venom: return Color(red: 18/255, green: 8/255, blue: 34/255)
        }
    }

    var colorInk: Color {
        switch self {
        case .cheatStore: return Color(red: 244/255, green: 241/255, blue: 234/255)
        case .veLix: return Color(red: 240/255, green: 248/255, blue: 255/255)
        case .venom: return Color(red: 248/255, green: 242/255, blue: 255/255)
        }
    }

    var colorMute: Color {
        switch self {
        case .cheatStore: return Color(red: 160/255, green: 160/255, blue: 165/255)
        case .veLix: return Color(red: 135/255, green: 160/255, blue: 190/255)
        case .venom: return Color(red: 175/255, green: 150/255, blue: 200/255)
        }
    }

    var accentColor: Color {
        switch self {
        case .cheatStore: return Color(red: 0/255, green: 140/255, blue: 255/255)
        case .veLix: return Color(red: 0/255, green: 215/255, blue: 255/255)
        case .venom: return Color(red: 196/255, green: 72/255, blue: 255/255)
        }
    }

    var glassBg: Color {
        switch self {
        case .cheatStore: return Color(red: 0/255, green: 140/255, blue: 255/255).opacity(0.05)
        case .veLix: return Color(red: 0/255, green: 180/255, blue: 255/255).opacity(0.06)
        case .venom: return Color(red: 186/255, green: 82/255, blue: 253/255).opacity(0.08)
        }
    }

    var glassBorder: Color {
        switch self {
        case .cheatStore: return Color(red: 0/255, green: 140/255, blue: 255/255).opacity(0.20)
        case .veLix: return Color(red: 0/255, green: 215/255, blue: 255/255).opacity(0.22)
        case .venom: return Color(red: 186/255, green: 82/255, blue: 253/255).opacity(0.24)
        }
    }

    var ambientGlowGradient: [Color] {
        switch self {
        case .cheatStore:
            return [
                Color(red: 0/255, green: 140/255, blue: 255/255).opacity(0.18),
                Color(red: 0/255, green: 80/255, blue: 220/255).opacity(0.06),
                Color.clear
            ]
        case .veLix:
            return [
                Color(red: 0/255, green: 200/255, blue: 255/255).opacity(0.22),
                Color(red: 0/255, green: 80/255, blue: 220/255).opacity(0.06),
                Color.clear
            ]
        case .venom:
            return [
                Color(red: 186/255, green: 82/255, blue: 253/255).opacity(0.24),
                Color(red: 110/255, green: 20/255, blue: 190/255).opacity(0.08),
                Color.clear
            ]
        }
    }

    var rainbowColors: [Color] {
        switch self {
        case .cheatStore:
            return [
                Color(red: 0.00, green: 0.85, blue: 1.00), // Cyan Neon
                Color(red: 0.15, green: 0.55, blue: 1.00), // Electric Blue
                Color(red: 0.35, green: 0.40, blue: 1.00), // Chàm Neon
                Color(red: 0.00, green: 0.70, blue: 1.00), // Azure
                Color(red: 0.75, green: 0.90, blue: 1.00), // Băng Lam
                Color(red: 0.00, green: 0.85, blue: 1.00)
            ]
        case .veLix:
            return [
                Color(red: 0.00, green: 0.88, blue: 1.00),
                Color(red: 0.20, green: 0.65, blue: 1.00),
                Color(red: 0.45, green: 0.40, blue: 1.00),
                Color(red: 0.75, green: 0.35, blue: 1.00),
                Color(red: 0.95, green: 0.95, blue: 1.00),
                Color(red: 0.00, green: 0.88, blue: 1.00)
            ]
        case .venom:
            return [
                Color(red: 0.85, green: 0.35, blue: 1.00),
                Color(red: 0.72, green: 0.20, blue: 0.98),
                Color(red: 0.55, green: 0.10, blue: 0.95),
                Color(red: 0.95, green: 0.60, blue: 1.00),
                Color(red: 1.00, green: 1.00, blue: 1.00),
                Color(red: 0.85, green: 0.35, blue: 1.00)
            ]
        }
    }

    var dockBackground: Color {
        switch self {
        case .cheatStore:
            return Color(red: 14/255, green: 16/255, blue: 24/255).opacity(0.96)
        case .veLix:
            return Color(red: 6/255, green: 14/255, blue: 28/255).opacity(0.96)
        case .venom:
            return Color(red: 14/255, green: 6/255, blue: 26/255).opacity(0.96)
        }
    }

    var dockLedColor: Color {
        switch self {
        case .cheatStore:
            return Color(red: 0/255, green: 140/255, blue: 255/255)
        case .veLix:
            return Color(red: 0/255, green: 215/255, blue: 255/255)
        case .venom:
            return Color(red: 196/255, green: 72/255, blue: 255/255)
        }
    }

    var dockHighlightColor: Color {
        switch self {
        case .cheatStore:
            return Color.white
        case .veLix:
            return Color(red: 140/255, green: 245/255, blue: 255/255)
        case .venom:
            return Color(red: 225/255, green: 120/255, blue: 255/255)
        }
    }

    var dockSecondaryColor: Color {
        switch self {
        case .cheatStore:
            return Color(white: 0.5)
        case .veLix:
            return Color(red: 0/255, green: 110/255, blue: 230/255)
        case .venom:
            return Color(red: 120/255, green: 30/255, blue: 210/255)
        }
    }

    var dockBorderGradient: [Color] {
        switch self {
        case .cheatStore:
            return [Color.white.opacity(0.25), Color.white.opacity(0.08)]
        case .veLix:
            return [
                Color(red: 0/255, green: 215/255, blue: 255/255).opacity(0.42),
                Color(red: 0/255, green: 110/255, blue: 230/255).opacity(0.12)
            ]
        case .venom:
            return [
                Color(red: 196/255, green: 72/255, blue: 255/255).opacity(0.42),
                Color(red: 120/255, green: 30/255, blue: 210/255).opacity(0.12)
            ]
        }
    }
}

