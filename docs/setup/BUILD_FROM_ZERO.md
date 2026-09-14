# 从零构建手册

最后更新：2026-09-13

## 1. 文档定位

本文件是仓颉 GUI 项目的灾难恢复式构建手册。

目标是假设一台新的 macOS arm64 机器，从零准备环境，最终能跑通：

- 仓颉最小 hello
- 仓颉调用 C 静态库 smoke
- 仓颉调用 AppKit / Metal bridge smoke

本文件不替代 [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)，而是把“从零恢复构建链”的最短路径集中写清楚。

## 2. 当前已验证机器

当前验证环境：

- macOS arm64
- Cangjie Compiler `1.1.3 (cjnative)`
- 目标：`aarch64-apple-darwin`
- 默认 SDK：`/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`（本机为 26.5）
- 保留对照 SDK：`/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`
- Homebrew libffi：`/opt/homebrew/opt/libffi`

注意：

- 不要修改系统 `MacOSX.sdk` symlink。
- 在 1.1.3 且不设置 `SDKROOT`/`CJ_GUI_SDKROOT` 时，hello、C FFI、AppKit/Metal bridge 与
  CJGUI normal bundle 已在本机默认 SDK 上复验。15.4 是可显式选择的回退对照，不再是默认值。

## 3. 前置依赖

### 3.1 Xcode Command Line Tools

确认存在：

```bash
xcode-select -p
```

确认当前默认 SDK；若需要复现旧工具链或作对照，再确认 15.4 SDK：

```bash
xcrun --sdk macosx --show-sdk-path
xcrun --sdk macosx --show-sdk-version
ls /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
```

### 3.2 仓颉 SDK

当前项目使用：

```bash
/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3
```

每次新 shell 先执行：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
```

验证：

```bash
cjc -v
cjpm -h
```

### 3.3 libffi

安装：

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew install libffi
```

当前路径：

```bash
/opt/homebrew/opt/libffi
```

如需显式暴露给编译链：

```bash
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"
```

## 4. 统一环境变量

```bash
unset SDKROOT CJ_GUI_SDKROOT
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
```

## 5. 验证 hello

在临时目录创建 `hello.cj`：

```cangjie
main(): Int64 {
    println("Hello, Cangjie")
    return 0
}
```

编译：

```bash
cjc hello.cj -o hello
./hello
```

预期：

```text
Hello, Cangjie
```

## 6. 验证 C FFI smoke

路径：

- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke/scripts/build_and_run.sh
```

预期：

```text
C FFI result: 42
```

## 7. 验证 macOS bridge smoke

路径：

- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)

自动关闭验证：

```bash
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

预期关键输出：

```text
cjgui: starting macOS bridge smoke
cjgui: entering event loop
cjgui: auto-closing after 1.00 seconds
cjgui: window closed
cjgui: event loop exited
Cangjie: cjgui_app_run returned 0
```

人工视觉验证：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

预期：

- 出现标题为 `Cangjie macOS Bridge Smoke` 的窗口。
- 窗口内容为青色 / 深青色 Metal 清屏背景。
- 手动关闭窗口后进程退出。

## 8. 常见失败

### 8.1 `libSystem.tbd is incompatible with arm64`（旧 1.1.0 对照）

原因：

- 使用旧 1.1.0 工具链与当时的默认 26.x SDK。1.1.3 的当前默认 SDK 验收见本章开头，
  不能把这条历史故障当作新工具链失败。

解决：

```bash
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
```

如确有旧工具链兼容需求，可在该进程显式回退：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
```

### 8.2 找不到 `cjc`

原因：

- 没有 source 仓颉环境。

解决：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
```

### 8.3 GUI 自动截图失败

当前已知：

```text
could not create image from display
```

这不阻塞 P0 bridge smoke，但说明后续需要单独设计自动化视觉验证路径。

## 9. 维护规则

任何改动如果影响以下内容，必须同步更新本文件：

- 仓颉 SDK 安装位置
- macOS SDK 选择
- Homebrew / libffi 依赖
- C / Objective-C / Metal 编译参数
- `cjc` / `cjpm` 构建方式
- smoke test 路径或命令
- GUI 自动化验证路径

如果本文件无法让一台新机器复现当前 smoke，说明构建链已经开始腐化，必须先修本文档或开 docs-only preflight。
