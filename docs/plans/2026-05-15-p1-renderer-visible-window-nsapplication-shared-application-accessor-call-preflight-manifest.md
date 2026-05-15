# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Preflight Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor call preflight decision`。阶段完成后，current runtime endpoint 从 accessor guard policy readiness 推进到 accessor call preflight readiness；本阶段仍不打开 actual application singleton accessor call。

## 当前 endpoint

- Runtime owner file：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh)
- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- Upstream manifest：[accessor call stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-stop-line-reconciliation-manifest.md)

## 事实边界

当前 truth 只承认 accessor call preflight value facts：actual application singleton accessor call still blocked、future native accessor call guard required、application singleton accessor scope still blocked、application singleton creation still blocked、main-thread gate required、bounded run loop required、auto-close required、headless / CI-like fail-closed route、teardown before visible required、non-user-visible required、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、production drawable blocked 与 render blocked。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- Current：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call native side-effect containment preflight decision`

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 返回 not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、owner probe、build、smoke、forbidden scan、protected path scan、manifest reachability 与 `detect-changes` 兜底。

## 设计意图出口自检

- 本 manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
