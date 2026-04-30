# P1 Scheduler Or Action Router Boundary Decision

日期：2026-04-30

## Current Landed Facts

- input intent / routing / input-to-runtime ingress 已落地，并由 [P1 input-to-runtime ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-input-to-runtime-ingress-manifest.md) 稳定主线。
- `runtime_state.cj` 当前约 `10065` 行、`367688` bytes，已处于 `>8000` critical size warning。
- 当前仍无 platform object、native handle、queue、event loop、scheduler、runtime cycle execution、global state write、public API 或 C ABI。

## Candidate Comparison

- A. `P1 internal scheduler tick intent boundary bundle implementation`：定义脱水 scheduler / tick intent，补齐 future event loop / cycle pacing 的时间入口；风险是抽象空转，因此必须少类型、无 wrapper 链，并默认放入新 scheduler owner file。
- B. `P1 internal Action Router boundary decision / architecture intake`：贴近 AI-native GUI 的战略方向，但当前缺 scheduler / queue / event loop，过早进入容易变成高层语义空转。
- C. `P1 runtime ingress owner split / module extraction decision`：最直接处理 `runtime_state.cj` critical warning，但会推迟真实 runtime ingress-adjacent 能力；可作为下一轮 implementation 的 owner guard，而不是先单独停在治理。

## Decision

推荐 A with owner split guard：下一步进入 `P1 internal scheduler tick intent boundary bundle implementation`。

选择理由：input ingress 已稳定，下一块自然边界是脱水 scheduler tick intent，为 future event loop / cycle pacing 提供内部时间入口。Action Router 暂缓，等 scheduler / tick 与 ingress 都有稳定内部边界后再开。owner split 不单独作为下一轮，因为我们可以通过默认新建 scheduler owner file 推进能力，同时停止继续喂大 `runtime_state.cj`。

## Approved Next Opening

`P1 internal scheduler tick intent boundary bundle implementation`

## Guardrails For Next Implementation

- scheduler tick 必须是 dehydrated internal-only intent。
- 不实现 scheduler。
- 不写 loop。
- 不接 queue / drain / event loop。
- 不执行 runtime cycle。
- 不写 global state。
- 不新增 public API / C ABI。
- 不新增 Request + Report 双层。
- 不新增五件套 sanity。
- 默认 owner / write set 应优先新建 `runtime/cjgui/src/runtime_scheduler.cj` 或等价 scheduler owner file。
- 不继续把新的 scheduler subsystem 塞进 critical `runtime_state.cj`。
- 若代码现实证明必须修改 `runtime_state.cj`，必须先做 file-size / owner split check，并解释原因、当前行数、critical warning、为什么暂不拆分、后续 split / module extraction 候选。

## Verification Note

本轮 docs-only，不跑 `cjpm build` 或 smoke guard。

只需运行：

- `git diff --check`
- README / tracker / plans README 链接检查
- forbidden 文件检查

未触发 `CANGJIE_ISSUE_LEDGER` 更新。
