# H R1–R4 收口证据索引（2026-10-02 执行者轮）

> 当前结论（2026-10-04 round18指导验收）：固定完成门独立复跑6/6、8/8、选择5/wire3及六份真实原件全部通过，confirmed统一迁移接线成立，本段工具收尾正式结束。[验收结论](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round18-tooling-accepted-20261004)与[本次原始回执](guidance-review/round18-acceptance-runs.json)。正常消费/R-C原证有效，旧指导不再是待执行清单。

范围：h-source-preview-followup-20261001 的 R1–R4 整包。平台指纹 `1fae9972ffe5fbc0c8837c30275b8de59697beb1150e7beb3ad455c6db897fec`。

## 构建与运行身份

| 产物 | 身份 | 断言 |
| --- | --- | --- |
| Pharos normal HAP | `7b85cb391e819137c9d18069030985acc17bfc4c54439150dc48d849714f9629`（run_20261002_114127） | 重链不变量/闭包/启动断言全绿，首启 PID 6301 |
| thermo normal HAP | run_20261002_114428（lab=ohos_thermo_app，CJGUI_APP_PKG_LIB=libcjgui_thermostat_application.so） | 同上全绿，PID 9698 |

## R4（检查器先行＋设备总门）

- 总门重写：`verify_pharos_dual_owner.py`（冻结 confirmed 选区→strict_utf16 独立期望→逐字节精确；单次 toggle；OWNER_STATE 唯一权威；非空 READ 核 AVAILABLE/长度）。
- 负控转正：`scripts/test_dual_owner_negative_controls.py` — 正控 exit0/OK；wrong-note-range、destructive-A-resume、zero-input、duplicate-write、missing-install-confirm、stale-log、note-cleared 全部 exit≠0（对真实 main AST）。
- **设备最终运行**：`dual-owner/dual-owner.json` — status **OK**，required_values 10/10（b_replace_exact_owner / a_resume_exact_owner / removed_is_zero / b_install_confirmed / exactly_once×2 / 双 owner 不变 / 再访保持）。运行身份与 A 侧冻结 caret [63,63)（=合法收拢后输入落新 caret 的设备事实）见 JSON。
- 运行注记：hilog 洪泛会冲掉 accepted 转储，运行前清缓冲＋全局 I 级；结束后已恢复 D 级。

## R1（renderer）

- 机制：`editingBornTicketId`（绑定出生票据）替代 `acceptedProjectionVersion < base` 宽限；`beginEditingOnNodeLocked` 完整绑定幂等（+kind/semantic/epoch）；`Session::PendingEnd` FIFO＋`pushPendingEndLocked` 统一收场出口（tap/跨绑定切换/kill×2/finish/回车全入口冻结将死身份；pump 按身份逐条投递；`imeDetach` 仅在无更新活上下文时执行——该函数当前从未 attach，为语义守卫）。
- 回归：`test_s2_identity_handoff_native.py`（正控 end→A、finish(A)→bind(B)、同 id 换 epoch、完整幂等、pre-binding 票据不杀/版本回退仍杀、外部换版重建 born 随结算票据）＋三个变异负控（去 epoch、换回版本阈值、去 finish 冻结均红）。
- 上轮遗留破测修复：`test_touch_gesture_native.py`（副本字段+clamp/push_end 提取）、`test_selection_handles_native.py`、`test_generated_reorder_editing_context.py`（陈旧"重置为 caret"期望改为 R3 保持非空选区语义）。

## R2（共享 ArkTS 生命周期）

- 机制：`CjguiImeSelectionLifecycle` 固定截止（scheduleDeadline 8000ms，settle/arm/invalidate 清理，旧请求不误伤）；`hasImeTrafficEvidence(mount)` 按挂载（`CjguiTextProxyMount.trafficSeen` 由 registry.onChange 真实改文置位）；`commitInstalled` 回传 native rc，rc≠0 → UNCONFIRMED；回声票据门 `consumeSelectionObservation`/`noteTraffic`（程序命令回声按括号消费；合法收拢=事实上报）。
- 页面：Pharos/thermo 的 `onProxySelectionChange` 改票据身份分流，删除"非空→折叠"形状守卫；`onFrameworkEnd`/`recordProxyFinish`/挂载换代调 `invalidateAttachmentFor`。
- 回归：`test_s2_shared_lifecycle.cjs` 11 用例（成功链/getter 异常/12800009 无证据退避耗尽/有证据开门/失配终态/旧序号不开门〔rejects 已按 case 隔离〕/非 12800009 拒绝/永挂截止/证据按挂载/native 拒绝/回声门）；`test_menu_install_gate.cjs` 18 用例重建为真实共享类 fixture；`test_ime_selection_host_seams.cjs` 两消费者 host 契约（含 [result.json](../../h-seam-consumers-20261002/result.json)）。

## R3 输入腿闭合（2026-10-02 执行者第二轮：生成 TEXT 字段通用范围会话桥）

- **框架（snapshot＋主树镜像）**：`CjguiGeneratedUiBindingProvider` 新增五入口（applyTextEdit＝owner 事务内整值应用＋版本校验、rangeTextEditSupported、fieldTextVersion、confirmFieldTextVersion、rebaseFieldTextSelection，默认拒绝/不支持→行为与之前完全一致）；新文件 `composable_ui_generated_range_session.cj`（`CjguiGeneratedFieldRangeSession`：Source/Sink 适配，范围重组在桥内按 baseVersion 现值兑现，owner 只做事务）；生成运行时 `handleEvent` 在 TEXT 字段 FOCUS 时按 resolveIntent 同一身份核对 bindRangeTextSession（同身份幂等不重绑；带名理由诊断 `GEN_RANGE_BIND_*`）；窗口 `recordProjectedFocus` 成功点为可编辑节点补发合成 FOCUS 通知（程序化聚焦原本不回发事件——设备断点根因之一；只进 controller.applyUiEvent，无事件环）。
- **thermo**：domain 增备注按版本有界历史（32条）＋`rebaseNoteSelection`（文本不变原样/单处替换平移/交叠 None）；binding 实现五入口（applyTextEdit 走与公开 SET_NOTE 同一 `executeFromHuman` 事务）；窗口配置开 `rangeTextEditDeltaDelivery`；两个备注编辑器（313/942）补声明 `operationResourceId`（此前 -1 连旧整值路径也会 owner_target_missing——打字从未达 owner 的另一半根因）。
- **设备五腿全链**（`verify_thermo_shared_lifecycle.py`，最终 normal HAP `97ca380b…`，PID 见 thermo-shared.json）：安装确认 [0,0) INSTALLED+rc=0 → 系统输入 `thermo shared lifecycle ok` 精确读回 → 拖选非空 [0,4) 确认 → 'X' 按冻结选区 oracle 期望 `Xmo shared lifecycle ok` 逐字节命中 → 外部 SET_NOTE `外部改版后的备注 thermΩ` applied → 改版后重基选区 [15,15) 确认 → 'Y' 继续输入 oracle 期望精确命中。脚本围栏教训：hilog 全量拉取耗时数秒，动作围栏必须取在动作之前。
- **同源汇合**：Pharos 同平台重建（normal HAP `520218dd…`），R4 双 owner 总门重跑 10/10 OK（[dual-owner.json](dual-owner/dual-owner.json)）；thermo 业务回归 verify_thermo_continuity.py PASS(failures=0)（verify-transport+test-gates 变体构建后跑）；离线回归 19/19。终平台指纹 `be2fab8a…`。

## R3第一轮（消费者接线/产品策略，历史）

