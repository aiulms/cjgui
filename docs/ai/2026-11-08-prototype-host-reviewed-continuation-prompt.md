# 通用原型宿主：复核后续修与正常消费（含纵向 splitState）

继续推进 CJGUI 通用原型宿主，按“白名单修复 → 针对性验证 → 正常原型消费 → HTML 对照 → 问题记录”的顺序完成本轮，最后集中交付。这是实施指令，请持续完成授权范围内的工作，不停留在计划或建议，不逐补丁请示。

工作目录：`/Users/jiangxuanyang/Desktop/cangjie`。

## 一、目标、授权与已有成果

本轮目标是完成跨会话旧请求隔离、生成式步进器输入、标签隐藏、诊断关联、资产页窄窗布局，以及新纳入的纵向 `splitState` 拖动；随后让同一宿主二进制在三个原型中真实消费这些能力。

**只有第三节 A–F 是本轮修复白名单。** 旧方案、旧报告、技能建议以及“已定位根因”“修改很小”都不能增加授权。开发中发现的其他既有缺陷、新能力需求只允许调查、保留复现、记录并提出建议，不允许同步修复。`triage=framework_fix` 不构成实施授权。

本轮实现直接引入的回归、编译错误，以及完成白名单必要的测试、公共声明、客户端接线和文档更新属于原任务，不能借此包入其他既有问题。某项受未授权问题阻塞时，仅暂停受影响部分，继续其他独立任务；不降低条件、重投刷绿或增加绕过来宣称完成。

复用现有宿主、三个项目、HIG 主题、catalog/region、公开客户端、项目 owner、界面文档、session v2 和反馈脚本。保留 R2 全记录草稿检查、R3 动作变更前置拒绝、R4 统一选择事件入口、R8 次行选择等已有有效成果，不重新做一遍。本轮推进共同框架的身份隔离、生成式控件接入、几何与捕获正确性，不新建宿主、不重造控件、不引入其他 GUI 框架运行时。

用户已将 skill 优化交给其他模型。**本轮不优化 skill、不修改其脚本或通用规则，只按既有格式记录实际问题及处理结果。**

## 二、接续材料与身份

先读取：

- [仓库规则](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md)。
- [ACTIVE 的 E 线](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/ACTIVE_DIRECTION.md)。
- [既有交付报告，重点 §19–21](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-11-08-prototype-host-delivery.md)。报告中的“已完成”须按本提示词复核结论校准。
- [cjgui-app-dev 入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/skills/cjgui-app-dev/SKILL.md)及其[反馈指南](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/skills/cjgui-app-dev/references/feedback.md)。仓颉实现按已安装的 cangjie-coding 查询必要知识。

宿主：[prototype_host_app](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/prototype_host_app)。

原型证据：[evidence](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence)；原型反馈：[feedback](/Users/jiangxuanyang/Desktop/cangjie/work/prototype-host-20261108/evidence/feedback)。

小说工作台的新问题原件：[反馈目录](/Users/jiangxuanyang/Desktop/小说工作台/artifacts/acceptance/v4-coreflow-20261108/feedback)及[上游问题记录](/Users/jiangxuanyang/Desktop/小说工作台/docs/上游问题记录.md)。该应用实际消费副本为 `/Users/jiangxuanyang/Desktop/小说工作台/deps/cjgui`，桌面成员为 `/Users/jiangxuanyang/Desktop/小说工作台/apps/novel_desktop`。

上次原型宿主审阅的候选 SHA 为 `f1552dc6856c6cb125e2d5b41f04e0a0abe8640e594f3839b1aaaeb2521bf826`，只作接续基线，不假定当前工作区未变。应用部分先按技能识别实际依赖，分别核对参考源码、构建/native 输入和运行实例；Git HEAD、目录名和历史 `verified` 不代替当前身份。

