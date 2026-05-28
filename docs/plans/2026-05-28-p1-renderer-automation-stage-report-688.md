# P1 Renderer Automation Stage Report 688

日期：2026-05-28

## 小设计

当前真实 tail 是 stage684 replay action-state-render host inspection runtime contract，属于 feedback/demo-host event-cycle 后的 replay host inspection/result contract 链路。最近多轮持续重复 feedback/replay -> inspection/result -> runtime contract 的同构节奏，本轮触发周期收敛；目标不是再做一个 input-feedback wrapper，而是把 stage684 host inspection runtime surface 提升为可复用 text input / form-field 内部模型。

本轮完成 stage685-688 four-slice macro package：stage685 消费 stage684 runtime contract，生成 replay host text edit field model；stage686 消费 stage685 field model，生成 text edit operation ledger 与 owner-local state delta dry-run；stage687 消费 stage686 dry-run receipts，生成 text/caret/validation/focus/submit RenderCommand/result surface refresh；stage688 消费 stage687 surfaces，抽出 shared replay host text input runtime contract/helper/execution receipt contract，并把 Todo、settings、AI-generated settings、chat composer 四个 demo 接到同一 runtime surface。关键 stop-line：不启用真实 input pipeline、不 dispatch、不提交 state、不发布 visibility、不执行 renderer、不写 renderer_state/runtime_state、不扩 native bridge 或 public API。

## Four Slices

1. Slice 1：新增 `runtime_renderer_stage685_replay_host_text_edit_field_model.cj`，消费 stage684 host inspection runtime contract，生成 shared replay host text edit field model、text value、selection、caret、validation preview、submit affordance 与四个 demo field models。
2. Slice 2：新增 `runtime_renderer_stage686_replay_host_text_edit_state_dry_run.cj`，直接消费 stage685 field model，生成 shared text edit operation ledger、insert/delete/submit/focus move dry-run、value/selection/caret/validation state delta dry-run 与四个 demo state receipts。
3. Slice 3：新增 `runtime_renderer_stage687_replay_host_text_edit_render_result_surface.cj`，直接消费 stage686 dry-run receipts，生成 shared text edit render/result surface、text-run RenderCommand refresh、caret/selection refresh、validation feedback refresh、focus feedback result surface、submit affordance result surface 与四个 demo surfaces。
4. Slice 4：新增 `runtime_renderer_stage688_replay_host_text_input_runtime_contract.cj`，直接消费 stage687 surfaces，抽出 shared replay host text input runtime contract/helper、shared execution receipt contract、`field_model_operation_state_render_result_runtime` cycle order，并把四个 demo surface 接入同一 runtime contract。

## 真实能力增量

- stage684 的 host inspection runtime surface 现在能落到具体 text input / form-field 内部模型，不再只停在 replay host inspection envelope。
- 文本输入的 value、selection、caret、validation preview、submit affordance 被统一为 shared field model，覆盖 Todo/settings/AI-generated settings/chat composer。
- 文本编辑操作被规范为 insert/delete/submit/focus move 的 owner-local dry-run，并继续保持无 action dispatch、无 state commit。
- dry-run state receipts 能刷新 text run、caret/selection、validation/focus feedback、submit affordance 与 result surface preview。
- stage688 抽出 shared replay host text input runtime contract/helper，减少后续 per-demo text input field/state/render/runtime owner-probe 模板复制。

本轮周期收敛已触发并完成：stage688 固定 `future_per_demo_text_input_runtime_template_need_reduced=true`，并将四个 demo 绑定到同一 `field_model_operation_state_render_result_runtime` contract，而不是继续复制 replay/input-feedback/inspection/result/runtime wrapper。

## 辅助 Envelope / Readiness

新增 owner structs、facts、readiness、owner probes 与 focused suites 属于辅助 envelope；它们服务于 text edit field model、operation/state dry-run、render/result refresh 与 shared text input runtime contract 的可验证链路，不声明 production render truth、backend-ready truth、owner acceptance granted、text shaping enabled 或 focus manager enabled。

## 修改文件

