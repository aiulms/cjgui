# P1 Renderer Automation Stage Report 684

日期：2026-05-28

## 小设计

当前真实 tail 是 stage680 replay action-state-render cycle executor：replay action intent、state delta dry-run、RenderCommand/result refresh 已被收敛为 shared executor，但仍缺少可检查 demo-host inspection surface。最近多轮持续重复 `surface -> inspection -> result refresh -> runtime contract` 与 `adapter -> state/render -> runtime contract`，本轮触发周期收敛；目标不是新增孤立 replay wrapper，而是把 stage680 runtime receipt 推进到 host inspection、layout/style/text/focus inspection、result-surface refresh 与 shared host inspection runtime contract。

本轮完成 stage681-684 four-slice macro package：stage681 消费 stage680 cycle executor，生成 replay action-state-render demo-host inspection preview 与 probe input；stage682 消费 stage681 inspection preview，生成 layout/style/text/focus inspection receipts；stage683 消费 stage682 receipts，生成 host result-surface refresh、semantic diff explain、focus transition、RenderCommand inspection refresh 与 input feedback display refresh；stage684 消费 stage683 refresh，抽出 shared replay action-state-render host inspection runtime contract/helper/execution receipt contract，并把 Todo、settings、AI-generated settings、chat composer 四个 demo 接到同一条 runtime surface。关键 stop-line：不执行真实 input pipeline、不 dispatch action、不提交 state、不发布 visibility、不提交 renderer、不写 renderer_state/runtime_state、不扩 native bridge 或 public API。

## Four Slices

1. Slice 1：新增 `runtime_renderer_stage681_replay_action_state_render_demo_host_inspection.cj`，消费 stage680 shared replay action-state-render cycle executor，生成 shared host inspection preview、host probe input 与 Todo/settings/AI-generated settings/chat composer host inspections。
2. Slice 2：新增 `runtime_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt.cj`，直接消费 stage681 host inspections，生成 shared layout/style/text/focus inspection receipt、layout slot/style token/text run/focus route receipts 与四个 demo layout/focus inspection receipts。
3. Slice 3：新增 `runtime_renderer_stage683_replay_action_state_render_host_result_surface_refresh.cj`，直接消费 stage682 inspection receipts，生成 shared host result-surface refresh、semantic diff explain、focus transition、RenderCommand inspection refresh、input feedback display refresh 与四个 demo refresh surfaces。
4. Slice 4：新增 `runtime_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract.cj`，直接消费 stage683 refresh surfaces，抽出 shared host inspection runtime contract/helper/execution receipt contract、`replay_action_state_render_host_inspection_layout_result_runtime` cycle order，并把四个 demo surface 接入同一 executor。

## 真实能力增量

- stage680 的 replay action/state/render receipt 现在能进入 demo-host inspection preview，而不是停在 shared executor readiness。
- host inspection 能继续检查 layout/style/text/focus 形态，形成可验证 receipt，同时仍保持 layout/style/focus engine disabled。
- host inspection receipt 能刷新 result surface，并覆盖 semantic diff explain、focus transition、RenderCommand inspection refresh 与 input feedback display refresh。
- stage684 把 Todo/settings/AI-generated settings/chat composer 统一接入 shared replay action-state-render host inspection runtime contract，减少后续 per-demo host inspection/result/runtime 模板复制。

本轮周期收敛已触发并完成：stage684 固定 `future_per_demo_replay_host_inspection_template_need_reduced=true`，并将四个 demo 绑定到同一 host inspection runtime contract/helper，而不是继续复制 per-demo inspection/result/runtime owner。

## 辅助 Envelope / Readiness

新增 owner structs、facts、readiness 与 focused owner/suite scripts 属于辅助 envelope；它们服务于 replay action-state-render host inspection、layout/style/text/focus inspection receipt、host result refresh 与 shared runtime contract 的可验证链路，不声明 production render truth、backend-ready truth 或 owner acceptance granted。

## 修改文件

