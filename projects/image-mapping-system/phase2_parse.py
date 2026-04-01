#!/usr/bin/env python3
"""
图片批量解析脚本 - Phase 2
使用MiniMax MCP解析图片内容
"""

import os
import json
import subprocess
import time
from pathlib import Path
from datetime import datetime

OUTPUT_DIR = Path.home() / ".openclaw/workspace-main/projects/image-mapping-system"
RESULTS_FILE = OUTPUT_DIR / "parsed_results.jsonl"

# 优先级队列（按商业 value排序）
PRIORITY_QUEUES = [
    "queue_document.json",      # 4张 - 资质证件，最高价值
    "queue_payment.json",       # 6张 - 支付/交易
    "queue_business_chat.json", # 80张 - 商务沟通
    "queue_pet_product.json",   # 312张 - 产品图片
    "queue_wechat_image.json",  # 7张 - 微信图片
    "queue_social_media.json",  # 2张 - 社交媒体
    "queue_search.json",        # 196张 - 搜索截图
    "queue_photo.json",         # 399张 - 个人照片
    "queue_other.json",         # 1467张 - 其他
]

def parse_image_with_minimax(image_path):
    """使用MiniMax MCP解析图片"""
    try:
        # 构建mcporter命令
        cmd = [
            "mcporter", "call", "MiniMax.understand_image",
            f"prompt=详细描述这张图片的内容。如果是产品图片，提取产品名称、品牌、规格、价格等信息。如果是截图，提取其中的文字内容和上下文。如果是证件/资质，提取关键信息如公司名称、编号、有效期等。",
            f"image_source={image_path}"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            return {
                "success": True,
                "description": result.stdout.strip(),
                "parsed_at": datetime.now().isoformat()
            }
        else:
            return {
                "success": False,
                "error": result.stderr.strip(),
                "parsed_at": datetime.now().isoformat()
            }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "parsed_at": datetime.now().isoformat()
        }

def process_batch(queue_file, max_images=None):
    """处理一个队列文件"""
    queue_path = OUTPUT_DIR / queue_file
    
    if not queue_path.exists():
        print(f"⚠️ 队列文件不存在: {queue_file}")
        return 0
    
    with open(queue_path, 'r') as f:
        images = json.load(f)
    
    if max_images:
        images = images[:max_images]
    
    print(f"\n🔄 处理队列: {queue_file} ({len(images)}张图片)")
    
    processed = 0
    for i, img in enumerate(images):
        # 检查是否已处理
        if img.get('status') == 'done':
            continue
        
        print(f"  [{i+1}/{len(images)}] {img['file_name']}")
        
        # 解析图片
        result = parse_image_with_minimax(img['file_path'])
        
        # 更新记录
        img['status'] = 'done' if result['success'] else 'error'
        img['parsed_at'] = result['parsed_at']
        
        if result['success']:
            img['description'] = result['description']
            # 提取标签（从描述中）
            img['tags'] = extract_tags(result['description'])
            # 评估商业相关度
            img['business_relevance'] = assess_business_relevance(img, result['description'])
        else:
            img['error'] = result.get('error', 'Unknown error')
        
        # 保存到结果文件
        with open(RESULTS_FILE, 'a', encoding='utf-8') as f:
            f.write(json.dumps(img, ensure_ascii=False) + '\n')
        
        processed += 1
        
        # 限速，避免API限制
        time.sleep(1)
    
    return processed

def extract_tags(description):
    """从描述中提取标签"""
    tags = []
    keywords = {
        'product': ['产品', '商品', '猫粮', '猫砂', '罐头', '包装', '价格', '规格'],
        'business': ['公司', '厂家', '供应商', '批发', '代理', '合作'],
        'chat': ['聊天', '对话', '微信', '消息', '沟通'],
        'document': ['证件', '资质', '证书', '合同', '营业执照'],
        'pet': ['猫', '狗', '宠物', '动物'],
        'payment': ['支付', '转账', '金额', '收款', '订单']
    }
    
    for category, words in keywords.items():
        if any(word in description for word in words):
            tags.append(category)
    
    return tags

def assess_business_relevance(img, description):
    """评估商业相关度 (0-10)"""
    score = 0
    
    # 根据分类加分
    category_scores = {
        'document': 10,
        'payment': 9,
        'business_chat': 8,
        'pet_product': 7,
        'wechat_image': 6,
        'social_media': 5,
        'search': 3,
        'photo': 1,
        'other': 0
    }
    score += category_scores.get(img['category'], 0)
    
    # 根据关键词加分
    business_keywords = ['公司', '厂家', '价格', '规格', '合作', '订单', '金额', '合同']
    for keyword in business_keywords:
        if keyword in description:
            score += 1
    
    return min(score, 10)

def main():
    print("=" * 60)
    print("图片批量解析系统 - Phase 2")
    print("=" * 60)
    print(f"输出文件: {RESULTS_FILE}")
    
    total_processed = 0
    
    for queue_file in PRIORITY_QUEUES:
        processed = process_batch(queue_file, max_images=10)  # 先处理10张测试
        total_processed += processed
        
        if processed > 0:
            print(f"  ✅ 已处理: {processed} 张")
    
    print(f"\n🎉 总计处理: {total_processed} 张图片")
    print(f"💾 结果保存到: {RESULTS_FILE}")

if __name__ == "__main__":
    main()
