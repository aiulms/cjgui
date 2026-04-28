# 仓颉 GUI 项目治理总则

最后更新：2026-04-27

性质：docs-only / governance gate / project rule
状态：生效中
范围：用于约束“仓颉原生 GUI 框架”项目的架构判断、开口审批、实现边界与封账方式

## 0. 这份文档是干什么的

本项目采用：

> 先文档化治理，再进入实现

这不意味着凡事都要开重型流程，而是意味着：

- 先把边界写清楚，再写代码
- 先确认 owner 和真相层，再开抽象
- 先确认当前 stop-line，再决定本轮只做什么
- 做完以后要封账，不让下一轮重复踩同一个坑
- 治理文档的目标是批准受限实现，不是无限推迟实现

这份治理文档是轻量版，不照搬业务系统的重流程。
它只服务于 GUI 框架研发真正高风险的地方。

## 1. 核心原则

快速开工前，先读：

- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

这张卡片记录的是本项目最硬的 AI 开发禁区。
长文档负责解释原因，宪法卡负责让边界在开工前被看见。

### 1.1 先做桌面运行时，再做 GUI 框架

窗口、事件、重绘、状态、绘制是底座。
控件、DSL、主题系统、响应式语法都建立在底座之上。

### 1.2 单一 owner，单向投影

任何能力都要先回答：

- 谁是真正 owner？
- 谁持有真相？
- 哪些只是投影、示例、调试输出或 read surface？

示例、文档、DSL、demo 都不能发明第二真相源。

### 1.3 低阻力路径必须先是合法路径

“快”不等于“对”。
凡是看起来省事但会破坏 owner、真相层、平台边界的路径，都属于高危捷径。

### 1.4 先单平台跑通，再谈跨平台

没有真实跑稳的第一平台，就不做漂亮的跨平台抽象。

### 1.5 文本、输入法、无障碍属于后期开口

这些不是“顺手补一下”的能力。
任何涉及 `Text` 深化、`Input`、`IME`、无障碍的推进，都默认升格审查。

### 1.6 演示不等于成熟

一个 demo 跑通，只能证明现象，不代表底座已经稳定。

### 1.7 桥接层要窄，不是盲目追求薄

平台桥接层可以承担 macOS / Metal 的脏活。

真正要控制的是向上暴露的接口：

- 向上只能输出标准化、脱水、可测试的事件和资源句柄
- 不能把 `NSEvent`、`NSWindow`、`CAMetalLayer` 等平台对象泄露成公共契约
- 不能把平台偶然性推给仓颉核心层解释

### 1.8 FFI、主线程和资源生命周期是底层硬边界

任何平台桥接实现都必须先回答：

- 跨 FFI 对象谁创建、谁持有、谁释放？
- macOS 主线程 owner 是谁？
- 后台任务如何把 UI 更新提交回主线程？
- FFI 错误如何返回结构化结果？
- 哪些错误不可恢复，必须 fail fast 或进程隔离？

### 1.9 构建链、错误哲学和能力查询不能靠记忆

能跑一次不等于构建链健康。

任何影响 SDK、编译脚本、链接参数、shader 编译、平台能力探测的改动，都必须让后续维护者能从文档复现。

错误处理也必须统一：

- `fatal`：不可恢复，应该 fail fast 或隔离
- `recoverable`：应返回结构化错误并交给上层处理
- `degraded`：允许降级，但必须诚实暴露状态

渲染能力不允许默认假设永远可用。未来需要 capability query 来说明当前设备支持什么、不支持什么。

## 2. GUI 项目中的三层治理

任何非平凡能力都先看三层：

- `入口层（Ingress）`
- `执行层（Execution）`
- `真相层（Truth）`

### 2.1 入口层

包括：

- 对外 API
- Widget API
- DSL
- 示例程序
- 文档中的调用方式

纪律：

- 入口层只能消费真实底座能力
- 不允许用入口层设想反逼底层实现

### 2.2 执行层

包括：

- 窗口创建
- 事件循环
- 事件分发
- 状态更新
- 布局计算
- 绘制与重绘
- 平台对象生命周期
- FFI handle 生命周期
- 主线程消息队列
- 平台错误边界

纪律：

- 执行链必须清楚
- 一件事情只能有一个 owner
- 后台线程 / 协程不能直接写 GUI 资源

### 2.3 真相层

包括：

- 当前 UI 状态树
- 当前布局结果
- 当前渲染输入
- 当前平台对象生命周期

纪律：

- 渲染结果不能反向定义状态真相
- 平台回调不能直接升级为高层 owner
- 调试输出不是系统真相

## 3. 什么情况下必须先过 docs-only gate

