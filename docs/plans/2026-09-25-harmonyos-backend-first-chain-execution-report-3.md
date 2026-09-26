# 鸿蒙后端优先链 · 第三轮执行报告（A1 present 票据事务）

依据：`docs/plans/2026-09-25-harmonyos-backend-first-chain-prompt.md` 页末
「第三次指导复核与当前完整工作包」；顾问答复
`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/rework3/`。

本轮范围：**A1（PENDING 恢复原事务）的实现 + 闸门可控化**。
A2/A3 未返工（原因见 §4）。

---

## 1. 交付内容

### 1.1 A1-native：票据机制与两个独立入口

`runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp`
+ `snapshot/cjgui_internal_renderer.h`（`native/cjgui_internal_renderer.h` 为同一副本，已 `cmp` 校验）

| 改动 | 说明 |
|---|---|
| `Session` 票据字段 | `nextTicketId`（每会话单调）、`unackedTicketId`、6 个取证计数 |
| `PendingSettlement` 扩展 | 新增 `ticketId / decision / terminalStatus / frameIndex / settled` |
| `settlePendingTicketLocked()` | 替代原 `resolvePendingSettlementLocked()`；**终态写入后保留直到 ACK**，重复调用直接返回同一 `decision` 并计入 `duplicateSettlementCount` |
| `cjgui_internal_renderer_query_present()` | 只读终态。不 configure、不 build、不创建新 job、不再次 Flush |
| `cjgui_internal_renderer_acknowledge_present()` | 幂等；只回收回执并开放下一次提交，不推进帧号 |
| `cjgui_internal_renderer_present_ticket_stats()` | `@C struct` 回执；`available` 字段区分「平台未实现」与「真实 0」 |
| `present_composable_scene()` | **去掉双重职责**：本会话存在未 ACK 票据时，既不结算也不投递，直接返回 PENDING |
| `destroy()` | 未结算即拒绝，返回新状态码 `CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED = 21` |
| `syncEditingBufferAfterAcceptedSceneLocked()` | 从同步成功路径抽出；**同步成功与延迟成功共用同一条收尾**（原延迟成功漏掉编辑缓冲同步） |

`CjguiInternalRendererFrameObservation` 末尾追加 `uint64_t ticketId`（非 0 = 该票据已登记，
调用方必须 query + ack）。**未用 `frameIndex` 代替**：后者只在接受后推进，且不是每次提交唯一。

### 1.2 macOS 同形实现

`runtime/cjgui/native/cjgui_internal_renderer.m`：query 恒返回 `DECISION_NONE`、
ack 为空操作、stats 全 0 但 `available=1`（真实读数，不是「未实现」）。
macOS 是同步提交、从不产生未确认票据，因此不改变原有成功/失败语义。

### 1.3 A1-core：事务与前置结算门

`runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj`

- `CjguiComposableUiPendingPresentTransaction`：`kind`（0 = 完整刷新 / 1 = 交互投影）、
  `attemptId`、`ticketId`、`consumedRequestEpoch`、原 `root/paintScene/previouslySubmittedScene`、
  `participant`、`candidateCommands/candidateDataTransferBindings`、`declaredVersion`、
  viewport 双版本、`settled`。

  保存的可变对象引用都是**本次候选自己的快照**（`cloneForWindowCandidate()` /
  `sceneWithResolvedInteractionPaint()` 的产物），不会被后续候选就地改写。

- `settlePendingPresent()`（前置结算门）：

  | 查询结果 | 对原事务的处理 |
  |---|---|
  | `PENDING` | 保留全部候选与 accepted；不 begin、不 build、不 present、不回滚 |
  | `ACCEPTED` | 用**事务里保存的**版本/绑定/scene 执行接受链一次，然后 ACK |
  | `REJECTED` | 按原提交类型回滚一次，保留旧 accepted，然后 ACK，并安排重新同步 |
  | `DECISION_NONE` | 本地持有 ticket 却查不到 → **协议缺口**（`present_ticket_lost`），不当拒绝也不当许可 |

- `refreshRequestEpoch`：等待期间的新 `requestRefresh()` 推进它；结算只消费原事务记录的 epoch。
  因此「原成功段无条件 `refreshRequested = false`」的缺陷被消除，等待期间的 owner 修改不会被吞。
- `finishAcceptedScene()`：完整刷新收尾链的唯一实现，同步成功与票据结算共用。
  调用方在进入前设 `acceptedCandidate = true`（Astra：收到 Accepted 后须在任何焦点恢复或
  participant 调用**之前**进入不可回滚状态）。
- 接入点：`refreshIfNeeded()` 开头、`refreshInteractionPaintIfNeeded()` 开头、
  `close()`（未结算不得谎称已关闭，native 也会拒绝销毁）。

### 1.4 闸门可控化

