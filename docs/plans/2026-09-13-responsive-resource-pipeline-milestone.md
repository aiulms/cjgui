# 大阶段：资源加载与界面响应

2026-09-13，Terra/xhigh，原执行任务和工作目录。指导已抽查 COW configure/setter/commit 与输入 owner revision，接受局部减少对象复制的实现和报告范围；未自行重跑构建。前阶段15组最终样本不等于已交付同条件前后加速对照。

## 目标与取舍

让正常应用在图片首次加载、替换和多资源切换时仍能输入、滚动和处理外部操作，交付可复用资源准备/缓存/完成通知及两种应用消费。复用[设计导航](DESIGN_INTENT_INDEX.md)、[资源阶段](2026-09-13-render-resource-efficiency-milestone.md)、[局部提交阶段](2026-09-13-incremental-scene-submission-milestone.md)的资源版本、窄平台桥接、单一调度器、scene事务和in-flight引用；落实避坑原文的主线程阻塞、资源归属和过期回调教训。当前 CjguiComposableImageTexture 在 setter 同步 newTextureWithContentsOfURL，约10.4ms是包含加载工作的 setter 测量，不能未经分段就定性为GPU编码耗时。

六主线中本轮继续高性能自绘的资源侧，同时检验真实人侧输入和外部接续；不是增加样例业务。已有COW保留，重排/resize仍近全量的边界保留；长文本、系统IME/VoiceOver与实际呈现限制不冒充完成，也不阻止本轮独立工作。不重写布局引擎，不做联网下载器或Agent壳。

## 必要旧问题

1. `syncProjection` 的 sameRenderedScene 分支在 commitSceneRefresh 前可能更新 renderedRoot/scene，但 nativeSceneAccepted 仍false；commit抛异常仍进入 rollback。以无绘制差异但结构/命令变化的真实public participant验证，明确不可逆提交边界，不让正常present路径修复遗漏该分支。正常实现优先提交前准备、提交时交换；应用违约异常按明确terminal结果处理，不称恢复旧scene。不能仅增加一个Bool而忽略真实状态交换。
2. 性能reporter目前仅计算运行后的源码digest、输出固定binary路径，未保存raw输出/二进制hash，也未把idle/recovery完整性纳入退出判定。补本轮所需最小证据：运行前后source一致性、实际binary指纹、原始日志、准确场景/样本覆盖与idle/recovery验证。15组最终结果和真正前后对照分别标记；不扩展成通用审计平台或重复历史所有测试。把前阶段交付数值和真实证据位置移到其阶段文档，ACTIVE保持短状态。

## 实现与应用验收

1. 分开测路径解析、缓存命中、文件读取/解码、纹理创建/上传、场景提交和同步readback；确认最主要主线程成本。旧计数名或总setter时间不当细分结论。相同版本复用不得重复解码；版本变化必须失效，同路径不同资源/窗口不得错误共享。
2. 提供框架内部有界资源准备与完成接续，必要公开入口允许应用预加载/查看状态。加载结果属于派生资源，业务值仍归应用owner；主线程只接受匹配session/resource/version/候选代际的完成结果，完成通知走既有调度/失效路径，不开第二事件循环。复用已有线程设施若归属合适；传输worker满载不能饿死渲染，资源worker也不能无界创建。后台调用的API/内存/Metal队列安全需源码和对应官方契约确认。
3. 保持明确ready/loading/failed结果。已有旧画面在新资源未准备好时如何保持、首次加载如何显示，由可解释的框架契约和应用选择决定；不假报加载成功，不把失败资源静默永久显示为新版本。完成时只刷新必要窗口/节点，不60Hz轮询。旧同步API可兼容，但正常应用必须实际消费新响应路径；不只增加无人使用的预加载函数。
4. 缓存同时考虑资源数与内存预算、活动/候选/in-flight资源引用和淘汰条件。旧 cache prune 会移除所有非active项，核实是否令图片切换每次重新解码；按真实负载允许有界复用，不无限保留。连续A/B切换、连续新版本、取消、移除、关窗、错误文件后恢复均不晚写新对象、不提前释放GPU资源。
5. 两种正常Host布局消费，至少一个包含图片加载期间的文字编辑/滚动，另一个同时执行外部授权操作和资源替换。独立Luna/Terra仅按公开文档集成并实际读回/关闭，写集隔离。用户同ID窗口不操作，使用隔离bundleId和临时资源。

