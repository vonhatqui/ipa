import plistlib
import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def decrypt_envelope(path):
    with open(path, 'rb') as f:
        data = f.read()
    magic = data[:10]
    bplist = data[10:]
    env = plistlib.loads(bplist)
    print('Package ID:', env.get('packageID'))
    print('isPasswordProtected:', env.get('isPasswordProtected'))
    
    pkg_id = env['packageID']
    ver = env.get('keyAADVersion') or env.get('schemaVersion', 1)

    if env.get('isPasswordProtected', True):
        password = b'1'
        salt = env['kdfSalt']
        iters = env['kdfIterations']
        wrapped_key = env['wrappedContentKey']

        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=iters,
        )
        wrapping_key = kdf.derive(password)
        aad = f'3105PATCH/v{ver}/key/{pkg_id}'.encode('utf-8')

        nonce = wrapped_key[:12]
        tag = wrapped_key[-16:]
        ciphertext = wrapped_key[12:-16]

        aesgcm = AESGCM(wrapping_key)
        content_key = aesgcm.decrypt(nonce, ciphertext + tag, aad)
    else:
        content_key = env['publicContentKey']

    payload_raw = env['encryptedPayload']
    p_nonce = payload_raw[:12]
    p_tag = payload_raw[-16:]
    p_ciphertext = payload_raw[12:-16]

    p_aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')
    p_aesgcm = AESGCM(content_key)
    payload_decrypted = p_aesgcm.decrypt(p_nonce, p_ciphertext + p_tag, p_aad)

    project_plist = plistlib.loads(payload_decrypted)
    project = project_plist.get('project', {})
    print('Project name:', project.get('name'))
    print('Target App:', project.get('targetApp'))
    print('Bundle IDs:', project.get('bundleIdentifiers'))
    print('Rules count:', len(project.get('rules', [])))
    for idx, r in enumerate(project.get('rules', [])):
        rpath = r.get('relativePath', '')
        rdata = r.get('replacementData', b'')
        print(f"  Rule {idx}: relativePath='{rpath}', size={len(rdata)} bytes")
    return env, project_plist

print('=== DELTAX FFM ===')
env_ffm, proj_ffm = decrypt_envelope(r'D:\update_file\aklo\DELTAX FFM .3105')
print('\n=== DELTAX FFTH ===')
env_ffth, proj_ffth = decrypt_envelope(r'D:\update_file\aklo\DELTAX FFTH .3105')
