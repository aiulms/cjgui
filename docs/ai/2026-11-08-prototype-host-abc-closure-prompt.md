# 通用原型宿主：A/B/C 收口、F 补证与公开模型连续编辑

**历史归档，不再作为当前执行指令。** 唯一执行入口为[通用原型宿主完整实施提示词](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/2026-11-08-prototype-host-blocker-decisions.md)，已包含本文件的仍有效目标、全部剩余工作及最新授权。执行者无需阅读或拼接本文件；下文仅保留当时的任务与证据背景。

工作目录：`/Users/jiangxuanyang/Desktop/cangjie`。

## 1. 本轮目标与授权

本轮推进两项可复用能力：同一公开连接在项目切换后仍能正确连续编辑；生成式字段与普通绑定字段共享主题、校验、可访问名称和输入约束。原型同时消费框架、暴露缺口，不以样例变好看或测试数量增加代替框架能力交付。

**修复白名单只有下文 A/R1、B/R9、C/R7，以及 F 原有轴映射/捕获范围内尚未完成的接线。** D/R6、E/720 保留既有成果，不从头重做；F 以补证为主。只调查项和其他新发现不得同步修复，`triage=framework_fix`、定位了根因、改动很小、旧报告中的建议，都不增加授权。

允许完成白名单直接需要的共同源码、窄平台接线、公开客户端、应用接入、测试与文档调整，以及修复本轮直接引入的编译错误和回归。不得借“解阻塞”修其他既有缺陷。若被未授权问题阻塞，只暂停依赖部分，记录事实，继续独立工作；不绕过约束、替换验收入口或降低要求刷绿。

复用现有 `CJGUIPrototypeHost`、三个声明项目、HIG 主题、catalog/region、真实 owner、NumericStepper、界面文档、session v2、公开 Python 客户端和反馈脚本。保留 R2 全记录草稿保护、R3 声明原子性、R4 选择提交、R8 整行选择等成果，不另造宿主、组件、业务状态机或协议体系。

**用户已把 skill 优化交给其他模型。本轮只使用现有 skill 记录问题，不修改 skill 的脚本、通用规则或安装分发。** 不自动调用外部顾问、创建用户线程、启动额外代理、恢复暂停任务；不 stage/commit/push。

## 2. 必要上下文与已追加反馈

先读 [AGENTS](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md)、[ACTIVE E 线](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/ACTIVE_DIRECTION.md)、本提示词、[交付报告 §22–23](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-delivery.md)，再读直接相关源码。§22 的“A–F 全部完成”已被 §23 复核纠正，不能沿用为当前结论。

应用部分加载 [cjgui-app-dev](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/skills/cjgui-app-dev/SKILL.md) 和 [反馈指南](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/skills/cjgui-app-dev/references/feedback.md)，识别实际依赖；仓颉实现先加载已安装的 cangjie-coding，按需查询。代码理解工具按 AGENTS 使用，索引覆盖不足时回到源码，图结果不作运行证据。

维护对象：[宿主](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app)、[证据目录](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence)、[反馈库](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/feedback)。本次指导已追加以下完整观察，原件保留，旧完成/归因结论用 supersedes 指明：

| 项 | 原 issue | 本次指导 event |
| --- | --- | --- |
| R1 版本一致性、无身份请求、历史测试 | `0858e5dc1ed5466a897dbbe3601c4062` | `83f3c777edca4af1b5eb2584141d9b76` |
| R9 完整字段语义与 accepted 节点检查 | `df00aec86b6e43c98a1da865b5721438` | `8f00f1ae03d14f859673984741242dfb` |
| R7 最终可见标签反证 | `ee2d46d74301434cb27be11e0d288489` | `a13aa4024fa4432ca3eaaebb8ebf81b6` |
| 窗口单测归因待证 | `8a9a83d150d44e4fa0b2437b1fa6c094` | `4590250f0f8347f9a07903e690c679ed` |

