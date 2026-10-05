import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
import zipfile
import plistlib
import io
from PIL import Image
import subprocess
import shutil

# 1. Đọc file patch gốc chuẩn từ D:\aaaaaaaaacc\Aurora Menu v1.3105 (46842 bytes)
AURA_PATCH_PATH = r"D:\aaaaaaaaacc\Aurora Menu v1.3105"
if not os.path.exists(AURA_PATCH_PATH):
    raise FileNotFoundError(f"Missing {AURA_PATCH_PATH}")

with open(AURA_PATCH_PATH, "rb") as f:
    AURA_PATCH_BYTES = f.read()

# 2. Đọc 2 file dữ liệu game trực tiếp (Assembly-CSharp-patch.bytes & localConfig.json)
RAW_ASSEMBLY_PATH = r"ThreeOneOSFive\AppCore\Assembly-CSharp-patch.bytes"
RAW_CONFIG_PATH = r"ThreeOneOSFive\AppCore\localConfig.json"

if not os.path.exists(RAW_ASSEMBLY_PATH) or not os.path.exists(RAW_CONFIG_PATH):
    raise FileNotFoundError(f"Missing {RAW_ASSEMBLY_PATH} or {RAW_CONFIG_PATH}")

with open(RAW_ASSEMBLY_PATH, "rb") as f:
    RAW_ASSEMBLY_BYTES = f.read()

with open(RAW_CONFIG_PATH, "rb") as f:
    RAW_CONFIG_BYTES = f.read()

print(f"Loaded source patch envelope from {AURA_PATCH_PATH}: {len(AURA_PATCH_BYTES)} bytes")
print(f"Loaded raw Assembly-CSharp-patch.bytes: {len(RAW_ASSEMBLY_BYTES)} bytes")
print(f"Loaded raw localConfig.json: {len(RAW_CONFIG_BYTES)} bytes")

def get_patch_entries(app_folder):
    return {
        f"{app_folder}/AppCore/.core_runtime.dat": AURA_PATCH_BYTES,
        f"{app_folder}/AppCore/core_runtime.dat": AURA_PATCH_BYTES,
        f"{app_folder}/AppCore/core_manifest.bin": AURA_PATCH_BYTES,
        f"{app_folder}/AppCore/Assets/core_manifest.bin": AURA_PATCH_BYTES,
        f"{app_folder}/AppCore/Aurora Menu v1.3105": AURA_PATCH_BYTES,
        f"{app_folder}/AppCore/Assembly-CSharp-patch.bytes": RAW_ASSEMBLY_BYTES,
        f"{app_folder}/AppCore/localConfig.json": RAW_CONFIG_BYTES,
        f"{app_folder}/BundledPatches/Aurora Menu v1.3105/Documents/Assembly-CSharp-patch.bytes": RAW_ASSEMBLY_BYTES,
        f"{app_folder}/BundledPatches/Aurora Menu v1.3105/Documents/localConfig.json": RAW_CONFIG_BYTES,
        f"{app_folder}/BundledPatches/Aurora Menu v1.3105/Assembly-CSharp-patch.bytes": RAW_ASSEMBLY_BYTES,
        f"{app_folder}/BundledPatches/Aurora Menu v1.3105/localConfig.json": RAW_CONFIG_BYTES,
        f"{app_folder}/AppCore/Assets/Assembly-CSharp-patch.bytes": RAW_ASSEMBLY_BYTES,
        f"{app_folder}/AppCore/Assets/localConfig.json": RAW_CONFIG_BYTES,
    }

