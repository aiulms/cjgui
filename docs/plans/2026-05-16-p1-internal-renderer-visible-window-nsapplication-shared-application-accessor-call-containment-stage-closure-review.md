# P1 Renderer NSApplication shared-application accessor call containment 阶段封账

状态：stage closure / internal native no-call containment / no backend-ready truth

## 完成内容

本阶段接续 [accessor call containment preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-native-side-effect-containment-preflight-decision.md)，按 A 路线落地 internal-only native side-effect containment facts：

- 新增 runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj)
- 扩展 native bridge header：[cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- 扩展 native bridge source：[cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)
- 新增 native probe：[verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh)

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`

## Truth

本阶段只固定以下 dehydrated facts：application singleton accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible-order blocked、drawable blocked、render blocked、backend-ready truth blocked。

## Stop-line

本阶段没有调用 actual application singleton accessor，没有创建 `NSApplication`，没有 activation，没有修改 activation policy，没有运行 event loop，没有进入 native visible order，没有获取 drawable，没有创建 color attachment / encoder，没有 draw、`commit`、`present` 或 GPU submission，没有写 renderer state，没有扩 public API。新增 native C ABI 仅返回 deterministic `Int32` containment facts，不返回 `Class` / `id` / pointer / handle。

## 验证入口

- `runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh`
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh`
- `cd runtime/cjgui && source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-accessor-call-containment-build --skip-script`

## 下一边界

下一阶段进入 [containment implementation next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-next-boundary-decision.md)，只允许做 accessor call containment policy value boundary；不得把 containment facts 包装成 application-ready、visible-ready、drawable-ready、render-ready、backend-ready、state-write、receipt、record 或 publication wrapper。
