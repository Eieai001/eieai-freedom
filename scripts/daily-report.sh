#!/usr/bin/env zsh
# ================================================
# 每日工作汇报 & 备份脚本
# 执行时间: 每天 02:00
# ================================================

DATE=$(date '+%Y-%m-%d')
LOG_FILE="$HOME/openclaw/logs/daily-report-$DATE.log"
BACKUP_DIR="$HOME/openclaw/backups/$DATE"
mkdir -p "$BACKUP_DIR" "$(dirname $LOG_FILE)" 2>/dev/null

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_USER="ubuntu"
SSH_TIMEOUT="10"

INSTANCES=(
    "AMD-1:158.179.175.145"
    "AMD-2:158.179.170.192"
    "ARM:144.24.73.140"
)

report_file="$BACKUP_DIR/daily-report-$(date '+%Y-%m-%d').md"
GENERATOR="$HOME/.openclaw/workspace-main/scripts/daily_report_generator.py"

log "${GREEN}========== 每日汇报开始 $(date '+%Y-%m-%d %H:%M') ==========${NC}"

# ================================================
# 第一步: 生成人类可读的工作汇报
# ================================================
log "${YELLOW}--- 生成工作汇报 ---${NC}"

if [[ -x "$GENERATOR" ]]; then
    REPORT_CONTENT=$("$GENERATOR" "$DATE" 2>&1)
    echo "$REPORT_CONTENT" > "$report_file"
    log "${GREEN}报告已生成 ($(echo "$REPORT_CONTENT" | wc -c) 字节)${NC}"
else
    log "${RED}生成器不存在: $GENERATOR${NC}"
    echo "# 每日工作汇报 $DATE\n\n_报告生成失败_" > "$report_file"
fi

# ================================================
# 第二步: 同步至 Memos
# ================================================
log "${YELLOW}--- 同步至 Memos ---${NC}"

if [[ -x "$GENERATOR" ]]; then
    SYNC_RESULT=$("$GENERATOR" "$DATE" "sync" 2>&1)
    if echo "$SYNC_RESULT" | grep -q "✅"; then
        MEMO_UID=$(echo "$SYNC_RESULT" | grep -o 'UID: [^ ]*' | awk '{print $2}')
        log "${GREEN}已同步至 Memos (UID: $MEMO_UID)${NC}"
    else
        log "${RED}Memos 同步失败: $SYNC_RESULT${NC}"
    fi
fi

# ================================================
# 第三步: 备份 Oracle Cloud 配置文件
# ================================================
log "${YELLOW}--- 备份配置文件 ---${NC}"

for entry in $INSTANCES; do
    name="${entry%%:*}"; ip="${entry##*:}"
    instance_backup_dir="$BACKUP_DIR/$name"
    mkdir -p "$instance_backup_dir"

    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
        $SSH_USER@$ip "echo OK" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        log "  备份 $name..."
        if [[ "$name" == AMD-* ]]; then
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip "sudo tar czf - /etc/nginx /etc/systemd /opt 2>/dev/null | base64" \
                > "$instance_backup_dir/configs.tar.gz.b64" 2>&1
            size=$(wc -c < "$instance_backup_dir/configs.tar.gz.b64")
            log "  $name: 备份完成 ($size bytes)"
        elif [[ "$name" == ARM ]]; then
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT \
                $SSH_USER@$ip "sudo tar czf - /home/ubuntu/docker 2>/dev/null | base64" \
                > "$instance_backup_dir/docker_config.tar.gz.b64" 2>&1
            size=$(wc -c < "$instance_backup_dir/docker_config.tar.gz.b64")
            log "  $name: 备份完成 ($size bytes)"
        fi
    else
        log "  $name: SSH 连接失败"
    fi
done

# ================================================
# 完成
# ================================================
log "${GREEN}========== 每日汇报完成 $(date '+%Y-%m-%d %H:%M') ==========${NC}"
log "📄 报告: $report_file"
log "📦 备份: $BACKUP_DIR"
