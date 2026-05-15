# P1 Renderer 可见窗口 NSApplication Shared-Application Feasibility Value Boundary 下一边界决策

## 当前阶段出口

Shared-application feasibility value boundary 已完成 implementation 封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application native guard preflight decision`

## 下一段只允许预检的问题

- 是否需要新增 no-side-effect native guard 来固定 singleton accessor 仍 blocked 的 native-side constants。
- 是否必须先继续拆分 singleton lifecycle、teardown ordering、headless fail-closed 与 non-user-visible mode。
- 如何证明 native guard 不等价于 application singleton accessor call、`NSApplication` creation、activation、activation policy mutation 或 event loop。
- 如何继续分类自动化环境 Metal unavailable，而不把 smoke evidence 升级为 runtime permission。

## 不自动继承的权限

- 本阶段不授权 application singleton accessor call。
- 本阶段不授权 `NSApplication` creation。
- 本阶段不授权 activation。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 native guard preflight，不是 native singleton accessor call。
- 已保留 upstream / downstream 指向：上游为 shared-application feasibility value boundary；downstream 为 future native guard decision。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
