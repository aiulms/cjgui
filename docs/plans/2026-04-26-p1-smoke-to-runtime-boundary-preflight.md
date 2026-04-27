# P1 Smoke-to-runtime Boundary Preflight

日期：2026-04-26

性质：docs-only / smoke-to-runtime boundary preflight / no implementation

状态：完成；不批准直接实现

范围：冻结 `labs/macos_bridge_smoke` 与未来正式 runtime 的边界，避免把 smoke demo 顺手扩成正式 GUI runtime。本轮只判断哪些内容必须留在 smoke，哪些经验可以迁移为正式 runtime 约束，哪些 C ABI / bridge API 不能直接升格为 public runtime API，以及第一条正式 runtime opening 应如何最小化。本轮不创建 runtime 目录，不写 runtime 代码，不修改 `labs/macos_bridge_smoke`。

## 1. 背景

本轮依据：

- [P1 frame hash verification evidence line closure / runtime pivot preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)
- [P1 frame hash bounds / crop semantics readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)
- [P1 main-thread UI message queue closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
- [P1 AppKit / Metal bridge boundary cleanup closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [P0 macOS bridge smoke closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)

上一轮 evidence line 已经建议：screenshot / frame hash verification 线暂时收口，下一步 pivot 回 runtime 边界讨论。本轮只冻结 smoke 与未来 runtime 的迁移边界，不进入实现。

## 2. `labs/macos_bridge_smoke` 当前身份是什么

`labs/macos_bridge_smoke` 当前身份是：

> 一个实验室 smoke / lab evidence 项目，用于证明仓颉可以经由 C ABI 触达 Objective-C / AppKit / Metal，并验证若干 P1 边界假设。

它不是：

- 正式 GUI runtime。
- public runtime API。
- framework 目录。
- Renderer / Scene / Widget / Layout 原型。
- 视觉回归测试框架。
- 跨平台 backend。

当前 smoke 的主要价值是让项目拥有一条真实、可复核、可封账的 macOS 桥接链路：

- 仓颉入口调用 C ABI。
- Objective-C bridge 创建 AppKit window 和 Metal layer。
- Metal 清屏与最小 capability check 可运行。
- 单实例 lifecycle queue 的 `RequestClose` 可以经主线程 drain 进入 close / destroy。
- 自动关闭、日志 harness、Metal readback、screenshot verification、frame hash readiness diagnostics 能作为 smoke guard。

这些价值都属于 evidence / constraint，不等于 runtime API。

## 3. 必须永远只作为 Smoke / Lab Evidence 的内容

以下内容不得直接迁移为正式 runtime：

- smoke 的目录结构 `labs/macos_bridge_smoke`。
- smoke 的 `scripts/build_and_run.sh`。
- smoke 的 C ABI 形态。
- smoke 的仓颉入口 `src/main.cj` 调用形态。
- smoke 的单实例全局状态假设。
- smoke 的单窗口假设直接升级为长期 runtime。
- smoke 的 auto-close 行为。
- smoke 的 clear-color render path。
- smoke 的 frame metadata / render stats 日志格式。
- smoke 的 Metal readback diagnostics 字段。
- smoke 的 screenshot / frame hash diagnostics 字段。
- smoke 的 artifact cleanup / retention shell harness 形态。
- smoke 的 `last_error` 全局错误语义。
- smoke 的 verification harness 直接升级为 runtime test framework。

这些内容可以继续服务 smoke 证据，但不能在没有新 execution card 的情况下进入 runtime 目录、public C ABI 或 public runtime API。

## 4. 可以迁移为未来 Runtime 设计约束的经验

以下经验可以迁移为未来正式 runtime 的约束，但迁移的是原则，不是当前代码形态：

- macOS UI 必须有主线程 owner。
- 后台任务、async runtime、Agent action 未来更新 UI 必须经过主线程 queue / drain。
- lifecycle close / destroy 必须受控，避免 auto-close、manual-close、future async message 三者竞态。
- 平台对象不能裸露给仓颉公共层。
- public API 不应直接暴露 `NSWindow*`、`NSView*`、`CAMetalLayer*`、`MTLDevice*`、`id`、`CGImageRef` 等平台对象。
- AppKit / Metal dirty work 可以留在平台 bridge 内部，但向上接口必须极窄、脱水、可测试。
- `last_error` 实验期 C ABI 不能扩展成长期并发错误系统。
- capability check、recoverable / degraded 日志和 fail-fast 边界需要进入正式 runtime 的错误哲学。
- verification harness 可以作为 smoke guard，但不代表正式 visual regression。
- frame hash / screenshot / baseline / pixel diff 暂时收口，不作为 runtime 第一刀。

这些约束应在未来 runtime preflight / execution card 中重新表达为 owner、truth、write set、ABI 和 verification rules。

## 5. 当前 C ABI / Bridge API 不能直接升格为 Public Runtime API

当前 smoke 中的下列 C ABI / bridge API 不能直接升格：

- `cjgui_app_run()`：当前绑定单窗口、单实例、AppKit event loop 和 smoke render path；不能作为长期 public runtime entry。
- `cjgui_last_error_code()`、`cjgui_last_error_category()`、`cjgui_last_error_message()`：当前只是实验期全局 last-error 观察口，不适合并发、多窗口、异步 runtime。
- 当前内部 bridge context：它持有 `NSWindow`、Metal view、`CAMetalLayer`、`MTLDevice`、`MTLCommandQueue` 等平台对象，只能留在 bridge 内部。
- 当前 lifecycle queue：只支持单实例 `RequestClose`，没有 handle table / generation / target update，不足以成为正式 async UI message queue。
- 当前 Metal readback / screenshot / frame hash diagnostics：这些是 verification evidence，不是 runtime API。

未来 public runtime API 至少需要另行回答：

- app owner 是谁。
- window handle 如何创建、验证和销毁。
- destroyed / stale handle 如何处理。
- 多窗口是否允许。
- 错误如何结构化返回。
- 平台对象如何隐藏。
- 主线程 queue 如何暴露或隐藏。

在这些问题冻结前，当前 C ABI 只能作为 smoke bridge API。

## 6. Verification Harness 能不能成为正式 Runtime Test Framework

不能。

当前 harness 的正确定位是：

> smoke guard。

它可以继续用于验证 smoke 没有倒退，例如：

- `verify_auto_close.sh` 复核 build、capability、lifecycle、frame metadata、Metal readback 和返回码。
- screenshot feasibility / verification harness 复核当前本机用户可见窗口证据线。
- frame hash / baseline readiness / source normalization / bounds diagnostics 复核“仍未允许 baseline / pixel diff”的负向护栏。

它不能成为正式 runtime test framework，因为：

- 它绑定 `labs/macos_bridge_smoke` 目录和脚本形态。
- 它绑定当前本机 macOS screenshot / CoreGraphics 环境。
- 它不是 CI / headless proof。
- 它不覆盖多窗口、resize、event routing、renderer scheduling、state truth、layout 或 widget。
- 它不应把 screenshot / frame hash diagnostics 字段升格为 runtime truth。

未来正式 runtime test framework 需要另开 preflight，不能从 smoke harness 自动继承。

## 7. 是否需要新目录承载正式 Runtime

结论：需要倾向于新目录，但本轮只讨论，不创建目录。

原因：

- `labs/` 语义就是实验室，不应承载正式 runtime。
- 继续扩写 `labs/macos_bridge_smoke` 会让 smoke demo 逐步变成半正式框架，边界变脏。
- 正式 runtime 需要清楚的 module owner、public API、internal bridge、tests、examples 和 docs 边界。
- smoke 的 build script、diagnostics 和 verification harness 应继续作为 guard，不应成为 runtime 目录结构。

未来新目录的名称、层次和 build entry 必须另开 docs-only preflight 冻结。本轮不创建目录，不移动文件，不改 build script。

## 8. 第一条正式 Runtime Opening 应先聚焦什么

第一条正式 runtime opening 应优先聚焦：

> minimal app / window lifecycle runtime boundary

而不是：

- Renderer。
- Scene。
- Widget。
- Layout。
- DSL。
- Text / IME / accessibility。
- pixel diff / baseline。
- cross-platform abstraction。

原因：

- app / window lifecycle 是 runtime 底座，决定主线程 owner、event loop、window creation、close / destroy、error return 和 platform object hiding。
- Renderer / Scene / Widget 都需要依赖稳定 window lifecycle 和 platform bridge boundary。
- 先做高层 API 会让入口层反逼底层。
- 当前 smoke 已经证明单窗口实验链路可行，但还没有正式 runtime 的 app/window owner contract。

## 9. 未来正式 Runtime 最小第一刀应避免的诱惑

未来 first slice 必须避免：

- 顺手迁移 smoke 目录。
- 顺手复用 smoke C ABI 当 public API。
- 顺手设计 `Window` / `Renderer` / `Scene` / `Widget` / `Layout`。
- 顺手添加 DSL。
- 顺手支持多窗口。
- 顺手支持通用 async UI update。
- 顺手做 pixel diff / baseline。
- 顺手把 screenshot harness 当 runtime tests。
- 顺手暴露 native handle 或平台对象。
- 顺手做跨平台 backend。
- 顺手打开文本、输入法、无障碍。
- 顺手引入 AI semantic tree / Action Router。

第一刀应只冻结或授权 app / window lifecycle 的最小边界，并清楚说明哪些只是 future slot。

## 10. 当前是否可以开始写 Runtime Implementation

不可以。

当前只能得出：

- smoke-to-runtime boundary 已经完成 docs-only preflight。
- smoke demo 不应继续扩写成 framework。
- 下一步应创建更窄的 docs-only runtime boundary preflight 或 execution card。

如果要进入任何 runtime implementation，必须先有：

- 明确 execution card。
- 明确 write set。
- 明确 forbidden write set。
- 明确 public API 是否允许。
- 明确是否创建新目录。
- 明确验证方式。
- 明确 stop-line。

没有这些，不允许写 runtime 代码。

## 11. Smoke-to-runtime 之后的 Next Opening

推荐下一条 docs-only opening：

> `P1 minimal app/window lifecycle runtime boundary preflight`

等价标题：

> `P1 minimal macOS app/window lifecycle runtime boundary preflight`

该 opening 只应冻结：

- future runtime app owner。
- window lifecycle owner。
- main-thread event loop / queue boundary。
- create / close / destroy 的最小 contract。
- platform object hiding。
- error return strategy。
- smoke guard 如何继续验证迁移不破坏旧链路。
- 是否需要 execution card 才能创建 runtime 目录。

它不应进入 Renderer / Scene / Widget / Layout / DSL。

## 12. 本轮 Stop-line

本轮强制保持：

- 不写 runtime 代码。
- 不创建正式 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 harness。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本 / 输入法 / 无障碍。
- 不引入 AI semantic tree / Action Router。
- 不做 pixel diff / baseline / offscreen renderer。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 13. 结论

本轮结论：

- `labs/macos_bridge_smoke` 继续定位为实验室 smoke，不是正式 runtime。
- 不建议继续把 smoke demo 扩写成 framework。
- smoke 中的经验可以迁移为未来 runtime 约束，但代码、目录、C ABI 和 diagnostics 字段不能默认迁移为 public API。
- 当前 verification harness 只作为 smoke guard，不是正式 runtime test framework。
- 正式 runtime 应另开边界，避免污染 lab。
- 下一步推荐 docs-only `P1 minimal app/window lifecycle runtime boundary preflight`。

当前没有自动开启的直接实现 opening。
