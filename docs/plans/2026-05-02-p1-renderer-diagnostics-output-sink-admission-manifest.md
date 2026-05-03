# P1 Renderer diagnostics output sink admission manifest

日期：2026-05-02

状态：docs-only manifest stabilization

## Purpose

本 manifest 固定 renderer diagnostics output sink admission 的 owner / truth / canonical endpoint / stop-line，封账当前 no-write output admission endpoint。

它不是 logging manifest、telemetry manifest、observer manifest、event bus manifest、public diagnostics manifest 或 file sink manifest。它只记录 renderer diagnostics value pipeline 内部的 output sink intent、output channel policy、privacy admission、artifact guard 与 no-write readiness value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_output.cj`

Canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft()`

Current truth：

- internal diagnostics output sink intent facts。
- internal diagnostics output channel policy facts。
- internal diagnostics privacy admission facts。
- internal diagnostics artifact guard facts。
- no-write readiness value facts。

该 truth 只表示 future diagnostics output admission boundary 可继续评估。它不表示真实 output sink，也不授予 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr output、artifact retention、backend handler、renderer state write、render failure callback 或 render permission。

## Upstream Facts

当前 output admission owner 只消费：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`

允许透传或引用的事实口径只限：

- dehydrated diagnostic facts。
- diagnostic severity facts。
- retention hint facts。

当前不收集 raw payload，不承诺 external artifact retention，也不读取 Queue / Action / Runtime lower-level mutable facts。

## Current Pipeline

当前 pipeline：

1. `CjguiInternalRendererDiagnosticsNoOutputReadiness`
2. `CjguiInternalRendererDiagnosticsOutputSinkIntent`
3. `CjguiInternalRendererDiagnosticsOutputChannelPolicy`
4. `CjguiInternalRendererDiagnosticsPrivacyAdmission`
5. `CjguiInternalRendererDiagnosticsArtifactGuard`
6. `CjguiInternalRendererDiagnosticsNoWriteReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft()`

Default draft 只生成 internal value facts。它不写文件、不打 stdout / stderr、不发事件、不写日志、不触发 telemetry、不调用 observer、不创建 public diagnostics、不保留 external artifact、不写 renderer state，也不触发 backend 或 render callback。

## No-write Readiness

`CjguiInternalRendererDiagnosticsNoWriteReadiness` 是当前 canonical no-write output admission endpoint。

它明确不是：

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
- backend handler。
- render failure callback。
- backend packet。
- command buffer。
- renderer state write。
- render permission。

No-write readiness 的含义只有一个：future diagnostics write sink runway 可以在后续 docs-only preflight 中继续评估。它不是 output permission、write permission、logging readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness 或 file sink readiness。

## Same-shape Boundary Brake

本轮选择 manifest 封账，而不是继续新增 output admission tail。

明确拒绝：

- output receipt。
- output record。
- output publication。
- write readiness wrapper。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file sink readiness wrapper。

`CjguiInternalRendererDiagnosticsNoWriteReadiness` 已经足够作为当前 no-write output admission endpoint。继续包装成 receipt / record / publication 会回到 same-shape thin wrapper，没有新增 owner truth、consumer、integration 或风险证据。

如果未来靠近真实 output / write sink，必须先做 docs-only preflight，评估 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary、local-only boundary 与 no-runtime-side-effect stop-line。不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

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

### A. P1 internal Renderer diagnostics write sink preflight decision

选择为下一阶段 opening。

理由：

- Output admission endpoint 已封账，下一步如果靠近真实 write sink，必须先做 docs-only preflight。
- Preflight 可以评估 future write sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary 与 local-only boundary。
- 它仍不允许 implementation，不批准 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

### B. Output sink hardening

暂缓。

只有发现 no-write / privacy / artifact guard facts 表达不足、manifest drift 或 closure 证据缺口时才选择。当前 manifest 已固定 canonical endpoint 与 no-write stop-line，没有 hardening blocker。

### C. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前本轮只做 docs manifest stabilization，没有新增 runtime tail。

### D. Output receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 no-write output admission endpoint 不允许真实输出、发布、遥测、回调、event bus 或公开诊断。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留外部 artifact。未来若评估真实 artifact sink，也必须先 docs-only preflight。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics output admission 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics output admission endpoint closure。

### I. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics write sink preflight decision`

下一轮必须是 docs-only preflight。它只评估是否可以打开真实 write sink runway，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

## Downstream Status

`P1 internal Renderer diagnostics write sink preflight decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-diagnostics-write-sink-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-write-sink-preflight-decision.md)

Preflight 选择下一阶段：

`P1 internal Renderer diagnostics write sink admission value boundary bundle implementation`

下一阶段默认新建 `runtime_renderer_diagnostics_write_sink.cj`，只消费 `CjguiInternalRendererDiagnosticsNoWriteReadiness`，输出 write sink intent / write channel admission / privacy-safe payload policy / local-only artifact policy / no-side-effect write readiness value facts。它仍不得实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file write / stdout / stderr / external artifact retention / backend handler / command buffer / renderer state write / render failure callback / render permission。

`P1 internal Renderer diagnostics write sink admission value boundary bundle implementation` 已完成，closure 见：

- [2026-05-02-p1-internal-renderer-diagnostics-write-sink-admission-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-write-sink-admission-boundary-closure-review.md)

当前 downstream canonical endpoint 是：

- `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsWriteSinkAdmissionDraft()`

`P1 internal Renderer diagnostics write sink admission closure / next diagnostics write decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-diagnostics-write-sink-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-write-sink-admission-next-boundary-decision.md)

Decision 判定 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 已足够作为当前 no-side-effect write admission endpoint。

当时 next opening 是 `P1 internal Renderer diagnostics write sink admission manifest stabilization bundle implementation`。该 opening 要求先 docs-only 固定 write sink admission owner / truth / canonical endpoint / stop-line，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission，也不得新增 write receipt / record / publication thin wrapper。

`P1 internal Renderer diagnostics write sink admission manifest stabilization bundle implementation` 已完成，manifest / closure 见：

- [2026-05-02-p1-renderer-diagnostics-write-sink-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-write-sink-admission-manifest.md)
- [2026-05-02-p1-internal-renderer-diagnostics-write-sink-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-write-sink-admission-manifest-stabilization-closure-review.md)

Manifest 固定 downstream canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsWriteSinkAdmissionDraft()`

当前 next opening 是 `P1 internal Renderer real write sink preflight decision`。下一轮只能 docs-only 评估 real write sink runway，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

## Pipeline Milestone Status

Renderer local diagnostics no-output / no-op pipeline milestone 已完成：

- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md)

Milestone 固定当前 canonical tail：`CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`。后续 reopening 必须从 docs-only preflight 或 duplicate audit 开始；不得直接新增 output receipt / record / publication、真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink 或 external artifact retention。
