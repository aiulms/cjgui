# 仓颉 GUI 文档中心

最后更新：2026-04-25

## 1. 文档入口规则

根目录只保留入口级文档：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

其他长期文档按职责收纳到本目录下，避免根目录被低频文档污染。

## 2. 目录职责

### 2.1 [core](/Users/jiangxuanyang/Desktop/cangjie/docs/core)

放项目方向、治理、风险、长期设计和协作文档。

当前包括：

- [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)
- [HUMAN_COLLABORATION_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/HUMAN_COLLABORATION_GOVERNANCE.md)
- [OPEN_NWE_PRODUCT_DEMAND_MAP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)

### 2.2 [ai](/Users/jiangxuanyang/Desktop/cangjie/docs/ai)

放 AI 执行、代码质量和任务卡模板。

当前包括：

- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)

### 2.3 [setup](/Users/jiangxuanyang/Desktop/cangjie/docs/setup)

放本机环境、构建链和本地资料索引。

当前包括：

- [LOCAL_DOCS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_DOCS.md)
- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)

### 2.4 [plans](/Users/jiangxuanyang/Desktop/cangjie/docs/plans)

放单次 bounded slice 的 preflight、execution card、approval gate、closure review。

索引：

- [plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## 3. 新文档放置规则

- 方向、治理、长期设计、风险账本：放 `docs/core/`
- AI 执行规则、代码质量、执行卡模板：放 `docs/ai/`
- 环境、构建、工具链、本地资料、仓颉上游问题账本：放 `docs/setup/`
- 单次任务计划、preflight、gate、closure：放 `docs/plans/`
- 只有总入口和当前任务账本可以留在根目录

如果一个新文档不知道该放哪里，先不要创建，应该先在 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 或本文件里补职责说明。
