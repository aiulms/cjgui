# P1 Action Router Or Queue Boundary Decision

日期：2026-04-30

## Current Landed Facts

- Input ingress 已落地。
- Scheduler ingress 已落地。
- Runtime ingress coordinator 已稳定并有 [runtime ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-ingress-manifest.md)。
- `runtime_ingress.cj` owner split 生效；new ingress work 不回塞 critical `runtime_state.cj`。
- 当前仍无 queue / dispatch / event loop / runtime cycle execution / global state write。

## Candidate Comparison

- A queue admission: 定义脱水 internal queue admission / enqueue-intent readiness；不实现 queue storage、enqueue side effect、drain 或 scheduler，是 Action Router 更可靠的下游前置。
- B Action Router: 战略价值高，但当前缺 queue admission / commit path，过早进入容易停在高层语义文档。
- C second stabilization: 风险最低，但 ingress manifest 和 derived helper 已足够封账，继续稳定化会拖慢真实能力推进。

## Decision

推荐下一步进入 queue admission boundary。

暂缓 Action Router：Action Router 需要可控的下游提交入口；先做 dehydrated queue admission readiness，能让未来 Action Router 消费 ingress front door 后有明确的 admission / dispatch-preparation 边界，而不是直接悬在 runtime front door 上。

## Approved Next Opening

`P1 internal queue admission boundary bundle implementation`

## Guardrails For Next Implementation

- Queue admission 必须是 dehydrated internal readiness model。
- No actual queue storage.
- No enqueue side effect.
- No drain.
- No scheduler implementation.
- No event loop.
- No runtime cycle execution.
- No global state write.
- No public API / C ABI.
- No Request + Report double layer.
- No five-piece sanity.
- Default owner/write set should be new `runtime_queue.cj` or equivalent queue owner file, not `runtime_state.cj`.
- If `runtime_state.cj` must be touched, file-size / owner split check is mandatory.

## Verification Note

本轮 docs-only，不跑 build / smoke。只跑 `git diff --check` / link check / forbidden check。
