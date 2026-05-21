# P1 Renderer Automation Stage Report 204

日期：2026-05-20

## 本轮主题阶段包

本轮主题是 `stage201 write-token reevaluation -> stage202 Scene / RenderCommand bridge -> stage203 semantic node fixture -> stage204 component demo state-update dry-run`。它接续 stage200 write readiness recheck join，把 renderer-state write token 重新评估输入接到既有 `runtime_scene_renderer_input.cj` 的 `RenderBatchingPacket`，并第一次把这条 admission 链路输出为最小 UI framework runway 输入。

本轮没有执行 bounded runtime native first-frame probe。当前 shell 复核为 `metal_capable_shell_observed=false`、`smoke_exit_code=20`、`failure_domain=automation_environment`、`code_failure_domain=false`；这次没有继续扩写 no-device denial，而是推进不依赖 live Metal 的 token decision、Scene / RenderCommand bridge、semantic node fixture 与 component demo dry-run。

## 工程闭环

1. `stage201` write-token reevaluation：新增 internal owner [runtime_renderer_stage201_write_token_reevaluation.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage201_write_token_reevaluation.cj) 与 owner probe [verify_renderer_stage201_write_token_reevaluation_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage201_write_token_reevaluation_owner.sh)。它消费 stage200 readiness join，物化 `write_token_decision_envelope_materialized=true` 与 `write_token_missing_predicate_receipt_materialized=true`，但保持 write token / renderer_state_write 为 false。

2. `stage202` Scene / RenderCommand bridge：新增 [runtime_renderer_stage202_scene_render_command_bridge.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage202_scene_render_command_bridge.cj) 与 owner probe [verify_renderer_stage202_scene_render_command_bridge_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage202_scene_render_command_bridge_owner.sh)。它把 stage201 token decision 与既有 `CjguiInternalRenderBatchingPacket` 接成 `scene_render_command_runway_bridge_materialized=true`，不触发 renderer submission。

3. `stage203` semantic node positive fixture：新增 [runtime_renderer_stage203_semantic_node_fixture.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage203_semantic_node_fixture.cj) 与 owner probe [verify_renderer_stage203_semantic_node_fixture_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage203_semantic_node_fixture_owner.sh)。它生成 internal Rect / Text / Button-like semantic node fixture，并准备 stage204 demo dry-run 输入；没有扩 public component API、layout engine 或 input pipeline。

4. `stage204` component demo state-update dry-run：新增 [runtime_renderer_stage204_component_demo_state_update_dry_run.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage204_component_demo_state_update_dry_run.cj) 与 owner probe [verify_renderer_stage204_component_demo_state_update_dry_run_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage204_component_demo_state_update_dry_run_owner.sh)。它物化 `component_demo_state_update_dry_run_materialized=true`、`owner_local_rollback_preview_materialized=true` 与 `visibility_not_published_boundary_materialized=true`，准备 stage205 component demo RenderCommand admission input。

5. `stage201-204` focused suite 与 slow-path 成本治理：新增 [verify_renderer_stage201_204_ui_runway_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage201_204_ui_runway_suite.sh)。初版默认 slow-path 会重生 stage197-200 packet，在当前 shell 会长时间停在上游 stage149 / stage150 packet 子链；该路径最后完成，但验证成本明显不适合作为默认复核。本轮改为默认 fast-path，要求注入已验证 stage200 packet，只有显式设置 `CJGUI_STAGE201_204_ALLOW_SLOW_STAGE200_REGEN=true` 才重生上游。

## 新增正向条件

- `write_token_decision_envelope_materialized=true`
- `write_token_missing_predicate_receipt_materialized=true`
- `scene_render_command_runway_bridge_materialized=true`
- `render_batching_packet_consumed=true`
- `internal_rect_semantic_node_materialized=true`
- `internal_text_semantic_node_materialized=true`
- `internal_button_like_semantic_node_materialized=true`
- `component_demo_state_update_dry_run_materialized=true`
- `owner_local_rollback_preview_materialized=true`
- `visibility_not_published_boundary_materialized=true`
- `minimal_ui_framework_runway_input_prepared=true`
- `stage205_component_demo_render_command_admission_input_prepared=true`

