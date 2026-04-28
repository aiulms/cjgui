# 仓颉 GUI 项目 AI 代码质量治理

最后更新：2026-04-27

性质：docs-only / code-quality governance / AI execution rule
状态：生效中
范围：用于约束后续由 AI 主导实现时的代码质量、边界控制、验证与封账

## 0. 为什么还需要这份文档

文档治理解决的是：

- 我们该不该做
- 这轮开口边界是什么
- 当前 stop-line 在哪里

但仅有文档治理还不够。

AI 在真正写代码时，最容易出现的问题不是“完全不会做”，而是：

- 只盯住局部目标，不看系统尾部影响
- 先把眼前错误修掉，再把结构偷偷搞乱
- 为了让代码看起来跑通，顺手扩面
- 自己以为改的是小点，实际上改到了公共边界
- 把示例、缓存、临时对象、平台细节错误升级成系统真相

所以这份文档解决的是：

> 如何治理 AI 的写码行为，防止它顾头不顾尾、局部最优、补丁化收口。

## 1. 我们要防的三类 AI 失控

### 1.1 局部最优失控

表现：

- 只修眼前 bug
- 不检查当前 owner、上下游、真相层
- 改完一个点，却埋下更大的结构问题

### 1.2 扩面失控

表现：

- 为了“顺手清理”
- 为了“更优雅”
- 为了“统一一下”
- 把本来一刀小修扩成跨模块重构

### 1.3 完成幻觉失控

表现：

- demo 跑了就说完成
- 一个函数能工作就说系统没问题
- 没做 fallout scan 就宣称结束

## 2. 代码治理的核心思路

后续所有 AI 实现都遵循一句话：

> 先冻结本轮写码边界，再进入实现；实现时只在批准范围内动作；完成前必须验证尾部影响；完成后必须封账。

补充约束：

> 治理文档是为了打开受限实现窗口，不是为了让 AI 永远停留在分析区。

### 2.1 AI 执行承诺

每个参与实现的 AI，都默认接受下面的承诺：

> 我不会把能跑一次当作完成。
> 我不会为了局部修复破坏 owner、truth 和 stop-line。
> 我会先确认边界，再写代码；写完之后给出真实验证证据。
> 如果发现本轮需要越界，我会暂停并回到治理门，而不是自行扩面。

## 3. 五道治理门

### 3.1 开工门：实现契约 (Implementation Contract)

任何非平凡实现开始前，AI 必须先写清楚本轮执行卡。

至少要回答：

- 本轮是否已获得 architect sign-off
- 本轮唯一 authority 是什么
- 本轮目标是什么
- 本轮 owner 是谁
- 本轮真相层是什么
- 本轮允许修改哪些文件 / 模块
- 本轮明确禁止碰哪些地方
- 本轮 invariant 是什么
- 本轮验证方式是什么
- 本轮 stop-line 是什么

没有执行卡，不允许开工。

但执行卡一旦回答清楚 authority、goal、write set、forbidden scope、verification 和 stop-line，就视为开工许可证。

除非发现新的高风险冲突，否则 AI 不得继续用新的 docs-only 文档替代本应进入的 bounded implementation。

### 3.1.1 上下文装载门：上下文装载预算 (Loaded Context Budget)

任何实现前都需要先确认上下文装载是否已满足，不允许为了省心把所有上下文一次读完。

- 必读：本轮 authority、当前 execution card、相应 closure、影响文件与当前变更相关的核心源码。
- 可选读：同 owner 相关的前序 plan（按需）、相关平台前置文档（按需）。
- 禁止默认读：无关模块、历史无关 closure、未授权的完整路径文档。
- 如果 required reads 超过 5 个文件，必须在 execution card 里明确 justification。
- 建议默认预算为 `<= 5` 个关键文档。
- 本条目与本仓颉项目治理策略联动：[CJGUI_CONTEXT_LOADING_POLICY.md](./CJGUI_CONTEXT_LOADING_POLICY.md)。

