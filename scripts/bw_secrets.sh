#!/bin/bash
# Bitwarden Secrets Helper - 存取敏感信息
# 用法:
#   ./bw_secrets.sh save <name> <value>   # 保存到 Bitwarden vault
#   ./bw_secrets.sh get <name>           # 从 vault 获取值
#   ./bw_secrets.sh list                 # 列出所有已存项目

set -euo pipefail

BW_SESSION="${BW_SESSION:-}"
TOKEN="memos_pat_SNWmx8pERXcFPZVdQcDtGnatmUZ18Yq0"

# 确保已登录
check_auth() {
    if [ -z "$BW_SESSION" ]; then
        echo "Error: BW_SESSION not set. Run: export BW_SESSION=\$(bw unlock --passwordenv BW_PASSWORD)"
        return 1
    fi
}

cmd="${1:-}"
case "$cmd" in
    save)
        name="$2"
        value="$3"
        if [ -z "$name" ] || [ -z "$value" ]; then
            echo "用法: $0 save <name> <value>"
            exit 1
        fi
        check_auth || exit 1
        ITEM=$(bw get item "$name" --session "$BW_SESSION" 2>/dev/null || echo "")
        if [ -n "$ITEM" ]; then
            bw edit item "$name" --session "$BW_SESSION" <<< '{"name":"'"$name"'","notes":"'"$value"'"}' 2>/dev/null || \
            echo "[WARNING] Update failed, item may exist"
        else
            echo "[]" | bw create item --session "$BW_SESSION" --name "$name" --notes "$value" 2>/dev/null || \
            echo "[WARNING] Create failed"
        fi
        echo "Saved: $name"
        ;;
    get)
        name="$2"
        if [ -z "$name" ]; then
            echo "用法: $0 get <name>"
            exit 1
        fi
        check_auth || exit 1
        bw get item "$name" --session "$BW_SESSION" 2>/dev/null | jq -r '.notes' || echo "[ERROR] Not found"
        ;;
    list)
        check_auth || exit 1
        bw list items --session "$BW_SESSION" 2>/dev/null | jq -r '.[].name' | grep -v "Previous Unlock" || echo "No items"
        ;;
    *)
        echo "用法:"
        echo "  $0 save <name> <value>   # 保存秘密"
        echo "  $0 get <name>            # 获取秘密"
        echo "  $0 list                  # 列出所有"
        echo ""
        echo "需要先设置: export BW_SESSION=\$(bw unlock)"
        ;;
esac
