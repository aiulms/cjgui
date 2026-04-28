# P1 Internal Lifecycle Coordination Execution Card

日期: 2026-04-27

类型: execution card / W2 internal concept slice / bounded implementation authorization
状态: 完成；创建本卡不等于实现

## Task Intent

bounded implementation authorization。授权下一刀实现一个最小 internal lifecycle coordination 概念切片；本卡不是长 preflight，也不是继续文档循环入口。

## Prompt Weight

`W2 internal concept slice`。

理由: 下一刀会把已有 app lifecycle state、window lifecycle state 与 platform fact projection 串成一个 internal coordination 入口，可能同时触达三条 runtime internal surface；但仍无 public API / C ABI、无平台对象、无 handle、无 event loop / callback binding，因此不升为 W3。

## Authority

- [2026-04-27-p1-runtime-internal-concept-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)
- [2026-04-27-p1-platform-fact-to-lifecycle-ingestion-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-fact-to-lifecycle-ingestion-closure-review.md)

## Goal

授权下一刀实现一个默认 internal lifecycle coordination function。该 function 可以接收 `CjguiInternalPlatformAdapterFact`、`CjguiInternalAppLifecycleState`、`CjguiInternalWindowLifecycleState`，并返回协调后的 app/window state。

## Write Set

下一刀最多允许修改:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Allowed Implementation Shape

- 可以新增一个默认 internal coordination type 或 coordination result type；必须无 public、无平台对象、无 handle、无 C ABI，且不得把它升级成公开 `Result`/error strategy。
- 可以新增一个默认 internal coordination function。
- function 内部可以调用既有 platform fact projection functions。
- function 只允许推进 internal marker facts，例如 app `hasLifecyclePhase=true`、window `hasWindowState=true`。
- 不允许引入真实 app run / shutdown / window create / close / destroy 行为。

## Forbidden Scope / Stop-Line

- 不新增 public runtime API。
- 不新增 public C ABI。
- 不接入 AppKit / Metal / Objective-C。
- 不暴露 native handle / raw pointer / platform object。
- 不实现 event loop / callback binding / queue / drain。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。

## Verification

下一刀必须运行:

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`
- `export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`
- `export SDKROOT="$CJ_GUI_SDKROOT"`
- `cjpm build --target-dir /tmp/cjgui-internal-lifecycle-coordination-card-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- 链接检查: closure review 必须能从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

## Next Implementation Expectation

下一刀默认进入:

`P1 internal lifecycle coordination first slice`

除非发现 HIGH / CRITICAL 风险、authority 冲突或必须越过 write set / stop-line，不得继续创建新的 preflight / execution card 替代 bounded implementation。
