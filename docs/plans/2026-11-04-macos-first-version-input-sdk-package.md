# Mac 首版普通输入与公共 SDK 收束

执行者：用户选择的 DS4.1 Flash。工作目录：`/Users/jiangxuanyang/Desktop/cangjie`。

这是一个完整实施包。直接接续当前共同源码和已接受成果，完成范围内的实现、必要验证、公共交付与收尾，最后集中报告。不要停在盘点、计划或逐小点完成报告；普通语法、构建、工具、接线和既有契约内的问题自行解决。指导负责取舍和审阅，你负责实施。不要恢复旧 Sol、旧 DS、H/W/Linux、顾问或自动监控，不自行换执行模型、创建新用户线程或调用外部咨询。

## 1. 目标与基线

目标是让普通开发者通过公共 SDK 获得可连续使用的 macOS 单行/多行输入，以及人与外部客户端共用 owner 的正常操作。保持仓颉核心、自绘、窄系统桥、手写/生成/混合共用机制；不做新编辑器、新输入法、富文本工程或第二套状态机。

先读 AGENTS.md、runtime/cjgui/ACTIVE_DIRECTION.md 的 E 段、本任务和直接相关源码。仓颉知识按 `/Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md` 按需查阅。大方向依据 `docs/plans/2026-09-26-framework-capability-roadmap.md#first-mature-version`、`docs/core/AI_NATIVE_UI_SEMANTICS.md` 与 `docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md` 的相关段落；不通读历史阶段。

直接承接已接受的有界批量传送：
- 正式 SDK：`work/macos-performance-20261103/frame-opportunity/backport-20261104/sdk-official-20261104c`；内容 `4c590433…`，622 输入锁 `4cdcb808…`，closure `f06c473e…`，646 载荷加 manifest 共647文件。
- 共同 window `79eb19a0…`、session `582686c6…`、native `59d2db6d…`。冻结 SDK 只读；实施仍回共同根，不形成长期私有核心。
- 最终 O2 EXE `fd2ae2f1…`／native archive `8e34e65e…` 的 R2f 真实1000条链已接受；具体结论见 `docs/plans/2026-11-03-macos-performance-first-version-package.md#guidance-bounded-batch-closeout-20261104`。

开工只核本次会用的来源、工作区并行改动与当前执行实例，发现漂移先辨归属，不重算整套旧锁或重审全部旧交付。批量优化已收口，不再把它当未完成项。

## 2. 普通输入：复用现成通道，只补真实缺口

以现有 TEXT／MULTILINE、整值／owned 输入路由和系统输入代理为基础。先用当前实现、公开说明与直接原件，简记首版实际支持和本包具体缺口，随后立即推进；不要另建输入矩阵或审计台账，不因某个组合历史未测就新增任务。

在已声明支持的正常使用范围内，接清：
1. 系统中文组字的 marked、提交与取消；普通 Unicode/emoji 的正文和 UTF-16 选区对应。单行、多行各按真实控件语义处理回车、换行和提交，不强行统一。
2. 焦点暂离、说明层/模态返回后，已有文字和选择保留，首个输入进入原目标；不靠额外点焦、重发或等待掩盖丢键。
3. 人编辑后外部读回同一正文/草稿；外部合法更新后人能继续编辑；旧版本、旧绑定或旧选择请求拒绝时不改正文、不污染另一个 owner。

已有证据适用就直接复用。仅对已确认漏接、真实故障或本次变更影响的边界补证。发现正常支持路径未接通，先保留实际 RED，再修原责任模块；不能只改文案把需要支持的能力删掉。若原件已足以证明现有能力正确，不强造生产改动。

优先沿 `runtime/cjgui/src/composable_ui_window.cj`、`composable_ui_mac_text_continuation.cj`、`text_session.cj`、`runtime_renderer_session.cj`、`runtime/cjgui/native/cjgui_internal_renderer.m` 及 `shared_operation_core` 的现有责任查明问题。共同 owner、正文/草稿、版本、选择和拒绝规则留在共同实现；系统回调、原生焦点和资源留在平台桥。通用机制确实不明时按 DESIGN_INTENT_INDEX 的本地参考定位一个相关实现，只读借鉴，不引入外部 GUI 依赖。

