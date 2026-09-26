# 鸿蒙 × 仓颉能力基线与证据（交接文档）

日期：2026-09-20
性质：**能力基线的单一入口**。新模型/新 Agent 接手鸿蒙线时先读本文；
凡本文标注"已验证"的结论，**不必重跑验证流程**，直接引用即可。

配套文档：

- 差异与移植分析：[2026-09-18-harmonyos-cangjie-dev-differences.md](./2026-09-18-harmonyos-cangjie-dev-differences.md)
- 可行性说明：[2026-09-18-harmonyos-deveco-cjgui-feasibility.md](./2026-09-18-harmonyos-deveco-cjgui-feasibility.md)
- 可运行基线 lab：[labs/ohos_cangjie_smoke](../../labs/ohos_cangjie_smoke/README.md)

## 0.0 范围与优先级（必读，避免与历史指令冲突）

- **2026-09-19**：指导/用户曾决定「鸿蒙暂缓、集中 macOS」，并把鸿蒙所有开发与环境排查挂起
  （见 [数据交换收尾与鸿蒙自绘通道验证](./2026-09-19-transfer-closure-harmonyos-channel-milestone.md) 页首说明）。
- **2026-09-20**：用户直接指示继续鸿蒙线（仓颉 SDK 审核通过后），本次全部工作在该指示下完成。
  按 AGENTS.md「用户当前指令优先」，**09-20 的用户指示覆盖 09-19 的挂起安排**。
- 该 milestone 的 B 节定义了鸿蒙自绘薄通道的范围，与本线一一对应：
  **B1 环境确认**（已完成，§1/§2.1）、**B2 真正运行仓颉并复用最小核心**（已完成，§2.2/§2.3）、
  **B3 一个可交互的自绘原型，按真实 SDK 选择窄桥**（**未做，下一步**）。
  该节同时要求「环境确认只做一次」，与本文 §7「何时才需重新验证」一致。
- **证据边界（指导校正）**：编译通过 / 关键词比例 **不等于**运行可用或移植工作量。
  本线目前只证明"能编译、能跑仓颉应用、能驱动 UI"，**没有**任何 cjgui 在鸿蒙运行的证据。

---

## 0. 三十秒结论

| 问题 | 答案 | 依据 |
| --- | --- | --- |
| 能在鸿蒙模拟器上跑仓颉应用吗 | **能，已跑通** | lab 全链路实测（含 UI 交互与状态更新） |
| cjgui 的仓颉核心能编到鸿蒙目标吗 | **能，零错误** | 404 个 `.cj` 编译通过，产出 ELF aarch64 的 `libcjgui.so` |
| cjgui 现在能在鸿蒙上显示吗 | **还不能** | 鸿蒙侧平台桥（原生实现层）尚未编写 |
| 渲染层要重写吗 | **逻辑不重写，原生 GPU 后端要重写** | 见差异指南 §4.1.2 的量化 |

## 1. 环境清单（本机实测）

| 项 | 值 |
| --- | --- |
| DevEco Studio | `/Applications/DevEco-Studio.app` = **26.0.0 Release**，SDK「HarmonyOS 26.0.0」API 26（另有旧安装 `DevEco-Studio-6.1.1-Beta1.app`，本线不用） |
| 仓颉插件 | `~/Library/Application Support/Huawei/DevEcoStudio26.0/plugins/devecostudio-cangjie-plugin-mac-arm-26.0.0.821`（341MB，内含 `harmonyos-cangjie-sdk-mac-arm.zip`） |
| 仓颉 SDK（已解压） | `~/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/cangjie`（626MB） |
| 编译器 | `Cangjie 1.2.0-beta.rc3`，宿主 `aarch64-apple-darwin`；目标模块含 `darwin_aarch64_cjnative` 与 **`linux_ohos_aarch64_cjnative`** |
| 模拟器镜像 | `~/Library/Huawei/Sdk/system-image/HarmonyOS-6.1.1-B1`（phone/tablet/pc，arm64） |
| 模拟器实例 | `~/.Huawei/Emulator/deployed`（Pura 90 / Mate X7 / MatePad Pro 13 / MateBook Pro） |
| 设备实际版本 | `emulator 6.1.0.117`，`const.ohos.apiversion = 24` |
| 平台↔API 对照（hvigor 内置） | 6.0.0→20，6.0.1→21，6.0.2→22，6.1.0→23，**6.1.1→24**，26.0.0→26 |
| DevEco CLI | `~/.local/bin/devecocli`（`@deveco/deveco-cli@1.3.0-stable`） |
| MCP（AI 会话用） | `~/.claude.json` 的 `codegenie`（`npx -y @deveco-codegenie/mcp@latest`，工具链操作 9 工具）与 `deveco`（`devecocli serve mcp`，ArkTS/C++ 代码智能 10 工具） |

