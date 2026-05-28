# P1 Renderer Automation Stage Report 525

日期：2026-05-25

状态：completed / internal-only / no stage / no commit / no push

## 小设计

当前真实 tail 是 `stage523_demo_surface_refresh_layout_style_preview_after_stage522`，属于 RenderCommand probe input 已回到 layout/style/text/focus preview 的能力链路。  
本轮完成三个连续 slice：state RenderCommand refresh -> checkable layout/style preview -> layout execution receipt -> checkable runtime preview/probe input。  
Slice 2 直接消费 Slice 1 的 checkable preview contract、三个 demo preview nodes 与 RenderCommand-to-layout binding，生成 owner-local layout execution receipts 与 shared layout execution helper v4。  
Slice 3 直接消费 Slice 2 的 execution receipts/helper，把 dry-run receipt 推进为 Todo/settings/AI-generated settings 三个 demo surface 的 checkable runtime probe inputs，并抽出 checkable runtime probe helper v4。  
关键 stop-line 是不启用 layout engine、style resolver、text shaping、focus manager，不执行 input pipeline/action dispatch/state commit，不做 renderer submission、visibility publication、renderer_state/runtime_state write、native bridge 或 public API 扩张。

## Three Slices

### Slice 1: stage523 checkable layout/style preview

新增 `runtime_renderer_stage523_demo_surface_refresh_layout_style_preview.cj`。它消费 `CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness`，把 stage522 refreshed state-to-RenderCommand helper v2 与 Todo/settings/AI-generated settings 三个 RenderCommand probe inputs 转成可检查的 layout/style/text/focus preview contract。

产出包括：

- `stage522_demo_surface_refresh_state_render_command_refresh_consumed=true`
- `shared_demo_surface_refresh_checkable_layout_style_text_focus_preview_materialized=true`
- `demo_surface_refresh_checkable_layout_preview_contract_materialized=true`
- `demo_surface_refresh_checkable_layout_preview_contract_bound_to_demo_surfaces=true`
- Todo/settings/AI-generated settings checkable layout/style preview nodes
- `refreshed_render_command_refresh_to_checkable_layout_style_preview_bound=true`
- `stage524_demo_surface_refresh_layout_execution_receipt_prepared=true`

### Slice 2: stage524 layout execution receipt/helper v4

新增 `runtime_renderer_stage524_demo_surface_refresh_layout_execution_receipt.cj`。它消费 stage523 preview/contract/nodes，生成 shared checkable layout execution receipt、text/focus affordance receipt、三个 demo layout execution receipts，并抽出 `demo_surface_refresh_layout_execution_helper_v4`。

产出包括：

- `stage523_demo_surface_refresh_layout_style_preview_consumed=true`
- `stage522_demo_surface_refresh_state_render_command_refresh_consumed_transitively=true`
- `shared_demo_surface_refresh_checkable_layout_execution_receipt_materialized=true`
- `demo_surface_refresh_layout_execution_helper_v4_materialized=true`
- `demo_surface_refresh_layout_execution_helper_v4_bound_to_demo_surfaces=true`
- Todo/settings/AI-generated settings layout execution receipts
- `checkable_layout_style_preview_to_execution_receipt_bound=true`
- `stage525_demo_surface_refresh_checkable_runtime_probe_prepared=true`

### Slice 3: stage525 checkable runtime preview/probe

新增 `runtime_renderer_stage525_demo_surface_refresh_checkable_runtime_probe.cj`。它消费 stage524 execution receipts/helper v4，把 dry-run receipt 推进为 shared checkable runtime preview/probe contract、helper v4 和三个 demo surface runtime probe inputs。

产出包括：

