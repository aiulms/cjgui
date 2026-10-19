已按限定只读四处源码。以下区分【证据】（file:line 实测引用）与【推断】。

## 根因证据（确认成立）

1. 【证据】`editorEnqueueSelectionChanged`（ohos_renderer.cpp:5576–5612）给 kind33 盖的是 `s.editingProjectionVersion`——该值只在聚焦（4645）与外部换版（7503）时更新，**入队后不随场景推进**。
2. 【证据】`resolveSelection`（composable_ui.cj:4810–4813）要求 `projectionVersion != version` 即 `missing`，严格等于当前版。
3. 【证据】window 的 33 分支（composable_ui_window.cj:2015–2031）**没有** continuation 回退；而 27–36/51 分支（2195–2271）经 `resolveLocalTextContinuation → resolveOwnedRangeContinuation`（5791、6260–6280）有 `projectionFloor ≤ proj ≤ version` 的宽通道。51 接受后重投影推进 `nativeInputScene.version`，其后所有 33（仍带冻结投影）在 3 处静默丢弃：无计数、无具名拒绝、不进 `staleOwnedSelectionEvents`。`focusedSelection*`（rememberInteraction，6470+）停在最后一次被采纳的 6:6——与 GET_WINDOW_INTERACTION 观测一致；平台侧 caret=11 是 native 绘制事实（3886 一带），不经此账本。
4. 【证据】每会话单 FIFO、单消费（1097、8632），出队序=入队序；51 与 33 都盖同一 `s.editingProjectionVersion`，所以 51 能走 floor、33 不能，是唯一分叉点。

## 对四点方案的裁决

**recordIndex 可用性**：【证据】窗口侧全文件只有 kind55 读 `recordIndex`（composable_ui_window.cj:5952）；native 对 33/51 从不设置（默认 0）；指针/焦点/activate 的 scene-index 用法与这两 kind 不相交。按 kind 重解释 POD 字段已有先例：55 把 `bindingEpoch` 槽当 requestId（987）。**无冲突**。但它单独不够：dequeue 时要判“同活 ctx”，事件里必须先冻结身份，否则 native 无从比对——你的第 1 点是第 2 点的前置，二者不能只留其一。

**可以更小**：
- 【证据】`Session::editingContextId` 由全局原子 `g_nextEditingContextId.fetch_add` 分配（4648、7500），进程内永不复用；blur（retire）不改号，**retire→同节点重聚焦会走 4618 `wasEditing=false`（因 `editorRetired`）→ 4648 分配新号**；外部换版也换号（7500）。所以**单个 int64 ctxId 即完备身份**，`editingContextGeneration`（=分配时 surfaceGeneration，1323）对身份判别是冗余的。QueuedEvent private 只加一个 `int64_t editingContextId` 即可，不必加 generation。
- 【推断，基于 1–3】**观测到的 r10 缺陷其实零 native 改动即可修**：给 33 分支补上与 51 相同的 `resolveOwnedRangeContinuation` 回退。ctx 判决只在你要求的 blur/refocus 判别上才是承重墙（见下）。
- 你方案 1 里“33 的 text 带全文后像”**建议删去**：51 接受时 `recordOwnedRangeLocalAcceptance`（6277–6322）已证明完整后像并冻结进 continuation；33 再带一份文本不增加判别力（同文可跨 ctx 相同），反而多一条假等价通道。若坚持保留，只作为附加 guard，不作判据。

**blur/refocus 判别（你的硬性要求）**：【证据】该场景下 Source 版本、binding epoch、projection、镜像全部不变——`ownedRangeMirrorMatches`（6250）与 acceptedBindingEpoch 门全部通过，只有 ctxId 变。所以“不能只凭 Source 版本与 binding”成立，dequeue 时 `ev.editingContextId == s->editingContextId && s->editingContextLive && !s->editorRetired` 的 0/1 判决是唯一列内判别子。【推断】dequeue 判 0 后、窗口处理前若发生 refocus，FIFO 里其后的 focus/新 33 事件会按序覆盖，残余竞态窗口极小且被后续事件闭合；如要绝对封死，可在 33 采纳 guard 上再要求 `focusedNodeId/Resource/Kind` 与 continuation 绑定一致（已有）。

