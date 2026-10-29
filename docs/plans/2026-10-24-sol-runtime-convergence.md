# Sol 整阶段接续：停止无效热回合，收好窗口返回与普通成本

日期：2026-10-24；当前接续更新2026-10-28。本文承接[原四部分施工图](2026-10-24-sol-runtime-continuation.md)。**当前执行以[§9.12 普通应用连续交互与性能](#sol-first-mature-runtime-20261028)为准，§9.11已收口；第8节及旧段仅保留当时交接与证据，不自动重启。** 执行线程仍为`01a16db2-14c6-7540-bf23-0048536bc8cd`，旧线程`01a16991-4c71-7cf3-9a00-784ec59b4843`保持归档。不fork或重放旧线程全部历史，不重做已验工作。

## 1. 已接受事实与本次要改变的结果

七个本地准备让出点登记 `needsReadyContinuation()` 的生产修复保留，window `a528090711c67e7839e9941c496d39ddded13da166066b7748b5314eaa8eb55d` 已进入 DS49 SDK，指导核根树/SDK 相同，不重复交接或回滚。最终同进程 5 项、Rules 即时拒绝/外改/续写/保存退出，以及 Mixed 已验的双窗部分链保留。

本次集中完成三类实际结果：没有可推进工作时宿主能真正等待；普通窗口返回/恢复后输入身份清楚且行为正确；普通负载的主导长段有生产改善。另收好公共测试装配，让 DS 用例可以执行。不要以增加观测字段或测量次数代替这些结果。

DS50 同时在公共文档/多对象/消费者写集实施，任务图是 [DS50 文档工作区](2026-10-24-ds50-ui-document-workspace-blueprint.md)。你不写其 region/schema、Python、mixed/rules 生产源码和唯一 SDK；需要薄接线就提供精确差分与契约，指导会统一分配。旧 C/Linux 不恢复。

## 2. 第一主线：6 秒约 49000 个 owner 回合的因果与修复

原件在[本轮 RESULT](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md#sol-runtime-continuation-20261024)及其 `continuation-*` 文件。窗口为 `3403420404453250..3403426488561916`，约6.084秒；wall减已记idle约6.009秒，尚不是 CPU 结论。邻近 modal 链且没有新 refresh 终态，不能直接归因为七处新增 ready 标记。

### 可区分的工作步骤

1. 先用保留原件关联热区首个/最后一个 owner turn、窗口/session、候选/accepted epoch、原始输入与准备游标，确定热区何时开始/结束。不要先重跑整条367秒链。
2. 围住一个可复现的短场景，只记录**每次为什么不等待**：本地游标 ready、实际 pending refresh、输入/FIFO、激活前缀、worker/resource pending、scheduling revision、到期工作。复用既有 trace；有必要才加默认关闭、限额的 reason/游标观测，不做常驻全节点日志。
3. 在相邻回合比较“相同 reason 是否有进度”：游标/候选阶段推进、队列实际消费、完成到达、版本变化。能继续的本地工作须续原 tail；等待 worker 的工作不能因一个旧 ready 标志持续占用 owner。这里查真实值和所有者，不猜“清掉某 Bool 就好”。
4. 同一窗口工作的标记如何消费/重置，兄弟窗口和全局调度 revision 如何使 wait 返回，都按生产调用链追到写入端。transport 保留 DS 写权；若首因实证在其中，只交具体函数和窄方案，其余部分继续，不能擅自换一个 transport 基线编译并称主树修复。
5. 最小 RED 能区分根因后修一个职责。保持 FIFO、正文/选区事件、原 candidate/token、resource retirement；不轮询睡眠、不定时强刷新、不把所有 wait 拉长、不扔掉待处理输入，也不把未完成当成功。

正常短链的判据是该做的输入/准备/绘制能完成，静置能等待、无同原因无进度热循环。不要给复杂有工作阶段武断规定“最多N回合”。性能记录线程 CPU 与 wall/idle 分开；原成本日志保留，不把总体高idle比例覆盖热区。

## 3. 第二主线：窗口返回与系统恢复的真实输入责任

原始6没有写入，已知当时 first responder 是 opener按钮。这一事实本身不证明丢键：如果公共契约本来回到 opener，按钮不接正文是正确的。先将**返回目标选择**与**已选目标的恢复失败**分开。

- 对普通同进程关闭/重开：核关闭前的 accepted focus/selection、打开动作是否将焦点转成按钮、每窗的最后合法编辑目标、系统 key window/first responder 及活动 range session。
- 用两个可区分情况：主窗编辑目标仍是合法返回目标；打开时目标被删除/换绑/禁用。前者恢复后原始首键只写一次、精确位置；后者拒绝旧目标、不转写新对象，合法重新选择后可继续。
- 若当前消费者想“关对照窗回最后编辑字段”，应利用已有公共 bookmark/返回策略，在**打开前**声明；不要 native 无条件抢回任意旧文本框，也不要应用在循环里补焦。需要应用薄接线时交 DS 精确建议，运行时归属仍在你。
- 不把实际焦点在按钮时的键入记为文本链成功，也不把事后点击/重发算作原首键。已有12345789成功链保留原范围。

系统最小化/恢复继续走真实系统入口。先确认驱动可用再启动昂贵候选；可以用系统 Window 菜单/Dock 的实际动作，不能直接 native 修改窗口状态或仅 AX Raise 冒充。工具不可观察时如实留门，并继续核心修复，不为探测工具反复开应用。

把受影响的双窗短链、关闭后旧结果不操作新 session、最终字体/租约终态汇合一次即可，不重复既有长资源矩阵。

## 4. 第三主线：普通成本要有实现收益

当前已知 Rules 暖事务中位约14ms/max221ms、layout max124ms；Mixed 暖事务max686ms而layout max约6.7ms；另有208ms事务中native墙钟187ms。**不能把所有慢都继续当布局问题。**

修完热回合后，用同负载、同配置、同观测口径判断剩余主导长段。优先处理一个确有重复或可拆准备的长段：追其依赖、生命周期和等待来源；既有prepared snapshot/memo/budget能复用则复用，不一次加多层缓存或重写调度。窗口大小/字体代/正文/约束变化的失效仍正确。

区分冷启动、暖输入、resize、取消/拒绝、native墙钟/线程CPU/worker与真实呈现。保留完整原样本和未知frame。16/32ms仍按原门报告，不缩负载、删慢样本或用 callback 代 presentedTime。若部分阈值仍未达，给主导生产接缝和已实现收益；不能只再交一份计数表就收口整个阶段。

## 5. 公共测试装配：一次修好入口，别再阻断 DS

指导读到了 `/private/tmp/ds49-test.log` 的具体编译错误，均在 DS49 用例开始前：

1. `src/linux_application_host_test.cj:27/28` 顶层 helper 无平台条件，引用 Linux 专属 `CjguiLinuxWindowRequest`。本次授权仅按源类型的相同平台条件修 test helper/装配；不改 Linux runtime、不恢复平台验证。不能把整个测试文件删出所有平台。
2. `composable_ui_press_lease_test.cj` / `composable_ui_wheel_binding_test.cj` 等重复定义相同 foreign 测试符号。用现有 package testing bridge 的单一声明，所有调用保持；新接缝不进生产API。
3. `composable_ui_prepared_candidate_test.cj:308` @Assert Int32返回对Int64期望。按真实 ABI 类型改测试表达，不改 native ABI 来迁就宏。

这是你公共 testing seam 的窄写集。修后先编译受影响目标并执行相关小组，给 DS 可直接运行的命令/源身份；不用等待普通性能结束才交这一小增量，但不要为了交接要求指导回传同义确认。

原92项的20异常已经拆到 notes/form依赖，不能再统一叫native生命周期。你上次交的两项 owner fixture补丁和剩5个消费者断言已写入DS50任务，由DS处理。你不替它删断言或改版本期望；DS也不再删你的测试作为“全库通过”。一次明确冻结输入上的受影响同进程组足够，重复失败按首因处理。

## 6. 交接与连续推进

顺序：短热区归因/生产修复，与测试声明装配独立推进；随后窗口返回和系统恢复、一个主导成本改善；最后汇合正常链。当前已接受a528是基底，保留ABI/nativeStaged/invokeShortcut；独立构建目录/target，桌面不与DS并行争用。

每个实质修改都需能改变问题判断，不按每个符号停工。对同一核心问题累计失败沿旧规则保留；没有新证据不要第4次猜改。若需指导选择，集中给首个破坏点/互斥假设/原件与推荐取舍，其余独立工作继续。不得再仅重复“未达，需要后续处理”而未逼近首因。

交接沿同一个 RESULT 与精确 patch/源清单，说明基底→结果、公共测试入口、正常消费者和未验项；不另造SDK。更新ACTIVE唯一Sol段。无代理/顾问、无Git写、无旧线程唤醒。

容量继续既有E总额：留存≤13GiB、峰≤14GiB、宿主峰后≥20GiB，不给新包另加额度。上次12.981GiB已接近上限，大构建前先退役本线可再生工作输出并保留必要RED/源/候选原件；不得删DS/用户或唯一失败证据。遵守 [AGENTS容量与验证投入](../../AGENTS.md#artifact-space-budget)，复用而不按轮号复制，结束给实际空间账。

## 7. 2026-10-24 集中回报后的指导复核与继续实施

已核 `runtime-converge-handoff.json` 的13份根树源码哈希、精确差分、12/12原始日志及正常消费者读回范围。quiet demand 退休、普通返回书签身份与生命周期快照消费可作为接续基底（window `0e3d4b14`），不回滚a528七处续行、不重跑原长链来重复确认。这里接受的是三项增量；同批输入、系统恢复、普通长耗时及整阶段仍未完成。快照方案只证明旧桥查询2→0，不等于所有AppKit查询消失，也不是804ms已消失的证据。DS50的唯一SDK仍为a528，后续DS按明确交接汇合，双方不整文件覆盖。

### 7.1 收束剩余主线，避免再以一份性能表结束

先利用现有原件定位两个**不同**形态：Mixed session1 begin_turn281→290 accepted墙钟804.405ms，其布局仅0.942ms、native4.959ms；同期owner turn282单回合709.516ms（未计idle）。Rules session1 begin_turn179→225的accepted为219.734ms，layout26.408ms，跨47回合。前者先查某次平台主线程派发/系统动画等待或同步操作，后者查反复让出、准入和候选推进；不能把二者都当布局慢，也不能把候选存活墙钟当某个函数CPU。

1. 为两种形态分别建立最短正常复现。现有phase、dispatch submit/main enter/main exit/owner resume、候选游标与thread CPU足以回答则直接使用；缺什么才补默认关闭且有界的观测。短采集须覆盖慢区，不能重放整条长链却只留下早期phase。
2. 区分应用未处理输入、实际计算、等待主线程/资源、系统转换动画和诊断自身成本。保留相同正常负载的默认诊断关闭样本与必要诊断样本，不能用扩大日志预算或删慢项解决。被系统最小化期间的呈现暂停与可交互窗口真正阻塞分别报告，不通过改名消除用户能感到的卡顿。
3. 找到可改的主导生产原因后在现有owner/准备/唤醒机制内实现，保留候选和输入身份。若实际是系统转换的不可缩短部分，须用完整phase/状态证明，并转而优化当前可交互路径中最大的框架自有成本，不为系统动画重造调度器。
4. 只在这两个受影响场景和一次最终连续链上做前后对照。16/32ms门如未达，仍保留，但必须交出对主导问题的明确归因及实现收益或有证据的范围取舍，不能再把同一组未解释最大值原样留给下一包。

### 7.2 原始输入与返回边界一起完成

历史 `Esc→9→CmdS` 同批只Apply前缀，是尚未排除的数据正确性问题，优先于更多外观能力。沿原驱动同一投递序列关联接收/FIFO/分派/owner提交/Apply，先证明事件进入应用的真实顺序，再区分驱动顺序问题、合法焦点拒绝和运行时丢失/越序。不要加补点击、延时或拆成逐步等待来宣布原边界通过。有证据说明输入未投递时，修驱动并保留旧原件；若进入了运行时，修拥有该顺序的生产接缝。失败累计继续沿原记录。

默认回opener按钮不接正文保持合法；DS选择回编辑字段属于应用策略。你交出可供DS使用的既有返回入口和失效语义，runtime只负责已声明合法目标的恢复及陈旧目标拒绝。`editingFocusReference()`查询不能代替安装。系统恢复先尝试既有系统Window菜单等真实入口；同一Dock/CUA故障不反复撞。工具仍不可用则明确留门、继续其余工作，不为此增加新平台/API。

### 7.3 测试链接的最新归因与协作

指导已读DS50 `evidence/document-transaction/unittest-link.log`：实际命令使用 `-L.../native/lib`，缺的是被刻意隔离的 `_cjgui_internal_renderer_test_*`/`_cjgui_macos_test_legacy_window_queries`。既有 `native/scripts/verify_cjpm_mac_testing_link.py` 会运行sidecar `--testing`、选择 `native/testing/lib`、核实际归档并保证生产归档不变。因此该日志**尚不能证明你的生产源码或testing实现缺失**，不把测试符号塞进生产archive补救。

本阶段提供一条可复用、精确source-lock的受影响小组命令；DS的Path helper已修，DS负责自己的文档/适配用例及正确runner消费。若正确runner仍失败，按首次实际链接/运行错误再归因，不删DS测试当全库绿。你的12项旧绿证复用；只有新生产修改影响它们时再跑。

owner导出415/414差一行只需收好一次有界快照/收尾，不为旧日志补造原件；新的性能结论必须基于完整新采集。整E留存已12.997GiB，开始新构建前先按精确归属退役可再生输出、保留唯一RED和当前候选，继续13/14GiB总额。无额外SDK、代理、顾问、Git写、Linux任务。

阶段完成或确需协调时，按用户直接授权主动给指导线程集中回报：交付、原件、精确增量、未达项和资源终态；正常过程不逐小修刷消息。

<a id="restart-handoff-20261024"></a>
## 8. 电脑重启后换线程：保全成果，完成剩余运行时工作

执行线程：`01a16db2-14c6-7540-bf23-0048536bc8cd`，GPT-6.1 Sol / xhigh；已由指导创建并下发本节完整任务。

用户报告电脑发生内存问题并重启，要求更换线程。此决定只更换执行上下文，不撤销已有交付，不清零失败累计，也不证明 CJGUI 是重启原因。新线程是当前运行时写集唯一执行者；旧线程归档只读，C/Linux 不恢复，DS 仍负责生成/组件/Python/业务消费者和唯一 SDK。

### 8.1 最小恢复入口与已知身份

先读 AGENTS、ACTIVE 的 Sol/DS 当前段、本节及第7节。然后只读以下小交接件，不通读整个 RESULT 或旧会话：

- [本轮交接 JSON](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge7-handoff.json)：5文件增量、555输入归档、两候选、测试/正常链、明确未达项。
- [本轮 RESULT 精确段](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md#sol-runtime-converge7-owned-operation)。
- [冻结后根树漂移记录](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge7-root-drift.json)与[1034字节差分](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge7-post-freeze-root-window.diff)。

指导在重启后复算两个归档：源 `7ebb1861…`、候选 `0e0da9e5…` 均与交接相符。5个交接文件中4项仍等于根树；window 已验冻结源为 `1fc39baf…`，根树为 `9c2c3344…`，不能把后者当同源通过，也不能用前者整文件覆盖主树。按 AGENTS 先用 CodeGraph 定位，再读这个窄差分和实际调用；图覆盖不足就用源补证。弄清改动来源与行为，仅对受影响处补验。Native 头/实现、Cangjie preparation operation 与 budget 是同一私有 ABI 闭包，须配套构建。

原 `convergence-work` 已归档后退役，不是材料丢失；需要构建时从归档恢复到同一自有可复用工作位置。先看归档清单，不递归复制旧 artifacts/target 或整仓。保留 a528/0e3 已接受修复、原始 FIFO/production invocation、queued BEGIN 取消和已完成工作的唤醒责任。

原最终12/12、Native门控/ASan、默认双窗同批 Esc→9→CmdS 的 owner `12345789`、资源0/0/0、1000条Rules仅目标行改变均保留。它们是各自冻结身份下的已验范围，不等于性能或重启前根树整体通过。新改动不影响的旧门不再重跑。

### 8.2 第一段：内存与重启后的安全恢复

指导只读样本：本机物理内存48GiB，启动时间2026-10-24 19:09:21（上海），重启后 swap 已用约20GiB；这是当前压力事实，不是泄漏归因。没有停止用户其它应用、模型服务或开发任务。

1. 先核当前系统压力、swap/压缩内存、确属本线的进程树、构建锁和输出身份。旧PID不可直接复用为清理依据；核可执行路径、父进程与本轮创建记录。若有相关系统诊断，只读窄时间范围/必要字段，不扫描全部个人日志或启动堆转储。
2. 区分运行时消费者增长、编译工具峰值、诊断保留，以及其它进程占用；RSS一次采样、历史磁盘13GiB账或电脑重启本身都不能证明某项泄漏。没有足够证据就记原因未知，不能擅自修改CJGUI内存管理。
3. 恢复期最多一个构建、一个自有应用验证；双窗只在同一必要生命周期场景内。用户20:01已说明语音任务已加限制并要求继续工作：warning只作负载约束，不再是拒绝一切编译的前门；先跑单个有界反例，成功后继续同一生产修复与受影响验证。critical或本线进程出现持续失控增长时停止新增高分配动作并只回收自有任务，保留小原件报告；其余独立工作继续。高swap存量、单次warning不能永久停工，也不能在压力恶化时盲重试。
4. 不全量加载旧线程、JSONL或数百MiB日志到一次工具结果；按文件/候选/时间段流式提取所需事实。采样有界、日志有上限，不新造常驻监视器或诊断平台。若当前系统资源不支持重型验证，具体留门，不要求用户为普通步骤逐次审批。

**19:49 指导资源复核：**系统仍为 warning；`top` 的最大 MEM 项是另一语音项目的 Python（本次 PID 13821，IndexTTS worker），显示约49G，本线无构建/应用。该样本支持暂缓高分配工作，不证明泄漏或重启责任，PID也不是未来清理凭据。`frame_native_check.py` 的75退出仅属自有原生验证脚本，不扩大为公共框架准入。没有独立工作时保留未完状态，停止空转轮询；不再换线程或启动新的资源诊断工程，不自动结束语音任务。资源可用后沿本节已确定反例与生产改善接续，无需重做恢复。见[小原件](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge8-guidance-resource-review.json)。

**20:01 用户明确恢复：**用户已对语音任务加限制，要求回到框架工作；此指令覆盖19:49的整线暂缓安排。指导复测仍为warning=2、swap约25.8GiB，20:02的top仍显示该Python MEM约49G，故不声称系统已恢复normal，也不据此再次要求用户审批。Sol继续原完整阶段：现成尺寸反例→最小生产修复→有界声明交接收敛→受影响连续链；自有runner相应把warning从强制75退出改为记录并串行继续，critical与失控增长保护保留，不给公共框架添加门禁。每次验证前后做轻量核对即可，不常驻轮询；资源扰动期数据标注条件，不当作稳定16/32ms验收。无需再恢复归档、换线程或重跑无关旧绿证。

### 8.3 第二段：身份与真实未完成项先收准

完成8.1的窄差分核对后，明确本次实际编译源；不要再把主树、旧冻结库和SDK混成一份身份。DS51第11节已另交新包，当前 ACTIVE/其 RESULT 有新状态，指导尚未逐项接受。DS自报的 rules 非空 seed 卡 native prepare 以及两项 publicationSettle，只作为待分流问题：先确认使用的是哪份窗口/ABI/候选与正确 testing runner，保留首个错误；缺失需求、业务拒绝、输入未送达不直接当作native缺陷。

若证明是运行时已排队/已完成却未消费或取消责任遗漏，在现有单槽/nonce/generation/deadline机制内修复；若是DS消费端，交具体事件、契约与最小差分建议，不接管其生产文件。80次4ms预算pump不是320ms等待，不能靠加次数、加sleep或延长阈值变绿。

### 8.4 第三段：普通成本的生产改善，避免更小片段但更长等待

最终记录必须作为起点：Mixed非首owner max约150ms；Rules非首owner max约69ms；同1000条滚动为122ms/62回合，旧同步49ms/9回合不是新版成绩。拥有型交接已解决借用内存与排队长占用的一部分，但不能只展示owner切片变小。

1. 先复用 `runtime-converge7-final-metrics.json`、`runtime-converge7-owned-latency.json` 与原始成本行，选一次能区分原因的短正常场景。追输入/需求开始、准备提交、Main开始/结束、owner消费、接受/呈现；不把候选总墙钟当CPU，也不把诊断等待归给默认运行。
2. 优先解释并修掉异步声明跨回合的无效延迟：工作已可消费却错过本轮、依赖了无关唤醒、重复拷贝/准入、或每个小动作都经历一次不必要往返。沿现有有界推进/唤醒与deadline修，不盲目提高8节点批量、增加轮询或定时器，也不全面异步化所有桥。
3. 对 `installed_range_main` 的114ms排队/约6µs服务，先分生产必需查询与可选观测；生产需要的事实从正确生命周期快照或有序结果获取，观测不影响默认交互。对 `native_frame_present` 约69ms服务，区分真实GPU/系统等待与框架重复工作。未知物理呈现时刻继续未知，不用callback代替。
4. 在相同1000条、同窗口尺寸/文字/操作、相同默认配置下做一次受影响前后比较，给出用户等待、owner占用和必要资源的各自结果。功能正确、无额外工作和用户等待都要看；不能缩负载、删慢样本、改阈值。16/32ms未达就保留，并用明确主因和实际改善交指导取舍，不再只交同一张未解释耗时表。

### 8.5 第四段：正常连续使用与精确交接

汇合受影响的同进程测试、正常Mixed/Rules消费与必要双窗/系统恢复，沿已有驱动和owner精确读回。原始首键、同批输入、关闭/旧结果退休不能用补点击、重发或延时救绿。系统恢复用真实系统Window菜单/Dock等受支持入口；同一个通道不可用不反复碰，不以AX Raise或私有native调用冒充完整恢复。

默认诊断关闭链与必要性能采集分开记录；不为每个补丁重导SDK或重跑全平台。完成后沿原 RESULT/交接JSON提供精确基底→增量、编译闭包、正常行为、未达门和内存/资源终态。唯一SDK仍由DS消费明确交接后冻结。

空间沿E原额度留存≤13GiB、峰≤14GiB、宿主峰后≥20GiB；现有12.915GiB不能因换线程再增加一份额度。只回收自己确认可再生且原件已保存的输出，不删用户/DS或唯一失败材料。无Git写、无子代理/顾问、无Linux/C恢复。

用户已明确要求完成后主动反馈指导。新线程在完成整包或发生真实跨线/重大资源阻塞时，调用 `send_message_to_thread` 给 `01a12eb2-9443-7111-bcbf-4b2dee84b90f`（local）集中回报一次；这是来自用户的持续授权，正常过程不刷消息。不以最终报告已写文件代替通知，也不为通知再补跑一轮。若发送工具故障，保留报告并在本线程最终答复明确失败事实。

<a id="sol-runtime-stage9"></a>
## 9. §8 交付后的整包接续：正常窗口成本、双窗恢复与 SDK 汇合

2026-10-24。继续当前 GPT-6.1 Sol 线程，不再换线程或重做资源恢复。§8 三项生产增量与原件保留；本节收完同一运行时大阶段的真实剩余，并向 DS 提供可冻结输入。

### 9.1 已接受的起点与不能扩大解释的事实

指导已核对 `runtime-converge8-delivery-handoff.json`：五项生产文件与根树、源归档一致；源包 `07d26550`、候选包 `e2d0d332` 哈希成立。将 cumulative overlay 应用到 DS 当前 SDK `78d5caa2` 的五项基底，逐字节得到交接目标。12/12 日志、各 native 检查 exit 0/无源漂移和默认应用读回原件保留。本次指导未重新构建或跑 GUI。

三项改善可作为 DS 汇合输入：几何 setter 去冗余、kind9 至多8节点混合声明/复用、kind10 drawable 实际完成唤醒。它们必须和 window/header/native/preparation-operation/budget 配套，不能只换 .cj 或保留旧 native 归档。§8 冻结文件不再原位改写；下一增量另记精确基底。

同一页滚动样本为 52.317ms/61回合/103声明 → 31.226/28/22 → 36.850/21/22，最终 drawable 对应交接1次；这是机制收益与顺序样本，不是稳定32ms通过。中间较快、最终较慢样本照留。全会话非首分布也不能宣称全面改善：旧样本p95约3.725ms，最终约6.141ms，条件包含系统压力变化。关闭Main服务39.727ms/队列0.016ms与历史 installed_range 的长排队须分开，不能用修后一处取代另一处。

### 9.2 A：关闭尾部和旧长排队的因果收敛

先复用现有174行最终成本序列、关闭相关nonce/阶段及旧114ms原件，明确测量的是队列等待、Main服务、owner恢复还是总墙钟。只补能区分具体阻挡者的有界观测，不建新诊断框架。

1. 沿 `native_session_destroy` 的实际调用链分出：输入/编辑会话停用、拥有型请求退休、GPU在途引用、view/window释放、字体与缓存释放。找到39.727ms中实际负责的操作，再决定修复；不要先把整个销毁移到后台。
2. 系统/UI对象线程责任不变；可以分离的资源退休必须由真实最后引用/完成事实驱动。即使窗口先不可见，旧session仍要完成回收且不能被新generation继承。不能把清理搬到无主队列后以“close立即返回”算优化完成。
3. 旧 installed_range 记录若服务仅微秒而排队约114ms，应追当时阻塞Main的实际callee；优化该查询自身不是答案。缺少该次原始调用跨度就保留未知，按同负载作一次可区分复现，不能凭一个新快样本给旧故障结案。
4. 若证据表明根因是重复销毁/重复等待/错误唤醒，在现有owner、单槽与退休契约内修。若是不可拆的系统调用或现有材料无法安全归因，具名交指导，不继续无依据扩大异步化。

先给最小RED，再跑受影响的取消、关闭中完成、同槽新generation重开及默认正常关闭；既有无关几何/混合声明绿证复用。资源终态、迟到回调不能碰新session和源指针所有权是必要门，不以性能理由放松。

### 9.3 B：普通操作的剩余延迟

优先用同1000条、一页滚动和既有Mixed负载判断新改动，而非另造更轻的场景。区分输入/需求→candidate接受墙钟、各owner工作、Main排队/服务与绘制提交。物理呈现时刻仍无事实时保持未知，不能由提交推导。

§8已减少交接，不再扩大8节点批量、续原deadline或加定时轮询。若剩余等待来自真实完成已到而owner没有被唤醒、无效的重复准入/转换、已经缓存的事实重复查询，在原机制内消除；若没有这种证据，别为追一个32ms数字改状态顺序。

做一组事先确定输入和采样条件的前后比较，保留所有样本及首帧/关闭分组，不反复重投挑最快。门未通过就保留未通过，说明下一项真正能改变体验的机制。默认诊断关闭的实际输入、owner精确读回、保存和正常关闭仍要成立。

### 9.4 C：同一会话的双窗系统恢复与退出

已有 Finder普通Open、同PID、73→首键4→734 是单窗正证据，不重跑来充数。补缺的连续会话：

- 主窗+第二窗各有可区分内容/owner事实 → 通过系统入口最小化/恢复 → 回到被恢复窗口首键写入正确对象 → 切另一窗继续 → 关闭第二窗 → 主窗继续 → 重开第二窗显示当前owner → 正常退出并核资源/descriptor终态。
- 使用真实系统恢复入口，记录同进程/窗口身份与键的到达；不以AX Raise、私有restore或补点击救绿。合法的“重新选择编辑字段”应与“系统恢复保留原焦点首键”分开报告。
- 全最小化⌘Q的旧失败先核命令确实到本应用。若是前台/驱动投递问题，只记该次通道事实；若native已收到application-exit意图，则追共享host唤醒、域关闭决策与最后窗口处理。业务拒绝和事件丢失分开，不绕过消费者强制host.close。

不再为Dock工具超时无限换助手；已有正确系统入口可以使用，但旧路径保持其边界。桌面与DS串行，自有bundle/PID可辨识，不关闭用户或其他线实例。

### 9.5 D：和 DS 的实际汇合

DS已拿到§8配套输入，其§12仍负责挂载事务、公共集合工作区和普通文件消费。你继续只写运行时归属，不代改生成核心/消费者/客户端/exporter。

- `native_advance_unsupported` 本身是合法同步fallback；DS seed 原失败在 `participant_prepare`。由DS先区分消费者registry与holder prepare，再带精确原因过来。不要恢复已撤回的“必属native”判断。
- 零间隔路径原件为43次投递、AX完整.json、另存后.js。DS先定位消费者与公共事件第一次分歧；若证明运行时收齐后派发/完成遗漏，你接收该最短序列优先修，沿FIFO/绑定代与完成责任，不能靠延时或重发。
- 两个publicationSettle组合失败只有在源/链接/原组合负载明确后才进入本线；不能用单跑绿色代替组合，也不扩80×4ms预算。无新归属证据时不要阻塞独立工作或启动全仓测试。
- 下一交接仍提供精确增量与累计配套覆盖，说明从DS当前接受基底如何到目标；必需新源加入闭包、native重建、实际链接指纹由DS完成。唯一SDK只由DS冻结。候选汇合成功不等于所有历史门通过。

<a id="sol-runtime-stage9-coordination"></a>
### 9.6 连续推进、容量与收口

本节是一整包，常规问题自主完成，不在A/B/C之间停工。生产改变应有实际体验/工作量收益或明确正确性收益，不能只新增计数。无新证据不重复旧12项、全部设备链或整包归档；有关联的生命周期检查仍必须做。重大归属/释放安全问题反复实修无进展按AGENTS集中升级，独立工作继续。

**2026-10-25 当前接续安排：** DS 正在收尾 §15 的消费者呈现、选中 owner 一致性和唯一 SDK；Sol 不必整体等待。先从已冻结 §9 配套接续 §9.2/9.3，复用原件和失败累计，选择能改变实现判断的主导成本，明确根因后做最小运行时修复与必要定向测试。保持同1000条负载及原输入/资源契约，不因旧慢样本难复现就反复采集或宣称旧因果已闭合。源码和测试可独立推进；桌面操作、最终消费者连续链与新增量的 SDK 汇合待 DS 本包冻结后由指导统一协调，不对 DS 在途界面反复重建。不写 DS 的 generated/公共组件/消费者/客户端/exporter/唯一 SDK，也不扩大 C1 未明归属。若已无独立必要工作，保留候选和具体待联验项后停在交接点，不把未验标完成。

**当前回报入口：** 用户在新指导线程「复核线程并拟定下一步提示词」明确要求 Sol 后续向该线程回报。目标改为 local 的 `01a17207-04bc-76a2-90c3-99c8c5060423`；本条覆盖 §7、§8 及旧消息中的 `01a12eb2-9443-7111-bcbf-4b2dee84b90f` 地址。完成整包、独立增量已就绪需协调联验，或发生实质重大阻塞时集中报告一次；正常进度留在执行线程，本次迁移无需另发确认回执。

继续使用既有恢复/构建/检查脚本和一个复用工作目录。E留存上限13GiB、峰14GiB不变；当前12.966GiB，先计算新留存与可退役的本线重复产物，不能把已有归档再复制一整份算另一条线。旧关键RED与基底保真；回收须准确归属、原件保全、进程/锁释放。warning记录后串行推进，critical/自有失控增长停新重负载；不得处理用户语音进程。

最终一次集中交付：实际生产改善、默认正常链、性能原始分组与未过门、配套源码/ABI/候选、DS接入条件和空间账。未完成项不标完成。完成或实质重大阻塞继续主动发给当前指导线程 `01a17207-04bc-76a2-90c3-99c8c5060423`；不要求指导再回传一轮同义收口确认。无Git写、无代理/顾问、Linux/C封存。

<a id="sol-runtime-stage9-input-scene-handoff"></a>
### 9.7 2026-10-26 接续：操作呈现、会话恢复与冻结增量汇合

**本节替代上一条等待DS整包的安排，继续原§9，不另开阶段。** DS已有不可变消费者基线[1e7c4c95](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/sdk-1e7c4c95/)，指导已核604项大小/SHA；其native仍为2d52b312/ea6e14d1。保留918b0bc0和既有定向绿证。本次恢复普通入口的可靠操作与会话连续性，再交可汇合的运行时增量；DS同时离线补mixed窄窗。复用现有事件观察、候选/accepted身份、焦点引用及资源退休实现，不重造命中或焦点状态机。

1. **先核实际失败层。** [基线原日志](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/evidence/section15-final-20261025/mixed-baseline-topleft-deadzone.log)第47行已有`PRESET_HELP state=open`，49行`CJGUI_SCENE_REJECTED reason=identity_reference_invalid`，并无关联点击/命中原件。它证明某次操作已到域状态，不证明HID从未送达；也尚不能把该操作归到某次鼠标投递。先从`MixedFormController`的helpVisible/helpReturn、弹层引用、command声明与候选拒绝路径查哪个身份失效，以及拒绝后域状态/可执行命令是否仍跟旧accepted画面一致。不要先猜透明遮挡、扩大hit区或放松引用验证。若首因是消费者引用/挂载声明，只交DS具体调用点和最小方案；共同候选、路由或回退有缺陷才在本线修。
2. **一次可区分的短复现。** 使用同一冻结源、独立bundle/PID，选一个失败入口和一个邻近正常入口，记录实际窗口/逻辑坐标、原始down/up、接收、命中node/semantic、ACTIVATE、域状态、candidate接受/拒绝及最终画面。优先复用`CJGUI_OWNED_POINTER_TRACE`、`CJGUI_HIT_TRACE`、`CJGUI_TRACE_POINTER_GEOMETRY`及已有域日志；前者有计数上限，采集须覆盖目标动作。日志仅观察，不改路由，缺哪段才补默认关闭的有界观测。移动/缩放/滚动只用于区分坐标与场景版本，不做无穷坐标扫描。若证据已指向场景拒绝，直接沿首个坏引用归因。
3. **会话停更另立事实，不叫污染结案。** 从保留操作序列/驱动缩出AX编辑、组合输入、Apply/Cancel后激活失效的最短序列；检查有效编辑/press lease、候选以及待完成事件。干净重启只是对照，不能替代原会话恢复。序列原件不足时明确缺口，最多做能区分假设的短采集，不重放整晚试错。保留FIFO、绑定代、正文/选区与完成责任；不靠Esc、补点击、延时、重发或直接改状态救绿。不能定位的重大生命周期问题按AGENTS集中升级，独立工作继续。
4. **正常消费和成本只做有价值的一轮。** 先RED再窄修，复用未受影响ASan/瓦片/构建绿证；新改动涉及生命周期时补对应反例。修后用默认诊断关闭的普通HID点击/文字输入确认一次执行、正确owner/完整正文与版本、画面反馈和正常关闭；AX写、快捷键和descriptor各按实际通道标记。沿§9.4补必要双窗恢复/退出段，不重复旧矩阵；918准备优化的收益仅在同消费者、同负载比较，不用旧版对新版不同布局作性能对照，16/32ms及历史长耗时未知边界保留。
5. **写集和汇合。** Sol只写运行时/native及必要定向测试，不写DS消费者/生成/公共样式/客户端/exporter，不修改冻结SDK。DS先修窄窗布局及归属明确的应用接线；本轮前台最初由Sol使用；Sol已报告自有窗口正常退出并释放前台，DS可继续本线必要验收，双方不并发构建同一target。runtime增量完成后一次集中交精确基底→目标差分、链接身份、正常链/未验项及前台释放状态，由DS统一接入并只导出一个新SDK。最终SDK消费不能提前由1e7的旧测试替代。

继续遵守[AGENTS容量](../../AGENTS.md#artifact-space-budget)和[验证投入](../../AGENTS.md#verification-value)：E留存≤13GiB/峰≤14GiB，开工核实际空间、先退役本线无用的可再生产物；不复制归档树、不删DS基座。无新源/新失败不重跑既有整套。完成或实质升级只回本指导`01a17207-04bc-76a2-90c3-99c8c5060423`，不回旧线程，不要单发同义接单回执。

<a id="sol-runtime-stage9-cost-luna"></a>
### 9.8 2026-10-26 用户下发：普通更新成本与资源收束，Sol 可委派 GPT-6 Luna

**授权与方向。** 用户在当前指导线程直接要求“你直接安排给他啊，他工作完了反馈给你，不用我反复搬运和提醒你了。并告诉他可以调用gpt 6 luna 思考档位按需调整”。本节继续原§9，替代§9.7交付后暂不派工的安排；不重开阶段。Sol保持当前主线程与主模型，负责归因、复杂实现、集成和集中交付；可按需调用型号准确为`gpt-6-luna`的子代理，思考档位按任务难度选low/medium/high/xhigh/max，不以旧“无代理”条款拒绝本次明确授权。默认复用一个子代理，明确方案、写集及验收后交完整子包；根因/结构不明及时交回Sol，不能靠换模型清零失败。子代理进展和完成回Sol，只有Sol集中回当前指导；不为子代理另建用户线程或定时，不自动调用外部顾问。

**基底与并行。** 已复核的[§9.7交接](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-input-handoff.json)及四文件patch保持不可变，供DS完成当前SDK；新工作以该接受增量为基底，先在Sol本线受控输入/构建目录形成精确差分。原私有目录已退役时，仅从明确清单恢复必要源码闭包，不复制整仓、历史产物或归档树，不另建Git worktree/切分支。DS当前包不等待、不追入本轮新优化；不原位改DS锁定输入，不改冻结SDK或已交接补丁。新差分在本包交付时集中协调回共同源码与后续SDK，不建立长期分叉。Sol只写共同运行时/native及必要测试；消费者/generated/公共样式/client/exporter仍归DS。

**要交付的结果。** 在既有普通负载下减少局部更新的重复准备、主线程交接或无效等待，让真实使用成本改善并保留状态和资源责任。复用当前布局、prepared painter、候选/accepted、FIFO、budget、唤醒和资源退休，不重造调度器、焦点状态机或诊断框架。

1. 从同1000条负载原件和当前生产路径出发，优先查字段修改、选择、一页滚动中的文字准备、节点处理和ready→owner等待。既有成本原件只提供线索，不能把可能重叠跨度相加；坐标/clip错误失效假设已有排除结论，直接复用。先定位可区分的主导成本，再保留生产反例和最小修复；不扩大批量、延长预算、加轮询或削弱凭据取得表面收益。
2. 918已消除prepared painter的冗余字体准备，既有字体/ASan/瓦片绿证保留；尚未测正常窗口墙钟收益。把它和本轮新改动的必要比较集中在最终同消费者、同布局、同负载、默认诊断关闭的正常链，不逐补丁重跑整套检查。区分墙钟、线程工作、排队和真实呈现，16/32ms未过仍保留。
3. 历史39.727/114ms继续保留未知，仅当新证据可以识别实际阻挡者时追，不反复等待旧慢点出现。生命周期有改动时才补关联的取消、迟到完成、关闭、同槽新generation与资源终态；不把释放移到无主后台或以窗口消失替代释放完成。
4. 先完成不占前台的归因、实现及必要定向检查。桌面当前授权以本节“当前协调”为准，最终实际输入/滚动/关闭链由指导协调错开，不能用AX写/私有调用替代原正常链。共享target的build/test串行；Luna不得另占桌面或重复构建。桌面确需等待时只暂停依赖段，独立必要工作继续；完成后报告精确待验段，不空转、不把未验标绿。
5. 最终一次交实际生产改善、基底→目标源码差分、链接身份、完整同负载原件、正确owner/正文/版本/正常关闭、未过门及空间账。没有证据支持安全修复时说明已排除假设、剩余选择和收益判断，交指导取舍，不制造无收益改动或无限采样。当前DS故障和C1只在有明确新运行时归属证据时接入，不把它们全部重验。

**跟进与边界。** 用户已明确授权Sol完成、独立增量就绪需协调联验或重大阻塞时，主动使用`send_message_to_thread`向local指导`01a17207-04bc-76a2-90c3-99c8c5060423`集中回报；不回旧`01a12eb2-9443-7111-bcbf-4b2dee84b90f`，不向用户索取搬运或再确认，不单发同义接单回执。若需核授权，读取当前指导线程的人类原话即可。指导直接复核和在已授权整包内接续，正常进度留Sol；自动化只作兜底，不替代主动回报。

沿用[AGENTS容量](../../AGENTS.md#artifact-space-budget)与[验证投入](../../AGENTS.md#verification-value)：本§9.8经2026-10-26指导裁决，E留存≤13.05GiB（原13GiB增加约51.2MiB）/峰≤14GiB，沿原核算边界且不重置旧占用，写盘前重查；宿主峰后≥20GiB。新增额度仅供必要焦点反例、受控来源差分、可复盘二进制与正常链原件，一个本线构建目录复用并在成功/失败/取消后退役；预估峰值、不可复用项、保留数与回收点记本任务现有scope，不另开台账。先按准确归属退役本线可再生产物，保原始RED与唯一证据，不复制归档树、不清DS或用户文件，不为最后数KiB反复压缩/重跑。没有新源/失败/证据疑点不重复整套。无Git stage/commit/push，无外部顾问；本次仅开放Sol按需委派GPT-6 Luna，不恢复Linux/C。

**2026-10-26 指导复核独立Native增量：** 已对[就绪交接](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-update-ready.json)及源码作限域复核：patch `a99b4de2…` 三hunk从根树918逐字节重建c61c6a9f，新增测试9196355a与受控目录一致；同测试RED/GREEN源清单除renderer外一致，原始`.log.gz`为唯一失败font queries=1→ASan全过0，共享瓦片ASan通过。完整credential/coverage准入、原同步helper和miss后独立paint保留；颜色/正文试验证明新像素不同及旧accepted完整正文/属性/纹理不变，不外推为独立像素oracle。根树918及§9.7四文件patch哈希未动。指导未构建、未跑GUI，接纳为可继续联验的独立候选，尚非最终SDK交付。Sol已完成同Rules/Cj9.7的2d52与c61两次普通构建；指导核两份build记录的470份Cj输入与配置相同、实际4成员/verified provenance、两EXE身份，以及重放所需五个归档的实际SHA。沿用Sol两候选各7文件字节/权限与严格签名重放证据，不再复跑。两候选同1000条比较只能归于918与新修合计增量，不额外造第三候选。默认OFF功能链与必要同配置成本观察分别记录；timing=-1和FrameObservation无呈现时刻时保留未知，不以trace/callback改称正常端到端收益。首个C测试编译错误原件未保留如实记缺口，最终同版RED/GREEN与共享瓦片原件不受影响。

**当前协调（2026-10-26 本轮交付复核后）：** 焦点74b7db97/测试675f9ceb与此前Native c61增量均已限域复核接受，两个验证身份分别保留，不借旧证据宣称合并SDK已通过。Sol明确释放前台和共享target、自有工作目录已退役；指导现场发现DS路径的mixed PID84304在运行，保护该实例，桌面交DS继续§16，不再等待旧72093或Sol。本包最后源码回接已完成且指导复核通过：实际根renderer c61、最终测试9196355a、公共头ed8f886f、窗口74/模层测试675/search源6a3的完整SHA均与已接受原件一致，patch a99b4de2不变；交接root_reconnection已完成、pending_normal_chain=false、combined_root_normal_consumed/combined_sdk_complete=false。仅核字节与diff，无构建、测试重跑或前台/target操作。Sol本包已收束，不再追加同义确认或自动造新阶段。DS可继续当前独立验收，最终SDK再按实际影响消费已冻结的74+c61；不得从根树抓其他WIP。E留存≤13.05GiB/峰≤14、宿主峰后≥20GiB保持，不增整套产物；无需用户给Sol搬运或同义确认。

**2026-10-26 指导复核正常消费增量：** 核[GUI归档](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-update-gui-originals.json)20成员及[日志原件](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-update-gui-log-originals.json)14份解压后SHA/长度一致；四次进程均exit0，默认OFF两次有close_permitted/destroy complete。独立按两份初态公开context逐记录比对四个60745B存档：均1000条、同SHA9db2be74，仅owner1000完整名称由原值变为97，其余owner字段保持；原始AX记录真实键入、全选1000、一页down/up及Apply后v1/v3。滚动同时影响外层与列表，不能写成隔离内列表滚动。c61正常链最终公开快照缺失，只接受AX与完整保存读回的既有范围；诊断快照不替代它。事件phase误标保留原件并以进程时段区分，旧94741超时与两次save-as启动失败不计生产RED或正常关闭。已查[成本归因](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-update-gui-cost-analysis.json)：累计计数不能映射单动作，Main queue/ready→owner与真实呈现时刻未知、trace覆盖不对称，不给wall/16或32ms/因果加速结论；只说明918+c61合计Native候选可正常消费。复用此前源与7文件重放审阅，本次未运行GUI或构建，不为缺快照重跑全链。

**本包必要返工：返回状态与确认消费。** 指导核DS新SDK604文件SHA/长度一致，窗口两处新改动在内存撤回即已接受5e47848e；首键链原件成立，但真实日志走的是owned拒绝→普通focus→旧bookmark的`installed`，未覆盖新增无书签`focused_whole_value`。源码确定该新字符串会被`CjguiSearchableSelectionPanel.takeConfirmed`（只接受`installed`/`focused`）清pending并作为失败，18项ordinary与现场日志不能替它证明通过。已直接交Sol在上述冻结比较之后收束共同窗口/搜索确认接缝，受控增量与性能候选分开、不原位改DS冻结SDK。优先复用现有`focused`表示合法仅焦点恢复，trace可细分；保无书签字段→弹层确认→实际业务确认的反例与受影响正常链，不扩公开状态、不重跑无关矩阵。另用有区分力反例核owned拒后旧bookmark能否独立准入：必须由owned证明的选区不能因普通focus成功变成`installed`，独立整值写链须有资格依据；保calibration/owner退休/版本拒绝与免重点击首键。Sol可按用户授权委派GPT-6 Luna，负责本包归因、必要最小修复和集中回报，不重造焦点状态机，不占DS消费者/generated写集。

**2026-10-26 指导复核焦点交付：** [patch528867c4](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-focus-from-e717.patch)在内存严格撤回后窗口恰为e717、测试恰为18d968c4；最终测试归档两文件与根树74/675一致。生产路径仅复用既有mode3候选与真实回执，使无书签及合法整值校准拒绝在关闭准备中保持pending、接受后focused；没有扩公开状态，source-owned多行与其余atomic拒绝不被此兜底接纳。CodeGraph未覆盖本次Cj符号、CodeLattice路由歧义，已按原源核prepare/receipt/takeConfirmed衔接，不把图缺口当零影响。核真实RED归档12成员、最终正常归档15成员及4份原始日志SHA/长度，最终13项日志为9+1+3通过；中间owned_selection_unavailable回归未改断言，源收窄后通过。独立正常应用是公开host/controller/panel与真实range sink拒绝夹具，非mixed或模型验收：真实回执focused→业务确认1/2、无重点击7/9→abcdef7/v2与abcdef79/v3，末帧/AX与完整日志一致，calibration仍true，PID76471 exit0/destroy complete。构建记录为normal/verified且实际4成员，窗口源74/search源6a3一致；编译EXE与签名app的SHA不同，进程记录已有完整段相等证明，运行EXE17d4fb6d与归档一致。Sol报告留存13.04982GiB、净新增51.03MiB、实际退役下界280.93MiB，采样高点13.4205非连续峰值；指导确认工作目录已不存在、宿主约226.69GiB，并保留首次重复raw短暂超额及finally修正记录。未跑新的GUI或测试，不把此native918+窗口74证据外推为c61合并消费。




**2026-10-26 Sol焦点接缝交付：** 已完成本包必要返工，见[完整交接](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-focus-ready.json)与[结果](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md#sol-runtime-stage9-update-cost)。根树窗口74b7db97、测试675f9ceb基于e717，复用既有mode3焦点候选/关闭回执，准备中pending、接受后focused、取消终态；校准拒绝不安装旧书签，其他owned/版本/选区拒绝保留。真实RED发现面板在关闭接受前消费target_changed；最终13项针对性通过，正常入口PID76471实际确认业务项2次，未重点击的原7/9使完整正文abcdef79/v3，校准仍true，正常exit0。原件及可重放二进制保留，所有自有实例/工作目录已退役；空间沿原E口径和批复13.05/14GiB收尾。未造合并SDK，冻结c61正常/成本证据与此native918+新窗口候选分开；DS整合时沿具体影响验证，不重跑已接受四链、不外推呈现墙钟。无Git写操作、外部顾问或Linux/C恢复。


**2026-10-26 共同native回接：** 已按指导要求将918→c61精确3hunk与最终9196355a测试回接共同根，完整SHA/原归档字节一致，头/ABI未改；无构建、桌面或旧链重跑。[当前交接](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-update-ready.json)已区分回接完成/冻结链完成/74+c61+§16新SDK组合未验，由DS按具体影响消费。

<a id="sol-runtime-stage9-combined-interaction"></a>
### 9.9 2026-10-26 DS组合候选触发的共同交互返工

§9.8已完成并结束原自动跟进。本节由指导依据用户本轮DS §32回报直接接续，属于同一交付目标内的新失败返工；不重开旧性能比较或独立C/平台任务。目标是让真实弹层中的字段可操作、退出后原编辑能续写，并使页面Apply/Cancel消费正确的输入完成状态。DS的嵌套组合与应用接线按[§16.6](2026-10-24-ds51-normal-workspace-delivery-blueprint.md#ds51-section16-nested-composition)继续，不等共同返工才能做独立工作。

**已核基底。** DS sdk-combined16-r3-final，source abec177ac69b561eeb9db4a2055bf6f7a6512eb8f01cc4c19fa4e753e552bca4、exported 8df0ddb8d0e5ab3d2662020eb0ba570e0a03a549de5da18aab8507d4be632259，604文件/581输入与当前树一致。共同window74b7db97、modal-test675f9ceb、search6a3d263f、native c61c6a9f/test9196355a/headered8f886f保留；精确SHA取原交接。DS原件在runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/evidence/ds16-combined16-r3-20261026。rules-dialog.png确有公开DialogLayerWithReference；报告称文本字段点击穿透、Tab无焦点约束，页面Cancel/Apply在内联编辑未收束时使v1→v5且未生效。47件里没有所报PID48847正常链日志，唯一app-rules-r3.log是PID48456后台直启NOT_READY关闭，不能将此日志当弹层成功/退出原件。对这些运行报告先定位可区分的事实，不直接归因native或把工具失焦当生产缺陷。

**执行范围和方法。**
1. 沿rule_set_window_app公开layerMode=record-edit的声明与共同布局/模层作用域/真实命中/输入路由查清：画面、候选与accepted作用域、坐标/viewport、native命中node和最终owner必须对应。复用既有trace，限量取一次能区分“遮挡或AX坐标错误 / 模层未接受 / 命中穿透 / 焦点入层失败”的原件；不能继续靠重启、Space、重复点击、延时、AX写值或私有调用绕过。通用机制原因不明时按设计导航查已有CJGUI实现及本地GPUI/Slint等只读参考，不引入依赖。
2. 保留实际RED后做共同责任内最小修复。弹层字段接受真实点击/键入，Tab/Shift-Tab留在活动模层，背景动作不触发；业务确认一次，关闭后无需重点击即可向原编辑器输入首键并读回完整owner正文/版本，不能用“Space重开按钮”代替文字续写。保§9.8的focused/installed、无书签、owned calibration/退休/版本拒绝边界与取消终态，不新增平行状态机，不弱化校准或选区证明。
3. 追页面Apply/Cancel疑点到输入完成→owner变更→动作裁定→accepted反馈，核是否旧编辑完成在Apply/Cancel后又把草稿写脏。若共同接缝有错，同包修FIFO/版本和完成归属，不丢首键/尾键、不加补发；若是应用接线/错误坐标，仅给DS具体源位置、因果与可执行修复意见，不并写消费者。真实页面操作必须只执行一次，读回结果与清洁状态，单纯版本增长不算成功。
4. 针对性反例和受影响正常rules消费一次集中核验，mixed只补该共同变化所需衔接；复用§9.8所有适用绿证，绝不重跑2d52/c61四条1000记录链或另做性能候选。后台直启NOT_READY只在与本根因相连时处理，否则记录独立工具/启动边界，不扩第三条研究线。所有未验/旧性能门继续如实留开。

**写集、串行与回报。** Sol负责共同window/search/layer/输入路由及必要窄native和定向测试；保持公共ABI，确需实质契约改变先给指导方案。不要改DS的composition/generated、client/exporter、mixed/rules消费者或冻结SDK；应用侧归属明确后交DS。可按需委派gpt-6-luna（档位按难度、一个复用子代理、写集明确），Luna只回Sol，不加顾问或用户线程。主执行线程local/01a16db2-14c6-7540-bf23-0048536bc8cd，整包就绪/实质阻塞回本指导01a17207-04bc-76a2-90c3-99c8c5060423，不回旧咨询线程；用户已授权直接收发，无需再请求。

监督到期时的收束裁决（最终交接见文末）：指导核PID37298、67446及35790的process原件均为1800秒Acceptance lifetime cap、forced_cleanup=true、实际app退出码不可得。第三实例实际EXE9c934b897ca8dcbd7650bd88e66cb73de6e8d1e8f8a1f7f7a5503b5a240f6c4a已消费DS main7a与本次native584，所录预填/输入只按实际原件范围保留，不能补称业务确认、完整owner读回或正常退出。已直接通知Sol停止第四轮前台启动、停止对过期对象调用及会自动重开空应用的取态；不放宽时限或靠延时/补点/重发救绿。此为工具/采集生命周期重复失败的投入收益裁决，不是生产RED，也不取消正确性验收。

Sol继续完成原§9.9的差分/证据交接与清理：交共同native/runtime基底→目标、必要测试与源身份、selector真实RED/GREEN、实际链接记录及已有真实命中/Tab/背景/页面输入/Save原件；如实列出确认/完整owner正文版本/清洁、文本返回首键及正常退出未验。保持7a应用消费身份，不抓DS的新组合/测试WIP、不改消费者或导SDK；只做必要离线检查和归档，按原预算保全唯一原件、退役自有可再生产物，并明确释放前台/共享target、集中回本指导。指导再限域审阅共同差分和关键原件，必要源码问题仍交Sol修；不自动恢复重复前台链。候选及明确释放就绪后，未完成的受影响正常链由DS原§16.6在唯一最终候选一次承接，不两边重复、不恢复历史矩阵。候选交出与原件保全不等于正常消费验收完成。

已核应用接入身份保持：main7a0dc048fa852f9463d723108fe6b942ba458740d3b98fd1a916fb2187a3233f，14hunk owner-routing.diff SHA ec2eb80a0f889880a49fc73b4ed0cfe29a6a8780a2ca2d359c8ad43b02915346，从5b87严格重放等于根源；DS报告的4460测试RED/GREEN当时已核，后续测试扩展按各自身份，不追逐根WIP、不将旧绿证归给新测试。原始基底与已有子链证据在原路径保留，DS整包其他独立项持续推进。

**容量裁决。** 本轮指导实测宿主244166225920B可用。为必要共同返工，在原E留存13.05GiB基础上只增加0.10GiB至13.15GiB，峰仍≤14GiB、宿主峰后≥20GiB，原13.04982GiB占用不清零；不是新10GiB额度。新增用于有限RED/GREEN、源码差分/测试原件及必要可复盘二进制，不为最后数KiB反复压缩或猜删唯一原件。开工核当前实占与构建峰，超出时先收束本线可再生产物或交具体方案，不静默上调；实际finally覆盖成功/失败/取消，只清自有实例和工作目录。无Git写，不恢复旧平台/C，不新增顾问。

**Rules应用归因已核（2026-10-26本次主动回报）：** 指导独立核PID37298原件的owner1/2 FIELD未变、draftVersion均0、AX名称7及kind28 applied=false；数值nodeId解码与selected全局form预填是明确的消费者问题。当前根Rules main5b87c1d8相对冻结8ca65cc6仅新增编辑界面入口，未修owner接线；DS唯一SDK已到bca75806、回退fd09ce54，保护该增量。已将按公开owner/field路由、无效元数据拒绝、按目标草稿预填以及Apply/Cancel元数据/版本一致性写回DS原§16.6。DS为外部执行者，无消息通道，用户可复制接续，未声称已送达/开工。Sol不并改消费者，继续独立Tab/屏障/返回及页面输入顺序归因；此时的owner源修复依赖现已由DS的7a交付解除，按上方当前协调接入；不在旧应用反复试绿。独立前台工作完成即清理释放，不为等待长期占桌面。DS ACTIVE报告19:25再次释放；此前19:13授予Sol的前台授权继续有效，新的DS源码返工先离线，正常消费只在明确交接后串行。原有native backdrop反例与本应用拒写分开，不扩大归因。


**Sol §9.9截止交接（候选待最终消费）：** 根native c61→5847821b/测试92b59587，backdrop屏障最小差分[0ed134b0](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-interaction-from-c61.patch)严格重放，生产selector RED12项5失败→ASan12/12；头/ABI和window74未改。真实命中及Tab已有范围、旧页面8/Apply与9/Cancel及保存的完整owner读回保留；Rules scoped-ID旧解码和跨owner预填归因已交DS，正常编译消费main7a，正确预填与实际文本/布尔仅取得callback/AX范围。三实例1800秒监督强清理使正常退出与余下链缺证，停止再启，不算生产RED或整包通过。[结果与余项](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md#sol-runtime-stage9-interaction)、[源/原件/空间交接](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-converge9-interaction-ready.json)。前台及共享target已释放，自有进程/已知endpoint/私有工作目录清理；剩余正常链并回DS §16.6最终候选一次验证，不重跑旧矩阵或另导SDK。

**指导最终交接复核：** 本次共同native584/fixture92最小差分、selector原件、正常两候选源/EXE及旧页面owner保存子链已限域复核，Sol执行收尾完成。自有进程/endpoint/工作与数据目录清理及前台/共享target释放已核，DS现有sdk-73c69772的相关四份输入同字节可直接复用。三次监督强清理及7a完整正常链缺证保持；剩余验收已并入DS原§16.6，不再由Sol重复开窗。本包无剩余执行事项，专属跟进结束；详见RESULT本节指导复核与ACTIVE，后续只按实际新问题派必要返工。

<a id="sol-runtime-first-ready-20261027"></a>
### 9.10 2026-10-27 用户要求安排并行工作：首次载入的共同就绪与候选交接

**本次新交付后的当前接续优先。** DS已交sdk-4725654d：generated3a89168e/region8ab120cf、Rules main31985/providerf35f/testc7ab，window74/native584不变。指导已核604文件及5源差分、测试输入归档和原件，见[472复核](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/RESULT.md#ds51-section16-followup-review-20261027)。先审阅这份已有“carrier超越保PENDING、同token重载”修复与native契约，不在旧73独立重造；73仅为失败/差分基底。P1/P2成功载入的rollback均token0/pending0，文档token1直接commit，并未证明新分支真机通过。Rules无窗口反例原始PASSED和三项文件保护绿证可复用；holder两项现存run2 wrapper exit0，原case日志被目录复用覆盖，source仍保真，不能混用后续保护测试日志。必要高风险衔接由你按本节离线区分，不随机开窗撞样本、不写DS源。指导已直接传达此调整。首键重输及生成卡裁剪先留DS原包归因；原图不支持“完整可见却AX缺失”，本线不扩为AX专项。

**授权与取舍。** 用户本轮问“sol那边呢？要等ds吗？还是可以先安排任务”，指导沿此前直接派工/回报授权，下发本有限工作包。§9.9已交接，不重启其三次超时的窗口链。当前框架缺口是正常界面文档首次载入可能被初始场景变动取消、继而落到默认seed；它影响人和AI保存的界面能否可靠接续。先明确共同就绪事实与失效责任，比再加样例或做一轮无动作关联的性能表更有价值。性能/物理呈现旧未知保留；已有FrameCadence presented hook及owner/dispatch观测只按本问题需要复用，不另造诊断框架。

**冻结依据。** 先读AGENTS、ACTIVE自己的当前段、本节及DS[最终原件复核](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/RESULT.md#ds51-section16-final-review-20261027)。故障输入为sdk-73c69772的main7a、window74、native584；直接原件在`runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-16.6-20261026/rules/final-acceptance-20261027/`。PID23061的`exit-reopen.log`：static_layout_basis_changed→文档token1 native_source_superseded→document rejected→默认seed token2 accepted；PID24362/24583后来同文件成功不能消除前次失败。原件既不证明文件坏，也尚未证明native拒绝错误。

当前共同根native `5847821bfff4325a2ffe21efbf191b58a0e56a9affd265a8337a72fe9caf98da`、window `74b7db97935a51511898eccf4b03ddc2dfc04e3f279c05980c6efbbd0c12c6d8`、renderer session `dda4a5527ae32ddcbb40be4c97f7a4126de003b29de649a65abfc8c516d323eb`、header `ed8f886f952fa9eb2c6fc584fd1899c7636e272c2ca7be2344b909599bb059d4`已核。开工核实是否仍同字节；冻结SDK只读，DS根消费者正在变化（指导观察已从cbd43到31985），不能把其WIP抓为本线输入。旧Sol归档与已接受测试按原身份复用。

**Sol连续完成的共同部分：**

1. 从现有host/pump、windowProjection、native preparation和A1 query/acknowledge语义查清“可以提交首次文档”的已有事实。区分提交帧号、已接受场景、待结算票据、布局基底、native文字/焦点源及generation；不能仅凭名字把submittedFrameIndex当所有阶段已完成，也不能设计“从此永不变化”的ready。用最短因果路径说明token1为何在该阶段被取消，现有公开/包内入口应怎样调用、哪些情形必须拒绝。
2. 做能区分共同缺陷与应用过早/错误接线的最小生产路径反例，先离线/无窗口。若共同实现符合契约，交源码依据和可直接采用的调用顺序，不为交补丁制造改动；若证明共同就绪、准备失效或结算交接有缺陷，在一个受控目录形成最小修复与相关RED/GREEN。优先用既有机制，只有确实缺少表达条件时才补最小兼容入口，给出签名/实际调用方；不改40B FrameObservation ABI、不扩公共协议/状态机。改变失效/异步责任时覆盖相应的有效源变化、旧候选拒绝、迟到完成/关闭及generation隔离，不能让过时source被接受。
3. 交精确基底→目标差分、必要原件/源及构建身份、应用应采用的条件和未验范围。指导核共同增量后才协调回根与DS最终消费。若只有应用接线问题，明确交可执行条件即完成本线；正常加载/保存/重开由DS在同一最终链承担，不让两边重复。共同结论已可解除DS依赖或候选就绪时集中回指导，不等用户转述。

**并行写集和前台。** DS继续负责Rules/mixed消费者、组合/generated、文档session/工作区、公共工具/client/exporter和唯一SDK，保其当前源码、测试、target及实例。Sol只处理共同window/renderer/必要host内部接缝及对应测试；本轮先不原位写共同根文件，私有编译闭包和一个构建目录受控，不用DS的SDK/共享target构建，不复制整仓/旧产物树。DS独占当前前台，Sol不得启动普通、隐藏或会自动重开的验收实例；不以进程空闲/时间经过推断释放。确需前台才能区分时，先交已得归因、最小具体待验段及输入身份，指导统一协调，独立工作继续。无延时、补点、重发或重启刷绿；协议内合法重准备必须有新事实、明确版本/责任和反例，不与盲重投混用。无可信文件观察的同名覆盖拒绝归DS保留，本线不得放宽或伪造基线。

**资源与回报。** 沿原E留存≤13.15GiB、峰≤14GiB、宿主峰后≥20GiB，旧占用不清零、不另加10GiB；上一已核留存约13.09882GiB，指导本次宿主约222.77GiB，开工再核。离线包先预算源码闭包、一次构建、必要RED/GREEN与差分；复用、保真归档后准确退役自有可再生产物，成功/失败/取消均收尾，不猜删唯一RED/DS/用户产物，不为几KiB反复压缩。保当前主模型；按用户明确授权可委派`gpt-6-luna`，档位按难度，Luna只回Sol，无额外顾问/用户线程/子代理定时。完成或实质阻塞主动发给local指导`01a17207-04bc-76a2-90c3-99c8c5060423`，不回旧线程、不要求用户搬运或同义确认。无Git写，不恢复旧性能矩阵、双窗/IME门、旧平台或独立C。

**2026-10-27 Sol共同部分结论。** 交[首次载入调用契约与审阅](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-first-ready-contract.md)、[原件审计](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-first-ready-evidence-audit.json)及[源身份/空间账](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-first-ready-closure.json)。保留DS现有472的generated/region/Rules适配：同token逻辑候选可保持PENDING，但旧native载体必须取消，重新构建准备并核当前源；没有证据要求新增host/window/native补丁。host.start、准备就绪、A1非零present票据、windowProjection帧号与文档ticket分别判断，按准确token ACCEPTED采用实际读入digest，不以默认seed或其他版本增长替代。旧失败具体native字段未留，P1/P2未命中新文档恢复分支；Rules定向原件复用，holder源归档/run2 exit0与缺失原stdout/源绑定限制分开。另交DS一个源码可达的应用边界：240轮后仍PENDING只能报未完成，启动token稍后接受时仍需完成loaded/文件baseline关联；现未取得该超限运行样本，不冒称native故障。本线没有生产源差分/构建/窗口/SDK，40B ABI及runtime_state/renderer_state未写；原E计费延续，零释放，前台及共享target始终留DS。正常载入/保存/重开仍由DS原包收尾，不重开随机窗口或旧矩阵。

**指导接收：§9.10本线收尾完成。** 已核三份交接材料的closure SHA、四份共同源身份、三份原始运行日志SHA及四份材料实际分配36864B，沿原计费未超上限。新增源码可达边界亦核冻结main31985：4768–4782把预算结束仍PENDING归入REJECTED，4784–4789仅立即成功路径建立文件关联；finishUiDocumentAction只收documentWorkspace自己的提交。611–613已防pending/accepted时默认seed覆盖，不把缺口扩大成必定覆盖。接受本次共同契约与已有适配的限域审阅，原真实token1恢复/具体native首拒绝字段未验继续保留，不要求为本线收尾另开窗口或补同义确认。应用预算后接续、准确token与文件观察关联已补入DS原§16.6，Sol无剩余执行事项；不因DS仍有首键/裁剪而让本线空转或另造新阶段。

<a id="sol-runtime-text-writeback-20261027"></a>
## §9.11 已出现文本回退的归因与必要共同修复（2026-10-27，指导直接下发）

这是用户原整包的真实输入缺口接续，§9.10仍已完成；不重开载入审阅、旧性能矩阵或平台工作。推进的框架能力是：人类编辑经共同输入完成协议写入owner后，普通投影/失焦/Apply不得把旧投影当新编辑回灌。复用window74/native584已有pending local text、候选与preserve basis失效、事件续接和owned拒绝机制，不另造应用补丁或并行状态机。

**事实与待区分。** 输入基底为DS冻结`sdk-629a50e2`，604文件SHA/长度已核，相对472仅main b21915f6129baa30e0d055e1193a966108070134b418f90b399708446a325385及source-lock变化；共同window74/native584保持。原件在`runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-16.6-20261026/rules/followup-20261027/`：原app1.log:860是field-notes kind28 size37，:885变36，:887才有accepted_input rollback；公开after-page-apply是B字段v2且无7，:984重输才保住7。真实回退成立，rollback在旧值事件之后，不能倒因为果。新loss-attribution读回来自另一次P4成功链（v1含7→Apply v2含7），不能代替原失败当时的v1原件，也不能仅凭v2排除原次Cancel/误点。DS给window6738–6769、10928–10937、11645–11665是排查入口，尚不是已定位的旧值生产者。P5正常短链/276B存档与P7布局通过均复用，不算原缺陷已修。

**执行。** 先离线从kind28的实际产生→native队列/源身份→窗口投递→owner写入及随后投影查清因果；核旧输入/命中原件的存在性，缺失就具名，不靠新成功链补造。区分真正人类删除/取消、程序投影回写、陈旧callback、失焦提交及预备包退休。必要时查现有本地参考实现。用既有生产入口建立能区别假设的最小反例，根因明确后最小修共同归属，并验证合法Backspace/Cancel/拒绝仍成立；不得在应用丢弃所有较短值/等于旧基线的事件来救绿。保FIFO、owner/版本/候选身份、native生命周期和owned校准/退休/选择拒绝、默认OFF成本。不改DS消费者、generated/composition、文档session/workspace、公共工具/client/exporter、唯一SDK或其冻结树。共同差分先受控，未经汇合不原位换根源。

本次先离线，不启动普通/隐藏/会自动重开的实例，不占共享target；一个私有可复用构建目录，按风险做有区分力的RED→最小修→相关GREEN。需要真实输入才能作出下一决定时，把具体缺口、源身份及最小动作交指导一次协调；无新判别证据不继续8–12秒间隔的随机重演，不复用已失效app对象，不开旧§9.9第四轮。最终受影响正常消费与DS唯一候选汇合一次；旧绿证按身份复用。若现有证据无法锁定生产者，给出排除项、剩余假设及最小可判别方案，不能以“共同层已定案”结项或猜改。

沿原E计费，最近已核约13.0963GiB，留存≤13.15GiB/峰≤14GiB/宿主峰后≥20GiB，开工实测、复用目录、保唯一失败原件，成功/失败/取消清理自有可再生产物并给实际空间账；不清零旧占用、不另加10GiB。Sol主责，可按用户授权委派gpt-6-luna，档位按需，Luna只回Sol；无顾问/Git写/新用户线程/子代理定时。完成或实质阻塞直接回本指导local/01a17207-04bc-76a2-90c3-99c8c5060423，不回旧指导，不要用户搬运。DS的迟到票据接线独立修，不作为本次离线工作的前置。

**Sol最终离线收尾（原回退仍未结案）。** [归因/失败边界](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-text-writeback-attribution.md)、[最终源/原始运行/空间身份](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/runtime-text-writeback-handoff.json)。唯一采集PID92927在首次公开instances读回即被错误ID断言截断：实际rule2 notes805003/owner2；原200000036由详情公式对应record2/index4 notes，两者是同owner/field的不同控件，不能要求ID相等或替换原路径。未发GUI输入/7/Apply、未取得owner/v1；未立即收口后由300秒cap强退-15，非正常关闭、生产RED、原P1复现或修复。工具按真实实例联结和失败同PID停止已仅作离线检查，不再开应用。观察638已去掉swap内重日志，该函数与584逐字一致；ON20/OFF0与合法缩短/Cancel仅按native合成ack范围成立，40B ABI不变。629闭包+已核main556+638的正常EXE73c16094和实际archive5ae5已保真归档，启动文档token1 ACCEPTED但不替代输入验收。根window74/native584、DS/SDK/共享target未写。精确私有PID/endpoint与本轮convergence-work已退役；前台释放DS，原E计费及空间账见最终身份。原P1缺逐事件正文/didApply/瞬时v1，不以P4补证；没有共同业务修复，观察不入SDK。

<a id="sol-text-writeback-capture-guidance-20261027"></a>
**指导审阅与一次采集授权（2026-10-27）。** DS应用差分已按[原件复核](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/RESULT.md#ds51-section16-startup-settlement-review-20261027)接受；DS明确写实释放前台/共享target，指导核当前仅受保护ds55 PID94477。Sol可在下述观察接线收窄、自验后直接用前台做本次§9.11的一条判别链，无需再请用户转交或批准；启动前若出现新的明确占用则协调。保持一个私有构建目录，不使用DS冻结工作树/target、不改根或SDK。

先修临时观察差分的确定问题：db82在`swapPrivateInputGraphWith:`前后调用重日志，违背此函数“无分配/通知/回调/销毁”的发布约束；回退调用还位于selection-transfer cell锁内。该函数内不得做JSON/base64、AppKit正文读取、堆栈或stderr输出。移除这些调用，确需交换标记时只在合法安全点输出已捕获的标量，不为观察引入新的队列/线程/状态机。现有主线程泵负责dequeue，不凭调用名称另造跨线程问题；按实际入口保线程与生命周期约束。只补受影响观察开关/编译检查，观察不是业务修复、不进入唯一SDK。交接中的attribution.md已写后变化，最终冻结时校正其hash即可，不重跑旧探针矩阵。

输入冻结为629闭包+已核main556（补丁与测试见DS原件）/window74/native584及收窄后的私有观察差分，记清源/链接/实际EXE。准备与几何定位完成后启动短会话：原规则乙36字节底本、准确owner/field、一次真实7→立即读完整draft及版本→单次真页面Apply→读同owner完整draft/applied/版本与画面，保原输入、队列正文和回调来源。DS正常读取JSON中的fields.owner=-1、draft_version/state_version=null不能充当这次完整owner版本证据；使用实际实例/TARGETS和原始公开字段/上下文组成可核身份。已知合成ack、NSApp.currentEvent或旧成功P4仍不能替代因果。完成正常保存/关闭与自有endpoint收尾；若本次不复现，只报告本次结果及剩余因果，不循环撞现象；首个具体工具失败即保全/清理/升级，不复用旧app对象、延长时限或开随机窗口。原§9.9及性能矩阵不恢复。沿原E留存13.15GiB/峰14GiB/宿主峰后20GiB，开工核余额，复用/退役自有可再生产物，集中回本指导。

**本次采集停止与前台交接（2026-10-27，取代上段待启动状态）。** Sol主动回报安全观察638/EXE73c16094/native archive5ae5d7c9，文档token1 ACCEPTED且apiReady；首次定位脚本将native节点200000036当作公开INSTANCE.id查找，未匹配真实`rule2 element=notes id805003 owner2`而断言失败。尚未发送7/Apply或任何GUI输入，也未取得完整owner/v1链；随后监督器300秒cap强退-15，不能称正常关闭、生产RED、原P1复现或修复。以上运行细节先按Sol报告记录，最终源/raw/空间原件待集中交接复核。指导已核当前PID92927不在，`/private/tmp/tmpDirDFcGwj`及其socket/descriptor均不存在，仅见受保护ds55，明确释放成立。DS§17原包可串行继续正常消费，不接诊断候选、不代跑Sol归因、不要求用户再转同义消息。Sol只余离线修定位/失败即停采集工具、保真归档及自有产物退休，不开第二次应用；原37→36因果保持未定案，观察不入SDK。已直接回Sol，无额外监控或新阶段。


<a id="sol-text-writeback-guidance-closeout-20261027"></a>
**指导最终限域复核（2026-10-27）。** 接受本轮离线交接与自有资源收尾，原P1的37→36仍未定因，§9.11的共同业务修复未完成。handoff完整SHA `ef295acc2555409ca15bf89355d72ccda0f46dd43feb0681996539bb350eb5c8`及其中67份材料的SHA/长度均匹配；四归档可读，关键成员main556/window74/header、观察638、实际EXE73c16094和native archive5ae5与交接一致。第四归档以完整SHA `64169dfd260a987efa3a66914a891aec41ff2237bb1eab72a7306e53464a933d`为准，消息中的c2速记已更正。共同根window/native/header/renderer-session四哈希仍匹配，私有PID92927、准确tmpDirDFcGwj及convergence-work均不存在。

源与原回包支持两种notes控件按同owner/field联结，不能要求id相等或改变原手写输入路径。核采集入口已在参数处理前注册失败收尾，向同PID监督器原子发布停止请求，过期记录不重开；其现有证明限于保存回包及缺日志/参数错误的离线fixture，未测在线停止时延。process原件明确300秒cap、forced_cleanup、exit -15；首错文件自己标明是整理摘要而非原始traceback。原37字节输入是否到达owner、didApply、瞬时v1及后续36字节来源仍无同次证据；合成ack、另一成功链与本次初始窗口不能补成复现或修复。

**执行安排。** 本轮Sol到此收尾，不开第二次应用、不再重编或重复验证，不要求再回同义确认；观察638不接根或SDK。DS按已授权§17继续自己的正常消费，无需等Sol本轮，且不代跑本缺陷归因；H独立同源复用不与此混派。原P1保持具名未解决，后续是否恢复归因按新的可判别证据与投入收益重新决策，不自动再开窗口或追加观察工程。无新增监控/阶段。原E空间账接受为其采样及计费范围：净留存20.62MiB、累计13.1159GiB，已测最高13.3241GiB不冒充连续峰值；退役分配量220.20MiB与卷净增157.26MiB分开，宿主208.12GiB为报告采样时值。本次指导只读核验及更新此段/ACTIVE，未跑应用或生产测试。


<a id="sol-text-writeback-integer-counterexample-20261027"></a>
**§9.11新增整数输入反例接续（2026-10-27，指导下发）。** 上述旧采集与离线归档仍已收尾；本次接续由DS新交付的实际反例触发，不重跑旧37→36会话。目标仍是连续输入、owner写入和普通投影之间的正文一致性，复用现有pending local text、accepted scene与完成协议，不另造平台/应用状态机。

指导已核[DS原始应用日志](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/mixed-input-failure-original.log)、[首次现场记录](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/mixed-input-failure.json)、同目录截图/AX及实际CUA调用：点击当前AX34 → super+a → 3 → 1，无补点/重发。初值4，目标31，截图/AX为41、草稿v2/已应用v0=4。日志22先为cardA copies applied=true text=[3]，23为target920/scene2的VISUAL_RECOVERY，25再为applied=true text=[41]；恢复记录是待查接缝，时序本身不证明因果。真实EXE0c12c2c5完整SHA与原构建身份一致；私有main945217f0及preset_cards02641a89仍匹配，setText确实先写draft再增字段/draft/revision，应用applied日志指该写入返回，不能解读成用户点击Apply。公开unknown_owner/unknown_resource/unauthorized_action原件保留，缺失的同次完整owner读回不由6200、-1/null或后续接纳后的事实替代。新INTEGER反例与原TEXT 37→36是否同根仍待证明。

**Sol现在先离线接续，不以DS整包完成作为前置。** 以DS冻结sdk-a94f15d7的window74/native584与上述确切应用输入为对照，追首次3写入后：投影构造读取哪个owner/字段版本、提交/接受哪一帧、whole-value编辑器/代理与视觉恢复实际使用哪份正文、随后1为何变成41。先排除具体应用投影/绑定错误，再在共同输入/呈现归属建立有生产可达性的最小区分反例；不将整数入口套成TEXT owned-range，不预设Unicode/IME或calibration为根因。根因明确后，在本线私有受控差分完成必要修复及不启窗口的定向RED/GREEN，保合法删除、替换、Cancel、版本/迟到拒绝与FIFO。应用根因则给DS精确归属与最小修改建议交指导，不改DS写集；证据不够就指出能改变决策的单个缺口，不持续添加观察/压测工程。

本次仍不授予新前台：不启动普通/隐藏应用，不占共享target，不改DS frozen SDK、生成/公共工具/消费者或H写集。只在受控差分确需正常消费时集中交冻结身份、最小动作与前台需求，由指导按DS明确释放协调；不拿无窗口、进程消失或租约到期当释放依据。DS按其已报告安排继续独立公开写读/文档与Rules消费，失败键盘链保留未验，候选不升级成全量通过。其真实回报线程已确认是local/01a17bea-9bcd-7872-a89b-2e357baf2311，本次读取不等于另向该线程派发消息。

沿原E计费13.1159GiB起算，留存≤13.15GiB/峰≤14GiB、宿主峰后≥20GiB，复用一个本线工作目录；先核余额，只恢复必要源/产物，保护原唯一失败，不递归复制DS target/artifacts，不清零额度。Sol主责，可按用户既有授权委派gpt-6-luna处理明确离线工作；无额外顾问/Git写。旧绿证按身份复用，不重跑历史矩阵；持续完成已明确的独立工作后集中回本指导，无新自动化或新阶段编号。


**Sol整数离线交接（待正常消费）。** [结果/边界](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-input-attribution.md)、[精确交接](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-input-handoff.json)。应用main945/cards026的整值writer及draft投影未发现把3改41；native584实际NSTextView/FIFO确认同次28+51额外投递，无恢复时第二键为31。共同窗口普通恢复未核旧场景接纳版本是否仍等于实时controller/owner，可能以旧4回灌。真实recover函数无窗口反例同源六例RED3过3失败，stale尝试3次且native返回INVALID_SESSION11；私有版本核对后GREEN6过。生产差分只在非visual且无同身份owned绑定的路径等待新接纳版本，保pending/重试及既有事件协议；测试接线另存。去hook实际生产源6ca32632再次skip-script构建0，库b39fb19a；测试函数与其逐字相同，不把带hook构建当生产候选。真实INTEGER Backspace/替换与合成Cancel投影限域通过；当前Cj Cancel只证明可进入恢复，不证明真实proxy成功。根window74/native584/SDK/DS/H未写，无窗口/共享target/Git/顾问。原次公开owner/恢复正文仍缺，原TEXT是否同因未知。源码/实际测试程序与生产库两归档逐成员核后，唯一私有工作目录已退休；空间沿原E账见handoff。下一步只需指导协调一次同源mixed正常31及完整owner/版本、Apply/保存/正常close，不能复用旧AX或事后准入补证。用户最新允许6.1Terra/6Luna及自主档位，本轮复用既有6Luna。

<a id="sol-integer-candidate-review-20261027"></a>
**指导复核与必要离线返工（2026-10-27）。** 交接b23439df所列55份材料SHA/长度一致；生产patch67de9cdb从根74严格重放得到6ca，测试接线继续严格重放得到bd83，两者恢复函数字节一致。源码归档537文件及二进制归档7文件中的窗口、测试、生产库b39、测试程序6072等关键成员身份一致；原件确为六例RED3失败→GREEN全过。接受这些限域证据，不把session=0的INVALID_SESSION或合成Cancel当正常proxy成功，也不把新INTEGER归因移给旧TEXT37→36。

**6ca尚不能直接进入最终消费：需先修刷新推进衔接。** 其过期分支每次调用`requestRefresh()`；共同窗口4109–4117先调用`cancelPreparedCandidate("request_changed")`并推进请求代际，10808起会撤销真实static layout/preparing candidate。pump在空事件时也可走5590的break而后到6925恢复；有输入时6906可能刚留下尚未完成的当前版本候选，恢复分支便再次取消它。这与“保pending等待该新版本完成”冲突，原六例未覆盖实际在途准备。Sol先在原私有写集建立有区分力的离线反例，复用现有请求合并/准备依赖/接受协议：源版本未再变时不得反复取消正在准备当前版本的候选或无故增加epoch，候选应能继续推进并在接纳后恢复；源版本确实再变时仍按原规则使旧候选失效。不要仅加延时、放宽版本判断、伪造accepted或新增一套等待状态机；不要机械按一个布尔标志吞掉真实的新请求。复用既有六例和适用拒绝边界，只补这一衔接及受影响构建，不重跑历史矩阵。

返工不等DS整包，也不授予新前台。DS当前在做组合公开预检，尚无本轮实际释放事实；返工交回后再按明确释放及同次公开owner可读条件协调一次mixed真实31/Apply/保存/正常关闭。应用main945/cards026/domain018与native584仍为冻结对照，若正常消费必须换应用接线，先明确受控差分，不能追DS在途源或在输入后才补准入来冒充前态。根/DS SDK/消费者/H保持各自归属，指导不接管实现。

为保全本次失败、候选与必要后续原件，并避免只剩约6MiB造成反复压缩/重建，当前§9.11留存上限调整为13.20GiB；原E已占13.1441GiB不清零，峰仍≤14GiB、宿主峰后≥20GiB（交接记录205.59GiB，本次指导实查205.45GiB）。增量只用于上述必要返工和最终受影响消费，复用一个工作目录与已有native，保留唯一RED和可复盘原件，不另导SDK或增加整套副本；成功/失败/取消均准确收尾并报告实际空间。Sol集中回本指导，不增加自动化或阶段编号。


**Sol准备推进返工交接（正常消费仍待协调）。** [实际结果与边界](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-request-attribution.md)、[精确身份/空间](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-request-handoff.json)。6.1Terra承接整包、Sol审查：真实在途static/prepared反例确认6ca重复恢复会取消候选（原9例RED7过2败）；初版又因exact-declared误取消依赖未变的信息更新，补独立11例RED9过2败。最终复用原声明/准备依赖、owner、request/binding/focus及basis匹配保留当前候选，不匹配仍走原requestRefresh；其公共实现逐字未变，无布尔吞新请求或等待状态机。11例GREEN全过、旧六例函数体不变；真实静态布局推进至session0的owner_preparation_capacity，未伪造或宣称accepted。去测试接线生产源c507a3b2构建0，库37edc928；6ca/15a只作历史，根74/native584/DS/H/SDK未写，native083复用。源码及实际测试程序/库逐成员归档后唯一私有树已退休；原E累积账和13.20/峰14见handoff。无窗口/共享target/Git/顾问。仍须指导按实际释放及输入前同次owner可读条件协调一次main945/cards026/domain018+c507的mixed31、Apply/保存/正常close；原TEXT同因未知。

**指导复核结论（2026-10-27）：c507接受为正常消费候选，离线返工收束。** handoff4365ff82所列63份材料SHA/长度一致；根74累计补丁及6ca增量分别严格重放得到c507，测试支持严格重放得到020e，两个生产函数与测试版本相同，公共requestRefresh逐字未改。核529/3归档中的生产源码、4068测试、37ed生产库、9043实际测试程序等关键成员；相对上一输入归档，共同源码仅窗口变更，测试移至独立tested目录。核两次原始RED分别为7/9、9/11，最终同一11例全过及去hook实际build exit0。对照既有preparation dependency契约，保留信息UI变化的准备工作不放宽owner/source拒绝。static真实推进至session0容量边界，不能称native接纳或31正常链通过；pending transaction冗余epoch不作为本轮新优化任务。根四SHA未变、私有树不存在；本轮账13.1762GiB/限13.20/峰14，宿主实查205.14GiB。无新证据不再追加离线测试或恢复候选构建。

下一步只协调现有正常消费门。DS最新回报正在离线补编译期组件预检与元素绑定，尚无本轮前台释放；两次租约结束不代替释放。另已核原公开查询在空生成区对cardA为unknown_owner，不能机械要求旧a94先按6301读回、失败后再改默认owner或事后注册补证。先由DS明确现有正常准入/同一草稿读回路径；如确实依赖正在修复的组合/绑定，则只交那份稳定最小差分及基底/定向原件，再与c507受控汇合，不追WIP，不等DS整包或另导SDK。正常链仍由Sol一次完成：输入前同次准确owner/field/正文/版本及初值4可读，当前真实控件全选后键入3→1，立即核31和画面，单次Apply、保存、正常关闭。指导已请求用户授权直连DS这条后来确认的线程，未向其发送消息，也尚未授予Sol前台；原Sol直接收发授权继续有效。

**DS主动交接到达，正常消费前台授权已生效（2026-10-27）。** DS随后主动明确“无自有窗口、前台暂交Sol、仅离线私有构建，待明示交回再开窗口”，ACTIVE已对应更新；指导当前相关进程核仅受保护ds55 PID94477。本轮释放依据已具备，不再沿用上段等待，也不要求用户转发。指导未主动向DS发消息；其主动交接足以推进已获授权的Sol正常链。

指导限域核DS `section-17-20261027/compiled-plan-final` 原件：新compiled预检用例RED1失败→GREEN1过，原compiled28过；使用testing native，非正常消费通过。source-inputs索引/归档中的 `src/composable_ui_runtime_composition.cj` 为795baf358ead99c2bfa56f11eaa826f1e4710f160a61ed0edd26b0cede5bebe3，根当前同字节；基底eebe2582逐字等于 `compiled-plan-before.cj` 和Sol已冻结输入。唯一生产差分在非runtime定义分支识别已注册compiled factory、计既有容器成本并保声明元素绑定；原runtime展开和真实子树审计未改。新测试a966e6d5在同归档；0项runtime筛选不算绿。接受795作为此次接入输入，不扩大为DS整包复核。既有main945/cards026/domain018仍在 `/private/tmp/ds17-mixed/src/` 且三SHA匹配。

Sol按原13.20GiB留存/14GiB峰和宿主20GiB余量，用唯一私有目录冻结实际完整消费输入，纳入c507窗口+上述归档795，复用normal native083（源584），不得链接DS测试native70f或追其他在途源。必要构建/签名/CLI请求及独立数据准备全部先完成，再启动一个可辨识自有mixed实例；不占共享target、不改DS/H/根/SDK。先通过既有正常生成/准入入口建立可公开读取的同一cardA草稿；在任何键入前确认完整正文、准确owner/field/版本和copies=4，不拿默认6200或后来准入补前态。再在当前实际手写copies控件（原920/6202、owner6301须从本实例核实）一轮全选→3→1，无中间等待/补点/重发；立即核31及画面、正文/版本，再单次Apply、按现有工作区保存界面文件并正常关闭，保退出码、endpoint清理与来源/链接身份。mixed内存业务不因此宣称有持久化数据库。

若公开前置或真实输入出现首个明确阻断，保原始请求/响应/输入和实际边界，安全清理自有实例并回报，不开第二轮、不延长租约或长时间带窗分析。成功或失败都明确释放前台并集中回本指导；仅本次受影响消费，不重跑历史矩阵、不另导SDK。DS已主动报告独立离线实施收尾且继续让出前台；Sol这条链结束、准确清理并经指导核实后，明确交回DS按原§17.4推进独立生成/公共/文档子链和精确SDK，不因旧TEXT首键未定因继续等待。Sol正常通过后再由指导复核并安排共同根回接及DS最终候选汇合；未通过的共同候选不自动纳入，旧输入缺证也不能补写为通过。

**正常构建归档身份裁决（2026-10-27）。** Sol在开窗前提交[preflight](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-normal-build-preflight.json)：sidecar083的production指纹不等同标准host的format=2缓存，标准入口会正常重编。指导直接解析私有083与DS正常host66ffc298实物，确认renderer、native_bridge、async_measure、async_bridge四对象各自SHA逐项相同；另核私有window c507、composition795、native584/headered8及13份应用源均匹配冻结身份。这是归档整体/缓存形式差额，不是已发现的Native实现变化。允许既有标准normal host构建，以上文“必须复用083整体SHA”为冻结条件的部分由此取代：保确切完整源输入、production参数及ABI，记录本次实际archive/四成员/最终链接和EXE身份；不把新归档称为083。正常重建得到不同容器哈希不需再次升级，也不为旧哈希新增私有缓存导入器、修改builder或伪造指纹。若成员不同先按本次实际构建源/参数归因，只有出现未授权源码/非正常参数或ABI变化才停止对应接入；不以相同源码的正常重编追加旧矩阵。尚未启动应用或输入，原一次正常链与前台授权继续。

**开窗前工具阻塞，前台交回DS（2026-10-27 15:39 UTC）。** 指导核[首次发现原件](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-normal-native-discovery.json)：`cua.getState`返回Mac locked且automatic unlock失败，apps为空、applicationStarted/inputSent均false。Sol已明确停止本次正常链并释放前台；指导当前相关进程仅见受保护ds55。现将前台归属交回DS原§17.4，不把归属交接写成锁屏已经解除。Sol只完成在途候选归档和自有目录退休，保实际构建/签名/链接与空间原件，不再UI探测、启动或修改锁屏设置。其报告标准build-only与严格签名通过、EXE d3edc374及normal renderer0d539342四对象同083，完整交接到达后再核；真实31/同次owner/Apply/保存/正常close全部未验，不计生产RED，也不把构建成功当正常链成功。后续获得确切解锁事实后由指导协调当时前台归属，只补未验链；DS可先完成不依赖可见输入的独立工作，旧首键缺口不阻塞这些事项。

**本轮归档收尾已复核，DS可消费源码候选。** 指导核最终result dce676f4的19份材料SHA/长度、候选83d1a14b全部40文件；实际normal build0/签名原件、production/testing=false、4个真实link成员与EXE d3ed、renderer0d53/launcher28d1身份相符，唯一私有树已不存在。本轮新增留存10.55MiB，最终保守计费13.1869GiB≤13.20、峰上界13.337GiB≤14，释放180.66MiB；最终账已含normal-public-definition，不能沿用较早retirement字段少算它。锁屏与真实门未验保持。本轮不再给Sol新UI任务；将31门并入DS解锁后的原正常mixed链，公共接入与共同机制仍各归原执行方，失败时保原件交回归因。

应DS明确询问，已在[DS§17.4当前冻结交接](2026-10-24-ds51-normal-workspace-delivery-blueprint.md#ds17-sol-c507-candidate-20261027)列唯一允许消费的74→c507生产文件/精确补丁与全部原件身份。允许DS只在私有冻结树与待验收SDK中消费c507；不改共同根、不收入诊断/测试接线、不把正常构建当真实31通过。根当前74，正常证据完成后仍由Sol负责回接；DS不必等旧TEXT定因才能离线组装候选，629/472已有交付地位和真实验收门保持。指导已更新共享阶段说明，未向尚缺直接用户消息授权的DS线程发送跨线程消息。

<a id="sol-h-composition-readonly-20261028"></a>
**H组合反例的有限离线归因（2026-10-28，指导接续；不恢复Sol前台）。** 用户提交H报告并询问Sol停工；实时快照确认Sol按上一交接收尾，DS随后明确用户已解锁，正用cc928/mixed9b92/Rulesf9c3执行原§17.4。c507正常验收与未来共同根回接仍按原安排，不等本项。此次复用H已有反例和构建原件，目标是把合法组合定义在OHOS被误拒的问题交回准确归属；不新建Goal、阶段号、监控或H完整移植任务。

指导已核[H原始交接](../../runtime/cjgui/platforms/ohos/evidence/harmonyos-common-integration-20261027/main_core/composition_runtime/HANDOFF_frozen_core_composition_cycle.md)及`discriminating_20261027`、实际`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/workspace6_clean_probe`、`workspace7_probe2`、`workspace9_final`日志。后两轮PID25641/21433原日志均为defs=1、核心graph返回空名cycle、App取名完整。冻结清单cf43815a/组合源eebe与lab副本一致；根当前795仅多compiled-factory展开计划，477–529图检查没有差分。H文档的根922为旧快照，报告中的`ohos_cjgui_smoke`路径应为`ohos_cangjie_smoke`。宿主探针输出为空，但引用的`target/release`实际库/符号身份仍须核，不能只凭import源码认定完全同源同模块。

Sol本项只读审查共同图检查、实际H消费/编译/链接证据及现有二进制，可在自己原证据目录写一份简短归因/交接；不改生产/测试源、DS composition与候选、H main_core/snapshot/lab/脚本，不构建、不运行设备/桌面、不占共享target。优先回答：原函数执行体/符号解析与HAP实际库是否对得上；空名来自哪一边界；当前证据究竟排除了什么。`ohos_app.cj:468–494`的App复刻省去byName/get/ref遍历，并加入逐步日志与step<8，只有单叶子控制组，不是完整函数的无插桩等价对照；不能据此确认编译器bug、所有合法定义都失败或将图检查改写为另一算法。O0尝试仍经llc -O2且139退出，不算有效优化级对照。

交付为有依据的归因及至多一个能区分余下假设的最小实验方案，明确保持相同SDK/目标/生产参数和实际调用身份，怎样区分模块/泛型/优化/链接问题；无需把已排除路径再跑一遍。若必须H设备或共同源码变动，给精确接口/文件/基底/预期和归属后回指导协调，DS仍拥有composition实现，H拥有平台消费与工具链构建；本项不授权Sol改其写集或私有重写算法。沿原E13.20GiB留存/14GiB峰、宿主峰后20GiB，不复制整树、反复归档或另建SDK，无Git/额外顾问。按现有授权可用Luna协助只读窄项但不必为此另起代理；完成直接回本指导，不等DS整包。

<a id="sol-static-mode-refusal-20261028"></a>
**cc928真实切换失败优先接续（2026-10-28）。** DS在已解锁的原§17.4正常链交首败；[原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/cc-mode-rejection.json)、[原日志](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/cc-mode-rejection-original.log)、[完整AX](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/cc-generated-detailA-full.ax.txt)与[画面](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/cc-generated-detailA.png)已由指导核对。PID84110/EXE9b92、window c507/composition795/native584仍是本次冻结。一次preset-detail-mode点击后日志mode=generated/cardA紧跟static_layout_build_basis_changed，AX及截图仍手写详情、按钮仍“切到生成详情”；未补点或重投。认定实际切换失败，尚未断言其必由c507引入。

同次已有绿证按原范围复用：generate终态ACCEPTED v1/token1；输入前A6301/B6302三字段完整读回及初值4/2；真实日志setText3→31、其后首次完整A读回draft31/applied4、draft/field版本2；单次UI Apply后applied31、appliedVersion2。公开A40/B42、reorder v2保两稿；一次UI CancelA回31，B42保留。指导已核这些独立原件，未知显示时延不外推性能；旧TEXT37→36同因仍未知。切换失败不抹除上述子链，也不能因此提升SDK或宣称整个正常包通过。

Sol先保存H只读归因已有结论，优先本条必要返工：沿点击、应用模式/声明/owner变化、static布局basis冻结与复核、拒绝后的正常推进定位，区分构建中改变basis、共同恢复/刷新调度错误，或正确拒旧但新任务未推进；对照c507增量与74适用路径。共同window/runtime契约内根因明确后，可在一个私有受控差分保有区分力RED并最小修复/相关离线验证，不删除basis/版本/owner/FIFO保护，不强制接纳、重复提交、延时/补点救绿。若根因属DS composition或应用，给精确归属/建议后交回，不能越写；H、DS候选/消费者、共同根和native冻结保持。此次扩展的是本包真实失败的必要接续，不是H工具链实验授权。

前台仍由DS完成不依赖切换的独立项并及时保存/正常退出，不能为Sol分析长期带窗或延长租约。Sol不动DS实例、不自行开窗或抢共享target；离线结果交指导后，再按准确释放集中受影响正常消费，不重跑31绿证或旧全矩阵。沿原E13.20GiB留存/14GiB峰、宿主峰后20GiB，写盘前核剩余与回收点，保原件不复制整树；若必要净增超额，报最小实际需要由指导裁决，不循环压缩或清理他方。H有限归因留在本节前项，待本条安排稳定后接续，不丢弃原任务。

**H只读交付已限域复核并交接（2026-10-28）。** 归因7640b186、代码身份2403ebf8及完整反汇编4d5362d3成立：指导独立核fba8与a9d7的.text/图函数逐字一致，真实pop路径清槽后才取name/phase。具体pass/集合泛型责任未定，未观察运行时函数地址。指导复核时可变HAP已由原4536变e6c90986而core仍fba8，不混写整包身份。H的一次同SDK/目标/生产参数、完整函数只换名的App对照及独立项接续已写入[H现有README](../../runtime/cjgui/platforms/ohos/evidence/harmonyos-common-integration-20261027/README.md#h-graph-pop-code-review-20261028)，无H直发通道，不宣称已送达。Sol此只读工作可收束，当前继续DS模式拒绝必要返工；无需构建/等待H或重跑已有归因。共同composition归DS，不授权H改图算法/工具链，必要绕行看对照结果后集中协调。

<a id="sol-mode-diagnostic-normal-20261028"></a>
**DS独立正常链已核，前台与一次分项诊断授权生效（2026-10-28）。** [DS总入口](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/normal/cc-normal-chain-result.json)及[空间账](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-17-20261027/space-after-normal.json)已核：四受控84110/4964/18993/25973的日志SHA、exit0/native destroy/endpoint自清，两EXE仍9b92/f9c3；mixed保存7741B/文件4042/结构bf302，原路径重开accepted v1及双owner内存初态4/2成立。stale_draft3对当前4拒绝，完整字段前后相同。Rules真实停用/Apply/保存重开false，业务文件逐字仅第二条enabled1→0，UI1856B/a1a不变；公开owner=-1/版本缺失仍unknown。额外无参3074单列关闭，不充作重开证明。DS明确释放，指导当前仅见受保护ds55；已直接把必要前台/target交Sol，DS不带窗等待。后续public ApplyB才推进generated是新线索，不能补首次失败。

[Sol离线归因](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-basis-attribution.md)、[handoff368fbbb7](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-basis-final-handoff.json)22份材料与归档3成员SHA/长度已核。两轮近似controller没有真实accepted native场景/现场会话，也未走原guard，只排除所构前态的简单build自增，不是原失败RED/GREEN；六段函数74/c507相同不证明全部运行时等价，旧owned TEXT仍无现场事实。停止扩无窗口变体和猜改调度。[dd0诊断提案](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-basis-diagnostic-proposal.patch)严格从c507重放成立。

允许Sol在私有正常候选保原短路顺序、读取次数、拒绝reason/rollback，记录首个component及原计算中已取得的expected/current；日志不额外调用controller/provider/selection/native getter，不读取短路未到项，不能无副作用取得的写unknown，不加刷新/强制接纳。对照同冻结应用/795/native，记实际production源、EXE/link身份，用原实际请求/可复核输入建必要前态，不把lossless=false重编码当原输入。只做一次受影响mode链，不另验31/历史矩阵；准备在启动前完成，不能重现则保首次结果与前态差异，不循环启动、延时补点/重投。根因明确且在共同契约内可继续最小私有修复与受影响验证；若归DS应用/alias或仍缺决定性事实，准确收尾释放后集中交指导，不越写或猜修。诊断不入根/DS SDK，629/472不提升。DS待受控差分接原剩余续写和最终汇合，不重复确认或重导包。

**原E空间裁决：** 精确账14,168,846,336B，旧13.20GiB余4,545,740B；指导实查宿主219,597,246,464B。按执行者所报差分候选及原件需要，仅调留存至13.21GiB（14,184,129,495B），旧占用不清零，新增预留≤9MiB；峰仍14GiB、宿主峰后≥20GiB。复用旧完整签名bundle83d1及一个W（预计≤512MiB），新增只留实际bundle差分、必要输入/日志/帧和真实链接身份；Info.plist等若变亦须纳入，不能只保EXE。原件1MiB是预估，可在总9MiB内调配，不截断关键序列或为分项小额反复请示；总额确实不足再报净需。成功/失败/取消均归档后准确退休W与实例，保唯一RED，不新导SDK或猜删他方。执行者补充本线程更晚的人类6.1Terra/6Luna授权，按其最新授权继续，不因旧摘要改模型或重跑。

**本次唯一启动与收尾（2026-10-28）：** Sol回报EXE341c778a/PID77158 ready后，admit的Capture构造给frozen SharedOperationClient.request赋值，抛FrozenInstanceError；指导核[首失败](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-live-public-evidence/admit/failure.json)、[进程结果](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-live-process.json)及[准确endpoint收尾](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-live-endpoint-cleanup.json)。Sol报告capabilities/submit、UI输入及mode均未发生；本次是采集工具兼容失败，旧生产问题仍未知。首败停止后exit-15、native_self_cleanup=false，不能写正常关闭；准确目录已人工清理，Sol明确释放前台且未触碰ds55。当前仅离线修工具对不可变真实SDK类的兼容、保原失败/8076源、归档已建候选相对83d1完整bundle的实际delta并退役W，完成集中回指导；没有授予第二轮启动。DS暂待受控共同差分，不重跑正常链。

**工具交付复核与原包接续（2026-10-28）：** 指导核[最终交接65c08a80](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-live-final-handoff.json)全部35材料SHA/长度、c2b差异归档12成员及83d1基底；SDK client73ea/generated cc59与原件一致，b16补丁严格从c507重放得到eec538，原声明/依赖的单次读取与后续短路保持。4772用实际frozen类子类拦截继承调用，原client不变；离线真实类RED/GREEN及异常保全可接受，fake transport不当正常业务通过。唯一77158首败/exit-15/人工endpoint清理范围保持；W已不存在，当前ds55 94477仍受保护。新留存9,232,384B、累计14,178,078,720B，13.21GiB上限余6,050,775B；宿主本次约219.54GB可用，精确实际峰未测。

必要工具问题已有明确修复，允许Sol接续原模式归因，不等DS：从83d1+c2b恢复同一341c候选，核Info/可执行名/签名及描述资源实际路径，使用4772；不重编或追根/DS/H在途源。准备与普通工具前置核对在启动前完成。仅恢复旧首败所必需前态并一次模式切换；31仅若原前态必需执行一次，不重跑其验收矩阵。记录原请求/回包、实际字段/owner/版本、焦点及第一分项拒绝，不用后续Apply/刷新/补点重发救绿。根因明确且属共同契约时可自主最小私有修复及受影响正常验证；应用归属或仍未知则保第一次结果并准确关闭释放交指导。明确新工具失败仍停本轮而不循环重开，正常关闭与强制清理分开。此次采集用总额现有余额，预留≤5MiB，旧账累计不清零；原9MiB是已交批次，不是新加额度，峰14GiB/宿主峰后20GiB维持。复用同一W/旧bundle，差分原件保真，完成准确清理；无SDK/根写/Git/监控。模型按执行线程最新人类授权，完成直接回本指导。DS继续待本共同归因/差分，H独立目标对照不受此等待影响。

**模式接续的工具边界校准（2026-10-28，取代笼统“任一工具错就关闭实例”）：** 同341c的PID2931已用4772完成真实准入scene_accepted v1及6301/6302初值4/2读回；真实全选3→1后原件FIELD copies为3331/applied34、TARGET6301、VERSION2/FIELD_VERSION2，指导已核。随后Apply脚本引用上一调用try内的局部modeAfter31，动作前ReferenceError，Apply与mode未发送；这与前次frozen错误不同，仍不算生产RED。该实例已exit-15、准确端点人工清理，正常关闭/分项原因仍未知。

本次暴露的是诊断脚本准备问题，不能每修一处普通脚本就启停、归档并升级。Sol先一次检查整条剩余动作模板的作用域及依赖；每次在同一调用内读取当前AX、解析准确身份并执行，跨调用仅用明确持久的应用句柄/原件路径，不依赖try内临时值或旧AX索引；不扩一套工具实验。若W仍在且身份一致直接复用，已退休才按原归档恢复，不为换轮号删后重建。继续一次原模式链的授权有效，普通明确的动作前脚本错误由执行者修正后在同一实例继续尚未发生的动作，不算重投且不再逐次申请启动。只有已发送动作的失败/结果不明、实例失效或缺少归因证据才按真实边界保原件并停止相关链，不能补点、重发、刷新或改判据救绿。已取得的前置绿证复用，重建进程必要前态与重复验收矩阵区分。目标仍是模式首败分项→明确归属/最小共同修复，生产写集、性能/组合边界与总空间上限不变。Sol负责本包执行与收尾，DS继续等待实际受控差分；不新增用户搬运或监控。

<a id="sol-mode-selection-first-20261028"></a>

**2026-10-28首次模式分项已定位，交DS处理alias生命周期。** [结果与范围](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-continue-result.json)、[源码归因与建议](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-continue-attribution.md)。同341c/4772正常PID16602复用既定前态，单次mode首败selection：declared12/owner-1/request11/binding1/focus904:6301:4前后相同；冻结selection1:1:0:0:0、旧owned910:6201:5，matchfalse。CancelA后自动焦点jobName，与DS旧AX相同；不是copies INTEGER会话。首次reorder被scene_transaction_busy拒绝且未重投，所以仍v1；A31/applied31、B42/applied2真实读回，不冒充旧v2重排精确复现。mode回调已generated而首次AX/画面仍手写，原拒绝不补绿。实时sourceVersion/bindingCurrent与拒绝后dirty/request未采，保留unknown。

应用build清live alias、generated分支不重声明，旧range闭包读取该alias，可令source从0变退休-1并触发此票据false；它是有源码支持的推断，并非测到了-1。6.1Terra仅只读核对range/ticket及unbind生命周期。DS应将alias权威接回现有scene接受/回滚边界，解释旧TEXT退休/新owner重绑与迟到输入；不能默认树删除自动release。Sol未改window guard/生产源，根74不动，无重编/新SDK/31矩阵/补刷新。清理Close是独立新需求，其后画面推进generated不当首败通过；原生放弃临时界面文档后exit0、native destroy、endpoint自清理均成立。W无打开文件/进程后退休，释放分配量41,635,840B；新增、累计、余额及宿主空间见[本次空间账](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mode-continue-space.json)，仍受5MiB/13.21GiB/峰14GiB约束。保83d1/c2b和首次原件、ds55不动；629/472及原9b92分项不提升，无Git/DS/H写。

**指导复核及归属接续（2026-10-28）：** 38541590的96材料SHA/长度一致，冻结源码7文件及摘录逐字匹配；main945从83d1恢复读取，根holder3a891/region8ab120/range c04cc8与冻结相同。首次mode原日志selection、旧910 TEXT、当前值unknown，以及CancelA自动焦点jobName、首次AX/PNG仍手写均已核。reorderbusy使本次前态v1，不外推为原v2分项；关闭后的显示变化不补首败。16602 exit0/destroy/端点自清理与W不存在成立，当前保护ds55。新增3,960,832B、累计14,182,039,552B/余2,089,943B，宿主实查约216.85GB，实际峰仍未采样。本次归因限域接受，未取得生产修复。alias即改即生效的路径足以支持由DS承担[原§17.5应用/holder生命周期接续](2026-10-24-ds51-normal-workspace-delivery-blueprint.md#ds17-alias-scene-lifecycle-20261028)，以真实反例核因再修，不预判现场source=-1。Sol不继续重跑或改guard；必要window接缝由DS给具体时序后再协调。

**2026-10-28 DS alias交付后的输入判定校准：** 指导已核[§17.5修复与原件](2026-10-24-ds51-normal-workspace-delivery-blueprint.md#ds17-alias-review-preedit-20261028)：42a4/b5f6/3539精确差分、6项针对性原件及9e/461的单次模式实际呈现成立。DS所报生成g仅COMPOSITION_UPDATE，最终关闭为CANCEL_PHASE，无COMMIT；c507的phase1只预编辑、phase2才业务提交。因此当前不成立新的已提交输入丢失或共同window修复任务，不把此证据贴给旧TEXT37。DS继续原包明确终结的正常输入/完整owner读回及剩余消费，不等Sol。Sol保持本轮归因收尾、不新增运行或源码改动；仅收到有提交/完成身份和明确共同接缝的新证据后再由指导下发。原累计空间与冻结证据保持，H不受此等待影响。

<a id="sol-c507-root-integration-20261028"></a>

**2026-10-28唯一共同根回接已执行：root_not_modified=false，root_integrated=true。** 根[window](../../runtime/cjgui/src/composable_ui_window.cj)完整SHA已从`74b7db97935a51511898eccf4b03ddc2dfc04e3f279c05980c6efbbd0c12c6d8`变为`c507a3b241df67987ca2c01f087023e2bff412d346d901da3aad099e228a8a3b`，与[已验生产原件](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-request-production-window.cj)逐字一致。74→c507统一差分与[6992补丁](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/integer-request-root.patch)逐字匹配；补丁完整SHA为`6992cef54f66601bd4b480f4c6abf2bdf5ba1188c26cbbb01da233c85b8f82ac`，仅同一生产文件37增/3删。普通proxy拒绝恢复在owner投影落后时保留刷新需求，并复用仍有效的准备候选；本步未重新设计或优化。

本次587条public声明前后相同，新增方法为private；未收入020e测试支撑、eec/b16诊断、旧runner/helper或任何DS/H在途源。15个受保护源文件前后SHA相同，包括DS已回根holder42a4e08f/regionb5f64b05/range35396bd3、native renderer5847821b/headered8f886f、runtime_state及runtime_renderer_session；其余公共文档/模板/消费者/工具、H均无本次写入。唯一另写为本Sol阶段与ACTIVE自身摘要；不可变结果、候选、补丁、既有root_not_modified等历史原件不改，它们只说明当时未回根，不能再作当前状态。

指导已核DS §17最终9e222493的53材料和受影响正常链：明确提交g→6301、真正v1→v2不重聚焦h→gh、换B后j仅6302、ApplyB/CancelA/保存及exit0；同c507/native584的INTEGER31和6项alias反例按精确源复用。本次按直接接续授权只做字节/差异、声明、受保护路径及git diff --check，不编译、不测试、不使用前台/共享target，不导出SDK、不搬树、不新建产物/代理，不stage/commit/push；SDK交付指针仍由指导处理。旧TEXT37/0c12、全IME/AX/性能和629/472的原边界不提升。

本次空间：生产源逻辑+1970B、分配+4096B；两文档分配净增0B，新增留存计费4096B，旧累计顺延至14182043648B，13.21GiB内余2085847B；无新产物或工作树。精确峰未新增采样；宿主可用仍大于20GiB，原峰14GiB约束不变。

<a id="sol-first-mature-runtime-20261028"></a>
## §9.12 普通应用连续交互、真实呈现成本与资源收束（2026-10-28，用户直接授权新阶段）

### 本包目的与已验起点

用户明确继续按整体设计目标补框架，不等鸿蒙。依据[首版范围](2026-09-26-framework-capability-roadmap.md#first-mature-version)，本包推进正常输入、系统交互与按需更新质量，并承接[§18](2026-10-24-ds51-normal-workspace-delivery-blueprint.md#ds18-ui-history-20261028)剩余正常消费与公共交付。**2026-10-28最新执行归属：**用户明确停止旧Sol/DS并新建整包线程01a18297-1b22-7f63-ad2d-e49f066db253，直接回指导01a17207-04bc-76a2-90c3-99c8c5060423。旧Sol已由用户暂停，DS已冻结释放并结束，两名旧子代理已结束；新主执行者统一负责实现、自验、接线与唯一SDK，不逐接缝回交旧线程。可按需委派gpt-6.1-terra和gpt-6-luna，档位自选、子代理只回主执行者。普通问题自主解决，只有架构/重大未解风险或无法自行解决的冲突集中升级。本段和新线程任务优先于下方旧双线协调记录，不重放旧聊天、不重启旧阶段。H独立继续，W/Linux与旧C不恢复。

本包原起点为已接受SDK9e222493（606文件/583输入）、window c507/native584；接管时保留已回根a5d及DS冻结路由合法增量，不能按原起点回退。保§17公共生命周期、真实INTEGER31、g→gh明确提交与绑定/模式切换、正常关闭原件；不重跑旧2d52/c61四条1000记录矩阵。原TEXT37/0c12因果缺口保留，新正常链不替历史定因，无新可区分证据不恢复猜改循环。

### 1. 先固定当前普通负载，再改善一个主导生产瓶颈


**本次固定操作与采样（Sol开工，2026-10-28）：** 主测9e Rules默认普通界面，加载按既有seed行规则独立生成的固定合法v2文件（恰好1000条、初选1），各run打开同原件并另存自己的路径，不启performance-scene；mixed仅功能短链。每个基底/候选、默认OFF/同配置诊断分别保20个过滤（1/BackSpace交替10对）、20次两个可见稳定owner间交替选择、20个当前owner名称尾部1/BackSpace编辑、20次列表down/up一页滚动；setup/focus/clear不混入暖分布。每类按预置顺序保全部事件，预编辑/取消/拒绝/无变化/未关联不删除。布局、数据、应用源及开关固定，启动/resize/结构替换另列。输入起点取native原始接收的mach时钟，终点取真实owner应用后版本/结果及对应accepted scene/frame的drawable.presentedTime；现有键盘seq与owner/frame尚无完整关联键，未补齐前输入p95保unavailable，不用owner-turn或回调到达代替。现有refresh/owner-turn/CPU与cadence可独立归因，不与默认OFF数据相加。默认OFF正常行为与诊断开销单列。

冻结9e manifest的framework/Rules初始561输入约22.9MB，复用唯一convergence-work，后补原typography必要18文件；不消费DS在途源。初始7862325c复用、__bss比较器及非法fixture失败保历史原件，不作生产RED。当前正常Rules受控重编EXE5cfc350f（仅独立包装元数据）实际完成80操作；末尾触600s cap、exit-15、cadence为0，16/32ms及正常close未达，原件/人工端点清理边界保baseline-diag。采样/导出/Save/Close已离线备好，等真实writer端点与必要接线冻结后一次采完整基底，不延cap；domain.version不满足continuation provider契约，保持-1。现有refresh/CPU仅作未关联局部资料，尚无主导生产瓶颈修复。

独立typography原df16eafe/源49b945c2在c507/native584首屏裁窄、722不可见，未送IME；67秒Close exit0/destroy/endpoint清，恢复当段微信输入法/VO0，未碰ds55。保[原屏/AX/完整notes读回及原EXE](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/ime-typography/outcome.json)。maxWidth=0合法；宽栏START取scroll固有24pt、padding后余8pt。DS一行宽栏STRETCH/窄栏START补丁7780a505/目标8505d3f1已由指导核无窗同输入RED/GREEN，正常画面仍待本线。mixed原9e模板19文件正常包f3203a6f已签名，数字build退出码未留存，不重跑补0；其BOOLEAN是select，VO checkbox复用同一已建任务板默认控件页，不添控件。

当前固定组合为c507/native584加[四源私有观测差分d491bf35](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/input-link-candidate/input-link.patch)，native9512221f/header38dd1f3f/renderer-session84a32608/window9d9d5d25，旧Event/ABI/FIFO未变。同一泵helper把附属值随私有queue/ticket带过两READY，以同次FFI局部out返回，未知归0，非Mac旧泵；不采用TLS跨Cj或新握手状态机。Rules已接DS最终f9c/319f/clock41ef/observatione823，单次正常build0（8.15s）/EXEfd047837412719faec73474da9e4ddab2d049bbc94e11dd229917fb5a2f4b480/normal archive a4f4（原5ef构建身份留旧原件）；无窗canary unset/ON验证invalid-session旧新Event一致、poison清0、NULL/边界，未代替direct/两READY/合并实测。普通Cj wrapper的inout编译RED与CFunc最小修保原件。Typography仅消费8505，正常build0/签名0、EXE42e70c75、archive6185，4对象与a4f4逐项同hash；下一功能链新input-link关闭、原workload诊断仍ON，不称原runtime逐字A/B或Rules性能通过。W当前525304KiB、已测build峰576620KiB，原df16 EXE单件新增37285776B留存；沿13.75/15GiB、临时W1.25GiB、旧累计14182043648B，收尾退役自身编译中间物，宿主约210.7GB可用。

前次锁屏/派发unknown原件保留；用户已解锁，本次先核ABC并在单实例42e/PID38069完成[真实Typography IME短链](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/ime-typography-fixed/RESULT.md)。十次GET_CONTEXT FIELD(8101,notes)保完整UTF-8：预编辑v2/127B不落owner，提交你好v3/6B、换行v4/7B、世界与取消后v5/13B；WIDTH宽窄及zoom中组合不丢，同绑定未补焦的一次Space续中到v6/16B。外部SET_NOTES applied 6→7清旧wen；其后Space的marked=0，v8为外部版本加普通空格，合法新jixu提交v9/19B；不称旧commit拒绝。八次generated-fields均ERROR unknown_owner，不造字段版本；初始region v0 scene_rejected与WIDTH后v1/v2 accepted分开。workload/key-entry ON、input-link OFF；截图后缀png实为JPEG，不作presentedTime。532.44s正常exit0/destroy/endpoint清，ABC/VO0恢复，前台/target已交DS；指导现独立核82原件SHA/长度、十次原FIELD正文/同endpoint及context版本、三张截图和原输入/KEY行，接受上述多行IME范围；WIDTH后合法重选与zoom后免重选分开，HOST/CONTEXT后段计数不同，按同event_time/keyCode核对，不能造同seq。仍欠VO、删除/换绑与旧提交拒绝、direct/两READY及16/32ms、真正主导生产改善。当前离线准备，不重开本例。新增本例保留2828KiB（含报告52KiB），文档/驱动预留64KiB，累计保守14185005056B；W525160KiB/峰576620KiB，实际释放0，宿主205436084KiB可用，沿既定预算。

**§18正常消费必要返工（2026-10-28）**：[原B RED、私有观测及实际边界](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/continuation-text/FINDINGS.md)。原应用五次参数-ne退成x/xt仍保。只备native584→17ef的有界默认OFF正文/实际queue copy观测，根/旧W/DS SDK未改；标准独立build0/testing=false/EXEdabbd274/archive48712679/4成员与真实link已留。71840裸结构夹具拒绝、76988遗漏原返回业务模式均正常exit0且未发suffix，不计生产RED。已核原JSON整体fa6a与内部结构7f9是不同对象，纠正Root先前错误解释；原模式补交明确为Cua调用转录而非raw extraction，既有mixed-return-business AX为原证据。98767按原13源/c3/完整原JSON，A/B各正常12键、layout2→人工undo3→redo4→正常返回业务，完整前态field12/state1/structure4与实际native910均达。唯一原suffix本次得到B-history-18-next/field17、A仍12；92.07s正常SaveClose/exit0/destroy/endpoint app清、ABC/VO0，前台/target已释放。诊断ON终态完整不算修复、默认OFF绿或原RED撤销。指导独立核app.log SHA及33条完整正文：record25–29是scene93真实queue_added到-next；record30/31（1151–1152行）scene94确将textStorage正文17B/选区17:0回写为旧12B/12:0，captured_scene93、awaiting_owner1、guard0；record32/33（1156–1157行）scene95才恢复-next/17:0。这是本样本burst后真实代理回退再恢复，尚非原xt时序的因果复现。已直接交Sol且其确认优先亲自追94捕获/owner完成/local frontier，在既有生产接缝做真实序列＋其间合法后续键的确定性交错反例，明确后最小修；保合法外改/Cancel/换绑/IME，不能盲禁所有新投影、用正文长度作权威或另开同样GUI。若实需新跨层协议先给最小方案，不能继续猜核心。Rules独立来源短段16130已报告532.88s/exit0/endpoint清、8个source动作但未跑80分布，实际旁路原件待核，不作16/32绿；当前释放前台/target，既定Rules/VO独立准备继续。13应用与431框架prepared源逐SHA相同，不继续猜源码/二进制错配；Root无生产逻辑修补。 当前Sol归因假设另核源码：refreshInteractionPaintIfNeeded:15933只挡未消费输入/候选/present，15974取旧nativeInputScene构paint，15985却取当前owner revision，16061–16096重stage focused editor；owner已推进而full刷新尚未消费时可能据旧正文发布新scene。94缺prep-trace只支持假设，不能替代确切分支证据；先复用testRefreshInteractionPaint/pumpEventsWithoutRefresh/真实native输入接缝做合法交错RED，最小修基底一致性，参照19909–19916已有声明/owner门。保拒旧paint后无需额外输入即可有界full接续，以及稳定hover/press/focus/动画不build/layout的快路，不盲改native guard。另指导核原log65–71/468–474/1023–1029的kind28手写先写→kind51 owner_version_moved，main仅generated.didApply才返回且6200护栏漏6301/6302；已直接交DS用真实接线反例确认观察/认领路径并最小修消费者。DS冻结释放前Sol不并改main/region/holder；释放后由Sol统一衔接和正常消费，原差分身份保留。早先有效夹具被真实输入/drawable门挡住，另一次link枚举错误未运行，均不算生产修复失败。Sol明确83884 destroy/exit0并释放后，DS短段取得两条路由RED；指导已核其red-release的17137/28793 destroy/退出和当前仅ds55，前台明确交回Sol，DS离线修复。现[red06原件](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/owner-paint-race/red06-identity.json)为真正可区分接缝：冻结window c507、测试784964fd及testing链接0，普通整值controller经真实TextKit/FIFO得到-next，refresh=true/epoch6；真实Metal drawable就绪后正常零时长paint接受scene1→2，后续x正文断言失败，destroy complete。指导核测试源SHA和原始stdout/stderr；fixture不使用range会话/外部owner revision，pretty diff填充不算完整正文，不能替原98767/原xt因果。后续red08已取得未修饰ASCII正文：五键后-next/17B、version17/writes5，旧paint后下一x成B-history-18x/13B、version18/writes6。指导核Green11四份实际test日志各PASS/exit0/destroy及真实testing链接；修复后-nextx/18B、稳定paint未重建、外部replacement/resource6202无需再输入full接受后续!、owner-only一次需求epoch1→2且无deferred均成立。red08→GREEN测试f7→f2仅移除重复foreign声明，隔离包用原样声明文件、根复用既有source_handoff_test，行为/断言未改。共同[精确window差分](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/owner-paint-race/production-window.patch)从c507严格生成a5d70827且等于当前根，测试f2ce546d等于根；公共声明相同。新增门只检查已有refresh需求/声明及owner基底，必要时requestRefresh一次、保deferred paint并退未用drawable；未改native拒绝/队列。该差分限域接受，正常consumer和原§9.12其余门仍待；不把测试接缝当原xt现场复现。Sol明确49506/49583/49594/49605收尾并释放后，DS已完成同c3/c507路由owned/whole/primary三项GREEN。指导核三份日志SHA、各1PASS/exit0、native65748/65897/65916 destroy/实际退出、明确release及当前仅ds55；前台现已直接交回Sol，继续准备就绪的独立正常消费/VO/性能必要工作。mixed最终HID在DS一次冻结释放后由Sol核输入并自主衔接，不再逐项等待指导放行，不在旧路由重试或追DS WIP，不阻塞独立项/不等H。DS留离线冻结/清理；两方正常汇合仍一次，原整包其余门不消失。保原拒绝和合法外改，不强清flag/丢队列/绕门，不另开同样GUI。Rules来源smoke只确认raw→Cj pump，writer sequence0属未提供的provenance，callback raw旁路候选不当owner/present端到端绿，其他原§9.12门继续。

复用9e的Rules与mixed以及现有成本/输入/准备/帧观测。以一条1000记录Rules（真实过滤、选择、一页滚动、当前owner编辑）和既有mixed的字段编辑/兼容布局更新作为冻结负载；确定一个主测量消费者，另一个只做受影响功能短链。基底与候选的应用源、数据、布局、诊断配置相同，DS在途新增历史不混入性能对照。

开工在本节补一小段具体操作序列、采样数与时间点定义：暖输入/选择目标为原始输入接收→owner实际应用p95≤16ms、接收→对应drawable实际呈现p95≤32ms；每类至少20个预先规定的有效事件用于p95，保全部原事件、慢样本和未呈现项。启动、resize、结构替换、系统转换分开统计，不混成一个数字；这些明确的新测量起止点不能改写旧16/32门结论。预编辑/取消、拒绝、无视觉变化及未能关联的事件分别列明，不能从分母悄悄删掉。记录p95/max/超门数、owner/main/worker CPU与wall、build/layout/staging/缓存工作量、内存/原生租约。正式功能以默认诊断关闭运行；必要同配置诊断成本另列，不把不同开关或不同行为的数值相加。

原native已有addPresentedHandler/presentedTime及frame cadence记录，优先接通事件/owner版本/accepted scene/提交frame的关联；缺字段才加默认关闭且有界的内部观测。不把accepted、GPU完成、回调或截图称为对应帧的呈现时间，无法关联就保unavailable。不要另造通用遥测系统或只交新统计表。

依据当前基底的主导耗时，修一个真正影响正常应用的同步等待、重复准备/布局/文字工作或无界持有；复用既有prepared snapshot、依赖失效、owner让出/唤醒和有界缓存。先保能区分根因的RED，再最小改共同归属，并以同负载复测受影响部分。若首个假设不是瓶颈，按新证据转向实际主导段，不为凑优化改代码。任何降本不得丢输入、合并需要保序的事件、缩负载、删慢样本、隐藏重试或靠定时轮询。没有实际改善且仍有长阻塞不能称本包通过；确为系统成本或测量通道阻塞时集中给原件、归因和可执行取舍，独立部分继续。

### 2. 支持范围内的系统输入和可访问交互真正可用

复用现有CjguiTextSession、owned/selection完成、模层返回和NSAccessibility投影，不新造输入法或另一套正文。选一个已安装、可实际驱动的macOS系统IME，在普通TEXT/MULTILINE字段完成预编辑→提交/取消、同绑定布局更新后继续；外部版本变化/删除换绑仍拒绝旧写入，合法重新选择后可继续。完整正文与owner/field/draft版本、原始输入/提交序列、实际显示对应。保护系统原输入源与用户剪贴板；不为工具便利把预编辑当已提交，也不以重发、补焦或延时救绿。

在同一支持子集中做一次真实VoiceOver导航/读出/操作：字段标签、值与错误，按钮/复选或滑块动作，模层范围及返回。复用真实role/value/action接口并修其中共性缺陷，AX查询或AX本地值不能冒充VoiceOver可用。保原VoiceOver开关并准确恢复；工具/系统无法取得证据则标明具体未验，不穷举输入法或重开多轮应用。只修支持范围所需的框架问题，不扩高级控件库。

2026-10-28多行消费者依赖已解除：DS交接且指导核9e原typography.cj SHA49b945c2f7a2b190cb0b657cae006035f4d720b701895e697207df220ce5a2b8，根源相同。用generated_panel_consumer的单个业务参数--typography进入正常页面，722/typography-notes为可写MULTILINE，notes/SET_NOTES绑定8101；经原声明规则/current domain.version写完整TEXT_CHANGED，CJGUI_TYPOGRAPHY_READY发布公共descriptor，GET_CONTEXT含完整notes与实际版本。未启rangeDelta，不能称mixed owned通过；不造field version。此入口内建setWorkloadDiagnostics(true)，只按诊断ON的补充功能证据记录，不冒充默认OFF多行/性能通过，不与固定Rules性能统计混合；原默认OFF链仍按上文执行。无需等DS接线、改消费者或追UI历史在途源。冻结说明见DS section-18-20261028/multiline-handoff.json，真实系统输入、读回和退出仍由本线执行。

原首键/同批末键→Apply/Cancel按影响并入最后短链，保FIFO、版本、focused/installed与owned拒绝契约。按钮返回只证明按钮返回，文字首键必须来自合法文本返回目标。必要应用接线由新主执行者在包内修复，不再交回旧DS。

### 3. 资源与普通窗口终态

复用既有资源/字体/图片缓存预算及正常退出证据。对本次实际涉及的连续输入、滚动/结构更新做有限驻留，再正常关闭自有窗口；分别说明活跃资源、允许保留的共享缓存和最后持有者释放，不能仅凭RSS不归零判泄漏或只凭进程消失判正常退出。两窗仅补本次影响的实例隔离/退出边界；不恢复GiB、全部图片矩阵或历史平台验证。

新主执行者统一交精确基底→目标差分、源码/ABI/构建/测试身份、实际收益和未达门，并回接已验共同源。消费DS已冻结材料，沿既有exporter/锁与配方完成受控SDK交付，不让旧线回来导包。current9e/rollback629及c3候选身份保留，候选只按已验增量受控替换；私有9512/38dd/84a3/9d9d等观测源仍须满足原接受条件，不因交接或构建成功混为生产交付。复用适用原件与工作目录，不重复历史矩阵。

### 写集、并行和收尾

DS已明确冻结并释放，新主执行者接管本包必要的window/text session/renderer/macOS host/native及generated/holder/region/range、UI文档/history/workspace、公共操作/客户端/模板/消费者/exporter和唯一SDK；先核收到的差分与根并行变更，再自主衔接和修复，不逐文件请示或返派旧线。公共API、输入/FIFO/owner与FFI资源契约不放松；实质架构或重大未解风险集中升级。H平台/snapshot/lab、其冻结core及其他用户/并行源继续保护。

本包Mac前台与构建target由新主执行者统筹，旧Sol已暂停、DS已冻结并释放，不再按测试段轮流交接。保留各自原件和准确源身份、复用已有目录，接管不复制整仓/旧产物或新建worktree。保护ds55 PID94477及用户/不明实例；正常会话准备齐再启动，长构建/分析放在窗口外。保留首个具体工具失败，不在失效对象重试或延lifetime cap，结束准确清理自有实例/端点。旧Sol最后性能A PID1501已-15退出且endpoint清理，未发采样输入；不计性能样本或正常关闭。

先核并行改动和本线空间。沿原E累计14,182,043,648B，不清零、不新增10GiB账。本完整阶段明确上限为留存13.75GiB、峰15GiB、宿主峰后至少20GiB：新增留存约555MiB只供必要基底/目标复盘与新RED/GREEN/原始正常记录；临时构建占用最多1.25GiB且成功/失败/取消均退役，优先复用旧可用二进制与精确源清单，不重复整个SDK。高写盘前补实际可回收项、预计峰值和保留数量；超出才带具体不可复用项交指导，不能静默扩额或猜删唯一RED/他方产物。普通日志沿AGENTS64MiB/单份、512MiB/轮上限并保完整有用序列，收尾给新增/保留/实释与宿主余额。

新主执行者沿用户当前主模型配置，获明确授权按需委派gpt-6.1-terra和gpt-6-luna、思考档位按难度选择。主执行者负责整包归因/方案/集成，子代理承担明确写集的完整子包并只回主执行者，不另建用户线程或定时。无外部顾问、Git写或新平台任务。整包完成或真正重大阻塞直接回指导01a17207-04bc-76a2-90c3-99c8c5060423；正常进展留执行线程，独立工作继续，不按每个补丁等确认。


**输入计时旁路裁决（2026-10-28）**：TLS及跨Cj诊断握手不采用；允许一次限域Mac私有pump-with-input-trace接入，复用原pump、队列和票据，在同一次FFI返回局部out，不能把out指针送入异步main。诊断附属值按原锁/generation/nonce随队列与ticket复制，direct/两READY在清票据前取完；NONE/失效/空out/未知每次清0，保原消费条件、FIFO、超时与业务准入。公共Event/旧ABI不变，非Mac保旧泵unavailable，默认OFF不另建等待/轮询/握手；未知合并来源不猜一对一。相关反例/正常库链接后再一次正常采集；raw→pump不自动证明owner→frame，不按相邻时间或同kind拼来源，真实dispatch返回最多是具名上界。若仍需新生命周期就停止该通道、保16/32ms unavailable，继续已授权局部成本归因和真实瓶颈改善、IME/VO，不再无限扩测量。CodeGraph本次仅覆盖别端、CodeLattice live root拒绝，影响以实际源码补核。DS旧writer包因测试专有时钟和generated准入绕行集中返工，未交性能消费；前台仍归DS。只用已授权Luna，无额外顾问。

**Typography冻结消费接续（2026-10-28）**：DS section-18-20261028/typography的patch7780a505/49b→8505d3f1已指导核唯一一行生产差分及同测试RED/GREEN（各484归档输入只差该文件）。只将其接到冻结9e消费者，复用正常c507/native584或准确已冻结本线runtime，不带DS历史/WIP，不等writer诊断返工才能做独立多行。Sol离线期间已明确无窗口/共同target占用，DS可先用，指导取消空档预留。随后Sol完成42e70c75普通构建、准备就绪仍无窗口；指导已核EXE/6185 archive/prepared/source-index/构建日志和与Rules a4f4四对象同hash，DS随后明确本轮完全离线、无自有窗口/真实输入，私有testing检查已结束、无活动cjpm且不占共同target或Sol库，明确短前台可交Sol；指导已直接授予立即执行既定短链，结束准确释放。先准备后启动，结束准确释放。一次核宽首屏722可见可聚焦、WIDTH窄宽保正文、系统IME提交/取消和完整8101 notes/version公共读回、正常关闭；原诊断ON/非owned范围保留，不当Rules性能或已测呈现。writer旧包仍撤回，无窗布局证明不替代正常效果。

本次构建组织可固定c507/native584＋私有四源观测增量＋Typography8505做正常功能链，须单列源/archive/EXE身份，非原runtime逐字A/B。新input trace OFF与Typography内建workload diagnostics ON分开标记；normal链接与invalid-session/NULL/canary只证明自身边界，不替代direct/两READY/NONE失效等关联反例。实际VO checkbox复用同一现成generated_panel无参数任务板marked控件，mixed BOOLEAN为select，不改名作checkbox；不新控件或消费者。

**本短段锁屏边界更正（2026-10-28）**：42e未启动、无自有应用、前台已释放；首次Cua读System Settings返回Mac locked/automatic unlock failed，但同一批调用包含后续pressKey，锁屏可能作为文本返回而未抛异常。slot-ime-fixed-lock-boundary.json实际before ABC/after微信，input_dispatch_status unknown，撤回先发摘要“未发键/输入源未变”；VO0保持。原始before/after保留，不计生产RED/IME实修失败。停止锁屏操作，解锁后先处理本段原ABC恢复及读回、新占用交接，再用已构建42e做一次既定正常链。后续驱动必须分开读取状态和发动作，显式识别锁屏/失败返回才能阻断，不只依赖异常；不改系统锁屏、自动解锁设置或增加重试。两线独立离线继续，不为等待造验证。

**writer时钟域衔接（2026-10-28，已交付）**：DS最终final_absolute_clock_packet已指导核17项包SHA/9项小检查SHA；main f9c34de2/generated319f6b28和原binding准入已接受，clock41efbf74/observation e82377f5只将89af/94f4的continuous符号/标签换为absolute。实际完整clock在正常系统链接后被独立C128 absolute读数括住，OFF=-1/exit0；与本线native9512221 receivedNs同域，不估offset、不改raw起点。Sol在冻结9e两侧仅接两个consumer补丁及两CURRENT helper，核identity，不整拷§18或H变更；已是最终helper不再叠absolute补丁，不为Rules重建Typography42e。旧3项及正常callback按continuous旧身份复用；新Rules运行仍须实际源/链接/输入身份，generated_binding_return仅返回上界，input0/未关联/-1保持unknown。ns/us和微秒量化不能漏算，更不能推成对应帧已呈现。计时接入的DS依赖解除；最终Rules离线接入已指导核9处实际SHA、源/prepared两套4文件、normal archive4对象及link-map与build原件；fd047837真实EXE48777360B，Typo42e不变，构建/签名0记录保留，未启动应用。session.py先清继承CJGUI_，仅Rules diagnostic启writer，默认OFF与原Typo workload ON分开。无需为此重复构建/绿证；实际direct/两READY关联、IME/VO/关闭、主导瓶颈与16/32ms仍欠。用户随后在Sol直接确认“已解锁，继续”。指导核DS当前仍无§18窗口、在候选export/包外构建，授Sol本次42e多行/宽窄/完整notes/Close短段；先只读取态核ABC/VO0及新占用，再操作。已准备VO可有限串行，结束准确清理释放给DS，Rules fd047后续采样另按当前就绪串行；不改cap、不起空窗等待。历史ABC→微信/派发unknown仍保原件；本次unlock-restored-abc.json读回ABC/VO0后执行42e单进程--typography。指导已核ime-typography-fixed/process.json与app.log SHA、实际EXE：PID38069在532.44s内exit0，raw destroy complete/CJGUI_TYPOGRAPHY_CLOSED endpoint_cleared=true，descriptor不存在，release/system-after实读ABC/VO0；前台/target明确释放，现已交DS候选链。Sol报告系统IME提交/换行/取消、同绑定zoom无补焦续写、WIDTH保全文、外部SET_NOTES后旧wen被取消及新合法jixu继续，原件现已完成限域复核，结论见本节当前IME段；不据此认定全IME/拒绝矩阵或端到端性能。generated-fields unsupported/初始region scene_rejected保留；内建workload与key-entry ON、input-link OFF，不能说所有诊断OFF。VO与Rules旁路/性能本段未跑，旧门保留，不重开窗口等分析。
**DS §18续写缺字接续（2026-10-28）**：本轮因Selected model is at capacity中断后原模型接续，不算实修失败。DS唯一待验c3efd63d消费9e c507/dda4/native584/ed8f（指导核实际与manifest），mixed signed EXE报告66f74385。normal/continuation-first-failure.json及同目录原序列/公开cardB/AX表明：undo/redo保A/B正文后，B首次click104/全选/Right/-next预期B-history-18-next，实际owner/AX为B-history-18xt，draft/field12→17；A自身首次-next成功不能替B。此前不能据版本差推五次payload；现指导已核history-main585/587/588/590/591实际完整参数为-/-n/-ne/x/xt，五次均applied=true，main64e/preset0264无显式字符串截断。较晚structure5/state2的before-branch仍不能与redo4拼同帧。Sol先离线区分工具投递/输入源/预编辑、原始选择与全值payload、owner版本和异步反馈覆盖，复用旧TEXT37/0c12与c507结论；缺证明确，不先猜首键/Unicode/历史栈。共同根因明确才最小修，应用归属交DS，旧失败累计不清零。DS原PID73564后到1800s cap/-15，非正常关闭；后续独立文件/Rules链已报告结束，foreground-release-verified列各PID与端点已清，指导当前进程核仅保护ds55，实际前台/target已释放。该唯一实际原路径诊断已在98767完成并正常退出，另71840/76988两次准备失败未发suffix；最终完整-next不能撤销原RED。指导已抓到scene94真实旧正文/选区覆盖、95恢复，详见本节当前必要返工；Sol优先离线确定性交错反例与既有完成协议修复，不再相同GUI碰运气。DS独立交付已限域复核并释放，Sol可按已授权本包在准备齐后串行用自有前台完成独立Rules/VO，未知关联/呈现和旧门不冒绿。交必要生产delta须以9e实际基底分离未验四源观测；指导核后DS允许一次受控替换c3候选，复用无关历史绿证，不重开全矩阵或额外咨询。


<a id="package-17ee-review-20261029"></a>
### 17ee 功能候选复核与本包剩余工作收束（2026-10-29，指导）

新整包执行仍为01a18297-1b22-7f63-ad2d-e49f066db253。指导本次只读复核614个导出文件SHA/长度、591锁输入及manifest 72762a63、最终Mixed704fd2fc/Rules65a348bf实物；候选共同window a5d/generated9e3a/region6cfc/native584/headered8f与冻结身份相符，未把私有性能四源混入。已审阅路由及Rules启动最小差分、SDK测试驱动闭包；复用既有反例，只核两项实际模板进程exit0和无源漂移。Mixed八阶段16份原始owner快照与汇总逐项相符；Rules公开FIELD与保存文件独立比对1000条四字段、draft=0与selected2一致，60774B/SHA7765相符；正常保存关闭、重开、合法/坏UI边界按各自原件接受。此为17ee功能候选限域接受，不补原xt全因果、native raw HID、16/32ms或VO证据，不晋升current/rollback。Rules修复是将240次轮询条件替换为既有事件驱动首帧/准确票据等待，保关闭/失败处理；不能描述为三个等待仍有原240次总上限。未运行构建、测试或前台。

**剩余两项继续由同一主执行者收束，不再交接旧线或重复功能矩阵。** 性能先解决记录没有覆盖目标慢段的问题：沿原固定1000条普通Rules、既有版本与开关，离线确认现有慢段保留/导出入口能覆盖一个目标refresh的完整preparation/turn/request/dispatch/scene/frame，再作一个正常应用的有限诊断片段并立即保全有关记录，正常保存退出。该片段只判别主队列等待、实际线程CPU、重复工作/多次往返，不替代四类20动作的性能验收。优先改现有采集驱动/导出时机，不扩ring、公共ABI、事件协议或增加等待/轮询。源码CjguiOwnerTraceAppendAt的timestampOverride边界本来没有CPU值，不能把它们改填或当缺陷；CPU要用同线程有效main_enter/main_exit等成对记录。一次完整慢段可判别后，主执行者直接完成证据支持的最小生产改善、相关反例及同源同负载前后消费，默认OFF与诊断成本分开；不再先实现完整input→owner→present新协议作为所有工作前置，16/32仍只按真实可关联证据判断。若采集关键记录仍不可得，停止同义重采，具名保未测与实施判断，不能猜优化或以unknown冒通过。

VO先核实际modifier、引擎和工具投递，用同一系统会话在自有系统应用/窗口做一个导航读出和动作对照，再验证CJGUI同类控件；保实际VO字幕/音频或其他可复判输出与业务状态，AX查询和Tab焦点不代替读出/激活。已有ctrl+alt+space触发输入源变化，不能假定组合键已准确送达VO。若系统对照也失败，精确定位为该路径尚不可验，停止改CJGUI和重开循环；若系统正常而CJGUI失败，以真实RED在本包修AX/焦点接缝并补受影响正常消费。保护原ABC/VO设置及用户窗口，准确恢复并关闭自有实例。

可继续按用户授权委派gpt-6.1-terra/gpt-6-luna，档位按需、子代理只回主执行者。17ee保持唯一功能候选；新增生产修复汇合后只做一次必要SDK替换，无生产变化不重导。原E/DS空间账、源归属及H/ds55保护不变。完成可执行项后一次回指导实际收益、必要原件、明确未达门与空间；重大新风险才中途升级，不要为本次复核再发同义确认。

<a id="package-17ee-bounded-review-20261029"></a>

### 2026-10-29 有限接续复核与功能 SDK 交付裁决

指导复用上节17ee功能验收，本次只核新增原件。snapshot日志前缀SHA一致、seq 1–25896连续且无重复，summary overwritten/dropped均0、export end已刷出；是运行中snapshot，不是最终trace。独立重算18个同pid/session/generation/request/dispatch/phase节点批次，逐对身份唯一、区间不重叠、main CPU有效且同线程：submit→main 0.166211ms、main wall 0.733831ms/CPU 0.731ms、main结束→owner消费14.764414ms。该结论仅适用于这18批，不能排除整个50.191750ms刷新由其他主队列等待主导，不能把返回间隔当睡眠或独占CPU；整个刷新主导成本仍未归因。present时间无效，不能通过16/32ms，诊断ON不能代替默认OFF。实际运行e1c954c2与留存签名EXE哈希相符，exit0且endpoint由应用移除；17ee manifest仍72762a63。生产推进原本已有8节点批处理、同nonce/prefix/绝对期限，现无证据支持放大批次/预算或另改唤醒协议，本次不强行制造生产优化。

VO系统原生对照也没有取得可复判读出/VO光标/动作证据；普通Space成功不证明VO，AX键盘焦点不证明VO光标。只能接受该工具投递/观测路径尚未验证，不能归因CJGUI、系统或修饰键丢失。原ABC/VO0及设置已恢复，自有实例已退出；不为此重开CJGUI或猜改AX。新增留存32.62MiB、释放46.84MiB按执行原账保留，仍在原E/DS额度内。本次指导未构建、跑测试或占前台。新增原件见[快照分析](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/package-trace-snapshot-20261029/snapshot-analysis.md)、[VO系统对照](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/package-vo-system-control-20261029/RESULT.md)。

**交付取舍：结束本轮同义采样，将17ee晋升为当前功能SDK，9e222493为最近回退。** 这更新上节“暂不晋升”的临时安排：17ee新增功能、输入正确性及正常消费者已有适用证据，既有current9e本身也保留性能/AX/IME门；继续冻结版本交付不能补足这些证据。版本交付与框架成熟度分别记录，§9.12+§18整体仍未全通过，不改验收标准、不宣称16/32或VO通过。原xt/raw HID、完整IME、真实呈现、跨进程业务草稿等边界继续按原范围标记，不能用布局文档重开冒充业务草稿持久化。

同一主执行线程01a18297-1b22-7f63-ad2d-e49f066db253只做本包最后实际交付：更新当前交付索引/运行入口、阶段报告、ACTIVE与两阶段交叉引用，指向已有section-18-20261028/sdk-17eec5e0，不重导、不移动或修改冻结包、不启动构建/测试/GUI、不改生产源；旧629及唯一原件保留为历史，不因回退指针变化自动删除。历史复现脚本保原身份，不机械改成新候选。检查本次文档差异和当前链接，给实际current/rollback和剩余门的集中回报即可。两旧执行线保持停止，H独立，不增加线程/监控；无需再回复同义确认。后续性能工作应先确定默认OFF的实际成本和安全优化目标，VO先建立可验证的读出/动作通道；本裁决不启动新的采样或平台阶段。

**2026-10-29 交付已落实：**同一主执行者已将现有17ee作为当前功能SDK、9e222493作为最近回退，629及唯一历史原件保留。[实际交付索引/运行入口](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/DELIVERY.md)、[整包报告](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/RESULT.md)和[DS §18交付结论](2026-10-24-ds51-normal-workspace-delivery-blueprint.md#ds18-delivery-20261029)已交叉引用。此为包外指针和文档更新，未重导/移动/修改冻结SDK，未改生产源或构建/测试/开GUI；历史复现身份保留，§9.12+§18整体未全通过及上述未达门不变。


<a id="mac-next-package-20261029"></a>

**2026-10-29 用户直接下发下一整包：**当前17ee功能交付保留；同一主执行线程01a18297-1b22-7f63-ad2d-e49f066db253接续[Mac连续交互、工作会话恢复与普通性能整包](2026-10-29-macos-mature-framework-package.md)。新任务取代上一轮仅交付指针收尾的实施范围，主执行者实际使用gpt-6.1-terra与gpt-6-luna，持续完成实现与必要验收并直接回指导。旧Sol/DS不恢复，不等待H；下方或上文旧分工与等待条件只作历史。
