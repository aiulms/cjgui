# 大阶段：通用交互状态、组件样式与主题

2026-09-14，原目录由 Terra/xhigh 协调 Luna/high 实施，不提交推送。

## 目标与方向

开发者用仓颉声明一次组件及其状态样式，按钮、输入框、列表项和可交互图形都能在悬停、按下、键盘焦点、禁用、选中时正确反馈；切换主题仍保持相同内容、焦点、选择、几何与外部操作。应用不必为每个按钮自己重写鼠标状态机，也不必在 native 添加业务颜色分支。交付通用框架能力，不只是给样例换颜色。

六主线取舍：组件/交互/样式是本轮重点，GPU和资源沿刚接受的缓冲区复用与局部更新路径；文字/系统输入保持既有唯一图与组合态，语义动作保持单一owner和授权；正常消费者/导出验证可复用性。本轮不继续扩矢量种类、完整CSS/选择器级联、动画系统、跨平台后端或输入法引擎。480图形当前stage_submit p50=1.611ms不等于框架整体输入延迟，后续仍按实际热点推进。

## 已有资产与承接

复用 [设计意图导航](DESIGN_INTENT_INDEX.md)、[组件身份与命令](2026-09-13-interaction-identity-commands-milestone.md)、[连续指针](2026-09-14-pointer-interaction-milestone.md)、[GPU提交效率](2026-09-14-vector-submission-efficiency-milestone.md) 和 [避坑](../research/gui-framework-pitfalls-intelligence.md) 的身份、捕获/焦点、单一布局和无变化不重绘。源码起点为 `composable_ui.cj` 的 Style/Theme/Identity/Node、`composable_ui_window.cj` 的 accepted scene/输入/局部刷新，以及 native 的实际命中、系统输入代理、pointer capture与GPU painter。已有 beaconDark/paperLight 可以扩展，不再创建另一份主题系统。

前阶段按受控与桌面自动化范围接受：480组30样本重算1.611/2.029ms，热态paint0几何上传；tp8mzk与桌面w0mBBB两份导出各七项关键源码与当前一致。桌面manifest报告同A输入v1→外写v2→输入v3，指导未亲自重做桌面操作。旧基线逐样本文件曾被覆盖，仅保留指导先前实际读到的分位数，不再引用旧路径作可复核基线。本阶段使用独立run目录保留原始结果，重跑不能覆盖作为对照的文件；缺失历史不要求重新制造。物理输入、IME/VoiceOver、GPU完成/呈现测量和发布边界继续保留。

## 实施范围

1. **声明式状态样式。** 提供兼容现有 Style/Theme 的小型公开表达，覆盖normal/hover/pressed/focus/disabled及owner声明的selected/checked。状态可组合，明确优先级和字段继承；没有新声明时兼容旧外观。首轮优先颜色、边框、焦点提示等不影响几何的paint属性；不支持的状态几何变化须明确拒绝/说明，不能让hover引起布局反复抖动。主题由应用选择，可对单组件覆盖；至少两种完整主题在两个正常应用消费，不暴露native对象。
2. **可靠交互语义。** 在现有真实命中和稳定identity上处理enter/leave、按下/移出/释放、键盘focus/激活、disabled/移除/换绑、层覆盖及失焦/关闭取消。按钮按下有反馈，正常按键或鼠标操作最终只能调用一次真实动作；移出释放/取消不误激活。若调整现有鼠标按下立即执行的行为，明确兼容策略并更新正常消费者和相关测试，不能让private test helper决定生产语义。AX的语义激活仍直接进入同一动作，不要求伪造一串物理鼠标事件。滑块/分隔条沿原capture流程，文本框沿系统输入代理，不另造输入runtime。
3. **视觉状态的唯一归属与局部更新。** hover/pressed/focus属于框架交互投影，selected/checked/disabled的数据依据仍是原owner；主题/样式声明归仓颉，native只适配事件和绘制。Terra明确最小状态负责模块与代际边界，不能在native和仓颉各造一个可独立写的状态机。纯hover/焦点paint变化不修改业务版本/CAS，不重新布局/构建整窗、不重传未变的几何/图片/文字。按实际状态转变合并事件，同一控件内mousemove不每像素触发刷新；最终release/cancel保留。不为实现样式重新启用常驻60Hz/120Hz循环。
4. **共同操作与正常应用。** 规则/自适应等至少两个已有应用采用公开状态样式；交互图形同样使用，不在样例写私有hit/颜色逻辑。外部授权更新选中/可用状态时，正在hover/pressed/focused的对象按其新有效状态反馈；对象删除、身份换绑或层开启后旧释放事件不得误写替代对象。完成“窗口操作同A→外部读A/修改A→窗口反馈→再操作A”与主题切换中的接续；内容与权限不因主题变化重置。文本选区/组合态/焦点不能因换色重建代理或被清空。
5. **真实导出与说明。** 正式exporter产出新公共能力、两种主题和所需资源，独立含空格目录构建正常消费者。README说明状态组合、主题覆盖、输入触发时机、disabled与语义动作边界及experimental级别。公共manifest必须根据真正执行结果写状态；纯脚本/直接命令、受控事件、桌面自动化分开，不能再把B计数当A接续。

