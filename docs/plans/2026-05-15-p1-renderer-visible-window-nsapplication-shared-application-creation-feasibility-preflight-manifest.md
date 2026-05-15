# P1 Renderer 可见窗口 NSApplication Shared-Application Creation Feasibility 预检 Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility preflight decision`。预检结论是：shared-application creation feasibility 可以打开，但不得直接调用 `NSApplication.sharedApplication`；下一步只能先做 internal value-style feasibility owner。

## 当前上游

- Upstream endpoint：`CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`
- Upstream default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationCreationActivationScopeDraft()`
- Upstream manifest：[NSApplication creation / activation scope value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-creation-activation-scope-value-boundary-manifest.md)

## 事实边界

只承认当前上游已经固定 creation / activation scope value facts；这些 facts 仍不是 `sharedApplication` call permission、`NSApplication` creation permission、activation permission、activation policy mutation permission、event loop permission、native visible order permission、production drawable permission、render permission、renderer state write permission、public API permission 或 backend-ready truth。

## 下一入口

`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility value boundary bundle implementation`

## 停止线

不创建 `NSApplication`；不调用 `sharedApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

GitNexus 对上游最新 endpoint / default draft 返回 not found / UNKNOWN；本预检未把 UNKNOWN 当作安全证明，后续 implementation 必须继续用 source reading、build、probe、smoke、forbidden scan 与 manifest check 兜底。

## 设计意图出口自检

- manifest 已同步当前 truth、stop-line 与下一 opening。
- topic manifest / README / tracker / design intent index 需要在 implementation 封账后一起同步到新的 canonical tail。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
