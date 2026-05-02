# P1 Renderer adapter binding next lifecycle decision

日期：2026-05-02

状态：docs-only decision

## Context

上一轮已完成 `P1 internal Renderer adapter binding value boundary bundle implementation`。

当前 endpoint：

- `CjguiInternalRendererNoRenderBindingReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererAdapterBindingDraft()`
- owner file：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_adapter_binding.cj`

该 endpoint 只表示 adapter binding boundary 可继续评估。它不是具体平台 adapter binding，不是 backend implementation，不是 render permission，不是平台资源许可，也不是 renderer state write。

本轮必须判断下一刀是否继续进入 adapter lifecycle value boundary，或先把 renderer backend tail 封成 milestone / manifest。

## Thin Wrapper Risk Check

近期 renderer backend tail 已经形成连续 owner chain：

1. `runtime_renderer_handoff.cj`：packet handoff receipt。
2. `runtime_renderer_backend_adapter.cj`：backend adapter candidate / capability placeholder / adapter admission / no-render readiness。
3. `runtime_renderer_backend_contract.cj`：backend contract / capability set / adapter contract admission / no-render contract readiness。
4. `runtime_renderer_backend_capability.cj`：capability profile / feature placeholder / constraint profile / no-render capability readiness。
5. `runtime_renderer_adapter_selection.cj`：selection policy / candidate family / selection admission / no-render selection readiness。
6. `runtime_renderer_adapter_binding.cj`：binding intent / binding candidate / binding admission / no-render binding readiness。

这些 files 的结构高度同构：每轮都只消费上游 readiness，输出一组 no-render value facts，并重复 fail-closed / defer-only / stop-line guards。它们目前仍有价值，因为把 future backend adapter 从 packet handoff 推进到 contract、capability、selection、binding，已经建立了一条可审计的 backend 前置链。

但在当前 stop-line 下，adapter lifecycle 还不能拥有真实 lifecycle owner truth：

- 不能 acquire / release 平台资源。
- 不能创建 backend adapter object。
- 不能绑定 platform object / native handle / raw pointer。
- 不能创建 command buffer / GPU device / CAMetalLayer。
- 不能 render、submit、flush 或 write renderer state。
- 不能表达真实平台 lifecycle phase transitions。

因此，若下一轮直接实现 `adapter lifecycle value boundary`，它很可能只会把 `CjguiInternalRendererNoRenderBindingReadiness` 再包成 lifecycle phase / lifecycle admission / no-render lifecycle readiness 的同构 wrapper，而不是新增稳定 owner truth。这触发 Tail Endpoint Exit Gate 与 thin wrapper 回潮风险。

## Candidate Comparison

### A. P1 internal Renderer adapter lifecycle value boundary bundle implementation

仅当 lifecycle 能新增明确语义时才应选择，例如 adapter lifecycle phase、lifecycle scope、lifecycle admission、no-render lifecycle readiness，并且这些 facts 不只是 binding readiness 的 receipt / record wrapper。

本轮暂缓。理由是当前禁止具体平台资源、backend object、command buffer、native handle、render execution 和 renderer state write，lifecycle 无法拥有真实 acquire / release / phase transition truth。继续 implementation 容易变成低价值 thin wrapper。

### B. P1 internal Renderer backend tail milestone / manifest stabilization bundle implementation

选择。

理由：

- handoff -> backend adapter -> contract -> capability -> selection -> binding 已经形成完整 no-render backend tail。
- 当前 endpoint `CjguiInternalRendererNoRenderBindingReadiness` 足够作为 backend tail milestone endpoint。
- lifecycle 语义在没有 platform resource 和 adapter object 前还不稳定。
- 先封 manifest 可以固定 owner / truth / stop-line / endpoint / public allowlist，并明确下一阶段是 backend shell preflight、platform abstraction preflight，还是暂停 renderer backend tail。
- 这不是 cleanup 空转，而是防止连续同构 owner 继续增长。

### C. Renderer backend tail consolidation

暂缓。当前没有发现明确 dead helper、duplicate projection 或 self-wrapping helper 可安全删除。问题不是已有 symbols 已死，而是下一刀需要先封 milestone，避免继续扩 tail。

### D. Concrete Metal/AppKit adapter lifecycle

拒绝。过早，且会绕过 no-backend / no-platform stop-line。

### E. CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer

拒绝。过早，且会把 value boundary 升级成平台资源边界。

### F. Render execution / draw call / GPU batching / draw-call merge

拒绝。当前 command / batching facts 仍是 dehydrated hints，不是真实绘制许可。

### G. Dirty-region / diff / patch / incremental render

暂缓。P1 仍坚持 full DisplayList / command list rebuild only。

### H. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。Scene / Renderer input contract 只预留语义字段，不实现这些系统。

### I. Runtime / Queue / Action integration

暂缓。Renderer backend tail 当前不读取 Queue / Action / Runtime lower-level mutable facts。

### J. Public surface expansion

拒绝。public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

选择：

`P1 internal Renderer backend tail milestone / manifest stabilization bundle implementation`

本 decision 不批准下一轮新增 `runtime_renderer_adapter_lifecycle.cj`。如果未来要重新打开 adapter lifecycle，必须先在 milestone 后证明 lifecycle 拥有不依赖平台资源的独立 owner truth，而不是 binding readiness 的同构 wrapper。

## Next Opening

`P1 internal Renderer backend tail milestone / manifest stabilization bundle implementation`

下一轮默认 docs / manifest stabilization：

- 固定 renderer backend tail owner chain：handoff / backend adapter / contract / capability / selection / binding。
- 明确 canonical tail endpoint：`CjguiInternalRendererNoRenderBindingReadiness`。
- 记录 `CjguiInternalRendererNoRenderBindingReadiness` 不是 backend object、platform binding、render permission、command buffer、renderer state write 或 platform resource permission。
- 判断 milestone 后下一阶段是否进入 backend shell preflight、platform abstraction preflight，或暂停 renderer backend tail。
- 不新增 runtime code，除非只补注释。
- 不触碰 `runtime_state.cj`。

## Stop-line

继续禁止：

- no concrete platform adapter binding。
- no Metal / AppKit adapter。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no concrete platform capability or adapter promise。
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

## Verification Plan

- `git diff --check`
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README can find this decision and next opening。
- forbidden check confirms no runtime code, `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, `AGENTS.md`, `CLAUDE.md`, or `CANGJIE_ISSUE_LEDGER.md` changes。
- public declaration scan confirms the only allowlisted public symbol remains `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- `gitnexus_detect_changes(scope=unstaged)` records risk / affected processes。

本轮 docs-only，不运行 build / smoke。
