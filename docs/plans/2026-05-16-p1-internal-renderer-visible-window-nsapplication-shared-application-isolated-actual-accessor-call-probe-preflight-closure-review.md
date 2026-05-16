# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe 预检 Closure 复核

状态：closure review / docs-only preflight / no actual accessor call

## 收束结果

本轮完成 isolated actual accessor call probe preflight。结论是：preflight 可以封账，但 actual application singleton accessor call first slice 需要 explicit human approval。

本轮没有新增 runtime owner、native C ABI、`foreign func`、probe、script 或 build config。自动化没有调用 actual accessor call。

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## 复核结论

Preflight guard branch 已足够作为 actual-call first-slice 前的 no-call evidence。当前缺口不是更多 no-call wrapper，而是人工明确批准是否允许一个极窄 isolated actual accessor call probe first slice。

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

本 closure 本身是 docs-only；完整验证在本轮 automation stage report 中汇总。由于没有新增 runtime owner，验证重点是 existing owner / native containment probe、build、forbidden scan、protected path scan、public declaration scan、Markdown link check、navigation reachability 与 GitNexus detect-changes。

## 设计意图出口自检

- 本轮改变主题状态：是，isolated actual accessor call probe preflight completed。
- 本轮改变 canonical endpoint：否。
- 本轮改变唯一 next opening：是，转为 explicit human approval decision。
- Stop-line 保持不变：actual accessor call、`NSApplication` creation / activation、event loop、bounded pump、visible order、drawable、render、state write 与 public surface 仍 blocked。
