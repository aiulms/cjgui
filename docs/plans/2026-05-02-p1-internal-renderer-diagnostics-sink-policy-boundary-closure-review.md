# P1 internal Renderer diagnostics sink policy boundary closure review

日期：2026-05-02

状态：runtime value boundary implementation closure

## Scope

本轮新增 internal-only Renderer diagnostics sink policy owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_sink.cj`

该 owner 只消费：

- `CjguiInternalRendererDiagnosticsPolicyResult`

Canonical endpoint：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

## Landed Symbols

新增 internal value-style types：

- `CjguiInternalRendererDiagnosticsSinkIntent`
- `CjguiInternalRendererDiagnosticsSinkPolicy`
- `CjguiInternalRendererDiagnosticsPrivacyGuard`
- `CjguiInternalRendererDiagnosticsLifecycleGuard`
- `CjguiInternalRendererDiagnosticsNoOutputReadiness`

新增 builders / default draft：

- `cjguiInternalBuildRendererDiagnosticsSinkIntent`
- `cjguiInternalBuildRendererDiagnosticsSinkPolicy`
- `cjguiInternalBuildRendererDiagnosticsPrivacyGuard`
- `cjguiInternalBuildRendererDiagnosticsLifecycleGuard`
- `cjguiInternalBuildRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft`

## Boundary Conclusion

本轮只建立 no-output diagnostics sink policy value boundary：

- open path：从 diagnostics policy result 形成 sink intent / sink policy / privacy guard / lifecycle guard / no-output readiness facts。
- defer-only：保持 defer，不伪造 sink readiness。
- blocked / inconsistent：fail-closed blocked。
- no-output readiness 只表示 future sink policy boundary 可继续评估，不代表允许输出诊断、写外部介质、触发事件、保留外部产物、写 renderer state 或获得 render permission。
- payload policy 仍只允许 dehydrated diagnostic facts / severity / retention hint，不收集原始 payload。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效点：

- 本轮没有新增 sink receipt / record / publication。
- 新 owner 的不可替代语义是 sink intent、no-output policy、privacy guard、lifecycle guard 和 no-output readiness。
- 这些 facts 不是把 `CjguiInternalRendererDiagnosticsPolicyResult` 换名包装；它们固定了 future diagnostics sink runway 在 no-output、privacy、lifecycle 和 no-side-effect 维度的入口契约。

## Stop-line

继续禁止：

- no logging subsystem。
- no telemetry。
- no observer callback。
- no event bus。
- no public diagnostics。
- no file output / stdout / stderr。
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

## GitNexus

Pre-edit impact:

- `CjguiInternalRendererDiagnosticsPolicyResult`: `UNKNOWN / not found`。
- `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft`: `UNKNOWN / not found`。

说明：近期新增 owner symbols 尚未被 GitNexus 索引；本轮按源码存在、build、smoke、forbidden scan 和 `detect_changes(scope=unstaged)` 兜底。

`detect_changes(scope=unstaged)`：

- risk level: `low`
- affected processes: `0`
- changed indexed symbols: docs / README sections only。
- 说明：new owner file symbols 尚未进入 GitNexus index，本轮以 build、smoke、source scan 和 forbidden scan 兜底。

## Verification

已完成：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-diagnostics-sink-policy-boundary-target --skip-script` 通过；仅保留既有 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。
- Markdown absolute link missing target check 通过。
- closure reachability check 通过：README / GUI_TASK_TRACKER / docs/plans README 均可找到本 closure 与 next opening。
- forbidden check 通过：未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 通过：唯一 declaration-level public symbol 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line source scan 通过：new owner 未出现真实输出 / platform / command / render / C ABI / handle / pointer / declaration-level public / module-level var 违禁命名。
- GitNexus `detect_changes(scope=unstaged)` 已运行，risk level `low`，affected processes `0`。

## Next Opening

唯一 next opening：

`P1 internal Renderer diagnostics sink policy closure / next diagnostics sink decision`

下一轮应先 docs-only 判断该 endpoint 是否需要 manifest stabilization，或是否存在真正新增语义的 diagnostics sink policy hardening。不得直接实现 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr output、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。
