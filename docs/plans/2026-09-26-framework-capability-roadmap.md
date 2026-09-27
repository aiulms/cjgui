# CJGUI 框架能力缺口与三线推进表

基线：2026-09-26。用途：分清实际欠缺、实施归属和依赖，让编辑器、鸿蒙与第三条通用框架线并行推进。本文是规划清单；当前执行对象、开工/暂停及阶段结果仍只由 [ACTIVE_DIRECTION](../../runtime/cjgui/ACTIVE_DIRECTION.md) 指向，不另建逐轮台账。

## 1. 三条线分别交付什么

| 执行线 | 主责 | 框架与应用边界 |
| --- | --- | --- |
| **E：Pharos Mark 编辑器线** | 用正常编辑器检验文字、输入、滚动、共同操作、生成面板及大文档响应；发现通用缺陷时补 CJGUI | 文档存储、Markdown、SourceMap、搜索、保存、导出属于产品；通用排版几何、命中、输入、场景事务、渲染与公共接入属于框架。编辑器不能长期私补这些能力 |
| **H：鸿蒙后端线** | 复用仓颉核心，完成 surface/GPU 生命周期、系统输入、文字/选区、平台资源与独立 HAP 消费 | 仓颉核心 + ArkTS 薄壳 + XComponent + 必要原生桥。平台差异留在桥和后端；遇到共同契约缺陷仍回到 CJGUI，不在鸿蒙另建组件/业务树 |
| **F：第三条通用框架线** | 补产品未必立即触发、但普通应用需要的视觉效果、动效、系统可用性及配套诊断/交付 | 先在 macOS 正常应用交付通用能力，手写、生成、混合消费共用。鸿蒙按能力支持情况接续，不要求 H 当前包同步补齐每一种新效果 |

三条线按具体依赖协作。E/H 当前包的全部收口不是 F 开工前置；F 的视觉效果也不是编辑器继续开发的前置。共用源文件或公共契约发生交叉时，按第 6 节交接。

## 2. 基线口径：已有能力要接着用

以下来自当前源码和已有阶段证据核对，本次规划未重新构建或运行。**“部分/待验”不是“没有”，也不是“已完成”。** 清单状态只在阶段交付或发现新事实时修正。

| 已有基础 | 后续复用方式与边界 |
| --- | --- |
| 组件布局、树/虚拟列表、scroll/split/tabs、命名样式、交互状态、图片资源、生成式目录与候选事务 | 扩展当前链路；具体类型与支持面见 [组件](../../runtime/cjgui/src/composable_ui.cj)、[命名样式](../../runtime/cjgui/src/composable_ui_named_style.cj)、[生成入口](../../runtime/cjgui/src/composable_ui_generated.cj) |
| 圆角形状、子树裁剪及与裁剪一致的命中 | 已有真实实现；仍要遵守裁剪链容量。抗锯齿质量和新效果越界是增量工作，不能把圆角裁剪重新列为从零开发 |
| 已接受场景、未变输出跳过提交、节点/资源复用、文字可见分片、图片与文字资源预算 | 当前 native 绘制仍会清理并绘制整帧；资源复用不等于通用 display-list 缓存、脏矩形重绘或 partial present。预算也不等于进程全部 CPU/GPU 内存上限 |
| macOS TextKit/CoreText 排版和字体回退、系统 IME 代理、accepted 光标/选区几何、AX 属性和动作、DPI 变化接线 | 继续检验正常应用消费、复杂文字、VoiceOver 与跨屏；不能因缺验收就重写系统排版/输入法服务 |
| 窗口进度/计数、CPU/GPU 部分耗时、截图与局部取色、导出指纹及独立消费者 | 为新能力补最小观测即可；无需先建完整调试器或重跑所有历史脚本 |

## 3. 能力缺口清单与主责

状态：**缺口**＝已核对的公共能力缺失；**部分**＝基础存在但链路/覆盖不全；**待验**＝尚无足够行为证据；**候选**＝尚需需求或测量决定，不计入当前必交包。

### E / H 已有执行线承接

