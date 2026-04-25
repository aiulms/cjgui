# macOS Bridge Smoke

最后更新：2026-04-25

用途：

- 验证仓颉可以通过 C ABI 调用 Objective-C macOS 平台桥接。
- 验证 AppKit 窗口可以从仓颉程序启动。
- 验证最小 Metal 清屏绘制链路。
- 验证 bridge 生命周期日志、Metal capability 检查和自动关闭退出路径。

## 运行

自动关闭模式：

```bash
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

人工检查模式：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

人工模式下，关闭窗口后进程应退出。

## 当前边界

本实验不是正式 GUI 框架 API。

它只验证：

- 仓颉到 C ABI
- C ABI 到 Objective-C
- AppKit 单窗口
- Metal 清屏
- 最小 Metal capability check
- 受控关闭和资源销毁日志

它当前会输出这些关键阶段日志：

- `cjgui: using SDKROOT=...MacOSX15.4.sdk`
- `cjgui: bridge init`
- `cjgui: capability check: metal device ok`
- `cjgui: capability check: command queue ok`
- `cjgui: window created`
- `cjgui: metal setup complete`
- `cjgui: first frame rendered`
- `cjgui: close requested: ...`
- `cjgui: destroy complete`
- `cjgui: event loop exited`

它不包含：

- Entity / Context
- Element tree / Scene
- Widget / Layout / DSL
- Text / Input / IME / Accessibility
- 跨平台后端