保 FIFO、owner/field/binding 身份、CAS、选择/marked、旧 accepted 画面、候选取消/回退及 FFI/GPU 释放。旧回调检查只随实际影响补，不穷举所有迟到交错。Unicode 注入、AXSetValue、私有直接调用不能冒充真实系统组字；用当前可用的系统输入源，不修改系统设置，不自研输入法。遇系统通道或工具不可用，保留准确限制，停止反复撞同一工具，继续独立项；不能据工具失败判产品 RED，也不能伪称通过。

## 3. 消费者与验证范围

主消费复用 `runtime/cjgui/templates/macos_application/mixed_form`，多行文档复用 `runtime/cjgui/examples/shared_document_window_app`。复用原场景、业务 owner、公开客户端和驱动，不新建第三款应用，不为凑验证把 shared 业务硬改成表单 Apply/Cancel。

先选能覆盖实际新改动的主消费者，相关修复汇合后完成一次正常连续会话：真实输入、状态/选择读回、窗口反馈、按该应用原有语义应用/取消或保存、独立完整正文/文件期望、自然退出及端点清理。第二消费者仅补主链不能覆盖的新影响。双 owner/多窗只在变更涉及其责任或必要新边界时补，不机械重跑。

明确复用、不得重复开跑：
- 批量分块、混合槽、跨字节、合法单项回退、交互重绘和原恢复/中段失败/关闭/公平性已验范围。
- `work/macos-performance-20261103/frame-opportunity/pairs/R2f-final-o2-apply` 的1000条 filter20/name20、Apply21、全文件 `32b93a15…`、Cancel22保持已应用值、自然exit0。Cancel证据不冒称新的脏草稿撤销实验。
- shared `work/macos-performance-20261103/frame-opportunity/backport-20261104/pairs/S1-shared-document-official-20261104d` 的 ASeed/版本/保存/自然exit0，及此前已接受的双 owner 保护，均按实际身份复用。
- `work/macos-performance-20261103/runtime-input/RESULT.md` 中7f54运行输入包的 WeType 单行 owned marked取消、原 UTF-16 选区、帮助返回首键及双 owner 保存；其他系统提交原件仅按已验通道复用。
- eb58/eda 的真实 VoiceOver（原件入口见当前 MACOS_CANDIDATE）；`docs/plans/2026-11-02-macos-dynamic-document-workspace-package.md` 中已接受的动态文档、绑定、生命周期；其他未改平台和历史矩阵。

只有本次修复实质影响上述路径、出现新失败或存在具体证据疑点，才做对应有限回归。Rules确受影响时用原1000条负载补一次正常链，不重跑四类80、旧性能对照、十轮资源矩阵。每次新验证必须能改变实现、风险或交付结论；相关改动汇合后统一验，不逐补丁重编/导包。保留失败、慢值和取消原件，不降低断言、缩负载或重投刷绿。运行前准备等待就绪应检查实际 descriptor/目标窗口，不能只等经理状态文件存在。

桌面按 AGENTS 的既有授权操作，优先 agent-desktop 的可访问性观察和语义动作；真实系统组字用实际系统通道。保护用户窗口/剪贴板，自有实例串行复用。用户接手或要求暂停时停止前台操作。正常消费诊断默认关闭，必要诊断另列，不能与默认 OFF 混称。

## 4. 公共 SDK 与开发者入口

沿原公共建项/构建/导出机制收束，不新造 profile、镜像、包装器或输入专用协议：
- `runtime/cjgui/scripts/create_macos_application.sh`；
- `runtime/cjgui/scripts/run_macos_application.sh`、`macos_build_config.py`；
- 既有 mixed-form 模板、shared-document 普通入口、`shared_operation_core/client.py`；
- `runtime/cjgui/README.md`、`runtime/cjgui/preview/MACOS_CANDIDATE.md` 和直接相关消费者说明。

