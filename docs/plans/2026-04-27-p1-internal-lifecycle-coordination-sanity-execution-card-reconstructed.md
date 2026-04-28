# P1 internal lifecycle coordination sanity execution card

日期: 2026-04-27

类型: execution card / W1 light internal concept slice

## Task Intent

bounded implementation authorization. 创建本卡不等于实现。

## Prompt Weight

W1 light internal concept slice: 下一刀只新增一个默认 internal sanity function，用现有默认 internal types / constructors / coordination function 做最小链路调用；不新增 owner、public contract、平台桥接或 runtime behavior。

## Authority

- [2026-04-27-p1-internal-lifecycle-coordination-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-closure-review.md)

## Goal

授权下一刀新增一个默认 internal sanity function。该 function 构造最小 platform fact / app state / window state，调用 `cjguiInternalCoordinateLifecycleFromPlatformFact`，并返回 `CjguiInternalLifecycleCoordinationResult`。

## Write Set

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Allowed Implementation Shape

- 可以新增一个默认 internal function。
- 可以构造 `CjguiInternalPlatformAdapterFact(true)` 或等价最小 fact。
- 可以构造默认 `CjguiInternalAppLifecycleState()` 与 `CjguiInternalWindowLifecycleState()`。
- 可以调用现有 `cjguiInternalCoordinateLifecycleFromPlatformFact`。
- 可以返回 `CjguiInternalLifecycleCoordinationResult`。

## Forbidden

- 不新增 public runtime API。
- 不新增 public C ABI。
- 不新增 `main`。
- 不修改 `cjpm.toml`。
- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不实现 event loop / callback binding / queue / drain。
- 不新增 handle table / generation。
- 不修改 `labs/macos_bridge_smoke`。

## Verification

- `cjpm build --target-dir /tmp/cjgui-internal-lifecycle-coordination-sanity-card-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- absolute markdown link check

## Next Implementation Expectation

下一刀默认进入 `P1 internal lifecycle coordination sanity first slice`。

除非发现 HIGH / CRITICAL 风险或 authority 冲突，不得继续创建新的 preflight / execution card 替代实现。
