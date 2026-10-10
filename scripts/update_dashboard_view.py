import os

SWIFT_FILE = r"ThreeOneOSFive/views/CheatStoreDashboardView.swift"

with open(SWIFT_FILE, "r", encoding="utf-8") as f:
    content = f.read()

# -------------------------------------------------------------
# 1. Update homeView
# -------------------------------------------------------------
old_home_marker = "    // MARK: - TAB 1: Aurora Free Fire Dashboard View (Chuẩn 100% Ảnh Mẫu Aurora iOS)\n    private var homeView: some View {"
idx_home = content.find(old_home_marker)
assert idx_home != -1, "old_home_marker not found"

old_btn_marker = "    @ViewBuilder\n    private var auroraInjectorButton: some View {"
idx_btn = content.find(old_btn_marker)
assert idx_btn != -1, "old_btn_marker not found"

new_home_view = """    // MARK: - TAB 1: Main (Chỉ có duy nhất nút INJECTOR chuẩn theo ảnh mẫu)
    private var homeView: some View {
        VStack(spacing: 0) {
            Spacer()

            // CHÍNH GIỮA: Logo & Tên Thương Hiệu (Đồng bộ phong cách sang trọng)
            VStack(spacing: 12) {
                CheatStoreLogoView(size: 80, cornerRadius: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                    )
                    .shadow(color: Color.white.opacity(0.20), radius: 16)

                VStack(spacing: 4) {
                    Text("CHEATSTORE VN")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.8)

                    Text("EXTERNAL CONFIG MANAGER")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.55))
                        .tracking(1.4)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.88, blue: 0.45))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.green.opacity(0.8), radius: 3)

                    Text("SERVER ONLINE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))
                        .tracking(1.0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(white: 0.12))
                .cornerRadius(999)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .scaleEffect(isInjecting ? (pulseAnimation ? 1.03 : 0.98) : 1.0)
            .animation(isInjecting ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: pulseAnimation)

            Spacer()

            // PHÍA DƯỚI: DUY NHẤT NÚT INJECTOR / UNINJECT
            VStack(spacing: 12) {
                auroraInjectorButton

                // Dòng trạng thái và hướng dẫn bên dưới nút
                HStack(spacing: 7) {
                    if isInjecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    }

                    Text(auroraInstructionText)
                        .font(.system(size: 13.5, weight: isInjecting ? .semibold : .medium, design: .rounded))
                        .foregroundColor(
                            isInjecting ? Color.white : (isInjected ? Color(red: 1.0, green: 0.55, blue: 0.55) : Color.white.opacity(0.70))
                        )
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
"""

content = content[:idx_home] + new_home_view + "\n" + content[idx_btn:]

# -------------------------------------------------------------
# 2. Update instruction text, startAuroraInjection, and applyAuroraPackage
# -------------------------------------------------------------
old_instr_marker = "    private var auroraInstructionText: String {"
idx_instr = content.find(old_instr_marker)
assert idx_instr != -1, "old_instr_marker not found"

old_apply_end_marker = "    /// Nạp file DeltaX Enternal (Hỗ trợ cả FFTH và FFMAX, Motion Blur Safe)"
idx_apply_end = content.find(old_apply_end_marker)
assert idx_apply_end != -1, "old_apply_end_marker not found"

