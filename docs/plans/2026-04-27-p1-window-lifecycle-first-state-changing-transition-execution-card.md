# P1 window lifecycle first state-changing transition execution card

日期: 2026-04-27

类型: execution card / W1 short card
状态: 完成；创建本卡不等于实现

## Task Intent

授权下一刀新增第一个真实但无副作用的 internal window lifecycle state-changing transition: 只把 returned state 的 `hasWindowState` 推进为 `true`。

## Authority

- [P1 window lifecycle construction + no-op transition closure review]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-construction-no-op-transition-closure-review.md)
- [P1 window lifecycle surface boundary preflight]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)

## Goal

当前已有 `CjguiInternalWindowLifecycleState`、`hasWindowState: Bool`、构造期初始化能力和默认 internal no-op window transition。

未来 first slice 最多只能新增一个默认 internal state-changing transition function。该函数必须接收 `CjguiInternalWindowLifecycleState` 并返回 `CjguiInternalWindowLifecycleState`。

唯一允许的 state change: 返回一个 `hasWindowState = true` 的 state。

## Write Set

未来 first slice 最大 write set:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-first-state-changing-transition-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Forbidden Scope / Stop-line

不允许: 定义 window state taxonomy、enum、handle、handle table、generation、window create / request close / destroy / release 行为、platform object、native handle、raw pointer、AppKit / Metal / Objective-C 引用、修改 app lifecycle state / transitions、修改 no-op window transition、public runtime API、public C ABI、run / shutdown / queue / drain、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、修改 `cjpm.toml`、新增 `src/main.cj` 或 `package_anchor.cj`、修改 smoke / harness / native bridge / 仓颉入口。

## Verification

未来 first slice 必须:

- 查证 CangjieSkills / 本地官方文档中的 function / struct construction / package / visibility / build 规则。
- 运行 `cjpm build --target-dir /tmp/cjgui-window-lifecycle-first-state-changing-transition-target --skip-script`。
- 运行
`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- 检查没有 taxonomy、enum、handle / handle table / generation、create / request close / destroy / release 行为、platform object / native handle / raw pointer、public API / C ABI、app lifecycle 修改、no-op transition 修改、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`。
- `git diff --check` 必须通过。

## Next Implementation Expectation

`P1 window lifecycle first state-changing transition first slice`

本卡完成后默认进入 bounded implementation；不得再开新的 docs-only 入口，除非发现 HIGH / CRITICAL 风险或 authority 冲突。
