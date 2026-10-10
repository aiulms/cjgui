# 鸿蒙：正常写作成本与有界大文件接入

2026-10-08 指导阶段提示词。2026-10-10 normal30资源回收已经单项收口，原包尚未完成。当前实施依据为下面“normal30 上层FIFO、发布交接与拒绝恢复”，优先于normal29及更早指导的冲突部分；这是指导交接，不自动恢复已暂停/blocked的执行任务。既有正常包及失败原件保留，不逐补丁请示，不自动调用顾问。

<a id="h-large-normal30-upper-fifo-20261010"></a>
## normal30 上层FIFO、发布交接与拒绝恢复（2026-10-10，当前优先）

**复核结论：票据回收可收口，快速输入仍是真实框架缺陷。** [资源回收双normal](../../artifacts/h-bounded-large-20261008/delivery-normal30-candidate-20261009/resource-close-normal-20261010/README.md)的424份共同输入匹配、各一笔Z和正常关闭终值成立；设备关闭前票据已被Home清空，持有载荷的释放由真实destroy函数RED21→GREEN0→撤回RED21补证，不扩大为峰值RSS或原完整链通过。沿用这些成果，不重新开资源工程。

[上层反例](../../artifacts/h-bounded-large-20261008/continuation/normal29-guidance-resume/UPPER_RANGE_FIFO_AND_ROLLBACK_COUNTEREXAMPLE.md)和[连续原日志](../../artifacts/h-bounded-large-20261008/continuation/normal29-guidance-resume/small-real-service-x123-once/continuous-pid-hilog.txt)证明：单次`x123`的四笔均产生并入队，范围为0:1、1:1、2:2、3:3；前两笔成功后，自有owner4的present先触发ctx3→4，后两张ctx3原票才出队。它们同时遇到native当前context门和窗口旧projection resolver；不是键盘没送到，也不只是下层事务未实现。上层拒绝未走owner completion和本次脏代理登记。输入前request3不能代表这次拒绝已经恢复。

**本阶段增加的共同能力：真实输入票从产生、owner提交、场景发布到失败恢复的完整责任链。** 复用已有输入registry、choice观察/采纳、owner版本事务、有界后像证明、staged/present/accepted、FocusAuthority.Transfer及共同attach/安装/确认，不另造产品队列或输入引擎。Pharos/thermo只保留领域事务和薄接线。原同值Will准入命令并返回true的SDK裁决不撤回，程序publication回声仍零事务。下面是已给出的实施方案，不需要再次询问是否允许改框架；此页编辑本身不启动执行。

### A．真实来源判决先于临时画面查找，判一次、消费同一份

1. 在`pumpInput`复制当前事件/provenance处，一起冻结该kind51的原票、文本及事件字段；不要经过其他出队或回调后再读`lastEventInputTicket`。把actual-ticket判决放到strict scene/`resolveLocalTextContinuation`之前。用原key/focus、node/resource/kind、两层binding、field、已采纳choice或原观察引用核根票；用唯一owner已接受前驱、原before==前驱after、owner版本和有界后像/postOrigin核后继。生成只读准入结果，`routeOwnedTextSessionRangeEdit`消费同一结果，写前核版本仍有效，不再先依赖已退休的投影缓存。
2. 复用`text_session.cj::ohosContinueRange16`及原共同owner事务；换算用原票before的UTF-16范围和认证的绝对postOrigin，不拿当前新镜像解释旧数字。无实际票继续走legacy严格门；实际票存在但畸形/失配不可退回legacy救绿。当前“kind51一律无来源代次”的旧注释须按两种路径校正，不能因此恢复历史无来源prepared重试。
3. 拆开`clearPendingLocalTextValue`的投影缓存退休与owner已接受前驱账目退休。镜像重新物化不抹掉真实前驱；真人换焦、外部正文推进、绑定撤销和关闭仍按依据终结旧链。kind31合成结构通知不能无条件当成人的新焦点意图。修改native当前context门必须有B的事实依据，不能直接忽略`recordIndex`。

### B．自有输入的发布保留输入面；必要移交结算有限旧前缀

**优先方案明确选“普通自有发布保留原输入面”。** 在共同窗口owner接受点形成原输入票→接受结果凭据（原key/focus/逻辑绑定、前驱、owner结果版本、已核的有界后像/绝对起点），随本候选冻结运输并只在原present成功时采纳。native `syncEditingBufferAfterAcceptedSceneLocked`据此区分自有推进与外部改版：本例前缀已接受、平台已接收后继时，accepted画面可以推进，不能将平台较新的输入后像重置为较旧前缀/新镜像，更不能只因正文窗口物化而reconcile成新ctx。失败候选不留下保ctx资格，同字节外部新版本也不能借用。不得仅扩大`preservesActiveLocalText` Bool、删版本门或凭文本相等推断自有提交。

确有导航、范围容量或结构要求必须换输入面时，才使用有限交接：复用现有Transfer，在其内部补原key、owner自推进凭据、**固定的已准入前缀**及不可延长截止，前缀包含Will已准入但Change尚未到的票。旧前缀按原身份/前驱owner结果结算，新输入归已生效的新挂载；不能把旧票key/scene改成新值，也不能把仅允许退役终态的`retiredTerminal`直接用作正文授权。真实换owner/换焦不继承旧正文写权。复用有界registry并计入持留容量，不等队列永久为空、不滑动延长前缀、不按键等待ACK或降低打字速度；跨窗一旦需要这个分支，就与A成组验证，不能只交普通保ctx正控。

本地[Flutter editable_text.dart](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/editable_text.dart>)的`updateEditingValue`与`beginBatchEdit/endBatchEdit/_updateRemoteEditingValueIfNeeded`已只读核对：平台已知值与业务值分开，批内避免覆盖输入的重复回写。借鉴这个分工，CJGUI仍须自己证明原票、有限前缀及owner版本，不引入Flutter依赖或照搬同值echo捷径。

### C．每张真实票恰一次结算，脏责任绑定原挂载

统一上层resolver拒绝、绑定拒绝、owner拒绝和接受的终结出口，registry持有可核的一次性结果；`internalRendererInputOwnerCompletion`不能再丢掉返回值。owner已写而完成回执失败，只补同票确认，不重做业务事务。当前completion依赖最后出队票，补确认须能按仍持有的原票身份定位，不借后一次事件。

拒绝时区分“Will尚未改变平台”和“平台已推进”。需要恢复的责任冻结拒绝票、exact mount/focus/绑定及最后owner接受的正文与有向选择；已退役挂载只终结旧票，不设置新挂载的全局失败旗标。失败前驱的已接纳后继具名终结，不冒充新根、不重放字符，已接受前缀不重复提交。`recoverRefusedRangeTextProxy`不能只靠node/resource/kind认为旧pending覆盖新拒绝；原request3及任何旧ACK都不能清除新责任。

恢复复用ArkTS现有publication登记→正文帧→同挂载attach→共同install/confirm。**原票实际安装、窗口条件采纳、同来源choice发布全部成功后，才关闭该脏责任并允许新根输入。** 当前native消费restore时先清失败、窗口随后可能拒绝、choice发布仅记日志的接缝需一起收齐；ACK失败只补确认，不重发setter。owner随后真推进时按新依据替换旧恢复目标，不给旧票追贴当前值。Back/Home/新焦点撤权保持，不借恢复抢焦；事实getter不加“先安装才能读”的循环前提。

### D．能区分本次缺陷的门与成本落点

先保留并复现原上层RED，串联**生产产生→出队→上层准入→owner→present→后继**，不能只给下层sink填正确basis。正控包括前驱`[5,4101)→中`换镜像、清旧投影缓存、插入自有accepted发布后，两张旧scene后继仍各精确一次；实际service/file单次`x123`必须得到独立oracle的`x123yz…`，不慢打、不重投。负控覆盖外部同字节改版、真人换焦/换绑、错前驱/范围、Will未Change时结构移交、重复完成、关闭/截止。撤回上层准入、发布因果或拒绝登记各应翻红。

拒绝消费须形成一条完整链：故意制造前驱冲突→本票及依赖后继零写入→唯一失败结算→本挂载脏责任→对应安装/采纳/choice→新一笔免点击输入成功；被拒字符不补回。旧挂载迟到失败/旧ACK既不能锁住新挂载，也不能清新责任。同值有/无Change、程序同值回声与正常异值快继保留。

性能与以上机制一起归因，不另从“SDK很慢”猜起。[原20笔逐票分段](../../artifacts/h-bounded-large-20261008/continuation/normal29-guidance-resume/cost20-unicode64MiB-normal30c-actual/RESTORE_PHASE_COST.md)的16笔通知→ACK中位606ms、ACK→完整反馈15.5ms；P00原日志可拆成通知→ArkTS42ms→mounted114ms→attach205ms→setter110ms→ACK132ms→反馈9ms，含重复focus请求和两次detached的showTextInput。按同票补齐mount准备、focus在飞、attach、body-frame、两次confirm实到，先消除可证明的重复工作和不必要重挂，保持真实安装条件/截止，不能只缩轮询或跳ACK。同时正文一次measure66.099ms、20笔正文首帧中位103ms，故修恢复不等于100ms通过；按完整文字/约束/字体身份核缓存，319/333不同宽度不冒充同一排版。旧未配对4笔不借邻票，成功Flush也不冒充物理呈现。

### E．一次汇合原包，不再扩轮次范围

先让上述小链及关键负控成立，再冻结源码、正式入口串行双normal，完成thermo共同来源/恢复/reveal及跨锚反转、Pharos原受影响连续链、原64MiB复杂Unicode20笔并同期RSS、原1GiB首中尾→跨窗替换→首次Undo/Redo→公开Agent→免点击人→保存→正常关闭→新PID固定版本流式全字节核验。旧容量/许可、字体资源、文件安全和资源close按影响复用；不新增GiB全删、全篇visual解析或旧65腿全矩阵。100ms与一般16ms分开如实记账，不因机制绿改预算。

用户下发后连续完成这一原包，不逐项停工、不再以“尚无同一问题裁决”循环等待；本方案被新生产反例推翻才按AGENTS暂停该依赖并明确哪条前提不成立，独立工作继续。不调用外部顾问、不新建执行卡，短更本页/ACTIVE H/原索引；E/W、用户资源、旧原件、暂存/stash保持，无stage/commit/push。本次指导仅复核源码与原件、更新文档，未构建、测试或操作设备。

**normal30 实施接续（2026-10-10，已恢复后具体升级、goal blocked、整包未完成）：** 共同上层原票准入与缓存拆退休、typed owner receipt 同步/延迟present、自有前缀保输入面、含Will未Change的固定Transfer及原票唯一结算已接。正式normal候选b（80481fb7…/PID26706）真实service/file一次x123四票各一次、owner2→6、ctx1、全文262135B精确通过；不等于完整反馈通过。恢复补确认另补真实owner推进而镜像仍旧的生产函数反例：RED31/32→33/33，撤回新增补确认预检后指定例RED，不重复setter/业务。

**新实际反例及具体升级：** normal原x123同owner6/ctx1的accepted反馈已为interactionCurrent0；SDK中已接受的平台后像12291、截取accepted排版12288，下一真实点击painted_layout_stale，未投递新JKL。typed保ctx修掉字节快继却未闭合accepted排版/新选择/新根覆盖，这是本次新增状态归属边界。[精确升级](../../artifacts/h-bounded-large-20261008/continuation/normal30-guidance-resume/ACCEPTED_BODY_POSTIMAGE_LAYOUT_COUNTEREXAMPLE.md)保留normal及专用SDK原件、必要源码判据、每次夹具差异、待区分覆盖与建议验收。按AGENTS暂停该依赖的猜修/64MiB完整反馈/1GiB受影响连续门，已请求针对这个边界补充指导；不是重复等旧normal30裁决。原件中的一次无闸门Agent交错未形成；专用交错第一次误保持GET_CONTEXT，UVW正常接受/Agent版本冲突；第二次零JKL先遇点击失败，均未冒充拒绝链成功。

独立normal候选已完成正式串行构建和实际消费，424共同输入（845a3f11…）逐项匹配：[正常包/启动/冻结身份/原件](../../artifacts/h-bounded-large-20261008/continuation/normal30-guidance-resume/frozen-normal-consumer-candidate/README.md)。Pharos755d7a6e…/29692正常新PID全文读回已保存262138B并正常关闭；thermo6ab421b2…/8987一次gesture4固定锚2，静止2991/2998ms有72/125次accepted滚动，跨锚61→1、UP停止、reveal293→354、免点击X及后续Z精确，其他字段不变并正常关闭。初版后处理误把排序range当有向范围，false原件保留；只读复核原API/样本确认跨锚，不重投手势。60.598秒连续原片1774帧/drop0。两应用fonts/lease/image/tail归零，thermo实际destroy持有input1/choice1→0；不扩大为峰值RSS。preclose单点RSS/HWM另列，原20同期RSS仍欠。暂存/stash字节身份保持。这是带已知RED的正常候选，不是最终完成包。[接续索引](../../artifacts/h-bounded-large-20261008/continuation/normal30-guidance-resume/README.md)。独立补[SDK外部退役拒绝分支](../../artifacts/h-bounded-large-20261008/continuation/normal30-guidance-resume/controlled-sdk-refusal-original-mount-once/README.md)：PID23000，唯一service/file先推进owner1→2，单次STU三票各拒绝一次/全文零STU；request2旧ctx1因外部版本终结，旧ACK不影响新ctx2。新request3安装/采纳/choice后一次免点击N、owner2→3、262144B精确。此为旧脏挂载真实外部退役分支，不拿新request3 ACK冒充旧request2原挂载恢复。SDK单N完整反馈380ms不作为normal20成绩。随后归还normal755d7a6e…/26650，此前保存262138B原件保持、正常关闭，生产源码未变。原20/RSS/100ms、原挂载存续拒绝后的最终确认/续写及1GiB完整门尚欠；旧资源双normal、文件安全/容量及成本RED保留。无顾问、无stage/commit/push，E/W与用户资源保护。

**当前具体阻塞复核：** 平台已接受后像12291/accepted排版12288的同一覆盖与新选择/新根来源边界连续三个goal轮次仍未得到技术接续，424冻结源码无漂移。前两轮已完成全部可独立的双normal消费、thermo跨锚/UP/reveal/续写/关闭，以及真实SDK外部版本退役的拒绝分支并归还normal；无在途构建/设备实例可等待。其余原挂载存续拒绝恢复、64MiB20/RSS/100ms与1GiB受影响完整链依赖这一边界。按AGENTS状态归属首次实质修复失败后的具体升级规则，停止该依赖猜修并将原goal标为blocked；目标不缩减，旧成果/失败原件保留，等待针对accepted正文覆盖、平台后继与选择来源的技术接续。不是旧normal30 FIFO方案尚未落实，未调用顾问或进行stage/commit/push。

<a id="h-large-normal29-adjudication-20261009"></a>
## normal29 三个反例的接续方案（2026-10-09，历史；未冲突部分保留）

**判断：普通选择来源发布和松手后的reveal存在共同框架漏接；上一轮同值owner-first取消出口未通过其要求的SDK试验，撤回该出口。** 拒绝后代理未恢复是实测现象，但精确失败层尚未确定。不能把三项都归为产品问题、工具问题或一句“等裁决”；也不能把安全拒绝普通首字当作输入通过。本节给实施方案与区分门，不接管执行。用户尚未恢复本次blocked任务；本次只读复核三份材料、实际源码和本地参考，未改生产、构建、测试或操作设备。

原件：[normal29候选交付](../../artifacts/h-bounded-large-20261008/delivery-normal29-candidate-20261009/README.md)、[普通选择来源及拒绝恢复](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/ORDINARY_SELECTION_SOURCE_PUBLICATION_COUNTEREXAMPLE.md)、[同值取消后继](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/SAME_VALUE_CANCEL_SUCCESSOR_COUNTEREXAMPLE.md)、[松手后可见边界](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/THERMO_RESIDENCE_VISUAL_BOUNDARY.md)。normal29 Pharos `1a22a448…` / thermo `a08326d1…`是候选，设备已恢复normal28；不能从文件存在推定设备正在运行候选。

**保留和复用：** normal29的Back/Home执行资格、明确新点击重新授权、私有字体集合18对几何/像素、10分钟资源观察、四次正常关闭及64MiB固定全文核验按原范围保留。它们没有证明原20笔/100ms或1GiB完整写作通过。许可已经执行，不再列作依赖。共同机制继续落在CJGUI的window/native/registry，Pharos与thermo只作薄接线和正常消费；不改E/W写集，不另造输入引擎，不自动咨询。

