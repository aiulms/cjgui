# 仓颉问题判定与上游 Bug 账本

最后更新：2026-04-25

性质：toolchain issue ledger / upstream bug evidence / recheck list  
状态：生效中  
范围：记录仓颉语言、SDK、编译器、标准库、FFI、包管理与本机工具链相关问题。

## 1. 这个文档解决什么问题

仓颉是一门较新的语言。

后续开发中，我们一定会遇到三类问题：

- 我们自己没有按文档使用。
- 本机环境或构建链配置有问题。
- 仓颉编译器、SDK、标准库、FFI 或工具链本身存在 bug / 兼容问题。

本文件用于把这些问题分开记录。

原则：

> 先记录证据，再判断归因；没有最小复现前，不轻易把问题定性为仓颉 bug。

## 2. 使用规则

遇到疑似仓颉问题时，先不要直接在实现代码里绕。

应该先记录：

- 现象是什么。
- 影响哪个版本。
- 命令怎么复现。
- 最小复现代码是什么。
- 官方文档是否支持我们的用法。
- 是否有 workaround。
- 当前判断是我们误用、环境问题，还是疑似上游 bug。

如果只是工程临时问题，不需要长期追踪，可以写在 execution card 或 closure review 里。

如果问题满足以下任一条件，应该进入本账本：

- 影响 SDK 安装、编译、链接、运行。
- 影响 C FFI / C ABI / cjpm。
- 影响标准库或语言语义理解。
- 有稳定最小复现。
- 暂时只能靠 workaround 推进。
- 未来适合提交给仓颉社区或官方 issue。

## 3. 判定等级

### 3.1 `UNCLASSIFIED`

默认状态。

含义：

- 现象已经出现。
- 还不能判断是我们误用、环境问题还是上游 bug。

要求：

- 必须补最小复现。
- 必须补当前仓颉版本。
- 必须补当前命令和错误输出。

### 3.2 `MISUSE_CONFIRMED`

确认是我们没有按文档使用。

处理：

- 在相关 setup / build 文档补正确用法。
- 不提交上游。
- 保留记录，防止未来重复踩坑。

### 3.3 `ENVIRONMENT_ISSUE`

确认是本机、SDK 路径、shell、Homebrew、Xcode、macOS SDK 等环境问题。

处理：

- 更新 [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md) 或 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)。
- 不直接归因给仓颉。

### 3.4 `UPSTREAM_SUSPECTED`

疑似仓颉上游问题，但证据还不足。

进入这个状态必须有：

- 最小复现。
- 当前版本。
- 预期行为。
- 实际行为。
- 官方文档依据或合理语言语义依据。

### 3.5 `UPSTREAM_REPORTED`

已经提交给仓颉社区 / 官方 / 仓库。

要求：

- 记录 issue 链接。
- 记录提交日期。
- 记录 workaround。
- 记录下一次复查日期。

### 3.6 `RESOLVED`

问题已解决。

要求：

- 记录解决版本。
- 记录验证命令。
- 记录是否移除 workaround。

## 4. 每条问题的记录模板

```md
### CJ-YYYYMMDD-NNN：一句话标题

- 状态：`UNCLASSIFIED | MISUSE_CONFIRMED | ENVIRONMENT_ISSUE | UPSTREAM_SUSPECTED | UPSTREAM_REPORTED | RESOLVED`
- 优先级：`P0 | P1 | P2 | P3`
- 影响范围：编译 / 链接 / 运行 / FFI / 标准库 / cjpm / 文档 / 其他
- 首次发现日期：YYYY-MM-DD
- 影响版本：Cangjie Compiler x.y.z，SDK / stdx / runtime 版本
- 平台：macOS / Linux / Windows，架构
- 现象：
- 预期：
- 实际：
- 最小复现路径：
- 复现命令：
- 关键错误输出：
- 当前判断：
- workaround：
- 是否适合提交上游：是 / 否 / 待定
- 上游链接：
- 下次复查日期：
- 复查命令：
- 结论更新记录：
```

## 5. 复查节奏

默认复查节奏：

- 每次升级仓颉 SDK 后，复查所有 `UPSTREAM_SUSPECTED` / `UPSTREAM_REPORTED`。
- 每次修改 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md) 后，复查构建链相关问题。
- 每月至少看一次仍有 workaround 的问题。
- 如果官方 release notes 提到相关模块，立即复查。

复查时不要只看“现在能不能跑”。

还要确认：

- workaround 是否仍然必要。
- 官方行为是否已经变化。
- 我们的文档是否需要更新。
- 旧判断是否需要改成误用、环境问题或已解决。

## 6. 当前问题账本

