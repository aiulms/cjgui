# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety Manifest

状态：manifest / internal value boundary / no runtime truth

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety value boundary bundle implementation`。阶段完成后，runtime 内部新增 cleanup / headless safety readiness，但没有打开 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop 或 native visible order implementation。

## 新增 owner

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj)
- Runtime owner probe：[verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh)

## 事实边界

只承认 cleanup co-ownership before visible mode required、headless fail-closed route required、CI artifact policy evidence-only、main-thread ownership proof required、teardown proof before visible mode required、non-user-visible mode required、actual accessor call blocked、no singleton accessor call、singleton creation blocked、bounded run loop required、auto-close required、application side effect blocked、activation policy / activation / event loop blocked、native visible order blocked、production drawable blocked、render blocked、no public surface、no renderer state write 与 no backend-ready truth value facts。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Current：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety stop-line reconciliation decision`

## GitNexus 结果

GitNexus 对本阶段新增 endpoint / default draft 返回 target not found / UNKNOWN / 0 impacted，`context` 也未找到当前 symbol。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、build、owner probe、related probes、smoke / smoke environment classification、forbidden scan、protected path scan、manifest reachability 与 `detect-changes` 兜底。

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
