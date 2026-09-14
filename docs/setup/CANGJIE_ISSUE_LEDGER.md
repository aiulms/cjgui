# 仓颉问题判定、上游倒推与贡献账本

最后更新：2026-04-30

性质：toolchain issue ledger / upstream feedback loop / contribution evidence / recheck list
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

CJGUI 也是仓颉语言、工具链和 FFI 能力的长期压力测试场。
如果 GUI runtime 开发过程中发现仓颉上游缺口，本项目不只是在本地绕开问题，还要尽量把可复现证据倒推给上游，形成 issue、文档修正、最小复现或能力建议。

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

每轮 closure / bundled closure 必须做一次轻量判断：

- 本轮是否遇到新的仓颉语法、编译器、SDK、FFI、cjpm、标准库或工具链问题。
- 如果遇到，是否已经在本账本新增或更新条目。
- 如果暂不入账，closure 需要说明原因，例如“确认是本项目误用”“只是一次性环境问题”“无稳定复现”。

这条规则的目标不是阻塞 runtime 主线，而是防止我们把上游问题埋在 workaround 里，过几周换会话后又重新踩一遍。

## 3. 上游倒推 / 贡献闭环

遇到疑似仓颉上游问题时，按下面闭环处理。

### 3.1 Detect：发现信号

以下信号应触发上游问题判断：

- `cjc` / `cjpm` / SDK / 标准库行为与官方文档或合理语义不一致。
- C FFI、C ABI、linker、platform SDK、debug / profile / coverage 工具出现稳定异常。
- 为了继续推进 CJGUI，不得不引入仓颉 toolchain workaround。
- 同一类仓颉限制反复影响 runtime、platform bridge、build 或 smoke。
- 仓颉文档缺少关键说明，导致实现 AI 或人类反复误判。

### 3.2 Minimize：最小化证据

在提交上游前，优先准备：

- 最小复现代码，优先放在 `/tmp/<topic>-repro-YYYYMMDD`，或可长期保留的 `labs/*_smoke`。
- 精确版本：`cjc --version`、`cjpm --version`、SDK 版本、平台和架构。
- 完整命令：包含 `envsetup.sh`、`SDKROOT`、`cjpm build`、`cjc` 参数。
- 实际错误输出和预期行为。
- 如果有 workaround，记录 workaround 命令和移除条件。

### 3.3 Classify：先归因，再上游

先把问题分成：

- 本项目误用。
- 本机环境问题。
- 官方文档缺口。
- 疑似编译器 / SDK / 标准库 / FFI / cjpm bug。
- 语言能力缺口或工具链能力缺口。

只有在有最小复现或稳定证据后，才升级到 `UPSTREAM_SUSPECTED` / `UPSTREAM_REPORTED`。

### 3.4 Workaround：继续推进但留下移除条件

如果本项目可以安全 workaround，允许继续推进 runtime 主线。

但 workaround 必须记录：

- 影响范围。
- 当前为什么可接受。
- 未来什么版本、issue 状态或验证命令通过后可以移除。
- 这是否影响 public API / C ABI / platform bridge 设计。

### 3.5 Report / Contribute：倒推上游

可贡献形式不只限于 bug issue：

- 上游 issue：稳定 bug、兼容性问题、工具链异常。
- 文档 PR / 文档建议：语义、FFI、工具链参数、平台限制说明不清。
- 最小复现仓库或 smoke：帮助上游快速定位。
- 能力建议：语言、调试、profiling、FFI、包管理、跨平台编译能力缺口。
- 设计反馈：来自 GUI runtime 场景的具体约束和用例。

提交上游时，优先带上：

- 最小复现。
- 预期 / 实际行为。
- CJGUI 中的实际影响。
- 当前 workaround。
- 是否阻塞当前路线。

### 3.6 Recheck：随上游演进复查

每次升级仓颉 SDK / toolchain / 文档后，应复查仍处于 `UPSTREAM_SUSPECTED` / `UPSTREAM_REPORTED` 且有 workaround 的条目。

复查不是只看“是否能跑”，还要判断：

- workaround 是否可以删除。
- 项目文档是否要更新。
- 本地 smoke 是否要简化。
- 曾经的运行时设计保守假设是否可以收窄。

## 4. 判定等级

### 4.1 `UNCLASSIFIED`

默认状态。

含义：

- 现象已经出现。
- 还不能判断是我们误用、环境问题还是上游 bug。

要求：

- 必须补最小复现。
- 必须补当前仓颉版本。
- 必须补当前命令和错误输出。

### 4.2 `MISUSE_CONFIRMED`

确认是我们没有按文档使用。

处理：

- 在相关 setup / build 文档补正确用法。
- 不提交上游。
- 保留记录，防止未来重复踩坑。

### 4.3 `ENVIRONMENT_ISSUE`

确认是本机、SDK 路径、shell、Homebrew、Xcode、macOS SDK 等环境问题。

处理：

- 更新 [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md) 或 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)。
- 不直接归因给仓颉。

### 4.4 `UPSTREAM_SUSPECTED`

疑似仓颉上游问题，但证据还不足。

进入这个状态必须有：

- 最小复现。
- 当前版本。
- 预期行为。
- 实际行为。
- 官方文档依据或合理语言语义依据。

### 4.5 `UPSTREAM_REPORTED`

已经提交给仓颉社区 / 官方 / 仓库。

