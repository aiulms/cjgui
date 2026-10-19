我已按限定符号读完局部代码。以下分四部分：证据（带行号）→ 对候选方案的质疑 → 最小机制 → 可区分实验与验收反例。证据=代码可证；推断=标注。

---

## 一、证据盘点（全部来自指定符号局部读取）

**E-A 两处全选分支的真实可达性不对称（关键发现）**
- 位点 1：`ohos_renderer.cpp:4700-4712`（`executePendingTapLocked`）。`longPress` 判定要求 `s.gesture.pressBeginMs > 0`（4666-4667），而 `pressBeginMs` 只在 4846（BEGIN 时已激活编辑器的 EditorHold 分支）赋值。pending 相（未激活时点编辑器）从 BEGIN 到 END 都不会设置它 → **位点 1 的全选分支当前是死代码**；它实际执行的是 beginEditing + FOCUS + `editingTapPending=true`。
- 位点 2：`ohos_renderer.cpp:5070-5081`（END 的 kGestureEditorHold）。用 `textPressBeginMs`（BEGIN 时 4847 已设）→ **这是生产上真正触发的长按全选**。所以"改两处"之前必须先决定位点 1 的可达性语义：一旦你把 `pressBeginMs` 补设到 pending 路径，首次长按（聚焦那次）就会带出部分选区——这是产品行为变更，需显式确认而非顺带发生。

**E-B `editingTapPending` 与长按选区互相覆盖的隐患（第二关键发现）**
- EditorHold 的 BEGIN 在 4848-4850 写 `editingTapPending=true`；END 在 5074-5081 写全选；随后 pump 的 caret 命中块（8001-8103）消费 pending，命中成功则 `selStart=selEnd=caret`（8094-8096）并重锚 "caret_hit"，**把刚写的选区塌缩掉**。
- 现在生产上全选能站住，推断依据是 8109 附近的守卫 `s->acceptedPaintTicketId == job->sourcePaintTicket`：END 后紧跟的重绘 Paint 未被核心 accept 时，命中被 "paint_pending_acceptance" 拒（2977-2983 同类拒绝），塌缩不落地。**这是靠拒答侥幸成立的脆弱平衡**。任何把部分选区写在 END、又遗留 pending tap-hit 的实现，都会在 accept 快时被同路塌缩——新机制必须显式清除/取代 pending，不能依赖这条。

**E-C 命中与发布的守卫链（可复用的资产）**
- `executeCaretHitTest`（2957-3020）：renderEpoch/window/generation/lease/geometryRevision、会话身份（editing/contextLive/!retired/contextId/node 身份/projectionVersion/`composedBuffer` 文本相等）、`acceptedPaintTicketId==painted->basePresentTicket`、node 几何/字体逐项相等；用 `GetGlyphPositionAtCoordinateWithCluster`（UTF16+affinity）+ `clampToCodePointBoundary`。**这套守卫是 word-boundary/handle 命中 job 的现成模板**。
- `publishPaintedLayout`（2466-2481）：render 线程独占、无锁、单调 serial、无编辑节点时以 null 候选**取代式撤销**。`drawNodeText`（3735-3905）：同一 typography 出高亮（`GetRectsForRange`, 3994-4022）、字形、光标；候选携带 serial/ticket/身份/relativeOrigin/density。
- pump 应用侧复核（8051-8103）：snapshot → 解锁 waitFor → 重锁全量重验（含 surfaceGeometryRevision、sameGeometry）→ 写纯视觉投影（不 bump 版本，8097 注释）→ 重锚。**这就是"跨锁不等待"的既有范式，照抄即可**。

**E-D 手势仲裁现状**
- UPDATE 分支只处理 pending 阈值/scroll/pointer-drag（4866-4984），**kGestureEditorHold 完全吞掉 MOVE**：编辑中拖动既不滚也不选——疑点 2 属实，证据在此。
- pending 相可编辑文本+有视口 → 阈值后视口接管（4877-4893，含 "takeover:" 惯例与冻结 viewportBindingEpoch）；无可编辑文本目标才走 pointer-drag。

**E-E 锚与代理回路**
- `recordHumanSelectionAnchorLocked`（4398-4436）：要求 accepted 绑定，冻结全身份+range，置 `humanCaretNotificationPending`、`selForwardedValid=false`、终止在途恢复票。
- 差分推送（8156-8170）：`!restoreLive && (pending || 与 selPlatformStart/End 有差)` 才发 `{"action":"caret",...}`——天然去重，但**连续拖动会产生安装风暴**（见质疑 3）。
- Index.ets：代理 `opacity(0.01)`、`focusOnTouch(false)`、`hitTestBehavior(None)`（451-467）；`onTextSelectionChange`(556-584) → `observeSelection` → `imeSetSelection` 回路；**当前未设置 `copyOption` / `selectionMenuHidden` / `caretColor` / `selectedColor`**——疑点 3 的实验矩阵入口。

---

## 二、对候选方案的质疑

