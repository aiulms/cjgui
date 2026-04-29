# P1 Runtime Cycle Replay Draft Bundle Closure Review

日期：2026-04-30

## Scope Closed

- 新增 `CjguiInternalRuntimeCycleReplayRequest` 与 `CjguiInternalRuntimeCycleReplayDraft`。
- 新增 `cjguiInternalBuildRuntimeCycleReplayRequest`、`cjguiInternalEvaluateRuntimeCycleReplay`、`cjguiInternalExecuteRuntimeCycleReplayDraft`、`cjguiInternalExecuteDefaultRuntimeCycleReplayDraft`。
- 新增 open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers。

## Boundary

- Replay draft 只消费 `CjguiInternalRuntimeCycleHandoffDraft`。
- `cycleRequestCandidate` 只来自 handoff 中已经持有的 candidate。
- `isReplayReady` 仅在 handoff 已 prepared 且没有 defer / blocked 时为 true。
- blocked / deferred path 可以继续携带 candidate value，但明确不会执行 candidate。
- 本层不调用 `cjguiInternalExecuteRuntimeCycle`，不执行 runtime step，不写 runtime global state，不创建 global mutable singleton，不执行新 mutation，不公开 state，也不读取 NextCycleRequestDraft / CycleFeedbackDraft / lower-level facts。

## GitNexus

- `runtime_state.cj` file-level impact：LOW，direct callers 0，affected processes 0。
- `CjguiInternalRuntimeCycleHandoffDraft` 与 `cjguiInternalExecuteRuntimeCycleHandoffDraft` 在当前索引中未解析到，返回 not found / UNKNOWN；未出现 HIGH / CRITICAL 风险。

## Verification

- `cjpm build --target-dir /tmp/cjgui-runtime-cycle-replay-draft-bundle-target --skip-script`：通过，仅有当前 internal scaffold 的 unused warnings。
- `verify_auto_close.sh`：通过。
- `git diff --check`：通过。

## Stop-Line

这是 internal-only / value-style replay readiness draft，不是 replay execution、runtime cycle execution、runtime step execution、event loop、queue / drain、scheduler、public API、C ABI、platform callback、global state store 或 public state publication。

## Next Opening

`P1 runtime cycle replay draft bundle closure / next runtime behavior decision`
