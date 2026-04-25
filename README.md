# 仓颉笔记

最后更新：2026-04-25

## 用途

这个目录是我们长期交流仓颉相关内容的工作区。
后续已经确认的结论、待研究的问题、重要链接和项目方向，都会持续沉淀在这里。

## 当前入口

如果以后上下文丢失，优先按这个顺序读取：

1. [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)：总入口和文档索引。
2. [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)：当前状态、stop-line、下一步 opening。
3. [docs/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/README.md)：文档中心和目录职责。
4. [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)：项目方向和长期边界。
5. [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)：开工门禁和 preflight / gate / closure 规则。
6. [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)：已识别风险与盲点总账。
7. [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)：历史 preflight / execution card / closure review 索引。

当前下一步以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 的 `当前 next opening` 为准。

## 当前已确认

### 1. 官方文档可访问

- 官方文档页 `https://cangjie-lang.cn/docs?url=%2F1.1.0%2Fdev-guide%2Fsource_zh_cn%2Ffirst_understanding%2Fbasic.html` 可以访问。
- 页面显示版本为 `1.1.0 STS`。

### 2. 桌面应用现状

- 截至 2026-04-24，仓颉可以构建并运行在 `Linux`、`macOS`、`Windows` 上的原生可执行程序。
- 这意味着命令行工具、本地工具、终端程序、后台服务都是现实可行的。
- 我没有查到成熟的一等公民官方桌面 GUI 方案，暂时还不能把它看成 `Qt`、`Flutter`、`WPF`、`Electron` 这一类成熟路线。
- 当前更明确、也更官方的应用方向仍然是 `HarmonyOS` 应用开发。

### 3. 桌面开发的现实路线

- `CLI/TUI`：当前最稳的路线
- `WebView 壳 + 仓颉逻辑`：适合快速做跨平台 GUI 原型
- `CJQT`：社区路线，更接近传统原生桌面 GUI
- `仓颉核心 + 其他 GUI 壳`：更适合严肃的跨平台产品工程

### 4. 一个关键区分

- “仓颉可以做桌面软件”这件事是成立的。
- “仓颉已经有成熟官方桌面 GUI 方案”这件事目前还不能明确成立。

## 已查过的来源

- https://cangjie-lang.cn/docs?url=%2F1.1.0%2Fdev-guide%2Fsource_zh_cn%2Ffirst_understanding%2Fbasic.html
- https://cangjie-lang.cn/
- https://docs.cangjie-lang.cn/docs/1.0.0/user_manual/source_zh_cn/deploy_and_run/run_cjnative.html
- https://docs.cangjie-lang.cn/docs/1.0.1/user_manual/source_zh_cn/FFI/cangjie-c.html
- https://docs.cangjie-lang.cn/docs/0.53.18/guide/source_zh_cn/%E4%BB%93%E9%A2%89%E9%B8%BF%E8%92%99%E5%BA%94%E7%94%A8%E5%BC%80%E5%8F%91%E5%85%A5%E9%97%A8%E6%8C%87%E5%8D%97.html
- https://github.com/gtn1024/awesome-cangjie
- https://blog.gitcode.com/4586bc120c915768be38192be9374113.html

## 后续待继续追的问题

- 仓颉在真实生产环境里的服务端能力到底成熟到什么程度？
- 仓颉相对 `Go`、`Rust`、`ArkTS` 的语言层优势到底是什么？
- 当前 `C` 互操作在实践里到底完整到什么程度？
- 哪条第三方 GUI 路线长期最可维护？
- 如果认真学仓颉，一条现实的学习路线应该怎么走？

## 新讨论：自己做 GUI 框架

### 初步判断

- 在仓颉之上构建 GUI 框架，技术上是可行的。
- 关键支撑点是 `C` 互操作，而不是仓颉内建 GUI 栈。
- 仓颉可以暴露和调用 `C` ABI 函数、回调、指针、静态库、动态库。
- 这让下面这些事情都变得现实：
  - 给现有原生库或图形库做薄绑定
  - 先做一个小型桌面运行时
  - 在渲染后端之上继续长出自己的组件层

