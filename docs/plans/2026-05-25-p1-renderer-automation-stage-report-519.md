# P1 Renderer Automation Stage Report 519

日期：2026-05-25

状态：completed / internal-only / no production truth

## 小设计

当前真实 tail 是 stage516 demo surface refresh interaction-cycle RenderCommand refresh。它已经把 refreshed owner-local state candidates 推到 shared interaction-cycle receipt、executor contract/helper 和 Todo / settings / AI-generated settings RenderCommand probe inputs，但还没有把这些输出重新落到 refreshed layout/style/text/focus preview。

本轮完成 three-slice macro package：stage517 消费 stage516 的 refreshed interaction-cycle receipt、executor contract/helper 和三个 RenderCommand probe inputs，生成 refreshed layout/style/text/focus preview；stage518 消费 stage517 preview，生成 refreshed layout execution receipts，并把 layout execution helper 提升为 v3；stage519 消费 stage518 receipts，生成 refreshed runtime preview/probe contract helper v3 与三个 demo runtime probe inputs。Slice 2 直接消费 Slice 1 的 shared preview 与三个 demo preview nodes；Slice 3 直接消费 Slice 2 的 shared receipt、三个 demo receipts 和 helper v3，把 dry-run 结果推进为可检查的 demo runtime probe input。关键 stop-line：不启用真实 layout/style/text/focus engine，不执行 input pipeline，不 dispatch action，不 commit state，不发布 visibility，不 renderer submission，不写 `renderer_state` / `runtime_state`，不扩 native bridge 或 public API。

## Three Slices

Slice 1: stage517 demo surface refresh layout/style preview

- 新增 `CjguiInternalRendererStage517DemoSurfaceRefreshLayoutStylePreviewReadiness` 和 default draft。
- 消费 `CjguiInternalRendererStage516DemoSurfaceRefreshInteractionCycleRenderRefreshReadiness`，确认 stage516 refreshed interaction-cycle receipt、executor contract/helper 和三个 RenderCommand probe inputs 已就绪。
- 产出 shared refreshed layout/style/text/focus preview 与 Todo/settings/AI-generated settings preview nodes。
- 新增 `demo_surface_refresh_refreshed_interaction_cycle_executor_helper_bound_to_layout_style_preview=true`，让 preview 明确消费 stage516 shared helper，而不是只复制 layout owner shell。

Slice 2: stage518 demo surface refresh layout execution receipt

- 新增 `CjguiInternalRendererStage518DemoSurfaceRefreshLayoutExecutionReceiptReadiness` 和 default draft。
- 直接消费 stage517 shared preview 与三个 demo preview nodes。
- 产出 shared refreshed layout execution receipt、Todo/settings/AI-generated settings execution receipts 和 text/focus affordance。
- 抽出 `demo_surface_refresh_layout_execution_helper_v3_materialized=true` / `demo_surface_refresh_layout_execution_helper_v3_bound_to_demo_surfaces=true`。

Slice 3: stage519 demo surface refresh runtime preview/probe

- 新增 `CjguiInternalRendererStage519DemoSurfaceRefreshRuntimePreviewProbeReadiness` 和 default draft。
- 直接消费 stage518 shared execution receipt、三个 demo receipts 与 layout execution helper v3。
- 产出 shared refreshed runtime preview/probe contract、runtime preview/probe contract helper v3、Todo/settings/AI-generated settings runtime probe inputs。
- 准备 `stage520_demo_surface_refresh_focus_input_action_adapter_after_stage519`，把 layout execution receipt 再次推回 focus/input/action adapter 链路。

## 真实能力增量

本轮把 stage516 RenderCommand refresh 输出重新落回 refreshed layout/style/text/focus preview，并继续推进到 layout execution receipt 与 runtime preview/probe input。三个 demo surface 都被接入：Todo、settings、AI-generated settings。真实增量不是 stage 号本身，而是 `stage516 executor helper -> stage517 preview -> stage518 layout execution helper v3 -> stage519 runtime preview/probe contract helper v3` 的可复用内部 framework contract。

辅助 envelope / readiness 仅用于证明消费关系与 stop-line：owner acceptance 仍 required/not granted；production/backend truth、layout/style/text/focus engine、真实 input pipeline、action dispatch、state commit、visibility publication、renderer submission、renderer_state/runtime_state write、native bridge expansion、public component API 均保持 false。

## 修改文件

- `runtime/cjgui/src/runtime_renderer_stage517_demo_surface_refresh_layout_style_preview.cj`
- `runtime/cjgui/src/runtime_renderer_stage518_demo_surface_refresh_layout_execution_receipt.cj`
- `runtime/cjgui/src/runtime_renderer_stage519_demo_surface_refresh_runtime_preview_probe.cj`
- `runtime/cjgui/native/scripts/verify_renderer_stage517_demo_surface_refresh_layout_style_preview_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage517_demo_surface_refresh_layout_style_preview_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage518_demo_surface_refresh_layout_execution_receipt_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage518_demo_surface_refresh_layout_execution_receipt_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage519_demo_surface_refresh_runtime_preview_probe_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage519_demo_surface_refresh_runtime_preview_probe_suite.sh`
- `docs/plans/2026-05-25-p1-renderer-automation-stage-report-519.md`
- latest-entry sync: `README.md`, `GUI_TASK_TRACKER.md`, `docs/plans/README.md`, `runtime/cjgui/README.md`, `docs/plans/DESIGN_INTENT_INDEX.md`

