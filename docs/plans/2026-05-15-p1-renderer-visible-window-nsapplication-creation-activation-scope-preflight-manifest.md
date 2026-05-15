# P1 Renderer 可见窗口 NSApplication Creation / Activation Scope 预检 Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication creation and activation scope preflight decision`。阶段完成后，Renderer 主线确认可以继续到 internal value boundary owner，但仍不允许真实创建 `NSApplication`、修改 activation policy、activation、运行 AppKit event loop 或执行 native visible order implementation。

## 当前输入

- Upstream：`CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness`
- Upstream default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationGuardPolicyDraft()`
- Upstream manifest：[NSApplication guard policy value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-guard-policy-value-boundary-manifest.md)

## 决策结果

选择 A：只允许下一刀新增 internal creation / activation scope value boundary owner。

## 停止线

不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下游

Downstream next opening：

`P1 internal Renderer visible-window production harness NSApplication creation and activation scope value boundary bundle implementation`

## GitNexus 结果

GitNexus 对 upstream guard policy endpoint / default draft 与 future creation activation scope endpoint 返回 not found / UNKNOWN；本轮不把该结果当作安全证明，后续实现必须继续使用源码读取、build、owner probe、forbidden scan 与 manifest reachability 兜底。

## 设计意图出口自检

- manifest 已同步当前 upstream、decision、stop-line 与 next opening。
- topic manifest / README / tracker / design intent index 需要在 implementation bundle 后同步到新的 endpoint。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
