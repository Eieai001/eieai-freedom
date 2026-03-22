# 内容自动化模板库

> Freedom 项目 - 可复用的内容创作提示词模板

## 社交媒体模板

### 1. 科技动态分享

```
主题: 分享 [主题] 的最新动态

格式:
🔬 [主题] 周报 | [日期]

📌 核心进展:
• [要点1]
• [要点2]
• [要点3]

💡 我的思考:
[2-3句深度分析]

❓ 讨论:
你对 [相关问题] 怎么看？

#AI #科技 #洞见
```

### 2. 学习笔记分享

```
主题: 分享 [学习内容] 的笔记

📚 [学习主题] 学习笔记

🎯 核心概念:
[列出3-5个关键点]

💡 关键洞察:
[最重要的领悟]

🔄 实际应用:
[如何应用到实际场景]

📖 延伸学习:
[推荐资源]

#学习 #知识管理 #[主题标签]
```

### 3. 工具推荐帖

```
主题: 推荐 [工具名称]

🛠️ [工具名称]
[一句话描述]

✅ 优点:
• [优点1]
• [优点2]
• [优点3]

⚠️ 限制:
• [限制1]
• [限制2]

🎯 适合人群:
[目标用户描述]

🔗 链接: [工具地址]

#工具推荐 #效率 #神器
```

### 4. 经验分享帖

```
主题: [数字] 个 [主题] 经验

[数字] 个 [主题] 经验，帮你 [获得收益]

1️⃣ [经验1]
[简短说明]

2️⃣ [经验2]
[简短说明]

3️⃣ [经验3]
[简短说明]

... (以此类推)

💬 你有什么建议？欢迎评论！

#经验分享 #[主题标签]
```

## 自动化流程

### 每日内容流水线

```javascript
// 伪代码: 每日内容生成流程
const dailyContent = async () => {
  // 1. 抓取热点
  const trends = await fetchTrends(['AI', 'Tech', 'Startup']);
  
  // 2. 筛选相关
  const relevant = filterByInterest(trends, userPrefs);
  
  // 3. 生成内容
  const content = relevant.map(item => ({
    type: 'social_post',
    platform: 'twitter',
    template: 'tech_update',
    data: item
  }));
  
  // 4. 发布
  for (const post of content) {
    await publish(post);
  }
  
  return content;
};
```

### 批量内容生成

```javascript
// 批量生成同类内容
const batchGenerate = async (topic, count) => {
  const results = [];
  for (let i = 0; i < count; i++) {
    const content = await generatePost(topic, {
      angle: ['tutorial', 'opinion', 'news', 'tips'][i % 4],
      length: 'medium',
      include_hashtags: true
    });
    results.push(content);
  }
  return results;
};
```

## 最佳实践

1. **保持一致性** - 固定发布频率，形成读者预期
2. **价值优先** - 每篇都要有干货，不发水文
3. **互动驱动** - 结尾放问题，提升评论率
4. **数据优化** - 追踪数据，持续改进

---

*模板是起点，创意是终点。*
