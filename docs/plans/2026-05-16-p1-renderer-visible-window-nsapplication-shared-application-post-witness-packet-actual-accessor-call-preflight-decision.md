# P1 Renderer 可见窗口 NSApplication Shared-Application Post-Witness-Packet Actual-Call Preflight 决策

状态：decision / preflight / value-only owner / no actual accessor call

## Decision

本阶段从 `external preexisting singleton source witness packet truth admission preflight` 回到 actual accessor call 决策点。裁定结果是：不继续制造同构 no-call audit wrapper，也不直接实现 actual accessor call；只打开 `post-witness-packet actual-call preflight revalidation`。

该 preflight revalidation 只确认当前 packet truth admission 可以作为 actual-call 决策输入之一，但仍不是 witness truth、source readiness truth、production singleton ownership truth 或 actual accessor call permission。

## Branch 选择

本轮选择 B：

- 打开极窄 actual-call preflight revalidation；
- 新增 value-only runtime owner 与 owner probe；
- 保持 actual application singleton accessor call blocked；
- 保持 production actual accessor call site blocked；
- 下一阶段必须先进入 explicit human approval decision，不能自动进入 first slice。

本轮不选择：

- A：继续追加同构 no-call audit branch wrapper；
- C：直接实现 actual application singleton accessor call；
- D：把 witness packet truth admission 升级成 source readiness truth 或 production singleton ownership truth。

## Canonical 状态

本阶段 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`

本阶段 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft()`

本阶段 runtime inputs：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`

## Truth

- `post_witness_packet_actual_accessor_call_preflight_opened=true`
- `only_actual_call_preflight_opened=true`
- `actual_accessor_call_implementation=false`
- `production_actual_accessor_call_site=false`
- `packet_truth_admission_as_witness_truth=false`
- `packet_truth_admission_as_source_readiness_truth=false`
- `packet_truth_admission_as_production_singleton_ownership_truth=false`
- `explicit_human_decision_before_actual_call_first_slice_required=true`
- `main_thread_confined_future_first_slice_required=true`
- `isolated_probe_first_future_first_slice_required=true`
- `activation_policy_mutated=false`
- `activation_called=false`
- `appkit_event_loop_started=false`
- `bounded_run_loop_pump_implemented=false`
- `cleanup_teardown_executed=false`
- `window_view_layer_created=false`
- `visible_order=false`
- `drawable_acquired=false`
- `render_commit_present_gpu_submission=false`
- `artifact_or_diagnostics_publication=false`
- `pointer_handle_class_id_return=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `renderer_state_write=false`
- `backend_ready_truth=false`

## Stop-line

不调用 application singleton accessor；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 预检结果

GitNexus 对当前 upstream endpoint 与拟新增 endpoint 返回 target not found / UNKNOWN / 0 impacted。该结果只说明图索引未覆盖近期新增符号，不能作为安全证明；本阶段以 source reading、owner probe、build、forbidden scan、protected path scan、manifest reachability 与最终 `detect-changes` 兜底。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`