- thermo：`ThermoImeSelectionHost`＋`selectionLifecycle` 字段替代内联 `armProxySelection`/`installProxySelection`/`proxySel*`（退役断言 `test_proxy_selection_install.cjs`）；挂载/换 controller/失效对齐 Pharos 同款。
- Pharos：`bindNoteSession` 接 `pharosOhosArmSmallDocumentCapacity`；`noteProjection()` 按 (documentId, contentVersion) 缓存（同版零重复读）。
- **设备**：thermo 真实触摸定位→共享类 attach/两帧确认 `terminal=INSTALLED target=[0,0) mount=app1/s1/c1/e1/m1`＋`rc=0`（`thermo-shared/thermo-shared.json`）。
- **第一轮当时缺口（精确断点；第二轮报告见上节）**：打字后 native `ime plain change NOT owner: enabled=0 declaredNode=0 editingNode=942`——生成 UI TEXT 字段无 owned 范围文本会话（composable_ui_generated 无 bindRangeTextSession；`CjguiGeneratedUiBindingProvider` 无 owner 事务内文本写入口）。该缺口本包之前即存在（旧 thermo PASS 为按钮＋外部 SET_NOTE）。下一单元：框架通用生成字段 range 桥＋provider applyTextEdit＋挂载期绑定；thermo domain 实现后跑"安装→输入精确替换→外部改版→继续输入→读回"。

## 回归汇合（离线 19/19）

dual-owner-negative-controls、s2-identity-handoff、lifecycle-counter-baseline、generated-reorder、touch-gesture、selection-handles、plain-mount-echo、ohos-ime-selection-event、focus-composable、text-multitap、ohos-ime-caret-notify、ime-range-delta、ime-context-capacity（py）＋ s2-shared-lifecycle、ime-selection-host-seams、menu-install-gate、proxy-selection-install、text-proxy、text-menu（cjs）。

## 边界

不重跑旧 N1–N4/全矩阵；未 stage/commit/push；自有转发与自有实例（两轮）已回收；用户 7856→7856 保留；hilog 恢复 D 级。模拟器键盘注入按既有标记为 uitest 注入（非人工物理输入）。模拟器键盘注入按既有标记为 uitest 注入（非人工物理输入）。


# R3补轮（2026-10-02 指导四项）收口补录

## ①正典同源
- canonical：`runtime/cjgui/examples/thermostat_application/src/{thermostat_app,thermostat_generated_region}.cj`（provider 五入口/备注历史重基/两处 operationResourceId）。
- 双轮同步验证：原 rsync 块 + CJGUI_APP_SRC 参数化，两轮后 wiring 完整（本轮执行时实测 exit0 两轮）。
- 最终 thermo normal：独立装配目录 `labs/ohos_thermo_asm_r3`（排除 build/oh_modules/.hvigor/cjgui/cpp/proxy/thermostat_application/settings_counter_application 后由正式入口同步重建），HAP `c48875dd0db9d693c8e35e3ada0173619bcdce10fba25526d95b2a739baa1a1a`，启动断言全绿，run_20261002_1649x。

## ②活动会话绑定（框架 snapshot+主树）
- 窗口新访问器 `ownedTextSessionBoundNodeId()`；region 钩子重写：accepted 目标先验证（semantic/kind/resource/field/writer/ownerTarget 全等）→ 窗口会话+完整 memo 三重一致才幂等跳过；迟到旧 FOCUS `stale_focus_not_accepted` 具名拒绝。
- 诊断经 `composable_ui_generated_region_diag.cj`（OHOS=hilog / macOS=空实现），共享 region 文件双树同源。
- 回归 `scripts/test_generated_range_binding.py`：cjc 编译**真实生产方法**（提取），8 判例（正控/幂等/A→B→A/换semantic/迟到FOCUS×2/关闭重开/provider 不支持）+ 两变异负控（去窗口会话检查、去 memo semantic 比较）。

## ③总门
- `verify_thermo_shared_lifecycle.py`：`_HILOG_PID` 列严格匹配（子串误配反例闭合）；`confirmed_selection(rows, fence)` 配对限围栏后、mount 发现全量；`expect_exactly_once` 冻结版本+逐字节期望+版本增量恰一次（键盘注入粒度=码元数，如实记录）；fport 创建确认+`fport ls` 匹配才 rm。
- 负控 `scripts/test_thermo_shared_driver_negatives.py`：错 PID/旧确认复活/创建失败清理/正控 4 项全绿。

## ④R1 提交来源（renderer）
- `PendingSettlement.sourceEditingContextId/sourceEditingLive`（present 锁内冻结）；`pendingSettlementSourceStaleLocked` 在 settle 不可逆晋升前整票拒绝陈旧来源（named `stale_source`）；sync 票号宽限与 `editingBornTicketId` 整段移除。
- 可达性论证：present 在锁内冻结后解锁等待渲染 job；UI 线程 begin(B) 与 present/settle 经同一 `g_sessions.lock` 串行 → present(来源A)→begin(B)→settle 可达。
- 回归 `test_s2_identity_handoff_native.py` 重写：8 判例 + 4 变异负控（stale 检查禁用/版本阈值宽限重引入/去 epoch/去 finish 冻结）。

## 生成 TEXT 设备消费（thermo 装配 HAP c48875dd）
- `verify_thermo_shared_lifecycle.py` 九腿：候选提交（CANDIDATE_ACCEPTED）→accepted 节点 component-2-1→触摸聚焦→安装确认→'G1' 恰落冻结 caret [1,1)（oracle '外G1部…'）→'X' 替换 [0,4)→外部 SET_NOTE→重基 [15,15)+'Y'→切手写备注 [12,12)+'H'→回生成编辑器 [1,1)+'G2'——全部逐字节命中、版本增量恰等。证据 `thermo-shared/thermo-shared.json`。
- 页面修复（labs/ohos_thermo_app entry 源，entry 配置权威在 lab）：代理 controlId 按挂载唯一；跨上下文焦点切换走卸载→onDisAppear→重挂（ImeReconcilePending 泛化 targetField）。

## 终态汇合（冻结指纹 fead3d89…）
- Pharos 冻结 HAP `5e5e5e0a…`（run_20261002_165x）R4 双 owner **10/10 OK**（dual-owner/dual-owner.json）。
- thermo 装配冻结 HAP `c48875dd…` 九腿 OK（thermo-shared/thermo-shared.json）。
- 离线受影响回归 21/21（含本补轮新增 4 套件）。
- macOS：主树 `cjpm build` 成功；`cjpm test` 链接缺口（press_lease 引用 `cjgui_internal_renderer_test_composable_drawable_pixel`，当前 native .a 不导出）为既有问题——两文件均非本包改动（git 实证）。

## 环境与归属
- 设备 7856 曾被 12:57 启动的旧 overnight 测试实例（bundle `com.pharos.mark.hovernight20260930`，09-30 HAP）占持 → 本轮 R4 前两次失败为误测（OWNER_STATE 缺失即旧包特征）。已 `aa force-stop` 该 bundle（未卸载，可重启）；当前 build 接管端口后 OWNER_STATE 恢复。
- Pi 咨询一次：`/Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/consultations/gen-field-proxy-divergence/`（其 seed-空重建被设备证据修正——实际 accepted value 非空、三方分歧根源是陈旧字段回放；采纳其 R2 页面回放门方向与同源化分析）。
- 未 stage/commit/push；hilog 恢复 D 级；自有转发（28997/17857）与实例按轮回收，用户 7856→7856 保留。


# round5-B 执行者补录（2026-10-03；顺序结论已由下方指导复核更正）

## B：真实 T2 顺序（设备，failures=0）
- 判据修正：`decide_t2_ordering` 业务终态改**归档帧**——T2 请求后恰一条 `APPLIED true` 回包且逐字等于 T2 回包；`VERSION_BEFORE` == 入队前 owner 版本（冻结基线）；读回 `VERSION_AFTER` 一致且正文恰好多 1 字节（单笔应用）。根因：公共 REPLACE_RANGE 的终态在传输账本，`PHAROS_OHOS_EDIT` 只记窗口 IME 会话判决（t2-verify4 的 `not_unique:0` 即误用）。
- 帧路由修正：`t2_business_request` 经 `EX.exchange_strict`（原 `m.request` 不归档，归档尾部看不到 T2 回包）。
- 设备证据：[t2-verify6](round6/t2-verify6/result.json)（verify-transport+test-gates 产物，终验实例 PID 12364（按 result.json 更正））——T2(request 9) 入队时 T1(ticket 7) 等待在飞行（7 ∉ 入队快照 [1–6]）；owner-claim 行(15) 晚于 T1 终态行(14)；归档恰 T2 回包、版本 3→4、字节 +1；对照组（无 hold 恰一票、许可前 hold 期间零 Flush、释放后 U 票成功、重铸上界）全绿。原始 [运行日志](round6/t2-verify6.log) 与归档 raw.json 同目录。
- 离线负控：[test_t2_ordering_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_t2_ordering_negatives.py) 9 判例；[replay 负控](../../runtime/cjgui/platforms/ohos/scripts/test_r1_pre_permission_replay_negatives.py) T2 GREEN/M16 锚点迁移归档语义（148 项 failures=0）。

