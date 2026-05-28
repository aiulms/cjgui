# P1 Renderer Automation Stage Report 522

日期：2026-05-25

状态：completed / internal-only / no stage / no commit / no push

## 小设计

当前真实 tail 是 `stage519_demo_surface_refresh_runtime_preview_probe`，属于 layout/style/text/focus preview 已进入 runtime preview/probe 后的 input/action/state 链路。  
本轮完成三个连续 slice：runtime preview/probe -> focus/input action adapter -> action state-update dry-run -> state-to-RenderCommand refresh。  
Slice 2 直接消费 Slice 1 的 shared focus/input adapter、contract 与三个 demo runtime intents，生成 owner-local state update candidates、rollback preview 与 runtime probe v3 binding。  
Slice 3 直接消费 Slice 2 的 state candidates 和 rollback preview，抽出 shared refreshed state-to-RenderCommand refresh helper v2，并把 Todo/settings/AI-generated settings 接成可检查 RenderCommand probe inputs。  
关键 stop-line 是不进入真实 input pipeline、action dispatch、state commit、renderer submission、visibility publication、renderer_state/runtime_state write、native bridge 或 public C ABI。

## Three Slices

### Slice 1: stage520 focus/input action adapter v3

新增 `runtime_renderer_stage520_demo_surface_refresh_focus_input_action_adapter.cj`。它消费 `CjguiInternalRendererStage519DemoSurfaceRefreshRuntimePreviewProbeReadiness`，把 stage519 runtime preview/probe contract helper v3 和三个 demo runtime probe inputs 接成 shared non-dispatching focus/input action adapter v3。

产出包括：

- `shared_demo_surface_refresh_refreshed_focus_input_action_adapter_materialized=true`
- `demo_surface_refresh_refreshed_focus_input_adapter_contract_materialized=true`
- `refreshed_focus_input_adapter_contract_bound_to_runtime_probe_v3=true`
- Todo focus activation intent、settings toggle intent、AI-generated settings submit intent
- `stage521_demo_surface_refresh_action_state_update_dry_run_prepared=true`

### Slice 2: stage521 action state-update dry-run v3

新增 `runtime_renderer_stage521_demo_surface_refresh_action_state_update_dry_run.cj`。它消费 stage520 adapter/contract/intents，生成 owner-local state update dry-run、三个 demo state update candidates、rollback preview，并将 state update dry-run 绑定回 runtime probe v3。

产出包括：

- `stage520_demo_surface_refresh_focus_input_action_adapter_consumed=true`
- `shared_demo_surface_refresh_refreshed_action_state_update_dry_run_materialized=true`
- Todo/settings/AI-generated settings refreshed state update candidates
- `refreshed_action_state_update_to_runtime_probe_v3_bound=true`
- `stage522_demo_surface_refresh_state_render_command_refresh_prepared=true`

### Slice 3: stage522 state-to-RenderCommand refresh helper v2

新增 `runtime_renderer_stage522_demo_surface_refresh_state_render_command_refresh.cj`。它消费 stage521 state candidates 与 rollback preview，产出 shared refreshed state-to-RenderCommand refresh、shared helper v2、三个 demo RenderCommand probe inputs，并准备 layout/style preview 的下一跳。

产出包括：

- `stage521_demo_surface_refresh_action_state_update_dry_run_consumed=true`
- `stage520_demo_surface_refresh_focus_input_action_adapter_consumed_transitively=true`
- `stage519_demo_surface_refresh_runtime_preview_probe_consumed_transitively=true`
- `shared_demo_surface_refresh_refreshed_state_render_command_refresh_materialized=true`
- `demo_surface_refresh_refreshed_state_to_render_command_refresh_helper_v2_materialized=true`
- `demo_surface_refresh_refreshed_state_to_render_command_refresh_helper_v2_bound_to_demo_surfaces=true`
- Todo/settings/AI-generated settings refreshed RenderCommand probe inputs
- `refreshed_state_update_dry_run_to_render_command_refresh_bound=true`
- `refreshed_render_command_refresh_to_layout_style_preview_bridge_bound=true`
- `stage523_demo_surface_refresh_layout_style_preview_prepared=true`

## 真实能力增量

本轮把 stage519 的 runtime preview/probe 输出推进成可复用的 internal UI framework 链路：focus/input adapter v3 产生 owner-local action intents，state-update dry-run v3 消费这些 intents 并生成 demo-local state candidates，state-to-RenderCommand helper v2 再把 state candidates 转成 Todo/settings/AI-generated settings 的 RenderCommand probe inputs。

完成的 shared helper / common contract / demo surface 接入：

- shared focus/input action adapter contract bound to runtime probe v3
- shared owner-local action state-update dry-run contract
- shared refreshed state-to-RenderCommand refresh helper v2
- Todo/settings/AI-generated settings 三个 demo surface 的 action intent、state candidate 与 RenderCommand probe input

辅助 envelope / readiness 仅用于 owner-local proof 和 probe packet 串接；它们不代表 production render truth、backend-ready truth、public API 或 runtime execution truth。

## 修改文件

Source:

- [runtime_renderer_stage520_demo_surface_refresh_focus_input_action_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage520_demo_surface_refresh_focus_input_action_adapter.cj)
- [runtime_renderer_stage521_demo_surface_refresh_action_state_update_dry_run.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage521_demo_surface_refresh_action_state_update_dry_run.cj)
- [runtime_renderer_stage522_demo_surface_refresh_state_render_command_refresh.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage522_demo_surface_refresh_state_render_command_refresh.cj)

