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

## 四、差异清单（探针回填区，初始为空）

> 规则：每轮探针发现一条差异，在此追加一行；修复后在行尾标注状态。保持增量，不重写。

- （待回填：编译探针差异 / 链接差异 / 运行时行为差异）

## 五、下一步准备清单（按依赖排序）

**用户侧（唯一硬依赖）**：
1. 仓颉开发者权限报名审批（进行中）
2. DevEco 设置 → 语言和框架 → Cangjie(Experiment) 勾选下载 SDK

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
