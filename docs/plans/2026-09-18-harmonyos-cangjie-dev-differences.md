# CJGUI：macOS ↔ HarmonyOS 仓颉 GUI 开发差异指南

> **2026-09-19 指导校正（优先于下方历史结论）：** 下文记录的是当时普通 HAP/工具链探测与移植假设，不证明 CJGUI 已在鸿蒙运行。“90% 就绪”“只差 SDK”“L0/L1 可原样共享”撤回为待验证判断；关键词/FFI 文件比例不等于移植工作量。模拟器免签仅限当时已试包与环境，不推广所有权限/API；目标识别也不证明运行时、链接和沙盒已通。当前用户同意的范围是[鸿蒙薄自绘通道验证及数据交换收尾](2026-09-19-transfer-closure-harmonyos-channel-milestone.md)，允许实验窄桥，不等于全面移植。以新任务的实际编译、运行与共享状态证据回填；下方旧“待决策/唯一缺口”不控制当前任务。


日期：2026-09-18
状态：框架版（基于已验证事实 + 标注"待 SDK 验证"项；SDK 到位后逐条升级为实测）
配套：[可行性说明](./2026-09-18-harmonyos-deveco-cjgui-feasibility.md)（结论与实测数据）
读者：后续接手鸿蒙侧开发的模型/人。**本文是活文档，每轮探针结果回填。**

---

## 一、总原则：什么一样，什么不一样

CJGUI 的分层决定了差异的边界：

- **L0 仓颉核心（组件树/布局/文本/语义/事件模型）和 L1 自绘逻辑：双平台同一套代码。**
  这是"仓颉原生 GUI"的本体，写一次，两边编译。
- **L2 平台桥：完全不同。** mac 是 AppKit/Metal 窄桥；鸿蒙是 XComponent/NativeWindow 窄桥。
  两座桥互相独立、接口对齐，不做跨平台抽象轰炸。
- **L3 应用壳：完全不同。** mac 是 cjpm 工程 + ObjC launcher；鸿蒙是 hvigor 工程 + HAP。

所以"鸿蒙上开发仓颉原生 GUI 仓库"= **同一个仓颉核心仓库 + 每平台一座窄桥 + 每平台一个壳**。
不是复制一份仓库分头改，而是核心共享、桥与壳分平台目录（如 `platform/macos/`、
`platform/ohos/`，具体布局立项时定）。

## 二、差异对照表

| 维度 | macOS（现状，已验证） | HarmonyOS（形态，★=待 SDK 实测） |
| --- | --- | --- |
| 工程形态 | `cjpm.toml` + `build.cj`，output-type static | hvigor 工程 + `module.json5` + EntryAbility；仓颉模块以★静态库/HSP 形态接入 |
| 工具链 | `envsetup.sh`（cangjie-1.1.3，darwin 目标） | DevEco 内置 Cangjie SDK（ohos 目标库）；**版本必须与镜像配对** |
| 交叉编译 | 不需要（本机目标） | `cjc --target aarch64-linux-ohos`；前端已支持，缺目标库（已探针证实） |
| 入口/生命周期 | ObjC launcher + NSApp/NSWindow 生命周期 | UIAbility（onStart/onForeground/onStop）+ ★XComponent 创建/销毁回调 |
| 渲染表面 | NSView + CAMetalLayer（Metal） | XComponent 提供的 Surface + NativeWindow；GPU 后端选 ★EGL+GLES（优先）或 Vulkan |
| 输入事件 | NSEvent：鼠标/键盘/手势 | 触摸（多指）/按键/★IME 文本输入（系统输入法框架）——cjgui 文本语义需重接 |
| 主线程模型 | AppKit 主线程规则（已有 admission 逻辑） | ★ArkTS 主线程 + native 线程规则；渲染线程模型要对照 XComponent 回调线程 |
| FFI 链接 | `[ffi.c]` + `-framework ... -lobjc`（.a/.dylib） | ★`[ffi.c]` + ohos sysroot（.so），随 HAP 打包进 libs |
| 文件/权限 | mac 路径自由 | ★应用沙盒（el2 目录）+ `module.json5` 权限声明 |
| 日志 | print / 自有日志 | hilog（`devecocli log`）；崩溃看 faultlog |
| 签名/分发 | 无要求 | 真机需签名；**模拟器豁免（已实测）**；`devecocli signature generate` 可生成调试签名 |
| UI 驱动测试 | mac 窗口 AX 验收流程 | `devecocli ui layout/screenshot/click` + codegenie-mcp（已实测） |

