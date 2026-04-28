# P1 First Internal Window Lifecycle State Execution Card

日期: 2026-04-27

性质: docs-only / W1 short execution card

## Task Intent

创建本卡不等于实现。本卡把推进方向从 app lifecycle mini-slice pivot 到 window lifecycle。

## Authority

- [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)
- [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)

## Goal

未来 first slice 最多只能在 [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj) 新增一个默认 internal window lifecycle state marker / placeholder type。

推荐形式是空 `struct`, 语义类似 `CjguiInternalWindowLifecycleState`。它只能表达:

> window lifecycle state boundary exists but window state machine is not yet defined.

## Write Set

未来 first slice 最大写入范围:

- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- future closure review
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Forbidden Scope / Stop-Line

不允许字段、enum、handle、handle table、generation、window create / request close / destroy / release 行为、platform object、native handle、raw pointer、AppKit / Metal / Objective-C 引用。

不允许修改 app lifecycle state / transitions, 不允许 public runtime API、public C ABI、run / shutdown / queue / drain、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router。

不允许修改 `cjpm.toml`, 不允许新增 `src/main.cj` 或 `package_anchor.cj`, 不允许修改 smoke / harness / native bridge / 仓颉入口。

## Verification

未来 first slice 必须查证 CangjieSkills / 本地官方文档中的 struct / package / visibility / build 规则, 运行 `cjpm build` 和 smoke guard, 并在 closure review 中记录 forbidden scope 检查。

## Next Implementation Expectation

当前 next opening:

> `P1 first internal window lifecycle state first slice`

本卡完成后默认进入 bounded implementation; 除非发现 HIGH / CRITICAL 风险或 authority 冲突, 不得再开新的 docs-only 入口。
