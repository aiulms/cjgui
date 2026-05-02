# P1 Renderer backend shell preflight decision

日期：2026-05-02

本轮任务：完成 `P1 internal Renderer backend shell preflight decision`。

本轮是 docs-only preflight，不写 runtime code，不新增 `.cj` 文件，不运行 build / smoke。

## Current Context

Renderer backend no-render tail 已经由 [2026-05-02-p1-renderer-backend-tail-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-tail-milestone-manifest.md) 封成 milestone。

当前 canonical endpoint：

- `CjguiInternalRendererNoRenderBindingReadiness`
- `cjguiInternalExecuteDefaultRendererAdapterBindingDraft()`

它只表示 future backend adapter runway readiness，不是 platform adapter、Metal / AppKit adapter、CAMetalLayer owner、MTLDevice、command buffer、native handle、raw pointer、renderer state write 或 render permission。

Same-shape Boundary Brake 已生效。上一阶段已经明确拒绝继续开 adapter lifecycle wrapper；本轮 preflight 必须判断是否存在新的 backend shell owner truth，而不是把 binding readiness 再包成 lifecycle / receipt / record 同构尾巴。

## Preflight Answers

### Owner

下一轮若 implementation，应新建 owner file：

- `runtime/cjgui/src/runtime_renderer_backend_shell.cj`

不应回塞到 renderer backend tail owner files：

- `runtime_renderer_handoff.cj`
- `runtime_renderer_backend_adapter.cj`
- `runtime_renderer_backend_contract.cj`
- `runtime_renderer_backend_capability.cj`
- `runtime_renderer_adapter_selection.cj`
- `runtime_renderer_adapter_binding.cj`

### Truth

Backend shell 的 truth 只能是 internal value-style backend shell facts。

它是 future backend adapter 的内部 shell contract / entry shell，不是平台 shell，不是 backend implementation，不是 renderer state，也不是 render permission。

### Input

第一刀只允许消费：

- `CjguiInternalRendererNoRenderBindingReadiness`

不得读取 Queue / Action / Runtime lower-level mutable facts，不得读取 platform object / native handle / raw pointer。

### Output

下一轮 implementation 可表达 internal value-style facts，例如：

- `CjguiInternalRendererBackendShellIntent`
- `CjguiInternalRendererBackendShellCandidate`
- `CjguiInternalRendererBackendShellAdmission`
- `CjguiInternalRendererBackendNoRenderShellReadiness`

这些 facts 只能说明 future backend shell boundary 可以继续评估。`NoRenderShellReadiness` 不能被解释成可以 render、可以创建 command buffer、可以选择 Metal / AppKit，或可以持有平台资源。

### Shell Stop-line

Backend shell candidate 不能持有 native handle / raw pointer / platform object，不能承诺 stable backend API 或 public API，也不能代表具体平台 adapter family 已经可用。

Shell 后的下一阶段必须有明确出口：

- command packet validation；
- backend shell manifest stabilization；
- platform abstraction preflight；
- 或明确的 tail consolidation。

不允许继续 lifecycle / receipt / record 同构尾巴。

## Candidate Comparison

### A. P1 internal Renderer backend shell value boundary bundle implementation

选择。

理由：

- Backend tail milestone 已封账，`CjguiInternalRendererNoRenderBindingReadiness` 是当前 canonical endpoint。
- Backend shell 能引入新的 owner truth：future backend adapter 的 internal shell contract / entry shell，而不是 binding 后的同形 readiness wrapper。
- Shell input / output / stop-line 可以被清楚限定为 internal value facts，不需要 Metal / AppKit、command buffer、native handle 或 renderer state。
- 选择 A 后，下一轮仍不写真实 backend，也不 render。

### B. P1 internal Renderer command packet validation boundary bundle implementation

可选但暂缓。

该方向可以回到 backend-agnostic command packet integrity / validation facts，能避免继续 backend tail。但本轮 owner / truth 足够清楚，先开 backend shell value boundary更能回答 tail milestone 后是否存在抽象 backend entry shell。

### C. P1 internal Renderer backend shell manifest stabilization

不选。

当前 owner、input、output 和 stop-line 已经足够清楚；若现在只做 manifest stabilization，会把 preflight 变成文档空转。

### D. Platform abstraction preflight

暂缓。

Platform abstraction vocabulary 更容易靠近 platform object、native handle、Metal / AppKit 术语。应先确认 backend shell 是否成立，再决定是否需要 platform abstraction preflight。

### E. Adapter lifecycle implementation

拒绝。

Same-shape Boundary Brake 已经判定 lifecycle 在当前条件下风险偏薄。没有平台资源 acquire / release、backend object、command buffer、native handle、render execution 或 renderer state truth 时，lifecycle 很容易只是 binding readiness 的同构自包。

### F. Metal / AppKit / CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer

拒绝。

这些都属于具体平台或资源边界，当前 backend shell preflight 不批准。

### G. Render execution / draw call / GPU batching / draw-call merge

拒绝。

当前 renderer runway 仍是 backend-agnostic value facts，不执行 draw call，不做真实 batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list rebuild only。Dirty region / diff / patch 不在本阶段。

### I. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些系统需要独立 owner truth 和 preflight，不能混入 backend shell。

### J. Runtime / Queue / Action integration

暂缓。

当前 renderer backend shell 只消费 renderer backend tail canonical endpoint，不读取 lower-level mutable runtime facts。

### K. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`，本 runway 不新增 public symbol，也不修改该签名。

### L. Consolidation

不选。

当前没有发现明确 dead helper、duplicate projection 或 self-wrapping helper 可安全清理。Same-shape Brake 已经通过 milestone 阻止了 lifecycle wrapper；本轮不需要额外 cleanup。

## Decision

选择：

`P1 internal Renderer backend shell value boundary bundle implementation`

## Next Opening

下一轮默认 owner / write set：

- 新建 `runtime/cjgui/src/runtime_renderer_backend_shell.cj`。
- 只消费 `CjguiInternalRendererNoRenderBindingReadiness`。
- 只输出 internal value-style backend shell facts。
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant renderer manifest / closure。
- 不回塞 renderer backend tail owner files。
- 不触碰 `runtime_state.cj`。

下一轮必须保持：

- no Metal / AppKit / backend implementation；
- no CAMetalLayer / MTLDevice / command buffer；
- no native handle / raw pointer / platform object；
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
- README / GUI_TASK_TRACKER / docs/plans README can find this preflight and next opening
- forbidden check: no runtime code, no `runtime_state.cj`, no `runtime/cjgui/cjpm.toml`, no smoke / harness / native bridge / entry, no `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md`
- public declaration scan: only `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged)`

本轮不运行 `cjpm build` / smoke guard，因为没有 runtime code change。
