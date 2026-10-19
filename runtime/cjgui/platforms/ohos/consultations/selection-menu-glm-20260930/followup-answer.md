# 结论（先读）

r14b 的根因**不是** guard 失效，也不是原子 validate/replace 有洞——19.717 那次 validate 看到的 native 状态（len23、sel 23:23）是**自洽的**，它是被污染后的结果，guard 语义上就该放行。真正的污染只发生在一处：

> **18:33:18.070 的 `ime select [23,23)`——把程序写文引发的平台“文末 reset”当成人的导航转发给了 native。**

而它之所以能被转发，是因为在此之前两次选区安装（18.005 `reason=caret`、18.067 `reason=menu`）都**在实际 onChange 回声（18.070）之前就用 getter 提前收口并清掉了 `proxySelMount`**，reset 到达时守门人已经下班。你的拟修方向（等确切回声再装、窗口内 selection 只作观测、supersede、有界 deadline）与 restore 事务的**已验证**语义同构，方向正确；但有 8 处需修正，其中两处是致命的实现细节（见 §3）。另外：**本机 SDK 没有 `setText` 带 selection 参数的 API**（§4，已核声明文件），不要按它设计方案。

---

## 1. 证据：r14b 时间线重建（区分证据/推断）

**证据**（menu-failure.hilog.txt 行号）：

| 时刻 | 行 | 事实 |
|---|---|---|
| 17.937 | 1586-1587 | native `replace range=5:10 accepted=1`——owner 正确剪切，native 文本 28→23 |
| 17.940 | 1588 | native caret notification sel=**5:5** |
| 17.974 | 1607 | `menu cut accepted=1` → `installed()` → `onMenuInstalled`：`acceptMenuSnapshot`（m.draft←23 文）、`this.imeText=23文`、**30ms 定时器** |
| 18.005 | 1654 | ImsaKit `IMC size: 28`——**TextArea 仍是旧 28 文**；同刻 `selection set [5,5) reason=caret`（native caret 推送路径）+ `getter observed [5,5) rc=0` → **`proxySelMount=null`，提前收口** |
| 18.067 | 1668-1671 | `selection set [5,5) reason=menu`（30ms 定时器）+ getter[5,5) → 再次提前收口；TextArea **仍是 28 文** |
| 18.069 | 1670 | ImsaKit `IMC size: 23, range 5/5→23/23`——**值赋值落地，平台把选区 reset 到文末** |
| 18.070 | 1673-1675 | `onChange len=23 verdict=ok`（回声）；组件 `On selection change`→**`ime select [23,23) rc=0` 转发 native** |
| 18.142 | 1693 | 菜单轮询看到 native sel **23:23**（污染已成事实） |
| 19.717/19.764 | 1796-1800 | paste validate 23:23 合法 → 文末粘贴 alpha → owner 46 字节错误终态 |

**推断**（由上列证据唯一合理化）：`getter observed [5,5)` 读到的是 controller 在**旧 28 文**上的选区状态；5:5 在新旧文本里都合法，getter 无法区分“回声前旧账”与“回声后落点”。这就是你说的“getter 先到但 onChange 后 reset”反例的机制本体。SDK 声明同样支持“同帧 getter 不可作证据”：`getCaretOffset` 注释明言 *"If this API is called when the caret position is updated in the current frame, it will not take effect"*（common.d.ts:24954-24956）。

**结构性结论（推断）**：`onMenuInstalled` 是全代码库唯一一条“程序写全文进代理、却不立票据任务”的路径。restore 路径的注释（Index.ets:774-778 五步、810-813“正文写入会让平台把光标重置到末尾，因此选区必须在文本更新之后装”）早已写明这个坑，menu 路径漏掉了同样的纪律，并用 30ms 墙钟定时器替代了“等回声”这个因果事件。

## 2. 证据：本机回调顺序

两次独立观测完全一致（cut 18.069-18.070、paste 19.893-19.894）：

```
this.imeText = 新值
  → 同帧/次帧 IMSA OnSelectionChange(旧→len,len)   ← reset 先到
  → onChange(value)                                  ← 回声后到
  → 组件 onTextSelectionChange(len,len)             ← 最后
```

