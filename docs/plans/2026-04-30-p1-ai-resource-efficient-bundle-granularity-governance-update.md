# P1 AI Resource-Efficient Bundle Granularity Governance Update

日期：2026-04-30

性质：docs-only / governance correction / implementation granularity

## 背景

近期 Action Router runway 在防止 wrapper 回潮、禁止 execution / queue / provider 越界方面是有效的，但局部 opening 写得过窄，导致执行 AI 每轮读取 tracker、manifest、closure、源码并运行 build / smoke 后，只新增一个薄 value type、一个 builder 或一个 helper。

这会浪费模型资源和人工复核成本。治理目标不是让每一刀都极小，而是在清晰 stop-line 内打开足够完整的 bounded implementation 窗口。

## 决定

新增 AI 资源效率规则：

- 同一 owner、同一 truth、同一 write set、同一 stop-line 和同一验证路径清楚时，默认使用 W2 / W3 same-owner bundle。
- 禁止把 `no execution`、`no queue`、`no provider` 等 stop-line 解释为“一轮只能新增一个 symbol”。
- 连续两轮低风险 implementation 只新增薄 value-stage / helper / projection 后，下一轮必须升级为 bundle、consolidation 或 manifest stabilization。
- docs-only decision 不作为每轮代码后的固定节拍；只有 owner、truth、side effect、public surface、platform、queue / drain、scheduler 或 runtime cycle 边界变化时，才需要新的 decision。
- closure 应说明本轮粒度是否匹配上下文装载、GitNexus、build / smoke 和人工复核成本。

## Action Router 立即影响

当前 Action Router 已有：

```text
ActionIntent
-> ActionAdmission
-> ActionRoutingResult
-> ActionDispatchAdmission
-> ActionDispatchPlan
-> ActionDispatchConvergence
-> ActionDispatchCommitCandidate
-> ActionDispatchFinalization
-> ActionDispatchRecord
```

下一步不应继续产生“单 value type + builder + helper”的微切片 opening。当前 next opening 改为：

```text
P1 internal Action Router action boundary same-owner bundle decision / implementation runway
```

该 decision 必须选择 W3 same-owner internal bundle 或 tail consolidation。除非发现 HIGH / CRITICAL 风险，不得继续输出 one-symbol micro-slice。

## 保持不变的 stop-line

本次松绑只针对实现粒度，不放开高风险边界。仍禁止：

- action execution
- AI provider / prompt / external agent / public surface
- public API / C ABI
- queue storage / enqueue / drain
- event loop / scheduler / platform callback
- runtime cycle execution
- runtime global state write
- 修改 critical `runtime_state.cj`，除非先做 file-size / owner split check

## 去重说明

本规则不新增一套独立治理体系。主规则落在 [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)；[GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md) 与 [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md) 只保留短引用，避免同一规则在多处发散。

## 同步文件

- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