普通开发者从公开 SDK 入口就能构建并使用上述能力。正常接入只依赖所选 SDK、声明的工具链和系统服务，不依赖仓库作者的私有工作目录、测试宏、手工重链或未声明缓存；生成的绝对依赖可以指向用户实际 SDK 位置，不能固化作者路径。已有包外消费适用就复用；只有建项、依赖运输或输入接线确有缺陷时补最小公共修复。不要为证明已工作的入口复制一整套工程。

可选全链 O2 沿已验证运输与缓存身份使用，Cj/native 实际参数和来源可解释；默认配置不改，保留调试/兼容用法，不把编译参数收益冒充本包源码收益。

公共说明面向开发者：怎样接入单行/多行输入，谁拥有正文、草稿与选择，如何让外部调用进入同一操作，当前支持范围、具名拒绝和宿主限制是什么。把旧性能轮次细节留在阶段原件，公共页面保留准确当前结论和必要证据链接。不要只做文档整理就宣称补齐能力，也不要把 experimental 改 stable、擅自发版本或远端发布。

相关变更汇合后只交付一个正式 SDK 源闭包和原格式锁。编译闭包未变时可按身份复用既有 App，不为文档变化重编；无载荷变化不为阶段改名再导一个相同包。若闭包变化，按新影响完成一次普通包消费，再核源锁/载荷/实际编译来源。测试夹具仅走根或既有合法 testing 入口，不能把测试符号塞进生产归档。

## 5. 性能边界与升级条件

本包不继续32ms专项，不重开 CAMetalDisplayLink、drawable数量、vsync、等待预算、缓存试投或单主线程架构改造。原32ms仍未通过；旧16ms只属已验 ON 两类责任边界，旧4354对照不重命名为最终新源收益；raw presentedTime=0仍unknown，不用 accepted/GPU/截图补真实呈现。

新实现若造成普通输入卡死、丢键、明显退化或无界资源增长，属于本包缺陷，必须处理，不能借上述边界忽略。一般局部问题独立解决；涉及状态归属、线程架构、FFI/GPU生命周期的重大问题且根因或安全方案不明，或连续低收益需要改变方案时，只暂停依赖部分。集中提交精确反例、相关差分、已排除假设及建议给指导，其余独立项继续；不按文件/补丁索要批准，不自动找顾问。

## 6. 空间、协作与收尾

遵循 AGENTS 的容量、并行写集和退出规则。无 Git 写，不切分支、不覆盖他方改动；同 target 构建/测试及前台串行。

承接前包实际累计账，不重新获得每线10GiB，不清零历史占用/释放。为本包受影响消费者、必要反例原件和唯一SDK，统一批准在前包已核实际累计基础上额外留存不超过512MiB、额外同时临时峰不超过768MiB；E/DS为同一份增量，不能双计。只按实际需要使用，优先复用可再生构建槽，冻结SDK/唯一原件/旧runtime target/用户或他方实例不动。开工及高写盘前补全实际路径累计、必要隔离和退役点；峰后宿主至少20GiB。超出本包额度才集中给精确方案，不为普通余额反复请同义确认。

指导准备任务时抽样：backport796124KiB、private-b4c-batch600880KiB、pairs107064KiB、根Rules target180172KiB、native/lib9380KiB、native/testing10816KiB，宿主可用156045869056B。这只是所列路径当前分配及宿主瞬时读数，不是全线累计或净增；嵌套路径不重复计，开工使用实际读数。

每个实际需要的消费者一个可复用构建槽，不按轮号克隆全仓/SDK/target。失败证据保可复判输入、精确源/二进制身份和必要日志，不因此永久留下每次整套构建树。成功/失败/取消均由驱动finally收尾，按准确身份清理自有进程与端点；删除可再生产物前核归属、无锁/无占用且原件已保全，不猜删。日志按AGENTS限量。

## 7. 结束条件与集中报告

