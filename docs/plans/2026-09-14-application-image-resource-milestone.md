# 大阶段：应用内图片资源复用与异步更新

2026-09-14，沿用户持续主线授权，由原执行任务 Terra/xhigh 协调 Luna/high 在原目录实施完整阶段。

## 交付与旧资产复用

开发者在同一应用的列表、详情和多个窗口中使用相同图片，框架复用准备好的资源；滚动换图、更新图片版本和关闭其中一个窗口，不阻塞其他窗口或使旧加载结果覆盖新内容。纯 UI 应用也可直接使用，对外操作仍通过应用自身真实对象与授权动作。交付通用图片资源生命周期能力及正常应用消费，不新造图片管理产品。

上一复杂场景阶段已按范围接受：指导抽查 scope 查表优化、真实 mixed application 的公开批次与 AppKit delegate输入链，核对8项当前源码哈希及两个probe二进制哈希；30批次16个屏外行、B接续输入、动态增删/锚点、resize/font、idle不重建提交及session释放已有受控证据。真实物理输入/IME、GPU完成/实际呈现和发布不在已验范围。本阶段不重跑所有既有scope或原生规模矩阵。

复用 [设计意图导航](DESIGN_INTENT_INDEX.md) 的资源/主题、自绘GPU、输入与单一内容归属，[避坑研究](../research/gui-framework-pitfalls-intelligence.md) 的缓存生命周期/重入与不盲目重绘，以及 [运行架构研究](../research/ai-native-gui-runtime-architecture-intake.md) 的局部视觉失效。当前 `composable_ui.cj` 已有 imageResourceId/version/path，`cjgui_internal_renderer.m` 已有按session的图片纹理/状态缓存、异步加载、generation防护、当前/候选节点强引用和完成失效；源码常量为8项/32MiB reusable cache、4 in-flight、16 pending、64 records。这些是复用起点，不等于整个应用或GPU总内存上限，不另建第二套图片运行时。

六主线取舍：本轮主攻自绘/GPU资源与异步调度，组件布局接通图片复用与状态展示；语义动作保持同一内容与版本，普通包消费检验通用性；文字沿现有系统排版/纹理路径，不扩富文本或IME引擎。跨平台、网络下载、磁盘缓存、视频/SVG解码、新主题系统均不在本轮。

## 实施范围

1. **核实重复工作并实现应用内共享。** 先测同一图片在两窗口/多组件的真实解码、纹理创建、加载任务和保留量，区分已有节点复用与跨session重复。优先演进既有资源所有者为具有清楚应用生命周期的共享复用域；独立窗口兼容旧入口。共享纹理必须匹配Metal device及资源身份，不能仅按业务ID串用不同路径/版本。公共仓颉接口不泄露原生对象；如需内部应用归属桥接，Terra检查影响范围、主线程和销毁次序，不能偷用无界进程全局字典。若共享本身不产生实际收益，及时带基线给指导调整方案，不堆无用缓存。
2. **加载合并和消费者失效。** 同一合法资源的并发需求合并为一次实际准备，并将结果通知仍然订阅该版本的窗口；窗口刷新仍走既有完成epoch/请求合并。新版本、同路径内容显式更新、移除节点/滚出、失败重试、窗口关闭后晚到完成必须有确定结果。旧generation/旧版本不能更新新目标；关闭A不取消B仍需要的任务，也不能让A的回调复活。失败不默默无限重试，恢复由明确新版本/现有重试约定触发。资源加载中、失败、就绪的展示与实际状态一致，已接受画面和候选事务不混用。
3. **有界资源与公平性。** 明确共享可复用缓存、排队/执行任务、场景及GPU在途强引用各自负责什么。复用现有预算思想，避免把每窗口4槽简单放大成任意应用并发；队列有界且不能饿死仍可见的窗口请求。淘汰不能释放GPU在用纹理，候选拒绝不能丢掉已接受节点资源。后台任务是否可取消按底层真实能力解释：取消订阅不等于解码已终止，不伪造active计数或清空字典假装释放。没有实际必要不加预取或复杂优先级体系。
4. **正常开发者消费与共同操作。** 复用一个现有正常应用，增加可重复的图片组件消费场景或可复用fixture：A/B同一资源、其中一处换版本、共享资源更新、滚动离开/返回、坏文件恢复、A关闭后B继续。图源来自小型本地测试文件/已有资源，使用不同可辨认图案证明真实像素更新，不能仅检查版本数字。外部脚本更新真实应用资源引用/版本，窗口看到结果并继续操作，已有授权不重复索取；不接入模型服务、不更改用户文件。纯UI模板和包含公开操作的普通消费者均保持可用，消费者不得复制private native源码或手工管理纹理。

