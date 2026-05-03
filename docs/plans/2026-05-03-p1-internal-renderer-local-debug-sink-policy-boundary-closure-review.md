# P1 internal Renderer local debug sink policy boundary closure review

日期：2026-05-03

状态：runtime value boundary implementation closure

说明：本 closure 使用当前执行日期 `2026-05-03` 前缀；其上游 preflight / manifest 属于同一 P1 renderer diagnostics 文档串，仍保留既有 `2026-05-02` 文件名前缀。

## Scope

本轮新增 internal-only owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_debug.cj`

该 owner 只消费：

- `CjguiInternalRendererDiagnosticsNoOpWriteReadiness`

当前 canonical endpoint：

- `CjguiInternalRendererNoOutputDebugReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft()`

本轮同步更新 README / tracker / plans index / runtime README / upstream no-op manifest。未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。

## Landed Symbols

- `CjguiInternalRendererLocalDebugSinkIntent`
- `CjguiInternalRendererDebugChannelPolicy`
- `CjguiInternalRendererDebugOptInGuard`
- `CjguiInternalRendererDebugRedactionPolicy`
- `CjguiInternalRendererNoOutputDebugReadiness`
- `cjguiInternalBuildRendererLocalDebugSinkIntent`
- `cjguiInternalBuildRendererDebugChannelPolicy`
- `cjguiInternalBuildRendererDebugOptInGuard`
- `cjguiInternalBuildRendererDebugRedactionPolicy`
- `cjguiInternalBuildRendererNoOutputDebugReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft`

## Boundary Result

`runtime_renderer_diagnostics_local_debug.cj` 把 no-op write endpoint 投影为 local debug sink policy value facts：

- local debug sink intent facts。
- debug channel policy facts。
- opt-in guard facts。
- redaction policy facts。
- no-output debug readiness facts。

Open path：上游 no-op write readiness 为 ready / open 且未 defer / block / inconsistent 时，形成 no-output debug readiness facts。

Defer-only path：保持 defer，不伪造 debug readiness。

Blocked / inconsistent path：fail-closed blocked，不伪造真实调试输出许可。

## Stop-line

`CjguiInternalRendererNoOutputDebugReadiness` 不是：

- local-debug receipt / record / publication。
- real logging。
- real local debug output。
- file / stdout / stderr sink。
- telemetry。
- observer callback。
- event bus。
- public diagnostics。
- artifact retention。
- external diagnostics export。
- backend handler。
- command buffer。
- renderer state write。
- render failure callback。
- render permission。

当前只允许 dehydrated diagnostic facts / severity / retention hint 继续作为 value facts 被描述。`DebugRedactionPolicy` 也不收集 raw payload，不产生真实 serialization output。

## Same-shape Boundary Brake

本轮不是把 `CjguiInternalRendererDiagnosticsNoOpWriteReadiness` 再包成 receipt / record / publication。

Brake 生效点：

- `DebugChannelPolicy` 固定 future debug channel 只能是 value-style policy，不是通道实现。
- `DebugOptInGuard` 固定 future opt-in requirement，不读取 runtime flag，也不写全局开关。
- `DebugRedactionPolicy` 固定 dehydrated diagnostic facts 的 redaction 口径，不捕获 raw payload。
- `NoOutputDebugReadiness` 固定 no-output endpoint，不是 logging readiness、file sink readiness、stdout / stderr readiness 或 public diagnostics readiness。

如果下一轮靠近真实 local debug output，必须先做 docs-only decision；不得直接实现 logging、telemetry、observer callback、event bus、public diagnostics、file sink、stdout / stderr 或 artifact retention。

## GitNexus

按要求对入口 symbol 做 impact：

- `CjguiInternalRendererDiagnosticsNoOpWriteReadiness`：GitNexus 返回 `UNKNOWN / not found`，impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererDiagnosticsRealWriteNoOpDraft`：GitNexus 返回 `UNKNOWN / not found`，impactedCount `0`。

原因按近期新增 owner symbol 未索引处理。本轮用源码存在、构建、forbidden scan、public declaration scan 和 `detect_changes(scope=unstaged)` 兜底。

## Verification

本 closure 已完成验证：

- `cjpm build --target-dir /tmp/cjgui-renderer-local-debug-sink-policy-boundary-target --skip-script`：通过；仅保留既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed。
- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- closure reachability check：README / GUI_TASK_TRACKER / docs/plans README / runtime README 可找到 closure 与 next opening。
- forbidden check：protected paths 无 tracked diff，`runtime_state.cj` 仍为 10065 行。
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line source scan：new owner 不出现真实 output / callback / external artifact / backend / command buffer / public / mutable-state implementation token。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，affected processes `0`。

## Next Opening

唯一 next opening：

`P1 internal Renderer local debug sink policy closure / next local debug decision`

下一轮必须先判断 `CjguiInternalRendererNoOutputDebugReadiness` 是否已足够作为当前 no-output local debug endpoint；不得直接新增 local-debug receipt / record / publication，也不得直接实现真实 local debug output。