## 验证结果

- Metal capability detector：`metal_capable_shell_observed=false`、`failure_domain=automation_environment`、`code_failure_domain=false`；未执行 bounded runtime native probe。
- RED owner probes：stage201、stage202、stage203、stage204 owner probe 在 source 缺失时均按预期 exit 2。
- GREEN owner probes：stage201、stage202、stage203、stage204 owner probes 均通过。
- Runtime package build：`cjpm build --target-dir /tmp/cjgui-stage201-204-early-build-target --skip-script` 通过；final suite build 也通过。
- Slow-path suite：`/tmp/cjgui-stage201-204-suite-final-23090/stage204-component-demo-state-update-dry-run-suite.packet`，`stage201_204_ui_runway_suite_passed=true`；该路径验证成本高，已改为显式 opt-in。
- Final fast-path suite：`/tmp/cjgui-stage201-204-suite-final-3-49719/stage204-component-demo-state-update-dry-run-suite.packet`，`stage201_204_ui_runway_suite_passed=true`。
- Public / foreign / forbidden native-render token scan：stage201-204 owner sources 通过。
- Protected path scan：未改动 `runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m`。
- `runtime_state.cj` 行数保持 `10065`，本轮没有 runtime_state schema/write-path 变更。
- `git diff --check` 通过。

## GitNexus / CodeLattice

已按 `cangjie-live-codelattice` 路线先做 impact。`CjguiInternalRendererStage200WriteReadinessRecheckJoinReadiness` 与 stage200 default draft 在当前 graph 中返回 not found / `UNKNOWN`，不能作为安全证明；`CjguiInternalRenderBatchingPacket` 与 `cjguiInternalExecuteDefaultRenderBatchingHintDraft` 在 `src/runtime_scene_renderer_input.cj` 中 upstream impact 为 LOW、0 direct callers、0 affected processes。最终 MCP 与 CLI `detect-changes --repo cangjie-live-codelattice --scope all` 返回 `changed_files=7`、`changed_symbols=2`、`affected_processes=0`、`risk_level=low`，但当前索引不覆盖本轮 untracked stage201-204 owner，不能把 low risk 当作完整证明。CodeLattice native review 仍为 static-only caution。

## 当前 endpoint / next route

Canonical endpoint：

- `CjguiInternalRendererStage204ComponentDemoStateUpdateDryRunReadiness`
- `cjguiInternalExecuteDefaultRendererStage204ComponentDemoStateUpdateDryRunDraft()`

Next route：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness stage205 component demo RenderCommand admission after state-update dry-run: consume stage204 packet, map owner-local semantic node fixture and component demo state update dry-run into an internal RenderCommand admission / preview packet, keep public component API, layout engine, input pipeline, renderer submission, renderer_state_write, runtime_state_write, native bridge and public C ABI blocked until production truth, semantic runtime admission, write token, guarded executor, visibility and rollback predicates are verified.`

## 剩余缺口

第一帧链路剩余缺口：当前 shell 不能刷新 live bounded first-frame observation；需要 Metal-capable shell 重跑 first-frame / baseline / semantic / production truth recheck，再把新 packet 注入 write admission 链。

renderer-state write / runtime_state write 剩余缺口：`production_render_truth=false`、`backend_ready_truth=false`、`semantic_runtime_admission=false`、`result_envelope_promotion_token=false`、`renderer_state_write_token=false`、`renderer_state_write_eligibility=false`、`visibility_publication_admitted=false`。本轮只生成 token decision envelope 和 UI runway dry-run，不做真实 renderer/runtime state mutation。

最小 UI framework 剩余缺口：已有 internal Rect / Text / Button-like semantic node fixture 与 component demo state-update dry-run 输入，但还没有 public component model、layout/style resolution、input/action bridge、focus/text editing、scroll 或 demo app rendering。下一条最值得推进的是 stage205：把 stage204 dry-run 输入接成 internal RenderCommand admission / preview packet，为 Todo / settings panel 级 demo 的可渲染命令链路铺路。
