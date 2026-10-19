# 结论先行

归因**成立且机制唯一可行**：`editorCommitPlainChangeLocked` 把 same-text no-op guard 放在 `!editorOwnsTextSession` 之后（ohos_renderer.cpp:8905–8912），generic 会话在挂载回声处返回 false，外层 `ohos_renderer_ime_preview_text_ctx` else 分支（8947–8953）把相等正文置成 `previewActive=true`；而 `requestLongPressWordLocked` 首行硬拒 `previewActive`（4779）。应把该 guard 移到 ownership 判断之前。

---

## 已证事实（代码 + 日志）

**代码侧（可复核行号）**
- `editorCommitPlainChangeLocked`（8903）：`if (!editorOwnsTextSession(s)) return false;`（8905）在前，`if (next == s.editingText && !s.previewActive && !s.markedActive) return true;`（8912）在后 → guard 只对 owned 生效。
- `ohos_renderer_ime_preview_text_ctx`（8930）是**唯一**生产调用点（grep 全文件仅 8944 一处）；false 时置 `previewText=next; previewStart=0; previewEnd=editingText.size(); previewActive=true; markedActive=false; caretUtf16=next.size()`（8947–8953）。
- `previewActive` 的下游门：`requestLongPressWordLocked`（4779）、`ohos_renderer_ime_grapheme_range_ctx`（8857，字词命中查询也拒）、选柄发布 `publishPaintedLayout`（2522）、`beginSelectionHandleDragLocked`/`selectionDragMatchesLocked`（4700/4728）。即一旦置位，长按→字词命中→选柄整链全灭。
- ArkTS 侧 `cjgui-text-proxy.ets` onChange（252–286）：无合法 marked 区间 → `bridge.preview` → 上述 native 入口；rc='0' → verdict ok，挂载存活。**平台无法在此区分“回声”与“真实同值取消”，native 是唯一裁决点。**
- 生命周期排除（用户要求的“其他撤销/生命周期可能性”）：`previewActive` 的清除点只有——commit ABI（8886 段）、finish/失焦结算 `settleComposedBufferOnBlurLocked`（5628）、外部换版 reconcile（7523 段，会换 contextId 并打 `ime context reconcile` 日志）、节点移除/换绑（7477/7567 段）、proxy restore（7098）。`beginEditingOnNodeLocked` 同节点重焦对活上下文早退（4631–4634），不清 preview；C-API `ImeFinishTextPreview` 路径已弃用（5805 明示 arkts proxy authoritative）。

**日志侧（hilog_after_long_click.txt，PID8329）**
- 40897 `17:55:26.644 ime proxy mounted ctx=1 ... text=warm`；40900 `26.646 selection set [4,4) reason=mount`。
- 40902 `17:55:26.654 ime proxy onChange len=4 verdict=ok` —— 唯一一条 onChange，经 preview ABI 且 rc=0（按代码，generic 必走 else 分支）。
- 40904–40905 `26.655 selection observation forwarded 4:4 / ime select [4,4) rc=0`。
- 41051–41054 `29.551 caret hit applied caret=4`（前序点按正常）。
- 41117–41120 `17:55:32.271 caret hit applied tap=(14.9,32.3) ... composed=4 caret=0 affinity=1 / human anchor seq=2 sel=0:0` —— **长按 BEGIN 被降级为 offset 0 的 caret 命中**（这正是其后 getter 观察 0:0 的来源，比“caret命中0”的表述更精确：是命中落在 0，不是零次命中）。
- 41152 `33.774 raw touch action=39`（END）。窗口 [26.654, 33.8] 内**无** `ime grapheme`、**无** `long-press selection: word range`、**无** `ime composition/commit`、**无** finish/reconcile，ctx 恒为 1、projection 恒 382 → 排除换版/退役/第二个写入者。

**推断（强，但未被直接日志钉死）**：32.269 时刻 `previewActive==true`。依据是“26.654 后无任何清除点触发”+ 代码路径穷举；日志里没有直接打印该标志。

---

## 1) 是否应在 ownership 之前消除 same-text 非 composition 回声 —— 是

```cpp
bool editorCommitPlainChangeLocked(Session &s, const std::u16string &next)
{
    // 挂载回声：与已接受正文相同且无活组合，对任何会话都不携带新的落点意图。
    if (next == s.editingText && !s.previewActive && !s.markedActive) return true;
    if (!editorOwnsTextSession(s)) return false;
    ...
```
- guard 条件本身不变（仍要求 `!previewActive && !markedActive`），只是提前；stale-context 拒绝仍在更外层 `takeEditingContextLocked`（8864）之后，不受影响。
- 唯一调用方对 true 的反应是“本轮无操作 + 重绘”（8944–8946），`visibleBefore==composedBuffer` 不会触发 blink 重置 → generic 回声不再产生预览、不折叠 caret、不取消恢复。恰好满足“不产生预览/提交/caret 折叠，也不取消恢复”。
- 附带修复一个未观测到的次生污染：现状下 blur 时 `settleComposedBufferOnBlurLocked`（5628）会把这条假 preview 折算并经 `editorEnqueueTextCommit(previous==next)` 发一条**冗余 kind-28**（5504–5507 走 `editorEnqueueTextChanged`）；guard 前移后该路径不再进入。

