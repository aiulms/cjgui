# P1 Internal Run Loop Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 internal run loop draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 internal-only types：

- `CjguiInternalRunLoopDraftRequest`
- `CjguiInternalRunLoopDraftIntent`
- `CjguiInternalRunLoopDraftReport`

新增 internal-only functions：

- `cjguiInternalBuildRunLoopDraftRequest`
- `cjguiInternalBuildRunLoopDraftIntent`
- `cjguiInternalEvaluateRunLoopDraft`
- `cjguiInternalExecuteRunLoopDraft`
- `cjguiInternalExecuteDefaultRunLoopDraft`
- `cjguiInternalRunLoopDraftOpenSanity`
- `cjguiInternalRunLoopDraftRuntimeBlockedSanity`
- `cjguiInternalRunLoopDraftInputBlockedSanity`
- `cjguiInternalRunLoopDraftShutdownBlockedSanity`
- `cjguiInternalRunLoopDraftCancellationBlockedSanity`

## Behavior Summary

RunLoopDraft 只消费 `CjguiInternalAppRunDispatchReport`，并只读取 `dispatchReport.summary`。它把 dispatch summary 的 run-loop-draft / deferred notice / blocked notice / future-boundary request signals 投影为 loop-intent summary。

Open path 会构建 enter-loop-draft 与 future-boundary request summary；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked path 都 fail closed，并生成 defer-loop / blocked-loop summary。

## Verification

- RED build：缺少 RunLoopDraft executor 时，`cjpm build --target-dir /tmp/cjgui-run-loop-draft-bundle-red-target --skip-script` 按预期失败。
- GREEN build：`cjpm build --target-dir /tmp/cjgui-run-loop-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 real event loop，未写 `while` / scheduling loop，未实现 callback binding / queue / drain，未执行 dispatch / `run()` / shutdown / cancellation，未创建 window，未新增 handle table / generation。

RunLoopDraft 不得被解释为真实 event loop result；`shouldEnterLoopDraft` 只是 internal dehydrated marker，不表示真实 event loop、scheduler task 或 queue item。

## Next Opening

建议 next opening：

`P1 internal run loop draft bundle closure / next runtime behavior decision`

