import os
import shutil
import plistlib
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

src_dir = r"D:\dac"
candidates = [
    os.path.join(src_dir, "Esp Ffthg (4).3105"),
    os.path.join(src_dir, "Esp Ffthg.3105"),
]

src_3105 = None
for c in candidates:
    if os.path.exists(c):
        src_3105 = c
        break

if not src_3105:
    raise FileNotFoundError(f"Source 3105 not found in {src_dir}")

password = b"Canhcupin"
print(f"Reading and decrypting {src_3105} ({os.path.getsize(src_3105)} bytes) with password '{password.decode()}'...")

raw_3105 = open(src_3105, "rb").read()
assert len(raw_3105) == 69286 or len(raw_3105) > 30000, f"Unexpected 3105 size: {len(raw_3105)}"

env = plistlib.loads(raw_3105[10:])
kdf = PBKDF2HMAC(hashes.SHA256(), 32, env['kdfSalt'], env['kdfIterations'])
wkey = kdf.derive(password)
ver = env.get('keyAADVersion') or env.get('schemaVersion')
pkg_id = env['packageID']
aad = f"3105PATCH/v{ver}/key/{pkg_id}".encode("utf-8")
wk = env['wrappedContentKey']
ckey = AESGCM(wkey).decrypt(wk[:12], wk[12:], aad)

ep = env['encryptedPayload']
p_aad = f"3105PATCH/v{ver}/payload/{pkg_id}".encode("utf-8")
payload = AESGCM(ckey).decrypt(ep[:12], ep[12:], p_aad)
project_plist = plistlib.loads(payload)
proj = project_plist.get("project", {})
print(f"Project name: {proj.get('name')}, rules count: {len(proj.get('rules', []))}")

rules = proj.get("rules", [])
extracted = {}
for r in rules:
    rel_path = r.get("relativePath")
    data = r.get("replacementData")
    extracted[rel_path] = data
    print(f"  Extracted rule: {rel_path} ({len(data)} bytes)")

assert "Documents/Assembly-CSharp-patch.bytes" in extracted
assert "Documents/localConfig.json" in extracted

assembly_bytes = extracted["Documents/Assembly-CSharp-patch.bytes"]
config_bytes = extracted["Documents/localConfig.json"]

print(f"\nAssembly-CSharp-patch.bytes: {len(assembly_bytes)} bytes")
print(f"localConfig.json: {len(config_bytes)} bytes")
assert len(assembly_bytes) == 68138, f"Expected 68138 bytes, got {len(assembly_bytes)}"
assert len(config_bytes) == 40, f"Expected 40 bytes, got {len(config_bytes)}"

app_core = r"ThreeOneOSFive\AppCore"
app_core_assets = r"ThreeOneOSFive\AppCore\Assets"
bundled_root = r"ThreeOneOSFive\BundledPatches"
bundled_patch = r"ThreeOneOSFive\BundledPatches\Esp Ffthg"
bundled_docs = r"ThreeOneOSFive\BundledPatches\Esp Ffthg\Documents"

for d in [app_core, app_core_assets, bundled_patch, bundled_docs]:
    os.makedirs(d, exist_ok=True)

# 1. Purge old stale files completely
stale_files = [
    r"ThreeOneOSFive\AppCore\.core_runtime.dat",
    r"ThreeOneOSFive\AppCore\core_runtime.dat",
    r"ThreeOneOSFive\AppCore\core_manifest.bin",
    r"ThreeOneOSFive\AppCore\Assets\core_manifest.bin",
    r"ThreeOneOSFive\AppCore\Aurora Menu v1.3105",
    r"ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105"
]
for junk in stale_files:
    if os.path.isdir(junk):
        shutil.rmtree(junk)
        print(f"Deleted old folder: {junk}")
    elif os.path.exists(junk):
        os.remove(junk)
        print(f"Deleted old file: {junk}")

# 2. Write Assembly-CSharp-patch.bytes (68,138 bytes)
for target_file in [
    os.path.join(app_core, "Assembly-CSharp-patch.bytes"),
    os.path.join(app_core_assets, "Assembly-CSharp-patch.bytes"),
    os.path.join(bundled_patch, "Assembly-CSharp-patch.bytes"),
    os.path.join(bundled_docs, "Assembly-CSharp-patch.bytes")
]:
    with open(target_file, "wb") as f:
        f.write(assembly_bytes)
    print(f"Written {target_file} ({len(assembly_bytes)} bytes)")

# 3. Write localConfig.json (40 bytes)
for target_file in [
    os.path.join(app_core, "localConfig.json"),
    os.path.join(app_core_assets, "localConfig.json"),
    os.path.join(bundled_patch, "localConfig.json"),
    os.path.join(bundled_docs, "localConfig.json")
]:
    with open(target_file, "wb") as f:
        f.write(config_bytes)
    print(f"Written {target_file} ({len(config_bytes)} bytes)")

# 4. Copy raw .3105 package under both names to avoid mismatch
for pkg_name in ["Esp Ffthg.3105", "Esp Ffthg (4).3105"]:
    for target_dir in [app_core, app_core_assets, bundled_root]:
        target_path = os.path.join(target_dir, pkg_name)
        with open(target_path, "wb") as f:
            f.write(raw_3105)
        print(f"Copied package {target_path} ({len(raw_3105)} bytes)")

print("\nDeployment complete! All targets updated to new 68138-byte patch.")