## 2. 已验证能力（含复现命令与期望输出）

### 2.1 从命令行启动鸿蒙模拟器

```bash
bash labs/ohos_cangjie_smoke/scripts/start_emulator.sh
# 等价于：
#   /Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator -start "Pura 90" \
#     -instancePath "$HOME/.Huawei/Emulator/deployed" -imageRoot "$HOME/Library/Huawei/Sdk"
```

期望：约 40s 后 `hdc list targets` 输出 `127.0.0.1:5555`。
**注意**：`devecocli emulator start` 会报 `system image ... cannot be found`（它走自己的镜像注册表，
不认 GUI 装的镜像），必须绕开。

### 2.2 构建并运行仓颉 HAP（含 UI 交互）

```bash
bash labs/ohos_cangjie_smoke/scripts/build_and_run.sh
```

期望输出（关键行）：

```
BUILD SUCCESSFUL
App install path: ...entry-default-unsigned.hap msg:install bundle successfully.
start ability successfully.
A00001/CangjiePoc: MyAbilityStage onCreated.
A00000/CangjiePoc: MainAbility ctor + registerSelf done
A00000/CangjiePoc: MainAbility OnCreated.MainAbility
A00000/CangjiePoc: onWindowStageCreate begin
A00000/CangjiePoc: onWindowStageCreate loadContent returned
A00000/CangjiePoc: onForeground
UI: Text [109,1345,1212,1550] "Hello Cangjie" clickable
```

点击验证 `@State` 响应式（预期文案变化）：

```bash
devecocli ui click --device 127.0.0.1:5555 660 1447
devecocli ui layout --device 127.0.0.1:5555
# → Text ... "Hello Cangjie from emulator" clickable
```

**无需签名**：模拟器直接安装 unsigned HAP（已实测）。

### 2.3 CJGUI 仓颉核心 → ohos 交叉编译探针

```bash
bash labs/ohos_cangjie_smoke/scripts/probe_cjgui_ohos.sh
```

期望输出：

```
同步文件数: 404
build exit=0
error 行: 0 ; warning 行: 61 ; 链接错误行: 0
✅ 全部通过：CJGUI 仓颉核心可按 ohos 目标编译
```

产物：`labs/ohos_cangjie_smoke/cjgui_core_probe/build/default/outputs/default/cjgui_core_probe.har`
（6.2 MB），内含 `libs/arm64-v8a/cjbins/cjgui/libcjgui.so`
= `ELF 64-bit LSB shared object, ARM aarch64`。

说明：探针清单相对 `runtime/cjgui/cjpm.toml` 只做三件事——去掉 darwin 链接框架
（AppKit/Metal/MetalKit/QuartzCore/lobjc）、去掉 `[ffi.c] cjgui_internal_renderer`
（Mach-O 静态库不可链接）、补 ohos 目标编译选项与 `bin-dependencies`。**源码未改**。

### 2.4 工具链事实（交叉编译可行性）

mac 版 cjc 执行 `--target aarch64-linux-ohos` 时会去找 `modules/linux_ohos_aarch64_cjnative`；
装入仓颉 SDK 后该目录存在，因此可在 Mac 上产出鸿蒙 ELF 产物（本次已多次产出）。

## 3. 坑与解法（全部踩过并验证）

