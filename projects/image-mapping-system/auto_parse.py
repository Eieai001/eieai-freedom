#!/usr/bin/env python3
"""
图片自动解析脚本 - API可用后自动执行
按优先级批量处理2473张图片
"""

import os
import json
import subprocess
import time
import sys
from pathlib import Path
from datetime import datetime

BASE_DIR = Path.home() / ".openclaw/workspace-main/projects/image-mapping-system"
RESULTS_FILE = BASE_DIR / "parsed_results.jsonl"
PROGRESS_FILE = BASE_DIR / "parse_progress.json"
LOG_FILE = BASE_DIR / "parse_log.txt"

# 优先级队列（按商业价值排序）
PRIORITY_QUEUES = [
    ("queue_document.json", 4, "P0-证件资质"),
    ("queue_payment.json", 6, "P0-支付交易"),
    ("queue_business_chat.json", 80, "P1-商务沟通"),
    ("queue_pet_product.json", 312, "P1-产品图片"),
    ("queue_wechat_image.json", 7, "P2-微信图片"),
    ("queue_social_media.json", 2, "P2-社交媒体"),
    ("queue_search.json", 196, "P3-搜索截图"),
    ("queue_photo.json", 399, "P3-个人照片"),
    ("queue_other.json", 1467, "P4-其他"),
]

