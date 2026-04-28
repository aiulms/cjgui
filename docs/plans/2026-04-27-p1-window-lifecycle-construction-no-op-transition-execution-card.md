# P1 window lifecycle construction + no-op transition execution card

日期: 2026-04-27

类型: execution card / W1 short card
状态: 完成；创建本卡不等于实现

## Task Intent

授权下一刀在 window lifecycle 中做一个 combined internal slice: 同时补齐 `CjguiInternalWindowLifecycleState` 的构造期初始化能力，并新增一个默认 internal no-op window lifecycle transition function。

## Authority

- [P1 window lifecycle state shape closure review]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-state-shape-closure-review.md)
- [P1 window lifecycle surface boundary preflight]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)

## Goal

未来 first slice 最多只能做两个小动作:

- 修改 `CjguiInternalWindowLifecycleState` 的 initialization shape。
- 新增一个默认 internal no-op window lifecycle transition function。

Initialization shape 只能保留现有 immutable Bool fact: `hasWindowState`。推荐增加无参 `init()` 和带参 `init(hasWindowState: Bool)`，或等价构造期初始化 shape；不得改成 `var`，不得新增字段。

No-op transition function 必须接收 `CjguiInternalWindowLifecycleState` 并返回同一个 state；不得修改 state。函数名必须体现 internal / no-op / window lifecycle transition 语义，不得叫 `create`、`requestClose`、`destroy`、`release` 或任何真实 window lifecycle API。

## Write Set

未来 first slice 最大 write set:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-construction-no-op-transition-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Forbidden Scope / Stop-line

不允许: `var`、新增字段、enum、handle、handle table、generation、window create / request close / destroy / release 行为、platform object、native handle、raw pointer、AppKit / Metal / Objective-C 引用、修改 app lifecycle state / transitions、public runtime API、public C ABI、run / shutdown / queue / drain、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、修改 `cjpm.toml`、新增 `src/main.cj` 或 `package_anchor.cj`、修改 smoke / harness / native bridge / 仓颉入口。

## Verification

未来 first slice 必须:

- 查证 CangjieSkills / 本地官方文档中的 struct init / function / package / visibility / build 规则。
- 先用 `/tmp` 最小临时探针验证 construction syntax。
- 运行 `cjpm build --target-dir /tmp/cjgui-window-lifecycle-construction-no-op-transition-target --skip-script`。
- 运行
`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- 检查没有 `var`、新增字段、enum、handle / handle table / generation、create / request close / destroy / release 行为、platform object / native handle / raw pointer、public API / C ABI、app lifecycle 修改、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`。
- `git diff --check` 必须通过。

## Next Implementation Expectation

`P1 window lifecycle construction + no-op transition first slice`

本卡完成后默认进入 bounded implementation；不得再开新的 docs-only 入口，除非发现 HIGH / CRITICAL 风险或 authority 冲突。
