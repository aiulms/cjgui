# 仓颉鸿蒙 UI 冒烟（ohos_cangjie_smoke）

最后更新：2026-09-20

> **接手鸿蒙线先读**：[鸿蒙 × 仓颉能力基线与证据（交接文档）](../../docs/plans/2026-09-20-harmonyos-cangjie-handoff.md)
> —— 那里有环境清单、全部已验证能力的复现命令与期望输出、坑表、未做事项；
> 标"已验证"的结论不必重跑。

用途：验证 **仓颉（Cangjie）声明式 ArkUI 应用**能否在鸿蒙模拟器上完成
`构建 → 安装 → 启动 → UI 读取 → 交互 → 状态更新` 全链路，作为 CJGUI 鸿蒙侧的
可复现基线。结论：**已验证通过（2026-09-20）**。

## 已验证结论与证据

```
A00001/CangjiePoc: MyAbilityStage onCreated.
A00000/CangjiePoc: MainAbility ctor + registerSelf done
A00000/CangjiePoc: MainAbility OnCreated.MainAbility
A00000/CangjiePoc: START_ABILITY
A00000/CangjiePoc: onWindowStageCreate begin → loadContent returned
A00000/CangjiePoc: onForeground
null cjAbilityObj 出现次数：0

UI 树（点击前）：Text [109,1345,1212,1550] "Hello Cangjie" clickable
UI 树（点击后）：Text [62,1242,1258,1652] "Hello Cangjie from emulator" clickable   ← @State 响应式生效
```

设备：DevEco 模拟器 `Pura 90`，HarmonyOS 6.1.1(24) Beta1（API 24），arm64。
HAP 产物：`libs/arm64-v8a/libentry.so`（仓颉模块，ELF aarch64）+ 仓颉 std 运行时库。

## 前置条件

1. DevEco Studio 26（`/Applications/DevEco-Studio.app`）且已安装**仓颉插件**（插件内含
   `harmonyos-cangjie-sdk-mac-arm.zip`；本机已解压到
   `~/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/`，可用 `DEVECO_CANGJIE_HOME` 覆盖）。
2. 鸿蒙模拟器实例（本机为 `Pura 90`）。启动见 `scripts/start_emulator.sh`。
3. `hdc`、`devecocli`（DevEco CLI）。

## 结构

- `entry/src/main/cangjie/{index,main_ability,ability_stage}.cj`：仓颉 UI（`@Entry/@Component/@State`）、UIAbility、AbilityStage
- `entry/src/main/cangjie/*_entry.cj`：**构建自动生成的注册胶水**（`UIAbility.registerCreator(...)`），不必手改
- `entry/cjpm.toml`：`output-type = "dynamic"` + `[target.aarch64-linux-ohos]` 编译选项 +
  `[target.aarch64-linux-ohos.bin-dependencies] path-option = ["${AARCH64_LIBS}","${AARCH64_MACRO_LIBS}","${AARCH64_KIT_LIBS}"]`
- `entry/build-profile.json5`：`buildOption.cangjieOptions.path = ./cjpm.toml`
- `hvigor/hvigor-config.json5`：依赖 `@ohos/cangjie-build-support`（**注意：当前为指向本机插件目录的
  `file:` 绝对路径，换机器需改**）
- `hvigorfile.ts`（根/模块）：从 `@ohos/cangjie-build-support` 导入 `appTasks` / `hapTasks`
- `scripts/`：`env.sh`、`start_emulator.sh`、`build_and_run.sh`

## 运行

```bash
bash scripts/start_emulator.sh          # 启动模拟器（首次需接受许可；GUI 亦可）
bash scripts/build_and_run.sh           # 构建 → 安装 → 启动 → 打印日志与 UI 树
```

## 关键坑（都踩过，按此避坑）

