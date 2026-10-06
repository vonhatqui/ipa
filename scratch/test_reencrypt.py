import sys
sys.path.append('.')
import plistlib
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import scratch.inspect_aklo as ia

env, proj_plist = ia.decrypt_envelope(r'D:\update_file\aklo\DELTAX FFM .3105')
content_key = env['publicContentKey']
pkg_id = env['packageID']
ver = env.get('keyAADVersion') or env.get('schemaVersion', 1)
aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')

# Change project name
proj_plist['project']['name'] = 'DeltaX Enternal'

# Re-encrypt
new_payload_bytes = plistlib.dumps(proj_plist, fmt=plistlib.FMT_BINARY)
p_nonce = os.urandom(12)
aesgcm = AESGCM(content_key)
p_ciphertext = aesgcm.encrypt(p_nonce, new_payload_bytes, aad)

env['encryptedPayload'] = p_nonce + p_ciphertext
magic = b'3105PATCH\0'
new_env_data = magic + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)

# Test decrypting it back
with open(r'scratch/test_env.3105', 'wb') as f:
    f.write(new_env_data)

env_test, proj_test = ia.decrypt_envelope(r'scratch/test_env.3105')
print('Decrypted project name:', proj_test['project']['name'])
assert proj_test['project']['name'] == 'DeltaX Enternal'
print('Test passed successfully!')
