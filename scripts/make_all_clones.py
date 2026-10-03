import os
import sys
import subprocess
import zipfile
import shutil

def main():
    base_ipa = r"d:\update_file\CheatStore-VN.ipa"
    if not os.path.exists(base_ipa):
        base_ipa = "CheatStore-VN.ipa"
    if not os.path.exists(base_ipa):
        print(f"Error: base IPA not found!")
        sys.exit(1)

    print(f"=== SỬ DỤNG BASE IPA: {base_ipa} ({os.path.getsize(base_ipa)} bytes) ===")

    # 1. Cập nhật base.ipa vào d:\update_file\well-known\base.ipa
    dest_base = r"d:\update_file\well-known\base.ipa"
    if os.path.abspath(base_ipa) != os.path.abspath(dest_base):
        shutil.copyfile(base_ipa, dest_base)
        print(f"Đã cập nhật base.ipa tại: {dest_base}")

    # Copy ra thư mục gốc d:\update_file\CheatStore-VN.ipa nếu khác
    dest_cs = r"d:\update_file\CheatStore-VN.ipa"
    if os.path.abspath(base_ipa) != os.path.abspath(dest_cs):
        shutil.copyfile(base_ipa, dest_cs)

    # 2. Tạo bản clone VeLix VN (Bảo tồn com.apple.mobile.MobileHouseArrest cho MHA-C2)
    print("\n--- Đang đóng gói VeLix VN ---")
    velix_icon = "assets/brands/velix_logo.jpg"
    velix_output = r"d:\update_file\VeLix_VN.ipa"
    cmd_velix = [
        sys.executable, "scripts/ipa_cloner.py",
        "--base-ipa", base_ipa,
        "--output", velix_output,
        "--app-name", "VeLix VN",
        "--bundle-id", "com.apple.mobile.MobileHouseArrest",
        "--version", "2.4",
        "--icon", velix_icon
    ]
    subprocess.check_call(cmd_velix)

    # 3. Tạo bản clone Venom VN (Bảo tồn com.apple.mobile.MobileHouseArrest cho MHA-C2)
    print("\n--- Đang đóng gói Venom VN ---")
    venom_icon = "assets/brands/venom_logo.jpg"
    venom_output = r"d:\update_file\Venom_VN.ipa"
    cmd_venom = [
        sys.executable, "scripts/ipa_cloner.py",
        "--base-ipa", base_ipa,
        "--output", venom_output,
        "--app-name", "Venom VN",
        "--bundle-id", "com.apple.mobile.MobileHouseArrest",
        "--version", "2.4",
        "--icon", venom_icon
    ]
    subprocess.check_call(cmd_venom)

    # 4. Kiểm tra cấu trúc & logo bên trong cả 3 IPA
    print("\n--- Kiểm tra cấu trúc và logo bên trong các IPA ---")
    for ipa_name, ipa_path in [("CheatStore VN", r"d:\update_file\CheatStore-VN.ipa"),
                               ("VeLix VN", velix_output),
                               ("Venom VN", venom_output)]:
        with zipfile.ZipFile(ipa_path, 'r') as z:
            names = z.namelist()
            print(f"[{ipa_name}] Tổng số files: {len(names)}, Kích thước: {os.path.getsize(ipa_path)} bytes")
            # Kiểm tra Payload/ folder
            has_payload = any(n == "Payload/" for n in names)
            # Kiểm tra executable permission
            exec_perm = None
            for item in z.infolist():
                if item.filename.endswith("/CheatStore"):
                    exec_perm = oct(item.external_attr >> 16)
                    break
            print(f"  -> Có thư mục Payload/: {has_payload}, Quyền binary: {exec_perm}")
            # Kiểm tra các file logo
            logos = [n for n in names if any(x in n for x in ["CheatStoreLogo.jpg", "CheatStoreLogo.png", "CustomLogo.png", "AppIcon60x60@2x.png"])]
            print(f"  -> Files logo: {logos}")

    # 5. Tải cả 3 file lên GitHub Releases v2.4
    print("\n--- Tải cả 3 file IPA lên GitHub Release v2.4 ---")
    upload_cmd = [
        "gh", "release", "upload", "v2.4",
        r"d:\update_file\CheatStore-VN.ipa",
        velix_output,
        venom_output,
        "--clobber",
        "--repo", "vonhatqui/ipa"
    ]
    subprocess.check_call(upload_cmd)
    print("\n✅ Hoàn tất upload cả 3 file IPA lên GitHub Release v2.4!")

if __name__ == "__main__":
    main()
