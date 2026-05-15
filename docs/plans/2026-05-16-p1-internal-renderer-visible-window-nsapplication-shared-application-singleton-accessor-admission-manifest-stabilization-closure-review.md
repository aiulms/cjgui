# P1 internal Renderer visible-window NSApplication shared-application singleton accessor admission manifest stabilization closure review

状态：manifest stabilization closure / no actual accessor call

## Stabilization 范围

本 closure 复核 [singleton accessor admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-singleton-accessor-admission-manifest.md) 是否稳定记录当前 owner、endpoint、truth、stop-line 与下一 opening。

## 复核结果

- Manifest 指向新增 owner file、owner probe、canonical endpoint、default draft 与 runtime input。
- Manifest 明确 owner 是 fail-closed admission facts，不是 actual accessor call permission。
- Manifest 保留 actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、bounded pump、actual teardown execution、artifact write、artifact publication、public diagnostics、visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI stop-line。
- Manifest 将唯一 next opening 固定为 singleton accessor admission stop-line reconciliation。

## Navigation 要求

完成本 closure 后需要同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## Closure 结论

Singleton accessor admission manifest stabilization 可以封账。下一阶段只允许 stop-line reconciliation；不得借此实现 actual `sharedApplication` call。
