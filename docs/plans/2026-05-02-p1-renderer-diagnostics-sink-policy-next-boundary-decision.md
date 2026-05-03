# P1 Renderer diagnostics sink policy next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

Renderer diagnostics sink policy boundary 已完成 implementation closure。

当前 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`

当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

当前 truth：

- diagnostics sink intent facts。
- diagnostics sink policy facts。
- privacy guard facts。
- lifecycle guard facts。
- no-output readiness facts。

这些 facts 只表示 future diagnostics sink policy boundary 可继续评估。它们不是真实 output sink、logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr output、external artifact retention、backend handler、command buffer、renderer state write 或 render permission。

本轮不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Endpoint Assessment

`CjguiInternalRendererDiagnosticsNoOutputReadiness` 已足够作为当前 no-output sink policy endpoint。

理由：

- 它已经收束 sink intent / sink policy / privacy guard / lifecycle guard。
- 它明确表达 no-output readiness，只允许 future boundary 继续评估。
- 它保留 defer-only 与 fail-closed blocked / inconsistent 分支语义。
- 它不收集 raw payload，只允许 dehydrated diagnostic facts / severity / retention hint。
- 它不授予真实 output、render permission、backend permission 或 command buffer readiness。

因此下一步应先做 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line，避免继续沿着 sink receipt / record / publication 自包。

## Candidate Comparison

### A. P1 internal Renderer diagnostics sink policy manifest stabilization bundle implementation

选择。

理由：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness` 已经是当前 endpoint，下一步价值在于固定 sink policy owner / truth / canonical endpoint / stop-line。
- Manifest 可以防止 future diagnostics runway 被误读成真实 output sink、logging readiness、telemetry readiness、observer readiness 或 public diagnostics readiness。
- Manifest 能明确下一阶段若靠近真实 output sink，必须先 docs-only preflight，而不是直接 implementation。

### B. Diagnostics sink output preflight

暂缓。

真实 output sink runway 更靠近 logging / artifact / lifecycle / thread-safety / privacy 边界。应先封 sink policy manifest，再评估 output sink preflight。即便未来选择 preflight，也必须 docs-only，不得实现 output。

### C. Diagnostics sink hardening

暂缓。

只有发现 no-output / privacy / lifecycle facts 表达不足、字段漂移或 closure 证据缺口时才选择。当前 endpoint 已覆盖 sink / privacy / lifecycle / no-output 语义，没有明确 hardening blocker。

### D. Sink receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererDiagnosticsNoOutputReadiness` 再包装成同构尾巴，缺少新的 owner truth、consumer、integration 或风险证据。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 sink policy endpoint 只表达 internal value facts，不允许任何真实输出、发布、回调、遥测或公开诊断。

### F. File / stdout / stderr / artifact sink

拒绝。

No-output readiness 明确禁止写文件、标准输出、标准错误和外部产物保留。当前不建立 artifact sink。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics sink policy 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前没有明确 consolidation evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 decision 继续生效。

`CjguiInternalRendererDiagnosticsNoOutputReadiness` 已经是当前 no-output sink policy endpoint。下一阶段不得默认新增：

- sink receipt。
- sink record。
- sink publication。
- output readiness wrapper。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

如果未来靠近真实 output sink，必须先做 docs-only preflight，评估 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary 与 no-runtime-side-effect stop-line，不能直接实现 logging / telemetry / observer callback / event bus / public diagnostics。

## Decision

最终选择：

`P1 internal Renderer diagnostics sink policy manifest stabilization bundle implementation`

下一轮默认 docs-only write set：

- 新增 `docs/plans/2026-05-02-p1-renderer-diagnostics-sink-policy-manifest.md`。
- 新增 sink policy manifest stabilization closure。
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
- forbidden check 确认没有 `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`。
- 不运行 build / smoke。
