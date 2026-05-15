# P1 Renderer 可见窗口 NSApplication Shared-Application Native Guard 预检 Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application native guard preflight decision`。阶段结论允许下一刀新增 no-side-effect native guard implementation，但不允许 application singleton accessor call 或 `NSApplication` creation。

## 当前上游

- Runtime upstream：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`
- Default draft upstream：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()`
- Upstream manifest：[shared-application feasibility value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-feasibility-value-boundary-manifest.md)

## 允许的下一实现

- Runtime owner candidate：`runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj`
- Native callable prefix：`cjgui_native_bridge_nsapplication_shared_application_guard_*`
- Probe candidates：
  - `verify_native_bridge_nsapplication_shared_application_guard.sh`
  - `verify_renderer_visible_window_nsapplication_shared_application_native_guard_owner.sh`

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

`impact` / `context` 对本阶段上游新增 symbols 返回 not found / UNKNOWN，不能作为安全证明。下一刀必须以 source reading、TDD probe、build、native probe、forbidden scan、protected path scan 与 reachability 兜底。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application native guard no-side-effect implementation bundle`
