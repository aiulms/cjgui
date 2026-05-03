# P1 internal Renderer local debug output admission boundary closure review

日期：2026-05-03

状态：implementation closure

## Scope

本轮执行：

`P1 internal Renderer local debug output admission value boundary bundle implementation`

新增 runtime owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`

唯一输入：

- `CjguiInternalRendererNoOutputDebugReadiness`

Canonical endpoint：

- `CjguiInternalRendererNoWriteLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft()`

本轮没有修改 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有触碰 smoke / harness / native bridge / entry / AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Added Internal Symbols

- `CjguiInternalRendererLocalDebugOutputIntent`
- `CjguiInternalRendererLocalOutputTargetPolicy`
- `CjguiInternalRendererLocalDebugOptInAdmission`
- `CjguiInternalRendererLocalDebugRedactionReadiness`
- `CjguiInternalRendererNoWriteLocalOutputReadiness`
- `cjguiInternalBuildRendererLocalDebugOutputIntent`
- `cjguiInternalBuildRendererLocalOutputTargetPolicy`
- `cjguiInternalBuildRendererLocalDebugOptInAdmission`
- `cjguiInternalBuildRendererLocalDebugRedactionReadiness`
- `cjguiInternalBuildRendererNoWriteLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft`

所有符号保持 package-internal 默认可见性；没有新增 public symbol，没有 `var` 或 module-level mutable state，没有 C ABI / native handle / raw pointer。

## Boundary Result

本 owner 将 no-output local debug endpoint 投影为以下 internal value facts：

- local debug output intent。
- output target policy。
- opt-in admission。
- redaction readiness。
- no-write output readiness。

Open path 只在 `CjguiInternalRendererNoOutputDebugReadiness` 已 ready / open，且未 defer、未 blocked、未 inconsistent 时打开。Defer-only path 保持 defer，不伪造 readiness。Blocked / inconsistent path 一律 fail-closed blocked。

`CjguiInternalRendererNoWriteLocalOutputReadiness` 的 ready 只表示 future local debug output admission boundary 可以继续评估。它不是 output permission，不是真实 debug output，不是 logging subsystem，不写文件 / stdout / stderr，不触发 telemetry / observer callback / event bus / public diagnostics，不保留 external artifact，也不接 backend handler / command buffer / renderer state write / render failure callback / render permission。

当前只允许处理 dehydrated diagnostic facts / severity / retention hint；不允许 raw payload collection 或真实 serialization output。

## Same-shape Boundary Brake

本轮没有新增 local-output receipt / record / publication。

选择 implementation 的理由不是继续包装 `CjguiInternalRendererNoOutputDebugReadiness`，而是新增了不可替代的 admission vocabulary：

- output target policy：只描述 future output target policy，不是 target implementation。
- opt-in admission：只表达 future opt-in admission，不是 runtime flag / global switch。
- redaction readiness：只处理 dehydrated diagnostic facts / severity / retention hint，不收集 raw payload。
- no-write output readiness：明确当前没有真实 output sink。

这些 facts 固定 future local debug output runway 的 opt-in / redaction / privacy / lifecycle / artifact / local-only stop-line，同时继续禁止真实输出。

## GitNexus

Pre-change impact：

- `CjguiInternalRendererNoOutputDebugReadiness`：UNKNOWN / not found。
- `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft`：UNKNOWN / not found。

处理结论：

- 这两个入口属于近期新增 owner symbol，当前 GitNexus index 尚未覆盖。
- 未出现 HIGH / CRITICAL risk。
- 本轮采用源码存在检查、`cjpm build`、smoke guard、forbidden scan 与 `detect_changes(scope=unstaged)` 兜底。

## Verification

已执行：

- `PATH="/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin:/Users/jiangxuanyang/cangjie-toolchains/cangjie/bin:$PATH" cjpm build --target-dir /tmp/cjgui-renderer-local-debug-output-admission-boundary-target --skip-script`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`

结果：

- build 通过；仅保留既有 unused warnings。
- smoke guard 通过。

最终同步检查：

- `git diff --check` 通过。
- Markdown absolute link missing target check 通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 均可找到本 closure 与 next opening。
- forbidden check 通过：未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line source scan 通过：新 owner 未出现真实 logging / telemetry / observer callback / event bus / public diagnostics / file output / stdout / stderr / artifact retention / backend / command buffer / render execution / C ABI / native handle / raw pointer / declaration-level public / module-level var。
- GitNexus `detect_changes(scope=unstaged)`：risk low，affected processes 为空。

## Next Opening

唯一 next opening：

`P1 internal Renderer local debug output admission closure / next local output decision`

下一轮必须是 docs-only decision。默认先判断 `CjguiInternalRendererNoWriteLocalOutputReadiness` 是否足够作为当前 no-write local output endpoint，以及是否应进入 manifest stabilization；不得直接实现真实 local debug output / logging / telemetry / observer callback / event bus / public diagnostics / file sink。
