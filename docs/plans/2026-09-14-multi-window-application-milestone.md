# 大阶段：同进程多窗口、共享内容与独立生命周期

## 最新指导接续：完整多窗口共同操作与繁忙调度

上一轮已完成应用身份、基本重入和精确窗口 projection；指导接受这些限定结果。现在直接继续同一完整阶段，不等用户或 heartbeat。以下是仍需交付的能力，不另开执行卡：

- **把指定窗口的共同操作接完整。** 当前新增 target catalog/context，但多窗口消费者撤下无 target 的 progress/interaction，并未交付原目标中的定向进度与必要交互读取。复用既有 progress/interaction owner、授权与结果，扩展为明确 target 的公共入口，响应绑定应用/窗口代际。保留单窗口兼容；关闭 A 后，A 的上下文、进度和交互读均不得切到 B；B 可独立读取。交互状态继续采用原窗口真实焦点/选区，不复制可写状态，不扩大读取权限。程序化受控输入与人工输入分开标记。
- **证明并修复繁忙时的可用性。** 原 1/2/4 窗口单项工作和等待轮转只保留为基线。通过真实连接制造持续但有界的外部积压，在同一调度中让 B 处理独立输入/更新，记录逐轮外部服务数、B 到相关 scene 的进展和等待预算；测出饥饿、超额 drain 或额外等待再改实际调度。补关闭/重开及部分创建失败后的 session、连接和实际资源收敛证据，避免只拿对象数替代资源。无需重跑无关文字/列表矩阵。
- **一起处理生命周期恢复边界。** Terra 检查当前 pumpOneTurn 的 guard 在可传播回调异常时是否恢复，若异常可到达则以真实回调反例验证并保证清理；不要吞掉错误伪装成功。检查多个 application 实例与全局 stopApplicationLoop 的所有权：当前身份探针中的 sibling 存活不自动证明正常主循环仍可服务。明确支持边界并验证正常入口；若公共设计仅允许一个活动 loop owner，应在入口明确拒绝冲突，而不是建窗成功后停掉其他实例。仅按实际反例改动，不扩张为新的进程管理产品。
- **最终源码一次导出消费。** 当前 ACTIVE 所列 26c0c45c 导出属于上一版，不能证明新 identity/target 实现的最终消费。以上生产改动稳定后，完成相关测试与正常 bundle 的公共 target/CAS/关闭链，并从最新导出副本的含空格路径构建消费，保存本次 source/payload/binary 指纹和原始日志。历史导出记录保留但明确标旧。可操作前台时接续已有 GUI 欠项；锁屏直接保留 not_run，继续其他独立工作。

Terra/xhigh 负责公共契约、调度和生命周期判断；给已有 Luna/high 一个完整的定向读取/客户端/消费验证工作包及明确写集，避免双方重做全套测试。Terra 整合后连续完成上述交付，只有重大设计阻塞及时升级；阶段完成主动发送原始报告给指导任务，由指导立即安排下一轮。复用现有自绘窗口、共享领域 owner、语义读取与调度资产，不另造运行时。仍按 AGENTS 的失败升级、原目录和不提交发布边界执行。

## 指导复核后的当前接续

初版已具多窗口建窗/同owner投影、单等待、定向关闭及导出证据，指导抽查 `macos_application_host.cj` 和原始probe/fairness日志，接受其限定结论；以下三项曾是同阶段必须补足的边界，现已实现并按“复核收口证据”独立验证。它们不等于前台人工链路完成：

