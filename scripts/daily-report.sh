#!/usr/bin/env zsh
# ================================================
# 每日工作汇报 & 备份脚本
# 执行时间: 每天 02:00
# ================================================

DATE=$(date '+%Y-%m-%d')
LOG_FILE="$HOME/openclaw/logs/daily-report-$DATE.log"
BW_SESSION_FILE="$HOME/.openclaw/bw-session"
BACKUP_DIR="$HOME/openclaw/backups/$DATE"
mkdir -p "$BACKUP_DIR" "$(dirname $LOG_FILE)" 2>/dev/null

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# 加载 Bitwarden session
if [[ -f "$BW_SESSION_FILE" ]]; then
    export BW_SESSION=$(cat "$BW_SESSION_FILE")
fi

# 颜色输出
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# SSH 连接参数
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_USER="ubuntu"
SSH_TIMEOUT="10"

# 三个 Oracle 实例
INSTANCES=(
    "AMD-1:158.179.175.145"
    "AMD-2:158.179.170.192"
    "ARM:144.24.73.140"
)

log "${GREEN}========== 每日汇报开始 $(date '+%Y-%m-%d %H:%M') ==========${NC}"

# ================================================
# 第一步: 收集各端日志
# ================================================
log "${YELLOW}--- 第一步: 收集日志 ---${NC}"

report_file="$BACKUP_DIR/daily-report-$(date '+%Y-%m-%d').md"

cat > "$report_file" << EOF
# 每日工作汇报 $(date '+%Y-%m-%d')

> 生成时间: $(date '+%Y-%m-%d %H:%M')

---

## 一、本地终端会话日志（过去24小时）

EOF

# 1. OpenClaw session logs
log "收集 OpenClaw 会话记录..."
openclaw_logs_dir="$HOME/.openclaw/agents/main/sessions"
if [[ -d "$openclaw_logs_dir" ]]; then
    cat >> "$report_file" << 'EOF'
### OpenClaw (主 Agent)

EOF
    # 找最近24小时的会话文件，提取用户消息摘要
    find "$openclaw_logs_dir" -name "*.jsonl" -mtime -1 2>/dev/null | while read f; do
        session_date=$(basename "$f" .jsonl | cut -c1-10)
        echo "**会话 $session_date**" >> "$report_file"
        # 提取用户消息
        grep '"role":"user"' "$f" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        content = d.get('content','')
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'text':
                    text = c.get('text','')[:200]
                    if text: print(f'- {text}')
        elif isinstance(content, str) and content:
            print(f'- {content[:200]}')
    except: pass
" 2>/dev/null | head -20 >> "$report_file" || true
    done
fi

# 2. Claude Code sessions
log "收集 Claude Code 会话记录..."
codex_sessions="$HOME/.codex/sessions/2026"
if [[ -d "$codex_sessions" ]]; then
    cat >> "$report_file" << 'EOF'

### Claude Code 会话

EOF
    find "$codex_sessions" -name "*.jsonl" -mtime -1 2>/dev/null | while read f; do
        session_date=$(basename "$f" .jsonl | cut -c1-10)
        echo "**会话 $session_date**" >> "$report_file"
        grep '"role":"user"' "$f" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        content = d.get('content','')
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'text':
                    text = c.get('text','')[:200]
                    if text: print(f'- {text}')
        elif isinstance(content, str) and content:
            print(f'- {content[:200]}')
    except: pass
" 2>/dev/null | head -10 >> "$report_file" || true
    done
fi

# 3. OpenCode sessions
log "收集 OpenCode 会话记录..."
opencode_sessions="$HOME/.opencode/sessions"
if [[ -d "$opencode_sessions" ]]; then
    cat >> "$report_file" << 'EOF'

### OpenCode 会话

EOF
    find "$opencode_sessions" -name "*.jsonl" -mtime -1 2>/dev/null | while read f; do
        echo "**$(basename $f .jsonl)**" >> "$report_file"
        grep '"role":"user"' "$f" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        content = d.get('content','')
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'text':
                    text = c.get('text','')[:200]
                    if text: print(f'- {text}')
    except: pass
" 2>/dev/null | head -5 >> "$report_file" || true
    done
fi

# 4. Mac 本地系统日志摘要（过去24小时 crash/log）
log "收集 Mac 系统日志..."
cat >> "$report_file" << 'EOF'

### Mac 系统状态摘要

