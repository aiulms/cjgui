# P1 internal Renderer diagnostics sink policy manifest stabilization closure review

日期：2026-05-02

状态：docs-only manifest stabilization closure

## Scope

本轮把 `runtime_renderer_diagnostics_sink.cj` 的 no-output sink policy endpoint 封为 manifest。

新增文档：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-sink-policy-manifest.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-sink-policy-manifest-stabilization-closure-review.md`

同步更新：

- `/Users/jiangxuanyang/Desktop/cangjie/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-policy-manifest.md`

本轮未修改 `.cj` 文件，未运行 build / smoke。

## Manifest Conclusion

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`

Canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

Current truth：

- internal diagnostics sink intent facts。
- internal diagnostics sink policy facts。
- privacy guard facts。
- lifecycle guard facts。
- no-output readiness value facts。

No-output readiness 明确不是 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、backend handler、command buffer、renderer state write、render permission 或真实 output sink。

当前只允许 dehydrated diagnostic facts / severity / retention hint，不收集 raw payload，不承诺 external artifact retention。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 manifest 封账生效。

本轮明确拒绝继续新增：

- sink receipt。
- sink record。
- sink publication。
- output readiness wrapper。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

`CjguiInternalRendererDiagnosticsNoOutputReadiness` 已经是当前 no-output sink policy endpoint。继续包装将只形成 same-shape thin wrapper，不增加 owner truth、consumer、integration 或风险证据。

## Candidate Comparison

### A. P1 internal Renderer diagnostics output sink preflight decision

选择。

Manifest 已固定 sink policy endpoint；如果下一步靠近真实 output sink，必须先 docs-only preflight，评估 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary 与 no-runtime-side-effect stop-line。

### B. Diagnostics sink hardening

暂缓。

只有发现 no-output / privacy / lifecycle 表达不足时才开。当前 manifest 已覆盖 endpoint truth 与 stop-line。

### C. Consolidation

暂缓。

只有发现 duplicate projection、low-value helper 或 self-wrapping evidence 时才开。当前没有明确 cleanup blocker。

### D. Sink receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 要阻止的 thin wrapper。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 endpoint 仍是 no-output value facts，不批准真实输出。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前不写文件、不打 stdout / stderr、不保留外部 artifact。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Diagnostics sink policy 不属于 backend 或 renderer execution。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

不属于 diagnostics sink policy manifest closure。

### I. Public surface expansion

拒绝。

public allowlist 不变。

## Verification

已完成：

- `git diff --check` 通过。
- Markdown absolute link missing target check 通过：project docs scope 覆盖 README / GUI_TASK_TRACKER / runtime README / `docs/plans`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check 通过，均可找到本 manifest / closure / next opening。
- forbidden check 通过：没有 `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 通过：唯一 declaration-level public symbol 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)` 已运行：risk level `low`，affected processes `0`。
- 本轮按 docs-only 要求未运行 `cjpm build` / smoke。

## Next Opening

唯一 next opening：

`P1 internal Renderer diagnostics output sink preflight decision`

下一轮必须仍是 docs-only preflight。它只评估是否可以打开真实 output sink runway，不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。
