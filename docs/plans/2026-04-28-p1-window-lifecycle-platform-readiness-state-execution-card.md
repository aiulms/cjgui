# P1 window lifecycle platform readiness state execution card

日期：2026-04-28

类型：execution card / W2 internal concept slice

## Task Intent

bounded implementation authorization. 创建本卡不等于实现。

## Prompt Weight

W2 internal concept slice：下一刀只让 window lifecycle internal state 明确承载 platform readiness observed 语义，并让现有 platform readiness projection 写入该 state；不新增 public contract、平台桥接或 runtime behavior。

## Authority

- [2026-04-28-p1-app-lifecycle-platform-readiness-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-app-lifecycle-platform-readiness-state-closure-review.md)

## Goal

授权下一轮让 `CjguiInternalWindowLifecycleState` 承载 internal `hasObservedPlatformReady` 或等价 Bool fact。

同时授权:

- 更新 window state constructor shape。
- 更新 platform readiness -> window lifecycle projection，让 `isPlatformReady=true` 推进该 window fact。
- 保持 internal-only、脱水 Bool fact、无平台对象、无 public runtime API / public C ABI。

## Write Set

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Allowed Implementation Shape

- 可以在 `CjguiInternalWindowLifecycleState` 新增一个 immutable Bool fact，例如 `hasObservedPlatformReady`。
- 可以更新 `CjguiInternalWindowLifecycleState.init()` 与带参 `init`。
- 可以更新 `cjguiInternalWindowLifecycleStateMarkerTransition`，保留新增 window lifecycle readiness fact。
- 可以更新 `cjguiInternalProjectPlatformFactToWindowLifecycleState`，让 `isPlatformReady=true` 推进新增 window fact。
- 可以更新 `cjguiInternalLifecycleCoordinationSanity`，保持最小 platform readiness fact -> app/window state coordination sanity 调用成立。
- 可以同步更新 `runtime/cjgui/README.md`。

## Forbidden

- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不实现 app run / shutdown / request quit。
- 不实现 event loop / callback binding / queue / drain。
- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不新增 public runtime API。
- 不新增 public C ABI。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`。

## Verification

- `cjpm build --target-dir /tmp/cjgui-window-lifecycle-platform-readiness-state-card-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- 链接检查

## Next Implementation Expectation

下一轮默认进入 `P1 window lifecycle platform readiness state first slice`。

除非发现 HIGH / CRITICAL 风险或 authority 冲突，不得继续创建新的 preflight / execution card 替代实现。
