import Foundation
import UIKit

/// =========================================================================
/// DeviceProfileService
/// Lấy thông tin thiết bị và hệ thống THẬT động từ iOS kernel và bundle:
/// Không hardcode, không hiển thị dữ liệu giả/VIP giả.
/// =========================================================================
public struct DeviceProfileInfo {
    public let modelIdentifier: String
    public let marketingName: String
    public let osVersion: String
    public let appVersion: String
    public let buildNumber: String
    public let keyStatus: String
    public let expiration: String
    public let serverStatus: String
}

public final class DeviceProfileService {
    public static let shared = DeviceProfileService()

    private init() {}

    public func getCurrentProfile() -> DeviceProfileInfo {
        let identifier = getDeviceIdentifier()
        let marketing = mapIdentifierToMarketingName(identifier)
        let os = UIDevice.current.systemVersion

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Tuân thủ mục 7: Nếu chưa có API xác thực thực tế, hiển thị NOT CONFIGURED / OFFLINE
        let keyStatus = "NOT CONFIGURED"
        let expiration = "NOT CONFIGURED"
        let serverStatus = "OFFLINE"

        return DeviceProfileInfo(
            modelIdentifier: identifier,
            marketingName: marketing,
            osVersion: os,
            appVersion: appVersion,
            buildNumber: buildNumber,
            keyStatus: keyStatus,
            expiration: expiration,
            serverStatus: serverStatus
        )
    }

    private func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }

    private func mapIdentifierToMarketingName(_ identifier: String) -> String {
        let map: [String: String] = [
            // iPhone 16
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            // iPhone 15
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            // iPhone 14
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            // iPhone 13
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            // iPhone 12
            "iPhone13,2": "iPhone 12",
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            // iPhone 11
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            // iPhone SE
            "iPhone12,8": "iPhone SE (2nd gen)",
            "iPhone14,6": "iPhone SE (3rd gen)",
            // Simulator
            "i386": "iPhone Simulator",
            "x86_64": "iPhone Simulator",
            "arm64": "Apple Silicon Simulator"
        ]
        return map[identifier] ?? identifier
    }
}
