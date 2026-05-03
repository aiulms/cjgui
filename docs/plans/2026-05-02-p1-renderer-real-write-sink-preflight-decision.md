# P1 Renderer real write sink preflight decision

日期：2026-05-02

状态：docs-only preflight decision

## Context

Renderer diagnostics write sink admission 已完成 manifest stabilization。当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsWriteSinkAdmissionDraft()`

该 endpoint 只表示 internal diagnostics write sink intent / write channel admission / privacy-safe payload policy / local-only artifact policy / no-side-effect write readiness value facts。

它不是 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮只做 docs-only preflight，不修改 `.cj`，不运行 build / smoke，不批准真实写入或输出。

## Preflight Answer

可以打开 real write sink runway，但下一步也只能是 internal value boundary，不是真实写入。

下一步默认 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_real_write.cj`

下一步唯一允许的 input：

- `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`

下一步允许输出的 truth 只能是：

- real-write intent value facts。
- sink target policy value facts。
- write safety gate value facts。
- privacy-safe serialization policy value facts。
- no-op write readiness value facts。

这些 facts 只能表达 future real write sink runway 的内部入口契约。它们不能持有 file handle、stdout / stderr handle、telemetry sink、observer callback、event bus、public diagnostics endpoint、external artifact target、backend object、command buffer、renderer state 或 render callback。

## No-output / No-write Boundaries

当前继续默认不允许：

- real file write。
- stdout output。
- stderr output。
- telemetry。
- observer callback。
- event bus。
- public diagnostics。
- external artifact retention。
- external diagnostics export。
- backend handler。
- command buffer。
- render failure callback。
- renderer state write。

当前不允许 raw payload collection。下一步若实现 value boundary，也只能处理 dehydrated diagnostic facts / severity / retention hint。

Debug-only / local-only 只能作为 value fact / policy label 出现，不能变成真实写入、真实输出、真实本地文件或真实 artifact retention。

## Policy Dimensions For Next Boundary

下一步 no-op boundary 必须把以下维度表达为 value facts，而不是 side effect：

- privacy：只允许 privacy-safe dehydrated facts，不收集 raw payload。
- lifecycle：只说明 future sink lifecycle admission，不创建真实 sink lifecycle。
- thread-safety：只说明 future write path 需要 thread-safety gate，不创建线程、锁、队列或 callback。
- artifact policy：只说明 no external artifact / no file output，不保留 artifact。
- sampling：只作为 future sampling policy label，不采样真实 runtime stream。
- retention：只作为 retention hint，不执行 retention。
- backpressure：只作为 future backpressure policy label，不创建 queue、buffer 或 scheduler。
- rate limit：只作为 future rate limit policy label，不执行 throttling。
- failure rollback：只作为 future rollback stop-line，不写入、不回滚真实 artifact。

同时必须继续保持 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 是 no-side-effect canonical endpoint，避免误判为真实 logging / write permission。

## Candidate Comparison

### A. P1 internal Renderer real write sink no-op boundary bundle implementation

选择。

理由：

- 它是从 no-side-effect write admission 进入 real write sink runway 的最窄第一刀。
- 它只消费 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`，不读取 Queue / Action / Runtime lower-level mutable facts。
- 它新增 sink target policy、write safety gate、privacy-safe serialization policy、no-op write readiness 语义，能说明 future real write sink 的目标、安全、序列化和 no-op stop-line。
- 它仍不真实 logging / write，不创建 file / stdout / stderr / telemetry / observer / event bus / public diagnostics / artifact sink。

下一轮默认新建 `runtime_renderer_diagnostics_real_write.cj`，只输出 internal value-style no-op facts。

### B. Milestone / manifest stabilization

暂缓。

只有发现 write sink admission manifest drift、owner/truth 不清或 preflight blocker 时才选择。当前 manifest 已固定 endpoint 与 stop-line，可以进入 no-op boundary。

### C. Real write implementation

拒绝。

当前只允许打开 runway，不批准真实写入、真实输出、真实 sink lifecycle 或真实 artifact。

### D. File / stdout / stderr sink

拒绝。

当前不得写文件、stdout 或 stderr。未来若评估这些 sink，也必须先完成 no-op boundary 与后续 docs-only preflight。

### E. Telemetry / observer callback / event bus / public diagnostics

拒绝。

这些会把 internal diagnostics runway 变成外部发布、回调、事件或公开诊断，当前过早。

### F. Artifact retention / external diagnostics export

拒绝。

当前不保留 external artifact，不导出 diagnostics。local-only 只能是 policy label，不是真实本地文件或 artifact。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics write sink 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Diagnostics consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才选择。当前 evidence 指向新增 no-op policy boundary，而不是 cleanup。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics write sink runway。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

不得把 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness` 包成：

- real-write receipt。
- real-write record。
- real-write publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file sink readiness wrapper。

选择 A 的原因不是继续 tail wrapper，而是下一刀必须新增不可替代的 sink target policy、write safety gate、privacy-safe serialization policy 与 no-op write readiness 语义。

No-op write readiness 仍不是 write permission。它只表示 future real write sink boundary 可继续评估。

## Decision

最终选择：

`P1 internal Renderer real write sink no-op boundary bundle implementation`

下一轮默认 write set：

- 新建 `runtime/cjgui/src/runtime_renderer_diagnostics_real_write.cj`。
- 只消费 `CjguiInternalRendererDiagnosticsNoSideEffectWriteReadiness`。
- 只输出 internal value-style real-write intent / sink target policy / write safety gate / privacy-safe serialization policy / no-op write readiness facts。
- 更新 README / GUI_TASK_TRACKER / docs/plans README / runtime README / relevant diagnostics manifests / closure。
- 不回塞 `runtime_renderer_diagnostics_write_sink.cj`。
- 不触碰 `runtime_state.cj`。

## Stop-line

下一轮继续禁止：

- no real logging / write implementation。
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

## Verification Plan

本轮 docs-only preflight 的验证口径：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 可以找到本 preflight 与 next opening。
- forbidden check：确认没有 `.cj` runtime code diff，未触碰 protected paths。
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)` 记录 risk 与 affected processes。
- 不运行 `cjpm build` / smoke。
