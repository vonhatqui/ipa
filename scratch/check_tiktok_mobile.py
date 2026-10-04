import urllib.request

url = "https://www.tiktok.com/@hong.c.thng873/video/7691366681712528653"
req = urllib.request.Request(url, headers={
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
})
try:
    with urllib.request.urlopen(req) as resp:
        html = resp.read().decode('utf-8', errors='ignore')
    print("Len:", len(html))
    print(html[:1000])
except Exception as e:
    print(e)
