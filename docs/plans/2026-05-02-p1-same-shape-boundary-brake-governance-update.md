# P1 Same-shape Boundary Brake Governance Update

日期：2026-05-02

性质：docs-only / governance correction / thin-wrapper brake

## 背景

Renderer backend runway 已从 handoff 推进到 backend adapter、contract、capability、adapter selection 与 adapter binding。近期几个 owner file 行数和形状高度接近，说明当前治理已经守住 no-render / no-platform stop-line，但也出现了 same-shape boundary 连续推进的风险。

本次更新不是否定 value-style boundary。它只补上一条更明确的刹车规则：当连续边界已经呈现同构模板时，下一轮不能只因为 next opening 名字自然就继续实现。

## 新增规则

新增 Same-shape Boundary Brake：

- 同一 runway 连续出现两个以上结构高度相似的 value boundary 后，下一轮必须做 thin-wrapper review。
- 行数不是判定标准；风险信号是相同 type / builder / default draft 结构、相同 open / defer / blocked / inconsistent 分支，以及主要差异只是名词替换。
- 如果新边界不能说明新增的不可替代 owner truth、consumer、gate、integration 或风险证据，默认选择 milestone / manifest stabilization / consolidation。
- closure 必须说明本轮为什么不是 thin wrapper，或为什么选择刹车。

## 立即影响

当前 renderer backend chain：

```text
RendererPacketHandoffReceipt
-> RendererBackendNoRenderReadiness
-> RendererBackendNoRenderContractReadiness
-> RendererBackendNoRenderCapabilityReadiness
-> RendererNoRenderSelectionReadiness
-> RendererNoRenderBindingReadiness
```

`CjguiInternalRendererNoRenderBindingReadiness` 暂时作为 renderer backend tail milestone endpoint。下一轮默认做:

```text
P1 internal Renderer backend tail milestone / manifest stabilization bundle implementation
```

在没有平台资源、backend object、command buffer、native handle、render execution 或 renderer state truth 前，不直接继续实现 adapter lifecycle value boundary。

## 同步文件

- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## 保持不变的 stop-line

本规则不放开 Metal / AppKit / backend implementation、CAMetalLayer / MTLDevice / command buffer、native handle / raw pointer、render / draw call、GPU batching、dirty-region / diff / patch、Widget / Layout / Text / IME / Accessibility / ECS、public surface expansion 或 `runtime_state.cj` 修改。
