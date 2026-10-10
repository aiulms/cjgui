# 鸿蒙下一包：多屏连续写作与文件往返

日期：2026-10-07。性质：用户要求的下一整包执行提示词；由用户交当前执行模型启动，指导本次不启动实例/构建/实现。r31原可视编辑包已验收关闭，保留其成果。

## 阶段选择

从单片段正常编辑推进到用户能处理一篇跨多屏的真实文档。当前确定缺口是OHOS产品 `commitVisualSelection` 明确返回 `selection_crosses_visual_fragments`；宿主选择拖动尚未接共同滚动活动；当前reveal以整个节点为目标，presentation carrier不能代替caret矩形。键盘默认避让可能已部分生效，本轮尚未实测，不能说平台完全没有避让。另产品只绑定私有固定文件，没有正常用户选文件入口。此包补这些相关能力，而非继续建设日志配对工具。

维持现有 **262144 bytes（256KiB）** 容量门，验收用至少八屏、十二个以上真实段落的UTF-8/Markdown文档，含标题、空行、列表、不同字级、折行、中文、ZWJ/旗帜/分解重音。不是GB、任意富文本、完整文件管理器或新编辑器项目。原task #12等独立待办继续留开，不隐去，也不无条件装入本包。

## 只读上下文与复用入口

