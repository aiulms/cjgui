# P1 Renderer 可见窗口 NSApplication Shared-Application Guard Policy Value Boundary 实现后续边界决策

## 当前阶段出口

Shared-application guard policy value boundary 已完成 implementation 封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope preflight decision`

## 下一段只允许预检的问题

- 是否允许从 shared-application guard policy facts 进入 application singleton accessor scope。
- 是否仍需继续拆分 singleton accessor、singleton creation、activation policy mutation、activation、bounded run loop、auto-close、headless fail-closed 与 visible order。
- 如何确保 guard policy facts 不被误读为 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready truth。
- 自动化环境若再次遇到 Metal unavailable，应继续按 smoke environment unavailable 分类。

## 不自动继承的权限

- 本阶段不授权 application singleton accessor call。
- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 shared-application accessor scope preflight，不是 accessor implementation 或 application implementation 直通。
- 已保留 upstream / downstream 指向：上游为 shared-application native guard 与 guard policy；downstream 为 future accessor scope。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / drawable-ready / render-ready wrapper。
