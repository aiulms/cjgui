# P1 Renderer diagnostics write sink admission manifest

日期：2026-05-02

状态：docs-only manifest stabilization

## Purpose

本 manifest 固定 renderer diagnostics write sink admission 的 owner / truth / canonical endpoint / stop-line，封账当前 no-side-effect write admission endpoint。

它不是 logging manifest、telemetry manifest、observer manifest、event bus manifest、public diagnostics manifest、file sink manifest 或 artifact export manifest。它只记录 renderer diagnostics value pipeline 内部的 write sink intent、write channel admission、privacy-safe payload policy、local-only artifact policy 与 no-side-effect write readiness value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_write_sink.cj`

Canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsWriteSinkAdmissionDraft()`

Current truth：

- internal diagnostics write sink intent facts。
- internal diagnostics write channel admission facts。
- internal diagnostics privacy-safe payload policy facts。
- internal diagnostics local-only artifact policy facts。
- no-side-effect write readiness value facts。

该 truth 只表示 future diagnostics write sink admission boundary 可继续评估。它不表示真实 write sink，也不授予 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr output、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

## Upstream Facts

当前 write sink admission owner 只消费：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`

允许透传或引用的事实口径只限：

- dehydrated diagnostic facts。
- diagnostic severity facts。
- retention hint facts。

当前不收集 raw payload，不承诺 external artifact retention，不执行 local file output，也不读取 Queue / Action / Runtime lower-level mutable facts。

## Current Pipeline

当前 pipeline：

1. `CjguiInternalRendererDiagnosticsNoWriteReadiness`
2. `CjguiInternalRendererDiagnosticsWriteSinkIntent`
3. `CjguiInternalRendererDiagnosticsWriteChannelAdmission`
4. `CjguiInternalRendererDiagnosticsPrivacySafePayloadPolicy`
5. `CjguiInternalRendererDiagnosticsLocalOnlyArtifactPolicy`
6. `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererDiagnosticsWriteSinkAdmissionDraft()`

Default draft 只生成 internal value facts。它不写文件、不打 stdout / stderr、不发事件、不写日志、不触发 telemetry、不调用 observer、不创建 public diagnostics、不保留 external artifact、不写 renderer state，也不触发 backend 或 render callback。

## No-side-effect Write Readiness

`CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 是当前 canonical no-side-effect write admission endpoint。

它明确不是：

- real write sink。
- real output sink。
- logging subsystem。
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
- render failure callback。
- backend packet。
- command buffer。
- renderer state write。
- render permission。

No-side-effect write readiness 的含义只有一个：future diagnostics real write sink runway 可以在后续 docs-only preflight 中继续评估。它不是 output permission、write permission、logging readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、file sink readiness 或 artifact export readiness。

## Same-shape Boundary Brake

本轮选择 manifest 封账，而不是继续新增 write admission tail。

明确拒绝：

- write receipt。
- write record。
- write publication。
- output readiness wrapper。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file sink readiness wrapper。
- artifact export readiness wrapper。

`CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 已经足够作为当前 no-side-effect write admission endpoint。继续包装成 receipt / record / publication 会回到 same-shape thin wrapper，没有新增 owner truth、consumer、integration 或风险证据。

如果未来靠近真实 write / output sink，必须先做 docs-only preflight，评估 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary、local-only boundary、sampling、retention 与 backpressure stop-line。不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` edits。
- no logging subsystem。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file / stdout / stderr output。
- no external artifact retention。
- no external diagnostics export。
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

## Candidate Comparison

### A. P1 internal Renderer real write sink preflight decision

选择为下一阶段 opening。

理由：

- Write sink admission endpoint 已封账，下一步如果靠近真实 write sink，必须先做 docs-only preflight。
- Preflight 可以评估 future real write sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary、local-only boundary、sampling、retention 与 backpressure stop-line。
- 它仍不允许 implementation，不批准 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

### B. Write sink hardening

