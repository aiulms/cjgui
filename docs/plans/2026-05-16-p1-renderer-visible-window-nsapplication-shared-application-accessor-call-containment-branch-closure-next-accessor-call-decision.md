# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment 分支收束与下一调用决策

状态：branch closure decision / docs-only / no runtime truth

## 本轮裁定

本轮选择 A + C：

- A：`NSApplication` shared-application accessor call containment branch 可以封账。
- C：actual application singleton accessor call 继续 blocked，后续转向 cleanup / headless safety evidence gate。

本轮不选择 actual `sharedApplication` call implementation，也不选择继续新增同构 no-call wrapper。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- 上游 manifest：[containment stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-stop-line-reconciliation-manifest.md)

## 分支确认

当前 containment branch 已经固定：

- actual application singleton accessor call blocked。
- no singleton accessor call。
- application singleton creation blocked。
- main-thread gate、bounded run loop、auto-close、teardown-before-visible 与 non-user-visible mode required。
- application side effect、activation policy mutation、activation、event loop、native visible order、production drawable 与 render blocked。
- no pointer / handle / `Class` / `id` return。
- no public surface、no renderer state write、no backend-ready truth。

这些 facts 足够封住当前 no-call containment branch；继续包装同构 no-call readiness 不会解除 visible-window harness 的真实 blocker。

## 仍然缺失

当前缺口不是“再证明 accessor call 被阻塞”，而是未来 visible-window harness 进入更高风险边界前必须拆清楚：

- cleanup co-ownership。
- headless / CI-like fail-closed safety。
- CI artifact policy 只能是 evidence，不是 runtime truth。
- main-thread ownership proof。
- teardown proof before visible mode。
- non-user-visible mode 的边界。

这些缺口可以用 internal value boundary 固化，不需要调用 application singleton accessor。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety preflight decision`

该 opening 只允许 docs-only preflight，判断是否新增 internal value-style owner。它不是 actual accessor call implementation。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不新增 public diagnostics；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，accessor call containment branch 从 stop-line reconciliation 转为 branch sealed。
- 本轮是否改变 canonical tail / endpoint：否，仍为 containment policy readiness。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 branch closure 与 cleanup/headless evidence gap 结论；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 cleanup / headless safety preflight。
- 是否同步 topic manifest：是。
