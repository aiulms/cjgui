# 结论(根因已由源码+日志证实)

你的假设成立，且比"猜归因"更进一步：**事故链每一环都有日志与代码对应**。同时我在当前快照源码里发现 `adoptOwnedTextSelection` **已经存在一个候选守卫**(`composable_ui_window.cj:6271-6278`),但事故运行的二进制显然没有它(或早于它)——下面按"证据/推断"分开说明，并指出该守卫仍缺的三处最小补齐。

## 一、证据链(全部来自 artifacts 与源码，非推断)

时间线(`05-n1-owner-samevalue-r3/after.hilog.txt` + `exchanges.jsonl`):

| 时刻 | 证据 | 事实 |
|---|---|---|
| 11:34:23.185 | hilog:2427 `ime select [0,26)`；exchanges `selection` 标签 `WINDOW_SELECTION pharos-editor-body 0 26`(owner 仍 v12) | 长按全选 0:26 被**正常采纳**:`setSelection16(0,26)`(selectionVersion=12)+`rememberInteraction`→focusedSelection=0:26 |
| exchanges `agent-same-value` | `REPLACE_RANGE 0 1 "@" expectedVersion 12`→v12→13,38B 不变 | owner 外部换版；产品侧 `ensureMirrorCurrent`(frozen controller:234-240)→`refreshMirror` 对 [0,38)@12 做重基 |
| 11:34:25.176 | hilog:2527 `addedLen=12 removedLen=38` | 系统输入"非空恢复"(4 UTF16/12B)在 native 侧本地替换 0:26,发出 kind51 range 0:26 bytes12 |
| 11:34:25.180 | hilog:2535 `PHAROS_OHOS_EDIT ... ticket=-1 ... reason=selection_version_stale owner_version=13 owner_bytes=38` | **早拒**:`submitRange16` 的 `selectionAlignmentBlock`(text_session.cj:784-794)在触碰 owner 前返回；`ticket=-1` 证明没走到 `applyByteEdit`,因此 **`needsCalibration` 未置位**(只有 text_session.cj:2064-2066 owner 拒绝路径才置) |
| 11:34:25.176 | hilog:2529-2530 `ime selection observation ... sel=4:4`、`ime select [4,4)` | 拒绝值的 collapsed 回声(4=被拒插入长度)作为 kind33 紧随入队 |
| 11:34:25.179 | hilog:2534 `proxy restore armed request=1 ... sel=4:4 units=26` | **票据目标已被污染成 4:4**——不是安装失败，是签发时就错 |
| 11:34:25.180 | hilog:2536 `PHAROS_OHOS_EDIT_REFUSED ... selection_version=13 content_version=13 sel=4:4 needs_restore=false` | 回声已被 `setSelection16(4,4)` 采纳并**重写了 selectionVersion=13**(setSelection16:756-772 把版本重新对齐到当前 contentVersion,即"用被拒值把陈旧门修好了") |
| 11:34:25.239-246 | hilog:2559-2561 `installed=4:4 ... reason=observed_installed`、`PHAROS_OHOS_RESTORE_ADOPTED count=1`;result.json `WINDOW_SELECTION 4 4` | native 忠实安装了错误目标；`adoptNativeSelectionRestored(13,4,4)` 成功→WindowAdopted |

机制逐行：

1. 早拒后窗口置 `refusedRangeTextPending=true`(composable_ui_window.cj:2283-2294),但会话侧**没有任何锁**(`needsCalibration=false`、`selectionNeedsNativeRestore=false`——后者是被 `refreshMirror` 的重基失败/投影失败 invalidate 掉的，`invalidateSourceSelection`:461-468 只清版本不清 flag 语义上的"待恢复"位)。
2. kind33 4:4 进入 `adoptOwnedTextSelection`(6262):当时 `needsNativeSelectionRestore()=false` 且 `mirrorFresh=true`(refreshMirror 已跑，contentVersion==sourceVersion==13)→ 两个分支条件都不命中 → 落入 `session.setSelection16(4,4)`(6294)返回 ADOPTED。
3. 调用点 2008-2010:`adoption != NAMED_STALE` → `rememberInteraction(33,4,4)`(6315-6327)把 **focusedSelection 覆写为 4:4**,并 dispatch 给产品。
4. 同一 drain 的 `recoverRefusedRangeTextProxy`(5781):`awaitingCalibration()=false` → `restoredSession=None`(5808 分支跳过)→ 恢复目标取 fallback `focusedSelectionStart/End`(5855-5863)= **4:4** → 签发 sel=4:4 票据。
5. 回执路径 5960-5992:`pending.session=Some`,`confirmProxyRestored` 无锁时平凡通过(695-698 早返回 true),`adoptNativeSelectionRestored(13,4,4)` 成功 → WindowAdopted → focused=4:4。最终 RED:WINDOW_SELECTION 4 4,且会话输入门已被 4:4 重开——"下一笔替换应覆盖 0:26"的不变量被破坏两次(目标丢失+门在错位重开)。

**"不是 setter 失败"的判别证据**：hilog:2534 `armed ... sel=4:4` 在签发时刻就已 4:4,而 2536 的 `needs_restore=false sel=4:4` 证明污染发生在票据签发**之前**的采纳，不在安装环节。

## 二、当前源码已有的守卫及其判定

