# P1 Renderer command packet validation manifest

日期：2026-05-02

状态：manifest stabilization

## Purpose

本 manifest 固定 renderer command packet validation 的 owner / truth / canonical endpoint / stop-line，防止 `CjguiInternalRendererCommandValidationResult` 后继续长 validation receipt / record / publication 同构尾巴。

这不是 backend manifest，也不是 renderer execution manifest。它只封账 command / batching packet 的 backend-agnostic integrity gate。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_validation.cj`

Upstream facts：

- `CjguiInternalRenderBatchingPacket`
- `CjguiInternalRenderCommandPacket`

Canonical endpoint：

- `CjguiInternalRendererCommandValidationResult`
- `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`

Current truth：

- backend-agnostic command / batching packet integrity facts。
- validation admission / result facts。
- no-render / no-backend / no-command-buffer validation boundary。

该 truth 不是 validation receipt、validation record 或 validation publication。它也不是 backend shell、platform adapter、Metal / AppKit adapter、command buffer、renderer state write、render permission 或真实 draw / batching。

## Current Pipeline

当前 validation pipeline：

1. `CjguiInternalRenderBatchingPacket`
2. preserved `CjguiInternalRenderCommandPacket` facts
3. `CjguiInternalRendererCommandPacketValidation`
4. `CjguiInternalRendererBatchingPacketIntegrity`
5. `CjguiInternalRendererCommandValidationAdmission`
6. `CjguiInternalRendererCommandValidationResult`

Default draft：

- `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`
- 只调用 `cjguiInternalExecuteDefaultRenderBatchingHintDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / platform resources。

## Validation Truth

Command packet validation 固定以下 facts：

- full rebuild only。
- stable node id。
- bounds。
- clip。
- z-order。
- material key。
- scene / display / command version。
- invalidation / repaint hint。
- placeholder command kind。
- backend-agnostic packet preservation。

Batching packet integrity 固定以下 facts：

- batch key 仍是 hint。
- ordering hint 不执行排序副作用。
- batching plan 仍是 dehydrated plan。
- no real command merge。
- no real GPU batching。
- no drawing permission。

Validation result 只表示 internal value-fact integrity gate 的结果。它不表示 backend permission、render permission、command buffer readiness 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

`CjguiInternalRendererCommandValidationResult` 已经是当前 packet integrity endpoint。继续新增 validation receipt / record / publication 会把同一结果换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- validation receipt。
- validation record。
- validation publication。
- validation readiness wrapper。
- shell contract / lifecycle continuation。

若未来要继续实现，必须证明新边界新增不可替代语义，例如 normalization、failure taxonomy、真正 downstream owner 或明确 consolidation target。

## Explicit Non-Truth

本 manifest 明确当前 validation endpoint 不是：

- validation receipt / record / publication。
- backend shell。
- platform adapter。
- Metal / AppKit。
- CAMetalLayer / MTLDevice / command buffer。
- native handle / raw pointer / platform object。
- renderer state write。
- render permission。
- draw call。
- GPU batching。
- draw-call merge。
- dirty-region / diff / patch / incremental render。
- Widget / Layout / Text / IME / Accessibility / ECS。
- public API / public C ABI。

## Full Rebuild Policy

P1 仍保持 full DisplayList / command list / batching packet rebuild only。

当前不实现：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental command update。
- incremental batching update。
- partial repaint。
- render cache。
- actual draw-call merge。
- GPU batching。

Validation 只确认 full rebuild value facts 被保留，不引入 incremental render 语义。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no stable backend API promise。
- no render side effect / draw call execution。
- no real draw op semantics。
- no real GPU batching / draw-call merge。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer packet normalization preflight decision

选择。

理由：

- Validation endpoint 已封账后，下一步可以评估是否需要 backend-agnostic normalized packet facts。
- Normalization 如果成立，应只讨论 canonical packet shape、field presence、stable ordering facts 或 normalization admission。
- 该 preflight 仍不得实现 sorting side effect、diff / patch、backend packet、command buffer 或 renderer state write。
- 先 preflight 能避免直接实现一个新的同构 wrapper。

### B. P1 internal Renderer validation error taxonomy boundary bundle implementation

可选但暂缓。

若未来发现 validation failure reason / degraded / blocked taxonomy 不足，可开独立 decision 或 implementation。当前 validation result 已表达 accepted / deferred / blocked / fail-closed facts，本轮没有证据显示 taxonomy 阻塞下一步。

### C. P1 internal Renderer command packet validation consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前 manifest 先固定 endpoint 和 stop-line，不为 cleanup 而 cleanup。

### D. Validation receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### E. Backend shell continuation / shell contract / lifecycle

拒绝。

Validation 是从 backend shell tail 回到 packet integrity 的出口，不能马上回到 shell tail 自包。

### F. Metal / AppKit / command buffer / render execution

拒绝。

Validation result 不是平台资源许可，也不是 draw-call permission。

### G. Dirty-region / Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth。P1 当前仍是 full rebuild renderer input runway。

### H. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer packet normalization preflight decision`

下一轮应保持 docs-only，评估 normalization owner / truth / input / output / stop-line 与是否真的需要 implementation。它不批准 backend implementation、platform object、command buffer、render execution、diff / patch、sorting side effect 或 public surface expansion。

## Downstream Status

Renderer packet normalization preflight 已完成：

- [2026-05-02-p1-renderer-packet-normalization-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-preflight-decision.md)

Renderer packet normalization boundary 已落地：

- [2026-05-02-p1-internal-renderer-packet-normalization-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-normalization-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererPacketNormalizationResult` / `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`。它只消费 `CjguiInternalRendererCommandValidationResult`，表达 normalized packet candidate / normalized ordering facts / normalized material grouping facts / normalization result。Normalization 仍是 backend-agnostic value facts，不是 validation receipt / record / publication、backend packet、command buffer、renderer state write、render permission、sorting side effect 或真实 batching。

Renderer packet normalization manifest 已完成：

- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)
- [2026-05-02-p1-internal-renderer-packet-normalization-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-normalization-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererPacketNormalizationResult` / `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()` 为 normalization canonical endpoint。Same-shape Boundary Brake 生效：下一阶段不新增 normalization receipt / record / publication，而是进入 packet error taxonomy boundary。

Renderer packet error taxonomy boundary 已落地：

- [2026-05-02-p1-internal-renderer-packet-error-taxonomy-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-error-taxonomy-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererPacketErrorTaxonomyResult` / `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`。它在 normalization endpoint 后补 failure / degraded / blocked reason taxonomy；不新增 taxonomy receipt / record / publication，不引入异常系统、后端错误处理器、绘制失败回调或 public surface。

Renderer packet error taxonomy next-boundary decision 已完成：

- [2026-05-02-p1-renderer-packet-error-taxonomy-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-next-boundary-decision.md)

该 decision 选择 error taxonomy manifest stabilization，继续防止 packet validation / normalization / taxonomy 后出现 receipt / record / publication 同构尾巴。

Renderer packet error taxonomy manifest 已完成：

- [2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md)
- [2026-05-02-p1-internal-renderer-packet-error-taxonomy-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-error-taxonomy-manifest-stabilization-closure-review.md)

当前 downstream endpoint 仍是 `CjguiInternalRendererPacketErrorTaxonomyResult` / `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`。它已由 manifest 固定为 internal-only failure / degraded / blocked reason taxonomy facts；下一阶段进入 internal packet diagnostics boundary，而不是 taxonomy receipt / record / publication。