## 三、差异识别方法论（四层探针，编译器是最高权威）

1. **词法扫描**（已完成）：grep darwin 词汇 → 三色清单。当前基线：FFI 硬耦合 13 文件
   / 5,848 行；darwin 实现面 ~102 文件；其余 ~74% 名义纯净。
2. **编译探针**（SDK 到位后第一件事）：对 `src/` 逐目录跑
   `cjc --target aarch64-linux-ohos`，**每条报错就是一条确凿差异**；按文件聚合回填
   本文第四节清单，直到全绿。这一步把"26% darwin 面"精确到语句级。
3. **链接/打包探针**：仓颉静态库接入 hvigor 工程，跑通 ohpm/hvigor 打包 HAP，
   暴露 sysroot 符号缺失、ABI、打包形态问题。
4. **运行行为探针**：模拟器冒烟（UI 驱动 + hilog 对照 mac 行为），暴露线程模型、
   生命周期时序、Surface 行为差异——这些是文档不会写、只有跑起来才知道的。

## 四、差异清单（探针回填区）

> 规则：每轮探针发现一条差异，在此追加一行；修复后在行尾标注状态。保持增量，不重写。

### 4.1 第二轮：真机运行期实测（2026-09-20，Cangjie HAP 上模拟器）

**已打通：**

```bash
# ① 模拟器可用命令行启动（绕开 devecocli 的镜像注册表）
cd /Applications/DevEco-Studio.app/Contents/tools/emulator
./Emulator -start "Pura 90" -instancePath "$HOME/.Huawei/Emulator/deployed" -imageRoot "$HOME/Library/Huawei/Sdk"
# ② 仓颉 HAP 构建（关键：hvigor 必须装载仓颉插件 + 用仓颉任务包）
#    hvigor/hvigor-config.json5:
#      "dependencies": { "@ohos/cangjie-build-support": "file:<插件>/lib/hvigor/cangjie-build-support" }
#    hvigorfile.ts（根 + 模块）:
#      import { appTasks } / { hapTasks } from '@ohos/cangjie-build-support'
# ③ 安装 + 启动：hdc install -r <hap>；aa start -a MainAbility -b <bundle>
```

实测现象：装包成功、Ability 被调到前台（`AA: abilityName MainAbility, state 2, isFocused 1`）、
**进程内仓颉运行时确实初始化**（hilog `A00008/CANGJIE-RUNTIME` 出现 GC/堆栈等启动日志），
说明 `libentry.so` 被加载、仓颉运行时可用。

**✅ 已于 2026-09-20 16:14 解决——根因是仓颉包名约定。**

经排查，`null cjAbilityObj` 的真正原因是**仓颉包名**：仓颉工程的 Cangjie 包名必须遵循
官方约定 **`ohos_app_cangjie_<模块名>`**（官方文档实例：`package ohos_app_cangjie_entry`），
`module.json5` 的 `srcEntry` 必须与之一致。之前用 `entry` 作包名时，系统侧 Cangjie UIAbility
桥按约定找不到能力类 → `null cjAbilityObj` → 窗口空白。

修正（三处同步改名）：

```cangjie
// index.cj / main_ability.cj / ability_stage.cj
package ohos_app_cangjie_entry        // 原为 package entry
```
```toml
# entry/cjpm.toml
  name = "ohos_app_cangjie_entry"
    [profile.build.combined]
      ohos_app_cangjie_entry = "dynamic"
```
```json5
// entry/src/main/module.json5
"srcEntry": "ohos_app_cangjie_entry.MyAbilityStage",
"abilities": [ { "srcEntry": "ohos_app_cangjie_entry.MainAbility", ... } ]
```

**打通后的实测证据（同一轮）：**

```
A00001/CangjiePoc: MyAbilityStage onCreated.
A00000/CangjiePoc: MainAbility ctor + registerSelf done
A00000/CangjiePoc: MainAbility OnCreated.MainAbility
A00000/CangjiePoc: START_ABILITY
A00000/CangjiePoc: onWindowStageCreate begin → loadContent returned
A00000/CangjiePoc: onForeground
null cjAbilityObj 出现次数：0
UI 树: Text [109,1345,1212,1550] "Hello Cangjie" clickable
点击后: Text [62,1242,1258,1652] "Hello Cangjie from emulator" clickable   ← @State 响应式生效
```

即：**仓颉声明式 ArkUI 应用在鸿蒙模拟器上真实运行，且可被 Mac 侧全程程序化驱动
（构建→安装→启动→UI 读取→点击→状态更新→截图）**。