以下场景不能直接开工，必须先写 docs-only 文档：

- 要新增或重构公共 API、Widget API、DSL
- 要引入跨平台抽象
- 要改动状态真相、布局真相、渲染真相的 owner
- 要引入新的底层依赖、图形依赖、系统级桥接能力
- 要新增或改变 FFI 对象生命周期 / handle 模型
- 要改变主线程、事件循环、消息队列或跨线程 UI 更新模型
- 要改变 FFI 错误返回、平台错误边界或崩溃隔离策略
- 要改变平台桥接层向上暴露的事件、资源或平台能力
- 要引入或承诺 GUI 自动化视觉验证基础设施
- 要改变构建脚本、SDK 选择、编译参数、链接参数或 shader 编译流程
- 要定义、改变或绕过错误处理哲学
- 要引入渲染能力查询、硬件能力判断或降级策略
- 要开启文本系统深化、输入框、IME、无障碍
- 要把平台原生事件翻译成框架公共事件模型
- 要重写平台桥接边界
- 发现当前文档判断与代码现实明显冲突
- 为了修一个局部问题，开始扩到本轮 blast radius 之外

### 3.1 Docs Exit / Implementation Bias Rule

docs-only gate 必须有出口。

当某条 opening 已经满足以下条件：

- owner 已明确
- truth 已明确
- write set 已明确
- forbidden scope 已明确
- stop-line 已明确
- verification 已明确

则下一轮默认必须进入 bounded implementation。

除非出现以下情况，否则禁止继续创建新的 preflight / execution card 来替代实现：

- 发现新的 HIGH / CRITICAL 风险
- 当前代码现实与既有文档明显冲突
- 必须触碰未批准 write set
- 必须改变 public API / runtime contract / owner / truth
- 必须新增依赖、系统权限、平台桥接或迁移

执行卡是开工许可证，不是新的文档循环入口。

如果已有 preflight 已经冻结边界，execution card 应保持短小，并且同一轮或下一轮必须落到代码。

### 3.2 Internal Concept Slice Rule

治理文档用于帮助执行 AI 找准方向，不用于把执行 AI 限制到每次只能写一个 symbol、一行字段或一个 marker。

bounded implementation 的粒度应按风险和内部概念划分，而不是按代码行数划分：

- 如果本轮仍在同一 owner 内。
- 不改变 public runtime API / public C ABI。
- 不暴露平台对象、native handle、raw pointer 或 FFI 生命周期。
- 不跨越既有 truth / projection 边界。
- write set、forbidden scope、verification 和 stop-line 已清楚。

则 execution card 应优先授权一个完整的 internal concept slice，而不是拆成 `marker -> field -> constructor -> no-op -> transition` 的多轮文档链。

一个 W1 / W2 internal concept slice 可以在同一轮内包含多个相互依赖的小动作，例如：

- 一个 internal type。
- 少量 immutable facts。
- construction shape。
- no-op transition。
- 一个极窄 state-changing transition。
- 对应 closure review 和索引更新。

代码行数本身不是风险指标。2 行、1000 行或 3000 行都可能是合理实现，前提是它们仍在批准的 owner / write set / stop-line 内，并且验证能覆盖本轮目标。相反，即使只改 1 行，只要它改变 public contract、truth owner、平台对象暴露、FFI 生命周期或安全边界，也必须重新走高风险 gate。

禁止无实质风险理由地把同一 internal concept slice 拆成多轮 docs-only / one-symbol implementation 循环。只有在出现语言语法不确定、build fail、authority 冲突、public contract 风险、跨 owner 影响或验证不可成立时，才应主动缩小切片或 fail closed。

### 3.3 Bundled Execution Card Rule

低风险 internal-only runtime work 可以使用 bundled execution card。bundle 的大小按内部概念完整性和风险边界决定，不按“每轮只能写几个函数”决定。

允许两档常用 bundle：

- `W2 internal behavior bundle`：一次完成一个完整内部行为概念，通常包含 3-7 个相互关联的 internal changes，代码规模可以是几十行到数百行。
- `W3 internal subsystem draft bundle`：当 owner / truth / write set / verification 都清楚，且仍完全 internal-only 时，可以一次完成一个内部子系统草案，通常包含 6-15 个相关 internal changes，代码规模可以达到数百行。它可以横跨同一 owner 下的多个紧密相关 types、builders、decision functions、result types、sanity paths 和 bundled closure。

W3 internal subsystem draft bundle 不是 high-risk gate 的同义词。只要它不触碰 public runtime API、public C ABI、platform bridge、event loop、queue / drain、handle table / generation、跨 owner truth、系统权限或安全边界，就不必因为代码行数较大而拆回 one-helper slices。