1. **"长按在 END 结算"与"长按后再拖"矛盾**：现有长按只在 END（5070）结算。若保持"END 才出词选区"，用户长按后想直接拖手柄必须抬手再按。要做到"长按→出选区→不抬手直接拖"，词选区必须在 **UPDATE 中计时到 400ms 且未跨阈值时**触发（一次性闰锁），END 只是终态。这是对你候选的时间线修正。
2. **必须显式取消 pending tap-hit**（E-B）：词选区落账那一刻，同手势 BEGIN 挂起的 `editingTapPending` 必须清掉，否则塌缩竞态换成"快 accept"就复现。你候选没提这条，这是最大暗雷。
3. **每次 MOVE 重锚会打爆代理回路**：`recordHumanSelectionAnchor` 每次置 pending → `action=caret` 推送 → ArkTS `installProxySelection` → 回声。拖动 102 个 MOVE 就是上百次安装。最小做法：拖动中只更新 `selStart/selEnd` + Redraw（纯视觉），**锚只在词选区创建时和拖动 END 各记一次**；拖动期间抑制 8160 的差分推送（槽位 active 时不推），END/CANCEL 恢复推送。注意反例：若 END 异常丢失（会话销毁 6323 手势复位路径），抑制必须一并解除，否则输入门永久关闭——参照 `terminateProxyRestoreRequestLocked` 的"取消必须回窗"教训（4340 附近注释）。
4. **冻结面太宽的风险**：冻结 context/binding/surface/geometry/ticket/text 正确，但"冻结 selection"要精确为"冻结非拖动端 offset + 拖动端锚定语义"，而非冻结整个 range；且拖动开始后**不能再用发布出来的手柄几何做命中**（中途 blink 重绘会推进 serial 换发 facts），拖动命中一律走 job 守卫链。发布 facts 只服务 BEGIN 的手柄判定。
5. **位点 1 的死代码语义**（E-A）：你候选默认"两处都改"，但位点 1 改活等于改首次长按行为。建议：显式让位点 1 与位点 2 同语义（首次长按=聚焦+词选区），并把这个行为变更写进验收；否则保持死代码只改位点 2，但要在注释里声明。
6. **词边界失败的回退不能是全选也不能是静默**：回退=塌缩 caret（复用现 caret-hit 语义）+ 日志 `word_boundary_failed`。绝不回退 select-all（旧探针语义只留日志证据）。
7. **grapheme 校验点**：`GetWordBoundary` 返回 Range（你已查 SDK，API11，需 `ReleaseRangeBuffer`）后仍须本地校验：`0≤start≤end≤len`、两端都在码点边界（复用 `clampToCodePointBoundary` 思路）、start<end。平台 ICU 词切分对 CJK 可能给出行级/字级范围，属可接受波动，但**不得给出撕裂代理对**。

---

## 三、最小可靠机制（M1–M6）

**M1 词选区（长按）**
- 触发点：UPDATE 中 EditorHold 且 `nowMs-pressBegin≥400` 且未跨阈值，闰锁一次 `wordSelectTriggered`；位点 1 同语义（BEGIN 对可编辑目标补设 `pressBeginMs`）。触发时**清除 `editingTapPending`**（防 E-B 塌缩），置 `wordSelectPending`（冻结身份快照：context/contextGeneration/node 身份/binding/projection/surfaceGeometryRevision/GestureKey + 落点）。
- 结算：pump 解锁区（照抄 8001 块范式）：post `RedrawJob` + `WordBoundaryJob`（守卫链=executeCaretHitTest 全套复制 + `GetWordBoundary`），`waitFor` 有界；拒答→回退塌缩 caret。落账：重锁重验 → 写 selStart/selEnd、caret=被点词的近侧端 → `recordHumanSelectionAnchorLocked(s,"long_press_word")` → Redraw。
- 拒绝面（继承既有）：previewActive 改变 composed → 文本不等拒；换版/换绑/blur/resize → 身份/几何拒；迟到的旧 job → ticket/serial/GestureKey 不匹配拒。

**M2 手柄几何发布（有界、非 owner）**
- `drawSelectionBoxes` 已经取过 `GetRectsForRange` 的 boxes——把手柄端点（首 box 左沿中点、末 box 右沿中点，surface 坐标）随候选一起算出并画两个实心圆（同 typography、同原点；半径用 `painted->density` 换算的固定 vp 触达半径）。
- `publishPaintedLayout` 在 Flush 成功后，于 render 线程取 `g_sessions.lock`（此刻不持 render 锁，与 `executeCaretHitTest` 内嵌 sessions 锁同序）把**纯值 facts**（两端 rect、serial、ticket、身份、geometryRevision、surfaceGeneration）写入 Session 单槽；**取代式更新（serial 单调），无编辑节点帧自动撤销**。消费者守卫：ticket==`acceptedPaintTicketId`、身份、editing、contextLive——与 pump 8109 同型。