追加后为 14 issue / 37 event，开工以实际 list/show 为准，不覆盖别人的新事件。[复核原件与回执](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/review-followup) 包含带文件 SHA 的源码片段、观察输入和 append 回执。指导只读源码、原日志和截图，未重跑窗口；不要把静态复核写成动态 RED。

复核候选 bundle SHA256：`6cd5290f6f8436f15ab3a44b32b7fabe04aa47e59c627c66eb64522458dc5752`。当时 build-provenance 的 482 个 source_files 仅两个后来补改的测试文件不匹配，464 个 prepared_sources、2 个 native_libraries 匹配。当前源码/构建/native/运行实例仍须分别核身份，不能只看历史 `verified` 或 Git HEAD。未导出 SDK，小说工作台没有消费本轮主树修复。

## 3. A / R1：会话隔离必须与正常公开编辑同时成立

入口：[PrototypeHostBridge](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_bridge.cj)、[region](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated_region.cj)、[公开编辑客户端](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core/cjgui_generated_edit.py)、[桥测试](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app/src/prototype_bridge_test.cj)。

已确认的遗漏：

- 桥给 accepted/candidate 版本及部分响应加 `sessionVersionBase`，但原子快照等载荷原样透传。快照的 `ACCEPTED_STRUCTURE_VERSION` 来自区域原始版本；公开编辑客户端从它构造 base_version，再原样提交，切项目后与桥入站版本空间不一致。
- `executeFromExternal` 遇负版本仍转发当前 domain。跳过数据版本比较不等于可以跳过会话归属；旧的无身份请求不能悄悄变为 B 项目的新请求。
- 历史隔离测试读取了 A/B payload，却提交固定 `surface=0 / epoch=0 / digest="digest"`，只断言拒绝。它没有证明真实旧历史请求被正确隔离，也未证明 B 新历史请求可用。

实施要求：

1. 复用已有会话/endpoint/版本机制，选择完整一致的最小方案。可以补齐版本带的公开消费接线，也可以在既有请求上明确会话身份；不要另建 RPC 或通用会话框架。所有受影响的读取、计划、提交、候选回执和读回须能相互对应。
2. 区分结构版本、owner 版本、历史版本、游标与持久化文档版本；不能对所有数字做字符串替换或统一加基址。版本发布和核对遵循各自的真实作用域。
3. 无身份的外部写请求须明确拒绝或通过既有入口携带可验证身份。若保留负版本“忽略数据版本冲突”的语义，仍必须核会话身份；不能在执行时自动取 B 的身份给 A 请求补票。不要因此擅改所有应用的全局默认契约。
4. 读取 B 不得给 A 旧请求重新授权；同一 descriptor 下 B 的合法新请求必须正常完成。保持新会话准备失败时旧项目、连接与状态不变。
5. 历史操作优先复用已有 surface/epoch/digest 约束。若既有实现正确，只修错误的测试和验收结论，不为补证重造历史机制。

必要反例与验收：

- A/B 字段兼容、局部版本相同。在 A 留存结构与业务请求，切 B，先由同一或另一客户端读取 B，再重投 A 原请求；仍拒绝且 B 的结构、draft/applied 不变。
- **必须经正常 `cjgui_generated_edit.py`：B 原子快照 → 新建 plan → preview → submit → 候选终态 → 精确读回 → 第二次续改。** 不手工加基址、不私改版本、不用专用客户端代替。受影响的保存计划/回执路径一并核对。
- 覆盖无版本/负版本旧业务请求；B 合法的新业务写入成功并读回实际状态，不能只断言 reason 不是 stale。
- 构造真实可撤销历史，保留 A 的真实 surface/epoch/digest/version。切 B 并读取后，A 请求因身份拒绝、B 文档不变；使用 B 的真实基线，合法 undo/redo 可成功。拒绝原因须能区分身份失配与伪造参数、历史未启用、无可撤销项。

## 4. B / R9：补齐字段呈现、约束和事件身份