另有两条：`caretPosition` 在旧值文本上即时生效并通知 IMSA（18.005），但**同值 setter 可不产生组件级 onTextSelectionChange**（18.005→18.067 之间无 [5,5) 组件事件；Index.ets:1214 注释已知此行为）。

**含义**：(a) reset 与回声同帧、reset 在前——任何“先装、赌回声晚到”的顺序必输，唯一正确顺序是 **回声(targetText 精确匹配) → 30ms → 装 → 组件事件或 echo 后 getter 等于目标 → 收口并转发一次**，即 restore 已验证的节奏；(b) 收口证据可以依赖 getter，但**必须在 textObserved 之后**。

## 3. 对拟修方案的质疑（8 点，前两条致命）

1. **【致命】只 gating “MenuInstall 任务”不够——第一个提前收口来自 `caret` 路径，不是 menu 定时器。** 18.005 的 `reason=caret` 是 native caret 推送（17.940 notification → focus request → `onProxyCaret` → `armProxySelection`）触发的。若 MenuInstall 任务只是自己内部等待，`installProxySelection`/`onProxyCaret`/`onFocus` 仍会在窗口内抢装并提前清 `proxySelMount`。**任务必须占据一个被所有入口查询的槽位**——现有先例：`installProxySelection` 开头 `if (this.proxyRestoreTask !== null) { this.proxySelMount = null; return; }`、`onProxyCaret` 的“恢复事务进行中……让路”。
2. **【致命】`textObserved=false` 期间禁止 getter 收口**，要落成硬规则：不得输出 `ime selection getter observed`、不得清槽、不得 `imeSetSelection`。r14b 的两行 getter 日志就是假证据本体。验收检查点：getter observed 行必须晚于 `onChange is program echo` 行。
3. `acceptMenuSnapshot` 在窗口起点就写 `m.draft=新文`：窗口内真人输入到达时，onChange 正常路径会以 m.draft(23文) 为镜像投影组件值（28文+人字）→ native kind-51 精确差分会把剪切**如实回滚**（人看到的是旧文，投影诚实）。这其实可接受（supersede=人赢），但若想语义干净，应让任务持 targetText、m.draft 只在 echo/收口时写（restore 的做法，Index.ets:506/917）。
4. **deadline 内“隐藏菜单”不必进最小修**。菜单可见性只读 native 快照（100ms 轮询）；转发被 gate 后 native 保持 5:5，菜单几何自动正确（18.142 的 23:23 位置正是污染后的读数）。加隐藏态是打磨，扩大改动面。
5. `needsText=false`（copy、selectAll、text 未变）**不得等回声**——等了就是白等 2.5s。规则照 restore：仅 `text !== this.imeText` 才进 echo 等待。selectAll 继续走既有 `setTextSelection(0,len,{HIDE})`（Index.ets:1215 同型）。
6. echo 后“下一帧复用 arm”——照抄 restore 的 **30ms 后 beginSelectionPhase**，不要发明新节奏（同帧残余事件先落账）。
7. onWillInsert/onWillDelete 先到时：它们无文本，只应作“取消安装任务”的提前信号（槽清空、task 终态）；**supersede 判据必须以 onChange(value≠targetText) 为主**，不得据 Will 回调发 ACK 或改 draft。
8. 上下文换版/卸载/blur 取消：挂到既有钩子即可——`mountEditingSnapshot` 已终态化 stale 任务、`submitAndFinish` 后 `isCurrent` 为假自然短路。

## 4. 本机 SDK 核验：`setText` 带 selection 不存在

已核 `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/component/text_area.d.ts` 与 `common.d.ts`：

- `TextAreaController`（text_area.d.ts:39-90）仅有：`caretPosition(value)`、`setTextSelection(start, end, options?: SelectionOptions)`、`stopEditing()`。
- `SelectionOptions`（common.d.ts:26803-26816）**只有 `menuPolicy?: MenuPolicy`**，没有 selection 参数、没有 setText。
- 基类可用原语（common.d.ts:24941+）：`addText(text, {offset})` since15，**同步返回插入后新光标位置**；`deleteText(range)` since15；`getSelection()`、`getCaretOffset()`、`clearPreviewText()`。

