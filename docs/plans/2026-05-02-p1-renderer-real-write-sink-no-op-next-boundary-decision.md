# P1 Renderer real write sink no-op next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

上一轮已完成 `P1 internal Renderer real write sink no-op boundary bundle implementation`。当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOpWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsRealWriteNoOpDraft()`

当前 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_real_write.cj`

该 endpoint 只表达 internal real-write intent / sink target policy / write safety gate / privacy-safe serialization policy / no-op write readiness value facts。

它不是 real-write receipt、record、publication、真实 logging / write sink、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr output、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮只做 docs-only decision，不修改 `.cj`，不运行 build / smoke，不批准真实 write / output implementation。

## Endpoint Assessment

`CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 已足够作为当前 real write no-op endpoint。

理由：

- 它有明确 owner：`runtime_renderer_diagnostics_real_write.cj`。
- 它有明确 truth：real-write runway 的 no-op value facts。
- 它保留了 sink target policy、write safety gate、privacy-safe serialization policy 三个不可替代语义锚点。
- 它明确不授予真实写入许可，不产生 serialization output，不绑定 output target，不保留 artifact。
- 它的 default draft 只从 no-side-effect write admission 串起，不读取 Queue / Action / Runtime lower-level mutable facts。

下一步应先做 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line，避免 no-op endpoint 后继续长出 receipt / record / publication thin wrapper。

## Candidate Comparison

### A. P1 internal Renderer real write sink no-op manifest stabilization bundle implementation

选择。

理由：

- 当前 no-op endpoint 已足够，最稳下一步是固定 manifest，而不是继续代码尾巴。
- Manifest 可以明确 `CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 不是真实 write permission、logging readiness、file sink readiness 或 public diagnostics readiness。
- Manifest 可以把 sink target policy / write safety gate / privacy-safe serialization policy 的 owner truth 写清楚，防止后续误开真实 output sink。
- 它仍是 docs / manifest stabilization，不写 runtime code，不运行 build / smoke。

下一轮默认新增：

- `docs/plans/2026-05-02-p1-renderer-real-write-sink-no-op-manifest.md`
- `docs/plans/2026-05-02-p1-internal-renderer-real-write-sink-no-op-manifest-stabilization-closure-review.md`

### B. Real local debug sink preflight

暂缓。

该方向如果未来要打开，也必须先完成 no-op manifest stabilization。真实 local debug sink 会更靠近 output / artifact / privacy / lifecycle / thread-safety / debug-only 边界，不能在当前 endpoint 尚未 manifest 封账前直接进入。

### C. Real write no-op hardening

暂缓。

只有发现 sink target policy、write safety gate、privacy-safe serialization policy 或 no-op readiness 表达不足时才选择。当前 closure 已证明这些语义存在，没有 hardening blocker。

### D. Real-write receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。`CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 已经是当前 endpoint，不需要再包成 receipt / record / publication。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 no-op endpoint 不允许真实输出、遥测、回调、事件发布或公开诊断。

### F. File / stdout / stderr / artifact sink

拒绝。

当前不写文件、不打 stdout / stderr、不保留 external artifact。未来若评估 local debug sink 或 file sink，也必须先 docs-only preflight。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics no-op write endpoint 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才选择。当前 evidence 指向 manifest stabilization，而不是 cleanup。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics no-op write endpoint closure。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

本轮明确确认：

- `CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 已经是当前 no-op write endpoint。
- 不批准新增 real-write receipt。
- 不批准新增 real-write record。
- 不批准新增 real-write publication。
- 不把 no-op readiness 解释成 logging sink readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness、file sink readiness 或 artifact retention readiness。

如果未来靠近真实 local debug sink / output sink，必须先做 docs-only preflight，评估 owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary、local-only boundary、sampling、retention、backpressure 与 failure rollback stop-line。不得直接实现 logging、telemetry、observer callback、event bus、public diagnostics、file sink、stdout / stderr 或 external artifact retention。

## Decision

最终选择：

`P1 internal Renderer real write sink no-op manifest stabilization bundle implementation`

下一轮默认 docs-only / manifest stabilization，不修改 `.cj`，不运行 build / smoke。

## Stop-line

下一轮继续禁止：

- no runtime code edits。
- no `.cj` edits。
- no real logging / write implementation。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file / stdout / stderr output。
- no external artifact retention。
- no external diagnostics export。
- no raw payload collection。
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

本 docs-only decision 的验证口径：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 可以找到本 decision 与 next opening。
- forbidden check：确认没有 `.cj` runtime code diff，未触碰 protected paths。
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)` 记录 risk 与 affected processes。
- 不运行 `cjpm build` / smoke。
