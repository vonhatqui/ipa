import os
import shutil
import plistlib
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

src_3105 = r"D:\dac\Esp Ffthg.3105"
password = b"Canhcupin"

if not os.path.exists(src_3105):
    raise FileNotFoundError(f"Source 3105 not found: {src_3105}")

print(f"Reading and decrypting {src_3105} with password '{password.decode()}'...")
raw_3105 = open(src_3105, "rb").read()
assert len(raw_3105) == 40091, f"Expected 40091 bytes, got {len(raw_3105)}"

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

assert len(assembly_bytes) == 38996
assert len(config_bytes) == 40

app_core = r"ThreeOneOSFive\AppCore"
app_core_assets = r"ThreeOneOSFive\AppCore\Assets"
bundled_root = r"ThreeOneOSFive\BundledPatches"
bundled_patch = r"ThreeOneOSFive\BundledPatches\Esp Ffthg"
bundled_docs = r"ThreeOneOSFive\BundledPatches\Esp Ffthg\Documents"

# 1. Purge completely all old files and companion files (.ffxc_*, Aurora Menu, core_*, etc.)
stale_patterns = [".ffxc_live", ".ffxc_neutral_785f10139667472283586f6094f07e1d", ".ffxc_runtime"]
for root_dir in [app_core, app_core_assets, bundled_root]:
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for fname in filenames:
            if fname.startswith(".ffxc_") or fname in stale_patterns:
                fpath = os.path.join(dirpath, fname)
                os.remove(fpath)
                print(f"Deleted stale file: {fpath}")

old_aurora_folder = r"ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105"
if os.path.exists(old_aurora_folder):
    shutil.rmtree(old_aurora_folder)
    print(f"Removed old folder: {old_aurora_folder}")

old_junk = [
    r"ThreeOneOSFive\AppCore\.core_runtime.dat",
    r"ThreeOneOSFive\AppCore\core_runtime.dat",
    r"ThreeOneOSFive\AppCore\core_manifest.bin",
    r"ThreeOneOSFive\AppCore\Assets\core_manifest.bin",
    r"ThreeOneOSFive\AppCore\Aurora Menu v1.3105",
]
for junk in old_junk:
    if os.path.exists(junk):
        os.remove(junk)
        print(f"Deleted old junk file: {junk}")

# 2. Deploy extracted files
for d in [app_core, app_core_assets, bundled_patch, bundled_docs]:
    os.makedirs(d, exist_ok=True)

# Write Assembly-CSharp-patch.bytes
for target_file in [
    os.path.join(app_core, "Assembly-CSharp-patch.bytes"),
    os.path.join(app_core_assets, "Assembly-CSharp-patch.bytes"),
    os.path.join(bundled_patch, "Assembly-CSharp-patch.bytes"),
    os.path.join(bundled_docs, "Assembly-CSharp-patch.bytes")
]:
    with open(target_file, "wb") as f:
        f.write(assembly_bytes)
    print(f"Written {target_file} ({len(assembly_bytes)} bytes)")

# Write localConfig.json
for target_file in [
    os.path.join(app_core, "localConfig.json"),
    os.path.join(app_core_assets, "localConfig.json"),
    os.path.join(bundled_patch, "localConfig.json"),
    os.path.join(bundled_docs, "localConfig.json")
]:
    with open(target_file, "wb") as f:
        f.write(config_bytes)
    print(f"Written {target_file} ({len(config_bytes)} bytes)")

# Copy the original raw .3105 package
for target_3105 in [
    os.path.join(app_core, "Esp Ffthg.3105"),
    os.path.join(bundled_root, "Esp Ffthg.3105")
]:
    with open(target_3105, "wb") as f:
        f.write(raw_3105)
    print(f"Copied package {target_3105} ({len(raw_3105)} bytes)")

print("\nAll files from D:\\dac\\Esp Ffthg.3105 successfully deployed! Old patch files purged completely.")
