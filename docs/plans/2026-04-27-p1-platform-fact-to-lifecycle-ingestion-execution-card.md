# P1 Platform Fact To Lifecycle Ingestion Execution Card

日期: 2026-04-27

类型: execution card / W2 internal concept slice
状态: 完成；创建本卡不等于实现

## Task Intent

将 platform adapter fact 投射到 app lifecycle 和 window lifecycle；不是继续 platform fact shape 细化，而是让 platform fact 具备生命周期消费能力。

## Prompt Weight

W2 light internal concept slice。下一刀只新增两个默认 internal projection functions，分别把 `CjguiInternalPlatformAdapterFact` 转换为 `CjguiInternalAppLifecycleState` 和 `CjguiInternalWindowLifecycleState`；不新增 owner、public contract、平台桥接或 runtime behavior。

## Authority

- [2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-closure-review.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-closure-review.md)
- [2026-04-27-p1-runtime-internal-concept-compaction.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)

## Goal

授权下一刀新增两个默认 internal projection functions：

- `cjguiInternalProjectPlatformFactToAppLifecycleState`
- `cjguiInternalProjectPlatformFactToWindowLifecycleState`

两个 function 都只读取 `fact.hasPlatformFact`，并据此设置 app/window state 的对应 Bool field。它们只组合内部标记 facts，不得引入真实 app run/shutdown 或 window create/close/destroy/release。

## Write Set

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Allowed Implementation Shape

- 可以新增两个默认 internal function。
- function 内部可以读取 `fact.hasPlatformFact`。
- function 内部可以构造 `CjguiInternalAppLifecycleState` / `CjguiInternalWindowLifecycleState`。
- function 只允许推进内部 marker facts，例如 `hasLifecyclePhase=true`、`hasWindowState=true`。

## Forbidden

- 不新增第二个字段、enum、`Result`、taxonomy、AppKit / Metal / Objective-C 引用、platform object、native handle、raw pointer、callback binding、runloop truth、delegate identity、event object。
- 不修改 app/window lifecycle source。
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

- `cjpm build --target-dir /tmp/cjgui-platform-fact-to-lifecycle-ingestion-card-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- absolute markdown link check

## Next Implementation Expectation

下一刀默认进入 `P1 platform fact to lifecycle ingestion first slice`。

除非发现 HIGH / CRITICAL 风险或 authority 冲突，不得继续创建新的 preflight / execution card 替代实现。