## 2) 普通 draft 与真实组合同值是否保留 —— 保留，逐例核对

| 场景 | guard 前移后 | 与现状 |
|---|---|---|
| generic 挂载回声（next==editingText，无 preview/marked） | return true，无任何状态变化 | **改变（即修复）** |
| generic 真实变文（next≠editingText） | guard 不命中 → ownership false → else 分支草稿投影，等 submit | 不变 |
| generic 活组合中（previewActive/markedActive） | guard 被自身条件排除；组合走 `preview_range_ctx` 根本不经此函数 | 不变 |
| generic 组合结束回基值（previewActive=true，final==editingText） | guard 跳过 → false → else 重置 preview 为终值、markedActive=false，保持草稿至 blur 结算 | 不变（这正是测试 17 块要保留的语义，仅返回值约定翻转） |
| owned 全部场景 | ownership 先真值判断时 guard 本就在其后生效，语义等价 | 不变 |
| proxyRestore armed 时 generic 回声 | return true 跳过 `cancelProxyRestoreRequest` | 符合“不取消恢复” |

风险面：函数文档“返回 true 表示已按提交处理”需改为“已按提交处理或确认无变化”；`test_plain_mount_echo_native.py` 的 `return 17` 块（断言 generic 相同正文必须 false）**必须同步翻转**为断言 true + 选区/恢复保持——这正是用户指出的“现有断言掩盖正常消费缺口”。块 10–16（owned 幂等、真实差异取消恢复并出 kind-51、活 preview 经公共入口清算）全部不受影响；`test_negative_guard_must_not_swallow_real_changes` 仍应通过。

## 3) 需要的生产摘录反例 / 负控

1. **把推断变事实的关键摘录（当前构建补测一次）**：回声后、长按前的 `ime context` 查询 JSON——现状应含 `previewStart/previewEnd/previewText="warm"`（8808–8824 的序列化只在 previewActive 时输出这些字段）；修复后应无这些字段。这是唯一能把“previewActive 置位”从推断转为直接观测的公开窗口，也是修复的最小机体验收。
2. **已在文件的负摘录**（引用即可，勿重跑）：[26.654→33.8] 无 `ime grapheme`、无 `long-press selection: word range`；唯一 onChange；ctx=1/projection=382 恒定（排除 reconcile/retire/第二写入者）。
3. **Pharos 同指纹 A/B**（已绿，作为 ownership 对照）：同序列下回声在 owned guard 处 return true，长按选词通过——两例唯一差异即 guard 与 ownership 的相对位置。
4. **防修复过宽的负控**：generic 字段敲入真实差异草稿（不 submit）→ 长按仍应被拒（previewActive 合法为真）；blur/submit 恰好交付一次变更。
5. **组合同值负控**：generic 全选后用 IME 重打相同正文 → 组合期拒选词、结算后 preview 清除、无双重交付（对应测试 16 块补一个 generic 变体）。

## 4) 若归因不成立的区分检查

- **补测 1 的 JSON 无 preview 字段但长按仍失败** → previewActive 归因错。转查 `requestLongPressWordLocked` 其余早退子句：`thresholdLatch`/滚动接管（窗内应无 scroll/consumeScroll 日志，现已无）、`pressBeginMs` 被清零（手势分类）、identity/binding epoch 漂移（accepted v 漂移）。
- **出现 `ime grapheme` 且 rc=1 而 previewActive=false** → 门在 8857 的其他条件（`utf16ToUtf8(editingText)!=input` 或 proxyRestore 三态旗），指向恢复/生命周期而非回声。
- **修复落地后 JSON 无 preview 但仍无选词** → 查手势相位分发：若 END 后出现第二次 `caret hit applied` 而 UPDATE 期间从未进入 `kGestureEditorHold`（5177/5400），说明长按分类/触发路径另有问题，与文本所有权无关。
- **回声后 contextId 变化或出现 `ime context reconcile`** → 外部换版路径介入，回声只是伴生现象。

边界提醒：guard 比较须留在 UTF-16 域（两侧均 u16string，勿做规范化）；不得把该判定上移 ArkTS（`previewKnown/composing` 启发式无法区分回声与真实同值取消，且 203 行已有删除路径依赖 native 裁决）；不涉及清 preview 后强制选择、组合门或 ArkTS 产品规则——与约束一致。
