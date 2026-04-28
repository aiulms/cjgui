# P1 App Lifecycle State Construction 执行卡

日期: 2026-04-27

性质: docs-only execution card / short bounded implementation authorization / no runtime code

状态: 完成；创建本卡不等于实现

## 授权依据

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md)
- [2026-04-26-p1-app-lifecycle-surface-boundary_preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

## 决策

本卡只回应上一轮 fail-closed 暴露的构造能力缺口。

下一刀允许进入 bounded implementation：最多只修改 `runtime/cjgui/src/app_lifecycle.cj` 中 `CjguiInternalAppLifecycleState` 的构造 shape。

推荐方向：给 `CjguiInternalAppLifecycleState` 增加一个默认 internal 显式 `init`，参数只允许覆盖既有两个 `Bool` 字段：`isStateMachineActive` 与 `hasLifecyclePhase`。该 `init` 只能把参数赋给这两个字段，不得有任何副作用。

## 未来 Stop-line

- 不新增字段。
- 不新增 enum、`Result` type 或 phase taxonomy。
- 不新增 state-changing transition function。
- 不修改 no-op transition function。
- 不把默认状态改成 active。
- 不实现 run / shutdown / request quit / queue / drain。
- 不做 platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不允许 public runtime API、public C ABI、AppKit / Metal / Objective-C 引用。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## 未来验证

未来 first slice 必须先查证 CangjieSkills / 本地官方文档中的 struct `init`、field initialization、package、visibility 和 build 规则，并运行：

- `cjpm build`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

## 下一步 opening

`P1 app lifecycle state construction first slice`

本卡完成后默认进入 bounded implementation；除非发现 HIGH / CRITICAL 风险或 authority 冲突，不再新开 docs-only 入口替代实现。
