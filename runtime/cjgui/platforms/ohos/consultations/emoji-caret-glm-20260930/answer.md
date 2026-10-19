# 只读咨询结论

## 0. 事实核对（先于归因）

**[证据-算术]** 从 owner v32 原始 hex（`human-user-emoji.owner.json` RANGE 0 58）逐码元核对，全文 28 个 UTF‑16 码元：

| 内容 | 码元区间 |
|---|---|
| 恢复后替换 | 0–4 |
| \n | 5 |
| Agent: | 6–11 |
| 正文小艺输入法 | 12–18 |
| 😆 | 19–20 |
| (^～^) | 21–25 |
| 😀 | 26–27 |

caret=28:28（`interaction.raw.txt` `WINDOW_SELECTION pharos-editor-body 28 28 / UTF16_CODE_UNIT`）是**文末**。因此 `caretRectFor`（ohos_renderer.cpp:3669‑3692）查询 `[caret-1,caret)` = **[27,28)，恰好只含 😀 的低代理项**。第一张截图时刻同理：caret=21，查询 [20,21) = 😆 的低代理项。

**[证据-时间线]** hilog：12:21:43 插 "(^～^)"（21→26），12:21:48.952 `InsertText length:2`（😀，26→28），12:21:48.956 平台回显 28:28、native `forwarded ctx=6 sel=28:28`，12:21:48.975 `present frame ok`（projection 33，accepted node=107 value 已含 😀，bytes=58）。截图在此帧之后。字节确实进了同一 owner，“首字丢失”已被证伪（同意既有判断）。

**[证据-几何一致性]** 截图描述“第一行右侧”与 fallback 路径（3578‑3581）**定量吻合**：`prefixWidthUtf16(全文)` = `longestLine` = 第二行宽（≈246vp 量级，与平台 caret left=246.07 同阶），`caretTop=0` = 第一行。第一行本身只有 ≈90vp 宽，“右侧”只能是第二行宽度投影上来。

**[推断]** 上述吻合强烈指向 fallback 被走（GetRectsForRange 对半代理区间返回 0 盒），但截图无法区分“无盒”与“给了错误盒/零尺寸盒后 fallback 仍被走以外的分支”。这正是需要探针的原因。

## 1. 根因假设与可区分实验

- **H1（主假设）**：`GetRectsForRange(27,28)` 起点落在代理对中间 → 无盒 → fallback。
- **H2**：有盒但值异常（零宽/NaN）→ 仍会走 fallback（x 取 right 仍在第二行 → 与截图不符，H2 基本被截图排除，除非盒在第一行）。
- **H3**：绘制用了别的 caret 值 —— 被 28:28 回显 + `min(caretUtf16, 28)` 排除 [证据]。
- **H4**：排版对象失败/节点值陈旧 —— 被 v33 accepted 日志排除 [证据]。

**区分实验（真机 SDK 探针，不是假设）**：沿 `cjgui_ohos_test_trigger_redraw`（:5769）的 test‑gate 导出模式加一个 `probe_typography` 导出（普通产物拒收），在 HAP 进程内用**与 drawNodeText 完全相同的 layoutText 参数**（HarmonyOS Sans、fontSize 18、weight 400、宽 333）排 `S1="恢复后替换\nAgent:正文小艺输入法😆"`（21 单元）与 `S2=S1+"(^～^)😀"`（28 单元），打点矩阵：

- `[26,27)`（仅高代理）、`[27,28)`（仅低代理）、`[26,28)`（整簇）、`[28,28)`（空，应空）、对照组 `[11,12)`（ASCII 后）、`[18,19)`（CJK 后）；
- S1 同构的 `[19,20)/[20,21)/[19,21)`；
- 补充类：😀 开头文本的 caret=0 查询 `[0,1)`（同缺陷在缓冲首部也存在，只是碰巧视觉无害）；`"a\nb\n"`（文末硬换行）；`"e"+U+0301`；ZWJ 家族；
- 每串同时打 `GetLineCount` 与行级盒（行首字素区间），用于判读盒在第几行。

**判读**：`[27,28)` size==0 且 `[26,28)` size>0 → H1 确立；`[27,28)` size>0 且在第二行 → H1 证伪，转向下面第二个实验；`[26,28)` 也 size==0 → 引擎连整簇都拒，机制必须以下游查询/行级 API 为主。

