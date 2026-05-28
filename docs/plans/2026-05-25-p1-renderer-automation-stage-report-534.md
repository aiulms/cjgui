# P1 Renderer Automation Stage Report 534

日期：2026-05-25

状态：completed / internal-only / normalized input event runway / no stage / no commit / no push

## 小设计

当前真实 tail 是 stage531 shared runtime demo cycle host probe readiness；它已经把 input/action/state/render/layout/probe 压成 shared runtime demo cycle host probe，但还缺 host-shaped input event 到 executor-consumable cycle input 的规范化入口。最近几轮反复在 layout/style preview、input/action/state dry-run、RenderCommand refresh 与 probe/readiness 间循环，本轮不能只再生成一个同构 probe。Slice 1 新增 shared input-event normalization contract，把 Todo click、settings toggle、AI-generated settings text input 三类 host event 归一为 shared normalized event ledger。Slice 2 消费 Slice 1，把 normalized events 适配为 stage529 cycle input / action intent draft，继续保持 non-dispatching。Slice 3 消费 Slice 2，把 Todo / settings / AI-generated settings 接入同一个 normalized event demo surface cycle probe helper，并减少后续 per-demo input adapter owner 复制。关键 stop-line：不启用真实 input event pipeline，不 dispatch action，不 commit state，不写 renderer_state / runtime_state，不扩 public API / native bridge。

## Three Slices

### Slice 1：stage532 shared input event normalization

新增 [runtime_renderer_stage532_input_event_normalization.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage532_input_event_normalization.cj)。它消费 `CjguiInternalRendererStage531SharedRuntimeDemoCycleHostProbeReadiness`，产出 `CjguiInternalRendererStage532InputEventNormalizationReadiness`。

本 slice materialize：

- `shared_input_event_normalization_contract_materialized=true`
- `host_input_event_shape_ledger_materialized=true`
- `todo_click_input_event_normalized=true`
- `settings_toggle_input_event_normalized=true`
- `ai_generated_settings_text_input_event_normalized=true`
- `input_event_normalization_bound_to_runtime_demo_cycle_host_probe=true`
- `normalized_events_bound_to_shared_runtime_demo_cycle_input_contract=true`
- `stage533_normalized_event_cycle_input_adapter_prepared=true`

它仍保持 owner-local、non-executing、non-dispatching，并保持 renderer submission / renderer-state write / runtime_state write blocked。

### Slice 2：stage533 normalized event cycle input adapter

新增 [runtime_renderer_stage533_normalized_event_cycle_input_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage533_normalized_event_cycle_input_adapter.cj)。它消费 fresh stage532 readiness，产出 `CjguiInternalRendererStage533NormalizedEventCycleInputAdapterReadiness`。

本 slice materialize：

- `normalized_event_to_cycle_input_adapter_materialized=true`
- `todo_normalized_event_action_intent_draft_materialized=true`
- `settings_normalized_event_action_intent_draft_materialized=true`
- `ai_generated_settings_normalized_event_action_intent_draft_materialized=true`
- `normalized_events_bound_to_stage529_cycle_inputs=true`
- `cycle_input_adapter_bound_to_stage530_executor_route=true`
- `cycle_input_adapter_state_dry_run_only=true`
- `cycle_input_adapter_render_preview_only=true`
- `stage534_normalized_event_demo_surface_cycle_probe_prepared=true`

Slice 2 直接消费 Slice 1 的 normalized events / normalization contract，并把它们接到 stage529/530 的 shared runtime demo cycle route，而不是新建每个 demo 一套 action adapter。

### Slice 3：stage534 normalized event demo surface cycle probe

新增 [runtime_renderer_stage534_normalized_event_demo_surface_cycle_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage534_normalized_event_demo_surface_cycle_probe.cj)。它消费 fresh stage533 readiness，产出 `CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness`。

本 slice materialize：

- `normalized_event_demo_surface_cycle_probe_contract_materialized=true`
- `normalized_event_demo_surface_cycle_probe_helper_materialized=true`
- `todo_normalized_event_demo_surface_cycle_probe_input_materialized=true`
- `settings_normalized_event_demo_surface_cycle_probe_input_materialized=true`
- `ai_generated_settings_normalized_event_demo_surface_cycle_probe_input_materialized=true`
- `normalized_event_cycle_probe_bound_to_stage531_host_probe=true`
- `normalized_event_cycle_probe_bound_to_stage530_executor=true`
- `normalized_event_cycle_probe_bound_to_todo_settings_ai_generated_settings=true`
- `per_demo_input_adapter_duplication_reduced=true`
- `stage535_shared_runtime_demo_cycle_event_state_refresh_prepared=true`

