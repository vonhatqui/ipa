import zipfile
import sys
sys.stdout.reconfigure(encoding='utf-8')

with zipfile.ZipFile(r"D:\update_file\well-known\base.ipa") as z:
    names = z.namelist()

print(f"Total entries: {len(names)}")

print("\n--- Matching entries ---")
for n in names:
    if any(k in n.lower() for k in ["patch", "assembly", "appcore", "localconfig", "ffxc", "aurora", "sophia"]):
        size = z.getinfo(n).file_size
        print(f"Match: {n} ({size} bytes)")
