import Foundation
import UIKit

public struct DeviceProfileInfo {
    public let marketingName: String
    public let modelIdentifier: String
    public let osVersion: String
    public let appVersion: String
    public let buildNumber: String
}

public final class DeviceProfileService {
    public static let shared = DeviceProfileService()

    public func getCurrentProfile() -> DeviceProfileInfo {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let marketingName = mapToMarketingName(identifier: identifier)
        let osVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        return DeviceProfileInfo(
            marketingName: marketingName,
            modelIdentifier: identifier.isEmpty ? "iPhone (ARM64)" : identifier,
            osVersion: osVersion,
            appVersion: appVersion,
            buildNumber: buildNumber
        )
    }

    private func mapToMarketingName(identifier: String) -> String {
        switch identifier {
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        default:
            if identifier.hasPrefix("iPhone") {
                return "Apple iPhone"
            } else if identifier.hasPrefix("iPad") {
                return "Apple iPad"
            }
            return UIDevice.current.model
        }
    }
}
