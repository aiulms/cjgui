# DS50 施工图：把运行时界面编辑做成可复用的文档工作区

日期：2026-10-24。执行者：用户启动的 DS，统一负责原 C 的 Python、公共声明、消费者与唯一 SDK。本文件是完整实施任务，不另建执行卡；按阶段连续完成，最后集中交付。

## 1. 目的与这次的取舍

开发者应能把“保存界面、查看变更、载入或恢复、处理冲突、继续编辑业务”作为一个可选公共组合接入应用。人在界面里操作与外部工具操作使用相同的结构语义和真实票据。换一个业务，不再复制一套五按钮控制器、提交状态机和文件启动分支。

DS49 的严格读取、真实多对象接入、Select 去重和 mixed 正常链保留。本包不是重做这些能力，也不是继续给空 rules 区域增加通过日志。先修本次复核确定的事务缺口，再交付公共文档命令/状态/预览组合，接入两个**非空、普通导航可达**的业务工作区，完成离线保存、重开和运行中交换布局的完整用途。

这推进首版的公共接入与交付能力。Sol 同时处理 owner 调度、焦点返回和普通负载成本；Linux/C/H/W 不恢复。不加新控件名清单、第三款展示应用、文件监听器、脚本引擎或模型服务，不把 16/32ms 性能门改成 DS 责任。

## 2. 最小输入与已经可复用的资产

