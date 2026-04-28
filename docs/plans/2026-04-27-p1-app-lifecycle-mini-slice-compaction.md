# P1 App Lifecycle Mini-Slice Compaction

日期：2026-04-27

性质：docs-only / W1 closure compaction

## 当前落下的 internal surface

- `CjguiInternalAppLifecycleState`
- `isStateMachineActive: Bool`
- `hasLifecyclePhase: Bool`
- `CjguiInternalAppLifecycleTransitionMarker`
- `cjguiInternalNoOpAppLifecycleTransition`
- `cjguiInternalAppLifecyclePhaseMarkerTransition`

## 它证明了什么

- `runtime/cjgui` package 可以承载默认 internal app lifecycle state type。
- state 当前只含两个 immutable Bool facts，并通过构造期初始化保留 default inactive / no lifecycle phase。
- package 可以承载默认 internal transition marker type。
- package 可以承载默认 internal transition function。
- `cjguiInternalAppLifecyclePhaseMarkerTransition` 可以构造一个新 state，并只把 `hasLifecyclePhase` 推进为 `true`，同时保留输入 `isStateMachineActive`。

## 它不证明什么

- 不证明 app lifecycle state machine 已定义。
- 不证明 lifecycle phase taxonomy 已定义。
- 不证明 caller responsibility, transition ordering, idempotence, late message, queue / drain interaction 或 shutdown policy。
- 不证明任何 public runtime API, public C ABI 或 platform adapter contract。

## 当前仍未实现

- `run`
- `shutdown`
- `request quit`
- `queue`
- `drain`
- state machine
- phase taxonomy
- platform adapter callback binding
- window lifecycle behavior
- public runtime API
- public C ABI

## Build / Smoke 状态

最近相关 closure 均记录：

- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-first-state-changing-transition-retry-target --skip-script` 退出码 `0`，输出 `cjpm build success`。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 退出码 `0`，输出 `auto-close log assertions passed`。

## 后续最小必读上下文

以后继续 app lifecycle 线时，优先读取：

- 本 compaction 文档。
- 当轮 current execution card。
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)。

不要再默认读取前面所有 marker / shape / constructor / transition closure；只有遇到 authority 冲突、fail-closed 复盘或 HIGH / CRITICAL 风险时再回溯。

## 推荐 Next Opening

`P1 app lifecycle first real phase taxonomy decision`

该 opening 只表示未来需要决定是否引入 internal phase taxonomy；本轮不授权实现，也不创建新的 implementation card。
