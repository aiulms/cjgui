# CJGUI 设计意图与资产导航

更新：2026-09-19。回答为什么做、已有东西在哪里、接续时要辨别什么。当前阶段和运行证据仍只在 [ACTIVE_DIRECTION.md](../../runtime/cjgui/ACTIVE_DIRECTION.md) 维护。

## 怎样使用

指导 AI 规划大阶段或恢复上下文时，先看下表，再读相关源码与一两份设计原文，把取舍带入阶段提示词。执行 AI 按提示词读取相关行，无需通读历史。
以下是本次源码抽查的资产分类，不是全仓完成清单：真实实现、实验值模型、待接通设计和退役文件必须区分。文件名、旧报告或图索引命中不构成可运行证明。
只在设计取舍、重要资产入口或长期问题发生变化时维护本页；不复制每轮测试、阶段尾号或审批出口。
本页只导航资产，不另维护架构规则。目标、架构、验收、当前状态的职责分工见[文档归属](../README.md#各类信息只在一处维护)。

2026-09-26 的跨阶段缺口与分工见[三线能力推进表](2026-09-26-framework-capability-roadmap.md)：编辑器以产品补框架，鸿蒙完成平台后端，第三线补通用视觉、动效与可用性。该表保留已有资产与待验边界，实际开工对象和当前包仍见 ACTIVE。

## 框架主线与已有资产

| 主线与原始目的 | 资产入口与抽查结果 | 接续时应回答什么 |
| --- | --- | --- |
| 仓颉核心、自绘、GPU 加速、轻量和可解释；服务不同桌面应用 | [原始方向](../archive/2026-09-11-direction-governance/docs--core--GUI_PROJECT_DIRECTION.before.md)、[当前方向](../core/GUI_PROJECT_DIRECTION.md)。GPUI/WGPUI 的骨架思想是参考；不是绑定路线 | 阶段是否增加通用框架能力？临时平台实现如何回到框架组织？当前没实现不等于放弃目标 |
| 复用传统 GUI 框架的避坑经验，防止重建相同技术债 | [框架避坑原文](../research/gui-framework-pitfalls-intelligence.md)覆盖事件重入/关闭、盲目重绘、布局状态归属、复杂文字/IME/无障碍、平台抽象、API 固化及 AI 语义成本；[运行架构研究](../research/ai-native-gui-runtime-architecture-intake.md)补充内容变更与局部视觉更新分工。原文工程风险继续使用，历史禁止实施语句不恢复 | 相关风险是否已在当前源码/运行路径处理，还是只有设计或注释？每次重大接续按需带入最相关教训和验证，不把旧资料仅作存档或逐轮全篇必读 |
| 从组件结构到布局、场景和绘制命令，最终驱动显示 | [可组合布局与场景](../../runtime/cjgui/src/composable_ui.cj)、[通用窗口提交](../../runtime/cjgui/src/composable_ui_window.cj) 是当前主链；[native renderer](../../runtime/cjgui/native/cjgui_internal_renderer.m) 负责 Metal 场景合成，包含形状、图片与文字资源，AppKit 提供窗口与系统文字服务。实际支持边界见[runtime 文档](../../runtime/cjgui/README.md)；[旧 Scene 输入](../../runtime/cjgui/src/runtime_scene_renderer_input.cj) 仍是内部值契约 | 测量、样式、裁剪、提交和显示进度是否真正对应？旧契约可供对照，不能把清屏或矩形样点当完整渲染器，也不能把早期摘要当当前能力上限 |
| 开发者自由组合组件、布局和样式，复用状态与动作 | [可组合组件](../../runtime/cjgui/src/composable_ui.cj)、[规则集消费者](../../runtime/cjgui/examples/rule_set_window_app/src/main.cj)、[通知消费者](../../runtime/cjgui/examples/notification_threshold_window_app/src/main.cj) 是新消费入口；[表单绑定契约](../../runtime/cjgui/shared_operation_core/src/shared_editing_form_contract.cj) 可复用。旧集合/表单入口是前置适配；[旧布局状态](../../runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj) 仅存字符串，[旧组件文件](../../runtime/cjgui/src/runtime_cjgui_experimental_reusable_component_contract_api.cj) 已退役 | 换字段、布局和业务动作是否仍需改 native？空/动态内容与文本是否正常？组件身份、业务字段和外部语义是否只绑定一次？ |
| 真实文字排版、可复用主题与资源，避免固定尺寸和逐控件重复配置 | [当前样式/布局](../../runtime/cjgui/src/composable_ui.cj)、[实际字体测量适配](../../runtime/cjgui/src/runtime_renderer_session.cj)已有 AppKit 测量、主题和图片初版；[native](../../runtime/cjgui/native/cjgui_internal_renderer.m)已有 Metal 纹理及路径缓存，动态失效/回收与排版一致性仍需辨别。[旧平台资源](../../runtime/cjgui/src/runtime_renderer_platform_resource.cj)、[旧资源桥接](../../runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj)只表达 value-only 边界 | 字体测量与绘制是否一致？主题、图片是否实际被多个组件消费并有加载/替换/释放路径？缓存是否有界且可失效？原生句柄不外泄的意图保留，旧无资源 stop-line 不阻止当前真实实现 |
| 人的鼠标、键盘、焦点、滚动、文本、输入法与无障碍 | [通用窗口](../../runtime/cjgui/src/composable_ui_window.cj)与 [native 输入](../../runtime/cjgui/native/cjgui_internal_renderer.m) 为新主线；[旧表单窗口](../../runtime/cjgui/src/shared_editing_form_window.cj)的草稿/选区集成可对照复用，实际验收查当前状态 | 必要系统输入服务与框架交互如何分工？焦点、选区、组合态和排队输入在刷新后是否仍对应原对象？测试工具不便不能默默决定控件架构 |
| 真实状态更新与事件执行；局部视觉反馈保持快速 | [旧 Action Router](../../runtime/cjgui/src/action_router.cj) 主要计算摘要，未执行真实动作；[当前共同操作契约](../../runtime/cjgui/shared_operation_core/src/shared_operation_contract.cj) 与领域实现提供新执行入口；[高频交互设计](../research/ai-native-gui-runtime-architecture-intake.md) 区分业务修改和局部视觉更新 | 哪条路径真正执行？新旧接口的替代关系是否清楚？焦点、悬停和重绘不应无端承担整套业务或模型往返成本 |
| 人与 AI 使用同一内容、选择和动作，并理解界面关系 | [当前共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)、[core 契约与传输](../../runtime/cjgui/shared_operation_core/)、[原语义盲点](../archive/2026-09-11-direction-governance/docs--core--AI_NATIVE_UI_SEMANTICS.before.md) 的关系绑定、显示时序和 IPC 讨论 | 字段、行、分组、动作与当前选择能否对应？业务已修改与人已看见如何区分？已授权对象操作可越过视口，旧可见性即权限的限制不恢复 |
| 共享文档与片段操作、人与外部接续 | [文档核心](../../runtime/cjgui/shared_operation_core/src/shared_text_document.cj)、[文档工作区](../../runtime/cjgui/shared_operation_core/src/shared_text_document_workspace.cj)、[文件绑定](../../runtime/cjgui/shared_operation_core/src/shared_text_document_file.cj)拥有正文/版本、原子批次、撤销与持久基线；[文档窗口](../../runtime/cjgui/examples/shared_document_window_app/)消费自绘 TextKit 适配与系统输入代理 | 鼠标位置、选区、文字排版与外部范围是否对应？组件换绑是否串输入？可见范围绘制不能等同于按范围布局；保存协调边界需明确 |
| 外部能力可选择、轻量接入；不强制 Agent 或服务器 | [公开客户端](../../runtime/cjgui/shared_operation_core/client.py)与[接入说明](../../runtime/cjgui/shared_operation_core/README.md)提供可导入 API/CLI；[备份配置消费者](../../runtime/cjgui/examples/backup_rule_config_consumer/)、[通知纯领域](../../runtime/cjgui/examples/notification_threshold_application/)、[架构研究](../research/ai-native-gui-runtime-architecture-intake.md) | 应用能否只使用 UI、按需接入外部系统？外部能否读到人的当前工作而不止已应用配置？接入代码、数据量和调用成本是否合理？ |
| 运行时生成、修改界面，与手写界面共用组件和状态；应用可按需启用 | [生成契约](../core/AI_NATIVE_UI_SEMANTICS.md#运行时生成与修改界面)、[验收标准](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md#运行时生成式界面验收)、[生成与操作研究第8节](../research/ai-native-gui-runtime-architecture-intake.md)、[旧生成 demo](../../runtime/cjgui/demo/ai_generated_ui_app.cj)。动态组件注册表与候选场景可复用；demo 仍仅是程序化内存样例 | 受限结构是否真正进入自绘窗口？生成后人能否编辑，结构更新后草稿/焦点/绑定是否正确？读取能力、结构更新与业务执行是否同源？固定界面的外部操作不能替代此项；编码可替换，生成不自授权限 |
| 正常包消费、可调试、可复现；应用需求检验复用 | [runtime 导航](../../runtime/cjgui/README.md)、[旧 demo 与 harness](../../runtime/cjgui/demo/)、[应用需求参考](../core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)、[原完整性尺](../archive/2026-09-11-direction-governance/docs--core--CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.before.md) | 用不同数据、布局和动作验证复用；纯状态 harness、窗口样例、发布各自证明什么？资源、主题、文本和性能欠项是否仍有后续位置？ |
| 工具链与上下游反馈保留原因、复现和解除条件 | [仓颉问题账本](../setup/CANGJIE_ISSUE_LEDGER.md)、[贡献候选](../setup/CANGJIE_UPSTREAM_CONTRIBUTION_RADAR.md)、[C FFI 实验](../../labs/cffi_smoke/README.md)、[native FFI 实验](../../labs/native_bridge_ffi_probe/README.md)、[语言与工具能力研究](../research/cangjie-1.1-owner-tooling-ffi-capability-intake.md) | 遇到相似问题先查记录；工具链升级时有针对性复查 workaround，不能只留下成功命令而丢失原因 |

## 层级与多选组件（2026-09-19）

[macOS 树形视图、多选与共享批量操作](2026-09-19-macos-tree-selection-milestone.md)承接固定/变高虚拟列表、stable key、焦点和公开动作，扩展可复用层级交互，不另建列表渲染器或业务数据库。既有规则 BATCH_SET_ENABLED 作为人/外部批量同源消费；第二个 UI-only 应用检查框架复用。

## 生成式方向校准（2026-09-19）

此前“可选扩展”混淆了应用接入选择与框架建设目标，固定编辑器的接口验收没有覆盖原始生成意图。方向、验收及 README 已同步纠正。当前树/多选按既定范围收口，不扩为完整 IDE；下一完整阶段优先[运行时生成与共同编辑](2026-09-19-runtime-generated-ui-milestone.md)，必要旧问题随阶段承接，不等控件库齐全。这里只描述设计与优先级，不声明新能力已完成或已启动开发。

[共同信息只定义一次](../core/AI_NATIVE_UI_SEMANTICS.md#共同信息只定义一次)是接入原则：共享字段/动作及规则来源，框架派生手写绑定、外部查询和生成式接入；实时条件与草稿仍归原 owner，布局和呈现可变。[接入成本验收](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md#共同定义的接入成本验收)用新增字段、365→730规则变更和失败路径检验，避免省掉截图后又增加三套 schema 维护。

## 鸿蒙实验通道（2026-09-19）

9 月 19 日的暂停已由用户后续恢复指令取代。当前入口为[鸿蒙后端：基础链收口与系统文字接入](2026-09-25-harmonyos-backend-first-chain-prompt.md)，实际状态只见 ACTIVE。沿仓颉核心 + ArkTS 薄壳 + XComponent + 原生绘制后端推进；必要返工与基础文字输入并行，按具体依赖安排，原实验用于复用与对照。

[数据交换收尾与鸿蒙自绘通道任务](2026-09-19-transfer-closure-harmonyos-channel-milestone.md)承接第二平台验证：Mac 开发、模拟器运行，验证仓颉核心的真实复用、自绘 surface、输入与外部操作同一 owner。复用现有稳定身份、布局/命中与动作；窄平台桥留在实验范围，macOS 主线不迁移。旧鸿蒙报告的扫描比例和 SDK 假设不是可移植性证明；本轮允许实验桥，不意味着公共跨平台 API 已定型。

## 问题反馈如何接回主线

- 工具链、SDK、链接、FFI 或长期 workaround：查并更新仓颉问题账本，保留现象、复现、受影响路径、当前归因和移除条件。有证据再判断上游缺陷。
- 样例/应用暴露的框架缺陷：在当前阶段说明或测试记录里连到失败场景、负责模块和回归入口；跨阶段仍未解决的事项由当前状态带到下一任务。不另建一套下游账本。
- 可独立贡献的样例、文档或工具：重要交付时按需登记到贡献候选。它不阻塞主线，不自动创建副任务或对外发 issue。
- 普通实现无需每轮填写“没有上游问题”。旧账本中的逐轮 closure 和固定复查节奏不增加当前流程；升级工具链或重遇相关问题时再复查相关条目。

例如：账本的 CJ-20260425-001 保留 SDK 链接复现、上游提交记录及移除条件；2026-09-12 抽查[规则集运行脚本](../../runtime/cjgui/examples/rule_set_window_app/run.sh)仍默认选择 MacOSX15.4.sdk。本次未重跑原始复现或查询远端 issue 最新状态，不能据此判断上游现已修复或仍未修复。

## 已被新共识取代的历史约束

旧逐符号审批、stage145–892 审计链、语义与基础输入一律后置、可见性等同权限、固定编码偏好不再控制新任务。
这些旧限制的退役不意味着组件、布局、资源、输入、GPU、性能、语义关系或反馈机制同时退役。
[原设计意图索引](../archive/2026-09-11-direction-governance/docs--plans--DESIGN_INTENT_INDEX.before.md) 用于需要精确历史证据时进一步定位；其中的 next opening 和暂停语句不直接续接。
