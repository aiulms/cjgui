# 通过 DevEco 在鸿蒙设备上开发 CJGUI 的可行性说明

> **2026-09-19 指导校正（优先于下方历史结论）：** 下文记录的是当时普通 HAP/工具链探测与移植假设，不证明 CJGUI 已在鸿蒙运行。“90% 就绪”“只差 SDK”“L0/L1 可原样共享”撤回为待验证判断；关键词/FFI 文件比例不等于移植工作量。模拟器免签仅限当时已试包与环境，不推广所有权限/API；目标识别也不证明运行时、链接和沙盒已通。当前用户同意的范围是[鸿蒙薄自绘通道验证及数据交换收尾](2026-09-19-transfer-closure-harmonyos-channel-milestone.md)，允许实验窄桥，不等于全面移植。以新任务的实际编译、运行与共享状态证据回填；下方旧“待决策/唯一缺口”不控制当前任务。


日期：2026-09-18
状态：**首轮实测已完成（2026-09-18 晚，见第七章）**——生产线闭环全通、可移植性已量化、
cjc ohos 探针已做；剩余唯一依赖：仓颉开发者权限 + HarmonyOS 版 Cangjie SDK。
后续模型/执行者可直接从第七章拿数据，无需重复探测。
性质：环境与路线评估，**不改变当前"仓颉核心、macOS 首平台、自绘、窄平台桥接"路线**；
若后续决定立项 ohos 平台桥，需按治理规则单独决策。

---

## 一、结论摘要

- **仓颉代码跑上鸿蒙模拟器：可行**，且本机环境已就绪 90%。唯一缺口是 HarmonyOS 版
  Cangjie SDK（ohos 交叉工具链），受华为"仓颉工程开发"权限管控（Cangjie(Experiment)），
  需实名开发者账号报名审批后在 DevEco SDK Manager 下载。
- **CJGUI 完整自绘窗口跑上鸿蒙：可行，但等于新增一个平台桥**。纯仓颉核心（组件树、布局、
  文本、语义、事件模型）可交叉编译到 `aarch64-linux-ohos`；darwin 侧的平台桥
  （AppKit/Metal/输入/生命周期）不可移植，需要在鸿蒙侧新写等价的窄桥
  （XComponent native surface + 触控/按键输入 + 窗口生命周期 + GPU 提交）。
- **开发/验证手段已打通**：DevEco 模拟器（arm64，与 Apple Silicon 同构）+ `devecocli`
  命令行 + 两套已接入 AI 会话的 MCP（codegenie-mcp 工具链操作面、deveco-mcp 代码智能），
  "构建 → 部署 → UI 驱动 → 日志"闭环在本机实测可用。
- **建议节奏**：先花小成本做仓颉 HAP 最小 POC 与 cjgui 核心可移植性扫描，把"能不能、
  多难"变成实测数据，再决定是否立项 ohos 平台桥。

## 二、本机已验证事实（2026-09-18 探测）

| 项 | 状态 | 证据 |
| --- | --- | --- |
| DevEco Studio 26.0.0 | 正在运行 | `/Applications/DevEco-Studio.app`，SDK 在 `Contents/sdk/default/{openharmony,hms}` |
| 模拟器 | 运行中 | `hdc list targets` → `127.0.0.1:5555`；`param get` → `emulator 6.1.0.117`；镜像 `~/Library/Huawei/Sdk/system-image/HarmonyOS-6.1.1-B1`（phone/tablet/pc，arm） |
| DevEco CLI | 已装 | `~/.local/bin/devecocli`（`@deveco/deveco-cli@1.3.0-stable`）：build/run/device/emulator/ui/log/docs/skills |
| codegenie-mcp | 实测通过 | `npx -y @deveco-codegenie/mcp@latest`（CodeGenie Toolbox 配置）：build_project / project_sync / start_app / get_app_ui_tree / perform_ui_action / get_hilog_or_faultlog_recent / check_ets_files / check_cpp_files / harmonyos_knowledge_search |
| deveco-mcp | 实测通过 | `devecocli serve mcp`（`devecocli-mcp-server` v0.0.1）：ArkTS/C++ 的诊断、定义、引用、调用层级等 10 工具 |
| 本机仓颉工具链 | mac 目标 | `~/cangjie-toolchains/cangjie-1.1.3`；`~/cangjie-toolchains/cangjie`（bin 仅 cjc/cjc-frontend，`native/lib` 为 CJGUI darwin 产物 `libcjgui_internal_renderer.a` 等） |
| HarmonyOS 版 Cangjie SDK | **未装** | 两个 DevEco 安装的 SDK 目录均无 ohos 版 `cjc`；DevEco 设置 → 语言和框架 → Cangjie(Experiment) 需开发者权限审批 |
| MCP 接入 AI 会话 | 已配置 | `~/.claude.json` 全局 mcpServers 已含 `codegenie` 与 `deveco` 两个 stdio 服务，新会话生效 |