1. **应用归属与窗口身份。** 当前每个application的nextGeneration都从1开始，identifier只有相同value/generation，entryFor未校验所属application。用两个application对象（总窗口不超过native容量）的首窗交叉identifier请求，或相继创建application时复用旧identifier，证明不能命中新对象。公共标识绑定真实application实例归属与窗口代际；若设计只允许一个application owner，须在入口明确拒绝第二个且不影响第一个，不能靠注释约束调用者。代际耗尽不得饱和后复用同一有效id；正常拒绝即可，不需要复杂长期存储。
2. **事件重入与生命周期。** pumpOneTurn直接遍历windows，期间controller可能调用open/requestClose/close或递归pump；现无稳定快照/代际复核及重入策略。用真实controller事件触发关闭兄弟窗口、创建新窗、请求应用退出和一次嵌套pump，检查本轮处理集合、已关闭实例不再pump、下轮新实例可用、只等待一次。采用应用拥有的快照或明确延迟变更，执行每个entry前验证仍live，拒绝/延后嵌套pump，不能再起主循环。应用层正常退出需有可消费的关闭决策入口；现close直接强制清理可保留用于已决定退出/启动失败，但不能作为未决业务关闭的唯一入口。覆盖一窗拒绝时应用继续可用，避免先销毁兄弟再发现拒绝造成含糊结果。
3. **外部窗口上下文。** 当前windowProjection/windowProgress只取first-live，关闭首窗后自动换目标；同一endpoint的调用者无法发现并选择其他窗口。这未满足明确window上下文的原目标。提供兼容的可发现窗口标识与定向projection/progress/必要交互读取，窗口关闭或标识错误明确返回失效，不静默切到另一窗。旧未指定window的单窗口消费可保留默认，但响应需明确所选窗口身份，不能让旧等待认成另一窗成功。继续一次执行领域动作、原owner/CAS/授权；发现列表和投影读取受既有read权限，不把纯UI窗口默认全部暴露。正常外部client实际读取A/B不同局部上下文、关闭A后旧目标拒绝且B可读，不能只测同份正文版本。
4. **最终证据边界。** 当前30/15/8等数字是被选中等待窗口的轮转次数，不单独证明繁忙负载公平与资源收敛。复用已有1/2/4固定工作量日志，只补上述重入/目标读取、繁忙外部队列不饿死另一窗、部分失败和关闭后有界资源的缺失证据；无需先重跑所有旧矩阵。生产变更稳定后一次完成相关回归/构建及导出真实公共消费，原始日志/指纹保存。前台人工GUI、IME及物理呈现继续not_run，不将协议/probe冒充它们。

Terra负责应用/窗口/连接归属与重入、关闭语义；Luna承接明确的定向读取/消费者/回归包，公共契约先交代再并行写集。必要旧问题和同阶段新能力一起完成，根因/契约有疑问及时升级，不能修一个方法就停。保持单调度器、自绘、仓颉和原目录授权边界。

