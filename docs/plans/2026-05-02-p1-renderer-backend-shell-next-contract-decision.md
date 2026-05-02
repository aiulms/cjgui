# P1 Renderer backend shell next contract decision

日期：2026-05-02

本轮任务：完成 `P1 internal Renderer backend shell value boundary closure / next renderer shell contract decision`。

本轮是 docs-only decision，不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Current Context

上一轮已新增：

- `runtime/cjgui/src/runtime_renderer_backend_shell.cj`

当前 endpoint：

- `CjguiInternalRendererBackendNoRenderShellReadiness`
- `cjguiInternalExecuteDefaultRendererBackendShellDraft()`

Backend shell 只固定 future backend shell 的 owner truth / vocabulary / entry contract / no platform shell / no stable backend interface promise。

它不是 platform shell、backend implementation、renderer state write、render permission，也不持有平台资源。

## Same-shape Boundary Brake Review

Same-shape Boundary Brake 本轮继续生效。

Shell value boundary 已经显式包含：

- shell owner truth；
- shell vocabulary；
- shell entry contract；
- no platform shell；
- no stable backend interface promise；
- no-render shell readiness。

因此，如果下一轮直接开 `shell contract / compatibility placeholder / no-stable-backend-interface / contract admission / no-render contract readiness`，它大概率会把已经存在的 shell facts 再包装成 contract facts。

在没有 platform object、backend object、command buffer、native handle、render execution 或 renderer state truth 前，shell contract value boundary 暂时缺少足够新的 owner truth。继续推进它会有 thin wrapper 回潮风险。

## Candidate Comparison

### A. P1 internal Renderer backend shell contract value boundary bundle implementation

暂缓。

该方向理论上可以表达 shell entry contract / compatibility placeholder / no-stable-backend-interface facts / contract admission / no-render contract readiness。但这些语义已经在 `runtime_renderer_backend_shell.cj` 的字段和注释中被明确表达。

若现在实现 A，很可能只是把 `CjguiInternalRendererBackendNoRenderShellReadiness` 改名投影为 shell contract readiness。它没有新增 platform-resource truth、backend-object truth、validation gate、integration consumer 或真实风险证据，因此不满足 Same-shape Boundary Brake 的继续实现条件。

### B. P1 internal Renderer command packet validation boundary bundle implementation

选择。

理由：

- 它从 backend shell tail 退出，回到 backend-agnostic RenderCommand / BatchingPacket integrity。
- 它能为 future backend shell / adapter runway 提供输入质量事实，而不是继续自包 shell readiness。
- 它可以只消费 `CjguiInternalRenderBatchingPacket` 或等价 backend-agnostic renderer packet endpoint，表达 packet integrity / command shape validation / batching hint consistency / no-render validation readiness facts。
- 它仍不接 Metal / AppKit / backend，不创建 command buffer，不 render。
- 它给 shell 后的出口提供了新的 validation gate，而不是 lifecycle / receipt / record 同构尾巴。

### C. P1 internal Renderer backend shell manifest stabilization bundle implementation

可选但不选。

Shell owner truth 已经由 closure 与 runtime README 记录清楚；如果现在只做 manifest stabilization，会比 B 更容易变成文档空转。除非后续发现 shell manifest drift，否则不需要先单开 manifest。

### D. Backend shell consolidation

暂缓。

当前没有发现明确 duplicate projection、low-value helper 或 self-wrapping helper 可安全删除。若未来 shell owner 出现重复 helper 或同构尾巴，再进入 consolidation。

### E. Concrete platform shell / Metal / AppKit / CAMetalLayer / MTLDevice / command buffer

拒绝。

当前 shell readiness 不是 platform permission，不允许接平台对象、图形资源或 backend implementation。

### F. Render execution / draw call / GPU batching / draw-call merge

拒绝。

当前 renderer runway 仍是 no-render value facts，不执行 draw call，不做真实合批或 GPU batching。

### G. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list / batching packet rebuild only。

### H. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth 与 preflight，不能混入 backend shell 或 validation runway。

### I. Runtime / Queue / Action integration

暂缓。

当前 validation 应保持 renderer-owned backend-agnostic input facts，不读取 Queue / Action / Runtime lower-level mutable facts。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`，本阶段不新增 public symbol，也不修改该签名。

## Decision

选择：

`P1 internal Renderer command packet validation boundary bundle implementation`

## Next Opening

下一轮建议：

- 新建 `runtime/cjgui/src/runtime_renderer_command_validation.cj` 或等价 validation owner。
- 只消费 `CjguiInternalRenderBatchingPacket`，或 preflight 明确选择的 backend-agnostic renderer packet endpoint。
- 表达 internal value-style packet validation facts，例如 command packet validation subject、command shape integrity、batching hint consistency、no-render validation readiness。
- 只做 backend-agnostic integrity / validation facts，不接 backend，不 render。
- 不回塞 `runtime_renderer_backend_shell.cj`，也不继续 shell contract / lifecycle / receipt / record 同构尾巴。

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
