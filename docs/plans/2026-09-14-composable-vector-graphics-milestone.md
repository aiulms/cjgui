# 大阶段：可组合矢量图形与共同操作

2026-09-14。原目录，Terra/xhigh 负责完整交付并协调 Luna/high；不提交推送。本阶段沿既有仓颉自绘框架方向实施，不制作新的独立产品。

## 目标与取舍

开发者能用仓颉组件描述线条、折线、圆/椭圆与简单闭合图形，组合文字、图片、滚动区域和弹层，直接得到可缩放、可交互的 GPU 画面。一个应用可把同一对象的颜色、位置或数据同时交给人和已授权外部接口修改；修改后画面、命中区域和公开读回一致。交付可用于图标、图表、关系图的通用基础，不能只画一张演示图或为示例新增 native 业务分支。

六主线取舍：本轮重点推进自绘表达、组件组合和局部几何更新；复用已有文字排版、图片资源、应用调度、稳定身份、授权/CAS与观察入口。菜单阶段的主要能力已有受控证据，普通输入和发布的未验边界保留；不继续扩大系统菜单项目。长单段文字热点仍承接，当前没有新根因，不重复过去失败路径。本轮不做跨平台后端、自研输入法、完整 SVG/CSS、通用复杂路径布尔运算、富文本编辑器或白板产品。

## 复用与必要旧问题

- 阅读 [设计意图导航](DESIGN_INTENT_INDEX.md) 的自绘、组件、资源和共同操作主题；复用 `composable_ui.cj` 的布局/clip/identity、`composable_ui_window.cj` 的候选接受和局部刷新、native 的有序 Metal 合成/形状合批，以及 [有序 GPU 合成](2026-09-13-ordered-gpu-composition-milestone.md)、[复杂场景更新](2026-09-14-complex-scene-update-performance-milestone.md) 的真实测量入口。旧 display-list/value-only 文件仅作设计对照，不复活历史审计链。
- [框架避坑](../research/gui-framework-pitfalls-intelligence.md) 的绘制顺序、布局唯一归属、无谓重绘、主线程和释放风险继续适用；其历史禁令不恢复。共享动作遵循 [共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)，图形不能成为另一份可写业务状态。
- 菜单阶段分项接受：Quit 拒绝/允许、Undo/Redo owner 优先级、同投影不重建、最终独立包消费。指导读取了三组原始 result；最终 preview 的 host/window/session/native 实际文件与当前源码相同。退出 probe 是稍早 native 版本，后续菜单变更的同源验证不能冒称全套退出场景都在最终二进制重跑。
- **必要退出边界随本阶段承接，不让它阻塞独立图形工作。** 当前 `applicationShouldTerminate` 在没有 key CJGUI window 时返回 `NSTerminateNow`，但无 key 不代表没有存活应用 owner。Terra先复现“应用拒绝退出，窗口仍存活但没有 key”的标准 Quit 是否绕过 owner；不要改用随便一个可见窗口冒充应用归属。将退出意图接至已有应用生命周期负责的通道，作用域独立于当前键盘焦点，保留合并/拒绝/允许/关闭清理及旧单窗宿主的明确行为；不新增业务退出状态机，不在主线程同步等待仓颉。只补这条有关联的高风险边界和最终来源，不扩展整个系统服务。若受前台条件限制，保留精确未验事实并继续图形交付。

## 实施范围