### 3.1.2 意图门：先判定是审查还是执行

除非本轮任务明确是治理审查（review-only）或文档梳理（docs-only），否则默认进入实现轨。

- 含 `bounded implementation`、`first slice`、`W1`/`W2` 的卡默认按实现处理。
- 含 `review` 且不带实现授权语义的卡，默认走审查，不产生行为代码变更。
- 无明确 authority + no behavior 时，默认停在 docs-only。

### 3.2 写码门：修改范围 (Write Set) 与差异预算 (Diff Budget)

AI 写码时必须满足：

- 只在批准的 write set 内修改
- 默认只做一个 bounded slice
- 默认不能顺手加新抽象
- 默认不能顺手重命名大范围符号
- 默认不能把局部问题扩成跨 owner 改动

建议默认预算：

- 单轮只处理一个明确目标
- 单轮默认只动少量文件
- 超出预算就必须暂停并重新走 docs-only gate

这里的重点不是卡死文件数量，而是防止“写着写着变成另一项工作”。

### 3.2.1.1 内部概念切片优先，不按单个符号切碎

W1/W2 internal concept slice 不要求 one-symbol 切割。

只要 write set、stop-line、verification、owner/truth 约束不变，允许在单轮内一起完成同一 internal 概念内的以下项：

- type
- field / fact
- construction shape
- no-op
- 极窄 marker transition

“写的更多行”本身不是风险指标，越界风险由语义和边界决定。

### 3.2.1.2 低风险 internal-only work 可 bundle

低风险 internal-only runtime work 可以用一张 bundled execution card 授权完整内部概念，不应默认限制为一轮一个函数或几个小字段。

常用粒度：

- `W2 internal behavior bundle`：一次完成一个完整内部行为概念，通常包含 3-7 个相关 internal changes。
- `W3 internal subsystem draft bundle`：当 owner、truth、write set、verification 与 stop-line 都清楚，且仍完全 internal-only 时，一次完成一个内部子系统草案，通常包含 6-15 个相关 internal changes。

如果 bundle 被拆成多个 slice，每个 slice 必须独立跑 build / smoke / `git diff --check`；slice 后可先只写 tracker 简短日志，bundle 结束后再写 mini-compaction / bundled closure。如果 bundle 是单次完整实现，可以在实现结束后统一验证并写 bundled closure。

bundle 不能绕过 public API、public C ABI、platform bridge、event loop、queue / drain、handle table / generation、跨 owner truth 或安全边界；触碰这些边界时恢复单卡单 closure。

### 3.2.1.3 helper 链封账后必须提高实现粒度

如果一条 internal-only runtime 线已经通过 helper / sanity / parity 证明了最小链路，后续不应继续默认新增单个 helper。

下一张 W2 / W3 bundle 应优先授权完整 internal behavior concept 或 internal subsystem draft，例如：

- 1-3 个 internal type。
- 2-5 个 internal function。
- 必要 constructor / builder。
- positive / negative path。
- sanity / parity check。
- bundled closure。

W3 internal subsystem draft 可以更大：允许 3-6 个 internal type、5-12 个 internal function、多个 ready / blocked / input / policy / outcome path，以及一份 bundled closure。它仍不等于放开 public API、public C ABI、platform bridge、event loop、queue / drain 或 handle table。

只要仍是 internal-only，且 owner、truth、write set、stop-line 和 verification 清楚，就应该让执行 AI 一次完成完整内部行为概念，而不是每轮只写十几行辅助函数。顶级模型的能力应被用来完成清晰边界内的完整概念；治理只负责防越界，不负责把实现切碎。

### 3.2.1 实现偏置：边界清楚后默认写代码

当本轮已经具备以下条件：

- owner / truth 已冻结
- write set 已冻结
- forbidden scope 已冻结
- stop-line 已冻结
- verification 已冻结

下一步默认应进入 bounded implementation。

只有在发现下面情况时，才允许回到 docs-only：