- `runtime/cjgui/src/runtime_renderer_stage685_replay_host_text_edit_field_model.cj`
- `runtime/cjgui/src/runtime_renderer_stage686_replay_host_text_edit_state_dry_run.cj`
- `runtime/cjgui/src/runtime_renderer_stage687_replay_host_text_edit_render_result_surface.cj`
- `runtime/cjgui/src/runtime_renderer_stage688_replay_host_text_input_runtime_contract.cj`
- `runtime/cjgui/native/scripts/verify_renderer_stage685_replay_host_text_edit_field_model_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage686_replay_host_text_edit_state_dry_run_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage687_replay_host_text_edit_render_result_surface_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage688_replay_host_text_input_runtime_contract_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage685_replay_host_text_edit_field_model_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage686_replay_host_text_edit_state_dry_run_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage687_replay_host_text_edit_render_result_surface_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage688_replay_host_text_input_runtime_contract_suite.sh`
- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`
- `docs/plans/2026-05-28-p1-renderer-automation-stage-report-688.md`

## 验证结果

- RED owner probes：stage685、stage686、stage687、stage688 owner scripts 在 source 缺失时均按预期 fail-closed。
- Owner probes：stage685、stage686、stage687、stage688 owner scripts 均通过。
- `cjfmt -f` 已逐个格式化 stage685-688 source；一次多文件 `cjfmt` 调用暴露当前工具只接受单文件参数，已改为逐文件格式化。
- Early `cjpm build --target-dir /private/tmp/cjgui-stage685-stage688-early/target --skip-script` 通过。
- Focused suite chain：
  - `verify_renderer_stage688_replay_host_text_input_runtime_contract_suite.sh` 通过，并串联 stage685、stage686、stage687 packet。
  - stage688 suite 执行 `cjpm build --target-dir /private/tmp/cjgui-stage685-stage688/stage688/target --skip-script`，通过；build log：`/private/tmp/cjgui-stage685-stage688/stage688/cjpm-build.log`。
  - stage688 packet：`/private/tmp/cjgui-stage685-stage688/stage688/stage688-replay-host-text-input-runtime-contract-suite.packet`，确认 shared runtime contract/helper、execution receipt contract、四个 demo runtime surfaces 与 `future_per_demo_text_input_runtime_template_need_reduced=true`。
- 新增 owner/suite scripts `zsh -n` 通过；stage688 suite 的 public/foreign scan、forbidden native/render token scan 与 protected path scan 通过。
- 独立 `git diff --check` 通过；独立 protected path check 确认 `runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m` 无 diff。

## GitNexus / CodeLattice

- 预编辑 `gitnexus context CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness --repo cangjie-live-codelattice`：symbol not found。
- 预编辑 `gitnexus impact CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness --repo cangjie-live-codelattice`：target not found，`risk=UNKNOWN`，`impactedCount=0`。未把 UNKNOWN 当作安全证明，按源码读取、RED/green owner probes、focused suite、build 与 scans 兜底。
- 后编辑 `gitnexus context CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractReadiness --repo cangjie-live-codelattice`：symbol not found。
- 后编辑 `gitnexus impact CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractReadiness --repo cangjie-live-codelattice`：target not found，`risk=UNKNOWN`，`impactedCount=0`。当前 graph 仍未覆盖 fresh stage688 owner。
- `gitnexus detect-changes --repo cangjie-live-codelattice --scope all`：`Changes: 5 files, 3 symbols`、`Affected processes: 0`、`Risk level: low`；changed symbols 仍仅为 README-style headings，fresh stage685-688 owner files 未被索引覆盖，因此只作为 indexed graph 参考。
- CodeLattice `project quick` / `symbol search` / `native_review` 均为 static-only，未执行 target code、scripts 或 coverage。`symbol search` summary risk low；`native_review` 建议继续以 targeted tests / source review 证明。`changed_symbols` 对 `/runtime/cjgui` 返回 `not_a_git_repo`，对 live repo root 返回 `path_denied`，因此不作为完整 change detection。
- alias status：live repo `/Users/jiangxuanyang/Desktop/cangjie`，registry `cangjie-live-codelattice` 指向 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`；工作区 dirty 较大，stable window RED，仅作状态提示，不执行 production smoke。

## Stop-Line

保持 `host_mutation=false`、`owner_acceptance_granted=false`、`production_render_truth=false`、`backend_ready_truth=false`、`public_component_api_added=false`、`text_shaping_enabled=false`、`focus_manager_enabled=false`、`input_event_pipeline_execution=false`、`action_dispatch=false`、`state_update_committed=false`、`visibility_publication_admitted=false`、`visibility_published=false`、`renderer_submission=false`、`renderer_state_write=false`、`runtime_state_write=false`、`native_bridge_expansion=false`。

本轮没有执行 bounded runtime native probe；该能力包不需要 live Metal/AppKit。未遇到新的 CJGUI harness 缺口或宿主限制。

## Current Endpoint / Next Route

Canonical endpoint：`CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractReadiness` / `cjguiInternalExecuteDefaultRendererStage688ReplayHostTextInputRuntimeContractDraft()`。

当前 next route：`stage689_replay_host_text_input_demo_host_integration_after_stage688`。

第一帧链路、renderer-state write、runtime_state write 仍未推进；minimal UI framework 距离真实 demo 还差真实 input event pipeline、action dispatch、owner-local state commit、真正 text shaping / selection editing、focus manager、layout/style resolver、RenderCommand 到 host/runtime surface 的实际刷新，以及 demo-host event integration。下一条最值得推进的工程目标是：在 stage688 shared text input runtime contract 上接 demo-host integration / host event adapter，让 text input field model 能进入可检查 host event queue / replay surface，同时继续保持无生产提交。
