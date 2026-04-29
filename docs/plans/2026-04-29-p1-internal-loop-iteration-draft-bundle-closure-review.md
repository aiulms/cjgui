# P1 Internal Loop Iteration Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 internal loop iteration draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 internal-only types：

- `CjguiInternalLoopIterationDraftRequest`
- `CjguiInternalLoopIterationDraftIntent`
- `CjguiInternalLoopIterationDraftReport`

新增 internal-only functions：

- `cjguiInternalBuildLoopIterationDraftRequest`
- `cjguiInternalBuildLoopIterationDraftIntent`
- `cjguiInternalEvaluateLoopIterationDraft`
- `cjguiInternalExecuteLoopIterationDraft`
- `cjguiInternalExecuteDefaultLoopIterationDraft`
- `cjguiInternalLoopIterationDraftOpenSanity`
- `cjguiInternalLoopIterationDraftRuntimeBlockedSanity`
- `cjguiInternalLoopIterationDraftInputBlockedSanity`
- `cjguiInternalLoopIterationDraftShutdownBlockedSanity`
- `cjguiInternalLoopIterationDraftCancellationBlockedSanity`

## Behavior Summary

LoopIterationDraft 只消费 `CjguiInternalRunLoopDraftReport`，并只读取 `loopDraftReport.intent`。它把 RunLoopDraft intent 的 enter-loop / defer-loop / blocked-loop / future-boundary signals 投影为 single-iteration intent summary。

Open path 会构建 attempt-iteration 与 future-boundary request summary；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked path 都 fail closed，并生成 defer-iteration / blocked-iteration summary。

## Verification

- Build：`source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-loop-iteration-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 real event loop，未写 `while` / scheduling loop，未实现 callback binding / queue / drain，未执行 loop iteration / dispatch / `run()` / shutdown / cancellation，未创建 window，未新增 handle table / generation。

LoopIterationDraft 不得被解释为真实 loop iteration result；`shouldAttemptIteration` 只是 internal dehydrated marker，不表示真实 event loop iteration、scheduler task 或 queue item。

## Next Opening

建议 next opening：

`P1 internal loop iteration draft bundle closure / next runtime behavior decision`

