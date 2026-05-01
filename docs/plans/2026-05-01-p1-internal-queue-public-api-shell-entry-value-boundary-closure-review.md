# P1 internal Queue public API shell / entry value boundary closure review

日期：2026-05-01

## Opening

`P1 internal Queue public API shell / entry value boundary bundle implementation`

## Result

本轮新增 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_api_shell.cj`

新增 internal-only API shell symbols：

- `CjguiInternalQueuePublicApiShell`
- `CjguiInternalQueuePublicSubmissionEntry`
- `CjguiInternalQueuePublicEntryResult`
- `CjguiInternalQueuePublicEntryResultHandoff`
- `cjguiInternalBuildQueuePublicApiShell`
- `cjguiInternalBuildQueuePublicSubmissionEntry`
- `cjguiInternalBuildQueuePublicEntryResult`
- `cjguiInternalBuildQueuePublicEntryResultHandoff`
- `cjguiInternalExecuteDefaultQueuePublicApiShellDraft`

## Consumed Endpoint

本轮只消费：

- `CjguiInternalQueuePublicCompatibilityNote`
- 默认 draft 只调用 `cjguiInternalExecuteDefaultQueuePublicResultShapeDraft()`，再串联 API shell / submission entry / entry result / result handoff pipeline。

本轮没有修改 `runtime_queue_public_result.cj`，没有回塞 public result shape owner 的 thin tail，也没有修改 `runtime_state.cj`。

## Behavior Boundary

Open path:

- `CjguiInternalQueuePublicCompatibilityNote` prepared / acceptable。
- No defer / no block / no reject / no incompatible / no unauthorized。
- 明确当前没有 stable public API compatibility promise。
- 形成 internal-only API shell、submission entry、entry result、result handoff value facts。

Defer-only path:

- 保持 defer。
- 不伪造 API shell ready 或 entry success。

Blocked / rejected / incompatible / unauthorized / inconsistent path:

- fail-closed blocked 或投影为 rejected / incompatible / unauthorized value facts。
- Entry result 只投影 result envelope / error projection / audit reference / compatibility note，不暴露 lower-level owner facts。

Stop-line:

- 未新增 `public` 修饰符。
- 未实现 public runtime API function。
- 未实现 public C ABI。
- 未 real enqueue。
- 未使用 `enqueue` 命名。
- 不接收 raw pointer / native handle / platform object。
- 不写 process-wide queue storage。
- 不创建 global mutable queue / singleton。
- 不做 item collection mutation。
- 不 drain。
- 不接 scheduler / event loop / platform callback / runtime cycle。
- 不写 runtime global state。
- 不触碰 `runtime_state.cj`。
- 不新增 module-level `var`。

## GitNexus

Impact analysis:

- `CjguiInternalQueuePublicCompatibilityNote`: UNKNOWN / not found，impacted count 0，risk UNKNOWN。
- `cjguiInternalExecuteDefaultQueuePublicResultShapeDraft`: UNKNOWN / not found，impacted count 0，risk UNKNOWN。
- Fallback evidence：两个入口 symbols 均在 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_result.cj` 中直接存在；本轮只新增 downstream owner file，未修改入口 owner。
- 未发现 HIGH / CRITICAL risk。

Detect changes:

- `gitnexus_detect_changes(scope=unstaged)` 已运行。
- 新 owner file symbols 尚未索引时可能显示 UNKNOWN / not found；记录为可接受 fallback。

## Verification

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-queue-public-api-shell-entry-value-boundary-target --skip-script`：通过，仅保留既有 internal skeleton unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- Markdown 绝对链接 missing target 检查：通过。
- Closure link 可从 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md` 与 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md` 找到。
- Forbidden 检查：未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`src/main.cj`、`package_anchor.cj`、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- Extra API shell 检查：`runtime_queue_public_api_shell.cj` 未出现 declaration-level `public` 修饰符，未出现 `enqueue` 命名，未出现 raw pointer / native handle intake。

## Next Opening

`P1 internal Queue public API shell closure / next public API exposure preflight decision`

下一轮性质应为 docs-only decision。它应比较 public API exposure preflight、internal API shell handoff / publication candidate、milestone / manifest stabilization、direct public runtime API implementation、public C ABI、real enqueue、drain / scheduler / event loop 与 runtime-state integration。

默认建议先评估 public API exposure preflight，而不是直接实现 public API。下一轮仍不得新增 `public` 修饰符，不得实现 public runtime API / C ABI，不得 real enqueue，不得写 process-wide queue storage，不得接 drain / scheduler / event loop / runtime cycle，不得触碰 critical `runtime_state.cj`。
