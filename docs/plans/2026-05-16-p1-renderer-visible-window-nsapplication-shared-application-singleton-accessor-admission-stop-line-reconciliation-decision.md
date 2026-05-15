# P1 Renderer 可见窗口 NSApplication Shared-Application Singleton Accessor Admission Stop-Line Reconciliation 决策

状态：docs-only decision / stop-line reconciliation / no actual accessor call

## 输入

- [singleton accessor admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-singleton-accessor-admission-manifest.md)
- [singleton accessor admission manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-singleton-accessor-admission-manifest-stabilization-closure-review.md)

当前 endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness`

## 决策

选择 A：将 singleton accessor admission owner 封账为 fail-closed admission endpoint，不再追加同构 application-ready / accessor-ready wrapper。

理由：当前 owner 已充分表达 future actual accessor call decision required、native side-effect audit required、lifecycle / run-loop / teardown / headless artifact / side-effect containment evidence carried-forward，以及 actual application singleton accessor call still blocked。继续包装只会增加同构 readiness，并提高把 admission facts 误读为 actual AppKit permission 的风险。

## 仍需保持的缺口

- actual application singleton accessor call 仍 blocked。
- `NSApplication` creation / activation 与 activation policy mutation 仍 blocked。
- actual AppKit event loop / bounded pump 仍 blocked。
- actual teardown execution、artifact write、artifact publication 与 public diagnostics 仍 blocked。
- visible order、drawable、render 与 renderer state write 仍 blocked。
- future actual accessor call 必须另有 explicit decision。

## 拒绝项

本 decision 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application singleton accessor admission branch closure / next actual accessor call decision`
