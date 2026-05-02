# P1 Renderer diagnostics sink preflight decision

日期：2026-05-02

状态：docs-only preflight

## Context

Renderer diagnostics policy 已完成 manifest stabilization。

当前 canonical upstream endpoint：

- `CjguiInternalRendererDiagnosticsPolicyResult`
- `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()`

当前 upstream owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_policy.cj`

当前 upstream truth：

- internal diagnostics policy facts。
- diagnostic severity handling policy facts。
- diagnostic retention hint facts。
- no-logging / no-telemetry / no-observer / no-public-diagnostics value facts。
- no file write / no stdout / no event publication / no external artifact retention facts。

本 preflight 只评估是否可以打开 diagnostics sink runway，不实现 sink，不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Preflight Questions

### Sink owner

可以进入新的 diagnostics sink owner，但只能作为 internal value-style owner。

推荐下一轮 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`

该 owner 只能消费：

- `CjguiInternalRendererDiagnosticsPolicyResult`

不得直接读取 Queue / Action / Runtime lower-level mutable facts，不得读取 platform object、native handle、raw pointer 或 backend state。

### Sink truth

Sink truth 只能是 internal value-style facts：

- sink intent facts。
- sink policy facts。
- privacy guard facts。
- lifecycle guard facts。
- retention guard facts。
- no-output readiness facts。

Sink truth 不是真实 logging sink、telemetry sink、observer callback、event bus、public diagnostics、exception system、backend handler、render failure callback、file writer、stdout / stderr writer、artifact owner 或 renderer state write。

### Output permission

默认不允许任何真实输出：

- no file write。
- no stdout。
- no stderr。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no external artifact retention。

No-output readiness 只表示 future sink policy boundary 可继续评估，不代表可以输出诊断。

### Payload policy

默认不允许收集 raw payload。

允许的输入形态仅限 dehydrated internal value facts：

- diagnostics policy result。
- severity handling facts。
- retention hint facts。
- privacy / lifecycle / no-output guard facts。

不得收集 platform object、native handle、raw pointer、backend packet、command buffer、renderer state、user payload、raw log payload 或 external artifact。

### Privacy / artifact / lifecycle / thread-safety / debug-only boundary

下一轮 value boundary 应显式表达：

- privacy guard：不收集 raw payload，不开放 public diagnostics，不跨边界暴露内部 evidence。
- artifact guard：不写文件、不打 stdout / stderr、不保留外部 artifact。
- lifecycle guard：不启动 sink lifecycle，不注册 callback，不创建 background worker，不创建 global mutable sink。
- thread-safety guard：不跨线程发布，不触发 observer，不接 event bus。
- debug-only guard：即便 future sink 仅用于 debug，也必须先固定 no-output readiness，不可直接写日志或导出 artifact。

### Boundary ordering

若继续 implementation，应先做：

`P1 internal Renderer diagnostics sink policy value boundary bundle implementation`

而不是直接实现 diagnostics sink。

## Candidate Comparison

### A. P1 internal Renderer diagnostics sink policy value boundary bundle implementation

选择。

理由：

- 它只消费 `CjguiInternalRendererDiagnosticsPolicyResult`，可以把 policy endpoint 投影为 sink intent / sink policy / privacy guard / lifecycle guard / no-output readiness value facts。
- 它新增的是 sink / privacy / lifecycle / no-output 语义，不是把 policy result 再包成 sink receipt / record / publication。
- 它仍不真实 logging、不写文件、不打 stdout / stderr、不发事件、不保留外部 artifact、不开放 public diagnostics。
- 它在靠近真实 diagnostics sink runway 前增加必要 stop-line，风险低于直接 sink implementation。

### B. Milestone / manifest stabilization

暂缓。

只有发现 diagnostics policy manifest drift、policy endpoint 不清或 owner / truth 不稳定时才选择。当前 manifest 已清楚固定 owner / truth / canonical endpoint / stop-line。

### C. Diagnostics sink implementation

拒绝。

真实 sink implementation 过早，会靠近 logging / output / artifact / lifecycle side effect。当前只允许 value boundary。

### D. Telemetry / observer callback / event bus / public diagnostics

拒绝。

这些都会引入外部可见或运行时 side effect，不属于 P1 sink policy preflight 的允许范围。

### E. File / stdout / stderr / artifact sink

拒绝。

本阶段禁止写文件、打 stdout / stderr、发事件或保留外部 artifact。

### F. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics sink 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback。

### G. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 manifest drift 时才选择。当前没有必须立即 consolidation 的证据。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些需要独立 owner truth，不能混入 diagnostics sink runway。

### I. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 preflight 继续生效。

不得把 `CjguiInternalRendererDiagnosticsPolicyResult` 包成：

- sink receipt。
- sink record。
- sink publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

选择 A 的前提是下一轮必须新增 sink / privacy / lifecycle / no-output 语义：

- sink intent 定义 future sink 的内部入口意图。
- sink policy 定义 no-output policy。
- privacy guard 定义 no raw payload / no public diagnostics。
- lifecycle guard 定义 no callback / no worker / no global mutable sink。
- no-output readiness 定义只能继续评估，不能输出。

如果下一轮无法表达这些新语义，应停止并转向 manifest stabilization 或 consolidation。

## Decision

最终选择：

`P1 internal Renderer diagnostics sink policy value boundary bundle implementation`

下一轮默认 write set：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant diagnostics manifest / closure。
- 不回塞 `runtime_renderer_diagnostics_policy.cj`。
- 不触碰 `runtime_state.cj`。

下一轮建议 internal symbols 可围绕：

- diagnostics sink intent。
- diagnostics sink policy。
- diagnostics privacy guard。
- diagnostics lifecycle guard。
- diagnostics no-output readiness。

具体命名可由 implementation 自主决定，但必须保持 internal-only，不新增 public symbol。

## Stop-line

继续禁止：

- no logging implementation。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no exception system / public error API。
- no file write / stdout / stderr。
- no external artifact retention。
- no raw payload collection。
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

本轮 docs-only preflight 验证：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 能找到本 preflight 与 next opening。
- forbidden check 确认未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`。
- 不运行 build / smoke。
