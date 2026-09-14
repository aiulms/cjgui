# 大阶段：公平调度与实际性能基线

日期：2026-09-12。原目录、原执行任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`，gpt-5.6-terra / xhigh。指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`，host local。

## 为什么现在做

用户目标仍是基于仓颉、类似 GPUI 的高性能自绘 GUI 框架，人和外部系统共同操作。前置层、虚拟列表和公开客户端已有较完整形态；下一优先级是证明外部吞吐不会伤害本地响应、空闲与资源成本可解释，不继续只增加样例控件。

完整结果：窗口在持续请求、慢连接、大上下文读写与批量修改期间仍能公平处理输入/关闭/刷新，外部请求有界推进，不丢结果、不越权、不阻塞主线程等待网络。普通文档/规则集消费者使用同一执行主链，形成可重复的响应/资源测量，以及补齐前置层的人机接续与独立消费。

依据 [设计导航](DESIGN_INTENT_INDEX.md)、[框架避坑](../research/gui-framework-pitfalls-intelligence.md)第1/2/3/5/7节、[运行架构研究](../research/ai-native-gui-runtime-architecture-intake.md)的业务变更/局部反馈分工，以及[前置浮层阶段](2026-09-12-composable-layers-menus-dialogs-milestone.md)。旧 opening 禁令不恢复。

## 复核基础与资产

- 复用 [transport](../../runtime/cjgui/shared_operation_core/src/shared_operation_transport.cj)的授权、帧上限、领域动作、变化流及刷新信号，公开客户端保持正常入口。StringBuilder 和16KiB分块已改善千项上下文；不是再次换协议或新建Agent runtime。
- 复用 [通用窗口](../../runtime/cjgui/src/composable_ui_window.cj)的FIFO身份、最后成功/尝试条件、层焦点范围、渲染/语义版本、显式恢复，以及 [native](../../runtime/cjgui/native/cjgui_internal_renderer.m)的主线程桥接与资源生命周期。
- 当前普通循环先 `pumpBurst(16,1,1)` 再窗口pump。每个 `pump` 同步读取整帧、执行并写完回复，readTimeout=128ms/writeTimeout=512ms；serveClient与分块write循环没有整请求deadline。请求数有界不等于离开本地输入的墙钟时间有界，慢速分片可持续重置单次I/O等待。先复现，不把注释“无法pin应用循环”当证明。
- 千项真实endpoint报告：1,001次创建3.160s、完整GET_CONTEXT 0.018s、物化0..7、63次刷新；这是一次运行的吞吐/计数，没有证明输入尾延迟、空闲CPU、GPU/内存或长期资源稳定。
- 前置已有层宿主、菜单/dialog/子层、焦点范围、锚点/异常行修正，规则领域14/14、布局/窗口控制器探针、第二规则消费者与root build的执行范围。指导只静态审阅，没有重跑开发测试。两bundle创建和首帧不替代最新层的真实输入周期；独立Agent、千项人工滚动、物理IME仍承接。

## 一、请求与本地事件公平推进

用受控客户端复现：每隔短于readTimeout的间隔发送一个片段但不完成帧；有效大回复的客户端缓慢读取/暂停读取；连续正常短请求与上述慢连接并存。记录窗口pump/真实输入/关闭的进度、请求时长与资源，先取得可区分原因的失败证据。

改为有界非阻塞推进，或有限I/O执行单元加应用线程收发队列，具体最小方案由执行AI决定。网络等待不能占住拥有GUI/领域动作的线程；只在其有效线程上执行真实操作/取得快照。后台单元不能直接改领域、native、窗口或独立写语义真相，不通过nested runloop偷跑应用逻辑。

限制并存连接、排队请求、响应缓存和总字节；读取/写入有整请求或各阶段绝对deadline，实际I/O遵守剩余时限，不能只在外层while检查预算。慢连接过期后释放，正常客户端不能被饿死；繁忙/超时/关闭有明确结果。正常大帧仍须完整、不因分块悄悄截断。避免每个请求无限生线程/任务。

窗口和外部处理有明确的数量与时间预算，事件负载下合并刷新但不无限推迟。按测量选择默认值并解释；不盲目承诺固定FPS或所有业务动作都有硬实时上限。若单个领域计算仍较重，先记录边界与优化真正瓶颈，不能把全仓领域搬到后台线程规避。

## 二、一致性、生命周期与兼容

授权和版本检查在实际执行时生效，排队时看到合法不代表稍后可无条件执行。同一连接请求顺序、不同连接公平性、变更信号和一次性结果语义清楚。写入已成功但回复中断不能宣称没发生或自动重试非幂等动作；保留现有requestId/版本与读回机制，测试丢失回复后的安全恢复。