- `stage524_demo_surface_refresh_layout_execution_receipt_consumed=true`
- `stage523_demo_surface_refresh_layout_style_preview_consumed_transitively=true`
- `stage522_demo_surface_refresh_state_render_command_refresh_consumed_transitively=true`
- `shared_demo_surface_refresh_checkable_runtime_preview_probe_contract_materialized=true`
- `demo_surface_refresh_checkable_runtime_probe_helper_v4_materialized=true`
- `demo_surface_refresh_checkable_runtime_probe_helper_v4_bound_to_demo_surfaces=true`
- Todo/settings/AI-generated settings checkable runtime probe inputs
- `layout_execution_receipt_to_checkable_runtime_probe_bound=true`
- `checkable_runtime_probe_bound_to_focus_input_adapter_next=true`
- `stage526_demo_surface_refresh_focus_input_action_adapter_prepared=true`

## 真实能力增量

本轮把 stage522 的 refreshed RenderCommand probe inputs 推进成更接近真实 UI framework 的可复用内部链路：RenderCommand 输入先被映射为可检查 layout/style/text/focus preview contract，再变成 layout execution receipt/helper，最后变成 Todo/settings/AI-generated settings 三个 demo surface 可检查 runtime probe input。

完成的 shared helper / common contract / demo surface 接入：

- shared checkable layout/style/text/focus preview contract
- shared checkable layout execution receipt
- `demo_surface_refresh_layout_execution_helper_v4`
- shared checkable runtime preview/probe contract
- `demo_surface_refresh_checkable_runtime_probe_helper_v4`
- Todo/settings/AI-generated settings 三个 demo surface 的 preview nodes、execution receipts 与 checkable runtime probe inputs

辅助 envelope / readiness 仅用于 owner-local proof 和 focused probe packet 串接；它们不代表 production render truth、backend-ready truth、runtime execution truth、public component API 或 renderer/backend readiness。

## 修改文件

Source:

- [runtime_renderer_stage523_demo_surface_refresh_layout_style_preview.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage523_demo_surface_refresh_layout_style_preview.cj)
- [runtime_renderer_stage524_demo_surface_refresh_layout_execution_receipt.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage524_demo_surface_refresh_layout_execution_receipt.cj)
- [runtime_renderer_stage525_demo_surface_refresh_checkable_runtime_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage525_demo_surface_refresh_checkable_runtime_probe.cj)

Focused scripts:

- [verify_renderer_stage523_demo_surface_refresh_layout_style_preview_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage523_demo_surface_refresh_layout_style_preview_owner.sh)
- [verify_renderer_stage523_demo_surface_refresh_layout_style_preview_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage523_demo_surface_refresh_layout_style_preview_suite.sh)
- [verify_renderer_stage524_demo_surface_refresh_layout_execution_receipt_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage524_demo_surface_refresh_layout_execution_receipt_owner.sh)
- [verify_renderer_stage524_demo_surface_refresh_layout_execution_receipt_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage524_demo_surface_refresh_layout_execution_receipt_suite.sh)
- [verify_renderer_stage525_demo_surface_refresh_checkable_runtime_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage525_demo_surface_refresh_checkable_runtime_probe_owner.sh)
- [verify_renderer_stage525_demo_surface_refresh_checkable_runtime_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage525_demo_surface_refresh_checkable_runtime_probe_suite.sh)

Docs:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [2026-05-25-p1-renderer-automation-stage-report-525.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-25-p1-renderer-automation-stage-report-525.md)

Protected files not modified:

