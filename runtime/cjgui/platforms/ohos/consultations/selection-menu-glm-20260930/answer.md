# 结论（先读）

架构方向可行：菜单几何从 `PaintedSelectionHandles`（已是同一次 Paint/Flush 的产物）以只读方式进 `imeEditingContext`、由框架组件纯显示、宿主薄壳执行命令，与现有「平台壳持有代理、native 持有真相」的分工一致。但计划里有**一处机制级错误**（`imeMenuCommand` 在 native 侧直接 apply 粘贴/剪切）和**一处坐标陷阱**（沿用 `snap.x / density` 模式），以及一个**无法从本地声明验证的风险点**（PasteButton 点击是否先触发代理 onBlur）。以下按证据/推断分开。

---

## 1. 证据：坐标与密度 —— 最大的可见陷阱

**证据链**：
- 节点几何是 vp，绘制时整体 `CanvasScale(density)`（ohos_renderer.cpp:2959-2961；注释 2336-2338「节点几何是 vp，绘制按它放大」）。
- handle 坐标在与字形同一 canvas 坐标系里计算：`h.startX = geom.originX + sx`（ohos_renderer.cpp:3930-3935），即 **vp（逻辑坐标）**。
- `surfaceDensity` 来源 = `OH_NativeDisplayManager_GetDefaultDisplayDensityPixels`（cjgui_host_bridge.cpp:1407），与 ArkTS `display.getDefaultDisplaySync().densityPixels`（Index.ets:1313-1315）同源同值。
- **陷阱**：宿主挂代理时 `this.imeX = snap.x / density`（Index.ets:1093-1098）——把 vp 又除了一次密度。代理 opacity(0)，错 3 倍没人看见；**菜单是可见组件，照抄这个模式在 density≠1 设备上必错**。

**最小修法**：菜单 `.position()` 直接用 JSON 里的 `menu.startX/startY` 数值（vp），不做任何密度换算；`density` 字段仅作日志。另注意：菜单与 XComponent 是 Stack 兄弟，坐标原点=页面原点=XComponent 左上角仅当 XComponent 顶格（当前 Index.ets 结构成立；若未来壳在 surface 上方加元素，需用 `onAreaChange` 记录 XComponent 偏移）。

**区分反例 A**：density=3 设备上 handle 实际在 (90,300)vp；若实现走了 `/density`，菜单落在 (30,100)。验收：日志比对 JSON `startX` 与屏幕 handle 位置，逐值相等才算对。

---

## 2. 机制质疑：`imeMenuCommand` 在 native 侧 apply 是错的

**推断（基于代码证据）**：计划让异步 pasteboard 回调后由 native 在 `g_sessions.lock` 下比较并直接 apply。但 TextArea 代理的草稿（`m.draft` / `this.imeText`）不会同步更新，而下一次真实键入的 `onChange` 携带的是**代理的旧全文**：

- owned 正文：`editorCommitPlainChangeLocked(input)`（ohos_renderer.cpp:8903-8932）会把这个「不含粘贴内容的旧全文」当真实提交 → kind-51 精确差分把粘贴内容**静默删掉**。
- generic 字段：native preview 与代理草稿分叉，Enter 提交的是 `m.draft`（cjgui-text-proxy.ets `submitAndFinish`），粘贴内容丢失。

唯一已有的「程序写全文进代理并确认回声」机制就是 restore 事务用的 `this.imeText = text` 赋值 → `onChange` 回声（Index.ets onProxyRestore，约 1280-1300 行；注释明言「成功与否由同挂载携带目标值的回声决定」）。恢复事务已闭合、不能再借用其票据，但**同一条通道对菜单命令同样成立**：

**最小可靠机制（推荐）**：
1. 菜单命令回调里 `await` pasteboard（cut 需 setData 成功）；
2. 然后**同一 ArkTS task 内同步**：`imeEditingContext()`（ImeEditingContext 是同步 NAPI，cjgui_host_bridge.cpp:2940，native 在 `g_sessions.lock` 下一次性快照）取**新鲜快照**，与 tap 时刻捕获的 `context/generation/wholeText/selection` 精确比较，不符即具名放弃；
3. 相符则计算新全文并 `this.imeText = newText`（一次程序写）。回声 `onChange` → `bridge.preview` → `ohos_renderer_ime_preview_text_ctx` → `editorCommitPlainChangeLocked`：owned 节点自动折入 kind-51，generic 节点自动成为 preview 草稿（8934-8956）——**零新 native ABI、零新编辑协议**，两条既有路径原样复用。

