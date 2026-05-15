# P1 Renderer 可见窗口 Visible Order Policy Value Boundary 下一边界决策

## 当前阶段出口

visible-order policy value boundary 已完成封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness visible-order native implementation preflight decision`

## 下一段只允许预检的问题

- 是否允许打开第一个 native visible order implementation slice。
- 是否需要先固定 application creation / activation 的更窄 scope unlock。
- 是否必须依赖 auto-close smoke 与 Metal-capable local shell 作为 evidence。
- 如何确保 visible order 不被误读成 drawable acquisition、color attachment、encoder、draw、GPU submission、render 或 backend-ready truth。

## 不自动继承的权限

- 本阶段不授权 native visible order implementation。
- 本阶段不授权 application creation / activation side effect。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 native implementation preflight，不是 implementation 直通。
- 已保留 upstream / downstream 指向：上游为 content-view attachment 与 visible-order policy value boundary，downstream 为可能的 native visible order scope。
- Same-shape Boundary Brake：下一段仍必须先证明不是 drawable-ready / render-ready wrapper。
