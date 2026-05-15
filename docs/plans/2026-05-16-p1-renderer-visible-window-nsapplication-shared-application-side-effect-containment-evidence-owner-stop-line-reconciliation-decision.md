# P1 Renderer visible-window NSApplication shared-application side-effect containment evidence owner stop-line reconciliation decision

状态：docs-only decision / stop-line reconciliation / no application side effect

## 输入

- [side-effect containment evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-side-effect-containment-evidence-owner-manifest.md)
- [side-effect containment evidence owner manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-side-effect-containment-evidence-owner-manifest-stabilization-closure-review.md)

当前 endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`

## 决策

选择 A：将 side-effect containment evidence owner 封账为 evidence-only endpoint，不再追加同构 application-ready / accessor-ready wrapper。

理由：当前 owner 已充分表达 side-effect containment、accessor-call containment carry-forward、artifact non-publication、public diagnostics blocked 与 no backend-ready truth；继续包装只会增加同构 readiness，并提高把 containment evidence 误读为 actual AppKit permission 的风险。

## 仍需保持的缺口

- actual application singleton accessor call 仍 blocked。
- `NSApplication` creation / activation 与 activation policy mutation 仍 blocked。
- actual AppKit event loop / bounded pump 仍 blocked。
- actual visible order、drawable、render 与 renderer state write 仍 blocked。

## 拒绝项

本 decision 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment branch closure / next application singleton accessor decision`