### A．正文与选择各有发布责任，输入仍持不可变来源

**已定因。** 普通kind33不要求新present；`adoptOwnedTextSelection`推进会话choice后，native的`ownedMirrorAccepted.sourceBasis`仍须present才更新。PID14944同挂载、同正文、同版本，平台首字冻结rev2/global0:0，owner已采纳rev3/global204:204/local122:122，因此拒绝正确，发布路径不完整。不要删除revision门、把当前basis补给旧票、强迫每次点击重绘整个正文。

1. **保留正文staged→present→accepted事务；补独立的已采纳choice记录。** 记录依附exact accepted正文身份（owner/source版本、mirrorRevision/绝对起点、正文、node/resource/kind和两层binding），另带choice版本/revision/方向/绝对与局部范围。普通真实观测或原恢复ACK完成采纳后，在同一owner执行序冻结事实，经native同锁条件发布。来源须是产生时冻结的observation ID或带类型的restore request ID，包含exact ProxyKey与focusGeneration；不可用出队计数充当产生序号。
2. choice-only发布只更新输入选择依据，不晋升staged正文、不改accepted场景、不重发setter、不生成业务编辑。同事实重复幂等，同号异事实拒绝；旧观测不得覆盖新choice。同正文身份的晚到候选提交应保留较新choice，正文/绑定真换代才退役旧choice，候选失败保旧。不能机械把所有`ADOPTED`返回值都当平台已安装：待恢复的非空目标分支仍没有新输入资格。
3. **一起覆盖“点击后马上输入、owner尚未消费选择”的间隙。** native在产生选择事件时冻结单调observation ID、正文/挂载身份和真实局部范围，随原事件FIFO；Will若在choice发布前到达，冻结对这条确定观察的引用及原正文依据，有界持留，并与该ID的唯一owner采纳结果配对后执行。不能取旧choice继续、不能出队后读取最新选择补票，也不能因为发布慢而丢掉正常快打首字。选择被拒/换代时依赖输入具名终结并恢复；容量须在允许平台推进前准入，不能事后承诺已经接收。复用当前票据队列，必要的内部来源接缝允许补齐，不扩公共Node/Event POD。
4. 已发布choice路径直接冻结完整basis；待配对路径冻结的是不可变观察引用，后续得到的是该引用的验证结果，不是改写旧票。实际Backspace/删除范围可以不同于当前选区，仍以真实Will范围及共同操作契约判断，不能新增一刀切的range==selection门。程序选择须走原安装与采纳，不凭读取到目标值取得输入资格。
5. **事实读取、输入准入、恢复执行分开。** `ohosInputSourceBasis()`读取事实不必以“已安装”为前提，否则恢复会陷入必须先恢复才能读来源的循环。能读上下文不授权attach/show/focus；Back/Home资格保持。恢复和新输入各自核原票资格，不用一个getter成功代替所有授权。

**拒绝恢复的有限归因与修复：** `input_source_ticket_stale`在`session.replaceRange16`之前返回，故`needsRestore=false`不代表代理干净；但外层已为kind51登记`refusedRangeTextPending`并在FIFO后调用`recoverRefusedRangeTextProxy`。kind10多行输入已在guard内，不再改此guard。现有唯一restore拒绝日志在20:15:16，本次输入在20:15:36，前者不能作为后者根因。

沿这一次拒绝补足“脏代理登记→回滚入口→目标冻结→native签发→ArkTS接收→ACK/终态”的有界同票事实，优先核共同恢复里的提前清待办、目标范围、签发和资格读回。用最后owner接受的正文/选择冻结恢复票，接原共同安装及ACK；即使来源门在事务前拒绝，也须完成脏代理责任。恢复前禁止拿脏坐标签新根输入；已经接受进有界队列的载荷要有明确结局，不能静默清空。拒绝的原字符不重投，ACK失败仅补确认。恢复成功并发布对应choice后，一笔新的免点击输入须成功；Back/Home介入不抢焦、不复活旧资格。

**必要反例：** 普通选择→零present→首字；选择事件尚未被owner消费→立即首字；choice发布后旧候选提交；ABA同坐标旧revision/同字节新正文/换镜像/旧mount；待恢复非空观测无资格；旧已签发输入不借新choice；拒绝后真实恢复→新输入。须串联真实产生/发布/消费函数，不再只给sink手填正确basis。先复现原64MiB一次点击→一次首字，再正常thermo/Pharos消费。参考本地Flutter `editable_text.dart`的`_handleSelectionChanged/updateEditingValue`与`_updateRemoteEditingValueIfNeeded`：选择通信与正文画面分开；不复制其运行时或削弱CJGUI身份。

### B．同值修改保留平台自然推进，业务命令与平台确认分开

**撤回normal28 B.4的return-false方案。** SDK PID11854单次`x123`证明取消后0:1没有折叠，下一笔实际仍替换0:1，得到`123yz…`。这是本次指导候选未成立，不能责怪执行者没多重试，也不能给后继重贴1:1。改为非组合、非已登记publication且来源完整的同值Will：先有界准入一次明确修改命令，返回true让组件按正常语义推进选择；异值路径仍配真实Change。不等待同值可能不存在的Change，不把Will/return true/owner回执任一项单独称为平台安装完成。

**必须成组处理的四个接缝，不能只删`before==after`：**

1. ArkTS当前同值只是return true，尚不生票；native `input_will`拒同值；`editorEnqueueTextCommit`又在有actual票之前将同值转成整值回声。只为具有完整实际修改票的同值新增原FIFO语义命令出口；无票同值echo、已登记程序publication继续零业务事务。命令入队一次，迟到同值Change只作对应票观察，不能第二次提交或误消费后继票。非owned及marked原路径按其既有适用边界保留。
2. **显式输入流前驱代替“最近相同文本”。** 当前native优先看`decl.text==before`，同值后会错误回到predecessor=0；`lastCompletedInputTicket`实际仅证明平台Change已入队，不证明owner已接受。共同流头应清楚记录命令/Change/owner回执各状态，同值与异值均连真实前驱；publication、导航、换挂载、外部冲突是带依据的流边界。owner按票序核前驱实际回执、原挂载/焦点、before==前驱本地后像，不凭字节相等跳过前驱。A的选择观察引用与B的修改前驱放在同一来源链，不建互不认识的两个队列。
3. **跨窗后继保留其真实局部坐标，补经过owner验证的后像映射。** 前驱跨全局选择替换后会reveal换镜像，不能再要求仍在平台中的有界后像必须等于当前新镜像，也不能拿新镜像解释旧局部数字。对当前plain-source路径，可从前驱冻结的全局替换`[A,B)`和本地prefix推导候选`postOrigin=A-UTF8Bytes(before[0:start16])`；这只是候选，须非负、边界合法，并在前驱真实owner回执的新版本上，核该有界区间逐字节等于native后像，连同suffix/范围关系成立才签发映射。后继真实range不变，通过这份证明转绝对源跨度，继续共同版本化owner事务；不走产品私有splice，不读取整个GiB。归一化、外部改文、非直接映射或校验不符具名冲突，不能套公式强行通过。
4. 已接受的快继输入保留载荷/序号/原截止；旧发布或恢复不得覆盖尚在消费的合法native后像。owner失败时结束依赖链并走共同恢复，已接受前缀不重复提交，后继不偷偷转成新根。owner全文真同值沿原no-op/版本契约，不强造+1；平台选择是否折叠由真实观测或可核同身份后继事件确认，不能仅从rangeAfter推测。队列容量包含在途、配对、失败恢复持留，满载明确拒绝，不无界缓冲。

**先做原SDK的单一分叉，再接共同owner。** 原0:1一次`x123`，同值登记命令且return true，无慢打/重投/补setter；核真实后继before为1:1、终值`x123yz…`。再核同值→异值、异值→同值、连续同值、同值有/无Change、程序同文publication零事务及真实IME普通提交；非空marked未观测仍不称通过。随即在真实owner小文件跑同一链及拒绝恢复，最后恢复原GB重复正文跨窗＋立即后继。原return-false RED保留；“安全拒绝第二笔”不是成功。小链通过后不再另开泛泛调查轮。

参考本地Flutter `FlutterTextInputPlugin.mm::insertText:replacementRange:`保存实际replacement range和delta；借鉴语义修改不等于全文差异。该参考不替代本机SDK对照，也不授权取消后用setter抢在下一笔之前改坐标。

### C．松手后继续共同reveal，不依赖再发一张场景

**已定因的部分：** `revealEditingCaretIfNeeded`只在accepted结算调用，capture期间只return、未持留；UP的`clearPointerCapture`和`stepWindowActivities`不接续它。原件UP后只有同429的native redraw，caret61为278.528..309vp、可见带从310vp开始，活动端不可见。共同host仍在运行，不是整个泵睡死。**未定因的部分：** native getter还核context/scene/paint ticket/surface/geometry/caret/正文/binding，当前失败统返0；draw日志不能证明getter成功，也不能证明完整clip链可达。

1. 将capture期间让位的reveal持留在共同window活动中：冻结会话/绑定、owner内容身份、有效选择来源与手势，只持有一份待办。持续按住期间由手势存活/取消约束，不把20秒合法驻留当作安装失败；首次解除capture具备执行资格时冻结一次执行绝对截止，此后等待paint/accepted不得续期。同手势真实选择提交可更新活动端依据，不能由paint本身产生选择权限。UP在最终选择消费并清capture后使其可运行；`hasActiveWindowActivities/stepWindowActivities`实际消费，native同scene redraw完成也能通知几何进度。render线程不直接写viewport，不持锁回调，不强造present、恢复票或setter。
2. 在既有getter门内给只读具名失败原因及同锁身份，区分“没调用”“已调用但几何/身份尚未就绪”“可读但无可达滚动方案”。等待真实paint/accepted进度沿原request和截止，不忙转、不每帧重签；成功发viewport请求后须等待对应accepted几何证明活动端可见，才终结。
3. 复用`composable_ui_reveal_plan.cj`的活动端小矩形及真实clip owner/scrollPrefix/requested/accepted/max。不要reveal整个934vp文本节点、缩caret或夹offset造成功。只剩1vp可见时核真正可动祖先和共同可达方案；不可达具名结束保旧。原数据推算约32vp只是假设，不能写死该位移。
4. 新人类滚动/新手势/换绑/owner推进/关闭按来源退役旧待办，旧redraw零作用；不能在所有clearCapture路径无条件抢回滚动。正常释放且选择来源有效可接续；取消因新意图取代则让位。Back/Home不重开键盘、不新签focus，已有显式焦点执行门保持。

**必要反例：** capture让位→UP→仅同scene redraw→原request可见且owner/选区不变、setter不增；getter首次stale后原身份就绪；旧请求被新意图取代；已可见零滚；真实不可达；未就绪原截止唯一终态。撤回消费/通知应翻红。正常thermo一次BEGIN→驻留→反转→UP→免点击替换，必须连续采到BEGIN和UP；旧环形日志缺BEGIN不能补称完整通过。参考本地Zed `scroll/autoscroll.rs::request_autoscroll`持留请求并notify、`element.rs`布局消费后重取snapshot、`element/mouse.rs`的已有请求保护及测试，复用CJGUI已有planner/viewport提交。

### D．接续顺序、原完成门与保护

按A把选择采纳及拒绝恢复接齐，B与其共用来源链；C可独立实现，设备和同target构建串行。先跑上述能区分的真实生产反例、关键撤回及一个SDK分叉；小链成立即冻结一次源码，正式入口串行双normal。不得反复用手填basis的小测试替代真实产生链，也不因每项局部绿色停止。已有正常Back/Home、字体语义/资源及文件安全原件只对受影响部分回归。

原包门不缩不扩：thermo共同来源/恢复/reveal与其他字段零污染；Pharos原有界连续写作、同值/异值跨窗与快继、拒绝后续写；原64MiB复杂Unicode20笔和100ms完整反馈；原1GiB首中尾→跨窗替换→首次Undo/Redo→公开Agent→免点击人→保存→正常关闭→新PID固定版本流式全字节核验。保留原容量/许可/service安全证据，不新增GiB全删或全篇visual解析。新增票据资源与关闭需核释放；原10分钟/正常关闭资源证据按影响复用。未达到100ms或一般16ms不能凭已归因宣布达标。

用户下发接续后自主完成相关内部接缝、反例、双消费者及集中交付，无须再询问是否允许上述方案；新的实质反例推翻方案则按AGENTS只暂停该依赖，并给具体差异，不循环报“未获裁决”。不调用Pi/GLM或其他外部顾问，不新建执行卡/轮次台账，只短更本页、ACTIVE H及原索引。源码清单/HAP/运行PID与输入类型必须对应；E/W、用户实例/正文/剪贴板、stash/暂存和旧原件保持，无stage/commit/push。

**normal30c集中验收（2026-10-10，原包仍未完成）：** 已依本节补共同选择观察/唯一采纳、same-value Will语义命令及下层前驱有界后像、capture后共同活动reveal；原SDK一次x123 return true真实后继/终值通过，native实际函数与窗口下层25、受控恢复31、同值caret幂等1、pending present运输RED71→GREEN0及关键撤回均有原件，不扩大为完整产品链。冻结424份共同输入，正式入口串行Pharos e22422d7…与thermo 181b6ef6…，两消费者实际文件/manifest逐项匹配。真实普通点击立即一字通过；同PID8486原64MiB20笔每笔一次投递/一笔owner/精确字节，保存v22→正常关闭→新9504固定1025段全文67109137B、SHA e2bbf8a5…通过。完整反馈97–1018ms、中位727.5ms，仅1/20≤100ms，仍RED；本轮20未同时采RSS，不借旧PID补证。thermo2492一次BEGIN/同手势两个静止区间91/130个accepted offset、固定锚/反向收缩/真实UP/同scene581重绘progress608→609接续原reveal→accepted582可见→免点击X及其他字段零污染通过；未跨锚，不称方向翻转完整通过。真实service/file小链一次x123得到x1yz…，后两票在上层旧projection resolver拒绝，未进入新的前驱证明，也未登记本次失败完成/拒绝恢复；补实际上层函数反例前驱已接受且postOrigin=5，resolver返回-1。[精确升级材料](../../artifacts/h-bounded-large-20261008/continuation/normal29-guidance-resume/UPPER_RANGE_FIFO_AND_ROLLBACK_COUNTEREXAMPLE.md)记录调用层差异、原字节/范围、测试夹具校正及建议区分点；依AGENTS停止这条状态归属依赖的继续猜修，原1GiB完整链依赖未闭合，其他独立验收已完成。三次本轮正常关闭字体live0/lease0/tail0。原normal29 Back/Home、字体资源、文件安全及原1GiB容量成功按原范围保留，旧RED与run10/r31/final6未覆盖，不调用顾问。额外thermo Agent诊断误用超64unit载荷且误判后重复一次，两次note_out_of_range均零改文，失败原件保留、不计Agent人续写通过。[同源正常候选与启动/冻结身份/成本/明确剩余](../../artifacts/h-bounded-large-20261008/delivery-normal30-candidate-20261009/README.md)集中交付；无stage/commit/push，E/W与用户资源、stash/暂存保护。 独立接续补[新增票据destroy回收](../../artifacts/h-bounded-large-20261008/continuation/normal29-guidance-resume/INPUT_TICKET_DESTROY_RESOURCE_EVIDENCE.md)：实际固定槽RED21→GREEN0/撤回RED21，SDK原生静态编译通过；补私有destroy数量日志后规范renderer605a7ad6…，已串行冻结[资源回收双normal](../../artifacts/h-bounded-large-20261008/delivery-normal30-candidate-20261009/resource-close-normal-20261010/README.md)（Pharos eb1f7347…/22168、thermo f921cfe1…/25609），424共同输入/消费者manifest全匹配。各一笔真实Z精确、thermo其他字段零污染，正常关闭票据终值0/字体0/lease0/tail0；Home已先清空票据，不把此设备终值当持有载荷释放或峰值RSS证明。thermo投递前格式读取错误原件保留，零输入后沿原PID/原焦点完成原意图。旧normal30c冻结原件保留。原20笔补16条原恢复票完整分段，通知→ACK521–783ms/中位606，ACK→完整反馈8–26ms/中位15.5；100ms与缺RSS仍未完成。

<a id="h-large-normal28-adjudication-20261009"></a>
## normal28 三项升级的具体接续（2026-10-09，历史；未冲突部分保留）

**normal29复核更正：** 下述B.4的同值return-false候选已被快速后继SDK反例推翻，停止采用，以本页当前normal29方案替代。A焦点执行权、C资源责任及既有有效证据继续保留；历史文字不是重新启用被撤回方案的授权。

