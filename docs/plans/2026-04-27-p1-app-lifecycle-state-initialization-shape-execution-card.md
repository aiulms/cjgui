# P1 App Lifecycle State Initialization Shape 执行卡

日期: 2026-04-27

性质: docs-only decision / execution card / W1 light slice / no runtime code

状态: 完成；创建本卡不等于实现

## Task Intent / Prompt Weight

- task intent: architecture_decision / bounded implementation authorization
- prompt weight: W1 light slice

## Authority

- [2026-04-27-p1-app-lifecycle-state-construction-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md)
- [2026-04-27-p1-app-lifecycle-state-construction-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-execution-card.md)

## Goal

本卡只回应上一轮 fail-closed 暴露出的 immutable default field / explicit init 冲突。

下一刀允许修改 `CjguiInternalAppLifecycleState` 的 initialization shape。推荐从字段默认值初始化改为主构造或等价构造期初始化 shape。目标是保留两个 immutable Bool facts, 同时允许构造不同取值的 state。

## Considered Routes

- 保持 `let + 默认值`: 安全, 但继续阻塞 state-changing transition。
- 改成构造期初始化 shape: 推荐; 保留 immutable facts, 同时允许构造不同 state。
- 改成 `var`: 当前不推荐; 太早打开可变 state。

## Write Set

未来 first slice 最多只能修改:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- future closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Forbidden Scope / Stop-line

- 不改成 `var`。
- 不新增字段。
- 不新增 enum、`Result` type 或 phase taxonomy。
- 不新增真实 lifecycle API。
- 不新增 state-changing transition function; transition 后续单独执行。
- 不修改 no-op transition function。
- 不实现 run / shutdown / request quit / queue / drain。
- 不做 platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不允许 public runtime API、public C ABI、AppKit / Metal / Objective-C 引用。
- 不修改 `cjpm.toml`, 不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## Verification

未来 first slice 必须:

- 查证 CangjieSkills / 本地官方文档中的 struct primary constructor / explicit init / immutable field initialization / package / visibility / build 规则。
- 先用最小临时探针验证语法, 再落正式代码。
- 运行 `cjpm build`。
- 运行 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- 运行 `git diff --check`。

## Next Implementation Expectation

`P1 app lifecycle state initialization shape first slice`

本卡完成后默认进入 bounded implementation; 除非发现 HIGH / CRITICAL 风险或 authority 冲突, 不再新开 docs-only 入口替代实现。
