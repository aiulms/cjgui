# P1 App Lifecycle Transition Boundary 执行卡

日期: 2026-04-27

性质: docs-only execution card / short decision card / no runtime code

状态: 完成; 创建本卡不等于实现

## 授权依据

- [2026-04-27-p1-app-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md)
- [2026-04-26-p1-app-lifecycle-surface-boundary_preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

## 决策

当前 `CjguiInternalAppLifecycleState` 只有 `isStateMachineActive: Bool = false`，不代表 state machine 已定义。

下一刀允许进入 bounded implementation: 最多只在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 新增一个默认 internal、无 `public`、无 import 的 transition marker / no-op transition marker。推荐形式是默认 internal 空 marker type，语义类似 `CjguiInternalAppLifecycleTransitionMarker`，只表达 transition boundary exists but transition behavior is not yet defined。

本卡默认不授权函数; 如果下一刀想选择函数, 必须 fail closed, 除非另有单独授权。

## 未来 Stop-line

- 不修改 `isStateMachineActive` 的值或语义。
- 不新增第二个 state 字段。
- 不允许 `public`、import、函数、方法、显式 init、构造逻辑或 runtime behavior。
- 不实现 `run` / `shutdown` / `request quit` / queue / drain。
- 不做 platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不定义 public runtime API 或 public C ABI。
- 不引用 AppKit / Metal / Objective-C。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## 未来验证

未来 first slice 必须先查证 CangjieSkills / 本地官方文档中的 struct / package / visibility / build 规则，并运行:

- `cjpm build`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

## 下一步 opening

`P1 app lifecycle transition marker first slice`

本卡完成后默认进入 bounded implementation; 除非发现 HIGH / CRITICAL 风险或 authority 冲突，不再新开 docs-only 入口替代实现。
