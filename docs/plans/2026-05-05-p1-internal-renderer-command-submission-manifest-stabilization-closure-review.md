# P1 internal Renderer command submission manifest stabilization closure review

日期：2026-05-05

状态：docs-only closure review

## Scope

本轮执行 `P1 internal Renderer command submission manifest stabilization bundle implementation`。

本轮必须 docs-only：没有修改 `.cj`，没有运行 `cjpm build` / smoke，没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮没有调用 `commit`、`present` 或 `nextDrawable`，没有创建 command buffer、drawable、render pass、encoder 或 pipeline state，没有调用 Metal / AppKit / Objective-C / FFI，没有提交 GPU work，没有执行 render，没有写 renderer state，没有扩 public API / C ABI。

## Files Updated

New docs:

- [2026-05-05-p1-renderer-command-submission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md)

Synchronized docs:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md)
- [2026-05-05-p1-renderer-command-submission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-next-boundary-decision.md)
- [2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)

## Manifest Conclusion

The command submission owner is fixed:

- Owner file: [runtime_renderer_command_submission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_submission.cj)
- Runtime input: `CjguiInternalRendererNoRealDrawableReadiness`
- Canonical endpoint: `CjguiInternalRendererNoGpuSubmissionReadiness`
- Default draft: `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`

Current truth is exactly:

- command submission intent value facts.
- command buffer commit policy value facts.
- drawable presentation gate value facts.
- GPU submission failure policy value facts.
- no-gpu-submission readiness value facts.

`CommandBufferCommitPolicy` does not create or commit command buffer.

`DrawablePresentationGate` does not present drawable.

`GpuSubmissionFailurePolicy` does not observe real GPU completion and does not register callback.

`NoGpuSubmissionReadiness` is not command buffer permission, drawable present permission, GPU submission permission, render permission, backend implementation permission, renderer state write permission, public API permission or C ABI permission.

## Boundary Conclusion

The current endpoint has no command buffer object, no drawable object, no render pass, no encoder, no pipeline state, no foreign API call, no resource token, no native handle, no raw pointer, no GPU work, no render execution, no renderer state mutation and no bridge / smoke / harness / native entry change.

The manifest keeps `CjguiInternalRendererNoRealDrawableReadiness` as the only runtime input. Real command queue lifecycle, no-draw backend shell, command buffer lifecycle, render execution no-op, state write no-write and backend / Metal reference evidence remain docs evidence only.

## Same-shape Boundary Brake

This round is a manifest closure, not another wrapper.

It explicitly rejects:

- command submission receipt / record / publication.
- GPU-submission permission wrapper.
- command-buffer-ready wrapper.
- drawable-present-ready wrapper.
- render-permission wrapper.
- backend implementation wrapper.
- renderer-state-write wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoGpuSubmissionReadiness` is not to be wrapped into a new tail endpoint. It only represents command submission intent / command buffer commit policy / drawable presentation gate / GPU submission failure policy / no-gpu-submission readiness value facts.

Future work approaching real backend shell implementation, render completion / frame completion tracking, real command buffer commit, real drawable present or real GPU submission must first pass docs-only preflight.

## Next Stage Candidate Comparison

### A. P1 internal Renderer real backend shell implementation preflight decision

推荐。

Command submission is now closed as value-only no-gpu-submission truth. The next safe question is docs-only: whether a real backend shell implementation preflight has enough owner / teardown / failure / no-draw / smoke strategy evidence.

### B. Render completion / frame completion tracking preflight

暂缓。

Completion tracking remains too close to callback, telemetry, observer and renderer state visibility.

### C. Command submission hardening

暂缓，仅在 commit policy / presentation gate / failure policy expression proves insufficient.

### D. Direct command buffer commit implementation

拒绝。

### E. Direct drawable present implementation

拒绝。

### F. GPU submission / render execution implementation

拒绝。

### G. Renderer state write

拒绝。

### H. Public API / C ABI expansion

拒绝。

### I. Receipt / record / publication

拒绝。

### J. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

## Validation

Completed:

- `git diff --check` passed.
- New manifest / closure no-index whitespace check passed.
- Markdown absolute link missing target check passed for project docs scope, excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability found the manifest, closure, `CjguiInternalRendererNoGpuSubmissionReadiness`, `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` and the unique next opening.
- Forbidden check found no tracked `.cj` diff and no protected path status for `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER.
- `runtime_state.cj` line count remains `10065`.
- Public declaration scan still finds only `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` reported risk `low`, `changed_count=13`, `changed_files=7`, `affected_count=0` and no affected processes.

Build and smoke were intentionally not run in this docs-only round.

## Unique Next Opening

`P1 internal Renderer real backend shell implementation preflight decision`