按 AGENTS 使用代码理解工具；索引缺失或覆盖不足时回到源码，不将图分析当运行证据。指导已核对下述缺陷源码，未在此次审阅中重跑窗口；实施者须取得针对性反例和修复后正常消费证据。

## 三、本轮修复白名单

### A. R1：真正隔离旧会话请求

当前 `PrototypeHostBridge` 使用 `observedGeneration`。切换后，任意公开读取会重新打开写入门，随后旧请求也能通过。现有测试明确断言“读一次新会话后，同一个旧候选被接受”，这不是跨会话隔离。

要求：

- 写请求绑定其创建依据所属的项目/会话身份，并在执行时核对，优先复用既有身份、版本机制。允许最小调整桥接、既有共享入口和公开客户端，不另造 RPC 或通用会话框架。
- 读取新会话不能替旧请求补上新身份；不能自动重新取版本、刷新代际后重投旧请求来刷绿。
- 保持同一 descriptor 下发现新项目、创建新请求和继续操作的能力。结构提交、业务写入及受影响的界面历史操作保持一致的隔离语义；旧格式不能静默解释成“当前会话”。
- 新项目准备失败仍保留旧项目、连接和状态。

反例必须包含：A/B 字段兼容、局部数值版本相同；在 A 创建并保留请求，切到 B，同一或另一客户端读取 B，再投递 A 的旧请求，仍须拒绝且 B 的界面与 owner 不变；基于 B 新创建的合法请求正常完成。旧业务写入也必须覆盖。

先取得能区分方案的 RED，再修正实现和测试期望，不继续围绕“是否发生过一次读取”增加条件。

### B. R9：步进器接入完整收口

本项属于原 R9 未完成。已确认：内部输入节点使用新 node ID，却未完整接入生成式字段身份映射，普通事件解析可能返回 `unknown_node`；去重使用节点 ID 加 region revision，普通刷新不保证推进该 revision，后续独立点击可能被吞掉。

要求：

- 将内部输入接回既有 accepted/candidate 身份、字段 writer 和 owner 路由，不绕过共同输入路径直接写业务值。
- 键入、±、校验、Apply/Cancel 共用同一字段和草稿；保留字段主题、可见标签、可访问名称和错误反馈，不能用裸步进器替换整个绑定字段语义。
- 每次合法独立点击产生对应步进；真正重复投递同一事件与两次独立点击必须区分。不能用刷新代、时间间隔或人为放慢输入代替事件身份。
- 只处理所属控件的有效输入，保留禁用、只读、旧节点身份拒绝等既有约束。复用 `CjguiNumericStepper`，不另造控件或第二套状态机。

验证键入整数 → draft → Apply → applied，清空/非法值、纠正、Cancel 和已有边界行为；在初值和 min/max 允许全部变化的条件下，连续点击同一个按钮，核对合法输入数和最终值，并检查重复投递不会重复写入。

保留“44 次点击只前进一步”的原记录并说明当时边界条件。不能把越界拒绝、工具未发送事件和框架吞输入混为一谈；不以重试、重新聚焦、延时或减少输入次数代替修复。

### C. R7：绑定字段真正隐藏可见标签

已确认：生成分支在 `labelVisible=false` 时传空 `editorLabel`，但 `cjguiComposableBoundFormField` 将空值回退为 `descriptor.label`。随后设置 `semanticLabel` 不会隐藏已经生成的可见标签。

明确区分可见标签控制、默认标签回退和可访问名称，修通绑定字段及相关生成路径，保持默认行为兼容。普通输入和步进器均正确消费；不使用 U+200B、特殊文本 sentinel 或私有 AX 修改绕过。

验证默认标签、显式隐藏、未显式填写 label 的合理回退，同时检查可见结果、AX 名称、输入及 owner 写入。AX 检查不冒充完整 VoiceOver 验收。

### D. R6：诊断对应当前失败候选

已确认：`clip-r6-3.log` 后一次 `internal_error` 仍打印前一次裁剪超限的诊断链。

