# P1 internal Renderer frame pacing owner value boundary closure review

日期：2026-05-04

状态：value boundary closure

## Scope

本轮新增 internal-only renderer frame pacing owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_frame_pacing.cj`

本 closure 记录 frame pacing owner value boundary 已落地，并确认它仍是 no-frame-scheduler / no-display-link / no-render-loop / no-render side-effect 边界。

## GitNexus Impact

执行前对入口 symbols 运行 GitNexus impact：

- `CjguiInternalRendererNoBackendObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft`

结果均为 `UNKNOWN` / not found。按近期新增 renderer owner 尚未进入 GitNexus index 记录；未出现 HIGH / CRITICAL impact，因此继续以源码存在、`cjpm build`、public declaration scan、stop-line scan 与 GitNexus detect_changes 兜底。

## Owner / Truth

Canonical upstream endpoint：

- `CjguiInternalRendererNoBackendObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_frame_pacing.cj`

Canonical endpoint：

- `CjguiInternalRendererNoFrameSchedulerReadiness`
- `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`

Current truth：

- frame pacing owner intent value facts。
- display timing policy value facts。
- frame request gate value facts。
- pacing failure policy value facts。
- no-frame-scheduler readiness value facts。

## Added Internal Symbols

- `CjguiInternalRendererFramePacingOwnerIntent`
- `CjguiInternalRendererDisplayTimingPolicy`
- `CjguiInternalRendererFrameRequestGate`
- `CjguiInternalRendererPacingFailurePolicy`
- `CjguiInternalRendererNoFrameSchedulerReadiness`
- `cjguiInternalBuildRendererFramePacingOwnerIntent`
- `cjguiInternalBuildRendererDisplayTimingPolicy`
- `cjguiInternalBuildRendererFrameRequestGate`
- `cjguiInternalBuildRendererPacingFailurePolicy`
- `cjguiInternalBuildRendererNoFrameSchedulerReadiness`
- `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`

## Value Pipeline

Default draft pipeline：

1. `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`
2. `CjguiInternalRendererFramePacingOwnerIntent`
3. `CjguiInternalRendererDisplayTimingPolicy`
4. `CjguiInternalRendererFrameRequestGate`
5. `CjguiInternalRendererPacingFailurePolicy`
6. `CjguiInternalRendererNoFrameSchedulerReadiness`

The runtime input remains unique:

- `CjguiInternalRendererNoBackendObjectReadiness`

No Queue / Action / Runtime lower-level mutable facts are read.

## Boundary Conclusion

`CjguiInternalRendererFramePacingOwnerIntent` only expresses future frame pacing owner intent. It is not a frame scheduler, backend-readiness wrapper, renderer-state-write wrapper, receipt, record or publication.

`CjguiInternalRendererDisplayTimingPolicy` only expresses display refresh / drawable timing / resize-scale-color relation facts. It does not create a frame clock, bind a frame callback, register a timer or attach a display link.

`CjguiInternalRendererFrameRequestGate` only expresses request admission, defer and no-draw fallback facts. It does not start a continuous frame driver, acquire a drawable, commit a command buffer, submit GPU work or render.

`CjguiInternalRendererPacingFailurePolicy` only expresses frame drop / defer / no-draw / rollback facts. It does not register callbacks, publish diagnostics, emit telemetry or write renderer state.

`CjguiInternalRendererNoFrameSchedulerReadiness` is the new no-frame-scheduler endpoint. It only says the future frame pacing boundary can continue to be evaluated; it is not scheduler permission, timer permission, display-link permission, render-loop permission, backend permission, command-buffer-commit permission, GPU-submission permission, render permission or renderer state write permission.

Current implementation has no frame scheduler, no frame clock, no frame callback binding, no continuous frame driver, no backend object creation, no platform object creation, no command buffer commit, no GPU submission, no render execution and no renderer state write.

## Same-shape Boundary Brake

Same-shape Boundary Brake 生效点：

- The new owner adds display timing / frame request gate / pacing failure / no-frame-scheduler semantics.
- It does not wrap `CjguiInternalRendererNoBackendObjectReadiness` as frame pacing receipt / record / publication.
- It does not create backend-readiness wrapper, renderer-state-write wrapper, scheduler-readiness wrapper, command-buffer-commit wrapper or GPU-submission wrapper.
- It does not reuse any backend object receipt semantics and does not mix renderer state write or backend-readiness final gate into this owner.

Future frame pacing decisions must keep this brake: if the next step approaches scheduler / timer / display link / render loop, renderer state write or backend readiness, it must first be docs-only preflight.

## Validation

- `cjpm build --target-dir /tmp/cjgui-renderer-frame-pacing-owner-value-boundary-target --skip-script`
  - Bare `cjpm` was not on `PATH`; reran with `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`.
  - Result: passed with existing unused warnings.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - Result: passed; auto-close log assertions passed.
- `git diff --check`
  - Result: passed.
- Markdown absolute link missing target check, project docs scope only.
  - Result: passed.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README closure reachability.
  - Result: passed.
- Forbidden path check for `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke tracked source, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER.
  - Result: passed.
- Public declaration scan remains limited to `cjguiExperimentalQueueSubmitShellReady(): Bool`.
  - Result: passed.
- New owner stop-line scan confirms no real scheduler / timer / display link / backend implementation / command buffer commit / GPU submission / renderer state write / public / native handle / raw pointer / module-level `var`.
  - Result: passed.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.
  - Result: low risk, affected processes empty.

## Next Opening

唯一 next opening：

`P1 internal Renderer frame pacing owner closure / next frame pacing decision`

下一轮必须 docs-only；先评估 `CjguiInternalRendererNoFrameSchedulerReadiness` 是否足够作为当前 no-frame-scheduler endpoint，再决定是否进入 manifest stabilization、renderer state write preflight 或 backend-readiness revisit。不得直接实现 frame scheduler / timer / display link / render loop、backend / Metal / AppKit、command buffer commit、GPU submission、render execution 或 renderer state write。
