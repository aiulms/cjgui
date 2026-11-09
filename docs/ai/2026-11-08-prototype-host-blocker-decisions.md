# 通用原型宿主与 macOS 首版候选：完整实施提示词（唯一目标）

工作目录：/Users/jiangxuanyang/Desktop/cangjie。指导更新：2026-11-09（§17.6复核接受H5-B后续修复与同源SDK，本轮收口；目标内自主修复与反馈规则保留）。

**继续原有“通用原型宿主与 macOS 首版候选”这一个目标。本文件完整包含当前基线、授权、验证、原型消费与反馈要求，无须拼接旧提示词或聊天，不另建目标或执行卡。**

**当前授权：继续同一个原型宿主与macOS首版候选目标，保留H1/H2及已经取得的H3–H5成果。H3–H5是既定交付项，不再是排他的修复白名单。开发模型对当前目标内新发现及反馈返回的问题，自行核实、归因、修复、验证并回接skill，不必先等指导逐项认可。具体工作方式和实质升级边界见§3.1。影响SDK输入的修复在汇合时统一入包并做受影响包外消费；已绿且未受影响的VO/性能矩阵不重开。**

**当前审阅结论：§17.6。** 上轮§17.2/§17.3指出的样式复制、纵向END、native文字复用及暗色详情可读性问题，已由§17.5交付修正并通过本次有限复核。本轮H5-B收口，保留H1–H5已验范围，不按历史失败段重新开工。当前SDK为`ec9237f6…`；§2、§17.1及旧图保留历史身份，不能代替新候选。候选仍experimental，不把本轮完成扩大为成熟首版、全平台或全部未证边界通过。

指导本次只维护授权与任务文档，未代替执行者改产品。**用户本次指令取代本文件及旧聊天中“新发现只记录”“仅修指导认可问题”的常规前置限制。** 指导负责方向、实质取舍与交付复核，开发模型负责日常问题的判断、实现、自验和反馈闭环。执行者在切换工作或集中交付前重读本文件；遇到不一致的旧条文，以本段和§3.1为准。

## 1. 唯一目标

把当前通用原型宿主及其公共子集收束为可独立接入、可分发、证据可复核的 macOS 首版候选：保留已验修复，完成本文件批准的剩余问题，保留同一二进制的三个声明原型与人/AI共同操作，完成受影响 HTML 对照；将修复汇入同源 SDK，用已有包外独立应用消费；补齐真实 VoiceOver 连续链与普通负载的资源、延迟证据；通过现有 skill 结构化反馈新发现，最后集中交付实际结果。

“修复 → 验证 → 原型消费 → SDK/包外消费 → 无障碍与性能 → 反馈”属于同一个目标。当前 SDK 和独立应用已交付，继续其受影响链，不重新做一套。仍是明确支持范围的候选，保留 experimental/additive_only；不靠改标签承诺 stable API、稳定 ABI、完整 HIG、长期稳定或正式发布。

复用 CJGUIPrototypeHost、settings/assets/materials、readonly-demo、split-demo、HIG 主题、catalog/region、真实 owner、NumericStepper、文档工作区、session v2、公开 Python 客户端、导出器/建项工具及已有测量驱动。手写/生成/混合消费共同声明；不另造 UI 运行时、owner、协议、打包或监控平台。外部框架只借鉴实现，不引入依赖。

执行者自主完成目标内归因、实现、自验与集中交付，不逐问题、符号或文件请求批准。新发现按§3.1处理；skill分类是带依据的筛选记录，不能替代开发者的事实核实，也不构成额外审批。只暂停确实依赖实质阻塞的问题，其余工作继续。

## 2. 当前基线与指导验收

