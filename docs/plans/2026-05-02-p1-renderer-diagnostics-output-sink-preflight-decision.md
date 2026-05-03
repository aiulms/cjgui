# P1 Renderer diagnostics output sink preflight decision

日期：2026-05-02

状态：docs-only preflight decision

## Context

Renderer diagnostics sink policy manifest 已完成。

当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

该 endpoint 只表示 no-output sink policy value facts：sink intent、sink policy、privacy guard、lifecycle guard 与 no-output readiness。它不是 logging permission、telemetry readiness、observer callback readiness、event bus readiness、public diagnostics readiness、file sink、stdout / stderr sink、artifact retention、backend handler、command buffer、renderer state write 或 render permission。

本轮只做 docs-only preflight，不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Preflight Questions

### 是否允许打开 output sink runway

允许，但只能先打开 internal value boundary。

下一阶段可以定义 output sink admission value facts，用来描述 future output sink 的 admission runway。它不能实现真实 output，不能写文件，不能打 stdout / stderr，不能接 telemetry、observer callback、event bus、public diagnostics 或 external artifact retention。

### 下一步 owner

推荐新建 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_output.cj`

该 owner 应与 `runtime_renderer_diagnostics_sink.cj` 分离，避免把 no-output sink policy owner 继续扩成 output admission / output policy 混合体。

### 输入

下一阶段只能消费：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`

Default draft 若存在，只能从 `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()` 串起，不得读取 Queue / Action / Runtime lower-level mutable facts。

### 输出 truth

下一阶段只能输出 internal value-style facts：

- diagnostics output sink intent facts。
- output channel policy facts。
- privacy admission facts。
- artifact guard facts。
- no-write readiness facts。

这些 facts 只表示 future output sink runway 可以继续评估。它们不是真实 output sink、logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、backend handler、renderer state write 或 render permission。

### Output stop-line

默认全部不允许：

- file output。
- stdout output。
- stderr output。
- telemetry。
- observer callback。
- event bus。
- public diagnostics。
- external artifact retention。
- backend handler。
- render failure callback。
- command buffer。
- renderer state write。

### Payload policy

默认不允许 raw payload。

下一阶段只能处理 dehydrated diagnostic facts / severity / retention hint。不得收集原始诊断 payload、用户数据、平台对象、native handle、raw pointer 或外部 artifact。

### Debug-only sink

Debug-only sink 只能作为 value fact / policy label 出现。

该 label 不允许触发真实输出，不允许写日志，不允许写文件，不允许 stdout / stderr，不允许 telemetry，不允许 observer callback，也不允许 event bus publication。

### Privacy / lifecycle / thread-safety / artifact / sampling / retention

下一阶段应将这些边界表达为 internal value facts：

- privacy admission：只允许 dehydrated facts，拒绝 raw payload 与外部可识别 artifact。
- lifecycle guard：不创建长期 sink，不持有外部资源，不建立 callback lifecycle。
- thread-safety guard：不引入 shared mutable state，不建立 async output queue，不跨线程发布。
- artifact guard：不写外部 artifact，不保留 external retention。
- sampling guard：只能是 policy label，不执行采样 side effect。
- retention guard：只能表达 no external retention / debug-label-only，不保留实际产物。

这些 guard 仍然不能变成 logging permission、telemetry permission、public diagnostics permission 或 output execution。

### No-output canonical endpoint

必须继续保留 `CjguiInternalRendererDiagnosticsNoOutputReadiness` 的语义。

Output sink admission value boundary 若实施，只能消费 no-output endpoint 并生成 no-write admission facts。它不能把 no-output endpoint 解释为真实 logging permission。

## Candidate Comparison

### A. P1 internal Renderer diagnostics output sink admission value boundary bundle implementation

选择。

理由：

- No-output sink policy endpoint 已由 manifest 封账，下一步可以建立独立 output admission owner。
- 该 owner 能新增 output-channel policy、privacy admission、artifact guard、no-write readiness 语义，不只是 no-output readiness 的 receipt / record 包装。
- 它仍不实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

默认下一轮 write set：

- 新建 `runtime/cjgui/src/runtime_renderer_diagnostics_output.cj`。
- 只消费 `CjguiInternalRendererDiagnosticsNoOutputReadiness`。
- 只输出 internal value-style output sink admission facts。
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant diagnostics manifest / closure。
- 不回塞 `runtime_renderer_diagnostics_sink.cj`。
- 不触碰 `runtime_state.cj`。

### B. Milestone / manifest stabilization

暂缓。

只有发现 no-output sink manifest drift、endpoint 不清或 preflight blocker 时才选择。当前 manifest 已固定 owner / truth / canonical endpoint / stop-line。

### C. Output sink implementation

拒绝。

真实 output sink 过早。本 preflight 只允许打开 value-boundary runway，不批准 implementation。

### D. File / stdout / stderr sink

拒绝。

当前不允许文件、stdout 或 stderr 输出。即便未来评估，也必须先 docs-only preflight。

### E. Telemetry / observer callback / event bus / public diagnostics

拒绝。

这些都会引入真实发布、回调、外部可见诊断或 public surface 风险，当前阶段不允许。

### F. Artifact retention / external diagnostics export

拒绝。

当前不允许 external artifact retention、外部诊断导出或 raw payload 收集。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics output sink runway 不属于 backend / renderer execution，不接 command buffer，不写 renderer state，也不是 render failure callback。

### H. Diagnostics consolidation

暂缓。

只有发现 duplicate projection、low-value helper 或 self-wrapping evidence 时才开。当前没有 consolidation blocker。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics output sink preflight。

### J. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 preflight 继续生效。

不得把 `CjguiInternalRendererDiagnosticsNoOutputReadiness` 包成：

- output receipt。
- output record。
- output publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

选择 A 的前提是下一轮必须新增 output-channel policy / privacy admission / artifact guard / no-write readiness 语义。它不是 sink policy tail wrapper，也不是 no-output readiness 改名。

继续禁止直接实现真实 output sink。

## Stop-line

继续禁止：

- no runtime code in this preflight round。
- no `.cj` edits。
- no logging subsystem implementation。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file / stdout / stderr output。
- no external artifact retention。
- no raw payload collection。
- no exception system / public error API。
- no backend handler / render failure callback。
- no backend packet / backend submission。
- no command buffer。
- no renderer state write。
- no render permission。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice。
- no native handle / raw pointer / platform object。
- no sorting side effect。
- no draw-call merge / GPU batching。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Decision

最终选择：

`P1 internal Renderer diagnostics output sink admission value boundary bundle implementation`

下一轮若执行 implementation，必须保持 internal-only、value-style、no-write / no-output execution boundary。它只批准建立 output sink admission facts，不批准 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

## Verification Plan

本轮 docs-only preflight 验证：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 能找到本 preflight 与 next opening。
- forbidden check 确认没有 `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`。
- 不运行 build / smoke。

