# P1 Renderer state write preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮 docs-only 基于 frame pacing owner manifest、backend object owner manifest、render execution no-op manifest、backend-readiness revisit preflight 与 backend / Metal reference pack，评估是否可以打开 renderer state write runway。

本轮不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不实现 renderer state write、backend / Metal / AppKit、platform object、command buffer commit、GPU submission、render execution、frame completion recording、public diagnostics 或 public API。

## Read Inputs

- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

## Preflight Decision

允许打开 renderer state write runway，但下一步仍只能是 internal no-write value boundary，不是真实 renderer state write。

选择下一阶段：

`P1 internal Renderer renderer state write no-write value boundary bundle implementation`

默认候选 owner：

- `runtime/cjgui/src/runtime_renderer_state_write.cj`

唯一 runtime input 建议：

- `CjguiInternalRendererNoFrameSchedulerReadiness`
- `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`

Docs evidence 可以引用 `CjguiInternalRendererNoBackendObjectReadiness`、`CjguiInternalRendererNoRenderExecutionReadiness` 与 backend / Metal reference pack，但它们不能成为多 runtime input。下一轮 runtime owner 必须保持单一 input，避免把 backend object、render execution no-op 与 frame pacing tail 混成 multi-source readiness wrapper。

Output truth 只能是：

- renderer state write intent value facts。
- state mutation policy value facts。
- commit visibility guard value facts。
- rollback state policy value facts。
- no-state-write readiness value facts。

Renderer state write preflight 明确不等于 renderer state write permission、backend readiness、render permission、frame completion recording、command buffer commit permission、GPU submission permission、public diagnostics 或 public API。

## Why Evidence Is Sufficient For A No-write Value Boundary

