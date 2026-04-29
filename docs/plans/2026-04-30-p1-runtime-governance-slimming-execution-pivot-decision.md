# P1 Runtime Governance Slimming / Execution Pivot Decision

日期：2026-04-30

## 背景

本轮接收了外部 AI 对 CJGUI 治理与 runtime draft 链的结构性诊断。该诊断不是项目事实真相源，但指出了一个已经可以用本仓库数据验证的风险：

> 治理机制正在从保护 runtime 边界，滑向延长 draft / report / sanity 链条的惯性。

## 当前事实体检

基于当前工作区快速统计：

- `runtime/cjgui/src/runtime_state.cj` 约 `9194` 行。
- `runtime_state.cj` 顶层 symbol 约 `439` 个。
- `Draft / Report / Request` 命名相关 symbol 约 `226` 个。
- `Sanity` 命名相关 symbol 约 `182` 个。
- `docs/plans` 顶层 plan 文档约 `235` 个。
- `GUI_TASK_TRACKER.md` 约 `3303` 行。

这些数字说明：模型债务、tracker 膨胀、sanity helper 膨胀和 draft/report/request 链条膨胀都已真实存在。

## 哪些诊断成立

成立：

- `runtime_state.cj` 已经过胖，继续把新概念都堆在一个文件里会降低可读性。
- `Draft / Report / Request` 层数已经很深，不能继续把每一个观察点都包装成新一层 boundary。
- `Sanity` helper 已经从验证辅助接近推进惯性，后续不能默认每层新增 open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked 五件套。
- `GUI_TASK_TRACKER.md` 已经不适合作为长历史流水继续增长，当前入口需要 compaction。
- post-attempt 之后如果继续写 `outcome -> observation -> feedback -> result` 一类纯 wrapper，会重新进入治理反噬。

不完全成立：

- 项目并非完全没有真实 state mutation。app/window lifecycle 已经有 owner-local immutable-copy mutation。
- 项目并非完全没有执行。`first internal execution attempt` 已经在 allowed path 调用一次 `cjguiInternalExecuteRuntimeCycle(plan.cycleRequestCandidate)`。
- 当前问题不是“治理无用”，而是治理已经完成保护使命，下一阶段需要从“继续铺准入层”切到“执行收敛与模型瘦身”。

## 新规则：Post-Attempt Draft Chain Cap

从当前节点开始，runtime execution tail 不再允许继续新增纯粹的 post-attempt wrapper 层。

禁止继续用下面形式作为下一轮主要产出：

- `ExecutionAttemptOutcomeObservation`
- `ExecutionAttemptOutcomeFeedback`
- `ExecutionResultDraft`
- `ExecutionResultReport`
- 任何只把前一层 Bool 原样搬运到后一层的新 `Request / Report / Draft`

除非该层同时满足至少一项：

- 删除或合并了已有 wrapper。
- 把结果接入已有真实 state / cycle / owner 边界。
- 明确减少 `runtime_state.cj` 的符号数量或重复 sanity。
- 为即将打开的 high-risk boundary 提供不可替代的证据。

否则，一律视为治理反噬。

## 新规则：Sanity Helper Freeze

从当前节点开始，不再默认给每个 internal layer 配五条 sanity helper。

允许新增 sanity 的情况：

- 新增了真实行为分支，且现有 build / smoke / helper 不能覆盖。
- 新增了新的 blocked path 语义，不只是复用已有 runtime / input / shutdown / cancellation path。
- 正在删除或合并旧 helper，需要临时保留一个 aggregate sanity 证明行为等价。

不允许新增 sanity 的情况：

- 只是把上一层 summary 投影到下一层。
- 只是复用同一套 open / blocked 五件套。
- 只是为了让 closure 看起来完整。

## 新规则：Tracker Compaction Trigger

`GUI_TASK_TRACKER.md` 已超过适合作为当前入口的长度。

下一轮或最近一次治理瘦身工作应把 tracker 压回入口职责：

- 保留当前阶段。
- 保留当前 next opening。
- 保留最近 5-10 条 landed facts。
- 保留 healthy stop-line。
- 历史流水迁移或压缩到 plan / compaction 文档。

tracker 不应继续作为完整历史数据库。

## 新规则：Execution Pivot

当前已经越过 pure readiness boundary，进入 first internal execution attempt。

因此下一阶段默认目标不再是继续证明“未来可执行”，而是：

```text
执行后如何收敛到已有 state / cycle / owner 边界
```

后续 implementation 应优先选择：

- execution convergence：让一次 internal execution attempt 的结果进入已有 cycle / state carry-forward / committed-state / next-cycle 语义，而不是继续只生成新 report。
- model compression：删除 always-true marker、stored derived Bool、重复 sanity、重复 wrapper。
- owner cleanup：把 owner-specific runtime / lifecycle facts 拆回更合适的 owner 文件，而不是继续堆在 `runtime_state.cj`。
- tracker compaction：降低每轮上下文成本。

## 当前 Next Opening 调整

原 next opening：

```text
P1 runtime execution attempt outcome draft closure / next execution boundary decision
```

现在收敛为：

```text
P1 runtime execution convergence / governance slimming bundle implementation
```

该 opening 的默认方向：

- 不再新增纯 post-attempt wrapper。
- 不再新增五件套 sanity helper。
- 优先压缩 `runtime_state.cj` 尾部 execution chain 的重复结构。
- 优先让已有 execution attempt / outcome 与已有 cycle / state carry-forward 语义产生真实收敛。
- 如无法安全进入 execution convergence，则先执行 tracker compaction / model compression，而不是继续新增 wrapper。

## Stop-Line

本 decision 不批准：

- public runtime API。
- public C ABI。
- AppKit / Metal / Objective-C bridge。
- platform callback。
- event loop。
- queue / drain / scheduler。
- 多 cycle execution。
- runtime global mutable singleton。
- runtime global state write。
- window create / close / destroy / release。
- layout / render / input / IME / accessibility。

## CANGJIE_ISSUE_LEDGER

本轮是治理与架构 decision，未发现新的仓颉语言 / SDK / FFI / 工具链 / 文档问题。

未触发 `CANGJIE_ISSUE_LEDGER` 更新。
