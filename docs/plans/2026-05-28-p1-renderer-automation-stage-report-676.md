# P1 Renderer Automation Stage Report 676

日期：2026-05-28

## 小设计

当前真实 tail 是 feedback / demo-host event cycle 链路：stage672 已把 feedback input demo-host event adapter、queue、cycle receipt 收敛成 shared event-cycle runtime contract，但 next opening 仍停在 event replay surface。最近多轮已经重复 `surface -> inspection -> result refresh -> runtime contract` 和 `adapter -> queue -> receipt -> runtime contract` 的同构节奏；本轮触发周期收敛，不再只新增同形 owner。

本轮完成 stage673-676 four-slice macro package：stage673 消费 stage672 event-cycle runtime contract，生成 replayable feedback input event result surface；stage674 消费 stage673 replay surface，生成 host inspection preview / probe input；stage675 消费 stage674 inspection preview，生成 replay result-surface refresh receipt；stage676 消费 stage675 refresh receipt，抽出 shared replay runtime executor / contract，并把 Todo、settings、AI-generated settings、chat composer 四个 demo surface 接到同一条 executor。关键 stop-line：不执行真实 input pipeline、不 dispatch action、不提交 state、不发布 visibility、不提交 renderer、不写 renderer_state/runtime_state、不扩 native bridge 或 public API。

## Four Slices

1. Slice 1：新增 `runtime_renderer_stage673_feedback_input_event_replay_surface.cj`，把 stage672 event-cycle runtime contract 转成 replayable event result surface，覆盖 validation dismiss、focus movement、input feedback clear、semantic diff acknowledge 四类 replay route，并产生 Todo/settings/AI-generated settings/chat composer replay surfaces。
2. Slice 2：新增 `runtime_renderer_stage674_feedback_input_replay_host_inspection_preview.cj`，直接消费 stage673 replay surface，生成 shared replay host inspection preview、host inspection probe input 与四个 demo inspection previews。
3. Slice 3：新增 `runtime_renderer_stage675_feedback_input_replay_result_surface_refresh.cj`，直接消费 stage674 inspection preview，生成 replay result-surface refresh receipt，把 semantic diff explain、focus transition、RenderCommand refresh preview、input feedback display refresh 收到同一 result-surface contract。
4. Slice 4：新增 `runtime_renderer_stage676_feedback_input_replay_runtime_executor.cj`，直接消费 stage675 refresh receipt，抽出 shared feedback input replay runtime executor、shared runtime contract、replay execution receipt contract 与 `event_cycle_runtime_replay_inspection_result_executor` cycle order，并把四个 demo surface 接入同一 executor。

## 真实能力增量

- 新增 replayable event result surface，不再只证明 event cycle readiness。
- 新增 replay host inspection preview / probe input，使 replay 能进入可检查 demo-host surface。
- 新增 replay result-surface refresh receipt，把 replay 结果推进到可复核的 result surface。
- 新增 shared replay runtime executor / common contract，压缩后续 per-demo replay / inspection / result owner 的必要性。

本轮周期收敛已触发并完成：stage676 固定 `future_per_demo_feedback_input_replay_template_need_reduced=true`，四个 demo surface 共享同一 replay runtime executor，而不是继续复制 Todo/settings/AI-generated settings/chat 的同构 owner。

## 辅助 Envelope / Readiness

新增 owner structs、facts、readiness 与 focused owner/suite scripts 属于辅助 envelope；它们服务于 replay surface、host inspection preview、result refresh 与 shared executor 的可验证链路，不声明 production render truth、backend-ready truth 或 owner acceptance granted。

## 修改文件

