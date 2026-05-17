# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe native-readiness value boundary

状态：value boundary / stage 72 / existing artifacts accepted

## Boundary

本阶段接纳已存在的 internal-only value boundary owner 和 owner probe，把 stage 71 native-readiness preflight readiness 收束成 dehydrated value boundary readiness。

该 boundary 只表达以下事实：

- 不调用 application singleton accessor。
- 不扩展 native bridge。
- 不执行 runtime native probe。
- 不创建 singleton。
- 不发布 artifact 或 public diagnostics。
- 不把 native-readiness evidence 升级成 production singleton ownership truth。

## Runtime shape

当前 endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness`

## Accepted artifacts

- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_value_boundary.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_value_boundary_owner.sh)

## Non-goals

本阶段不进入 actual accessor call、native bridge expansion、runtime native probe execution、production singleton owner implementation、cleanup / teardown execution、activation、event loop、visible order、drawable、render、public API 或 production public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe preflight / no-accessor no-bridge-expansion no-runtime-execution owner decision`
