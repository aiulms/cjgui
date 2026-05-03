# P1 internal Renderer local debug output preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Context

上一轮已完成 `P1 internal Renderer local debug sink policy manifest stabilization bundle implementation`。当前 canonical endpoint：

- `CjguiInternalRendererNoOutputDebugReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft()`

当前 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_debug.cj`

该 endpoint 只表达 internal local debug sink intent / debug channel policy / opt-in guard / redaction policy / no-output debug readiness value facts。

它不是 local-output receipt / record / publication、real logging、real local debug output、file / stdout / stderr sink、telemetry、observer callback、event bus、public diagnostics、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮只做 docs-only preflight，不修改 `.cj`，不运行 build / smoke，不批准真实 local debug 输出、文件写入、控制台输出、event publication、telemetry 或 observer callback。

## Preflight Assessment

允许打开 local debug output runway，但下一步也只能是 internal value boundary，不是真实 output implementation。

理由：

- No-output local debug endpoint 已由 manifest 封账，当前 downstream 可以评估 local debug output admission vocabulary。
- Local debug output admission 可以新增不可替代语义：output target policy、opt-in admission、redaction readiness、no-write output readiness。
- 这些语义不是 `CjguiInternalRendererNoOutputDebugReadiness` 的 receipt / record / publication 包装。
- 下一步仍只消费 no-output endpoint，不读取 Queue / Action / Runtime lower-level mutable facts。
- 下一步不允许真实文件、stdout、stderr、telemetry、observer callback、event bus、public diagnostics 或 external artifact retention。

下一步建议 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`

下一步唯一输入：

- `CjguiInternalRendererNoOutputDebugReadiness`

下一步允许输出的 truth：

- local debug output intent value facts。
- output target policy value facts。
- opt-in admission value facts。
- redaction readiness value facts。
- no-write output readiness value facts。

## Output Runway Stop-line

下一阶段仍必须保持：

- no real local debug output。
- no file output。
- no stdout / stderr output。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no external artifact retention。
- no external diagnostics export。
- no raw payload collection。
- no serialized payload output。
- no logging subsystem。
- no exception system / public error API。
- no backend handler / render failure callback。
- no backend packet / backend submission。
- no command buffer。
- no renderer state write。
- no render permission。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `.cj` edits in this preflight round。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

允许 debug-only / local-only 只作为 value fact / policy label 存在。它们不得解释为真实输出许可、文件写入许可、控制台输出许可、artifact retention 许可或 public diagnostics 许可。

允许处理的事实口径只限 dehydrated diagnostic facts / severity / retention hint；默认不允许 raw payload。

必须继续保持 `CjguiInternalRendererNoOutputDebugReadiness` 的 no-output canonical endpoint 语义，避免误判为真实 debug output permission。

## Boundary Vocabulary

如果下一轮进入 implementation，local debug output admission boundary 应表达：

- `local debug output intent`：future local debug output runway 的内部意图事实，不是 output sink。
- `output target policy`：future local debug output target 的 policy label，不是 target implementation。
- `opt-in admission`：future opt-in admission 的 value fact，不读取设置、不写 runtime state。
- `redaction readiness`：future redaction readiness 的 value fact，只面向 dehydrated diagnostic facts。
- `no-write output readiness`：只表示 local debug output admission boundary 可继续评估，不代表真实 debug logging permission。

需要继续表达的风险边界：

- opt-in：只作为 policy fact，不读取设置、不启用输出。
- redaction：只作为 readiness fact，不执行输出前序列化。
- privacy：默认不收集 raw payload，不输出 serialized payload。
- lifecycle：不注册 sink，不创建持久 owner，不绑定 callback。
- thread-safety：不创建 mutable sink state，不引入 module-level mutable state。
- artifact policy：不保留 external artifact，不写 local file。
- debug-only / local-only：只作为 policy label，不允许真实输出。
- sampling / retention：只作为 future policy vocabulary，不执行采样或保留。
- backpressure：只作为 future constraint vocabulary，不接真实 queue / drain。
- failure rollback：只作为 future safety vocabulary，不接真实 write failure handler。

## Candidate Comparison

### A. P1 internal Renderer local debug output admission value boundary bundle implementation

选择。

理由：

- 它只消费 `CjguiInternalRendererNoOutputDebugReadiness`。
- 它能新增 local debug output intent / output target policy / opt-in admission / redaction readiness / no-write output readiness 语义。
- 它不是 local-output receipt / record / publication，也不是 local debug policy tail wrapper。
- 它仍不真实 logging / output，不写文件，不打 stdout / stderr，不触发 telemetry、observer callback、event bus 或 public diagnostics。

下一轮默认新增 owner：

- `runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`

### B. Milestone / manifest stabilization

暂缓。

只有发现 no-output local debug manifest drift、owner truth 不清、canonical endpoint 不稳或 preflight blocker 时才选择。当前 local debug manifest 已固定 owner / truth / stop-line，没有 blocker。

### C. Local debug output implementation

拒绝。

真实 local debug output 过早。当前只能定义 internal value-style admission boundary，不能写文件、输出控制台、发布事件、触发 telemetry 或暴露 public diagnostics。

### D. File / stdout / stderr sink

拒绝。

当前不允许 file sink、stdout sink、stderr sink 或任何真实 output channel。

### E. Telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 local debug output preflight 不批准 telemetry、observer callback、event bus、public diagnostics 或外部通知入口。

### F. Artifact retention / external diagnostics export

拒绝。

当前不允许 external artifact retention，不允许 diagnostics export，也不允许 serialized payload output。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics local debug output runway 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Diagnostics consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper evidence 时才选择。当前 evidence 指向新增 local debug output admission vocabulary，而不是 cleanup。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics local debug output preflight。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

本轮明确禁止把 `CjguiInternalRendererNoOutputDebugReadiness` 包成：

- local-output receipt。
- local-output record。
- local-output publication。
- debug logging readiness wrapper。
- file sink readiness wrapper。
- stdout / stderr readiness wrapper。
- public diagnostics readiness wrapper。

选择 A 的理由不是“继续尾巴”，而是 local debug output admission boundary 有新增语义：

- output target policy。
- opt-in admission。
- redaction readiness。
- no-write output readiness。

这些语义为未来 local debug output runway 提前固定 opt-in / redaction / privacy / lifecycle / artifact / local-only stop-line，但仍不实现真实输出。

## Decision

最终选择：

`P1 internal Renderer local debug output admission value boundary bundle implementation`

下一轮允许新增一个 internal-only runtime owner file，但必须严格保持 no-write / no-output 边界。

默认 owner / write set：

- 新建 `runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`
- 只消费 `CjguiInternalRendererNoOutputDebugReadiness`
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant diagnostics manifest / closure
- 不回塞 `runtime_renderer_diagnostics_local_debug.cj`
- 不触碰 `runtime_state.cj`

## Stop-line

下一轮继续禁止：

- no real logging / local debug output implementation。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file / stdout / stderr output。
- no external artifact retention。
- no external diagnostics export。
- no raw payload collection。
- no serialized payload output。
- no backend handler / render failure callback。
- no backend packet / backend submission。
- no command buffer。
- no renderer state write。
- no render permission。
- no Metal / AppKit / backend implementation。
- no native handle / raw pointer / platform object。
- no sorting side effect。
- no draw-call merge / GPU batching。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Verification Plan

本 docs-only preflight 的验证口径：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 可以找到本 preflight 与 next opening。
- forbidden check：确认没有 `.cj` runtime code diff，未触碰 protected paths。
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)` 记录 risk 与 affected processes。
- 不运行 `cjpm build` / smoke。