- [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)
- [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

## 验证结果

RED probes:

- stage523 owner/suite failed before source existed as expected.
- stage524 owner/suite failed before source existed as expected.
- stage525 owner/suite failed before source existed as expected.

GREEN probes:

- stage523 owner probe passed.
- stage524 owner probe passed.
- stage525 owner probe passed.
- pre-format focused chain passed from a fresh stage522 packet through stage523 -> stage524 -> stage525.
- post-format focused chain passed:
  - `/private/tmp/cjgui-stage523-stage525-postfmt/stage522/stage522-demo-surface-refresh-state-render-command-refresh-suite.packet`
  - `/private/tmp/cjgui-stage523-stage525-postfmt/stage523/stage523-demo-surface-refresh-layout-style-preview-suite.packet`
  - `/private/tmp/cjgui-stage523-stage525-postfmt/stage524/stage524-demo-surface-refresh-layout-execution-receipt-suite.packet`
  - `/private/tmp/cjgui-stage523-stage525-postfmt/stage525/stage525-demo-surface-refresh-checkable-runtime-probe-suite.packet`

Formatting and scripts:

- `cjfmt -f` passed for the three new `.cj` files after sourcing envsetup with a local `ps` shim; direct envsetup first failed because sandboxed `ps` made shell detection report unsupported shell.
- `zsh -n` passed for all six new focused scripts.

Build and scans:

- `cjpm build --target-dir /private/tmp/cjgui-stage525-final-independent-build/target --skip-script` passed after sourcing `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` with the same `ps` shim.
- Build emitted the existing broad unused-warning baseline plus one new unused default draft warning for stage525; no build failure.
- `git diff --check` passed before and after latest-entry doc sync.
- Public/foreign declaration scan on the three new owner files produced no matches.
- Native/render forbidden-token scan on comment-stripped owner files produced no matches.
- Protected path diff scan for `runtime_state.cj`, `cjpm.toml`, native bridge header and implementation produced no changed paths.

## GitNexus / CodeLattice

Repository rule used: `cangjie-live-codelattice`.

Pre-edit:

- GitNexus MCP context for `CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness` returned target not found.
- Tool CLI `impact CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness --repo cangjie-live-codelattice` returned not found / UNKNOWN / impacted count 0.
- Tool CLI `context init --repo cangjie-live-codelattice` hit an `init` ambiguity in the current CLI, so source reading and probe/build evidence were used instead of treating that command as coverage.
- CodeLattice context/impact for stage522 were static-only and did not provide runtime proof.

Post-edit:

- GitNexus MCP context for `CjguiInternalRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeReadiness` returned target not found.
- Tool CLI `impact CjguiInternalRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeReadiness --repo cangjie-live-codelattice` returned not found / UNKNOWN.
- GitNexus MCP and Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all` only covered tracked doc changes, not the untracked new owner/script files; reported affected processes remained 0 / low risk.
- CodeLattice post-edit review was static-only; it did not execute focused probes or build.

Graph coverage did not cover the new stage523-525 symbols, so the blast radius is not proven by GitNexus. Known source-level impact is limited to new internal-only owner files and focused scripts plus latest-entry docs; no direct callers were changed, no public API was added, and no protected runtime/native bridge path changed.

## Endpoint And Next Route

Current canonical endpoint:

- `CjguiInternalRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeReadiness`
- `cjguiInternalExecuteDefaultRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeDraft()`

Current next route:

- `stage526_demo_surface_refresh_focus_input_action_adapter_after_stage525`

This naturally continues from checkable runtime probe inputs into a focus/input action adapter that can consume the new runtime probe contract, still without dispatching real input or committing state.

## Runtime / Native Probe

Bounded runtime native probe was not executed. This package stayed in internal owner/probe and `cjpm build --skip-script` scope; it did not modify native bridge, renderer runtime state, public C ABI, or live Metal/AppKit call sites. No new CJGUI harness gap or host limitation was found. The only environment issue was sandboxed `ps` during envsetup, resolved with a local shim for formatting and build.

## Remaining Distance

First-frame chain remains prior evidence only; this run did not add a new live first-frame observation.

Renderer-state write remains blocked: no renderer_state write, no renderer submission, and no visibility publication was admitted.

`runtime_state` write remains blocked: no `runtime_state.cj` edit and no global state commit.

Minimal UI framework is closer because refreshed RenderCommand probe inputs now reach checkable layout/style/text/focus preview, layout execution receipt and runtime probe inputs for three demo surfaces. It still lacks real input event ingestion, real action dispatch, committed state update, layout engine execution, style resolution, text shaping, focus manager, backend submission and public component API.

## Stop State

No stage, commit, or push was performed.

Stopping reason: the requested three-slice macro package is complete, focused probes and build passed, latest-entry docs were synced, and the next route is explicit.
