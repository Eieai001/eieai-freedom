#!/bin/bash
# Memos 同步脚本 - 通过 ARM SSH 直写数据库
# 用法:
#   ./memos_db_sync.sh update <memo_id> "<content>"   # 更新备忘录
#   ./memos_db_sync.sh read <memo_id>                # 读取备忘录内容

ARM_IP="144.24.73.140"
SSH_KEY="~/.ssh/id_ed25519"
DB="~/.memos/memos_dev.db"

cmd="${1:-}"
memo_id="${2:-}"

if [ -z "$cmd" ]; then
    echo "用法:"
    echo "  $0 update <memo_id> <content>   # 更新备忘录"
    echo "  $0 read <memo_id>              # 读取备忘录"
    exit 1
fi

case "$cmd" in
    update)
        content="$3"
        if [ -z "$content" ]; then
            echo "用法: $0 update <memo_id> <content>"
            exit 1
        fi
        # Escape single quotes for SQL
        safe_content="${content//\'/\'\'}"
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$ARM_IP \
            "sqlite3 $DB \\\"UPDATE memo SET content = '\$safe_content', updated_ts = strftime('%s', 'now') WHERE id = $memo_id; SELECT 'Updated ID ' || $memo_id || ': ' || substr(content, 1, 80) || '...' FROM memo WHERE id = $memo_id;\\\""
        ;;
    read)
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$ARM_IP \
            "sqlite3 $DB 'SELECT substr(content, 1, 200) FROM memo WHERE id = $memo_id'"
        ;;
    *)
        echo "未知命令: $cmd"
        exit 1
        ;;
esac
