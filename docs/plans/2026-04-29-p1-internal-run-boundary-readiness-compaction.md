# P1 Internal Run-Boundary Readiness Compaction

日期：2026-04-29

类型：closure_review + architecture_decision

authority：

- [2026-04-29-p1-internal-runtime-readiness-run-boundary-chain-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-readiness-run-boundary-chain-compaction.md)
- [2026-04-29-p1-internal-runtime-run-request-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-run-request-bundle-closure-review.md)
- [2026-04-29-p1-internal-shutdown-cancellation-intent-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-shutdown-cancellation-intent-bundle-closure-review.md)

本次无需 fallback；指定 closure / compaction 文件均存在。

## Current Internal Chain

- readiness / root state
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：从 platform readiness 经 bootstrap snapshot 投影到 `isRuntimeReady`。
  - Not：不是 runtime state machine、event loop、queue / drain 或 app run。

- step / cycle
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 root readiness、step input / policy 和 blocked outcome 规整成一次 cycle summary。
  - Not：不是真实 tick，不消费 queue，不绑定 callback，不代表 frame / render / layout progress。

- command draft / command pipeline
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 cycle result 投影成 request-next-cycle / report-blocked / observed-progress，再串成 internal summary pipeline。
  - Not：不是 renderer command list、event loop task、queue item、platform callback 或 AppKit / Metal command。

- driver pass / driver report
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：组织一次 gated pipeline pass，并输出 stable internal next-action summary。
  - Not：不是真实 runtime driver、scheduler、runloop policy、queue policy 或 public API。

- run intent / run request
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 driver report 投影为 run-boundary intent，再评估为 accepted / deferred internal run request summary。
  - Not：不是 `run()` 调用、event loop start、platform callback、queue item 或 public run API。

- shutdown / cancellation intent
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 shutdown / cancellation 脱水意图规整为 defer-run 与 enter-path flags。
  - Not：不是真实 app shutdown、event loop stop、queue drain、platform close callback、task cancellation 或 error system。

## Current Capability

- Ready path 可以接受 internal run request。
- Runtime-not-ready path 可以 defer / blocked，并 surface blocked summary。
- Input-blocked path 可以 defer / blocked，并保持 fail-closed。
- Shutdown / cancellation intent 可以要求 defer run request，并标记 shutdown path / cancellation path。
- 上述全部仍是 internal-only summary，不执行 `run()`，不启动 loop，不 drain queue，不调平台。

## Still Closed

- public runtime API
- public C ABI
- real `run()`
- event loop
- queue / drain
- platform callback
- app shutdown
- window create / close / destroy
- renderer command list
- handle table / generation

## Decision

不建议继续增加纯 report / wrapper 层。当前链路已经同时覆盖正向 run request 与退出方向 shutdown / cancellation intent；再继续包装会增加噪音，而不会打开新的 runtime truth。

可以进入第一个 internal run boundary draft。

该 draft 必须仍保持 internal-only：

- 只聚合 run request report + shutdown report。
- 只判断 run boundary 是否 open / deferred / blocked。
- 不执行 `run()`。
- 不启动 loop。
- 不 drain queue。
- 不调平台。

## Recommended Next Opening

`P1 internal run boundary draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight：`W3 internal subsystem draft`

建议下一刀一次完成：

- `CjguiInternalRunBoundaryRequest`
- `CjguiInternalRunBoundaryReport`
- builder / evaluator
- ready sanity
- runtime-blocked sanity
- input-blocked sanity
- shutdown-blocked sanity
- cancellation-blocked sanity

下一刀仍不允许新增 public API / C ABI，不允许接入 event loop、queue / drain、platform callback 或 app run。
