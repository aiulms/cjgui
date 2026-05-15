# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard 预检清单

## 清单定位

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard preflight decision`。本阶段选择 A：可以进入 internal accessor native guard owner，但只能复用既有 no-side-effect shared-application guard C ABI，不能新增 native bridge C ABI。

## Canonical 输入

- 上游 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`
- 上游 default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeDraft()`
- 既有 native evidence：`cjgui_native_bridge_nsapplication_shared_application_guard_*`

## Truth

只承认 accessor native guard 可以继续证明 application singleton accessor call still blocked、accessor scope still blocked、singleton creation still blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、activation policy / activation / event loop still blocked、native visible order / drawable / render still blocked。

本阶段不承认 application singleton accessor call permission、`NSApplication` creation / activation permission、activation policy mutation permission、event loop permission、native visible order implementation permission、production drawable permission、render permission、renderer state write permission、public API / public C ABI permission 或 backend-ready truth。

## Downstream

下一 opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard implementation`

## 维护备注

后续 implementation 必须新增 owner probe，并复跑既有 native guard probe、build、forbidden scan、protected path scan 与 manifest reachability。若新增 native C ABI、修改 `runtime/cjgui/cjpm.toml` 或触碰 `runtime_state.cj`，视为越过本 manifest 停止线。