- 代码现实与文档冲突
- 必须触碰未批准文件
- 必须改变 public API / owner / truth
- 必须引入新依赖、迁移、系统权限或平台桥接
- 当前验证条件不成立，且不能通过窄实现解决

否则继续写 preflight / execution card 属于治理反噬。

### 3.2.2 纯注释 (Comment-only) 不能冒充实现

除非任务本身明确是文档或注释整理，`comment-only` 不得计为 implementation。

如果任务名称包含 `implementation`、`first slice`、`bounded implementation` 或 `runtime slice`，则必须至少产生一种真实行为变化：

- 可编译的仓颉类型、函数或内部结构
- 可运行的 smoke / harness
- 可测试的错误分类、状态转换或输入输出变化
- 构建系统可见的 package / module / entry 能力

只有注释、README、stop-line 或计划文档变化时，必须如实称为 docs-only，不得称为 implementation。

### 3.2.3 注释与文档语言：中文优先

文档和注释默认中文为主。

- 命令、符号、类型名、协议名可保留英文。
- 术语可给出中文解释 + 英文原词。
- 避免为了“统一风格”将中文说明改写为长英文段落。

### 3.3 尾部治理门：尾部影响扫描 (Fallout Scan)

这一步专门防你说的“顾头不顾尾”。

AI 在完成实现前，必须回答：

- 当前改动是否影响公共 API？
- 是否影响已有 read surface？
- 是否影响事件流、状态流、渲染流？
- 是否影响 owner 或真相层？
- 是否把平台细节泄露到了上层？
- 是否制造了第二真相源？
- 是否需要同步补测试、示例、文档、账本？

如果这些问题没过，就不能宣称完成。

### 3.4 验证门：验证包 (Verification Bundle)

AI 不能只靠“代码看起来对”结束任务。

至少要做：

- 编译或静态检查
- 与本轮相关的测试
- 最小 smoke 验证
- diff 自查
- 边界自查

对于 GUI 相关实现，下面这些也可以作为验证证据：

- 截图对比
- 人工视觉检查记录
- 人工交互检查记录
- 窗口打开、关闭、resize、点击、键盘输入等最小操作记录
- 渲染结果是否为空白、错位、闪烁、重叠的检查记录

如果某项没法做，必须显式说明：

- 哪项没做
- 为什么没做
- 这会留下什么风险

### 3.5 封账门：封账 (Closure) 与账本更新

实现完成后，必须说明：

- landed code reality 是什么
- 本轮 invariant 是否成立
- stop-line 是否守住
- 哪些残留问题没有做
- 后续不能误以为这条线已经完整解决

必要时同步更新：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- `docs/plans/*-closure-review.md`

## 4. GUI 项目专属的必查项

下面这些是 GUI 项目里的高危尾部，AI 每次写完都要扫一遍。

### 4.1 平台细节是否泄露到了公共层

例如：

- 原生平台对象出现在上层 API
- 平台专属事件语义直接暴露给 widget 层

### 4.2 状态真相是否被渲染层篡改

例如：

- 渲染缓存自己保存 UI 真相
- 渲染结果反向成为状态来源

### 4.3 入口层是否开始反逼底层

例如：

- 为了让 demo 好看，强迫底层适配一个并不真实的 API 形状

### 4.4 布局是否被写死在控件里

例如：

- 控件实现里出现大量绝对坐标和 parent hack

### 4.5 是否过早打开文本 / 输入深渊

例如：

- 明明在做事件或绘制，却顺手开始做输入框

### 4.6 demo 是否被错当成成熟能力

例如：

- 一个样例跑通，就把系统判定为稳定

### 4.7 视觉和交互是否真实可见

例如：

- 程序编译成功，但窗口没有实际显示
- 渲染命令生成了，但屏幕是空白
- 点击事件存在，但人工交互没有验证
- resize 后出现内容错位或重叠

