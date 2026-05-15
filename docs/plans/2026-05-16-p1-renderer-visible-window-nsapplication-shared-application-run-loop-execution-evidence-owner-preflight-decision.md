# P1 Renderer visible-window NSApplication shared-application run-loop execution evidence owner preflight decision

状态：docs-only / preflight decision / no runtime implementation yet

## 输入

本决策消费 [lifecycle evidence owner stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stop-line-reconciliation-manifest.md) 与 [lifecycle evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-manifest.md)。

当前上游 endpoint 是：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

## 决策

选择 A：打开一个极窄 internal value-style run-loop execution evidence owner。

推荐 owner：

- `runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_run_loop_evidence.cj`

推荐 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft()`

该 owner 只消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`，并只固定以下 facts：

- lifecycle evidence readiness preserved
- run-loop execution evidence still required
- bounded run-loop owner evidence required
- stop-condition evidence required before event-loop entry
- auto-close evidence required before visible mode
- main-thread run-loop affinity evidence required
- actual AppKit event loop / run-loop pump still blocked
- actual application singleton accessor call still blocked
- `NSApplication` creation / activation / activation policy mutation still blocked
- native visible order / drawable / render still blocked
- no public surface, no public C ABI, no renderer state write, no backend-ready truth

## 拒绝项

本阶段拒绝 AppKit event loop implementation、bounded pump implementation、actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、native visible order、drawable、render、GPU submission、public API、public C ABI、diagnostics 与 renderer state write。

## Same-shape Boundary Brake

该 owner 不得只是 lifecycle evidence endpoint 的同构包装。它必须新增 run-loop execution evidence、bounded run-loop owner evidence、stop-condition evidence、auto-close evidence 与 main-thread run-loop affinity evidence 的显式 value facts。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner value boundary implementation`
