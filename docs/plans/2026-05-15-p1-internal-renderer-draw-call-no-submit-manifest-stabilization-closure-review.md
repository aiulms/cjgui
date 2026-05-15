# 绘制调用 no-submit 清单封账复核

本轮完成 `P1 internal Renderer draw call no-submit planning runway bundle` 的 manifest stabilization。新增 manifest：

- [2026-05-15-p1-renderer-draw-call-no-submit-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md)

## 固定结论

Canonical endpoint 固定为 `CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`；runtime input 固定为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()`。

Current truth 仅限 draw call no-submit planning facts、still-blocked C ABI observed facts、draw input bundle facts 与 no-draw-input-bundle readiness facts。

## 已同步索引

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 保持关闭

本轮没有创建 render command encoder，没有调用 `setRenderPipelineState`，没有调用 `setVertexBuffer`，没有调用 `drawPrimitives` / `drawIndexedPrimitives`，没有创建 index buffer，没有调用 `commit` / `present`，没有提交 GPU work，没有执行 render，没有写 renderer state，没有扩 public API，没有返回 pointer / handle / `id` / `Class`。

## 唯一后续入口

`P1 internal Renderer no-submit render pipeline branch reconciliation decision`

该入口只允许 docs-first reconciliation，不能把 draw input bundle facts 包装成 encoder binding、draw、GPU submission、render、renderer state write、backend-ready truth、public API、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，draw call no-submit manifest 已封账。
- 本轮是否改变 canonical tail / endpoint：是，固定为 `CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner chain、native still-blocked C ABI 与 stop-line 已写入 manifest。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
