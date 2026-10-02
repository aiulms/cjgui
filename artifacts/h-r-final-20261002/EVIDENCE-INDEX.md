# H R1–R4 收口证据索引（2026-10-02 执行者轮）

> 2026-10-02指导限域复核：本页为执行者原报告，“全部闭合”不再代表当前验收。正典同步、活动绑定、新thermo驱动及原R1仍待修，见[原任务最新复核](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-source-preview-followup-20261001)与[离线反例](guidance-review/driver-and-sync.json)。原HAP运行摘要保留，不冒充修后最终消费。

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
