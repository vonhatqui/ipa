import SwiftUI

/// =========================================================================
/// New3105InjectorButton
/// Thanh ngang INJECTOR nổi bật toàn màn hình (Horizontal Bar Button):
/// - Nằm ngang trên thanh Tab Bar theo yêu cầu người dùng.
/// - Thực hiện nạp file Assembly-CSharp-patch.bytes và localConfig.json
///   vào các container của game Free Fire (com.dts.freefireth, com.dts.freefiremax, v.v.)
///   chuẩn cơ chế 3105 engine.
/// - Trạng thái: Sẵn sàng (Nền đen viền sáng) / Đang nạp (Spinner) / Đã nạp (Nền đỏ UNINJECT).
/// =========================================================================
public struct New3105InjectorButton: View {
    @ObservedObject var configManager: LocalConfigManager
    
    public enum InjectorState {
        case idleReady
        case processing(String)
        case connected
    }
    
    @State private var currentState: InjectorState = .idleReady
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Thông Báo"

    public init(configManager: LocalConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        Button(action: handleButtonPress) {
            HStack(spacing: 10) {
                switch currentState {
                case .idleReady:
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 1.0))
                    Text("NẠP CẤU HÌNH (INJECTOR)")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                case .processing(let step):
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                    Text(step)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                case .connected:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("HỦY NẠP (UNINJECT)")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1.2)
            )
            .shadow(color: shadowColor, radius: 8, y: 3)
        }
        .disabled(isButtonDisabled)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
    }

    private var isButtonDisabled: Bool {
        if case .processing = currentState {
            return true
        }
        return false
    }

    private var backgroundColor: Color {
        switch currentState {
        case .idleReady:
            return Color(white: 0.09)
        case .processing:
            return Color(white: 0.16)
        case .connected:
            return Color(red: 0.85, green: 0.15, blue: 0.15)
        }
    }

    private var borderColor: Color {
        switch currentState {
        case .idleReady:
            return Color.white.opacity(0.3)
        case .processing:
            return Color(white: 0.45)
        case .connected:
            return Color(red: 1.0, green: 0.35, blue: 0.35)
        }
    }

    private var shadowColor: Color {
        switch currentState {
        case .idleReady:
            return Color.black.opacity(0.5)
        case .processing:
            return Color.black.opacity(0.4)
        case .connected:
            return Color(red: 0.85, green: 0.15, blue: 0.15).opacity(0.4)
        }
    }

    private func handleButtonPress() {
        switch currentState {
        case .idleReady:
            performInjectionWorkflow()
        case .processing:
            break
        case .connected:
            performUninjectWorkflow()
        }
    }

    private func performInjectionWorkflow() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentState = .processing("ĐANG ĐỒNG BỘ CẤU HÌNH...")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            // Bước 1: Lưu cấu hình localConfig.json mới nhất
            _ = self.configManager.saveConfig()

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentState = .processing("ĐANG NẠP VÀO GAME...")
                }
            }

            let fm = FileManager.default
            let appDocs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // 1. Dữ liệu localConfig.json
            var configData: Data? = nil
            if let d = try? JSONSerialization.data(withJSONObject: self.configManager.rawConfig, options: [.prettyPrinted, .sortedKeys]) {
                configData = d
            } else if let localData = try? Data(contentsOf: self.configManager.configURL) {
                configData = localData
            }

            // 2. Dữ liệu Assembly-CSharp-patch.bytes
            var patchData: Data? = nil
            let localPatchURL = appDocs.appendingPathComponent("Assembly-CSharp-patch.bytes")
            if fm.fileExists(atPath: localPatchURL.path), let d = try? Data(contentsOf: localPatchURL) {
                patchData = d
            } else if let bURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes") ??
                        Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes", subdirectory: "AppCore/new123") ??
                        Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes", subdirectory: "AppCore") ??
                        Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes", subdirectory: "BundledPatches/CheatVN_External_Files/Documents") {
                patchData = try? Data(contentsOf: bURL)
            }

            // Lưu trực tiếp vào app Documents
            if let pData = patchData {
                try? pData.write(to: localPatchURL, options: .atomic)
            }
            if let cData = configData {
                try? cData.write(to: self.configManager.configURL, options: .atomic)
            }

            // 3. Quét tất cả container Free Fire khả dụng (Standard, MAX, VN, TH)
            var targetContainers: [URL] = []
            let targetBIDs = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
            for bid in targetBIDs {
                if let p = ContainerStore.resolveAppContainerPath(bundleID: bid) {
                    let u = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: p, isDirectory: true))
                    if !targetContainers.contains(u) { targetContainers.append(u) }
                }
            }
            for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
                if !targetContainers.contains(root) { targetContainers.append(root) }
            }
            if let ffPath = findFreeFireContainerPath() {
                let canonical = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: ffPath, isDirectory: true))
                if !targetContainers.contains(canonical) { targetContainers.append(canonical) }
            }

            var injectedContainersCount = 0

            // 4. Ghi đè file vào từng container game
            for root in targetContainers {
                let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                try? fm.createDirectory(at: docDir, withIntermediateDirectories: true)

                let dstPatch = docDir.appendingPathComponent("Assembly-CSharp-patch.bytes")
                let dstConfig = docDir.appendingPathComponent("localConfig.json")

                var successWrite = false
                if let pData = patchData {
                    DevicePatchService.captureGoldenSnapshotIfNeeded(targetURL: dstPatch, bundleID: "com.dts.freefireth", relativePath: "Documents/Assembly-CSharp-patch.bytes", replacementData: pData, fileManager: fm)
                    try? fm.removeItem(at: dstPatch)
                    if (try? pData.write(to: dstPatch, options: .atomic)) != nil {
                        var uPatch = dstPatch
                        var resVals = URLResourceValues()
                        resVals.isExcludedFromBackup = true
                        try? uPatch.setResourceValues(resVals)
                        try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstPatch.path)
                        successWrite = true
                    }
                }

                if let cData = configData {
                    DevicePatchService.captureGoldenSnapshotIfNeeded(targetURL: dstConfig, bundleID: "com.dts.freefireth", relativePath: "Documents/localConfig.json", replacementData: cData, fileManager: fm)
                    try? fm.removeItem(at: dstConfig)
                    if (try? cData.write(to: dstConfig, options: .atomic)) != nil {
                        var uConfig = dstConfig
                        var resVals = URLResourceValues()
                        resVals.isExcludedFromBackup = true
                        try? uConfig.setResourceValues(resVals)
                        try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dstConfig.path)
                        successWrite = true
                    }
                }

                // Sao chép các runtime files phụ trợ từ BundledPatches nếu có
                if let bundleRes = Bundle.main.resourceURL {
                    let runtimeSrcDir = bundleRes.appendingPathComponent("BundledPatches/CheatVN_External_Files/Documents")
                    let runtimeFiles = [".ffxc_runtime", ".ffxc_live", ".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9"]
                    for rf in runtimeFiles {
                        let srcRF = runtimeSrcDir.appendingPathComponent(rf)
                        let dstRF = docDir.appendingPathComponent(rf)
                        if fm.fileExists(atPath: srcRF.path) {
                            try? fm.removeItem(at: dstRF)
                            try? fm.copyItem(at: srcRF, to: dstRF)
                        }
                    }
                }

                if successWrite {
                    injectedContainersCount += 1
                }
            }

            // Nạp qua cơ chế 3105 patch envelope
            _ = CheatVNPatchService.shared.applyPatch(injectCheatVN: true, injectEspAimSilent: true)
            DevicePatchService.ensureActivePatchesInjected()

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentState = .connected
                }
                self.alertTitle = "Nạp Cấu Hình Thành Công"
                if injectedContainersCount > 0 {
                    self.alertMessage = "Đã nạp Assembly-CSharp-patch.bytes và localConfig.json vào \(injectedContainersCount) container Free Fire thành công!\nSẵn sàng mở game."
                } else {
                    self.alertMessage = "Đã nạp và đồng bộ Assembly-CSharp-patch.bytes cùng localConfig.json vào môi trường 3105 thành công!\nSẵn sàng mở game Free Fire."
                }
                self.showingAlert = true
            }
        }
    }

    private func performUninjectWorkflow() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentState = .processing("ĐANG HỦY NẠP...")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            let targetBIDs = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
            var targetContainers: [URL] = []
            for bid in targetBIDs {
                if let p = ContainerStore.resolveAppContainerPath(bundleID: bid) {
                    let u = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: p, isDirectory: true))
                    if !targetContainers.contains(u) { targetContainers.append(u) }
                }
            }
            for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
                if !targetContainers.contains(root) { targetContainers.append(root) }
            }
            if let ffPath = findFreeFireContainerPath() {
                let canonical = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: ffPath, isDirectory: true))
                if !targetContainers.contains(canonical) { targetContainers.append(canonical) }
            }

            for root in targetContainers {
                let docDir = root.appendingPathComponent("Documents", isDirectory: true)
                let filesToRemove = [
                    "Assembly-CSharp-patch.bytes",
                    "localConfig.json",
                    ".ffxc_runtime",
                    ".ffxc_live",
                    ".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9"
                ]
                for file in filesToRemove {
                    try? fm.removeItem(at: docDir.appendingPathComponent(file))
                }
            }

            _ = CheatVNPatchService.shared.restoreOriginals()
            _ = DevicePatchService.cleanRestoreAllModifications()

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentState = .idleReady
                }
                self.alertTitle = "Đã Hủy Nạp Cấu Hình"
                self.alertMessage = "Đã xóa sạch các file patch khỏi game Free Fire, đưa ứng dụng về trạng thái sẵn sàng."
                self.showingAlert = true
            }
        }
    }
}
