# 仓颉 GUI 项目 AI 代码质量治理

最后更新：2026-05-01

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

### 3.2.0 单文件体积门：防止巨型源码文件失控

AI 每次准备修改 `.cj` 文件时，必须把目标文件当前行数纳入风险判断。单文件过大往往意味着 owner、truth、subsystem、diagnostics 或 legacy tail 没有及时拆分。

阈值：

- `> 1500` 行：soft warning。允许修改，但完成汇报必须说明为什么继续放在该文件。
- `> 3000` 行：hard warning。默认不新增新的 subsystem；若继续新增行为，必须说明它仍属于同一 owner / truth，并记录后续拆分候选。
- `> 8000` 行或接近 `1MB`：critical warning。默认不得继续追加新行为；下一步优先做 owner split、module extraction、manifest / stabilization、tail consolidation 或 dead-helper cleanup。确需修改时，执行卡必须显式授权，并在 closure 中记录“为什么暂不拆”。

执行要求：

- 修改前：报告本轮触碰 `.cj` 文件的行数档位。
- 实现中：避免因为“加几行很方便”继续把新 owner / 新 subsystem 塞进已经过大的文件。
- 完成后：如果目标文件处于 hard / critical warning，closure 必须记录新增 / 删除行数趋势、是否产生新的拆分候选、下一次应优先拆哪里。
- 提示词中若允许修改 critical 文件，必须写出 `file-size / owner split check`，不能只写功能目标。

本规则不要求每次超过阈值都立刻拆分。它要求 AI 不再无意识地把大文件继续养大。

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

### 3.2.1.4 AI 资源效率门：禁止低风险链路长期小碎步

上下文装载、GitNexus、build / smoke、链接检查和人工复核都有固定成本。如果每轮都要求 AI 读取完整治理上下文，却只允许新增一个 value type、一个 builder 或一个 helper，会造成明显模型资源浪费。

后续执行卡和提示词必须遵守：

- 同一 owner、同一 truth、同一 write set、同一 stop-line、同一验证路径下，默认使用 W2 / W3 bundle，而不是 one-symbol slice。
- 连续两个 implementation 都是“单薄 projection / record / helper”后，下一轮不得继续自动新增同类薄层；必须升级为 same-owner bundle、做 tail consolidation，或进入 manifest stabilization。
- 禁止把 `no action execution`、`no queue`、`no provider` 等 stop-line 误解成“只能写几十行”。这些 stop-line 只禁止越界 side effect，不禁止在同一 owner 内完成完整 internal value pipeline。
- 执行卡应尽量描述目标、输入、输出、invariant、stop-line 和验收标准，而不是把实现降格成固定 symbol 清单填空。可以给建议 symbol，但不应把建议写成唯一允许路径，除非该符号名本身就是 public / interop / compatibility contract。
- 同一 owner 内允许 AI 自主选择更合适的拆分、合并、删除低价值 helper、补维护注释或更新 manifest；只要不越过 stop-line，结构复杂度可以放开给模型发挥。
- docs-only decision 不能作为每轮代码后的固定拍子。只有 owner、truth、write set、side effect、public surface、platform、queue / drain、scheduler 或 runtime cycle 边界变化时，才需要新的 decision。
- closure 必须说明本轮粒度是否匹配上下文成本；如果读了多个治理文档却只改了极少代码，需要说明为何不能 bundle。

例外情况：

- 高风险边界第一次打开。
- 必须触碰 hard / critical 大文件且 owner split 未清楚。
- GitNexus 返回 HIGH / CRITICAL。
- 需要 public API、C ABI、platform bridge、queue / drain、event loop、scheduler、runtime cycle 或 global state write。

简化判断：

- 可以放开：同 owner 内的完整 internal design、tail consolidation、behavior-preserving cleanup、注释补账、manifest 同步、policy / readiness / blocked reason 的成组建模。
- 不能放开：跨 owner truth、真实 side effect、public surface、平台桥接、queue / drain、event loop / scheduler、runtime global state、critical 大文件无授权增长。

### 3.2.1.5 Tail Endpoint Exit Gate：canonical endpoint 后必须换挡

AI 资源效率门解决的是“不要切太碎”；但仅仅把 one-symbol 改成 W2 / W3 bundle 还不够。如果同一 owner 内的 value tail 已经到达 manifest 标记的 canonical endpoint，继续追加 `readiness -> record -> outcome -> publication -> handoff -> record` 这类同构 value-stage，仍然会形成漂亮但空转的尾巴。

当 manifest、tracker 或 closure 已经标记某个 symbol / default draft 为 canonical endpoint 时，下一轮不得默认继续在同一 owner 末尾新增薄层。下一轮必须在以下出口中选择一个：

- **downstream consumer / handoff integration**：让另一个 owner 或既有下游边界消费该 endpoint。
- **permission gate decision**：如果确实准备靠近真实执行，先建立极窄 permission gate，并说明仍禁止哪些 side effect。
- **milestone closure / manifest stabilization**：明确该 tail 暂时封账，后续不再本地自包。
- **tail consolidation / deletion**：删除、合并或标记 legacy-only / diagnostics-only tail。
- **real boundary execution card**：只有在 stop-line、write set、verification 和回滚/失败路径都清楚时，才打开真实 side effect 前置卡。

如果 AI 仍想在同一 owner 后面新增本地 value-stage，必须回答：