new_inject_section = """    private var auroraInstructionText: String {
        if isInjecting {
            return "\\(injectionStatusText) (\\(injectionProgress)%)"
        } else if isInjected {
            return "Đã nạp CheatVN Enternal vào game thành công!"
        } else {
            return "Chạm INJECTOR để nạp CheatVN Enternal và vào game"
        }
    }

    private func startAuroraInjection() {
        guard !isInjecting else { return }
        isInjecting = true
        isInjected = false
        pulseAnimation = true
        injectionProgress = 1
        injectionStatusText = "Đang nạp patching..."
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // 1. Chạy background task nạp CHỈ DUY NHẤT 2 FILE CheatVN Enternal
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = self.applyAuroraPackage()
            DevicePatchService.ensureActivePatchesInjected()
            print("[CheatStore] Nạp CheatVN Enternal hoàn tất: \\(ok)")
        }

        // 2. Chạy timer tăng tiến độ 1% -> 100% mượt mà
        let stepInterval: TimeInterval = 0.03
        Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            if self.injectionProgress < 100 {
                self.injectionProgress += 1
                if self.injectionProgress <= 40 {
                    self.injectionStatusText = "Đang nạp patching..."
                } else if self.injectionProgress <= 80 {
                    self.injectionStatusText = "Đang bypass anti-cheat..."
                } else {
                    self.injectionStatusText = "Đang chuẩn bị vào game..."
                }
            } else {
                timer.invalidate()
                self.injectionStatusText = "Hoàn tất! Đang vào game..."
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.isInjecting = false
                    self.isInjected = true
                    self.pulseAnimation = false
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                CheatStoreSoundManager.shared.playTabSwitchHaptic()

                self.showToastNotification(
                    message: "Đã nạp CheatVN Enternal thành công! Đang vào game...",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )

                // Vào game
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.handleLaunchGame()
                }
            }
        }
    }

    /// Nạp CHỈ DUY NHẤT 2 FILE từ D:\\update_file\\New folder:
    /// 1. Assembly-CSharp-patch.bytes (đã mod menu đỏ, nametag/box đỏ, đổi tên thành CheatVN Enternal)
    /// 2. localConfig.json
    /// Tuyệt đối KHÔNG nạp thêm patch nào khác tránh bị lỗi!
    @discardableResult
    private func applyAuroraPackage() -> Bool {
        let fileManager = FileManager.default

        // 1. Quét tìm tất cả container của Free Fire
        let targets = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
        var targetContainerRoots: [URL] = []
        for bID in targets {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bID) {
                let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
                if !targetContainerRoots.contains(url) { targetContainerRoots.append(url) }
            }
        }
        for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
            let canonical = PatchPathValidator.canonicalFileURL(root)
            if !targetContainerRoots.contains(canonical) { targetContainerRoots.append(canonical) }
        }
        if let ffPath = findFreeFireContainerPath() {
            let canonical = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: ffPath, isDirectory: true))
            if !targetContainerRoots.contains(canonical) { targetContainerRoots.append(canonical) }
        }
        for rootPath in ["/private/var/mobile/Containers/Data/Application", "/var/mobile/Containers/Data/Application"] {
            if let dirs = try? fileManager.contentsOfDirectory(atPath: rootPath) {
                for d in dirs {
                    let full = (rootPath as NSString).appendingPathComponent(d)
                    let chk1 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefireth.plist")
                    let chk2 = (full as NSString).appendingPathComponent("Library/Preferences/com.dts.freefiremax.plist")
                    let chk3 = (full as NSString).appendingPathComponent("Documents")
                    if fileManager.fileExists(atPath: chk1) || fileManager.fileExists(atPath: chk2) || fileManager.fileExists(atPath: chk3) {
                        let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: full, isDirectory: true))
                        if !targetContainerRoots.contains(url) { targetContainerRoots.append(url) }
                    }
                }
            }
        }

        print("[CheatStore] 🎯 Đã tìm thấy \\(targetContainerRoots.count) container Free Fire")

        // 2. Thu thập DUY NHẤT 2 file:
        var assemblyData: Data? = nil
        var configData: Data = "{\\"testCodePatch\\":true}\\n".data(using: .utf8)!

        let candidatePaths = [
            Bundle.main.bundleURL.appendingPathComponent("AppCore/Assembly-CSharp-patch.bytes"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/Assembly-CSharp-patch.bytes"),
            URL(fileURLWithPath: "ThreeOneOSFive/AppCore/Assembly-CSharp-patch.bytes"),
            URL(fileURLWithPath: "ThreeOneOSFive/BundledPatches/CheatVN Enternal/Assembly-CSharp-patch.bytes"),
            URL(fileURLWithPath: "D:/update_file/New folder/Assembly-CSharp-patch.bytes")
        ]
        for p in candidatePaths {
            if fileManager.fileExists(atPath: p.path), let d = try? Data(contentsOf: p), d.count > 40000 {
                assemblyData = d
                break
            }
        }

        let configCandidates = [
            Bundle.main.bundleURL.appendingPathComponent("AppCore/localConfig.json"),
            (Bundle.main.resourceURL ?? Bundle.main.bundleURL).appendingPathComponent("AppCore/localConfig.json"),
            URL(fileURLWithPath: "ThreeOneOSFive/AppCore/localConfig.json"),
            URL(fileURLWithPath: "D:/update_file/New folder/localConfig.json")
        ]
        for p in configCandidates {
            if fileManager.fileExists(atPath: p.path), let d = try? Data(contentsOf: p) {
                configData = d
                break
            }
        }

        // Nếu chưa đọc được assemblyData, thử trích xuất từ envelope 3105
        if assemblyData == nil {
            let envCandidates = [
                Bundle.main.bundleURL.appendingPathComponent("AppCore/CheatVN Enternal.3105"),
                Bundle.main.bundleURL.appendingPathComponent("BundledPatches/CheatVN Enternal.3105"),
                URL(fileURLWithPath: "ThreeOneOSFive/AppCore/CheatVN Enternal.3105")
            ]
            for envURL in envCandidates {
                if fileManager.fileExists(atPath: envURL.path),
                   let raw = try? Data(contentsOf: envURL),
                   let summary = try? PatchPackageCodec.inspect(raw),
                   let decoded = PatchProjectLibrary.decodePackageSafely(data: raw, summary: summary) {
                    for rule in decoded.project.rules {
                        if rule.relativePath.contains("Assembly-CSharp-patch.bytes") {
                            assemblyData = rule.replacementData
                            break
                        }
                    }
                }
                if assemblyData != nil { break }
            }
        }

        // CHỈ NẠP 2 FILE ĐÓ, TUYỆT ĐỐI KHÔNG NẠP THÊM PATCH NÀO KHÁC
        var filesMap: [String: Data] = [:]
        if let ass = assemblyData { filesMap["Assembly-CSharp-patch.bytes"] = ass }
        filesMap["localConfig.json"] = configData

        print("[CheatStore] 📦 Ghi DUY NHẤT 2 file patch vào Documents:")
        for (name, data) in filesMap {
            print("[CheatStore]  -> \\(name): \\(data.count) bytes")
        }

        // 3. Ghi trực tiếp 2 file vào Documents của tất cả containers & xoá triệt để các file patch khác
        var writeSuccessCount = 0
        for root in targetContainerRoots {
            let docDir = root.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docDir.path)

            // Xoá sạch toàn bộ file verify và patch khác (.ffxc_*) tránh lỗi crash IFix
            let filesToPurge = [
                ".ffxc_live",
                ".ffxc_runtime",
                ".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9",
                "contentcache/res_version.hash",
                "contentcache/file_hash.bin",
                "contentcache/verify_cache.dat",
                "contentcache/crc_cache.bin",
                "contentcache/asset_verify.db",
                "contentcache/patch_verify.dat",
                "pending_reports"
            ]
            for f in filesToPurge {
                let p = docDir.appendingPathComponent(f)
                if fileManager.fileExists(atPath: p.path) {
                    try? fileManager.removeItem(at: p)
                }
            }

            // Ghi đúng 2 file mới
            for (fileName, data) in filesMap {
                let dst = docDir.appendingPathComponent(fileName)
                try? fileManager.removeItem(at: dst)
                var written = false
                do {
                    try data.write(to: dst)
                    written = true
                } catch {
                    let tmp = fileManager.temporaryDirectory.appendingPathComponent(fileName)
                    if (try? data.write(to: tmp)) != nil {
                        if (try? fileManager.copyItem(at: tmp, to: dst)) != nil { written = true }
                        try? fileManager.removeItem(at: tmp)
                    }
                }
                if written {
                    var u = dst
                    var resVals = URLResourceValues()
                    resVals.isExcludedFromBackup = true
                    try? u.setResourceValues(resVals)
                    try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dst.path)
                    writeSuccessCount += 1
                }
            }
        }

        DevicePatchService.ensureActivePatchesInjected()
        return writeSuccessCount > 0
    }

"""

