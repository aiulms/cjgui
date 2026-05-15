# P1 Renderer 可见窗口 Application Activation Policy Value Boundary 下一边界决策

## 当前阶段出口

application activation policy value boundary 已完成 implementation 封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication native guard preflight decision`

## 下一段只允许预检的问题

- 是否允许把 application activation policy facts 推进到 no-side-effect `NSApplication` native guard。
- 是否仍需继续把 application creation、activation、bounded run loop、auto-close 与 visible order 拆成独立 gate。
- 如何确保 any native guard 不被误读为 `NSApplication` creation / activation permission、visible order、drawable acquisition、color attachment、encoder、draw、GPU submission、render 或 backend-ready truth。
- 自动化环境若再次遇到 Metal unavailable，应继续按 smoke environment unavailable 分类。

## 不自动继承的权限

- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 native guard preflight，不是 application implementation 或 visible-order implementation 直通。
- 已保留 upstream / downstream 指向：上游为 visible-order native guard 与 application activation policy；downstream 为 `NSApplication` native guard scope。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / drawable-ready / render-ready wrapper。