**本轮判断：三个阻塞有实际依据，应回共同框架解决；1GiB许可已经执行，不再是依赖。** 保留normal27/28共同恢复、驻留、文件安全和1GiB首中尾/保存/新PID固定全文核验的原范围。接续推进两项框架能力：显式来源的输入/焦点执行权，以及可回收的字体排版资源。不是另造编辑器、改输入法或重新验全部旧矩阵。这里给出具体实施方向，未运行生产修复、测试、构建或设备；执行状态仍待用户恢复。

复核材料为[成本与资源升级](../../artifacts/h-bounded-large-20261008/continuation/normal27-adjudication/UNICODE_COMMON_OWNER_COST_ESCALATION.md)、[结束编辑执行权升级](../../artifacts/h-bounded-large-20261008/continuation/normal27-adjudication/KEYBOARD_DISMISSAL_OWNERSHIP_COUNTEREXAMPLE.md)、[范围修改升级](../../artifacts/h-bounded-large-20261008/continuation/normal27-adjudication/SOURCE_RANGE_COUNTEREXAMPLE.md)。这次已读实际生产函数、SDK头/声明和材料中的原件；CodeLattice snapshot项目分析因模型IO错误失败，关系以直接源码核对补证，不把图工具失败当生产阻塞。内部只读分工不是外部咨询；不调用Pi/GLM或其他顾问。

### A．焦点执行资格：文档绑定存活不授权重新拉起键盘

**确定漏口。** snapshot `restoreFocusAfterProjectionChange` 多分支凭owned绑定有效调用focus；native checked focus只核绑定/几何，`beginEditingOnNodeLocked` 在context仍live时也可能再次通知平台focus。共同 `submitAndFinish` 的reason只写日志，native finish看不到结构结束依据。故Back后ctx3结束、accepted382又建立ctx4的原件有共同源码解释。SDK对照同时证明Back、切字段、程序stopEditing和卸载都可产生editing=false/blur，不能从单个回调猜人类来源。

**裁决：在共同window/native/registry引入或接通一份焦点执行资格，独立于owner版本和会话存活。** 先复用已有实例/会话/绑定/挂载及前后台身份，缺失的最小内部字段和传递接缝允许补齐；不要求另开公共框架设计。

1. 真实命中、明确的公开focus操作可签发新意图代；合法结构交接只能承接尚未撤销的资格。owner改文、Agent普通改文、accepted发布、onFocus回声和选区ACK不能签发新资格。人和Agent的显式focus走同一授权入口，不能把普通业务更新暗改为focus操作。
2. 发起程序stop/卸载/reconcile之前，登记操作号、exact旧ProxyKey、目标身份、原焦点代和原恢复票；旧端退役与登记有明确顺序。复用页面已有`retireForReconcile → pending → 卸载`接缝，归属放共同类。不得blur到达后才补来源，也不得仅因存在某个pending就把当前结束认成结构结束。
3. 已登记且已退役的exact旧挂载终态只收旧端，不提交旧草稿、不撤销新端。当前挂载没有前置结构依据的结束记`platform_end_unknown`并撤销本代执行资格——不谎称一定是人工，但必须尊重平台已结束。owner正文、全局选择和其他字段会话保留。Home/background同时作为强执行栅栏；回前台本身不复活被dismiss的资格。
4. 结构恢复、projected/semantic focus、native restore/caret、ArkTS delayedFocus/重挂最终消费同一资格，native实际执行点再核代次，关闭查询后到执行前被Back/新点击打断的竞态。仅给`restoreFocusAfterProjectionChange`加一个Bool不够。合法原票保留request/seq/绝对截止与唯一setter；撤销只终结本资格所属待办一次，不全清pending、不重签延期。

**固定区分：** Back→unchanged/end→多次刷新/Agent改文仍零focus、零重开；Home后后台改文零focus，回来不自动重开但一次新点击可输入；已登记结构往返接续原票且免点击首笔精确；旧mount终态在新mount之后/重复/异字段均不误撤销；旧恢复发送前被新意图抢占零focus。先真实函数RED/GREEN和关键撤回，再用normal thermo/Pharos各消费受影响路径。

参考已核：[Flutter focus_manager的keyboard token](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/focus_manager.dart:969>)与[editable_text连接关闭](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/editable_text.dart:4279>)。借鉴的是“存活状态与执行权分开”，不复制Flutter运行时，不把其行为当OHOS证据。

### B．跨窗修改：保留实际替换范围，同值意图不能等待不存在的Change

**源范围门正确，不删除。** 当前`editorEnqueueTextCommit`只从有界旧/新全文求最小差分；原GB global0:12291/local0:8192被压成0:0，局部后像正确却丢掉实际选择。`source_selection_proxy_range_stale`应继续拒绝。共同`onWillChange`目前没有普遍保存options；同值提前返回又使合法无Change意图无执行入口。SDK原件已证明程序赋值也有Will/Change、同值替换可能只有Will，不能以options存在认人输入、以value==draft认回声，或以rangeAfter充当最终caret。

**共同修改票是唯一身份，两个结算出口在签发时明确，不能超时后换出口重投。** 产品页面只传平台数据，不在Pharos单独拼选区/重放正文。允许最小扩展OHOS内部NAPI/桥接/事件附带来源；不要无关改E/W公共POD或把当前值补贴成旧来源。

1. 在修改产生点冻结完整ProxyKey/field、node/resource/kind/accepted绑定、context/generation、owner与mirror版本/绝对起点/有界原文、已安装全局source choice及revision/方向/局部投影、本次oldContent/rangeBefore/rangeAfter/插入片段/后像、新旧preview、票号和真实前驱依据。必要source字段须随原镜像声明/安装一同到达平台，不在owner出队时读取最新选择来补。
2. 校验UTF-16标量边界及`old[0:before.start] + inserted + old[before.end:] == proposedNew`，保留实际before范围而非重新最小diff。跨镜像仍由现有`applySelectedSourceEdit/submitCurrentSourceChoice`真实owner事务执行，只增加冻结票复核；不扩成全GiB镜像，不走产品私有`session.applySplice`旁路。
3. **异值路径先保留平台正常推进：** Will冻结票，实际Change须与同挂载、原文、范围和后像配对，一次消费后经原native FIFO/owner提交。旧mount、缺依据、正文/范围/版本不符仍拒绝，不能把最后一张Will当成任意Change的来源。相同机制保留非owned普通控件及原marked路径的适用边界。
4. **同值但有语义的非组合替换，采用有限owner-first出口。** 当次新旧preview明确非组合、来源完整且不是已登记程序发布时，共同桥在有界准入成功后冻结命令，`onWillChange`返回false取消组件原修改，异步走同一native FIFO和真实owner事务。owner成功后由共同发布/原安装确认同步正文与选区；不能等待原Change、不能把Will返回值当owner或平台完成。owner全文也同值时沿既有no-op/版本契约，不强造+1；选择折叠独立确认。此出口是本轮批准验证的候选，**现有SDK证据只覆盖return true，尚不能宣称return false链已验**。
5. 所有挂载、owner/restore正文写回和既有纠正操作，在写组件之前登记完整publication票。只有匹配未消费发布票的回调作为程序回声，初始无Will的Change也要有初始发布依据；不得让程序更新生成业务事务。迟到/重复回调不重新消费。异值owner拒绝走现有`refusedRangeTextPending/recoverRefusedRangeTextProxy`和原身份ACK，恢复前不接受用脏草稿产生的新坐标；owner-first尚未改组件的拒绝保原值，版本已变则沿原reconcile。ACK失败只补确认，不重写owner。

**先用原有小SDK诊断做一次必要区分，然后直接接生产，不再铺一轮泛泛调查。** 验return false确实取消原修改；已登记发布仍能到达且不递归生票；焦点/键盘保留；同值后立即2–3笔、异值/同值交错和软IME实际提交完整。后继输入保全属于本出口本身：每票容量先准入，携真实前驱/坐标依据；不能取消后丢笔、用慢打等恢复、或仅按FIFO就把旧选区重贴成新caret。优先复用已有共同输入待办/来源/恢复机制，不能为一个同值边界把所有输入重写成另一套编辑器。若真实SDK取消路径或后继依据被反例推翻，只暂停该出口并交回具体新反例；不得把同值丢弃、延时帧读数或DidInsert缺失当成功。

**必要反例与正常消费：** 原global/local重复正文RED；局部同值/全局异值；owner也同值；完全相同metadata的程序回声零事务；同字节新版本/镜像换窗/选择revision改变拒旧；旧mount/重复/缺options；快速后继不丢不重；owner拒绝后真实恢复并免点击续写；ACK失败不重写。真实候选确认已可用的hook按当次来源消费，不能要求所有路线都有DidInsert；组件非空marked仍未观测的部分保留未验，不拿输入法候选隐藏冒充marked取消。小链成立后恢复原1GiB跨窗替换→首次Undo/Redo→公开Agent→免点击人续写→文件链。

参考已核：[FlutterTextInputPlugin的insertText:replacementRange:](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/engine/src/flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.mm:796>)保留旧文本和实际替换范围，framework `setEditingState`为独立发布。华为[TextChangeOptions/回调说明](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-text-common)仅作接口依据，实际同值/程序回声语义以本设备已归档实验为准。

### C．Unicode资源与100ms：有生命周期的字体集合，加独立的恢复成本修复

**这次可批准生产资源归属，但不能宣布全部RSS或性能根因已定。** 独立真实Typography四个不同正文对照复现持留；私有collection销毁释放52,629,632B，另候选collection销毁释放39,563,088B且旧Typography仍可画。这说明缓存责任独立于单个Typography销毁。生产`layoutTextStyled`仍全用global，`Measured/PaintedTextLayout`没有对应collection持有责任。原20measure中位106.5145ms、paint6.6995ms、measure排队0.0965ms，完整反馈中位1087.5ms；另有重挂/attach/正文落定/确认成本，不能归为一个缓存问题。

1. **共同renderer内部持有可共享私有FontCollection代和布局租约。** 使用SDK `CreateSharedFontCollection`，由实际Typography及其measure/paint/presentation租约持有；先销毁Typography，最后引用释放后再由正确渲染线程销毁collection。复用布局必须连同collection引用转移；候选失败只收候选，Flush成功才提升，旧accepted命中/画面/光标不受损。不得把裸指针暴露到公共仓颉接口。
2. 不是每笔/每帧clear或重建。相同字体环境在预算内复用，按已准入不同排版工作量及字体配置代轮换；失败候选也计费，accepted/candidate/retiring都受有界代数与工作量预算约束。旧代仍被布局持有时不得偷销毁，也不得无限开新代；需要迁移仍活布局时沿现有准备/失败保旧机制推进，避免预算永久锁死。A2的UTF-16工作量不是实际cache字节，实际allocator/RSS、代数与布局引用分开报告，销毁成本计入测量。
3. **字体语义是准入条件。** 当前生产指定HarmonyOS Sans，先证明该明确字体、fallback、CJK/emoji/组合/BiDi、runs/字号/权重/宽度在新provider上与原输出一致；字体/配置换代进失效键。SDK说明global提供主题字体且禁止释放，不能把私有collection当成主题等价。需要主题而无可验证私有provider时保留具名global路径及其资源边界，不静默换固定字体或宣称全部字体问题已闭合。禁止Destroy global、每笔ClearFontCaches(global)、强制GC、缩镜像、任意分段测量累加。原24573B镜像是无换行混合BiDi/ZWJ/组合单段，随意切开会改变几何。
4. **同时闭合多余重挂和几何单位。** 复核原同请求时间线，对每笔ctx推进区分本地已接受事务、真正外部改版、结构变化；只有完整来源票可证明的本地连续性才能保留同一组件，不能靠同字节放行。合法外部/结构换代继续原共同安装，去掉不必要重挂与串联固定等待；真实正文落定、attach和跨帧确认仍保留，不改成即时ACK。native快照已是vp，两产品再次除density的错误需在共同几何契约修复；分清完整layout尺寸、裁剪后的可见代理盒和caret/selection转换，不能只删除法后把数千vp TextArea铺满，也不能改真实排版宽度换快。
5. 同身份同输入的重复measure/paint可沿完整键复用，319/333不同宽度不可强合。固定原20不同正文冷工作与暖态复用分开，不能用相同正文反复缓存命中替换原负载。若剩余确为必要系统排版大于预算，保留具体输入/调用/耗时RED，不宣称系统极限或以已归因冒充达标。

**最少资源门：** accepted活着时候选排版/Flush失败和退役，旧几何/实际画面/命中仍正常；成功提升/借旧布局/多窗口/取消/关闭不早释不重复释；预算满、旧代被pin、连续失败均不无限增长；原四个不同正文重复若干轮＋同文暖态，证明代与持留受控；字体配置变化正确失效。机制稳定后才在无并行构建条件下跑原64MiB复杂Unicode20笔，分别记producer→正文帧→完整caret/选区、必要排版、队列、挂载/确认、回收与RSS。缺正文frame独立时刻不拿相邻日志差补造阶段时间。原100ms长尾门及一般16ms未通过口径保持。

参考已核：[Flutter font_collection生命周期](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/engine/src/flutter/txt/src/txt/font_collection.cc:28>)及其失效测试、[GPUI line_layout两代缓存](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui/src/text_system/line_layout.rs:586>)与font generation失效。只借资源owner/代/失效与测试，不引入外部GUI依赖。

### D．一轮完成的组织与结束门

先按A/B把输入和恢复执行权接在同一共同注册表/来源票上，C资源归属可独立推进；设备及同target构建串行。不要每修一项停止，也不再将上述已给方案的分叉统称“等指导”。必要内部接缝修改在原交付范围内；若方案被新的实际反例推翻，按AGENTS只暂停该依赖并交精确差异，独立工作继续，失败次数不重置。

有判别力的生产反例与撤回门通过后冻结源码，经正式入口串行双normal：thermo核共同Back/结构恢复/输入来源与资源；Pharos核原有界连续链、同值/异值跨窗与拒绝后续写、原64MiB20笔、原1GiB首中尾→跨窗替换→Undo/Redo→公开Agent→人→保存→正常关闭→新PID固定流式全文核验。既有许可、9MiB非CoW隔离和真实service安全原件复用，除实际受影响不重跑；不新增GiB全删、全篇可视解析、无关65腿或物理机矩阵。短诊断、正常输入和物理呈现的证据边界保持。

正常驻留/取消/关闭需包含新增collection和票据释放，复用原三次关闭/十分钟混合观察门；不以一次RSS下降代替长期有界。统一交付源码/HAP/PID身份、可启动包、原始失败与当前GREEN、成本和具名剩余；不把机制实现当三项门已过。只更新本页、ACTIVE H及原索引，E/W、用户资源、stash/暂存和旧包原件保留，无stage/commit/push，无自动外部咨询。

### normal29 当前执行事实（2026-10-09，实施中，未冻结交付）

用户已恢复原包。A 已接共同 native/window/registry 的焦点意图代、exact 结构结束预登记及 Back/Home 执行栅栏，普通选择、原恢复 ACK 和当前挂载终态分开；native 实际执行点复核身份。真实 native 函数及共同生命周期/两消费者受控路径通过。正式 normal Pharos PID26114 已真实证明 Home/Back 后公开 Agent 改文均不抢焦，返回前台不复活，一次新点击可建立资格；免点击人续写仍依赖下述 B，正式 normal thermo PID32496 同样通过 Back/Home→公开改文无抢焦，一次可见正常新点击建立资格；其余字段零污染。

B 异值已保存实际 Will 范围，完整镜像/source choice 身份随声明到 native，Change exact 配对后进原 FIFO；仓颉复核冻结来源及实际前驱，再走原 `replaceRange16`/owner 路径。native actual-range 隔离撤回翻红，共同配对现为 8 项（SDK可选range端点缺失拒绝）、仓颉 Source/Sink 与生产窗口受控 22 项通过。发布票在挂载/恢复写组件前登记，补全 preview 身份后原代理 20 项、恢复 17/双消费者 44 项通过，未以回声生成新业务票。

**首次正常消费推翻了“来源已接齐”的局部判断。** PID26114 首笔一次 `界` 被拒绝，未重投；仅加只读来源日志的正式 normal PID14944 再一次不同诊断意图 `诊`，原文/字段/exact挂载匹配，但 frozen choice revision2/全局0:0 与真实当前revision3/204:204（局部122:122）不同。普通选择采纳可无新present，而native来源声明只随accepted正文提升；拒绝后的真实恢复也未确认；曾推断input-kind guard漏掉Pharos，经enum核对已撤回（kind10多行输入在guard内），恢复原因尚需区分。完整[来源发布与拒绝恢复反例](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/ORDINARY_SELECTION_SOURCE_PUBLICATION_COUNTEREXAMPLE.md)含原票、源码接缝、受控测试缺口及最小待区分建议。按 AGENTS 状态归属首次实质修复失败规则，仅暂停这个依赖的继续猜改，A/C 与文件/资源独立工作继续，来源门不放宽。