`composable_ui_window.cj:6271-6278`(现在的快照):

```
// A refused kind-51 edit has already changed the platform value. ...
if (refusedRangeTextPending) {
    staleOwnedSelectionEvents += 1
    return CJGUI_OWNED_SELECTION_NAMED_STALE
}
```

- 事故日志行为与该守卫矛盾(若守卫在运行，回声必然 NAMED_STALE,armed 应为 sel=0:26)→ **推断：过夜二进制早于这段代码**。判别实验：带此守卫重放 05。
- 守卫位置正确：在 `mirrorFresh`/flag 判定之前，恰好封住事故形状(`flag=false && mirrorFresh=true && refusedRangeTextPending=true`);NAMED_STALE 使调用方跳过 `rememberInteraction` 与 controller dispatch(2008-2011),即"具名消费 kind33";锚分支在其后，天然"禁止取人类锚"。

## 三、仍需的最小补齐(不新增 owner/协议，不扩 E 写集)

1. **守卫缺身份范围**(必要):`refusedRangeTextPending` 由**任何**可编辑节点 kind51 被拒都会置位(2284-2294 包括 route 返回 None 走 owner dispatcher 被拒的路径)，而 `adoptOwnedTextSelection` 只判"本会话节点"。多字段窗口中，节点 A 被拒不回滚期间，会话节点 B 的合法 kind33 会被误吞。补:`refusedRangeTextPending && node.nodeId==refusedRangeTextNodeId && resourceId/nodeKind 同` 三元组匹配才消费。
2. **不要**把 `pendingPlatformRestore` 一并加进守卫：选区重基票据(`restoreOwnedTextSelectionAfterAcceptedScene`,refusalRecovery=false)在途期间 `needsNativeSelectionRestore=true` 本就挡住回声值不匹配的采纳，而 H1-R.a 的人类锚解锁恰恰依赖"flag 分支内可取锚"。一刀切会关掉票据窗口内人第一次点击的解锁——回归风险。拒绝恢复票据窗口由 `refusedRangeTextPending` 全程覆盖(签发→回执才清)，无需重复。
3. **receipt 两处**:
   - `pending.session=Some` 的早拒恢复**已经**要求 `adoptNativeSelectionRestored` 成功才记 WindowAdopted(5965-5980)——你问的"actualadopt 到既有 ownedSession 后才记 ADOPTED"对此分支已成立，无需改。
   - `pending.session=None`(5960-5963):现在清 flag、计 recoveries、写 focused,却对**回执时已存在且身份匹配的 ownedTextSession** 零采纳，会话/焦点可能分叉。最小补齐：身份匹配时尝试 `adoptNativeSelectionRestored(会话当前 contentVersion, installed…)`,**失败只具名记账(lastNativeFailure)、不得翻转 ADOPTED**——平台安装事实与票据冻结代会次独立，不能让一个签发时不存在、回执时才出现的会话去 gate 代理回滚的成功账。
   - 顺带修正一处注释与代码不符:`restore_adoption_source_stale` 路径(5971-5980)注释称"下一轮重签发"，但 `refusedRangeTextPending` 已在 5962 清掉，`recoverRefusedRangeTextProxy` 永远不会再签。要么在该失败分支按身份恢复 `refusedRangeTextPending=true`,要么改注释为"依赖会话自身 rebase/anchor 修复记账"。这是既有 receipt 真正需要补的一笔。

## 四、验收(含反例)

GREEN(重放 05 脚本):
- `PHAROS_OHOS_EDIT ... reason=selection_version_stale ticket=-1` 不变;回声后**无**新的 sel=4:4 采纳，`armed ... sel=0:26 units=26`;native 安装 0:26(`observed installed req=1 sel=0,26`);`PHAROS_OHOS_RESTORE_ADOPTED`;终态 `GET_WINDOW_INTERACTION` 为 `WINDOW_SELECTION ... 0 26`;owner 保持 v13/38B/SHA `6e8ea3…b0e48b`。
- **下一笔**输入替换 0:26 被接受(v13→14,正文变为 4 UTF16)或仅因 owner 仲裁被拒——不得再出现任何 selection 门拒绝。

反例(必须不回归)：
- H1-R.a:Agent 换版、无被拒 kind51、人在票据窗口内首击 → `humanSelectionAnchorsAdoptionCount` +1,首键入不被 `selection_native_alignment_required` 丢弃(守卫不得吞真实锚场景)。
- 守卫范围：节点 A kind51 被拒期间，会话节点 B 的 kind33 正常采纳(focused/会话选区随 B 更新)。
- 单元判据：`adoptOwnedTextSelection` 返回 NAMED_STALE ⇔ `refusedRangeTextPending ∧ 身份三元组匹配`(即使 flag=false ∧ mirrorFresh=true,即本事故形状)；否则 ADOPTED。

推断(未在日志中直接可证、不影响修复)：`selection_version_stale` 的直接来源是 `refreshMirror` 重基/投影失败后的 `invalidateSourceSelection`(具体是 `selection_rebase_unavailable` 还是 `selection_projection_unavailable`,日志无 lastReason 细分)；同值写 [0,1)→1B 与选区 [0,38) 边界重叠是重基失败的合理诱因。03(0:22)与 05(0:26)只是样本长度差异，机制相同。
