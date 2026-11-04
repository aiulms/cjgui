# Mac 普通交互响应与系统可用性整包

2026-10-31，用户要求指导自行复核、返工或安排下一阶段，不让主执行空等。本文件即正式实施任务。主执行继续为 `01a18297-1b22-7f63-ad2d-e49f066db253`，集中交付或实质升级直接回指导 `01a17207-04bc-76a2-90c3-99c8c5060423`；不恢复旧 Sol/DS，不等待 Windows、鸿蒙，不创建新执行线程或监控。

## 交付目标与取舍

把已经能连续编辑的共同框架推进到普通应用响应成本可解释、主导浪费有实际改善、常用控件能通过系统辅助功能操作。包含必要旧问题与可复用运行能力，不能交一包新日志就停止；也不为了制造代码差异强改已满足目标的实现。

依据[首版范围](2026-09-26-framework-capability-roadmap.md#first-mature-version)、[完整性视角](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md#规划大阶段时的完整性视角)及[共同实现导航](DESIGN_INTENT_INDEX.md#shared-code-entrypoints)。组件/布局、主题、公共工作区、生成/混合接入已有交付；本阶段不从零建控件库或扩编辑器产品功能。SDK741e 的 Source/Visual、外部写入、历史恢复、续写/保存关闭已接受，原包无返工项，沿[复核](2026-10-29-macos-input-exit-performance-package.md#guidance-source-visual-continuity-20261031)复用，不再重复整套验收。

唯一起点为已接受 SDK741e / 根 Native `aca8ced9`、Window `82a0fc33`、text_session `c60584b0`。冻结包不原位改；实际变更落共同源和必要 Mac 桥。同源当前 Rules 为主消费者，Range/mixed/冻结 Pharos仅按改动影响选择一个补接，不能为每个优化重跑全部应用。业务 owner 和应用内容仍归应用，不用 Pharos 特例或新的应用状态机绕开框架。

## 一、完成有收益的普通交互性能改进

1. 先复用现有固定1000条 Rules、公开消费者和驱动。四类仍为 `filter/name/scroll/selection`，现有无变化、失败、超时和不关联原件保留。只读旧性能结果的结论和本次所需原件，不从头重放旧阶段。旧深层 wrapped-layout 复用已因一次同配置对照无收益撤回，不能再把该假设直接当优化方案；保留现有浅层复用、serializer/clip正确性及应用collection依赖修复。
2. 首个有限正常片段只回答当前主导成本在哪里：真实原生收件、实际writer生效、Cj构建/布局、preparation/跨线程等待、提交和drawable。复用当前身份、计时与有界诊断，实际目标、线程和有效跨度先对齐；缺字段只补最小必要观测。writer前后单调区间不是精确CPU指令时刻，不伪造 `BusinessOwnerRevisionProvider` 或用最近时间戳匹配。普通CPU/等待热点已可判断时直接实施，不再把完整新追踪协议作为所有工作的前置。
3. 按证据修主导的重复构建、无变化刷新、测量/光栅化/资源准备、无进度唤醒或等待。复用共同失效、候选、缓存与租约责任，保正文/版本、绑定、FIFO、旧画面和失败恢复。不能把工作挪出计时窗、限制正常输入或放松拒绝换数字；没证明收益的优化撤回，正确性修复可独立保留。通用机制方案不明时按设计导航局部查GPUI/Slint/Flutter等参考，只借鉴不引依赖。
4. 实际呈现沿现有 `addPresentedHandler`、原始 `presentedTime`、frame/drawable/lease身份查清。旧目标帧零值与其他帧有效均有原件；区分记录/转换、遮挡或未呈现、提交/生命周期问题。不把回调、GPU完成、后一帧时间或截图当本帧呈现。明确框架问题就修；系统/工具仍不可观测则保该指标未知，继续已能定位的实际改善，停止同义重采。
5. 修复汇合、关联方法有效后，再统一完成既定1000条/四类各20事件的最终口径：暖输入/选择原生接收→owner实际应用p95≤16ms、对应drawable实际呈现p95≤32ms为目标。保原动作定义与完整样本，区分setup、无变化、合并/拒绝、未关联/未呈现；attempted数量不等于通过数量。默认OFF正常成本与诊断ON成本分开，不能把ON数字贴成OFF。不在无关联前提下重复80事件；未达标须交真实改善及准确瓶颈/未验，不改门槛或缩负载刷绿。

已有入口：`runtime/cjgui/src/composable_ui_window.cj`、`composable_ui.cj`及相关布局/生成模块，`runtime/cjgui/native/cjgui_internal_renderer.m`的资源准备/调度/呈现路径，`runtime/cjgui/examples/rule_set_window_app/`。CodeGraph此次未覆盖所问Mac/Cj符号，返回了无关平台；按实际覆盖决定局部源码回退，不以图的0 affected证明无影响。

直接证据根记为 N：`runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/`。优先复用 `wrapped-layout-reuse/RESULT.md`、`cost-pair/DECISION.md`（在该子目录内）、`one-link-plan.md/json`、`b163-admission-and-collector-review.md`、`scroll-fixed-short-ready/RESULT.md`及现有解析器。旧consumer overlay/EXE仅按原身份参考，当前构建必须消费本次Root/冻结基底；不再追W包或已退役SDK。

## 二、接通常用控件的系统可用性

复用系统IME已通过范围、公共语义/焦点投影、现有可访问性说明和正常应用，不重跑拼音全矩阵。Luna负责完整的系统通道判别、常用控件消费及明确修复子包；同一native/Window源码由主执行统一集成，不能与性能任务并写。

旧VO正控在 `artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/package-vo-system-control-20261029/RESULT.md`：引擎运行、字幕偏好、普通Space成功，均没有证明VO读出/光标/动作。先按本机实际工具/系统文档确定与旧失败不同且可观测的投递/读出方法；没有实质方法变化不再反复启停。只做一次有意义的系统原生控件正控，通后直接验证CJGUI文本字段、按钮/开关、列表选择和弹层返回的实际读出/状态/操作。发现role/value/state/focus或动作路由缺陷就在共同投影/窄桥归属修复，并确认业务状态真实变化；AX查询或AX写值救绿不能代替系统辅助功能操作。

若正控仍受具体工具/系统通道阻断，保准确失败和原设置恢复，不猜改框架、不增权限绕过；只暂停依赖该通道的门。Luna转入已明确的性能消费者、完整owner/保存/退出与资源验证子包，主执行继续实际性能实现。真实VO门未过就不称首版系统可用性全通过。

## 三、团队执行与一次集中交付

必须复用并实际使用既有 `gpt-6.1-terra` 和 `gpt-6-luna`，思考档位按难度调整。Terra负责性能归因、通用实现与高风险审查；Luna承担上述完整可独立工作块。主执行负责方案取舍、重叠写集、串行target/前台与最终集成。避免逐符号/逐探针反复委派；一块任务给清楚完成条件后连续推进，子代理只回父线程。普通编译、路径和工具问题自行处理，只有实际安全/架构冲突或持续低收益阻塞集中升级指导；升级不阻止独立项继续。

构建、目标确认、脚本与采集准备放在启动GUI之前，分析和归档尽量放正常退出后。沿现有runner一次明确正常消费；不再让工具整理耗尽应用期限，不对过期对象重试或启动第四个同义失败实例。保护用户和归属不明实例；用户接手电脑就停前台、继续离线工作，恢复不新增人为审批。

汇合后仅补受影响的连续正常链：完整owner正文/版本、实际可见反馈、保存和正常退出；有输入路径变更才补SDK741e已通过链的受影响衔接，不能全套重跑。资源沿已有固定循环和租约证据；改变资源责任时只回归相应周期，不另开长时间soak。源码/构建/运行身份、拒绝反例、默认OFF与ON成本、有效/无效样本及资源账集中提交一个候选。达到条件则交可复用能力和收益；未达到则准确报剩余与根因，不把未验改名完成。无需逐项停工或回传同义确认。

## 容量与保护

沿[AGENTS容量规则](../../AGENTS.md#artifact-space-budget)和原累计口径。已核五部约2.08998GiB，E约14.81551GiB、DS子范围约2.30873GiB；此时宿主约191.28GiB，开工/大写盘前再核。E最终留存≤15.25GiB、峰≤16.5GiB；DS子范围最终≤2.75GiB、峰≤3.25GiB，DS仍包含在E内。旧占用不能清零或另加10GiB。

本次仅将同一五部工作集合临时上限由2.25GiB调整为3.0GiB，允许复用工作目录容纳必要构建、正常App和归档同时存在；上述总峰值/最终留存不变，取实际最严边界。新增临时余量用于一个可复用构建图及本次必要材料，成功/失败/取消均按原runner finally退役；不长期保留第三套整包。默认只留当前和最近可用交付、唯一RED及必要可复盘原件；不为几十MiB余量反复压缩、复制和复跑。日志沿64MiB单文件/512MiB当轮限额并同时服从更小实际余额，宿主峰后≥20GiB。

不修改W/H/Linux冻结源/包/target，不恢复旧线，不占其他执行者桌面；无Git写、外部顾问、新监控或用户线程。本阶段已有充分授权，直接开始整包，最终回指导。

**执行当前（2026-10-31）** Root复用Terra/Luna，32e/锁c6a9字段caret修复已保RED→GREEN及同源完整owner/UTF16/1000保存、Apply4、UI原SHA、close0/端点空；3生产+1测试改动，其他603输入同741e。按裁决完成同32e B(去heavy phase)及C(再去app成本采集)，实际环境与全3条writer→drawable链均核，C总54.895/51.731/51.138ms仍为关联ON、非OFF/p95；写后约43ms未消失。一次3s系统sample只得聚合责任栈，未证明可删重复工作，未采用性能补丁；时间轴xctrace不可用。实质低收益/安全边界已集中交指导，停止本路线再采或80。Luna当前OFF单页仍未到record2，不当生产RED，完整原字节/正常0成立；VO只自身门留阻。原件N/responsiveness-accessibility/integration/postwriter-causal-boundary-review.md及analysis报告。精确App/native已归档，约260MB唯一图暂留；原累计/峰cap不变，整包未完成。

<a id="guidance-name-cost-decision-20261031"></a>
### 本次性能升级裁决（2026-10-31）

依据 `responsiveness-accessibility/integration/performance-decision-review.md`、`performance/name-profile-current-source-raw5/case-data/PHASE-SUMMARY.md` 与同目录原件。指导核四个输入文件SHA/长度和raw5的实际writer、scene39/frame45/drawable44/layer32027426368关联。一次ON总66.508959ms可分为raw→writer末端16.709625ms、writer末端→batch-tail0.044375ms、tail→accepted27.925041ms、accepted→实际present21.829918ms。这是同一链的互斥墙钟区间，不与嵌套CPU相加；writer本身仅约1µs计时精度，首个owner记录及空pump不能证明实际入队时刻或丢唤醒。未证明暖状态，不能据此判暖p95失败，也不能漏掉writer后的49.799334ms。

1. **先复用现有观测，不为观测先重编或新建协议。** 已核当前Native的 `CJGUI_EARLY_KEY_TRACE=1` / `CJGUI_EARLY_KEY_FILTER=18`：同NSEvent关联identity、userdata与单调时钟，含window_receive/window_return、context_before/after、should_change/insert_text，512条上限，485b已含此能力。主执行随后报告Luna正在修Rules字段选择投影，认可其先合流再沿唯一构建图构建一个正常消费者；不先单跑485b再重复。该最终同一候选只做一次预先声明的首笔及后续两笔原始名称编辑对照；每个动作只投递一次，先写预期完整owner/版本，保留首笔、失败和慢样本。不能为得到暖绿而重投、补点、延时重试；后续笔以真实完成前一笔为序，未能证明已暖就保持未知。旧66.5ms不能贴成变更后源码同条件收益；系统sample和另一套Native队列插桩不并行追加。
2. 以已有原件一并拆解后段preparation、提交和actual drawable，互斥墙钟与CPU分开。既有EARLY只能给实际调用边界，不能直接改名为FIFO发布；`OWNER_WAIT`无raw，不按最近时间硬配。先沿同步调用路径确认能证明的上下界；仅在这一次明确指出具体发布点仍是唯一决定性缺口时，允许主执行在既有默认OFF观测门内补极小、有限记录，沿原构建图完成一次受影响片段，不扩ABI/协议/状态机、不在持锁路径写日志、不循环加点。无证据不调整8/16ms预算或唤醒。
3. 证据表明冷初始化/系统文本回调成本时，保冷首笔、不要伪造框架优化；若真实发布已早而消费晚，针对已证等待/通知责任修；若暖样本主要消耗在tail/preparation/呈现，优先修后段，不回到413µs lookup或旧深cache猜改。根因成立就连续完成最小修复、同条件对照与受影响正常消费，不逐补丁请示。该有界方法仍无判别力就停止同路线采集，保具体缺口，不继续开第三套观测或无关联80事件。
4. VO仅该通道留阻。Luna优先连续完成已报告的Rules域字段选择投影修复：活动label的7:7不能借给UTF16长度更短的retentionCount/excludedType/notes；复用共同投影契约，保活动字段选择及owner身份，原件RED与针对性反例自验后与Name片段同候选合流。指导此处认可归属和执行安排，不代替最终差分/原件复核。实际列表滚动和第二行选择缺口只做必要真实目标/viewport/owner核对，不另开整套控件矩阵；输入没到目标不能当生产RED。已绿的完整owner、开关/取消、帮助和保存关闭复用，最终合并一次受影响链。重叠源、前台和target由主执行串行；原模型/空间/平台保护不变，整包继续，交付或实质升级直接回指导。

<a id="guidance-observer-cost-decision-20261031"></a>
### 三笔升级后的取舍：先排重型观测成本

本段接续上段，优先于再采后两笔完整CPU或追加enqueue观测。依据 `N/responsiveness-accessibility/integration/name-three-decision-review.md` 及 `performance/name-first-and-following-analysis/`。指导核四份输入文件SHA/长度一致；32e/锁c6a9的三条实际writer→accepted→同drawable链及67.379/58.367/57.150ms成立，仍是诊断ON，不是暖p95。字段投影的源234b/测试860f/差分de55和真实RED、最终GREEN原件已核，源/TDD范围接受；不为此重验旧完整链。

**决定性混淆尚未排除。** Native `CjguiOwnerFormattedProjectionEnabled` 的LIGHT只关闭格式化投影；`CjguiOwnerTraceAppendAtWithOwnerIdentity` 对非覆盖时间戳记录仍调用 `CjguiOwnerTraceThreadCpu`，含 `mach_thread_self/thread_info/mach_port_deallocate`。首笔5074条唯一记录中2457条cpu_valid=1；仅tail→accepted的25.549542ms内即4750条/2338条有效CPU记录。不能将它们的CPU直接扣成准确观测税，也不能尚未对照就认定生产路径有同量耗时。已有frame60在617580040156792ns呈现，frame61于617580170568458ns才排入，至少此处不支持先前帧积压；present_flags=6不含事务位。GPUI本地Metal正常分支也沿presentDrawable后commit，只作机制参照，不据此断言系统原因或调整drawable数量。

1. **同二进制、无新观测协议，做一次明确的配置对照。** 保留完整三笔A原件；复用32e及同1000负载/布局/三笔预声明输入，B只关闭重型owner-phase体系（彻底移除PHASE及其target/watch/sample配置，离线确认没有环境继承），保留既有INPUT_LINK、真实writer和cadence关联，其他实际输入/正文/退出判据不变。无需重编、重跑A或加系统sample。先离线核时钟/dispatch/accepted关联独立于PHASE；已有window trace使用无条件owner_clock_ns、业务clock为mach_absolute_time。若分析器依赖重型CPU表，保其原判据，用准确的低观测模式解释缺项，不能伪造CPU或松业务断言。B仍是“关闭重型owner观测的诊断ON”，不是默认OFF。对比只回答观测敏感性，不称生产优化收益。
2. 若大部分额外耗时随该体系消失，停止追它制造的热点；以后性能终验使用足够关联的低观测路径，默认OFF另保业务/资源消费，重型CPU只按已明确问题使用。若内部postwriter仍慢，先用已完整保留的首笔dispatch-submit/main-enter/main-exit/owner-return及4750条分类，定位tail→candidate9.84ms、candidate→first-unit4.89ms中的实际工作与等待，再由Terra连续完成有因果依据的局部修复与同条件对照。后两笔全量CPU、每键font/cache-hit不再成为所有工作的前置。不能把余量全叫等待，不猜调8/16ms预算、drawable数、vsync或旧缓存。
3. 暖输入终验用事前定义的业务稳态/预热过程，保初态与首笔，不能要求所有动态新文本每键缓存命中，也不能反复预热到过线。正式四类20只在关联有效且修复/无需修复结论成立后集中执行，低观测与默认OFF分开；未达16/32ms保持未达，不降目标。GPU→present约23ms单独保留；没有框架持有/延迟提交证据时不扩成显示系统研究。本次B若仍不能选修复，主执行在本包内选择最有区分力的一项现有profile/源责任方案并落实，普通局部归因不逐条请批；出现实质架构/正确性风险或同路低收益阻塞再集中升级，不重复请求下一轮泛化采集。
4. 字段修复、实际列表viewport/第二owner与最终必要正常消费继续，前台串行。指导不要求另起整套OFF或SDK741e矩阵，也不把局部GREEN当包完成。复用Terra/Luna与唯一图，原空间/平台/无Git规则不变；集中交付源差分、实际收益、未验和资源账。

<a id="guidance-performance-route-boundary-20261031"></a>
### B/C/D后的阶段边界与直接接续

依据 `N/responsiveness-accessibility/integration/postwriter-causal-boundary-review.md`。指导核B/C/D六份app/cadence原件SHA/长度、各三条完整实际链及manager exit0/无forced/端点清空。B移除重型owner观测、C再移除应用cost收集后，后续笔仍约23ms tail→accepted与约20ms accepted→present；重型观测不足以解释主要剩余跨度。一次系统sample无逐raw时间轴，其影响的约215ms不能当生产回归。没有可安全采用的性能优化，不删必要逐slot身份/版本检查来凑收益。

**指导决定停止本性能采集路线，原目标保持未完成并后置。** 不再追加profile/新trace、80事件或为此新装工具；16/32ms、有效四类20和VO实际消费都不标通过。字段投影源/TDD及相应正常消费、当前32e精确App/native档案是本包实际交付；不据此将本包原完整目标或整个Mac标完成。原严格分析器对manager关闭字段的覆盖不足仍保留，normal0/端点与业务关闭证据分别按原件表述。

2026-11-01直接接续[集合视口接入与连续导航整包](2026-11-01-macos-collection-viewport-navigation-package.md)。已核公共变高/固定列表工厂没有显式viewport接入，而共享布局、revealKey和window.revealVirtualListItem已实现；补公共接入与真实人/外部连续消费，不另造滚动引擎。GET_WINDOW_TARGETS是窗口枚举，其拒绝不是列表节点缺失证据；原page目标未达保留，下一包先核实际命中/顺序/绑定。原性能/VO缺口留在本页，不作为新阶段开工门槛，不要求用户再次转述或逐项批准。
