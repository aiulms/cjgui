# P1 Window Lifecycle State Shape Execution Card

日期: 2026-04-27

性质: docs-only / W1 short execution card

## Task Intent

创建本卡不等于实现。当前已有 `CjguiInternalWindowLifecycleState`，但 window state machine 尚未定义。

## Authority

- [2026-04-27-p1-first-internal-window-lifecycle-state-closure-review.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-closure-review.md)
- [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)

## Goal

未来 first slice 最多只能给 `CjguiInternalWindowLifecycleState` 增加一个不可变 `Bool` 字段。

推荐字段语义等价于 `hasWindowState: Bool = false`。该字段只表达 window state boundary exists，但 window state taxonomy 尚未定义。

## Write Set

未来 first slice 最大写入范围:

- [runtime/cjgui/src/window_lifecycle.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- future closure review
- [docs/plans/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md]
(/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Forbidden Scope / Stop-Line

不允许新增其他字段、enum、handle、handle table、generation、window create / request close / destroy / release 行为、platform object、native handle、raw pointer、AppKit / Metal / Objective-C 引用。

不允许修改 app lifecycle state / transitions，不允许 public runtime API、public C ABI、run / shutdown / queue / drain、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router。

不允许修改 `cjpm.toml`，不允许新增 `src/main.cj` 或 `package_anchor.cj`，不允许修改 smoke / harness / native bridge / 仓颉入口。

## Verification

未来 first slice 必须查证 CangjieSkills / 本地官方文档中的 struct field / package / visibility / build 规则，运行 `cjpm build` 和 smoke guard，并在 closure review 中记录 forbidden scope 检查。

## Next Implementation Expectation

> `P1 window lifecycle state shape first slice`

本卡完成后默认进入 bounded implementation; 除非发现 HIGH / CRITICAL 风险或 authority 冲突，不得再开新的 docs-only 入口。