1. **公开、纯值的矢量描述。** 在现有组件/scene 中提供可复用的几何与画笔表达，覆盖线段、折线、圆/椭圆、简单闭合多边形的填充和描边，至少明确线宽、端点/连接、透明度、逻辑坐标与布局缩放语义。Terra决定最小一致接口，保留现有组件兼容，不向用户暴露 Metal/AppKit 对象或 GPU 指针。声明几何点数/复杂度上限及非法、非有限、退化和不支持形状的失败行为；不默默裁掉数据伪称支持。曲线、洞与复杂自交不要求本轮完整实现，支持范围必须明确。
2. **进入真正的自绘主链。** GPU 绘制几何，复用形状 pipeline/有序合成；必要的 CPU 几何准备有明确归属和有界缓存，不把每个图形先截图再贴图当作矢量支持。几何、样式和布局变化触发正确失效；文字/图片/图形/弹层混合顺序、alpha、嵌套 clip、不同缩放遵守同一 scene。只在实际兼容且连续的绘制项合批，不能跨遮挡重排。
3. **交互与外部修改共用对象。** 默认装饰图形不截获输入；选择交互图形时，用已接受几何做准确命中，不能只拿整个外接矩形拦截背景按钮。复用稳定身份、pointer capture、focus和真实 action，不另建画布事件循环。至少有一种形状可被人选中/调整；外部在已有授权范围内修改同一对象后，形状、属性面板、命中区域与公开读回一起更新，人能继续调整。陈旧写入拒绝、对象删除/换绑、捕获期间外写沿既有 owner/version 规则，示例数据必须只有一个明确 owner。
4. **实际复用与开发者接入。** 做两个不同使用场景：一个纯 UI 的小型图表/图标组合消费者，一个结合现有共同操作入口的图形属性消费者；至少一处复用到已有正常应用，避免只增加孤立 probe。业务代码仅使用公开仓颉能力，换形状/数据不改 native。最终含空格的独立导出实际构建运行新矢量消费者，README说明接口、坐标/命中/失败语义和 experimental 状态。

## 验收与性能

- 覆盖填充/描边、半透明重叠、混合文字图片顺序、clip、非整数位置与至少两个受控缩放、线端/转角、退化/容量超限及失败保留旧场景。真实 drawable 或已有可解释像素证据证明 GPU 路径，单纯返回成功/计数不能证明画面。抗锯齿验证用稳健采样/误差边界，不把不同机器整幅像素 hash 固化成门槛。
- 正常消费者完成一次“人操作 → 外部读取具体对象 → 授权修改 → 窗口更新 → 人接续”，留具体值和版本；受控 native、桌面自动化、脚本外部调用分别标记，不称真实模型参与。锁屏只跳过真实桌面操作，先完成同一 owner 的代码/受控链路。
- 取小/中/接近本阶段声明容量三个实际负载规模，记录几何准备/上传、实际 draw/batch、局部修改与整体尺寸变化成本，样本量和冷热条件明确。静态 idle 不生成新几何、不重传不相关资源、不重复提交；相同几何多次使用不逐帧重复准备。改变一个对象应保持其他对象的几何/文字/图片缓存有效。新能力无历史对照时报告成本，不宣称提速；旧路径比较需同条件，发现普通矩形/文字明显回退先定位。
- 在一次正常应用负载中交错局部几何修改、外部操作和另一窗口输入，验证公平性与关闭后 CPU/GPU 资源收敛；只覆盖本轮改变的生命周期，不补跑历史全矩阵。几何容量、缓存预算和场景/GPU仍持有的资源分别说明。
- 必要源码/FFI/公共声明检查、相关 tests/build、最终独立消费和 diff 检查按 AGENTS；同 cjpm target 串行。保留实际存在的原始日志与最终 source/bundle/preview 对应；人工物理输入、完整呈现延迟、安装公证和发布仍不由这些证据推导。

## 分工与完成

Terra先确定几何/scene/FFI与命中边界，亲自处理 GPU/退出生命周期和跨层根因；Luna/high完成明确的几何值/验证、消费者、回归、独立导出及文档工作包。默认一个 Luna，写集隔离、原生消息回实际父代理；接口明确后把可并行的完整包交出去，不让 Luna 只收零碎补丁。指导只复核方向、关键方案和最终证据。三次有效修复仍失败按 AGENTS 升级，不用 K3。

