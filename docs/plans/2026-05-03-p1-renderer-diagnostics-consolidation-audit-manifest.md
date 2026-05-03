# P1 Renderer diagnostics consolidation audit manifest

日期：2026-05-03

状态：docs-only audit manifest stabilization

## Purpose

本 manifest 固定 [diagnostics consolidation audit decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-consolidation-audit-decision.md) 的结论：当前 Renderer diagnostics no-output / no-op local pipeline 没有明确可直接删除、合并或重命名的 diagnostics runtime owner。

它不是代码 consolidation plan，不授权删除 owner，不授权合并 owner，不授权重命名 owner，也不授权真实 diagnostics output。它只把当前 audit truth、canonical tail、Same-shape Boundary Brake、命名误读风险和 reopening 条件封成 manifest。

## Audit Conclusion

当前没有明确可直接删除、合并或重命名的 diagnostics runtime owner。

本轮 audit 发现的是 runway 长度和命名误读风险，而不是强代码重复证据。9 个 owner 的 shape 高度相似，但它们的 manifest truth 仍分别固定不同语义，当前不满足 targeted consolidation 的证据门槛。

未发现 `Receipt` / `Record` / `Publication` 型 diagnostics owner 回潮。源码里存在 `didAvoidDiagnosticPublication` 这类 stop-line facts，但它们表达的是避免 external / public publication，不是 publication owner。

## Current Owner / Endpoint Chain

当前 9 个 owner / endpoint 仍分别代表不同语义：

1. diagnostics result：`CjguiInternalRendererPacketDiagnosticsResult`
2. diagnostics policy：`CjguiInternalRendererDiagnosticsPolicyResult`
3. sink policy：`CjguiInternalRendererDiagnosticsNoOutputReadiness`
4. output admission：`CjguiInternalRendererDiagnosticsNoWriteReadiness`
5. write admission：`CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
6. real write no-op：`CjguiInternalRendererDiagnosticsNoOpWriteReadiness`
7. local debug sink policy：`CjguiInternalRendererNoOutputDebugReadiness`
8. local output admission：`CjguiInternalRendererNoWriteLocalOutputReadiness`
9. real local no-op：`CjguiInternalRendererNoOpLocalOutputReadiness`

Owner file chain：

1. `runtime/cjgui/src/runtime_renderer_packet_diagnostics.cj`
2. `runtime/cjgui/src/runtime_renderer_diagnostics_policy.cj`
3. `runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`
4. `runtime/cjgui/src/runtime_renderer_diagnostics_output.cj`
5. `runtime/cjgui/src/runtime_renderer_diagnostics_write_sink.cj`
6. `runtime/cjgui/src/runtime_renderer_diagnostics_real_write.cj`
7. `runtime/cjgui/src/runtime_renderer_diagnostics_local_debug.cj`
8. `runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`
9. `runtime/cjgui/src/runtime_renderer_diagnostics_real_local_output.cj`

## Canonical Tail

Current canonical tail endpoint：

- `CjguiInternalRendererNoOpLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

该 endpoint 只表示 diagnostics no-op local output value pipeline 已到当前 tail，可供后续 docs-only decision 重新评估。它不是 logging permission、output permission、write permission、debug output permission、file sink readiness、stdout / stderr readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、backend readiness 或 render readiness。

## Current Truth

当前 truth 只包括 internal diagnostics value facts：

- diagnostics summary / severity / evidence facts。
- diagnostics policy / severity handling / retention hint facts。
- sink intent / privacy guard / lifecycle guard facts。
- output channel policy / privacy admission / artifact guard facts。
- write channel admission / privacy-safe payload / local-only artifact facts。
- real-write sink target policy / write safety gate / privacy-safe serialization facts。
- local debug channel policy / opt-in guard / redaction policy facts。
- local output target policy / opt-in admission / redaction readiness facts。
- real local target admission / opt-in enforcement / redaction enforcement facts。
- no-output / no-write / no-side-effect / no-op readiness facts。

这些 facts 只允许 dehydrated diagnostic facts、diagnostic severity facts 与 retention hint facts。当前不收集 raw payload，不输出 serialized payload，不保留 external artifact，不执行 local file output，不读取 Queue / Action / Runtime lower-level mutable facts。

## Naming Misread Risk

当前主要风险不是已存在的代码重复，而是 pipeline runway 较长，且多个 endpoint 使用 `Readiness` / `NoOutput` / `NoWrite` / `NoOp` 命名。