`ohos_renderer.cpp` 新增 `extern "C" cjgui_ohos_test_gate_set_flush_hold_ms()` 与
`cjgui_ohos_test_gate_flush_count()`：两个变体都导出同名符号，**生产产物返回 -1 表示闸门不可用**，
不提供任何时序影响；只有 `build_renderer.sh --test-gates`（`-DCJGUI_OHOS_TEST_GATES`）编出的
测试产物才真正生效。

---

## 2. 证据

| 项 | 结果 |
|---|---|
| native 静态库 | `build_renderer.sh` 通过（仅既有 C-linkage 警告） |
| 测试闸门变体 | `build_renderer.sh --test-gates` 通过；`llvm-nm` 见 `T cjgui_ohos_test_gate_set_flush_hold_ms` |
| 核心模块 | `cjpm build --target aarch64-linux-ohos` → **cjpm build success** |
| 完整链路（普通变体，闸门控制加入后） | run `run_20260925_212552`，HAP sha256 `97392a7dd56ebfa95aaedb245100e7c2613eaac984e2c6f9b10c1847b2a29722`，`build_variant=normal`，`log_cleared=ok`，`launch_pid=20804`，manifest 464 项 |
| 启动断言 | 4/4 OK：owner 启动 / 场景提交（`present frame ok (nodes=12)`）/ 宿主导入仓颉入口 / 普通产物无验证接缝 |

首次构建（闸门控制加入前）run `run_20260925_212420`，HAP `d5553aef…`；两次均 12 节点首帧正常，
`accepted node=24/25`（名称/别名）值正确落地。

**结论：A1 的改动未破坏既有同步路径**（同步成功 → `ticketId = 0` → 无票据 → 行为不变）。

---

## 3. 本轮欠项（精确，非「等用户」）

1. **A1 的 PENDING 真机反例尚未跑。**
   闸门控制入口已就位，但**尚未接上应用内触发通道**：需要在宿主桥加 1 个 NAPI
   （或把 `GATE <ms>` 加进 transport 验证接缝的控制 OP），并让 `build_and_run.sh`
   在 `--verify-transport` 路径下给 `build_renderer.sh` 传 `--test-gates`。
   判据（按任务页）：
   - 卡住首帧与正常窗口 Flush，让等待方拿到 PENDING；
   - 等待期间插入新的 owner 修改；
   - 旧候选**仅结算一次**，随后新版本正常提交；
   - 无 `identity_candidate_already_open`、无首帧误销毁、无重复提交、无 native/核心 accepted 分叉；
   - 覆盖 native 最终失败与 close 交错。

2. **`StartingPending` 未实现**（Astra 第 3 点）。当前
   `CjguiMacosApplicationHost.start()` 在窗口返回 false 后仍会立即 close，
   因此「只改窗口内部状态」不足以成立。

3. **交互投影的 PENDING 路径未验证**（已实现代码，未跑设备反例）。

---

## 4. A2/A3 的既有实现被 Sol 复核推翻（未返工）

Sol `surface-stop/answer.md` 明确指出上一轮 A2 的实现不满足判据，四点必须返工：

1. **UI 回调里的 400 ms 静默等待要移除。** `onSurfaceDestroyed` 只标记退休 + 投递任务，
   不得当场 `Unreference`，也不得因等满超时就归还引用或宣称静默。
   引用归还应由渲染线程完成最后一次 Flush + `SurfaceDestroy` + 归还全部使用许可后，
   通知宿主在 **UI 线程**归还。
2. **引用失败不得发布 `active`。** 当前实现 `nativeRefHeld = (refRc == 0)` 后仍发布了 lease。
3. **停止判据不足。** `g_appThread.detach()` 只覆盖引导线程；必须 `join` 真正的 owner。
   全局 `shutdownDone == 1` 不能替代按 `appInstance` 的退出判据（重开后可能是上一实例的值）。
4. **`busyGeneration` 不能充当静默判据。** 它只在测试闸门之后、Flush 之前置位，
   redraw 的 Flush 不在其覆盖内。

Sol 建议的身份键：`appInstance / sessionToken / componentInstance / surfaceGeneration / geometryRevision`
（五个都不复用），并给出 8 条可区分反例（取得许可后 / 创建中 / 绘制中 / 最终提交准入前 /
已进入不可取消提交 / 空闲 / queued / committing 三时机 `stop → await → boot`）。

**未返工原因**：本轮上下文预算用尽。A2/A3 的返工不是「改一行」，
它要引入 `SurfaceRecord` 表、把引用归还移到渲染线程完成后的 UI 线程、重做 `StartHost/StopHost`
的实例化判据——按用户「每变更 ≤8 文件」的约束，这是独立一轮的完整工作。

---

## 5. 未提交

按 `AGENTS.md`「未经要求不 commit」，本轮改动保留在工作区，未提交。