## 验收与成本

- 普通窗口中鼠标进入/按下/移出/释放、键盘Tab/激活、disabled、layer、删除/重排后身份、失焦/关闭均有区分成功与取消的断言；实际画面颜色/焦点指示对应同一状态，而非仅日志说hover=true。至少一轮正常bundle桌面操作；锁屏只跳过这部分，先做同入口受控验证，保留明确未验项。
- 用小/中/接近已支持节点规模的交互场景，各30次跨对象状态变化记录实际build/layout/submit、几何上传/文字准备和真实单调时钟阶段耗时。重复同状态无新工作、跨状态只更新相关paint，owner版本不变；切主题时必要批量重绘只发生一次，之后idle归零。已有480矢量热态缓存和普通1x路径做针对性回归，发现实际回退再扩大检查，不重跑所有旧矩阵。
- 先定位刷新和命中成本再选择缓存，不以缓存条数充当端到端效果。短时间pointer burst与另一窗口输入/外部操作同轮推进，验证公平性、最终状态与取消不丢。主题或paint变化不失效无关buffer，失败候选保持旧状态/画面可操作，结束后资源和临时窗口回收。
- 按AGENTS运行相关runtime/native/消费者测试、实际runtime build及声明/FFI影响检查；同target串行。最终源码完成后保留一次正式导出与各入口证据，记录实际source/bundle身份；不要边交付边覆盖基线或将自述manifest当全部运行原始证据。

## 分工与交付

Terra定状态/事件/paint事务和生命周期方案，亲自处理跨层结构问题；接口明确后Luna/high负责完整状态样式值层/主题、正常消费者、回归与导出文档包，必要内部实现按明确方案交Luna。需要的exporter/脚本/公共说明改动均在阶段范围，父子直接协调helper签名、写集和构建时段，不逐条转指导。无独立工作时完成当前包并final，后续用同一代理followup接续。

