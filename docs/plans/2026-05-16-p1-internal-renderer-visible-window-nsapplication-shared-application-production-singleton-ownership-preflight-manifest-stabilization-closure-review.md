# P1 Internal Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Manifest Stabilization Closure Review

状态：manifest closure / docs-only / navigation stabilized

## Closure 范围

本 closure 固定 production singleton ownership preflight manifest 的导航出口。它不新增
runtime owner、不修改 native bridge、不新增 C ABI、不调用 actual accessor、不修改
`runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 已稳定化的文档链

- [production singleton ownership preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-decision.md)
- [production singleton ownership preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-closure-review.md)
- [production singleton ownership preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-next-boundary-decision.md)
- [production singleton ownership preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-manifest.md)

## 导航同步要求

以下导航必须指向本 manifest 作为最新 Renderer `NSApplication` shared-application
production singleton ownership preflight 状态：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer backend readiness topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer implementation admission topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 稳定结论

- runtime canonical endpoint 仍是 throwaway creation probe evidence endpoint。
- production singleton ownership preflight 已打开。
- production singleton ownership truth 仍为 false。
- production singleton implementation 仍未授权。
- actual accessor production call site 仍未授权。
- 下一步只允许 source-and-cleanup boundary decision。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership source-and-cleanup boundary decision`