## 关键 guard（33 走 continuation 采纳的完整合取）

1. `recordIndex==0`（同活 ctx；==1 → 具名丢弃，见下）。
2. `resolveOwnedRangeContinuation` 全条：projection∈[floor, version]、`ownedRangeMirrorMatches`（bindingEpoch、焦点绑定、contextEpoch、mirrorRevision、contentVersion==sourceVersion、startByte/length/text）、非 awaitingCalibration、非 needsNativeSelectionRestore。
3. 沿用现有 `acceptedBindingEpoch != 0 && currentAcceptedBindingEpoch(resolved)==ev` 门；补 `resolveSelection` 同款文本节点/启用校验（continuation 路径用 `nodeForId`，未做 isText/isEnabled 检查——小缺口，需补）。
4. UTF-16 区间先验合法（start≤end≤镜像 UTF-16 长）再 `adoptOwnedTextSelection`；`NAMED_STALE` 时不 `rememberInteraction`、不动 `focusedSelection*`（现有分支已如此，2038）。
5. 视图语义不变：不置 `requiresProjection`、不 bump owner 版本、不动 `pendingLocalText*`/continuation（拒绝时不 `clearPendingLocalTextValue`，留给后续同活 ctx 的 51）。
6. recordIndex==1 的 33：`staleOwnedSelectionEvents++` + 具名 reason（如 `selection_context_stale`），零状态变化。51 同理在 `routeOwnedTextSessionRangeEdit` 顶部具名 `session_context_stale` 拒绝，不进 owner、不触发恢复、不扰动新 ctx。

## 实现范围

- ohos_renderer.cpp：QueuedEvent 加 1 个 `int64_t editingContextId`；`editorEnqueueSelectionChanged`、`editorEnqueueTextCommit` 各 1 行冻结；pump dequeue（~8634）对 33/51 计算 recordIndex 0/1（+1 行具名 RLOGI）。
- composable_ui_window.cj：33 分支加 continuation 回退 + recordIndex 门（~15 行）；`routeOwnedTextSessionRangeEdit` 顶部加 ctx 拒绝（~8 行）。
- composable_ui.cj / text_session.cj：**零改动**（setSelection16/adoption 现有语义已满足“保留原选区、纯视图”）。

## 4 个判别负控

1. **同活 ctx 旧投影 33（r10 复现）**：6 笔 alpha→alphaH 链后，末笔 33(caret=11, 旧投影) 必须被采纳；终态 GET_WINDOW_INTERACTION=11，owner Source 版本对 33 零变化、native 场景版本零变化。区分“投影陈旧修复”与“ctx 拒绝过度”。
2. **blur/refocus 同 binding 同投影同镜像**：ctx A 下入队 33，点空白 retire，同节点重聚焦（ctx B），再出队 → 必须 recordIndex=1、会话选区保持重聚焦初值、`staleOwnedSelectionEvents+1`。任何只看版本/binding/镜像的方案在此必假阳性——证明 ctx 判决承重。
3. **旧 ctx 51 跨重绑**：ctx A 的 51 入队后 blur+重聚焦且 owner 值被外部改写，出队 → 具名 `session_context_stale`、mirror/owner 不动、不触发恢复；随后新 ctx 的 51 仍被接受（输入门未卡死）。
4. **重复 aaaa 端点分歧**：构造 51 最小差分合法端点 ≠ 平台实际 caret 的重复段场景，其后同 ctx 33 报实际值 → 账本终值必须等于平台观测，不等于差分端点。证明“按实际”由 FIFO（51 先、33 后覆盖）保证，而非差分推导。

## 残留（如实声明）

【推断】同 ctx 内平台若先入队 33、却报提交前坐标（入队晚于 51 但值是旧文本系），ctxId 与镜像均无法判别；r10 证据（select 6→11 随提交单调前进）表明平台报的是提交后坐标，此残留按平台事实信任接受。另：dequeue 判决与窗口处理之间的微窗口依赖 FIFO 后续事件闭合，属既有事件协议的统一假设，非本方案新增。