GUI 项目的验证不能只停在代码层。
只要本轮涉及窗口、渲染、输入、布局、控件，至少要留下一个视觉或交互层面的验证证据。

### 4.8 仓颉语言知识是否经过查证

AI 在仓颉 GUI 项目里写代码时，不能只凭模型记忆判断仓颉语法、FFI、`cjc` / `cjpm`、标准库、构建参数或工具链 workaround。

默认查证规则：

- 普通 docs-only、Objective-C bridge、日志 harness 或治理更新，不需要每轮读取 `CangjieSkills` / `DocFlow`。
- 一旦任务涉及仓颉语言语法、FFI、`cjc` / `cjpm`、标准库或工具链 workaround，执行 AI 必须按需查证本项目文档、本地官方文档、已有 smoke demo 或相关 skill。
- `CangjieSkills` 已作为本地辅助 skill 接入 `/Users/jiangxuanyang/.agents/skills`；`DocFlow` 当前没有 `SKILL.md`，只保留为 knowledge / tool repo。
- `CangjieSkills` / `DocFlow` 不作为每轮 execution card 的强制必读入口。
- 读取 skill 时只读取与当前不确定点相关的小节，不全文翻阅，不让外部 skill 扩大本轮 write set。
- 本项目真相源仍是项目文档、本地官方文档、已验证 smoke / harness 和当前 execution card；skill 只提供辅助解释和补充样例。
- 凡进入代码实现的仓颉语法、FFI 或工具链判断，最终必须通过 `cjc` / `cjpm`、smoke 或对应 harness 验证。

## 5. AI 的默认暂停条件

AI 一旦遇到以下任一情况，必须暂停：

- 当前代码现实与文档判断冲突
- 当前修改开始越出 write set
- 当前问题需要改 owner / truth / public API
- 当前问题开始碰跨平台抽象
- 当前问题开始碰 `Input` / `IME` / 无障碍
- 当前问题需要引入新底层依赖
- 当前问题无法在本轮 bounded slice 内收口

暂停后不能自己偷偷扩面，只能回到 docs-only gate。

但暂停不是默认选择。

当执行卡已经批准且未出现上述暂停条件时，AI 必须继续推进受限实现，不得因为“继续写文档更安全”而停在 docs-only 循环。

## 6. 完成定义 (Definition of Done)

后续任何 AI 说“做完了”，至少要满足下面 12 条中的适用项：

1. 本轮 authority 和目标清楚
2. 改动没有越出批准边界
3. owner / truth 没有被破坏
4. 没有制造第二真相源
5. fallout scan 做过
6. 验证做过，并说明了未做项
7. stop-line 守住了
8. 必要的文档 / 账本 / closure 已同步
9. 如果任务叫 implementation，必须有真实可编译、可运行或可验证的行为变化
10. 如果本轮只改文档，必须明确称为 docs-only，不能冒充代码进展
11. 本轮上下文装载符合 [CJGUI_CONTEXT_LOADING_POLICY.md](./CJGUI_CONTEXT_LOADING_POLICY.md)，没有用过量阅读替代实现
12. 新增注释和项目文档默认中文，必要英文技术名词保留原文即可

## 7. 最推荐的协作模式

如果后续仍以 AI 主导开发，我建议默认采用：

- 一个 AI 做实现
- 同一轮结束后，再做一次独立 review pass

即便 reviewer 仍是 AI，也比“写的人自己立刻宣布没问题”稳得多。

实现 AI 要负责：

- bounded implementation
- verification bundle

review AI 要负责：

- fallout scan
- owner / truth / projection 检查
- stop-line 检查

## 8. 一句话目标

这套代码质量治理机制的核心目标不是拖慢 AI，而是防止 AI：

- 修头不修尾
- 修一点烂一片
- 把局部补丁误当成结构收口
- 在底座未稳时过早抽象

一句话：

> 后续 AI 不是“会写代码就行”，也不是“只会写文档就安全”，而是必须在明确边界内写代码、写完能验证、验证后能封账。
