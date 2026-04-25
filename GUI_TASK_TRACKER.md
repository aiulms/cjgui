# 仓颉 GUI 项目任务账本

最后更新：2026-04-25

## 账本职责

本文件只保留：

- 当前阶段判断
- 当前 healthy stop-line
- 当前 active / future openings

不写长流水实现细节，不写聊天记录，不写过长设计推演。

## 当前阶段

当前项目处于：

> `治理与方向冻结阶段`

当前已完成的基础不是代码，而是：

- 仓颉官方文档已本地化
- 仓颉桌面路线已完成初步判断
- GUI 项目思考框架已落地
- GUI 项目 docs-only governance gate 已落地

当前已经完成实验性 P0 bridge smoke、P1 bridge boundary cleanup、P1 main-thread UI message queue preflight，以及 P1 main-thread UI message queue execution card。
下一步仍不自动进入实现；如果继续推进，必须按 execution card 做受限 implementation slice。

## 当前 current-state summary

### 1. 项目目标已清楚

- 做一个仓颉原生 GUI 框架
- 上层尽量保持仓颉原生
- 底层允许必要且向上接口极窄的平台桥接
- 第一阶段优先做桌面运行时，而不是大而全 GUI 框架

### 2. 当前推荐阶段顺序已清楚

- 先单平台
- 先窗口 / 事件循环 / 重绘 / 基础绘制
- 再进入布局、控件、文本
- 输入法、无障碍、复杂文本都属于后期开口

### 3. 当前治理框架已落地

当前项目已经具备：

- [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)
- [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [HUMAN_COLLABORATION_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/HUMAN_COLLABORATION_GOVERNANCE.md)
- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)

## 当前统一 stop-line

在新的批准出现之前，当前项目统一保持：

- 不做跨平台抽象
- 不做公共声明式 DSL
- 不做输入框
- 不做 IME
- 不做无障碍
- 不做大而全控件库
- 不引入重型 GUI 框架
- 不把平台原生事件直接暴露成公共 API
- 不把 demo 当成熟能力
- 不让状态真相和渲染真相分裂为双源
- 不让后台线程 / 协程直接写 GUI 资源
- 不让 FFI 平台对象以裸指针语义泄露到仓颉公共层

## 当前 active opening

当前没有正在执行的直接实现 opening。

已创建受限 implementation authorization：

- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)

它只允许后续在明确继续实现时，按卡执行 `labs/macos_bridge_smoke` 内部单实例 lifecycle queue first slice；本轮尚未实现运行时代码。

最近完成的 implementation opening：

### `P1 AppKit/Metal bridge boundary cleanup implementation`

- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)

完成内容：

- `labs/macos_bridge_smoke` 已补生命周期日志。
- 已补最小 Metal capability 检查。
- 已补实验期 last-error C ABI。
- 自动关闭 smoke 已通过日志断言验证。

当前 stop-line 仍然有效：

- 不创建正式 GUI runtime。
- 不设计公共 Widget / DSL / Scene / Renderer API。
- 不做跨平台抽象。
- 不开启文本 / 输入 / IME / 无障碍。
- 不实现 AI semantic tree / action router。

最近完成的 docs-only opening：

### `P1 main-thread UI message queue execution card`

- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)

完成内容：

- 将 main-thread UI message queue preflight 收束为受限实现授权卡。
- 明确创建本卡本身不等于已实现；后续实现必须严格按本卡执行。
- 限定未来第一刀只做 `labs/macos_bridge_smoke` 内部单实例 lifecycle queue。
- 建议第一刀只支持 `RequestClose`，不支持通用 UI update。
- 明确不做 handle table / generation 的原因和后续 target update 的升级条件。
- 固定日志断言验证要求：post close request、main-thread drain、close requested、destroy complete、event loop exited、`cjgui_app_run()` 返回 `0`。

### `P1 main-thread UI message queue preflight`

- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)

完成内容：

- 冻结未来后台任务 / Agent action / runtime 异步更新 UI 回到 macOS 主线程的规则。
- 明确 UI message queue owner 是主线程 bridge runtime owner。
- 明确 enqueue 只能来自受控入口，drain 只能由主线程 event-loop adapter 执行。
- 明确 message payload 不允许携带 AppKit / Metal 平台对象。
- 明确 stale message 必须通过 handle / generation / lifecycle state 校验后丢弃。
- 明确 `last_error` 不能扩展成长期并发错误系统。

近期已完成的基础 opening：

### `E0 仓颉 SDK 与本机工具链就绪 preflight`

目标：

- 先确认本机能稳定编译和运行仓颉程序
- 先确认 `cjc`、`cjpm`、SDK、macOS 依赖和 shell 环境变量可用
- 为后续 `P0 macOS + Metal` 运行时实现扫清环境障碍

当前已知现实：

