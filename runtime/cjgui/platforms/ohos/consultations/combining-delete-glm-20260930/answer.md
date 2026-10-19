# 只读咨询结论：OHOS 代理 TextArea 组合重音退格只删重音（26B≠25B）

## 证据基础（本次实读）

| 事实 | 出处 |
|---|---|
| 代理 TextArea 只挂了 `onChange(value, previewText)` + `onSubmit` + `onTextSelectionChange` + `onFocus/onBlur`；**没有** onWillDelete/onDidDelete/onWillChange | Index.ets:449-543（全文 grep 无这些回调） |
| onChange 全文交 `proxyRegistry.onChange` → `bridge.preview/previewRange` → `entryNapi.imePreviewText/imePreviewRange`（同步 napi） | cjgui-text-proxy.ets:153-181；Index.ets:98-114 |
| napi → `ohos_renderer_ime_preview_text_ctx` → `editorCommitPlainChangeLocked`（窗口拥有节点时是真实提交） | cjgui_host_bridge.cpp:2998-3013；ohos_renderer.cpp:7967-8020 |
| **值差通道**：`editorEnqueueTextCommit` 按 UTF-16 最小公共前后缀复算精确范围增量（kind-51），只保证**标量边界**（代理对不切开），注释明言“区间是结果文本的一个合法表达”——不是平台意图 | ohos_renderer.cpp:4839-4906（4843 注释、4861/4872 标量回退、4881 畸形具名拒绝） |
| owner 侧 `replaceRange16`→`submitRange16` 带组字门禁与同版本仲裁；快照 `handlePlainIntent(DeleteBackward/…)` 存在：无服务→`grapheme_boundary_unavailable`，簇内 caret→`grapheme_interior`，选区删除不查簇 | text_session.cj:818-943、1877-1883 |
| OHOS 字素服务是具名拒绝 stub（TEXT_SERVICE_UNSUPPORTED），注释明示 mac 用 CFStringGetRangeOfComposedCharactersAtIndex | ohos_renderer.cpp:5401-5418 |
| **handlePlainIntent 在 mac 有真实意图源**：native 拦截 `deleteBackward:/deleteForward:/moveLeft:` 等 selector 转成 plainIntent 事件→窗口调 session.handlePlainIntent；OHOS 无任何调用方 | cjgui_internal_renderer.m:11383-11410；src/composable_ui_window.cj:3697-3739 |
| SDK：`onWillDelete(Callback<DeleteValue, boolean>)` @since12，“返回 true 表示文本已删除、false 否则；**text preview 时不回调；仅系统输入法可用**”；`DeleteValue={deleteOffset, direction(BACKWARD=0/FORWARD=1), deleteValue}`；`onDidDelete` @since12；`onWillChange` @since15：“在 onWillInsert/onWillDelete 之后、onDidInsert/onDidDelete 之前触发，**返回 false 取消变更**”，携带 `TextChangeOptions.rangeBefore/rangeAfter` | text_area.d.ts:1148-1174、1354-1369；text_common.d.ts:423-453、320-340、1543-1563 |
| SDK native：unicode/ubrk.h 在位（UBRK_CHARACTER=0、ubrk_open/preceding/following/isBoundary 声明），ICU 72.1（uvernum.h:56/82/89）；libicu.so 导出符号按你方 dynsym 认定 | 本机头文件 |

## 1 可区分归因：平台行为 / 框架遗漏 / 代理差分

**【证据】同一轮 UITest 里平台删除单位不一致**：旗帜、肤色、ZWJ 家庭簇整体删除；`e+U+0301` 只删重音（−1 个 UTF-16 码元，留 `e`）。这同时排除两个单因假说：
- 不是纯 UTF-16 delta（旗帜是 4 码元整体删）；
- 不是完整字素簇（Mn 序列被逐个剥离）。

**【证据】这次删除根本没走 CJGUI 的簇契约路径**：值差通道只保证标量安全（ohos_renderer.cpp:4845-4849 明确只修代理对边界），owner 按同版本仲裁合法接受这笔“平台替换”。即 owner 的 kind-51 通道**按设计**不 policing 簇语义——它承载的是平台事实，不是删除意图。

**【推断，高置信】根因是 OHOS TextArea/系统输入法内部的退格分段策略：emoji 类按簇、Mn 组合标记逐个剥离**（iOS 系控件同款“剥重音”惯例）。是否与真人软键盘路径完全一致——**未决**，UITest 注入与系统 IME 客户端路径的等价性无本地证据，不许默认。

**可驳回的误归因**：
- “TextInput→TextArea 迁移引入”——无本地证据；同一 TextArea 同轮已对 emoji 整簇删除，说明 TextArea 本身簇感知，剥 Mn 是分段策略差异，不是代理差分（可用 RED-B 一锤定音）。
- “owner 接受 UTF-16 delta 是 bug”——错误框架：diff 通道按设计就是标量安全的值通道（注释自证）；缺陷在于**删除意图缺失**，不在接受端。

**框架遗漏（证据）**：① 字素服务 stub；② OHOS 无删除意图源（mac 有 selector 拦截，OHOS 零调用方）。

## 2 最小满足簇契约路径（不发明 IME、不默默扩删）

“系统 ICU 窄服务 + 真实删除意图”**是合理且必要的配对，二者缺一不可**：

