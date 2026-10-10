import sys
import plistlib
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def create_3105_package():
    ass_path = r"ThreeOneOSFive/AppCore/Assembly-CSharp-patch.bytes"
    cfg_path = r"ThreeOneOSFive/AppCore/localConfig.json"

    with open(ass_path, "rb") as f:
        ass_data = f.read()
    with open(cfg_path, "rb") as f:
        cfg_data = f.read()

    print(f"Packaging 2 files: Assembly-CSharp-patch.bytes ({len(ass_data)} B), localConfig.json ({len(cfg_data)} B)")

    bundle_ids = ['com.dts.freefireth', 'com.dts.freefiremax', 'com.dts.freefire', 'com.dts.freefirevn']
    rules = [
        {
            'relativePath': 'Documents/Assembly-CSharp-patch.bytes',
            'replacementData': ass_data
        },
        {
            'relativePath': 'Documents/localConfig.json',
            'replacementData': cfg_data
        }
    ]

    project_dict = {
        'project': {
            'name': 'CheatVN Enternal',
            'bundleIdentifiers': bundle_ids,
            'rules': rules,
            'targetApp': None
        }
    }

    payload_bytes = plistlib.dumps(project_dict, fmt=plistlib.FMT_BINARY)

    # Password "OG", also testable with "1" or ""
    pkg_id = '7E957616-DC10-4CB7-9931-3C586F1FE6FB'
    salt = os.urandom(16)
    iters = 100000
    ver = 3

    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=iters,
    )
    wrapping_key = kdf.derive(b'OG')
    key_aad = f'3105PATCH/v{ver}/key/{pkg_id}'.encode('utf-8')

    content_key = os.urandom(32)
    key_nonce = os.urandom(12)
    aesgcm_wrap = AESGCM(wrapping_key)
    wrapped_content_key = key_nonce + aesgcm_wrap.encrypt(key_nonce, content_key, key_aad)

    p_nonce = os.urandom(12)
    aesgcm_payload = AESGCM(content_key)
    payload_aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')
    encrypted_payload = p_nonce + aesgcm_payload.encrypt(p_nonce, payload_bytes, payload_aad)

    env = {
        'packageID': pkg_id,
        'schemaVersion': ver,
        'keyAADVersion': ver,
        'isPasswordProtected': True,
        'kdfSalt': salt,
        'kdfIterations': iters,
        'wrappedContentKey': wrapped_content_key,
        'encryptedPayload': encrypted_payload,
    }

    pkg_data = b'3105PATCH\0' + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)

    targets = [
        r"ThreeOneOSFive/BundledPatches/CheatVN Enternal.3105",
        r"ThreeOneOSFive/BundledPatches/CheatVN External.3105",
        r"ThreeOneOSFive/AppCore/CheatVN Enternal.3105",
        r"ThreeOneOSFive/AppCore/CheatVN External.3105",
        r"ThreeOneOSFive/AppCore/.core_runtime.dat",
    ]

    for t in targets:
        os.makedirs(os.path.dirname(t), exist_ok=True)
        with open(t, "wb") as f:
            f.write(pkg_data)
        print(f"Saved: {t} ({len(pkg_data)} bytes)")

if __name__ == '__main__':
    create_3105_package()
