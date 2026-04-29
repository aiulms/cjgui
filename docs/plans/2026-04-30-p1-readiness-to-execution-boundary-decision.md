# P1 Readiness-to-Execution Boundary Decision

日期：2026-04-30

性质：architecture decision / model quality review

## Landed Facts

- Internal runtime chain 已从 readiness / run boundary / app run / loop draft / lifecycle mutation / state publication / carry-forward / state holder / committed store / feedback / next-cycle request / handoff / replay / replay outcome 形成一条闭环雏形。
- Runtime replay outcome 已能表达 accepted / deferred / blocked summary。
- 当前仍没有执行 `CjguiInternalRuntimeCycleRequest` candidate。
- 当前仍没有把 `cjguiInternalExecuteRuntimeCycle` 作为 replay / execution 调用。
- 当前仍没有 runtime step execution、event loop、scheduler、queue / drain、runtime global state write、platform callback、public API 或 C ABI。

## Decision

暂不建议马上进入真实 execution boundary。

原因：

- `runtime_state.cj` 已偏胖，继续直接打开 execution 会把模型债务带进更高风险边界。
- Pure wrapper / report 层已经较多，后续如果继续线性堆叠会降低可读性和 owner 清晰度。
- Sanity helpers 数量膨胀，尾部 replay / handoff / next-cycle / feedback 链条已经出现重复验证形态。
- 真实 execution boundary 一旦打开，会接近 cycle execution / step execution / future loop semantics，风险明显高于前序 value-style draft 层。

## Recommended Next Opening

`P1 runtime chain model compression / owner cleanup bundle implementation`

## Model Compression / Owner Cleanup Scope

- 优先检查 `runtime_state.cj` 中 replay / handoff / next-cycle / feedback 末端链条。
- 检查是否存在 always-true marker、stored derived Bool、重复 sanity helper pattern、可合并的 request / report wrapper。
- 只能做 behavior-preserving cleanup。
- 不做全链路重命名。
- 不改变 public surface；当前仍没有 public runtime surface。
- 不改变 app/window state shape。
- 不改变 existing transition / mutation semantics。
- 不移动 app/window owner facts。
- 如果 scan 后没有安全 cleanup 候选，应 fail closed，写明原因，然后再回到 execution boundary decision。

## Not Recommended Now

- 不建议继续新增 pure wrapper / report layer。
- 不建议直接进入 event loop / queue / scheduler / platform callback。
- 不建议现在做 public API / C ABI。
- 不建议现在把 `CjguiInternalRuntimeCycleRequest` candidate 交给真实 execution。
- 不建议现在调用 `cjguiInternalExecuteRuntimeCycle` 作为 replay / execution。

## GitNexus Guidance

- 后续 cleanup 前应对 `runtime_state.cj` file-level 和被修改 symbols 做窄口 impact analysis。
- 当前不要求全量 `detect_changes`，因为工作区有历史 dirty diff，容易产生噪声。
- GitNexus 结果只能辅助 owner / impact 判断，不替代 build / smoke / `git diff --check`。

## Stop-Line

- 本 decision 是 boundary / model quality review，不是 preflight，也不是 execution card。
- 本 decision 不应变成每轮 implementation 的默认必读项。
- 下一轮若进入 cleanup，只能围绕 runtime chain model compression / owner cleanup 做行为保持型整理；不得借机打开真实 execution boundary。
