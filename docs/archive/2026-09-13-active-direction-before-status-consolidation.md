> 历史快照：原 runtime/cjgui/ACTIVE_DIRECTION.md 于 2026-09-13 整理前内容。下文过程指令和“当前”标签均已失效，仅供追溯；链接已按归档位置调整。

# CJGUI 当前方向与实施状态

更新：2026-09-13。本文件是唯一当前状态入口；阶段报告保留详细历史证据。

## 当前任务：自适应组合布局与测量复用

指导接续（优先于下方历史记述）：接受上一文字阶段的已验交付，保留多段100KB尾部约71ms、超长单段约77–79ms及物理IME/VoiceOver未验边界，不宣称任意位置高性能。下一阶段按[自适应组合布局与测量复用](../plans/2026-09-13-adaptive-layout-reuse-milestone.md)实施：修正跨轴尺寸与饱和约束分配，复用现有组件/测量器/宿主，交付动态布局、测量复用、两个正常消费者与实际成本。此项比继续孤立优化极长单段更能拓展框架通用可用性；下一候选为渲染资源与局部提交效率。下方文字阶段与更早报告保留为历史证据，不能覆盖本段当前指派。

## 上一阶段：增量文字布局与视口效率

指导最新接续：增量文字布局与视口效率阶段已交付。活跃文字图已将内容/可见 glyph、几何、目标 range、精确高度与滚动锚点拆开；绘制、命中、选择、候选与滚动使用唯一 TextKit graph 的 range 布局。超长单段的 range 请求仍可能被 TextKit 隐式扩张；若多段同一热位置也持续线性，才在现有接口正确性条件下评估受控段落索引。不能重新引入直接 proxy storage 或第二 layout graph，也不能预先锁死分段方案。具体证据与后续取舍见阶段末尾。

