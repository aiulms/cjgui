# P1 Renderer diagnostics consolidation audit decision

Date: 2026-05-03

## Scope

本轮是 docs-only audit decision。目标是审计 Renderer diagnostics no-output / no-op local pipeline 是否已经出现明确 duplicate projection、low-value helper、self-wrapping owner 或 manifest drift，并决定是否需要进入 targeted consolidation preflight。

本轮不修改 `.cj`，不删除、合并或重命名 runtime owner，不运行 build / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Inputs Reviewed

- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-diagnostics-pipeline-milestone-stabilization-closure-review.md)
- [2026-05-02-p1-renderer-packet-diagnostics-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-diagnostics-manifest.md)
- [2026-05-02-p1-renderer-diagnostics-policy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-policy-manifest.md)
- [2026-05-02-p1-renderer-diagnostics-sink-policy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-sink-policy-manifest.md)
- [2026-05-02-p1-renderer-diagnostics-output-sink-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-output-sink-admission-manifest.md)
- [2026-05-02-p1-renderer-diagnostics-write-sink-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-write-sink-admission-manifest.md)
- [2026-05-02-p1-renderer-real-write-sink-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-real-write-sink-no-op-manifest.md)
- [2026-05-03-p1-renderer-local-debug-sink-policy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-debug-sink-policy-manifest.md)
- [2026-05-03-p1-renderer-local-debug-output-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-debug-output-admission-manifest.md)
- [2026-05-03-p1-renderer-real-local-debug-output-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-real-local-debug-output-no-op-manifest.md)

只读源码扫描也覆盖了 9 个 diagnostics owner file，用于确认是否存在 `Receipt` / `Record` / `Publication` 型 owner 命名、真实输出词漂移，以及 readiness 命名误判风险。

## Current Pipeline Truth

当前 pipeline 仍以 [local diagnostics pipeline milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md) 为总账。Canonical tail endpoint 是：

- `CjguiInternalRendererNoOpLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

当前 9 个必须保留的语义节点如下：

- Packet diagnostics：`CjguiInternalRendererPacketDiagnosticsResult` 表达 internal diagnostics summary / severity / evidence / result facts。
- Diagnostics policy：`CjguiInternalRendererDiagnosticsPolicyResult` 表达 severity handling / retention hint / no-public-diagnostics policy facts。
- Sink policy：`CjguiInternalRendererDiagnosticsNoOutputReadiness` 表达 sink intent / privacy guard / lifecycle guard / no-output readiness facts。
- Output admission：`CjguiInternalRendererDiagnosticsNoWriteReadiness` 表达 output channel policy / privacy admission / artifact guard / no-write readiness facts。
- Write admission：`CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 表达 write channel admission / privacy-safe payload / local-only artifact / no-side-effect readiness facts。
- Real write no-op：`CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 表达 sink target policy / write safety gate / privacy-safe serialization / no-op write readiness facts。
- Local debug sink policy：`CjguiInternalRendererNoOutputDebugReadiness` 表达 debug channel policy / opt-in guard / redaction policy / no-output debug readiness facts。
- Local output admission：`CjguiInternalRendererNoWriteLocalOutputReadiness` 表达 local output target policy / opt-in admission / redaction readiness / no-write local output facts。
- Real local no-op：`CjguiInternalRendererNoOpLocalOutputReadiness` 表达 local target admission / opt-in enforcement / redaction enforcement / no-op local output readiness facts。

这些节点都仍是 internal-only value facts。它们不是真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

## Audit Findings

未发现明确可直接删除、合并或重命名的 runtime owner。当前 9 个 owner 的结构确实高度相似，但每一段 manifest 都固定了不同的 owner truth：diagnostics summary、policy、sink privacy/lifecycle、output artifact guard、write admission、real-write no-op、local debug opt-in/redaction、local output admission、real local no-op enforcement。该差异足以支持本轮不直接提出代码 consolidation。

未发现 `Receipt` / `Record` / `Publication` 型 diagnostics owner。只读源码扫描没有匹配到 `struct .*Receipt`、`struct .*Record`、`struct .*Publication`、`CjguiInternalRenderer.*Receipt`、`CjguiInternalRenderer.*Record` 或 `CjguiInternalRenderer.*Publication`。源码里存在 `didAvoidDiagnosticPublication` 这类 stop-line 字段，但它们表达的是避免 public diagnostics / external publication，而不是新 publication owner。

发现的主要风险不是“已有明确重复 owner”，而是 diagnostics runway 已经很长，且多个 endpoint 使用 `Readiness` / `NoOutput` / `NoWrite` / `NoOp` 命名。如果后续提示词忽略 manifest stop-line，容易把这些 readiness 误读成真实 logging / file sink / telemetry permission。因此下一步应固定 audit manifest 或进行 stop-line hardening，而不是继续新增 tail wrapper。

未发现文档已经批准真实 output / logging。9 个 manifest 与 pipeline milestone 都持续拒绝 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 和 render permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮继续生效：diagnostics local-output tail 已经足够长，后续不得再默认新增 receipt / record / publication / readiness wrapper。

本轮不把高度同构的 shape 当成直接删代码证据。没有强 evidence 时，直接合并 owner 会有误删 owner truth 的风险；更稳的路径是先固定 audit 结论，再只在未来出现 duplicate projection、low-value helper、self-wrapping evidence 或 manifest drift 时进入 targeted consolidation preflight。

未来若要靠近真实 local diagnostics output / logging sink，必须先做 docs-only preflight，并提供 concrete owner、privacy、lifecycle、threading、artifact、opt-in、redaction、retention、backpressure、failure rollback 和 debug-only / local-only evidence。不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

## Candidate Comparison

### A. P1 internal Renderer diagnostics consolidation audit manifest stabilization bundle implementation

选择。

理由：

- 当前没有强 evidence 支持直接开代码 consolidation。
- Audit 已经识别主要风险是 long runway + readiness 命名误判，而不是明确可删 owner。
- Manifest stabilization 可以固定 audit 结论、owner 保留理由、stop-line 和 future reopening conditions，继续阻止 tail wrapper 回潮。

### B. P1 internal Renderer diagnostics targeted consolidation preflight decision

不选择。

只有发现明确 duplicate projection、low-value helper、self-wrapping owner 或 manifest drift 时才进入该候选。本轮只读审计没有达到这个证据标准。

### C. P1 internal Renderer diagnostics stop-line hardening docs bundle implementation

暂不单独选择。

当前 docs 已持续拒绝真实 output / logging；误判风险可以先纳入 audit manifest stabilization。如果后续发现某个 manifest 表述漂移，再单独开 stop-line hardening。

### D. Real local diagnostics output preflight

暂缓。

Milestone 刚完成，本轮 audit 仍建议先封住 diagnostics tail，不立即重新逼近真实输出。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 diagnostics pipeline 仍是 internal value facts，不批准真实输出、发布、遥测、回调、event bus 或公开诊断。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留 external artifact，也不输出 serialized payload。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics pipeline 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些不是 diagnostics consolidation audit 的目标。

### I. Public surface expansion

拒绝。

Public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

本轮 audit 结论：没有发现明确可直接删除、合并或重命名的 diagnostics runtime owner；也没有发现 receipt / record / publication owner 已经回潮。发现的真实风险是 diagnostics no-output / no-op runway 同构度高，未来容易继续 tail wrapping 或把 readiness 误读成真实 output permission。

最终 next opening：

`P1 internal Renderer diagnostics consolidation audit manifest stabilization bundle implementation`

下一轮仍必须 docs-only。它应固定 audit 结论、9 个 owner 保留理由、canonical tail endpoint、stop-line、future targeted consolidation reopening conditions，并继续拒绝真实 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / artifact retention / backend / command buffer / renderer state write / render failure callback / render permission。
