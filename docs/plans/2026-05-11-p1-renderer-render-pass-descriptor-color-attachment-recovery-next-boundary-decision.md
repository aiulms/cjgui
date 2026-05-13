# 渲染通道描述符颜色附件恢复后续判断

日期：2026-05-11

## 结论

选择下一步：

`P1 internal Renderer production drawable texture lifetime preflight decision`（已接续；当前主线进一步转为 `P1 internal Renderer pipeline state no-draw planning preflight decision`）

## 判断

当前 recovery 已固定：color attachment implementation 的第一阻塞点是 production drawable texture lifetime，而不是 descriptor token lifecycle。

因此下一步应先评估：

- 是否可以新增 production drawable token / texture lifetime support。
- 是否可以证明 drawable acquire / classify / release / cleanup 不需要 present、command buffer、encoder 或 render。
- 是否可以证明 descriptor / drawable / layer / device cleanup 共同所有权。
- 是否仍必须保留 no encoder、no draw、no commit、no present、no GPU submission、no renderer state write stop-line。

## 暂缓项

- 暂缓 `P1 internal Renderer render pass descriptor color attachment first slice preflight decision`。
- 暂缓 `P1 internal Renderer render pass descriptor color attachment runtime FFI call owner preflight decision`。
- 拒绝直接进入 render command encoder planning。

## 设计意图出口自检

- 本轮是否改变主题状态：是，color attachment recovery 已固定 blocker。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 production drawable texture lifetime / cleanup co-ownership absent。
- 本轮是否改变唯一 next opening：是，当时转为 `P1 internal Renderer production drawable texture lifetime preflight decision`；现已由 production drawable texture lifetime planning、implementation recovery、no-submit planning 与 blocker reconciliation 接续，当前唯一 next opening 为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。

## 下游已接续

[Production drawable texture lifetime manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 已接续本 decision；下游仍不授权 color attachment、encoder creation、draw、`commit` / `present`、GPU submission、render、public API 或 renderer state write。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
