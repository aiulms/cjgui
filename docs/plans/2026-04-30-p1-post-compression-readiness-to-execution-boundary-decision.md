# P1 Post-Compression Readiness-to-Execution Boundary Decision

日期：2026-04-30

性质：architecture decision / execution boundary review

## Landed Facts

- Runtime replay outcome draft 已完成，可表达 accepted / deferred / blocked summary。
- Runtime tail chain cleanup 已完成；`cjguiInternalRuntimeCycleFeedbackStateCandidatesReady` 与 `cjguiInternalRuntimeCycleRequestCandidateReady` 复用 readiness 判断，并压缩了重复 open sanity / evaluator pattern。
- `didPrepareCycleFeedback`、`didPrepareNextCycleRequest`、`didPrepareCycleHandoff`、`isReplayReady` 与 `didAcceptReplay` 已保留，因为它们表达上游 gate / readiness / accepted facts，不是纯 candidate-state 派生字段。
- Request wrappers 已保留，因为它们提供 one-hop traceability 与 truth boundary。
- 当前仍没有执行 `CjguiInternalRuntimeCycleRequest` candidate。
- 当前仍没有调用 `cjguiInternalExecuteRuntimeCycle` 作为 replay / execution。
- 当前仍没有 event loop、queue / drain、scheduler、runtime global state write、platform callback、public API 或 C ABI。

## Decision

可以考虑进入 execution boundary，但只能打开极窄 internal-only execution admission draft。

Admission 不是 execution。下一刀最多只能定义 single internal execution admission draft：

- 消费 `CjguiInternalRuntimeReplayOutcomeReport`。
- 判断 future execution boundary 是否允许 accept candidate。
- 将 replay outcome 的 accepted / deferred / blocked summary 转换为 execution-boundary admission summary。
- 可以持有 candidate 作为 trace / admission candidate。
- 不执行 candidate。
- 不调用 `cjguiInternalExecuteRuntimeCycle`。
- 不执行 runtime step。
- 不写 runtime global state。

## Recommended Next Opening

`P1 runtime execution admission draft bundle implementation`

命名刻意使用 admission，而不是 execution，避免误开真实执行边界。

## Not Recommended Now

- 不继续新增 pure wrapper / report layer。
- 不沿 replay outcome 再堆一层同义 summary。
- 不做全链路重命名。
- 不做大规模文件拆分。
- 不做 public API / C ABI。
- 不做 event loop / queue / scheduler / platform callback。
- 不做 real app run / shutdown。
- 不做 window create / close / destroy / release。

## Next Implementation Boundary

- 允许 owner 继续在 `runtime_state.cj`，因为 admission 是 runtime-level boundary summary。
- 只允许新增 `CjguiInternalRuntimeExecutionAdmission*` 或等价 internal value-style draft。
- 只允许消费 `CjguiInternalRuntimeReplayOutcomeReport`。
- 不允许绕过 replay outcome 读取 CycleReplay / Handoff / NextCycle / lower-level facts。
- 不允许真实 execution、runtime step、loop、queue、scheduler、platform callback。
- 不允许 state mutation、public state publication、public runtime API、public C ABI。

## Remaining Cleanup Debt

- `runtime_state.cj` 仍偏胖。
- 进入任何真实 execution / event loop 前，应再次做 owner cleanup / subsystem split decision。
- 当前只允许打开 admission draft；不允许打开真实 execution。
- 本 decision 不应变成每轮 implementation 的默认必读项。