关闭窗口/连接、重开、timeout与迟到完成不能访问已销毁对象或污染新会话；排队中的未执行请求和已执行待回复分别处理。回收所有新增连接、队列和I/O资源，不清理他人的实例。等待/公开错误类型兼容迁移要有消费示例；headless消费者继续可用，GUI仍默认可不启用外部连接。

增加针对性进程/窗口回归，包含授权目标在排队期间失效、旧版本、失败恢复、慢写、慢读、关闭时有pending结果、有效正常客户端不饥饿。使用临时数据，不把用户文件或剪贴板当压力负载。

## 三、可重复的框架运行成本

在同一机器/SDK、同一数据量、当前正常产物下，测无连接空闲、有连接空闲、重复GET、单项编辑、100条批次、持续请求混合输入、菜单/对话框与长列表滚动。给清楚的预热、样本数、时长、窗口大小/可见性和数据规模；输入到处理/提交/overlay分别命名，不能把程序化事件到队列读出称为人眼延迟。

选取真正有用的指标：本地事件等待与处理的分布/最大值、请求延迟与吞吐、build/layout/native提交/排版次数、进程CPU/内存和连接/队列高水位。GPU若工具可用给实际时间/利用率，否则明确尚未观测，不从Metal调用次数推断。比较修正前后瓶颈；没有足够样本不包装P95结论。

让一次普通命令可复现实验，复用现有诊断与探针，报告在当前阶段即可，不建报告驱动状态机或新治理系统。测量功能轻量/可关闭，不能让日志本身成为负载。若要优化，只针对有证据的主要成本，保留原始结果与局限；GPUI仅目标参照，没有同条件数据不作性能对比声明。

## 四、前置层闭环与独立使用

完成规则集与文档当前产物的菜单/子菜单/对话框鼠标、Tab、Escape、焦点恢复、外部更新后的接续；千项真实窗口键盘导航/滚动并显露此前屏外修改目标。首帧或native探针不替代这些可见交互，遇锁屏先推进其他项，留下具体环境证据。

安排一个无实现上下文的 Luna/Terra 验收Agent，只提供公开README、CLI/API入口、应用descriptor和自然语言目标，让它动态发现当前对象/层、读取/执行/处理一次明确失败并读回。阶段明确授权该验收，不要再仅因“尚未安排”停工；真正不可用时列出尝试入口与阻塞。独立消费者不要阅读源码/测试/阶段日志或被预填业务ID。报告真实Agent身份、运行场景及结果，早期已通过的独立文档场景不能替代当前层与调度改动。

验证一个外部业务操作在视觉模态存在时仍按有效授权完成，缺参/冲突正确返回，人的层状态据领域结果保持一致。不要因弹窗人为新增确认。物理中文IME仅在条件允许时补真实候选/组合/提交证据，未跑仍单列。

## 执行边界与回报

按AGENTS.md做公共契约/native/并发跨模块影响检查，以当前源码、进程与生产事件路径补图索引不足。相关core/客户端/领域、窗口/native/传输回归及root build --skip-script、差异与声明检查在适当时机运行，不逐helper全量重跑。

原目录Terra/xhigh，不stage/commit/push、不切分支、不覆盖他人改动。指导只给方向/诊断/复核，执行实现。两次实际修复失败请K3只读讨论；两轮有效建议实施仍失败立即带证据回报指导，次数跨阶段累计。不能以锁屏或工具不可用冒充源码失败。

完整阶段完成或实质升级时更新ACTIVE_DIRECTION和下方报告，主动回报指导任务。报告同时列调度/资源保证、真实性能与未测项、前置层/千项/独立验收去向。前置阶段保留未整体验收标记，不通过改阶段名抹去遗留；没有用户环境依赖就连续完成，不能只因一个局部测试绿色停工。

## 交付区

### 2026-09-12 执行更新

**已实施的最小公平路径。** 原 `pump` 在窗口 owner 上同步执行 accept、整帧读取、领域调用和整帧写回；慢客户端每次有少量进度即可反复延长等待。红测先确认：仅发送三个帧头字节并停180 ms 时，旧窗口 `pump(1)` 约190 ms；一个完整授权 peer 在该慢 peer 并存时，80 ms 内不能得到响应。

现有 transport 保留 descriptor、授权、版本检查和领域 owner，不增加第二状态机：一个 accept worker 与四个固定 I/O worker 管理接入队列8、就绪请求队列8和16 MiB就绪请求字节。读总时限160 ms、写总时限512 ms；每一次真实 I/O 使用不超过8 ms且按剩余总预算收紧。worker 只能读/写字节；请求到达窗口 `pump` 后才执行 `dispatchPayload`，所以授权和版本均在执行时检查。慢分片回归现在确认窗口 `pump` 少于80 ms，完整 peer 在另一个慢分片并存时80 ms 内得到快照；完整 core 测试的187/231 ms包含故意等待慢 peer 退出，不能被标作正常请求延迟。

