# P1 Input-To-Runtime Ingress Boundary Decision

日期：2026-04-30

## Current Landed Facts

- Input intent / admission 已落地，并保持 dehydrated internal model。
- Input routing candidate 已落地：`CjguiInternalInputRoutingResult` 只消费 `CjguiInternalInputIntentAdmission`。
- Runtime state store transition 已稳定：version / snapshot / transition 是 value-style runtime state boundary context。
- 当前仍没有 queue、event loop、scheduler、platform event object、runtime cycle execution、`cjguiInternalExecuteRuntimeCycle` 新调用点或 global state write。

## Decision

- 下一步进入 input-to-runtime ingress。
- Ingress 只消费 `CjguiInternalInputRoutingResult`，并可消费 `CjguiInternalRuntimeStateStoreTransition` 或 default state store transition 作为当前 runtime state boundary context。
- Ingress 只表达 future runtime ingress candidate 是否可被当前 runtime state boundary 接受。
- Ingress 不执行 candidate、不 enqueue、不 dispatch、不调用 cycle、不接 event loop / queue / scheduler / platform。

## Approved Next Opening

`P1 internal input-to-runtime ingress boundary bundle implementation`

## Guardrails For Next Implementation

- No platform event object.
- No native handle / raw pointer / callback.
- No queue / event loop / scheduler.
- No runtime cycle execution.
- No new `cjguiInternalExecuteRuntimeCycle` call.
- No global state write or global mutable singleton.
- No public runtime API / public C ABI.
- No Request + Report double layer.
- No five-piece sanity helper.
- Ingress value should stay small, direct, and tied to routing result plus state-store transition context.

## Verification Note

- 本轮 docs-only，不跑 `cjpm build` 或 smoke guard。
- 只跑 `git diff --check` / link check / forbidden check。
