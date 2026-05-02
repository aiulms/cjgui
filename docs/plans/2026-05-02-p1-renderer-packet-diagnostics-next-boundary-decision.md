# P1 Renderer packet diagnostics next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

上一轮已完成 `P1 internal Renderer packet diagnostics boundary bundle implementation`。

当前 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_packet_diagnostics.cj`

当前 canonical endpoint：

- `CjguiInternalRendererPacketDiagnosticsResult`
- `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`

当前 truth：

- internal diagnostics summary facts。
- diagnostic severity facts。
- diagnostic evidence facts。
- diagnostics result facts。

它只消费 `CjguiInternalRendererPacketErrorTaxonomyResult`，不是 public diagnostics、logging subsystem、observer callback、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。

本轮不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Decision Question

Diagnostics endpoint 后，下一步是否继续实现 diagnostics policy / handoff，还是先做 manifest stabilization？

Same-shape Boundary Brake 已生效：不能默认新增 diagnostics receipt / record / publication，也不能把 diagnostics result 解释成日志、telemetry、observer callback 或 public diagnostics。

## Candidate Comparison

### A. P1 internal Renderer packet diagnostics manifest stabilization bundle implementation

选择。

理由：

- `CjguiInternalRendererPacketDiagnosticsResult` 已足够作为当前 diagnostics endpoint。
- Diagnostics boundary 已经新增 summary / severity / evidence 语义；继续追加 receipt / record / publication 会变薄。
- Manifest 可以固定 owner / truth / canonical endpoint / stop-line，防止 diagnostics result 被误解释成 logging、telemetry、observer callback、public diagnostics 或 backend readiness。
- 这是 packet taxonomy -> diagnostics 之后的自然封账动作。

### B. P1 internal Renderer diagnostics policy boundary bundle implementation

暂缓。

理由：

- diagnostics policy / severity handling policy / retention hint 可以是未来候选，但需要先明确 policy 是否拥有独立 owner truth。
- 现在若直接实现 policy，容易把 severity facts 再包装成 policy readiness。
- 若未来选择它，必须保持 internal value facts，不得引入 logging subsystem、telemetry、observer callback、public diagnostics 或 backend error handler。

### C. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

理由：

- 只有找到明确 downstream owner 时才开。
- 当前 diagnostics result 还没有 downstream consumer；直接 handoff 会接近 receipt wrapper。

### D. P1 internal Renderer packet diagnostics consolidation bundle implementation

暂缓。

理由：

- 本轮未发现明确 duplicate projection、low-value helper 或 self-wrapping helper。
- 当前更适合先用 manifest 固定 endpoint 和 stop-line。

### E. Diagnostics receipt / record / publication thin wrapper

拒绝。

这会直接违反 Same-shape Boundary Brake。

### F. Logging subsystem / telemetry / observer callback / public diagnostics

拒绝。

Diagnostics result 只表达 internal value facts，不发布、不记录外部日志、不调用 observer、不开放 public diagnostics。

### G. Backend packet / command buffer / backend submission

拒绝。

Diagnostics result 不是 backend readiness，也不允许生成 backend packet、command buffer 或 backend submission。

### H. Sorting side effect / draw-call merge / GPU batching

拒绝。

Diagnostics owner 不执行排序副作用，不合并 draw call，也不做 GPU batching。

### I. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list rebuild only。

### J. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Diagnostics endpoint 不接平台对象，不持有 native handle，也不是 backend bridge。

### K. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 renderer packet diagnostics endpoint。

### L. Runtime / Queue / Action integration

暂缓。

Diagnostics owner 当前只消费 renderer packet taxonomy result，不读取 Queue / Action / Runtime lower-level mutable facts。

### M. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终选择：

`P1 internal Renderer packet diagnostics manifest stabilization bundle implementation`

下一轮应以 docs / manifest stabilization 为主，新增 diagnostics manifest，固定：

- owner file：`runtime_renderer_packet_diagnostics.cj`。
- upstream fact：`CjguiInternalRendererPacketErrorTaxonomyResult`。
- canonical endpoint：`CjguiInternalRendererPacketDiagnosticsResult` / `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`。
- current truth：internal diagnostics summary / severity / evidence / result value facts。
- stop-line：no public diagnostics、no logging subsystem、no telemetry、no observer callback、no backend error handler、no render failure callback、no backend packet、no command buffer、no renderer state write、no render permission。

## Same-shape Boundary Brake

Brake 在本轮继续生效：

- 不批准 diagnostics receipt。
- 不批准 diagnostics record。
- 不批准 diagnostics publication。
- 不批准 diagnostics logging / telemetry / observer wrapper。
- 不批准 backend readiness wrapper。

下一阶段选择 manifest stabilization，是因为 diagnostics endpoint 已经有足够语义，先封账比继续追加同构 owner 更稳。

## Stop-line

继续保持：

- no runtime code in this decision round。
- no `.cj` edits。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no stable backend API promise。
- no render execution / draw call。
- no real draw op / GPU batching / draw-call merge。
- no sorting side effect。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS。
- no exception system / public error API / logging subsystem / observer callback / telemetry。
- no Queue / Action / Runtime lower-level mutable facts。
- no new public symbol；`cjguiExperimentalQueueSubmitShellReady(): Bool` unchanged。
- no `runtime_state.cj` touch。

## Verification

Required docs-only checks:

- `git diff --check`
- Markdown absolute link missing target check
- README / GUI_TASK_TRACKER / docs/plans README reachability for this decision and next opening
- forbidden check for runtime code, `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke / harness / native bridge / entry, `AGENTS.md`, `CLAUDE.md`, `CANGJIE_ISSUE_LEDGER.md`
- public declaration scan
- GitNexus `detect_changes(scope=unstaged)`

本轮按要求不运行 `cjpm build` 或 smoke guard。

## Next Opening

建议下一步：

`P1 internal Renderer packet diagnostics manifest stabilization bundle implementation`

下一轮应固定 diagnostics owner / truth / canonical endpoint / stop-line，且继续拒绝 diagnostics receipt / record / publication、logging subsystem、telemetry、observer callback、public diagnostics、backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、dirty-region / diff / patch 和 public surface expansion。