先读[AGENTS](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md)、[ACTIVE E线](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/ACTIVE_DIRECTION.md)、本文件及直接相关源码。指导已复核基线为[§48](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-delivery.md#48-h1三项收口h2离线更正与最终候选续交2026-11-09)及§49裁定；H3最新执行交付见同一报告§50和ACTIVE，本次授权更新不重验、不覆盖其新证据身份，不从头重放旧计划。应用部分加载[cjgui-app-dev](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/skills/cjgui-app-dev/SKILL.md)核实际依赖，仓颉实现按[cangjie-coding](/Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md)。

| 产物 | 指导当前实核身份 |
| --- | --- |
| 宿主bundle | `93562f0305ef6c4a512b93580346ee703225a1dc38154367e4a549efe6922444`；native `4f53174c6f3f2d0a6aceab7530ace0b0acd8deba785eee82d3e785f984bbfeaf` |
| 实际SDK ZIP | `156c30604a69953a275a75710c90494750a6131565548204e57d7fc75324f06f`，6,455,934字节；640文件逐项匹配 |
| source-lock | `9345b9f1fbf14edad7d4168e6d753022a7adc8e46d9ed35d2159f66eb2a78588`；613源输入匹配，prototype_host_app不在SDK闭包 |
| exported content | `9feb19cbede8ae65c18f1d765400b39350ed39df4b87a376d64d79b4d618e9da`；包外从ZIP安装目录640文件一致 |
| 包外InspectionCandidate | `a6aa5d4fe71ad4ec360bbb2ca620f41f9c3b0a50e6416933a298d5ac2e3ae938`；native `4c251896cc497f8151bbfd2fb1ed96f178aae4d8ef59dc9faca089b7efea1172` |
| 构建来源 | 宿主483源/465准备源/2原生库，包外458/440/2，当前哈希均匹配、testing=false |

[本次指导复核原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-48-20261109.json)含身份核对、H1证据范围、H2独立复算和H3精确源码链。本次未新运行GUI/构建；H1真实VO原件来自对应执行候选。旧b0276dde/51687252等仅为历史基线，不能再称当前包。

已验收：H1精度/作用域/viewport换绑的实现级RED/GREEN和公共消费2项，宿主及包外真实VO读24、正确字段VO选“泵”与range3,1、viewport/AX/画面对应及短静置计数；H2同原数据43有效/17未证，native commit→present p95=26.193501ms/max29.235459ms。43是有效子集，不作全60或端到端p95。最终SDK与包外消费也已闭合，不再重复这轮修复。

materials、深色样式、保存计划、SDK锁、A–F、旧应用/客户端测试、30+30局部p95、暖机首交互约1.195s、load5、三原型与未改HTML旧链按原版本/范围保留。仍为experimental/additive_only，不新增真人、完整IME、长期稳定、全平台、完整HIG或光子级门。包外继续复用既有目录 `/Users/jiangxuanyang/Desktop/CJGUI Prototype Candidate Consumer`，无需新建第二个消费者。

## 3. 本次接续范围与授权

继续同一个原型宿主与候选目标；既定交付为**H3恢复绑定（§9.1）、H4整窗布局与默认配方（§15）、H5列表裁字与按钮文字对齐（§16）**。已完成部分保留证据，继续尚未完成项；当前开发、正常消费和反馈中遇到的相关真实问题一并自主处理，不限于这些编号，不另建目标。

H1/H2及其SDK和包外消费已验收，后续保留。§7/§8留存历史方案与证据边界，不是重做清单。修复应落在实际责任层：宿主接线、共用组件/布局、生成消费、必要native适配及当前交付工具均可按§3.1自主处理；不能为少改框架而在每个应用重复绕过，也不能把应用误用直接改成全局默认。沿现有工具更新锁和包，验证以实际影响为准，不重跑未受影响的VO、30+30、load5、全尺寸HTML、全平台或无关历史矩阵。

若某个反馈反例因已有保护不成立，给出保护入口与原结果并更正归因，不为满足问题描述硬改。证据不足先做能区分原因的核对；核实后自主修复，无法确定或不值得在当前目标内扩展的，记录理由与下一步。实质范围/架构/兼容性取舍按下节集中升级，不因触及核心文件或收到新的issue就停工。

不改skill、不升级小说工作台、不恢复其他平台、不扩控件/渲染工程；不stage/commit/push、发布、建第二目标或用户线程、启动额外代理/外部顾问。

### 3.1 当前自主修复与反馈规则（用户最新授权）

1. **开发者自行判定并处理目标内问题。** 包括运行错误、数据/状态不一致、布局裁剪、控件易用性、合理默认与重复接线障碍，以及直接影响本次交付的构建/导出/消费工具问题。先核实际依赖、触发条件、预期依据和责任入口；形成有证据的最小方案后直接实施，不需要指导先批准每个新问题。必要的兼容性增量API与内部接线可在目标内自主完成，需记录语义、兼容边界和真实消费。
2. **先保全问题，再修；修好仍反馈。** 值得复用的问题先查同题issue，用既有feedback.py create/append保存当时事实、必要原件与真实身份；记录不等于等待处理批准。修后在同issue追加根因、修改位置、修前/修后结果与回归边界。已经自行修好的问题仍须回接，不能因“本轮已解决”省略。工具故障时先保留等价字段与原件、注明待入库，恢复后补录，不让记录工具故障阻塞其他独立工作。
3. **验证与状态分别负责。** 用有效修前反例或既有原件检验修复；配方优化使用明确设计期望和改前/改后对照，不伪造契约失败。验证实际受影响的正常连续操作，涉及可见效果必须看实际画面。source_fix、sdk_inclusion、consumer_verification分别填写；源码修复不等于已入包，编译通过不等于运行消费通过。写清开发者自验范围，不能把尚未进行的指导复核写成通过。
4. **只对实质决策升级。** 改变产品目标/核心架构/状态权威，破坏公共契约或持久化兼容、需要迁移用户数据，或重大正确性/并发/FFI/GPU生命周期风险尚无可验证安全方案时，集中交回事实、尝试和建议。根因明确、沿既有责任与契约的修复继续自主完成；不把native、owner、公共API等文件或关键词本身当审批开关。反复失败及低收益投入按AGENTS既有规则复盘/升级，只暂停相关工作。
5. **保持交付边界。** 优先解决影响当前候选可用性、正确性与交付的问题，不借授权重做全部旧矩阵、开启全平台迁移或无限扩展功能。历史暂缓项若在本次正常消费中取得新的直接反例，可按本节处理；旧根因未明、已推翻的反例和无当前影响的愿望清单不自动重启。完成必要修复后集中报告已修、未修、未证与原因；发布、Git写操作、skill维护及外部咨询仍沿本文件现有边界。

这是对开发模型的直接实施授权。技能中的普通“应用任务不擅自改框架”约束仍适用于未获框架授权的消费者任务；当前任务同时承担框架交付，依据本节在责任层修复，不据此新增审批，也不修改skill本体。

## 4. materials 已闭合：保留成果，不重复开发

当前源码只留一次CjguiStartNextComposableImageLoads，Ready无可达cache/resource/bound texture时仍以同key重请求。原“保存UI→切走→切回”序列及11图/12卡成果保留；本次不再要求第二轮单次/两次调用比较。

[load5-final原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/load5-final)已由指导复算：65条idle样本CPU均1.186153846%，样本时间84.615–149.196秒；host.log计数2405稳定64.674594秒；RSS端点中位209920/188592/202016/183872/159616 KiB，首轮+32MiB+15%预算274176 KiB，均通过；静置RSS155.875→155.219MiB。仅为本负载，非长期/所有Metal资源结论。

报告以measurement-final.json所定义的±1.5秒端点中位为准；summary-final.json另有直接marker的首轮320544KiB/预算401393KiB，不混用。两种定义均通过，无需为统一文案再跑5轮。原load宿主a85aafcb…与最终437d8178…分开记录，后者观测接线和有限sanity不能倒写成同一原始运行。

保留settings原字段、assets200、materials12、原5轮与静置预算；只有后续改动确实影响资源/刷新行为或出现新的决定性反例时才复验对应范围。纯时钟/日志修正不重复整套负载。焦点实验计数增长另作待证观察，不据此重开已闭合materials或猜修内核。

## 5. 已闭合的深色样式与动作配方

保留generatedNumericStepperStyle从secondary_action取base+interaction、随后覆写尺寸的修复，以及readonly-demo动作的公开主题角色。已有[亮暗图](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/b-theme)和真实±/Apply操作按原身份复用；不用再按旧RED重复修同一处。

只在本轮修改影响样式/生成构造时补亮暗、只读/可写/禁用与必要focus/pressed验证：文字和边界可辨、无裁剪、只读文本可查看/选择而±不可写、可写精确单步、Apply/Cancel/校验和AX名称保持正确。不硬编码白字、不改全局normal强制覆盖或重造样式级联。公开配方仍区分framework stepper接线和应用动作style；不扩开关/字符计数/底栏控件。

## 6. 已闭合的保存计划往返

保留write_json_file默认保序和既有完整preview/摘要/endpoint/base校验。旧排序文件仍具名saved_preview_mismatch，不静默重算或rebase。新宿主和包外公开CLI的insert/set_property往返accepted/exact已取得；指导另用真实历史原件离线核对和4项既有保护测试通过。

该问题不再是本轮开发任务；只有相关变更造成直接回归才修。若修改序列化路径，复验真实计划preview/save/load/apply及篡改/过期拒绝；不要只用任意字典排序测试替代公开计划。旧文件兼容边界在使用说明保留，新包沿同一公开客户端消费。

## 7. H1热复核：修复滚动区AX，保留已验VO链

**当前状态：§48/§49已验收。以下保留发现与修正过程；所有旧“待修/待入包/待补证”均是当时状态，当前以§2为准，不再执行一次H1。**

**2026-11-09指导即时认可，执行者可直接续修，无须另等批准。** 问题仍归e855e4908dc44be1bf33ae6283fde687；[vo-chain4原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/vo-chain4/observation.json)、[热复核](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-ax-scroll-20261109.json)接续§44，旧错误按键的反例不能独立证明框架缺陷，但本次新证据已足够批准明确范围的修复。

### 7.1 已核事实与责任

- 更正helper后使用VO+Shift+Down、VO+Shift+S、plain PageDown；原生NSScrollView能滚动且有AXScrollBar值，CJGUI两次PageDown仍暴露记录1..4、位置513/547/581/615不变，record24不可达。源自包外4eb8205e、SDK b0276dde；主树与包内renderer均为cc7e3494…，不是版本差异。
- [消费者main.cj](/Users/jiangxuanyang/Desktop/CJGUI%20Prototype%20Candidate%20Consumer/App/src/main.cj:154)已用公开ScrollArea绑定recordsViewport并声明24行。无需应用另造滚动owner或重写列表。
- [native AX包装](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:23228)发布ScrollArea role和semanticChildren；accessibilityNodeIsActionable排除ScrollArea，actionNames无滚动项，也无scrollbar getter/可用滚动AX桥。**空action或无滚动条单独不构成缺陷；结合正确VO协议、原生对照和当前源码，确认缺的是macOS无障碍滚动接入。**
- 普通滚轮routeScrollAtPoint及[共同viewport处理](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:14748)、滚动条键盘处理已有。复用这些既有状态和事件责任，补AX适配，不重造滚动机制。

### 7.2 本项已批准的最小实现

1. 让viewport-bound ScrollArea向AppKit提供真实、可消费的滚动能力：根据本机AppKit契约补scroll/scroller属性、方向/range/value、必要动作/值写入与通知。可采用与真实viewport绑定的AXScrollBar及其标准操作，不要求为了验收强制添加新的可见滚动条，也不能只添加不能执行的action名字。哪些标准属性/动作实际被VO使用，以原生对照和系统文档核实，不能照搬iOS API。
2. offset、contentExtent、viewportExtent仍由现有CjguiComposableUiScrollViewport唯一负责；AX只读当前accepted事实，操作进入现有有界输入/视图状态请求和正常accepted发布，通知跟随真实变化。禁止native私存第二份权威偏移、AX直接改业务owner、仅伪造AXValue或依赖鼠标位置替换被操作的滚动区。
3. 允许为本项最小修改native AX包装/头文件、对应内部FFI与accepted投影元数据、仓颉窗口滚动消费及针对性测试。若当前投影没带必要offset/extent，补内部事实运输，不借此扩张公共业务协议。保留node/resource/viewport incarnation、scope/模态和退役wrapper拒绝；请求失败不得部分推进AX或画面。
4. 同一公共ScrollArea机制应覆盖手写及生成式消费；不要硬编码inspection-records、record24、案例名或只在宿主中绕过。保持已实现的轴支持，未支持方向不虚报；不将本项扩成所有屏外节点常驻、任意语义ID自动reveal或全平台AX重构。
5. 实现前按[共同实现与本地参考入口](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md#本地开源实现参考)找已有scroll/AX职责，必要时局部查阅成熟实现，仅借鉴不引入依赖。[Apple自定义控件指南](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/ImplementingAccessibilityforCustomControls.html)强调角色之外的属性/动作和通知；具体平台接口按本机SDK确认。根因明确的本项内部接线持续完成，不因触及native/FFI就重新等批准；实质架构/资源风险或反复无进展再按AGENTS升级。

### 7.3 必要验收与SDK回接

- 直接保留vo-chain4为RED，不为凑失败数重跑。修后以真实VoiceOver进入滚动区、正常滚动并导航读出初始屏外record24；核实际viewport/accepted变化、AX子项/位置和画面一致。普通AX属性查询/动作探针只辅助，不能替代真实VO成功。
- 最小针对性覆盖：顶部/底部钳制、无滚动范围、旧或移除wrapper不误写别的viewport；原有滚轮/滚动条继续作用于同一viewport，停止操作后不持续提交。按影响用局部测试/正常消费验证，不追加整套资源/30+30或全平台矩阵。
- 选区新观察已报告两条正确协议成功，保留这个方向；selection-final-before-close.txt实际查到serial(component-3-1)，不能当name选区读回。受影响包外短回归时按语义字段找当前name节点，保全非空UTF-16范围/所选文本与owner一致的正确原件，避免把旧数字ID当字段身份。无需据此修文本内核。
- 修复框架/native后按§11从最终同源输入更新锁并统一导出SDK，用现有包外App重建并重验record24与受影响只读/选区短链。分别记source_fix、sdk_inclusion、consumer_verification；b0276dde旧包不可标为已包含未来修复。SDK和宿主/包外身份更新到本文件及交付报告，旧绿线按原身份复用。

### 7.4 保留操作与反馈边界

步骤1只读帮助/值/禁用±、步骤4公开move续接、步骤5真实保存和正常cmd+w按原范围保留。VO游标与键盘焦点、工具合成与真人分开；不要把cmd+w写成VO退出，或用AX预滚动/设选区伪造成功。正确滚动协议见[Apple滚动说明](https://support.apple.com/en-euro/guide/voiceover/vo2702/10/mac/26)，选区方法见[Apple选择说明](https://support.apple.com/zh-sg/guide/voiceover/mchlp2741/mac)。

本段原为H1阶段的单项授权，H1已经交付；当前发现与修复权限以§3.1为准。保留其实例保护要求：准确自有PID、正常关闭、VO/字幕及实际调整设置恢复；无新影响不重做H1旧链。

### 7.5 H1最终验收状态（2026-11-09，§48后）

- 初步NSScrollView接入与三项直接修正均已完成。native使用double位移、共同准入；viewport身份进入AX binding key，sameLayoutNode复用判定也核viewport身份。原先的小数损失、作用域漏检与旧动画跟随换绑均有区分RED/GREEN，含仅改key仍失败的原件；不把失败夹具或重跑当修复。
- 宿主93562f03与包外a6aa5d4f真实VO导航读出record24的字幕/操作链已归档；字段VO选“泵”、range3,1与owner字符串对应。短静置accepted/submitted/frame保持稳定，不再仅凭bar不变判定。VO焦点与业务选择分开。
- SDK ZIP156c3060、锁9345b9f1、640清单文件/613源输入及包外安装目录与两应用provenance已实核，包含H1最终修正；旧b0276dde/中间51687252只作历史身份。
- source_fix=fixed，sdk_inclusion=included，consumer_verification=指定H1消费范围passed。指导event c61bfc52…验收；完整身份和原件见§2/交付§48–49。无其他VO版本/长期认证等新增宣称。
- 平台实现结论仍限本机探针；保留窄AppKit代理，不推广“只有NSScrollView才能支持所有VO”。本节已闭合，H3无需重做它。

### 7.6 H1交付热复核与已批准收口

**本节三项现已完成，保留原方案与反例供追溯；不得因读到下文旧时态重新修或重跑。**

以下保留当时批准的三项原因与修正要求。现在实际RED/GREEN已取得并验收，作用是解释修复边界，不是要求H3重新执行。

1. **H1-F1：保全小数位移。** [proxyBoundsDidChange](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:23661)先更新lastProxyOffset，再丢弃abs(delta)<0.5，并对每一帧llround；[enqueue入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:28375)只接Int64。算术反例：0.25pt×8原生累计2pt却不发送；0.5pt×8累计4pt却发送8pt。共同[CjguiPreciseWheelState](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:2627)已经累积Float64余量，原cjgui-wheel-v1也可携带小数。复用这一责任，避免在native逐帧丢弃/取整，不另造应用补偿或第二个offset。定向验正反小数序列、合法页滚动最终偏移与受理事实一致；原生回调入队失败不得被当成已接受位移，按现有拒绝语义取消/恢复，不重投刷绿。
2. **H1-F2：原生裁剪通知复用AX准入。** 同一proxyBoundsDidChange直接调用enqueue；该helper只检查session/数值，不做[accessibilityNodeIsInCurrentScope](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:28248)，而page和setbar路径会检查。[共同wheel resolver](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:14581)核binding/eligible/version，不能替代这里漏掉的当前AX作用域准入。让原生clip、scroller值/动作共用合格viewport、实时身份和scope判决；失去准入时取消旧动画/待同步状态并保持accepted不变。验收在模态/作用域改变时保留旧AX引用或继续旧clip回调，底层viewport不变；合法作用域仍可滚动。不扩成全局模态重构。
3. **H1-F3：动画不得随同节点换绑到新viewport。** [AX缓存key及复用](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:28092)与[nativeSemanticBindingKey](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:14495)不含viewport身份；共同wheelBindingIdentity已有viewStateIdentity。公开ScrollArea可以保留node/semantic ID而换viewport。当前复用会更新action.node，scrollGestureActive时又跳过投影，旧clip动画后续回调遂读取新node并盖上新projection入队，旧请求不再能靠版本拒绝。复用已有viewport/binding身份，必要时补内部投影事实，使换绑/退休立即取消或隔离旧代理与回调；不把scene每次递增都当换绑，不另建公共协议。用同node/key从viewport A换到B且旧动画未结束的反例验证B不被旧请求修改，B的新合法滚动正常；补旧/移除wrapper调用无副作用。250ms只可用于同一合法动画的正常投影收敛，不能延迟换绑/失效处理。

修复汇合后做一次受影响验证：定向测试/探针、必要构建、宿主和现有包外App真实VO进入→翻页→读出record24，保全相同实例的AX/viewport与画面对应；附当前语义字段的正确VO选择读回或明确复用旧证据，不能用AX设值代替。顺带核端值/无范围、旧滚轮和短静置计数。无需再做全平台、全HTML、30+30、load5或未改的UI历史矩阵。只有最终源码统一导出SDK、更新ZIP并补受影响包外链后，才把这三项对应状态写成完成。**H2与本节并行属于同一交付目标，最终报告不能遗漏§8。**

## 8. H2热复核：修分析脚本，保留局部p95和首次有效输入

**当前状态：H2已按本节完成并经指导独立复算验收，43有效/17未证及26.193501ms子集p95保持。以下为原方案/边界，不再采样或重做脚本。**

[本次复核原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-other-feedback-20261109.json)包含ID反例、时钟选点反例及离线独立计算。此项只批准测量/分析接线，不是新的框架性能或输入修复任务。

### 8.1 已验成果不重开

prototype_measurement.cj处理前记点、contentVersionForGeometry关联、容量64/超时2s及默认关闭保留。固定30+30局部nearest-rank p95：窗口业务回调0.019ms、起点→accepted观察15.902ms、起点→submission15.740ms；公开结构提交对应0.331/23.661/23.362ms。公开组不改变业务owner，0.331ms仍叫结构提交回调。原16/100ms只按局部起止范围成立；31条未应用事件、零/无效present、正常关闭原件保留。

first-interaction-3失败结论不变，不能由字段可见推通过；但新的[有效轮5](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/first-interaction-5/first-interaction.json)已经修正前台/投递顺序，取得obs=3 applied、owner205→206、matching accepted、唯一期望draft与投递后snapshot精确一致。driver同一monotonic起点到accepted接收为1195.08875ms（上界），足以支持**本次暖机后续启动≤2s**，不依赖1193.02275ms跨钟估计。posted_ms也是投递子进程返回时刻，不能当原始key-down瞬间。

保留first-interaction-4的失败和旧冷/首次轮，不称冷缓存、真人或IME通过。无需为已取得的这条成功再跑启动矩阵；源变更确实影响启动输入时才做针对性回归。旧30次draft没有逐字原件，保留其边界，不倒写；这次唯一文本已验证，不以此冒充旧30次逐字验收。

### 8.2 已确认的H2脚本错误与最小修正

analyze_present.py用`abs(observed_absolute_ns - submission_relative_ns)`寻找“nearest”时钟对；两者起点不同。指导用原1520对/60个accepted复算，**60个全部选第0对**，正确同域按elapsed找近点则选60个不同位置。脚本所称nearby配对不成立，24.938ms的旧跨域估计不能原样保留为已校准结果。

批准执行者直接修复并离线复算：

1. 优先用原cadence中同一`session/generation/scene/frame`的commit与正值有效present计算**native commit→present**，核submit/callback drawable身份；这些time_ns来自同一mach host时钟，避免无必要的跨域估计。accepted携带的scene用于输入与显示身份关联，不把commit时间冒充输入时间。完整身份校验要实际执行，不能只在说明中声称。
2. 若仍保留“宿主观测起点→native present”参考值，用elapsed与relative submission比较，或先用有依据的偏移转换到同域再找近点，明确偏移方法/误差。管道最小读取延迟仍不是精确同步，13.806ms散布不是绝对误差界；不据此判严格16/32ms端到端门。
3. 不用无解释的`estimate−5ms`容差将时间倒置计为通过。无法判定时报告未证/估计误差；保留0/invalid、缺行、错配和慢样本。不能换任意后一帧补绿，后帧合并呈现必须有携带状态证明。
4. 指导原件已给一个独立同域核对：现有43个valid exact-scene有43个同身份commit，commit→present p95约26.194ms、max29.235ms。执行者用同一原数据复算并核结果/字段，不把这个43子集当全部60个或系统投递端到端p95。无需重新采30+30或负载5轮。
5. 保存旧分析原件及H2更正结果，用一个有区分力的离线反例验证同域配对/身份检查，更新报告准确起止点。只修脚本、说明和原件关联，不建立大型计时平台。

### 8.3 未证边界与完成口径

现有60条中43条有有效exact-scene present（窗口30、公开13），另外17条公开更新的exact-scene present为0/invalid。已逐条分类不等于60条全部显示通过；43子集统计不能包装成整组p95。暂不根据17个无效值批准GPU/渲染修复；先保留原件，必要时只在下一次已安排的受影响正常消费核是否真正缺可见更新，不另外造整轮压力验证。

系统presentedTime仍是本包采用的显示观测边界，已有首显示0.248/0.258s按原身份保留。真人、完整系统IME、冷缓存、长期性能和光子级不新增为本包前置门。H1修框架需SDK回接，H2仅改验证工具不单独触发SDK导出；所有已绿旧门按影响复用。

## 9. 已通过行为的保护边界

这些要求都保留；无受影响变化不重复旧矩阵。

- A/R1：同descriptor的跨会话版本/endpoint/surface/epoch/digest隔离，读B不能复活A请求；合法B连续编辑及undo/redo必须完成终态。保留普通空闲workspace.finish接线，无提交不制造刷新。候选接受不等于历史结算；不手工清pending或统一版本作用域。切项目完整构造后adopt，失败保旧；新会话构造异常注入仍未验则明说，不伪造已通过。
- B/R9：descriptor为共同只读事实，手写helper只能收紧；availability/reason/callable与typed read_only一致；旧producer缺事实保持None，非法token拒绝。isWritable仍可表示writer路由存在，不能全局false让只读字段无法渲染。只读与禁用分开，查看/选择语义保留，owner仍具名拒绝写入。
- stepper：输入子节点身份、仅ACTIVATE、inputSequence去重、accepted field/writer/owner/incarnation检查、旧节点拒绝、错误反馈与合法Apply/Cancel都保留。样式修复不得双步进、吞点击或解锁只读。
- C/D/E：可见label不回填内部ID；semanticLabel按声明回退，不用U+200B。诊断只归当前候选；不扩大裁剪上限。assets720详情保持可见、选择owner正确、恢复1280正常。
- F：祖先独立变更/换绑被accepted后旧捕获取消，旧事件不再写；自身拖动accepted重绘保持连续。窗口屏幕原点不同于布局祖先平移。保留已取得8项测试和有序真实窗口证据，fixture有界owner-turn等待不是放宽断言；无需再重开F排查或修改生产捕获。小说工作台回接未验保持原结论。

只按最终改动影响复验这些边界：例如主题改动复验B/C可见状态，刷新改动复验A正常结算与输入连续性，保存计划改动复验会话/摘要保护；不逐补丁全矩阵重跑。

### 9.1 H3已批准：恢复选中对象后同步详情绑定

issue `0708aba456e24778902df9cf4b6639eb`，指导event `ce21c230f7984dda9386de5f82cd346c`。**原反例定位为宿主应用接线缺陷，沿既有rebind修正即可。** 本项已有§50执行交付，保留对应成果和身份；下文留存归因与验收边界，不因授权更新重做。新的相关问题按§3.1自行核实处理。

已核因果链：

- [PrototypeSession构造](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_session.cj:271)先建立domain和PrototypeRegionBinding；[binding构造](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_session.cj:20)捕获初始activeObject（001）的FormBinding。
- [controller启动恢复](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj:72)随后载入session；[domain.restoreSessionState](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_domain.cj:872)恢复selected=199，但[prototypeRestoreSessionPayload](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_runtime.cj:435)成功后仅setDark，没有调用binding.rebind。
- 详情draftText、fieldOperationResourceId、Apply/Cancel仍委托捕获的current FormBinding。正常[SELECT_RECORD路径](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj:681)已经调用同一个rebind，可直接复用。实际保存ui/main.json只声明field=title/quantity等，没有固定owner；本样本不是“文档故意固定001”。
- `binding.currentOwner()`直接读取domain.activeObject，因此它可以报199而内部current仍是001，不能只靠此包装getter判绿。源码推导实际owner可能为3198/3000，但本次指导没有新typed读回，不把预测写成已运行证明。

最小实施：在整体会话恢复成功之后、启动文档/可见字段/公开连接消费之前，把宿主绑定接到恢复的activeObject；优先在已有统一恢复入口使用现有rebind，必要的宿主投影/版本通知沿正常机制。失败保持原domain与绑定，不清空会话、不改写UI文件、不人工点199补救、不用逐帧自动重绑掩盖漏接。保留各对象draft/applied/version，不隐式Apply，不新增owner或持久化格式。

定向验收（共享一个私有项目，不影响用户会话）：

1. 最小应用测试先RED：保存非首条对象选择及可区分的draft/applied，走真实prototypeRestoreSessionPayload恢复；对比domain.activeObject.ownerId、binding.fieldOperationResourceId("title")和binding.draftText("title")，证明旧实现不一致。再GREEN；非法payload恢复被拒时，原选择/所有草稿及字段绑定保持不变。
2. 用正常宿主入口从原保存会话重开，不经补点选择，核选中提示、详情、当前字段owner/公开typed值同属199。生成字段编辑、Cancel、Apply正确作用于199，001前后不变；恢复本身不Apply，非当前对象草稿保留。保存再重开仍一致；保全真实窗口输入、公开读回及原session/UI身份，不仅结构show或currentOwner包装值。
3. 只补这一条恢复消费与有区分力的应用测试/构建；settings/materials与旧绿线按影响复用。HTML没有变更，最多记录同需求下恢复后详情状态一致，不重拍全尺寸。当前SDK ZIP156c3060、包外a6aa5d4f及H1/H2都保留，无需重新导出/重建/采样。

完成后追加同issue的应用source_fix和真实consumer_verification；sdk_inclusion写not_applicable并说明宿主不在613输入SDK闭包。只更新宿主候选身份、原阶段交付和ACTIVE当前摘要；本项收口后继续已授权H4/H5，合并集中交付，不自动启动其他未证工程。

## 10. 继续通用原型宿主与独立 HTML 对照

用同一最终二进制经--project消费三个项目；字段、数据、动作、界面与资源来自项目声明和cjgui.ui-document，不按案例名硬编码整页。

| 项目 | 保留和受影响消费 |
| --- | --- |
| settings | 两列表单、只读/可写、stepper/选择/校验/Apply/Cancel；声明兼容新增字段经重载可公开发现并入owner；有草稿重排、保存冷重开按字段ID恢复且不隐式Apply |
| assets | 200记录筛选/滚动/整行选择/详情编辑、720和宽窗；切项目对应新owner，非当前记录草稿仍受保护 |
| materials | 12卡、2/4列、选择、缺图占位、详情；保持停止操作后收敛且后续输入/公开更新可用 |
| readonly-demo/split-demo | 保留已修配方与小型公开验收入口，按影响复用，不做大型样例扩张 |

汇合时走一次真正公开消费接缝：descriptor能力发现 → 原子snapshot → 计划preview/save/load/apply终态/exact读回 → 正常窗口输入 → 模型读同owner → 有草稿重排 → 切项目后旧请求拒绝、新快照合法续改 → 文档undo/redo → 保存冷重开。已验且未变的完整链可按版本复用，重点补本包变更；不能只汇报READY或截图。

公开模型用正常cjgui_generated_edit.py，不手改版本、不写专用成功客户端。注明真人、工具物理事件、AX、合成输入；真实执行模型消费与预写脚本回放分开。复用宿主构建/启动目录，换项目无须重编；交付核实最短打开方法。

审美继续以macOS HIG为参考，借鉴ArkUI组件/布局思路，外部框架只读参考。复用[独立HTML](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/html)与[对照说明](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-html-comparison.md)：同需求/数据/状态/主题/内容尺寸，沿1280/960/720保留旧证据，只补受影响亮暗控件、滚动态和其他实际变化。不能改HTML需求迁就CJGUI、不凑截图数、不要求逐像素复刻。

开关/checkbox、色点/select、字符计数、列表密度、空态等仍区分产品策略、配方、能力边界、缺陷或未证；不能仅凭与HTML不同判错。当前目标内有依据的缺陷和易用性问题按§3.1自主处理，其余记录取舍，不为追求外观相同扩大需求。H4沿§15改善整窗组织；新增公共能力确有必要时先核已有实现与兼容边界。整体生成效率和首交互/连续修改时间只比较同条件实测，不用一次submit时间宣称比HTML快。

## 11. 锁定 SDK 已交付：按影响维护

当前实际交付ZIP为156c3060…、源码锁9345b9f1…、内容9feb19cb…；640包文件、613当前输入、包外安装目录与构建身份已由指导逐项复核。H1最终修正已包含；旧b0276dde只作明确标识的基线，旧51687252是中间目录身份，不再冒充当前包。

H3/H4/H5-A的原定方案落在prototype_host_app；该目录不在既有613输入SDK闭包，单独不会触发SDK重导或包外重建。实际修复按责任归属；新证据证明需修共同机制时按§3.1处理，不以宿主方案预设掩盖框架问题。

H5-B及按§3.1实施的相关框架/公共工具修复若进入SDK输入，汇合后沿现有source-lock导出流程统一更新同源SDK，再用现有InspectionCandidate验证受影响能力与真实动作，避免逐补丁导出。记录新的完整身份与source_fix/sdk_inclusion/consumer_verification。156c3060保留为旧基线，不能标成包含未来修复；未变的H1/H2/VO/性能原件保留原身份。导出工具自身若有直接相关缺陷可按同一规则修复，不重造分发流程、不自动升级小说工作台或重跑所有旧消费。

继续保留experimental/additive_only；不发布、主动联系测试者、创建新消费者或按轮复制全树。旧49c/b027基线的必要复判用途及空间规则仍按原文档执行。

## 12. skill反馈与新发现

只使用现有[反馈流程](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/skills/cjgui-app-dev/references/feedback.md)，不修改skill。§48指导复核追加H1/H2验收与H3宿主归因/授权3条事件，截至2026-11-09T14:50:36+08:00读取为**22 issue/110 event，complete、errors为空**；[list原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-48-feedback-list.json)。数量不是全部已修，后续按实际读取更新时间。

| 事项 | issue / 最新指导event |
| --- | --- |
| materials已验 | 62eff39434e841619307c9b30cf835cc / 0a810bf28a6c47e2ace8ba5db686f57b |
| SDK锁已验 | ce5fc57697f94948b64a48152b7f3f08 / b6704b4fc749462c96588c27e2ddb6f5 |
| H1修复、入包、指定消费已验收 | e855e4908dc44be1bf33ae6283fde687 / c61bfc52db614f0086f3f52757f5422c |
| H2离线更正已验收，43有效/17未证 | 40c23dc27eb94ec289816eca40044294 / 3baf07a43c654e46822dfcd41185fc70 |
| H3恢复绑定漏接，批准宿主修正 | 0708aba456e24778902df9cf4b6639eb / ce21c230f7984dda9386de5f82cd346c |
| H4整窗布局与默认配方，用户已批准 | §15；执行时查同题记录并复用或新建，尚未登记issue/event，不计入上方历史数量 |
| H5-A列表裁字、H5-B按钮对齐，指导热复核认可 | §16；按两种责任分别回接，issue/event由执行者实际登记，不能沿用历史计数声称已入库 |
| 焦点增长，仅记录 | 46646e70eb51458c9054e898748ed496 / d2509136c1ad491eb774e346d7d2b8dd |
| AX ID布局交换反例不成立，不修 | 3be75e89f9a0455bb0cec1f59df7195b / 19b0d002a0864c73a45c6e1df372c023 |
| 字段style配方当前SDK已覆盖 | 911862302972436fba24a102ac768d8d / c5f6ecc06a5246959c4ad1f7519768c7 |
| probe2未修，纠正旧措辞 | 9fd477c859994ba0a0c5a07ec45a3d0b / 7041c13254ab4d848e2d5a753bc4fa04 |

H1/H2已经验收，H3–H5继续，其他当前目标内的问题按§3.1由开发者核实并自主处理。H3的no_framework_action表示不改框架内核，**不是不修宿主**；source_fix须标应用范围。H4按宿主集成/配方易用性记录；H5-A为宿主固定行尺寸与控件绘字空间不匹配，H5-B为公共按钮内容对齐/默认动作配方缺口，不把两者混作一次全局字体修复。needs_evidence须保留待区分事实；补证后可由执行者更正归因并直接处理，无需先等待指导更新白名单。

每条完整观察填本条真实identity、goal/expected/actual、证据/归因/易用性，以及source_fix/sdk_inclusion/consumer_verification三个独立状态。未确定框架是否需修写unknown，不用not_needed代替“未修/尚未证明”；SDK未改的宿主脚本修正可写not_applicable；已验H1状态不退回pending。修复前/源码已修/待入包/消费未验或通过均按实际追加；所有自行修好的可复用问题也要记录，不能直接从报告消失。修复、入包、消费不互相推导，不因已修就删除原RED或旧版本失败。

同问题append、新问题create，必要supersedes只替代同issue的错误结论，旧原件保留；当前阶段页回链issue/event。普通一次性工具错误不另造框架issue；影响结论的重复观测问题回已有40c23dc2…。A仍用0858e5dc…，不混R9事件。

**其他反馈的既有事实与取舍（新证据按§3.1自主更新）：**

- `3be75e89…`的“隐藏手写区让AX ID交换”被其附带原件推翻：before与doc-tools两张树均是`component-3-1=设备编号`、`component-4-1=设备名称`，只改变几何。源码按`registry.use("generated-${spec.key}")`复用实例，semanticId是generation/localSlot，不是该次布局遍历序号。撤回本反例和推测，不修身份机制，也不发布“AX ID随布局变化”的错误说明。跨进程/销毁重建不保证复用数字ID，不能混作同一实例变化；自动化按当前语义/公开实例映射找目标。
- `91186230…`生成字段style配方旧缺口：当前主树及b0276dde SDK的STYLE_ROLES.md已经明确字段`style=input`及主题注册。保留已成功配方，无需重造控件或自动改变默认视觉策略；如果将来要改默认审美另给具体方案。
- `39d4382e…`测试foreign重复声明已去重并有原编译证据，不再开同一修复。包外`414cf78d…`为已文档化构建配置保护，正常重建已成功，易用性建议保留，不扩修runner。
- `9fd477c8…`probe2/internal_error仅旧候选时序证据；source_fix本来就是pending，旧workaround“已修复”错误，应纠正为“未修”。当前根因/新包是否仍复现未证，不因该措辞批准猜改事务或重开旧矩阵。

焦点102→329先按已有时序区分输入/光标与真正静置、是否仅--measure出现。缺信息保持needs_evidence，不因计数上涨判泄漏或重开materials；本次无新的决定性事实，不专门启动该工程。

历史暂缓项包括issue10/probe2 participant_prepare、R5全矩阵、小说工作台回接及末尾跟随/重复node ID/退出provider、窗口标题/筛选后详情策略、运行时改规则/删字段/迁移、完整控件库、递归组合/脚本/源码热重载、出版级排版/GiB、全平台同版；本次授权不自动启动这些整项工程。若其中问题在当前正常消费中复现且直接影响交付，执行者可按§3.1做有依据的最小修复，不必因其曾列为暂缓再等逐项批准。外部应用升级、平台恢复和重大产品需求扩展仍保持边界；旧包/其他应用/平台不自动标修。

## 13. 验证、工程与空间

先拿到有效RED再最小修复；已保全的真实失败原件可复用。不得删有效测试、放宽断言、缩负载、重试刷绿、伪造必拒参数或用陈旧测试二进制。fixture错误可以修，但说明原始首错与仍然覆盖的行为。

按影响验证针对性测试、必要cjpm build --skip-script、git diff --check、公共签名/稳定性及受保护路径/禁止行为扫描。最终汇合做必要正常消费者回归，不逐补丁全平台全矩阵。运行候选、编译器原件、签名后的bundle、native和源码provenance分别对应。

保护混合脏工作区及别线写集；不reset/stash/切分支/覆盖他人改动，不stage/commit/push。同一cjpm target build/test必须串行。工具/语法/路径/既有契约内局部接线自行解决；实质风险按AGENTS集中升级，只暂停相关工作，不把某个未验项改名成整体完成。

桌面沿已有授权，优先agent-desktop与语义操作，视觉验收按需看图。使用精确自有PID/bundle/主窗口，复用实例，避免争用前台；保护用户实例和剪贴板。换二进制/生命周期才重启，自有正常/失败实例、descriptor/socket与采集器都落实finally收尾，不清理归属不明进程。

遵守[AGENTS容量与收尾](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md#artifact-space-budget)：开工核本线输出/可用空间，高写盘前算峰值；默认新增保留≤10GiB、峰后可用≥20GiB。每消费者一个复用构建目录，当前候选+最近可用基线为默认完整产物数。保留必要RED/GREEN、输入和原始日志；普通日志单文件64MiB、当轮512MiB，不截断必要证据判绿。准确归属、进程/锁退出、原件归档后才回收本线临时输出，保护用户和其他任务数据。报告新增/保留/实际释放/剩余空间及在用路径。

## 14. 完成条件与集中交付

在[原交付报告](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-delivery.md)§49指导裁定之后续写；ACTIVE E仍只一段原则上≤600字。当前接续交付须包含：

1. H3的实际根因/宿主最小修改，恢复入口RED/GREEN，正常保存重启后选择/详情/typed owner一致，编辑/Cancel/Apply只写恢复对象，其他对象与失败恢复保旧证据。
2. H4共用布局与默认配方的实际落地、用户截图对应状态的前后对照、不同窗口高度/720窄窗与短长内容消费、一次公开模型续改；说明留白、内容滚动和操作区的明确规则及仍存差异。
3. H5列表两行文字完整、整行选择正确；普通动作按钮文字居中、列表文字保持左对齐、输入不受影响，手写/生成一致。附改前/改后及最小定向验证，不能仅靠AX完整字符串或测试数量判视觉通过。
4. 新宿主身份与直接受影响消费；最终修复若改变SDK输入，按§11统一更新最终SDK并完成受影响包外消费。H1/H2、旧SDK156c3060/包外a6aa5d4f及未受影响的原型/HTML/性能证据保留原身份，不重跑全矩阵。
5. H3/H4/H5及自主处理的新问题各自反馈回接，列出issue/event、实际修复位置、三种进展与验证范围；尚未修复/未证/需升级的明确理由和下一步。必要检查、原件、空间账与自有实例/端点清理；未提交/发布、未改skill。

既定任务及当前交付所需的相关修复完成后集中交付；发现范围可以广，修复优先级和投入以当前目标为准，不把所有历史未证、完整IME/真人/长期认证自动转成新工程。候选保持experimental，必要问题未闭合则如实报告未完成；实际阻塞只影响对应项，不能用旧H1/H2待办继续绕圈。

## 15. H4新增授权：整窗布局与默认原型配方

**2026-11-09用户根据资产库截图明确要求优化，并加入本任务。继续同一个目标，不另建任务；H3已验成果保留，本节完成后与其集中交付。** 本项提升已有组件组合的默认使用质量，让模型沿正常宿主入口生成合理的整窗原型，减少反复提醒“下半截空着”的人工补救。

### 15.1 已复核事实与问题归属

用户[原截图](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/layout-whitespace-before.png)中，资产库筛选199后只剩一条记录，右侧四字段表单及按钮集中在窗口上半部，底部状态栏仍位于窗口底部。[对应UI文档快照](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/layout-whitespace-before.ui.json)取自截图状态所用私有项目，保留为改前对照。

- [buildUiInner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj:224)已经给工作区growY；侧栏及详情区域也已有交叉轴STRETCH，不能重复归因为旧720伸展漏接。
- [buildRegionArea](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj:470)统一将生成内容放进ScrollArea；[现有布局契约](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/LAYOUT_PRIMITIVES.md:106)规定滚动内容按自然高度计算范围。UI文档的root/card只声明横向增长，字段与按钮自然堆叠，没有整窗空间分配方案。
- 当前证据足以解释这张图的留白，**尚未证明布局引擎违反契约**。问题按宿主布局选择与生成配方易用性处理；短表单/单条记录允许合理留白，不把空白面积本身作为框架错误或要求所有控件拉高。

### 15.2 授权实施范围与效果要求

1. **复用已有布局，补齐宿主共用配方。** 用现有Vertical/Horizontal、grow、align/STRETCH、ScrollArea和语义主题组织有界工作区。明确“内容自适应”与“填充工作区”两类承载用法，列表—详情默认采用整窗工作区组合；短表单可保留自然高度。优先调整宿主共用组合与项目UI声明；仅凭当前留白不足以改变框架测量、滚动契约或全局主题，若另有明确框架反例则按§3.1处理。不仅向滚动内容加growY就宣称填充完成。
2. **解决整个窗口的组织。** 侧栏和详情面板有连续、清楚的区域边界，随窗口高度使用可用空间；表单保留合理阅读宽度、标签间距与正常控件高度。操作区位置清晰、一致、可达，明确短内容与长内容时的规则；若采用面板底部固定操作区，用有界内容区与其分工，避免按钮被长内容挤出可用区。背景、分隔、留白共同形成工作区层次，不能只涂满背景或加空占位就算完成，也不为填空增加无需求字段。
3. **默认路径真正消费配方。** 在宿主共用布局入口、项目UI声明及README中给模型可直接复用的示例与选择规则，减少每次重新拼接窗口尺寸关系。沿现有项目视图声明选择布局用途；必要宿主内部组合参数可调整，保留旧项目缺省兼容，不按assets/settings名称或记录199硬编码。不能只追加一句“请填满窗口”而保持原默认输出不变。
4. **以assets为主要改前/改后实例。** settings/materials复用适合其用途的部分；涉及共同壳布局时做受影响短检查，不强制三个项目采用同一种高度策略。生成字段、动作、owner、草稿与UI文档仍走原公共链；保持H3恢复绑定、720可用性和既有滚动/AX语义。审美沿macOS HIG方向和现有主题，借鉴ArkUI布局组织，不引入外部框架依赖或扩大为控件库重做。

### 15.3 有限且直接的验收

- 复用用户截图和原UI文档作为体验改前对照；本项不伪造“旧引擎算错高度”的RED单测。用实际contentBounds及布局诊断区分外层区域与内部内容高度，确认方案依赖有界布局而非手算一个固定大高度。
- 同一宿主实例检查宽窗下**相同宽度、明显不同的两种高度**，再检查720窄窗；记录实际内容区尺寸。先看筛选199的短内容，再清筛选查看原200条列表并滚动，确认面板连续、控件不被拉长、操作可达、滚动范围/选中状态正确。只补受影响的前后画面，不重拍全尺寸全主题矩阵；主题角色有改动时补一个代表性暗色状态。
- 用正常公开模型入口选用配方并续改一处字段布局，保留草稿与正确owner，导出/重开后布局仍成立。与H3的选择199、Cancel/Apply及保存恢复链合并验一次即可；模型消费应依赖已交付配方/说明，不依赖用户再次提醒处理窗口下半部。
- 复用独立HTML中相同数据、筛选状态和内容尺寸的页面，对照空间分配、表单宽度、操作区与滚动方式；需要时只补直接受影响的一组HTML画面，不改需求来迁就CJGUI，不逐像素复刻。可见布局需要实际看图，AX/几何断言仅辅助。
- 按实际改动运行必要应用检查与构建；共用滚动承载变化时补其正常滚动、焦点与可访问短链。未改的H1/H2、SDK/包外与性能矩阵继续按原身份复用，不因样例视觉优化重跑整包。

### 15.4 反馈与交付边界

按§12查询同题反馈后复用或新建，记录用户图、原UI、布局责任与优化前后；归类宿主集成/配方易用性，不预判framework_fix。source_fix按宿主实际修改填写，sdk_inclusion为not_applicable并注明未进入SDK闭包，consumer_verification必须对应实际窗口与公开模型消费。更新原报告和ACTIVE同一当前摘要，不另开布局台账或新提示词。

若实施中发现相关框架问题，按§3.1保全反例、归因、最小修复并验证，不再要求先经指导复核。仅宿主配方变更无需重导SDK；实际涉及SDK输入则按§11统一回接。不修改skill、不提交或发布，空间与自有实例收尾沿§13执行。

## 16. H5热复核批准：列表文字裁剪与按钮内容对齐

用户连续提供[列表裁字截图](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/list-text-clipped-before.png)与[按钮文字对齐截图](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/button-label-alignment-before.png)。指导核对当前源码，确认以下两条责任，批准纳入当前整包；无需等待H3/H4结束再申请。[本次源码片段与原图哈希](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-label-geometry-20261109.json)保留复核时身份。截图证明可见现象，源码说明当前责任；指导未另启动该二进制做运行测试，修后验收仍由执行者完成。

### 16.1 H5-A：列表次行被裁是实际可读性缺陷，修宿主尺寸配方

- [PrototypeListSource.buildRow](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_session.cj:204)将标题和次行都做成可选择的BUTTON：外行42pt、标题22pt、次行16pt，后者fontSize=11、padding=2。次行从label改为button后，不能继续假定两种节点的文字内边距相同。
- [native文字矩形](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:12535)仅TEXT/TAB_TITLE使用上下2pt，其余包括BUTTON为上下6pt；[prepared绘字路径](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:14900)沿同一规则。按当前声明，次行16−2×6仅剩4pt可排文字，不能容纳11pt字体正常行框。宿主style.padding=2没有改变这段BUTTON内部文字几何。截图中的半截次行与此责任相符。
- 最小修正：按真实字体行框和按钮文字留量统一两行尺寸、外行高度及[VirtualList行步长](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj:459)，避免多个独立常数漂移。保留标题/次行的同一SELECT_RECORD和owner，不退回不可点击的label。不得取消必要裁剪、调小字体到不可读或全局缩减按钮内边距掩盖宿主错误；若复用已有紧凑整行组合，须证明相同选择/AX语义仍成立。
- 验收：筛选199的一条记录、清筛选后的200条滚动列表，标题/次行完整可读；顶部与底部完整可见行不被截，视口边缘的部分行与行内错误裁剪分开。分别点标题/次行，公开读回相同选中对象；保留长内容省略策略与完整AX名称。与H4窗口检查共用一次消费，不独立重跑整包。

### 16.2 H5-B：按钮文字对齐是公共控件易用性缺口，补最小共同能力

- [chromeButton](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_controller.cj:629)直接消费命名actionStyle，没有自行将文字向左移动。[CjguiComposableUiStyle](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui.cj:914)现有alignX/alignY定位整个节点，不是按钮内部文字；当前公开样式没有对应文字内容对齐事实。
- [CjguiFreezeTextAttributes](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:14950)只设置断行等段落属性；当前绘字矩形统一从x=7、y=6起排按钮文字，没有根据按钮内容框与字体行框做居中。截图能确认普通动作文字靠左；纵向观感需用实际行框再核，不凭截图强行指定像素补偿。
- **授权范围：**复用现有样式、按钮构造、生成action和文字准备/绘制链，为普通按钮补最小的内容水平/垂直对齐声明与消费。若存在可用的等价公共入口则优先复用；没有则允许增量补所需公共样式事实、样式复制/冻结、生成校验及必要内部native运输。明确其与节点alignX/alignY的区别，不重解释旧属性，不扩成全控件文字/富文本排版重构。
- **默认与兼容：**未声明的新属性保持既有行为；HIG primary_action/secondary_action/quiet_action配方明确采用居中，使宿主与生成式普通操作按钮默认得到合理效果。列表行按钮保持水平起始对齐；普通标签、表单标签、文本输入不被全局改成居中。按真实字体行框在内容区内定位，不用字数×固定字宽、空格填充、每个文案单独偏移或宿主画第二层假文字。
- 测量、prepared绘字、实际使用的fallback、裁剪、纹理缓存/失效和必要AX几何须消费同一对齐事实；更换文字/尺寸/对齐后不能复用旧位置。保持动作命中、enabled/readOnly与业务写入路径不变。共享代码及内部运输变更先核影响，不破坏现有FFI同源与身份护栏，不自动修改其他平台适配副本。
- 最小验收：一个短中文按钮“深色”、一个较长中文动作、一个英文/数字动作，在不同宽度和代表性高度下居中且无裁字；列表标题/次行仍左对齐，输入框仍沿原规则。手写与生成action各实际消费一次，亮/暗各保留一个代表性结果，点击动作与owner读回成立；加入有区分力的对齐/尺寸或缓存反例，视觉结果必须实际看图，不能只看AX名称。

### 16.3 汇合、SDK和反馈

H5-A与H5-B分别归因、分别回接：前者宿主集成/尺寸误用，后者公共API/命名配方易用性及其获批实现。先查现有反馈并复用或新建，不仅写自由格式说明；截图原件和源码责任随记录保留，修复前后/SDK包含/实际消费状态各自如实填写。

完成H5-B及相关框架修复后按§11统一导出同源SDK，并在现有包外应用消费受影响能力；旧包不标为已修。仅宿主变更本身不另触发导出；未变的H1/H2、VO record24、性能和历史链按原身份复用。新问题按§3.1自主归因、修复、验证和反馈；输入法、GPU生命周期、owner等按实际责任与风险判断，不以模块名自动停工，也不借问题重构无关机制。沿§13保护并行工作、串行build/test、复用产物及清理自有实例，最终按§14集中交付。

<a id="17"></a>
## 17. §52交付复核后的接续要求（2026-11-09）

本节是同一个完整任务的当前进度与剩余工作，不另建目标、不重做H1–H5。§3.1自主修复持续有效，下面是已发现的重点，不是新的排他白名单。指导本次只核源码、产物、原图与反馈，未运行新的GUI或产品构建。

### 17.1 保留成果与当前身份

- H3恢复绑定、H4填充/自然承载与内滚+兄弟操作行、H5-A两行尺寸和列表主题色保留各自原版本证据。指导实际查看了H4宽短窗及H5亮/暗列表原图，行内裁字与列表暗色文字已有改善。H4三尺寸来自H4构建，不能改写成最终宿主三尺寸全过；H5旧私有UI的自然高度截图也不能冒充新版H4配方结果。
- H5实际产物：宿主`d3b6bc10d5fdf0f715742ed6c586ad55aaf47f3903c5ecc168b496746c1ef9f1`；[SDK ZIP](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/CJGUI-macOS-Candidate-h5.zip)为`8f24128363ded994b2870d69cbb43aa1a45e710783af6a1b83fd9a673928dddb`；包外`f31309765978cbf84d98171eff12c1cd942eb0ada5aafa30c63e704905be8c2c`。ZIP、导出目录、包外安装目录的640个manifest文件逐项一致；宿主484/466及包外458/440源/准备源、各2项native输入均核对一致，testing=false。这证明来源，不证明视觉正确。
- 锁`e17b4228…`在ZIP/导出/包外三处一致。相对指导复核时的checkout，613项中仅skill的`SKILL.md`、`references/diagnostics.md`、`references/layout-theme.md`不同；保留这是交付后当前源差异的事实，不回滚其他任务的skill，也不把旧锁写成当前613项全匹配。下次汇合按§11重新冻结实际导出输入，仍不在本任务修改skill。
- 身份复核原件：[hot-review-h5-delivery-20261109.json](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-h5-delivery-20261109.json)。旧SDK156c3060等继续作为各自范围的历史基线。

### 17.2 H5-B尚未完成的真实问题

1. **样式复制丢失内容对齐，实际截图仍靠左。** `composable_ui.cj`的`cjguiComposableUiStyleWithPaint`（1382）和`cjguiComposableUiStyleWithTranslation`（1406）重建样式时没有转发`contentAlignX/Y`，构造器会回到START。`CjguiComposableUiInteractionStyle.resolve`即使normal状态也调用前者，window透明度/颜色与位移路径也使用这两个公共复制入口。以CENTER/CENTER基样式调用空交互样式的resolve或平移复制，应保留CENTER；当前源码确定会丢失。指导查看[宿主生成动作](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/dark-generated-english-action-1280x877.png)及[包外动作](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/ext/consumer-actionstyle-applied.png)，短中文、“Reset 42”和“应用”仍靠左。修共用复制归属，不能只让宿主绕开interaction、移除状态样式或改按钮宽度来伪装居中。
2. **公开纵向END被接受，却没有实现。** 构造器1227–1240接受START/CENTER/END；native的`CjguiComposableNodeCentersContent`（12542）和prepared几何（14921）只对CENTER处理，END仍走起始位置。补齐同一按钮内容框的纵向语义，保留缺省旧行为；不静默接受无效果值。`!prepared`绘字分支（15612附近）也没有设置段落对齐，先确认它在本能力中的可达性，再统一实际消费的几何/属性；不可达路径说明保护入口，不为证明覆盖强行启用另一套绘制。
3. **native缓存覆盖不能由region测试代替。** `CjguiComposableTextTextureKey`（12707）未包含新对齐事实；`CjguiRetainedLayoutRasterSource`（13655）只核持留布局宽度，纹理路径15858可按相同key及宽度复用旧prepared布局。现有PASSED 1只证明结构化region签名失效，未证明native重排/重绘。以同节点、同文字、同尺寸仅改变对齐做native或正常窗口反例，核对新accepted文字位置/像素；同时看retained credential是否来自当前声明。若其他保护确实阻断复用，给出其源码和反例结果，不硬改；若证实旧纹理/几何复用，在实际共同责任处修，不全局禁用缓存。指导本次确认源码缺少这些事实，未把未运行的native反例写成已复现。

上述问题属于已有H5-B，不需新授权。对齐属性运输存在、调用accepted、owner写入成功，都不能代替文字确实位于内容框中心。原反馈issue `8dca7fed997b494ea0c29516126f326c`已追加指导事件`ad4c05b4d6134c28aef9f2b857fea102`，更正`622417fb…`的过宽结论，重述已核SDK身份及原动作写入证据的范围；修复后继续追加本issue。

<a id="173"></a>
### 17.3 新观察：暗色详情的“启用”仍低可读

[最终暗色选中行原图](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5-label-geometry/verify-20261109/dark-selected-row-after-fix-1280x877.png)中列表文字已可读，但详情checkbox及“启用”文字接近深色背景。当前assets公开UI及验收私有UI的`field-enabled booleanInput`没有命名style；生成`styleFromDeclaredProperties`在无命名样式时使用缺省`CjguiComposableUiStyle()`。这是需要闭合的显示问题，尚不能仅据截图判定是disabled设计、宿主配方遗漏还是框架主题消费缺陷。

先核正常可写状态、accepted颜色/availability与最终像素，比较同一控件显式消费合适主题角色的结果；按实际归属修宿主配方或共同主题消费，保留只读/禁用语义，不全局强制白字。复用现有窗口补亮/暗及选中/未选中必要对照，确认点击写入正确owner。按§3.1处理即可，不等指导再次定性；与列表行已修问题分开记录，不能以“列表暗色已过”推导整页主题已过。已建issue `3915db8a6ad04e5a84aae18aa824adc0` / event `50fde7426e294851a828b05ce8eeafd6`，triage为needs_evidence（归属待区分，不是要求再获授权）。

### 17.4 有限验收与同一次交付

- 先保全样式复制的确定性RED，再修并验证normal/代表性交互状态、paint/translation的属性保真；用一个有区分力的native或正常窗口案例覆盖START/CENTER/END及仅改对齐的缓存更新。可合并检查，不为每个状态重建一轮完整应用。
- 最终同源宿主用正常actionStyle，现有包外应用用最终SDK，各取一次真实操作及owner读回；**实际查看**短中文、长中文、英文数字按钮的最终图像，结合内容框/字体行框判断，记录前后。不得仅保存截图、只核AX完整字符串或把截图中的靠左称为居中。顺带确认列表左对齐、完整行文字、输入和暗色“启用”未被改坏。
- 修复汇合后统一导出并更新当前SDK入口和包外依赖身份；保留已绿H3/H4/H5-A及不受影响的VO/性能/HTML矩阵。若使用旧私有UI验按钮，单独标明；原型交付仍给出默认assets配方正常入口的代表性画面，不将不同项目文档混成一个视觉结果。
- 追加本节发现的反馈以及实际source_fix/sdk_inclusion/consumer_verification；修好也要记。更正报告§52居中/缓存与“4 issue/6 event”（所列实际为7个事件）的口径，不抹掉旧证据。更新同一报告和ACTIVE一段当前摘要，集中报告真实完成项/遗留项/空间账，沿§13保护并行产物和自有实例收尾。当前未收口项解决后回到原目标交付，不因此重启全量验收或扩成新渲染工程。


<a id="175"></a>
### 17.5 执行结果：H5-B闭合与暗色启用（2026-11-09）

**H5-B。** `composable_ui.cj`两个paint/translation复制入口已转发`contentAlignX/Y`（[1393](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui.cj#L1393)、[1417](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui.cj#L1417)）。public RED在`overlay.contentAlignX == CENTER`失败，修复后PASSED 1/SKIPPED 1176。native新增共用`CjguiComposableContentTextRect`，prepared/fallback/credential同框；纵向END贴底、行高不变；纹理key与retained credential携带并对齐`textRect`。定向native测试14/14 PASS；故障注入对照实际5 PASS/7 FAIL（12项断言，非完整旧版renderer，见§17.6）（[日志](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/native-alignment/run.log)）。

**实际消费。** 宿主`fefd5b72…`/native`9a4b8c57…`暗/亮截图动作居中、列表左对齐；公开模型入口生成动作accepted v1→v2 `exact_readback=1`（[预览](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/model-apply.json)）。包外消费者由同源SDK重建`70bf07ad…`，手写动作居中，AXPress“应用”后owner 8201 draft/applied 0→1，正常关闭`INSPECTION_CLOSED`（[身份](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/external-identity.json)）。

**暗色启用。** 归属宿主生成UI文档漏命名style；assets `field-enabled`与settings `field-notificationSound`补`style body`后，暗/亮可读且checkbox可点，应用后会话`asset-0001 applied.enabled=false`、`fieldVersions.enabled=1`、`appliedVersion=1`（[验证](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/dark-enabled-verification.json)）。框架无关此issue改动。

**同源SDK。** ZIP `ec9237f666721a86e8328295fc24b520bcd9d0f5eeb62b94906d75f56550980f`，6,464,594字节（680条目=641文件+39目录，无AppleDouble）；锁`a630a7e6…`、manifest`3edd2cee…`、640文件/closure 613。旧`d3b6bc10`/`8f241283`仅回退基线。

**反馈。** H5-B issue `8dca7fed…` append event `f7bc9264cb30464fb2b7524a7ffeeb23`，再 append `6fdda62b72354854922ce9fd0486f55c` 更正ZIP打包身份；暗色 issue `3915db8a…` append event `72993c8105d84fb18bed01c8f8492dd0`；list 29 issue/125 event、complete、errors空（[原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/feedback-after-h5b-fix.json)）。

**边界。** 未重跑VO/性能/全平台；未改skill、未stage/commit/push或发布；候选仍experimental。空间与实例收尾见[报告§53.1](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-delivery.md#53)和[空间账](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/candidate/h5b-followup-20261109/space-account.json)。

<a id="176"></a>
### 17.6 指导复核：接受本轮交付（2026-11-09）

指导核对了相对旧H5包的源码差异、public/native测试原件、宿主亮暗与包外实际截图、模型提交/owner读回、会话原件及产物身份，接受本轮H5-B及暗色“启用”修复。没有新运行GUI、构建或测试；验证依据与边界见[报告§53.2](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-delivery.md#532)和[复核原件](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup/hot-review-h5b-closure-20261109.json)。

- 两个共用复制入口已保留对齐；native统一内容矩形、实现单行按钮END、将对齐纳入纹理key及retained布局检查。原图中普通/生成动作确实居中，列表仍左对齐。暗色“启用”使用既有body角色后可读，资产会话`asset-0001`应用值与版本已核；包外owner `8201`为另一条Apply证据。
- 最终ZIP `ec9237f6…` /锁`a630a7e6…`：640个manifest文件在ZIP/导出/包外三处一致，613项当前源输入全匹配，无AppleDouble；宿主`fefd5b72…`、包外`70bf07ad…`的源/准备源/native与可执行哈希均匹配生产构建记录。
- 修正测试口径：native GREEN是14项PASS；红对照是故障注入版本，实际12项断言中5 PASS/7 FAIL，且不是完整旧SDK renderer重跑。它证明定向断言能识别移除保护后的故障，不扩大为所有绘制路径回归。public复制的真实RED/GREEN另有原件，继续保留。
- H5-B追加指导事件`ef0914c06ad641ed92141e4227c40b67`；暗色issue追加`c5d136fb1ba94b5daca2761097d0c878`，明确应用配方已修、此项无需框架改动。修复已完成仍反馈；旧版本失败不删除，新版本通过不冒充旧SDK、其他平台或新一轮VO/性能验收。

本轮不再要求执行者补一轮同义确认或重复绿线。后续沿已交付宿主与SDK正常消费，出现新的实际问题时按§3.1处理；未出现新证据不重开本轮问题，也不把留白、列表左对齐、视口边缘部分行、未加载UI文档的生成区自动定为缺陷。
