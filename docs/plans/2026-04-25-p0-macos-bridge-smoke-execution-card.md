# P0 macOS Bridge Smoke Execution Card

日期：2026-04-25

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认
- 确认者：本轮 Codex 根据已批准 preflight 执行
- 确认依据：[P0 macOS 桥接运行时 Preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是
- 上层尽量仓颉原生：是
- 底层只保留必要平台桥接：是
- 没有过早抽象跨平台：是

## 1. Authority

本轮唯一 authority / owner 判断：

- `native/macos` 持有平台对象生命周期。
- 仓颉层只调用 C ABI 入口。

## 2. Goal

本轮唯一目标：

- 在 `labs/macos_bridge_smoke/` 中证明仓颉可以通过 C/Objective-C shim 打开 macOS 窗口，并完成最小可见绘制。

## 3. Scope

本轮只做：

- 一个 `cjgui_app_run()` C ABI 入口。
- 一个 macOS 单窗口 smoke demo。
- 优先尝试 Metal 清屏。
- 若 Metal 接入失败，允许降级为 AppKit 背景色绘制，并明确记录。
- 一个可重复执行的构建运行脚本。

本轮明确不做：

- 不做正式公共 API。
- 不做 Entity / Context。
- 不做 Element tree / Scene / Renderer 公共抽象。
- 不做 Layout / Widget / DSL。
- 不做 Text / Input / IME / Accessibility。
- 不做跨平台。

## 4. Write Set

本轮允许修改的文件 / 模块：

- `labs/macos_bridge_smoke/`
- `docs/plans/2026-04-25-p0-macos-bridge-smoke-execution-card.md`
- 必要的索引文档补账：`README.md`、`GUI_TASK_TRACKER.md`、`LOCAL_TOOLCHAIN_SETUP.md`

本轮禁止触碰的文件 / 模块：

- `sources/`
- `repos/`
- `reference_repos/`
- 仓颉 SDK 安装目录
- 系统 SDK symlink

## 5. Truth / Projection

本轮真相层：

- 真实 macOS 窗口是否出现。
- 真实事件循环是否运行。
- 真实绘制是否可见。
- 关闭窗口后进程是否退出。

本轮只是投影 / read surface 的部分：

- 示例 `main.cj`
- `cjgui_app_run()` 命名
- smoke demo 目录结构

## 6. Invariants

本轮必须守住的 invariant：

- Objective-C/AppKit/Metal 类型不泄露到仓颉公共层。
- 仓颉只看到 C ABI。
- 不修改系统 SDK 配置。
- 不引入重型 GUI 框架。

## 7. Fallout Scan Targets

本轮完成前必须检查的尾部影响：

- 公共 API：不得形成正式 API 承诺。
- 事件流：只验证 macOS event loop，不抽象事件模型。
- 状态流：不引入 UI 状态模型。
- 渲染流：只做最小可见绘制。
- 平台桥接：Objective-C 对象留在 native 层。
- 视觉 / 交互：窗口可见，关闭可退出。
- 文档 / 示例：README 与账本轻量补账。
- 测试：构建运行脚本可重复执行。

## 8. Verification

本轮计划执行的验证：

- `scripts/build_and_run.sh`
- 终端输出生命周期日志。
- 人工视觉确认窗口出现。
- 关闭窗口后进程退出。

本轮如果无法完成的验证：

- 自动截图验证可能暂不做。

对应残留风险：

- 视觉检查需要人工确认，后续可补自动化截图或像素验证。

## 9. Stop-Line

本轮 stop-line：

- 只交付 macOS bridge smoke demo。
- 不从 smoke demo 推导正式框架 API。

## 10. Closure

完成后需要同步的文档或账本：

- `labs/macos_bridge_smoke/README.md`
- `GUI_TASK_TRACKER.md`
- 如有必要，新增 closure review。