1. **窄服务**：用 libicu 实现 `cjgui_internal_renderer_grapheme_cluster_range`：`u_strFromUTF8` → `ubrk_open(UBRK_CHARACTER, …)` → `ubrk_preceding/following` → `u_strToUTF8` 回字节。dlopen/dlsym 失败保持具名拒绝。这是消费系统 Unicode 服务，与 mac CFString 平级，非自研引擎。**决策点【未决】**：locale 用 root 还是系统 locale（ICU 字符断行有 locale tailoring，如泰文；建议 root 并在 RED-C 钉死，且注明 ICU 72 UAX#29 覆盖 ZWJ/旗帜/肤色，语义是 mac “组合字符序列”的严格超集）。
2. **真实意图**：镜像 mac 先例（selector→plainIntent 事件→window→handlePlainIntent）。ArkTS 侧在代理 TextArea 上挂 `onWillDelete`（首选）或 `onWillChange`（备选，@since15 有明确“false 取消”文档且带 rangeBefore/rangeAfter；但组字期间也触发，需按现有 composing 判定放行）。同步段：回调内经 napi 同步查簇（新增无副作用纯查询入口，renderer 互斥下安全），**平台拟删 span == 簇 span → 放行**（emoji 全部场景零行为变化）；不等 → 同步返回取消，再异步投 `imeDeleteIntent(direction, offset16, span16)` → renderer 入队意图事件 → window `handlePlainIntent(DeleteBackward/Forward)` → 一笔 owner 事务 → 现有 `action=restore` 机制装回正确文本+选点。
3. **不越线**：取消发生在平台变更落地**之前**，owner 删的是自己 oracle 算出的簇，是独立显式事务——这不重解释平台替换范围。被禁止的变体是：在 kind-51 Sink 里事后把平台已表达的替换区间悄悄加宽（那才是“默默扩删平台明确替换范围”），不要做。也不许在 ArkTS 手写 UAX#29 或按键码猜删除。

若 RED-A 证明 onWillDelete 返回 false **不能**取消（或 UITest 注入不触发该回调且无备选），拦截方案不成立，只能降级为“接受后由 owner 发一笔显式补全事务并上报状态”——那属于产品裁决，不是本咨询可宣布的绿色。

## 3 回调顺序、身份、restore、owner 仲裁

- **文档顺序【证据】**：onWillDelete → onWillChange（可取消）→ 变更落地 → onDidDelete。onChange 与 onDidDelete 的相对次序**文档未钉**，需 RED-A 实测。
- **身份**：沿用挂载捕获 `m` + ProxyKey 校验（cjgui-text-proxy.ets validate/isCurrent）；迟到/退役挂载的 delete 回调只记日志。异步意图带 contextId，`takeEditingContextLocked` 已天然拒 stale context（preview/commit 同款）。
- **restore**：复用 proxyRestoreTask（mount+targetText 回声吞除）、imeRestoreAck 回执、`cancelProxyRestoreRequest("human_commit_supersedes")`（已在共同提交入口 ohos_renderer.cpp:7979）。被取消的平台删除不产生 onChange，无回声冲突；纠偏窗口内真人输入 → superseded 既有有界重发。
- **仲裁**：不需要新契约裁决——纠偏恰好一笔 plain intent 事务（wroteOwner=true）走 replaceRange16 的既有同版本仲裁；平台侧被取消故零写入，无双写。**需要新增裁决/审计的**：① onWillDelete 返回值语义与触发面（RED 钉死后写入模板注释）；② `handlePlainIntent` 入口缺 `compositionActive` 总门禁（replaceRange16 有 composition_busy，但 Move/Extend 分支无组字检查，text_session.cj:892-939）——新意图源接入前必须补；③ undo 归组（若 owner 有 undo：一笔意图=一个撤销单元，被取消的平台动作无孤儿撤销项）。

## 4 RED 反例与正常系统输入验证

- **RED-A 语义钉死（纯 ArkTS 探针页，无 owner）**：`e\u0301` 末尾退格——记录 onWillDelete 的 deleteOffset/direction/deleteValue（预期 deleteValue=`\u0301` 单独）、返回 false 后文本是否不变、回调次序（含 onChange vs onDidDelete）、**H 套件同款 UITest 注入是否触发该回调**。false 不取消或注入不触发 → 拦截方案改道或判死。
- **RED-B 归因差分**：同页旗帜/肤色/ZWJ 退格预期 deleteValue=整簇（钉死“平台策略差异”而非代理差分）；可加 TextInput 对照杀掉迁移误归因。
- **RED-C ICU 单元**：反例缓冲断言 `e..U+0301` 为一簇（非仅重音）；ZWJ/旗帜/肤色；dlopen 失败仍具名拒绝；root vs th locale 差异钉死。
- **RED-D 端到端**：重放原序列，第 4 次 DEL 后 owner 读回必须 25B `'# Pharos Mark\n\nH1R\n中文'`（现 26B）；负例：拼音组字中 DEL 不被拦截（onWillDelete 不触发于 preview，验证日志缺席）；纠偏窗口内打字不双删。
- **RED-E 真系统输入法（人工，必需）**：真键盘中文 IME 下退格 `e+重音` 与 emoji。按你的门槛，UITest 单独不能给绿。
- **RED-F 身份**：取消与意图到达之间退役挂载 → 意图被弃、文本不变、无孤儿 restore。

**明确未决**：onWillDelete 返回值精确语义与触发面（含 UITest 注入等价性）、onChange/onDidDelete 次序、ICU locale 选择、真实键盘下 Mn 剥离是否复现。以上未决项在 RED-A/B/E 出结果前，任何实现不得视为满足簇契约。