入口：[生成控件](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated.cj) 的 `generatedIntegerStepperNode` 与绑定分支；[region 事件处理](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated_region.cj)；[已有 NumericStepper](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_field_controls.cj) 与 [表单绑定](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated_form_binding.cj)。

输入子节点映射、只消费 ACTIVATE、按输入身份区分独立点击已有成果，保留。尚未完成的是：绑定分支提前返回裸 stepper，未传字段 validationError、已解析主题/交互样式，辅助构造写死 readOnly=false；步进分支仅按 actionName 前缀直接写字段，没有经过当前 accepted 控件身份检查。

实施要求：

- 只替换字段编辑器的呈现，保留同一字段的 owner、草稿、校验事实、帮助/不可用原因、主题与错误态。复用现有绑定字段和 NumericStepper 能力，不复制业务校验、不创建第二套 owner。
- 已解析的输入/按钮主题及交互状态实际到达控件；只读、禁用与错误状态来自同一字段事实，不写死，不以默认样式掩盖缺口。
- 步进事件进入与普通字段等价的 accepted 身份核对：节点仍存在、仍是此 stepper、字段/writer/owner/incarnation 匹配且允许输入。已删除/重绑的旧节点不得写入；只检查动作前缀或最终 owner 相等不够。
- 保留每次独立点击对应一次步进、真正重复投递不重复写入；不恢复刷新代去重，不用延时、重新聚焦或减少输入次数绕过。

验证：正常输入 → draft → Apply → applied；清空、非法/越界、纠正、Cancel；普通整数输入和 stepper 对照同字段错误及可见反馈；禁用、只读、已删除/重绑旧节点的事件拒绝且状态不变；足够上下界余量下连续独立点击和真实重复投递。旧“44 次点击”的原记录与边界说明继续保留，不反复重做已能解释的整段操作。

## 5. C / R7：把可见文字和可访问名称贯通到最终输出

交付的 [assets-final-edited.png](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/whitelist/assets-final-edited.png) 仍显示 `component-10-1`、`component-22-1`，数量框重复显示“数量”。不能继续按“AX description 正确”宣称视觉隐藏完成。

源码线索：窗口在 node.label 为空时用 semanticLabel/semanticId 回填局部变量，再把它作为 `nativeBatch.addStagedNode` 的 **label 可见文字参数**传出；该函数另有 semanticLabel 参数。沿普通同步、增量更新和实际 native 绘制/AX 路径核对，不只改仓颉节点树。

实施要求：

- 可见 label、semanticId、可访问名称各走已有正确通道。labelVisible=false 时最终绘制不出现标签或内部 ID，业务可访问名称仍存在；不使用 U+200B、特殊 sentinel、私有 AX 补丁或删除语义来隐藏文字。
- 普通 text/integer/boolean 与 stepper 的相关生成路径保持一致。未显式写 label 时按已有字段声明合理回退可访问名称；显式隐藏不能恢复可见默认标签。
- 默认显示标签、按钮等既有展示保持兼容。优先用已有 native label/semanticLabel 字段补接，不增加一套传输协议；必要的窄平台修正属于 C。

验收必须分别给出：最终画面（无内部 ID、无重复标签）、AX 名称、实际输入/owner 读回。覆盖默认显示、显式隐藏、隐藏但未显式给 label，以及更新/重开后的结果；复用现有 native 标签值和 AX 相关测试。图像审阅用于发现可见反证，不要求逐像素一致；AX 通过不冒充 VoiceOver。

## 6. 保留 D/E，补齐 F 的受影响验证

D/R6 候选边界清理诊断、E/720 窄窗 `alignY: STRETCH` 已有实现与对应证据，保留。此次修改不触及它们时复用旧证据，在正常汇合消费中确认即可；不重新扩裁剪容量、不改为 Stack、不重复整套探针。

F 纵向 split 的主轴映射、grab offset、捕获匹配已有共同实现；`--split-demo` 已取得拖动、夹紧和拖回结果。继续使用现有 [平移/捕获测试](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_translation_test.cj) 与最小公开消费者，补尚未证明的关键边界：

