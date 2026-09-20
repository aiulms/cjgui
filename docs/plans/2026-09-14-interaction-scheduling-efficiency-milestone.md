# 大阶段：高频交互的局部刷新与跨窗口公平调度

指导授权原任务 Terra/xhigh 协调 Luna/high，在原目录交付完整阶段，不提交推送。当前阶段入口维护在 ACTIVE_DIRECTION.md。

## 交付目的与取舍

用户快速移动鼠标、点击或用键盘操作时，状态反馈及时且动作正确；同时另一个窗口和外部已授权修改仍能推进。一次控件换色不应无端承担整窗构建、测量和资源准备。目标是通用框架交互效率与可靠性，不是给样例增加按钮，也不从8ms pump推断模型无关的输入到呈现时延。

复用 [交互样式阶段](2026-09-14-interaction-styles-themes-milestone.md)、[动态组件](2026-09-14-dynamic-component-composition-milestone.md)、[复杂场景性能](2026-09-14-complex-scene-update-performance-milestone.md)、[矢量提交效率](2026-09-14-vector-submission-efficiency-milestone.md) 的 accepted scene、身份、唯一布局、候选事务、缓存和正常 application 调度，不创建新业务状态机/输入runtime/主题系统。按 [设计意图导航](DESIGN_INTENT_INDEX.md) 和避坑原文的无谓重绘、事件重入/生命周期、单一状态归属来取舍。

六主线：本轮主攻交互调度和自绘提交成本，组件/文字/资源保持已有能力，语义动作和正常开发者消费作为必须贯通的路径。输入法仍只集成系统，不扩跨平台、动画或富文本。当前已有功能不少，优先让这些功能组合使用时可靠且省工作；没有证据的极限优化不强做。

## 承接结论和剩余任务

指导只读接受上一轮基础状态、按压换绑矩阵、主题像素及选区/焦点/滚动连续性的已验结果；mMBxly正式导出ui/window/host/session/native m/h六项与工作区一致。106根因按动态菜单候选声明修复，执行报告controller通过；最终原始PASS日志入口需在本阶段注明，不因旧同名日志停在上一轮而重跑整个矩阵。

完整桌面同A接续因锁屏尚未完成；旧pointer_public_interleaving检验的是连续拖动capture，不等同新hover/press/terminal事件混合公平性。上一轮90条paint样本只证明build/layout/measurement为0、两节点native更新，仓颉当前仍遍历scene合成/比较样式，native可能仍有整场景工作，不能声称整体O(1)。这些依赖自然并入本阶段，不把上一轮全部重做。

## 完整实施范围

