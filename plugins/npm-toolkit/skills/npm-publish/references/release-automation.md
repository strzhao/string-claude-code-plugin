# 发布自动化工具选型

## 选型决策树

```
需要发布自动化？
├── Monorepo（多包联合发布）→ Changesets
├── 全自动化（commit 驱动，零人工干预）→ semantic-release
└── 受控自动化（PR 审批后发布）→ release-please
```

## Changesets — Monorepo 首选

### 核心理念
开发者在 PR 中声明变更意图（changeset 文件），合并后自动聚合为 changelog 和版本升级。

### 基础配置

```bash
# 安装
npm install -D @changesets/cli @changesets/changelog-github
npx changeset init
```

`.changeset/config.json`：
```json
{
  "$schema": "https://unpkg.com/@changesets/config@3/schema.json",
  "changelog": ["@changesets/changelog-github", { "repo": "owner/repo" }],
  "commit": false,
  "access": "public",
  "baseBranch": "main"
}
```

### 工作流程
1. 功能开发完成后运行 `npx changeset`，选择包和版本类型（patch/minor/major）
2. 生成 `.changeset/xxx.md` 文件，随代码一起提交
3. 合并到 main 后，CI 自动创建 "Version Packages" PR
4. 合并该 PR 后触发发布

### GitHub Actions 集成

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          registry-url: https://registry.npmjs.org

      - run: npm ci

      - uses: changesets/action@v1
        with:
          publish: npx changeset publish
          title: 'chore: version packages'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## semantic-release — 全自动化

### 核心理念
完全基于 Conventional Commits 消息自动决定版本号、生成 changelog、发布到 npm 和 GitHub Release。零人工版本管理。

### 基础配置

```bash
npm install -D semantic-release @semantic-release/changelog @semantic-release/git
```

`.releaserc.json`：
```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md", "package.json"],
      "message": "chore(release): ${nextRelease.version}"
    }],
    "@semantic-release/github"
  ]
}
```

### Commit 规范与版本映射
- `fix:` → patch（1.0.x）
- `feat:` → minor（1.x.0）
- `feat!:` 或 `BREAKING CHANGE:` → major（x.0.0）

### GitHub Actions 集成

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
        with:
          persist-credentials: false

      - uses: actions/setup-node@v4
        with:
          node-version: 24
          registry-url: https://registry.npmjs.org

      - run: npm ci
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## release-please — 受控自动化

### 核心理念
Google 出品。分析 Conventional Commits 自动创建 Release PR，人工审批合并后才发布。兼顾自动化与可控性。

### GitHub Actions 集成

```yaml
name: Release
on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          release-type: node

  publish:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    environment: npm
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          registry-url: https://registry.npmjs.org
      - run: npm ci
      - run: npm publish --provenance --access public
```

### 配置文件（可选）

`release-please-config.json`：
```json
{
  "packages": { ".": { "release-type": "node" } },
  "changelog-sections": [
    { "type": "feat", "section": "Features" },
    { "type": "fix", "section": "Bug Fixes" }
  ]
}
```

## Monorepo 发布

Monorepo 推荐使用 Changesets，原生支持多包联合发布：

- **工作区发现**：自动识别 `pnpm-workspace.yaml` 或 `package.json` workspaces
- **依赖同步**：包 A 升级时，依赖 A 的包 B 自动 bump 版本
- **发布顺序**：按依赖拓扑排序发布，确保被依赖的包先发
- **独立版本**：每个包独立版本号（默认），也支持 `fixed` 模式统一版本

配置 `fixed` 模式（统一版本）：
```json
{
  "fixed": [["@scope/pkg-a", "@scope/pkg-b"]]
}
```

## 选型建议

| 维度 | Changesets | semantic-release | release-please |
|------|-----------|-----------------|---------------|
| 自动化程度 | 半自动（需手写 changeset） | 全自动 | 半自动（需审批 PR） |
| Monorepo | 原生支持 | 需插件 | 原生支持 |
| 版本控制 | 手动声明 | Commit 驱动 | Commit 驱动 |
| Changelog | 从 changeset 生成 | 从 commit 生成 | 从 commit 生成 |
| 学习成本 | 低 | 中（需严格 commit 规范） | 低 |
| 适合场景 | 多包项目、团队协作 | 单包、持续交付 | 单包、需审批流程 |