| 坑 | 现象 | 解法 |
| --- | --- | --- |
| **仓颉包名约定** | 包名写成 `entry` 时：`E C01332/UIAbility: null cjAbilityObj`、窗口空白、无任何仓颉日志 | 包名必须是 **`ohos_app_cangjie_<模块名>`**（如 `ohos_app_cangjie_entry`），且 `module.json5` 的 `srcEntry` 与之一致 |
| 日志域 | `Hilog.info(1, ...)` 看不到输出，误判"代码没跑" | 调试用 `domain=0` |
| hvigor 未接仓颉管线 | 只跑 ArkTS 任务、不打包仓颉库 | `hvigor-config.json5` 加 `@ohos/cangjie-build-support` 依赖；`hvigorfile.ts` 从该包导任务 |
| `devecocli emulator start` | 报 "system image ... cannot be found" | 它走自己的镜像注册表；改用 `Emulator -start`（`scripts/start_emulator.sh`） |
| `cjc-version` | cjpm 报字段错误 | 写 semver（如 `1.0.0`），不是编译器版本串 |
| `@Entry` 宏报未定义符号 | `ObservedProperty` / `observeComponentCreation` 未定义 | 保留模板完整的 `kit.ArkUI.*` 导入，宏会生成对这些符号的引用 |
| `uiSyntax` / `main_pages.json` | hvigor schema 拒绝 | 仓颉模块**不要**加 `uiSyntax`，也**不要**保留页面清单文件 |

## CJGUI 核心 ohos 交叉编译探针（2026-09-20）

目的：回答"`runtime/cjgui` 的仓颉核心能否为鸿蒙目标编译"。做法：把 cjgui 源码同步进
`cjgui_core_probe` 模块（HAR，源码目录被 .gitignore 排除，**不改动 runtime/cjgui 本体**），
用本 lab 已验证的 hvigor 仓颉管线按 `aarch64-linux-ohos` 编译。

```bash
bash scripts/probe_cjgui_ohos.sh      # 同步源码 → 编译 → 汇总结果
```

探针清单与 `runtime/cjgui/cjpm.toml` 的差异（即平台桥必须处理的部分）：
去掉 darwin 链接框架（AppKit/Metal/MetalKit/QuartzCore/lobjc）与 `[ffi.c] cjgui_internal_renderer`
（其 `.a` 是 Mach-O arm64，鸿蒙不可链接），并补上 ohos 目标编译选项与 `bin-dependencies`。

**结果（2026-09-20 实测）**：

| 指标 | 值 |
| --- | --- |
| 同步文件 | 404 个 `.cj`（cjgui 368 + shared_operation_core 36） |
| 编译 | **BUILD SUCCESSFUL，0 error**；61 warning（弃用 API / 未用变量等） |
| CompileCangjie 耗时 | 13.6 s |
| 产物 | `cjgui_core_probe.har`（6.2 MB）内含 `libs/arm64-v8a/cjbins/cjgui/libcjgui.so` |
| 产物架构 | `ELF 64-bit LSB shared object, ARM aarch64`（鸿蒙目标，29 MB 含调试信息） |

含义：**仓颉核心（组件树/布局/文本/语义/事件模型等纯逻辑）可直接为 ohos 目标编译**，
不需要重写；缺口集中在被探针剥离的那部分——mac 平台桥（darwin FFI 静态库 + 系统框架）
需要为鸿蒙重写（XComponent surface / 输入 / 生命周期 / GLES 或 Vulkan 提交）。



## 边界与状态

- 本 lab 用于**能力验证**，不代表产品化能力；未纳入 CI，未做签名（模拟器装 unsigned HAP 即可）。
- 仓颉鸿蒙能力目前是 Experiment（受控权限），SDK 版本与模拟器镜像需配对（本机 26.0.0.105 ↔ 6.1.1(24)）。
- 更大范围的差异与移植分析见
  [docs/plans/2026-09-18-harmonyos-cangjie-dev-differences.md](../../docs/plans/2026-09-18-harmonyos-cangjie-dev-differences.md)
  与 [可行性说明](../../docs/plans/2026-09-18-harmonyos-deveco-cjgui-feasibility.md)。
