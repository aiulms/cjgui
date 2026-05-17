# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe native-readiness preflight

状态：preflight / internal-only owner

## 范围

本 preflight 只把 stage 70 scan-only evidence first slice 投影为 native-readiness preflight facts。它不是 native probe execution，不扩展 Objective-C bridge，不新增 C ABI，不读取或返回 native identity。

## 输入

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness`

输入必须仍满足：

- scan-only main-thread confinement evidence recorded。
- scan-only headless fail-closed evidence recorded。
- no singleton creation。
- no application accessor call。
- no native bridge expansion。
- no runtime probe execution。
- no production singleton ownership truth。

## 输出

Canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightDraft()`

本阶段只输出 native-readiness preflight facts：

- no-accessor native-readiness preflight opened。
- no-bridge-expansion native-readiness preflight opened。
- runtime probe execution deferred。
- owner probe / forbidden scan required before any later native-readiness value boundary。

## 非授权事项

本阶段不授权 actual `sharedApplication` call、throwaway singleton creation、production singleton owner implementation、cleanup / teardown execution、activation、activation policy mutation、AppKit event loop、bounded pump、visible order、drawable、render、artifact publication、public diagnostics、public API、production C ABI、renderer state write、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe native-readiness value boundary / no-accessor no-bridge-expansion owner decision`
