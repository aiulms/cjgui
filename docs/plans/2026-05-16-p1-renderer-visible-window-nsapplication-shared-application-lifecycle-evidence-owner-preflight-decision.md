# P1 Renderer visible-window NSApplication shared-application lifecycle evidence owner preflight decision

状态：docs-only / preflight decision / no runtime implementation yet

## 输入

本决策消费 [lifecycle / run-loop / teardown evidence gap classification manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-run-loop-teardown-evidence-gap-classification-manifest.md)、[cleanup / headless safety stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-stop-line-reconciliation-manifest.md) 与 [cleanup / headless safety manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-manifest.md)。

当前上游 endpoint 是：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`

## 决策

选择 A：打开一个极窄 internal value-style lifecycle evidence owner。

推荐 owner：

- `runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence.cj`

推荐 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

该 owner 只消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`，并只固定以下 facts：

- cleanup / headless safety readiness preserved
- lifecycle owner evidence required
- application singleton ownership evidence required
- run-loop execution evidence still required
- teardown ordering evidence still required
- headless artifact policy still evidence-only
- side-effect containment evidence still required before actual accessor call
- actual `sharedApplication` accessor call still blocked
- `NSApplication` creation / activation / activation policy mutation / event loop still blocked
- native visible order / drawable / render still blocked
- no public surface, no public C ABI, no renderer state write, no backend-ready truth

## 拒绝项

本阶段拒绝：

- actual `sharedApplication` call
- `NSApplication` creation / activation
- activation policy mutation
- AppKit event loop 或 bounded run-loop pump implementation
- native visible-order implementation
- production drawable acquisition
- color attachment / encoder / draw / `commit` / `present`
- GPU submission / render
- public API / public C ABI / diagnostics
- renderer state write

## Same-shape Boundary Brake

该 owner 不得只是 cleanup / headless safety endpoint 的同构包装。它必须新增 lifecycle owner scope、singleton ownership evidence、run-loop evidence gap、teardown ordering evidence gap、headless artifact policy 与 side-effect containment evidence gap 的显式 value facts。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner value boundary implementation`
