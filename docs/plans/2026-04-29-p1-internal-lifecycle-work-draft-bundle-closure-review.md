# P1 Internal Lifecycle Work Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 internal lifecycle work draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 internal-only types：

- `CjguiInternalLifecycleWorkDraftRequest`
- `CjguiInternalLifecycleWorkDraft`
- `CjguiInternalLifecycleWorkDraftReport`

新增 internal-only functions：

- `cjguiInternalBuildLifecycleWorkDraftRequest`
- `cjguiInternalBuildLifecycleWorkDraft`
- `cjguiInternalEvaluateLifecycleWorkDraft`
- `cjguiInternalExecuteLifecycleWorkDraft`
- `cjguiInternalExecuteDefaultLifecycleWorkDraft`
- `cjguiInternalLifecycleWorkDraftOpenSanity`
- `cjguiInternalLifecycleWorkDraftRuntimeBlockedSanity`
- `cjguiInternalLifecycleWorkDraftInputBlockedSanity`
- `cjguiInternalLifecycleWorkDraftShutdownBlockedSanity`
- `cjguiInternalLifecycleWorkDraftCancellationBlockedSanity`

## Behavior Summary

LifecycleWorkDraft 只消费 `CjguiInternalIterationWorkPacketDraftReport`，并只读取 `workPacketReport.packet`。它把 IterationWorkPacketDraft 的 lifecycle / defer / blocked / future-boundary-after-lifecycle signals 投影为 lifecycle-work summary。

Open path 会构建 process-lifecycle 与 future-boundary-after-lifecycle summary；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked paths 都 fail closed，并生成 defer-lifecycle / blocked-lifecycle summary。

## Verification

- Build：`source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-lifecycle-work-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 real event loop，未写 `while` / scheduling loop，未实现 callback binding / queue / drain，未执行 runtime work / lifecycle work / input processing / layout / render，未修改 app lifecycle state 或 window lifecycle state，未执行 `run()` / shutdown / cancellation，未创建 window，未新增 handle table / generation。

LifecycleWorkDraft 不得被解释为真实 lifecycle execution result；`shouldProcessLifecycleWork` 只是 internal dehydrated marker，不表示 app lifecycle execution、window lifecycle execution、state mutation、scheduler task、platform callback 或 queue item。

## Next Opening

建议 next opening：

`P1 internal lifecycle work draft bundle closure / next runtime behavior decision`
