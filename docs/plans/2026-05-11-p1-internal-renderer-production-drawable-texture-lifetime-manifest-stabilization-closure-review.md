# Production drawable texture lifetime 清单封账复核

日期：2026-05-11

## 封账内容

本阶段 manifest 固定为 planning-only：

- 当前 tail：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- Runtime input：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`
- Owner：[runtime_renderer_drawable_texture_lifetime_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_texture_lifetime_planning.cj)
- Probe：[verify_native_bridge_drawable_texture_lifetime.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_texture_lifetime.sh)

## 封账结论

Production drawable texture lifetime 尚未实现。当前只证明下一步需要补齐 production visible window semantics、display-backed layer ownership、drawable token-local acquire / classify / release、double release / stale fail-closed，以及 descriptor / drawable / layer / device cleanup 共同所有权。

## 不得误读

- 不是 drawable-ready。
- 不是 `nextDrawable` production permission。
- 不是 descriptor color attachment permission。
- 不是 encoder / command buffer / commit / present permission。
- 不是 render permission。
- 不是 GPU submission permission。
- 不是 backend-ready truth。
- 不是 renderer state write permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，production drawable texture lifetime 已封账为 planning-only readiness。
- 本轮是否改变 canonical tail / endpoint：是，canonical tail 固定为 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner；truth 只说明 lifetime implementation 前置缺口，不允许包装成 drawable acquisition implementation。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`；现已由 implementation recovery 与 no-submit planning 接续，并转为 `P1 internal Renderer render command encoder creation blocker reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游已接续

[Drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 已接续本 manifest closure。该接续确认 production drawable lifetime 暂停、visible-window production harness 独立化，并仍禁止 production `nextDrawable`、drawable acquire / release、color attachment、encoder creation、draw、`commit` / `present`、GPU submission、render、public API 与 renderer state write。