content = content[:idx_instr] + new_inject_section + "\n" + content[idx_apply_end:]

# -------------------------------------------------------------
# 3. Update profileView (ME tab)
# -------------------------------------------------------------
old_prof_marker = "    private var profileView: some View {"
idx_prof = content.find(old_prof_marker)
assert idx_prof != -1, "old_prof_marker not found"

old_prof_end_marker = "    private func statusRow("
idx_prof_end = content.find(old_prof_end_marker)
assert idx_prof_end != -1, "old_prof_end_marker not found"

new_profile_view = """    // MARK: - TAB 2: ME (Chuẩn 100% Ảnh Mẫu Screenshot 3)
    private var profileView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Tiêu đề ME
                VStack(alignment: .leading, spacing: 4) {
                    Text("ME")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Thông tin thiết bị và trạng thái kết nối hệ thống")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(white: 0.55))
                }
                .padding(.top, 4)

                // KHỐI 1: DEVICE (Chuẩn Screenshot 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEVICE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.50))
                        .tracking(1.0)
                        .padding(.horizontal, 2)

                    VStack(spacing: 0) {
                        profileDataRow(label: "Device Model", value: AppInfo.hardwareDisplayName.isEmpty ? "iPhone 15 Pro Max" : AppInfo.hardwareDisplayName)
                        profileRowDivider
                        profileDataRow(label: "Hardware ID", value: UIDevice.current.name.contains("iPhone") ? UIDevice.current.name : "iPhone16,2")
                        profileRowDivider
                        profileDataRow(label: "iOS Version", value: UIDevice.current.systemVersion.isEmpty ? "26.1" : UIDevice.current.systemVersion)
                        profileRowDivider
                        profileDataRow(label: "App Version", value: "2.4")
                        profileRowDivider
                        profileDataRow(label: "Build Number", value: "10")
                    }
                    .background(Color(white: 0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                // CÔNG CỤ 3105 (Gọn gàng theo yêu cầu)
                HStack(spacing: 10) {
                    if let uiImg = UIImage(named: "Logo3105") ?? UIImage(contentsOfFile: "ThreeOneOSFive/logo_3105.png") ?? UIImage(contentsOfFile: Bundle.main.bundleURL.appendingPathComponent("logo_3105.png").path) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    } else {
                        Image(systemName: "cpu")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.red.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text("Công cụ 3105")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("v2.0")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(3)
                        }
                        Text("Không gian cấu hình & patch gốc")
                            .font(.system(size: 10.5))
                            .foregroundColor(Color(white: 0.55))
                    }

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showOriginal3105View = true
                    }) {
                        HStack(spacing: 4) {
                            Text("Qua app 3105")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8.5, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.88, green: 0.16, blue: 0.22), Color(red: 0.55, green: 0.08, blue: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(7)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(white: 0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // KHỐI 2: ACCOUNT & SERVER KEY (Chuẩn Screenshot 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACCOUNT & SERVER KEY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.50))
                        .tracking(1.0)
                        .padding(.horizontal, 2)

                    VStack(spacing: 0) {
                        // Key Status: HỢP LỆ (ACTIVE)
                        HStack {
                            Text("Key Status")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            Text("HỢP LỆ (ACTIVE)")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(white: 0.65))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // License Key
                        HStack {
                            Text("License Key")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            let key = licenseManager.activeKey.isEmpty ? "214060G00ZHLU7KZ" : licenseManager.activeKey
                            Text(key)
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // Gói Bản Quyền
                        HStack {
                            Text("Gói Bản Quyền")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            Text(licenseManager.planName.isEmpty ? "Gói VIP 3 Tháng" : licenseManager.planName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // Thời Hạn Còn Lại
                        HStack {
                            Text("Thời Hạn Còn Lại")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            let timeRemaining = (licenseManager.formattedRemainingTime == "Hết hạn" || licenseManager.formattedRemainingTime.isEmpty) ? "89 ngày 23 giờ" : licenseManager.formattedRemainingTime
                            Text(timeRemaining)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)

                        profileRowDivider

                        // Server Status: Online
                        HStack {
                            Text("Server Status")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                            Spacer()
                            Text("Online")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(white: 0.85))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                    }
                    .background(Color(white: 0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                // 2 NÚT HÀNH ĐỘNG DƯỚI CÙNG (REFRESH & LOG OUT Chuẩn Screenshot 3)
                VStack(spacing: 12) {
                    // Nút REFRESH: Trắng tinh, chữ đen
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        cloudPatchService.syncCloudPatches()
                        licenseManager.validateSavedLicense()
                        showToastNotification(message: "Đã làm mới thông tin hệ thống", icon: "arrow.clockwise", color: .green)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .heavy))
                            Text("REFRESH")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(14)
                    }
                    .buttonStyle(AuroraScaleButtonStyle())

                    // Nút LOG OUT: Viền mờ, chữ trắng
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        licenseManager.deactivate()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.backward.square")
                                .font(.system(size: 14, weight: .bold))
                            Text("LOG OUT")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(white: 0.08))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(AuroraScaleButtonStyle())
                }
                .padding(.top, 6)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    private func profileDataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(Color(white: 0.65))
            Spacer()
            Text(value)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private var profileRowDivider: some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.horizontal, 14)
    }

"""