规定的真实 SDK 小实验另产生[同值取消后继反例](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/SAME_VALUE_CANCEL_SUCCESSOR_COUNTEREXAMPLE.md)：return false 确实取消，但非空选择未折叠；一次 x123 的下一笔 107ms 后仍实际替换旧范围，最终 123yz 而非 x123yz。普通 FIFO 不足以保全后继；该候选同值出口接入亦暂停，具名交回前驱/坐标问题。已登记发布的实际 Will/Change 零诊断人票，实际软键盘中提交有完整回调；组件非空 marked 仍未观测。自有 SDK PID11854 正常关闭、消失并卸载，不是 normal owner/file 成绩。

C 已实现私有共享 FontCollection 有界代与 Typography 租约，失败候选保旧，Flush 后转移，渲染线程按 Typography→collection 释放；A2 工作量与 SDK 缓存字节分别报告。真实 SDK PID1868 上原四 Unicode 正文及 fallback/runs/字号/权重/319与333宽共18对排版/有界采样像素一致，十二轮旧accepted保持；创建/销毁4/4、live0，累计destroy30078µs，原数见 [SDK结果](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/font-lease-sdk-once/actual-sdk-result.json)。混合global参考RSS不算纯private持留，主题global等价未宣称。共同可视盒交surface/键盘/accepted clip，vp与完整排版宽度分开；实际构造含小数底沿，隔离撤回floor翻红。正常 Pharos 两PID准确身份关闭均 owner/renderer/待办/引用归零，字体创建/销毁各2/2、live0，累计destroy20832µs与5379µs；thermo准确正常关闭7创建/7销毁/live0、累计destroy334µs，owner/renderer/待办/引用全零。正常Pharos新PID11274完成600.083s、原四正文十二轮共48次真实公开service/file事务及精确前缀读回，存活代观测最多1、单代工作最高258848，RSS起始241844/峰值351256/结束313964KiB；前一分钟峰值351256，之后峰值346916，不能由此宣称全部RSS归因。静默暖观察不算暖态重排延迟。自有前缀已真实撤回到原67109014B，正常保存version50，并固定全文SHA再一致；第四个准确normal关闭亦全零，字体4创建/4销毁/live0，累计destroy132994µs/work714886/refused0，销毁成本未排除。

独立正常文件链已保留：两次公开 Agent 前缀 B29H29 保存，固定快照1025块/至多64KiB读，全文67109014B与独立期望SHA `3a1afc78…`一致；正常关闭后新PID14944真实service新实例又读回同一全文，拒绝字符没有进入文件。这不代称原20笔人输入或原GB剩余写作链。两次正式 normal Pharos 编译/装载成功，诊断HAP `1a22a448…`，共同平台 `5e64b14e…`；是首笔来源RED的候选包，尚非最终稳定交付。thermo `a08326d1…`正式 normal已装载，两包共同469项当前身份一致，14项候选生产源码保持不漂移。thermo本次驻留保留同gesture4的23次accepted滚动、选区从0:1扩至0:61及真实UP停止，但BEGIN/MOVE被hilog环覆盖，原完整门仍false，精确X替换NOT_RUN，未重投。[采集边界](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/thermo-current-common-dwell-once/capture-boundary.json)及连续视频保留；末端备注仅1vp可视高、frame16显示后续区域；原件补得同ticket/proj429真实UP后caret61 top278.528/bottom309，accepted带从310起，活动端完全在外，完整反馈RED。共同capture期间defer，UP后Redraw未见共同reveal新消费，getter资格与调用漏口仍需具名区分，新增[实际画面边界](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume/THERMO_RESIDENCE_VISUAL_BOUNDARY.md)，共同reveal完整反馈不据ACK代称通过。设备已准确normal关闭后保数据恢复原normal28两包，新候选和14项源码原件保留。多余重挂、原20笔完整成本和原1GiB剩余链仍未完成，100ms原RED不变。

原件均留在 [normal29接续目录](../../artifacts/h-bounded-large-20261008/continuation/normal28-guidance-resume)，normal27/28、许可、文件安全与容量原件不覆盖，无顾问、无Git写操作。后续仍按D受影响正常门，暂停的具体来源/同值问题按精确反例升级，独立工作不停。

<a id="h-large-normal27-adjudication-20261009"></a>
## normal27 恢复归属与驻留几何裁决（2026-10-09，历史；适用部分保留）

**整体取舍：保留已经实际闭合的退出和排版工作，推进两个共同框架接缝，不继续在产品页面分别补延时。** 本次指导只读核对生产函数、16个受控对照、原设备日志及本地Zed/GPUI，再更新任务文档；未修改生产、运行测试或操作设备。normal27成功与原RED不变。下一轮仍完成原包，不新增编辑器、输入法、全篇可视解析或无关矩阵；没有自动顾问前置。

### A．明确裁决：原恢复票交给共同安装生命周期执行

**已证实的责任断点。** Pharos `onProxyRestore` 在reconcile间隙 `imeCtx==0` 直接失败，设备请求29正是此形；thermo虽然保存payload等重挂，但重入后才新开页面1500ms计时，尚未证明原截止接续。Pharos无正文恢复直接调用页面setter；两页正文回声又固定等30ms后进入同一直接setter；即时读数命中即可ACK。对照中的“attach80ms、回声10ms”和“40ms成功ACK、70ms又被正文重置”分别证明提前安装、提前成功。它们是实际函数的受控RED，不是实际IME或性能成绩，详见[原16对照](../../artifacts/h-bounded-large-20261008/continuation/final24-guidance-resume/mount-restore-diagnostic/README.md)。

**方案在框架内落实。** 复用共同 `arkts/cjgui-text-proxy.ets` 的任务、注册表、attach、唯一setter、确认和settle。Pharos/thermo页面只提供组件、正文回声、焦点和native回执接缝；删除被替代的页面安装/即时成功逻辑，不能留下两套执行器。内部任务/通知接缝的必要最小调整在本阶段范围内；不因需要改相关内部文件再停下来索要逐项批准。

1. **首次收票即保存原请求依据，等待挂载不等于旧票失效。** 使用native已冻结的request/contextGeneration/node/resource/kind/binding/field/正文/规范选区及会话实例依据；若ArkTS通知缺必要项，从原 `ProxyRestoreRequest` 补传，不能在发送/挂载时用当前值补贴来源。`deadlineMonoMs` 已存在于native票据，native也独立到期；将原截止或可核验的等价期限接到共同任务，单调时钟同域或明确换算，不能将native uptime直接与`Date.now()`比较。挂载、attach、回声、确认不得重新开1500ms/8000ms预算。
2. **区分“尚未绑定组件的有效目标票”和“已绑定旧组件的迟到票”。** 前者仅在native当前冻结目标、已声明reconcile目标和请求完整身份相符时有界等待；目标组件出现后绑定exact mount一次。后者遇换context/同context换generation或mount/退役，一律旧票具名终结，不能改写票据去跟随新挂载。等待期间新请求、真人输入、关闭、超时同样按原归属结算；不得把`imeCtx==0`普遍放行。用真实卸载→重挂→attach流程补证，现有`reconcile_gap`只跑入口分支，不够。
3. **恢复取得共同安装执行权，不能向自己让位。** 当前共同 `install/confirm` 遇`host.restoreTaskActive()`一律等待，直接`arm(restore)`会自锁；`arm()`另开seq和8s也不适用。在同一共同状态机明确此次执行来源与请求所有者：恢复自身可以在资格齐全后执行，其他待办让位。会话attach资格仍独立于选择pending，继续复用原异步attach和有界12800009处理，不以正文回声、setter成功或`observed_installed`代替attach事实。
4. **同一挂载attach＋本次正文落定之后，才执行一次选区安装，再由实际观测确认。** 无正文和需正文两路进入同一入口；固定30ms不是正文已落定的证据。已在飞的文本更新必须有对应回声/组件状态依据，排除它稍后把caret重置。setter即时读数不能成功ACK；缺值/异常/错误选区/迟到旧回声/native拒绝均不能借历史通过。共同安装和恢复完成不能互相重复下发同一setter；恢复后同事实旧待办按身份确认结束，已被真人输入取代者不恢复写权，其他独立新意图仍按既有资格执行，不能全局清pending。
5. **终态走正确出口，且区分平台安装和窗口采纳。** 普通安装沿`imeSetSelection`，具名恢复沿原request/context的`imeRestoreAck`并检查返回；匿名菜单恢复也复用共同执行器但保持普通选择的结算语义。不能为同一恢复同时发普通选择和恢复ACK来“确保生效”。ACK成功是平台安装事实，仍须原窗口采纳/当前身份成立才算完整反馈，不修改账本伪造完成；每请求最多一个终态，旧回调零写入，计时器/等待者随终态释放。

**三个有判别力的完成门：**（a）真实卸载与重挂之间收到有效目标票，原request/原deadline接续，未attach零setter，ready后成功；旧mount/换代/永不attach与超时均拒绝；（b）无正文、回声先到attach后到、attach先到回声后到共用同入口；迟到文本重置/异常读数/ACK拒绝不提前成功；（c）共同待办与恢复竞争、在飞确认让位、新人输入抢占，证明一次写、唯一终态、不死等、不释放后再写。原16对照迁移到真实共同路径，保留正控与关键撤回翻红；不要把预期改成允许先失败重签来消掉RED。

**成本也属于本项，不能只交功能。** 原64MiB复杂Unicode20笔、原100ms门保持；现有正文首帧35–109ms、完整反馈99–327ms，说明消除重签也不保证全部达标。先以同操作时间线消除页面重复安装、固定等待和可避免的重复挂载/排队，再测余量。共同类两个32ms确认间隔与页面30ms不可机械叠加。若确认调度仍主导，可依据实际SDK/组件生命周期，以正文落定后的真实跨帧观测驱动共同确认；必须先通过迟到重置反例和真实消费，不能仅把数字改小或即时ACK。measure宽319与paint333不同，不强行共用Typography；对必要排版另计原数。保留旧身份保护、不藏caret、不慢打、不以文字首帧代替完整反馈，不把本方案称为100ms已通过。

### B．驻留裁决：按同一候选布局核坐标，不能只夹紧offset

**新复核结果。** 原[驻留反例](../../artifacts/h-bounded-large-20261008/continuation/final24-guidance-resume/RESIDENCE_COUNTEREXAMPLE.md)中的两次offset回步，在原`live-pid-hilog.txt`均有共同节点仍向前的几何：scene2858→2860，offset6652→6634、root190 y=-6585→-6567，node1122 y=431→429；其内容前缀7016→6996，重基-20与offset-18相消后屏幕前进2px。scene3902→3904同类，offset20880→20879、共同可见行向上19px。**这是accepted几何，不是物理呈现，也尚无稳定源key/测量代次证明FIFO淘汰就是原因。** 不能继续把裸offset回退直接称内容倒退，也不能就此整链转绿。

还有更值得追查的同帧疑点：scene2858 node1119 y317/h46、node1120 y355/h46，两个矩形间隔38、重叠8px；产品当前行gap=12。先核两者确为同候选连续普通行与同源测量（矩形不等于字形墨迹），再判断为何行位置像用了估高而实际高度已经46。不能只改验收忽略这个错配。

**实施入口与一次区分实验：** 复用snapshot `CjguiComposableUiVirtualListState::recordVariableMeasurement/variableOffsetForIndex/updateVariableMaterializedRange`、`materializeVariableHeightList`、`stageExtents/commitStagedExtents`与窗口`stepEdgeDwell`。原动作不变，一次BEGIN→下缘驻留→反向驻留→UP；用有界记录关联首个异常候选：PID/gesture/binding/owner/scene/solve、viewport writer与request generation、稳定源key/跨度/行内锚、测量key/index/revision/width/height/estimate及新增更新淘汰、候选读取的测量代次/最终row offset/accepted rect。不要持续打印全文或无限日志。

- **若是同一候选的高度和位置使用了不同测量集：** 在共同虚拟列表内固定本候选已物化行的有界测量集合，完成测量后用同一集合解行位置/锚与extents，并随本候选一起提交；新增capture/overscan行导致变化时，有限重解或具名待准备保旧，不让半新测量混入已算位置。持留预算包含候选与旧accepted；不可扩成无界历史缓存，也不能用Pharos整文重估补偿。
- **若是晚到滚动/布局候选覆盖新请求：** 修共同viewport请求身份与提交时序；重测只对仍属它的稳定锚重基，不覆盖后到的人类滚动。参考本地GPUI `elements/list.rs::rebase_pending_scroll`及对应重测/滚动测试，Zed `scroll.rs::ScrollAnchor::scroll_position`按当前DisplaySnapshot解锚；仅借算法和测试，不引运行时。
- **若只有合法坐标重基：** 本指导授权在证明前缀修正与offset修正相消、稳定源锚/屏幕行连续、活动端方向正确、无行重叠错配及无旧请求覆盖之后，将跨基准裸offset门校准为“同基准单调＋跨基准稳定源/屏幕连续”。必须同时保留旧viewport覆盖、实际屏幕倒退、行高错配三个能翻红的负控；缺基准证据仍为unknown，不能删除判据或先放宽再找解释。原严格RED原样保留，当前尚不满足校准条件。

修后在Pharos和thermo消费同一共同机制，原一次手势驻留/反转/松手停止及后续替换、首次Undo/Redo保持。不能用`max(old,new)`、累计offset硬夹紧、扩大缓存、清捕获后重启手势来通过。

### C．原包完成顺序与边界

已有关闭Promise/三次归零、冻结帧正文、布局复用/A2与文件安全证据复用；除新改动实际影响，不重新开旧65腿。先形成A共同接线与B一次因果区分，内部可分工，设备操作和同target构建串行；不要每修一点就停。有限反例成立后冻结一次源码，经正式入口串行normal Pharos/thermo，同版完成受影响连续链、原Unicode20笔成本及驻留完整画面，保存原始失败，交付可启动包与精确剩余。若新的生产假设被反例推翻，按AGENTS整理具体分叉问题，只暂停依赖项，不循环猜guard。

**1GiB许可已获用户实际答复（2026-10-09：允许许可，允许继续推进）。** 本轮已按该授权接受 Emulator 许可并启动指定隔离实例 `127.0.0.1:10008`；首次实测可用 21,339,516KiB，系统保存选择器已发布恰好1,073,741,824B夹具（首次默认“我的手机”的原件及工具失败保留；后续已明确选中Documents，正常导入、首中尾三笔增长9B、SAVE、完整归零关闭、新PID重开和固定流式全文精确读回现已通过；重复正文跨窗替换源范围准入RED见本轮升级材料，完整写作门仍未过）。夹具准备、真实Pharos service/file导入与已过容量门分开归档；跨窗替换RED意味着原1GiB完整写作链仍未通过。授权及准备原件见 `artifacts/h-bounded-large-20261008/continuation/normal27-adjudication`。 沿下方原1GiB固定链和已准备的1,073,741,824B夹具，许可到位后只启动已建24GB隔离实例，先核实际容量，正常Documents导入与首中尾/跨窗/UndoRedo/Agent→人/保存/正常关闭/新PID/固定全文核验；不新增许可外操作、不用64MiB代称。许可未到只暂停这条设备链，A/B不再写成“待指导”。E/W、用户资源、stash/暂存不动；无stage/commit/push，无自动外部咨询。

<a id="h-large-final24-guidance-20261009"></a>
## final24 三项剩余的指导裁决（2026-10-09，历史；适用部分保留）

**阶段判断：正常有界连续编辑已取得完整消费，不重开此前来源/A2/驻留设计；只闭合 Unicode 成本、生命周期收尾与真实1GiB原门。** Pharos HAP 实物 SHA `052ad4fe4c772591e667ed020b8763fafc08d9b24f4f503062be3db5f68d11f9`、thermo `278f265fb990b4c8c6fda57a58b6a6749b4929817c12515f0a70230c522db062` 已核对；源码首笔完整链和 thermo 汇总均 ok，1,182 项冻结记录、共同459项和视频按[交付README](../../artifacts/h-bounded-large-20261008/delivery-final24-20261009/README.md)保留原范围。源码未构成GB设备成绩，内部Flush也不是物理呈现。指导仅查原件、源码、SDK和本地参考，不构建/验收/恢复任务；本节给出旧升级的实施方向，不自动调用顾问。

