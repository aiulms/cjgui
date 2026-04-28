# P1 Runtime Internal Concept Compaction

日期: 2026-04-27

类型: docs-only / W1 closure compaction

## App Lifecycle

当前 internal capability:

- state type: `CjguiInternalAppLifecycleState`
- immutable facts: `isStateMachineActive: Bool`, `hasLifecyclePhase: Bool`
- construction shape: `init()` and `init(isStateMachineActive: Bool, hasLifecyclePhase: Bool)`
- no-op transition: `cjguiInternalNo0pAppLifecycleTransition`
- state-changing marker transition: `cjguiInternalAppLifecyclePhaseMarkerTransition`
- phase taxonomy marker: `CjguiInternalAppLifecyclePhaseTaxonomyMarker`

## Window Lifecycle

当前 internal capability:

- state type: `CjguiInternalWindowLifecycleState`
- immutable fact: `hasWindowState: Bool`
- construction shape: `init()` and `init(hasWindowState: Bool)`
- no-op transition: `cjguiInternalNo0pWindowLifecycleTransition`
- state-changing marker transition: `cjguiInternalWindowLifecycleStateMarkerTransition`

## Platform Adapter

当前 internal capability:

- fact type: `CjguiInternalPlatformAdapterFact`
- immutable fact: `hasPlatformFact: Bool`
- construction shape: `init()` and `init(hasPlatformFact: Bool)`
- no-op ingestion: `cjguiInternalNo0pPlatformAdapterFactIngestion`

## What This Proves

- `runtime/cjgui` package 可以承载 internal immutable state / fact。
- `runtime/cjgui` package 可以承载 construction shape。
- `runtime/cjgui` package 可以承载 no-op internal function。
- `runtime/cjgui` package 可以承载极窄 state-changing marker transition。
- 最近 closure 记录 runtime build 与 smoke guard 仍通过。

## What This Does Not Prove

- 不证明 public runtime API。
- 不证明 public C ABI。
- 不证明 platform adapter callback binding。
- 不证明 AppKit / Metal / Objective-C runtime 接入。
- 不证明 app `run` / `shutdown` / queue / drain。
- 不证明 window create / request close / destroy / release。
- 不证明 handle / handle table / generation。
- 不证明 Renderer / Scene / Widget / Layout / DSL。

## Minimal Future Context

继续 `runtime/cjgui` internal slices 时，优先读取：

- 本 compaction 文档。
- 当轮 current execution card。
- 对应 source 文件：
  - [app_lifecycle.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [window_lifecycle.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
  - [platform_adapter.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)

不要再默认读取前面所有 marker / shape / construction / transition closure；只有遇到 authority 冲突、fail-closed 复盘或 HIGH / CRITICAL 风险时再回溯。

## Recommended Next Opening

`P1 platform fact to lifecycle ingestion boundary decision`

该 opening 不自动开启实现。它只表示下一步应决定是否让 platform adapter 的 dehydrated fact 进入 app/window lifecycle 的 internal ingestion boundary。