先读仓库AGENTS、ACTIVE中的当前H段、本页和直接源码，写仓颉前读cangjie-coding技能。不重读二十多轮报告。r31结果仅从[已验收节](../../artifacts/visual-edit-20261004/guidance-review-20261005/after-ae-review.md#r31-finite-closeout-accepted)按影响复用。

- 框架主树：`runtime/cjgui/src/text_session.cj` 的源选区/镜像/票据与 `composable_ui_window.cj` 的选择、accepted位置、viewport/reveal/活动调度；核当前实现和E并行diff，不把Mac TextKit平台实现或E未验分支整块复制到H。
- H快照：`runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj` 的 `CjguiPresentationSourceRecord`、`freezePresentationHit`/`submitPresentationSelection`、`applyViewportScrollStep`、`revealAcceptedNodeIfNeeded`、`stepWindowActivities`；host的 `SelectionDrag`、`queueSelectionExtentLocked`、当前排版租约、clip/geometry身份；共享ArkTS `cjgui-text-proxy.ets`/`cjgui-text-menu.ets`。
- 产品：`/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src/pharos_ohos_controller.cj` 的 `commitVisualSelection`、`handleVisualPointer`、accepted/candidate两槽、`visualDrawStateFromSession`；`packages/editor_surface/src/bounded_visual_binding.cj`/`range_mapping.cj`/`surface.cj`；`packages/markdown_engine` 的SourceMap；复用 `document_core`/`app_services` 的唯一owner、历史和保存。
- 文件入口：`pharos_ohos_document.cj::pharosOhosOpenSmallDocument` 已按字节限额打开；`PharosDocumentService.save/beginSaveAsync`＋`pollActiveSave()` 保存；`readWholeCurrentVersion(maxBytes:262144)`取得固定版本完整字节。`saveAs`会改变绑定，不可将其误作不改变工作副本的导出。

**分工不变：**仓颉框架负责通用选择、活动、有效视口、accepted身份与命令结算；平台桥提供系统窗口/键盘/输入/文件能力；Pharos保留Markdown语义、SourceMap和文件工作流。框架缺陷回框架修，不能靠Pharos私有计时器、重复点击、脚本重发或放宽版本门兜底。公共核心改动先核并行写集及影响范围，做必要最小共享改动；同步采用正典输入与文件清单，不覆盖E/W在途文件、不把通用代码复制成每个产品各一份。

## 参考必须落实到方案

按[已有导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)只读一个最相关实现及对应测试，先说明借鉴的状态归属/失效规则、CJGUI差异与实施点，再编码；不要通读或引入这些框架依赖。

- Flutter本地 `packages/flutter/lib/src/widgets/selectable_region.dart::MultiSelectableSelectionContainerDelegate.dispatchSelectionEvent` 与 `test/widgets/selectable_region_test.dart`：跨子项的两端、顺序与反向选择。CJGUI文档顺序来自源映射，不能按屏幕排序拼正文。
- Flutter `widgets/scrollable_helpers.dart::EdgeDraggingAutoScroller` 与 `scrollable_helpers_test.dart`：目标静止在边缘时仍推进、滚动后重算；接回CJGUI已有单调时钟/窗口活动，不复制Flutter动画运行时。
- Flutter `widgets/editable_text.dart::_scheduleShowCaretOnScreen`、`didChangeMetrics` 与 `editable_text_test.dart`：布局后按活动端矩形做reveal、键盘变化时保持选择；Zed `crates/editor/src/scroll.rs::ScrollAnchor::scroll_position` 与 `element/mouse.rs`：文档锚经新排版重映射。
- 本地根：`/Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库`，当前定位版本Zed `1a28cff4…`、Flutter `8db55268…`；执行时只核相关入口是否仍在。
- 系统接缝查当前华为官方文档与本机SDK声明，不能靠猜API。参考[窗口避让指南](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/immersive-window-feature)、[UIContext键盘避让](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-uicontext-uicontext)、[DocumentViewPicker](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-file-picker)。本机 `.../DevEco-Studio.app/Contents/sdk/default/openharmony/ets/api/@ohos.window.d.ts` 已有 `getWindowAvoidArea`、`avoidAreaChange`、`keyboardHeightChange`；`@ohos.arkui.UIContext.d.ts` 有 `setKeyboardAvoidMode`。选与实际SDK/窗口模式相符的方案，核px/vp、surface实际resize与遮挡，避免重复扣键盘高度。文件URI按系统授权访问，不能当任意磁盘路径截取拼接。

## A. 有效可视区与真实caret reveal

把surface实际尺寸/原点/缩放、系统遮挡区域和accepted clip接到同一份可视事实。先实测当前默认resize/offset行为，再选择最小适配；不能同时缩surface又把同一键盘高度重复扣除。必要窗口事实桥保持窄接口、生命周期订阅与退订成对。

reveal按当前accepted caret或选择活动端的小矩形计算，不以整篇carrier的大bounds定位。键盘展开/收起、视口尺寸改变、连续输入换行和删除之后，正文与触点同坐标、活动端可见，标题/工具栏仍可达。保持阅读锚必须经过新排版映射；删掉一段后后文按正常流式布局上移，不保留已删除内容的旧像素占位。失效位置可等待有身份的新排版，但不能临时拿旧几何发新选择。

## B. 跨片段选择和统一提交

支持源码与可视面内跨多个段落的正反向选择、选区收缩、跨起点反转、替换/删除、Undo/Redo及免点击续写。选择只改交互状态，不能制造正文事务；替换/删除按原范围会话进入同一owner，逐意图精确一次（系统拆笔按现有逐笔范围/版本链核）。

先对照主树源选区与H既有票据/安装契约，复用实际可用公共机制，补缺处归CJGUI；Pharos只把两个显示端点和完整跨度经同一accepted SourceMap映成源范围，不独自持第二份选区。不能只删除 `selection_crosses_visual_fragments`。跨片段并不天然非法：当SourceMap可唯一解析完整跨度时应支持；transformed/embedded等真正歧义继续具名拒绝并保旧，必要时复用产品已有reveal/source体验。不能把Markdown显示D≠源M硬塞进仅支持D==M的直接映射接口。

锚点/活动端有同一文档及版本，UTF-8/UTF-16转换基于同一镜像及绝对sourceBase，保留方向与字素边界。框架把源选区投影到所有当前可见片段；源选择范围不因片段退场而被截断，滚出/滚入后的高亮按当前accepted布局恢复。普通竖滑仍是滚动；长按/已有选择手柄或已经胜出的选择手势再进入跨段扩展，不能把所有纵拖改成选字。

## C. 跨屏边缘驻留与滚动后立即编辑

复用共同viewport、活动注册、手势捕获与时钟。选择已经开始后，活动端进入可视边缘并保持不动，也要有界续滚；随距边缘的距离调整速度并封顶。每次滚动accepted后，固定同源文档锚、按新的geometry/clip/布局重算活动端，不拿旧scene票改号继续用。源/绑定变化按现有重基或取消契约处理，不一概取消所有正常滚动，也不无条件接受旧事件。

手指松开、取消、应用退场、换绑、窗口关闭都终结本次活动；旧tick不能覆盖下一次选择或显式reveal。停下后不再空转求解。拖选与惯性共用已有接管顺序，不在ArkTS页面另起永久timer。

跨屏选择后替换、连续删除、滚动往返后点击输入以及Agent非冲突改版后续写，owner、代理、caret、高亮和accepted正文始终对应；触及旧r31路径时只做受影响回归，不重做其来源/A2设计。

## D. 用户可打开并带走文档

通过系统文件选择入口导入一个UTF-8 Markdown/文本文件，限制 **262144 bytes**，外部原件只读，先有界读取/校验并建立唯一私有候选副本，现有服务成功打开后再切换当前文档。读取后仍核实际字节数，不能只信事前stat；取消、超限、编码非法、读取失败保留当前文档/历史/选区。已有脏文档先按保存或取消流程处置，不静默丢弃。选择器迟到结果不得覆盖已被新请求或新编辑取代的当前会话。

普通保存继续写私有工作副本；“导出副本”用既有固定版本字节，经系统选择的新目标写出，读回逐字节核对，后续正文变化不混进已冻结导出。导出不改变工作文件绑定，不调用saveAs把未来保存指向外部原件；失败不伪报成功，释放本次文件句柄，不碰未授权原文件。系统接口/提供者不支持原子替换时不要声称崩溃原子性，本包选择新目标即可；不是云盘或全文件管理工程。

UI按钮由CJGUI正常界面承载，ArkTS仅桥接系统picker与字节/结果；允许复用已有平台文件能力，不为两个入口建新的workspace服务。复制/剪切/粘贴菜单已有，复用同一版本/选区核验，勿重写剪贴板系统或覆盖用户原剪贴板做测试。

## E. 固定完成门与交付节奏

先快速打通一条多屏正常使用链，再围绕它补必要反例和性能，不先花整轮造工具。A/B/C互相接续，D可独立推进；由执行者安排工作，不逐文件/小绿点停工。普通问题先查技能和既有代码；用户已取消GLM咨询，不自动启动其他模型咨询或把咨询当开工门。根因不明时给区分实验，沿AGENTS累计失败规则只升级具体问题，独立工作继续；不能因换模型清零失败次数。

固定门只有以下五组，不逐轮扩成新的审核工程：

1. **框架反例：**键盘可视区换代、跨片段正反向/反转、边缘驻留无MOVE续滚、停止后旧tick、滚动accepted更新、owner外部换版失效。测试现有生产函数/真实公共路径；撤回关键修复能翻红，不复制影子算法。复用selection handles、scroll activity、reveal等现有套件。
2. **Pharos一条最终normal连续链：**系统导入多屏文件→源码查看/编辑→可视长按/选区拖柄跨至少三个真实片段→向下越边驻留并继续扩展→反向收缩/越过起点→单次替换→免点击续写→Undo/Redo→删除后后文上移→键盘展开/收起→滚动后立即输入→公开客户端非冲突改版→人继续输入→保存→正常关闭/新实例重开全文精确→导出新文件并读回全文精确。手工物理输入与uitest合成分别标记，不拿协议写入代替人类腿；公开客户端不是实际模型消费。
3. **独立普通消费者：**复用既有thermo，长备注/多个TEXT呈现片段连接同一note owner，实际消费相同可视区/reveal、跨片段选择及边缘活动，替换→Undo或等价原有历史能力→继续输入，主文档/其他字段零污染。不新建一套编辑器，不把Pharos备注或GET_CONTEXT算第二个UI消费者；若thermo无某业务动作，不为测试造第二套历史。
4. **真实反馈与成本：**保留一次含“按住微移、跨边静止、松手停、键盘变化”的短连续录屏或连续帧原件，记录采样条件；只拍终态不能证明过程无闪烁/丢高亮。至少20次输入/选择与若干冷/热滚动记录平台入队、owner和accepted反馈时刻、p50/p95/max、观察到的可见反馈、峰值RSS及停止后的活动计数；工具命令耗时单列。不把accepted提交称真实屏幕present，不用最终正确掩盖秒级挂起，不把整篇重排/永久轮询当实现。超过100ms的框架内部自然长尾须有负责阶段与处理结论，不能据此宣称整帧16ms或真机性能通过；新性能目标不无限扩旧95/355ms Mac问题。
5. **一次受影响汇合：**生产机制稳定后冻结源码，正式入口串行构建同源normal Pharos/thermo，保存HAP SHA/清单/安装启动及消费PID。完整owner字节、实际冻结范围、同源当前身份与必要帧要能复算；对未受影响r31保存/Unicode/来源/A2原证按影响复用，不机械再跑65腿或重造日志配对平台。归档失败/必需腿未验不能标整包完成。

保护E/W在途改动、用户窗口/文档/剪贴板、7856转发、stash与暂存；只清自己准确归属的临时实例与映射。未经要求不stage/commit/push/reset/stash/切分支。同target构建串行，设备不与其他执行者争用；已有授权内必要操作自主完成。任务末提供一个可启动正常包和简明操作路径，由用户直接体验；更新本页实施结果和ACTIVE，集中报告真实交付/剩余，不按每个补丁报“包完成”。


## 2026-10-08 指导复核与当前接续（优先于下方历史实施口径）

**原 A–E 包继续，未达到完成门。** 本次只读核对当前源码、run10/run18、冻结清单与判定器，未构建、测试或操作设备。保留 r31 与本包真实成果；以下是原目标的必要修正，不增加新阶段、模型咨询或审核工程。用户已取消 GLM 咨询，当前执行模型直接实施，不每修一处就停工。

### 原件可以证明什么

- **run10 的短链成功保留。** `health_pre_write=true`，两次 Undo 都是 `attempt0`，没有靠健康重启或多次 Undo 救绿；有跨段精确替换、恢复、滚动/Agent 后输入和保存后新实例读回。但起点是公开播种，尚缺系统导入、同手势驻留、Redo、替换后立即续写和导出，关闭用的是 force-stop。不得升级为 E2 原固定整链通过。
- **run18 只证明多次单步启动/停止。** 六次独立 longClick 中四次 engage 各有一条 `steps=1`，20–39ms 后 `capture_cleared`；stop 的 7/8/9/10 是累计 `edgeDwellStepCount`，不是同一手势多步。跨四次按压累计三步不等于一笔按住不动续滚；每次先重新聚焦并 Back 也不是用户正常拖选的闭合证据。先核真正 UP 与 capture 失效原因，不能直接归咎注入工具。
- **最终构建不等于最终消费。** `e5-freeze/freeze.json` 明列 run10/run18 来自旧 `dwell-probe-2`（HAP `9c7b4e64…`）；最终 Pharos `54f444b0…` 的 snapshot window 指纹由 `f5f10bde…` 变为 `4a7eff38…`。native 库相同不能替代上层同源。thermo reveal/驻留也尚未通过。
- **成本口径收窄。** `textLayoutsBuilt/textLayoutInputBytes` 是累计创建次数/输入工作量；排版对象已有销毁与帧租约，不能以每帧增长断言驻留泄漏。`verify_pharos_input_cost.py` 用动作前任意日志到后续首条任意 `accepted node=` 的时间差，未配 PID/输入/版本；592/856/886ms 不能作逐笔 accepted 延迟。229ms 保留为含注入与轮询的 owner 观察耗时；90 条 node 日志不是90帧。重新关联实际阶段再判断成本。
- **E1 未证明撤回敏感性。** 新 `composable_ui_keyboard_occlusion_reveal_test.cj` 手填正确 clip 并用整数 caret 调通用 planner，没有调用 H 生产 clip 构造或底沿取整；撤回 H 修复不必使它失败，且本轮未运行。所指 `e5-freeze/offline-suite.txt` 仅有 `failed:`，不足以复算74项；先查已有逐项原件，缺失才补必要检查，不推断74项必然失败。

### 先修 D：私有副本与迟到结果的真实安全缺口

源码入口：产品 `pharos_ohos_controller.cj::startDocumentIntent/applyDocumentIntentResult`、`pharos_ohos_document.cj::pharosOhosImportWorkingCopy/pharosOhosReadIntentResult`、`Index.ets::onDocumentIntent/writeIntentResult`。以下是源码可达风险，尚未设备复现，不应报成已发生的数据损失。

1. `requestSeq/importOrdinal` 随进程从0开始，结果文件 `r1.result.json` 不消费删除，导入目标 `pharos-mark-import-1.md` 用 `overwrite:true` 发布。重启再导入会复用旧名字；旧结果能被新请求读到，旧私有工作副本也可能被覆盖。副本写入还早于 `replaceDocument` 的 dirty 拒绝。
2. pending 未冻结发起时的文档/会话/owner版本，结果也未核请求身份；只查当前 dirty 不能阻止“选择器等待→Agent改版并保存→迟到结果切换新正文”。
3. host 超时仅清 pending；ArkTS 在 `await picker.save()` 后仍可打开/TRUNC 外部目标。不得把“回执不消费”写成“外部副作用已取消”。结果直接 TRUNC 写入也会暴露半份回执。

**实施方向：**复用现有文档意图通道与唯一 owner，用实例级唯一命名空间＋请求身份、action、发起文档/会话/版本形成有界待办。私有候选/工作副本唯一且排他创建，不覆盖旧工作文件；导入提交前复核冻结依据，拒绝时清本请求候选并保留当前状态。结构化回执带同一身份，原子发布后精确消费，发出失败、取消、退场各有一次终态及资源释放；晚结果不能重活。导出保留发起时冻结字节，后续合法正文编辑不混入导出；取消/替代必须在外部写入授权处与执行权交接，区分尚未开始与已进入写入，不能只在 await 后读一次 Bool 留竞态。桥接发出失败要归还/终结 pending，句柄与回调归属沿既有能力落实，不新建文件服务体系。

**必要反例：**重启后再导入不覆盖首份工作副本；旧 `r1` 回执不被新实例采纳；picker等待期间正文改版并保存后旧导入被拒且全文不变；取消/替代与picker迟到交错不启动失效写入；导出读回仍等于其冻结版本且工作绑定不变。用临时自有文件，不拿用户文档试覆盖。

### A/C 联合修复：有效视口、活动端与手势生命周期

**thermo 不是没有 caret。** host 已在 presentation 排版支路计算并绘制它，却只为 `isEditingNode` 发布 `editingCaretRect`，窗口 reveal 只读该出口。回框架让 source/presentation 共同 reveal 消费其已 accepted 活动端小矩形。不能仅放宽 if：现缓存只有 valid/node/top/bottom，渲染中写入、没有场景标签；复用既有排版租约/位置来源，携节点、绑定、scene及几何依据，在实际成功发布时交付，失败保旧或拒绝，换代拒旧。保持 D→M 与票据契约，禁止改为整 carrier bounds 或为 thermo 单写一个 reveal。

**驻留先定位失效链再改机制。** Pharos `commitVisualSelection` 每次标记恢复、重新请求焦点并推进 revision；共同 capture 默认关联 revision，可能被正常选择推进取消。这是待区分假设，不是已证根因。一次关联：同 GestureKey 的 BEGIN 接受→选择更新→哪处 need false→true→restore签发/ACK/采纳→哪条 capture 失效→是否真实 UP。按现有 Flutter `EdgeDraggingAutoScroller` 的“目标更新不重启、活动持续、滚动后重算”思路，保留跨正常 accepted 滚动的手势，重算当前活动端；真实 UP/取消/退场/绑定替换才按各自契约终结，不整体移除 scene/source 门。

键盘遮挡、surface/viewport、accepted clip 合成的有效可视带须同时供命中、reveal和边缘活动使用。修正常焦点进入与键盘展开下的工具栏可达，不将“先点正文→Back→再选”固化为必需仪式。长时间 IME 退化在首次失败的同实例上沿当前来源→安装→采纳→owner链定位；已有去重与截止机制先复用，不再以重启重播种作为产品修复。

**必要消费：**同一手势 DOWN→选择已胜出→边缘静止→至少多次滚动accepted/活动端扩展→UP→稳定停步→该冻结源跨度替换/Undo，期间无重聚焦、重复longClick或动作重投；反向及键盘变化沿同一机制。用当前SDK实际支持的持续触摸途径，能力限制与产品故障分开；缺真实保持输入时保留设备门未验，不能拼多个手势改名通过。thermo复用已有note owner与呈现节点接入这同一条链，其他字段零污染。

### E 有限收紧后一次收口

1. 原通过原件保留。最终验收每个用户意图只投递一次、有界等结算；去掉 Undo 三击及 L4 失败后覆盖原目录的重试。失败原件留下，诊断恢复另记，不能替代同实例连续成功。先补最短正常链，不先重造大型判定器。
2. 键盘反例调用生产构造/取整路径或抽取真实函数，加入非整数底沿与换版拒旧；在隔离副本撤回关键修复实际翻红。对74项先补可复核索引/原始退出码，不能用编译代运行。
3. 排版成本先按 same PID/scene/布局键核无正文变化时的重复创建来源；以当前存活租约/对象/当前RSS和峰值分别检验释放。沿现有缓存与失效责任修确证重复工作，不因累计计数增长另开“泄漏重构”。20笔成本用同输入/owner版本/accepted身份与同钟阶段事实；工具观察单列，可见反馈另证，原任务100ms内部自然长尾要求保留，不扩成Mac16ms攻坚。
4. 生产稳定后冻结一次，正式入口串行构建normal Pharos与thermo，在实际这两个HAP上跑原E2/E3。E2须含系统导入、驻留后的精确替换与免点击续写、Undo/Redo、键盘/滚动/Agent交错、保存、正常关闭新实例全文读回、导出精确；E3实际消费共同reveal/跨段/驻留。保留按住微移与边缘静止的连续过程画面，不能用几张终态截图证明不闪烁。
5. 完成后只更新本页与ACTIVE并集中交付正常包/启动路径/实际通过与剩余，不重开旧来源/A2/65腿，不把工具未验改成产品通过。保护E/W、用户实例/文档/剪贴板、转发、stash/暂存；未经要求不stage/commit/push。

### 2026-10-08 final6 正式汇合交付（模拟器范围自验完成）

原 A–E 完成门已由当前执行者连续自验通过，交付入口为 [final6 正常包与操作路径](../../artifacts/h-continuous-write-20261007/final6-20261008/delivery/README.md)，[机器汇合结果](../../artifacts/h-continuous-write-20261007/final6-20261008/final-gate.json)及完整原件在同目录。此结论不改写上面的指导复核原件或下方历史结果；r31按未受影响证据复用，run10仍是首过健康/首次Undo的短链，run18仍只证明多个独立单步，未重跑65腿。

**文件安全已闭合。** 实例/请求身份、私有排他候选/工作副本、完整身份原子回执与精确消费、发起文档/会话/版本核验、waiting→executing与waiting→cancelled争用均进入现有文档意图/owner路径。自有临时文件的重启重名、旧回执、编辑且保存后的迟到导入、取消与已执行结算、冻结导出及工作绑定重开反例已有生产RED/GREEN；取消胜出后 picker 迟到返回在写权限入口被拒，不继续host外部写入。生产导入另实跑262144B精确成功、262145B及非法UTF-8在候选创建前拒绝。正常保存只写私有工作副本，外部原件未用于覆盖测试；系统提供者的新目标写入不宣称崩溃原子替换。

**共同reveal与手势已闭合。** source/presentation使用带节点/绑定/scene/几何/owner身份的accepted活动端小矩形，成功Flush后才发布；有效可视带由surface、键盘和accepted clip共同取交。正常选择推进保留同源固定锚，accepted滚动后从当前排版重算活动端；真实取消、换绑、UP终结旧活动，来源及预算门保持。真实消费又揭示两条每帧重复focus通知路径与在活动捕获中重复发整份proxy restore，它们会阻塞反向MOVE；共同窗口仅在活动中保持原焦点/源pending，UP后恢复正常签发。随后thermo收键盘→普通点击反例揭示END回调期间捕获仍须保留以核源范围，却不能据此跳过重新聚焦；已加终态分发门，生产分支RED→GREEN、隔离撤回RED。没有另做thermo reveal，也没有放宽isEditingNode后消费无版本缓存。

**一次最终源码与双normal HAP。** final6冻结400项生产源，正式入口串行构建 `h-final6-continuous-pharos-20261008`、`h-final6-continuous-thermo-20261008`；两包实际编译的411项共同框架输入逐项相同，renderer同为 `b005d922…`。Pharos HAP=`a549066381476335a9d9b70931aef72d6397bfdbb414d053025b93ac0bf62b2d`，thermo HAP=`e19e8cc30234816a37794ea2d7034c46dfefff3aa826e96df99911b25500ab92`。正常安装/启动/消费身份与清单均保留，实际编译源码另按原清单校验并封存；`cjpm build --skip-script --target aarch64-linux-ohos`通过。构建、真实消费、正常包与采样视频分域记录，不再用native同库冒充同源上层。

**Pharos原固定完整链一次连续通过。** PID30421，系统导入自有23917B多屏文件→普通源码首焦点/20笔输入→预览可视跨16个真实片段选择→同一DOWN/UP手势下两个严格无native MOVE的1814ms/2583ms区间分别55/52次accepted重算、50/47个不同源范围→反向收缩/越过固定源锚24，UP冻结3:24→首次X替换→0.388s后免点击Y→首次一次Undo/一次Redo→一次删除2:90、原后文上移249vp→真实键盘隐藏/展开与正常滚动后Z→公开客户端Agent非冲突追加→免点击Q→GUI保存→正常recent-task关闭（无force-stop）→新PID32403全文精确→系统导出新目标并读回精确。最终23757B全文SHA=`e487afb7c5507d82bbe9332675b9f5aed6f7fe4ae5deabe75030860a0d18ba0e`，新实例/保存/导出一致，工作绑定不变。人类腿是uitest/SDK合成MMI输入，公开客户端腿不冒称实际模型消费；每个意图投递一次、有界观察，没有诊断恢复或重投救绿。

**thermo同机制实际通过。** 正式PID3437首轮普通焦点进入，31行备注跨多行选择；一次位置静止2480ms（uinput重复同坐标MOVE）有106次accepted重算，判定静态区间94个不同offset、5个扩展范围，真实UP后旧tick=0。UP冻结范围1:61、首次X得AX、免点击Y得AXY，温度/eco/范围/图片版本始终不变。共同reveal实际消费，键盘收起后一次普通点击重新展开、owner全文不变；现有thermo领域无Undo，本包未造第二套历史。66张连续帧覆盖导航、按住微移、静止、UP、替换/续写及键盘变化，采样间隔0.236–0.508s；Pharos29张连续帧约6.87s。按原采样时长拼接的视频保留所有原帧，不声称30fps采集或逐帧无闪烁。

**成本与资源结论有限且可复算。** 同PID30421的20笔均配 producer/dequeue、owner版本、accepted ticket/冻结paint；producer→paint p50/p95/max=67/72/75ms，dequeue→paint=60/66/66ms。工具=122.8/125.9/127.5ms，owner观察上界=182.1/188.6/190.4ms，截图可见反馈观察上界=288.0/337.8/347.0ms；内部paint身份不冒称物理屏幕present。按同当前活动及新scene/ticket配对的滚动样本：Pharos11个=15/28/28ms，thermo9个=12/13/13ms；首步、后续和反向回访均保留。内部输入没有本轮>100ms自然长尾，不搬入E的一般16ms/GB预算。峰值RSS581096KiB（约567.5MiB），静置574596→564560KiB，正常关闭前434524KiB；长正文始终1槽/9582单位，约4秒累计layouts+64/layoutBytes+576是小标签工作，caret不再重复排版长正文。正常关闭在同渲染线程释放最后5槽/759单位至0；thermo最后1槽/3单位也归零。累计工作量不能当泄漏证据，长时间RSS上界仍未证明。

**失败原件与保护。** final2/3真实反向事件阻塞、final4仅构建未消费、final5导出超120s后的安全拒写、final5第二轮只读version conflict中断后延迟续写都保留；后者虽未重发输入，仍不当立即续写成功。最终final6完整自动管线首过。新的观察器只在2秒内因具名version_conflict重取整个只读版本快照，不重发写意图。真实小数底沿生产构造/取整测试已运行、两修复隔离撤回翻红，原恢复/预算等受影响回归保留。用户旧bundle/PID23711、文件、E/W、转发与两仓stash/暂存保持；临时gesture工具卸载，thermo按准确PID正常关闭，Pharos正常交付实例回前台。无stage/commit/push/reset/stash/切分支。

本轮完成范围是当前模拟器、256KiB文件通道及多屏正常写作；23KiB正式视觉链不冒称256KiB视觉性能实测。真机性能/发布认证、长期RSS和一般16ms帧预算未据此通过；系统marked/cancel回调仍按已有SDK/镜像反例另列，旧独立task #12不改名关闭。

### 2026-10-08 执行接续历史（汇合前过程，现状见上方final6）

文件通道现已实现实例/请求唯一身份、排他私有副本、原子且精确消费回执、发起文档/会话/版本复核，以及 waiting→executing 与取消的原子争用；自有文件的重启重名、旧回执、编辑并保存后的迟到导入、取消交错反例已有 RED/GREEN 原件，见 `artifacts/h-continuous-write-20261007/safety-20261008/`。新工作绑定指针在成功导入后原子发布，正常 recent-task 关闭后新实例全文读回已按自有 31011B 副本实证；这是诊断版本证据，不能替代最终同版整链。导出另有自有 27908B 冻结版本真实系统 picker 写入/精确读回，第一次 picker 超时原件保留，没有覆盖重跑。

共同窗口已接 accepted 活动端带身份小矩形与可视带，生产小数底沿构造/取整反例运行通过且隔离撤回翻红。驻留按同 GestureKey/绑定在 accepted 滚动后重算，真实 UP/取消终结；`dwell-selection-superseded-ready-diagnostic` 单手势静止期间 184 次 accepted 滚动、9 次源选区扩展，UP 源范围 110:1337 与结算一致，首次 X、免点击 Y、一次 Undo、一次 Redo 均完整 owner 精确，但该版本画面尚无高亮，故不称可视门通过。

随后定位两处高亮接线缺失：H native 缺少共同 selection-background-only 装饰合同；Pharos 预览分支在准备当前 SourceMap 候选前读取绘制映射。针对性生产 RED/GREEN 和撤回负控已保留。正常 `h-selection-paint-20261008` 的连续帧终于显示真实跨段高亮，单手势静止期间 189 次 accepted 滚动/8 次扩展、UP 后停止；首次替换却被 `selection_native_alignment_required` 拒绝，失败原件保留于 `dwell-selection-paint-diagnostic`。旧代理非空回声改写待恢复源范围的生产反例 2 RED→5 PASS，隔离撤回 1 FAIL；原恢复采纳 31/31 保持。当前正在 normal 包验证此修复，判定器已改为等待带请求/owner/范围的窗口恢复终态，不能用 ADOPTED2 选区观测冒充恢复成功。

20 笔成本观察已收紧为同 PID、单输入、producer/dequeue、owner 与 accepted paint 关联，owned binding 与 accepted binding 分域核对，工具时间/观察上界/同钟阶段分列。新实际 20 笔、thermo 同共同机制、最终源码冻结和正式两 HAP 的原连续汇合仍待完成；不得升级诊断绿线为本包完成。

执行接续补充：`dwell-visible-cull-frozen-feedback-diagnostic`（PID2976）已显示真实跨段高亮，单手势静止 48 个 accepted offset/6 个源范围，窗口恢复终态与 UP 冻结范围一致；首次 X、免点击 Y、一次 Undo、一次 Redo、保存 23917B 均精确。此前 20 笔同 PID 关联的 native dequeue→冻结 paint feedback p95=71ms、max=77ms；该 paint 身份不冒充真实屏幕 present。停止时租约有界；累计工作仍揭示 caret 重绘重复排版长正文，现按完整布局条件借用原渲染线程唯一对象，成功 Flush 才转移，失败候选保旧；生产反例/隔离撤回与原预算 9/9 通过，最终同版 20 笔和同 PID 静置资源观察仍在执行。

thermo normal `h-thermo-source-extent-20261008`（PID8555）已在同一反向手势静止期持续 accepted 滚动/8 次范围扩展，真实 UP 后停步、首次 X 精确、免点击 Y 精确，其他字段不变；连续帧含微移、静止、UP 和后续键盘隐藏/展开。该消费暴露并修复透明 IME 代理抢触摸、共同 reveal 在活动捕获中夺走驻留，以及父 viewport 滚过独立 note 范围导致 UP 排版失效；修复均回共同框架/既有宿主路径，保留来源/预算门。旧失败与反向规范化判定器误判原件均保留。

首次正式冻结 `final-20261008` 未闭合：自有外部文件缺 `.md` 后缀，第一导入等待到期；另存导出准备后系统导入23917B实际成功（PID12430），但 `replaceDocument` 释放旧 range session 而未重绑新 bridge，首笔输入前读回 `no_session`，没有投递输入。生产路径已调用原 `rebindBodySession` 再请求焦点；真实函数反例 RED→PASS，隔离撤回 RED。旧冻结/原件不覆盖，新冻结 `final2-20261008` 正由正式入口构建并消费；双 HAP 原整链仍不能称完成。

## 实施状态（2026-10-07 执行者历史记录；结论以2026-10-08复核为准）

**A 键盘可视区与 caret reveal：设备 5/5 腿全绿（normal 包 run-id `caret-probe-3/4`）。**
- 实测事实：键盘展开时本窗口模式系统**不缩 surface、不移原点**（viewport 恒 1320×2622px、origin (0,137)、密度 3.5），仅底部覆盖；唯一事实源 = `getWindowAvoidArea(TYPE_KEYBOARD)` + `keyboardHeightChange`（ArkTS 上报，桥 napi→renderer 全局 → 窗口侧一次扣除，vp 换算用 surface 密度）。物理 caret 矩形由渲染器排版侧记录（编辑节点真值，presentation 支路不写），窗口按**真实 caret 小矩形**（不是整节点 bounds）规划。
- 首轮探针定位到真实缺陷：planner 的 clip 语义是「目标必须落在矩形内」，而键盘那段写成了键盘区域本身 → 变成「caret 必须在键盘里」→ 每帧 `reveal_unreachable`、永不滚动。修正为「底边=键盘顶、覆盖其上方全部空间」的一个矩形后，`plan=reveal_visible`（已可见，幂等不动）与 `plan=reveal_requested offsets=[11]` + `revealed=yes`（caret 底 514>502 时精确上滚）两条路径均在设备原件中成立。
- caret 底用 ceil：真实底沿是浮点，向下取整会把最后 1vp 留在键盘下（实测 514.0 被写成 513 → 只滚 11）。
- 设备腿（`runtime/cjgui/platforms/ohos/scripts/verify_pharos_keyboard_caret.py`，证据 `artifacts/h-continuous-write-20261007/a-keyboard/probe-4/`）：A1 点击出现 caret；A2 连续换行 7 次 caret 逐行下移、越过键盘顶时由 reveal 保持可见；A3 连续退格文本上移、caret 仍可见；A5 文档末端换行（尾部余量场景）仍可见；A4 系统 Back 收起键盘（overlay→-1，进程不变）再点编辑器展开，caret 可见。

**B 跨片段选择：设备全绿。** 产品 `commitVisualSelection` 移除单片段包含预拒，完整显示跨度经同一 accepted SourceMap 一次解析（transformed/embedded 内部端点仍具名拒绝）。设备证据 `artifacts/h-continuous-write-20261007/cross-fragment-b1/cross-fragment.json`：正向拖选跨片段 1000→1002（冻结源域跨度含段落分隔符）、单注入 'X' 精确替换（版本恰 +1、逐字节 oracle）、Undo 精确复原；反向（锚在后焦点在前）同判据全绿。normal 包 run-id `pharos-continuous-write-b1`。

**C 边缘驻留：框架接线完成、构建绿；设备上快滑=滚动已验，驻留 engage 未复现（如实记录）。** 借鉴 Flutter `EdgeDraggingAutoScroller` 的状态归属（活动属视口、时钟驱动、滚动后重算），实现于共同窗口：`evalEdgeDwell/stepEdgeDwell/stopEdgeDwell`（身份=捕获手势 epoch+绑定；`stepWindowActivities` 单入口推进，交付一帧新 accepted 后合成同坐标 UPDATE 让产品用新几何重算；捕获替换/节点退役/容器换绑/越出边缘带/offset 上限/步数上界全部终结；无永久 timer）。另加 presentation TEXT **长按 400ms → 指针拖动选择**入口（泵时钟触发，零位移采样也成立；普通竖滑仍走视口接管）。
- 设备腿 `verify_pharos_edge_dwell.py`（`artifacts/h-continuous-write-20261007/c-edge-dwell/run7/`）：**C1 快滑=滚动全绿**（可见块顶推移、正文逐字节不变、无冻结选区）。**C2 未绿**：用 `uinput -T`（真实按下/移动/边缘保持 1.8s/松手，正常 Pharos run-id `dwell-probe-2`）复现时，原件里出现 `presentation long-press selection stream open node=1004` 与 `gesture scroll takeover viewport=311`，但驻留的 engage 日志一条未出——驻留钩子挂在**指针分发尾部且要求该 BEGIN 已被产品接受**（`applyUiEvent.didApply` 才建立 capture 并调用 `evalEdgeDwell`），合成序列在该起手上未建立 capture，故驻留从未被评估。已补的限流 reject 日志（`CJGUI_EDGE_DWELL stage=reject …`）也一条未出，反证是钩子未被调用而非条件不满足。下一步具名：在 BEGIN 路径记录 `didApply` 与 capture 结果，再对齐合成手势（或改用与 B 腿相同的手势族）重跑。
- 本轮顺带发现两处设备事实（未修，供指导判断）：① **键盘展开时工具栏行的点击不生效**（同一坐标收起键盘后可切换模式）——A 的“工具栏可达”仍需定位；② 渲染器每帧 `layouts/layoutBytes` 单调增长（+9 项≈+3KB/帧，seq 165 时 1508 项/514KB），疑似无界累积，需单独定位。

**D 导入工作副本 / 导出文件：两条腿设备全通（normal 包，真实系统 picker）。**
- 通道：框架桥新增通用「文档意图」threadsafe 通道（`registerDocumentIntent` + renderer 侧 sink/emitter，仿焦点 sink 分层；product 编辑不落入被同步覆盖的桥副本）。
- 导入：CJGUI「导入」按钮 → owner 循环发意图 → ArkTS `DocumentViewPicker.select` → 有界读取 → 私有暂存 → 结果文件回执 → 产品 `pharosOhosImportWorkingCopy`（事前 stat+读后实际字节双查、严格 UTF-8、`.candidate` rename 发布）→ 现有服务打开 → `replaceDocument` 切换（脏文档拒绝）。原件：`emit=1 {"action":"import"...}` → `doc intent import staged bytes=104` → `DOCUMENT_INTENT result=import status=switched bytes=104`，私有工作副本 `pharos-mark-import-1.md` 落盘。
- 导出：`readWholeCurrentVersion(256KiB)` 冻结字节 → 私有暂存 → `DocumentViewPicker.save`（默认名 pharos-mark.md）→ 写目标 → **读回逐字节核对**。原件：`DOCUMENT_INTENT result=export status=exported readback_exact=true`（104B 与冻结版逐字节相等）。
- 超时取消：选择器被系统 UI 关闭而无回执时，宿主循环按 120s 截止具名取消（迟到结果不再被消费，当前文档不受影响）。

**E2 连续链：设备全绿（同一次会话，9/9 腿，normal Pharos）。** 驱动器 `runtime/cjgui/platforms/ohos/scripts/verify_pharos_continuous_chain.py`，原件 `artifacts/h-continuous-write-20261007/e2-chain/run10/`（`continuous_chain.json` + 内嵌 6/6 的跨段判定器 `l4-crossfragment/`）：L0 公开通道播种多屏夹具（2971B）→ L1 基线逐字节一致 → L2 IME 单笔输入（版本恰 +1、逐字节 oracle）→ L3 键盘展开下连续换行（caret 底 502.0vp == 键盘顶 502.0vp，退格后正文复原）→ L5 滚动往返后立即输入（落点绝对源字节精确）→ L6 公开 Agent 追加段落后人继续输入（追加与续写均逐字节精确）→ L4 跨段落选择/替换/Undo（正向 [123,293)、反向 [123,276) 冻结源域均跨段落分隔符，两次替换版本各 +1、Undo 逐字节复原；内嵌判定器 6/6）→ L7 保存 → 工作文件落盘逐字节一致（3070B）→ 强制重启新实例重开全文一致（sha256 前缀 `5bbfdb6581861bee`）。
- 链的工具链前置（设备实测，已写进驱动）：工具栏行点击在**键盘展开时不生效**（撤销腿因此先收起键盘再点，最多 3 次并以 owner 状态推进判定）；实例长时间编辑后 IME 会退化到不再落地，链头与链尾各做一次「健康检查，失败即重启并重播种」。
- 尚未接进同一趟链的：系统 picker 的导入/导出两腿（D 段已各自设备验证：`status=switched bytes=104` / `readback_exact=true`），以及 §5.4 的连续画面原件与 §5.5 的 ≥20 笔成本统计（E4 进行中）。

**E1 反例（离线+设备原件）**：框架离线套件在本轮冻结源上 **74 PASS / 0 FAIL**（13 个触设备条目按旧例排除，`e5-freeze/offline-suite.txt`）。新增离线几何反例 `runtime/cjgui/src/composable_ui_keyboard_occlusion_reveal_test.cj`：把「键盘以上可见区」与「键盘区域本身」两种 clip 形状的判别固定下来（后者在正确输入下也只得到 `reveal_unreachable`），并把 caret 底沿 ceil 的取整规则写进断言——撤回 A 的修复即翻红；该文件随包编译通过，运行需 native 测试桩变体（`CJGUI_INTERNAL_RENDERER_TESTING`，本轮未构建）。设备级反例以原件成对呈现：键盘遮挡变化（probe-1/2 的 `reveal_unreachable` vs probe-3/4 的 `reveal_visible`/`reveal_requested offsets=[11] revealed=yes`）、跨段正反向选择（`cross-fragment-b1`、`e2-chain/run10` 内嵌 6/6）、边缘静止续滚与停止后旧 tick（`c-edge-dwell/run18`：engage/step 的 `waitVersion` 接受门 + 松手 `capture_cleared` 后目标段顶 263 三轮稳定）、滚动换帧与 owner 改版（E2 的 L5/L6 逐字节 oracle）。

**E4 成本与画面**：`verify_pharos_input_cost.py`（`e4-cost/run1/`）20 笔输入采样——工具注入 p95 187ms；owner 版本推进 p50/p95/max = 190/229/246ms；设备时钟差（accepted 行）p50/p95/max = 592/856/886ms；进程 RSS HWM 248→281MB；**停止后 3s 静置窗口仍有 90 条 accepted 行**（掷闪重提整帧的既有事实，与 layouts 增长同源，记为待定位）。连续画面原件：`e4-cost/run2-process/dwell_process.mp4`（10 帧：起态→键盘展开→收起→三次带内按压各带落定帧）。

**E5 冻结与串行汇合**：`e5-freeze/freeze.json` 记录平台指纹、14 个关键源文件哈希、git HEAD；正式入口串行构建同源 normal 双宿主——Pharos `h-final-pharos`（HAP sha256 `54f444b0…`，launch pid 16323，bundle `com.pharos.mark`）、thermo `h-final-thermo`（HAP sha256 `8146ba46…`，launch pid 17563，bundle `com.example.cjguithermo`），源码清单在 `labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/<run-id>/source_manifest_*.txt`。

**E3 thermo 独立消费（部分）**：`verify_thermo_shared_mechanism.py`（`e3-thermo/shared2/`）在 thermo（独立安装、normal 构建）上验证：公开 `SET_NOTE` 长备注（60 标量，逐字节 + 版本恰 +1）→ 备注 presentation 点选安装（`ime proxy restore notification` + `ime selection observation forwarded`，共享会话/恢复链）→ IME 输入（精确一次插入差分 oracle + 版本恰 +1）→ `targetTemp`/`eco` 全程不变（零污染）。**未过**：reveal（thermo 备注走 presentation 上下文，渲染器按设计不写编辑真值 caret → reveal 链无 caret 可消费，属具名缺口）与边缘驻留（无法程序化地把可交互 presentation 文本放进可见带边缘；备注当前 `clip` 高 0 需先滚入视口，滚动手势与 presentation 选择互相争用）。姿态：选择/会话/owner 三类共享机制在 thermo 上消费成立；reveal 与边缘活动两条待补。

**最终构建复核（run-id `pharos-continuous-write-e2`）**：D 接线与窄档工具行（6 按钮：保存/撤销/重做/导入/导出/预览）修正后，B 跨片段验证器重跑 **6/6 全绿**（正向 1000→1002 跨段冻结 [1,42)、反向 [2,42)，替换/Undo 逐字节精确；证据 `artifacts/h-continuous-write-20261007/cross-fragment-final/`）。受影响离线套件（真实帧预算 9、命中失效 2、租约溢出 1）同源全绿。D 两条腿的设备原件来自同一 D 线构建（hilog `PHAROS_OHOS_DOC_INTENT`/`DOCUMENT_SWITCHED`/`readback_exact=true`，结果文件 `pharos-doc-intent/r1.result.json`）；用户空间 Documents 已由导出腿落盘 `pharos-mark.md`（104B），可作为后续导入腿的种子文件。多屏夹具（2971B/25 段）已备于 `/tmp/continuous-writing-fixture.md`，E2 链路应经“公开通道写入→保存→导出到用户空间→导入”建立的工作副本进行。
