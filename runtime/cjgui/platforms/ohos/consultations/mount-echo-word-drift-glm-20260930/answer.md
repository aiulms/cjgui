# 只读咨询结论：mount 同值回声经 `editorCommitPlainChangeLocked` 塌缩 native 落点

## 1. 根因证据（时间线全部对上，16:14:19–20，非 15:14）

**证据链（log 行号 = actual-install-and-adoption.hilog.txt）：**

| 时刻 | 事实 | 出处 |
|---|---|---|
| 19.185 | word hit painted 5:10；human anchor recorded origin=long_press_word sel=5:10；ime caret notification sel=5:10 caret=10 | 行1148–1153 |
| 19.186–187 | mount（mode=immediate）；requestFocus attempt=0 失败（组件不存在）；setTextSelection 两次失败（JSTextEditableController NULL，reason=mount / reason=caret，均 focused=false）→ `proxySelMount` 仍 armed，重试定时器挂起 | 行1156–1170 |
| 19.196–197 | TextArea 程序回声：`On change previewText len:0` → `ime proxy onChange len=60` → `addedLen=0 removedLen=0`。无 restore task 在飞 → registry.onChange 无 marked → `bridge.preview` → native `ohos_renderer_ime_preview_text_ctx` → `editorCommitPlainChangeLocked`：**caret=60、sel=60:60、清 preview/marked、cancel restore**，随后 `editorEnqueueTextCommit(previous==next)` 落入 `editorEnqueueTextChanged` 发出 **kind-28 整值重复事件** | 行1178–1180；ohos_renderer.cpp:8875–8894、5494–5500 |
| 19.197 | 平台因文本赋值把自身光标重置到尾（华为 FAQ 行为）→ onTextSelectionChange 60:60 → `imeSetSelection(60,60)`：**native_changed=0** | 行1186–1188；ohos_renderer.cpp:9013–9021 |
| 19.202/212 | caret blink active、caret geometry=60 affinity=1（视觉光标已在文尾闪烁） | 行1189–1197 |
| 19.287/520–525 | requestFocus attempt=1 成功；onFocus 栅栏 `installProxySelection(5,10,'focus')` 平台真实装上 5:10（HandleSetSelection 5,10；IMC 60/60/5/10）；getter observed [5,10)；`ime select [5,10)` rc=0。但 `ime_set_selection_ctx` 的 `movingSelection` 守卫（手指仍按住，wordHold drag active/anchorReady/!terminal）**拒绝采纳** → native 仍 60:60 | 行1200–1245；ohos_renderer.cpp:9024–9031 |
| 20.245–262 | END：`kGestureSelectionDrag + wordHold + !moved` → `selectionDrag = {}`「retain the selected word」——保留的是**已塌缩的 60:60**，不产生新 hit；pump 差分（native 60:60 vs selPlatform 5:10）推 `action=caret 60:60` → ArkTS `armProxySelection(60,60,'caret')` → `Set caret position to 60` → IMC 5/10→60/60 → 回声 `ime select [60,60)` → 平台/窗口双塌缩 | 行1391–1412；ohos_renderer.cpp:5409–5411、8506–8537 |

**判别性事实**：19.197 的 `native_changed=0` 证明 native 在平台 60:60 回声**到达之前**就已经是 60:60——唯一能在 19.187（画 5:10）与 19.197 之间写 60:60 的路径就是 onChange→preview→`editorCommitPlainChangeLocked`。20.315 的 projection 4→5（ticket=5、rows=0、units=60）则是 kind-28 重复整值被窗口消费的旁证。

