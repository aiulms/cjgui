# P1 Lifecycle Owner Handoff Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 lifecycle owner handoff draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 app lifecycle owner-specific internal-only items：

- `CjguiInternalAppLifecycleWorkHandoffDraft`
- `cjguiInternalBuildAppLifecycleWorkHandoffDraft`
- `cjguiInternalAppLifecycleWorkHandoffOpenSanity`
- `cjguiInternalAppLifecycleWorkHandoffBlockedSanity`

新增 window lifecycle owner-specific internal-only items：

- `CjguiInternalWindowLifecycleWorkHandoffDraft`
- `cjguiInternalBuildWindowLifecycleWorkHandoffDraft`
- `cjguiInternalWindowLifecycleWorkHandoffOpenSanity`
- `cjguiInternalWindowLifecycleWorkHandoffBlockedSanity`

新增 runtime cross-owner routing internal-only items：

- `CjguiInternalLifecycleOwnerHandoffRequest`
- `CjguiInternalLifecycleOwnerHandoffReport`
- `cjguiInternalBuildLifecycleOwnerHandoffRequest`
- `cjguiInternalEvaluateLifecycleOwnerHandoff`
- `cjguiInternalExecuteLifecycleOwnerHandoffDraft`
- `cjguiInternalExecuteDefaultLifecycleOwnerHandoffDraft`
- `cjguiInternalLifecycleOwnerHandoffOpenSanity`
- `cjguiInternalLifecycleOwnerHandoffRuntimeBlockedSanity`
- `cjguiInternalLifecycleOwnerHandoffInputBlockedSanity`
- `cjguiInternalLifecycleOwnerHandoffShutdownBlockedSanity`
- `cjguiInternalLifecycleOwnerHandoffCancellationBlockedSanity`

## Behavior Summary

App lifecycle owner-specific draft facts live in `app_lifecycle.cj`，window lifecycle owner-specific draft facts live in `window_lifecycle.cj`。这些 drafts 只表达 accept / defer / blocked handoff facts，不修改 app/window lifecycle state，也不执行 app/window lifecycle transition。

`runtime_state.cj` 只负责 cross-owner routing summary。它只消费 `CjguiInternalLifecycleWorkDraftReport.draft`，把 `shouldProcessLifecycleWork`、`shouldDeferLifecycleWork` 与 `shouldReportLifecycleBlocked` 投影给 app/window owner builders，并返回 owner handoff report。

Open path 会让 app/window drafts 都 accept lifecycle work；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked paths 都 fail closed，并让 app/window drafts 都 defer + blocked。

## Verification

- RED probe：`/tmp/cjgui-owner-handoff-red-probe` 临时包引用目标 handoff symbols，因缺少 `cjguiInternalBuildAppLifecycleWorkHandoffDraft`、`cjguiInternalBuildWindowLifecycleWorkHandoffDraft` 与 `cjguiInternalExecuteDefaultLifecycleOwnerHandoffDraft` 失败，确认新 capability 尚未存在。
- Build：`source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-lifecycle-owner-handoff-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 real event loop，未写 `while` / scheduling loop，未实现 callback binding / queue / drain，未执行 runtime work、app lifecycle work、window lifecycle work、input processing、layout 或 render，未修改 app lifecycle state 或 window lifecycle state，未执行 `run()` / shutdown / cancellation，未创建 / 关闭 / 销毁窗口，未新增 handle table / generation。

Owner handoff draft 不得被解释为真实 lifecycle execution；owner handoff report 不是真实 lifecycle result。`runtime_state.cj` 只保留 routing summary，不拥有 app/window lifecycle semantics。

## Next Opening

建议 next opening：

`P1 lifecycle owner handoff draft bundle closure / next runtime behavior decision`
