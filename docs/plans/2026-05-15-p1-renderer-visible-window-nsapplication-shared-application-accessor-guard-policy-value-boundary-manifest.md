# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Guard Policy Value Boundary Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor guard policy value boundary bundle implementation`。阶段完成后，runtime 内部新增 shared-application accessor guard policy readiness，但没有打开 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop 或 native visible order implementation。

## 新增 owner

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy.cj)
- Runtime owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy_owner.sh)

## 事实边界

只承认 application singleton accessor call still blocked、accessor scope still blocked、application singleton creation still blocked、shared-application main-thread gate required、bounded run loop required、auto-close required、headless / CI-like fail-closed route、teardown before visible required、non-user-visible required、activation policy mutation still blocked、activation still blocked、event loop still blocked、native visible order still blocked、production drawable still blocked 与 render still blocked value facts。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`
- Current：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call stop-line reconciliation decision`

## GitNexus 结果

GitNexus 对本阶段新增 endpoint / default draft 返回 not found / UNKNOWN。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、build、probe、forbidden scan、protected path scan 与 manifest reachability 兜底。

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
