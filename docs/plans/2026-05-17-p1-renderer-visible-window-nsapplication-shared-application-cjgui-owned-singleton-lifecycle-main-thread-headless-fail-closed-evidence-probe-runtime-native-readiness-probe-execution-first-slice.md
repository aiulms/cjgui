# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe runtime native-readiness probe execution first slice

状态：implementation / internal-only no-runtime-execution owner

## First slice

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness` 只有在以下条件同时成立时才可认为 ready：

- Stage 76 runtime native-readiness probe execution value boundary readiness 已被消费。
- runtime native-readiness probe execution first slice 已打开。
- no application accessor call for runtime native probe execution first slice。
- no native bridge expansion for runtime native probe execution first slice。
- no runtime native probe execution。
- no singleton creation。
- production singleton ownership truth 继续 false。
- activation、activation policy mutation、AppKit event loop、bounded pump、visible order、drawable / render 继续 deferred。
- public API、production public C ABI、renderer state write、runtime state write 与 `cjpm.toml` change 继续 false。

## Scope

本 slice 是 dehydrated readiness owner。它不执行 native probe，不读取或创建 `NSApplication`，不扩展 native bridge，不创建 singleton，不调用 application accessor，也不改变 production runtime truth。

## Probe

Focused owner probe 必须证明 owner file 存在、包含 execution first-slice symbols、没有 public surface、没有 forbidden production AppKit / render tokens，且 protected paths 未进入 diff。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe execution closure preflight / no-accessor no-bridge-expansion no-runtime-execution owner decision`
