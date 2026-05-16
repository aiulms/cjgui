# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard Manifest 稳定化 Closure 复核

状态：manifest stabilization closure / implementation manifest / no actual accessor call

## Closure 范围

本 closure 复核 [actual accessor call preflight guard manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest.md) 是否完整记录 owner、truth、stop-line 与 next opening。

## 通过项

- Manifest 指向 runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard.cj)。
- Manifest 指向 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh)。
- Manifest 固定 canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`。
- Manifest 固定 default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`。
- Manifest 固定 runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`。
- Manifest 明确 actual-call preflight guard facts 不等于 actual accessor call permission。

## 未改变项

- 未修改 native bridge `.h` / `.m`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)。
- 未新增 public declaration、public C ABI、public diagnostics 或 renderer state write。

## Closure 结论

Actual accessor call preflight guard manifest 可以作为当前 implementation stage 的导航锚点。下一步进入 stop-line reconciliation，继续保持 no-call stop-line。