## Harness 漂移修复（round5-C 引入后未更新）
- selection 事件测试：补 `editingBindingHealthyLocked` 提取（takeEditingContextLocked 引用）＋副本 `editingAcceptedBindingEpoch/editingFieldName`＋`isEditableTextKind` 桩，11/11。
- binding 测试：`internalRendererWindowLog`→`generatedRegionDiagLog`（双树诊断拆分），3/3。

## 复用与边界
- 本轮无新共享生产改动（仅工具/harness）；A 恢复配对与 C 人锚 36 号码按当前源码复验全绿；离线全套 **26/26**。
- round6 Pharos normal（R4 11/11）与 thermo normal（9 腿 OK）原件直接复用；N1–N4、图片/惯性、macOS、E 大文档未重跑。
- 设备：hilog 恢复 D 级，自有实例/转发回收（t2-verify6 用 28865 已释放），用户 7856→7856 保留；未 stage/commit/push。

## round6 指导复核（2026-10-03，A–D 未收口）

上段failures=0为执行者当时判据结果，不再作为T2顺序通过结论。[新反例和源码指纹](guidance-review/round6-review.json)保留当前格式正控与四条误接受：旧ctx完整恢复对、未来T1/READ冒充、同长度错正文、单笔版本跳跃。原raw第65项request9已pending，4.000173s后第66项才发送REPLACE_RANGE；当前归档不能把两者关联为同笔写。最终PID是12364/token tbac32e，原20661口径错误；需补同PID原始wait-enter/enqueue/exit/claim流，现有摘要下标不足。

[C生产提取测试](guidance-review/round6-anchor-review.json)在独立临时target只跑新反例：40次立即pump，0ms读数，持续ANCHOR_PENDING却calls=11/attempts=8/failures=1，测试RED；[原始输出](guidance-review/round6-anchor-review.log)。没有2500ms等待截止。正常Pharos/thermo功能和完整owner原件继续保留，不能抵消该未闭合等待机制。本次未操作设备或改生产；接续要求集中于[原H任务](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)。


# round6 A–D 执行者自验补录（2026-10-03；指导结论见下段）

## A 当前上下文配对（工具＋窗口只读事实）
- `body_restore_evidence`：显式票加当前 focus ctx 核对（`restore_ack_stale_context`）；挂载快照要求同挂载 `CJGUI_OWNED_SELECTION_ADOPTED2`（窗口 kind-33 采纳 owned 选区时的新 H 只读事实行：node/resource/kind/sel/projection/binding）；focus 切换退役旧上下文观测与采纳候选。
- 反例复跑：[round6-review.py](guidance-review/round6-review.py) A/B 两组 false_positive 全 false。常驻负控：[test_round6_restore_pairing.py](../../runtime/cjgui/platforms/ohos/scripts/test_round6_restore_pairing.py)（6 判例：当前 ctx 正控/旧 ctx 拒/无采纳事实拒/有事实过/落点不一致拒/焦点切换退役）。

## B T2 同一身份贯穿（工具＋观测分类）
- 编排：基线（版本+全文）围栏前读取；`t2_write_only(version)` 线程只写（不再 read_all——旧读请求入账本即"pending id 早于写帧 4s"反例根源）；requestId＝发送前账本快照差集＋claim 行 `op=REPLACE_RANGE`（生产 `ownerClaimOperation` 补该分类，纯观测）；T1＝发送前行序光标后第一条 `present terminal` 行（票号差集会漏真 T1，verify8 实测）；"入队时已返回"用发送前终态快照（写入即刻入队，轮询检出晚 1–2 个 waitFor 周期，verify10 实测）。
- 业务终态：唯一 APPLIED 回包逐字等于 T2 回包；版本恰 +1（`t2_version_not_exactly_one`）；完整 owner 恰为 `58+before`（`t2_full_owner_bytes_mismatch`，同长度错文拒绝）。
- 转发：`hdc_target_args()` 显式 `-t`（未配置具名失败零命令）；`release_forward` 核 rm 退出码/输出（`cleanup_rm_failed_rc=…`）。负控新增：读冒充写/未来 T1/同长错文/版本跳跃/rm 失败/无 target（[replay 负控](../../runtime/cjgui/platforms/ohos/scripts/test_r1_pre_permission_replay_negatives.py) 166 项 failures=0；[t2 判例](../../runtime/cjgui/platforms/ohos/scripts/test_t2_ordering_negatives.py) 9/9）。
- 设备实验（verify 变体 `d1fc32f8…`）：[t2-verify12](round6/t2-verify12/result.json) failures=0——T1=7（发送后首条 wait 返回行 idx14）＜ T2 claim（idx15），request 9 绑定唯一 REPLACE_RANGE 帧，v3→4 恰 +1，全文=58+before；[ordered_rows.txt](round6/t2-verify12/ordered_rows.txt) 12,556 行可复算有序流随包。中途 verify7–11 为逐步定位（op 分类缺失→T1 配对→发送前快照），日志保留同目录。

## C 单调时间等待（snapshot 生产＋fixture）
- `ownedAnchorWaitDeadline: MonoTime`（开窗冻结 +2500ms）替代"8 轮×3 窗"；`ownedAnchorWaitExpired` 同身份到期一次（后续 pending 按真实 8 次预算，不无限重开）；身份换代/need-clear 撤销旧窗与到期标志；截止具名 `owned_anchor_wait_deadline` 且保留可恢复源锚；真失败仍走原预算。
- harness 时钟接缝：提取方法内 `MonoTime.now()` → `anchorHarnessNow()`（计数校验防静默失效），窗口类持 `harnessClockAdvanceMs`。
- 反例复跑：[round6-anchor-review.py](guidance-review/round6-anchor-review.py) **test_exit_code=0**。fixture 21/21（新增 5 判例：泵频无关/截止一次/截止前确认＋旧截止无副作用/换绑撤销/真失败 8 次预算；旧"12 轮=2 签发"迁移为时间语义）。

## D 受影响汇合（终指纹 4cde3c8e…）
- Pharos normal `ef2c519c81f6ada5c92120ff9c75bf25ee30f3a0451b71d9ffbf38bf3ea05f8a`：一次原锚往返 11/11 OK（含 `a_resume_at_frozen_anchor`；A 在 B 期间版本+完整字节零变化）。
- thermo（独立装配目录＋正典 `CJGUI_APP_SRC`）normal `7dd5decfb2971263ea7d61c5a7bd4923e623762ba55cf66b10fc7e9907b339bd`：15 腿 OK（手写→生成→回访全链逐腿 exactly_once）。
- verify 变体 `d1fc32f80e21e44325e77801a07d777c7ef00fb69094e6c8b2e4e175fa810046`（注：直连框架入口需显式 `CJGUI_APP_PKG_LIB=libpharos_mark_ohos_application.so`）。
- macOS 主树 `cjpm build` 成功（ADOPTED2 事实行只在 snapshot 树——主树 kind-33 已分叉且无该恢复路径）。
- 离线全套 27/27；旧 N1–N4、图片/惯性、E 大文档未重跑。设备清理：用户 7856→7856 保留，hilog D，自有转发/实例回收；未 stage/commit/push。

## round6交付后指导：仍需三处局部返工