**推断（需设备实验）**：menu cut/paste 若改走 `imeTextController.deleteText({start,end})` / `addText(text,{offset})` 而非 `this.imeText=` 值赋值，则**从根上绕开“值赋值→文末 reset”FAQ 行为**，且光标副作用与目标天然一致（cut 后光标在删除点≈目标 5:5；paste 后在插入尾=目标），onChange 回声走 registry 既有 IME 路径。本库间接证据：grapheme 纠正路径已用 `deleteText` 且依赖其回声（cjgui-text-proxy.ets:224-238，900ms 超时兜底）；onWillDelete 注释明说 controller 变更会 re-enter WillChange（现状下 `deleteOperation=null` 时 onWillChange 直接放行）。**但这是优化项，不是修正确性的前置**——先落 §5 的 gate，r14b 翻绿后再评估 controller 化作双保险。

## 5. 最小可靠修法

**复用 ProxyRestoreTask 机器，`request=0` 匿名票据**（不借 native request/ACK，符合你的“不造业务 owner”约束）：

1. `onMenuInstalled` 删掉 30ms 定时器与手写 arm 逻辑，改为构造 `ProxyRestoreTask(mount, /*request*/0, targetText, selStart, selEnd, needsText)` 放进 `this.proxyRestoreTask` 槽、清 `proxySelMount`，`needsText` 时 `this.imeText=text` + `armRestoreDeadline(task, 2500)`，否则直接 `beginSelectionPhase`。`ackProxyRestore` 对 `request<=0` 本来就 no-op（Index.ets:937-940）——native 侧无需任何新 ABI、无新推送。
2. 由此**免费获得**全部已有纪律：onChange 的 echo 匹配/`superseded_by_input`（503-520 行）、onTextSelectionChange 的安装观测分支（566-575 行，reset 不转发）、`installProxySelection`/`onProxyCaret`/`onFocus` 让路（1194-1197、1290-1294）、deadline 终态、mount retire 终态化。
3. 需要的增量只有三处小改：(a) `onProxyRestore` 的同请求去重分支加 `request>0` 条件，防真 restore request=0 与 menu 任务混淆；(b) `armRestoreDeadline`/日志加 `kind='menu'` 字段区分诊断；(c) deadline 从 1500 提到你要的 2500（或保持 1500，本机实测 echo 间隔 ≤70ms，1500 已宽裕 20 倍）。
4. **保留**原子 validate/replace 不动——它的职责是拒并发编辑，选区事件归属是壳的职责，两者正交（§1 已证 guard 在本反例中无责）。
5. 可选第二阶段：cut/paste 改 controller `deleteText/addText`（§4），同一 gate 仍保留。

## 6. 验收反例（判别式）

- **R1 主复现**：r14b 场景重放。绿：日志无 `ime select [23,23)`；无 `reason=caret` 的 set 出现在 echo 前；native 保持 5:5；随后 paste 得 `前alpha行保留\n beta😆 gamma\n末行保留`。红（只 gate menu 任务不占槽）：仍见 `ime proxy selection set ... reason=caret` 先行。
- **R2 getter 假证据判别**：人为让 echo 前旧文上 caret 命中目标（本反例即天然如此）。绿：`getter observed` 行严格晚于 `onChange is program echo` 行。红：echo 前出现 getter observed 并清槽。
- **R3 真人输入不被吞**：窗口内 IME 键入一字符。绿：`superseded_by_input` 终态、preview 正常、native 收到该字（剪切被诚实回滚）；红：字符消失。
- **R4 reset≠导航**：echo 后组件报告 [len,len)≠目标。绿：不转发、30ms 重装至 [5,5)（restore 的 `selectionRetried` 分支原样复用）；红：转发（=r14b 原状）。
- **R5 deadline**：断点卡住 echo。绿：2.5s 终态日志（区分 `text_observation_timeout`/`selection_observation_timeout`）后恢复转发，不得永久吞 selection（否则人点别处光标死）。
- **R6 换版**：窗口内外部 reconcile → 旧任务终态、新 mount 安装不被旧任务阻挡（mountEditingSnapshot 既有清理 + request=0 ack no-op）。

## 7. 焦点

证据支持你的观察：hilog 全窗口无 `ime proxy blur`/`submit` 行，焦点自 18:33:13.941 挂住，copy(16.344)/cut(17.933)/PasteButton SUCCESS(19.711) 均未触发 blur。此前建议的 onBlur 兜底保持“已知未复现、设备实验 C 仍待跑”的状态即可，不阻塞本修。