**生命周期回归。** 规则集独立消费者真实复现了新竞争：它在最终 `pump` 返回后关闭，工作线程尚未写回最后一个 `GET_CHANGES` 响应，客户端报“连接在完整响应前关闭”。关闭现在仅等待已发布到响应队列的请求最多64 ms；未执行、未完成或慢写的 peer 不获无限宽限，随后一律取消并回收。新增 `genericTransportDeliversDispatchedResponseDuringBoundedClose`，core 27/27 与规则集独立消费者/双进程保存竞争均通过。

**真实窗口与成本样本。** 当前规则集 bundle 的公开 descriptor 创建1,001条临时规则：3.003 s；一次全上下文读取：0.009 s。真实窗口按 End 显示995–1001。编辑对话框仍可见时，外部 `BATCH_SET_ENABLED` 作用于200–299（版本1001→1002）并读回两端为启用；随后通过普通键入把本地草稿保留天数改为17，窗口读回17。完整大上下文慢读 peer 并存下，五次 `GET_CONTEXT(8000)` 为1.4–1.5 ms；当时进程快照为RSS 180336 KiB、CPU 1.2%，仅是一刻的样本，未宣称空闲/长期内存或GPU基线。外部持续读取时，真实窗口菜单可打开并由 Escape 关闭。

**补齐的层缺口。** 真实规则窗口发现顶层锚定菜单打开后 Escape 无效：非模态层没有接管焦点，键盘仍留在基础 scope。原生窗口控制器先以普通 mouse-down 路径新增红测，随后将新出现层的焦点移到其显式初始节点或首个可聚焦后代；顶层菜单的 Tab、Escape和锚点焦点恢复现在通过。该修复没有把业务行为放到 native。

**独立公共黑盒。** 一个无源码、测试、阶段日志或 Git 状态上下文的独立执行者，按规则集公开 README 启动自己的临时应用，只经运行时 descriptor 与 `client.py` 动态发现根资源8000和15个动作。它以1字节分片创建中文临时规则，旧版本创建返回 `version_conflict`，再读回版本2、规则数1和选中ID1；临时应用和文件均由该执行者清理。它不验证 GUI、IME、慢连接延迟或并发公平，故不把这项黑盒结果扩大为那些结论。

**验证与边界。** 已通过：`cjpm test --timeout-each 30s`（core 27/27）、`verify_composable_ui_window_controller.sh`、`examples/rule_set_second_consumer/test.sh`、`runtime/cjgui cjpm build --skip-script`，以及最终规则集 bundle 构建。构建存在既有 `chmod` 和 AppKit `allowedFileTypes` 弃用警告。当前桌面在完成实窗验证后重新锁屏，未对最后仅含关闭收尾改动的 bundle 重做 CUA 视觉输入；该 bundle 已构建。物理中文 IME、长期 CPU/GPU/内存和严格同条件输入尾延迟仍未完成；不把上述黑盒或前置共享文档结果外推为这些结论。


### 指导复核与继续实施（仍属同一大阶段）

接受上述固定I/O worker、owner线程dispatch、core27/27、独立规则黑盒与实窗周期的针对性执行范围；指导静态复核，没有重跑测试。5次定向请求与一刻RSS/CPU样本不完成原定可重复运行成本目标。当前阶段继续，不因换任务名称而递延性能验收。

**需落实的边界与具体方法：**

- `serveQueuedClient` 在完整帧排入ready队列后循环 `waitForResponse`，只有stop/cancel结束，没有排队等待截止时间。先用owner暂停pump、四worker均持有完整请求复现，再验证有界排队/拒绝/资源释放与恢复；取消与owner领取执行必须原子协调，超时不能既宣称未执行又稍后悄悄修改。已执行但回复失败单独说明，不伪造回滚。
- `writeFrameWithDeadline` 捕获SocketTimeoutException后重试相同offset的16KiB块。仓颉本地原始文档的UnixSocket.write返回Unit，仅说明writeTimeout，未给出超时意味着零字节已发送的保证。核对当前工具链实际实现或用受控背压验证部分写后超时，比较收到的整帧字节/长度而不只解析前缀；不允许在发送进度未知时盲重发。可选择使worker用剩余总预算写入、超时关闭，或使用能准确报告部分进度的受控内部入口；具体选择按证据，不为猜测改公共ABI。
- `close` 的64ms已发布响应宽限只是有限策略，不能保证允许512ms写预算的正常响应总能送完。用正常接收、大回复、64–512ms受控背压和完全不读的peer测试；明确快速取消关闭与有限消费者正常结束的差别，保证有限结束不依赖偶然sleep成功。超时已提交业务的结果保持可解释，宽限耗尽后有界退出，不无条件加长GUI阻塞。
- `stop`只发取消/关socket，worker futures仍保留在state；不要仅凭代码未join就断言泄漏，但必须测多轮start/close/reopen后worker/FD/内存收敛和迟到回调隔离。一次单连接慢分片不证明四worker占满时正常请求公平；覆盖满worker慢读/慢写与正常客户端并存。
- `pumpBurst`仍仅按数量限定领域执行；用满负载测本地事件等待。需要时增加可配置墙钟预算，在两个完整动作之间让出，不能中断已开始领域写或靠只读探针成绩外推输入尾延迟。

