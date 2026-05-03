# P1 Renderer real local debug output preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Context

当前 renderer diagnostics local debug output admission endpoint 已由 manifest 封账：

- [2026-05-03-p1-renderer-local-debug-output-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-debug-output-admission-manifest.md)
- [2026-05-03-p1-internal-renderer-local-debug-output-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-debug-output-admission-manifest-stabilization-closure-review.md)

Canonical upstream endpoint：

- `CjguiInternalRendererNoWriteLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft()`

该 endpoint 只表示 local debug output intent / output target policy / opt-in admission / redaction readiness / no-write local output readiness value facts。它不是 real local debug output permission，不是真实 logging、file / stdout / stderr sink、telemetry、observer callback、event bus、public diagnostics、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮问题：是否可以从 no-write local debug output admission 进入 real local debug output runway 的第一步。注意：本轮只做 preflight，不批准真实 local debug 输出、文件写入或控制台输出。

## Preflight Conclusion

允许打开 real local debug output runway，但下一步也只能是 internal value boundary，不是真实输出。

下一步默认 owner：

- `runtime/cjgui/src/runtime_renderer_diagnostics_real_local_output.cj`

唯一输入：

- `CjguiInternalRendererNoWriteLocalOutputReadiness`

下一步输出 truth 只能是：

- real local output intent value facts。
- local target admission value facts。
- opt-in enforcement policy value facts。
- redaction enforcement policy value facts。
- no-op local output readiness value facts。

这些 facts 只能描述 future real local debug output 的 owner vocabulary、target admission、opt-in enforcement、redaction enforcement 与 no-op readiness。它们不得写日志、不得写文件、不得输出 stdout / stderr、不得触发 telemetry、不得调用 observer、不得发 event bus、不得创建 public diagnostics、不得保留 external artifact，也不得接 backend / command buffer / renderer state / render failure callback。

## Guardrails

### Output Permission

默认不允许任何真实输出：

- no file output。
- no stdout output。
- no stderr output。
- no logging subsystem。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no external artifact retention。
- no diagnostics export。

### Payload Boundary

默认不允许 raw payload collection。

下一步只允许处理：

- dehydrated diagnostic facts。
- diagnostic severity facts。
- retention hint facts。

不得输出 serialized payload，不得保留 external artifact，不得创建 local file artifact。

### Debug-only / Local-only

`debug-only` 与 `local-only` 只能作为 value fact / policy label 出现。

它们不是 runtime flag，不是 global switch，不是 local file permission，不是 stdout / stderr permission，也不是真实 logging permission。

### Privacy / Lifecycle / Thread-safety / Artifact Stop-line

下一步如果实现 no-op value boundary，必须继续只表达：

- opt-in enforcement policy facts。
- redaction enforcement policy facts。
- privacy-safe payload boundary facts。
- lifecycle guard facts。
- thread-safety guard facts。
- artifact policy facts。
- sampling guard facts。
- retention guard facts。
- backpressure guard facts。
- failure rollback guard facts。

这些都只能是 internal value facts，不得触发真实 output side effect。

### Canonical Endpoint Protection

`CjguiInternalRendererNoWriteLocalOutputReadiness` 仍必须保持 no-write canonical upstream endpoint。不能把它误判为真实 debug output permission、logging readiness、file sink readiness、stdout / stderr readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness 或 artifact export readiness。

## Candidate Comparison

### A. P1 internal Renderer real local debug output no-op boundary bundle implementation

选择。

下一步只消费 `CjguiInternalRendererNoWriteLocalOutputReadiness`，输出 real local output intent / local target admission / opt-in enforcement policy / redaction enforcement policy / no-op local output readiness value facts。

选择理由：

- 它新增的是 local target admission、opt-in enforcement、redaction enforcement 与 no-op local output readiness 语义。
- 它不是 local output admission tail wrapper。
- 它继续禁止真实 logging / output / file / stdout / stderr / telemetry / observer / event bus / public diagnostics。
- 它能在靠近真实 output 前先固定安全词汇、payload 边界、debug-only / local-only label、artifact / lifecycle / thread-safety stop-line。

### B. Milestone / manifest stabilization

暂不选择。

No-write local output admission manifest 已封账，没有发现 manifest drift 或 preflight blocker。

### C. Real local debug output implementation

拒绝。

当前只能进入 no-op value boundary，不允许真实 local debug output、logging、文件写入或控制台输出。

### D. File / stdout / stderr sink

拒绝。

当前不批准 file sink、stdout sink 或 stderr sink。

### E. Telemetry / observer callback / event bus / public diagnostics

拒绝。

这些属于真实发布 / 输出 / 外部观察路径，当前阶段过早。

### F. Artifact retention / external diagnostics export

拒绝。

当前不保留 external artifact，不导出 diagnostics，不输出 serialized payload。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics local debug output runway 不接 backend handler、command buffer、renderer state write 或 render failure callback，也不是 render permission。

### H. Diagnostics consolidation

暂缓。

只有发现明确 duplicate、low-value helper 或 self-wrapping evidence 时才选择。当前 manifest 与 preflight 未发现该 blocker。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些不属于 diagnostics real local debug output preflight 的当前 downstream。

### J. Public surface expansion

拒绝。

public allowlist 不变，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮继续生效：

- 不允许把 `CjguiInternalRendererNoWriteLocalOutputReadiness` 包成 real-local-output receipt / record / publication。
- 若选择 A，下一步必须证明新增的是 local target admission / opt-in enforcement / redaction enforcement / no-op local output readiness 语义。
- 下一步不得新增 real-local-output receipt / record / publication。
- 继续禁止直接实现真实 local debug output。

## Decision

最终选择：

`P1 internal Renderer real local debug output no-op boundary bundle implementation`

下一轮默认 write set：

- 新建 `runtime/cjgui/src/runtime_renderer_diagnostics_real_local_output.cj`
- 只消费 `CjguiInternalRendererNoWriteLocalOutputReadiness`
- 只输出 internal real local debug output no-op value facts
- 更新 `README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、relevant manifest 与 closure
- 不回塞 `runtime_renderer_diagnostics_local_output.cj`
- 不触碰 `runtime_state.cj`

下一轮仍不得实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / external artifact retention，不得接 backend / command buffer / renderer state / render failure callback。

## Final Next Opening

`P1 internal Renderer real local debug output no-op boundary bundle implementation`
