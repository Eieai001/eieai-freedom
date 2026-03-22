#!/bin/bash
#===============================================================================
# Freedom 项目 - 每日内容生成器
# 自动生成社交媒体内容并推送到指定频道
#===============================================================================

CONFIG_FILE="$HOME/.openclaw/freedom-config.sh"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# 默认配置
CONTENT_DIR="${CONTENT_DIR:-$HOME/.openclaw/freedom-content}"
PLATFORMS="${PLATFORMS:-weibo,xiaohongshu,jike}"
AI_MODEL="${AI_MODEL:-minimax}"

mkdir -p "$CONTENT_DIR"

# 生成今日内容主题
generate_topics() {
    DATE=$(date +"%m月%d日")
    WEEKDAY=$(date +"%A")
    
    # 根据星期生成不同主题
    case $WEEKDAY in
        Monday)
            TOPIC="本周 AI 趋势"
            HASHTAG="#AI趋势 #周一干货"
            ;;
        Tuesday)
            TOPIC="OpenClaw 技巧"
            HASHTAG="#OpenClaw #技巧分享"
            ;;
        Wednesday)
            TOPIC="AI Agent 案例"
            HASHTAG="#AI案例 #实战分享"
            ;;
        Thursday)
            TOPIC="工具推荐"
            HASHTAG="#效率工具 #神器推荐"
            ;;
        Friday)
            TOPIC="本周总结"
            HASHTAG="#一周回顾 #AI周报"
            ;;
        Saturday|Sunday)
            TOPIC="轻松话题"
            HASHTAG="#AI生活 #周末话题"
            ;;
    esac
    
    echo "📅 $DATE 内容主题: $TOPIC"
    echo "   标签: $HASHTAG"
}

# 生成小红书内容
generate_xiaohongshu() {
    TOPIC="$1"
    
    cat > "$CONTENT_DIR/xiaohongshu-$(date +%Y%m%d).md" << EOF
---
平台: 小红书
日期: $(date +"%Y-%m-%d")
主题: $TOPIC
---

🎯 标题建议:
[数字] 个方法，让你 [获得收益] | 亲测有效！

📝 正文模板:

姐妹们！今天分享一个超实用的技巧 💡

[核心内容，3-5个要点]

✨ 要点1
✨ 要点2
✨ 要点3

💬 我的真实体验:
[个人经历，增加可信度]

❓ 你们有什么想问的？
评论区告诉我！

#OpenClaw #AI #效率 #自动化 #[其他标签]

📌 发布建议:
- 配图: 3-6张截图/示意图
- 发布时间: 18:00-21:00
- 互动: 发布后1小时内回复评论
---
EOF
    
    echo "✅ 小红书内容已生成: $CONTENT_DIR/xiaohongshu-$(date +%Y%m%d).md"
}

# 生成即刻内容
generate_jike() {
    TOPIC="$1"
    
    cat > "$CONTENT_DIR/jike-$(date +%Y%m%d).md" << EOF
---
平台: 即刻
日期: $(date +"%Y-%m-%d")
主题: $TOPIC
---

💡 今日分享

[核心观点，1-2句话]

[详细说明，3-5个要点]

💬 讨论:
[开放性问题]

#OpenClaw #AI #[相关话题]

---
EOF
    
    echo "✅ 即刻内容已生成: $CONTENT_DIR/jike-$(date +%Y%m%d).md"
}

# 生成微博内容
generate_weibo() {
    TOPIC="$1"
    
    cat > "$CONTENT_DIR/weibo-$(date +%Y%m%d).md" << EOF
---
平台: 微博
日期: $(date +"%Y-%m-%d")
主题: $TOPIC
---

🚀 [一句话标题]

[核心内容，100-200字]

👇 详细教程
[链接]

#OpenClaw# #AI# #效率# #自动化#

---
EOF
    
    echo "✅ 微博内容已生成: $CONTENT_DIR/weibo-$(date +%Y%m%d).md"
}

# 主函数
main() {
    echo ""
    echo "🎨 Freedom 内容生成器"
    echo "======================"
    echo ""
    
    # 生成主题
    TOPIC=$(generate_topics | head -1 | cut -d: -f2 | xargs)
    
    # 生成各平台内容
    generate_xiaohongshu "$TOPIC"
    generate_jike "$TOPIC"
    generate_weibo "$TOPIC"
    
    echo ""
    echo "======================"
    echo "📁 内容目录: $CONTENT_DIR"
    echo "✅ 生成完成！请编辑后发布。"
    echo ""
}

case "${1:-}" in
    --topic)
        generate_topics
        ;;
    --dir)
        echo "$CONTENT_DIR"
        ;;
    *)
        main
        ;;
esac
