# npm-toolkit

npm 发布全链路 + GitHub Actions CI/CD 配置工具包，覆盖从首次发布到自动化发布的完整流程。

## 功能概览

- OIDC Trusted Publishing 自动发布（无需管理 npm token）
- GitHub Actions 工作流配置（CI/CD 全场景覆盖）
- 安全最佳实践（2FA、Token 管理、Provenance、供应链安全）
- 发布自动化工具选型（Changesets / semantic-release / release-please）
- GitHub Actions 进阶模式（复合 Action、可复用 Workflow、Matrix、缓存）

## 包含技能

### npm-publish

配置 npm 包通过 GitHub Actions + OIDC Trusted Publishing 自动发布。

**核心能力**:
- 完整的 5 步配置流程（package.json → workflow → environment → trusted publisher → 测试）
- Public / Private 仓库双模板（provenance 自动适配）
- Node 版本兼容性矩阵（必须 Node 24 + npm 11.5.1+）

**参考文档**:
- `references/troubleshooting.md` — E404/E422 排查、首次发布流程、2FA 配置、Token 管理、Provenance 验证、供应链安全审计
- `references/release-automation.md` — Changesets / semantic-release / release-please 选型决策树、核心配置、GitHub Actions 集成 workflow、Monorepo 发布策略

### github-actions-setup

GitHub Actions 工作流配置，覆盖常见 CI/CD 场景。

**核心能力**:
- 6 种触发器配置（Push / PR / Release / 定时 / 手动 / 组合）
- 4 套项目模板（Node.js CI / Python CI / Docker / 部署）
- Environment、Secrets、Permissions 配置
- Workflow 失败排查方法

**参考文档**:
- `references/advanced-patterns.md` — 复合 Action 封装、可复用 Workflow 定义与调用、依赖缓存与构建缓存策略、动态 Matrix 与 fail-fast 控制、Artifact 上传与跨 Job 传递

## 使用方式

安装插件后：
- 发送 "配置 npm 自动发布" 或 "npm publish" 触发 npm-publish 技能
- 发送 "配置 GitHub Actions" 或 "设置 CI/CD" 触发 github-actions-setup 技能

## 目录结构

```
npm-toolkit/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── npm-publish/
│   │   ├── SKILL.md                         # 核心配置流程
│   │   └── references/
│   │       ├── troubleshooting.md           # 排障与安全最佳实践
│   │       └── release-automation.md        # 发布自动化工具选型
│   └── github-actions-setup/
│       ├── SKILL.md                         # 工作流配置指南
│       └── references/
│           └── advanced-patterns.md         # 进阶模式
└── README.md
```

## 版本历史

### v2.0.0 (2026-03-21)
- 结构升级为 Progressive Disclosure（SKILL.md 精简 + references 详细）
- 新增排障与安全最佳实践参考文档（2FA / Token / Provenance / 供应链安全）
- 新增发布自动化工具选型参考文档（Changesets / semantic-release / release-please / Monorepo）
- 新增 GitHub Actions 进阶模式参考文档（复合 Action / 可复用 Workflow / 缓存 / Matrix / Artifact）
- README 扩展为完整文档

### v1.0.0 (2026-03-21)
- 初始版本
- npm-publish：OIDC Trusted Publishing 配置 + 常见问题排查
- github-actions-setup：触发器 + 模板 + Environment/Secrets/Permissions
