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
