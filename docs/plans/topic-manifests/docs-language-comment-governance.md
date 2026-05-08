# 文档语言与 owner 注释治理

状态：docs-only / governance topic manifest

## 主题定位

本主题固定 CJGUI plans / closure / manifest / README / tracker 的中文文档写作规则，以及后续新增 `.cj` owner 文件头维护注释要求。

## 当前状态

文档语言与 owner 注释风格护栏已通过 [P1 文档语言与 owner 注释风格护栏稳定化](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 落地，并写入 [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)。

## 已落地现实

- 新增或修改 Markdown 默认中文正文。
- Markdown 章节标题默认中文。
- 英文只用于代码符号、文件路径、API 名称、工具命令、上游资料标题和固定治理术语。
- 新增 `.cj` owner 文件必须保留文件头维护注释，至少覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。
- closure 文档应包含设计意图出口自检，避免 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 与 topic manifest 滞后。

## 未落地与明确禁止

- 不允许把执行提示词中的 `Decision`、`Boundary`、`Verification`、`Next Opening` 等英文模板直接落成主标题。
- 不允许整段英文模板化写作。
- 不允许为了避开 stop-line scan 而省略 owner 文件头维护注释。
- 注释不得把 admission facts 写成真实 implementation permission。

## 当前 owner 链摘要

本主题没有 runtime owner。它是 docs governance 入口，约束后续计划文档与新增 `.cj` owner 注释风格。

## 关键文档链

- [doc language guard stabilization](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)
- [design intent navigation exit protocol](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [plans README](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## 下次开 gate 前必须读取

涉及新增或修改 Markdown、closure review、manifest、README 同步段、tracker 同步段或新增 `.cj` owner 文件时，必须读取本 manifest 或 doc language guard stabilization。

## 推荐下一步

保持本治理护栏。后续若发现英文模板漂移、owner 注释缺失或 Same-shape Boundary Brake 注释变薄，优先做 docs-only governance correction，不改变 runtime next opening。

## 禁止误读点

- 中文写作规则不改变 runtime truth。
- owner 文件头注释是维护边界，不是实现许可。
- 验证应包含中文标题与中文正文抽查、owner header scan，以及必要时的设计意图出口自检。

## 维护备注

本主题随文档风格规则变化而更新。若未来新增更严格的 lint / scan，也应先以 docs-only 方式记录验证范围。