**把已授权的测量做完：** 提供一条可重复命令，正常构建产物、临时数据、预热/样本数/环境明确。至少测无连接空闲、有连接空闲、全量与定向GET混合、批次/输入、连接饱和与开关循环；安排一段连续资源观察（例如10分钟，含稳定负载与恢复），记录CPU/RSS/FD/worker/队列高水位和趋势，不只单点。GUI受锁屏影响时仍可测普通进程成本和生产事件探针，但明确它不是物理输入到人眼延迟；GPU实测工具不可用如实写未测，不伪造估算。样本足够才给分位数，解释实际瓶颈与局限，按证据完成必要优化。

保留已通过的规则集独立黑盒身份/场景，不再笼统标“独立Agent全部未验”；具体新调度、文档层或物理IME未覆盖仍单列。最终GUI复验遇锁屏可保留，但不能据此停止独立的网络、生命周期与CPU/内存测试。两次修复失败/K3升级按原规则累计；完整阶段或实质阻塞才再次交付。

### 2026-09-12 继续实施交付（headless 调度、生命周期与成本基线）

**原子排队期限。** 先新增四个 worker 都完成 `SET_MARKED`、owner 暂停300 ms 的实际 UDS 红测。旧路径会在“调用方已等到请求过期”后由 owner 迟到领取并把列表版本改为1。请求生命周期现由同一 mutex 保护 `waiting → claimed → cancelled`：worker 只可取消未领取请求，owner 只可领取仍为waiting的请求；已取消的ready tombstone被owner drain但永不执行。默认等待上限256 ms。回归确认四个过期请求不写入（版本仍0、标记仍false），其后的正常 `GET_CONTEXT` 在240 ms窗口内恢复；诊断同步观测5个I/O future、ready高水位至少4及非零排队字节。

**未知部分写与关闭。** 仓颉标准库 `UnixSocket.write` 的签名返回`Unit`，未提供timeout时“已发送0字节”的保证。因此不扩展公共ABI，也不猜测offset：`SocketTimeoutException`立刻结束该一次性流，避免对同一16 KiB片段盲重发。正常接收者的约5 MiB快照可完整读到；完全不读的同类peer关闭不会等待512 ms writer预算（若内核已接收全部字节可立即返回，64 ms是宽限上界而不是下界）。另以普通第二消费者和1024字节接收缓冲做实际背压：请求后停700 ms，帧body声明37,725字节、实际只收8,186字节，endpoint正常退出并删除。这表明当前机上确有部分输出后超时/关闭的路径；该结果配合不重发实现，不能把中断回复解释为领域动作回滚。

**连续可复现实验。** 新增 `examples/shared_operation_second_consumer/transport_perf_baseline.py`；它启动普通第二消费者的有界诊断模式，只经公开descriptor/capability发起请求。诊断是owner本地只读计数，未进入descriptor、语义快照或领域状态。普通命令为：

```sh
cd runtime/cjgui/examples/shared_operation_second_consumer
zsh ./build.sh
python3 ./transport_perf_baseline.py \
  --duration-seconds 600 --sample-seconds 5 --recovery-seconds 15 --idle-seconds 5 \
  --output /tmp/cjgui-transport-perf-600s.json
```

本机已实跑的原始 V1 JSON 仍位于`/tmp/cjgui-transport-perf-600s.json`，不覆盖：2个正常定向`GET_CONTEXT`线程与2个每次只发送3字节、停125 ms的有限碎片peer，共完成469,410个正常请求和9,151个有限慢peer循环；请求p50/p95/max为1.222/12.249/16.641 ms。该 JSON 的`IO_WORKERS=5`是 retained future 数，`fd_count=13–14`是 `lsof` 显示行数（含`cwd`、`txt`等），不能解释为活 I/O loop 或数字 FD；其 RSS/线程结论也只保留原始样本范围。V2 改为分别报告`RETAINED_WORKERS`、`ACTIVE_IO_WORKERS`和`lsof -Ff`的数字 descriptor 字段，并加入无 peer 空闲、连接但不发帧空闲；GPU仍未观测。原报告的主进程关闭后descriptor/socket删除和15 s新进程恢复成功，仍仅证明各自进程的 endpoint 回收，不证明同进程重开。

