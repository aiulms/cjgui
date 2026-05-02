# P1 Renderer packet error taxonomy next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

上一轮新增 `runtime/cjgui/src/runtime_renderer_packet_error_taxonomy.cj`，当前 endpoint 是：

- `CjguiInternalRendererPacketErrorTaxonomyResult`
- `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`

它只表达 renderer packet value pipeline 内部的 failure / degraded / blocked reason taxonomy facts。它不是异常系统、public error API、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。

本轮不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Boundary Reading

当前 taxonomy endpoint 已具备独立语义：

- failure taxonomy：区分 no failure / deferred / blocked / fail-closed 分类。
- degraded reason：保留内部 degraded reason 分类位置，不发布外部错误。
- blocked reason：记录 fail-closed blocked reason value facts。
- taxonomy result：只表达 internal taxonomy ready / defer / blocked facts。

这些 facts 仍保持 backend-agnostic，不读取 Queue / Action / Runtime lower-level mutable facts，不接平台资源，不引入异常、日志、observer callback 或公开错误面。

## Candidate Comparison

### A. P1 internal Renderer packet error taxonomy manifest stabilization bundle implementation

选择。

理由：

- `CjguiInternalRendererPacketErrorTaxonomyResult` 已足够作为当前 canonical endpoint。
- taxonomy 已新增 failure / degraded / blocked reason 语义，不需要继续追加 receipt / record / publication。
- 下一步应固定 owner / truth / canonical endpoint / stop-line，防止 taxonomy result 被误读成 diagnostics publication、backend readiness 或 public error API。
- manifest 可保留后续出口：packet diagnostics boundary、normalized packet handoff preflight、backend packet preflight 或 consolidation，但不直接进入薄 wrapper。

### B. P1 internal Renderer packet diagnostics boundary bundle implementation

可选但暂缓。

如果未来需要从 taxonomy result 形成 internal diagnostics facts，可以新开 implementation。但该 boundary 必须仍是 internal value facts，不得成为 public diagnostics、logging subsystem、observer callback 或 render failure callback。

### C. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

只有能找到明确 downstream owner 时才开。当前若直接 handoff，容易退化成 taxonomy result 的 receipt wrapper，不满足 Same-shape Boundary Brake。

### D. P1 internal Renderer packet taxonomy consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前没有 cleanup blocker。

### E. Taxonomy receipt / record / publication thin wrapper

拒绝。

这会把 taxonomy result 换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

### F. Backend packet / command buffer / backend submission

拒绝。

Taxonomy result 不是 backend packet readiness，也不允许生成 command buffer 或 backend submission。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Taxonomy 只分类 packet value facts，不执行 ordering mutation、draw-call merge 或 GPU batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list rebuild only。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Taxonomy endpoint 不接平台对象，不持有 native handle，也不是 backend adapter。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 renderer packet taxonomy endpoint。

### K. Runtime / Queue / Action integration

暂缓。

Taxonomy owner 当前只消费 `CjguiInternalRendererPacketNormalizationResult`，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮继续生效。

本 decision 不批准 taxonomy receipt、taxonomy record、taxonomy publication、diagnostics publication wrapper 或 backend readiness wrapper。原因是 `CjguiInternalRendererPacketErrorTaxonomyResult` 已经是当前 taxonomy endpoint；在没有明确 downstream owner、integration need 或 cleanup evidence 前，继续包装只会制造同构尾巴。

下一步选择 manifest stabilization，是为了把当前 endpoint 封账，而不是继续延长 tail。

## Decision

最终选择：

`P1 internal Renderer packet error taxonomy manifest stabilization bundle implementation`

下一轮应默认 docs / manifest stabilization，不写 runtime code。建议新增：

- `docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md`
- `docs/plans/2026-05-02-p1-internal-renderer-packet-error-taxonomy-manifest-stabilization-closure-review.md`

Manifest 应固定：

- owner file：`runtime/cjgui/src/runtime_renderer_packet_error_taxonomy.cj`
- canonical endpoint：`CjguiInternalRendererPacketErrorTaxonomyResult`
- default draft：`cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`
- truth：internal-only failure / degraded / blocked reason taxonomy value facts
- stop-line：no exception system / no public error API / no backend error handler / no logging subsystem / no observer callback / no render failure callback / no backend packet / no command buffer / no render permission

## Stop-line

继续禁止：

- no runtime code in this decision round。
- no `.cj` edits。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no stable backend API promise。
- no render side effect / draw call execution。
- no real draw op semantics。
- no real GPU batching / draw-call merge。
- no sorting side effect。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public error API / exception system / observer callback / logging subsystem。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Verification Plan

本轮只需要 docs-level verification：

- `git diff --check`
- Markdown absolute link missing target check
- README / GUI_TASK_TRACKER / docs/plans README 能找到本 decision 与 next opening
- forbidden check：确认本轮未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged)`

本轮不运行 `cjpm build` 或 smoke guard。
