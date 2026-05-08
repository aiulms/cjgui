# 可拔插浏览器内核与 foreign surface intake

状态：docs-only / future radar / no implementation

## 主题定位

本主题记录“可拔插浏览器内核组件”作为 future radar / docs-only future slot。它用于保留复杂富文本、Markdown preview、legacy SaaS 或 Web 文档场景的远期评估入口。

## 当前状态

当前没有正式 runtime implementation，没有 browser dependency，没有 Chromium / WebKit / WebView 接入，也没有 foreign surface owner。该方向只在 [AI-native operability / foreign surface intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md) 中登记为 future opening。

## 已落地现实

- foreign surface 被定义为被 CJGUI 圈养的外部内容 surface，而不是 CJGUI 的宿主。
- 浏览器内核只能是可选 component / plugin。
- 默认 runtime 不携带 browser kernel 重量。
- foreign surface 不直接拥有 app window，不直接接收 OS input，不直接暴露 DOM / accessibility tree 作为 CJGUI semantic truth。

## 未落地与明确禁止

- 不走 Electron 路线。
- 不把浏览器作为宿主。
- 不把 WebView 作为主渲染管线。
- 不创建 browser dependency，不接 Chromium / WebKit，不实现 WebView widget，不实现 external process IPC、texture sharing 或 DOM semantic bridge。
- 不进入当前 runtime implementation，不改变 Renderer next opening。

## 当前 owner 链摘要

当前没有 runtime owner。未来如果评估 foreign surface，必须先建立 docs-only containment preflight，明确 sandbox process、texture handoff、input proxy、focus / IME cursor rect sync、semantic projection gate、IPC failure 和 teardown owner。

## 关键文档链

- [AI-native operability / foreign surface intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md)
- [README foreign surface entry](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI task tracker](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)

## 下次开 gate 前必须读取

开 foreign surface、browser kernel、WebView、foreign texture、input proxy、IME sync、A11y projection 或 sandbox process gate 前，必须读取 AI-native operability intake、Action Router manifest、GUI governance 和本 manifest。

## 推荐下一步

若未来重新打开该方向，推荐先做 `P1 foreign surface / browser-kernel containment preflight`，且仍为 docs-only。

## 禁止误读点

- foreign surface 不是默认框架能力。
- foreign surface 不是 runtime truth，也不是 semantic truth。
- future slot 不等于实现许可。
- foreign semantic tree 必须受 CJGUI zero-trust action gateway 管理。

## 评估问题

- texture sharing / IPC / compositor 时序如何不破坏 CJGUI owner。
- focus / cursor rect / IME / accessibility 如何与 CJGUI layout truth 同步。
- foreign semantic tree 如何降权、过滤、标注 provenance，并由 Action Router mediated input 控制。
- sandbox / permission / storage / network policy 由谁拥有。
- 外部进程 crash、hang、IPC timeout、GPU resource loss 如何 fail closed。

## 维护备注

除非出现正式 docs-only preflight，本主题只能作为 future radar。任何实现动作都必须先更新本 manifest 并建立对应 owner / truth / stop-line。
