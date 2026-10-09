import plistlib, os, struct, io, sys
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def encode_7bit_int(value):
    out = bytearray()
    while value >= 0x80:
        out.append((value & 0x7F) | 0x80)
        value >>= 7
    out.append(value & 0x7F)
    return bytes(out)

def encode_string(s):
    b = s.encode('utf-8')
    return encode_7bit_int(len(b)) + b

# 1. Read original D:\update_file\new3\OG MENU FFTH.3105 or extracted backup
backup_assembly = r'scratch/new3_extracted_0_Assembly-CSharp-patch.bytes'
if os.path.exists(backup_assembly):
    with open(backup_assembly, 'rb') as f:
        raw_assembly = bytearray(f.read())
else:
    source_3105 = r'D:\update_file\new3\OG MENU FFTH.3105'
    with open(source_3105, 'rb') as f:
        raw_data = f.read()
    env = plistlib.loads(raw_data[10:])
    pkg_id = env['packageID']
    ver = env.get('keyAADVersion') or env.get('schemaVersion', 1)
    content_key = env['publicContentKey']
    p_aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')
    payload_raw = env['encryptedPayload']
    aesgcm = AESGCM(content_key)
    payload_decrypted = aesgcm.decrypt(payload_raw[:12], payload_raw[12:], p_aad)
    proj_plist = plistlib.loads(payload_decrypted)
    raw_assembly = bytearray(proj_plist['project']['rules'][0]['replacementData'])

# Read localConfig.json
config_path = r'scratch/new3_extracted_1_localConfig.json'
if os.path.exists(config_path):
    with open(config_path, 'rb') as f:
        raw_config = f.read()
else:
    raw_config = b'{"testCodePatch":true,"resetGuest":true}'

# 2. Patch bytecode instructions in raw_assembly BEFORE the string table
# Method 0 base: 0x1f27
# Method 5 base: 0x3ba7
m0_base = 0x1f27
m5_base = 0x3ba7

# In Method 5: instruction 684 loads window title string.
# Change operand from 33 ('nhismgaylolgbt') to 51 ('CheatVN External')
off_m5_684 = m5_base + 684 * 8
code_684, op_684 = struct.unpack('<ii', raw_assembly[off_m5_684:off_m5_684+8])
print(f"Method 5 insn 684 before: code={code_684}, op={op_684}")
assert code_684 == 176
struct.pack_into('<ii', raw_assembly, off_m5_684, 176, 51)
print(f"Method 5 insn 684 after: code=176, op=51 (CheatVN External)")

# In Method 0: make auth state ALWAYS succeed (true = 16)
# Instructions 105, 174, 345, 358, 371, 374 previously set false (19)
for insn_idx in [105, 174, 345, 358, 371, 374]:
    off = m0_base + insn_idx * 8
    code, op = struct.unpack('<ii', raw_assembly[off:off+8])
    if op == 19:
        struct.pack_into('<ii', raw_assembly, off, code, 16)
        print(f"Method 0 insn {insn_idx}: patched op from 19 (false) -> 16 (true)")

# 3. Modify intern string table
sys.path.append('.')
import scratch.parse_new3_ifix as p

reader = p.BinaryReader(bytes(raw_assembly))
reader.read_uint64(); reader.read_string()
for _ in range(reader.read_int32()): reader.read_string()
m_cnt = reader.read_int32()
for _ in range(m_cnt):
    cs = reader.read_int32()
    reader.read_bytes(cs * 8)
    eh = reader.read_int32()
    reader.read_bytes(eh * 24)
ext_m_cnt = reader.read_int32()
for _ in range(ext_m_cnt):
    is_gen = reader.read_boolean()
    if is_gen:
        reader.read_int32()
        reader.read_string()
        gen_arg_cnt = reader.read_int32()
        reader.read_bytes(gen_arg_cnt * 4)
        p_cnt = reader.read_int32()
        for _ in range(p_cnt):
            if reader.read_boolean(): reader.read_string()
            else: reader.read_int32()
    else:
        reader.read_int32()
        reader.read_string()
        p_cnt = reader.read_int32()
        reader.read_bytes(p_cnt * 4)

str_start_pos = reader.tell()
str_count = reader.read_int32()
original_strings = [reader.read_string() for _ in range(str_count)]
tail_pos = reader.tell()

head = raw_assembly[:str_start_pos]
tail = raw_assembly[tail_pos:]

# Replace strings:
# [33] 'nhismgaylolgbt' (Master key check in Method 0)
# [48] 'nhismgaylolgbt' (Default prefilled login key in Gate)
# [51] 'CheatVN External' (VIP SUITE header & Gate title)
# [121] 'CheatVN External' (Watermark brand label)
new_strings = list(original_strings)
new_strings[33] = 'nhismgaylolgbt'
new_strings[48] = 'nhismgaylolgbt'
new_strings[51] = 'CheatVN External'
new_strings[121] = 'CheatVN External'

new_str_buf = bytearray()
new_str_buf += struct.pack('<i', len(new_strings))
for s in new_strings:
    new_str_buf += encode_string(s)

modified_assembly = bytes(head) + bytes(new_str_buf) + bytes(tail)
print(f"Original Assembly size: {len(raw_assembly)}, Modified Assembly size: {len(modified_assembly)}")