完整阶段交付后主动汇总给指导 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`：真实能力、原始证据、未验边界和下一主线建议，不按单控件停工。三次有效修复失败或不明生命周期按AGENTS升级，禁K3。原目录、保护并行修改和用户实例，不stage/commit/push、不切分支或建worktree；自有实例整轮复用，结束统一退出。

## 指导复核与本阶段续交（2026-09-14）

指导只读复核源码与原始结果，没有运行开发测试。接受状态样式值层、基础 hover/press/cancel 和局部 paint 的已验成果，**尚不接受完整阶段完成**。`/private/tmp/cjgui-interaction-style-native/result` 有像素与取消/释放一次的断言；其中 `physical_*` 是受控 helper 标签，不是物理人工输入。`/private/tmp/cjgui-interaction-style-scale/result` 的 8/128/960 各30条样本经指导重算，pump p50/p95 为8.2585/8.475、8.035/8.184、6.659/6.848ms，全部 build/layout/measurement=0、submit=1、node_update=2。当前窗口代码仍遍历 accepted scene 合成/比较样式，因此“两节点更新”不能解释成整条刷新路径恒定成本。ARtrO5 正式导出的 composable_ui/window/native m/h 四项与工作区逐字节一致；这证明源码消费一致，不补充尚未执行的动态交错验收。

### 先纠正退出106的诊断

`composable_ui_window_controller_probe.cj` 的 same-scene participant 异常断言返回155/156；**106实际位于其后的 layerWindow.declareCommand 检查**。LayerInputController 初始 layerMode 为空，9012及其scope只在菜单打开后产生；现在窗口打开后 declareCommand 会调用 commandsValidForAcceptedScene，拒绝尚不存在的目标。源码强烈指向测试所用预注册时序与现契约不一致，不能因最后一条日志名把失败归给 participant，也不应放宽生产目标校验来凑绿。

Terra先把106的两个布尔分支分开记录，确认是初次注册拒绝还是冲突注册误接受。以当前公共契约为准，优先让该动态控制器复用已有 SceneRefreshParticipant 的 candidateSceneCommands 随菜单挂载/销毁原子发布；若本用例只需测试 accepted-scene 的增量声明，可在菜单实际接受后注册并在目标销毁时撤销。选择与该测试意图一致的一条，保留同scope冲突拒绝、关闭后不可调用、重开只执行一次、旧快捷键/AX拒绝。现有动态组件和事务能力已经实现，不重建身份注册表、第二绑定系统或新回滚机制。若发现兼容性约定要求预声明，先给出既有文档/消费者依据及安全方案，不能静默改公共语义。

### 整体交付，不能修106就停

继续完成上方原定范围的动态组合与共同操作，必要框架修复、两个正常消费者接入、相关验证和最终公开消费一并交付。复用 [动态组件](2026-09-14-dynamic-component-composition-milestone.md)、[刷新事务](2026-09-13-component-refresh-transaction-milestone.md) 和当前样式路径；这是让新交互能力适用于已有动态组件，不重新宣布已有组件身份是新能力。

1. **输入存续边界。** 在真实生产 down/up/cancel 路径验证按住A后同A被外部禁用、删除再建、同原始字段换绑、改action、打开/关闭模态或切换窗口的结果。当前 native pressed 与仓颉 sameInteractionIdentity 主要比较 nodeId/resourceId/kind，是否充分须以现有身份代际与真实反例判定。旧按下不能释放到新动作；无关B变化或纯paint提交不应无端取消仍合法的A。框架状态、平台路由与 accepted candidate 的提交/失败边界保持一致；不能简单用每次scene version变化取消一切交互。复用已有scope、身份与事务，补最小必要代码。
2. **真实共同操作与主题接续。** 用两个已有正常消费者消费完整状态样式；至少一个当前正常bundle完成同A窗口输入→公开外写A→可见反馈→再输入A及读回。包括外部改变enabled/selected/checked中的实际适用状态，鼠标/键盘/AX仍进入同一owner。用真实存在的权限入口，不能给样例添加绕过owner的测试后门。纯主题换色保持正文、选区、焦点及滚动；字体改变单独记录需要的测量，不拿“换主题同时换字体”的观察证明纯paint无布局。组合输入可使用已有系统集成受控入口检查不被换色破坏，仍不冒称系统候选窗验收。
3. **完整状态与失败恢复。** 补现有证据未覆盖的重复同状态无工作、聚焦/禁用/选中组合优先级、主题完成后idle归零、pointer burst与另一窗口输入/公开调用公平推进、失败paint候选保留已接受画面与可用动作。先核对已有证据，已有针对性覆盖不重跑；新增代码影响的缓存/渲染只做相关回归，验证未变文字/图片/矢量buffer不因hover或换色无谓重建。以生产路径断言结果，不只在值层设置一个状态位。
4. **收尾。** Controller probe须按实际失败点闭合，不能用最后日志定位或跳过后续断言。当前源码完成后一次正式导出含空格路径，独立消费者实际使用本轮能力；保留原始run日志、源码/二进制标识、读回与可用截图，旧结果不覆盖。只有新增变更/失败或明确疑点触发重验；前面90条性能样本继续作为已验记录，受影响才重跑。锁屏跳过桌面部分并推进其余，结束统一回收本轮自有实例。

Terra/xhigh负责契约与跨层诊断，默认一个Luna/high接完整的消费者/针对性验证或已明确方案的实现包，直接向实际父代理报告，不向指导发送例行等待。构建串行；执行反馈以完整交付或实质阻塞为单位。K3取消与跨模型3次有效失败升级不变。完成后再由指导选择下一大阶段，不在此轮额外扩展新的组件体系。


### 续交后的指导结论

接受受控范围的新press-boundary矩阵与theme continuity（原始 `/private/tmp/cjgui-interaction-style-native/result`、`/private/tmp/cjgui-interaction-style-theme-continuity.log`），并确认mMBxly最终导出的ui/window/host/session/native m/h六项与当前一致。执行报告controller106已通过，实际修复采用既有participant候选命令，未放宽accepted目标检查。最新正常窗口公开CREATE_RECORD读回不是同A窗口接续，锁屏欠项继续保留；drag-only交错不代替hover/press高频公平性。剩余终结事件跨轮/交互paint、实际状态外写、正常桌面接续与局部刷新成本在[交互调度阶段](2026-09-14-interaction-scheduling-efficiency-milestone.md)继续完成，不宣布本阶段所有场景已通过。指导未重跑开发测试。