完成后集中报告一次，不要求指导再让你回传同义收口。报告先写实际解决了什么、普通开发者现在能怎样使用，再给：
- 本包实际差分与共同归属；真实新增缺口如何从RED到修复，或为何现有实现已足够。
- 支持范围、必要新消费结果、完整owner/正文/版本/保存/实际退出；原件链接、来源身份和真实限制。
- 明确列出直接复用而未重跑的绿证；工具失败、产品失败、未知分别保留。
- 唯一SDK、公开使用入口、源锁/编译身份；默认配置与experimental边界。
- 新增/保留/实际退役的空间账、宿主余量、剩余具体事项。

把结果写回本阶段，ACTIVE E只维护一段不超过600字的当前摘要，不新增逐轮台账。该摘要区分“本包完成”与“整个首版/性能达标”。本包完整验收就是上述受影响范围，不是历史整仓/全平台矩阵。完成有明确支持范围、正常接入与必要修复的实际交付后停止本包；不自行续造输入排列组合、性能日志阶段或全功能设计器。

## 8. 执行结果（2026-11-04，DS；默认 OFF，指导复核范围见第 9 节）

**实际改动。** `textView:doCommandBySelector:` 原先未消费单行 Return；现只在无系统组字时对 `TEXT_INPUT`/`INTEGER_INPUT` 消费 `insertNewline:`/`insertLineBreak:`，多行及 `hasMarkedText`/`compositionTerminalInFlight` 交回系统。native `59d2db6d…`→`06a30fcf…`；共同 `composable_ui_window.cj`、`runtime_renderer_session.cj`、`text_session.cj` 未改。测试脚本补链 `cjgui_async_multiline_measure.m`，扩展测试直接调用生产代理：执行者报告 RED exit8（单行 Return 未消费）→ GREEN exit0（TEXT/INTEGER 消费、多行 NO、marked text 不消费），日志与二进制保存在 `work/macos-input-sdk-20261104/evidence/focused-input-skip-{red,green}*`。这是代理级行为差分；原问题是否为 Return 导致失焦、修复后正常首键是否保留，尚无该实例的真实按键闭环。

**当前源码正常消费。** 公共 creator 生成 mixed-form，`verified=true/testing=false`；签名 EXE `dc6e23fc…`、renderer `123707a0…`。native 实际 O2；原报告“三包实际 O2”无保存的 Cangjie 显式配置支持，不能作为 O2 性能样本。同一正常实例外部 `card-set` 将 cardA/jobName `资料 A`→`外部更新🙂`（draft v1）；旧 `--expected-draft-version 0` 返回 `APPLIED false/CONFLICT true/VERSION 1→1/REASON stale_draft` 且正文不变；`card-apply` `APPLIED true/VERSION 1→2`；814B 工作会话独立解码 draft/applied 均 `外部更新🙂`、cardB 保持 `资料 B`；关窗走原 guard，自然 exit0、forced 空、端点清空。原件 `work/macos-input-sdk-20261104/cases/mixed-final/`。前台系统键盘未形成可读回增量，原因尚未区分，不认定为已定位的工具限制；真实组字/选区/焦点返回按 7f54 原身份复用，不覆盖新增 Return 分支。

**复用。** R2f 最终 O2 的 1000 条 filter20/name20、Apply21、全文件 `32b93a15…`、Cancel22、exit0；7f54 的 WeType 单行 owned marked 取消、UTF-16 6..8、说明层返回首键、旧 draft 拒绝、双 owner Apply/Cancel/保存；S1 shared 单窗口 ASeed/版本/保存/exit0；VO eb58/eda、动态文档、批量分块/混合槽/恢复/关闭按原身份。未新开性能采样。

**唯一 SDK。** `backport-20261104/sdk-official-20261104d`：646 载荷+manifest=647 文件，content `6208a685…`，载荷24,797,679B（含manifest共25,076,461B）；622 输入闭包锁 `b10e0eec…`，mode closure；`FINAL_SDK_LOCK_PASS` 0 drift/0 extra。公开 creator 从该 SDK 在含空格目录建 mixed-form 并 `--build-only` 成功，EXE `e8256d2d…`、renderer `fa406666…`，provenance 451 个 SDK 源条目与最终导出逐字节相同、0 不符。`d-write` 退役；默认配置不变，O2 仍为应用显式选择。