## 交付标准

相同实际图片/尺寸/版本工作负载前后各30次，明确冷/热缓存，报告输入/外部动作完成延迟p50/p95、主线程加载/提交、解码次数、队列与资源峰值及idle恢复。不预设性能百分比，不以异步函数快速返回冒充资源完成变快。取消/失败/版本超越/关窗晚完成有针对性断言；受控像素检查真正显示对应资源版本，GPU完成与呈现分开。资源准备API读回不能代替正常GUI消费。

按AGENTS完成相关runtime/core/native/Host回归、1.1.3 build --skip-script、FFI/公开声明及diff检查。技能按需查，CodeLattice若live root仍拒绝则源码补证。遇上游工具链问题先最小复现和旧账本归因，主动报告指导，不让workaround埋在实现里。

锁屏跳过真实桌面依赖继续代码/成本/独立任务，记录系统IME等未验项不冒称通过。两次实际修复失败按既有K3规则，环境无效不反复撞。原目录、不切分支、不stage/commit/push/发布、不改安全设置、不关闭用户实例。完整交付或实质阻塞主动报告指导；不能做完异常小修或仅基线测试就停工。

## 本轮实施结果（2026-09-13）

### 已落地的资源契约

- `MTKTextureLoader` 的 URL 加载已改为完成回调；回调先回到既有主 AppKit run-loop，再按 session generation、资源 key 和当前引用判定是否接纳。没有增加轮询 timer、第二事件循环或公开原生对象。Apple 仅提供整个 loader 回调区间，故测试把它标为 `metalkit_url_loader_total_us`，不虚构文件读取、解码和上传的分别耗时。
- 每个 renderer session 维护独立的 key（逻辑资源 ID、版本、规范化路径）、`unrequested/loading/ready/failed/busy` 记录、8 项/32 MiB LRU 纹理缓存、4 个在飞加载槽、16 个待启动项及64个记录上限。`busy` 表示有界队列暂满而非文件失败：当前/staged 场景中的 busy key 按稳定声明顺序补入既有 pending 队列；不在场景中的显式预加载保持可读的 busy，等调用方重试。活动节点同时保留实际纹理 provenance，cache 淘汰只移除可复用引用，不能把已显示的同 key 重置为待请求或重启加载。跨窗口不共享；关闭时清空记录，过期回调只能命中已存活且 generation 匹配的 session。
- `CjguiComposableUiWindow.prepareImageResource` 与 `imageResourceStatus` 是窄的公开实验入口，只返回状态标量。普通场景 setter 可接受 loading/failed；替换期间保留旧纹理作为可解释回退，首载保持普通占位，失败只由显式 prepare 重试，避免无界自动重试。
- 资源完成代际进入原有 `refreshIfNeeded` 判定，只重 stage 图片节点；未被当前/staged 场景引用的预加载完成不唤醒空闲 UI。same-rendered-scene 的 public participant commit 异常已先标记 native 接受后终止关闭，不能再伪回滚。

### 当前运行证据

