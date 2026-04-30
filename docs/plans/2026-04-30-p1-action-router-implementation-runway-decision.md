# P1 Action Router Implementation Runway Decision

日期：2026-04-30

## Current Landed Facts

- Runtime ingress coordinator 已落地并稳定为 unified internal front door。
- Queue admission 已落地，`runtime_queue.cj` 已成为 queue owner file。
- Action Router 现在已有下游 readiness gate：`CjguiInternalQueueAdmission`。
- `runtime_state.cj` 当前仍处于 critical warning；Action Router 不得塞回 `runtime_state.cj`。

## Action Router First Slice Decision

- 下一步只做 internal action intent boundary。
- 第一刀允许定义 action source / action kind / action intent / action admission。
- Admission 必须消费 queue admission readiness，作为下游提交门。
- 不执行 action。
- 不公开 API。
- 不接 AI provider / prompt / external agent。

## Approved Next Opening

`P1 internal Action Router action intent boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: new `action_router.cj`.
- No `runtime_state.cj` modification.
- No public API / C ABI.
- No model provider / prompt / external agent.
- No action execution.
- No queue storage / enqueue / drain.
- No event loop / scheduler / platform.
- No runtime cycle execution.
- No Request + Report double layer.
- No five-piece sanity.
- Action values must be dehydrated internal facts.
- Must consume queue admission readiness as downstream gate, not bypass it.

## File-size / Owner Split Note

- `runtime_state.cj` is in critical warning range.
- `action_router.cj` is required unless code reality proves otherwise.
- If future implementation touches `runtime_state.cj`, file-size / owner split check is mandatory.

## Verification Note

本轮 docs-only，不跑 build / smoke。只跑 `git diff --check` / link check / forbidden check。
