# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe first slice

状态：implementation / internal-only scan-only owner

## Value boundary

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness` 只有在以下条件同时成立时才可认为 ready：

- Stage 69 evidence probe preflight readiness 已被消费。
- main-thread confinement evidence 与 headless fail-closed evidence 只以 scan-only facts 记录。
- singleton creation、application accessor call、native bridge expansion 与 runtime native probe execution 均为 false。
- cleanup / teardown execution、activation、activation policy mutation、event loop、visible order、drawable / render 均 deferred。
- production singleton ownership truth、production implementation、public API、public C ABI、renderer state write、runtime state write 与 cjpm change 均保持 false。

## Scope

本 slice 是 no-side-effect evidence owner。它不执行 native probe，不读取或创建 `NSApplication`，不扩展 native bridge，不创建 singleton，不调用 application accessor，也不改变 production runtime truth。

## Probe

Focused owner probe 必须证明 owner file 存在、包含 scan-only evidence symbols、没有 public surface、没有 forbidden production AppKit / render tokens，且 protected paths 未进入 diff。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe native-readiness preflight / no-accessor no-bridge-expansion decision`