**对归因的两点挑战（成立性修订）**：
1. 「先 cancel restore」这半句在**本 trace 中不起作用**——窗口内没有任何 proxy-restore 票据在飞（长按是人类路径，不是恢复路径）。本 RED 的全部可观测损伤 = caret/sel 塌缩 + preview/marked 清除 + kind-28 重复。cancel-restore 子句对「恢复在飞 + 游离回声」的其它序列才致命，修复应一并覆盖，但不要把它当作本 trace 的机制。
2. 「movingSelection 只挡 ime_set_selection，不挡 same-text mount onChange」——**确认属实**：9024 的守卫只存在于选区通道；提交通道（8875）没有任何等价物，且它先于 enqueue 判同值之前就写了 caret。你的假设主体成立。

## 2. 不同序列的判别实验

- **E1（复现 RED + 一行探针）**：在 `editorCommitPlainChangeLocked` 入口加 `next==s.editingText` 的 RLOGI。RED 重放应看到它在 19.197、早于 60:60 观测；若无此行而 native 仍塌缩 → 存在第二个写者，假设被否。
- **E2（时序判别 mount 先后）**：GREEN 序列（先聚焦安装、后长按）没有「人类锚之后才发生的程序赋值回声」；RED 是 SAVE 失焦→长按（mount 后至）。把 RED 改为长按前预置 TextArea 文本（避免锚后赋值）→ 若不塌缩，触发源确认为 mount 赋值回声。
- **E3（抬指时序判别）**：长按后 <100ms 抬指（focus 重试 19.287 之前）→ 19.525 的 5:10 到达时 movingSelection=false → 采纳生效、native 修复 → END 不推 60:60。若此变体仍塌缩，则 F 步归因错。
- **E4（END 保留语义）**：长按后**拖动**再 END（moved=true）→ 走 `queueSelectionExtentLocked` terminal hit，不走 5411 的保留分支 → 与 !moved 的行为差异确认 G 步。
- **E5（guard 后终态）**：加 guard 重放 RED：native 全程 5:10；19.197 的 60:60 只被转发（movingSelection 挡采纳）不被采纳；END 推 5:10（或 selPlatform 已 5:10 则不推）；终态平台/窗口 5:10；projection 不再无谓 +1。若终态仍 60:60 → 假设或写集不全。

## 3. 最小修复写集

**必改（1 处）**：`runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp` `editorCommitPlainChangeLocked`（~8875），在 owns 判定之后、`cancelProxyRestoreRequest` 之前插入：

```cpp
if (next == s.editingText && !s.previewActive && !s.markedActive) {
    RLOGI("ime plain change echo ignored ctx=... (same text, no composition)");
    return true;   // 已按提交处理：不取消恢复、不动 caret/sel/anchor/preview/owner、不出事件
}
```

- **必须 return true**：否则 `ime_preview_text_ctx`（8916）落入 else 分支，以 previewText 全文 + caret=preview 末尾的形式再次塌缩——同一损伤换通道复发。
- 该 guard 天然覆盖 `ime_commit_text_ctx` 之外的唯一调用方（preview_text_ctx），且 stale context 已由 `takeEditingContextLocked` 前置拒绝。

**可选加带（同文件，~5494）**：`editorEnqueueTextCommit` 中 owned 会话 `previous==next` 时不再发 kind-28（owner 文本未变，整值重复只制造 projection 抖动）。影响面稍大（同值直达 commit ABI 也会被静默），建议独立提交、双向负控。最小修复不含它也能消除本 RED 的选区损伤，只是保留一次无害的重复整值。

**不建议动**：`ime_set_selection_ctx` 的 movingSelection 采纳守卫（真实手柄拖拽的保护，放宽会在拖拽中采纳敌对值）；END 的 wordHold 保留分支（5411，GREEN 路径依赖它）；ArkTS 侧重试/栅栏逻辑。

## 4. 平台回声 vs 真实导航 / 同值 composition 结算边界

