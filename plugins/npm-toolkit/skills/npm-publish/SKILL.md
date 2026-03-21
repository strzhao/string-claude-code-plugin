---
name: npm-publish
description: |
  配置 npm 包通过 GitHub Actions 自动发布到 npmjs.com。使用 OIDC Trusted Publishing（无需 npm token）。
  当用户提到"发布 npm"、"npm publish"、"配置 npm 自动发布"、"npm 包发布"、"设置 npm CI/CD"、
  "把包发到 npm"、"npm trusted publishing"、"OIDC 发布"时使用此技能。
  也适用于用户已有项目想添加 npm 自动发布流程的场景，或者 npm publish 失败需要排查的场景。
---

# npm 自动发布配置指南

将 npm 包通过 GitHub Actions + OIDC Trusted Publishing 自动发布，无需管理 npm token。

## 核心知识

### Node 版本要求

OIDC Trusted Publishing 需要 npm CLI >= 11.5.1。各 Node 版本对应的 npm：

| Node 版本 | npm 版本 | 是否支持 Trusted Publishing |
|-----------|---------|--------------------------|
| Node 20   | npm 10.x | 不支持 |
| Node 22   | npm 10.9.x | 不支持 |
| Node 24   | npm 11.x+ | 支持 |

**必须使用 Node 24**，这是最常见的失败原因。

### Private 仓库限制

`--provenance` 签名仅支持 public 仓库。Private 仓库使用 `--provenance` 会报错：

```
Error verifying sigstore provenance bundle: Unsupported GitHub Actions source repository visibility: "private"
```

Private 仓库需要去掉 `--provenance` flag。

## 配置流程

### 第一步：确认 package.json 配置

确保 package.json 包含以下关键字段：

```json
{
  "name": "@scope/package-name",
  "version": "1.0.0",
  "files": ["dist", "README.md"],
  "publishConfig": {
    "access": "public"
  }
}
```

- scoped 包（`@xxx/yyy`）需要 `publishConfig.access: "public"`，否则默认 restricted
- `files` 字段控制发布内容，避免发布 src、node_modules 等

### 第二步：创建 GitHub Actions Workflow

创建 `.github/workflows/publish.yml`：

**Public 仓库（推荐，带 provenance）：**

```yaml
name: Publish to npm

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    environment: npm
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 24
          registry-url: https://registry.npmjs.org

      - run: npm ci
      - run: npm run build
      - run: npm publish --provenance --access public
```

**Private 仓库（不带 provenance）：**

```yaml
name: Publish to npm

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    environment: npm
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 24
          registry-url: https://registry.npmjs.org

      - run: npm ci
      - run: npm run build
      - run: npm publish --access public
```

关键配置说明：
- `environment: npm` — 必须与 npmjs.com 上配置的 environment 名称一致
- `permissions.id-token: write` — 允许 GitHub Actions 生成 OIDC token
- `node-version: 24` — 确保 npm >= 11.5.1
- `registry-url` — 必须设置，否则 npm publish 不知道往哪发

### 第三步：创建 GitHub Environment

通过 `gh` CLI 创建：

```bash
gh api repos/{owner}/{repo}/environments/npm -X PUT --input - <<< '{}'
```

或到 GitHub 仓库 Settings → Environments → New environment，名称填 `npm`。

### 第四步：在 npmjs.com 配置 Trusted Publisher

前提：包必须已经手动发布过至少一个版本（npm 要求包已存在才能配置 trusted publisher）。

1. 访问 `https://www.npmjs.com/package/{package-name}/access`
2. 找到 "Trusted Publisher" 部分
3. 选择 GitHub Actions，填入：
   - **Owner**: GitHub 用户名或组织名
   - **Repository**: 仓库名（不含 owner）
   - **Workflow**: `publish.yml`（仅文件名，不含路径）
   - **Environment**: `npm`（大小写敏感，必须精确匹配）

### 第五步：测试发布

1. 在 package.json 中 bump version
2. 提交并推送
3. 创建 GitHub Release：
   ```bash
   gh release create v{version} --title "v{version}" --notes "Release notes" --target main
   ```
4. 检查 workflow 运行状态：
   ```bash
   gh run list --limit 1
   gh run watch {run-id}
   ```

## 参考文档

- **排障与安全最佳实践**: See [references/troubleshooting.md](references/troubleshooting.md) — E404/E422 排查、2FA、Token 管理、Provenance、供应链安全
- **发布自动化工具选型**: See [references/release-automation.md](references/release-automation.md) — Changesets / semantic-release / release-please 配置与对比