**可复现基线**：已固化到 [`labs/ohos_cangjie_smoke`](../../labs/ohos_cangjie_smoke/README.md)——
`bash scripts/start_emulator.sh` 起模拟器，`bash scripts/build_and_run.sh` 一键跑完整链路；
同一 lab 目录下已复现成功（含删除构建生成胶水后自动重建）。

### 4.1.1 CJGUI 核心 ohos 交叉编译探针结果（2026-09-20）

**结论：仓颉核心可直接为 ohos 目标编译，0 error。**

做法：`labs/ohos_cangjie_smoke/scripts/probe_cjgui_ohos.sh` 把 `runtime/cjgui` 源码同步进
HAR 模块 `cjgui_core_probe`（不改动本体），用 hvigor 仓颉管线按 `aarch64-linux-ohos` 编译。
探针清单相对 `runtime/cjgui/cjpm.toml` 只做三件事：去掉 darwin 链接框架
（AppKit/Metal/MetalKit/QuartzCore/lobjc）、去掉 `[ffi.c] cjgui_internal_renderer`
（Mach-O 静态库，鸿蒙不可链接）、补 ohos 目标编译选项与 `bin-dependencies`。

| 指标 | 值 |
| --- | --- |
| 源码规模 | 404 个 `.cj`（cjgui 368 + shared_operation_core 36） |
| 编译结果 | **BUILD SUCCESSFUL，0 error**，61 warning（弃用/未用变量等） |
| 产物 | `cjgui_core_probe.har` 6.2 MB，含 `libs/arm64-v8a/cjbins/cjgui/libcjgui.so` |
| 架构 | `ELF 64-bit LSB shared object, ARM aarch64`（29 MB，含调试信息） |
| 耗时 | CompileCangjie 13.6 s |

**对"多难"的修订**：纯仓颉核心（组件树/布局/文本/语义/事件模型）**零改动即可编到 ohos**；
剩余工作量集中在被剥离的 mac 平台桥——darwin FFI 静态库与系统框架需替换为鸿蒙实现
（XComponent surface、触摸/键盘/IME 输入、生命周期、GLES 或 Vulkan 提交）。
即：**不是重写框架，而是补一座桥 + 给渲染后端加可替换实现**。

### 4.1.2 平台桥与渲染层的量化（2026-09-20，可直接引用，无需重跑）

回答"渲染层要不要重写"的关键区分——**仓颉侧逻辑不重写，原生后端要重写**：

| 项 | 数量 | 复现命令 |
| --- | --- | --- |
| 仓颉侧桥函数声明（`foreign func`） | **257 个**（87 个名字含 appkit/cametal/nsview/objc；170 个为通用语义，如 command_buffer_create/destroy） | `grep -rhoE 'foreign func [a-zA-Z_0-9]+' runtime/cjgui/src/*.cj \| awk '{print $3}' \| sort -u` |
| mac 原生库实现的 `cjgui_*` 函数 | **376 个**（其中 `cjgui_native_bridge_*` 294 个） | `llvm-objdump -t runtime/cjgui/native/lib/libcjgui_internal_renderer.a \| grep -oE '_cjgui_[a-zA-Z_0-9]+' \| sort -u \| wc -l` |
| mac 原生源码体量 | `cjgui_internal_renderer.m` 780KB、`cjgui_native_bridge.m` 205KB、`cjgui_macos_application_launcher.m` 4KB | `ls -la runtime/cjgui/native/*.m` |
| renderer 相关仓颉文件 | **294 个**：**144 个**含 Metal/darwin 词汇、**150 个**平台无关（规划/契约/准入） | 文件名关键词分类 grep |
| 已存在的抽象接缝 | `renderer_backend_contract` / `renderer_backend_capability` / `renderer_adapter_selection` / `renderer_backend_adapter`（含 backend 无关候选族与选择准入） | 文件即证据 |

**三条结论**：

> 证据边界：编译通过、文件计数与契约数量 **不等于**运行可用或移植工作量，勿据此估算工期；
> 本线目前无任何 cjgui 在鸿蒙运行的证据（见[交接文档 §0.0](./2026-09-20-harmonyos-cangjie-handoff.md)）。

1. 仓颉侧渲染逻辑（150 个平台无关文件 + 后端契约/适配器选型）**不需要重写**——已实测零错误编到 ohos。
2. **必须新写的是原生实现层**：当前 376 个 `cjgui_*` 函数全部由 darwin 的 ObjC/Metal 库实现；
   鸿蒙侧需用 XComponent Surface + EGL/GLES（或 Vulkan）+ 触摸/键盘输入 + 生命周期实现同一套契约。
