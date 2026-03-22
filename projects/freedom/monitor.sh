#!/bin/bash
# Freedom 项目 - 资产/收入监控脚本
# 用途: 自动追踪多个收入来源和资产状态

echo "📊 Freedom 项目 - 资产监控"
echo "=============================="
echo ""

# 1. OpenClaw 状态
echo "🤖 OpenClaw 状态"
openclaw status 2>/dev/null | head -5 || echo "• OpenClaw 运行中"
echo ""

# 2. GitHub Stars (如果关联了 repo)
echo "⭐ GitHub 统计"
gh api repos --paginate 2>/dev/null | jq -s '.[0] | {stars: [.[] | select(.stargazer_count > 0) | {name: .full_name, stars: .stargazer_count}] | sort_by(.stars) | reverse | .[0:5]}' 2>/dev/null || echo "• 无公开仓库数据"
echo ""

# 3. Cron 任务状态
echo "⏰ 定时任务"
crontab -l 2>/dev/null | grep -E "openclaw|cron" | head -5 || echo "• 无活跃定时任务"
echo ""

# 4. 磁盘空间 (资源状态)
echo "💾 资源状态"
df -h / | tail -1 | awk '{print "• 磁盘: " $5 " 使用 (" $3 "/" $2 ")"}'
echo ""

echo "=============================="
echo "监控完成: $(date '+%Y-%m-%d %H:%M:%S')"
