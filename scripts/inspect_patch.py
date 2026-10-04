import plistlib
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

with open(r'D:\aaaaaaaaacc\Aurora Menu v1.3105', 'rb') as f:
    data = f.read()

bplist_data = data[10:]
env = plistlib.loads(bplist_data)

password = b'1'
salt = env['kdfSalt']
iters = env['kdfIterations']
wrapped_key = env['wrappedContentKey']
pkg_id = env['packageID']
ver = env.get('keyAADVersion') or env.get('schemaVersion')

# Derive key using PBKDF2
kdf = PBKDF2HMAC(
    algorithm=hashes.SHA256(),
    length=32,
    salt=salt,
    iterations=iters,
)
wrapping_key = kdf.derive(password)

aad = f"3105PATCH/v{ver}/key/{pkg_id}".encode('utf-8')
print('AAD:', aad)

nonce = wrapped_key[:12]
tag = wrapped_key[-16:]
ciphertext = wrapped_key[12:-16]

aesgcm = AESGCM(wrapping_key)
content_key = aesgcm.decrypt(nonce, ciphertext + tag, aad)
print('Content key decrypted successfully! Length:', len(content_key))

payload_raw = env['encryptedPayload']
p_nonce = payload_raw[:12]
p_tag = payload_raw[-16:]
p_ciphertext = payload_raw[12:-16]

p_aad = f"3105PATCH/v{ver}/payload/{pkg_id}".encode('utf-8')
p_aesgcm = AESGCM(content_key)
payload_decrypted = p_aesgcm.decrypt(p_nonce, p_ciphertext + p_tag, p_aad)
print('Payload decrypted successfully! Length:', len(payload_decrypted))

project_plist = plistlib.loads(payload_decrypted)
print('Project keys:', list(project_plist.keys()))
proj = project_plist.get('project', {})
print('Inner Project keys:', list(proj.keys()))
for k, v in proj.items():
    if k == 'rules':
        print(f'rules: count={len(v)}')
        for r in v:
            data = r.get('replacementData', b'')
            print('  rule relativePath:', r.get('relativePath'), 'bundleID:', r.get('bundleID'), 'data_len:', len(data))
            if len(data) < 200:
                print('    Content:', data.decode('utf-8', errors='replace'))
    elif isinstance(v, (bytes, bytearray)):
        print(f'{k}: bytes len={len(v)}')
    else:
        print(f'{k}: {v}')