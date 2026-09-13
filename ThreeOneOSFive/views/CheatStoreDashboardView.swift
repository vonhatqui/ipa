import SwiftUI

struct CheatStoreDashboardView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @ObservedObject var licenseManager = CheatStoreLicenseManager.shared
    @State private var workingPatchID: UUID?
    @State private var alertMessage: String?
    @State private var showAlert = false

    private let brandGreen = Color(red: 0.06, green: 0.73, blue: 0.51)
    private let darkBackground = Color(red: 0.05, green: 0.06, blue: 0.08)

    var body: some View {
        NavigationView {
            ZStack {
                darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Card Trạng Thái Bản Quyền
                        licenseStatusCard

                        // Tiêu Đề Danh Sách Chức Năng
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BẢNG ĐIỀU KHIỂN CHỨC NĂNG")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(brandGreen)
                                    .tracking(1.1)

                                Text("Bật / Tắt Mod & Tiện Ích Trực Tiếp")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.gray)
                            }
                            Spacer()

                            Button {
                                BundledPatchInjector.autoImportBundledPatches(into: patchStore)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(brandGreen)
                                    .padding(8)
                                    .background(brandGreen.opacity(0.12))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // Danh sách Chức Năng Hack / Mod
                        if patchStore.items.isEmpty {
                            emptyStateView
                        } else {
                            VStack(spacing: 14) {
                                ForEach(patchStore.items) { item in
                                    CheatItemCard(
                                        item: item,
                                        isWorking: workingPatchID == item.id,
                                        onToggle: { enable in
                                            handleToggle(item: item, enable: enable)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("CheatStore VN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        licenseManager.deactivate()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Thông báo"),
                    message: Text(alertMessage ?? ""),
                    dismissButton: .default(Text("Đã hiểu"))
                )
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            BundledPatchInjector.autoImportBundledPatches(into: patchStore)
        }
    }

    private var licenseStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(brandGreen.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(brandGreen)
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(licenseManager.planName.isEmpty ? "GÓI VIP" : licenseManager.planName.uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)

                        Text(licenseManager.activeKey)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("TRẠNG THÁI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(brandGreen)
                            .frame(width: 6, height: 6)
                        Text("Đã Kích Hoạt")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(brandGreen)
                    }
                }
            }

            if let expiry = licenseManager.expirationDate {
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                    Text("Hạn sử dụng: \(formattedDate(expiry))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandGreen.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.gray)
                .padding(.top, 30)

            Text("Chưa tìm thấy bản mod nào")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text("Vui lòng đảm bảo các file .3105 đã được đặt vào thư mục BundledPatches hoặc nạp qua Tệp.")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button {
                BundledPatchInjector.autoImportBundledPatches(into: patchStore)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Quét lại bản mod")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(brandGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(brandGreen.opacity(0.12))
                .cornerRadius(20)
            }
            .padding(.top, 6)
        }
    }

    private func handleToggle(item: PatchLibraryItem, enable: Bool) {
        workingPatchID = item.id

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if enable {
                    // BẬT chức năng (Apply)
                    guard let project = item.project else {
                        throw PatchPackageError.unsupportedFormat
                    }
                    _ = try DevicePatchService.apply(project: project)
                    let title = item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
                    DispatchQueue.main.async {
                        patchStore.reload()
                        workingPatchID = nil
                        alertMessage = "Đã BẬT thành công chức năng: \(title)"
                        showAlert = true
                    }
                } else {
                    // TẮT chức năng (Restore)
                    guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
                        DispatchQueue.main.async {
                            patchStore.reload()
                            workingPatchID = nil
                        }
                        return
                    }
                    try DevicePatchService.restore(receipt: receipt)
                    let title = item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
                    DispatchQueue.main.async {
                        patchStore.reload()
                        workingPatchID = nil
                        alertMessage = "Đã TẮT và khôi phục an toàn: \(title)"
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    patchStore.reload()
                    workingPatchID = nil
                    alertMessage = "Thao tác thất bại: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}

private struct CheatItemCard: View {
    let item: PatchLibraryItem
    let isWorking: Bool
    let onToggle: (Bool) -> Void

    private let brandGreen = Color(red: 0.06, green: 0.73, blue: 0.51)

    private var displayName: String {
        item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
    }

    private var isApplied: Bool {
        DevicePatchService.latestReceipt(projectID: item.id) != nil
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon chức năng với logo CheatStore
            ZStack {
                CheatStoreLogoView(size: 48, cornerRadius: 12)

                if isApplied {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brandGreen, lineWidth: 2)
                        .frame(width: 48, height: 48)
                }
            }

            // Tên và thông tin chức năng
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let author = item.project?.author, !author.isEmpty {
                    Text("Tác giả: \(author)")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }

                // Trạng thái Bật / Tắt
                HStack(spacing: 4) {
                    Circle()
                        .fill(isApplied ? brandGreen : Color.gray.opacity(0.6))
                        .frame(width: 6, height: 6)

                    Text(isApplied ? "ĐANG BẬT" : "ĐANG TẮT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isApplied ? brandGreen : .gray)
                }
            }

            Spacer()

            // Nút Bật / Tắt Switch
            if isWorking {
                ProgressView()
                    .tint(brandGreen)
                    .frame(width: 50)
            } else {
                Toggle("", isOn: Binding(
                    get: { isApplied },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(brandGreen)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isApplied ? brandGreen.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
