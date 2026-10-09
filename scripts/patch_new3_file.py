import plistlib, os, struct, io, sys, uuid, hashlib, datetime
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
sys.stdout.reconfigure(encoding='utf-8')

# 1. Load clean modified assembly from scratch/assembly_20931f2_binary.bytes
# In this binary, bytecode is 100% intact and clean, and strings are already set to:
# [33]: 'CheatVN External'
# [48]: 'nhismgaylolgbt'
# [51]: 'CheatVN External'
# [121]: 'CheatVN External'
assembly_src = r'scratch/assembly_20931f2_binary.bytes'
if not os.path.exists(assembly_src):
    raise FileNotFoundError(f"Missing {assembly_src}")

with open(assembly_src, 'rb') as f:
    modified_assembly = f.read()

print(f"Loaded clean modified assembly: {len(modified_assembly)} bytes")

# Verify strings using parser
sys.path.append('.')
import scratch.parse_new3_ifix as p

reader = p.BinaryReader(modified_assembly)
reader.read_uint64(); reader.read_string()
for _ in range(reader.read_int32()): reader.read_string()
m_cnt = reader.read_int32()
for _ in range(m_cnt):
    cs = reader.read_int32(); reader.read_bytes(cs * 8)
    eh = reader.read_int32(); reader.read_bytes(eh * 24)
ext_m_cnt = reader.read_int32()
for _ in range(ext_m_cnt):
    is_gen = reader.read_boolean()
    if is_gen:
        reader.read_int32(); reader.read_string()
        reader.read_bytes(reader.read_int32() * 4)
        for _ in range(reader.read_int32()):
            if reader.read_boolean(): reader.read_string()
            else: reader.read_int32()
    else:
        reader.read_int32(); reader.read_string()
        reader.read_bytes(reader.read_int32() * 4)

str_cnt = reader.read_int32()
strings = [reader.read_string() for _ in range(str_cnt)]
assert strings[33] == 'CheatVN External', f"Expected CheatVN External at 33, got {strings[33]}"
assert strings[48] == 'nhismgaylolgbt', f"Expected nhismgaylolgbt at 48, got {strings[48]}"
assert strings[51] == 'CheatVN External', f"Expected CheatVN External at 51, got {strings[51]}"
assert strings[121] == 'CheatVN External', f"Expected CheatVN External at 121, got {strings[121]}"
print("✅ Verified intern strings: [33] 'CheatVN External', [48] 'nhismgaylolgbt', [51] 'CheatVN External', [121] 'CheatVN External'")

raw_config = b'{"testCodePatch":true,"resetGuest":true}'

# 2. Build 100% PatchPackageCodec compliant .3105 envelope
# Use stable UUIDs
pkg_uuid_str = '2ACC74EE-70EA-4360-A614-A005DBF6E93E'
rule0_uuid_str = '293D1C2E-73E0-414C-BFE3-89D2AEEA8769'
rule1_uuid_str = '3DD0A3C6-D782-494B-BBC8-D298F4D92D0B'

rule0_digest = hashlib.sha256(modified_assembly).digest()
rule1_digest = hashlib.sha256(raw_config).digest()

now = datetime.datetime.now()

proj = {
    'bundleIdentifiers': [],
    'createdAt': now,
    'directories': [],
    'id': pkg_uuid_str,
    'name': 'CheatVN External',
    'updatedAt': now,
    'rules': [
        {
            'bundleID': 'com.dts.freefireth',
            'id': rule0_uuid_str,
            'relativePath': 'Documents/Assembly-CSharp-patch.bytes',
            'replacementFilename': 'Assembly-CSharp-patch.bytes',
            'replacementData': modified_assembly,
        },
        {
            'bundleID': 'com.dts.freefireth',
            'id': rule1_uuid_str,
            'relativePath': 'Documents/localConfig.json',
            'replacementFilename': 'localConfig.json',
            'replacementData': raw_config,
        }
    ]
}

payload_plist = {
    'project': proj,
    'replacementDigests': {
        rule0_uuid_str: rule0_digest,
        rule1_uuid_str: rule1_digest,
    }
}

payload_bytes = plistlib.dumps(payload_plist, fmt=plistlib.FMT_BINARY)
content_key = os.urandom(32)
key_fp = hashlib.sha256(content_key).digest()

p_aad = f'3105PATCH/v1/payload/{pkg_uuid_str}'.encode('utf-8')
aesgcm = AESGCM(content_key)
p_nonce = os.urandom(12)
p_ciphertext = aesgcm.encrypt(p_nonce, payload_bytes, p_aad)

env = {
    'encryptedPayload': p_nonce + p_ciphertext,
    'isPasswordProtected': False,
    'keyFingerprint': key_fp,
    'packageID': pkg_uuid_str,
    'publicContentKey': content_key,
    'schemaVersion': 1,
}

magic = b'3105PATCH\x00'
new_env_data = magic + plistlib.dumps(env, fmt=plistlib.FMT_BINARY)

print(f"Generated compliant .3105 package: {len(new_env_data)} bytes")

# Test decode package using python to verify 100% compliance
test_env = plistlib.loads(new_env_data[10:])
assert test_env['schemaVersion'] == 1
assert test_env['keyFingerprint'] == hashlib.sha256(test_env['publicContentKey']).digest()
test_aesgcm = AESGCM(test_env['publicContentKey'])
test_nonce = test_env['encryptedPayload'][:12]
test_ct = test_env['encryptedPayload'][12:]
test_dec = test_aesgcm.decrypt(test_nonce, test_ct, f"3105PATCH/v1/payload/{test_env['packageID']}".encode('utf-8'))
test_pl = plistlib.loads(test_dec)
assert test_pl['project']['name'] == 'CheatVN External'
assert len(test_pl['project']['rules']) == 2
assert test_pl['replacementDigests'][rule0_uuid_str] == hashlib.sha256(modified_assembly).digest()
assert test_pl['replacementDigests'][rule1_uuid_str] == hashlib.sha256(raw_config).digest()
print("✅ Verified .3105 package decode & SHA-256 digest checks successfully!")

# 3. Save files to all workspace locations
save_targets = [
    r'D:\update_file\new3\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\CheatVN_External_Files\Documents\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\OG MENU FFTH\Documents\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\CheatVN External\Documents\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105\Documents\Assembly-CSharp-patch.bytes',
    r'ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105\Assembly-CSharp-patch.bytes',
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
    r'ThreeOneOSFive\BundledPatches\CheatVN External\Documents\localConfig.json',
    r'ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105\Documents\localConfig.json',
    r'ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105\localConfig.json',
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
    r'ThreeOneOSFive\BundledPatches\DELTAX FFTH .3105',
    r'ThreeOneOSFive\AppCore\CheatVN External.3105',
    r'ThreeOneOSFive\AppCore\.core_runtime.dat',
]
for t in env_targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    with open(t, 'wb') as f:
        f.write(new_env_data)
    print(f"Saved envelope: {t} ({len(new_env_data)} bytes)")

print("\n🎉 HOÀN TẤT: Đã xây dựng và đồng bộ bản vá CheatVN External chuẩn 100% cho mọi vị trí!")