## 验收

- 对真实重复工作或生命周期失败做可区分的基线/RED与修复验证；不把“新类型不存在”当旧业务失败。相同key复用、不同路径/版本/device隔离、多消费者释放顺序、失败与迟到完成、候选拒绝及session/app销毁是本阶段直接风险。
- 用同输入/构建条件比较一窗与两窗共享资源、冷热、重复换图和工作结束后的计数/保留量；相关耗时适用条件至少30有效样本，计时外验证内容。复用应有真实decode/upload/task减少证据；不把少分配等同端到端加速。若报告时延收益，给同条件前后分布、原始日志和计时边界。GPU缓存字节和在途资源分开，不能宣称整个应用内存严格等于缓存预算。
- 持续图片请求期间另一窗口的文本/滚动和真实公开读写保持推进；停止后pending/in-flight/subscriber等按定义收敛，不盲重建提交。当前已有调度和scope正确性复用，只有影响到的部分补回归。
- 可操作桌面时用隔离正常bundle验证可辨认图片和局部更新；锁屏/工具受限先用真实资源与renderer读回、窗口/状态探针完成独立工作，缺项保留，不反复撞锁屏。受控GPU读回不是物理显示证明。
- 相关仓颉/native/资源/窗口测试、根build、声明/FFI边界检查和diff检查。同cjpm target串行，继续已核实工具链/SDK。最终从含空格路径正式导出，使用本阶段能力的独立消费者实际构建/运行，保留source/preview/binary及原始证据，LICENSE/NOTICE保持完整。无生产变更不重复整套旧矩阵。

## 分工与持续推进

Terra亲自确定共享资源归属、异步完成/取消、GPU引用和公开边界，复杂跨层实现由其负责；方案清楚后由Luna完整执行fixture、资源版本/失败回归、正常消费者和导出，必要明确实现也交Luna。默认一个子代理，只在独立价值明确时并行，不重复重跑彼此测试。原生协作发实际父代理，首次核实消息送达，Luna不向指导app任务报日常构建或索取契约。

需要旧问题只阻塞依赖它的工作，完整阶段实施不按文件/补丁停工；同一失败跨模型累计并按AGENTS K3规则升级。普通工程取舍Terra自主，方向或重大未解风险给指导具体方法请求，同时继续独立工作。