- 在分隔条不同位置按下、不移动即释放不跳变；非零容器原点及平移下映射正确。
- 连续拖动跨越自身 accepted 重绘仍有效；独立修改绑定/祖先几何后旧捕获正确取消。
- 受影响的横向路径正常，保留最小尺寸、边界夹紧和 accepted 几何规则。

只修原 F 轴映射/捕获范围的明确遗漏或本轮直接引入的回归。其他新机制问题记录后交指导，不扩成整个指针系统重写。纯逻辑、正常窗口和窗口测试各注明覆盖范围，不能相互冒充。

小说工作台的 `deps/cjgui`、`deps/editor-core` 和现有 `novel-split-drag` 保持只读，不自动升级或删除 workaround。主树消费通过仍不等于该应用已修；维护反馈关联和回接条件即可。

## 7. 只调查/记录，不能同步修复

| 问题 | 本轮处理边界 |
| --- | --- |
| 窗口级单测首场景失败，`8a9a83d1…` | 现象成立，环境归因未证。只有能改变 F/R6 验收结论时才做最小同条件源码/native基线对照；不反复整包重跑、不以“旧测试名也失败”排除回归，不授权新的 runner/native 修复。 |
| issue 10，`9fd477c8…` | 保留裁剪回滚与 participant_prepare 失败的时序证据；根因未定，仅调查，不改未知核心机制。 |
| R5 普通 VERTICAL 自然宽度额外分支，`0643156b…` | 现有代码不盲目回退。补与 R9 直接相关的必要性/影响证据并提出保留或撤回建议；上一轮执行者写“保留”不等于指导批准。不得扩改布局引擎，也不要求为此跑全框架矩阵。 |
| 重复 foreign 声明，`39d4382e…` | 执行者已经删了重复声明。保留实际变更和编译证据，注明其超出原 A–F 列举范围，不借此开展测试基础设施整治，也不盲目覆盖他人的修改。 |
| 空态文案、清除入口、筛选后旧详情、窗口标题等 | 核对事实后记录；区分选中记录、可见集合与 owner，不仅凭截图断言数据写错。本轮不新增这些功能。 |
| 小说工作台滚动末尾跟随，`ba646cfd…` | 当前属于应用策略/公开配方易用性，未证明框架违约。保留 requested/accepted offset 与上滚取消跟随的事实，不实现自动跟随引擎、不把定时重试固化为框架机制。 |
| 小说工作台重复 node ID / 退出 provider | 已有 duplicate_node_id 校验与拒绝保旧；应用补接退出 provider 有通过记录。不能据旧表述重造校验或改变默认退出契约。 |

其他新发现同样只调查并记录。反馈列表中的其他 issue 不是自动修复清单。以上限制不取消它们的长期价值，只限定本轮授权。

## 8. 修复后继续通用原型宿主与 HTML 对照

使用同一最终候选二进制、现有三个项目完成连续消费，不只交单测和探针：

- settings：两列表单、完整 stepper、标签/AX、错误态、Apply/Cancel。以现有声明重载入口新增字段，公开能力可发现并接入 owner；有草稿时通过公开编辑计划重排，按字段 ID 保留值，保存重开不隐式 Apply。
- assets：保留 200 条记录，筛选/滚动/整行选择/详情编辑；720 可见与恢复宽窗；切项目后的模型读取和写入确实对应新 owner，非当前记录草稿保护仍有效。
- materials：保留 12 卡、列数调整、选卡、缺图占位与详情，作为另一领域的公共能力消费，不写该案例专用补丁。
- 分隔布局：复用 F 的最小公开消费者，不增加庞大样例。

至少完成一条真实模型链：公开 descriptor 发现能力 → 原子快照 → 生成/修改并精确读回 → 人在正常窗口输入 → 模型读回 owner → 切到另一项目 → 拒绝旧请求 → 新快照创建新计划并连续修改 → 保存、重开和续改。主体始终来自项目声明与 `cjgui.ui-document`，不按案例名硬编码整页，不用人工改版本证明客户端可用。

