# P1 Renderer NSApplication shared-application accessor call containment policy manifest 稳定封账

状态：manifest stabilization closure / current tail / no backend-ready truth

## 封账结论

[containment policy value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest.md) 已固定本阶段的 owner、canonical endpoint、default draft、runtime input、truth、stop-line 与 downstream。

当前 endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`，runtime input 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`。

## 导航同步

本阶段应从以下入口可达：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 下一步

唯一 next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`。

下一步必须是 docs-only decision；不得新增 runtime owner、native C ABI、probe、public API、renderer state write、actual application singleton accessor call、`NSApplication` creation / activation、event loop、visible order、drawable、render 或 backend-ready truth。
