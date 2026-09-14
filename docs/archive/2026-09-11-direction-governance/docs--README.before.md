# 仓颉 GUI 文档中心

最后更新：2026-05-21

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
- [CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)
- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)
- [AI_ACTION_PROTOCOL_EXPERIMENT.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md)
- [HUMAN_COLLABORATION_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/HUMAN_COLLABORATION_GOVERNANCE.md)
- [OPEN_NWE_PRODUCT_DEMAND_MAP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)

### 2.2 [ai](/Users/jiangxuanyang/Desktop/cangjie/docs/ai)

放 AI 执行、代码质量和任务卡模板。

当前包括：

- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)

### 2.3 [setup](/Users/jiangxuanyang/Desktop/cangjie/docs/setup)

放本机环境、构建链、本地资料索引，以及仓颉上游倒推 / 贡献账本。

当前包括：

- [LOCAL_DOCS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_DOCS.md)
- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [CANGJIE_UPSTREAM_CONTRIBUTION_RADAR.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_UPSTREAM_CONTRIBUTION_RADAR.md)

说明：

- [CANGJIE_UPSTREAM_CONTRIBUTION_RADAR.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_UPSTREAM_CONTRIBUTION_RADAR.md) 是阶段性盘点入口，不是每轮 implementation 的默认必读上下文。

### 2.4 [plans](/Users/jiangxuanyang/Desktop/cangjie/docs/plans)

放单次 bounded slice 的 preflight、execution card、approval gate、closure review。

索引：

- [plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

### 2.5 [research](/Users/jiangxuanyang/Desktop/cangjie/docs/research)

放 sidecar research、行业排雷和不阻塞当前 runtime implementation 的架构风险情报。

research 文档是按需雷达，不是每轮 implementation 的默认必读上下文。只有触碰对应高风险开口时，才读取相关章节。

当前包括：

- [gui-framework-pitfalls-intelligence.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/gui-framework-pitfalls-intelligence.md)
- [ai-native-gui-runtime-architecture-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/ai-native-gui-runtime-architecture-intake.md)
- [cangjie-1.1-owner-tooling-ffi-capability-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/cangjie-1.1-owner-tooling-ffi-capability-intake.md)
- [cjmp-reference-radar.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/cjmp-reference-radar.md)

### 2.6 [assets](/Users/jiangxuanyang/Desktop/cangjie/docs/assets)

放根 README、长期文档和 GitCode 首页可直接引用的图像资源。

当前包括：

- [cjgui-architecture-ai-native.svg](/Users/jiangxuanyang/Desktop/cangjie/docs/assets/cjgui-architecture-ai-native.svg)

## 3. 新文档放置规则

- 方向、治理、长期设计、风险账本：放 `docs/core/`
- AI 执行规则、代码质量、执行卡模板：放 `docs/ai/`
- 环境、构建、工具链、本地资料、仓颉上游倒推与贡献账本：放 `docs/setup/`
- 单次任务计划、preflight、gate、closure：放 `docs/plans/`
- sidecar research、行业排雷、架构风险情报：放 `docs/research/`
- 根 README、长期文档可复用的图像资源：放 `docs/assets/`
- 只有总入口和当前任务账本可以留在根目录

如果一个新文档不知道该放哪里，先不要创建，应该先在 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 或本文件里补职责说明。
