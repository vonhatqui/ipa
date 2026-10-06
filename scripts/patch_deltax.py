import sys
import os
import shutil
import struct
import plistlib
import json
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

sys.stdout.reconfigure(encoding='utf-8')

def patch_deltax_bytecode(raw: bytes) -> bytes:
    data = bytearray(raw)
    assert len(data) == 97028, f"Expected 97028 bytes, got {len(data)}"

    # 1. Strings
    # String #0 and #1: \x05DELTA\x09VIP SUITE -> \x06DeltaX\x08Enternal
    orig_s01 = b'\x05DELTA\x09VIP SUITE'
    assert data[0x17218:0x17218+16] == orig_s01, f"Mismatch at 0x17218: {data[0x17218:0x17218+16]}"
    data[0x17218:0x17218+16] = b'\x06DeltaX\x08Enternal'

    # String #7: \x09JustinNam -> \x09 CheatVN 
    orig_s7 = b'\x09JustinNam'
    assert data[0x1727c:0x1727c+10] == orig_s7, f"Mismatch at 0x1727c: {data[0x1727c:0x1727c+10]}"
    data[0x1727c:0x1727c+10] = b'\x09 CheatVN '

    # Gate string: \x05DELTA -> \x05Delta
    if data[0x17114:0x17114+6] == b'\x05DELTA':
        data[0x17114:0x17114+6] = b'\x05Delta'

    # Helper to write RGBA floats (each float is 8 bytes: 4 bytes code=3, 4 bytes float)
    def write_rgba(off, r, g, b, a):
        for i, val in enumerate([r, g, b, a]):
            p = off + i * 8
            code = struct.unpack('<I', data[p:p+4])[0]
            assert code == 3, f"Expected opcode 3 at {hex(p)}, got {code}"
            data[p+4:p+8] = struct.pack('<f', val)

    # 2. Nametag Lime Green -> Bright Red
    write_rgba(0xa817, 1.00, 0.20, 0.20, 1.00)

    # 3. Menu Background -> Black
    write_rgba(0xd8ff, 0.015, 0.015, 0.018, 0.985)

    # 4. Menu Border -> Metallic
    write_rgba(0xd927, 0.30, 0.30, 0.32, 0.85)

    # 5. Header Background -> Black
    write_rgba(0xd9ef, 0.012, 0.012, 0.015, 0.98)

    # 6. Header Border -> Subtle
    write_rgba(0xda2f, 0.20, 0.20, 0.22, 0.90)

    # 7. Title glow 1 & 2 -> Bright White
    write_rgba(0xdabf, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0xdb3f, 1.00, 1.00, 1.00, 1.00)

    # 8. Cyan accents -> Bright White
    write_rgba(0xde2f, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0xdfa7, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0xe1af, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0xfbbf, 1.00, 1.00, 1.00, 1.00)

    # 9. Active buttons -> Dark Sleek
    write_rgba(0x14a0f, 0.18, 0.18, 0.20, 0.95)
    write_rgba(0x14b5f, 0.18, 0.18, 0.20, 0.95)

    # 10. Button highlights -> White
    write_rgba(0x14fb7, 1.00, 1.00, 1.00, 0.95)
    write_rgba(0x15277, 1.00, 1.00, 1.00, 0.95)

    assert len(data) == 97028
    return bytes(data)

def decrypt_envelope(path):
    with open(path, 'rb') as f:
        data = f.read()
    magic = data[:10]
    bplist = data[10:]
    env = plistlib.loads(bplist)
    pkg_id = env['packageID']
    ver = env.get('keyAADVersion') or env.get('schemaVersion', 1)
    content_key = env['publicContentKey']

    payload_raw = env['encryptedPayload']
    p_nonce = payload_raw[:12]
    p_tag = payload_raw[-16:]
    p_ciphertext = payload_raw[12:-16]

    p_aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')
    p_aesgcm = AESGCM(content_key)
    payload_decrypted = p_aesgcm.decrypt(p_nonce, p_ciphertext + p_tag, p_aad)
    project_plist = plistlib.loads(payload_decrypted)
    return env, project_plist

def reencrypt_envelope(env, project_plist):
    content_key = env['publicContentKey']
    pkg_id = env['packageID']
    ver = env.get('keyAADVersion') or env.get('schemaVersion', 1)
    aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')

    new_payload_bytes = plistlib.dumps(project_plist, fmt=plistlib.FMT_BINARY)
    p_nonce = os.urandom(12)
    aesgcm = AESGCM(content_key)
    p_ciphertext_and_tag = aesgcm.encrypt(p_nonce, new_payload_bytes, aad)

    env['encryptedPayload'] = p_nonce + p_ciphertext_and_tag
    magic = b'3105PATCH\0'
    new_env_data = magic + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)
    return new_env_data

