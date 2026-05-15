# P1 Renderer 可见窗口 Visible Order Native Guard Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness visible-order native guard no-side-effect implementation`。阶段完成后，runtime 内部新增 visible-order native guard readiness，但没有打开 application creation、activation 或 native visible order implementation。

## 新增或更新的 owner

- Runtime owner：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- Runtime file：[runtime_renderer_visible_window_visible_order_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_visible_order_native_guard.cj)
- Native probe：[verify_native_bridge_nswindow_visible_order_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nswindow_visible_order_guard.sh)
- Runtime owner probe：[verify_renderer_visible_window_visible_order_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_visible_order_native_guard_owner.sh)

## 事实边界

只承认 production native bridge 可返回 application ownership required、application creation deferred、activation deferred、bounded run loop required、auto-close required、headless / CI-like fail-closed、content-view prerequisite required、visible order still blocked、drawable still blocked 与 render still blocked integer facts。

## 停止线

不调用 `makeKeyAndOrderFront` / `orderFront` / `activateIgnoringOtherApps`；不创建 `NSApplication`；不 activation；不运行 AppKit event loop；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- Current：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness application creation and activation scope preflight decision`

## GitNexus 结果

GitNexus 对本阶段新增 endpoint / default draft / native callable 返回 not found / UNKNOWN；后续不能把该结果当作安全证明，仍需 source reading、build、probe、forbidden scan 与 manifest check 兜底。

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