[当前函数独立反例](guidance-review/round7-review.json)分别隔离缺陷：A当前身份缺失/别字段换焦/采纳字段损坏仍通过；B保持合法REPLACE_RANGE后，入队在wait之前或之后仍通过，缺边界也通过。旧复合反例被READ拒绝，不能证明未来T1已拒绝。t2-verify12 PID11473的12,557行归档可复算ticket7终态→request9认领及queueUs=1118605，但没有被判据核对的wait-enter/enqueue边界，不能据此判等待区间通过。

[C截止后生产反例](guidance-review/round7-anchor-review.json)及[原始测试输出](guidance-review/round7-anchor-review.log)：native持续码36，2600ms时终结等待，再40次pump，调用1→9/attempts8/failures1，终态被覆盖；新的单测RED。到期前40次不烧预算的已修证据保留。Pharos final3完整137B→140B已由指导独立复算，正常消费功能保留；本次没有重跑设备或修改生产。固定方案与验收只在[原H任务](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)，不新增任务卡。

## round7 执行者原记录（2026-10-03；受下方交付后复核限定）

平台指纹 `8dc64ba06485ab412ba6257be7e3e0b03f9dedee597bacd368f670a5db77b76c`。
详细逐项与边界见[原节 round7 结果](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)。

### A 当前身份元组
- 生产（只读日志，未改 Node/Event POD）：`platform focus` 补 `resource/kind/binding/v`；`ime selection observation forwarded` 由「仅 `!changed` 打印」改为**每次转发都打印**并补 `node/resource/kind/binding/v`；`CJGUI_OWNED_SELECTION_ADOPTED2` 补 `owner_version`。
- 检查器：[verify_pharos_dual_owner.py](../../runtime/cjgui/platforms/ohos/scripts/verify_pharos_dual_owner.py) 的 `_current_edit_identity` / `_latest_observation` / `_identity_mismatch` + 重写的 `body_restore_evidence`（通用 `field=` 解析、当前身份缺失/换焦/分量缺失具名拒绝）。
- 反例：[身份元组 16 例](../../runtime/cjgui/platforms/ohos/scripts/test_current_identity_tuple_negatives.py) 绿；既有 [dual owner 负控 19](../../runtime/cjgui/platforms/ohos/scripts/test_dual_owner_negative_controls.py) 绿。
- 设备：[pharos-final/dual-owner.json](round7/pharos-final/dual-owner.json) `a_restore.source=mount_snapshot`，`current_identity={ctx:7,node:107,resource:1,kind:10,binding:36,v:36}`，观测 `complete=true`，ADOPTED2 逐字段相等，`owner_version=2` 对上 BIND_OWNER；`a_resume` 逐字节相等 / `exactly_once` / `removed_is_zero` / v2→3。

### B 真实阶段边界与 --target
- 生产：`cjgui_ohos_observation_seq()`（`std::atomic` 单调，跨 C++/仓颉唯一全序域）；`present wait enter|exit … seq=`；transport `stage=enqueue … seq=`（BRIDGE_LOCK 内、紧贴 `queue.add`）；`owner-claim` 补 seq。判据不读 hilog 行序/时间戳。
- 反例：[t2 边界 18 例](../../runtime/cjgui/platforms/ohos/scripts/test_t2_ordering_negatives.py) 绿（含「行序倒置不改变结论」）；[replay 负控 243 项](../../runtime/cjgui/platforms/ohos/scripts/test_r1_pre_permission_replay_negatives.py) failures=0（新增 M18 入队晚于 exit、M19 T1 配对截单）。
- `--target`：`main()` 必填；`hdc_run` 统一注入 `-t`（唯一设备出口）；rm 后复查映射；`forward_cleanup`/`target` 落 result.json 并折进退出码。
- 设备：[t2-verify/result.json](round7/t2-verify/result.json) failures=0 —— `t1_enter_seq=127 < t2_enqueue_seq=128 < t1_exit_seq=129 <= t2_claim_seq=130`，T1=24 / T2 request=41 唯一配对（`t1_basis=open_wait_interval_at_enqueue`），v11→12 恰 +1，`forward_cleanup=removed`。verify 变体 HAP 见 [build-pharos-verify.log](round7/build-pharos-verify.log)。

### C 到期终态
- 生产：`restoreOwnedTextSelectionAfterAcceptedScene` 换代键并入 sel16 + `ownedSelectionIntentRevision`（本编辑面专用）；`ownedAnchorWaitExpired` 终态直返；显式重试 = `needsNativeSelectionRestore` false→true 边沿；`finishAcceptedScene` 仅在未记具名终态时写 `"none"`。
- 反例：指导 [RED 原件](guidance-review/round7-anchor-review.json)（`calls_final=9 attempts=8 failures=1`）**未改动**；[修后 GREEN 另存](round7-fix/anchor-review-after-fix.json)；[窗口接缝 24/24](../../runtime/cjgui/platforms/ohos/scripts/test_window_restore_adoption_snapshot_cjpm.py) 含 4 个新用例，5 条 RED 变异全被拒（新增 expired-direct-return、generation-key-drops-selection）。

### D 受影响消费
- thermo normal HAP `2ee99f8e18649647063ee09fc351b94a4e9f0e7938043b764a6cfdce406c175e`：[thermo-shared](round7/thermo-shared/thermo-shared.json) **status=OK 9/9**（install / input-insert v+26 / nonempty-select[0,4] / exact-replace v+1 / external-set / post-external-select[15,15] / continue-input v+1 / generated-select+input / hand-revisit+generated-revisit）。
- Pharos normal HAP `f99f825cedbbd9252842f02b940c4a2f4e175e9fca3251e23c51cdcf5bdfa924`：**部分绿**——A 身份链与 A 续写逐字节成立（见上），但「再访 B」步未绿：首跑 `revisit_tap_failed`、复跑 `preview_mode_not_reached`（首个切换即 `toggle-timeout`，见 [rerun](round7/pharos-final-rerun/dual-owner.json)）。原“模拟器点击抖动”归因已撤回：下方复核原件证明ACTIVATE已送达，仍需最终accepted与观察有效性定位。
- macOS `cjpm test` 链接失败为**本轮之前既有**（测试专用符号在 `#ifdef CJGUI_INTERNAL_TESTING` 内、sidecar 脚本不定义该宏；加宏编译即出现），属 E 写集未动；框架 `cjpm build --skip-script` 成功。
- 清理：自有实例 `com.pharos.mark` / `com.example.cjguithermo` 已按准确身份 force-stop；本轮两条转发已自清理；用户 `7856→7856` 原样保留。未 stage/commit/push。

## round7交付后指导复核（2026-10-03）

- [当前函数与原件复算](guidance-review/round8-review.py)、[结果](guidance-review/round8-review.json)：A三条独立假绿与一条真实格式漏判；B四边界127/128/129/130、唯一T1=24原证保留；D两次按钮ACTIVATE确已分发，按PID/行号保存决定性事实与LOGLIMIT，不能归因为未送达。
- [生产恢复＋finish收尾反例](guidance-review/round8-anchor-review.py)、[结果](guidance-review/round8-anchor-review.json)、原RED测试输出已被执行者后续覆盖、不可恢复：当时隔离target单测1/1 RED，Expired的下一次accepted收尾擦除具名reason；calls=1/attempts=0/failures=0机制保持，明确数据/FFI/钟替身边界。
- 本轮身份16例与T2边界18例原套件复跑通过，说明新增反例覆盖此前盲区；没有构建HAP或操作设备/生产源码。完整续做要求仅在[原任务最新指导](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)。

## round8 执行者原记录（受页末指导复核限定：C通过，A/D未闭合）

平台指纹 `b776cd4c70d8396dccff2ccbd50cf70ee24df8bb7b78591ca11de80e0d66b2c9`。
逐项与边界见[原节 round8 结果](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)。

