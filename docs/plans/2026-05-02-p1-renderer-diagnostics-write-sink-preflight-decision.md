# P1 Renderer diagnostics write sink preflight decision

日期：2026-05-02

状态：docs-only preflight decision

## Context

Renderer diagnostics output sink admission manifest 已封账。

当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft()`

当前 truth：

- internal diagnostics output sink intent facts。
- internal diagnostics output channel policy facts。
- internal diagnostics privacy admission facts。
- internal diagnostics artifact guard facts。
- no-write readiness value facts。

这些 facts 只表示 future diagnostics write sink runway 可以继续评估。它们不是真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮只做 docs-only preflight，不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Preflight Conclusion

允许打开 diagnostics write sink runway，但下一步只能做 internal value boundary，不是真实写入或输出实现。

默认下一步 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_write_sink.cj`

默认输入：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`

默认 output truth 只能是：

- write sink intent value facts。
- write channel admission value facts。
- privacy-safe payload policy value facts。
- local-only artifact policy value facts。
- no-side-effect write readiness value facts。

该 truth 只能表达 future write sink 的内部 admission contract。它不能变成 logging writer、file writer、stdout / stderr writer、telemetry emitter、observer callback、event bus publisher、public diagnostics exporter、external artifact retention owner、backend handler、command buffer owner、renderer state writer 或 render failure callback。

## Boundary Answers

- 是否允许打开 write sink runway：允许，但只能先做 value boundary，不批准真实写入 / 输出实现。
- owner 是否应新建：是，默认新建 `runtime_renderer_diagnostics_write_sink.cj`，避免回塞 output admission owner。
- input 是否只消费 `CjguiInternalRendererDiagnosticsNoWriteReadiness`：是，下一刀不读取 Queue / Action / Runtime lower-level mutable facts。
- output truth 是否只能是 write sink intent / write channel admission / privacy-safe payload policy / local-only artifact policy / no-side-effect write readiness：是。
- 是否允许真实文件、stdout、stderr、telemetry、observer callback、event bus、public diagnostics、external artifact retention：默认全部不允许。
- 是否允许 raw payload：不允许；只允许 dehydrated diagnostic facts / severity / retention hint。
- 是否允许 debug-only / local-only：只允许作为 value fact / policy label，不允许真实写入或输出。
- privacy / lifecycle / thread-safety / artifact policy / sampling / retention / backpressure：只能表达为 value facts、guard facts 或 blocked reasons，不得驱动真实 sink、thread、buffer、queue、scheduler、artifact store 或 retry loop。
- 是否仍保持 no-write canonical endpoint：是。`CjguiInternalRendererDiagnosticsNoWriteReadiness` 在下一轮 implementation 前仍是 current canonical endpoint，不能被误读为 logging permission、write permission 或 file sink readiness。

## Candidate Comparison

### A. P1 internal Renderer diagnostics write sink admission value boundary bundle implementation

选择。

理由：

- 它能新增 write-channel admission、privacy-safe payload policy、local-only artifact policy 与 no-side-effect write readiness 语义。
- 它不是把 `CjguiInternalRendererDiagnosticsNoWriteReadiness` 包成 receipt / record / publication。
- 它仍保持 no real output：不写文件、不打 stdout / stderr、不发 telemetry、不调用 observer、不发布 event bus、不创建 public diagnostics、不保留 external artifact。
- 它为未来如果真的评估 write sink implementation 留下 owner / privacy / lifecycle / thread-safety / artifact / sampling / retention / backpressure vocabulary。

### B. Milestone / manifest stabilization

暂缓。

只有发现 no-write output admission manifest drift、canonical endpoint 不清楚或 preflight blocker 时才选择。当前 manifest 已固定 owner / truth / endpoint / stop-line，没有 blocker。

### C. Write sink implementation

拒绝。

当前只能打开 runway 的 internal value boundary，不能实现真实 logging、写文件、stdout / stderr、事件发布或外部 artifact。

### D. File / stdout / stderr sink

拒绝。

下一步不得写文件、stdout 或 stderr，也不得建立 file sink owner。

### E. Telemetry / observer callback / event bus / public diagnostics

拒绝。

下一步不发 telemetry、不调用 observer、不接 event bus、不创建 public diagnostics。

### F. Artifact retention / external diagnostics export

拒绝。

下一步只允许 local-only artifact policy value facts，不允许 external artifact retention 或 diagnostics export。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics write sink runway 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Diagnostics consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前没有明确 consolidation evidence。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics write sink preflight。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 preflight 继续生效。

不得把 `CjguiInternalRendererDiagnosticsNoWriteReadiness` 包成：

- write receipt。
- write record。
- write publication。
- logging readiness wrapper。
- file sink readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。

选择 A 的前提是下一轮必须引入 write-channel admission、privacy-safe payload policy、local-only artifact policy 与 no-side-effect readiness 语义。若实现只是在 `NoWriteReadiness` 后面加 receipt / record / publication，则必须拒绝并转向 consolidation 或 milestone。

## Stop-line

继续禁止：

- no runtime code in this preflight round。
- no `.cj` edits。
- no real write sink implementation。
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

## Decision

最终选择：

`P1 internal Renderer diagnostics write sink admission value boundary bundle implementation`

下一轮允许新增 internal-only runtime owner file，但仍不得实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr / external artifact retention。默认 owner 是 `runtime_renderer_diagnostics_write_sink.cj`，默认只消费 `CjguiInternalRendererDiagnosticsNoWriteReadiness`，输出 write sink intent / write channel admission / privacy-safe payload policy / local-only artifact policy / no-side-effect write readiness value facts。

## Verification Plan

本轮 docs-only preflight 验证：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 能找到本 preflight 与 next opening。
- forbidden check 确认本轮没有 `.cj` runtime code edits，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`。
- 不运行 build / smoke。