**回归与范围。** `shared_operation_core cjpm test --timeout-each 15s`为29/29；通用第二消费者验收、规则集第二消费者验收及真实双进程保存竞争均通过；`runtime/cjgui cjpm build --skip-script`通过。通用消费者验收同时修正为把公开CLI规定的`unauthorized_* → 5`和版本冲突`→ 4`作为预期失败而非测试脚本异常。GitNexus旧索引未收录`CjguiSharedOperationExternalConnection`，其变更扫描只映射到无关文档；已以源码消费者枚举、全量core和两个独立消费者补证，不能把图的`UNKNOWN`当运行结论。`chmod`弃用警告仍存在。

阶段仍非整体完成：锁屏后没有重新做最终GUI实窗输入周期；物理中文IME、物理输入到提交/overlay尾延迟、GPU时间/利用率，以及无连接GUI空闲成本均未测。以上headless结果也不外推为这些事实。


### 指导复核：从通信基线推进到窗口运行成本

指导静态审阅最新源码、压测脚本和600秒原始JSON，未重跑开发测试。接受29/29及本次469,410次定向GET的执行报告范围；JSON记录CPU末值53.5%、最大79.8%，RSS有明显波动。此负载不代表空闲GUI或绘制效率。继续当前大阶段，下一交付重心是可复用的窗口调度与实际渲染成本，同时修正以下有证据的边界；不再次仅交付一轮通信压测。

1. **队列真实占用与截止。** `expirePendingRequest → discardPendingRequest`在payload仍由ready tombstone持有时扣queuedRequestBytes，`takeReadyRequest`稍后再次扣同一payload；夹入新请求会低估占用，负数钳零掩盖问题。先用过期大帧、未过期新帧交错复现，保证物理持有字节只在释放/出队时扣一次，16MiB限制与诊断对应同一含义。`claimForOwner`目前只查状态，256ms到期由worker轮询取消；owner若先于晚调度的worker领取，仍可能越过所宣称的绝对截止。若契约是绝对未领取期限，保存单调时钟deadline并在同一领取锁下检查；区分调度容差与业务已领取后的完成语义，不宣称可抢占业务执行。
2. **测量结论修正。** `IO_WORKERS`来自retained futures数组长度，不是活worker数；`lsof`行数包含cwd/txt等，不等于数字FD。新进程15秒恢复只证明重新启动可用，不能证明同进程多轮start/close资源收敛。修正指标名称或采样方式，补同进程循环及无连接/有连接空闲；历史JSON保留，不覆盖原始事实。记录产物身份、数据量、预热、请求成功/失败和测量条件。无需为了修正标签机械重复全部600秒。
3. **把窗口主链做实。** 复用composable_ui_window的失效合并、现有native提交/overlay进度、领域owner与平台主循环；规则集当前循环是pumpBurst(16,1,1)、刷新、window.pump、sleep16ms。先测持续业务/大上下文下本地事件等待、空闲唤醒与CPU、构建/布局/文字排版/提交频率，再据瓶颈实现通用有界调度和必要的唤醒/等待改进，由规则集与文档两个应用正常消费。数量预算不能宣称墙钟预算；时间预算只在完整领域动作之间让出。保持交互状态单一归属，不新增全局tick或第二状态机，不仅把调度helper复制到样例。
4. **实际渲染与混合负载。** 补窗口无外部连接空闲、有连接空闲、千项列表导航、文档编辑、批量修改并行本地输入/层交互的重复测量，分开事件到处理/提交/overlay时间与物理呈现。有条件观测真实Metal完成/GPU时间；工具不可用明确未测，不为统计强制每帧readback、不把提交计数当GPU成本。锁屏时仍完成通用调度实现、生产事件路径探针、正常进程资源测试和构建；可见窗口/物理IME只保留具体未验项。复用历史避坑第1/2/3节的主线程、盲目重绘与状态归属教训，而不是恢复旧治理禁令。

关闭64ms是快速取消政策，8ms单次write超时会提前于512ms总预算结束；正常接收、大回复与受控中等背压的边界须如实公开，已提交但回复中断保持结果不确定与读回恢复。不要为了好看的成功率放宽为无界等待。新阶段候选优先考虑测量揭示的渲染/文字排版瓶颈，其次是正常包消费与开发者可组合接口；当前先交付窗口调度与成本闭环，不提前扩展样例业务、富文本或多平台。

完整任务继续由Terra/xhigh在原目录执行，两次实际失败/K3升级规则跨轮累计。只剩确实依赖桌面的项时可明确交付独立部分；其余已授权工作持续推进，完成或实质升级后回报指导。

### 2026-09-12 继续实施交付（二）：物理队列、窗口转向与口径校正

