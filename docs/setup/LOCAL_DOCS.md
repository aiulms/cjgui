# 仓颉本地文档索引

最后更新：2026-04-24

## 已经下载到本地的内容

### 本地文档源仓库

- [cangjie_docs_1.1](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_docs_1.1)
  - 源仓库：`https://gitcode.com/Cangjie/cangjie_docs.git`
  - 分支：`release/1.1`
  - 用途：语言指南、开发指南、工具链文档、版本说明

- [cangjie_runtime_1.1](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_runtime_1.1)
  - 源仓库：`https://gitcode.com/Cangjie/cangjie_runtime.git`
  - 分支：`release/1.1`
  - 用途：标准库文档和运行时源码

- [cangjie_stdx_1.1](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_stdx_1.1)
  - 源仓库：`https://gitcode.com/Cangjie/cangjie_stdx.git`
  - 分支：`release/1.1`
  - 用途：stdx 扩展库源码和相关资料

- [docs_cangjie_master](/Users/jiangxuanyang/Desktop/cangjie/sources/docs_cangjie_master)
  - 源仓库：`https://gitcode.com/openharmony-sig/docs_cangjie.git`
  - 分支：`master`
  - 用途：HarmonyOS / ArkUI / 仓颉应用开发文档

### 本地辅助仓库

- [CangjieSkills](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills)
  - 源仓库：`https://gitcode.com/Cangjie-SIG/CangjieSkills.git`
  - 用途：面向 AI 编程工具的现成技能包结构

- [DocFlow](/Users/jiangxuanyang/Desktop/cangjie/repos/DocFlow)
  - 源仓库：`https://gitcode.com/Cangjie-SIG/DocFlow.git`
  - 用途：把文档蒸馏成本地 JSON 知识库，适合做 RAG / 文档生成

### 本地 GUI 参考仓库

- [wgpui-openagents](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/wgpui-openagents)
  - 对应站点：`https://docs.openagents.com/wgpui`
  - 当前提交：`bc63772`
  - 用途：参考 `WGPUI` 的组件思路、渲染组织和工程结构

- [gpui-zed](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/gpui-zed)
  - 对应站点：`https://www.gpui.rs/`
  - 当前提交：`f2e9c5a`
  - 用途：参考 `GPUI` 的桌面框架分层、事件与渲染设计

- [flutter](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/flutter)
  - 源仓库：`https://github.com/flutter/flutter`
  - 当前提交：`aeb96234`
  - 用途：参考大规模跨平台 UI 框架的工程组织和工具链设计

- [qt-therecipe](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/qt-therecipe)
  - 源仓库：`https://github.com/therecipe/qt`
  - 当前提交：`c0c124a`
  - 用途：参考传统桌面 GUI 绑定层和封装方式

## 这两个仓库为什么重要

### CangjieSkills

这个仓库很有用。

它已经包含了一套整理好的 skill 层级结构，主要在这里：

- [`.agents/skills`](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills)

其中比较重要的子技能有：

- `cangjie-original-docs`
- `cangjie-lang-features`
- `cangjie-std`
- `cangjie-stdx`
- `cangjie-toolchains`

这个仓库最有价值的地方在于：

- 可以参考它的 skill 目录组织方式
- 可以参考它的写法风格
- 可以参考它如何按主题拆知识

### DocFlow

这个仓库也很有用。

它不是 skill 包，而是“知识蒸馏工具”。
它可以把 Git 仓库里的文档加工成 `RAG_Lite/` 里的本地 JSON 知识库。

它的价值在于：

- 能作为本地文档摄入管线
- 能减少未来重复访问网页
- 能作为我们后面自建仓颉 skill 之前的知识预处理层

## 当前最适合本地查阅的路径

### 语言与构建文档

- [开发指南中文目录](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_docs_1.1/docs/dev-guide/source_zh_cn)
- [工具链中文目录](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_docs_1.1/docs/tools/source_zh_cn)
- [版本说明](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_docs_1.1/release-notes)

### 标准库文档

- [标准库总览](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_runtime_1.1/stdlib/doc/libs/std/std_module_overview.md)
- [标准库文档根目录](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_runtime_1.1/stdlib/doc/libs/std)

### HarmonyOS / ArkUI / 仓颉应用文档

- [仓颉应用文档中文根目录](/Users/jiangxuanyang/Desktop/cangjie/sources/docs_cangjie_master/zh-cn)

### GUI 参考代码根目录

- [reference_repos](/Users/jiangxuanyang/Desktop/cangjie/reference_repos)

## 后续最推荐的路线

如果我们要做自己的 skill，当前最合理的路线是：

1. 先把这些本地 Git 仓库当成长期真相源。
2. 参考 `CangjieSkills` 的组织方式，不重新发明目录结构。
3. 如果需要更快检索，再用 `DocFlow` 生成更紧凑的本地知识库。
4. 最后再做一个真正面向我们长期目标的仓颉 skill，重点服务：
   - 语言查询
   - std / stdx 查询
   - 工具链查询
   - GUI 框架项目知识

## 对未来自建 skill 的命名建议

与其做一个很泛的 skill，不如做一个真正贴合我们长期工作的专用 skill，比如：

- `cangjie-local-docs`
- `cangjie-gui-lab`

这样它就可以优先查本地文件，只有在本地没有答案时再回退到网页。