先读根 [AGENTS](../../AGENTS.md)、[ACTIVE](../../runtime/cjgui/ACTIVE_DIRECTION.md) 的 DS/Sol 段、本文和直接相关源码。需要理解归属时按 [设计导航](DESIGN_INTENT_INDEX.md#shared-code-entrypoints) 局部查阅，不读全部历史。

- 当前交付：[DS49 SDK](../../runtime/cjgui/artifacts/ds49-public-workbench-20261024/sdk/)，content `eea7a7425741018dcbecc0621aaf921cfd9aaefffc5da9e65cb9d82faba8bcfc`；manifest `5d8baee0b11cf265201048f67a8785cd7e6a2166730958aa453d9dcc68c7eb5f`；596 项、闭包 573。指导逐项复算文件大小/哈希一致，未重建该包。
- 指导原件：[review evidence](../../runtime/cjgui/artifacts/ds49-public-workbench-20261024/evidence/guidance-20261024/)。无窗口小反例直接链接既有框架产物，操作受控 `CjguiUiDocumentSurface`；它不是应用 GUI 证据。相关 session/loader/adapter/Python 源与 SDK 相同，见 `package-check.json`。
- 共同文档：`src/composable_ui_ui_document.cj`、`composable_ui_ui_document_session.cj`；Python `shared_operation_core/cjgui_ui_document.py`、`cjgui_generated_edit.py`、`cjgui_generated_client.py`。Python 已有 candidate/expected 区分、merge/replace、票据查询和原子读回；仓颉 region/holder 已有提交、逐票据状态、接受/拒绝/替代结算。**复用这些事实，别再写一个以正文相等推断成功的分支。**
- 界面：`composable_ui_common_controls.cj` 的 Select，既有 CommandToolbar/CommandPalette/ContextMenu、IdentityScope、Scroll、Split、Tabs、反馈组件和 workspace registration。只做薄组合，不新增“文档工作台”节点解释器。
- 对象：`composable_ui_generated_multi_object.cj`、generated range session/form binding、region accepted owner/incarnation。业务仍归 mixed domain/preset cards 与 rule-set domain。
- 消费者：`templates/macos_application/mixed_form/src/`，`examples/rule_set_window_app/src/`。rules 已有公开生成结构、组合定义、实例和票据路径；DS46 曾有非空结构消费。当前空面是接入未完成，**不需要扩 native 才能接通**。
- 已接受 runtime：本次 SDK 与根 `composable_ui_window.cj` 都是 `a528090711c67e7839e9941c496d39ddded13da166066b7748b5314eaa8eb55d`，已经含 Sol 的本地预算让出续行。不要重复打 d3bd→a528 补丁。后续只接明确交接增量。

## 3. 复核结论：什么保留，什么必须改

### 3.1 保留的有效交付

Python 原两处 RED 的精确类型/expected 摘要守卫已修，17 项文档测试指导复跑通过；有界仓颉读取与 loader 探针、mixed/rules 正常链按报告原范围保留。公共多对象适配确实出现在两个生产构造点，不再只是 FakeObject。Select 重复 host/命令已修，包身份一致。无需为这些无改动部分重新跑整套历史矩阵。

### 3.2 文档会话不能自行猜票据结果（优先级最高）

`CjguiUiDocumentSurface` 现在只有 accepted 文本与 submit；session 没保存返回 token。`verifyReload` 用 `accepted.digest == pendingFileDigest` 宣布成功。指导反例实际输出：

```text
CONFIRM_1=submitted
CONFIRM_2=submitted
SUBMISSION_COUNT=2
UNCHANGED_VERIFY=false
CANCEL_AFTER_SUBMIT=cancelled
UNRELATED_SAME_BODY_VERIFY=true
UNRELATED_STATUS=...已载入 v9...
```

含义：尚未接受时确认两次会重提；提交后的取消只清本地记录，并不撤销候选；另一笔操作接受相同正文也会被认成本次成功。若本票据已拒绝而 accepted 未前进，现有接口甚至无法观察拒绝，session 可永久等待。旧探针在 submit 内立即改变 accepted，掩盖了这个边界。

这是公共会话的实现缺陷，不是测试需要多等。让 session 观察 region/holder 已有的真实结算，不能靠延时、补输入、轮询次数或“版本大于基线”修复。

### 3.3 预览与实际操作不是完整同义

- `confirmReload` 直接提交文件正文；文件省略定义在生产协议里是**保留**。`cjguiUiDocumentDiffLines` 却把当前有、文件没有的定义显示为“移除”。恢复也直接走这条路径，可能保留本应恢复时删除的额外定义，随后报摘要不一致。
- diff 不表示同父子顺序；指导将 a/b 互换，只得到“节点数 3 -> 3”。定义 facts 只取参数名、部分元素字段和部分 template 字段，漏掉类型/默认值/约束、gap/padding、presentation 等实质改动。
- Python v2 保存计划的 `removals=[]` 被当作“不检查”：指导将合法 replace 计划的非空 removals 改成空数组，仍被接受并重建出 REMOVE。正文摘要守卫仍在，因此这不等于任意改写正文；但“保存的事实逐项一致”不成立。v2 的显式空列表与旧 v1 缺字段须区分。

### 3.4 第二业务的交付还未成立

DS49 rules 真链验证了已有生成对话框的 notes，主生成 region 却是 `STRUCTURE 0`。空文件重开只打印 `LOADED empty=true`，没有证明工作区的非空文档保存/重载、A/B 生成实例或模型改版。这不能替代上一施工图 C3/D2 的正常生成详情。

同时，`ruleUiDocumentHasNodes` 的空启动快捷分支只看 NODE/版本0，不能把“有定义但无节点”的文件也当成已精确接受。空态合法应有准确含义；不要用空态分支绕过定义和 requirements 的准入。

## 4. A：收敛公共文档事务，先建立一个正确内核

### A1. 同一预览同时给出候选和完整预期

不要把 JSON 文件或 rendered diff 当权威。根据 **当前 accepted 完整文档 + 当前目录 + 文件 + 显式策略** 产生不可变预览事实：基线身份/版本/摘要、输入文件摘要、候选文本与摘要、预期完整 accepted 摘要、定义新增/更新/删除和节点/绑定/顺序变更。复用现有编码/解码和候选规则，不加另一套组合 grammar。

固定策略含义：普通载入默认与 Python 一致，省略定义保留；“恢复已存界面”表达恢复完整保存态时，必须明确采用 replace，并在预览中列出 REMOVE。不要悄悄改变普通导入默认语义，也不要让预览说 replace、提交做 merge。选择了不同策略就生成新预览。

提交前复核当前基线、文件及目录仍能支持同一操作；业务数据变化不自动判结构 stale。真正的并发裁决仍是服务端现有 CAS。合并时文件摘要可能不同于完整 expected 摘要，必须分开保存、显示、比较。

**最小对照**：当前目录 A+B，文件只含 A 且无 B 实例。merge 预览/提交保留 B，replace 预览/提交显式移除 B；两者都有自己的完整 expected，均能正确结算。存在仍引用 B 的实例时整候选拒绝，不先删目录。

### A2. session 只拥有操作记录，holder 拥有候选结果

沿现有 region/holder 接一个必要的窄公共只读面：给定原 token，能获得真实 pending/accepted/rejected/replaced/closed 事实及该票据关联的版本/原因；需要和 accepted 内容比较的事实，在同一个 region 锁/既有原子快照内取得。优先复用已有类型；若补类型，标 experimental，并说明谁持锁、何时返回。不要把两次独立查询拼成“原子”。

session 记住原 token、提交预览及其所需生命周期身份。每次 finish 只查询，不重新 submit。临时未完成可保留记录；拒绝、替代、关闭都能终止等待并显示真实原因。相同正文、其他 token 或更高版本不自动证明本次接受。接受后已被后续更新替代时，报告原票据接受事实和当前已变更，不能混为失败或当前仍精确。

确认后按钮状态应防止重复提交；即使调用方连调两次公共 API，也不能提交第二张票据。预览阶段取消必须零提交；提交后若协议没有可靠取消能力，返回“已提交，不能取消预览”之类具名事实并继续保留可查询操作，不假称撤回。save/setPath/新preview同样不能无声抹去在途票据；按当前单操作范围明确拒绝或先结算，勿建无限历史。

`verifyReload` 需要区分“状态发生变化”与“本次 accepted”；消费者不能在任何终态变化时统一打印 `UI_DOCUMENT_ACCEPTED`。GUI 命令可用性和状态来自同一只读结果。

### A3. 完整可读差异和文件状态

差异必须覆盖本支持子集的全部语义：定义参数类型/约束/默认值、元素 field/action/role/presentation、模板布局属性、节点增删/移动/同父重排/绑定/属性。以规范编码/结构化事实比较，不用易碰撞的 `|` 拼串代替全字段语义。展示可以汇总，但不能把真正变化漏成“无变化”或“保留”。无需写一个通用版本控制 UI。

状态区分：文件路径/保存摘要、当前 accepted 摘要、是否有未保存界面变更、预览待确认/提交中/结果。普通 owner 草稿变化不把 UI 文件标脏；兼容结构变化会标脏。启动从文件精确接受后有正确保存基线。业务 dirty 继续由原 domain 决定，UI 状态不触发业务 Apply/Cancel。

修 Python v2 removals 的空列表检查，保留真实旧 v1 正控。原严格 JSON、读中限额、原子文件替换、unknown/lossy 不导出契约保持。不要为此扩成通用 JSON 安全工程。

## 5. B：新增可插入应用的公共文档工作区组合

现在两个消费者分别复制按钮、action 分支、状态文字和 finish 回调。待 A 的结果可被准确消费后，把**重复的框架接线**收成一个可选公共组合，应用只提供：surface/session、作用域身份、显式路径、主题与布局位置，必要的结果通知。应用保留自己的业务导航和关闭策略。

建议分清两层，名称可根据现有接口调整：

1. 文档命令投影：从同一个 session 生成保存、预览、确认、取消、恢复及其 enabled/disabledReason。复用既有 `CjguiComposableUiCommand` 与 invoke 路径，可放工具栏、命令面板、原生菜单。公共动作不能再在两个应用里各写一遍生命周期判断。
2. 文档状态/预览呈现：用已有布局、文本/列表、Scroll、反馈和 IdentityScope 组合。长路径、长原因和较多差异在窄窗能读到，预览与背景编辑的焦点契约沿现有层机制；不新增 native 对话框或独立编辑器状态机。

一个应用不启用文档能力时不产生额外文件、空闲 pump、后台线程或强制控件。两个作用域实例并存时命令、语义和状态不串，主题沿现有公共样式。不要再为“共同”造一个带打印卡片字段的万能 controller。

接入结束应能指出：两个消费者各自还保留哪些业务决策，原重复的框架分支被哪一个公共入口替代。构建行数不是验收，但不能只包住旧私有实现再称降低接入成本。

## 6. C：多对象公共适配的最后接缝与 rules 非空工作区

### C1. 适配器保住一致拒绝

DS49 field intent 已核 owner target、范围五项也已转发，保留。重点审已存在的不一致：`ownerBlockedReason` 在完整 action/field 分支判断，却未覆盖旧 action 重载、默认分支及 range 写入；`actionAvailable` 也可能与 availability 分裂。公共 API 不能因选择旧重载绕过自己声明的 block。写入仍最终交 owner 校验，不能把 UI enabled 当授权。

只修影响真实写入的守卫；读快照/rebase 是否可读按已有契约，别一刀切把只读事实全隐藏。region 的 owner/incarnation 仍唯一，禁止另加代次表。验证默认单 owner range、A/B 相同值/版本但不同 owner、同 key 退休后旧 session 的已有反例，等价绿证复用。

### C2. rules 的正常生成详情必须接通

沿 `CjguiRuleSetGeneratedRegion` 现有 submit/accepted/instances 路径，把开放区放进正常可导航页，或替换已有空生成页；**不要用原生成对话框代替它**。用已发布字段/动作/Select 和公共多对象 binding，建立 ruleA/ruleB 两个真实不同 owner 的可编辑实例。业务字段/校验/持久化继续原域，数据不会写进 UI 文件。

第一份结构可由应用用公共编码/提交给出默认文档，或由显式 `--ui-document` 提供；不是为这个布局再编一个专用工厂。后续经公共工具在运行中更新定义、布局或呈现，仍可编辑同一对象。文件为合法空面时如实为空；有定义的空面按真实协议处理，不能只打印 LOADED。

补一条 rules 非空用途：两条已有规则的不同未应用草稿 → 生成详情可达、notes/Select 与手写互见 → 保存界面方案甲 → 公开改成布局乙并保草稿 → 预览/取消 → 确认重载或恢复甲 → 继续编辑 → Apply/保存业务 → 关闭重开时布局与两份已应用数据各自精确恢复。A/B 授权、锁定/退休反例在该公开适配路径做一次，不能只给领域单测。

布局重载不改变选择的业务权威、不把 A 写到 B。已有滚动/reveal/Select/主题足够，保持低位字段可通过正常导航到达，不能靠 AX 直接操作屏外对象掩盖。

## 7. D：修正测试装配归因，集中跑有收益的验证

DS49 的 compile blockers 确实在用例执行前，不能写“新增单测已过”。但也不能全部叫 Sol 产品缺陷。当前原件分别是：

- Linux test 顶层 helper 使用 `CjguiLinuxWindowRequest` 却未带对应 `@When`；由 Sol 接测试目标装配的窄修复，不恢复 Linux 开发。
- Mac 多测试文件重复 foreign 声明与 Int32/Int64 宏断言类型；由 Sol 收到公共 testing seam。
- **本次编译接续已暴露的 DS 自身错误（2026-10-24）：**Sol 窄修上述公共装配后，冻结编译已跨过原错误；`src/composable_ui_ui_document_test.cj:27` 的 `uiDocumentTestWrite(directory: Directory, ...)` 接收 `Directory.createTemp` 返回的 `Path`，导致 line28 无 join、37/54/60/66/71/75/80 等调用报 `expected Directory, found Path`。DS 将 helper 参数改为真实 `Path`，保留全部断言与清理，并在恢复的 testing-link 入口执行该组；不要再归因为 Sol，也不要只删此单元绕过。指导已核源码与原始编译输出，摘录在 DS49 `evidence/guidance-20261024/document-test-type-error.log`。Sol 的独立小组可显式排除该未修单元，但该结果不是全库通过。
- Sol 已给 rules 两项 owner fixture/有界等待补丁，属于 **DS 消费者测试**：`continuation-consumer-fixture.patch`。采用受支持 fixture 和单调 deadline 等真实 accepted 条件，不能固定 pump 次数，也不能每例新进程来掩盖同进程故障。
- Sol 的清晰冻结窗口组是 87/5/0。5 项交 DS：image discovery 初始声明拒绝、declaration swap 初始拒绝、named-style 初始拒绝、文件头旧 v1 断言、组合预期版本3/实际2。先核实际 catalog/输入/版本推进，保留与纠正真实契约相符的断言；不能统一删除或仅改成当前值。

这些消费测试与文档工作可以继续，不等 Sol 全部性能通过。需要新 runtime 时只等具体增量。不要整文件覆盖或自行删掉 Sol 测试，然后对删减树宣布全库通过；定向闭包允许明确列明范围和未纳入项。

验证按一个汇合批次进行：

1. 将指导受控 RED 转绿，包含延迟接受/拒绝/替代、重复确认、提交后取消、merge/replace、重排/参数差异、v2 空 removals；这是当前修复依据。
2. 两端对同一组文件/预览语义一致；沿既有 Python 和仓颉 tests/runner，不新建一套测试工程。
3. mixed 一条最终链保留 A/B 草稿、人工范围输入和 Select，穿过文档冲突→拒绝→重新预览合法续行；不逐次小补丁重跑全链。
4. rules 完成 C2 的非空第二消费、业务保存/正常关闭/重开。旧绿色输入与 IME 证据可按版本复用，未改输入路径不重跑完整 IME/VO 矩阵。
5. 如尚需模型现场修改，复用 DS49 的目标与脚本入口，但从**当时** live catalog/snapshot 规划一次实际变化；不为增加“模型次数”重复已验目标，不称独立模型服务。

## 8. E：交付一个开发者可接入的版本

源码稳定后一次冻结唯一 SDK，沿 exporter/source-lock；先核 Sol a528 已在包内，再按明确交接纳入后续 runtime，不能把根树最新都自动当已接受。普通文档读写不需要额外平台包。

包根说明提供三条可运行入口：ui-only；mixed-form + 显式 UI 文档；rules 的非空生成详情与文档。补最小公共接线示例，说明应用的业务 owner/授权与公共工作区各做什么，给 named refusal 的恢复方式，不要求读本对话。

在包外含空格路径从最终 SDK 创建/构建一个消费者，完成文件重开→实际编辑→公共读回→正常退出。第二业务从同 SDK 构建并用短链确认，已有长链只在同源身份时复用。上一包消费者仅换依赖做适用升级，真不兼容则写最小迁移，不能暗改 src 后称无需迁移。

最终 RESULT 只汇总实际能力、相关反例、两条正常用途、唯一 SDK/锁/源身份、尚欠范围与容量。指南进入导出闭包；可运行候选和必要原件放稳定目录，不靠 `/tmp` 唯一副本。未达项不能因为做了五个阶段便称“全部端点完成”。

## 9. 写集、推进和容量

DS 写 generated/region/composition/common controls、多对象/文档公共层、Python、mixed/rules、相关测试、runner/exporter/文档。Sol 写 window/session/host/native/budget/prepared layout 与公共 testing seam。需要对方接缝时交具体符号/反例/建议窄差分；独立工作继续，避免反复搬运同义消息。不要复活 C 或 Linux，不开顾问/子代理，不做 Git 写操作。

先 A 的真实事务内核，穿插 C1 和测试消费修复；再 B 公共组合、C2 非空工作区，最后集中 D/E。这是可连续 goal 的整包，普通实现/构建/工具问题自主处理，不按文件请示。根因不明的实质 FFI/并发/重大数据风险按 AGENTS 集中升级，不盲叠补丁。

同 target 构建与桌面串行，保留用户实例。复用每消费者一个构建目录，不复制历史 target/artifacts。遵守 [验证投入](../../AGENTS.md#verification-value)和[容量规则](../../AGENTS.md#artifact-space-budget)：默认本线新增留存≤10GiB、峰后宿主≥20GiB；开大构建前核当前空余。只清本线确知可再生输出，原 RED/必要日志与最终可用包保留。收尾给新增、回收、留存理由和实际可用空间，不为凑轮数反复导出或测试。