### A 恢复证据生命周期配对（执行者自验；独立反例仍失败）
- 检查器：[verify_pharos_dual_owner.py](../../runtime/cjgui/platforms/ohos/scripts/verify_pharos_dual_owner.py) 新增 `_mount_lifecycle`（事件顺序维护代号）＋重写的 `body_restore_evidence`。退役信号全部来自**既有生产日志**（`platform focus` / `proxy released by framework ctx=` / `proxy restore terminated`），**未新增日志、未改 Node/Event POD**。
- 两处真实缺陷：① 生产 `PHAROS_OHOS_RESTORE_ADOPTED count=2 failed=2 pending=false request=4 …` 因 `failed`/`pending` 夹在 count 与 request 之间，旧正则 `count=(\d+)(?: request=…)?\s*$` **永不匹配** ⇒ 显式 ACK 路径被静默漏读（设备结果退回 mount 路径）；② ADOPTED2 的 `owner_version` 由可选改**必填**。
- 反例：[test_mount_lifecycle_pairing_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_mount_lifecycle_pairing_negatives.py) 23 例 failures=0。round7 的 `test_current_identity_tuple_negatives.py` 是其子集，已并入并删除（业务判据未放松）。

### C 收尾后终态保留（离线＋指导反例 GREEN）
- 生产：`restoreOwnedTextSelectionAfterAcceptedScene` 入口不再清 `ownedRestoreNamedTerminal`；清零只发生在换代块 / need-clear / 成功采纳三处。
- 指导 RED 原件 [round8-anchor-review.json](guidance-review/round8-anchor-review.json) **按字节恢复**（320 B）；修后 GREEN 另存 [anchor-finish-after-fix.json](round8-fix/anchor-finish-after-fix.json) exit 0。
- `round8-anchor-review.log`（RED 原始日志）被首次复跑覆盖且无法逐字恢复；决定性一行保存在同目录 JSON 的 `counterexample` 字段。
- 窗口接缝 24 → **29/29**（新增 5 例全部走 `reviewAcceptedRestoreAndFinish()`，逐字抽取生产收尾守卫），**7 条 RED 变异全被拒**（新增 `terminal-cleared-per-call`、`terminal-not-cleared-on-generation`）。

### D 模式切换（最终accepted未证实，归因未闭合）
- **撤回 round7 的「模拟器点击抖动」归因。** 证据：两次 ACTIVATE 均入队并分发；`owner_state=preview`；owner 线程持续分发公开请求。
- 生产（只读）：新增 `accepted faces v=… ticket=… source=… preview=… nodes=…`（两条 settle 路径同位置）；accepted 全量转储改为**内容指纹变化才重发**。
- 检查器：`scene_face` 按**动作行文本围栏 + 投影版本**取锚，无当前投影面证据即返回「未观测」；具名区分 `evidence-dropped`（已提交但面证据不可得）／`evidence_lost`（围栏被回收）／`scene_not_following`（未提交）；`mode_trace` 增 `accepted_faces`/`owner_alive`/`loglimit`。
- 反例：[test_scene_face_commit_marker_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_scene_face_commit_marker_negatives.py) 9 例 failures=0；既有 [dual owner 负控 19](../../runtime/cjgui/platforms/ohos/scripts/test_dual_owner_negative_controls.py) 19/19。
- **设备（normal HAP `2344ea5b5ee1aff96cb56f22645839cbe92b22097467b23920dfbc427117cc94`，PID 28068）未绿**：状态 `preview_mode_not_reached`，`mode_trace` = `owner_state=preview` / `scene_face=source` / `accepted_faces={v:4,source:3,preview:0,nodes:16}`。切换点后该进程只剩 **49 行 transport**（含 `stage=owner-claim` ⇒ owner 存活且在分发）而 **CjguiRenderer 域沉默 33 秒**，最后一行是 `present wait enter ticket=5` + `ensureSurface dispatch`，此后无 `wait exit`/`faces`/`frame ok`/accepted。原件 [round8/pharos-final](round8/pharos-final/dual-owner.json) 与 [hilog_rows.txt](round8/pharos-final/hilog_rows.txt)。
- 指导更正：同owner线程后续分发排除持续卡在同一次present；不证明该票成功采纳。所谓“按域流控”仅为候选解释，不能据tag沉默直接定因，也不能把删14行日志作为已确定修法。接续需有界accepted状态读回及票据归属，见原任务D固定方案。

### 其他
- B 四边界（`127<128<129<=130`）按指示**未重跑**；已绿矩阵（replay 243、t2 18）复用通过。
- thermo 恢复腿复验**本轮未做**（D 未收口，按「A/C 反例闭合后才汇合」的顺序同批做）。
- macOS `cjpm test` 链接失败仍是本轮之前既有问题（测试专用符号在 `#ifdef CJGUI_INTERNAL_TESTING` 内、sidecar 脚本不定义该宏），属 E 写集未动。
- 清理：自有实例 `com.pharos.mark` 已按准确身份 force-stop；本轮转发自清理；用户 `7856→7856` 原样保留。未 stage/commit/push。


## round8交付后指导复核（2026-10-03）

- [只读复核说明](guidance-review/round9-review.md)、[直接抽取当前函数的反例](guidance-review/round9-review.py)、[输入/结果与原始流复算](guidance-review/round9-review.json)：两正控通过，6边界误判。幂等focus、旧ctx释放、恢复请求终结三种假红；缺绑定、旧代绑定和迟到旧ADOPTED2来源歧义三种假绿。最后一项是证据不可区分性，不冒充设备故障复现。
- [C当前隔离测试](guidance-review/round9-anchor-current.json)、[新日志](guidance-review/round9-anchor-current.log)：29/29，包含生产finish守卫；原round8 RED日志丢失已如实更正，不把同名现文件当原件。当前只跑必要接缝，未重复7条变异/全仓套件。
- D原始行245185为ACTIVATE；245310/245311为ticket5等待与ensureSurface；后续24条owner-claim同TID28268。最后可见faces行2376属于动作前。最终accepted未知，不能把缺日志同时当“未提交”或“已被限流”。新增Pharos语义前缀在通用renderer中的分类随本次观测修复移回产品/驱动。
- B同序号四边界与既有消费按范围复用；A/D闭合后仅一次最终normal Pharos双owner和受影响thermo汇合。指导未改生产/操作设备；E及暂存保留，具体写集/咨询/验收只维护在原任务节。

## round9 执行（2026-10-03：A 闭合；D 模式切换已收口，A→B→A→B 整链未完成）

平台指纹见 `runtime/cjgui/platforms/ohos/FINGERPRINT.txt`。逐项与边界见[原节 round9 结果](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)。
咨询：[Pi→zai-coding-cn/glm-5.3 answer-d](../../artifacts/consultations/h-round9-abcd-20261003/answer.md)（exit 0）。

### A 恢复证据的真实来源（离线闭合，设备复验随整链待做）
- 生产（H 私有只读接缝，**未改公共 Node/Event POD**）：`QueuedEvent` 入队时已冻结 `editingContextId`/`editingContextGeneration`，但公共事件 POD 无此二字段（`_Static_assert(sizeof==184)` 不可扩），出队只剩 `recordIndex` 布尔量。新增 `ohos_renderer_last_event_provenance(session, outCtx, outGen, outSeq)`：per-session 槽、在 `g_sessions.lock` 下**一次读出三元组**（顾问指出的三处实缺陷已全部修掉：进程级槽会跨会话串味、多次独立原子读会撕裂、打印时读会拿到下一条事件的来源）。窗口在 pump 出口捕获，随本迭代消费；ADOPTED2 打印 `source_ctx=`/`source_gen=`，无来源写 `unverified`。
- 检查器 `_mount_lifecycle` 按生产真实状态转移重写：幂等 focus（`beginEditingOnNodeLocked` 对同 live binding 直接 return）不开新代；`proxy released by framework ctx=C` 只终结所指 ctx；`proxy restore terminated` 是请求生命周期不注销挂载；换挂载**一律**清 ADOPTED2/观测/BIND_OWNER（round8 漏了「同 node/field 但 ctx 变」）；缺当前挂载 BIND_OWNER 即拒（round8 空列表整段跳过）；缺冻结来源即拒。
- 反例：[test_restore_evidence_source_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_restore_evidence_source_negatives.py) 25 例全绿，含复核件 [round9-review.json](guidance-review/round9-review.json) 的 2 正控 + 6 反例逐条固化。
- 设备（normal HAP）：ADOPTED2 实测 `source_ctx=1 source_gen=1`。

