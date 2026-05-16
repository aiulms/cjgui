# P1 Renderer 可见窗口 NSApplication Shared-Application Preexisting Harness Manifest Closure

状态：manifest stabilization closure / docs-only / blocker preserved

## Manifest closure

Preexisting harness manifest 已稳定化：
[manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)。

本 closure 确认当前主线没有打开新的 implementation surface。canonical endpoint、
default draft 和 runtime input 均保持 first slice evidence owner，不新增 `.cj` owner、
native C ABI、native bridge implementation、public API、artifact publication 或
runtime state write。

## 导航出口结论

本阶段改变了主题状态和唯一 next opening，因此需要同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe external preexisting singleton harness or throwaway creation approval decision`

## Stop-line

Manifest closure 不解除任何 stop-line。自动化仍不能创建 `NSApplication`、activation、
修改 activation policy、启动 AppKit event loop、运行 bounded pump、visible order、
drawable、render、artifact publication、public diagnostics、public API、production C ABI、
runtime state write 或 `cjpm.toml` change。
