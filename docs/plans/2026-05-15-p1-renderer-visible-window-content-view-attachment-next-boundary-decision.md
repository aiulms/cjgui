# P1 Renderer 可见窗口 Content View Attachment 下一边界决策

## 当前阶段出口

`NSWindow.contentView` attachment first slice 已完成封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness visible-order preflight decision`

## 下一段只允许预检的问题

- 是否允许进入 visible order 相关决策。
- 是否必须先补一层 internal visible-order policy owner，固定 `NSApplication` / activation / bounded run loop / auto-close / user-visible side-effect 的权限边界。
- 如何确保 content-view attachment facts 不被误读成 `makeKeyAndOrderFront`、production `nextDrawable`、drawable texture lifetime、color attachment、encoder、draw、`commit`、`present` 或 render permission。
- 如何继续保持 headless / CI-like fail-closed route。

## 不自动继承的权限

- 本阶段不授权 `makeKeyAndOrderFront`。
- 本阶段不授权 `NSApplication` creation / activation policy。
- 本阶段不授权 production `nextDrawable`。
- 本阶段不授权 color attachment、command buffer、encoder、draw、commit、present、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 visible-order preflight，不是 implementation 直通。
- 已保留 upstream / downstream 指向：上游为 native `NSWindow` harness 与 content-view attachment，downstream 为可见窗口 ordering policy。
- Same-shape Boundary Brake：下一段仍必须先证明不是 drawable-ready / render-ready wrapper。