Slice 3 直接消费 Slice 2 的 normalized event -> cycle input adapter 和 action intent drafts，把 Todo / settings / AI-generated settings 接入同一 shared probe contract/helper。它把 dry-run 结果推进为可检查的 demo surface cycle probe input，但仍不是 runtime input pipeline truth。

## 真实能力增量

本轮新增的是最小 UI framework 内部的 shared input-event normalization 能力族：host-shaped input event 可以先被归一化，再被适配为 shared runtime demo cycle input / action intent draft，最后由同一个 demo surface cycle probe helper 检查 Todo / settings / AI-generated settings 三个 demo 的输入形状。它接在 stage529-531 的 shared cycle executor 后面，让后续真实 input pipeline 可以少复制 per-demo action adapter / probe owner。

这不是只新增 owner/readiness：stage532 定义公共内部 normalized event shape；stage533 把 normalized event 接到 existing cycle route；stage534 把三个 demo surface 接到同一 helper 并明确减少模板复制。

## 周期收敛

触发了周期收敛判断。stage529-531 已经完成 shared runtime demo cycle executor 收敛，本轮没有继续复制 layout preview -> runtime probe -> action adapter 的同构链，而是推进新的真实能力族：input event normalization。收敛结果是 `shared_input_event_normalization_contract`、`normalized_event_to_cycle_input_adapter` 与 `normalized_event_demo_surface_cycle_probe_helper` 成为后续 input/event/state/render route 的公共内部入口。

## 辅助 Envelope / Readiness

`CjguiInternalRendererStage532InputEventNormalizationReadiness`、`CjguiInternalRendererStage533NormalizedEventCycleInputAdapterReadiness`、`CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness` 只是 internal proof envelopes。它们不声明 production render truth、backend-ready truth、owner acceptance、visibility publication、renderer submission、runtime input pipeline execution 或 public component API。

## 修改文件

新增 source：

- [runtime_renderer_stage532_input_event_normalization.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage532_input_event_normalization.cj)
- [runtime_renderer_stage533_normalized_event_cycle_input_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage533_normalized_event_cycle_input_adapter.cj)
- [runtime_renderer_stage534_normalized_event_demo_surface_cycle_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage534_normalized_event_demo_surface_cycle_probe.cj)

新增 focused probes / suites：

- [verify_renderer_stage532_input_event_normalization_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage532_input_event_normalization_owner.sh)
- [verify_renderer_stage532_input_event_normalization_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage532_input_event_normalization_suite.sh)
- [verify_renderer_stage533_normalized_event_cycle_input_adapter_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage533_normalized_event_cycle_input_adapter_owner.sh)
- [verify_renderer_stage533_normalized_event_cycle_input_adapter_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage533_normalized_event_cycle_input_adapter_suite.sh)
- [verify_renderer_stage534_normalized_event_demo_surface_cycle_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage534_normalized_event_demo_surface_cycle_probe_owner.sh)
- [verify_renderer_stage534_normalized_event_demo_surface_cycle_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage534_normalized_event_demo_surface_cycle_probe_suite.sh)

Latest-entry sync：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)

## 验证结果

Focused RED：

- stage532 owner probe 在 source 缺失时失败，确认 probe 能捕获 missing source。
- stage533 owner probe 在 source 缺失时失败，确认 probe 能捕获 missing source。
- stage534 owner probe 在 source 缺失时失败，确认 probe 能捕获 missing source。

Focused GREEN：

- `zsh runtime/cjgui/native/scripts/verify_renderer_stage532_input_event_normalization_owner.sh`
- `zsh runtime/cjgui/native/scripts/verify_renderer_stage533_normalized_event_cycle_input_adapter_owner.sh`
- `zsh runtime/cjgui/native/scripts/verify_renderer_stage534_normalized_event_demo_surface_cycle_probe_owner.sh`

Fresh chain, pre-format：

- stage532 suite consumed `/private/tmp/cjgui-stage529-stage531-postfmt/stage531/stage531-shared-runtime-demo-cycle-host-probe-suite.packet` and produced `/private/tmp/cjgui-stage532-stage534-prefmt/stage532/stage532-input-event-normalization-suite.packet`.
- stage533 suite consumed the stage532 packet and produced `/private/tmp/cjgui-stage532-stage534-prefmt/stage533/stage533-normalized-event-cycle-input-adapter-suite.packet`.
- stage534 suite consumed the stage533 packet and produced `/private/tmp/cjgui-stage532-stage534-prefmt/stage534/stage534-normalized-event-demo-surface-cycle-probe-suite.packet`.

