# Pipeline state create/destroy no-draw 清单稳定化复核

日期：2026-05-13

状态：manifest stabilization / sealed

## 稳定化结论

本轮清单固定 `MTLRenderPipelineState` create/destroy no-draw 的最小 implementation truth：production native bridge 可在固定容量 table 内创建、分类、销毁 token-backed pipeline state；runtime internal owner 可通过 FFI 局部调用 create / classify / destroy 并脱水为 facts。

这不是 renderer backend-ready truth，不是 render permission，不是 GPU submission permission，不是 encoder binding permission，也不是 public API。

## 已同步入口

需要同步并已在本稳定化阶段推进的导航入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 验证责任

最终验证需要覆盖 native pipeline state probe、runtime-adjacent pipeline state call probe、既有 native probes、`cjpm build`、smoke auto-close、Markdown link / reachability / 中文抽查、public declaration scan、forbidden scan、protected path scan 与 GitNexus `detect-changes`。

若后续验证发现 pipeline state creation 需要 drawable texture / color attachment / encoder 或 build/probe 不稳定，应停止到 implementation recovery，不得伪造 encoder binding 或 render permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，pipeline state create/destroy no-draw manifest 已稳定化。
- 本轮是否改变 canonical tail / endpoint：是，最新 tail 是 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 链扩展到 pipeline state planning / create-destroy / runtime-call；truth 只限 pipeline state no-draw lifecycle facts；stop-line 继续禁止 encoder、draw、commit、present、GPU submission、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。
