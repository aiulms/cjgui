# P1 internal Renderer packet normalization manifest stabilization closure review

日期：2026-05-02

本轮任务：实现 `P1 internal Renderer packet normalization manifest stabilization bundle implementation`。

本轮为 docs / manifest stabilization，没有修改 runtime code，没有修改 `.cj` 文件，没有运行 build / smoke。

## Landed Scope

新增 manifest：

- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)

同步更新：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)
- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)

## Manifest Conclusion

Normalization manifest 固定当前 owner / truth / canonical endpoint：

- owner file：`runtime/cjgui/src/runtime_renderer_packet_normalization.cj`
- canonical endpoint：`CjguiInternalRendererPacketNormalizationResult`
- default draft：`cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`

Current truth：

- backend-agnostic normalized packet candidate facts；
- normalized ordering facts；
- normalized material grouping hint facts；
- no-render / no-backend / no-command-buffer normalization result facts。

该 endpoint 不是 backend packet、backend shell、platform adapter、command buffer、renderer state write、render permission、sorting side effect、draw-call merge、GPU batching、dirty-region、diff 或 patch。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 manifest stabilization 生效。

`CjguiInternalRendererPacketNormalizationResult` 已经足够作为 current normalization endpoint。继续新增 normalization receipt / record / publication 会把同一 endpoint 换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此本轮选择封账，而不是继续新增同构 tail。下一轮也不默认进入 normalized packet handoff；只有存在明确 downstream owner 时才允许重新评估 handoff。

## Next Stage Candidate Comparison

### A. P1 internal Renderer packet error taxonomy boundary bundle implementation

选择为 next opening。

理由：

- normalization endpoint 已封账；
- failure / degraded / blocked reason taxonomy 能新增明确语义；
- taxonomy 仍是 backend-agnostic value facts，不进入 renderer backend execution；
- 它比 receipt / backend packet 更稳，能先解释 normalization blocked reason。

### B. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

没有明确 downstream owner 时，handoff 会退化成 receipt wrapper。

### C. P1 internal Renderer backend packet preflight decision

暂缓并慎选。

Backend packet 术语容易被误读成 command buffer / backend submission，必须等 taxonomy 或 downstream owner 更清楚后再评估。

### D. P1 internal Renderer packet normalization consolidation bundle implementation

暂缓。

当前没有发现 duplicate projection、low-value helper 或 self-wrapping helper。

### E. Normalization receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确禁止的 thin-wrapper path。

### F. Backend packet / command buffer / backend submission

拒绝。

当前 normalization result 不是 backend packet readiness。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Ordering / grouping 仍是 value facts，不执行排序，也不做真实合批。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍 full rebuild only。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

本 runway 仍不接平台资源。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth。

### K. Runtime / Queue / Action integration

暂缓。

本 manifest 不读取 lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 未变。

## Verification

已运行：

- `git diff --check`
  - 结果：通过。
- Markdown absolute link missing target check
  - 结果：通过。
- README / GUI_TASK_TRACKER / docs/plans README reachability check
  - 结果：均可找到 manifest / closure / next opening。
- forbidden check
  - 结果：未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke / harness / native bridge / entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan
  - 结果：唯一 declaration-level public symbol 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`
  - 结果：risk `low`，affected processes `0`。

本轮未运行 `cjpm build` / smoke guard，因为没有 runtime code change。

## Stop-line

本轮保持：

- no runtime code；
- no `.cj` edits；
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

## Next Opening

建议下一步：

`P1 internal Renderer packet error taxonomy boundary bundle implementation`

下一轮如果实现，应只消费 `CjguiInternalRendererPacketNormalizationResult`，表达 normalization failure / degraded / blocked reason taxonomy value facts。不得生成 backend packet、command buffer、render permission、sorting side effect、draw-call merge、GPU batching、diff / patch 或 public surface expansion。
