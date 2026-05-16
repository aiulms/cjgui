# P1 Internal Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe First Slice Manifest Stabilization Closure Review

状态：manifest closure / navigation sync required

## 稳定项

本轮 first slice manifest 已固定：

- 当前 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Owner file：[runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj)
- Native probe：[verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence_owner.sh)

## Manifest conclusion

First slice 已打开 isolated actual accessor call probe surface，但当前 run 因缺 preexisting `NSApplication` singleton 而 fail-closed，不调用 accessor，不创建 application。

该结论不能升级为 production runtime permission、public API、production C ABI、application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready truth。

## 导航同步要求

本 closure 需要同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [renderer backend readiness topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer implementation admission topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 下一边界

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preexisting-application harness decision`