| ID | 能力与当前缺口 | 状态 / 主责 | 完成判据与边界 |
| --- | --- | --- | --- |
| E1 | 正常正文点击、拖选、跨片段高亮、键盘扩选、细光标、IME 与外部修改交错。accepted 几何已有，产品正常循环仍需接通 | 部分 / **E** | 同一正常窗口真实输入→范围/owner→accepted 几何/画面对应；失效版本、换绑、取消不误写。领域 SourceMap 在产品，几何与事件修在框架 |
| E2 | 混合中英文/emoji/组合字符与 bidi 的视觉—逻辑位置、行尾 affinity 等覆盖不足 | 待验 / **E** | 复用系统 shaping；按相同 accepted 排版检验命中、左右移动、选区和替换，补失败所需的公共表示。不是自建字体整形引擎 |
| E3 | 编辑器窗口拥有的真实生成 region、AppServices 绑定与公共候选/事件路由 | 部分 / **E** | 外部提交→该窗口接受节点→操作生成控件→读回真实 owner；非法候选保留旧面板。已有框架 holder 成功不能代替这条产品链 |
| E4 | 大文档滚动/锚点变化/编辑/异步保存并行时的有界响应；精确滚轮、指针形状、可用滚动条随产品需求补齐 | 部分 / **E** | 文档范围读取和保存归产品；通用 viewport、滚轮语义、cursor/滚动条组件归框架。测正常应用 owner/scene、内存与工作量；不把 GB 文档变成单个全文排版节点 |
| E5 | 富文本样式 run、内联内容的测量/命中/布局接缝由真实编辑需求检验 | 部分 / **E** | 现有 style runs 复用；tokenize、Markdown、公式语义和脚注属于产品。需要公共 inline box 时再按真实用例增加，而非把完整排版出版系统塞进框架 |
| H1 | surface 身份、原生引用、停止/重开与迟到回调 | 模拟器已交付 / **H** | 真实引用、在途卸载、原票停止/ACK、全零与同 PID 新实例已有证据；新增资源继续遵守同一仲裁，物理设备性能单列 |
| H2 | 系统文字/选区/组合输入、焦点及外部修改接续 | 草稿/选区与双域接续已消费，marked/cancel 待验 / **H** | 两款 normal HAP 的系统编辑→提交→外部改值→校准→续写及旧挂载防护已验；marked/cancel 保留当前 SDK/镜像/输入法的版本化边界 |
| H3 | 裁剪像素/命中、独立消费者与 normal/verify 同源交付 | 模拟器已交付，新增能力继续按包量测 / **H** | 实际像素、裁剪与命中负控及双域同源 HAP 原证复用；各阶段累计计数/TCP 往返不等于逐请求渲染性能 |
| H4 | 共享 region、生成候选接受事务与真实控件消费 | 双 normal HAP 已交付 / **H** | 设置/thermo 的外部提交→画面→系统输入/动作→owner，重排/拒绝保旧及同源指纹已验；模型与脚本候选分列 |
| H5 | 共享图片资源在鸿蒙的加载、绘制和生命周期 | 缺口 / **H 下一包** | [当前接续](2026-09-26-harmonyos-executor-handoff.md#h-image-resource-next)：PNG、fit/fill、key/version、公开状态、缓存/预算/退役与双域手写/生成消费；复用核心，平台对象归后端 |

E 的具体执行入口：[Pharos Mark 当前实施计划](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#input-session-20260927>)。H 的具体执行入口：[当前图片资源接续](2026-09-26-harmonyos-executor-handoff.md#h-image-resource-next)。本表归属这些能力，不重复下发其正在进行的补丁。

### F 第三条通用框架线承接

| ID | 能力与当前缺口 | 状态 / 实施包 | 可验收交付 |
| --- | --- | --- | --- |
| F1 | 效果输出范围/采样范围的公共内部契约；矩形/圆角矩形阴影；线性渐变 | macOS 共同定义及正常消费已交付 / **P1** | 严格拒绝、继承清除、裁剪、命名修订、聚焦文字与公共消费证据按各已验证快照复用；其他后端不由此自动覆盖 |
| F2 | 帧时钟、可中断补间/弹簧、交互状态过渡、停止后休眠 | macOS 正常初始化与公开候选/真实控件消费已交付 / **P2** | 首次交互、主题目标、绑定代次、停止收敛与已有反例保留；几何动画及未声明属性仍属后续范围 |
| F3 | 通用效果分组、alpha mask、组透明度与受支持的混合模式 | macOS 三项复核机制与两消费者汇合已通过 / **P4 前段** | normal/multiply、mask、提交前失败重试、缓存命中在途代次、独立节点/组动效及公开消费均有判别证据；不扩称所有模式或 H 后端 |
| F4 | 背景模糊/材质与窗口级系统材质适配 | macOS 内部背景模糊与系统内容背景材质首片已消费 / **P4 后段** | 内部 blur 有采样/缓存/预算/回退；系统材质有窗口宿主、主题事务与公开实际状态，OHOS 后端和前台系统视觉另验 |
| F5 | VoiceOver 实际操作、通用焦点可见性/键盘消费与系统主题/减少动态效果策略 | macOS 控件/AX/键盘及系统强调色已消费，VoiceOver 待验 / **P3** | 共同语义、accepted 代次、键盘 reveal、强调色跟随/固定与公开观察已交付；实际 VoiceOver 导航仍需接续，AX 查询不替代 |
| F6 | 多显示器不同 scale、运行中缩放的真实覆盖；新效果的边缘抗锯齿一致性 | 部分、待验 / **P1/P3** | DPI 接线与圆角已有；检验几何/命中/纹理/裁剪/效果一致。没有第二屏时如实保留实机欠项，先完成可控 scale 与 resize 验证 |
| F7 | 开发者可用的布局/裁剪/效果边界叠加，以及分阶段帧成本汇总 | macOS 首个公共诊断切面与双消费者已交付 / **F 诊断包** | [本包结果](#f-diagnostics-and-regression)含有界同版本快照、可关闭叠加和原始开关成本；未提供的细分指标标 unavailable，全帧绘制不称为局部重绘 |
| F8 | 剪贴板/拖放的图片、文件或富文本格式扩展 | 文本基础已有，**下一包先交付 PNG 公共交换** | [当前任务](#f-png-transfer-next)：标准 PNG→框架有界二进制交付→owner→既有图片资源呈现，手写/生成共用；文件、富文本及 E 的文档插图语义后续消费 |
| F9 | 通用重绘/合成复用、效果离屏缓存与预算、实际功耗/峰值资源诊断 | 部分 / **每包度量，按回退单独优化** | 复用已有缓存/分片；新增效果有自己的预算、失效、退役。只有实测瓶颈才扩大到 display-list、atlas、局部重绘或异步准备，不把这些技术名当必做项 |
| F10 | 新能力的公共目录、手写/生成一致性、模板与独立包消费 | 持续要求 / **每个 P 包** | 新能力共同定义一次，生成描述可发现并严格校验；不支持的平台明确能力状态；导出后两个独立消费场景接通，不只在开发仓探针里存在 |

**暂不列成基础完备性的硬缺口：**竖排/ruby、出版级多栏脚注、游戏后处理、压感笔/触觉、九宫格图片、径向/锥形渐变和全套描边/混合模式。分别属于后续应用需求候选；开包前确认现有实现与实际消费需求。编辑器若出现明确需求可提前提取其中一项。partial present 也需先验证后端能力及收益，不能由其他 API 的功能直接推定 Metal 当前路径可用。

## 4. 第三线按完整工作包推进

顺序默认 **P1 → P2 → P3 → P4**。P3 中出现影响现有应用的真实可用性缺陷时可提前，与视觉任务交错；P4 先完成一种效果分组消费，再扩大到背景采样。每包同时修复自己引出的缺陷并推进新能力，局部阻塞不停止独立项。

### P1：效果基础、阴影与线性渐变

这是第三线首个可下发实施包，承接 F1/F6/F7/F10。

**实施范围与路线**

1. 在现有 style/layout/scene 链增加所需效果描述。区分 layout bounds、实际输出 bounds、后续滤镜所需的采样 bounds 与祖先 clip；布局尺寸与命中仍按原语义，阴影不能凭空扩大可点击区域。当前节点 clip 与自身 bounds 相交，不能直接拿它裁掉外阴影：祖先裁剪、自身圆角填充、子内容裁剪分别处理。范围扩张由偏移、spread、算法核支持域及 scale 推导，不把 blur 参数直接当所有方向的固定膨胀量。
2. 先实现形状外阴影和线性渐变。阴影首版限定矩形/圆角矩形，明确参数单位与上限、渐变坐标/stops、透明度和绘制顺序；参数与停止点数量有界。参数非法、资源预算不足、native 准备失败均保留旧 accepted scene。默认无效果路径保持现有成本；任意路径、内/多重阴影及通用滤镜链留给后续实际需求。
3. 优先评估解析/形状 mask 复用，确需离屏时仅为效果组分配。无需为阴影先引入第二棵公共 UI 树或完成整套脏矩形渲染。当前全帧绘制可继续使用，但效果身份、样式比较和输出范围必须为后续局部失效留下正确依据。
4. 静态阴影缓存按形状、参数、scale 等实际依赖失效；正文变化或光标闪烁若不改变阴影形状，不应重算阴影。若采用不缓存的解析画法，则测量其真实绘制成本，不伪造缓存指标。
5. 手写样式、注册组合组件、生成描述/能力发现共用定义；增加严格校验与支持状态。新增属性进入布局/场景的相关复用签名、相等比较和提交路径，效果参数单独变化也必须生效。macOS 首先真实实现，鸿蒙仍明确报告当前支持范围，避免静默吃掉新属性。
6. 在既有正常消费者中完成两种布局/领域的消费，至少一个 UI-only、一个包含生成组件；视觉保持简洁、可读，阴影用于层级区分，渐变用于有明确用途的表面。复用已有窗口与截图设施，不为展示单独再造应用架构。

**收口证据**

- 真实窗口中切换/修改阴影与渐变；阴影超出自身框但受祖先裁剪，阴影区域不扩大命中；移动/移除后旧像素消失。透明渐变、滚动、resize、非法候选后旧界面继续可用；仅改效果参数也更新画面。
- 固定场景的局部像素/关系断言，包含“关掉效果或改错参数会失败”的负控；不同平台/font/scale 不强求整图逐像素相同。
- 同进程、同工作负载、有/无效果与冷热对照：CPU 准备、GPU/提交、资源字节和工作量分列；最小诊断给出输出范围、额外 pass/离屏像素、缓存失效原因（适用时），记录输入响应与空闲是否新增工作。若引入回退，先缩小效果面积/参数/默认策略或调整算法，再扩实现。
- 无效参数、预算拒绝、关闭、替换及两窗口资源归属有针对性证据；无变化刷新不重复 build/分配。正常文本编辑不被效果缓存牵连。
- 当前框架消费包统一导出在含空格独立目录从零构建并消费新能力，源码/资源指纹相符；生成链确认描述经解析/绑定实际送达。公共接口暂按 experimental 范围说明，不以本包冻结全部效果 API。

<a id="p1-review-p2-package"></a>

### P1 指导复核与下一整包：效果正确性收口 + P2 动效基础

复核日期：2026-09-26。依据为当前源码和[执行者原报告](../../.resultverify/P1_effect_verification_report.md)，本次指导未构建或重跑窗口。**保留阴影/渐变真实实现和两种消费者的有效像素证据；P1 尚未整包通过。** 原报告的完整 PASS、非法候选保留旧界面、性能无回退，均应以以下限定和返工为准。已有文字结构体定义顺序、导出源清单漏项的集成修复继续保留。

#### 已确认的问题与实施依据

| 项 | 当前源码/证据事实 | 本包修复与判别要求 |
| --- | --- | --- |
| A1 生成效果准入与继承 | `validatePropertyValue` 对畸形 shadow/gradient 仅记 advisory；`declaredShadowOf/declaredGradientOf` 把显式 `none` 也当作继承。消费者非法用例随后自动恢复合法结构，不能证明拒绝时旧 accepted 未变 | 恢复原任务的整候选拒绝，给出稳定 reason/path；未声明继承，显式 `none` 清除，空串语义明确统一。先建立含命名效果的 accepted 界面，分别清除阴影/渐变；非法提交后先读结构版本、身份、样式与旧控件操作，再提交合法恢复。用真实外部公共客户端送候选，而非仅在应用按钮内调用 holder |
| A2 效果裁剪与缓存 | native 在 `CjguiAppendMetalShadow` 之前因自身 clip 为空跳过整个节点，本体完全出视口而阴影仍在视口时会错误消失；`appendStyle` 结构签名遗漏两种效果 | 阴影按输出范围与祖先 clip 判定，本体绘制仍按本体范围；保持命中不扩张。补“本体完全裁出、阴影仍可见→再移出后消失”的像素反例。补齐结构签名的效果依赖及效果独改用例；该签名缓存默认关闭，问题只归于显式开启路径，不扩大为普通窗口必现 |
| A3 数值与工作量边界 | 手写 RGBA 可带 NaN/Infinity 进入效果，渐变有效性没有检查颜色；`normalizedStops` 先对全部 stops 反复重建列表排序，再截成 4 个，构造工作量并未有界 | 把数量和数值准入放在排序/分配/native 提交之前；超限与非有限值具名拒绝，不先截断或抹掉错误再宣称合法。有限参数是否允许规范化必须在同一公共定义说明；生成侧与手写侧语义一致。保持透明色与合法无效果可用。反例覆盖超量 stops、非有限色值、边界合法输入及拒绝后旧场景不变 |
| A4 公开发现与平台配套 | `PROPERTY shadow/gradient ... values=none` 只发布一个枚举值，实际却接收有结构的字符串；`describe` 没有由属性定义完整发布其编码/单位/范围。macOS CJ/C 声明当前吻合，OHOS 保持旧 snapshot | 把格式、单位、上限、`none`、experimental 和后端支持面由共同定义发布，公共客户端只凭发现信息即可组出合法效果。更正“追加 36 字段”：当前静态比对是 59→94，新增 35 项。F 负责 macOS 公共支持契约及同步前校验；H 下一次同步时成套更新 CJ/header、重编重链，并对未实现效果明确拒绝或采用调用方明确选择的降级。当前冻结 OHOS 并未实测接受新效果，不能写成“已忽略且不崩溃” |
| A5 原验收缺口 | 两窗实为两个进程；带阴影卡片无 action；性能仅 10 次空闲 CPU/RSS 汇总；导出只有生成侧消费本次效果。SHAPE 失败无变更前对照 | 用一个正常 host 的双窗补资源归属/替换/关闭与输入；加一个可交互阴影节点，框内点击触发、仅阴影区点击不触发。补下述活动负载对照和 UI-only 导出消费。SHAPE 失败先定位是否阻断所需量化，只修相关原因或复用可信计数入口；在缺前基线时不归为“既有失败” |

定位入口：A1/A4 在 [generated](../../runtime/cjgui/src/composable_ui_generated.cj)、[命名样式编解码](../../runtime/cjgui/src/composable_ui_named_style.cj) 与 [任务消费者](../../runtime/cjgui/examples/generated_panel_consumer/src/generated_region.cj)；A2/A3 在 [组件与布局](../../runtime/cjgui/src/composable_ui.cj) 及 [native](../../runtime/cjgui/native/cjgui_internal_renderer.m)。公共指针 ABI 当前没有 size/version 握手，因此不能混用新头文件与旧仓颉结构；本包最低要求是配套版本、声明镜像及重新构建校验，无需为本次效果扩大成全框架 ABI 重写。

#### B：同时推进 P2，交付可消费的动效基础

复用 P1 样式、现有交互状态、窗口刷新和提交链，新增最小公共动效实现；先做不改变布局的颜色/透明度状态过渡及一个可中断弹簧标量。本包透明度指节点 paint 的 alpha，隔离组透明度仍属 P4。弹簧值消费在明确有界的视觉属性上，避免越界 alpha 或意外扩大命中。

1. **时间与状态。** 单调时钟推进，显式传入时间以便确定性测试；变帧间隔、长暂停有明确有界策略。补间改目标从当前呈现值开始；弹簧改目标保留当前值和适当速度。业务目标/版本、accepted 样式目标与当前视觉值分别归属；一次业务操作不因每帧推进而重复执行。
2. **生命周期与事务。** 动效绑定窗口实例及 accepted 节点身份/代际。同 key 重排可保持连续；换绑、销毁、关闭按契约取消，旧完成不会落到新实例。被拒结构/样式候选不能启动或污染当前动画。视觉帧失败保留上次有效输出，业务 owner 不回滚成视觉状态。
3. **帧调度。** 复用正常应用循环，仅活动动画申请后续帧；隐藏/暂停/恢复采取确定策略。停止后帧请求、提交和资源收敛，同 host 另一窗可继续输入。颜色变化不触发正文重新排版、图片解码或全文纹理重建；沿现有渲染接缝避免无关工作。
4. **共同定义与系统策略。** 手写、生成和注册组合组件消费同一动效参数/状态规则，生成发现公开实际支持范围并严格校验。macOS 接入系统减少动态效果偏好，偏好变化时已有动画可确定地收敛；公开目标/当前值/活动状态可供外部理解，不要求每帧广播或调用模型。几何动画、跨容器转场与玻璃继续留在后续包。
5. **两个真实消费者。** 在已有 UI-only 消费者实现 hover/pressed/取消的颜色过渡，在生成消费者实现同定义效果与可中断值变化。连续快速操作、中途反向、重排/拒绝/关闭和减少动态效果都有判别证据；至少一条从外部公开候选进入窗口，再由真实控件输入触发变化并读回真实 owner。

A 的准入/native 修复与 B 的纯时间状态、消费者准备可以交错推进。B 接入同一 native/窗口符号时再合并写集；不等 A 所有历史验证结束才开始 B，也不让动画依赖尚未修正的效果裁剪/准入语义。

#### C：合并一次性能与交付验收

- 在同进程、同窗口数量和相同内容下比较无效果/静态效果/活动动画，冷启动与热路径分开。记录逐样本 CPU 准备、提交/可获得的 GPU 完成时段、上传字节/pass/分配与资源峰值，以及另一窗 owner/scene 响应；GPU 不可测部分具名保留，不能由 CPU/RSS 推导。解析阴影没有离屏缓存就按实际 pass/工作量记账。
- 停止后以计数差证明无新增动画帧/无无关 build、排版、解码或分配；测文字输入与效果同时存在的正常路径。对照若有明显回退，定位额外工作、限制默认效果面积/参数或优化，再说明结论；不用改阈值或降低负载来把红项变绿。
- 同 host 双窗、真实阴影命中负控及新动效共用一套正常消费场景汇合。图像关系验证与结构/owner 读回相互印证；窗口像素证据不称为显示器物理呈现。
- 最终含空格独立包中，一个 UI-only 与一个生成消费者实际构建运行 P1/P2。可导出 adaptive，或让已有导出 UI-only 消费者真正消费相同能力；清单、来源和指纹覆盖最终产物。生成侧原有效证据保留，受本次变更影响的段才重跑。
- 仅在新反例、相关变更及包末汇合时验证。源码定位后连续实施；等待编译/咨询期间推进独立必要工作，确无独立工作再等待。本节已是任务说明，不再增建执行卡或逐轮报告；本页末只写实现、有效证据及真实剩余项，当前状态只更新 ACTIVE。

#### 执行者包末记录（2026-09-27；指导结论见下一节）

**已实现**：A（A1 生成效果整候选拒绝 + 未声明继承/`none`·空清除/合法替换；A3 单一准入定义、非有限/越界/stops 边界具名拒绝、排序前准入、结构签名补效果依赖；A4 由共享常量发布编码/单位/上限/`none`/experimental/后端支持并接入公共客户端解析）；A2 native（阴影按输出范围 ∩ 祖先 clip 判定、本体按自身范围、命中不扩张）；B（动效基础：显式单调时间、补间/弹簧、绑定与取消、仅活动动画申请帧、reduce-motion）；C（`no_effect`/`effect_static`/`animation_active` 三模式量化 + 停止收敛；两消费者 + 同 host 双窗；含空格导出）。

**有效证据**：`cjpm test` 249/249（含新增动效/效果校验/窗口动效单测）、Python 客户端 84 tests、效果门控/命中负控探针 rc=0（`draw_gate/ancestor_clip_intersection/painter_order/hit_bounds_only/opacity_zero_effect_alpha/no_effect_regression/effect_cost` 全 true）、`animation_active` 量化三尺寸 `TEXT_WORK raster_delta=0 upload_delta=0 text_ok=1` 与 `ANIMATION_STOP submitted_frame_delta=0`、真实指针 hover `verify_adaptive_pointer_hover.sh` exit 0（normal 75.7→hover 57.3→pressed 42.5→leave 75.7；框内点击激活/阴影带拒绝）、多窗 `verify_multi_window_response.sh` exit 0（inputs=accepted，关 A 后 B 继续）、含空格导出两消费者构建运行并带指纹。独立验证报告 `.resultverify/P1P2_package_verification_report.md`（任务 14 修复后复验 **VERDICT: PASS**）。

**架构复核（gpt-6-astra 只读）发现并已修复**：① opacity 乘子未覆盖 shadow/gradient → `applyPaintAlphaMultiplier` 增加 `scaleShadowAlpha`/`scaleGradientAlpha`（逐 stop）；② 文字纹理键含 `textAlpha` 致逐帧重排版/重栅格 → 键移除 textAlpha、动态 alpha 改 `paintAlpha` 绘制乘子（raster/upload 增量为 0）；③ 动画终值提交脱节 → `pendingPresentation`/`needsTick` 保证终值提交；④ 暂停/身份退役未闭合 → `needsTick=!paused&&hasActive` + accepted 切换即清理退役绑定；⑤ 弹簧合法域大于稳定域 → `advanceSpring` 按 ω 取有界子步 + 隐式阻尼；⑥ 手写非法效果未贯穿事务 → `effectRejection` + 窗口接受前拒绝；⑦ 效果整数解析溢出 → 累加前判界返回 None；native 阴影门控亦由保守判定改为精确逐次求交（`ancestor_clip_intersection` 探针复核）。

**停机 SIGSEGV（多窗）归因（2026-09-27，任务 18）**：`pkg-verify-multiwindow.log` 末尾 `CJNative Handle signal: 11.` 发生在**所有窗口 `destroy complete` 之后、`GCThreadPool Exit` 之后的主线程**，属仓颉 runtime 停机末段；与本次效果/动效/overlay tracking area 改动**无因果证据**（崩溃版快照尚无 tracking area，含该代码的当前版本亦 40+ 次未复现）。低频非确定性竞态，未强行改代码；建议记入反馈入口并备一次性 `lldb` 抓栈。

**包末独立复验（2026-09-27，零弹窗，任务 17）**：非桌面项全部独立重跑通过（`cjpm test` 249/249、门控探针 rc=0 `opacity_zero_effect_alpha=true`、`animation_active` 三尺寸 `TEXT_WORK raster/upload_delta=0 text_ok=1`、`ANIMATION_STOP submitted_frame_delta=0`、弹簧极端/换规格、手写准入/溢出、A3 边界单测全过）；桌面项（真实指针 hover、同 host 多窗、含空格导出）以实现者 exit 0 证据为准并已只读交叉核对（hover app.log 的 alpha/bounds/click count、多窗 SUMMARY、导出指纹）。**整体 VERDICT: PASS**（报告 `.resultverify/final_package_reverification_task17.md`）。

**真实剩余项**：颜色域仅节点 paint 的 alpha（RGB 插值/几何动画/跨容器转场/玻璃未做）；未基于窗口可见性自动暂停（native 未发布可见性）；减少动效开启态未独立运行；GPU 完成时段不可测（具名保留）；OHOS 用未同步 snapshot（`ohos:unpublished_snapshot`），未实测接受新效果；**桌面项（真实指针 hover、多窗）本轮以实现者 exit 0 证据为准，独立重跑待授权后单次进行**；多窗停机 SIGSEGV 的具体根因待 backtrace。

<a id="p1p2-review-p3-package"></a>
### 第二次指导复核与接续：P1/P2 机制修正 + P3 首个可消费切面

日期：2026-09-27。本次只读核对源码、原任务和两份验证报告，未构建、运行探针或启动桌面窗口。**保留有效交付，整包暂不接受。** 原报告的 PASS 是其实际用例集结果，不能替代下列未覆盖的公开路径。此节是当前第三线完整接续，直接复用既有资产，不另建任务卡。

**已具备的基础：**严格效果 token/数量准入、三态继承清除、精确祖先裁剪、静态文字纹理复用、alpha 补间/弹簧、终值 pending、暂停/关闭与无活动帧收敛均有实现及局部证据。空串 `\e` 两端编解码已对上。249 项测试和原像素、工作量证据按其路径保留；新反例要求由执行者建立，不把本次静态推导写成已实跑。

#### A：必要返工，按机制连续修复

| 项 | 当前源码事实与判别反例 | 实施与闭合要求 |
| --- | --- | --- |
| A1 聚焦文字的 alpha 与资源 | `cjgui_internal_renderer.m` 的 active layout/attribute signature 仍含 textAlpha；`prepareActiveMultilineFallbackRunsForNode` 把它写入颜色并全文 setAttributes，active texture key 又含该 signature。纹理已含 alpha，绘制端再乘一次。静态 glyph 探针零 raster 不能覆盖此路径 | 分清字形/样式本色 alpha 与动态绘制乘子，统一静态及聚焦多行路径的消费规则，保持 style runs。同一聚焦多行正文 1→0.5→1、半透明本色、输入/选区同时变化：像素对照识别双乘，纯动效全属性写/布局/栅格/上传无无关增量；真正文字变化仍更新。与 E 协调相关 native 符号，F 修动效资源消费，不接管 E 的 IME 会话迁移 |
| A2 命名效果与公开观察 | `NamedStyleCatalog.revision()` 未包含 shadow/gradient；观察 tracker 只据 styleRevision 发 STYLES。仅改 blur 或一个 stop，定义变化却漏通知 | 使用共同效果语义覆盖修订计算，包含清除/透明/顺序等已公布规则。真实公共增量客户端观察“仅效果变更”→STYLES→守卫分段读取新定义；无变化不产生通知，不以业务版本增长冒充样式更新 |
| A3 非法命名样式被洗白 | Style 保存 effectRejection，但 named catalog 注册/更新不检查，generated.styleFor 重建未带 base.effectRejection；非法 blur=257 可经命名引用变成合法 None | 在共同注册/更新/解析边界保持明确拒绝与原目录/accepted 原子性。用同一非法定义对照手写、生成、组合；合法恢复、合法显式清除照常可用。修复不能把拒绝重新改成静默归一化 |
| A4 accepted 动效归属 | driver 只认 identityKey→nodeId；同 key/id 从 resource A 直接换为 B、换 action 或节点种类时旧动画仍存活。现测仅先删除再重挂 | 复用 accepted 绑定身份/代际，候选 paint 与接受后存活检查都识别换绑；纯重排/文案变化继续。覆盖活动及已收敛残留绑定、直接同槽换绑、非法候选、旧回调；不以每次 sceneVersion 改变就全取消来规避 |
| A5 公共标量有限性 | ScalarAnimation.finiteOr 仅排 NaN，构造可保存 ±Infinity 目标；tween 运算可输出非有限，spring 防护 converge 又恢复非法 target。opacity clamp 掩盖了通用 API 缺口 | 起点/目标/速度/时间/换规格统一有限性和无效输入策略，异常收敛目标也必须有效。覆盖 NaN、±Inf、极大有限值、时间倒退、长帧与中途改目标；保留当前合法域和稳定性证据，不能仅给 opacity 再加 clamp |
| A6 验收必须能失败 | adaptive 的 `--verify-hit`、generated 的 `--verify-animation` 打印结果后无条件 return 0，导出脚本主要验退出码。hover 脚本另用 pgrep 按同路径取最新 PID，可能误认并行实例 | 自验逐条断言 ready/接受/实际变化/拒绝后稳定/取消结果并传播非零；外层校验完整完成标记，至少一项注入失败必须让整链失败。启动时登记自身 PID/唯一身份，核对后操作和回收；stdout/退出码随本轮产物保存。指纹覆盖实际生成客户端与全部消费者源，利用既有总清单，不另造缺项摘要 |

入口均为现有 `composable_ui_animation.cj`、`composable_ui_window.cj`、`composable_ui_named_style.cj`、`composable_ui_generated.cj`、native renderer 与两消费者/验证脚本。以上为可定位的代码路径，先用最小判别例确认，再一次性修正共同机制、接消费者及相关回归。

#### B：完成原 P2 欠交，避免把按钮演示当公共能力

1. **真实交互状态过渡。** 当前 hover/pressed 直接切 interaction paint，动画另由演示按钮触发；补真实 enter/down/up/leave/cancel 到同一过渡规则。快进快出与中途反向从当前视觉值续接。补原包要求的最小 RGB/alpha 颜色过渡，明确插值颜色空间、透明端点及预乘约定；几何/组透明度/玻璃仍留后续。颜色变更与纯 alpha 的文字工作预算分开，不要求 RGB 换色也套用未经证明的零栅格结论。
2. **共同定义与公开接入。** 生成消费者目前在应用中硬编码 160ms/ease/目标值，不能证明生成发现已完成。注册受限动效/状态规则，由一份定义供手写、组合和生成引用；公开真实支持的属性/引用、参数边界、后端与稳定性。合法外部候选→accepted→真实控件触发→目标/当前/活动状态读取→owner 对应；未知或非法声明具名拒绝保旧。先完成现有 paint 能力的共同契约，不扩成任意脚本时间线。
3. **减少动效与暂停。** 复用现有系统偏好入口及 driver，验证开启/变化时的终值确实提交并停止请求帧。先用可控偏好源覆盖完整窗口链，再补系统来源的实际证据；不要把修改用户全局偏好当默认验收手段。隐藏/最小化的生命周期策略在 C 中与平台事实统一；窗口关闭仍确定取消。

#### C：P3 首个切面——普通控件的系统可用性（独立项同步推进）

复用现有 AX 元素、role/value/action/选区与焦点通知、accepted identity、Tab/reveal、命名主题及 backing-scale 接线。先实现缺的连接与实际缺陷，不重建语义树，也不重复 E 的正文选择/IME。

- 在两个既有消费者中，覆盖按钮、复选框、页签和滚动区域：正常键盘顺序与焦点可见；disabled/隐藏项不被错误激活；被裁剪目标 reveal 后几何/焦点对应；AX 动作与真实点击进入同一 owner。观察值/可用性变化与真实 VoiceOver 导航分别标证据，AX 查询不代替 VoiceOver 实际操作。
- 最小公共平台状态快照接入减少动效、应用选择的系统主题跟随以及窗口可见/最小化状态；仅在变化时更新。明确用户固定主题优先级、关闭/隐藏/恢复的动画时间策略、被拒场景保持；不在每帧重建主题或业务状态。系统强调色有可复用现成入口就接入，否则具名保留为 P3 后续，不为该项拖住本切面。
- 可控 scale 1→2 与 resize 验证焦点框/裁剪/效果边缘/命中几何一致。第二显示器的实际跨屏单列环境未验；不由模拟 scale 宣称跨屏已验。

#### D：响应、退出与交付汇合

- 现有同 host 证据是 pump 前直接 `humanAppendText` 写 owner，再按 sceneVersion 增长计 turn；可证明共同循环有进展，不能证明真实输入排队时延。改为请求带身份从正常事件或公开队列到 owner，再核对该请求对应 accepted 内容；分别记录单调时钟 ready→owner→scene 和精确值。保留一条真实控件输入，确定性注入单列；同一负载比较 no_effect/static/active，不把 0 turn 写成 0ms。
- 旧停机 signal 11 保留为**退出阶段崩溃、归因未定**。日志最后是 GC/销毁不能证明根因在 runtime，也不能证明本次改动无关。优先已有日志/产物/系统崩溃栈；必要时安排一次有界、带符号抓栈的相关运行，并配置后续失败自动留栈，避免几十次盲目开窗重跑。未复现仍保留开放项，不以返回正常的另一次运行覆盖它。
- 当前桌面证据不以“是否另一个模型再跑一次”作为验收标准。已有足够原证直接复用；针对缺失的 hover 完整输出、修复影响和新交互集中跑一轮，记录源版本、日志、退出码与产物。用户当前暂停/接管优先；否则沿既有桌面授权和单操作者规则，不自行增加逐次审批。
- A/B/C 汇合后统一从含空格导出根构建运行两个消费者，实际消费修后的动效和系统可用性。复算源/客户端/资源指纹，原反例稳定且注入失败可被拒；GPU 完成不可得、VoiceOver 尚缺人工证据、物理跨屏和 OHOS snapshot 分别保留，不改名通过。

**推进方式。** 本包由第三线实施，必要返工和 C 的独立工作交错。涉及文字纹理/alpha、accepted 绑定或公共动效语义的不明契约提前咨询 Astra；实现/验证器/平台适配根因给 Sol，型号与档位按用户当前选择。给出最小反例和原始结果，已有裁决直接落实。同 target 构建、共享 native 符号和桌面串行，等待时推进独立模块/消费者；无新变化不重复全套测试，不追加逐轮 Markdown。包末仅更新本页结果与 ACTIVE 的短状态，指导不在本次启动执行任务。

**执行者包末记录（2026-09-27，验证器在其可运行范围内 PASS；指导结论见下一节）**

已实现：**A**（A1 聚焦文字 alpha：active multiline 纹理键纳入 `attributedGeneration`+`styleRunsSignature`、属性改为"框架键 addAttribute + runs 逐段覆盖"、基础色 alpha-neutral；A2 `NamedStyleCatalog.revision()` 纳入共同 effect 语义；A3 命名注册/更新具名拒绝且原子、`styleFor` 携带 `base.effectRejection`；A4 绑定槽位 7 字段 `nodeId/resourceId/nodeKind/actionName/operationActionName/operationResourceId/fieldId`、不以 sceneVersion 当代际；A5 外部非有限/时间倒退拒绝且无副作用、仅内部溢出 fail-closed 收敛；A6 两消费者自验逐条断言 + `exit(1)` 传播 + `--instance-token` 唯一身份 + DONE marker + 注入失败必拒）。**B**（B1 RGBA 颜色通道 + 真实交互 enter/leave/down/up/cancel 经同一 `applyInteractionIntent` 走可中断过渡、非瞬切；B2 框架级 `CjguiGeneratedMotionRegistry` 共同定义、消费者移除本地副本；B3 reduce-motion/暂停终值提交且停帧、平台状态链收敛/恢复/取消）。**C**（平台状态快照 + 消费者级控件可用性脚本）。**D**（带身份请求经队列到 owner、`identity_checked==inputs`、`max_req_scene_ms`；旧停机 signal 11 保留开放项）。

有效证据：`cjpm build` success、`cjpm test` **298/298（0 FAILED）**；A1 离屏 Metal 探针 `EXIT=0 ALL PASS`（`A0.5/A1=0.502`、`run own=0.502`、`own×dyn=0.251`、纯 alpha 零 raster/upload、run-only/content 重建），负控旧双乘实现 `FAILURES=7`；强负控注入 4 处缺陷 → **29 FAILED 精准命中**；含空格导出 v3 六项指纹逐项复算一致、注入必拒、两消费者 marker `failed=0`；Astra 裁决 alpha 合成 `resolve→presentedColor ×nodeOpacity`（0.8/0.75/0.5→0.375，未覆盖→0.4，常量 `presented_paint_alpha_times_node_opacity_once`）。报告 `.resultverify/p1p2_p3_package_verification_task24.md`。

真实剩余项：**桌面项因会话锁定（`CGSSessionScreenIsLocked=true`）本轮 BLOCKED**——真实指针 hover 交互过渡分帧/中途反向、同 host 双窗响应、C 消费者键盘/AX/resize、VoiceOver 实测、可控 scale 1→2、跨屏；脚本已就绪（`verify_adaptive_pointer_hover.sh`、`verify_consumer_control_usability.sh`），解锁后单次复跑即可，不得据模拟 scale 宣称跨屏通过。GPU 完成不可得、OHOS snapshot 未同步分别保留。观察项（非 FAIL）：A6 hover 脚本仍用 `pgrep -f`（但按唯一 token + ps 二次校验）；导出注入路径 DONE 行 `instance_token` 为空。

<a id="p3-consumption-review-package"></a>
### 第三次指导复核与接续：动效正常消费、主题接线与 P3 可用性

日期：2026-09-27。此节取代上节的“只待解锁即可收口”判断，作为第三线完整接续；本次执行结果记在本节末。指导复核时只读当前源码、原始日志和 task24 报告，未构建、重跑探针或操作桌面。**复核时有效实现与证据保留，整包尚在进行中。** 298/298、注入后 29 FAILED、字形 alpha 0.502/0.251、纯 alpha/选区零栅格及导出自验各自成立；它们未覆盖以下正常消费路径。复核只校准既有规划与 ACTIVE，未增建执行卡或报告。

#### 1. 修复共同渲染与动效机制，并接正常窗口

| 已确认缺口 | 实施方法与最小判别闭环 |
| --- | --- |
| 聚焦多行 run 只加不撤销：native `applyActiveComposableTextAttributesForNode` 未移除上次 run 的 background/obliqueness，空 run 直接返回；`drawMultilineNode` 仅画 glyph，另一 prepared 路径的 background 调用不能覆盖它 | 明确基础属性、框架 run 与平台组合属性的所有权，精确撤销旧框架属性后叠加新值，保护其他属性；聚焦多行背景与字形用相同 range/origin 绘制。复用同一离屏实例验证“背景+斜体→普通→空 run”，同时查属性与空格区背景像素，保住已有 alpha/工作量反例。光标/选区等独立装饰是否跟随节点 opacity 明确成契约，不能由字形 alpha 结果代证，也不能直接再乘混有文字本色的 textAlpha。F 主责这些渲染符号，与 E 协调，不接管 IME 会话 |
| 颜色通道正常候选默认不 sync；首次交互才建立 settled(target)，可能瞬切。已有通道又会在普通主题刷新时用旧呈现色覆盖新解析色。现单测先调用 testRefreshInteractionPaint 预热了 normal | 首次 accepted 建立颜色基线；候选颜色目标及绑定变化按 stage/commit/discard 随场景事务发布，拒绝不污染运行通道。正常窗口直接首次 hover、中途 leave、同身份换主题且无新指针事件，分别验证连续过渡、新目标采纳和最终停帧；用当前呈现值续接，不靠测试预热或额外伪造事件 |
| 七字段是绑定内容而非代次：同 key/nodeId 的 A→B→A 会重新匹配最初 token，旧回调可复活 | 保留七字段作变化判据，token 另带窗口实例及 accepted binding epoch；换绑、移除再入场退休旧代，纯重排/文案/paint 保持。覆盖 A→B→A、跨窗口旧 token、拒绝候选、移除重建；不要使用每次 sceneVersion 递增来取消动画 |

以上反例来自源码推导，尚未实跑。实现者先用针对性反例确认，再修共同机制及消费者；已有 alpha 合成裁决和有效回归直接沿用，不重新从头争论公式。

#### 2. 把共同动效定义接成可发现、可提交、可触发的能力

`CjguiGeneratedMotionRegistry` 目前是每次新建的两项私有常量表，没有注册/结构引用；生成校验与 builder 未消费动效声明，应用仍自行选择固定规则。`framework_common_definition` 只比较 capability 字符串和直接查表，不能证明外部候选消费。

把规则值契约和解析下沉通用动效模块，由应用一次注册受限规则，供手写/组合和生成 catalog 引用；生成层负责引用的发现、校验与 accepted 实例绑定。公共提交合法引用后由真实控件触发，公开读取目标/呈现/活动状态并对应 owner；未知引用、非法规格整候选拒绝且旧界面可继续操作。复用现有候选/事件路由，不另造动作管线。仅效果目录变化的 STYLES 公共增量读回随这条链补证。

#### 3. 推进 P3 的实际主题与普通控件消费

- host 已采集平台事实并应用 motionConverges；有效主题目前只在快照/测试中计算，两个消费者仍用固定 palette。补应用可选择的 SystemFollow/FixedLight/FixedDark 到共同样式解析和实际 accepted paint，固定选择优先；相同事实零无关重建，场景拒绝保持在用视觉。受控平台源应经过真实 host→window 链，再补系统来源实证，不以局部 tracker 布尔值代替。
- 在两个已有消费者中真正装入按钮、复选框、页签、裁剪滚动目标，使用已发布 accepted 身份/AX identifier。补正常 Tab 顺序、可见焦点、disabled 不激活、reveal、AX/指针同 owner 与 resize；框架已有身份桥继续复用，缺消费接线由 F 完成。
- 可控 scale 1→2 可利用既有 internal-testing 接缝，验证 accepted 几何/裁剪/命中/效果边缘；无需为测试扩出生产 API。实际跨屏单列硬件待验。VoiceOver 有可用会话时实际导航并留结果，未操作不能写通过。

#### 4. 修判据后集中补一次受影响的桌面链

`verify_consumer_control_usability.sh` 从空 title 启动，直接提交必被业务拒绝；补合法初态。disabled 检查吞掉 type 失败后仅看值未变，须加已启用输入投递正控、真实 disabled 状态及精确目标；resize 后控件 missing 必须失败。Tab 的正尺寸不等于焦点确实可见，分别核对身份顺序与视觉。功能尚未接通、缺 reveal 标识、可控 scale 未用接缝归实施欠项；锁屏/设备缺失归环境，混合结果汇总不能把必需欠项折成整包 exit 0。

hover 判据按 enter/leave 事件边界分段：反向必须发生在原目标尚未到达时，记录前后实际呈现值并验证连续；当前“任意中间值+任意递增+最终1”会把 enter 瞬切、普通 leave 也判通过。多窗身份队列与精确内容核对成果保留，补同负载 no_effect/static/active 的单调 ready→owner→scene 原样本、既定预算判据和一条真实控件输入；21ms 单次最大值不外推为其他负载性能。现有停机 signal 11 继续保留，配置失败自动留栈，不靠反复开窗碰运气。

#### 5. 源清单与最终交付

批量补 38 个脚本是本轮漏项修复，不是去重。当前通用 window 调用 generated 模块的 Registry，静态扫描有 36 个脚本显式编入 window 而未列 generated；`zsh -n` 不能检验编译符号闭包。完成第 2 项的依赖下沉后，将重复核心源集集中为一个可导入的构建清单/助手，探针仅追加各自入口和必要测试开关；导出/指纹复用同一权威源集或明确子集，保留测试/实验的排除规则，避免全目录通配混入入口。验证一个最小非生成探针、一个生成消费者及清单闭包，再随最终含空格导出确认两个消费者消费本包新链。

执行按独立写集交错；构建、咨询等待期间继续未阻塞的注册/主题/脚本工作，同 target 和桌面串行。复杂技术根因咨询 Sol，accepted 事务/代次/属性所有权等契约不明时咨询 Astra，使用用户当前指定型号与档位；已有裁决直接实施。以代码接线和可消费结果推进，受影响测试与集中链通过后停止重复自验，包末更新本节结果及 ACTIVE 短状态。P4 保留在规划中，本接续继续完成 P2/P3 的通用能力。

**本次执行结果（2026-09-27，第三次复核接续）。** 保留上节 298/298、注入 29 FAILED、字形 alpha 0.502/0.251 和纯 alpha 工作量证据；本次未以新探针替代这些原证。聚焦多行先以旧 run 残留及空格背景缺失建立反例，再精确撤销框架 run 属性、保留平台属性，并以相同 range/origin 绘制背景；修后同一实例的“背景+斜体→普通→空 run”属性及像素均通过（`/private/tmp/cjgui-p3-active-multiline.log`）。首次交互颜色基线、候选目标 stage/commit/discard、主题重定向和窗口 token + accepted binding epoch 已接入；A→B→A、跨窗口旧 token、拒绝候选、纯重排连续性及 reduce-motion 终值由受影响单测覆盖。共同动效规则从通用模块注册，生成目录发现并校验引用，合法候选 accepted 后由生成控件实际动作驱动，目标/呈现/活动状态可读；非法引用/规格整候选拒绝并保留旧界面。

**正常消费与交付证据。** 本轮 Cangjie 源码 `cjpm build --skip-script` 成功，`cjpm test --skip-script` **320/320、0 FAILED**；公开生成客户端另有 29/29 测试通过（`/private/tmp/cjgui-p3-build-current.log`、`/private/tmp/cjgui-p3-tests-current.log`、`/private/tmp/cjgui-p3-generated-client-tests.log`）。真实指针 enter/leave/down/up 中途反向与像素/owner 命中通过（`/private/tmp/cjgui-p3-hover-final3.log`）；普通及生成控件的 8 个 Tab 顺序、可见焦点、裁剪 reveal、AX/指针同 owner、enabled 正控与 disabled 负控、resize 几何通过，公开 typed 客户端提交同结构合法候选，独立 ticket 终态 ACCEPTED、版本 1→2，再经真实控件触发动效（`/private/tmp/cjgui-p3-controls-external-final2.log`；该轮 `controls.log` 留原始步骤）。系统/固定主题经正常 host 到 accepted 根节点实际背景，重复事实保持平台快照和背景，候选失败保留旧视觉（`/private/tmp/cjgui-p3-spaced-export-current.log`、`/private/tmp/cjgui-p3-theme-continuity.log`）。可控 scale 1→2 的几何/裁剪/命中/效果边缘通过（`/private/tmp/cjgui-p3-vector-scale2.log`）。同 host 双窗同一 B 队列在 no_effect/static/active 各 120/120 accepted，最大 ready→scene 为 41/43/36ms；附加 active 负载中对 A 的真实 AX 控件动作成功，B 仍 120/120、最大 48ms，均在既定 150ms 预算内（`/private/tmp/cjgui-p3-multi-response-final.log`）。

重复的 standalone 构建源集已由 `native/scripts/lib_cjgui_source_set.sh` 集中，区分基础与生成闭包；非生成 vector 探针、生成 commit 探针和导出分别编译验证。P3 预览在含空格路径 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927103613-77057/CJGUI Framework Preview` 从导出源构建运行 UI-only 与生成消费者，两个 DONE marker 均 `failed=0`，两条注入失败均退出非零；`CONSUMER_FINGERPRINTS.txt` 绑定框架/客户端/消费者源、资源、bundle 与 runner（`/private/tmp/cjgui-p3-spaced-export-latest.log`），native 主文件与导出时工作区逐字节一致。期间并行文本线更新了同一 native 文件的光标几何，当前 SDK 拒绝其中三个调用；已仅按 SDK 声明修正拼写/属性入口，空值属性边界随后由该线修正。320 单测对应本轮 Cangjie 源码；native 空值布局更新由当前 SDK 语法检查与上述消费者从零构建覆盖。更新后的控件桌面复跑发布 descriptor，但另一应用持续抢占前台；第一次在激活门槛 BLOCKED，第二次在输入前失焦、正控未写入（原日志报 FAIL，`/private/tmp/cjgui-p3-controls-current.log`、`/private/tmp/cjgui-p3-controls-latest.log`）。脚本已补输入前/后 exact focus 与前台门槛，失去投递条件归 BLOCKED；改后未再争用桌面，因此该 native 快照的真实键鼠复验仍 **未通过**，先前完整 PASS 只覆盖其对应源码。导出后文本线又修改同一 native 文件的 range-edit pending 处理，含临时归因标记；当前工作区已不同于本 P3 指纹，未将并行实验混入此预览。此为本地 macOS 可消费预览，公共动效能力仍为 experimental；GPU 完成、人工 VoiceOver 导航、物理跨屏、OHOS snapshot 和历史低频停机 signal 11 尚无本轮通过证据，系统强调色仍在 P3 后续范围。

**指导限域验收（2026-09-27）。** 本次只读冻结导出、当前源码与上述原始日志，独立复算导出内 12 项源码/资源/客户端/runner/bundle 指纹全部一致；未重新构建或运行桌面。确认第三次复核的旧 run 撤销/聚焦背景、首次颜色基线与主题目标事务、窗口+绑定 epoch、公开动效引用、主题到 accepted paint、控件判据和共享源清单已有实质修复，接受已留证的 P2/P3 主消费链。10:30 控件全链与 10:36 导出构建/消费者自验分别按各自版本使用，后一导出的新 native 桌面段仍待验。复核时导出范围的仓颉源码无差异，当前 native renderer 与其 sidecar 指纹/静态库已变化；不将旧桌面 PASS 扩大到当前并行输入代码。后续在输入线形成可构建接续点后按影响补一次集成；第三线可规划 P4 前段，沿用原 P4 范围，实际开工仍由用户指派。无需重复已经充分验证的 P2/P3 机制。

### P2：动效与持续帧调度

复用应用循环与交互状态，仅为活动动画请求帧。先交付颜色/透明度等不改布局的状态过渡和一类可中断弹簧值；使用单调时间，明确暂停/长帧处理、当前值改目标、完成与取消的归属。

业务 owner 保持业务真相；动画目标、当前视觉值与完成事实分开。关闭/换绑/候选拒绝不能把旧动画写到新节点；对外可读取必要的目标/呈现状态，不要求每帧向外广播。若随后增加几何动画，命中与公开几何必须一致，不能只移动画面。

验收用连续快速操作、不同帧间隔、隐藏/关闭/重排、系统减少动态效果和同 host 双窗；证明静止后帧请求/资源收敛。布局过渡与跨容器 shared element 等待基础语义稳定后按实际消费扩展。

### P3：普通应用可用性与平台一致性

围绕现有组件完成 VoiceOver、键盘焦点、系统主题/强调色策略和 DPI 的正常应用覆盖。复用已有语义字段，应用仍决定主题是否跟随系统。E 已负责的文字选择/滚轮/指针问题由 E 继续，F 补的是公共平台层与非编辑器组件。

把确实缺的通用能力、已有但未接通、环境未验分开交付。无硬件的跨屏/真机项保留，但不阻塞其他可实现项；能力目录/模板同步已交付范围。若控件本身可读性或焦点反馈有缺陷，直接修复并验证，不等“美化阶段”。

<a id="p3-controls-semantics-accent"></a>

#### F 线下一整包：普通控件语义、焦点反馈与系统强调色（2026-09-27）

**对象与目标。** 下发给左侧「框架渲染线」，目录 `/Users/jiangxuanyang/Desktop/cangjie`。承接 F5/F6/F10：让普通自绘应用的按钮、复选框、页签、树和滚动区域具有一致的系统语义、键盘操作与可见反馈，并接通尚标为 `P3_deferred_system_accent_color` 的公共平台能力。P4 系统窗口材质首包的实现和已有判别证据保留；本包修必要衔接并推进通用能力。E 线继续负责正文/IME 会话与 SourceMap，H 线继续鸿蒙后端；对外部编辑器 Agent 的协作请求交用户转达，不等待已停止的旧编辑器线程。

**复用与已知入口。** 复用 accepted 场景、稳定 semanticId/绑定身份、现有 AX 元素和动作、viewport reveal、命名样式、平台状态快照与动效收敛。当前 native 的 `CJGuiInternalComposableAccessibilityAction` 将元素父节点统一指向 overlay，常见角色按绘制 kind 推导；这能支撑已有按钮/字段，但页签/树的组合语义需按正常消费者验证。`composable_ui_platform_state.cj` 明确尚未接系统强调色。本包从这些接缝补齐，不要求先建独立语义运行时或调试器。

1. **公共控件语义与 accepted 身份。** 根据 Apple 官方控件语义，在共同组件定义中表达必要的角色、标签、父子/逻辑次序、选中/展开/禁用状态；手写、注册组合、生成控件共用。平台投影从 accepted 事实派生，应用不另写一套 AX 名称和业务动作。先打通页签组及滚动中的树，再补所需按钮/复选框衔接。隐藏页不暴露可操作子项；被裁剪或虚拟化的条目按控件语义报告/按需 reveal，保持有界，避免为辅助功能物化整棵大树。重排保留正确身份，换绑/删除后旧 AX 引用不能操作新 target；候选拒绝后旧结构与动作继续可用。控件值和结构变化发对应通知，空闲不重复通知。
2. **普通键盘与焦点反馈。** 正常应用中完成 Tab/Shift-Tab、页签/树适用的方向导航、激活、展开/折叠与 reveal；具体导航和选中策略以组件共同定义为准。disabled 项可被解释但不可错误激活，隐藏页不占键盘顺序。以窗口真实焦点事实驱动画面，不能把编辑器种类或 AXFocused 单个值当焦点证明；焦点标记在浅/深主题、opaque/材质回退、裁剪与 resize 后可读且对应目标。复用 E 的文字输入协议，F 本包限定非正文导航及公共 AX 接缝。
3. **系统强调色共同消费。** 通过窄平台桥把系统强调色解析为明确颜色空间的公共值/修订，并接入既有平台状态与命名样式消费；应用可选择跟随或显式固定，固定样式优先。主题/强调色改变随正常 scene 事务接受，失败保旧；生成与手写控件读到同一有效值，公开发现/观察给出支持范围及实际来源。复用现有可控偏好源测试变更，正常应用再消费实际系统值。仅颜色变化按现有 paint/纹理分工更新，稳定状态无重复 build/栅格/提交。
4. **两消费者贯通。** 在现有 UI-only 与生成消费者中安排小而完整的页签、树/滚动、按钮/复选框场景。生成侧由真实公开客户端提交结构并改状态，键盘、AX 动作与指针进入同一 owner；精确读回动作次数和状态。验证重排、失效引用、禁用、非法候选保旧、主题和窗口大小变化。尝试一段真正的 VoiceOver 导航与动作，记录角色/标签/状态及 owner 结果；AX 查询、工具驱动 VoiceOver、人工体验分别标证据，某种输入环境不可用不阻塞其余实现。材质前台观感在同一消费窗口条件具备时补验，沿用用户系统偏好；仍为减少透明度回退则如实保留该范围。
5. **有界验证与交付。** 新缺陷先用有判别力的最小反例定位，再修负责该能力的框架模块；测语义投影/通知更新量及空闲零工作，在两窗同负载中确认一窗操作后另一窗仍推进。可控 scale/resize 复用既有入口，物理跨屏独立标记。包末只做一次受影响回归与同源含空格双消费者导出，核对所用最终输入指纹；此前效果组/blur/材质的稳定证据按未改范围复用。诊断只补角色/身份/状态/范围和实际计数，不另建庞大工具。

**执行方式。** 先核对实际实现，已接通项直接复用；把实现、正常消费和相关测试连续完成，避免只写状态或循环验收。普通接线直接处理；复杂平台技术咨询 `gpt-6-sol`，公共语义/身份/并发架构不明确时咨询 `gpt-6-astra`，通过 Codex CLI 提交精确源码与反例，已有裁决直接落实。按 AGENTS 协调共享 native 符号、同 target 构建和桌面；等待期间推进独立工作。最终只在本节集中记录交付和真实剩余项，ACTIVE 保持短状态；未授权不 stage/commit/push。

**本包交付与边界（2026-09-27）。** 共同节点现声明页签组/页签、滚动区/树/行、按钮/复选框的角色、标签、逻辑父子、选中/展开/禁用；手写、注册组合与生成节点投影到同一 accepted 身份。macOS AX 从 accepted 场景建立层级和动作，只让当前绑定代次响应；重排保留引用、换绑/删除使旧引用失效，隐藏页不暴露动作，等价重绘不重复通知。生成候选对行状态做准入，拒绝保留旧结构与动作；窗口用 accepted 行身份执行方向键、激活与 reveal，页签焦点/选中及绘制比较也跟随声明状态。正常生成应用曾通过公开客户端把 `controlLeaf` 从未选中提交为选中（accepted 版本 1→2），非法展开候选被拒且版本保持 2；真实 Tab、方向键、Return、AXPress 和指针到达同一 owner。手写应用真实 AX 在两页切换后仅活动页标题 selected=1，隐藏页不可读，按钮/树/复选框都有共同角色。AX 原生重排、换绑、层级、通知与空闲探针 `verify_composable_control_ax_semantics.sh` 通过。

**强调色与正常消费。** 窄 macOS 桥在 AppKit 主线程异步取系统 control accent，按 sRGB8 原子采样；每窗公开 `observed/requested/adopted` 颜色、来源、修订、accepted scene 与交付失败，固定色优先，读取失败保留上次可用色。应用用同一颜色更新具名样式和手写控件，再随正常 scene 接受；生成公共客户端的 `PLATFORM` 增量与并发游标重同步已接通。真实生成应用读到系统 `#0040ddff`，AXPress 控件后固定 `#b02088ff` 于 accepted scene 230，再恢复系统色于 scene 249；1.2 秒空闲观察无新增量、scene/native 提交保持 3→3。手写正常应用的 15 项 `--verify-hit` 中，accepted 按钮两次到达 owner，固定色于 scene 38、跟随系统于 scene 39 被采用，具名样式边框同色。当前系统“减少透明度”开启，沿用 P4 的 `opaque_fallback/reduce_transparency` 材质范围。

**汇合证据。** `cjpm build --skip-script` 成功，CJGUI `cjpm test --skip-script` 356/356、shared core 61/61、公开 Python 客户端 56/56，native AX 探针通过。`verify_multi_window_response.sh` 的无效果/静态组/活动组三腿各 120/120 请求进入 owner 与 accepted，活动负载真实 AX 动作后 B 窗继续推进，关闭 A 后 B 仍接受 60 次；最大请求→scene 延迟分别 60/54/35 ms，AX 活动负载腿为 50 ms。含空格预览 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927193342-3016/CJGUI Framework Preview` 从同源构建运行两消费者，UI-only 15/15、生成 13/13，公开效果/材质客户端及两条注入失败拒绝通过；`CONSUMER_FINGERPRINTS.txt` 记源/产物哈希。独立 `export_fingerprint.py` 在补齐既有材质验证文件清单后核实 96 个输入（86 逐字节一致、10 按设计重写），总 SHA256 `d0c660b25a8cc5e7155a0c471393348da8fc25809aae40bb7d11b8bbfb776f24`。`git diff --check` 通过；CodeLattice 错选子项目、GitNexus 旧索引报 0 变更，影响结论改以源码、构建与上述反例为准。

**前台接续补验（2026-09-27）。** 用户空出桌面后，当前源码的 `verify_consumer_control_usability.sh` 完整 PASS（`/private/tmp/cjgui-consumer-control-usability/20260927194503-29517/controls.log`）：正控真实键入使 enabled title 从空值变为 `X`；Tab 顺序覆盖 14 个不同控件并回到原身份，`effectAnimate` 从裁剪状态 `visible=0` 按需 reveal 到 1；公开生成动效候选由版本 1→2 accepted 后真实控件点击 2 次。AXPress 和指针点击同一提交按钮均进入 owner（版本 2、3、5），提交后的 disabled title 点击/按键不改值；窗口从 840×552 拖到 914×606 后控件 AX 几何仍有效。此前三轮正控前失焦的 BLOCKED 属桌面竞争，现有完整补验取代其验收缺口；本轮自有实例的进程、descriptor 与 socket 已按身份清理，日志保留。

**仍未获通过的证据。** 旧 `verify_two_window_workload.sh` 的 MIDWORK 样本 owner/accepted p95 为 14/29 ms，但请求落入 A 在途排版的覆盖条件及大正文滚动 `scrolled_ok` 失败（`/private/tmp/cjgui-p3-final-two-window.log`），整探针仍为 FAIL；其中同步 barrier 对照另有 owner p95=131 ms，不能统称所有样本均在预算内。F 先定位探针时序与滚动失败的实际归属，再协调涉及 E 在途文本符号的实现，不能仅按“文本负载”转交或放宽判据。已尝试启动真实 VoiceOver 并发送导航键，首次 Quickstart 抢占，无可判定导航/动作，AX 查询不能代替它。物理跨屏、OHOS 平台后端及减少透明度关闭时的真实材质观感未在本包验证。E/H 并行改动保留，未 stage/commit/push。

**本轮指导限域复核（2026-09-27）。** 已读取前台补验日志、失败探针原始样本和对应判据，未构建、运行窗口或复算导出。接受本包已验证的普通控件/强调色及前台消费切面，范围仍绑定上述产物；不将其扩为大正文探针或当前并行工作树全部通过。固定 2/9/15 ms 延迟在 A 实际多为 6–9 ms 的区间仅命中 6/20 次；每条请求的 owner/accepted 均成功，`all_applied=false` 实为复合判据失败。滚动最终 offset=47397、有字形和非零像素，但缺每步位置/最大值/API 状态，尚不能判定触底钳位还是回归。下一包按下方接续解决，保留原 FAIL，不循环重跑挑绿。

### P4：按依赖扩展合成与材质

<a id="p4-front-package"></a>

#### P4 前段：效果组隔离、组透明度与遮罩（2026-09-27，主链已实现，指导复核待收口）

**交付目标。** 普通开发者可把包含文字、图片和控件的子树声明为一个效果组，统一渐隐、遮罩或与背景混合；手写、生成和混合界面消费同一框架定义。macOS 自绘后端完成真实绘制、有界资源及正常应用消费，为后续玻璃建立合成基础。本包覆盖 A–E；背景模糊与系统窗口材质接在下一包。

**接续事实与旧资产。** P2/P3 主消费链已按上文「指导限域验收」接受，其 320/320、公开候选与真实交互、主题和导出证据按原快照复用。当前 native 有 E 线输入改动，不能把旧 PASS 当成整仓现状，也不必等待 E 全部完成才做独立模块。沿用现有组件/布局/场景、accepted 事务、效果输出范围与祖先裁剪、命名样式、动效规则、生成目录及公共客户端、资源预算和统一源清单。已有文字栅格缓存继续承担文字资源职责；本包增加的是通用子树合成目标。

**责任分工。** F 实现通用声明、合成、资源管理、发现与两个消费者；E 继续文字会话、IME、正文范围和编辑器消费；H 继续平台宿主与 Surface 生命周期。共享 native/FFI 段先核对在途写集，由单一写入者集成重叠符号。F 的新契约说明各后端实际支持范围，H snapshot 未接入时明确发布状态；macOS 交付无需等待 H 同步。编辑器无需为本包另造效果实现。

#### A. 固定合成语义，再沿现有场景接线

1. **明确子树边界。** 设计最小公共效果组声明及对应生成词汇，组内包含其背景、子节点、文字装饰和阴影。先按原 painter order 绘入透明目标，再对组结果应用 alpha mask 与组 opacity 各一次，最后按组的 blend mode 合入父目标。首批为 `normal`（source-over）与 `multiply`。嵌套组各自结算，布局、业务身份和原有节点 paint opacity 保持各自语义。
2. **组透明度与节点透明度分开。** 组 opacity 不向每个后代改写 alpha。效果不扩大命中，mask 在本包只影响绘制；透明位置仍按已有几何、enabled 和焦点规则判断交互，公开说明这一点。保持 AX 子树与真实 owner 路由；需要的焦点反馈仍按现有可用性契约消费。
3. **写清 alpha 边界。** 当前 native 多条路径是 straight 片元输出配 `SourceAlpha` 混合，不能把离屏结果直接当同类普通纹理再次相乘。实施前在本节简记“声明颜色→片元输出→目标存储→组采样→父目标混合”的 alpha association、纹理格式和颜色空间，明确转换位置。本包采用与既有 paint 一致的 sRGB 分量运算并公开，不把它称为线性光运算；若实际目标格式含硬件转换，须纳入推导与像素预期。保持现有纯节点路径的颜色结果。
4. **multiply 的背景有确定时点。** 背景是父目标在该组之前已绘制的内容；不包含未来兄弟，也不得对同一 attachment 做未定义的同时读写。隔离组内部从透明背景开始，嵌套边界与最终组混合分别处理。选择符合当前 Metal 管线的有界实现，说明增加的 pass/临时目标。
5. **准入与发布沿 scene 事务。** 手写/命名/生成/组合共用验证；未声明、显式清除、合法替换可区分。非法数值、未知模式、超限或不支持的引用带稳定原因和 path 整候选拒绝。组拓扑进入 accepted 后才对外发布，不能提前污染在用样式、身份或资源绑定。公共 API 标为 experimental。

**实施前的 alpha 与所有权边界。** 现有节点颜色和文字/图片纹理在片元侧是 straight RGBA；`BGRA8Unorm` 附件以 RGB=`SourceAlpha`/`OneMinusSourceAlpha`、A=`One`/`OneMinusSourceAlpha` 混合，透明目标中存下的是预乘 RGB。效果组从透明目标按原节点次序画自己的背景、阴影、文字装饰和后代；组采样得到的预乘 RGB 与 alpha 同乘局部 mask×组 opacity 一次，`normal` 用预乘 source-over（RGB/A=`One`/`OneMinusSourceAlpha`）合回父目标，绝不再次用 `SourceAlpha` 缩放 RGB。设组预乘源为 `S,a`、此前父背景为 `B,b`，`multiply` 的目标为 `S(1-b)+B(1-a)+S·B`，alpha 为 `a+b(1-a)`。采用两次定义良好的固定功能混合：第一遍 RGB 因子 `DestinationColor`/`OneMinusSourceAlpha` 且保留目标 alpha，第二遍 RGB 因子 `OneMinusDestinationAlpha`/`One`、alpha 因子 `One`/`OneMinusSourceAlpha`；两个 draw 相邻且覆盖一致，不在片元中同时采样/写入父 attachment。4× MSAA 在附件样本上混合，组自身 resolve 后的采样差异与 8-bit 中间舍入须以像素探针裁决。目标格式为非 sRGB 的 `BGRA8Unorm`，此包按既有 sRGB 数值分量混合，不声称线性光。场景 accepted 快照持有组声明与内容目标；命令缓冲完成前仍需持有其精确纹理代次，候选失败不得改写旧 accepted 纹理或缓存。

**借鉴依据与适配方式。** [W3C Compositing and Blending](https://www.w3.org/TR/compositing-1/) 用作 isolation、source-over 与 multiply 的语义和独立像素公式依据；只实现本包声明的子集。[Flutter Canvas.saveLayer](https://api.flutter.dev/flutter/dart-ui/Canvas/saveLayer.html) 用作“先合组、再统一施加效果”及离屏成本的参考。将这些语义映射到 CJGUI 已有场景事务和自绘后端；缓存及所有权由 CJGUI 的实际生命周期决定。

#### B. 可消费的 alpha mask 与效果几何

1. 首批 mask 来源限定为**组局部线性 alpha 渐变**：归一化起止坐标、2–4 个有限 stop（position/alpha 均在 0..1），复用现有渐变的排序与有界准入工具。它是透明度遮罩，不读 RGB 亮度。公开说明重复 stop 的规则；端点重合等退化输入具名拒绝，数量检查先于分配。
2. mask 域取组的布局矩形，在组局部坐标中采样，域外 alpha=0；域内投影超出首末 stop 时取端值。mask 对整个组结果生效，因此也可能裁掉域外阴影，这是显式契约。无 mask 时效果输出仍可超出布局矩形。保留后续接资源型 mask 的空间，本包不提前发布未实现来源。
3. 输出范围依据子树实际效果范围、组效果和全部祖先 clip 计算；逻辑点到像素按 backing scale 向外取整，布局/命中范围分别保留。移动、滚动、resize 和 scale 改变时同源更新；空范围不分配目标。嵌套组合与裁剪相交不能退化为包围盒并集。
4. mask 声明、命名样式修订、结构签名、候选绑定及公开发现齐全。纯 mask 参数或组效果变化必须可观察并产生正确画面；复用已有主题与样式发布机制，不在消费者加私有旁路。

#### C. 有界离屏资源、缓存与响应

1. GPU 目标纳入 candidate/accepted/在途提交的明确持有。候选拒绝或被替代只释放自身；GPU 未完成使用的纹理不得提前归池重用。关闭、换代和失败后按原资源生命周期收敛。预算覆盖同时存活的 accepted、candidate、in-flight 和池内缓存，记录 current/peak；像素面积、尺寸乘法、嵌套深度、组数量和总字节在分配前检查，并发布实际限制。预算拒绝保留旧 accepted，随后合法候选可恢复。
2. 组内容缓存按真实子树绘制依赖、绑定、尺寸、scale 和效果定义失效，不能只用全局 sceneVersion。将组内容准备与最终合成分开：仅改组 opacity 应复用组内容；仅改变父背景时，multiply 的源组可复用，但必须重新与当前背景合成。文字纹理沿用现有缓存，不能因整组透明度每帧变化而重新栅格化。
3. 动态目标复用 P2 单调时间、accepted 身份、取消/停止调度。组内实际内容改变可重绘相应目标；光标若位于该组内，本就是内容依赖，不能把“不更新”当优化。普通无组场景保留原路径，静态稳定后零新增帧请求/提交。
4. 仅补定位本机制所需计数：离屏分配/复用、存活/峰值字节、额外 pass、内容重绘及原因、文字 raster/upload。以同内容无组、静态效果组、活动组 opacity 三模式对照；记录冷/热和停止后收敛，使用既有双窗负载与 ready→owner/scene 口径，沿用其 100/150ms 预算。GPU 完成耗时若不可测仍如实列出，资源释放的完成确认必须另外成立。

#### D. 两个正常消费者与公共调用

- **UI-only**：复用 `adaptive_layout_public_consumer`，手写效果组内放重叠卡片、文字/图片及一个真实可交互控件；正常控件切换组 opacity、mask、normal/multiply，移动/滚动/resize 后仍可操作并读回同一 owner。
- **生成消费**：复用 `generated_panel_consumer`，通过公共目录发现和真实外部客户端提交含效果组的结构，等待该 ticket 的 accepted 终态；真实生成控件改变同一框架定义并取色核验。补未知/非法声明拒绝后旧面板继续交互，再提交合法候选恢复；组合组件作为组内内容一起消费。
- 两者使用同一声明和效果参数，不各写一套 shader/规则。公开能力列明模式、mask 来源、颜色/坐标/透明度语义、限制、稳定性与后端范围；观察读回能区分声明与 accepted 事实。最终同源导出同时携带两个消费者。

#### E. 判别验收与交付

下列是本包新机制的判别点，可集中在少量探针与消费者链中完成，不要求每格另写脚本：

| 判别场景 | 必须证明 |
| --- | --- |
| 两个重叠不透明子节点，组 opacity=0.5，再套一组 | 像素符合先合组再透明；把实现改成逐节点乘透明度时必须失败 |
| 半透明彩色源与半透明背景，normal/multiply | 独立标量公式与读回一致，含透明彩色边缘；交换绘制顺序的负控可判别，避免只测全不透明色 |
| mask 的 0/0.5/1，移动、祖先 clip、resize、可控 scale | 渐隐真实存在，坐标与裁剪正确；布局/命中/owner 不被效果错误改变，可控 scale 不冒充跨屏 |
| A accepted→B 准备后注入拒绝→合法 B | A 画面/公开状态保持，B 独有资源归还；合法 B 可恢复，未知模式/畸形参数同样具名拒绝 |
| 受控在途提交中替换/关闭/到达预算 | 未完成资源不提前复用，拒绝与释放可观测，预算总账含所有存活者，最终收敛 |
| 源组不变只改背景、只改 opacity、再改组内容 | multiply 结果跟随背景，源缓存可复用；opacity 不重栅格文字，内容改变真正失效；停止后无持续工作 |
| 两消费者与同 host 双窗 | 手写/公开生成/真实操作同链，另窗响应与身份独立，关闭一窗后另一窗仍可操作 |

像素预期独立于被测 shader/解析器，容差依据格式和采样位置明确给出。优先精确内部点与几何关系，边缘单列；关键错误用有界注入或旧实现证明判据能失败。后台/锁屏可完成逻辑、准入、资源受控探针与构建，真实窗口输入和画面在可用桌面集中完成。

最终运行受影响框架/客户端用例、`cjpm build --skip-script`、正常应用链及含空格导出消费；源清单复用 `lib_cjgui_source_set.sh`，指纹覆盖新增模块、native、资源、客户端、两个消费者和实际产物。在 E 线可构建接续点，对共享 renderer 补一次受影响的文字/交互集成；注明其源码指纹，旧 P2/P3 证据按版本保留。既有 signal 11 若重现自动留栈并分层定位，不靠多次偶然绿色认定修复。

**执行节奏与咨询。** 执行者先读 AGENTS、ACTIVE、本节及直接相关源码；写仓颉前读 `cangjie-coding` 技能。先用当前管线画出 A3 的 alpha/所有权边界，带必要源码向 `gpt-6-astra`（Codex CLI，只读，xhigh）作一次聚焦契约咨询，然后连续实现可消费链；复杂技术故障向 `gpt-6-sol`（同为只读/xhigh）提供复现、假设与结果。已有裁决直接用，普通接线自行完成；Laya 如可用只作辅助判断。遵循 AGENTS 的失败升级阈值，减少在同一猜测上换补丁。编译/咨询等待期间推进独立模块、消费者或判据，同 target 和桌面串行；确无独立工作才等待。验证按影响运行，充分通过后进入下一项；包末只在本节记录结果与证据链接、ACTIVE 写短状态，不追加逐轮长文。完成报告列清新增公共能力、两条真实消费链、性能原样本和实际剩余项。

**P4 前段实施与验收范围（2026-09-27）。** 已接通 experimental `EffectGroup` 的手写/命名/生成/组合共同准入、accepted 事务、公开目录及候选：组内容先隔离绘制，再统一施加局部线性 alpha mask 与组 opacity，以 `normal` 或 `multiply` 合入此前父目标。节点自身 paint opacity、布局、命中和 owner 不随组效果改变。Metal 保留原有 straight 片元绘制；离屏 BGRA8Unorm 目标存预乘结果，组采样使用预乘 source-over，multiply 按上文两遍固定功能混合，未采样正在写入的 attachment。父背景变化重做合成，单改 opacity 复用组内容；内容、尺寸/scale、绑定或声明改变时失效。离屏目标按 accepted/在途代次持有，分配前限制尺寸、深度、组数与总字节，拒绝保留旧画面；GPU 完成前不复用在途纹理。公共说明及后端支持范围见 `runtime/cjgui/README.md`。Astra 的契约咨询、Sol 的资源/交互根因咨询均为只读建议，以下运行结果独立验收。

**判别证据。** 当前共享源码 `cjpm build --skip-script` 成功，`cjpm test --skip-script` **327/327**、0 FAILED（`/private/tmp/cjgui-p4-cjpm-build-post-activation.log`、`/private/tmp/cjgui-p4-cjpm-test-post-activation.log`）。独立 native 像素探针通过重叠组/嵌套、半透明 normal/multiply、反序负控、mask/域外/移动/clip/resize、可控 2×→1×→2×（mask 逻辑中点颜色一致）、拒绝恢复与无组路径（`/private/tmp/cjgui-p4-native-scale-final2.log`）；受控在途 A=230400 B=230400 字节，B 独立分配时存活 460800，frame 5 的 GPU fence 后降至 230400，最终 frame 6 为 0，本次 GPU 完成耗时 157µs，峰值 460800。缓存对照：只改 opacity 时分配 17→17、重绘 17→17、合成 43→44；改内容时分配/重绘 17→18；multiply 仅改父背景时分配/重绘 19→19、合成 49→53。与 E 线共享 renderer 的受影响文字属性/空布局和交互 native 探针重新通过（`/private/tmp/cjgui-p4-shared-text-final.log`、`/private/tmp/cjgui-p4-shared-interaction-final.log`）；交互探针明确启用 reduce-motion 以检查即时像素，正常动效另由仓颉测试覆盖。

**正常消费与导出。** `adaptive_layout_public_consumer` 的真实桌面控件已改变组 opacity/mask/multiply，移动、滚动、resize 后仍读回同一 owner；`generated_panel_consumer` 通过公共客户端发现 `effectGroup`，提交合法候选获得独立 ticket `ACCEPTED`、版本 2，未知模式/越界参数具名拒绝且旧控件保留，再次合法提交恢复。最终导出的正常生成应用再经 CUA 真实点击“切换/清除/恢复生成效果组”，依次读到 `70,multiply,…`、`none`、`50,normal,…` 的已应用声明；非法效果动作保留 `versionBefore=2/versionAfter=2` 和旧控件身份，随后合法恢复，进程 exit 0（`/private/tmp/cjgui-p4-generated-final.aR0LiY/generated-ui.log`）。这些动作证明控件与声明/候选链，合成颜色数值仍以独立 native 像素探针为准。两个消费者从最终含空格路径 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927124314-72719/CJGUI Framework Preview` 构建、运行、自验；注入失败均 exit 1，源/native/客户端/资源及 bundle 指纹见该目录 `CONSUMER_FINGERPRINTS.txt` 与 `/private/tmp/cjgui-p4-spaced-export-post-activation.log`，公开调用见 `/private/tmp/cjgui-spaced-export/gen-external-client-20260927124314-72719.log`。导出源集统一由 `native/scripts/lib_cjgui_source_set.sh` 提供，含 E 新增 `range_text.cj`/`text_session.cj`；最终预览与本次框架/native/两消费者源码对应，多窗受控实例是另行编译的同源码应用。

**同 host 响应对照。** 相同 B 队列各 120 个带身份请求全部 accepted、身份/内容核对 120/120，关 A 后 B 再接受 61/61/60；100/150ms 预算内。原始每请求时钟样本在 `/private/tmp/cjgui-multi-window-response/20260927122507-36943/{no_effect,static,active}.response.log`，脚本汇总在 `/private/tmp/cjgui-p4-multiwindow-current.log`。下表顺序为最小/中位/p95/最大，单位 ms；这是这一次机器与负载的观测，不外推为所有应用时延。

| 模式 | ready→owner | ready→scene | A 动效活跃 turn | A 效果组活跃 turn |
| --- | --- | --- | ---: | ---: |
| 无组 | 16/16/17/21 | 32/33/34/40 | 0 | 0 |
| 静态组 | 16/16/17/23 | 33/33/34/40 | 0 | 0 |
| 活动组 | 15/16/17/18 | 31/33/34/36 | 119 | 120 |

**真实控件与共享框架修复。** 上表三模式为外部驱动待验前的可比负载；另起最终 native/应用源码的受控活动腿，应用 `activateWindow()` 在 AppKit 主线程带回 A，读回 `accepted/key/main/app_active=true`，CUA 对其公开 AX“动效过渡”按钮执行一次点击。动作日志仅一条，前/后 B 都在第 36 个已接受请求且 A 未关闭，随后 B 到 120/120 accepted/身份核对，关 A 后再接受 15 笔；该腿 ready→owner 最小/中位/p95/最大为 14/24/33/36ms，ready→scene 为 31/49/66/66ms，均在 100/150ms 预算内，进程 exit 0（`/private/tmp/cjgui-p4-activate.VZKwza/active-real-control.log`）。原先直接在 Cangjie 工作线程执行 AppKit `makeKeyAndOrderFront:` 曾 SIGTRAP（`.ips` incident `35AD4D4D-31A2-489D-A17F-937AC60D730E`）；native 激活和相邻状态查询现在先派发主线程，在主线程核对 session/window/关闭状态，受控同三窗复验无新崩溃。此处点击是系统辅助功能真实控件动作，不宣称物理鼠标或人工 VoiceOver 验收。背景模糊、窗口材质与 H 平台实现仍属后续，不以本包 macOS 结果代替。

<a id="p4-front-review"></a>

#### P4 前段指导复核：保留主链，补三项机制（2026-09-27）

**复核范围与结论。** 本次只读当前源码、冻结导出与原始日志，独立复算导出内 13 项指纹全部一致；框架/native/两消费者的对应源码与该导出一致。按每次真实提交请求重算四组各 120 条样本，最小/中位/p95/最大与上表及真实 AX 腿全部一致。327/327、像素和释放数字已核对原日志，本次未重新构建、运行探针或操作桌面。normal/multiply 的预乘公式、mask/裁剪、公开候选在 native 接受后提交、消费者控制和 AppKit 激活修复均有有效交付，**不接受“只剩后段和平台待验”的整包结论**：以下三项由当前调用路径确认，具体失败表现仍需执行者建立运行反例。

1. **提交前失败后，离屏目标被误当成已绘制。** `CjguiEncodeEffectGroupContents` 在 encoder 结束时即置 `needsRedraw=NO`，后续主场景 MSAA 分配、encoder 创建或编码失败仍可在 command buffer 提交前返回。`scheduleAcceptedScenePresent` 直接重绘 accepted 节点，不经过候选拒绝清理；文字变化或 resize 分配的新目标因此可能在重试时命中缓存、跳过从未提交的内容。把编码中、已提交、GPU 失败的状态分开：成功提交才发布可复用内容，所有提交前失败统一恢复 dirty/撤销该次准备。**反例**走正常 accepted 重绘：改组内内容或 resize→离屏编码后注入主 encoder 失败→同条件重试，断言重新绘制且像素等于无失败对照。现有候选拒绝反例继续保留。
2. **缓存命中帧的 GPU 在途资源可从预算账上提前消失。** completion 捕获的 `[view.composableNodes copy]` 是浅拷贝；另一个强持有数组仅含本帧 redrawn 目标。正常 accepted 重绘会原地更换节点的 `effectTarget`，缓存表也随后更换；缓存命中帧使用的旧目标包装对象可提前离开弱 ledger。底层 Metal 纹理可能仍被命令缓冲持有，**这证明的是预算漏计风险，不是已证 GPU 悬空**。每次提交应持有实际读取/写入的精确目标代次集合，覆盖缓存命中，直到该提交完成。**反例**为 A 首次完成→命中 A 的第二帧保持在途→原地更新生成 C，旧目标字节在第二帧 fence 前必须在账、不得绕过总预算，之后释放收敛；原有 A/B 首次重绘探针不能替代这一腿。
3. **既有节点动画被隐式改为整组动画。** `animateNodeOpacity` 公开约定只改节点 paint；`applyPaintAlphaMultiplier` 遇到 `effectGroup` 却改乘组 opacity，并保持本节点 paint 不变。同身份节点仅新增一个 opacity=1 的组声明，就会把已有动画扩大到所有后代，违背本包“节点与组分开”的契约。保留节点 paint 通道，给组 opacity 明确的独立目标/通道，复用原单调时钟、accepted 绑定、重定向和停止机制。**反例**为父节点 paint 动画在添加/清除中性组前后均不改子节点；另证组动画统一作用于子树、可中断、拒绝不污染、停止后无持续提交。当前双窗 `tickEffectGroupOpacity` 每 turn 在 1/0.55 之间改声明，证实的是频繁组更新负载；旁边的 P3 节点动画不抵账新的组动画语义。

**接续与验收取舍。** 先连续完成上述机制修正及针对性反例，再对受影响路径作一次汇合。最终导出 UI-only 的现有 `--verify-hit` 主要断言旧 P2/P3 行为，只观察到初始组声明；把其真实组 opacity/mask/multiply 切换及组内 owner 读回纳入现有消费链即可。生成外部客户端的固定合法/非法 payload 是有效协议测试，不因其使用常量而要求再造通用生成器；命名样式共同准入沿已有机制复用，按实际改动补覆盖。正常绘制、像素公式和未受影响的 P2/P3 无需重做。背景采样契约等独立准备可交错推进，依赖资源/动画语义的后段实现接在三项修正之后；仍由当前执行线实施，本次指导只更新本节与 ACTIVE，未启动任务或修改生产代码。

**执行接续（2026-09-27）。** 离屏组目标直到命令缓冲真正提交才发布可复用状态；编码后、提交前的主 encoder 故障保持 accepted 版本与旧画面，重试重新编码。正常 accepted 重绘的注入腿中失败状态 9、提交帧 2→2→3、离屏 pass 1→2→3，重试和无失败对照同为 BGRA `[204,51,26,255]`。每帧提交持有实际读取/写入的目标代次，缓存命中也在内；A 命中帧仍在途时原地换 C，总账 230400→288000 字节，fence 后为 57600，未把旧目标提前移出弱 ledger。`animateNodeOpacity` 继续只影响节点 paint；独立 `animateEffectGroupOpacity` 复用时钟、accepted token、重定向和停止机制。新增/清除中性组不扩大节点动画作用域，组动画对子树一次施加，并覆盖拒绝、打断和停机反例。原生反例及旧 normal/multiply/mask 探针同在 `/private/tmp/cjgui-effect-group/composable_effect_group_probe.log`；仓颉动画和公共准入见 `cjpm test --skip-script` **330/330**、0 FAILED（`/private/tmp/cjgui-p4-blur-test3.log`）。

**两消费者与当前构建。** UI-only 正常 `--verify-hit` 的 14 项断言包含组 opacity、mask、normal/multiply、blur 0/8 控件动作及同一组内 owner 的 accepted 读回；生成应用的真实外部客户端先发现公共契约，再对 normal/multiply 和 blur on/off 候选等独立 ticket 等待 ACCEPTED，非法半径/fallback 具名拒绝且旧场景和 title/notes owner 保留。含空格导出 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927141258-7349/CJGUI Framework Preview` 内两者均构建运行，两个注入失败均 exit 1，外部客户端 PASS；源/native/资源/客户端/两 bundle 的 14 项指纹见其中 `CONSUMER_FINGERPRINTS.txt`，已独立逐项复算一致，原始执行见 `/private/tmp/cjgui-p4-blur-spaced-export-final.log`。导出内框架和消费者源码与此次对应工作树文件逐项相同；产物按导出内源码构建，不能将并行 E/H 的整个脏工作区称作冻结快照。最终 `cjpm build --skip-script` 成功（`/private/tmp/cjgui-p4-final-build.log`）；共享 renderer 的聚焦多行背景/撤销与交互受影响探针通过（`/private/tmp/cjgui-p4-blur-shared-text.log`、`/private/tmp/cjgui-p4-blur-shared-interaction.log`）。原 P4 两消费者、AX 动作和四组 120 请求时延原证按当时版本保留，不重写成这次测量。

#### P4 后段：应用内部背景模糊与 macOS 系统窗口材质首片

本前段通过后，再接应用内部背景模糊：明确采样已有背景的区域/时点、遮挡/裁剪、预算、缓存失效及失败回退。

背景缓存必须跟随被采样区域的真实变化；不能只比较玻璃组件自己，也不能无条件随全局 sceneVersion 重算。前景光标与被采样背景中的光标分开处理。最后按平台能力接系统窗口材质；不支持时使用声明允许的降级并可被发现，不宣称视觉等价。H 只在自己的接续包实现所需后端，并复用公共描述。

**macOS 首片契约与消费（2026-09-27）。** 公共 `EffectGroup` 增加 0..16 逻辑点的 `backdropBlurRadiusPoints`，0 关闭，唯一 fallback 为 `unblurred`；生成 wire 保留旧前缀，选用 `;blur=8,unblurred` 后缀。命名样式、手写应用、生成目录和外部候选共享准入；每个场景限一个根层模糊组，嵌套或第二组拒绝。采样在该组 painter 顺序之前，输出 ROI 为组布局矩形与 clip 交集，向外取 `ceil(3σ)` halo，σ=`radiusPoints × backingScale / 2`，前序已接受内容按同一 clear/MSAA 重放进私有目标，横/纵 Gaussian 滤波后与组内容一次合成，再施加组 opacity/mask。缓存键跟随此前影响采样的节点、资源、文字装饰、clear、drawable/scale/MSAA 与核；组自身内容和后序普通兄弟不触发重滤。只重用 GPU 成功完成的背景目标；前景/背景/中间纹理及在途旧代同受 96 MiB 预算。透明 clear、容量/分配或 blur 编码失败以新命令缓冲绘制未模糊的 accepted 组，不把未完成结果当成功。公共边界与 OHOS 未发布能力见 `runtime/cjgui/README.md`。

**判别与原始性能。** 同一原生探针用独立离散 Gaussian 标量 oracle 检查 1× 颜色过渡边缘、裁剪、前序背景红→绿和 clear 变化；静态 cold/hot 的前序重放/横/纵 pass 为 1→1、缓存命中 0→2，前序背景变更使 pass 1→2，单改组内容/opacity 或后序兄弟保持 2。提交前故障状态 9、帧 19→19→20，重试前序 pass 5→6→7，重试与对照像素均为 `[23,189,8,255]`；滤波编码故障和预算不足分别以状态 0 接受未模糊帧、fallback +1，后者存活 83911680 字节且不超总预算。背景缓存命中在途换代账 38400→404160 字节，fence 后 38400。半径 4 的单次 cold/hot CPU present 原样本为 **7595/7013 µs**，只代表这次机器与场景；原 P4 四组各 120 请求时延见前段表，不把单帧差额外推为收益。完整原始计数与像素结果在 `/private/tmp/cjgui-effect-group/composable_effect_group_probe.log`。正常 UI-only 控件事件自验与导出生成客户端均消费 blur 开/关及 accepted/owner；本次 UI-only 未新增物理键鼠腿。系统窗口材质、OHOS 绘制快照、透明根窗口上的 blur 与人工 VoiceOver/物理跨屏仍待对应接续。

<a id="p4-blur-review"></a>

#### P4 接续指导复核：保留主链，修两个机制接缝（2026-09-27）

**本次复核范围。** 只读源码与上述原始日志，独立复算最终导出的 14 项指纹全部一致，导出中框架/native/两消费者的 28 个对应源码文件与当前工作树相同；未重新构建、运行探针或操作桌面。提交前失败保持 dirty、缓存命中帧精确持有旧代两项旧问题已由实现和原始反例闭合。背景重放、Gaussian 像素对照、背景改色失效、预算与失败回退的已测路径成立，330/330 和消费者结果按原运行范围保留。以下两项是源码审阅确认的遗漏，**实际失败像素尚待执行者建立针对性反例**，不能据现有全绿报告宣称它们已覆盖。

1. **组动画到完全不透明的终值会失效。** `composable_ui_window.cj` 的 `applyPaintAlphaMultiplier` 在 `multiplier >= 1 && effectGroupOpacity >= 1` 时直接返回原样式。但前者是节点乘子，后者是组的绝对呈现值。声明组 opacity=0.4、无节点动画、组动画到 1.0 时，driver 可以报告终值 1，投影却保留 0.4。早退应判断是否确实没有样式变化，不能把绝对值 1 当作“无覆盖”。补 0.4→1 的零时长和正常补间终值反例，对照 driver、accepted 样式及停止后零提交；保留已有节点/组独立通道，不另造调度器。
2. **背景缓存没有覆盖全部真实绘制依赖。** `CjguiBackdropSignature` 使用 scaleX/Y 计算采样范围，但未把它们或实际核参数纳入键；全视口 ROI、drawable 不变、逻辑视口与 scale 反向变化时，截满的 ROI/halo 边界可不变，实际前序像素和 Gaussian σ 已变。另遗漏 `textCaretIsDeclared`，而 painter 由它选择正文色或系统强调色，普通效果内容键已包含此字段。用可控同 drawable 的 1×→2× 对照，以及正文/资源/光标矩形不变而颜色来源切换的对照，验证缓存失效后与强制重算像素相等。实现时核对并尽量复用同一份节点绘制依赖，环境键显式包含缩放与核配置，避免继续维护两份易漂移的依赖清单；不扩入 E 的输入会话工作。

**下一切面：让实际降级可读。** 当前公共读回可确认 accepted 请求 `blur=8,unblurred`，实际预算/透明根/编码失败后的回退只在 testing 计数中可见。它不否定本轮原生回退像素证据，也不把 accepted 声明当实际绘制结果。接续增加窄的效果呈现/降级投影，复用窗口观察通道，按 accepted 身份与提交代次发布实际模式及原因；失败或旧完成不得覆盖新状态，状态变化进入既有增量观察。用正常消费者或公开客户端证明请求仍为 blur 而实际为 unblurred、恢复后状态正确。该项是接续的公共消费完善，不追溯要求本轮已有协议测试证明它。

**实施与验证取舍。** 当前执行线连续完成两个机制修正及公开降级切面，独立工作交错推进；系统窗口材质的契约/API 调研可并行，平台实现沿原 P4 后段接续。只为上述反例和受影响消费路径补验证，包末做一次同源汇合；未改变的 normal/multiply、旧资源持有和旧性能样本复用。保持现有文档和短状态，避免再开逐轮台账；本次指导只更新本节与 ACTIVE，未改生产代码或启动执行任务。

**接续实施结果（2026-09-27）。** 组 opacity 声明 0.4→动画终值 1 的零时长及正常补间先得 2 个 RED，再按组的绝对终值与原样式是否相等决定投影早退；driver、accepted 投影、停止后零持续提交与节点/组独立通道通过。背景键提取共用节点绘制依赖，纳入实际 drawable/scale/MSAA、光标颜色来源 `textCaretIsDeclared` 与编码所用 Gaussian σ/halo。同 drawable 改 1×→2× 的 RED 陈旧像素 `[51,41,20,255]` 对照重算 `[25,22,149,255]`，修后 pass 1→2 且实际像素等于重算；同光标矩形改颜色来源的 RED `[175,34,0,255]` 对照 `[5,10,242,255]`，修后 pass 2→3 且实际等于重算。未触及 IME 会话。

**公开状态与真实消费。** native 在命令缓冲 commit 后发布提交帧的 `blurred/unblurred/none`、稳定降级原因、scene/frame 与 pending/completed 状态；提交前失败保留旧回执，旧 GPU 完成受 session+scene+frame 守卫。原生反例记录编码失败仍以帧 23 提交 `unblurred/encode_failed`，旧帧 2 的完成不能覆盖新帧 3。窗口 `GET_WINDOW_PROGRESS` 和生成 `EFFECTS` 快照/增量复用同一读回。真实生成客户端首次发现透明布局效果组的视觉中性快路径让 accepted `blur=8` 却 native `none`；新增正常窗口 RED（335 项中 1 失败）后在框架中修正，335/335 转绿。正常生成应用经公开候选保持 accepted `blur=8,unblurred`，透明根提交帧 5 被读为 `unblurred/non_opaque_clear/succeeded`，恢复帧 7 为 `blurred`；公开客户端同时读到 EFFECTS 增量和组内控件 owner。UI-only 14 项与生成消费者从同一个含空格导出构建运行、两侧注入失败均拒绝，外部候选和上述回退/恢复在导出副本再通过。导出独立核对为 94 项（84 项逐字节同源、10 项声明的路径改写），聚合 sha256 `7262ebc176cb8b6255f489c8012022c66f5be1d513599bf43140f8a93c273526`；`cjpm build --skip-script`、CJGUI 335/335、shared core 60/60、Python 51 项与原生效果探针通过。证据见 `/private/tmp/cjgui-p4-blur-review-*` 和导出 `CONSUMER_FINGERPRINTS.txt`。半径 4 同一原生探针的本次 cold/hot CPU present 原数为 **8989/8161 µs**；与前包 7595/7013 µs 属单次不同运行，不推断性能回归或收益。系统窗口材质、OHOS 绘制快照、透明根实际模糊、人工 VoiceOver/物理跨屏留后续接续；本包未 stage/commit/push。

**本接续包指导验收（2026-09-27）。** 本次限域核对三项修复的源码、定向反例和实际公开消费日志，未发现阻断本包收口的问题：组 opacity 的绝对终值与节点乘子已分开；背景键与编码共用实际 scale/核及节点绘制依赖；效果回执在 commit 后发布，完成只在同 session/scene/frame 上更新。原始 RED→GREEN、帧 5 回退/帧 7 恢复和旧完成被忽略均有对应日志。335/335 来自 `cjgui-p4-blur-review-neutral-group-green.log`，较早名为 `test-final` 的日志是 334/334；60/60 和 Python 51 项已核原日志。独立复算 15:42:59 导出内 94 项全部一致，聚合指纹仍为 `7262ebc176cb8b6255f489c8012022c66f5be1d513599bf43140f8a93c273526`。本次没有重新构建、运行探针或操作桌面。**接受本包已验证快照范围内的交付，沿上述系统窗口材质等剩余范围接续，不重复开启这三项修复。** 当前工作树的 `text_session.cj` 与 `composable_ui_window.cj` 已有后续输入线变化（窗口差异为选区事件与会话选区同步），不将此次结果延伸为新增输入代码或整个当前工作树的验收；本次核对的 native、生成层和公共客户端仍与该导出相同。

<a id="p4-window-material-current"></a>

#### F 线当前接续：系统窗口内容背景材质（首个消费包，2026-09-27）

执行对象是左侧 **「框架渲染线」**，工作目录 `/Users/jiangxuanyang/Desktop/cangjie`；这是 macOS P4 接续，鸿蒙 TCP 入口归 H 线，文本会话/IME 归 E 线。15:16 的 `/private/tmp/cjgui-p4-blur-review-build.log` 属已恢复的文本会话误写事件；当前 `text_session.cj` 已有 mirror/ticket/acknowledge/校准 API，16:57 的 `cjgui-p4-window-material-root-test3.log` 为 **341/341、0 ERROR/FAILED**。之后窗口主题事务仍在修改，341 只证明该次源码测试，不是最终整包验收，也不再将旧 API 缺失列为当前阻断。

已有系统材质适配、`windowBackground` 生成声明/公开状态、UI-only/生成消费者及验收入口正在接线，直接完成已有实现，不从头再建一套。当前汇合重点是**主题值与材质请求随同一场景提交**：候选冻结、accepted 后发布，拒绝/失败保持先前已接受事实。公共值说明请求、实际安装/回退、原因与身份；系统宿主已安装、GPU 提交完成和桌面实际合成是不同证据。

接着完成两个正常消费者的开启/切换/清除/回退/恢复，生成侧经公开客户端提交并读回；核对主题、减少透明度、焦点/resize、多窗隔离与关闭释放，以及原控件/文本 owner 的连续性。复用已接受的组效果、模糊和缓存证据，只补本次受影响检查；最终对汇合源码做一次串行构建/相关回归、实际消费和含空格同源导出。原生适配与主题事务的咨询结论直接用于实施；有新证据再追问。等待构建或咨询时推进独立消费接线，确无安全独立工作才等待。只在本节汇总结果并更新 ACTIVE，保持 E/H 写集。

**实施边界与事务。** 公共 `opaque/system_content_area` 是窗口内容区背景请求，和应用内部效果组的 backdrop blur 分开；生成根属性只在既有授权、候选验证及 scene accept 后生效。macOS 窄适配在透明 `NSWindow` 内容宿主内固定放置不透明回退层、`NSVisualEffectView` 和透明 Metal 层，材质采用 `UnderWindowBackground`、`BehindWindow`、`FollowsWindowActiveState`；原生对象及枚举不出公共接口。窗口级候选把材质模式与有效浅/深主题一起冻结、stage、接受或回滚；pending/失败不改旧状态，交互帧复用已接受主题。主题只赋给材质 view 的 `NSAppearance`，浅/深回退层与 Metal clear 同色；减少透明度时发布 `opaque_fallback/reduce_transparency`，恢复后沿本窗刷新提交，不把已编码等同已提交。依据本机 macOS SDK，并对照 Apple 的 [UnderWindowBackground](https://developer.apple.com/documentation/appkit/nsvisualeffectview/material-swift.enum/underwindowbackground?changes=latest_major)、[BehindWindow](https://developer.apple.com/documentation/appkit/nsvisualeffectview/blendingmode-swift.enum/behindwindow)、[减少透明度偏好](https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducetransparency?language=objc) 与 [NSAppearance](https://developer.apple.com/documentation/appkit/nsappearance)。公共发现说明 macOS experimental 与 OHOS snapshot 未发布；窗口与生成 `EFFECTS` 增量分别读到接受请求、后端、实际模式、稳定原因、主题、身份、scene/frame、请求/环境/观察代次及完成态，桌面视觉结果明确为 `unobserved`。

**判别与真实消费。** 原生探针 `/private/tmp/cjgui-window-material-native.MYghyp/run.log` 验证 stage 不改变 live host、非法方案拒绝、同节点主题变更请求代次 +1、提交前失败回滚主题/host/scene/frame、减少透明度回退和同 scene 恢复、resize 宿主同尺寸、双窗隔离及关闭两 session 后 content host 释放；透明与不透明 clear 通道均有 native 像素回读。CPU 单次 present 原样本按时间顺序为 **12749、1250、1069、1840、3791、1321 µs**（首启、主题、切 opaque、恢复系统、减少透明度中换主题、恢复）；空闲两次观察帧 **1→1**，不从不同场景的单帧推断加速。正常 UI-only 从已接受按钮执行 opaque→system→opaque→clear→system，6/6，当前系统偏好下实际为 `opaque_fallback/reduce_transparency`，accepted 控件和 owner 保持；生成应用在材质请求下随宿主浅/深/系统主题分别提交，材质读回 `light/dark/light`、帧 `3/4/6`。公开客户端发现根属性与平台范围，按授权写标题并从 owner 读回，再完成 system→opaque→省略清除→非法候选拒绝→system，最后读到 `opaque_fallback`、scheme `light` 与 `EFFECTS` 增量。正常系统偏好未被探针修改；因此真实应用证明回退和请求恢复，**不声称在本机减少透明度开启时已视觉恢复系统材质**，恢复为 `system_host_installed` 的判别由原生受控环境完成。 另用桌面 UI 操作最终导出的生成应用：点击备注字段后粘贴“材质输入验证”，AX 中手写字段和生成字段都读到该值、共享版本 0→1；实际点击材质切换/清除/恢复按钮，结构 v1→v2→v3→v4，值仍在两个字段中，最后关闭本轮实例并核对 PID 消失。普通逐键物理输入未在此腿证明，`typeText` 本次未产生文字变化，成功路径是粘贴。

**汇合与剩余证据。** `cjpm build --skip-script`、CJGUI **342/342**、shared core **61/61**、Python 客户端 **53/53**，对应 `/private/tmp/cjgui-p4-window-material-final-{build,test}.log` 与 `...-shared-test.log`。首个导出运行发现客户端把省略属性的空字符串误按 `None` 比较，修正后定向公共客户端 PASS，最终 `/private/tmp/cjgui-p4-window-material-spaced-export-final.log` 全链 PASS；含空格导出位于 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927171118-16504/CJGUI Framework Preview`，`CONSUMER_FINGERPRINTS.txt` 记录框架/客户端/两 bundle 的 16 项指纹，导出的 16 个 framework Cangjie 源文件与两消费者 7 个源文件同当前工作树逐字节一致，native 两处差异只是重新构建的库及其指纹。两消费者的注入失败均非零退出。原生探针试图激活窗口，但原始状态 `active=0/key=0/app_active=0`；其捕获图只证明宿主配置与当时非前台画面。最终导出应用的桌面画面和真实点击/粘贴有 UI 观察，受系统减少透明度限制仍**不能证明前台 WindowServer 的系统材质视觉**；逐键物理输入和 VoiceOver 尚未通过。透明根上的应用内部 backdrop blur、OHOS 后端绘制快照仍按各自接续范围保留；本包未 stage/commit/push。

**系统材质首包指导限域复核（2026-09-27）。** 已核候选材质/主题与 scene 配对、present 失败回滚、实际模式/回退原因分层、宿主释放和生成非法候选保旧的直接源码及既有日志，未发现需阻断本包的衔接问题；接受上述已验证快照范围内的交付。此次未重跑测试、桌面或重新计算导出指纹。`system_host_installed` 仅表示系统宿主安装；原生探针 inactive 的捕获及 UI-only 的 `theme=not_consumed` 不代表两消费者完整的前台系统主题视觉验收，生成侧已有 scheme/frame 读回仍保留其适用域。下一包按 [P3 普通控件语义、焦点与系统强调色](#p3-controls-semantics-accent)推进，材质实现直接复用，真实系统视觉及未执行的人机验收保持原边界。

<a id="f-diagnostics-and-regression"></a>
### F 线开发者诊断首个消费包：已交付，证据边界见下

**目标与归属。** 执行对象「框架渲染线」，目录 `/Users/jiangxuanyang/Desktop/cangjie`。承接 F7/F9/F10，同时处理上方两窗探针与 VoiceOver 的欠项；P1–P4 已验能力复用。诊断供普通开发者查看真实布局/裁剪/效果和工作量，默认隐藏，保持应用简洁。正文会话、IME、SourceMap 仍归 E，鸿蒙适配归 H；共享 native 的重叠符号先协调，外部编辑器 Agent 的必要交接由用户转达，不等待已停止的旧线程。

**复用入口。** `composable_ui_window.cj` 的 `acceptedSceneDump/acceptedNodeBounds` 已读 accepted 身份与布局框；`windowProjection()` 已含 accepted/submitted 版本、提交/完成帧、部分 CPU/GPU 时长和复用计数。native 效果/encoder/present 细分统计主要在测试入口。缺的是普通消费者可开启的统一诊断切面，不另造 UI 树、计数来源或调度器。本包没有测量依据去扩张 display-list、局部重绘或异步排版重构。

1. **两窗失败作两项区分。** 保留旧延迟采样的 FAIL，将请求入场、命中目标在途阶段、owner/scene 成功及预算分别记账。用已有阶段观察或最小测试闸门确定在途投递；受控暂停只证明交错，真实时延仍在不加闸门的同负载测量，不能混入等待时间或降低原预算换绿。滚动补原序列及从已知头部开始的对照：每步 before/after/max offset、API 返回、accepted 身份/范围和目标标记可见性，区分合法触底、非边界停滞/倒退与统计读取失败。正文字符串含标记加任意非零 alpha 不能证明对应标记已进视口。夹具问题修夹具，生产缺陷修负责模块；没有可追溯前后对照时不称既有故障或 P3 回归。诊断功能交付不能抵消原失败未解决。
2. **有界、同版本的只读快照。** 从已有 accepted 场景派生窗口/绑定身份、layout bounds、有效祖先裁剪、效果输出和采样范围；资源/帧统计沿已有入口汇合。明确字段属于 accepted、最近刷新、实际提交还是异步完成，分别标身份/时间；缺失或 GPU 不可测保留 unavailable，不写 0。build/layout/prepare/submit 与 raster/upload、效果 pass/缓存/活资源/在途字节按真实可用范围发布，嵌套耗时不重复相加。按可见节点或显式上限读取并给截断标记，不扫描全文、复制正文或同步等待 GPU；默认关闭，按需或状态变化采样。
3. **同快照的可关闭边界叠加。** 正常窗口可显示布局、裁剪、效果输出/采样框及选定 accepted 身份。复用当前绘制链，选择不改变业务布局、命中、Tab/AX 次序和 owner 的实现位置；诊断不被自身背景模糊或效果缓存再次采样，亦不维护第二份几何。当前全帧绘制如实标注，不命名成局部重绘。滚动、resize、重排和拒绝候选时对应实际在用场景；关闭后正常画面恢复且空闲不持续提交。
4. **正常消费与 VoiceOver。** UI-only、生成消费者均经公共框架入口启用/关闭诊断；生成候选从真实客户端进入 accepted 后，读回同一节点身份、边界和工作量。用裁剪/越界阴影及一次拒绝候选证明诊断反映在用场景，开关不改变业务内容或操作结果，双窗不串值，关闭重开不复活旧身份。沿已有桌面授权完成一次 VoiceOver 首次引导处理，再导航页签/树/按钮并激活动作，记录朗读/选中/owner；恢复先前辅助功能状态。环境仍确实阻断时留具体证据，继续独立诊断交付，不把 AX 查询改名为 VoiceOver 验收，也不重测全部已过键鼠矩阵。
5. **验证、交付与咨询。** 记录诊断开/关的 CPU/资源额外成本、采样上限及停止后零工作。旧缺陷最小反例→机制修复→受影响回归；包末一次串行构建、相关检查与含空格双消费者导出，公共入口随包交付。复杂技术用 `gpt-6-sol`；accepted/提交快照一致性、资源寿命或架构方案未定用 `gpt-6-astra`，按当前可用次高档聚焦只读咨询。等待期间推进不改在编译输入的独立模块/消费接线，完成链路才更新本页和 ACTIVE，过程输出留日志。保留 E/H 改动，未经要求不 stage/commit/push。

**本包结果（2026-09-27，F 线）。**

- 两窗原始 FAIL 保留于 `/private/tmp/cjgui-p3-final-two-window.log`：延迟 2/9/15 ms 的 20 笔中仅 6 笔实际在 A 同步段投递，旧判据将投递阶段不匹配与请求交付失败混在一起；旧滚动日志末值 47397，缺少足够逐步数据来证明旧检查起点或精确首因。修正探针采用 1 ms 早期投递并逐笔确认在途；从已知头部滚动，testing-only native 入口读 offset、最大值可用性、可见 glyph 范围与版本。`/private/tmp/cjgui-f-two-window-corrected-run.log` 的 20 次尝试全部在途且 owner/accepted 成功，无挑选或重试；由 producerPost 计时，未插入保持 A 的等待闸门，owner p95 7 ms、accepted 观察上界 p95 24 ms，原 100/150 ms 预算未改。本结果只覆盖早期在途，不能声称旧 early/middle/late 三相位均通过，也不能将 14/29→7/24 解释为性能优化。head 0→mid step 77–79→tail step 157，共 158 步单调；这些步的 max=-1（未知），另一个边界腿确认 `47397→47397` 合法钳位且尾标记可见，`passed=true`。新探针的在途投递、从头滚动与触底判别成立；保留旧 FAIL，不将其精确根因扩大为本次已证事实。测试中的“CJGUI 调度 B”固定 620×440 点、虚拟列表固定 8×26 点；2×截图下的下半部留白来自该视口。
- 公共 experimental `diagnosticSnapshot` 返回当前 accepted 窗口/节点身份、布局、有效裁剪、声明效果范围，以及按提交场景/帧匹配的 native 输出和实际 backdrop 采样范围；accepted、submitted、completed 与最近刷新耗时分别标明，缺失的 raster/upload/effect pass/cache hit/in-flight 计数为 -1。读回不复制正文或同步等待 GPU；每页最多 256 个可见节点，下一索引和截断位支持同 session/accepted 版本分页，原场景准入上限为 1024 节点。独立 AppKit 诊断层在 Metal 和多行正文之上绘制布局、祖先裁剪、效果输出/采样与选中身份；默认隐藏、无命中/焦点/AX 元素，关闭和失效时撤销；采样框只在同代实际 blurred 提交时显示。此方案由只读 `gpt-6-astra` xhigh 聚焦咨询后按现有资源/线程归属实施，咨询不是验收证据。
- UI-only 正常应用经公开入口开启/关闭，scroll 令 accepted 16→17，非法候选保留 17；生成应用与真实公开 Python 客户端使候选 `ACCEPTED`、场景 3→5、native output/sample 均可用，再以非法 blend 得 `REJECTED` 且场景不变。两者开启叠加不增加 Metal 提交，资源字节不变，关闭后 draw/submission 不再增长；真实双窗 session 隔离和一窗 resize 640→710 点后仅该窗可见节点 62→48 已验，叠加期间 AXPress 与指针分别使同 owner 动作 0→1→2。截图 `/private/tmp/cjgui-f-overlay-two-live.png`，正常应用日志 `/private/tmp/cjgui-f-ui-diagnostic-final.log`、`/private/tmp/cjgui-f-gen-diagnostic-final-app.log`，客户端日志 `/private/tmp/cjgui-f-gen-diagnostic-final-client.log`。
- 最终含空格同源导出中的原始成本：UI-only 单次快照 630/869 µs（开关前/后样本），24 次读取 20311/14509/关闭后 13192 µs，live/cache 7680000/7680000 B 不变，开关提交 20→20；生成应用单次 371/320 µs，24 次 5531/15667/关闭后 5590 µs，live/cache 804000/804000 B 不变，开关提交 3→3。数值是当轮原始 CPU 读时，不作为跨场景吞吐提升结论；空闲 4 轮后 draw 与提交均不增长。框架 `cjpm test` 359/359、`cjpm build --skip-script`、native clang 语法、脚本语法及 `git diff --check` 通过；359 项全测先于最后一行 native-only 采样门控，该行另经 clang 与最终同源应用实跑覆盖。最终导出 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927205749-62399/CJGUI Framework Preview/CONSUMER_FINGERPRINTS.txt` 标记 `v9`，两消费者构建运行、生成公开诊断/效果/材质客户端及注入失败拒绝均通过；框架 source/native SHA-256 分别为 `62bc693520e2f9ac159e94729303a7c83bcdd7e504ee462e3cae17ed2847cd37` / `35a72e3bbe130c44a90fcc54dec914f0d659bfe21a1c05f84a4003e11332b243`。静态 CodeLattice 路由未识别此多项目根、GitNexus 新符号为 UNKNOWN，以源码调用、构建、真实应用/客户端和 native 检查补证。
- VoiceOver 原先为关；首次启动出现 Quickstart，用户随后协助开启且系统进程存在。尝试 VO 键导航后没有可归因的旁白光标、朗读或旁白发起的动作证据，故 **VoiceOver 导航/激活仍未通过**；独立 AXPress/指针结果不可替代它。已恢复先前关闭状态。后续保留真实旁白动作和当前不可测的细分 GPU/资源统计，不将它们记为本包通过。E 正文/IME、H 平台后端的并行改动均保留，未 stage/commit/push。

**指导限域复核（2026-09-27）。** 抽查窗口诊断入口、native 同场景/帧门控及独立叠加层，并复算两窗原始样本：每页/裁剪链/身份长度有界，同 session 与 accepted 版本可校验；叠加无命中、焦点或 AX 元素，独立于效果采样，失效/关闭后撤销。正常消费日志支持开关不增加 Metal 提交和效果资源。按上述范围接受本包，校准两窗投递覆盖与最大 offset 可用性表述；本次未构建、测试或操作桌面。VoiceOver 和未发布计数仍待验，旧日志保留。

<a id="f-png-transfer-next"></a>
### F 线下一包：PNG 剪贴板与拖放的公共消费

**目标、范围与取舍。** F7 已有可消费诊断，不继续扩成完整调试器；接续 F8 的首个真实格式，服务普通应用的图片粘贴与拖入。目录 `/Users/jiangxuanyang/Desktop/cangjie`，执行对象为框架渲染线 F。E 继续负责编辑器正文/IME/Markdown 与附件持久化，H 继续鸿蒙后端及生成式消费；本包交付通用交换机制和两个正常消费者，不以 E 完成接入为前置。文件 URL、文件 promise、HTML/RTF 和其他图片编码留在后续范围。

**已有资产与借鉴。** `shared_operation_core/src/shared_operation_transfer.cj`、`composable_ui_window.cj` 的 declaration/provider/event 已支持 accepted 身份路由、owner/CAS 与有界文本；native 的 `CjguiPasteboardTypeForDataTransferFormat` 仅将 text/plain 映射到系统字符串，其余格式走私有 UTI，`CjguiReadComposableDataTransferItem` 一律 UTF-8 解码，因此标准 PNG 二进制不能直接消费。复用这些声明、授权、事件归属和既有图片加载/缓存/引用机制。macOS 格式及拖放会话按 Apple 的 [NSPasteboardTypePNG](https://developer.apple.com/documentation/appkit/nspasteboard/pasteboardtype/png?language=objc) 与 [NSDraggingDestination](https://developer.apple.com/documentation/appkit/nsdraggingdestination) 适配；系统负责拖放追踪，CJGUI 负责 accepted 目标、数据寿命和 owner 事务。借鉴分层与平台服务，不复制另一套组件树或在产品写原生补丁。

**A．二进制值契约与准入。** 扩展现有 transfer 表示，使文本与 PNG 二进制可区分，保留旧文本消费者的兼容路径。平台 MIME/UTI 映射必须互通标准 PNG，真实二进制不能经 NSString 解码或冒充结构化文本。定义不可变 payload/受控资源引用、数据格式、编码字节数与内容摘要；引用须有明确所有者和释放点，不公开原生指针。按既有预算体系明确发布每项字节、图片尺寸/像素、解码资源、排队总字节与在途数量上限，乘法/加法先判溢出。先检查可得元数据，在框架复制/排队/解码增长前准入；若平台取数本身先物化全部数据，单列其内存与时延限制，不能把读后拒绝说成读前有界。PNG 签名、截断、畸形尺寸和解码失败均具名拒绝并保留旧图；使用既有解码服务，不新写 PNG 解码器。

**B．平台交换到原 owner 的完整接线。** 接通显式复制/粘贴与 copy 语义拖放，格式选择确定；预览和悬停只检查能力/目标，不触发业务写入或反复解码。用户完成动作后，由框架捕获一份有界不可变数据并经同一 owner 接受/拒绝，成功动作恰好推进一次业务版本。异步准备/图片加载继续复用已有资源路径，绑定窗口/session、目标语义身份与绑定代次；关闭、禁用、删除或同 key 换绑后旧结果不得应用，无关场景刷新不误取消仍有效的目标。失败、取消、替换、源窗先关闭及目标关窗均释放本轮临时资源；accepted 图片与在途解码/GPU 使用按既有持有规则存活。仅图片数据才进入图片路径，外部来源元数据不构成授权。若需临时文件适配现有图片入口，由框架管理唯一目录与租约，不能把产品临时路径约定当公共契约。

**C．手写/生成共用定义与正常应用证据。** 在现有 UI-only 与生成消费者各增加简洁的图片接收/预览区，使用同一公共组件/声明与领域导入操作。共同能力只定义一次；生成目录如实发现可用格式、目标与预算，候选复用既有接受事务。外部系统通过原有授权操作引用应用已拥有的资源，得到与人相同的校验和 owner 结果；生成声明本身不读取系统剪贴板或任意本地路径。

一次连续验收：标准 PNG 来源→真实 Cmd+V→owner 摘要/版本与可见图片→复制并真实拖入另一消费者→重排目标后继续接收→非法/超预算/过期目标保留旧图→取消/关闭回收。至少一个输入由独立标准 pasteboard 生产者提供、无 CJGUI 私有元数据，避免只证明自家私有格式互通；PNG 原字节用含零字节/非 UTF-8 序列的夹具逐字节或哈希核对，解码结果用尺寸及判别像素核对。拖放必须有真实系统 down/move/up 及接收端操作回执，直接调 handler 或公开写入单列。测试只使用自有图片/实例；剪贴板按 changeCount 保护，仅在本轮写入仍为最新时恢复原内容，他方新内容保留。

**D．机制反例、成本和同源交付。** 必要反例覆盖标准 UTI 对照、字节损坏/超限、同 key 换绑迟到结果、源/目标关闭、取消与重复回调；每类检查 owner/accepted/临时资源的前后值。复用有界诊断记录取数、复制、解码、owner 接受与 scene 呈现的阶段成本；小图、接近已发布上限、超限三档分别报告，接近上限导入期间另一正常窗口的公开操作仍可服务，沿原 100/150 ms owner/scene 预算判断，明确载荷/计时起点与冷/热范围。系统取数若不可抢占，指出阻塞区间并缩小已发布支持预算或升级方案，不用事后取消冒充提前避免分配。空闲不新增轮询/提交，缓存/队列/临时资源按上限和生命周期收敛。

按改动范围运行旧文本/结构化传输回归及新反例，包末做一次框架构建、受影响测试和含空格同源导出双消费者真实链；无改动的 P1–P4 与诊断基线直接复用。VoiceOver 保持待验，只有新增可区分证据/环境条件时才续查，不反复切系统设置。二进制所有权、异步接受或跨窗口事务方案未明时提前用 `gpt-6-astra` 只读咨询；复杂平台实现用 `gpt-6-sol`，按可用次高档，沿 AGENTS 的失败升级规则，Laya 仅辅助。等待编译/咨询期间推进独立任务，同 target 构建和桌面操作串行。只在本节集中写实现与证据、ACTIVE 写短状态；保留 E/H 写集，未经要求不 stage/commit/push。

## 5. 不把“技术清单”误当交付目标

- **优先完整消费链。** 阴影、动画、无障碍分别是不同完整包；每包有真实普通应用和公共消费结果，不按每个函数/文档拆成一轮。
- **优化由实测选择。** 已有文字 tiling/缓存无需重建；普通 GUI 的资源缓存不能替代编辑器的范围存储/增量解析；后台布局、atlas、LOD、partial present 都要先证明瓶颈和语义可接受性。
- **框架完备性按使用面讨论。** 本表不是“所有现代框架特性都必须齐全”的清单，也不以控件数或阶段数计算百分比。每次接受注明平台、输入方式、负载、调用来源与尚未验证范围。

## 6. 三线共享代码与交付方式

1. **主责随问题层级走。** E 发现框架问题，E 可在 CJGUI 修复并带回独立框架用例/消费；F 不重复接管。H 的平台问题在后端修，共同 contract 的修改与其 macOS 消费一并说明。主责转移时在原任务交接，不让两边都等待“对方会做”。
2. **共享文件需要协调写集。** 三线可能同时涉及 `composable_ui.cj`、`composable_ui_window.cj`、`composable_ui_generated.cj`、`runtime_renderer_session.cj`、`native/cjgui_internal_renderer.m`。F 起步先核对 E/H 正在修改的符号；重叠段由一名执行者负责集成，其他线先做独立模块/消费者。独立目录不能证明共享核心没有冲突。
3. **共享构建与桌面串行。** 同一 cjpm target 由执行者协调 build/test 顺序；桌面同一时刻一个操作者。等待期间推进有用的独立工作；确无独立工作时用等待工具，避免循环查状态、重复测试或写进度文档填时间。
4. **阶段证据集中更新。** 复用未受影响基线；有代码变更、失败或新疑点才重跑相关检查，包末一次汇合验证。本文更新能力状态和证据链接即可，不追加逐轮长日志。第一包直接使用本文 P1，不再复制成一套执行卡。
5. **执行对象由用户选择。** 当前只完成规划与开工依据；收到第三线实施指令后，在 ACTIVE 写入执行对象和当前 P 包。后续包沿本表接续，保持既有 E/H 工作；咨询、升级与仓库操作沿 [AGENTS](../../AGENTS.md)。

## 7. 直接相关入口

- 方向与验收：[项目方向](../core/GUI_PROJECT_DIRECTION.md)、[共同信息与生成架构](../core/AI_NATIVE_UI_SEMANTICS.md)、[完整性标准](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)。
- 样式/场景：[composable_ui.cj](../../runtime/cjgui/src/composable_ui.cj)、[named style](../../runtime/cjgui/src/composable_ui_named_style.cj)、[generated](../../runtime/cjgui/src/composable_ui_generated.cj)。
- 窗口/后端：[composable_ui_window.cj](../../runtime/cjgui/src/composable_ui_window.cj)、[macOS renderer](../../runtime/cjgui/native/cjgui_internal_renderer.m)。
- 消费和已知范围：[runtime README](../../runtime/cjgui/README.md)、[设计资产导航](DESIGN_INTENT_INDEX.md)。

读取入口按当前 P 包选择，不要求执行者通读所有历史文档。本表基于源码与既有证据的规划，不把新增规划条目记作已实现。