### D 模式切换（已收口）
- **撤回 round8 的「按域流控」归因**（复核与我本人重算双重否定）。
- 生产只读诊断：中性 `accepted commit v= ticket= nodes= semantic=`（**撤掉** `accepted faces` 里硬编码的 `pharos-editor-body/note/block` 前缀）；H 私有有界读回 `ohos_renderer_accepted_state(session) -> const char*`（当前结算单值槽 + 在途票据 + K=8 票据环 + **面节点清单**），返回形状与既有 `cjgui_internal_renderer_form_event_text` 同一先例。
- 分类分层：通用 renderer 只报事实；产品用 `previewFacts()` 在公开状态线声明 `face=`（与 mode 同线）；驱动用自己的前缀词表独立分类。判据为**三方一致**（产品声明 × 中性事实 × 驱动期望）。
- 反例：[test_ticket_phase_readback_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_ticket_phase_readback_negatives.py) 8 例、[test_scene_face_commit_marker_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_scene_face_commit_marker_negatives.py) 10 例、[dual owner 负控](../../runtime/cjgui/platforms/ohos/scripts/test_dual_owner_negative_controls.py) 19/19。
- **设备（normal HAP，763 项清单，`seam absent`）**：[round9/pharos-final4](round9/pharos-final4/dual-owner.json) 两次模式切换（`ensure-source`、`enter-b`）均以 `owner-state+scene-click` 通过——round8 卡死的这一步已收口。

### 未完成
- **A→B→A→B 整链未绿**：停在 `note_surface_not_reachable`。`accepted commit v=3/v=4 nodes=16` 存在，但归档里 `accepted node=313` 与 `node-rect id=313` 各 0 条——B 面命中点仍靠指纹门控的 `node-rect` 行取物理像素矩形。下一步：读回面节点清单扩到带物理像素矩形。**本轮未做、未验证，不登记完成。**
- thermo 恢复腿复验、A 完整设备复验：随整链同批做，本轮未做。
- B 四边界（`127<128<129<=130`）按指示**未重跑**；已绿矩阵（replay 243、t2 18）复用通过。
- macOS `cjpm test` 链接失败仍是本轮之前既有问题（E 写集未动）。
- 清理：自有实例 `com.pharos.mark` 已按准确身份 force-stop；用户 `7856→7856` 原样保留。未 stage/commit/push。

## 2026-10-03 round9交付后指导复核（当前）

- [说明](guidance-review/round10-review.md)、[直接提取脚本](guidance-review/round10-readback-review.py)、[源码哈希与结果](guidance-review/round10-readback-review.json)、[C++原输出](guidance-review/round10-native-readback.log)。同步成功frame8读7；延迟成功ACCEPTED/frame8读PENDING/frame0；两种拒绝均残留在途；slot复用读旧票；6份分别不一致响应被真实驱动拼成成功。
- A配对25项独立重跑通过。B/C不重开；完整A恢复设备原件随最终D消费补。final4原件保留为备注发现阶段中断，不能升级整链绿。
- 此轮只有指导文档/离线反例，无生产修改、设备操作或stage/commit/push；E段及既有暂存逐字保护。

## round10 执行者自验原记录（2026-10-03；下方指导纠正D1/D3闭合判断，字段错位设备绿跑无效）

平台指纹 `060b356910321c98cb1073e78ee8948ed5e337b6b3aa8f886262f23638d4db23`。
逐项与边界见[原节 round10 结果](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)。
咨询：[Pi→zai-coding-cn/glm-5.3](../../artifacts/consultations/h-round10-d1234-20261003/answer.md)（exit 0；顾问确认 D1 形状可行、指出 `cancelled` 三类混同，并给出 D2 锁序/D3 基线/D4 现成符号裁决）。

### D1 终态统一发布（离线闭合）
- 同步成功发布移到 `submittedFrameIndex += 1` **之后**；延迟成功发布移到 `decision/frameIndex/terminalStatus` **全部落定之后**；延迟拒绝（rollback）**补发布**且只写票据终态、**accepted 保旧**（独立 `cjguiOhosPublishTicketTerminal`，不碰成功发布器）；同步失败/取消**补发布**并清在途。query/ACK/重复结算按既有 `p.settled` 早退，不重复发布。
- `reason(x)` 三值（Pi 咨询 §1）：0=协议内结算、1=present 同步终态失败（`phase==Done`）、2=`phase==Cancelled`，取自 `job->phaseSnapshot()`。
- 反例：[test_readback_publish_consistency.py](../../runtime/cjgui/platforms/ohos/scripts/test_readback_publish_consistency.py) 27 项——**逐字抽取并编译运行**生产 C++ 发布/序列化实现（非手造串），含 5 项源码级发布时机检查（变异实测有效）。

### D2 session 生命周期与锁（离线闭合）
- 槽绑定 token；`create`/`destroy` 都复位；读回在 `g_sessions.lock` 内完成 token→slot 与身份校验；锁序 `g_sessions.lock → g_acceptedFactLock`。token 不匹配返回**空串**（仓颉侧按 `isEmpty()` 分流，无 null 检查）。修正「全部静态分配」不实注释。
- 反例：同 D1/D2 套件（槽复用隔离、销毁后空读回、全新实例无事实）。

### D3 单份快照判据（离线闭合）
- `public_snapshot`：一次 GET_CONTEXT、一次解析；`current_mode`/`ticket_outcome`/`driver_face` 全部消费同一份。票据环正则吃满 7 段并锚定（原未锚定会静默丢 `/x`）。`action_baseline` + `ticket_verdict`（票号 > 基线、epoch 单调性、reason 四映射）；多面并存具名 `driver_face_ambiguous`；`already_at_target` 单列。
- 反例：[test_single_snapshot_judgment_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_single_snapshot_judgment_negatives.py) 13 项，含**逐字复现 round10 六份假绿**并断言恒不通过。
- 身份守卫最终用 **epoch 单调性**而非 token 相等：见下方「我犯的错」。 **指导更正：这个取舍依赖字段错位假象，当前实现仍有跨token假绿，必须撤回。**

### 设备：**绿跑不成立**
- [round10/pharos-final2](round10/pharos-final2/dual-owner.json) status=OK、四段 `submitted_target`、`a_restore=restore_ack`、续写逐字节——**但该二进制里读回 head 的 `token=%llu` 漏了实参，字段整体错位一格**（同份票环存在真票 5 而 `last=0` 即错位症状）。故不作为收口证据。实参已补齐，探针确认 `token=201 … frame=8 last=11` 对齐。
- 修正后重建被**环境安全删除守卫**拦在重链步骤（按「本轮删除计数 ≥50」拦截，逐轮只增 51→52；未绕过）。thermo 同样被拦（其 renderer `.a` 已按新源码编译成功）。

### D4 有界目标几何 — 未做
备注命中点仍靠指纹门控的 `node-rect` 日志行。Pi 咨询已给出可复用符号（`RenderThread::effectiveClips`/`pointInsideClips`、`physicalToLayout`、`s->surfaceDensity`；**不要**用 `hitTestAccepted` 做几何读出；几何在**发布时**算）与显式截断标志要求。

### 我本轮犯的错
1. 给格式串加 `token=%llu` 漏实参 → 读回字段整体错位；**并据此得出「产品切换时重建会话」的错误结论**（那其实是错位后的 epoch 值）。修正后 token/epoch 各归各位。
2. 身份守卫先写成「token 相等」，正是 (1) 的错位让它看起来成立；改为 epoch 单调性后才对。 **指导更正：此结论错误，epoch是槽内修订，不能替代session身份。**
3. `reach_mode` 重写吞掉模块级 `MAP_ROW`，设备首跑 `NameError`，已恢复。
4. 负控桩三处保真度缺口（状态线缺 `token=`、票环缺 `/x`、模式动作不发新票）让新判据在桩上无法判定，补齐后 19/19。

### 未闭合
① 字段对齐修正后的 normal A→B→A→B 未复跑（环境守卫）；② D4 未做；③ thermo 恢复/输入腿未跑；④ A 完整设备复验与画面/owner 字节对应待同批做；⑤ B 四边界、C 29/29 按指示未重跑；⑥ macOS `cjpm test` 链接失败仍是既有问题（E 写集）。


