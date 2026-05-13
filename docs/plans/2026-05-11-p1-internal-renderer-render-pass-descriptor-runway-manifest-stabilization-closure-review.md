# MTLRenderPassDescriptor 路线清单稳定封账复核

日期：2026-05-11

## 封账结果

render pass descriptor runway 已按 A/B 路线封账：

- production native bridge 提供 token-backed `MTLRenderPassDescriptor` create / destroy / classify callable。
- runtime internal owner 只调用 create / classify / destroy，并将 token lifecycle 脱水为 internal facts。
- color attachment、drawable texture 与 encoder creation 继续以 still-blocked facts 固定。
- 当前 tail 是 `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassDescriptorCreateDestroyDraft()`。

## 同步范围

已同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 保留风险

- Drawable texture lifecycle 尚未成为 production token-backed render target contract。
- Color attachment configuration 尚未实现。
- Render command encoder 尚未创建。
- `commit` / `present` / GPU submission / render 仍全部禁止。

## 设计意图出口自检

- 本轮是否改变主题状态：是，render pass descriptor create / destroy first slice 已完成并封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 descriptor owner / native callable / probe；truth 只到 descriptor lifecycle facts；stop-line 继续禁止 color attachment / encoder / draw / commit / present / GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer render pass descriptor color attachment preflight decision`；现已由 [render pass descriptor color attachment planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-manifest.md) 接续，当前后续入口转为 `P1 internal Renderer render pass descriptor color attachment implementation recovery decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
