# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 停止线复核 Manifest

状态：manifest / docs-only / no runtime truth

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety stop-line reconciliation decision`。本阶段确认 cleanup / headless safety endpoint 足够作为当前 non-call evidence endpoint，但不授权 application singleton accessor call 或任何 AppKit / Metal 真实 side effect。

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Owner file：[runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh)

## 当前 truth

只承认 cleanup co-ownership required、headless fail-closed route required、CI artifact policy evidence-only、main-thread ownership proof required、teardown proof before visible required、non-user-visible mode required、actual accessor call blocked、no singleton accessor call、singleton creation blocked、bounded run loop required、auto-close required、application side effect blocked、activation policy / activation / event loop blocked、native visible order blocked、production drawable blocked、render blocked、no public surface、no renderer state write 与 no backend-ready truth facts。

## 停止线

不调用 `sharedApplication`；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不配置 color attachment；不创建 encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：cleanup / headless safety value boundary manifest。
- Current：cleanup / headless safety stop-line reconciliation manifest。
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification decision`

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 返回 target not found / UNKNOWN / 0 impacted，`context` 也未找到当前 symbol。该结果只说明近期新增 Renderer symbols 未被图覆盖，不能作为安全证明；本阶段按 docs-only 范围用 manifest reading、navigation reachability、protected path scan、public declaration scan 与 `detect-changes` 兜底。

## 设计意图出口自检

- 本 manifest 改变当前 next opening，需要同步 README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifests。
- 本 manifest 不改变 runtime owner、canonical endpoint、default draft 或 runtime input。
- Same-shape Boundary Brake：本阶段不新增 cleanup/headless wrapper，不创建 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