[Frame pacing owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md) 已固定 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`。该 endpoint 明确不是 scheduler permission、display-link permission、backend readiness、renderer-state-write readiness、render permission 或 GPU submission permission。

[Backend object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md) 已固定 `CjguiInternalRendererNoBackendObjectReadiness`，并明确 backend acceptance gate 不授予 renderer state write permission，也不创建 backend object / platform object。

[Render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 已固定 `CjguiInternalRendererNoRenderExecutionReadiness`，并明确 no-submit / completion observation 只作为 dehydrated value facts，不注册 callback、不观察真实 GPU completion、不写 renderer state。

[Backend-readiness revisit preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md) 已把 renderer state write owner truth 列为 remaining gap，并明确它阻止 backend-readiness wrapper 误读为 state write readiness。

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 提供 evidence：command buffer completion / presentation / resource lifetime 是 future backend-local concern；frame pacing / drawable acquisition / AppKit resize-scale-color 只能以 dehydrated facts 过界。该 evidence 支撑 no-write boundary，但不批准 callback、state mutation、command buffer commit、GPU submission 或 backend implementation。

因此下一刀可以新增 renderer state write intent / state mutation policy / commit visibility guard / rollback state policy / no-state-write readiness 语义。该新增语义不是 `CjguiInternalRendererNoFrameSchedulerReadiness` 的 receipt / record / publication，因为它必须回答 future state mutation 是否可见、何时不得 commit visibility、rollback state 如何保持 value facts、以及当前为什么仍没有任何 renderer state write。

## No-write Boundary

下一阶段即使选择 value boundary，也必须继续禁止：

- 不写 renderer state。
- 不接 global mutable state。
- 不新增 module-level `var`。
- 不提交 command buffer。
- 不 GPU submission。
- 不记录 frame completion。
- 不实现 backend readiness。
- 不暴露 public diagnostics。
- 不暴露 public API。
- 不创建 backend object。
- 不创建 Metal / AppKit / platform object。
- 不持有 native handle / raw pointer。
- 不注册 callback、observer、event bus、telemetry 或 log sink。

Allowed value facts 只限 future state write intent、state mutation policy、commit visibility guard、rollback state policy、no-state-write readiness。它们不能携带 renderer state object、runtime global mutable reference、completion callback、backend object、platform object、GPU object、native handle 或 raw pointer。

## Relationship To Existing Endpoints

### Frame pacing owner

`CjguiInternalRendererNoFrameSchedulerReadiness` 是下一轮唯一 runtime input。Renderer state write no-write boundary 只能读取 no-frame-scheduler / display timing / frame request gate / pacing failure policy value facts；不能把它包装成 renderer-state-write receipt、frame-completion wrapper、backend-readiness wrapper 或 scheduler-readiness wrapper。

### Backend object owner

`CjguiInternalRendererNoBackendObjectReadiness` 只能作为 docs evidence，说明 backend object、platform confinement 与 backend acceptance gate 已经不授予 state write permission。它不是下一轮 runtime input，也不是 backend readiness final gate。

### Render execution no-op

`CjguiInternalRendererNoRenderExecutionReadiness` 只能作为 docs evidence，说明 no-submit、completion observation 与 rollback / no-draw 是 value facts，不是 completion callback、frame completion record、command buffer commit、GPU submission 或 state mutation。

### Backend / Metal reference pack

Reference pack 只提供 official evidence。它不是 runtime input，不批准 backend object、platform object、display link、render loop、command buffer commit、GPU submission、completion callback、renderer state write 或 public API。

## Candidate Comparison

### A. P1 internal Renderer renderer state write no-write value boundary bundle implementation

选择。

当前 evidence 足以证明 renderer state write runway 有新增 state mutation policy / commit visibility / rollback state / no-state-write 语义。下一轮仍只能新建 internal-only value owner，不写 renderer state，不接 global mutable state / module-level `var`，不提交 command buffer，不 GPU submission，不记录 frame completion，不实现 backend readiness，不创建 platform object，不开放 public diagnostics 或 public API。

### B. P1 internal Renderer backend-readiness revisit

暂缓。

Backend-readiness revisit 已确认 state write owner truth 是 remaining gap。应先建立 no-write value boundary，再重新评估 backend readiness，避免 backend-readiness wrapper 误读 state visibility 或 frame completion。

### C. P1 internal Renderer frame pacing hardening

暂缓。

Frame pacing owner manifest 已固定 display timing / request gate / failure policy；当前没有发现表达不足。若下一轮发现 no-frame-scheduler facts 不够支撑 state write policy，再回到 hardening。

### D. P1 internal Renderer state snapshot / diagnostics docs

暂缓。

State snapshot / diagnostics 仍容易变成 public diagnostics、record / publication 或 frame completion artifact。当前应先完成 no-write owner truth，再决定是否需要 docs-only diagnostics preflight。

### E. Real renderer state write implementation

拒绝。

### F. Command buffer commit / GPU submission / render execution

拒绝。

### G. Backend / Metal / platform implementation

拒绝。

### H. Renderer state receipt / record / publication

拒绝。

Renderer state write runway 不能新增 state receipt / record / publication，也不能把 no-frame-scheduler endpoint 包成 visibility record、frame completion record 或 backend-readiness wrapper。

### I. Dirty-region / UI integration

暂缓。

### J. Public surface expansion

拒绝。

### K. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前风险是 downstream thin wrapper，而不是 consolidation need。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

明确拒绝：

- 把 `CjguiInternalRendererNoFrameSchedulerReadiness` 直接包成 renderer-state-write wrapper。
- backend-readiness wrapper。
- GPU-submission wrapper。
- frame-completion wrapper。
- renderer state receipt / record / publication。
- scheduler-readiness wrapper。
- command-buffer-commit wrapper。
- real renderer state write implementation。

若下一轮选择 A，必须证明新增的是 state mutation policy / commit visibility / rollback state / no-state-write 语义，而不是 no-frame-scheduler tail wrapper。下一轮仍必须禁止 renderer state write、global mutable state、module-level `var`、command buffer commit、GPU submission、frame completion recording、backend readiness implementation、backend / Metal / AppKit / platform object implementation、public diagnostics 与 public API。

## Decision

本轮批准打开 renderer state write runway，但只批准下一轮 internal no-write value boundary。

唯一 next opening：

`P1 internal Renderer renderer state write no-write value boundary bundle implementation`

下一轮若执行，默认 owner 为 `runtime/cjgui/src/runtime_renderer_state_write.cj` 或等价 internal-only owner；只消费 `CjguiInternalRendererNoFrameSchedulerReadiness`；只输出 renderer state write intent / state mutation policy / commit visibility guard / rollback state policy / no-state-write readiness value facts。

下一轮仍不得写 renderer state，不得接 global mutable state / module-level `var`，不得记录 frame completion，不得实现 backend readiness，不得提交 command buffer，不得 GPU submission，不得执行 render，不得创建 backend / Metal / AppKit / platform object，不得开放 public diagnostics / public API，不得引入 native handle 或 raw pointer。

## Downstream Value Boundary Closure

Renderer state write no-write value boundary 已完成：

- [2026-05-04-p1-internal-renderer-state-write-no-write-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-state-write-no-write-boundary-closure-review.md)

该 closure 新增 `runtime/cjgui/src/runtime_renderer_state_write.cj`，固定 `CjguiInternalRendererNoStateWriteReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()` 作为当前 no-state-write endpoint。下一步转入 docs-only `P1 internal Renderer renderer state write no-write closure / next renderer state decision`，不批准 renderer state write、backend readiness、command buffer commit、GPU submission、render execution、backend / Metal / AppKit implementation、platform object、public diagnostics 或 public API。

## Downstream No-write Next-boundary Decision

Renderer state write no-write next-boundary decision 已完成：

- [2026-05-04-p1-renderer-state-write-no-write-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoStateWriteReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()` 已足够作为当前 no-state-write endpoint。下一步选择 docs-only `P1 internal Renderer renderer state write no-write manifest stabilization bundle implementation`，先固定 `runtime_renderer_state_write.cj` owner / truth / canonical endpoint / stop-line；不批准 state-write receipt / record / publication、backend-readiness wrapper、GPU-submission wrapper、frame-completion wrapper、command-buffer-commit wrapper、real renderer state write、render completion tracking、backend / Metal / AppKit、platform object、public diagnostics 或 public API。

## Downstream No-write Manifest Stabilization

Renderer state write no-write manifest stabilization 已完成：

- [2026-05-04-p1-renderer-state-write-no-write-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
- [2026-05-04-p1-internal-renderer-state-write-no-write-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-state-write-no-write-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_state_write.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoStateWriteReadiness`。下一步转向 docs-only `P1 internal Renderer backend-readiness final preflight decision`；不批准 renderer state write、backend readiness wrapper、state-write receipt / record / publication、GPU-submission wrapper、frame-completion wrapper、command-buffer-commit wrapper、backend / Metal / AppKit implementation、platform object、public diagnostics 或 public API。
