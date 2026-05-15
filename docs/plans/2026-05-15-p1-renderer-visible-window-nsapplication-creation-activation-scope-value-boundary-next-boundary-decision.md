# P1 Renderer 可见窗口 NSApplication Creation / Activation Scope Value Boundary 下一边界决策

## 当前阶段出口

`NSApplication` creation / activation scope value boundary 已完成 implementation 封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationCreationActivationScopeDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility preflight decision`

## 下一段只允许预检的问题

- 是否允许从 scope facts 进入 `NSApplication.sharedApplication` creation feasibility。
- 是否必须先把 shared application singleton ownership、main-thread affinity、headless fail-closed、bounded run loop、auto-close 与 teardown / non-user-visible mode 拆成更小 gate。
- 如何确认 creation feasibility 不等价于 activation、activation policy mutation、event loop、visible order 或 backend-ready truth。
- 如何继续处理自动化环境 Metal unavailable：只能分类为 smoke environment unavailable，不得把 smoke 结果误读为 runtime permission。

## 不自动继承的权限

- 本阶段不授权 `NSApplication.sharedApplication` call。
- 本阶段不授权 application activation。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 shared-application creation feasibility preflight，不是 creation implementation。
- 已保留 upstream / downstream 指向：上游为 creation / activation scope value boundary；downstream 为 future shared-application creation feasibility。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
