# Autopilot — Claude Code 自动驾驶工程套件

<div align="center">

**从目标描述到代码合并，全程自动化**

[![Plugins](https://img.shields.io/badge/plugins-7-blue.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)](https://claude.ai/code)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

</div>

---

## 这是什么

Autopilot 是一套 Claude Code 插件集合，核心是 **autopilot 自动驾驶工程套件**——你只需要描述目标，它就能自动完成设计、编码、测试、修复、提交的全流程闭环。

一句话：**把 AI 从"辅助编程"升级到"自动驾驶"。**

---

## 核心能力

### `/autopilot <目标>` — 全流程闭环

```
目标 → 设计 → [审批] → 红蓝对抗编码 → 五层 QA → 自动修复 → [验收] → 知识沉淀 → 合并
```

全流程由 6 阶段状态机驱动（design → implement → qa → auto-fix → merge → done），状态持久化到文件，支持 Git Worktree 隔离——每个 worktree 独立运行互不干扰。你只需介入 2 次：设计审批 + 验收审批。

#### 红蓝对抗编码

蓝队和红队作为两个独立 Agent **并行启动**，遵循严格的信息隔离：

- **蓝队**（实现者）：读取设计文档 + 实现计划，按方案编码
- **红队**（验证者）：**仅**读取设计文档，不能看到蓝队的实现代码，独立编写验收测试

红队测试代表的是设计意图的代码化表达，而非对已有实现的追认。这种信息不对称确保了测试独立于实现。

当设计文档声明了领域 Skill 委托时，自动路由到已有的专业 Skill 执行（而非从零实现），Skill 失败则自动回退到红蓝对抗路径。

#### 五层 QA

QA 分三波执行，最大化并行效率：

**Wave 1 — 命令并行执行**
- **Tier 0**：红队验收测试（最高优先级，失败 = 实现不符合设计）
- **Tier 1**：类型检查 / Lint / 单元测试 / 构建验证（4 项并行）
- **Tier 3-4**：集成验证 + 回归检查（条件性并行）
- 快速路径：Tier 0+1 合计 ≥3 项失败时跳过后续，直接进入修复

**Wave 1.5 — 真实场景冒烟测试**（独立步骤，不可跳过）
- 执行设计文档中定义的真实用户场景（CLI 命令、curl 调用、dev server 验证等）
- 每个场景强制记录 `执行:` 命令 + `输出:` 实际输出，描述性文字不被接受
- 内置防合理化机制，覆盖 5 种常见跳过借口（"dev server 太重"、"jest 已验证"等）

**Wave 2 — 并行 AI 审查**
- **设计符合性审查**：独立 Agent 逐项比对设计文档与实际实现，遵循"不信任报告"原则
- **代码质量审查**：独立 Agent 按审查清单检查，置信度 ≥80 过滤假阳性

修复后支持选择性重跑（仅重跑失败 Tier + Tier 1.5），节省 30-50% 重试时间。

#### 自动修复

QA 失败项进入系统化调试流程，每个失败项严格按四阶段执行：

1. **观察**：完整阅读错误信息和堆栈，不跳过细节
2. **假设**：形成明确的因果假设，写下再行动
3. **验证**：用最小实验验证假设，被推翻则回到观察
4. **修复**：假设被验证后才做修复，附命令输出作为证据

铁律：**不允许修改红队测试来通过 QA**——问题在实现，不在测试。最多 3 轮自动修复，超限则交由用户决定。

#### 知识工程

项目知识按三层 Progressive Disclosure 组织：索引层（`index.md`，路由用）→ 全局层（`decisions.md`、`patterns.md`）→ 领域分区层（`domains/*.md`）。

- **消费**：design 阶段两阶段检索——先扫索引匹配 tags（≤5s），再按需加载相关文件（≤10s，最多 3 个）
- **生产**：merge 阶段自动从设计文档和调试历程中提取决策和教训，自动生成 tags，同步索引

#### 核心原则

贯穿全流程的 7 条铁律，其中两条值得强调：
- **成功需要证据**：任何阶段声称"完成"必须附上可验证的证据（命令输出、测试结果）。"我检查了"不算。
- **假设需要证据**：对外部系统行为的假设（API 响应结构、数据格式）必须通过运行时验证确认，不能仅凭文档推理。

---

### `/autopilot commit` — 智能提交

不只是 `git commit`——一套三阶段并行执行模型：

**Phase 1 → 1.5 → 2 → 3**

| 阶段 | 内容 | 串/并行 |
|------|------|---------|
| Phase 1 | 分析 git diff，识别改动类型和影响范围 | 串行 |
| Phase 1.5 | React 最佳实践检测 + 代码简化（修改文件，后续必须基于优化后代码） | 串行 |
| Phase 2 | Bugfix 验证 + 代码理解测验 + 项目元数据更新 | **并行** |
| Phase 3 | 执行提交 + ai-todo 任务同步 + 输出总结 | 串行 |

**上下文感知**：检测到 autopilot 主链路（代码已通过五层 QA）时，自动跳过代码优化和测验——再优化可能破坏已验证状态。

**Bugfix 双模式验证**（有测试框架 → 自动化测试模式；无测试框架 → 运行时验证模式），两种模式都要求产出运行时证据。

**代码理解测验**：1-2 道场景判断题，考察的是设计权衡和失败模式——"如果上游返回的数据结构和预期不同，这段代码会怎样？"——而非语法细节。Vibe Coding 时代，开发者的核心价值是有效监督 AI 产出。

**提交信息**：`type(scope): 业务描述 (技术说明)`，中文业务视角优先，技术细节括号补充。

---

### `/autopilot doctor` — 工程健康度诊断

10 个维度加权评分，两波并行采集，输出 S-F 六级评分：

| 维度 | 权重 | 评估内容 |
|------|------|----------|
| 测试基础设施 | 20% | 框架、测试文件、覆盖率工具、测试/源码比 |
| 类型安全 | 15% | 类型系统、strict 模式 |
| 代码质量工具 | 10% | Lint + Format 组合、auto-fix 脚本 |
| 构建系统 | 10% | build/dev 命令、构建工具配置 |
| CI/CD 流水线 | 10% | Workflow 文件、测试/lint/构建门禁 |
| 项目结构 | 10% | 分层清晰度、命名一致性、模块边界 |
| 文档质量 | 10% | CLAUDE.md 深度、README 完整性 |
| Git 工作流 | 5% | pre-commit hooks、commitlint |
| 依赖健康 | 5% | Lock 文件、漏洞数、过期依赖 |
| AI 就绪度 | 5% | CLAUDE.md 丰富度、测试模板可复制性、红队可测试性 |

**autopilot 兼容性矩阵**：将 9 项 autopilot 核心功能映射到依赖维度，标注 ✅ 完整 / ⚠️ 降级 / ❌ 不可用，告诉你具体哪项功能会受影响。

**`--fix` 模式**：对 ≤6 分的维度自动生成修复方案（配置文件、脚本），逐项确认后应用，修复后立即重跑验证。

---

## 生态插件

除了核心的 autopilot，还提供以下实用插件：

| 插件 | 功能 | 一句话描述 |
|------|------|-----------|
| **worktree-setup** | Git Worktree 自动初始化 | `claude -w <name>` 后自动链接配置、安装依赖、分配端口，开箱即用 |
| **writer-skill** | 写作技能包 | 博客向 / 通用向 / 技术文档向三种风格 |
| **npm-toolkit** | npm 发布 + GitHub Actions | OIDC 自动发布（无需 token）+ CI/CD 工作流配置 |
| **summarizer** | 多模态内容摘要 | 文章/视频/音频自动提取 + 结构化摘要 + flomo 保存 |
| **task-notifier** | 任务完成提示音 | 任务执行完自动播放系统提示音，跨平台支持 |
| **plugin-sync** | 跨模型插件同步 | 解决 `cc switch` 切换模型后插件丢失问题 |

---

## 快速开始

### 方案一：插件市场安装（推荐）

在 Claude Code 中执行：

```bash
/plugin marketplace add https://github.com/strzhao/autopilot.git
```

然后按需安装你想用的插件。

### 方案二：单插件安装

```bash
git clone https://github.com/strzhao/autopilot.git
cd autopilot
# 安装 autopilot 核心
/install plugins/autopilot
# 安装其他插件（按需）
/install plugins/worktree-setup
/install plugins/writer-skill
```

重启 Claude Code 后生效。

---

## 许可证

MIT

---

## 联系方式

- **维护者**：String Zhao
- **邮箱**：zhaoguixiong@corp.netease.com
- **仓库**：https://github.com/strzhao/autopilot
