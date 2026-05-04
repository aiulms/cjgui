# P1 internal Renderer encoder lifecycle value boundary closure review

日期：2026-05-03

本轮执行 `P1 internal Renderer encoder lifecycle value boundary bundle implementation`。它是 internal-only runtime owner slice，不是 encoder implementation、backend implementation、Metal / AppKit implementation、render execution、renderer state write 或 draw call runway。

## Scope

实际新增 owner file：

- `runtime/cjgui/src/runtime_renderer_encoder.cj`

实际同步文档：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md`
- `docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md`
- `docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md`

未触碰：

- `runtime_state.cj`
- `runtime/cjgui/cjpm.toml`
- smoke tracked source / harness / native bridge / entry
- `AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`

## Added Internal Symbols

- `CjguiInternalRendererEncoderLifecycleIntent`
- `CjguiInternalRendererEncodingScopePolicy`
- `CjguiInternalRendererPipelineBindingGuard`
- `CjguiInternalRendererEndEncodingPolicy`
- `CjguiInternalRendererNoEncoderReadiness`
- `cjguiInternalBuildRendererEncoderLifecycleIntent`
- `cjguiInternalBuildRendererEncodingScopePolicy`
- `cjguiInternalBuildRendererPipelineBindingGuard`
- `cjguiInternalBuildRendererEndEncodingPolicy`
- `cjguiInternalBuildRendererNoEncoderReadiness`
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft`

No `public` symbol was added.

## Boundary Conclusion

The value boundary opens only the encoder lifecycle vocabulary runway:

1. `CjguiInternalRendererEncoderLifecycleIntent` consumes `CjguiInternalRendererNoRenderPassReadiness` and records future encoder lifecycle intent facts.
2. `CjguiInternalRendererEncodingScopePolicy` records future encoding scope, command sequencing, viewport/scissor placeholder, and failure/no-draw fallback facts.
3. `CjguiInternalRendererPipelineBindingGuard` records future pipeline/resource binding preconditions without binding pipeline state or emitting draw commands.
4. `CjguiInternalRendererEndEncodingPolicy` records future end-encoding boundary, post-encoding invalidation, and failure rollback facts without ending an encoder.
5. `CjguiInternalRendererNoEncoderReadiness` seals the no-encoder endpoint.

The open path forms encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness facts. The defer-only path remains deferred and does not forge encoder readiness. Blocked or inconsistent upstream facts fail closed as blocked.

`CjguiInternalRendererNoEncoderReadiness` explicitly means:

- no `MTLRenderCommandEncoder`
- no pipeline state object
- no draw command
- no render pass descriptor object
- no command buffer object
- no native resource token or pointer-like resource
- no backend permission
- no render permission
- no renderer state mutation

It is not backend readiness, encoder permission, pipeline binding permission, draw permission, render permission, renderer state write, or platform object permission.

## Same-shape Boundary Brake

Same-shape Boundary Brake was active for this slice.

This owner is not a thin wrapper around `CjguiInternalRendererNoRenderPassReadiness` because it adds new, independently named value facts:

- encoding scope policy
- command sequencing boundary
- viewport/scissor placeholder facts
- pipeline binding guard
- resource binding placeholder facts
- end-encoding boundary
- post-encoding invalidation and failure rollback facts
- no-encoder readiness

The slice rejects:

- encoder receipt / record / publication
- render pass receipt / record / publication
- backend-readiness wrapper
- draw call readiness wrapper
- pipeline state lifecycle wrapper

Draw call lifecycle and pipeline state lifecycle remain out of scope and must not be mixed into this owner.

## GitNexus

Pre-edit impact:

- `CjguiInternalRendererNoRenderPassReadiness`: `UNKNOWN / not found`
- `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft`: `UNKNOWN / not found`

Both entry symbols are recent runtime owners not yet indexed by GitNexus. The fallback evidence is source presence in `runtime/cjgui/src/runtime_renderer_render_pass.cj` plus this round's build verification.

Final change detection is recorded in the validation section below.

## Validation

Validation results:

- `cjpm build --target-dir /tmp/cjgui-renderer-encoder-lifecycle-value-boundary-target --skip-script`: passed; existing unused warnings remain.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed.
- `git diff --check`: passed.
- Markdown absolute link missing target check: passed.
- Closure reachability from `README.md`, `GUI_TASK_TRACKER.md`, and `docs/plans/README.md`: passed.
- Forbidden path check: passed; no `runtime_state.cj`, `cjpm.toml`, smoke tracked source, harness, native bridge, entry, `AGENTS`, `CLAUDE`, or `CANGJIE_ISSUE_LEDGER` touch.
- Public declaration scan: passed; still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- Stop-line source scan for `runtime_renderer_encoder.cj`: passed.
- GitNexus `detect_changes(scope=unstaged)`: risk `low`, affected processes `0`. The returned indexed changed-file count was `7`; untracked recent owner files are not fully represented in that index result.

## Next Opening

唯一 next opening：

`P1 internal Renderer encoder lifecycle closure / next encoder decision`

下一轮必须 docs-only，评估 `CjguiInternalRendererNoEncoderReadiness` 是否已经足够作为当前 no-encoder lifecycle endpoint，并决定是否先做 manifest stabilization。不得直接创建 encoder，不得进入 draw call lifecycle implementation、pipeline state implementation、backend readiness wrapper、render execution 或 renderer state write。