- 为什么现有 canonical endpoint 不能被下游消费。
- 新 layer 是否减少重复、合并结构、承载新的不可替代 truth，或打开新的高风险证据门。
- 为什么它不是把上一层 Bool / defer / blocked summary 原样改名搬运。
- 本轮新增后新的 exit 是什么；不能只写“下一轮继续 boundary decision”。

如果回答不了，默认停止新增 tail layer，转向 handoff consumer、permission gate decision、milestone closure 或 consolidation。

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
- 新增代码注释默认必须使用中文；必要英文技术名词可以保留原文，但解释句应使用中文。
- 若 AI 生成了英文代码注释，交付前必须改成中文，除非该注释是在引用外部 API 原文、编译器原文、协议字段名或错误信息。
- closure review 必须说明新增关键维护注释是否符合中文优先；若保留英文注释，必须说明原因。

### 3.2.4 代码注释充分性门：关键语义必须可维护

AI 不应把“避免空注释”误解为“尽量不写注释”。本项目的 internal runtime 链路有大量相似的 value-style stage、fail-closed 分支和 stop-line，缺少关键注释会让后续维护者无法判断这些结构为什么存在、为什么不能合并或为什么不能执行真实 side effect。

必须写最小维护注释的场景：

- 新 owner file 顶部：说明该文件拥有的 owner / truth，以及明确不拥有的边界。
- 新 internal runway 的关键 boundary type：说明它消费哪一层、产出什么 summary、不是哪种真实行为。
- fail-closed / inconsistent 分支：说明为什么选择 blocked，而不是 silently defer 或 accept。
- default draft / default executor：说明它只是 draft / summary path，不是真实执行、真实 queue 或真实 platform call。
- 临时 workaround、上游限制、语言 / 工具链规避：说明移除条件。
- 名称相近但语义不同的 stage：例如 `Plan`、`Convergence`、`CommitCandidate`、`Finalization`、`Record`，至少在链路入口或关键类型处解释差异。

不要求注释的场景：

- 机械字段赋值。
- 纯 derived helper，且函数名已经完整表达投影含义。
- 简单 builder 中与类型字段一一对应的构造。
- 重复粘贴 README / manifest 中已有的长 stop-line。

执行要求：

- 新增或修改 `.cj` 时，执行卡 / 提示词应提醒检查注释充分性。
- closure 必须说明本轮是否新增了关键 owner / boundary / fail-closed 语义；若有但没有补注释，应解释原因。
- `comment-only` 仍不得冒充 implementation；维护注释是实现质量的一部分，不是单独进度。

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
- 本轮是否遇到仓颉语言 / SDK / FFI / 工具链 / 文档问题；如果遇到，是否已经更新上游问题账本或说明暂不入账理由

必要时同步更新：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- `docs/plans/*-closure-review.md`
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)

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

### 4.9 仓颉上游问题是否进入贡献闭环

CJGUI 开发过程中遇到的仓颉语言、SDK、FFI、工具链或文档缺口，不能只在当前线程里口头记住。

AI 在 closure 前必须做轻量判断：

- 本轮是否出现新的仓颉上游疑点。
- 是否需要最小复现、issue draft、文档建议或能力反馈。
- 是否已经更新 [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)。
- 如果没有更新账本，原因是否清楚：误用、本机环境、无稳定复现、只属于本项目代码问题，或本轮没有相关问题。

这个检查不要求每轮都读完整账本；只有触发仓颉语言 / SDK / FFI / toolchain / docs 问题时，才按 [CJGUI_CONTEXT_LOADING_POLICY.md](./CJGUI_CONTEXT_LOADING_POLICY.md) 读取相关章节。

### 4.10 Draft / Sanity 是否正在反客为主

AI 在 runtime execution tail 上写代码前，必须检查本轮是不是又在新增纯 wrapper 或重复 sanity。

如果本轮新增的是 `Draft / Report / Request / Outcome / Observation / Feedback` 类符号，必须说明：

- 它是否直接接入已有 state / cycle / owner 边界。
- 它是否删除、合并或替代了已有 wrapper。
- 它是否减少了重复 Bool、重复 sanity 或重复 trace。
- 为什么不能复用已有 report。

如果本轮新增的是 `Sanity` helper，必须说明：

- 它覆盖了哪个新的行为分支或新 blocked path。
- 为什么现有 build / smoke / helper 不能覆盖。
- 为什么不是复制已有五件套。

如果回答不了，默认应该停止新增 wrapper / sanity，转向 model compression、owner cleanup、execution convergence 或 tracker compaction。

### 4.11 Canonical Tail 是否正在自我包装

AI 在同一 owner 的 action / runtime / ingress tail 后继续写代码前，必须检查当前 manifest 是否已经声明 canonical endpoint。

如果已经声明 canonical endpoint，下一步默认不是“再加一个本地 tail value”，而是：

- 下游 owner 消费；
- permission gate decision；
- milestone closure；
- tail consolidation；
- 或真实边界前置卡。

只有当新增层承载新的不可替代 truth 时，才允许继续本地追加。单纯把 `didX / shouldDeferX / shouldReportBlockedX` 改名投影到下一层，不构成新的 truth。

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

后续任何 AI 说“做完了”，至少要满足下面 14 条中的适用项：

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
13. 如本轮触发仓颉语言 / SDK / FFI / 工具链 / 文档问题，必须更新 [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md) 或在 closure 中说明不入账理由
14. 如本轮新增 pure `Draft / Report / Request` 或重复 `Sanity`，必须说明它不是治理反噬；否则优先执行 compression / convergence

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