- 最终 `verify_render_resource_efficiency.sh` 通过，并把 Cangjie stdout 与并发 native `NSLog` 分存为 `/private/tmp/cjgui-render-resource-efficiency/probe.stdout.log` 与 `probe.stderr.log`，30 条原始样本可无交错解析。30 次请求到 ready：cold p50/p95 `13/13 ms`，hot `8/8 ms`；ready 到匹配 native scene 接受：cold `3/3 ms`，hot `8/8 ms`。闸门保持的 30 次真实 FIFO 文字输入覆盖 `loading` 与 `busy`，p50/p95 `7/10 ms`（最大80 ms）；它断言的是 controller 已实际接纳输入，不是 enqueue 返回。A/B 热切换不重复解码；更高版本超越、缺文件后显式修复、关窗晚完成均有断言。
- 停止业务更新后，12 张临时生成的16px小图在8项 LRU 下精确收敛至 `launch/decode/completion=12`，6 张1254px大图在32MiB预算下收敛至 `6` 和 `cache=5`，两组连续16个普通 turn 的提交/计数不再变化。24张合法小图的受控瞬间为 `loading=20`（4 in-flight + 16 pending）、`busy=4`、`failed=0`；解闸后真实场景公平清空为24 ready、24次 launch/decode、8项 cache，无 timer 或第二队列。最终普通窗口的观测为 `async_launches=71`、`peak_inflight=4`、`peak_pending=16`、`cache_bytes=31,450,320`；前两个峰值是本测试事实，不是全局吞吐承诺。文本、字体、图片重绑、滚动、resize、idle 各30样本，idle 节点写入增量为0。
- `verify_composable_ui_window_controller.sh`、`verify_composable_ui_appkit_text.sh`、`scene_submission_scale_report_test.py`、实际资源 FFI 编译/探针及 `cjpm build --skip-script` 都通过。controller probe 现在先经正常 turn pump 等待首图完成，再断言空闲读取和选择输入不额外提交；它不把产品路径同步化。历史 `verify_native_bridge_cjpm_integration_boundary.sh` 仍硬性要求 `cjpm.toml` 不含 `[ffi.c]`，与当前已落地的 FFI 路线冲突（exit 5），故不作为本阶段绿色门禁，也未为迎合它撤回当前实现。
- scale reporter 现保存 raw log、运行前后源码 digest、实际 probe binary SHA-256，且把15组各30样本以及 idle/recovery 完整性放入退出条件。规模 probe 的图片案例改为两个已声明版本 A/B 重绑，避免把 COW 规模测试伪装成无界资源入队压测；连续新版本容量测试留在资源探针。
- Adaptive Layout 已在隔离 bundle ID 的真实 normal Host 验收并关闭：点击“主组件切换资源”后，公开 Python client 对 `target=7101` 完成30次真实 `SET_MARKED` 写入并每次读回版本；最终原始日志为 `/private/tmp/cjgui-adaptive-public-owner-latency.log`，本轮本地 socket 往返 p50/p95 `21.741/22.395 ms`，最终 version=30，并读回 accepted/submitted/overlay scene=32、frame=32、pending=none。此前同一隔离宿主的 AX投影也显示 version=30。Notification Threshold 的 checkbox 与“应用配置”确实使 AX 从“已停用”更新为“已启用”，草稿/基线版本更新，但当时正式入口仍是旧手写循环/打包，**不计为 normal Host 验收**；该真实窗口行为保留，normal Host 标签已在后续统一入口阶段校正。两者均未操作用户正在运行的 Rule Set bundle。

### 如实保留的边界

- 当前资源 probe 是最终源码下的针对性行为与30样本成本证据；没有同设备、同图片、同版本的旧同步实现前后对照，故不报告端到端提速百分比或冷/热 p50/p95 优势。
- Adaptive 的资源替换有加载/就绪和公开 owner 写入读回，但其 scene diagnostic 标为 `no_deterministic_scene_pixel`；不能把它说成资源像素逐值验收。Notification 的 focused readback 只覆盖该受控 native 诊断点。
- 系统输入法只验 CJGUI 的文本上下文、选区、组合提交/取消、焦点与外部修改协调边界；未进行物理中文 IME 路径、VoiceOver、真实呈现、多显示器、安装/公证/发布验收。CJGUI 不自研输入法引擎、词库、识别、候选生成/排序或输入法语言模型。

## 指导复核与本阶段接续

2026-09-13：执行任务已结束；指导读取源码、资源probe及已有scale原始日志，未代执行运行构建/测试。接受异步准备、session代际检查、LRU实现及所列单图/A-B/两窗口消费证据；本阶段仍需完成多资源调度正确性和加载中响应验收，不新开另一小阶段。

