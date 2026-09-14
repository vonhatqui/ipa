import Foundation
import SwiftUI

/// Quản lý cấu hình ESP & Aim tuỳ chỉnh trực tiếp trong ứng dụng
class EspConfigManager: ObservableObject {
    static let shared = EspConfigManager()

    // MARK: - Keys UserDefaults
    private let kBox = "esp_cfg_box"
    private let kName = "esp_cfg_name"
    private let kHP = "esp_cfg_hp"
    private let kLine = "esp_cfg_line"
    private let kDistText = "esp_cfg_dist_text"
    private let kAim = "esp_cfg_aim"
    private let kDistance = "esp_cfg_distance"
    private let kColorIndex = "esp_cfg_color_index"

    // MARK: - Published Properties
    @Published var isBoxEnabled: Bool {
        didSet { UserDefaults.standard.set(isBoxEnabled, forKey: kBox) }
    }
    @Published var isNameEnabled: Bool {
        didSet { UserDefaults.standard.set(isNameEnabled, forKey: kName) }
    }
    @Published var isHPEnabled: Bool {
        didSet { UserDefaults.standard.set(isHPEnabled, forKey: kHP) }
    }
    @Published var isLineEnabled: Bool {
        didSet { UserDefaults.standard.set(isLineEnabled, forKey: kLine) }
    }
    @Published var isDistanceTextEnabled: Bool {
        didSet { UserDefaults.standard.set(isDistanceTextEnabled, forKey: kDistText) }
    }
    @Published var isAimEnabled: Bool {
        didSet { UserDefaults.standard.set(isAimEnabled, forKey: kAim) }
    }
    @Published var scanDistance: Double {
        didSet { UserDefaults.standard.set(scanDistance, forKey: kDistance) }
    }
    @Published var colorIndex: Int {
        didSet { UserDefaults.standard.set(colorIndex, forKey: kColorIndex) }
    }

    // Danh sách màu hỗ trợ
    struct EspColorOption: Identifiable {
        let id: Int
        let name: String
        let color: Color
        let rgb: (r: Float, g: Float, b: Float)
    }

    let colorOptions: [EspColorOption] = [
        EspColorOption(id: 0, name: "Xanh Cyber", color: Color(red: 0.0, green: 0.72, blue: 1.0), rgb: (0.0, 0.55, 1.0)),
        EspColorOption(id: 1, name: "Đỏ Neon", color: Color(red: 1.0, green: 0.25, blue: 0.25), rgb: (1.0, 0.20, 0.20)),
        EspColorOption(id: 2, name: "Vàng Gold", color: Color(red: 1.0, green: 0.84, blue: 0.0), rgb: (1.0, 0.85, 0.0)),
        EspColorOption(id: 3, name: "Xanh Lá", color: Color(red: 0.2, green: 0.9, blue: 0.4), rgb: (0.1, 1.0, 0.3)),
        EspColorOption(id: 4, name: "Tím Neon", color: Color(red: 0.75, green: 0.3, blue: 1.0), rgb: (0.75, 0.2, 1.0))
    ]

    private init() {
        let defaults = UserDefaults.standard
        self.isBoxEnabled = defaults.object(forKey: kBox) != nil ? defaults.bool(forKey: kBox) : true
        self.isNameEnabled = defaults.object(forKey: kName) != nil ? defaults.bool(forKey: kName) : true
        self.isHPEnabled = defaults.object(forKey: kHP) != nil ? defaults.bool(forKey: kHP) : true
        self.isLineEnabled = defaults.bool(forKey: kLine) // Mặc định tắt để chống văng / lag
        self.isDistanceTextEnabled = defaults.object(forKey: kDistText) != nil ? defaults.bool(forKey: kDistText) : true
        self.isAimEnabled = defaults.object(forKey: kAim) != nil ? defaults.bool(forKey: kAim) : true
        self.scanDistance = defaults.object(forKey: kDistance) != nil ? defaults.double(forKey: kDistance) : 90.0
        self.colorIndex = defaults.integer(forKey: kColorIndex)
    }

    func resetToDefaults() {
        isBoxEnabled = true
        isNameEnabled = true
        isHPEnabled = true
        isLineEnabled = false
        isDistanceTextEnabled = true
        isAimEnabled = true
        scanDistance = 90.0
        colorIndex = 0
    }