**M3 BEGIN 仲裁（疑点 2 答案）**
- EditorHold BEGIN：先用手柄 facts 精确命中（半径内）→ 新相 `kGestureHandleDrag{端}`，冻结另一端 offset + M1 同款身份快照；否则 EditorHold 如旧（并补设 pressBeginMs）。
- UPDATE：HandleDrag → 走 M4；EditorHold 跨阈值（沿用 12px 与不可逆闰）：若本手势已出选区 → 转 `kGestureSelectionExtend`（固定另一端=离落点较远端）；若选区塌缩 → **视口接管滚动**（复用 4877 起的 takeover/sample 代码与冻结 viewportBindingEpoch）；无选区无 viewport → 维持现状（待定到抬起）。长按 400ms 触发在阈值判定**之前**检查（长按不出位移）。

**M4 有界 MOVE/END 槽（疑点 4 答案）**
- Session 单槽：`{gestureEpoch, seq, latestX/Y, inFlight, 终态标记}`。MOVE 只更新 latest/seq；pump 保证**至多一个在飞 CaretHitTestJob**（复用守卫链，仅多一个"命中即拖动端 caret"输出），完成时 epoch+seq+身份+ticket 全匹配才应用（更新拖动端、Redraw、不重锚），latest 变了立即补发一个——同 `kEvPointerUpdate` 尾合并（4960-4972）与 `postCaretBlink`"队列唤醒渲染最新相位"两个先例。
- END：以 END 坐标做最后一次同步 resolve（pump 解锁 waitFor 范式），应用后 `recordHumanSelectionAnchorLocked(s,"selection_drag_end")` 并恢复代理推送；CANCEL：槽连同抑制位一起终态化，选区停在最后应用的 MOVE，不补 END。迟到 END/CANCEL 已被 4742-4748 的 GestureKey 采样拒收挡在门外；**新 BEGIN 新 epoch 使旧在飞结果作废**（解决"新的 BEGIN 覆盖 oldPending"的正反向：旧结果污染新手势、新手势误收旧结果都不会发生）。会话销毁（6323）路径同步清槽。

**M5 代理装饰（疑点 3：未知，先实验后定）**
- 现状证据：未设任何隐藏属性。实验矩阵（最小、一次性）：①基线：装非塌缩选区观察系统柄/放大镜是否出现及位置；②`copyOption(CopyOptions.None)`；③`selectionMenuHidden(true)`（属性可用性先在 SDK d.ts 确认，仓内无法证实）；④`selectedColor/caretColor` 透明。判定门见 E9。**不许**用"代理选区保持塌缩"规避——`onWillDelete` 依赖 `getSelection()` 实际范围（Index.ets 490 附近），塌缩会毁掉 IME 替换语义。

**M6 通道纪律**
- 不新增 owner 写、不新协议：词选区/拖动端全部是纯视觉投影（不 bump 版本），权威化只经 `recordHumanSelectionAnchor` → `action=caret` 差分推送 → 代理 `onTextSelectionChange` 实际观测 → kind33 回路。旧 "native_select_all" 日志/探针保留为旧范围证据，不参与验收。

---

## 四、可区分实验与验收反例

| # | 操作 | 期望（通过） | 反例（失败信号） |
|---|---|---|---|
| E1 | 已编辑态长按第 7 行某词 | anchor `long_press_word`，sel=词范围 | sel=0..len（全选回归）；sel 塌缩（E-B 塌缩或词查询失败未回退日志） |
| E2 | 长按 emoji/代理对 | 两端都在码点边界、不撕裂 | 范围含半个代理对 |
| E3 | 拖起始柄跨行向左 | 仅 selStart 动，selEnd 冻结；越界钳到 [0,len] | 两端同动/跳全文档 |
| E4 | 拖动中注入 CANCEL | 选区停最后 MOVE，无 END 补落，下次点击正常 | CANCEL 塌缩/全选/手势卡死 |
| E5 | 旧在飞 job 期间新 BEGIN | 旧结果按 epoch 作废 | 旧 caret 贴到新手势 |
| E6 | 组合预览进行时长按 | 词查询拒（composed 不等），无变更无崩溃 | 按旧布局出选区 |
| E7 | 长按与词 job 完成间 blur/resize/换绑 | 拒，不落账 | 选区贴到新上下文 |
| E8 | 仲裁 | 塌缩态竖拖→kEvScroll 如旧；出选区后同手势拖→extend；新手势非手柄起手→按现状 tap/viewport | 编辑中拖动仍全吞（回归疑点 2） |
| E9 | M5 矩阵 | native 视口内无系统柄像素；IME 候选替换仍删对范围 | 系统柄出现在代理几何处 / 替换删错范围 |
| E10 | r7 回归 | 102MOVE→原文不变→命中 243→插入正确 | 任何滚动/命中回归 |

**验收关键分界**：E1 通过 + E10 无回归 = 部分选区成立；E3+E4+E5 = 手柄与终态成立；E9 = 装饰收口。全选行为只允许出现在旧探针日志里，任何新路径出现 `selStart=0 && selEnd=len` 即失败。

**主要推断标注**：E-B 的"生产全选靠 PRESENT_PENDING 拒答站住"是推断（accept 时序无法静态证实），但其竞态窗口由 4850/5074/8094 三处行号证据链支撑，机制上必须按"会发生"防御。
