import os
import shutil

src_dir = r"D:\SOPHIA ALL FILE LEAKED BY AURORA\aim head with line fast fire lv2"
app_core = r"ThreeOneOSFive\AppCore"
app_core_assets = r"ThreeOneOSFive\AppCore\Assets"

os.makedirs(app_core, exist_ok=True)
os.makedirs(app_core_assets, exist_ok=True)

# 1. Assembly-CSharp-patch.bytes with SOPHIA -> CHEATVN
with open(os.path.join(src_dir, "Assembly-CSharp-patch.bytes"), "rb") as f:
    data = f.read()

target = b'\x06Sophia\x01m\tSOPHIA\n[ \x02 ]'
replacement = b'\x07CheatVN\x01m\nCHEATVN\n[ \x02 ]'
assert target in data
patched_data = data.replace(target, replacement)
assert b"SOPHIA" not in patched_data and b"Sophia" not in patched_data

for target_file in [
    os.path.join(app_core, "Assembly-CSharp-patch.bytes"),
    os.path.join(app_core_assets, "Assembly-CSharp-patch.bytes")
]:
    with open(target_file, "wb") as f:
        f.write(patched_data)
    print(f"Written patched {target_file} ({len(patched_data)} bytes)")

# 2. Other 4 files: localConfig.json, .ffxc_live, .ffxc_neutral_785f10139667472283586f6094f07e1d, .ffxc_runtime
other_files = [
    "localConfig.json",
    ".ffxc_live",
    ".ffxc_neutral_785f10139667472283586f6094f07e1d",
    ".ffxc_runtime"
]

for name in other_files:
    src_file = os.path.join(src_dir, name)
    with open(src_file, "rb") as f:
        content = f.read()
    for dest_dir in [app_core, app_core_assets]:
        dest_file = os.path.join(dest_dir, name)
        with open(dest_file, "wb") as f:
            f.write(content)
        print(f"Copied {name} -> {dest_file} ({len(content)} bytes)")

print("All patch files deployed to AppCore successfully!")
