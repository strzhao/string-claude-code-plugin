# writer-skill

写作技能包。包含多种写作风格 Skill，让 AI 写出有个人味道的文章，而不是千篇一律的 AI 味。

## 包含的 Skill

### writer-blog-skill
科技博客向。叙事驱动、口语化、类比落地，适合公众号/个人博客等长文场景。

### writer-general-skill
通用写作向。（开发中）

## 方法论

参考宝玉AI提出的"写作风格 Skill"方法论：不是用提示词去 AI 味，而是给 AI 一份持续更新的"菜谱"，让它学会你的口味。

## 使用方式

安装插件后，根据场景调用对应的 Skill：
- 写博客/长文：`/writer-blog-skill`
- 通用写作：`/writer-general-skill`

## 迭代建议

每个 Skill 都是可以持续迭代的"菜谱"：

1. 让 AI 按 Skill 写一篇文章
2. 手动修改成你满意的样子
3. 对比差异，更新对应 Skill 的规则
4. 重复以上步骤
