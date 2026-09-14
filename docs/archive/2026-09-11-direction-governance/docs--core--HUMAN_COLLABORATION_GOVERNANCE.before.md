# 人类协作治理说明

最后更新：2026-04-25

## 1. 文档定位

本文件面向未来可能参与仓颉 GUI 项目的人类贡献者、协作者和维护者。

它不是社区章程，也不是完整开源治理制度。当前项目还处于早期底座阶段，不需要复杂委员会、投票流程或大型 RFC 体系。

它只解决一个问题：

> 当项目从一个人的长期工程，逐步走向多人协作时，怎样减少误解、越界 PR、方向冲突和维护者情绪消耗？

本文件与以下文档配合：

- [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

## 2. 核心态度

本项目欢迎帮助，但不把“有人愿意贡献”自动等同于“任何方向都可以合入”。

当前第一优先级是：

- 架构边界清楚
- 底座真实可验证
- 状态真相单一
- 平台桥接不污染上层
- 不为了 demo 或短期便利牺牲长期可维护性

因此，贡献的价值不只看代码量，也看是否强化项目骨架。

## 3. 维护者职责

维护者应当做到：

- 把项目方向写清楚，而不是只放在脑子里。
- 拒绝 PR 时说明违反了哪条边界，而不是只说“不喜欢”。
- 对新贡献者保持善意，但不牺牲项目底线。
- 对 core 方向承担最终责任，不把架构判断推给黑箱 AI。
- 尽量把“为什么这样设计”写进文档、代码注释或 closure review。

架构 AI 可以作为规则解释器、风险分析员和文档辅助者，但不能替代维护者承担最终决策责任。

## 4. 贡献者职责

贡献者应当做到：

- 先阅读方向和治理文档，再提交非平凡改动。
- 不把局部可用方案直接扩成框架公共能力。
- 不绕过 owner boundary。
- 不把 demo API 的美观程度凌驾于底层真实能力之上。
- 不把平台原生对象泄露到公共仓颉 API。
- 不把 `projection` 当成 `truth`。
- 不把一次 PR 扩成多个 owner 的大重构。

如果一个改动涉及公共 API、状态语义、平台桥接、渲染模型、事件模型、布局模型、文本/输入、跨平台抽象，默认先写 docs-only preflight。

## 5. 领域地图

### 5.1 `core`

定义：

- 项目底座和长期架构主权所在。

当前包括：

- 平台桥接边界
- 事件循环
- 渲染命令模型
- Scene / Renderer 边界
- 状态真相模型
- 语义树 / AI-readable UI 的长期接口
- 公共 API

规则：

- PR 必须先有 preflight 或 execution card。
- 不接受“顺手重构”。
- 不接受未解释 owner / truth / ingress 的改动。
- 维护者保留严格拒绝权。

### 5.2 `experimental`

定义：

- 用于探索、验证、试错的区域。

当前包括：

- `labs/*`
- 独立 spike
- docs-only 研究
- 参考仓库分析

规则：

- 可以更灵活。
- 可以被推翻。
- 不能直接升格为公共 API。
- 实验成功后必须通过 closure review 才能进入主线判断。

### 5.3 `stable`

定义：

- 已经闭合、可依赖、暂时不希望频繁扰动的能力。

规则：

- 允许 bugfix、文档修正、测试补强。
- 不允许无批准修改公共行为。
- 不允许重新打开已 closure 的线，除非有新的 preflight。

### 5.4 `help-wanted`

定义：

- 欢迎贡献者优先帮助的领域。

当前更适合的帮助方向：

- 文档校对
- 示例程序
- 本地运行验证
- 参考框架调研
- 测试脚本
- 截图 / 视觉验证方式
- macOS / Windows / Linux 平台资料整理
- 仓颉语言特性验证

规则：

- 帮助方向应尽量低耦合。
- 不应越过 core owner boundary。
- 对新贡献者优先提供清楚、可完成的小任务。

### 5.5 `no-go`

定义：

- 已明确不作为当前路线的方向。

当前 no-go：

- Electron / WebView 作为主渲染路线
- Qt / GTK 等重型 GUI 框架作为框架核心依赖
- 过早跨平台抽象
- 过早输入框 / IME / 富文本 / 无障碍
- 为了第一个 demo 设计完整声明式 DSL
- 把 Rust 依赖塞进 GUI 框架核心
- 让框架核心知道 `open-nwe` 的业务模型
- 让平台原生对象泄露到仓颉公共 API

规则：

- 可以讨论，但默认不进入实现。
- 如果未来要重开，必须先写 approval gate。

## 6. PR 接收原则

一个 PR 更容易被接受，如果它满足：

- 边界小
- write set 清楚
- 不跨多个 owner
- 能说明当前 code reality
- 能说明 owner / truth / ingress
- 有最小验证
- 有 stop-line
- 不制造新的第二真相源
- 不把实验能力伪装成稳定能力

一个 PR 更容易被拒绝，如果它出现：

- 大范围重构但没有 preflight
- 为了 demo 好看提前设计 API
- 修改 core 但没有解释 owner boundary
- 引入重型依赖但没有必要性论证
- 让平台偶然性进入公共契约
- 把多个 future opening 合并成一刀
- 用兼容层、fallback、helper 掩盖真实边界问题

## 7. 标准回复模板

### 7.1 方向有价值，但需要 preflight

> 这个方向有价值，但它触碰了当前 core boundary。
> 当前 PR 还没有冻结 owner / truth / ingress / failure / stop-line。
> 请先补一份 docs-only preflight，再决定是否进入实现。

### 7.2 违反当前 stop-line

> 这份 PR 进入了当前明确暂停的范围。
> 目前项目 stop-line 是：不做跨平台抽象 / 不做输入框 / 不做完整 DSL / 不引入重型 GUI 依赖。
> 因此当前不能合入。欢迎把需求转成 future opening 文档。

### 7.3 代码可以，但位置不对

> 这段实现本身有参考价值，但它放在了错误的 owner 里。
> 当前模块只能消费 truth，不能创建或解释 truth。
> 请把能力移动到真正 owner，或先写 preflight 说明为什么 owner boundary 需要改变。

### 7.4 太大，需要拆分

> 这个 PR 同时改动了多个 owner，review 风险过高。
> 请拆成更小的 bounded slice，每一刀只改变一个清晰边界，并说明 stop-line。

### 7.5 不符合项目方向

> 感谢贡献，但这个方向与项目当前路线不一致。
> 本项目当前选择的是仓颉原生核心 + 向上接口极窄的平台桥接 + GPU 自绘路线。
> 因此不会把该方案作为主线合入。

## 8. 协作时的语言原则

拒绝 PR 时应当：

- 先承认对方投入。
- 说明具体边界。
- 引用文档或 stop-line。
- 给出可继续参与的替代路径。
- 避免把技术拒绝表达成人身否定。

贡献者也应当理解：

- 项目拒绝一个 PR，不等于否定贡献者能力。
- 早期框架项目最需要的是方向一致，而不是功能越多越好。
- 很多“不做”是为了以后能做得更稳。

## 9. 当前协作成熟度

当前项目仍处于：

> early solo-maintained architecture lab

这意味着：

- 可以提前准备协作规则。
- 不急于开放大规模贡献。
- 不急于承诺稳定 API。
- 不急于把实验代码产品化。
- 不急于为社区便利牺牲底座边界。

更现实的目标是：

- 先让未来第二个人能看懂项目为什么这么走。
- 再让未来贡献者能找到安全的小切口。
- 最后才谈更正式的开源社区治理。

## 10. Stop-line

本文件不批准：

- 立即开放无限制外部 PR
- 为社区便利提前稳定公共 API
- 为贡献者方便放宽 core boundary
- 用架构 AI 替维护者承担最终决策
- 把人类协作治理变成繁重流程

本文件只批准：

- 把人类协作风险显式记录下来
- 建立最小领域地图
- 准备 PR 沟通模板
- 在未来进入多人协作前，降低解释成本和冲突成本
