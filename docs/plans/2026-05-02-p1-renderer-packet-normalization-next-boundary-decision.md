# P1 Renderer packet normalization next-boundary decision

日期：2026-05-02

本轮任务：完成 `P1 internal Renderer packet normalization closure / next renderer packet boundary decision`。

本轮是 docs-only decision，不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Current Context

上一轮已新增：

- `runtime/cjgui/src/runtime_renderer_packet_normalization.cj`

当前 endpoint：

- `CjguiInternalRendererPacketNormalizationResult`
- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`

它只表达 backend-agnostic normalized packet / ordering facts / material grouping hints / normalization result value facts。

它不是 backend packet、command buffer、renderer state write、render permission、真实排序结果、真实 draw-call merge、GPU batching、dirty-region、diff 或 patch。

## Same-shape Boundary Brake Review

Same-shape Boundary Brake 本轮继续生效。

`CjguiInternalRendererPacketNormalizationResult` 已经是 normalization runway 的 current endpoint。如果下一轮继续新增 normalization receipt / normalization record / publication / backend packet readiness wrapper，就会把 normalization result 重新包装成同构尾巴，缺少新的 owner truth、consumer、integration 或风险证据。

因此本轮不批准 thin wrapper。若继续推进代码，必须证明新增不可替代语义；否则应先把 normalization endpoint 封成 manifest。

## Candidate Comparison

### A. P1 internal Renderer packet normalization manifest stabilization bundle implementation

选择。

理由：

- `CjguiInternalRendererPacketNormalizationResult` 已足够作为当前 normalization endpoint。
- Manifest 可固定 normalization owner / truth / canonical endpoint / stop-line，避免后续把 normalization result 包成 receipt / record / publication。
- Normalization 已经新增 packet shape / ordering facts / material grouping hints 的语义；当前更需要封账，而不是继续扩同构尾巴。
- 这一步仍是 docs / manifest stabilization，不接 backend、不 render、不新增 public surface。

### B. P1 internal Renderer packet error taxonomy boundary bundle implementation

可选但暂缓。

如果未来发现 normalization failure / degraded / blocked reason 不足，可以单独开 packet error taxonomy。但当前 result 已能表达 accepted / deferred / blocked / fail-closed value facts，暂未阻塞下一步。

### C. P1 internal Renderer normalized packet handoff boundary bundle implementation

暂缓。

当前没有明确 downstream owner。没有明确 consumer 时，handoff 容易退化成 receipt wrapper，不满足 Same-shape Boundary Brake。

### D. P1 internal Renderer packet normalization consolidation bundle implementation

暂缓。

当前没有发现明确 duplicate projection、low-value helper 或 self-wrapping helper。若 manifest 后发现 cleanup target，再进入 consolidation。

### E. Normalization receipt / record / publication thin wrapper

拒绝。

这是本轮 brake 明确要避免的路径。

### F. Backend packet / command buffer / backend submission

拒绝。

Normalization result 不是 backend packet readiness，也不允许生成 command buffer 或 backend submission。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Ordering facts 只描述 value facts，不执行真实排序；material grouping facts 也不是 draw-call merge 或 GPU batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍固定 full DisplayList / command list / batching packet rebuild only。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Normalization endpoint 不持有平台资源，也不是平台 bridge 或 backend adapter。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 packet normalization endpoint。

### K. Runtime / Queue / Action integration

暂缓。

Normalization owner 当前只消费 renderer command validation result，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

选择：

`P1 internal Renderer packet normalization manifest stabilization bundle implementation`

## Next Opening

下一轮建议：

- 新增 `docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md`。
- 新增 closure review，固定 normalization owner / truth / canonical endpoint / stop-line。
- 不新增 runtime code，除非只做 comment-only clarification 且必须说明必要性。
- 记录 canonical endpoint：`CjguiInternalRendererPacketNormalizationResult` / `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`。
- 明确 normalization result 不是 backend packet、command buffer、renderer state write、render permission、sorting side effect、draw-call merge、GPU batching、diff 或 patch。
- 给后续候选排序：packet error taxonomy、normalized packet handoff、normalization consolidation。

必须保持：

- no runtime code in this decision round；
- no Metal / AppKit / backend implementation；
- no CAMetalLayer / MTLDevice / command buffer；
- no native handle / raw pointer / platform object；
- no stable backend API promise；
- no render / draw call；
- no real draw op / GPU batching / draw-call merge；
- no sorting side effect；
- no dirty-region / diff / patch / incremental render；
- no Widget / Layout / Text / IME / Accessibility / ECS；
- no Queue / Action / Runtime lower-level mutable facts；
- no public symbol expansion；
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change；
- no `runtime_state.cj` touch。

## Verification Plan

本轮验证：

- `git diff --check`
- Markdown absolute link missing target check
- README / GUI_TASK_TRACKER / docs/plans README can find this decision and next opening
- forbidden check: no runtime code, no `runtime_state.cj`, no `runtime/cjgui/cjpm.toml`, no smoke / harness / native bridge / entry, no `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md`
- public declaration scan: only `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged)`

本轮不运行 `cjpm build` / smoke guard，因为没有 runtime code change。
