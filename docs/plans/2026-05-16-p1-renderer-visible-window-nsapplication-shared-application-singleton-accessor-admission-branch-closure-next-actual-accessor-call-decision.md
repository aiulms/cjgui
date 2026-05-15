# P1 Renderer 可见窗口 NSApplication Shared-Application Singleton Accessor Admission 分支收束与下一 Actual Accessor 决策

状态：branch closure decision / docs-only / no actual accessor call

## 本轮裁定

本轮选择 A + C：

- A：`NSApplication` shared-application singleton accessor admission branch 可以封账。
- C：actual application singleton accessor call 继续 blocked；下一步只允许进入 actual accessor call side-effect audit preflight。

本轮不选择 actual `sharedApplication` call implementation，也不选择继续新增同构 application-ready / accessor-ready / visible-ready wrapper。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness`
- 上游 manifest：[singleton accessor admission stop-line manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-singleton-accessor-admission-stop-line-reconciliation-manifest.md)

## 分支确认

当前 singleton accessor admission branch 已经固定：

- fail-closed admission owner 已完成 implementation / stop-line 封账。
- future actual accessor call explicit decision、native side-effect audit、lifecycle / run-loop / teardown / headless artifact / side-effect containment evidence carry-forward 仍是 internal admission facts。
- actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、actual AppKit event loop、bounded run-loop pump、actual teardown execution、artifact write、artifact publication、public diagnostics、native visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 均仍 blocked。
- no pointer / handle / `Class` / `id` return 保持不变。

这些 facts 足够封住当前 admission branch；继续包装同构 readiness 不会解除 visible-window harness 的真实 blocker。

## 仍然缺失

当前缺口不是“再证明 admission fail-closed”，而是进入 actual singleton accessor call 前必须先完成 native side-effect audit value boundary：

- audit 必须明确 `sharedApplication` accessor call 可能触发 AppKit singleton lifecycle / side effects。
- audit 必须继续区分 accessor call、application creation、activation、activation policy mutation、event loop、visible order、drawable 与 render。
- audit 必须确认 headless / CI / artifact / teardown / public diagnostics 边界仍 blocked。
- audit 不能把 admission facts 升级为 AppKit permission、backend-ready truth 或 runtime diagnostics publication。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit preflight decision`

该 opening 只允许 docs-only preflight，判断是否新增 internal no-call audit owner。它不是 actual application singleton accessor call implementation。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 与拟新增 audit endpoint 返回 target not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、manifest reachability、forbidden scan、protected path scan 与最终 `detect-changes` 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，singleton accessor admission branch 从 stop-line reconciliation 转为 branch sealed。
- 本轮是否改变 canonical tail / endpoint：否，仍为 singleton accessor admission readiness。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 branch closure 与 actual accessor side-effect audit gap 结论；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 actual accessor side-effect audit preflight。
- 是否同步 topic manifest：是。
