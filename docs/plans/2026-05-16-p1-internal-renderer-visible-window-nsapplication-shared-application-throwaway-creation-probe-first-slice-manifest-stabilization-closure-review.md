# P1 Renderer 可见窗口 NSApplication Shared-Application Throwaway Creation Probe First Slice Manifest Stabilization Closure Review

状态：manifest stabilization / navigation-ready / stop-line preserved

## 稳定化结论

[throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
已足够作为本阶段 canonical manifest。它固定了：

- canonical endpoint；
- default draft；
- runtime input；
- owner file；
- owner probe；
- isolated native probe；
- observed throwaway creation classification；
- production singleton ownership non-truth；
- stop-line；
- 当前唯一 next opening。

## 导航同步要求

本 closure 要求同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## Stop-line

Stop-line 保持不变：throwaway creation evidence 不授权 production singleton
ownership truth，不授权 activation、activation policy mutation、AppKit loop、
bounded pump、visible order、drawable、render、GPU submission、artifact publication、
public API、production public C ABI、runtime state write 或 package manifest change。

## Same-shape Boundary Brake

本 manifest closure 不是 application-ready、accessor-ready、visible-ready、
drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
或 publication wrapper。