- 本机是 `macOS arm64`
- Xcode Command Line Tools 已存在
- 仓颉 SDK 已解压到 `/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- `source envsetup.sh` 后 `cjc` 可用
- `source envsetup.sh` 后 `cjpm` 可用
- 默认 `MacOSX26.4.sdk` 会导致仓颉 hello 链接失败
- 指定 `MacOSX15.4.sdk` 后，最小 `hello.cj` 已能编译并运行
- 指定 `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk` 后，`cjpm run` 已能运行最小项目
- `libffi 3.5.2` 已通过 Homebrew 安装，路径为 `/opt/homebrew/opt/libffi`
- 仓颉调用本地 C 静态库的最小 FFI smoke test 已通过，输出 `C FFI result: 42`

预期只覆盖：

- 安装或定位仓颉 macOS aarch64 SDK
- 执行 `envsetup.sh`
- 验证 `cjc -v`
- 验证 `cjpm --version` 或 `cjpm -h`
- 编译并运行一个最小 `hello.cj`
- 用 `cjpm init` / `cjpm run` 验证项目管理工具链

当前 E0 已完成。
后续统一参考：

- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)

P0 preflight 已创建：

- [2026-04-25-p0-macos-bridge-runtime-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)

P0 bridge smoke 已落地：

- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- [2026-04-25-p0-macos-bridge-smoke-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-execution-card.md)
- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)

人工视觉检查已确认：运行 smoke 后出现青色窗口。

P1 bridge boundary cleanup、P1 main-thread UI message queue preflight 和 P1 main-thread UI message queue execution card 都已完成。下一步仍不能扩写正式 GUI runtime；如需实现，只能按 execution card 做极窄 first slice。

## 当前 next opening

当前推荐的下一条 opening 是：

### `P1 main-thread UI message queue bounded implementation first slice`

目标：

- 只在 `labs/macos_bridge_smoke` 内部实现单实例 lifecycle queue。
- 第一刀只支持 `RequestClose` 这类 lifecycle message。
- 通过日志断言证明 post close request、main-thread drain、close requested、destroy complete、event loop exited、`cjgui_app_run()` 返回 `0`。

前置依据：

- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)
- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)

Stop-line：

- 只能按 execution card 做 bounded implementation slice
- 不支持通用 UI update
- 不支持 target update
- 不引入 public handle / handle table / generation
- 不进入正式 Scene / Renderer 实现
- 不设计公共 Widget API
- 不做跨平台抽象
- 不开启文本 / 输入 / IME / 无障碍
- 不引入 AI semantic tree / action router
- 不把平台对象泄露到仓颉公共层

历史上一条 `P0 单平台桌面运行时 first slice` 已通过 smoke 形式完成：

当前 `P0 macOS bridge smoke implementation` 已完成。
已验证自动关闭模式：

- 编译成功
- 链接成功
- 进入 macOS event loop
- 自动关闭窗口
- `cjgui_app_run()` 返回 `0`

已验证人工视觉模式：

- 运行 smoke 后出现青色窗口

残留：

- 自动截图失败，错误为 `could not create image from display`
- P1 cleanup 未解决 headless / pixel-diff 验证。
- P1 main-thread UI message queue 已有 preflight 和 execution card，但尚未实现运行时代码。

## 当前 future openings

以下内容可以保留为 future opening，但都不自动开启：

### 0A. AI-native UI semantics

状态：

- 已记录为长期方向
- 不作为当前实现入口

入口：

- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)

边界：

- 不实现 semantic tree
- 不实现 action router
- 不引入 AI runtime
- 不开启无障碍系统
- 只在未来 Element / Scene / Renderer 设计中保留语义投影空间
- P1 最多预留稳定 `id` / `tag` / debug label 这类拓扑口，不生成语义系统

### 0B. open-nwe future host demand map

状态：

- 已记录为 future demand map
- 不作为当前实现入口

入口：

- [OPEN_NWE_PRODUCT_DEMAND_MAP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)

边界：

- 不迁移 `open-nwe` 当前 React 前端
- 不为了 `open-nwe` 提前开启输入框 / IME / 富文本 / 终端 / 编辑器
- 只把 `open-nwe` 当作复杂桌面应用压力测试样本

### 1. 框架级事件模型冻结

前提：

- 第一平台运行时已经稳定

目标：

- 把平台原生事件翻译成框架自己的事件结构

### 2. 最小文本能力 preflight

前提：

- 窗口、事件、重绘已经稳定

目标：

- 明确第一阶段 `Text` 到底支持到什么程度

### 3. 基础布局系统 preflight

前提：

- 基础绘制路径稳定

目标：

- 明确布局 owner、布局输入输出、控件与布局的边界

### 4. 核心控件 first slice

前提：

- 运行时、事件、基础布局已清楚

目标：

- 只做极少量基础控件，而不是控件大全

## 当前不自动重开的线

下面这些线，在单独批准之前都不自动重开：

- 跨平台 backend
- 公共 DSL
- 输入框
- IME
- 无障碍
- 富文本
- 动画系统
- 主题系统
- 热重载
- 完整控件库

## 当前建议的下一步

如果继续推进，最合适的下一步是：

> 按 `P1 main-thread UI message queue execution card` 做 bounded implementation first slice

范围只能是 `labs/macos_bridge_smoke` 内部单实例 lifecycle queue，不能跳到正式 Scene / Renderer / Widget。