- **组字结算净零差**（选中"ab"→组字"ab"→提交）：settle 经 preview_text_ctx 到达时 `previewActive=true` → guard 跳过 → 走提交路径清 preview。**guard 必须含 `!previewActive` 正是为了不吃掉这次结算**。今日行为（caret→尾 + kind-28 + 平台选区回声纠正）不变。
- **组字取消回退原文**：previewActive=true → 同样走提交路径，行为与今日一致（caret→尾是既有瑕疵，本修复不恶化；如要恢复组字前 caret 属后续独立项）。
- **无组字的同值真人提交**（剪贴板粘贴与选区相同文本）：guard 吞掉文本事件是**正确**的——文本无变化无可交付；caret/选区由随后 onTextSelectionChange → `ime_set_selection_ctx` 采纳（无拖拽时 movingSelection=false）。唯一损失是 `caretBlinkResetPending`/affinity 的一次重置，纯外观。这是负控 B 必须守住的反例。
- **恢复在飞**：ArkTS 侧 `proxyRestoreTask.targetText` 已在 520 行附近过滤程序回声，正常情况下回声根本到不了 native；guard 是第二道（task 已清而 native 票据仍活时的游离回声不再取消恢复）。真人取代（value≠targetText）路径不受影响。
- `markedActive` 无 `previewActive` 的组合在现有代码不可达（preview_range 同时置两者），双条件是冗余保险。

## 5. late 60:60 的归属

- 加 guard 后，60:60 的唯一来源是**聚焦前** TextArea 文本赋值的光标重置（19.197）。它会被转发一次给窗口（`selForwardedValid=false` 于 mount 重置，首条观测必转发，8466–8471，这是首字不丢的既有设计），但：拖拽期间不被 native 采纳（movingSelection）、END 后 pump 推的是 native 的人类锚 5:10。**「END 之后才来的 60:60」作为覆盖源就此消失**——END 时刻的权威值是 native 人类锚。
- 结论：**native 人类锚继续做 END 时刻唯一写者；ArkTS pending-selection fence 只作为聚焦前过滤器**（可选硬化：`onTextSelectionChange` 中 `proxySelMount===m && !proxyFocused` 时记日志不 arm/不转发——聚焦前代理 focusOnTouch=false、hitTestBehavior=None，人类不可能在其上导航，该窗口内事件必为程序性，零误伤）。不要把栅栏下沉进 native 的 movingSelection——那是真实拖拽的承重墙。
- 19.525 采纳被挡并非缺陷：若用户此后直接键入，平台按自身 5:10 选区替换 → onChange 文本不同 → 真 kind-51 增量，坐标由字符串差分决定，不依赖 native 旧 sel。

## 6. 确定性负控

- **N0（RED 重放）**：SAVE→失焦→长按 alpha→按住→END。预期：新探针行出现且无塌缩；native 终态 5:10；无 20.315 式 rows=0 的 projection 抖动。
- **N1（guard 不得吃真实提交）**：同序列按住期间注入一次**不同值** onChange/真实键入 → 恰一条 kind-51、restore 被取消、文本更新（对应你说的 Agent 追加行 68:68 已是此类的现场证据）。
- **N2（同值真人编辑）**：无组字、粘贴与选区相同文本 → 无 kind-28/51；选区通道把 caret 更新到贴入点；文本与 projection 均不变。
- **N3（净零组字结算）**：组字==选中文本后提交 → preview 被清、结算照发（探针行**不**出现，证明 guard 因 previewActive 让路）。
- 说明：请求中提到的 tests/脚本 `actualgetter`、`humanselectionanchor` 在两仓按名检索未命中源文件（仅 request.md 提及，疑在 artifacts 驱动脚本内）；上述负控以 hilog 断言（探针行、`ime select`、`native_changed`、projection serial/ticket）即可确定性判定，不依赖它们。

**推断标注**：第 1 节表格为日志+代码直证；「TextArea 文本赋值触发 onChange+光标重置为平台既有行为」引用自 Index.ets:505 注释与 Huawei FAQ（代码内注释为据，非我复现）；kind-28 与 projection 4→5 的因果为强旁证级推断（窗口侧消费代码未读）。
