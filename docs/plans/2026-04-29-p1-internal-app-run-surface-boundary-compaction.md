# P1 Internal App Run Surface Boundary Compaction

日期：2026-04-29

类型：closure_review + architecture_decision

authority：

- [2026-04-29-p1-internal-run-boundary-readiness-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-boundary-readiness-compaction.md)
- [2026-04-29-p1-internal-run-boundary-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-boundary-draft-bundle-closure-review.md)

本次无需 fallback；指定 compaction / closure 文件均存在。

## Current Run Boundary Capability

- run request report
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：表达 internal run request 是否 accepted / deferred，以及是否应 surface blocked report。
- shutdown / cancellation report
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：表达 shutdown / cancellation intent 是否要求 defer run request，以及是否进入 shutdown / cancellation path。
- run boundary request
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：只聚合 run request report 与 shutdown / cancellation report。
- run boundary report
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：表达 boundary open / deferred / blocked，以及 runtime / input / shutdown / cancellation blockers。

当前 ready path 可以得到 open boundary；runtime-not-ready 与 input-blocked path 会 fail closed；shutdown / cancellation intent 会 defer boundary 并标记对应 blocker。

## Still Not

- 不是 public run API。
- 不是 app run implementation。
- 不是 event loop。
- 不是 queue / drain。
- 不是 platform callback。
- 不是 AppKit / Metal bridge。
- 不是 window create / close / destroy。

## Decision

可以开始定义 internal-only app run surface。

第一刀只能定义脱水 AppRunState / AppRunRequest / AppRunReport 与 internal evaluator。它应消费 `CjguiInternalRunBoundaryReport`，而不是绕过 run boundary 直接读取 platform / lifecycle lower-level facts。

下一刀仍不得执行 `run()`，不得启动 event loop，不得 drain queue，不得调用平台，不得新增 public API 或 public C ABI。

## Owner Recommendation

当前 runtime run boundary 已由 `runtime/cjgui/src/runtime_state.cj` 持有。下一刀的 app run surface 可以继续放在 `runtime_state.cj`，作为 runtime-level owner 的 internal-only surface。

不建议把 app run surface 放入 `app_lifecycle.cj`，除非同时重开 owner model；当前 app lifecycle owner 更适合保留 lifecycle state / transition truth，而不是 runtime run boundary surface。

## Recommended Next Opening

`P1 internal app run surface bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight：`W3 internal subsystem draft`

建议下一刀一次完成：

- `CjguiInternalAppRunState`
- `CjguiInternalAppRunRequest`
- `CjguiInternalAppRunReport`
- builder / evaluator
- ready sanity
- boundary-blocked sanity
- shutdown-blocked sanity
- cancellation-blocked sanity

下一刀仍不允许：

- public API / C ABI
- real `run()`
- event loop / queue / drain
- platform callback
- window create / close / destroy
- AppKit / Metal bridge