**队列与领取边界。** 先给已有 owner 暂停300 ms、四个完整请求的实际 UDS 回归增加“已过期 tombstone 的`queuedRequestBytes`仍非零”断言，并新增延迟260 ms后 owner 直接领取的红测；两者分别暴露提前扣减物理 queue byte 与只靠 worker 轮询取消的漏洞。新增确定性容量回归再交错三个5 MiB已取消帧和一个新的2 MiB帧：在 owner drain 前后者因物理16 MiB占用被拒绝，drain一个 tombstone后才可入队。现在 payload 仅在`takeReadyRequest`实际出队时扣减；过期只从待执行清单移除并保留 tombstone，故16 MiB admission 与诊断代表同一物理占用。请求创建时保存`MonoTime`，`claimForOwner`在同一 lifecycle lock 内检查256 ms绝对未领取截止，过期请求不能被迟到的 owner 执行。core 回归也明确区分`retainedWorkerCount`与`activeIoWorkerCount`。

**同进程关闭/重开。** I/O state 只在运行时允许 worker 进入计数；close 关 socket/取消请求后，最多64 ms等待该 state 的固定循环退出，再允许下一个 start。`genericTransportRestartsSameProcessWithFreshWorkerState`在同一连接对象完成 close/start：旧 descriptor/socket 已删除，新 endpoint 路径不同、五个 retained/active loop 已建立，公开`GET_CONTEXT`仍可读回。这是同进程生命周期回归，不把它扩大为长期 RSS 结论。

**通用窗口转向。** `CjguiComposableUiWindowTurnScheduler`放在通用窗口模块而非样例中；`pumpWithExternal`至多执行16个完整 owner action，只在动作之间检查16 ms墙钟预算，剩余时间交给`window.pump`的 AppKit 有界事件等待。它不后台化领域/Native/UI，也不新增全局 tick。规则集和共享文档（有连接和无连接）都改为消费它，移除`window.pump(16)`后的第二个16 ms sleep。原生窗口控制器探针新增空闲转向：实际等待8–80 ms且不增加build/layout/native submission；这是生产事件路径的空闲等待证据，非物理输入或呈现延迟。

**V2 smoke 与范围。** 在该次 V2 smoke 中，`zsh build.sh`产物以`--duration-seconds 6 --sample-seconds 1 --recovery-seconds 3 --idle-seconds 2`运行，开始100 ms后采样：2个正常GET与2个125 ms碎片 peer 得到4,328个成功、1个连接关闭、92个有限慢 peer，p50/p95/max为1.256/12.307/14.543 ms；每个诊断样本 retained handles=5且active loops=5，数字FD=9。3 s恢复轮403个成功；无 peer 空闲数字FD=5，连接但不发帧的2 s读截止观察为5–6。新脚本还保留两种 idle context 的原始 sample；它没有重跑或替换600 s原始JSON。当时`shared_operation_core cjpm test --timeout-each 15s`为32/32，两个窗口消费者`cjpm build --skip-script`、native controller probe与root build均已通过；后续普通窗口与异步 Metal 的当前证据见本计划末尾交付节。物理IME、真实可见窗口混合输入/长列表/文档编辑、GPU时间/利用率及长期GUI CPU/RSS在此时仍未运行，不能声称阶段整体完成。


### 指导接续：正常窗口测量与渲染完成反馈

接受最新core32/32、队列修复、两应用使用通用TurnScheduler与V2口径修正的针对性报告；指导仅静态复核，没有重跑开发测试。当前继续同一大阶段，以正常窗口运行成本为主要交付，不再重复通信基线修补作为整轮终点。

- 先落实输入等待语义：native `pump_event`目前在检查`pendingInteractions`前调用`nextEventMatchingMask:untilDate:`；验证已有排队交互、无新系统事件时是否仍白等剩余16ms。增加普通生产入口回归，已有事件应立即交还owner，真正无事件才等待；保留FIFO、原投影身份、关闭和主线程约束。不要仅靠空闲wait探针声称输入延迟改善。
- `waitForWorkersToExit`到64ms即返回Unit，不能据此保证下次start绝不与旧loop重叠。区分已验证的代际隔离与尚未退出数量，修正注释/状态保证；验证延迟退出时旧state不能污染新state并且最终收敛。不得以无限join堵住窗口，也不因理论超时强行扩大公共生命周期接口。
- 交付一条正常规则集/文档产物可运行的窗口测量入口，临时数据、构建身份、预热和环境清楚，记录无连接/有连接空闲、重复GET、批量改动、文档与千项列表生产事件路径的CPU/RSS、build/layout/排版/提交、输入排队至处理与提交分布。窗口处于锁屏/遮挡时也可尝试正常进程及现有native路径，明确其可见性；不能把CUA不可用直接等同于无法测CPU或实现测量入口。若WindowServer/drawable确实阻止某实验，保留具体一次错误，继续其他实验；不强行解锁。
- 补可复用的异步渲染完成观测：目前普通提交不更新Metal完成，readback才推进；复用现有session代际和进度模型，在实际command buffer完成时安全记录成功/失败及可得GPU时间，观察可选且低成本，避免每帧同步readback或waitUntilCompleted。完成回调不得直接写领域/仓颉UI，关闭后迟到回调不得访问已销毁对象；区分submitted、GPU completed、overlay与人眼presented，不能把GPU完成宣称整体呈现。先按当前Metal SDK与源码能力核对接口，缺GPU时间支持就如实 unavailable。至少验证正常帧、失败/无drawable、连续更新和带in-flight关闭重开；应用消费同一通用观测而不是各自造计数器。
- 用采集到的数据完成至少一个有证据的主要瓶颈处理；若数据未显示需要优化，也应给真实成本与结论，不能为凑改动擅自重写文字引擎。完整物理IME和肉眼可见交互仍保留环境待验；不扩展样例业务。该交付同时推进渲染/GPU、资源调度和两应用消费，后续再按结果决定文字排版或包消费优先级。

