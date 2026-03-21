# GitHub Actions 进阶模式

## 复合 Action（Composite Actions）

将多个步骤封装为一个可复用的 Action，适用于团队内部共享通用流程。

### 定义复合 Action

```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Checkout + Node setup + install dependencies'
inputs:
  node-version:
    description: 'Node.js version'
    required: false
    default: '24'
runs:
  using: 'composite'
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    - run: npm ci
      shell: bash
```

### 使用复合 Action

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/setup-project
        with:
          node-version: '24'
      - run: npm test
```

注意：复合 Action 中每个 `run` 步骤必须指定 `shell`。

## 可复用 Workflow（Reusable Workflows）

将整个 workflow 封装为可调用的模块，适用于跨仓库共享标准流程。

### 定义可复用 Workflow

```yaml
# .github/workflows/reusable-ci.yml
name: Reusable CI
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '24'
      run-lint:
        type: boolean
        default: true
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
        if: ${{ inputs.run-lint }}
      - run: npm test
```

### 调用可复用 Workflow

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  ci:
    uses: ./.github/workflows/reusable-ci.yml
    with:
      node-version: '24'
      run-lint: true
    secrets: inherit    # 或逐个传递
```

### 复合 Action vs 可复用 Workflow

| 维度 | 复合 Action | 可复用 Workflow |
|------|------------|----------------|
| 粒度 | 步骤级（steps） | 任务级（jobs） |
| 调用方式 | `uses:` 在 step 中 | `uses:` 在 job 中 |
| 跨仓库 | 需发布到 Marketplace 或引用仓库 | 直接引用仓库路径 |
| Secrets | 自动继承 | 需显式传递或 `secrets: inherit` |

## 缓存策略

### 依赖缓存（内置）

`actions/setup-node`、`actions/setup-python` 等官方 Action 内置缓存支持：

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: 24
    cache: 'npm'       # 自动缓存 ~/.npm，key 基于 package-lock.json hash
```

### 自定义缓存

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/turbo
      .next/cache
    key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-build-
```

### 缓存失效模式
- lockfile 变更时自动失效（推荐）
- `restore-keys` 实现前缀匹配降级：精确 key 未命中时使用旧缓存
- 缓存总大小上限 10 GB/仓库，超过后自动淘汰最久未用的

## Matrix 进阶

### 基础 Matrix

```yaml
strategy:
  matrix:
    node-version: [20, 22, 24]
    os: [ubuntu-latest, macos-latest]
```

生成 3x2 = 6 个 job 并行执行。

### include / exclude

```yaml
strategy:
  matrix:
    node-version: [20, 22, 24]
    os: [ubuntu-latest, macos-latest]
    exclude:
      - node-version: 20
        os: macos-latest         # 跳过 Node 20 + macOS 组合
    include:
      - node-version: 24
        os: windows-latest       # 额外添加 Node 24 + Windows
        experimental: true
```

### 动态 Matrix

```yaml
jobs:
  generate:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set.outputs.matrix }}
    steps:
      - id: set
        run: echo "matrix=$(node scripts/gen-matrix.js)" >> $GITHUB_OUTPUT

  test:
    needs: generate
    strategy:
      matrix: ${{ fromJSON(needs.generate.outputs.matrix) }}
    runs-on: ${{ matrix.os }}
    steps:
      - run: echo "Testing on ${{ matrix.os }} with Node ${{ matrix.node }}"
```

### fail-fast 控制

```yaml
strategy:
  fail-fast: false    # 默认 true，某个 matrix job 失败时取消其余
  matrix:
    node-version: [20, 22, 24]
```

设为 `false` 可确保所有组合都运行完毕，便于一次性发现所有兼容性问题。

## Artifact 管理

### 上传构建产物

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 7           # 保留天数，默认 90
```

### 跨 Job 传递 Artifact

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/
      - run: deploy ./dist
```

### Artifact 注意事项
- 单个 Artifact 上限 5 GB（GitHub Free），10 GB（Enterprise）
- 同名 Artifact 在同一 run 中会报错，v4 不再自动合并（v3 行为已变更）
- 敏感文件不要上传为 Artifact（任何有仓库读权限的人可下载）
