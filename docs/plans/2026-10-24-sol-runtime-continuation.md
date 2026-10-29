# Sol 新线程施工图：普通窗口可持续运行、及时反馈与成本收敛

日期：2026-10-24。执行者：用户指定 GPT-6.1 Sol 的新线程。本文是已授权的大阶段实施任务，取代旧线程的继续执行入口；不是恢复全部历史任务。指导负责审阅，Sol 自主完成实现、必要验证和集中交付。

## 1. 本阶段要让什么变好

普通开发者应能在同一进程正常创建、关闭、再创建窗口；拒绝关闭、外部修改和弹层返回之后，界面能自行更新，下一次输入落到正确对象；输入和调整窗口尺寸不反复承担不必要的整套准备工作。最终交付是一套可被 DS 的统一 SDK 消费的运行时增量，以及两个正常消费者的对应证据。

先处理明确影响正确性和可用性的窗口生命周期、刷新推进，再处理普通负载的主导长段。呈现观测只服务于这个判断，不能把整个阶段做成采样工程。

## 2. 新线程从哪里接，不从哪里接

- 仓库：`/Users/jiangxuanyang/Desktop/cangjie`。先读根 `AGENTS.md`、`runtime/cjgui/ACTIVE_DIRECTION.md` 的 Sol/DS 摘要、本文、直接相关源码。写仓颉时按技能要求查语言资料。
- 旧线程 `01a1343e-c7ac-7392-b04f-52f884adce2b`，标题“Mac E：滚动反馈、连续输入与资源收束”。指导已观察其最新回合 interrupted、线程 idle；保留供查证，不发消息恢复，不 fork 全部历史。开工只核是否还有它启动的自有编译/验收进程；不得按模糊名称批量杀进程。
- 旧阶段方向和已接受边界在 [上次指导接续](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md#guidance-ordinary-runtime-large-stage-20261023)。本文收敛其顺序和当前反例，不把尚未完成的工作写成新包已交付。
- 当前可复现消费基线是 [DS48 SDK](../../runtime/cjgui/artifacts/ds48-runtime-ui-document-20261023/sdk/)，manifest content `95f334f0296baca853a5e7ee5ed9f5f1e0a3791e4fef8fea2a424a62f519c8c3`，595 文件、572 闭包。指导逐文件复算无差异，未重建该包。
- 以下根树源与 SDK 对应源在本次指导核对时逐字节相同；开工再核自己将改的文件，不能据日期或目录名认定全树相同。

| 成员 | SHA-256 前缀 |
| --- | --- |
| `src/composable_ui_window.cj` | `d3bd1224ad52` |
| `src/runtime_renderer_session.cj` | `dda4a5527ae3` |
| `src/macos_application_host.cj` | `ae240dddb070` |
| `src/owner_turn_budget.cj` | `17f90e1d3c11` |
| `src/prepared_layout_inputs.cj` | `44f78367f284` |
| `native/cjgui_internal_renderer.m` | `2ed24f8ae121` |
| `native/cjgui_internal_renderer.h` | `ad5a20aa3786` |
| `shared_operation_core/src/shared_operation_transport.cj` | `c423dd2ed940` |

窗口的 `nativeStaged` 五行修复和 DS 的 `invokeShortcut` 接线已在 d3bd 中，不能回退成旧 019a 源或重复套补丁。旧 Root 定向链、私有候选链、共同段成本证据各按自己的输入身份保留，不拼成一个“最终全绿”。

## 3. 写集与两线分工

Sol 写 window、renderer session、Mac host/native、prepared layout、owner budget/调度，以及这些机制的针对性测试和既有驱动。必要 ABI 成员随精确配套增量交付。

DS49 写 generated/region/composition、通用控件、多对象绑定、界面文档、Python、模板/rules 业务消费者、exporter 和唯一 SDK。不要改其 schema 或复制其消费者成为长期分支。transport 当前写权保留 DS；若实证必须改其唤醒接缝，先集中协调具体函数与不变量，不整文件同时编辑。

rules 的关闭策略仍由应用决定；Sol 处理公共 Host/窗口如何推进拒绝后的刷新。DS 处理本应用何时调用已有公共入口、显示什么文案。不得由 native 强行接受未保存关闭。

C 不再独立派工，Linux/H/W 保持封存。不要建立第二 SDK，不调用子代理/外部顾问，不做 Git 写操作。源码写集分开不等于可共用同一 cjpm target 并行构建；用明确冻结输入和各自可复用输出，桌面也串行。

## 4. 第一部分：把窗口测试的失败变成可解释、可修复的生产问题

### 已有事实

[DS48 原始日志](../../runtime/cjgui/artifacts/ds48-runtime-ui-document-20261023/evidence/notes-rule-change-20261023/window-app-tests-160.log)在同一测试进程运行 92 项：47 通过、25 失败、20 错误。原文有：

```text
CJGUI_REFRESH_INTERNAL_ERROR startup_phase=candidate_exception_after_controller_build prepared=false static=false
CJGUI_SCENE_REJECTED reason=internal_error
pumpRejectSceneAccepted(host, window) == true  // actual false
```

第一批失败包括 `rejectedSceneRollsBackGeneratedCandidateAndKeepsEditor`、`generatedCandidateTicketsArePerAttemptInTheApplicationProvider`。DS 报告相关定向运行能过；这提示同进程状态/启动/装配问题，但**不是已证明的原生生命周期根因**。控制器后的其他共同代码也可能抛异常，不能凭这一条 catch 标签认领根因。

### 施工顺序

1. 从现有 runner 取真实执行顺序、第一处异常、确切源码/sidecar/资源根。只运行能区分“单跑”和“前一个窗口结束后再跑”的最小序列；不要一开始反复跑 92 项。
2. 在原 catch 边界取到第一异常类型、消息和有界栈/阶段；不能先把异常吞成可接受空场景，不能为拿栈加入常驻海量日志。若是 DS 控制器/新声明代码的错误，交回精确函数和最小输入，不将它全部标为 Sol 缺陷。
3. 核对 NSApplication/main thread、host loop 引用、session/ticket、prepared 工作、callback、共享测试状态和资源路径的真实所有者。`close()` 请求、native destroy、待完成工作退休和可新建窗口是不同事件，不通过 sleep 等“稳定下来”。
4. 修生产接缝或受支持测试装配；不得删测试、删断言、在每个测试中重启进程冒充同进程修复，或扩公共 API 只为了访问测试内部。
5. 最小序列转绿后，在冻结输入上跑一次受影响窗口/场景组。再用普通入口做少量同进程开关/重开，证明修复不只服务测试。完整 92 项如仍有异类失败，按首因分组报告，不能一概归因为“历史测试”。

## 5. 第二部分：有工作就推进，没有工作才等待

### 已有反例

[rules 关闭证据](../../runtime/cjgui/artifacts/ds48-runtime-ui-document-20261023/evidence/rules-close-20261023/README.md)明确写着：未保存内容拒绝 ⌘Q 后，**补按一次 Tab** 才显示拒绝状态。已保存文档的 ⌘W/⌘Q 正常关闭保留为绿；这个反例不能改名成“拒绝提示已及时可见”。

当前消费者在 `pumpUntilWork()` 返回后消费 `consumeApplicationExitRequest()`，调用 `host.requestClose()`，被拒后 `window.requestRefresh()`。当前 `requestRefresh` 主要设置标记；下一轮如何识别 pending 和安排续行须查调度。以上只是定位入口，不预设“必须新增线程/定时器/唤醒 API”。

### 要达到的契约

- owner 业务拒绝已改变可见状态时，下一合法 owner turn 能推进到 accepted/显示；不依赖另一个用户按键、重复请求或外部消息。
- 外部写入、结构候选、图片/准备完成与关闭拒绝仍走已有调度职责；不再另建应用定时刷新循环。
- `requestRefresh` 的 public 语义、Host 的工作判断、prepared tail 和 wait 的关系明确。只标记不保证即时提交可以是接口语义，但正常 Host 不能在有待处理工作时无限休眠。
- 多次标记可合并；已在途票据按原 epoch 结算；所有有效业务输入/FIFO 保序，不能用“最新一条覆盖”处理正文编辑。

用现有普通消费者证明：未保存 ⌘Q → 无其他输入即可看到原因 → 继续编辑 → 明确保存/放弃 → 正常退出。另一个真实外部修改或准备完成场景作关联回归即可，不把同类每个按钮都各建一套矩阵。若当前公共 `refreshIfNeeded()` 的一次正确消费已足够，给 DS 精确调用时机；若底层缺陷则在本线修复并交付，DS 不碰你的文件。

## 6. 第三部分：普通输入和尺寸变化的主要成本

第一、二部分稳定后，在同一运行时输入上复用 mixed/rules，覆盖逐键输入、连续缩放、滚动、兼容结构/样式改版、弹层返回首键。先用已有成本与一组有界新样本决定主导段，不再从所有组件重新盘点。

已有 81→11 克隆、2→1 文字准备是特定共同段的绿证，保留，不重复实现。原有 507/695ms 历史样本与 16/32ms 门没有因为这两项改善自动转绿；本包必须说明当前普通工作量中的主要长段是否仍在。

按实际原因选择生产改动：避免相同依赖下重复 projection/clone/shape；延续已准备候选的原 tail；按已有预算拆可拆工作；只合并语义允许替换的视口/样式请求。尺寸变化后命中必须对应新 accepted 几何；正文、范围选择、owner 版本和实例身份门不能为缓存省略。

新复用键须覆盖实际影响它的正文、宽度、字体代、样式、布局约束与会话生命周期。不要一次引入多层缓存；先证明一次重复工作可被去掉，再测相同负载。没有新瓶颈就不要为了交数字增加缓存。

可见反馈与工作时间分列：原输入/owner turn/scene/frame/drawable 标识关联；Metal presented 若为 valid=0/time=0 就保留未知，不能用 callback 到达或 commit 时间填充。观测缺口只做一轮有区分力的定位后继续生产工作，不等到所有物理呈现指标齐了才做其他部分。

保留冷、暖、拒绝和慢样本；不删 max、不降负载、不关 vsync、不忙轮询、不吞事件换成绩。若 16/32ms 仍未达，给剩余主导成本和本包实际收益，而非再申请无边界采样。

## 7. 第四部分：最终双窗连续会话与精确交接

同一最终运行时输入完成：主窗编辑 → 打开第二窗 → 改数据/大小，两窗可响应 → 关闭第二窗 → 主窗首键 → 重开第二窗 → 正常最小化/系统恢复 → 编辑 → Apply/保存 → 正常关闭全部。

区分 AX Raise、前台、key window、first responder 和文本会话；正常系统激活成功后仍不能续写才判对应产品路径。不得为工具方便让后台窗无条件抢焦。需要真实输入的步骤不能用直接 owner 写入代替。

资源按真实租约/在飞完成/关闭终态说明；稳定缓存不要求每一帧清零，RSS 不立即下降不是泄漏证据。旧窗口迟到结果不得操作新 session。历史未重现事件仍保留未归因，不为证明旧因果无限重跑。

给 DS 一份精确运行时交接：基底和结果 SHA、最小相关增量、配套 ABI/调用条件、相关测试、正常候选、未验边界。新消费者源码仍归 DS；必要薄接线建议写在交接，不长期在私有副本维护。新 SDK 只由 DS 冻结。

## 8. 长跑方式与停止空转

本阶段四部分连续推进，普通语法、脚本、构建、现有契约内接线自主处理；不按每个文件/探针停工找指导。发生系统性归属/生命周期风险不明或反复实修低收益，按 AGENTS 集中交具体失败，其余部分继续。默认无顾问、无子代理。

每次检查必须能改变下一步判断。若几轮只更新采样/脚本、没有逼近首因或可见能力，主动缩为一个可区分反例，或改变实现方案；不要用新线程名清零旧失败累计。

可定向参考本地 GPUI 的窗口关闭/唤醒、Metal completion、文字准备和失效机制，以及 CJGUI 已有普通宿主；只借鉴，不引入依赖。不要求通读旧十几万行聊天、所有 RESULT 或重做 GiB/全平台/全 IME。

## 9. 空间与集中报告

遵守 [容量规则](../../AGENTS.md#artifact-space-budget)。E 既有范围沿用留存≤13GiB、峰≤14GiB、宿主峰后≥20GiB；这不是给新线程另加 13GiB。上包接近上限，先核准确输出归属，复用工作目录；只退役已保全证据的本线可再生输出，不碰 DS/用户/旧唯一失败原件。默认日志限量，禁止按轮复制完整树。

结尾报告实际行为与生产收益、失败/未知、精确输入和可用候选、DS 接线、空间账。更新 ACTIVE 唯一 Sol 段。无 stage/commit/push/reset/stash/分支操作，不启动 Linux 或旧线程，不另造 SDK。无需再回传一轮同义收口确认。

<a id="owned-preparation-handoff-20261024"></a>
## 10. 指导接续：准备声明的拥有型异步交接

2026-10-24，针对本线程主动升级的 Mixed 原始最小化反例。继续同一整阶段，不另开顾问/代理或第二份 SDK。

### 已核事实与集中取舍

指导核对了 `runtime-converge7-mixed-overlap.log` 原件：owner turn153 为1084.524ms；session2/preparation17/generation2/dispatch2260 的 sync_call→main_enter 队列等待1065.419ms，main_enter→main_exit 服务8.375µs。对应源码 prepare/reuse node batch 都经 `CjguiOwnerTraceDispatchSync`，仓颉 wrapper 在调用返回时释放节点/geometry/CString；不能只把 dispatch_sync 换成 dispatch_async。全局解析有环形覆盖/解析缺口，本次因果仅采用这条身份完整的 dispatch 与独立 owner cost 原行，不宣布整个 trace 完整。

**采用你的推荐方向：扩展现有 preparation mailbox，交接有界、完整拥有的声明包；AppKit 继续拥有私有准备图。** 允许配套改 Sol 的 window、renderer session、私有 C ABI/header、native 和定向测试。公共组件/业务/生成协议不变，DS 消费者/exporter不并写，Linux不恢复。旧同步兼容入口可留给非正 deadline/既有调用者；macOS 正 deadline 的生产路径必须明确走新协议，不能把 pending 当 unsupported 后暗退同步路径。

复用现有 scalar advance 的 slot/nonce/generation、单一 serviceScheduled、真实完成唤醒与退休责任，扩成一个操作种类明确的准备交接，不再建平行“候选管理器”。本地 GPUI `gpui_macos/src/dispatcher.rs` 的 main dispatch 把 Runnable 所有权交给回调、由 trampoline 取回并执行，可以参考所有权交接的边界；不引入其依赖，也不照搬 Rust 裸指针到仓颉。

### 1. 明确拥有、身份与有界准入

节点包至少冻结 `(session,generation,preparationId,nonce,operationKind,firstIndex,count,deadline)` 和原 trace 关联。沿现有每批最多8节点规则，完整复制 POD、geometry、所有被 native 使用的字符串及嵌套数据；计入字节预算、长度/加法溢出检查与分配失败。不要在异步 block 捕获仓颉数组、栈 out 参数、mallocCString resource 的借用指针。不要因 count 有限就假定字符串字节有限，也不要为绿随便缩小正常节点能力。

Main 才查 session 对象和私有图；准入侧只使用可跨线程的值与既有 generation 原子事实。不得将借来的 AppKit 对象指针装入待执行包。原 caller 可在准入返回后立即销毁/修改其输入，包仍完整可用。完成结果只有值和实际前缀，不保留 caller 输出地址。

每 session 的在途数/字节和全局预算有明确上限；容量满返回可恢复的准入结果，等待真实释放，不自旋、不叠无界 block。优先一份已冻结操作＋一个既有 service wake，消费完成后才提交下一份。重复查询不得重新复制载荷或发新请求。

### 2. pending、完成、cache miss 和 deadline 必须可区分

采用内部明确的完成态＋停止原因（可扩既有私有 ABI 的输出，或新增私有 admit/poll 对），别复用 `reused=0` 表示所有情况。调用者必须能区分：仍 pending；完成全部/实际前缀；真实 cache miss；本次 deadline 已到未继续；stale/cancelled/failed。

pending 时只保留原请求并返回，不能推进 nativeCursor、调用 full fallback 或再次入队。完成的前缀只记一次；重复消费不能二次填槽、写帮助语义或增加计数。reuse 只有**完成且明确 cache miss**，才对未完成位置做原有完整声明 fallback。deadline 到的0前缀不是 cache miss；错误时按原契约退休私有候选，不把其部分副作用当 accepted。

已入队操作的绝对 deadline 不被查询或资源唤醒续期。过期只结算一次；后续在合法新 owner turn 获得新的预算后可为剩余前缀发新 nonce，不重放已完成部分。不将 pending 映射为立即 runnable 的 `needsReadyContinuation()` 循环：真实完成才通知 owner；尚未投递但有可执行预算的剩余工作与等待 Main 的在途工作要分开。

### 3. 退休与执行中的所有权

不要对含 owned pointer 的 slot 继续裸 `memset` 后丢失释放责任。服务在锁下取得独立执行引用/所有权，再在锁外调用 Main；cancel/replacement/close 退休 slot 只撤销发布资格，不能释放正在用的包。执行结束校验 nonce/generation/preparation，过期结果丢弃并最终释放，不能写新窗口或新候选。

排队未执行、Main已取包、完成待消费、消费后、窗口关闭/会话槽复用这些终态都要有且仅有一个最终释放者。不持有 mailbox 锁进入 AppKit，不在锁内等待 Main/GPU，不新增主线程与 owner 的反向等待。取消旧包仍保留已有 single service wake 的责任，不能每退休一包就再叠一个回调。

### 4. 沿生产调用链修，别把同步堵塞挪到下一行

指导读到 `nativeCursor` 更新前还有 `internalRendererSetComposableSemanticHelp`，它也同步派发 Main；begin、resident-source、caret、image 声明也要按实际正 deadline 路径核对。先完成 node/reuse 的拥有型协议，再把同一声明提交所必需、会紧接着同步等 Main 的元数据接进同一有序包或同一邮箱的有界操作。

原图构建仍有顺序：begin成功→声明/所需元数据完成→advance→commit；仅“已排队”不能设置 nativeBegun 或 nativeCursor 为完成。不能只让 nodes 异步，随后用 semanticHelp/barrier 的 dispatch_sync 把相同1秒等待重新带回来。对于没有本轮证据影响的无关 native API，不做全库异步化；有剩余必经同步点要具名列出，不能称生产路径已去阻塞。

window 候选只增加原准备游标所需的请求 token/等待状态，业务 owner、selection/source资格、FIFO、候选epoch保持不变。Windows 等旧同步适配可由 wrapper 映射成 completed；不改变其原来0表示miss的语义，不恢复平台验证工程。

### 5. 用可区分反例一次验证责任，再回普通窗口

先做有 gate 的定向测试，不靠 sleep 猜时序：

- Main尚未执行时，正deadline准入已返回，caller输入已释放/改写，之后输出仍精确；其他窗口的 owner 工作可推进。AppKit 主线程本身被系统占住时不承诺别窗已经呈现。
- pending reuse 不触发完整上传；真miss、过期0前缀和部分完成各走自己的路径；同一结果不能消费两次，旧前缀不重放。
- 排队/执行中取消与关闭重开，旧 nonce/generation 结果不污染新对象，资源回到真实终态；预算满时有界、释放后可继续。必要 ASan/生命周期验证聚焦这条新所有权，不重做全平台。

随后在**同一正常原负载**复跑 peer CmdA→原始2→系统最小化，主窗保持可用、owner精确读回、正常恢复/续写/关闭。保留原 Esc→9→CmdS 的已绿原事件回归。测量要同时列 owner调用耗时、Main队列等待、Main服务、submit到consume延迟；把等待搬入异步队列不等于用户端到端延迟已消失，更不能靠遗漏 pending 工作使16/32ms变绿。不可删慢样本、改负载或增延时等待动画结束再测。

### 6. 其他进展与汇合

原 Esc越序修复、成本输出完整性修复先按你的报告范围保留，最终增量一并交接。Rules 冻结适配的 `snapshot()+serialize`→已有版本读取具有明确收益；先把精确 hunk、等价事实与负载原件交 DS/指导，不直接写 DS 主树，不把49ms说成32ms已达。DS51目前继续文件/scoped/关闭组合，本次新运行时仍不进入它的 SDK，直到精确交接明确。

按上述顺序继续原整阶段，不按每个packet函数停下来请示。若 packet 不能安全拥有某个资源，或仍有新的循环等待，集中交出具体类型、所有权和已区分结果；其余独立工作继续。完成或出现实质阻塞时，按用户既有授权主动回报当前指导线程，附原 RESULT/handoff、准确可消费增量与剩余门；不再要求用户搬运。容量沿§9，正常进展留在本线程。
