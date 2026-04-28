# P1 App Lifecycle Phase Marker 执行卡

日期：2026-04-27

性质：docs-only execution card / short bounded implementation authorization / no runtime code

状态：完成；创建本卡不等于实现

## 授权依据

- [2026-04-27-p1-app-lifecycle-no-op-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-closure-review.md)
- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

## 决策

当前已有 `CjguiInternalAppLifecycleState`、`isStateMachineActive: Bool = false`、`CjguiInternalAppLifecycleTransitionMarker` 和 `cjguiInternalNoOpAppLifecycleTransition`。

下一刀允许进入 bounded implementation：最多只在 `runtime/cjgui/src/app_lifecycle.cj` 的 `CjguiInternalAppLifecycleState` 上新增一个默认 internal 的最小 phase marker / field。推荐方向是一个不可变 `Bool` 字段，语义等价于 `hasLifecyclePhase: Bool = false`。

该字段只表达 phase boundary exists；lifecycle phase taxonomy 尚未定义。

## 未来 Stop-Line

- 不允许 enum、`Result` type、string code / int code / category / severity。
- 不允许 `public`。
- 不修改 no-op transition function，不让 no-op transition 改变 state。
- 不把 `isStateMachineActive` 改成 true，不修改它的语义。
- 不实现 run / shutdown / request quit / queue / drain 行为。
- 不做 platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不允许 public runtime API、public C ABI、AppKit / Metal / Objective-C 引用。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## 未来验证

未来 first slice 必须先查证 CangjieSkills / 本地官方文档中的 struct field / package / visibility / build 规则，并运行：

- `cjpm build`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

## 下一步 opening

`P1 app lifecycle phase marker first slice`

本卡完成后默认进入 bounded implementation；除非发现 HIGH / CRITICAL 风险或 authority 冲突，不再新开 docs-only 入口替代实现。