### 现实建议

- 不要一上来就做 `Qt` 级别的大框架。
- 先从一个最窄的目标开始：
  - `窗口 + 事件循环 + 输入 + 绘制`
- 之后再逐步补：
  - 布局
  - 组件树
  - 文本渲染
  - 输入法 / 无障碍
  - 打包和工具链

### 重要工程风险

- 仓颉当前最强的是 `C` 互操作，不是 `C++` 互操作。
- 所以像 `Qt` 这类大型 `C++` GUI 生态，直接绑定会更难，通常需要一层 `C shim`。
- `AppKit`、`Win32`、`GTK` 这些平台之间的桌面差异非常大。
- 真正难的部分通常不是按钮，而是文本 shaping、输入法、无障碍、剪贴板、拖拽、高 DPI 这些系统级能力。

### 如果目标是为爱发电，而不是商业交付

- 那“值不值得”就不再主要由商业效率决定，而要看学习价值、架构美感和个人满足感。
- 在这个前提下，从零做一个 GUI 框架，是一个很合理的长期项目。
- 更推荐的 framing 是：
  - 先做桌面运行时
  - 再做渲染层
  - 再做布局和控件
  - 最后才做声明式 UI 系统

### 个人项目最适合的心态

- 不要试图一开始就和 `Qt`、`Flutter`、`SwiftUI` 竞争。
- 更适合把这个项目当成：
  - 仓颉生态实验
  - 系统编程练习
  - 框架设计实验室
- 成功标准不是功能对标，而是架构是否自洽、可讲清楚、可持续扩展。

### 一个人推进时的路线

- 阶段 1：先只做一个平台
- 阶段 2：先做一个窗口、一条事件循环、一个绘制面
- 阶段 3：再补文本、输入和布局
- 阶段 4：再做少量核心控件
- 阶段 5：再考虑声明式语法和响应式更新
- 阶段 6：最后视情况扩到多平台后端

## 工作约定

- 以后每次继续讨论，都把新确认的结论追加到这里。
- 不确定的地方要明确标出来，不混成既定事实。
- 只要官方资料可用，就优先以官方资料为准。

## 本地文档准备情况

- 仓颉官方文档源已经可以直接通过 Git 仓库下载到本地。
- 文档中心在这里：
  - [docs/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/README.md)
- 本地文档索引在这里：
  - [LOCAL_DOCS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_DOCS.md)
