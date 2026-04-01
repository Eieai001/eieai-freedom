#!/bin/bash
#===============================================================================
# AI Agent 工具箱 - Freedom 项目
# 
# 用途: 为 OpenClaw Agent 提供实用工具集
# 
# 用法:
#   ./agent-toolkit.sh [command]
#
# 命令:
#   health      - 系统健康检查
#   backup      - 备份重要文件
#   stats       - 显示统计信息
#   clean       - 清理临时文件
#   monitor     - 资源监控
#   todo        - 待办事项管理
#   timer       - 计时器
#   weather     - 快速天气查询
#   news        - 科技新闻摘要
#===============================================================================

set -e

# 配置
AGENT_DIR="$HOME/.openclaw"
BACKUP_DIR="$AGENT_DIR/backups"
LOG_DIR="$AGENT_DIR/logs"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

#-------------------------------------------------------------------------------
# 命令: health
#-------------------------------------------------------------------------------
cmd_health() {
    echo ""
    echo "🤖 AI Agent 健康检查"
    echo "=============================="
    
    # OpenClaw 状态
    echo -n "OpenClaw: "
    if pgrep -f "openclaw" > /dev/null; then
        log_success "运行中"
    else
        log_error "未运行"
    fi
    
    # 磁盘空间
    echo -n "磁盘空间: "
    USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$USAGE" -lt 80 ]; then
        log_success "$(df -h / | tail -1 | awk '{print $5}')"
    else
        log_warning "$(df -h / | tail -1 | awk '{print $5}')"
    fi
    
    # 内存使用
    echo -n "内存使用: "
    MEMORY=$(memory_pressure | grep "Physical" | awk '{print $3}' || echo "未知")
    log_info "当前: ${MEMORY}"
    
    # Cron 任务
    echo -n "定时任务: "
    CRON_COUNT=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l | tr -d ' ')
    log_info "${CRON_COUNT} 个活跃任务"
    
    echo "=============================="
    echo ""
}

#-------------------------------------------------------------------------------
# 命令: backup
#-------------------------------------------------------------------------------
cmd_backup() {
    echo ""
    echo "📦 开始备份..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup_${TIMESTAMP}"
    
    mkdir -p "$BACKUP_PATH"
    
    # 备份配置文件
    if [ -f "$AGENT_DIR/openclaw.json" ]; then
        cp "$AGENT_DIR/openclaw.json" "$BACKUP_PATH/"
        log_success "配置文件"
    fi
    
    # 备份记忆文件
    if [ -d "$AGENT_DIR/workspace-main/memory" ]; then
        cp -r "$AGENT_DIR/workspace-main/memory" "$BACKUP_PATH/"
        log_success "记忆文件"
    fi
    
    # 备份 AGENTS.md 等关键文件
    for file in AGENTS.md SOUL.md MEMORY.md IDENTITY.md; do
        if [ -f "$AGENT_DIR/workspace-main/$file" ]; then
            cp "$AGENT_DIR/workspace-main/$file" "$BACKUP_PATH/"
            log_success "$file"
        fi
    done
    
    # 压缩备份
    cd "$BACKUP_DIR"
    tar -czf "backup_${TIMESTAMP}.tar.gz" "backup_${TIMESTAMP}" 2>/dev/null
    rm -rf "backup_${TIMESTAMP}"
    
    log_success "备份完成: $BACKUP_DIR/backup_${TIMESTAMP}.tar.gz"
    echo ""
}