# 4. Verify modified assembly with parser
test_reader = p.BinaryReader(modified_assembly)
test_reader.read_uint64(); test_reader.read_string()
for _ in range(test_reader.read_int32()): test_reader.read_string()
test_m_cnt = test_reader.read_int32()
for _ in range(test_m_cnt):
    cs = test_reader.read_int32(); test_reader.read_bytes(cs * 8)
    eh = test_reader.read_int32(); test_reader.read_bytes(eh * 24)
test_ext_m_cnt = test_reader.read_int32()
for _ in range(test_ext_m_cnt):
    is_gen = test_reader.read_boolean()
    if is_gen:
        test_reader.read_int32(); test_reader.read_string()
        test_reader.read_bytes(test_reader.read_int32() * 4)
        for _ in range(test_reader.read_int32()):
            if test_reader.read_boolean(): test_reader.read_string()
            else: test_reader.read_int32()
    else:
        test_reader.read_int32(); test_reader.read_string()
        test_reader.read_bytes(test_reader.read_int32() * 4)

read_str_cnt = test_reader.read_int32()
read_strings = [test_reader.read_string() for _ in range(read_str_cnt)]
assert read_strings[33] == 'nhismgaylolgbt'
assert read_strings[48] == 'nhismgaylolgbt'
assert read_strings[51] == 'CheatVN External'
assert read_strings[121] == 'CheatVN External'
print("Verified all modified strings successfully!")

# 5. Build .3105 envelope
proj = {
    'bundleIdentifiers': ['com.dts.freefireth', 'com.dts.freefiremax'],
    'createdAt': 1760000000.0,
    'description': 'CheatVN External iOS Runtime Patch',
    'id': 'cheatvn-external-2026',
    'name': 'CheatVN External',
    'rules': [
        {
            'action': 'replace',
            'bundleID': 'com.dts.freefireth',
            'relativePath': 'Documents/Assembly-CSharp-patch.bytes',
            'replacementData': modified_assembly,
        },
        {
            'action': 'replace',
            'bundleID': 'com.dts.freefireth',
            'relativePath': 'Documents/localConfig.json',
            'replacementData': raw_config,
        },
        {
            'action': 'replace',
            'bundleID': 'com.dts.freefiremax',
            'relativePath': 'Documents/Assembly-CSharp-patch.bytes',
            'replacementData': modified_assembly,
        },
        {
            'action': 'replace',
            'bundleID': 'com.dts.freefiremax',
            'relativePath': 'Documents/localConfig.json',
            'replacementData': raw_config,
        },
    ],
    'version': '1.0'
}

proj_plist = {'project': proj}
new_payload_bytes = plistlib.dumps(proj_plist, fmt=plistlib.FMT_BINARY)

content_key = os.urandom(32)
pkg_id = 'cheatvn-external-package'
p_aad = f'3105PATCH/v1/payload/{pkg_id}'.encode('utf-8')
aesgcm = AESGCM(content_key)
new_nonce = os.urandom(12)
new_ciphertext = aesgcm.encrypt(new_nonce, new_payload_bytes, p_aad)

env = {
    'encryptedPayload': new_nonce + new_ciphertext,
    'isPasswordProtected': False,
    'keyAADVersion': 1,
    'packageID': pkg_id,
    'publicContentKey': content_key,
    'schemaVersion': 1,
}

magic = b'3105PATCH\x00'
new_env_data = magic + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)

# 6. Save files to all workspace locations
save_targets = [
    r'D:\update_file\new3\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\CheatVN_External_Files\Documents\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\OG MENU FFTH\Documents\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\AppCore\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\AppCore\Assets\Assembly-CSharp-patch.bytes',
]
for t in save_targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    with open(t, 'wb') as f:
        f.write(modified_assembly)
    print(f"Saved: {t} ({len(modified_assembly)} bytes)")

config_targets = [
    r'D:\update_file\new3\localConfig.json',
    r'ThreeOneOSFive\BundledPatches\CheatVN_External_Files\Documents\localConfig.json',
    r'ThreeOneOSFive\BundledPatches\OG MENU FFTH\Documents\localConfig.json',
    r'ThreeOneOSFive\AppCore\localConfig.json',
    r'ThreeOneOSFive\AppCore\Assets\localConfig.json',
]
for t in config_targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    with open(t, 'wb') as f:
        f.write(raw_config)
    print(f"Saved: {t} ({len(raw_config)} bytes)")

env_targets = [
    r'D:\update_file\new3\CheatVN External.3105',
    r'D:\update_file\new3\OG MENU FFTH.3105',
    r'ThreeOneOSFive\BundledPatches\CheatVN External.3105',
    r'ThreeOneOSFive\BundledPatches\OG MENU FFTH.3105',
    r'ThreeOneOSFive\AppCore\CheatVN External.3105',
    r'ThreeOneOSFive\AppCore\.core_runtime.dat',
]
for t in env_targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    with open(t, 'wb') as f:
        f.write(new_env_data)
    print(f"Saved envelope: {t} ({len(new_env_data)} bytes)")

print("\n[SUCCESS] Da tao va phan phoi ban va CheatVN External 100% chuan xac voi key nhismgaylolgbt!")
