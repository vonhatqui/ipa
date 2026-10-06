import urllib.request
import os

urls = {
    "cheatvn_external.png": "https://files.catbox.moe/rifgg5.png",
    "deltax_enternal.png": "https://files.catbox.moe/xslw3c.png"
}

headers = {'User-Agent': 'Mozilla/5.0'}

for filename, url in urls.items():
    print(f"Downloading {url} to {filename}...")
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp, open(filename, 'wb') as f:
            data = resp.read()
            f.write(data)
            print(f"Downloaded {filename}: {len(data)} bytes")
    except Exception as e:
        print(f"Error downloading {url}: {e}")
