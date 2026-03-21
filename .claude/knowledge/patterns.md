# Patterns & Lessons

### [2026-03-21] README.md 版本号与 CLAUDE.md 长期不同步
**Scenario**: 插件版本在 CLAUDE.md 更新日志中迭代（v2.0.0 → v2.9.0），但 README.md 标题行版本号从未同步更新
**Lesson**: autopilot-commit 的版本升级步骤只检查 `.claude-plugin/plugin.json` 和 `package.json`，不会自动同步 README.md 中的版本号。多处记录版本号时，升级流程应覆盖所有版本出现位置，或在 autopilot-commit 中增加 README 版本同步检查
**Evidence**: README.md L54 `autopilot (v2.0.0)` 停留了 9 个版本未更新，CLAUDE.md 已记录到 v2.9.0。`grep "autopilot.*v2" README.md CLAUDE.md` 可复现不一致

### [2026-03-21] Skill 插件 Progressive Disclosure 重构模式
<!-- tags: skill, progressive-disclosure, plugin, refactoring -->
**Scenario**: npm-toolkit SKILL.md 内联所有内容（排障/模板/高级用法），导致行数膨胀（195+311 行），不符合 <500 行最佳实践
**Lesson**: 按信息频率拆分：核心流程（每次都需要）保留在 SKILL.md，低频内容（排障/高级模式/工具选型）外置到 `references/` 目录。引用用相对路径 `See [references/xxx.md](references/xxx.md)`。拆分后 SKILL.md 精简 30-40%，Claude 按需加载 references 文件。关键：引用只保持一层深度（SKILL.md → references/），不嵌套引用
**Evidence**: npm-toolkit 重构：npm-publish 195→165 行（-15%），github-actions-setup 311→196 行（-37%），3 个 references 文档（106+224+239 行），24/24 验收测试通过

### [2026-03-21] HTML comment tags 比 YAML frontmatter 更适合 AI 知识标签
<!-- tags: knowledge, tags, ai-parsing -->
**Scenario**: 需要为知识条目添加可检索的标签元数据
**Lesson**: 使用 `<!-- tags: tag1, tag2 -->` HTML comment 格式优于 YAML frontmatter。原因：(1) 不影响 Markdown 渲染的可读性 (2) AI 解析简单（正则即可） (3) 与 Markdown 标题行紧邻，上下文关联清晰 (4) Git diff 友好
**Evidence**: 红队验收测试 41/41 通过，AI 能正确识别和匹配 HTML comment 中的 tags（knowledge-upgrade.acceptance.test.mjs:85-91）
