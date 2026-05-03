# P1 Renderer diagnostics stop-line hardening

日期：2026-05-03

状态：docs-only stop-line hardening

## Purpose

本 hardening 文档补强 Renderer diagnostics pipeline 的命名 stop-line，防止后续执行 AI 把 `Readiness` / `NoOutput` / `NoWrite` / `NoSideEffect` / `NoOp` 误读成真实 output permission、logging permission 或 sink implementation。

本轮不修改 `.cj`，不删除、合并或重命名 runtime owner，不运行 build / smoke。它不是新的 runtime boundary，不是 diagnostics implementation，不批准真实 output，不批准 targeted consolidation。

## Inputs

- [2026-05-03-p1-renderer-diagnostics-consolidation-audit-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-consolidation-audit-manifest.md)
- [2026-05-03-p1-internal-renderer-diagnostics-consolidation-audit-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-diagnostics-consolidation-audit-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- The 9 diagnostics manifests for packet diagnostics, diagnostics policy, sink policy, output admission, write admission, real write no-op, local debug sink policy, local output admission, and real local no-op.

## Canonical Tail

Current canonical tail remains:

- `CjguiInternalRendererNoOpLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

This endpoint is an internal value fact endpoint only. It does not grant output permission, write permission, logging permission, debug output permission, backend readiness, command buffer readiness, renderer state write permission, render failure callback readiness, or render permission.

## Vocabulary Hardening

`Readiness` means the current internal value pipeline can be evaluated by a future docs-only decision or preflight. It does not mean side-effect permission, output permission, write permission, backend permission, render permission, public API permission, logging readiness, telemetry readiness, observer readiness, event bus readiness, file sink readiness, or public diagnostics readiness.

`NoOutput` means the current value explicitly records that there is no real output. It also means no logging, no debug output, no file sink, no stdout / stderr sink, no telemetry, no observer callback, no event bus, no public diagnostics, no external artifact retention, and no serialized payload output.

`NoWrite` means the current value explicitly records that there is no write. It also means no file write, no stdout write, no stderr write, no artifact write, no telemetry emission, no observer callback, no event bus publication, no public diagnostics publication, no renderer state write, and no backend write.

`NoSideEffect` means the current value explicitly records that the pipeline performs no side effect. It is not a side-effect policy implementation, not a runtime guard implementation, not a logging guard, and not a write safety runtime gate.

`NoOp` means the current endpoint remains a no-op value endpoint even if its name is near write / output vocabulary. It does not execute logging, does not serialize payload, does not write files, does not write stdout / stderr, does not emit telemetry, does not call observers, does not publish events, does not create public diagnostics, and does not retain artifacts.

`Sink`, `Output`, `Write`, `Real`, and `LocalDebug` are runway vocabulary in the current diagnostics docs. They name future evaluation lanes and internal value facts only. They are not implementation permission, not runtime flags, not global switches, not logging sinks, not file sinks, not console sinks, not telemetry channels, not observer callbacks, not event bus integrations, and not public diagnostics APIs.

## Current Stop-line

The diagnostics pipeline still is not:

- logging subsystem.
- telemetry.
- observer callback.
- event bus.
- public diagnostics.
- file sink.
- stdout sink.
- stderr sink.
- artifact retention.
- external diagnostics export.
- serialized payload output.
- exception system / public error API.
- backend handler.
- backend packet.
- backend submission.
- command buffer.
- renderer state write.
- render failure callback.
- render permission.
- public API / public C ABI expansion.

The public allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

No diagnostics endpoint expands the public surface, changes that Bool-only signature, or creates a public diagnostics symbol.

## Future Reopening Rules

Any future real output / logging / file sink / telemetry / observer / event bus / public diagnostics path must first pass docs-only preflight.

That preflight must provide concrete evidence for:

- privacy: raw payload policy, dehydrated fact boundary, and data minimization.
- opt-in: debug-only / local-only opt-in rule and default-off behavior.
- redaction: redaction policy, enforcement point, and serialization boundary.
- lifecycle: owner, creation, cleanup, shutdown, and failure rollback.
- thread-safety: main-thread / worker-thread boundary, concurrency policy, and backpressure.
- artifact: whether any file / stdout / stderr / external artifact is allowed and how it is retained or cleaned.
- retention: retention duration, retention hint mapping, and deletion policy.
- failure rollback: partial write, duplicate write, failed write, and no-op fallback behavior.

Without that evidence, future work must not implement logging, telemetry, observer callback, event bus, public diagnostics, file sink, stdout / stderr sink, artifact retention, backend handler, command buffer, renderer state write, render failure callback, or render permission.

## Same-shape Boundary Brake

This round is docs stop-line hardening, not a runtime boundary.

It does not approve targeted consolidation, receipt / record / publication, real output preflight, real output implementation, logging implementation, or file sink implementation.

If future work claims targeted consolidation is needed, it must first show duplicate fields, duplicate builders, low-value owner, self-wrapping owner, manifest drift, or build-level dead code evidence. Without that evidence, the safer path is to keep the 9 semantic owner endpoints and avoid code churn.

## Candidate Comparison

### A. P1 internal Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision

选择为下一阶段 opening。

理由：

- Diagnostics branch 已完成 pipeline milestone、consolidation audit、audit manifest 与 stop-line hardening。
- 下一步应 docs-only 判断是否封账 diagnostics branch 并回到 renderer command / backend 非 diagnostics 方向。
- 该候选不会实现真实 output，也不会修改 runtime code。

### B. Real local diagnostics output preflight

暂缓。

Hardening 没有发现真实 output ready evidence。若未来选择该方向，仍必须先 docs-only preflight，并提供 privacy / opt-in / redaction / lifecycle / thread-safety / artifact / retention / failure rollback evidence。

### C. Targeted consolidation preflight

暂缓。

Hardening 没有发现 duplicate / low-value / self-wrapping evidence，不满足 targeted consolidation preflight 条件。

### D. Diagnostics hardening follow-up

仅在发现 hardening 缺口时选择。

当前本轮已经固定 vocabulary stop-line；若后续某个 manifest 出现 drift，再做 docs-only follow-up。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### I. Public surface expansion

拒绝。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision`

下一轮必须 docs-only。它应评估 diagnostics branch 是否可以整体封账，并决定下一步是否回到 renderer command / backend 非 diagnostics track；不得直接进入 real local diagnostics output、targeted consolidation、receipt / record / publication、logging、file sink、telemetry、observer callback、event bus、public diagnostics、backend、command buffer、renderer state write 或 render permission。

## Downstream Branch Closure

`P1 internal Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision` 已由 [2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md) 完成。

Branch closure 正式关闭 diagnostics no-output / no-op 支线；current canonical diagnostics tail 仍是 `CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`，但不再继续 diagnostics readiness / receipt / record / publication / output tail。

新的 next opening 是：

`P1 internal Renderer command packet post-normalization handoff preflight decision`
