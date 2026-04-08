# MEMORY.md - Agent Main

_长期重要记忆，持续更新_

---

## 核心身份

- **Agent ID**: main
- **Name**: Eieai
- **Role**: 主Agent (Master Agent)
- **Emoji**: 🤖

### 我是谁
我是 **Eieai**，Eieai 的个人AI助手（Agent ID: main）。我是所有 Agent 的指挥中心，负责接收用户需求、分派任务、协调其他 Agent 工作。

### 身份说明
- **main**（workspace: workspace-main）= 我
- **m0**（workspace: workspace-m0）= 另一个独立 Agent，与 main 是并列关系，非前身

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

## Oracle Cloud AMD 梯子服务器

### 实例信息（2026-03-31确认）
| 名称 | 公网IP | 形状 | 订阅端口 |
|------|--------|------|----------|
| AMD-1 | 158.179.175.145 | E2.1.Micro | :2080/sub |
| AMD-2 | 158.179.170.192 | E2.1.Micro | :2080/sub |
| ARM-4C24G | 144.24.73.140 | A1.Flex | - |

### 订阅链接
- `http://158.179.175.145:2080/sub`

### 检查命令
```bash
ssh ubuntu@158.179.175.145 "sudo systemctl status sing-box"
ssh ubuntu@158.179.175.145 "sudo ss -tlnp | grep -E '2080|33899|33900|8443'"
ssh ubuntu@158.179.175.145 "sudo journalctl -u sing-box -n 30 --no-pager"
```

### 已知问题
- AMD-2 有 hmac mismatch 错误（密码/Token不匹配）
- 手机端连接不稳定（Oracle 韩国机房对移动网络）

### ⚠️ OCI安全组是替换模式
更新时要包含所有规则，否则SSH规则会被冲掉。

---

## Oracle Cloud ARM 服务器（重要！）

| 项目 | 值 |
|------|-----|
| IP | <oracle-arm-ip> |
| 用户名 | ubuntu |
| SSH Key | `<oracle-arm-ssh-key-path>` |
| hapi 端口 | 3006 |

### Bitwarden 快速使用

**登录 Bitwarden：**
```bash
bw login
bw unlock
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
| IP | <oracle-arm-ip> |
| 用户 | ubuntu |
| SSH Key | <oracle-arm-ssh-key-path> |
| SSH 命令 | `ssh -i <oracle-arm-ssh-key-path> ubuntu@<oracle-arm-ip>` |

### 已安装软件
- Claude Code 2.1.87 → 路径: ~/.local/bin/claude
- Happy 1.1.3 → /usr/lib/node_modules/happy
- OpenClaw（多个实例在跑，作为 opc 用户）
- hapi relay → 运行在 localhost:3006

### Happy 配置
- Happy auth: ✅ 已完成
- Happy daemon: 需要时启动
- 启动命令: `ssh ubuntu@<oracle-arm-ip> happy daemon start`
- 状态检查: `ssh ubuntu@<oracle-arm-ip> happy daemon status`
- 设置文件: ~/.happy/settings.json
- 日志: ~/.happy/logs/*.log

### Cloudflare Tunnel
- ARM 上 cloudflared 已安装并作为服务运行
- Tunnel token: [stored-in-bitwarden-cloudflare-tunnel-token]
- 已有路由: memos.eieai.us.ci → localhost:8081
- 需要添加: arm.eieai.us.ci → localhost:3006 (hapi)

### 快速检查清单
```bash
# 1. 检查 ARM 状态
ssh ubuntu@<oracle-arm-ip> "happy daemon status; ps aux | grep happy | grep -v grep"

# 2. 启动 Happy daemon
ssh ubuntu@<oracle-arm-ip> "happy daemon start"

# 3. 查看 Happy 日志
ssh ubuntu@<oracle-arm-ip> "tail -30 ~/.happy/logs/*.log | tail -50"

# 4. 重启 Happy daemon
ssh ubuntu@<oracle-arm-ip> "pkill -f 'happy.*daemon'; sleep 2; happy daemon start"
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

---

## 持续未解决问题 (jy)
- ARM Bitwarden 解锁问题
- EvoMap 注册（已注册但未完成验证）
- Telegram groupPolicy="open" 安全配置（待修复）

## 最近探索的技能 (jk)
- session-logs: jq 搜索历史会话，`~/.openclaw/agents/main/sessions/`
- skill-creator: SKILL.md 三级加载系统，初始化脚本 `scripts/init_skill.py`
- find-skills: 技能发现与安装
- video-frames: ffmpeg 抽帧工具

---

*Last updated: 2026-04-05*
