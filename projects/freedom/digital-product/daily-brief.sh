#!/bin/bash
#===============================================================================
# 每日简报生成器 - AI Agent Starter Kit
#===============================================================================

CONFIG_FILE="${HOME}/.openclaw/brief-config.txt"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📰 AI Agent 每日简报${NC}"
echo "=================="

# 获取日期
DATE=$(date +"%Y年%m月%d日 %A")
echo -e "\n📅 $DATE\n"

# 天气 (使用 wttr.in)
echo -e "${GREEN}🌤️ 今日天气${NC}"
WEATHER=$(curl -s "wttr.in/Shanghai?format=3" 2>/dev/null || echo "无法获取")
echo " $WEATHER"
echo ""

# 科技新闻 (使用 Hacker News API)
echo -e "${GREEN}📰 科技新闻 (HN Top 5)${NC}"
NEWS=$(curl -s "https://hn.algolia.com/api/v1/search?query=AI&tags=story&hitsPerPage=5" 2>/dev/null | \
    jq -r '.hits[:5] | to_entries | .[] | "\(.key + 1). \(.value.title)"' 2>/dev/null || echo "无法获取新闻")
echo "$NEWS"
echo ""

# AI Tip
echo -e "${GREEN}💡 AI 技巧${NC}"
TIPS=(
    "用 /model 命令切换不同的 AI 模型"
    "在 SOUL.md 中定义你的 AI 个性和专长"
    "用 cron 设置每日自动任务"
    "安装 skill: openclaw skills install <name>"
    "查看所有命令: openclaw help"
)
RANDOM_TIP=${TIPS[$RANDOM % ${#TIPS[@]}]}
echo " $RANDOM_TIP"
echo ""

# 系统状态
echo -e "${GREEN}🤖 Agent 状态${NC}"
if pgrep -f "openclaw" > /dev/null; then
    echo " ✓ OpenClaw 运行中"
else
    echo " ✗ OpenClaw 未运行"
    echo "   运行: ~/.openclaw/start-agent.sh"
fi

echo ""
echo "=================="
echo "简报生成完成: $(date +%H:%M)"
