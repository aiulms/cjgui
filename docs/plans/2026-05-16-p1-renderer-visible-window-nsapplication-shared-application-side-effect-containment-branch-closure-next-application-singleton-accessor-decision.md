# P1 Renderer 可见窗口 NSApplication Shared-Application Side-Effect Containment 分支收束与下一 Singleton Accessor 决策

状态：branch closure decision / docs-only / no runtime truth

## 本轮裁定

本轮选择 A + C：

- A：`NSApplication` shared-application side-effect containment evidence branch 可以封账。
- C：actual application singleton accessor call 继续 blocked，后续只允许进入 singleton accessor admission preflight。

本轮不选择 actual `sharedApplication` call implementation，也不选择继续新增同构 application-ready / accessor-ready wrapper。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- 上游 manifest：[side-effect containment stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-side-effect-containment-evidence-owner-stop-line-reconciliation-manifest.md)

## 分支确认

当前 side-effect containment branch 已经固定：

- side-effect containment evidence 已完成 owner / stop-line 封账。
- accessor-call containment carry-forward、headless artifact policy、teardown ordering、run-loop execution 与 lifecycle evidence 都仍是 internal evidence facts。
- artifact write、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、native visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 均仍 blocked。
- no pointer / handle / `Class` / `id` return 保持不变。

这些 facts 足够封住当前 containment evidence branch；继续包装同构 readiness 不会解除 visible-window harness 的真实 blocker。

## 仍然缺失

当前缺口不是“再证明 side effect 被阻塞”，而是进入 actual singleton accessor call 前必须明确一个 fail-closed admission 边界：

- future actual accessor call 必须另有 explicit decision。
- admission 必须共同检查 lifecycle / run-loop / teardown / headless artifact / side-effect containment evidence。
- admission 必须继续区分 singleton accessor call、application creation、activation、activation policy mutation、event loop、visible order、drawable 与 render。
- admission 不能把 evidence facts 升级为 AppKit permission、backend-ready truth 或 runtime diagnostics publication。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application singleton accessor admission preflight decision`

该 opening 只允许 docs-only preflight，判断是否新增 internal fail-closed value owner。它不是 actual application singleton accessor call implementation。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，side-effect containment evidence branch 从 stop-line reconciliation 转为 branch sealed。
- 本轮是否改变 canonical tail / endpoint：否，仍为 side-effect containment evidence readiness。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 branch closure 与 singleton accessor admission gap 结论；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 singleton accessor admission preflight。
- 是否同步 topic manifest：是。