历史避坑中等待/关闭尾部消息、盲目重绘与GPU异步生命周期在此落到真实入口。完整交付或实质升级主动回报；原目录Terra/xhigh及两次失败/K3规则不变。

### 2026-09-12 接续交付：普通窗口等待、完成观测与成本入口

**输入等待与关闭隔离。** `pump_event`先检查原生 FIFO，再在真正无 owner
事件时调用最多16ms的`nextEventMatchingMask`。窗口控制器探针先以普通
`CjguiComposableUiWindowTurnScheduler`排入选择事件取得红测（旧实现退出码
76、仍等待一个 idle interval），修复后同一入口及时把事件交给 controller，
且未增加 build/layout/submission。`waitForWorkersToExit`改为返回有界的
`Bool`观察，不再宣称64ms后旧 loop 必然退出；每个 start 的独立
`CjguiSharedOperationIoState`才是旧 loop 无法服务/污染新 endpoint 的正确性
边界。core 33/33含该观察的即时收敛回归。

**异步 Metal 完成。** 经当前 macOS 15.4 SDK 确认 `MTLCommandBuffer`有
`addCompletedHandler`、`GPUStartTime`与`GPUEndTime`。提交前分配 frame
identity，回调只捕获 token/generation/frame/status/timestamp 标量，再异步回
主线程重查 live session；generation 不匹配、destroyed 或已释放 slot 直接
丢弃。它只更新通用 window progress 的 completed/failed frame 和可得 GPU
duration（`-1`为不可得），不写领域、controller、仓颉 UI 或 overlay。测试
覆盖普通非readback frame完成、连续更新、in-flight close/reopen 后旧 generation
不污染新 session、以及实际 native view invalidated 时不伪造 command-buffer
完成。`submitted`、GPU completed、overlay draw 与 human presentation 仍分开，
后者保持`unavailable`。

**可复现窗口成本入口。** 规则集和文档正常 bundle 增加有限
`--measurement-duration-ms`，只决定本次 run 何时按正常 close/endpoint cleanup
退出。`runtime/cjgui/examples/window_perf_baseline.py`保存 bundle/source hash、
首帧预热说明、CPU/RSS/thread 样本与公开只读 window progress；它分别运行
文档无连接 idle、文档/规则连接 idle、规则/文档重复`GET_CONTEXT`。当前 1s、
0.2s smoke 结果写在`/tmp/cjgui-normal-window-perf-v1-smoke.json`：五个实际
bundle cycle都退出0并清理 endpoint；规则/文档重复 GET 为56/54次，读回 work
counts=1/1/1、GPU completed=1、failed=-1，GPU duration=2007/1734µs。CPU/RSS
仅是该短样本（文档无连接max 4.2%/104720KiB，连接 idle 31.3%/106336KiB，规则
连接 idle 27.5%/110656KiB），不作长期或P95结论。

**未运行而非完成。** V1 测量器不为了填指标注入 AppKit/IME 事件或修改领域，
故物理输入排队至处理/提交分布、批量改动、千项列表、长时稳定负载仍标为
`not_run`；锁屏/遮挡下正常进程、首帧与GPU回调已测，但没有人眼可见或物理
IME 验收。此轮可证的主瓶颈修复是已有 FIFO 被新系统事件等待拖慢，不以当前
短 CPU 样本擅自重写文字引擎。


### 指导复核：完成已授权的实际窗口负载，不以smoke结项

接受33/33、FIFO等待修复、普通Metal异步完成与session重开首帧的针对性报告。指导已抽查command buffer回调的代际匹配及标量更新，无每帧同步等待新增；没有重跑开发测试。当前1秒窗口smoke只是入口可用，不满足本阶段运行成本目标。

