# P1 Renderer 可见窗口 NSApplication Native Guard Implementation 下一边界决策

## 当前阶段出口

`NSApplication` native guard no-side-effect implementation 已完成。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication native guard policy value boundary decision`

## 下一段只允许预检的问题

- 是否需要把 native guard observed facts 脱水为 value-style policy boundary。
- 是否仍需继续拆分 application singleton ownership、main-thread gate、creation deferred、activation deferred、activation policy deferred、event loop deferred、visible order still-blocked 与 drawable/render still-blocked。
- 如何防止 native guard 被误读为 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready truth。

## 不自动继承的权限

- 不授权 application singleton creation、activation policy mutation、activation 或 AppKit event loop。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public diagnostics、public C ABI 或 build config integration。

## 设计意图出口自检

下一 opening 是 policy boundary decision，不是 application creation / activation implementation，也不是 visible order implementation 直通。Same-shape Boundary Brake：不得继续堆叠同构 guard wrappers。
