#!/bin/bash
#===============================================================================
# Freedom 项目 - 自动化推广脚本
# 
# 用途: 自动在社交媒体推广 AI Agent Starter Kit
# 支持: 微博/小红书/即刻/微信群
# 
# 使用: 添加到 crontab 自动执行
# 例: 每天早上 9 点推广
# crontab -e
# 0 9 * * * /path/to/autopromote.sh
#===============================================================================

set -e

# 配置
PRODUCT_NAME="AI Agent Starter Kit"
PRODUCT_LINK="${GUMROAD_LINK:-'[你的链接]'}"  # 设置后自动替换
PRICE="¥9.9"
HASHTAGS="#AI #OpenClaw #效率工具 #自动化 #AI助手"

# 内容库
declare -a POSTS

# 帖子1: 直接推广
POSTS[0]="🤖 $PRICE 解决 2 小时配置问题！

刚整理完我的 AI Agent 启动工具包，包含：
✅ 一键配置脚本
✅ 每日简报生成器
✅ 社交媒体内容工具
✅ 完整使用文档

5 分钟完成配置，不用折腾。
👇 $PRODUCT_LINK

$HASHTAGS"

# 帖子2: 解决问题型
POSTS[1]="为什么你的 AI Agent 总配不好？

90% 的人卡在这：
❌ 不知道装什么
❌ 不知道怎么配
❌ 配完不知道咋用

我做了一个工具包，5 分钟搞定。
¥9.9，节省 2 小时。
👉 $PRODUCT_LINK

#AI #OpenClaw #工具"

# 帖子3: 案例型
POSTS[2]="用这个工具包，我每天多出 1 小时

配置好 AI Agent 后：
📧 邮件自动处理
📅 日程自动提醒
📝 内容自动生成

工具包 ¥9.9，点此获取 👇
$PRODUCT_LINK

#效率 #AI #时间管理"

# 帖子4: 教程型
POSTS[4]="手把手教你在 5 分钟内搭建 AI 助手

1. 下载工具包
2. 运行配置脚本
3. 输入 API Key
4. 完成！

工具包 ¥9.9:
$PRODUCT_LINK

#AI助手 #教程 #OpenClaw"

# 帖子5: 轻量推广
POSTS[3]="分享一个省时间的工具
AI Agent 启动工具包
¥9.9，5 分钟配置完成
👉 $PRODUCT_LINK

#AI #效率"

# 随机选择帖子
random_post() {
    INDEX=$((RANDOM % ${#POSTS[@]}))
    echo "${POSTS[$INDEX]}"
}

# 发送到微博 (需要配置)
send_weibo() {
    echo "准备发送到微博..."
    # TODO: 集成微博 API 或使用第三方工具
    echo "微博: 需要配置微博 API"
}

# 发送到小红书 (需要配置)
send_xiaohongshu() {
    echo "准备发送到小红书..."
    # TODO: 集成小红书 API
    echo "小红书: 需要配置小红书 API"
}

# 发送到即刻
send_jike() {
    echo "准备发送到即刻..."
    # TODO: 集成即刻 API
    echo "即刻: 需要配置即刻 API"
}

# 发送到 Discord (如果有配置)
send_discord() {
    if [ -n "$DISCORD_WEBHOOK" ]; then
        echo "发送到 Discord..."
        curl -H "Content-Type: application/json" \
             -d "{\"content\":\"$(random_post)\"}" \
             "$DISCORD_WEBHOOK" 2>/dev/null
        echo "Discord: 已发送"
    fi
}

# 发送到 Telegram (如果有配置)
send_telegram() {
    if [ -n "$TELEGRAM_CHAT_ID" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        echo "发送到 Telegram..."
        curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
             -d "chat_id=$TELEGRAM_CHAT_ID" \
             -d "text=$(random_post)" \
             > /dev/null
        echo "Telegram: 已发送"
    fi
}

# 生成今日推广报告
generate_report() {
    echo ""
    echo "📊 推广报告 - $(date '+%Y-%m-%d %H:%M')"
    echo "================================"
    echo "产品: $PRODUCT_NAME"
    echo "价格: $PRICE"
    echo "链接: $PRODUCT_LINK"
    echo ""
    echo "推广状态:"
    echo "  - Discord: $([ -n "$DISCORD_WEBHOOK" ] && echo '✓ 已配置' || echo '✗ 未配置')"
    echo "  - Telegram: $([ -n "$TELEGRAM_BOT_TOKEN" ] && echo '✓ 已配置' || echo '✗ 未配置')"
    echo "  - 微博: ✗ 需要手动或 API"
    echo "  - 小红书: ✗ 需要手动或 API"
    echo ""
}

# 主程序
main() {
    echo "🚀 Freedom 自动推广"
    echo "==================="
    
    generate_report
    
    echo ""
    echo "今日推广内容:"
    echo "-------------"
    random_post
    echo "-------------"
    echo ""
    
    # 尝试发送到已配置的平台
    send_discord
    send_telegram
    
    echo ""
    echo "✅ 推广完成"
}

# 测试模式
test() {
    echo "🧪 测试模式"
    echo "==========="
    echo ""
    echo "推广内容预览:"
    echo "-------------"
    random_post
    echo "-------------"
}

# 帮助
help() {
    cat << EOF
Freedom 自动推广脚本

用法:
    $0           运行推广
    $0 test      测试模式
    $0 help      显示帮助

环境变量:
    GUMROAD_LINK     你的 Gumroad 产品链接
    DISCORD_WEBHOOK  Discord webhook URL
    TELEGRAM_BOT_TOKEN  Telegram Bot Token
    TELEGRAM_CHAT_ID    Telegram Chat ID

设置示例:
    export GUMROAD_LINK="https://yours.gumroad.com/l/xxxxx"
    export DISCORD_WEBHOOK="https://discord.com/api/webhooks/xxx"
    
Crontab 示例:
    0 9 * * * /path/to/autopromote.sh  # 每天早上9点
    0 12 * * * /path/to/autopromote.sh  # 中午12点
    0 18 * * * /path/to/autopromote.sh  # 下午6点

EOF
}

case "${1:-}" in
    test) test ;;
    help|--help|-h) help ;;
    *) main ;;
esac
