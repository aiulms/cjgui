# P1 Input Routing Boundary Decision

日期：2026-04-30

## Current Landed Facts

- `CjguiInternalInputIntentSource` / `CjguiInternalInputIntentKind` / `CjguiInternalInputIntent` / `CjguiInternalInputIntentAdmission` 已落地。
- Input intent 是 dehydrated internal ingress model：source exactly one，kind exactly one，absent defer，invalid fail-closed blocked。
- 当前没有 platform event object、native handle、raw pointer、callback、queue、event loop、scheduler、runtime cycle execution 或 global state write。

## Decision

- 下一步进入 internal input routing。
- Routing 必须只消费 `CjguiInternalInputIntentAdmission`。
- Routing 只表达 admitted input intent 是否可成为 future runtime ingress candidate，以及 defer / blocked summary。
- Routing 不执行 candidate，不接 platform，不接 queue / event loop / scheduler，不写 global state。

## Approved Next Opening

`P1 internal input routing boundary bundle implementation`

## Guardrails For Next Implementation

- No platform event object.
- No native handle / raw pointer / callback.
- No queue / event loop / scheduler.
- No runtime cycle execution.
- No global state write or global mutable singleton.
- No public runtime API / public C ABI.
- No Request + Report double layer.
- No five-piece sanity helper.
- Routing value should stay small, direct, and consume only `CjguiInternalInputIntentAdmission`.

## Verification Note

- 本轮 docs-only，不跑 `cjpm build` 或 smoke guard。
- 只跑 `git diff --check` / link check / forbidden check。