1. **按实际事件分析成本并优化。** 在现有正常application入口准备小/中/接近已支持上限的场景，记录单调时钟下入队、仓颉解析/合成比较、native staging/submit及可解释的等待。复用既有计数，必要时添加关闭默认输出的内部观测。每档至少30次有效变化，预热、样本和正确性检查分离，保留原始对照。按实测热点优化：优先避免无变化输入全场景扫描/分配，按实际脏目标合成paint并复用已接受索引/布局；批量事件同轮合并绘制，不合并掉必须执行的动作。若主要耗时是既有等待而非CPU，就先明确等待/批次策略，不为“局部”口号增加昂贵缓存。正式方案由Terra根据实证确定；性能目标不能靠改为不声明耗时收口。
2. **明确事件次序与存续规则。** 连续移动可合并中间视觉状态，down/up/cancel、键盘/AX激活和owner动作不可丢失或重复。同目标rebind/禁用/删除/模态后的旧release不能误触新对象；无关B写入和纯paint不破坏合法A。重点核查当前 pressedInteractionNode 在 reconcileInteractionProjection 中被清空、PRESS_END之后通过 suppressedPressActivationNode拒绝generic action的衔接：若两事件跨pump预算、交互paint夹在外部换绑与release之间、事件拒绝/队列压力或之后AX激活，是否可能丢失取消依据或误吞独立动作。先复现区分，源码疑点不是已确认失败；无需穷举无关组合。复用现有目标身份/代际与事务；不要每次scene变化都取消，也不要保留无界历史快照。
3. **混合负载与公平推进。** 在同一正常application的A/B窗口里运行实际hover/press事件与真实公开socket调用。A连续跨控件hover/点击，B输入或公开写入须在有限调度回合内处理；A最终状态/动作数量与读回正确，队列和待处理工作有界，停止输入后idle无持续重绘。不用两个独立进程代替，不用旧drag-only probe代替。覆盖受预算分割的terminal序列和失败候选/健康重试，保留计时与正确性原始结果。只在真实证据需要时调整调度预算/合并策略，不新增忙轮询或固定60/120Hz空转。
4. **已有公开能力的共同消费。** 两个既有正常应用继续采用公开主题/状态样式；在真实可用的owner入口验证外部改变selected/checked/enabled中适用字段后的反馈，不造直写UI后门。至少一次同A窗口输入→外部读A/改A→可见反馈→再输入A和读回。桌面锁屏则将该项保留为未验，先完成相同入口的受控/公开调用，解锁后再补；不改锁屏设置，不索取密码。主题的正文/选区/焦点保持沿用上轮证据，只有受改动影响才复测。
5. **缓存与开发者消费收尾。** 局部paint不重建不相关文本/图片/矢量buffer，缓存/索引仅随accepted candidate晋升，拒绝与关闭有明确释放。现有图形热态缓存、布局与文字只跑受影响回归；必要runtime build、FFI/声明/差异检查按AGENTS完成。同target构建串行，最后源码完成后一次含空格正式导出，实际公共消费者运行本轮路径。保留源码/产物指纹与原始运行日志，旧对照不覆盖；工作区源码、受控运行、公开脚本、桌面自动化、真实模型、物理呈现、发布分开表述。

## 分工与阶段交付

Terra/xhigh负责事件生命周期、实际热点判断和优化方案及关键审阅；Luna/high执行完整且明确的观测/混合消费者/验证包或已确定的实现方案，默认一个，复用已有代理，写集明确且构建串行。Luna报告实际父代理，Terra汇总后通知指导，不逐个测试回报或另开定时任务。没有独立工作时等待完成通知，不为运行状态重复读码。