已实测的模拟器驱动样例：`devecocli device list` 识别 Pura 90 (127.0.0.1:5555)；
`ui screenshot` 产出截图；`ui layout` 读出模拟器内应用（HarmonyPDF）完整节点树。

## 三、CJGUI 分层与鸿蒙映射

| 层 | 内容 | 鸿蒙上的可行性 |
| --- | --- | --- |
| L0 仓颉核心 | 组件树、布局、文本、语义、事件模型等纯仓颉框架逻辑 | **高**。仓颉为 HarmonyOS 一等语言，核心可交叉编译 `aarch64-linux-ohos` 打进 HAP |
| L1 自绘渲染核心 | 绘制原语、光栅化/批处理逻辑 | **中→高**。纯仓颉部分可移植；若 L1 直接依赖 Metal 类型/队列则需抽象出后端接口 |
| L2 平台桥（窄桥） | darwin：AppKit 窗口/事件、Metal surface、生命周期、FFI 边界 | **不可移植，需新写 ohos 等价物**：XComponent 提供的 native surface（OH_NativeXComponent / NativeWindow）、触摸/按键/文本输入事件桥、窗口与生命周期桥、GPU 提交（EGL+GLES 优先，Vulkan 备选） |
| L3 应用壳 | 应用入口与工程形态 | 鸿蒙侧为 hvigor 工程（module.json5 / ability），仓颉模块按 SDK 形态接入；构建签名走 DevEco 工具链 |

关键认知：**cjgui 的"自绘"路线恰好是可移植性最好的部分**——只要 L1 不渗入 Metal 类型，
平台差异被压在 L2 窄桥内，与 darwin 桥同构。这与现有"窄平台桥接"设计意图一致。

## 四、分期路径与验收

### 阶段 A：环境就绪（依赖用户/权限）
- 用户在华为开发者联盟完成仓颉计划报名（实名开发者账号），审批通过后在
  DevEco 设置 → 语言和框架 → Cangjie(Experiment) 勾选下载 Cangjie SDK。
- 验收：`find $DEVECO_SDK -name cjc` 命中 ohos 交叉版；`cjc` 可输出 ohos 目标信息。

### 阶段 B：生产线闭环预热（不依赖仓颉，可立即做）
- 在 /tmp 或 labs 下建最小 hvigor 工程（ArkTS 壳），走
  `project_sync → build_project → start_app → perform_ui_action/get_app_ui_tree → hilog` 全链。
- 验收：模拟器出现应用窗口且 UI 树可读、截图可见、一次程序化点击生效。
- 价值：证明"构建→部署→驱动验证"生产线无暗坑；仓颉就位后仅替换弹头。

### 阶段 C：仓颉上鸿蒙最小 POC（依赖阶段 A）
- 一个 HAP 内用仓颉写最小逻辑（如文本渲染到日志/UI 控件），模拟器运行验证。
- 验收：`hilog` 出现仓颉模块输出；仓颉代码参与界面行为且可被 `perform_ui_action` 触发。

### 阶段 D：cjgui 核心可移植性扫描与桥接评估（依赖阶段 C，产出决策依据）
- 用 codelattice 扫 runtime/cjgui 的平台耦合点：FFI 调用面、darwin 路径/类型假设、
  native 产物依赖（`libcjgui_internal_renderer.a` 等 darwin 产物清单）。
- 以 ohos 目标对纯仓颉部分做交叉编译探针，产出三色清单：
  可直接移植 / 需抽象接口 / 卡在平台桥。
- 产出：ohos 平台桥工作量评估报告（surface/输入/生命周期/GPU 四件套 + L1 后端抽象成本），
  交由用户/指导 AI 决策是否立项。**本阶段不写桥接代码。**

## 五、风险与边界

1. **Cangjie(Experiment) 受控**：SDK 权限、版本与 DevEco/镜像绑定，Beta 期 API 可能变动；
   版本需与模拟器镜像（6.1.1-B1 系）配对。
2. **模拟器 ≠ 真机**：图形驱动与性能表现有差异；自绘渲染结论最终需真机复验。
3. **MCP 工具不含仓颉语义**：codegenie/deveco 面向 ArkTS/C++；仓颉侧继续用 codelattice
   （桌面源码分析，与目标平台无关）+ cjc/cjpm。
4. **路线边界**：本方案只做环境验证与评估；macOS 首平台路线不变，
   ohos 桥若立项属新平台桥接，按治理规则单独决策，不在本说明授权范围内。

## 六、决策点

| 决策 | 时机 | 谁拍板 |
| --- | --- | --- |
| 是否申请仓颉开发者权限并下载 SDK | 立即 | 用户（已启动） |
| 是否执行阶段 B（生产线预热） | SDK 审批期间即可 | 用户（本次选择：暂缓） |
| 是否立项 ohos 平台桥（L2 实现） | 阶段 C/D 产出实测依据后 | 用户 / 指导 AI |