1. **缓存淘汰与活动纹理复用风险（待复现）**：`CjguiPruneComposableImageTextureCache(..., NO)`淘汰cache时将record设unrequested，但已显示节点仍持有texture；`resourceCompletionChanged`会令图片setter重跑，`CjguiComposableImageTexture`仅从cache取texture且会重新prepare。因此多于8个小图片，或活动图片超过32MiB缓存预算时，可能出现“完成→全图setter→淘汰图重新加载→再次完成”的循环。用12个不同key小图、6个约6MiB纹理两组正常场景，所有图首次加载后停止业务修改，断言持续pump期间decode/launch/completion/scene提交均收敛，普通resize/无关文字输入不重读同版本活动纹理。按真实资源key复用活动纹理并区别cache状态与已绑定ready状态；需要有界dirty-key完成集合时沿现有调度实现，不能靠放大cache或禁止普通场景掩盖。
2. **临时饱和与永久失败混用（待复现）**：4个加载槽+16个pending满时，prepare将正常资源记录成failed，普通setter不会重试。以24个合法小图受控延迟加载验证第21个起的状态；容量限制可以保留，但临时未调度必须明确区分文件/解码失败。让仍被当前场景需要的请求在槽释放后公平接续，或向应用提供明确可操作的繁忙状态及实际正常消费策略；不能无界排队、固定timer轮询或默默永久占位。新版本超越/取消的旧pending尽可能不占住当前资源，关闭后不接纳晚完成。
3. **完成语义与实际成本**：原30样本的`window.pump`返回只证明事件处理/提交，异步资源可能未ready，不能当图片完整完成时间。补同一最终产物至少30次冷/热资源任务的请求到ready、ready到对应scene接受，以及加载期间输入/外部owner操作延迟p50/p95，原始日志可定位，idle/峰值同时记录。旧同步前后对照目前缺失可保留为“未测”，本轮不为重造旧版本停工，也不宣称加速倍数；这不免除最终响应与完成成本。
4. 两个正常Host和独立公开消费者实际消费上述多图/繁忙/恢复流程；修复通用framework/native，不让应用自行遍历内部队列。保留旧COW、接受事务、输入保护、像素/版本对应和关闭清理回归。只复跑本轮受影响检查及最终产物。修正旧integration guard时说明过时断言与真实替代，不恢复no-FFI禁令。

### 复核闭环（2026-09-13）

- 缓存风险已先红后绿：旧实现的12活动大图会持续重启加载（`decode=353`）；修复后小图12项和大图6项分别在16个空闲普通 turn 内保持 launch/decode/completion/提交不变。修复不提高预算，而是区分缓存引用、声明 key 和节点已经绑定的实际纹理 key。
- 饱和风险已先红后绿：旧实现的第21项起将合法资源记为 `failed`；现在闸门下明确得到20 loading与4 busy，解除后当前场景按稳定顺序补入原有有界 pending 队列并全部 ready。`busy` 不被伪装成 `failed`，也没有无限队列或固定轮询。
- 成本语义已补齐：`pump` 返回不作为图像完成，原始日志分别记录30次 cold/hot request-to-ready、ready-to-scene 接受和30次 loading input；公共 Adaptive consumer 的30次 owner 写入另行记录。缺少历史同步实现的同设备前后对照仍如实标为未测，不宣称加速倍数。
- 两个隔离 normal Host、公开 descriptor client、资源替换、输入/队列/失败/关闭回归均已在最终源码上复验。Rule Set 用户实例未被操作；不 stage、commit、push 或发布。

本阶段整体能力不更换：可靠资源调度、缓存和人/外部操作响应已完成本阶段交付；下一大阶段须由指导/用户另行指定。两次实际失败按AGENTS升级，框架输入法工作只限系统集成。原目录、Terra/xhigh、不stage/commit/push、不干扰用户实例。


### 指导最终复核

指导读取原始stdout确认30条loading input、cold/hot各30条ready与scene样本、两组缓存收敛和24 ready排空；源码按imageTextureContentKey复用绑定纹理、busy补原pending。接受这些资源能力范围，未代执行重跑测试。Notification正式src/run.sh仍为旧循环和1.1.0路径，因此其“normal Host”标签待核实上轮实际临时入口，普通窗口行为不因此删除。该入口统一与证据校正由[下一阶段](2026-09-13-framework-consumption-preview-milestone.md)承接；资源阶段不再无界加压力案例。
