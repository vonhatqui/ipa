#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Rebrand DELTA CLIENT IPA into CheatStore VN IPA
- Preserves full in-game exploit / MobileHouseArrest functionality
- Updates Info.plist (CFBundleDisplayName, CFBundleName)
- Updates AppIcon with CheatStore VN logo
- Patches binary strings: Discord, Telegram, and App Titles
- Strips stale codesign for clean sideloading on Esign/Scarlet/TrollStore/AltStore
"""

import os
import sys
import zipfile
import plistlib
import argparse
from PIL import Image
import io

def rebrand_ipa(base_ipa, output_ipa, icon_path=None):
    if not os.path.exists(base_ipa):
        raise FileNotFoundError(f"Base IPA not found: {base_ipa}")

    print(f"📦 Opening base IPA: {base_ipa}")
    
    # Replacement table: (old_bytes, new_bytes) - MUST MATCH EXACT LENGTH & NO TRAILING SPACES IN URLS
    BINARY_REPLACEMENTS = [
        (b"discord.gg/deltaclient", b"discord.gg/jinwwostore"), # 22 bytes exact
        (b"discord.gg/zrxsoftware", b"discord.gg/jinwwostore"), # 22 bytes exact
        (b"t.me/dovietphuog",       b"t.me/jinwwostore"),     # 16 bytes exact
    ]

    with zipfile.ZipFile(base_ipa, 'r') as zin:
        app_folder = None
        for name in zin.namelist():
            parts = name.split('/')
            if len(parts) >= 2 and parts[0] == 'Payload' and parts[1].endswith('.app'):
                app_folder = f"Payload/{parts[1]}"
                break
        
        if not app_folder:
            raise ValueError("Invalid IPA: Missing Payload/*.app directory")
        
        # 1. Update Info.plist
        plist_name = f"{app_folder}/Info.plist"
        plist_data = zin.read(plist_name)
        plist = plistlib.loads(plist_data)
        
        # CFBundleDisplayName changes the app name shown on iPhone home screen & Esign
        plist['CFBundleDisplayName'] = "CheatStore VN"
        # CFBundleName MUST match CFBundleExecutable (Zrxipa) to avoid iOS bundle loader crash
        plist['CFBundleName'] = "Zrxipa"
        plist['CFBundleExecutable'] = "Zrxipa"
        plist['CFBundleIdentifier'] = "com.apple.mobile.MobileHouseArrest"
        updated_plist_bytes = plistlib.dumps(plist)

        # 2. Process Custom Icons
        custom_icons = {}
        if icon_path and os.path.exists(icon_path):
            print(f"🎨 Generating icons from: {icon_path}")
            src_img = Image.open(icon_path).convert("RGBA")
            icon_sizes = [
                ("AppIcon60x60@2x.png", 120, 120),
                ("AppIcon60x60@3x.png", 180, 180),
                ("AppIcon76x76@2x~ipad.png", 152, 152),
                ("AppIcon83.5x83.5@2x~ipad.png", 167, 167),
                ("AppIcon20x20@2x.png", 40, 40),
                ("AppIcon29x29@2x.png", 58, 58),
                ("AppIcon40x40@2x.png", 80, 80),
            ]
            for filename, width, height in icon_sizes:
                resized = src_img.resize((width, height), Image.Resampling.LANCZOS)
                buf = io.BytesIO()
                resized.save(buf, format="PNG")
                custom_icons[f"{app_folder}/{filename}"] = buf.getvalue()

        # 3. Create Repackaged Output IPA
        temp_output = output_ipa + ".tmp"
        if os.path.exists(temp_output):
            os.remove(temp_output)
            
        print("✍️ Writing repackaged IPA...")
        with zipfile.ZipFile(temp_output, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                clean_name = item.filename.replace('\\', '/')
                
                # Strip signatures and old prov profiles for clean Esign signing
                if "_CodeSignature" in clean_name or "embedded.mobileprovision" in clean_name or "SignedByEsign" in clean_name:
                    continue
                    
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
                elif clean_name == f"{app_folder}/Zrxipa":
                    # Binary patch Zrxipa cleanly without corrupting Swift metadata or URLs
                    print("⚡ Patching binary Zrxipa (safe exact-byte replacements)...")
                    bin_data = zin.read(item.filename)
                    for old_b, new_b in BINARY_REPLACEMENTS:
                        count = bin_data.count(old_b)
                        if count > 0:
                            print(f"   ✓ Replaced '{old_b.decode()}' -> '{new_b.decode()}' ({count}x)")
                            bin_data = bin_data.replace(old_b, new_b)
                    zinfo.external_attr = 0o100755 << 16
                    zout.writestr(zinfo, bin_data)
                else:
                    # Keep all resource files intact (especially binary plists like Localizable.strings)
                    zinfo.external_attr = 0o100644 << 16
                    zout.writestr(zinfo, zin.read(item.filename))

        if os.path.exists(output_ipa):
            os.remove(output_ipa)
        os.rename(temp_output, output_ipa)
        size_mb = round(os.path.getsize(output_ipa) / (1024 * 1024), 2)
        print(f"🎉 Success! Created: {output_ipa} ({size_mb} MB)")
        return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rebrand DELTA CLIENT to CheatStore VN")
    parser.add_argument("--base-ipa", required=True, help="Path to base DELTA CLIENT IPA")
    parser.add_argument("--output", required=True, help="Path to output CheatStore VN IPA")
    parser.add_argument("--icon", help="Path to icon file")
    args = parser.parse_args()
    
    rebrand_ipa(args.base_ipa, args.output, args.icon)
