# CLAUDE.md - Agent Main 行为规则

## 对话开始
1. 读取 MEMORY.md 和当前 CLAUDE.md
2. 应用 jy/jk 规则

## 对话结束（自动同步）
1. 检查本次新增的敏感信息 → 保存到 Bitwarden
2. 将 MEMORY.md 增量更新同步到 Memos

## 敏感信息自动处理

### 获取到新 token/key/密码
→ **立即**执行 `./scripts/bw_secrets.sh save <name> <value>`

### 需要使用已知密钥
→ 执行 `./scripts/bw_secrets.sh get <name>`

### Memos API 同步
```bash
# 关键: curl 必须加 --noproxy '*' 否则被本地代理拦截

# 更新备忘录
curl -s -X PATCH "https://memos.eieai.us.ci/api/v1/memos/<uid>" \
  -H "Authorization: Bearer $MEMOS_PAT" \
  -H "Content-Type: application/json" \
  --noproxy '*' \
  -d '{"content":"新内容","visibility":"PRIVATE"}'

# 创建备忘录
curl -s -X POST "https://memos.eieai.us.ci/api/v1/memos" \
  -H "Authorization: Bearer $MEMOS_PAT" \
  -H "Content-Type: application/json" \
  --noproxy '*' \
  -d '{"content":"内容","visibility":"PRIVATE"}'
```

### 同步脚本
```bash
./scripts/memos_sync.sh update <uid> "<content>"
./scripts/memos_sync.sh create "<content>"
./scripts/memos_sync.sh list
```

### Bitwarden 脚本
```bash
./scripts/bw_secrets.sh save <name> <value>
./scripts/bw_secrets.sh get <name>
./scripts/bw_secrets.sh list
```

### 敏感信息存储位置
- **Bitwarden**: tokens, API keys, SSH keys
- **Memos**: 脱敏后的记忆存档（用户角色、偏好、实例状态等）
- **记忆文件**: ~/.openclaw/workspace-main/MEMORY.md
