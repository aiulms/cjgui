# CJGUI 自选命题查重说明

核查日期：2026-10-07。结论：在本次核查到的项目说明中，未发现完整覆盖 CJGUI 核心交付组合的项目。基础 GUI、组件、状态管理和自绘均已有相关实现；差异须以真实源码和消费行为支撑。

## 核查范围和方法

检查 Cangjie-TPC 组织公开项目入口、TPC-Resource/TPC-LIST.md、cj-awesome 组织首页和公开项目说明。对邻近项目比较解决对象、主运行时、业务状态与外部操作、生成界面绑定；没有把项目名称不同当作功能不同，也没有把 README 未提到某项能力当成其绝对不存在。

| 项目 | 公开定位和相交能力 | CJGUI 本次交付的区别 |
| --- | --- | --- |
| CJQT | Qt 的仓颉绑定；常见窗口和控件 | 仓颉组件与布局、窄系统桥接；共同操作和受限生成绑定由框架接入 |
| CJQT6 | 通过 FFI 桥接 Qt6 的 GUI 库 | 有 GUI 交集；CJGUI 使用自有组件与平台自绘路线，重点验证共同业务域和外部接续 |
| three.cj | 3D 场景、材质、渲染和游戏配套子系统，集成 SDL3/ImGui 等 | CJGUI 面向应用 GUI 与业务编辑；本次不提供 3D 引擎替代品 |
| CangjieMagic | LLM Agent DSL、MCP 和任务规划 | CJGUI 提供应用界面与授权业务操作入口；不提供通用 Agent 推理或规划引擎 |
| titlebar / xt_hud | TPC 资源目录中的标题栏、提示 UI 等局部组件 | CJGUI 交付组件、布局、业务域、混合生成与共同操作的框架链路 |
| CUI/苍翠 | 仓颉声明式、自渲染桌面 GUI，依赖 CangjieSDL；状态和组件能力 | 基础 GUI 明显相交。CJGUI 不依赖 SDL，区别着重在统一字段/动作、授权版本检查和混合生成接续 |

## 证据来源

- Cangjie-TPC 项目入口：https://gitcode.com/Cangjie-TPC
- 资源目录：https://gitcode.com/Cangjie-TPC/TPC-Resource/blob/main/TPC-LIST.md
- cj-awesome 项目入口：https://gitcode.com/cj-awesome
- CJQT：https://gitcode.com/Cangjie-TPC/CJQT
- CJQT6：https://gitcode.com/Cangjie-TPC/CJQT6
- three.cj：Cangjie-TPC 组织项目列表 https://gitcode.com/org/Cangjie-TPC/repos
- CangjieMagic：https://gitcode.com/Cangjie-TPC/CangjieMagic/tree/dev
- CUI/苍翠：https://github.com/SunriseSummer/CangjieGUI 。本机已克隆 README 描述了其声明式、自绘、状态、组件及 CangjieSDL 依赖。

## 判断边界

这是公开目录与邻近项目说明的有范围核查，不是对两个组织所有源码的逐行审计，也不是赛事的提前资格认定。判断重点为功能和交付链路；后续如发现同类共同操作或生成绑定实现，应更新本说明及比较依据。

CJGUI 的源码定位：runtime/cjgui/src/；共享操作：runtime/cjgui/shared_operation_core/；普通消费者：runtime/cjgui/examples/shared_document_window_app/ 和 rule_set_window_app/。外部 GUI 框架仅参考实现思路，不引入依赖。