3. 257 个桥函数语义 + 150 个平台无关文件的规划模型 = 鸿蒙新实现的**规格说明书**；
   可按 `command_buffer_* / render_pass_* / pipeline_*` 子集起步，逐步覆盖。

**排查中排除的原因（保留供后续复用）：**

- ✗ 缺 native 库：向 HAP 注入 30+ 依赖库（libcangjie-*/libkit.*/libohos.*）后行为不变
- ✗ `compile-option` 缺少 `--cfg="${COMPILE_CONDITION_ENTRY}"`：恢复模板原文后行为不变
- ✗ `uiSyntax` 字段：模块级与产品级都被 hvigor schema 拒绝，不是正确落点
- ✗ `main_pages.json`：Cangjie 模块不该有页面清单；空对象/空 `src` 都会触发 schema 校验失败
- ⚠️ 日志域：调试期 `Hilog.info` 用 `domain=0`（`1` 会被过滤，导致"看不到日志"的误判）

**已确认的配置事实：**

- 编译后的 `module.json`：`virtualMachine = "ark24.0.0.0"`、`compileMode = "esmodule"`
  —— 对仓颉模块也是**正常**的，不是失败征兆（`isArkModule(){return!0}` 在 hvigor 中恒真）
- 仓颉 hvigor 插件导出 `appTasks/hapTasks/harTasks/hspTasks`，并注册
  `CangjiePreBuild / CompileCangjie / MoveCangjieLibs / ProcessCangjieLibs / AfterCompileCangjie` 任务
- 构建会**自动生成注册胶水**（`entry/src/main/cangjie/*_entry.cj`）：
  `UIAbility.registerCreator("MainAbility", {=> MainAbility()})`、
  `AbilityStage.registerCreator("entry", {=> MyAbilityStage()})`
  —— "能力名/模块名 ↔ 仓颉类"的绑定由构建生成，因此包名与 `srcEntry` 必须严格一致

**下一步假设（按优先级）：**

1. 能力注册路径：`registerSelf()` + `module.json5 srcEntry` 的匹配规则（包名 vs 类名 vs 模块名）
2. 与 IDE 新建的仓颉工程做**逐文件 diff**（最快、最权威；IDE 生成的配置即 ground truth）
3. 运行期：检查 `/proc/<pid>/maps`（shell 无权限）、或用 `cj_ui_ability` 桥的符号要求反推

### 4.2 首轮：SDK 落地形态与交叉编译（2026-09-20）


**SDK 落地形态**：仓颉能力以 DevEco 插件分发（`devecostudio-cangjie-plugin-mac-arm-26.0.0.821`，
341MB），插件内含 `harmonyos-cangjie-sdk-mac-arm.zip`（192MB 压缩 / 653MB 解压）。
已解压到 `~/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/`：

```
cangjie/
  build-tools/{bin/cjc, lib, modules, runtime, third_party, tools}   # 工具链本体
     modules/darwin_aarch64_cjnative + linux_ohos_aarch64_cjnative   # 宿主 + ohos 目标模块
  api/{lib,modules,macro}/linux_ohos_aarch64_cjnative                # 鸿蒙 API 库(kit.ArkUI 等)+ohos 宏
```

**编译器版本**：`Cangjie Compiler 1.2.0-beta.rc3 (cjnative)`，宿主 Target `aarch64-apple-darwin`
（mac 上交叉编译）。**注意版本差**：本机社区工具链是 1.1.3，`runtime/cjgui/cjpm.toml` 声明
`cjc-version = "1.1.3"`，鸿蒙侧是 1.2.0-beta.rc3——移植前需实测版本兼容性。

**交叉编译已验证（静态库 + 可执行）：**

```bash
export CANGJIE_HOME=~/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/cangjie/build-tools
OH=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native

# ① 静态库（对应 cjgui 现有 output-type = "static"）
$CANGJIE_HOME/bin/cjc hello.cj --target aarch64-linux-ohos --output-type=staticlib -o hello.a
#  → 成功：current ar archive

# ② 可执行（按官方 compile-option 补 sysroot 与 CRT 搜索路径）
$CANGJIE_HOME/bin/cjc hello.cj --target aarch64-linux-ohos -o hello_ohos \
  -B "$CANGJIE_HOME/third_party/llvm/bin" \
  -B "$OH/sysroot/usr/lib/aarch64-linux-ohos" \
  -L "$OH/sysroot/usr/lib/aarch64-linux-ohos" \
  -L "$OH/llvm/lib/aarch64-linux-ohos" --sysroot "$OH/sysroot"
#  → 成功：ELF 64-bit LSB pie executable, ARM aarch64, interpreter /lib/ld-musl-aarch64.so.1
```