## round10交付后指导复核（2026-10-03）

保留已核实D1/D2改善；D未收口。实际生产提取与真实reach_mode反例：取消槽环绕后ticket9仍为`ACCEPTED/x2`；动作token201→999仍`submitted_target`；MODE=preview但accepted source仍`already_at_target`。合法已到目标正控通过。手写serializer测试在删掉生产token实参的内存变异下生成代码完全不变，故原格式错位仍会漏检。完整要求集中回写原任务，不另开卡；本次无设备/生产修改。

[说明](guidance-review/round11-review.md) · [反例脚本](guidance-review/round11-review.py) · [原件JSON](guidance-review/round11-review.json) · [native原数](guidance-review/round11-native.log)。修正后GREEN另存，保留本次原件。D4目标几何与字段正确的最终normal Pharos/thermo消费继续；安全删除拒绝须原文留证，不绕过、不因此搁置独立实现。


## round11 执行者自验原记录（2026-10-03；旧D1–D3保留，D4/最终汇合完成判断由下方指导纠正）

- D1 票环完整终态 + D2 生产 serializer 逐字 + `-Werror=format`：[readback 套件](../../runtime/cjgui/platforms/ohos/scripts/test_readback_publish_consistency.py)（35 项 + 双变异负控）。
- D3 同 token 守卫/无动作面匹配/零额外动作，执行真实 reach_mode：[single_snapshot 套件](../../runtime/cjgui/platforms/ohos/scripts/test_single_snapshot_judgment_negatives.py)（27 项 + 3 变异负控）。
- D4 有界目标几何（发布边界冻结、cap=16、三态具名、零提交零帧增长）：[target_geometry 套件](../../runtime/cjgui/platforms/ohos/scripts/test_target_geometry_readback.py)。
- round11 反例修后 GREEN（另存，RED 未覆盖）：[round11-green.json](round11-fix/round11-green.json)。
- 最终 normal Pharos `0840f212…` 单实例 A→B→A→B required_values 11/11 OK：[dual-owner.json](round11-fix/pharos-final4/dual-owner.json)；OWNER_STATE 终态（geo density=3.5/viewport=1320x2622）：[owner_state_final.txt](round11-fix/pharos-final4/owner_state_final.txt)；画面 [screen.png](round11-fix/pharos-final4/screen.png)。
- 同源 normal thermo `ce7106fb…` 手写字段恢复/输入腿 1–6 全绿（exactly-once ×3、外部改版续写）：[thermo-shared.json](round11-fix/thermo-legs5/thermo-shared.json)；生成字段腿 `generated_install_unconfirmed`（平台安装+ADOPTED2 在、ArkTS terminal 行缺）留证不扩写集。
- 安全删除守卫拒绝原件（asm_r3 入口，不绕过）：[thermo-normal-build.log](round11-fix/build/thermo-normal-build.log)。


## round11交付后指导限域复核（2026-10-03）

- [直接生产/实际驱动反例](guidance-review/round12-review.py)、[结果与源码SHA](guidance-review/round12-review.json)、[native原输出](guidance-review/round12-native.log)、[说明](guidance-review/round12-review.md)：当前ctx9/已结束仍读ctx7；旧focus覆盖当前hint使旧ACK通过；9面→1面残留截断；圆角真实命中拒绝驱动点；无表面原点仍返回(0,0)。正文/备注还调用日志定位，不能用按钮消费代替完整D4。
- [四套已有针对性测试独立复跑](guidance-review/round12-existing-tests.log)均退出0，旧D1–D3接受，以上为其未覆盖边界。修后GREEN另存，不覆盖本次RED形状。
- [原件独立核算](guidance-review/round12-evidence-audit.json)：Pharos正文137→140B插入“回”准确，v2→v3，原范围[3,3)/removed=0；备注[0,4)替换后25B且一笔，均保留。正文非空跨切换仍待验。thermo手写长串26笔/替换1笔/续写1笔精确；生成腿终态仍generated_install_unconfirmed，未证无关。
- 指导本次未改生产、未构建HAP、未操作设备；E状态和两仓既有暂存保留。实施只按[原任务R1–R4](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round6-evidence-wait-review-20261003)；旧无关矩阵不重跑。


## round12 执行者修复与汇合原记录（2026-10-03；身份门控结论由round13复核限定）

- R1 权威当前身份（查询时刻 Session 现值；历史 focus 行不得覆盖）：[round12-green.json](round12-fix/round12-green.json)、[mount 套件 31 项](../../runtime/cjgui/platforms/ohos/scripts/test_mount_lifecycle_pairing_negatives.py)。
- R2 读回几何消费（逐条裁剪约束 q=、原点缺失具名、正文/备注/thermo 全量接入）：[target_geometry 套件](../../runtime/cjgui/platforms/ohos/scripts/test_target_geometry_readback.py)。
- R3 正文 span 腿 + thermo 生成字段等价链：[dual_owner 套件 21 项](../../runtime/cjgui/platforms/ohos/scripts/test_dual_owner_negative_controls.py)、[generated_install_equivalence 7 项](../../runtime/cjgui/platforms/ohos/scripts/test_generated_install_equivalence_negatives.py)。
- R4 汇合：Pharos `959d5095…` caret 11/11 OK（[pharos-caret](round12-fix/pharos-caret/dual-owner.json)）+ span 12/12 OK（[pharos-span2](round12-fix/pharos-span2/dual-owner.json)，removed=6B 恰一笔）；thermo `f1ae83d2…` 全腿 OK 含生成字段安装+G1/G2 exactly-once（[thermo-shared.json](round12-fix/thermo-legs4/thermo-shared.json)）；[OWNER_STATE 终态](round12-fix/owner_state_final.txt)。

## round13 指导限域复核（2026-10-04）

- [实际函数/完整main反例](guidance-review/round13-review.py)、[RED最终结果](guidance-review/round13-review-final.json)：新wire的gen使parser漏接（两轮各24/24）；无权威身份main仍OK；观察换ctx得KeyError；thermo冲突身份通过；圆角自动误报但显式点可命中。修后GREEN另存，RED不覆盖。
- [五套既有测试独立复跑](guidance-review/round13-existing-tests.json)均exit0；[原件核算](guidance-review/round13-evidence-audit.json)确认Pharos两种恢复后完整owner精确，thermo HAP哈希与正式构建一致。thermo-legs4只保存摘要，安装四件套需恢复原件或定向补验。
- [复核说明与明确范围](guidance-review/round13-review.md)：默认仅H工具/测试/文档，先原件重判，无生产改动不重建HAP、不重跑历史矩阵。本次指导无设备操作，无生产修改，无Git写操作。


## round13 工具身份链与证据收尾（2026-10-04）

- R1 wire→解析→判定（共享 parse_edit_section 四类、24/24 归档回放、四态权威门）：[wire 回放套件](../../runtime/cjgui/platforms/ohos/scripts/test_wire_parse_replay.py)、[round13-green.json](round13-fix/round13-green.json)。
- R2 观察状态机（变化继续观察/请求号在途判序/耗尽具名/零额外动作）：[dual_owner 套件 26 项](../../runtime/cjgui/platforms/ohos/scripts/test_dual_owner_negative_controls.py)。
- R3 thermo 统一最终守卫（两种安装来源一套判据、逐字段冲突全拒、拖选 human anchor 窗口事实）：[equivalence 套件 22 项](../../runtime/cjgui/platforms/ohos/scripts/test_generated_install_equivalence_negatives.py)。
- R4 圆角定位失败分类：[target_geometry 套件](../../runtime/cjgui/platforms/ohos/scripts/test_target_geometry_readback.py)（point_unavailable ≠ fully_invisible）。
- R5 原件：Pharos caret/span 归档 wire 离线回放全过（未重跑设备）；thermo 同 HAP f1ae83d2 全腿 OK + 四件套有序原件（[thermo-final](round13-fix/thermo-final/)：hilog_cjgui_rows.txt / owner_state_final.txt / identity.txt / thermo-shared.json）。零生产改动、零 HAP 重建。

