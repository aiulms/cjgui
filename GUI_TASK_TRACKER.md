# 仓颉 GUI 项目任务账本

最后更新：2026-04-30

本文件现在只做当前状态仪表盘，不再保存逐轮流水账。历史决策、closure、execution card 与 compaction 由 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 索引；本轮未新增 archive，因为被移除的 tracker 长历史已由 plans 索引与各 closure review 可追溯。

## 当前阶段

当前项目处于：

> `P1 runtime 受限实现 / execution convergence runway`

长期目标仍是仓颉原生 GUI runtime / framework：上层尽量保持仓颉原生，底层通过极窄平台桥接接入窗口系统与渲染后端。当前还不是成熟 GUI toolkit，也不提供稳定 public API 或 public C ABI。

## 最小上下文入口

后续会话默认只需先读：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)：仓库总入口。
- 本 tracker：当前阶段、tail、stop-line、next opening。
- [2026-04-30-p1-runtime-tracker-compaction-execution-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-tracker-compaction-execution-runway.md)：当前 execution runway。
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)：runtime 内部链路与 stop-line。
- [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)：仅按 next opening 窄口读取相关 symbols。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)：历史索引，不默认全文阅读。

## 当前 runtime execution tail

当前 execution tail 已回到：

> `CjguiInternalRuntimeExecutionAttemptReport`

保留的 first internal execution attempt：

- `CjguiInternalRuntimeExecutionAttemptRequest`
- `CjguiInternalRuntimeExecutionAttemptReport`
- `cjguiInternalBuildRuntimeExecutionAttemptRequest`
- `cjguiInternalEvaluateRuntimeExecutionAttempt`
- `cjguiInternalExecuteRuntimeExecutionAttemptDraft`
- `cjguiInternalExecuteDefaultRuntimeExecutionAttemptDraft`

已移除的 pure post-attempt wrapper：

- `CjguiInternalRuntimeExecutionAttemptOutcomeRequest`
- `CjguiInternalRuntimeExecutionAttemptOutcomeReport`
- outcome builder / evaluator / executor
- outcome open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers

当前语义边界：

- allowed path 最多执行一个 `CjguiInternalRuntimeCycleRequest` candidate。
- blocked / deferred path 不执行 candidate。
- attempt report 不持有伪造 `CjguiInternalRuntimeCycleResult`。
- 这不是 event loop、scheduler、queue / drain、app run、global state commit、public API 或 C ABI。

## 最近关键 landed facts

- macOS AppKit / Metal smoke、auto-close guard、screenshot / frame hash / readback 相关实验已形成验证基础，但仍是 lab，不是 public runtime contract。
- `runtime/cjgui` 已具备最小 compilable package / internal source skeleton。
- app/window lifecycle owner-local state 已存在，并已完成 first internal immutable-copy mutation。
- runtime chain 已走过 readiness、run boundary、AppRun / RunLoop draft、lifecycle mutation、state publication、carry-forward、state holder、committed store、cycle feedback、next-cycle request、handoff、replay、replay outcome、execution admission、dry-run plan。
- first internal execution attempt 已落地：allowed path 调用一次 `cjguiInternalExecuteRuntimeCycle(plan.cycleRequestCandidate)`，blocked / deferred path 不执行。
- governance slimming / execution pivot 已生效：冻结继续新增 pure post-attempt wrapper / observation / feedback / result report 层。
- tail outcome wrapper compression 已完成：post-attempt outcome wrapper 被删除，execution tail 回到 attempt report。
- 当前 tracker 已压缩为 current-state dashboard；历史追溯入口改为 plans README 与 closure review 链。

## 当前 verification baseline

最近 runtime code 变更的验证基线来自 tail outcome wrapper compression closure：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-runtime-tail-outcome-wrapper-compression-target --skip-script` 通过，仅既有 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。
- GitNexus：outcome symbols not found / UNKNOWN；fallback `runtime_state.cj` file-level upstream impact 为 LOW，direct callers 0，affected processes 0。

本轮 tracker compaction 是 docs-only，不需要跑 `cjpm build` 或 smoke guard。

## 当前统一 stop-line

继续禁止：

- public runtime API / public C ABI。
- AppKit / Metal / Objective-C 新接入，platform object、native handle、raw pointer 暴露。
- event loop、`while` loop / scheduling loop、scheduler、queue / drain、callback binding。
- app run / shutdown。
- window create / request close / close / destroy / release。
- runtime global state write、global mutable singleton。
- 多 cycle execution、next-cycle execution、真实 runtime step 扩展。
- new app/window state mutation、in-place mutation、改变既有 state field semantics。
- Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility。
- 修改 `runtime/cjgui/cjpm.toml`、`labs/macos_bridge_smoke` tracked source、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`。

## 当前 active opening

### `P1 runtime execution convergence bundle implementation`

性质：bounded implementation / execution convergence / governance slimming

目标：

- 默认从 `CjguiInternalRuntimeExecutionAttemptReport` 继续推进。
- 不再新增 pure outcome wrapper / report / draft layer。
- 不再新增单纯 sanity helper bundle。
- 如果需要新增类型，必须证明它替代、压缩或承接现有 execution attempt，而不是把 tail 再包一层。
- 优先让 first internal execution attempt 与已有 state / cycle / owner 边界收敛。

## 当前建议的下一步

> `P1 runtime execution convergence bundle implementation`

下一轮应直接进入 runtime execution convergence implementation。若要修改 `runtime_state.cj` 中 existing symbols，必须先按 AGENTS / GitNexus 要求做窄口 upstream impact；如遇 HIGH / CRITICAL 风险则停止。

本 opening 不批准 public API / C ABI、event loop、queue / scheduler、platform callback、app run / shutdown、window create / close / destroy / release、多个 cycle execution、runtime global state write，或继续堆 pure wrapper / report / sanity 层。
