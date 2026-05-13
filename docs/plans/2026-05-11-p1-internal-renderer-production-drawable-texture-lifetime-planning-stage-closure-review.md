# Production drawable texture lifetime 规划阶段复核

日期：2026-05-11

## 本轮完成

本轮按 A 路线完成 planning / ownership facts：

- 新增 runtime owner：[runtime_renderer_drawable_texture_lifetime_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_texture_lifetime_planning.cj)
- 新增 planning probe：[verify_native_bridge_drawable_texture_lifetime.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_texture_lifetime.sh)
- 固定 endpoint：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- 固定 default draft：`cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- 固定 runtime input：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`

## 关键结论

当前不能实现 production drawable acquire / classify / release first slice。原因不是 isolated probe 无法观察 drawable，而是 production runtime 仍缺少可封账的 texture lifetime 所有权：

- Production visible window semantics 仍未进入 runtime。
- Production display-backed layer ownership 仍未封账。
- Drawable token-local acquire / classify / release 仍未定义。
- Double release / stale drawable fail-closed 仍未实现。
- Descriptor / drawable / layer / device cleanup 共同所有权仍未证明。

## 未实现内容

- 未新增 production drawable texture lifetime C ABI。
- 未调用 `nextDrawable`。
- 未新增 drawable token table。
- 未新增 runtime FFI call owner。
- 未 present。
- 未创建 command buffer / encoder。
- 未调用 `commit`。
- 未提交 GPU work。
- 未执行 render。
- 未写 renderer state。
- 未新增 public API / diagnostics。

## GitNexus 记录

- 上游 endpoint / default draft 与新增 planning owner 在当前索引中返回 `UNKNOWN` / not found / impactedCount `0`。
- 未出现 HIGH / CRITICAL 风险输出。
- 使用源码阅读、`cjpm build`、planning probe、native forbidden scan、public declaration scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，production drawable texture lifetime 从 preflight 进入 planning facts。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner；truth 只说明 production drawable texture lifetime 缺口，不说明 drawable 可生产侧获取。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`；现已由 implementation recovery 与 no-submit planning 接续，并转为 `P1 internal Renderer render command encoder creation blocker reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游已接续

[Drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 已接续本 closure；随后 [render command encoder no-submit planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md) 继续接续。当前唯一后续入口转为 `P1 internal Renderer render command encoder creation blocker reconciliation decision`。
