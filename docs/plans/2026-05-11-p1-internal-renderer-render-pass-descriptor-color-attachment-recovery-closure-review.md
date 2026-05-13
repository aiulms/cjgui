# 渲染通道描述符颜色附件恢复阶段复核

日期：2026-05-11

## 本轮完成

本轮按 A 路线完成 recovery analysis / blocker facts：

- 新增 runtime owner：[runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj)
- 新增 recovery probe：[verify_native_bridge_render_pass_descriptor_color_attachment_recovery.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_render_pass_descriptor_color_attachment_recovery.sh)
- 固定 endpoint：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`
- 固定 default draft：`cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft()`
- 固定 runtime input：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness`

## 关键结论

当前不能进入 production color attachment first slice。缺口不是 `MTLRenderPassDescriptor` token lifecycle，而是 drawable texture 的 production lifetime 与 cleanup co-ownership：

- isolated no-present `nextDrawable` 只能证明环境 probe 可观察 drawable。
- production runtime 没有 drawable token / texture lifetime support。
- production runtime 没有 descriptor / drawable / layer / device cleanup 共同所有权。
- 因此不能配置 `colorAttachments[0]`，也不能设置 load / store action 或 clear color。

## 未实现内容

- 未新增 production drawable texture lifetime C ABI。
- 未配置 `colorAttachments[0]`。
- 未绑定 drawable texture。
- 未新增 color attachment runtime FFI call owner。
- 未创建 render command encoder。
- 未 draw / `commit` / `present`。
- 未提交 GPU work。
- 未执行 render。
- 未写 renderer state。
- 未新增 public API / diagnostics。

## GitNexus 记录

- 上游 endpoint / default draft 与新增 recovery owner 在当前索引中返回 `UNKNOWN` / not found / impactedCount `0`。
- 未出现 HIGH / CRITICAL 风险输出。
- 使用源码阅读、`cjpm build`、既有 probes、recovery probe、native forbidden scan、public declaration scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，render pass descriptor color attachment 已从 planning facts 进入 recovery blocker facts。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 recovery owner；truth 只说明 production drawable token / texture lifetime 与 cleanup co-ownership 尚缺，不说明 attachment 可配置。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer production drawable texture lifetime preflight decision`；现已由 production drawable texture lifetime planning、implementation recovery 与 no-submit planning 接续，当前主线转为 `P1 internal Renderer render command encoder creation blocker reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游已接续

本 closure 已由 [production drawable texture lifetime planning stage closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-production-drawable-texture-lifetime-planning-stage-closure-review.md) 接续。下游只封住 planning facts，不把 recovery blocker 解释成 production drawable acquisition、descriptor color attachment、encoder、present、commit、GPU submission、render 或 renderer state write permission。

后续又由 [drawable texture lifetime implementation recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-drawable-texture-lifetime-implementation-recovery-closure-review.md) 接续。该 recovery 选择暂停 production drawable lifetime implementation，并把 visible-window production harness 独立成恢复分支；主线只允许转向 render command encoder no-submit planning，不允许创建 encoder、配置 color attachment、draw、`commit` / `present`、GPU submission、render 或 renderer state write。