## round13交付后指导复核（2026-10-04，round14证据）

- 接受R1/R2/R4；四套原测试定向复跑仍绿：[执行结果](guidance-review/round14-existing-tests.json)。
- thermo实际判定函数仍放过9类错误输入，真实wait_confirmed也接受source_gen999/current gen1：[反例脚本](guidance-review/round14-review.py)、[冻结RED](guidance-review/round14-review.json)。
- `human anchor recorded`是native待消费锚；[最终原日志](round13-fix/thermo-final/hilog_cjgui_rows.txt)第19601行记录锚、第20073行已经有同node942/sel13:17的真正窗口ADOPTED2，撤销“拖选不发采纳”解释。
- thermo的有序日志与owner输入事实有效；owner_state_final仅ctx5，不能代表各早前判定时刻。后续在同一最终判据内保存真正用过的每腿原回包/围栏/匹配事实，必要补跑限同一normal thermo。
- wire套件回放真实原回包解析，ACK/采纳正控由身份合成；它不等于Pharos11/12项完整归档重判，原功能证据保留。指导未改生产/验证器、未构建/操作设备，详见[限域报告](guidance-review/round14-review.md)。

## round14 收口（2026-10-04，A/B/C 全闭合）

- **A 归一最终判据**：terminal 配对/等价链只作两种安装凭据，逐一过唯一 `_final_adoption_identity_gate`（ProxyKey 形状、挂载 ctx==读回 ctx、e==读回 gen、观测 sel==凭据选区、ADOPTED2 全字段对观测、source_gen==读回 gen、owner_version==动作前冻结基线、观测≤采纳、当前身份逐字段；人锚分支撤销；按行序取最后通过完整门的凭据）。套件 [equivalence 71 项](../../runtime/cjgui/platforms/ohos/scripts/test_generated_install_equivalence_negatives.py)（round14 九类 RED 全反转＋thermo-final 六腿真实行回放＋缺/改任一来源字段必拒）、[driver 9 项](../../runtime/cjgui/platforms/ohos/scripts/test_thermo_shared_driver_negatives.py)。
- **B 判定点归档**：每腿 `*-judgment.json`+`*-rows.txt`（每轮原回包/围栏/匹配事实/基线/observation_source）；必需归档写入失败 `archive_write_failed` 具名终结、缺件 `archive_incomplete`；[GREEN 复判 r4](round14-fix/round14-green-recheck-r4.json)（11 例＋归档/写失败负控）。
- **C 设备复跑**：[thermo-rerun7](round14-fix/thermo-rerun7/thermo-shared.json) **OK exit0**（f1ae83d2 原样复用，零重建）：安装/拖选[13,17]/重挂[15,15]/生成 G1[16,16]/手写回访[18,18]/生成回访 G2[16,16] 全过统一判据，六判定腿 owner 基线 0/26/28/29/31/32 逐腿精确相等；输入腿 exactly-once 26/1/1/2/1/2。复跑1–6 为 hilog 通道丢行原证（三类：观测行/凭据行/采纳行各丢于不同腿）；[Pi→GLM5.3 咨询](../../artifacts/consultations/h-round14-leg6-obs-20261004/)归因采集丢失非生产缺陷，裁决 attach_confirmed 补位（12 项负控 RED 全拒）＋凭据候选多判＋时间戳围栏＋`hilog -Q off/-b I` 通道修复（已恢复默认）。零生产改动、零 HAP 重建；kind-33 出队侧生产补强留下一轮生产窗口。
- 汇总：[offline-suites-r4.json](round14-fix/offline-suites-r4.json)；交接记录见[原任务节 round14 执行者自验](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-round13-thermo-review-20261004)。

## round14交付后指导复核（2026-10-04，round15证据）

- 正常消费/逐腿归档接受：[六份原回包＋实际行重放](guidance-review/round15-review.json)、[owner全文字节独立核算](guidance-review/round15-owner-audit.json)。六份均obs_row路径，owner基线0/26/28/29/31/32，未使用attach补位。
- 旧判据/driver/归档负控继续通过：[定向复验](guidance-review/round15-existing-tests.json)。
- 七个新工具失败形状已固定：[实际函数反例](guidance-review/round15-review.py)、[RED](guidance-review/round15-review.json)。分为最新选择状态失效、排他围栏、空/变版读回三组；仅离线修工具，不据此否定最终实际编辑结果。
- 详细机制及限域完成门：[说明](guidance-review/round15-review.md)。未操作设备/构建/生产代码，不追加kind33日志开发轮。


## round15 纯离线工具收尾（2026-10-04）

- A 选择状态退役（全量 select 凭据 + 最新选择状态行退役）：[七形状常驻反例](../../runtime/cjgui/platforms/ohos/scripts/test_selection_state_and_fence_negatives.py)。
- B 围栏排他边界（原文行唯一出现游标 / ts 严格大于 / 未知围栏具名未证实）：同上套件。
- C 读回 None/畸形/异常归一 + owner 版本准入（VERSION≠基线具名 owner_version_advanced；projection 推进不受限）：同上套件。
- GREEN 复判：[round15-green-final.json](round15-fix/round15-green-final.json)（七形状 wrong=false + thermo-rerun7 六份原件重放 all-equal/obs_row/gen+owner 全 match）。
- 旧九类 RED 复判 exit0：[round14-green-recheck-r5.json](round14-fix/round14-green-recheck-r5.json)（ok 腿受控 VERSION 30→29 为 round15-C 版本准入后的正控适配）。
- 零生产改动、零 HAP 重建、未操作设备。


## round16 选择轮次折叠与缺版本准入（2026-10-04）

- R-A 选择轮次折叠（sel 变化即新轮次、只评最后一轮、ADOPTED2 跨轮丢弃、pending 跨线程归入）：[round16-green.json](round16-fix/round16-green.json)（selection_cases 5/5、wire_cases 3/3、real_final 6/6）。
- R-C 缺版本准入（VERSION 缺失/非法/推进均具名拒绝，projection 推进不受限）：同上 wire_cases。
- 旧九类 RED 复判 exit0（sha 与当前源一致）：[round14-green-recheck-r6.json](round14-fix/round14-green-recheck-r6.json)。
- 零生产改动、零 HAP 重建、未操作设备。


## round17 轮次所有权收尾（2026-10-04）

- A1 切轮统一退役（obs/select/confirmed/terminal 统一开关点；异 sel pending/confirmed 即退役）：[round17-green-final.json](round17-fix/round17-green-final.json) 四条 RED 反转 + 四正控成立。
- A2 terminal 配对所有权（未消费 confirmed 配对即凭据、配对一次消费、未配对不遮蔽 select）：同上。
- 常驻用例扩至 20 项：[test_selection_state_and_fence_negatives.py](../../runtime/cjgui/platforms/ohos/scripts/test_selection_state_and_fence_negatives.py)。
- 关联重放：[round16 判据重放 5/5+3/3+6/6](round17-fix/round16-review-replay.json)、[旧九类 RED exit0](round14-fix/round14-green-recheck-r7.json)。零生产改动、零 HAP 重建、未操作设备。


## round18 confirmed 轮次迁移收口（2026-10-04）

- 统一迁移入口 `_transition`（OBS/select/confirmed/terminal 共用；confirmed 先迁移后保存）＋矛盾采纳丢弃（异 sel ADOPTED2 不挂 pending）：[round18-green.json](round18-fix/round18-green.json) 6/6（三反例反转 + 三正控）。
- RED 复现原件：[round18-red-repro.json](round18-fix/round18-red-repro.json)（三条 failing 与 guidance-review 冻结件一致）。
- 关联重放：[round17 8/8](round18-fix/round17-replay.json)、[round16 selection 5 + wire 3 + real 6](round18-fix/round16-replay.json)、[旧九类 RED exit0](round14-fix/round14-green-recheck-r9.json)。常驻套件扩至 27 项。零生产改动、零 HAP 重建、未操作设备。
