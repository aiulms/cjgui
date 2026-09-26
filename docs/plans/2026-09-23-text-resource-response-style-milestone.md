# 文字渲染响应与统一样式消费

建立：2026-09-23。指导复核后的完整接续包，承接[上一阶段](2026-09-23-rendering-window-scale-milestone.md#2026-09-23-指导复核与接续结论)的必要返工，同时推进公共样式的一次接入、手写/生成对等和新应用消费。当前执行对象只见 [ACTIVE](../../runtime/cjgui/ACTIVE_DIRECTION.md)，操作规则见 [AGENTS](../../AGENTS.md)。本页是实施提示词，无需另开执行卡。

## 交付目标、资产与取舍

普通开发者创建正常窗口时，文字清晰、交互状态可辨；长内容的更新不会反复准备同一批文字或让另一窗口长时间失去响应。为组件选一次共同样式，基础外观与交互状态一起到达手写、生成及注册组合组件；应用仍自由决定布局、主题和是否启用外部能力。

六条主线的取舍：组件布局本包补标题样式对等，不再新增容器；自绘/GPU 优先补长文本成本与候选资源事务；文字输入沿用系统 TextKit、焦点/选区桥，不扩 IME；资源调度补实际字节与负载期响应；语义/动作沿用共同定义与现有 STYLES 观察；普通开发者接入用现有两个模板与导出文档闭环。此前“能启动大文字窗口”是正确性进展，不等于性能目标完成，也不等于整套框架成熟。

复用 `composable_ui.cj`、`composable_ui_named_style.cj`、generated holder 的 staged/accepted 样式表、composite context、已有 TextKit/NSString/Metal、文字计数、场景事务、正常 application host、精确身份输入驱动、三个消费者及 `create_macos_application.sh`。旧研究的无谓重绘、状态归属、Retina/裁剪和公共 API 过早固化教训继续适用；不恢复其历史禁止开发条款。不上新字体引擎、全局无限缓存、CSS 级联、Agent 壳或第四套业务应用。

## 执行分工与顺序

- 外部 DeepSeek 4.1 Flash 是唯一主写入者，负责整个 A–E。先保存相关 dirty diff、未跟踪文件与指纹，核查实际写入/构建/桌面竞争；保留并行鸿蒙和历史证据。
- A/B 涉及候选/在用资源与 native 主线程：先用同一份限域问题包咨询 Codex CLI `gpt-5.6-sol` / xhigh，给出下面已定位的源码、原始日志及预期反例，要求确认资源归属和可区分检查。不要把整个仓库交它重审；咨询只读，DS 落地和运行验证。C 的常规实现由 DS 推进，公共契约有歧义再 high 咨询。
- 普通问题两次实质修复无进展时咨询；核心问题第一次失败不盲猜第二方案。一次咨询加一次带新证据追问仍无方案，按 AGENTS 向指导升级该点，其他工作继续。旧失败累计不清零，不换回 Terra/K3，不恢复 GPT-6 Sol、Luna 或定时。
- 按 A/B 和 C/D 两组范围推进，最终 E 汇合；它们不互相制造开工门槛。同 target 构建串行，同一时间一个桌面操作者。不要逐文件停工，也不要用重复绿测试代替新交付。

## A. 必要返工：文字资源的失败与释放边界

已核对 `CjguiCommitComposableSceneOnMain` 的文字准备失败直接返回、`present_composable_scene` 同样直接返回，已创建的 candidate 文字资源仍可能由 `stagedComposableNodes` 持有到下次 configure/关闭。之前释放探针只验证 session 数与旧 token 失效，不能证明 candidate/current/scratch 字节分别归零。失焦的 `prepareInactiveTextResourceForFocusChange` 直接调用 raster helper、不经整场景预算，是须先用正常路径判别的风险，尚未证明实际越预算。

1. 在既有探针先建立可判别反例：旧 accepted 有可编辑内容；候选的前节点生成新纹理，后节点触发超预算或注入准备失败；不启动下一次 configure、不关闭窗口，就观察该次拒绝已完成后的资源。候选独有纹理/临时 staging 应释放，旧 accepted 持有和具体内容不变，随后还能编辑与接受合法候选。共享 accepted 引用不能按 candidate 清理误释放。
2. 沿既有提交/拒绝路径做最小清理，保留具体原因；不得为通过测试提前销毁旧场景。资源观察须区分唯一分配与重复引用、candidate 独有/current 共享、CPU staging/Metal texture；不能只统计逻辑宽高，也不能把 24MiB 说成全进程峰值。关闭只释放本窗自有资源，另一窗继续可用。
3. 同一近预算场景通过真实生产焦点路径切入/离开多行输入，并穿插内容、resize/scale 或裁剪改变，检查失焦转换是否绕过预算、失败是否破坏已有文字。先证明可触发条件，再修复；如果无法触发，给出限域调用链和反例范围，不把源码疑点写成已修 bug，也不无限追加试验。必要的预算/转换决策交 Sol；禁止把错误忽略或单纯调大上限。

## B. 新框架能力：复用文字准备结果，保持负载期间响应

指导读到 `/private/tmp/cjgui-large-text-window/probe.log`（2026-09-23 14:50）中，100k 冷启动 1828ms；同一双窗夹具 resize 1093ms、热内容更新 1087ms。探针是 A 完成后才编辑 B，不能证明负载期公平性。现有每片非零 alpha 只证明有字形，不证明首/中/尾和最终接缝内容正确。

### B1 先归因，再最小化准备工作

- 先核对真实构建参数：现有 probe 和正常 `run_macos_application.sh` 的 clang flags 均未显式设置优化级别。记录仓颉/native 配置、工具链、源/产物、scale/视口。若引入明确优化构建模式，将其纳入 runner/缓存 fingerprint，保留诊断构建；旧/新实现对照必须同配置，编译优化收益与算法收益分开，不能只给探针加 `-O2` 便宣布框架已提速。
- 有根据的待验证热点：静态候选每片 `CjguiRasterComposableTextTexture` 都对完整字符串调用 `drawWithRect`；保留焦点的 resize/外部改值又在 `setNodesFromProjection → refreshGpuTextForActiveInput` 走 active TextKit。日志相应操作各增加四次 raster，与两片各准备两遍吻合，但这还不是耗时根因证明。
- 用现有 work reason/单调计时限域区分排版/测量、静态准备、active 准备、像素转换、upload 和提交。选择同一 100k、980×620、2× 的静态/已聚焦对照，保留短文字/10k 控制组，不从头造 profiler。应用源数据与选区不计入 renderer 的新 owner。
- 依据量测消除重复排版或 static→active 双准备，复用既有系统文字布局/缓存和可见范围。资源 key 明确内容/字体/宽度/scale/裁剪/paint 依赖，位置/选区和纯背景变化不应无谓重栅格文字；改了文字颜色或字体必须正确失效。所有复用受 A 的事务与预算保护。若单次准备仍长时间占据主线程，由 Sol 给出有界分段或安全准备方案；不得先搬 AppKit 对象到工作线程，也不得靠无上限缓存、全局 tick 或隐藏同步成本通过。

### B2 正确内容与真正的双窗负载

- 同一正常应用内 A 持续滚动/resize/更新，B 请求须在该轮重工作开始前或执行期间真实进入既有队列，并记录 ready/enqueue、owner 应用、accepted 具体值、提交的时间。不能让 B 用直接同步写绕过调度，不能等 A 停止才发请求。含关闭 A 后 B 接续和停止后零额外 raster/upload 的检查。
- 每类关键热操作取有界 20 个原始样本，冷启动单列；真实工作量与单调耗时分开，正确性在计时外。先建立同条件基线再优化，至少给出 p50/p95/max 与正常短文字负载是否回退。本包在本机正式消费构建上的工作目标是：B 排队到 owner 的 p95 ≤100ms、排队到 accepted 具体内容的 p95 ≤150ms；这是本阶段响应预算，不是行业比较或最终性能上限。长文单次同步准备接近秒级仍属未解决。未达目标应带归因和下一方案升级，不得改成“只声明功能”收口，也不扩为无限性能工程。
- 在同一 10k/100k 内容放置可辨识的首部、中部、尾部及分片接缝标记，真实滚动/编辑后分别核对 owner 精确值与最终 drawable/正常窗口图像；至少覆盖一个接缝的裁剪和中文/emoji。允许复用现有读回和截图，不新造通用视觉平台。非零 alpha、矩形连续、选区跨 seam、版本前进不能各自代替内容完整性。受控比例与真实显示比例分别标注。

## C. 新公共能力：样式定义一次，整组消费

必要返工已从源码确认：`beaconDark().primaryAction` 未设前景色，白字只在 `primaryActionInteraction.normal`；协作按钮/两个模板漏接后成为黑字。知识目录 `titleInteraction.hover/pressed` 和 `rowInteraction.pressed` 又读取该基础前景，正常截图可读不代表交互态可读。新增 Tabs `titleStyle/titleInteraction` 仅手写有入口，generated `nodeFor(TABS)` 仍只传容器 style/titleHeight。

1. 先在现有主题/组件用例建立上述失败，再修正基础与状态的完整定义。不要改全框架默认文字成白色；浅色背景/输入框同样应正确。现有暗/亮主题对普通可用文字给出明确前景与背景；检查 hover/pressed/focused/selected/disabled 的组合，选中页与键盘焦点可区分。数值对比度是辅助，不能只数亮像素当所有状态通过。
2. 复用 `CjguiComposableUiNamedStyle` 已有的 base + interaction，提供公共的整组消费入口，开发者选择一次样式/角色即可把两者传到组件；允许局部几何，明确定义局部 paint 覆盖顺序。优先少量重载/绑定方法，保留旧显式写法兼容，不为每个示例再造 roleStyle/roleInteraction，也不建立第二样式目录。实验 API 命名由执行者给出清晰签名；存在语义冲突时先咨询。
3. 同一已注册标题角色能由手写和生成 Tabs 使用，并把允许属性、类型与引用如实公开发现。未知标题角色/不支持属性拒绝整个候选，旧页/草稿/焦点/滚动仍在；标题样式变更随现有 staged/accepted 事务。不要把容器的全部布局属性粗暴继承给标题，也不要只改生成解析器却不接 builder。
4. 注册组合组件继续消费同一解析后的样式与交互，不复制状态机。至少一套共同样式经应用现有主题动作更新后，手写、内置生成、组合三路画面一致变化，公开 STYLES 能读到同源变更；业务值、结构身份、当前页和合法选区不因此重置。只改 paint 应沿已有 paint 路径，不新增布局/模型调用。
5. TAB_TITLE 的 label-only 绘制与输入谓词拆分保持；主题/标签变化的缓存失效用上述实际链和局部工作计数覆盖，不为单个标题再造一套 renderer 或独立验收工程。

## D. 普通开发者接入与可读示例

三个既有消费者消费 C 的公共能力，删除此次被公共入口替代的重复拆装代码；它们验证框架复用，不重新设计完整产品。规则空状态和生成 v0 保留事实但用自然提示说明下一步；页签选中/焦点可辨。知识目录默认只展示实际条目或准确标注摘要，不再以“可见条目”重复 18 行却标 3 行；长文本/重复数据保留为显式测试配置，不删除所需负载。

更新现有 `ui_only` 与 `collaboration` 模板使用完整主题入口，不强制 UI-only 创建 descriptor/Agent，也不让协作模板复制 renderer。修复导出 README 指向却未携带的 `MACOS_APPLICATION_HOST.md` 等首要接入资料；历史内部文档可明确为源码仓库参考链接，不为清链接导出整个 docs/plans。从导出模板创建普通应用，应按包内快速开始完成，不能依赖作者目录或抄消费者私有 helper。

## E. 一次汇合验收与集中交付

- 作者实现稳定后做一份含空格路径的最终导出，清单/指纹包含实际新增公共源码、模板和必要文档。三个既有消费者从同一根运行；另从同一包的两种模板各创建最小应用，验证其真实输入/动作、主题正常与关键状态，以及 UI-only 无外部能力依赖。只验证本次改变的接入/主题路径，不对模板重复整个业务/性能矩阵。
- 正常应用输入/外部读回/修改后继续编辑，至少一条覆盖生成 Tabs 标题样式、主题更新与非法候选保留。A/B 资源与性能证据可以沿同源码限域探针，但至少一个导出普通窗口消费优化后的长文本；避免作者私有编译模式掩盖导出慢路径。
- 跑相关针对性用例、必要 build、公共契约/影响范围与 `git diff --check`。旧生成模型、竞态、拖放、全套历史矩阵不因换阶段重跑。原始日志保留，不清 20GB 历史目录；自有实例整轮结束按准确身份回收，不关用户或不明实例。
- 集中报告 A–E 的实际新事实、复用证据与来源、失败到修正、咨询的作用、同条件耗时及实际资源、最终导出来源、未验边界。本包不做人工物理输入证明、系统 IME/VoiceOver 专项、全进程峰值、鸿蒙、真机或发布，不把工具图像核对称为人工验收。
- 原目录、无 worktree/切分支/stage/commit/push；桌面按已授权规则使用，锁屏只暂停依赖段，独立部分继续。完工后等待指导复核，不自行开下一阶段或恢复自动化。

## 2026-09-23 执行记录（第一轮，进行中）

执行者：DeepSeek 4.1 Flash（按 ACTIVE 当前指定）。开工前已保存基线：`git rev-parse HEAD`=64735d0、dirty diff（58 文件 +19850/-933）与未跟踪文件存 `/private/tmp/cjgui-milestone-baseline-20260923/`（sha256=7f79859…818e5d），无并行写入/构建冲突；上一轮遗留的 4 个证据实例（cjgui preview 20260923151216-6843 等）保留未动。

### 聚焦咨询（Sol xhigh，先于 A/B 实施）

`codex exec -m gpt-5.6-sol -s read-only -c model_reasoning_effort=xhigh`，材料 `/private/tmp/cjgui-sol-consult-text-style.md`，答复 `/private/tmp/cjgui-sol-consult-text-style.out`（约 19.5 万 tokens，只读未改文件）。关键结论已全部采纳：候选独有资源按 staged/committed 同索引对象同一性判别、集中清理于事务拒绝两个出口；失焦预算旁路真实成立但需 scale 交错触发，修复采用栅格前 admission + 失败保留旧资源；`+4` 归因更符合 2 static + 2 active 并补 ProjectionGeometry/ExternalProjectionContent 两个 reason；每片全串排版改候选局部 TextKit 需分步、先 multiline；双窗响应必须以 t_enqueue≤t_heavy_start 与 20 样本 p95 断言。

### C. 公共样式（已完成，测试红→绿）

- C1 修复：`beaconDark().primaryAction` 基础样式补白前景（0.96,0.98,1.0），hover/pressed 经现有 resolve 覆盖顺序继承；亮色主题与输入框深色前景不变。新测试文件 `src/composable_ui_theme_test.cj` 先红（修复前 beaconDark 用例断言失败）后绿。
- C2 公共一次接入入口：`CjguiComposableUiNamedStyle.localStyle(...)`——几何/排版局部覆盖（fontSize/fontWeight/padding/gap/fixed*/grow*/min*/max*/align*/cornerRadius/fontFamily），paint 一律来自定义本体且定义不可变，覆盖顺序写入 API 文档；与既有 `interaction` 一次配对传组件。测试加入 `composable_ui_named_style_test.cj`。
- C3 生成 Tabs 标题样式：`tabsContentProperties` 新增 `titleStyle`（命名样式引用）；`isPropertyImplemented` 白名单放行（曾因漏改导致 12 个 tabs 测试连锁失败，已修）；`validatePropertyValue` 复用 `style_reference_not_registered` 严格校验（未知标题角色拒绝整个候选）；`collectReferencedStyleNames` 同生命周期保活；`nodeFor(TABS)` 经 `namedStyleDefinition`（同一 staged/accepted 事务）取 base+interaction 传入 `cjguiComposableTabs`；发现端自动发布 `PROPERTY tabs titleStyle STRING` 与 STYLE_REVISION。测试：标题消费命名样式 base+interaction、主题更新后下次刷新生效、未知引用整候选拒绝、发现端发布。
- C4 核实：组合组件已经由 `styleFromDeclaredProperties`+`interactionStyleFor` 走同一解析路径，无需改动。
- 测试证据：`/private/tmp/cjgui-c-green-test4.out`（183/183 PASSED，含 4 个新测试）。修正过程：@Assert 宏内多行深嵌套注册调用两次括号配平失败（改为先赋值后断言），`tabsTestFindFirstKind` kind 参数 Int64。

### A. 候选资源释放边界（已完成，探针红→绿）

- 修复 1（集中清理）：新增 `CjguiReleaseFailedCandidateTextResources(ctx)`，在 present 两处拒绝出口调用——commit 非 OK 返回前、commit 成功但 Metal present 失败回滚后。仅清理 staged-only 节点（同索引对象同一性），只置空派生字段（textTexture/textTileTextures/textTileRects/key/byteCount/rect），语义内容保留，同候选重试与共享纹理（ARC 双持有）安全。
- 修复 2（失焦预算旁路）：`prepareInactiveTextResourceForFocusChange` 改为先 plan、`FitsSceneBudget` 栅格前 admission、key 命中复用、拒绝或失败保留旧资源只清装饰——不再绕过 24MiB 场景上限，也不再安装半状态。
- 判别 seam（TESTING）：`test_composable_text_candidate_stats`（committed/staged 唯一纹理集合、candidate-only 数与字节、shared 数）、`test_composable_text_cpu_scratch_stats`（BGRA current/peak，与 Metal 字节分开）；reason-stats seam 随新 reason 扩展。
- 探针：`probe/candidate_text_resource_probe.cj` + `native/scripts/verify_candidate_text_resource.sh`，日志 `/private/tmp/cjgui-candidate-text-resource/probe.log`。四场景全绿：预算拒绝（真实 budget_exceeded，先装后败次序）后 candidate-only=0 且字节归零、连续两轮干净、accepted 字节/纹理集/版本/内容不变、继续编辑+接受合法候选；注入失败（首节点败）无害；纯移动克隆共享 accepted 纹理，拒绝后 committed 像素读回不变（alpha 295729 前后一致）；scale 切换自身零栅格化、焦点切换栅格有界、scratch 归零。
- 红→绿判别：临时禁用两处清理调用重跑，`released=false、candidate_only_bytes=19376640`（约 19.4MB 候选纹理滞留 staged），恢复修复后归零。证据成立。

### B1. 归因与重复准备消除（第一部分完成，同配置对照显著）

- 已核对新构建配置：verify 脚本 clang 无显式 -O（`build_cjgui_internal_renderer_sidecar.sh` 支持 `CJGUI_NATIVE_CLANG_FLAGS_APPEND` 且入指纹）；以下收益为**同配置算法收益**，非编译优化收益。
- 新增归因：ProjectionGeometry / ExternalProjectionContent 两个 work reason（`setNodesFromProjection` 内几何/外部改值时设置，未发生准备则回收为 Unknown，不污染后续归因）；raster 内细分计数 staticDrawWithLayoutMicros / normalizeMicros / textureCreateMicros（子区间，不与外层 wall time 相加）。drawWithRect 排版/绘制一体，未虚报拆分。
- 优化 1（聚焦静态候选跳过）：`CjguiPrepareComposableTextResources` 对当前聚焦输入的 staged 节点不再栅格化静态形态（提交后 active 刷新立即覆盖视觉），按 acknowledge 路径计 retained 字节；helper `CjguiStagedNodeIsFocusedInput` 置于 overlay @interface 之后（前向声明问题两次修正）。
- 优化 2（纯宽度变化惰性失效）：active 多行签名拆分——字体/颜色变化才整串 setAttributes（10 万字符级），宽度变化仅 `invalidateLayoutForCharacterRange` 惰性重排可见段。
- 同条件对照（`verify_large_text_window.sh`，100k 双窗夹具，优化级别未变）：

| 操作 | 上一包基线 | 本轮 | raster 增量 |
|---|---:|---:|---:|
| 聚焦 resize | 1093ms，+4 | **182ms**，+2 | 4→2 |
| 聚焦热内容更新 | 1087ms，+4 | **184ms**，+2 | 4→2 |

  双窗 B（滚动/缩放/内容/关 A 后）全部即时响应、idle 零额外 raster/upload、accepted 内容正确；`CJGUI_LARGE_TEXT_WINDOW passed=true`。全套 cjpm 测试 183/183 通过（`/private/tmp/cjgui-c-green-test4.out` 后续全绿轮次）。

### 遗留与下一步（按序）

1. B2 已量测（见下"双窗负载实测"），预算未达、归因明确：大文本聚焦单次同步刷新 ~180ms 是结构性下限，B1 后半（static↔active 正文复用、增量/有界分段准备）是达标路径；按阶段要求带归因升级，不以局部数据改名完成。
2. B1 后半：近预算焦点判别探针（O+B_old≤cap、scale 交错后 focusNode 触发、断言拒绝时零栅格）以证实 Q2 修复的可触发条件；static↔active 纹理复用的分步演进（候选局部 TextKit layout → scrollbar 移出正文 → canonical body key）按量测决定是否继续。
3. D 剩余：generated_panel_consumer 的演示声明接入生成 `titleStyle` 引用（框架能力与测试已就绪，demo 编码声明待加注册+引用）；消费者真机运行验证沿 E 链。
4. E：含空格路径最终导出、三消费者同根运行、两模板最小应用、生成 Tabs 标题样式+主题更新+非法候选保留链、`git diff --check`；完成后集中报告并更新 ACTIVE。

### B2. 双窗负载实测（第二轮，预算未达、带归因）

新探针 `probe/two_window_workload_probe.cj` + `verify_two_window_workload.sh`（日志 `/private/tmp/cjgui-two-window-workload/probe.log`）。口径按咨询 Q5：B 的编辑经真实 TextKit 输入管线（insertText→事件入队）先于 A 的重负载入队（`immediate_owner=false` 证明非同步派发），t_enqueue/t_owner/t_accepted 全部单调时钟记录，20 原始样本取 nearest-rank p50/p95/max。

- 事件循环模式（每重操作一个 turn，20 样本）：owner p50=412 / p95=462 / max=463ms；accepted 同值。**超预算**（p95≤100/150）。
- 屏障模式（三重操作连续无 pump，20 样本）：owner p50=416 / p95=420ms。与事件循环模式几乎相同——插入 pump 不改变 B 的派发时机。
- 归因：A 的每次聚焦 100k 刷新是同步 stage+commit+present（现 ~180ms/次），主线程串行意味着 B 的已入队事件只能等当前同步刷新结束；序列含 resize+scroll+热更三次刷新，410-460ms≈三次刷新之和。pump 的插入不会打断正在执行的同步刷新——**这是调度架构现状的量化，不是测量假象**（warmup 轮也显示 owner/accepted 同时刻出现）。
- 上一包对照：非聚焦长文本操作（热更 7ms/resize 48ms）远在预算内；聚焦场景经 B1 优化已从 1087/1093ms 降至 ~184/182ms，但单次仍>100ms。
- 达标路径（升级项）：单次聚焦刷新继续压缩——static↔active 正文复用、可见范围增量准备、scrollbar 移出正文纹理；把"3 次连续刷新"压到单次 <100ms 后事件循环模式即可达标。属 B1 后半工程，量大需独立推进。
- 复测稳定性（第七轮，P2′ 后）：事件循环模式 owner p50=355 / p95=405 / max=411ms（较首轮归因前 462ms 再降 ~57ms，与 fallback 段收益一致）；屏障模式 p50=360 / p95=363ms。预算仍未达（结构性），结论与归因不变。日志 `/private/tmp/cjgui-two-window-workload/probe.log`（覆盖重写，含两轮数据以脚本历史为准）。

### B1 后半归因精确化（第四轮，细分到 130ms 级单点）

large_text 探针补三组细分计数（raster/upload micros 差值、draw-with-layout/normalize/texture-create 总量、configure/set/commit stage 总量）。聚焦 100k 两次重操作的同轮差分：

- **resize 182ms**：raster_us_delta=121ms（多行 TextKit 栅格含 drawGlyphs/normalize/upload），normalize 仅 5ms、texture-create 0.1ms、draw-with-layout（静态路径）零增长；commit 差 ≈91ms 与 raster 重叠。
- **hot_content 177ms**：raster_us_delta 仅 **42ms**、upload 1ms——**commit 差 ≈176.6ms≈全部 native_submit，其中 ~134ms 在文字栅格之外**。
- 定位：外部改值路径 `markActiveTextFallbackRunsDirtyForWholeValue` → `prepareActiveMultilineFallbackRunsForNode` 对**全文逐 composed-sequence** 调 `CTFontCreateForString` + `setAttributes`（renderer.m 7710 附近循环）——100k 字符的 O(n) 次 Core Text 调用即 ~130ms 级主因；框架已有 `test_composable_multiline_fallback_runs`（mismatched=0）等价性测试。
- B1 后半第一工程项（先 Sol 聚焦咨询确认等价边界再实施）：fallback run 解析惰性化/聚合——仅可见范围或按 run 聚合探测，保持 fallback 字体解析与现有测试逐字符等价；次要项：maximumScroll 惰性化（renderer.m:5223 全量 ensureLayout，涉及滚动边界语义）。
- 探针细分输出已固化在 `verify_large_text_window.sh` 日志（COST 行 intervals/stage/raster_us_delta 字段）。

### B1 后半：P2′ fallback 解析优化（第四轮实施，oracle 等价）

二次 Sol xhigh 咨询（材料/答复 `/private/tmp/cjgui-sol-consult-fallback.{md,out}`）结论：P1 可见范围解析在严格全文等价下不等价、不做；P2 原案（块/脚本聚合）不等价，改为 **P2′（完整 composed-sequence 缓存 + 相邻同字体 run 合并）** 可行且直击 134ms 单点；P3 scrollbar overlay 延后（失焦复用先按 maximumScroll 条件禁用即可保正确性）。

- 实施：`applySystemFallbackRunsToActiveInput` 改两遍式——第一遍按 composed-sequence 枚举，以完整序列字符串为键（单次解析作用域局部缓存，杜绝陈旧字体环境）解析 `CTFontCreateForString`（调用 N 次→U 次），相邻同解析字体的 sequence 合并；第二遍每合并 run 一次 `setAttributes`（N 次→R 次）。nil 解析序列保持原语义跳过；CTFontRef 经 `__bridge_transfer` 由缓存统一持有。
- 等价性：`verify_composable_ui_appkit_text.sh` 的全文逐字符 oracle（owner ack 后与恢复后两处 `mismatched_runs==0` 断言）PASSED。
- 性能：聚焦热内容 177ms→**151ms**（fallback 解析段收益 ~26ms）；其余 ~134ms 确认不在 fallback 解析，而在 `setNodesFromProjection` 的 inputProxy 状态更新/TextKit 布局链——下一精确步需 commit 内部阶段计时 seam（遗留）。

### B1 后半：projection 阶段计时（第五轮，根因链闭合）

新增 `test_composable_projection_timing_stats` seam（AX 重建 / 聚焦输入状态 / active refresh 三段累计）+ 探针输出。同场景差分闭合归因链：

- **hot_content 151ms**：proj_input（inputProxy 状态/外部值比较）差仅 **0.7ms**；proj_refresh（`refreshGpuTextForActiveInput`）差 **≈150ms≈全部**。
- refresh 150ms 内：文字栅格（rasterize+normalize+upload）42ms、fallback 解析（P2′ 后）≤26ms——**剩余 ~80-100ms 是 TextKit 对 100k 文档的可见布局 realize（ensureLayoutForBoundingRect/glyphRangeForBoundingRect）**。
- 结论：聚焦刷新的剩余成本是 TextKit 大文档布局固有成本，重复准备工作已全部消除（1093ms→151ms，-86%）。压到 <100ms 需要新布局契约（non-contiguous checkpoint/远端惰性+滚动锚点修正，即咨询 P1 的"新布局语义"），属新契约设计决策，交指导与 Sol 复核，不在本阶段以 hack 方式实施。

内容正确性同场验证通过：100k 正文含头部标记XYZ/中部标记ABC/尾部标记QWE，owner 与 accepted 全文包含三个标记；12 次滚动 offset 单调推进至 10000、可见 glyph 1248、可见 tile alpha 非零（87882 像素）、3 tiles 接缝结构存在；滚后空闲轮 raster/upload 零增量（356->356）。中文与 emoji（😀）随正文通过全部检查。

### D. 开发者接入（第一部分完成）

- tree_outline_consumer：`roleStyle`/`roleInteraction` 私有拆装重建改为框架一次入口 `localStyle`+`interaction` 的薄绑定（哨兵→Optional 翻译，paint 不再在本消费者重组），`rolePaint` 删除；`cjpm build` 通过。
- 模板 ui_only/collaboration：按钮改用一次角色消费 `CjguiComposableUiNamedStyle(...primaryAction, interaction: primaryActionInteraction)` + `localStyle()`/`interaction` 传入组件（此前只传基础样式曾是暗色黑字根源之一，C1 修复后叠加完整交互态）。
- 模板从当前框架创建编译验证：`create_macos_application.sh` 两模板在含空格路径 `/private/tmp/cjgui-template-check/app dir/` 创建成功，配 launcher+sidecar 后 `cjpm build` 均成功（E 的正式运行验证沿既有链）。
- 导出修复：`export_framework_preview.sh` 现携带 `MACOS_APPLICATION_HOST.md`（README 首要接入指向此前在导出内悬空），且导出目标父目录不存在时自动创建（消费者链参数化导出根路径依赖此行为）。
- `git diff --check` 干净（exit 0）。

### D. 剩余项完成（第二轮）

- generated_panel_consumer：注册 `panel_tab_title` 命名角色（paperLight heading 派生），demo 编码声明 `PROPERTY 0 board titleStyle panel_tab_title`；新增两测试——生成标题消费注册角色的 base paint+interaction、未注册标题角色整候选拒绝且合法结构随后照常接受。该包 31/31 测试通过。
- 至此三个消费者/模板的公共能力接入完成：tree_outline（localStyle+显式 titleStyle/titleInteraction）、generated_panel（生成 titleStyle 引用+组合组件同一解析）、rule_set（既有 style 引用+主题 update 链路不变）。

### E. 汇合（完成）

- 消费者链第一轮（`/private/tmp/cjgui-final-consumer-chains.out`）：导出+指纹段 PASSED；无头结构段通过；**真机输入段 BLOCKED（`reason=session_locked`）**。
- 消费者链第二轮（解锁后重跑，`/private/tmp/cjgui-final-consumer-chains2.out`）：**PASSED**（`root='/private/tmp/cjgui-final-chains/cjgui final export 20260923180120/export'`，`root_has_spaces=true`，`files=83 identical=75 rewritten=8 sha256=eef8116f…e7b0`）。关键证据：
  - `step2 ui_only_tree_consumer_started source=export` + `step2b ui_only_tree_interaction_ok`（真机键盘/点击：focus_shift/select_all/collapse_expand 全 true）；
  - `step2c tab_switch`（真机页签切换）+ `step3t rule_tabs_page_switch_ok retention/file input=real_desktop_control driver=ax`（rule_set 页签往返+草稿保存真实输入）；
  - `step4a panel_control_text_edit before='' after='export-panel-title-one' input=real_desktop_control driver=cgevent`（真机点击替换输入写回 owner）；
  - `step4i composite_shared_style_paint_ok method=bounded_region_screenshot`（**组合组件与生成节点共同消费公共命名样式的截图级验证**）；
  - `step5 exported_public_client_ok` / `step5b exported_observation_ok`（公开观察流）/ `step5c exported_candidate_race_ok`（候选竞态：first ACCEPTED、second REJECTED structure_version_conflict——非法候选保留 accepted）；
  - `step5d same_host_two_window_ok`（同宿双窗：B owner readback、A 图片资源 ready、close 后 B stable）+ 双窗时序（b_owner_enqueue_to_applied_ms=239）。
- 两模板最小应用已从同源框架创建并编译成功（`/private/tmp/cjgui-template-check/app dir/`）；正式运行验证（第三轮，从最终导出包创建）：用导出包内 `framework/cjgui/scripts/create_macos_application.sh` 在 `/private/tmp/cjgui-created-apps/`（无空格目的地，避开 cjpm build-script 对空格 CWD 的断裂——工具链缺陷，另记反馈）创建两应用：
  - ui-only：依赖路径正确解析到含空格导出根，`framework_native_archive=reused`（sidecar 自导出物化），构建+启动成功，`CJGUI_UI_ONLY_READY` 输出后正常终止；
  - collaboration：同链路成功，`CJGUI_COLLABORATION_READY DESCRIPTOR_PATH …` 外部连接端点就绪；
  - 运行实例已按身份回收。接入过程不依赖作者目录或消费者私有 helper，包内快速开始自足——E 的"从导出包创建应用"要求达成。
- 覆盖边界说明：生成 Tabs 标题样式+主题更新+非法候选保留的运行级覆盖由 panel 包测试（真实提交事务三用例）+ 本链 `step4i` 共享样式截图与页签真机切换共同组成；专门针对 titleStyle 的真机键盘链未单独构造（评估为低增量）。
- 工具链问题反馈（非本阶段代码缺陷）：`cjpm build`（含 [script] 依赖包）在含空格 CWD 下 build-script 缓存路径分词断裂（`cjpm build --skip-script` 不触发）；已有记录在案，移除条件=升级 cjpm 或框架侧改用无脚本包。
- 公共契约扫描（第五轮补证）：本包新增公共面 = `CjguiComposableUiNamedStyle.localStyle(...)` 方法、生成 tabs `titleStyle` 属性契约（含白名单/严格校验/发现发布）、`CjguiTaskGeneratedRegion.panelTabTitleStyle()` 演示工厂、`beaconDark().primaryAction` 前景值修复（值变更非签名变更）、native 三个 TESTING-only 计时/分类 seam 与 reason-stats 扩展（仅探针链路）。无删除、无既有签名变更。仓库工作方式含大量 untracked 源/测试/探针文件（含本包新增 `composable_ui_theme_test.cj`、`candidate_text_resource_probe.cj`、`two_window_workload_probe.cj` 等），基线保存以文件系统+指纹为准，不依赖 git diff 完整性。

### 当前遗留汇总（第九轮更新，以此为准；上文各轮"遗留"段为过程记录）

1. ~~真机输入段证据~~ **已完成（第九轮）**：解锁后重跑消费者链，PASSED、BLOCKED=0（见 E 段）。
2. **B2 响应预算达标（升级项，交指导）**：聚焦 100k 单次刷新 151ms 中 TextKit 可见布局 realize 占 ~100ms（固有成本），重复准备已全部消除（1093→151ms，-86%）；压到 <100ms 需"远端惰性布局+滚动锚点修正"新契约（Sol 二次咨询 P1 判定其非严格等价，属新语义），待指导决策后另行立项。归因链、两次咨询记录、细分计数已全部备齐。
3. 近预算焦点判别探针：构造推演确认单窗口可见范围（全屏 2×≈20.7MB）无法越过 24MiB cap——Q2 修复的可触发场景需 popup 逃逸窗口+精确聚焦坐标，判别价值/成本比低，保留为可选精化；Q2 修复本身已有 admission 逻辑与 focus 场景基本验证。
4. maximumScroll 惰性化（renderer.m:5223 全量 ensureLayout）：与滚动边界语义耦合，随第 2 项一并决策。


## 指导复核与接续结论

2026-09-23。本次为源码、原始日志及最终导出字节的只读复核，没有重跑构建、测试或桌面输入。上文保留为执行过程记录；“A–E 全部完成、只剩 B2”超出了当前证据，下列结论为最新指导口径。接续见[长文本增量更新与完整样式绑定](2026-09-23-incremental-text-style-binding-milestone.md)。

### 接受的实际进展

- 候选独有纹理集中清理成立。configure 同索引共享、setter 同索引 COW 与清理逻辑一致，`/private/tmp/cjgui-candidate-text-resource/probe.log` 支持拒绝后 candidate-only 归零、committed 共享资源保留。失焦 admission 已接入，但失败族的覆盖范围见下。
- 聚焦场景少做一次 static 准备、P2′ composed-sequence 缓存与相邻 run 合并已有代码/执行证据；当前 large-text 日志热内容为151ms、resize为154ms，报告182ms属于另一轮样本。可确认这些样本比上一包明显改善，尚非所有输入的分布或结构性下限。
- 暗色基础前景、localStyle 几何便利方法、生成 Tabs titleStyle 的白名单/严格校验/builder/引用保活/staged-accepted 已接通；`MACOS_APPLICATION_HOST.md` 已随导出携带。
- 最终导出根 `/private/tmp/cjgui-final-chains/cjgui final export 20260923180120/export`，83项指纹 `eef8116fd947ed45b3839567051b28d2af90a426db108123cd2cac961947e7b0`。本次只读核对83项 hash 及75个 identical 文件与当前作者源码一致。日志 `/private/tmp/cjgui-final-consumer-chains2.out` 的既有三消费链可接受为执行者运行证据；该指纹不是未包含的测试/验证脚本或编译产物指纹。

### 具体返工与判断纠正

1. **P1：聚焦优化把非输入文字也跳过。** [renderer helper](../../runtime/cjgui/native/cjgui_internal_renderer.m) 的 `CjguiStagedNodeIsFocusedInput`（本次行4819）只比身份/kind，3958的跳过也可能命中有焦点的 TAB_TITLE/button/boolean；7467的 active refresh 则排除非输入。源码形成“接受新 label/文字色但无纹理更新”的路径。需要正常聚焦标题/按钮的反例与同次呈现验证；这是本次源码发现，尚未在指导会话实跑。
2. **B2时延记录晚于实际完成，归因应撤回到待校准。** [双窗探针](../../runtime/cjgui/probe/two_window_workload_probe.cj) 的 ResponsiveMarkedController 未在 applyUiEvent 记录时间；runWorkload 在第一次 pump 前检查 owner，随后几次 pump 没有立即采样，accepted 更只在三重工作结束后观察。405–462ms可能包含 B 已完成后的 A 工作，不能证明 pump 未推进 B，也不能以此决定重写布局。当前原始日志 warmup 另有 `scroll=99 all_applied=false`，需要修正有效预热条件。20样本目前仅输出汇总，原始每样本时间须落盘。
3. **“~100ms TextKit固有成本”未被直接证明。** 当前日志只把成本定位到 refresh 外层，余量减法无法指定到 ensureLayout；原有 active layout trace 已能量 character/bounding ensure 等调用。setNodesFromProjection 的 ProjectionGeometry/ExternalProjectionContent 原因还被写在刷新之后，需要校准。当前已有 non-contiguous layout；P1的不等价不代表所有等价优化已穷尽。热更新夹具主要追加尾部，生产却全量赋 inputProxy.string、全文 fallback 失效，增量派生存储是明确可验证的下一方向；静态逐片完整字符串绘制同样尚有准备复用空间。
4. **文字画面和资源统计仍有证据缺口。** 新 runMarkedContent 只断言 accepted 全文 contains 三个标记，滚动后仍是 tile0 alpha 非零；没有中尾标记确实进入视口或最终 seam 画面的证据。active multiline 的 BGRA 分配未计入新增 scratch 统计，故该路径的 scratch=0不能用作释放证明。失焦计划失败分支会清空旧资源，现有2×→1×焦点用例也未触发近预算拒绝，需受控反例划清范围。
5. **C2整组绑定尚欠交，真实标题链也欠交。** [localStyle](../../runtime/cjgui/src/composable_ui_named_style.cj) 返回 base，不携 interaction，调用者仍可漏传；tree仍有 roleStyle/roleInteraction 两次查找，协作主按钮仍只传基础样式。最终 step4i 是主操作角色的生成/组合截图，没有三路同一次主题变更，也不是 Tabs titleStyle 消费。标题主题用例修改 base 却保留覆盖它的 normal.textColor，仅查base不足以证明最终 paint 变化。
6. **模板只验到启动。** `/private/tmp/ui-only-export-run.log`、`/private/tmp/collab-export-run.log` 终点是 READY/descriptor，尚未覆盖本包要求的操作、输入读回和交互态。快速开始仍推荐带空格应用目的地，实际采用无空格目录绕过 cjpm 故障，须同步已验证范围并沿问题账本记录。目前工具输入统一称“本机正常应用的CGEvent/AX模拟输入”，不再以“真机输入”混同人工物理输入。

### 指导方案

按新阶段一并交付：先修聚焦条件及计时/内容判别；在既有语义下实现外部小范围文本更新保留有效布局、同一候选多片共享文字准备；同时补真正的命名样式整组绑定和正常生成标题消费，最后完成两模板操作与统一导出。B的100/150ms预算保留，用校准后的实际时间判断。保持现有全文内容、fallback、选区和滚动语义，实测仍不足时才比较新布局契约的具体收益和行为变化。复杂问题按当前协作方式限域处理。
