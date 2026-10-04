import urllib.request
import re
import json

url = "https://www.tiktok.com/@hong.c.thng873/video/7691366681712528653"
req = urllib.request.Request(url, headers={
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
})
try:
    with urllib.request.urlopen(req) as resp:
        html = resp.read().decode('utf-8', errors='ignore')
    
    title = re.search(r'<title>(.*?)</title>', html)
    desc = re.search(r'<meta name="description" content="(.*?)"', html)
    og_desc = re.search(r'<meta property="og:description" content="(.*?)"', html)
    print("Title:", title.group(1) if title else "N/A")
    print("Desc:", desc.group(1) if desc else "N/A")
    print("OG Desc:", og_desc.group(1) if og_desc else "N/A")

    # Look for video script data
    s_idx = html.find('__UNIVERSAL_DATA_FOR_REHYDRATION__')
    if s_idx != -1:
        e_idx = html.find('</script>', s_idx)
        json_str = html[s_idx:e_idx].split('=', 1)[1].strip()
        data = json.loads(json_str)
        print("JSON loaded successfully")
        # try find desc
        default_scope = data.get('__DEFAULT_SCOPE__', {})
        video_detail = default_scope.get('webapp.video-detail', {})
        item_info = video_detail.get('itemInfo', {}).get('itemStruct', {})
        print("Video text:", item_info.get('desc'))
        print("Author:", item_info.get('author', {}).get('uniqueId'))
        # print video download/play url
        video = item_info.get('video', {})
        print("PlayAddr:", video.get('playAddr'))
except Exception as e:
    print("Error:", e)