    /// Cập nhật các Rules trong PatchProject theo cấu hình hiện tại
    func applyConfiguration(to project: inout PatchProject) {
        let selectedDist = UInt16(min(max(scanDistance, 30), 250))
        let selectedColor = UInt8(colorIndex)

        for index in 0..<project.rules.count {
            let path = project.rules[index].relativePath.lowercased()

            // 1. Cập nhật config.bin (21 bytes)
            if path.hasSuffix("config.bin") {
                var cfg = [UInt8](project.rules[index].replacementData)
                if cfg.count >= 21 {
                    cfg[0] = 1 // Master ESP ON
                    cfg[1] = isAimEnabled ? 1 : 0
                    cfg[2] = isBoxEnabled ? 1 : 0
                    cfg[3] = isHPEnabled ? 1 : 0
                    cfg[4] = isNameEnabled ? 1 : 0
                    cfg[5] = isDistanceTextEnabled ? 1 : 0
                    // Khoảng cách (Little Endian uint16)
                    cfg[6] = UInt8(selectedDist & 0xFF)
                    cfg[7] = UInt8((selectedDist >> 8) & 0xFF)
                    cfg[16] = selectedColor
                    project.rules[index].replacementData = Data(cfg)
                }
            }

            // 2. Cập nhật com.dts.freefireth.plist
            if path.hasSuffix(".plist") {
                if var plist = try? PropertyListSerialization.propertyList(
                    from: project.rules[index].replacementData,
                    options: [],
                    format: nil
                ) as? [String: Any] {
                    plist["__espon"] = 1
                    plist["__ebox"] = isBoxEnabled ? 1 : 0
                    plist["__ename"] = isNameEnabled ? 1 : 0
                    plist["__ehp"] = isHPEnabled ? 1 : 0
                    plist["__eline"] = isLineEnabled ? 1 : 0
                    plist["__edir"] = isLineEnabled ? 1 : 0
                    plist["__cage"] = 0
                    plist["__edistance"] = isDistanceTextEnabled ? 1 : 0
                    plist["__edist"] = Int(selectedDist)
                    plist["__cgc"] = Int(selectedColor)

                    plist["__q01"] = isAimEnabled ? 1 : 0
                    plist["__q02"] = isBoxEnabled ? 1 : 0
                    plist["__q03"] = isHPEnabled ? 1 : 0
                    plist["__q04"] = isNameEnabled ? 1 : 0
                    plist["__q05"] = isDistanceTextEnabled ? 1 : 0
                    plist["__q06"] = isLineEnabled ? 1 : 0
                    plist["__q07"] = 31
                    plist["__q08"] = Int(selectedDist)
                    plist["__q18"] = Int(selectedColor)
                    plist["HighFPS"] = 1

                    if let updatedData = try? PropertyListSerialization.data(
                        fromPropertyList: plist,
                        format: .binary,
                        options: 0
                    ) {
                        project.rules[index].replacementData = updatedData
                    }
                }
            }
        }
    }

    /// Ghi đè cấu hình mới trực tiếp vào thư mục game đang chạy nếu máy đã cài game
    func syncDirectlyToGameContainer() {
        let bundleIDs = ["com.dts.freefireth", "com.dts.freefiremax"]
        guard let roots = try? DevicePatchService.resolveContainers(bundleIDs: bundleIDs) else {
            return
        }

        let selectedDist = UInt16(min(max(scanDistance, 30), 250))
        let selectedColor = UInt8(colorIndex)

        for (_, rootURL) in roots {
            // A. Ghi Documents/config.bin
            let configURL = rootURL.appendingPathComponent("Documents/config.bin")
            if FileManager.default.fileExists(atPath: configURL.path),
               var cfg = try? [UInt8](Data(contentsOf: configURL)), cfg.count >= 21 {
                cfg[0] = 1
                cfg[1] = isAimEnabled ? 1 : 0
                cfg[2] = isBoxEnabled ? 1 : 0
                cfg[3] = isHPEnabled ? 1 : 0
                cfg[4] = isNameEnabled ? 1 : 0
                cfg[5] = isDistanceTextEnabled ? 1 : 0
                cfg[6] = UInt8(selectedDist & 0xFF)
                cfg[7] = UInt8((selectedDist >> 8) & 0xFF)
                cfg[16] = selectedColor
                try? Data(cfg).write(to: configURL)
            }

            // B. Ghi Library/Preferences/com.dts.freefireth.plist
            let plistURL = rootURL.appendingPathComponent("Library/Preferences/com.dts.freefireth.plist")
            if FileManager.default.fileExists(atPath: plistURL.path),
               let rawData = try? Data(contentsOf: plistURL),
               var plist = try? PropertyListSerialization.propertyList(from: rawData, options: [], format: nil) as? [String: Any] {
                plist["__espon"] = 1
                plist["__ebox"] = isBoxEnabled ? 1 : 0
                plist["__ename"] = isNameEnabled ? 1 : 0
                plist["__ehp"] = isHPEnabled ? 1 : 0
                plist["__eline"] = isLineEnabled ? 1 : 0
                plist["__edir"] = isLineEnabled ? 1 : 0
                plist["__edistance"] = isDistanceTextEnabled ? 1 : 0
                plist["__edist"] = Int(selectedDist)
                plist["__cgc"] = Int(selectedColor)
                plist["__q01"] = isAimEnabled ? 1 : 0
                plist["__q02"] = isBoxEnabled ? 1 : 0
                plist["__q03"] = isHPEnabled ? 1 : 0
                plist["__q04"] = isNameEnabled ? 1 : 0
                plist["__q05"] = isDistanceTextEnabled ? 1 : 0
                plist["__q06"] = isLineEnabled ? 1 : 0
                plist["__q08"] = Int(selectedDist)
                plist["__q18"] = Int(selectedColor)
                plist["HighFPS"] = 1

                if let updatedData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0) {
                    try? updatedData.write(to: plistURL)
                }
            }
        }
    }
}