**第二个区分实验（把反例绑定到分支）**：在 fallback 分支（:3577 附近）加一行 `RLOGW("caret fallback used caret=%u units=%zu")`。复现输入一次：出现该行 → 反例确实由 fallback 产生；不出现而画面仍第一行 → H1/H2 均不成立，另寻（目前无候选，需回到探针原始数据）。

## 2. SDK 可用性评审（按本机 sysroot 实际声明）

- `OH_Drawing_TypographyGetRectsForRange`：API 11，头文件 2196‑2210 明确 start/end 为 UTF‑16 码元、"Must be less than end; otherwise, an empty result is returned"——**对代理对中间位置的行为文档未定义**，这就是必须实测的点。
- **GlyphInfo：本 sysroot 中不存在**（native_drawing 全目录无 `OH_Drawing_TypographyGetGlyphInfoAt`/`OH_Drawing_GlyphInfo` 符号）。任何方案不得引用它。
- `OH_Drawing_LineMetrics`/`GetLineMetrics`/`GetLineMetricsAt`：**@since 12**（:723‑773, :2731‑2774）。当前产物排版查询只用 API 11（`GetRectsForRange`、`GetGlyphPositionAtCoordinateWithCluster` 均 11；被 deprecate 的是旧的 `GetGlyphPositionAtCoordinate`，since 18）。若 fallback 想用行级 API，需要单独的 minAPI 评审，且建议只作可选增强，不进主路径。

## 3. caret 最小机制（坐标与簇框同源）

原则：**任何 GetRectsForRange 查询区间必须与完整字素簇对齐**（上/下游各一查，与 Flutter `_computeCaretMetrics` 的 upstream/downstream 双查询同构 [记忆参考：本地无 Flutter 检出，机制而非逐字引用]）：

1. caret 先 clamp 到标量边界（已有 `clampToCodePointBoundary`）；`textUnits==0`（空缓冲占位空格）→ 直接返回原点盒 `(0, 0, lineHeight)`，不查询。
2. 在 `drawNodeText` 已有的同一 `g_sessions` 快照上，用 `cjgui_internal_renderer_grapheme_cluster_range`（ICU UAX#29 边界，:5441）对**同一份 UTF‑8 快照**求包含 `max(caret-1,0)` 的完整簇字节区间 → 机械换算回 UTF‑16 单元 `[gs,ge)`（编码映射不是字素算法；CABI 内部已有 byte↔unit 边界表可提为公共小工具）。**不在 ArkTS 实现任何字素逻辑**。
3. 上游查询 `A=GetRectsForRange(gs,ge,TIGHT,TIGHT)`：caret==0 取首盒 left；caret>0 取**最后盒** right + 该盒 top/bottom。
4. 硬换行：`caret<size && text[caret-1]=='\n'` 时补下游查询 `B=GetRectsForRange(下一簇 gs',ge')`，B 非空 → 用 B 首盒 left/top/bottom（下一行行首），避免“\n 后光标停在上一行行尾”。
5. A、B 均空（引擎拒答整簇，如长 ZWJ 序列跨软换行）→ 终局 fallback：取**前一完整簇盒**的 right 与其 top/bottom（x 近似、y 真行），`prefixWidthUtf16` 只在连前一簇都没有时使用且**禁止 top=0 归零**。emoji/combining/ZWJ 由第 2 步簇扩张统一覆盖，不存在“半个簇”的查询。
6. 兜底 x 的既有缺陷顺带修：`prefixWidthUtf16` 用 `longestLine`，对折行前缀本来就不是该行宽（`executeCaretHitTest` 注释已自证）。

## 4. blink 方案（pump 半周期 + 现有 RedrawJob）

**[证据]** 现状：`drawNodeText` 只要 `isEditingNode` 就画 caret（常亮的直接原因）；`kPumpWaitMax=16ms`（:340），pump 每轮持 `g_sessions.lock`；`RedrawJob` fire‑and‑forget、`executeRedraw` 已有 `leaseValid`+`geometryMatches` rebind 与停机清 `lastNodes`；`postIfRunning` 在 stopping/未运行时自动拒收；caret/选区变更已是“纯视觉投影、不 bump 版本、只 post RedrawJob”的既有模式（pump 命中分支注释）。

