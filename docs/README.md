# CJGUI 文档导航

更新：2026-09-19。执行任务默认读 AGENTS.md、ACTIVE_DIRECTION.md 与它指向的当前阶段任务；指导 AI 规划大阶段时再核对设计意图和相关历史资产。本页负责文档归属与导航，不另写架构或执行状态。

## 各类信息只在一处维护

| 要回答的问题 | 唯一维护入口 | 其他文档怎样引用 |
| --- | --- | --- |
| 项目要做什么、保留哪些路线 | [项目方向](core/GUI_PROJECT_DIRECTION.md) | README、任务和治理只摘要并链接，不另定义项目定位 |
| 状态由谁持有，组件/渲染/外部入口怎样连接 | [架构契约](core/AI_NATIVE_UI_SEMANTICS.md) | 共同定义、权限、草稿、生成式接入等机制集中在此；任务只写本阶段方案与差异 |
| 什么证据算完成 | [验收标准](core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md) | 阶段引用相关标准并补具体场景，不降低或改名绕过要求 |
| 当前做什么、谁执行、哪些仍未验、下一候选 | [当前状态](../runtime/cjgui/ACTIVE_DIRECTION.md) | README、导航、定时提示词都读取此页，不保存第二份当前任务 |
| 当前阶段怎样交付、结果在哪里 | ACTIVE 指向的阶段页 | 执行提示词是该阶段的启动/交接入口，不重写整套目标、方案与验收；历史阶段不是自动开工指令 |
| 怎样协作、失败如何升级 | [AGENTS.md](../AGENTS.md) | 治理总则解释，协作分工说明职责，具体当前执行对象在 ACTIVE |
| 过去为什么这样设计、能复用哪些资产 | [设计意图导航](plans/DESIGN_INTENT_INDEX.md) | 只提供主题入口和复用判断；旧研究和历史记录不覆盖现行契约 |
| 实际能力缺口由哪条线承接、后续包如何依赖 | [三线能力推进表](plans/2026-09-26-framework-capability-roadmap.md) | 维护能力基线、主责和阶段范围；执行对象与当前结果仍回到 ACTIVE 和阶段证据，不逐轮追加另一套状态日志 |

用户最新明确决定优先。阶段可细化实施与验收，但不得悄悄更改项目方向或架构；需要改变时先由指导校准对应维护入口，再更新当前任务的引用。源码与运行证据决定实现状态，设计文字不能证明能力已经完成。发现冲突按上表回到负责该信息的文件处理，不把相反规则都保留给执行者选择。

## 按需资料

- [治理总则](core/GUI_GOVERNANCE.md)：执行自主权、风险处理与文档减负。
- [协作分工](core/HUMAN_COLLABORATION_GOVERNANCE.md)：指导 AI 与执行 AI 的职责。
- [阶段任务模板](ai/AI_EXECUTION_CARD_TEMPLATE.md)：按大阶段交付，不按符号拆卡。
- [最小上下文](ai/CJGUI_CONTEXT_LOADING_POLICY.md)：按问题查资料。
- [协议实验](core/AI_ACTION_PROTOCOL_EXPERIMENT.md)：保留经验，格式可替换。
- [按需风险参考](core/GUI_RISK_LEDGER.md)：只读涉及的条目。

## 当前工作

唯一事实入口：[ACTIVE_DIRECTION.md](../runtime/cjgui/ACTIVE_DIRECTION.md)。
当前阶段与提示词由 ACTIVE_DIRECTION.md 指向，本页不另维护阶段版本。
[2026-09-11 历史调整记录](plans/2026-09-11-direction-governance-realignment.md)只解释当时取舍。

## 资料与历史

setup/ 保存[工具链问题账本](setup/CANGJIE_ISSUE_LEDGER.md)与[贡献候选](setup/CANGJIE_UPSTREAM_CONTRIBUTION_RADAR.md)；research/ 保存按需研究，不增加默认任务。
plans/ 除当前状态明确指向的阶段文件外，均视为历史计划或按需研究，不能自动续接其中的 next opening。
[2026-09-11 快照](archive/2026-09-11-direction-governance/README.md) 保留此次改写前的 25 份文档与校验信息。
历史中的批准、暂停、只读、未来开口等语句仅解释当时工作，不覆盖当前规则。

新增资料优先更新已有对应文档。只有独立阶段或独立研究确有必要时才新增文件，不要求同时更新多套索引。
