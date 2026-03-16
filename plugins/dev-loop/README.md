# dev-loop — AI 驱动的 DevOps 闭环

从目标描述到代码合并，全程自动化。人只在两个审批门介入：**设计审批** 和 **验收审批**。

## 工作流程

```
用户输入目标 → AI 设计方案 → [审批门 1] → AI 编码(TDD) → AI 全面测试
    → AI 自动修复 ←→ AI 重新测试(循环) → [审批门 2] → AI 合并代码
```

## 快速开始

```bash
# 推荐：在 worktree 中运行（隔离代码改动）
claude -w dev-loop-avatar

# 启动 dev-loop
/dev-loop 实现用户头像上传功能，支持裁剪和压缩

# AI 自动完成设计后，审批设计方案
/dev-loop approve

# 或者要求修改
/dev-loop revise 需要支持 WebP 格式

# AI 自动完成编码和测试后，验收代码
/dev-loop approve
```

## 命令

| 命令 | 说明 |
|------|------|
| `/dev-loop <目标>` | 启动新的 dev-loop |
| `/dev-loop approve` | 批准当前审批门 |
| `/dev-loop revise <反馈>` | 要求修改当前阶段产出 |
| `/dev-loop status` | 查看当前状态 |
| `/dev-loop cancel` | 取消并清理 |
| `/dev-loop --help` | 显示帮助 |

## 选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `--max-iterations` | 30 | 最大迭代次数 |
| `--max-retries` | 3 | QA 失败后自动修复的最大重试次数 |

## 阶段说明

### 1. Design（设计）
AI 分析目标，探索代码库，产出设计文档和实现计划。完成后进入审批门。

### 2. Implement（实现）
按计划逐任务编码，采用 TDD 模式（先写测试再写实现）。

### 3. QA（质量检查）
四层质量检查：
- **Tier 1**: 类型检查、Lint、单元测试、构建验证
- **Tier 2**: 设计符合性、模式一致性、安全审查、边界处理
- **Tier 3**: Dev server 启动、API 端点验证、导入完整性
- **Tier 4**: 回归检查

### 4. Auto-fix（自动修复）
QA 发现问题时自动修复，修复后重新全量验证。最多重试 3 次。

### 5. Merge（合并）
调用 git-tools 完成智能提交，生成完成报告。

## 可追溯性

所有过程记录在 `.claude/dev-loop.local.md` 状态文件中：
- 目标描述、设计文档、实现计划
- 每轮 QA 报告（完整保留历史）
- 变更日志（时间戳 + 每个关键事件）
- Git 历史提供代码层面的完整回溯

## 与其他插件的配合

- **worktree-setup**: 建议在 worktree 中运行，隔离代码改动
- **git-tools**: merge 阶段复用其智能提交能力
- **local-test**: QA 阶段复用其验证策略
- **ralph-loop**: 两者互斥（共用 Stop hook 机制）
