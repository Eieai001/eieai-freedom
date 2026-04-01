#!/usr/bin/env python3
"""
图片扫描与分类脚本 - Phase 1
扫描mymemory中的所有图片，建立基础映射
"""

import os
import json
import hashlib
from pathlib import Path
from datetime import datetime
from collections import defaultdict

BASE_DIR = Path.home() / "mymemory"
OUTPUT_DIR = Path.home() / ".openclaw/workspace-main/projects/image-mapping-system"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.HEIC', '.bmp', '.tiff'}

def extract_date_from_filename(filename):
    """从文件名提取日期"""
    import re
    # 匹配常见日期格式: 20220503, 2022-05-03, 2022_05_03
    patterns = [
        r'(\d{4})[-_]?(\d{2})[-_]?(\d{2})',
        r'(\d{4})(\d{2})(\d{2})',
    ]
    for pattern in patterns:
        match = re.search(pattern, filename)
        if match:
            try:
                year, month, day = match.groups()
                return f"{year}-{month}-{day}"
            except:
                pass
    return None

def categorize_image(file_path):
    """根据路径分类图片"""
    path_str = str(file_path).lower()
    
    if 'screenshot' in path_str or '截图' in path_str:
        # 进一步细分截图类型
        if 'wechat' in path_str or 'mm' in path_str or '微信' in path_str:
            return 'business_chat'
        elif 'xhs' in path_str or 'xiaohongshu' in path_str or '小红书' in path_str:
            return 'social_media'
        elif 'alipay' in path_str or '支付宝' in path_str:
            return 'payment'
        elif 'baidu' in path_str:
            return 'search'
        else:
            return 'screenshot'
    
    if any(x in path_str for x in ['猫粮', '猫砂', '罐头', '宠物', 'pet', 'cat', 'dog']):
        return 'pet_product'
    
    if any(x in path_str for x in ['证件', '资质', '合同', 'license', 'cert']):
        return 'document'
    
    if 'wechat' in path_str or '微信' in path_str:
        return 'wechat_image'
    
    if any(x in path_str for x in ['dcim', 'camera', '照片']):
        return 'photo'
    
    return 'other'

def get_source_device(file_path):
    """识别设备来源"""
    path_str = str(file_path)
    if 'xiaomi' in path_str.lower():
        return 'xiaomi'
    elif 'meizu' in path_str.lower():
        return 'meizu'
    elif 'wechat' in path_str.lower():
        return 'wechat_backup'
    else:
        return 'unknown'

def scan_images():
    """扫描所有图片"""
    images = []
    stats = defaultdict(int)
    
    print(f"🔍 扫描目录: {BASE_DIR}")
    
    for ext in IMAGE_EXTENSIONS:
        for file_path in BASE_DIR.rglob(f"*{ext}"):
            try:
                stat = file_path.stat()
                file_hash = hashlib.md5(file_path.read_bytes()).hexdigest()[:16]
                
                image_info = {
                    "id": file_hash,
                    "file_path": str(file_path),
                    "file_name": file_path.name,
                    "extension": file_path.suffix.lower(),
                    "size_bytes": stat.st_size,
                    "source_device": get_source_device(file_path),
                    "category": categorize_image(file_path),
                    "date_from_filename": extract_date_from_filename(file_path.name),
                    "modified_time": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    "status": "pending",
                    "processed_at": None,
                    "extracted_text": None,
                    "description": None,
                    "tags": [],
                    "business_relevance": None
                }
                
                images.append(image_info)
                stats[image_info['category']] += 1
                
                if len(images) % 100 == 0:
                    print(f"  已扫描: {len(images)} 张图片")
                    
            except Exception as e:
                print(f"  ⚠️ 错误: {file_path} - {e}")
    
    return images, stats

def main():
    print("=" * 60)
    print("图片扫描与分类系统 - Phase 1")
    print("=" * 60)
    
    images, stats = scan_images()
    
    # 保存完整列表
    output_file = OUTPUT_DIR / "image_index.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(images, f, ensure_ascii=False, indent=2)
    
    # 保存统计
    stats_file = OUTPUT_DIR / "category_stats.json"
    with open(stats_file, 'w', encoding='utf-8') as f:
        json.dump(dict(stats), f, ensure_ascii=False, indent=2)
    
    # 按分类保存队列
    for category in set(img['category'] for img in images):
        category_images = [img for img in images if img['category'] == category]
        queue_file = OUTPUT_DIR / f"queue_{category}.json"
        with open(queue_file, 'w', encoding='utf-8') as f:
            json.dump(category_images, f, ensure_ascii=False, indent=2)
    
    print("\n✅ 扫描完成!")
    print(f"📊 总计: {len(images)} 张图片")
    print(f"\n📁 分类统计:")
    for cat, count in sorted(stats.items(), key=lambda x: -x[1]):
        print(f"  {cat:20s}: {count:4d} 张")
    
    print(f"\n💾 输出文件:")
    print(f"  - {output_file}")
    print(f"  - {stats_file}")
    print(f"  - queue_*.json (按分类)")

if __name__ == "__main__":
    main()
