import sys
sys.path.append('.')
import struct
import plistlib
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

import scratch.inspect_aklo as ia

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

    # Helper to write RGBA floats (each float is 8 bytes in opcode 3: 4 bytes code=3, 4 bytes float)
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

print("Testing patch_deltax_bytecode...")
env1, p1 = ia.decrypt_envelope(r'D:\update_file\aklo\DELTAX FFM .3105')
raw = p1['project']['rules'][0]['replacementData']
patched = patch_deltax_bytecode(raw)
print("Success! Patched length:", len(patched))
