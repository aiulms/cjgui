# P1 Renderer real local debug output no-op next-boundary decision

日期：2026-05-03

状态：docs-only decision

## Context

上一轮新增 `runtime_renderer_diagnostics_real_local_output.cj`，当前 canonical endpoint 是：

- `CjguiInternalRendererNoOpLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

该 endpoint 只表达 internal real local debug output no-op value facts：real local output intent、local target admission、opt-in enforcement policy、redaction enforcement policy 与 no-op local output readiness。它不是 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Endpoint Assessment

`CjguiInternalRendererNoOpLocalOutputReadiness` 已经足够作为当前 no-op local output endpoint：

- 它固定了 local target admission 语义，且没有绑定 output target implementation。
- 它固定了 opt-in enforcement policy 语义，且没有引入 runtime flag / global switch。
- 它固定了 redaction enforcement policy 语义，且只允许 dehydrated diagnostic facts / severity / retention hint。
- 它固定了 no-op local output readiness 语义，明确不代表真实 local debug output 或 write permission。

因此下一步应先做 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line，而不是继续新增同构尾巴。

## Candidate Comparison

### A. P1 internal Renderer real local debug output no-op manifest stabilization bundle implementation

选择。

理由：

- 当前 endpoint 已完整表达 real local output no-op runway 的 owner truth。
- Manifest stabilization 可以固定 `runtime_renderer_diagnostics_real_local_output.cj` 的 owner / truth / canonical endpoint / stop-line。
- 这能防止后续把 no-op endpoint 继续包装成 receipt / record / publication。
- 该候选仍是 docs-only，不靠近真实 logging、telemetry、observer callback、event bus、public diagnostics、file sink 或 output sink implementation。

### B. Real local debug sink/output implementation preflight

暂缓到 manifest 之后。

如果未来要靠近真实 local debug output / logging sink，必须先做 docs-only preflight，评估 opt-in、redaction、privacy、lifecycle、thread-safety、artifact policy、debug-only / local-only、sampling、retention、backpressure 与 failure rollback stop-line。当前不应跳过 manifest 直接评估实现 runway。

### C. No-op local output hardening

暂缓。

只有发现 local target admission、opt-in enforcement、redaction enforcement、no-op readiness 或 stop-line 表达不足时才选择。当前 closure 已说明这些 value facts 足够，未发现 hardening blocker。

### D. Real-local-output receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确阻止的 thin wrapper 路径。它不会新增 owner truth、consumer、gate 或 risk evidence。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 endpoint 不允许真实输出、发布、遥测、回调、事件总线或公开诊断。

### F. File / stdout / stderr / artifact sink

拒绝。

当前 no-op endpoint 不写文件、不打 stdout / stderr、不保留 external artifact，也不输出 serialized payload。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics local output runway 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Consolidation

暂缓。

只有发现明确 duplicate projection、low-value helper、self-wrapping evidence 或 dead helper 时才选择。当前本轮是 endpoint decision，未发现需要 cleanup 的 blocker。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics real local output no-op endpoint closure。

### J. Public surface expansion

拒绝。

Public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

`CjguiInternalRendererNoOpLocalOutputReadiness` 已经是当前 no-op local output endpoint。本轮不批准新增 real-local-output receipt / record / publication。

如果未来靠近真实 local debug output / logging sink，必须先做 docs-only preflight，不能直接实现。Preflight 之前也不能把 no-op readiness 解释成 logging readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、file sink readiness 或 artifact export readiness。

## Decision

最终选择：

`P1 internal Renderer real local debug output no-op manifest stabilization bundle implementation`

下一轮必须 docs-only / manifest stabilization，固定：

- owner file：`runtime/cjgui/src/runtime_renderer_diagnostics_real_local_output.cj`
- canonical endpoint：`CjguiInternalRendererNoOpLocalOutputReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`
- current truth：real local output intent / local target admission / opt-in enforcement policy / redaction enforcement policy / no-op local output readiness value facts
- stop-line：不实现真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission

## Next Opening

`P1 internal Renderer real local debug output no-op manifest stabilization bundle implementation`
