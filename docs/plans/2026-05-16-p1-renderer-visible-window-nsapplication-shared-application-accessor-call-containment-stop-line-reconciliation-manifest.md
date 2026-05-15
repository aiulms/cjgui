# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment Stop-Line Reconciliation Manifest

状态：manifest / docs-only stop-line reconciliation / no runtime truth

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`。阶段完成后，当前 runtime endpoint 保持 containment policy readiness；本阶段只确认 no-call containment policy endpoint 足够作为当前分支封账上游，不打开 actual application singleton accessor call，也不继续新增同构 no-call wrapper。

## 当前 endpoint

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- Upstream manifest：[containment policy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest.md)

## 事实边界

只承认 containment policy facts 足够作为 current no-call endpoint 与 future branch decision 上游。当前 facts 仍是 containment readiness preserved、actual application singleton accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、production drawable blocked、render blocked、no pointer / handle / `Class` / `id` return、no public surface、no renderer state write 与 no backend-ready truth value facts。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不新增 runtime owner、native C ABI、`foreign func` 或 probe；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Current：accessor call containment stop-line reconciliation docs-only decision
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment branch closure / next accessor call decision`

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 返回 not found / UNKNOWN / 0 impacted，`context` 也未找到当前 symbol。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、manifest reachability、forbidden scan、protected path scan 与 `detect-changes` 兜底。

## 设计意图出口自检

- 本 manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 no-call wrapper continuation、application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