## 验证结果

RED checks:

- Before owner files existed, stage517/518/519 owner probes failed with missing source.
- Before owner files existed, stage517/518/519 suites failed through owner-probe failure.
- `zsh -n` passed for all six new scripts before implementation.

Focused and build checks:

- Stage517/518/519 owner probes passed and emitted expected true facts plus stop-line false facts.
- Pre-format suite chain passed from `/private/tmp/cjgui-stage514-stage516-postfmt/stage516/stage516-demo-surface-refresh-interaction-cycle-render-refresh-suite.packet` through:
  - `/private/tmp/cjgui-stage517-stage519-green/stage517/stage517-demo-surface-refresh-layout-style-preview-suite.packet`
  - `/private/tmp/cjgui-stage517-stage519-green/stage518/stage518-demo-surface-refresh-layout-execution-receipt-suite.packet`
  - `/private/tmp/cjgui-stage517-stage519-green/stage519/stage519-demo-surface-refresh-runtime-preview-probe-suite.packet`
- `cjfmt -f` completed for the three new `.cj` files after loading the toolchain with the local `ps` shim.
- Post-format suite chain passed through:
  - `/private/tmp/cjgui-stage517-stage519-postfmt/stage517/stage517-demo-surface-refresh-layout-style-preview-suite.packet`
  - `/private/tmp/cjgui-stage517-stage519-postfmt/stage518/stage518-demo-surface-refresh-layout-execution-receipt-suite.packet`
  - `/private/tmp/cjgui-stage517-stage519-postfmt/stage519/stage519-demo-surface-refresh-runtime-preview-probe-suite.packet`
- Final stage519 suite confirmed `renderer_submission=false`.
- `zsh -n` passed for all six new scripts.
- Public / foreign declaration scan passed for the three new owners.
- Comment-stripped forbidden native/render token scan passed for the three new owners.
- Protected path scan found no `runtime/cjgui/src/runtime_state.cj`, `runtime/cjgui/cjpm.toml`, or native bridge implementation changes.
- Trailing whitespace scan passed for the three new owners and six scripts.
- `git diff --check` passed before and after documentation sync.
- Independent final build `cjpm build --target-dir /private/tmp/cjgui-stage519-final-independent-build/target --skip-script` passed after loading the toolchain with the local `ps` shim. The compiler still prints the existing unused-symbol warning baseline.

Bounded runtime native probe: not executed. This package is internal owner/probe contract work and does not require live Metal/AppKit. No new CJGUI harness gap or host limitation was encountered. A direct toolchain load without the `ps` shim hit the existing sandbox `ps` limitation, then formatting/build proceeded with the same shim pattern used by focused suites.

## GitNexus / CodeLattice

GitNexus / `cangjie-live-codelattice`:

- Pre-edit impact for planned stage517/518/519 readiness symbols returned `UNKNOWN` / target not found. This was not treated as safe.
- Post-edit context for `CjguiInternalRendererStage519DemoSurfaceRefreshRuntimePreviewProbeReadiness` returned not found.
- Post-edit impact for `CjguiInternalRendererStage519DemoSurfaceRefreshRuntimePreviewProbeReadiness` returned `UNKNOWN` / target not found.
- `detect_changes --repo cangjie-live-codelattice --scope all` reported 5 changed tracked files, 2 README section symbols, 0 affected processes, low risk. Because the new owner files are untracked, this graph result does not cover the new internal stage symbols.
- `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status` confirmed `cangjie-live-codelattice` points at `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`; stable window is RED because the workspace is broadly dirty with 333 total dirty entries. Status only, no smoke tests run.

CodeLattice:

- `codelattice_symbol` context for `CjguiInternalRendererStage519DemoSurfaceRefreshRuntimePreviewProbeReadiness` completed static analysis with low risk and no runtime/coverage proof.
- `codelattice_change_review` impact for stage519 reported medium risk, static-only.
- `codelattice_change_review` production_assist for stage517/518/519 reported medium risk, static-only.

Graph coverage did not cover fresh untracked owner files, so safety rests on source reading, RED/GREEN probes, suite chaining, scans, and builds.

## Current Endpoint

Canonical endpoint:

- `CjguiInternalRendererStage519DemoSurfaceRefreshRuntimePreviewProbeReadiness`
- `cjguiInternalExecuteDefaultRendererStage519DemoSurfaceRefreshRuntimePreviewProbeDraft()`

Current next route:

- `stage520_demo_surface_refresh_focus_input_action_adapter_after_stage519`

The next most valuable engineering target is to consume stage519 runtime preview/probe contract helper v3 into a focus/input action adapter that keeps the path owner-local/non-dispatching while reusing the stage517-519 preview/execution/probe helper contracts.

## Remaining Distance

First-frame and renderer-state write paths are unchanged. This run does not move runtime_state write, renderer_state write, Metal/AppKit submission, platform command buffers, backend-ready truth, production render truth, layout engine truth, style resolver truth, text shaping truth, focus manager truth, or public component API.

Minimal UI framework is closer because Todo/settings/AI-generated settings now share a refreshed RenderCommand -> layout/style/text/focus preview -> layout execution receipt -> runtime preview/probe path, but a real demo still needs a real input event pipeline, focus manager, state commit protocol, layout/style/text engine, demo host integration, backend adapter execution, and a stable public component API decision.

No files were staged, committed, or pushed.
