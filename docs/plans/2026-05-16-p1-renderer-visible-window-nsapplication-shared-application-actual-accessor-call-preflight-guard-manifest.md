# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 清单

状态：manifest / implementation / no actual accessor call

## 阶段摘要

本 manifest 固定 actual accessor call preflight guard value boundary。该 owner 是 no-call preflight guard facts，不是 actual application singleton accessor call、`NSApplication` creation、activation、event loop、visible order、drawable、render、renderer state write、backend-ready truth、public diagnostics、public API 或 public C ABI permission。

## 当前 endpoint

- Preflight decision：[actual accessor call preflight guard preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-preflight-decision.md)
- Stage closure：[actual accessor call preflight guard closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stage-closure-review.md)
- Next-boundary：[actual accessor call preflight guard next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-next-boundary-decision.md)
- Manifest closure：[actual accessor call preflight guard manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest-stabilization-closure-review.md)
- Runtime owner file：[runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh)
- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## Current truth

Current truth 只包含：

- actual accessor side-effect audit readiness 已保留。
- actual-call first slice explicit approval missing。
- main-thread confined preflight required。
- isolated / probe-first route required。
- no activation policy mutation。
- no application activation。
- no AppKit event loop。
- no bounded run-loop pump。
- no visible order。
- no drawable。
- no render。
- no artifact publication。
- no public API。
- no `runtime_state.cj` write。
- no `cjpm.toml` change。
- actual application singleton accessor call still blocked。
- no application singleton accessor call。
- application singleton creation still blocked。
- actual teardown execution、artifact write 与 public diagnostics still blocked。
- no pointer / handle / `Class` / `id` return。
- no public C ABI、no renderer state write、no backend-ready truth。

## Same-shape Boundary Brake

本 owner 不得被包装为 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。

## Stop-line

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不新增 public API 或 public C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## 验证记录

- Owner probe RED：缺少 owner file，exit 3。
- Owner probe GREEN：新增 owner 后通过。
- Build：归入本轮 automation stage report。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard stop-line reconciliation decision`