**差异点（已识别）：**

| # | 差异 | 状态 |
| --- | --- | --- |
| D1 | 独立可执行链接须显式带 `-B <sysroot>/usr/lib/aarch64-linux-ohos` 与 `--sysroot`，否则 CRT（Scrt1.o/crti.o/crtn.o）与 libc/libm 找不到 | ✅ 解法已验证 |
| D2 | 鸿蒙用 musl（`/lib/ld-musl-aarch64.so.1`），与 mac dyld 体系完全不同 | ✅ 已确认 |
| D3 | 仓颉 HAP 模块的 `cjpm.toml` 须 `output-type = "dynamic"`、`src-dir = "./src/main/cangjie"`，并有 `[target.aarch64-linux-ohos] compile-option` 段 | ✅ 模板已确认 |
| D4 | 构建期依赖 `DEVECO_CANGJIE_HOME`（SDK 根）与 `DEVECO_OH_NATIVE_HOME`（native SDK 根）；hvigor 另用 `CANGJIE_HOME`/`AARCH64_LIBS` | ✅ 源码/模板已确认 |
| D5 | 仓颉模块构建配置走 `module-build-profile.json5` 的 `buildOption.cangjieOptions.path = ./cjpm.toml` | ✅ 模板已确认 |
| D6 | 鸿蒙提供**仓颉版 ArkUI**（插件内 `docs/application-dev/reference/arkui-cj/`，含 Canvas/Path2D/Matrix2D 等 2D 图形 API）——声明式 UI 不必全靠自绘 | 待评估（对 cjgui 影响大） |
| D7 | 设备端运行待验：模拟器在 DevEco 重启后未启动；裸二进制需推送 Cangjie runtime `.so` 或走 HAP 打包 | ⏳ 待模拟器启动 |

## 五、下一步准备清单（按依赖排序）

**用户侧（唯一硬依赖）**：
1. ✅ 仓颉开发者权限报名审批（2026-09-20 已通过）
2. ✅ DevEco 重启后自动安装仓颉插件，SDK 随插件分发；已解压到
   `~/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/`（IDE 自身的管理路径尚未触发解压）

**模型侧（SDK 到位当天按序执行）**：
1. 全量编译探针，回填第四节差异清单
2. 集成形态选型（三选一，按风险从小到大）：
   a. **能力层**：仓颉静态库被 ArkTS 壳调用（只验工具链，不动 UI）
   b. **纯仓颉 HAP**：仓颉模块独立成应用（验仓颉运行时完整度）
   c. **XComponent 自绘最小窗**：cjgui 渲染核心直绘 Surface（ohos 桥的第一块砖）
3. 建 `labs/ohos_gui_smoke` 骨架（对齐现有 labs 惯例），把生产线脚本固化

## 六、文档地图（去哪查）

| 源 | 内容 | 状态 |
| --- | --- | --- |
| 本地 `devecocli docs search/read` | HarmonyOS 文档（ArkTS/NA 向） | **XComponent 渲染原理/排障专题已有**（cjgui 桥直接相关）；仓颉章节无，随 SDK 补 |
| codegenie-mcp `harmonyos_knowledge_search` | 云端 API 参考/指南/FAQ | 工具可用；本次查询返回空，疑似需 auth 或参数调整，待调 |
| 华为开发者联盟网站 | 仓颉语言/鸿蒙集成官方文档 | 本会话 DNS 受限打不开，需用户浏览器查阅/下载离线包 |
| `cangjie-coding` skill | 仓颉语言知识库（语言特性/标准库） | 可用；鸿蒙集成部分以其覆盖为准 |
| 本文 + 可行性说明 | CJGUI 双平台开发的事实基线 | 活文档，持续回填 |
| [能力基线与证据（交接文档）](./2026-09-20-harmonyos-cangjie-handoff.md) | **接手必读**：环境清单、复现命令与期望输出、坑表、未做事项、何时才需重验 | 2026-09-20 建立 |
| [`labs/ohos_cangjie_smoke`](../../labs/ohos_cangjie_smoke/README.md) | 可运行基线（脚本 + 探针模块），一条命令复现 | 2026-09-20 建立 |
