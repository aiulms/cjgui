# P1 内部 Renderer 可见窗口 Application Activation Policy Value Boundary 阶段封账复核

## 完成内容

本阶段完成 `P1 internal Renderer visible-window production harness application activation policy value boundary bundle implementation`。

新增 runtime internal owner [runtime_renderer_visible_window_application_activation_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_application_activation_policy.cj)，只消费 `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`，并固定 application singleton ownership scope、main-thread gate、application creation still-deferred、activation still-deferred、bounded run loop required、auto-close required、headless fail-closed route、content-view prerequisite required、native visible order still blocked、production drawable still blocked、render still blocked、no public surface、no renderer state write 与 no backend-ready truth。

新增 owner probe [verify_renderer_visible_window_application_activation_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_application_activation_policy_owner.sh)，用于确认 owner 符号、上游输入与停止线。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`

## 未越过的停止线

- 未创建 `NSApplication`。
- 未 activation，未运行 AppKit event loop。
- 未调用 native visible order API。
- 未调用 production `nextDrawable`。
- 未配置 color attachment，未创建 command buffer / encoder。
- 未 draw，未 `commit` / `present`，未提交 GPU work，未执行 render。
- 未写 renderer state，未触碰 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API / public C ABI / diagnostics。

## 设计意图出口自检

- 该 owner 是 value-style policy boundary，不是 application-ready wrapper。
- Same-shape Boundary Brake：未新增 visible-ready、drawable-ready、backend-ready、render-ready、state-write、receipt、record 或 publication wrapper。
- topic manifest / README / tracker / design intent index 需要同步新 endpoint 与 next opening。

