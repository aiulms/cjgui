# P1 Renderer real local debug output no-op manifest

日期：2026-05-03

状态：docs-only manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_diagnostics_real_local_output.cj` 的 owner / truth / canonical endpoint / stop-line，封账当前 no-op real local debug output endpoint。

它不是 logging manifest、debug output manifest、file sink manifest、stdout / stderr sink manifest、telemetry manifest、observer callback manifest、event bus manifest、public diagnostics manifest、artifact export manifest 或 backend diagnostics manifest。它只记录 renderer diagnostics value pipeline 内部的 real local output intent、local target admission、opt-in enforcement policy、redaction enforcement policy 与 no-op local output readiness value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_real_local_output.cj`

Canonical endpoint：

- `CjguiInternalRendererNoOpLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

Current truth：

- internal real local output intent facts。
- internal local target admission facts。
- internal opt-in enforcement policy facts。
- internal redaction enforcement policy facts。
- no-op local output readiness value facts。

该 truth 只表示 future real local debug output runway 可以在后续 docs-only preflight 中继续评估。它不表示真实 logging、debug output、file / stdout / stderr sink、telemetry、observer callback、event bus、public diagnostics、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

## Upstream Facts

当前 real local debug output no-op owner 只消费：

- `CjguiInternalRendererNoWriteLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft()`

允许继续描述的事实口径只限：

- dehydrated diagnostic facts。
- diagnostic severity facts。
- retention hint facts。

当前不收集 raw payload，不输出 serialized payload，不承诺 external artifact retention，不执行 local file output，也不读取 Queue / Action / Runtime lower-level mutable facts。

## Current Pipeline

当前 pipeline：

1. `CjguiInternalRendererNoWriteLocalOutputReadiness`
2. `CjguiInternalRendererRealLocalOutputIntent`
3. `CjguiInternalRendererLocalTargetAdmission`
4. `CjguiInternalRendererOptInEnforcementPolicy`
5. `CjguiInternalRendererRedactionEnforcementPolicy`
6. `CjguiInternalRendererNoOpLocalOutputReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

Default draft 只生成 internal value facts。它不写文件、不打 stdout / stderr、不发事件、不写日志、不触发 telemetry、不调用 observer、不创建 public diagnostics、不保留 external artifact、不输出 serialization payload、不写 renderer state，也不触发 backend 或 render callback。

## No-op Local Output Readiness

`CjguiInternalRendererNoOpLocalOutputReadiness` 是当前 canonical no-op real local debug output endpoint。

它明确不是：

- real-local-output receipt / record / publication。
- real logging。
- real debug output。
- file sink。
- stdout sink。
- stderr sink。
- telemetry。
- observer callback。
- event bus。
- public diagnostics。
- artifact retention。
- external diagnostics export。
- backend handler。
- command buffer。
- renderer state write。
- render failure callback。
- render permission。

No-op local output readiness 的含义只有一个：future real local debug output runway 可以在后续 docs-only preflight 中继续评估。它不是 output permission、logging readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、file sink readiness、artifact export readiness 或 serialized payload readiness。

## Same-shape Boundary Brake

本轮选择 manifest 封账，而不是继续新增 real-local-output tail。

明确拒绝：

- real-local-output receipt。
- real-local-output record。
- real-local-output publication。
- debug logging readiness wrapper。
- file sink readiness wrapper。
- stdout / stderr readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- artifact export readiness wrapper。

`CjguiInternalRendererNoOpLocalOutputReadiness` 已经足够作为当前 no-op local output endpoint。继续包装成 receipt / record / publication 会回到 same-shape thin wrapper，没有新增 owner truth、consumer、integration 或风险证据。

如果未来靠近真实 local debug output / logging sink，必须先做 docs-only preflight，评估 opt-in、redaction、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary、local-only boundary、sampling、retention、backpressure 与 failure rollback stop-line。不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / external artifact retention。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` edits。
- no logging subsystem。
- no real debug output。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file / stdout / stderr output。
- no external artifact retention。
- no external diagnostics export。
- no raw payload collection。
- no serialized payload output。
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

## Candidate Comparison

### A. P1 internal Renderer local diagnostics pipeline milestone stabilization bundle implementation

选择为下一阶段 opening。

理由：

- Diagnostics no-output / no-op runway 已经形成较长链路：diagnostics policy -> sink policy -> output admission -> write admission -> real-write no-op -> local debug policy -> local output admission -> real local output no-op。
- Milestone stabilization 可以一次性固定整条 no-output runway 的 owner chain、canonical tail、truth 与 stop-line，避免继续在尾部新增同构 value wrapper。
- 该候选仍是 docs / manifest stabilization，不实现真实 local debug output、logging sink、telemetry、observer callback、event bus、public diagnostics 或 file sink。

### B. Real local debug output implementation preflight

暂缓。

当前 runway 已经足够长，先做 milestone 更稳。未来若靠近真实 output / logging sink，仍必须先 docs-only preflight，不能直接 implementation。

### C. No-op local output hardening

暂缓。

只有发现 local target admission、opt-in enforcement、redaction enforcement、no-op readiness、manifest wording 或 stop-line 表达不足时才选择。当前 manifest 已固定 canonical endpoint 与 no-op stop-line，没有 hardening blocker。

### D. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前本轮是 manifest stabilization，没有直接 cleanup blocker。

### E. Real-local-output receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。

### F. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 no-op local output endpoint 不允许真实输出、发布、遥测、回调、event bus 或公开诊断。

### G. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留 external artifact。未来若评估真实 local debug output，也必须先 docs-only preflight。

### H. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics local debug output no-op endpoint 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics local debug output no-op manifest closure。

### J. Public surface expansion

拒绝。

Public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer local diagnostics pipeline milestone stabilization bundle implementation`

下一轮必须是 docs / manifest stabilization。它总结并封账 diagnostics policy -> sink policy -> output admission -> write / no-op -> local debug / no-op 的整条 no-output runway；不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write、render failure callback 或 render permission。

## Pipeline Milestone Status

Renderer local diagnostics no-output / no-op pipeline milestone 已完成：

- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md)

Milestone 固定当前 canonical tail：`CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`。后续 reopening 必须从 docs-only preflight 或 duplicate audit 开始；不得直接新增 real-local-output receipt / record / publication、真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink 或 external artifact retention。