| # | 坑 | 现象 | 解法 |
| --- | --- | --- | --- |
| 1 | **仓颉包名约定** | `E C01332/UIAbility: null cjAbilityObj`、窗口空白、无仓颉日志 | 包名必须是 **`ohos_app_cangjie_<模块名>`**，`module.json5` 的 `srcEntry` 与之一致 |
| 2 | 日志域 | 看不到自己的 `Hilog` 输出，误判"代码没跑" | 调试期用 `Hilog.info(0, ...)`（domain 0） |
| 3 | hvigor 未接仓颉管线 | 只跑 ArkTS 任务、不打包仓颉库 | `hvigor-config.json5` 加 `@ohos/cangjie-build-support` 依赖；根/模块 `hvigorfile.ts` 从该包导 `appTasks`/`hapTasks` |
| 4 | 依赖包缺目标段 | 链接报 `cannot open crti.o` / `unable to find library -lc` | 每个被依赖的 cjpm 包（含 path 依赖）都要有 `[target.aarch64-linux-ohos]`（`-B/-L/--sysroot`） |
| 5 | 模块类型 | `module.json5 file not found` | HAR/静态库模块也要 `src/main/module.json5`（`"type": "har"`） |
| 6 | cjpm 包名与源码不符 | `the package name ... is wrong` | cjpm `name` 必须等于源码根包名（cjgui 是 `cjgui`），与 hvigor 模块名可不同 |
| 7 | `cjc-version` | cjpm 报字段错误 | 写 semver（如 `1.0.0`），不是编译器版本串 |
| 8 | `@Entry` 宏 | 报 `ObservedProperty` / `observeComponentCreation` 未定义 | 保留模板完整的 `kit.ArkUI.*` 导入 |
| 9 | 无效配置字段 | hvigor schema 报错 | 仓颉模块**不要** `uiSyntax`，也**不要**页面清单 `main_pages.json` |
| 10 | API 版本错配 | 安装报 `9568297 older sdk version in the device` | `compatibleSdkVersion` 用对照表（本机设备 API 24 → `"6.1.1(24)"`） |
| 11 | `devecocli emulator start` | 报找不到镜像 | 用 `Emulator -start`（见 §2.1） |
| 12 | 构建生成物 | `*_entry.cj` 注册胶水出现在源码目录 | 属正常（`UIAbility.registerCreator(...)`），不要手改，可 gitignore |

## 4. 移植证据（回答"多难"）

见差异指南 §4.1.2，要点：

- 仓颉侧桥函数声明 **257 个**（87 个 mac 专属名词，170 个通用语义）
- mac 原生库实现 **376 个 `cjgui_*` 函数**（`cjgui_native_bridge_*` 294 个）
- renderer 仓颉文件 **294 个**：**144 个**含 Metal/darwin 词汇、**150 个**平台无关
- 已存在抽象接缝：`renderer_backend_contract` / `capability` / `adapter_selection` / `backend_adapter`
- 结论：**逻辑不重写，原生 GPU 后端 + 平台桥要重写**；257 个契约即新实现的规格说明书

## 5. 明确未做的事（避免误判为已完成）

- ❌ 未编写鸿蒙侧平台桥（无 XComponent / GLES / 输入 / 生命周期代码）
- ❌ cjgui 尚未在鸿蒙设备上运行或显示（无"第一个画面"证据）
- ❌ 未做真机验证（仅模拟器）；x86_64 ohos 目标未探
- ❌ 未做签名/上架（仓颉鸿蒙能力仍是 Experiment 受控状态）
- ❌ 未改 `runtime/cjgui` 本体（探针在 lab 内进行，源码同步后编译）

## 6. 资产位置

| 资产 | 位置 |
| --- | --- |
| 能力基线 lab（可运行） | `labs/ohos_cangjie_smoke/`（`scripts/{env,start_emulator,build_and_run,probe_cjgui_ohos}.sh`） |
| 探针模块 | `labs/ohos_cangjie_smoke/cjgui_core_probe/`（源码 gitignore，探针时同步） |
| 差异与移植分析 | `docs/plans/2026-09-18-harmonyos-cangjie-dev-differences.md` |
| 可行性说明 | `docs/plans/2026-09-18-harmonyos-deveco-cjgui-feasibility.md` |
| 桌面副本（便于查阅） | `~/Desktop/CJGUI鸿蒙可行性说明-2026-09-18.md`、`~/Desktop/CJGUI鸿蒙开发差异指南-2026-09-18.md`、`~/Desktop/仓颉鸿蒙POC工程/` |

## 7. 什么时候才需要重新验证

仅在下列情况重跑 §2 的脚本，否则直接引用本文结论：

1. DevEco / 仓颉插件 / SDK 版本升级，或切换到 Beta1 那套安装
2. 换机器或 SDK 路径变化（`scripts/env.sh` 支持环境变量覆盖）
3. 模拟器镜像或设备 API 版本变化（会影响 §3 的坑 10）
4. 要验证**新的**能力面（例如后续的 ohos 平台桥、自绘通道）