暂缓。

只有发现 no-side-effect readiness、privacy-safe payload policy、local-only artifact policy facts 表达不足、manifest drift 或 closure 证据缺口时才选择。当前 manifest 已固定 canonical endpoint 与 no-side-effect stop-line，没有 hardening blocker。

### C. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前本轮只做 docs manifest stabilization，没有新增 runtime tail。

### D. Write receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 no-side-effect write admission endpoint 不允许真实输出、发布、遥测、回调、event bus 或公开诊断。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留外部 artifact。未来若评估真实 artifact sink，也必须先 docs-only preflight。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics write admission 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics write admission endpoint closure。

### I. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer real write sink preflight decision`

下一轮必须是 docs-only preflight。它只评估是否可以打开真实 write sink runway，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

## Downstream Status

`P1 internal Renderer real write sink preflight decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-real-write-sink-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-real-write-sink-preflight-decision.md)

Preflight 选择下一阶段：

`P1 internal Renderer real write sink no-op boundary bundle implementation`

下一阶段默认新建 `runtime_renderer_diagnostics_real_write.cj`，只消费 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`，输出 real-write intent / sink target policy / write safety gate / privacy-safe serialization policy / no-op write readiness value facts。它仍不得实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file write / stdout / stderr / external artifact retention / backend handler / command buffer / renderer state write / render failure callback / render permission。

`P1 internal Renderer real write sink no-op boundary bundle implementation` 已完成，closure 见：

- [2026-05-02-p1-internal-renderer-real-write-sink-no-op-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-real-write-sink-no-op-boundary-closure-review.md)

当前 downstream endpoint：

- `CjguiInternalRendererDiagnosticsNoOpWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsRealWriteNoOpDraft()`

该 endpoint 只表示 real-write intent / sink target policy / write safety gate / privacy-safe serialization policy / no-op write readiness value facts。它仍不是真实 logging / write sink，不写文件 / stdout / stderr，不触发 telemetry / observer callback / event bus / public diagnostics，也不保留 external artifact。

`P1 internal Renderer real write sink no-op closure / next diagnostics write decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-real-write-sink-no-op-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-real-write-sink-no-op-next-boundary-decision.md)

Decision 判定 `CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 已足够作为当前 no-op write endpoint；下一阶段应先做 `P1 internal Renderer real write sink no-op manifest stabilization bundle implementation`，固定 `runtime_renderer_diagnostics_real_write.cj` 的 owner / truth / canonical endpoint / stop-line，而不是新增 real-write receipt / record / publication 或直接实现 local debug sink / file sink。

`P1 internal Renderer real write sink no-op manifest stabilization bundle implementation` 已完成，manifest / closure 见：

- [2026-05-02-p1-renderer-real-write-sink-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-real-write-sink-no-op-manifest.md)
- [2026-05-02-p1-internal-renderer-real-write-sink-no-op-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-real-write-sink-no-op-manifest-stabilization-closure-review.md)

Manifest 固定当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOpWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsRealWriteNoOpDraft()`

该 endpoint 只表示 internal real-write intent / sink target policy / write safety gate / privacy-safe serialization policy / no-op write readiness value facts。它不是真实 logging / write sink、file / stdout / stderr sink、telemetry、observer callback、event bus、public diagnostics、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

最终 next opening：

`P1 internal Renderer local debug sink preflight decision`

下一轮只能做 docs-only preflight，评估 local debug sink owner、privacy、lifecycle、thread-safety、artifact、debug-only、local-only、opt-in、backpressure、retention 与 failure rollback stop-line；不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

## Pipeline Milestone Status

Renderer local diagnostics no-output / no-op pipeline milestone 已完成：

- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md)

Milestone 固定当前 canonical tail：`CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`。后续 reopening 必须从 docs-only preflight 或 duplicate audit 开始；不得直接新增 write receipt / record / publication、真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink 或 external artifact retention。