### 一、Unicode：批准冻结帧正文方向，不原样批准隔离候选

当前生产 `ohos_renderer.cpp` SHA `7a06a167…` 与隔离材料一致。[候选](../../artifacts/h-bounded-large-20261008/continuation/frozen-frame-current-final24-readonly/candidate.patch)避免在 Present 中把未获 owner 采纳的 native 后像当作本票正文，方向正确；但原隔离 GREEN 只抽取 draw 文字决策及 caret 门，不能证明缓存、恢复、Flush或成本已闭合。以下同属本次有限修复，不回头猜旧输入guard：

1. **将“不适用”和“owned票据失配”分开。** 当前 helper false 统一进入 `composedBuffer(sess)`，混合了合法组合/非owned路径与声明代、owned binding不符。真实 setter 可独立推进 owned binding，而 draw 外层核的是节点 accepted binding；两者不能假定永远同步。决策应明确区分本票冻结正文、依原契约允许的原生组合/非owned绘制、owned来源失配拒候选。旧票不得读当前 Session 正文补来源。有限反例：同node/resource/kind/acceptedBinding，冻结owned binding5而当前声明6，必须拒绝借用且旧accepted保持；另核同字节新owner、组合输入及合法当前票正控。复用既有 PresentJob、binding/declaredBinding 与失败保旧，不新造产品侧正文镜像或授权例外。
2. **布局身份与交互反馈资格分开。** 候选把 `caretContext=0` 表示旧native坐标不能画；而 `cjguiOhosCanReuseEditingTypography` 要求 paintContext相同。恢复同步正文后 context回非0，Redraw即使正文相同也会miss重排。应保留可证明的布局来源身份，用独立资格判断旧选区/caret是否可发布；不能简单删掉context或binding门。布局键核完整正文、字体/样式/runs、宽度/密度与原资源作用域；命中与交互继续核本次accepted/ticket/context和源映射。旧坐标不得提前显示，恢复后的当前caret也不能永久隐藏。
3. **补真实失败传播与有限复用。** 当前 draw 排版为空只return，提交仍可能Flush并以空candidate覆盖旧layout。这是本路径既有漏口：本帧必需排版失败应经现有帧结果传播，在Flush前拒候选，旧accepted/布局不受损。保持渲染线程持有Typography、Flush成功才晋升、失败不转移旧对象，沿既有A2预算计费。`executeMeasure` 排版后销毁、paint重新排版仍客观存在，不能称候选消除了全部重复工作。先核 draw→Flush→restore→Redraw 的实际layout次数；若measure＋paint仍主导，再在现有有界准备/保留资源内复用完整输入一致的排版。测量固定黑色与实际样式/配色不同，不能直接拿尺寸结果或黑色Typography冒充最终彩色绘制；不引入无界全局缓存或跨线程裸指针。

参考入口：当前 `PresentJob/TextPaintFrame/PaintedTextLayout/publishPaintedLayout` 的冻结与晋升，`executeMeasure/drawNodeText/executeRedraw` 的实际工作；本地 Zed `crates/gpui/src/text_system.rs::layout_line`、`text_system/line_layout.rs::finish_frame/reuse_layouts` 的完整布局输入与帧使用权分离。借鉴缓存键、资源责任及测试，不复制其运行时，也不重写文字引擎。

**先证机制，再做一次生产成本对照。** 实际生产函数链覆盖旧native后像不绘制、owned票失配、组合、正文/样式/宽度/代次变化、排版失败零Flush与旧对象存活、同字节恢复不重复排版、恢复后正确caret/选区重新可见；撤回关键修复应翻红。完成后同正常HAP在原64MiB复杂Unicode夹具执行原20笔，单次投递、同PID/owner/accepted关联，正文精确。分别记录measure/paint/排队/恢复与正文首帧、选区/caret完整反馈；不能用无caret的提前文字帧结束完整输入计时。保持原100ms长尾归因门和一般16ms未通过的边界，不缩夹具、不慢打、不隐藏反馈、不换口径。若余下耗时落在单次必要系统排版，报告该调用/输入量及下一个可区分方案，不能未经测量宣布系统极限，也不开始第四轮无依据猜修。

### 二、退出：接系统支持的异步生命周期，不在UI线程阻塞

三次原件不能合并判泄漏或归零：PID10680完整尾成立；PID11807已见file drain、`host closed ... shutdown_done=1 tail_cleaned=true owner_orderly=true`，只缺stop monitor最终回执；PID24472在surface归还后断尾，owner/file未见。历史unknown保持。

**新的明确依据：** 本机SDK `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/api/@ohos.app.ability.UIAbility.d.ts:429–451` 声明 `onDestroy(): void | Promise<void>`，并说明回调完成后应用可能退出、打断异步操作，推荐用Promise返回。当前产品 `EntryAbility.ets::onDestroy(): void` 仅调用 `entryNapi.appShutdown()` 即返回；native随后由owner/render/独立monitor完成停止。故“只能在UI盲等或接受缺尾”不是二选一。

指导方案：在共同OHOS宿主生命周期接缝中，将**本次appInstance**的停止完成作为有界异步结果接回UIAbility的Promise；产品/thermo仅薄接线。沿 `requestHostStopOnce → owner/file drain → renderer teardown/UI surface归还 → startStopMonitorOnce` 原状态机，不再写第二套stop，不重发停止、不把surface卸载当应用退出。优先复用已有HostState/原生终态；若需要共同异步完成出口，以当前实例、唯一stop请求和单调截止持留结果。不能只等rendererDone=1：须同实例owner有序并真实回收、sessions/unacked/pending/refsUnclosed/activeSurfaces归零且phase=stopped。

Promise等待期间UI事件循环必须继续执行surface归还/TSFN，不用sleep/join/忙轮询阻塞UI。已停止/未启动、重复onDestroy、超时/failed、实例换代、回调失效均具名收敛并释放计时器/等待者；超时不返回“清理成功”。截止与既有10s monitor协调，不层层叠加超时或申请后台保活。按实际API24的系统关闭行为验证，不假定Promise可对抗强杀。关闭早期就启动宿主侧连续采集，按PID/launch/appInstance归档停止请求、owner返回、surface归还、最终settled；必要时由真实终态点写一份有界只读回执，不能由测试器补零或事后拼另一个实例。

有限反例：surface归还需要UI循环时Promise仍可完成；重复请求只停一次；旧实例完成不能结束新实例；故意留一项未归零必须拒绝成功。随后在normal包做三次正常关闭及新PID全文核验，完整归零在进程退出前成立。系统强制杀进程/未触发onDestroy单列中断恢复语义，不要求不可能的强杀后析构日志，不以该路径替换原三次正常关闭门。未受影响历史/保存安全反例复用。

### 三、1GiB：只隔离许可依赖，准备和其他两项继续

当前6GB设备空间不足，已创建24GB隔离实例 `H bounded GB 20261008`；启动原件确实提示三份软件许可。[原文](../../artifacts/h-bounded-large-20261008/continuation/emulator-start1.txt)保留。指导本聊天已向用户请求授权，**截至本节写入尚未收到答复**。执行者必须依据用户实际答复；未授权前不接受/绕过，不把本提示词当许可同意，不重复请示其他已授权开发。Unicode与退出不依赖新设备，直接继续；可先完成夹具流式准备工具、磁盘峰值预算、原链参数化。

**2026-10-09 用户质疑空间后的实测复核：** [磁盘原件与可恢复清理](../../artifacts/h-bounded-large-20261008/continuation/storage-review-20261009/README.md)确认现有 Pharos 约951MiB中有多轮工作副本、旧底本和24,639个旧看门狗日志；并非构建包占满。五份旧64MiB底本及旧日志先归档并校验，再定向清理，其他145份私有文件身份/长度/mtime保持；可用由851,512KiB增至1,278,340KiB。原“10份文件槽+2GiB”约12GiB只是未实测的保守预算，不得据此称正常1GiB写作必需12GiB；24GB也不是证明出的最低需求。现余约1.219GiB仍不足原件/工作副本/非CoW底本同时存活。未启动新设备、未接受许可，未把手工清理当自动回收已修复；按阶段测真实同时存活与峰值的要求保持。

获授权后仅启动该隔离实例，明确hdc target，保留原6GB设备/用户数据。先核实际可用磁盘及一次原链峰值（原文件、工作副本、非CoW底本、保存/导出暂存/历史），不可只看虚拟磁盘标称24GB，也不删除不明目录腾空间。原始恰好1,073,741,824B经正常系统授权文件路线导入；不以私有直注、macOS service或64MiB成绩代替。

固定链不扩张：首/中/尾各一笔真实输入→跨有界窗口非空替换→首次Undo/Redo→公开Agent非冲突修改→免点击人续写→保存→正常关闭→新PID重开→固定版本流式全字节核验；原始文件保持，增长后的保存/重开/冻结导出仍符合既有容量政策。记录打开/准备/首编辑/保存/全核验分段耗时、RSS与可取消性；全文核验时间不算输入响应。不新增GiB全文删除/全篇可视解析或真机矩阵。

### 四、收尾顺序与完成口径

先把上述两个机制方案形成生产反例与针对性修复，Unicode原负载成本及三次正常退出在现有设备闭合；许可已获答复则并行准备新设备，桌面/同target构建按归属串行。机制稳定后冻结源码、正式入口串行构建normal Pharos/thermo，Pharos覆盖受影响近256KiB连续链与实际GB链，thermo只验证受影响文字呈现/恢复/关闭及其他字段零污染，不重跑无关旧来源/A2轮次。保留final6、final24与所有RED。

只更新本页/ACTIVE H及原交付索引，交付源码清单、HAP/PID、原件、成本范围与启动方式。不再新增逐轮治理台账；普通观察缺失不能自动等于生产失败，编译/抽取GREEN也不等于运行通过。许可尚未答复时只保留1GiB依赖，不能把已给方案的Unicode/退出继续写成“待指导”。E/W、用户实例、正文、剪贴板、stash/暂存保留，不stage/commit/push；不自动调用顾问。

<a id="h-large-normal27-result-20261009"></a>
## normal27执行汇合（2026-10-09，原包仍未完成）

按上述裁决实施框架冻结owned正文、完整布局来源键/独立当前交互资格、必需排版失败在Flush前拒绝及保旧；实际生产draw/Redraw/Flush/restore消费链正反例、撤回RED和原A2帧预算9/9通过。同字节恢复不重复owned排版，当前caret恢复后重新发布。生产25另揭示accepted同步/恢复消费漏唤醒、完整反馈等到下一次500ms闪烁的问题；已有真实RED后接回现有共同Redraw，撤回唤醒RED。没有复制隔离候选或放宽旧票/来源门。

共同宿主的同appInstance有界Promise已接通既有停止请求/monitor，等待在worker，UI循环继续运行，重复调用复用同一结果；未归零、旧实例、超时和环境失效均拒绝或抑制回调。Pharos三次正常关闭703→10418→16339→17537均完整file drain、owner返回与回收、native全零、随后Promise成功，每个新PID完整读回67,108,984B/hash `84b34056…`。历史1/3和断尾unknown不改记通过。实际thermo26关闭又揭示Phase B漏交owner终态，Promise正确拒绝；用实际Cangjie尾部复现RED，薄接线在既有窗口结算及清理事实后通知owner，8个边界GREEN/撤回通知或事实检查RED。最终normal27的Pharos18401/thermo19813各一次正常关闭均owner有序声明、native全零与同实例Promise成功，两个自有实例已正常退出。

原64MiB复杂Unicode正常Documents导入、单次20笔/resource2/owner1..21、保存和全量固定快照流式读回精确通过。**成本仍RED**：正文首帧35–109ms/中位83.5，完整caret/选区99–327ms/中位148.5；工具中位0.871秒另列。实际measure19次中位57,971µs，paint20次中位3,925µs；宽319/333不同，未直接复用不一致Typography。327ms样本在body/accepted79ms之后，新context挂载期间两次安装失败/落点重置，再请求31安装成功；不把恢复重签算连续首过。已形成[具体时序、原件与下一对照方案](../../artifacts/h-bounded-large-20261008/continuation/final24-guidance-resume/UNICODE_RESTORE_ESCALATION.md)，保留100ms门，不笼统写“待指导”、不开始无依据第四次猜修或宣称系统极限。

normal27冻结后继续取证，未修改生产或重投原成本输入：[真实函数接缝对照](../../artifacts/h-bounded-large-20261008/continuation/final24-guidance-resume/mount-restore-diagnostic/README.md)运行两个消费者各8个受控场景，实际共同注册表/安装生命周期及页面恢复/回声/ACK方法，原单请求就绪要求运行RED；就绪正控、旧挂载和超时拒绝、守卫计时器耗尽分别留证。Pharos无正文恢复在attach前抢装，thermo该分支等待；两者正文回声阶段仍绕过attach，即时ACK也可早于受控迟到文本重置。设备原始行把请求29具体定位为reconcile间隙active=0的`stale_context`，请求30为组件未绑定后的末尾落点失配，不能把renderer泛化结果类别直接解释为setter抛错。三份执行输入及两个共同代理镜像与冻结27摘要相等。下一裁决收敛为有效票在卸载/挂载间隙的原请求接续，以及恢复和共同安装入口的执行/确认责任；离线取证不是完整设备接续、成本通过或第四次生产猜修。

受影响近256KiB源首笔/精确替换、免点击续写、首次Undo/Redo、三片段删除后上移、键盘/滚动、Agent→人、保存、正常关闭新PID及固定导出→Documents正常回导的独立全文门通过，最终261,819B/hash `9157b464…`；冻结导出期间后续Agent64保留在原工作绑定，回导仍精确为旧固定版。原宿主采集被goal中断，设备手势继续真实UP；原件标采集缺口而非覆盖重跑。补完整录像的单独gesture7/binding81静止23.993/28.999秒、713/595个accepted位置、源锚183/mirror20598→0及UP成立，但下缘6652→6634、20880→20879使原offset单调门RED，不能合并成新的完整连续链PASS。reveal在该时刻明确因capture延后；实际Cangjie128项稀疏缓存另复现淘汰前缀修正时5031→5001且行锚不变，尚未证明设备归因。具体原件与区分计划见[驻留新反例](../../artifacts/h-bounded-large-20261008/continuation/final24-guidance-resume/RESIDENCE_COUNTEREXAMPLE.md)，未删判据或猜改虚拟列表政策。

thermo27实际消费共同reveal/跨段/一次BEGIN-UP，3.011秒静止内102个不同accepted位置、松手无迟到步、X精确替换及其他字段零污染，键盘变化后正常refocus成立。连续画面70.336秒/2064帧/0丢帧。资源新增同PID/owner/accepted30秒3样本：累计layouts776→1248/layoutBytes129908→134333，liveSlots1/liveUnits12288，RSS320092→315008KiB；累计量不判泄漏，原600秒证据保留原范围。

许可仍未获实际答复，24GB隔离实例未接受/绕过许可或启动；1GiB仅此依赖暂停。主机已流式准备恰好1,073,741,824B夹具/hash `9d9a329c…`、一次4MiB增长和约12GiB保守文件槽预算，非设备导入/峰值实测，原设备GB完整门仍未验。未以macOS或64MiB代替。

最后在thermo收尾接线稳定后重新冻结，正式入口Pharos→thermo串行normal构建/安装/实际消费：Pharos `f6272f40…`、thermo `e4d620e9…`，1,181权威输入构建后无漂移、共同461项一致，renderer动态库 `d7466208…`。Pharos27的50个HAP内部文件与已验26逐字节摘要相同，外包摘要变化，不重投成本输入。可启动HAP、完整身份/源码胶囊、操作路径、视频、正反原件和以上真实剩余集中在[normal27交付](../../artifacts/h-bounded-large-20261008/delivery-guidance27-20261009/README.md)。原normal26根目录`cjpm build --skip-script`因未改的live `range_text.cj`重复selectionOwner声明失败，原日志保留；后续并行改动删除重复，本包未编辑此文件，确认无运行中编译进程后串行[当前live根构建exit0](../../artifacts/h-bounded-large-20261008/continuation/final24-guidance-resume/cjpm-build-current-after-parallel-fix.json)，有27警告，不改记旧失败或当前live/冻结27一致。正式OHOS/NDK/针对性Cangjie/Python分别留证，不改E/W来补绿。stash/暂存摘要保持，不stage/commit/push。

<a id="h-large-first-pass-review-20261008"></a>
## 首轮实施后复核（2026-10-08，历史指导）

