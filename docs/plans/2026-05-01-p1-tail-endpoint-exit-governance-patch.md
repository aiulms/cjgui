# P1 Tail Endpoint Exit Governance Patch

日期：2026-05-01

## 背景

Action Router guarded execution 线已经推进到：

`ActionGuardedExecutionFinalization -> ActionGuardedExecutionResultPublication -> ActionGuardedExecutionHandoffCandidate`

这条链路没有越过真实 action execution / queue / provider / public surface stop-line，但它暴露了一个治理缺口：治理文档已经要求不要 one-symbol 小碎步，却没有足够明确地规定 canonical endpoint 之后必须换挡。因此执行 AI 可以用 W2/W3 bundle 的形式继续追加新的 local value-stage，形成“合规但空转”的 tail self-wrapping。

## 补丁结论

本轮补丁新增 `Tail Endpoint Exit Gate`：

- manifest / tracker / closure 已标记 canonical endpoint 后，下一步默认不得继续同 owner 追加薄 tail。
- 允许的出口是 downstream consumer / handoff integration、permission gate decision、milestone closure、tail consolidation，或真实边界前置卡。
- 如果仍要新增本地 value-stage，必须证明它承载新的不可替代 truth，并说明新增后的 exit 条件。
- 单纯把上一层 `didX / defer / blocked` 改名投影到下一层，不构成新的 truth。

## 修改范围

- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)：新增 Tail Endpoint Exit Gate 与 canonical tail self-wrapping 检查。
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)：要求 execution card 在 canonical endpoint 后优先选择出口，而不是继续授权本地 tail self-wrapping。
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)：新增 canonical endpoint 是出口的总则。
- [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)：明确 `CjguiInternalActionGuardedExecutionHandoffCandidate` 是当前 canonical endpoint，并禁止继续追加 handoff readiness / record / outcome / publication record 等同构薄层。

## 对当前主线的影响

当前 Action Router tail 不继续追加本地 wrapper。下一步应转向：

`P1 internal Action Router handoff endpoint milestone / downstream consumer decision`

该 decision 应在以下方向中选择：

- 下游 owner 消费 `CjguiInternalActionGuardedExecutionHandoffCandidate`；
- 真实 execution 前 permission gate decision；
- Action Router tail milestone closure；
- tail consolidation。

不得默认选择“再新增一个 Action Router local tail value-stage”。

## Stop-line

本补丁不放开真实 action execution、queue enqueue / drain、AI provider / public API、event loop / scheduler / platform callback、runtime cycle 或 runtime global state write。它只修正出口规则，防止治理把强 AI 资源耗在同一 tail 的自我包装上。
