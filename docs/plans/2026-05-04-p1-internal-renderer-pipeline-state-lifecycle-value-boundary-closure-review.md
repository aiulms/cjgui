# P1 internal Renderer pipeline state lifecycle value boundary closure review

日期：2026-05-04

状态：closure review

## Scope

本轮实现 `P1 internal Renderer pipeline state lifecycle value boundary bundle implementation`。

允许的 runtime write set 只有：

- [runtime_renderer_pipeline_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state.cj)

同步更新的文档：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)

本轮未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。

## Read Inputs

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime_renderer_draw_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call.cj)
- Adjacent renderer lifecycle owners for naming / fail-closed shape.

## GitNexus Impact

Impact was requested before editing the new downstream owner:

- `CjguiInternalRendererNoDrawCallReadiness`: `UNKNOWN / not found`, affected count `0`。
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft`: `UNKNOWN / not found`, affected count `0`。

Interpretation：these are recent renderer owner symbols that are present in source but not indexed yet. No HIGH / CRITICAL risk was returned, so implementation proceeded with source existence plus build fallback.

## Implemented Owner

Owner file：

- `runtime/cjgui/src/runtime_renderer_pipeline_state.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoPipelineStateReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`

## New Internal Symbols

- `CjguiInternalRendererPipelineStateLifecycleIntent`
- `CjguiInternalRendererShaderFunctionPolicy`
- `CjguiInternalRendererPipelineDescriptorPolicy`
- `CjguiInternalRendererPipelineCompatibilityGuard`
- `CjguiInternalRendererNoPipelineStateReadiness`
- `cjguiInternalBuildRendererPipelineStateLifecycleIntent`
- `cjguiInternalBuildRendererShaderFunctionPolicy`
- `cjguiInternalBuildRendererPipelineDescriptorPolicy`
- `cjguiInternalBuildRendererPipelineCompatibilityGuard`
- `cjguiInternalBuildRendererNoPipelineStateReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft`

No `public` symbols, `var`, C ABI, native resource owner, pointer-like resource owner, import, backend hook, platform hook or mutable module-level state were added.

## Boundary Conclusion

The new owner opens only a no-pipeline-state internal value boundary.

Open path：

1. Consume `CjguiInternalRendererNoDrawCallReadiness` from the draw call lifecycle default draft.
2. Form pipeline state lifecycle intent facts.
3. Form shader function policy facts.
4. Form pipeline descriptor policy facts.
5. Form pipeline compatibility guard facts.
6. Seal no-pipeline-state readiness facts.

Defer-only path：

- If upstream no-draw-call readiness is deferred, the new owner preserves defer and does not forge pipeline readiness.

Blocked / inconsistent path：

- If upstream is blocked, contradictory or half-open, the new owner fail-closes blocked.

The endpoint is explicitly not pipeline state permission, shader asset permission, descriptor permission, encoder binding permission, resource binding permission, backend readiness, render execution permission or renderer state write.

## Stop-line

Current stop-line remains closed for:

- real pipeline state creation.
- shader library / function loading or resolution.
- pipeline descriptor creation.
- pipeline compile / cache mutation.
- encoder call.
- buffer / texture binding.
- GPU submission.
- draw call execution.
- backend / Metal / AppKit implementation.
- command buffer / render pass / drawable creation.
- native resource token / pointer-like resource ownership.
- render execution.
- renderer state write.
- public surface expansion.

Any future platform object names remain only prohibited / future vocabulary in comments or value facts, not imported types, fields, function calls or resource holders.

## Same-shape Boundary Brake

Same-shape Boundary Brake was applied.

This is not a `CjguiInternalRendererNoDrawCallReadiness` receipt / record / publication because it adds owner truth that the draw-call endpoint does not own:

- shader role placeholder.
- future shader selection policy.
- vertex layout placeholder.
- color attachment format relation.
- blend / depth-stencil placeholders.
- material key compatibility relation.
- render pass compatibility relation.
- encoder / draw call compatibility relation.
- failure / no-pipeline fallback.
- no-pipeline-state readiness.

The owner deliberately does not introduce:

- pipeline-state receipt / record / publication.
- render execution readiness wrapper.
- backend-readiness wrapper.
- shader library lifecycle implementation.
- real pipeline compilation / cache.

## Next Opening

唯一 next opening：

`P1 internal Renderer pipeline state lifecycle closure / next pipeline state decision`

下一轮必须 docs-only，评估 `CjguiInternalRendererNoPipelineStateReadiness` 是否足够作为当前 no-pipeline-state lifecycle endpoint，并决定是否先做 manifest stabilization。不得直接实现 shader library lifecycle、pipeline state implementation、backend-readiness wrapper、render execution 或 renderer state write。

## Downstream Next-Boundary Decision

Renderer pipeline state lifecycle next-boundary decision 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererNoPipelineStateReadiness` 已足够作为当前 no-pipeline-state lifecycle endpoint。下一步选择 docs-only `P1 internal Renderer pipeline state lifecycle manifest stabilization bundle implementation`，先固定 owner / truth / canonical endpoint / stop-line；不批准 pipeline-state receipt / record / publication、backend-readiness wrapper、render-execution readiness wrapper、shader library lifecycle implementation、pipeline state implementation、render execution 或 renderer state write。

## Validation

Validation results:

- `cjpm build --target-dir /tmp/cjgui-renderer-pipeline-state-lifecycle-value-boundary-target --skip-script`: passed when run with local SDK paths in `PATH` (`/Users/jiangxuanyang/cangjie-toolchains/cangjie/bin` and `/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin`). The plain shell initially did not have `cjpm` / `cjc` discoverable. Build completed with existing unused-symbol warnings and no errors.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed; auto-close log assertions passed and remained non-user-visible-window verification.
- `git diff --check`: passed.
- Markdown absolute link missing target check: passed.
- Closure reachability check: passed; `README.md`, `GUI_TASK_TRACKER.md` and `docs/plans/README.md` can find this closure and the next opening.
- Forbidden touch check: passed; this round did not touch `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke tracked source, harness, native bridge, entry, `AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`.
- Public declaration scan: passed; the only public declaration remains `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- Stop-line source scan: passed; the new owner has no `public`, no `var`, no import, no C ABI hook, no backend / platform call and no platform object type usage. Platform terms only appear in prohibitive comments.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`, affected processes `[]`.
