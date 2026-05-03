# P1 internal Renderer local debug sink policy next-boundary decision

日期：2026-05-03

状态：docs-only decision

## Context

上一轮已完成 `P1 internal Renderer local debug sink policy value boundary bundle implementation`。当前 canonical endpoint：

- `CjguiInternalRendererNoOutputDebugReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft()`

当前 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_debug.cj`

该 endpoint 只表达 local debug sink intent / debug channel policy / opt-in guard / redaction policy / no-output debug readiness value facts。

它不是 local-debug receipt / record / publication、real logging、real local debug output、file / stdout / stderr sink、telemetry、observer callback、event bus、public diagnostics、artifact retention、external diagnostics export、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮只做 docs-only decision，不修改 `.cj`，不运行 build / smoke，不批准真实 local debug output。

## Endpoint Assessment

`CjguiInternalRendererNoOutputDebugReadiness` 已足够作为当前 no-output local debug endpoint。

理由：

- owner truth 已清楚：local debug sink policy value facts。
- canonical endpoint 已清楚：`CjguiInternalRendererNoOutputDebugReadiness` / `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft()`。
- stop-line 已清楚：no logging / no output / no file / no telemetry / no observer / no public diagnostics / no external artifact。
- Same-shape Boundary Brake 已要求不得继续把 endpoint 包成 local-debug receipt / record / publication。
- 如果未来靠近真实 local debug output，必须先 docs-only preflight，不能直接 implementation。

## Candidate Comparison

### A. P1 internal Renderer local debug sink policy manifest stabilization bundle implementation

选择。

理由：

- 当前 endpoint 已足够，下一步应固定 owner / truth / canonical endpoint / stop-line。
- Manifest stabilization 可以防止 local debug policy 后继续增长 receipt / record / publication 同构尾巴。
- 它仍是 docs / manifest stabilization，不实现真实 logging、debug output、file sink、stdout / stderr、telemetry、observer callback、event bus 或 public diagnostics。

### B. Local debug output preflight

暂缓。

需要等 manifest 固定后再评估。未来若开启，也必须是 docs-only preflight，评估 privacy、lifecycle、thread-safety、artifact、debug-only、local-only、opt-in、redaction、sampling、retention、backpressure 与 failure rollback stop-line。

### C. Local debug hardening

暂缓。

只有发现 opt-in guard、redaction policy、no-output readiness 或 stop-line 表达不足时才选择。当前 closure 已能说明 debug channel / opt-in / redaction / no-output 语义，没有 hardening blocker。

### D. Local-debug receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。它不会新增 owner truth、consumer、integration 或风险证据。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 no-output local debug endpoint 不批准真实 logging、telemetry、observer callback、event bus 或 public diagnostics。

### F. File / stdout / stderr / artifact sink

拒绝。

当前不写文件、不打 stdout / stderr、不保留 external artifact，也不输出 serialized payload。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Local debug policy endpoint 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render failure callback 或 render permission。

### H. Consolidation

暂缓。

只有发现明确 duplicate projection、low-value helper、self-wrapping helper 或 dead helper evidence 时才选择。当前没有 consolidation blocker。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些属于 renderer / UI system 后续方向，不属于 diagnostics local debug policy decision。

### J. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

本轮明确认定：

- `CjguiInternalRendererNoOutputDebugReadiness` 已经是当前 no-output local debug endpoint。
- 不批准新增 local-debug receipt / record / publication。
- 不批准把 no-output readiness 解释成 logging readiness、file sink readiness、stdout / stderr readiness、telemetry readiness、observer readiness、event bus readiness 或 public diagnostics readiness。
- 若未来靠近真实 local debug output，必须先 docs-only preflight，不能直接实现。

## Decision

最终选择：

`P1 internal Renderer local debug sink policy manifest stabilization bundle implementation`

下一轮默认 docs / manifest write set：

- 新增 `docs/plans/2026-05-03-p1-renderer-local-debug-sink-policy-manifest.md`。
- 新增 `docs/plans/2026-05-03-p1-internal-renderer-local-debug-sink-policy-manifest-stabilization-closure-review.md`。
- 更新 README / GUI_TASK_TRACKER / docs/plans README / runtime README / relevant upstream diagnostics manifest。
- 不修改 `.cj`。
- 不触碰 `runtime_state.cj`。

## Stop-line

下一轮继续禁止：

- no runtime code。
- no `.cj` edits。
- no real logging / local debug output implementation。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file / stdout / stderr output。
- no external artifact retention。
- no external diagnostics export。
- no raw payload collection。
- no serialized payload output。
- no backend handler / render failure callback。
- no backend packet / backend submission。
- no command buffer。
- no renderer state write。
- no render permission。
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
