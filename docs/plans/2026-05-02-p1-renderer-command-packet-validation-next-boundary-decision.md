# P1 Renderer command packet validation next-boundary decision

日期：2026-05-02

本轮任务：完成 `P1 internal Renderer command packet validation closure / next renderer packet validation decision`。

本轮是 docs-only decision，不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Current Context

上一轮已新增：

- `runtime/cjgui/src/runtime_renderer_command_validation.cj`

当前 endpoint：

- `CjguiInternalRendererCommandValidationResult`
- `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`

它只表达 command / batching packet integrity gate：

- full rebuild only；
- stable node id；
- bounds；
- clip；
- z-order；
- material key；
- version；
- invalidation / repaint hint；
- placeholder command kind；
- batch key hint；
- ordering hint；
- dehydrated batching plan。

它不是 backend shell、platform adapter、Metal / AppKit、command buffer、renderer state write、render permission 或真实 draw / batching。

## Same-shape Boundary Brake Review

Same-shape Boundary Brake 本轮继续生效。

Validation result 已经是 command / batching packet integrity gate 的 current endpoint。如果下一轮直接新增 validation receipt / validation record / publication / readiness wrapper，就会把 `CjguiInternalRendererCommandValidationResult` 改名再包装一层，缺少新的 owner truth、consumer、integration 或风险证据。

因此本轮默认不继续新增同构 validation tail。除非下一步能证明有不可替代语义，否则应先封成 manifest 或转向明确的新 gate。

## Candidate Comparison

### A. P1 internal Renderer command packet validation manifest stabilization bundle implementation

选择。

理由：

- `CjguiInternalRendererCommandValidationResult` 已经足够作为当前 packet integrity endpoint。
- Manifest 可固定 validation owner / truth / stop-line，避免后续把 validation result 继续包成 receipt / record / publication。
- Validation 是从 backend shell tail 回到 command / batching packet integrity 的新出口；需要先把术语和边界封账。
- 这一步不新增 runtime code，也不接 backend。

### B. P1 internal Renderer packet normalization boundary bundle implementation

可选但暂缓。

Normalization 可能在未来新增明确语义，例如 backend-agnostic normalized packet facts、canonical ordering shape 或 field presence projection。但当前还没有 normalization owner truth，也不能做 sorting side effect、diff / patch、backend packet 或 command buffer。建议先做 validation manifest，等 normalization 的输入输出和 stop-line 更清楚后再开。

### C. P1 internal Renderer validation error taxonomy boundary bundle implementation

可选但暂缓。

当前 validation result 已能表达 accepted / deferred / blocked / fail-closed value facts。若未来需要 failure reason / degraded / blocked taxonomy，可在 manifest 后单独 preflight；本轮没有证据表明 taxonomy vocabulary 已经阻塞下一步。

### D. P1 internal Renderer command packet validation result handoff boundary bundle implementation

暂缓。

目前没有明确 downstream owner。没有 downstream owner 时，handoff 容易退化成 receipt wrapper，不满足 Same-shape Boundary Brake。

### E. Validation receipt / record / publication thin wrapper

拒绝。

这是本轮 brake 明确要避免的路径。

### F. Backend shell continuation / shell contract / lifecycle

拒绝。

上一轮已经从 shell tail 退出，回到 packet integrity gate。继续 shell contract / lifecycle 会回到同构 tail。

### G. Metal / AppKit / CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer

拒绝。

Validation result 不是平台资源许可。

### H. Render execution / draw call / GPU batching / draw-call merge

拒绝。

Validation result 不是绘制许可，也不代表真实 batching。

### I. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list / batching packet rebuild only。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 validation endpoint。

### K. Runtime / Queue / Action integration

暂缓。

Validation owner 当前只消费 backend-agnostic renderer packet facts，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### M. Consolidation

暂缓。

当前没有发现明确 dead helper、duplicate projection 或 self-wrapping helper 可安全删除。若 manifest 后发现 validation owner 内有低价值 helper 或重复 projection，再进入 consolidation。

## Decision

选择：

`P1 internal Renderer command packet validation manifest stabilization bundle implementation`

## Next Opening

下一轮建议：

- 新增 `docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md`。
- 新增 closure review，固定 validation owner / truth / canonical endpoint / stop-line。
- 不新增 runtime code，除非只做 comment-only clarification 且必须说明必要性。
- 记录 canonical endpoint：`CjguiInternalRendererCommandValidationResult` / `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`。
- 明确 validation result 不是 backend shell、platform adapter、command buffer、renderer state write、render permission 或真实 draw / batching。
- 给后续候选排序：packet normalization preflight、validation error taxonomy preflight、validation consolidation、platform abstraction preflight。

必须保持：

- no runtime code in this decision round；
- no Metal / AppKit / backend implementation；
- no CAMetalLayer / MTLDevice / command buffer；
- no native handle / raw pointer / platform object；
- no stable backend API promise；
- no render / draw call；
- no real draw op / GPU batching / draw-call merge；
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
