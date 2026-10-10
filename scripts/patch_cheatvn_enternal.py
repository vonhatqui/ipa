import struct
import os
import io

def patch_assembly_csharp(data: bytes) -> bytes:
    b = bytearray(data)

    def write_rgba(off, r, g, b_val, a):
        for i, val in enumerate([r, g, b_val, a]):
            p = off + i * 8
            code = struct.unpack('<I', b[p:p+4])[0]
            assert code == 3, f"Expected opcode 3 at {hex(p)}, got {code}"
            b[p+4:p+8] = struct.pack('<f', val)

    # 1. ESP BOX & Nametag visible (was lime green 0.20, 0.95, 0.40, 1.00) -> BRIGHT RED
    write_rgba(0x832f, 1.00, 0.20, 0.20, 1.00)

    # 2. ESP Line / Tracer (was green 0.18, 0.92, 0.42, 1.00) -> BRIGHT RED
    write_rgba(0x7167, 1.00, 0.20, 0.20, 1.00)

    # 3. ESP Health / Text (was green 0.18, 0.92, 0.35, 1.00) -> BRIGHT RED
    write_rgba(0x8547, 1.00, 0.20, 0.20, 1.00)

    # 4. MENU ACCENT & HEADERS: Change from Purple (0.72, 0.12, 1.00) to Sleek Red
    write_rgba(0x7a27, 1.00, 0.18, 0.18, 1.00)
    write_rgba(0x8abf, 1.00, 0.18, 0.18, 1.00)
    write_rgba(0x98cf, 1.00, 0.18, 0.18, 0.90)
    write_rgba(0x9adf, 1.00, 0.18, 0.18, 1.00)
    write_rgba(0xe15f, 1.00, 0.18, 0.18, 0.28)
    write_rgba(0xe26f, 1.00, 0.18, 0.18, 1.00)

    # 5. Rename "AURORA IOS" -> "CheatVN Enternal" in string table
    old_target = b'\x0aAURORA IOS'
    pos = b.find(old_target)
    assert pos != -1, "AURORA IOS string not found!"

    # 16 characters for "CheatVN Enternal" -> length byte 0x10
    new_str = b'\x10CheatVN Enternal'
    result = bytes(b[:pos]) + new_str + bytes(b[pos + len(old_target):])
    return result

def main():
    src_file = r"ThreeOneOSFive/BundledPatches/CheatVN Enternal/Assembly-CSharp-patch.bytes"
    with open(src_file, "rb") as f:
        orig = f.read()
    print(f"Original size: {len(orig)} bytes")

    patched = patch_assembly_csharp(orig)
    print(f"Patched size: {len(patched)} bytes")

    targets = [
        r"ThreeOneOSFive/BundledPatches/CheatVN Enternal/Assembly-CSharp-patch.bytes",
        r"ThreeOneOSFive/BundledPatches/CheatVN External/Assembly-CSharp-patch.bytes",
        r"ThreeOneOSFive/BundledPatches/CheatVN_External_Files/Documents/Assembly-CSharp-patch.bytes",
        r"ThreeOneOSFive/AppCore/Assembly-CSharp-patch.bytes",
    ]

    for t in targets:
        os.makedirs(os.path.dirname(t), exist_ok=True)
        with open(t, "wb") as f:
            f.write(patched)
        print(f"Wrote patched binary to: {t}")

    # Also ensure localConfig.json is written
    config_content = b'{"testCodePatch":true}\n'
    config_targets = [
        r"ThreeOneOSFive/BundledPatches/CheatVN Enternal/localConfig.json",
        r"ThreeOneOSFive/BundledPatches/CheatVN External/localConfig.json",
        r"ThreeOneOSFive/BundledPatches/CheatVN_External_Files/Documents/localConfig.json",
        r"ThreeOneOSFive/AppCore/localConfig.json",
    ]
    for ct in config_targets:
        os.makedirs(os.path.dirname(ct), exist_ok=True)
        with open(ct, "wb") as f:
            f.write(config_content)
        print(f"Wrote localConfig.json to: {ct}")

    # Remove all extra patch files to ensure STRICTLY only 2 files
    docs_dir = r"ThreeOneOSFive/BundledPatches/CheatVN_External_Files/Documents"
    for extra in [".ffxc_live", ".ffxc_neutral_37ca851ab5df497db608f1b2f45165f9", ".ffxc_runtime"]:
        ep = os.path.join(docs_dir, extra)
        if os.path.exists(ep):
            os.remove(ep)
            print(f"Removed extra patch file: {ep}")

if __name__ == '__main__':
    main()
