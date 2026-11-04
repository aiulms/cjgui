# Mac 普通应用键盘与公开交互接入整包

2026-11-01正式下发。同一主执行 `01a18297-1b22-7f63-ad2d-e49f066db253` 统筹，实际复用 `gpt-6.1-terra` 和 `gpt-6-luna`，档位按难度；完成直接回指导 `01a17207-04bc-76a2-90c3-99c8c5060423`。用户已授权指导持续安排Mac整包，不等W/H，不要求用户再转提示词，不另建线程/监控或调用顾问。

## 目标与基线

依据[设计意图](DESIGN_INTENT_INDEX.md#shared-code-entrypoints)、[首版范围](2026-09-26-framework-capability-roadmap.md#first-mature-version)与[共同操作验收](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)，把已交付的虚拟集合定位能力接成普通开发者可使用的键盘与外部交互入口：人在集合里导航到目标、进入字段、应用/取消；外部客户端能按应用明确授予的权限读取同一窗口/视口状态并接续操作，运行中更新后仍对准正确owner。

复用[上一包已接受范围](2026-11-01-macos-collection-viewport-navigation-package.md#guidance-review-20261101)：SDK630/607、content `6a65a8dc…`、锁 `e30f4231…`；共同Core c895/Window804b/generated511b/prepared cef3；Rules979e和包外Mixed bcae的正常短链。旧SDK741e不原位改，Source/Visual、旧输入/保存/退出、集合完整1000条和已验证反例按身份复用。本包不改写上包未验项，也不为新阶段再跑一遍滚轮→V→X整链。

已知缺口是接入与消费范围，不能预判成共同输入缺陷：Mixed本轮仅声明GET_CONTEXT/生成式及业务权限，WINDOW_PROGRESS/INTERACTION被正确拒绝；编辑使用公开业务调用，尚无本次集合动态变化后的原生键盘连续操作证据。其独立消费源/构建配方目前位于阶段私有目录，也要核普通开发者是否能通过已有SDK入口复用，不把本地归档身份等同于可直接接入。

## 已有机制与应完成的工作

1. **接通显式只读窗口观察，保留权限边界。** 复用 `shared_operation_core/client.py::get_window_progress/get_window_interaction`、transport现有授权/目标校验、Window已接受投影与绑定viewport。先核现有public provider/注册入口，能配置就配置；仅在多消费者确有共同接入缺口时补窄的公共helper，不能为了本包强造协议或状态机。正常示例明确声明要开放的只读窗口观察动作；保原未授权票据/范围的拒绝反例，不改transport默认权限，不放宽其他owner或写操作。opaque window target、业务owner、generated mount和semantic key保持不同身份，不把unknown_resource/unknown_owner改成默认窗口成功。
2. **完成键盘在虚拟集合与字段间的连续使用。** 复用 `composable_ui_generated_collection_keyboard.cj::cjguiNavigateGeneratedCollection` 的accepted-mount重载、现有CollectionSelection、scope focus及reveal。已有上下/Home/End/Page/Shift语义不另写；应用只接普通选择/业务动作。核实际事件命中与接受场景：集合导航不进入文本替换，字段内箭头不泄漏成另一owner选择；一次原始键只能由正确路径消费。滚出当前项、重排/过滤或挂载更新后按stable key/viewport代次继续；旧mount、错viewport、退休目标与晚到事件不得污染新对象。发生真实缺陷时保可区分RED再最小修复；已有路径正确就复用，不为交付量改代码。
3. **公开操作后人能直接接续。** 同一正常窗口中让外部读取实际获授的窗口/视口状态、显示已声明的目标，并通过原业务入口改变一项实际状态；随后人通过真实键盘继续编辑、Apply/Cancel。完整owner正文、草稿/字段版本及焦点目标须相互对应；无关owner草稿保持。只等待真实accepted/就绪条件，不靠补点击、延时或重发获得首键。显示请求、accepted scene和实际画面仍分层表述，不另造完成回执真相。
4. **交付普通接入入口。** 使用已有建项/SDK构建/公开客户端流程，给同一公共能力的最小可运行用法、必要授权声明、身份/读取/失败语义。尽量复用现有公共示例和Mixed完整消费者，不复制解释器、renderer、业务镜像或按本轮另造一套脚本。若现有包外Mixed只能从旧会话私有路径编译，修其可搬移源码/依赖配方或接回现有公开消费者入口；不能只写“可迁移”。Common API仍experimental；没有共同/SDK载荷变化就复用6a65，不为换阶段导包，有变化则汇合后只导一次必要新候选。

本阶段推进的是正常输入与公共接入的可用性，不扩高级控件库、完整设计器、额外平台或权限体系。通用机制不明时按设计导航局部查GPUI/Slint等只读参考与现有测试；不增加第三方框架依赖。app授权配置问题由app修，共同状态/焦点缺陷归共同模块，平台实际输入/资源问题才进窄桥。

## 分工、反例与一次汇合验收

Terra领键盘/accepted mount/焦点/身份及必要共同修复完整块，Luna领显式窗口观察、消费者接线与普通接入交付完整块。主执行先划写集、串行target和桌面，负责整合与最终正常链；复用已有子代理，子代理只回主执行，不逐函数派工或把未知根因反复丢给另一模型。

先用现有单测/接缝定位真正新增的风险：缺权和错target拒绝、当前mount/同几何兄弟mount/旧代次、导航与文本输入路由、key排序/过滤变化。测试要对行为有区分力，原测试已覆盖且条件未变就复用。源码检查或fixture不能冒充真实键盘；反过来，工具初焦/坐标错误也不能判共同缺陷。

汇合后安排一条预先明确目标的正常Mixed链（现有30卡，DEFAULT_OFF）：

- 通过显式授予的公开窗口观察读回相应视口与accepted状态，受限/错目标拒绝另按直接契约证明。
- 人从真实集合入口以正常键盘跨出当前物化范围，选择准确stable key/owner；进入字段一次输入，完整读回。只覆盖会改变风险判断的导航组合，不枚举所有键。
- 保另一owner脏草稿，做一次现有sort/filter或生成mount更新，外部按真实目标显示/读取；人继续键盘编辑和Apply/Cancel。核正文、版本、选择和焦点，不用公开业务写替代本轮原生键入。
- 按应用现有持久化能力保存/处理关闭守卫并正常退出。Mixed没有业务文件就如实说明，不凭空增加文档系统；可用UI文档流程复用。保实际输入、公开读回、少量关键窗口原件和端点退出。

Rules仍用原1000条负载，仅补本次共同改动真正影响的键盘/观察短链；若只有Mixed权限与接入配方改变，则复用Rules979e既有证据，不启动Rules。第二消费者和包外编译合并安排，不能为每个小改动重跑全套。采用已有正常runner，在启动前完成准备；两次同工具失败先调整方法，不重复创建同义实例。正常工具等待和最终归档不能吞掉整轮交互时间。

有源码/脚本变化，按AGENTS完成相应构建、针对性检查、声明/禁止行为扫描与diff --check；只检相关范围。已有性能B/C/D、四类80事件、16/32ms、VoiceOver、旧Source/Visual和平台矩阵不重开。新出现的实际卡死、输入丢失或无界资源增长必须处理，但不能把一般指标采集重新扩成无终点前置。

## 资源、交付和接续

沿[容量规则](../../AGENTS.md#artifact-space-budget)。本包核准新增**最多128MiB留存额度**用于必要新候选/归档/窗口原件，避免为几十KiB反复压缩旧原件；E最终上限从15.25到**15.375GiB**，DS子范围从2.75到**2.875GiB**，旧累计不清零。E峰16.5GiB、DS峰3.25GiB、原五部临时3GiB及宿主峰后20GiB底线不变，不再追加10GiB。当前E约15.204GiB、DS2.697GiB，宿主约181.63GiB；开工及高写盘前重查实际值。

正常图已退役，按现存源/构建入口恢复一个必要的可复用图；不再复制阶段整树。预算含编译、两个消费者、压缩同时峰，串行复用。最终只保当前候选、必要回退与唯一RED/正常原件，按准确路径/PID/lsof清理自有可再生产物并保finally。旧32e/741e/6a65来源和仍在用交付不猜删，任何退役先查用途和可复盘原件。

开工顺手核清并清理6a65 SDK内两份本线Python运行缓存：`framework/cjgui/shared_operation_core/__pycache__/client.cpython-314.pyc`、`cjgui_generated_client.cpython-314.pyc`；不要动630项载荷。以后客户端用既有运行入口禁写bytecode或把可再生缓存放自有工作目录，不因缓存清理重新导SDK，也不单独停工回报。

最终集中交付实际能力/修复、公共接入用法、精确源/构建/运行身份、适用测试及正常原件、尚未覆盖范围、实际留存/释放/宿主余量。更新本阶段结果后直接回指导。普通修复、接线和编译自行持续解决；只有架构/重大安全或资源风险、写集冲突、重复低收益才集中升级。无Git写/顾问/新线程/监控，不修改W/H/Linux冻结包或关闭他方实例。

<a id="guidance-reveal-continuation-20261101"></a>
## 718f候选后的集中修复裁决

仍在本包内持续完成，不另开阶段。指导已核当前generated `511b5645…`、Window `d50bc27a…`、keyboard `32e256c9…` 的相关源差分，以及兄弟mount精确焦点、tooltip/交互popup的定向RED/GREEN原始结果。本次Rules `4e78a992…`、PID99980的正常退出、选中1000及完整保存原件不能证明末项显露：`consumers/rules-generated-keyboard-window-continuation-close-batch/validation.json`记录requested30348/accepted30264/content31092/viewport240，实际`observations/navigation-live/after-End.jpg`和AX仅见993、994及部分995。当前SDK718f/632载荷/609输入、锁0d53665e范围下仍是PARTIAL。新Window下Mixed输入j后、Cancel前的完整owner读回缺口也保留，不能借旧Window804b/c2的原件补齐。

1. **允许立即恢复生产修复。** 先把候选复制的假设变为一个有区分力的生产路径反例：公开holder/mount事务、`candidateCopy`、真实变高源、接受/回滚均走原实现，目标key在晚测量后应仍进入本mount可见区域；不要只手调list state代替候选链。源码已确认复制创建新viewport、复制state却保留旧viewport身份。优先在复制的state上先`adoptSharedViewportRequest(原viewport)`，消费确实较新的滚动请求，再`completeRevealViewportRequest(复制viewport)`迁移身份，使相同语义reveal不被复制身份变化当成新滚动。实际反例支持后最小修改；不共享/修改accepted对象，不复制原生句柄，不把所有代次都忽略。若反例否定假设，按新证据修正方案，不硬套这两行。
2. **只补这一边界必要反例。** 区分reveal后没有新滚动、真正较新的滚动应胜出、候选回滚不污染accepted视图；退休/重绑和晚请求按现有适用测试复用，有实际覆盖空白才补。检查接受后的普通刷新不再次丢key。不要为该局部改动重跑已绿tooltip、整套输入/性能或平台矩阵。Terra领共同修复，主执行归因/集成；Luna完成独立交付和正常消费块。
3. **汇合后一次替换当前SDK，补受影响正常链。** 保现有三次导出的历史身份，最终源码汇合后再作一次必要导出，不能改称此前只导过一次。Rules仍1000条、DEFAULT_OFF，沿现有原始输入配方一次End，保所选owner完整正文/版本、真实末项目标位于clip内的AX与截图、保存和正常退出；不追加滚动、重按End或额外reveal救绿。Mixed沿既有30卡短链，保另一owner草稿、外部操作后的原生续写；输入j后Cancel前立即按原公开入口完整读取owner各字段/版本，并保同运行画面，随后Cancel/草稿保持/正常退出。旧证据按具体源和作用范围复用，不把旧EXE写成新SDK同源通过。导出/普通构建与所需检查合并串行，不逐补丁启动消费者。
4. **先把验收顺序准备齐再启动。** 预先固定输入、公共读回检查点、画面、保存/关闭及finally；长分析/打包放退出后。可以在现有主执行下，用短任务上下文替换已超长的原生验收子代理，先结束旧执行，保持6.1Terra/6Luna实际分工，不创建用户线程或第二个前台执行者。原PID退出后只读manager结果、进程和端点，不再用可能重新启动应用的取态入口确认关闭。原超时、容量监督125、自动另开空实例等各按实际身份保留，不能改记正常成功。

容量一并处理：指导实查宿主可用186,380,726,272B；主线报告五部2,996,101,120B、可退役图170,188,800B，后两项仍由主线完成实际收尾核算。为覆盖本次新反例、源码和最终双消费者必要原件，避免归档末尾再为小额空间停工，**在本包原128MiB之外再核准最多64MiB留存**，E上限改为**15.4375GiB**，DS子范围**2.9375GiB**；E峰16.5、DS峰3.25、五部临时3GiB、宿主峰后20GiB均不变，旧累计和核算边界不清零。这是本包必要收尾额度，不是新实验额度，不要求用满。先保真归档再按准确归属退役旧图/可再生产物，复用一个构建目录，保护唯一RED与在用交付；高写盘前重核峰值。

上述是一次完整接续授权，不需逐步回问。根因明确的普通修复持续完成；若仍发生重大风险或低收益反复，带具体新证据集中升级。最终重写RESULT中的当前身份和结论，旧c395/f697/c2/718f分别置于历史范围，不留下多个互相冲突的“当前SDK”。完成源差分、必要回归、正常原件和资源收尾后直接回本指导，不要求同义收口确认。

<a id="guidance-keyboard-accepted-20261101"></a>
## 最终交付指导复核与接续

本包按声明范围接受，当前功能候选为ad7935/632载荷/609输入，raw锁65ef736d。指导独立重算全部载荷长度/SHA及609个根输入，零漂移；检查最终generated a81相对511b仅在复制state上接纳原viewport的新请求并迁移复制身份，不改变accepted原对象。实际holder测试经过候选构建、接受后settle与再次refresh、新请求及discard；三份最终原始日志各1项通过，测试728c与对应锁及当前根一致。原几何RED与夹具缺settle的方法失败分开。此前已核keyboard32e精确节点、Windowd50非交互层返焦边界，复用其原范围，不重跑。

指导逐成员核Mixed归档55项、Rules归档113项的文件字节/模式/链接与完整归档SHA，均一致；签名EXE分别9aadc57d/c78a6308，匹配实际manager。两份归档内normal provenance均testing=false/verified=true，实际源与prepared输入中的三个共同文件均为32e/d50/a81；签名前后EXE身份不同，未冒充同一哈希。两个normal原日志SHA匹配、自然exit0、无超时/forced；Rules有close_permitted及destroy，Mixed有destroy，不将Rules的关闭标记借给Mixed。

实际收益已由原件补齐：Rules原图/fullAX的末行完整在clip内，对应owner1000及公开五字段；直接比较原1000条文件与60765B保存文件，仅SELECTED1变1000，SHA487a840b。Mixed同PID61069的原图显示card30、资料30kj及copies5；原始stdout与解析响应相等，独立核Apply后、j后、Cancel后和A保稿的完整三字段/owner/state/draft/applied/field/validation版本。j时draft3/applied1，Cancel后draft4/applied4、正文恢复；A仍Pending A、draft1/applied0，没有用全局state推进冒充A草稿变化。旧718f可见性/瞬态缺口不改绿。

最终Mixed113.168秒低于旧360/600编排期限；900秒安全监督不是产品性能门变化，原超时和方法失败继续保留。当前ASCII链使用ABC，不能据此宣称IME全覆盖、实体HID或输入到呈现延迟认证。最终资源账沿原累计：五部2,907,168,768B，E16,571,105,280B、DS3,142,041,600B在既定上限内；归档与退役记录保留，gross退役不当卷净回收。指导只读宿主约174.32GiB；未重建、启动窗口或执行生产修改。

无需再回同义收口确认。按用户持续推进首版的授权，直接接续[系统文本编辑与共享命令整包](2026-11-01-macos-system-text-editing-package.md)。选择依据是首版正常系统编辑与人/外部接续的可复用能力；不再围绕这次End/j重复验收，也不恢复已停止的B/C/D性能采样和没有新条件的VO尝试。Source/Visual及已回接的W T11c共同恢复逻辑按现有身份复用，本包接受不等于整个Mac成熟度或其他平台通过。
