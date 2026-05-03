# P1 Renderer diagnostics sink policy manifest

日期：2026-05-02

状态：docs-only manifest stabilization

## Purpose

本 manifest 固定 renderer diagnostics sink policy 的 owner / truth / canonical endpoint / stop-line，封账当前 no-output sink policy endpoint。

它不是 logging manifest、telemetry manifest、observer manifest、event bus manifest 或 public diagnostics manifest。它只记录 renderer diagnostics value pipeline 内部的 sink intent、sink policy、privacy guard、lifecycle guard 与 no-output readiness value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`

Canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

Current truth：

- internal diagnostics sink intent facts。
- internal diagnostics sink policy facts。
- internal diagnostics privacy guard facts。
- internal diagnostics lifecycle guard facts。
- no-output readiness value facts。

该 truth 只表示 future diagnostics sink policy boundary 可继续评估。它不表示真实 output sink，也不授予 logging、telemetry、observer callback、event bus、public diagnostics、backend handler、renderer state write 或 render permission。

## Upstream Facts

当前 sink policy owner 只消费：

- `CjguiInternalRendererDiagnosticsPolicyResult`

允许透传或引用的事实口径只限：

- dehydrated diagnostic facts。
- diagnostic severity facts。
- retention hint facts。

当前不收集 raw payload，不承诺 external artifact retention，也不读取 Queue / Action / Runtime lower-level mutable facts。

## Current Pipeline

当前 pipeline：

1. `CjguiInternalRendererDiagnosticsPolicyResult`
2. `CjguiInternalRendererDiagnosticsSinkIntent`
3. `CjguiInternalRendererDiagnosticsSinkPolicy`
4. `CjguiInternalRendererDiagnosticsPrivacyGuard`
5. `CjguiInternalRendererDiagnosticsLifecycleGuard`
6. `CjguiInternalRendererDiagnosticsNoOutputReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

Default draft 只生成 internal value facts。它不写文件、不打 stdout / stderr、不发事件、不写日志、不触发 telemetry、不调用 observer、不创建 public diagnostics、不写 renderer state，也不触发 backend 或 render callback。

## No-output Readiness

`CjguiInternalRendererDiagnosticsNoOutputReadiness` 是当前 canonical no-output sink policy endpoint。

它明确不是：

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
- real output sink。

No-output readiness 的含义只有一个：future diagnostics output sink runway 可以在后续 docs-only preflight 中继续评估。它不是 output permission、logging readiness、telemetry readiness、observer readiness 或 public diagnostics readiness。

## Same-shape Boundary Brake

本轮选择 manifest 封账，而不是继续新增 sink policy tail。

明确拒绝：

- sink receipt。
- sink record。
- sink publication。
- output readiness wrapper。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

`CjguiInternalRendererDiagnosticsNoOutputReadiness` 已经足够作为当前 no-output sink policy endpoint。继续包装成 receipt / record / publication 会回到 same-shape thin wrapper，没有新增 owner truth、consumer、integration 或风险证据。

如果未来靠近真实 output sink，必须先做 docs-only preflight，评估 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary 与 no-runtime-side-effect stop-line。不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

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

### A. P1 internal Renderer diagnostics output sink preflight decision

选择为下一阶段 opening。

理由：

- Sink policy endpoint 已封账，下一步如果靠近真实 output sink，必须先做 docs-only preflight。
- Preflight 可以评估 future output sink owner、privacy、lifecycle、thread-safety、artifact policy 与 debug-only stop-line。
- 它仍不允许 implementation，不批准 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

### B. Diagnostics sink hardening

暂缓。

只有发现 no-output / privacy / lifecycle facts 表达不足、manifest drift 或 closure 证据缺口时才选择。当前 manifest 已固定 canonical endpoint 与 no-output stop-line，没有 hardening blocker。

### C. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前本轮只做 docs manifest stabilization，没有新增 runtime tail。

### D. Sink receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 no-output sink policy endpoint 不允许真实输出、发布、遥测、回调或公开诊断。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留外部 artifact。未来若评估真实 artifact sink，也必须先 docs-only preflight。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics sink policy 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics sink policy endpoint closure。

### I. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics output sink preflight decision`

下一轮必须是 docs-only preflight。它只评估是否可以打开真实 output sink runway，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

## Downstream Status

`P1 internal Renderer diagnostics output sink preflight decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-diagnostics-output-sink-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-output-sink-preflight-decision.md)

Preflight 选择下一阶段：

`P1 internal Renderer diagnostics output sink admission value boundary bundle implementation`

下一阶段只能建立 output sink intent / output channel policy / privacy admission / artifact guard / no-write readiness value facts。它仍不得实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

## Pipeline Milestone Status

Renderer local diagnostics no-output / no-op pipeline milestone 已完成：

- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md)

Milestone 固定当前 canonical tail：`CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`。后续 reopening 必须从 docs-only preflight 或 duplicate audit 开始；不得直接新增 sink receipt / record / publication、真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink 或 external artifact retention。

`P1 internal Renderer diagnostics output sink admission value boundary bundle implementation` 已完成，closure 见：

- [2026-05-02-p1-internal-renderer-diagnostics-output-sink-admission-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-output-sink-admission-boundary-closure-review.md)

当前 downstream canonical endpoint 是：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft()`

该 endpoint 仍只允许 internal no-write value facts，不批准 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。

`P1 internal Renderer diagnostics output sink admission closure / next diagnostics output decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-diagnostics-output-sink-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-output-sink-admission-next-boundary-decision.md)

当前 next opening 是 `P1 internal Renderer diagnostics output sink admission manifest stabilization bundle implementation`。

`P1 internal Renderer diagnostics output sink admission manifest stabilization bundle implementation` 已完成，manifest 见：

- [2026-05-02-p1-renderer-diagnostics-output-sink-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-output-sink-admission-manifest.md)

closure 见：

- [2026-05-02-p1-internal-renderer-diagnostics-output-sink-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-output-sink-admission-manifest-stabilization-closure-review.md)

当前 downstream canonical endpoint 仍是：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft()`

当前 next opening 是 `P1 internal Renderer diagnostics write sink preflight decision`。下一轮仍必须 docs-only，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。
