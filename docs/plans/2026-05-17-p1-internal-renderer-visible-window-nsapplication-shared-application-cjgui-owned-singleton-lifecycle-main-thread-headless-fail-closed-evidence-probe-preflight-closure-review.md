# P1 internal Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe preflight closure review

状态：closure / internal owner added / stop-line preserved

## Closure

本阶段完成 `CJGUI-owned NSApplication singleton lifecycle main-thread and headless fail-closed evidence probe preflight` macro bundle 的 implementation slice：

- 消费 Stage 68 owned lifecycle main-thread / headless fail-closed value boundary readiness。
- 新增 internal-only evidence probe preflight owner 与 owner probe。
- 固定 main-thread confinement evidence probe preflight。
- 固定 headless / CI fail-closed evidence probe preflight。
- 固定 no singleton creation during evidence probe。
- 固定 no application singleton accessor call during evidence probe。
- 固定 no native bridge expansion for probe preflight。
- 只输出 owned lifecycle evidence probe preflight readiness facts。
- 不创建 singleton。
- 不调用 application singleton accessor。
- 不执行 cleanup / teardown。
- 不新增 production singleton ownership truth。

## Runtime endpoint

Canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness`

## Files

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight-decision.md)
- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight.md)
- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight_owner.sh)

## Truth closure

- `evidence_probe_preflight_opened=true`
- `main_thread_confinement_evidence_probe_preflight_required=true`
- `headless_fail_closed_evidence_probe_preflight_required=true`
- `no_singleton_creation_during_probe=true`
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `production_singleton_owner_implementation=false`
- `cleanup_teardown_execution=false`
- `production_singleton_ownership_truth=false`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line review

Stop-line 保持。未新增 production singleton owner implementation、application singleton accessor call、cleanup / teardown execution、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe first slice / scan-only no-singleton owner decision`
