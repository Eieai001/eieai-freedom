# 图片解析映射系统 (Image Mapping System)

## 项目概述
系统化解析mymemory中的2471张图片，建立结构化映射数据库。

## 数据结构

### 核心表：image_mappings
```json
{
  "id": "uuid",
  "file_path": "原始路径",
  "file_name": "文件名",
  "source_device": "设备来源(xiaomi/meizu等)",
  "category": "分类(截图/照片/微信/产品等)",
  "date_created": "创建时间(从EXIF或文件名提取)",
  "extracted_text": "OCR提取的文本",
  "description": "图像内容描述",
  "objects": ["识别到的物体列表"],
  "tags": ["标签"],
  "business_relevance": "商业相关度评分(0-10)",
  "related_contact": "关联的微信联系人",
  "processed_at": "处理时间",
  "status": "处理状态(pending/processing/done/error)"
}
```

### 分类体系
1. **screenshots** - 截图（微信、小红书、支付宝等）
2. **products** - 产品图片（猫粮、猫砂、包装等）
3. **documents** - 文档（资质、合同、证件）
4. **personal** - 个人照片
5. **business_chat** - 商务沟通截图
6. **pet_related** - 宠物相关

## 处理流程

### Phase 1: 扫描与分类
- 遍历所有图片文件
- 根据路径和文件名初步分类
- 提取EXIF信息
- 生成待处理队列

### Phase 2: 批量解析
- 使用MiniMax MCP进行图像理解
- OCR提取文本
- 生成描述和标签
- 评估商业相关度

### Phase 3: 关联分析
- 关联微信文本记录
- 识别供应商/客户
- 提取产品信息
- 建立知识图谱

### Phase 4: 建立索引
- 创建可搜索数据库
- 生成统计报告
- 提供查询接口

## 技术方案

### 工具选择
- **图像理解**: MiniMax MCP (understand_image)
- **OCR**: 本地Tesseract或API
- **数据库**: SQLite或JSONL
- **批处理**: Python脚本

### 成本控制
- 2471张图片 × API调用 = 需要预算控制
- 优先处理高价值图片（商务相关）
- 相似图片去重
- 分批处理，可中断恢复

## 输出产物

1. **image_database.jsonl** - 主数据库
2. **category_stats.json** - 分类统计
3. **business_insights.json** - 商业洞察
4. **search_index.json** - 搜索索引
5. **report.md** - 分析报告

## 执行计划

### 任务分配
- **@e1**: 开发扫描与分类脚本
- **@t1**: 开发批量解析pipeline
- **@t2**: 开发关联分析与索引
- **@m0**: 协调、验收、整合

### 预计时间
- Phase 1: 2小时
- Phase 2: 12-24小时（API限制）
- Phase 3: 4小时
- Phase 4: 2小时

总计: 20-32小时
