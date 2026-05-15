# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 阶段收束复核

状态：closure review / internal value boundary / no runtime truth

## 收束结果

本阶段新增 internal value owner，用于固定 visible-window production harness 在未来更高风险边界前需要的 cleanup co-ownership、headless fail-closed、CI artifact policy、main-thread ownership proof 与 teardown proof facts。

本阶段没有新增 native C ABI、没有修改 production native bridge、没有新增 `foreign func`、没有修改 build config、没有修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 新增 owner

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj)
- Runtime owner probe：[verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh)

## 当前 truth

只承认 cleanup / headless safety readiness 是 internal value facts：cleanup co-ownership required、headless fail-closed route required、CI artifact policy evidence-only、main-thread ownership proof required、teardown proof before visible required、non-user-visible mode required、actual accessor call blocked、no singleton accessor call、singleton creation blocked、bounded run loop and auto-close required、application side effect / activation / event-loop / visible-order / drawable / render blocked、no public surface、no state write、no backend-ready truth。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不做 native visible order implementation；不获取 production drawable；不创建 color attachment / command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不返回 pointer / handle / `Class` / `id`；不写 renderer state；不扩 public API / public C ABI。

## 验证策略

本阶段涉及 `.cj` 与 probe script，必须运行 owner probe、`cjpm build --target-dir /tmp/<target> --skip-script`、相关回归 probe、auto-close smoke 或环境不可用分类、scans 与 GitNexus detect-changes。结果记录在 automation stage report。
