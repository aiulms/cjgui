# P1 Renderer local diagnostics pipeline milestone manifest

日期：2026-05-03

状态：docs-only milestone stabilization

## Purpose

本 manifest 固定 Renderer diagnostics no-output / no-op local pipeline 的 owner chain、canonical endpoints、stop-line 和后续 reopening 条件。

它不是 logging manifest、telemetry manifest、observer callback manifest、event bus manifest、public diagnostics manifest、file sink manifest、artifact export manifest 或 backend diagnostics manifest。它只把 renderer diagnostics value pipeline 当前已经形成的 internal diagnostics / policy / sink / output / write / local-debug facts 做 milestone 封账，避免继续在尾部生成 receipt / record / publication / readiness wrapper。

## Pipeline Chain

当前 milestone chain：

1. packet diagnostics：`CjguiInternalRendererPacketDiagnosticsResult`
2. diagnostics policy：`CjguiInternalRendererDiagnosticsPolicyResult`
3. sink policy：`CjguiInternalRendererDiagnosticsNoOutputReadiness`
4. output admission：`CjguiInternalRendererDiagnosticsNoWriteReadiness`
5. write admission：`CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
6. real write no-op：`CjguiInternalRendererDiagnosticsNoOpWriteReadiness`
7. local debug sink policy：`CjguiInternalRendererNoOutputDebugReadiness`
8. local debug output admission：`CjguiInternalRendererNoWriteLocalOutputReadiness`
9. real local debug no-op：`CjguiInternalRendererNoOpLocalOutputReadiness`

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

该 endpoint 只表示 future real local diagnostics output runway 可以在后续 docs-only preflight 中重新评估。它不是 output permission、write permission、logging readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、file sink readiness、artifact export readiness、serialized payload readiness、backend readiness 或 render readiness。

## Current Truth

当前 truth 只包括 internal value facts：

- packet diagnostics summary / severity / evidence facts。
- diagnostics policy / severity handling / retention hint facts。
- diagnostics sink intent / sink policy / privacy guard / lifecycle guard facts。
- diagnostics output sink intent / output channel policy / privacy admission / artifact guard facts。
- diagnostics write sink intent / write channel admission / privacy-safe payload policy / local-only artifact policy facts。
- real-write intent / sink target policy / write safety gate / privacy-safe serialization policy facts。
- local debug sink intent / debug channel policy / opt-in guard / redaction policy facts。
- local debug output intent / output target policy / opt-in admission / redaction readiness facts。
- real local output intent / local target admission / opt-in enforcement policy / redaction enforcement policy facts。
- no-output / no-write / no-side-effect / no-op readiness facts。

这些 truth 都是 backend-agnostic、internal-only、dehydrated value facts。当前只允许 dehydrated diagnostic facts、diagnostic severity facts 与 retention hint facts；不收集 raw payload，不输出 serialized payload，不承诺 external artifact retention，不执行 local file output，不读取 Queue / Action / Runtime lower-level mutable facts。

## Stop-line

本 milestone 明确当前 diagnostics local pipeline 不是：

- real logging。
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
- backend submission。
- command buffer。
- renderer state write。
- render permission。
- logging subsystem。
- exception system / public error API。
- Metal / AppKit / backend implementation。
- CAMetalLayer / MTLDevice。
- native handle / raw pointer / platform object。
- sorting side effect。
- draw call。
- real GPU batching / draw-call merge。
- dirty-region / diff / patch / incremental render。
- Widget / Layout / Text / IME / Accessibility / ECS implementation。
- public API / public C ABI expansion。

继续禁止：

- no runtime code in this milestone round。
- no `.cj` edits。
- no raw payload collection。
- no serialized payload output。
- no file write / stdout / stderr / event publication。
- no external artifact retention。
- no Queue / Action / Runtime lower-level mutable facts。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。

## Public Surface

Current public allowlist unchanged：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 milestone 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public diagnostics、不开放 public error API，也不开放 public C ABI。

## Same-shape Boundary Brake

本 milestone 的目的就是刹住 diagnostics local-output tail。

明确拒绝继续新增：

- diagnostics receipt / record / publication。
- policy receipt / record / publication。
- sink receipt / record / publication。
- output receipt / record / publication。
- write receipt / record / publication。
- real-write receipt / record / publication。
- local-debug receipt / record / publication。
- local-output receipt / record / publication。
- real-local-output receipt / record / publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file / stdout / stderr readiness wrapper。
- artifact export readiness wrapper。
- backend readiness wrapper。

Brake 生效点：`CjguiInternalRendererNoOpLocalOutputReadiness` 已经是当前 no-op local output canonical tail。继续包装不会新增 owner truth、consumer、integration 或风险证据，只会把同一 no-output / no-op facts 换名拉长。

## Reopening Conditions

未来若要靠近真实 local diagnostics output / logging sink，必须先从 docs-only preflight 重新打开，并至少提供以下 concrete evidence：

- concrete owner：真实 output / logging sink 的 owner、输入、输出、生命周期和不变量。
- privacy：raw payload 禁止或最小化策略、dehydrated facts 边界、redaction 证据。
- lifecycle：sink 创建 / 关闭 / cleanup / failure rollback / ownership 边界。
- threading：thread-safety、main-thread / worker-thread 边界、backpressure / rate limit 口径。
- artifact：file / stdout / stderr / external artifact retention 是否允许、保留期限、清理策略。
- opt-in：debug-only / local-only / opt-in guard 是否存在，以及如何防止默认开启。
- redaction：redaction enforcement 与 serialization boundary 的证据。
- retention：retention hint 到真实 retention policy 的授权条件。
- failure rollback：写入失败、部分写入、重复写入、回滚或 no-op fallback 证据。

没有这些证据时，下一阶段不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / external artifact retention。

## Candidate Comparison

### A. P1 internal Renderer diagnostics consolidation / low-value duplicate audit decision

选择为下一阶段 opening。

理由：

- Diagnostics no-output / no-op runway 已经很长，继续向尾部推进会增加 same-shape wrapper 风险。
- Docs-only audit 可以检查 duplicate projection、low-value helper、self-wrapping evidence 与 manifest drift，但不直接删代码。
- 该候选符合 Same-shape Boundary Brake：先审计 owner truth 和重复度，再决定是否 hardening、consolidation 或暂停 diagnostics track。

### B. P1 internal Renderer real local diagnostics output preflight decision

暂缓。

Milestone 后可以作为未来候选，但现在先做 duplicate audit 更稳。若未来选择它，仍必须 docs-only，不得直接 implementation。

### C. Diagnostics hardening

暂缓。

只有发现 policy、redaction、opt-in、no-output、no-write、no-side-effect 或 no-op 表达不足时才选择。

### D. Return to renderer command / backend non-diagnostics track

暂缓作为后续备选。

本轮先完成 diagnostics pipeline milestone。后续如果 diagnostics audit 无 blocker，可再评估是否回到 command / backend 非 diagnostics track。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 milestone 不批准真实输出、发布、遥测、回调、event bus 或公开诊断。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留 external artifact。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics pipeline 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics local pipeline milestone closure。

### I. Public surface expansion

拒绝。

Public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics consolidation / low-value duplicate audit decision`

