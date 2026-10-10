# 20261006 返工证据索引（输入来源/泵/线程/工具门）

本目录由接续执行者在复核（windows-input-pump-review-20261006）之后立即建立。
用于登记 accept9/accept10 相关来宾原件、二进制身份与缺失项；不覆盖任何旧 RED。

## 一、已归档原件（来自来宾，2026-10-06 09:47 抓取）

| 文件 | sha256 | 说明 |
| --- | --- | --- |
| editor-stdout.log | 346a0d9cce9944bf79bd1ee752283b3bef154cb8365e4f3562aaf65afc6adca7 | **accept10** 应用 stdout（17920B；accept9 的同路径日志已被 accept10 覆盖，见缺失登记） |
| editor-stderr.log | e3b0c44298fc1c149afb…（空文件） | accept10 stderr，空 |
| click-probe.txt | e3b0c44298fc1c149afb…（空） | accept10 探针请求文件（已被单次语义清空） |
| click-probe.txt.out | b1569a38b9f86ee5d4fdd9ed6a9232eac55c6952c687871d28b231ed48a98946 | accept10 最后一次探针结果（28B，`CLICK_RESULT 114 at=2228,48`） |
| renderer-thread.log | 74111dad40c80a2abf27bf18457d904ff0ebe78d110022d95ab4da97f5816665 | 泵线程追踪（28B，`pump tid=14044 owner=14044`，accept10 全程未变化） |
| renderer-qorr.log | f25ae10003547bf785ab9e4e9f132d2864007fab7e69e2103b94d43207f21644 | qorr 推送日志（933B，含 accept9/accept10 的 M/K push 记录） |
| accept10-01-opened.png | 170d659f43049cbf15a9…（全量见下） | accept10 启动截图（771121B） |
| accept9-01-opened.png | 5d8f2f7a52c45cf5f349… | accept9 启动截图（771139B） |

## 二、二进制身份

| 产物 | 身份 | 备注 |
| --- | --- | --- |
| accept10 的 main.exe | sha256=d0ab2c623f9d9505add88c4d5ec4b9ccc3a2bcfed9565609a0204c96c21df52f, len=22665728 | 渲染器源码 sha=6bb6dc61e51453292bac1e70eb6047940079221df930cd44fdaa86e362b81c16（含裸 ALT 消费+线程追踪；**含无条件重盖**） |
| accept9 的 main.exe | sha256=374ffa15ce07a834ae1db7911bbecd437e6ce7aa1043f166c0503f75bc428783, len=22665216 | 渲染器源码 sha=f4c51c440e383d887bcb2a4f5e448f259f7d6b9ed5527d47b0f24c7baeb62d19（裸 ALT 消费，未含线程追踪） |
| 应用位码（两轮相同） | build-bc-captured.bc sha=5f3c10f8aa9b4ab94464e111402e90ca50d391d548d1b3a1a4d2e4f60b272cb6 | relay4 输入（27,937,788B）；obj sha=9b32ddac0004f02c4ebe5379ba665b681645a00ccd8ea192d83bf034c52b2605 |

## 三、缺失登记（不以新轮倒证旧轮）