Focused scripts:

- [verify_renderer_stage520_demo_surface_refresh_focus_input_action_adapter_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage520_demo_surface_refresh_focus_input_action_adapter_owner.sh)
- [verify_renderer_stage520_demo_surface_refresh_focus_input_action_adapter_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage520_demo_surface_refresh_focus_input_action_adapter_suite.sh)
- [verify_renderer_stage521_demo_surface_refresh_action_state_update_dry_run_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage521_demo_surface_refresh_action_state_update_dry_run_owner.sh)
- [verify_renderer_stage521_demo_surface_refresh_action_state_update_dry_run_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage521_demo_surface_refresh_action_state_update_dry_run_suite.sh)
- [verify_renderer_stage522_demo_surface_refresh_state_render_command_refresh_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage522_demo_surface_refresh_state_render_command_refresh_owner.sh)
- [verify_renderer_stage522_demo_surface_refresh_state_render_command_refresh_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage522_demo_surface_refresh_state_render_command_refresh_suite.sh)

Docs:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [2026-05-25-p1-renderer-automation-stage-report-522.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-25-p1-renderer-automation-stage-report-522.md)

Protected files not modified:

- [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)
- [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

## 验证结果

RED probes:

- stage520 owner/suite failed before source existed as expected.
- stage521 owner/suite failed before source existed as expected.
- stage522 owner/suite failed before source existed as expected.

GREEN probes:

- stage520 owner probe passed.
- stage521 owner probe passed.
- stage522 owner probe passed.
- pre-format focused chain passed from stage519 packet through stage520 -> stage521 -> stage522.
- post-format focused chain passed:
  - `/private/tmp/cjgui-stage520-stage522-postfmt/stage520/stage520-demo-surface-refresh-focus-input-action-adapter-suite.packet`
  - `/private/tmp/cjgui-stage520-stage522-postfmt/stage521/stage521-demo-surface-refresh-action-state-update-dry-run-suite.packet`
  - `/private/tmp/cjgui-stage520-stage522-postfmt/stage522/stage522-demo-surface-refresh-state-render-command-refresh-suite.packet`

Formatting and scripts:

- `cjfmt -f` passed for the three new `.cj` files.
- `cjfmt -f` rejects multiple file arguments in this toolchain; reran one file at a time.
- `zsh -n` passed for all six new focused scripts.

Build and scans:

- `cjpm build --target-dir /private/tmp/cjgui-stage522-final-independent-build/target --skip-script` passed after sourcing `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`.
- Build emitted the existing broad unused-warning baseline; no build failure.
- `git diff --check` passed before and after latest-entry doc sync.
- Public/foreign declaration scan on the three new owner files produced no matches.
- Native/render forbidden-token scan on comment-stripped owner files produced no matches.
- Protected path diff scan for `runtime_state.cj`, `cjpm.toml`, native bridge header and implementation produced no changed paths.

## GitNexus / CodeLattice

Repository rule used: `cangjie-live-codelattice`.

Pre-edit:

- GitNexus MCP context/impact for the stage519 tail returned target not found / UNKNOWN.
- Tool CLI impact for stage519 and stage520 also returned not found / UNKNOWN.
- CodeLattice `production_assist` ran static-only for stage519 and reported no runtime proof.
- This was not treated as safety proof; source reading, RED/GREEN focused probes, scans and build were used as fallback evidence.

Post-edit:

- GitNexus MCP impact/context for `CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness` returned target not found / UNKNOWN / impacted count 0.
- GitNexus MCP detect-changes saw only tracked doc changes and did not cover the untracked new owner/script files.
- Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all` reported 5 files / 2 symbols / 0 affected processes / low risk, again limited to tracked README symbols.
- CodeLattice post-edit review was static-only; it did not execute probes or build.

Graph coverage did not cover the new stage520-522 symbols, so the blast radius is not proven by GitNexus. Known source-level impact is limited to new internal-only owner files and focused scripts plus latest-entry docs; no direct callers were changed, no public API was added, and no protected runtime/native bridge path changed.

## Endpoint And Next Route

Current canonical endpoint:

- `CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness`
- `cjguiInternalExecuteDefaultRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshDraft()`

Current next route:

- `stage523_demo_surface_refresh_layout_style_preview_after_stage522`

This is the natural continuation back into layout/style/text/focus preview, now driven by refreshed state-to-RenderCommand probe inputs from Todo/settings/AI-generated settings.

## Runtime / Native Probe

Bounded runtime native probe was not executed. This package stayed in internal owner/probe and `cjpm build --skip-script` scope; it did not modify native bridge, renderer runtime state, public C ABI, or live Metal/AppKit call sites. No new CJGUI harness gap or host limitation was encountered. The only toolchain issue found was `cjfmt -f` argument shape, corrected by formatting each file individually.

## Remaining Distance

First-frame chain remains prior evidence only; this run did not add a new live first-frame observation.

Renderer-state write remains blocked: no renderer_state write, no renderer submission, and no visibility publication was admitted.

`runtime_state` write remains blocked: no `runtime_state.cj` edit and no global state commit.

Minimal UI framework is closer because the demo path now has a reusable internal action -> state update dry-run -> RenderCommand refresh helper chain, but it still lacks real input event ingestion, real action dispatch, committed state update, layout engine execution, text shaping, focus manager, backend submission and public component API.

## Stop State

No stage, commit, or push was performed.

Stopping reason: the requested three-slice macro package is complete, focused probes and build passed, latest-entry docs were synced, and the next route is explicit.