def main():
    print("=== BẮT ĐẦU PATCH DELTAX ENTERNAL ===")
    ffm_env_path = r"D:\update_file\aklo\DELTAX FFM .3105"
    ffth_env_path = r"D:\update_file\aklo\DELTAX FFTH .3105"

    env_ffm, proj_ffm = decrypt_envelope(ffm_env_path)
    env_ffth, proj_ffth = decrypt_envelope(ffth_env_path)

    raw_assembly = proj_ffm['project']['rules'][0]['replacementData']
    patched_assembly = patch_deltax_bytecode(raw_assembly)
    config_bytes = proj_ffm['project']['rules'][1]['replacementData']

    # Cập nhật project plist
    proj_ffm['project']['name'] = 'DeltaX Enternal'
    proj_ffm['project']['rules'][0]['replacementData'] = patched_assembly

    proj_ffth['project']['name'] = 'DeltaX Enternal'
    proj_ffth['project']['rules'][0]['replacementData'] = patched_assembly

    # Re-encrypt envelopes
    reencrypted_ffm = reencrypt_envelope(env_ffm, proj_ffm)
    reencrypted_ffth = reencrypt_envelope(env_ffth, proj_ffth)

    # Ghi đè file tại D:\update_file\aklo
    with open(ffm_env_path, "wb") as f:
        f.write(reencrypted_ffm)
    with open(ffth_env_path, "wb") as f:
        f.write(reencrypted_ffth)
    print(f"✅ Đã ghi đè envelope tại {ffm_env_path} ({len(reencrypted_ffm)} bytes)")
    print(f"✅ Đã ghi đè envelope tại {ffth_env_path} ({len(reencrypted_ffth)} bytes)")

    # Lưu các file vào ThreeOneOSFive
    deltax_dirs = [
        r"ThreeOneOSFive\BundledPatches\DeltaX Enternal\Documents",
        r"ThreeOneOSFive\BundledPatches\DeltaX Enternal",
        r"ThreeOneOSFive\AppCore\DeltaX",
    ]
    for d in deltax_dirs:
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Assembly-CSharp-patch.bytes"), "wb") as f:
            f.write(patched_assembly)
        with open(os.path.join(d, "localConfig.json"), "wb") as f:
            f.write(config_bytes)
        print(f"✅ Đã lưu Assembly-CSharp-patch.bytes và localConfig.json vào {d}")

    # Lưu envelopes vào BundledPatches & AppCore
    os.makedirs(r"ThreeOneOSFive\BundledPatches", exist_ok=True)
    os.makedirs(r"ThreeOneOSFive\AppCore", exist_ok=True)

    with open(r"ThreeOneOSFive\BundledPatches\DELTAX FFM .3105", "wb") as f:
        f.write(reencrypted_ffm)
    with open(r"ThreeOneOSFive\BundledPatches\DELTAX FFTH .3105", "wb") as f:
        f.write(reencrypted_ffth)
    with open(r"ThreeOneOSFive\BundledPatches\DeltaX Enternal.3105", "wb") as f:
        f.write(reencrypted_ffm)
    with open(r"ThreeOneOSFive\AppCore\DeltaX Enternal.3105", "wb") as f:
        f.write(reencrypted_ffm)
    with open(r"ThreeOneOSFive\AppCore\.deltax_runtime.dat", "wb") as f:
        f.write(reencrypted_ffm)

    print("✅ Đã lưu tất cả envelope patches vào ThreeOneOSFive")

    # Sao chép logo vào các thư mục assets
    logo_src1 = "cheatvn_external.png"
    logo_src2 = "deltax_enternal.png"

    dest_pairs = [
        (logo_src1, r"ThreeOneOSFive\cheatvn_external.png"),
        (logo_src1, r"ThreeOneOSFive\AppCore\Assets\cheatvn_external.png"),
        (logo_src1, r"assets\brands\cheatvn_external.png"),
        (logo_src2, r"ThreeOneOSFive\deltax_enternal.png"),
        (logo_src2, r"ThreeOneOSFive\AppCore\Assets\deltax_enternal.png"),
        (logo_src2, r"assets\brands\deltax_enternal.png"),
    ]

    for src, dst in dest_pairs:
        if os.path.exists(src):
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(src, dst)
            print(f"✅ Đã sao chép {src} -> {dst}")

    # Tạo Imagesets trong Assets.xcassets
    def create_imageset(name, src_png):
        folder = os.path.join(r"ThreeOneOSFive\Assets.xcassets", f"{name}.imageset")
        os.makedirs(folder, exist_ok=True)
        dst_png = os.path.join(folder, f"{name}.png")
        shutil.copyfile(src_png, dst_png)
        contents = {
            "images": [
                {
                    "filename": f"{name}.png",
                    "idiom": "universal",
                    "scale": "1x"
                },
                {
                    "idiom": "universal",
                    "scale": "2x"
                },
                {
                    "idiom": "universal",
                    "scale": "3x"
                }
            ],
            "info": {
                "author": "xcode",
                "version": 1
            }
        }
        with open(os.path.join(folder, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)
        print(f"✅ Đã tạo xcassets imageset {folder}")

    create_imageset("CheatVNExternal", logo_src1)
    create_imageset("DeltaXEnternal", logo_src2)

    print("🎉 HOÀN TẤT PATCHING VÀ SAO CHÉP TẤT CẢ TÀI NGUYÊN DELTAX!")

if __name__ == "__main__":
    main()
