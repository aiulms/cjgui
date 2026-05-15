# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment 分支收束复核

状态：closure review / docs-only / no runtime truth

## 收束结果

本轮完成 branch-level closure。`NSApplication` shared-application accessor call containment branch 已封账为 no-call containment endpoint；actual application singleton accessor call 继续 blocked。

本轮没有新增 runtime owner、native C ABI、`foreign func`、probe、script 或 build config。后续不再继续堆叠同构 no-call wrapper。

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## 复核结论

Containment policy facts 已足够表达当前 no-call branch：accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate、bounded run loop、auto-close、teardown-before-visible、non-user-visible、application side effect blocked、activation / event-loop / visible-order / drawable / render blocked、no public surface、no state write、no backend-ready truth。

下一缺口转为 cleanup co-ownership、headless fail-closed、CI artifact policy、main-thread ownership 与 teardown proof。该缺口不是 accessor call permission，也不是 application-ready truth。

## 同步范围

本 closure 需要同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 验证策略

本 closure 本身是 docs-only；完整验证在本轮 automation stage report 中汇总。若后续新增 runtime owner，则必须运行 owner probe、`cjpm build`、相关回归 probe、smoke 或 smoke environment classification、scans 与 GitNexus detect-changes。

## 设计意图出口自检

- 本轮改变主题状态：是，containment branch sealed。
- 本轮改变 canonical endpoint：否。
- 本轮改变唯一 next opening：是，转为 cleanup / headless safety preflight。
- Stop-line 保持不变：actual accessor call、`NSApplication` creation / activation、event loop、visible order、drawable、render、state write 与 public surface 仍 blocked。