只修诊断关联：诊断必须对应实际候选/失败；当前失败没有布局诊断时不能把旧诊断作为当前原因。通过最小清理或身份关联完成，保持只读观察、原错误 token、容量和回滚语义。

覆盖“容量失败 → 无布局诊断的失败”及随后正常候选，避免串用旧信息。本项不授权修 issue 10 未知根因，不提高容量、不修改裁剪算法。

### E. issue 08：720 窄窗宿主布局接入

现象成立，但“普通 vertical 应改 stack”的归因已被指导否定。`prototype-narrow-body` 位于 horizontal 父容器中，仅设置 growY，未设置该交叉轴要求的 `alignY: STRETCH`，现有布局文档已说明这一要求。

先按已有公开配方补齐窄窗列的伸展责任，保持纵向排列，不直接改为叠放子项的 Stack。验证 720 下详情字段可见且可滚动、列表展开/收起正常、恢复宽窗正常。

在原 issue 追加修正归因，保留原始截图和旧结论。明确接入修正后若仍有另一种缺陷，记录可区分证据，不借此扩大为布局引擎修改。

### F. 新批准：纵向 splitState 拖动的轴处理

来源：小说工作台 issue `11fc8ed7e1b74b76815eca77743a93b7`，event `81272a1874aa4cd293efa2b2e1b6bb19`。

指导已核实：公开 `cjguiComposableScopedSplitView` 同时接受 `axis=VERTICAL` 和 `splitState`，但共同窗口的拖动路径仍只取 `pointerVisualX`，调用 `applySplitStatePointerDrag(windowX, …)` 与 `windowToSplitTrackPointX`。抓取偏移、轨道原点和捕获匹配也按横向假设处理。上述相关函数在小说工作台依赖副本与当前主树中相同，问题仍存在；这是框架缺陷，不是应用漏接或仅缺一个组件。

维护入口：

- [共同窗口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj)：`applySplitStatePointerDrag`、抓取开始、更新/结束、`rememberSplitCaptureBinding`、`splitCaptureBindingMatches` 及直接相关捕获状态。
- [共同几何与 split 声明](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui.cj)：`CjguiComposableUiVisualGeometry`、`CjguiComposableUiSplitState`、`cjguiComposableScopedSplitView`。
- [既有平移/捕获测试](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_translation_test.cj)：复用横向映射、自己的拖动与独立修改区分等已有反例。

修复范围：

1. 按声明轴选择主轴坐标、尺寸和轨道原点；横向保留 X，纵向使用 Y。补 Y 等价映射或最小轴参数化实现，保持现有公开调用兼容。
2. 修通整条状态绑定拖动路径，包括开始时的 grab offset、更新/结束、accepted 几何映射、捕获身份与约束匹配。不能只在更新分支替换一个 X。
3. 区分“分隔条沿主轴移动的正常结果”和“独立修改了轨道/绑定/祖先几何”。自己的连续拖动及接受后的重绘不能误取消捕获；真正失效的旧捕获仍须按既有契约取消。
4. 沿已有 accepted 场景几何、平移和精确坐标规则计算，保持必要的一次量化；不混用屏幕坐标、窗口坐标、旧 bounds 和新 firstSize。
5. 保留两侧最小尺寸、边界夹紧和视图状态归属。修共同仓颉机制，不给小说工作台写特例，不以应用私有 Y 拖动替代框架修复，不重写整个指针系统。

验收：

- 用公开接口和当前主树保留最小纵向 RED，记录输入及 `splitState`/accepted 尺寸前后值。
- 纵向上下连续拖动跟手；分隔条不同位置按下后不移动再释放不跳变；拖至两端按最小尺寸夹紧，再拖回正常。
- 连续拖动跨越自身接受/重绘仍有效；使用已有捕获契约核对独立变更后的取消，避免放宽身份检查。
- 使用非零容器原点、已有平移场景验证映射；做受影响的横向回归，不重开全部指针、平台或编辑器矩阵。
- 取得真实窗口中的正常公开消费，标明物理/合成输入条件，不能只交几何公式单测。通用原型宿主已有 split 入口能消费时，接入一次上下分区操作；若生成入口有其他未授权缺口，记录并用正常手写公开消费者验证，不另造生成协议。