要求：

- 记录 issue 链接。
- 记录提交日期。
- 记录 workaround。
- 记录下一次复查日期。

### 4.6 `RESOLVED`

问题已解决。

要求：

- 记录解决版本。
- 记录验证命令。
- 记录是否移除 workaround。

## 5. 每条问题的记录模板

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
- workaround 移除条件：
- 是否适合提交上游：是 / 否 / 待定
- 上游目标仓库：`Cangjie/cangjie_compiler | Cangjie/CangjieCommunity | docs | other | 待定`
- 上游贡献类型：bug / docs / repro / proposal / tooling / FFI / 待定
- CJGUI 临时决策：继续 workaround / fail closed / 阻塞当前线 / 待定
- 上游提交材料路径：
- 上游链接：
- 下次复查日期：
- 复查命令：
- 结论更新记录：
```

## 6. 复查节奏

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

## 7. 当前问题账本

### CJ-20260425-001：默认 `MacOSX26.4.sdk` 导致仓颉 1.1.0 macOS arm64 最小程序链接失败

- 状态：`LOCAL_1_1_3_VERIFIED_UPSTREAM_ISSUE_OPEN`
- 最新核对（2026-09-13）：上游 #859 中仓颉 Committer liujiajie 称 1.1.3 已修复，并指向[官方 1.1.3 下载](https://cangjie-lang.cn/download/1.1.3)；页面仍为“已开启”，未显示关联 PR。已下载官方 mac-aarch64 包并核对 SHA-256 `7eff8d3b9119535cf3d05cb81526c5df391137dce908d744449f4edb99da3199`，安装到独立的 `/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3`，未替换旧 1.1.0 路径。清除 `SDKROOT`/`CJ_GUI_SDKROOT` 后，`cjc --version` 为 1.1.3，`xcrun` 默认 SDK 为 `MacOSX.sdk`（26.5）。本机已通过默认 SDK hello、C FFI（结果 42）、实际 AppKit/Metal bridge、CJGUI core build，以及新编译签名的 Adaptive normal bundle 的启动、公开 GET/SET/readback、过期 CAS 拒绝和正常关闭/descriptor 清理。上游状态仍未闭合，不能据本机验证替上游关闭 issue。
- 优先级：`P1`
- 影响范围：链接 / SDK 兼容 / 本机工具链
- 首次发现日期：2026-04-25
- 影响版本：Cangjie Compiler 1.1.0，macOS arm64 SDK 包；1.1.3 已在本机默认 SDK 验证通过
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

- 历史 workaround / 可显式回退：

```bash
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjc hello.cj -o hello
./hello
```

- 当前判断：这是 1.1.0 与当时默认 26.4 SDK 的历史兼容故障；不能从 1.1.0 推断 1.1.3 失败。本机 1.1.3 在当前 26.5 默认 SDK 已满足 hello、FFI、bridge 与 normal GUI 的分层验证，但 issue 的上游关闭、其他 macOS/SDK 组合和发布验收仍未知。
- workaround 移除条件：**本机项目默认**已满足：1.1.3 在默认 `SDKROOT` 下最小 `hello.cj` 可直接 `cjc hello.cj -o hello` 并运行，且 FFI/normal GUI 已通过。15.4 仍保留为显式覆盖回退，而非默认；上游 issue 是否关闭仍由维护者决定。
- 是否适合提交上游：是。
- 上游目标仓库：`Cangjie/cangjie_compiler`
- 上游贡献类型：bug / repro / tooling
- CJGUI 当前决策：项目入口使用 1.1.3，normal runner 默认采用 `xcrun --sdk macosx --show-sdk-path`；`CJ_GUI_SDKROOT` 或有效 `SDKROOT` 仍可显式选择 15.4。旧全局工具链不被覆盖。
- 上游提交材料路径：本条目内 “上游 issue 草稿”。
- 上游链接：[Cangjie/cangjie_compiler#859](https://gitcode.com/Cangjie/cangjie_compiler/issues/859)
- 下次复查日期：下次升级仓颉 SDK 或 Xcode Command Line Tools 后。
- 复查命令：

```bash
unset SDKROOT CJ_GUI_SDKROOT
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
cd /tmp/cangjie-sdk-issue-repro-20260425
cjc hello.cj -o hello
./hello
```

- 结论更新记录：
- 2026-09-13：确认维护者的1.1.3修复声明及官方mac-aarch64包入口；安排[工具链与技能配套升级](../plans/2026-09-13-cangjie-113-skills-upgrade.md)，未替换当前编译器或删除SDK workaround。
- 2026-09-13：按官方 SHA-256 安装并显式验证 1.1.3。默认 26.5 SDK 的 hello、C FFI、AppKit/Metal bridge、CJGUI core 和 Adaptive normal bundle 均通过；项目默认改为 1.1.3/默认 SDK，旧 1.1.0 与 15.4 显式回退保留，上游 issue 未关闭。
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

## 8. 不进入本账本的问题

以下问题不默认进入本账本：

- GUI 自动截图权限问题，除非证明与仓颉 runtime 有关。
- AppKit / Metal 使用错误，除非最小复现证明仓颉 FFI 行为异常。
- 我们自己的 Objective-C shim 崩溃。
- 我们自己的构建脚本写错。
- 参考仓库自身的问题。

这些问题应该优先进入对应的 preflight、execution card、closure review 或 [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)。
