# P1 Renderer 可见窗口 NSApplication Shared-Application Guard Policy Value Boundary 决策 Manifest

## 阶段摘要

本 manifest 封账 `NSApplication` shared-application guard policy value boundary docs-only 决策。结论是：`NSApplication` shared-application native guard no-side-effect integer facts 不足以直接授权 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop 或 user-visible side effect；下一刀只能先补 internal shared-application guard policy value boundary。

## 当前 owner

- Upstream owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- Current canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- Current default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()`
- 本阶段不新增 runtime owner、不新增 native C ABI、不新增 probe。

## 事实边界

只承认 `NSApplication` shared-application native guard facts 已经被观察并保持 no-side-effect。当前 runtime truth 仍停在 native guard observed facts；application singleton accessor blocked、application singleton creation blocked、main-thread gate、bounded run loop、auto-close、teardown-before-visible、non-user-visible、headless fail-closed、activation policy / activation / event loop blocked、visible order blocked、drawable blocked 与 render blocked 均仍只是 guard policy 输入，不是 application-ready truth。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 present / commit / draw / render；不提交 GPU work；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- Current：`NSApplication` shared-application guard policy value boundary docs-only decision
- Downstream next opening：`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary bundle implementation`

## 设计意图出口自检

- manifest 已同步当前 truth、stop-line 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