小说工作台依赖副本保持只读。不要自动升级或覆盖其 `deps/cjgui`、`deps/editor-core`，不要删除现有 `novel-split-drag`。本轮维护源修复及正常消费者通过后，给出接回条件；未在新依赖上验证工作台，就明确“应用回接未验证”，不将主树通过当作它已修复。

## 四、只审查或记录的问题

- **R5 的普通 VERTICAL 自然宽度变更：**此前仅批准水平测量。核对额外变更的必要性、影响及与 R9 的依赖，提交保留/撤回建议；可以运行直接相关现有测试。不自动追认、不扩改、不盲目覆盖或撤回其他任务代码。水平容器已有反例保留。
- **issue 10 的 probe2 internal_error：**日志指向 `participant_prepare`。调查探针树、生成区域准备和启动文档载入的关系，取得最小复现与失败点；不认定为渲染器缺陷，也不因正常入口暂未复现就宣布无影响。本轮不改其未知核心机制。
- **原型空态文案、清除入口、筛选后旧详情、窗口标题等：**继续核对和记录。旧详情区分截图时点、选择状态、可见状态与真实 owner，不仅凭截图断言错误写入。
- **小说工作台重复 node ID，issue `20392b9feff84a6199b6750cf31ae242`：**当前主树及该依赖副本已有 `duplicate_node_id` 校验、拒绝保旧和窗口进度诊断，不能按“框架完全缺少唯一性校验”开发另一套机制。需要时核现有诊断的应用消费，不新增框架修复。
- **ScrollArea 末尾跟随，issue `ba646cfd5e04414690d6cef94f1532ab`：**现有 API 区分 requested/accepted offset，并声明 requestOffset 按已接受范围夹紧。当前证据支持应用跟随策略或文档配方成本，未证明框架违反契约；不将 2s 重试窗口固化为框架机制，不扩做自动跟随引擎。
- **退出 provider，issue `c61db6fbd77848d9bb73cce6bcc994d3`：**应用补接退出决策 provider 后已有通过记录；现有契约由应用决定退出。保留接入事实，不改默认退出语义，也不自动强制退出。

其余新发现继续只调查和记录。上述分类仅限定本轮范围，不删除原始观察。

## 五、修复后继续通用原型宿主开发与消费

不能只交单测和探针。A–F 汇合后，回到同一候选二进制与三个项目，完成受影响的正常连续操作。

- **settings：**两列表单、标签/AX、segmented/select、步进器键入与连续点击、错误反馈、Apply/Cancel；验证受影响的运行时新增字段、有草稿重排和保存重开。
- **assets：**保留 200 条记录、筛选、滚动、标题/次行选择、详情编辑；重点验证 720 与恢复宽窗、项目切换后的模型读写归属，保留非当前记录草稿保护。
- **materials：**保留 12 张卡片、列数调整、选卡、缺图占位与详情，用于检查公共修改的另一领域消费，不另写专用修复。
- **分隔布局：**按 F 消费已修复的公开 splitState，复用一个最小消费者或宿主既有入口，不新建庞大样例。

至少完成一条真实模型公开链：发现当前能力 → 创建/修改结构 → 接受并读回 → 正常窗口输入 → owner 读回 → 继续编辑 → 保存重开。

允许在已有项目声明中变换字段、布局和绑定以验证通用性，主体继续来自声明和 `cjgui.ui-document`，不按案例名硬编码整页。区分“同一二进制打开不同项目”和“运行期修改不重编译”；框架修复后的必要重建不代表每次原型修改都要重建。

## 六、HTML 对照与问题回接

