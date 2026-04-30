# P1 Runtime Ingress Manifest Stabilization Decision

日期：2026-04-30

## Current Landed Facts

- Input ingress 已落地：input intent / admission / routing / input-runtime ingress 主线已闭合。
- Scheduler ingress 已落地：scheduler tick intent / admission / scheduler-runtime ingress 主线已闭合。
- Runtime ingress coordinator 已落地：`CjguiInternalRuntimeIngressCoordinator` 统一组合 input ingress 与 scheduler ingress。
- `runtime_ingress.cj` 已成为 ingress coordinator owner file；`runtime_scheduler.cj` 继续作为 scheduler owner file。
- `runtime_state.cj` 仍为 `10065` 行 critical warning，本轮 closure 未继续扩大。
- 当前仍无 queue / event loop / scheduler implementation / runtime cycle execution / global state write。

## Decision

下一步进入 ingress manifest stabilization。

不立即进入 Action Router。原因是 Action Router 应消费一个稳定、可交接的 ingress front door；当前应先固定 input 主线、scheduler 主线与 coordinator owner/truth/mainline，避免高层语义在未稳定 ingress 上空转。

## Approved Next Opening

`P1 internal runtime ingress manifest stabilization bundle implementation`

## Guardrails For Next Implementation

- Default owner/write set: `runtime_ingress.cj` + docs。
- No `runtime_state.cj` unless absolutely necessary; if touched, file-size / owner split check is mandatory.
- No queue / event loop / scheduler implementation.
- No runtime cycle execution.
- No global state write.
- No public API / C ABI.
- No Request + Report double layer.
- No five-piece sanity.
- Optional derived helper max 1-2.
- No new behavior wrapper.

## Verification Note

本轮 docs-only，不跑 build / smoke。只跑 `git diff --check` / link check / forbidden check。
