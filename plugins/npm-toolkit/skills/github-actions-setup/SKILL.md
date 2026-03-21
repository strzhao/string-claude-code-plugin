---
name: github-actions-setup
description: |
  配置 GitHub Actions 工作流，包括 CI/CD 自动触发、构建、测试等。
  当用户提到"配置 GitHub Actions"、"设置 CI/CD"、"添加 workflow"、"自动构建"、"自动测试"、
  "github action 触发"、"workflow 配置"、"CI 流水线"、"持续集成"时使用此技能。
  也适用于需要修改现有 workflow、排查 workflow 失败、或添加新的自动化流程的场景。
---

# GitHub Actions 工作流配置指南

帮助快速配置 GitHub Actions 工作流，覆盖常见的 CI/CD 场景。

## 工作流基础结构

```yaml
name: Workflow Name

on:
  # 触发条件
  push:
    branches: [main]

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Step name
        run: echo "Hello"
```

## 触发器配置

```yaml
# Push（支持 branches/paths/tags 过滤）
on:
  push:
    branches: [main, develop]
    paths: ['src/**', 'package.json']   # 路径过滤（可选）
    tags: ['v*']                        # tag 匹配

# Pull Request
on:
  pull_request:
    branches: [main]

# Release
on:
  release:
    types: [published]

# 定时（cron 格式，UTC 时区）
on:
  schedule:
    - cron: '0 2 * * 1-5'              # 工作日 UTC 2:00

# 手动触发（带参数）
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deploy environment'
        type: choice
        options: [staging, production]

# 组合触发
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
```

## 常用工作流模板

### Node.js 项目 CI

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [20, 22, 24]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - run: npm ci
      - run: npm run build
      - run: npm test
```

### Docker 构建推送

```yaml
name: Docker

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
```

## Environment、Secrets 与 Permissions

### Environment 与 Secret 管理

```bash
# 创建 environment
gh api repos/{owner}/{repo}/environments/{env-name} -X PUT --input - <<< '{}'

# 仓库级 secret
gh secret set SECRET_NAME --body "value"

# environment 级 secret
gh secret set SECRET_NAME --env production --body "value"
```

在 workflow 中引用：`environment: production` + `${{ secrets.DEPLOY_TOKEN }}`

### Permissions

GitHub Actions 默认权限较小，按需显式声明：

```yaml
permissions:
  contents: read          # 读取仓库代码（默认）
  id-token: write         # OIDC token（npm trusted publishing 等）
  packages: write         # 推送 GitHub Container Registry
  pull-requests: write    # 评论 PR
```

最小权限原则：只声明需要的权限。

## 实用技巧

```yaml
# 条件执行
- run: npm run deploy
  if: github.ref == 'refs/heads/main'

# 并行与依赖
jobs:
  lint: ...
  test: ...
  build:
    needs: [lint, test]    # 等 lint 和 test 都过了再 build
```

## 排查 Workflow 失败

```bash
gh run list --limit 5                    # 查看最近的 run
gh run view {run-id} --log-failed        # 查看失败日志
gh run rerun {run-id} --failed           # 重新运行失败 job
```

常见原因：Node 版本过低、permissions 不足、Secret 未配置、package-lock.json 未提交、actions 版本过旧。

## 参考文档

- **进阶模式**: See [references/advanced-patterns.md](references/advanced-patterns.md) — 复合 Action、可复用 Workflow、缓存策略、Matrix 进阶、Artifact 管理