#-------------------------------------------------------------------------------
# 命令: stats
#-------------------------------------------------------------------------------
cmd_stats() {
    echo ""
    echo "📊 Agent 统计信息"
    echo "=============================="
    
    # 会话数量
    if [ -d "$AGENT_DIR/agents/main/sessions" ]; then
        SESSION_COUNT=$(find "$AGENT_DIR/agents/main/sessions" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
        log_info "会话数量: $SESSION_COUNT"
    fi
    
    # 记忆文件
    if [ -d "$AGENT_DIR/workspace-main/memory" ]; then
        MEMORY_COUNT=$(find "$AGENT_DIR/workspace-main/memory" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        log_info "记忆文件: $MEMORY_COUNT 个"
    fi
    
    # 技能数量
    if [ -d "$AGENT_DIR/skills" ]; then
        SKILL_COUNT=$(find "$AGENT_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
        log_info "已安装技能: $SKILL_COUNT 个"
    fi
    
    # 项目数量
    if [ -d "$AGENT_DIR/workspace-main/projects" ]; then
        PROJECT_COUNT=$(find "$AGENT_DIR/workspace-main/projects" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        log_info "项目数量: $PROJECT_COUNT 个"
    fi
    
    # 最新活动
    echo ""
    echo "最近活动:"
    find "$AGENT_DIR" -name "*.md" -mtime -7 2>/dev/null | head -5 | while read f; do
        echo "  • $(basename $f)"
    done
    
    echo "=============================="
    echo ""
}

#-------------------------------------------------------------------------------
# 命令: clean
#-------------------------------------------------------------------------------
cmd_clean() {
    echo ""
    echo "🧹 清理临时文件..."
    
    # 清理日志
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null
        log_success "旧日志已清理"
    fi
    
    # 清理临时文件
    find /tmp -name "openclaw-*" -mtime +1 -delete 2>/dev/null
    log_success "临时文件已清理"
    
    # 清理缓存
    if [ -d "$AGENT_DIR/completions" ]; then
        find "$AGENT_DIR/completions" -type f -mtime +30 -delete 2>/dev/null
        log_success "旧缓存已清理"
    fi
    
    log_success "清理完成"
    echo ""
}

#-------------------------------------------------------------------------------
# 命令: monitor
#-------------------------------------------------------------------------------
cmd_monitor() {
    echo ""
    echo "📈 实时监控 (Ctrl+C 退出)"
    echo "=============================="
    
    while true; do
        clear
        echo "📊 $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # CPU
        echo -n "CPU: "
        top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'
        
        # 内存
        echo -n "内存: "
        vm_stat | grep "Pages active" | awk '{printf "%.1f%%\n", $3/1000000}'
        
        # 磁盘
        echo -n "磁盘: "
        df -h / | tail -1 | awk '{print $5}'
        
        # 网络
        echo -n "网络: "
        netstat -ib | grep -E "en0|eth0" | head -1 | awk '{print $7/1024/1024, "MB"}' 2>/dev/null || echo "N/A"
        
        # OpenClaw 进程
        if pgrep -f "openclaw" > /dev/null; then
            echo ""
            echo -e "${GREEN}✓${NC} OpenClaw 运行中"
        else
            echo ""
            echo -e "${RED}✗${NC} OpenClaw 未运行"
        fi
        
        sleep 5
    done
}

#-------------------------------------------------------------------------------
# 命令: todo
#-------------------------------------------------------------------------------
cmd_todo() {
    TODO_FILE="$AGENT_DIR/todo.md"
    
    if [ ! -f "$TODO_FILE" ]; then
        cat > "$TODO_FILE" << 'EOF'
# 待办事项

## 今天

## 本周

## 长期

EOF
    fi
    
    $EDITOR "${EDITOR:-nano}" "$TODO_FILE" 2>/dev/null || echo "请手动编辑: $TODO_FILE"
}

#-------------------------------------------------------------------------------
# 命令: timer
#-------------------------------------------------------------------------------
cmd_timer() {
    if [ -z "$1" ]; then
        echo "用法: $0 timer [分钟]"
        return 1
    fi
    
    MINUTES=$1
    SECONDS=$((MINUTES * 60))
    
    echo ""
    echo "⏱️  计时器: ${MINUTES} 分钟"
    echo "按 Ctrl+C 取消"
    echo ""
    
    while [ $SECONDS -gt 0 ]; do
        MINS=$((SECONDS / 60))
        SECS=$((SECONDS % 60))
        printf "\r  %02d:%02d  " $MINS $SECS
        sleep 1
        SECONDS=$((SECONDS - 1))
    done
    
    echo ""
    echo ""
    log_success "时间到！⏰"
    
    # 发送通知
    osascript -e 'display notification "计时器完成！" with title "Agent Toolkit"' 2>/dev/null || true
}

#-------------------------------------------------------------------------------
# 命令: weather
#-------------------------------------------------------------------------------
cmd_weather() {
    if [ -z "$1" ]; then
        CITY="Shanghai"
    else
        CITY="$1"
    fi
    
    curl -s "wttr.in/${CITY}?format=3" 2>/dev/null || echo "无法获取天气信息"
}

#-------------------------------------------------------------------------------
# 命令: news
#-------------------------------------------------------------------------------
cmd_news() {
    echo ""
    echo "📰 今日科技新闻"
    echo "=============================="
    
    # 使用 Hacker News API
    curl -s "https://hn.algolia.com/api/v1/search?query=AI&tags=story&hitsPerPage=5" 2>/dev/null | \
        jq -r '.hits[] | "• \(.title)\n  \(.url)\n"' 2>/dev/null || \
        echo "无法获取新闻"
    
    echo "=============================="
    echo ""
}

#-------------------------------------------------------------------------------
# 帮助信息
#-------------------------------------------------------------------------------
show_help() {
    cat << EOF
🤖 AI Agent 工具箱

用法:
    agent-toolkit.sh [command]

可用命令:
    health      系统健康检查
    backup      备份重要文件
    stats       显示统计信息
    clean       清理临时文件
    monitor     实时资源监控
    todo        待办事项管理
    timer       计时器 (需要分钟数)
    weather     快速天气查询
    news        科技新闻摘要
    help        显示此帮助信息

示例:
    agent-toolkit.sh health
    agent-toolkit.sh backup
    agent-toolkit.sh timer 25
    agent-toolkit.sh weather Beijing

EOF
}

#-------------------------------------------------------------------------------
# 主程序
#-------------------------------------------------------------------------------
case "${1:-help}" in
    health)    cmd_health ;;
    backup)    cmd_backup ;;
    stats)     cmd_stats ;;
    clean)     cmd_clean ;;
    monitor)   cmd_monitor ;;
    todo)      cmd_todo ;;
    timer)     cmd_timer "$2" ;;
    weather)   cmd_weather "$2" ;;
    news)      cmd_news ;;
    help)      show_help ;;
    *)         show_help ;;
esac
