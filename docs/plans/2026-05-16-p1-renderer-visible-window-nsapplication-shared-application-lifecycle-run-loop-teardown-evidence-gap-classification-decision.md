# P1 Renderer visible-window NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification decision

状态：docs-only / classification decision / no runtime implementation

## 输入

本决策消费 [cleanup / headless safety stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-stop-line-reconciliation-manifest.md)、[cleanup / headless safety manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-manifest.md)、[containment branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-branch-manifest.md) 与 [containment policy value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest.md)。

当前 canonical endpoint 保持 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`，runtime input 保持 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`。

## 决策

选择 A：只做 lifecycle / run-loop / teardown evidence gap classification，不新增 runtime owner、native C ABI、`foreign func`、probe、diagnostics、public API 或 renderer state write。

已固定为 value evidence 的事实：

- cleanup co-ownership required
- headless fail-closed route
- CI artifact policy evidence-only
- main-thread ownership proof
- teardown proof before visible
- non-user-visible mode
- bounded run loop / auto-close required
- actual accessor call blocked

仍是缺口的证据：

- lifecycle owner gap：尚未证明谁拥有 `NSApplication` lifecycle，也未证明 shared application singleton 的生命周期归属。
- run-loop execution gap：尚未证明 AppKit event loop、bounded run loop pump 或 stop condition 可进入 runtime。
- teardown ordering gap：尚未证明真实 `NSApplication` / `NSWindow` / layer / drawable 资源的 release ordering。
- headless artifact gap：CI / headless artifact policy 仍是 evidence-only，不是 runtime visible truth。
- side-effect containment gap：actual `sharedApplication` call 的 native side effect 仍未进入 production runtime。

## Stop-line

本阶段不批准 actual `sharedApplication` call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible order、production `nextDrawable`、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner preflight decision`
