# npm 发布排障与安全最佳实践

## 常见错误排查

### E404 Not Found

```
npm error 404 Not Found - PUT https://registry.npmjs.org/@scope%2fpackage
```

可能原因及解决方案：

1. **npm 版本太低** — Node 22 以下的 npm 10.x 不支持 OIDC token，Actions 中拿不到身份凭证
   - 解决：workflow 中 `node-version` 改为 `24`
   - 验证：在 workflow 中添加 `npm --version` 步骤，确认 >= 11.5.1
   - 注意：即使 `setup-node` 指定了 24，runner 缓存可能导致使用旧版本

2. **Trusted Publisher 配置不匹配** — owner/repo/workflow/environment 任意一项不一致即失败
   - 逐项对照检查，注意 environment 大小写敏感
   - workflow 只填文件名（`publish.yml`），不含 `.github/workflows/` 路径
   - 排查命令：`gh api repos/{owner}/{repo}/environments` 确认 environment 存在

3. **包从未手动发布过** — npm 要求包已存在才能配置 Trusted Publisher
   - 先本地执行一次 `npm publish --access public`
   - 确认包名正确：`npm view @scope/package-name` 应返回包信息

4. **registry-url 未设置** — workflow 中 `setup-node` 必须配置 `registry-url`
   - 缺少此配置时 npm 不知道往哪发，OIDC token 也不会生成

### E422 Unprocessable Entity (provenance)

```
Error verifying sigstore provenance bundle: Unsupported GitHub Actions source repository visibility: "private"
```

`--provenance` 签名仅支持 public 仓库。Private 仓库必须去掉 `--provenance` flag。

如果仓库从 private 转为 public，需要等待 GitHub 缓存刷新（通常几分钟），或重新运行 workflow。

### E403 Forbidden

```
npm error 403 Forbidden - PUT https://registry.npmjs.org/@scope%2fpackage
```

可能原因：
- npm 账号未启用 2FA，但包要求 2FA 发布
- Granular Token 权限不足（缺少 publish 权限）
- 包被 npm 安全团队标记为需要审查

### npm warn Unknown user config "always-auth"

这是 npm 11+ 的废弃配置警告，不影响发布功能，可安全忽略。
如需消除警告，删除 `.npmrc` 中的 `always-auth=true` 行。

### ENEEDAUTH / EAUTHUNKNOWN

Token 认证失败。检查顺序：
1. OIDC 场景：确认 `permissions.id-token: write` 已声明
2. Token 场景：确认 `NODE_AUTH_TOKEN` secret 已设置且未过期
3. 检查 `.npmrc` 是否有冲突的 registry 或 authToken 配置

## 首次发布流程

Trusted Publishing 无法用于首次发布（包不存在时无法在 npmjs.com 配置）。首次发布步骤：

1. 确保本地 npm 已登录：`npm whoami`，未登录则 `npm adduser`
2. 确认 registry：`npm config get registry`（应为 `https://registry.npmjs.org`）
3. Build 项目：`npm run build`
4. 手动发布：`npm publish --access public`
5. 发布成功后再去 npmjs.com 配置 Trusted Publisher

## 安全最佳实践

### Token 管理

- **优先使用 OIDC Trusted Publishing**，彻底消除长期 token 泄露风险
- 需要传统 token 时，使用 Granular Access Token（细粒度令牌）：
  - 默认过期时间 7 天，最长 90 天
  - 限制到具体包和权限（read-only / read-write）
  - 绑定 IP CIDR 范围（可选）
- 禁止使用 Classic Automation Token（无范围限制、不过期）

### 2FA 配置

- 所有 npm 账号必须启用 2FA
- 推荐 WebAuthn（硬件密钥）> TOTP（Authenticator App）> SMS
- 发布操作启用 2FA：`npm profile set auth-and-writes`
- 组织账号：`npm org set <org> --2fa required`

### Provenance 签名

- Public 仓库始终使用 `--provenance` 发布，为消费者提供可验证的构建来源
- 验证已发布包的 provenance：
  ```bash
  npm audit signatures
  ```
- 在 npmjs.com 包页面查看绿色 "Provenance" 徽章确认

### 供应链安全

- **定期审计依赖**：`npm audit`，CI 中集成 `npm audit --audit-level=high`
- **锁定依赖版本**：提交 `package-lock.json`，CI 使用 `npm ci`（非 `npm install`）
- **SBOM 生成**：`npm sbom --sbom-format cyclonedx` 生成软件物料清单
- **Socket.dev / Snyk**：集成第三方供应链扫描工具，检测恶意包和 typosquatting
- **发布前检查**：`npm pack --dry-run` 确认发布内容，避免泄露 `.env`、私钥等敏感文件