- `runtime/cjgui/src/runtime_renderer_stage681_replay_action_state_render_demo_host_inspection.cj`
- `runtime/cjgui/src/runtime_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt.cj`
- `runtime/cjgui/src/runtime_renderer_stage683_replay_action_state_render_host_result_surface_refresh.cj`
- `runtime/cjgui/src/runtime_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract.cj`
- `runtime/cjgui/native/scripts/verify_renderer_stage681_replay_action_state_render_demo_host_inspection_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage683_replay_action_state_render_host_result_surface_refresh_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage681_replay_action_state_render_demo_host_inspection_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage683_replay_action_state_render_host_result_surface_refresh_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract_suite.sh`
- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`
- `docs/plans/2026-05-28-p1-renderer-automation-stage-report-684.md`

## 验证结果

- RED owner probes：stage681、stage682、stage683、stage684 owner scripts 在 source 缺失时均按预期 fail-closed。
- Owner probes：stage681、stage682、stage683、stage684 owner scripts 均通过。
- Focused suites：
  - `verify_renderer_stage680_feedback_input_replay_action_state_render_cycle_executor_suite.sh` 通过。
  - `verify_renderer_stage681_replay_action_state_render_demo_host_inspection_suite.sh` 通过。
  - `verify_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt_suite.sh` 通过。
  - `verify_renderer_stage683_replay_action_state_render_host_result_surface_refresh_suite.sh` 通过。
  - `verify_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract_suite.sh` 通过。
- stage684 suite 执行 `cjpm build --target-dir /private/tmp/cjgui-stage681-stage684/stage684/target --skip-script`，通过；build log：`/private/tmp/cjgui-stage681-stage684/stage684/cjpm-build.log`。
- stage684 packet：`/private/tmp/cjgui-stage681-stage684/stage684/stage684-replay-action-state-render-host-inspection-runtime-contract-suite.packet`，确认 shared runtime contract/helper、execution receipt contract、四个 demo runtime surfaces 与 `future_per_demo_replay_host_inspection_template_need_reduced=true`。
- `cjfmt -f` 已逐个格式化 stage681-684 source；第一次 source toolchain 时遇到 `envsetup.sh` 的 `ps` 检测限制，已用本地 `ps` shim 重跑成功。
- 一次 build RED 暴露 stage682 readiness constructor 缺少 `visibility_published=false` 参数；已补齐并重跑 suite chain 通过。
- 新增 owner/suite scripts `zsh -n` 通过；stage681-684 source public/foreign scan、forbidden native/render token scan 与 protected path scan 通过。
- `git diff --check` 通过；新 docs/source/scripts 无 conflict markers、无 trailing whitespace；`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 无 diff。

## GitNexus / CodeLattice

- 预编辑 `gitnexus context CjguiInternalRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorReadiness --repo cangjie-live-codelattice`：symbol not found。当前 graph 未覆盖 fresh internal owner，不能当作安全证明。
- 预编辑 `gitnexus impact CjguiInternalRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorReadiness --repo cangjie-live-codelattice`：target not found，`risk=UNKNOWN`，`impactedCount=0`。按规则走源码读取、focused probes、cjpm build 与 scans 兜底。
- 后编辑 `gitnexus context CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness --repo cangjie-live-codelattice`：symbol not found。当前 graph 仍未覆盖 fresh stage684 owner。
- 后编辑 `gitnexus impact CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness --repo cangjie-live-codelattice`：target not found，`risk=UNKNOWN`，`impactedCount=0`。未把 UNKNOWN 当作安全证明，继续以源码读取、focused probes、cjpm build 与 scans 兜底。
- `gitnexus detect-changes --repo cangjie-live-codelattice --scope all`：`Changes: 5 files, 3 symbols`、`Affected processes: 0`、`Risk level: low`；changed symbols 仅为 README-style doc headings，fresh stage681-684 owner files 未被索引覆盖，因此只作为 indexed graph 参考。
- alias status：live repo 是 `/Users/jiangxuanyang/Desktop/cangjie`，registry `cangjie-live-codelattice` 指向 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`；工作区 dirty 较大，stable window RED，仅作状态提示，不执行 production smoke。

## Stop-Line

保持 `host_mutation=false`、`owner_acceptance_granted=false`、`production_render_truth=false`、`backend_ready_truth=false`、`input_event_pipeline_execution=false`、`action_dispatch=false`、`state_update_committed=false`、`visibility_publication_admitted=false`、`visibility_published=false`、`public_component_api_added=false`、`layout_engine_enabled=false`、`style_resolver_enabled=false`、`focus_manager_enabled=false`、`renderer_submission=false`、`renderer_state_write=false`、`runtime_state_write=false`、`native_bridge_expansion=false`。

本轮没有执行 bounded runtime native probe；该能力包不需要 live Metal/AppKit。未遇到新的 CJGUI harness 缺口或宿主限制。

## Current Endpoint / Next Route

Canonical endpoint：`CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness` / `cjguiInternalExecuteDefaultRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractDraft()`。

当前 next route：`stage685_replay_action_state_render_host_input_feedback_loop_after_stage684`。

第一帧链路、renderer-state write、runtime_state write 仍未推进；minimal UI framework 距离真实 demo 还差真实 input event pipeline、action dispatch、owner-local state commit、真实 RenderCommand 到 host/runtime surface 的刷新、layout/style/focus/text 的可执行模型，以及可检查 demo-host replay/action-state-render input feedback/focus closed loop。下一条最值得推进的工程目标是：在 stage684 shared host inspection runtime contract 上接 host input feedback/focus loop，把 replay host inspection result 推进到更可复用的 feedback/focus route，同时继续保持无生产提交。