def log(message):
    """记录日志"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_msg = f"[{timestamp}] {message}"
    print(log_msg)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(log_msg + '\n')

def check_api_available():
    """检查MiniMax API是否可用"""
    test_image = "/Users/eieai/mymemory/BaiduNetdisk-backup/来自：MEIZU 20/Screenshots/S51003-19451227_com.tencent.mm.png"
    try:
        result = subprocess.run(
            ["mcporter", "call", "MiniMax.understand_image", 
             "prompt=描述这张图片", f"image_source={test_image}"],
            capture_output=True, text=True, timeout=30
        )
        if "usage limit exceeded" in result.stderr or result.returncode != 0:
            return False
        return True
    except Exception as e:
        log(f"API检查失败: {e}")
        return False

def load_progress():
    """加载处理进度"""
    if PROGRESS_FILE.exists():
        with open(PROGRESS_FILE, 'r') as f:
            return json.load(f)
    return {"completed_ids": [], "current_queue": None, "queue_index": 0}

def save_progress(progress):
    """保存处理进度"""
    with open(PROGRESS_FILE, 'w') as f:
        json.dump(progress, f, indent=2)

def parse_image(image_info):
    """使用MiniMax MCP解析单张图片"""
    image_path = image_info['file_path']
    
    prompts = {
        'document': "这是一张证件或资质文件。提取：1)文件类型 2)公司名称 3)编号/证书号 4)有效期 5)关键信息摘要",
        'payment': "这是一张支付或交易截图。提取：1)交易类型 2)金额 3)交易对象 4)时间 5)订单号/流水号",
        'business_chat': "这是微信聊天截图。提取：1)聊天对象/群名 2)对话主题 3)关键信息 4)待办事项 5)商业相关内容",
        'pet_product': "这是宠物产品图片。提取：1)产品类型 2)品牌名称 3)规格/重量 4)价格信息 5)产品特点",
        'default': "详细描述这张图片的内容。提取所有可见的文字信息，描述场景和关键元素。"
    }
    
    category = image_info.get('category', 'default')
    prompt = prompts.get(category, prompts['default'])
    
    try:
        result = subprocess.run(
            ["mcporter", "call", "MiniMax.understand_image", 
             f"prompt={prompt}", f"image_source={image_path}"],
            capture_output=True, text=True, timeout=60
        )
        
        if "usage limit exceeded" in result.stderr:
            return {"status": "api_limited", "error": "API用量超限"}
        
        if result.returncode == 0:
            return {
                "status": "success",
                "description": result.stdout.strip(),
                "parsed_at": datetime.now().isoformat()
            }
        else:
            return {
                "status": "error",
                "error": result.stderr.strip(),
                "parsed_at": datetime.now().isoformat()
            }
    except subprocess.TimeoutExpired:
        return {"status": "timeout", "error": "解析超时"}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def extract_tags(description, category):
    """从描述中提取标签"""
    tags = [category]
    keywords = {
        'product': ['产品', '商品', '猫粮', '猫砂', '罐头', '包装', '价格', '规格'],
        'business': ['公司', '厂家', '供应商', '批发', '代理', '合作'],
        'chat': ['聊天', '对话', '微信', '消息'],
        'document': ['证件', '资质', '证书', '合同', '营业执照'],
        'pet': ['猫', '狗', '宠物'],
        'payment': ['支付', '转账', '金额', '收款']
    }
    
    for cat, words in keywords.items():
        if any(word in description for word in words):
            tags.append(cat)
    
    return list(set(tags))

def assess_business_relevance(category, description):
    """评估商业相关度"""
    scores = {
        'document': 10, 'payment': 9, 'business_chat': 8,
        'pet_product': 7, 'wechat_image': 6, 'social_media': 5,
        'search': 3, 'photo': 1, 'other': 0
    }
    score = scores.get(category, 0)
    
    business_keywords = ['公司', '厂家', '价格', '规格', '合作', '订单', '金额', '合同']
    for keyword in business_keywords:
        if keyword in description:
            score += 1
    
    return min(score, 10)

def send_progress_report(queue_name, processed, total, high_value_items=None):
    """发送进度报告"""
    message = f"📊 图片解析进度报告\n\n当前队列: {queue_name}\n进度: {processed}/{total} ({processed/total*100:.1f}%)\n"
    
    if high_value_items:
        message += f"\n🔍 发现高价值信息:\n"
        for item in high_value_items[:5]:
            message += f"- {item['file_name']}: {item['description'][:100]}...\n"
    
    # 通过message工具发送
    try:
        subprocess.run(
            ["openclaw", "message", "send", "--channel", "feishu", "--message", message],
            capture_output=True, timeout=30
        )
    except:
        pass

def process_queue(queue_file, queue_name, max_images, progress):
    """处理一个队列"""
    queue_path = BASE_DIR / queue_file
    
    if not queue_path.exists():
        log(f"队列文件不存在: {queue_file}")
        return 0, False
    
    with open(queue_path, 'r') as f:
        images = json.load(f)
    
    # 过滤已完成的
    images = [img for img in images if img['id'] not in progress['completed_ids']]
    images = images[:max_images]
    
    if not images:
        log(f"队列 {queue_name} 无待处理图片")
        return 0, False
    
    log(f"🔄 开始处理队列: {queue_name} ({len(images)}张图片)")
    
    processed = 0
    high_value_items = []
    
    for i, img in enumerate(images):
        log(f"  [{i+1}/{len(images)}] {img['file_name']}")
        
        # 解析图片
        result = parse_image(img)
        
        if result['status'] == 'api_limited':
            log("⚠️ API用量超限，暂停处理")
            save_progress(progress)
            return processed, True  # 需要暂停
        
        # 更新记录
        img['status'] = 'done' if result['status'] == 'success' else 'error'
        img['parsed_at'] = result.get('parsed_at', datetime.now().isoformat())
        
        if result['status'] == 'success':
            img['description'] = result['description']
            img['tags'] = extract_tags(result['description'], img['category'])
            img['business_relevance'] = assess_business_relevance(img['category'], result['description'])
            
            if img['business_relevance'] >= 7:
                high_value_items.append(img)
        else:
            img['error'] = result.get('error', 'Unknown error')
        
        # 保存到结果文件
        with open(RESULTS_FILE, 'a', encoding='utf-8') as f:
            f.write(json.dumps(img, ensure_ascii=False) + '\n')
        
        progress['completed_ids'].append(img['id'])
        processed += 1
        
        # 每10张保存一次进度
        if processed % 10 == 0:
            save_progress(progress)
        
        # 限速
        time.sleep(2)
    
    # 发送进度报告
    if processed > 0:
        send_progress_report(queue_name, processed, len(images), high_value_items)
    
    log(f"✅ 队列 {queue_name} 完成: {processed}张")
    return processed, False

def main():
    log("=" * 60)
    log("图片自动解析系统 - 开始执行")
    log("=" * 60)
    
    # 检查API可用性
    log("🔍 检查MiniMax API可用性...")
    if not check_api_available():
        log("❌ API仍受限，任务退出")
        sys.exit(1)
    
    log("✅ API可用，开始处理")
    
    # 加载进度
    progress = load_progress()
    log(f"📊 已处理: {len(progress['completed_ids'])}张")
    
    total_processed = 0
    api_limited = False
    
    # 按优先级处理队列
    for queue_file, count, name in PRIORITY_QUEUES:
        if api_limited:
            break
        
        processed, api_limited = process_queue(queue_file, name, count, progress)
        total_processed += processed
        
        # 队列间休息
        time.sleep(5)
    
    # 保存最终进度
    save_progress(progress)
    
    # 发送完成报告
    if api_limited:
        log(f"⏸️ 处理暂停（API限制）。已处理: {total_processed}张")
    else:
        log(f"🎉 全部完成！总计处理: {total_processed}张")
    
    log(f"💾 结果文件: {RESULTS_FILE}")
    log(f"📋 日志文件: {LOG_FILE}")

if __name__ == "__main__":
    main()
