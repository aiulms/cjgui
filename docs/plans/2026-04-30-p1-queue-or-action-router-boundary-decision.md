# P1 Queue Or Action Router Boundary Decision

日期：2026-04-30

## Current Landed Facts

- Runtime ingress coordinator 已落地并稳定为 unified internal front door。
- Queue admission 已落地，消费 `CjguiInternalRuntimeIngressCoordinator` 并形成 dehydrated admission readiness。
- `runtime_queue.cj` owner split 生效；queue work 默认不回塞 critical `runtime_state.cj`。
- 当前仍无 real queue storage / enqueue side effect / drain / event loop / scheduler implementation / runtime cycle execution。

## Candidate Comparison

- A queue admission stabilization: 风险低，可做 manifest / README 稳定化，但 queue admission 本身很小，继续停留会拖慢 Action Router。
- B Action Router: 开始进入 AI-native Action Router 边界；只做 internal dehydrated action intent / admission / routing runway，并消费 queue admission readiness 作为下游提交门。
- C enqueue-intent: 比 Action Router 更低层，但容易继续生成 queue wrapper 链，绕开项目核心差异化。

## Decision

推荐下一步进入 Action Router boundary decision / implementation runway。

理由：ingress front door 与 queue admission readiness 已经存在，Action Router 不再悬空；下一步应先定义 internal-only dehydrated action intent / admission runway，让 Action Router 有明确下游 queue admission gate，而不是继续堆 enqueue-intent wrapper。

不选择 C：enqueue-intent 会把队列前置继续名词化，却仍不触及 Action Router 的语义入口；当前更需要把 AI-native runtime 差异化接入可控的 internal boundary。

## Approved Next Opening

`P1 internal Action Router boundary decision / implementation runway`

## Guardrails For Next Step

- Action Router 必须 internal-only。
- 只能定义 dehydrated action intent / action source / action admission 或 runway。
- 不执行 action。
- 不公开 AI API。
- 不新增 public API / C ABI。
- 不接 model provider / prompt / external agent。
- 不写 queue / enqueue / drain。
- 不接 event loop / scheduler / platform。
- 不执行 runtime cycle。
- 应消费 queue admission readiness 作为下游提交门。
- 默认新建 Action Router owner file，不能塞进 `runtime_state.cj`。
- 如果必须触碰 `runtime_state.cj`，file-size / owner split check mandatory。

## Verification Note

本轮 docs-only，不跑 build / smoke。只跑 `git diff --check` / link check / forbidden check。
