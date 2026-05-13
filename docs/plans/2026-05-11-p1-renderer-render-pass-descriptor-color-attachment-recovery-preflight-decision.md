# 渲染通道描述符颜色附件恢复预检

日期：2026-05-11

## 结论

本轮选择 A：recovery analysis / blocker manifest。

不进入 B / C / D：

- 不新增 production drawable token-local acquisition support。
- 不配置 `MTLRenderPassDescriptor.colorAttachments[0]`。
- 不新增 color attachment runtime FFI call owner。

## 判断

当前 blocker 仍成立：

- `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness` 只证明 attachment configuration 所需前置尚缺。
- Drawable no-present acquisition 仍是 isolated visible-window probe evidence，不是 production drawable token / texture lifecycle。
- Production native bridge 当前没有 production drawable token table、drawable texture ownership contract 或 drawable release / cleanup API。
- Descriptor / drawable / layer / device cleanup 共同所有权尚未被 production contract 证明。
- 直接配置 `colorAttachments[0]` 会把 isolated probe evidence 误升级为 production descriptor truth。

## 禁止误读

本预检不批准 `colorAttachments[0]` configuration、drawable texture binding、load / store action、clear color、render command encoder、draw、`commit`、`present`、GPU submission、render、renderer state write、public API、public diagnostics、native pointer / handle / `id` / `Class` return。

## GitNexus 记录

- `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness`：当前索引返回 `UNKNOWN` / not found / impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentPlanningDraft`：当前索引返回 `UNKNOWN` / not found / impactedCount `0`。
- `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`：当前索引返回 `UNKNOWN` / not found / impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft`：当前索引返回 `UNKNOWN` / not found / impactedCount `0`。
- 未出现 HIGH / CRITICAL 风险输出；本轮使用源码阅读、build、probe 与 scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，color attachment 从 planning next opening 进入 recovery blocker 固定。
- 本轮是否改变 canonical tail / endpoint：预检建议改为 `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，建议新增 recovery owner；truth 限 production drawable texture lifetime / cleanup co-ownership 缺口。
- 本轮是否改变唯一 next opening：是，当时若 recovery 完成，转为 `P1 internal Renderer production drawable texture lifetime preflight decision`；现已由 production drawable texture lifetime planning、implementation recovery、no-submit planning 与 blocker reconciliation 接续，当前主线转为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。
- 是否同步 topic manifest：待 closure / manifest 完成后同步。
- 已同步哪些 topic manifest：待同步。
