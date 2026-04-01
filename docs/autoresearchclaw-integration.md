# AutoResearchClaw × OpenClaw 集成指南

## 方案一：简单集成（推荐，5分钟）

### 步骤

```bash
# 1. 用户发送给 OpenClaw
"@m0 帮我集成 AutoResearchClaw
GitHub: https://github.com/aiming-lab/AutoResearchClaw
用途：自动化研究论文生成"

# 2. OpenClaw (M0) 自动执行
```

### OpenClaw 自动处理流程

| 步骤 | OpenClaw 动作 | 说明 |
|------|--------------|------|
| 1 | 读取 `RESEARCHCLAW_AGENTS.md` | 理解研究编排者角色 |
| 2 | 读取 `README.md` | 理解安装和pipeline结构 |
| 3 | 复制配置模板 | `cp config.researchclaw.example.yaml config.arc.yaml` |
| 4 | 询问 LLM API Key | OpenAI / 其他 provider |
| 5 | 运行安装 | `pip install -e .` + `researchclaw setup` |
| 6 | 配置完成 | 保存配置到 `~/.openclaw/workspace/config/` |

### 使用方式

```bash
# 用户说
"Research 深度学习在宠物健康监测中的应用"

# OpenClaw 自动执行
researchclaw run --config config.arc.yaml \
  --topic "深度学习在宠物健康监测中的应用" \
  --auto-approve

# 返回结果到会话
```

---

## 方案二：OpenClaw Bridge 集成（高级，30分钟）

### 配置详解

```yaml
# config.arc.yaml - OpenClaw Bridge 配置
openclaw_bridge:
  # 1. 定时研究任务
  use_cron: true
  
  # 2. 进度通知 → 飞书/Discord/Slack
  use_message: true
  
  # 3. 跨会话知识持久化
  use_memory: true
  
  # 4. 并行子会话（多Agent协作）
  use_sessions_spawn: true
  
  # 5. 实时网页搜索
  use_web_fetch: true
  
  # 6. 浏览器论文收集
  use_browser: false
```

### 集成后能力矩阵

| OpenClaw 能力 | AutoResearchClaw 受益 |
|--------------|----------------------|
| **cron** | 定时启动研究任务（如每周一早上8点） |
| **message** | 实时进度推送到飞书（文献收集→实验→论文撰写） |
| **memory** | 跨研究持久化知识库（上次研究的教训→下次使用） |
| **sessions_spawn** | 并行Agent处理多个研究阶段 |
| **web_fetch** | 实时网页搜索补充文献 |

---

## 方案三：ACP 集成（无API Key方案）

### 使用 Claude Code / Codex 作为后端

```yaml
# config.arc.yaml - ACP 配置
llm:
  provider: "acp"
  acp:
    agent: "claude"        # 或 codex, gemini, kimi
    cwd: "."               # 工作目录
  # 不需要 base_url 或 api_key!
```

### 执行

```bash
# AutoResearchClaw 通过 acpx 协议与 Claude Code 通信
# 你的 agent 用自己的 credentials
researchclaw run --config config.arc.yaml --topic "..."
```

---

## 方案四：多Agent分工集成（推荐用于复杂研究）

### 架构设计

```
User Request
    ↓
[M0 - 研究协调者]
    ↓ 分发任务
    ├─→ [E1 - 文献Agent] → 收集&筛选论文
    ├─→ [E2 - 实验Agent] → 设计&执行实验  
    ├─→ [T1 - 分析Agent] → 结果分析
    └─→ [T2 - 写作Agent] → 论文撰写
    ↓ 汇总
[Deliverable: 完整论文]
```

### 实现步骤

**Step 1: 创建研究任务分发脚本**

```python
# ~/.openclaw/workspace-main/scripts/research-dispatch.py
#!/usr/bin/env python3
"""
研究任务分发器 - AutoResearchClaw 多Agent协作
"""

import subprocess
import json

RESEARCH_TOPIC = "用户输入的研究主题"

# Phase 1: 并行文献收集 + 实验设计
subprocess.run([
    "openclaw", "sessions", "spawn",
    "--agent", "e1",
    "--task", f"AutoResearchClaw Phase B: 文献发现\n主题: {RESEARCH_TOPIC}\n执行: SEARCH_STRATEGY → LITERATURE_COLLECT → LITERATURE_SCREEN"
])

subprocess.run([
    "openclaw", "sessions", "spawn", 
    "--agent", "e2",
    "--task", f"AutoResearchClaw Phase D: 实验设计\n主题: {RESEARCH_TOPIC}\n执行: EXPERIMENT_DESIGN → CODE_GENERATION → RESOURCE_PLANNING"
])

# Phase 2: 等待完成后，分析和写作
# ... 自动协调
```

**Step 2: OpenClaw 配置**

```json
// ~/.openclaw/openclaw.json 添加 skill
{
  "skills": {
    "auto-research-claw": {
      "repo": "https://github.com/aiming-lab/AutoResearchClaw",
      "entry": "researchclaw",
      "dispatch_script": "~/.openclaw/workspace-main/scripts/research-dispatch.py"
    }
  }
}
```

---

## 集成验证清单

- [ ] 克隆仓库到 `~/.openclaw/skills/auto-research-claw/`
- [ ] 安装依赖 `pip install -e .`
- [ ] 运行 `researchclaw setup` 检查环境
- [ ] 配置 `config.arc.yaml`（LLM provider）
- [ ] 测试运行 `researchclaw run --topic "test"`
- [ ] 配置 OpenClaw Bridge（可选）
- [ ] 设置 cron 定时任务（可选）

---

## 快速启动命令

```bash
# 一键集成（在OpenClaw中执行）
cd ~/.openclaw/skills
git clone https://github.com/aiming-lab/AutoResearchClaw.git
cd AutoResearchClaw
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
researchclaw setup

# 配置
export OPENAI_API_KEY="sk-..."
# 或配置其他 provider

# 测试
researchclaw run --topic "测试研究主题" --auto-approve
```

---

## 与你的现有系统集成

### 与 ChronosProject 结合

```
Chronos 预测 → AutoResearchClaw 论文
     ↓                    ↓
历史趋势分析      撰写预测方法论论文
     ↓                    ↓
  输入主题        "基于历史模式的经济预测方法"
```

### 与 EvoMap 结合

```
EvoMap Bounty → AutoResearchClaw 研究
      ↓                  ↓
  接收研究任务     自动生成研究论文
      ↓                  ↓
  提交结果         获得奖励
```

---

选择你想实施的方案，我可以帮你：
1. 一键执行简单集成
2. 配置高级 Bridge 集成
3. 设计多Agent分工架构
4. 结合你的 ChronosProject 设计混合工作流

选哪个？或者全部实施？
