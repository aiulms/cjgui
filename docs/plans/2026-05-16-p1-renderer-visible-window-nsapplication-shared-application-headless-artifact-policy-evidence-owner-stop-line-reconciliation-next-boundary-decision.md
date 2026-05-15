# P1 Renderer visible-window NSApplication shared-application headless artifact policy evidence owner stop-line reconciliation next-boundary decision

状态：docs-only / next-boundary decision / no artifact output

## 当前端点

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`

## 候选

A. side-effect containment evidence owner preflight
B. actual artifact write / publication preflight
C. public diagnostics preflight
D. actual teardown execution preflight
E. actual AppKit event loop / bounded pump implementation preflight
F. actual application singleton accessor call preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment evidence owner preflight decision`。

理由：headless artifact policy evidence 已封账为 evidence-only endpoint；classification 链中剩余的最小缺口是 side-effect containment evidence。它仍必须先作为 internal value owner 固定 application side-effect containment、accessor-call containment carry-forward、artifact non-publication 与 no backend-ready truth，不能直接进入 actual accessor call、teardown、event loop 或 visible-order work。

## 拒绝项

B/C/D/E/F 仍无权限。当前 endpoint 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment evidence owner preflight decision`