如果 bundle 被拆成多个 slice，每个 slice 仍必须独立运行 build / smoke / `git diff --check`，slice 完成后可先只在 tracker 记录简短日志，bundle 完成后再写一份 mini-compaction / bundled closure。如果 bundle 是单次完整实现，可以在实现结束后统一运行验证并写 bundled closure。

bundle 不得绕过 public API、public C ABI、platform bridge、event loop、queue / drain、handle table / generation、跨 owner truth 或安全边界 gate；触碰这些边界时恢复高风险 docs-only gate 或单卡单 closure。

### 3.4 Helper Chain Exit / Larger Internal Behavior Bundle Rule

helper / sanity 链只能用于证明内部链路可组合，不能成为长期推进方式。

当某条 internal-only 方向已经完成 positive path、negative path、parity 或 root sanity，并且 bundle closure 已明确验证 build / smoke / `git diff --check`，下一张 bundle 默认应提高授权粒度，转向完整的 internal behavior concept。

完整 internal behavior concept 可以在一张 W2 bundle 中包含 3-7 个相互关联的 internal changes；如果同一 owner 下的内部子系统边界已经清楚，可以升级为 W3 internal subsystem draft bundle，一次包含 6-15 个相关 internal changes。例如：

- input / policy / decision / result 等 internal types。
- default constructor 或 builder。
- 核心 internal behavior function。
- positive / negative path。
- minimal sanity / parity check。
- request / response / pipeline / draft command 等同一内部行为链路。
- 状态汇总、outcome、progress、command draft 等同一 owner 内的闭环草案。
- tracker log 与 bundled closure。

只要仍满足 internal-only、owner 清楚、truth 清楚、write set 清楚、verification 清楚，并且不触碰 public runtime API、public C ABI、platform bridge、event loop、queue / drain、handle table / generation 或安全边界，就不应把这些相关变化拆成 helper-by-helper 的多轮循环。拆分的理由必须是风险、语法不确定、验证不可成立或 owner 冲突，而不是“代码行数看起来多”。

模型能力不是风险来源；越界才是风险来源。顶级执行模型可以承担完整 internal concept slice。治理应帮助模型对齐方向，而不是把模型降级成每轮只能写一个函数的打字员。

## 4. 三种 docs-only 任务

### 4.1 Preflight

用途：

- 用于探索和冻结开口边界
- 用于确认“这件事值不值得做、能不能做、应该切多窄”

适用场景：

- 新能力
- 新阶段开口
- future slot
- owner 不清
- 真相层可能变化

产出路径：

- `docs/plans/YYYY-MM-DD-<topic>-preflight.md`

Preflight 至少要回答：

- 当前代码现实是什么
- 当前真正 owner 是谁
- 当前真相层是什么
- 入口层和投影层分别是什么
- FFI 对象生命周期和释放路径是什么
- 主线程 owner 和跨线程消息路径是什么
- 平台桥接向上暴露的是哪些窄接口
- 构建链如何从零复现，是否需要更新 `BUILD_FROM_ZERO.md`
- 错误如何分类为 `fatal` / `recoverable` / `degraded`
- 当前依赖哪些硬件 / GPU / Metal capability，缺失时如何报告
- 验证证据如何获得，是否存在自动化路径或人工残留
- 当前失败窗口在哪里
- 当前不做什么
- 下一轮是否允许进入实现或 approval gate

说明：

- Preflight 本身不等于批准实现

### 4.2 Approval Gate

用途：

- 批准或拒绝高风险开口

适用场景：

- 公共 API / DSL
- 跨平台抽象
- 文本 / 输入 / IME / 无障碍
- 新底层依赖
- owner 调整
- 真相层重组

产出路径：

- `docs/plans/YYYY-MM-DD-<topic>-approval-gate.md`

Approval Gate 至少要回答：

- 是否批准
- 批准的边界是什么
- 本轮允许触碰哪些 write set
- 哪些区域仍然禁止触碰
- 是否允许进入 bounded implementation
- 当前 stop-line 是什么

说明：

- Approval Gate 批准的是“开口”，不是批准无限扩面

### 4.3 Closure Review

用途：

- 对已完成的 bounded slice 进行封账

适用场景：

- 一段实现已经落地
- 需要确认 stop-line 是否守住
- 需要防止后续 AI 重复打开已闭合的线

产出路径：

- `docs/plans/YYYY-MM-DD-<topic>-closure-review.md`

Closure Review 至少要回答：

- 当前 landed code reality 是什么
- 本轮 invariant 是否成立
- stop-line 是否守住
- 还剩哪些 residual
- 哪些线不能自动重开