2026-09-14，指导已授权实施。原任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`，Terra/xhigh负责，复用Luna/high；原目录，不另建任务/worktree。

## 要交付的使用能力

开发者通过公共仓颉接口在同一应用进程打开、关闭、重新打开多个自绘窗口。两个窗口可查看同一份领域内容，也可绑定不同文档；人在A修改、B能读到并显示同一owner结果，外部授权修改同样反映到相关窗口，人的窗口焦点/选区/滚动保持各自定义的上下文。关闭A不关闭B，关闭被业务拒绝不损坏会话，最后退出完整清理连接与资源。实现通用应用宿主能力，不做IDE、窗口管理产品、聊天或跨进程协作服务器。

六主线取舍：组件/可变高度集合、文字/GPU、语义与普通包已有源码和受控证据；真实GUI/系统输入条件仍有限。当前优先资源调度、应用生命周期与开发者接入的单窗口限制，延续高性能自绘和同一真实owner方向，不继续无止境优化单条文本或列表边角。

## 复用及旧欠项

- 读[设计导航](DESIGN_INTENT_INDEX.md)相关生命周期/状态归属/事件重入教训，复用 [macos_application_host.cj](../../runtime/cjgui/src/macos_application_host.cj)、[窗口及调度器](../../runtime/cjgui/src/composable_ui_window.cj)、现有native session generation和GPU完成资源保留、launcher主线程桥接、公开connection与文档owner。
- 当前host每实例只有一个window，`close()`无条件停止应用loop，单窗口scheduler每次finishTurn都可能等待完整预算。直接循环多个现有host既有退出耦合也有串行等待风险；从应用级统一生命周期和一次等待预算解决，不能每窗复制一个AppKit主循环/线程/scheduler。
- 旧[单窗口宿主阶段](2026-09-13-normal-app-host-package-consumption-milestone.md)的“不扩多窗口”是当时范围，本阶段明确扩展；仓颉核心、macOS首平台、窄native、自绘路线不变。保留单窗口API既有行为或提供兼容委托，不把旧消费者全部改写才能运行。
- [变量集合阶段](2026-09-14-variable-height-collections-milestone.md)源码、针对性回归、规模及公共摘要包装按已证范围接受。执行报告最终preview payload为`b1f6302b2d4ffebd92d1c595ad740c1bdbd30be8dce9783caa5ae13094305645`；指导抽查了公共wrapper/native和样例调用，仍需执行补明原始成功日志位置供最终归档。其最后GUI滚动显露/点击与[低延迟阶段](2026-09-13-low-latency-text-resource-milestone.md)的CJK/emoji GUI→CAS→GUI接续仍未验，不能标整体完成。本阶段前台可用时在最终有效bundle一并覆盖相关旧场景；锁屏仅挂起前台项。

## 完整范围

1. **公共应用/窗口责任。** Terra确定应用拥有窗口集合、运行/退出与可选连接的边界；窗口拥有自身投影、身份和关闭状态，领域内容只有原owner。提供实验性创建/查询/定向关闭的纯仓颉入口，稳定应用内window标识含可辨别代际，不泄露native token。配置/建窗部分失败要明确回滚本次资源并保留存活窗口；单窗口兼容正常构建和退出。共享连接的生命周期归应用或明确owner，不被某个窗口误关闭。
2. **单调度器与公平性。** 复用现有turn scheduler，应用一轮分配有界窗口/外部动作工作及一次等待；繁忙A不能饿死B，空闲窗不持续重排/提交，不随窗口数串行增加固定等待。新窗/关闭发生在回调中用可解释的快照或延迟变更，不能遍历失效对象或递归pump。窗口停止后拒绝其排队输入/旧AX/晚到GPU完成，代际拒绝不影响其他窗口。GPU资源保留与预算按实际共享/独占范围统计，不用改预算名称隐藏总量增长。
3. **共享内容与上下文。** 复用一个真实文档/领域owner和CAS，不为每窗复制可写正文。先明确领域选择与窗口局部选区/焦点/视口的区分，不能为了“独立窗口”悄悄改变业务选择语义。A编辑同对象后B相关投影更新；不相关窗口不无故重建。同owner外部修改只执行一次，再定向失效相关窗口；共享刷新请求不能由第一个窗口consume掉导致其他窗口漏更新。公开调用能明确目标owner以及必要的窗口上下文，权限仍属于已有授权，不从窗口是否可见推导权限。
4. **关闭/退出与失败。** 覆盖A请求关闭被拒绝、随后允许关闭、B继续编辑、重开A不继承旧输入、最后关闭正常退出及descriptor/socket清理。应用退出有清楚的关闭决策与顺序，已有有效授权不重复索权；拒绝后的存活状态可继续操作。资源加载/提交失败只影响对应窗口，不能关闭无关owner/connection。任何创建窗口计数与主循环停止路径都要在部分启动失败中平衡，不能只用简单global计数掩盖所有权。
5. **普通开发者消费和完整证据。** 扩展一个现有示例，以公共API实际打开两个窗口，至少一次同owner不同视图和一次不同对象绑定；单窗口现有消费者继续兼容。最终从正式导出副本在含空格路径构建多窗口消费者，不允许应用自写native launcher/foreign或私有符号接线。无前台依赖的测试先验证应用生命周期、失败隔离、定向共享刷新、已关闭代际拒绝；正常macOS进程的实际事件/资源/endpoint也要验证，不能只有纯对象计数。1/2/4窗口相同总工作负载下记录公平性、每轮等待、输入/外部工作到相关scene的耗时分布、无关窗口build/submit以及关闭后资源收敛；每主要条件30有效样本，固定binary无verbose。一次GPU完成不称屏幕呈现，锁屏无drawable与逻辑通过分别标注。

## 分工与边界

Terra亲自负责应用/窗口/连接所有权、退出/重入、调度和FFI/GPU衔接；Luna承接明确完整的兼容回归/消费者/确定方案实现包，默认一名、写集互斥。先给必要接口，再让消费者接入，避免下面长期等待未定契约。遇反复失败按AGENTS跨阶段累计及K3规则升级；环境不可用不重复撞。

若需要调整受影响公共契约先在本页简述兼容与状态归属，再自主实施；公共、native与跨模块影响按工具实际覆盖及源码核对，不把旧索引当阻塞。修改测试按风险完成，无新疑点不重跑无关文字/列表矩阵。实现不顺时先证明真实失败再改，不能为保持活跃制造工作。

完整交付包括通用API、正常多窗口/单窗口兼容、共享内容和关闭恢复、公平性/资源证据与最终包；不能只交建两个窗口的probe就停止。GUI可用时实际验证A→B→外部CAS→A/B→关闭一窗→另一窗继续，并承接旧列表/中文输入；锁屏保留明确not_run，继续独立代码及受控工作，不反复解锁、不操作凭据/系统锁屏设置。当前全部代码可交付而只剩外部条件时带原始入口/欠项报告指导安排后续，不伪绿。只读指导不直接开发，执行整阶段完成或重大阻塞主动报告 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。

不stage/commit/push、安装发布、不覆盖并行修改或用户实例；临时bundle隔离且保留原始验收证据。

## 2026-09-14 执行结果与证据边界

### 复核收口证据（已完成，人工前台链路除外）

- **应用绑定 identity 与共享主循环。** `CjguiMacosApplicationWindowIdentifier` 同时携带 application owner、opaque value 和 generation。process nonce 加锁 application generation 为每个 application 分配 owner；window generation 饱和后置为耗尽而非复用，并在 native start 前失败关闭。`entryFor`、retire 与 target read 都校验 owner/value/generation。成功创建 native projection 的 application 才获取 process-loop reference；最后一个释放者才调用全局 AppKit stop。`--multi-window-identity` 的实际 AppKit 进程输出 `cross_application_rejected=true stale_rebuild_rejected=true sibling_application_turn_survived=true reclaimed=true`，即关闭 A 后 B 仍实际处理输入。
- **重入和业务退出。** 应用 turn 对 window identifiers 取快照，并在 refresh/pump 前重新获取 live entry；重入 `pumpOneTurn` 不再执行第二次 drain/wait。回调中的 sibling close 被延迟至外层 turn，回调中的建窗得到 `application_turn_active` 明确失败，正常 application exit 必须先由 `CjguiMacosApplicationExitDecisionProvider` 允许；拒绝不关闭任何窗口或 connection。`--multi-window-reentrancy` 的实际 AppKit 进程输出 `callback_close_deferred=true nested_wait_suppressed=true exit_rejected_preserved_a=true open_rejected_during_turn=true reclaimed=true`。
- **精确外部 projection/progress/interaction。** core 新增 target catalog/progress provider 与公开 client 的 `window-targets`、`window-context <target>`、`window-progress <target>`、`window-interaction <target>` 和 `wait-window --target`。multi-window consumer 不再发布无 target 的 progress/interaction，避免关闭首窗后静默切换。真实 bundle 先读 primary/review 两个不同 `WINDOW_NODE` root，执行一次原 owner CAS `v0→v1`，关闭 A 后旧 A 的 context/progress/interaction 一律 `unknown_window_target`，B 保持精确可读；重开 target 是 generation 4。
- **异常、部分创建和繁忙积压。** `pumpOneTurn` 在回调异常时释放 guard 并继续传播错误；`--multi-window-exception-guard` 先得到传播异常，再证明 B 的下一轮真实输入被服务。`--multi-window-partial-creation` 让 native capacity 造成 B 首次 `native_start_failed`，确认 B 无残留 owner/reference、A 保留4个 session，释放容量后 B 可创建并最终回收。四个真实 public UDS caller 持续发起有界读取，再由同一连接提交 CAS；逐轮记录外部服务数、B scene 与 wait budget。此次 transport `ready_high_water=4`、`serviced_actions=133`，235轮中37轮服务外部动作，B 从 scene 1 到2；一轮 CAS 因已耗18ms而给出0ms wait budget，故结果仅说明该真实有界负载下没有测到 B 饥饿，不把它说成每轮正等待或更改后的策略上限。
- 当前验证：root `cjpm test` 9/9、core `cjpm test` 45/45、public Python client 25/25、root `cjpm build --skip-script`、host runner、consumer entrypoint/scaffolding 和 `git diff --check` 均通过；AppKit `--multi-window`、`--multi-window-reentrancy`、`--multi-window-identity`、`--multi-window-exception-guard`、`--multi-window-partial-creation` 和 `--multi-window-fairness` 逐段通过（公平性仍为1/2/4窗口各30有效样本）。`verify_multi_window_application.sh` 本轮完整通过，输出包含 `application_probe=passed`、`exception_guard=passed`、`identity_binding=passed`、`partial_creation=passed`、`busy_backlog_b_progressed=true`、`closed_target_rejected=true`、`sibling_target_survived=true` 与 `endpoint_cleared=true`；原始根为 `/private/tmp/cjgui-multi-window-application.boxfKa`。

本段仍不是手工前台验收：人工 A→B 可见、中文 IME、滚动/选区和物理呈现继续为`not_run`；未安装、公证或发布。

以下为初版阶段的实现和历史基线；其中旧 identifier/connection 记录不能替代以上复核收口证据：

- `CjguiMacosApplication` 是公共的应用级集合/连接/退出 owner；`CjguiMacosApplicationWindowIdentifier` 只含值与代际，不含 native token。创建失败在加入集合前回滚本次 window，定向 close 先走控制器决策，旧代际不能关闭重开后的 window；最后一个 window 才关闭 connection 并停止 AppKit loop。旧 `CjguiMacosApplicationHost` 保持未改的单窗口消费入口。
- native renderer 的 session 容量为4，继续使用既有 session generation 防止关闭后的 Metal/异步工作命中后来 session。应用一轮只给一个轮转窗口非零 event wait；其余窗口只进行零等待 drain 与版本检查。connection 的刷新信号由应用单次消费，但不粗暴调用所有窗口的 `requestRefresh()`：每个 controller 的声明 scene version 决定是否更新，因此相关共享 view 不漏更新、不同 owner 不无故 build/submit。
- `shared_document_window_app --multi-window` 是普通公共消费者：两个不同 controller/view 固定绑定说明文档，一个绑定笔记文档；显示名与 ASCII semantic id 分离，避免公共 descriptor/snapshot token 因中文显示文字失效。connection 的 window projection provider 是 application 而非 A，因此 A 关闭后不会遗留 A session 所有权。消费者不声明 `foreign`、不接私有 launcher 或 test session seam。

以下初版日志保留为历史基线；最终受控验收入口仍为 `runtime/cjgui/native/scripts/verify_multi_window_application.sh`，本轮完成根为 `/private/tmp/cjgui-multi-window-application.boxfKa`，不得再用旧 `/private/tmp/cjgui-multi-window-application.YZnh7o` 覆盖新的 target、异常、共享 loop 或繁忙积压结论：

- `application-probe.log`：正常 AppKit process 创建4个 native session；受控 AppKit human input 进入共享文档 owner，外部 CAS 到达相关投影；A 首次 close 被拒绝、后续接受、重开取得新代际，最终 session=0。
- `fairness.log`：固定 binary、相同单项工作、1/2/4窗口各30个有效样本。`turn_ms` 分布分别为 1窗 min/p50/p95/max=`0/9/10/17ms`、2窗=`8/9/10/10ms`、4窗=`8/9/10/10ms`（`0ms` 只表示毫秒时钟下限）。唯一等待轮转为 `30`、`15/15`、`8/8/7/7`；共享的相关窗口每次 build/submit各+1，无关窗口为0，并在每条件结束后回收0 session。
- `connection.log`：正式 bundle 通过公开 client 的 `REPLACE_RANGE` 将说明文档 `v0→v1`；两个说明视图为 `SCENE 2 BUILD 2 SUBMIT 2`，笔记窗保持 `SCENE 1 BUILD 1 SUBMIT 1`，transport serviced_actions=2（一次 context read、一次 CAS），process 退出后 descriptor 不存在。`connection-start-failure.log` 证明无效 connection start 不会销毁3个已建窗口，随后显式 application close 才清理。
- 最终导出副本已从本轮源码重跑：`/private/tmp/cjgui-framework-preview-consumption.pmbLyk` 的 source/preview payload 同为 `a34c49a1874a83d997f89b77a99a62b9274716dc741a89cc38fc22c82f04de97`。导出树迁移到含空格路径后，UI-only、collaboration 和复制的 `shared_document_window_app` 都从 exported framework/core/native 构建；三者 bundle SHA-256 分别为 `f4d23c1cadc9c31f509e0499ff1f3f2e0229c8282b217e817a98b9e37cd70c28`、`a14ff06814d018aeaaed0f9c187418368d31748ef4082529749a1121c2c32810`、`e1dafb594c476f81e03fa90a4aa981ee053057726d5bedaf6e8edbe1d89a76fd`。这是导出消费/包证据，不是该消费者的人工多窗 GUI 运行。

这些是源码、测试/受控 AppKit、正常 bundle、socket 和资源清理证据；一次 native submit 或窗口创建不等于人已看见内容。本阶段的前台人工链路仍为 `not_run`：在当前最终 bundle 中手动完成 A 编辑→B可见、外部 CAS→A/B可见、关闭A后B继续编辑、重开A不接受旧输入，并同时复查中文 IME、滚动/选区和物理呈现。未安装、公证、发布；不以旧运行实例或受控 AppKit helper 替代这些项。