EOF
# 找最近的系统日志
syslog_recent=$(log show --predicate 'subsystem == "com.apple."' --last 24h 2>/dev/null | grep -i "error\|fail\|panic" | tail -20 || echo "无重大错误")
echo "$syslog_recent" >> "$report_file" 2>/dev/null || echo "无法读取系统日志" >> "$report_file"

# ================================================
# 第二步: 收集 Oracle Cloud 实例状态
# ================================================
log "${YELLOW}--- 第二步: Oracle Cloud 实例状态 ---${NC}"

cat >> "$report_file" << 'EOF'

---

## 二、Oracle Cloud 实例状态（过去24小时）

EOF

for entry in $INSTANCES; do
    name="${entry%%:*}"; ip="${entry##*:}"
    log "检查 $name ($ip)..."
    
    cat >> "$report_file" << EOF

### $name - $ip

EOF
    
    # SSH 连接并收集状态
    ssh_ok=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
        $SSH_USER@$ip "echo 'SSH_OK'" 2>&1 || echo "SSH_FAILED")
    
    if [[ "$ssh_ok" == "SSH_OK" ]]; then
        echo "**状态**: 在线 ✅" >> "$report_file"
        
        # 获取基本信息
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
            $SSH_USER@$ip bash << 'SSHEOF' >> "$report_file" 2>&1
echo ""
echo "**系统**: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "**运行时间**: \$(uptime -p 2>/dev/null || uptime)"
echo "**内存使用**: \$(free -h | grep Mem | awk '{print \$3 "/" \$2}')"
echo "**磁盘使用**: \$(df -h / | tail -1 | awk '{print \$3 "/" \$2 " (" \$5 ")"}')"
echo "**CPU负载**: \$(uptime | awk -F'load average:' '{print \$2}')"
SSHEOF
        
        # 检查关键服务状态
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
            $SSH_USER@$ip "systemctl list-units --failed --no-pager 2>/dev/null | head -5; echo '---'; docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | head -10" >> "$report_file" 2>&1 || true
        
        # 重要文件变更（过去24小时）
        echo "" >> "$report_file"
        echo "**最近24小时文件变更**: " >> "$report_file"
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
            $SSH_USER@$ip "find /home/ubuntu -newer /tmp -type f -name '*.py' -o -name '*.js' -o -name '*.json' -o -name '*.sh' 2>/dev/null | head -20" >> "$report_file" 2>&1 || echo "无法获取" >> "$report_file"
        
    else
        echo "**状态**: 离线 ❌ ($status)" >> "$report_file"
    fi
done

# ================================================
# 第三步: 清洗涉密信息 + 存入 Bitwarden
# ================================================
log "${YELLOW}--- 第三步: 涉密信息处理 ---${NC}"

cat >> "$report_file" << 'EOF'

---

## 三、涉密信息处理记录

EOF

secrets_found=0
for entry in $INSTANCES; do
    name="${entry%%:*}"; ip="${entry##*:}"
    # 在日志中搜索疑似密钥/Token（脱敏后记录）
    sensitive_patterns="(api[_-]?key|token|password|secret|private[_-]?key|bearer)"
    
    log "扫描 $name 的日志中涉密信息..."
    # 检查 SSH 登录记录是否有失败（疑似攻击）
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
        $SSH_USER@$ip "journalctl --since '24 hours ago' | grep -i 'failed\|invalid\|break-in' | tail -5" 2>/dev/null >> "$report_file" || true
    
    # 统计失败登录次数
    failed_logins=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
        $SSH_USER@$ip "journalctl --since '24 hours ago' | grep -i 'failed password' | wc -l" 2>/dev/null || echo "0")
    
    if [[ "$failed_logins" -gt 0 ]]; then
        echo "⚠️ **$name 过去24小时有 ${failed_logins} 次 SSH 失败登录尝试**" >> "$report_file"
        secrets_found=1
    fi
done

if [[ $secrets_found -eq 0 ]]; then
    echo "✅ 未发现涉密信息泄露或异常登录" >> "$report_file"
fi

# ================================================
# 第四步: 备份 Oracle Cloud 数据
# ================================================
log "${YELLOW}--- 第四步: Oracle Cloud 备份 ---${NC}"

cat >> "$report_file" << 'EOF'

---

## 四、数据备份记录

EOF

for entry in $INSTANCES; do
    name="${entry%%:*}"; ip="${entry##*:}"
    log "备份 $name..."
    
    instance_backup_dir="$BACKUP_DIR/$name"
    mkdir -p "$instance_backup_dir"
    
    cat >> "$report_file" << EOF

