# P1 App Lifecycle No-op Transition 执行卡

日期：2026-04-27

性质：docs-only execution card / short bounded implementation authorization / no runtime code

状态：完成；创建本卡不等于实现

## 授权依据

- [2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md)
- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

## 决策

当前已有 `CjguiInternalAppLifecycleState` 和 `CjguiInternalAppLifecycleTransitionMarker`。

下一刀允许进入 bounded implementation：最多只在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 新增一个默认 internal no-op transition function。该函数只能证明包内可以承载 internal lifecycle transition function，不得改变 state，不得激活 state machine。

推荐语义：接收 `CjguiInternalAppLifecycleState` 并返回同一个 `CjguiInternalAppLifecycleState`。函数名必须体现 no-op / marker / internal transition，不得叫 `run`、`shutdown`、`requestQuit`、`drain` 或任何真实 lifecycle API。

## 未来 Stop-line

- 不允许 `public`、`import`、`enum`、`Result` type、public runtime API 或 public C ABI。
- 不修改 `isStateMachineActive` 的值或语义，不新增字段。
- 不实现 queue / drain / request quit / shutdown / run 行为。
- 不做 platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不引用 AppKit / Metal / Objective-C。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## 未来验证

未来 first slice 必须先查证 CangjieSkills / 本地官方文档中的 function / struct / package / visibility / build 规则，并运行：

- `cjpm build`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

## 下一步 opening

`P1 app lifecycle no-op transition first slice`

本卡完成后默认进入 bounded implementation；除非发现 HIGH / CRITICAL 风险或 authority 冲突，不再新开 docs-only 入口替代实现。
