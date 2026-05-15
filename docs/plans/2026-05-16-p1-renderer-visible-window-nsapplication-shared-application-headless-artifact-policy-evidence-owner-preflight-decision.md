# P1 Renderer visible-window NSApplication shared-application headless artifact policy evidence owner preflight decision

状态：preflight decision / internal value owner / no artifact output implementation

## 输入

本 preflight 消费 [teardown ordering evidence owner stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stop-line-reconciliation-manifest.md)。

当前上游 endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

## 决策

选择 A：新增 internal-only value-style headless artifact policy evidence owner。

默认 owner：

- `runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_headless_artifact_policy_evidence.cj`

默认 owner probe：

- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_headless_artifact_policy_evidence_owner.sh`

拟定 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`

## 允许范围

本阶段只允许固定 value facts：

- teardown ordering evidence readiness preserved
- headless artifact policy evidence required
- CI artifact path / retention / containment policy remains evidence-only
- non-user-visible artifact mode required
- fail-closed artifact route required
- no actual artifact write or publication
- no application singleton accessor call
- no actual AppKit event loop / bounded pump / visible order / drawable / render

## 拒绝项

本阶段不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、native visible order、production drawable、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 验证要求

- owner probe 先 RED 后 GREEN。
- `cjpm build --target-dir /tmp/cjgui-headless-artifact-policy-evidence-owner-build --skip-script`。
- 相关 teardown / run-loop / lifecycle / cleanup / containment owner probes 回归。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`；若自动化环境返回 `default Metal device is unavailable`，按既有用户复核结论记录为 smoke environment unavailable。
- closure scans：`git diff --check`、touched whitespace、Markdown absolute link target、reachability、中文抽查、public allowlist、native/build forbidden scan、protected path scan、`runtime_state.cj` 行数与 GitNexus detect-changes。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner bundle implementation`
