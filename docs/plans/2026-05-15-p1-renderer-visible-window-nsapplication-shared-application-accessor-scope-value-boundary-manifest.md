# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Scope Value Boundary Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope value boundary implementation`。

本阶段新增 runtime internal owner，将 shared-application accessor scope 固定为 value-only readiness：只消费上游 guard policy readiness，只声明 accessor scope 仍 blocked，并继续保留 application singleton accessor blocked、application singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、headless CI fail-closed、teardown before visible required、non-user-visible mode required、activation policy / activation / event loop blocked、visible order / drawable / render blocked、no public surface、no renderer state write 与 no backend-ready truth。

## 当前 Endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness`
- Owner file：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_scope.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_scope.cj)
- Upstream manifest：[shared-application guard policy value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-guard-policy-value-boundary-manifest.md)
- Preflight decision：[shared-application accessor scope preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-scope-preflight-decision.md)

## 探针

- [verify_renderer_visible_window_nsapplication_shared_application_accessor_scope_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_scope_owner.sh)

## 当前 Truth

当前 truth 仅限以下 internal value facts：

- application singleton accessor scope remains blocked
- application singleton accessor remains blocked
- application singleton creation remains blocked
- shared-application main-thread gate remains required
- bounded run loop and auto-close remain required before any future accessor scope
- headless CI route remains fail-closed
- teardown-before-visible and non-user-visible mode remain required
- activation policy mutation, activation and event loop remain blocked
- native visible order remains blocked
- production drawable and render remain blocked
- no public surface, no renderer state write and no backend-ready truth remain fixed

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不配置 color attachment；不创建 render encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不返回 pointer / handle / `id` / `Class`；不写 renderer state；不扩 public API；不修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj) 或 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。

## Same-shape Boundary Brake

不得把本 endpoint 包装成 application-ready、visible-ready、drawable-ready、render-ready、state-write-ready、backend-ready、diagnostics publication、receipt / record / publication wrapper 或 public API shell。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard preflight decision`