本节优先校正下面的开工时源码快照；原目标与固定完成门不扩大。执行者报告 HAP `39ef44cb…` 构建/安装冒烟、core 257/257 与相关 harness 通过；这些本轮未重跑，保留其证据范围。当前已读源码确认分块导入、容量参数、私有底本入口及 H mirror 预算接线存在；1MiB/64MiB/1GiB 正常设备链尚无验收。本次只读复核与文档校准，未操作设备、修改生产或启动构建。

**剩余不只是 picker 自动化。先以有限反例补齐以下真实接线，再连续完成原包：**

1. **打开、编辑与重开必须走同一大文件策略。** 产品 `apps/pharos_mark_ohos/entry/src/main/cangjie/ohos_app.cj:455` 仍调用 `pharosOhosOpenSmallDocument`；导入成功更新工作绑定后，新 PID 会回到 256KiB 门。应在正式装配源及生成/同步链接通，不能只修改临时生成副本。另核正常 `PharosDocumentService.applyEdit → DocumentFile.apply → admitJournalLocked`：大底本没有精确依据时返回 `exact_base_prepare_pending`，当前 H 只接 `pollSaveAsync`，没有 `pollEncodingValidation` 所驱动的 exact-base 等后台准备。复用共同 service 的准备、完成发布、关闭回收，不绕过日志准入。新 `owned_private_open_test.cj` 直接 `session.applySplice`，不能证明此正常服务路径；其注释称原位 rewrite，实际并无改写源文件动作，需补真实隔离反例或收窄名称/证明，不以该单测替代非 CoW 设备链。
2. **分块不等于后台执行，也不等于整条链有界。** `Index.ets::copyFileBounded/filesExact` 是页面回调里的同步 `readSync/writeSync` 循环；`async onDocumentIntent` 只在 picker 等待处让出，之后仍同步复制/逐字节比对。仓颉 `applyDocumentIntentResult` 又在 owner turn 同步执行复制＋全文件 UTF-8 校验＋打开，非 CoW 捕获还会稳定复制底本。按已有任务/票据模式把重工作移出 UI/owner，分块检查取消、失败保旧、关闭后回收；owner 只接受同请求/同发起依据的完成结果，不能因异步化失去最后采纳前的身份复核。区分并计量各次必要复制/校验，不将全量工作按每帧极小份额节流成漫长等待。可直接借鉴本地 Zed `crates/project/src/buffer_store.rs::open_buffer` 的任务去重、后台准备、owner 更新分工；不照搬其整文表示，更不引运行时依赖。
3. **导出上游仍全量物化。** controller `beginDocumentIntent` 的 export 分支仍 `readWholeCurrentVersion(maxBytes: 1GiB)` 再 `File.writeTo(frozen.bytes)`；service 的 `WholeVersionChunkSink` 最终组装全文。只把 ArkTS 改为分块并未解决此路径。改用共同不可变快照＋有界 chunk sink/取消/释放生成冻结暂存，owner 不持全文数组；现有保存 worker 的快照与流式写是复用入口，不能顺手给活动文档换绑定。私有候选和外部新目标的发布能力分别据实际平台证明。
4. **容量政策目前不闭合。** owner 允许“打开长度＋4MiB”，但 open、export 意图/读全量门及 ArkTS trustedCap 仍封顶 1GiB。于是原始恰好 1GiB 通过后插入几个字节，可被接受却不能按当前门重新打开/导出。统一有界政策，明确首次外部导入与可信已保存工作副本的容量、增长上限和重开恢复；不能每次重开重新赠送余量无限增长，也不能仅把所有常量抬高。验收必须含原始 1,073,741,824B 加实际输入后保存与新实例打开，超过政策则在写入前拒绝且保旧。

**系统 picker 复用入口已存在。** `artifacts/h-continuous-write-20261007/final6-20261008/finite-chain/import.py` 与 `import-console.txt` 已证明“工具栏导入→浏览→我的手机→Documents→选文件”的正常链。该夹具先由应用正常导出创建：`final-20261008/fixture-preparation/issued-on-normal-app/hilog.txt` 中有系统 `createOK: file://docs/storage/Users/currentUser/Documents/h-final-owned-20261008-1203.md`，随后 23917B exported/readback_exact；不是 shell 写猜测物理目录。这是授权 URI，不等于 shell 可访问路径，不需要把 root 当成先决条件。旧准备摘要有失败而后续原日志成功，分开标注。

先复用该途径完成新包近 1MiB 的正常导入/编辑/保存/正常关闭/新 PID 重开。大夹具准备也须通过可核实的系统授权文件途径或隔离的流式准备工具，不在内存/公开协议中拼出整个 GiB，不把私有文件直注计为正常导入。旧脚本的设备/端口/文件名/目录/固定等待/导出确认坐标按当前事实参数化；`read_all` 最终拼全文不能直接扩大到 GiB，应复用固定版本分块核验。原报告夹具 1,048,528B 是接近 1MiB，并非精确容量边界证明。

**实施顺序与限界。** 先用 >8MiB 的普通局部事务在非 CoW 路径证明底本、exact-base/编码准备、第一笔服务写入和保存，再推进 64MiB 与 1GiB 正常链；各档是同包调试梯度，不逐档停工。仍保留 23KiB/近256KiB普通体验与成本门，机制稳定后一次冻结串行双消费者。当前 `pharosNewSaveIdentity` 非 macOS 分支拒绝、retained-history store 捕获/见证的平台断点，**仅在 retained/durable history 路径实际进入时适用**，不能泛化为普通局部写入必败；本包不新增 GiB 全文删除或历史架构工程。遇到原门真实依赖才最小修共同 core 的平台接缝，禁止关日志/历史门、伪造身份或全局打开 copy fallback。

本轮执行者继续负责实施、自验、集中交付，不调用外部顾问。实际问题分别回产品文件任务、共同 core/service、CJGUI 范围/输入机制修复，不在 Pharos 塞绕行。保留 final6、E/W、用户资源及 Git 状态边界；当前没有 GB 响应成绩，不把启动冒烟改称大文件可用。

<a id="h-large-continuation-evidence-20261008"></a>
## 当前接续实施证据（2026-10-08，整包仍执行）

所有新原件位于 [h-bounded-large-20261008](../../artifacts/h-bounded-large-20261008/)，final6 未覆盖。Zed `LocalBufferStore::open_buffer` 的后台加载/归一化后 owner 发布规则用于本轮 immutable ticket 接线；只读借鉴，未引入依赖。

- 正式 OpenLarge 启动/重开、真实后台导入、共同 exact-base/编码完成及关闭 drain、固定快照分块 staging 导出、原始容量一次性 sidecar 已实施。容量针对性测试只证明生产政策读取/反复重开不重发增长余量，**不是实际1GiB服务链**。源窗口32768B/12288UTF16；共同session已要求有界后像不同时先恢复再续写，实际撤回翻红。
- `near1MiB/` wiring7正常包：系统Documents原件1,048,528B；单次输入/首次保存/正常关闭/新PID7612；全部1,048,536B固定快照 SHA `d885a7bd…`与冻结预期一致。不是精确1MiB容量边界。
- `9MiB-wiring8/`：正常HAP `1932f027…`，PID3047两笔输入（第二笔免点击），首次保存/正常关闭，新PID10571；全部9,437,197B固定快照 SHA `236f7cac…`一致。旧`9MiB/`错误位置/人类其他手势干扰和未发到owner的SAVE原件独立保留；诊断公开SAVE不替代正常链。
- `noncow-probe/`与`continuation/noncow-service-run2.txt`：在真实OHOS运行，链接wiring7实际core/service库（SHA另存），9MiB `captureKind=stable_copy`，O_RDWR+pwrite64原位改写外部首字节并保持长度，owner仍读原字节；第一笔**service**写入日志准入、保存/重开和底本清理通过。先前OpenMode.Write截断测试失败保留并纠正；macOS单例测试同样改用真实pwrite。未把macOS CoW说成nonCoW。
- `64MiB/`：隔离流式工具先系统发布Documents夹具，另由正常Pharos系统导入；首笔中文/首次保存/全部67,108,876B固定快照一致（SHA `956a4a35…`，完整协议核验24.206s）。连续中段滑块暴露“快速换窗代理尚未入树又退役，等待卸载”RED，未算完整64MiB链。共同native在同手势内合并到UP/cancel后交付最新上下文，实际生产准入反例GREEN/隔离撤回RED；共同proxy registry无用全历史Map会保留1000份12288单元草稿，实际模板RED→GREEN。wiring9正常HAP `572eb943…`已通过中段/尾段滑块定位后免点击输入、首次保存、正常关闭与新PID28884重开；全部67,108,890B SHA `f46dbb35…`一致。正常系统导出在冻结V1后公开Agent修改及人免点击续写，工作绑定保持；再从正常系统入口导入导出件，全字节仍精确等于冻结V1。完整协议核验23.510s/24.949s分别标记，均不是输入时间。
- 24GB自有模拟器`H bounded GB 20261008`已创建，原6GB实例与用户数据保留；启动工具要求三份软件许可，原文`continuation/emulator-start1.txt`。用户许可答复仍待，未接受或绕过。现有设备独立工作继续。

- `cost20-wiring9-64MiB/`：PID28884/resource2/owner1→21，20笔各一次真实输入与精确源字节核验。按producer context/projection/ownerBase/range/bytes匹配出队、owner日志、accepted ticket和版本化文字反馈，首反馈72–93ms（中位75ms）；工具调用中位0.867s另列，不宣称物理屏幕呈现时间。三次wiring9正常关闭/新PID以及600.003s混合间隔资源原件已保存；layouts/layoutBytes按累计工作量，liveSlots/liveUnits与RSS分PID，尚不由其推出无泄漏。
- `ordinary-wiring9/`：正常导入final6系统导出件23,757B并全文核验；单手势静止驻留61个不同accepted偏移、7组同源扩展、真实UP停步、精确替换和免点击续写、Undo/Redo各首次成功、无编辑源码/预览往返、公开Agent后人免点击续写、正常保存关闭与新PID21098读回18,229B SHA `30215684…`一致。连续窗口画面75.199s/2209帧，capture只取准确Emulator窗口；这条尚未补微移/反转/删除补位。
- `safety-wiring9/import-edit-save-late-run2/`：真实正常picker等待时公开Agent改文并通过真实service SAVE使dirty=false；迟到导入仍因冻结origin改变拒绝，旧文档/路径及全文保留。run1仅字段名读取失败、无任何操作，原件保留。新taskpool实际worker函数在自有临时文件执行取消前写入/块间取消/比较前取消、已有非空目标保护、写入失败、预算及全量精确比较；此为主机真实I/O故障反例，不代称设备任务调度证明。

- `unicode64MiB-preparation/`与`unicode64MiB-wiring9/`：独立系统发布后正常导入64MiB无换行、ZWJ/组合符/RTL夹具；全部67,108,864B SHA `df2c0b1d…`与独立262144B块生成预期一致。首笔输入成功，但同PID/owner/accepted反馈201ms，保留为成本RED。共同UTF坐标函数实际测试暴露27,648次小数组物化，改成每函数单次数组后2/2 GREEN，隔离撤回RED；wiring10实测首反馈189ms，**仍超过100ms定位门**，不将此微调称性能闭合。进一步核对正式CJGUI装配只带`--dy-std`，本地cjc声明默认-O0；已在框架同步入口显式-O2，wiring11正常HAP `4927fafd…` 首笔同身份反馈122ms，仍未闭合。该包PID24181/resource1的20笔owner2→22均各一次接受且源切片精确；同身份版本化反馈114–197ms、中位174ms，工具中位0.878s另列。原始日志明确有native较长后像的绘制、同步natural-height测量及恢复后accepted反馈，但未以它们的任意时间差声称具体调用耗时。

- `cost20-wiring11-unicode64MiB/` 保存后正常关闭，新PID24391因底本复制写入失败拒绝打开；`continuation/reopen-failure-space/` 确认现有6GB设备仅588KiB可用，自有夹具工具的未完成1GiB临时文件大小1,055,072,256B。该文件仅为工具私有准备、没有正常导入证明；保留stat/空间证据后精确清理，未删Documents或用户原件。另立诊断恢复路径后新PID19131固定快照全67,109,008B SHA `2aa0f00c…`与冻结20笔预期一致，23.440s。这次恢复不能替代原失败的连续重开门。
- 全局选择实际生产反例暴露同正文版本的新选择不使旧prepared凭据失效、reveal后旧UTF16坐标可继续写入。共同core/service新增可选源选区写入前提，在实际owner锁及journal准入前核视图代次/revision/方向端点，并把依据纳入重复请求身份；真实文件service两例GREEN，隔离撤回两例RED。共同框架的可选SourceSelectionEditSink由产品bridge接入真实service/file；H session保留owner全局方向端点，仅裁剪native投影，精确恢复回执不覆盖外窗锚，当前恢复投影才可消费全局替换。实际H源码4例GREEN，选区revision/换窗恢复分别隔离撤回RED；既有受影响窗口接续18例GREEN。wiring12正常HAP `91f518b1…` 已安装启动PID1272，64MiB真实首笔3B输入及一次正常保存通过；尚不以此称跨窗门完成。9MiB正常导入后全选镜像、只投递一次Shift+Right，窗口未继续扩展，设备RED原件`source-global-wiring12/key-red2/`保留。共同proxy/native/窗口已接物理水平键意图，冻结mount/context/generation/绑定及本地选区，窗口核来源后复用全局选择和共同恢复；当前真实proxy/native/窗口针对性检查GREEN，native代次和窗口选区前提分别隔离撤回RED。正式wiring13首轮仅因两处E/H私有字段差异编译失败；去除无关引用后wiring13b正常HAP `0e14a34a…`/PID28488已构建启动。一次Shift+Right真实跨窗并精确恢复，但随后一次替换只删除当前可视跨度：恢复同值kind33回声又经setSelection16覆盖了外窗源锚，`source-global-wiring13b/exact-global-replace/`原RED保留。脚本误用旧bundle仅查询PID，原空PID未改；另存当前正确PID28488的过滤原日志和身份纠正，不重投原手势。已在共同H窗口核精确同值全局投影回声，保持源revision/方向/外窗锚及恢复等待；实际窗口4例GREEN，隔离撤回前后两种回声均RED，受影响原18例GREEN。错误自有工作副本仅另立诊断Undo/保存复原，不算原门通过。wiring14正常HAP `262a2564…`/新PID14524已实际装配。一次物理Shift+Right跨窗后，一次“跨窗”输入准确替换源0..12289（9,424,901B），随后免点击“续”形成9,424,904B；随后Undo/Redo各一次首过、一次正常保存关闭，新PID14752固定快照全部9,424,904B SHA `d4f3161e…`与预期一致（`source-global-wiring14/`）。阶段计时冻结session/context/projection/owner/文字指纹，在真正layout调用前后取同一单调时钟，尚不由日志间隔推断函数耗时。

`cost20-wiring14-unicode64MiB/`：PID14752正常系统重新导入原始Unicode夹具，首笔及20笔各一次精确输入，保存67,108,987B全文SHA `1778b1f8…`一致。首反馈127–251ms仍失败。actual layout边界的同身份计时：20次measure中位52,472us、38次paint中位60,631.5us，measure排队中位100,319.5us；普通未采纳后像先经旧票重绘，阻塞随后owner测量。native共同redraw现在只在完整当前票/投影/绑定/owner/镜像匹配、无组合的owned plain后像等待时保留accepted画面，待owner正常新帧；实际入口反例GREEN、隔离撤回RED，范围差分3例及持有排版反例通过。计时measure字段ownerBase此轮实际冻结的是contextBase/projection，不能当内容版本；关联以producer内容版本、ctx/projection和paint owner核定，报告明确标注。首轮wiring15误由框架包装直接启动，闭包按默认样例lib检查失败，未安装；原件保留，改由已有正式产品入口wiring15b串行构建，正常HAP `2c070f57…`/PID29849已实际安装使用。20笔Unicode首反馈73–197ms、中位137ms仍失败；measure排队中位降至40us，而正常Present仍绘制native未裁剪后像（paint最高59,105us）。原件`cost20-wiring15b-unicode64MiB/`及离线完整字节核对保留，未重投20笔。当前真实draw入口反例RED，隔离冻结帧候选GREEN/撤回RED、完整NDK编译成功，但未写生产：按累计三轮实际修复仍失败规则，具体材料`continuation/unicode-cost-escalation.md`已交指导，其他独立工作继续。