**先校准可比性。** window_perf_baseline.py目前无连接文档仍等待不存在的descriptor直到min(5秒,duration)，有连接则ready后即采样，导致两种idle的采样起点不一致；1秒4.2%与31.3%不能直接归因于连接。为所有场景提供真实窗口就绪信号与相同显式预热，计时从就绪/预热后统一开始；startup单列，不让预热耗尽有效测量窗口。至少60秒稳态idle对照并多轮采样，再判断连接开销。记录进程CPU采样含义及唤醒/worker等待热点；只有稳定证据支持时优化，避免凭1秒数字改架构。

**授权无缺口。** 批量修改、临时生成1001项规则、文档编辑/选区与正常生产事件测量，已在本阶段反复明确授权。当前测量器自行选择只读不是不运行这些项的理由。补公开业务动作创建临时fixture、版本/失败/读回、屏外100项批量与人的当前工作接续，记录布局/提交/排版与延迟、CPU/RSS；不要碰用户文件/剪贴板，也不要借增加无关样例功能绕开框架测量。

**集中完成实窗与稳定负载。** 正常规则集、文档消费均做菜单/对话框、键盘与列表导航、外部改动接续；Cua实际不可用才留具体未验。指导本次已能读取Finder AX及桌面截图，但loginwindow获取超时，不能凭此宣称已解锁或GUI验证通过。执行应重新检查自己应用的实际可操作状态，不沿用之前锁屏标签。重新锁定且无法操作时回报指导处理，继续独立测量，不获取或记录凭据。程序化生产事件与物理输入分开标识。

完成至少一段数分钟正常窗口混合负载与恢复，测量过程中包含真实批次和文档内容变化，GPU时间对应实际帧而非反复读取首帧；不要强制每帧readback。完成所需针对性修复后统一验证。只有真实环境阻塞的项可剩余；不可因为脚本暂未支持或跑了1秒就再次停止整个任务。K3累计与原目录执行规则保持不变。

### 本轮实际交付（2026-09-13）

**可比的正常窗口边界。** 两个应用均在已启动正常 native window、首帧提交后才输出
`WINDOW_READY`；相同 scheduler 再跑5秒显式预热，应用输出`MEASUREMENT_START`后 runner
才采样。两轮各60秒的文档无连接、文档连接和规则连接 idle 共六个 cycle 都退出0，
每个有60–61个有效样本。文档无连接 CPU 为0.5–1.9%，文档连接为0.8–2.5%，规则连接
为0.8–2.5%。新进程 RSS/线程基线存在差异，故原始轮次保留而未把它们称为泄漏收敛。

**授权业务和数分钟恢复。** 最终 paced 的两个180秒正常窗口均退出0。规则集创建
1,001个进程内临时规则，100项目标批量启用达到版本1002，旧版本请求返回冲突，定向
读回为启用，并读到更晚的真实 Metal completed frame；文档在内存中完成替换、旧版本
冲突和 exact range 读回，并读到更晚 completed frame。业务完成后仍在同一 process
采样，未把后续启动称作恢复；不打开或写入用户文件。

**压力归因与不越界的修复。** 初版 runner 未持续排空 child stderr。千项 mutation
产生的 native 日志填满 pipe 后，主线程阻在`writev`内的一次`refreshIfNeeded`，
180秒边界无法再检查，端点随后只报`server_busy`。128 KiB、无换行 stderr 的红测稳定
复现5秒超时；runner 现同时排空 stdout/stderr、仅保留 stderr 尾64 KiB，红测和三个
实际 bundle 回归通过。它不改变业务、窗口或 native 行为。

无节流 full `GET_CONTEXT` 的较早180秒高压 JSON 保留，不能和正常恢复混淆。最终
reader 每次成功请求后明确等待100ms：规则集有1,081个成功快照、p95 145.653ms，业务后
CPU 26.3–91.3%；同一1,001项 fixture、无 reader 的静默恢复是0.9–30.6%、末值3.1%。
60秒 profile 说明 owner 的主要读取成本为`dispatchContextRead → snapshotPayload →
contextSnapshot`、UTF-8 hex 编码和每次构造当前 window projection；它不是循环重绘、
每帧 readback 或同步 Metal completion。快照包含实时进度，当前未以缓存制造第二份
真相；若要把全量快照从压力路径改为常规订阅，应单独选择/验证变化流契约。paced 文档
读取1,479次、p95 24.643ms、CPU 1.0–3.9%。

**实窗复核。** 解锁后实际文档窗口接收公开改动，再可由本地系统原生粘贴继续编辑；
规则编辑对话框显示期间，公开批量改变可见，随后本地草稿可继续编辑，子菜单 Escape
只关闭子层。`typeText`未产生已验证写入，故这些不是物理键盘或中文 IME 验收；GPU
completed/overlay 也不等同于人眼呈现。