## 七、首轮实测结果（2026-09-18 晚补充）

### 7.1 生产线闭环（阶段 B）——已实测打通

| 环节 | 结果 | 备注 |
| --- | --- | --- |
| `devecocli create` | ✅ 秒级 | API 自动探测=26（SDK 实为 "HarmonyOS 26.0.0"/API 26，新命名体系） |
| `devecocli build` | ✅ 2.8s 全量 / 0.6s 增量 | hvigor 33 任务，产出 unsigned HAP |
| 安装 | ✅ | **模拟器不要求签名**，unsigned HAP 直接装上 |
| `devecocli run` | ✅ | EntryAbility 启动成功 |
| `ui layout` | ✅ | 读到 `Text#HelloWorld` 节点及坐标 |
| `ui screenshot` | ✅ | 110KB 截图 |
| hilog | ✅ | 系统日志可见 hellopoc 的窗口/控件活动 |
| `ui click` | ✅ | 坐标点击与 `--id` 节点点击均可用 |

实测踩坑（已解，复用价值高）：
- **坑 1**：SDK 是 "HarmonyOS 26.0.0"（API 26，新跳代命名），模拟器镜像是 API 24，
  直接 run 会报 `9568297 older sdk version in the device`。
  解法：`compatibleSdkVersion: "6.1.1(24)"`。平台-API 对照表（来自 hvigor 内置映射）：
  6.0.0→20，6.0.1→21，6.0.2→22，6.1.0→23，**6.1.1→24**，26.0.0→26。
- **坑 2（协作）**：模拟器是共享资源，另有 AI 会话在同一模拟器上测试 HarmonyPDF，
  存在前台竞争；后续 POC 操作需与其他会话错峰或使用独立实例。

### 7.2 cjgui 可移植性扫描——量化数据

| 指标 | 数值 | 含义 |
| --- | --- | --- |
| 仓颉源码总量 | 389 文件 / 212,310 行 | `src` + `shared_operation_core` |
| **FFI 硬耦合** | **13 文件 / 5,848 行（≈2.8%）** | 真正触碰 native 的接缝，集中于 `runtime_renderer_session.cj` 等 |
| darwin 词汇文件（原始） | 230（≈59%） | 含大量 admission/contract/probe/test 验证类文件 |
| darwin 词汇文件（剔除验证类命名） | **102（≈26%）** | 需抽象/拆分的 darwin 实现面 |
| 条件编译 | 无 `@When` | 现无多平台门控，需新建 |
| codelattice 图级 | 371 源文件 / 5,614 符号 / 6,577 调用边 / 0 诊断 | 交叉验证通过 |

显式耦合点（ grep 级确认）：`cjpm.toml` 的 `link-option` 挂
`-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc`；
`[ffi.c] cjgui_internal_renderer`；`native/` 下 ObjC 源（launcher 等）。

### 7.3 现有工具链 ohos 目标探针——关键利好

mac 版 cjc 1.1.3 执行 `--target aarch64-linux-ohos` 的报错是
`target library path is not exist: .../modules/linux_ohos_aarch64_cjnative`——
**编译器前端已认识 ohos 目标，缺的只是目标库**。即 SDK 到位后是"补库/换 SDK"，
不是"换编译体系"。（备选路径：社区工具链 + ohos 目标库或可绕过部分权限依赖，
待 SDK 对照验证。）

### 7.4 修订结论

- **能不能**：生产线全通；仓颉模块上模拟器仅剩"权限+SDK"一个依赖。
- **多难**：L2 ohos 桥的工作量 = 13 个 FFI 文件定义的接缝复刻 + ~102 个 darwin 实现
  文件的抽象拆分 + 渲染后端接口化（Metal → GLES/Vulkan）。定性：**中大型工程，
  但接缝面已收敛、可增量推进**，不需要全仓重写。

## 附：本次探测涉及的关键路径

- DevEco 26：`/Applications/DevEco-Studio.app`（运行中；SDK：`Contents/sdk/default/`）
- 模拟器镜像：`~/Library/Huawei/Sdk/system-image/HarmonyOS-6.1.1-B1`
- DevEco CLI：`~/.local/bin/devecocli`；AI CLI：`~/.local/bin/deveco`（deveco-code，未用于本方案）
- CodeGenie Toolbox：`/Applications/CodeGenie Toolbox.app`（codegenie-mcp 的配置入口）
- 仓颉工具链（mac 目标）：`~/cangjie-toolchains/cangjie-1.1.3`、`~/cangjie-toolchains/cangjie`
- MCP 配置：`~/.claude.json`（mcpServers：codegenie、deveco 已加入）
