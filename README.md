# CJGUI

仓颉 GUI 框架：让人通过视窗理解、操作应用，让外部智能系统通过对应的内容、上下文和动作共同工作。

应用开发者决定界面与交流方式。CJGUI 不强制聊天窗、Agent 底座、模型供应商或特定通信格式。
界面生成是可选能力；首先要让人看得见、改得动，外部系统理解准确、操作可靠，双方能够接续工作。

## 当前状态

更新：2026-09-12。方向、历史资产与实际交付分别通过下方入口查看。
详细事实仅维护在 [ACTIVE_DIRECTION.md](runtime/cjgui/ACTIVE_DIRECTION.md)，避免多个入口互相矛盾。

## 从哪里开始

- 开发 AI：[AGENTS.md](AGENTS.md) → [当前阶段](runtime/cjgui/ACTIVE_DIRECTION.md) → 当前任务与相关源码。
- 规划大阶段或恢复历史：[设计意图与资产导航](docs/plans/DESIGN_INTENT_INDEX.md)，包含框架主线、已有资产和问题反馈入口。
- 了解定位：[项目方向](docs/core/GUI_PROJECT_DIRECTION.md)。
- 理解共同操作：[语义与操作设计](docs/core/AI_NATIVE_UI_SEMANTICS.md)。
- 当前实施：由 [ACTIVE_DIRECTION.md](runtime/cjgui/ACTIVE_DIRECTION.md) 指向当前任务，避免把旧阶段链接当成最新安排。
- 查构建入口：[runtime 说明](runtime/cjgui/README.md)。
- 查其他资料：[文档导航](docs/README.md)。

## 如何判断进展

正常应用消费框架，人在真实窗口操作；外部系统通过同一应用能力修改内容，结果可见且能继续接手。
构建、探针、外部接口、真实模型调用与发布分别记录。[验收标准](docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)

继续保持仓颉核心、macOS 首个平台、自绘及窄平台桥接。当前不承诺稳定公共 API 或任意外部系统兼容。

## 历史

stage145–892 已冻结，不续写审计包装阶段。
原长 README、tracker、治理与索引保留在 [2026-09-11 历史快照](docs/archive/2026-09-11-direction-governance/README.md)。
[本次治理调整说明](docs/plans/2026-09-11-direction-governance-realignment.md) 记录删改理由与检查范围。