隔离主机真实service测试 `continuation/service-one-gib-host-run3.txt` 通过：执行正式OHOS打开/容量策略源码，原始1,073,741,824B，真实日志准入下人/Agent各3B，保存1,073,741,830B，新service按同一持久容量1,077,936,128B重开；固定V2流式暂存全文核验1,073,741,827B且不含后续Agent输入，超容量写入前拒绝，关闭/后台drain/私有文件回收。此证据为macOS共同service范围，不替代OHOS非CoW或系统picker正常1GiB验收。首两轮仅测试调用/未启动poll的问题已保留并修正；未修改生产来迁就harness。

- wiring15b空文件正常导入、0B冻结导出及导出件正常再导入通过；一次“空文”6B、正常保存关闭、新PID9538全部6B精确。原first-input脚本仅把0B协议占位符`-`误作hex，失败发生在文字投递之前；另立一次实际输入原件，未重复投递。
- `continuation/near256KiB-continuous-wiring15b/preview-entry/`保留真实失败：262,128B普通短段落解析成功，4,298片段触发共同1024场景节点预算，`refresh_scene_node_count_invalid`，owner已声明preview而accepted仍为source。后续有界集合已关闭节点预算与首次聚焦缺口，驻留和完整连续门仍未通过，不以源码面绿色或更换夹具称近256KiB可视链通过。先前桌面激活期间额外native逗号及另立诊断Undo/保存/重开原件也保留，不覆盖原失败。独立`near256-source-cost-wiring15b/`在一次正常源码选择/替换后为249,841B，20笔各一次精确输入；同PID14330/owner2→22首反馈32–58ms（中位43.5ms），工具中位0.909s单列。正常保存关闭、新PID11028固定快照全部249,961B SHA `462ea957…`一致，范围仅源码成本/字节链。
- `continuation/ordinary-wiring15b/micro-dwell-reverse-once/`：正常系统导入23,917B，ONE物理鼠标轨迹经模拟器真实触摸ep4（1 BEGIN/27 UPDATE/1 UP）；底边静止83个、顶边静止94个不同accepted偏移，总221次滚后重算，gesture/binding唯一，固定源锚110、源范围反转至17..110，UP后无迟到步进，当前精确恢复完成。连续画面23.056s/678帧/0 writer drop，不外推逐帧无闪烁。一次X精确替换源字节19..226，再免点击续写；Undo/Redo各首次且全部字节一致；公开Agent后人免点击续写、正常保存关闭、新PID16393全部23,734B SHA `f9e5ac7e…`一致。原picker定位期限失败保留：原请求随后正常滚动一次并选原命名文件，没有重发导入；这次诊断接续不称最终连续门。
- `cost20-wiring15b-ordinary23KiB-source/`：新PID16393/owner1→21，各一次实际输入/精确源字节，同身份首反馈19–36ms、中位30ms，工具中位0.872s单列。原collector假定mirror-sync在commit+10ms内、owner日志必须早于native反馈，input17分别违反这两个假定；原失败材料保留，owner观测日志在pump后，不当service函数耗时。当前关联以唯一PID/node/owner和下一笔producer围栏核sync及owner日志，未放宽输入/版本/accepted反馈身份、未重投。保存关闭、新PID30577全部23,854B SHA `3f5dee7a…`一致。
- `continuation/cancel-service-ohos/`链接wiring15b实际共同core/service，在真实OHOS独立ELF用自有64MiB、非CoW稳定底本验证：活跃exact-base/encoding准备期间close，拒迟到发布/无journal/worker drain/底本回收；实际异步保存立即取消，结果save_cancelled、原64MiB全部A不变、owner v2 dirty/saved v1和绑定保留。原missing-parent SaveAs只证明target准入拒绝，不称写入失败。另一真实worker用**只作用自有进程**并finally还原的RLIMIT_FSIZE=262144触发第二块内核write error；旧64MiB逐块全部字节、绑定和版本保留，关闭后底本回收。无全局填盘、用户文件/系统设置修改，独立ELF不代称系统picker/GUI消费。
- 私有文件定向盘点：已退休wiring15b Unicode工作目录仍保留工作副本，`.pharos-bases`仅8KiB目录/元数据；旧跨轮目录和正常工作副本不当“泄漏”也未清不明资源。三次正常recent-task关闭均PID退休，当前仅ordinary PID11028原件完整记下owner rc0/文件任务pending=false/render_shutdown_status0和native sessions/unacked/pending/refs/surfaces全0；另两次终结尾日志缺失仍unknown，不补造三次归零。当前6GB设备剩888,976KiB不足准备原始1GiB，24GB许可仍待答复。

- `continuation/ordinary-wiring15b/export-normal-frozen/`：新PID30577冻结owner v1/23,854B，通过正常系统导出；等待期间一次公开Agent64写入、回到正文后免点击“末续”，当前工作副本23,867B、绑定保持。保存后从Documents正常导入导出件，全部23,854B SHA `3f5dee7a…`精确等于冻结v1，不含后续两笔。
- `continuation/device-file-worker/verified.json`：独立工具HAP执行**未改动的生产**ArkTS文件worker（SHA `0876ea68…`），实际OHOS taskpool UI TID27289/worker TID27405。取消先于执行权移交：claim_refused/零写入；复制期间取消：源64MiB，在524,288B停止（取消发布时观察262,144B，允许当前块结束）；比较期间取消：已复制64MiB后拒绝成功回执；已有16B非空目标保旧。UI定时器在worker期间分别6/225次运行，终结后60ms文件大小不再增长，源64MiB逐块全部字节验证、排他请求目录回收。此为真实设备任务调度与文件I/O，**不代称系统picker消费或已写外部字节回滚**。
- `continuation/normal-picker-cancel-wiring15b/`：正常应用PID30577仅一次导入、一次系统Back，完整请求i1791461475801-0-r3回cancelled/kept_current=true，旧owner/版本/绑定字段相同且无file-worker派发。原collector错用CJGUI标签的期限失败保留；随后只读PID原日志及当前字段确认，没有重发意图。无关日志截断UTF8按replace解码只用于事件识别，原件字节保留。
- 密集预览接续：原262,128B/4,298片段场景预算RED保留。共同variable-height集合接同一viewport请求代次与稳定内容carrier；产品把不可变SourceMap片段接入既有Pharos逐片段场景，不增加另一套编辑/滚动机制。实际共同state/viewport/请求采纳3例由RED→GREEN，隔离撤回仍3例RED。wiring16/16b编译失败原件保留，16c正常入口实际场景29节点，但首次聚焦失败。共同candidate clone丢失稳定carrier模板已修，实际类3例GREEN/隔离撤回2例RED；共同native face facts纳入interactive TEXT、普通标签仍排除，实际publisher反例GREEN/撤回RED。正式source manifest沿真实cjpm依赖图含全部可达产品源码，遗漏产品反例RED→GREEN。wiring17正常HAP `1b9b23e0…`/PID24034，1046项源码清单；262,128B/4,298片段预览仍29节点、一次首次点击carrier190真实restore采纳通过。`near256KiB-wiring17/micro-dwell-reverse-once/`同物理轨迹原件失败：5步/4次重算均依赖MOVE，随后accepted偏移回0，静止无续滚；工具UP而native无UP、无capture_invalidated，不当驻留通过。连续画面实际23.3265s/585帧/0 writer drop。共同行间隙锚点反例52→0已修为保留stride，4例GREEN/隔离撤回1例RED。产品SourceMap原把全局字节当镜像局部、跨度大于镜像先拒绝；实际controller+桥/session/core/service/file两例RED，改接同版本全局有向选择与活动端有界reveal；真实后台编码准备后深处点击和跨窗反转精确替换2例GREEN，service实际journal写入，纯session恢复确认不冒充设备native回执。wiring18正常HAP `a0be3755…`/PID19204已实际装配1046项源码，首次普通预览点击及精确native恢复通过；原模式collector类型错误保留，未重发模式意图。桌面CG轨迹工具自报UP但native零BEGIN/UP，另存为工具交付失败。正常SDK uinput一次down/up实际1 BEGIN/1 UP；另一单次move＋3s keep实际1 BEGIN/243 UPDATE/1 UP，10次accepted重算到offset228且不再回0，但起始row1003退出有界集合，`capture_invalidated revision=75:75 binding=3:0 node=1003:-1`提前停步，驻留仍RED。正常keep期间系统重复同坐标UPDATE，未称零MOVE；原视频/日志保留。共同虚拟列表按Flutter keepAlive生命周期借鉴，采纳BEGIN持一份排他行票，每次候选从当前key/title/layoutRevision/source generation重建最多一行、按真实逻辑offset布局，UP/cancel释放；不缓存旧几何或放松来源/捕获门，不超过128行。完整生产UI/layout、采纳树保留/释放钩子4例GREEN（包括预算满额拒多建、来源变化与旧终态），隔离撤回保留分支后起始行丢失RED；原native绑定/真实UP仍须设备消费。wiring18正常recent关闭PID退休及file pending=false/waited_ms=0已见，完整owner/native归零尾仍unknown。wiring19正式HAP `56611373…`/PID25215已实际使用：同一次SDK move/keep真实1 BEGIN/1 UP，2.984s固定触点期间83个不同accepted偏移、固定源锚183与33个不同活动端，UP后零迟到步进及精确恢复。该keep重复同坐标UPDATE，明确区别于无MOVE。源183..4268首次X精确替换、免点击“续”、Undo/Redo各首次全文、公开Agent及免点击“人继续”、正常保存关闭、新PID25447全部258,067B SHA `e888fbda…`一致。但内容删除后caret约195而accepted仍只含row62起，当前活动行缺失，无小矩形可交付reveal，**完整可视链仍RED**。已由同版本SourceMap将活动行接现有共同revealKey/requested viewport：只有新内容owner或显式源焦点变化、目标未物化时准备当前行，手动滚动/同owner捕获不被复位；candidate/accepted焦点随既有commit/rollback晋升且带绑定版本，拒旧来源。实际controller/SourceMap/真实service journal及完整CJGUI布局3例GREEN，隔离撤回2例RED，未新造编辑/滚动算法。wiring20正式HAP `066b2b55…`/PID17530已串行构建并从系统Documents首次正常导入原262,128B、固定快照全文一致。首次预览观察器只核live/pending，漏核恢复node/ctx和源落点；原结果保留，**首次焦点正确性通过撤回**。非空carrier190/ctx4无携带选择，native_changed=0的默认末尾12288回声在attach前被采纳，虚拟行跳至row201；单手势Driver在node1003预检StopIteration，尚未发送意图。实际H窗口bind/adopt及真实service/file反例默认末尾ADOPTED的RED已保留；非空首绑接现有精确安装链，三例GREEN，隔离撤回仍1FAIL/2PASS。只改H绑定，未改generic bind/main E/来源和输入门。wiring21正式HAP `e2fff8dc…`/PID21530，正常启动/1046项清单通过；系统Documents首次导入原262,128B全SHA `89db9ceb…`一致，首次普通点击真实carrier190/current ctx5/owner1安装与源落点0通过，无Back/重播种。同一Driver真实1BEGIN/1UP、静止正向/反向accepted滚动、源锚183和终态恢复已见，native零capture失效；最大源跨度未超过12,288，原跨窗门FAIL保留，未降门。42.542s/1252帧/0 writer drop。源2..183首次X、免点击续、Undo/Redo各首次和全文一致；活动row0可见。随后三片段拖选0..161首次Delete至261,790B全文一致。原tool安装包仅复制到本轮目录，旧原件不改。暂存/index和stash两仓精确SHA未变；已完成独立ELF使用的准确私有runtime目录回收，原件保留。


- wiring21键盘交错**完整链RED**：删除后canonical caret0在native ctx10；一次Back与边缘外pan后native重新激活ctx11，只保留非空选择的旧分支把collapsed0重置至镜像末尾。`native_changed=0`默认12288回声被采纳；一次“滚后”实际写在12288，原helper跟随错误当前位置的局部PASS不当原导航意图通过。后续正常焦点脚本row0预检缺失，未发送点击或Agent；原上下文/全部261,796B/视频保留。实际完整`beginEditingOnNodeLocked`及真实scalar取整边界的有限反例RED已保留；同完整绑定/accepted owned镜像字节与owner版本严格相等、无组合且合法collapsed坐标时保留，新owner/文本/绑定/来源未放宽。15种状态分支实际GREEN，隔离撤回同例RED；H native生产已修，下一正式wiring22消费待验。此为refocus新producer边界修复，不是第四次Unicode成本修复，未用未同意的冻结frame候选。

- wiring22正式正常HAP `8d4f077d…`/PID9338、renderer `f044f14e…`，1046项装配/启动与系统原262,128B导入全文、首次current carrier190/ctx5/owner1源0恢复通过。该包仅增加严格owned collapsed refocus修复，键盘消费仍待。Driver一次down/UP将静止正向延长24s、反向29s，原跨窗门仍FAIL；70.157s/2064帧/0 drop原件保留，未重跑覆盖wiring21。真实accepted从offset6545修正6566，旧await要求下一请求像素完全相等，静止期间无后续步直到反向MOVE；没有capture失效。实际完整共同viewport及H step反例2FAIL/2PASS，接accepted request generation后5PASS；current main同5PASS，隔离撤回await仍原2FAIL/3PASS。同一票反复接受修正的20步及终态反例追加，正式wiring23正串行构建。旧候选、后到pending请求、新手势和换绑均保留门；不是简单删偏移检查或消费无版本缓存。CodeLattice此root分析IO失败、GitNexus UNKNOWN均记录，不当影响零证明。两仓index/stash按原格式SHA保持。

- wiring23正常HAP `b213d639…`/PID10553、1046项，系统原262,128B导入全文/首次ctx5源0通过。**原未修改跨窗门PASS**：同一Driver原始24s无MOVE707次accepted、反向29.005s558次、同gesture4/binding4，mirrorStart最大20,598再回0，fixed183/真实UP/0迟到，随后源2..183首次X及免点击续、Undo/Redo各首次全文均一致；三片段Delete0..161至261,790B全文SHA `3f06b2fd…`。但keyboard一次Back/pan仍使canonical0变12288，**完整连续链仍RED**；新增冻结前提在投递下一笔之前拒绝，未写“滚后”、未调用Agent/SAVE，失败原文/全部字节/视频保留。原helper计划文件名含agent，实际没有Agent操作，不扩大证明。native新refocus分支本身保留了12288，已定位更早proxy blur的submitAndFinish整值同值commit无条件先把native0改文尾；不再将这次上游重置算refocus归因已闭合。
- native实际整值commit/finish＋真实delta/scalar路径同值blur反例RED；接既有plain onChange“同值、无draft、无marked不产生新意图”规则，保持selection及在途restore，真实变化与组合仍原提交。12种状态GREEN，隔离撤回同例RED；受影响原plain echo5例GREEN。wiring24正式正常HAP `811c7269…`/PID22685已构建安装、1046项清单/启动通过（仅H native新改），新键盘消费及完整链待验。此为有证据的新producer接线，不是第四次Unicode成本猜修。
- wiring24导入事务确已切换/262,128B全文正确，旧观察器额外要求edit=live而当前前台为另一测试应用Pharos PDF，原timeout保留；将导入发布与下一次普通焦点分开核。wiring24b在另一应用前台点击，未产生我方第二import意图，按工具前台失败保留。用户明确允许继续并行测试；现每次我方输入前核前台，必要时只恢复我方同PID实例、不关闭另一应用、不重投意图。新独立原件wiring24c正常Documents导入/首次current ctx6源0通过，现完整可视文件链PASS：原跨窗门未改，同BEGIN/UP正向23.987s707次、反向28.993s500次accepted、mirrorStart20,598→0/fixed183/零迟到；首次X/免点击续/首次UndoRedo/三片段Delete0..161/后文可见、一次Back/pan后冻结0及精确“滚后”、公开Agent和免点击人继续、保存/正常关闭、新PID10680全部261,816B SHA `24004fb0…`、正常冻结导出/正常Documents回导全文一致。退出PID退休/file pending=false/presentation remaining=0已见，完整owner/native settled尾仍unknown。

- `preview-cost20-w24/`：同PID10680/resource2/owner1→21，20笔各一次源字节精确，固定快照全261,936B SHA `696a1d49…`一致。旧INPUT关联器要求owned-input sync及painted carrier，实际隐藏carrier190/native node0，原collector失败保留；专用只读关联严格核PUBLIC当前SourceMap owner/mirror/restoreOwner/projection、accepted ticket及同producer/native binding/context，接真实mirror sync与同票可见片段Flush。first accepted presentation Flush18–37ms、中位26ms，工具中位0.868s单列；native反馈owner=-1明确不当直接owned INPUT/物理屏幕时延。隔离篡改owner2→1的原门拒绝，无重投。thermo正式入口正在串行构建，当前741项实际生产/配置输入与w24manifest无漂移。原freeze脚本语法失败后shell曾继续构建，因此这次只记录源身份核对，不伪称最终构建前freeze。

