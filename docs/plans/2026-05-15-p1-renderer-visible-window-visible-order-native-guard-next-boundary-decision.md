# P1 Renderer 可见窗口 Visible Order Native Guard 下一边界决策

## 当前阶段出口

visible-order native guard no-side-effect implementation 已完成封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness application creation and activation scope preflight decision`

## 下一段只允许预检的问题

- 是否允许把 no-side-effect application guard facts 推进到 `NSApplication` creation / ownership scope unlock。
- 是否仍需把 activation、bounded run loop、auto-close 与 user-visible side effect 拆成独立 gate。
- 如何确保 application creation / activation 不被误读为 visible order、drawable acquisition、color attachment、encoder、draw、GPU submission、render 或 backend-ready truth。
- 自动化环境若再次遇到 Metal unavailable，应继续按 smoke environment unavailable 分类。

## 不自动继承的权限

- 本阶段不授权 application creation / activation side effect。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 scope preflight，不是 application implementation 或 visible-order implementation 直通。
- 已保留 upstream / downstream 指向：上游为 visible-order policy 与 native guard；downstream 为 application creation / activation scope。
- Same-shape Boundary Brake：下一段仍必须先证明不是 drawable-ready / render-ready wrapper。
