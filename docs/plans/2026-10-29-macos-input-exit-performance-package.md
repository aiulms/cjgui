# Mac 连续输入、最终退出与运行成本整包

2026-10-29，用户再次明确要求直接继续安排 Mac 剩余缺口，并要求实际使用 6.1 Terra 与 6 Luna，思考档位按需调整。主执行仍为 `01a18297-1b22-7f63-ad2d-e49f066db253`，完成/实质升级直接回指导 `01a17207-04bc-76a2-90c3-99c8c5060423`。本文件就是实施任务，不另开执行卡、用户线程或监控；不恢复旧 Sol/DS，不等待 H/W。

## 目标与已有资产

以普通应用的连续可用性和可说明的实际运行成本推进首版。当前组件、运行时组合、公共历史/客户端、会话恢复均已有实现，本包直接复用，不新增控件库或再造工作会话。实际交付应是：原键与末键不会在焦点/动态界面/业务动作间丢失，系统输入和可访问操作有明确支持范围，多窗口最终关闭不会越过新工作，普通负载没有未解释的阻塞或持续资源增长。

先读 AGENTS、ACTIVE E当前段、本任务；规划/机制疑难按 [设计导航](DESIGN_INTENT_INDEX.md)、[项目方向](../core/GUI_PROJECT_DIRECTION.md)、[首版边界](2026-09-26-framework-capability-roadmap.md#first-mature-next-20261028) 及直接相关源码。共同基线是 [efee91ba](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/sdk-efee91ba/README.md)，622文件/599输入；保冻结包只读，根树先核并行差分。复用 [本轮已接受原件和边界](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/RESULT.md#guidance-efee-accepted-20261029)：双owner恢复、AX角色、Rules版本查询及联合关闭已验范围无需重跑。Windows继续17ee，H消费自己的冻结源。

## 实际使用两个子代理，保持一个集成负责人

必须实际调用/复用 `gpt-6.1-terra` 与 `gpt-6-luna` 原生子代理，不能只在报告中列模型名。Terra承担输入/退出/提交归属的复杂归因、方案和获分配的实现；Luna承担方案明确的消费者、针对性反例、正常消费及收尾完整子包。思考档位按难度选择，复杂问题可 high/xhigh，明确工作用 medium/high；及时随证据调整。主执行统筹根因、跨层修改与最终集成，不把同一未知问题反复换模型猜改。

复用已有子代理和目录，明确写集；同一native文件、cjpm target及前台只有一个当前操作者。子代理只回父执行者，不另建用户线程/定时，不直接给指导刷常规消息；二者是本包实现团队，不是额外外部顾问。普通编译/工具/接线问题自主处理，不逐项等待指导。

## 一、连续输入及系统可用性

复用 `composable_ui_window.cj`、文字会话/generated range session、native TextKit代理与 `CjguiEnqueueComposableInteraction`、accepted绑定/owner路径。原“7→Increment”确有可见空值，之后“4”成功不能替它结案；旧 KEY_ENTRY 只覆盖overlay，不能再用它的缺行断言TextKit没收到原键。

先建立一个能区分问题的当前生产反例，沿原键接收、实际TextKit回调、排队/合并、Cangjie分派、完整owner正文/版本逐段定位；已有队列的版本、node/owner与生产调用身份应复用。最小补观察只为定位这一原键及紧接的按钮/焦点动作，不能另造输入管线、重发、补点、延时或AX写值。旧原件缺失的历史因果仍标未知；当前同类缺陷可以用新的精确生产反例修复，不为了复刻旧PID无限重启。

形成连续操作能力：普通整值/多行及已支持owned编辑，末键紧接Apply/Cancel或关闭、模层返回原文字首键、公开合法外改/运行中结构改版后接续；保FIFO、源版本、绑定退休、owned校准/选区拒绝与独立owner。只补受修改影响的场景，按同一正常会话汇合。

系统IME和VO分清系统/工具通道与框架缺陷。先查当前工具文档、已装SDK/系统接口及导航中的本地参考；不能复用失败方法再次碰运气。IME的TIS源ID并非组合态证据，要区分实际输入模式、按键/Unicode文本投递、原生接收/markedText/commit；旧42e适用成果复用。VO需可识别的光标/读出或实际VO动作，普通键盘焦点、引擎进程、Quick Nav开关不替代。只在明确改变投递或观测方法后做一次能区分的系统应用正控，再消费CJGUI；若仍无有效通道，带精确事实升级该依赖，其他源码/退出/性能工作继续。不要把正控失败直接归为框架或系统错误，不擅增安全权限或改锁屏。恢复输入源、VO与临时系统设置。

## 二、从关闭决定到实际退出，以及资源回收

复用现有Mac host、退出provider、UI-document guard和WorkSession。efee已解决guard层许可生命周期，本次重点是此前未验的host批准→延后关闭之间：批准后或多窗口逐个询问期间，原输入、公共写入、UI改版或新窗口出现，最终退出是否仍能识别新工作。先读真实调用顺序并做可区分反例；已有机制确已保护便验明，不凭“存在异步”先造缺陷。

存在缺口时在实际归属做最小修复：复用既有版本/关闭意图、准入与完成机制，关闭必须覆盖真正待处理工作；取消、拒绝、保存失败及新工作不能沿用旧许可。不能提前清队列、冻结所有交互、关端点吞掉合法操作或把未保存内容隐式Apply。补一条真正双窗正常链，覆盖脏主窗/干净companion、最小化参与窗口、取消后继续输入、正常保存关闭；多窗适配器单测不冒充真实桌面消费。业务/UI仍为各自单文件原子保存，不扩成跨文件事务或新数据库。

同一正常应用中做预先界定的资源循环：打开/关闭自有窗口、更新/移除生成区域、文字/图片/效果替换与滚动；复用当前缓存、drawable lease和in-flight回收责任。区分活跃租约、允许驻留缓存与单调残留，排空到有意义稳定点再比较，RSS/进程退出不单独证明有界。建议10个固定工作周期、一个初态和一个终态复核，先写清目的与上限；若已有精确同源数据足够就复用。有增长则沿真实持有者修复，修后只回归该循环，不建数小时soak或无限循环器。

## 三、实际输入→owner→呈现与普通负载成本

沿既有native收件/owner时钟、场景/帧/lease身份、`addPresentedHandler`及公开反馈定位。先用一条正常输入证明因果映射，再采最终矩阵；映射不成立就不要重跑80事件。复用前阶段presented-time机制说明：e1某帧转换时间为0但同进程后帧有效，不能称环境全部不支持，也不能先认定丢帧或生命周期错误。必要时仅补足原始presentedTime、回调参数/lease身份和转换结果的区分信息；callback到达/GPU完成不是实际呈现。

测量保持原固定1000条Rules、同布局和四类动作各20事件的最终口径：暖输入/选择从框架原生接收至owner实际应用p95≤16ms，至对应drawable真实呈现p95≤32ms。原生接收点与硬件投递前时间分开标明；保setup、无变化、合并/拒绝、未关联/未呈现和慢样本，不删除不利结果。诊断ON与默认OFF分开；复用最小现有观测或平台采样，不把追加追踪的运行冒充默认OFF，不将测量工作挪出时间窗。无法可靠关联的部分仍未知，不能靠放宽门槛或缩小负载变绿。

以能改变实现的证据定位主导owner/build/layout/准备、跨线程等待、绘制或资源成本，修阻塞、重复工作和无界增长。版本getter已修，不重复优化同一处；少做节点/回调不直接等于端到端改善。通用归属疑难先查GPUI/Slint/Flutter等导航相关源码与测试，仅借鉴算法和生命周期，不引入它们的运行时。观测改动必须有界并解释自身成本，不发展成独立遥测平台。

## 合并验收、持续推进、交付

以mixed承接输入、运行中改版/公共操作、双窗保存关闭；Rules承接固定普通负载及受影响接缝。同源修改稳定后统一做必要回归和正常消费，不逐补丁换SDK/重编所有样例。适用旧证据连同身份引用；新增真实系统输入或外部操作明确实际通道，受控接口不得冒充HID或真实模型消费。

持续完成上述可执行实现和验收再集中回报。一个正控受阻只阻塞其对应结果，不把整包改为“已盘点、待下一步”；不要做完一个小修复或一个子代理子包就停工。必要独立项都推进后，若仍有具体外部依赖，集中给事实、剩余影响和可执行取舍。反复工作无收益时改变方法/范围并升级问题，不靠无限新增检查维持忙碌，也不无证据改生产代码凑数量。

最终交一份继任功能候选、正常App/包外消费入口及可复盘原件，保efee为当前可用基线，指导复核后接替；Windows17ee不追更。写清每个实际修复/能力、同源输入与运行身份、拒绝/失败保护、实际成本和仍未验项；首版目标没有实际满足不能标成熟。报告直接发本指导，不让用户搬运或提醒；指导收到后继续决定本目标内下一步，不以局部验收作为整体停工理由。

## 写集与资源

共同根核心、Mac native/host、公共契约/客户端、模板/消费者与SDK由本主执行统筹。H/W/Linux目录、冻结SDK、旧线及用户/不明实例不写不关，保护ds55。前台和共享target串行，准备/归档放窗口外；不因无窗口推断他方释放，按当前事实协调，其他后台工作继续。

沿[容量](../../AGENTS.md#artifact-space-budget)及[验证价值](../../AGENTS.md#verification-value)。原累计账不清零：上包E上界13.674GiB、DS993.43MiB、临时1036MiB。本包为必要原键/关闭RED、正常App和有界资源原件，将E累计留存上限调至14.25GiB、峰15.5GiB；DS子范围留存1.25GiB、峰仍2GiB；临时构建1.5GiB。重叠边界不相加、子代理不各加10GiB。开工核实际占用，复用一个工作目录和既有驱动，高写盘前核峰值，宿主峰后至少20GiB；指导最近只读约203.6GiB。日志普通单文件64MiB/当轮512MiB为上限，按具体问题更小采集；若预计触及容量先落实复用/回收和采集预算。唯一RED保真，候选/必要回退和原件保留，其余自有产物在成功/失败/取消时收尾，最终报实际空间账，不猜删旧库存。

无Git stage/commit/push、切分支、stash/reset、新worktree、额外顾问或重复监控。ACTIVE仅替换E当前段≤600字，细节留本任务和现有证据根；不新增逐轮治理台账。

<a id="guidance-exit-commit-20261029"></a>
## 最终退出的跨层裁决（2026-10-29）

本包主执行已升级真实输入在退出批准后被销毁的问题。指导核过 [生产接缝原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/exit/production-pending-input-red/)、归档host/test哈希和两份运行日志：无新工作对照1项通过；A的TextKit输入进入controller并调用默认host，provider读到B空正文后，通过原TextKit入口一次加入B的`new`，真实FIFO的pending/kind28/node2断言先通过，随后双窗均关闭、B仍为空/writes0。该反例成立，渠道是受控TextKit＋生产路径/testing链接，尚非HID或最终正常App验收；无需重做RED。归档host为`c6754a9e…`、测试`d0a38b7c…`，normal archive前后`83e860aa…`不变。当前根有退出lifecycle及资源WIP，不能把归档旧源当当前修复已通过。

**裁决：允许在本包补有限的批量退出提交协议。** 共同host/window负责参与者、业务许可与可安全结算状态；Mac native负责实际输入准入和会话的最终批量提交；公共transport负责自己已排队/已claim请求的归属。复用已有机制，必要的内部FFI和可选provider生命周期接口属于本包实施范围。不是另起阶段，也不是仅把provider延后或给每个窗口加一次计数检查。

### 实现边界

1. **把退出意图、业务许可和最终提交分开。** 普通`requestApplicationExit`进入同一待处理意图，在owner正常轮次推进；不得一得到true就转用强制`close()`。先正常完成所有参与窗口已接受的输入、owner结果及ACK，再检验许可。许可仍绑定业务正文/版本、UI文档基线和参与窗口集合/代次；无变化的技术等待保留已有许可，不重复提问；新工作导致许可失效时按现有规则重新判定。显式取消/保存失败撤回意图和许可，实际提交成功才finalize一次。保持现有Bool入口的请求语义，新增生命周期优先可选接口/内部实现；没有这类接口的合法provider也必须得到安全退出，不能全退到强制路径。

2. **先纯预检，失败时一个窗口也不进入不可逆关闭。** 复用`composable_ui_window.cj`的正文/receipt/present结算，取出可观察、无破坏的最终退役判据。正常轮次可以推进原结算，但预检不得调用`close()`/`discardSession()`、先取消绑定或清队列制造ready。检查真实FIFO、已取出的Ready/正在分派输入、原始key/模层/owned capsule及组合输入、未ACK owner/present、未交接recovery和已接受公共操作；这些可复用已有状态，不能只看`owner_pump_has_unconsumed_input`。已完成源元数据与仍欠用户正文的负载要区分，不能因为任意一个metadata字段非空而永久挡住关闭。纯渲染在途租约按已有完成后回收规则保留，不要求所有缓存/异步回调先归零。

3. **一次主线程批量校验并提交，最多现有4个本应用session。** 校验明确的token/generation与参与集合、上述实际状态；覆盖通过预检后新到的输入，而非“检查一下，再逐窗调用旧destroy”。所有可预期拒绝必须在任一窗口不可逆退役之前返回，保持全体窗口和端点可继续使用。通过后先让整个已批准集合进入终态、禁止其后新的准入，再复用既有native资源拆卸；不在检查和这一状态切换间pump AppKit、调用业务/provider、等待异步或进入nested runloop。AppKit关闭可以同步重入，因此必须在第一次window close/通知之前保护整个集合，不是每销毁一个才设置该窗口的标志。有限提交点上的终态准入是正常关闭的一部分，允许；从询问起跨turn冻结输入、等待其自行清空不允许。返回后Cj按精确成功身份完成原投影/参与者释放，不重新调用带结算/拒绝副作用的旧`close()`。

4. **拆分现有销毁实现，复用清理，不复制另一套。** `cjgui_internal_renderer_destroy`当前在最终recovery拒绝前会退休pointer charge并调用`CjguiTerminateModalExitInput`；后者会移除对应原始输入，所以它不能兼作纯preflight。把真正的拒绝条件、必要正常结算与已提交后的拆卸分开；普通单窗入口也避免形成两份不同的安全判据。`discardSession`现有native成功之后的Cj退休可以提取复用。既有owned确认、校准/退休拒绝、recovery字节责任、present ACK和worker/drawable租约不能绕过。正常拒绝留在commit前；commit后不再走业务拒绝或回滚到“仍可编辑”。不可预期拆卸故障保留精确会话/资源归属与错误，不清token伪称全部退出。这是逻辑关闭的一致提交，不宣称各系统窗口像素在同一瞬间消失。

5. **外部输入与同一边界相接。** `shared_operation_transport.cj`的`tryQueueRequest`在IO锁内发布pending lease，`notifyOwnerWork`在锁外，故全局wake revision不能证明外部队列为空；Ready数也不覆盖已经claim而未完成的请求。复用原owner admission/claim、endpoint代次和pending lease，明确请求在最终提交点前后各归哪里。提交前已准入或已有受保护lease的操作须正常结算，或按既有取消/拒绝契约给真实终态，不从端点关闭中静默消失。仅收到部分网络字节不等于业务接受，也不能让慢socket无限阻塞退出。若需短暂的可撤销准入reservation，仅围住这一次最终同步尝试：busy/拒绝即释放，随后正常泵送；尝试中到达的请求保有原件并获得确定处理/拒绝，不能先报接受后丢弃。不得持transport/owner锁跨主线程dispatch、执行provider或等待响应写出；明确锁序、重入和finally解锁。不得修改授权/版本校验或另造第二套操作协议。

### 可区分验收与推进方式

主执行直接整合实施，Terra负责上述生命周期实现/审查，Luna继续明确的正常消费者/资源子包；思考档位按难度调整。只在存在新的安全矛盾时再集中升级，无需先回同义批准确认。

复用已得RED和无新工作对照；同一针对性构建补能区别新协议的少量接缝：B真实输入在provider内及提交检查前到达；任一窗口持Ready、未ACK或recovery时全体仍活，正确结算后同一意图可继续；owner/参与集合或公共写入在批准后变化会失效；销毁通知重入与提交后的迟到事件不准入新工作、无半关闭或双释放。选择实际状态覆盖关键分支，不能以布尔假状态或普通text一例代表owned/外部操作。公开请求用原transport，准入与结果原件分别保留。

之后与本包已有真实双窗链合并验收取消后续写、脏主窗/最小化companion、明确保存/丢弃、正文与UI文件读回、正常退出及端点回收；不另跑旧性能矩阵。`生成改版后8+CmdR`、系统输入和10轮资源包继续独立推进，不让最终退出的实现阻塞所有工作。原预算及efee/17ee/H/W保护不变。

指导本次还核了本地GPUI `app.rs::shutdown`、`gpui_macos/platform.rs::quit`与`window.rs::close_window`：它把应用清理和平台退出分开，明确关闭通知会同步重入，并先标记closed再回调。只借鉴这些生命周期边界；GPUI的超时退出/清空window集合不是CJGUI受保护正文、ACK和恢复负载的正确性证明，不复制其策略或引入依赖。

<a id="guidance-26d1-continuation-20261030"></a>
## 26d1复核后的连续接续（2026-10-30）

本整包继续实施，不新开阶段、线程或监控，不等H/W。26d1普通输入/保存/双窗退出及身份已限域核对，但新增退出回调和非Mac关闭分支存在源码风险，暂不升当前；efee及W17ee保留。详见[复核事实](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/RESULT.md#guidance-26d1-review-20261030)。

**先完成两个实质修复。** Terra主责公开退出完成回调的重入/异常与提交后清理：固定精确参与者，提交后的准入状态覆盖turn外requestApplicationExit，确保host/window lifecycle回调不能增窗改变迭代集合、复活终态，或因抛错中断其余参与者和transport/loop/资源退休。复用既有清理，不造另一套退出状态机；保明确cancel/save失败撤回和混合消费者cancelIntent。用现有生产接缝留turn外max4/两参与窗的DidCommit增窗反例，以及app/window完成回调抛错的清理反例；原native通知重入绿证不能替代它们。先获得可区分事实后最小修复，回调错误仍需具名，不能假称成功释放。新批量门至少复用一条真实未ACK或recovery生产状态，确认任一参与窗欠结算时全体仍活、正确结算后可继续；已有精确同路径原件足够则直接引用，不重建整个owned矩阵。

共同close的Mac专属batch路径须与非Mac原合法退役分开，消除非Mac恒拒导致的关闭失效；优先窄能力分派/编译分支和复用旧路径。只验证该受影响分支，不追更W/H冻结包、不在本Mac包重开跨平台移植。两处修复与相关衔接合并一次必要正常退出消费；输入正文、系统拼音、十轮资源和旧性能已验范围按身份复用，不逐补丁重跑。

**然后持续完成实际输入成本和系统可用性。** Terra继续Rules直接writer实际dispatch/window/session/thread与owner生效、batch request、accepted scene和drawable呈现的最小因果关联。只补当前缺失身份，不能为测量实现假的BusinessOwnerRevisionProvider、改正文权限/版本或把跨度当CPU原因。一条正常因果链先成立，再按实际热点修冗余构建/布局/等待和调度；无可解释数据不猜优化。默认OFF和诊断ON分开；具备有效对应关系后才统一跑既定1000条/四类各20事件的最终口径，保慢样本、拒绝和未关联，未达16/32ms如实交付改善与剩余。

Luna承担已明确的消费者/反例/正常输入与VO可观察通道子包，Terra复核归属、主执行集成。VO先复用一个可靠系统正控的实际朗读/字幕/VO光标通道，再验证CJGUI正文、角色/状态、操作、焦点返回，发现框架问题就修共同语义投影并回归正常消费。原系统正控失败不归因框架；通道仍受系统阻断就具名保留并继续其他实现，停止同义开关/取态循环。实际使用gpt-6.1-terra和gpt-6-luna原生子代理，按难度调整思考档位，复用已有子代理，各自明确写集，target和前台串行。

整包最后集中交一个可复盘候选、正常App入口、实际收益/拒绝边界/性能结果与未验项，直接回指导；中途只对真正架构/安全矛盾或交叉写集升级，不为完成一个修复停工。所有本次证据沿现有目录。E累计留存14.25GiB/峰15.5GiB、临时1.5GiB不变；仅把DS子范围留存调至1.5GiB、峰仍2GiB，仍包含在E内，不能相加或清零旧账。先落实本线可再生产物退役及当前候选/efee保留方案，保唯一RED和必要运行原件，宿主峰后至少20GiB；不得为最后余额反复压缩/重跑。无Git写、额外顾问、新监控/用户线程；保护H/W、ds55和归属不明实例。

<a id="guidance-owned-fallback-20261030"></a>
## 正常owned/multiline停滞的有限诊断与修复边界（2026-10-30）

主执行升级的[正常反例](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/normal/range-text-multiline/cua/RESULT.md)成立。指导核了当前保留EXE1574ee0a、49B seed及完整日志SHA8e7390a1与运行元数据一致：首H的receipt为v1→v2，后4笔1B输入保留在handoff1/original_A2，未见完整owner读回；native/画面H加原文而heading仍旧，原正常close未完成，最终-15。不能把保留中的4笔说成已丢失或已应用，也不能把SIGTERM说成正常关闭。470编译输入、退出3RED→9GREEN、recovery35PASS与Rules strict链为执行报告，后续集中按实际源身份复核，不在本次升级重复其矩阵。旧Y失败仅提供原件/原输入不重放规则，本次根因不能套用旧结论。

**直接进行一次同源、有界诊断；根因明确后在现有契约内持续修复，无需再逐项审批。** Terra负责共同Cj/native候选、fallback和handoff的归因/实现；Luna负责明确的正常消费者输入、完整读回与包装衔接，主执行保一个集成负责人和串行target/前台，6.1Terra/6Luna思考档位按难度。已在推进的Rules appliedCollectionRevision缓存失效修复继续，不等待这一条前台门。

1. 区分两个问题。源码BEGIN在activeSourceCredential为nil时返回unsupported；凭据工厂又明确允许不可冻结delegate等情况走live绘制。因此nil不等于原输入非法，也不证明fallback只能失败。分别记录首个凭据拒绝分支（对象/tiles/scale、delegate、attributes或temporary runs冻结、正文等值、typing attributes）与fallback之后真正不能前进的状态。不得删delegate/属性、伪造凭据或放宽正文/版本等值去强行通过。若是合法不可缓存源，修正常live fallback；若是来源或生命周期不一致，修其归属，保原accepted画面、owner与受保护输入。

2. 复用现有默认OFF诊断门，补BEGIN自身的nil点以及同一次candidate的fallback/frame/menu、selection capture/bind/prepare、nativeStaged、submit/present/accepted或cancel/reject理由。联结session/generation、preparation/候选base/目标scene、request/binding、handoff/transfer、原输入nonce/序号、owner/context/source版本与范围；观察实际返回，不为日志再调用一次捕获/绑定/布局或清队列。预算跨新preparation共享，按session/generation与原handoff计数/去重，建议全链至多128条状态变化加总计，不能每个新candidate重置次数。当前已有两个线程日志拼接和无界PREPARE/BIND输出，要用既有日志出口作有界完整记录；只抑制日志不等于修掉CPU空转。

3. 维持原49B seed、自动caret0、一次CUA typeText Hello，诊断源只差有界观测，并记实际编译/签名运行身份。已有停止原件保真，不需要重做原RED。一次记录能区分首拒绝与fallback终止/重复边界即停止失败采样；不等600秒期限或继续刷几十万行。相同签名重复且owner/handoff无进展时按准确自有PID收尾，记非正常退出；不要延长时限、补点击、重发或修改受测输入来救绿。首拒绝不充分时先分析已得原件，不自动无限加点重开。

4. 修复必须保持同一原输入/源跨度、FIFO、owner receipt、单次交接和版本拒绝。若候选在无新事实时重复取消/重建或反复绑定transfer，定位具体basis/返回状态后保留或正确退休原候选；不靠不断分配新preparation制造进展。没有可推进工作的等待复用既有真实唤醒/结算，不能加sleep，亦不能清空retained bytes或伪报handoff完成来关窗。若需要改变owner/FFI/异步资源权威且方案仍不明确，冻结该问题并带新事实升级，其他工作继续；明确的局部修复自行完成。

5. 反例应经过真实owned-preparation BEGIN和fallback衔接，既有selection-only native绿证不替代；修后关闭诊断，正常入口同一Hello操作取得完整54B（Hello+原49B）、实际逐笔版本/无重复、匹配可见正文和heading、随后一次正常关闭/进程结果。版本按实际receipt核算，原manifest中的57B是另一条尚未运行的脚本序列，不能拿来当本次Hello期望。未验完整owner不能用AX或首32B摘要代替。两张tint缺资源是独立包装问题，沿正常配置修资源运输即可；不删visual lab、削视觉负载或将其先验归因为本次输入停滞。无需新SDK、80事件或资源十轮，相关修复稳定后统一整包冻结验收。

以上仍属当前Mac整包。efee当前、26候选以及W17ee/H冻结保护不变；容量沿原累计口径，保唯一失败日志/必要二进制，可保真压缩一次，不增加成套副本。指导只写本接续和ACTIVE，不接管实现、不启动顾问/新线程/监控。

<a id="guidance-owned-drawable-diagnostic-20261030"></a>
### 补齐提交返回点的一次定点诊断（2026-10-30）

本次调整前述“一次诊断”限制：允许再做一次只补遗漏返回点的短诊断，然后依据真实原因修复。理由是新证据已经排除凭时序猜修retire/nonce的方案，而第一次没有记录selection已准备后kind10实际返回与cancelSubmittedPreparedCandidate；机械坚持次数会迫使使用不含真实Cj owner的替代夹具，不能解决本问题。此次不批准无变化重复，也不继续扩大selection-only矩阵。

指导已核实际App95d0f4bd、完整40205B日志26f1ae90与运行元数据、632条源码归档SHA全匹配（这是输入集合，不是632个编译文件）。日志显示temporary_attributes首拒绝，configure/capture/bind/selection准备成功，同handoff持续换candidate而未accepted。两份production fixture日志确认真实BEGIN unsupported、未完成retire的同ID admission为capacity，正常结算后新kind10得到Ready并live Present；selection-only保留4笔也能Ready，但其owner保持10/5B，并未复现真实v1→v2、49→50B。这些范围支持补诊，不能推出已有生产修复或整个fallback无缺陷。

开跑前由主执行与Terra用源码把观测缺口一次补齐，自验后直接执行，不再回指导请求同义批准：stage21记录实际state/status/stop/prefix与nativeStaged，stage22覆盖submitted取消；native区分staged scene/background、proof身份/descriptor以及ticket失配。若proof descriptor分支命中，必须能由同一记录区分view/device/pixel format/sample count/roles/pipeline对象等实际谓词，不能只留下笼统proof mismatch再要求第三次补点。读取当前判据的值/比较结果，不额外重做capture、bind、layout或资源请求，保持原返回和生产行为；默认OFF及同handoff共享128条上限不变。

观测身份要真实标注：现有Cj trace的owner取presentationBefore.version，所以1与native afterVersion=2不自动构成失配；stage21/22应读候选已持有的真实transfer身份而非把0占位解释为丢失。记录实际preparation、ticket nonce/generation/kind与取消前状态，按有意义变化去重，保第一个失败至原handoff下一次重复的完整边界。现有run元数据diagnostic_environment为空，但launch明确FIRST_REFUSAL=1且确有trace，此次是ON；沿原驱动补识别该开关/保存launch，不能拿空字典作OFF证明。

仍为原49B、自动caret0、一次Hello、同一生产Cj owner。取得首个具体返回与重复边界即可收尾；真实无进展就按准确自有PID停放并如实记非正常退出，不等lifetime期限，不加延时/补点击/重发，不手设ACK/版本。根因明确后在既有owner/FIFO/receipt/GPU资源契约内完成最小修复，不需要逐补丁再批；若新事实证明要改变权威或安全方案仍不明，再带这次具体predicate及建议升级。修后默认OFF正常Hello54B、完整owner/逐receipt版本/画面及正常关闭，复用其余已绿证据。

执行报告临时占用1536630784B、余73981952B，不足以凭空假定容纳新大构建。保原App/632源/日志后先退役本线可再生target或raw图，核实际峰值，再复用原工作目录；容量不增加、不把旧账清零。指导只读宿主约197.79GiB。Rules缓存失效三项GREEN按报告保留、其余独立交付继续；6.1Terra/6Luna保持原分工，最后集中报告，不新开阶段/线程/监控或重跑80/资源十轮。

<a id="guidance-current-root-accepted-20261030"></a>
## 共同根交付复核后持续完成本包（2026-10-30）

**本次输入/退出与缓存增量按证据范围接受，当前整包继续。** 指导已从632源归档严格重放两份增量，633/634输入SHA全吻合；window最小diff严格反向还原c23，当前为511f66ee。生产补诊dee5836d完整40315B确见kind10 Ready后kind7结果尚未由Cj结算，下一turn的kind10被Cj严格kind校验拒绝并submitted取消；排序修复把同候选selection-bound menu完成移到drawable reserve前，已有menuReady/binding守卫让后续kind10原票据续行，保最终native lease检查。没有把不可冻结临时属性改成可缓存，也没有改nonce或放宽kind拒绝。第二诊断实际90秒timeout/-15，不记作及时收束或正常退出。

指导核迁址App44bd实际EXE/codesign0、正常log a1c2adcd完整14736B及PID59291退出0。原49B加一次Hello与最后完整owner54B逐字节相等；原日志5收据按v1→6、0:0至4:4各1B，无重复，pending0/applied5/rejected0/timing=off，未见FALLBACK行，launch清除诊断门。中间只读32..36B前缀，完整正文证明只属最终v6；画面为执行线程CUA内联原件，指导未另重开窗口或把它称物理HID。关窗后工具误重开的59816无输入、另行正常清理，不混入这条结果。原1574/95d/ae8失败证据继续保留。

退出回调源码已固定提交参与者，在公开回调前封住重入准入并标记全部已提交窗；应用/窗口回调异常具名捕获，后续退休/transport善后继续。指导核3个实际RED、9个独立GREEN原日志；nonMac只接受窄分派源码修复，未运行其他平台。原真实recovery通知由正常pump消费后35 PASS原件成立，不能替代所有恢复路径。实际same-event只读Experimental scope由原诊断门启用，2 GREEN原件已核；Rules原始输入→writer→dispatch→accepted/drawable原件SHA及单样本身份衔接成立，12.808542ms是writer返回上界、60.38575ms是ON呈现跨度，不是OFF/p95。缓存修复的实际1000→0反例与三项GREEN（第三项复用修正后的夹具日志）按范围接受；初次选择夹具失败保留，未宣称真实正常延迟已改善。图工具没有覆盖到这次Cj责任路径，复核依据是相关实际源码与原件。

**当前取舍与执行顺序：** 复用已具备的组件、组合、公开操作和正常App，将主线转到普通负载的响应成本与同源交付。由原主执行整合，实际复用gpt-6.1-terra与gpt-6-luna，档位按需；继续同一整包，完成后直接回指导，不再等用户搬运或逐项确认。

1. Terra主责性能因果和必要共同修复，Luna承担明确的Rules消费/原件/交付工作，写集、前台和target仍串行协调。在当前源（含缓存和menu排序）复用原1000条/同布局，先用已有严格链和最小必要正常样本找主导耗时；区分raw→writer、owner/build/layout/准备、ready/跨线程等待、drawable真实呈现，沿实际支配段修重复工作或阻塞。不能把1000→0扫描次数或旧ON 60ms当端到端收益。当前same-event scope只在INPUT_LINK_TRACE开启时存在，不能用该ON链或空诊断字典冒称OFF。
2. 原固定四类各20事件的最终口径继续有效。此前“不重跑80”针对没有新实现/疑点的重复矩阵，**不禁止本包真正的最终验收**：实际代码稳定、四类关联/拒绝与采集方法可解释后，自主做一次最终矩阵，无须另要批准。先确定默认OFF能拿到哪些真实原始时刻；若需轻量观测，明确模式及成本，与OFF功能/可测成本分开，缺失的OFF因果p95保留未知，不能扣除猜测开销或冒称零成本。若测量通道有实质限制，集中给可支持的口径及具体限制，实际修复和交付继续；保慢样本、无变化/合并/未关联，保持1000负载与16/32ms目标。
3. 两项Cj回归当前都在accepted首帧前置失败，既不计GREEN，也未证明是生产排序缺陷。先对照保留原件、成功正常App及既有同型测试的host/main-loop/owned-turn/链接身份，定位首个无法前进的具体状态。明确新差异后才做一次针对性修复/回归，不无依据第五轮重编、延长5秒等待或手设accepted/ACK。现有正常Hello修复无需重新争取接受；前置问题不阻断独立性能与最终候选准备。
4. VO按原任务有界推进：有真正改变投递/观测的方法后，做可观察VO光标/读出/动作的系统应用正控，再消费CJGUI；没有新方法就保该依赖，不重复旧键组合、不拿AX/进程作VO证明。只阻塞VO结论，不阻塞其他工作；恢复原设置。
5. 本包必要代码稳定后，自主做一次继任SDK/正常App及包外入口汇合，补受影响mixed双owner/返回原键/末键业务动作/双窗保存关闭与Rules短链，范围按最终差分决定，复用此次54B、回调、资源十轮及其余适用原件。此前“不导新SDK”限制临时诊断和每补丁重复打包，**不禁止最终交付**。冻结26不是当前新源，不能把44bd绿证贴给26；保持efee当前可用基线至指导复核替换，W17ee/H继续不追更。VO/性能/未达断言仍如实列明，不标成熟。
6. 仅修后续还会用到的采集/清理入口：按实际结构化stage识别诊断终态，关窗后用原PID/进程结果/descriptor观察退出，避免CUA过期对象取态重开空窗；不为证明驱动重跑原RED。指导实测四目录加共享testing保守1.24994GiB、测试package已不存在，历史直接释放701.83MiB沿记录范围。E14.25/峰15.5、DS子1.5/峰2、临时1.5GiB不清零；大构建/最终导出先算峰值、复用和合法回收，保唯一失败及必要源/二进制。无Git/顾问/新线程/监控。

上述是本包实现和最终交付接续，不要求再发一轮同义确认。实质新根因/跨模块安全取舍按原规则集中升级；正常工作持续完成。




<a id="root-final-b16382bb-20261030"></a>
## 主执行本包实际交付与指导升级（2026-10-30）

按上述整包接续自主汇合 SDK b16382bb（630文件/607输入），当前共同根无漂移；Mixed20abf2c7/defaultOFF真实双owner、公共修改后不补焦首键、帮助层返回、双窗业务/UI保存正常exit0，Rules fa64ed57/defaultOFF真实1000条原键+即时Apply、完整owner/保存仅record1label变化、UI保存关闭exit0，端点均在清理前自消。普通包样式资源fallback的启动RED已窄修。kind9 mixed有界运输8→16真实native RED/GREEN；罕见Cj字节拒绝缩8分支及普通消费者9包计数/端到端收益未证，原预算/deadline/lease和其它kind8不变。

性能最终逻辑80仍只有77次实际尝试，selection01/03/05因真实目标身份guard未投；两次观测均900秒超时/-15是Root采集生命周期控制失误，无present终态、p95或16/32ms绿色，不归因应用不能退出。scroll05原raw46仅node21、writer0→120，epoch29/scene53后额外epoch30/scene54及外层-224pt；可能是virtual-list位移未被焦点恢复解释而触发root reveal，缺同turn焦点/bounds/root requested offset，需先有区分力验证再窄修，不再猜改/重发/延时救绿。两项unit现能越过首帧，仍在真实目标断言失败（menu pending未出现；builds2≠3），window511原件未冒充最终cc重测。VO真实正控与Fn投递/观测依赖仍未满足，本轮未改设置。

efee继续为接受基线，不标成熟，不更W17ee/H/Linux；54B、回调/恢复/cache/scope与旧26资源证据按各身份复用。当前临时保守1.292/1.5GiB（含整个shared testing），沿原E14.016/14.25与DS1.332/1.5，不清零；较上次接续收口保留增42.7MiB，直接退役/无损压缩1055.23MiB下界（旧701.83MiB不重复相加），宿主196.10GiB。构建图已收，保留唯一失败/原件/还原元数据，无Git、顾问、新用户线程/监控。

集中事实、精确输入/预期实际/假设/原始结果和推荐验证见 [本包当前结果](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/RESULT.md#final-b16382bb-20261030)、[cohort](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/final-four-by-twenty/RESULT.md)、[source检查](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/final-candidate-source-check.json)、[空间账](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/final-candidate-space.json)。当前没有新证据支持再做核心补丁或相同矩阵；指导需对上述跨模块焦点归属与unit夹具策略集中取舍，独立交付已完成。


<a id="guidance-b163-reviewed-next-20261030"></a>
## b163交付限域接受与同包继续（指导，2026-10-30）

指导已逐件核 SDK 630 payload 长度/SHA、607锁定源对当前根零漂移、manifest/lock，以及38个交付/正常链引用哈希；两份实际 App EXE 分别为20abf2c7/fa64ed57，签名验证通过，启动脚本仅语法/路径检查，没有重开应用。独立解码 Mixed 会话，A为资料 A7、B为Final B69且draft/applied相同；Rules保存1000条独立逐行比对，只有record1名称增加一个1，其余字段/记录及头尾不变。原日志与进程记录支持Mixed双窗、Rules正常退出0，端点在善后之前消失。此功能和分发范围接受，b163作为本包接续源与可用开发候选；efee仍保留为已接受基线/回退，不宣布整包成熟。Escape+9旧批次未投的9、CmdK未出层、ON性能及其它缺证没有被正常链覆盖。

新增样式资源fallback与builder目录一致；kind9宽包的144字符串长度槽、16节点限制、非kind9仍8、原4MiB单槽预算及nonce/prefix/lease规则已按源审阅，native RED/GREEN原件支持有界运输能力。普通应用实际包数、耗时收益及Cj缩8路径仍缺证，不能用静态18→9或测试数替代性能。两unit已过首帧、仍分别失败于pending菜单未观察和builds=3，旧511源结果不贴给最终cc4719。当前采样四目录加整个shared testing为1.29166GiB，宿主约196.02GiB；历史E/DS累计及峰限按原账延续。

本包继续由同一主执行整合，实际复用6.1Terra与6Luna，职责/写集沿原任务。目标是让真实虚拟列表、嵌套滚动与焦点接续稳定配合，并收束普通负载的实际成本；无需等待H/W，也不新开阶段、线程或验证工程。指导不接管实现。

1. **优先修滚动/焦点的真实交互。** 现有 `freezeFocusedScrollOffsets` 只冻结ScrollViewport，`focusMovedOnlyByAcceptedScroll` 按其accepted差值解释位置；`restoreFocusAfterProjectionChange` 仍会对同身份位移调用reveal。源码支持漏记VirtualList位移这一假设，但不能证明它就是scroll05的原因。一次有界原输入观察须带同turn焦点node/resource/semantic incarnation、是否处于实际滚动容器后代、前后accepted未裁剪bounds/clip、VirtualList与祖先viewport的requested/accepted offset，以及reveal与额外request epoch的来源。观察按原事件和candidate关联，不能通过取快照推进事件。若同身份位移由本次已接受的滚动解释，应在既有共同焦点恢复路径承认该来源，保焦点/正文而不反向把用户滚动reveal回来；若证据指向滚轮传播、尺寸变化或其它请求，修该真实归属。不要笼统屏蔽所有reveal，不清焦，不把列表offset直接当像素差。复用既有几何/scroll/reveal及本地参考；至少保“纯滚动不拉回”与“真正重排/布局变化仍能reveal、身份退休不串owner”的区分。归属清楚后自主实现并验受影响正常链，不再等逐补丁裁决。

2. **把两项回归做成能检出原故障的测试。** 菜单用例先确认candidate.selectionTransfer、真实kind7准入与bindingEpoch前置；普通调度下瞬时pending可能不可观察，不能仅凭未采到pending就猜生产失败。需要覆盖pending时，复用既有native测试调度gate，暂停真实已准入请求的执行，验证kind7完成/消费先于drawable kind10；不得手写nonce/ACK或放松生产契约。用同一有效夹具比较排序修复前后，保原RED。builds=3先将每次build/commit关联request epoch与来源：只有证实第三次是开场/聚焦的独立合法请求，才在该前置真实完成后冻结计数基线；目标正文变更仍只能对应一次必要build/commit、无错误rollback，稳定后不得继续增加。若同一请求被重复构建则修生产原因，不把2改3或改成上界。原5秒与48/96界限保持；先把可区分条件和源码准备好，再一次目标回归，不重编试运气。

3. **宽包兼容与实际收益一起收束。** 从合法scene的字符串限制及原4MiB单槽预算先判断“16包超预算而首8合法”是否可达。可达则构造真实合法边界，验证零prefix/未持有lease拒绝后缩8仍完成同一candidate，沿原截止时间与资源责任；不可达则给约束推导，审视是否删除无必要的fallback状态，不能用本就非法的首8样本称兼容通过。在同1000条/同布局的下一次有用正常链里读取实际准备节点/字节/包数与主要耗时，区分传输减少和主队列/呈现收益。若16的成本或复杂度没有收益，允许依据实测收回这项优化、保留输入与退出修复；不为保优化名称持续增加例外，也不再凭静态包数宣称提速。

4. **性能采集先解决完整性，再决定最终采样。** 旧77次/两次900秒超时原件全部保留，不补填旧80缺项或删除无变化/慢样本。把操作、当前真实可见目标解析、保存关闭和footer导出预先准备好；实例存活时只做采集，不插入长分析或文档归档。下一条用于滚动归因/修复的短链同时验证正常关闭与真实present导出，生命周期/观测成立后，才允许一份独立完整四类20笔采样。保持1000条、原16/32ms目标及完整失败记录，选择目标须与当时accepted可见clip/owner相符，setup不充样本。默认OFF和诊断ON严格分开，无对应原件仍报unknown；不能从OFF功能通过或ON accepted推导呈现。没有有效新采集方式就停止该采集依赖，继续实际修复与交付，不第三次盲等超时。

5. **其它接缝与最终交付统一处理。** CmdK未观察到层需按一次实际命令/焦点路径区分投递与框架接线，不把按钮打开层当快捷键通过；可并入上面的正常短链。VO只有新的可观察系统正控方法才接续，没有则明确保留工具依赖，不重复旧键或擅改设置。新源稳定后按实际影响更新一次继任SDK/App及普通入口，复用本次完整owner、1000条保存、双窗退出及历史54B/回调/recovery/resource等各自身份的绿证，不重复全套。当前源码与冻结SDK的状态分开，保护efee、b163原件及W17ee/H；不原位改已冻结包。

继续沿E留存14.25GiB/峰15.5、DS子1.5/峰2、临时1.5GiB及宿主峰后20GiB，累计不清零；高写盘前核预计峰值，复用并回收本线可再生构建，保唯一RED/原输入/完整保存和必要二进制。上述是同包持续实施授权；完成后集中回本指导，重大新归属或安全/低收益阻塞才升级，不要求同义收口确认。无Git写、顾问、用户新线程或监控。


<a id="execution-8882-convergence-20261030"></a>
## 8882 同包修复与继任交付（执行，2026-10-30）

Root整合，复用原Terra/Luna。一次原输入证据将scroll05归因为“祖先先滚、VirtualList又滚”，没有证实先前的reveal假设。修复复用共同accepted binding、组件分发和现有ScrollViewport链：无自有viewport的真实虚拟列表先分发，实际有界offset改变则不向祖先重复消费；真正未消费的顶/底边仍回祖先，offset不换算像素。保留正常重排reveal和身份退休不串owner。另将Cocoa首帧nil overlay的空resource统一为-1，避免同一请求虚假过期；没有另建滚动/退出状态机或外部GUI依赖。

[同夹具原RED/GREEN](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/exit/owned-fallback-ordering/real-admission/canonical/RESULT.md)完成：真实selection authority/provider及A→B completion、只暂停真实已准入kind7的testing gate，验证其消费早于kind10；两项旧回归现在各启动build/commit1、目标epoch再1，非2改3。4项滚动及合法offscreen宽包合计7项绿。私有图恢复旧排序/旧路由都真失败并冻结源/EXE，随后恢复生产源再绿。合法4MiB边界通过真实reuse累计接受大场景构造，不放宽可见文本worker上限；16包零prefix/nonce/reservation拒绝后同prep缩8+8，全文相等。保留16有界运输，但不称已获得响应提速。

继任[SDK8882身份](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/final-freeze/scroll-fixed/identity.json)为630 payload/607 inputs，只有Window/common/native m/h四个生产输入变化；normal C ABI和Cj公共声明一致，runtime_state.cj/cjpm.toml同b163。两份签名Current App经此SDK普通构建；[Rules诊断ON原滚轮/CmdK/1000条保存/正常退出](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/scroll-fixed-short-ready/RESULT.md)、[实际脚本默认OFF功能](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/scroll-fixed-default-off/RESULT.md)和[Mixed公开创建/默认OFF新A/B工作会话保存关闭](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/final-mixed/scroll-current-default-off/RESULT.md)均成立。前者list current0→120、materialized1:6，祖先requested/accepted0/0，详情保持owner1；CmdK走native菜单快捷键路径，搜索层实际聚焦，Escape后消失。Mixed未改UI文档，未冒充新版双窗/完整正文重测；b163旧绿线各留原身份。

剩余性能门明确：[原raw2/ordinal3只到accepted scene10/frame10](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/scroll-fixed-short-ready/short-validation.json)，同drawable回调time0/valid0，无后续同帧有效记录；cadence END854/dropped0与正常footer完整，仍不能给truepresent。9个preparation实际84准入/84服务、prefix守恒，逐prep节点/字节/包数已留。未新开80、未补旧77或两次900秒超时，默认OFF p95及16/32ms unknown。VO无新的系统可观察正控，不重试旧键。首个新版case在业务输入前误读旧ready日志而中止，原件留存；之后只认当前case WINDOW_READY和当前AX身份，没有重投原输入。

[集中结果](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/RESULT.md)、[普通Current入口](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/../apps/README.md)及[续接空间账](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/continuation-final-space.json)已更新。E累计上界14.0034/14.25GiB、DS1.4968/1.5GiB，本线连同整个shared testing 1.2789/1.5GiB；本轮净留存增加29.63MiB，定点回收/已核无损归档837.39MiB，宿主约192.37GiB。旧SDK26、CloseSuccessor与早期源副本及关闭的旧日志按原件SHA/模式无损保留后退役展开目录；8882、b163、efee和可用App保留。原规则产物容量规则继续适用，无预算重置、Git写、顾问、新聊天/自动化或W/H/Linux快照改动。ACTIVE指导段留由指导按本次集中报告更新，执行者未覆盖。


<a id="guidance-8882-reviewed-next-20261030"></a>
## 8882 限域接受与同包继续（指导，2026-10-30）

8882接受为本包当前可运行功能候选，整包成熟与性能目标仍未完成。指导逐件核630个payload长度/SHA、607锁定源对根零漂移，较b163只有Window/common/native m/h四生产输入；最终归档内同源生产文件及3份目标测试与根一致，7份原日志各1项通过，旧排序/旧滚轮的反向差分及失败源/EXE可复盘。测试gate只暂停真实准入kind7，normal公共ABI未扩；原4MiB边界、合法同candidate缩8、返回/版本/owned保护保留。滚动修复接受为“VirtualList实际消费后不再传祖先，顶底未消费仍可上交”；真实重排仍reveal，不将未证实的reveal假设写成根因。首帧nil overlay空resource统一-1修复不靠修改build次数断言。复用已核7项，不再整套跑。

两Current App实际EXE 5eb8d071/26d1a5d6与启动记录一致，签名有效、3个新testing符号未导出，普通构建日志为verified/4成员。Rules ON/OFF原日志SHA吻合、exit0及close_permitted/destroy成立，两个60762B保存与1000条原输入逐字节一致；接受滚动/选择/保存/退出功能，不声称本轮重新验证正文编辑。Mixed新默认会话独立解码为A资料A/4/false、B资料B/2/true、draft/applied相等，原日志exit0及endpoint=cleared；没有重验新源双窗、全文续写或UI文档。b163完整正文/双窗与更早绿证各按原身份复用，efee基线/回退保留。CmdK动作原件的backend是ax_menu_command，实际搜索层聚焦/关闭接受为原生菜单命令消费，尚非真实CmdK键事件路由。

**决定性新增事实：**指导直接解析[新cadence原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/scroll-fixed-short-ready/cadence.log)，85次presented中70个valid1、15个time0/valid0；不能报告该进程或环境完全没有有效呈现。原raw2在499423973455375ns进入，scene10/frame10直接回调为零，随后10→11→12→13→14的interaction accepted链记录同declared_base8/request_current5；scene14/frame14、同layer、drawable13真实time=499424050120542ns。上述只给出可查的后继，不足以把该时间自动归给原滚轮。已安装Apple SDK的MTLDrawable.h:47–52明确0可表示未呈现或被跳过；GPU完成/回调observed时间不能替代。旧报告“同帧没有后续有效记录”成立，不能由此扩大成“无任何可用后继呈现”。

同一主执行继续原整包，实际复用gpt-6.1-terra与gpt-6-luna，思考档位按工作难度选择；Terra可负责跨Cj/native归因与最小修复，Luna负责明确的原件关联/驱动/定向验收，主执行整合。无需同义收口确认，不等待H/W，不启动旧两线。

1. **先从这批完整原件解决输入到可见结果的归属，再改有依据的瓶颈。** 沿现有interaction提交源码核10→14是否保留该动作的业务owner/version、投影内容与滚动结果，区分新输入覆盖、合法合并/动画与同内容重呈现；只能把实际携带该结果的有效drawable归给原动作，不能“找最近非零帧”、复用已退休身份或丢弃未配对/被覆盖样本。若现有source/record足以严格推导，修现有分析器；不足则只补最小因果字段和必要反例，仍默认OFF、限量，不另造审计状态机。scene14只是待核候选，不预填76.7ms为已验延迟。结合真实native→owner、request→prepare/accept、drawable等待/提交/后继呈现，定位阻塞或无效工作；动画/交互帧多不自动等于浪费，包数下降不自动等于提速。证据指向普通可修原因时在原框架直接修并验证，不停在追加日志；根因/重大契约不明才集中升级。
2. **采集按收益收束。** 如需补观测，用同1000条普通Rules一条短链完成一个可辨识输入的原始投递、完整owner状态/反馈、真实有效呈现及正常退出；原件不足的真实CmdK键路由可并入，记录实际backend及keydown/命令到达，不能继续用AX菜单激活替代键投递。前置与脚本在启动前备好、分析在退出后，保原动作不重投；不重开已验7项或旧77/两次900秒链。关联与收尾成立后，按原任务一次独立四类20笔同源同负载采样；保全部慢、无效、无变化与失败，16/32ms目标不降。未满足前置不机械启动80。只有采样揭示的新缺陷/新修复才再做受影响检查；ON成本/OFF功能和实际响应收益分别报告。
3. **VO及交付并行但不空跑。** 若能提出不同于旧重试、能观测VO光标/输出/动作的系统正控方法，先一次有限正控再正常CJGUI；否则明确保留依赖，不能循环按键或改系统设置。不因VO独立依赖停掉性能/修复。相关源稳定后一次汇合普通SDK/App、更新实际入口及未验范围，复用旧正文/IME/退出/资源绿证，不逐诊断轮导SDK。只把实际改好、正常消费的能力算交付；源码冻结、运行身份、预算和清理集中回本指导。
4. **容量取舍：避免围绕最后数MiB反复压缩。** 指导当前du核本线加shared testing约1.279GiB，与所报上界相容，宿主约192.3GiB；E原累计14.0034/14.25GiB、DS1.4968/1.5GiB仍沿旧边界，不清零。仅将本包DS子留存上限调整为1.75GiB（增加256MiB），其峰仍2GiB，E总留存14.25/峰15.5、临时1.5及宿主峰后20GiB不变；子账有余量不允许突破更严的E总账。额度只供有实际用途的增量、必要原始反例与可复盘产物，复用现有构建目录，成功/失败/取消均退役可再生产物，不为测量再复制全SDK。所报837.39MiB是定点退役/保真归档的分配空间下界，不冒充宿主净新增可用空间，旧回收不重加。

原件入口：[测试](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/exit/owned-fallback-ordering/real-admission/canonical/RESULT.md)、[源与App身份](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/final-freeze/scroll-fixed/identity.json)、[Rules短链](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/scroll-fixed-short-ready/RESULT.md)、[空间账](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/continuation-final-space.json)。指导本次只读源/原件并改本计划与ACTIVE E，不重编、不启动GUI或整套验证，无Git写；W/H/Linux及旧执行者状态不变。

<a id="guidance-phase-cost-target-capture-20261030"></a>
## 3915短链升级裁决：先修采集盲点，再判实际阻塞（2026-10-30）

继续原整包，主执行保持根因、实现与交付主责，6.1Terra/6Luna按既定写集参与，不恢复旧Sol/DS或新增咨询。不同意凭重复解析次数做缓存/先poll再resolve的猜改：samePaint立即采纳动画目标及撤回drawable，另有focus/hover/pressLease/modal/accent/origin-rebase/binding输入，当前没有完整安全失效依据。也不猜调Metal属性、缩负载或启动80笔。

**本次复核事实。** 指导核391547a9 EXE与d1f5e0ae日志原件哈希、60762B保存正文逐字节等于同1000规则输入，PID76963正常exit0。CmdK单次CGEventPostToPid down/up及native两条同userdata/k接收、搜索层与Esc反馈属于合成键盘正常通路；不是旧AX菜单证据或物理键盘证明。实读cadence为826条、82个presented，其中50有效/32零，目标scene14–33共20条全零，提交/回调drawable与layer均匹配；scene34已换request6，35的有效时间不能借给request5。旧8882的v1.3锁源单次后继76.665167ms与本次严格分开，主执行完成既定分析器合流审阅即可，不把它升级成新版本/OFF/p95。原件见[本轮目录](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/interaction-present-continuation/)。

当前证据不是“所有呈现接口不可用”。[Apple presentedTime说明](https://developer.apple.com/documentation/metal/mtldrawable/presentedtime)明确零值可能是尚未显示或帧被丢弃；callback到达、GPU结束都不能替代有效呈现。已核本地SDK MTLDrawable.h同义约束。CJGUI在37395–37409读取回调自身时间/ID，37558使用presentDrawable；本地GPUI metal_renderer.rs:448–488也区分普通present+commit与明确transaction路径，参考不支持无依据换Metal配置。

**下一步一次有判别力的收束，准备妥当后再开同1000正常Rules：**

1. **把目标区间保住，而非再延长日志。** 原owner主ring已覆盖145558条旧记录，interaction_retention为0。native:1910–1918只保留≥16ms、同live/thread且带输入的最长turn；跨多个短turn或线程迁移的24ms原始事件→accepted链可全落空。这是已见采集限制，不先断言哪个资格分支在本例触发。复用现有8192交互保留区/既有记录格式，为一个明确session/generation/raw(或已有dispatch/turn归属)提供限定的目标区间保留：含原输入至目标accepted/其owner返回的完整阶段；时间近邻不能补身份。若原有触发接线确有缺陷则最小修；若按设计未选中，增加仅诊断开启时的目标保留方式，保留原“最长turn”定义，不放松CPU同线程/时钟有效性。线程变化或CPU缺失仍unknown，whole-span的阶段原件不应一起丢弃。标明首尾seq、容量/丢失/覆盖，不增加成套ring或扩采全部历史。不要中途调用现有一次性owner_trace_export冒充可重复快照，它会占用最终导出。
2. **同一cadence中补能区分原因的少量事实。** 在已有合法main-thread采集点记录实际window号、active/key/main、visible/occlusion/minimized、screen与view/layer附着/隐藏状态及必要layer尺寸；记录实际present配置值、command-buffer终态/错误码，而不改配置。沿现有窗口变化入口保留变化边界；拿不到的字段留unknown，不能从后来key_window=1反推滚轮时。callback沿用提交时冻结标量与真实drawable标识，不跨线程读AppKit、不延长session/drawable生命。active/key/visible只用于归因，不替代present，也不把后台可见窗口一律判不具资格。默认OFF及原有有界容量保持，采集附加开销单列。
3. **一个正常实例、一段预先准备的驱动完成正控和目标动作。** 开始先把自有正常窗口置于可辨认且无遮挡的位置，并记录真实前台/显示事实，保护用户实例。复用既有可见选择变化或CmdK→Esc作为同layer普通呈现正控，确认返回原正常工作区后只投递一次目标滚轮，保原输入、完整状态/反馈、phase/cadence、保存及实际退出码；动作之间不切回Codex做长分析/取态，避免工具改变前台成为未知干扰。用既有完成事件和有界观察，不加人为等待/重复滚轮以等出绿帧。正控及目标都必须保留零/慢/失败记录；这是独立新样本，不“修绿”旧20零。新trace采集与原准备负载保持同源，稳定前不导SDK或复制两套新构建树。
4. **按该结果直接实施，不再为小步回问。** 若确证是驱动遮挡/窗口资格变化，修现有验收入口并保旧样本，不能称框架提速；若可见正控成立且目标仍丢帧，优先核提交/transaction/scene替换及frame完成状态；若主要耗时在raw→accepted约24ms，按保住的enqueue→main服务→ready发布→owner恢复→stage/submit及有效CPU拆分定位，不能把9批服务合1.731ms当整个排队耗时，亦不能把27.290ms多次resolve相加充作关键路径。证据指向普通框架缺陷时，主执行直接最小修复、定向反例及受影响正常消费；重叠/回调/FIFO/关闭和owned拒绝不弱化。不满足同源有效呈现或独立方案仍只剩猜测时，交回这个实验的具体分支与剩余原因，禁止无新事实第二次相同短链。满足原前置后才一次性做原四类20笔，16/32ms不降；归因ON成本与默认OFF功能/实际收益分别写明。

这次允许的诊断修复只为改变上述机制/驱动决策，不单独立项为“观测系统交付”。VO已有新正控方法及既定交付整理可独立推进，无新方法保留其依赖。E留存14.25/峰15.5、DS子1.75/峰2、临时1.5GiB及宿主峰后20GiB沿旧累计；159.2MiB退役只计一次。唯一旧RED/有效8882样本、新20零及当前可复盘3915保真，按入口finally清理自有资源。W/H/Linux摘要和写集不变，无Git写；主执行完成本包集中直接回指导，不要求用户中转。

<a id="guidance-display-opportunity-20261030"></a>
## 479 升级裁决：显示机会与可替换重绘的有限实现（2026-10-30）

继续同一整包，由原主执行负责，复用 6.1 Terra/6 Luna，不等待 W/H。此次采集已足够排除“所有呈现都不可用”，不再重复单提交正控，不再以增加日志作为独立交付。下一项实际能力是把已有纯时间推进的交互/动画重绘接到真实显示机会；先做一项受控实现及对照，不能先宣称它就是 96ms 的根因。

### 已核事实与尚未证明的因果

指导重新核了 a429fc72 锁的 607 个实际源文件（repository 两项按仓库根解析），均无漂移；5db1a71c 应用日志和32c5fb15 cadence原件哈希一致。原件中 scene33/frame37 在同window30848/layer52345618320 有有效呈现；目标scene34/frame38及35–37的四个回调为0，scene38/frame42的提交/回调drawable同41、有效时间523262787528333，与raw4的差是96.017417ms。接受源绑定人工审阅下的后继投影结论，仍不是直接目标帧、绝对首次视觉、默认OFF或p95；virtual_accepted仍unknown。20.516ms到accepted与21.187ms到outer-end保留，后者不含紧随的保留区复制。保存/exit0及此前源身份按本次报告范围使用，不重新跑正常链。

源入口已核：host `serviceWindowAnimations` 每个owner turn调用 `advanceAnimations`；Window `advanceAnimationsAtMs` 在变化/终值pending时调用 `presentAnimationValueOrKeepPending`，最终走 `refreshInteractionPaintIfNeeded`。native另有 `scheduleAcceptedScenePresent/armAcceptedScenePresent/presentAcceptedSceneIfNeeded` 的accepted-paint display-link。当前drawable lease及pending transaction防资源错用/重复结算，不是显示机会准入。五个不同drawable的连续提交和在途重叠已见，但7–15ms的间隔本身不能证明超过该屏刷新节拍，也没有“同一帧重复commit”证据。

本地GPUI `gpui_macos/src/window.rs` 的start_display_link→step→request_frame_callback，以及 `gpui_apple/src/metal_renderer.rs` 的普通present_drawable+commit，只作为职责参考，不引入依赖。当前本地SDK的NSView.h说明view display-link与所在显示器同步，隐藏或不在显示器时不回调；沿既有macOS14分支和旧系统后备实现，不新增系统版本下限。此次在线官方文档工具不可用，以上API约束来自已安装SDK，未假称在线核验。

**待区分的单一假设：** owner周转频率驱动纯时间重绘，可能在同一显示机会内反复计算/提交可替换视觉投影，并增加drawable/显示等待。其是否造成这次慢呈现尚未确定。不要改Metal配置、drawable数量、transaction模式或等待GPU/present来验证它，也不要一起加paint缓存、先poll捷径或抑制动画。

### 实施边界：一个已有窗口调度机制的接通

1. **先固定有区分力的生产反例，再实现。** 用实际host/Window/native路径验证：没有新显示机会时多个owner turn，不应不断推进并提交同一accepted业务基底的纯时间投影；出现新机会后消费当前时间的最新值，不能补跑积压的所有动画步。若当前路径事实上已满足该性质，保结果并直接否定该假设，不为得到RED另造生产行为。测试可控制时间/显示机会供给，但必须调用生产路径，不放松FIFO/owner/票据准入；不用测试通过冒充正常呈现。
2. **复用现有view display-link与共同唤醒，不另建帧线程/定时器/队列。** 为每个live session/window保留至多一个最新机会及未完成paint需求，按generation拒绝迟到回调；native callback只发布有界机会/唤醒，不重入Cj/controller。无机会时自动动画工作挂起等待，不能把“有pending paint”当成每turn立即ready而忙轮询。按单调时间采样，不按漏过的tick数量追赶；没有工作时解除请求。
3. **只约束可替换的自动时间推进，不把全部refreshInteractionPaintIfNeeded/deferredInteractionPaint一起延后。** 新输入、公共操作、full candidate、owner/布局/绑定改版、focus/selection/IME、关闭与票据结算仍遵循已有路径和优先级；首个新业务投影不能等上一帧实际present或回调才准入。新目标注册、samePaint时的目标采纳、终值pending、reduce-motion、暂停/恢复、移动origin重基与资源失败重试必须保留。公开显式推进及非Mac语义不因Mac宿主接线被悄悄改变。需要区分自动tick与新语义请求时做最小内部区分，不重写输入/提交状态机。
4. **与native accepted-paint共用机会归属。** 不让同一机会一边先绘旧accepted、一边再独立绘Cj时间投影而形成第二套调度。结合已有dirty、ready lease及实际commit处理机会消费/保留；未ready/提交拒绝/同paint时不要丢native文本/选区/光标重绘或动画终值。新的full scene若已覆盖待绘状态，按原提交语义结算；不能丢其资源或拿旧base paint覆盖它。显示机会被隐藏/离屏暂停时不能堵塞业务输入、保存/关闭，恢复可见必须能继续；旧系统fallback保留有界唤醒。先读完整相关函数/测试，复用已有拒绝和收尾，不凭符号名重造。

Terra负责复杂归因与获分配实现，Luna负责方案明确的反例/消费/资源子包；主执行集成。同一native文件/target/桌面串行，子代理只回主执行。允许本包必要的Mac内部接线和host/window改动，保护W/H/Linux、冻结SDK及他方实例；不以共同头变动为由同步平台快照。

### 只做能决定保留或撤回的验证

- 先做相关确定性回归：无机会不反复提交、新机会取最新值、失败/终值保留、generation/关闭及新输入/绑定拒绝。复用旧输入/关闭/资源绿证，不重开旧77、7项或900秒矩阵。
- 实现具备上述正确性后，用一份受控候选做**旧调度与显示机会准入各一条**同1000 Rules/同布局/同动作短链；临时内部选择只用于该对照，不成为永久两套调度。观测显示机会时，对照分支不能因此额外唤醒owner或改变其原工作；两边诊断配置一致。准备与采集在开窗前就绪，输入一次、动作后观察，分析放退出后。不同运行保独立raw/session/scene归属，全部0时间、慢帧、未关联和失败原件保留；不能把479的旧样本当新候选对照。
- 用现有有界记录回答每个真实显示机会的纯时间提交、有效CPU、drawable等待、raw→owner与raw→有效呈现是否改变。补字段仅供这项判别，不建新ring/遥测工程。帧数少、callback或GPU结束都不是收益；后继关联沿本次人工源审阅的适用边界，新源需核该衔接，不能无条件沿用旧profile。
- 若正确且有实际响应/有效CPU成本收益，收束成唯一生产路径，完成默认OFF受影响正常输入/保存退出及最终合流。若基线本就每机会至多一帧，或只是帧数下降而成本/响应未改善，明确否定该归因；无独立收益就撤回这项实验实现，保原件，不能继续第二轮同样采集或顺手试另一组Metal参数。只有具体新源缺陷才修其必要分支，不再发同义确认。
- 原四类各20笔/16与32ms门不降低；候选稳定且因果映射、观测口径真正满足原前置后再一次完成。诊断ON与默认OFF功能/成本分别写明，不能拿ON延迟写成OFF达标。其余已授权正常分发/最终一次SDK汇合继续推进；VO无新正控仍保依赖，不重复失败方法。无收益/仍不达标就把性能缺口明确交回，不能把观察交付或局部功能包标成熟。

### 本次资源裁决与收尾

本次报告含预留后的E14.2156/14.25、DS1.7089/1.75GiB仅余约35/42MiB，不能让必要实现再次陷入压最后几MiB的循环。**仅为上述一份受控候选、必要原件及最终集成，E留存调至14.50GiB、DS子留存2.00GiB；E峰仍15.50GiB，DS子峰2.50GiB，临时工作范围上限2.00GiB。** 所有旧占用不清零、重叠不相加，各子账仍服从E总峰和宿主峰后20GiB；写盘前重核，不能将新上限当必须用满的额度。复用一棵构建树；保8882可用交付、479必要原件和当前受控候选，历史诊断App按既有逐成员校验保真归档，成功/失败/取消均清自有可再生产物。756.88MiB分配释放与旧837.39分别只计一次，不冒充宿主净回收。

结果入口仍为[本包RESULT](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/RESULT.md)和[本次PHASE原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/interaction-present-continuation/target-capture/case-source/PHASE-AND-SUBMISSION.md)。不另建任务卡、顾问、聊天或监控，无Git写。持续完成可实施部分后集中直接回本指导；不要求用户中转，不按每个小补丁停工。

<a id="guidance-wrapped-layout-reuse-20261031"></a>
## 显示机会负结果接受；接通正常包装下的区域复用并完成原包（2026-10-31）

继续当前整包和同一执行线程，不新开性能工程。主执行负责归因、实现与集成，实际复用 gpt-6.1-terra 和 gpt-6-luna，思考档位按工作难度调整；子代理只回主执行，写集/构建/桌面串行。原可用交付仍为8882，显示机会实验不是新候选。

**复核结论。** 指导核实验锁6375的七份源码归档与目标一致、签名EXE bfa1196f一致；撤回后a429fc72的607个根输入全部一致、实验测试源已移除。两条最终链的18件关联原件SHA/长度匹配，目标raw/detail/pump/writer/dispatch/batch/终态行在应用原日志，后继presented行在cadence中；各自终态exit0且endpoint清理。接受同1000规则60762B保存/状态与有界负结果：observe/new的有效后继分别91.080459/94.422250ms，目标自身presented为0，两目标raw→accepted区间均无自动动画opportunity claim/cost。它们不足以证明显示机会调度收益，也不是该机制一定更慢或端到端回归的统计证据。不再重跑同对照、猜调Metal或为此导SDK。空间账14.3611/14.50GiB及163.10MiB已凭据释放沿原口径保留，不把仅有线程输出的两份测试树退役重复加账。原件见[已复核负结果](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/display-opportunity/RESULT.md)。

**下一项实际框架能力与源码依据。** 复用现有CjguiComposableUiLayoutReuseCache及显式layoutReuseKey，让正常包装层下的稳定区域确实到达既有复用入口，不建立第二套缓存/调度。当前Rules的LayerHost(1)→ScrollArea(480)→Vertical(2)→header(5)已声明页头复用键；layoutLayerHost的普通base保留深度，普通scroll内容三个路径却加一，Vertical对子节点再加一，而layoutNodeOrReuse只在reuseDepth==1查缓存。因此页头落在深度2，源码上不会尝试其显式键。入口为composable_ui.cj的layoutLayerHost、scroll内容布局、layoutNodeOrReuse、signatureFor及Rules main的构树/页头键；先保留同真实树形的生产反例确认，不把静态推导直接写成运行通过。

目标raw→accepted约21.526/19.486ms，batch尾→candidate创建的约6–7ms中已有projection/build/layout工作，candidate在布局后才创建，不能当作空等待。两次布局片段已有测量缓存命中、native_measurement_calls=0，没有新字体缓存的依据；嵌套阶段不能直接相加。本次复用接线也不先指认是约90ms后继呈现的主因。

1. **一次完整修复，先确认边界。** 主执行与Terra核普通包装下的既有复用准入，选择最小实现使合法稳定区域可达；可以调整包装层相对深度/区域入口，但不能简单把全部节点都改成可缓存。保留既有条数/节点/字节上限和默认不做全树结构签名；scroll/layer及动态虚拟子树本身仍走canonical。缓存键继续包括bounds、所有clip、input scope、measurement environment，owner/identity、origin/anchor、候选accepted才commit及拒绝discard规则不变；祖先命中不再重复捕获后代，不能引入每层全树扫描。先核相关现有实现/测试；若发现比普通接线更深的归属问题，再按机制查本地参考，不引入外部GUI依赖或新公共API。
2. **同时审阅被激活的调用方依赖。** 页头键当前未生效可能掩盖漏项；逐项核Rules该区域后代的文字、样式、可用性、动作/owner及界面工作区状态依赖，必要时在既有key源最小补齐。禁止用常量或放宽签名刷命中，也不把全树总revision塞进key使每次miss后声称接通。保同key可复用、任一有关输入变化即正确失效。用既有布局/准备复用测试承载真实包装、内容与几何/clip变化、测量环境变化、动态区域拒绝、候选拒绝不污染旧缓存；完整输出与canonical对照要含业务/语义元数据及顺序，不能只比节点数或命中数。公共/native影响扫描按实际改动，图覆盖不足补源核，不为此扩大到其他平台。
3. **有可区分结果后回正常消费。** 冻结改前/后源身份，复用一个构建目录和现有同1000 Rules负载，不为每个小补丁造包。汇合后做一次有界同配置成本对照与必要默认OFF正常链：内列表滚动时稳定页头实际复用，改变页头相关状态/窗口几何正确失效，真实字段与owner/版本、保存、正常退出不回退。复用已过输入/关闭矩阵，只补本次受影响的衔接及必要第二消费者。用有效CPU/实际响应判断收益，命中数、少走节点及candidate accepted不能单独当端到端提速；诊断ON与默认OFF分开，不把后继presented写成绝对首显。只做能改变保留决定的一组对照，不反复换容量/阈值/延时；若普通包装假设不成立或实际成本没有收益，撤回该局部优化、明确反证，继续原包可独立交付项，不生成第三套猜测性实验。
4. **同包持续合流与交付。** Luna承担明确的受影响正常消费/分发收束子包，与Terra/主执行错开共享target和桌面。真正有效且通过的共同差分回接正常构建与唯一产品候选；冻结8882不原位改，也不为观察版或同字节产品重导SDK。现有可独立完成的分发入口、正常消费者、身份与资源收尾继续，已经完成的复用原件。原四类20笔、16/32ms和VO门均不降低；只有原映射/候选稳定前置满足才跑原性能门，VO无新正控不重试旧方法。可用功能范围与尚欠成熟度分别集中报告，不按小补丁停工，不把未验门改名成完成。

仍沿AGENTS容量与验证价值规则：E留存14.50/峰15.50GiB、DS子留存2/峰2.5GiB、临时2GiB，旧累计/64MiB预留不清零，宿主峰后至少20GiB。新增大产物前核余额；已否定实验的可再生产展开App/重复树按已有逐成员保真归档和准确归属退役以腾空间，保唯一RED、源码/二进制和原始输入，不为余额再跑GUI或猜删其他线。所有入口成功/失败/取消均收尾自有资源，释放量按凭据不重计。保护W/H/Linux和用户实例，无Git写、顾问、新聊天或监控；完成可实施部分或出现需改变方案的具体阻塞时集中直接回指导01a17207-04bc-76a2-90c3-99c8c5060423，不要求用户中转。

<a id="guidance-wrapped-review-20261031"></a>
## 包装复用交付复核与同包有限返工（2026-10-31）

主执行/模型/写集及原整包授权不变。已核新锁1f22d2f1的607项根源零漂移，相对a429仅Core bb01与公共Rules main9fbc两项生产变化；源码归档含私有main2ac8，签名EXE a5d与身份记录相符。最终testing归档478成员逐项匹配清单，其中Core bb01、测试5551；9份最终日志确实各1项通过，旧包装hits0、根semanticLabel失效、旧clip owner误命中导致无效scene以及324→25的原记录成立。它们是源/机制反例证据，不是正常应用已通过或CPU收益。CodeGraph本轮未覆盖该Cj路径，按实际差分补核；不重跑旧绿色矩阵。

**仍须一次集中完成的两个离线衔接：**

1. 交付目录的production-diff-vs-8882.patch已严格按上下文重放：55dfb0ef基底只得到04703af8中间源，不等于当前bb01；遗漏了blockedByDynamicDescendant及最终嵌套扫描处理。保留必要中间身份，交付入口改为真正最终差分，并从精确基底严格重放到最终根源码/归档一致。只有交付差分更新时，不重编、不重测。
2. bb01的“已扫描则不再探测”只在blockedByDynamicDescendant为真时生效。signatureFor在编码显式key之前遍历后代；普通静态子树若因maxSignatureBytes拒绝，signature为不可缓存、已经扫描但blocked为false，layoutNodeOrReuse仍把cache传给更深key，可能重新形成逐层全子树扫描。先在既有生产用例里做有区分力的小反例：24层普通显式key链、无scroll/layer/split/tabs动态后代，key长度大于合法1024字节签名上限（例如2048），完整canonical保持一致并核实际扫描量。若生产路径证实，最小调整“拒绝前避免无用扫描”或“真实扫描后的保守fallback”，不能只针对动态原因，也不能把未扫描包装阻断、清计数、缩链或放宽阈值救绿。若该输入实际在更早生产门被拒，给具体原件再选择真正能触发该分支的合法输入，不为追RED弱化生产。保原根声明/clip修复、容量及候选commit/discard规则；此为同一深层准入的边界返工，不开第三性能实验。

继续实际使用已有Terra/Luna：主执行负责归因/集成，Terra承担明确预算拒绝衔接，Luna可完成精确交付/准备的独立部分；源码与target串行，不加顾问。生产未变只补交付；若确有生产修复，只补相应定向回归、归档/锁/正常候选身份和一次必要构建，旧原件按原身份复用，不复制整套构建树或每补丁导包。根声明和clip的独立正确性修复必须与深层复用的成本采用决定分开；将来成本不改善时不能一并回退已证实的旧正确性修复。

**桌面事实与恢复顺序。** 指导本轮再次只读确认当前uid501的CGSSessionScreenIsLocked=true、global IOConsoleLocked=false。旧479/PID41250仅窗口准备失败，目标输入0、manager超时-15、端点清理，不是功能RED或一条有效成本样本。不要尝试解锁、改设置、反复AX/启动/投递；离线返工完可只读检查一次，仍锁就地待条件，不能循环轮询或新建监控。会话真正恢复且无新的已知争用时，沿现有授权直接续跑，无需再请示桌面：原同1000规则的一组前/后成本实际仍各0条，保锁屏前缀，正常默认OFF/相关状态失效/完整owner正文版本/保存退出及必要mixed短链随后合流。正常入口若确需SDK，源选定后可先导唯一产品候选再做其公开消费者验收，同字节通过后转最终，不形成“必须先验最终SDK才能造候选”的循环，也不提前宣称最终通过。

保留当前性能未验，不能因锁屏认定无收益撤掉候选；同样不能把命中或编译当收益。80笔/16与32ms、VO原门不降，VO无新方法不重试。E留存14.50/峰15.50、DS子2/峰2.5、临时2GiB沿旧累计；目前报告E14.4029、DS1.8961，有凭据新释放533.70MiB与旧释放分开，不重加、不归因共享卷free。高写盘前重核并复用/退役本线可再生产物，不压最后几KiB、不猜删他方。更新原RESULT与来源，不改其他平台/旧SDK，无Git写；原主执行完成或出现真实新阻塞直接回本指导，不要求用户转交。

<a id="guidance-wrapped-offline-accepted-20261031"></a>
## dfbc离线返工接受；保留正常消费依赖（2026-10-31）

上一节要求的最终差分与预算拒绝衔接已完成，不再下发同义返工。指导独立逐行严格重放Core11个hunk：55df→dfbc1693与根源码一致；源码只把拒绝后的递归扫描判断从“含动态后代”改为“实际已扫描显式区域”，未扫描包装仍透传、容量/断言未放宽。2048B静态key/1024B签名上限的bb01原RED为324次，最终25；动态链25。最终五份runner各自确有1项通过，final-dfbc-green清单10件SHA/长度及478源档成员全部一致。该证据支持重复扫描修复，不直接证明CPU/呈现收益；旧根声明/clip正确性修复保留。

正常候选4ecc实际EXE与身份一致，来源80a0125b的607项输入；构建原件的编译EXE/prepackage、私有main2ac8、normal/verified相符。后续ffedb1c2当前607项仅比构建锁多verify_cjpm_mac_testing_link.py，实际根文件全部匹配该当前快照；不把ffed写成4ecc构建来源，不因这个工具差分重建App。原公共/私有key依赖审阅按不变源复用，不扩大到其他平台。

**证据覆盖更正必须随交付保留。** 上一轮指导当时读到的bb01九项原件，后被同输出目录复用覆盖0–4、完整result及source-inputs清单/源档；现存5–8四日志已独立核SHA。当时审阅不是丢失原件的替代物；当前五项或早轮不同源的结果也不能补名为原九项。保留更正、前像、剩余原件及范围，不补跑伪造历史，不要求为此重开旧矩阵。新最终五项原件完整，旧拒绝/anchor/metadata/clip按仍存原件及不变实现有限复用。

防复发已接到实际测试入口：固定--output构建图配独立--evidence-output，旧证据冲突在启动工具前拒绝，marker/log/manifest/tar/result独占创建，finally不删除非本驱动创建的output/native。指导核e958→9d9工具差分及新增75c8测试逐行严格重放等于根源，3项Python文件/短子进程原日志通过；这不是完整native/cjpm执行证明。今后在下一次本来必要的测试使用新入口，不专门重跑一轮证明它。

主执行已完成当前可独立实施范围，按最后一次真实会话检查仍锁屏。现不再造离线任务、开窗、轮询或要求同义确认；保留这个明确依赖即可。收到解锁事实后沿原授权直接继续同1000 Rules一组成本对照（旧锁屏前缀不是有效样本，两侧仍0）、默认OFF正常owner/版本/状态失效/保存退出及mixed短链。只按有效成本决定深层复用采用，独立正确性修复不随之误撤；必要时先产一份明确身份的产品候选SDK，以公开消费者验收后同字节转最终，不再导观察包。可用交付仍8882，原80笔/16与32ms、VO、整包成熟均未通过。

资源上限和旧累计不变：报告E14.4263/14.50、峰15.50，DS子1.9195/2、峰2.5，临时2GiB、宿主峰后20GiB；新产物前按原规则重查、精确退役本线可再生产物，898.22MiB本阶段回执不得再加旧释放或冒充共享卷净回收。仍由现有6.1Terra/6Luna与主执行推进同包，W/H/Linux不动，无Git写、顾问、新聊天/监控。仅新交付或依赖解除后直接回指导，用户不转交报告。

<a id="guidance-owner-handoff-20261031"></a>
## SDK318限域接收；接续外部正文与视觉选区交接整包（2026-10-31）

**取舍与现状。** 深层布局复用的一组同1000条成本对照未显示收益，按原约定撤出，不继续为这个假设增加轮次。当前Core50c相对55df保留根声明完整编码及父clip ownerIdentity正确性修复；指导已核当前SDK318的629份payload与SHA/长度、607份根输入（含repository/LICENSE/NOTICE）、两份normal EXE身份、Rules归档CRC及四项测试原日志。源锁59075是write-source-lock外置生成，manifest mode=none，不能称预锁强制导出。Rules保存1000条独立全文件比较仅record1.label由“重复规则 1”变“重复规则 11”，两份正常运行回执exit0；mixed原始六次读回SHA一致、B除九处公共context元数据外全值不变，业务/自身版本保持0，846B工作会话的22B schema/377B正文及六字段长度已独立解码，保存前后原件相同。以[SDK318交付](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/wrapped-layout-reuse/correctness-product/README.md)作为这些已验范围的当前功能基线，旧可用交付保留。该接收不覆盖下述新交接缺陷。

原Rules视图PID69701仍是600秒超时/-15，滚动未观察到位移；PID90087是后续独立业务会话，不拼为一条连续正常退出链。键入为CGSession合成键对，不能称物理HID；脚本公共调用不称真实模型服务；业务会话保存不称生成UI定义持久化。性能80笔/16与32ms/p95、VO及旧证据缺失边界均保留。新用户报告是比继续盲目性能实验更直接的框架缺口：人和外部系统应能通过同一owner连续操作真实内容，并得到最终可用的视觉/选择状态。按设计导航共同窗口、owner交接、候选准备及shared_operation入口复用实施，不另造应用状态机。

**新原件与已核事实。** 用户本次只授权指导处理框架问题，不介入Pharos应用侧临时禁止写入方案。[外部原件](</Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/owner-handoff-loop-20261031/README.md>)及同目录run-wb4/run-wb5/sample保留只读。指导数得wb4交接id2绑定409次（transfer2..410），wb5绑定427次（2..428），均没有COMPLETE；wb5有SEAL after2、mirrorVersion2/1072B、14个fragment及新首段，而accepted仍24、pending=refresh_preparing_resources。turn540增长到16310，所以“单次owner回合永远不返回”尚不成立；日志本身也不含公共写响应/owner_busy原件，约200次/秒、请求未claim的具体原因不冒充指导已复算。确认的是持续重复候选/未结算异常，不能仅凭TextKit热点指认排版死循环。

冻结SDK位于同mature-package目录的sdk-efee91ba，窗口a5d70827、native a247caa4；当前窗口6a8ef2c9、native8fc8008c。两侧owner_handoff模块813d3f30相同，performTextOwnerSelectionChange、preparedCandidateBasisChangeReason、validateOwnerSelectionHandoff函数逐字相同；prepareCandidateSelection差异仅新增诊断，advancePreparedCandidate另有已验分包改变。因此没有证据可宣布当前已修，也不能把旧SDK日志直接认作当前normal复现。后续先在当前精确基线确认，不重开全部旧矩阵。

**主执行持续完成以下整包，无需逐补丁请示。** 仍由01a18297-1b22-7f63-ad2d-e49f066db253负责，实际使用已有gpt-6.1-terra及gpt-6-luna，按难度调整档位。主执行负责归因、实现和集成；Terra可承担交接/候选失效及生命周期的独立查证，Luna在方案明确后承担一个完整反例/受影响验证包。写集与构建串行，子代理只回主执行，无额外顾问或新聊天/监控。

1. **用原正常消费固定当前反例与具体失效条件。** 只读Pharos生产调用与实际构建源，在本线复用工作目录冻结必要应用输入，使用当前框架/SDK构建独立自有实例；不改Pharos项目、其target、冻结SDK、用户文件或现有实例。诊断直接写分支保持关闭。复用原1072B/14片段输入与正常公开REPLACE_RANGE，保真实请求响应、完整owner正文/版本/选择、候选/transfer/准备任务身份、失效原因及最终受理/终态。若当前不复现，以精确源差异定位已有修复或消费条件，完成正常连续链后交回，不能为凑修复改生产。只为归因补有界观测；不要再跑数分钟高CPU来积累相同日志。
2. **修真实归属，复用原推进协议。** 沿performTextOwnerSelectionChange→seal/bind→候选保留/失效→资源准备→安装receipt→complete及公共请求claim路径，区分真正新业务/源变化与自己准备完成造成的失效。检查request epoch、owner/selection/binding、resource completion与准备依赖，不能未经反例就删校验。正常等待应保有原候选、游标、输入和资源责任，由已有ready/worker或合法预算续进推动，避免每轮重新build和光栅化。仅在实际新状态时合法替换；不可恢复失败须具名结束并释放本次责任，不能永久占住owner、用固定重试次数掩盖根因，或伪造安装/完成。若涉及新通用调度机制，先按导航核GPUI/Slint等相关实现与测试，仅作思路参考。保原FIFO、版本、binding退休、owned校准、installed-source票据、关闭及FFI/worker生命周期。
3. **连续可用性和失败保护一并落实。** 正常视觉模式第一写完成后，同实例第二次合法REPLACE_RANGE、UNDO/REDO、人的原编辑器续写应继续生效，逐次独立读完整正文/版本/选择及对应accepted状态，不能用AX本地字符串或APPLIED=true替代。覆盖准备等待后恢复及明确失效/退休的生产反例；已发生的正文变更与尚未完成的呈现/交接分别记账，不能重复执行业务、隐式回滚或将已应用请求改称未应用。源模式原来直接owner_busy也不是绿对照，沿同一机制判断受影响范围。保另一owner和已准入操作，业务CPU/等待回落及最终正常保存关闭、端点清理要有原件。APPLIED、accepted和真实呈现分别报告，无法取得呈现时间不自动写成已呈现。
4. **回到可复用框架交付。** 先真实反例后最小修复，稳定后一次受影响normal连续消费；第二消费者优先复用range_text/shared_document的既有公共owner入口，只验本次交接边界，不重跑Rules/mixed全包或性能80笔。Pharos仅作冻结生产消费者；若发现应用违反明确契约，交精确调用/归属，不代改应用或将其绕过分支纳入产品。修改进入共同根或必要Mac窄桥，拒绝平台私有长期分叉。若需要导SDK，仅在源稳定后做一份功能候选，同字节正常消费后交付，源码/构建/链接/运行身份齐全；不原位修改旧SDK或给其他平台强制追更。完成真实修复、针对性回归、普通构建和正常消费后集中直接回本指导，不在归因报告、一个测试或一个子代理结束时停工。

**资源与收尾。** 沿AGENTS容量/验证价值规则和旧累计，不新增独立10GiB。为本次必要生产反例、修复源码、可复盘二进制及最终SDK，E累计留存上限调整为15.25GiB、峰16.5GiB，DS子范围留存2.75GiB、峰3.25GiB，临时工作上限2.25GiB（本包10月31日容量裁决，见下）；子范围不叠加且不清零14.4908/1.9840既有账。指导初次接续时宿主可用约189.54GiB；执行前及高写盘前重核实际峰值、不可复用项和退役点，宿主峰后≥20GiB。一个复用工作目录、唯一RED与必要当前/回退保真，不为最后数KiB反复压缩或猜删旧产物；不可变证据目录保持防覆盖。归档分析放窗口外，前台保护Pharos/其他线的自有与用户实例，准确清理本线实例/子进程/端点；锁屏只阻塞桌面，不循环开窗。无Git写，不改W/H/Linux，不恢复旧线。新实质跨模块问题按原规则集中升级；无新疑点不追加同义验证。

**同包临时容量裁决（2026-10-31，执行者升级后）。** 同意仅将临时上限由2GiB调至2.25GiB，即2,415,919,104B，增加256MiB；E/DS留存与峰值不变。继续以mature-package父目录P的原五parts口径核算，不改成其input-exit-performance子目录、不清零旧占用、不另加子代理额度。执行者本次报告临时2,133,344,256B（1.98683GiB）、E约14.71GiB、DS约2.21GiB，正常构建图完成态约153.5MiB；这些为执行账，指导本次独立df确认宿主197,003,048KiB可用，约187.88GiB。新额度只覆盖现有生产反例、共同修复的复用构建图、必要正常消费与最多一份稳定功能SDK；写盘前按实际同时占用估峰，正常回归后退役可再生图，保唯一RED与必要源码/二进制。此前2.027GiB越界及签名期cap-abort/计数不一致按原件保留，新上限不追溯改写它们。不再为原14MiB余额反复归档，也不要求再回同义容量确认。

本次是容量许可，不是功能验收。执行者报告SDK318/冻结Pharos正常连续链通过、同源旧efee重现重复绑定；原件保留，[当前证据](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/owner-handoff/README.md)与[第二消费者归因](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/owner-handoff/offline/range-undo-owner3-rootcause.md)中已区分新Range已写后Present33、真正Source UI的Begin32和旧循环。按当前可区分首因继续原包的最小修复：候选所持原A证明只用于对应就绪候选的严格授权，保全局BEGIN/focus及原身份拒绝；终态收尾不得回滚已写owner或丢掉原输入，ready不能替代B receipt/COMPLETE。源稳定后合并受影响正常验收，不重跑已有适用Pharos绿线；新差分影响到该消费者时才补对应接缝。最终集中交生产差分、真实反例/正常消费、未验边界与空间账，不停在诊断交付或启动主线外任务。

**执行交付（2026-10-31，owner-handoff）。** 根生产改动为Native0bf精确候选原A custody及Window8d0终态收尾，BEGIN等旧拒绝保留。单份预锁SDK4b332（630 payload／607输入）同字节normal Range键1→Undo→Redo→键2→close0、冻结Pharos外写×2／UndoRedo／续写／SAVE6全1085B／close0通过；201份应用源未改。旧Native33控制证实owner3保留、匹配restore具名结束并正常关闭。SourceUI BEGIN32独立未过，旧CPU不称新性能。五部2.01559GiB，E14.74113／DS2.23423，精确退役563851264B，host187.73GiB；图、进程与端点已清。实现与自验完成，指导审阅待收。[交付证据](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/owner-handoff/README.md)。

<a id="guidance-source-visual-continuity-20261031"></a>
## 同包接续：源码与视觉共享编辑、共同安装恢复（2026-10-31）

**本轮裁决。** SDK4b332及Native0bf／Window8d0限域接受。指导已核630份payload、607根输入、两份4hunk严格重放、生产拒绝反例、三份normal原日志、Range各版本全正文、Pharos六次公共读回及最终1085B磁盘正文、签名EXE与构建身份，详见上方交付证据的指导复核。已修复的是就绪候选持有原A时的合法交接与真实拒绝后的精确终态收尾；不能声称整个Mac完成或历史WB5只由本次两处改动造成。Source UI原件中的点击stale／BEGIN32发生在正文写入前，仍是原整包第3项的缺口，不再以交付完一个补丁作为停工点。W的T11d正常整值链已按范围收口，不再让它重复Tab矩阵；此前已交本线的共同恢复差分仍未落入4b332。

**推进能力与复用。** 依设计导航的共同窗口／输入、shared_text_document／workspace／file与共同操作入口，完成同一正文、版本和选择在源码／视觉表示中的连续操作，以及业务改版后原编辑器的合法安装恢复；复用既有owner、选择票据、候选与ready推进，不另造应用状态机、文本引擎或平台私有核心。冻结Pharos仅作既有生产消费者，Range作另一正常消费者；4b332成功及拒绝绿证按相同源身份复用。W已验证的差分用于共同根合流判断，不将Windows探针、编译或GUI任务转派Mac，也不要求其他平台等待或追包。

原主执行01a18297-1b22-7f63-ad2d-e49f066db253继续负责整包，实际使用既有gpt-6.1-terra与gpt-6-luna，思考档位按难度选择。Terra可查Source stale／BEGIN32的实际归属，Luna可独立完成W共同差分的适配分析和有区分力反例设计；涉及同一Window的写集由主执行集中集成，不能并写。子代理只回主执行，最终直接回本指导01a17207-04bc-76a2-90c3-99c8c5060423；无需用户搬运、同义确认或等待鸿蒙，无新聊天、顾问或监控。

1. **修源码视图的真实接续边界。** 从`owner-handoff/cases/sdk318-source-ui-installed-write/`已保留的正常Source107／resource1／kind10安装、单次点击kind33／120:120被判stale、唯一外写BEGIN32／change_called=false／v1不变出发。先核事件归属、当前源／选择版本、安装票据和BEGIN实际前置；沿已证明未变的路径复用旧RED，只有缺少决定性判别时才补一条有界正常诊断。区分合法点击未接回共同owner、合理的过时事件拒绝、工具前台／坐标条件和应用接线，不先放松BEGIN／focus／版本门，不用补点、重投、直接写或固定延时救绿。若归属框架，落最小共同修复并保真正过时／错owner／退休拒绝；若冻结应用违反明确契约，交具体调用与证据，不改用户Pharos项目或把应用绕过纳入产品，其他独立工作继续。
2. **完成已交W共同恢复的根合流。** 入口是W82的[安装门差分](<../../artifacts/windows-pharos-20261005/delivery/Pharos Windows W82 - sdk-17eec5e0/patches/common-source-install-gate-t11-to-t11b.patch>)及[T11b→T11c差分](<../../artifacts/windows-pharos-20261005/delivery/Pharos Windows W82 - sdk-17eec5e0/patches/cjgui-t11b-to-t11c.patch>)。核`composable_ui_window.cj`两处由InstalledRangeSupported改SourceRangeSupported的门，以及`text_session.cj`的`refreshMirrorForAcceptedScene`在acceptedVersion落后source时设置既有`selectionNeedsNativeRestore`的两分支。前两门在Mac按当前能力值应等价；镜像恢复逻辑并无OS限定，必须与本次owner-handoff／pending restore／版本和FIFO协同核对，不能据Windows绿证直接宣称Mac无影响。只吸收必要语义，若共同根已有更合适的等价路径就明确映射，不整文件覆盖8d0、盲套旧行号或新增第二套安装路径；不重放首键。最终共同根不留此机制的长期私有副本，精确回交适用条件及平台未验范围。
3. **汇合后做一次受影响正常连续链。** 目标是正常Source／Visual入口切换后，人和公开客户端仍操作同一owner，连续合法写／UndoRedo／原编辑器续写不丢首键、不重复业务，完整正文／版本／source选择及实际窗口反馈对应，最终保存／正常关闭。已有证据覆盖且未受改动影响的步骤不重跑；原Source失败若属于应用契约则明确限界，不假造正常链。W差分若影响共同文本镜像，补能区分“字节相同但source版本推进”与普通刷新恢复的原反例及必要正常消费；结合本次源码视图链验证，Range仅补实际受影响交接，不再跑Rules／mixed全包、三轮Tab、性能80笔或旧VO矩阵。所有等待有既有就绪／版本条件；工具失败与产品RED分开，不为收口延长时限、换路径或循环开窗。
4. **交唯一稳定功能候选及实际收益。** 先保反例、修复及针对性检查；源码稳定且确有产品变化才导一次共同候选，使用既有正常构建／运行驱动串行验收，记录实际源码／链接／签名运行身份。4b332作为当前已验基线保留，不原位覆盖，不部署到用户Pharos或改W/H/Linux源、target、前台和冻结包。归档必要原件、准确清理自有进程／端点和可再生图，集中回报修了什么、哪些正常操作已可用、何处仍未验或属应用，不停在归因稿、一个子代理或一次构建后。

资源继续沿本页既有五parts／E／DS口径与AGENTS容量、验证价值规则：E留存15.25／峰16.5GiB，DS子2.75／峰3.25，临时2.25GiB，宿主峰后至少20GiB；旧累计不清零、不新增10GiB额度。指导复核五部2,164,244,480B，临时尚余251,674,624B，新增产出前重核共存峰值；同一消费者复用一个构建目录，成功／失败／取消均按归属收尾，保护唯一RED与实际交付。无新代码疑点不重复核原件或补验证工程；不得为几KiB余量反复压缩或猜删历史产物。指导只负责此次文档裁决和关键审阅，生产实现仍归主执行。

**执行当前（2026-10-31，原主执行／既有Terra与Luna）。** Source隐藏宿主命中与合法选择回调后的真实安装恢复已修，W两Source能力门及镜像恢复标志已共同合流。根Nativeaca8／Window82a／text_sessionc605；唯一新SDK741e为630payload／607closure，仅三项生产输入变化，其他604及旧4b332交付不变。Native原几何RED／同fixture绿、焦点拒绝和35项FIFO／abort；Cj同字节会话RED／GREEN分别成立。同SDK normal Pharos的Source单击、同字节v1→2、切Visual／外写／UndoRedo／单键／SAVE6全1073B／close0，以及Range两键／UndoRedo全owner1..5／close0均完成；每步完整正文和真安装回执对应。方法截断、桌面介入及零输入旧几何检查器前缀保留，未重投或降低canonical逐段条件。图、进程和端点已清，空间沿原累计账；无用户部署、Git写或其他平台追更。实现自验和指导限域审阅完成，不扩称性能／VO／所有pending交错或Mac全部完成。[交付、原件与空间](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/owner-handoff/README.md#source-visual-continuation-20261031)。ACTIVE由指导维护。

**指导复核（2026-10-31）：** 接受本包的 Source／Visual 连续编辑与共同恢复增量。独立核630份SDK文件SHA／长度、607项根输入和三处差分；现有关闭／绑定／版本拒绝没有放宽。核实际normal链接来源、签名EXE及Range归档32成员；从原始公开READ_RANGE逐份重算Pharos v1..6完整正文，最终1073B与磁盘SHA6604f857一致，SAVE6／handoff COMPLETE／进程0成立；Range v1..5完整正文、安装回执与后续消费者完成记录按字段对应，最终12B、正常退出0。每键为一次CGSession合成事件，不称物理HID；Range不声明磁盘保存。Cj单位GREEN仍保其467输入和Window0b600身份，未贴为全部最终Window82a单测；最终正常链覆盖合流后的源。独立五部walk=2,244,100,096B，原E／DS累计口径及峰值不变，宿主核约192.39GiB，两个自有应用PID已退出。本指导只审源码和现有原件，未重建／跑GUI；本包不再追加同义确认、Tab／历史矩阵或低收益验证。保留边界不改称通过，后续阶段仍按框架整体能力取舍。

**2026-10-31正式接续：** 用户要求指导直接安排，不让主执行空等。SDK741e已验收范围继续复用；同一主执行按[普通交互响应与系统可用性整包](2026-10-31-macos-responsiveness-accessibility-package.md)接回普通负载性能、系统辅助功能及受影响消费，连续实施后直接回指导。新阶段明确复用入口、实际修复/验收、模型整块分工和原峰值内临时构建余量；不恢复旧线、已撤回实验或重复功能矩阵。本段不是另一次收口确认要求。
