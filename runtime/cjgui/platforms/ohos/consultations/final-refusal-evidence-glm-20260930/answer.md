## 先回应你的归因：“Agent 同值换版后下一笔应拒绝”

这个归因把**两件不同的事**压成了一件，四份局部文件都不支持它的普遍形式：

- **被拒的是“携带旧身份的这一笔”**，不是“恢复完成后的下一笔”。`text_session.cj` 的门禁全部是**版本/身份条件化**的：`selectionAlignmentBlock()`（约 800–815 行）分三条具名子句（`selection_native_alignment_required` / `selection_version_stale` / `selection_unprojected`）；`selectedSourceRange()`（约 782 行）注释明说“replacement still performs its own same-version owner arbitration”。没有任何一条按“事务序号”或“上一笔是谁做的”拒绝。
- 你观察到的 v2 拒绝（version_conflict）本身是一个**真实存在的生产形状**——fixture `ohosRefusedDeltaSelectionEchoCannotCollapseAcceptedNonemptyRange`（test 275–350 区段）就是它的 RED：“同值 owner 换版的生产 RED：kind51 因 selection_version_stale 被拒，随后脏代理 kind33 报 4:4……恢复目标必须仍是 0:26”。所以“同值换版后**紧邻的旧版本请求**被拒”是对的；推广成“**下一笔**（已按新版本重基后的请求）也应被拒”是错的。
- 你的 57 秒后人输入被接受为 v4（[11,15) "beta" → “拒绝输入”，正文坐标含前行“前行保留\n”，11:15 恰是全文档 UTF-16 下的 beta 区间）**恰好是 N1 验收判据本身**：“实际非空选区恢复后的下一笔替换落在预期范围”（handoff 309–334，N1 行）。这不是异常，是机制达标的证据。反过来，“恢复完成后下一笔仍被拒”才是 bug 形状——`adoptOwnedTextSelection` 注释里 09-30 04:17 的实测反例（8 次有界重试烧完、`RESTORE_ADOPTED` 从未出现、13 笔输入全部具名拒绝、“输入门再也打不开”）就是设计明确要消灭的形态。

## 1) 自动恢复完成后，下一笔应当接受吗？

**应当，且是机制强制的。** 证据链（均为读到的事实）：

- 拒绝触发 `recoverRefusedRangeTextProxy`（composable_ui_window.cj 约 5800 起）：它把隐藏代理**回滚到 owner 实际接受的值**，“never invents content”，冻结回执身份（epoch/mirror），native 排队安装，**等平台实际安装回执**才走采纳。
- 你的日志 `RESTORE_ADOPTED count=1 pending=false` 对应 `onPlatformProxyRestoreReceipt` 的唯一成功终态（约 6005–6020 行）：票据消费成功 → `confirmProxyRestored` 按原回执身份解锁（`needsCalibration=false`、`selectionNeedsNativeRestore=false`、`setSelection16(安装值 11:15)`）→ `adoptNativeSelectionRestored` 通过 owner 版本守卫 → 才计 `textSessionRestores+=1`、回写焦点/bookmark。
- 解锁后 `selectionAlignmentBlock()` 三条子句全清（`setSelection16` 会把 `selectionVersion` 对齐到当前 `contentVersion`），`handlePlainIntent` 的 `recalibration_required` 门也不再命中；6250 区段显示人输入同样走 `session.replaceRange16` 仲裁——所以 v4 被接受是**通过门禁后的必然**，不是侥幸。
- `failed=1` 的具体来源（哪一次失败记账）在所给四个区段内无法定位，标记为**未决**；但它与 `pending=false`、count=1 并存说明事务已终结、锁已释放。

**结论：把“拒绝 stale 请求”与“拒绝下一笔”混同，会导致验收标准反向**——你会把符合 N1 的正确接受误判为缺陷，或反过来用“再拒一次”当通过条件，两者都是无判别力的。

## 2) 不需要 seam / 概率竞速的合法 normal 拒绝触发

**存在，且是确定性的：用“已观测完成的 owner 前进”制造陈旧版本，而不是用时间窗竞速。** 两个公开行为可选：

