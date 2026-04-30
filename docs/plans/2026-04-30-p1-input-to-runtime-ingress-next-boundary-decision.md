# P1 Input-To-Runtime Ingress Next Boundary Decision

日期：2026-04-30

## Current Landed Facts

- input intent / admission 已落地：`CjguiInternalInputIntent*` 只表达脱水 internal input facts。
- input routing 已落地：`CjguiInternalInputRoutingResult` 把 admitted intent 标记为 future runtime ingress candidate。
- input-to-runtime ingress 已落地：`CjguiInternalInputRuntimeIngress` 组合 input routing result 与 runtime state store transition context。
- runtime state store transition 已落地：`CjguiInternalRuntimeStateStoreTransition` 仍是 value-style candidate movement，不是 global mutable state。
- 当前仍无 platform object、native handle、queue、event loop、scheduler、runtime cycle execution、global state write、public API 或 C ABI。
- 单文件体积闸门已生效：后续改 `.cj` 文件必须报告 line-count 档位；`runtime_state.cj` 当前约 `10065` 行，已处于 `>8000` critical warning 区间。

## Candidate Comparison

- A. `P1 internal input-to-runtime ingress stabilization bundle implementation`：稳定 input intent -> routing -> runtime ingress 主线，新增 manifest / 少量 derived helper / README 压缩；风险低，能把 ingress 交接成基线。
- B. `P1 internal scheduler tick intent boundary bundle implementation`：有助于 future pacing，但 input ingress 刚落地，直接开 tick 会让两个 ingress 边界同时漂移。
- C. `P1 internal input ingress to Action Router boundary decision`：战略价值高，但当前还没有 scheduler/tick 或 queue boundary，过早进入 Action Router 容易放大抽象债。

## Decision

批准下一步进入 A：`P1 internal input-to-runtime ingress stabilization bundle implementation`。

选择 A 的理由：input-to-runtime ingress 刚刚把 dehydrated input candidate 与 runtime state boundary context 合并成 acceptance value，下一步应先稳定 manifest、default path 和 stop-lines。scheduler tick 与 Action Router 暂缓，等 input ingress 成为可交接基线后再进入，避免并行漂移或重新堆 wrapper。

## Approved Next Opening

`P1 internal input-to-runtime ingress stabilization bundle implementation`

## Guardrails For Next Implementation

- 不新增 behavior wrapper。
- 可新增 ingress manifest。
- 可新增 1-2 个 derived helper。
- 可压缩 runtime README。
- 不接 platform / queue / event loop / scheduler。
- 不执行 runtime cycle。
- 不写 global state。
- 不新增 public API / C ABI。
- 不新增 Request + Report 双层。
- 不新增五件套 sanity。
- 如修改 `runtime_state.cj`，必须做 file-size / owner split check：记录当前行数、critical warning、为什么暂不拆分、后续拆分 / module extraction 候选。

## Verification Note

本轮 docs-only，不跑 `cjpm build` 或 smoke guard。

只需运行：

- `git diff --check`
- README / tracker / plans README 链接检查
- forbidden 文件检查

未触发 `CANGJIE_ISSUE_LEDGER` 更新。