为什么新鲜快照比较足够：native 文本变更只能经 ArkTS 回调进入（preview/commit/setSelection 都是 NAPI），与菜单回调在同一事件循环上串行；await 之后、赋值之前的 check+assign 之间无 yield。残余窗口只剩 native 触摸线程改 selection（拖动中），而拖动中菜单本就无资格，且后果仅为「按捕获锚点落字」，不产生文本丢失。

**区分反例 B**：粘贴后立刻键入一个字符。走 native-apply 的实现里该字符存活但粘贴内容消失（代理旧全文覆盖）；走代理通道的实现里两者都在。这是两条路线的决定性区分实验。

---

## 3. native 事件 / postimage / caret 顺序（证据）

- 事件顺序安全：kind-51 与 kind-33 同一 FIFO（`s.events`），commit 先于选区回声入队，owner 按序消费。
- **菜单几何锚定的是「已 Flush 的帧 + 当前编辑缓冲」，不是 owner 的 accepted postimage**：`publishPaintedLayout`（2509-2530）在 Flush 后晋升，门槛是 `composedBuffer == painted text && sel == handles.start/end && context 一致`；`executeCaretHitTest` 另有 `acceptedPaintTicketId` 等待（~3050），菜单**不需要**等它——这正是「按真实可见端点定位」的正确锚。后果：菜单比 owner postimage 领先最多一个 owner 往返，帧内字形与 handle 同源，无视觉错位。
- 全选走平台回声不产生自激：`ime_set_selection_ctx` 回声时同步 `selPlatformStart/End`（~9075-9080），pump 的差分推送（8516-8552）不会再推同一值。
- **缺口**：几何变化（滚动、重排版）不改变 selection，现有 action=caret 推不到。需要在 pump 的 caret-diff 段落旁加一个 `action=menu` 差分推送（比较 `selectionHandles.serial/valid` 与 Session 新增的 `lastMenuPushSerial`），壳收到后重查 JSON。这是**只读定位通知，与 action=caret 同类**，不触碰 owner/编辑协议；建议加 ≥1vp 位移阈值 + 最小间隔，避免滚动时每帧刷推。

---

## 4. generic draft 显示（证据）

- generic 字段一旦有任何未提交改动，`previewActive=true`（8948-8955），而 handle 绘制门槛是 `!previewActive`（3888-3890）→ **generic 草稿期间本来就没有 handle，也就没有菜单**；菜单只在无草稿状态（挂载初值/纯选区操作）出现。
- 菜单命令一旦改文（cut/paste），generic 立即进入 preview 草稿 → `publishPaintedLayout` 门槛自动不晋升 → 菜单自动隐藏，草稿由 `composedBuffer` 绘制路径显示（3880 附近 `editComposed = composedBuffer(sess)`）。Enter/blur 走 `submitAndFinish` → `ohos_renderer_ime_commit_text_ctx` 整值 kind-28 提交——与既有协议完全一致，**不需要为菜单改任何 generic 逻辑**。
- copy 的取值来源必须是 native 快照的可见文（`previewActive` 时为 composed），不能取 `m.draft`；但菜单无资格态已排除组字，快照里 `text` 即可见文。

---

## 5. PasteButton：安全样式 / 定位 / 焦点（证据 + 明确的未知项）

**证据（本地 SDK 声明）**：
- `SecurityComponentMethod` 属性白名单只有 iconSize/layoutDirection/position/markAnchor/offset/字体/颜色/边框/padding/尺寸等（security_component.d.ts）；**没有 focusable、focusOnTouch、hitTestBehavior、opacity、visibility**。即：PasteButton **不能**做成透明/零尺寸藏在自定义 pill 里，也不能显式关掉触摸聚焦。
- 样式约束（paste_button.d.ts 错误码 2 清单）：字/图标过小、与背景色过近、过透明、负 padding、**被其他组件或窗口遮挡**、文字溢出、**超出窗口/屏幕**、尺寸过大、文字截断 → 授权失败。`icon/text/buttonType` 创建后不可动态改。
- 点击结果 `SUCCESS=0` 才允许读；`TEMPORARY_AUTHORIZATION_FAILED=1` 禁止读。`getData()` since 12 标注 `@permission ohos.permission.READ_PASTEBOARD`（临时授权即满足）；`setData` 无权限但可抛 27787277（并发操作中）/27787278。授权是一次性短窗：**SUCCESS 后立即 getData，不要先做别的 await**。
- 定位结论：菜单容器可用普通 Row+自定义按钮（这些**可以**也**必须** `.focusable(false).focusOnTouch(false)`），PasteButton 作为其中一枚真实可见的胶囊；容器位置钳制必须保证 PasteButton 整体在屏内且无任何组件压在其上（不要用 zIndex/覆盖物装饰它）。

