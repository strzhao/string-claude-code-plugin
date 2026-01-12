# Claude Code Plugins Collection

<div align="center">

**会员业务私域 Claude Code 插件集合**

[![Plugins](https://img.shields.io/badge/plugins-1-blue.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)](https://claude.ai/code)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

</div>

---

## 📖 项目简介

本仓库收集了一系列高质量的 **Claude Code 插件**，旨在通过 AI 辅助提升开发效率和代码质量。

### 🎯 设计理念

- **专业化**：每个插件专注于特定领域，提供深度优化的解决方案
- **易用性**：简化配置流程，降低团队推广成本
- **实时性**：通过 MCP 动态获取数据，确保信息准确性
- **可扩展**：清晰的架构设计，便于二次开发和定制

---

## 📦 插件列表

---

## 🚀 快速开始

### 方案一：插件市场安装
https://g.hz.netease.com/cloudmusic-agi/plugins/vip-claude-code-plugin.git
在 Claude Code 中执行，添加以下 git 仓库为插件市场来源

`/plugin marketplace add https://g.hz.netease.com/cloudmusic-agi/plugins/vip-claude-code-plugin.git`

![alt text](https://p6.music.126.net/obj/wonDlsKUwrLClGjCm8Kx/77480383284/54b4/b5cb/d12e/cc0df2244d1c9730665b2d5cdb4400b0.png)


安装完成后重启 claude code。


### 方案二：本地安装流程

#### 1️⃣ 克隆仓库

```bash
git clone <repository-url>
cd vip-claude-code-plugin
```

#### 2️⃣ 安装插件

```bash
# 复制插件到 Claude Code 插件目录
cp -r plugins/article-summarizer ~/.claude/plugins/
```


#### 3️⃣ 重启 Claude Code

重启后插件会自动加载生效。

---

## 📂 项目结构

```
vip-claude-code-plugin/
├── README.md                           # 本文档
├── .gitignore                          # Git 忽略规则
│
└── plugins/                            # 插件目录
    └── article-summarizer/             # 文章摘要生成器
        ├── .claude-plugin/             # 插件配置目录
        │   └── plugin.json             # 插件元数据
        └── skills/                     # Skill 技能
            └── article-summarizer/
                ├── SKILL.md            # AI 行为指南
                ├── assets/             # 模板资源
                │   └── summary_template.md  # 摘要模板
                ├── references/         # 参考指南
                │   └── content_extraction_guidelines.md  # 内容提取指南
                └── scripts/            # 辅助工具
                    └── content_extractor.py  # 内容提取器
```

## 🤝 贡献指南

欢迎贡献新插件或改进现有插件！

### 贡献流程

1. **Fork 仓库**
2. **创建特性分支**：
   ```bash
   git checkout -b plugin/your-plugin-name
   ```
3. **开发插件**：
   - 遵循项目结构规范
   - 编写完整的 README.md
   - 提供安装和配置指南
4. **测试验证**：
   - 在本地 Claude Code 中测试
   - 确保文档准确性
5. **提交 PR**：
   - 详细描述插件功能
   - 附上使用截图或演示

### 插件提交清单

- [ ] 完整的 `.claude-plugin/plugin.json`
- [ ] 详细的 `README.md`（包含使用示例）
- [ ] 清晰的 `SKILL.md`（定义明确的角色和工作流程）
- [ ] 必要的 `install.sh`（MCP 插件必需）
- [ ] 在本地 Claude Code 中测试通过
- [ ] 文档准确无误
- [ ] 遵循项目的目录结构规范