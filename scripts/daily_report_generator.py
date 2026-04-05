#!/usr/bin/env python3
"""每日工作汇报生成器 + Memos 同步"""
import json, os, subprocess, time, sys, re
from pathlib import Path
from datetime import datetime

DATE = sys.argv[1] if len(sys.argv) > 1 else datetime.now().strftime('%Y-%m-%d')
NOW = datetime.now().strftime('%Y-%m-%d %H:%M')
ACTION = sys.argv[2] if len(sys.argv) > 2 else 'generate'
CUTOFF = time.time() - 86400
MEMOS_PAT = "memos_pat_SNWmx8pERXcFPZVdQcDtGnatmUZ18Yq0"
MEMOS_URL = "https://memos.eieai.us.ci/api/v1"

def extract_user_messages(jsonl_path, max_msgs=8):
    msgs = []
    seen = set()
    try:
        with open(jsonl_path) as f:
            for line in f:
                line = line.strip()
                if not line: continue
                try:
                    d = json.loads(line)
                    if d.get('type') != 'message':
                        continue
                    msg = d.get('message', {})
                    if msg.get('role') != 'user':
                        continue
                    content = msg.get('content', '')
                    texts = []
                    if isinstance(content, list):
                        for c in content:
                            if isinstance(c, dict) and c.get('type') == 'text':
                                t = c.get('text', '').strip()
                                if t and len(t) > 6 and 'HEARTBEAT_OK' not in t and 'Read HEARTBEAT.md' not in t:
                                    texts.append(t)
                    elif isinstance(content, str) and content.strip():
                        t = content.strip()
                        if 'HEARTBEAT_OK' not in t and 'Read HEARTBEAT.md' not in t:
                            texts.append(t)
                    for t in texts:
                        short = t[:100]
                        if short not in seen:
                            seen.add(short)
                            msgs.append(short)
                except: pass
    except: pass
    return msgs[:max_msgs]

def get_instance_status(ip, ssh_key):
    try:
        r = subprocess.run(
            ['ssh', '-i', ssh_key, '-o', 'StrictHostKeyChecking=no',
             '-o', 'ConnectTimeout=8', f'ubuntu@{ip}', 'echo OK'],
            capture_output=True, text=True, timeout=12
        )
        if r.returncode != 0:
            return 'offline', 'SSH连接失败'
        r2 = subprocess.run(
            ['ssh', '-i', ssh_key, '-o', 'StrictHostKeyChecking=no',
             '-o', 'ConnectTimeout=10', f'ubuntu@{ip}',
             'free -h | grep Mem | awk \'{print $3"/"$2}\'; df -h / | tail -1 | awk \'{print $5}\'; uptime | awk -F"load average:" \'{print $2}\''],
            capture_output=True, text=True, timeout=15
        )
        lines = [l.strip() for l in r2.stdout.strip().split('\n') if l.strip()]
        return 'online', f"内存 {lines[0] if len(lines)>0 else '?'} | 磁盘 {lines[1] if len(lines)>1 else '?'} | 负载 {lines[2] if len(lines)>2 else '?'}"
    except Exception as e:
        return 'error', str(e)[:50]

def memos_create(content):
    """通过 Memos API 创建备忘录"""
    import tempfile
    payload = {"content": content, "visibility": "PRIVATE"}
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(payload, f)
            f.flush()
            tf = f.name
        result = subprocess.run(
            ['curl', '-s', '-X', 'POST', f'{MEMOS_URL}/memos',
             '-H', f'Authorization: Bearer {MEMOS_PAT}',
             '-H', 'Content-Type: application/json',
             '-d', f'@{tf}'],
            capture_output=True, text=True, timeout=20
        )
        import os; os.unlink(tf)
        resp = json.loads(result.stdout)
        if 'name' in resp:
            return True, resp['name'].replace('memos/', '')
        return False, resp.get('message', 'Unknown error')
    except Exception as e:
        return False, str(e)

def generate():
    ssh_key = os.path.expanduser('~/.ssh/id_ed25519')
    
    # 收集会话
    sessions_dir = Path.home() / '.openclaw' / 'agents' / 'main' / 'sessions'
    session_files = []
    if sessions_dir.exists():
        for f in sessions_dir.glob('*.jsonl'):
            if f.stat().st_mtime > CUTOFF:
                session_files.append((f.stat().st_mtime, str(f)))
        session_files.sort(reverse=True)
    
    all_msgs = []
    for _, sf in session_files[:6]:
        all_msgs.extend(extract_user_messages(sf))
    
    unique, seen = [], set()
    for m in all_msgs:
        short = m[:80]
        if short not in seen and len(m) > 10:
            seen.add(short)
            unique.append(m)
    
    report = f"""# 📋 每日工作汇报 {DATE}

> 生成时间: {NOW}

---

## 一、📌 今日工作记录

"""
    if unique:
        for m in unique[:12]:
            report += f"- {m}...\n"
    else:
        report += "_今日暂无工作记录_\n"
    report += "\n---\n\n## 二、🖥️ 系统状态\n\n"
    
    instances = [
        ('AMD-1', '158.179.175.145'),
        ('AMD-2', '158.179.170.192'),
        ('ARM', '144.24.73.140'),
    ]
    for name, ip in instances:
        status, detail = get_instance_status(ip, ssh_key)
        emoji = '✅' if status == 'online' else '❌'
        report += f"**{name}** ({ip}) {emoji}\n{detail}\n\n"
    
    report += "---\n\n## 三、📁 备份状态\n\n"
    backup_dir = Path.home() / 'openclaw' / 'backups' / DATE
    if backup_dir.exists():
        items = list(backup_dir.iterdir())
        report += f"✅ 今日备份已完成（{len(items)} 个项目）\n\n"
    else:
        report += "⚠️ 今日备份未找到\n\n"
    
    report += f"---\n_由 OpenClaw 自动生成 · {NOW}_\n"
    return report

if __name__ == '__main__':
    if ACTION == 'generate':
        print(generate())
    elif ACTION == 'sync':
        report = generate()
        ok, result = memos_create(report)
        if ok:
            print(f"✅ Memos UID: {result}")
        else:
            print(f"❌ Memos 同步失败: {result}")
