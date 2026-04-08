#!/usr/bin/env python3
import urllib.request
import urllib.parse
import json
import sys
import os

TOKEN = "123.d62c2883a638892ad50ccc15a67370cf.Y3j1zldsvZG97LDWjShtxrTFDUn21uDbsjK9Ii-.y17ptw"
BASE_URL = "https://pan.baidu.com/rest/2.0/xpan/multimedia"
DEST = "/Users/eieai/.openclaw/workspace-main"

files = [
    ("315-技术理论框架.docx", "990500655928516"),
    ("316-产业分析方法论.docx", "890793397194809"),
    ("317-产业预测方法论.docx", "137797950511783"),
]

for fname, fsid in files:
    print(f"\n=== Getting dlink for {fname} ===")
    params = f"method=filemetas&access_token={TOKEN}&fsids=%5B{fsid}%5D&dlink=1"
    url = f"{BASE_URL}?{params}"
    
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
    
    dlink = data["list"][0]["dlink"]
    print(f"DLink: {dlink[:80]}...")
    
    # 下载（含 Referer 头）
    dl_req = urllib.request.Request(dlink, headers={
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Referer": "https://pan.baidu.com",
    })
    with urllib.request.urlopen(dl_req) as resp:
        content = resp.read()
    
    out_path = os.path.join(DEST, fname)
    with open(out_path, "wb") as f:
        f.write(content)
    
    size = os.path.getsize(out_path)
    print(f"Downloaded: {size} bytes -> {out_path}")
    
    # 检查是否为有效docx（zip格式）
    if content[:2] == b"PK":
        print("Valid DOCX (ZIP format)")
    else:
        print(f"WARNING: file may be invalid. First bytes: {content[:100]}")
