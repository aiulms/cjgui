# P1 Renderer visible-window NSApplication shared-application source readiness truth value boundary decision

日期：2026-05-16

状态：decision / internal-only value owner / source readiness truth still false

## 结论

本轮选择 A：在当前自动化窗口预授权范围内，推进 `external preexisting singleton source readiness truth value boundary` 的 internal-only readiness owner。

该阶段不把 source readiness truth 升级为 true。它只把 preauthorized actual accessor first-slice、source readiness admission preflight 与 witness packet truth admission preflight 的 evidence 串成一个 value boundary，固定 source readiness truth 仍为 conditional / false，并为下一段 production singleton ownership value boundary 提供可审计输入。

Canonical endpoint 转为：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryDraft()`

## Runtime inputs

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`

## 写集

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary_owner.sh)

## Truth

- `preauthorized_actual_accessor_first_slice_preserved=true`
- `source_readiness_admission_preflight_preserved=true`
- `witness_packet_truth_admission_preflight_preserved=true`
- `source_readiness_truth_value_boundary_opened=true`
- `source_readiness_truth_conditional=true`
- `external_preexisting_singleton_source_readiness_truth=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `actual_accessor_call_isolated_probe_only=true`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-line

继续禁止：`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、production visible `NSWindow` creation、`makeKeyAndOrderFront` / `orderFront`、AppKit event loop / bounded pump、production `nextDrawable`、production drawable texture color attachment、render command encoder、draw / commit / present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` mutation、public API、public / production C ABI、pointer / handle / `id` / `Class` return、artifact / diagnostics publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership value boundary / internal readiness owner decision`
