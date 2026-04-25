# 本机仓颉工具链配置

最后更新：2026-04-25

性质：local setup / environment note  
状态：生效中  
范围：记录本机仓颉 SDK、macOS SDK 兼容问题和当前推荐编译方式

## 1. 当前安装位置

仓颉 SDK 已安装在：

```bash
/Users/jiangxuanyang/cangjie-toolchains/cangjie
```

每次新 shell 使用前，先执行：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
```

## 2. 当前工具链版本

已验证：

```text
Cangjie Compiler: 1.1.0 (cjnative)
Target: aarch64-apple-darwin
```

## 3. macOS SDK 兼容问题

当前系统默认 SDK 是：

```bash
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
```

它指向：

```bash
/Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk
```

仓颉 1.1.0 使用默认 SDK 链接最小程序时，会出现类似错误：

```text
libSystem.tbd is incompatible with arm64 (macOS)
```

原因是当前 `MacOSX26.4.sdk` 的 `libSystem.tbd` 暴露目标偏向 `arm64e-macos`，而仓颉 1.1.0 生成目标是普通 `arm64-apple-darwin`。

## 4. 当前推荐解决方式

不要修改系统 SDK symlink。

当前推荐在编译时显式使用系统已有的 `MacOSX15.4.sdk`：

```bash
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
```

直接使用 `cjc` 时：

```bash
cjc hello.cj --sysroot "$CJ_GUI_SDKROOT" -o hello
```

使用 `cjpm` 时：

```bash
SDKROOT="$CJ_GUI_SDKROOT" cjpm run
```

## 5. 已通过的 smoke 验证

已验证：

- `cjc -v`
- `cjpm -h`
- `cjc hello.cj --sysroot "$CJ_GUI_SDKROOT" -o hello`
- `SDKROOT="$CJ_GUI_SDKROOT" cjpm run`
- 仓颉调用本地 C 静态库函数

FFI smoke test 路径：

- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)

macOS bridge smoke test 路径：

- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)

## 6. 后续建议

后续项目脚本应统一封装这两个动作：

1. `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`
2. 设置 `CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`

这样不污染系统配置，也不依赖每次手动输入长路径。

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
