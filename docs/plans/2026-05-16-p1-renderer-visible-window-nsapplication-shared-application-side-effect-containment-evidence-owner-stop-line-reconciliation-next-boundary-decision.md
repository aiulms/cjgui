# P1 Renderer visible-window NSApplication shared-application side-effect containment evidence owner stop-line reconciliation next-boundary decision

状态：docs-only / next-boundary decision / no application side effect

## 当前端点

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`

## 候选

A. side-effect containment branch closure / next application singleton accessor decision
B. actual application singleton accessor call preflight
C. actual teardown execution preflight
D. actual AppKit event loop / bounded pump implementation preflight
E. actual visible order / drawable / render preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment branch closure / next application singleton accessor decision`。

理由：side-effect containment evidence 已封账为 evidence-only endpoint；进入 actual application singleton accessor call 之前，必须先做 docs-only branch closure，确认 lifecycle、run-loop、teardown、headless artifact 与 side-effect containment evidence chain 是否确实能作为 accessor-call preflight 的上游，而不是直接打开 native side effect。

## 拒绝项

B/C/D/E 仍无权限。当前 endpoint 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment branch closure / next application singleton accessor decision`
