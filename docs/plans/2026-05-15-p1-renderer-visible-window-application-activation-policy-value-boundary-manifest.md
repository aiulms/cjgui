# P1 Renderer 可见窗口 Application Activation Policy Value Boundary Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness application activation policy value boundary bundle implementation`。阶段完成后，runtime 内部新增 application activation policy readiness，但没有打开 `NSApplication` creation、activation、event loop 或 native visible order implementation。

## 新增 owner

- Runtime owner：`CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Runtime file：[runtime_renderer_visible_window_application_activation_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_application_activation_policy.cj)
- Runtime owner probe：[verify_renderer_visible_window_application_activation_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_application_activation_policy_owner.sh)

## 事实边界

只承认 application singleton ownership scope、main-thread gate、application creation still-deferred、activation still-deferred、bounded run loop required、auto-close required、headless / CI-like fail-closed route、content-view prerequisite required、native visible order still blocked、production drawable still blocked 与 render still blocked value facts。

## 停止线

不创建 `NSApplication`；不 activation；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Current：`CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication native guard preflight decision`

## GitNexus 结果

GitNexus 对本阶段新增 endpoint / default draft 预计会返回 not found / UNKNOWN；后续不能把该结果当作安全证明，仍需 source reading、build、probe、forbidden scan 与 manifest check 兜底。

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。