### CJ-20260425-001：默认 `MacOSX26.4.sdk` 导致仓颉 1.1.0 macOS arm64 最小程序链接失败

- 状态：`UPSTREAM_REPORTED`
- 优先级：`P1`
- 影响范围：链接 / SDK 兼容 / 本机工具链
- 首次发现日期：2026-04-25
- 影响版本：Cangjie Compiler 1.1.0，macOS arm64 SDK 包
- 平台：macOS 26.4.1 / Darwin 25.4.0 / arm64 / Command Line Tools
- 现象：使用默认 macOS SDK 链接最小仓颉程序失败。
- 预期：最小 `hello.cj` 可以在默认 Command Line Tools SDK 配置下编译和链接。
- 实际：默认 `MacOSX26.4.sdk` 链接失败；显式指定 `MacOSX15.4.sdk` 后可编译和运行。
- 最小复现路径：`/tmp/cangjie-sdk-issue-repro-20260425/hello.cj` 或 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md) 中的 hello 验证步骤。
- 复现命令：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
cd /tmp/cangjie-sdk-issue-repro-20260425
cjc hello.cj -o hello
```

- 关键错误输出：

```text
info: selected Darwin SDK path: /Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk (SDK Version: 26.4)
ld64.lld: error: /Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk/usr/lib/libSystem.tbd(/usr/lib/libSystem.B.dylib) is incompatible with arm64 (macOS)
ld64.lld: error: undefined symbol: ___stack_chk_fail
ld64.lld: error: undefined symbol: ___stack_chk_guard
ld64.lld: error: undefined symbol: __dyld_get_image_header
ld64.lld: error: too many errors emitted, stopping now (use --error-limit=0 to see all errors)
error: '/Users/jiangxuanyang/cangjie-toolchains/cangjie/third_party/llvm/bin/ld64.lld' ... command failed (use -V to see invocation)
```

- 环境证据：

```text
Cangjie Compiler: 1.1.0 (cjnative)
Target: aarch64-apple-darwin
SDKROOT after envsetup: /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
MacOSX.sdk -> MacOSX26.4.sdk
xcrun --sdk macosx --show-sdk-version: 26.4.1
bundled linker: /Users/jiangxuanyang/cangjie-toolchains/cangjie/third_party/llvm/bin/ld64.lld
bundled linker version: LLD 15.0.4
system linker: /Library/Developer/CommandLineTools/usr/bin/ld
system linker version: ld-1266.8, Apple TAPI 21.0.0
```

- `.tbd` 对比证据：

```text
MacOSX26.4.sdk/usr/lib/libSystem.tbd targets:
[ x86_64-macos, x86_64-maccatalyst, arm64e-macos, arm64e-maccatalyst ]

MacOSX15.4.sdk/usr/lib/libSystem.tbd targets:
[ x86_64-macos, x86_64-maccatalyst, arm64-macos, arm64-maccatalyst, arm64e-macos, arm64e-maccatalyst ]
```

- 对照实验：

```bash
cd /tmp/cangjie-sdk-issue-repro-20260425
xcrun clang -arch arm64 hello.c -o hello-clang-default
./hello-clang-default
```

结果：

```text
Hello, clang
```

说明：

- 系统 `clang` + 系统 `ld` 能在默认 `MacOSX26.4.sdk` 下编译 `arm64` C 程序。
- 仓颉 1.1.0 使用 bundled `ld64.lld 15.0.4`，在同一 SDK 下失败。
- `--target arm64e-apple-darwin` / `--target aarch64e-apple-darwin` 不可用，仓颉报架构不支持。
- `-B /Library/Developer/CommandLineTools/usr/bin` 没有让 `cjc` 改用系统 `ld`。
- 通过 `--link-options "-syslibroot ...MacOSX15.4.sdk"` 追加 syslibroot 不能覆盖 `cjc` 已选择的 `MacOSX26.4.sdk`，仍失败。

- workaround：

```bash
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjc hello.cj -o hello
./hello
```

- 当前判断：更像仓颉 1.1.0 自带 `ld64.lld 15.0.4` 与 `MacOSX26.4.sdk` 的 `libSystem.tbd` / target 表达不兼容，而不是仓颉源码用法错误。仍需上游确认这是已知限制、期望用户固定旧 SDK，还是需要升级 bundled linker / TAPI 支持。
- 是否适合提交上游：是。
- 上游链接：[Cangjie/cangjie_compiler#859](https://gitcode.com/Cangjie/cangjie_compiler/issues/859)
- 下次复查日期：下次升级仓颉 SDK 或 Xcode Command Line Tools 后。
- 复查命令：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
cd /tmp/cangjie-sdk-issue-repro-20260425
cjc hello.cj -o hello
./hello
```

