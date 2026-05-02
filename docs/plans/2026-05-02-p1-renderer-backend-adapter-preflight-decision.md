# P1 Renderer backend-adapter preflight decision

日期：2026-05-02

状态：docs-only decision

## Current Facts

- `P1 internal Renderer packet handoff boundary bundle implementation` 已完成。
- 新 owner file 是 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_handoff.cj`。
- 当前 endpoint 是 `CjguiInternalRendererPacketHandoffReceipt` / `cjguiInternalExecuteDefaultRendererPacketHandoffDraft()`。
- Renderer packet handoff 只消费 `CjguiInternalRenderBatchingPacket`。
- Handoff receipt 只是 future renderer adapter 的前置 handoff value facts。
- 它不是 backend adapter、command buffer、render execution、draw-call merge、GPU batching 或 renderer state write。
- 当前没有 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer。
- 当前没有 render side effect，没有 Widget / Layout / Text / IME / Accessibility / ECS implementation。
- 当前没有 dirty-region、diff、patch 或 incremental render。
- public symbol allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- `runtime_state.cj` 未修改且仍为 10065 行 critical warning，本轮不得触碰。

## Decision

选择 B：`P1 internal Renderer backend-adapter preflight decision`。

Renderer packet handoff 已经让 `CjguiInternalRenderBatchingPacket` 退出 material / batching owner，进入 downstream handoff owner。下一步自然应评估 future backend adapter 的第一道边界，但当前还不能直接写 backend adapter value boundary implementation。原因是 adapter 术语容易被误读成真实 platform backend、native handle、command buffer 或 render execution；必须先用 docs-only preflight 固定 owner / truth / platform stop-line / no-render readiness。

本 decision 不批准 backend code、Metal / AppKit 接入、CAMetalLayer、command buffer、GPU device、pipeline state、draw-call merge 或 render side effect。它只批准下一轮做 backend-adapter preflight。

## Candidate Comparison

- A. Renderer packet handoff manifest stabilization：暂缓。handoff closure 已经记录 owner / truth / stop-line，现阶段没有明显 manifest drift；若立刻再做 manifest，收益偏低。
- B. Renderer backend-adapter preflight：选择。它是 handoff receipt 后的自然下一步，但仍是 docs-only，用来回答 backend-adapter 第一刀是否能做 value facts，以及 owner / platform stop-line 如何固定。
- C. Backend adapter value boundary implementation：暂缓。它需要先由 preflight 明确 backend owner、platform bridge 禁区、native handle 禁区和 no-render readiness，否则 implementation 容易越线。
- D. Metal adapter implementation：拒绝。当前 handoff receipt 不是 Metal permission，也不是 CAMetalLayer 或 command buffer permission。
- E. AppKit / CAMetalLayer bridge：拒绝。当前不接 platform object，也不建立 native bridge。
- F. command buffer / render execution：拒绝。当前没有 render side effect，也不创建 GPU command buffer。
- G. real draw op semantics / GPU batching：拒绝。当前 command kind、batch key、batching plan 都是 placeholder / hint / dehydrated facts，不是真实 draw op 或 GPU batching。
- H. Widget / Layout / Text / IME / Accessibility：暂缓。Scene / Renderer runway 仍在 renderer input / command / handoff contract 层。
- I. Dirty region / incremental render：暂缓。P1 仍固定 full DisplayList / command list / batching packet rebuild only。
- J. runtime / queue / action integration：暂缓。当前 renderer path 不读取 Queue / Action / Runtime lower-level mutable facts，也不得靠近 `runtime_state.cj`。
- K. public surface expansion：拒绝。public shell milestone 已封账，allowlist 不扩第二个 public symbol。

## Backend-Adapter Preflight Scope

下一轮 preflight 应回答：

- backend-adapter truth 是否应由新 owner file `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_adapter.cj` 持有。
- 第一刀是否只消费 `CjguiInternalRendererPacketHandoffReceipt`。
- 第一刀是否只表达 `backend adapter candidate` / `backend capability placeholder` / `adapter admission` / `no-render readiness` value facts。
- 是否继续禁止真实 backend adapter implementation、platform bridge、render execution 和 renderer state write。
- 是否继续禁止 Metal / AppKit / CAMetalLayer / command buffer / GPU device / pipeline state。
- 是否继续禁止 native handle / raw pointer / platform object intake。
- 是否继续禁止 real draw-call merge、GPU batching、dirty-region / diff / patch、Widget / Layout / Text / IME / Accessibility。
- 是否继续禁止 public API expansion 和第二个 public symbol。
- 如何验证没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、native bridge、smoke tracked source 或 public surface。

## Stop-line

下一轮仍不得：

- 新增 runtime code，除非 preflight 后另有明确 implementation opening。
- 接 Metal / AppKit / Objective-C / backend / platform object。
- 接 native handle / raw pointer / CAMetalLayer / command buffer。
- 创建 GPU device、pipeline state、render pass 或 command buffer。
- render 或实现真实 draw op semantics。
- 实现真实 draw-call merge / GPU batching / batch scheduler。
- 实现 Widget / Layout / Text / IME / Accessibility。
- 实现 dirty-region / repaint boundary / diff / patch。
- 实现 ECS engine。
- 读取 Queue / Action / Runtime lower-level mutable facts。
- 修改 `runtime_state.cj`。
- 修改 `runtime/cjgui/cjpm.toml`。
- 扩 public surface 或新增第二个 public symbol。

## Public Surface

public symbol allowlist 继续保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 decision 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Opening

`P1 internal Renderer backend-adapter preflight decision`