## 5. 默认工作流

默认按下面的节奏走：

```text
preflight
-> approval gate（如有高风险开口）
-> execution card
-> bounded implementation
-> closure review
```

如果只是局部、低风险、完全不改变边界的修补，可以不走完整 gate。
但只要进入本治理文档列出的高风险场景，就不能跳步。

默认工作流不能退化成：

```text
preflight -> execution card -> closure -> preflight -> execution card -> closure
```

如果连续两轮都是 docs-only 且没有新的实质风险发现，第三轮必须优先选择 bounded implementation 或明确暂停该方向。

## 6. 文档职责分工

### 6.1 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

只记录：

- 当前阶段
- 当前 healthy stop-line
- 当前 active / future openings

不要把它写成长流水实现记录。

### 6.2 [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

只记录：

- GUI 历史坑
- 项目长期禁忌
- 当前需要反复提醒自己的风险

### 6.3 [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)

承载：

- 项目的思考框架
- 元逻辑循环
- 长期判断语言

### 6.4 `docs/plans/*.md`

承载：

- preflight
- approval gate
- execution card
- closure review

### 6.5 [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

承载：

- AI 写码时的质量治理
- fallout scan
- verification bundle
- Definition of Done

### 6.6 [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)

承载：

- 每次非平凡实现前的执行卡模板

### 6.7 [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)

承载：

- 每轮 AI 必读上下文预算
- L0 / L1 / L2 / L3 分层读取规则
- 防止架构 AI 用长阅读清单替代清晰执行边界

### 6.8 [CJGUI_SKILLIZATION_PLAN.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_SKILLIZATION_PLAN.md)

承载：

- CJGUI 治理未来 skill 化的阶段计划
- skill 与项目文档的真相源边界
- 避免 skill 复制整套文档或变成第二个 tracker

## 7. 必须暂停的场景

一旦出现下面任一情况，必须暂停，不得自行扩面：

- 需要触碰未批准 write set
- 开始讨论跨平台抽象，但第一平台还没稳定
- 开始碰 `Input` / `IME` / 无障碍
- 准备把平台原生对象泄露到公共 API
- 需要新增重型外部 GUI 依赖
- 发现入口层已经开始反逼底层真相
- 发现状态真相和渲染真相出现双源
- 当前文档判断与代码现实明显冲突

## 8. Bounded Implementation 规则

真正进入实现时，必须说明：

- 本轮 blast radius
- 当前 owner / truth 如何落地
- 改动了哪些文件
- 本轮不做什么
- 如何验证

如果实现开始越出当前切口，就必须停下，不允许边写边扩。

### 8.1 No Comment-Only Implementation Rule

除非任务本身明确是文档整理、注释补账或 public documentation cleanup，否则 `comment-only` 不得计为 implementation。

如果一轮任务名为：

- implementation
- first slice
- bounded implementation
- runtime slice
- code slice

则必须至少产生一个可编译、可运行或可验证的行为变化。

允许的最小行为变化包括：

- 新增可编译的仓颉类型 / 函数 / 内部结构
- 新增可运行 smoke / harness
- 新增真实错误分类或状态转换
- 新增测试能捕捉到的行为
- 新增构建可见的包、模块或入口能力

不允许把“只新增注释、只扩写 stop-line、只整理 README”命名为 implementation。

## 9. 当前项目的统一 stop-line

在新的单独批准出现之前，当前统一保持：

- 不做跨平台抽象
- 不做公共声明式 DSL
- 不做输入框
- 不做 IME
- 不做无障碍
- 不做完整控件库
- 不引入重型 GUI 框架
- 不让示例程序反向定义底层真相
- 不让平台原生类型泄露到上层公共契约

## 10. 每次开工前的轻量检查点

以后每轮推进前，先快速回答这 6 个问题：

1. 这次改动属于入口层、执行层，还是真相层？
2. 当前真正 owner 是谁？
3. 这是不是当前最窄的一刀？
4. 这一步会不会制造第二真相源？
5. 这一步能否用最小 demo 验证？
6. 这一步是否仍服务于“仓颉 GUI 底座”，而不是别的野心？

## 11. 一句话目标

这套机制的目标不是拖慢开发，而是防止我们：

- 一边写代码一边临时决定架构
- 在底座未稳时过早抽象
- 把 demo 当成熟能力
- 用局部补丁掩盖边界问题
- 重复打开已经应该封账的线

一句话：

> 先把 GUI 底座边界写清楚，再实现；边界清楚后必须实现；实现后封账，不让下一轮继续在同一个坑里打转。