下一轮必须是 docs-only audit。它只检查 diagnostics pipeline 是否存在 duplicate / low-value helper / self-wrapping evidence 或 manifest drift，不直接删代码，不实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / external artifact retention，也不接 backend / command buffer / renderer state write / render failure callback / render permission。

## Downstream Audit

`P1 internal Renderer diagnostics consolidation / low-value duplicate audit decision` 已由 [2026-05-03-p1-renderer-diagnostics-consolidation-audit-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-consolidation-audit-decision.md) 完成。

Audit 结论：当前没有强 evidence 支持直接删除、合并或重命名 diagnostics runtime owner，也没有发现 receipt / record / publication owner 回潮。9 个 semantic owner 继续保留；主要风险是 diagnostics no-output / no-op runway 同构度高，后续可能被误读成真实 output permission。

新的 next opening 是：

`P1 internal Renderer diagnostics consolidation audit manifest stabilization bundle implementation`

## Downstream Audit Manifest

`P1 internal Renderer diagnostics consolidation audit manifest stabilization bundle implementation` 已由 [2026-05-03-p1-renderer-diagnostics-consolidation-audit-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-consolidation-audit-manifest.md) 与 [2026-05-03-p1-internal-renderer-diagnostics-consolidation-audit-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-diagnostics-consolidation-audit-manifest-stabilization-closure-review.md) 完成。

Audit manifest 固定当前没有明确可直接删除、合并或重命名的 diagnostics runtime owner；主要风险是 `Readiness` / `NoOutput` / `NoWrite` / `NoSideEffect` / `NoOp` 命名可能被误读成真实 output permission。

新的 next opening 是：

`P1 internal Renderer diagnostics stop-line hardening docs bundle implementation`

## Downstream Stop-line Hardening

`P1 internal Renderer diagnostics stop-line hardening docs bundle implementation` 已由 [2026-05-03-p1-renderer-diagnostics-stop-line-hardening.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-stop-line-hardening.md) 与 [2026-05-03-p1-internal-renderer-diagnostics-stop-line-hardening-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-diagnostics-stop-line-hardening-closure-review.md) 完成。

Hardening 固定 `Readiness` 不是 permission，`NoOutput` / `NoWrite` / `NoSideEffect` / `NoOp` 只表示 internal value facts / stop-line，`Sink` / `Output` / `Write` / `Real` / `LocalDebug` 只是 runway vocabulary，不是 implementation permission。

新的 next opening 是：

`P1 internal Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision`

## Downstream Branch Closure

`P1 internal Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision` 已由 [2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md) 完成。

Branch closure 结论：Renderer diagnostics no-output / no-op 支线正式封账，current canonical tail 仍是 `CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`，但不再继续新增 diagnostics readiness / receipt / record / publication / output tail。

新的 next opening 是：

`P1 internal Renderer command packet post-normalization handoff preflight decision`