**未知项（无法从声明验证，需设备实验）**：PasteButton 点击是否先让 TextArea 失焦。若 blur 先于 onClick(SUCCESS) 到达，Index.ets 的 `onBlur → submitAndFinish` 会当场 commit+finish 杀死编辑上下文（~588-598），粘贴验证必然失败、键盘收起。
**区分实验 C**：代理聚焦后点 PasteButton，记录 onBlur 与 onClick 的先后。
**兜底（若 blur 先到）**：onBlur 里若「菜单打开且 `imeEditingContext()` 仍返回活上下文」，延迟 ~300ms 再执行 submitAndFinish，期间收到菜单命令则取消收尾（纯壳侧逻辑，不加协议）；无命令到达则按原语义收尾。自定义按钮的同类风险用 `focusOnTouch(false)` 直接消除（本代码库已有同型先例：代理自身 Index.ets:467）。

**区分反例 D（剪切开销竞态）**：tap 剪切 → `await setData` 期间 IME 组字确认改文 → 新鲜快照比较失败 → 放弃改文（剪贴板已写入旧选区内容，可接受，记日志）。若不做比较，则会把已被替换的区间删掉。

---

## 6. 资格与迟拒（对计划的修正意见）

JSON 侧在 `ohos_renderer_ime_context_json` 内**查询时重新校验**（锁内），而不只信晋升时快照：`selectionHandles.valid && handles.context == editingContextId && editingContextLive && !editorRetired && !previewActive && !markedActive && !(selectionDrag.active && !terminal) && proxyRestore 不在途 && composedBuffer == handles.text && sel == handles.start/end`。迟到的资格变化（开始组字、restore 起飞、拖动开始）会在下一次推送/查询时把菜单藏掉。菜单命令侧的迟拒用 §2 的新鲜快照比较实现，**取消计划中的 native apply 型 `imeMenuCommand`**。

**区分反例 E/F**：E=拖动中不加闸门则菜单逐帧跟随、闪烁；F=自定义按钮未关 focusOnTouch，点「复制」即触发 blur→finish，菜单杀掉自己的会话。

---

## 7. 最小函数清单（若按上述修正采纳）

**native（ohos_renderer.cpp，零新 ABI）**
1. `ohos_renderer_ime_context_json`：追加 `"menu":{startX,startY,endX,endY,startLineY,endLineY,startVisible,endVisible,serial,geometryRevision}`（约 40 行，纯读）。
2. `cjgui_internal_renderer_pump_event`：caret-diff 段旁加 handle-serial 差分 → `sink({"action":"menu",...})`（约 20 行 + Session 一个 `lastMenuPushSerial` 字段，带节流）。

**框架 arkts（新公共模板，仿 cjgui-text-proxy.ets）**
3. `CjguiTextSelectionMenu`：props = 几何/资格/回调（onCopy、onCut、onPasteGranted(text)、onSelectAll）；内部渲染自定义按钮（focusOnTouch(false)）+ 真实 PasteButton，位置按 vp 钳制屏内。框架只做显示，不碰身份。

**宿主薄壳（Index.ets）**
4. `onFocusRequest` 增加 `action==='menu'` 分支 → 重查 `imeEditingContext` 更新 `@State menuGeom`；`end`/`restore` 分支顺手清菜单态。
5. `menuOnCopy / menuOnCut / menuOnSelectAll / menuOnPasteGranted(text)`：实现「捕获快照 → await pasteboard → 新鲜快照精确比较 → `this.imeText` 单次程序写 →（可选）回声后按既有 30ms 模式 `armProxySelection` 装理想 caret」。全选 = `imeTextController.setTextSelection(0, len, {menuPolicy:HIDE})`（既有 API，Index.ets:1215 已用），回声自然回流 native，无推送循环。

**明确不做**：native 侧 apply 型 `imeMenuCommand`；任何对 restore 事务、owner 仲裁、editorCommitPlainChangeLocked 语义的修改；对 `imeX/imeY` 既有 `/density` 的顺手「修复」（那是另一个咨询，先只保证菜单不沿用该模式）。
