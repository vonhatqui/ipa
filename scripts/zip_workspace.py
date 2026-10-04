import os
import zipfile

src_dir = r"d:\update_file\ipa-main"
out_zip = r"d:\update_file\ipa-main.zip"

exclude_dirs = {'.git', '.build', '.gemini', '__pycache__', 'scratch', 'DerivedData'}
exclude_extensions = {'.pyc'}

print(f"Creating zip from {src_dir} to {out_zip}...")
with zipfile.ZipFile(out_zip, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src_dir):
        # modify dirs in place to skip excluded
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for f in files:
            ext = os.path.splitext(f)[1]
            if ext in exclude_extensions:
                continue
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, src_dir)
            z.write(full_path, rel_path)

print(f"Successfully created {out_zip} ({os.path.getsize(out_zip)} bytes)")