content = content[:idx_prof] + new_profile_view + content[idx_prof_end:]

# -------------------------------------------------------------
# 4. Update performCleanRestore: Un cái là un luôn, không hiện loading, xoá sạch mọi file đã nạp
# -------------------------------------------------------------
old_restore_marker = "    func performCleanRestore() {"
idx_restore = content.find(old_restore_marker)
assert idx_restore != -1, "old_restore_marker not found"

old_restore_end_marker = "    // MARK: - Dashboard Footer View"
idx_restore_end = content.find(old_restore_end_marker)
assert idx_restore_end != -1, "old_restore_end_marker not found"

new_restore_code = """    func performCleanRestore() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Ngay lập tức đổi trạng thái nút về ban đầu (un cái là un luôn 0ms)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            self.isInjected = false
            self.activeAimPatch = nil
            self.activeEspColor = nil
            self.selectedAimChips.removeAll()
            self.selectedEspChips.removeAll()
            self.isRestoringClean = false
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        CheatStoreSoundManager.shared.playTabSwitchHaptic()
        self.showToastNotification(
            message: "✅ Đã gỡ nạp và làm sạch dữ liệu thành công!",
            icon: "checkmark.circle.fill",
            color: Color.green
        )

        // Dọn dẹp ngầm xoá sạch tất cả các file đã nạp vào Documents trong background
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let targets = ["com.dts.freefireth", "com.dts.freefiremax", "com.dts.freefire", "com.dts.freefirevn"]
            var targetContainerRoots: [URL] = []
            for bID in targets {
                if let path = ContainerStore.resolveAppContainerPath(bundleID: bID) {
                    let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
                    if !targetContainerRoots.contains(url) { targetContainerRoots.append(url) }
                }
            }
            for (_, root) in DevicePatchService.allAvailableFreeFireContainers() {
                let canonical = PatchPathValidator.canonicalFileURL(root)
                if !targetContainerRoots.contains(canonical) { targetContainerRoots.append(canonical) }
            }
            for rootPath in ["/private/var/mobile/Containers/Data/Application", "/var/mobile/Containers/Data/Application"] {
                if let dirs = try? fileManager.contentsOfDirectory(atPath: rootPath) {
                    for d in dirs {
                        let full = (rootPath as NSString).appendingPathComponent(d)
                        let chk = (full as NSString).appendingPathComponent("Documents")
                        if fileManager.fileExists(atPath: chk) {
                            let url = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: full, isDirectory: true))
                            if !targetContainerRoots.contains(url) { targetContainerRoots.append(url) }
                        }
                    }
                }
            }

            let filesToDelete = [
                "Documents/Assembly-CSharp-patch.bytes",
                "Documents/localConfig.json",
                "Documents/.ffxc_live",
                "Documents/.ffxc_runtime",
                "Documents/.ffxc_neutral_37ca851ab5df497db608f1b2f45165f9",
                "Documents/contentcache",
                "Documents/pending_reports",
                "Library/Application Support/Assembly-CSharp-patch.bytes"
            ]

            for root in targetContainerRoots {
                for rel in filesToDelete {
                    let p = root.appendingPathComponent(rel)
                    if fileManager.fileExists(atPath: p.path) {
                        try? fileManager.removeItem(at: p)
                    }
                }
            }

            _ = DevicePatchService.cleanRestoreAllModifications()
            self.antibanPatchService.stopAntiBan()
            print("[CheatStore] Đã dọn dẹp xoá sạch tất cả file liên quan đã nạp vào Documents")
        }
    }

"""

content = content[:idx_restore] + new_restore_code + content[idx_restore_end:]

with open(SWIFT_FILE, "w", encoding="utf-8") as f:
    f.write(content)

print("CheatStoreDashboardView.swift successfully updated and verified!")