- **A（人推进 → Agent 旧版本重放）**：真实长按建立非空选区（owner vN）→ Agent 记下 vN → 人做一次真实 IME 输入，**等待日志/回包确认 owner 已到 vN+1** → Agent 再提交携带 base vN 的 REPLACE_RANGE。预期公开可观察：`APPLIED=false, CONFLICT=true`，具名 REASON ∈ 注册集（version_conflict 或 selection_version_stale，取决于哪个身份陈旧）；`wroteOwner=false`（前后 owner 逐字节差分为空、版本不动）；随后进入拒绝恢复事务 → `RESTORE_ADOPTED`（或具名有界失败）→ 恢复后下一笔新鲜请求被接受并落在重基后的预期范围。**确定性来自“等待已观测的状态前进再发送”，与交错时序无关。**
- **B（Agent 自己的同值换版 → 旧 base 重放）**：即你 r8 实际发生的形状（fixture 已把它固化成生产 RED）。Agent 先完成一笔接受的换版，再用旧 base 重发——同样无需竞速。

**不能**作为确定性 normal 拒绝触发的：把请求塞进 `awaitingCalibration` 窗口（`recalibration_required`）、代理挂载回声窗口、或 8 次重试耗尽/超时终态——这些依赖平台事件交错或故障注入，属于接缝/夹具层（`ohosOwnedRestoreRetriesSameSceneAndStopsAtEightTerminals`、终态后迟到回执不补记成功，均在 test 275–350 内覆盖）。

## 3) 严谨区分“同版本生产接缝反例”与“final normal 消费者证据”

建议预先注册**三层证据标签**，报告里逐条标注，不得互相冒充：

- **T1 接缝/夹具**（确定性制造故障终态）：八次终态停机、迟到回执不补记、echo 不得塌缩 accepted 非空区间、他字段拒绝不阻塞本字段。这是“失败超时终态保留之前”这类判据的**唯一**确定来源（对应 handoff H1-R.b/c“本项补实际生产窗口接缝反例”）。
- **T2 normal 单发消费证据**（final HAP，一次 人→Agent→人）：用第 2 点 A/B 构造确定性拒绝；断言 = 拒绝具名 + `wroteOwner=false` 全量 owner 差分 + `RESTORE_ADOPTED` 身份字段 + **恢复后下一笔被接受且范围准确**（N1）+ Agent 原回包与完整 owner 核对。
- **T3 机会性交错**（r6 的 selection_version_stale 人输入、r8 的 1 秒后采纳）：原日志完整保留（r6 先例），**只记录、不当门槛、不重跑凑绿**。

**防“重试直到绿”的判别设计**：单发预注册，结果三值预声明——陈旧请求被**接受** = FAIL（门禁缺失）；恢复后新鲜请求被**拒** = FAIL（04:17 输入门卡死形状）；同场必须含**负控**：一笔新鲜版本请求被接受，证明门禁只拒陈旧身份（双向判别力）。

**必做仍未完成清单**（按优先级）：

1. **修观察脚本分类**——本次中断的根因是 H1-R.d 类探针缺陷：`APPLIED=false + CONFLICT=true + 具名 REASON` 应归类 EXPECTED_REFUSAL 而非 ERROR，且 EXPECTED_REFUSAL 不得触发中断或注入人输入（57 秒后那笔“拒绝输入”正是误操作产物，制造了“随后有拒绝”的假象）。判决事实应取**判决时**的 decision 记录（`lastTextSessionDecision`/计数器），不得事后重读对齐事实——`selectionAlignmentBlock` 注释里 03:49:30 的教训：“日志区分不出……事后读到的对齐事实又会被同一轮里更晚的平台回声覆盖”。
2. **预注册单发协议文档**（通过/失败/负控三值定义 + 禁止改判重跑；重跑仅限代码变更后重新注册，旧件保留）。
3. **注册场景的正式 final 单发**——r8 这次因脚本中断 + 57 秒人输入污染，只能归 T3，不能当 final 证据。
4. **分层标签报告**：T1 保留为超时/终态/回声判据唯一来源，T2 只认公开行为，T3 原样归档。

**证据/推断边界**：以上机制结论来自四个指定区段与 handoff 309–334/385–393；`failed=1` 的记账来源、以及 base v2 为何判 version_conflict（`replaceRange16` 仲裁体在 650–825 之外）属**未决推断**，建议在 final 断言中直接采信判决记录里的具名 REASON 与 wroteOwner 差分，而不是事后重建门禁路径。
