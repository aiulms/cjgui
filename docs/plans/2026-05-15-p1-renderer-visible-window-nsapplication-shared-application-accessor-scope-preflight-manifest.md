# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Scope 预检 Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope preflight decision`。本阶段选择 A：可以进入 internal value-style accessor scope boundary，但不能直接调用 application singleton accessor。

## 当前上游

- Upstream endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness`
- Upstream default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyDraft()`
- Upstream manifest：[shared-application guard policy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-guard-policy-value-boundary-manifest.md)

## 当前 truth

只承认 accessor scope 仍必须保持 blocked、singleton creation 仍 blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、activation policy / activation / event loop still blocked、native visible order / drawable / render still blocked。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不配置 color attachment；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj) 或 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。

## 后续入口

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope value boundary implementation`

## 设计意图出口自检

- 本 manifest 改变 Renderer 主线 next opening，需要同步 README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifests。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
