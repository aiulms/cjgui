# P1 Internal App Run Controller Boundary Compaction

日期：2026-04-29

类型：closure_review + architecture_decision

authority：

- [2026-04-29-p1-internal-app-run-surface-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-surface-boundary-compaction.md)
- [2026-04-29-p1-internal-app-run-surface-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-surface-bundle-closure-review.md)

本次无需 fallback；指定 compaction / closure 文件均存在。

## Current AppRun Surface Capability

- AppRunState
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：从 `CjguiInternalRunBoundaryReport` 投影 `isAppRunAllowed`、`isAppRunDeferred`、`isAppRunBlocked`。
- AppRunRequest
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：只包装 `CjguiInternalRunBoundaryReport`。
- AppRunReport
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 AppRun state 投影为 `didAcceptAppRun`、`shouldDeferAppRun`、`shouldReportAppRunBlocked`。

当前 sanity 覆盖：

- ready / open path：接受 internal AppRun surface。
- runtime-blocked path：defer and report blocked。
- input-blocked path：defer and report blocked。
- shutdown-blocked path：defer and report blocked。
- cancellation-blocked path：defer and report blocked。

AppRun surface 只消费 `CjguiInternalRunBoundaryReport`，不越级读取 readiness / platform / lifecycle lower-level facts。

## Still Not

- 不是 public run API。
- 不是 real app run implementation。
- 不是 event loop。
- 不是 queue / drain。
- 不是 platform callback。
- 不是 AppKit / Metal bridge。
- 不是 window create / close / destroy。

## Controller Decision

可以开始定义 internal-only app run controller draft。

controller draft 可以从 `CjguiInternalAppRunReport` 派生 internal next action：

- `shouldEnterAcceptedPath`
- `shouldEnterDeferredPath`
- `shouldEnterBlockedPath`
- `shouldRequestFutureRunBoundary`

但 controller draft 仍不能执行任何 action，不能启动 run / loop / queue / platform bridge，也不能绕过 `CjguiInternalAppRunReport` 直接读取 `CjguiInternalRunBoundaryReport` 或 lower-level facts。

## Recommended Next Opening

`P1 internal app run controller draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight：`W3 internal subsystem draft`

建议下一刀一次完成：

- `CjguiInternalAppRunControllerRequest`
- `CjguiInternalAppRunControllerDecision`
- `CjguiInternalAppRunControllerReport`
- builder / evaluator
- open sanity
- runtime-blocked sanity
- input-blocked sanity
- shutdown-blocked sanity
- cancellation-blocked sanity

下一刀仍不允许：

- public API / C ABI
- real `run()`
- event loop / queue / drain
- platform callback
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

当前仍建议放在 `runtime/cjgui/src/runtime_state.cj`，因为 controller draft 是 runtime-level next-action summary owner，不是 app lifecycle implementation。

不建议放入 `app_lifecycle.cj`，除非同时重开 owner model；当前 app lifecycle owner 更适合保留 lifecycle state / transition truth。
