# P1 内部 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment Stop-Line Reconciliation Manifest Stabilization Closure Review

状态：manifest stabilization closure / docs-only / no runtime truth

## Closure 结论

`NSApplication` shared-application accessor call containment stop-line reconciliation manifest 已完成封账。当前 canonical endpoint、default draft、runtime input 与 stop-line 均保持 containment policy value boundary 的结果；本阶段只同步文档导航并稳定 branch-level next opening。

## 稳定后的 canonical endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## 稳定后的 truth

当前 truth 仍限于 no-call containment policy facts：containment readiness preserved、actual application singleton accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、production drawable blocked、render blocked、no pointer / handle / `Class` / `id` return、no public surface、no renderer state write 与 no backend-ready truth。

## 稳定后的 stop-line

本阶段不新增 runtime owner、native C ABI、`foreign func`、probe、public API、public C ABI 或 diagnostics；不调用 actual `sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop；不做 native visible order；不获取 drawable；不创建 color attachment、encoder 或 draw call；不 `commit` / `present`；不提交 GPU work；不写 renderer state；不触碰 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一边界

当前唯一 next opening 稳定为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment branch closure / next accessor call decision`

该下一边界仍是 docs-only branch decision，不是 actual accessor call implementation。它只能判断 no-call containment branch 是否 stop、是否进入更高层 branch closure、是否发现新的非同构 evidence gap，或是否需要人类产品/风险判断。

## 导航同步要求

本 closure 后应同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 验证要求

本阶段是 docs-only；不运行 `cjpm build`、native probe 或 auto-close smoke。必须运行 docs-only validation：`git diff --check`、touched Markdown whitespace、Markdown absolute link target、reachability、中文标题/正文抽查、public declaration scan、protected path scan、`runtime_state.cj` 10065 行检查与 GitNexus `detect-changes`。
