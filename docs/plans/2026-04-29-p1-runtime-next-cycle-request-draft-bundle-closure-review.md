# P1 Runtime Next-Cycle Request Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮在 `runtime_state.cj` 新增 internal-only / value-style runtime next-cycle request draft layer：

- `CjguiInternalRuntimeNextCycleRequestDraftRequest`
- `CjguiInternalRuntimeNextCycleRequestDraft`
- `cjguiInternalBuildRuntimeNextCycleRequestDraftRequest`
- `cjguiInternalEvaluateRuntimeNextCycleRequestDraft`
- `cjguiInternalExecuteRuntimeNextCycleRequestDraft`
- `cjguiInternalExecuteDefaultRuntimeNextCycleRequestDraft`
- `cjguiInternalRuntimeNextCycleRequestOpenSanity`
- `cjguiInternalRuntimeNextCycleRequestRuntimeBlockedSanity`
- `cjguiInternalRuntimeNextCycleRequestInputBlockedSanity`
- `cjguiInternalRuntimeNextCycleRequestShutdownBlockedSanity`
- `cjguiInternalRuntimeNextCycleRequestCancellationBlockedSanity`

## Boundary

Next-cycle request draft 只消费 `CjguiInternalRuntimeCycleFeedbackDraft`。它用 feedback 的 app/window state candidates 作为 preparation gate，并构造 value-style `CjguiInternalRuntimeCycleRequest` candidate；当前 root state shape 不承载 app/window state，因此 app/window feedback 不被写入 root state，只用于 request preparation summary。

本层不执行 `cjguiInternalExecuteRuntimeCycle`，不执行 runtime step，不执行下一轮 cycle，不写 runtime global state，不创建 global mutable singleton，不公开 state，不执行新的 lifecycle mutation，也不读取 CommittedStateStoreDraft / StateHolderDraft / lower-level facts。

## Verification

- GitNexus 窄口 impact：`runtime_state.cj` file-level risk LOW / direct callers 0 / affected processes 0；`CjguiInternalRuntimeCycleFeedbackDraft` 与 `cjguiInternalExecuteRuntimeCycleFeedbackDraft` 在当前索引中未解析到 symbol，返回 not found / UNKNOWN 而非 HIGH / CRITICAL。
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-runtime-next-cycle-request-draft-bundle-target --skip-script`：通过，仅既有 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。

## Stop-Line

这不是 real next-cycle execution，不是 runtime step execution，不是 event loop / scheduler / queue / drain，也不是 public runtime API / C ABI。它只是把 cycle feedback 转成下一轮 internal runtime cycle request candidate 的脱水 summary。

## Next Opening

`P1 runtime next-cycle request draft bundle closure / next runtime behavior decision`
