# P0 macOS Bridge Smoke Closure Review

日期：2026-04-25

性质：closure review / landed slice  
状态：完成，人工视觉检查已确认，保留自动截图残留

## 1. Landed code reality

本轮新增：

- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)

核心文件：

- `scripts/env.sh`
- `scripts/build_and_run.sh`
- `native/cjgui_macos.h`
- `native/cjgui_macos.m`
- `src/main.cj`
- `README.md`

实现内容：

- 仓颉 `main.cj` 通过 `foreign func cjgui_app_run(): Int32` 调用 C ABI。
- Objective-C 层创建 `NSApplication`、`NSWindow` 和 `CAMetalLayer`。
- Metal 完成一次清屏绘制。
- `CJGUI_AUTOCLOSE_SECONDS` 支持自动关闭 smoke 窗口，方便非交互验证。

## 2. Verification

已执行：

```bash
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

结果：

```text
cjgui: starting macOS bridge smoke
cjgui: entering event loop
cjgui: auto-closing after 1.00 seconds
cjgui: window closed
cjgui: event loop exited
Cangjie: calling cjgui_app_run
Cangjie: cjgui_app_run returned 0
```

说明：

- 编译成功。
- 链接成功。
- macOS event loop 进入成功。
- 自动关闭成功。
- `cjgui_app_run()` 返回 `0`。

## 3. Visual verification

已尝试自动截图：

```bash
screencapture -x build/macos_bridge_smoke_screenshot.png
```

结果：

```text
could not create image from display
```

因此本轮没有得到自动截图证据。

人工视觉检查命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

用户已于 2026-04-25 人工确认：

- 出现了一个青色窗口。
- 该现象符合 Metal 清屏 smoke 的预期。

预期窗口行为：

- 出现标题为 `Cangjie macOS Bridge Smoke` 的窗口。
- 窗口内容为深青色 Metal 清屏背景。
- 手动关闭窗口后进程退出。

## 4. Invariant check

已守住：

- Objective-C/AppKit/Metal 类型没有泄露到仓颉层。
- 仓颉只看到 C ABI。
- 没有修改系统 SDK symlink。
- 没有引入重型 GUI 框架。
- 没有引入 Entity / Context / Element tree / Scene / Widget / Layout。

## 5. Stop-line check

本轮 stop-line 已守住。

本轮只得到：

- 一个 macOS bridge smoke demo。
- 一个可复用构建脚本。
- 一条从仓颉到 macOS 窗口 / Metal 清屏的真实链路。

没有顺手打开：

- 正式公共 API
- Entity / Context 运行时
- Widget 系统
- Layout 系统
- 跨平台抽象
- 完整 Renderer 架构

## 6. Residual

残留项：

- 自动截图失败，需要后续单独处理 macOS 截图权限或改用其他视觉验证方式。
- P0 只证明 Metal 清屏，不证明可绘制矩形、场景树或渲染命令系统。

## 7. Next opening

下一步可以选择：

- `P1 最小 Scene / Renderer 输入 preflight`
- `P1 AppKit/Metal 桥接边界清理 preflight`

默认建议：

- 先讨论 `Scene -> Renderer` 的最小输入形状。
- 暂不把自动截图失败作为主线阻塞项。