继续以 macOS HIG 为视觉/交互参考，借鉴 ArkUI 组件与布局思路；复用独立 HTML 三页，保持同需求、数据、状态、主题和内容区条件。重点比较标签、输入内容、stepper 主题/错误态、720 详情与滚动。沿 1280/960/720 条件补受影响证据，复用无关旧结果，不凑截图数量、不要求逐像素复刻，也不修改 HTML 需求来迁就 CJGUI 缺口。

记录这次真实公开链的首个可交互结果和连续修改耗时、是否重编译/重启、拒绝及保旧结果；使用同一范围的前后证据，不把单次提交耗时等同整体开发效率。新视觉/交互差异进入反馈，不自动扩修。

## 9. 反馈、验证与资源保护

用既有 `feedback.py list/show/create/append`。同问题 append，新问题才 create；完整记录 goal/expected/actual、身份、复现、证据和下一步。必要原件复制并哈希，使用 supersedes 纠正具体旧结论，保留有效成果和历史失败；跨应用只 links 关联。

R1/R9/R7 的新修复须追加到上述原 issue，回应本次指导 event。窗口测试归因有新证据再更新；未定位仍为 needs_evidence。分别写 source_fix、sdk_inclusion、consumer_verification，不把源码已改、checkout消费、导出SDK和外部应用升级混为一谈。更新公共 API/配方文档，不改 skill 通用实现，不上传或创建外部 issue。

先取得能区分问题的 RED，再做最小修复。保留失败用例，不通过删除有效断言、伪造参数必拒、重投或替换测试范围取得绿色。确有测试自身错误，保留原件、说明纠正原因，并给出仍覆盖原行为的有效测试。最终日志须与实际编译输入及测试名称对应，防止再次使用陈旧测试二进制。

按影响范围完成针对性测试、必要框架根 `cjpm build --skip-script`、`git diff --check`、公共声明/受保护路径及禁止行为检查；相关改动汇合后统一回归，不逐补丁跑全平台矩阵。验证必须改变实现或验收结论，遇到低收益反复失败先调整方法。未过项如实保留，不能改名成环境已排除或完整完成。

同一 cjpm target 的 build/test 串行，保护混合脏工作区。桌面按 agent-desktop 与现有授权，复用自有验收实例、保护用户实例；输入证据分别标记物理、合成、AX、模型。正常视觉消费必须实际查看画面，不能只靠 AX/stdout。

遵守 [产物容量与收尾](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md#artifact-space-budget)：高写盘前核空间；默认本线新增保留不超过 10GiB，预计峰值后宿主至少余 20GiB；复用既有工作目录，保留必要 RED/GREEN 原件，只清理本任务准确归属且已退役的冗余产物。没有新理由不复制整套 target/SDK/夹具，不自动清理用户或其他任务文件。

## 10. 集中交付

继续维护既有交付报告，在 §23 之后写本轮实际结果；ACTIVE E 线只保留一段不超过 600 字的当前摘要。不另建执行卡或第二套状态台账。

最终一次性报告：

1. A/B/C 实际修复和 F 补证结果，完成/部分完成/受阻逐项对应真实证据；D/E 复用与受影响范围。
2. 正常公开模型连续编辑、三个原型及分隔消费的实际效果；HTML 对照变化和剩余差异。
3. 当前源码/构建/native/运行身份、最终候选哈希、最短启动与公开连接方式。
4. 本轮反馈 issue/event、修正了哪些旧结论、新发现但未修的问题；未导出 SDK、未回接小说工作台等边界。
5. 必要检查、未通过项、仍需指导决策的具体问题；下一轮建议不是本轮新增授权。
6. 空间账：新增/保留/实际释放、宿主余量、在用输出路径及原因。

完成授权整包后集中交付；不能把测试数、反馈数、AX 名称或某条 accepted 回执当成全部用户目标完成。
