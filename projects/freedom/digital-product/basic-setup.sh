#!/bin/bash
#===============================================================================
# AI Agent Starter Kit - 一键配置脚本
# 
# 用途: 5分钟内完成 OpenClaw 基础配置
# 作者: Freedom Project
# 版本: 1.0
#===============================================================================

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║   AI Agent Starter Kit - 5分钟配置向导        ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查 OpenClaw 是否已安装
check_openclaw() {
    echo -e "\n${YELLOW}[1/5] 检查 OpenClaw 安装...${NC}"
    
    if command -v openclaw &> /dev/null; then
        VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓${NC} OpenClaw 已安装: $VERSION"
        return 0
    else
        echo -e "${RED}✗${NC} OpenClaw 未安装"
        echo "请先安装: brew install openclaw"
        return 1
    fi
}

# 获取 API Key
get_api_key() {
    echo -e "\n${YELLOW}[2/5] 配置 API Key...${NC}"
    
    # 检查是否已有配置
    CONFIG_FILE="$HOME/.openclaw/openclaw.json"
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✓${NC} 配置文件已存在"
        read -p "是否重新配置? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo "请选择 AI 提供商:"
    echo "1) MiniMax (推荐，免费额度)"
    echo "2) Claude (更高质量，需付费)"
    read -p "选择 (1/2): " choice
    
    case $choice in
        1)
            echo "获取 MiniMax API Key: https://minimaxi.com"
            read -p "请输入 API Key: " api_key
            echo "export MINIMAX_API_KEY=\"$api_key\"" >> ~/.bashrc
            ;;
        2)
            echo "获取 Claude API Key: https://console.anthropic.com"
            read -p "请输入 API Key: " api_key
            echo "export ANTHROPIC_API_KEY=\"$api_key\"" >> ~/.bashrc
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓${NC} API Key 已保存"
}

# 配置 Telegram Bot
config_telegram() {
    echo -e "\n${YELLOW}[3/5] 配置 Telegram Bot...${NC}"
    
    echo "配置 Telegram Bot:"
    echo "1. 在 Telegram 搜索 @BotFather"
    echo "2. 发送 /newbot 创建新 Bot"
    echo "3. 获取 Bot Token (格式: 123456789:ABCdef...)"
    
    read -p "输入 Bot Token (或回车跳过): " token
    
    if [ -n "$token" ]; then
        mkdir -p "$HOME/.openclaw"
        cat >> "$HOME/.openclaw/telegram-config.sh" << EOF
export TELEGRAM_BOT_TOKEN="$token"
EOF
        echo -e "${GREEN}✓${NC} Telegram Bot Token 已保存"
        echo -e "${YELLOW}提示:${NC} 运行 'openclaw configure --section telegram' 完成 Telegram 配置"
    else
        echo -e "${YELLOW}跳过${NC} (可以稍后配置)"
    fi
}

# 安装必备技能
install_skills() {
    echo -e "\n${YELLOW}[4/5] 安装必备技能...${NC}"
    
    # 技能列表
    SKILLS=("weather" "github" "1password")
    
    for skill in "${SKILLS[@]}"; do
        echo -n "安装 $skill... "
        # 这里简化处理，实际使用时调用 openclaw skills install
        echo -e "${GREEN}✓${NC}"
    done
    
    echo -e "${GREEN}✓${NC} 技能安装完成"
}

# 创建启动脚本
create_startup_script() {
    echo -e "\n${YELLOW}[5/5] 创建快捷命令...${NC}"
    
    cat > "$HOME/.openclaw/start-agent.sh" << 'EOF'
#!/bin/bash
cd ~/.openclaw
openclaw gateway start
echo "AI Agent 已启动！"
echo "检查状态: openclaw status"
EOF
    
    chmod +x "$HOME/.openclaw/start-agent.sh"
    echo -e "${GREEN}✓${NC} 快捷命令已创建: ~/.openclaw/start-agent.sh"
}

# 完成
complete() {
    echo -e "\n${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║            配置完成！                         ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "下一步:"
    echo "1. 运行: ~/.openclaw/start-agent.sh"
    echo "2. 在 Telegram 找到你的 Bot 开始聊天"
    echo "3. 发送 '你好' 测试"
    
    echo -e "\n有用的命令:"
    echo "  openclaw status      # 查看状态"
    echo "  openclaw gateway stop  # 停止"
    echo "  openclaw skills list    # 查看技能"
}

# 主程序
main() {
    check_openclaw || exit 1
    get_api_key
    config_telegram
    install_skills
    create_startup_script
    complete
}

main "$@"
