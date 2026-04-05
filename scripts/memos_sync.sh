#!/bin/bash
# Memos API 同步脚本 - 直接通过 HTTPS API 更新 Memos
# 用法:
#   ./memos_sync.sh update <memo_uid> "<content>"    # 更新备忘录
#   ./memos_sync.sh create "<content>"               # 创建新备忘录
#   ./memos_sync.sh read <memo_uid>                 # 读取备忘录
#
# 注意: 需要设置 MEMOS_PAT 环境变量或在 ~/.bw_secrets 中存储

MEMOS_PAT="${MEMOS_PAT:-}"
if [ -z "$MEMOS_PAT" ]; then
    # 尝试从 secrets 文件读取
    SECRETS_FILE="$HOME/.openclaw/workspace-main/scripts/.memos_secrets"
    if [ -f "$SECRETS_FILE" ]; then
        MEMOS_PAT=$(cat "$SECRETS_FILE" 2>/dev/null | grep -v '^#' | grep 'memos_pat' | head -1)
    fi
fi

if [ -z "$MEMOS_PAT" ]; then
    echo "Error: MEMOS_PAT not set and not found in secrets file"
    exit 1
fi

BASE_URL="https://memos.eieai.us.ci/api/v1"

cmd="${1:-}"
shift || true

case "$cmd" in
    update)
        memo_uid="$1"
        content="$2"
        if [ -z "$memo_uid" ] || [ -z "$content" ]; then
            echo "用法: $0 update <memo_uid> <content>"
            exit 1
        fi
        response=$(curl -s -X PATCH "${BASE_URL}/memos/${memo_uid}" \
            -H "Authorization: Bearer $MEMOS_PAT" \
            -H "Content-Type: application/json" \
            --noproxy '*' \
            -d "{\"content\":\"$content\",\"visibility\":\"PRIVATE\"}")
        if echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'name' in d else 1)" 2>/dev/null; then
            echo "✅ Updated memo ${memo_uid}"
        else
            echo "❌ Update failed: $(echo $response | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("message","?"))' 2>/dev/null)"
        fi
        ;;
    create)
        content="$1"
        if [ -z "$content" ]; then
            echo "用法: $0 create <content>"
            exit 1
        fi
        response=$(curl -s -X POST "${BASE_URL}/memos" \
            -H "Authorization: Bearer $MEMOS_PAT" \
            -H "Content-Type: application/json" \
            --noproxy '*' \
            -d "{\"content\":\"$content\",\"visibility\":\"PRIVATE\"}")
        if echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'name' in d else 1)" 2>/dev/null; then
            uid=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name','?').replace('memos/',''))" 2>/dev/null)
            echo "✅ Created memo: $uid"
        else
            echo "❌ Create failed: $(echo $response | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("message","?"))' 2>/dev/null)"
        fi
        ;;
    read)
        memo_uid="$1"
        if [ -z "$memo_uid" ]; then
            echo "用法: $0 read <memo_uid>"
            exit 1
        fi
        curl -s "${BASE_URL}/memos?creatorId=1" \
            -H "Authorization: Bearer $MEMOS_PAT" \
            --noproxy '*' | python3 -c "
import sys,json
d=json.load(sys.stdin)
for m in d.get('memos',[]):
    if '$memo_uid' in m.get('name',''):
        print(m.get('content','')[:500])
        break
" 2>/dev/null
        ;;
    list)
        curl -s "${BASE_URL}/memos?creatorId=1" \
            -H "Authorization: Bearer $MEMOS_PAT" \
            --noproxy '*' | python3 -c "
import sys,json
d=json.load(sys.stdin)
for m in d.get('memos',[]):
    name=m.get('name','').replace('memos/','')
    preview=m.get('content','')[:50].replace('\n',' ')
    print(f'{name} | {preview}...')
" 2>/dev/null
        ;;
    *)
        echo "Memos API 同步脚本"
        echo ""
        echo "用法:"
        echo "  $0 update <uid> <content>   # 更新备忘录"
        echo "  $0 create <content>         # 创建新备忘录"
        echo "  $0 read <uid>              # 读取备忘录内容"
        echo "  $0 list                    # 列出所有备忘录"
        echo ""
        echo "环境变量: MEMOS_PAT"
        ;;
esac
