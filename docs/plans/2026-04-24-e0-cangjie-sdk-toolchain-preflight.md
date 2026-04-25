# E0 仓颉 SDK 与本机工具链就绪 Preflight

日期：2026-04-24

性质：docs-only / environment preflight  
状态：完成  
范围：只确认仓颉 SDK、命令行工具链和最小编译运行能力，不进入 GUI 运行时代码实现。

## 1. 为什么需要 E0

在讨论 `P0 macOS + Metal` 之前，必须先确认本机能稳定完成仓颉最小开发闭环。

如果 `cjc`、`cjpm`、SDK、shell 环境变量都没有就绪，那么后续任何 GUI 设计都会卡在最基础的编译和运行环节。

## 2. 当前本机现实

- 系统：macOS arm64
- Xcode Command Line Tools：已存在
- 仓颉 SDK：已解压到 `/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- `cjc`：source `envsetup.sh` 后可用
- `cjpm`：source `envsetup.sh` 后可用
- Homebrew：已存在
- `libffi`：已通过 Homebrew 安装，版本 `3.5.2`
- 默认 macOS SDK：`MacOSX26.4.sdk`
- 兼容验证 SDK：`MacOSX15.4.sdk`

## 3. 官方文档依据

本地官方文档路径：

- [安装仓颉工具链](/Users/jiangxuanyang/Desktop/cangjie/sources/cangjie_docs_1.1/docs/dev-guide/source_zh_cn/first_understanding/install.md)

文档要点：

- macOS 版仓颉工具链支持 macOS 12.0 及以上版本。
- macOS 使用前需要安装 `libffi`。
- arm64 macOS 应下载 `cangjie-sdk-mac-aarch64-x.y.z.tar.gz`。
- 解压后通过 `source cangjie/envsetup.sh` 配置当前 shell 环境。
- 通过 `cjc -v` 验证工具链安装成功。

## 4. E0 成功标准

E0 只要证明下面这些事情：

1. 仓颉 macOS aarch64 SDK 已下载并解压到固定目录。
2. `envsetup.sh` 能正常 source。
3. `cjc -v` 可执行。
4. `cjpm -h` 或 `cjpm --version` 可执行。
5. 一个最小 `hello.cj` 能用 `cjc` 编译并运行。
6. 一个最小 `cjpm` 项目能 `cjpm run`。

说明：

- `libffi` 是官方 macOS 依赖。
- Homebrew 将它作为 keg-only 包安装，后续需要时可显式配置 `LDFLAGS`、`CPPFLAGS`、`PKG_CONFIG_PATH`。

## 4.1 当前验证结果

已通过：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`
- `cjc -v`
- `cjpm -h`
- 使用 `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk` 编译并运行最小 `hello.cj`

关键发现：

- 默认 `MacOSX26.4.sdk` 中 `libSystem.tbd` 暴露的目标包含 `arm64e-macos`，但缺少普通 `arm64-macos`，仓颉 1.1.0 默认链接时会报 `libSystem.tbd is incompatible with arm64 (macOS)`。
- 指定 `MacOSX15.4.sdk` 后，最小 hello 程序已经可以编译并输出 `Hello, Cangjie`。

新增通过：

- `brew list --versions libffi`
- `cjpm init`
- `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk cjpm run`

本机工具链配置记录：

- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)

## 5. E0 明确不做

- 不写 GUI 运行时代码。
- 不写 macOS 桥接代码。
- 不碰 Metal。
- 不创建正式 GUI 框架 API。
- 不做跨平台抽象。
- 不把 SDK 安装目录写死成公共项目契约。

## 6. 下一步

E0 完成后，才进入：

- `P0 单平台桌面运行时 first slice preflight`

如果 E0 失败，优先解决工具链安装和环境变量问题，不扩展到 GUI 技术选型。
