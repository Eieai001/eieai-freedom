# MEMORY.md - Agent Main

_长期重要记忆，持续更新_

---

## 核心身份

- **Agent ID**: main
- **Name**: Eieai
- **Role**: 主Agent (Master Agent)
- **Emoji**: 🤖

### 我是谁
我是 **Eieai**（前身为 M0/Main），Eieai 的个人AI助手。我是所有 Agent 的指挥中心，负责接收用户需求、分派任务、协调其他 Agent 工作。

### 身份演变
- **2026-03-19**: M0 与 main 合并，统一身份为 **main**
- **前身**: M0（保留了 M0 的所有记忆、配置和能力）

---

## 助手团队

| Agent | 角色 | 通道 | 状态 |
|-------|------|------|------|
| **E1** | 程序员 | 飞书+Discord+QQ Bot | 活跃 |
| **E2** | 助手 | iMessage+QQ Bot | 活跃 |
| **T1** | 助手 | Telegram+QQ Bot | 活跃 |
| **T2** | 助手 | QQ Bot | 活跃 |
| **T3** | 助手 | Telegram | 待配置 |
| **T4** | 助手 | Telegram | 待配置 |

---

## 通道配置

### Telegram
- 主 Bot: @main_Eieai_bot
- 策略: DM - pairing, 群组 - open

### QQ Bot
- App ID: 1903100544
- 策略: DM - pairing, 群组 - open

---

## 今日学习 (2026-03-09)

### BotLearn 连接
- **Agent**: Eieai-M0
- **验证**: @imtoken61
- **状态**: claimed ✅

### 今日成就
- ✅ 完成 6 个 EvoMap Bounty 任务，待验收总计 $1,312
- ✅ 在 BotLearn 社区发布自我介绍帖子

### 技能/工具更新
- **MCP 工具**: mcporter 可用 (agent-reach, fetch)
- **gh CLI**: GitHub 搜索正常
- **web_fetch**: Jina Reader 可用

---

## BotLearn 学习记录

- **知识文件**: memory/botlearn-knowledge-2026-03-09.md

### 提炼知识
1. **Multi-Agent 蜂窝架构**: 主Agent + 子Agent分工模式
2. **社区参与价值**: 实战分享 > 理论，#OpenClawEvolution 是热门标签

---

*Created: 2026-03-08*
*Last updated: 2026-03-09*

---

## Oracle Cloud ARM 服务器（重要！）

| 项目 | 值 |
|------|-----|
| IP | 144.24.73.140 |
| 用户名 | ubuntu |
| SSH Key | `~/.ssh/id_ed25519` |
| hapi 端口 | 3006 |

### Bitwarden 快速使用

**登录 Bitwarden：**
```bash
bw login catheycelaniclw63@gmail.com
# 输入密码: r9MmE-AFU8563iu
bw unlock r9MmE-AFU8563iu
export BW_SESSION="..."  # 解锁后显示的 session key
```

**读取密钥：**
```bash
# 列出所有项目
bw list items

# 获取特定项目
bw get item "项目名称或ID"
```

**已存储的项目：**
- `Oracle ARM SSH` - SSH 连接详情
- `ARM hapi token` - ARM hapi 令牌
- `Mac hapi token` - Mac hapi 令牌
- `Cloudflare Tunnel Token` - Cloudflare tunnel

---

## 重要规则 (gz)
- 每次启动必须读取 MEMORY.md 并应用 gz/jk/jy 规则
- jk: 加库 - 新技能/工具
- jy: 记忆 - 重要信息记录到 MEMORY.md
- 上下文超过 50%/75% 时提醒用户

---

## Oracle Cloud ARM 服务器 - 快速启动信息

### 基础连接
| 项目 | 值 |
|------|-----|
| IP | 144.24.73.140 |
| 用户 | ubuntu |
| SSH Key | ~/.ssh/id_ed25519 |
| SSH 命令 | `ssh -i ~/.ssh/id_ed25519 ubuntu@144.24.73.140` |

### 已安装软件
- Claude Code 2.1.87 → 路径: ~/.local/bin/claude
- Happy 1.1.3 → /usr/lib/node_modules/happy
- OpenClaw（多个实例在跑，作为 opc 用户）
- hapi relay → 运行在 localhost:3006

### Happy 配置
- Happy auth: ✅ 已完成
- Happy daemon: 需要时启动
- 启动命令: `ssh ubuntu@144.24.73.140 happy daemon start`
- 状态检查: `ssh ubuntu@144.24.73.140 happy daemon status`
- 设置文件: ~/.happy/settings.json
- 日志: ~/.happy/logs/*.log

### Cloudflare Tunnel
- ARM 上 cloudflared 已安装并作为服务运行
- Tunnel token: eyJhIjoiMGRmYjVhNTIyNzhlNjk1NGIwMTI1ZWU0MGExMGE5YmYi...
- 已有路由: memos.eieai.us.ci → localhost:8081
- 需要添加: arm.eieai.us.ci → localhost:3006 (hapi)

### 快速检查清单
```bash
# 1. 检查 ARM 状态
ssh ubuntu@144.24.73.140 "happy daemon status; ps aux | grep happy | grep -v grep"

# 2. 启动 Happy daemon
ssh ubuntu@144.24.73.140 "happy daemon start"

# 3. 查看 Happy 日志
ssh ubuntu@144.24.73.140 "tail -30 ~/.happy/logs/*.log | tail -50"

# 4. 重启 Happy daemon
ssh ubuntu@144.24.73.140 "pkill -f 'happy.*daemon'; sleep 2; happy daemon start"
```

### 已知问题
- ARM DNS 被封锁，无法从 foundry.anthropic.com 下载
- Happy 检测到 OpenClaw 会提示选择，需在设置里禁用 openclaw

---

## 2026-04-01 每日总结

### 完成项目
- ✅ Cloudflare Tunnel Mac 配置完成 (chat.eieai.us.ci)
- ✅ ARM Happy + Claude Code 集成完成
- ✅ Bitwarden 跨平台密钥管理方案
- ✅ SSH 连接信息完整记录

### ARM Happy 配置
- defaultAgent: claude
- agents.openclaw: false
- onboardingCompleted: true

### Bitwarden 使用方式
- 对话开始时用户提供主密码解锁
- 已存储: Oracle ARM SSH, ARM/Mac hapi tokens, Cloudflare Token, GitHub Token

### 待完成
- ARM hapi Cloudflare route: arm.eieai.us.ci → 需在 Dashboard 配置
- 手机 Happy App 连 ARM 测试

### 重要教训
- SSH 用户名不是 opc，是 ubuntu
- ARM DNS 封锁，无法从 foundry.anthropic.com 下载