当前进展：本阶段已完成本地 owner acknowledgement、inactive TextKit cache 的稳定 identity/样式 key、缓存高水位观测和外部替换覆盖未 pump 本地 proxy 的修复；测试探针也不再由关闭窗口吞掉失败返回。最新生产修复使 `positionInputProxyForNode` 只写入真实改变的 nine native geometry/font 属性；此前相同值重写会把 TextKit 已实现前沿从 90,113 重置到 0，并让普通视口滚动触发约 1.5s 的 bounding-range 工作。细分 trace 现分别记录 range ensure、glyph/line/location、候选、锚点、proxy 变更及 `firstUnlaidCharacterIndex`；同一 100KB 多段尾部插入的约 71ms 全部落在一次 character-range ensure，随后候选与普通视口滚动为 0µs 且不再重置前沿。三新进程、每位置 5 对预热后 30 对插删（n=90）的主证据是：多段 start/middle insert input p50 2/6ms、tail insert 71ms（p95 73ms），tail delete 0ms；单段三个 insert 位置仍为 77–79ms。旧 9 点首/中/尾序列另存为历史对比，不能称为“中间热点 p50”。独立 `NSTextView` 对照已按相同宽度/换行与插入后 caret 几何运行，但其预热生命周期不同，明确不可与 CJGUI 指标相加或相减。当前源码的 `--cost`、两类冷首编辑、trace 和稳态 probe、core 40/40、runtime 5/5、场景/窗口/宿主回归与 CJGUI 项目根 build 均通过；两 normal bundle 已从最终 native archive 重建并通过公开实际 owner 写入、冲突、读回与完成帧。已解锁桌面上共享文档和截图中的共享操作应用均出现正常实窗及 accessibility 节点；物理 IME/VoiceOver/人眼 GUI 不继承为绿色。完整边界、成本和记录位置见[任务说明](../plans/2026-09-13-incremental-text-layout-milestone.md#交付区)。

指导最新复核：程序化组合与AX已有针对性证据，继续本阶段完成旧本地输入与外部修改交错、字符边界校准、两应用真实owner撤销接续、长文档稳定成本及独立消费。5秒外部读取不替代本地编辑/滚动测量；物理IME保持环境未验。

**接续基线（本阶段开始前，2026-09-13）：** 通用 native overlay 已把 marked text 与 committed value 分开：外部同对象投影、焦点切换、Escape、只读/禁用/删除/重绑都会取消组合而不产生迟到领域写入；新组合提交只进入一次既有 text-change/undo 路径。共享文档 workspace 的 committed 投影只生成保守 UTF-8 边界下的最小替换；它不宣称完整 UAX #29 segmentation。此前 10,250/102,400 字节含 Unicode 的 TextKit→document-owner 诊断中 owner delta 仅 0–2 ms，但 102,400 字节 input turn 为首89–90/中95/尾151–152 ms，故本阶段开始优化真正的文字布局/视口热路径。物理中文 IME、候选窗人眼、真实键盘跨行选择、VoiceOver 全程与多显示器 DPI 在当时仍未验，不能由程序化探针替代。

指导最新复核的内容指纹失效、bundle 资源收敛、标题保持、实际 Host 生命周期和稳定
运行对照已经完成；早期两秒 smoke 只保留为历史证据，不再作为本阶段结论。可追溯的
命令、边界和报告摘要在[当前大阶段](../plans/2026-09-13-normal-app-host-package-consumption-milestone.md#复核收口结果2026-09-13)。

**前阶段状态：完成其已列实现与验收范围。框架拥有 `CjguiMacosApplicationHost`、单一既有 TurnScheduler 和 AppKit 主线程 launcher；普通应用只声明仓颉 controller、标题/尺寸、bundle 配置和可选 external connection。runner 用内容/工具链 fingerprint、同 app 锁和原子 bundle staging 管理仅应用本地的产物；规则集、共享文档和独立消费者均已从最终源码重建。真实 bundle 的首帧/Metal readback、有限生命周期关闭、外部读写/CAS、跨 cwd bundle 资源路径、标题不被 scene commit 覆写和 LaunchServices 参数传播均已复验。最终 root 5/5、core 37/37、Python client 18/18、root `cjpm build --skip-script`、native host static probe 和 `git diff --check` 通过；三组 60 秒 idle 和一组 60 秒混合报告另有文件 hash。生产 Host 覆盖 connection 启动失败清理及拒绝/批准 close 语义，但物理输入/IME、人眼呈现、标题栏关闭按钮/取消关闭、安装、公证、发布和稳定 ABI 仍未验收。**
执行任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`，gpt-5.6-terra / xhigh，原目录。
以[当前大阶段](../plans/2026-09-13-incremental-text-layout-milestone.md)为依据；[前阶段宿主交付](../plans/2026-09-13-normal-app-host-package-consumption-milestone.md)保留证据；[前阶段观察交付](../plans/2026-09-13-efficient-observation-targeted-read-milestone.md)保留已验与未验范围；[前阶段性能与调度报告](../plans/2026-09-12-fair-scheduling-performance-baseline-milestone.md)保留原始证据与未验边界。

指导复核接受前阶段身份绑定/交互授权及37/37、18/18的针对性报告；本阶段已经提取框架拥有的通用 macOS 宿主与构建入口，迁移规则集/文档并让独立开发者只按公开 API 创建正常应用。下一候选仍为实际文本输入/无障碍完整性；前述通过状态与本阶段 normal-host 证据分别记录，不把它们外推为发布或跨平台完成。

## 2026-09-13 收尾验收（优先于本页早期接续记述）

- `CjguiSharedOperationContextSnapshot.streamIdentity` 是可选的 owner 同锁快照字段。规则集和文档的 full/target 读取以及 `GET_CHANGES` 使用同一身份；观察器在新流、`RESYNC_REQUIRED` 或 target 补读身份不一致时清空并完整重同步。缺少该字段的旧 provider 明确降级为每轮完整 resync。
- `GET_WINDOW_PROGRESS` 已回到进度专用字段；`GET_WINDOW_INTERACTION` 是单独发现、单独授权的窄入口。`IDS` 作用域既不返回焦点、选区或 layer，也不以错误载荷泄露；`ALL` 作用域可读交互投影。
- 曾红的 root viewport 测试已两次确切复现为 `window.start()` 在 `cjpm test` 的 Cangjie worker 调用 AppKit，native status `1`（`CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD`），不是视口映射回归。该单测收回 owner 无关的 viewport 映射；两应用从正常 AppKit 主线程入口实际创建窗口、首帧/Metal readback 后退出 0。
- 当前验证：core 37/37、Python 18/18、规则 owner 15/15、root 4/4、root `cjpm build --skip-script`；两份重建 normal bundle 均由只读公开 README 与 client 的独立黑盒动态发现并验证 `get`、`wait-window`、`window-interaction` 与两轮 target observe。此前旧 bundle 的失败保留为二进制陈旧性证据，不与重建结果混同。
- 180 秒性能产物保留但未重跑：本收尾未改变 owner 的 full/target 构造或布局热路径。物理 IME、人眼像素、安装、发布和稳定公共 API 仍未验收。

## 不变的方向

CJGUI 是仓颉 GUI 框架，macOS 首个平台，保持自绘/GPU 与窄平台桥接。文字排版、输入法及系统窗口服务可使用平台能力；应用决定产品、组件组合和交流方式，外部系统可以是 Agent、模型、脚本或其他应用。不强制聊天窗、Agent runtime 或固定编码。

应用领域拥有内容/草稿/规则；组件拥有必要焦点、选区和视口等交互状态，画面与语义是这些状态的投影。人和外部调用进入真实业务操作，不另造可独立写入的语义或文档真相。

已有有效授权可覆盖屏外批量操作；可见性、模态弹窗和AI身份不自动增加权限门槛。真实缺参、冲突、业务约束和未授权目标仍须处理。层遮挡约束视觉输入，不等于禁用所有外部业务动作。

方向依据：[设计导航](../plans/DESIGN_INTENT_INDEX.md)、[项目方向](../core/GUI_PROJECT_DIRECTION.md)、[共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)。

## 已有资产与最新证据

指导复核为源码与报告审阅，没有重跑开发测试；下列运行结果来自执行任务，未证明稳定API或发布。

| 能力 | 当前事实与边界 |
| --- | --- |
| [组件/布局](../../runtime/cjgui/src/composable_ui.cj)、[通用窗口](../../runtime/cjgui/src/composable_ui_window.cj) | 仓颉构造组件树、测量/布局、稳定身份、输入快照、失效合并和窗口命令；业务与页面无需写进 native。 |
| [自绘/native](../../runtime/cjgui/native/cjgui_internal_renderer.m) | Metal 绘制矩形/图片，AppKit/TextKit 为自绘文字提供排版/绘制与输入代理；资源和排版缓存有界。每次已提交 command buffer 的异步完成回调仅回写会话代际匹配的标量：成功/失败帧与可得的 GPU 微秒数；它不写领域或仓颉UI。`submitted`、GPU completed、overlay draw 与 `presentation=unavailable`仍是四个不同事实。 |
| 通用输入与文档 | 鼠标跨行选择、键盘焦点/动作、只读选择、文档批次/撤销/保存与人机接续有前置实窗证据；物理中文IME仍未验。 |
| 刷新恢复与客户端 | 最后成功/最后尝试条件已分离，失败v2和AppKit resize的重复尝试有回归；进程nonce+单调代际区分会话，等待的总deadline和错误分类已补测试。公开Python API/CLI可动态发现、操作、读回和有界等待；观察器用一次 monotonic deadline 贯穿 changes、所有定向补读和 resync，失败清空投影，多目标只整体发布。 |
| 虚拟集合 | 固定行高范围构造、稳定 key 导航与 `WINDOW_COLLECTION` 已有实现。动态数据变更按 key+行内偏移恢复，空/重复/超高行保留固定格或明确失效；2,000项布局探针首屏7行、跳转首尾有界，物化行上限128、native节点上限1,024。 |
| 通用层 | 仓颉层宿主统一布局、绘制顺序、裁剪、命中和输入范围；规则集消费菜单、草稿对话框和其局部子菜单，文档消费同一宿主菜单。顶层非模态锚定层首次出现时现会接管其声明的输入范围；原生控制器探针以普通鼠标路径覆盖顶层菜单 Tab/Escape/焦点恢复，不再只靠手工聚焦子菜单。 |
| 公平传输与生命周期 | socket accept 与四个固定 I/O worker 只搬运有界字节（接入队列8、就绪请求8、就绪字节16 MiB）；读总时限160 ms、完整请求等待 owner 最多256 ms、写总时限512 ms、每次实际 I/O 最多8 ms。`waiting → claimed → cancelled` 在同一锁下原子转换，领域/授权/版本仍只在 owner `pump` 执行；过期 tombstone 只排队待 drain，不能迟到写入。`waitForWorkersToExit`现在返回有界观察结果，`false`不代表无限 join 或新旧 worker 不重叠；正确性来自每次 start 的独立 I/O state，迟到旧 loop 无法服务新 endpoint。 |
| 最新针对性验证 | 本轮 core `cjpm test --timeout-each 30s` 36/36、Python client 14/14、规则 owner 15/15、性能辅助单测5/5及实际 workload 单测1/1 均通过；两个窗口消费者重新构建，root `cjpm build --skip-script` 通过。另一次 root `cjpm test` 的旧 `sharedOperationWindowProjectsMoreThanEightStableRecordsThroughOneViewport` 在 `window.start()` 处失败（3/4）；它不覆盖本轮 composable progress/observer 变更，未被隐藏为绿色。native window controller probe 的既有范围仍保留。 |
| 正常窗口成本 | [window_perf_baseline.py](../../runtime/cjgui/examples/window_perf_baseline.py) 等待正常 bundle 的 `WINDOW_READY`（首帧已提交），再经相同显式预热并由应用发出 `MEASUREMENT_START` 后采样。两轮60秒 idle 的六个周期均退出0且有60–61个有效样本：文档无连接 CPU 0.5–1.9%，文档/规则连接 idle 分别0.8–2.5%与0.8–2.5%。启动、预热、RSS和线程原始轮次均在 JSON 中；不同新进程的 RSS/线程基线不被宣称为收敛。 |
| 连续基线与恢复 | 原始 `/tmp/cjgui-transport-perf-600s.json` 保留：600 s 混合负载完成469,410个正常请求，p50/p95/max为1.222/12.249/16.641 ms；其中 `IO_WORKERS=5` 仅表示 retained future，`fd_count=13–14` 是 `lsof` 显示行数，二者不再用于活 worker/数字 FD 结论。新 V2 采样以 `RETAINED_WORKERS`、`ACTIVE_IO_WORKERS` 和 `lsof -Ff` 的数字字段分别报告。6 s 当前产物 smoke（2正常GET、2有限碎片 peer，100 ms预热后采样）取得4,328个成功请求、p50/p95/max 1.256/12.307/14.543 ms、active I/O loops=5、数字FD=9；另有无peer及连接但不发帧的空闲上下文。它们只证明当前 headless 进程路径，GPU、物理输入到呈现延迟与长期内存仍未测。 |
| 实际批次、混合与恢复 | 最终180秒 paced 正常窗口：规则集创建1,001项临时规则19.430s，100项批量启用到版本1002，旧版本冲突、定向读回和后续 Metal 完成帧均通过；文档替换、旧版本冲突、范围读回和后续完成帧也通过。规则完整快照以100ms显式节奏读取1,081次，p95 145.653ms，业务后 CPU 26.3–91.3%；同 fixture、无读取器的同进程恢复为0.9–30.6%、末值3.1%。profiler 将读取成本定位为 `snapshotPayload → contextSnapshot`、UTF-8 编码和当前 window projection 构造，不是循环重绘或每帧回读。文档 paced 读取1,479次、p95 24.643ms、CPU 1.0–3.9%。无限速读取的较早高压 JSON 也保留，不能同 paced 指标混合。 |
| 本阶段局部读取与观察 | `GET_CONTEXT` 无 target 保持完整兼容；显式 target 才调用 owner 的定向快照。规则/文档 owner 的针对性测试证明未先构造全量资源，两个正常窗口均启用该能力及标量-only `GET_WINDOW_PROGRESS`。`SharedOperationObserver` 以 changes + target reread 构成可丢弃且可消费的快照映射；断线、超时、协议/授权错误或 resync 失败均清空，变化 target 先建替代映射再整体发布。因为 snapshot wire 没有 `STREAM_ID`，initial/resynced 的公开 stream 是空，下一次 changes 才绑定；目标读到另一版本即丢弃并显式 resync。黑盒曾发现连字符 stream ID 被 Python 错拒、也发现 active progress 漏 `WINDOW_PROJECTION`，两者均先失败再修复。实际文档窗口以菜单和文本焦点/选区使 interaction 0→3→4、scene 1→2，而内容 `VERSION` 保持0；窄端点只输出 focus/layer/UTF-16 坐标，无正文。当前机 `/tmp/cjgui-rule-read-comparison-180s.json` 的同 bundle、同1,001项/100批量/100ms/180s 对照：完整、单目标、观察 p95 延迟 151.974/24.784/43.956 ms，p95 wire bytes 318,472/6,515/712；三组皆通过批量、CAS 冲突、读回、稀疏目标修改和完成帧，观察另有一次明确 resync。该性能产物早于本轮窄 progress 字段和 observer 语义补强；二者不改 owner 的全量/target 构造热路径，故未机械重跑180秒。观察器在 app 正常关端点尾端记录一次 `ConnectionRefusedError`（app exit 0），不把它藏作零错误。它报告 CPU/RSS/字节/延迟与 owner 行为证据，不是跨机、安装或呈现承诺。 |

## 本轮承接与验收边界

- 旧同步 `accept/read/dispatch/write` 已由慢分片红测复现：窗口 `pump` 曾耗约190 ms。现在 worker 读取完整帧后仅把请求交给 owner；相同慢分片下窗口 `pump` 少于80 ms，正常完整请求在另一个慢分片并存时80 ms 内完成。总测试时长仍包含故意等待的慢客户端，不能误作请求延迟。
- 有限规则集消费者曾在最终 `pump` 后立即关闭，导致已执行请求的响应被截断；独立消费者真实回归先失败，再由64 ms 已发布响应收尾及 core 生命周期回归修复。它不是吞掉错误或无限等待。
- 四个完整 `SET_MARKED` 请求占住 I/O worker、owner 暂停300 ms 的红测曾让首个请求在稍后 `pump` 中突变版本；现在请求创建时保存的256 ms绝对未领取截止与原子领取/取消使四个请求全部失效，正常 `GET_CONTEXT` 随后恢复且列表版本仍为0。过期 tombstone 的字节只在实际出队释放，故16 MiB限制、诊断和物理队列一致；该回归同时观测 retained handles=5、active loops=5、ready高水位至少4和非零物理占用。
- 仓颉 `UnixSocket.write` 只返回 `Unit`；受控1024字节接收缓冲的真实 peer 在发送定向大上下文后停700 ms，响应声明37,725字节、仅收到8,186字节，服务端正常退出并清理私有 endpoint。写timeout不再重试同一16 KiB offset；这是保守防重复策略，不声称已提交领域动作回滚。
- 公共第二消费者新增仅 owner 本地可读的诊断模式和 `transport_perf_baseline.py`。其600 s报告在`/tmp/cjgui-transport-perf-600s.json`，命令、指标和外推限制载于shared-operation README；它没有把队列诊断加进descriptor或领域快照。
- `CjguiComposableUiWindowTurnScheduler` 是无状态的普通应用转向器：外部连接至多16个完整 domain action，且只在两个 action 之间检查16 ms墙钟预算；余下时间交给 AppKit 的有界事件等待。规则集和文档（含无外部连接）均通过它循环，不再在`window.pump(16)`后额外`sleep(16)`；原生窗口探针验证空闲转向不新建 build/layout/submission 且实际等待落在8–80 ms。它不是物理输入或GPU呈现延迟测量。
- 当前千项窗口已完成实际 End 导航、菜单打开/Escape 关闭、外部模态期间业务写入与其后普通键入读回；桌面随后重新锁屏，最终 bundle 只完成构建，未在锁屏后再做 CUA 视觉复验。

- 桌面重新可操作后已重新复核两个实际窗口：文档的公开改动随后可由本地系统原生粘贴继续编辑；规则集的编辑对话框显示期间，公开批量改动可见，随后本地草稿仍可继续编辑，子菜单 Escape 只关闭子层。`typeText` 未产生可验证写入，故这些结果不声称物理键盘或中文 IME。


- 动态锚点、锚点删除、插入/重排/过滤、空/重复/超高行、部分行和 `overscan=0` 已由布局探针覆盖；列表不再用选中项掩盖丢锚点。
- 严格屏外批次在最新1,001项真实规则窗中记录物化范围0..7后选择200–299，读回成功；有效授权中夹带未授权目标的零写入由规则领域回归验证。领域全量 `GET_CONTEXT` 的串行拼接和大帧单写曾在实窗失败，现改为有界线性构造和分块回写并有1001项回归。
- 层宿主、锚定菜单、对话框和子层已接入两个正常应用；层内/层外视觉输入、失效、焦点和业务授权分别判定，业务仍委托原有领域动作。
- 无源码/测试/阶段日志的独立公共客户端已完成当前规则窗口验收：动态发现根资源与15个动作，以1字节分片创建中文临时规则、旧版本冲突和根资源读回；它没有验证 GUI、IME、延迟分布或慢连接并发，不能外推这些结论。
- 接续 source-blind 黑盒又复验了文档旧 descriptor 关闭后的退出2、新 descriptor 的 target observe 与 active progress、未授权 range 的退出5无内容；规则集窗口公开创建/读取具体 rule 内容、删除后的空投影，以及256次实际创建后的 explicit resync v2→v258。它没有泄露 descriptor/capability，也不把文档 `GET_CONTEXT=ALL` 错称 target scope 隔离。
- 物理中文IME候选/组合/提交/删除/粘贴仍未验；程序化Unicode、AX和候选rect探针不能替代。稳定公共API、整体呈现保证、完整富文本、多平台、安装/发布仍未验收。

## 历史与反馈入口

[输入阶段](../plans/2026-09-12-general-input-dynamic-components-milestone.md)、[刷新阶段](../plans/2026-09-12-efficient-refresh-display-progress-milestone.md)、[公共接入/文档视口](../plans/2026-09-12-developer-interop-document-viewport-milestone.md)、[文字/资源](../plans/2026-09-12-text-layout-style-resources-milestone.md)、[组件/自绘](../plans/2026-09-12-composable-ui-rendering-milestone.md)保留各自验收范围；旧绿色不能传递为当前整体完成。

长期工具链/FFI workaround和重复跨层问题按[设计导航反馈入口](../plans/DESIGN_INTENT_INDEX.md#问题反馈如何接回主线)接回既有账本。当前沿用SDK15.4不代表重新确认上游issue状态。demo_support、旧Action Router摘要和退役stage145–892按导航辨别，不复活Bool审计链。

## 执行与回报

遵守[AGENTS.md](../../AGENTS.md)。指导只复核、规划、文档和指派；执行自主完成整个阶段。必要旧问题与新能力一起推进，只有正确性阻塞暂停依赖工作，非阻塞遗留不要求清零。

同一问题两次实际修复验证失败后使用Kimi Code CLI的kimi-code/k3只读讨论；两轮有效建议实施验证仍失败立即回报指导给方法，次数跨轮累计，环境/锁屏不算源码修复失败。只在当前阶段简记，不建新台账。

锁屏跳过具体GUI，继续独立代码/逻辑/进程/布局测试和构建，不反复解锁或修改系统设置。原目录不新worktree、不切分支、不stage/commit/push、不覆盖他人工作或清理未知未保存窗口。

完整阶段完成或实质升级后更新本页和当前阶段交付区，主动回报指导任务`01a08f0f-e1ce-71c1-9a6e-4eee08308d61`（host local）。定期复核仅兜底，状态不变不重复指派或通知。
