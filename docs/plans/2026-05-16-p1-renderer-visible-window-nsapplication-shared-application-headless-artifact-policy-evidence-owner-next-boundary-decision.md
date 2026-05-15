# P1 Renderer visible-window NSApplication shared-application headless artifact policy evidence owner next-boundary decision

状态：next-boundary decision / implementation closure / no artifact output

## 当前端点

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`

## 候选

A. headless artifact policy evidence owner stop-line reconciliation
B. side-effect containment evidence owner preflight
C. actual artifact write / publication preflight
D. actual teardown execution preflight
E. actual AppKit event loop / bounded pump implementation preflight
F. actual application singleton accessor call preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner stop-line reconciliation decision`。

理由：headless artifact policy evidence owner 已新增，但必须先封账其 evidence-only stop-line，确认 CI artifact policy、path containment、retention、non-user-visible mode 与 fail-closed route 没有被误读为 artifact output、diagnostics publication 或 backend-ready truth。

## 拒绝项

B 是后续候选，但不能越过本 owner 的 stop-line reconciliation。C/D/E/F 仍无权限。当前 endpoint 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner stop-line reconciliation decision`
