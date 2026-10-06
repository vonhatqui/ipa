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

    # Helper to write RGBA floats (each float is 8 bytes: 4 bytes code=3, 4 bytes float)
    def write_rgba(off, r, g, b, a):
        for i, val in enumerate([r, g, b, a]):
            p = off + i * 8
            code = struct.unpack('<I', data[p:p+4])[0]
            assert code == 3, f"Expected opcode 3 at {hex(p)}, got {code}"
            data[p+4:p+8] = struct.pack('<f', val)

    # 1. STRINGS: Thay thế hoàn toàn ASHOK và đổi tên thành CheatVN External
    # String #32 + #33 (Login Gate): 26 bytes
    # ASHOK (len 5) + SECURE LICENSE GATE (len 19) -> CheatVN (len 7) + EXTERNAL GATE VIP (len 17)
    data[0x17114:0x17114+26] = b'\x07CheatVN\x11EXTERNAL GATE VIP'

    # String #47 (Watermark): 6 bytes
    if data[0x17208:0x17208+6] in [b'\x05ASHOK', b'\x05DELTA']:
        data[0x17208:0x17208+6] = b'\x05Cheat'

    # String #49 + #50 + #51 (Main Menu Header): 24 bytes
    # Enemy: (len 7) + ASHOK (len 5) + VIP SUITE (len 9) -> Enemy: (len 6) + CheatVN (len 7) + External (len 8)
    data[0x17210:0x17210+24] = b'\x06Enemy:\x07CheatVN\x08External'

    # String #57: JustinNam -> CheatVN (10 bytes)
    if data[0x1727c:0x1727c+10] in [b'\x09JustinNam', b'\x09 CheatVN ']:
        data[0x1727c:0x1727c+10] = b'\x09 CheatVN '

    # String #120 (Online status watermark): 6 bytes
    if data[0x175de:0x175de+6] in [b'\x05ASHOK', b'\x05DELTA']:
        data[0x175de:0x175de+6] = b'\x05Cheat'

    # 2. NAMETAG ESP LIME GREEN -> BRIGHT RED
    write_rgba(0xa817, 1.00, 0.20, 0.20, 1.00)

    # 3. LOGIN GATE COLORS (Chuyển sang nền đen chữ trắng sang trọng)
    login_blacks = [
        0x6317, 0x63a7, 0x64a7, 0x6877, 0x6ad7,
        0x6b07, 0x6f0f, 0x6f6f, 0x72d7, 0x747f, 0x75ff
    ]
    for off in login_blacks:
        write_rgba(off, 0.015, 0.015, 0.018, 0.985)

    login_borders = [0x633f, 0x64cf, 0x689f, 0x6b47]
    for off in login_borders:
        write_rgba(off, 0.30, 0.30, 0.32, 0.85)

    login_whites = [
        0x6437, 0x6557, 0x660f, 0x6b77, 0x6e17,
        0x6f3f, 0x6ff7, 0x7267, 0x75cf, 0x762f
    ]
    for off in login_whites:
        write_rgba(off, 1.00, 1.00, 1.00, 1.00)

    # 4. MAIN MENU COLORS (Nền đen chữ trắng sang trọng)
    write_rgba(0xd8ff, 0.015, 0.015, 0.018, 0.985) # Menu Background -> Black
    write_rgba(0xd927, 0.30, 0.30, 0.32, 0.85)     # Menu Border -> Metallic
    write_rgba(0xd9ef, 0.012, 0.012, 0.015, 0.98)  # Header Background -> Black
    write_rgba(0xda2f, 0.20, 0.20, 0.22, 0.90)     # Header Border -> Subtle
    write_rgba(0xdabf, 1.00, 1.00, 1.00, 1.00)     # Title glow 1 -> Bright White
    write_rgba(0xdb3f, 1.00, 1.00, 1.00, 1.00)     # Title glow 2 -> Bright White
    write_rgba(0xde2f, 1.00, 1.00, 1.00, 1.00)     # Cyan accents -> Bright White
    write_rgba(0xdfa7, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0xe1af, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0xfbbf, 1.00, 1.00, 1.00, 1.00)
    write_rgba(0x14a0f, 0.18, 0.18, 0.20, 0.95)   # Active buttons -> Dark Sleek
    write_rgba(0x14b5f, 0.18, 0.18, 0.20, 0.95)
    write_rgba(0x14fb7, 1.00, 1.00, 1.00, 0.95)   # Button highlights -> White
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
    print("=== BẮT ĐẦU PATCH DELTAX / LEAK FILES (CHEATVN EXTERNAL & BLACK THEME) ===")

    # 1. Các nguồn file cần patch
    leak_ffm_path = r"D:\update_file\aklo\leak\OG MENU FFM.3105"
    leak_ffth_path = r"D:\update_file\aklo\leak\OG MENU FFTH.3105"

    source_path = leak_ffm_path if os.path.exists(leak_ffm_path) else r"D:\update_file\aklo\DELTAX FFM .3105"
    print(f"Sử dụng file nguồn: {source_path}")

    env_ffm, proj_ffm = decrypt_envelope(source_path)
    env_ffth, proj_ffth = decrypt_envelope(leak_ffth_path if os.path.exists(leak_ffth_path) else r"D:\update_file\aklo\DELTAX FFTH .3105")

    raw_assembly = proj_ffm['project']['rules'][0]['replacementData']
    patched_assembly = patch_deltax_bytecode(raw_assembly)
    config_bytes = proj_ffm['project']['rules'][1]['replacementData']

    # Cập nhật project plist: Đổi tên thành CheatVN External / DeltaX Enternal
    proj_ffm['project']['name'] = 'CheatVN External'
    proj_ffm['project']['rules'][0]['replacementData'] = patched_assembly

    proj_ffth['project']['name'] = 'CheatVN External'
    proj_ffth['project']['rules'][0]['replacementData'] = patched_assembly

    # Re-encrypt envelopes
    reencrypted_ffm = reencrypt_envelope(env_ffm, proj_ffm)
    reencrypted_ffth = reencrypt_envelope(env_ffth, proj_ffth)

    # Ghi đè vào D:\update_file\aklo\leak\
    leak_dir = r"D:\update_file\aklo\leak"
    if os.path.exists(leak_dir):
        with open(os.path.join(leak_dir, "OG MENU FFM.3105"), "wb") as f:
            f.write(reencrypted_ffm)
        with open(os.path.join(leak_dir, "OG MENU FFTH.3105"), "wb") as f:
            f.write(reencrypted_ffth)
        print("✅ Đã ghi đè file tại D:\\update_file\\aklo\\leak\\")

    # Ghi đè vào D:\update_file\aklo\
    aklo_dir = r"D:\update_file\aklo"
    if os.path.exists(aklo_dir):
        with open(os.path.join(aklo_dir, "DELTAX FFM .3105"), "wb") as f:
            f.write(reencrypted_ffm)
        with open(os.path.join(aklo_dir, "DELTAX FFTH .3105"), "wb") as f:
            f.write(reencrypted_ffth)
        with open(os.path.join(aklo_dir, "DeltaX Enternal.3105"), "wb") as f:
            f.write(reencrypted_ffm)
        print("✅ Đã ghi đè file tại D:\\update_file\\aklo\\")

    # Trích xuất raw Assembly-CSharp-patch.bytes & localConfig.json vào Documents
    raw_dirs = [
        r"D:\update_file\aklo\DeltaX Enternal\Documents",
        r"ThreeOneOSFive\BundledPatches\DeltaX Enternal\Documents",
        r"ThreeOneOSFive\BundledPatches\DeltaX Enternal",
        r"ThreeOneOSFive\AppCore\DeltaX",
    ]
    for d in raw_dirs:
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

    print("🎉 HOÀN TẤT PATCHING VÀ SAO CHÉP TẤT CẢ TÀI NGUYÊN DELTAX & CHEATVN EXTERNAL!")

if __name__ == "__main__":
    main()
