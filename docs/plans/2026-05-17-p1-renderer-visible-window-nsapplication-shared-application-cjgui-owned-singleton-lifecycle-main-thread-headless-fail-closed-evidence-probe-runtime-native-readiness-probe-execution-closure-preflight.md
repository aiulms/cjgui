# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe runtime native-readiness probe execution closure preflight

状态：implementation / internal-only no-runtime-execution owner

## Readiness

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness` 只有在以下条件同时成立时才可认为 ready：

- Stage 77 runtime native-readiness probe execution first slice readiness 已被消费。
- runtime native-readiness probe execution closure preflight 已打开。
- no application accessor call for runtime native probe execution closure preflight 为 true。
- no native bridge expansion for runtime native probe execution closure preflight 为 true。
- runtime native probe execution 继续 false。
- singleton creation、cleanup / teardown execution 与 production singleton ownership truth 继续 false。
- activation、activation policy mutation、AppKit event loop、bounded pump、visible order、drawable / render 继续 deferred。
- public API、production public C ABI、renderer state write、runtime state write 与 `cjpm.toml` change 继续 false。

## Owner

本 owner 是 dehydrated readiness owner。它不执行 native probe，不读取或创建 `NSApplication`，不扩展 native bridge，不创建 singleton，不调用 application accessor，也不改变 production runtime truth。

## Probe

Focused owner probe 必须证明 owner file 存在、包含 execution closure-preflight symbols、没有 public surface、没有 forbidden production AppKit / render tokens，且 protected paths 未进入 diff。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe execution closure value boundary / no-accessor no-bridge-expansion no-runtime-execution owner decision`
