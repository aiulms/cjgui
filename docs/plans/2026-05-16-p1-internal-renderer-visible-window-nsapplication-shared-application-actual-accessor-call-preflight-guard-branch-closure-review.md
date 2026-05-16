# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 分支收束复核

状态：closure review / docs-only / no actual accessor call

## 收束结果

本轮完成 branch-level closure。Actual accessor call preflight guard branch 已封账为 no-call preflight endpoint；actual application singleton accessor call 继续 blocked。

本轮没有新增 runtime owner、native C ABI、`foreign func`、probe、script 或 build config。后续不再继续堆叠同构 no-call wrapper。

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## 复核结论

Preflight guard facts 已足够表达当前 no-call branch：actual accessor side-effect audit preserved、explicit approval missing、main-thread confined preflight required、isolated / probe-first route required、activation policy mutation / activation / event-loop / bounded pump / visible-order / drawable / render / artifact publication blocked、no public surface、no state write、no backend-ready truth。

下一缺口转为 isolated actual accessor call probe preflight。该缺口不是 accessor call permission，也不是 application-ready truth。

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

本 closure 本身是 docs-only；完整验证在本轮 automation stage report 中汇总。若后续新增 isolated probe 或 runtime owner，则必须先完成 preflight，再运行 owner / native probe、`cjpm build`、forbidden scan、protected path scan、smoke 或 smoke environment classification、scans 与 GitNexus detect-changes。

## 设计意图出口自检

- 本轮改变主题状态：是，preflight guard branch sealed。
- 本轮改变 canonical endpoint：否。
- 本轮改变唯一 next opening：是，转为 isolated actual accessor call probe preflight decision。
- Stop-line 保持不变：actual accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、bounded pump、visible order、drawable、render、state write 与 public surface 仍 blocked。
