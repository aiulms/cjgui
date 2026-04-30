# P1 Scheduler-To-Runtime Ingress Boundary Decision

日期：2026-04-30

## Current Landed Facts

- scheduler tick intent / admission 已落地在 [runtime_scheduler.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scheduler.cj)。
- `runtime_scheduler.cj` 已成为 scheduler owner file；后续 scheduler 相关实现默认继续放在该 owner，不回塞 `runtime_state.cj`。
- `runtime_state.cj` 当前 10065 行，处于 single-file critical warning，本轮决策不继续扩大它。
- 当前 scheduler tick 是 dehydrated internal facts：source / kind exactly one，absent defer，invalid fail-closed blocked，default synthetic cycle-preparation present admitted。
- 当前仍无 platform timer / callback、queue / drain、event loop、scheduler implementation、runtime cycle execution、global state write。

## Decision

下一步批准进入 scheduler-to-runtime ingress。

该 ingress 只消费 `CjguiInternalSchedulerTickAdmission`，并可消费 `CjguiInternalRuntimeStateStoreTransition` 或 default state store transition context。它只表达 admitted scheduler tick 是否可被当前 runtime state boundary 接受为 future runtime pacing / cycle-preparation candidate。

本边界不实现 scheduler，不 enqueue，不执行 runtime cycle，不调用 `cjguiInternalExecuteRuntimeCycle`，不接 event loop / queue / drain / platform timer。

## Approved Next Opening

`P1 internal scheduler-to-runtime ingress boundary bundle implementation`

## Guardrails For Next Implementation

- default owner / write set: `runtime_scheduler.cj`。
- 不把 scheduler symbols 写入 `runtime_state.cj`。
- no platform timer / callback。
- no native handle / raw pointer。
- no queue / event loop / drain / scheduler implementation。
- no runtime cycle execution。
- no new `cjguiInternalExecuteRuntimeCycle` call。
- no global state write。
- no public API / C ABI。
- no Request + Report double layer。
- no five-piece sanity。
- 如代码现实证明必须触碰 `runtime_state.cj`，必须先执行 file-size / owner split check，并解释为什么不继续拆分。

## Verification Note

本轮 docs-only，不跑 build / smoke。只跑 `git diff --check`、link check 与 forbidden file check。
