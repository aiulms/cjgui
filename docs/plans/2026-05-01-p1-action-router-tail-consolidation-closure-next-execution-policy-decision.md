# P1 Action Router Tail Consolidation Closure Next Execution Policy Decision

日期：2026-05-01

## Decision

Action Router tail consolidation 已封账。下一刀选择：

`P1 internal Action Router execution policy model bundle implementation`

## 依据

- `CjguiInternalActionExecutionRecord` / `cjguiInternalExecuteDefaultActionExecutionRecordDraft()` 已固定为当前 Action Router canonical endpoint。
- 低价值、无 `.cj` 调用点的 route / execution-record derived helper 已删除。
- dispatch tail 与 execution tail 已通过 manifest 固定为 value-style runway，没有继续新增 outcome / readiness / report wrapper 的必要。
- 进入 policy model 前，当前缺口不是继续做 tail wrapper，而是表达 future execution policy 的脱水约束事实。

## 下一刀允许范围

- 默认 owner file：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/action_router.cj`。
- 输入：`CjguiInternalActionExecutionRecord`。
- 输出：internal-only value-style execution policy model / policy gate / policy readiness bundle。
- 允许同 owner W2/W3 bundle，避免 one-symbol 微切片。
- 可以补充最小中文维护注释，说明 policy 只表达 future execution 的约束事实。

## 必须保持的 Invariant

- policy model 不执行 action。
- policy model 不产生 side effect。
- policy model 不写 queue、不 enqueue、不 drain。
- policy model 不接 AI provider、prompt、external agent 或 public API。
- policy model 不接 event loop、scheduler、platform callback 或 runtime cycle。
- policy model 不写 runtime global state。
- policy model 不新增 public runtime API 或 public C ABI。

## 不批准事项

- 真实 action execution / action executor。
- provider response、model session、prompt routing 或 external agent contract。
- queue storage、enqueue side effect、drain。
- event loop / scheduler implementation。
- platform bridge / native bridge / callback binding。
- runtime cycle execution 或 runtime global state commit。
- 继续在 execution record 后堆 pure outcome / report / five-piece sanity wrapper。

## 验收标准

- Action Router manifest 明确记录 execution policy model 位于 execution record 之后，且仍不是 execution。
- `runtime/cjgui/README.md` 说明当前 Action Router 下一段 runway 与 stop-line。
- `GUI_TASK_TRACKER.md` 的 next opening 指向 `P1 internal Action Router execution policy model bundle implementation`。
- 如果实施源码，必须先做 GitNexus impact，随后运行 build / smoke / diff verification 与 GitNexus detect_changes。

## 当前 Next Opening

`P1 internal Action Router execution policy model bundle implementation`