- 本机仓颉工具链配置在这里：
  - [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- 从零构建和灾难恢复手册在这里：
  - [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- 仓颉问题判定与上游 Bug 账本在这里：
  - [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- 仓颉调用 C 的最小 smoke test 在这里：
  - [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)
- P0 macOS 桥接运行时 preflight 在这里：
  - [2026-04-25-p0-macos-bridge-runtime-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)
- P0 macOS 桥接 smoke demo 在这里：
  - [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- P0 macOS 桥接 closure review 在这里：
  - [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- P1 AppKit / Metal 桥接边界 preflight 在这里：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- P1 AppKit / Metal 桥接边界清理 execution card 在这里：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
- P1 AppKit / Metal 桥接边界清理 closure review 在这里：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- P1 主线程 UI message queue preflight 在这里：
  - [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)
- P1 主线程 UI message queue execution card 在这里：
  - [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)
- GUI 项目的思考框架在这里：
  - [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- GUI 项目的方向说明在这里：
  - [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- AI 原生 UI 语义方向在这里：
  - [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)
- GUI 项目的治理总则在这里：
  - [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- GUI 项目的任务账本在这里：
  - [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- GUI 项目的风险账本在这里：
  - [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- 人类协作治理说明在这里：
  - [HUMAN_COLLABORATION_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/HUMAN_COLLABORATION_GOVERNANCE.md)
- `open-nwe` 对未来仓颉 GUI 的产品需求映射在这里：
  - [OPEN_NWE_PRODUCT_DEMAND_MAP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)
- AI 代码质量治理在这里：
  - [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- AI 开发宪法卡在这里：
  - [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- AI 执行卡模板在这里：
  - [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- 当前已本地化的主要文档源包括：
  - `cangjie_docs_1.1`
  - `cangjie_runtime_1.1`
  - `cangjie_stdx_1.1`
  - `docs_cangjie_master`
- 当前已本地化的辅助仓库包括：
  - `CangjieSkills`
  - `DocFlow`
- 当前已本地化的 GUI 参考仓库包括：
  - `wgpui-openagents`
  - `gpui-zed`
  - `flutter`
  - `qt-therecipe`

### 这里的关键结论

- 我们后续不需要只依赖公开网页来查资料。
- 对后续自建 skill 来说，这些 Git 仓库比网页更适合作为长期真相源。

## GUI 参考仓库

- 这些仓库是后续做仓颉 GUI 框架时的重要参考样本。
- 当前统一放在：
  - [reference_repos](/Users/jiangxuanyang/Desktop/cangjie/reference_repos)

### 已准备好的参考仓库

- [wgpui-openagents](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/wgpui-openagents)
  - 对应站点：`https://docs.openagents.com/wgpui`
  - 用途：参考 `WGPUI` 的工程组织、渲染与 UI 设计思路

- [gpui-zed](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/gpui-zed)
  - 对应站点：`https://www.gpui.rs/`
  - 用途：参考 `GPUI` 的事件系统、渲染模型、桌面框架抽象

- [flutter](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/flutter)
  - 源仓库：`https://github.com/flutter/flutter`
  - 用途：参考大规模 UI 框架的工程结构、工具链组织、跨平台经验

- [qt-therecipe](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/qt-therecipe)
  - 源仓库：`https://github.com/therecipe/qt`
  - 用途：参考传统桌面 GUI 生态的封装方式与绑定层设计

## 个人项目方向

### 动机

- 目标不只是“技术上能不能做”。
- 更深层的目标是：给仓颉生态补一块真正有意义的基础设施。
- 你的明确偏好是尽量不依赖重型外部框架，而是做一块自己可掌控的桌面 UI 基座。
- 另一个重要目标，是让以后自己做桌面应用时更轻松。

### 当前设计哲学草稿

- 更偏向小而清楚、自己能讲明白、自己能掌控的基础。
- 接受操作系统原生能力作为最底层。
- 第一阶段避免引入大型 GUI 框架依赖。
- 追求一套个人开发者也能从头理解到尾的教学型架构。

### 当前更准确的 framing

- 这里追求的不是“绝对零依赖”。
- 更准确的说法是：`不依赖 OS 层之上的重型 GUI 框架`。
- 具体来说就是：
  - 允许使用操作系统原生 API
  - 必要时允许手写 `C shim`，但向上接口必须极窄
  - 第一阶段避免 `Qt`、`GTK`、`Electron` 这类重型栈

## 可行性边界：什么叫“纯仓颉从零开始”

### 严格解释

- 如果“纯仓颉”指的是：
  - 不调 OS API
  - 不用 FFI
  - 不写桥接代码
  - 不接任何原生库
- 那么做一个真正的桌面 GUI 框架基本不可行。
- 因为桌面窗口最终一定要通过操作系统的窗口系统创建出来。

### 实际可用解释

- 如果“纯仓颉”指的是：
  - 不依赖第三方 GUI 大框架
  - 框架主体逻辑用仓颉写
  - 最底层只保留最薄的一层原生桥接
- 那么这个项目是可行的，而且非常值得做。

### 当前最好的项目规则

- 上层尽量保持仓颉原生：
  - 事件系统
  - 渲染抽象
  - 场景树
  - 布局
  - 控件
  - 响应式运行时
- 最底层接受一层极薄的平台桥接。

### 当前建议的使命表述

- 做一个“仓颉原生”的 GUI 框架
- 避免依赖重型外部 GUI 框架
- 底层只允许最小程度的操作系统桥接