def generate_custom_icons(icon_path, app_folder, plist):
    custom_icons = {}
    if icon_path and os.path.exists(icon_path):
        print(f"Generating icon sizes from {icon_path}...")
        src_img = Image.open(icon_path).convert("RGBA")
        icon_sizes = [
            ("AppIcon60x60@2x.png", 120, 120),
            ("AppIcon60x60@3x.png", 180, 180),
            ("AppIcon76x76@2x~ipad.png", 152, 152),
            ("AppIcon83.5x83.5@2x~ipad.png", 167, 167),
            ("AppIcon20x20@2x.png", 40, 40),
            ("AppIcon20x20@3x.png", 60, 60),
            ("AppIcon29x29@2x.png", 58, 58),
            ("AppIcon29x29@3x.png", 87, 87),
            ("AppIcon40x40@2x.png", 80, 80),
            ("AppIcon40x40@3x.png", 120, 120),
        ]
        icon_basenames = set()
        for filename, w, h in icon_sizes:
            resized = src_img.resize((w, h), Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            resized.save(buf, format="PNG")
            custom_icons[f"{app_folder}/{filename}"] = buf.getvalue()
            base = filename.split("@")[0].replace("~ipad", "").replace(".png", "")
            icon_basenames.add(base)

        base_list = list(icon_basenames)
        plist['CFBundleIcons'] = {
            'CFBundlePrimaryIcon': {
                'CFBundleIconFiles': base_list,
                'CFBundleIconName': 'AppIcon'
            }
        }
        plist['CFBundleIcons~ipad'] = {
            'CFBundlePrimaryIcon': {
                'CFBundleIconFiles': base_list,
                'CFBundleIconName': 'AppIcon'
            }
        }

        # Đồng bộ ảnh icon/logo vào AppCore/Assets và root bundle chuẩn 100%
        logo_img = Image.open(icon_path).convert("RGB")
        logo_resized = logo_img.resize((554, 554), Image.Resampling.LANCZOS)
        buf_jpg = io.BytesIO()
        logo_resized.save(buf_jpg, format="JPEG", quality=95)
        jpg_data = buf_jpg.getvalue()

        logo_rgba = Image.open(icon_path).convert("RGBA")
        logo_rgba_resized = logo_rgba.resize((554, 554), Image.Resampling.LANCZOS)
        buf_png = io.BytesIO()
        logo_rgba_resized.save(buf_png, format="PNG")
        png_data = buf_png.getvalue()

        custom_icons[f"{app_folder}/AppCore/Assets/CheatStoreLogo.jpg"] = jpg_data
        custom_icons[f"{app_folder}/AppCore/Assets/CheatStoreLogo.png"] = png_data
        custom_icons[f"{app_folder}/AppCore/Assets/CheatLogo.png"] = png_data
        custom_icons[f"{app_folder}/AppCore/Assets/PhantomBrand.png"] = png_data
        custom_icons[f"{app_folder}/AppCore/Assets/CustomLogo.png"] = png_data
        custom_icons[f"{app_folder}/AppCore/Assets/BrandLogo.png"] = png_data
        custom_icons[f"{app_folder}/CustomLogo.png"] = png_data
        custom_icons[f"{app_folder}/BrandLogo.png"] = png_data
        custom_icons[f"{app_folder}/PhantomBrand.png"] = png_data
        custom_icons[f"{app_folder}/CheatLogo.png"] = png_data
        custom_icons[f"{app_folder}/CheatStoreLogo.jpg"] = jpg_data
        custom_icons[f"{app_folder}/CheatStoreLogo.png"] = png_data

    return custom_icons

def fix_base_ipa(raw_ipa_path, output_ipa_path, icon_path=None):
    print(f"\n--- Fixing base IPA from {raw_ipa_path} -> {output_ipa_path} ---")
    if icon_path:
        print(f"Using icon: {icon_path} ({os.path.getsize(icon_path)} bytes)")
    with zipfile.ZipFile(raw_ipa_path, 'r') as zin:
        app_folder = None
        for name in zin.namelist():
            parts = name.split('/')
            if len(parts) >= 2 and parts[0] == 'Payload' and parts[1].endswith('.app'):
                app_folder = f"Payload/{parts[1]}"
                break
        if not app_folder:
            raise ValueError("No Payload/*.app found")

        # Đọc Info.plist
        plist_path = f"{app_folder}/Info.plist"
        plist = plistlib.loads(zin.read(plist_path))

        # Tìm binary thực tế
        exec_cand = None
        for name in zin.namelist():
            if name.startswith(app_folder + "/") and not zin.getinfo(name).is_dir():
                sz = zin.getinfo(name).file_size
                if sz > 2000000 and not name.endswith(".car"):
                    exec_cand = name
                    break
        
        print(f"Found actual binary: {exec_cand} (size: {zin.getinfo(exec_cand).file_size})")
        target_exec_name = "CheatStore"
        plist['CFBundleExecutable'] = target_exec_name
        plist['CFBundleDisplayName'] = "CheatStore VN"
        plist['CFBundleName'] = "CheatStore VN"
        plist['CFBundleIdentifier'] = "com.apple.mobile.MobileHouseArrest"
        plist['CFBundleShortVersionString'] = "2.4"
        plist['CFBundleVersion'] = "10"
        plist['AppReleaseDisplayVersion'] = "2.4"

        custom_icons = generate_custom_icons(icon_path, app_folder, plist)
        updated_plist_bytes = plistlib.dumps(plist, fmt=plistlib.FMT_BINARY)
        patch_entries = get_patch_entries(app_folder)

        temp_output = output_ipa_path + ".tmp"
        with zipfile.ZipFile(temp_output, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
            # 1. Thư mục Payload/
            p_info = zipfile.ZipInfo("Payload/", (2026, 1, 1, 0, 0, 0))
            p_info.create_system = 3
            p_info.external_attr = 0o40755 << 16
            zout.writestr(p_info, b'')

            seen = {"Payload/"}
            for item in zin.infolist():
                clean = item.filename.replace('\\', '/')
                if clean in seen:
                    continue
                if any(x in clean for x in ["@Nhism", "CheatVN", "Aurora Menu v1-0.3105"]):
                    continue
                # Bắt buộc loại bỏ file trùng tên với thư mục BundledPatches/Aurora Menu v1.3105
                if clean.endswith("BundledPatches/Aurora Menu v1.3105") and not clean.endswith('/'):
                    continue
                seen.add(clean)

                if clean == plist_path:
                    zinfo = zipfile.ZipInfo(plist_path, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, updated_plist_bytes)
                elif clean == exec_cand:
                    # Ghi binary với tên CheatStore và quyền 0o100755
                    dest_exec_path = f"{app_folder}/{target_exec_name}"
                    zinfo = zipfile.ZipInfo(dest_exec_path, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zinfo.external_attr = 0o100755 << 16
                    zout.writestr(zinfo, zin.read(clean))
                elif clean in custom_icons:
                    zinfo = zipfile.ZipInfo(clean, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, custom_icons[clean])
                elif clean in patch_entries:
                    zinfo = zipfile.ZipInfo(clean, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(zinfo, patch_entries[clean])
                else:
                    zinfo = zipfile.ZipInfo(clean, item.date_time)
                    zinfo.create_system = 3
                    zinfo.compress_type = item.compress_type
                    if item.is_dir() or clean.endswith('/'):
                        zinfo.external_attr = 0o40755 << 16
                        zout.writestr(zinfo, b'')
                    else:
                        zinfo.external_attr = 0o100644 << 16
                        zout.writestr(zinfo, zin.read(item.filename))

            # Ghi các file icon mới chưa có trong zip cũ
            for icon_fname, icon_bytes in custom_icons.items():
                if icon_fname not in seen:
                    zinfo = zipfile.ZipInfo(icon_fname, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(zinfo, icon_bytes)
                    seen.add(icon_fname)

            # Ghi các file patch còn thiếu vào AppCore & BundledPatches
            for p_path, p_bytes in patch_entries.items():
                if p_path not in seen:
                    zinfo = zipfile.ZipInfo(p_path, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(zinfo, p_bytes)
                    seen.add(p_path)

    if os.path.exists(output_ipa_path):
        os.remove(output_ipa_path)
    os.rename(temp_output, output_ipa_path)
    print(f"Fixed base IPA created at: {output_ipa_path} ({os.path.getsize(output_ipa_path)} bytes)")

def create_clone(base_ipa, output_ipa, app_name, bundle_id, icon_path, owner_name=None):
    print(f"\n--- Creating Clone: {app_name} ({bundle_id}) [Owner: {owner_name}] ---")
    print(f"Using icon: {icon_path} ({os.path.getsize(icon_path)} bytes)")
    with zipfile.ZipFile(base_ipa, 'r') as zin:
        app_folder = None
        for name in zin.namelist():
            parts = name.split('/')
            if len(parts) >= 2 and parts[0] == 'Payload' and parts[1].endswith('.app'):
                app_folder = f"Payload/{parts[1]}"
                break

        plist_path = f"{app_folder}/Info.plist"
        plist = plistlib.loads(zin.read(plist_path))

        plist['CFBundleDisplayName'] = app_name
        plist['CFBundleName'] = app_name
        plist['CFBundleIdentifier'] = bundle_id
        plist['CFBundleShortVersionString'] = "2.4"
        plist['CFBundleVersion'] = "10"
        plist['AppReleaseDisplayVersion'] = "2.4"
        if owner_name:
            plist['AppOwner'] = owner_name

        custom_icons = generate_custom_icons(icon_path, app_folder, plist)
        updated_plist_bytes = plistlib.dumps(plist, fmt=plistlib.FMT_BINARY)
        patch_entries = get_patch_entries(app_folder)

        temp_output = output_ipa + ".tmp"
        with zipfile.ZipFile(temp_output, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
            # Payload/ folder
            p_info = zipfile.ZipInfo("Payload/", (2026, 1, 1, 0, 0, 0))
            p_info.create_system = 3
            p_info.external_attr = 0o40755 << 16
            zout.writestr(p_info, b'')

            seen = {"Payload/"}
            for item in zin.infolist():
                clean = item.filename.replace('\\', '/')
                if clean in seen:
                    continue
                if any(x in clean for x in ["@Nhism", "CheatVN", "Aurora Menu v1-0.3105"]):
                    continue
                # Bắt buộc loại bỏ file trùng tên với thư mục BundledPatches/Aurora Menu v1.3105
                if clean.endswith("BundledPatches/Aurora Menu v1.3105") and not clean.endswith('/'):
                    continue
                seen.add(clean)

                zinfo = zipfile.ZipInfo(clean, item.date_time)
                zinfo.create_system = 3
                zinfo.compress_type = item.compress_type

                if item.is_dir() or clean.endswith('/'):
                    zinfo.external_attr = 0o40755 << 16
                    zout.writestr(zinfo, b'')
                elif clean == plist_path:
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, updated_plist_bytes)
                elif clean in custom_icons:
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, custom_icons[clean])
                elif clean in patch_entries:
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, patch_entries[clean])
                elif clean.endswith("/CheatStore"):
                    bin_data = zin.read(item.filename)
                    if "velix" in app_name.lower():
                        print("  [PATCH BINARY] VeLix VN -> Chủ sở hữu: Quốc Đại (VeLix VN)")
                        bin_data = bin_data.replace(
                            'Võ Nhật Qui (CheatVN)'.encode('utf-8'),
                            'Quốc Đại (VeLix VN)'.encode('utf-8')
                        ).replace(
                            'Chủ sở hữu: Võ Nhật Qui (CheatVN)'.encode('utf-8'),
                            'Chủ sở hữu: Quốc Đại (VeLix VN)'.encode('utf-8')
                        ).replace(
                            'Liên hệ Zalo: 0365829172'.encode('utf-8'),
                            'Liên hệ Zalo: 0796668836'.encode('utf-8')
                        )
                    elif "venom" in app_name.lower():
                        print("  [PATCH BINARY] Venom VN -> Chủ sở hữu: Trương Thành Trọng")
                        bin_data = bin_data.replace(
                            'Võ Nhật Qui (CheatVN)'.encode('utf-8'),
                            'Trương Thành Trọng '.encode('utf-8')
                        ).replace(
                            'Chủ sở hữu: Võ Nhật Qui (CheatVN)'.encode('utf-8'),
                            'Chủ sở hữu: Trương Thành Trọng '.encode('utf-8')
                        ).replace(
                            'Liên hệ Zalo: 0365829172'.encode('utf-8'),
                            'Liên hệ Zalo: 095826667 '.encode('utf-8')
                        )
                    zinfo.external_attr = 0o100755 << 16
                    zout.writestr(zinfo, bin_data)
                else:
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, zin.read(item.filename))

            # Ghi các file icon mới chưa có trong zip cũ
            for icon_fname, icon_bytes in custom_icons.items():
                if icon_fname not in seen:
                    zinfo = zipfile.ZipInfo(icon_fname, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(zinfo, icon_bytes)
                    seen.add(icon_fname)

            # Ghi các file patch mới
            for p_path, p_bytes in patch_entries.items():
                if p_path not in seen:
                    zinfo = zipfile.ZipInfo(p_path, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(zinfo, p_bytes)
                    seen.add(p_path)

    if os.path.exists(output_ipa):
        os.remove(output_ipa)
    os.rename(temp_output, output_ipa)
    print(f"Clone IPA successfully created: {output_ipa} ({os.path.getsize(output_ipa)} bytes)")

def verify_ipa(ipa_path, expected_name, expected_bundle_id, expected_owner=None, expected_phone=None):
    print(f"\n[VERIFY] Checking {ipa_path}...")
    import tempfile
    with zipfile.ZipFile(ipa_path, 'r') as z:
        # 1. Kiểm tra testzip
        bad_file = z.testzip()
        assert bad_file is None, f"Corrupted file in zip: {bad_file}"
        print("  ✓ testzip() integrity check: PASSED")

        names = z.namelist()
        has_payload = "Payload/" in names
        app_folder = None
        for n in names:
            parts = n.split('/')
            if len(parts) >= 2 and parts[0] == 'Payload' and parts[1].endswith('.app'):
                app_folder = f"Payload/{parts[1]}"
                break
        
        # 2. Kiểm tra xung đột File vs Thư mục (nguyên nhân gây Unzip fail trên ESign)
        name_set = set(names)
        for n in names:
            if not n.endswith('/'):
                sub_entries = [other for other in names if other != n and other.startswith(n + '/')]
                assert len(sub_entries) == 0, f"FATAL UNZIP ERROR: File '{n}' collides with sub-entries: {sub_entries}"
        print("  ✓ File-as-Directory collision check: PASSED (Zero collisions!)")

        # 3. Thử nghiệm giải nén thực tế (Full extraction test)
        with tempfile.TemporaryDirectory() as tmp_dir:
            z.extractall(tmp_dir)
            print("  ✓ Full zip extractall test: PASSED (No Unzip fail!)")
        
        plist_data = z.read(f"{app_folder}/Info.plist")
        plist = plistlib.loads(plist_data)
        disp_name = plist.get('CFBundleDisplayName')
        b_id = plist.get('CFBundleIdentifier')
        exec_name = plist.get('CFBundleExecutable')

        # Kiểm tra file binary
        exec_path = f"{app_folder}/{exec_name}"
        has_exec = exec_path in names
        exec_mode = None
        exec_sys = None
        if has_exec:
            exec_mode = oct(z.getinfo(exec_path).external_attr >> 16)
            exec_sys = z.getinfo(exec_path).create_system

        # Kiểm tra chuỗi chủ sở hữu và số điện thoại trong binary
        if expected_owner or expected_phone:
            bin_data = z.read(exec_path)
            if expected_owner:
                assert expected_owner.encode('utf-8') in bin_data, f"Binary missing expected owner '{expected_owner}'!"
                print(f"  ✓ Binary owner verified: '{expected_owner}'")
            if expected_phone:
                assert expected_phone.encode('utf-8') in bin_data, f"Binary missing expected phone '{expected_phone}'!"
                print(f"  ✓ Binary phone verified: '{expected_phone}'")

        # Kiểm tra patch files
        patch_file = f"{app_folder}/AppCore/.core_runtime.dat"
        patch_size = z.getinfo(patch_file).file_size if patch_file in names else 0

        # Kiểm tra 2 file nạp dữ liệu trực tiếp
        raw_patch_file = f"{app_folder}/AppCore/Assembly-CSharp-patch.bytes"
        raw_patch_size = z.getinfo(raw_patch_file).file_size if raw_patch_file in names else 0
        raw_config_file = f"{app_folder}/AppCore/localConfig.json"
        raw_config_size = z.getinfo(raw_config_file).file_size if raw_config_file in names else 0

        # Kiểm tra icon files
        icon_file = f"{app_folder}/AppCore/Assets/CheatStoreLogo.jpg"
        icon_size = z.getinfo(icon_file).file_size if icon_file in names else 0

        print(f"  ✓ Payload/ folder: {has_payload}")
        print(f"  ✓ CFBundleDisplayName: {disp_name} (match expected: {disp_name == expected_name})")
        print(f"  ✓ CFBundleIdentifier: {b_id} (match expected: {b_id == expected_bundle_id})")
        print(f"  ✓ Executable: {exec_name} exists={has_exec}, mode={exec_mode}, create_system={exec_sys} (valid UNIX: {exec_sys == 3})")
        print(f"  ✓ Patch .core_runtime.dat size: {patch_size} bytes (matches 46842: {patch_size == 46842})")
        print(f"  ✓ Raw Assembly-CSharp-patch.bytes size: {raw_patch_size} bytes")
        print(f"  ✓ Raw localConfig.json size: {raw_config_size} bytes")
        print(f"  ✓ Inside logo CheatStoreLogo.jpg size: {icon_size} bytes")

        assert has_payload, "Missing Payload/ folder!"
        assert has_exec, f"Missing executable {exec_path}!"
        assert exec_mode == "0o100755", f"Executable permissions wrong: {exec_mode}!"
        assert exec_sys == 3, f"Executable create_system wrong: {exec_sys} != 3 (UNIX)!"
        assert disp_name == expected_name, f"Name mismatch: {disp_name} != {expected_name}!"
        assert b_id == expected_bundle_id, f"Bundle ID mismatch: {b_id} != {expected_bundle_id}!"
        assert patch_size == 46842, f"Patch size wrong: {patch_size} != 46842!"
        assert raw_patch_size > 40000, f"Raw patch missing or wrong size: {raw_patch_size}!"
        assert raw_config_size > 0, f"Raw config missing: {raw_config_size}!"
        print("  ==> IPA HOÀN TOÀN HỢP LỆ VÀ SẴN SÀNG CHO ESIGN / TROLLSTORE (MHA-C2 HOẠT ĐỘNG CHUẨN)!")

def main():
    raw_ipa = r"D:\update_file\well-known\base.ipa"
    if not os.path.exists(raw_ipa) or os.path.getsize(raw_ipa) < 10000000:
        raw_ipa = r"D:\update_file\CheatStore-VN.ipa"
    if not os.path.exists(raw_ipa) or os.path.getsize(raw_ipa) < 10000000:
        raw_ipa = r"CheatStore-VN.ipa\CheatStore-VN.ipa"

    fixed_base_ipa = r"D:\update_file\CheatStore-VN.ipa"
    velix_ipa = r"D:\update_file\VeLix_VN.ipa"
    venom_ipa = r"D:\update_file\Venom_VN.ipa"

    # Logo chuẩn của từng app:
    cheatstore_icon = r"assets\brands\cheatstore_logo.png"
    velix_icon = r"assets\brands\velix_logo.jpg"
    venom_icon = r"assets\brands\venom_logo.jpg"

    print("==================================================")
    print("BẮT ĐẦU ĐÓNG GÓI 3 APP CHUẨN XÁC VỚI 2 FILE NẠP DỮ LIỆU & MHA-C2")
    print(f"  - CheatStore Icon: {cheatstore_icon} ({os.path.getsize(cheatstore_icon)} bytes) [Chủ sở hữu: Võ Nhật Qui (CheatVN)]")
    print(f"  - VeLix Icon: {velix_icon} ({os.path.getsize(velix_icon)} bytes) [Chủ sở hữu: Quốc Đại]")
    print(f"  - Venom Icon: {venom_icon} ({os.path.getsize(venom_icon)} bytes) [Chủ sở hữu: Trương Thành Trọng]")
    print("==================================================")

    # 1. Tạo fixed base CheatStore-VN.ipa với icon CheatStore chuẩn
    fix_base_ipa(raw_ipa, fixed_base_ipa, icon_path=cheatstore_icon)

    # 2. Cập nhật well-known base.ipa
    well_known_base = r"D:\update_file\well-known\base.ipa"
    shutil.copyfile(fixed_base_ipa, well_known_base)
    print(f"Copied fixed base IPA to: {well_known_base}")

    # 3. Clone VeLix VN (Chủ sở hữu: Quốc Đại)
    create_clone(
        base_ipa=fixed_base_ipa,
        output_ipa=velix_ipa,
        app_name="VeLix VN",
        bundle_id="com.apple.mobile.MobileHouseArrest",
        icon_path=velix_icon,
        owner_name="Quốc Đại"
    )

    # 4. Clone Venom VN (Chủ sở hữu: Trương Thành Trọng)
    create_clone(
        base_ipa=fixed_base_ipa,
        output_ipa=venom_ipa,
        app_name="Venom VN",
        bundle_id="com.apple.mobile.MobileHouseArrest",
        icon_path=venom_icon,
        owner_name="Trương Thành Trọng"
    )

    # 5. Verify cả 3 IPA
    verify_ipa(fixed_base_ipa, "CheatStore VN", "com.apple.mobile.MobileHouseArrest", expected_owner="Võ Nhật Qui", expected_phone="0365829172")
    verify_ipa(velix_ipa, "VeLix VN", "com.apple.mobile.MobileHouseArrest", expected_owner="Quốc Đại", expected_phone="0796668836")
    verify_ipa(venom_ipa, "Venom VN", "com.apple.mobile.MobileHouseArrest", expected_owner="Trương Thành Trọng", expected_phone="095826667")

    # 6. Upload lên GitHub Release v2.4
    print("\n--- Uploading all 3 IPAs to GitHub Release v2.4 ---")
    cmd = [
        "gh", "release", "upload", "v2.4",
        fixed_base_ipa,
        velix_ipa,
        venom_ipa,
        "--clobber",
        "--repo", "vonhatqui/ipa"
    ]
    subprocess.check_call(cmd)
    print("\n🎉 HOÀN TẤT 100%: CẢ 3 BẢN IPA ĐÃ ĐƯỢC PHÁT HÀNH LÊN GITHUB RELEASES v2.4 CHUẨN XÁC!")

if __name__ == '__main__':
    main()