本页即完整任务，不另开执行卡。必要旧边界与新图形能力一起推进；完成公开 API、真实 GPU、交互共同状态、性能/生命周期与独立消费后统一回报指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`，包括源码/证据入口、未验边界与下一主线建议。阶段内部小项完成不停止。自有临时实例整轮复用，结束统一退出；保护用户实例和其他任务改动。

## 本轮交付与验证（2026-09-14）

执行已提交首轮完成报告，指导复核后整阶段继续接续，未提交或推送。公开仓颉层新增纯值几何/画笔和 `cjguiComposableVectorGraphic`：line、polyline、ellipse 与最多 12 点的 simple polygon；非有限值、越界、相邻重复点、零长度/面积、自交、容量超限、无可见画笔及非法端点/连接均返回失败。Metal/AppKit/GPU 指针不进入公开值对象。默认图形不截获输入；声明 action 后，native 按同一几何命中，而非节点外接矩形。

native 复制已接受的 geometry payload，在已有 Metal shape pipeline 中三角化/描边并按 scene 声明顺序合成；不预光栅化为图片。主合成改为可复用 4x MSAA target 后 resolve 到 drawable。受控真实 drawable probe 读到 line `26,173,240,255`、polyline `31,224,89,255`、半透明重叠 `106,127,150,255`、凹多边形 notch 保留背景椭圆 `196,32,47,255`；1x 抗锯齿边缘为 `23,107,146,255`，严格介于背景 `20,41,51` 和实线之间。ellipse 内实际触发选择，落在其 layout bounds 但几何外的点继续交给背景按钮；1x/2x 的实际像素均为蓝线。2/6/12 点负载记录上传 `110352/116688/135168` bytes、batch `35/37/43`、单 batch 上界 `3168` bytes；这是当前受控成本记录，不是跨版本提速或物理呈现延迟声明。原始 native artifact：`/private/tmp/cjgui-composable-vector-native`。

公开消费者分别为纯 UI 图表和已有 `CjguiSharedOperationList` 的颜色投影。后者先通过公开 UDS 授权 `SET_MARKED` 将 `isMarked` 写为 true，再由人侧 `vector.shared.toggle` 读回 false/blue，二者没有第二份图形业务状态。当前 consumer manifest 为 `/private/tmp/cjgui-composable-vector-consumers-final/manifest`；含空格、迁移后的导出 Preview 从导出框架构建运行并给出 `vector_chart_consumer=true`、`vector_external_color_write=true`、`vector_window_projection_readback=true`、`vector_human_action_after_external=true`。保留的 Preview evidence root 为 `/private/tmp/cjgui-framework-preview-consumption.y6deHP`，其中 `vector-preview.manifest` 可复核。

回归：`verify_composable_vector_graphics_values.sh` 通过纯值/平台无关拒绝路径；`verify_composable_vector_graphics_native.sh`、`verify_composable_scene_renderer.sh` 和消费者/Preview 入口通过。合批回归记录 7 个独立绘制压为 3 个连续 batch 且 `pixels_equal=true`。无 key 标准 Quit 的最终 LaunchServices receipt 为 `/private/tmp/cjgui-command-menu-exit-native-runs/run.Eff6E2/result`：两次拒绝保留连接与 B 的 `persisted@2`，第三次允许后 application=false、window count=0。为避免 AppKit 隐藏转场采样到中间 key state，probe 仅在既有有界 application scheduler 中最多观察 8 轮，不建立嵌套 run loop，也不从窗口选择 application owner；本次实际一轮稳定。

人工物理鼠标/键盘、IME、VoiceOver、完整 physical presentation latency、安装、公证、发布和真实模型参与仍为 `not_run`。下一阶段应基于新的正常消费者与主线程/renderer 热点选择，不应把本轮固定 12 点简单几何扩张为完整 SVG、路径布尔或白板产品。

## 指导复核后的性能与共同操作接续

指导只读核对 `/private/tmp/cjgui-composable-vector-native/result`、消费者源码与 native 实现。真实像素和几何内外命中有分项进展，不能用本轮五个绘制节点、2/6/12点变化的单次成本记录代替原任务要求的实际规模、局部复用和双窗混合负载。原 `JogQWT` 整个导出目录不存在；执行随后已补留 `/private/tmp/cjgui-framework-preview-consumption.y6deHP/vector-preview.manifest`，指导确认存在。现在继续实际代码交付，最终实质变更后保留对应证据，不再单独为目录问题重跑全量。

1. **抗锯齿策略与旧路径成本。** 当前 present_clear 无条件创建4x MSAA整窗附件，两类 pipeline 也固定sampleCount=4；无矢量的普通文字/表单窗口同样承担此成本。先在同条件普通矩形/文字场景核验新增附件的大小/分配复用和 CPU提交/GPU计时（可用时）的变化。优先保留无矢量场景原单采样路径，仅需要矢量抗锯齿时选择匹配的 pipeline/附件，或给出有实际成本证据的更优局部方案；不能只把全局4x称作可复用而省略成本。混合图片文字仍要正确，sample变化、resize、分配失败和关闭须有明确资源生命周期；不引入每帧pipeline创建。不要为本任务再造通用渲染后端。
2. **实际几何复用与可比较成本。** `CjguiAppendMetalVectorShape` 当前每次绘制都重算ellipse ring的三角函数并重新追加各形状顶点；仅用idle没有scene提交无法证明局部更新复用。复用accepted节点/COW生命周期，建立必要且有界的几何准备复用，区分几何内容、布局变换、paint与clip的失效；不要建立无归属全局缓存。按实际节点预算取小/中/接近支持容量三种图形对象规模，各至少30次同条件局部样式/几何更新，尺寸变化另做必要验证。记录几何准备、上传/批次、真实CPU阶段耗时和附件/几何资源保留；区分首次和热态。改变一个对象时，其他对象不重复几何准备，旧图片/文字缓存不无故失效。新几何能力无历史对照只报成本，旧普通场景若回退必须解释/解决，不能改成“不宣称提速”代替验收。
3. **同一对象真实输入与双窗负载。** `framework_preview_vector_consumer.cj` 的所谓 humanAction 实际是 `window.invokeCommand`，这证明命令与外部共用owner，但未证明人在图形上操作同一owner。将这个正常消费者接成实际可操作窗口：正常鼠标事件经几何命中/既有动作进入该列表owner，外部读取具体对象，授权修改后画面/属性/命中一起更新，再次窗口操作同对象并读回。至少增加一次几何变化而非仅SET_MARKED颜色切换，复用已有owner/CAS规则，不另造图形业务状态。已有normal native受控事件可先证明，前台可用时补桌面自动化；锁屏只记录后者未验。另一窗口输入与一组局部几何外写同轮推进，结束后两窗 idle 和资源收敛。两份独立probe的成功不能代替这条共用状态链。至少一个已有正常应用复用一处矢量组件，不把新probe当全部应用消费。
4. **一次最终交付。** Luna在正式exporter清单和消费者写集内继续工作，无需逐文件问指导；核对source哈希枚举含两个vector源、component与native/host等实际依赖。最终源码完成后保留KEEP_TMPDIR=1的实际目录与manifest/log，注明公开命令调用、真实事件和窗口截图各自的证明范围；源/产物无法对应时直接列欠项，不标整阶段完成。必要runtime build/test与局部native/消费回归按实际改动串行运行，不重跑所有旧阶段。

Terra负责MSAA/几何缓存的主链方案、GPU生命周期与高风险衔接，Luna/high拿到精确helper和写集后完成交互消费者、混合负载/规模回归和正式导出文档。指导只接关键升级和整个阶段汇总，常规签名/编译错误/构建时段由父子直接协调。若没有可执行独立工作，子代理交付后final结束，接口到位用同一代理followup继续，不常驻发送等待消息。完成四项整个交付后主动回报；三次有效失败按AGENTS升级。

## 最终交付（2026-09-14）

四项接续已完成，未提交或推送。渲染器只在 scene 含 vector node 时配置 4x MSAA target 并 resolve 到 drawable；普通文字/矩形路径为 1x、额外 multisample attachment bytes=0。当前 native probe 对 vector 记录 `4/4` samples、attachment `38886400/38886400` bytes、pipeline builds `2/2`，而 normal 场景为 `1x/0`；resize 后仍保持 matching sample/pipeline 生命周期。原始结果为 `/private/tmp/cjgui-composable-vector-native-final/result`。

accepted scene node 现在以 COW 所属的 prepared triangle payload 复用 geometry；几何变动才作准备，paint alpha/color、layout/clip 不重复构造拓扑。16、128、480 个实际 ellipse 图形各做 30 次局部 paint 更新，分别为 geometry preparations `16→16`、`128→128`、`480→480`，pipeline 均为 `1→1`，idle submission delta=0；相应 attachment、prepared bytes、batch、encoder CPU 和每个原始样本保留在 `/private/tmp/cjgui-composable-vector-scale-final/result` 与 `manifest`。这是同条件受控成本记录，不宣称 GPU completed、物理呈现时延或跨版本普遍提速。

正常 public-only 双窗消费者持有唯一的 `CjguiSharedOperationList` 业务 owner。外部先读具体 window field，再经授权 `SET_MARKED` 将椭圆从 `center=80,55 radius=42,30` 改为 `center=130,85 radius=24,20`；窗口字段读取确认几何和颜色。生成的 current-source 测试 variant 用实际 native pointer：旧点命中 background、新点命中 vector，第二次输入再次由同一 owner 回读，且 B 图表 pointer 与 A 外部写在同一 application turn；结束时两窗 idle 并关闭收敛。生产 source 本身不含 native/foreign/test seam；其 manifest、stdout、binary fingerprint 位于 `/private/tmp/cjgui-composable-vector-consumers-final/`。

最终 `KEEP_TMPDIR=1` Preview 从新导出的框架复制公共消费者，迁移到含空格目录后构建、启动、外部几何写入和普通输入均通过，`vector=build_and_run`；source/preview consumer SHA-256 均为 `ae087af61bd932b04f89ddec48fd88331e2779aaf6a0d59978138099a90cb1d7`，bundle SHA-256 为 `be8dc9e30fb96d0e8e6a3b6ce97e95d65fb29be7cc3ef75a18041d5028646765`。最终 vector manifest/log 为 `/private/tmp/cjgui-framework-preview-consumption.MeEyLO/vector-preview.manifest` 和 `/private/tmp/cjgui-framework-preview-consumption.MeEyLO/vector-preview-run.log`。

受控 native pointer、UDS 与导出 bundle 证明范围如上；人工物理鼠标/键盘、IME、VoiceOver、完整 GPU completed/物理呈现时延、安装、公证、发布和真实模型参与仍为 `not_run`。下一主线应从实际应用的 renderer/主线程热点选择，不把本轮 12 点 simple geometry 扩张为完整 SVG、路径布尔或白板产品。


## 指导接受范围与后续承接

指导已读native/scale/consumer结果和最终MeEyLO导出，七项关键源文件相同，未重跑测试。几何/像素、COW准备缓存、无矢量1x和受控native同owner命中接受。公开导出源码默认只调用B的chart.input；human_readback读取A仍为外写后的状态，不能证明人接续A。因此“整个四项全部完成”的执行总结超出证据，正常导出同对象输入与已有应用复用、几何/resize缓存验证仍待完成。它们明确随[矢量GPU提交效率与正常应用接续](2026-09-14-vector-submission-efficiency-milestone.md)承接，与已测得的重复顶点/小批次热点一起推进，不标成已验。
