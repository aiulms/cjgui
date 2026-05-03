# P1 Renderer diagnostics write sink admission next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

上一轮已新增 internal-only Renderer diagnostics write sink admission owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_write_sink.cj`

Current canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsWriteSinkAdmissionDraft()`

该 endpoint 只表示 renderer diagnostics value pipeline 内部的 write sink intent、write channel admission、privacy-safe payload policy、local-only artifact policy 与 no-side-effect write readiness facts。

它不是 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮只做 decision，不修改 `.cj`，不运行 build / smoke。

## Endpoint Assessment

`CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 已足够作为当前 no-side-effect write admission endpoint：

- 它固定了 write-channel admission，而不是 channel implementation。
- 它固定了 privacy-safe payload policy，只允许 dehydrated diagnostic facts / severity / retention hint，不允许 raw payload collection。
- 它固定了 local-only artifact policy，但不写文件、不创建 external artifact、不承诺 artifact retention。
- 它固定了 no-side-effect readiness，明确不是 write permission、output permission、logging readiness、telemetry readiness、observer readiness、event bus readiness 或 public diagnostics readiness。
- 它保留 defer-only 与 blocked / inconsistent fail-closed 语义，不伪造 write readiness。

因此下一步应先把 owner / truth / canonical endpoint / stop-line 封成 manifest，而不是继续新增 write receipt / record / publication。

## Candidate Comparison

### A. P1 internal Renderer diagnostics write sink admission manifest stabilization bundle implementation

选择。

理由：

- 当前 endpoint 已足够，风险主要来自误读为真实 write / logging permission。
- Manifest 可以固定 owner file、truth、canonical endpoint、input / output facts 和 stop-line。
- Same-shape Boundary Brake 要求在 endpoint 足够时先封账，避免把 no-side-effect readiness 包成 receipt / record / publication。

### B. Real write sink preflight

暂缓。

如果未来靠近真实 write / output sink，必须先做 docs-only preflight，评估 owner、privacy、lifecycle、thread-safety、artifact policy、debug-only、local-only、sampling、retention 与 backpressure stop-line。当前应等 manifest 封账后再评估。

### C. Write sink hardening

暂缓。

只有发现 no-side-effect readiness、privacy-safe payload policy 或 local-only artifact policy 表达不足时才选择。当前 closure 已给出足够边界证据。

### D. Write receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。它不会新增 owner truth、consumer、gate、integration 或风险证据。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 endpoint 不允许真实输出、遥测、事件、回调或公开诊断。

### F. File / stdout / stderr / artifact sink

拒绝。

当前 no-side-effect write readiness 不写文件、不打 stdout / stderr、不保留 external artifact。未来若评估真实 artifact sink，也必须先 docs-only preflight。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics write sink admission 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前本轮只做 docs decision，没有 consolidation blocker。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics write sink admission endpoint closure。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

本轮明确把 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 视为当前 no-side-effect write admission endpoint。

继续禁止新增：

- write receipt。
- write record。
- write publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file sink readiness wrapper。

如果未来靠近真实 write / output sink，必须先做 docs-only preflight，不能直接实现 logging、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr 或 external artifact retention。

## Decision

最终选择：

`P1 internal Renderer diagnostics write sink admission manifest stabilization bundle implementation`

下一轮默认 docs-only write set：

- 新增 `docs/plans/2026-05-02-p1-renderer-diagnostics-write-sink-admission-manifest.md`。
- 新增对应 manifest stabilization closure review。
- 更新 `README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md` 与相关 diagnostics manifests。
- 不修改 `.cj`。
- 不触碰 `runtime_state.cj`。
- 不运行 build / smoke。

## Stop-line

下一轮继续禁止：

- no runtime code unless a future explicit task changes scope。
- no `.cj` edits in manifest stabilization。
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

## Verification Plan

本轮 docs-only decision 的验证口径：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 可以找到本 decision 与 next opening。
- forbidden check：确认没有 `.cj` runtime code diff，未触碰 protected paths。
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)` 记录 risk 与 affected processes。
- 不运行 `cjpm build` / smoke。
