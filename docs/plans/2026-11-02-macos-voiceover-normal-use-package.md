# Mac VoiceOver 正常使用与公共语义收束整包

2026-11-02正式下发。主执行`01a18297-1b22-7f63-ad2d-e49f066db253`继续，实际调用`gpt-6.1-terra`与`gpt-6-luna`，思考档位按难度选择；主执行负责归因、集成和整包交付，完成直回指导`01a17207-04bc-76a2-90c3-99c8c5060423`。不等W/H/Linux，不恢复旧Sol/DS，不另开用户线程或监控。

## 目标与复用

依据[首版范围](2026-09-26-framework-capability-roadmap.md#first-mature-version)、[设计导航](DESIGN_INTENT_INDEX.md#shared-code-entrypoints)与[标准退出包已接受结论](2026-11-02-macos-standard-exit-package.md#guidance-standard-exit-accepted-20261102)。组件、普通键鼠/剪贴板、固定workspace公共客户端和标准退出已有适用证据；本包补辅助技术用户真正导航、读出、操作同一业务的缺口，不为凑实现量新造控件或复跑输入矩阵。基底SDK608162（642/618），根源/SDK身份已核；复用现有AX投影、组件角色/标签、owner绑定和原业务dispatch，不建可访问性专用业务镜像。

旧[系统正控原件](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/mature-runtime-20261028/package-vo-system-control-20261029/RESULT.md)已经用过CUA，不能因CUA现在可用就称条件改变。旧例只确立普通键盘焦点/Space有效，没有确立VoiceOver光标所在项及实际读出；不能据此认定VO组合键没投递，也不是已证CJGUI缺陷。新判别必须先明确VO光标和可复核的VoiceOver输出；此处是待区分假设，不是替旧失败改归因。

## 连续完成

1. **一次有判别力的系统正控。** 启动前准备目标、采集和恢复，记录当前VO状态/修饰键、函数键行为、输入源及已存在的系统实例。用自有标准系统控件，按当前macOS实际命令明确把VO光标置于目标，拿到名称/角色/值的真实读出或VO字幕，再作一次VO导航和动作并核值变化。普通AXFocusedUIElement、Space、AXPress或VO进程存在都不能替代。优先既有字幕面板的必要原图/文本；不把Live Captions当VO字幕，不增装捕获工具或改系统安全设置。只改变必要临时状态并精确恢复。

   官方方法已核：[导航命令](https://support.apple.com/guide/voiceover/navigation-commands-cpvokys04/mac)列出将VO光标移到键盘焦点的`VO-Shift-Fn-F4`，实际Fn按本机配置与投递能力核实；[VO字幕面板](https://support.apple.com/guide/voiceover/use-the-braille-and-caption-panel-unac078/mac)显示其实际朗读内容。必要时先查[Item Chooser](https://support.apple.com/guide/voiceover/item-chooser-vo2724/mac)选择目标，不能猜按键并轮流试入口。先证明光标和读出，再把动作无效归到投递或控件；不是单纯再按一次旧ctrl+alt+Space。已有同条件失败不反复重开系统/应用实例；新方法若仍无法建立正控，保首个明确失败并集中升级该门，不改CJGUI刷绿或继续数小时工具试探。

2. **接通正常消费者的可访问使用。** 正控通过后选已有普通Rules作为主体，复用当前SDK/正常构建，覆盖常用列表/表单、文本与布尔控件、按钮和模态的实际VO导航、读出与激活。使用有区分力的双owner状态：选择B时打开A、正确名称/值与目标、一次修改/确认只影响A、取消保稿或回到应用规定状态、关层后正确目标；列表/可用性随正常应用状态更新。不要逐控件做笛卡尔积；若另一消费者才具备受影响的整值/owned编辑机制，只补那一条接缝，不重跑其整包。

3. **真实缺陷落在共同责任层。** 先区分系统/输入通道、VO光标、候选未接受、AX角色/层级/名称/值/动作或陈旧绑定。保能区分的生产RED后修最小共同实现或必要窄Mac桥；沿现有版本、owner、模层、退休和输入完成契约。同一个操作必须进入现有业务路径，不以AX写入/private调用、重复动作、补焦点、等待或重发救绿。需要时局部查本地AppKit/GPUI等参考，不引入外部框架。无生产缺陷就如实交付新取得的正常VO能力证据，不造补丁。

4. **完成受影响交付。** 修复汇合后用最终普通应用完成必要连续链；实际VO读出/目标、完整owner正文版本、可见反馈、取消/保存和自然退出各有直接证据，查询/截图不能替实际激活结果。普通输入、菜单Quit、末键退出等刚接受原件按原身份复用；仅当本次修改影响其中接缝才补。公共用法写入已有组件/消费者说明，不能靠私有验收脚本让开发者可用。只有载荷变化才导唯一SDK及正常包外受影响消费；无变化沿用608162。

## 分工、收束和资源

Terra负责VO光标/AX责任判别及共同修复完整块；Luna负责已明确方法的正常消费者、原件和收尾完整块。主执行先固定方法和必要接口，两个子代理不争桌面、target或同一文件；复用代理，必要时以同指定模型的短上下文接续。子代理只回主执行；不把方法未明的失败反复丢给Luna。独立的源码/公共接入检查可并行，但不能把纯检查数量当交付，也不因等待正控另造工作。

只管本Mac框架正常使用，不接Pharos应用业务或跨平台包；16/32ms、四类20及既有性能归因限制仍如实保留。此次不恢复性能B/C/D、Source/Visual、GiB、旧退出/输入矩阵。参考[验证价值规则](../../AGENTS.md#verification-value)：每次验证必须改变修复或交付判断，不增加确认回合；整包做完或遇有证据的实质阻塞一次集中回指导。

沿[容量规则](../../AGENTS.md#artifact-space-budget)，累计E16,708,403,200B、DS3,279,339,520B不清零，五部3,044,466,688B。旧E帽仅余约1.6MiB，指导明确只为本包将E/DS留存帽各增64MiB至15.625GiB（16,777,216,000B）/3.125GiB（3,355,443,200B）；峰仍16.5/3.5GiB、五部临时3.25GiB、宿主峰后≥20GiB，当前宿主约176.28GiB。额度用于必要新SDK约26MiB、可复盘正常二进制归档约10MiB及原件约16MiB/差分余量，非必须都花完；无源码变化不占新SDK额度。不可截断或删除失败样本迁就额度，确需超出先说明具体不可复用项与退役点。

一个复用工作目录，高写盘前核并存峰。保护608162、952952、ad7935和唯一RED；不为最后几KiB反复压缩或猜删旧产物。成功/失败/取消均退役本线可再生产物；仅关闭准确自有实例，保护用户和其他线，恢复本轮改变的VO/字幕/输入源状态。给实际新增/留存/回收、峰值采样范围、宿主余量；无Git写、顾问、新线程、重复监控。主执行不改ACTIVE，集中回报后由指导更新E当前摘要。

<a id="execution-system-vo-gate-20261102"></a>
## 系统正控执行结果（2026-11-02，交指导）

唯一系统轮结果为 `VO_ITEM_CHOOSER_AND_SPOKEN_CONTENT_UNESTABLISHED`，见[原件与完整边界](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/RESULT.md)。本轮按已核 Apple 文档只发一次 VO-I，目标为自有标准 AppKit 两复选框，避免 Fn 不确定性；真实旁白引擎 PID 66390，普通焦点 Alpha，但未取得可辨识的项目选取器或目标名称/角色/值的真实字幕/朗读。VO 截图只有未标识轮廓；无同期前台/HID 证据，不能归因键未投递，也不是已证 CJGUI 缺陷。没有重按、换组合键、补焦点、等待、VO激活或 AX 直写。普通 Rules 的双 owner 正常 VO 门未开，公共能力未验。

VO/input source/字幕等前后态已恢复；五个自有实例及输出服务余留0，终态后零 App/AX 调用。SDK608162 642/618 逐载荷零漂移，无生产源码改动或新导出；Luna 离线 Rules 预案已就绪，不能替代 UI/持久化证明。全仓既有两处空白问题原样保留。只退役本轮 Swift 缓存211,714,048B，累计释放7,510,487,040B；精确终态留存与离散峰值范围见原件空间账，授权64MiB增帽不清零。本次只集中升级系统 VO 光标/读出及全局命令可观测的正控通道；不依据此失败猜改 CJGUI，不恢复旧矩阵。主执行未改 ACTIVE。

<a id="guidance-system-vo-gate-review-20261102"></a>
## 指导裁决：保留失败，先补观测准备，等待实体键盘对照（2026-11-02）

已核首次失败JSON、CUA实际调用、系统前后态、原始图片与小程序源/二进制身份。该轮仅证明系统正控未建立；没有CJGUI生产RED，也不能称VO快捷键丢失或系统缺陷。SDK608162和既有输入/退出接受结论不受影响，不重查整套绿色。恢复/自有实例清理和原口径新增2,752,512B、缓存回收211,714,048B限域接受。

具体方法缺口：小程序在 `makeKeyAndOrderFront` / `activate` 返回后立即记录ready，原件active/key均false；未记录真正激活完成，也未采到VO-I同期前台。截图是VO未标识轮廓叠加层，不能当字幕。指导查当前CUA公开接口仅有App级pressKey，未提供可确认系统全局投递的接口；另一个Kimi键盘接口明确为后台投递，但不能据此断言本轮CUA的内部实现相同。当前没有证据支持重新用同一App按键方法再试。

必要有限接续交原主线：只在既有自有标准控件小程序补真实激活/键窗口通知与带时间的前台PID、窗口key状态、firstResponder身份记录；ready须对应条件成立，不能把异步请求返回当完成。这是诊断准备，不是CJGUI产品修复；保原小程序/首次失败身份，原目录复用、差分及新身份分开，只重编这个小程序，不构建Rules/框架或导SDK，不开新的控制器或捕获工程。准备好一条实体键盘正控的具体入口、采集与恢复步骤后回指导；本次不启动VO、不占前台，也不投递任何新VO快捷键。

指导已向用户询问是否方便一次实体Control+Option+I对照。得到用户明确可配合并由指导发信号后，主线再准备自有窗口，确认当前真实前台与键窗口，启用VO并明确交给用户按键；不得预先代按、补按，或让用户对着已退出窗口操作。记录人工操作与机器投递的证据区别；出现Chooser后再读其实际目标/字幕，不以设置值、AX普通焦点或对其他控件的AXPress代替。对照之前保持系统已恢复状态；用户暂不方便则只保留此具体依赖，不启动旧性能/输入矩阵或制造新阶段。

本包仍未完成。已有Terra/Luna分工继续复用，有限准备完成无需另回同义确认；主线直接回指导实际准备结果或具体工具限制。累计E16,711,155,712B、DS3,282,092,032B，五部3,047,219,200B，留存帽15.625/3.125GiB、峰16.5/3.5、临时3.25GiB均不再增加，宿主约176.24GiB。指导维护ACTIVE，执行者不改其他线或Git。

<a id="execution-manual-entry-prepared-20261102"></a>
## 实体键入口已离线准备（2026-11-02）

[具体入口/采集/恢复](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/system-control/MANUAL_ENTRY.md)已备，新的标准控件小程序仅离线编译及签名校验；没有启动VO/窗口或投新快捷键。ready改为真实AppKit激活/key通知、NSWorkspace前台PID和当前目标窗口/Alpha firstResponder条件同时成立，带wall/monotonic时间及对象身份；失焦/退出撤销。原首次失败程序和10个源/签名/身份/状态文件哈希保持不变，新源/二进制在同目录分名保存。Runtime通知与窗口真实ready仍未验，等待用户可配合且指导发信号后才实际准备并交实体键。无CJGUI/Rules构建、新SDK或ACTIVE写；本次缓存已按finally退役，累计与当前空间账见原报告最新段。

<a id="guidance-manual-entry-prepared-20261102"></a>
## 指导复核：人工入口准备已接受，现场仍未运行（2026-11-02）

已核[实体键入口](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/system-control/MANUAL_ENTRY.md)、当前源码28eb148f与EXE1383443a身份、原10件零漂移及离线准备/清理记录。新源码从真实激活、键窗口和workspace通知取状态，ready要求前台PID、本窗口及Alpha firstResponder同时成立；失焦/退出撤销ready，未增加键盘合成或监听。图索引未覆盖该Swift原件，已直接核6757B源码。本次接受“已编译签名的准备入口”，不接受尚未发生的实际通知、窗口就绪或VO操作。

当前manual-current和module-cache均不存在，未启窗口/VO；不继续重编、取态或代按。唯一待办是用户是否方便配合实体键盘对照，待其答复后由指导通知原主线准备。按键前须保一次真正当前的ready与存活凭据；若Chooser正常出现并取得前台，之后ready撤销可能是预期变化，不能把结果时的失焦倒推为按键前未就绪。人工来源、字幕/目标和应用回调仍分别记证据。

离线新增241,664B、缓存回收211,664,896B；整包留存2,994,176B、回收423,378,944B，累计回收7,722,151,936B。E16,711,397,376B、DS3,282,333,696B，五部3,047,460,864B，帽与峰值规则不变。无需执行者再回同义确认，本轮不再下发独立新任务。

<a id="external-executor-handoff-20261102"></a>
## 用户更换本次执行者（2026-11-02，最新指令）

用户明确表示本次不用Sol，将自行选择另一模型执行。指导已核原主线01a18297-1b22-7f63-ad2d-e49f066db253为idle；不唤醒、派工或自动恢复它。新模型接本次VO现场对照及本包受影响接续，具体型号由用户选择，不继承原主线的强制Terra/Luna编排。提示词交用户复制，当前不声称外部线程已收到或开工。

用户已答复可以，指导在交接提示词中正式下发现场准备，因此旧文档“等待用户可配合+指导继续信号”已由最新指令满足，不再要求一轮开工批准。实体Control+Option+I仍须由新执行者把准确窗口准备到真实ready后，明确请用户亲自按一次；不能把该开工授权或模型工具请求冒充实体键。当前程序与原件直接复用，不先重编或重跑SDK/旧矩阵。

既有源/版本/容量/恢复与首个明确失败边界继续有效。一次实体VO-I只证明相应通道/Chooser现象，不外推自动化VO导航、激活或Rules已验；系统目标、读出和实际动作闭环成立后才继续正常Rules消费与有真实RED的必要框架修复。若后续仍只能人工完成，集中说明最少动作，不重复空跑。完成本包或遇实质阻塞集中报告，能直接回本指导则使用已有真实通道，否则交用户报告，不声称已发出。

<a id="guidance-normal-vo-review-20261102"></a>
## 指导复核：接受系统正控与部分正常消费，同包仍须完成（2026-11-02）

外部执行者已交回[正常Rules报告与原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/luna-rules-vo/run-20261102-normal-vo/README.md)。指导限域核了系统状态/事件和真实字幕原图、三份公开快照、151B业务文件、构建与关闭日志、仪器差分及空间原件，未重新启动应用或运行测试。此次不用Sol，继续由用户选择的外部模型负责；未建立实际跨聊天通道，不声称接续已经送达。

**已接受的增量。** 系统仪器本次源11cae421/EXE8b97388c，先前28eb/1383另存；新增的是准备/激活时安装Alpha普通焦点，不能混用旧身份。人工“可以了”属于用户回报，未保存当时Chooser出现的完整证明；但随后一次合成VO-Space、一次VO-Right和一次VO-Space已有Alpha/Bravo动作与字幕对应（seq24 actions0 → seq27 actions2，两项值均1），足以成立本次系统导航/激活正控，不再补跑旧VO-I。Rules main b4c09f91与SDK608162相符，构建记录renderer_link=verified；运行EXE b8c0dd72/PID53098按原件身份接受。本轮布尔草稿v1、Apply v2、再改v3、Cancel v4有对应公开字段，151B保存文件aa6d342d独立解码为A停用/保留2/cache、B启用/保留10/temp；Cancel后文件未改。普通业务关闭有discard_ui、close_permitted、destroy complete、leftover_holds=0日志。未取得包装器实际退出码，不追加exit0断言。既有SDK、输入和标准退出接受结论继续复用。

**整包完成不接受。** 本轮没有覆盖任务原定的文本编辑、选择B时打开A弹层及完整双owner草稿/版本读回；三份GENERATED_UI_SNAPSHOT只有当前五字段及生成实例元数据，保存文件能证业务落盘，不能补成B草稿全过程。列表转到B依赖普通Down；这可能是合法列表交互/虚拟化，不能仅凭Chooser缺项判定生产缺陷，也不能把它改写成全程VO导航通过。退出守卫最终用了指针，缺少守卫的实际VO可达与激活证据。守卫截图与Chooser里的旧版本/计数提示需要区分当前场景、AX图及VO缓存/通知；未核全量Chooser前不宣称按钮必然不存在。详情版本标签的暂时陈旧也保留为同一更新边界的待判别项。

**恢复与容量须纠正。** [恢复原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/system-control/manual-live-20261102/system-restore-final.json)明确voiceOverOnOffKey初值0、末值1、legacy_restored=false，且改动了另一个axShortcutExposedFeatures字段；关闭进程或另一个快捷键字段不能代替原状态恢复。字幕用MediaAccessibility域不存在也不足以证明实际VO字幕设置恢复。核本轮真正修改的VO开关/修饰键/字幕及快捷键，与保存的before逐项对应；通过正常系统UI恢复，保留原值不存在与false的区别，勿覆盖他方变更。撤回未验证的sudo及跨偏好域写建议，不绕过TCC；确实受权限限制就保留具体未恢复项和准确人工恢复步骤，不写“已恢复”。

[空间账](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/closeout-space-account.json)把本包work/macos-vo-rules-20261102排除在五部之外。指导du核该目录176,250,880B（原图107,008,000B、SDK工作副本68,677,632B及其他），全部仍须归本包；按报告同一采样加回后E16,928,714,752B、DS3,499,651,072B，分别超过原留存帽151,498,752B和144,207,872B，WITHIN_UNCHANGED_CAPS不成立。现场五部另比报告多12,288B，最终须重新按全路径实测；起末离散样本不能称完整峰值。新增44,060,672B原来是整个VO阶段内五部增量，不能当新执行轮的全口径留存。累计释放还漏接先前423,378,944B，两次原件所记回收若保持成立，则应为7,941,918,720B。不得通过换目录、重置基底或删除唯一失败原件压账。

**本包集中接续，直接推进实际可用性。**

1. 先处理本轮系统状态恢复与全口径空间纠正。保全必要原件，核归属/占用后处理重复帧及可再生产物；复用当前工作目录，避免删后再拷整包。预算仍沿本页上限，峰后宿主至少20GiB；保护原件若确需超帽，说明不可复用项和退役点，不反复压缩或静默增额。系统恢复若有真实权限阻塞，只暂停依赖它的现场操作，独立的离线定位与实现继续；高写盘仍须先落实容量。
2. 沿SDK608162和当前相同的native aca8ced9接续，优先核`CJGuiInternalComposableSceneOverlay.reconcileAccessibilityActions`、当前scope/identity与通知、正常Rules列表/守卫声明。CodeGraph本次未覆盖该ObjC源，已按实际文件局部检查；这里是定位入口，不是既定根因。用同一接受场景对照公开目标、AX层级与可复核VO输出，区分投递/交互方式、虚拟化、投影遗漏与通知陈旧。只在真实RED后修共同语义或窄Mac桥，应用接线问题留在消费者；不常驻全部虚拟行、不建第二份业务状态、不用延时/重发/鼠标代操作刷绿。
3. 把尚欠范围合成一条正常Rules链：经可访问列表选择B，打开A编辑弹层，读正确A名称/值，真实文字和布尔输入只改A；确认、再编辑取消、返回正确目标，公开读回两owner完整正文及draft/applied版本；随后保存并通过可访问的退出守卫自然关闭。允许框架正常的列表交互方式，但须证明VO用户能发现和使用；普通Down不能自动定为缺陷，也不能替代未发生的VO光标读出。记录实际退出码及descriptor清理；不为同义证明另开整轮。已验布尔链/系统正控/旧输入退出矩阵不重复，只有源变动影响的接缝才补。
4. 修复需要构建时按AGENTS完成相关反例、受影响正常消费和声明/差异检查，保持原SDK只读；只有交付载荷改变才重导唯一候选，并绑定实际源/构建/运行身份。正常VO使用方法写回现有消费者文档。持续完成后集中报告实际修复、已验/未验、系统恢复与正确空间账，不逐项停工。外部执行者不改ACTIVE、不恢复旧Sol，不增加顾问、线程或监控，无Git写。

<a id="guidance-row-capability-integration-20261102"></a>
## 指导复核：行能力补丁须补角色转换，随后直接回接与交付（2026-11-02）

已核[三处native差分](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/renderer-row-scope-fix.diff)：82434ff8从受保护608162的aca8ced9严格重放等于工作副本19c06921；共同根仍为aca8ced9。build-normal-vo4记录normal构建成功、renderer_link=verified、四成员归档d91ac3a6；运行物3f0cef30按退役前哈希记录标识，不冒充当前仍有可检查的EXE。此次没有在指导侧运行构建/测试或前台。

**修复方向与正常消费限域接受。** AX属性原件证实PID25410的ScrollArea/StaticText有三个disclosure属性，PID34864修复后消失；行专用类隔离这些getter方向成立。原件和实现足以支持消除非行“已折叠”误报，不能把此前所有导航停滞都归到这一个原因。A文字/布尔Apply及Cancel结果、B部分字段保持v0、149B保存文件9d23eb3d的完整两记录、守卫真实VO目标字幕和PID34864的正常关闭日志有对应证据；PID49178另有关闭日志与退出状态0，分别接受，不拼成同一实例。保存实际使用公开SAVE_RULE_SET客户端，不是这轮VO保存；之前基底上的VO保存仍只归基底。系统正控及旧布尔链继续复用。

**必须修的一处代码接缝。** 19c06921的reconcileAccessibilityActions只在cache miss时按semanticRole选择RowAction。缓存键不含role或能力类；共同nativeSemanticBindingKey同样不含role，公共节点允许保留identity/incarnation而改变semanticRole，既有composable_control_ax_semantics_test也已覆盖同identity换role须通知。于是row→普通控件会复用仍实现disclosure getter的旧RowAction；普通控件→row会复用缺getter的基类。报告的ax-row-title-attrs-after-fix实际是AXStaticText，不是AXRow，不能证明行能力保留。

按既有测试入口先保反例，再做最小修复：同nodeId/resourceId/nodeKind/incarnation/binding的合法非行↔行转换，以及保留旧AX引用的返回转换；角色要求的能力类变化时替换wrapper，沿现有retirement清除旧引用并通知。优先比较所需确切类/能力族，不用isKindOfClass(base)误接纳子类，也不为同类普通属性更新重建全部AX对象。同类更新继续保持稳定身份；实际AXRow的展开/层级/子节点与非行不暴露这三个getter一并核。复用现有control AX和protocol setter/退休反例，不扩大到所有可选属性重构或全平台矩阵。

**已授权直接完成集成，不再等待一次“是否合并”的答复。** 完成上述必要返工后，核共同根当前字节及并行写集，把精确最终差分和相关测试回接共同源；当前根aca8与基底一致是本次检查事实，执行前仍以实际状态为准。有真实冲突才升级，不覆盖新并行改动。随后沿现有构建/导出流程交唯一新SDK、保持608162只读回退，并从新候选完成一次受影响普通Rules消费。之前有效文字/布尔/取消/关闭证据按19c原身份复用；最终一轮集中补完整两owner原始读回、真实VO保存及守卫自然退出，必要编辑/取消衔接合在同一实例，不重复系统正控、三轮稳定性或历史输入性能矩阵。

原始字段记录有边界：[双owner抄录](../../work/macos-vo-rules-20261102/evidence/vo-chain-2-dual-owner-readback.txt)中Apply后的B只有三字段、Cancel后的两owner各三字段，最终文件不能替代缺失的草稿字段。先从已保留的实际工具输出恢复完整正文；没有原输出则在上述最终一轮补齐，不能把解码推断或摘要扩写成原件。已有输入过程涉及剪贴板、输入源/前台修正及普通Space，按真实路线标注，不称全程无补焦点的VO键入。英文字幕与先前对话文字相似，仅凭不一致不能定性为注入；把它列为来源/VO目标未核，优先查原有前台/目标记录，不为此再启工具实验。

消费者README须跟最终交付身份校准：当前主树仍是旧renderer，不能宣称旧SDK已包含私有补丁的完整VO链；客户端保存不能写成VO保存。取消关闭不会出现destroy complete；Chooser粘贴失败只记本次工具现象，不概括为系统能力限制。真实正常用法保留，原生测试或AX属性表不替VO行为。

**系统恢复停止低收益试探。** 本次指导只读核voiceOverOnOffKey已回0；其余修饰键/字幕/输入源按恢复文件的UI读回范围记录。axShortcutExposedFeatures由缺省变为显式值的功能等价尚未证实，不称完全一致；不得建议删除整个字典，当前其中还有其他辅助功能项。撤回settings-restore里未验证的整字典defaults delete建议。依据已有before/UI原件说明剩余差别，若确需人工处理只指对应项，不继续猜键、绕TCC或反复切换系统设置；此差别不阻塞独立的框架返工和集成。

**明确本次收尾预算，避免为少量额度反复搬运。** [修正账](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/voiceover-normal-use/integration/closeout-space-account-corrected.json)已把work纳入；指导du核五部约3,058,262,016B、work180,191,232B，宿主约195.15GiB。旧帽下超额事实保留。为保护唯一原件并完成必要角色反例、共同回接和SDK交付，本包E/DS留存帽各追加128MiB至15.75GiB（16,911,433,728B）/3.25GiB（3,489,660,928B）；累计占用不清零，峰仍16.5/3.5GiB、五部加工作目录临时仍3.25GiB、宿主峰后≥20GiB。原生反例与普通应用构建串行、一个复用目录；新增最终SDK预计约26MiB、必要运行物归档约10MiB，先计同时峰值，成功/失败/取消均清本线可再生产物。完整工作SDK约68.75MiB在最终差分可重放、必要运行物和原件保全后退役，它并非必须整套保留的“唯一源码”；不先删后拷造成重复构建。

回收计数也按时点更正：指导上轮已实测work176,250,880B、SDK68,677,632B，不能无依据将旧target回收改称从未发生；本轮重新构建后再次退役是不同产物。按已有删除/构建记录区分，缺记录的部分不追加“已核回收”，不为校账重建。独立时段最大值相加只是保守预算界限，不是实际观测峰值，也不能据此宣称峰值已通过。完成实际修复、最终消费与收尾后一次集中回报；外部模型继续主责，旧Sol不恢复，无Git写、顾问、新线程或监控。

<a id="guidance-final-vo-acceptance-20261102"></a>
## 指导最终复核：接受本包交付，保留证据范围（2026-11-02）

本包的非行 disclosure 误报、角色能力转换与共同源码/SDK 集成已收口；没有新的生产缺陷需要返工。无需再运行本包构建、前台链或提交同义收口报告。该结论不等于全部 Mac 框架目标已完成，也不恢复停放的 Sol 或自动启动下一阶段。

**独立核实。** 差分 `594820ee` 的三个 hunk 从受保护 `608162` renderer `aca8ced9` 严格重放，结果与共同根及新 SDK 的 `eda3a550` 逐字节相同。新 `sdk-eb58ceb9` 的642个文件长度/SHA全部一致，618个闭包输入全部对应当前根，与旧锁相比仅 renderer 改变。测试 `bba815d0`、脚本 `bcb2b2ec` 与报告身份一致；已读实际行层级、同identity角色回转、替换时旧对象退休、同类更新稳定身份的断言及最终PASS、cjpm成功日志。去掉缓存命中时的能力类转换会违反这些断言，这是源码审查判断，不冒充本次独立执行了旧实现RED。指导未运行测试或构建。

**运行交付身份。** 运行来自中间 `41472b6b`，构建日志指向该SDK并记录四成员 renderer archive `c826dc9d`；最终 `eb58ceb9` 是README重导出，不称重新执行完整输入链。11,016,748B归档SHA `2f3d1057` 与其中EXE `c888abe5` 已独立核实。归档含13个普通条目及13个AppleDouble元数据条目，共26个tar头；identity中的members=13按普通条目理解，不是全头数。旧SDK和初版补丁 `renderer-row-scope-fix-v1.diff` 的 `82434ff8` 原件保留。

**正常消费边界。** PID88443的保存焦点截图、149B文件SHA `9d23eb3d`及12:08:48文件mtime、关闭日志与报告路线相符；接受第二次VO-I选取保存→VO-Right→VO-Space的保存结果。文件已与已应用值一致，证明同字节保存，不称新草稿在此实例提交。最终守卫明确先用AX设置焦点，再由VO-Space激活；接受该操作下的自然关闭，不称独立VO导航到达守卫。PID90050的实际exit0单独记录。文字/布尔/Apply/Cancel及补全的两owner字段抄录仍归19c/PID34864，不能搬到最终PID；本次未重新采集或逐行核原transcript。原正控和适用绿证继续复用。

**文档与资源。** 指导已校准公共README及结果中的版本、辅助聚焦和峰值口径；公共README这次只是说明更正，交付SDK保持不可变，不为措辞再重导包。另撤回“缺省与显式false功能等价”和“英文字幕已定性注入”的无证判断，不继续操作系统设置。指导实测五部3,096,748,032B、work115,843,072B（文档修订前样本），留存仍在E15.75/DS3.25GiB帽内；后续少量文档增量不重置累计。原峰值估算只加193,712,896B，三个退役分项合计却为262,631,424B，且源副本/中间SDK的并存时点没有完整采样；因此账中within_peak_caps已改为未证。225,289,684B只是退役量减新增留存的算术，不是已测峰值回落。不为补历史峰值重建，下一次实际高写盘动作仍按完整并存量预算。

本次只读复核原件并修改说明与ACTIVE E段；未改生产实现、SDK、其他执行线摘要或系统设置，未使用额外顾问、代理、线程或监控。