**边界与空间。** 完整 IME 矩阵、迟到交错、跨平台输入未验；32ms 未通过，旧 ON 数据不是本包收益，raw presentedTime=0 仍 unknown；未改系统输入源/锁屏/可访问性，无顾问、无 Git 写。新增保留 `work/macos-input-sdk-20261104` 370,312KiB + SDK 25,900KiB ≈387MiB（<512MiB），同时峰值约440MiB（<768MiB）；宿主余 152,002,568KiB（约144.96GiB）。

<a id="guidance-input-sdk-review-20261104"></a>
## 9. 指导复核与接续（2026-11-04）

**限域接受交付，保留一条新行为缺口。** 独立核回 d 的646载荷与622根输入、无额外文件、锁 `b10e0eec…` / closure `6d84ecbd…`；相对 c 仅 native 一项生产编译输入变化，另为说明和导出锁。生产 diff 是9行 Return 分支，不改变共同 owner/版本/选择/CAS。测试扩展直接调用代理并观察消费结果和 proxy 正文；没有真实 NSWindow/firstResponder/Return→下一字符链，因此其 RED 不是“真实失焦丢键”的运行反例，其 GREEN 也不是该问题的正常应用验收。当前根 README 与 MACOS_CANDIDATE 已校准此边界；冻结 d 不改、不为此另导包，说明变更随下一实际交付携带。

**正常消费与身份已核。** mixed 签名 EXE、renderer、manager 日志 SHA 一致，PID65257 默认诊断关闭、实际 exit0、端点消失；旧 draft 拒绝前后完整读回 JSON 相同。独立解码814B保存件（SHA `d1df773b…`）的361B payload，cardA正文/版本与Apply原件相符，cardB各字段保留。包外 creator 构建的451项 SDK 来源全匹配；其24项应用/434项框架 prepared 索引与自身原件匹配。根 mixed 为23/450索引，按各自构建身份分记，不冒充同一 App。两套 pre-sign、签名 EXE 分开核验，不要求签名前后哈希相等。没有重跑测试、构建、桌面或旧正常链。

**编译口径校准。** 两套 provenance 的 Cangjie `compiler_configuration` 均为空配置，生成清单未含显式 O2，`.cjpm-history` 的 `compile-option` 为空；只确认 native fingerprint 的 `clang_flags=-O2`。不据此接受“三包实际 O2”，也不凭空补 Cangjie 实际优化级。功能结果保留，后续性能使用参数明确的当前基线，不能与 R2f 或旧 ON 比较混算；不为这一文字校准重编。

**按用户决定回到性能主线。** 当前输入/SDK整包停止扩展，保留已交付源、SDK和适用绿证。将唯一新行为缺口并入下一正常输入准备：同一已确认可写的目标，先有真实字符正控，再连续 Return→下一字符，中间无补焦、重新点选或等待读回；事后核完整正文/版本/选择和原焦点责任。若 Return 前字符也无法进入，应先区分投递通道/焦点/产品路径，不能把空结果归因于 Return 或直接写成工具限制；无可用真实通道时明确未验，只停依赖该输入证据的判断，独立性能分析继续。公共整数分支按实际受影响范围处理，不扩输入法/VO/旧矩阵。

下一性能工作围绕当前最终源的输入→提交关键路径与实际改善开展，先复用已有原始归因和被排除方案；不重复 display-link/depth 参数扫描、批量正确性回归或无新问题的日志采集。32ms仍未达标，真实非零present与raw0分别统计，旧原件按原版本，不以本次功能包关闭性能目标。性能具体架构方案须依据当前责任路径取舍，不先假定必须单主线程或存在不可消除的23ms固定时延。整包末集中报告实际改善、正常消费和剩余项。
