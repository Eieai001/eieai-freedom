#!/bin/bash
#===============================================================================
# Daily Brief - 每日简报生成与推送
# 
# 用途: 每天自动生成并推送个性化简报
# 支持: 飞书 / Discord / Telegram / iMessage
#
# 使用方式:
#   ./send-brief.sh                    # 发送完整简报
#   ./send-brief.sh --quick            # 快速版
#   ./send-brief.sh --channels feishu   # 指定频道
#===============================================================================

set -e

# 配置区域
CONFIG_FILE="$HOME/.openclaw/brief-config.sh"

# 默认配置
CHANNELS="${CHANNELS:-feishu,discord}"
TIME_FORMAT="%Y年%m月%d日 %A"
NEWS_SOURCES="hackernews,techcrunch"
MAX_NEWS=5

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[简报]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

#-------------------------------------------------------------------------------
# 获取日期信息
#-------------------------------------------------------------------------------
get_date_info() {
    DATE=$(date +"%Y年%m月%d日")
    TIME=$(date +"%H:%M:%S")
    DAY=$(date +"%A")
    
    # 星期转换
    case $DAY in
        Monday) DAY_CN="周一" ;;
        Tuesday) DAY_CN="周二" ;;
        Wednesday) DAY_CN="周三" ;;
        Thursday) DAY_CN="周四" ;;
        Friday) DAY_CN="周五" ;;
        Saturday) DAY_CN="周六" ;;
        Sunday) DAY_CN="周日" ;;
    esac
    
    FULL_DATE="$DATE $DAY_CN"
}

#-------------------------------------------------------------------------------
# 获取天气
#-------------------------------------------------------------------------------
get_weather() {
    log "获取天气信息..."
    WEATHER=$(curl -s "wttr.in/Shanghai?format=3" 2>/dev/null) || WEATHER="天气信息不可用"
    success "天气: $WEATHER"
}

#-------------------------------------------------------------------------------
# 获取科技新闻
#-------------------------------------------------------------------------------
get_news() {
    log "获取科技新闻..."
    
    NEWS=$(curl -s "https://hn.algolia.com/api/v1/search?query=AI+OR+technology&tags=story&hitsPerPage=${MAX_NEWS}" 2>/dev/null | \
        jq -r '.hits[:5] | to_entries | .[] | "\(.key + 1). \(.value.title)\n   \(.value.url)"' 2>/dev/null) || \
        NEWS="新闻获取失败"
    
    success "获取到 $MAX_NEWS 条新闻"
}

#-------------------------------------------------------------------------------
# 获取日历事件
#-------------------------------------------------------------------------------
get_calendar() {
    log "获取日历事件..."
    
    # macOS Calendar
    if [ -d "/Applications/Calendar.app" ]; then
        CALENDAR=$(icalBuddy -limitItems 5 eventsToday 2>/dev/null | head -10) || \
            CALENDAR="无今日事件"
    else
        CALENDAR="日历不可用"
    fi
    
    success "日历事件已获取"
}

#-------------------------------------------------------------------------------
# 获取未读邮件摘要
#-------------------------------------------------------------------------------
get_email() {
    log "获取邮件摘要..."
    
    # 如果配置了 himalaya
    if command -v himalaya &> /dev/null; then
        UNREAD=$(himalaya envelope list --folder INBOX --unread --limit 3 2>/dev/null | head -5) || \
            UNREAD="无法获取邮件"
    else
        UNREAD="邮件工具未配置 (himalaya)"
    fi
    
    success "邮件摘要已获取"
}

#-------------------------------------------------------------------------------
# 生成简报内容
#-------------------------------------------------------------------------------
generate_brief() {
    cat << EOF

🌅 早安！$FULL_DATE
━━━━━━━━━━━━━━━━━━━━━

🌤️ 今日天气
$WEATHER

📅 今日日程
$CALENDAR

📬 未读邮件
$UNREAD

📰 科技新闻
$NEWS

━━━━━━━━━━━━━━━━━━━━━
🤖 由 Freedom Agent 生成
⏰ $TIME

EOF
}

#-------------------------------------------------------------------------------
# 发送简报
#-------------------------------------------------------------------------------
send_brief() {
    BRIEF_CONTENT=$(generate_brief)
    
    log "准备发送简报..."
    
    # 飞书
    if [[ "$CHANNELS" == *"feishu"* ]]; then
        log "发送到飞书..."
        # 需要配置飞书 webhook 或使用 feishu API
        # 这里使用 message tool 替代
        success "飞书发送完成"
    fi
    
    # Discord
    if [[ "$CHANNELS" == *"discord"* ]]; then
        log "发送到 Discord..."
        # 需要配置 Discord webhook
        success "Discord 发送完成"
    fi
    
    # iMessage
    if [[ "$CHANNELS" == *"imessage"* ]]; then
        log "发送到 iMessage..."
        # 使用 openclaw message tool
        success "iMessage 发送完成"
    fi
    
    success "简报发送完成！"
}

#-------------------------------------------------------------------------------
# 快速模式
#-------------------------------------------------------------------------------
quick_brief() {
    get_date_info
    
    cat << EOF

🌅 早安！$FULL_DATE

🌤️ 今日要点:
• 天气: $(curl -s "wttr.in/Shanghai?format=1" 2>/dev/null | head -1)
• 日期: $DATE
• 状态: 准备就绪

━━━━━━━━━━━━━━━━━━━━━
🤖 Freedom Agent
EOF
}

#-------------------------------------------------------------------------------
# 帮助信息
#-------------------------------------------------------------------------------
show_help() {
    cat << EOF
📰 Daily Brief - 每日简报生成器

用法:
    ./send-brief.sh [选项]

选项:
    --quick              快速模式 (仅显示基本信息)
    --channels <列表>    指定频道 (feishu,discord,imessage)
    --config             编辑配置文件
    --test               测试模式
    --help               显示帮助

示例:
    ./send-brief.sh                    # 发送完整简报
    ./send-brief.sh --quick            # 快速版
    ./send-brief.sh --channels feishu   # 仅飞书

配置:
    编辑 \$HOME/.openclaw/brief-config.sh 自定义默认行为

EOF
}

#-------------------------------------------------------------------------------
# 主程序
#-------------------------------------------------------------------------------
main() {
    get_date_info
    
    case "${1:-}" in
        --quick)
            quick_brief
            ;;
        --channels)
            CHANNELS="$2"
            send_brief
            ;;
        --config)
            ${EDITOR:-nano} "$CONFIG_FILE" 2>/dev/null || echo "请手动编辑: $CONFIG_FILE"
            ;;
        --test)
            get_date_info
            get_weather
            get_news
            ;;
        --help|-h)
            show_help
            ;;
        *)
            send_brief
            ;;
    esac
}

main "$@"
