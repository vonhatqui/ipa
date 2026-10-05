import struct
import plistlib
import os
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def patch_assembly_csharp_data(raw_data: bytes) -> bytes:
    data = bytearray(raw_data)
    assert len(data) == 45441, f"Expected 45441 bytes, got {len(data)}"

    def write_rgba(off, r, g, b, a):
        for i, val in enumerate([r, g, b, a]):
            p = off + i * 8
            # check opcode is 3
            code = struct.unpack('<I', data[p:p+4])[0]
            assert code == 3, f"Expected opcode 3 at {hex(p)}, got {code}"
            data[p+4:p+8] = struct.pack('<f', val)

    # 1. Nametag badge background: change from green (0.05, 0.30, 0.08, 0.88) to dark red (0.50, 0.05, 0.05, 0.88)
    write_rgba(0x735d, 0.50, 0.05, 0.05, 0.88)

    # 2. Nametag text/border: change from green (0.20, 0.95, 0.40, 1.00) to bright red (1.00, 0.20, 0.20, 1.00)
    write_rgba(0x7495, 1.00, 0.20, 0.20, 1.00)

    # 3. Enemy Tracer Line: change from green (0.20, 0.95, 0.40, 1.00) to bright red (1.00, 0.20, 0.20, 1.00)
    write_rgba(0x6ce5, 1.00, 0.20, 0.20, 1.00)

    # 4. Other enemy green text/label at 0x8325: change to bright red (1.00, 0.20, 0.20, 1.00)
    write_rgba(0x8325, 1.00, 0.20, 0.20, 1.00)

    return bytes(data)

def main():
    target_files = [
        r"ThreeOneOSFive/AppCore/Assembly-CSharp-patch.bytes",
        r"ThreeOneOSFive/AppCore/Assets/Assembly-CSharp-patch.bytes",
        r"ThreeOneOSFive/BundledPatches/Aurora Menu v1.3105/Assembly-CSharp-patch.bytes",
        r"ThreeOneOSFive/BundledPatches/Aurora Menu v1.3105/Documents/Assembly-CSharp-patch.bytes",
    ]

    with open(target_files[0], "rb") as f:
        orig = f.read()

    patched = patch_assembly_csharp_data(orig)
    print("Patched patch binary length:", len(patched))

    for tf in target_files:
        if os.path.exists(tf):
            with open(tf, "wb") as f:
                f.write(patched)
            print("Wrote patched binary to:", tf)

    # Now update the encrypted envelope at D:\aaaaaaaaacc\Aurora Menu v1.3105
    envelope_path = r"D:\aaaaaaaaacc\Aurora Menu v1.3105"
    if os.path.exists(envelope_path):
        with open(envelope_path, "rb") as f:
            env_file_data = f.read()

        magic = env_file_data[:10]
        assert magic == b"3105PATCH\0", f"Unexpected magic: {magic}"
        bplist_data = env_file_data[10:]
        env = plistlib.loads(bplist_data)

        password = b'1'
        salt = env['kdfSalt']
        iters = env['kdfIterations']
        wrapped_key = env['wrappedContentKey']
        pkg_id = env['packageID']
        ver = env.get('keyAADVersion') or env.get('schemaVersion')

        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=iters,
        )
        wrapping_key = kdf.derive(password)
        aad = f"3105PATCH/v{ver}/key/{pkg_id}".encode('utf-8')

        nonce = wrapped_key[:12]
        tag = wrapped_key[-16:]
        ciphertext = wrapped_key[12:-16]

        aesgcm = AESGCM(wrapping_key)
        content_key = aesgcm.decrypt(nonce, ciphertext + tag, aad)

        payload_raw = env['encryptedPayload']
        p_nonce = payload_raw[:12]
        p_tag = payload_raw[-16:]
        p_ciphertext = payload_raw[12:-16]

        p_aad = f"3105PATCH/v{ver}/payload/{pkg_id}".encode('utf-8')
        p_aesgcm = AESGCM(content_key)
        payload_decrypted = p_aesgcm.decrypt(p_nonce, p_ciphertext + p_tag, p_aad)

        project_plist = plistlib.loads(payload_decrypted)
        rules = project_plist['project']['rules']
        # Update replacementData in all rules matching Assembly-CSharp-patch.bytes
        updated_count = 0
        for r in rules:
            if 'Assembly-CSharp-patch.bytes' in r.get('relativePath', '') or len(r.get('replacementData', b'')) == 45441:
                r['replacementData'] = patched
                updated_count += 1
        print(f"Updated {updated_count} rule(s) in payload plist.")

        new_payload_bytes = plistlib.dumps(project_plist, fmt=plistlib.FMT_BINARY)
        new_p_nonce = os.urandom(12)
        new_p_ciphertext_and_tag = p_aesgcm.encrypt(new_p_nonce, new_payload_bytes, p_aad)
        env['encryptedPayload'] = new_p_nonce + new_p_ciphertext_and_tag

        new_env_data = magic + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)
        with open(envelope_path, "wb") as f:
            f.write(new_env_data)
        print("Updated encrypted envelope at:", envelope_path, f"({len(new_env_data)} bytes)")

        # Also update BundledPatchInjector.swift embeddedPayloadBase64
        new_b64 = base64.b64encode(new_env_data).decode('ascii')
        injector_swift = r"ThreeOneOSFive/helpers/BundledPatchInjector.swift"
        with open(injector_swift, "r", encoding="utf-8") as f:
            code = f.read()

        import re
        pat = r'(static let embeddedPayloadBase64: String = ")[^"]+(")'
        new_code, num_subs = re.subn(pat, r'\g<1>' + new_b64 + r'\g<2>', code)
        assert num_subs == 1, f"Failed to substitute embeddedPayloadBase64 (subs={num_subs})"
        with open(injector_swift, "w", encoding="utf-8") as f:
            f.write(new_code)
        print("Updated embeddedPayloadBase64 in BundledPatchInjector.swift!")

if __name__ == "__main__":
    main()
