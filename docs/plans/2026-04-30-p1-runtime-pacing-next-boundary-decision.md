# P1 Runtime Pacing Next Boundary Decision

日期：2026-04-30

## Current Landed Facts

- input-to-runtime ingress 已落地：`CjguiInternalInputRuntimeIngress` 组合 input routing 与 runtime state store transition context。
- scheduler-to-runtime ingress 已落地：`CjguiInternalSchedulerRuntimeIngress` 组合 scheduler tick admission 与 runtime state store transition context。
- `runtime_scheduler.cj` owner split 生效；scheduler symbols 不再写入 `runtime_state.cj`。
- `runtime_state.cj` 当前 10065 行，处于 single-file critical warning，本轮决策不继续扩大它。
- 当前仍无 queue / drain、event loop、scheduler implementation、runtime cycle execution、global state write 或 public API / C ABI。

## Candidate Comparison

- A. scheduler ingress stabilization：风险最低，可新增 manifest，但会让 input ingress 与 scheduler ingress 继续双轨停留。
- B. runtime ingress coordinator：把 input candidate 与 scheduler pacing candidate 归并为 future ingress front door；需要严格保持少类型、强语义，避免 coordinator wrapper 回潮。
- C. Action Router：战略价值高，但当前还缺统一 ingress front door，过早进入容易高层语义空转。

## Decision

推荐 B：进入 internal runtime ingress coordinator。

理由：input-to-runtime ingress 与 scheduler-to-runtime ingress 都已落地，下一步更自然的收束不是继续分别 stabilization，而是形成一个小的 internal ingress coordinator。它只表达 input candidate / scheduler pacing candidate 的 combined readiness，不 enqueue、不 dispatch、不实现 scheduler、不执行 runtime cycle。

暂缓 Action Router，因为 Action Router 应消费更稳定的 runtime ingress front door；在 input 与 scheduler 两条 ingress 尚未归并前直接进入 Action Router，容易把语义层建在未收口的入口之上。

## Approved Next Opening

`P1 internal runtime ingress coordinator boundary bundle implementation`

## Guardrails For Next Implementation

- coordinator 只消费 `CjguiInternalInputRuntimeIngress` 与 `CjguiInternalSchedulerRuntimeIngress`。
- 不 enqueue。
- 不 dispatch。
- 不实现 scheduler。
- 不接 event loop / queue / drain。
- 不执行 runtime cycle。
- 不写 global state。
- 不新增 public API / C ABI。
- 不新增 Request + Report 双层。
- 不新增五件套 sanity。
- 默认新建 `runtime_ingress.cj` 或等价 ingress owner file；不要塞回 `runtime_state.cj`。
- 如果必须触碰 `runtime_state.cj`，必须先做 file-size / owner split check，并解释为什么不继续拆分。

## Verification Note

本轮 docs-only，不跑 build / smoke。只跑 `git diff --check`、link check 与 forbidden file check。
