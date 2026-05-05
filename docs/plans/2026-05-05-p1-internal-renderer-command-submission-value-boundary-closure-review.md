# P1 internal Renderer command submission value boundary closure review

日期：2026-05-05

状态：implementation closure review

## Scope

本轮执行 `P1 internal Renderer command buffer commit / GPU submission value boundary bundle implementation`。

允许新增一个 internal-only runtime owner：

- [runtime_renderer_command_submission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_submission.cj)

本轮没有修改 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有触碰 smoke tracked source、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮没有创建 command buffer、render pass、encoder、pipeline state、drawable、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、backend object、platform object、native handle 或 raw pointer；没有调用 `commit`、`present`、`nextDrawable`、Metal、AppKit、Objective-C 或 FFI API；没有提交 GPU work，没有执行 render，没有写 renderer state，没有扩 public API / C ABI，没有新增 module-level `var`。

## GitNexus Impact

实施前对入口 symbols 执行 GitNexus impact：

- `CjguiInternalRendererNoRealDrawableReadiness`：`UNKNOWN / not found`，impacted count `0`，未返回 HIGH / CRITICAL。
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft`：`UNKNOWN / not found`，impacted count `0`，未返回 HIGH / CRITICAL。

结论：这些 renderer owner 属于近期新增链路，当前 GitNexus 索引尚未覆盖；按要求记录为 not indexed，并使用源码存在性、`cjpm build`、stop-line scans、public declaration scan 和 GitNexus `detect_changes` 兜底。

## Landed Owner

Owner file：

- [runtime_renderer_command_submission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_submission.cj)

Runtime input：

- `CjguiInternalRendererNoRealDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoGpuSubmissionReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`

## New Internal Symbols

- `CjguiInternalRendererCommandSubmissionIntent`
- `CjguiInternalRendererCommandBufferCommitPolicy`
- `CjguiInternalRendererDrawablePresentationGate`
- `CjguiInternalRendererGpuSubmissionFailurePolicy`
- `CjguiInternalRendererNoGpuSubmissionReadiness`
- `cjguiInternalBuildRendererCommandSubmissionIntent`
- `cjguiInternalBuildRendererCommandBufferCommitPolicy`
- `cjguiInternalBuildRendererDrawablePresentationGate`
- `cjguiInternalBuildRendererGpuSubmissionFailurePolicy`
- `cjguiInternalBuildRendererNoGpuSubmissionReadiness`
- `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`

## Boundary Conclusion

The new owner only records:

- command submission intent value facts.
- command buffer commit policy value facts.
- drawable presentation gate value facts.
- GPU submission failure policy value facts.
- no-gpu-submission readiness value facts.

`CjguiInternalRendererCommandSubmissionIntent` preserves the upstream no-real-drawable endpoint and opens only a future command submission intent runway.

`CjguiInternalRendererCommandBufferCommitPolicy` describes future commit timing, single-use and no-commit facts. It does not create or commit command buffer work.

`CjguiInternalRendererDrawablePresentationGate` describes future drawable presentation ordering facts. It does not acquire drawable and does not present drawable.

`CjguiInternalRendererGpuSubmissionFailurePolicy` describes future completion / failure / rollback / no-draw relation facts. It does not observe real GPU completion, register callbacks, emit telemetry or publish diagnostics.

`CjguiInternalRendererNoGpuSubmissionReadiness` seals the current no-gpu-submission endpoint. It is not command buffer permission, drawable present permission, GPU submission permission, render execution permission, backend implementation permission, renderer state write permission, public API permission or C ABI permission.

## Fail-closed Behavior

Open path:

- upstream `CjguiInternalRendererNoRealDrawableReadiness` must be ready, evaluable, sealed, value-only and free of drawable acquisition / submission / render / state mutation permission.
- the owner builds all five value-fact stages and seals `CjguiInternalRendererNoGpuSubmissionReadiness`.

Deferred path:

- upstream defer stays defer.
- the owner does not fabricate no-gpu-submission readiness.

Blocked / inconsistent path:

- upstream blocked or contradictory readiness facts fail closed.
- downstream stages preserve blocked status and keep denial facts value-only.

## Same-shape Boundary Brake

This round intentionally adds commit policy / presentation gate / GPU submission failure / no-gpu-submission readiness semantics.

It is not a thin wrapper over `CjguiInternalRendererNoRealDrawableReadiness` because it adds separate facts for:

- future command submission intent.
- future command buffer commit policy.
- future drawable presentation gate.
- future GPU submission failure / rollback / no-draw relation.
- current no-gpu-submission endpoint.

Explicitly rejected:

- command submission receipt / record / publication.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- drawable-present-ready wrapper.
- backend implementation wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

Future work near real commit, real present, GPU submission, render execution or renderer state write must first pass a separate docs-only preflight.

## Validation

Completed:

- GitNexus impact was executed before implementation and returned `UNKNOWN / not found` for both requested symbols, with no HIGH / CRITICAL risk.
- Bare `cjpm` was not available in `PATH`; reran through `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`.
- `cjpm build --target-dir /tmp/cjgui-renderer-command-submission-value-boundary-target --skip-script` passed from `runtime/cjgui`; current package still emits unused-symbol warnings.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed and reported auto-close log assertions passed.
- `git diff --check` passed.
- No-index whitespace check for the new owner and this closure passed.
- Markdown absolute link missing target check passed for project docs scope, excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability found this closure, `CjguiInternalRendererNoGpuSubmissionReadiness` and the unique next opening.
- Forbidden path check found no protected path status / diff for `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER.
- `runtime_state.cj` line count remains `10065`.
- Public declaration scan still finds only `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`.
- New owner stop-line scan found no actual `commit(...)`, `present(...)`, `nextDrawable(...)`, platform API token, native handle / raw pointer token, public declaration or module-level `var`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` reported risk `low`, `changed_count=13`, `changed_files=7`, `affected_count=0` and no affected processes.

## Unique Next Opening

`P1 internal Renderer command buffer commit / GPU submission closure / next command submission decision`
