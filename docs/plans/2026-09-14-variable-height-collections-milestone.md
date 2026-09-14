# 大阶段：可变高度集合、增量测量与稳定共同操作

2026-09-14，指导下发。原执行任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`，Terra/xhigh负责并直接复用Luna/high，原目录。此阶段已授权实施，不是待审批草案。

## 交付目标与取舍

开发者能组合不同高度的列表条目：短标题、自动换行的长摘要、展开后出现的内容。数千条记录只物化视口附近组件；插入、删除、展开、宽度变化或外部修改导致高度变化时，人正在看的对象与行内位置保持稳定，点击/焦点和外部动作仍对应同一稳定身份。通过通用组件接口与两个不同的真实消费者交付，不把测试专用列表当框架能力，不开发聊天产品、数据库或完整表格。

六主线取舍：自绘有序合成、文字资源复用、调度/语义与正式消费已有具体证据；系统IME/VoiceOver/多显示器仍需前台条件。本阶段优先组件布局的固定行高缺口，复用文字测量和局部失效来增加通用能力，而不是继续追单一超长文本极端成本。仓颉、自绘/GPU与人和外部系统共用真实内容的路线不变；不规定编码与Agent实现。

## 旧资产与必要欠项

- [设计导航](DESIGN_INTENT_INDEX.md)、[长列表阶段](2026-09-12-virtual-collections-offscreen-operations-milestone.md)及 [composable_ui.cj](../../runtime/cjgui/src/composable_ui.cj) 中的source、stable key、selected/focused/anchor、范围构造、键盘导航继续复用。当前 `materializeVirtualList` 强制固定高度，索引与滚动偏移依赖固定stride；本阶段扩展这些内部职责，不另起互不兼容的列表系统。保留已有固定行高快速路径与消费者兼容性。
- 复用已有真实文字measurer、单轮测量缓存、刷新事务、最终layout/clip/命中、组件实例身份和旧事件拒绝机制。测量高度是派生缓存，不是内容owner；系统字体排版仍由平台服务提供，不扩输入法或另做shaping。
- [低延迟阶段](2026-09-13-low-latency-text-resource-milestone.md)源码修复、1440样本受控对照、readback取样修正和导出成功已经指导按范围审阅。最近preview成功日志 `/private/tmp/cjgui-preview-consumption-oracle-final.stdout`，payload `d15a8c634d611bbb3e850d975d031a98920ca41abfd7dc3b82948121263b4cf0`。最后binary前台中文/emoji、GUI→公开CAS→GUI续写与关闭仍未验，不能将上阶段整体标完成。
- 上述GUI欠项只阻塞依赖它的前台结论，不阻止本阶段仓颉布局开发。解锁后先识别旧隔离进程与新bundle，正常关闭自己的旧实例，用当前有效binary完成适用最小复查；用户实例不动。新阶段改动后以最终构建同时覆盖相关旧欠项，避免每补一项重建全部。源码100KB插入/长单段成本和物理系统输入等残余继续明示，不要求先清零。

## 完整范围

1. **公共组合与测量入口。** Terra先确定source条目身份、内容修订、布局约束/样式与测量缓存键；提供实验性可变高度入口，开发者能用普通子树构造行，不用把高度或业务字段写入native。允许可靠的显式高度和未测量估计值，但必须交付至少一种用真实内容/宽度测量得到高度的路径，不能仅新增height数组。多行文本、展开内容和宽度变化实际改变高度；测量结果进入同一布局真相，绘制/命中/语义位置一致。
2. **范围索引、增量失效和有界工作。** 选择适合当前规模的高度累计/偏移定位结构，不预先锁死树结构。未见项允许估计，揭示后修正；不能为了确定总高先构造/排版全部条目。单行修改仅失效相关测量；约束/字体变化按真实依赖失效，可用代际懒更新避免立刻测量全量。可接受一次性或结构变更时的轻量索引成本，明确其复杂度；禁止把全量正文读取、组件创建藏在索引里。保留物化与native节点现有限额，缓存策略说明上界/清除/大集合退化，不无依据提高上限。布局收敛须有界，不以无限measure-refresh反馈追准确高度。
3. **稳定视口和交互。** 稳定key加行内位置保存锚点，估计转实测、锚点前增删或高度变化不无故跳走；锚点删除有确定邻近回退。过滤/重排、同索引换key、清空、尾部clamp、超高单行、重复/缺失key和算术溢出有明确行为。reveal和PageUp/Down按实际/估计几何工作，未测远处可先估计定位再有界校正，不宣称瞬间获得全量精确高度。导航不抢详情文本输入，失效节点事件不得落到新对象。外部授权修改屏外记录不自动reveal、不改人的选择与滚动；其后人滚动到该项应显示实际修改。
4. **两种真实组合消费。** 复用规则/文档或其他现有消费者，以两种不同子树验证，例如标题加多行摘要、可展开字段组；选最少业务改动的组合。至少一个消费者经现有外部owner动作改变屏外条目内容/展开相关数据，并完成读回、滚动显露、人的后续操作。不得为验收造第二份可写真相或mock成功；如领域现有动作不足，最小扩展其明确授权动作并保持CAS/批次语义。第二消费者也必须实际调用公共组件入口，不只导入空接口。
5. **证据与最终交付。** 针对性回归覆盖真实布局算法、身份/锚点、失败后恢复和新旧消费者。以1千/1万条、相同视口和内容分布测冷启动、已测区域往返滚动、单行变更、批量屏外变更、宽度失效；报告source访问/构造/测量/物化数量及总区间p50/p95/max，稳定二进制无verbose。数量应证明普通滚动不随总条目数全量构造/测量，耗时不超出证据声称O(visible)；结构索引重建与领域全量快照成本单列。每主要条件至少30有效样本，先用小样本验证再一次完整测量，不重复1440个旧文字对照。窗口无变化时不连续测量/提交；反复滚动/增删后缓存按设计收敛。

最终必要构建、声明/禁止行为扫描、相关布局/控制器/受影响native测试和diff检查；正式导出实际消费新接口、验证当前源码来源。真实GUI与外部接续锁屏时单列not_run，有条件再做；自动化probe不替代人可见窗口。失败计数/K3按AGENTS，公共/native影响按源码/工具实际证据核实，旧索引不当永久阻塞。

## 执行分工与结束条件

Terra负责增量测量与锚点一致性、缓存/失效边界及复杂衔接；默认一个Luna完整承接明确实现/回归/消费者包。先定写集，布局核心与测试/消费者可分开，不能同时编辑同文件或争测量负载。Luna发现接口矛盾或结构问题及时带复现交Terra；明确后交回，不为形式委派小碎片。根因清楚的衔接Terra可直接做，避免两层重复完整验收。

持续交付公共能力、两个真实消费者、规模/稳定性证据及旧GUI欠项；不能只交高度索引、测试报告或第一消费者就停。若只有桌面项目待验，保留原始构建/运行入口与精简欠项，回报指导安排下一项独立工作；若结构根因阻塞及时报告，不无限猜测。完成/实质阻塞主动报告指导 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。不新建worktree/任务/定时，不切分支、stage/commit/push、安装发布，不覆盖并行修改。锁屏不反复解锁或操作凭据，不改系统设置。

## 实施记录（2026-09-14，仍有前台验收缺口）

- 公共实验入口已落在 `runtime/cjgui/src/composable_ui.cj`：`CjguiComposableUiVariableHeightListItem` 明确 stable key、单项 `layoutRevision` 与未见行 estimate；`CjguiComposableUiVariableHeightListSource` 分开共享 `measurementGeneration`；`cjguiComposableVariableHeightList` 复用既有 `CjguiComposableUiVirtualListState`，固定行高入口保持不变。普通 row 子树经既有 `preferredHeight`/真实 measurer 取得最终高度，随后同一最终布局用于绘制、命中和语义；未向 native ABI 加入业务字段或第二布局树。
- 索引为“统一未见 estimate + 最多128个已见 key 的稀疏修正”。宽度或 `measurementGeneration` 变化清空派生缓存；单项 revision/title 变化只把该 entry 回退到新 estimate，下一次显露再真实测量。每轮先把缓存 key 重解为 live index，再以二分 offset locator 加稀疏修正确定估计范围；若真实行比估计矮，materializer 只在同一128行预算内追加并测量至实际行覆盖视口，再做一次最终范围/total/origin 发布。变量路径的 buffer 只保留在可见区之后，避免未测量的前置 estimate 在同一帧压缩后迫使第二个不同范围；它不读取全量正文或构造全量组件，source 自己的 key-index 建立成本单独报告。
- 布局 probe 的红测先证明公共类型/入口缺失；本轮又先红测“estimate=1000、真实高=10、500px视口”的空白反例及 `overscan=1000` 越过128行上限，随后转绿。最终 `verify_composable_ui_layout.sh` 还覆盖真实多行文本高度、10,000条首屏有界构造、锚点前展开、屏外 owner 修改不自动 reveal、主动 reveal 后的真实行/宽度高度、前插和锚点删除到后继、selection/focus 不重绑、同一state超过128个key后的淘汰/返回重测、混合高低行、尾部 reveal 与宽度失效。固定路径原回归仍同跑。`verify_composable_ui_window_controller.sh`、`verify_composable_ui_appkit_text.sh` 的先前通过仍仅是框架探针，不替代两个消费窗口的人可见验收。
- 两个真实组合消费者已经实际调用公共入口：规则集窗口的 row 为标题、当前草稿状态/摘要和原 `SELECT_RECORD`；文档窗口的 row 为标题、workspace 内容摘要和原 `SELECT_DOCUMENT`。规则的 selected/focused 背景/颜色保持 appearance-only、标题字重固定；`measurementGeneration` 仅表示字体族，选中状态折入单条 `layoutRevision`，因此 A→B 只懒失效 A/B，不清空无关的已测高度。框架比较 `item.title`，故外部重命名造成的标题换行不会复用旧高度。文档只调用 renderer-adjacent 公共实验接口 `cjguiExperimentalDocumentPreview`；接口在框架内构造 <=2KiB 的 scalar-safe 窗口，再经 internal macOS `NSString` composed-character bridge 返回值类型结果。它限定 `maxBytes=4..512`、`maxClusters=1..160`，输出包含省略号也始终 <=512 bytes；未知窗口末簇会被丢弃，不泄露 native object，并且只声称 macOS composed-character 语义，不声称跨平台完整 Unicode grapheme。领域 owner、CAS、外部 descriptor/transport 与动作名没有改造为 UI 真相。两个当前源码 `zsh run.sh --build-only` 均通过，规则 owner 原有测试15/15通过。
- 规模 evidence（核心修正并格式化后重跑）：`composable_ui_variable_height_scale_probe.cj` 与 `composable_ui_variable_height_scale_report.py` 在1,000/10,000条、cold startup/warm back-and-forth/single-row/screen-off batch/width invalidation五类各30有效样本通过，报告为 `/private/tmp/cjgui-variable-height-scale-guidance-final.json`，原始日志为`/private/tmp/cjgui-variable-height-scale-guidance-final/variable_height_scale.raw.log`，当前 source digest `4dfec9093a078521d7be109d9271abfd6329ae762178ac2e3047f3fda3ddd0a5`，binary SHA-256 `426fd8e321965dc34dc0df95c70c0e14a16c84b52202bb0b84c0a0e81379ea83`。10,000条 cold p50/p95：source item reads 11/11、row builds 8/8、measurer calls 16/16、materialized 4/4；warm往返为49/49、15/15、16/16、5/5。`elapsed_ms`全部0是毫秒时钟下限，不声称零成本或物理呈现延迟。
- normal rule bundle 的公开 owner 屏外链已以可读原始JSON保留于`/private/tmp/cjgui-variable-height-owner-pty.gT1BXB`（不含 capability descriptor）：初始/12次创建/修改/读回/陈旧CAS响应各自独立保存，`after-create-get.json` SHA-256为`46d5ff0b9f41cded62e908ba9f3de02194c06f493adda979aeb88318b89ba449`，`after-edit-get.json`为`b9a29ebc9ef63f2190c16a1ce1be3caa1c0dfd86b8ee46f67ad2447d414b1f70`；开展该次 owner 验收时规则包可执行文件 SHA-256为`41693d9989efbd1ca375736e2998f8d18cad9fecd568a46900db49844f0e0914`，随后初始核心格式化重建为`0bbe37ed7f2e3b09566d38eb8cf8c0ba670c9e048f9d0913e560c14055db019c`。本次局部选择失效修正后的 current rule bundle SHA-256为`f4ac1af5c7bd1f2eb54348c833939948357c03f85d875389479d063ac7dd5869`；current shared-document bundle为`19dc1dff3ad525872cefe2f20e29580362ce107cfa1d1d40f77c62c6a7d4a06d`，未把旧 owner raw 说成这些新binary的GUI验收。README/descriptor 为`CJGUI_SHARED_OPERATION/2`、17个`ALL` actions；公开 client 创建记录1..12后，version=13、当前选中rule12、材料化范围0..9。对 rule12 的 `EDIT_DRAFT_TEXT(fieldId=label, expectedDraftVersion=0)` 后读回 version=14、draft version=1、长中文`WINDOW_FIELD_VALUE`、scene/frame=15，材料化范围仍0..9、selection relation仍指向rule12；陈旧global CAS=13返回`version_conflict`且version仍14。这是真实 owner/CAS/屏外范围读回，不声称可读取 UI scroll offset。
- 当前已知欠项：此前 CUA 的最近读取仍报告系统锁定，本轮未重复自动解锁；上述 current normal bundle 的真实人工滚动显露/后续点击、UI scroll/selection不变量，以及低延迟文字阶段 GUI→公开CAS→GUI续写均为 `not_run`。不以 probe、app build、owner readback 或旧实例代替该验收；后续只操作新的隔离 source-built bundle，再完成这条最小真实链路。本轮成功 owner 验收的已知临时实例PID 44340已停止；两次连接前即退出的临时目录已移至废纸篓，成功的无descriptor原始JSON目录保留在上述路径。

## 指导复核：仍有源码闭环缺口，继续原阶段

指导已只读检查公共state/materialize、两个消费者和规模报告。本阶段不只是前台not_run：以下源码问题需先针对性复现并修正，不能以现有300样本通过替代。无需另开小阶段或等指导批准实现。

1. `materializeVariableHeightList` 在首次测量后求totalHeight/范围，再对变化后的范围测量，但随后仍发布第二次测量之前的totalHeight与origin，既没有再统一这些几何，也没有保证真实行已覆盖视口。用合法最小固定高度子树、统一estimate明显大于真实高度、overscan=0、足够多行和500px视口建立反例：例如estimate1000、真实高度10，第一次只物化一行，下一次通常仅多引入一行，实际内容远不足覆盖视口。检查首帧范围/内容总高/命中与下一次无内容变化layout是否发生漂移。不能以强制每帧重排修正，也不能无限循环。Terra采用有界行预算内逐步填满实际视口的策略，复用本轮已建已测行；最终范围、origin、scroll clamp与total必须来自发布时同一测量快照。达到容量仍不能填满时明确且确定地降级，不伪称完整覆盖。
2. `updateVariableMaterializedRange` 的while虽限制128，但overscan会在其后追加；起点又提前减overscan，`end<=firstVisible`分支也可能越过总限制。用overscan=1000、1万行及首中尾位置验证source构造/物化的真正上界，不能等native拒绝。先为可见行分配预算，再裁剪前后buffer，最终end-start不得超过既有限额；数量、索引与溢出安全一起处理。
3. 128条稀疏高度缓存淘汰会改变已知前缀偏移，当前规模warm场景不能替代越过缓存容量的往返。沿同一state至少访问超过128个不同key，覆盖大幅高低行混合、估计偏差、尾部reveal、宽度变化后返回。核对稳定锚点/行内位置与最终geometry、selection/focus；缓存和元数据有界，无内容变化时收敛，无全量构造。若失败先给可区分根因，不直接无限加缓存。
4. 消费者文档行把整个 `snapshot.content` 作为summary传给普通文本，仅maxHeight=72限制显示，不限制输入测量规模。提供按Unicode边界有界的正文预览，必要读取优先复用owner范围入口；保持正文owner不变，不能复制100KB文本到每次列表摘要布局。结合规则行selected/focused引起fontWeight/摘要变化，明确这些真实测量依赖如何失效，而不是把缓存键仅有title/revision宣称覆盖所有样式。

修正后先跑上述反例和受影响原回归，再在最终稳定binary更新受影响的规模/消费证据，不重跑无关文字矩阵。保留可复查的raw logs、source/binary指纹与公开屏外操作证据；临时应用可关闭，唯一原始验收记录不能随临时目录丢失，已移废纸篓的若是唯一记录须定位可用证据并保留必要副本，不能伪造补写。现有公共屏外修改后人尚未滚动显露，仍明确not_run。

### 第二次指导复核：局部失效与系统文字边界

视口填充和128物化限制已见源码修正，独立owner原始JSON已保留；本轮继续收紧消费者，不能写成仅剩GUI：

- 规则source将selectedRecordId编码进全局measurementGeneration，而核心generation变化会清空全部高度缓存；普通选择不应让无关条目退回估计。全局generation仅用于真正共享测量依赖，选择影响的摘要须进入对应条目的局部revision/失效，或使行高度与选择无关。覆盖多屏已测项、A→B选择后无关高度保留及锚点稳定，不以只改注释解决。
- 当前摘要自制分簇在ZWJ到来时会把它与前一base分开（startsCluster判断未把ZWJ附着于前簇），有限Unicode范围也不支持普遍cluster-safe结论。复用SDK或系统composed-character分段服务，不继续补造Unicode表；保持有界输入/扫描/结果，超长簇不能突破预算。若无可用服务，Terra需明确保守摘要的保证边界，不能伪称完整Unicode分段。预算临界ZWJ、组合标记、非拉丁序列与超长簇需覆盖，仍是文本服务集成，不扩输入法。

Terra定方案、Luna承接清晰消费者工作包；不无故重写布局核心或重跑无关性能矩阵。源码/针对性证据与最后真实GUI继续分开，前台限制不代替处理上述可运行工作。

### 第二次复核落实（仍待指导验收）

指导后续只读核对：局部selection revision与macOS有界composed-prefix策略方向可接受；最终仍需将样例中的 `foreign cjgui_internal_renderer_composed_prefix_utf8_length`、CString分配及预览包装移到框架的实验性仓颉文字服务入口，应用只消费纯仓颉接口，不把私有native接线留给开发者复制。桥接保留internal、无原生对象外泄，明确平台范围/输入预算/失败行为；不扩Unicode算法。无效UTF8可直接报错，无需对2KiB窗口递减重试上千次解码；局部revision乘2加bit的边界不得普通加法溢出。完成后验证最终导出包含新入口且Document消费者通过公共API实际调用，保留源码/产物/原始日志对应；不链接该桥接的旧规模probe无需重复。GUI欠项继续not_run，不据此阻塞独立封装与包消费。

- 规则消费者先以旧实现在 `selectionOnlyInvalidatesAffectedRuleMeasurements` 看到全局 generation 随 10→11 选择改变的 RED；修正后以20条规则、1200px 多屏布局预热、长文本 rule_1 非选中锚点实际经过变量高度布局，证明 generation 不变、A/B revision 改变、无关锚点 revision 与最终 y/height 保持、且实际高度大于76估计值。缓存本身不是公开可写真相；该 source 事实加核心既有逐项 revision 路径共同证明无关项不会因全局 generation 清空而回退 estimate。
- 文档消费者移除手写 Unicode 范围与“cluster-safe”泛称。针对预算临界 combining/ZWJ、Hangul/Indic、窗口末簇及超长组合簇先取得 RED，再以 `cjgui_internal_renderer_composed_prefix_utf8_length` 转绿：桥接只临时构造 caller-owned UTF-8 输入的 `NSString` 并返回 prefix length；输入不完整时末个 composed range 不输出。consumer测试为4/4，规则消费者测试为1/1；两 normal app build、根 `cjpm build --skip-script` 与 `verify_composable_ui_layout.sh` 已在本次改动后通过。测试中的 Indic 序列已改用 Unicode escape；仅保留既存 `chmod`/probe unused warnings，均无失败。
- 这次只改消费者局部投影和窄 native 文本服务边界，未重开 `composable_ui.cj` 或领域/CAS。平台无关的规模probe不链接该桥接；仍以新隔离目录重跑并得到同一source SHA-256 `4dfec9093a078521d7be109d9271abfd6329ae762178ac2e3047f3fda3ddd0a5`、scale binary `426fd8e321965dc34dc0df95c70c0e14a16c84b52202bb0b84c0a0e81379ea83`、10组各30样本全有界，10K cold/warm指标仍为11/11、8/8、16/16、4/4与49/49、15/15、16/16、5/5；报告`/private/tmp/cjgui-variable-height-scale-consumer-boundary-final.json`。它不替代 current normal app 的新binary指纹。真实人工滚动显露、点击选择稳定及 GUI→CAS→GUI 仍是 `not_run`，阶段尚未整体接受。

### 第三次复核落实（待指导最终验收）

- 文档样例不再声明 `foreign`、`CString`、`LibC`、`unsafe` 或 internal bridge；它仅 `import cjgui.*` 并消费 `cjguiExperimentalDocumentPreview(...).preview`。internal FFI 与内存资源管理收敛在 `runtime_renderer_session.cj`，对开发者导出不可变纯仓颉 `CjguiExperimentalDocumentPreviewResult`（`preview`、可用性、截断状态、reason、experimental/macOS 标签）。native 对超过2KiB或无效UTF-8直接返回 internal invalid-UTF8 状态，不再逐字节缩短窗口重试。
- 先补 `157` 个三字节CJK簇加一个39字节 ZWJ 簇的 RED：旧实现先按512 bytes取完整native簇、再在仓颉侧为省略号回缩，结果错误投影 `👩‍…`。GREEN 将3-byte省略号预算前移至 AppKit composed-range 选择（native budget=`maxBytes-3`），仓颉仅按native已选完整簇重构文本；文档消费者测试现为5/5，运行时7/7，规则消费者1/1。规则的 `draftRevision*2 + selectedBit` 同时收紧为 `saturatingMul(...).saturatingAdd(...)`。
- 本轮通过 `verify_composable_ui_appkit_text.sh`；两种 normal app `zsh run.sh --build-only`、根 `cjpm build --skip-script` 也通过。最终 normal rule/document executable SHA-256 分别为 `84f3a384d5640d5e8d2d92cb96d45acfcf4f731e226b3c5983db031bf7f936b1` 与 `c9734ebc1c03775d135e3cae012adbb514dd49aa69760b8ccb9a71928802b1fc`，同次 native archive 为 `5088b362d35f30fd61b8442d9dee8241c35964b20739cff6320e93fab64ce721`。这些是构建/链接证据，不倒灌为GUI验收。
- `verify_framework_preview_consumption.sh` 从最终源码导出、整体迁移到含空格路径后构建 UI-only、collaboration、document 三消费者；document只通过导出 `cjgui` 的公共API编译。原始成功日志保留于 `/private/tmp/cjgui-framework-preview-consumption-final-log.pe0OpN`；source/preview payload SHA-256 同为 `b1f6302b2d4ffebd92d1c595ad740c1bdbd30be8dce9783caa5ae13094305645`，document consumer source 为 `42812e0dd17c2ac9567c241c9b4b48f6cafb08c7b7b004100862a429482526f2`，该次 document export bundle 为 `e2ae8e55ace1ade88408857b0e743e760e43eb1a6c667dc9c6c3ffae5ccda249`。自动化还验证公开协作handoff的空标题写入与陈旧写拒绝；这不是变量列表人工GUI滚动/点击证据。
- 平台无关的规模probe没有链接新bridge，遵循复核结论未重跑；它继续只对应前述 `4df...` 源码/`426...` binary的布局有界证据。当前最终normal bundle的人工滚动显露、点击选择稳定和 GUI→CAS→GUI，以及锁屏条件，仍明确为 `not_run`；阶段等待指导最终验收。

### 解锁后前台补验（09-14；覆盖上文对应的 `not_run`）

- 首次从正常规则窗口创建记录时，领域操作实际成功而窗口刷新失败。先新增回归并得到 RED：`window.refresh() == true` 断言失败，诊断为 `duplicate_node_id`；原因是 split view 的默认 handle 使用节点 22，而首条记录 materialize 后的规则列表内容也使用 22。列表内容节点改为 24 后，规则样例 `cjpm test` 为 5/5、`zsh run.sh --build-only` 通过。
- 当前源码的新隔离规则 bundle 通过公开 `CJGUI_SHARED_OPERATION/2` 创建 16 条记录，CUA 在真实列表先显示 1..9、滚动后显示 6..14，并点击第 14 条；标题、详情字段和状态均读回 `批量滚动规则 14`，公开窗口投影为 scene 18、`pending=none`、`failure=none`。这完成真实外部 owner→屏外条目→GUI 滚动显露→后续点击，不把旧 owner readback 冒充为 GUI 证据。
- 正常 document 窗口还完成 CJK GUI（原生控件粘贴）→公开 CAS→GUI：文本到 v12 后，以 expected v12 在 UTF-8 字节 63..63 追加 `CAS 追加：已核验。` 至 v13；列表、编辑区、预览和 read-range 一致。CUA 直接 CJK `typeText` 仍只留下 ASCII，物理键盘和系统 IME 保持 `not_run`。该次只改默认文档的未保存内存状态，未指定 `--file`、未保存文件。
- 多窗口参数化生命周期也以独立 bundle `open -n … --args --multi-window --with-connection` 验证：同一 PID 公开目标为 3 个窗口，CUA 按自定义 bundle ID 附着到已启动的参数化实例，未再启动无参数副本。所有完成的独立临时 bundle 已在本次补验后以正常退出回收；仅保留用户恢复的正常规则和 document 实例。
