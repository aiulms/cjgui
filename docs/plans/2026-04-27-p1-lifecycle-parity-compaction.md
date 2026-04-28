# P1 lifecycle parity compaction

日期: 2026-04-27

性质: docs-only / W1 closure compaction

## 当前 App Lifecycle Internal Symbols

- `CjguiInternalAppLifecycleState`
- `isStateMachineActive: Bool`
- `hasLifecyclePhase: Bool`
- `CjguiInternalAppLifecycleTransitionMarker`
- `CjguiInternalAppLifecyclePhaseTaxonomyMarker`
- `cjguiInternalNo0pAppLifecycleTransition`
- `cjguiInternalAppLifecyclePhaseMarkerTransition`

## 当前 Window Lifecycle Internal Symbols

- `CjguiInternalWindowLifecycleState`
- `hasWindowState: Bool`
- `cjguiInternalNo0pWindowLifecycleTransition`
- `cjguiInternalWindowLifecycleStateMarkerTransition`

## 当前共同证明

- `runtime/cjgui` package 可以承载默认 internal immutable state facts。
- `runtime/cjgui` package 可以承载最小 construction shape。
- `runtime/cjgui` package 可以承载 no-op transition。
- `runtime/cjgui` package 可以承载 first state-changing marker transition。
- 最近 app/window lifecycle 相关 closure 均记录 `cjpm build` 通过，smoke guard 通过。

## 当前不证明

- 不证明真实 app/window state machine。
- 不证明 `run` / `shutdown` / `request quit` / `queue` / `drain`。
- 不证明 window create / request close / destroy / release。
- 不证明 handle / handle table / generation。
- 不证明 platform adapter callback binding。
- 不证明 public runtime API / public C ABI。
- 不证明 Renderer / Scene / Widget / Layout / DSL。

## 后续最小必读上下文

继续 app/window lifecycle 线时，优先读取:

- 本 compaction 文档。
- 当轮 current execution card。
- 对应 source 文件:
  - [app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)

不要再默认读取前面所有 marker / shape / construction / transition closure; 只有遇到 authority 冲突、fail-closed 复盘或 HIGH / CRITICAL 风险时再回溯。

## 推荐 Next Opening

`P1 lifecycle internal mini-runtime closure / next functional slice decision`

该 opening 不自动开启实现。下一步应先决定是继续 window lifecycle phase taxonomy、开始 internal handle / generation preflight、开始 platform adapter fact ingestion，还是开始 app-level queue acceptance 的 internal shape。
