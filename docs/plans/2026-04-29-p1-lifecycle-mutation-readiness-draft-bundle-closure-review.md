# P1 Lifecycle Mutation Readiness Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 lifecycle mutation readiness draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 app lifecycle owner-specific internal-only items：

- `CjguiInternalAppLifecycleMutationReadinessDraft`
- `cjguiInternalBuildAppLifecycleMutationReadinessDraft`
- `cjguiInternalAppLifecycleMutationReadinessOpenSanity`
- `cjguiInternalAppLifecycleMutationReadinessBlockedSanity`

新增 window lifecycle owner-specific internal-only items：

- `CjguiInternalWindowLifecycleMutationReadinessDraft`
- `cjguiInternalBuildWindowLifecycleMutationReadinessDraft`
- `cjguiInternalWindowLifecycleMutationReadinessOpenSanity`
- `cjguiInternalWindowLifecycleMutationReadinessBlockedSanity`

新增 runtime cross-owner readiness internal-only items：

- `CjguiInternalLifecycleMutationReadinessRequest`
- `CjguiInternalLifecycleMutationReadinessReport`
- `cjguiInternalBuildLifecycleMutationReadinessRequest`
- `cjguiInternalEvaluateLifecycleMutationReadiness`
- `cjguiInternalExecuteLifecycleMutationReadinessDraft`
- `cjguiInternalExecuteDefaultLifecycleMutationReadinessDraft`
- `cjguiInternalLifecycleMutationReadinessOpenSanity`
- `cjguiInternalLifecycleMutationReadinessRuntimeBlockedSanity`
- `cjguiInternalLifecycleMutationReadinessInputBlockedSanity`
- `cjguiInternalLifecycleMutationReadinessShutdownBlockedSanity`
- `cjguiInternalLifecycleMutationReadinessCancellationBlockedSanity`

## Behavior Summary

App mutation readiness facts live in `app_lifecycle.cj`，window mutation readiness facts live in `window_lifecycle.cj`。这些 drafts 只从 owner handoff draft 投影 `canMutate` / `shouldDefer` / `shouldReportBlocked` facts，不修改 app/window state，也不调用 state-changing transition functions。

`runtime_state.cj` 只负责 cross-owner mutation readiness summary。它只消费 `CjguiInternalLifecycleOwnerHandoffReport.appDraft` / `windowDraft`，调用 app/window owner readiness builders，并汇总 `canMutateLifecycleOwners`、`shouldDeferLifecycleMutation` 与 `shouldReportLifecycleMutationBlocked`。

Open path 会让 app/window readiness 都 can mutate；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked paths 都 fail closed，并让 cross-owner summary defer + blocked。

## Verification

- Build：`source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-lifecycle-mutation-readiness-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未修改 `cjpm.toml`，未新增 `src/main.cj` 或 `package_anchor.cj`，未修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。

本轮未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 real event loop，未写 `while` / scheduling loop，未实现 callback binding / queue / drain，未执行 runtime work、app lifecycle work、window lifecycle work、input processing、layout 或 render，未修改 app lifecycle state 或 window lifecycle state，未调用 existing app/window state-changing transition functions，未执行 `run()` / shutdown / cancellation，未创建 / 关闭 / 销毁窗口，未新增 handle table / generation。

Mutation readiness draft 不得被解释为真实 lifecycle mutation；readiness report 不是真实 lifecycle result。`runtime_state.cj` 只保留 cross-owner readiness summary，不拥有 app/window lifecycle mutation semantics。

## Next Opening

建议 next opening：

`P1 lifecycle mutation readiness draft bundle closure / next runtime behavior decision`