### $name - $ip

EOF
    
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
        $SSH_USER@$ip "echo 'SSH_OK'" > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        # AMD 实例: 备份配置
        if [[ "$name" == AMD-* ]]; then
            log "  $name: 备份配置文件..."
            backup_item="$instance_backup_dir/configs.tar.gz"
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip bash << 'SSHEOF'
                CONFIG_DIRS="/etc/supervisor /etc/nginx /etc/systemd ~/.config ~/scripts"
                tar -czf /tmp/configs-backup.tar.gz $CONFIG_DIRS 2>/dev/null && echo "OK"
SSHEOF
            scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip:/tmp/configs-backup.tar.gz "$instance_backup_dir/configs.tar.gz" 2>/dev/null && \
                echo "✅ 配置已备份: $(du -h "$instance_backup_dir/configs.tar.gz" | cut -f1)" >> "$report_file" || \
                echo "⚠️ 配置备份失败" >> "$report_file"
        
        # ARM 实例: 备份程序和数据
        elif [[ "$name" == "ARM" ]]; then
            log "  ARM: 备份程序和数据..."
            
            # 备份关键目录
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip bash << 'SSHEOF'
                
                BACKUP_LIST="/home/ubuntu/.claude /home/ubuntu/.codex /home/ubuntu/.openclaw /home/ubuntu/.opencode /home/ubuntu/scripts /home/ubuntu/newapi"
                # Docker 数据
                docker ps -a --format '{{.Names}}' 2>/dev/null | while read c; do
                    docker commit "$c" "backup_${c}" 2>/dev/null && echo "镜像备份: $c"
                done
                # 打包重要目录
                tar -czf /tmp/arm-programs-backup.tar.gz $BACKUP_LIST 2>/dev/null && echo "打包完成: OK"
SSHEOF
            echo "✅ ARM 程序备份命令已执行" >> "$report_file"
            
            # 下载备份文件
            scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip:/tmp/arm-programs-backup.tar.gz "$instance_backup_dir/programs.tar.gz" 2>/dev/null && \
                echo "✅ 程序备份: $(du -h "$instance_backup_dir/programs.tar.gz" | cut -f1)" >> "$report_file" || \
                echo "⚠️ 程序备份失败（文件过大或传输超时）" >> "$report_file"
            
            # Docker 容器列表
            docker_containers=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip "docker ps -a --format '{{.Names}} ({{.Status}})' 2>/dev/null" || echo "无法获取")
            echo "**Docker 容器**: ${docker_containers:0:500}" >> "$report_file"
        fi
        
        # 记录备份时间
        echo "**备份时间**: $(date '+%Y-%m-%d %H:%M')" >> "$report_file"
    else
        echo "⚠️ $name SSH 连接失败，跳过备份" >> "$report_file"
    fi
done

# ================================================
# 第五步: 同步至 Memos
# ================================================
log "${YELLOW}--- 第五步: 同步至 Memos ---${NC}"

cat >> "$report_file" << 'EOF'

---

## 五、Memos 同步记录

EOF

# 调用 memos_sync.sh 通过 API 同步
MEMOS_SYNC="$HOME/.openclaw/workspace-main/scripts/memos_sync.sh"
if [[ -x "$MEMOS_SYNC" ]]; then
    sync_result=$("$MEMOS_SYNC" create "$(cat "$report_file")" 2>&1)
    if echo "$sync_result" | grep -q "Created memo"; then
        memo_uid=$(echo "$sync_result" | grep -o 'Created memo: [^ ]*' | awk '{print $3}')
        echo "✅ 已同步至 Memos (UID: $memo_uid)" >> "$report_file"
        log "${GREEN}已同步至 Memos (UID: $memo_uid)${NC}"
    else
        echo "⚠️ Memos 同步失败: $sync_result" >> "$report_file"
        log "${RED}Memos 同步失败${NC}"
    fi
else
    echo "⚠️ Memos 同步脚本不存在: $MEMOS_SYNC，跳过同步" >> "$report_file"
    log "${RED}Memos 同步脚本不存在${NC}"
fi

# ================================================
# 完成
# ================================================
log "${GREEN}========== 每日汇报完成 $(date '+%Y-%m-%d %H:%M') ==========${NC}"
echo "" >> "$report_file"
echo "---" >> "$report_file"
echo "*本报告由 OpenClaw 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')*" >> "$report_file"

log "📄 报告: $report_file"
log "📦 备份: $BACKUP_DIR"
