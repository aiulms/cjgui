# P0 macOS 桥接运行时 Preflight

日期：2026-04-25

性质：docs-only / platform preflight / first runtime slice  
状态：草案，可进入下一轮执行卡  
范围：只冻结 macOS 单平台最小桥接运行时，不实现完整 GUI 框架。

## 1. 背景

E0 已经完成：

- 仓颉 SDK 已安装。
- `cjc` / `cjpm` 可用。
- `libffi` 已安装。
- `MacOSX15.4.sdk` 作为当前兼容 SDK 已验证。
- 仓颉调用本地 C 静态库的 FFI smoke test 已通过。

因此可以进入 P0：

> 证明仓颉可以通过极薄 macOS 平台桥接打开窗口、进入事件循环，并完成最小绘制。

## 2. 当前 authority

本轮 authority：

- [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)

参考资料：

- [GPUI Platform 接口](/Users/jiangxuanyang/Desktop/cangjie/reference_repos/gpui-zed/crates/gpui/src/platform.rs)

## 3. P0 要证明什么

P0 只证明四件事：

1. 仓颉程序可以启动 macOS 应用事件循环。
2. 仓颉程序可以通过 C/Objective-C shim 创建一个 `NSWindow`。
3. 窗口内容可以承载最小绘制表面。
4. 程序可以完成一次可见绘制，优先目标是 Metal 清屏或画一个纯色矩形。

P0 成功不代表 GUI 框架完成。
P0 只代表第一块平台底座真实可行。

## 4. 当前推荐分层

P0 采用三层，而不是完整 GPUI/WGPUI 全链路：

```text
仓颉入口层
-> C ABI 桥接层
-> Objective-C / AppKit / Metal 平台层
```

### 4.1 仓颉入口层

职责：

- 调用 `cjgui_app_run()`
- 传入最小窗口配置
- 暂时不持有复杂 UI 状态
- 暂时不暴露公共 Widget API

### 4.2 C ABI 桥接层

职责：

- 对仓颉暴露稳定的 C 函数。
- 隐藏 Objective-C 对象和 macOS 原生类型。
- 将未来可扩展的 callback 入口预留为 C ABI 形式。

示例函数形状：

```c
int32_t cjgui_app_run(void);
```

P0 可以先只暴露一个函数。

### 4.3 Objective-C / AppKit / Metal 平台层

职责：

- 创建 `NSApplication`
- 创建 `NSWindow`
- 创建最小 view 或 `CAMetalLayer`
- 进入 macOS event loop
- 完成一次或持续的最小绘制

## 5. P0 不引入哪些层

P0 不做：

- `Entity`
- `Context`
- `Element tree`
- `Scene`
- `Renderer` 公共抽象
- Layout
- Widget
- DSL
- Text
- Input
- IME
- Accessibility
- Clipboard
- Drag and drop
- Multi-window
- Cross-platform backend

这些都是 future opening，不在 P0 自动开启。

## 6. 技术选型判断

### 6.1 首发平台

批准倾向：

- macOS first

原因：

- 当前开发机器就是 macOS arm64。
- 仓颉 macOS SDK 已安装并验证。
- AppKit / Metal 是 macOS 原生桌面和 GPU 绘制路径。

### 6.2 桥接语言

批准倾向：

- Objective-C `.m` 或 Objective-C++ `.mm`
- 对仓颉只暴露 C ABI

原因：

- 仓颉官方支持 C FFI。
- AppKit / Metal 是 Objective-C API。
- C ABI 是最稳的语言边界。

### 6.3 渲染后端

批准倾向：

- P0 以 Metal 为目标。

降级路径：

- 如果 Metal 首次接入成本过高，允许先完成 AppKit 窗口 + view 背景色绘制。
- 但降级必须明确记录，不得把 AppKit 背景色绘制冒充为 Metal 路线完成。

## 7. Owner / Truth / Projection

Owner：

- `native/macos` 持有平台对象生命周期。
- 仓颉层只持有调用入口和未来 API 草稿。

Truth：

- P0 的真相是“平台窗口是否真实创建、事件循环是否真实运行、绘制是否真实可见”。
- 不是 API 是否好看。
- 不是 demo 代码是否像最终框架。

Projection：

- 示例 main 只是 smoke test。
- C ABI 函数名只是 P0 实验接口。
- 任何 demo 都不能反向定义未来公共 API。

## 8. 失败窗口

可能失败点：

- AppKit 主线程要求没有被满足。
- 仓颉 runtime 与 `NSApplicationMain` / `[NSApp run]` 生命周期冲突。
- Objective-C 代码编译和 `cjc` 链接参数不稳定。
- Metal layer 创建成功但没有可见绘制。
- `MacOSX26.4.sdk` 链接问题再次出现。
- 关闭窗口后进程无法退出或异常退出。

对应防守：

- 继续固定 `MacOSX15.4.sdk`。
- 先做单窗口。
- 先做一个 `cjgui_app_run()`。
- 先做可见绘制，不做上层 API。
- 先用人工视觉检查作为有效验证证据。

## 9. Write Set 建议

下一轮实现允许新增：

- `labs/macos_bridge_smoke/`

建议结构：

```text
labs/macos_bridge_smoke/
  README.md
  scripts/
    env.sh
    build_and_run.sh
  native/
    cjgui_macos.h
    cjgui_macos.m
  src/
    main.cj
```

禁止触碰：

- `sources/`
- `repos/`
- `reference_repos/`
- 仓颉 SDK 安装目录
- 系统 SDK symlink
- 已有治理文档之外的无关内容

## 10. P0 验证标准

实现后至少要提供：

- 编译命令成功。
- 运行命令成功。
- 终端输出明确生命周期日志。
- 人工确认窗口真实出现。
- 如果做了 Metal，人工确认窗口内容不是空白。
- 关闭窗口后进程能正常退出。

如果无法截图或自动化验证，必须在 closure review 中明确记录人工视觉检查结果。

## 11. Stop-line

P0 结束时只允许得到：

- 一个 macOS 桥接 smoke demo。
- 一个可复用的最小构建脚本。
- 一条从仓颉到 macOS 窗口 / 绘制的真实链路。

P0 不能顺手长成：

- 正式公共 API
- Entity / Context 运行时
- Widget 系统
- Layout 系统
- 跨平台抽象
- 完整 Renderer 架构

## 12. 是否允许进入实现

允许进入下一轮：

- `P0 macOS bridge smoke implementation`

但必须先填写：

- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)

下一轮实现的唯一目标：

> 在 `labs/macos_bridge_smoke/` 中证明仓颉可以通过 C/Objective-C shim 打开一个 macOS 窗口，并完成最小可见绘制。