1. **accept9 的 editor-stdout.log 完整原件缺失**：accept9 与 accept10 复用同一 `C:\cjgui-windows-w1\accept-run\` 目录，accept10 启动时覆盖了 accept9 的日志。已抓取的关键片段（首次 `not_main_thread` 行号 141/42670、turn 280→290 的 status 0→1 转变、`CJGUISCENE_REJECTED reason=not_main_thread`）保留在本轮对话记录中，非完整原件，不当作复现结论。
2. **accept9 的 renderer-thread.log 缺失**：该轮构建（f4c51c44）尚未含线程追踪代码。
3. accept9 的 qorr/探针文件同样被 accept10 覆盖；qorr 日志中 accept9 的 M/K push 行尚存（933B 内含两轮记录）。

## 四、复核已确认的返工项（对应任务文档表）

- 输入来源重盖（present 后 kind 28/51/52/33 无条件改 projectionVersion）→ 删除，保留真实来源。
- 安装 pending 下 IME RESULTSTR 被消费无事务（replay 反例：`handled=1/freed=1/update=0/terminal=0`）→ 有界交接，不静默丢。
- `pump_windows_messages` FIFO 空且 remaining==0 时未 PeekMessageW → 零超时仍须有界服务就绪系统消息。
- 线程失配证据不足（泵 tid 打印在 guard 成功之后）→ 首个拒绝点记录 API/token/tid/状态。
- relay 仅按文件名注入（admission 反例：不同 BC 仍注入）→ 前置内容哈希门 + 捕获失败非零。
- 验收假阳性（`CLICK_RESULT 107 missing` 匹配通过；250ms 慢打；替换仅查旧 token 消失）→ 修工具门，最终 SendInput+全文 oracle。

（复核反例脚本与结果原件在 `../guidance-review-20261006/`，本目录不复制。）

## 五、2026-10-06 晚间轮验证快照（本地可验证项）

- Astra 咨询已回：`consultations/input-handoff-thread-affinity/answer.md`（28497B，exit=0）。裁决：输入走生产侧来源保留+共享 owner 验证接续+安装回执放行；线程走 Windows 原生专用 UI dispatcher + 仓颉单一逻辑 owner；`projectionVersion` 保留捕获时 scene；`char utf8[8]` 未终止 OOB 需修；`cjProcessorNum=1` 仅诊断对照；re-home 不采用。
- pread 双向实证已归档（见 RED-GREEN §2）：修复前 `pos 8→4 / read=4567 → POSITION_BROKEN`，修复后 `pos 0→0 / read=0123 → POSITION_PRESERVED`；工作树与上架包哈希一致（f7ed04b4）。
- 渲染器本轮定稿（27f819bc）：创建 Attach + 每次 pump 懒 Attach（幂等）+ 销毁 Detach 各一份；`push_event_payload_internal` 不改写版本（无 present 期重盖）；kind51 链/非链分别用捕获 scene / 首笔 pending scene；composition 用 compositionSceneVersion；claim→intent 携带 nonce/generation/windowToken/binding/context/mirror/ownerVersion/installedSceneVersion + seq/prevSeq/observedAck + pre/replacement/post；`char utf8[9]` 终止修复；能力拆分（InstalledRange 保持 macOS-only，SourceRange 开 macOS||Windows，SelectionTransfer 保持 macOS-only）。
- 调试残留已清：`CJGUI_DBG*` 零残留；qorr/nav/heartbeat 写盘已删；仅剩环境变量门控探针 4 处 fopen（默认关闭）；`git diff --check` 干净。
- 上架包 a3343b67（含懒 Attach，三文件 CLEAN+LAZY_OK）；relay obj 四代齐（5f3c/f59f/76430b40/0297fa59）+ snapshot；来宾 SDK llc 已核原版（1ea68362…）。
- 阻塞：来宾 `Pharos Mark Windows Source` 目录已不在，无 main.exe，整链 accept 与固定门重跑需重新上架源包+构建+（若 BC 漂移）重冻。本轮未新跑 guest 验收，不以本地验证冒充整链通过。

## 六、验收毒素二分：agent 通道流量无罪（2026-10-06 晚间，AGENT_CLEAN）

- 同一启动内：STAGE1 缝点击切到 source（`PHAROS_MODE visual=false`）→ agent discover（400B）/snapshot（v1）/read（103B）→ STAGE2 缝点击切回 visual（`PHAROS_MODE visual=true`）。
- 结论：agent 通道流量不毒化后续按压；accept 必挂另有原因（待查：截图、前台 ALT、中文夹具、settle 等待）。
- 探针：`agentbisect2.ps1`（基线+agent+再点，两阶段期望各一）。

## 七、A/B 调用线程反例 RED（2026-10-06 晚间，dispatcher 缺口定锤）

- harness：`renderer-contract/dispatcher_ab_thread_probe.c`（主线程 A 建会话+pump，工作线程 B 再 pump 同 session，读 `debug_last_pump_tid`）。
- 结果：`window_tid=19004`，`pumpA_caller=11292 pumpA_exec=11292`，`pumpB_caller=10804 pumpB_exec=10804`，`verdict=CALLER_THREAD_EXEC`（exit=1）。
- 结论：当前实现直接在调用线程执行会话逻辑；AttachThreadInput 只解决焦点/输入队列可见性，不解决执行归属。完整 dispatcher（命令封送到固定 UI 线程）必须做。
- 观测点：renderer `lastPumpTid` 字段＋入口记录＋`debug_last_pump_tid` 导出（harness 用 extern 声明，未改公共头）。

## 八、A/B 调用线程反例复跑 RED（2026-10-06 晚间第二轮，dispatcher 缺口再确认）

- harness：`renderer-contract/dispatcher_ab_thread_probe.c`（98805ae7），观测点 renderer `lastPumpTid`＋`debug_last_pump_tid`（961f7d5d）。
- 结果：`window_tid=10832`，`pumpA_caller=16788 pumpA_exec=16788`，`pumpB_caller=14888 pumpB_exec=14888`，`verdict=CALLER_THREAD_EXEC`（exit=1）。
- 与首轮（19004/11292/10804）一致：执行 tid 恒等于调用 tid，与 UI 线程无关。AttachThreadInput 不解决执行归属，完整 dispatcher 必须做。

## 九、完整 UI dispatcher phase-1 落地并转绿（2026-10-06 晚间）

- 机制：per-session 命令环（64 槽，调用者栈指针，INFINITE 等待＋UI 有界切片）；
  C ABI pump/destroy 封送到 UI（泵）线程执行；find/create/destroy/计数走
  全局表锁；destroy 拆分为 UI 侧 phase-A（retiring＋取消排队＋IME 分离）
  与调用侧 phase-B（join＋资源释放＋槽位回收）；pump 等待改 MsgWait
  （rawWake＋cmdWake＋QS_ALLINPUT）＋嵌套非 pump/destroy 搬运＋停止检查；
  UI 环等待集加 cmdWakeEvent 并每轮搬运；UI 线程内重入直接执行，UI 线程
  调 destroy 具名拒绝（防自 join 死锁）；pre-ready 无 UI 线程时走旧直连路径。
- A/B 反例转绿：`window_tid=12380`，`pumpA_exec=12380 pumpB_exec=12380`，
  `verdict=FIXED_UI_THREAD`（exit=0）。此前两轮 RED（CALLER_THREAD_EXEC）已归档。
- 回归：零超时公平 `gotClose=1`；跨线程泵 `got42=1`；全部 exit=0。
- 关闭探针：`destroy1 status=0 workerPumps=30 workerBad=0`，worker 正常 join；
  `pump2_after OK`（另一窗存活）；`pump1_after_destroy=11`；
  `destroy1_again=11`；`verdict=CLOSE_ISOLATED`（exit=0）。
- 渲染器工作树哈希：`e1f10c9c…`→`b62e4ee1…`（dispatcher 落地）。
- 残留（phase-2）：其余约 115 个导出函数仍驱动线程直调（ Neuroscience 批次
  迁移）；`form_event_text`/`pumped_pointer_geometry` 读面租约未加固；
  调用侧无界等待改有界看门狗；以上均不影响本包已验行为。

## 十、输入交接 harness 双绿（2026-10-06 晚间，renderer c11084f0）

- 交接 harness `renderer-contract/input_handoff_probe.c`：
  `HANDOFF_CONTRACT PASS provisional outcome stale_reject order_BA`（exit=0）。
  覆盖：安装成功门保持＋provisional／outcome=INSTALLED；门内字符不交易；
  owner 经门 API 结算后 outcome=CONFIRMED、输入恢复；旧票安装拒绝；
  建链后 A→Left→B 经 restore 确认重放得 BA（屏障缺失则为 AB，即红）。
- 既有 install contract（已按 provisional 更新期望）：
  `WINDOWS_INSTALL_CONTRACT PASS gate=3 install=0:5 first=X stale_refused
  recover_refused continue=Y`（exit=0）。门控三项＋原子安装＋误 epoch
  拒绝＋首笔精确替换＋非活跃恢复拒绝＋续写，全部保持。
- 同轮 dispatcher 回归（A/B 转绿、关闭隔离、零超时公平、跨线程泵）已在
  §九确认；本轮 renderer 含序号幻影修复、provisional、修饰键冻结、导航屏障。

## 十一、完整 UI dispatcher phase-2 落地并转绿（2026-10-07，renderer 6c0ee90b）

- 机制：堆信封通用 `windows_dispatch_sync`（token 路由，会话查找/代次/退役一律 UI
  线程；调用者栈返回后永不被引用；30s 有界等待；未开始超时原子取消
  `COMMAND_TIMEOUT`，已开始超时保留 `COMMAND_IN_FLIGHT`＋`reap_orphaned_command`
  取回，禁重发副作用）；重入快路（UI 线程直接执行）；STOP 命令替代
  PostThreadMessage/PostQuitMessage 跨线程投递；destroy 图形释放移入 UI 线程，
  调用侧只 join＋收内存/槽位并清 hold 环；form_event_text 租约双槽；
  pump 孤儿事件经 hold 环下次 pump 即时返回。
- 迁移：约 90 个导出会话 API 全部封送（present/focus/安装/恢复/claim/读面/探针/
  场景构建/共享/菜单/传输/png/诊断），C ABI 不变；纯时钟、纯字节算法、
  会话计数、create（建 UI 线程本身）按 Astra 表直调；`owner_thread_cpu_ns`
  仍计量调用线程（语义未变，如实保留）。
- 反例（guest MinGW 直编真实 renderer，`windows-dispatcher-phase2.ps1`）：
  `PHASE2_FIXED_UI`（present/focus/install/node_rect 跨 A/B 线程 exec==hwndTid；
  40s 睡眠命令 IN_FLIGHT＋reap 取回＋无二次执行；destroy 执行 tid==hwndTid；
  毁后 pump 得 11）；A/B `FIXED_UI_THREAD`；关闭 `CLOSE_ISOLATED`；零超时
  `gotClose=1`；跨线程泵 `got42=1`；`WINDOWS_INSTALL_CONTRACT PASS`；
  `HANDOFF_CONTRACT PASS`。全绿复跑通过；中途一次 phase2 单发失败（后加 PID
  窗口定位＋reap 窗口放宽，未再现）。
- 修复中抓到的真实缺陷：空载荷深拷贝把有效空串归一成 NULL（arm 34）；
  form_text wrapper 漏 `ctx->token`（读到 token 0 会话空文本）；另顺手修正两处
  新写错配（config_xfer/xfer_copy 调错 proc），均在转绿前消除。
- 残留：Cangjie 侧逻辑 owner 串行纪律仍由既有 host turn 保证（封送不替代）；
  owner 已提交后 ACK 失败只重试 ACK、导航屏障完整交接按既有 handoff 契约，
  明确 owner 结局的 `finish_source_install` 入口与门内待决输入保全是下一项。

## 十二、输入保全与明确结算落地（2026-10-07，renderer 4923039c）

- 门内待决队列（32 项/256KiB，原始目标·请求·来源·完整载荷·修饰·重复·组字 id/相位）；
  字符/导航/组合开始三处门丢字改为延期并返回已接管；确认后按序兑现并核对
  binding/request，不匹配进恢复；取消/取代/冲突/关闭各具名结局，待决与导航
  持留进 4 深恢复环（弹出式读取）；满载首超载荷具名背压保留。
- `finish_source_install(request,outcome,receipt)` 私有入口：CONFIRMED 须
  provisional＋票据匹配，否则拒绝并保留待办；旧票/无门拒绝且不碰现门；
  destroy 以 CLOSED 结算。`install_recovery` 弹出读取；
  `source_install_receipt` 读票据。仓颉 `finishSelectionRestore` 按
  reason→outcome 映射并凭票结算，失败打 `SETTLE_RETAINED` 行且不再 Bool 清门；
  非 Windows 路径原样保留（Windows 门控谓词＋foreign 声明）。
- IME 产生点冻结：WndProc 当场拥有 RESULTSTR/COMPSTR/光标（16 槽环，超限具名
  miss），raw 记录带槽位，消费只读冻结字节；门内组字整体延期（kind 2/3），
  兑现时重建组合会话并核对 compositionId/binding。
- 反例（`input_settlement_probe.c`，7 项全绿）：门内 Q 拒绝保留＋取消恢复；
  已安装后取消零放行；门内 A→Left→B 可恢复；provisional 下确认按序 A、B；
  33 项满载首超具名；换绑旧待决不误投；旧票拒绝；失败 ACK 不消费、重试恰一次。
  既有 install/handoff/phase2 全回归绿。
- 未在探针覆盖、留产品级验证：延迟消费真实 RESULTSTR/COMPSTR/END（需系统 IME，
  进第六节组合门）；仓颉映射的编译正确性（进冻结构建的 cjpm/relay 链验证）。

## 十三、r3 新 run 隔离与 prepare-source 转绿（2026-10-07）

- 基线：`r3-frozen-baseline.json`（renderer `4923039c`、window `bfe71f93`、
  session `1e9d2952`、main `e57b8078`）；冻结权威为单文件 manifest，
  archive hash 漂移系 zip mtime 所致，不作为门。
- `prepare-source.ps1` 已支持 `PHAROS_SOURCE_ZIP`/`PHAROS_SOURCE_SHA256`
  环境覆盖（默认旧值，旧批次行为不变）。
- relay-build 已加固：全局互斥独占、llc/llc-real 双哈希准入、SDK 外原版备份、
  构建 try/finally 立即恢复＋外层 finally 再核＋下次拿锁自愈残留。
- r3 wrapper/capshim 变体（`runs\r3` 路径）已在 guest MinGW 编译通过：
  wrapper `9e49a683…9614d1f`、capshim `a4922d82…b2c739`，见
  `r3-relay-material.json`。
- guest prepare-source（`runs\r3`）：`source_and_native_ready`，Exit 0；
  renderer/wic/posix_compat 编译＋归档＋manifest res＋app support 全绿。
  新 renderer（含 dispatcher phase-2 与结算机制）在 MinGW 下编译通过。

## 十四、posted-click 定层 diluted：kill 点在 UP 的 frozen-target 校验（2026-10-07）

- 探针链（同一最终二进制、默认窗口尺寸）：`NODE_RECT 114` 可测；
  `HITTEST` 命中 node 114（pressable button，interactive，无位移）；
  `DOWN_NODE` 单发 → `press=1`、`pushTotal=2(45,31)`，native 分发正常；
  `UP_NODE` 只推单个 `47 PRESS_CANCEL`，`press=0`，无模式翻转。
- push 计数排除中途 MOVE/FFI-cancel/resize（各会多一次 push）；
  raw 环全程无 `512 MOUSEMOVE`；`downMark=0/upMark=2` 与总数自洽。
- UP-decision 记录：`sceneDown=1/sceneUp=2`（DOWN→UP 之间场景重发，
  系框架消费 PRESS_BEGIN 后的 pressed 重绘）；`upNode=0/upFlags=0`
  说明 UP 在 `windows_current_mouse_target` 校验处提前返回
  （frozen 身份：按 id 查找＋约 25 项几何/取值/lease 比对＋坐标纪元），
  未走到 hit-test，更无 `PRESS_END`/`ACTIVATE`。
- 结论：native 侧健康到分发为止；kill 点是 frozen-target 校验与
  中间重发的严格性冲突。exact 失配字段（lease/value/位移）未定，
  需另一次 native 探针或框架日志；修复方向（native UP 容忍重绘 /
  框架 lease 连续性 / 接受为已知限制）待用户裁决，不在本轮改动。
- 构建证据：zip `f076704f`（renderer `4c0383d9`，110 个 `.cj` 与 relay
  已验证集逐字节一致，window.cj+main.cj 钉在 BC 版本）；relay
  `RELAY_OK` exe `1ee4a2ad…`（23387136B，link 后 AV 沿用已验证模式，
  mouse-diag 活体通过）；基线
  `r3-frozen-baseline-20261007-discriminator.json`；llc 已恢复原版。

## 十五、r4 按压连续性与输入责任收口轮（2026-10-07，renderer `ad714b1c…`）

- 按压：UP 门控诊断一次补齐 stage/首个拒绝字段/前后值（DOWN 重置），门控分
  press/文本两档（press 跳 lease＋值，Boolean 保值；文本仍严格），UP 门控
  失败同步记 fresh-hit（`upNode=0/upFlags=0` 两义性解除），去掉了
  `mouseProjectionVersion` 查询副作用改写。MOUSE_DIAG 末尾追加
  `upStage/upReject/upOld/upNew/upFresh`（旧正则按子串匹配不受影响）。
- dispatcher：完成端锁内重读 orphaned 再决定通知/移交；超时遇已完成取成功
  认领（done＋未 orphaned）或转 IN_FLIGHT（已入 hold）；phase-B 有界等
  cmdWaiters 归零后再删锁/清零（关闭×超时 UAF 关口）。
- 输入：恢复槽按完整记录（kind/修饰/重复/组字/相位/光标/额外载荷）转移；
  `stash_recovery` 返回可解释结局，失败保留原件；defer/导航持留总预算含
  恢复积压，满载/分配失败不再假成功；IME 冻结失败保留槽位，pump 顺带重驱；
  `nav_barrier_hold_char` 保留修饰符。
- 结算：新增 `source_install_gate_state` 查询；`finishSelectionRestore`
  仅在 native 明确受理（OK）、会话槽已释放（INVALID）或门已无本请求
  （STALE＋gate-state 确认）时清 pending，其余一律保留重试（只补结算）。
  `install_recovery` 取回同步加宽（旧参传 NULL 仍兼容）。
- 探针（来宾 MinGW 直编真实 renderer，`C:\cjgui-windows-r4` 隔离运行，
  交互会话计划任务执行）：既有 7 项回归全绿；settlement 新增 T10 门状态、
  T11 整记录回读；新增 `press_continuity_probe` P1 重绘激活＋P2–P7 退役/
  严格反例。整轮 `R4_ALL_GREEN`，见 `r4-probe-round-20261007.log`。
- 宿主 `cjpm build --skip-script` 通过（仅既有警告）。Windows 分支的完整
  类型检查随冻结构建在来宾 cjc 链验证。


### 2026-10-08 W r5 实施接续（进行中）

以 r4 的 120 文件完整冻结清单为基线，仅纳入 W 的恢复接缝及新增共同接收契约；r5 为 121 文件。未吸收 live E/H 整树；正典源码里的并行改动保留，未 stage/commit/push。新恢复契约将完整载荷交产品持久化 sidecar、字节读回后 ACK，失败留在原槽，不向当前正文重放。共享 `cjpm build --skip-script` exit 0。

已保留 F1 发布/通知 UAF 的 RED、GREEN 与撤回负控，F2/F3/D/关闭接收的真实 native 反例及 GREEN；九个受影响探针按分批原件的并集通过（并非同一运行全九项）。P8 已运行并检查节点、场景和精确 byte 5 两端事件各一次。新 worker 先作业绑定再开启动门；正负控检查继承管道的后代责任，新 worker SHA `923e6edd05ba307d037bbc59bf377aa1398501c192799b1d89b33a055a163ed4`。当前 worker 又运行三批各四任务，六个继承标准管道的自有后代均由对应作业回收，资源原数见本轮 runner JSON。

r5 仓颉输入捕获 BC `ac9703ce73658bad981c1fbe8efe99dc1f49665c772bd10da0beb27185d03052`，Mac 同 SDK/目标参数 obj `64bcfc15abc4226d76ada3ef53aa249188474c342730c8b0fde17abaed3430e0`；来宾正式链接 exit 0，EXE `a282a219f964ab892bfa82817e811e91787bd2c7fbdd5721b9ecefcaa57a21fb`。捕获时驱动真实 AV 与预期 capshim 终止分别保留；最终链接并未沿用其非零结果。SDK 两份 llc 原 SHA 已恢复。r5b 后续只修改 private native（PNG/device/失败诊断），仓颉输入、ABI 与 BC 不变，正在同哈希准入后重链接。

普通 PNG 节点原来确实返回 unsupported，已留下正常 prepare/场景/真实像素 RED；新增 WIC 有界文件解码、16 槽缓存、CPU/GPU 各 32MiB 预算及现有 flight 租约中的图片引用，坏图与超尺寸拒绝保旧。设备恢复探针经同一 Present 失败分支注入受控 RESET HRESULT，真实释放并重建 D3D/交换链/纹理，窗口身份保留，失败帧未 accepted，PNG 像素读回成功；这不是物理设备故障证明。产品 PNG/恢复的正常消费仍未验。

正常产品首轮 `097ebf14a7c140f1ae048785f0794d49` 验证默认逻辑 1100×780（实际 client 2200×1560，DPI 192）、中文/空格文件、真实 Markdown 与单次 SendInput 模式按钮；切源码后 `CJGUI_SCENE_REJECTED reason=internal_error`，accepted 无正文 107，链停在该处。正对新场景失败层做诊断，不加点击、放大或慢打救绿。完整主链、Unicode/系统 IME、滚动/resize/焦点、20 笔重叠请求、idle、五轮 editor close/reopen、最终可启动交付仍未完成，不将探针/构建成绩写成整包完成。

参考复用：本地 GPUI Windows `dispatcher.rs` 的异步 runnable 所有权仅用于对照线程责任；CJGUI 同步结果/超时 hold 仍按自身命令信封收口。`text_system.rs::layout_line` 对照几何缓存输入；颜色纹理与来源授权保持各自门。`directx_renderer.rs::resize`（先解绑目标再 ResizeBuffers）及 `recreate_resources` 对照设备代次重建；CJGUI 在同一 HWND 保留 owner/accepted 语义，丢弃 GPU 代次。框架 Mac `CjguiPrepareComposableImageResourceOnMain` 对照 path/id/version 身份、已绑定纹理保留；Windows 用现有 WIC 和有限同步缓存，不引入任何外部框架依赖。

原件：`artifacts/windows-pharos-20261005/evidence/20261008-r5/`；当前常驻 runner `ce74c33878ce4bcb9942920ec5460ede`（旧 worker `fc856ac678f448d286a6635b1856efa4` 已 BYE/socket closed）。F1/F2/F3/D 旧 RED、harness 设置错误与真实失败原件均保留。


W r5 当前 D 升级（2026-10-08）：正常消费首次失败已归因到候选复用契约：真实 native `r5-reuse-red` nonce f9efa3b34d3b4f20820d034cba3b5749，abc+[0,3) accepted后，configure2＋相同runs＋geometry、跳过未变正文，Present=33、candidateRunsPending=1、accepted仍1。正常产品 r5c e46a1e829…/PID6932源模式缺107；开启frame trace的新实例 PID及完整日志见 accept-run-fdeecd0d80454176bf31d89b0808c28d，raw status33经现有状态名兜底显示internal_error。此前native INTERNAL_ERROR诊断为空符合该码，并非native错误静默。Pi deepseek-flash只读指出未映射状态路径，实际根因由生产反例验证。新配对门修复误拒了共同窗口有意复用的节点，计入本轮公共契约首次正常消费失败，按AGENTS提前升级，未继续猜改。已向用户提交有限方案：在Present边界将pending声明和保留的同一候选正文/绑定校验准备，再维持runs先于新body、真实越界保旧、相同几何lease保持的三种反例；等待指导裁决，只暂停D依赖。PNG像素在正常产品窗口已可见；首两次采样harness分别把Shot日志误当路径、把前沿click点误当中心，原件保留，正在独立验证正确中心采样/idle/五次正常关闭，不把这两次称后端修复失败。


W r5 独立消费与收口补证（2026-10-08，D 裁决仍待回复）：r5c EXE `e46a1e829a5cdf542fac722b7cb75300a90767bbe286bed68089d96aa0c6b753` 的正常 PNG 及五轮正常关闭最终运行 nonce `577cbcba56c742159b98ed8cc50f59cc` exit 0。普通产品共同图片节点实际屏幕采样：左 A255/R255/G0/B0、右 A255/R0/G255/B0；这不是专用图片应用或硬编码 shader。聚焦预览静止 10s：进程 CPU 0.1875s、handles 304→304、threads 12、RSS 84,054,016→71,106,560 bytes、frame 始终1。它覆盖聚焦只读预览静止，尚不能替代失焦静止和源码 caret 闪烁门。五个新 PID 3344/16644/11372/11436/8036 均由系统 Alt+F4 四事件正常关闭，预持有内核 process handle 读回 ExitCode=0；未覆盖编辑保存重开。旧 ExitCode 空值失败是 PowerShell process 对象读法问题，原件保留。

实际模块核验 nonce `52648ba0ac9b4aa1b0295837ddaaee10`：PID19200 主 EXE 及非系统 `libcangjie-runtime.dll`（ca65f2b8…）/`libboundscheck.dll`（07b33dd3…）均 PE machine0x8664；完整路径、bytes、SHA 位于本轮 `r5c-dll/dll-identity.json`。两份 SDK llc SHA 均1ea68362…，正常关闭内核退出0。该身份是已构建的r5c，不拿它证明随后native改动。

又发现并补齐两条原范围内的遗漏支路。`ResizeBuffers` 的受控 COM 调用错误 RED nonce `c93fe00bce8b471bafc862d7069c5c6e`：RESET只返回internal_error、没有恢复责任。修复让其进入既有graphicsRecoveryPending，物理resize事件仍返回，消息泵同UI线程重建后才把事件交回应用；GREEN `9136bacfea654f318f182e752876ae28` 验实际代次2/3、同HWND、旧accepted保持、真实纹理重建、后续正文准备/呈现。它是受控HRESULT，正常产品resize/device后续编辑仍待D门。无存活pump的public destroy旧分支绕过接收ACK，RED `05fd39cccd9f4b2ebe50cbb4a7df2cb6`；接回同一个destroy_proc预检/资源释放后，GREEN `0e8d2fc8c2354ceeb17fbc577f91ec08` 保留完整Q/binding9/request100，精确ACK后才退役，普通关闭接收/重复ACK/live waiter一并通过。它覆盖已冻结恢复记录，未据此宣称所有半代理项/待后继组合态的关闭恢复已验证。

r5d完整121项从r5c复制，仅native实现变化；manifest SHA83a41e447dcf66b9c26562173f560bef4b21ef8c2de01c218c34620109b6ce67，完整源ZIP SHAbe18a71487b4d348a0730199027aa689609b6d00dc18fa3db66a9911efe3b0a1，native ddfa1f49…。Cangjie/foreign ABI/flags与已冻结BC/obj不变，正在正式准入重链接。写作验收脚本另修正真实Markdown code fence、初始owner与预冻文件完整字节一致、两次正常关闭内核退出0、必需日志上传失败必须非零；finally失败负控 nonce `0561023318194efb828d2a06a15bd21b` 即主体exit0也由worker读回exit1。主链尚未重新运行，因为D方案未获指导回复。


W r5d 正式链接与容量接线（2026-10-08）：nonce `7dc7c1cb09d144e9917a0e0e9480378c` 正式build exit0，native archive d734cfbbf1b717fef045ce186ddb2b37c349b39e1cd57496aeec4fc5cf7afa22，EXE e72ea9ca4fe1ecb3e6c3047e956913f8aa0305ccd484ca7d843f28e5b3bb2ba1；仍是同r5 BC/obj，SDK恢复。独立公开拒绝门 nonce `3a51e583f27643d3a4a2d725d3913172` 实际PID20100/owner v1/258016bytes：wrong-version→version_conflict、越界→invalid_range、UTF8内部→not_utf8_boundary，均全文/版本保旧；容量负控50,000-byte有效追加却被接受成v2/308016bytes。这是产品未启用已有owner.configureContentCapacity的真实RED，不归因D。

Windows产品现已补有限配置：正常controller采用/换绑和额外CLI文档服务配置262144bytes，初始/额外打开以同一捕获的session字节长度拒绝超范围，失败显示具名notice且不截断文件；最近文档拒绝时保留原活动owner和恢复提示。shared DocumentSession本身的默认/签名不变，非Windows私有helper为空/允许，未把共享编辑器永久限到256KiB。W冻结的同步journal重放前先给捕获session配置同一准入，不让历史绕过结果长度。live E已改为异步恢复，正典只在它已有blockPendingRecovery接缝前配置，未将旧同步流程覆盖回去；本轮W不吸收该E变更，canonical异步恢复与Windows容量组合尚未作为W消费证据。

r5e 捕获nonce `73401a749305451f946a388fbb4ec61f`，BC c01f7f18…；原始driver日志nonce `384eb6cce2394efca0e26a839aa55caa`明确为capshim exit94（不是这次真实AV），该输入后来补充了pre-journal接线，故不用于最终obj。r5f完整121项，main SHA49cf75a8a36f0ba57880a9c635528d56986bd676280ad16d190cb03acf174b17，manifest SHAfbc00c295189d2a9ebcd51a81635341a93bcb740f018061b09a811f578ae76a1，源ZIP SHAe9e0795a176a67b18ef8f87e377c65b1fb80b208fa703815377e5b2d9b5cf469。正在重新捕获/生成匹配obj；没有拿r5旧obj覆盖新的Cangjie输入。容量GREEN与超范围打开/原固定门待实际r5f运行。D配对裁决仍待回复，未改该门或重跑依赖它的主链。


<a id="windows-r5f-handoff-20261008"></a>

### 2026-10-08 W r5f 汇合原件与 D 待裁决（本节为最新状态，整包未完成）

本轮通用机制改动在原 A–F 范围：dispatcher 完成/通知/回收同锁发布；输入与导航整条载荷成功转移才出队，冻结 IME 的提交/后继更新分别结算；恢复记录由完整公开读取、产品 sidecar 持久化读回后 ACK；排版与 GPU lease 复用保留。Windows 增加有界 WIC PNG/D3D11 真实采样、同 HWND 设备代次恢复，以及 ResizeBuffers 设备丢失到消息泵重建的交接；无 live-pump 关闭复用公共关闭责任路径。产品仅在 Windows 正常写作入口配置已有 owner 的 262144-byte 上限、打开拒绝保留原 owner/文件。恢复/PNG/关闭尚未全部被正常编辑链消费，不能统称责任全部收口。正典 E 新异步恢复流程已保留；本包冻结的旧恢复流程在日志重放前配置容量，不能用本包证明 E 新异步恢复与 Windows 容量的组合已验。

r5f 正式混合构建 nonce `894b26aa5f4a495a80f24e038708cf97` exit 0。121 项源清单逐项复核零失配。以下是同一冻结关系：

| 原件 | SHA256 |
| --- | --- |
| 完整源 ZIP | `e9e0795a176a67b18ef8f87e377c65b1fb80b208fa703815377e5b2d9b5cf469` |
| 121 项源 manifest | `fbc00c295189d2a9ebcd51a81635341a93bcb740f018061b09a811f578ae76a1` |
| app main | `49cf75a8a36f0ba57880a9c635528d56986bd676280ad16d190cb03acf174b17` |
| 新 BC | `32576c52863f9b8e45df77bac2beb9ad4863906fc73b0ce3a660068defac8c0e` |
| Mac llc x64 COFF（exit 0） | `2dd3916d114c547d96a3312732b4525b657bafcd48eb2126cc55ccfaf41e636a` |
| Windows native 实现 | `ddfa1f49d4aedc26266a8114ce2ce2478b0c820bce5784dfc30d7b1c9326c1ad` |
| native archive | `d734cfbbf1b717fef045ce186ddb2b37c349b39e1cd57496aeec4fc5cf7afa22` |
| r5f EXE（23,487,488 B） | `508cba991c5e9220dc3a8459c4a8c9bc7660d2effc816c0bbd1213ad91611c12` |
| 实际加载 runtime DLL（1,276,416 B） | `ca65f2b82121a0587e03203314fc723724058d59d42391aa1e19b3eb69463b27` |
| 实际加载 boundscheck DLL（44,032 B） | `07b33dd3de22489b442cc32f0fe8ddfc80b753443b17fb2053133b2e7ffb6c78` |
| 可独立启动候选 ZIP | `2f70f9c8702c7fa45e621a62ece2e4d16fe4fd39258844197ceb6b7ddb147bd3` |

新 BC 捕获 `07dbf439519c4c8e8f913f0d261d425c` / raw driver `6e6ac695865b40cd803a810b23faee4e` 明确是 capshim exit94，不是此轮真实 AV；正式构建另有真实 exit0。Cangjie 输入改变后生成了新的 BC/obj，未复用 r5 旧 obj。SDK 原版 llc 与 llc-real 双 SHA 均为 `1ea683623104335fe503b5c603e70faaaf14517c31672fa35a6b3b7f8580c770`。

独立容量消费最终 nonce `1bf285e713f44babb93b8d6ef4a35fbc` / PID12464 / exit0：v1/258016 B 旧版、越界、UTF8内部及有效50KB超限写均具名拒绝、完整正文和版本不变；合法4128 B追加精确到v2/262144 B，一字节再追加拒绝保留v2；公开 Undo 精确v3/258016 B、Redo精确v4/262144 B。原 `bf01ec63332a4e5ea27253f83865a10c` 失败回包为 invalid_parameters，验收漏传要求的一个文档目标；之后 `6e54933fa5124850972244eca7e0c092` 是公共HEX字段解析只允许小写的脚本误红。两份原件保留，最终从 GET_CONTEXT 的 sessionDocumentId 配对实际 owner 后携带 ID 调用，未修改 owner/公共契约、未降全文或版本标准。正式写作脚本亦已修同一目标与明确 APPLIED 判据，D 未裁决故主链未重跑。

超范围正常打开 nonce `57ffd986a480421194e3d1fd1e2cf39b` / PID3100 / exit0：262145 B 中文/空格文件原字节/hash不变，保留 pharos-untitled v1 的预先从该版 sampleArticle 源字面冻结的922 B完整正文；正常Alt+F4退出0。截图显示未命名文档，不能据此宣称容量拒绝通知全文可见（当前顶部状态区截断）。同实例三个非系统模块均 PE x64；两 DLL 完整实际路径/hash在 `oversize-open-b66ecded71c744528de5e5f35d236e02/identity.json`。

PNG 有限 GPU 读回补证：alpha nonce `8febcb09687144919cdc38986112a90f`，128/64 alpha在白底为 (255,127,127)/(191,255,191)，opacity0.5仅一次，父裁剪外白、换图蓝、坏图保旧蓝，关闭纹理实计归零。Pinned aggregate budget nonce `7862a93a33274f9da61f126f675dd180`：第二幅16MiB RGBA超过32MiB CPU总预算，真实 PNG status28、failed3，CPU16798421/GPU16777216 B不变，旧accepted/旧像素保持，关闭资源归零；此前两次为探针误用TEXT预算码/不存在枚举的原件，不是PNG后端改动。正常产品不透明PNG屏幕采样仍复用 r5c `577cbcba56c742159b98ed8cc50f59cc` 原证；坏图/预算/恢复后编辑的正常产品组合门仍未验。

候选可启动包 nonce `929ada90041f477dbc197eb6fef55db7` / PID5300 / exit0：仅系统 PATH，从含空格候选目录启动，中文/空格文档完整 owner42 B匹配；三个实际非系统模块全部来自包内，正常关窗0。来宾保留路径 `C:\cjgui-windows-w1\delivery\Pharos Windows r5f candidate ec731d7f3f954730b5a299a63a062b75\Pharos Mark.exe`；双击或 `"Pharos Mark.exe" --open "中文 含空格路径.md"`。Mac对应文件在 `artifacts/windows-pharos-20261005/delivery/Pharos Windows r5f candidate/`；候选 ZIP 在本轮 worker 的 `r5f-portable/`，说明明确整包未验，不作为最终可用编辑器交付。

同 r5f 候选 EXE 五次开/关和失焦预览 idle nonce `6b75fa45530c4c538d5c367a65d528af` / exit0：PID14644/16132/13500/16428/14380，各系统Alt+F4四事件、内核退出0；handles初值308/309/309/309/309、threads10、RSS约82.5MB。第一实例用自有WinForms辅助窗一次系统点击取得真实前台，Pharos失焦10.0490358s、CPU0.125s（单核1.2439%）、handles308→308、RSS82665472→69812224 B、frame1→1。它是失焦只读预览，不替代源码caret闪烁或编辑生命周期。旧 `052d271cfbe14e68b753c8cf2d2665b0` 是 SetForegroundWindow 被系统拒绝、`a856c2b19a23436d82e2f815fd2e5d4b` 是 MatchCollection 负索引误读；最后先以已留实际日志验证非负 Item 索引，再测真实失焦间隔，不重投编辑救绿。

原固定门汇合状态（截至 r5f；子项PASS不关闭整门）：

| 原固定门 | 状态 | 已验与尚缺 |
| --- | --- | --- |
| 正式入口 | PASS | r5f含空格同冻结正式build0，EXE/DLL x64；中文/空格正常入口与自绘accepted窗口。构建是来宾捕获→Mac llc→来宾链接 |
| 人类输入通路 | BLOCKED | 单次系统模式按钮/P8具名局部原证保留；当前D导致源码107未accepted，尚无正常字符的owner＋可见全文闭环 |
| 范围与Unicode | NOT_RUN | 正常中段非空/代理对/分解重音/多标量移动删除未完成；native来源/P8不替代此门 |
| 组合输入 | NOT_RUN | 已安装IME环境核对保留，真实预编辑/提交/取消及0/1/0 owner事务未完成 |
| 源码/预览往返 | FAIL | r5c源模式raw33，107 missing；重复runs＋保留旧正文被D误拒，完整往返未通过 |
| 人/Agent共同操作 | BLOCKED | r5f真实公开写/完整读回、拒绝保旧、Undo/Redo子项PASS；人→Agent→人免点击连续性未验 |
| 保存与复开 | BLOCKED | 同最终二进制保存全文→正常关闭→新PID一致且能输入未完成 |
| 几何与生命周期 | BLOCKED | ResizeBuffers device-lost及无pump close RED/GREEN/撤回负控PASS；正常滚动/resize/minimize/focus/旧回调编辑组合未验 |
| 图片与失败 | BLOCKED | 正常不透明PNG像素PASS；alpha/裁剪/坏图/aggregate预算/恢复有限native证据PASS；正常受控恢复后继续编辑未验 |
| 响应与资源 | NOT_RUN | 原至少20笔真实滚动/预览重叠、owner/accepted p50/p95/max和工作原数未完成；不以公开回包替代accepted时延 |
| 空闲与回收 | BLOCKED | 同r5f失焦预览10s＋五次关闭PASS，3×4 worker含六个继承管道后代回收PASS；源码caret闪烁及全部输入责任/资源终态仍未完成 |
| 同源交付 | BLOCKED | 121项清单、新BC/obj/hash准入、正式build0、无SDK PATH候选启动、必需上传失败负控PASS；最终正常写作尚未通过 |

D 当前准确升级仍为 `f9efa3b34d3b4f20820d034cba3b5749` 生产反例：accepted abc+[0,3)，下一候选重复runs、保留未变正文，Present33、pending1、accepted1。有限建议是在提交边界仅将 pending runs 与同一保留 candidate 正文/绑定共同验证/准备；仍覆盖新 abcdef+[0,6) 先runs后正文、真越界保旧、复用几何/lease、样式颜色/字体/DPI失效。按 AGENTS 第一次公共契约实质修复失败后的升级规则，已提交用户待裁决，未进一步改D、未自动调用其他顾问。收到裁决后先跑这组区分反例和撤回负控，再按native-only准入复用匹配r5f BC/obj重链接，首先进入默认1100×780正常小文档整链，随后原固定门；不要从r4重做或吸收整棵E/H。

其他具名留开：关闭时 pending IME successor/半个高代理的完整恢复来源未证明；PNG诊断texture探针仍stub，失败状态没有缓存，不能以资源诊断全0宣称全部机制真；一般图片aspect mode实现尚不完整；Styled run纯颜色复用未获新运行证据。以上不改名为已完成。测试数据全部属于本轮独立目录，后续测试显式PHAROS_DATA_HOME；当前worker环境HOME/DataHome确为空，旧最近记录按各自工作目录的相对路径解释，未读写用户记录内容。runtime_state.cj/cjpm.toml仍零Git差异，E/H并行正文保留，未stage/commit/push/切分支。最终worker/SDK回收原件下段补记。


最终自有资源收口（D 仍待裁决，目标没有标完成/暂停）：nonce `1572c779d51a4e99980edeaf8ef6b8f7` exit0，worker PID19876最终 handles570、threads17、private83517440 B，自有build目录应用零残留，两份SDK llc双hash原版一致；runner session `ce74c33878ce4bcb9942920ec5460ede/session.json` 已读回 `closed` / `BYE_AND_SOCKET_CLOSED`。runner总退出1包含所保留RED/负控/工具误红，不代表最终正式build或关闭失败，也不能把此runner整场写为全绿。Portable候选目录保留但应用均已关闭；VM/用户窗口未清理。Mac候选ZIP另保存在 `artifacts/windows-pharos-20261005/delivery/Pharos Windows r5f candidate.zip`，SHA与上表相同。两仓相关diff --check通过，正典native与r5f同SHA，runtime_state/cjpm零Git差异；既有针对性/build原证按影响复用，未再重跑无改动整套。已授权Pi deepseek-flash快查使用的答复与运行证据分开保留，没有调用其他顾问或启动子代理。


### 2026-10-08 r5g pending IME successor关闭交接

完整结论及身份见[原任务页r5g](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5g-close-successor-20261008)。同一生产handler/deferred replay＋公开destroy/v1接收原件，均位于 `runner-sessions/09d0b7b4a4d547169e2d3e75be6d18d7/results/`：RED a512c54e37564d1b8b31bd76987388ce exit2；GREEN43c373310f9c41c8b161559c6b8fa687 exit0；完整字段/容量/分配失败8ec5c34dfa324ade93f0ada7a189fa08 exit0；原request100/binding9跨current200/10的defer/replay f76c516fc2ae4ad5a9614bddca0116a6 exit0；仅撤回关闭转存40b15ba10d2a416694002e7653c4b5c7 exit3重新RED。半个高代理是未完成解码暂存；有限close取消未造字，与完整marked UTF8转恢复分开。公开kind2/UPDATE和16项meta不新增；结果不替代真实系统IME/最终写作。

正式 `3120eb0bbcb146218918ad27fc5e4284` cjpm build --skip-script exit0，新EXE c6ca45d4e0c49217e3c26234965e6e46270494c2bdf39fc6bfc1aaa806250eca（23488512B），native403c2e9373a774a7dfa6e923e000286191c0b26bb2a13487fad39c56460f2403、归档92fa8c5b801c642ddee1364be8516fb1901c967b3deaeb69e665701039d069b3，121项r5g清单ff20f9c5753d1099e3fb846e82030526fa3f7bde3c303b80152b9c151fafcc52。从完整r5f仅改native，BC32576c52…/obj2dd3916d…准入与实际捕获相同，未重编llc，未吸收E/H。原r5f portable候选保留，r5g未另做正常窗口启动，不能声称候选/全部固定门升级通过。

最终audit7c036f099cd84aa29961f58f27f7ea32 exit0：121源hash零错误，原SDK llc双hash一致、自有应用0；worker12992/session09d0b7b4a4d547169e2d3e75be6d18d7已BYE/socketclosed。Pi deepseek-flash只读快查原件在 `evidence/20261008-r5/flash-close-ownership-{request,answer,stderr}.txt`，实际exit0，不当运行证明。D仍待已提交的指导裁决；全部正常消费/剩余固定门口径保持上一汇合。pending successor的presentation-conflict/换绑定消费仍具名未证明，未宣称全部责任闭合。未改产品E/H、runtime_state/cjpm零Git差异、无Git提交操作。


### 2026-10-08 r5h/i来源交接与当前D受阻

完整范围/矩阵/同源身份与受阻审计见[原任务页r5i](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5i-successor-source-20261008)。本轮全部原件在 `runner-sessions/b5a3a8ff50914a499ece0fed7ad81e84/results/`：后继五边界生产RED723e53bf7f734de2a3de83f8cd00a6a0 exit5；10-caseGREEN08f4217bb57a44a6bd9f64a817210f75 exit0；仅恢复旧finish/start负控d22bbc9e595a4d2d9d8622bde56eb394 exit5；待决门真实REDb4b96d20f0e64af9bb5203cf14863ad8 exit1；接回原门59622d1c4f8440b186b6e751c18c104d exit0。b61f92b52c3e482694537d21ee8e569b为错误helper名的编译误红，保留但不作运行失败。

后继完整恢复、捕获binding/node/resource/kind准入、同deliveryId失败重试及IDLE/MARKED共用安装门已有限验证。真实renderer/UI dispatcher/focus＋人工冻结payload，未用真实系统IME/SendInput/Pharos owner，不扩报正常体验。中间r5h正式a02ecea115a04fcc936f6164c67d09f6 exit0不作最终版；r5i正式7ecf49e5855c4ded9e85bee5bf463a1f build --skip-script exit0，EXEbe754458ad8fc92fe9fa991f885dd42305b1df5cf1e49e5359e9f223c4fca68e，native39b535f1…、库bf196f9e…、121项清单ad0f6c01…；实际BC32576c52…匹配obj2dd3916d…，无新llc生成或E/H整树吸收。

正常脚本f886b96e…加入完整版本一致分块读回、真实journal逐事务范围/版本/checksum/合法scalar前缀与每步独立全文oracle；typing原件设计保留；实际断言/归档顺序在r5k真实失败后已校正、按原字节上传。最终fixture53926553b2034bb1a5e5205d40e78501 exit0（13 journal＋10读协议fixture/拒绝原因，完整AST与C#编译）。前序ParseFile无BOM读取与fixture数组展开的错误及原负例误绿均保留，最终结果依具名拒绝原因；fixture不等于正常链/逐筆owner通过。Pi deepseek-flash只读快查exit0原件 `evidence/20261008-r5/flash-successor-retry-*.txt`，不作运行证据/不裁决D。

最终821244d15d3a4c42921a5e08824ce3f6 audit exit0，来宾121源零hash错误/自有应用0/SDK双原版SHA恢复；worker7592/sessionb5a3a8ff50914a499ece0fed7ad81e84已BYE/socketclosed。D四个routine与r5f逐字一致，原Present33反例未被改掉；D指导待答连续三个goal轮仍在，独立必要项完成，原正常主链/固定门/最终portable依赖D裁决。原目标未完成、不自主暂停；当前受阻原因与有限接续方案保持。r5f候选未改身份，新r5i未做正常应用启动；runtime_state/cjpm零diff、E/H/用户资源保留，无Git提交操作。


### 2026-10-08 r5j D闭合与r5k新键盘升级

见[当前任务页](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5k-keyboard-escalation-20261008)。原件统一位于 `runner-sessions/4bc684dc0296405c91811723b39d6693/`。D原RED e437a2e4023048288ac0995767368a20 exit3，5-caseGREEN99a60e3f35624728b2c2a61de4ae7884 exit0，配对6f27cfce5fc949108abbcbc1229684a0/身份6cace7dfe70d47a297d88c6781bb6008/范围cf6556416a3e4cbd9e06e742b619799b三撤回均exit1。正式r5j第一次9e1ef200fd294c3b89a00d3bad7f79a0 exit46（真实SDK AV）保留，单次同输入重试dfd02c7899c44aba888578c093d42442 exit0产新EXE9fcbe2d1…，SDK恢复。

正常写作319481b2893f48d091a6b6227d1c587c exit32已从D旧失败推进到实际源码focus，Ctrl+Home定位失败；owner原116B/v1保持，accept-run-9373abc56b9345b98b92d1c0156a82c7截图/日志已上传，自有app10604回收。原GetAsync修饰RED59b6eaf1…、首修GetKeyState部分GREEN但Shift RED c8e8ef15…、WndProc诊断213d296f…和扫描码对照01ddc64b…均有原件；按AGENTS已升级，未猜第二修。共同文档首尾意图及窗口接线的Mac isolated两项测试red run1/green run0在 `evidence/20261008-r5/document-boundary-unit/`，不作Windows普通输入证明。r5k121项清单c4e7c922…只纳入W三文件块，重新捕获/新obj/build待完成，Shift/原完整链/第六节余项/最终portable仍具名留开。旧r5i“D待答”是历史状态，不能恢复为当前阻塞。


### 2026-10-08 r5k主链新RED与r5l来源端点修复

[当前输入节](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5l-range-prefix-20261008)给出同源身份和判据。r5k正式7b1c3957… exit0/EXEa601ab54…；正常8b676a0c… exit32从中段定位PASS推进到28项SendInput、实际只接受W；owner v2/117B、journal一条byte31:31→57，补取179fadc6… exit0。typing after完整readback未落失败原件，旧“失败前归档”口径已更正；现仅调整持久化先后，不松全文/版本/逐笔oracle。

同session4bc684dc…有限生产RED c1b21731ccc64f729dfea4ea85364f6b exit1；GREEN3cd80576e5c5419ab810f8697dc81f11 exit0；capture撤回4c97dfd7480f4ee5988b2d1545d8f70a/ACK端点撤回d31e3a5d035f4b6cbffc9de3e46a85df均exit1。真实renderer/system输入＋手工owner ACK，覆盖ACK0原源与ACK1后的来源冻结；不替代正常Pharos/IME。r5l只改native，121项MF87fce429…/nativec836415f…，正式relay在途。Shift仍待指导，不重新等待D。语言清单a9c1f830…给出真实zh-Hans-CN/TIP，系统IME正常三腿仍未验。

### 2026-10-08 r5l正式消费：连续输入PASS，Shift扩选FAIL

同session正式retry `2275b96cc65941ffa245858ca42a50cf` build0/227.664s；native库fad21db3…、BC32576c52…、obj2dd3916d…、共同cjo9ed28506…/archive21f99cfd…、新EXE `12073933f1ca52555a851c325abf1ecb7ebc266cb409bca31044b0d87f3726df`。首轮ab0acaee…真实SDK AV与原件保留，SDK原版恢复。完整产物/实际relay日志见 `guest-results/4bc684dc0296405c91811723b39d6693/r5l-build-retry1/`。

正常 `d97ddb23f6be4e1db907eb3f884a2f8a` exit33：PID9520/HWND20190200、默认1100×780，Ctrl+Home→13Right精确；连续WINCHAIN-01中😀28项系统输入投递、13笔human事务、v1→14/116→134B，逐笔oracle＋完整owner均PASS。run `accept-run-8ae42c0b520f477189757a9a6224adec` 的typing前后bin/journal/meta及02-typed.png已保留，截图已查看，Python独立按冻结UTF16跨度核完整二进制。随后Shift+3Left8项投递，27→25→24→23却仍[23,23)，期望[23,27)，FAIL。原已升级Shift问题未二次猜改；D已闭合。其后往返/替换/人Agent人/保存新PID均NOT_RUN，原包与最终portable未完成。自有应用回收，继续独立系统IME；保护E/H及Git状态。


### 2026-10-08 r5m真实系统IME呈现与两处新RED

见[当前任务IME节](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5m-system-ime-20261008)。同worker/session4bc684dc…，r5m正式c4f171fb… build0/EXE3c2f0f39…/121项MFa976156f…/native2eb84ea1…/SDK恢复；position消息级RED21120f02…→GREENfe4ef8fd…不替代系统组字。r5l正常ef466731…零／一／零事务PASS但UI位置/预编辑缺失；r5m正常12370de6…保持事务，真实ni及候选在插入点可见，随后连续Unicode零写入、exit44。现有逐笔日志055a946c…确认第一笔是v1旧基线对owner v2的version_conflict，后缀才sideband_invalid；原件在guest-results同session的accept-run-abb22dd…和accept-run-07374d0…，全文/journal/相位/截图均保留。共同能力门的最小修复尚待重新Cangjie编译及正常消费。

5427B预览b1822541… exit45（accept-run-5279e2…），240片段/336runs但native node140文字预算拒绝、accepted0；20笔公开请求及真实wheel未开始，不虚报性能成绩。r5n只加原测试门控实际预算尺寸/字节诊断。原Shift失败仍待指导，无第二次猜修，D无需重问，最终portable仍旧候选；原A–F包未完成。


### 2026-10-08 r5n预算实测、r5p有限修复与新BC

同session4bc684dc…，r5n正式0f68d4ec… build0；原5427B诊断c99d3377… FAIL/exit45，实际node1056/680×29、other25,111,808B接近原24MiB cap，owner保旧/20未开。r5p真实renderer RED2dbbdb12…→GREEN6a5f73e9…、仅撤回visible覆盖fdb7cf30…翻红；240布局/16可见纹理4,597,824B、滚动保lease、长段落中部、真实超预算保旧和释放均有限通过。七项受影响回归ef62ed19… exit0；真实工作计数e9a4509f… exit0。夹具不是Pharos/IME/性能成品证明。

r5o同121项只改共同来源恢复能力门，7b8834f1…捕获BC成功，原SDK恢复；新Mac llc运行证据在evidence/20261008-r5/mac-llc-r5o-*，正式build/正常汇合待完成。目标原件、身份及责任边界见[当前任务页](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5m-system-ime-20261008)。工具初次r5p AST下载404只因文件尚未复制到guest-transfer，保留7d5bec07…；不作生产修复失败。Shift仍待原指导，未二次猜改，无Git操作。


### 2026-10-08 r5p正常续写、r5q文件/滚轮与正式候选

详见[当前任务接续](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5q-writing-20261008)。r5p f2635ea7… build0；608081df…/PID12864真实IME零／一／零＋28系统Unicode/13事务v2→15/137B，以及Agent append v16→免点击五human v21/161B精确；SAVE真实candidate_sync_failed/原116B保旧、tool首版也缺异步终结等待，均保原件。原5427B预览已accepted：836ba027…工具误查apply.version，9350777b…正确20笔全文v1→11/5477B却80 wheel实际位置未动，FAIL；真实raster/upload/present计数不当滚动成绩。

文件f243866e… RED→c312acae… GREEN，目录7b4fefb6…真实barrier、missing/目录目标保全文、非法输入拒绝、100次handles75→75；30649574…sync撤回翻红/364ac6cd…ANSI发布撤回C程序翻红且脚本清理失败均保留。wheel ff44c3a1… RED→3ee66225… GREEN、WndProc撤回2839b2af…RED，覆盖真实accepted点/clip/旧投影/输出和分配压力保原FIFO后恰一次。kind11原压力通知不是第二次wheel：8be6a432…旧工具误红/5213207f…校准通过，无生产救绿。只读TEXT_POSITION供P8正常跨度测量。Flash仅用户新授权的无工具协议快核13.05s/exit0，不当生产证据。

r5q121项MF7bbf660d…仅纳入原p renderer/posix，native42a2d9f8…/posix99f96884…/ZIP6b2cf4c0…；正式bc29495e… build0/166.388s，EXE29ce544b…/23,504,384B，native库bcc18cb4…，原Cj/header/flags不变，实际BC32576c52…/本轮实际COFF2dd3916d…准入、SDK恢复。普通IME后同次保存/fresh PID和真滚动20笔消费在途；Shift仍待原指导，原整包未完成。protected runtime_state/cjpm未改，暂存空，scoped diffcheck0，E/H与用户资源保持。


r5q正常系统IME＋连续输入＋Agent→人→真实同次SAVE→正常关闭→新PID重开输入：9ac57fe3070a4b92a08a8061a0ade7b1 exit0，PID20264→12004，161B文件SHA0a07e93f…/两kernel退出0。原件accept-run-49df6f46f6d04708b8abbc2cffb06354。原5427B真实预览/80系统wheel与20公开请求：7599d40aee544094928ffef7cb80eae5 exit0，PID5428，20/20实际投递重叠/9次世界位置变化/全文5477B v11精确。原件accept-run-481e91c07cd54a76a6f5e1f1afe7a56c，129新增raster/upload/47,340,864B、14成功present；owner回包8.588–105.781ms，输入→accepted仍NOT_RUN。鼠标非空选择/预览返源独立腿在途，Shift FAIL不被覆盖；原全包/portable尚未完成。


### 2026-10-08 r5r共同快捷键、正常P8和r5s选区历史接续

r5q鼠标644e3d01…真实[23,27)/预览返源精确安装/免点击X一笔通过，CtrlZ缺入口FAIL；r5r shortcut a6521d6e…RED→28ae6bb2…GREEN（原transfer也通过）、6db35610…只撤回入口翻红。正式b398ea48…build0、EXEc4cca083…、native24d21b43…、SDK恢复；原保护失败f76e34a0…是prior清单工具误替换、无修改。r5r normal8c7f9273…/PID5040，原P8正常门再次通过且Undo/Redo全文v15→16→17精确；human SA=-导致Redo queued=false/没有after选择，后续不借0:0救绿。

r5s仅采用正典已有的同事务human selectionAfter三块，121MFf6dd1485…/ZIP54edbe95…；正典E/H三文件只读，实际采用与SHA见r5s-canonical-adoption.json。捕获7a084ea3…0/171.679s，新BC4bed0995…/28,597,448B，SDK恢复，新实际Mac llc在途/尚未正式build。独立范围Unicode与resize/device/20输入工具继续：7f6c0c0c…AST通过；8abb046f…UIntPtr工具失败未注入，fc8409ae…resize无实际Present所以尚未触发控制闸，下一版由一笔公开[G]真实触发，不改生产、不重发输入、不称已恢复。见任务页r5q anchor末尾。

- r5t device只读归因：r5r controlled retry4988f5d0…经真实[G]公开写version1→2仍无RECOVER，不能证明“没有Present”。r5t MFebe79d4b…/native12c41701…，仅WORKLOAD追加设备代/恢复/pending/HRESULT字段，编译待r5s新实际obj。
- 独立工具：25758500… accepted字形0点击STALE_SELECTION，范围移动尚未跑；b3461041…普通resize/minrestore后13:13重复选择没有新日志，20样本未跑。已有main日志只在坐标变化时输出；改非零首次1与恢复后14并启用现有归因，AST通过后顺序消费，原失败保留。

- r5r Unicode GREEN6ede948c… PID9620，grapheme左右整簇/3次全簇Backspace；几何20输入 GREENf623b477… PID20168，20个全owner/journal/accepted body，p50/p95/max与实际资源见任务页，Python独立全字节复核r5r-independent-full-byte-check.json。
- r5s新Mac llc0/1085.588s、obj0cecb4d9…COFF8664（mac-llc-r5s-result.json）。r5t正式AST9e4aaefb…0，sourceMFebe79d4b…/新BC4bed…/新obj0cec…实际正式链接在途；原12固定门仍完整保留。

- r5t首次正式de56cedd…exit46/真实cjpm -1073741819；失败log/inject/BC与SDK双恢复回收fe1af1dc…，事件f0dbf3ef…/Application1107与旧cjpm SDK模块偏移0x12e608一致。一次同输入retry1按既有指导进行；当前产出aee89ebf…尚不能称正式构建通过。


### r5t 正式正常消费／r5u 恢复入口首修（2026-10-08）

全部来宾原件仍为 session `4bc684dc0296405c91811723b39d6693`；工具、冻结身份及Mac原件在 `evidence/20261008-r5/`。当前整包未完成，详见原任务页 `windows-r5q-writing-20261008` 末段。

| 原件/nonce | 事实与边界 |
| --- | --- |
| `95f0b804…` / `r5t-build-retry1/product-artifacts.json` | 正式build0、EXEc3c69f2a…、新BC4bed0995…/obj0cecb4d9…/native archive67234317…；首AV仍保留 |
| `16f26508…` | editor首次点击前覆盖检测失败，无输入投递 |
| `555d2755449a4dacb05a257f6122651d` / `accept-run-b4c29bc33afb4223b111f31b936198ce` | PID17724，13笔/非空P8/预览返源/免点击X/Undo精确；Redo v17正文及owner24:24正确但无原生恢复REQ，exit33；主链后继依赖未跑 |
| `7178c31540824a56bfbb371338507a0e` / `accept-run-30b3d7695fd34f39be1ab07acc9391c1` | PID10172，设备代1→2/count0→1/pending0/hr887a0007恢复读回成立；[G] owner v2/119B；恢复后A零事务/installed_range_prefix_mismatch，exit55。撤回旧缺日志即未恢复推断 |
| `945da92a252f4ccdbbee585a17ebf0db` / `typing-lifecycle-latency.json` / `r5t-latency-full-byte-check.json` | PID10008，resize/minrestore后20笔v1→21/116→136B精确/正常关窗0。owner33.6/69.4/98.3ms、accepted81.9/117.3/164.8ms观察上界，含IPC/probe；device本腿NOT_RUN |
| `77381274…` | 正常PNG实际红/绿像素及正常退出，原坏图/预算有限原件按影响复用 |
| `d9938e745bb44685a549b6f1a070f5a5` / `r5t-portable/` | 系统PATH-only，正常中文空格路径、完整owner、3个同目录x64模块、正常退出；ZIP7b33aa21…，仅未完成写作候选 |
| `eec5fb9f991043889f38f7cd3ef23b51` / `idle-close5-8e7510deb6ff418cac819410c594446c/idle-close5.json` | 失焦10.048s/单核3.4211%/frame1→1/handles308→308；五个kernel0/HWND退休。聚焦caret未验 |
| `e1f70cfa…` / `c1b5f659…` / `493f4b96…` | 3批worker，目录1/仅当前任务及固有conhost10840，handles516/518/514、RSS约120.7MB；不宣称恰回零或长时无泄漏 |
| `30bdaa27…` / `r5t-build-config/` | 实际7份构建TOML完整传回、哈希吻合 |
| `9a7bcfbd508e43da9683d44306083e55` / `r5t-source-delivery/` / `r5t-source-delivery-check.json` | 新含空格目录132项实际大小/SHA、121源与7cfg、脚本ParseInput/VerifyOnly通过；源ZIPda5900b8…/delivery MF3a1a1bf8…；干净重构建NOT_RUN。保留原构建MF，过期size单列 |
| `restore-projection-unit/{red,green,withdrawn}-*` / `w_restore_projection_test.cj` | 完整冻结r5t共同生产恢复入口：旧投影先guard导致owner-after请求误拒。新顺序3项GREEN；撤回1失败/2拒绝仍PASS，均compile0。fixture构造器工具误红原件保留 |
| `r5u-identities.json` / `capture-r5u.ps1` / `7bc9a745…` | 121+7cfg，window8004f3c3…/MFaea57e01…/ZIP1abe8bba…；只改owner选区读取顺序、原coordinate/source/install门不变；AST0，新BC捕获在途，不复用旧obj |

局部共同修复已回正典window及既有source_handoff两例，未吸收E/H大diff。CodeLattice stale/workspace图未给有效caller覆盖，以本窗口及Pharos源码入口补证。Shift首修失败仍等指导；r5u首次正常验证若失败按核心机制升级，不再猜guard。不stage/commit/push，用户/SDK/并行保护继续。

| `260e4eb6…` / `mac-llc-r5u-*` / `22cc7f36…` | 原目录新捕获BC4bed0995…/新编译obj0cecb4d9…，llc0/804.346s/fresh_compile；正式脚本AST0后build在途 |
| `0f80df24…` / `62480154…` / `aa8b4add…` / `efca794e36934548beccf266f94e7511` | 独立空目录121+7cfg/native新建；首次SDK AV/事件1111保留，一次同输入复试捕获0，实际BCf02f558b…须单独obj；正式干净build尚未验 |
| `bfaf70a34ec743d0a90ef26d5bf251af` | PID14812聚焦source10.0526s/CPU3.5750%/frame4→4/完整owner保持，handles355→360；不推断caret闪烁。截图semantic label显示缺口待有限修复 |
| `deepseek-flash-delivery-check-*` | 60s无答复/helper1终止；无采纳，不作验证证据 |

| `867cdae5695b47de9cf9330a2ad158ca` / `r5u-build/` | 正式build0/238.991s，新EXE7a02e03a…，当次BC/obj匹配注入、CJGUI真实重建、SDK恢复；主链验收在途 |

| `82a4d2e45ae64706b89720671f2f5b5a` / `r5u-main-full-byte-check.json` | 默认完整owner写作链0：5044→fresh19864，Redo REQ6安装、Agent REQ7/人续写、151B公共保存、新PIDR→152B；22笔/10快照独立复算。可见source选择/光标未通过 |
| `bc3c88005df141b28b6ab6c7140dc3d4` | r5u设备门仍FAIL55，PID6324/owner119Bv2，REQ1 identity open/attempt exhausted，A单投零写/prefix mismatch；精确observed-after保留，向指导升级 |
| `4fa86cb3b2c14daf8a19a04ab83dada7` / `r5u-clean-build/` / `mac-llc-r5u-clean-*` | 独立空目录正式build0/BCf02f…/fresh obj497f…/EXEf4e57273…，SDK恢复；首clean正常6eca14f3…为工具\S+不接受真实空格path，原件与有限正则检查保留 |
| `d536cb36…` / `89693781…` / `d9439721…` / `r5v-identities.json` | 多行标签真实3RED→全GREEN→3RED；回正典有限条件，nativec614…/121+7cfg MF6e725…正式构建在途 |
| `dbfac1ee3fd0456bb12dbe7478387fb9` / `r5w-source-paint-*` | 实际native选择和caret成立，2个GPU表面变化缺失RED；自绘投影artifact试验，未回生产 |

| `a9a3c854df67473c93ac60f5d8d26c7e` | 含空格干净目录EXEf4e57273…完整正常链0，PID2284/fresh11152，151B同SHA与fresh输入/两正常关闭 |
| `244ea4756b4645cc9fecf911866ec06f` / `r5v-build/` / `666946419d364bc99aa168b6bb8d59ca` | native-only正式build0/EXE8c44a7d2…/archive5271e02b…，正常完整主链0、截图semantic标签去除；source选区/光标显示另验 |
| `6d442d02…` / `0467dd70d448437e84f5812cb845d34a` / `e3324411438444c79e512a4e4f7726ea` | artifact提取指针工具编译失败保留；修正后source实际像素2GREEN/撤回2RED，未回生产。闪烁/焦点/资源有限门在途 |

| `ef6a5c98a4154ba2a192a8a4ff4a8303` / `da14e3b28b254f70a88f80bcd1dc7db8` | 私有 paint 31项GREEN；系统blink off/on、焦点与owner目标撤回/返回、accepted/candidate不变、零layout/raster/upload/scratch；撤回实际像素RED |
| `31ef6153ab184a518aec9c3a4ed6729f` / `375dd7bd8fec4ae698e85c4676de6639` | draw提取常规回归通过；首PNG工具漏资产失败原件保留；补工具资产SHA后alpha/预算/保旧/销毁GREEN，不覆盖正常device输入FAIL |
| `deepseek-flash-paint-check-*` / `r5w-identities.json` / `c2e49cc0…` | flash只读4.4877s未见机械失配，不作运行；native b71d…回正典，121+7cfg MFfb631…/ZIP5edf…；formal AST0后构建在途 |

| `a2a59a25…` / `4135ebe0…` / `4abcfe75…` / `r5w-build-fail/` | 首formal build AV -1073741819，原log/匹配inject/BC和事件1121保留；SDK恢复，产物不算成功；一次同输入retry1 AST e2ffaaa6…0后在途 |

| `9214d65d1b7a46e194bcb6e3d87f2084` / `ce7eaa17…` | 原目录同输入唯一retry1仍SDK AV，停止原目录复试并升级；独立含空格目录w工具AST0，真实build/自身BC准入待执行；不由旧EXE倒证 |

| `ccd27017b95d4c3db43ab0d381bbcd39` / `r5w-clean-build/` / `r5w-actual-build.json` | 独立目录正式build0/243.212s，BCf02f…/obj497f…/archive42574a07…/EXE46a8e992…，SDK恢复；原目录两AV保留 |
| `76d313ad…` / `5bedefbb…` | 主链／实际blink工具AST/C#0；首host误读上传目录和missing script留原记录，修正后未降低消费断言 |

| `5a440efca5b243c39bba965cf1873588` | EXE46a8…默认完整主链0，14512→fresh10748，151B保存/152Bfresh输入，首次选择实际蓝色高亮；返源时工具栏焦点下无source高亮，具名保留 |
| `aef7bc7695f44e758003e1b74014f4d6` | 27真实pixel样本2状态/5转换/system530ms；source10.0129s CPU3.1210%/frame+19，零layout/raster/upload/scratch增长/owner不变；handles+9不称零增长 |
| `93dfc96d4cfa476e86aa7b5abbf49ac3` / `r5x-async-measure-*` | 252000B owner正确但空窗/worker_unavailable真实RED；Windows async失败占位已定位，有界native worker隔离试验尚未回生产 |
| `69e75c3a…` / `ef8ce5f9…` / `31e387e8…` | 同46a8…独立resize/minrestore+20输入、20公开请求和80系统wheel真实重叠、正常PNG实际像素与关闭通过；device/Shift旧失败仍留开 |

| `22fd9b64…` / `41d16582…` / `7e64212c…` / `386c7402…` | async原占位RED；首宏双求值工具失败保留；仅修夹具后GREEN/撤回RED |
| `2a991f3e…` / `a124285670044e2c953f3e8bbb5fd680` / `705943b0…` | 实际异线程／冻结输入／四槽／256KiB输入／取消双退休／stale／准确归零和既有高度预算有限GREEN；实际绘制10组回归GREEN |
| `deepseek-flash-async-check-*` / `r5x-identities.json` / `538685e0…` | 17.3068s只读机械检查非运行；nativeb505…回正典121+7cfg MF3b2c…/ZIP043b…，AST0后独立正式构建在途，近上限原反例待正常消费 |


r5x 当前真实结果（原A–F仍未齐）：
| 原件nonce | 结果 | 对应事实 |
| --- | --- | --- |
| 0d2ef977732f4784bbf8314a5fe7b677 | 0/208.894s | 正式build0/EXE9497b7ca…/BCf02f…→obj497f…/native478d…/SDK恢复 |
| b13d2f1e784849598d3e7f5863f561b0 | 33/30.515s | 252000B出图；旧夹具误比owner与64KiB镜像；未投递文字 |
| e8a89ee3c47b4b7292584cfeea5c07da | 1/35.520s | 单次28项；13笔恰一次；分块读v13→14拒绝混版；完整终态owner未取 |
| 07fb8431f12b4c539a115af8df18877d | 32/37.000s | 原2500ms预算内终态未齐；PID11344只到seq12/v13；不延时/重投，长文档依赖升级 |
| 6dfbf3111e3b45e0a12a39add514b64a | 0/45.393s | 纯系统PATH便携完整小文档链/2正常退出/freshPID输入；22笔及全文独立复核 |
| 42eca585764e4bc78905337b77a322d1 | 0/5.936s | 最终源码候选从空含空格目录展开；121+7cfg/132实际字节；新native和支持库；正式构建待验 |

范围核验r5x-frozen-scope-check.json：仅native变、115共同/header相等、132名称/ABI及flags保持；CodeLattice needs_project_selection不作运行证据。近上限夹具校准见r5x-near-cap-source-window-oracle.json；固定截止原件typing-fixed-budget-terminal.json。当前自有worker4bc684dc…继续用于串行构建，尚未最终回收。Shift与设备首修FAIL仍保留，不以新私有度量有限绿覆盖。

最终源码capture1357084d…45/269.934s，collectorbcade4b4…0：SDK AV1127/PID0x254/同runtime+12e608、app BC/日志未出、两llc原hash恢复；仅同输入retry1在途。原日志78432fd4…/327142B保留。长文档raw collectorcc6d6e0e…0，13/12笔actual journal逐行SUM/BASE/version/源跨度前缀精确，full live owner_after未捕获；见r5x-near-cap-journal-prefix-check.json，不能关闭长文档链。


### r5x 最终候选交付与原12门汇合（2026-10-08）

原A–F仍未完成；以下是独立交付实际结果，不覆盖Shift、设备恢复后首输入和252000B原2500ms失败。固定门及指导待区分问题见[任务页](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5x-final-delivery-20261008)。

| 原件 | 实际结果 |
| --- | --- |
| 0576f619… retry / 4766f2fd… recovery / 5aa3e055… restore | 唯一同输入retry新BC写入工具旧路径，collector45不是第二次SDK AV；按日志/时间/128输入/newhash准确拷回，旧工具BC/log恢复，工具错误保留 |
| mac-llc-r5x-final-result.json | actual新BC64b1…→fresh COFF8664 obj7472…，exit0/1217.112154s |
| d12e742fd20a49399d498e53f300db14 | 最终源码新空含空格目录正式cjpm build0/185.366s、新native825c…/EXEcdd740d0…、SDK恢复 |
| ee31b38278eb449999e7ef0301c27fd1 | 新EXE正常完整链0/42.939s、PID12700/fresh2588、151B保存/152B续写；[22笔/10全文复算](../20261008-r5/r5x-final-source-main-full-byte-check.json) |
| f47bfcb9c02d4882a16828be40e3edaf | 最终便携9497…预览真实4轮/Y85→-613，原非空返源蓝色反馈/免点击替换及完整后续链0/44.443s，5427→5462保存/fresh5463；[全文复算](../20261008-r5/r5x-portable-preview-scroll-full-byte-check.json) |
| 08b46a49b9ce44638bed5d921f5db943 | 最终源码133/132载荷全部VerifyOnly0/4.538s，新含空格交付目录；普通build脚本build分支NOT_RUN |
| r5x-final-portable-zip-check.json | 应用ZIP91865dd2…/6文件/5载荷/3PE8664、实际已测EXE/DLL保持、快捷方式读回；[实际核对](../20261008-r5/r5x-final-portable-zip-check.json) |
| r5x-final-delivery-prepared.json | 最终源码ZIP5c7aed1d…/交付MFd4b97f4a…、128构建输入未变、host与guest全核 |
| c288f702f74c4e5484c413c8a6478e81 | 8准确editor退休、32实际channel路径归零/8个残留精确回收，SDK双原hash；worker末handles580/RSS120545280/private87142400，不称长期零增长 |
| session.json / r5x-final-worker-after-bye.json | worker3908共236批正常BYE_AND_SOCKET_CLOSED，worker/conhost10840/专属目录不存在；host两端口无监听。宿主聚合exit1为保留的非零/RED，不是关停失败 |

用户入口为Windows桌面“Pharos Mark Windows r5x 候选”；宿主交付ZIP位于artifacts/windows-pharos-20261005/delivery。环境仍为Windows11 ARM64来宾、x64模拟和虚拟GPU。源码内部远处滚后编辑NOT_RUN，116B返源瞬间高亮缺口保留，原三项首次实修失败按AGENTS升级；不复跑、延时或改guard救绿，不启动其他顾问，无stage/commit/push。


### 2026-10-09 r5y 原包接续（进行中）

现行指导与逐项事实：[任务页 r5y](../../../../docs/plans/2026-10-05-windows-pharos-editor-package.md#windows-r5y-execution-20261009)。诊断与准入目录：`../20261009-r5y/`；raw session `35637620c94e4db98aa96b59e3c1896f`，worker15032。

- `native-only-input-admission.json`、`r5y-actual-build.json`：d2597a47…正式构建exit0及首SDK AV，旧9497/cdd保留；生产native设备拒绝RED/GREEN/撤回RED。
- `r5y-shift-full-chain-oracle.ps1.stdout.log` / c304ad45…：六组Shift、真实预览返源精确替换、UndoRedo、Agent/人类/SAVE/正常close通过，freshPID全文一致；reopen_body_rect工具测量门FAIL49，重开输入未通过。
- a67a2ea3… reset-only：设备恢复/新scene接受保旧owner，工具同选区新日志门FAIL54。e2d98655…/cc39f981… no-reset/compound首A FAIL55；0fd507ef…细节锁定安装33→base2/expected1第一前缀失配，未重投。
- `r5y-nearcap-segments.json` /83ad192f…：252000B/2500ms原负载11笔，118native记录；正继续领取/复制/ACK与安装条件计时，无性能完成声明。Pi deepseek-flash仅只读工具检查exit0，原prompt/answer/stderr保留。


r5z/r6最新事实见上述任务页同一 r5y 接续段：cfd611…同188dfda…/PID3068→18328完整Shift写作链exit0与全文复算；243a463…原252000B/2500ms仍FAIL32，桥接等待<1ms、约190ms共同回合间隔待归因；06badf0b…首A FAIL55，8次安装33仍待accepted节点诊断。66a4f988…源码内部wheel已送8但文字无移动FAIL35，owner/journal保旧，远处编辑未跑。r6仅诊断的2输入新MF40a…真实capture/新Mac llc0/961.559s，正式relay在途；旧候选与用户入口保持，原A–F未完成。全部新证据在 `../20261009-r5y/`，raw session/worker不变。


r6当前接续原件（原A–F未完成，旧记录不覆盖）：

- `r6-trace-actual-build.json` /836b…0/EXE8d426d…；`r6-focus-actual-build.json` /7a878…0/EXEbf25…，两实际BC/COFF/SDK恢复分列。bf25尚无后续票据/deferred转送/源码视口。
- `r6-owner-phase-profile.json` /5afb…1：252000B固定单burst2490.5434ms/13筆/v14，后续全文读取身份失败保留；362查询合计2384.562ms。`r6-grid-cost-admission.json`、`r6-grid-cost-capture.ps1`、`mac-llc-r6-grid-cost-*` 记录只main三处最小块、新MF255e…/BCb33a…及新的Mac对象编译，未声明正常性能通过。
- 三正常对照 `r6-focus-no-reset.ps1` /7ab056…0，`r6-focus-compound.ps1` /48f21…55，`r6-focus-reset-only.ps1` /7451…54。public install deferred原f28e…1→5809…0；真实Present原38/零票83de…2→b11c…0，有限门与正常应用版本区别见任务页。
- 源码滚动当次DPI/actual accepted落点：084c…旧实现四RED、031c…新全GREEN，错误未缩放夹具5ed3…另存；原正常5427B远处185即时编辑仍待最终EXE。`r6-native-closeout-finite.ps1` 补分配压力/换绑定与票据重入负控。
- `r6-worker-typed-resource-comparison.json` 同worker15032四快照578→582→580→578，差异仅File；151未知类型明确保留，未外推editor零泄漏。

`r6-combined-admission.json`、`r6-combined-actual-build.json`：634d…真正build0/171.596s，EXE2424dcbd…/MF56924…，实捕BCb33a…与新Mac llc0/917.064s对象d707…对应，SDK恢复。c899…三实际case0、错拼第四case2的overall1与a799…正确install单例0分别保留；9个同版normal工具AST待验后串行运行，尚不作normal通过声明。


r6同版normal/portable汇合已完成，独立源码构建仍在进行：唯一normal EXE2424dcbd…、252000B原预算1549.8498ms完整22事务；11d8…正确Shift六组与完整小链；c508…真实源码far185/185:188/单X完整owner；三对照13e…/26e…/6e7…各20笔单投准确，全文三对照检查为120份owner+完整校验journal；IME18f…核心及后续20事务/save161/fresh全文PASS，raw49旧fresh rect时序单列。PNG a01…0、20public重叠02e…0、同editor typed资源0d77…0（364→365→364）各真实原件保留。portable001d…0/SystemPATH仅包内三x64/22事务，ZIP78f285c1…；快捷方式即时read1及独立read0/最终record0分别保留。详见任务页windows-r6-final-delivery-20261009和../20261009-r5y/r6-*-full-byte-check.json。新源码native archiveb498…及BCdb0d…实际捕获493c…0、SDK双恢复；Mac fresh llc10939和正式relay/独立链仍在途，不用旧独立产物替代。


r6最终收尾：83c0a879…正式独立source build0/BCdb0d…/新Mac1162.030s objf93d…/EXEda3027c8…；7ab2bff2…独立默认完整Shift写作链0/PID18076→4024/22事务及10全文save151/fresh152复算PASS。最终源码ZIP22247df2…/MF8e46b6a6…/142实际文件141载荷，7a785238…新空含空格目录全SHA/bytes/VerifyOnly0，无target复制；应用ZIP78f285c1…同主EXE2424…保持。be6d16c4…0/152准确channel路径退休，31具名editor无活消费者、SDK原件双恢复。worker15032末typed560/File41/Unknown151，资源快照548另列；121批BYE/socketclosed，聚合exit1来自保留RED。准确后检15032/conhost5692/TEMP pharos-worker目录不存在、8792/8802无监听；首次猜测错目录不作为证据。r6-final-delivery-and-cleanup.json保存全部原件；原A–F在256KiB/来宾范围完成，NOT_RUN/unsupported与旧原始失败保留。现行完整12门、应用/source入口及范围见任务页windows-r6-final-delivery-20261009；无stage/commit/push，E/H与旧用户候选保留。
