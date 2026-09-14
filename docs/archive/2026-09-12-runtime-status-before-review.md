# 当前状态历史快照：可组合主链交付后、指导复核前

保存：2026-09-12。此页保留执行报告到达时的原始状态陈述，可能混有不同阶段的口径；它不是当前任务或授权入口。当前事实与待办只读 [ACTIVE_DIRECTION.md](../../runtime/cjgui/ACTIVE_DIRECTION.md)。原文中的相对链接已按存放位置换算，正文未改。

---

# CJGUI 当前方向与实施状态

更新：2026-09-12。本文件是唯一当前状态入口。

## 当前阶段：可组合 UI 与自绘渲染主链

状态：主链实现、两个正常窗口、核心/原生探针和桌面主要交互已完成；执行与未验
边界见[可组合 UI 与自绘渲染主链](../plans/2026-09-12-composable-ui-rendering-milestone.md#交付区)。

本阶段以已有的规则集编辑和通知阈值领域为两个普通消费者：开发者在仓颉中组合组件、布局、样式、绑定与动作，框架据此生成同一份场景、命中/焦点目标和辅助功能关系；窄 native bridge 只消费通用绘制与输入投影。现有 AppKit 自绘与 Metal 基础是前置资产，而非阶段完成证据。本轮已收口真实场景矩形/裁剪重绘、布局驱动的输入/无障碍、两个不同窗口入口及双实例保存租约协调；Metal readback、真实键鼠/坐标命中、AX 树与独立 Agent 分别留有当前证据。CUA 对自绘输入框的中文粘贴仍在“等待应用读取剪贴板”超时，不能把这一工具受限路径写成中文粘贴或 IME 组合验收。

此前“首个可用开发预览”的实现与测试作为本阶段回归基线保留，不能将其局部探针或 CUA 对自绘 accessibility frame 的限制表述为已完成 GUI 验收。

## 当前共识

CJGUI 提供人和外部智能系统共同理解、操作应用的框架能力。
应用开发者决定产品、界面、交流方式；外部系统可以是 Agent、模型平台、脚本或其他应用。
不强制聊天窗，不内置 Agent 运行时，不固定 S 表达式或其他编码。
同一应用内容、当前选择与实际动作同时服务人和外部调用；有效授权内允许批量操作屏幕外对象。

完整方向见 [项目方向](../core/GUI_PROJECT_DIRECTION.md)，按需读 [共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)。

## 当前事实

下表的“本轮实测”是当前工作树的结果；它不等同于稳定 API、发布状态，也不覆盖其他未提交工作。

| 资产 | 当前证据与限制 |
| --- | --- |
| native/cjgui_internal_renderer.h / .m | R1 的真实 AppKit/Metal 实现仍是 internal/unstable C ABI：`presentClear` 提交 Metal 基础清屏，集合/表单主画面由 `CJGuiInternalSharedEditingFormOverlay.drawRect` 用 AppKit 文字和路径绘制。它是“AppKit 手绘早期界面 + Metal 基础”，不是已完成的通用仓颉/GPU 自绘渲染引擎；状态仍由仓颉领域拥有 |
| shared editable form native bridge | 可见字段、按钮和行仍由 overlay 自绘、命中并排入 FIFO；仅保留一个不可见 `NSTextView` 作为 IME、剪贴板、删除和 UTF-16 选区服务，及自绘 accessibility action 语义。它不保存应用内容；仓颉领域回推草稿、错误、焦点和选区。当前 CUA 无法取得这些自绘元素的可点击 frame，故不把其便利性或失败绕过计为 GUI 验收 |
| src/runtime_renderer_session.cj | internal 仓颉封装；本轮扩充共同操作投影的窄 FFI，不暴露原生对象 |
| probe/runtime_renderer_clear_window_probe.cj | 本轮复跑：create → 两帧（首帧 readback）→ bounded pump → close/destroy，occupied count 回到 0 |
| native/scripts/verify_internal_renderer_clear_window.sh | 本轮通过；日志确认 Metal clear readback、两帧提交和关闭释放，以及 6 个自绘共同操作 accessibility action 均为 enabled |
| shared_operation_core/ | 本轮新增普通 static core 包：不链接 renderer/AppKit/Metal；它公开资源/上下文/动作/typed 参数/目标/结果契约及通用 v2 descriptor、分片 frame 和 Unix socket transport。transport 不包含列表或备份业务分支，调用开发者领域的外部入口 |
| shared_operation_core/src/shared_editing_form_contract.cj | 本轮新增纯仓颉表单字段/绑定/草稿投影契约；备份规则字段与独立“通知阈值”字段定义使用同一绑定。core 无 AppKit/Metal/FFI 或备份字段分支 |
| examples/backup_rule_application | 本轮抽出 GUI 与无窗口消费者共用的 `CjguiBackupRuleEditingDomain`。它以一把业务锁拥有已应用配置、原始草稿、草稿基线、配置/草稿/字段版本、焦点、选区和校验；人类入口只是构造调用并进入同一 dispatch，不绕过旧草稿检查 |
| examples/backup_rule_form_window_app | 本轮新增正常签名的 `CJGUIBackupRuleForm.app`；`zsh run.sh` 可重建、签名、启动、输出一次 descriptor 并在窗口关闭后退出。它只更新运行中配置，不声称保存备份文件或数据库 |
| shared_operation_core/src/shared_operation_list.cj | 原 101 条列表现为通用契约的一种领域消费者。人类和外部入口、以及旧的 select/toggle/set-marked 便捷 API，均汇入同一个 `executeUnlocked` 业务锁 |
| examples/shared_operation_window_app | 101 条窗口样例已直接依赖 core，正常 `run.sh` 重新构建 bundle 后本轮实机回归：人类 GUI 勾选 1000 得 v1；外部 v1 写屏外 1077 得 v2；滚动到 1077 后原生 checkbox 为 on；人类改回 off 得 v3；旧 v1 外部写返回冲突且读回仍 off。原生关闭后本实例 descriptor/socket 与进程均不存在 |
| 外部共同操作 | 本轮 core 单测、两个无窗口独立进程验收和迁移后 GUI 实机回归通过：v2 `GET_CONTEXT`/动态 `INVOKE`、UTF-8 frame、目标 scope、能力、类型参数、业务拒绝、版本冲突、读回和关闭清理均有当前代码证据。该证据不等同于发布或第三方模型提供方接入 |
| 无窗口消费者 | 列表第二消费者与不同领域的备份规则消费者均作为只依赖 core 的普通包构建并经实际 AF_UNIX 双进程验收；备份规则的 `SET_RULE_LABEL` 自定义字段/动作未改 core 或公开客户端 |
| 窗口内人类/辅助功能输入 | 迁移后本轮经真实 CUA 输入完成勾选、连续滚动至屏外 ID 1077、观察外部修改投影、再由人类修改及旧写冲突；不使用上一阶段 GUI 证据替代本轮验收 |
| 独立 Agent | 本轮 `gpt-5.6-luna` 只获得一次性 descriptor、`shared_operation_core/client.py` 和自然语言目标；它从实际描述发现 `backup_rule` ID `4201`、`APPLY_BACKUP_RULE` 及参数，以 v1 把保留期设为 21、排除类型设为 `logs`，读回 v2/`APPLIED true`/未变标签。命令轨迹为 `describe → get → invoke → get`，进程随后正常清理 descriptor。上一阶段 v1 Luna 记录仍只是历史 |
| 本阶段独立 Agent | 本轮独立 Agent 只持有真实表单 descriptor、公开通用客户端与自然语言目标；它从描述发现 `retentionCount` 资源 `42013`、`EDIT_DRAFT_TEXT`、字段版本及 `APPLY_DRAFT`，把保留期草稿改为 21、确认旧字段 revision 返回 `field_version_conflict`、获授权后应用，并确认未授权文本写 `42012` 返回 `unauthorized_resource`。这是当前实际进程证据，不是第三方模型接入或发布 |
| demo/ 与 src/demo_support/ | 已有 10 个程序化 demo 与 typed state/harness；不能称为 10 个可点击 GUI 应用 |
| src/action_router.cj / action_handoff.cj | 当前文件主要输出路由/接收摘要，明确不执行真实 action；不能按名称当成已接通执行器 |
| 正常应用与外部共同操作 | 一个中性列表样例的文字投影、窗口点击、状态驱动画面、私有连接和独立 Agent 均由同一真相所有者贯通；这不等同于第三方模型提供方兼容性或发布 |

R1 已把 smoke 改为薄 shim，共用 runtime-owned native 实现，原记录称 verify_auto_close.sh 通过。
R1 的 internal/unstable C ABI 使用 cjgui_internal_renderer_*，已有 session 容量 2。
R1 没有稳定公共 API；本轮新增的共同操作 API 也明确为 experimental。文字、原生点击和辅助功能动作仅限本阶段中性列表样例。
本轮未写 `runtime_state.cj` 或 renderer_state。
既有 R1 未提交工作必须保留，下一执行 AI 先检查现场，不覆盖、重置或盲目重做。

当前不以 Metal 首帧、`drawRect` 外观或临时原生交互代理宣称“通用自绘渲染引擎”完成。通用 GPU、组件、布局和多平台抽象仍是既定框架主线，由指导 AI 安排后续大阶段；完整引擎不在本轮临时扩建。相反，本里程碑已授权的基本自绘命中、输入、焦点/选区与交互问题仍须在当前领域、窄平台桥接和已有窗口样例内收口，不能被这项边界文案降格为待批准。

## 当前交付：CJGUI 首个可用开发预览

状态：**里程碑接续修复与实机收官中**。此前 A–G 的初版实现、普通 bundle 构建和部分非 GUI 验收只构成起点；它们没有覆盖关闭决策、普通文件操作、草稿隔离、撤销影响范围、请求去重、并发保存、文档/实例游标隔离、独立字段消费者及完整可见交互。因此不能称 A–G 已完成，更不能称里程碑全绿。当前授权与缺口见 [可用开发预览里程碑](../plans/2026-09-12-usable-framework-preview-milestone.md#2026-09-12-复核接续桌面已可用完成本里程碑)。

- A：可见表单改为 `drawRect` 的 AppKit 手绘，`NSTextView` 仅保留为不可见的 IME/剪贴板/选区代理；原生探针确认没有可见 `NSTextField`/`NSButton`。它保留既定自绘及窄平台桥接路线，但不等同于通用 GPU 渲染器。表单事件改为容量 64 的 FIFO；同字段连续文本可合并，但不会跨焦点、应用或关闭边界。队列满会保留已接收事件并回传显式重试提示。顺序/UTF-8 探针已通过。
- B/C：已有纯仓颉 `CjguiSharedCollectionEditorDomain` 与通用列表/详情窗口的初版；列表用最多 8 行的 renderer 视口、翻页和滚轮 intent。规则集已有稳定 ID 的新增、复制、重命名、删除、选择、草稿、应用/取消、批量启用、撤销/重做，但接续复核要求修复其草稿保留、身份单调性、实际影响范围与渲染事件定位。
- D：已有 `CJGUI_RULE_SET 1` 格式、打开与保存初版；接续复核要求加入关闭决策和窗口内新建/打开/另存为，且把版本拼接临时文件改为每次保存独占的写入路径，重新验证外部冲突边界。
- E/F：已有动态 descriptor、快照和 `GET_CHANGES` 初版；接续复核要求让去重绑定完整请求指纹、具有有界文档作用域，并让变化游标明确绑定实例/文档身份，不能把切换文件或重启误报为无变化。
- G：已有 `examples/rule_set_window_app` 和直接消费规则集领域的第二进程；接续复核仍须补一个不同字段/约束的公开契约消费者，并记录当前规则集的真实 Agent 决策轨迹。

此前真实桌面仅验证：普通 bundle 启动并输出 descriptor；通过 macOS 可访问性实际点击“新增记录”后，窗口投影读回 `新规则 1`、启用/保留/排除字段；原生关闭后进程 `exit 0`、renderer destroy 和 descriptor 清理有日志。这不是本次收官证据。当前普通 bundle 可以启动且首次 Metal clear/readback 成功；但本轮 CUA 未能对最终自绘元素取得可点击 frame，故中文输入法组合、粘贴/删除/组合字符选区、快速文本后应用/切换、外部更新投影、撤销/重做、保存/重开、关闭取消/保存与资源清理仍待按最终代码实测；不能以程序化领域写入、无窗口测试或临时原生覆盖层代替。

## 已实施基础：人和外部系统共同编辑真实表单

状态：代码、纯仓颉测试、双进程 socket、独立 Agent、正常窗口构建/签名/启动及大部分 GUI 回归已完成；范围、无窗口与 GUI 验收边界见[共享编辑表单阶段提示词](../plans/2026-09-11-shared-editing-form-stage-prompt.md)。本阶段在不污染 `shared_operation_core` 领域语义的前提下，提供可复用的文本/整数/布尔表单绑定与编辑草稿状态，令备份规则 GUI 和无窗口消费者共用应用领域、草稿冲突/应用/取消语义及既有私有 descriptor 入口。

本轮真实 CUA GUI 已验证键盘文本编辑、空整数不回滚而显示 `retention_count_required`、改为 31 后原子应用、取消重载、外部修改另一字段时当前文本/焦点保留，以及关闭资源清理。原生文本控件本身使用 Cocoa `NSTextField`；Unicode 在领域/transport 双进程测试中已真实往返，且窗口显示中文默认标签和可选区中文文本。**但 CUA 的 clipboard 调用在该 app 上超时，且当前 CUA 键盘 API 未提供可用的 macOS modifier/backspace 名称，因此“通过 CUA 实际粘贴中文并删除/复核选区边界”的最后一条 GUI 证据仍未取得，不能用前述无窗口 Unicode 结果替代。**

因此本阶段应标为“实现与大部分集成验证完成，Unicode 粘贴/删除 GUI 验收待补”，而不是完整可见交互验收完成。最短待验是：在该 app 的规则名称字段粘贴中文、选择其中一段后删除，确认草稿与外部 `GET_CONTEXT` 的 UTF-8 值和选区保持一致；其余路径已有当前实测。

上一阶段的 core、列表、备份规则、独立 Agent 与 GUI 证据保留在下一节。它们是本阶段起点，不能替代表单草稿、真实键盘编辑、应用/取消或新并发边界的验收。

## 上一阶段交付：开发者可定义数据与动作的共同操作

状态：代码、普通构建、core 自动测试、两类无窗口独立进程验收、独立 Agent 消费及迁移后 GUI 实机回归已完成。执行范围与边界见[下一大阶段提示词](../plans/2026-09-11-extensible-shared-operations-stage-prompt.md)。本阶段已把中性列表迁移为共同操作契约的一种消费者，新增不同领域的无窗口配置消费者、通用公开客户端和不链接 renderer/AppKit/Metal 的普通 core/transport 构建入口。

上一阶段的窗口、外部操作与关闭清理记录保留在下节；它们不能替代本阶段迁移后的 GUI 验收。本轮已经重新复核迁移列表的真实勾选、外部修改重投影、视口滚动、冲突拒绝和关闭清理；这只代表当前样例的集成路径，不代表发布、跨机器身份系统或第三方模型提供方接入。

## 上一阶段交付：首个可共同操作的窗口

状态：本次接续阶段已完成。gpt-5.6-terra（xhigh）完成了可复用、可授权、可批量操作的首版，并留下 source、针对性测试、正常应用和第二消费者证据。macOS 正常关闭的退出码修正已在当前 bundle 的真实窗口关闭回归中通过。
执行位置：直接使用 /Users/jiangxuanyang/Desktop/cangjie，不创建 worktree、不复制工作目录。
入口：[大阶段提示词](../plans/2026-09-11-shared-operation-stage-prompt.md)。

目标：一个正常消费 CJGUI 的中性列表样例，人在窗口选择/修改，外部系统读取同一上下文并完成实际修改，双方看到/获取一致结果并接续操作。
列表是框架验收载体，不确定未来产品类型，也不要求聊天窗。
这个阶段包括最小显示、输入、真实动作、状态更新和一条外部连接；不再把语义交互全部留到传统 GUI 做完之后。

开始条件：用户将阶段任务交给执行 AI，或明确要求开始该阶段。无需再为同一阶段的每个内部步骤申请批准。
实施范围：runtime/cjgui 下必要的源文件、native、样例、连接适配、构建与验证；可以同步必要的 smoke 兼容入口。
runtime_state.cj / cjpm.toml 如确为正常应用集成所需，按 AGENTS.md 最小修改与较强验证；不默认要求修改。
下一执行 AI 先复核 R1 与包消费现实，再自主安排实施，不把复核扩成新的审计链。

阶段交付按 [可用性验收](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)：
正常应用、人类输入、外部实际操作、版本冲突处理、真实模型接入分别留证。
窗口内真实输入、socket 外部操作和独立 Codex Luna Agent 已验收：Agent 只从 descriptor 与公开 client 的 GET 解释标题和范围后行动，再在人的修改后只读续接。该证据不等同于第三方模型提供方接入、跨机器身份系统或发布；这些仍须单独标记和验证。

本次接续的功能验收已完成：每个实例拥有受开发者显式授权的私有外部连接；协议完整传输 Unicode/长内容并限制畸形输入；101 条真实记录由窗口视口浏览但以稳定 ID 操作；授权范围内的批量设值在同一业务锁中原子完成，越权、过期和未知目标不改状态。连接/核心聚焦测试、native verifier、正常 app 与第二消费者都分别留有证据，不以此前三行演示替代这些证据。AppKit 主循环退出后，启动桥接显式返回成功状态，以避免编译器生成的 C `main` 读取未定义返回寄存器；当前 bundle 的真实窗口关闭已确认 shell `exit 0`，且 descriptor/socket 已清理，因此该项为 integrated green。以上均不等同于发布。

## 分工与记录

指导 AI 负责方向、阶段提示词与验收审阅；Luna/Terra 等执行 AI 负责实现、修复与验证。
方向与治理文档由指导 AI 亲自调整；用户随后已授权 Terra 持续执行整个阶段。后续不按函数或小文件逐次审批。
执行 AI 只在这里更新当前事实，并给一次阶段交付摘要；不要往多个索引复制日志。
第二个独立样例已检验复用；编辑、画布等优先级是后续工作，不属于本阶段追加任务。

## 已退役的推进方式

stage145–892 的 748 个源文件和 1410 个验证脚本已退出活跃源码树，仅作为历史证据。
不恢复旧链，不创建 stage893 或同构 Bool 审计包装。
旧“四周目标”“本阶段只清理”和旧 docs-only next opening 均已由本版取代，不按旧日期续排任务。
[历史清单](cjgui-stage-145-892-manifest.md) 与 [本次调整前快照](2026-09-11-direction-governance/runtime--cjgui--ACTIVE_DIRECTION.before.md) 可按需追溯。
