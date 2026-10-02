import base64
import os
import shutil

aura_path = r"D:\aura\Aurora Menu v1.3105"
with open(aura_path, "rb") as f:
    aura_bytes = f.read()

print(f"Loaded D:\\aura\\Aurora Menu v1.3105: {len(aura_bytes)} bytes")
b64 = base64.b64encode(aura_bytes).decode("ascii")

# 1. Copy to all required locations
targets = [
    r"ThreeOneOSFive\AppCore\.core_runtime.dat",
    r"ThreeOneOSFive\AppCore\core_runtime.dat",
    r"ThreeOneOSFive\AppCore\core_manifest.bin",
    r"ThreeOneOSFive\AppCore\Assets\core_manifest.bin",
    r"ThreeOneOSFive\BundledPatches\Aurora Menu v1.3105",
    r"ThreeOneOSFive\BundledPatches\Aurora Menu v1-0.3105",
    r"ThreeOneOSFive\BundledPatches\@Nhism Menu v1-0.3105",
    r"ThreeOneOSFive\BundledPatches\CheatVN Menu v1-0.3105",
    r"D:\update_file\well-known\patches\.core_runtime.dat",
    r"D:\update_file\well-known\patches\core_manifest.bin"
]
for t in targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    with open(t, "wb") as f:
        f.write(aura_bytes)
    print(f"  -> Wrote {t}: {os.path.getsize(t)} bytes")

# 2. Update BundledPatchInjector.swift
injector_path = r"ThreeOneOSFive\helpers\BundledPatchInjector.swift"
with open(injector_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "static let embeddedPayloadBase64" in line:
        lines[i] = f'    static let embeddedPayloadBase64: String = "{b64}"\n'
        break

with open(injector_path, "w", encoding="utf-8") as f:
    f.writelines(lines)
print("  -> Updated BundledPatchInjector.swift with new 46842-byte payload")

# 3. Ensure assets/brands has correct logos
src_velix = r"C:\Users\Nhat Qui\.gemini\antigravity-ide\brain\5a618448-b9d4-4547-95b4-b67dc4d6aa1d\.user_uploaded\media_1790968897594.jpg"
src_venom = r"C:\Users\Nhat Qui\.gemini\antigravity-ide\brain\5a618448-b9d4-4547-95b4-b67dc4d6aa1d\.user_uploaded\media_1790969601571.jpg"

os.makedirs("assets/brands", exist_ok=True)
shutil.copyfile(src_velix, r"assets\brands\velix_logo.jpg")
shutil.copyfile(src_venom, r"assets\brands\venom_logo.jpg")
shutil.copyfile(src_venom, r"assets\brands\venom_logo.png")
print(f"  -> VeLix logo set to media_1790968897594.jpg: {os.path.getsize(r'assets\brands\velix_logo.jpg')} bytes (Angel wings with VELIX VN)")
print(f"  -> Venom logo set to media_1790969601571.jpg: {os.path.getsize(r'assets\brands\venom_logo.jpg')} bytes (Crown & dragon with VENOM VN)")