- `runtime/cjgui/src/runtime_renderer_stage673_feedback_input_event_replay_surface.cj`
- `runtime/cjgui/src/runtime_renderer_stage674_feedback_input_replay_host_inspection_preview.cj`
- `runtime/cjgui/src/runtime_renderer_stage675_feedback_input_replay_result_surface_refresh.cj`
- `runtime/cjgui/src/runtime_renderer_stage676_feedback_input_replay_runtime_executor.cj`
- `runtime/cjgui/native/scripts/verify_renderer_stage673_feedback_input_event_replay_surface_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage674_feedback_input_replay_host_inspection_preview_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage675_feedback_input_replay_result_surface_refresh_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage676_feedback_input_replay_runtime_executor_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage673_feedback_input_event_replay_surface_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage674_feedback_input_replay_host_inspection_preview_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage675_feedback_input_replay_result_surface_refresh_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage676_feedback_input_replay_runtime_executor_suite.sh`
- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`
- `docs/plans/2026-05-28-p1-renderer-automation-stage-report-676.md`

## 验证结果

- RED owner probes：stage673、stage674、stage675、stage676 owner scripts 在 source 缺失时均按预期 fail-closed。
- Owner probes：stage673、stage674、stage675、stage676 owner scripts 均通过。
- Focused suites：
  - `verify_renderer_stage672_feedback_input_demo_host_event_cycle_runtime_contract_suite.sh` 通过。
  - `verify_renderer_stage673_feedback_input_event_replay_surface_suite.sh` 通过。
  - `verify_renderer_stage674_feedback_input_replay_host_inspection_preview_suite.sh` 通过。
  - `verify_renderer_stage675_feedback_input_replay_result_surface_refresh_suite.sh` 通过。
  - `verify_renderer_stage676_feedback_input_replay_runtime_executor_suite.sh` 通过。
- stage676 suite 执行 `cjpm build --target-dir /private/tmp/cjgui-stage673-stage676/stage676/target --skip-script`，通过；build log：`/private/tmp/cjgui-stage673-stage676/stage676/cjpm-build.log`。
- stage676 packet：`/private/tmp/cjgui-stage673-stage676/stage676/stage676-feedback-input-replay-runtime-executor-suite.packet`，确认 `shared_feedback_input_replay_runtime_executor_materialized=true`、`shared_feedback_input_replay_runtime_contract_materialized=true`、`replay_execution_receipt_contract_materialized=true`、四个 demo replay runtime surfaces materialized、`future_per_demo_feedback_input_replay_template_need_reduced=true`。
- Final scans：`git diff --check` 通过；新 docs/source/scripts 无 conflict markers、无 trailing whitespace；stage673-676 source public/foreign scan 无输出；`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 无 diff。

## GitNexus / CodeLattice

- `gitnexus context CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorReadiness --repo cangjie-live-codelattice`：symbol not found。新 internal owner 尚未被当前 graph 覆盖，不能当作安全证明。
- `gitnexus impact CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorReadiness --repo cangjie-live-codelattice`：target not found，`risk=UNKNOWN`，`impactedCount=0`。按规则走源码读取、focused probes、cjpm build 与 scans 兜底。
- `gitnexus detect-changes --repo cangjie-live-codelattice --scope all`：报告 5 files / 3 symbols / affected processes 0 / low risk，但未覆盖本轮 untracked stage673-676 owner files，因此只作为 indexed graph 参考。
- CodeLattice `codelattice_workspace` impact：static-analysis-only，risk low；未执行 target code/scripts，不能作为 runtime proof。
- CodeLattice `codelattice_project` diagnose on stage676 source：static-analysis-only，risk medium / top confidence 0.95；未执行 target code/scripts，最终以 focused suites 和 `cjpm build --skip-script` 作为 runtime/build proof。
- alias status：`cangjie-live-codelattice` 指向 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`；工作区 dirty 较大，stable window RED，仅作状态提示，不执行 production smoke。

## Stop-Line

保持 `host_mutation=false`、`owner_acceptance_granted=false`、`production_render_truth=false`、`backend_ready_truth=false`、`input_event_pipeline_execution=false`、`action_dispatch=false`、`state_update_committed=false`、`visibility_publication_admitted=false`、`visibility_published=false`、`public_component_api_added=false`、`renderer_submission=false`、`renderer_state_write=false`、`runtime_state_write=false`、`native_bridge_expansion=false`。

本轮没有执行 bounded runtime native probe；该能力包不需要 live Metal/AppKit。未遇到新的 CJGUI harness 缺口或宿主限制。

## Current Endpoint / Next Route

Canonical endpoint：`CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorReadiness` / `cjguiInternalExecuteDefaultRendererStage676FeedbackInputReplayRuntimeExecutorDraft()`。

当前 next route：`stage677_feedback_input_replay_action_state_bridge_after_stage676`。

第一帧链路、renderer-state write、runtime_state write 仍未推进；minimal UI framework 距离真实 demo 还差真实 input event pipeline、action dispatch、owner-local state commit、RenderCommand 到 host/runtime surface 的真实刷新、layout/style/focus/text 的可执行模型，以及可检查 demo-host replay/action-state bridge。下一条最值得推进的工程目标是：在 stage676 shared replay runtime executor 上接 `feedback input replay action/state bridge`，把 replay receipt 转成 non-dispatching action intent/state delta/RenderCommand refresh dry-run，并继续保持无生产提交。
