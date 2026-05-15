# P1 Renderer visible-window NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification manifest

状态：docs-only / manifest / no runtime truth

## 上游

- [cleanup / headless safety stop-line reconciliation decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-stop-line-reconciliation-decision.md)
- [cleanup / headless safety stop-line reconciliation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-stop-line-reconciliation-closure-review.md)
- [cleanup / headless safety stop-line reconciliation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-stop-line-reconciliation-next-boundary-decision.md)
- [cleanup / headless safety stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-cleanup-headless-safety-stop-line-reconciliation-manifest.md)

## Canonical endpoint

当前 endpoint 不变：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`

runtime input 不变：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`

## Current truth

本 manifest 只固定分类事实：

- cleanup / headless safety endpoint 足够作为当前 non-call evidence endpoint。
- lifecycle owner、run-loop execution、teardown ordering、headless artifact 和 side-effect containment 仍是证据缺口。
- 这些缺口不能被 cleanup / headless safety facts、containment facts、smoke evidence 或 isolated evidence 自动补齐。

## Stop-line

不授权 actual `sharedApplication` call、`NSApplication` creation / activation、activation policy mutation、AppKit event loop、native visible order、production drawable、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、backend-ready truth、public API、public C ABI 或 diagnostics。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner preflight decision`