- 结论更新记录：
  - 2026-04-25：记录为疑似上游 / SDK 兼容问题，当前采用 `MacOSX15.4.sdk` workaround。
  - 2026-04-25：补充系统性排查。默认 SDK 失败、指定 `SDKROOT=MacOSX15.4.sdk` 成功；系统 clang + Apple ld 使用默认 SDK 成功；`MacOSX26.4.sdk` 的 `libSystem.tbd` 不再列出 `arm64-macos`，仓颉 bundled `ld64.lld 15.0.4` 无法接受该组合。
  - 2026-04-25：已提交到 GitCode，上游 issue 为 [#859](https://gitcode.com/Cangjie/cangjie_compiler/issues/859)。

#### 上游 issue 草稿

标题：

```text
macOS arm64: Cangjie 1.1.0 fails to link hello world with MacOSX26.4.sdk, bundled ld64.lld reports libSystem.tbd incompatible with arm64
```

正文：

````md
## Environment

- macOS: 26.4.1
- Darwin: 25.4.0 arm64
- Developer directory: `/Library/Developer/CommandLineTools`
- Default SDK: `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`
- Default SDK symlink: `MacOSX.sdk -> MacOSX26.4.sdk`
- Cangjie Compiler: `1.1.0 (cjnative)`
- Cangjie target: `aarch64-apple-darwin`
- Bundled linker: `third_party/llvm/bin/ld64.lld`
- Bundled linker version: `LLD 15.0.4`
- System linker: Apple `ld-1266.8`, Apple TAPI `21.0.0`

## Minimal reproduction

`hello.cj`:

```cangjie
main(): Int64 {
    println("Hello, Cangjie")
    return 0
}
```

Command:

```bash
source /path/to/cangjie/envsetup.sh
cjc hello.cj -o hello
```

## Actual result

`cjc -V hello.cj -o hello` shows:

```text
info: selected Darwin SDK path: /Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk (SDK Version: 26.4)
```

Then linking fails:

```text
ld64.lld: error: /Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk/usr/lib/libSystem.tbd(/usr/lib/libSystem.B.dylib) is incompatible with arm64 (macOS)
ld64.lld: error: undefined symbol: ___stack_chk_fail
ld64.lld: error: undefined symbol: ___stack_chk_guard
ld64.lld: error: too many errors emitted, stopping now (use --error-limit=0 to see all errors)
```

## Expected result

A minimal hello world program should link successfully with the default Command Line Tools macOS SDK, or the compiler should document/reject unsupported SDK versions with a clearer diagnostic.

## Workaround

If I force Cangjie to use `MacOSX15.4.sdk`, the same program builds and runs:

```bash
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
cjc hello.cj -o hello
./hello
```

Output:

```text
Hello, Cangjie
```

## Additional evidence

The default SDK's `libSystem.tbd` target list contains `arm64e-macos`, but not `arm64-macos`:

```text
MacOSX26.4.sdk/usr/lib/libSystem.tbd targets:
[ x86_64-macos, x86_64-maccatalyst, arm64e-macos, arm64e-maccatalyst ]
```

The older SDK contains both `arm64-macos` and `arm64e-macos`:

```text
MacOSX15.4.sdk/usr/lib/libSystem.tbd targets:
[ x86_64-macos, x86_64-maccatalyst, arm64-macos, arm64-maccatalyst, arm64e-macos, arm64e-maccatalyst ]
```

For comparison, system clang + Apple ld can link an arm64 C hello world with the default `MacOSX26.4.sdk`:

```bash
xcrun clang -arch arm64 hello.c -o hello-clang-default
./hello-clang-default
```

Output:

```text
Hello, clang
```

## Questions

1. Is macOS SDK 26.x currently unsupported by Cangjie 1.1.0 on macOS arm64?
2. Is setting `SDKROOT` to an older SDK such as `MacOSX15.4.sdk` the recommended workaround?
3. Is there a supported way to make `cjc` use the system Apple linker instead of bundled `ld64.lld`?
4. Would upgrading the bundled linker / TAPI support be the intended fix?
````

## 7. 不进入本账本的问题

以下问题不默认进入本账本：

- GUI 自动截图权限问题，除非证明与仓颉 runtime 有关。
- AppKit / Metal 使用错误，除非最小复现证明仓颉 FFI 行为异常。
- 我们自己的 Objective-C shim 崩溃。
- 我们自己的构建脚本写错。
- 参考仓库自身的问题。

这些问题应该优先进入对应的 preflight、execution card、closure review 或 [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)。
