# P1 Renderer diagnostics output sink admission next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

Renderer diagnostics output sink admission boundary 已完成 implementation closure。

当前 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_output.cj`

当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft()`

当前 truth：

- diagnostics output sink intent facts。
- diagnostics output channel policy facts。
- privacy admission facts。
- artifact guard facts。
- no-write readiness facts。

这些 facts 只表示 future diagnostics output admission boundary 可继续评估。它们不是真实 output sink、logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、external artifact retention、backend handler、command buffer、renderer state write 或 render permission。

本轮不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Endpoint Assessment

`CjguiInternalRendererDiagnosticsNoWriteReadiness` 已足够作为当前 no-write diagnostics output admission endpoint。

理由：

- 它已经收束 output sink intent / output channel policy / privacy admission / artifact guard。
- 它明确表达 no-write readiness，只允许 future boundary 继续评估。
- 它保留 defer-only 与 fail-closed blocked / inconsistent 分支语义。
- 它只允许 dehydrated diagnostic facts / severity / retention hint，不允许 raw payload collection。
- 它不授予真实 output、logging permission、telemetry permission、observer callback permission、public diagnostics permission、backend permission、command buffer readiness 或 render permission。

因此下一步应先做 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line，避免继续沿着 output receipt / record / publication 自包。

## Candidate Comparison

### A. P1 internal Renderer diagnostics output sink admission manifest stabilization bundle implementation

选择。

理由：

- `CjguiInternalRendererDiagnosticsNoWriteReadiness` 已经是当前 endpoint，下一步价值在于固定 output admission owner / truth / canonical endpoint / stop-line。
- Manifest 可以防止 future diagnostics runway 被误读成真实 output sink、logging readiness、telemetry readiness、observer readiness、event bus readiness、public diagnostics readiness 或 file sink readiness。
- Manifest 能明确下一阶段若靠近真实 write sink，必须先 docs-only preflight，而不是直接 implementation。

### B. Output sink write preflight

暂缓。

真实 write sink runway 更靠近 logging / artifact / privacy / lifecycle / thread-safety / debug-only 边界。应先封 output admission manifest，再评估 write preflight。即便未来选择 preflight，也必须 docs-only，不得实现真实 output。

### C. Output sink hardening

暂缓。

只有发现 no-write / privacy / artifact guard facts 表达不足、字段漂移或 closure 证据缺口时才选择。当前 endpoint 已覆盖 output-channel policy、privacy admission、artifact guard 与 no-write 语义，没有明确 hardening blocker。

### D. Output receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererDiagnosticsNoWriteReadiness` 再包装成同构尾巴，缺少新的 owner truth、consumer、integration 或风险证据。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 output admission endpoint 只表达 internal value facts，不允许任何真实输出、发布、回调、遥测、event bus 或公开诊断。

### F. File / stdout / stderr / artifact sink

拒绝。

No-write readiness 明确禁止写文件、标准输出、标准错误和外部产物保留。当前不建立 artifact sink。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics output admission 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前没有明确 consolidation evidence。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics output admission endpoint closure。

### J. Public surface expansion

拒绝。

public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 decision 继续生效。

`CjguiInternalRendererDiagnosticsNoWriteReadiness` 已经是当前 no-write output admission endpoint。下一阶段不得默认新增：

- output receipt。
- output record。
- output publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file sink readiness wrapper。

如果未来靠近真实 output sink / write sink，必须先做 docs-only preflight，评估 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary 与 no-runtime-side-effect stop-line，不能直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

## Decision

最终选择：

`P1 internal Renderer diagnostics output sink admission manifest stabilization bundle implementation`

下一轮默认 docs-only write set：

- 新增 `docs/plans/2026-05-02-p1-renderer-diagnostics-output-sink-admission-manifest.md`。
- 新增 output admission manifest stabilization closure。
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant diagnostics manifest。
- 不修改 `.cj`。
- 不触碰 `runtime_state.cj`。

## Stop-line

继续禁止：

- no runtime code in this decision round。
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

## Verification Plan

本轮 docs-only decision 验证：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 能找到本 decision 与 next opening。
- forbidden check 确认本轮没有 `.cj` runtime code edits，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`。
- 不运行 build / smoke。

