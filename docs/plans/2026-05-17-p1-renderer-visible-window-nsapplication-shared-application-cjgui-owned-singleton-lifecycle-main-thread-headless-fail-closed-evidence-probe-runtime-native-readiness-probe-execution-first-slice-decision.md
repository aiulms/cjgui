# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe runtime native-readiness probe execution first slice decision

状态：decision / stage 77 / internal-only first slice

## 结论

本轮选择 A：在用户已预授权的 visible-window / `NSApplication` / AppKit harness runway 内，继续推进 runtime native-readiness probe execution first slice 的 internal-only owner。

该 first slice 只消费 stage 76 runtime native-readiness probe execution value boundary readiness，不调用 application singleton accessor，不扩展 native bridge，不执行 runtime native probe，也不把 readiness 升级为 production singleton ownership truth。

## 上游输入

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness`

上游已经固定：

- runtime native-readiness probe execution value boundary opened。
- no application accessor call for runtime native probe execution value。
- no native bridge expansion for runtime native probe execution value。
- no runtime native probe execution。
- no singleton creation。
- no-side-effect evidence only。

## 写集

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_first_slice.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_first_slice_owner.sh)

## Stop-line

继续禁止 production singleton owner implementation、application singleton accessor call、new application singleton accessor call、native bridge expansion、runtime native probe execution、cleanup / teardown execution、activation、activation policy mutation、AppKit event loop / bounded pump、visible `NSWindow`、visible order、production `nextDrawable`、drawable texture color attachment、render command encoder、draw / commit / present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` change、public API 与 production public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe execution closure preflight / no-accessor no-bridge-expansion no-runtime-execution owner decision`