可行，且不需要新线程/定时器/锁：

- **状态放 Session（g_sessions.lock 已覆盖）**：`caretActivityMs`、`caretBlinkNextToggleMs`、`caretBlinkVisible`（决策值）。present 与 redraw 两路径都读这个已决策值（不要在绘制时用时钟现算，保证两路径同相）。
- **pump 每轮（持锁段内）**：活动谓词 = `editing && !editorRetired && 焦点有效 && selStart==selEnd`；`now ≥ nextToggle` → 翻转 `visible`、`nextToggle=now+500ms`（落后多周期也只翻一次，禁止补发 burst）；**解锁后**（沿 caret 命中分支的现有纪律，避免 sessions→render 嵌套锁序）`postIfRunning(RedrawJob)`。半周期 500ms（与 Flutter caretBlink 同阶 [记忆参考]），pump 16ms 粒度抖动可接受，空闲成本 ≈2 帧/秒重绘。
- **输入重置相位**：previewText/插入/删除/命中/选区**数值实际变化**时 `activityMs=now、visible=true、nextToggle=now+500`。关键门：**回声同值不重置**（hilog 里大量 `native_changed=0` 的平台回声若参与重置会造成常亮）。
- **失焦/停用**：谓词为假即不再翻转，并 post 最后一笔把 caret 抹掉；`g_applicationStopRequested` 优先级已高于一切；停机中 `postIfRunning` 拒收，RedrawJob 无票据不阻塞 `shutdownAndJoin`。
- **无自激/无 owner 写入**：blink 只产生 RedrawJob；不产生 ev.kind 事件、不 bump projectionVersion、不触发 ime caret 通知、不写 owner 文档——与既有 caret 视觉投影同法律地位。
- **selection 非空隐藏**：画 caret 条件加 `selStartUtf16==selEndUtf16`（与 collapsed 语义一致）。

## 5. 测试补强与验收反例

现 `test_text_geometry_native.py` 的假 `GetRectsForRange` 对**任何相交区间都给盒**（:203 起），结构上不可能复现本反例。补：

- **簇感知拒绝模型**：加簇区间表 + 开关“start/end 不在簇边界 → 返回空”；并记录全部查询、断言 **caret 路径所有查询簇对齐**（不变量，独立于模型取值）。
- **真实对照**：把第 1 节真机探针矩阵落盘 artifacts（模式同 `test_grapheme_service_native.py`），按实测校准假模型开关。

**严格反例（验收必须全过）**：R1 S2 caret=28 → 光标在第二行 😀 右侧（top≠0、x≠整段 longestLine，本 bug 直接回归项）；R2 caret=6（\n 后）→ 第二行行首；R3 文末 "\n" 结尾 → 新空行行首 x=原点；R4 e+U+0301 → 光标在整簇右沿、永无簇中 x；R5 ZWJ 家族同理；R6 空缓冲 → 原点盒；R7 选区非空 → 无 caret；R8 blink：输入即亮且相位重置、回声不重置、失焦停、停机后无 RedrawJob（计数静态）、无新增线程；R9 命中测试不回归（tap 第二行末尾仍得 28）；R10 查询形状不变量。

## 6. 需提前 Sol/Astra 的未决点（不要用本回答冒充已验证）

1. 键盘 resize 窗口期 RedrawJob 的 geometry rebind 路径原本假设由编辑变更触发；blink 以 2Hz 常驻该窗口，lease/teardown 仲裁是否受影响需复核。
2. present（owner 提交）与 blink 翻转交错只差一帧相位，确认没有“画面必须与 accepted 严格一致”的复核条款会把纯视觉差异判失败（既有注释支持不冲突，但条款归属在 Sol）。
3. OHOS 是否有系统级光标闪烁/减少动画设置需要读取（ArkUI 侧行为未查证）。
4. ICU 图素 locale=root 的既有决策与 caret 簇扩张共用；若前次 combining-delete 咨询改 locale，两处必须同步。
5. 若 fallback 引入 `GetLineMetricsAt`（API 12），minAPI/编译目标评审；建议维持 11 纯净。
