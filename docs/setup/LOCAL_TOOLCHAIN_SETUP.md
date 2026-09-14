# 本机仓颉工具链配置

最后更新：2026-09-13

性质：local setup / environment note  
状态：生效中  
范围：记录本机仓颉 SDK、macOS SDK 兼容问题和当前推荐编译方式

## 1. 当前安装位置

CJGUI 默认使用的新 SDK 安装在：

```bash
/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3
```

每次新 shell 使用前，先执行：

```bash
unset SDKROOT CJ_GUI_SDKROOT
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
```

## 2. 当前工具链版本

当前默认验证为：

```text
Cangjie Compiler: 1.1.3 (cjnative)
Target: aarch64-apple-darwin
```

1.1.0 仍保留在 `/Users/jiangxuanyang/cangjie-toolchains/cangjie`，仅作为可显式选择的
回退与历史复现路径，不是项目默认工具链。

## 3. macOS SDK 兼容问题

当前系统默认 SDK 是：

```bash
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
```

它指向：

```bash
/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
```

仓颉 1.1.0 曾在默认 26.x SDK 下链接最小程序失败：

```text
libSystem.tbd is incompatible with arm64 (macOS)
```

该历史故障由旧工具链 bundled linker 与 SDK target 表达不兼容引起。当前已用 1.1.3 在
默认 26.5 SDK 通过 hello、C FFI、AppKit/Metal bridge、CJGUI core 与 normal bundle 的真实读写/关闭；
上游 issue 仍开启，详见 [CANGJIE_ISSUE_LEDGER.md](CANGJIE_ISSUE_LEDGER.md)。

## 4. 当前推荐解决方式

不要修改系统 SDK symlink。

默认使用 1.1.3 与系统当前 SDK，不修改系统 SDK symlink：

```bash
unset SDKROOT CJ_GUI_SDKROOT
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
```

直接使用 `cjc` 时：

```bash
cjc hello.cj -o hello
```

使用 `cjpm` 时：

```bash
cjpm run
```

## 5. 已通过的 smoke 验证

已验证：

- `cjc -v`
- `cjpm -h`
- 默认 SDK 下的 `cjc hello.cj -o hello`
- 默认 SDK 下的 `cjpm run`
- 仓颉调用本地 C 静态库函数
- AppKit / Metal bridge 与 CJGUI normal macOS bundle 的公开 `GET`、`SET_MARKED`、读回和正常关闭

FFI smoke test 路径：

- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)

macOS bridge smoke test 路径：

- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)

## 6. 后续建议

如需复现旧 1.1.0 或针对性回退，可只在该进程显式固定 15.4：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
```

项目 normal runner 默认跟随 `xcrun --sdk macosx --show-sdk-path`，但会优先尊重
`CJ_GUI_SDKROOT`（其次是有效的 `SDKROOT`），因此上述回退不污染系统配置。

## 7. libffi

官方文档要求 macOS 安装 `libffi`。

当前已通过 Homebrew 安装：

```text
libffi 3.5.2
```

安装路径：

```bash
/opt/homebrew/opt/libffi
```

由于 Homebrew 将 `libffi` 标记为 keg-only，后续如果编译器、C shim 或 pkg-config 需要显式查找它，可以设置：

```bash
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"
```
