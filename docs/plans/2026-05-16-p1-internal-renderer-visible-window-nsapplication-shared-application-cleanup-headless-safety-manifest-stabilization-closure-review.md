# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 清单稳定化复核

状态：manifest stabilization closure / no runtime truth

## 稳定化结果

Cleanup / headless safety manifest 已固定当前 owner、truth、stop-line 与下游入口。该 endpoint 只表示 internal value facts，不是 application singleton accessor call permission，也不是 `NSApplication` creation / activation、event loop、visible order、drawable、render、state write 或 backend-ready truth。

## 已固定内容

- Current endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh)

## 停止线复核

没有新增 native C ABI、没有新增 `foreign func`、没有修改 native bridge、没有修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`，没有打开 application singleton accessor call、application creation / activation、activation policy mutation、event loop、visible order、drawable、render、renderer state write、public API、public C ABI 或 backend-ready truth。

## 出口自检

- 清单与 closure 指向同一 current endpoint。
- 下游是 cleanup / headless safety stop-line reconciliation decision。
- 后续若讨论 actual accessor call，必须先过 explicit docs-only risk / product decision；当前不自动授权。
