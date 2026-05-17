# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle preflight recovery decision

状态：decision / route C selected / internal-only preflight owner

## 决策

用户已选择路线 C：长期保留 hosted / owned 双模式设计。

- hosted mode：宿主应用已经拥有 `NSApplication` lifecycle，CJGUI 只接入 view / layer / render surface。
- owned mode：CJGUI 自己负责 `NSApplication` singleton lifecycle，用于独立 app runtime。

当前没有 external owner source witness evidence packet。因此 hosted mode 在当前 runway 标记为 evidence absent / unavailable；本阶段不继续等待 external witness，也不伪造 preexisting singleton owner witness。

本阶段进入 `CJGUI-owned NSApplication singleton lifecycle preflight / recovery`，但只形成 internal-only planning/readiness facts。owned mode 是当前 recovery route；它不是 production singleton ownership truth，也不是 production singleton owner implementation。

## 当前 route C 结论

- `route_c_hosted_owned_dual_mode_design=true`
- `hosted_mode_external_owner_witness_evidence_absent=true`
- `hosted_mode_current_route_available=false`
- `hosted_owner_truth=false`
- `owned_mode_current_recovery_route=true`
- `isolated_throwaway_probe_evidence_promoted_to_hosted_owner_truth=false`
- `isolated_throwaway_probe_evidence_promoted_to_production_ownership_truth=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `new_application_singleton_accessor_call=false`

## Owned mode 固定前置条件

本阶段把 owned mode 的前置条件固定为 value/preflight readiness，而不是实现许可：

- main-thread creation requirement。
- headless / CI fail-closed。
- activation deferred。
- activation policy mutation deferred。
- AppKit event loop / bounded run-loop pump deferred。
- visible order deferred。
- drawable / render deferred。
- teardown / cleanup responsibility required before implementation。
- artifact / public diagnostics non-publication。
- no public API / no public C ABI。
- no renderer state write。
- no `runtime_state.cj` write。
- no `runtime/cjgui/cjpm.toml` change。

## Runtime owner

新增 internal-only owner：

[runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight.cj)

新增 owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight_owner.sh)

该 owner 只消费：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness`

并输出：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightDraft()`

## Stop-line

本阶段不授权 production singleton owner implementation、新的 application singleton accessor call、`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、visible `NSWindow`、visible order、production `nextDrawable`、render pass drawable texture、render command encoder、draw、commit、present、GPU submission、renderer state write、`runtime_state.cj` 修改、`runtime/cjgui/cjpm.toml` 修改、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle value boundary / teardown-cleanup responsibility owner decision`
