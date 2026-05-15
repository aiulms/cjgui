# P1 Renderer visible-window NSApplication shared-application headless artifact policy evidence owner stop-line reconciliation decision

状态：docs-only decision / stop-line reconciliation / no artifact output

## 输入

- [headless artifact policy evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-headless-artifact-policy-evidence-owner-manifest.md)
- [headless artifact policy evidence owner manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-headless-artifact-policy-evidence-owner-manifest-stabilization-closure-review.md)

当前 endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`

## 决策

选择 A：将 headless artifact policy evidence owner 封账为 evidence-only endpoint，不再追加同构 artifact / diagnostics wrapper。

理由：当前 owner 已充分表达 CI artifact policy、path containment、retention policy、non-user-visible mode 与 fail-closed artifact route；继续包装只会增加同构 readiness，并提高把 artifact evidence 误读为 runtime truth 的风险。

## 仍需保持的缺口

- side-effect containment evidence 仍 required。
- actual artifact write / publication 仍 blocked。
- public diagnostics 仍 blocked。
- actual teardown execution / actual AppKit event loop / bounded pump 仍 blocked。
- application singleton accessor call 与 `NSApplication` creation / activation 仍 blocked。

## 拒绝项

本 decision 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment evidence owner preflight decision`