Formatting and post-format verification:

- `cjfmt -f` passed for all three new `.cj` files after sourcing `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` with a local `ps` shim because the sandbox blocks `ps`.
- All three owner probes passed again post-format.
- All six suite scripts passed `zsh -n`.
- Fresh stage532 -> stage533 -> stage534 post-format chain passed and produced `/private/tmp/cjgui-stage532-stage534-postfmt/stage534/stage534-normalized-event-demo-surface-cycle-probe-suite.packet`.

Build / scans:

- `env CLANG_MODULE_CACHE_PATH=/private/tmp/cjgui-stage532-stage534-final-build/clang-cache cjpm build --target-dir /private/tmp/cjgui-stage532-stage534-final-build/target --skip-script` passed under `runtime/cjgui`; current baseline still prints existing warnings.
- New source public/foreign scan passed.
- New source forbidden native/render token scan passed after comment stripping.
- Protected path diff scan confirmed no changes to `runtime/cjgui/cjpm.toml`, `runtime/cjgui/src/runtime_state.cj`, `runtime/cjgui/native/cjgui_native_bridge.h`, or `runtime/cjgui/native/cjgui_native_bridge.m`.
- Trailing whitespace / tab scan passed for the nine new files.

Final workspace check:

- `git diff --check`: passed after latest-entry docs were written.

## GitNexus / CodeLattice

Pre-edit `gitnexus context` / `impact` on `CjguiInternalRendererStage531SharedRuntimeDemoCycleHostProbeReadiness` and `cjguiInternalExecuteDefaultRendererStage531SharedRuntimeDemoCycleHostProbeDraft` returned not found / `UNKNOWN`. That was not treated as safe proof; source reading, stage531 packet validation, focused probes, scans, and build were used as fallback.

Post-edit `gitnexus context` / `impact` on `CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness` also returned not found / `UNKNOWN`. MCP `gitnexus detect_changes --repo cangjie-live-codelattice --scope all` and the Tool CLI command `node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js detect-changes --repo cangjie-live-codelattice --scope all` both reported low risk with changed docs symbols only, so the graph did not cover the new stage532-534 source symbols. `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status` confirmed the active registry entry is `cangjie-live-codelattice`, path `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`, indexed 2026-05-11, commit unknown; it also flagged the large dirty worktree as RED, which matches the existing untracked automation artifacts and was not treated as a production smoke pass. CodeLattice workspace impact was static-only (`runtimeProof=false`, scripts not executed) and did not provide runtime proof. This report therefore treats GitNexus / CodeLattice as incomplete coverage, not as safety evidence.

## Canonical Endpoint / Next Route

Current endpoint:

- `CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness`
- `cjguiInternalExecuteDefaultRendererStage534NormalizedEventDemoSurfaceCycleProbeDraft()`

Current next route:

- `stage535_shared_runtime_demo_cycle_event_state_refresh_after_stage534`

The next valuable engineering move is to consume the normalized event demo surface cycle probe and produce owner-local event/state refresh candidates that can later feed the existing state update -> RenderCommand refresh bridge, still without dispatch or committed state write.

## Runtime Native Probe / Harness

No bounded runtime native probe was executed in this run. The changed surface is internal owner/probe source plus shell suites; no native bridge, AppKit/Metal live path, `runtime_state.cj`, or renderer-state write path changed. No new CJGUI harness gap or host limitation was encountered beyond the known sandbox `ps` restriction while sourcing the Cangjie toolchain envsetup.

## Remaining Distance To Real UI

First-frame and visible-window evidence remain prior-run evidence only; this run did not create new production render truth. Renderer-state write and `runtime_state` write remain blocked. Minimal UI framework still lacks real host input ingestion, input normalization execution inside runtime, action dispatch, committed state update, real RenderCommand refresh execution, layout engine, style resolver, text shaping, focus manager, backend submission, demo host integration, and public component API.

## Stop State

The three-slice macro package is complete. No production truth, backend-ready truth, renderer submission, renderer-state write, runtime_state write, native bridge expansion, public component API, action dispatch, or committed state update was introduced. No files were staged, committed, or pushed.
