import zipfile
import os

zip_path = r"D:\CheatStore-All-IPAs.zip"
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as z:
    for f in [r"D:\update_file\CheatStore-VN.ipa", r"D:\update_file\VeLix_VN.ipa", r"D:\update_file\Venom_VN.ipa"]:
        z.write(f, os.path.basename(f))
        print("Added", os.path.basename(f), os.path.getsize(f))
print("Updated", zip_path, os.path.getsize(zip_path), "bytes")
