# 正常尺寸窗口的有界文字渲染与完整键盘接续

建立：2026-09-23。此完整阶段包含上一包必要返工和新的通用渲染能力，最初由 Sol/Luna 实施；用户现已暂停原任务，改由 DeepSeek 4.1 Flash 接续、GPT-5.6 Sol 聚焦咨询，目标和验收不缩减。唯一执行状态见 [ACTIVE](../../runtime/cjgui/ACTIVE_DIRECTION.md)；操作规则见 [AGENTS](../../AGENTS.md)，接手提示见[外部执行交接](2026-09-19-external-executor-handoff-prompt.md)。旧生成式阶段的接受范围及原始证据见[最新复核](2026-09-19-runtime-generated-ui-milestone.md#2026-09-23-sol-luna-交付指导复核)。

## 目标与优先级

正常大小的桌面窗口中，短文字不因控件占地大而无法启动；多行内容在预算内清楚显示、滚动、编辑，窗口放大和缩小不破坏旧画面、草稿或焦点。人能只用键盘到达已有交互控件，外部系统仍从同一 owner 读取和修改内容。手写、生成、混合三种作者共用同一条路径。

此阶段把重心从增加容器转回自绘质量、资源成本和正常输入。组件布局已有 Tabs/Scroll/Split 可复用，但嵌套 reveal 与 Tab 可达性仍有具体缺口；自绘/文字存在普通尺寸下的纹理失败；资源调度需要观察实际分配和两窗公平性；语义动作沿用共同定义和 owner；普通开发者以统一导出消费验收。六条主线都保留，不另造展示产品，也不扩大到新控件库。

复用 `composable_ui.cj` / `composable_ui_window.cj`、native 现有 TextKit/NSString 排版光栅化、Metal 合成、文字资源缓存和工作量计数、accepted/candidate 事务、精确 semantic identity、正常 application host、原生焦点/选区桥接，以及当前三个消费者。参考既有 `verify_composable_scene_renderer.sh`、`verify_composable_ui_appkit_text.sh`、`verify_render_resource_efficiency.sh` 与页签桌面脚本；按实际覆盖选用，不全跑。复杂文字仍复用系统服务，不自研排版器、输入法或字形 atlas。历史研究只吸收重绘、状态归属和 Retina 经验，其旧 stop-line 不恢复为当前禁令。

## 执行组织

- 主执行为外部 DeepSeek 4.1 Flash，在原目录 `/Users/jiangxuanyang/Desktop/cangjie` 接续全部 A–E。原 GPT-6 Sol 任务 `01a0cc16-e3e3-7d30-bbbb-1c23dc2a1bed` 已被用户中断；不恢复它、Luna 委派、旧 Terra 任务或定时。先接收已有源码与原始证据，不重写已完成实现。
- 复杂问题通过 Codex CLI 的 `gpt-5.6-sol` 聚焦只读咨询，通常 high；核心并发、FFI/GPU 生命周期、状态归属或公共契约需连续判断时 xhigh，不默认 max/ultra。DS 负责实现、自验与整包报告，咨询方分析具体问题和方案反例，不同时写代码、操作桌面或重复整套验证。所有同 target 构建串行，桌面同一时刻一个操作者。
- 普通问题两次实质修复无进展就咨询；核心归属/生命周期方案不清先咨询，第一次修复失败不盲猜第二方案。提供同次复现、必要源码/diff、假设与原始结果，要求可区分检查、方案和验收；答复不当运行证据。首次咨询及一次有新证据的追问仍无方案，或触及 AGENTS 跨模型失败上限，向指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61` 升级，其余独立工作继续。不因换执行者清零失败累计；CLI 不可用时保留具体阻塞，不擅自换型号。
- 开始前保全本包相关 dirty diff、未跟踪文件与源码指纹，确认实际写入竞争。不建 worktree、不切分支、不 stage/commit/push，不改并行鸿蒙、用户实例和历史证据。桌面按已有授权使用，锁屏跳过并继续独立项，不反复解锁或改设置。

## A. 必要返工：真实可达、完整可见

### A1 嵌套 reveal

源码已确认：内容按 `inner.y - offset` 布局，`revealAcceptedNodeIfNeeded` 却以 `top += offsetDelta` 把内层移动传给外层。现测试只验 inner 请求大于零、outer 大于等于零，未检验下一个已接受场景。

先建立能区分方向的 RED：目标初始在内层屏外，内层滚动已足够时外层应保持；确需两层协同的第二例中，提交后目标须经过全部真实祖先 clip 可见，不能只是 offset 改了。用 accepted 到本次请求的实际位移推导坐标；若已有 pending request，不能把请求坐标和旧 accepted bounds 混算。修复后覆盖重复 reveal 幂等、同坐标兄弟不动、拒绝保留旧 accepted、随后合法提交可恢复。继续允许手写合法嵌套，不为通过测试放宽生成描述现有嵌套限制。

### A2 纯键盘的控件入口

native `nextFocusableNodeFrom` 当前只列文本/button/boolean；页签标题、分隔条、slider 虽有获得焦点后的按键逻辑，却没有 Tab 入口。统一已有控件的可聚焦策略，沿用 input scope、模态层、enabled 与 accepted 身份，不简单把所有可点击节点加入顺序。

页签组采用一个 Tab 停靠点（当前可用标题；失效时明确退到可用项），组内方向键只移焦点，Enter/Space 切页；Tab 进入当前页，Shift-Tab 能离开，禁用/隐藏页不截获。已有可调分隔条和 slider 能用 Tab 到达并按现有方向键规则改变值。不要新造第二个独立焦点 owner。

验收从正常应用中已聚焦的前一个控件出发，使用 CGEvent Tab 到达标题而不是先点击标题；正反向、禁用标题、页内编辑、分隔条/slider、切页后的真实 UTF-16 替换各有精确状态和 accepted 身份断言。已有鼠标、AX 和受控 responder 证据可复用其各自范围。

## B. 新框架能力：大控件不等于大块空白纹理

旧问题已有同次原始证据：`/private/tmp/cjgui-sol-a2-generated-detail.log` 中 980×620pt、scale=2 的文字节点申请 9,721,600 bytes，超过 8MiB 单节点限制，`commit_text_prepare_failed` → status99。320×240 通过只定位了条件，不能把生产缺口改称夹具问题。

1. 保留原尺寸 RED；首先将静态短文本的 raster 范围收紧到正确排版后确实可见的文字区域，保持换行、字体回退、基线、中文/emoji、Retina scale、圆角祖先裁剪和原始布局坐标。空白空间不应占用等面积文字纹理。测量不得反向改变 owner、控制器布局或事件坐标。
2. 多行内容确需大面积显示时，提供有界的可见文字分片或同等有据方案，复用既有系统排版和 Metal 路径。只画可见内容，不能靠缩字体、删内容、把失败改成功或将整个控件切成 AppKit UI 绕过自绘。先在现有结构做有限设计，不引入完整字体引擎或新的通用渲染平台。
3. 方案实施前在本页简记实际预算：每次 raster 分配、活动场景、候选/回滚、缓存、临时 staging 各约束什么。不能仅把 8MiB 常量放大解决；若分片要求调整原“每节点”限制的含义，明确单片与合计限制、拒绝反例和生命周期。24MiB 现有场景预算先作为约束核实，不把它声称为全进程上限。超预算必须给具名、可解释的原因，保留旧 accepted 场景并支持下次合法恢复；首次启动失败清理后也保留原因。
4. 接通实际 native 光栅化、upload、编码消费和释放，不能只把分片信息列到场景。active 编辑、选区/caret 更新、普通 refresh 和 theme/resize 都使用一致坐标和资源身份；主题、字体、比例、内容和裁剪变化该失效时失效。

必需验收：320×240、980×620、1440×900 三档逻辑窗口/视口，至少受控 1×/2× scale；真实窗口记录实际 scale，不能把注入比例称为真实显示器。覆盖大矩形的一行短文字、可见多行文字、总文本 10k/100k 但可见区有限的长内容。精确对照首部/中段/尾部、滚动后内容、无缝裁剪及编辑读回；跨分片选区与 emoji 不截断。旧大尺寸首次启动与小→大→小 resize 必须走正常场景接受。预算超限负例、拒绝后旧控件继续编辑、关闭后自有资源收敛必须有证据。

### 实施前资源边界（方案，待实测）

现有 native 约束是单次 BGRA raster/Metal texture 最多 8 MiB、一个 accepted 文字场景合计最多 24 MiB；前者把 980×620pt、2× 的整块纹理拒绝，后者不是进程 RSS 或所有 Metal 资源上限。本包保留单次 8 MiB，把确有内容的可见矩形按完整像素边界分成若干纹理；一个节点的分片合计计入 24 MiB，节点不能借分片绕过场景预算。短文字先用同一字体和换行规则测得实际可绘区域，再与节点及完整祖先 clip 相交，不能用控件面积代替文字面积。

每片 raster 的 CPU BGRA staging 最多 8 MiB，逐片释放；每片上传后的纹理最多 8 MiB，一个 accepted 场景的文字纹理合计最多 24 MiB。准备 candidate 时旧 accepted 资源仍被保留，故事务期间两套场景纹理可能并存，最多各自 24 MiB，不能把 24 MiB 误报成瞬时双场景峰值。文字缓存目前随 scene node 持有，没有独立跨窗全局文字缓存；新方案先沿用这个生命周期，候选拒绝丢弃候选资源，关闭窗口释放其 scene，避免再添无限制缓存。创建纹理、总预算和维度失败需分别留下可解释状态；未接受的 candidate 不替换旧画面，下一次合法候选可以恢复。实测字节及释放边界在 C/D 记录，若实际持有量不符合这些界限，先修生命周期。

## C. 资源复用和两窗响应

在 B 的真实资源路径上区分内容变化、纯位置变化、裁剪变化、颜色/字体变化、选区/caret 变化。保持必要失效正确；仅移动或选区变化不应无条件重建整篇文字。缓存策略以实际热点和对照决定，不为了保住方案叠加缓存层。

沿用同一进程正常 application host 双窗：A 滚动/resize/更新长内容，B 按既有入口修改一个可见字段；分别观察 B owner 到达、accepted 具体内容和提交，不用版本加一代替值正确。负载停止后不得继续 raster/upload/重建，关闭 A 后 B 仍可编辑。记录活动、候选、缓存与临时分配的实测字节及释放边界；这是受测文字资源账目，不是 RSS/Metal 总显存峰值。内存预算到达时应有明确拒绝或有界回收，不丢旧画面、不饿死另一窗。

## D. 一组有效成本对照

复用现有性能夹具和 native 工作计数，针对 B/C 新路径记录冷启动、热内容更新、scroll、resize、selection/caret、idle，原始单调时间与实际工作量分开。内容/可见几何/字体/scale 相同才比较手写与生成；混合做正常消费覆盖，不机械再跑所有旧矩阵。

在计时外验证每类操作真的改变了预期内容或几何，clamp 后没移动不当作滚动性能。计数使用实际 build/layout/raster/upload/native submission 计数器，不能将 `nativeSubmissionVersion` 或其他版本差当作提交次数。原矩阵的 hot 只是强制同内容 refresh，后续沿用时使用明确名称；相邻 MonoTime 读差不是时钟精度测量，保留单位和真实零样本即可。

取必要冷热原始样本（热场景有界20次），旧实现大窗口失败与小窗口正常基线分别记录，不能计算不存在的失败路径加速率。无需构造历史整个分支或全库基线。若实测常见负载稳定回退，先简化/收窄默认策略并验证，不以“不声明性能”代替交付。submit、GPU completed、drawable 读回、桌面截图各自标范围，不声称显示器物理呈现或行业领先。

## E. 公共消费与最终汇合

作者端先集中定位，稳定后统一一次含空格导出。复用规则混合面板、生成任务消费者及 UI-only 树；为大文字消费做正常参数/数据夹具，避免复制 renderer 或业务解释器。原有 shared_document 的 owner/编辑路径如适合可复用，但不要扩成新的文章产品或引入第四套并行验证。

至少一个无外部能力的普通 UI 消费者在导出目录启动大文本节点，两个领域的共同字段/生成路径仍能编辑→公开读回→外部改值→显示→继续编辑。三者从同一最终根解析代码、native、资源；包含 A 的正常 Tab/reveal 与 B 的正常窗口显示证据。按实际变更跑相关包/探针、`cjpm build --skip-script`、声明/影响范围、指纹和 `git diff --check`。旧模型回合、端点竞态、拖放、全套历史压力无需重跑。

完成时集中报告新根因、复用资产、改变的公开契约、原始证据及未验边界。源码、执行者自验、受控比例、工具输入、实际显示分别标注。只改文档不重建；全绿后不重复导出或抄报来维持运行。实质阻塞按失败累计升级，锁屏只阻塞相关桌面段；独立工作完成后明确剩余并结束等待。所有自有实例按身份在整轮结束回收，保留用户实例、剪贴板和日志。

本包不做：HarmonyOS、输入法引擎、系统 IME/VoiceOver 专项、真实模型新回合、真机性能、安装/公证/发布。暂不新增治理文件或逐轮任务卡；后续实质执行证据追加在本页，ACTIVE 仅维护当前摘要。

## 2026-09-23 暂停交接与尚待汇合

用户中断原 GPT-6 Sol 执行后，指导只读核对近期执行记录、部分源码和原始日志，没有重跑产品测试，也未将 A–E 宣布完成。以下供新执行者定位成果与缺口，不要求从头重复验证。

- 原执行者报告已实现 A1 accepted 坐标 reveal、A2 Tab/页签入口、B 有界文字 raster/Metal 分片、预算拒绝与恢复、C 双窗及释放、相关计数。目标脚本包括 `verify_large_text_window.sh`、`verify_generated_ui_reveal_keyboard.sh`、`verify_generated_ui_tabs_keyboard.sh`；应把实际证据逐项对照本页 A–D，不能仅按报告标题算通过。
- 有界证据入口：`/private/tmp/cjgui-render-stage-a1-a2-reveal.out`、`/private/tmp/cjgui-render-stage-a2-cgevent-final.out`、`/private/tmp/cjgui-render-stage-b-invalidstatus-green.out`、`/private/tmp/cjgui-render-stage-regression-resource.out`、`/private/tmp/cjgui-render-stage-regression-text.out`、`/private/tmp/cjgui-render-stage-regression-scene-green2.out`。这些是原执行者运行记录，指导未逐项重新建立全部结论。实际窗口 1440×900 请求被系统约束为 1440×841 的记录，与受控精确视口、受控 1×/2×比例必须分别保留。
- 指导已读到统一导出链 `PASSED exported consumer chains`：日志 `/private/tmp/cjgui-preview-chains/cjgui preview 20260923135758-73112/chains.log`，消费根 `/private/tmp/cjgui-render-stage-final green export`，指纹日志 `/private/tmp/cjgui-render-stage-final-green-fingerprint.out` 为 `files=82 identical=74 rewritten=8 sha256=4313b2d6c63ef8c5489a3786cbef1fea37f810276702d0078078a5f34162fb07`。这轮通过早于后续消费者配色修改，不能称为当前最终导出。早先 `SKIP_STEP2C=1` 仅是下游独立证据，不替代这次完整链。
- 已知未收口问题：知识目录 `catalog_surface` 为深色，而标题、操作按钮、状态与普通正文仍有默认深色前景。当前 `tree_outline_consumer/src/main.cj` 只给大文字 `detailStyle` 补浅色，尚未覆盖全部控件。其 `/private/tmp/cjgui-render-stage-tree-style-test.out` 的通过也不证明整窗对比度正确。复用现有共同样式，统一默认及大文字配置下的标题/正文/按钮/状态及正常、焦点、禁用状态，不新造全局样式继承系统、不降低文字大小来隐藏问题。
- 接续顺序：保存接手基线并确认无实际写入竞争 → 对照已有 A–D 证据并只补真实缺口 → 完成上述可读性与真实截图核对 → 作者稳定后刷新 E 的统一导出/三消费链，归并当前源码证据和未验边界。若新变化影响渲染/焦点，针对性回归对应路径；仅配色改动不触发全套历史矩阵。整包集中报告，不按补丁停工。

## 2026-09-23 DeepSeek 4.1 Flash 接续执行记录

接手基线：tracked diff 存于 `/private/tmp/cjgui-ds-baseline-20260923/tracked.diff`（1,672,772 字节）+ `status.txt`/`untracked.txt`/`head.txt`。接手时无 cjgui/cjpm 进程，未发现实际源码写入或构建产物竞争；原执行者的 A–D 源码与 `/private/tmp` 原始日志保全未动。

### 1. 新根因：整窗可读性缺陷不止“配色未补”

1. `CjguiComposableUiStyle.textColor` 默认近黑 `(0.12,0.13,0.16)`，窗口 clear color 为深蓝 `(0.08,0.16,0.20)`，目录面板又是深色 `(0.06,0.10,0.16)`：任何没有显式写色的节点都在深底上画近黑文字。改动前只有大文字 `detailStyle` 写了浅色，标题、操作按钮、状态、正文、行控件全部不可读。
2. **框架缺陷（此前未记录）**：`CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE` 同时被排除在两条文字绘制路径之外（`CjguiComposableNodeUsesGpuText` 与场景 overlay 的 kind 过滤），页签标题从不绘制自己的 label。它在 AX/键盘里可达、可按下、可切换页面，但屏幕上看不见。仅靠“配色补丁”无法收口此项。

修复方式：让 TAB_TITLE 进入 GPU 文字路径，其纹理文字只取 label（该节点的 `value` 存页面 key，不能画在屏幕上），并按 label 使用 2pt 纵向留白（新公共辅助 `CjguiComposableNodeUsesLabelTextInset` 统一纹理量测、位图绘制与 overlay 三处，保证量测与绘制一致）。`native/cjgui_internal_renderer.m` 与 sidecar 已重建。

### 2. 应用侧统一（不新建主题/继承系统）

`tree_outline_consumer/src/main.cj` 把**已有**的 `CjguiComposableUiTheme.beaconDark()` 展开为同一个既有 `CjguiComposableUiNamedStyleCatalog` 里的角色：`catalog_surface`（保留原 padding/gap/背景/边框与身份）`catalog_title`、`catalog_body`、`catalog_status`、`catalog_action`（含 normal/hover/pressed/focused/disabled/selected/checked）、`catalog_row`、`catalog_tab_title`。标题、正文、状态、行、操作按钮、页签标题都按角色取 paint，节点自己保留字号与几何（沿用两个应用消费者“命名样式只带 paint”的既有约定）。默认与大文字两配置现在只差字号，不再一配置有浅色、另一配置没有。

共享 `cjguiComposableTabs` 增加可选的 `titleStyle`/`titleInteraction`（默认空样式/空交互：不传即与此前完全一致的标题），使深色表面能决定页签标题 paint，同时不新增第二个焦点 owner、不引入颜色继承。

### 3. 本轮验证（均为本次源码、本次运行）

- `runtime/cjgui` `cjpm test`：**176/176 PASSED**。
- `tree_outline_consumer` `cjpm test`：**10/10 PASSED**，含新测试 `uiOnlyCatalogRolesStayReadableOnTheDarkSurface`（标题/正文/状态/行/页签标题对深色表面的 WCAG 对比度 ≥4.5；页签标题与操作按钮声明 normal/focused/disabled；默认与大文字解析到**同一个** body 角色且文字色 token 相同）。
- 真实窗口可读性链 `native/scripts/verify_tree_consumer_catalog_readability.sh`（新）：两种配置各取一个稳定帧（连续两次捕获一致才接受；表面色非主导或遮挡体主导则重捕），再在**同一帧**内按控件 accessibility frame 裁剪量测。PASSED：默认 标题 3438 / 页签标题 632 / 操作按钮 1134 / 正文 12510 / 状态 1879 个亮像素（阈值 0.35，深色占比 0.80–0.97）；大文字 标题 3438 / 页签标题 632 / 操作按钮 1134 / 正文 162177；大文字配置的状态行在窗口外，按 `clipped_outside_window` 如实记录而非算通过。像素量测工具为新 `native/scripts/region_luminance.py`。
- A1/A2 回归（本次改动后重跑）：`verify_generated_ui_reveal_keyboard.sh` PASSED；`verify_generated_ui_tabs_keyboard.sh` PASSED（Tab 进入活动标题、Shift-Tab 返回/离开、方向键移动不改页、Enter/Space 切页、禁用标题不激活、分隔条与 slider 可达且方向键改值）；`verify_composable_ui_tabs_native_selection.sh` PASSED。A1 方向/两层协同/幂等/兄弟不动/拒绝保留旧 accepted 的判定继续由 `src/composable_ui_reveal_identity_test.cj`（4 例）与 `src/composable_ui_scroll_viewport_test.cj`（11 例）承担，均在本轮 176 例内通过。
- B/C/D 回归（本次源码重跑 `verify_large_text_window.sh`，PASSED `CJGUI_LARGE_TEXT_WINDOW passed=true`）：320×240 / 980×620 / 1440×900 短文字均 47040 字节单片（旧为 9,721,600）；10k 多行 2 片 9,721,600；100k 多行 3 片 19,445,760（仍 ≤ 24MiB 场景预算）；受控 1×/2× 比例、320→1440→320 往返、`text_resource_budget_exceeded` 拒绝后旧 accepted 保留并恢复、启动预算失败保留具名原因、同 host 双窗 B owner 读写与空闲收敛（`idle_raster=14->14`）、关 A 后 B 仍可用、资源释放。
- 其他回归：`verify_tree_consumer_human_rows.sh` PASSED；`verify_composable_scene_renderer.sh` PASSED。
- E（咨询后的最终源码冻结，一次统一导出 + 三消费链）：`verify_framework_preview_consumer_chains.sh` **PASSED**，含空格根 `/private/tmp/cjgui-preview-chains/cjgui preview 20260923151216-6843/export`，指纹 **`files=82 identical=74 rewritten=8 sha256=c05c51493507cdf6d392d6e379aeb0f65b898e1a6c68f663e184ea8fbfdf48d4`**（不同于修改前的 `4313b2d6…`；早一轮 `20260923145131-96226` 的 `26e01268…` 已被本轮咨询后的源码取代）。该链在导出根内完成三个消费者的构建、真实桌面输入/读回、外部改值后继续编辑、规则页签往返与双窗段。`verify_export_fingerprint.sh` 对同一根复检 `82/82 identical` 且负例控制全部拒绝。随后以同一导出根运行可读性链（`CJGUI_TREE_READABILITY_APP_DIR=<export>/consumers/tree_outline_consumer`、`CJGUI_TREE_READABILITY_RUNTIME_DIR=<export>/framework/cjgui`）：默认 5 控件、大文字 4 控件全部可读，PASSED。日志 `/private/tmp/cjgui-ds-preview-chains2.out`、`/private/tmp/cjgui-ds-export-readability2.out`。

### 4. 改动文件与未验边界

改动：`runtime/cjgui/src/composable_ui.cj`（tabs 可选标题 paint）、`runtime/cjgui/native/cjgui_internal_renderer.m`（TAB_TITLE 文字绘制、label 留白辅助、GPU 文字谓词拆分）、`runtime/cjgui/examples/tree_outline_consumer/src/main.cj`、`.../shared_definitions_consumption_test.cj`、新 `native/scripts/region_luminance.py` 与 `native/scripts/verify_tree_consumer_catalog_readability.sh`。未改 `runtime_state.cj`、`cjpm.toml`、公共 C FFI 头；`git diff --check` 干净。

未验边界（如实保留）：无人工物理输入，桌面证据为工具 CGEvent/AX；“目视”为图像输入模型观察（见第 7 节），不是人工肉眼；系统 IME/VoiceOver、真机、发布/公证、全进程峰值内存不在本包。TAB_TITLE 文字绘制由框架单测、页签键盘链、页签原生选择链、场景渲染回归与新的整窗像素链共同覆盖，但没有单独的纹理字节单测；Sol 建议的“accepted 节点 paint provenance 探针”（读 `textTextureCacheKey`/`textTextureByteCount`/tile 数与非零 alpha 像素）本轮未新增，故“label 变→重栅格、value 变→不重栅格”只有缓存键源码依据（键含 `displayText` 与文本 RGBA/几何/裁剪签名，不含 `value`），没有运行断言。共享主题的主操作 paint 在白字配蓝底上实测约 4.4:1，略低于 WCAG AA 正文字号的 4.5，本轮沿用共享主题值并如实记录，未为此改公共主题。真实 1440×900 窗口在不同运行被系统约束为 1440×841 与 1440×844 两次，均按实际值记录，受控 1440×900 视口始终单列，不混称真实显示器测试。

### 5. 聚焦咨询：GPT-5.6 Sol（Codex CLI，只读，high）

按提示词要求，对 TAB_TITLE 文字绘制与相关风险做了一次限域只读咨询（`codex exec -m gpt-5.6-sol -s read-only -c model_reasoning_effort=high`，登录状态 `Logged in using ChatGPT`；原始材料 `/private/tmp/cjgui-sol-consult.md`，答复 `/private/tmp/cjgui-sol-consult.out`）。咨询方只读，未改文件、未构建、未操作桌面；其答复不作为运行证据。

- **确认根因**：逐条排除了 Cangjie 侧文字子节点、专用 native 页签绘制、staging/accepted 拷贝丢字符串、AX overlay 等候选，认定“TAB_TITLE 同时缺失于两条文字路径”在字形绘制归属层面是完整解释；并指出我的前后对照把“路由修复”和“消费者取色”合并了，源码本身才是“改前任何颜色都画不出字形”的依据。
- **可区分检查**：建议用 accepted 节点 paint provenance 探针读 `(label, value, textAlpha, clip, textTextureCacheKey, textTextureByteCount, textTextureRect, tileCount, nonzeroAlphaPixels, finalDrawableRegion)`，可区分“字符串丢失 / 准入拒绝 / 光栅几何 / 编码裁剪”四类失败。
- **采纳的实质改进（本轮已实施）**：`CjguiComposableNodeUsesGpuText` 同时被“文字绘制准入”和“活动 TextKit 输入生命周期”两类路径复用；把 TAB_TITLE 加进去会让获得焦点的页签标题进入 `refreshGpuTextForActiveInput`，尤其是 `prepareInactiveTextResourceForFocusChange` 的焦点丢失重栅格**不经过场景文字预算准入**。据此把谓词拆开：新增 `CjguiComposableNodeHasGpuText`（准入、场景文字资源记账、编码、CPU overlay 排除、读回分类，含 TAB_TITLE），活动输入三处改用既有 `CjguiComposableNodeIsTextInput`（仅三种文本输入）；并顺手把 `scheduleActiveTextResourcePreparation` 的内联 kind 列表也归到同一谓词，避免再次分叉。
- **未采纳/记为边界**：Sol 建议进一步把量测与光栅统一到一个 draw-rect 辅助并做 harness 级反例（预算越界保留旧场景、24pt 标题在 1×/2× 与圆角裁剪下的片数/字节、状态换色重栅格）。本轮只采纳了谓词拆分；这些反例未构造，已在上方未验边界写明，不当作已验证。
- **确认无需改动**：命中/焦点/AX 不受影响；可见文字与 AX value（页面 key）本就不同，属独立 AX 契约问题，不能为“看起来一致”去改 `value`；有纹理的标题会让通用不透明读回探针保守拒绝其采样，属预期诊断退化。

### 6. 咨询后复验

谓词拆分后于同一批源码重跑：`cjpm test` 176/176、消费者 10/10、`verify_generated_ui_tabs_keyboard.sh`、`verify_composable_scene_renderer.sh`、可读性链（作者树）全部 PASSED；随后重做导出并得到上述最终根/指纹，导出链与导出根可读性核对再 PASSED。

### 7. 目视核对（图像输入模型，独立于像素统计）

本主执行者所在路由 `deepseek-official/deepseek-v4.1-flash-expires-on-0910` 不声明图像输入，`read_image` 在工具层被拒，因此上图核对改为委派给同一提供方的图像输入模型 `deepseek-official/deepseek-v4-flash-vision-exp`（子代理，只调用 `read_image`，未运行 shell、未改文件）。这是本轮唯一一次真正的“目视”观察，与像素统计相互独立；它不是人工肉眼，也不替代人工复核。

被观察的四张图：修复前的大文字窗口 `/private/tmp/cjgui-render-stage-big-visual-first.png`；修复后作者树默认配置 `/private/tmp/cjgui-tree-readability/20260923151048-5561/default-frame.png`；修复后作者树大文字配置 `.../large-frame.png`；修复后导出根默认配置 `/private/tmp/cjgui-ds-export-readability2/20260923151553-11178/default-frame.png`。

观察结论（照录其判定）：修复前大文字窗口的标题偏暗、按钮为“很淡的灰”、两个页签“几乎无法可靠确认”，只有大文字正文可读，属低对比；修复后默认配置可逐字读出 `知识目录（树形多选）`、页签 `目录`/`条目`、四个蓝色按钮 `展开全部 收起全部 全选条目 清空多选`、18 行 `domain-0 · 绘制 / domain-1 · 布局 / domain-2 · 输入` 与状态行 `多选 0 条 · 可见 3 行 · 焦点 unfocused|none|0`，五项均判为清晰可读；修复后大文字配置的标题/页签/按钮/正文同样清晰，状态行被推出视口（与像素链 `clipped_outside_window` 一致）；导出根默认帧与作者树默认帧判定为像素等价。

一处需要保留的混淆：修复前那张图底部另有一个系统“已添加到剪贴板”提示遮住部分正文，因此它的“状态行不可见”不能单独作为改前证据；改前不可读的可靠信号是标题/页签/按钮的低对比与像素链里这些区域零亮像素（该图是大文字配置，状态行本就在视口外）。


## 2026-09-23 指导复核与接续结论

本次指导只审阅当前源码和原始日志，没有重跑构建、测试或桌面操作。上文是执行者自验记录，保留原文；其中“整包收口”的范围经本次核对应修正为：实现和导出已有重要进展，资源释放、性能与全部交互态仍有具体欠项，统一接入下一包，不通过改写目标宣告完成。

### 接受的进展

短文字紧凑分配、实际分片进入纹理/Metal 编码、单片和场景预算拒绝及恢复，已有实现与探针证据；TAB_TITLE 的 label-only GPU 绘制与活动 TextKit 谓词分离有源码、窗口链和像素证据。最终三消费者导出链见 `/private/tmp/cjgui-ds-preview-chains2.out`，导出根可读性见 `/private/tmp/cjgui-ds-export-readability2.out`；对应根 `20260923151216-6843/export` 与上文 `c05c5149…` 指纹一致。默认五类控件与大文字四类控件被核对，大文字状态行在窗口外的事实继续保留。

### 必须承接的缺口与方法

1. **性能不能按探针 PASS 收口。** 最新 `/private/tmp/cjgui-large-text-window/probe.log`（14:50）记录 100k 冷启动 1828ms，resize 1093ms、热内容更新 1087ms，后两者各增加四次 raster/upload；这不是物理输入延迟或行业比较。探针和正常 runner 的 native flags 均未显式指定优化级别，因此先记录并校准真实构建，再在同配置下归因。静态逐片完整字符串绘制、保留焦点后再做 active TextKit 准备是待测热点，不是已经证明的全部原因。探针 `runTwoWindowResponse` 先结束 A 的工作再编辑 B，证明的是事后可用，缺负载期间排队/执行证据；关键热场景也尚无要求的20样本分布。
2. **资源和文字完整性需要更强反例。** 当前拒绝路径可能保留先前已准备的 staging 节点直到下次 configure/关闭，session 归零不能代替候选独有/current/scratch 资源观察。应先构造“候选先分配，后超预算”，在不刷新/不关窗时证明独有资源释放且旧 accepted 保留。失焦转换直接走 raster helper 的预算疑点只作为待判别风险。每片 alpha 非零和矩形连续不证明首/中/尾内容正确，须以可辨识标记和最终 drawable/正常截图核对滚动后的文字及接缝。
3. **配色补齐没有消除公共接入缺口。** `beaconDark().primaryAction` 基础前景仍为默认近黑，浅字只在 interaction.normal；任务消费者、两个模板漏接 interaction。知识目录页签 hover/pressed 与树行 pressed 又取该基础前景，当前正常态截图不能覆盖这些状态。新增 `titleStyle/titleInteraction` 只有手写 Tabs，生成 builder 未接通。下一包复用已有 NamedStyle 的 base+interaction 做一次选择、整组消费，并补生成入口、组合消费及事务，不能只继续逐个示例写颜色。
4. **开发者入口一并接通。** 默认目录重复文本是显式夹具构造而非本次证明的 renderer 重复绘制；应让默认数据与“可见”用词对应，保留长文本测试模式。导出 README 主要接入链接 `MACOS_APPLICATION_HOST.md` 当前未随包携带，两个模板仍采用不完整主题接法；这些与公共样式一起修正，从导出包创建普通应用验证。

[接续阶段：文字渲染响应与统一样式消费](2026-09-23-text-resource-response-style-milestone.md) 合并上述返工与新的框架能力，继续由用户选择的 DeepSeek 4.1 Flash 执行、GPT-5.6 Sol 聚焦咨询。旧任务与定时保持暂停。保留本页历史日志，不要求换执行会话重跑已接受且未受影响的全部验证。
