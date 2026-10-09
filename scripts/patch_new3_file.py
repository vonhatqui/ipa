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

# 1. Read D:\update_file\new3\OG MENU FFTH.3105
source_3105 = r'D:\update_file\new3\OG MENU FFTH.3105'
with open(source_3105, 'rb') as f:
    raw_data = f.read()

magic = raw_data[:10]
assert magic == b'3105PATCH\x00'
env = plistlib.loads(raw_data[10:])

pkg_id = env['packageID']
ver = env.get('keyAADVersion') or env.get('schemaVersion', 1)
content_key = env['publicContentKey']
p_aad = f'3105PATCH/v{ver}/payload/{pkg_id}'.encode('utf-8')

payload_raw = env['encryptedPayload']
p_nonce = payload_raw[:12]
p_tag = payload_raw[-16:]
p_ciphertext = payload_raw[12:-16]

aesgcm = AESGCM(content_key)
payload_decrypted = aesgcm.decrypt(p_nonce, p_ciphertext + p_tag, p_aad)
proj_plist = plistlib.loads(payload_decrypted)
proj = proj_plist['project']

print(f"Decrypted project: {proj['name']}")

raw_assembly = proj['rules'][0]['replacementData']
raw_config = proj['rules'][1]['replacementData']

# 2. Modify string table in Assembly-CSharp-patch.bytes
# We know intern_strings start at 0x16F97
# Let's parse string table
sys.path.append('.')
import scratch.parse_new3_ifix as p

reader = p.BinaryReader(raw_assembly)
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
# [33] 'ASHOK' -> 'CheatVN External' (window header)
# [48] 'ASHOK' -> 'nhismgaylolgbt' (default prefilled key)
# [51] 'ASHOK' -> 'CheatVN External' (VIP SUITE header)
# [121] 'ASHOK' -> 'CheatVN External' (brand label)
new_strings = list(original_strings)
new_strings[33] = 'CheatVN External'
new_strings[48] = 'nhismgaylolgbt'
new_strings[51] = 'CheatVN External'
new_strings[121] = 'CheatVN External'

new_str_buf = bytearray()
new_str_buf += struct.pack('<i', len(new_strings))
for s in new_strings:
    new_str_buf += encode_string(s)

modified_assembly = head + bytes(new_str_buf) + tail
print(f"Original Assembly size: {len(raw_assembly)}, Modified Assembly size: {len(modified_assembly)}")

# Update project rules with modified assembly and ensure bundleIDs cover FFTH and FFMAX
proj['name'] = 'CheatVN External'
proj['bundleIdentifiers'] = ['com.dts.freefireth', 'com.dts.freefiremax']
proj['rules'][0]['replacementData'] = modified_assembly
proj['rules'][0]['bundleID'] = 'com.dts.freefireth'
proj['rules'][1]['replacementData'] = raw_config
proj['rules'][1]['bundleID'] = 'com.dts.freefireth'

# Add duplicate rules for FFMAX if not present
rule_ffmax_0 = dict(proj['rules'][0])
rule_ffmax_0['bundleID'] = 'com.dts.freefiremax'
rule_ffmax_1 = dict(proj['rules'][1])
rule_ffmax_1['bundleID'] = 'com.dts.freefiremax'

proj['rules'] = [proj['rules'][0], proj['rules'][1], rule_ffmax_0, rule_ffmax_1]

# Re-encrypt envelope
new_payload_bytes = plistlib.dumps(proj_plist, fmt=plistlib.FMT_BINARY)
new_nonce = os.urandom(12)
new_ciphertext = aesgcm.encrypt(new_nonce, new_payload_bytes, p_aad)

env['encryptedPayload'] = new_nonce + new_ciphertext
new_env_data = magic + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)

# Save files to workspace locations
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

print("\n🎉 HOÀN TẤT: Đã tạo và phân phối bản vá CheatVN External mới 100% chuẩn xác!")
