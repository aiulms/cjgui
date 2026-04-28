# P1 Internal Runtime Readiness / Run-Boundary Chain Compaction

日期：2026-04-29

类型：closure_review + architecture_decision

authority：

- [2026-04-29-p1-internal-runtime-run-request-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-run-request-bundle-closure-review.md)
- [2026-04-29-p1-internal-runtime-run-intent-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-run-intent-bundle-closure-review.md)
- [2026-04-29-p1-internal-runtime-driver-report-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-driver-report-bundle-closure-review.md)

本次无需 fallback；指定 closure 文件均存在。

## Current Internal Chain

- root state
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：聚合 bootstrap snapshot 与 `isRuntimeReady`。
  - Not：不是 runtime state machine、app run、event loop、queue / drain 或 shutdown。

- runtime step
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 root readiness 与 step input / policy 映射为 `didAdvance` 与 blocked outcome。
  - Not：不是真实 tick、queue drain、callback dispatch 或 app run。

- runtime cycle
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：组合 root state、step input、step policy、decision、step result 与 `didProduceProgress`。
  - Not：不是循环，不消费外部事件，不代表 frame / render / layout progress。

- command draft
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：从 cycle result 派生 request-next-cycle / report-blocked / observed-progress 摘要。
  - Not：不是 renderer command list、event loop task、queue item 或 platform callback。

- command pipeline
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 cycle request、cycle result 与 command draft 串成一次 internal summary pipeline。
  - Not：不是 public API、renderer pipeline、event loop、queue / drain 或 app run。

- driver pass
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：组织一次 command pipeline pass，并投影 driver-level progress / blocked summary。
  - Not：不是真实 runtime driver，不启动 loop，不接平台 callback。

- driver report
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 gated driver result 规整为 stable next-action summary，含 `isReadyForNextInternalPass`。
  - Not：不是 scheduler decision、queue policy、event loop command 或 renderer command list。

- run intent
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 driver report 投影为 run-boundary intent，含 `mayRequestRuntimeRun`。
  - Not：不是真实 run loop、scheduler、queue item 或 public run API。

- run request
  - Owner：`runtime/cjgui/src/runtime_state.cj`。
  - Internal fact：把 run intent 包装并评估为 accepted / deferred request summary。
  - Not：不是 `run()` 调用、event loop start、platform callback、queue item 或 error system。

## Current Capability

- ready path 可以从 platform readiness 经 app/window readiness、bootstrap、root、step、cycle、pipeline、driver report、run intent 推进到 accepted run request。
- runtime-not-ready path 可以 fail closed：不 advance、不 complete driver pass、不 request run boundary，并 surface blocked report。
- input-blocked path 可以 fail closed：不 advance、不 request next cycle、不 accept run request，并保留 blocked summary。
- run request 已能表达 accept / defer，但不执行 run，不启动 event loop，不消费 queue。

## Still Closed

- public runtime API
- public C ABI
- event loop
- queue / drain
- app run / shutdown
- window create / close / destroy
- platform callback
- renderer command list
- handle table / generation

## Next Boundary Decision

不建议继续增加纯 report / wrapper 层。当前链路已经能表达 readiness 到 run request 的正向意图，再继续向前包装会提高文档和代码噪音，但不会解决运行时生命周期的缺口。

可选路线：

- A. `P1 internal run boundary draft bundle`
  - 继续 internal-only，定义 run boundary draft type / request executor / report。
  - 仍不 public、不接平台、不启动 loop。

- B. `P1 internal shutdown / cancellation intent bundle`
  - 在进入 run boundary 前，补齐 stop / shutdown / cancel intent。
  - 避免当前链路只有 ready / request-run 方向，而没有退出、取消或停止方向。

推荐路线：B，优先进入 `P1 internal shutdown / cancellation intent bundle`。

理由：当前链路已经证明“进”的方向：ready path 可以推进到 run request accept，blocked path 可以 fail closed。但退出 / cancel / shutdown 尚未建模。如果直接继续走 run boundary，未来 `run` 容易只剩启动方向，没有对称的停止意图、取消意图和 fail-closed 出口。

## Recommended Next Opening

`P1 internal shutdown / cancellation intent bundle implementation`

下一轮如果进入实现，仍应保持 internal-only：不新增 public API / C ABI，不接 AppKit / Metal / Objective-C，不启动 event loop，不实现 queue / drain，不实现 app run / shutdown，不创建 window，不新增 handle table。