- `source-cost20-w24/`：同PID10680/resource2/owner21→41，各一次精确输入，直接owned INPUT版本反馈35–65ms、中位44ms，工具中位0.899s；全部262,056B SHA `b9e0c4e1…`一致。后续中尾正常输入及资源导航另记；旧head短拖小于阈值、第二次起点被键盘遮挡误投一个newline至我方临时副本，原失败/262,069B精确差异保留，非用户原件。工具接实际surface/accepted clip/keyboard有效带后单次头导航通过，只计诊断，不替代连续门。
- thermo wiring24正式normal HAP `0aa408ac…`/PID2317，共同388项与Pharos逐项SHA一致。原同一Driver真实BEGIN/UP和2,984ms无MOVE内101次accepted滚动、同gesture4/binding1、accepted scene301/320/337/356/374的范围39/29/17/7/1→61、源锚61/零迟到已证。原观察器按任意elapsed>=1.1混入移动前折叠59，原FAIL保留；精确关联无MOVE内accepted scene首次范围的只读修正通过，无重投手势。原UP1..61随后仅一次X精确为AX，其他字段全同，Back一次/正常再聚焦及共同reveal47条通过；连续驻留和后续键盘画面分别保留，未伪称原失败观察器或最终新包门绿。
- `resources-ten-minute-w24b/`：同PID10680/同endpoint/resource2，600.0005s/41份，关联owner21/25/33/40/41/42/43/44及accepted身份，覆盖源码20笔/中尾/导航。累计layouts27,055→41,247/layoutBytes1,122,530→4,019,787；当前live从preview10slots/649units转source1slot/8195units，没有表项持续累积。RSS372,040–570,096KiB、末520,836KiB，不能从末回落或累计计数判无泄漏。原-w24 observer及早期-wiring9 feedback中的hilog -x/-z组合CODE-31均不当layout证据。
- 正常close三次PID10680/11807/24472各退休、新PID各全文262,069B SHA `3e7f4950…`一致；完整native零尾仅10680一份，11807已见file drain/owner rc0但无stop settled，24472仅presentation remaining0而file/owner/native尾缺失，**1/3不是三次归零通过**。共同AppShutdown只在UI onDestroy置位/请求，由owner/render/独立monitor异步收敛；当前证据不能区分OS结束与未完成清理，不改UI回调为盲等。具体退出证据缺口交指导，继续独立汇合，不重投失败原close。
- 已完成最终集成候选构建前冻结1,182项源码/配置，正式产品入口Pharos→thermo串行normal构建，后核零漂移；Pharos HAP `052ad4fe…`/PID32711（1046项）、thermo `278f265f…`/PID1754（943项）已安装启动。此两HAP已实际消费：Pharos最终原件PID32711→6984完整预览/键盘/Agent/文件链全文261,816B SHA `24004fb0…`；另补原固定链源码首笔，PID6984正常导入→源码尾端一次“源”→预览，底边23.983s无MOVE内708个accepted偏移、反向28.984s内519个，mirrorStart20,633→0/fixed183/真实UP零迟到，替换续写/首次UndoRedo/Delete/键盘/Agent人继续/保存关闭及新PID9782全文261,819B SHA `9157b464…`、正常冻结导出回导全一致。thermo PID1754同BEGIN/UP、3,009ms无MOVE内103个accepted偏移及accepted scene范围39/29/19/9/1→61、源锚61/零迟到，一次X=AX/其他字段全同，Back再普通聚焦/共同reveal及键盘连续画面通过。源码先冻结、两包构建后及实际验收/源码首笔补齐后均1,182项零漂移；两消费者共同框架459项源码/配置SHA一致。wiring24成本原件的全部1,044个唯一构建输入与最终Pharos一致，仍标原PID10680，不迁移时延身份。正常HAP、操作路径、原件/视频与真实剩余集中见[当前冻结包交付](../../artifacts/h-bounded-large-20261008/delivery-final24-20261009/README.md)。Unicode候选已在final24当前源码隔离副本接回、真实决策GREEN/撤回RED/完整NDK编译成功，未写生产；首轮漏include工具失败保留。Unicode具体升级、24GB许可/真实1GiB与三次完整native尾仍未完成。

当前冻结同源串行双消费者、近256KiB源码首笔到可视跨窗/微移驻留反转/删除/键盘/Agent与完整文件链已通过，前述文件取消/实际失败/非CoW与20笔证据保持各自范围。真实剩余为Unicode三轮成本RED的具体指导裁决、24GB软件许可及原始1GiB正常增长/保存/新PID/冻结导出全文、三次完整native退出归零。已有两项问题待答复，不自动接受许可或做第四次生产猜修；只暂停相关依赖，独立汇合已完成。当前没有鸿蒙GB性能成绩，整包仍未完成；不stage/commit/push，E/W、stash/暂存和用户资源保持。

## 基线与目标

保留 [final6 正常包及原件](../../artifacts/h-continuous-write-20261007/final6-20261008/delivery/README.md)：Pharos `a5490663…`、thermo `e19e8cc3…`，原 A–E 在当前模拟器范围接受。实际完整可视文件约 23KiB；256KiB 是导入/提交容量边界，不能外推为 256KiB 可视性能或 GB 能力。内部 producer→paint p95=72ms、峰值 RSS≈567.5MiB，不是物理 present/长期内存/16ms 已通过。

本阶段推进两项框架能力：有界文本范围在鸿蒙宿主的连续消费，以及可解释、可回收的呈现工作量。产品继续复用现有 document_core、app_services、Markdown SourceMap；通用输入、范围镜像、viewport、排版、发布、唤醒和生命周期问题回 CJGUI 修复。目标是同一正常包保持普通写作体验，并完成 1GiB 源码面的最小真实写作链，交付可直接启动的 Pharos。

1GiB 明确指 1,073,741,824 字节原夹具；编辑后按实际长度核算。本包不宣称 1GiB 全篇 Markdown 可视编辑、真机/发布、系统输入法完整 marked/cancel 或普遍 16ms 达标；不重开旧来源/A2设计或无关历史矩阵。新问题按责任与影响处理，不能以旧包已完成为由丢弃。

## 开始前只读核对

读 AGENTS、ACTIVE 的 H 当前段、本文件、final6 README 和直接相关源码。编写仓颉前读 cangjie-coding 技能。主执行负责归因、实现、自验，不自动咨询 Pi、GLM 或其他顾问；历史裁决前提仍成立时直接复用。

先比较 H 编译副本和产品正典公共包，明确可复用的 E 资产，不整份覆盖 E/W 在途文件。当前已确认的小文件假设：

- `apps/pharos_mark_ohos/application/src/pharos_ohos_document.cj`：`PHAROS_OHOS_SMALL_DOCUMENT_MAX_BYTES=262144`；打开和 owner 提交均有限额；导入 `File.readFrom` 全量物化。
- `application/src/pharos_ohos_document_intent.cj` 与 `entry/src/main/ets/pages/Index.ets`：协议固定 262144，ArkTS 使用整份数组和同步读写完成导入/导出。
- `application/src/pharos_ohos_controller.cj`：`bodyProjection`、镜像安装、`ensureVisualCandidate` 与 `noteProjection` 依赖小文件范围；预览扫描正文投影，不能把局部窗口当完整 Markdown 文档。
- 产品正典 `packages/document_core/src/{store,tree,session,encoding_task,persistence,retained_history_generation}.cj`、`packages/app_services/src/workspace.cj`，以及 macOS `apps/pharos_mark/src/main.cj` 中的有界 mirror、文件打开/恢复、范围定位、解析取消和流式核验是复用来源。核对真实依赖、优化开关和已证明边界；源码在 H 副本中存在不等于 H 已消费，更不等于 E 最终体验已完成。
- 一个必须先接通的平台断点：当前 `DocumentFile.open` 大文件进入 `openFileBacked`，其底本捕获默认不允许 copy fallback；`immutable_base.cj` 的非 macOS `pharosAttemptClone` 返回不可用，因此 H 会遇到 `snapshot_unavailable`。在本阶段只读核对时，core/services/editor_surface 非测试仓颉源码与 H entry 副本相同，不能把问题归为“只缺同步”。须为已经由本实例排他创建、尚未公开给写入者的私有导入候选，落实可证明的不可变底本所有权或显式流式稳定复制方案；不能把普通复制伪称原子 CoW，不可静默打开全局 fallback 或复用不可信的路径/mtime 身份。核对非 macOS 文件身份、保存/历史 FFI 能力及失败语义，必要平台适配归共同核心的窄桥接。
- 框架 `runtime/cjgui/platforms/ohos/snapshot/src/range_text.cj` 与主树 `runtime/cjgui/src/range_text.cj` 的 mirror 预算准入时序存在差异：H 路径先发布 `slice.content` 再判预算，主树先核跨度/预算。按当前函数现文核定并定向同步必要防线；不能整份覆盖包含 E/H 不同交接实现的 text_session/window。非 macOS `pharosSameFile` 当前返回 `None`，涉及既有目标替换时保留具名拒绝，不能直接假定身份相等；本包外部导出继续采用新目标。

通用机制方案不明时按 [本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考) 定位 Zed/GPUI 的快照、可见范围、缓存/失效、滚动锚，或 Flutter/SDL 的相关平台生命周期及测试。只读借鉴，不引入第三方 GUI 依赖。在本页实施记录简述实际符号、借鉴规则、CJGUI 差异与落点，然后继续实施；不另开参考台账。

## A. 正常写作体验及资源归因

先复用 final6 约 23KiB 夹具，并以接近 256KiB 的普通多段文本建立同机基线。把选择微移/跨段/驻留/反转/UP停止、删除后后文补位与 caret、键盘开合、滚后立即输入放在连续操作中，不能只核最后正文。

围绕现有 72ms/567.5MiB 原数，关联同操作的 producer、出队、owner、prepare/layout、accepted/paint 和可取得的显示证据。区分初始运行时/字体开销、正文与数组复制、排版/纹理、历史、日志及采集工具影响，不先断言泄漏或系统慢。性能诊断有界、默认关闭；正常包另测，不扣诊断开销凑通过。

修复重复全文投影/排版、无效重装、缓存失效过宽、无活动仍持续工作等被实证的责任点。缓存必须有身份、容量与退役责任，失败保留已接受画面，旧资源不能清掉新 caret。相同输入或颜色变化是否可复用布局，以几何契约和反例判定。

新包在同负载下不应劣化 final6。内部自然长尾超过 100ms 必须定位负责阶段并给出处理结果；100ms 不是替代 16ms 的新帧标准。按同一实例记录至少 20 笔输入/选择、冷/热滚动、停止后活动计数；短连续高频画面覆盖微移，不将低频采样宣称为逐帧无闪烁。三次打开/关闭和至少十分钟混合操作观察内存、活跃资源及退出归零；不由累计分配数或一次 RSS 回落推断泄漏结论。

## B. 大文件打开与保存复用共同核心

先打通 1MiB，再用 64MiB 定位全量工作，随后完成真实 1GiB；这些是内部调试梯度，不在每档停工交付。原 256KiB 路径及拒绝原件保留为基线；新能力接通前不能直接提高常量绕过容量保护。新增容量由实际打开策略配置，导入与人/Agent 提交遵循同一 owner 限制。

系统 picker 仍是正常导入入口，外部原件只读，采用唯一私有工作副本。保留 final6 的实例/请求身份、冻结发起文档与版本、取消/执行权仲裁、精确回执和迟到拒绝。平台提供文件访问，仓颉核心负责文档/历史；不新建 OHOS 专属正文库。不能把 1GiB 搬进 ArkTS number[]、JSON、一个字符串、FFI 整值或 UI 节点。

按 SDK 实际能力做异步有界流式读写、校验、取消和空间检查；需要文件权限持有时按句柄/URI 生命周期处理。可随机访问的稳定来源和必须先流式复制的来源分别报告成本；不能在来源尚不可靠时承诺编辑，也不能伪造随机访问或绕过 picker 把预置私有文件当正常导入。

复用共同后台编码扫描、局部合法性证明、精确文件身份、私有恢复 staging 与 durable 历史。首屏/局部能力不应无故等完整扫描或整篇历史；实际依赖尚未满足时明确能力状态，并保持 UI 可响应取消。不得以关闭校验、破坏坏字节或跳过恢复责任换速度。保存/导出按冻结正文流式写与核验，候选失败/取消保旧；只承诺已证明的原子性。

分别计时：picker/复制、首次可见、首次可编辑、全文校验、历史就绪、保存和重开，包含完整端到端时钟。不预设 GB 必然秒开，也不接受分钟级无反馈仅以“大文件”解释。若慢，先核优化开关、串行依赖、吞吐、每帧节流及重复读/hash，再修责任层。

## C. 有界源码呈现与全局选择

复用 CJGUI range 会话、版本化 sourceBase、全局源选区、同源 accepted 几何和既有恢复/输入交接。全文 owner 与当前窗口明确区分；首/中/尾定位和滚动换窗只物化预算内文字。源字节与 UTF-16 换算、方向/亲和性、旧票拒绝、输入保存责任保持，不重盖版本、不靠放慢键入或多发动作救绿。

正文与排版缓存须有显式预算，不把整份 1GiB 字符串送进 native 输入代理或测量函数。超长单段也须有界；不得以错误切分字素、塑形上下文或 bidi 换取快。全局选择不能因片段退出而丢失，高亮仅由当前可见片段投影；删除后正常重新布局并补取后文，不能留旧像素占位。

本包 1GiB 主验源码面。保留小文件可视能力；对大文件预览仅消费已具可靠解析上下文的有界投影，否则明确提示当前预览能力并保持源码可编辑，禁止局部开头冒充全文。全篇 Markdown 虚拟化另列后续，不由它阻塞本包源码目标。

## 固定完成门

1. **生产反例：**对实际修改的全量物化/容量、换窗来源、取消/迟到、旧缓存退役等提取真实路径，先留 RED，最小修复后 GREEN，关键撤回能翻红；不重复全部旧套件。
2. **普通写作：**约 23KiB 与接近 256KiB 各一条正常连续链，跨段微移/边缘驻留/反转、替换/续写、Undo/Redo、删除补位、键盘及滚后编辑，连续画面与 owner 一致。
3. **1GiB：**系统导入正常打开→首/中/尾可见定位及各一笔真实输入→跨有界窗口非空选择精确替换→Undo/Redo→公开 Agent 非冲突修改→免点击人类续写→保存→正常关闭→新 PID 重开→固定快照流式全字节核验。原文件不变；完整核验计时不充当输入响应。另用 64MiB 无换行/复杂 Unicode 夹具检验窗口预算与可取消性。不将全篇删除/重做或全篇可视解析新增为本包门。
4. **成本及安全：**20 笔分别记录内部时延和工具/显示观察；1MiB/64MiB/1GiB 比较正文、镜像、排版活跃量和 RSS。前台每次操作不得遍历全文，内存中全文副本不得随大小增长；文件映射/页缓存、必要的磁盘工作副本与历史另行计账。取消导入/准备、失效来源、空间或写入失败保旧各有受影响反例。超过预算或明显卡顿保持未闭合，不能改称“不测”。
5. **同源交付：**机制稳定后一次冻结、正式入口串行构建 normal Pharos/thermo。thermo 只消费受影响共同范围/换窗/选择机制并核其他字段零污染，不另造文件管理器。保存源码清单、HAP SHA、安装与 PID、原始输入/owner/画面/磁盘证据和简短启动方式；final6 不覆盖。未受影响旧来源/A2/Unicode/文件安全原证按影响复用。

## 执行与结束

本阶段相关生产代码、必要测试、构建与设备验证均由接到实施任务的执行者连续完成。按现行 AGENTS 升级已累计失败的具体问题，只暂停其依赖；其余工作继续。不自动调用外部模型、不新增独立用户聊天。

共享 core/框架需要修改时，在正典责任层最小修复并明确 H 消费同步；不能只在 H 复制一套机制，也不能把 E/W live 树整包覆盖进入本次交付。同 target 构建串行，保护用户文档、实例、剪贴板、转发、stash/暂存及 E/W 写集。清理仅针对准确归属的自有资源。未经用户要求不 stage/commit/push/reset/stash/切分支。

完成时集中报告实际交付、实际成本、剩余边界和可启动产物；1GiB 未通过不得称本包完成。更新本页实施记录与 ACTIVE，不再建立逐轮治理台账。