整阶段交付必须给出旧项处理、新框架行为、同条件成本前后、另一窗口推进、失败恢复、真实公开消费和仍需桌面的确切事项；不修一个边界就停。3次有效修复失败按现行AGENTS升级指导给方案，不调用K3。独立任务继续推进；原目录，不stage/commit/push，不切分支/建worktree，自有实例整轮复用并在任务结束统一退出。完成即报告指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61` 以安排下一阶段。


## 2026-09-17 恢复执行补充

用户明确恢复原任务及30分钟指导定时。暂停前最终报告表明当前阶段未完成：旧按压重绑已修复验证，新双窗口效率probe连续idle后两窗提前退役，旧双窗口UDS对照仍通过，尚未做新正式导出。先保存并核对暂停前证据与源码指纹，不能把现存mMBxly说成新源码产物。

Terra先比较新旧probe的application/host/window/connection持有关系、等待循环和退出判断；区分正常close意图、错误状态导致的退役、session销毁与测试自身构造问题。定位第一个关闭/丢弃调用点及其触发条件，再沿根因修复；队列堆积可能是窗口先退役的后果，不先盲目扩大队列或加sleep。修复验证须包括idle存活、A/B分别操作、关A后B继续、正常退出及session收敛，不放宽失败/关闭守卫。

Luna/high并行只承担写集独立的测量/正常消费者与明确验证包，同cjpm target仍串行。960控件解析0.17–0.20ms、比较0.004–0.006ms而约6ms在原生提交段的现有结果先读原始记录，再拆分CPU编码、drawable/限流等待等实际边界，不能把等待误当GPU耗时或优先优化仅0.2ms的仓颉遍历。独立性能工作无需等生命周期全部解决；依赖真实双窗的公平性验收须等其正确。继续原阶段完整交付、锁屏欠项和最终公共导出，不修一个问题就停、不启动K3、不擅自提交推送。三次有效失败累计升级指导，不从本次恢复清零。

## 2026-09-17 执行交付

- **生命周期复现结论：** 新效率 probe 的“idle 后两窗退役”不是 scheduler 关闭了健康窗口。验证脚本在命令替换子 shell 中 `wait` 非子进程而返回 127，probe 又直接 `window.close()`，没有向 application 归档窗口。改为由父 shell 等待，并由 application 请求关闭；不加 sleep、不扩大队列。三档均验证 A/B idle 存活，关 A 后 B 仍开着、A 的 session 已关，最终正常收敛。
- **终结事件与失败候选：** press 快照跨一次局部 paint 保留；若 release 前同一目标已换绑，则抑制旧 release 的 generic action，不影响无关 B 写入或独立 A 激活。受控 native `interaction_paint` 失败现在保留 `pendingRefreshReason` 和既有 accepted scene，显式 `refresh()` 后才恢复，不忙轮询。RED 日志为 `/private/tmp/cjgui-interaction-scheduling-press-trace-red.driver.log`；当前 90 条真实 UDS 验收在 `/private/tmp/cjgui-interaction-scheduling-efficiency-green-6.driver.log`，其中受控失败提交数保持 `62`，重试后为 `63`。
- **顺序交错与历史 90 样本：** `verify_interaction_scheduling_efficiency.sh` 的 full mode 以普通 `CjguiMacosApplication` A/B 窗口运行 8/128/960 节点各 30 条真实 UDS 样本；每档有 terminal rebind 抑制、无关 B 激活、A close 后 B 存活、失败候选恢复和 idle 无提交。它保留为顺序交错/生命周期证据，不能单独证明高负载重叠公平性。
- **成本边界：** 原先 `stage_submit` 的余项不再称为 drawable wait。测试专用窄观测已直接覆盖 `nextDrawable`、既有 encoder CPU、`presentDrawable`、`commit` 调用和仅在读回时的 `waitUntilCompleted`：960 节点、90 个无逐帧 readback 热态样本的 `nextDrawable` p50/p95 为 `5.062/6.125ms`，encoder 为 `291/333us`，present/commit 调用和 readback wait 均为 `0`；原始日志为 `/private/tmp/cjgui-interaction-scheduling-native-cost-green-present-timing.driver.log`。锁屏时独立重测为 `5.667/6.084ms` 与 `250/292us`，原始日志为 `/private/tmp/cjgui-interaction-scheduling-native-cost-locked.driver.log`。这些仍不是 GPU completed、物理呈现或端到端输入延迟；没有安全的 CPU 热点可改，未改变同步/节流，并已把这一取舍提交指导决定。
- **正式公共消费：** 最终 `verify_framework_preview_consumption.sh` 已在含空格隔离路径从最新导出副本构建并运行六个公共消费者；外部 vector 写入/投影读回、图片 A 关闭后 B ready、菜单和文档 consumer 都通过。`/private/tmp/cjgui-interaction-scheduling-preview-final.driver.log` 的 source/preview payload 均为 `eebdb44bfe1c3afe67e15c12cfd94e8800b0dc12d917c5a36f6ef9c36bc54c86`，证据根为 `/private/tmp/cjgui-framework-preview-consumption.QChXnf`。
- **仍未验：** 本轮未把受控 AppKit/UDS 输入冒充人工桌面操作；同 A 窗口的人类可见输入→外写→再输入、物理键盘、IME/VoiceOver、GPU completed、实际呈现与安装/公证/发布仍为 `not_run`。测试驱动以 50ms/1ms 就绪屏障等待外部进程；生产调度没有固定 sleep、忙轮询或空转。


## 2026-09-17 指导复核：接受修复，继续完整阶段

指导只读核对效率driver的三档通过与summary、native-cost原始计时代码，以及l0P234导出的ui/window/host/session/native m/h六项逐字节与工作区一致。接受父shell wait、application.requestClose、press快照和失败候选恢复的对应修复与受控交错证据；**不接受当前报告将完整高频公平性与性能阶段宣布完成**。具体差距如下，不重跑已通过的旧矩阵来替代：

- `interaction_scheduling_efficiency_probe.cj` 的B generic event先enqueue并pump完，之后才启动A down/paint/public-write/up。`generic_split`证明了B独立动作可执行，不是PRESS_END与generic activation被预算切到不同轮，也不是A繁忙期间B输入竞争。90条样本的公开调用有效，但该时间安排不能证明持续高频公平性。保留这个顺序交错用例，另接真实重叠场景：在同一application中让A的hover/press待处理持续跨多个turn，期间入队B普通输入并发起真实UDS写入，记录B入队至实际owner执行的回合/时间、A最终动作与取消数、队列峰值及停载idle。至少一个确定性场景要使终结状态与实际动作跨pump边界，若生产一次drain不可分则明确其原子保证及压力/拒绝边界，不把B先执行命名成terminal split。
- `interaction_scheduling_native_cost_probe.cj` 的 `residualNs = stageSubmit - (configure + set + commit)` 是尚未细分的余项，仍含原生绘制与其他工作，不能直接说已测出drawable wait或GPU耗时。在真实 `nextDrawable` 前后、现有encoder CPU区间、present/commit和测试读回wait路径做窄范围直接计时，保留正常无逐帧readback的热态输入基线与锁屏/后台状态。计时分辨率和观测开销如实说明；不关闭同步/节流来伪造更低延迟，不直接删必要等待。
- 依据直接测量给出至少一个有证据支持的提交/调度改进并同条件比较；如果证据显示时间来自必要平台节奏且无安全收益，带源码与测量给指导做明确取舍，不能自行靠“不作加速声明”代替原定目标。复用既有renderer与候选事务，不造另一个渲染线程/状态owner。
- 正常同A窗口→公开外写→窗口接手仍未验；当前电脑是否可用由执行检查，不继承两天前锁屏结论。可用时在本阶段一起完成，不可用则记录实际原因并先做上述无桌面依赖的工作。必要构建/消费者验证以最终源码为准，已有正式导出保留，只有新生产修改影响才再做最终一次导出。

Terra负责跨层计时与调度取舍，Luna负责明确的重叠负载/验证完整包，父子写集和同target构建协调。旧90样本与顺序交错修复保留，不能覆盖成新基线。脚本的50ms就绪轮询属于测试驱动等待，和“没加sleep掩盖生产生命周期”区分，不再声称脚本完全无sleep。修复一个断言后继续整个阶段；完整交付或重大阻塞再汇总给指导。

## 2026-09-17 补充执行：真实重叠与直接计时

- **真实重叠公平性通过：** 当前源码的 focused mode 在同一 normal application 中先完成 A 的 down 回合，再一次性填满 64 项 A hover FIFO；B 普通输入与一笔真实、版本化的 UDS `SET_PREVIEW_LIMIT(B)` 在后续 owner 回合抵达。`/private/tmp/cjgui-interaction-scheduling-overlap-green-7.driver.log` 的原始结果为：第一个 external owner 回合 `1`、wait 前 `3ms`（测试服务界 `64ms`）、UDS `APPLIED true`、B ordinary delta `1`、B owner version delta `1`、A normal action delta `1`、A pending/high-water 都是 `64`、第 65 项被拒，ACK 后 A 关闭而 B 仍存活。A 的一次 drain 对 64 项 FIFO 是原子边界；probe 明确记录此边界，不把它说成可抢占。此前的 8 请求测试因手写整数协议编码错误先得到 `invalid_parameters`，修正后又暴露客户端自身超时，均不计为生产 RED 或绿色结论；最终用完整的一笔真实写完成本项。
- **当前桌面状态：** 直接 App/AX 访问返回 macOS 已锁定且不能自动解锁；完整 90 条 current-source rerun 也在旧顺序样本第 23 条因 socket 提前关闭中止。一次有界日志定位在 `/private/tmp/cjgui-interaction-scheduling-overlap-green-5` 只发现前两个 scale 的预期 `close requested: probe`/destroy，sample 23 之后没有主动 close、native error、exception 或 timeout 记录，client 仅报“connection closed before a complete response frame”；故不归因为锁屏或生产回归，也不重复全量运行。因此旧 90 条绿色只保留为历史顺序交错证据，当前 focused overlap 是本轮绿色；桌面同 A 可见输入→外写→再输入仍为 `not_run`，未改锁屏设置、未触碰用户实例。
- **锁屏计时日志完整性：** `/private/tmp/cjgui-interaction-scheduling-native-cost-locked.driver.log` 用 `2>&1` 合并 stdout 与 AppKit stderr；其 960/sample 20 的 stdout 行被一条 frame metadata stderr 日志切开。验证器实际解析并保留的 stdout 文件 `/private/tmp/cjgui-interaction-scheduling-native-cost-locked/result` 中该行完整，含 `native_readback_wait_us=0 native_readback_waited=0`；90 条样本和 summary 都通过。因此保留合并 driver 作原始诊断，但以 `result` 作为标量样本的完整记录，不补造或重跑数据。


### 指导对直接计时结果的决策

指导只读核对green-present-timing/locked两份driver与直接计时代码，重算各30条960节点样本：nextDrawable p50/p95分别5.0625/6.125ms、5.667/6.084ms，encoder CPU分别291/333us、250/292us。前一组逐样本readback wait均为0；锁屏组报告热态无readback等待，但逐样本有字段缺失，原始记录完整性需执行说明。l0P234对照显示ui/window/host/session生产仓颉源码未变，native新增测试计时。指导接受本阶段保留生产提交/同步策略：当前主要被测耗时在nextDrawable，不通过关闭节流、删同步、增加渲染线程或小CPU改动制造加速。这不是性能极限或未来无优化空间的结论，不宣称本轮整体加速。

接受overlap-green-7证明的一次有界积压：A已有64条hover待处理时B普通输入和真实UDS到达，首个external回合1、pre-wait3ms，B动作/owner版本各+1，A释放动作+1，第65条拒绝，关A后B存活。这是受控原子drain边界的重叠证据，不扩大为无限持续压力或物理呈现延迟。

当前完整90轮重跑第23条连接关闭，须保留原始路径和最终状态，归因仍待证据；同时锁屏不等于锁屏为根因，不能宣称当前90轮绿或确认生产回归。执行只做一次有界日志定位，区分主动关闭/原生错误/测试超时，不在相同锁屏条件下反复全量重跑；历史90绿、当前focused绿、当前完整运行中断分别记录。正式导出进行收尾后汇总，正常同A桌面接续仍待可用环境完成。此决策不再要求新增CPU优化，也不抹除未验事项。


### 指导最终收尾与接续

已读QChXnf最终日志并核对六项关键源码与当前一致。locked/result sample20完整，readback_wait_us=0/readback_waited=0，合并stderr造成的缺字段解释成立。按上述受控范围接受修复、观测与保留提交策略的决策；不宣布current完整90轮或正常同A桌面接续通过。导出实际UI/document仅build，其他入口按日志的运行范围记录，不能笼统称六消费者均运行。连接关闭未定位与可见接续在[通用数据交换阶段](2026-09-17-data-transfer-milestone.md)承接，结束此轮小边界追测，继续新增通用框架能力。
