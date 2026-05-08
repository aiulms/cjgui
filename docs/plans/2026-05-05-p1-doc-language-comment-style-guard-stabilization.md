# P1 文档语言与 owner 注释风格护栏稳定化

日期：2026-05-05

状态：docs-only / governance stabilization

## 背景

近期 renderer backend 计划链在进入 native bridge、platform object、Metal device-layer 和 real command queue implementation admission 后，部分新增 Markdown 文档开始整段使用英文标题和英文正文，例如 `Decision`、`Boundary`、`Verification`、`Next Opening` 等模板词被直接写入文档结构。

同时，部分新增 `.cj` owner file 的文件头维护注释开始变薄，甚至省略 owner / truth / stop-line / Same-shape Boundary Brake 说明。这个漂移不是 runtime 语义变化，而是执行提示词没有显式锁定中文文档风格和 owner 文件头注释要求。

## 稳定化结论

从本护栏生效后，CJGUI 的计划文档、closure review、manifest、README 同步段和 tracker 同步段默认使用中文写作。

允许保留英文的范围仅限：

- 代码符号、类型名、函数名、文件路径和命令。
- API / SDK / toolchain / Metal / AppKit / Objective-C / FFI / C ABI 等固定技术名词。
- `Same-shape Boundary Brake`、`owner`、`truth`、`stop-line`、`preflight`、`manifest`、`closure`、`next opening` 等项目内已经稳定的治理术语。
- 引用原始英文资料时的标题或短语。

不再允许：

- 新增文档整段英文写作。
- 使用 `Decision`、`Boundary`、`Verification`、`Next Opening` 作为主要章节标题。
- 把执行提示词里的英文模板直接复制成文档结构。
- 为了避免 stop-line scan 而完全省略 `.cj` owner 文件头注释。

## Markdown 标题规则

新增或修改的计划文档默认使用中文标题，例如：

- `## 决策结论`
- `## 边界结论`
- `## 候选比较`
- `## Same-shape Boundary Brake`
- `## 验证结果`
- `## 唯一 next opening`

如果必须保留英文术语，应以中文句子承载，而不是整段英文模板化写作。

## `.cj` owner 注释规则

新增 internal-only owner file 必须保留最小文件头维护注释。注释可以简短，但不能省略，至少覆盖：

- `Owner`：本文件负责的 owner 边界。
- `Truth`：唯一 runtime input、canonical endpoint 和输出 truth 范围。
- `Stop-line`：明确不创建、不调用、不写入的资源 / bridge / GPU / public surface。
- `Same-shape Boundary Brake`：说明新增语义是什么，为什么不是上一层 readiness 的 permission wrapper / receipt / record / publication。

注释默认使用中文，必要英文技术名词可以保留原文。注释不应给机械赋值、字段搬运或显然的构造器写空注释；重点应放在 owner、truth、fail-closed / inconsistent 分支、default draft / executor 和 stop-line 上。

## 执行提示词固定块

后续所有涉及 Markdown 或新增 `.cj` owner 的执行提示词，都必须包含或等价表达以下约束：

```text
语言与注释约束：
- 所有新增 / 修改的 Markdown 文档正文必须使用中文。
- Markdown 章节标题必须使用中文；不要使用 Decision / Boundary / Verification / Next Opening 作为主标题。
- 英文只允许用于代码符号、文件路径、API 名称、工具命令和固定治理术语。
- 新增 `.cj` owner 文件必须保留文件头维护注释，至少说明 Owner / Truth / Stop-line / Same-shape Boundary Brake。
- 注释可以简短，但不能完全省略；注释不得引入真实 implementation permission。
```

## 与当前 renderer runway 的关系

本轮只修正治理风格护栏，不改变当前 renderer / backend implementation runway。

当前 next opening 仍以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 为准。最新 active opening 仍是 `P1 internal Renderer real drawable implementation admission value boundary bundle implementation`。

## 验证要求

本类 docs-only 护栏更新应至少验证：

- `git diff --check`
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- forbidden check：无 `.cj` runtime code diff、无 protected path diff/status，`runtime_state.cj` 行数不变
- public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`
