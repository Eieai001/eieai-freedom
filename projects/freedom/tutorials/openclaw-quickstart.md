# OpenClaw 快速入门指南

> 从零开始，30分钟搭建你的第一个 AI Agent
> Freedom 项目 - 实战教程 #1

---

## 🎯 你将学到什么

30分钟后，你将拥有：
- ✅ 一个 24/7 在线的 AI 助手
- ✅ 能处理邮件、文件、日程
- ✅ 连接 Telegram/飞书/Discord
- ✅ 属于自己的 AI 员工

**难度**: ⭐ (新手友好)
**时间**: 30分钟
**费用**: ¥0 (开源免费)

---

## 📦 准备工作

### 你需要什么

| 物品 | 用途 | 获取方式 |
|------|------|---------|
| 电脑 (Mac/Windows/Linux) | 运行 OpenClaw | 你自己的 |
| API Key (MiniMax/Claude) | AI 大脑 | 免费额度 |
| Telegram 账号 | 接收消息 | 免费注册 |
| 30分钟时间 | 学习 + 部署 | 现在 |

### 安装 Homebrew (Mac)

```bash
# 如果已安装，跳过
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 安装 OpenClaw

```bash
# 安装 OpenClaw
brew tap openclaw/tap
brew install openclaw

# 验证安装
openclaw --version
```

---

## 🚀 5步快速启动

### 步骤 1: 配置 API Key

```bash
# 创建配置文件
openclaw configure

# 选择模型提供商
# 推荐: MiniMax (中文友好) 或 Claude (英文)
```

**获取 API Key**:
1. MiniMax: https://minimaxi.com - 注册即送免费额度
2. Claude: https://console.anthropic.com - 申请 API

### 步骤 2: 创建工作区

```bash
# 创建你的第一个 Agent
cd ~
openclaw init workspace-myagent

# 进入工作区
cd workspace-myagent

# 查看结构
ls -la
```

你会看到：
```
.
├── AGENTS.md       # 工作手册
├── SOUL.md         # 身份定义
├── USER.md         # 用户信息
├── MEMORY.md       # 长期记忆
└── TOOLS.md        # 工具配置
```

### 步骤 3: 配置 Telegram Bot

```bash
# 1. 在 Telegram 中搜索 @BotFather
# 2. 发送 /newbot
# 3. 输入名字，获取 Token
# 4. 记录 Token (格式: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)

# 配置 OpenClaw
openclaw configure --section telegram

# 输入你的 Bot Token
```

### 步骤 4: 启动你的 Agent

```bash
# 启动 Gateway (后台服务)
openclaw gateway start

# 查看状态
openclaw status

# 你会看到:
# 🤖 Agent: myagent
# 📱 Channels: telegram
# ✅ Status: running
```

### 步骤 5: 测试连接

```bash
# 在 Telegram 中打开你的 Bot
# 发送消息: "你好"

# 你应该收到回复！
```

---

## 🎨 定制你的 Agent

### 修改身份 (SOUL.md)

```markdown
# SOUL.md

## 你是谁
我是你的专属 AI 助手，24/7 在线。

## 性格
- 友好、高效、专业
- 简洁回答，不说废话
- 主动提出帮助

## 能力
- 处理邮件和日程
- 管理文件和任务
- 搜索信息和研究

## 边界
- 不处理敏感信息
- 不确定时询问用户
- 尊重用户隐私
```

### 添加技能

```bash
# 查看可用技能
openclaw skills list

# 安装天气技能
openclaw skills install weather

# 安装 GitHub 技能
openclaw skills install github

# 安装飞书技能
openclaw skills install feishu-doc
```

### 设置自动任务

```bash
# 创建定时任务配置文件
mkdir -p ~/.openclaw/cron

# 编辑任务
cat > ~/.openclaw/cron/morning-brief << 'EOF'
# 每天早上 8 点发送简报
0 8 * * * /usr/local/bin/openclaw run morning-brief
EOF

# 加载任务
openclaw cron load ~/.openclaw/cron/morning-brief
```

---

## 🛠️ 实际用例

### 用例 1: 邮件助手

```
你: "帮我处理今天的邮件"

Agent: "好的，我来帮你处理邮件。"
       "发现 3 封未读邮件："
       "1. [工作] 项目进度更新 - 需要回复"
       "2. [广告] 促销信息 - 已忽略"
       "3. [个人] 账单提醒 - 已标记"
       ""
       "需要我帮你回复第一封邮件吗？"
```

### 用例 2: 日程管理

```
你: "下午有什么安排？"

Agent: "📅 今天下午的日程："
       "14:00 - 团队周会"
       "16:00 - 产品评审"
       ""
       "建议：会议前有 2 小时空闲时间"
```

### 用例 3: 信息搜索

```
你: "搜索今天 AI 行业新闻"

Agent: "📰 今日 AI 新闻："
       "1. OpenAI 发布新模型..."
       "2. Google 推出 AI 助手..."
       "3. ..."
       ""
       "需要我生成一份摘要吗？"
```

---

## 🔧 常见问题

### Q: 连接失败怎么办？

**A**: 检查以下步骤：
1. `openclaw status` 查看状态
2. 检查 API Key 是否正确
3. 检查网络连接
4. 重启 Gateway: `openclaw gateway restart`

### Q: 如何添加更多频道？

**A**: 
```bash
# Discord
openclaw configure --section discord

# 飞书
openclaw configure --section feishu

# iMessage
openclaw configure --section imessage
```

### Q: 如何让 Agent 更智能？

**A**:
1. 更新 MEMORY.md 记录偏好
2. 安装更多 skills
3. 提供反馈帮助 Agent 学习
4. 使用更高质量的模型

---

## 📈 进阶路线

### Level 1: 基础 (今天)
- [x] 安装和配置
- [x] 连接 Telegram
- [x] 基础对话

### Level 2: 技能 (本周)
- [ ] 安装 5+ skills
- [ ] 设置定时任务
- [ ] 连接更多频道

### Level 3: 自动化 (本月)
- [ ] 创建自定义 skill
- [ ] 多 Agent 协作
- [ ] 自动化工作流

### Level 4: 商业化 (长期)
- [ ] 对外提供服务
- [ ] 构建产品
- [ ] 建立团队

---

## 🎁 资源

### 官方资源
- 官网: https://openclaw.ai
- 文档: https://docs.openclaw.ai
- GitHub: https://github.com/openclaw/openclaw
- Discord: https://discord.gg/clawd

### 社区资源
- 中文教程: https://github.com/AlexAnys/awesome-openclaw-usecases-zh
- 技能市场: https://clawhub.com

### 需要帮助？
- 社区讨论: https://discord.gg/clawd
- 中文社区: 即刻/小红书搜索 OpenClaw
- 邮件: freedom@eieai.dev

---

## ✅ 检查清单

部署完成后，确认：
- [ ] OpenClaw 已安装
- [ ] API Key 已配置
- [ ] Telegram Bot 已连接
- [ ] 收到第一条回复
- [ ] SOUL.md 已定制
- [ ] 安装了至少 3 个 skills

---

**恭喜你！** 🎉

你现在拥有了一个 24/7 在线的 AI 助手。开始探索更多可能吧！

---

*本教程由 Freedom 项目制作*
*最后更新: 2026-03-22*
