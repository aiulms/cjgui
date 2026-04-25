# GUI 计划文档目录

这个目录用于存放后续的：

- preflight
- execution card
- approval gate
- closure review

命名建议：

- `YYYY-MM-DD-<topic>-preflight.md`
- `YYYY-MM-DD-<topic>-execution-card.md`
- `YYYY-MM-DD-<topic>-approval-gate.md`
- `YYYY-MM-DD-<topic>-closure-review.md`

这些文档只承载单次 bounded slice 的判断和封账，不承担长期总索引职责。

## 当前计划文档索引

长期入口仍以仓颉工作区根目录的 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 为准。

本目录当前已有：

- [2026-04-24-e0-cangjie-sdk-toolchain-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-24-e0-cangjie-sdk-toolchain-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结仓颉 SDK、本机工具链、`cjc` / `cjpm`、macOS SDK 兼容问题。

- [2026-04-25-p0-macos-bridge-runtime-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结 P0 macOS bridge smoke 的边界，允许在 `labs/macos_bridge_smoke/` 做最小窗口和 Metal 清屏验证。

- [2026-04-25-p0-macos-bridge-smoke-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：定义 P0 macOS bridge smoke 的 write set、stop-line、验证方式和执行边界。

- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P0 bridge smoke，记录自动关闭验证与人工视觉确认。

- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结 P1 AppKit / Metal 桥接边界，回答 FFI 生命周期、主线程 owner、错误处理哲学、capability query、构建复现和桥接窄接口。

- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 P1 bridge boundary cleanup 的 write set、owner、生命周期清理范围、错误返回口径、验证命令和 stop-line。

- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 bridge boundary cleanup，记录 landed code reality、验证结果、stop-line 和残留风险。

- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结未来后台任务、Agent action、runtime 异步更新 UI 回到 macOS 主线程的 enqueue / drain / stale message / lifecycle 规则。

- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)
  - 类型：execution card
  - 状态：完成；尚未实现
  - 用途：授权未来一个极窄的 `labs/macos_bridge_smoke` 内部单实例 lifecycle queue first slice，第一刀只建议支持 `RequestClose`。

## 当前下一篇计划文档

下一篇推荐：

- `P1 main-thread UI message queue bounded implementation first slice`

用途：

- 按 execution card 在 `labs/macos_bridge_smoke` 内实现单实例 lifecycle queue，并在完成后创建 closure review。

当前可执行动作：

- 当前没有自动开启的无限实现 opening。
- 如需继续推进，只能按 execution card 做 bounded implementation first slice，不能扩成正式 runtime。