这些命名可能被误读成真实 output permission：

- `Readiness` 不是 permission。
- `NoOutput` 不是 future output 已批准。
- `NoWrite` 不是 write sink 已准备好。
- `NoSideEffect` 不是 side-effect policy implementation。
- `NoOp` 不是真实 no-op logger 或 output sink。

因此后续文档需要补强 stop-line 解释，避免执行 AI 把 diagnostics readiness 当成 logging sink、file sink、telemetry、observer callback、event bus 或 public diagnostics 的实现许可。

## Not This

本 manifest 明确这些 endpoint 都不是：

- logging。
- telemetry。
- observer callback。
- event bus。
- public diagnostics。
- file sink。
- stdout sink。
- stderr sink。
- artifact retention。
- external diagnostics export。
- backend handler。
- backend packet。
- command buffer。
- renderer state write。
- render failure callback。
- render permission。
- exception system / public error API。
- public API / public C ABI expansion。

## Same-shape Boundary Brake

本轮选择 audit manifest 封账。

Same-shape Boundary Brake 生效点：没有具体 evidence 时，不新增 receipt / record / publication / readiness wrapper，不把 `CjguiInternalRendererNoOpLocalOutputReadiness` 再包装成另一个 tail endpoint。

未来若要开 targeted consolidation，必须先有具体 evidence：

- duplicate fields。
- duplicate builders。
- low-value owner。
- self-wrapping owner。
- manifest drift。
- build-level dead code evidence。

没有这些 evidence 时，不进入代码 consolidation，不删除 runtime owner，不合并 runtime owner，不重命名 runtime owner。

未来若要靠近真实 output，必须重新做 docs-only preflight，并提供：

- privacy evidence。
- opt-in evidence。
- redaction evidence。
- lifecycle evidence。
- thread-safety evidence。
- artifact policy evidence。
- retention evidence。
- backpressure / rate-limit evidence。
- failure rollback evidence。

没有这些 evidence 时，不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / artifact retention。

## Candidate Comparison

### A. P1 internal Renderer diagnostics stop-line hardening docs bundle implementation

选择为下一阶段 opening。

理由：

- Audit manifest 已固定当前没有明确可删 / 可合并 owner。
- 当前真实风险是命名误读，而不是代码重复。
- Stop-line hardening 可以专门补强 `Readiness` / `NoOutput` / `NoWrite` / `NoOp` 的解释，降低后续执行 AI 误把 diagnostics readiness 当成真实输出许可的概率。
- 该候选仍是 docs-only，不改 runtime code。

### B. Targeted consolidation preflight

暂缓。

当前没有 duplicate fields、duplicate builders、low-value owner、self-wrapping owner、manifest drift 或 build-level dead code evidence；不满足 targeted consolidation preflight 的证据门槛。

### C. Real local diagnostics output preflight

暂缓。

先完成 stop-line hardening，再评估是否需要靠近真实 output runway。

### D. Return to renderer command / backend non-diagnostics track decision

保留为后续备选。

本轮先完成 diagnostics hardening，后续可再评估是否回到 renderer command / backend 非 diagnostics track。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 audit manifest 不批准真实输出、遥测、回调、event bus 或公开诊断。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留 external artifact。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics pipeline 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些不属于 diagnostics consolidation audit manifest 的下游。

### I. Public surface expansion

拒绝。

Public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics stop-line hardening docs bundle implementation`

下一轮必须 docs-only。它应补强 diagnostics no-output / no-write / no-side-effect / no-op 命名解释，明确 readiness 不是 output permission、logging permission、file sink permission、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、backend readiness 或 render permission。

## Downstream Stop-line Hardening

`P1 internal Renderer diagnostics stop-line hardening docs bundle implementation` 已由 [2026-05-03-p1-renderer-diagnostics-stop-line-hardening.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-stop-line-hardening.md) 与 [2026-05-03-p1-internal-renderer-diagnostics-stop-line-hardening-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-diagnostics-stop-line-hardening-closure-review.md) 完成。

Hardening 结论：`Readiness` 不是 permission；`NoOutput` / `NoWrite` / `NoSideEffect` / `NoOp` 只表示 internal value facts / stop-line；`Sink` / `Output` / `Write` / `Real` / `LocalDebug` 只是 runway vocabulary，不是 implementation permission。

新的 next opening 是：

`P1 internal Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision`