继续以 macOS HIG 为视觉与交互参考，借鉴 ArkUI 的组件和布局思路。复用独立 HTML 三页，共享需求、初始数据、目标状态和窗口条件，各自实现状态与交互；HTML 本身也要核对。

重点对照标签是否重复、输入是否可辨认、步进及错误状态、720 详情和滚动、连续编辑、保存重开，以及既有 B/C 空态与滚动态差异。沿原定 1280/960/720 条件取必要证据，记录内容区尺寸、主题、缩放；复用未受影响结果，不为凑截图数量重做全部。

截图和布局诊断证明外观，输入和 owner 读回证明行为；DOM、AX、截图、accepted 回执不能互相代替。不要求逐像素一致，不降低需求或减少负载来消除差异。新的差异进入记录，不自动获得修复授权。

使用现有 `feedback.py list/show/create/append`，只做问题记录，不优化 skill：

- 上次原型目录为 10 issue/22 事件，小说工作台目录为 4 issue/5 事件，开工以实际为准。
- 同一问题追加完整观察，新问题才 create；保留 RED，用 supersedes 指明被推翻的旧事件，不覆盖原件。
- 回接 A–F 的事实和结果，修订 08 的归因。F 关联小说工作台原 issue/event 与新维护源反例；跨应用记录用 links 关联，不复制覆盖其历史。
- 分别记录 `source_fix`、`sdk_inclusion`、`consumer_verification` 的实际版本和范围。“尚未修/待证”不能写成 `not_needed`；checkout 消费通过不等于导出 SDK 包含或正式发布。
- 必要公共 API 文档和配方随实现更新，新属性不能只在宿主 README 中出现。未经确认的问题不写成公共限制。
- 报告引用的 `app-tests-r9-final.log` 上次未在所指路径找到：优先找回真实日志并纠正链接；找不到则标缺失，不能凭文字补造成功证据。
- 默认本地保存，不自动发消息、上传或创建外部 issue。

## 七、验证、保护与空间

先保留明确 RED，再做最小修复；修改汇合后完成必要回归和正常消费。按 [AGENTS](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md) 做相关测试、必要根 `cjpm build --skip-script`、`git diff --check`、公共声明与禁止行为检查。不重复无关旧矩阵，不新增正式 VoiceOver、其他平台追平或发布门槛。

同一 cjpm target 的 build/test 必须串行。先检查脏工作区，保护并行改动；不 stage/commit/push，不恢复旧执行线，不自动调用外部顾问、创建新用户线程或额外代理。

桌面操作沿 agent-desktop 和既有授权，保护用户实例，复用自有验收实例，按准确身份收尾。必要窗口输入区分物理、合成、AX 与模型调用，不混写证据等级。

遵守 [产物容量与收尾](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md#artifact-space-budget)：默认本线新增保留不超过 10GiB，预计峰值后宿主至少保留 20GiB。高写盘前重查，复用构建和证据目录，只清理本任务明确归属的冗余产物，保全必要原件。

## 八、集中交付

继续维护既有交付报告和 ACTIVE E 线当前摘要，不另建执行卡或第二套台账。保留历史，但纠正当前“R1–R9 全部完成”等不成立的表述。

最终一次性报告：

1. A–F 各自实际解决的问题、实现与验证结果，完成/部分完成/受阻及其证据。
2. 三个原型和分隔布局的可见效果、正常连续操作结果。
3. HTML 对照变化和剩余差异。
4. 源码、构建/native、运行实例、候选身份与最短启动/连接方法。
5. 原型及小说工作台反馈的回接关系，新增但未修的问题、原因与建议优先级；SDK/外部应用回接未验就明确保留。
6. 只调查项和未通过项；下一轮建议不等于本轮授权。
7. 新增、保留、实际释放量、剩余空间及在用输出路径。

完成已授权整包后集中交付。测试数、截图数、文档数和“已记录问题”不能代替应完成的修复及正常使用结果。
