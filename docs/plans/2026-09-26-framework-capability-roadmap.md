# CJGUI 框架能力缺口与三线推进表

基线：2026-09-26。用途：分清实际欠缺、实施归属和依赖，让编辑器、鸿蒙与第三条通用框架线并行推进。本文是规划清单；当前执行对象、开工/暂停及阶段结果仍只由 [ACTIVE_DIRECTION](../../runtime/cjgui/ACTIVE_DIRECTION.md) 指向，不另建逐轮台账。

**咨询规则（2026-10-08）：**旧阶段的默认/强制模型路由已撤销；现行授权与问题升级统一见 [AGENTS](../../AGENTS.md#independent-model-consultation)。历史咨询事实、答复和验证结果保留，不构成重新调用授权。

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
| E1 | 组合终态、同身份草稿恢复/取回与切文档已消费；source迟到取消仍有一处门控缺口 | 主链已验、定向接续 / **E** | source16/16、visual25/25完整owner保留；补B基点过期后旧A CANCEL零恢复副作用，见[当前E接续](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#editor-text-position-next-20260929>)，不重跑整套IME |
| E2 | 字素边界、bidi视觉—逻辑位置、行尾affinity与公共导航/扩选 | 当前E新能力 / **E** | 复用系统分段与accepted排版；source/visual同版映射、普通第二消费者接同一能力。光标实钟消费已验，复杂文字按真实反例补公共契约，不自建shaping引擎 |
| E3 | 编辑器公开生成、同一真实模型v1→v2物理重排、活草稿与人接续 | 本轮目标已消费 / **E** | 原始模型events及20/20记录，accepted顺序与AX几何反转、非法保旧、正文精确、撤销来源往返；无相关变更不重跑模型链，不等同所有生成交错全覆盖 |
| E4 | 大文档有界窗口已有；普通小文档inline预算与生产失败回退仍需接通 | 部分 / **E** | 固定lease/每轮一步/同内核尾复用原证保留；小文档不豁免投影额度，旧scanner退役；尾checkpoint重基、GB编码覆盖及完整响应后续。通用viewport/光标/滚动组件修框架，Markdown/存储修产品 |
| E5 | 富文本样式 run、内联内容的测量/命中/布局接缝由真实编辑需求检验 | 部分 / **E** | 现有 style runs 复用；tokenize、Markdown、公式语义和脚注属于产品。需要公共 inline box 时再按真实用例增加，而非把完整排版出版系统塞进框架 |
| E6 | 固定快照租约、撤权/关闭/重装与第二消费者公开生命周期 | 已有真实socket原证 / **E牵头shared core** | 多轮旧凭证有界记账、cleanup_pending拒绝重装、A→revoke→close→grantB与重发布保留；E1 core95/95，容量8的淘汰边界如实发布，无相关改动不重验 |
| H1 | surface 身份、原生引用、停止/重开与迟到回调 | 模拟器已交付 / **H** | 真实引用、在途卸载、原票停止/ACK、全零与同 PID 新实例已有证据；新增资源继续遵守同一仲裁，物理设备性能单列 |
| H2 | 系统文字/选区/组合输入、范围会话及编辑器平台消费 | 基础字段双域已消费；编辑器范围会话/几何待接，marked/cancel待验 / **H** | 设置/thermo草稿、选区、外部校准和续写原证保留；[Pharos真实源码编辑闭环](2026-09-26-harmonyos-executor-handoff.md#h-pharos-product-validation-next)已规划、未启动，复用主树契约并补H adapter，不等待E全部完成；marked/cancel仅按已测SDK/镜像/输入法记录未观测边界 |
| H3 | 裁剪像素/命中、独立消费者与 normal/verify 同源交付 | 模拟器已交付，新增能力继续按包量测 / **H** | 实际像素、裁剪与命中负控及双域同源 HAP 原证复用；各阶段累计计数/TCP 往返不等于逐请求渲染性能 |
| H4 | 共享 region、生成候选接受事务与真实控件消费 | 双 normal HAP 已交付 / **H** | 设置/thermo 的外部提交→画面→系统输入/动作→owner，重排/拒绝保旧及同源指纹已验；模型与脚本候选分列 |
| H5 | 共享图片资源在鸿蒙的加载、绘制和生命周期 | 双 normal HAP 已消费，观察记录回收已修 / **H** | [图片结果](2026-09-26-harmonyos-executor-handoff.md#h-image-resource-next)及[触摸包 A](2026-09-26-harmonyos-executor-handoff.md#h-touch-scroll-next)：异步 PNG、fit/fill、缓存/交错/停止与退役观察表收敛按原证保留；SDK 临时内存/物理性能另列，不重复重开图片包 |
| H6 | 触摸滚动、点击仲裁、焦点 reveal 与可中断惯性 | 原触摸包模拟器已验；惯性 r10 部分实现、共同机制未收口 / **H** | [当前复核与实施](2026-09-26-harmonyos-executor-handoff.md#h-inertial-scroll-review-20260929)：修 H Node ABI/冻结绑定，接共同窗口及生成策略、活动/请求/accepted 确认、固定截止积分与 split 自身修订；受影响测试通过后双 normal HAP 汇合，原触摸/图片证据复用；回弹与嵌套后续 |

E 的具体执行入口：[Pharos Mark 三处接缝与文字能力接续](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#editor-text-position-next-20260929>)。H 的具体执行入口：[当前快照接线与惯性滚动包](2026-09-26-harmonyos-executor-handoff.md#h-inertial-scroll-next)。本表归属这些能力，不重复下发其正在进行的补丁。

### F 第三条通用框架线承接

| ID | 能力与当前缺口 | 状态 / 实施包 | 可验收交付 |
| --- | --- | --- | --- |
| F1 | 效果输出范围/采样范围的公共内部契约；矩形/圆角矩形阴影；线性渐变 | macOS 共同定义及正常消费已交付 / **P1** | 严格拒绝、继承清除、裁剪、命名修订、聚焦文字与公共消费证据按各已验证快照复用；其他后端不由此自动覆盖 |
| F2 | 帧时钟、可中断补间/弹簧、交互状态过渡、停止后休眠 | macOS 共同动效及位置呈现事务已限域消费 / **P2/F11** | 候选只确认自身 mutation，通道重建按真实 accepted checkpoint 接续；自然20样本及空闲停帧已验。具体通道覆盖见[复核](#f-position-motion-acceptance-review)，未声明属性后续 |
| F3 | 通用效果分组、alpha mask、组透明度与受支持的混合模式 | macOS 三项复核机制与两消费者汇合已通过 / **P4 前段** | normal/multiply、mask、提交前失败重试、缓存命中在途代次、独立节点/组动效及公开消费均有判别证据；不扩称所有模式或 H 后端 |
| F4 | 背景模糊/材质与窗口级系统材质适配 | macOS 内部背景模糊与系统内容背景材质首片已消费 / **P4 后段** | 内部 blur 有采样/缓存/预算/回退；系统材质有窗口宿主、主题事务与公开实际状态，OHOS 后端和前台系统视觉另验 |
| F5 | VoiceOver 实际操作、通用焦点可见性/键盘消费与系统主题/减少动态效果策略 | macOS 控件/AX/键盘已有消费；F5 真实 VO 链未闭合，接续标准 AX 接线与可达性 | [正常手写/生成消费任务](#f-accessibility-consumption-next)：导航、角色/状态、动作→同 owner、重排及通知接续；AX查询与普通CGEvent不替代VoiceOver，复用accepted语义及已有系统输入代理 |
| F6 | 多显示器不同 scale、运行中缩放的真实覆盖；新效果的边缘抗锯齿一致性 | macOS 同版几何、双消费者受控 scale、正常 resize 与最终前台输入已交付；物理跨屏待验 | [本包结果](#f-scale-consumption-next)：当前/提交事实、失败恢复、2×→1×→2× 像素/命中/成本；真实跨显示器单列 |
| F7 | 开发者可用的布局/裁剪/效果边界叠加，以及分阶段帧成本汇总 | macOS 首个公共诊断切面与双消费者已交付 / **F 诊断包** | [本包结果](#f-diagnostics-and-regression)含有界同版本快照、可关闭叠加和原始开关成本；未提供的细分指标标 unavailable，全帧绘制不称为局部重绘 |
| F8 | 剪贴板/拖放的图片、文件或富文本格式扩展 | PNG、Finder 单文件粘贴/真拖入与精确回执已由两消费者消费 / **F 文件首片** | [本包接续结果](#f-file-png-receipt-review)含特殊文件、读中变化、会话身份和有界结算反例；通用文件管理、富文本和 E 插图语义后续 |
| F9 | 通用重绘/合成复用、效果离屏缓存与预算、实际功耗/峰值资源诊断 | 稀疏复用、native 提交边界与公共队列闸内 ready 已观测 / **F** | [局部刷新原证](#f-local-refresh-next)和[提交接续](#f-file-png-receipt-review)保留自然 CPU 交叠 0/60；区分 post/公共队列 ready/owner/accepted、commit 调用前后及 GPU host 回调；峰值资源与功耗仍待单列 |
| F10 | 新能力的公共目录、手写/生成一致性、模板与独立包消费 | 持续要求 / **每个 P 包** | 新能力共同定义一次，生成描述可发现并严格校验；不支持的平台明确能力状态；导出后两个独立消费场景接通，不只在开发仓探针里存在 |
| F11 | 节点级亚点平移及一致的坐标变换 | **macOS 机制和冻结导出前台消费限域收口** | [原可平移容器证据](#f-translation-containers-bounded-text-review)与[位置呈现复核](#f-position-motion-acceptance-review)：待决确认/联合准入/退役/活动单行已修，CGEvent活动帧输入和精确owner成立；同帧AX框/光标偏移/选区不扩称范围矩形oracle。候选窗实体视觉、H/任意仿射另验 |

**暂不列成基础完备性的硬缺口：**竖排/ruby、出版级多栏脚注、游戏后处理、压感笔/触觉、九宫格图片、径向/锥形渐变和全套描边/混合模式。分别属于后续应用需求候选；开包前确认现有实现与实际消费需求。编辑器若出现明确需求可提前提取其中一项。partial present 也需先验证后端能力及收益，不能由其他 API 的功能直接推定 Metal 当前路径可用。

<a id="joint-operation-gap-review-20260928"></a>
### 编辑器反馈的缺口校准与接续（2026-09-28）

本次为当前源码及既有证据的只读复核，未构建或操作桌面。按可执行工作归并，本清单中**至少六组需新增或接通的通用能力/接缝**：E6 公共固定快照租约、E1 组合生命周期到 owner 的接缝、F11 节点亚点平移，以及已下发的 H6 触摸仲裁、F8 文件 PNG、F9 真实提交阶段观测。后三项直接沿原包推进。复杂文字、富文本和有界响应已有基础，仍可能由真实反例引出公共修复，不能将“待验”折算为整套引擎缺失。

| 反馈项 | 核实后的归属与处理 |
| --- | --- |
| 撤销来源 | Pharos `HistoryEntry` 已存 origin/requestId/viewId，界面只显示“撤销”；E 增加下一笔 undo/redo 的 owner 摘要及共同 UI/公开投影。未知历史来源如实显示未知，无需新增渲染 API |
| 固定快照 token | E6。expectedVersion 冲突后整体重取可防混页，但不能保证编辑期间仍能跨请求读取旧版本；不可与内部 DocumentSnapshot 租约或生成结构快照游标混称 |
| 多文档 list/open | PharosWorkspace 已能打开/枚举/关闭，公开域仍绑定当前 service；E 接通工作区公共操作。CJGUI 文本文档集合不承担产品文件工作区。先核对同版本文档切换后旧 resource=1 请求的目标身份 |
| 组合态 × Agent | 不是只缺验收：owner 保护实现已有，正常 bridge 未调用 beginComposition，框架会话目前依靠 `composition_base_stale` 防旧。E 补公共生命周期接缝、产品 owner 仲裁及实际交错，保留安全拒绝兜底，不按键码/日志轮询加保护 |
| 编辑器活草稿重排、真实模型生成 | macOS 框架重排与编辑器 Luna 公开生成均有旧证；编辑器当前 D 两棵树换了 key 且提交后才输入，未覆盖活草稿同 key 重排。补模型生成→真实控件→owner→模型重排→人续写这一组合，不把真实模型生成重新标为未实现 |
| 共同定义及 365→730 | [旧框架里程碑](2026-09-19-runtime-generated-ui-milestone.md)已有三入口同规则及启动重声明原证（`declared=1..365/1..730`，非热更新）。E 只核实际字段/动作是否复制规则，发现重复再修；不用在 Markdown 产品硬加“保留天数”或重跑全部旧验收 |
| bidi/affinity、styled runs/inline | E2/E5：TextKit/CoreText 和 run 背景/字形消费已有；视觉逻辑位置和公共 affinity 需按反例补齐。内联组件需具体用例才扩公共接缝；不重建 shaping 引擎 |
| VoiceOver、物理跨屏、文件 PNG、提交阶段观测 | 分别在 F5/F6/F8/F9。前两项是实际消费待验；后两项已进入 [F 当前包](#f-file-png-receipt-next)，不新增重复任务 |
| H marked/cancel、触摸滚动 | 前者是特定 SDK/镜像/输入法的未观测边界；后者已进入 [H 当前包](2026-09-26-harmonyos-executor-handoff.md#h-touch-scroll-next)，继续模拟器正常 HAP 消费 |
| 无约束 preferredWidth | 旧完整测量路径存在，但本次没有新热点原数；遇实际负载先量测及归因，必要通用修复归 E/F 协调，不把风险推测算已确认性能缺陷 |
| G9、长列表、encodingCoverage、整值替换提示、PDF、跨机 | 属产品实现/产品性能或交付验收。G9 有真实产品预算洞；单页短夹具不证明 PDF 不支持分页。空 RANGE 已见同快照修复源码，运行结论待执行者收取，不能再安排重复修复 |

**推进顺序与工作量控制：**E 保持[当前有界导出/可视 A–D](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#bounded-export-visual-next-20260928>)，同版文档身份作为读取接续的优先反例；[共同操作与固定快照下一包](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#shared-editing-snapshot-next-20260928>)统一承接撤销来源、工作区公开接线、快照租约与正常窗口交错。独立项可在等待时推进，共享写集由 E 主执行者统一安排；不因新清单重启已闭合的 IME/D。F 完成已下发文件 PNG/提交观测后再做 F11，H 继续触摸包。生成式八项在相应能力交付时检查，不要求每个修复包都新增勾选或全量重验；快照租约和坐标变换也不能称为几件“小补丁”。本节更新既有规划，不创建第四条执行线。

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

**推进方式。** 本包由第三线实施，必要返工和 C 的独立工作交错。涉及文字纹理/alpha、accepted 绑定或公共动效语义的不明契约，由当前执行者结合源码与最小反例归因；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型。升级时给出原始结果，已有裁决前提未变直接落实。同 target 构建、共享 native 符号和桌面串行，等待时推进独立模块/消费者；无新变化不重复全套测试，不追加逐轮 Markdown。包末仅更新本页结果与 ACTIVE 的短状态，指导不在本次启动执行任务。

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

执行按独立写集交错；构建、咨询等待期间继续未阻塞的注册/主题/脚本工作，同 target 和桌面串行。问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型；accepted 事务/代次/属性所有权等契约先由当前执行者结合源码和反例核实，已有裁决直接实施。以代码接线和可消费结果推进，受影响测试与集中链通过后停止重复自验，包末更新本节结果及 ACTIVE 短状态。P4 保留在规划中，本接续继续完成 P2/P3 的通用能力。

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

**执行方式。** 先核对实际实现，已接通项直接复用；把实现、正常消费和相关测试连续完成，避免只写状态或循环验收。普通接线直接处理；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，公共语义/身份/并发架构不明确时先核源码与可区分反例，已有裁决直接落实。按 AGENTS 协调共享 native 符号、同 target 构建和桌面；等待期间推进独立工作。最终只在本节集中记录交付和真实剩余项，ACTIVE 保持短状态；未授权不 stage/commit/push。

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

**执行节奏与问题升级。** 执行者先读 AGENTS、ACTIVE、本节及直接相关源码；写仓颉前读 `cangjie-coding` 技能。先用当前管线画出 A3 的 alpha/所有权边界，结合必要源码和反例明确契约，然后连续实现可消费链；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，升级时提供复现、假设与结果。已有裁决直接用，普通接线自行完成；Laya 如可用只作辅助判断。遵循 AGENTS 的失败升级阈值，减少在同一猜测上换补丁。编译/咨询等待期间推进独立模块、消费者或判据，同 target 和桌面串行；确无独立工作才等待。验证按影响运行，充分通过后进入下一项；包末只在本节记录结果与证据链接、ACTIVE 写短状态，不追加逐轮长文。完成报告列清新增公共能力、两条真实消费链、性能原样本和实际剩余项。

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

接着完成两个正常消费者的开启/切换/清除/回退/恢复，生成侧经公开客户端提交并读回；核对主题、减少透明度、焦点/resize、多窗隔离与关闭释放，以及原控件/文本 owner 的连续性。复用已接受的组效果、模糊和缓存证据，只补本次受影响检查；最终对汇合源码做一次串行构建/相关回归、实际消费和含空格同源导出。原生适配与主题事务的既有咨询结论在前提未变时直接用于实施；新证据或冲突由当前执行者核实，必要时按 AGENTS 向指导升级，不自动追问顾问。等待构建或咨询时推进独立消费接线，确无安全独立工作才等待。只在本节汇总结果并更新 ACTIVE，保持 E/H 写集。

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
5. **验证、交付与问题升级。** 记录诊断开/关的 CPU/资源额外成本、采样上限及停止后零工作。旧缺陷最小反例→机制修复→受影响回归；包末一次串行构建、相关检查与含空格双消费者导出，公共入口随包交付。accepted/提交快照一致性、资源寿命或架构方案先由当前执行者结合源码与反例核实；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型。等待期间推进不改在编译输入的独立模块/消费接线，完成链路才更新本页和 ACTIVE，过程输出留日志。保留 E/H 改动，未经要求不 stage/commit/push。

**本包结果（2026-09-27，F 线）。**

- 两窗原始 FAIL 保留于 `/private/tmp/cjgui-p3-final-two-window.log`：延迟 2/9/15 ms 的 20 笔中仅 6 笔实际在 A 同步段投递，旧判据将投递阶段不匹配与请求交付失败混在一起；旧滚动日志末值 47397，缺少足够逐步数据来证明旧检查起点或精确首因。修正探针采用 1 ms 早期投递并逐笔确认在途；从已知头部滚动，testing-only native 入口读 offset、最大值可用性、可见 glyph 范围与版本。`/private/tmp/cjgui-f-two-window-corrected-run.log` 的 20 次尝试全部在途且 owner/accepted 成功，无挑选或重试；由 producerPost 计时，未插入保持 A 的等待闸门，owner p95 7 ms、accepted 观察上界 p95 24 ms，原 100/150 ms 预算未改。本结果只覆盖早期在途，不能声称旧 early/middle/late 三相位均通过，也不能将 14/29→7/24 解释为性能优化。head 0→mid step 77–79→tail step 157，共 158 步单调；这些步的 max=-1（未知），另一个边界腿确认 `47397→47397` 合法钳位且尾标记可见，`passed=true`。新探针的在途投递、从头滚动与触底判别成立；保留旧 FAIL，不将其精确根因扩大为本次已证事实。测试中的“CJGUI 调度 B”固定 620×440 点、虚拟列表固定 8×26 点；2×截图下的下半部留白来自该视口。
- 公共 experimental `diagnosticSnapshot` 返回当前 accepted 窗口/节点身份、布局、有效裁剪、声明效果范围，以及按提交场景/帧匹配的 native 输出和实际 backdrop 采样范围；accepted、submitted、completed 与最近刷新耗时分别标明，缺失的 raster/upload/effect pass/cache hit/in-flight 计数为 -1。读回不复制正文或同步等待 GPU；每页最多 256 个可见节点，下一索引和截断位支持同 session/accepted 版本分页，原场景准入上限为 1024 节点。独立 AppKit 诊断层在 Metal 和多行正文之上绘制布局、祖先裁剪、效果输出/采样与选中身份；默认隐藏、无命中/焦点/AX 元素，关闭和失效时撤销；采样框只在同代实际 blurred 提交时显示。此方案由只读 `gpt-6-astra` xhigh 聚焦咨询后按现有资源/线程归属实施，咨询不是验收证据。
- UI-only 正常应用经公开入口开启/关闭，scroll 令 accepted 16→17，非法候选保留 17；生成应用与真实公开 Python 客户端使候选 `ACCEPTED`、场景 3→5、native output/sample 均可用，再以非法 blend 得 `REJECTED` 且场景不变。两者开启叠加不增加 Metal 提交，资源字节不变，关闭后 draw/submission 不再增长；真实双窗 session 隔离和一窗 resize 640→710 点后仅该窗可见节点 62→48 已验，叠加期间 AXPress 与指针分别使同 owner 动作 0→1→2。截图 `/private/tmp/cjgui-f-overlay-two-live.png`，正常应用日志 `/private/tmp/cjgui-f-ui-diagnostic-final.log`、`/private/tmp/cjgui-f-gen-diagnostic-final-app.log`，客户端日志 `/private/tmp/cjgui-f-gen-diagnostic-final-client.log`。
- 最终含空格同源导出中的原始成本：UI-only 单次快照 630/869 µs（开关前/后样本），24 次读取 20311/14509/关闭后 13192 µs，live/cache 7680000/7680000 B 不变，开关提交 20→20；生成应用单次 371/320 µs，24 次 5531/15667/关闭后 5590 µs，live/cache 804000/804000 B 不变，开关提交 3→3。数值是当轮原始 CPU 读时，不作为跨场景吞吐提升结论；空闲 4 轮后 draw 与提交均不增长。框架 `cjpm test` 359/359、`cjpm build --skip-script`、native clang 语法、脚本语法及 `git diff --check` 通过；359 项全测先于最后一行 native-only 采样门控，该行另经 clang 与最终同源应用实跑覆盖。最终导出 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260927205749-62399/CJGUI Framework Preview/CONSUMER_FINGERPRINTS.txt` 标记 `v9`，两消费者构建运行、生成公开诊断/效果/材质客户端及注入失败拒绝均通过；框架 source/native SHA-256 分别为 `62bc693520e2f9ac159e94729303a7c83bcdd7e504ee462e3cae17ed2847cd37` / `35a72e3bbe130c44a90fcc54dec914f0d659bfe21a1c05f84a4003e11332b243`。静态 CodeLattice 路由未识别此多项目根、GitNexus 新符号为 UNKNOWN，以源码调用、构建、真实应用/客户端和 native 检查补证。
- VoiceOver 原先为关；首次启动出现 Quickstart，用户随后协助开启且系统进程存在。尝试 VO 键导航后没有可归因的旁白光标、朗读或旁白发起的动作证据，故 **VoiceOver 导航/激活仍未通过**；独立 AXPress/指针结果不可替代它。已恢复先前关闭状态。后续保留真实旁白动作和当前不可测的细分 GPU/资源统计，不将它们记为本包通过。E 正文/IME、H 平台后端的并行改动均保留，未 stage/commit/push。

**指导限域复核（2026-09-27）。** 抽查窗口诊断入口、native 同场景/帧门控及独立叠加层，并复算两窗原始样本：每页/裁剪链/身份长度有界，同 session 与 accepted 版本可校验；叠加无命中、焦点或 AX 元素，独立于效果采样，失效/关闭后撤销。正常消费日志支持开关不增加 Metal 提交和效果资源。按上述范围接受本包，校准两窗投递覆盖与最大 offset 可用性表述；本次未构建、测试或操作桌面。VoiceOver 和未发布计数仍待验，旧日志保留。

<a id="f-png-transfer-next"></a>
### F 线 PNG 剪贴板与拖放：主链交付，准入/发现返工接续

**目标、范围与取舍。** F7 已有可消费诊断，不继续扩成完整调试器；接续 F8 的首个真实格式，服务普通应用的图片粘贴与拖入。目录 `/Users/jiangxuanyang/Desktop/cangjie`，执行对象为框架渲染线 F。E 继续负责编辑器正文/IME/Markdown 与附件持久化，H 继续鸿蒙后端及生成式消费；本包交付通用交换机制和两个正常消费者，不以 E 完成接入为前置。文件 URL、文件 promise、HTML/RTF 和其他图片编码留在后续范围。

**已有资产与借鉴。** `shared_operation_core/src/shared_operation_transfer.cj`、`composable_ui_window.cj` 的 declaration/provider/event 已支持 accepted 身份路由、owner/CAS 与有界文本；native 的 `CjguiPasteboardTypeForDataTransferFormat` 仅将 text/plain 映射到系统字符串，其余格式走私有 UTI，`CjguiReadComposableDataTransferItem` 一律 UTF-8 解码，因此标准 PNG 二进制不能直接消费。复用这些声明、授权、事件归属和既有图片加载/缓存/引用机制。macOS 格式及拖放会话按 Apple 的 [NSPasteboardTypePNG](https://developer.apple.com/documentation/appkit/nspasteboard/pasteboardtype/png?language=objc) 与 [NSDraggingDestination](https://developer.apple.com/documentation/appkit/nsdraggingdestination) 适配；系统负责拖放追踪，CJGUI 负责 accepted 目标、数据寿命和 owner 事务。借鉴分层与平台服务，不复制另一套组件树或在产品写原生补丁。

**A．二进制值契约与准入。** 扩展现有 transfer 表示，使文本与 PNG 二进制可区分，保留旧文本消费者的兼容路径。平台 MIME/UTI 映射必须互通标准 PNG，真实二进制不能经 NSString 解码或冒充结构化文本。定义不可变 payload/受控资源引用、数据格式、编码字节数与内容摘要；引用须有明确所有者和释放点，不公开原生指针。按既有预算体系明确发布每项字节、图片尺寸/像素、解码资源、排队总字节与在途数量上限，乘法/加法先判溢出。先检查可得元数据，在框架复制/排队/解码增长前准入；若平台取数本身先物化全部数据，单列其内存与时延限制，不能把读后拒绝说成读前有界。PNG 签名、截断、畸形尺寸和解码失败均具名拒绝并保留旧图；使用既有解码服务，不新写 PNG 解码器。

**B．平台交换到原 owner 的完整接线。** 接通显式复制/粘贴与 copy 语义拖放，格式选择确定；预览和悬停只检查能力/目标，不触发业务写入或反复解码。用户完成动作后，由框架捕获一份有界不可变数据并经同一 owner 接受/拒绝，成功动作恰好推进一次业务版本。异步准备/图片加载继续复用已有资源路径，绑定窗口/session、目标语义身份与绑定代次；关闭、禁用、删除或同 key 换绑后旧结果不得应用，无关场景刷新不误取消仍有效的目标。失败、取消、替换、源窗先关闭及目标关窗均释放本轮临时资源；accepted 图片与在途解码/GPU 使用按既有持有规则存活。仅图片数据才进入图片路径，外部来源元数据不构成授权。若需临时文件适配现有图片入口，由框架管理唯一目录与租约，不能把产品临时路径约定当公共契约。

**C．手写/生成共用定义与正常应用证据。** 在现有 UI-only 与生成消费者各增加简洁的图片接收/预览区，使用同一公共组件/声明与领域导入操作。共同能力只定义一次；生成目录如实发现可用格式、目标与预算，候选复用既有接受事务。外部系统通过原有授权操作引用应用已拥有的资源，得到与人相同的校验和 owner 结果；生成声明本身不读取系统剪贴板或任意本地路径。

一次连续验收：标准 PNG 来源→真实 Cmd+V→owner 摘要/版本与可见图片→复制并真实拖入另一消费者→重排目标后继续接收→非法/超预算/过期目标保留旧图→取消/关闭回收。至少一个输入由独立标准 pasteboard 生产者提供、无 CJGUI 私有元数据，避免只证明自家私有格式互通；PNG 原字节用含零字节/非 UTF-8 序列的夹具逐字节或哈希核对，解码结果用尺寸及判别像素核对。拖放必须有真实系统 down/move/up 及接收端操作回执，直接调 handler 或公开写入单列。测试只使用自有图片/实例；剪贴板按 changeCount 保护，仅在本轮写入仍为最新时恢复原内容，他方新内容保留。

**D．机制反例、成本和同源交付。** 必要反例覆盖标准 UTI 对照、字节损坏/超限、同 key 换绑迟到结果、源/目标关闭、取消与重复回调；每类检查 owner/accepted/临时资源的前后值。复用有界诊断记录取数、复制、解码、owner 接受与 scene 呈现的阶段成本；小图、接近已发布上限、超限三档分别报告，接近上限导入期间另一正常窗口的公开操作仍可服务，沿原 100/150 ms owner/scene 预算判断，明确载荷/计时起点与冷/热范围。系统取数若不可抢占，指出阻塞区间并缩小已发布支持预算或升级方案，不用事后取消冒充提前避免分配。空闲不新增轮询/提交，缓存/队列/临时资源按上限和生命周期收敛。

按改动范围运行旧文本/结构化传输回归及新反例，包末做一次框架构建、受影响测试和含空格同源导出双消费者真实链；无改动的 P1–P4 与诊断基线直接复用。VoiceOver 保持待验，只有新增可区分证据/环境条件时才续查，不反复切系统设置。二进制所有权、异步接受或跨窗口事务方案先由当前执行者结合源码与反例核实；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，Laya 仅辅助。等待编译/咨询期间推进独立任务，同 target 构建和桌面操作串行。只在本节集中写实现与证据、ACTIVE 写短状态；保留 E/H 写集，未经要求不 stage/commit/push。

**2026-09-28 实施与判别。** A–C 已接入现有传输、accepted 场景与图片 owner：`image/png` 使用系统 `public.png`，不可变二进制 offer 带字节数和 `fnv30x2` 摘要；每项 512 KiB、尺寸各 2048、像素 1,048,576、排队 2 MiB、在途 4、待处理 16、记录 64，纹理缓存 8 项/32 MiB。PNG 经既有解码和图片呈现路径，原 owner 版本只在接受后推进；生成目标随 accepted 结构重排保持身份，换绑、删除和拒绝候选用绑定代次拦住旧结果。手写和生成消费者共用声明与公开能力目录，原 owner `SELECT_OWNED_IMAGE` 精确读回。标准独立 `NSPasteboardItem` 的 80 B PNG（SHA-256 `091f92661b0eeb27b20812642590bf63f902d392ef93d38dcc5759e40f53951f`）真实 Cmd+V 后，手写 owner v1、生成 owner v1 且可见；真实系统 down/move/up 跨窗拖入先落生成静态目标 v2，再在接受重排后落动态目标 v4，接收端 `prepare→perform` 状态 0、源端 `ended operation=1`，公开选择 v5 与原摘要一致。native Metal readback 判出红、绿、蓝源像素；非法 27 B 与超限 524,289 B 都保留生成 owner v7 的 492,058 B 旧图。取消、重复完成、预算不足和释放后恢复的探针通过，close 后 native 缓存 0、记录 0；weak ledger 为 4，不记为零。

**成本、回归与导出边界。** 80 B 独立来源在手写窗口取数 535 μs、队列复制 20 μs、解码 238 μs、owner 21 μs；492,058 B 冷取数 1004 μs、复制 17 μs、解码 691 μs、owner 4 μs，热取数 45 μs、复制 10 μs、解码 607 μs、owner 4 μs；524,289 B 超限项在系统已物化后取数 368 μs 并拒绝，无排队、解码或 owner 接受。并行的另一正常窗口公开操作 200 次，owner p95 21.238 ms、scene p95 33.455 ms（阈值 100/150 ms）；第 102 次的 scene 等待跨过导入时刻，不能说其 owner 同步段重叠。系统 `dataForType` 先物化整项，超限拒绝前的系统分配不可预阻，公开目录如实标 `system_fetch_preflight_bounded=false`。旧文本/native 交换、单次拖放会话、资源预算与生成绑定反例通过；最终框架 `cjpm build --skip-script`、373/373 测试通过。含空格同源最终导出 100 项（原样 90、导出重写 10）指纹 `1fd55bfbee533900ff8d01d82987a158503471ec168aef4a4692c699c8bf09b3`，两消费者分别构建运行、真实 Cmd+V 接受同一标准 PNG，AX 状态 v0→v1、彩色预览可见，公开 owner 对原 SHA 精确读回并选择到 v2。先前正常 AX 关闭曾留下图片 owner 描述符（RED）；框架 Host 现有界接管附加连接的关闭，最终导出两消费者在实际导入后 AX 关闭，各自主/附加描述符、socket 与私有目录均消失（GREEN）。第一次追加粘贴遇第三方剪贴板改写而跳过，协调桌面后用新快照完成上述最终链，并按 changeCount 恢复原文本。文件 URL/HTML/RTF、系统取数预物化上限、VoiceOver 和 E 的文档插图语义仍留后续；未 stage/commit/push。

**指导限域复核（2026-09-28）。** 已读最终两消费者粘贴/公开 owner 日志、373 项测试和导出指纹记录，并从 200 条唯一样本复算报告分位数（脚本用排序数组下标 `ceil((n-1)*0.95)`）；本次未重跑构建或桌面。现有真实消费与关闭交付保留，但源码显示两处未闭合边界：① `cjguiComposableImageFromTransfer` 和 native scene setter 只限编码字节，缓存未命中时可走通用 `newTextureWithData`，没有经过交换入口的 PNG 尺寸/像素验证与解码前预算预留；这是可达的准入旁路，尚未由本次运行实验测出实际超额。② 当前验证器仅接静态 8-bit RGB/RGBA，能力目录未说明此子集，其他变体混报 `png_invalid`。下一包 A 先建立判别反例并统一机制，不能据本包通过推定所有公共呈现入口均有同样预算。当前正常导入预准备是同步解码；队列迟到与准备后绑定复核不称为后台解码完成实测。主要原证：`/private/tmp/cjgui-f-png-resume/` 下 `final2-{adaptive,generated}-paste-live.log`、`native-budget-final.log`、`framework-adopt-test.log`、`export-other-window-bench-overlap.log`、`final-export-fingerprint-postbuild.log`。

<a id="f-scale-consumption-next"></a>
### F 线 PNG 准入与运行中缩放：消费结果及指导复核

**目标与取舍。** F 继续负责通用框架：补 PNG 公共入口的一致准入，并让普通应用和外部客户端准确读取、消费运行中的点尺寸、像素尺寸与 backing scale。现有 DPI 通知、文字/效果缓存与 P4 的受控 2×→1×→2×像素探针已存在，当前未确认整体缩放渲染错误；新增交付是正常窗口的同版本事实、连续输入和失败恢复。E 保留正文/IME/SourceMap/文档插图语义，H 保留鸿蒙图片后端；共享值契约保持可移植，macOS 接线留在窄桥。A 的返工与 B–D 的独立部分交错推进。

**复用与平台依据。** 直接复用 `currentBackingScale`、`windowDidChangeBackingProperties → windowGeometryDidChange → resizeVersion`，窗口 `syncProjection` 的布局缓存失效和同逻辑 scene 强制重提，以及既有 scale 测试接缝、图片资源域、效果在途持有和 `composable_ui_diagnostics.cj`。native 已记录 `lastSubmittedPointSize/lastSubmittedDrawableSize`，公共诊断与 platform snapshot 尚未把这些事实连成同版本读数。按 Apple 的 [backing 属性通知](https://developer.apple.com/documentation/appkit/nswindow/didchangebackingpropertiesnotification)、[macOS Metal 窗口尺寸转换](https://developer.apple.com/documentation/metal/managing-your-game-window-for-metal-in-macos)及 [drawableSize 像素单位](https://developer.apple.com/documentation/quartzcore/cametallayer/drawablesize)落实平台换算；借鉴系统坐标服务与失效通知，不另外建设布局/渲染树或生产用强制 scale API。

**A．PNG 准入由全部公开呈现入口共同消费。** 先用真实公共构造器及正常 scene 事务建立反例：预算内编码长度的超尺寸/超像素 PNG，通过 `createBinary → cjguiComposableImageFromTransfer` 直接呈现；以及合法导入、移除、缓存失效后同 offer 重显的再准备路径。检查解码启动前的尺寸/像素/解码字节准入、在途预留及失败/取消释放，不能只断言最后拒绝。把交换预准备、直接声明与缓存未命中后的再准备接回同一个受预算约束的机制；不要以“应用应该先粘贴”作为公共 API 的隐含条件，也不要新增信任 Bool 绕过验证。缓存命中可复用与不可变内容身份绑定的准入结果；资源身份、窗口代次、owner CAS、失败保旧及 GPU 在途持有延用既有机制。交换项上限仅约束相应来源，普通已声明应用资产沿自身资源契约。

对齐 PNG 子集和公开发现：本包至少诚实发布静态图、支持的 bit depth/color type/interlace、系统取数预物化边界；已识别的未支持变体使用稳定的 unsupported 原因，与畸形/截断/超预算区别。格式能力由公共定义一次派生到手写/生成目录和客户端；补 RGB/RGBA 正控与灰度/索引色/16-bit 等变体判别，保留既有解码库，不自研解码器。无须为修正声明扩展所有 PNG 变体。实现或准入路径变化后，验证一次真实粘贴→owner→图片、直接声明消费、缓存失效重显和关闭回收；未影响的拖放/文本基线复用。

**B．同版本的窗口几何与呈现事实。** 在既有有界、只读诊断/公共观察链补最小平台无关值：窗口/session 身份、逻辑内容尺寸及单位、实际 scale、drawable 像素尺寸、几何/环境修订，并关联 accepted scene 与成功提交 frame。明确区分“平台当前观察值”和“最近成功提交使用值”；resize/scale 已发生而新场景尚未成功时，两者可以不同，读者须看得出来。读取原子采样或以修订守卫拒绝混合值，不能把新 scale 拼到旧 frame 上；未知、未提交和已关闭具名表示。读取不触发 build/layout/submit，不暴露 NSWindow/屏幕句柄，不另造一套轮询服务。生成消费者使用现有公开快照/分段版本机制取得同源值，UI-only 无须为了诊断强制启用外部服务器。

**C．变化传播、缓存与输入连续性。** 正常 host 中由所属窗口的真实通知驱动，保持同逻辑尺寸换 scale 也能重提；重复同值通知不造成持续 build/栅格化或代次泄漏，其他窗口不被误失效。像素换算与裁剪使用一致的点→像素规则，边界按覆盖需要取整；保留排版的子点精度，不能把所有字符/布局框逐项四舍五入。校核文字栅格、效果目标/blur 核及采样框的实际依赖；原始图片不因显示 scale 变化就强制重复解码。复用已有接受事务：受控一次准备/提交失败时旧 accepted 内容、owner、身份和资源存活，平台观察变化仍如实保留，下一合法提交恢复；旧 GPU 完成不能覆盖新提交事实。

将同一坐标来源接到 AX、诊断叠加与实际指针命中。缩放/resize 后控件继续操作同一 owner，草稿、选择/焦点身份、滚动位置按既有规则保持；光标/选区几何若需重取，复用 E 已交付的 accepted 查询，不改其文本会话协议。命中按逻辑区域与祖先裁剪，不能把 Retina 截图像素直接当窗口点坐标。移动窗口涉及屏幕原点变化时，走平台转换；不依赖屏幕原点为零或主屏固定 2×。

**D．双消费者真实闭环、成本与交付。** 复用现有 UI-only 与生成消费者，各用一个可操作控件、文字、PNG 和效果表面组成简洁场景。连续完成：读取初始身份/几何→真实 resize→公开候选接受→实际输入/owner 精确读回→同点尺寸的受控 scale 往返→当前/提交事实和判别像素一致→拒绝保旧→恢复→停止与关闭收敛。受控 scale 使用既有 test-only 接缝通过正常通知/host 链，明确标记测试构建；最终 normal 导出仍须在本机真实 scale 下构建、公开读取和实际操作。有不同 scale 的真实显示器则加窗口跨屏腿；没有硬件时只把物理跨屏单列，继续其余实施，不把受控覆盖命名成物理跨屏。

关键反例集中覆盖：PNG 旁路、同点换 scale 误走 no-change、新旧 frame/scale 混读、失败后恢复及另一窗口隔离。使用关系/局部像素、精确身份与操作读回判别；必要错误注入应能使对应检查失败，不重跑 P4 全部效果矩阵。记录每次转换前后 build/layout/raster/upload、效果 live/in-flight 字节、CPU 阶段和可得 GPU 完成；正常同 host 另一窗的带身份请求按原 100/150 ms owner/scene 预算，给样本数、原始分布和真实重叠范围。转换结束、重复读取及空闲时计数收敛；未知指标保持 unavailable。

包末按改动影响一次构建/针对性测试和含空格同源导出，保留源码/资源/客户端指纹。准入所有权、异步资源或公共一致性契约先由当前执行者结合最小源码与反例核实；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型；Laya 只辅助，不代替运行证据。等待构建/咨询推进独立代码或消费接线；同 target 构建和桌面串行。只集中更新本节及 ACTIVE 短状态，已有基线按影响复用，保留 E/H 写集，不 stage/commit/push。

**2026-09-28 实施结果与判别。** A：公共 `createBinary → ImageFromTransfer → scene` 的 2049×1 旁路先实测为 `status=0/records=1/loaders=1`，现与粘贴预准备、缓存未命中重建同走同步 PNG 准入；超尺寸/超像素在解码前拒绝且 `records=loaders=0`，同 offer 换字节拒绝，候选丢弃、源窗关闭及末窗关闭分别回收而不伤另一窗口。静态非隔行 8-bit RGB/RGBA 两种判别像素通过；灰度、索引、16-bit 给 `png_unsupported`，坏 deflate 给 `png_decode_failed`，编码项/排队/纹理预算各有稳定原因。公开能力由共同定义派生，声明系统 `public.png`、512 KiB/2048×2048/1,048,576 像素及系统取数先物化边界。仓颉直接声明 1/1 针对性测试、native 资源/重建/关闭探针通过（`/private/tmp/cjgui-f-scale/direct-test.log`、`/private/tmp/cjgui-png-resource-budget/20260928020016-20723/result.log`）。准入/解码在主线程同步完成；提交后的纹理由既有 GPU 持有和资源域账本覆盖，未声称系统 pasteboard 预物化也受 512 KiB 分配上限保护。

**B–D 消费与成本。** 公开 `GET_WINDOW_PROGRESS`、有界诊断及生成快照现以同一次 native 采样分列当前点/像素/scale/revision 与最近成功提交的 scene/frame/几何；未提交、关闭有具名状态。受控通知证明当前 2×→1× 时提交仍为旧 2×，一次提交失败保旧，恢复后同版，重复同值无新 revision、另一窗不变（`/private/tmp/cjgui-f-scale/geometry-final.log`）。两个正常消费者各真实 resize、操作控件/文字、标准 PNG 粘贴并从 owner 精确读回；UI-only 为 640×700→1512×846 点、1280×1400→3024×1692 像素，按钮 owner 0→1→2，PNG v1 为 3×2/80 B；生成窗为 840×520→1512×846 点、1680×1040→3024×1692 像素，PNG v1 为 3×2/79 B，标题/备注回写及公开候选 accepted 后非法候选拒绝保旧。随后两消费者各用**临时测试构建**沿正常 host/backing 通知完成同点 2×→1×→2×：手写像素宽 1280→640→1280、帧 9→11→13；生成 1680→840→1680、帧 3→4→5；session/owner 不变，当前/提交修订汇合，空闲连续四轮收敛（`/private/tmp/cjgui-f-scale/controlled-adaptive-cost-final.log`、`controlled-generated-cost-final.log`）。同一测试的 build/layout/submission 计数分别为手写 `2/4/6/6`、`2/4/6/6`、`9/11/13/18`，生成 `3/5/7/7`、`3/5/7/7`、`3/4/5/5`（起点/1×/返 2×/空闲）；效果 live bytes 为手写 `7,680,000/1,920,000/7,680,000/7,680,000`、生成 `1,029,120/257,280/1,029,120/1,029,120`，GPU 最近完成为手写 110/331 μs、生成 197/533 μs。该诊断的 raster/upload/in-flight 及 native stage CPU 为 `-1`，如实记 unavailable。公开空闲读取 20 次 10,413/21,214/22,336/22,413 μs（最小/中位/p95/最大）且 scene/frame/revision 未动；同 host 另一窗 no-effect/static/active 各 120/120 接受，owner p95 均 17 ms、最大 36/36/19 ms，scene p95 均 34 ms、最大 54/57/37 ms，均在 100/150 ms 预算；此响应负载没有与 scale 转换重叠（`/private/tmp/cjgui-multi-window-response/20260928020138-21916/`）。

**交付与实余。** 生成消费者首次无候选刷新误将系统材质预设改成 opaque，以及 PNG 控件把效果组推到 y=560、超过 520 点窗口的两项导出 RED 已按候选提交与可见布局修复；最终模糊回退/恢复、材质、诊断及生成外部客户端全过。含空格导出两消费者构建、自验和注入负控成功，指纹在 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260928022751-46652/CJGUI Framework Preview/CONSUMER_FINGERPRINTS.txt`（框架 Cangjie `38c62656…`、native `f961bd90…`），正常产物不含测试专用 scale/session 符号。最终布局的两个正常独立应用又完成实体前台复跑：手写窗口标准 PNG 粘贴 v1 `3×2/80 B` 后，resize 至 `1512×846` 点、`3024×1692` 像素，公开当前/提交 revision 均为 `41`、scene/frame 均为 `49`，组内按钮 owner `0→1`；生成窗口在实际生成 PNG 目标粘贴 v1 `3×2/79 B`，PNG owner 公开 digest/尺寸/字节精确一致，resize 后当前/提交同为 `1512×846` 点、`3024×1692` 像素、revision `41`，真实文本框逐键与系统粘贴写回 title `Scale ready`、共享版本 `7`。非法效果候选读回 `accepted=false` 且 version `3→3`，随后合法恢复为 v4。两窗均关闭且 socket 退役，临时 PNG 剪贴板在各轮后按先前快照恢复（正常应用日志 `/private/tmp/cjgui-f-scale/final-adaptive-app.log`、`final-generated-app.log`）。受控向量 2×→1×→2× 边缘 RGBA `26,173,240,255`、命中与裁剪关系通过；焦点环新增一个固定 generic paint 后修正了向量探针的旧“零 generic”判据（`/private/tmp/cjgui-f-scale/vector-native-fixed2.log`）。另一个向量批量探针仍原样 FAIL：16 对象的 30 次局部改色统计 570 次节点克隆/分配，而旧判据为各 30；这不是本包 PNG/scale 像素成功证据。物理跨显示器未验；桌面 `typeText` 一次快速整串输入丢字，逐键观察与系统粘贴最终精确写入，尚未把快速合成事件当作应用键入成功证据。E 的正文/IME、H 的鸿蒙和并行改动保留；未 stage/commit/push。

**指导限域复核（2026-09-28，本包接续）。** 已读 PNG 资源原证、几何失败/恢复探针、两消费者正常与受控 scale 日志、导出记录及向量批量 FAIL，并核对关联源码；本次没有构建或操作窗口。尺寸旁路、子集发布和当前/提交几何读回的成果保留，主消费链不重开。仍有两项具体问题：

- PNG setter 先统一准备新图，随即 `finish(..., accepted=1)` 归还 preparation 引用并触发修剪，此时候选尚未取得新 texture/key。已有 8 个被场景保护的缓存项时，第 9 张新图可成为唯一可淘汰项，随后又经通用异步路径解码；准入与候选持有之间存在空档。该路径由源码确认，压力反例尚未运行。现有 `cache_rebuild` 用例仍持 accepted 纹理，证明的是缓存/记录重建，不等于所有持有消失后的冷重显。
- `/private/tmp/cjgui-composable-vector-scale-final/result:31` 的 `clones=0/570 allocations=35/605` 是 30 次单对象改色后的增量；原几何/上传计数仍复用。当前代码可解释为 18 个高度 2 的非文字结构节点每轮误入空文本布局、内缩后布局为 nil、下轮再 clone，加上 1 个真正改色节点，合计 `19×30=570`；执行者仍须用一次按原因/节点的判别确认。该探针的 scale 指对象数量，首组失败使 128/480 组短路未运行，不是 DPI 失败或 35 个节点全部复制。已有 120 请求响应表没有与显示 scale 转换重叠，不扩大其适用域。

<a id="f-local-refresh-next"></a>
### F 线 PNG 候选持有交接 + 局部刷新复用与工作量消费：按受验快照收口

**目标与复用。** 本包优先修已定位的资源交接和局部刷新额外工作，推进 F9 的正常消费及最小工作量观测。沿用 PNG 准入/资源域、staged→accepted 事务、按需复制（COW）、文字/向量资源缓存、几何进度、公开诊断和两个正常消费者。保留 E 的空文本 accepted 布局/细光标能力与 H 图片后端写集；不通过回退整段文字修复换取向量指标。架构仍是仓颉组件/owner + 窄 native 资源后端，不另建渲染器或业务状态。

**A．把 PNG 准备引用真正交给候选。** 先建立“8 个仍受场景引用的不同图片 + 第 9 张新 PNG”反例，记录准备、修剪、候选取得 texture/key、解码次数、loader 和实际存活字节。再补移除 accepted、清除缓存/其他持有后同 offer 冷重显；不能只删字典而保留活纹理来声称完成冷路径。复用当前准入，明确准备持有→候选持有→accepted/GPU 使用→释放的交接：新节点已拥有准确资源后才能归还准备引用；候选失败、替代与关闭只释放自己的份额，重复 build 不累积。具体用已有引用计数或小型内部租约表达，由执行者依当前结构落实，不能仅把某次 prune 禁用。

所有 transfer-origin 的首次/缓存未命中解码须经同一准入和预算机制；普通加载器不得成为回退旁路。保持资源域可解释的 encoded/decoded/in-flight 账目、同身份内容不可换、稳定错误与旧 accepted 保留。明确 8 项是可回收缓存限额还是全部 live 限额，场景持有与 GPU 在途不能为了满足缓存数量提前销毁；超出硬预算时在解码/分配前拒绝。判据是单次合法准备无额外无预算解码、压力拒绝不污染旧场景、反复失败/移除/关窗最终收敛。复用现有预算咨询结论；若交接或账本归属仍不明确，先以这条精确调用链和反例归因，反复失败按 AGENTS 携证据升级指导，不自动咨询。

**B．收紧空文字布局的职责，恢复稀疏节点复用。** 原失败日志保留，先一次记录 clone 原因、nodeId/kind/几何，区分 setter 的必要 clone 与空布局分支的额外 clone。结构节点、向量、图片等非文字不得被当成空段落；同时保留旧文字资源/装饰的必要清理和候选 COW，使同槽换 kind、清空正文、裁剪与失焦不会留下旧资源。合法空文字/输入节点仍能提供 accepted 光标几何，零尺寸或暂时裁剪的情况用明确状态处理，不能每次都分配后才发现没有可准备的几何。

修在共同 native 准备入口；与 E 协调该分支，产品无需补特例。原 30 次只改一对象的 clone/allocation 判据保持，以 16/128/480 三档全部实际运行收口，不能因第一档短路而把后两档算通过。除向量原矩阵外，补混合文字/空输入/PNG/效果场景的局部改色、无变化刷新及一次候选拒绝：未变资源继续复用，文字样式/光标/选区可见，失败不污染 accepted。容器数组复制、遍历和布局仍可能为 O(n)，本包只按实测证明避免无关对象/派生资源重建，不宣称全链 O(改动数)。

**C．让正常消费者能核对工作量。** 在现有有界诊断快照中补这次定位确实需要的最少标量：节点写入/克隆/新分配、文字布局准备、图片解码启动及可复用的资源字节，区分累计值、本次尝试和最近 accepted/提交身份；若某项后端未提供，继续具名 unavailable。优先复用真实工作点已有计数，按窗口/session 归属，单调饱和，无正文/图片内容或无界逐节点日志。允许显式开启诊断，说明关闭状态；读取不触发刷新、对象克隆或新增提交。由手写/生成消费者及生成侧公开客户端消费同一值，正常构建可用，不能只在测试宏下有真实数据。若公共快照增加字段，保持旧调用兼容，并更新实际导出来源。

**D．正常应用、并窗响应与交付。** 在既有两消费者完成一条连续链：真实控件改变一个表面/属性→同 owner 精确读回→观测对应工作量→公开候选局部改版→PNG 压力/拒绝保旧→恢复与关闭。一次受控 scale 变化确认仍会必要地重建派生资源，修复不得把合法失效也跳过；normal 产物在本机实际 scale 消费，物理跨屏继续单列。无变化、停止动画和重复诊断读取后零额外提交。

同 host A 做局部改色/图片切换/几何转换时，B 的带身份请求记录 ready→owner→scene；在实际在途区间采集，有意保持的测试闸门只用于正确性交错，不计作自然性能。补齐上一包未覆盖的转换重叠响应；沿既有正常负载 owner/scene 100/150 ms 预算，分别报告 CPU 时间、工作量和内存/资源，给原始样本/分位数及测量范围。节点少分配不直接等于端到端同比加速；若预算失败，沿实测瓶颈修机制或带证据升级，不能降低载荷、放宽判据后沿用原结论。

包末一次受影响回归、构建与含空格同源双消费者导出；PNG 子集/无压力粘贴、DPI/效果算法和未变输入基线按影响复用。快速整串工具输入丢字、人工 VoiceOver/物理跨屏等旧边界保留，各按证据归属接续，不把慢速投递成功当作快速输入已修。问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，资源所有权/架构算法先核源码与反例；Laya 辅助。普通接线直接推进，失败升级沿 AGENTS。A/B 各自的证据与消费者接线可交错推进，同 target 构建/桌面串行；等待编译或咨询时做独立必要工作。只在本节集中报告、ACTIVE 保持短状态，保留 E/H 并行改动，不 stage/commit/push。

**本包实施与判别（2026-09-28）。** A：native PNG 资源域以每 session、精确 token/代次租约把 preparation 交给候选；候选配置成功后才交接，accepted/失败/替代/关窗各归还自己的持有。transfer-origin 缓存未命中不得退回普通 loader，仍按原准入及预算拒绝。原 8 项缓存满时第 9 图无租约解码启动 17→19、候选拿不到纹理；修后 19→20 且候选持有，同 offer 在所有持有释放后冷重显 25→26，旧弱引用已消失；两窗取消 23→23 不误毁存活窗口。压力拒绝保旧且释放待决持有。原始记录：`/private/tmp/cjgui-f-local-png-after-configure.log`。

**B/C：** 非文字节点不再进入空文字布局，同槽换 kind 清理旧文字资源；合法空输入仍有 accepted 光标几何，零尺寸与裁剪不制造多余布局。混合文字/空输入/PNG/效果局部修改 30 次 clone=30、额外文字准备=0，拒绝候选保旧；向量 16/128/480 三档各实际运行 30 次，改色 clone/分配各 30、未变向量上传 0、空闲提交 0，受控 scale 仍重建所需 raster。日志 `/private/tmp/cjgui-f-local-mixed-sparse.log`、`/private/tmp/cjgui-f-local-vector-red.log`、`/private/tmp/cjgui-f-local-overlap-green.log`。正常窗口有可开关的有界只读 workload 标量及公开 `WINDOW_WORKLOAD_*`：累计、最近尝试、scene 身份、文字准备、图片解码启动和可复用字节；关闭用 `disabled/-1`，重复读取不提交。最终导出手写控件尝试 writes/clones/allocations=18/18/18、text=11、decode=0、reusable=13,719,280 B；生成公开候选 2/2/2、text=2、decode=0、reusable=7,017,264 B，外部诊断客户端同 scene=5 读到 writes=2 与接受/拒绝票。对应导出运行日志和客户端日志见下述目录。

**D：** 正常手写窗口实收标准 `public.png` 的 80 B、3×2 测试图，屏幕有对应像素，owner v3→v4 的公开精确读回为 `fnv30x2:212259688:130720502:80`（`/private/tmp/cjgui-f-local-normal-png/ui-app.log`、`ui-owner-client.log`）。生成窗口的 accepted PNG 目标/源由公开结构和实例发现；在同一最终导出二进制上，用户于生成目标区域实体按 `⌘V` 后后台收到 PNG paste(kind 49)，画面显示彩色 3×2 图片与 `accepted` v15，公开 owner 从 v15→v16 精确读回同一 80 B digest，画面随之显示 v16。首次粘贴原数 decode=502 µs、owner=46 µs；本次实际出现多次 paste/drop 事件，不把 v15 归因于单次按键。复核日志 `/private/tmp/cjgui-f-png-rerun-20260928/generated-app.log`、`generated-endpoint-client.log`、`generated-owner-client.log`。同源双消费者正常构建运行与候选/拒绝/诊断客户端通过。并窗 20 笔每组：原 MIDWORK owner/accepted 上界 p95=7/24 ms，scale 1/48 ms；新局部改色 69/87、图片 73/91、几何 70/88 ms，均满足原 100/150 ms；B 请求实际发在 A host 在途，三组 A 布局约 50–51 ms，每次只写/克隆/分配 1 节点、文字准备 0，首图解码 1 次后复用。`native_stage_overlap=false`，所以这组只证明 A 布局在途交错；探针负载不能外推为自然键鼠尾延迟或全链 O(改动数)。原数 `/private/tmp/cjgui-f-local-overlap-green.log`。CJGUI `cjpm test --skip-script` 374/374、shared core 69/69、生成消费者 36/36，native PNG/混合/向量与 Python 客户端通过；含空格同源 v11 双消费者导出及注入失败拒绝见 `/private/tmp/cjgui-f-local-spaced-final-v2.log`，导出源文件已与当轮工作区逐字节比对。按用户截图修两消费者 PNG 按钮的深色文字，并为生成区固定深色区域的标题、正文和禁用动作设显式前景；组内默认 50% opacity/线性 mask 的演示暗度保持声明语义。快速整串输入、人工 VoiceOver、物理跨屏仍按旧边界；Codex 自动桌面注入的 `⌘V` 未触发应用事件，该工具限制由实体按键补证，不改变上述产品结果。

**并窗标记复核。** 当前探针的 `native_stage_overlap` 名称容易误导：它比较生产者时间与 native 活动文字资源准备钩子的起止时间，不是 GPU 提交起止时间。上述三组有效依据是 B 投递发生在 A 的实测 host turn 内；要证明真正的 native 提交阶段重叠，需另设提交边界的判别时间戳，重复现有探针不会补出此证据，且无需用户操作桌面。

**人/Agent 同状态验收。** 本次应用后台在用户操作时已记录接受事件与 owner 版本；Codex 测试进程不会自动收到窗口推送，但现有公开 `GET_CONTEXT` 和有界 `wait_for_window_progress` 足以在操作前建立基线、操作后自动判定 owner/accepted 变化。让用户再报一次“已按”是验收编排失误，不是 CJGUI 没有共享状态；后续同类前台验收先启动公开观察，再请人操作。

**指导限域复核（2026-09-28）。** 已读取 PNG 原反例/修后日志、三档向量及混合探针、并窗逐样本、正常生成 PNG 和公开 owner 日志、v11 导出记录，并核对对应持有/计数源码。未发现阻断上述范围的新缺陷；本次未构建、运行测试或操作桌面。PNG probe 使用真实 configure/setter 后直接提升 staged 数组，属于资源准入/交接证据；正常呈现继续以正常消费者为准。混合 probe 的 IMAGE 无实际纹理、效果仅有元数据，直接调用文字 prepare，故它证明跨 kind 不误 clone 与 COW 保旧，不能单独代表混合 PNG/效果的完整 GPU 复用。`reusableResourceBytes` 包含本窗文字/向量与共享图片缓存，不能将两窗值相加解释为独占驻留内存。生成日志缺逐笔目标 semanticId，已有输入到 owner 证据保留其前台目标归因范围，下一包补公共回执。

抽比 v11 与当前源码：diagnostics、shared workload 契约一致；native/window 已有 E 线的 `wheelScrollable` 和具名拒绝日志追加，因此本次接受已验证快照及未变机制，不宣布当前整仓重新全绿。真正 native 提交区间仍未覆盖，随下一包做一次有判别力的补证，不重复原文字准备钩子探针。

<a id="f-file-png-receipt-next"></a>
### F 下一包：提交阶段观测 + 本地 PNG 文件接收与目标回执（2026-09-28）

**目标与取舍。** 执行对象 F 框架渲染/通用能力线，工作目录 `/Users/jiangxuanyang/Desktop/cangjie`。保留刚交付的 PNG 持有交接、局部刷新和诊断；补真实提交阶段口径，并让普通应用能从 Finder 粘贴/拖入一个本地 PNG 文件，外部客户端能准确读到哪次接收作用于哪个 accepted 目标及 owner。当前 native 系统格式映射只有字符串与 `public.png`，文件 URL 接收仍是 F8 的实际缺口。这比继续重复稀疏刷新基线更能推进正常应用接入；本包不接管 E 的文档打开/插图持久化或 H 的触摸滚动。

**复用与借鉴。** 继续使用 `CjguiComposableUiDataTransferDeclaration/Event/Provider`、native eventId/bindingEpoch、`CjguiSharedOperationTransferOffer/AcceptRequest/Result`、owner CAS、PNG 准入和 candidate lease，结果回执仅是同一事务的投影。macOS 文件输入按 AppKit [pasteboard URL 读取选项](https://developer.apple.com/documentation/appkit/nspasteboard/readingoptionkey)及实际 SDK 声明接入；携带系统访问范围的 URL 按 [NSURL 访问生命周期](https://developer.apple.com/documentation/Foundation/NSURL/startAccessingSecurityScopedResource%28%29)管理，只有实际取得的访问才成对归还，不能把普通非沙箱文件一律当作需要 security scope。先使用本机 SDK/官方接口核实线程和访问要求；共同身份、事务和有界值留在仓颉，URL/文件句柄由窄平台适配器拥有。扩展当前机制，不另造文件仓库、业务 owner 或第二套传输服务。

**A．一次补清提交阶段与成本。** 给现有两窗探针加真实 native stage/present/command-buffer commit 的边界时间戳，按 session、scene/frame 和请求身份关联。区分 host turn、CPU 资源准备/编码/提交、GPU scheduled/completed；统一到可比较的单调时间域，不能直接比较未换算的两个时钟。旧 `native_stage_overlap` 按真实含义更名或兼容标注。受控闸门可证明 B 在指定边界进入公共队列、恢复后恰好到 owner/accepted，闸门等待不算自然性能。自然样本记录真实交叠数量、载荷和 ready→owner→scene，沿用 100/150 ms 判据；阶段太短未捕获则具名未观测，不伪造每阶段并行或无限复跑。已有布局在途的三组通过结果继续有效。若发现同步等待/GPU fence 占住 host，先按精确边界与原数归因再修机制，未决问题按 AGENTS 携证据升级指导，不先推倒调度或自动咨询。正常消费者只需复用现有最小诊断；细分不可得的 GPU 指标继续 unavailable。

**B．单个本地 PNG 文件进入既有传输链。** 在声明允许该来源的 PNG 接收目标上，支持 Finder 文件复制后粘贴、文件拖入两条系统路径；手写和生成目录共用来源能力声明、上限和拒绝原因。首片限定单个本地普通 PNG，格式取实际字节准入，不依赖扩展名；多文件/目录/非本地 URL/其他图片格式/文件承诺等明确报告本片未支持，不能悄悄取第一项。若同一系统 offer 同时含 PNG 字节和文件 URL，使用声明明确的选择顺序，一次接收最多提交一次。

主线程只取得平台输入及必要身份，文件读取在有界任务中执行，按既有 512 KiB 编码项、尺寸/像素、队列和资源上限准入。打开同一只读文件对象后检查类型/长度并限制实际读取量，不能仅 stat 后重新按路径无界读；文件消失、无权限、超限、短读或受控读取中变化时具名失败、原 owner/图像保持。读取完成形成不可变 PNG offer，再共用既有解码和候选持有链，不能走普通图片 loader 旁路。需要的 fd、URL 访问和候选资源在完成、取消、关窗和失败路径归还；异步开始就冻结目标窗口/绑定代次和预期 owner 版本，完成时重新核验，重排可保持同一目标、换绑/移除/关窗不能把旧结果交给新对象。不要把平台接收入队回包当作 owner 已接受。

**C．有界的精确目标与 owner 结果观察。** 复用或贯通现有事件身份，为一次人或外部接收提供稳定、按窗口实例区分的 receipt，最少包含来源类别、目标 semanticId/nodeId/绑定代次、格式/内容摘要、处理中或终态原因、实际 owner 前后版本，以及能证明的 accepted scene/frame 关联。同内容两次独立粘贴有不同接收身份，同一接收重复回调不重复应用。沿既有授权公开查询/变化入口与类型化客户端扩展，终态表与保留期有界，淘汰后明确 unknown/expired；读取不触发处理或提交。当前 provider 只回 `didApply`，不能靠布尔值猜 owner 版本，优先兼容扩展既有 `TransferResult` 或明确的 owner 回执适配。

直接 `public.png` 和文件 URL 归一后的接收都使用该结果投影。至少两个可区分目标分别操作，证明同一 digest 也能归因准确，重排/换绑后旧回调有明确终态。拒绝、取消、仅入队与业务已接受须区分；若多个 owner 更新合并进一帧，报告实际可证的 scene 关联或被后续状态取代，不能虚构每笔都独立呈现。使用正常应用的公开基线和有界等待自动收取结果，消除再让用户口头确认操作的依赖；本包不增加无界审计日志或第二套业务状态。

**D．两消费者一次汇合交付。** UI-only 与生成消费者均从正常入口声明图片接收；生成侧由真实公共客户端提交可接收文件来源的目标。完成 Finder 文件粘贴/拖入→实际预览→receipt 精确目标与 owner→公开读取；用含空格/中文文件名覆盖 URL 处理。正常消费至少覆盖一次正在读取时的目标重排/取消或关闭、非法 PNG/超限保旧、合法恢复；稳定交错可用受控 native 反例补足，分开记账。有效图片进入现有图像/效果混合场景，经真正 present 显示，并对照实际解码/资源/提交计数；这条新消费补足旧 mixed probe 的适用域，旧机制测试不重写。

记录读取/复制/解码/owner/提交的实际成本和有界工作量；异步读取期间另一窗带身份操作继续到 owner/accepted，held 实验与自然时延分列。包末按改动影响跑针对性反例、构建、公共客户端与一次含空格同源双消费者导出，固定源码/产物指纹。直接 PNG 原压力反例、向量三档和已验输入按影响复用。受控 scale、真实桌面输入、人工 VoiceOver、物理跨屏分别说明；后两项未验不改名通过。

**推进规则。** A 的阶段观测、B 的文件适配、C 的结果投影可按明确写集交错推进；核心并发/异步身份/资源归属方案先核源码与反例；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，Laya 辅助判断。普通 API/语法先读技能和现有实现。等待编译、咨询或资源占用时推进独立工作；同 target 构建与桌面协调串行。保留 E 的 `wheelScrollable`/文本与 H 后端改动，只在完整实现切面或新事实时短更本节、ACTIVE，包末集中报告，不增加逐轮台账。未经要求不 stage/commit/push。

**执行结果（2026-09-28；Finder 真拖入尚待前台补证）。** A：TESTING 时间线现以同一 native 单调时钟记录精确 session/scene/frame 的 stage、encode、present、commit、GPU scheduled/completed。自然 recolor/image/geometry 各 20 笔的 B owner/accepted 上界 p95 分别为 `75/92`、`73/91`、`71/89 ms`，均满足 100/150 ms；真实 CPU 提交交叠为 `0/60`，不声称自然重叠。present→commit 的 41,000 µs 受控闸门中，B producer 于闸内投递，B owner/accepted 为 `54/71 ms`，闸门等待未混入自然分位数；原始 `/private/tmp/cjgui-f-file-two-window-gate.log`。B/C：普通 PNG 目标按声明接受单个本地 `public.file-url`（512 KiB/项、4 在途、2 MiB 全局预留），单 fd/O_NOFOLLOW/本地普通文件检查和有界异步读取后进入原 PNG 准入与 owner CAS；同项 URL+PNG 只取声明的 URL 优先路径。回执沿现有授权入口按窗口 session+event 查询/增量读取，保留 64 项及明确 unknown/expired，记录源、accepted 目标与代次、digest、owner 前后版本和可证 scene/frame；异步完成保留捕获身份，重绑旧结果取消，队列满时为在途读取预留终态槽。native 受控 paste/drop、混合 offer、多文件、超限、held-read→重绑探针通过（`/private/tmp/cjgui-f-file-native-final.log`）。

**正常消费与同源产物。** Finder 含空格/中文文件的实体 `⌘V` 已在 UI-only 与生成消费者分别到真实彩色预览和公开 owner；生成窗同 digest 的生成目标 `component-4-1` 与手写目标 `collaboration-png-target` 分别得 event 1/2、owner `0→1→2`、scene/frame `6/6` 与 `28/28`。生成目标非法 27 B 文件保留 v2 图/owner，event 3 回执 `rejected/png_invalid`、owner 未尝试；UI-only 超 512 KiB 保旧并报 `file_payload_too_large`。首笔文件实测 read/copy/decode/owner `109/5/201/16 µs`；第二笔 `136/1/200/2 µs`（`/private/tmp/cjgui-f-file-generated-accepted-app.log`）。CJGUI `377/377`、shared core `69/69`、生成消费者 `37/37`、Python 客户端 `33/33` 通过；含空格导出 `/private/tmp/cjgui-f-file-export/Spaced Preview Workspace 20260928-1/CJGUI Framework Preview`，100 项载荷（90 同字节/10 预期改写）SHA-256 `4341ab1a3ecebbf9919f832b494adebcaf1078f91ed507ba07b2b7554d9abb02`，两消费者从该份构建并各跑自验 `15/15`、`13/13`。Finder→应用的真实拖入在桌面接口报告 Mac 锁定前未得到系统事件；仅 native 生产回调受控 drop 通过，故此项明确未验。旧直接 PNG/三档稀疏刷新有效基线保留；E/H 并行改动未覆盖，未 stage/commit/push。

<a id="f-file-png-receipt-review"></a>
### 文件 PNG 包指导复核与接续（2026-09-28）

**裁定与范围。** 本次核对当前源码、native/两窗/正常应用日志和导出记录，未重跑 CJGUI 构建或桌面。保留两消费者系统文件粘贴、event 1/2 的精确目标和 owner `0→1→2`、event 3 非法 PNG 保旧、自然三组性能及导出自验的已有证据。源码另暴露下列生命周期缺陷，所以本包不仅缺 Finder 真拖入，A–D 仍需接续。均由 F 在原包内完成；E 的编辑器/文本与 H 平台接线继续独立推进，F11 亚点平移保持后续顺序。

| 当前源码事实 | 影响与应建立的判别反例 |
| --- | --- |
| native `CjguiReadLocalPngFileAsync` 在进程共享串行队列先 `open(O_RDONLY)`，再 `fstat/S_ISREG`；取消检查更晚 | 无 writer 的 FIFO 会卡在打开阶段，后续合法文件及关窗取消无法使该任务退出。指导用相同打开标志做了独立 OS 小实验：300 ms 内不返回；加 `O_NONBLOCK` 可返回并判非普通文件。这不是 CJGUI 端到端反例，执行时需证明“FIFO 具名拒绝→同进程另一窗合法 PNG 成功→资源收敛”。 |
| `start()` 换 `windowSessionIdentity`，native eventId 从新 session 重新计数；`receiptIndex/begin/settle` 却只按 eventId，旧表/水位仍在 | 同窗口对象关闭再启动，新 event 1 可被旧 event 1 挡住，owner 已应用但新 session 无回执。建立 close→start→两 session 各自 event 1 的公开读回反例。 |
| `beginTransferReceipt` 超 64 项直接删最早项，未区分在途；过期项的重复回调仍可进入 owner 调用路径 | hold 第 1 笔文件读取，处理 64 次其他接收后释放：原在途项必须仍能结算；另验证旧回调在 owner 前去重，以及真正耗尽容量时的具名准入结果。native 终态队列预留不能代替仓颉回执保留。 |
| `settleTransferSceneReceipts` 对 `owner_accepted/superseded_before_scene` 每帧重新加 revision | 一笔 owner v1 被 v2 抢先呈现后，仅动画/resize 就不断生成相同回执变化。反例应证明首次标记后 revision 稳定，保留真实 owner 结果而 scene/frame 仍不可用。 |

**1．修文件读取准入与生命周期。** 复用单 fd、有界 buffer 和统一清理出口：worker 开始先判取消；以非阻塞打开方式取得 fd 后判定普通本地文件，必要时调整 fd 标志再执行有界读取。类型准入不应被 FIFO 打开阻塞。现有 gate 在 `open` 前，只证明捕获身份不变；补一个仅测试的“已打开且首段 read 完成”闸门，覆盖中途截断、路径替换和关窗，逐项核旧 owner/图像保持、具名失败或窗口退役、fd/实际取得的 URL scope/预留归还，以及另一窗口仍可接收。读取前后变化检查纳入适用的 ctime 等事实，并写清检测边界；stat 前后相同不等于绝对不可变文件快照。本片产物仍是有界读取得到的不可变字节 offer，共用现有 PNG 解码与 owner CAS。

**2．统一回执身份、保留与终态。** 查找、结算、去重和淘汰统一按窗口 session + event 身份；明确旧 session 查询的保留/过期策略，避免重开复用旧水位。在途项有界固定保留、终态按预算淘汰；满额时先裁决新接收，不能在 owner 写入后才发现无处记录。淘汰水位必须兼容乱序完成，不能因高 eventId 先完成就把较早在途项当过期。保留现有公开 schema 的兼容性，`superseded_before_scene` 只结算一次；相同终态重复到达不增加 revision。上表反例覆盖普通字节 PNG 与文件 URL 共享的入口，公共客户端读取证明观察不会触发处理或提交。若身份/容量方案仍不明确，先用这几个反例归因，按 AGENTS 携未决证据升级指导；方案明确后连续实施，不自动咨询。

**3．补齐提交观测的精确边界。** 原闸门日志中 `producer_post=1195884991375` 在闸内，但 `native_enqueue=1195885045541` 晚于 `gate_end=1195885030666` 及 `commit=1195885030708`。源码由 `dispatch_async(main)` 后才调用 `CjguiEnqueueComposableInteraction`，因此成立的是“闸内向主线程投递、释放后进入框架并到 owner/accepted”，尚未证明原 A 要求的公共队列闸内接收。复用已有真实公开请求/owner 队列链做一笔受控判别，记录实际接收/入队位置、请求身份、释放后 owner 恰好一次及 accepted；无需为观测另造调度器。若实际队列也受主线程约束，如实报告这项机制事实及响应结果，再按原预算判断是否需要调度修改。补区分 commit 调用前/返回后（现 `commitCallMicros` 实在返回后采样）；scheduled/completed 是 host 回调时刻，不能当 GPU 执行或物理呈现时刻。原 60 笔自然样本保留，口径为 producer post→owner/accepted 观察上界；0/60 不要求反复重跑变成非零。

**4．完成正常系统消费后一次汇合。** 在同一最终版本的 UI-only 与生成消费者补 Finder 真文件拖入，取得系统 drop、accepted 目标及代次、唯一回执、owner 精确读回和可见图片；复用已验文件粘贴，不要求用户口头回报。使用独立可辨识窗口和含空格/中文文件名，桌面操作协调串行；锁屏时记录边界并推进上述独立代码。当前导出记录中的 Finder 输入来自作者目录应用，导出应用证明的是构建和自验，二者分别引用；最终导出至少让两消费者的文件输入/回执经过实际运行，修正后指纹覆盖相应源码。按影响跑新增反例、构建、公共客户端和一次包末同源导出，原 PNG 压力、向量三档和未受影响输入证据继续复用。

**执行方式。** 这是 F 原 A–D 的完整接续，不逐个缺陷停工请示。普通实现直接推进；生命周期/并发与公共身份契约先核源码与反例，问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型；Laya 仅辅助判定。编译/咨询等待时做未阻塞的实现，确无独立工作时再等待。只在形成可消费切面或新事实时短更本节和 ACTIVE，包末集中报告代码、反例、真实消费及剩余边界。

**F 接续结果（2026-09-28）。** native 文件 worker 在打开前检查取消，以 `O_NONBLOCK|O_NOFOLLOW` 打开后核普通文件，并核读前后 fd/路径的大小、设备/inode、mtime/ctime；首段读取后测试闸门覆盖截断、路径替换和关窗。FIFO 在同进程另一窗合法 PNG 之前得到具名拒绝，不再占住共享队列；测试核 fd、实际取得的 URL scope 与预留归还。边界是读前后元数据校验及最终不可变字节 offer，不声称获得原子文件快照。回执改为 session+event 精确查找/去重，以 native 首次投递序号拒绝重放；63 个在途固定保留并预留一个容量拒绝的终态槽，满额在 owner 前裁决，终态按 revision 淘汰并保留有界精确 tombstone。旧 session 在保留期仍可查；tombstone 保留期返回 expired，tombstone 自身淘汰后返回 unknown；superseded 只结算一次。新增五个仓颉反例（重开 event 1、held-read 跨 65 个终态、乱序较低 eventId、容量拒绝、superseded 后多帧）均通过；CJGUI `382/382`，native 传输探针通过，`cjpm build --skip-script` 通过。受控公共请求 `SET_PREVIEW_LIMIT` 的真实 UDS `ready` 在 native 闸内：`gate_start=1201769320083`、`ready=1201769321718`、`gate_end=1201769371208 µs`（ready 相对基点 `2802 µs`，由 MonoTime 顺序采样映射到 native 时钟；精度边界见下方复核）；释放后 owner 版本 `0→1`、accepted scene `1→2`、`pump_rounds=1`、恰好一次。旧主线程 post 闸门仅保留其原口径。commit 现分别记调用前与返回后，GPU scheduled/completed 仍仅指 host 回调。最终两窗探针 60/60 在途、CPU 提交自然交叠 `0/60`；recolor/image/geometry 的 owner p95 `72/77/73 ms`、accepted 观察上界 p95 `90/94/90 ms`，20 个 scale 样本通过；原数 `/private/tmp/cjgui-f-receipt-two-window/probe.log`，受控请求 `/private/tmp/cjgui_public_submit_gate_run4.log`。

**最终正常消费与导出。** 同一份含空格导出 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260928131320-62070/CJGUI Framework Preview` 的两款应用均实际运行。Finder 的 `中文 文件 PNG.png`（80 B、3×2）拖入 UI-only `adaptive-png-target`：公开 session `cjgui_window_11727198779088584430_1`、event 1、`local_file_url`、owner `0→1`、accepted scene 146、revision 3；AX 与画面显示 `PNG v1` 和彩色预览。生成应用先有一次落在手写目标的 event 1，随后生成目标 `component-4-1` 的 event 2 与 event 4 均得到文件来源的 accepted 回执；event 4 为 session `cjgui_window_7602123560637981538_1`、node 804001、binding epoch 2、owner `3→4`、accepted scene/frame `687/687`、revision 12，公开精确读取三次不增加 revision，AX/画面为 `PNG v4` 和同一彩色预览。两款 owner digest 都为 `fnv30x2:212259688:130720502:80`；本轮 decode/owner 原数 UI-only `258/15 µs`、生成 event 4 `177/2 µs`，文件 read/copy 本轮正常应用日志未单列，沿用原包已列的独立样本。两测试进程结束为 0；导出脚本两消费者 build/run、自验、注入拒绝均通过，产物指纹见该目录 `CONSUMER_FINGERPRINTS.txt`。生成侧首次监视时前一笔拖入落在手写目标，等候生成目标超时；后续生成目标以精确回执及稳定读回补验，不把它记为预先订阅观察。系统文件粘贴、拒绝保旧和旧 PNG/稀疏刷新原证按原范围复用。未 stage/commit/push，E/H 写集保留。

**指导限域复核（2026-09-28）。** 已检查上述生产分支、反例、原始日志和最终导出身份，未重跑构建或桌面。文件读取和回执机制未发现新的必须返工缺陷；两款导出应用的真实 Finder drop→owner→可见图片按已有证据保留，不再要求用户重复拖入。以下为证据口径补正，不撤销本包已成立的消费链：① tombstone 也有 64 项上限，保留期间可返回 `expired`，其自身淘汰后是 `unknown`，不是永久过期查询；② `ready` 来自生产 UDS 排队成功处的 MonoTime，经顺序采样基点映射到 native 单调钟，上文“同一时钟”不准确。gateStart→创建新 marker→客户端发送→队列 ready 的因果链与保守上界支持本轮闸内接收，但映射值不是原始同钟精确打点。自然两窗样本起点为 producerPost，60/60 是 A 整个 host turn 在途，CPU 提交自然交叠仍为 0/60；③ 生成 event 4 的 owner 日志、最终导出身份与用户真实操作已对应，本次未定位到后补 event 4 精确公开回包的独立归档，下一包补存已有原始输出及索引，不据首次超时日志冒称精确回包通过。当前并行工作树继续变化，本结论不替代后续源码的集成验收。

<a id="f-subpoint-translation-next"></a>
### F11 下一完整包：accepted 亚点平移与统一几何消费（2026-09-28）

**目标与归属。** 本包由 **F 框架线**执行：使普通手写、命名样式、组合及生成界面都能以逻辑点的小数位移移动子树，画面、裁剪、点击、无障碍和文字定位一致。复用当前 Int64 布局及 `offsetX/offsetY`、accepted 场景事务、文字几何查询、效果缓存与诊断，不把整套布局改为浮点，也不另造渲染器。首片仅做有界二维平移；旋转、缩放矩阵、共享元素转场另按实际需求安排。E 继续负责编辑器与文本会话机制，H 继续负责鸿蒙输入/滚动；本包补它们可复用的通用几何能力。

**A．带上两个小收尾，然后连续实施。**

- 修正 `interaction_scheduling_efficiency_probe.cj` 的 ready 时钟观测：优先在真实队列 ready 边界使用与 native gate 相同的单调钟；也可对跨钟采样前后夹取，公开不确定区间并要求整个区间落在 gate 内。用一笔受控真实公共请求验证即可，保留原 owner/accepted 恰好一次和自然 60 笔样本。去掉未经实测的固定 1 ms 误差假设，区分原始值、映射值和因果见证。
- 从原任务已有输出补存生成 event 4 的 session/target/owner/scene/revision 三次精确读回及来源索引。若原输出确实不可恢复，明确这部分是执行报告记录而非已归档原始回包，保留其余真实拖入证据；不让它阻塞 F11，也不再要求用户重复操作。

**B．定义一份可接受、可查询的浮点平移事实。**

- 新增明确命名的二维平移声明（Float64、单位逻辑点、默认零），保持旧整数 offset 的兼容语义。先统一有限值、单项幅度、累计幅度和算术溢出准入；非法值具名拒绝整个候选并保旧。坐标按层级组合一次：布局位置/旧 offset + 父级累计平移 + 自身平移，避免同一偏移在布局、stage、paint 中重复相加。平移不改变节点尺寸、兄弟排布或业务身份。
- resolved 平移与正逆映射属于 accepted 几何；候选提交成功才发布，拒绝保留旧值。复用已有 `geometryTransformVersion` 等身份维度，使 caret/range/命中查询能对应同一 accepted 排版与变换。既有整数 `acceptedNodeBounds` 保持明示的兼容语义，新增或扩展明确的浮点视觉几何查询，不能把截断值宣称为精确呈现位置。
- 手写、完整命名样式、生成描述和组合组件共用定义与严格准入，公共目录发布单位、范围、清除/继承和后端支持。复用 `CjguiComposableUiStyleWithPaint` 等现有复制入口；paint-only 角色只改 paint，须保留 base 平移，不能顺带覆盖几何。接通声明判等、缓存依赖、生成 strict parser、样式修订和视觉中性快路径。
- 优先使用附加的、候选事务内的 transform staging 窄接缝，使既有 FFI POD 布局和 H snapshot 保持可辨识兼容。若确需修改 POD，则先确定版本/布局检查与所有使用方适配，不能只扩 macOS 镜像。首包公开标明 macOS 支持、未接入后端不支持；非零声明不得静默吞掉。

**C．同一变换贯穿绘制、裁剪和输入。**

- native 绘制、效果输出范围、调试叠加、AX frame、指针命中逆映射、caret/range 与 IME 候选窗定位均消费同一 accepted 几何。逻辑点到设备像素、窗口到屏幕各由统一出口转换，按实际 scale 保留浮点位置和边缘覆盖，不能先统一取整消掉亚点位移。当前 native pointer/公共事件存在整数坐标，补兼容的精确坐标接缝，保留到逆映射完成；只把画面画到小数位置不算交付。
- 每个祖先 clip 使用**产生该 clip 的祖先**的变换：移动子节点不会把父 clip 一起移走，移动裁剪祖先才会带动它。文字、图片、圆角和阴影共用正确裁剪；效果输出范围可超本体，命中仍按实际可交互本体与 clip。跨边界时不能出现“画面消失但旧位置可点”。
- 排队输入保留其 accepted 目标身份及解释坐标所需的变换事实；换绑/退役沿原契约拒绝，避免用新变换误解释旧事件。单纯平移不重开文本会话、不清草稿/选区、不产生 owner 写入。E 的组字生命周期继续由 E 实现，本包仅接回 accepted 几何出口。
- 纯平移在文字、宽度、scale、样式不变时复用正文测量/排版/纹理及图片资源；不因位置变化把全文加入新的纹理键，也不为平移默认增加离屏层。裁剪、背景 blur 采样位置等真实依赖仍需正确失效。分别记录 build/layout/text prepare/raster/upload/submit；允许位置改变产生必要 scene/Metal 提交，不能用不提交掩盖画面未动。

**D．两个正常消费者与有判别力的包末验证。** 复用 `adaptive_layout_public_consumer` 和 `generated_panel_consumer`，沿真实公共入口接入；新能力自身带以下闭环，PNG 包原证按影响复用：

| 场景 | 必须证明的行为 |
| --- | --- |
| 父 `(0.25,0.5)`、子 `(-0.75,0.25)`，再叠旧整数 offset | 浮点矩形、画面、AX 和文字定位累计一致；零平移维持原行为。大位移使新旧命中位置可区分，小位移用精确边界反例验证，无须要求系统鼠标能投递任意小数像素 |
| 移动子树及移动裁剪祖先，两者分别验证 | 圆角祖先 clip、文字/图片/阴影与实际点击一致；旧位置拒绝、新位置激活同一 owner，效果带不扩大命中 |
| 非空草稿/选区期间平移，再正常输入和外部改值后续写 | caret/range/候选定位更新，目标和会话仍是原实例，owner 精确读回；保留原组字协议及业务版本规则 |
| 手写与公开客户端生成/修改/清除；非法值及受控 native 拒绝后恢复 | accepted 版本、变换、画面、命中与 AX/文字查询原子保旧；命名样式/组合传递不丢平移；合法恢复真实可操作 |
| 仅平移连续更新、停止、移除及关窗 | 简单场景复用文字/图片资源，背景采样场景按真实依赖更新；计数与资源预算有界，停止后不持续提交，另一窗口身份/画面不被污染 |

受控 1×/2× 下核亚点边缘与裁剪像素；正常桌面按本机实际 scale 验真实点击/文本和 owner，受控 scale 不称为物理跨屏。成本取固定负载的零平移、静态平移、连续平移原数与工作量，先看瓶颈再决定优化，不重建全套性能平台。包末一次受影响构建、定向测试/原生反例、公开客户端和含空格同源双消费者导出，固定源码/产物身份并在导出应用实际消费新能力；未受影响的 PNG 压力、旧三档向量和输入原证复用。

**参考机制与实施节奏。** 按 [本地开源实现参考](DESIGN_INTENT_INDEX.md#本地开源实现参考)定向查 Flutter `proxy_box.dart` 的 `RenderTransform.hitTestChildren/paint/applyPaintTransform` 及两个 `transform_test.dart` 的往返、嵌套命中和纯平移不增层用例。指导本次核对本地 `8db55268667c`：借鉴统一有效变换、逆映射、纯平移直接绘制和边界测试；CJGUI 保留自身 accepted 事务和整数布局，声明单位是逻辑点，不照搬 `RenderFractionalTranslation` 的尺寸比例语义。只借思路，不引入参考框架依赖。先读关键符号和测试，前提不变复用结论；新反例涉及其他机制时自行定位相关参考，不等导航补齐。

几何归属、queued event、FFI/缓存契约存在实质歧义时，由当前执行者结合精确源码与区分反例归因；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，普通接线直接实施，Laya 辅助判断。共享 `composable_ui.cj/window.cj`、native 文字几何等符号先协调单一写入者，其余声明/测试/消费者并行推进；同 target 构建与前台串行。等待编译或咨询时做独立必要工作，已有通过且未受影响的验证直接复用。只在形成真实切面或新事实时短更本节与 ACTIVE，最终集中报告，保持 E/H 在途改动与两仓未提交状态。

**F 执行结果（2026-09-28，macOS 范围）。** A：公共队列 ready 采样改为单调钟前后夹取并做精确刻度换算，一笔受控请求的 ready 区间 `1204572450209..1204572450214` 完全位于 native gate `1204572448950..1204572500176`，owner/accepted 各一次；保留自然 CPU 提交交叠 `0/60` 的原范围。已从原会话输出归档生成 Finder event 4 的公开回包：`session=cjgui_window_7602123560637981538_1`、`target=component-4-1/node=804001/binding_epoch=2`、`owner=3→4`、`scene=687→703`、`revision=12/stable_reads=3`，原解析记录 `/private/tmp/cjgui-f11-event4-public-original.txt` 指向原会话行；原始协议字节当时未单独保存，故只称公开客户端解析回包。

B/C：公共 `translateX/Y` 为逻辑点 Float64，默认零，单项 ±1024、累计 ±4096，非法候选具名拒绝并保旧；旧整数 offset 和 `acceptedNodeBounds` 语义保留，新增精确 `acceptedNodeVisualBounds`。手写、命名样式、组合、生成 strict 解析共享声明；accepted 几何附加 staging 保持旧 FFI POD，native 绘制/祖先 clip/效果范围/AX/精确指针与文字 caret/range 消费同一变换，排队指针保留当时目标与精确坐标。纯平移复用正文布局/纹理及图片；效果组与背景模糊缓存键加入变换依赖。判别反例先见组缓存和背景缓存错误命中，修后受控 1×/2× 边缘、`1.49` 未命中/`1.5` 命中、父 clip、AX、排队事件和拒绝恢复均通过；背景源仅改 `0→0.75` 时采样红值 `246→249`、重绘 `1→2`，静态下一帧命中缓存。中性组切页的旧 clip 复用另造成原窗口测试 `57` 失败，补比较 clip owner/几何后 `cjpm test --skip-script` 为 `390/390`；最终 native 定向反例、受影响窗口测试与 `cjpm build --skip-script` 通过。

D：两款正常应用及公开生成客户端在本机实际运行；手写真实点击移动组的新位置激活原 owner、旧位置拒绝，生成应用真实键盘/选区在平移及外部写后继续写回同一 owner。两窗公开实验 A 平移 `0.25→30.25→0.25`、B 保持 `0.25`，关闭 A 后 B 可读；生成客户端版本 `1→2→3→4` 经过大位移、非法值拒绝、清除、恢复。最终含空格同源导出为 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260928154937-84200/CJGUI Framework Preview`，`CONSUMER_FINGERPRINTS.txt` 为 `v12`，关键框架/native/消费者源码逐文件与工作树相同，两个导出消费者、公开平移和原效果/材质/诊断受影响入口均 PASS。最终导出手写连续 9 样本：build `175–293 µs`、layout `611–1075 µs`、submit `4.912–5.780 ms`、全样本 `text_prepares=0/decode_starts=0`，空闲 `154 ms` 后 submissions `23→23`；生成大位移为 build `319 µs`、layout `562 µs`、submit `5.922 ms`、文字准备 1 次（结构变化）、图片解码 0。导出日志见 `/private/tmp/cjgui-f11-spaced-export-final.log`。旧 P4 独立 `composable_effect_group_probe` 沿用过时的窗口背景 staging 前提，当前停在 `stage_group_isolation`，故不计为本轮通过；F11 native 组/背景缓存反例及最终导出公共效果链均通过。系统 IME 候选窗的实体视觉跟随、物理跨显示器与 H 后端未由本包证明；F 不代替 E 的组字生命周期，也不把受控 scale 称为跨屏验收。未 stage/commit/push。

<a id="f-translation-containers-bounded-text-review"></a>
### F11 第二次指导：可平移交互容器与有界文字 A–E（2026-09-28）

**阶段判断。** 亚点声明、附加几何 staging、clip owner、绘制/精确命中/AX/文字查询、两消费者与公开候选已实质接通，保留首包成果。本次指导核对源码、测试和原始记录；独立复算最终导出框架源码/native、两消费者源码和两 app bundle 六组指纹均一致，没有重跑 cjpm 或操作桌面。现有证据尚不能把“统一坐标”推广到所有框架控件，且新增了文字预算回退。因此 F 下一包先交付**可平移的 scroll/split 与长文本窗口**，让已实现的公共能力在普通交互中完整可用；随后再接 P2 连续位置动效，避免放大当前坐标/资源问题。E 继续正文、组合生命周期与共同操作，H 继续触摸机制，本包不接管这两条线。

| 本次复核 | 依据与适用范围 | 接续判据 |
| --- | --- | --- |
| 分栏拖动未逆变换 | `composable_ui_window.cj` 的 `dispatchPointerEvent` 仍将整数全局 `pointerX` 传给 `applySplitStatePointerDrag`；后者用未平移 `node.bounds.x` 求轨道原点。native 的兼容坐标是全局点取整，精确点/平移另存 | 父平移 `+100.25` 后，在隔条同一局部位置按下不改变栏宽；拖动、反向和 resize 仍用同一 accepted 尺寸规则 |
| reveal 未使用视觉几何 | `revealAcceptedNodeIfNeeded` 比较 `target.bounds.y` 与 `container.bounds.y`；子平移移出父 clip 后仍可能判“已可见” | 子移父不移、父子同移、嵌套 clip 各按实际祖先坐标求 reveal；可达目标真正进入可见区，失败/无可行滚动不循环刷新 |
| 非零平移强制全文纹理，确定预算回退 | `CjguiComposableGeometryNeedsFullTextCoverage` 与 `CjguiComposableTextTextureRectForNodeWithText` 使非零节点/clip 平移改取整节点。无窗口、原样提取生产函数反例：[原始结果](/private/tmp/cjgui-f11-text-review-jyfyi2lk/result.log)：同一 `1000×10000` 节点、`1000×400` clip，`0` 平移计划 `1,600,000 B/admitted=1`；`0.25` 平移 tile 计划失败、`admitted=0`。这不是整应用实跑证据，也不是内存已超限的证明 | 按变换后可见范围准备有界 tile；小平移不因节点全文高度触发预算拒绝；新露出内容准确，旧资源/失败事务安全 |
| 排队输入原证未覆盖跨接受边界 | `composable_translation_native_test.m` 在入队后立即 pump，之后才接受新变换；core 目前拒绝旧 projection，属于安全拒绝 | 先入队→接受新平移→再 pump，明确原事件安全结算；换绑/退役不能落到新目标。保留版本守卫，不能用新变换解释旧坐标 |
| 旧 P4 探针入口失配，成本口径需校正 | `composable_effect_group_probe.m::present` 漏同版本窗口背景 staging；native 在场景 commit 前返回 `99`，故 `stage_group_isolation` 尚未检验隔离。正常 F11 成本日志部分动作含两次提交却只记最后 refresh；正常消费者未独立给 raster/upload 增量 | 修正确保能进入原断言的夹具，保留效果判据；区分单次尝试与动作累计成本，补有界文字的资源工作量 |

**A．把内置交互接到同一 accepted 坐标出口。** 复用现有 `CjguiComposableUiVisualGeometry`、精确事件坐标/捕获变换、完整绑定身份及整数布局。先固化上表 split/reveal 反例，再给框架自有消费者一个明确的窗口点↔目标/轨道局部点转换出口；逆映射完成之后才进入旧整数尺寸规则，按既有规则量化，不能在调用点分别减常数补偿。对滚动需求使用目标和每个真实 clip owner 各自的 accepted 变换，向能保证可见的方向取整；父子共同移动应相互抵消，移动子树不得移动父 clip。保持嵌套由内向外、兄弟视口不抢占的既有语义；平移不自动扩大 layout extent，超出可滚范围时具名/有界结束，不伪报可见或永久请求新帧。拒绝候选保持旧几何、焦点与视口请求，合法恢复可继续。

输入边界随同一切面补齐：先入队再接受几何变更，至少覆盖按钮与一次捕获拖动、换绑/移除后旧事件；冻结事件解释所需事实，观察实际 owner 与选区结果。既有旧 projection 安全拒绝可保留并明确记录，不能把它写成“旧事件接续成功”；如同一合法拖动的正常反馈确实被自身刷新打断，再针对完整绑定/捕获代次设计接续，不移除 owner CAS 或盲改事件版本。E 的文字事务保留；F 负责坐标和控件路由。

**B．用局部覆盖恢复长文本预算，而非全文预热。** 复用当前文字布局、tile、预算 admission 与候选持有机制。将可见窗口及每个祖先 clip 用其 owner 变换映到文字局部空间，形成保守矩形覆盖，加有限的字形/抗锯齿余量；圆角精确裁剪仍在实际绘制链实施。内容/样式/宽度/scale 决定正文准备，tile 覆盖决定栅格资源，平移决定绘制位置，三者分别建依赖。平移在已有覆盖内复用原资源；新露出区域只补必要 tile，不承诺跨任意距离都零 raster。可采用固定局部 tile 网格/小范围 guard，需说明 tile 归属与回收，不新建整套排版引擎。

移除“出现非零平移就取全文”及归零后永久保留全文覆盖的策略；共享/缓存命中与在途引用仍计入现有预算，候选失败只释放自身准备、不损害 accepted 画面。反例覆盖 `0→0.25→0`、父 clip 平移、连续跨 tile 边界、clip 内外往返、活动及非活动文字、空输入、中文/emoji/样式背景；头/中/尾可见标记及 seam 与同版强制重算对照。上述 `1000×10000/1000×400` 必须恢复为有界可接受；先做生产机制反例，再带入正常可滚容器，不把放宽 24 MiB 或缩小原负载当修复。仅恢复这条平移消费所需资源机制，Markdown/GB 存储、E 的整体解析不在此包。

**C．修复受影响的既有探针与观测，一次完成。** P4 helper 接同版本窗口背景声明，使其走到原隔离/嵌套/mask/multiply/缓存/预算/fence 判据。各对照使用实际裁剪后的分配量；预算负例必须确实超预算，缓存热态必须保持真实 clear color 等依赖相同，另保留改变依赖必重算的负控。只修过时前提，若进入生产路径后仍有实际失败，定位对应机制后处理，不降低像素/生命周期要求。

成本按同一操作起止采样已有累计计数，分列 build/layout/text prepare/raster/upload/decode/submit 及所需资源 live/peak；多次 refresh 的最后一次和整次累计明确区分。重复观察不能产生额外提交。沿原固定负载比较零平移、静态平移、覆盖内连续平移及跨 tile 平移；只将原 `175–293 µs/611–1075 µs/4.912–5.780 ms` 保留为旧日志的 refresh 样本，不外推为整次交互成本。A 包 ready 时钟夹取和 Finder event 4 解析回包归档可接受，原字节未保存的边界保留，无需重做 Finder 操作或原 60 笔负载。

**D．两个正常消费者完成同一真实链。** 复用 adaptive 与 generated panel，加入共用的可平移 scroll/split 内容和受裁剪长文字，保留原 PNG/效果/owner。手写及公共生成候选均消费声明；至少由正常指针拖隔条、键盘导航屏外字段、平移后继续输入/外部修改后续写驱动，公开读回同一 owner。活草稿/非空选区期间平移和一次拒绝→恢复，核 caret/range/AX 与画面；单独检查系统组字中的候选定位查询与实体视觉跟随，工具能观测到才标通过，不能用静态 `firstRect` 查询替代实体候选窗证据。已有源码会重定位 proxy frame，不能因缺显式通知就断言系统必错；发现实际滞后再查 AppKit 坐标失效契约，修改保持在几何适配面。

同 host 另一窗用原公开队列少量可归因请求核响应、关闭隔离和停止收敛；本包不重建性能平台。包末从最终同源含空格导出运行两消费者，保留输入来源、源码/产物身份、owner 精确值和图像证据；定向原生/框架反例、受影响 build/test 与一次汇合完成即可，未影响的图片压力和旧图表原证复用。物理跨屏、VoiceOver、H 支持仍按各自边界；本包成功不自动关闭它们。

**E．机制参考、问题升级与推进。** 沿 [本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)，复用已读 Flutter `RenderTransform` 与 transform tests，补读 [viewport.dart](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/rendering/viewport.dart>) 的 `getOffsetToReveal/showInViewport`：先变换到目标祖先坐标，再判断显露及可行滚动，不能混 layout/visual 两空间。本次核对本地 `8db55268667c` 的相关符号；CJGUI 仍保留整数 viewport、accepted 事务及自身 tile，不照搬 Flutter 的 sliver/组件树、不引入依赖。文字覆盖先核现有 CJGUI tile 与 admission；现有机制解决不了的新问题再定向查一个相关成熟实现，不通读参考仓库。

普通接线直接做；缓存覆盖/候选资源归属或捕获版本方案有实质歧义，由当前执行者结合本页原反例及必要源码归因；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型。已明确的修复直接实施，已有模型答复仍以实现和反例验证。批量可复核日志分类可用 `laya-ask`，明确规则直接判断；分类不能替代源码、根因与实际验收。A 与 B/C 可按符号写集交错，native 同一段由一个执行者集成；同 target 构建、桌面串行，等待期间做独立必要工作。形成可消费切面或新事实再短更本节与 ACTIVE，包末集中报告，不新建执行卡/逐轮长日志。保留 E/H 在途改动和未提交状态。

**本包实施与定向证据（2026-09-28，F）。** A：split 拖动经 accepted visual geometry 映到 track，再按既有整数尺寸规则量化；reveal 使用目标与各真实 clip owner 的 accepted 变换，内向外求可达滚动。捕获绑定/手势代次、split revision CAS 与同一合法拖动跨自身接受刷新接续已入框架；旧版本排队输入保留冻结身份，换绑/退役安全拒绝。稀疏 COW 下 scene 21 复用 scene 20 的 POD 时，入队事件仍标 scene 21；native 排队/换绑反例通过。另以真实窗口反例确定单视口自身 clip 必须随目标滚动；双层排队请求若把目标移出内层 clip，撤销该请求并求满足两层的偏移，若同时满足两层则保留原请求。五项新判别及两项原嵌套身份回归均通过，分别见 `/private/tmp/cjgui-f11-green-*.log`；不可行与可行排队请求的原始 RED 输出保留在 `/private/tmp/cjgui-f11-final-reveal*.log`。生产路径前台手写分栏 `360→410→360`、滚动 `0→540` 的旧源码实例原证见 `/private/tmp/cjgui-f11-review-adaptive-capture-continuous.log`，不混记为最终导出实例。

B：native 文字改用固定局部 `512×256` tile，先以各 clip owner 的 accepted 变换求可见覆盖，再复用旧 tile；正文布局键与 tile 覆盖分离，候选失败保留 accepted 资源，预算仍为原 24 MiB。同一 `1000×10000` 文字和 `1000×400` clip 在 `0→0.25→0` 平移均可准入；跨边界只新增 2 次 raster，1×/2× 中文与 emoji、空文字、回滚和逐像素合成对照通过（按场景行序CPU合成 `scene_pixel_diff_bytes=0`、接缝相等；非Metal drawable读回）。原生输出：`/private/tmp/cjgui-f11-review-translation-cow2.log`、`/private/tmp/cjgui-f11-review-text-tile-run.log`。

C：旧 P4 夹具补齐同版窗口背景 staging，隔离/嵌套/normal/multiply/mask/背景缓存/预算/在途 fence 原断言全部通过，见 `/private/tmp/cjgui-f11-review-effect-probe-final.log`。最终同源导出自验手写 9 次整操作：build `176–242 µs`、layout `697–915 µs`、累计 submit `2.136–10.142 ms`、elapsed `15.359–24.443 ms`，部分动作有 2 次提交；最后 refresh 单列，`text prepare/raster/upload/decode=0`，文字 live/候选峰值均 `4,713,056 B`。生成远移一次 build `360 µs`、layout `569 µs`、submit `2.084 ms`、文字准备 1 次、raster/upload 各 1 tile `140,400 B`、decode 0、文字 live `3,237,392 B`、候选峰值 `4,816,864 B`；两者空闲提交停止。原数在 `/private/tmp/cjgui-spaced-export/ui-translation-run-20260928203213-6024.log` 与 `/private/tmp/cjgui-spaced-export/gen-translation-run-20260928203213-6024.log`，不与旧最后 refresh 样本混算。

D：两款正常导出应用已完成真实 host 键鼠路径（CGEvent 投递）的分栏、滚动、屏外焦点、文本输入与 owner 精确读回。手写导出窗口隔条 `360→402→362`、视口 `0→540`，点击平移后原 action 使公开字段 `7101` 的 `isMarked` 为 `1`、共享版本 `1`，见 `/private/tmp/cjgui-f11-export-ui-live.log` 和 `/private/tmp/cjgui-f11-export-ui-accepted.png`。生成导出窗口隔条 AX x `559→539`、可见文字段 `0→17`，Shift+Tab reveal 屏外 notes 后焦点及 AX frame 对齐；键入后公开 `8101` 草稿/应用/选区同为 `F11 可平移 owner ✅ + 续写`、`20:20`，外部候选版本 `1→2→3→4` 包含拒绝保旧，见 `/private/tmp/cjgui-f11-export-gen-live.log`、`/private/tmp/cjgui-f11-export-gen-final.png`。这组前台实例来自 20:07 同源导出；其后排队 reveal 接缝用上述 RED/GREEN 定向测试闭合。另有两窗少量真实公开队列请求在 463.112 ms 滚轮期间自然交错 `12/20`，见 `/private/tmp/cjgui-f11-review-two-window-overlap.log`，不宣称 native 提交阶段重叠。最终含空格同源导出 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260928203213-6024/CJGUI Framework Preview` 已构建运行两消费者，公开平移/效果/材质/诊断与注入拒绝全部通过，源码/客户端/产物指纹见 `CONSUMER_FINGERPRINTS.txt`、汇合日志 `/private/tmp/cjgui-f11-final-spaced-export.log`。系统组字候选窗实体视觉跟随、物理跨屏、H 后端与连续位置动效仍未由本包证明。隔离 target 的 `cjpm build --skip-script`、相关脚本语法及 `git diff --check` 通过；E/H 在途改动保留，未 stage/commit/push。

<a id="f-position-motion-next"></a>
### F 接续：位置呈现事务、连续平移与正常交互 A–E（2026-09-28）

**本次限域复核与阶段选择。** 保留 F11 已交付的浮点声明、split/reveal 求解、局部 tile、24 MiB 预算、P4 原断言及两消费者原证。指导只读当前源码、20:32 最终导出与日志，独立复算框架 source/native、两消费者 source/app 六组指纹全部一致；没有重跑构建、测试或桌面。20:07 前台 CGEvent 消费与20:32定向修复/导出自验分别成立，不合称同一最终二进制的前台全验。当前 window 相对导出仅新增焦点测试字段，下面三处缺口在导出内也存在。整包范围仍有三处必须接通的生产分支，不能只凭七条 reveal 测试将它们关闭。

**下一能力是连续位置动效。** 复用 P2 帧时钟、补间/弹簧、绑定代次、暂停/减少动效与终值提交，接到 F11 的同一 accepted 几何投影。先把下列衔接修完整，再完成两消费者的连续移动与人/公开操作。位置通道与模型/解析/IME组合生命周期无关；E 继续输入协议与正文，H 继续触摸生命周期。旋转、缩放、任意仿射、惯性回弹另按后续需求推进，本包只做既有 translateX/Y 的连续呈现。

**A．补齐三个生产接缝，复用原机制而非新增旁路。**

| 只读确认的缺口 | 必须先有的判别反例 | 实施要求 |
| --- | --- | --- |
| `focusProjectedNode` 仍用 `cjguiFocusVisibleIntersection(node.bounds,node.clipConstraints())`；helper 只算整数 layout 交集，未使用 accepted 平移。七个窗口级 reveal 测试没有实际 translate 声明 | clip Y=[0,100]，layout Y=[120,140]、子 translateY=-100，视觉已在[20,40]却不能聚焦；另测 layout 内但视觉移出 X/Y clip | 最终焦点准入与 reveal 共用目标、真实 clip owner 的 accepted 浮点几何，检查两轴；父子共同移动正确抵消。实际窗口验证焦点及键盘到同一 owner，不只断言 offset 增加。不可达目标有界结束，候选拒绝保旧 |
| macOS legacy `pointerGestureMatches` 先要求 projection==当前scene，dispatch 后方允许同一 split 捕获跨已认证接受区间的分支因此不可达 | core 收到 BEGIN；UPDATE/END 在 N 排队；该拖动自身刷新接受 N+1；再由真实 pump/dispatch 处理，核更新和捕获终结 | 将手势/绑定身份判断与可接受的 projection 区间判断分开，并统一裁决。保留冻结坐标、完整 accepted binding、手势代次、目标 revision CAS、换绑/独立写入/新手势拒绝；不以普遍放开旧版本修接续。旧 END 必须精确结算自己的捕获，不影响新捕获 |
| 正常 owner-stable 活动框发送 `preservesActiveLocalText=1` + 空value，native `CjguiComposableTextResourceAcknowledgesActiveLocalInput` 后提前continue，只计旧纹理；跨tile新覆盖等提交后才refresh。既有focused回滚测试传完整正文/preserve=0 | 保持真实焦点/草稿，沿正常Cangjie提交形态跨tile；强制新覆盖准备失败，核接受前后scene/几何/正文资源/选区/owner；再恢复成功 | preserve 的含义仅是复用权威活动正文，不能绕过几何、scale、clip变化带来的新覆盖准入。覆盖足够时复用；不足时从同一活动文本快照准备候选tile并计预算，成功后同几何一起接受。失败保留完整旧投影及草稿，不通过提前提交新几何、事后换纹理补偿 |

A1 与 H 正在接续的通用焦点 pending/重试状态机共享函数，A2 与 H GestureKey/acceptedBindingEpoch 共享守卫；先按符号确定唯一集成者，保留对方新增字段与状态机。F 负责视觉坐标准入、macOS捕获接续与其反例；H 的完整手势身份不因macOS兼容路径而降级。A3 与 E 的活动文本/草稿拥有关系保持一致，只修渲染候选资源准备，不重做组合仲裁。静态分支矛盾先落定向RED，再修一次机制及相关回归；已验证的求解器七例直接复用。

**B．连续 translateX/Y 进入窗口统一动画与呈现事务。**

- 在现有 `CjguiComposableUiAnimationDriver`/窗口动画入口中增加位置通道，复用显式单调时钟、标量曲线与accepted binding，不在消费者定时重建整树。声明目标与当前成功呈现值分开；起始值取该节点当前accepted局部平移，父子按已有累计规则相加。当前呈现值替换该通道的局部平移，不能再把同一个目标加两次；整数offset仍按原语义参与。公开入口的稳定性、单位和限制统一发布，非法/非有限值原子拒绝。
- 中途反向/改目标从当前成功呈现位置连续接续，弹簧速度按已有契约处理；拒绝帧不能成为命中/AX的“已呈现值”。将位置、clip、效果采样、输入几何、caret/range和诊断作为一次候选投影接受；失败保留旧几何并通过现有pendingPresentation有界恢复，终值不能漏提交。现有±1024单项/±4096累计准入覆盖中间值；对弹簧越界/内部非有限数给出一致的有界收敛策略，不循环拒绝到永久活动。
- 位置变化保持文本会话、草稿/选区、业务owner和结构身份；动画帧不制造业务事务或冒充结构重排。布局尺寸/内容不变时复用控制器结果、测量、文字布局与图片解码，只更新必要几何投影和资源覆盖；确需重算的clip与背景采样正确失效。沿现有绑定代次淘汰换绑/移除后的通道，不把每次scene变化当新实例；位置、paint alpha、组opacity和颜色通道互不覆盖。
- 零时长、reduce-motion、暂停/恢复、关闭及终值提交复用P2机制；仅活动/待提交通道请求帧，停止后归零。提供同一窗口的有界读回，区分目标与成功呈现值及其scene/frame，复用既有公开观察/诊断，读取不触发新提交。

**C．共同定义与真实可操作的移动界面。** 手写API、命名/组合声明、公共生成motion定义共用位置规格和准入；沿 `CjguiGeneratedMotionRegistry` 及现有生成事务扩展，不在两消费者各写一套动画。公开客户端可发现、设置/改目标/清除；非法候选保留旧界面与活动通道。让真实按钮或公开动作在两款正常消费者里驱动移动，覆盖中途反向、再次触发、清除和终值；生成侧通过公共provider接受声明后由真控件执行，而非仅脚本直接调用内部driver。

动画期间核新旧位置的真实命中、移动父子/祖先clip、split拖动及屏外reveal、AX与caret/range对应同一已接受帧。输入与动画同时发生仍遵守冻结事件/捕获身份，避免用新位置解释旧事件；实际输入及公开owner读回精确。聚焦文字有活草稿/非空选区时移动并继续输入，E负责的组合生命周期保持原契约。候选窗实体视觉跟随可并入同一已授权桌面运行，能观察才标通过；拿不到该证据单列，避免为此反复重跑整包或改造输入法。

**D．有界文字的连续采样与成本。** 保留局部512×256网格、原24 MiB预算及在途代次；覆盖内移动复用，跨格仅补新覆盖，不要求任意大位移零raster。旧 `scene_pixel_diff_bytes=0` 是把每张raw纹理翻转为场景行序后的CPU逐字节拼接对照，严格零差和一字节负控有效，不能描述成Metal drawable读回。补真正1×/2×的连续亚点Metal跨缝对照，覆盖中文/emoji/背景与活动文字，和同版强制重算/独立覆盖对照比较；是否需要有限gutter或像素相位处理由采样反例决定，当前未证明已有可见接缝缺陷。

成本采用固定负载的静止、覆盖内移动、跨tile移动三组，逐操作/逐帧区分build、layout、text prepare、raster/upload、decode、submit及live/peak；停止后计数稳定。同host另一窗在位置动画进行中经原公共队列得到owner/accepted，沿原100/150ms预算和真实投递时段判断，不把等待闸门计入自然性能、不追求伪造native重叠。先定位异常工作量再优化，已有P4/Finder/PNG压力及未受影响输入原证复用。

**E．参考、协作与一次最终交付。** 按[本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)复用已核的 Flutter `RenderTransform` 几何链，定向查 `animation_controller.dart::_animateToInternal/_startSimulation/stop` 的当前值接续、时钟与停止机制。指导本次核对本地相关符号；借鉴状态机与测试设计，不引入框架依赖，也不照搬Flutter渲染树。CJGUI自身accepted事务、绑定和有界tile仍是实现基础。

普通接线直接实施；本包涉及候选资源/输入版本与动画失败恢复，方案有歧义时先核精确源码和反例；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型；既有结论前提不变则复用。`laya-ask`用于成批可复核分类，不能替代机制判断。A的独立分支、B/C可按写集并行；同target构建、native同段和桌面串行，等待时做独立必要工作，确无工作用等待工具。

包末按改动影响集中验证：上述三反例、位置通道状态/失败/身份、真实采样、两正常消费者输入和公开回包。最终冻结含空格导出，两款应用自身构建运行并消费新能力；把必要的前台链合到最终实例，保留源码/产物指纹。当前共享树在途变化另记，不能用旧二进制为新源码背书。只短更本节和ACTIVE，不另起逐轮执行卡。E/H并行内容、用户实例及剪贴板保留，未经要求不stage/commit/push。系统候选窗实体视觉、物理跨屏、VoiceOver、H后端分别保持实际未验边界。

**实施结果（2026-09-28，macOS）。** A 的三条判别反例已由生产路径闭合：最终焦点使用 accepted 视觉矩形与两轴祖先裁剪（`fPositionFocusUsesFinalAcceptedVisualClipOnBothAxes`）；legacy split 自己刷新 N→N+1 后仍结算原队列 UPDATE/END，换绑/新捕获不借此放开（`fPositionLegacySplitQueuedUpdateAndEndSurviveOwnAcceptedRedraw`）；活动文字 `preservesActiveLocalText=1`、空 value 跨 tile 时，缺新覆盖在接受前拒绝并保留原纹理、草稿/选区，重试成功，已有覆盖不重复 raster（native `composable_translation_native_test.m`）。B/C 复用 P2 时钟与 F11 accepted 几何，增加节点位置通道、当前 accepted 值接续/改目标、失败帧 pending、终值和停止；公开 `GET/SET/CLEAR_NODE_TRANSLATION` 以 accepted 目标身份和 CAS 准入，手写、命名/组合与生成定义共用规格。两款正常应用的真控件和公共客户端均完成往返、清除、拒绝保旧及 owner 版本不变；最终导出实例中 AX 按钮动作各完成两次反向和一次清除，公开 requested/presented、scene 与 owner 读回相符，行动为前台 AX，不扩称实体键盘或指针。

**采样、成本与生命周期。** 真实 Metal drawable 1× `640×300`/1000 点及 2× `1280×600`/2000 点与独立覆盖重算均 `diff_bytes=0`，移动的 `raster=8→8`；原始读回分别 `8,334,979/16,669,095 µs`，这是受控 readback 总时长，不是正常帧提交延迟（`/private/tmp/cjgui-f-position-drawable-fence.log`）。手写正常消费覆盖内 `build/layout/submit=459,000/2,161,000/43,582,000 ns`、scene `2→20`、text prepare/raster/upload/decode `0/0/0/0`，跨覆盖 `0/0/37,261,000 ns`、scene `20→32`、`2/0/0/0`、live `4,902,304→4,500,896 B`；生成侧对应 `887,000/1,176,000/30,066,000 ns`、scene `2→19`、`1/1/1/0`，跨覆盖 `0/0/22,944,000 ns`、scene `19→31`、`2/0/0/0`、live `3,237,392→3,078,992 B`。同 host 真实公共队列得到 `A animated frame→external B→A continues`、B scene `2→3`、owner `5→6`、ready→final `121 ms`；这是公共队列交错，未测得 native/GPU 提交重叠。另据判别 RED 修正 `NOT_MAIN_THREAD` 视为未消费调用：窗口与宿主持有 session/资源/descriptor，等待合法线程重试 destroy 成功后才释放；wrong-thread 反例的 `pump_status=1`、scene `1→1`、descriptor 存活并返回 open，正常两消费者关闭资源归零。原始记录 `/private/tmp/cjgui-f-position-adaptive-recheck.log`、`/private/tmp/cjgui-f-position-generated-action.log`、`/private/tmp/cjgui-f-position-lifecycle-final-probe.log`。

**最终汇合与边界。** 受影响 native、公共协议/客户端、双消费者及 `cjpm build --skip-script` 通过，`cjpm test --skip-script` **429/429**；含空格同源导出 `/private/tmp/cjgui-spaced-export/Spaced Preview Workspace 20260928233511-4318/CJGUI Framework Preview` 两应用构建运行且公开位置/效果/材质/诊断及注入拒绝通过。独立逐文件核验 `105=95 identical+10 rewritten`，sha256 `cafe885acc234f7e299acf5d912ed33050516dd521ced2cef167129703f92a2e`；框架源码、native、两消费者源码及 bundle 指纹在该目录 `CONSUMER_FINGERPRINTS.txt`。最终二进制的前台 AX 动作和公开读回已验；动画中途同一接受帧的实体键鼠、活草稿继续输入、AX/caret/range 联合读回，以及候选窗实体视觉、物理跨屏、VoiceOver、H 后端仍未得到该版联合前台证据，不能由独立几何/文字测试代替。E 文本/IME 与 H 后端并行改动保留；未 stage/commit/push。

<a id="f-position-motion-acceptance-review"></a>
**指导限域复核与接续（2026-09-29）：待决呈现事务、绑定退役与移动中输入。** 本轮只读源码、23:35 冻结导出和原始日志，未构建、运行探针或操作桌面。相关 position/animation/window/native/host 与该导出一致；独立复算 framework、shared core、native、两消费者源码和两 app 共七组树指纹均相符。保留已交付的连续位置通道、公共 CAS、最终 AX 控件消费及多行资源准入；下面是冻结源码中的具体分支缺口，须先落反例取得运行判别，不能把本次静态复核写成已执行 RED。

阶段选择：仍由 **F 框架渲染线**完成同一能力的异步确认、资源准入及正常移动界面消费。E 的人/Agent 正文事务和 IME 会话由外部工具开发，F 不联系其线程、不接管其写集；H 的触摸/平台接续独立。此次不是重做编辑器，也不另开动画系统。复用既有 accepted 快照、P2 driver、F11 几何和 tile，把以下六处归到共同机制修复。

| 源码发现与定位（行号为复核时） | 可区分序列与验收要求 |
| --- | --- |
| **A1 待决旧票可清掉后来的 paint 终值。** `window.cj:3094` 接受后无条件 `markPresentationCommitted()`；`animation.cj:1408` 只清共享 Bool | 零时长位置候选进入真实 PENDING（其中 alpha=1）→请求零时长节点 alpha=0→旧票接受。目前新 alpha 可因 dirty 被清且通道已 inactive 而永不提交。候选只确认自己包含的 mutation，后来的节点 alpha/组 opacity/颜色/位置请求必须仍待提交，终值各一次落地后停帧。必须覆盖实际 pending→accept，提交前同步拒绝不能替代 |
| **A2 clear→重建后局部 revision 碰撞。** `position_motion.cj:84/153` 新通道 revision 重置，旧 sample 按 binding+revision 进入新通道；driver 按 key 投递 | accepted x=0；0→100 在 x=50/sample2 提交 pending；clear 后同 binding 建 0→200/sample1；旧票接受时不能让新曲线继续从0推进而出现50→20回跳。区分通道实例、请求及采样身份；旧票真实接受的画面仍须发布，当前有效请求从该 accepted checkpoint 接续，不靠丢弃完成回调掩盖事实 |
| **B1 多个单项合法目标合成非法终值，clear 也无联合准入。** `window.cj:2480–2494/2519–2523/7523` | 五层各800（累计4000），两层依次请求880，单次预检各4080、联合4160；另先A到0、B到1024均接受，再clear A恢复声明800，累计4224。SET/retarget/CLEAR 对有效目标集合及拟恢复声明统一原子准入，拒绝不改请求版本/通道/accepted。非法终值不能经 converge 后永远 pending；合法终值的中间越界沿有限收敛策略验证 |
| **B2 accepted 语义换代未使动画/公开暴露换代。** `AnimationBinding` 不含 semantic incarnation/key，`window.cj:2975–3006` 保留旧 epoch | 仅把 `semanticIncarnation` 1→2，保持 nodeId/identityKey/resource/action。旧通道与旧 accepted token 必须失效；新实例未授权 expose 前不能自动继承旧暴露。此处旧 scene CAS 已会拒绝，不把问题误报为旧 CAS 绕过。与原 resource 换绑对照验证 |
| **B3 退役元数据未回收。** `exposedPositionMotionKeys` 永久占32名额；请求/接受 revision、mode、failure 表只增不减 | 依次接受→expose→移除不同 key，任意时刻仅一个存活，第33个仍应可用；窗口元数据和候选遍历成本有界。成功接受移除/换绑后清退，拒绝候选保留原绑定；旧在途回执不能污染新实例，关闭清理。若需要短期退役回执，明确有限保留策略 |
| **C 单行活动文字仍跳过覆盖准入。** native `6135` 只准备 multiline，`6156` 对其他活动框 continue；单行 `12124–12129` key/复用条件不判 coverage | 聚焦1000×40单行框、父clip宽100、长正文；初始局部覆盖0..512，owner不变平移X=-600，新可见600..700。先验证缺字/空白反例，再用同一活动文本快照在接受前准备必要覆盖；注入失败保旧几何/资源/草稿/选区，恢复后与重算对照。覆盖内零额外栅格，原24MiB预算及在途持有保留；同时核普通/整数单行及已修多行的共享分支 |

**A．一次修正候选确认边界。** 在现有 driver/window 呈现事务中冻结候选实际包含的 mutation revision、完整绑定及通道生命周期身份。接受只能确认该候选包含的工作，拒绝不得推进 accepted checkpoint；后来的请求仍有独立待提交事实。局部 sample revision 只在其通道生命周期内比较；同一绑定 clear→重建期间旧画面获接受时，应如实更新窗口画面，并让仍有效的新请求从该事实重新起算。先做上表两个确定性交错，再实现共同确认机制，覆盖节点 paint alpha、组 opacity、颜色与位置，避免分别加“再刷一帧”补丁。现有 pause/reduce-motion/retarget/同步失败恢复及终值停帧用例复用；有影响才增补。

**B．联合几何准入与 accepted 绑定生命周期。** SET、retarget、CLEAR 恢复声明共用目标集合预检；accepted 声明/父链改变也要重核仍存活目标，处理合法中间采样与非法组合的差别。保留±1024单项/±4096累计边界，失败应具名且有限，不提高上限或把失败目标标成已呈现。身份判断接回 CJGUI 已有完整 accepted 语义定义，避免 native、animation、公开 exposed 表各维护不一致字段；语义同实例的每帧scene变化仍可接续，真实 incarnation 改变才退役。退役与名额/元数据回收在 accepted 边界共同完成，历史 key 不长期进入每帧工作量。沿用现有公开 CAS 与请求/呈现读回，无必要不增第二套协议。

**C．统一活动文字覆盖准入。** `preservesActiveLocalText` 只表示正文权威在活动文本快照，不等于旧纹理能覆盖新几何。单行、多行通过共用的内容身份、局部覆盖、scale、clip和预算判断决定复用或准备；复用现有 raster/tile/cache，不复制整套单行特例、不改 E 的组合生命周期或正文写入。新覆盖与新几何一起接受，失败只释放候选持有。原 multiline preserve RED/GREEN 继续有效，新增单行判别后重跑受影响交叉面即可。

**D．在最终两款正常消费者补完整移动中操作。** 使用现有 adaptive/generated 窗口、公共provider及原owner：公开设置/真实控件启动动画，观察一个接受后的中间位置；在新位置点击，旧位置不误激活；活草稿/非空选区移动并继续输入、外部原owner修改后续写，读回精确。通过正常宿主键鼠路径投递即可，如实标 CGEvent/AX，人工物理输入另标。至少一条真实输入发生在动画活动时；AX/caret/range查询绑定同一accepted scene/frame，必要时显式暂停于已接受中间帧取得一致快照，不能把暂停查询冒充活动时输入。选区/owner不得由动画自身推进。split 自身刷新接续与祖先独立移动导致的安全取消分别验并声明，不能把安全取消写成持续拖动。

把 wrong-thread 拒绝后的**同实例合法线程继续 pump→正常 close**补成一个生命周期测试，确认原owner/descriptor可用、最终自身资源归零；旧探针的拒绝后保留与另一个应用的正常关闭不能拼成这条证据。系统候选窗实体视觉能在同次运行观察才记录，否则单列；不为此改输入法或反复等待人工。

**E．受影响采样、性能与一次汇合。** 原 drawable 比较是真实Metal读回，但只比较-0.25→+0.25复用与同网格新session，采水平接缝附近五行；不能外推为独立无缝oracle或完整连续动画。随C的覆盖改动增加少量横/纵跨格和不同亚点相位的1×/2×对照，保留复用/重算范围及判别负控，不重建大规模golden平台。正常消费上述submit数是跨12–18次提交的**操作区间累计**，不是43ms单帧；readback总耗时另列。

同host沿现有固定公开队列负载，在A活动期间采一批自然请求（复用原20样本规模），分别记录ready→owner/accepted原样本及p95，沿100/150ms预算；121ms单次最终回包不替代此判据。受控PENDING闸门只用于交错正确性，不计入自然性能，也不要求制造native/GPU重叠。仅当新计数暴露异常才继续优化。包末相关反例、受影响build/test及一次最终含空格导出汇合；同一最终双应用合并完成上述D链，身份和指纹固定，不反复重跑未变PNG/Finder/P4全套。

**实施顺序与问题升级。** 先由当前执行者结合A/B的现有机制、六项反例和拟议统一状态边界，明确“旧票接受→新请求继续”的身份、确认与联合准入，不重扫全仓；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型，方案明确的接线直接完成。咨询或编译期间可并行C、定向测试和消费者布置，同一native段/同target构建/桌面串行。参考沿本节原Flutter动画入口和导航，重点学习取消重建的生命周期与当前值接续；其同步帧模型不替代CJGUI异步accepted裁决，只借鉴思想、不引依赖。`laya-ask`用于批量可复核日志分类，不替代根因判断。无新代码、失败或证据疑点不重复验证；工作量大不作为将A/B核心机制再推下一包的理由，有真实架构阻塞按AGENTS升级、其余独立任务继续。只在本节集中记录修复与原数，ACTIVE保持短状态，不另建任务卡或逐轮长报告。保留E/H并行改动，未授权不stage/commit/push。

**执行接续（2026-09-29，F）：** 旧通道样本、联合目标/clear、incarnation 退役及第33个暴露目标四项先在旧机制得到失败；focused 单行越覆盖的 native 旧版在 `single_line_missing_tile_rejects_before_acceptance` 退出56。修复后以候选捕获的呈现 revision 确认实际接受工作，旧 PENDING 票据接受时发布旧画面、保留后来请求并从 accepted checkpoint 重定向新通道；通道实例 generation 与完整 accepted 绑定分离，联合目标和声明刷新共用预检，接受边界回收退役元数据。活动单行与多行共用可见 tile 准入及在途预算；单行注入失败保留原画面、草稿和选区，恢复后覆盖完整，覆盖内平移不再栅格化。A/B 六项确定性测试及真实 PENDING 测试通过；native 单行与原多行/亚点测试通过。split 自身刷新接续与祖先独立移动安全取消分别通过定向测试；wrong-thread 拒绝后同一实例合法 pump 和 close 通过，原 owner、descriptor 保留直至关闭。

同 host 的 A 活动中固定公开队列 20 个自然样本全部有效：ready→owner p50/p95 `8.841/11.874 ms`，ready→accepted `10.114/14.478 ms`，最大 accepted `14.565 ms`；空闲四项提交计数增量均为0。真实 Metal drawable 复用/重算 1×/2× 对照分别采1000/2000点、差异0、读回总耗时 `8,336,756/16,668,840 us`；新增横/纵/交叉接缝各比例75点差异0，负控1。CJGUI 完整测试在新增 split 用例前 `436/436`，之后该用例单独 `1/1`；根包正常 `cjpm build --skip-script` 及含空格一次导出的手写/生成构建、`--verify-position-motion` 与两窗口公开 CAS→accepted→clear 读回通过。导出源码逐文件一致、两二进制指纹见 `/private/tmp/cjgui-f-position-final/Spaced F Position Preview/F_POSITION_FINGERPRINTS.txt`；原日志见 `/private/tmp/cjgui-f-position-final/`、`/private/tmp/cjgui-f-position-review-motion-latency-final.log` 与 `/private/tmp/cjgui-text-tile-drawable-seam.74ca9T/native.log`。

**解锁后的最终前台联合消费（2026-09-29，F）：** 直接运行上段固定含空格导出的两款应用，独立 token/descriptor；CGEvent 投递获准，窗口明确前台后才作点击判别。手写窗口公开位置目标 `8000000000000000006` 的活动帧 `209→217` 中，原 owner `7101` 聚焦且 UTF-16 非空选区 `0:1`，真实键入 `V` 使版本 `6→7`、标题精确为 `V`，动画自身未推进 owner；公开 `SET_MARKED` `7→8` 后继续键入 `W` 到版本 `9`、标题 `VW`。再平移到 `(-80.25,3.5)`：旧位置独有点 `(1005,720)` 不改变版本9，新按钮点 `(740,720)` 使版本 `9→10`、标记 `1→0`。同一 accepted scene/frame `287/287` 的前后进度包住 AX 输入框 `(731,658,256,36)`、AX 光标偏移0、公开选区 `0:2` 和位置读回，Metal 完成帧也到287。原始活动/owner、几何和最终读回分别在 `/private/tmp/cjgui-f-position-final/front-adaptive-motion-selected.log`、`front-adaptive-external-owner.log`、`front-adaptive-geometry-bracket.log`、`front-final-public-readback.log`。

生成窗口公开目标 `806001` 的活动帧 `23→34` 中，`component-14-1` 的原 owner `8101` 备注草稿/应用均为「生成活稿」、选区 `3:4`；CGEvent 输入「终」使版本 `4→5`、草稿/应用均精确为「生成活终」。公开 `SET_MARKED` `5→6` 后继续输入「续」到版本7，草稿/应用与 owner 均为「生成活终续」。平移 `(80.25,0.5)` 接受后，前台 CGEvent 旧按钮位置独有点 `(580,495)` 保持动作计数6，新可见按钮点 `(680,495)` 变为7；受控判别见 `front-generated-pointer-accepted.log`。另在静止的 `(30.25,10.5)`，同一 accepted scene/frame `101/101` 的前后进度包住 AX 输入框 `(597,444,150,42)`、AX 光标偏移4、公开选区 `4:5`，见 `front-generated-geometry-bracket.log`；最终 scene/frame/Metal 完成同为602。初期未固定前台的零增量点击不作为框架失败或通过；只读 Sol 咨询指出须先区分 native press 入队与命中，本轮以明确激活窗口后的旧/新点运行判别收口，未因此改生产代码。两窗口最终 owner/焦点、动画终值与完成帧读回在 `front-final-public-readback.log`；精确身份的测试进程、socket/descriptor 已清理。以上是系统 CGEvent/AX 前台证据，未宣称人工物理键盘、候选窗实体跟随、物理跨屏、VoiceOver 或 H 后端通过。E 正文/IME 与 H 写集保留；本接续只更新本节和 ACTIVE，未 stage/commit/push。

**指导限域复核结论（2026-09-29，解锁记录优先）。** 本包按固定导出的 macOS CGEvent/AX 消费范围收口；锁屏前“尚待前台”报告已被上面解锁原证取代，不再要求用户重做这一段。只读复核确认 A1/A2/B1/B2/B3 的共同确认、通道代次、联合准入及退役回收已落实，单行活动 tile 与 split 两类行为也有对应实现和反例，未发现新的可达生产缺陷。真实 PENDING 另引用 `/private/tmp/cjgui-f-position-review-pending-linear.log`，不单靠可能跳过原生闸门的总套件计数；TEXT_INPUT 有独立覆盖反例，INTEGER_INPUT 是同一生产分支的接线范围。可独立核对活动动画中的输入、外部事务后续写及生成窗口旧/新点 `6→6→7`；指定 front 日志没有单独保存输入前 `0:1/3:4` 选区，以及手写旧/新点的分段原回包，这两项目前依据执行叙述，不扩称已独立复算。下一包正常窗口消费时顺带补齐或索引已有原件，不重开整套。`geometry-bracket` 中 caret=0/4 来自 AXSelectedTextRange 的起点，故准确口径是同帧的 **AX 输入框矩形＋光标偏移＋公开选区区间**，并非光标/选区屏幕矩形的独立几何 oracle。两份二进制哈希与固定清单一致；后续 E 的源码改动不由本导出自动覆盖。本次未运行构建、测试或桌面。

wrong-thread 已串成同实例拒绝→恢复调用→关闭，但 `pointer_public_interleaving_probe.cj` 的 `legalPump` 目前只看窗口/descriptor/token/owner 保留，不能区分合法消费与再次受控拒绝。该验收小缺口并入下节 A，以真实消费补强，不重开已通过的动画、性能、Metal 或导出矩阵。物理输入、候选窗实体视觉、物理跨屏、VoiceOver 与 H 后端沿原边界保留。

**F5 接续执行（2026-09-29，进行中）。** A 验收缺口已补强：`legalPump` 现断言恢复后 native 状态正常（`legal_status=0`）并通过真实滑杆控件完成一笔身份操作（x=240 整步命中 owner `512→320`，accepted scene 前进，owner 精确读回）；判别器让同一实例被故意二次拒绝时新判据必须失败（`refused_consumption=false`，此时入队仍 OK 且 `turn.isOpen` 成立，唯 nativeStatus 判据可区分），恢复后下一个合法 turn 恰好消费被保留的入队事件（owner `→224`），原资源保留与最终清理断言不变。host 探针 exit0，`/private/tmp/cjgui-f5-wrongthread/wrong-thread.log`；脚本断言同步更新为 `legal_status=0 … refused_consumption=false retained_delivered=true`。只跑该受影响探针，未重跑 F11 矩阵。

A3 语义桥在 F11 固定导出的两正常应用上以 AX 查询核对通过：角色/标签/层级（页签组→单选钮、树→行、禁用行 `enabled=0`）、未聚焦短文本框 AXValue 与 owner 字节一致（手写标题 `窄宽布局动态项目` 24B/8 UTF-16）、AXPress 页签/复选框状态翻转与 accepted 一致；同进程稳态 press→切页→树一致 9–11ms/轮，冷连接首轮 ~7.9s 慢源于客户端侧 TCC/审计（服务端采样见 `TCCAccessCheckAuditToken→tccd` 同步 XPC），VoiceOver 持久连接不受其影响，如实归因为测量伪象而非框架缺陷。通知面对照 Flutter `AccessibilityBridgeMac.mm`（只读借鉴，无依赖）：CJGUI 已按 accepted 差异发 ValueChanged（label/value/state/tabSelected）、LayoutChanged（结构/几何）与焦点/选区通知并有去重反例，与参考分类一致。证据 `/private/tmp/cjgui-f5-voiceover/`。

**F5 C 段静默窗口重跑与 VoiceOver 实测（2026-09-29 12:00–12:35，F）。** 三项 F11 留证缺口全部以普通 CGEvent 输入闭合：手写窗口输入前非空选区精确为 `0:1`（shift+right 于 caret 0）且 owner 原回包版本0、标题24B 原文；键入 `V` 替换后版本1、标题 `V宽布局动态项目` 22B、选区 `1:1`。平移 `(-80.25,3.5)` 收敛后（SETTLED scene60）旧位置独有点 `(1020,715)` 版本保持1、焦点不变，新按钮点 `(860,718)` 版本 `1→2`、焦点 `adaptive-translated-owner-action`，分段原回包各自保存。生成输入前 `3:4` 选区证据见事故段。证据 `/private/tmp/cjgui-f5-voiceover/evidence/adaptive3-*`、`generated-preinput-*`。

**VoiceOver 执行原报与指导更正（2026-09-29）。** 执行者曾据截图、和弦与 owner 声称“手写 VO 激活链完整”，并把约 1–4 次命令后退出归为系统边界；本次指导核原日志、截图与源码后不采纳这两项结论。`vo-cycle1-01/02` 两图均为 shared operation version=2、资源选中，背景仍有 Quickstart 第2面板；没有该次动作紧邻的 `isMarked 0→1` 原回包。普通 Space/Enter 也可经 native `keyDown:` 激活相同 owner，故 owner 变化本身不能区分 VO 与普通键盘。`vo-nav-06/07` 图与归档进程时间不匹配，不能一律把黑框当作存活且就绪的 VO 光标。`vo-syslog.txt` 的 PID35069/37784 从最早日志到退出分别约10.32/10.34秒，均在退出前报 `VoiceOver was not launched by UA daemon as expected`；Finder 使用同一启动方式，只证明现象不局限于 CJGUI，未排除启动/驱动缺陷。保留 AX 查询、直接 AXPress、普通 CGEvent 的原范围；两款应用的完整 VO 导航/读出/激活与编辑继续未验，不自动转为“只能人工物理键盘”。字幕面板未配置不推断必须 sudo。测试工具新增和弦、focus-id 与 AX 探针属已写工具；本轮未修生产 AX 桥不代表该桥已无缺口。下一步按下述指导接续。

**B 分层结论（2026-09-29）。** 本包实测未发现应用声明或框架投影缺陷：语义投影与 accepted 一致（A3）、AXPress/AX 查询路径全部有效、CJGUI AX 树不触发 VO 异常（Finder 对照同亡）；两次观测到的"慢/死窗"分别归因客户端 TCC 冷连接与 VO 对合成和弦的系统行为。无生产机制修复；不因缺实测重建 AX 层。E/H 写集保留，未 stage/commit/push。

**桌面并行输入冲突事故（2026-09-29 10:49，F5 C 段）。** 硬化后的普通输入脚本在手写应用内完成 click→focus 断言→全选读回后，读回间隙收到并行执行者的一笔 802 字节粘贴（H 线「继续 H 线原惯性滚动包…」任务提示词全文），替换了本实例 `7101 title` 选区（版本 3→4，读回 `406:406`）；本方 `type "V"` 未再产生版本变化。受影响证据已改名为 `INCIDENT-adaptive-afterinput-owner-collided-paste.txt` 留证；本方两实例（独立 token/精确路径核对）立即 TERM，轮次 descriptor 目录清理，VoiceOver 确认未启动无需恢复。对方运行可能丢失该笔输入，如实报告不动其会话。生成应用段在此窗口前已完成且干净：输入前非空选区 `3:4`、owner 原回包 `notes=生成活稿`（版本4）、替换后 `生成活终`（版本5、DRAFT/APPLIED 一致），上节缺口之「生成输入前 `3:4` 选区」就此闭合；手写两项与 VoiceOver 链等桌面静默后重跑，输入批前一律重新断言前台 pid 与公开 WINDOW_FOCUS。



<a id="f-accessibility-consumption-next"></a>
### F5 接续：正常手写与生成界面的 VoiceOver 可操作性（2026-09-29）

**目标与取舍。** 本包属于 **F 框架通用能力线**，工作目录 `/Users/jiangxuanyang/Desktop/cangjie`。连续平移先按上述范围接受；下一主线兑现 P3/F5 一直单列的实际屏幕阅读器消费：人能发现控件、理解名称/状态、导航并操作，外部系统从原 owner 读到同一结果。复用当前 accepted 语义、AX wrapper、焦点/reveal、控件动作和两款正常消费者；先跑一条真实 VoiceOver 正控，再据失败修机制，不能因缺实测就重建整个 AX 层。E 继续正文/IME，H 继续鸿蒙，F 不联系外部 E 线程、不接管其产品会话。

**A．收紧唯一验收余项，并核实际语义桥。** 在现有 wrong-thread 同实例探针恢复合法线程后，断言 native 返回正常状态，并通过既有公开队列或真实控件完成一笔带身份操作、精确读回后关闭。保持拒绝时资源保留与最终资源清理的原断言；故意让第二次调用仍被拒绝时，新判据必须失败。只跑这一受影响探针，无需重跑上包完整矩阵。

对正常两消费者中的按钮、复选框、页签、树/滚动区域和短文本输入，检查 role/label/value/state、父子关系、焦点、可执行动作及通知是否与同一 accepted 语义一致。沿用 `CJGuiInternalComposableAccessibilityAction`、`rebuildAccessibilityActions` 及共同字段/动作定义：手写、生成及公开 owner 不另定义三份规则。实际失败按“应用没声明／框架没有投影／AppKit 未收到／VoiceOver 已收到但行为不同”区分，不能从 AX 查询成功推断 VoiceOver 可用。

**B．用稳定身份把导航、状态变化和操作接通。** VoiceOver 导航/激活进入既有 accepted 目标与 controller；禁用、只读、失效旧引用及非法候选保旧继续按共同规则执行。相同实例的内容变化、同 key 重排、resize/平移保留有效 AX 身份；移除、换绑/ABA 后旧 wrapper 失效。屏外导航和滚动使用现有 viewport/reveal，按目标角色补确实需要的标准动作；不能只把屏外控件从树中删掉而让用户无法到达其内容，也不能让被裁剪区域成为可误点的新位置。

通知从已经接受的状态变化派生，区分焦点、值/选区和结构变化。避免每帧无变化仍重复通知、重排时无故抢走当前阅读位置，以及先发新值通知后客户端却读到旧值。生成候选被拒时保留原语义/焦点/动作；公开改值后屏幕阅读器与普通输入都能接续。静态扫描的怀疑先落最小反例，未复现不自行扩大重构。

普通文本框复用现有系统输入代理及 accepted 文字快照，明确可读值是 accepted 内容还是该目标的活动草稿，UTF-16 选区、只读状态和焦点对应同一对象。按真实 VoiceOver 请求补需要的标准查询/操作；可见文字范围、位置/范围几何若发布必须来自同一排版事实，不能把全文范围、光标索引或零矩形充作可见范围/屏幕几何。查询保持有界，缺失时明确不可用；不通过 AX 再建正文副本、第二条编辑事务或 IME 管线。若故障落在 E 已修改的组合生命周期，按原分工给出精确衔接点，其余控件继续。

**C．两款正常应用完成一条可归因的 VoiceOver 链。** 使用既有 adaptive/generated 消费者，生成结构仍经真实公开客户端提交。记录本次进程/窗口/semantic/accepted scene，实际启动或使用系统 VoiceOver，确认焦点已在测试应用并完成导航→读出角色/名称/状态→激活控件→原 owner 精确读回。两款应用各有一段连续操作，合计覆盖上面控件，并至少包含页签或树状态变化、滚动后可达、短输入框编辑、同 key 重排后的接续和非法候选保旧。已有正常指针/键盘/AXPress 原证用于对照，不把这些调用改名为 VoiceOver 操作。顺带保存输入前非空选区和 owner 原回包、替换后的完整字节，以及手写窗口旧/新位置点击前后原回包，补上上节仅有执行叙述的留证缺口；已有原件可定位时直接复用，用户动作不重投。

通过 VoiceOver 自己的导航/交互命令驱动。以可归因的 VoiceOver 光标/选中对象、系统输出（如字幕面板）和动作后的 owner 结果留证；只看到 VoiceOver 进程启动或按过快捷键不够。工具驱动 VoiceOver、直接 AX 调用、CGEvent 普通输入、人工体验分别标注。首次 Quickstart/提示先识别其窗口并正常进入应用，不反复向遮挡窗口盲投键；用户已有 VoiceOver/剪贴板状态按身份和变化检查保护，临时开启的状态在结束时恢复。用户当前桌面授权继续有效，不增加“回复已解锁才开工”的人工门槛；若系统确实锁屏或工具拒绝，留下具体边界，推进 A/B 独立实现，条件改变再补相关段。

**D．参考、成本与一次汇合。** 系统约束参考 Apple 的[自绘控件无障碍契约](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/ImplementingAccessibilityforCustomControls.html)；按当前 SDK 核对具体 selector/role。实现思路参考本地 Flutter `8db55268667c` 的 [AccessibilityBridgeMac.mm](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/engine/src/flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMac.mm>)（状态变化到系统通知、焦点与选区通知的取舍）、[对应测试](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/engine/src/flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMacTest.mm>)和 [FlutterTextInputSemanticsObject.mm](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/engine/src/flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputSemanticsObject.mm>)（语义对象与既有系统编辑器协作）。只借思想和测试设计，不引入 Flutter/Chromium/AccessKit 依赖，也不直接把其原生控件替换方案搬入 CJGUI 自绘路线。

按变化补通知次数、稳定身份/退役、查询工作量和空闲提交不增加的最小观察；VoiceOver 开关与操作前后对照，不另建全套诊断平台。无新生产改动时复用本包固定导出、构建和性能原证；需要修桥接/共同语义时，受影响反例通过后完成一次核心 build、相关测试及含空格同源双消费者汇合，再用最终版完成 C。只有新计数/延迟出现异常才扩展性能定位。GPU 物理呈现、跨屏硬件及 H 后端不自动纳入本包。

复杂平台根因、新的公共语义/生命周期方案由当前执行者结合准确请求与原始结果归因；问题归因与升级按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型。现有 accepted/owner/输入会话裁决不重问。仓颉编码先读 skill；`laya-ask` 用于可复核的批量日志分类，不能代替平台研究或实际操作。等待构建/咨询时推进独立工作，同 target 和桌面操作串行。只在原节记录闭环和新事实，ACTIVE 短更，不另开执行卡或逐轮长文；保留 E/H 并行修改，不 stage/commit/push。

<a id="f-accessibility-consumption-review"></a>
#### F5 指导复核与整包接续（2026-09-29）

**结论与范围。** 这是 F5 的本次指导复核；F11 连续平移已有范围继续接受，不重开其性能、Metal 或完整导出矩阵。wrong-thread 行为补强和普通输入原证按实际范围复用；F5 原 A–D 尚未整体通过。下面把旧任务中遗漏的生产接缝与验收工具问题合并推进，不新建任务卡。指导本轮只读源码/SDK、日志与截图，未启动桌面、构建或修改生产代码。H 产品驱动编辑器方案仍是未启动规划，E 当前文本位置任务不变。

**接受的补证。** `/private/tmp/cjgui-f5-wrongthread/wrong-thread.log:48` 与探针356行确认同实例合法恢复、owner `512→320`、二次受控拒绝及后续224/最终清理；F11两款输入前非空选区与完整字节、手写旧点v1/新点v2原回包已补齐，均属普通 CGEvent/AX 范围。wrong-thread 的 `!refusedConsumption` 尚不能单独排除“报错却偷消费”，下次触碰该探针时在恢复dispatch前补 owner=320/begins不变的独立断言即可，不据此重复整套旧包。

**1．先修验收入口，不能把失败启动当平台限制。** `vo-syslog.txt:1254/1269/1425`、`:1608/1623/1779` 已给出可区分线索。按 Apple [启动/关闭说明](https://support.apple.com/en-az/guide/voiceover/vo2682/mac)用系统公开开关或标准快捷键启动；不能只 `open -a VoiceOver` 后见进程便宣告 ready。识别并正常退出 Quickstart，保留用户原设置；做一次无输入、跨越原约10秒退出窗口的存活/就绪正控，再投一个导航/激活命令。查当前 VO 修饰键、导航分组与焦点跟随设置，按[导航说明](https://support.apple.com/en-gb/guide/voiceover/cpvounav/mac)区分 VO 光标和键盘焦点；树/组不能仅用连续右箭头即判不可达。驱动 `postVoiceOverCommand` 第一笔 Control flagsChanged 已同时带 Option，应校准完整按下/释放序列；不宣称它已被证明导致退出。若正控仍失败，带启动时间线及准确事件按 AGENTS 升级指导，停止无差别重启/换和弦，不自动咨询；同时继续下面独立生产修复。

**2．修标准 AX selector 到真实输入/owner 的接线。** 本机 SDK `NSAccessibilityProtocols.h:251/727` 要求 `isAccessibilityFocused`、`setAccessibilityFocused:`、`setAccessibilitySelectedTextRange:(NSRange)`；当前 `CJGuiInternalComposableAccessibilityAction`（renderer约8545–8583）使用 `accessibilityFocused`、`accessibilitySetFocused:`、`accessibilitySetSelectedTextRange:(NSValue*)`，value setter同样未覆盖标准 `setAccessibilityValue:`。这是已核实的入口不匹配；具体客户端失败结果先用正式 AX 请求固定，不凭源码宣称已复现所有症状。接回既有 focusNode、选区、文本会话与 owner，统一 settable/只读/禁用准入，不增加第二编辑通道。外部 AX 写焦点必须读到真实焦点/firstResponder与公共 WINDOW_FOCUS；以 CFRange 写非空 Unicode 选区后精确读回，value 操作进入原 owner；失效 wrapper 与禁止写入零副作用。`composable_scene_probe.m:1404` 直接调用自定义 getter 不能继续充作标准协议判据，补正式 selector 和进程外 AX 的区分反例。F 只修 AX 适配，不接管 E 的正文、IME 或新字素机制。

**3．落实可见范围与屏外可达，不把裁剪当身份销毁。** `accessibilityVisibleCharacterRange`（约8572）当前无条件 `0..全文`；`reconcileAccessibilityActions`（约8931/9016）把 clip 为零的节点排除并退役 wrapper，均与原 B 要求不符。按同一 accepted 排版事实提供有界可见范围，无法得到时明确不可用，不能用全文/零矩形冒充；查询不得触发全文布局。对已物化且绑定仍有效的节点区分“在屏外”与“已移除/换绑”，复用当前 viewport/reveal 和身份，不把 GB 文档全量建成 AX 节点。以部分裁剪单行/多行滚动前后范围、保留旧引用→滚出→导航/reveal→滚回、真移除/ABA三组反例闭合；命中仍受当前裁剪限制。保留重排/resize有效身份，按 accepted 变化发需要的通知，空闲无通知/提交增长。树标准动作、虚拟节点可达若方案不明确，先用本地 Flutter AX 实现与测试作机制参考，再按 AGENTS 携未决证据升级指导，不自动咨询，不另起一套语义树所有权。

**4．一轮正常消费，建立真实 VO 因果链。** 修后复用两款消费者，生成侧经公开候选进入同一 accepted 事务。先建立一个能区别普通 Space 的 VO 按钮正控：记录紧邻前后完整 owner 回包、VO 就绪与目标身份，利用 VO 光标与键盘焦点分离或受控入口观察区分 AX 动作与普通 keyDown，补 VO 关闭时同和弦对照；不得只凭一次 owner 变化判 VO 成功。正常链合计覆盖页签/树变化、屏外可达、短输入编辑、同 key 重排及拒绝保旧，保留每款的 PID/semantic/scene 与可归因角色/名称/状态输出。实际失败修所属机制，直接 AXPress/普通输入仍单列。只在生产修改后做一次受影响测试、核心构建与含空格同源汇合；未变 F11 原证直接复用。

**推进与报告。** 先完成2/3的确定机制和1的启动判别，独立工作交错进行，最后汇合4，不把每个探针结果拆成新一轮文档。技术根因、公共契约/生命周期由当前执行者结合原始反例归因，问题升级与咨询授权按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)，不自动启动或替换咨询模型；普通明确接线直接实施。`laya-ask` 可批量归类日志，不能代替根因或通过判定。等待编译/咨询时推进独立工作；同 target、桌面串行，发现外部输入污染立即隔离该段，不重投用户动作。只短更本节与 ACTIVE，集中报告生产变化、判别结果和剩余项；保留 E/H 写集，不 stage/commit/push。

## 5. 不把“技术清单”误当交付目标

- **优先完整消费链。** 阴影、动画、无障碍分别是不同完整包；每包有真实普通应用和公共消费结果，不按每个函数/文档拆成一轮。
- **优化由实测选择。** 已有文字 tiling/缓存无需重建；普通 GUI 的资源缓存不能替代编辑器的范围存储/增量解析；后台布局、atlas、LOD、partial present 都要先证明瓶颈和语义可接受性。
- **框架完备性按使用面讨论。** 本表不是“所有现代框架特性都必须齐全”的清单，也不以控件数或阶段数计算百分比。每次接受注明平台、输入方式、负载、调用来源与尚未验证范围。

<a id="two-plus-one-product-lines"></a>
## 6. 下一阶段 2+1 分工方案与共享交付（2026-09-29）

**本次分工下发（2026-09-29）。** E 字素首包结束后，已按当前源码和证据安排 [macOS 连续写作/accepted 位置](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#editor-macos-position-session-next>)与 [OHOS 真实小文档编辑器＋惯性接缝](2026-09-26-harmonyos-executor-handoff.md#h-pharos-product-validation-next)两包，由用户分发提示词开工。原 F 转能力任务池，F5 仍未完成；本次没有自动创建、恢复或联系任何执行线程，实际运行状态只看 ACTIVE。

**方案边界。** 同一个 Pharos 产品的两端消费线，不复制业务或建立两个长期编辑器。H 原惯性返工和 F5 未完事实保留；新包完成以各自真实终点判断，旧未验不改名为通过。

| 主线 | 主要交付 | 框架责任 |
| --- | --- | --- |
| E：Pharos macOS 主线 | 同一产品的正文/事务/解析/SourceMap、共同应用服务与 macOS 编辑体验 | 编辑器遇到的通用文字、布局、语义或渲染缺口修回 CJGUI，并给出独立框架反例及必要第二消费者；不把通用能力藏进产品 |
| H：Pharos OHOS 主线 | 复用同一产品 owner/规则/服务，接 OHOS 宿主、存储端口与真实 HAP 编辑链 | 平台输入/绘制/触摸/生命周期在 OHOS 适配层；发现共同契约缺陷时修共同核心，保留 macOS 有限回归。设置/thermo 保留为小型机制回归，主要新消费目标转向真实编辑器 |
| +1：临时专项 | 一项明确的通用能力、跨平台衔接、性能瓶颈或独立审阅 | 每包明确写集、接入主线、验收终点与退出条件；完成即回归两条主线，不连续自增新包。F5/VoiceOver、未来效果或平台能力在池中按真实需求排序，不因非阻塞而永久丢弃 |

**同一产品、同一框架。** 两端不同的是平台宿主/适配器与能力支持范围；正文模型、版本事务、撤销、解析和共同语义维持同一实现。主 `src` 是公共机制来源，H `snapshot` 是可追溯的同步交付副本，不另立一套长期分叉规则。新增平台宿主目录可以独立，不能复制整份编辑器后两边分别修业务。平台未支持的能力明确发布边界，不能假成功或回落到私有 owner。

**共同核心每包一个集成人，不固定让 E 排队。** 包主责通常承担其跨层改动；H 当前 ABI/身份/共同滚动接缝仍由 H 集成，E 当前文字会话/字素/位置接缝仍由 E 集成。实际重叠的字段/函数/文件在动手前明确交接；对无法安全分开的同一文件修改串行。ABI 按 C 头、主仓颉镜像、H 镜像、生产填充/读取、两端针对性验证作为一个交付单元同步，不能一线改布局、另一线靠宽松身份判据兜底。冻结构建输入并记录来源/同步差异；同 target 串行，不以源码分目录推断产物隔离。

**发现方修到正确层。** 产品格式/规则/持久化语义留产品；通用 GUI 机制回 CJGUI；平台 API 差异落桥接。两条产品线都承担框架建设，不因取消常驻 F 而把所有新缺口搁置，也不能以两个编辑器能跑替代框架手写/生成/混合、共同 owner、普通消费者及公共发现的完整目标。指导继续在现有 roadmap 排通用缺口，必要时交 +1；不新增每轮台账。

**当前先后。** E先修跨片段/非空选区边界、连续写作镜像与表格命令预算，再落实已定的accepted统一位置/视觉导航；H先修Node ABI与冻结事件绑定两个GUI前置，同时做产品目标构建/存储端口，再交小文档源码编辑→人/Agent接续→撤销→保存重开。原惯性必做项仍在H包，完整惯性、visual大文件或所有IME回调不是小文档接入总前置。F5保留具体反例，暂不自动派发第三常驻包。

<a id="two-editor-write-sets"></a>
### 本次两线具体写集与交接

| 写入归属 | 本包范围 | 另一线的使用方式 |
| --- | --- | --- |
| E/macOS | 主 `src/text_session.cj`、新文字位置/意图模块、`composable_ui_window.cj` 的文字镜像/意图/查询函数；macOS renderer文字段；Pharos `main.cj`、editor_surface、edit_intent/SourceMap及表格命令 | H先固定上一包已完成的最小文本契约及指纹，按依赖同步到平台副本；新契约稳定后窄接入，不追随每次在途修改 |
| H/OHOS | `platforms/ohos/{host,snapshot,scripts}`、HAP和新产品OHOS宿主；产品文件平台端口/构建装配；共同viewport活动、滚动接受与split接续 | E不改这些函数或存储/目标构建；H不能把同文件内E文字段整体覆盖 |
| H统一集成ABI | Node/Event C结构、主仓颉镜像/H镜像、staging/填充/读取与尺寸哨兵测试；实际不兼容修改作为一份交付 | E新文字查询优先独立C头/查询值与仓颉模块，不往Node/Event继续加字段；不得为方便把E现有字段删掉或改变原义 |
| H薄平台装配，E桌面消费点 | 复用共享AppServices/DocumentSession/editor_surface；H新增独立平台端口或小文档命令装配 | 不大拆/复制桌面main私有控制器；确需调整桌面调用点由E集成，不能双方重写main |

同一文件不同函数仍需先查最新差异，按上下文最小补丁写入，禁止整文件从旧副本覆盖；同一函数只有一个集成人。实际重叠无法安全分开时只暂停该段，冻结待交接的最小接口/差分及来源，其他工作继续。两外部工具没有消息通道时不得假设对方已收到，必要窄交接在当前任务/状态说明，由用户转达，不自建跨线程调度系统。主src是公共来源，H snapshot按依赖同步并记录来源，不全量追赶未完成E包。

新一轮构建前固定输入/指纹；同target串行，必要时各用已存在的独立产物目录但不私建分支/worktree。E桌面输入与H模拟器的主机前台操作也须错开。构建/咨询等待时推进不会修改该次构建输入的工作；不因等待而重复稳定验证。

根因与方案由当前执行者结合源码、相关本地参考和可区分反例自主判断；反复失败按 [AGENTS 现行规则](../../AGENTS.md#independent-model-consultation)携证据升级指导，独立工作继续。只有用户当前明确授权咨询时，才按指定模型和范围执行；已有答复按适用前提复用，不能作为验收证明。Laya仅用于可复核批量分类。

**互斥与交付。** 同一桌面、模拟器 target 和同一构建目录只由一个执行者操作；等候时推进确实独立工作，完成后使用等待工具，不重复扫描或重跑旧绿色套件。临时 +1 触及 E/H 写集时，转交相关片段的独占集成权，其他独立工作继续。每个包保留反例、正常产品消费和必要第二消费者，按修改风险一次汇合；不把每个补丁拆成报告。未经用户要求不 stage/commit/push，不重启暂停任务/自动化；执行对象仍由用户选择。

## 7. 直接相关入口

- 方向与验收：[项目方向](../core/GUI_PROJECT_DIRECTION.md)、[共同信息与生成架构](../core/AI_NATIVE_UI_SEMANTICS.md)、[完整性标准](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)。
- 样式/场景：[composable_ui.cj](../../runtime/cjgui/src/composable_ui.cj)、[named style](../../runtime/cjgui/src/composable_ui_named_style.cj)、[generated](../../runtime/cjgui/src/composable_ui_generated.cj)。
- 窗口/后端：[composable_ui_window.cj](../../runtime/cjgui/src/composable_ui_window.cj)、[macOS renderer](../../runtime/cjgui/native/cjgui_internal_renderer.m)。
- 消费和已知范围：[runtime README](../../runtime/cjgui/README.md)、[设计资产导航](DESIGN_INTENT_INDEX.md)。

读取入口按当前 P 包选择，不要求执行者通读所有历史文档。本表基于源码与既有证据的规划，不把新增规划条目记作已实现。
