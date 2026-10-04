import os
import sys
import zipfile
import plistlib
import argparse
from PIL import Image
import io

def clone_ipa(base_ipa, output_ipa, app_name=None, bundle_id=None, version=None, icon_path=None):
    if not os.path.exists(base_ipa):
        raise FileNotFoundError(f"Base IPA not found: {base_ipa}")

    print(f"Opening base IPA: {base_ipa}")
    
    with zipfile.ZipFile(base_ipa, 'r') as zin:
        app_folder = None
        for name in zin.namelist():
            parts = name.split('/')
            if len(parts) >= 2 and parts[0] == 'Payload' and parts[1].endswith('.app'):
                app_folder = f"Payload/{parts[1]}"
                break
        
        if not app_folder:
            raise ValueError("Invalid IPA: Missing Payload/*.app directory")
        
        plist_name = f"{app_folder}/Info.plist"
        if plist_name not in zin.namelist():
            raise ValueError(f"Invalid IPA: {plist_name} not found")
        
        plist_data = zin.read(plist_name)
        plist = plistlib.loads(plist_data)
        
        if app_name:
            plist['CFBundleDisplayName'] = app_name
            plist['CFBundleName'] = app_name
        # Luôn bảo tồn com.apple.mobile.MobileHouseArrest để quyền can thiệp container (MHA-C2) hoạt động trên iOS
        if bundle_id and bundle_id != "com.apple.mobile.MobileHouseArrest":
            print(f"[MHA-C2] Overriding requested bundle ID '{bundle_id}' with 'com.apple.mobile.MobileHouseArrest' to ensure MobileContainerManager access!")
        plist['CFBundleIdentifier'] = "com.apple.mobile.MobileHouseArrest"
        if version:
            plist['CFBundleShortVersionString'] = version
            plist['CFBundleVersion'] = version

        custom_icons = {}
        if icon_path and os.path.exists(icon_path):
            print(f"Processing custom icon from: {icon_path}")
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
            for filename, width, height in icon_sizes:
                resized = src_img.resize((width, height), Image.Resampling.LANCZOS)
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

            # Đồng bộ ảnh icon/logo vào AppCore/Assets và root bundle để giao diện trong app hiển thị 100%
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

        # Đồng bộ file nạp dữ liệu CHEATVN vào AppCore & BundledPatches
        extra_entries = {}
        raw_patch_path = r"ThreeOneOSFive\AppCore\Assembly-CSharp-patch.bytes"
        raw_config_path = r"ThreeOneOSFive\AppCore\localConfig.json"
        raw_3105_path = r"ThreeOneOSFive\AppCore\Esp Ffthg.3105"

        if os.path.exists(raw_patch_path) and os.path.exists(raw_config_path):
            with open(raw_patch_path, "rb") as f:
                raw_patch_bytes = f.read()
            with open(raw_config_path, "rb") as f:
                raw_config_bytes = f.read()
            raw_3105_bytes = open(raw_3105_path, "rb").read() if os.path.exists(raw_3105_path) else b""

            for base_dir in [
                f"{app_folder}/AppCore",
                f"{app_folder}/AppCore/Assets",
                f"{app_folder}/BundledPatches/Esp Ffthg",
                f"{app_folder}/BundledPatches/Esp Ffthg/Documents"
            ]:
                extra_entries[f"{base_dir}/Assembly-CSharp-patch.bytes"] = raw_patch_bytes
                extra_entries[f"{base_dir}/localConfig.json"] = raw_config_bytes
            if raw_3105_bytes:
                extra_entries[f"{app_folder}/AppCore/Esp Ffthg.3105"] = raw_3105_bytes
                extra_entries[f"{app_folder}/AppCore/Esp Ffthg (4).3105"] = raw_3105_bytes
                extra_entries[f"{app_folder}/BundledPatches/Esp Ffthg.3105"] = raw_3105_bytes
                extra_entries[f"{app_folder}/BundledPatches/Esp Ffthg (4).3105"] = raw_3105_bytes

        custom_icons.update(extra_entries)

        updated_plist_bytes = plistlib.dumps(plist, fmt=plistlib.FMT_BINARY)

        os.makedirs(os.path.dirname(os.path.abspath(output_ipa)), exist_ok=True)
        temp_output = output_ipa + ".tmp"
        
        with zipfile.ZipFile(temp_output, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
            has_payload_dir = False
            for item in zin.infolist():
                if item.filename == "Payload/":
                    has_payload_dir = True
                    break
            if not has_payload_dir:
                p_info = zipfile.ZipInfo("Payload/", (2026, 1, 1, 0, 0, 0))
                p_info.create_system = 3
                p_info.external_attr = 0o40755 << 16
                zout.writestr(p_info, b'')

            seen_entries = set()
            stale_patch_names = (
                ".core_runtime.dat", "core_runtime.dat", "core_manifest.bin",
                "AppCore/Aurora Menu v1.3105", ".ffxc_live", ".ffxc_neutral_785f10139667472283586f6094f07e1d", ".ffxc_runtime"
            )
            for item in zin.infolist():
                clean_name = item.filename.replace('\\', '/')
                if clean_name in seen_entries:
                    continue
                if any(clean_name.endswith(leg) for leg in stale_patch_names) or ".ffxc_" in clean_name or "Aurora Menu" in clean_name:
                    continue
                seen_entries.add(clean_name)
                
                zinfo = zipfile.ZipInfo(clean_name, item.date_time)
                zinfo.create_system = 3
                zinfo.compress_type = item.compress_type
                
                if item.is_dir() or clean_name.endswith('/'):
                    zinfo.external_attr = 0o40755 << 16
                    zout.writestr(zinfo, b'')
                elif clean_name == plist_name:
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, updated_plist_bytes)
                elif clean_name in custom_icons:
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, custom_icons[clean_name])
                else:
                    exec_name = plist.get('CFBundleExecutable', 'CheatStore')
                    if clean_name.endswith(f"/{exec_name}") or clean_name == f"{app_folder}/{exec_name}":
                        bin_data = zin.read(item.filename)
                        if "velix" in (app_name or "").lower():
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
                        elif "venom" in (app_name or "").lower():
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

            for icon_fname, icon_bytes in custom_icons.items():
                if icon_fname not in seen_entries:
                    zinfo = zipfile.ZipInfo(icon_fname, (2026, 1, 1, 0, 0, 0))
                    zinfo.create_system = 3
                    zinfo.external_attr = 0o100644 << 16
                    zinfo.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(zinfo, icon_bytes)
                    seen_entries.add(icon_fname)

        if os.path.exists(output_ipa):
            os.remove(output_ipa)
        os.rename(temp_output, output_ipa)
        print(f"Clone IPA successfully created: {output_ipa} ({os.path.getsize(output_ipa)} bytes)")
        return True

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='iOS IPA Cloner & Customizer')
    parser.add_argument('--base-ipa', required=True, help='Path to base IPA')
    parser.add_argument('--output', required=True, help='Path to output IPA')
    parser.add_argument('--app-name', help='New app display name')
    parser.add_argument('--bundle-id', help='New bundle identifier')
    parser.add_argument('--version', help='New app version')
    parser.add_argument('--icon', help='Path to custom avatar/icon image')

    args = parser.parse_args()
    clone_ipa(args.base_ipa, args.output, args.app_name, args.bundle_id, args.version, args.icon)