当前工作区已有多轮未提交修改，全部保留，不stage/commit/push、不切分支、不建worktree；不碰其他模型推广或演示素材。同轮复用自有窗口，结束退出自有实例并保留证据，不动用户应用。ACTIVE切换当前阶段及范围，旧数值只作历史，不新增逐轮台账。完整交付或重大阻塞主动报告指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`，无需等30分钟提醒。

## 首轮指导复核：继续完成资源生命周期与消费

指导只读抽查共享域/订阅/加载次序，以及domain/public日志。接受同key双窗一次加载解码、可区分图片读回、一个共享请求发起窗关闭后另一订阅窗成功的对应范围；未重跑测试，不将其扩大为队列压力、公平性或完整导出证明。以下是本阶段原目标内的必要继续工作，Terra诊断结构、Luna执行明确回归/消费，不另开切片阶段：

1. **无人需求的排队请求。** 当前 `CjguiRemoveComposableImageSubscriptions` 移除 requester；`CjguiStartNextComposableImageLoads` 对无live requester的pending项放回队尾，未区别“测试gate暂缓”和“需求已消失”。复现A占满16个未启动pending、B同域存活、A关闭/移除图片后B请求新图片。若孤儿pending未回收，B可能永久Busy。先用明确加载gate构造可区分顺序，再修清理：无人需要的未启动请求应退队/复位；仍有B消费者的请求保留；已启动工作如底层不可取消则等待真实完成且阻止过期发布，不用清空计数冒充取消。
2. **候选和请求归属。** 当前commit reconcile只清subscriber，requester只按session+generation登记，移除组件/拒绝候选后旧requester是否还能触发无用加载需实际验证。需求应能对应已接受节点、当前候选或明确预加载，不让活窗口曾经访问过的所有版本永久算活需求。复用既有事务，候选拒绝时保留旧画面和旧共享需求，清除候选独有需求，不打断其他窗口。
3. **预算与繁忙公平性。** prune保护scene/loader/pending键且无victim时break，源码常量不是严格上限证明。用超过8张同时显示图片、超过32MiB缓存压力和超过64record的版本churn核查实际cache/scene/in-flight保留。缓存与场景/GPU强引用分开；给出明确可执行预算，别只把超额情况改名后仍声称8/32MiB/64严格成立。只需代表性针对测试，不新增海量无关矩阵。持续请求时B真实输入/公开读写仍推进，停止/关闭后pending和真实后台工作按各自定义收敛。
4. **完成本轮独立消费。** 当前报告没有最终含空格目录正式导出及使用该能力的独立消费证据。现有normal bundle与上阶段preview不替代。复用原exporter和模板，使用导出内资源构建/运行一个多窗口图片消费者，查源覆盖环境和路径，不复制未导出的私有native或硬编码作者仓库资源；纯UI与公开调用可沿对应既有模板做受影响检查，LICENSE/NOTICE完整。保留原始manifest/source/binary/实际资源来源。

另：当前域按NSApplication+Metal device共享，即同一原生应用内多个仓颉application实例可能共域。请在状态/文档明确该边界，不误称仓颉application实例隔离，也不无证据把它当权限漏洞。30次7–8ms是受控等待ready结果，保持原测量边界，不据此宣称端到端优化。

## 本轮继续工作结果

- **需求生命周期。** 测试 gate 下先复现 A 占满 16 个 pending、关闭后 B 只能 `busy` 的 RED；修复会移除没有存活 requester 的未启动记录，但仍把 gate 暂停的存活需求保留。Green 中 B 在 1 个 pump turn 后 `ready`，pending/in-flight 均收敛为 0。另有 20 个显式 preload 的 RED：16 个启动后其余 4 个永久 `busy`；修复后 20 个实际加载都在 6 个 pump 内结束（8 ready、12 因 reusable cache=8 被按预算复位为 `unrequested`），而非保留 20 张纹理。原始 RED/green 分别在 `/private/tmp/cjgui-application-image-explicit-overflow-red/probe.stdout.log` 与 `/private/tmp/cjgui-application-image-explicit-overflow-green-2/probe.stdout.log`。commit/rollback 现在清理候选/旧 accepted-scene requesters，同时保留明确调用公共 `prepareImageResource` 建立的 preload；session close 仍移除全部请求。强制候选 present 失败的回归确认旧蓝图仍 ready、珊瑚候选回到 `unrequested`，实际加载计数保持 1。
- **资源边界与压力。** 资源域按同一 `NSApplication` 与精确 `MTLDevice` 共享，不是每个仓颉 `CjguiMacosApplication` 实例隔离，也不是无界进程全局缓存。9 个同时显示的图片保持 9 个 scene refs，而 reusable cache 实测为 8 项、8,192 bytes；36MiB fixture 被已接受 scene 持有时 reusable cache 为 0 项/0 bytes；65 次版本 churn 后 resource records 为 64。因而 8 项/32MiB 是 **可复用缓存** 预算，4 是 domain in-flight 上限、16 是 pending 上限、64 是 record 上限；不把它们误报为总应用/GPU 内存上限。
- **真实交错公平性。** `verify_complex_scene_application_mixed.sh` 在同一受控 normal application 中让 A 的 16 个显式 preload 先 gate 排队；A 首次真实公开 UDS `REPLACE_RANGES` 与 B 的普通 AppKit text delegate 输入同轮发生后，16 次实际异步加载完成，peak in-flight=4、peak pending=16。该运行同时完成 30 次授权公开写入、A/B 最终读回、idle 无重建提交和 native session 回收；原始根为 `/private/tmp/cjgui-image-fairness-final/`。这证明调度和公开/原生输入可交错推进，不是物理键盘、GPU completed 或人眼呈现证明。
- **独立导出消费。** `verify_framework_preview_consumption.sh` 从含空格的隔离导出目录构建并运行仅使用公共仓颉 API 的图片双窗消费者，使用导出内 `composable-beacon.png`。两窗均 `ready`，关闭 A 后 B 仍 `ready`，日志仅有 1 次真实准备启动；manifest 为 `/private/tmp/cjgui-framework-preview-consumption.X4Xe9P/image-multiwindow-preview.manifest`，source/preview payload 同为 `0b6908f5ac43cdda730eb96ea8921b012092ce7de7d3d5a830e35e4dc42de2b4`，且保留 bundle hash、资源来源及 `native_private_copy=false`。这是构建/受控运行证据；未声称前台人工可见性、安装、公证或发布。
