# Windows Pharos 编辑器整包接续（2026-10-05）

**框架与产品责任校准（2026-10-06）。** 本包同时负责CJGUI Windows后端和现有Pharos消费，不是只把编辑器在来宾中跑起来。窗口/消息泵/线程/输入来源/安装交接/排版命中/GPU与文件平台语义归框架后端；平台无关的选择、owner、布局及资源契约优先复用CJGUI公共核心，发现公共缺口应沿真实责任层修复。产品只留文档与Markdown语义和声明式接线，不能复制公共机制或用慢打、重投绕过框架缺陷。保护E/H写集是禁止覆盖并行工作，不是禁止本包必要的公共框架修改；先核现有契约与diff，按最小影响实施并验证相关调用兼容。按原整包连续完成，不以单个探针或构建修复结束；报告分别列框架机制、平台适配、产品接线及正常消费依据。本条仅澄清原范围，不恢复已暂停线程。

本包已于2026-10-09完成，范围与边界见本页[r6原A–F交付](#windows-r6-final-delivery-20261009)。下方r5x/r5i与早期指导均保留为历史，不恢复已修事项或旧咨询要求。用户请求的[下一包R7](2026-10-09-windows-bounded-preparation.md)推进Windows通用有界准备与8MiB正常写作，只有用户交给执行者后启动；指导不代替执行者开发或自动操作虚拟机。

**交付目标：让现有 Pharos Mark 在 Windows 上完成正常写作链：打开文档 → 源码编辑 → Markdown 预览 → 回到原选区继续编辑 → 公开 Agent 修改 → 人继续输入 → 撤销／重做 → 保存 → 关闭重开。** 使用现有编辑器检验 Windows 后端；设置、thermo 或另写一个玩具编辑器不作为前置交付。

这是一包连续实施任务，包含必要旧问题、Windows 后端和产品消费。内部按依赖安排工作，最后集中报告；不要每完成一个探针就停止询问是否继续。不能把“编译出窗口／画出文字”改称整包完成，也不承诺一个夜间就达到 macOS 全部能力。

<a id="windows-r5x-closeout-guidance-20261009"></a>
## r5x 三项失败的具体指导与原包收尾（2026-10-09，历史指导；已由r6完成）

**阶段判断：继续完成原 Windows Pharos A–F，不另开移植或工具工程。** 小文档正常链已经成立，接下来优先补齐 Windows 后端对公共提交、输入和准备协议的消费，再完成剩余正常交互与交付。范围仍为原有 256KiB UTF-8，不加入 Mac E 的 1GiB/16ms 大包、UIA 全能力或新编辑器。用户恢复执行后按下列方案连续实现、自验和收尾，不逐补丁请示；本节明确解除三项旧失败的“等待指导方案”阻塞，但没有替它们宣布通过。无自动 Pi/GLM 或其他顾问调用。

### 已核对的当前事实与复用边界

- 指导实际读取候选 ZIP，EXE SHA 为 `9497b7ca90a7e2ae686ad88e794de49ebb1f045e974029c193427a644bf51e0e`；独立源码构建 `cdd740d0…` 的身份与正常链原件仍分开保留。最终 12 门见下方 [r5x 交付](#windows-r5x-final-delivery-20261008)，不把旧轮复用项说成最终 EXE 全重跑。
- 正典 Windows native 与交付源逐字同 SHA `b50509389f48fd022cba83ce612eb78ab8b1a409e25ab5243aa9c7d02c595537`。共同窗口交付源为 `8004f3c3…`，live 已为 `f73b8861…`：**定位 r5x 先读其冻结源，移植修复再核 live 差异**，不把 E/H 当前代码当成旧 EXE 已具有的行为，不整棵覆盖。
- Shift 失败沿用 r5k/r5l；设备首输入失败沿用 r5u `bc3c88005df141b28b6ab6c7140dc3d4`，并非 r5x 新跑出的两条故障。近上限 `07fb8431f12b4c539a115af8df18877d` 是 r5x 真实失败：252000B、单次 28 个 SendInput 记录、原 2500ms 窗，实际观察 2524.5845ms 未完成、预期 v14 而当时 v13/12笔。另一次原件在全文读取中才推进最后一笔，故目前首先是**原预算内未完成**，不能据此断言最后字符永久丢失。
- 平台无关 owner/范围选择/方向/FIFO/恢复完成发布继续用 CJGUI 与现有 Pharos；Windows 只接 Win32、DWrite/D3D、系统 IME 和文件适配。复用 macOS 的公共协议及责任划分，不复制 AppKit 对象或产品补丁。外部实现仅作只读参考，不引入依赖。

### 一、设备恢复：先关闭已经查实的提交协议漏口

**源码确定缺口，不再只猜 13:13/14:14。** `cjgui_windows_renderer.c::present_composable_scene_impl` 在 DXGI device-lost 后调用 `recover_graphics`，随后返回 `PRESENT_PENDING`；没有产生有效 ticket。外层 `cjgui_internal_renderer_present_composable_scene` 只在 OK 时复制 observation，PENDING 也不会把凭据带回。`query_present_impl` 恒返回 decision NONE、`acknowledge_present_impl` 对非零票恒回 SCENE_STALE，尚无真实待决协议。r5x 共同窗口 `recordPendingTransaction` 明确要求非零 ticket；零票只记 `present_pending_without_ticket` 并返回，未登记可结算事务。它与后续 `identity_candidate_already_open` 形成具体可检验链，不能靠 force-clear candidate 或放宽输入 prefix 门消掉症状。

**指导选定的优先实现：当前同步 Present 的失败候选走明确拒绝，设备恢复另行有界推进。** DXGI 已明确未接受这一帧时，返回现有可解释的非 PENDING 失败，使共同 `rejectParticipantCandidate` 正常 discard native candidate、rollback participant/identity/layout，旧 accepted/owner 保留；设备重建和旧 accepted 重绘归 UI dispatcher，恢复就绪用现有唤醒/刷新机制产生下一候选。不为一个已知失败的同步帧先建新票据系统，不整段阻塞 UI 重试。必须核对所有对外 Present 路径：内部资源等待不等于对核心声明“已有待决提交”；COMMAND_IN_FLIGHT/超时且提交结果未知不能强判拒绝；已接受帧不可回滚。若实际发现存在不可取消的异步提交，才沿已有 Query/Acknowledge 接口补齐真实唯一票据、终态持留及 ACK，只在这条路径采用 PENDING。禁止伪票、返回 OK 冒充画面、零票自动重试或直接重置 identityRegistry。

设备 GPU 代次、场景候选、文本 owner/安装来源要分开：重建纹理不能擅自重置文档/选区或给旧输入换来源；确实失效的安装需走已有共同恢复并保留待决输入，真实回执之后才放行，旧来源仍拒绝。当前失败用例还连续做了 Agent `[G]`、resize、minimize/restore，且只看到 session selection 就发送 A，**它既不是 GPU 单因素实验，也不能通过加睡眠修好**。

执行顺序：先以真实 native Present＋共同窗口入口形成“设备失败→候选回滚一次→可开始下一候选”的确定性 RED/GREEN；再做三个有界对照：仅恢复设备；仅 Agent/resize/minrestore 而不丢设备；原复合动作。三者分别保留同实例 owner 全文/版本、candidate 开始终态、安装 request/nonce/ctx/gen/base/seq 和第一笔 A。首输入只投一次；将 `installed_range_prefix_mismatch` 第一个不等字段具名记录，区分恢复请求落点、真实回执与本笔来源，不把 seq0 本身解释成用户未输入。原复合固定门仍须通过，两个对照不能替代它；失败保旧、恢复中关闭、旧设备迟到回调拒绝及正常路径作受影响反例。仅在同一次结果证明还有第二处失配时再修对应责任层。

参考：共同窗口 `beginPendingTransaction/recordPendingTransaction/settlePendingPresent/rejectParticipantCandidate`；本地 Zed `crates/gpui_windows/src/directx_renderer.rs::handle_device_lost_impl` 的 GPU 资源重建与文档分离。GPUI 的 skip-draw 返回值不是 CJGUI Accepted 协议，不可照搬为 OK。

### 二、Shift：先证明发的是哪个键，随后才检查共同扩选

旧 `213d296ffff84305badabbec16631610` 原消息显示 Shift-down 后、Left-down 前多出 Shift-up，Left 捕获 flags=0。普通 r5l 日志 REQ6 已安装，随后是 25:25→24:24→23:23，并无新恢复覆盖。现 WndProc 捕获 GetKeyState、raw FIFO、延期回放已经保留 modifiers；共同窗口有 ExtendLeft，text_session 固定 anchor 移动 focus。**没有依据先改公共锚点或把 Shift 粘住。**

`writing-r5l.ps1` 的 KeyDown/KeyUp 和独立 probe 均用 wScan=0，Left/Home 没有 EXTENDEDKEY。优先区分独立方向键与数字小键盘导航身份。微软 [KEYBDINPUT](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-keybdinput) 与 [键盘消息规范](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input) 明确区分 scan/extended；这目前是**待验证的投递器假设**，不是已证实 NumLock 根因。旧 scans 对照未归档最终 INPUT/到达 scan，不能作已排除依据。

保持原单次动作及断言，做一次明确独立导航键身份的对照：记录 INPUT vk/scan/flags/extraInfo、HKL/NumLock、目标 HWND/TID，与到达 WM_KEY lParam/extraInfo、冻结 modifiers、raw dequeue、共同 intent 配对。不要改全局 NumLock 或替用户释放未知按键。若改正投递身份后成立，只修工具；若冻结 Shift 正确但共同层生成折叠选区，才修首个断点。再用“Shift+Left 捕获后立即松 Shift，延后消费”确定性例证明消费不读最新键态；Unicode 夹具 caret27 的三笔应保持 anchor27、focus25→24→23，owner/version/journal 零写，补反向收缩、跨 anchor 翻转与精确替换。不得用公开设选区替代真实 Shift 验收。

参考：共同窗口 `dispatchNavigationIntent`/ExtendLeft 路由、`text_session` 方向选择与安装确认；macOS selector 将 modifySelection 冻结成共同 intent；本地 GPUI Windows `events.rs` 事件构造时捕获修饰状态。参考读取止于相关机制与测试，不再通读整套框架。

### 三、252000B：优化真实场景准备，保留原 2500ms 负载

**已核实的能力边界：** Windows `begin/prepare/advance/promote_composable_preparation_impl` 都仍返回 TEXT_SERVICE_UNSUPPORTED。r5x 新增的是有界异步尺寸测量，实际 `prepare_scene_node_text` 仍在 UI dispatcher 同步调用 `create_styled_text_layout` 及 raster；共同候选可退回同步路径。文本变一笔就不能靠“相同全文指纹命中”复用原布局。因此“Windows 已异步排版”不能当完整结论；但没有分段计时前也不能断言这解释了全部 2500ms。

先复用现有 owner/workload/dispatcher 时钟，在一次原252000B recipe上关联原事件序号，分开原始FIFO等待、owner提交、共同build/prepare、UI派发等待、UTF转换/复制、DWrite布局、raster/upload、Present、安装ACK与下一笔放行。每笔记录实际处理字节/节点数与缓存命中；限量内存记录或批量落盘，不加每字符同步刷盘。标明20笔时延、单次burst终态预算和屏幕呈现三种口径，禁止拿GPU编码结束冒充已显示。

根据该次关键路径集中实施一组方案：

1. 若同步布局/raster是主要成本，接通既有共同 preparation 接口的 Windows 实现。复用 macOS `CjguiPrepareComposableNodeOnMain/CjguiAdvanceComposablePreparationOnMain` 和共同 packet 的冻结输入、预算推进、取消、旧accepted保留、同票提升语义；DWrite资源按自己的线程/COM归属实现，不传 AppKit 对象。有界不可变输入、固定工作容量、关闭/取消能释放，GPU资源操作仍归原UI线程，generation/DPI/正文/runs/约束齐全才晋升。不得仅把原大调用包进任务而保留UI同步等待，不能后台完成就先发布输入资格。
2. 若队列串行往返或每笔重复全镜像复制主导，修对应公共调度/平台封送与既有保留候选复用；只合并可丢弃的未发布画面请求，不合并或丢弃 owner 编辑意图。真实内容变化不能借旧layout当有效，字体/Unicode/命中/裁剪仍同源。选择最小受测方案，不预先重写整个渲染器。
3. 若时间落在系统等待/Present，定位具体调用与前后队列再处理，不直接归咎虚拟机、不关vsync凑数、不从总墙钟中扣去等待。不把 Mac 的16ms硬塞进本包，也不放宽本包原2500ms。

必要反例包括准备中版本推进/取消/关闭/设备代次变化、失败保旧及缓存输入变异；正常消费者仍为当前 Pharos，借已有普通范围消费者验证共享改动，不另造应用。最终252000B原recipe单次投递、原预算内全部13笔，逐笔版本/范围/合法前缀与固定终态全文同时通过。容量仍按UTF-8字节，256KiB边界及超限拒绝遵循原契约，不裁文档、缩夹具、慢打或事后journal重放救绿。

### 四、执行顺序、剩余原门与交付

1. 一次核冻结源与live差异，先修 Shift 投递观测小门和设备确定性协议反例；长文档分段测量可独立推进。之后实施上述责任层修复，针对性验证后合成同一 normal 构建。不要每个日志字段都花一次完整仓颉重编；仅 native C 改且实际BC、ABI和构建参数一致才复用已核COFF。共同仓颉改动确有必要就按正式capture→Mac llc→relay重建，不以编译昂贵为由在产品造旁路。SDK原件/互斥/finally与真实build退出码继续保持。
2. 构建源先冻结，保存具体文件manifest；canonical最小修复与隔离输入一一对应，E/H漂移只报告和按影响处理，不偷带整树新改动、不覆盖他人。同target构建串行。复用已有持久worker与这台Parallels来宾，不反复prlctl exec堆控制台、不新装SDK/系统。已交付用户候选保留到新包替换验证完成。
3. 同一最终EXE/default1100×780完成小文档全写作链、以上三门、源码内部远处滚动后点击/选择/立即输入、预览返源选区和焦点即时画面。输入机制变更要回归真实系统IME提交/取消，Unicode注入与IME证据分开；维持原PNG/设备/20请求重叠/正常关闭重开等固定12门，旧未受影响证据明确版本复用，不机械重跑全部历史探针。
4. 句柄先分归属：当前580相对514–518是worker数据，358→367是另一editor短样本，不能合并成编辑器泄漏。以同一worker/PID基线、等量任务和同一editor开关/焦点循环，等待真实任务/图形完成后分类型核增量；有界缓存、延迟释放与每轮线性遗留分开。若持续累积，修真正创建/释放责任；按准确PID清自有资源，不能通过重启worker抹增长。
5. 最终保留一套实际可复现构建配方和含空格源码包、正常可启动包、快捷方式及启动文档。清楚说明relay构建与普通脚本build分支是否实跑，不能把VerifyOnly当build；应用zip内EXE、消费PID、源码清单及日志同源。同包完成后集中更新本页、ACTIVE W段和原INDEX，报告框架/后端/产品/工具各改什么、真实门及剩余，不以候选可启动代替A–F完成。

本轮指导仅做源码/归档/本地参考与微软规范核对，并修改本页和ACTIVE W段；未运行来宾、窗口、构建或生产测试。上述方向由当前执行者在用户恢复后实施；新证据否定假设时按首个断点修正方案，独立工作继续，不能换模型重置失败累计或把需指导当默认咨询授权。

<a id="windows-r5i-d-ruling-20261008"></a>
## r5i D 指导裁决：补齐保留候选配对，随后直接完成正常写作（2026-10-08，历史裁决）

**裁决：同意在 Present 绘制编码前，把本候选 pending runs 与本候选最终正文和有效绑定共同校验、准备；这是补齐既有公共契约，不是放宽门。** D 不再等待第二次指导确认。执行者在用户恢复任务后按以下有限方案连续实施原包；指导此次只读源码/原件并更新文档，没有构建、运行来宾或修改生产。

### 事实、复用关系与当前断点

本次正典native SHA仍为 `39b535f1d39085feaa92f39d31be5f6237ef56499d1a97313f22834666f70f62`，与r5i冻结一致；新EXE `be754458…` 尚未正常应用消费。原反例 `f9efa3b34d3b4f20820d034cba3b5749` 的归档标准输出确为 `REUSED_RUNS_PRESENT status=33 pending=1 accepted=1`，不是单凭摘要推定。

Windows已经复用同一套Pharos `document_core / app_services / markdown_engine / editor_surface`、产品 `main.cj` 与CJGUI公共窗口/范围会话；r5i清单列出了实际输入。继续复用这些责任层，不另写Windows编辑器，也不把Mac在途整棵源码复制过来。Windows自身负责线程/消息、DWrite/D3D、系统输入与文件适配。下一优先级是让现有共同能力在正常Windows窗口完整兑现，暂不扩GB、UIA或新控件包。

共同窗口 `composable_ui_window.cj::submitPreparedCandidate` 的configure→runs→选择性node setter序列明确允许跳过未变正文；`sameLayoutNode`核正文及身份，`applyNativeTextStyleRuns`仍重发声明，包括空runs清除旧装饰。macOS `CjguiConfigureComposableSceneOnMain`保留旧节点，`CjguiComposableValidateSelectionBackgroundRuns`先验wire、`CjguiPrepareComposableTextResources`再对最终staged正文验范围，成功后晋升。复用这一时序和所有权，不照搬其ObjC对象或selection-only解析器，也不把macOS setter直接修改可达节点的做法移入Windows accepted快照。

Windows `scene_configure`克隆accepted并将`candidateValueStaged=0`；`set_composable_text_runs_impl`因此只验wire并置pending；共享层合法省略正文后，`present_composable_scene_impl`把pending一律判33。修早期runs对旧短正文误验时，漏接了“本候选合法保留正文”这一支。不能通过configure把所有value标成已stage、强制产品每帧重发全文或清pending恢复通过。

### 有限实施方案

1. 在现有UI dispatcher归属内增加一个私有候选准备步骤；位于`begin_text_flight`及Clear/Draw/实际Present之前。只消费本configure代的runs声明、本candidate最终节点和已提交geometry。新正文已明确stage的现有路径保留；runs先于新正文时继续只验格式，直到同候选正文可用才验跨度。
2. 对省略正文的保留路径，合法依据来自configure时保留的节点身份与正文。核nodeId/resourceId/nodeKind/acceptedBindingEpoch及现有bindingKey等真实身份，防独立semantic setter换绑后借旧正文；不得在Present读最新accepted或IME/current owner补来源。使用现有身份定义，不把semanticLabel、parentRowKey等展示/层级元数据全体memcmp成输入身份；同绑定仅改说明文字应正常复用。新绑定若同候选明确stage了新正文（即使字节相同），应可按新候选正常验证。
3. 使用临时节点，参照现setter的clone→装runs→范围/预算校验→`prepare_scene_node_text`→成功换入candidate。`clone_scene_node`会清`hasGeometry`，此处须保留当前候选已提交geometry及其资格；不得重用上代几何完成标记。内存、纹理、声明和引用计数由原责任层管理，准备失败不得更改accepted；部分候选准备成功也不能提前发布场景或输入资格。
4. 原runs范围、Unicode边界、节点完整性、预算、graphics失败门保持；空runs是有效清除，非“没有声明”。声明跨configure退役，不能借旧代按nodeId拼接。重复相同输入继续复用layout/lease；几何位置改变但排版约束不变不必换文字lease；字体/约束/DPI/正文真实变化按现规则失效，节点纯颜色更新实际像素。缓存命中不授予旧来源输入权。
5. 不新增公共ABI或新渲染协议来解决这条已具足够信息的接线。需临时诊断时只报本候选首次失败字段/状态，默认关闭。若现有private结构需要保存保留身份，做最小有界字段；不要再改90个dispatcher API。

本地参考已定向核对GPUI `text_system.rs::layout_line`：以完整text/font-runs/font-size/约束构成布局输入，装饰与字体规则分别处理。此处借鉴完整输入再准备和缓存归属，不把该API当成CJGUI候选协议，也不引入依赖。

### 仅补这一组区分门，然后回产品

在现有真实renderer probe内补齐，不新造验证框架：

- 原 `abc + [0,3)`→重复runs＋geometry、省略正文：成功晋升下一scene，layout/lease保持。
- 重复非空runs改空：旧样式实际清除；`abc`→`abcdef`且`[0,6)`先于新正文仍通过；逆序也按同一候选成立。
- 保留正文上的真越界/非法边界：拒绝、accepted版本/正文/有效布局保持。
- 仅semanticLabel变化的保留正控；bindingKey或真实身份变化且未stage正文的负控；同候选新绑定＋显式正文的正控。
- 位置移动/同输入保lease、字体/宽度/DPI真失效，复用原门；准备失败或候选弃置不污染accepted，后续合法候选可成功，无重复资源发布。
- 撤回这次配对步骤使原重复runs反例重新RED；撤掉范围/身份门能被对应负控抓住。测试不得手填“已配对成功”状态跳过生产调用。

这组通过后立刻重链接，先在默认1100×780的同一正常Pharos跑源码focus→连续ASCII/CJK/emoji→中段非空→预览→无编辑返回→免点击替换→Undo/Redo→公开Agent→人续写→保存→正常关闭→新PID精确重开。不要再用数轮独立探针替代这条主链。之后完成原第六节未验的系统IME、生命周期/受控设备恢复、20笔重叠、资源及含空格交付，已证明且未受影响项按原身份复用。

### 构建、边界和持续执行

从完整r5i清单建立下一run，仅纳入相关W修改；不以r4为起点重做。若仍native-only、实际Cangjie/foreign/ABI/flags未变且准入BC精确相等，复用BC `32576c52…`与obj `2dd3916d…`，只重编native和正式链接。必要公共仓颉修改回正典，明确同步与新冻结，不能为省llc永久私补或拒修共同层。最终以本次真实build exit0和新EXE身份判定，SDK恢复与自有资源清理沿既有机制。

本次不调用外部顾问；旧Pi答复可作历史材料，不需要再咨询才实施。原D失败累计保持，本裁决补足方案后可落实；若同一核心机制实质修复仍失败，提交新原件与失效前提，不再次循环猜guard，其余独立工作继续。保护E/H、用户资源和既有暂存/stash，未获要求不stage/commit/push。无需另开任务卡或新聊天，更新本页实际结果及ACTIVE，最终交付能直接启动的正常应用与诚实剩余边界。

<a id="windows-r4-resume-20261008"></a>
## r4 暂停后复核：保留正确方向，补齐交接漏口后完成原包（2026-10-08，历史指导；已修项按r5i保留）

**可以按原授权继续，重冻/重编/验收不需要逐步请示；但不能把资源/输入责任记成已经全部收口。** 本次指导只读当前源码、r4清单和已有原件，未运行探针/构建/VM。下列风险是源码可达，不等于已证明本次 editor-focus 失败或一次实际崩溃的根因。原 A–F、第六节固定门不变；不另做W0/W1、不扩GB/UIA/新编辑器，不调用GLM或自动追加咨询。

### 1．保留已有成果，先校准本轮基线

- 按钮将动作连续性与文本排版来源分开，复用CJGUI press机制的方向成立。新 `prepare_scene_node_text` 的正文/label/盒约束/字体/DPI/runs复用和节点颜色单独重画纹理方向保留；准备先操作临时next，失败不晋升accepted，不能为了通过点击删除文本身份门。构建 `983a0c23…` 的真实模式点击按报告保留为旧版本正控，新复用尚待实际构建消费。
- 本地 `r4-probe-round-20261007.log` 有九探针 `R4_ALL_GREEN`，press原件只有P1–P7。P8源码已存在，但 `sel33>0` 只证出现选择事件，未证明精确身份/落点/恰一次，也未找到本轮运行原件。新复用使P1“必换lease”的前提不再成立：有限补强为按钮只换label仍激活、文本只换字体/约束拒旧选择、同输入重绘保持layout/lease且精确选区成立，再接产品focus→输入。不把P8消息级探针等同SendInput消费。
- r4 `source-manifest.json` 的120个staging文件本次全部hash匹配（native `ad714b1c…`）；当前native是 `4b50625c…`，live另有公共头/窗口/文本会话/产品main等共13项相对漂移。**从完整r4冻结副本建立新run，加必要W修复，不能重新打包整棵live再声称旧BC仍匹配，也不能只拼回旧main/window两个文件。** 记录已吸收的共享基线及其影响；保护并行E/H文件，不回滚它们。BC/obj复用以实际Cangjie输入、foreign/ABI、编译flags及对应BC哈希不变为准；必要共享修复回正典并重新冻结/重捕，不为省llc留下生成副本私补。

### 2．先集中闭合三个原责任漏口，不重写整组

**F1：完成标记还不代表UI已停止访问。** `execute_dispatcher_command` 先在锁外写 `done=1`（当前6069），再读orphaned/通知；超时方6259见done就释放信封，UI在6077/6100仍访问。`fail_queued` 的取消完成发布→解锁→通知也有同类窗口。现有shim未覆盖此精确调度，不能靠“锁内重读orphaned”判完成。最小反例：UI暂停于done已写、尚未通知，让waiter超时认领完成，再恢复UI，验证无释放后访问。将最终结果、通知/移交、可回收完成发布与认领置于统一同步规则，所有正常/早拒/取消入口同责；完成发布后执行方不再访问已移交对象。phase-B等35秒到限但waiter仍非零时不能继续删锁/清session，须有具名延期回收责任。沿当前dispatcher做最小修复，不再封送90个API。

**F2：转存失败仍假成功结门，导航仍释放原件。** `finish_source_install_impl` 的非确认分支转存失败仅break（7001附近），随后仍 `settle_gate_locked`＋OK，shared因此清pending；`nav_barrier_stash_to_recovery` 失败后仍 `nav_barrier_release(...,0)`，导航重放也须核投递返回。返回了stash结局却未由所有调用方接住，守恒没有闭合。沿现有记录逐条转移成功才出队；失败保留完整记录、原request和结算责任，返回真实不可完成状态。容量释放后续接原结算，不重发owner写。确认、取消/替代、导航和关闭共用这项责任，不能只在某分支保留内存却清门使其不可达。最小反例用已有容量边界/分配失败接缝：有恢复积压时取消、nav转存失败、重放入队失败，核载荷/来源全等、零丢失、零重复和最终有界收场。

**F3：IME外层保槽仍被内部handled假成功绕过。** `handle_ime_core` 在terminal入队失败时只置recovering、未清handled（12963附近）；marked更新忽略返回。外层12913看到handled=1即释放冻结槽，新retry已无原件。让返回值反映实际接管，并记录RESULTSTR/后继COMPSTR的分段交接，部分成功不能整条重投。最小反例：冻结合法结果/预编辑→相应队列拒绝→完整载荷仍有主→释放压力→同composition恰一次兑现；附RESULTSTR成功而后继COMPSTR失败，不能重提已提交正文。保持禁止实时回读HIMC补旧消息的契约。

以上先用生产函数和可控交错做最短RED/GREEN，再撤回关键修复翻红。正常信封释放、锁内出队、恢复完整字段/短读保尾、导航epoch、共享层不再按8次无条件清pending等已修部分保留；不要重审无关全矩阵。

### 3．排版复用接完整候选，不用缓存掩盖阶段错配

还有一个可构造的候选顺序缺口，纳入本次文本准备修复：共同窗口configure后先安装本候选runs；Windows configure先克隆旧accepted节点，`set_composable_text_runs_impl` 随即用旧 `candidate->value` 校验新runs并prepare。旧 `abc`→新 `abcdef`，本候选run `[0,6)` 会先按旧3B正文拒绝，尚未进入新正文stage。先复现真实调用顺序，然后暂存本候选声明，与该候选新正文/绑定一起校验和准备；真实越界仍拒绝且保留旧accepted。不能放松UTF-8边界或全局把旧声明套新节点。

有限验证复用边界：相同输入排版/lease保持；节点纯颜色变化画面更新而几何连续；字体/宽度/DPI/正文真实变化重建；runs与新正文同时改变合法通过、非法拒绝保旧。绘制/命中/caret共同消费同一布局，缓存命中不授予旧绑定输入权。参考本地GPUI `text_system.rs::layout_line` 的文本/字体runs/约束缓存与平台持留规则，只读借鉴，不引依赖。

### 4．重编后连续完成正常产品链与原固定门

将上述相关native修复集中后，使用新清单在来宾重建库、按已验证BC/obj关系完成relay，核新EXE/实际加载库/hash/真实退出码/SDK原版恢复。受控捕获终止与真正AV分开留证；最终relay必须真实成功，不用旧exe存在或能启动倒证失败构建。仅native变更且依赖核实不变时不必重跑昂贵llc。

**本轮先跑默认1100×780路径。** 当前acceptance仍强制2640×1620，且仍发送裸ALT；去掉这两项补救，系统SendInput一次投递＋有界观察，必要坐标只读测量不能写owner/焦点/选择。editor-focus以当次当前身份的实际落点与首笔精确owner变化闭合，不以任意历史selection行计数。保留精确正文oracle，不用慢打、重复点击或增加等待掩盖丢字。

完整链沿第六节：中文/空格路径打开→连续ASCII/CJK/emoji→中段非空选区→Markdown预览→无编辑切回→免点击替换→Undo/Redo→公开Agent写→人续写→保存完整字节→正常关窗→同二进制新PID重开并再输入。原Unicode/系统IME、几何/生命周期、PNG及受控设备恢复、20笔真实工作重叠、空闲/回收和含空格交付继续完成；不把探针全部绿当作这些已跑。

runner用现有有界worker；修stdout/stderr继承与进程生命周期，不把“每次先杀遗留main.exe”当输出管道卡住的最终方案。关闭/失败按本轮PID、路径、启动身份回收，保护用户或归属不明进程；正常退出必须有真正回执。旧原件保留，新增失败具名分层，独立工作继续。最终只在本页/ACTIVE/既有INDEX短更，交可启动产物和用户能试的步骤，不stage/commit/push，不因一个小绿点停止。

<a id="windows-r3-press-resume-20261007"></a>
## r3 暂停后接续：按压连续性、输入责任与最终正常消费（2026-10-07，历史；以r4复核为准）

**原目标不变，修框架是本包已有责任，无需再选择“修复或绕过”。** 本轮指导只读源码与本地原件、核对官方 API 并更新任务；未启动 VM、实现、构建或设备验收。由用户把提示词交给执行者后恢复。原 A–F 和第六节固定门保留；不重开 W0/W1，不新增编辑器、GB、UIA 或验证平台。GLM 不可用，本包不再发起 GLM 或自动更换模型；已有 Astra 裁决前提不变直接落实。

### 当前事实先校正，避免从过期断点重来

- 本地 renderer 当前为 `4c0383d95baf…`，晚于用户附件 `9a2d0f04…`。[INDEX §十四](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/INDEX.md) 已记录 discriminator 轮，包 `f076704f…`、EXE `1ee4a2ad…`、`sceneDown=1/sceneUp=2/upNode=0/upFlags=0`；[冻结 manifest](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/r3-frozen-baseline-20261007-discriminator.json) 也在。当前本地有限检索未找到该轮完整逐行运行输出，执行者先找对应 run/session 原件并核实，不把索引叙述升级成独立运行证明，更不要默认重复“relay 重试→采同几个字段”。
- **这几个 UP 字段仍有两义性。** `windows_handle_mouse_up` 在 `windows_current_mouse_target` 失败时早退可留零；后面的 fresh hit 返回 NULL 且未取消也会写出同样的零。DOWN 未重置全部 UP 诊断。因此 INDEX 的“必然未走 hit-test”及报告的“唯一自洽解释”均待校正，不能据此把全部取消归因于重绘。
- **源码有可单独构造的具体缺陷：按钮绘制资源与动作身份混用。** button 进入 `prepare_scene_node_text`，重建排版产生新 `layoutLease`；`windows_mouse_geometry_still_matches` 对所有手势都要求 lease 相等。同动作、同绑定、同几何的按钮仅换 label 布局也会被取消。scene 号本身允许在后续推进，不是应删除 scene/identity 守卫的问题。这个静态反例尚不能替代本次 node114 的 exact-field 原件。
- 旧三组返工已有部分补丁：正常 dispatcher 返回已 free 信封、pump wrapper 已避开 TIMEOUT/IN_FLIGHT 回收、出队在锁内标 started；recovery 已扩大为48槽，零容量查询不弹出、短读保留尾部；IME 缺冻结时已不回读实时 HIMC；旧确认释放导航前已有 `navBarrierEpoch` 比较，owned-source安装只进入 provisional。按当前函数和对应反例逐项核验，**不重写已修整组**。恢复载荷转移、非确认结算、关闭与共享 pending 最终责任仍须闭合，不能据源码存在认定全部完成。
- 当前验收器的 `WindowFromPoint` 已是按值 POINT，旧错误不要重复修。`SendInput=0` 仍只说明投递未成功，未证是 Widgets 或 OS 故障。下面旧复核节保留当时证据，不作为当前逐项状态。

### 1．先闭合一个真正的按钮点击，再继续原链

先核 CJGUI 自身的 `CjguiComposableUiPressLease`、`pressLeaseIsContinuousInScene`、`consumePressActivation` 和 `composable_ui_press_lease_test.cj`；macOS 的 `pressedPressableNode`、`pressedRoutingNode` 提供现有平台对照。前者保留原 action/绑定及一次消费权，重新绘制后核真实几何、遮挡、scope；Boolean 另核值。**这些机制已有，Windows 应接齐，产品不另造按钮补丁。**

实现方向：

1. 在现有门控诊断里一次补齐 UP 的 `stage/reject_field/old/new`，并在每次 DOWN 重置；区分坐标纪元、目标缺失、绑定/启用/几何/lease、fresh hit/遮挡、显式取消及队列准入。保留同一 gesture/press seq、HWND/session 和捕获状态。只解决这一个分支判别，不建另一套遥测工程。
2. 把普通 pressable 的**动作连续性**与文本选择的**正文/排版来源连续性**分开。纯绘制/label 资源重建不取消合法按钮按压；保留原 press 身份，UP 仍查当前有效命中，并让共同 lease 决定业务授权。文本命中和拖选仍严格核对排版/正文，不把按钮规则套到文字；不能全局去掉 layout/版本/绑定门，不能给旧事件盖当前版本。
3. 真换绑、节点删除、禁用、Boolean 值变、坐标或命中语义变化、遮挡和捕获取消必须退役原序列。终态一次，后继旧 UP 不误激活新目标，按压外观也须清掉。核 `ReleaseCapture` 自己也会触发 `WM_CAPTURECHANGED` 的交错，不能双结算或把迟到取消给下一次手势。
4. RED/GREEN 用真实生产函数：同身份 DOWN→accepted 纯绘制重建→UP 恰一笔 END+ACTIVATE；另有换绑/禁用或遮挡/取消/文字 lease 失效负控。复用现有共同 press-lease 用例，不为每个日志字段建测试。

本地参考是 `/Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui_windows/src/events.rs` 的 `handle_mouse_down_msg/handle_mouse_up_msg`（窗口捕获），以及 `gpui/src/elements/div.rs` 的 `Interactivity::paint_mouse_listeners`（元素状态保存 DOWN、主动 refresh、UP 用同元素当前 hitbox 消费）。`div.rs` 的 hover/press 测试不是异常捕获完备证明；不照抄其默认消息分发。系统边界核 [SetCapture](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setcapture) 和 [WM_CAPTURECHANGED](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-capturechanged)。仅借鉴规则和测试，不引入 GPUI 依赖。

### 2．点击定位期间，完成尚未闭合的输入/调度责任

这些与前台点击独立的工作继续，不能全部排在 GUI 通了以后；同一文件由一个写入者整合、同一 target/设备串行。

- **输入转移必须有接收方。** 当前 `stash_recovery` 满48槽或分配失败只记 drops 后返回 void，取消路径继续销毁最多32项原件；转存只带 `bytes/length`，不能证明额外 marked 载荷、输入种类及来源仍完整。48仅覆盖空恢复环+32待决+16导航，没有覆盖旧恢复积压。先预算/预留或转移整条记录所有权，接收失败保留原项并返回可解释结局，不能继续扩大常数冒充守恒。现有短缓冲修补按当前实现复验；查询/短读不得销毁未取回的记录。关闭前由正常消费者接收或明确终结仍持有的输入，不能“写进 stdout 后清空”当成可恢复，也不允许只剩不可达 native 环。不会对无来源/已退役绑定进行盲重放。
- **结算失败不是请求退休证明。** 当前 `finishSelectionRestore` 仅对 SCENE_STALE 且次数<8保留，之后仍清 pending。安装尝试预算与已提交后的 ACK 责任分开；同请求待结算保留完整身份，只有 native 明确受理或转交到有主的具名恢复/终态后才清。重试只补结算，不重复 owner 写入，也不无限热泵。Windows 分支必要共享修改回正典，不能为保旧 BC 把此修复永久留在生成副本。
- **保留并验证当前 dispatcher 补丁。** 当前源码仍可到达：destroy把queued标cancelled但留在环中；timeout看到cancelled跳过摘除并释放ctx/信封，返回INVALID_SESSION；pump wrapper又free同一ctx。另完成端锁外读orphaned，与超时端锁内移交没有统一完成交接。这是静态可达风险，本次没有运行证明；先固定关闭×超时和完成×超时反例，把摘除、通知、移交、唯一回收权放入同一状态交接。不要继续靠返回码隐含所有权，更不要再次封送90个API。正常/排队取消/执行中超时/竞争/关闭，各验证proc至多一次、ctx/信封/句柄各释放一次、结果由原commandId认领，包含孤儿结果容量边界。先查已有 `dispatcher_lifetime_review.py` 与phase-2 probe补缺口，不扩无关调度器。
- **导航须经真正新选区确认。** 保留 `navBarrierEpoch` 修补，并用当前 `A→Left→B` 通过实际范围/版本/完整正文证明结果 BA；A的旧确认后B仍被新导航挡住，新选择安装后才继续。仅看到 A/B 两个载荷不是成功。源 provenance、旧票拒绝和 IME 缺冻结不回读的修复一并保持。

线程参考沿原 Astra 裁决和本地 `gpui_windows/src/dispatcher.rs::dispatch_on_main_thread/run_work_callback`，参考任务转移和唤醒；CJGUI 的同步超时、原请求取回与关闭责任需按本系统实现，不能把GPUI异步队列当作现成协议。

### 3．用正确输入工具核验；用一次一致构建集成

**输入工具方案：** 若 C# P/Invoke 的 SendInput 仍为0，优先在同一来宾交互 session/desktop/integrity 下用 SDK 原生小助手校对 `sizeof(INPUT)`、union布局、即时返回数/错误、HWND/前台/焦点。用可确定属于本轮的简单窗口做工具阳性，然后同一助手驱动 Pharos。助手只投递系统键鼠，不调用 owner、不直接给控件发 WM_CHAR 冒充系统输入。遵循 [SendInput 官方契约](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)：UIPI失败不能只据错误码定因。诊断 PostMessage/CLICK_NODE 可以定层，最终证据仍用系统输入，标明非物理人手。不要用放大窗口、250ms慢打、重复点击或裸ALT解锁替代修复。若真是外部环境阻塞，仅停依赖它的腿，继续原包独立项。

**构建策略：** 继续现有 Parallels Windows11 ARM64/x64来宾、常驻有界worker及 relay；不更换架构/SDK。先把以上相关 native 修复集中通过快速真实函数/MinGW probe；必要共同结算修复定稿后冻一次一致 source manifest，再完成受影响构建。单纯 native 变化且实际编译输入/ABI/flags一致可复用 BC/obj；`.cj`/foreign/布局等依赖变化就重捕并产匹配 obj。**昂贵 llc 不是不修共同框架的理由，已在整包授权内，不逐次请示。** 不把 live 漂移整包灌入，不从刚覆盖的 ZIP 反取旧 pin；旧基线及变更来源逐文件核对后形成新快照。常规输出隔离在新的 run 目录，不操作 E/H 现场。

**构建通过口径必须修正：**当前 `pharos-windows-relay-build.ps1` 在检查非零 `buildExit` 之前打印 `RELAY_OK`。这只证明部分注入/产物检查到达，不能覆盖稍后的 code46；EXE能启动也不能把本轮失败构建改称通过。实际使用的 r3 包装脚本也须按同一门核对，最终仅在本轮命令成功、捕获/注入/链接/新EXE清单一致、SDK原版恢复后报总PASS。45/46保留阶段原日志，可有界复试以得到新成功构建，但不把“AV后有exe”定义成可交付成功；若工具仍异常，隔离证实失败位置、记录可移除workaround，不能无限重跑或重做编译器。诊断产物可继续定层，最终正常包另取真实成功退出与完整哈希链。

### 4．同一最终正常 Pharos 完成原包，而非止于按钮探针

默认1100×780正常窗口：打开中文/空格路径 → 源码普通连续输入 → 中段非空选区 → 同版Markdown预览 → 无编辑切回 → 免点击精确替换 → Undo/Redo → 公开Agent修改 → 人继续输入 → 保存精确 → 正常关闭 → 新PID重开全文精确并继续输入。每次以动作前冻结正文、源跨度和版本独立算期望；纯选择不写正文，输入按真实意图边界核恰一次，合法拆笔单列而不放宽终态。最终验收关闭诊断注入缝，默认尺寸点击必须过。

继续原第六节剩余门：Unicode/系统IME、resize/DPI/失焦/生命周期、PNG正常消费与受控设备失败恢复、20笔实际工作重叠请求、空闲/资源回收、含空格同源交付。保留不受影响的旧证据，新增/受影响项才重跑；不引入新验收平台，不把还没做的固定门降格为下一包。错误脚本只修已证缺陷，不能改期待、加重投或放宽身份替生产救绿。

完成后交可启动产物、普通启动方式和人能试的操作链；在本页与ACTIVE短更源码/构建/设备证据及诚实边界。不stage/commit/push，不清用户实例/剪贴板/stash/暂存；自有worker、实例、端点按身份收回并核llc恢复。无新失败/疑点不重复整套审核。按整包连续推进；重复真实失败按既有规则带精确原件升级，只停依赖部分，不因修好一个点就结束。

<a id="windows-r3-phase2-review-20261007"></a>
## r3 / phase-2 复核与原包接续（2026-10-07，历史复核；已修事项以上方最新接续节为准）

**方向保留，不能接受“只剩来宾会话输入阻塞”。** 当前 renderer `4923039c…`、验收器 `a3ca58d4…` 与报告一致；r3 冻结/relay 材料保留，最终 EXE `22d590d6…` 为执行者报告，本次未访问 VM 核验。以下是当前源码、抽取生产函数的宿主反例及官方 Win32 契约的有限复核，不把这些缺陷说成已经证明了当前 UI 无响应的根因；指导不操作 VM、不改生产或验收器、不恢复执行。原 A–F 范围和正常编辑器目标不变。

### 先纠正输入诊断，别据坏探针修改系统或布局

验收脚本第40行把 `WindowFromPoint` 声明为 `(int x, int y)`，官方实际是按值一个 `POINT`。x64 下两个整数参数与8字节结构体参数并不等价。因此由该声明得到的“中心命中 explorer”不能证明窗口被覆盖；任务栏阳性不能校验不同 y 坐标。见[静态复核原件](../../artifacts/windows-pharos-20261005/evidence/20261007-phase2-review/input-diagnostic-abi-review.json)、[微软签名](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-windowfrompoint)、[x64 参数传递](https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-170)。改为顺序布局的两个32位有符号成员组成 POINT、按值传参，诊断与验收复用同一正确入口；用本机 SDK 原生调用对照非零 y 点，不能只改单个临时脚本。

`SendInput=0` 不能单独归因于 Widgets：核调用进程位数、INPUT 实际尺寸/字段偏移、即时错误码、runner与目标的session/desktop/integrity、目标HWND/PID和前台焦点；[SendInput 文档](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)明确有结构大小及UIPI约束且UIPI未必可由错误码识别。[PostMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postmessagew)是向指定HWND线程队列投递，不经屏幕点选，单纯Z序覆盖不能解释其不派发；记录发送返回值/错误和同次WndProc到达，勿与SendInput混为一个故障。Notepad没出现目标窗口也不是已建立的输入阳性。先做一次有界的正确工具对照，明确卡在发送/系统投递/框架出队/业务判决哪一层；不先杀Widgets、Explorer、重启VM或放大窗口救绿。默认1100×780“布局不可达”目前未证，保留待验。

### 框架原机制的必要返工，不另起新阶段

**独立复核原件：** [说明与范围](../../artifacts/windows-pharos-20261005/evidence/20261007-phase2-review/README.md)、[dispatcher 原始输出](../../artifacts/windows-pharos-20261005/evidence/20261007-phase2-review/result.log)、[输入恢复结果](../../artifacts/windows-pharos-20261005/evidence/20261007-phase2-review/recovery-extracted-result.json)。抽取真实生产函数的宿主实验已复现：正常 pump 漏一个命令信封；排队超时对同一 ctx 两次 free；5笔取消只保留4笔；短读取和零容量查询都会弹出未读完整载荷。这里的脚本 exit=0 表示成功复现缺陷，绝非生产验收通过。执行中超时、并发出队窗口和句柄复用仍属静态发现，未作设备证明；修后 GREEN 另存，不覆盖这些原件。

1. **dispatcher 所有权收口。** 当前正常 `windows_dispatch_sync` 返回只关doneEvent不free信封；pump wrapper在TIMEOUT/IN_FLIGHT后无条件free(ctx)，分别与核心已释放/后台仍使用冲突；IN_FLIGHT关闭的句柄仍留在命令里供reap再次关闭。出队与started也不原子：drain从环取出并解锁，execute才标started，超时方可在这段间隙把不在队列却尚未标started的命令释放。按既有Astra方向做统一命令状态与归属：QUEUED→RUNNING的交接和取消在同一同步边界内完成；出队获得执行责任后不得按“没找到/未开始”释放；运行proc不持队列锁。调用者、UI与取回槽的责任用明确持有/转移规则表达，信封/ctx/句柄各只回收一次，运行中超时保留原命令结果且不得重发副作用。统一wrapper退出规则，正常高频pump也须回到资源基线。先补真实函数的正常回收、出队竞态、pump超时及同commandId恰一次取回反例；已有40s sleep通过不足以覆盖这些。
2. **输入保全按完整载荷守恒。** `stash_recovery`在4槽满时只记drops，非确认结算仍把最多32项逐个free再返回OK；`install_recovery`短缓冲复制后整项弹出；close转存又随session清空。不能简单把4改32宣称闭合：原待决与恢复之间必须有完整载荷的责任转移、总量预算和正常消费者可达的取回/终态，未接纳前不销毁原件；短缓冲/长度查询不消费未读部分，关闭按既定责任结清。冻结IME槽满/超限时返回-1，当前消费又回退读实时HIMC，违反产生点来源；不能在已接管消息后补读当前内容冒充旧消息。核已冻结binding/组字身份，缺来源走具名保全/拒绝结局。共享`finishSelectionRestore`在native finish失败后仍无条件清pending，与SETTLE_RETAINED日志矛盾；保留同请求结算重试责任，owner已提交时只补ACK，不重复编辑。只改Windows必要分支、保留E/H语义。
3. **新导航屏障不得被旧确认放掉。** `finish_source_install`先drain `A→Left→B`，Left新建屏障并hold B，随后无条件`nav_barrier_release(s,1)`提前放B。确认只结清它负责的原请求；drain中新建屏障须等该导航经owner裁决、新选区安装确认后再继续。当前T3b跳过导航只核A/B载荷，不能证明最终应为BA；把判据改为真实范围/版本/最终完整正文，并核新安装前B尚未变成可提交范围。保留旧handoff正控，不以AB两字符串到达代替顺序正确。

**参考必须参与方案：** 先核共同CJGUI的owner/FIFO/安装ACK规则，再定向读本地 `/Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui_windows/src/dispatcher.rs` 的 `dispatch_on_main_thread`（队列转移后唤醒）、`run_work_callback`（into_raw/from_raw归属）及 `platform.rs` 的任务出队。对照责任转移、UI线程和唤醒，不能将GPUI对退出期特定泄漏的取舍套成本系统常态泄漏的许可，也不能把异步Runnable机制声称为现成的CJGUI同步超时协议。IME系统细节查SDK/官方文档。仅借鉴，不引依赖；用原报告一小段说明参考机制、差异及落点，已有结论可复用，不新增研究包或审批。

### 固定接续顺序

先修正确输入诊断，与上述独立native机制返工按写集安排；VM操作串行。native快速反例集中通过、必要共享窗口结算接线定稿后，再冻结匹配源集做一次正式构建；BC内容与工具链/ABI/参数匹配才复用relay，不能每个native补丁都重跑昂贵llc。SDK原版恢复证据及既有有效探针保留，不重做整个W0/W1。

随后用最终正常Pharos、默认窗口和真实SendInput完成本页原完整写作链及第六节受影响固定门。诊断PostMessage只标消息级；不得用CLICK_NODE、固定大窗口、慢打或重投替代。若正确工具和受控对照仍证明来宾会话问题，给出同一次原始事实及具体外部恢复需求，暂停依赖GUI的步骤，独立框架/文件/构建项继续；不把猜测当无限期阻塞。

不再咨询GLM、不重新选后端、不加GB/UIA/新应用，不在单个探针转绿后停工。保留用户及E/H实例/文件/剪贴板/转发/暂存/stash，不自行stage/commit/push。最终报告分清已修机制、原件证明、仍未验边界；本节修复完成后继续原整包，不另开下一轮纯验证器工程。

<a id="windows-current-review-20261007"></a>
## 2026-10-07 当前树复核：先消除验收误红，再完成原整包

**交接附件落后于当前实现，但完整写作链确实仍未交付。** 本次只读当前 renderer `c11084f0…`、共享窗口、验收器及 INDEX §九/十；未操作 VM，来宾目录是否缺失未现场复核。CodeLattice 对 live root 返回 `path_denied`，关系以直接源码补核；不据此推断能力缺失。宿主侧正则捕获回放与抽取真实 C 函数的结果见[最小复核原件](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/current-review-20261007.json)，它们不是新设备消费证据。

### 保留现有成果，纠正三个状态结论

- INDEX 已有 pump A/B 固定 UI 执行线程、关闭隔离，以及 provisional/导航屏障的局部探针 GREEN；不要再把整条线说成只有 Attach。修饰键已在 WndProc 捕获，旧无条件 scene 重盖已删，逐字 250ms 慢打已从 TypeUnicode 移除，这些保留。
- 当前 ZIP 实算 `371a0317…`，118 个源项与包内 manifest 一致；与 live 的两项差异是共享 `composable_ui_window.cj` 和产品 `main.cj`。旧 `a3343b67…` 是历史身份，不能代表当前包。冻结包可作为明确基线；新框架修复及必要共享依赖应形成新的完整一致快照，不因 live 继续变化拒绝构建，也不盲覆盖成 live 全树。
- `open-nwe` 是交接中的 cwd 漂移，不是本任务的候选工作仓。使用本仓和 `/Users/jiangxuanyang/Desktop/Pharos Mark` 的明确绝对路径；runner 传正确 root。旧来宾目录丢失依既有授权新建 run 恢复，不等待用户选择仓库或 E/H 合龙。

### 四项必要工作，按依赖连续完成

1. **先修确定的验收误红，停止由它推导焦点根因。** `pharos-writing-chain-acceptance.ps1` 当前正则 `(PHAROS_MODE visual=(?:true|false))` 的 group 1 是整串，后面却比较裸 `false`。有正确 `PHAROS_MODE visual=false` 行仍必报 `mode_switch_not_reached`。改为捕获布尔值，并用本次单击围栏后的 source/visual/无行三个原始文本用例固定判据；历史行不可救绿。此缺陷不能解释所有无日志的点击失败，后者仍需按同一次操作的捕获→入队→派发→版本/租约判决→accepted 结果定位。`Send-Click` 部分成功后整次重投、正文聚焦最多三次重投不能进入最终验收；默认窗口可达性仍需修，不以强制 2640×1620 代替。只做必要工具修正，不另开验证器工程。
2. **完成 UI 归属，复用 phase-1，不以 pump 探针代替全部封送。** 当前命令枚举仅 PUMP/DESTROY；present/SetFocus/安装/查询/图形释放等仍可在调用线程执行，destroy 的 caller phase 仍释放图形，栈上命令用 INFINITE 等待。依下节已定方案把相关 session API 封送、输出/事件载荷寿命、关闭及命令超时责任一起完成，保留单一仓颉逻辑 owner；不要只加线程附着或删线程门。反例在实际 present/focus/install/destroy 内核 caller/execution/HWND tid，补执行中超时与关闭在途命令，不能只读 lastPumpTid 宣称全 API 完成。
3. **完成输入交接，不能把“门内零写入”当作保全输入。** `queue_owned_range_replace` 的安装门 return 仍在导航持留入口之前；导航与组合开始亦有同类路径。现有 handoff T1 发 Q 只核零范围事件，之后直接从空文档走 A 链，未证明 Q 能取回。清门 API 只有 pending Bool：共享 `finishSelectionRestore` 对 installed/binding_changed/superseded 都传 0，native 只按 provisional 判 OWNER_CONFIRMED 并调用 replay。抽取函数实跑证实三种调用均得到 outcome=2、pending=0、replay=1。应传明确 owner 结局和匹配回执；失败时保留待结算责任，不先清公共待办。原始意图按原目标/请求/来源有界保存，确认成功后才顺序兑现；取消/换绑零误投、载荷可恢复。IME 的 raw record 当前仍只有 message/wParam/lParam/modifiers，需在产生点拥有 RESULTSTR/COMPSTR 等内容及来源，不能出队时读取当下 HIMC 补证。新增最小反例必须核门内 Q 最终恰一次或具名可取回、native 已装但 owner 取消零放行，以及延迟消费 IME 原载荷；沿用下节已有容量、ACK、ABA、A→Left→B 固定门。
4. **安全冻结构建后，直接完成正常 Pharos 原链和固定门。** `--stem`、`PHAROS_RUN_ROOT` 和 relay 内容哈希门已有，复用。当前 SDK 交换/交换后校验仍在 try 外，llc-real 只判存在，无 SDK 独占锁；worker 取消会杀承担 finally 的作业树。先按下节补独占、原件双哈希和不被同一取消杀掉的恢复责任，不能以一次 LLC_RESTORED 推导取消安全。native 反例集中通过后再做昂贵 BC 构建；缓存按完整输入准入。随后跑同一最终正常包的写作主链及原第六节矩阵，重开后还要继续输入。保留未改旧证据，复跑受影响面；图片/恢复/IME/资源等原门不得悄悄删去，也不新增 GB/UIA/另一应用。

**本次不改变方向或重复咨询。** 既有 Astra 方案已明确，GLM 无额度；上述问题由当前执行者在原包内实施。把框架线程/输入缺口回框架修，产品只保留声明与文档语义。完成一个探针不停止，失败只阻断其依赖；最后集中交付可由用户启动的正常应用、同源证据和真正剩余项。下节原方案与完成门仍有效，以下旧哈希和“尚无 dispatcher”表述仅表示当时事实。

<a id="windows-dispatch-input-package-20261006"></a>
## 2026-10-06 接续方案：冻结隔离、完整 UI 归属与输入交接（当前执行依据）

**决定：采用隔离后的 A，不等待 E/H 整仓合龙；先完成下述两项框架机制，再直接闭合原整包。** 目录遗失需在来宾核实，但不是架构阻塞。并行源码量大也不等于不能构建一个冻结副本。用户恢复执行后，重上架、隔离构建和本包必要框架修复均在原授权内，不再为它们逐项请示。此文档更新本身不恢复暂停线程。

### 本次复核事实与可复用资产

- 指导核了正典 native、共享消费、runner、[本轮索引](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/INDEX.md)及[Astra 答复](../../artifacts/windows-pharos-20261005/consultations/input-handoff-thread-affinity/answer.md)，未运行 VM 或重跑设备链。保留删 restamp、真实来源 claim、UTF-8 终止修复、能力拆分和已有 owner 决策/ACK 重试；这些确有接线。不能把它们改称完整输入交接已经完成。
- 本地 [源码 ZIP](../../artifacts/windows-pharos-20261005/guest-transfer/pharos-windows-source.zip) 实算 `a3343b67…`，118 个源码条目及生成清单一致；本次核查时它们也与当前正典逐项一致，含 `main.cj=8cb1f174…`、renderer `27f819bc…`。可先冻结此 ZIP 恢复构建基线。它不自动包含本节后续修复，最终需另冻新包并建立差分来源。
- 已有专用线程创建 HWND/D3D，但其余导出 API 仍直接在调用线程执行，`require_session` 仅查非空。所谓创建/懒 Attach/Detach 是 **Win32 `AttachThreadInput`**；不是运行时线程 attach，也没有实现 Astra 的命令封送。消息环目前仅存 message/wParam/lParam，IME 内容、修饰键在晚到的消费时才读，来源冻结仍不完整。
- 安装门内字符、导航和组合开始仍有直接返回路径；native 安装成功即清门，早于共享 owner 确认。满 32 个 range claim 会释放第 33 笔载荷；事件入队失败还可能让前驱序号先行推进。这些是当前源码可定位缺口，尚非本轮新增设备丢字证明。
- `pread` 的串行位置恢复 RED/GREEN 接受；它仍由 seek/read/restore 三步组成，不能由此推出共享 fd 并发语义成立。旧 `not_main_thread` 已有首次失配原件，不能再写成只有 M:N 猜测；但新 dispatcher 是否解决，仍要在最终正常包验收。

### 1．构建隔离：恢复已有产物路径，避免反复编译和踩现场

使用既有 Parallels Windows VM 与常驻 worker。核 UUID、SDK 实际版本及 worker 身份；不重装 SDK，不循环 `prlctl exec` 开新终端。沿用第六节的直接 EXE 退出码与中文/空格路径门。

1. 保留现有 ZIP、四代 relay 原件及日志；新建 `C:\cjgui-windows-w1\runs\<run-id>\source`、`relay`、`accept`。源码、target、日志和结果均按 run 隔离。现有 `stage_pharos_windows.py` 会删固定 staging/覆盖 ZIP，先参数化输出目录；不在旧现场原样执行。解包后逐项核 manifest，不能只看顶层哈希或复制成功。
2. 框架修复先落正典 W 责任层；把本轮明确的修复及其必要共享依赖同步到隔离快照，保留前后清单。共享文件按函数核差分，不能覆盖 E/H 整文件。若公共 API 已并行变更，就冻结相互匹配的依赖集并编译验证；不把等待整仓结束当默认方案。最终产物只来自冻结目录，不边构建边读取变化的 live 树。
3. relay 复用键包含实际 BC 内容哈希、工具链/llc 身份、目标 ABI 与全部影响代码生成的参数，输出路径等非语义差异应明确归一。匹配已归档关系才可复用 obj；不匹配只为该新 BC 重生成一次。不得拿旧 EXE、旧捕获日志充当本轮结果。先完成 native 快速反例与必要 FFI 设计，再做昂贵的应用 BC 构建；不是每改一个 native 分支就重跑 25 分钟 llc。
4. 不重复已失败的 PATH/CANGJIE_HOME/junction/bin-copy 重定向实验，见[原记录 §3](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/RED-GREEN-20261006.md)。本包可沿用已建立的受控 SDK 临时交换，补齐安全边界：同 SDK 独占构建锁；原版 llc 与 llc-real 双哈希准入；**交换及交换后校验都进入恢复保护**；正常/失败/取消均恢复并核原版哈希。现脚本交换在 try/finally 前，须修。worker 取消不得把唯一恢复责任方一并杀掉；保留可验活的外层恢复责任。wrapper 与 PS 的硬编码路径一起改为本轮目录。

### 2．框架方案一：完整原生 UI dispatcher，仓颉 owner 不迁移

采用已取得的 Astra 方案：进程内一个原生 UI dispatcher 管理 renderer sessions。仓颉继续由单一逻辑 owner 串行运行控制器和 DocumentSession；后台解析只提交待采纳结果。**不另造 Windows 编辑器、不把 owner 搬进 WndProc、不用 cjProcessorNum=1 或 re-home 解决线程归属。**

- 将 session 有关的 C ABI 入口变为命令封送，原实现成为 dispatcher 内部函数。session 查找/代次判断、HWND/焦点/IMM32、D3D immediate context、DXGI Present/resize/释放统一在 UI 线程执行并保留内部线程断言；只读纯值查询可用明确的不可变快照。不能先在调用线程取得可变 session 裸指针再排队。
- 命令拥有所需输入/输出和生命周期，队列有容量、命令 ID 与结局。调用者栈指针不得在返回后仍被 UI 使用；开始执行后的超时不是“未执行”，不得重发副作用。未开始的命令可原子取消，已开始的结果持留待取。UI 内合法重入走内部函数，不能同步等自己；出队后释放队列锁再调用可能重入的系统 API。
- `pump(timeout)` 是待满足的取事件请求，dispatcher 必须继续处理消息与其他命令，不把整个 UI 线程堵在该请求上。零超时仍服务已就绪消息；FIFO 持续有值、连续鼠标移动、无输入三类负载都要公平且有界，无事时阻塞等待。事件文字/几何/claim 的出队租约须覆盖调用者完成复制，不被另一次 pump 或 destroy 提前释放。
- 关闭以 session 代次退役新准入、完成/拒绝等待者、保存未决输入，再由 UI 线程结束 IME、销毁 HWND/图形资源；关闭一窗不能停止其他窗。禁止线程仍运行就清零 session/释放资源。`request_application_stop` 应投到 dispatcher，不能对任意调用线程直接 PostQuitMessage。
- 逻辑 owner 检查不能被 native 封送替代：同一 host 的并发 turn 必须被拒绝或由既定 owner 串行交接。不同调用 OS tid 的合法调用与不同逻辑 owner 并发必须分别检测；不把某次运行未迁移当作线程正确性证明。

**本组固定反例：** 原生 A/B 两调用线程操作同一 session，实际执行 tid 始终为 UI tid；真实仓颉默认调度负载正常；两个逻辑 owner 并发调用被拦；pump 等待中 resize/关闭仍收敛且另一窗存活；SetFocus 重入无死锁；命令执行中超时不二次提交/不悬空输出；持续 FIFO 下 OS 消息不饿死。记录实际 API 调用的 caller/execution/HWND tid、session 代次和返回状态，不依赖旧错误字段。

实现参考只读 [GPUI dispatcher](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui_windows/src/dispatcher.rs>) 的队列与唤醒；系统约束见 [Windows 窗口线程归属](https://learn.microsoft.com/en-us/windows/win32/procthread/creating-windows-in-threads)、[D3D11 多线程](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro)。不引入 GPUI 等运行时依赖。AttachThreadInput 仅在有证明的焦点操作中短时配对使用，不再承担线程正确性。

### 3．框架方案二：捕获、安装、owner 结算组成一条输入交接

复用已经接通的 arm/receipt、claim→共享 `submitInstalledRange16`→owner 决策→ACK，不恢复 restamp 或同文旁路。Windows 普通 SourceRange 能力与尚未实现的 selection-transfer 分开；不为本包开启全部 macOS transfer。

- **捕获时拥有事实。** WndProc 当场复制 IME RESULTSTR、同消息后继 COMPSTR、相位、composition ID；同时冻结修饰键、重复次数、捕获顺序、目标绑定/安装请求和实际来源。之后不能重新读“现在的”HIMC、Shift 或 scene 补来源。`projectionVersion` 始终保留产生时版本。指针/press 的旧几何也不能被刷新成新 scene；按已有 press 租约连续性判决。
- **安装成功先 provisional。** 按 `Ready → Holding(request,captureCut) → ProvisionalInstalled → OwnerConfirmed(receipt) → Draining → Ready` 实施；native 安装成功不能先清门。以 Windows 窄适配的 request/outcome/receipt 完成入口，区分 installed、superseded、conflict、closed；owner 后续检查失败不放行，调用失败不能忘掉请求。取消/换绑后的输入保留旧目标，不能投给新 request。
- **导航是顺序屏障。** 纯字符可沿共享已接受前缀连续物化；导航/选择/组合开始后，暂存后续原始意图，等共享处理器裁决与新选择安装确认后再生成范围。固定 `A→Left→B` 应为 `BA`，不能由旧 caret 得到 `AB`。ACK 重试只补确认，不再次 replace；发布 scene 也不等于前缀 ACK，不能丢未结算后缀。
- **容量有责任。** 将待决队列、claim、shadow 和必要副本合并计费，预留恢复/组合终态槽。普通突发有界，首次超限的原目标及完整载荷可取回，之后拒绝必须可见；不承诺无限输入全部保留。32 claim 的第33笔、raw 环满、分配/事件入队失败均不能仅计数并吞字；序号/前驱仅随成功准入提交，失败不得留下不存在的前驱。预留恢复载荷必须有正常可达的取回/放弃责任方，不能只有测试打印。

**本组固定反例：** XY 连发且每笔之间 present；同 binding 外部同长度写/同字节新版本；A→B→A 身份复用；门内 `A→Left→B`；门内 RESULTSTR/RESULTSTR+COMPSTR/END；捕获 Shift+Left 后松 Shift 再消费；native 安装成功后 owner 拒绝；旧请求结束不放行新请求；owner 已提交但 ACK 失败；第33笔与入队失败后下一笔。每项核原来源、唯一结局及完整载荷/owner 字节；不能靠250ms慢打、重复投递、扩大等待或放松共同守卫拿绿。

### 4．两项机制完成后，连续完成原编辑器整包

先在同一正常 Pharos 走完整小文档主链：中文/空格路径打开→无刻意逐字延时的系统输入→中段非空选区→Markdown 预览→无编辑切回→免点击精确替换→Undo/Redo→公开 Agent 改版→人继续输入→保存→同二进制新实例重开及续写。各步使用动作前冻结源跨度/版本/完整字节独立计算期望，截图对应同实例和相应 accepted 结果。诊断 CLICK_NODE/SendMessage 不能冒充最终 SendInput；每次投递核发送数/焦点，观察结算可轮询，但不重复动作救绿。

随后完成**本页第六节原固定门**：系统 IME、Unicode、几何/生命周期、PNG/失败恢复、20笔真实工作重叠、成本原数、空闲/回收及含空格同源交付。默认窗口下模式按钮已有超出裁剪区的原记录，须分清产品布局声明和框架测量/命中，在责任层修正常尺寸可达性；只把验收窗口放到特定大尺寸不能宣称默认交互已可用。保存前补共享 fd 的两个位置读真实交错及顺序读取反例；若 Windows 文件垫片仍不能履约，就修窄平台文件服务或证明/实施覆盖所有相关访问的串行所有权，不能只给 pread 自身加一把锁便宣称与其他 read/seek 不竞争。保留现有串行 GREEN，不重建通用 POSIX 库。

本轮不追加 1GiB、完整 visual 结构编辑、UIA、Linux、Android 或另一新应用。探针用于压缩定位与构建成本；机制门通过就继续正常产品，不把工作变成新一轮纯验证器工程。旧矩阵按影响复用，产物变更后的主链与受影响面绑定最终同一源集。性能在虚拟 GPU/x64 模拟层如实分项报告，不以工作时长推导性能或承诺物理机器结果。

### 执行、咨询与结束规则

执行模型由用户当前工具决定。用户已说明 GLM5.3 无额度，本包不再调用 Pi/GLM，也不要求执行者再向同型号咨询；旧第七节与早先 Pi 模板不作为本轮开工条件。已经取得 Astra 裁决，以上方案直接实施，不重复问同一架构。查 Microsoft Learn/本机 SDK 及仓颉技能解决 API 细节；仅出现推翻既定前提的新证据时，整理具体冲突交指导，其他独立项继续。既有失败次数不因换工具清零。

恢复后按整包持续推进，不以“咨询完成/探针绿/源码改完/上下文深”停止；只在用户叫停、真实外部阻塞或必须交回的新架构矛盾时中止依赖工作。工具/目录/本地构建缺口在本包内修。写集可分工，guest 构建/SDK交换/桌面串行，保留用户及 E/H 的进程/文件/剪贴板/暂存/stash。结尾集中报告框架机制、平台接线、正常消费、明确未验边界与可启动产物；清理准确归属的自有临时资源，核 SDK 恢复，不 stage/commit/push。

<a id="windows-input-pump-review-20261006"></a>
## 2026-10-06 源码复核：恢复正确输入，再闭合原编辑器整包

本节是较早复核原件；其中已完成的修复、已取得的咨询以及工具隔离实验按上方当前执行依据更新，不把旧措辞重复下发。

**方向没有变；当前不能按原报告继续堆后半链。** 保留 Win32 + D3D11/DXGI + DirectWrite + IMM32 + WIC、同一个 Pharos 及共同 owner/会话/解析/保存。构建、UTF-8 manifest、native 适配、PRESS_BEGIN 先于 FOCUS、runner 有界取消的有效成果复用；不重跑 W0/W1。当前仍没有最终正常编辑器整链证据。接续的新框架能力是：Windows 宿主有界且不饿死输入的消息泵、真实来源可解释的范围输入接续，以及同源正常编辑器消费。

本次核查了当前正典源码、验收脚本、relay 注入器及本机已有索引；**没有操作 VM**。暂停报告中的 accept9/accept10 完整原件在本机索引中尚未定位，不能把报告里的 `not_main_thread` 或点击无排水归因当作复现结论。执行者先归档对应来宾原件和二进制身份；确实缺失就登记，不以新轮倒证旧轮。[离线判据复核](../../artifacts/windows-pharos-20261005/guidance-review-20261006/admission-predicate-results.json)仅证明实际源码判据的假阳性，不冒充 Windows 运行。

新增[生产分支抽取反例](../../artifacts/windows-pharos-20261005/guidance-review-20261006/replay_native_input_seams.py)已在 Mac host clang 执行，[结果](../../artifacts/windows-pharos-20261005/guidance-review-20261006/replay_native_input_seams_result.json)固定当前 renderer SHA：四类事件来源 41→42、range/binding 不变，清 pending shadow 后 FIFO 仍有5条；安装 pending 下 IME RESULTSTR `handled=1/freed=1/update=0/terminal=0/successor=0/queueFull=0`，无门正控 update/terminal 各1。这是实际分支抽取的机制证据，尚非 Windows 完整 owner 错写/丢字的运行复现。脚本和旧 RED 保留，实施后同一反例应反转并补正常产品消费。

### 已确认的必要返工

| 项目 | 当前源码事实及风险 | 本包处理与区分验收 |
| --- | --- | --- |
| 输入来源重盖 | `cjgui_windows_renderer.c` 的 present 成功路径遍历 FIFO，将 kind 28/51/52/33 的事件及几何槽 `projectionVersion` 全改成新 scene。未逐事件证明文本、选择、owner 基线和来源仍适用。同 binding 不等于同一文本位置；binding 守卫仍在，不能夸称所有跨绑定检查已失效，但旧坐标来源确被抹掉 | 删除无条件重盖，保留真实产生时的身份。同绑定纯画面更新可以在消费侧有证明地接续；文本/owner 变化须走既有版本/锚点契约或具名拒绝并保全输入。若生产者缺少必要来源，先定最小来源与安装/FIFO交接契约，不能把当前版当来源。反例覆盖纯刷新合法接续、同 binding 外部写入、换绑/ABA、旧选择或组合终态不得错写 |
| 输入被门丢弃 | `source_install_gate_holds_input` 只增计数；字符/导航/组合开始返回未消费，无延期队列。WndProc 默认处理不会替 CJGUI 保存编辑意图。尤其 IMM32 RESULTSTR 在开始失败后仍被标 handled 并消费，结果无 owner 事务也无可恢复载荷 | 保留安装对齐门；实现或复用有容量责任、真实来源和顺序的待决输入交接。正常同绑定短暂安装后按 FIFO 恰一次兑现；换绑/版本冲突不得投到新目标，须明确终态/恢复路径；满载不能假成功。连发、自动重复、代理对和组合提交都不能靠 250ms 节奏救绿。不是简单删门，也不是给无来源旧按键盲重放 |
| 零超时消息泵 | `pump_windows_messages` 先取 CJGUI FIFO，空且 `remaining==0` 就返回，尚未 `PeekMessageW`。共同调度器预算用尽与 drain 后续轮会调用 pump(0)，可反复不搬运系统消息；FIFO 持续有值时也需核系统队列公平性 | `timeout=0` 表示不阻塞等待，不表示不处理已就绪系统消息。先用实际函数做 FIFO空、OS队列有消息的 pump(0)/pump(1) 区分；再实现有界系统消息服务与 FIFO 排水，保护 WM_QUIT、关闭、输入、公平性和空闲不自旋。不能声称这一源码缺口已解释 accept10，须同实例轨迹确认 |
| 线程失配证据不足 | native guard 比较 current OS tid 与创建时 ownerThreadId；现有 pump tid 打印在 guard 成功之后，不能排除被拒的调用。某轮 tid 不变也不能证明另一轮没有迁移；共同窗口的 lastNativeFailure 还可能保留此前错误，不能代替本次 FFI 返回码 | 在首个拒绝点记录 API、session/token、HWND创建线程、owner/current tid、turn/场景及实际返回状态，贯穿创建→pump→present→destroy。先区分真实线程迁移、调用者错误、历史错误字段、旧 session、旧 DLL/EXE。不能删 guard、随调用改 ownerThreadId，或单凭“仓颉 M:N”建立第二套线程架构。若确需固定 UI 线程，先独立裁决窄适配及 Cangjie 回调/owner归属，保持公共 owner 串行契约 |
| 构建来源准入 | `guest-transfer/llc-relay/llc_wrapper.c` 只按 `pharos_mark.opt.bc` 文件名注入固定 obj；捕获 CopyFile 的失败未挡住成功返回，wrapper 内无内容 hash 门。报告的构建后 SHA 对比不能代替下一次注入的先决条件 | relay 可继续使用，但纳入正式可复现入口：冻结源码/依赖/ABI/编译器版本与哈希/完整flags/BC/obj/nativeDLL/EXE关系，注入前核输入和obj；不匹配/捕获失败必须非零，不允许旧obj。使用隔离工具链目录或明确工具重定向，移除对用户SDK全局llc的长期替换，核原件恢复哈希。不变的输入可复用已验obj，不必每次重复13–29分钟生成；app输入改变才重新relay。Mac产obj+来宾链接如实标为混合构建，不能写来宾原生完整编译 |
| 验收假阳性 | `Probe-Click` 匹配 `CLICK_RESULT 107`，native 返回 `CLICK_RESULT 107 missing` 也通过；CLICK_NODE 实际使用 SendMessageW。TypeUnicode 每单元250ms，未核 SendInput 返回数；foreground 失败仅记录；替换只查旧token消失且任意X出现 | 只修这些必要工具门：missing/未送达必须失败；SendInput精确发送数+目标HWND/焦点+owner/accepted核对。CLICK_NODE保留为明确标注的局部诊断，最终鼠标腿走系统输入。基于动作前版本、源跨度、完整字节独立算结果；同长错文、错范围、零投递均红。不得扩成另一条无尽日志验证器工程 |

源码入口：[`cjgui_windows_renderer.c`](../../runtime/cjgui/platforms/windows/native/cjgui_windows_renderer.c)（present、`pump_windows_messages`、`source_install_gate_holds_input`、`queue_owned_range_replace`、`handle_windows_ime_composition`、CLICK_NODE）；[`windows_application_host.cj`](../../runtime/cjgui/src/windows_application_host.cj)；[`llc_wrapper.c`](../../artifacts/windows-pharos-20261005/guest-transfer/llc-relay/llc_wrapper.c)；[`pharos-writing-chain-acceptance.ps1`](../../artifacts/windows-pharos-20261005/runner/batches/acceptance/pharos-writing-chain-acceptance.ps1)。按符号读必要代码，不重新通读所有平台历史。

另有保存前必须核对的小接缝：[`cjgui_windows_posix_compat.c`](../../runtime/cjgui/platforms/windows/native/cjgui_windows_posix_compat.c) 的 `pread` 用 `_lseeki64 + _read`，会改变 fd 位置，不能仅凭注释“单线程owner”声称与位置读等价。共同 `ImmutableBase.readAt` 确实调用该符号。先核本轮冻结装配中后台读取/保存的实际调用者，用两个不同偏移及共享句柄交错验证；需要修复就在 Windows 窄文件服务内保持位置读取语义。`renameat`/`fsync` 也按保存链实际使用核失败保旧及路径语义，不扩写通用 POSIX 层，不据一次正常保存宣称掉电持久性。

### 实施顺序与咨询

1. **冻结一次可解释输入，稳定宿主。** 复用现有 VM、已装SDK与常驻worker。先把relay准入和最小验收门修可信，再做 pump(0) 与首次线程拒绝的区分实验；可以并行读码/离线反例，但同一guest图形桌面与cjpm target串行。不要又从GPU画矩形开始。
2. **统一输入接续。** 把重盖、安装待决、pending shadow、IME结果、旧来源拒绝作为同一交付来处理。先复用已有输入/线程裁决，并核对上述反例、当前 Windows 生产者字段、核心消费门和 E 的现行契约，明确最小字段、队列归属、顺序与终态；前提冲突则带证据交指导，不自动重启咨询。期间继续 pump/构建/工具的独立工作。共享头/核心若确需小改，列出受影响函数和E/H边界；不能批量覆盖在途树或为Windows放宽共同旧事件守卫。
3. **先闭合完整小文档正常链。** 正常 Pharos 打开中文/空格路径→快速系统输入→中段非空选择→预览→无编辑切回→免点击首笔精确替换→Undo/Redo→同owner公开Agent改版→人免点击续写→保存→正常关窗→同二进制新实例打开和续写。单次投递，状态变化或明确截止结算；输入可以依契约拆笔，但逐笔范围/版本/合法前缀及终态完整字节须成立。禁止为了拿绿反复点焦点、重投正文、退化成末尾追加。
4. **继续完成原第六节固定门。** 系统IME、Unicode、几何/生命周期、正常编辑器PNG、受控设备恢复、20笔真实工作期间公开请求、空闲/回收、含空格同源交付均仍在包内。无变化原件复用；变更后的输入链与最终产物必须对应同一源码/ABI。不要增加1GiB、完整visual编辑、UIA、Linux或新的前置消费者目标。

线程与消息泵参考 [Microsoft PeekMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-peekmessagew)，输入计数参考 [Microsoft SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)。本地 GPUI `gpui_windows/src/platform.rs` 的消息循环、`dispatcher.rs` 的主线程归属仅作实现思路参考，不引入依赖；精确目录见本页原参考节。普通明确接线直接做，API查Microsoft Learn与SDK头；根因不明先核框架与参考实现并做区分实验，达到升级条件时按第七节带证据交指导，不自动调用顾问。不得用“需要裁决”停住全部工作，也不能换模型清零累计失败。

### 收尾与停止边界

高频无条件调试文件输出改为默认关闭、按实例有界的诊断；保留能重算的原件，不因删诊断失去唯一证据。最终核EXE/DLL/源码/relay链及原SDK恢复，提供用户可直接启动的正常编辑器。仅清本轮准确归属的进程/端口/文件，保留用户VM、窗口、输入历史、剪贴板、E/H改动及暂存/stash；不stage/commit/push。

本节不是新一轮纯探针任务。上述明确反例及受影响检查通过后就推进正常写作链，最后按原固定门集中报告；不在每个绿色后请示。若旧故障达到现行 AGENTS 的升级条件仍无可验证方案，仅交回该依赖并继续独立项；旧咨询流程不再作为前置步骤。不能因长上下文、已有todo勾完或“理论上能工作”将整包称完成。

<a id="windows-tool-handoff-review-20261005"></a>
## 换工具接续：当前复核与执行顺序（2026-10-05）

**方向保持；实施顺序收紧到正常 Pharos。** 旧线程「推进 Windows 编辑器移植 A–F」已暂停，现有 Windows renderer、仓颉 host、共同包适配和 runner 保留。接续者不从 W0/W1 重启，不另造编辑器，也不先把全部 Windows 底层接口做完才尝试产品。当前尚无正常 Pharos Windows 写作链，更不能把 native 输入探针称作编辑器已可用。

### 已有成果的有效范围

- Windows native 已有 D3D11／DirectWrite、样式、DPI、累计纹理预算、鼠标与 UTF-16 事件等实现和定向原件。最新[输入原件](../../artifacts/windows-pharos-20261005/runner-sessions/bc279ba2cd8347b0adb9db78c4b4ee19/guest-results/input-contract/windows-input-contract-run.log)的构建、探针和 worker 退出均为 0；清单 50/50，源码包 `79bd9e84f9c35a70ad6f5221621c617f5bafdbd4def1ab342e08fb94b942522b`。该[探针](../../artifacts/windows-pharos-20261005/renderer-contract/cjgui_windows_input_contract.c)使用 **SendMessageW + native FIFO 读取**；标签／值、拖选 1:3、A/B 范围载荷、旧 DPI 坐标拒绝有效，尚无仓颉 owner、SendInput 正常产品或真实 IME 证明。
- [runner](../../artifacts/windows-pharos-20261005/runner/windows_runner.py)的返回码／不完整帧／超时退役已有修复和负控；有效证据复用。运行中主动取消与跨任务应用持有另见下文，不能由 15/15 回包测试推导成立。
- SDK 已在来宾当前用户 `C:\Users\jiangxuanyang\AppData\Local\Programs\Cangjie` 持久安装，暂停报告为 1.1.3。新工具只核一次实际版本与可执行文件路径；若已变更，沿现安装做兼容验证，不重复安装，不改 Mac SDK。
- Windows 正典实现入口为 [native](../../runtime/cjgui/platforms/windows/native/) 与 [windows_application_host.cj](../../runtime/cjgui/src/windows_application_host.cj)。目前产品仍由 [stage_pharos_windows.py](../../artifacts/windows-pharos-20261005/runner/stage_pharos_windows.py)从现有 `apps/pharos_mark/src` 和四个共同包生成装配；不存在一个已经完成的 `apps/pharos_mark_windows` 产品入口。名称不作为验收门，同源和可复现构建才是。

### 第一优先：把正式产品构建和正常启动打通

1. 接续已有[源码发现咨询材料](../../artifacts/windows-pharos-20261005/consultations/pharos-package-source-discovery/request.md)，不接受其假设为结论。[失败原件](../../artifacts/windows-pharos-20261005/runner-sessions/1c570524093f423b89a85fd9b8658355/guest-results/pharos-build-logs/pharos_mark.log)是 **127 errors generated、仅打印 8 条诊断**，涉及 7 个不同类型；“包内有声明”不证明该次 cjc 真读到了这些文件，也不证明这 8 条就是第一根因。先对应失败那次 archive／manifest／实际来宾源码／cjc 参数及完整诊断，区分旧包装配、文件发现、条件编译与后续连带错误。新清单不能倒证旧构建。
2. [旧慢构建咨询](../../artifacts/windows-pharos-20261005/consultations/pharos-app-timeout/answer-followup.md)已有进程证据：某次无新输出时仍在 app 单元 `llc` 代码生成，外部停止并非编译器给出的失败。不得再用“没日志＝卡在链接”归因，也不反复用相同输入全量编译等待超时；先做能区分假设的小检查，必要时只重建受影响 app 单元。新构建需要固定输入和阶段原数，不继承旧残留 exe 当新结果。
3. 正常产品的平台边界必须一起核清：host 条件编译、实际被选中的传输、应用侧 `pharos_*` 原生服务及 DLL／库闭包。当前 app 生成清单无应用 `[ffi.c]`，冻结 `main.cj` 有 35 个 `pharos_*` foreign 声明且未打包其 native 源；不能把“8 条类型诊断解决”直接视为可运行。已有 macOS 诊断注入／PDF 等辅助不能整套成为 Windows 正常启动前置；通过正典平台边界按需隔离。正常入口需要的时间、文件、进程、owner／公开传输服务必须真实实现，其他能力具名不支持；不能用返回成功的空壳换取链接通过，不能复制 owner／历史／解析器。另有具体待核点：host／产品用 `@When[os == "windows"]`，共同 transport 用 `"Windows"`；用当前 SDK 的极小目标条件检查确定取值后统一，不能由字符串差异直接归因上述类型报错，也不能不核就改共享传输。
4. 将反复使用的 staging、native 构建、包构建与运行命令收敛为正式入口（平台／产品 tools 下，现有脚本按职责迁移或包装；artifacts 只存输入快照和结果）。一次完成同步、指纹、构建、闭包及正常启动；不依赖执行线程的记忆或来宾中手改文件。共享修复仍回正典，E/H 在途写集按函数避让，不重构整份产品主文件。

### 同包必修：三个源码安装／恢复接缝

以下为当前源码与共同契约复核发现，**尚未在 VM 跑新增 RED**。接续者先在当前生产函数上各落一个最小负控，再最小修复，并最终在正常 Pharos 消费；不把静态推理写成设备结论。

| 问题与落点（`cjgui_windows_renderer.c`） | 机制要求与区分验收 |
| --- | --- |
| `set_source_install_gate` 存 pending 并返回 OK，但 `queue_owned_range_replace`、`enqueue_windows_navigation`、`begin_windows_composition` 未消费这个门 | 安装待决期间不能按旧选择发布编辑；复用共同具名拒绝／延期语义，不能静默丢键或私自重放无来源输入。负控：新非空范围票已挂起、尚未安装时字符／Delete／组合开始不产生旧范围 owner 事务；正确安装后首笔只替换新冻结范围 |
| `install_owned_source_selection` 在 `SetFocus` 前调用要求已经聚焦目标且 proxy 正文相等的 `windows_validate_active_text`；声明入口也要求先聚焦。共同窗口 `sourceInstall` 路径却有意跳过先 focus | 分清 accepted 目标准入与“当前已活跃”校验。以正确票据准备目标 proxy，并在同一次接管安装焦点和非空范围，失败保旧。负控：A 为源码目标、焦点在预览／另一节点 B，A 的正确请求应完成安装；错误代次拒绝不动 B。不得靠产品额外点击或永远先聚焦掩盖原子安装契约 |
| `recover_active_text_proxy` 只查 accepted 节点／正文，未核当前活跃身份就改 session 全局 proxy 和选区 | 按公共头文件“非活跃目标拒绝且不变”履约。负控：A 正在编辑，accepted 中另有 B，恢复 B 必须拒绝且 A 的正文镜像、选区、待决输入不变；随后 A 仍能正常输入 |

源码位置：上表依次为当前 native 约 3860/5374/5537/5623、6009/5319/6120、6074 行；以符号为准。已有 DPI、样式 run、label/value 和累计纹理预算问题不再列为待返工。presentation TEXT 的直接可视输入未接齐属于主链之后的扩展，本包先保证源码编辑与只读预览。

### 控制通道：补一个取消切面，明确应用持有方式

[worker_run.ps1](../../artifacts/windows-pharos-20261005/runner/worker_run.ps1)在任务 `WaitForExit` 期间不读取 STOP；host `run_batch` 只捕获 `Exception`，本次纯内存中断检查发现 `KeyboardInterrupt` 后协议仍为 connected，最终 STOP 不能立即结束在跑的 guest 任务，最长可能等到该任务预算。下一次长构建前补**同 session/job 身份的有界取消或断连回收**，验活跃子进程与回执，不能只改捕获类型后宣布解决，也不能批量杀控制台或用户进程。不重建一个通用远控平台。

worker 在一项任务结束后关闭 kill-on-close job，后代一并回收。因此不能 `Start-Process Pharos` 后让脚本立即返回、再在下一任务找那个窗口。优先把本轮正常消费放进**同一个有界 guest 作业**，应用保持到原件落盘再清理；确需跨批持有才实现明确的实例所有权。最终另提供用户可正常启动的产物及命令，不以验收器保活替代正常入口。

### 接续到结束：一个产品链，最后一次汇合

执行顺序为“构建／启动 → 三处接缝与源码编辑 → 预览原选区往返 → 人／公开 Agent／人 → 保存关开”，独立的 PNG／设备恢复可以交错推进；以上顺序不是逐段请示点。不得先扩 visual 编辑、UIA、GB 文档、Linux 或第二个前置应用。

功能接通后按原第六节固定门完成 Unicode／系统 IME、PNG／失败保旧、设备恢复、20 笔真实负载下的公开操作、空闲和开关资源、含空格同源交付。旧证据按源码影响复用；最终同一构建必须有 SendInput→共同会话→owner 完整字节→accepted 画面以及保存／新实例复开原件。不能用 SendMessage 探针和仓颉编译分别通过来拼成这条证据。

新工具不需要旧线程上下文即可从上述路径接续。咨询规则按第七节及现行 AGENTS；不自动调用 Pi/GLM 或其他顾问，已有答案前提不变就复用。当时构建源码发现问题的请求已写好但暂停前未调用，该材料不构成现在启动咨询的授权。不得因换工具清零失败累计。遇具体阻塞只暂停其依赖，不能把全部时间继续消耗在 runner／探针，最后按固定门集中报告。

### 本轮执行记录（2026-10-05，Sisyphus 接续中，整包未完成）

- 正式链收敛：stage/prepare/包构建已成固定入口（115 项清单、zip 哈希门、应用原生库同链编译）；六个依赖包干净重建全绿。证据索引见 `artifacts/windows-pharos-20261005/evidence/20261005-sisyphus-handoff/INDEX.md`。
- 三接缝已修并探针收口：RED `gate_leak range=1 nav=2` → GREEN `PASS gate=3 install=0:5 first=X stale_refused recover_refused continue=Y`；旧输入契约回归仍绿。
- 阻塞（只暂停依赖部分）：产品包前端已出 `.cjo`，`llc` 在 ARM64 模拟 x64 上三轮预算（45/117/125 分钟）无产出且不可续跑；`--stack-trace-format=simple` 对照同样爬行。`main.cj` 的 `runPharosApplication`（3742 行单函数）与 E 在途 `async_multiline_measure`（已给诚实失败桩）的裁定归 E；E 当日在 mac 侧撞上同样的 `@When` 大小写与 lambda 裸块错误（本轮已顺手修 3 行）。验收二进制与 A–F 门待 llc 收敛后执行。
- E/H 写集、暂存/stash、用户文件、剪贴板、实例均未动；无 stage/commit/push；各 guest 会话均已按身份关闭。

## 一、固定方向：同一个编辑器，共享核心，补 Windows 适配

macOS、鸿蒙和 Windows 的文档模型、事务、撤销、Markdown 规则与公开协议必须同源。Windows 平台入口可以不同；业务正文不能再有一份独立实现。不是把 AppKit 或 ArkTS 文件逐份翻译成 Windows 代码。

| 层 | 本包选定路线 | 复用与约束 |
| --- | --- | --- |
| 编辑器业务 | 现有 `document_core`、`app_services`、`markdown_engine`、`editor_surface` | 复用 DocumentSession、DocumentFile、SourceMap、历史、快照和保存；平台只提供必要服务 |
| 框架 | CJGUI 仓颉组件、布局、状态、场景接受、文本会话与共同操作 | 延续原 owner 和 accepted 身份，不在 Windows 桥里复制业务正文、撤销或第二套布局 |
| 窗口／事件 | Win32 | HWND、消息泵、键鼠、焦点、捕获、剪贴板、窗口尺寸与 DPI；默认走 Unicode API |
| GPU 自绘 | D3D11 + DXGI | 将 W1 的有效图形经验接入 CJGUI 正常 renderer；对象按设备／窗口／资源代次归属，不能长期保留实验中的全局单窗口状态 |
| 排版与文字绘制 | DirectWrite + CJGUI 的 D3D11 提交 | 持留同一份排版，绘制、命中、caret、选区和上下导航共用；字形栅格结果进入有界缓存。DirectWrite 不会自动替应用完成 D3D11 绘制。[微软说明](https://learn.microsoft.com/en-us/windows/win32/directwrite/rendering-directwrite) |
| 系统输入法 | 先走 Win32／IMM32 消息到现有文本会话 | 对照本地 GPUI 的实际路径，接组合、提交／取消、焦点和候选定位。TSF 是出现已证能力缺口时的扩展方向，不先并造两套输入栈。不得自研输入法或把直接注入汉字当作系统组字。[组合消息](https://learn.microsoft.com/en-us/windows/win32/intl/wm-ime-composition) |
| PNG | Windows WIC 解码 + 现有 CJGUI 图片准入／缓存 + D3D11 纹理 | 解码前预算、尺寸和失败原因沿共同契约；WIC 只承担平台解码。[系统编解码器](https://learn.microsoft.com/en-us/windows/win32/wic/native-wic-codecs) |
| Agent 入口 | 现有 shared-operation 协议与 owner 队列 | 若 Unix socket 不适用，为同一协议补 Windows 本地传输；可用 loopback TCP，保留身份、授权和版本校验，不另造业务服务器 |
| 无障碍 | 后续 Windows UI Automation 平台投影 | 保留共同语义模型。本包不把 UIA 全覆盖、讲述人验证作为启动编辑器的前置条件，也不能因此宣称已支持 |

初期采用 DirectWrite 字形／run 栅格与有界纹理缓存；彩色字形若需要 Direct2D 系统接口，可封装在同一 Windows 文字适配内部，仍消费同一布局，不另起整套 UI 框架。不能把 shaping cluster 直接等同 Unicode 字素；分段服务与现有文本会话的契约不明确时先核对已有实现和反例，实质未决问题按第七节交指导。

不在本包改用 Vulkan、Qt、Slint、Flutter、SDL、WebView 或可见的系统 EDIT 控件替代 CJGUI 自绘正文。GPUI 等仅查实现思路与测试，不成为开发、构建、运行或发布依赖。Linux／Android 不在本包开工，现有 macOS／鸿蒙后端也不换路线。

## 二、起步只读这些，并保留当前工作

1. 框架 [AGENTS](../../AGENTS.md)、[ACTIVE](../../runtime/cjgui/ACTIVE_DIRECTION.md)、本任务；阶段意图按需看[设计导航](DESIGN_INTENT_INDEX.md)、[共同操作契约](../core/AI_NATIVE_UI_SEMANTICS.md)。
2. 产品 [AGENTS](</Users/jiangxuanyang/Desktop/Pharos Mark/AGENTS.md>)、[STATUS](</Users/jiangxuanyang/Desktop/Pharos Mark/STATUS.md>)及[架构的状态归属和范围输入部分](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/ARCHITECTURE.md>)。首次写仓颉前读 [cangjie-coding 技能](</Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md>)。
3. [W1 报告](../../artifacts/windows-w1/REPORT.md)、本轮指导的 [RED 原件](../../artifacts/windows-w1/guidance-review-20261005/red.json)和[只读回放程序](../../artifacts/windows-w1/guidance-review-20261005/replay.py)。原 RED 保留，修后另存 GREEN。
4. 直接相关资产：框架 [src](../../runtime/cjgui/src/)、[FFI 与 POD](../../runtime/cjgui/src/runtime_renderer_session.cj)、[公开传输](../../runtime/cjgui/shared_operation_core/src/shared_operation_transport.cj)；产品 [四个共享包](</Users/jiangxuanyang/Desktop/Pharos Mark/packages/>)、[macOS 入口](</Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark/src/main.cj>)、[鸿蒙薄装配与控制器](</Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src/>)。只按依赖读相关符号，不通扫历史计划。

Windows 机制参考位于[本地 GPUI Windows 源码](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui_windows/src/>)：`window.rs`／`events.rs` 看窗口与 IMM32，`directx_devices.rs`／`directx_renderer.rs`／`directx_atlas.rs` 看提交和资源退役，`direct_write.rs` 看排版与字形。先定位关键函数和测试，再查对应 Microsoft Learn 及本机 SDK 头文件；不从记忆猜 ABI、消息含义或 HRESULT。

开始时记录两仓当前差异和暂存边界。E/macOS 的文字安装、性能和输入改动，H 的 OHOS renderer／snapshot／ArkTS／transport，以及既有暂存都保留。不切分支、不 reset/stash、不自动 stage/commit/push，不用整文件覆盖共享写集。共享核心确需变化时按函数做最小通用修复；已有未完成并行修改不可直接改写。冲突只阻塞其依赖部分，Windows 独立工作继续。

## 三、工作环境：就在已安装的 Windows 虚拟机里实施与验收

使用 Mac 上现有 Parallels 的 Windows 11 来宾，不另买／另装虚拟机，不在 macOS 上编译一个近似版本冒充 Windows。W1 使用的 VM UUID 为 `{9e5dedb2-90f8-4d21-80f0-41e194407fab}`，工作目录为 `C:\cjgui-windows-w1`；使用前按身份核对，不据此操作其他虚拟机。

W1 报告记录 SDK 1.1.3、`x86_64-w64-mingw32`，路径 `C:\cjgui-windows-w0\sdk\cangjie`。先取实际 `cjc/cjpm` 版本；若用户已换成 1.2.0，沿用并验证受影响兼容面，不为旧报告反复重装，也不升级两仓的全局 SDK 要求。编译器、应用及实际加载的自建 DLL 架构逐项核对；目标是当前 x64 来宾产物，不假装已支持 Windows ARM64 原生编译。

控制通道复用 W1 经验，但先修第四节中已证的退出码与生命周期问题。长脚本按文件传输／执行，避免反复调用 `prlctl exec` 开新控制台。采用一个有身份、可退出的 worker；每批复用或明确回收，不留下无限重连的旧 worker。核对客户机实际部署脚本的路径和 SHA，不能拿 Mac 上 `worker_batch.ps1` 的检查替代实际运行的 `worker_run.ps1`。

前台验收在 Windows 来宾的交互会话完成。优先 guest-side 有界驱动与截图／读回；Mac 屏保、Mac 工具报错、Windows 会话状态分别判断。不以抢不到焦点推断框架错误，不改变系统锁屏策略；工具确实无法输入时保留具体错误，继续不依赖桌面的实施。

## 四、必要旧问题一次并入本包，不另开验证长跑

W1 的 D3D11 设备、着色／透明混合／裁剪／resize 和仓颉参数到图形的结果保留；它尚未证明 CJGUI 编辑器正常消费。指导已核对源码及原件，以下按实际缺口补齐：

| 必要项 | 已发现的问题 | 本包如何闭合 |
| --- | --- | --- |
| 事件改变状态与画面 | W1 `drainEvents()` 只累计事件，场景来自硬编码参数；注入后没有事件驱动的状态提交 | 在 Pharos 真输入链完成事件 → 共同事务 → 新 owner → accepted 文字画面。受控断开处理器时验收必须失败 |
| 纹理实际使用 | `w1gpu.c` 的纹理支路要求 alpha 参数为负，现有场景调用未进入 | 显式覆盖采样支路与像素，再在正常编辑器的共同图片节点消费 PNG；分配出纹理不等于画过 |
| runner 准确报错 | 畸形 `[exit=…]` 被当 0；传输异常伴部分成功正文也可返回 0，指导 RED 已复现 | exe → PowerShell → worker → host 的唯一真实退出码链；缺失、格式错、超时、截断具名失败；用确实返回 7 的程序做全链负控 |
| 有界执行与回收 | `Start-Process` 只打印 ExitCode、不显式传递；同步读管道可能卡住；worker 每批启动且无限重连 | stdout/stderr 均有界收集，连接／任务／关闭有截止；3 批共 12 个轻任务核对自有进程与窗口不累积，结束按 PID／实例回收 |
| 资源证据 | W1 shutdown 把计数直接清 0，不能证明零泄漏 | 正常创建／释放点记账，覆盖部分初始化失败及 5 次开关编辑器；debug layer 可用时附 live-object 原件，不可用就明示，不伪造 0 |

集中更正旧报告中的范围，不重做整个 W0：VendorId 十进制 `88099906` 对应十六进制 `0x05404C42`；原 `1,000,000,007` 小于 `2^32`；`cjpm run` 行为不能直接外推到 `cjpm test`；原 Int64 负控在最大值 `+1` 时抛溢出，另用一个不溢出的错误期望证明断言汇总确实非零退出。截图颜色一致不等于同帧完整像素相等。保留 W1 真正的正控数据，不把这些修正变成整包的主要工作。

## 五、整包实施范围 A–F

### A．同源构建与 Windows 框架入口

拟建 `runtime/cjgui/platforms/windows/` 和产品 `apps/pharos_mark_windows/` 的薄装配，名称可按现有组织调整，不能另建第二个业务编辑器。Windows 构建显式选择共同源码与平台实现；当前主 `cjpm.toml` 含 AppKit／Metal 链接选项，不能原样照搬。

优先直接依赖共同包；工具链需要 staging 时由脚本从正典源码生成、带输入清单和 SHA，所有共享修复回正典，不能长期手工维护第二份 `text_session`／DocumentSession。Windows 专属实现放平台目录。正常入口必须从干净产物目录完成同步、构建、DLL 闭包检查与运行；不靠上次残留 DLL、手修生成清单或一串未归档临时命令。

保留公共签名和现有 POD 的意义。不支持的平台服务返回具名 unsupported，不以永远成功的 stub 通过构建。碰到不可分离的 macOS 硬绑定，抽出最小平台边界；先做影响分析，不能为 Windows 把 E/H 正在用的契约重写一遍。

### B．正常自绘窗口、排版与输入通路

接通窗口创建／关闭、消息泵、焦点、键盘、鼠标点击／拖选、滚轮、resize、DPI 和按需刷新。框架接收事件后在真实 owner 通路裁决；原生回调不持有另一份业务正文或执行自己的 Undo。

DirectWrite 持留布局绑定内容、样式、可用宽度、DPI 与 accepted 版本。命中／caret／选区查询必须取对应版本的同一布局；失效就重建或具名重试，不混用上一帧几何。字体回退、UTF-8 字节 ↔ UTF-16、代理项、组合字符和字素导航不得用“每字符固定宽度／每个 UTF-16 单元一步”替代。

D3D11 的纹理、字形和图片必须有预算、缓存键、引用及设备代次。空闲不持续全量 build/layout/upload；caret 闪烁可以按需提交，但不应每次重排／上传正文。普通窗口和 GPU 生命周期用真正的生产路径，不长期留在 W1 `w1_*` 实验接口。

### C．现有 Pharos 的正常编辑与预览

本包先复现 **UTF-8 文档不超过 256 KiB 的正常写作范围**。复用已存在的容量准入机制，打开及人／Agent／Undo／Redo 按同一结果长度规则裁决；超范围具名拒绝，禁止截断加载或丢数据。这是本包验证范围，不是把共享编辑器永久限制到 256 KiB。

正常窗口提供打开／新建、源码正文、保存、撤销／重做、预览切换等已有动作。支持中文和含空格路径、LF／CRLF 原字节保留。复用现有样式和呈现描述；平台菜单、快捷键及文件选择器可适配 Windows 习惯，不为移植重做首页设计。

源码面做到插入、Enter、Backspace/Delete、方向移动、Shift 扩选、非空选区替换、上下导航、滚动后编辑、焦点往返与光标闪烁。Markdown 预览复用同一解析器与 SourceMap，至少实际显示标题、段落、强调、列表与代码块。源码中段非空选区 → 预览 → 返回，正文零修改；安装确认后免点击输入精确替换原范围，再 Undo 完整还原。

源码／预览共用同一个文档实例；不把预览字符串重新导入为正文。直接在 visual 呈现面编辑是下一项扩展，只有主链全绿且仍可推进时再接现有 `editor_surface`；只读预览绝不能报告为 visual 编辑通过。

### D．系统输入法接现有会话，人的事务与 Agent 共用

将 Win32 普通文字和 IMM32 组合生命周期接到现有窗口拥有会话；平台只给正文范围、preedit、选区与终态。确保 RESULTSTR／WM_CHAR 等相邻通路不会重复提交。组合期间不提前写 owner；提交恰好一笔，取消零笔；组合开始于非空范围时冻结该范围。系统候选位置取同一 accepted caret。处理失焦、会话换绑与旧事件退役，复用已有恢复／草稿机制。

用来宾当前已安装系统输入法做一次真实组字提交和一次 ESC 取消；若需要改变输入源，按身份记录和恢复。缺输入法／系统回调时如实列出具体环境边界，不能用 `SendInput(KEYEVENTF_UNICODE)` 注入成品汉字代替 IME 验收；独立的普通输入与框架生命周期测试继续。

公开连接至少实际消费发现／context、同版本范围读、带版本修改、Undo／Redo、保存以及 owner／accepted 读回。Windows 传输必须复用现有协议解析、授权和串行 owner 队列；调用可以由来宾内真实公开客户端发出，避免无必要地暴露到其他网络。

完成“人修改 → 脚本 Agent 通过公开协议修改同一 owner → 人免点击续写”。外部改版后按现有 ChangeMap／锚点契约恢复或具名拒绝，不能吞掉输入或插到错误文档。脚本客户端和真实模型调用分开标注；本包不以额外调用模型充当技术闭环。

### E．图片和异常恢复服务于编辑器

让正常 Pharos 窗口中至少一个实际使用的共同图片节点走 PNG → WIC → 共同准入／缓存 → D3D11 纹理，可使用现有产品资源或界面图片；不为此另造 Markdown 图片语法或专用展示应用。覆盖非对称小 PNG 的像素／alpha、裁剪、换图、坏 PNG 和超预算拒绝，拒绝保留此前有效资源。图像 oracle 独立于被测 shader／解码结果。

处理 `Present`／`ResizeBuffers` 的设备移除或重置错误，记录原因，终结旧设备代资源，重建并根据当前 owner 恢复画面；失败有界，不能不停自旋。按[微软设备恢复说明](https://learn.microsoft.com/en-us/windows/uwp/gaming/handling-device-lost-scenarios)核实 Windows 桌面接法，不照抄 UWP 宿主。

允许通过测试闸在真实错误处理入口注入一次失败，证明原 owner 不丢、旧资源不复用、恢复后继续编辑；明确是受控故障，不能写成真实驱动掉线。夜间不执行影响整台来宾的强制 TDR、禁用显卡或重启用户虚拟机。候选提交失败保留旧 accepted 场景；已提交的业务 owner 不因 GPU 失败回滚，也不能谎报已经呈现。

### F．冻结一次、完成真实写作链和可复现交付

受影响针对性检查通过后冻结一份源码输入，从含空格目录的随包源码构建最终 x64 Pharos，运行下表。应用、native DLL、共享包、客户端与数据夹具的来源和 SHA 对应同一轮；构建后的源码再变就只重做实际受影响链。

运行探针是验收辅具，最终应留下可由用户正常启动的编辑器、构建／运行说明和独立测试数据。不能只交一段自动自关闭程序。

## 六、固定验收门：证明现有编辑器在 Windows 消费

| 项目 | 本包必须取得的事实 |
| --- | --- |
| 正式入口 | 来宾中干净产物构建成功；应用及自建 DLL 为 x64；包含中文／空格路径的文档从正常入口打开；画面确由 CJGUI 自绘 |
| 人类输入通路 | 使用来宾 [SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput) 经系统队列投递，核发送数、目标 HWND、实际焦点及到达事件；至少一笔输入导致 owner 与可见正文精确变化。PostMessage 仅能标消息级证据，不能覆盖本项 |
| 范围与 Unicode | 中段非空选择后替换，owner 按冻结源跨度精确匹配；覆盖代理对、分解重音及一个多标量簇的移动／删除，边界不切坏；一次明确编辑意图恰一笔，纯选择零笔 |
| 组合输入 | 系统 IME 可见预编辑、提交与取消；分别核 owner 的零／一／零事务和完整字节。普通注入与系统组字分开留证 |
| 源码／预览往返 | 同版本预览的实际画面；无编辑往返后非空选区保持，免点击首笔替换及 Undo 全文还原；不能只核末尾 caret |
| 人／Agent 共同操作 | 同一实例、同一 owner 的人→公开写→人；全程请求／回包、版本与完整 owner 字节对应；过期版本、非法范围／越界容量拒绝后版本和正文保持 |
| 保存与复开 | 保存成功回执后检查真实文件完整字节；正常关窗，再由同一最终二进制打开，新的 owner 完整字节一致，重开后还能输入 |
| 几何与生命周期 | resize、最小化／恢复、滚动后的点击、选择、输入仍在正确位置；DPI 受控检查标明方式，未做物理跨屏就保留边界；失焦不误写，关闭后旧回调不访问退役窗口 |
| 图片与失败 | 正常编辑器图片实际采样显示；坏数据／超预算保旧；受控设备错误走真实恢复入口，owner 保持且恢复后继续编辑 |
| 响应与资源 | 一轮至少 20 笔公开读／写在编辑器实际滚动或预览工作期间完成，记录是否真的交叠；输入→owner／accepted 的 p50/p95/max、实际样本数、RSS、build/layout/upload/submit 原数分别报告，不把 IPC 回包当显示完成 |
| 空闲与回收 | 失焦静止至少 10 秒核不空转；聚焦闪烁单列。3 批 worker 与 5 次编辑器开关核自有资源回到基线；旧窗口／用户进程不在清理范围 |
| 同源交付 | 含空格源码包可独立构建，清单逐项核实；测试退出码贯穿到底，必需原件写入失败不能仍返回 PASS |

夹具与期望由冻结的原始字节及明确编辑跨度计算，不能拿当前 owner 自己生成自己的预期。IME 的多键组字按一次提交意图计数；普通逐键输入按实际事务契约分开核对。模拟故障、系统合成输入、物理人手输入是三种证据，分别标明。

这些是本包功能门；不要为了“全绿”删除失败腿或反复改等待时间。性能如实报告当前虚拟 GPU + x64 模拟环境，不外推物理 Windows 机器，也不从 W1 出图推断 16ms 已通过。慢点先定位最大贡献与可复现负载，不能让一个未定性能问题阻塞所有独立功能。

本包不要求 macOS 的 1GiB／全部 visual 结构编辑／全部生成式面板／UIA 与讲述人／物理多屏／安装签名发布同步完成。这些继续属于目标能力，未实现就留在后续，不拿初包成功宣称三端完全等价。

## 七、疑难处理与咨询规则（2026-10-08 校准）

原 Pi→GLM5.3 默认路由、自动升级 Sol/Astra 的表格及 CLI 模板已撤销；已发生的咨询材料和答复仍作为历史证据保留。现行规则统一见 [AGENTS 独立咨询入口](../../AGENTS.md#independent-model-consultation)，不自动调用 Pi/GLM，也不自动改用其他顾问。

执行者先查 CJGUI 现有机制、仓颉技能、SDK 与相关本地参考实现，结合最小失败和真实版本做可区分实验。已有裁决前提没变就直接落实。普通问题两次实质修复无进展或核心机制首次实质修复失败后，停止继续猜改，把精确事实、已试假设和原始结果交指导；只暂停实际依赖部分，独立工作继续，不因换模型清零累计失败。

只有用户当前明确要求咨询或下发的当前任务明确指定咨询及模型时，才按该授权做聚焦只读分析；更晚的“不咨询”指令优先。不得借旧模板、请求文件或工具就绪记录恢复调用；答复仍须用反例和正常编辑器消费验证。替换固定平台路线、引入外部 GUI 运行时、另造编辑器或改变数据模型，仍需把事实、备选、代价与建议交指导，不能自行改变目标。

## 八、执行节奏与最终报告

先把控制通道变得可信，同时厘清共同源码与平台边界；随后连续完成框架与编辑器接线，最后做一次冻结版本的集中消费。等待构建或已明确授权的咨询时推进其他必要工作。已有有效绿色证据按影响复用，不重跑无关 H、E 全套，也不接着扩 H round18 验证器。

桌面、同一构建 target 与高风险共享文件串行使用。只收回本包拥有的实例、worker、端口和临时数据；不批量杀 WindowsTerminal／conhost／explorer，不关闭用户编辑器或虚拟机。若操作剪贴板，开始前重新核实有效备份，恢复前核序号，用户已改动就保留现值并如实报告。

在现有状态文档中只短更 Windows 当前状态，保留 E/H。完整原件建议集中到 `artifacts/windows-pharos-20261005/`，一个证据索引关联源码清单、构建、输入、协议、owner、文件、截图、错误／恢复与成本，避免每天再建一套治理台账。旧 RED 原件不覆盖。

最终集中回答：

1. 现有 Pharos 在 Windows 实际能做什么，正常启动命令及可运行产物在哪里。
2. 本包复用了哪些共同模块，新增哪些 Windows 适配；是否产生必须回归 E/H 的公共改动。
3. 上述固定门逐项 PASS／FAIL／BLOCKED／NOT_RUN，附最终二进制身份与原始证据，不只报测试总数。
4. 人→Agent→人和保存重开的完整字节／版本，以及范围、组字、失败保旧的判别结果。
5. 当前环境下的成本原数、最慢环节和未证明的能力；不按代码行数或咨询次数宣称进度。
6. 自有资源清理和并行写集保护情况；未完成项给出具体原因和下一落点。

交付完成前保持连续推进，不把每个 A–F 小节另拆成等待用户确认的任务。若到达真实依赖阻塞或需要改变固定方向，报告该问题的最小材料和已完成部分，不能把整包改名为完成。


### 2026-10-08 W r5 实施接续（进行中）

以 r4 的 120 文件完整冻结清单为基线，仅纳入 W 的恢复接缝及新增共同接收契约；r5 为 121 文件。未吸收 live E/H 整树；正典源码里的并行改动保留，未 stage/commit/push。新恢复契约将完整载荷交产品持久化 sidecar、字节读回后 ACK，失败留在原槽，不向当前正文重放。共享 `cjpm build --skip-script` exit 0。

已保留 F1 发布/通知 UAF 的 RED、GREEN 与撤回负控，F2/F3/D/关闭接收的真实 native 反例及 GREEN；九个受影响探针按分批原件的并集通过（并非同一运行全九项）。P8 已运行并检查节点、场景和精确 byte 5 两端事件各一次。新 worker 先作业绑定再开启动门；正负控检查继承管道的后代责任，新 worker SHA `923e6edd05ba307d037bbc59bf377aa1398501c192799b1d89b33a055a163ed4`。当前 worker 又运行三批各四任务，六个继承标准管道的自有后代均由对应作业回收，资源原数见本轮 runner JSON。

r5 仓颉输入捕获 BC `ac9703ce73658bad981c1fbe8efe99dc1f49665c772bd10da0beb27185d03052`，Mac 同 SDK/目标参数 obj `64bcfc15abc4226d76ada3ef53aa249188474c342730c8b0fde17abaed3430e0`；来宾正式链接 exit 0，EXE `a282a219f964ab892bfa82817e811e91787bd2c7fbdd5721b9ecefcaa57a21fb`。捕获时驱动真实 AV 与预期 capshim 终止分别保留；最终链接并未沿用其非零结果。SDK 两份 llc 原 SHA 已恢复。r5b 后续只修改 private native（PNG/device/失败诊断），仓颉输入、ABI 与 BC 不变，正在同哈希准入后重链接。

普通 PNG 节点原来确实返回 unsupported，已留下正常 prepare/场景/真实像素 RED；新增 WIC 有界文件解码、16 槽缓存、CPU/GPU 各 32MiB 预算及现有 flight 租约中的图片引用，坏图与超尺寸拒绝保旧。设备恢复探针经同一 Present 失败分支注入受控 RESET HRESULT，真实释放并重建 D3D/交换链/纹理，窗口身份保留，失败帧未 accepted，PNG 像素读回成功；这不是物理设备故障证明。产品 PNG/恢复的正常消费仍未验。

正常产品首轮 `097ebf14a7c140f1ae048785f0794d49` 验证默认逻辑 1100×780（实际 client 2200×1560，DPI 192）、中文/空格文件、真实 Markdown 与单次 SendInput 模式按钮；切源码后 `CJGUI_SCENE_REJECTED reason=internal_error`，accepted 无正文 107，链停在该处。正对新场景失败层做诊断，不加点击、放大或慢打救绿。完整主链、Unicode/系统 IME、滚动/resize/焦点、20 笔重叠请求、idle、五轮 editor close/reopen、最终可启动交付仍未完成，不将探针/构建成绩写成整包完成。

参考复用：本地 GPUI Windows `dispatcher.rs` 的异步 runnable 所有权仅用于对照线程责任；CJGUI 同步结果/超时 hold 仍按自身命令信封收口。`text_system.rs::layout_line` 对照几何缓存输入；颜色纹理与来源授权保持各自门。`directx_renderer.rs::resize`（先解绑目标再 ResizeBuffers）及 `recreate_resources` 对照设备代次重建；CJGUI 在同一 HWND 保留 owner/accepted 语义，丢弃 GPU 代次。框架 Mac `CjguiPrepareComposableImageResourceOnMain` 对照 path/id/version 身份、已绑定纹理保留；Windows 用现有 WIC 和有限同步缓存，不引入任何外部框架依赖。

原件：`artifacts/windows-pharos-20261005/evidence/20261008-r5/`；当前常驻 runner `ce74c33878ce4bcb9942920ec5460ede`（旧 worker `fc856ac678f448d286a6635b1856efa4` 已 BYE/socket closed）。F1/F2/F3/D 旧 RED、harness 设置错误与真实失败原件均保留。


W r5 当前 D 升级（2026-10-08）：正常消费首次失败已归因到候选复用契约：真实 native `r5-reuse-red` nonce f9efa3b34d3b4f20820d034cba3b5749，abc+[0,3) accepted后，configure2＋相同runs＋geometry、跳过未变正文，Present=33、candidateRunsPending=1、accepted仍1。正常产品 r5c e46a1e829…/PID6932源模式缺107；开启frame trace的新实例 PID及完整日志见 accept-run-fdeecd0d80454176bf31d89b0808c28d，raw status33经现有状态名兜底显示internal_error。此前native INTERNAL_ERROR诊断为空符合该码，并非native错误静默。Pi deepseek-flash只读指出未映射状态路径，实际根因由生产反例验证。新配对门修复误拒了共同窗口有意复用的节点，计入本轮公共契约首次正常消费失败，按AGENTS提前升级，未继续猜改。已向用户提交有限方案：在Present边界将pending声明和保留的同一候选正文/绑定校验准备，再维持runs先于新body、真实越界保旧、相同几何lease保持的三种反例；等待指导裁决，只暂停D依赖。PNG像素在正常产品窗口已可见；首两次采样harness分别把Shot日志误当路径、把前沿click点误当中心，原件保留，正在独立验证正确中心采样/idle/五次正常关闭，不把这两次称后端修复失败。


W r5 独立消费与收口补证（2026-10-08，D 裁决仍待回复）：r5c EXE `e46a1e829a5cdf542fac722b7cb75300a90767bbe286bed68089d96aa0c6b753` 的正常 PNG 及五轮正常关闭最终运行 nonce `577cbcba56c742159b98ed8cc50f59cc` exit 0。普通产品共同图片节点实际屏幕采样：左 A255/R255/G0/B0、右 A255/R0/G255/B0；这不是专用图片应用或硬编码 shader。聚焦预览静止 10s：进程 CPU 0.1875s、handles 304→304、threads 12、RSS 84,054,016→71,106,560 bytes、frame 始终1。它覆盖聚焦只读预览静止，尚不能替代失焦静止和源码 caret 闪烁门。五个新 PID 3344/16644/11372/11436/8036 均由系统 Alt+F4 四事件正常关闭，预持有内核 process handle 读回 ExitCode=0；未覆盖编辑保存重开。旧 ExitCode 空值失败是 PowerShell process 对象读法问题，原件保留。

实际模块核验 nonce `52648ba0ac9b4aa1b0295837ddaaee10`：PID19200 主 EXE 及非系统 `libcangjie-runtime.dll`（ca65f2b8…）/`libboundscheck.dll`（07b33dd3…）均 PE machine0x8664；完整路径、bytes、SHA 位于本轮 `r5c-dll/dll-identity.json`。两份 SDK llc SHA 均1ea68362…，正常关闭内核退出0。该身份是已构建的r5c，不拿它证明随后native改动。

又发现并补齐两条原范围内的遗漏支路。`ResizeBuffers` 的受控 COM 调用错误 RED nonce `c93fe00bce8b471bafc862d7069c5c6e`：RESET只返回internal_error、没有恢复责任。修复让其进入既有graphicsRecoveryPending，物理resize事件仍返回，消息泵同UI线程重建后才把事件交回应用；GREEN `9136bacfea654f318f182e752876ae28` 验实际代次2/3、同HWND、旧accepted保持、真实纹理重建、后续正文准备/呈现。它是受控HRESULT，正常产品resize/device后续编辑仍待D门。无存活pump的public destroy旧分支绕过接收ACK，RED `05fd39cccd9f4b2ebe50cbb4a7df2cb6`；接回同一个destroy_proc预检/资源释放后，GREEN `0e8d2fc8c2354ceeb17fbc577f91ec08` 保留完整Q/binding9/request100，精确ACK后才退役，普通关闭接收/重复ACK/live waiter一并通过。它覆盖已冻结恢复记录，未据此宣称所有半代理项/待后继组合态的关闭恢复已验证。

r5d完整121项从r5c复制，仅native实现变化；manifest SHA83a41e447dcf66b9c26562173f560bef4b21ef8c2de01c218c34620109b6ce67，完整源ZIP SHAbe18a71487b4d348a0730199027aa689609b6d00dc18fa3db66a9911efe3b0a1，native ddfa1f49…。Cangjie/foreign ABI/flags与已冻结BC/obj不变，正在正式准入重链接。写作验收脚本另修正真实Markdown code fence、初始owner与预冻文件完整字节一致、两次正常关闭内核退出0、必需日志上传失败必须非零；finally失败负控 nonce `0561023318194efb828d2a06a15bd21b` 即主体exit0也由worker读回exit1。主链尚未重新运行，因为D方案未获指导回复。


W r5d 正式链接与容量接线（2026-10-08）：nonce `7dc7c1cb09d144e9917a0e0e9480378c` 正式build exit0，native archive d734cfbbf1b717fef045ce186ddb2b37c349b39e1cd57496aeec4fc5cf7afa22，EXE e72ea9ca4fe1ecb3e6c3047e956913f8aa0305ccd484ca7d843f28e5b3bb2ba1；仍是同r5 BC/obj，SDK恢复。独立公开拒绝门 nonce `3a51e583f27643d3a4a2d725d3913172` 实际PID20100/owner v1/258016bytes：wrong-version→version_conflict、越界→invalid_range、UTF8内部→not_utf8_boundary，均全文/版本保旧；容量负控50,000-byte有效追加却被接受成v2/308016bytes。这是产品未启用已有owner.configureContentCapacity的真实RED，不归因D。

Windows产品现已补有限配置：正常controller采用/换绑和额外CLI文档服务配置262144bytes，初始/额外打开以同一捕获的session字节长度拒绝超范围，失败显示具名notice且不截断文件；最近文档拒绝时保留原活动owner和恢复提示。shared DocumentSession本身的默认/签名不变，非Windows私有helper为空/允许，未把共享编辑器永久限到256KiB。W冻结的同步journal重放前先给捕获session配置同一准入，不让历史绕过结果长度。live E已改为异步恢复，正典只在它已有blockPendingRecovery接缝前配置，未将旧同步流程覆盖回去；本轮W不吸收该E变更，canonical异步恢复与Windows容量组合尚未作为W消费证据。

r5e 捕获nonce `73401a749305451f946a388fbb4ec61f`，BC c01f7f18…；原始driver日志nonce `384eb6cce2394efca0e26a839aa55caa`明确为capshim exit94（不是这次真实AV），该输入后来补充了pre-journal接线，故不用于最终obj。r5f完整121项，main SHA49cf75a8a36f0ba57880a9c635528d56986bd676280ad16d190cb03acf174b17，manifest SHAfbc00c295189d2a9ebcd51a81635341a93bcb740f018061b09a811f578ae76a1，源ZIP SHAe9e0795a176a67b18ef8f87e377c65b1fb80b208fa703815377e5b2d9b5cf469。正在重新捕获/生成匹配obj；没有拿r5旧obj覆盖新的Cangjie输入。容量GREEN与超范围打开/原固定门待实际r5f运行。D配对裁决仍待回复，未改该门或重跑依赖它的主链。


<a id="windows-r5f-handoff-20261008"></a>

### 2026-10-08 W r5f 汇合原件与 D 待裁决（本节为最新状态，整包未完成）

本轮通用机制改动在原 A–F 范围：dispatcher 完成/通知/回收同锁发布；输入与导航整条载荷成功转移才出队，冻结 IME 的提交/后继更新分别结算；恢复记录由完整公开读取、产品 sidecar 持久化读回后 ACK；排版与 GPU lease 复用保留。Windows 增加有界 WIC PNG/D3D11 真实采样、同 HWND 设备代次恢复，以及 ResizeBuffers 设备丢失到消息泵重建的交接；无 live-pump 关闭复用公共关闭责任路径。产品仅在 Windows 正常写作入口配置已有 owner 的 262144-byte 上限、打开拒绝保留原 owner/文件。恢复/PNG/关闭尚未全部被正常编辑链消费，不能统称责任全部收口。正典 E 新异步恢复流程已保留；本包冻结的旧恢复流程在日志重放前配置容量，不能用本包证明 E 新异步恢复与 Windows 容量的组合已验。

r5f 正式混合构建 nonce `894b26aa5f4a495a80f24e038708cf97` exit 0。121 项源清单逐项复核零失配。以下是同一冻结关系：

| 原件 | SHA256 |
| --- | --- |
| 完整源 ZIP | `e9e0795a176a67b18ef8f87e377c65b1fb80b208fa703815377e5b2d9b5cf469` |
| 121 项源 manifest | `fbc00c295189d2a9ebcd51a81635341a93bcb740f018061b09a811f578ae76a1` |
| app main | `49cf75a8a36f0ba57880a9c635528d56986bd676280ad16d190cb03acf174b17` |
| 新 BC | `32576c52863f9b8e45df77bac2beb9ad4863906fc73b0ce3a660068defac8c0e` |
| Mac llc x64 COFF（exit 0） | `2dd3916d114c547d96a3312732b4525b657bafcd48eb2126cc55ccfaf41e636a` |
| Windows native 实现 | `ddfa1f49d4aedc26266a8114ce2ce2478b0c820bce5784dfc30d7b1c9326c1ad` |
| native archive | `d734cfbbf1b717fef045ce186ddb2b37c349b39e1cd57496aeec4fc5cf7afa22` |
| r5f EXE（23,487,488 B） | `508cba991c5e9220dc3a8459c4a8c9bc7660d2effc816c0bbd1213ad91611c12` |
| 实际加载 runtime DLL（1,276,416 B） | `ca65f2b82121a0587e03203314fc723724058d59d42391aa1e19b3eb69463b27` |
| 实际加载 boundscheck DLL（44,032 B） | `07b33dd3de22489b442cc32f0fe8ddfc80b753443b17fb2053133b2e7ffb6c78` |
| 可独立启动候选 ZIP | `2f70f9c8702c7fa45e621a62ece2e4d16fe4fd39258844197ceb6b7ddb147bd3` |

新 BC 捕获 `07dbf439519c4c8e8f913f0d261d425c` / raw driver `6e6ac695865b40cd803a810b23faee4e` 明确是 capshim exit94，不是此轮真实 AV；正式构建另有真实 exit0。Cangjie 输入改变后生成了新的 BC/obj，未复用 r5 旧 obj。SDK 原版 llc 与 llc-real 双 SHA 均为 `1ea683623104335fe503b5c603e70faaaf14517c31672fa35a6b3b7f8580c770`。

独立容量消费最终 nonce `1bf285e713f44babb93b8d6ef4a35fbc` / PID12464 / exit0：v1/258016 B 旧版、越界、UTF8内部及有效50KB超限写均具名拒绝、完整正文和版本不变；合法4128 B追加精确到v2/262144 B，一字节再追加拒绝保留v2；公开 Undo 精确v3/258016 B、Redo精确v4/262144 B。原 `bf01ec63332a4e5ea27253f83865a10c` 失败回包为 invalid_parameters，验收漏传要求的一个文档目标；之后 `6e54933fa5124850972244eca7e0c092` 是公共HEX字段解析只允许小写的脚本误红。两份原件保留，最终从 GET_CONTEXT 的 sessionDocumentId 配对实际 owner 后携带 ID 调用，未修改 owner/公共契约、未降全文或版本标准。正式写作脚本亦已修同一目标与明确 APPLIED 判据，D 未裁决故主链未重跑。

超范围正常打开 nonce `57ffd986a480421194e3d1fd1e2cf39b` / PID3100 / exit0：262145 B 中文/空格文件原字节/hash不变，保留 pharos-untitled v1 的预先从该版 sampleArticle 源字面冻结的922 B完整正文；正常Alt+F4退出0。截图显示未命名文档，不能据此宣称容量拒绝通知全文可见（当前顶部状态区截断）。同实例三个非系统模块均 PE x64；两 DLL 完整实际路径/hash在 `oversize-open-b66ecded71c744528de5e5f35d236e02/identity.json`。

PNG 有限 GPU 读回补证：alpha nonce `8febcb09687144919cdc38986112a90f`，128/64 alpha在白底为 (255,127,127)/(191,255,191)，opacity0.5仅一次，父裁剪外白、换图蓝、坏图保旧蓝，关闭纹理实计归零。Pinned aggregate budget nonce `7862a93a33274f9da61f126f675dd180`：第二幅16MiB RGBA超过32MiB CPU总预算，真实 PNG status28、failed3，CPU16798421/GPU16777216 B不变，旧accepted/旧像素保持，关闭资源归零；此前两次为探针误用TEXT预算码/不存在枚举的原件，不是PNG后端改动。正常产品不透明PNG屏幕采样仍复用 r5c `577cbcba56c742159b98ed8cc50f59cc` 原证；坏图/预算/恢复后编辑的正常产品组合门仍未验。

候选可启动包 nonce `929ada90041f477dbc197eb6fef55db7` / PID5300 / exit0：仅系统 PATH，从含空格候选目录启动，中文/空格文档完整 owner42 B匹配；三个实际非系统模块全部来自包内，正常关窗0。来宾保留路径 `C:\cjgui-windows-w1\delivery\Pharos Windows r5f candidate ec731d7f3f954730b5a299a63a062b75\Pharos Mark.exe`；双击或 `"Pharos Mark.exe" --open "中文 含空格路径.md"`。Mac对应文件在 `artifacts/windows-pharos-20261005/delivery/Pharos Windows r5f candidate/`；候选 ZIP 在本轮 worker 的 `r5f-portable/`，说明明确整包未验，不作为最终可用编辑器交付。

同 r5f 候选 EXE 五次开/关和失焦预览 idle nonce `6b75fa45530c4c538d5c367a65d528af` / exit0：PID14644/16132/13500/16428/14380，各系统Alt+F4四事件、内核退出0；handles初值308/309/309/309/309、threads10、RSS约82.5MB。第一实例用自有WinForms辅助窗一次系统点击取得真实前台，Pharos失焦10.0490358s、CPU0.125s（单核1.2439%）、handles308→308、RSS82665472→69812224 B、frame1→1。它是失焦只读预览，不替代源码caret闪烁或编辑生命周期。旧 `052d271cfbe14e68b753c8cf2d2665b0` 是 SetForegroundWindow 被系统拒绝、`a856c2b19a23436d82e2f815fd2e5d4b` 是 MatchCollection 负索引误读；最后先以已留实际日志验证非负 Item 索引，再测真实失焦间隔，不重投编辑救绿。

原固定门汇合状态（截至 r5f；子项PASS不关闭整门）：

| 原固定门 | 状态 | 已验与尚缺 |
| --- | --- | --- |
| 正式入口 | PASS | r5f含空格同冻结正式build0，EXE/DLL x64；中文/空格正常入口与自绘accepted窗口。构建是来宾捕获→Mac llc→来宾链接 |
| 人类输入通路 | BLOCKED | 单次系统模式按钮/P8具名局部原证保留；当前D导致源码107未accepted，尚无正常字符的owner＋可见全文闭环 |
| 范围与Unicode | NOT_RUN | 正常中段非空/代理对/分解重音/多标量移动删除未完成；native来源/P8不替代此门 |
| 组合输入 | NOT_RUN | 已安装IME环境核对保留，真实预编辑/提交/取消及0/1/0 owner事务未完成 |
| 源码/预览往返 | FAIL | r5c源模式raw33，107 missing；重复runs＋保留旧正文被D误拒，完整往返未通过 |
| 人/Agent共同操作 | BLOCKED | r5f真实公开写/完整读回、拒绝保旧、Undo/Redo子项PASS；人→Agent→人免点击连续性未验 |
| 保存与复开 | BLOCKED | 同最终二进制保存全文→正常关闭→新PID一致且能输入未完成 |
| 几何与生命周期 | BLOCKED | ResizeBuffers device-lost及无pump close RED/GREEN/撤回负控PASS；正常滚动/resize/minimize/focus/旧回调编辑组合未验 |
| 图片与失败 | BLOCKED | 正常不透明PNG像素PASS；alpha/裁剪/坏图/aggregate预算/恢复有限native证据PASS；正常受控恢复后继续编辑未验 |
| 响应与资源 | NOT_RUN | 原至少20笔真实滚动/预览重叠、owner/accepted p50/p95/max和工作原数未完成；不以公开回包替代accepted时延 |
| 空闲与回收 | BLOCKED | 同r5f失焦预览10s＋五次关闭PASS，3×4 worker含六个继承管道后代回收PASS；源码caret闪烁及全部输入责任/资源终态仍未完成 |
| 同源交付 | BLOCKED | 121项清单、新BC/obj/hash准入、正式build0、无SDK PATH候选启动、必需上传失败负控PASS；最终正常写作尚未通过 |

D 当前准确升级仍为 `f9efa3b34d3b4f20820d034cba3b5749` 生产反例：accepted abc+[0,3)，下一候选重复runs、保留未变正文，Present33、pending1、accepted1。有限建议是在提交边界仅将 pending runs 与同一保留 candidate 正文/绑定共同验证/准备；仍覆盖新 abcdef+[0,6) 先runs后正文、真越界保旧、复用几何/lease、样式颜色/字体/DPI失效。按 AGENTS 第一次公共契约实质修复失败后的升级规则，已提交用户待裁决，未进一步改D、未自动调用其他顾问。收到裁决后先跑这组区分反例和撤回负控，再按native-only准入复用匹配r5f BC/obj重链接，首先进入默认1100×780正常小文档整链，随后原固定门；不要从r4重做或吸收整棵E/H。

其他具名留开：关闭时 pending IME successor/半个高代理的完整恢复来源未证明；PNG诊断texture探针仍stub，失败状态没有缓存，不能以资源诊断全0宣称全部机制真；一般图片aspect mode实现尚不完整；Styled run纯颜色复用未获新运行证据。以上不改名为已完成。测试数据全部属于本轮独立目录，后续测试显式PHAROS_DATA_HOME；当前worker环境HOME/DataHome确为空，旧最近记录按各自工作目录的相对路径解释，未读写用户记录内容。runtime_state.cj/cjpm.toml仍零Git差异，E/H并行正文保留，未stage/commit/push/切分支。最终worker/SDK回收原件下段补记。


最终自有资源收口（D 仍待裁决，目标没有标完成/暂停）：nonce `1572c779d51a4e99980edeaf8ef6b8f7` exit0，worker PID19876最终 handles570、threads17、private83517440 B，自有build目录应用零残留，两份SDK llc双hash原版一致；runner session `ce74c33878ce4bcb9942920ec5460ede/session.json` 已读回 `closed` / `BYE_AND_SOCKET_CLOSED`。runner总退出1包含所保留RED/负控/工具误红，不代表最终正式build或关闭失败，也不能把此runner整场写为全绿。Portable候选目录保留但应用均已关闭；VM/用户窗口未清理。Mac候选ZIP另保存在 `artifacts/windows-pharos-20261005/delivery/Pharos Windows r5f candidate.zip`，SHA与上表相同。两仓相关diff --check通过，正典native与r5f同SHA，runtime_state/cjpm零Git差异；既有针对性/build原证按影响复用，未再重跑无改动整套。已授权Pi deepseek-flash快查使用的答复与运行证据分开保留，没有调用其他顾问或启动子代理。


<a id="windows-r5g-close-successor-20261008"></a>
### 2026-10-08 r5g：pending IME 后继的关闭交接（有限原件，整包未完成）

独立于待裁决D，生产 `handle_windows_ime_composition` 已将 RESULTSTR 提交入队、COMPSTR 复制到 pending successor 后，冻结槽已释放；旧关闭预检仅收冻结槽，phase A 随后释放 successor。`r5-close-successor-red` nonce `a512c54e37564d1b8b31bd76987388ce` exit2：普通关闭及恢复容量恢复后的关闭均未留下恢复责任。单独高代理通过生产字符解码入口后，没有 owner event/恢复载荷；正常 destroy 清理解码状态而未伪造 U+FFFD，两个断言PASS。本地 GPUI `events.rs::parse_char_message` 的独立 surrogate 暂存用于区分未完成UTF-16解码态与完整UTF-8载荷，仅作机制参考，没有引入依赖。

正典renderer现将后继的字节数、cursor、input/binding/request/composition身份与副本一起冻结；即时IME取当笔冻结来源，deferred replay取原条目字段。关闭预检把尚未投递的 marked update 转入已有 kind2 / COMPOSITION_UPDATE 恢复记录；不打包已提交RESULTSTR，不写owner；转移失败保留完整原件，成功后清副本并等待现有v1精确ACK，再进入phase A。没有新公共API或恢复kind，产品原接收方仍保存完整opaque sidecar/readback后ACK，不对当前文档自动重放。

| 区分原件 | 实际结果 |
| --- | --- |
| `43c373310f9c41c8b161559c6b8fa687` | six有限cases exit0：普通/满容量关闭、half surrogate、原C successor压力、no-pump关闭、v1接收/ACK；并非系统IME正常消费 |
| `8ec5c34dfa324ade93f0ada7a189fa08` | 三个关闭case exit0：普通、满容量、malloc复制失败；全文`next`、cursor2、binding9、input1、kind2、phaseUPDATE精确读回，current binding10不被拿来补旧来源；重复关闭不重复commit或恢复 |
| `f76c516fc2ae4ad5a9614bddca0116a6` | 实际defer/replay后关闭 exit0：原request100在current request200、binding10时仍读回100/9，完整字节/ACK/退休恰一次 |
| `40b15ba10d2a416694002e7653c4b5c7` | 只撤回关闭的successor转存调用，三个case exit3重新RED；隔离负控源没有覆盖正典 |

以上原件在 [本轮worker results](../../artifacts/windows-pharos-20261005/runner-sessions/09d0b7b4a4d547169e2d3e75be6d18d7/results/)。用户授权的 Pi deepseek-flash / low 只读快查 exit0，答复保留在 [flash-close-ownership-answer.txt](../../artifacts/windows-pharos-20261005/evidence/20261008-r5/flash-close-ownership-answer.txt)；答复不作为运行证据。没有调用其他顾问/子代理。

r5g从完整r5f复制，121项逐hash零差异错误，只更换renderer一项；其他仓颉输入、foreign/公开C签名/ABI及代码生成flags保留，所以BC/obj复用。正式nonce `3120eb0bbcb146218918ad27fc5e4284` 实际 `cjpm build --skip-script` exit0（244.104s），新native编译/归档后才链接；新BC捕获仍精确匹配旧准入，不重跑llc。成功消息已放到非零构建退出检查之后。

| 当前身份 | 完整SHA256 |
| --- | --- |
| 正典/冻结native | `403c2e9373a774a7dfa6e923e000286191c0b26bb2a13487fad39c56460f2403` |
| [r5g源清单](../../artifacts/windows-pharos-20261005/staging/Pharos%20Windows%20r5g/source-manifest.json) | `ff20f9c5753d1099e3fb846e82030526fa3f7bde3c303b80152b9c151fafcc52` |
| 完整源ZIP | `63a30bbf48172d9a47af8c942dc32cdb7c19bd77ecf27d229b8b8af35b424a87` |
| native归档（460118B） | `92fa8c5b801c642ddee1364be8516fb1901c967b3deaeb69e665701039d069b3` |
| BC | `32576c52863f9b8e45df77bac2beb9ad4863906fc73b0ce3a660068defac8c0e` |
| obj | `2dd3916d114c547d96a3312732b4525b657bafcd48eb2126cc55ccfaf41e636a` |
| 新EXE（23488512B） | `c6ca45d4e0c49217e3c26234965e6e46270494c2bdf39fc6bfc1aaa806250eca` |

新EXE在 `C:\cjgui-windows-w1\runs\r5\Pharos Mark Windows Source\apps\pharos_mark\target\release\bin\main.exe`，本轮没有启动它做正常窗口消费；可独立启动的现有r5f候选ZIP保持原身份，不能冒充新r5g或最终通过。正常系统IME/连续写作/回调组合及pending successor的presentation-conflict/换绑定消费仍未证明；half surrogate有限取消不关闭正常Unicode整门。原固定门及D暂停原因继续按[上一汇合](#windows-r5f-handoff-20261008)，D无新源码改动，也没有用顾问答复替代指导裁决。

最终audit `7c036f099cd84aa29961f58f27f7ea32` exit0，来宾121项源hash零错误，native/归档/新EXE读回与上表相同，自有build应用0；SDK llc/llc-real均原版 `1ea683623104335fe503b5c603e70faaaf14517c31672fa35a6b3b7f8580c770`。本轮worker PID12992/session09d0b7b4a4d547169e2d3e75be6d18d7 已BYE_AND_SOCKET_CLOSED；其runner退出1包含保留的RED/撤回负控，不能写为整场绿色。相关diff --check通过，runtime_state.cj/cjpm.toml仍零Git差异；本轮仅W native/验收材料及这三个既有状态文档改变，未改产品E/H、未stage/commit/push/切分支。原goal仍未完成，等待已提交D裁决，不将本次有限关闭交接升级为全部输入/资源责任收口。


<a id="windows-r5i-successor-source-20261008"></a>
### 2026-10-08 r5h/i：后继来源、重试和逐笔验收（整包仍受阻于D裁决）

上一goal轮是实际进展：r5g关闭交接及正式构建已完成。本轮独立核对了r5g具名未证明的successor边界。生产反例 nonce `723e53bf7f734de2a3de83f8cd00a6a0` exit5，分别证明presentation-conflict直接丢副本、恢复容量满仍丢副本、新binding/同epoch新target可收到旧marked、首笔UPDATE分配失败后走CANCEL并使副本不能恰次续送。后面三个case使用真实640×480 D3D/DWrite renderer/UI dispatcher、实际focus/owned声明、真实handler提交/Present匹配和事件出队；`aRc`是按fixture提交预期声明的accepted正文，**不是Pharos DocumentSession owner或真实系统IME/SendInput成绩**。负控中destroy拒绝的自有native进程由本轮job回收，不算正常应用关闭成绩。

修复继续在Windows private holder内：捕获原node/resource/kind；重放前核原binding与目标身份，失配转既有kind2/UPDATE恢复记录，容量失败仍保副本；presentation-conflict同样走完整恢复，不再free掉副本。首笔UPDATE失败保留该次新composition的deliveryId，后续仅同一来源/目标/同deliveryId可重试，不重复begin/CANCEL/RESULTSTR。局部重试仍使用原`source_install_gate_holds_input`：覆盖IDLE与保留MARKED两路，安装门存在时不入队，生产取消结算后才续送。这是落实原来源门规则，不新增公共授权/恢复协议，也没有改D候选或通用状态机架构。

| 原件（本轮session `b5a3a8ff50914a499ece0fed7ad81e84/results/`） | 结论 |
| --- | --- |
| `08f4217bb57a44a6bd9f64a817210f75` exit0 | 五个新边界＋原关闭/容量/复制失败/defer-replay/C后继压力，10 cases全部通过 |
| `d22bbc9e595a4d2d9d8622bde56eb394` exit5 | 隔离源仅恢复r5g的finish/start两个旧routine，五个新边界重新RED；保留新字段/capture与绿色close预检，没有覆盖正典 |
| `b61f92b52c3e482694537d21ee8e569b` exit1 | 工具误红：验收误用不存在的`set_source_install_pending_impl`，编译未到运行；不计生产修复失败 |
| `b4b96d20f0e64af9bb5203cf14863ad8` exit1 | 改成实际`set_source_install_gate_impl`后，真实request101待决期间保留MARKED重试仍送入UPDATE的生产RED；r5h因此只是中间构建 |
| `59622d1c4f8440b186b6e751c18c104d` exit0 | r5i将原门检查接回重试，10 cases全绿，含待决拒送→生产cancel→exact one UPDATE及原来源/关闭回归 |

Pi deepseek-flash/low只读快查本轮exit0，原件 `evidence/20261008-r5/flash-successor-retry-{request,answer,stderr}.txt`。顾问只核原门接线，没有讨论/裁决D，没有改码/运行桌面；答复不作运行证据。

**逐笔验收已接线，但正常链仍NOT_RUN。** 正常写作脚本此前连续系统输入只核最终全文；现固定动作前/后完整owner字节和版本，公共snapshot→分块read→snapshot核每块版本/offset/count与终端documentId/版本一致，支持256KiB，拒短读/变版/换文档/零进展/坏UTF8，空文档可读。真实输入仍一次原节奏SendInput、无逐字慢打/重发/新增等待。动作前后真实`.pharos-journal`必须只追加；SUM、SEQ、VER、human来源与单个实际splice逐笔核验，字节范围须精确等于冻结caret加既有输入前缀，插入须为下一个完整scalar前缀。每步重建全文再与冻结原文＋独立预期前缀比对，最终版本/完整owner双核；可接受合法合笔，不强迫“一scalar一事务”。新增typing前后原owner bin、日志与元数据在失败前保留，finally按原字节上传，上传失败仍拒绝本轮成功。

最终脚本SHA `f886b96e31dd6641ddf7eac54f8923ff048158a580f5ac89a4dd4c37cb5f158c`。`53926553b2034bb1a5e5205d40e78501` exit0：完整PowerShell AST/C#实际编译；Python按冻结codec独立生成checksum的13个oracle正反夹具＋10个只读协议fixture通过，含完整72004B多块CJK/emoji、空owner与按具体原因拒绝。**这些是验收工具fixture，不是正常应用读写或逐笔owner已验。** 前序 `f713d766f11444f6befb19dc9b049594` 是把无BOM UTF8直接ParseFile导致错误，生产worker实际用UTF8 BOM写task；显式UTF8 ParseInput通过。`4a82b2aa6a8245c99ee22ddb42be79e7`/`76279dac68d54821951351d1aa5fb424` 是fixture的PowerShell if管道把byte[]展开/空数组变null，非reader生产故障；显式byte[]赋值后，`125bbf7f088845689dd80b87dd76ff04`和最终原件通过，并逐一核拒绝原因，未把未触达判据的旧“负例PASS”采纳为最终证据。

**同源正式构建。** r5h `a02ecea115a04fcc936f6164c67d09f6` exit0、EXE `d7b95a04…`（234.631s）是加入原安装门前的中间版。最终r5i从完整r5h再改这一个native门检查，121项清单零hash错误；仓颉/foreign/ABI/flags不变，正式 `7ecf49e5855c4ded9e85bee5bf463a1f` `cjpm build --skip-script` exit0（192.311s），实际BC捕获仍与准入相同。未重新运行Mac llc，未吸收live E/H。

| 最终r5i身份 | SHA256 |
| --- | --- |
| 正典/冻结native（665711B） | `39b535f1d39085feaa92f39d31be5f6237ef56499d1a97313f22834666f70f62` |
| [121项清单](../../artifacts/windows-pharos-20261005/staging/Pharos%20Windows%20r5i/source-manifest.json) | `ad0f6c01873b7018ad268b3fe6ba66a8672128f933203b4155b53a23abfc34bd` |
| 完整源ZIP | `8b663dfc95f9a4f666232a9322bbfdacfbc145ef49d0bcd90373fa9b247ba0f4` |
| native库（460546B） | `bf196f9ed656c00196de03b3f997363ba957279aaf2421467bdc9788e095ca9b` |
| BC | `32576c52863f9b8e45df77bac2beb9ad4863906fc73b0ce3a660068defac8c0e` |
| obj | `2dd3916d114c547d96a3312732b4525b657bafcd48eb2126cc55ccfaf41e636a` |
| 新EXE（23488512B） | `be754458ad8fc92fe9fa991f885dd42305b1df5cf1e49e5359e9f223c4fca68e` |

实际新EXE仍在 `C:\cjgui-windows-w1\runs\r5\Pharos Mark Windows Source\apps\pharos_mark\target\release\bin\main.exe`，本轮没有启动它做Pharos正常消费或更新portable；现有r5f候选保持原版本，不能混称r5i/最终可写应用。全包门仍按[12项汇合](#windows-r5f-handoff-20261008)具名保持：Source/preview已有D失败；正常输入/选择恢复、人→Agent→人、保存重开、真实IME/Unicode/resize/focus/晚回调/设备恢复后编辑、20笔实际重叠性能、完整资源终态和最终包均未完成，不能拿本轮有限10 case、fixture或build绿替代。

**当前受阻审计。** 同一D指导待答已跨三个连续goal轮：r5f独立交付轮、r5g关闭轮、本r5h/i来源轮；后两轮均实际完成独立必要修复/自验，并非只重述状态。当前没有live构建/worker/advisor。正典D的configure/text_runs/set_node/Present四个routine逐字与r5f相同，原 `f9efa3b34d3b4f20820d034cba3b5749`（重复runs＋跳过未变正文→Present33、pending1、accepted1）及正常source107未采纳归因未被新C修复覆盖。AGENTS公共契约首次实质失败升级及指导给方案的要求仍适用，已提交的有限D方案尚无用户/指导回复；自动goal continuation不是裁决。独立必要项已完成到本轮可验证边界，剩余正常主链/固定门/最终交付依赖D，当前执行者不能继续猜改D。原目标完整保留，等待指导裁决后先做同候选runs+保留body/绑定的有限正反例，再按native-only准入重链接→默认1100×780正常完整链→原第六节；不要重新r4/整树E/H或无限补探针。

最终audit `821244d15d3a4c42921a5e08824ce3f6` exit0：121项来宾源hash零错误，native/库/EXE读回同上；自有build应用0，worker PID7592（handles627/threads15/private83795968B）已BYE_AND_SOCKET_CLOSED，原SDK llc/llc-real双SHA `1ea683623104335fe503b5c603e70faaaf14517c31672fa35a6b3b7f8580c770`。runner退出1含RED/负控/工具误红，不称整场绿色。相关diff --check、公开C签名不变及受保护路径扫描通过；runtime_state/cjpm仍零Git差异，产品E/H未由本轮修改，无stage/commit/push/切分支/用户资源清理。没有将goal标完成或自主暂停。

<a id="windows-r5j-d-execution-20261008"></a>
### 2026-10-08 r5j D裁决实施：有限门通过，接正式链接与正常消费

用户已恢复原A–F整包，D不再等待确认。从完整r5i的121项冻结源建立r5j，只更新Windows native，不纳入live E/H；125个公共C入口签名不变。configure克隆的节点/正文/POD身份由私有保留资格记录；nodeId/resourceId/kind/epoch没有独立setter，显式node/body setter重新stage。独立semanticId/bindingKey setter成功换身份时退役保留资格（bindingKey按共同窗口完整operation/field身份定义）；semanticLabel/parentRowKey等说明/层级更新不退役。Present编码前只取本configure代声明和本candidate，在临时clone上核完整范围/预算、保留本代已提交geometry并调用原prepare_scene_node_text；成功才换入，未从最新accepted/IME/owner补来源。原安装门、runs-before-body、显式新绑定/body以及失败保accepted保留。

当前worker session `4bc684dc0296405c91811723b39d6693`、PID3908，原RED `e437a2e4023048288ac0995767368a20` exit3：重复runs/未变正文、清旧样式及semanticLabel复用失败，原新正文双序/布局颜色字体宽度DPI门仍绿。GREEN `99a60e3f35624728b2c2a61de4ae7884` exit0：5 cases（reuse-runs、pair-retained、pair-identity、pair-order、layout）全过，含实际DWrite字体清除、范围/非法scalar拒绝、分配失败保旧和后续合法候选、显式新绑定/body。三份隔离源撤回负控均翻红：配对步骤 `6f27cfce5fc949108abbcbc1229684a0`、身份门 `6cace7dfe70d47a297d88c6781bb6008`、范围门 `cf6556416a3e4cbd9e06e742b619799b`（各exit1）；未覆盖正典，原r5i及历史RED保持。以上是生产函数的真实640×480 renderer/dispatcher有限门，不是正常Pharos/系统IME接受。

r5j native `026d73c9f5fa52f152678d6306dd07f73a4b249376295753f282dff1113f78af`，清单 `413b83782bf27f35b77ff9751e5c4de9d021c7382f11e5fe1584ac799577c7c5`，完整ZIP `80769b2d844d0d9244af76f2a06d60e4b0c88d92ba43777b018f4028f4c01bf5`。来宾正式relay已排入同worker；须实际BC32576c52/obj2dd3916d/flags/ABI准入、exit0和SDK恢复后，立即跑默认1100×780原完整正常写作链及第六节余项。此刻新EXE/正常链未验，不称原包完成；不咨询外部模型，不stage/commit/push，E/H保护。

正式首轮 `9e1ef200fd294c3b89a00d3bad7f79a0` exit46：实际捕获BC32576c52、obj2dd3916d注入匹配，native库791f30ec…；`cjpm build --skip-script`返回-1073741819，没有新EXE，SDK双原版hash恢复。读取/上传失败原件 `6765308cc7664c00b59fa74e58308c88`；Windows Application/1000事件 `31c712f2ebbe433597c1edd87307f1ff`明确cjpm.exe PID0x3658在SDK libcangjie-runtime.dll偏移0x12e608发生0xc0000005，不把受控BC捕获终止或D renderer有限绿色当作本次构建成功。按既有r3指导允许的有界复试，原冻结source/flags/哈希准入不变，仅一次retry1在同worker进行；若仍失败先定位工具链，不能无限重跑或采用旧EXE。

有界正式复试 `dfd02c7899c44aba888578c093d42442` exit0、230.478s：真实 `cjpm build --skip-script`成功，捕获BC32576c52/注入obj2dd3916d准入相同，新native库 `6c02700778e78fb6fa6477e7f00148c4c5861e5079eb8707576fc67e4f0dd64b`，新EXE `9fcbe2d1aff419e42946e2d6a88da79e627672f1fa0417945a3b96d801a13c1b`（23490048B），SDK原版llc恢复。首轮失败不改名通过；本次新增成功是独立运行原件。`writing-r5j.ps1`先核该新EXE完整SHA再运行现有逐笔/full-owner验收，已立即排入同worker默认1100×780正常链。只读输入法清单 `7521f31d87f94ac58ab49094d3b78d17`读到HKL8040804/F0E50409，但Get-WinUserLanguageList属性为空，不能从该清单声称真实组字已验。


<a id="windows-r5k-keyboard-escalation-20261008"></a>
## r5j 正常消费与 r5k 键盘升级（2026-10-08，D 已闭合，原包仍执行）

r5j 正式 relay 的 `dfd02c7899c44aba888578c093d42442` exit0 已核：native `026d73c9…`、121项清单 `413b8378…`、实际BC `32576c52…`/obj `2dd3916d…`、native库 `6c027007…`、EXE `9fcbe2d1aff419e42946e2d6a88da79e627672f1fa0417945a3b96d801a13c1b`（23,490,048B）。第一次正式构建的真实SDK AV保留，单次同输入重试才得到成功；不能用成功覆盖失败原件。SDK llc 双原版SHA恢复。

随即运行原正常写作脚本，仅追加该EXE身份准入与r5 run根，默认1100×780未变：nonce `319481b2893f48d091a6b6227d1c587c` exit32，实例PID10604/HWND25887750，run `accept-run-9373abc56b9345b98b92d1c0156a82c7`。D不再拒绝源码107：正常中文/空格路径116B全文打开、公开同版全文读回、真实SendInput源码按钮及正文focus成功，caret62/v1。Ctrl+Home后13次Right未到期望13，实际仍62，`middle_selection_exact`失败；尚未输入正文/保存/复开。初始Markdown截图 `01-opened.png` 已查看，列表/斜体/代码块真实渲染；带BOM标题的字面`#`保留为当前范围，不能称全部语法呈现完美。失败stdout、owner读协议与截图在同session guest-results中，自有应用已由finally/job回收。

**新的键盘修饰失败按AGENTS升级，D无需再确认。** 真实renderer/UI线程、实际前台窗口，单次8项SendInput后经生产WndProc冻结与raw分发：原GetAsyncKeyState的Ctrl+Home和Shift+Left均flags0，RED `59b6eaf1b849417da7da9b0922f0ade6` exit1。首个实质修复改GetKeyState，`c8e8ef15a3fd4c9bb055816a3f477e69` exit1，Home=0x40000而Left仍0；这个修复只有Ctrl有限绿色，不能称修饰输入全部完成。Microsoft [GetKeyState](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeystate)定义消息队列取出时的状态，是该尝试依据。

只读诊断 `213d296ffff84305badabbec16631610` exit1显示：Shift-down(lp1)后、Left-down前出现额外Shift-up(lp c02a0001)，Left后又有Shift-down(lp2a0001)；准确原始序列在该nonce stderr。使用MapVirtualKeyW＋SCANCODE的区分对照 `01ddc64b3a9b46aca34922863c46cf8b` exit2也失败，且Home缺失。原虚拟键投递是合法API用法，不能归咎“scan0必错”；目前不能断言来源是模拟器、宿主用户、IME或AttachThreadInput。依AGENTS“核心…状态归属…第一次实质修复失败后，停止继续猜改，整理证据向指导升级”，已提交下一项可区分实验/方案的指导请求，没有第二次猜改、没有咨询。待区分：额外Shift转换发生于系统投递/键盘布局还是线程输入状态共享；应以同一burst的投递序列、目标、队列和到达事件判定，不重投或慢打救绿。

不依赖Shift的共同导航缺口继续实施：原窗口35事件没有Ctrl+Home/End消费者，text_session增加四个文档首尾移动/扩选意图，经原bound/composition/version/prepared/alignment门和真实document-edge判定处理；局部窗口不能假冒文档边界，纯选择零owner写。共同窗口沿原pushOwnedPlainSelectionToProxy接线；保留现有方向anchor和原来源/安装门，只插入相关块，未覆盖E/H整文件。公共C ABI未变；Cangjie枚举为新增变体，API沿README现有experimental等级，原handlePlainIntent签名不变。34项冻结源均可编译；实际共同窗口消费仍须新的完整Windows构建和正常运行。仅Ctrl+Home/End，本次未声称裸Home/End视觉行导航。

Mac isolated cjc测试只验证共同会话契约：冻结r5k的34项CJGUI生产源＋原Fake owner夹具，两项RED→GREEN（撤掉处理块为intent_unknown；实际完整镜像扩选锚点/零写、局部镜像at_window_start/end拒绝均通过）。原件 `evidence/20261008-r5/document-boundary-unit/{red,green}-{compile,run}.log`，编译各0，运行1/0；撤掉document-edge门的第三个负控编译0/运行1，只使局部镜像测试翻红，完整正文正控仍绿；不占live cjpm target，不当Windows/IME/正常写作证据。夹具reserved-word编译误红保留，未计生产修复失败。

完整r5j冻结只纳入native修饰首修与上述两处Cangjie块，r5k仍121项，清单 `c4e7c92288f9681a3bc80b17e44b1d8ce01b9212010b0be26f7fa14b89722311`，ZIP `2a19ea7ac898833267560f8570b179f1dbac690839b8ff369f007d5897fd0656`。相关Cangjie输入已变，禁止直接复用旧BC/obj；同worker3908正在重新捕获。此次r5k是待验候选，Shift仍RED，不是最终可写交付。原正常主链与第六节系统IME、Unicode编辑、往返/人Agent人/保存重开、真实20笔重叠及终态资源仍未完成，portable仍旧r5f候选。runtime_state/cjpm和产品E/H保持，未stage/commit/push。


r5k 捕获终态：nonce `36a59d7a58124e5f9fab467acc105b40` job exit0，198.915s。真实cjpm capture build1由capshim对app llc预期退出94导致（日志已核），不是AV/最终build。新的共同CJGUI源在捕获流程中编译，app单元BC恰与旧值32576c52…相同，已回传28,568,992B；相关输入变更仍按任务要求重新运行Mac llc，不以一致哈希跳过。SDK两副本原版恢复，原日志/BC在同session `guest-results/.../r5k-bc/`。r5k正式build尚待完成。


捕获后的实际共同包产物读回 `b74b0d6e689c4c01a8de4ec9edf365b6` exit0：应用target内 `cjgui/cjgui.cjo` 9,070,624B/SHA9ed28506…，`cjgui/libcjgui.a` 9,166,048B/SHA21f99cfd…；并非runtime/cjgui自身target。前序错误路径检查4ac5b15d…是工具路径误红，保留，不计为生产机制修复。r5k正式relay将再次记录实际共同包/native/EXE身份。r5k清单同时修正前序三份已改源码遗留的size元数据；SHA均按真实冻结字节核对，没有借此替换源码。


Mac llc r5k正式终态：exit0，用时944.326s，输出新5,602,483B x64 COFF，SHA仍2dd3916d…；相同BC和完全相同参数的重编得到相同字节，原件 `mac-llc-r5k-{command,result}.json` / log。新relay manifest sourceSHA是本r5k的c4e7c922…，已排队正式 `cjpm build --skip-script`；不拿捕获build1或同旧obj哈希代替最终build0。


r5k首个relay工具准入940dad28d4204a439edae354e11d0efc exit1：执行者复用r5j脚本时遗漏旧native/MF上传文件名，使源复核在text_session处拒绝；真实build/SDK交换尚未启动，不计为生产机制实修。按r5k两份Cj＋r5j native组成的精确121项混合身份先核对，再恢复r5k四份上传；976815cb5cd4414d8e1eb8f01c00c9a2 exit0读回R5K_SOURCE_RESTORED files=121。正式relay已移除旧上传，源哈希未放宽；随后重新排队。失败原件保留。


<a id="windows-r5l-range-prefix-20261008"></a>
## r5k 正常连续输入 RED 与 r5l ACK 来源修复（2026-10-08，原整包接续）

r5k 正式 `7b1c39575fa14aa290f81945e892c360` build --skip-script exit0，用时199.181s，EXE `a601ab546995cfeee3fb1c32079314008eb605565c5f2dc3ceabffdf66ba5600`（23,494,144B），native库 `309330d9…`，共同cjo `9ed28506…` / archive `21f99cfd…`。实际BC32576c52…匹配刚重新生成的obj2dd3916d…；原SDK恢复。完整产物身份在同session `r5k-build/product-artifacts.json`。

正常 `8b676a0c2a9b4962aa510354d456b6dd` exit32，实例PID16720/HWND34144516，默认1100×780。Ctrl+Home现在真实到0，13次Right精确到13，中段定位已通过；单次TypeUnicode28项发送全部成功，13个scalar应组成WINCHAIN-01中😀，实际全文只多W（owner116→117B，v1→2）。日志首笔applied/settled，后缀为 `installed_range_prefix_mismatch`。run `accept-run-65144491a5a84185a87f374ba2024cb0` 的正常日志、截图原件保留；fixture与失败journal通过179fadc674d34eb3859b95f67d44e131 exit0补取，journal只有一条真实human事务，源跨度byte31:31、insert57。没有保存/复开通过，没有用重发救绿。

**失败归档口径修正：**旧r5i记录称typing前后原件在失败前保存，源码实际全文断言位于保存之前，本次失败只保住日志。当前验收脚本将before原字节先于投递保存，after原字节/meta/journal先于原全文断言保存；C# oracle、发送数、选区和期望全文判据未放宽。r5k该次after完整owner readback的内存结果未落原件，不能事后把journal重建称作当时全文读回。补取journal脚本一次PowerShell数组拼接误红f5b5c520…及有限probe原型编译误红1292d421…保留，不计生产机制实修。

根因来自Windows installed-range旁带：`observedAckSeq/Version`已捕获，但claim时`sourceEndByte`用含待决输入的preBody长重算，与共同`CjguiInstalledRangeChain.observedAckMatches`要求的该ACK来源跨度不同。已核现有共同连续前缀测试及macOS捕获/ACK更新实现；参考只读，不引外部依赖。私有修复保留根basis与共同门：ACK成功时更新私有acceptedSourceEnd，每条input与observedACK同时冻结sourceStart/End，claim只读本条冻结字段；不借最新accepted/owner重建、不重盖场景、不改C ABI。

真实renderer、production WndProc/raw/owned queue/claim/ACK，系统Unicode XY一burst与稍后的Z一burst；owner ACK为有限夹具手工值，不是Pharos owner或系统IME证明。原RED `c1b21731ccc64f729dfea4ea85364f6b` exit1：seq2 observed0/v1却source20:24（应20:23）；seq3 observed1/v2却20:25（应20:24）。GREEN `3cd80576e5c5419ab810f8697dc81f11` exit0同数据精确成立，3条载荷释放。撤回capture `4c97dfd7480f4ee5988b2d1545d8f70a` exit1恢复两个来源错配；撤回ACK端点更新 `d31e3a5d035f4b6cbffc9de3e46a85df` exit1只使观察ACK1的后继来源翻红，旧ACK0仍正确。原件均在同session results/。

完整r5k121项只替换此native，r5l native `c836415f810b6e19622b49d47feaf53171616a723ee8181eb8d841a662e5f203`；MF `87fce42920d7029be0a304ea00498eeb633288778b8579ae84822426abbf87fa`，ZIP `a027ad976b10abb1da7c992b546ceb358af04d4d1ec60f60abdae8539ba7c3cd`。Cangjie/foreign/ABI/flags与r5k未变，复用本轮刚编的obj，正式relay已排队，仍要求实际BC准入与build0。随后同默认正常链；Shift指导待答保持，未实修第二次。语言清单nonce a9c1f83055544f16ba06e2bd7cfe70e9 exit0实际zh-Hans-CN/TIP81D4E9C9…FA550B04…、preload00000804，不等于已证明预编辑/提交/取消。主链/原第六节/最终portable仍未完成，E/H/产品写集、runtime_state/cjpm与Git保护保持。


r5l首个正式构建ab0acae8201b4869b98b539858fa8fe0 exit46（258.140s）保留：native库fad21db3…与实际BC/obj注入准入正确，真实cjpm退出-1073741819。cb6f42b1664246999bde30d916b4c155 exit0保存原log/inject/manifest与Application1000记录1078：SDK cjpm.exe PID0x3F74，libcangjie-runtime.dll offset0x12e608，0xc0000005；与r5j同类SDK事件。SDK llc原版恢复。按原r3已授权一次有界同输入重试，不重新诊断已解决的app llc阶段，不改生产；retry1还锁定并复用fad21db3…已编native库、原wrapper/obj，121源全部再准入。真实build仍须0，不能由正确注入覆盖AV。

r5l单次同输入复试 `2275b96cc65941ffa245858ca42a50cf` 正式build exit0，227.664s。实际BC32576c52…/obj2dd3916d…、native库 `fad21db3b9a9b33b6bfa56c6a6687e5bfb7071e2cae70598ee04a8f03b6a2621`（462,218B）、共同archive21f99cfd…/cjo9ed28506…与准入一致，新EXE `12073933f1ca52555a851c325abf1ecb7ebc266cb409bca31044b0d87f3726df`（23,494,656B）；SDK恢复。完整原件位于同session `r5l-build-retry1/`，首轮AV保留。

立即正常消费 `d97ddb23f6be4e1db907eb3f884a2f8a` exit33，34.105s，默认1100×780（实际2200×1560、DPI192），PID9520/HWND20190200，run `accept-run-8ae42c0b520f477189757a9a6224adec`。Ctrl+Home→13次Right精确到13；连续 `WINCHAIN-01中😀` 系统输入28项全部投递，13个scalar形成13笔human事务，owner v1→14、116→134B。逐笔journal范围/版本/checksum/合法scalar前缀与最终完整owner均通过；另由Python按冻结原文UTF16前缀13＋token＋后缀独立核完整二进制。`02-typed.png` 已查看，实际源码中ASCII、中文、emoji可见。typing before/after全文、journal、meta均在失败前落盘并上传；此次是正常Pharos输入接受，不是手工ACK夹具。

随后Shift+3次Left投递8项全部成功，但实际caret27→25→24→23，选区仍[23,23)，期望[23,27)，`frozen_selection_span_mismatch`。代理对Left跨2 UTF16、中文跨1的零写移动可见，不能据此声称非空选择/簇删除已完成。此失败仍是r5k已升级的Shift修饰问题，未进行第二次猜改；D不再阻塞。预览往返、免点击替换、Undo/Redo、人→Agent→人、保存/正常关闭/新PID重开尚未进入，原整包仍未完成。自有PID9520由finally/job按身份回收；portable仍r5f候选。继续独立系统IME及原第六节必要边界，Shift依赖等待具体指导。

<a id="windows-r5m-system-ime-20261008"></a>
## r5l真实系统组字与r5m呈现接续（2026-10-08）

独立正常系统IME运行 `ef466731f827470f9fc5fe5b72e303c9` exit0，32.425s，仍是r5l EXE12073933…、默认1100×780，PID1860/HWND34280570、UI thread13352，run `accept-run-a39dbf23ba064a9b952e1ecbff5dc0e2`。仅对自有窗口Post WM_INPUTLANGCHANGEREQUEST选择已安装HKL8040804（环境设置，不是文字输入证据），读回准确；原HKLF0E50409在finally准确恢复，未加载/安装/重置输入法。实际Ni四项SendInput、Space两项、第二次Ni四项、Escape两项，各只投递一次。现有diagnostic开关只增加日志preedit_hex，不改变owner。

完整owner/版本/journal及共同composition相位验证：第一次n→ni在UTF16[13,13)、byte[31,31)、v1的同一claim，owner116B不变、零事务；Space提交“你”仅一笔human事务byte31:31→e4bda0，v1→2/116→119B，claim退休；第二次n→ni冻结UTF16[14,14)、byte[34,34)、v2，Escape后composition_cancel、owner/journal保持v2/119B。全部before/preedit/commit/cancel-preedit/cancelled原bin/meta/journal已上传，Python从原文UTF16前缀13独立计算完整期望再核五份readback。工具最初C#跨Add-Type引用失败f6c4327c…保留，修为同一程序集内SendInput helper后5bae05e9… AST/C# exit0；未计为生产修复。

**上述绿色只关闭事务腿，组合输入整门暂未关闭。** 原截图真实显示系统拼音候选、提交正文及取消后保正文，但正文内未见ni预编辑，候选栏落在屏幕右下，未绑定插入点。Windows WM_IME_COMPOSITION冻结/入队后直接return0，既未自绘preedit，也未转系统默认IME窗口；source输入面没有产品绘制的caret声明，旧declare_input_caret不足以设置位置。对照共同settleOwnedCompositionDecision、原DWrite插入点查询及只读GPUI Windows retrieve_caret_position/update_ime_position；系统默认组合窗职责核[Microsoft WM_IME_COMPOSITION](https://learn.microsoft.com/en-us/windows/win32/intl/wm-ime-composition)。不引GPUI依赖，不生成候选或补输入引擎。

r5m私有适配：在真实UI WndProc START前用同一accepted节点/资源/种类、已安装选择和保留DWrite布局定位系统composition/candidate；安装待决、焦点绑定不符及无有效布局不借坐标，零选择/owner副作用。冻结原始IME载荷仍走原共同来源/相位；preedit显示交默认系统IME窗口，RESULTSTR及其结果元数据不转显示路径，owned WM_IME_CHAR不再产生第二份字符提交。系统IME仍负责组字与候选。原正常UI失败为RED；消息级真实renderer有限position RED `21120f026f204efaa4cd09021478c0ed` exit1（两个坐标0,0）→GREEN `fe4ef8fdea874ab9bc8749dbafddd253` exit0（DPI192、accepted点30.176/20.000/26.602→composition60,40、candidate60,93），两个失配负例/零选区写/正常destroy同时通过；该有限门不替代真实系统组字截图。

完整r5l冻结只改native，r5m121项清单 `a976156f7764ab041c76b2713d0e7095d183218e9964d81c674f26f639194936`，native `2eb84ea1d5d206b26b58ebab203633507a00193a79ed8f5f93c1e7ad679d8741`，ZIP `f0f32b22c929a48e24caf0d7e5257264694682d31a0cd357e3e0e8408b2246f2`。正式 `c4f171fb81754cb6a869b8774c624350` build0，175.070s；实际BC32576c52…/obj2dd3916d…匹配、无新llc，native库e0a7c433…，新EXE `3c2f0f39cf948f1848118129ad147ac1b78f9edc2aeba5fd7921776e47a30acf`（23,497,216B），SDK恢复。立即在此正常EXE核系统预编辑/提交/取消与其后连续Unicode；并准备独立20笔正常预览/系统滚动中的公开读写。Shift仍待原指导，未第二次实修，原整包/最终portable仍未完成。


**r5m正常汇合原件（整包仍未完成）。** `12370de63cba4dcf8a70e12baeddbf38` exit44，PID13064/HWND78058608、run `accept-run-abb22dd20ac34e719127da391f90e694`：系统n→ni/Space提交你/再次ni→Escape的零／一／零事务保持；截图已查看，ni现在显示在冻结插入点，候选栏紧随该行，系统默认预编辑字体仍偏小。随后免点击连续WINCHAIN-01中😀投递28项，却零owner写、v2/119B保旧，不能称IME后续写已通过。首次periodic日志只见后缀`installed_range_sideband_invalid`。原EXE仅打开已有逐笔诊断的区分运行 `055a946c1fc64fc5ba42168250aec152` exit44，PID7388、run `accept-run-07374d0c3af549a29d43e88282a7eb18`，定位第一笔seq1/nonce1/proxy1/base1/owner_before1为`version_conflict`；实际owner已v2，后缀才关闭。不是投递失败或事件scene错配。冻结源码中`carriesInstalledSource`误用macOS-only的跨选择能力门，Windows未走已有普通来源基线安装/回执，所以AUTO只恢复选区而保留旧v1。正典仅将该门改为已有`internalRendererSourceRangeSupported`，Mac路径不变；Cangjie输入改变，下一版须重新捕获/编译，不能借旧obj证明。原RED保留，尚未声称新修复通过。

独立预览准备 `b18225415c29450695c875f293f10daf` exit45，PID3432/HWND48239788、run `accept-run-5279e2d318a94373b4b7fc9dda779aa7`，相同默认窗口、中文/空格路径5427B正文（SHA ce0b6abacb0d2a8fc8c0264697f66c9b46f0cecdf3440ebb512787ac19201f45），owner完整read通过，240解析片段/336runs/240呈现节点缓存存在，但scene/accepted仍0：`native_node_140_text_resource_budget_exceeded`。20笔公开请求和wheel尚未启动，均NOT_RUN，不能将工具退出写成20笔性能失败或减少文本救绿。native现有24MiB scene预算及整节点盒光栅化正在核实际尺寸/累计字节；r5n仅加原测试环境门控的失败候选实测，不改变预算/准入/owner。Shift原升级仍待指导；D已闭合，原固定门和最终portable仍未齐。


**r5n预算归因与r5o/p在途（2026-10-08）。** native-only r5n正式`0f68d4ecf00740799b0ccf1294e8b6a7` build0/179.547s、EXEa1353a7a…/SDK恢复。原5427B诊断消费`c99d3377125947e39892b35d5dbbeb12` exit45，PID11956、run accept-run-7e9987fe…：native实际节点1056，680×29/DPI192、文字实际232.884×24.003，已有纹理25,111,808B，cap25,165,824B/scratch0；共同进度的native_node_140标签与实际nodeId分开保留，不能据旧标签认定是大纲入口。明确原因是整节点盒和屏幕外片段纹理累计，未提高原scene/session/scratch预算。

r5p把光栅覆盖接回同一候选真实geometry/clip/viewport，DWrite正文/约束/排版租约不随滚动重做；无本候选geometry只延后纹理，不补输入来源。visible范围在原布局空间像素网格上加有限AA guard，实际Draw及run背景偏移一致，纹理按真实像素尺寸放回原坐标；隐藏节点只退休candidate持有的纹理，accepted/flight保留各自refs；两份替代纹理成功才换入候选，失败不晋升accepted。真实超预算继续拒绝。对照CJGUI macOS原CjguiComposableTextTextureRectForNodeWithText与只读GPUI DirectX atlas/sprite责任，不引参考依赖。

同真实renderer夹具：RED `2dbbdb12c62547d29e910b4154ff3e06` exit1→GREEN `6a5f73e9b2624e1b8211cf7957e7d484` exit0，240段落、16可见纹理/4,597,824B，geometry-only滚动保所有DWrite指针/lease、新可见文字实际光栅、旧隐藏纹理退出、真正可见超预算保旧、5000逻辑高段落中部有真实glyph、scratch归零/正常destroy。仅撤回visible覆盖 `fdb7cf30a52146b496483742048935fd` exit1。受影响配对/身份/runs-before-body/reuse/color/font/width/DPI/resize device recovery/IME position七case `ef62ed19ddfd4b0b8072b79d17a03f6f` exit0。实际CPU raster、immutable texture upload及live字节接现有private计数/POD，`e9a4509ff0eb4946a9739f9d97a7f104` exit0独立核16次/实际上传字节；成功CPU提交时长不当GPU完成时长。只读WORKLOAD复用原测试门，不写owner、不发frame、不改源准入。字段未支持的计数仍具名留开，不拿0作“零工作”。

共同门修复r5o只改变原121项中的窗口局部块。正式捕获 `7b8834f159594b25ab29035ef41c6673` exit0/212.585s；BUILD_EXIT1是capshim捕获的预期终止，非正式build通过。实际BC32576c52…/28,568,992B已上传、SDK恢复；本轮新Mac llc实际exit0、1062.910s，BC32576c52…/obj2dd3916d…与原参数一致，原件mac-llc-r5o-result.json；没有借旧obj。r5p已正式链接并正常消费，结果见下方r5q接续；没有吸收整棵E/H。Shift依赖继续等待具体指导，D已闭合，原整包未完成。

<a id="windows-r5q-writing-20261008"></a>
## r5p正常消费与r5q文件／滚轮接续（2026-10-08，原A–F未完成）

r5p正式`f2635ea784a94b628d8760ba4732632b` build0/212.672s，EXE `cdea6bce5f8e71be6df3b5aa2bfec4948e8fe83993acf5fe647ec5d5776feb5b`/23,499,776B，native库4aafd636…、共同CJGUI archive80c8be89…/cjo b78c27d8…；真实新BC/obj准入、121项清单9a18d77b…、SDK恢复。正常`608081df6dd44ac3a0c50b2d337b767d` PID12864/HWND27853934，run accept-run-7805f18098054e1684d9496cf84193f9：系统IME零／一／零保持；随后28项系统Unicode一次投递，13 human事务v2→15/119→137B完整精确。公开Agent在末尾追加“\nAGENT-中😀”，v15→16，当前AUTO id3/version16＋DONE sel28:28＋END installed后免点击HF-中😀五human事务，v16→21/最终161B全部精确。此前r5m version_conflict原RED保留，该普通来源门修复已获正常消费证明。

同次SAVE公共回复仅APPLIED true/reason=save_started。工具首版立即读文件而FAIL47；终结日志实际`PHAROS_SAVE applied=false persisted=false version=1 bytes=0 reason=candidate_sync_failed`，故同时存在生产失败，不能只叫工具误红。原文件116B保留，owner v21/161B保持；原失败/相位/完整bin/journal已归档。r5q工具等待同次围栏后的终结、要求persisted/version/bytes一致再比完整文件，不重发SAVE。保存／正常关窗／新PID重开仍待该版本消费。

原5427B预览已在r5p默认窗口accepted1、240片段真实显示，原24MiB预算未变。初次20笔工具`836ba027…` FAIL45在第二笔误查apply.version；真实协议为versionBefore/versionAfter。修正工具后`9350777be8314e07bc993d48d8aadc62` PID3724/run accept-run-28494cc3f63146378bc899331d174a38：10 read＋10 apply共20笔全文与版本v1→11、5427→5477B精确，80 wheel全部系统送达、前台保持，但真实accepted位置未动，FAIL不关闭滚动重叠门。实际23 raster/23 upload/3,866,560B、10成功present，live6,627,136B/peak7,283,648B、scratch0；这些工作来自公开写的预览刷新，不能冒充滚动工作或完整输入→accepted时延。

**文件最小反例与修复。** 原窄适配`f243866e8fcf4ec8bd5cbabea14591db` exit3：ACP936，ASCII readonly FD `_commit`拒绝(errno9/win5)，UTF8中文open失败(win1113)，MoveFileExA发布失败(win123)。同对象ReOpenFile写权限＋FlushFileBuffers实测成功；目录直接GENERIC_READ|GENERIC_WRITE/BACKUP_SEMANTICS的真实barrier也成功。修复既有foreign open/renameat的strict UTF8 wide API和raw-byte FD；目录仅为当前同步消费者获得flush权，CRT FD仍readonly。fsync先冲刷原对象，只有读权限拒绝才用ReOpenFile同对象，不经后来路径补对象；实际拒绝保留。依据[ReOpenFile](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-reopenfile)、[FlushFileBuffers](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-flushfilebuffers)，原shared持久化政策与错误返回不关闭。有限最终`c312acaef47a41ec836828b9b5034379` exit0：ASCII/中文/目录barrier、中文发布、missing源和目录目标保原全文、非法UTF8/FD拒绝、100次barrier handles75→75；sync撤回30649574…C程序exit3，A发布撤回364ac6cd…C程序exit3（脚本自有目录清理另失败exit1，原件保留）。未作掉电实验。初次候选普通文件通过但directory ReOpen拒绝，改为已经实测的目录原始writer权限barrier；7b4fefb6…目录也通过，未将该失败写成全绿。

**滚轮最小反例与修复。** Windows原本无WM_MOUSEWHEEL分支。借鉴共同macOS scrollNodeContainingPoint/routeScrollAtPoint的同accepted滚动区域与clip、既有cjgui-wheel-v1载荷，核只读GPUI events.rs handle_mouse_wheel_msg和[WM_MOUSEWHEEL](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousewheel)的signed screen coordinate、DPI、120及系统行单位；不引外部依赖。WndProc冻结client坐标/投影/coordinate epoch/系统行单位，front raw在真实输出成功前保留、压力不让后续输入越过，转移后不重复dispatch；旧投影或坐标epoch不借最新accepted补来源。命中包含且未被clip裁掉的scroll area/wheelScrollable，保留node/resource/kind/acceptedBindingEpoch及pointer geometry，零focus/selection/owner写。

真实renderer有限RED `ff44c3a16c3a4c7cbede66060569231a` exit1→最终`3ee66225b5864e04b787c628b542fe56` exit0，覆盖DPI192点、真实WndProc→raw→30载荷、父scroll目标、clip/零delta、输出满和payload分配失败保原FIFO后恰一次、旧投影拒绝及destroy；仅撤回WndProc入口2839b2af…翻红。工具初版编译误用既有签名623a4a8a…保留；分配恢复的8be6a432…把既有kind11压力通知当成重复wheel，实际一次wheel＋一次原压力通知，修正具名判据5213207f…通过，未改生产来隐藏通知。只读TEXT_POSITION复用既有accepted DWrite位置服务并读body哈希，仅供正常鼠标源跨度测量，不写owner／焦点／选择。

**r5q正式候选。** 完整121项仅从r5p纳入renderer及posix两文件；MF7bbf660d…/native42a2d9f8…/posix99f96884…/ZIP6b2cf4c0…，其余Cangjie/foreign/header/flags不变，126项本次扫描捕获的renderer导出签名相等（不是宣称扫描覆盖全部声明）。正式`bc29495e195744b5acd39e1978949409` build0/166.388s，native archivebcc18cb4…、EXE `29ce544bd38b1fc8ac1d3a0eff8d43ebffb85b8e04424184776485e5d24864cf`/23,504,384B；BC32576c52…/新实际obj2dd3916d…再次核捕获准入，SDK恢复。普通来源r5p已验；现在此正常binary核same-save终结、fresh PID及20笔真wheel工作，尚不称最终portable。20笔工具以每笔4个原系统wheel合计80个安排重叠，要求每个请求区间实际含wheel送达，并核node rect＋geometry translation的真实世界位置，不以线程存活代工作。

用户最新允许Pi DeepSeek Flash做快速执行／验证；本轮仅限定无工具静态协议判据核对`flash-protocol-check-*`，deepseek/deepseek-flash exit0/13.05s，原答复保留，未经实验意见不当运行证据，也未咨询Shift或调用其他顾问。Shift原首修依旧FAIL/待具体指导，不清零；正常鼠标非空选择按原P8及主链单独核验，不能替代键盘Shift门。保护E/H和用户实例／剪贴板／暂存，无Git写操作。


**r5q正常消费已取得的事实。** AST/C#检查181ffd89…exit0；系统组字与连续链`9ac57fe3070a4b92a08a8061a0ade7b1` exit0/39.589s，首PID20264/HWND20316956/run accept-run-49df6f46f6d04708b8abbc2cffb06354。默认1100×780、DPI192，IME预编辑/提交/取消owner零／一／零，随后13笔普通Unicode v2→15/137B，Agent v16及AUTO id3→DONE28:28→END installed后免点击五笔人续写v21/161B精确。本次公开SAVE的同次围栏终结`PHAROS_SAVE applied=true persisted=true version=21 bytes=161 reason=`，真实文件161B/SHA0a07e93f…；恢复原输入locale后真实AltF4退出0。同EXE新PID12004，重开完整161B/初始v1精确，冻结该新实例真实collapsed83:83后一笔R→v2/162B/full journal精确，正常AltF4退出0。文件/相位bin、journal、公开原回包、同次终结、两PID屏幕与kernel退出均保留；独立Python复核全文公式和UTF16插点通过。本腿尚不含原非空预览往返，summary明确BLOCKED_SHIFT。

真实滚动20笔`7599d40aee544094928ffef7cb80eae5` exit0/10.737s，PID5428/HWND43652108/run accept-run-481e91c07cd54a76a6f5e1f1afe7a56c，同q EXE、原5427B/48copy默认预览。10 read＋10 apply，每笔请求区间含实际系统wheel投递（20/20、共80），前台无变化，accepted node rect＋translation世界位置9次变化，真实Markdown截屏；owner5427→5477B/v1→11全文逐笔精确，独立Python解析实际版本字段/严格bool及每笔完整hex通过。记录实际14成功present、129 raster/129 upload、47,340,864B新增工作，live6,888,256B/peak11,797,312B/scratch0，RSS138,600,448B/private132,075,520B/handles353；请求owner回包8.588–105.781ms。输入→accepted时延仍NOT_RUN，CPU upload API耗时不作GPU完成；不外推物理Windows性能。两张实际画面已人工检查正文/emoji与真实预览滚动。接着单独验正常鼠标[23,27)非空选择/预览返源/P8替换与Undo/Redo；Shift原失败保持，最终固定门与portable未齐。


**r5q正常鼠标非空往返。** 644e3d0101d54af9abac20eb1f1245e8 exit36，PID7512/HWND28247046/run accept-run-c1a7165f662d4f8e97f5c22f901f5fd0，同q默认窗口。TEXT_POSITION两点同accepted5/layoutLease29/134B全body hash，实际SendInput3项拖选[23,27)/owner v14零写；同版真实Markdown预览后返源REQ3→DONE23:27→END installed，owner不变；无editor点击的X一次2项投递，唯一human journal精确byte[41,49)替换58、v14→15/127B。实际source/preview/选择/替换屏幕已检查，P8正常来源与精确落点获证明。随后真实Ctrl+Z4项没有任何历史操作/owner保持v15/127B，FAIL36原件保留；源码handle_windows_key_down只有导航/删除，没有共同shortcut:入口，此为新的明确缺失接线，不把Shift失败改名或清零。

**r5r仅接现有共同命令。** 对照共同窗口event34/normalized declaration及mac CjguiComposableShortcutForEvent/CjguiEnqueueComposableShortcut，GPUI events.rs只读核键盘修饰与字符解析；不加业务表、不在native执行Undo。Windows冻结Ctrl+A-Z映射共同primary/command wire，Shift细分，AltGr/Windows组合保留；原source安装门延期完整字符串，同FIFO交付后kind34，Cangjie仍决定声明、有效target及focus scope。有限原RED a6521d6e…→GREEN28ae6bb2…，shortcut及原transfer压力保持；只撤回入口6db35610…6项翻红。工具初版5660fe7a…误用不存在lastPumpedText字段、44512a79…复用未清空event导致empty pop后旧kind误红已保留，核实际GEOMETRY_EMPTY契约校准，未改生产救绿。

完整r5r仍121项、仅原q renderer变化，native de933595…/MF26de9076…/ZIPc383ffdc…；其余仓颉/foreign/header/flags/实际BC与obj关系不变，正式重链在途。正常链Redo先用现有119工具栏声明按钮（系统SendInput），原CtrlY未声明不当必然支持；原Shift键盘失败继续保留，未重新修该问题。原整包/最终交付仍未完成。


**r5r正常消费及r5s既有选区历史接入。** 正式b398ea48… build0/174.245s、EXEc4cca083…/23,504,896B/native库24d21b43…，BC32576c52…/obj2dd3916d…与实际捕获相等，SDK双哈希恢复。首次f76e34a0…仅旧MF保护失败（脚本依次替换把prior MF误换成new MF），修改前校验拒绝/无源码或SDK写；修工具后正式通过。r5r normal8c7f9273… PID5040/HWND51843968/run accept-run-897218f0643b43cda04e951edcfb51f2：原系统连续13笔、中段鼠标[23,27)、同版真实预览、返源REQ3精确安装、免点击一笔X均通过；Ctrl+Z现通过共同命令激活真实UNDO，v15→16/full134B；真实119按钮Redo v16→17/full127B，也精确。随后不是简单“caret24工具预设”问题：源日志queued=false、PHAROS_TEXT_SESSION_SELECTION0:0/version17，原human journal SA=-；Redo无可恢复after choice，故主链后续依赖暂停，不用0:0替代已安装授权。旧失败保留。

正典产品已有解决：PharosSessionRangeBridge以本笔冻结startByte＋inserted bytes计算合法collapsed after，随同一PharosEditRequest→EditTransaction保存到owner/history；非法坐标仍拒绝，不能靠后来的GUI回调补history。在r5r完整输入只接此必要三处（capabilities optional selectionAfter/defaultNone、service传递、human bridge计算/提交），不吸收E/H其余代码/新增source-choice API，不覆盖已有正典更完整实现；canonical三个实际hash/采用边界见r5s-canonical-adoption.json。原W来源/版本/epoch拒绝门保留、native/header不变，完整r5s121项MFf6dd1485…/ZIP54edbe95…；捕获7a084ea3…exit0/171.679s，BUILD_EXIT1为capshim预期终止，实际新BC4bed0995…/28,597,448B（旧BC不能复用），SDK恢复。新Mac llc正对该BC运行，最终正式build/Redo后免点击链仍待绿；不以捕获exit0当正常构建完成。

独立几何/设备/20输入工具：8abb046f…PS UIntPtr转换拒绝，尚未故障注入；修调用类型后fc8409ae…没有RECOVER日志。先前把原因归为resize没有新Present的推断已撤回：4988f5d0… PID16176又经真实公开[G]末尾写，回包严格applied/version1→2、source mirror实际更新，仍无RECOVER，原因未定。r5t只向现有可选只读WORKLOAD补device_generation/recovery_count/pending/attempts/last_hr/controlled_pending，不改恢复策略、正文或公共ABI；完整121项MFebe79d4b…/ZIP69684797…，仅native变化，仓颉/foreign/header/flags与r5s实际BC仍相等，待新obj完成后正式构建。独立普通resize/minrestore腿b3461041… PID8452停在13:13重复选择的日志门，产品只在坐标变化时记录选区；工具改为恢复后选择下一ASCII边界14，保新选区事件与全字节/version门。

范围/Unicode独立腿用普通单行34B `A😀é👩‍👩‍👧‍👦Z`。bd4e27ee…首次body矩形中央未产生选择；25758500… PID14684按accepted真实字形0点击，框架STALE_SELECTION一次但坐标仍0:0，后续移动/删除未跑。继续启用已有CJGUI_SELECTION_ADOPT_TRACE，并将首次点击设为有效非零边界1以区分日志不变和真实来源拒绝；不删来源门、不补重发。系统左右与每簇单Backspace、原版本/完整owner/journal/accepted hash仍为验收要求。Shift原首修FAIL保留，主链新选区历史编译及整包仍在途。

**独立门实际GREEN及新obj（2026-10-08）。** r5r 6ede948c…/33.350s PID9620/HWND52368256/run accept-run-867cc6e19954499fa2577c681c336baa，以实际accepted字形1单次系统点击，home后Right整簇1,3,5,16,17、Left16,5,3,1,0，零owner写。单Backspace精确删除surrogate_pair v1→2/34→30B、decomposed_accent v3→4/34→31B、ZWJ_family v5→6/34→9B；中间公开整篇复位有独立请求/版本，末次画面及正常AltF4/kernel0，Python按冻结UTF8[1,5)/[5,8)/[8,33)三处逐项复核。原0:0首次日志门失败保留；未修来源守卫。

r5r f623b477…/36.963s PID20168/HWND29164550/run accept-run-ca05096ea0394e1299a819a977789fb0，resize小160×120后回默认、minimize/restore、真实新caret14、20笔A–T输入均严格一次/full owner/version1→21/journal20。owner观察上界p50/p95/max31.7068/50.4868/64.9134ms，accepted81.7551/101.0803/113.6511ms；读IPC与readonly full-body哈希探针时间包含在内，不称GPU完成。实际native frame7→27/layout87→168/raster70→131/upload70→131，新增133,928,800B raster/upload；live7,352,280/peak14,388,112/scratch0，RSS113,680,384/private106,463,232/handles366。设备门未运行，物理跨屏未运行。末次正文实际可见，正常AltF4/kernel0；独立Python复核20个全字节及每行version。工具bb94d347…为PS5.1 ParseFile把无BOM UTF8按ANSI读导致误红；校准为已有UTF8 ReadAllText+ParseInput及实际C# block编译后6cd8e735…0，未更改应用。

新BC4bed0995…实际Mac llc0/1085.588s/PID19281，obj0cecb4d91f9b5a0b7ab2bfac2eb8325800bc3c86586cc811b4c0a0422f44533d/5,609,498B/COFF8664。r5t只有native readonly设备字段新增，与r5s仓颉/header/foreign/flags一致，可用该新obj；正式脚本AST9e4aaefb…0，依序核guest r5s121项后换r5t/native重编/同BC重捕获/双SDK恢复，正式build在途。不能以新obj成功替代最终应用消费。


r5t首次正式de56cedd…实际cjpm build退出-1073741819/264.063s，job exit46保留，不能用它已有EXE倒证成功。回收原件fe1af1dc…：BC4bed…/obj0cec…注入匹配，native库67234317…，原SDK llc与llc-real双SHA1ea68362…恢复，构建log086cc90d…/300,332B UTF16、inject3b771d46…均保留。Application1000 f0dbf3ef…事件1107：cjpm.exe PID0x3C40/SDK libcangjie-runtime.dll offset0x12e608/0xc0000005，与r5j/r5l既存事件同位置；r5t新EXEaee89ebf…/23,514,112B存在也不能覆盖此失败。沿r3已采纳指导，仅一次同输入retry1，121源MF/native库/新BC/obj/flags全部再准入，SDK互斥及finally保留；ASTd9cb1cd9…0，正式重试在途。如再次失败停止此依赖并升级原件，不继续猜改SDK或循环重跑。


r5t单次retry1 95f0b804…真实build0/233.117s，捕获BC4bed0995…/新obj0cecb4d9…注入同值，native库67234317…、EXEc3c69f2a8de6c3263e678851963be0d8430d19948834cb6ef67df62f6a338ad8/23,514,112B，SDK恢复。失败构建原件仍保留；不能用它和本次成功混为一轮。product-artifacts包括CJGUI、Pharos app_services/editor_surface实际新静态库。正常主链/P8恢复后24:24仍将按原要求执行。

按用户2026-10-08最新授权，仅用Pi/deepseek-flash作快速只读工具检查，12.837s/exit0/no-tools，prompt/stdout/stderr/退出原件为deepseek-flash-device-check-*。其答复不是运行证据：截取上下文未带后面的[G]完整owner/version校验，不能据此断言该校验缺失；执行者采用可核实的pending一次观察竞态及完整WORKLOAD响应门，受控记录精确同PID/单次reset代/count，再核[G]完整owner和恢复后正常输入。不委派图形根因或更换顾问型号。


**r5t 实际正常消费与交付（2026-10-08，原包仍未完成）。** 主链首次工具运行16f26508…在editor首次点击前命中另一PID，未投递输入；改为首次accepted字形1坐标后555d2755449a4dacb05a257f6122651d/exit33，PID17724/HWND50468012，run accept-run-b4c29bc33afb4223b111f31b936198ce。13笔普通输入v1→14/116→134B、非空鼠标[23,27)、同版真实预览返源REQ3/DONE/END installed、免点击X v14→15/127B、系统CtrlZ共同命令118 Undo v15→16/134B及REQ5/DONE/END installed均精确。按钮119 Redo v16→17/127B全文正确，新的同事务selectionAfter已投影为24:24；但PHAROS_TEXT_FOCUS_RESTORE queued=false，随后没有REQ/AUTO/DONE/END，不能将owner选区更新当成原生安装。Agent后继、人免点击续写和本主链最终保存新PID依赖仍未进入。

设备7178c31540824a56bfbb371338507a0e/exit55，PID10172/HWND65278998/run accept-run-30b3d7695fd34f39be1ab07acc9391c1。同次单控故障读回：generation1→2/recovery_count0→1/pending0/attempts0/last_hr887a0007/controlled_pending0，真实[G]公开写owner v1→2/116→119B保持。此前仅由缺少RECOVER日志推断未恢复的意见撤回。最小化恢复后实际新caret14:14/v2，首笔A系统2项单次投递却零owner写，具名installed_range_prefix_mismatch；该完整设备门FAIL，恢复部分成功不关闭继续编辑要求。记录仍有identity_candidate_already_open和旧恢复attempt_limit_exhausted，不据此再猜改D候选配对。

当前同EXE独立几何/20输入945da92a252f4ccdbbee585a17ebf0db/exit0/36.311s，PID10008/HWND42669098/run accept-run-e016ac915cc14f34858ff43ca843bb36。默认1100×780、DPI192，resize后回原尺寸/minrestore，caret14后A–T每笔2项各一次，20笔v1→21/116→136B全文与journal精确，独立Python20全字节复核。owner观察上界p50/p95/max33.6016/69.3823/98.2932ms，accepted81.9038/117.2973/164.8038ms；含IPC与fullbody readonly probe，不称GPU/物理显示完成。frame8→28/layout90→171/raster73→134/upload73→134，新增133,928,800B，live7,352,280/peak14,388,112/resources20/scratch0；RSS114,495,488/private106,733,568/handles369，正常AltF4/kernel0。device故障在本腿NOT_RUN。正常PNG77381274…/exit0，PID15128，实际node1001左右255,0,0及0,255,0，正常退出；坏图/过预算/alpha/crop既存有限原件按未变WIC路径复用。

portable d9938e745bb44685a549b6f1a070f5a5/exit0，PID19156，系统PATH-only普通入口中文空格文档、owner全文和3个实际非系统x64模块同目录/哈希核验，正常AltF4/kernel0。目录C:\cjgui-windows-w1\delivery\Pharos Windows r5t candidate 12d1eb8b70534de4b4ca4c690a8b8e01；包ZIP7b33aa21…，使用说明明确未完整写作通过。当前native及产品真实身份见r5t-build-retry1/product-artifacts.json，不以旧r5f交付覆盖。失焦/五次开关eec5fb9f991043889f38f7cd3ef23b51/exit0：自有helper实际系统点击，10.048s/CPU0.34375s/单核3.4211%，frame1→1/handles308→308，五PID4940/12232/9004/15100/2904均AltF4四项/kernel0/准确HWND退休；聚焦caret闪烁仍须单列，不把preview空闲替代。三批当前worker实测e1f70cfa…/c1b5f659…/493f4b96…各exit0，目录1、仅当前PS任务加从worker启动即存在的conhost10840，handles516/518/514、RSS约120.7MB/private约87.3MB。旧任务后代/目录退休，计数无该样本增长趋势；不称恰回零或长时无泄漏，worker在整包执行中保留。

完整源码交付已补来宾实际7份TOML，30bdaa27…/exit0逐项哈希与构建MF一致；本地source121+configs7，原MF保持ebe79d4b…字节不改，旧size失配在provenance列出，独立delivery清单逐项实际大小/SHA。源ZIPda5900b8…、交付MF3a1a1bf8…，9a7bcfbd508e43da9683d44306083e55/exit0在新含空格目录C:\cjgui-windows-w1\delivery\Pharos Windows r5t Source 631e78c1936a44e09c594c8866b1c551，PowerShell解析及132项全文/大小SHA、原121与7cfg验证通过。新目录干净重构建仍NOT_RUN；build脚本存在或VerifyOnly不关闭独立构建门。旧工具404 c85ac941…为未将脚本放transfer原件；修正实际传输及固定脚本SHA后e761ccd8…AST/C#0，并未以重跑修改产品标准。

**r5u 共同恢复准入的可区分反例与首修（当前接续）。** 在完整冻结r5t共同源上以真实requestOwnedSelectionRestore入口构造：owner全范围新事务及同版本after3:3，session.refreshMirror先失去旧rebase。原入口pre=false/request=false；随后selection16只读才把owner选区映射成3:3/坐标match=true。隔离Mac cjc--test编译0、原运行1，反例明确；仅将现有selection16读取移到未改的selectionCoordinatesMatchMirror检查之前，3项GREEN/exit0，含原无owner镜像迁移拒绝及有owner源选区在新mirror之外拒绝/零写。撤回同一顺序改动后编译0/运行1，只原owner-after例翻红，两个拒绝例仍PASS。fixture首次错用dispatch constructor为工具编译失败并保留，不计生产实修。未清任何来源门或以mirror相等授权。只读GPUI Windows events.rs/retrieve_caret_position先从应用input_handler读选择，再算bounds作归属参考；CJGUI依旧维护owner版本/源跨度、同mirror证明和真实native回执，未引入参考依赖。

修复已按局部hunk回正典window，并在既有source_handoff_test中追加两例；未覆盖E/H在途大diff。CodeLattice live root图为stale_baseline/workspace，symbol callers未能选择本框架项目，旧审计符号建议不作因果或影响证明；源扫描核本窗口内部恢复调用与Pharos四个消费入口，现public签名/foreign/header不变。下一冻结r5u完整121+实际7cfg只变共同window方法顺序，MFaea57e019b5ae3eeb0f8b0eeeb188b910e0d5ab16d304924640f538a8b9cc400/ZIP1abe8bbaa92e21ff70b8ce1be2eb2d1310b9c268553ea07c42f48601ae5c55d7/window8004f3c3a343d099010287b9470ee590f4bc20344e879a7198036e85388613c1；native/产品3处selectionAfter与flags均不变。原目录新BC捕获260e4eb6ba4c4930b506bcea162de330/exit0（捕获墙预期build1），实际新BC4bed0995…/28,597,448B；随后Mac llc新进程76522/exit0/804.346s，fresh_compile=true，实际新obj0cecb4d9…/5,609,498B/x64 COFF。内容与旧哈希相同来自新捕获及新编译，不是复用旧产物；原命令/输出/原版SDK恢复保留。正式脚本AST22cc7f36…/exit0后正在运行。正式构建后先原正常主链和设备继续编辑，若该首修仍失败按原公共/状态机制规则升级，不继续猜guard。Shift首修FAIL/待具体指导维持，未换模型或重命名清零；原12门/完整A–F、最终同版portable与同源干净构建尚未完成。无stage/commit/push，runtime_state/cjpm及E/H/用户资源保持。


独立干净r5u目录 `C:\cjgui-windows-w1\runs\r5u-clean 55a5bc26ed3d4bceb30166243035eb7d` 从空目录展开完整121+实际7cfg，0f80df24…准备exit0；三native与app support/manifest res均新建，未拷旧targets/EXE。首次捕获62480154…/exit45为真实SDK cjpm -1073741819，Application事件1111/PID0x4500/libcangjie-runtime偏移0x12e608，原日志及SDK双原hash由aa8b4add…回收。按已采纳SDK规则仅一次同输入复试efca794e36934548beccf266f94e7511/exit0/226.432s、捕获墙预期build1，实际BCf02f558b…/28,597,488B，与原目录BC不同；独立Mac新llc PID96219编译在途，不准入原目录obj。此时独立正式build及正常消费仍NOT_RUN。

聚焦source空闲bfaf70a34ec743d0a90ef26d5bf251af/exit0，PID14812/HWND30147694，实际caret1:1/v1，10.0526s/单核3.5750%、frame4/layout37/raster28均不变；完整116B owner/v1/零写保持，handles355→360如实记录，正常AltF4/kernel0。这不能证明caret闪烁；截图发现Windows多行正文绘制semantic fallback标签，Mac共同值绘制不含该标签，现有renderer探针已准备有限反例，尚未更改生产或宣告通过。Windows selection paint bridge当前是非macOS空实现，源码及截图不足以称source caret/选区绘制通过，需按既有输入身份核正常画面。快速Pi/deepseek-flash交付工具检查60s无答复已终止/helper1，原prompt/stdout/stderr/result保留，无答复采纳、未更换模型。


r5u原目录正式867cdae5695b47de9cf9330a2ad158ca/exit0/238.991s，真实cjpm build0/匹配当次BC/obj注入/SDK恢复；EXE7a02e03a34915d87ca0ac0d8a973cefe866663655b143c93ff7bc1e638806efb/23,514,112B，native archive67234317…不变，CJGUI lib17e36dd6…/cjo fe392bb4…实际重建，产品两包既有身份不变。主链工具1e68883a…ParseInput/C#0，正按默认同EXE输入验收，不以构建关闭恢复/正常写作门。


r5u正常主链82a4d2e45ae64706b89720671f2f5b5a/exit0/44.989s，PID5044/HWND74712082，freshPID19864，run accept-run-874bbc896c804df1a02d5d77fafa9ed7。13笔v1→14/134B、同版非空鼠标[23,27)/真实Markdown预览无编辑返源REQ3、X精确替换v15/127B、Undo v16/134B及Redo v17/127B+REQ6/DONE/END installed、公开Agent v18/143B+REQ7安装24:24、免点击五笔人HF-中😀→v23/151B、同次公共SAVE persisted=true/全文精确、两个正常AltF4/kernel0、新PID同151B/v1并R单次→152B/v2通过。独立Python重放22笔journal（版本/SEQ/SUM/严格UTF8源边界/所有splices）、10份owner全文、保存和fresh实际79:79输入全相等，r5u-main-full-byte-check.json。截图真实预览成立；source非空选择没有可见highlight/光标，不能把这条owner链外推为可见选择或完整包通过。

r5u设备bc3c88005df141b28b6ab6c7140dc3d4/exit55/41.387s，PID6324/HWND23991288，run accept-run-4fc8e5de8dc7416792f4100b60c6359e，设备恢复及[G] owner v2/119B成立，REQ1/AUTO出现但identity_candidate_already_open、END attempt_limit_exhausted；实际首笔A两项一次投递，PHAROS_EDIT seq0/mirror2/version2/119B installed_range_prefix_mismatch、完整observed-after仍v2/119B。与r5t前提相同，owner-first修复只关闭Redo误拒，不关闭设备后输入。按公共/状态首次实修失败停止依赖该问题的猜改，向指导升级：请区分故障后候选身份闭合、13:13请求与14:14后继实际选择、已装链prefix/nonce在同PID同v2的归属及安装结算；建议先固定单次故障、[G]全文、REQ1终态与首笔原票，不删prefix/identity门、不重开D已闭配对。不因本轮或模型更名清零。Shift既存首修FAIL仍等具体指导。

独立r5u Mac llc PID96219/exit0/875.699s，新obj497fcc7c…/5,609,672B/x64；4fa86cb3b2c14daf8a19a04ab83dada7/exit0/186.616s正式干净build0，实际BCf02f558b…注入匹配，EXEf4e57273…/23,514,112B，native archive369869bb…及CJGUI/app_services/editor_surface都从该新目录构建，SDK恢复。首次正常6eca14f346bb4c5a99259702e28ddd96/exit50是工具把socket/descriptor路径写为\S+，实际stdout已listen0/manifest_written=true/descriptor_written=true且路径含r5u-clean空格；不计产品启动失败或输入失败。固定真实完整行的新路径正则离线反例通过，r5u-clean-channel-regex-check.json；只修两处工具路径提取，正常干净消费仍待复验，原失败保留。

r5v多行绘制责任有限门：d536cb36…RED3项，89693781…GREEN所有项，d9439721…撤回RED同3项，均真实DWrite/D3D、native选择/owner写入不变。单行/整数/布尔标签、同输入layout/lease和多行切回释放旧标签正确。最小条件回正典，只为MULTILINE排除inline label，semanticId/label身份仍保留；生产同一条件另含说明注释，formal编译覆盖实际源码。完整121+7cfg冻结r5v nativec61476e1…/MF6e725d11…/ZIP1b30a3bb…，仅native实现变、公共foreign/ABI/flags与所有仓颉输入不变，正式过程仍须匹配BC4bed0995…才复用实际obj0cecb4d9…，构建在途。

source paint独立缺口已由dbfac1ee3fd0456bb12dbe7478387fb9/exit1压缩为真实表面反例：native focus/1:4选区与0:0光标均安装，正文/选择零额外改变，但同正文accepted重绘的GPU表面与无选择像素同hash。现从r5v在artifact隔离试验Windows私有自绘投影：同一DWrite layout/已装proxy全文/节点身份/裁剪，选区背景与文字后光标；复用现有GPU flight/纹理租约和scratch预算，只在原有有界UI pump发生选择/焦点/系统闪烁相位变化时重绘accepted，不晋升candidate、不修改owner/选区/输入许可。尚未回正典或记通过。参考仅算法：本地Zed element.rs paint_cursors与微软[HitTestTextRange](https://learn.microsoft.com/en-us/windows/win32/api/dwrite/nf-dwrite-idwritetextlayout-hittesttextrange)、[GetCaretBlinkTime](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getcaretblinktime)；不引入外部依赖、不设系统blink值或改变线程。


独立干净正常a9a3c854df67473c93ac60f5d8d26c7e/exit0/43.603s，PID2284/HWND53548094/fresh11152/run accept-run-a32408de20c64fd9820147b59978c0f3，同13笔/P8/预览/免点击X/Undo/Redo REQ6/Agent REQ7/人续写/公共SAVE151B/正常关闭及fresh输入成立，saved SHA77556583…与原目录独立链一致。完整空格路径工具固定后仍严核foreground/send/version/fullbytes/install/关闭，不放宽产品验收。

r5v正式244ea4756b4645cc9fecf911866ec06f/exit0/182.555s，native archive5271e02b…，本轮匹配BC4bed0995…/obj0cecb4d9…后EXE8c44a7d21b9890bd82faee05f0776f1ae5e0585d38e31ffe9a96b5e07b669b66/23,514,112B，SDK恢复。666946419d364bc99aa168b6bb8d59ca/exit0/44.412s，PID16012/HWND50070636/fresh6776/run accept-run-81f55913742949c99f88be5201df1a46，正常完整主链0；首次字形x558取代旧含标签x838，actualP8及source原跨度仍精确，截图正文已不显示semantic ID。可见source选区仍缺，不能把该owner链当光标绘制通过。

source paint首工具编译6d442d02…为隔离函数提取时scene指针“.”误写，原日志及初包保留；修正常规C指针后0467dd70d448437e84f5812cb845d34a/exit0，真实2个表面反例GREEN、绑定拒绝和零正文/输入意图改变仍PASS，撤回e3324411438444c79e512a4e4f7726ea/exit1同2项翻红。原先不存在的allocation状态名在本地生成断言时被挡住，未进入编译/生产；采用现有INTERNAL_ERROR。新试验每次画前都核完整proxy/body字节，不以paintKey相等代替来源。当前追加真实系统闪烁间隔on/off像素、焦点退出/返回、另一owned target退出、当前owned target投影、accepted/candidate和layout/lease/raster/upload/scratch不变的有限门，尚未回生产。


r5w 私有 source 自绘投影有限门已经完成：ef6a5c98a4154ba2a192a8a4ff4a8303/exit0/5.332s 的 31 项核验包含真实系统闪烁 off→on 像素、真实失焦退出／复焦返回、公开 owner 目标改绑撤回与当前目标恢复、全文 proxy 不匹配拒绝及零正文／选择／输入意图改变。accepted sceneVersion 与 candidate 不变，layout 指针／lease 不变，额外 layout/raster/upload/scratch 均零；da14e3b28b254f70a88f80bcd1dc7db8/exit1/8.035s 撤回为原实现，同表面选区、光标与 off 相位反例仍翻红。选区 HitTestTextRange 临时数组继续受既有 scratch 上限与配对释放约束；新状态仅 Windows renderer 私有字段，没有公共 ABI 或 owner 写入。

draw helper 提取回归 31ef6153ab184a518aec9c3a4ed6729f/exit2 原件保留：layout、runs/保留候选配对、标签、resize/recovery 全通过，PNG 腿因工具漏传既有图资产而 alpha 失败／budget 夹具空值崩溃。补齐工具资产并逐项核 hash 后 375dd7bd8fec4ae698e85c4676de6639/exit0，真实 alpha/裁剪／opacity／换图、坏图保旧、第二张超预算拒绝并保 accepted 纹理与像素、销毁归零通过。有限 device recovery 不覆盖正常 Pharos 已升级的设备后续输入失败。Pi deepseek-flash 按最新用户授权完成 4.487704s 聚焦只读机械核对，答复未见 owner 写入／accepted 提升／scratch 失配；只作辅助查阅，不作运行或裁决。

以上通过后私有实现完整回正典，native b71d1e03ac7b5ed0c8bc73281f82ada1c54948017a8a5974649ddfc79c0c8014；完整 r5w 121+实际7cfg 冻结 MF fb6316d84fff1d246b23c92c71e493f566bc415301a04715b4aadf480149a313，ZIP 5edf26ce2569a9101fc258f6bad4b782367bfe51a774cf755939a9146912e092。全部仓颉／foreign／ABI／flags 未变，正式过程要求实际 BC 4bed0995…匹配才复用当次 fresh obj 0cecb4d9…；AST c2e49cc0…/exit0 后同串行 worker 正式构建在途。下一步同一新 EXE 的正常主链、可见非空选区与 source 闪烁／零 owner 写入，再按原12门补齐最终交付。Shift 与设备来源失败仍升级留开，不猜 guard；E/H／暂存／用户资源保护不变。


r5w 正式首轮 a2a59a25bfd94c2999eb0614c4706b1e/exit46/274.238s 真实 build=-1073741819；native archive b61e6971…，BC4bed0995…注入已匹配，SDK双原版恢复，不能用该轮产生的 EXE9720569f…覆盖非零退出。4135ebe0…保存当次完整构建 log d0985b5b…/300,332B、inject283b16ee…、manifest39f31909…及捕获BC；4abcfe75…保存 Application1000 事件1121，SDK cjpm.exe PID0x3CE8、runtime.dll offset0x12e608/0xc0000005，与既存SDK故障同类。只按 r3 已采纳指导做一次同输入 retry1；121+7cfg、已编 archive、BC/obj/flags 再准入，互斥与恢复不变，AST e2ffaaa6…0 后复试在途。如同输入第二次仍非零，停止该依赖并升级，不循环重跑。


r5w 原目录同输入 retry1 9214d65d1b7a46e194bcb6e3d87f2084/exit46/249.969s 仍真实 SDK build=-1073741819。BC4bed0995…再次匹配，SDK双原版恢复；不能宣布构建成功或正常消费，也不使用其 EXE。本依赖停止再次猜改／重试，并升级两次完整失败。独立交付门继续：此前真正由空目录121+7cfg／native／fresh BCf02f558b…／fresh obj497fcc7c…建立并完整正常消费成功的含空格目录，仍保持独立身份，按 native-only 准入纳入 r5w；ce7eaa17…/exit0 工具AST已核，其正式过程仍须核全文件、配置以及本目录当次BC并真实build0。它不是重跑原目录第三次，原目录两个失败不会被覆盖。若该独立目录也无法实际build0，则最终新二进制及正常消费依赖SDK升级，旧v/u绿色不能冒充新w。


独立含空格目录 r5w 正式 ccd27017b95d4c3db43ab0d381bbcd39/exit0/243.212s，actual BC f02f558b…与该目录 fresh obj497fcc7c…匹配后真实build0；新 EXE46a8e992c1837cee7074840dba6997d327c500da47ac0c536d1992a583fee8fa/23,518,720B、native archive42574a07…/477,076B，SDK恢复。此前原目录两次 SDK AV1121/1123 保留，不以独立成功覆盖。r5w-actual-build.json 与 r5w-clean-build/product-artifacts.json 关联全部真实库；共同Cangjie输入未改，独立库沿用同目录u已正式编译的完整冻结输入，非整树E/H。主链 AST76d313ad…0、focused/blink工具AST5bedefbb…0。首个host读回用了错误上传目录，工具连锁 FileNotFound/runner script missing 原记录保留；修为当前session_dir/guest-results后生成与核验，未运行输入／未放宽产品门。


r5w 正常主链 5a440efca5b243c39bba965cf1873588/exit0/45.742s，PID14512/HWND53085032/fresh10748，run accept-run-1aeca3a8155f45c2bb524b42bae9dcbe，默认1100×780/DPI192。完整 owner 与journal逐步通过13笔/P8[23,27)/预览返源REQ3/X/Undo/RedoREQ6/AgentREQ7/人续写/公共SAVE151B SHA77556583…/两次正常kernel0/fresh单次R152B。已实际看图：首次非空源码选择显示1中😀高亮；返回source截图工具栏114仍有焦点，原23:27 owner与安装票保持但该截图不显示source高亮，不称返回当刻高亮通过。

正常 source blink aef7bc7695f44e758003e1b74014f4d6/exit0/41.078s，PID20396/HWND10814600，完整116Bv1、实际选区1:1保持。system GetCaretBlinkTime530ms，27次真实screen区域取样、恰2个重复状态及5次转换，同窗口两张全图可见caret关闭／出现。随后独立10.0129s聚焦idle CPU0.3125s/单核3.1210%；frame13→32，而layouts36、raster/upload27与累计9,650,176B、live7,426,560B/peak9,650,176B/资源19/scratch0全部保持。handles358→367，不能称零增长；正常AltF4/kernel0。

近上限正常反例 93dfc96d4cfa476e86aa7b5abbf49ac3/exit30，PID9364/HWND48301184/run accept-run-e6d33cef7634451395a271f0becbc16a，冻结252,000B/SHA c99d5110…公开owner v1正确，但默认窗口空白、NODE_RECT114 missing；真实stdout反复layout_native_text_worker_unavailable。源码已定位共同measurer遇>1024B TEXT走beginCjguiAsyncTextMetrics，而Windows相应接口仍失败占位（status4/handle0），不是输入投递或增加等待可修。现隔离r5x原生有界任务试验，保持共同foreign/ABI/MAX_JOB131072及Mac源不动，先核同一DWrite纯布局算法的真实异步scalar结果、冻结输入副本、容量／取消／释放／旧句柄；尚未回正典或称大文档已验。参考当前共同Mac job的consumer/worker双责任、4槽/128KiB单任务/256KiB总输入上限、退休后句柄失效；Windows按OS threadpool callback在独立factory执行，不访问HWND/session/GPU/owner。

独立最终r5w resize/minrestore+20单投输入 69e75c3a…/exit0/35.503s，PID12440，owner p50/p95/max28.7193/63.6794/103.6311ms，accepted对应全文观测上界71.0657/111.759/136.9547ms，20笔完整版本／journal与正文均精确，不计GPU完成。公开10read+10write真实滚动 ef8ce5f9…/exit0/11.465s，PID10896/HWND53412712，全部20区间有系统wheel，80/80投递、8次accepted位置改变，owner5427→5477B/v1→11；20present/206raster及upload/78,455,616B增量，live7,007,936/peak11,896,000/57资源/scratch0/RSS141,492,224/private136,331,264/handles364。正常PNG 31e387e8…/exit0/5.130s，PID7496，真实红255,0,0／绿0,255,0采样及正常关闭通过。


r5x async 测量有限门已完成：22fd9b64…原 Windows 占位长TEXT真实begin失败；首41d16582…夹具宏CK对表达式求值两次，实际重复begin/release导致保留未交付consumer，错误原件与源码包保留，不计生产退休修复失败。只修夹具求值一次后7e64212c…GREEN，386c7402…撤回再次begin RED。扩四槽2a991f3e…GREEN，再保持既有multiline高度1,000,000上限、增加真实50,000换行测高的命名预算失败后a1242856…/exit0/4.013s，全部有限检查通过：caller改写并释放后同DWrite全文度量精确、实际worker异线程、pending不可consume、wrong-kind/UTF8/参数/128KiB超限拒绝、256KiB总输入与四槽分别准入／拒绝、abandon在worker存活时不回收槽／字节、回调离开后准确归零、新identity和旧handle始终stale。705943b0…/exit0/7.001s，source-paint 31项、layout/runs/候选配对/label/alpha/budget/resize-recovery 共10组全部通过，原probe资产均hash准入。multiline高度上限补充是对同步实现同规则的保持，不扩文档范围。

私有实现参考：共同 cjgui_async_multiline_measure.m 的 consumerLive/workerLive 双责任、锁内完成与退役、复制前容量拒绝；本地GPUI Windows dispatcher.rs 的dispatch_on_threadpool与direct_write.rs的DirectWriteTextSystem／layout_line在锁下访问共享scratch。原参考text_system.rs路径失效，局部定位为direct_write.rs，未跳过或引入依赖。CJGUI只把冻结UTF8／字体／宽度和scalar句柄交系统callback，worker使用独立局部factory/layout，不读写UI session、GPU、owner或选择；所有结果和退休由同一SRW锁发布，退休后不再访问job。系统入口已核[TrySubmitThreadpoolCallback](https://learn.microsoft.com/en-us/windows/win32/api/threadpoolapiset/nf-threadpoolapiset-trysubmitthreadpoolcallback)和[DWriteCreateFactory](https://learn.microsoft.com/en-us/windows/win32/api/dwrite/nf-dwrite-dwritecreatefactory)。Pi deepseek-flash按用户快速配合授权，17.3068s只读机械核对未见双责任／配对释放／owner写入问题；不作运行／裁决，答复原件保留。

通过有限门后回正典native b50509389f48fd022cba83ce612eb78ab8b1a409e25ab5243aa9c7d02c595537。完整 r5x 121+7cfg MF3b2c9f09489257212cfb91df9c13bc6ddaee4e52c328d7c3690ff74940152fcc／ZIP043b6ec6ba5986f9be6b7fe3941f6f4968601981446e08fe70499b8b59eed722；共同仓颉／foreign／ABI／flags及Mac实现不变，继续以独立目录实际BCf02f…准入后复用此前该目录fresh obj497f…，不能使用原目录失败产物。AST538685e0…0后正式构建在途，随后立即回252,000B正常产品原反例，仍未称范围内正常消费或最终交付完成。


r5w 独立完整字节复算已保存 r5w-main-full-byte-check.json：冻结初始owner＋明确输入recipe，22个journal逐SEQ/base-version/标准FNV行SUM/BASE全hash／严格UTF8边界和splices逐笔重放，10份owner快照、保存151B与fresh79:79→152B全部一致。数值校准：真实Agent插入是14B，127→141B；人HF-中😀是10B，141→151B。先前摘要的143B／8B为算术错误，以原bin和journal为准；没有改原owner、原件或验收条件。


**r5x 正式构建、正常消费边界与最终源码独立构建（2026-10-08）。** `0d2ef977732f4784bbf8314a5fe7b677` 真正 build0/208.894s，EXE9497b7ca90a7e2ae686ad88e794de49ebb1f045e974029c193427a644bf51e0e/23,521,792B，native archive478d4ae3…/482,004B；当次实际捕获BCf02f558b…匹配已新编译obj497fcc7c…，SDK恢复。121源码+实际7cfg全核；仅w→x native实现变，115共同/header项和flags保持，132既有renderer名称未变，没有新外部依赖。CodeLattice native_review仍返回needs_project_selection/staticAnalysisExecuted=false，推荐旧审计消费者不适用；源/ABI和真实有限门补证，图覆盖不能称运行通过。

近上限原件全部保留：`b13d2f1e784849598d3e7f5863f561b0`/exit33/30.515s，PID14552/HWND30278794，252,000B固定fixture c99d5110…已不再空窗，能正常源码；夹具错将完整owner与既有65,536B正文镜像比较。冻结源契约pharosSourceInputWindowBytes=65536、range初始start0；本recipe全部动作在byte100前。新夹具只把坐标身份校验改为完整冻结[0,65536)镜像，同时所有owner/journal/保存门仍核全部252,000B；离线首head hash14212551224565689462恰匹配，单字节变更与短prefix都拒绝，未改产品或窗口/输入。

`e8a89ee3c47b4b7292584cfeea5c07da`/exit1/35.520s，PID8784/HWND55186590，首glyph/原导航/单次28项输入送达；完整分块读从v13开始，最后第13笔在下一chunk间到达v14而拒绝混版。日志13笔恰一次applied，但未捕获终态完整owner，不能称长文档链通过。为区分并发读和迟完成，仅在同原2,500ms预算内等待已知第13笔终态再启动完整read，预算从SendInput前计，不新增时限/重读/重投。`07fb8431f12b4c539a115af8df18877d`/exit32/37.000s，PID11344/HWND46339084：实际2524.5845ms截止观察Complete=false、只到seq12/v13/252014B，固定门near_cap_original_2500ms_terminal_budget_exceeded FAIL。r5x首修关闭worker_unavailable空窗，未关闭256KiB正常连续链；按核心首次实修失败升级该依赖，不继续猜来源guard、缩小文档、慢打或延时救绿。建议指导从同PID原票和共同prepare/native layout责任区分每次65,536B排版/准备代价及队列消费；未做GPU完成时间推断。Shift首修FAIL、受控设备恢复后首输入FAIL仍维持原升级。

独立便携正常链 `6dfbf3111e3b45e0a12a39add514b64a`/exit0/45.393s，同正式EXE、纯系统PATH，目录C:\cjgui-windows-w1\delivery\Pharos Windows r5x candidate 1d0a542e915e45eba3b8ce84b03188e8。PID11180/HWND59184352及fresh3340，13笔v1→14/116→134B、非空[23,27)/真实Markdown预览无编辑返源REQ3、免点击X/Undo/Redo安装REQ6、Agent14B→141B+REQ7、人五笔10B→151B/v23、public SAVE persisted/fullSHA77556583…、两正常AltF4/kernel0、新PID原79:79单次R→152B/v2。独立Python22笔严格journal/FNV/源跨度、10份owner、保存/fresh全文复算PASS（r5x-portable-main-full-byte-check.json）。3实际非系统模块均本包x64，DLL ca65f2b8…/07b33dd3…，没有SDK路径借载。此小文档成功不覆盖长文档、Shift或设备门。

最终源码候选包132项（121+7cfg+4元数据，不含delivery manifest自身），ZIPa6d54e98…/交付MF a502b8f0…；`42eca585764e4bc78905337b77a322d1`/exit0/5.936s在新的空含空格目录r5x-final 94ff007c098f45ba8b0221b37f0bc38f展开，VerifyOnly132全bytes/SHA、原121及7cfg核对，三native/app support/manifest全部新编译0，无旧target或EXE复制。该最终源码包干净BC捕获/新Mac obj/正式build仍在途；不以VerifyOnly或此前独立目录成功覆盖此独立构建门。原12门不删改，最终A–F未完成。


最终源码首次capture `1357084dbf3d441f89e8f87348633f94`/exit45/269.934s：真实cjpm -1073741819在app BC之前退出；BUILD_EXIT旁“llc wall expected”旧模板备注不适用于此实际AV。`bcade4b4ca6247399fa342a371ff8944`/exit0回收Application1000/1127/PID0x254/SDK libcangjie-runtime.dll+0x12e608/c0000005，capture log78432fd4…/327,142B；capshim.log尚未产生具名ABSENT before_app_llc，SDK llc/llc-real两原哈希恢复。与旧SDK已采纳裁决相同，仅一次同输入retry1（121+7cfg仍全准入）在途；不能拿半产物称独立build0，不另找目录或第三次复试覆盖失败。

近上限原票收集 `cc6d6e0e026446a3897b113fe5e21b72`/exit0：两原文件均仍252000B/c99d5110…；实际journal source-window13笔/a3108f3a…、terminal-fence12笔/894a6e15…，全校验SUM/BASE/version/冻结UTF8跨度及recipe合法前缀。前者重放252018B/v14，后者252014B/v13；没有live终态全文读回，不以journal重放代替正常链。准确旧PID8784/11344退休，无重复输入或未知进程清理。

<a id="windows-r5x-final-delivery-20261008"></a>
### r5x 最终候选交付与固定门汇合（2026-10-08；原 A–F 未完成）

本段校正前段“构建在途”。首次SDK AV1127保留。唯一同输入retry0576f619…实际到了app LLC，但克隆capshim旧根常量把新BC写到本任务旧capture目录，collector退出45；不是第二个SDK AV，不第三次重编。核日志、末尾CAPTURE、时间、新hash及128项输入后，4766f2fd…/exit0拷回新BC。前两版恢复工具正则/转义错误exit1保留，未改产品；5aa3e055…/exit0将旧工具BC/log逐字恢复f02f…/de8cf…，未碰E/H/用户文件。

新BC64b1dacb…/28,597,488B在Mac全新llc编译0/1,217.112154s，COFF8664 obj7472e653…/5,609,713B；wrapper新根已校正。正式d12e742fd20a49399d498e53f300db14/exit0/185.366s真实cjpm build0，准确注入这对BC/obj，SDK双hash/互斥/finally保持。新native archive825c873f…/482,004B、新EXE cdd740d0f2a0953a257249cab4f585dff783545f26e4d20c8bd67b0c6ee63792/23,523,840B及共同库均来自新空含空格目录，无旧target/EXE复制。详见[实际构建](../../artifacts/windows-pharos-20261005/evidence/20261008-r5/r5x-final-actual-build.json)及r5x-final-build原件。

该新EXE的ee31b38278eb449999e7ef0301c27fd1/exit0/42.939s、PID12700/HWND50074816/fresh2588完成默认1100×780完整正常链：单投Unicode、鼠标[23,27)、真实Markdown往返/免点击X、Undo/Redo、Agent14B/人10B、public SAVE151B/SHA77556583…、两AltF4/kernel0、新PID全文/R→152B。独立22笔journal及10份全文/保存/fresh复算PASS，见[复算](../../artifacts/windows-pharos-20261005/evidence/20261008-r5/r5x-final-source-main-full-byte-check.json)。生成器首次误断言文件名出现一次（实际两次），仅host AssertionError未投递输入，工具修正后AST26f38b31…0；不计产品修复/重试。

便携交付保留已纯系统PATH消费的9497b7ca…，不把新目录cdd7…误称同一二进制。另补f47bfcb9c02d4882a16828be40e3edaf/exit0/44.443s，PID13332/HWND59315424/fresh14688：冻结5427B/ce0b6aba…、13笔→5445B/v14、鼠标[23,27)，一次4项system wheel -120使accepted node1000 Y85→-613、owner不变；返源REQ3/免点击X及后续完整链通过，保存5462B/SHA7ab514eb…，新PID全文/R→5463B。见[22笔/10份全文复算](../../artifacts/windows-pharos-20261005/evidence/20261008-r5/r5x-portable-preview-scroll-full-byte-check.json)。已看真实截图：此用例选择及返源均蓝色“1中😀”，预览实际列表/强调/代码块。旧116B返源瞬间缺高亮仍保留，不外推所有路径；源码内部滚动到远处后编辑尚未验证。

最终源码ZIP5c7aed1d…：121源码+7cfg+4元数据=132项，delivery MF d4b97f4a…，MF自身另计共133文件；仅说明/provenance更新，128项构建输入与独立成功构建逐字相同。08b46a49…/exit0/4.538s在另一个新含空格交付目录实际VerifyOnly全byte/SHA/文件数。普通build-windows.ps1的build分支NOT_RUN；成功构建是已记录native/capture/Mac/正式relay路线。应用最终ZIP91865dd2…含6文件，MF列5载荷、排除MF/外置record，3PE8664，EXE/DLL仍已测身份。旧候选ZIP保留。见[交付核对](../../artifacts/windows-pharos-20261005/evidence/20261008-r5/r5x-final-portable-zip-check.json)及[源码核对](../../artifacts/windows-pharos-20261005/evidence/20261008-r5/r5x-final-delivery-prepared.json)。

入口：**Windows桌面**“Pharos Mark Windows r5x 候选”，TargetPath/WorkingDirectory已读回；或来宾 C:\cjgui-windows-w1\delivery\Pharos Windows r5x candidate 1d0a542e915e45eba3b8ce84b03188e8\Pharos Mark.exe，参数 --open "中文 含空格路径.md"。源码目录 C:\cjgui-windows-w1\delivery\Pharos Windows r5x Source final 0fd3777317674a05b1d52e2ad63f99ac。宿主[应用ZIP](../../artifacts/windows-pharos-20261005/delivery/Pharos%20Windows%20r5x%20candidate%20final.zip)、[源码ZIP](../../artifacts/windows-pharos-20261005/delivery/Pharos%20Windows%20r5x%20Source%20final.zip)。Mac共享桌面.lnk不能当作Mac直接运行EXE。

固定第六节12门保持；复用项保留原版本身份，不当成最终EXE全部重跑：

| 原固定门 | 当前状态 | 实际范围与仍开边界 |
| --- | --- | --- |
| 正式入口 | PASS | 两条真实r5x build0、新产物正常消费、9497…纯系统PATH三x64模块、中文/空格文档自绘 |
| 人类输入通路 | FAIL（近上限） | 116B/5427B单投owner/画面通过；252000B原2500ms仅seq12/v13，完整范围连续链未完成 |
| 范围与 Unicode | FAIL（Shift） | 鼠标非空精确替换/零写选择，r5r代理对/分解重音/ZWJ移动删除复用；Shift首修23:23而非23:27 |
| 组合输入 | PASS（复用） | r5q实际安装IME/Ni+Space/Ni+Esc、0/1/0全文；与汉字注入分列，最终EXE未重跑 |
| 源码／预览往返 | PASS（已验fixture） | 同版实际Markdown、非空保持/免点击替换/Undo全文；新增预览滚动链。116B返源瞬间高亮缺口单列 |
| 人／Agent 共同操作 | PASS | 同实例人→公开Agent→人及全文/journal；r5f旧版/非法跨度/容量拒绝保旧复用。脚本客户端，不冒充真实模型 |
| 保存与复开 | PASS | 9497…保存151B/5462B、正常退出、新PID全文/续写；cdd7…151/152B也通过 |
| 几何与生命周期 | NOT_RUN（剩余子门） | r5w resize/minrestore/失焦/有限旧回调复用；预览滚后返源编辑通过，源码内部滚后远处点击/选择/输入仍开；未做物理跨屏 |
| 图片与失败 | FAIL（设备后首输入） | r5w实际PNG红/绿、有限坏图/预算保旧复用；设备代/count/[G]全文通过，首A seq0/installed_range_prefix_mismatch及REQ1终态未闭 |
| 响应与资源 | PASS（具名实测） | r5w20公开请求/80轮滚动/8次accepted移动、20输入时延及原资源数见前段；含IPC/探针、不计GPU完成，长文档原预算仍FAIL |
| 空闲与回收 | PASS（有界退出）；驻留增长未证明 | r5t失焦10s/5次关闭/旧3×4 worker退出复用，r5w实际blink单列；本worker236批BYE及32路径退休。末handles580高于早前514–518，不称长期零增长/无泄漏 |
| 同源交付 | PASS（混合构建路线） | 新空含空格目录新native/BC/obj/正式build0+正常消费，133文件/132载荷全核；普通build脚本build分支NOT_RUN |

资源c288f702…/exit0：8已知editor PID退休；8实际channel日志对应32个socket/descriptor/private descriptor/manifest路径，8个仍存文件仅在核无同run活消费者后清理这些精确路径，全部不存在，正文/journal/日志保留。SDK llc/llc-real均原1ea68362…。worker末handles580/RSS120545280B/private87142400B/threads15，本探针仅1作业目录、自身task与原conhost10840，其余作业退休。3908实际BYE_AND_SOCKET_CLOSED，宿主聚合exit1来自236批保留非零/RED，不是关停失败；单次prlctl只读终核3908/10840/专属session目录不存在，宿主8792/8802无监听。未杀用户/未知进程、改锁屏/剪贴板、stage/commit/push；E/H及受保护路径保持。

**剩余与升级。** 原A–F未完整实现范围承诺。Shift、设备恢复后首输入、252000B原预算三项真实首修失败保留，按AGENTS停止依赖猜改。后续指导分别区分冻结Shift修饰状态/选区锚点、设备请求13:13与安装14:14/候选终态、每次65536B共同prepare/DWrite成本和队列归属；成本分量尚未测得，不先归因模拟器/GPU。源码内部滚动、返源焦点反馈、驻留句柄增长另留开。独立构建、正常消费、最终文件/快捷方式及准确关停已完成，不为等待指导重复整套测试或自动调用其他顾问。


<a id="windows-r5y-execution-20261009"></a>
### r5y 实际执行接续（2026-10-09，原包仍在执行）

本节是上述指导的执行证据，当前状态仍见 ACTIVE；未把局部门绿改为 A–F 完成。新 worker PID15032/session35637620c94e4db98aa96b59e3c1896f，旧 worker3908已按原归属退出。用户另授权可用 Pi CLI deepseek-flash 作快速明确辅助：本轮限定 read/grep/find/ls 检查输入工具，exit0；不修改、构建、操作桌面，答复不作运行证据。

- 同步设备拒绝：真实 native Present-device-reset seam 原 status20/ticket0 RED（fbdca57b…/1），最小修复后4/ticket0 GREEN（cacf5d0d…/0），撤回33f2270f…/1。accepted旧正文/帧/布局票保留，原候选由既有共同回滚链结算；pump独立恢复，新候选接受。2709c2f8…/0同时复核resize及正确extended导航；不将COMMAND_IN_FLIGHT强判拒绝，相关完整待决边界仍开。
- 仅native变化121文件＋7配置逐项准入：MF2affcd8f…、native97011626…、实捕BCf02f558b…/obj497fcc7c…参数相同。首正式构建5dd19775…的SDK AV -1073741819原件独立保存；唯一同输入重建42eb85a8…/exit0/210.539s，EXEd2597a47…/23,525,888B、archive660be54e…，SDK恢复1ea68362…，不混称旧9497/cdd。
- Shift投递：仅MapVirtualKey scan仍产生numpad/额外Shift-up；明确standalone SCANCODE|EXTENDEDKEY对照在快速松开和延期消费后，冻结Left modifiers131072。只修验收工具，无Windows私有anchor。c304ad45…正常六组选择23:27、27:27、22:27、27:28、27:27、23:27，owner v14/全文/journal零写；原Unicode左三笔25:27→24:27→23:27。反向原工具把emoji步数算错，原件保留，按冻结字素边界独立算期望。后续真实Markdown预览、返源无额外编辑器点击替换X、UndoRedo、公共Agent与人类续写、SAVE151B/SHA77556583…、PID5168正常AltF4/kernel0均绿；freshPID全文151B相同，因模式日志先于accepted节点，工具reopen_body_rect先测到missing，重开输入未通过，不能写整链全绿。
- 新三对照：reset-only a67a2ea3…/54，gen1→2/recovery1，scene5失败一次→scene6真接受，完整owner116B不变；工具要求点击同一13:13必须新增selection日志而提前失败。no-reset e2d98655…/55/PID16616与原compound cc39f981…/55/PID12340都拒绝首A、完整owner119B/v2不变。归因0fd507ef…/55/PID11736启用已有恢复细节：id1/request13:13在scene6连续8次install33(SCENE_STALE)，随后range seq1/prev0/nonce2/proxy9/base2，而common expectedOwner1，故prefix_mismatch；不是设备仍挂候选，也未重投A。下一诊断定位第一native安装条件。
- 252000B/SHA c99d5110…原单28 SendInput/2500ms：83ad192f…/32/PID15500，terminal观测2526.7661ms未完，只11笔/v12。固定内存TRACE118条全部保留；原始输入约25ms出队，已记录DWrite新布局17.103ms、copy0.667ms、draw8.024ms、Present1.866ms主要在输入前，不能归咎实际场景排版占满2500ms。正补claim/copy→ACK关联及安装条件的固定内存计时；无每输入文件I/O、未放宽预算或提前选定性能修法。

原件集中在 `artifacts/windows-pharos-20261005/evidence/20261009-r5y` 及上述 session 的 raw JSON/guest-results。后续需完成恢复首A、原预算13笔、公共Present状态审计、源码远滚即时编辑、实际返源画面和同版本受影响验收、同PID等量资源循环归属、最终normal/portable/含空格source交付。


**r5z 同二进制完整 Shift 链与精确计时（2026-10-09）。** 此记录接续并校正上面的 c304… fresh-body 工具门失败，不覆盖原件。r5z 仅 native 诊断改变，121+7cfg MF13cbefb8…准入后，c8636fa6…真正 build0/195.204s，EXE188dfda441de1c9ed5c76c805f4be503407a3e312984ea04ca9316de6be75ce3/23,527,936B、native archive8661bb61…；实际BCf02f…/既有新obj497f…相符，SDK原llc双hash恢复。工具只在原10s观察窗等真实已接受节点，未重投输入或改变固定性能预算。

cfd611bab72f4322a574a55f410d0b11/exit0/45.539s、PID3068→fresh18328，同EXE/default1100×780：13笔116→134B/v1→14；独立E0导航键六组扩展/反向收缩/跨anchor/Unicode，纯选择零owner/version/journal写；真实Markdown往返后未点编辑器即X精确替换“1中😀”8B→1B；首次Undo/Redo、公开Agent→人五笔、SAVE151B/SHA77556583…、正常AltF4/kernel0，fresh全文一致，原UTF16 79单次R→152B/v2/SHA33fcd096…，二次正常关闭0。[独立完整字节复算](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r5z-shift-main-full-byte-check.json)核10份全文/22笔journal。已查看两张真实画面：116B选区在返源后仍蓝色高亮“1中😀”。Shift本次闭合为工具投递修正；未改共同anchor。旧失配原件保留。

252000B固定负载243a463b95d3408887cb6e92977fc9c9/exit32、PID19648，2533.659ms截止Complete=false，不能以稍后的第13笔宣布原2500ms通过。[桥接计时](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r5z-nearcap-owner-bridge-segments.json)保留202条最终native记录：13笔claim/copy/ACK派发等待合计不到1ms；多数copy结束→ACK约10ms，ACK→下一claim约188–202ms。固定预算内只有stdout终态观察，没有Agent读取；故首要未归因段是共同宿主回合间隔，不能把DWrite17ms或ACK体当190ms主因。原始burst与final采样分列。

06badf0b…/exit55、PID5620无设备恢复对照仍第一笔A拒绝，owner119B/v2完整不变。8次selection_install33的expected/native scene均6；request/binding/node/resource/enabled匹配；第一笔native base2而共同expected1。accepted正文/resource/kind尚待新诊断分开核，不能宣称已有根因或放宽来源门。READBACK_FAILED13在当前Windows路径没有返回点；第一次readback在Present之前，失败99不晋升accepted。真正仍开的提交协议是COMMAND_IN_FLIGHT38结果未知，不能当明确拒绝，需沿现有票据Query/ACK补齐，不能强回滚。

66a4f988b3194c038d9351eb7f1251d6/exit35、PID2060真实源码多行内部滚动RED：5427B/ce0b6aba…，8项一次SendInput wheel -120全投递，首字坐标301→301、远处UTF16 185坐标2025→2025，scene4/lease286未移动；完整owner/v1/journal零写。[全文复算](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r5z-source-scroll-full-byte-check.json)通过保旧。后续远处点击/非空选择/立即输入因滚动依赖未执行。源码确认Windows只转声明滚动容器，多行输入未有内部offset；Mac已有按node/resource的私有视口、绘制/命中/IME共同变换可供机制复用，本包不会引入外部框架依赖。

**r6 仅归因同源编译的捕获记录（随后正式构建见下）。** Windows接已有共同owner phase内存记录，Mac分支保持；canonical owner_turn_budget.cj仅18+/4-，native固定8192记录、批量显式取回与install_node诊断，无逐笔I/O/放宽预算。冻结MF40a8568c…只2项变化，其余构建输入逐字相同。实际capture6b9283eb…/219.406s到capshim94；底层build1是预期截获，不能称build0。SDK原hash已恢复。新BCf02f…/28,597,488B由新Mac llc PID5032真正exit0/961.559s产出COFF8664/5,609,672B，obj497f…虽与旧相等仍实际新编译，未绕过共同源码改动的capture→新llc→relay要求。该条记录时正式relay在途；随后真实成功见下，捕获build1仍不当build0；[准入](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-trace-admission.json)和原件保留。

Pi deepseek-flash本轮两项有界辅助为诊断代码只读审阅、生成只读worker句柄类型工具，exit0原prompt/answer/stderr保留；主执行者补边界/身份校验并实际验AST/运行，不把模型答复当验证。worker仍15032；首次578句柄中151个typeindex56复制查询失败具名Unknown，不报告全类型归因或零增长。最终同版设备/256KiB/源码内部滚动/受影响IME与PNG/重叠资源/便携及独立源码交付仍待完成，原A–F目标保持，未stage/commit/push。


**r6 当前接缝与性能执行结果（2026-10-09，最终同版验收仍待完成）。** 归因正式relay `836b10c9…/0/214.203s`，EXE `8d426dabda3cef3ac4f6a5247c06f0e678db3b2bb2d6aae8637547bd683bbe16`。随后仅native焦点延期，正式 `7a87830f…/0/179.380s`，EXE `bf25dd6614bf2c9265702943df3aad228bf846d972fbc8c4c7d517e5cfcb9bac`，MF8682095a…，实捕BCf02f…对应已验新Mac对象497f…；两轮SDK原件双hash恢复。bf25只含焦点延期，不含随后票据、公开deferred转送或源码视口修复。

- 性能归因：`5afb672d…/1/PID11600` 原252000B/SHA c99d5110…、单28项SendInput、2500ms窗内terminal观测2490.5434ms/13笔/v14，完整252018B逐笔合法；但后续Agent→人5笔在500ms时仍推进，分块读全文报owner_chunk_identity，原整链失败保留，不称近上限最终通过。[phase原数](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-owner-phase-profile.json)：phase362包括outline/search/table及build，14次合计2384.562ms/max182.577ms，实际DWrite布局max7.852ms。查实tableGrids即使缓存命中仍先全文读取/解析，且源码模式不消费grid。只回正典三处匹配块：源码跳过grid查询、dense/whole grid键匹配先于正文扫描；加已有内存phase364/366，不丢owner意图、不换排版协议。新MF255eba91…只main hash变，capture0324…预期截获/SDK恢复，实际BCb33a45f7…/28,600,660B；新的Mac llc正在编译，尚无对应新EXE或性能GREEN。
- 三对照：bf25无设备 `7ab056cb…/0/PID16800`，Agent[G]/resize/minrestore后首A一次发送成功、20筆完整owner/journal和正常close通过；复合 `48f21b99…/55/PID14068` 实际gen1→2，匹配正文/节点/请求的8次install已返回20，却共同attempt_limit。第一个新断点是public wrapper只在OK复制outDeferred，20时丢标记，common未获得既有延期语义；公开入口RED `f28e3829…/1` 证实20/deferred0，最小转送后 `58097133…/0` 为20/deferred1，错scene/body/binding仍33，恢复同票精确安装/nonce/finish一次。未增加attempt预算。reset-only `7451dada…/54` 卡在工具要求不变13:13必须新增selection日志，未发送首A；需用当次native INPUT_STATE及accepted正文的只读对应核无操作选区，不改产品制造日志。
- 未知提交：实DXGI Present用kernel event阻塞超过原30s，公开RED `83dede83…/2/64.009s` 两终态都38/ticket0。只沿既有Present/Query/ACK补private唯一票据与POD终态，global锁只保凭据、不等待UI/GPU；`b11c6803…/0/64.136s` 真正20/非零ticket，UI仍阻塞时Query Pending可用；pending ACK/关闭拒绝、实际接受或设备拒绝终态不可变、ACK与重复ACK、ACK后NONE、实际close均绿。已知同步DXGI失败仍明确4。新票据与public deferred目前仅有限renderer验收，待最后正式normal构建，不能外推共同窗口整个超时链完成。
- 源码内部视口：只读参考既有Mac同node/resource视口、DWrite同源绘制/命中及本地Zed滚动clamp机制，在Windows私有字段中实现offset；先准备有限raster再替换accepted节点，失败保完整raw记录；同一offset用于文字/选区/命中/IME几何，同绑定续帧保留，新绑定清除。首有限夹具把30,35物理像素当逻辑坐标，192DPI落框外，原5ed39…失败保留；工具按当次DPI和accepted节点生成60,70物理坐标、核真正命中后，撤回旧native `084c9190…/1` 四RED，新native `031c57dd…/0` 位移/远处384命中/真实像素/FIFO/epoch/lease与全文不变通过。后续分配压力与换绑定负控进行中；原正常应用5427B/8wheel/远处185即时输入门仍未被最终EXE闭合。
- worker同PID资源：[四次类型对照](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-worker-typed-resource-comparison.json) 为578/File39→582/File43→580/File41→578/File39，其他可识别类型稳定、threads15；151个typeindex56具名Unknown，非全类型或editor零泄漏证明。Pi/deepseek-flash只读/生成工具答复与实际AST/运行分存，不作生产证据。

后续将这组已验native接缝与新grid对象组成同源正式EXE，再原预算/单次投递完成完整近上限链、三设备对照和源码远处即时编辑，补受影响IME/PNG/重叠/资源/portable及独立含空格source构建。既有r5z绿线保留；原A–F不改完成，E/H及用户候选不覆盖，未stage/commit/push。


**r6组合正式构建已完成，正常消费开始。** `634d074597d04d7b8a2d1f9e6889d621/exit0/171.596s`，MF `56924b38db4f73d52eaedc65a34fac396e6dfe51e7d106e5f66068bc16ae428f`、native `bd058fcb…`、archive `bd749a57…`、EXE `2424dcbd0ab8e62eb8201569681571a5134f88b7472e72bb727e889142e0dafd` /23,538,176B。来宾正式构建实捕BC `b33a45f7…` 后才注入新Mac llc PID67366/exit0/917.064s产出的COFF8664/obj `d707fc48…` /5,612,542B，SDK原件恢复1ea68362…；[构建身份](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-actual-build.json)含6项产物，不能将旧bf25当本版normal证据。组合只在grid阶段修改native，其余121来源与7cfg hash一致。[有限门准入](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-admission.json)如实保存c899…整作业exit1：实际source/Pending Accepted/Rejected三case均0，第四错误拼写install-minimize未运行exit2；正确source-install-minimize单独a799…exit0。压力保同一raw批次、换绑定/弃置/短正文clamp、票据重复Present不重投、wrong ACK/终态统计与重复ACK不重计均通过，没有为工具错名重复三项30s超时腿。


<a id="windows-r6-final-delivery-20261009"></a>
### r6 原 A–F 完成交付（2026-10-09；256KiB/来宾范围）

**原三项失败均已在最终正常 EXE2424dcbd… 关闭。** 生产修复为：已知未接受的设备帧具名拒绝并由共同候选回滚；不可取消、结果未知的实际Present使用唯一票据、真实Query/ACK和终态统计；公开安装正确转送延期输出；源码multiline拥有私有视口偏移，并统一绘制、命中、选区与IME几何。Shift只改系统INPUT工具为独立导航键的E0/scan身份，共同anchor和扩选机制未改。分段成本证明重复产品查询是近上限输入的主因，因此源码模式跳过未消费table查询，缓存先核version/window再复制扫描；没有把异步尺寸测量说成Windows通用异步场景准备。共同owner-turn诊断仅按Windows现有计时桥接最小接线。没有覆盖E/H全树或引入外部GUI依赖，参考机制与早期RED仍见本段前文。

[同版完整构建身份](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-actual-build.json)对应MF56924b38…/121源码+7cfg、native bd058fcb…、实际BCb33a45f7…、Mac新llc PID67366/exit0/917.064s、COFF8664 objd707fc48…、真实cjpm build0，SDK恢复1ea68362…。有限门c899…overall1的错拼case未运行与随后正确a799…exit0均保留，实际source/Pending Accepted/Rejected已通过，不删原失败。

| 原固定门 | 本轮状态 | 证据与边界 |
| --- | --- | --- |
| 正式入口 | PASS | 同版2424…默认logical1100×780、实际中文/空格路径；portable纯系统PATH三模块均来自包内x64。独立源码目录本轮另验。 |
| 人类输入通路 | PASS | 5eb4a50a…/exit0/PID8232→11584：固定252000B/c99d5110…、单次28条INPUT、13笔v1→14，1549.8498ms<原2500ms、无重投/慢打；完整链22事务及10份全文复算。 |
| 范围与 Unicode | PASS | 11d8fe7e…/exit0/PID3804→11984：六组Shift扩展/收缩/跨anchor，23:27→27:27→22:27→27:28→27:27→23:27；纯选择零owner/journal写，跨汉字/emoji精准替换。r5r代理对/分解重音/ZWJ移动删除未改机制，旧版具名复用。 |
| 组合输入 | PASS（系统IME核心及后续链） | 18f82111…/PID1180实际HKL08040804：Ni真实preedit零事务，Space提交“你”恰一事务，Ni/Esc取消零事务；随后13笔Unicode→Agent→人、SAVE161B/正常关闭和fresh17072全文均通过。raw overall49停在旧工具fresh body rect时序，fresh输入未跑；同版小/近上限/portable新实例输入独立通过，不伪改raw为0。 |
| 源码／预览往返 | PASS | 同版小文档及252000B均实际Markdown列表/强调/代码块、蓝色非空选区、返源无额外编辑点击立即X、Undo/Redo。已检查截图；旧未绿瞬间原件保留。 |
| 人／Agent 共同操作 | PASS | 同实例公开JSON协议真实客户端/完整字节与journal；三对照各20笔真人路径；02e166f5…20请求（10读10写）均与80项系统wheel区间重叠，实际9次accepted几何变化。真实外部模型NOT_RUN；r5f非法跨度/旧版/容量拒绝保旧具名复用。 |
| 保存与复开 | PASS | 同版小文档151B/fresh152B；近上限252035B/SHAe4cccbf8…/fresh252036B。两次AltF4由预持有内核handle核ExitCode0，不以force-stop替代正常关闭。 |
| 几何与生命周期 | PASS（虚拟来宾范围） | c50811ce…/exit0/PID19060：一次8项wheel，far185 y2041→892、accepted scene4/lease286、5427B/v1/journal0保持，真实远处点击→185:188→一次X，7字节替换为1字节，完整5421B/v2。三组resize/minrestore及实际192DPI坐标通过；物理跨屏NOT_RUN。 |
| 图片与失败 | PASS | a01cd429…/exit0正常PNG实际红/绿屏幕像素/正常关闭。设备reset-only26e62e…、无reset的Agent/resize/minrestore6e7b62…、原复合13e0038…均0，各20笔实际A…T全文/每笔事务通过，首A各仅投一次。有限WIC坏图/预算/alpha/crop未变项复用原版证据；未知Present不强判回滚。 |
| 响应与资源 | PASS（具名有限负载） | 三组owner p95分别50.863/49.899/103.072ms，accepted观察上界99.621/99.180/138.363ms，含IPC/file/probe，不减等待或声称GPU完成。20请求滚动实际raster/upload147次/54,585,536B，15个完成帧，scratch0；新owner phase362合计1252.168ms，outline仍1246.532ms，未宣称16ms或GB性能。 |
| 静止与回收 | PASS（有限范围） | 0d770535…/exit0/PID13904真实系统caret blink5次翻转；idle10.017s CPU0.515625s/单核5.147%，layout/raster/upload/资源不变、19帧为blink；四次预热后两组各10次minrestore，typed handles364→365→364，差异仅File27→28→27，Unknown type56=109保持。worker15032四快照578→582→580→578另列，151未知类型保留；未称长期无泄漏。旧失焦idle/3×4worker关闭未影响项具名复用。 |
| 同源交付 | PASS（实际混合构建） | 新空含空格目录native新编译，实际BCdb0dea44…/新Mac llc PID10939/objf93d182b…，83c0a879…正式build0；独立EXEda3027c8…正常完整链7ab2bff2…/exit0及22事务全文复算。最终源码ZIP142文件另在新目录7a785238…/exit0逐项核对，普通完整build脚本分支仍NOT_RUN。 |

[252000B全文复算](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-nearcap-full-byte-check.json)、[Shift链全文](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-shift-full-byte-check.json)、[源码远处全文](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-source-scroll-full-byte-check.json)、[三对照120份全文/完整journal](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-three-controls-full-byte-check.json)、[IME全文](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-combined-ime-full-byte-check.json)及[portable全文](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-portable-full-byte-check.json)均由原owner字节、冻结recipe、UTF-16跨度和校验journal独立核对。新验算工具初次误用native哈希种子/IME旧聚焦位置及BOM读法被原件挡住，修正为当前契约与原recipe后才生成PASS；未改变生产判据或重复输入。252000B raw summary沿用旧KeyboardShift caption，这个recipe未跑Shift，六组Shift仅以独立actual green原件为准。

便携同版主链001d46e2…/exit0/PID17656→12684，22事务/10份owner/save151/fresh152全文通过，三实际非系统模块均包内。ZIP78f285c1…含6文件、MF列5载荷、3PE8664，见[ZIP核对](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-portable-zip-check.json)。首次快捷方式即时COM读回50f507d0…/exit1保留；随后独立d3e75fe5…/exit0实际Target/WorkingDirectory逐字正确，d79d0721…/exit0固化record，没有重建或改目标。Windows桌面入口 **Pharos Mark Windows r6**，目标C:\cjgui-windows-w1\delivery\Pharos Windows r6 e9e8a19f74b349528a62fc1bf093945f\Pharos Mark.exe；[宿主应用ZIP](../../artifacts/windows-pharos-20261005/delivery/Pharos%20Windows%20r6%20final.zip)。旧9497…候选、快捷方式和cdd7…独立源产物保留。

含空格源码首native工具b1ff3225…/exit1准确暴露windres内部cpp切开带空格绝对-I；以native为cwd、相对-I .及.rc修正，保留原三工具/ZIP/日志。493ce40a…/exit0实际native0和新BC捕获，底层Windows llc退出-1073741819为已知编译器墙，不记正式build0；SDK双原件恢复，来宾archiveb498d56f…由新路径产生。此项不改变128份构建输入。普通build-windows.ps1完整build分支NOT_RUN；实际路线是native→capture→Mac llc→核BC/obj的正式relay。源码包保留精确执行配方与限制。

**保留范围。** Windows11 ARM64来宾/x64模拟/虚拟GPU；<=256KiB Markdown正常写作，预览非结构编辑，Windows四项general preparation仍unsupported。物理Windows显卡/跨显示器、真实外部模型和1GiB/16ms不在本包证明内。native修改实际写入会话candidate/accepted/ticket/viewport/输入安装投影；正文仍由DocumentSession事务归属、保存通过真实服务。runtime_state.cj、renderer_state.cj、cjpm.toml本轮W未改；E/H、用户实例/正文/剪贴板/暂存/stash保留，无stage/commit/push。


**独立源码门已完成，以上12门按具名范围汇合。** 83c0a8791d8d4123a7c37fab688273d3/exit0/212.804s真实cjpm build0，实际BCdb0dea449e648372bb6a1d889f834294fcc48a77fec7692003cc8ef42ebd06cb对应当次Mac llc PID10939/exit0/1162.030s、新COFF8664 objf93d182ba11b52b3e9b6cebd2ca44c89feada7aa6e0c8284772b30bfa49c6073/5,612,541B；native archiveb498d56f…、新EXEda3027c80e9fe77eb31e2c6b8bab90ca8c1fe63238b95421190f555fe6f1c55c/23,537,664B，全部来自新空含空格r6-source-final目录，SDK恢复。7ab2bff24fc54b14b61267c4c7191f2f/exit0/45.812s、PID18076→fresh4024完成默认窗口/实际SendInput/六组Shift/Markdown返源免点击替换/UndoRedo/公开Agent后人续写/SAVE151B/两AltF4 kernel0/fresh完整151B并R→152B；[独立源正常链22事务及10份全文复算](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-source-final-main-full-byte-check.json)通过。[构建6项产物](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-source-final-actual-build.json)与主应用2424…分别标识，未以相同源码混称相同EXE。

[最终源码ZIP](../../artifacts/windows-pharos-20261005/delivery/Pharos%20Windows%20r6%20Source%20final.zip) SHA22247df26dc7009ae294afb614fa73c5e87515273c40a0116994a21cfdc803da：121源码+7cfg+精确native/capture/新Mac/relay构建配方与元数据，142实际文件/MF列141载荷；128构建输入与两次正式构建保持。7a7852381266476eb83ad55c1478cab6/exit0/1.435s在另一个新的含空格目录实际展开、全bytes/SHA/文件数/VerifyOnly0，未复制target；交付目录C:\cjgui-windows-w1\delivery\Pharos Windows r6 Source final 9dbe0edb27da4e1093e80ab8c5e392d4\Pharos Mark Windows Source。普通完整builder分支NOT_RUN、Windows llc编译墙与实际混合路线明确写在[README](../../artifacts/windows-pharos-20261005/delivery/Pharos%20Windows%20r6%20Source/README.md)，不宣称Windows独立原生代码生成成功。应用ZIP仍78f285c1…/主EXE2424…，旧用户候选和入口保留。

**准确收尾完成。** be6d16c4e38045979a2b453faaac5e93/exit0确认31个具名editor PID无对应活消费者；38条实际channel日志对应152个精确socket/descriptor/private descriptor/manifest路径，核无同run消费者后仅移除这些文件，读回全不存在，正文/journal/日志保留。当前检查作业目录1、直属子进程仅自身PS和conhost5692，前作业全部退休。原worker15032最终typed snapshot93bb6fd4…/exit0：560handles/File41/threads15，Unknown type56=151和4次复制失败明确保留；关停前另一资源快照548handles，不混用两次数或声称长期无泄漏。121批后WORKER_SHUTDOWN BYE_AND_SOCKET_CLOSED，宿主聚合exit1仅含保留RED/nonzero作业。准确后检worker15032/conhost5692均不存在，实际TEMP/pharos-worker-35637620…目录不存在，SDK llc/llc-real双hash1ea68362…，宿主8792/8802无监听；首次后检猜错sessions目录原件保留并排除为证据，随后按真实worker源码取TEMP路径复核。见[交付与清理原件](../../artifacts/windows-pharos-20261005/evidence/20261009-r5y/r6-final-delivery-and-cleanup.json)。

必要本地链接、git diff --check及冻结source/config/header/外部运行依赖声明扫描通过。没有新增公共renderer签名或外部GUI运行依赖；CodeLattice图不可用仍不作为运行证据。原A–F在<=256KiB/default窗口/该Windows来宾范围交付完成；上述明确NOT_RUN与通用框架欠缺保留，不扩称物理设备、所有IME/长期资源/完整async preparation已验。
