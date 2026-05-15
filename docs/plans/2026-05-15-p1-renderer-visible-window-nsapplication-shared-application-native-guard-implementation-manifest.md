# P1 Renderer 可见窗口 NSApplication Shared-Application Native Guard 实现 Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application native guard no-side-effect implementation bundle`。

本阶段新增 production native bridge internal no-side-effect `int32_t` guard callables，并新增 runtime owner 消费这些 callables，将 application singleton accessor blocked、application singleton creation blocked、main-thread affinity required、bounded run loop required、auto-close required、headless fail-closed、teardown before visible required、non-user-visible required、activation policy blocked、activation blocked、event loop blocked、visible order blocked、drawable blocked 与 render blocked 脱水为 runtime internal readiness facts。

## 当前 Endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`
- Owner file：[runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj)
- Upstream manifest：[shared-application feasibility value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-feasibility-value-boundary-manifest.md)

## Native bridge 文件

- [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

## 探针

- [verify_native_bridge_nsapplication_shared_application_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_guard.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_native_guard_owner.sh)

Existing native bridge allowlist probes 已更新，允许新的 no-side-effect guard callables：

- [verify_native_bridge_skeleton_compile.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh)
- [verify_native_bridge_no_resource_symbols.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh)
- [verify_native_bridge_package_link_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh)
- [verify_native_bridge_cjpm_package_link_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh)
- [verify_native_bridge_cjpm_integration_boundary.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh)

## 当前 Truth

当前 truth 仅限以下 internal dehydrated facts：

- application singleton accessor remains blocked
- application singleton creation remains blocked
- main-thread affinity remains required
- bounded run loop and auto-close remain required
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

`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary decision`
