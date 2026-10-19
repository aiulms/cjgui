# 咨询结论：`found 13` 是验收解析器的版本盲区，不是渲染缺陷

以下全部基于只读检查：`verify_normal_handwritten_scroll_nav.py`（下称 verify）、`test_normal_handwritten_scroll_nav.py`（下称 test）、`consultations/accepted-geometry-inertia-glm-20260930/frames_sample.raw.txt`（下称 sample）。【证据】= 日志/源码直接可见；【推断】= 由证据推出、需实验确认。

---

## 1. 根因（证据链）

**日志侧证据（sample，PID 28901 全程一致）：**
- END 行：line 54 `raw touch action=39 … ep=14` @ `10:02:05.180`。
- END 之后共 **13 个完整渲染 batch**，ticket `v=796..808`，terminal 时间 `.182→.682`（lines 55–145），全部严格晚于 END。
- 每个 batch 结构恒定：`node-rect id=1`（root）起 → `id=900`（viewport）→ `id=944`（nav）→ 三行 `accepted … v=<T>` → `present terminal session=1 ticket=<T> status=0 phase=3` 收尾。
- nav(944) 每版 y 递减 1（263→251），clip 高度同步 37→25；**viewport(900) 十三版完全相同**。
- 每一版内部，944 的 rect 只出现一次、无冲突；帧间隔 18ms→87ms 递增，与惯性衰减一致；terminal 之后无更晚几何行 → 惯性在采集前已终结（END+~523ms 与 `.682` 吻合）。

**代码侧证据（verify）：**
- `accepted_geometry_records`（L109）只按 node id 配对 node-rect，时间戳仅做行级 fence；**完全忽略日志自带的版本身份 `v=`/`ticket=`**。
- `_unique_accepted_geometry`（L156–166）要求“严格 END 后所有 node-rect 去重后恰好 1 个”，即隐含假设“END 之后该 semantic 至多提交一个不同布局”——这是只有拖动帧时代的世界观（拖动帧被 fence 排除，fence 后只剩单一 settle 帧可重复）。
- 真实惯性使 13 个合法不同布局落在 fence 之后且留在 ring 中（settle 1s > 523ms，采集时全部在场且完整）→ nav 命中 `found {len(unique)}=13`；viewport 恰好全等故先在 nav 上爆。
- `poll_fresh_nav_viewport_geometry`（L668）的 retryable 判定（L703）按子串匹配：`found 13` 不含 `found 0`/`is absent` → 正确地硬失败 → `hand_input_r2` 失败。

**根因一句话：** 日志已携带 per-batch 版本号，但验收解析器按“跨版本全局唯一”建模，把合法的跨版本运动（惯性）误判为同源歧义。渲染器每版自洽、票据单调、terminal 证明齐全——**无 native 缺陷证据**，符合“勿重写渲染器/协议”。

---

## 2. 可区分检查（区分各假设）

| # | 检查 | 区分什么 | 预期 |
|---|---|---|---|
| A | 对 sample 逐 ticket 统计 944 的 distinct rect：**每版内部**去重 | H1 版本盲区 vs H2 同版真歧义 | 每版=1（H1 成立）。若任一版≥2，现有拒绝才是对的，修复方向作废 |
| B | 13 个 terminal 时间戳 vs `.180` | fence 是否生效 | 全部 >END（fence 已生效，问题不在 fence） |
| C | `_pid_hilog_rows(sample, "28901")` / 错误 PID | 旧 PID 泄漏 | 28901→13 保留；他 PID→0（PID 过滤不是问题） |
| D | 最后 terminal `.682` 后是否还有几何行 | “等一等的再 poll 会绿” | 无 → 重 poll 拿到同一 13 帧，等待无用，必须改选择规则 |
| E | 单测层：现行 `fresh_nav_viewport_geometry` 喂 sample（前缀 3 行做 baseline）| 最小复现 + 修复验收同一载体 | 现行：`found 13`；修复后：nav y=251/clip h=25、viewport y=282、ticket=808 |

A–D 均为纯日志/离线分析，不碰设备。

---

## 3. 最小严格修复：END 后只消费“最新完整 accepted batch”

机制方案（不改渲染器、不放宽扫描——`present terminal` 行本就带 `CjguiRenderer` tag，已被 `_capture_hilog` 的 grep 捕获，sample 可证）：

**(1) batch 分组（新 helper，作用于已过 PID/新鲜度证明的 `fresh` 行）**
- 以 `present terminal session=S ticket=T status=0 phase=3` 为界切块；一个 batch = 上一个 terminal 之后（不含）到本 terminal（含）的全部行。root `id=1` 先行、node-rect 先于 `accepted v=` 是 sample 证实的块内结构，作为分组前提写入 docstring。
- 块内一致性：块内每条 `accepted … v=X` 必须满足 `X == T`，否则具名硬拒（“块内版本混合”）。

**(2) 资格与选择（精确规则）**
- 资格：batch 的 **terminal 时间戳 > fence 时间戳**（提交时刻作 fence 语义；跨 fence 的 batch 以其 terminal 归属，terminal 恰等 fence 的排除，与现行行级 `<=` 一致）。
- 选择：资格 batch 中取 terminal 最晚者（行序即时间序，由 `fresh_hilog_rows` 保证；同毫秒 tie 取行序最后，确定性）。
- **终结规则：若最后一个 terminal 之后仍有残余行（不完整 batch），不消费任何更早的完整 batch**——渲染仍在提交中，归类为可重试；超时后由外层具名拒绝。这正是禁止“用旧几何补绿”的落点。
- nav 与 viewport 必须在**同一个被选 batch** 内解析；返回值携带 ticket（写入 `nav_geometry.json` 作证据），并保留 `nav_ticket == viewport_ticket` 的断言作为反例钩子。

**(3) 同版判定（歧义的新正确定义）**
- 同一 ticket 内：semantic→多个 node id → 具名硬拒 "ambiguous"；同 node id 多条 node-rect **不同值** → 具名硬拒（同版冲突才是真歧义）；**完全相同的重复行容忍去重**（延续 L156 注释“Repeated accepted frames are expected”的语义）。
- 跨版本差异：合法运动，永不比较，只消费最新版。
- 几何合法性（w/h>0、clip≥0、`require_positive_clip`）在被选 batch 内原样保留。
- 旧 fence / 旧 PID：不改 `fresh_hilog_rows`/`gesture_terminal_fence`/`_pid_hilog_rows`，batch 解析只吃它们已证明的输出，拒绝性继承。

**(4) 无 terminal 行时的原严格 fallback**
- `fresh` 中 `present terminal` 行数为 **0** → 走现行 `_unique_accepted_geometry` 路径，报错文案不变。这让 `test_nav_geometry_requires_fresh_unique_labeled_nav_and_viewport` 及全部旧 fixture（`frame_rows` 均无 terminal 行）原样通过——原歧义负控不删不改。只要存在任何 terminal 行即进入 batch 模式，不做按 poll 混用两种模式。

**(5) retryable 分类的子串陷阱（必须一并修）**
- L703 用子串判 retryable：`"is absent" in message`。若新的硬错误写成 “…is absent from the latest complete accepted batch”，会被误判可重试 → 变相超时补绿/漏报。修复：要么硬错误措辞避开这些子串（如 “missing from accepted batch ticket=808”），更好是改为结构性分类（专用异常类型或返回标志），不再靠文案匹配。

---

## 4. “是否需要两次稳定快照才能用点？”——不需要

1. `present terminal status=0 phase=3` 是渲染器自己对“该版本已完整提交”的证明，版本级终结已有凭据；惯性是否“彻底停”不是点击正确性的必要条件（probe 自带 settle 1s > 实测 523ms，且点击后的每一步都会重新 fence 重读几何）。
2. **机制上不可实现**：本管线的新鲜度契约要求第二次快照含严格更新的行（`fresh_rows` 重叠路径返回后缀；rotation 路径要求逐行严格新于 baseline）。两次字节相同的快照在现行契约下只会得到空 fresh 集（“found 0”式重试），无法构成“稳定”信号；要支持它就得放宽新鲜度或扫描——均在禁止清单上。
3. “读点到点击之间仍在动”的残余竞态在现行设计和任何日志式验证器中都存在，双快照启发式并不能一般化消除，反引入对“渲染器会重发同版帧”的错误依赖（sample 显示 settle 后无重发心跳）。
- 替代证据：每阶段把消费的 `ticket` 记入 `nav_geometry.json`（同 `gesture_terminal_fence` 已记录的方式），审计时可复现“点了哪一版”。

---

## 5. 测试建议（含验收反例）

fixture：新增 `batch_rows(timestamp, ticket, [(semantic, node, rect, clip), …])` 生成 root 起始三元组 + accepted + terminal；保留 `frame_rows` 给 fallback 路径。

| 测试 | 断言 | 反例作用 |
|---|---|---|
| 13-batch 真形复现（内联 sample 或缩至 3 版 y=263/262/261） | 返回最新版（y=261，ticket=最大），无 "found N" | 主绿路径；若仍 found N 则未修 |
| 同版冲突 rect：一版内 944 两条不同 y，单 terminal | 具名硬拒 | 若容忍即过松（真歧义放行） |
| 同版 semantic→双 node id | "ambiguous" | 保留原歧义语义（同版） |
| 版本混合：nav 仅在 v=807、viewport 仅在 v=808（均完整、均 post-fence） | 具名拒绝，**不得**返回 807/808 配对 | 禁跨版配对的直接反例 |
| 不完整尾批：完整 806 后跟无 terminal 的 807 头部 | poll 第二轮补全 terminal 后消费 807（非 806）；永不补全则超时具名拒绝 | 禁“退回旧完整版”补绿 |
| 旧 fence：terminal 全部 ≤ fence | 可重试→超时，不回退 pre-fence 几何 | 禁旧 fence 放行 |
| 旧 PID：terminal 行属他 PID | 进不了 parser（现有 rotated 负控 + 一个 batch 模式变体） | 继承性证明 |
| 跨 fence 毗邻 batch：rects≤END、terminal>END | 计入 post-fence（提交语义）；terminal==fence 排除 | 边界钉死 |
| 原负控 `test_nav_geometry_requires_fresh_unique_labeled_nav_and_viewport` 原样保留 | 照旧 "exactly one"/"ambiguous" | fallback 未被弱化 |
| 旧 fake（Delayed/EventOrdered/Rotated/FakeWorkflowHdc）不 emit terminal | 全走 fallback，行为不变 | 无意外回归 |

【推断，非本咨询范围但同类暴露】`editor_visible_in_fenced_geometry`（L421）在 offset-restore swipe 之后同样消费 post-END 行并做全局唯一（错误文案 "fresh editor bounds are ambiguous…"），残余惯性会在设备上复现同类硬失败；`field_point_from_fresh_logs`/`field_text_hit_point_from_fresh_logs` 同类但处于 post-IME 静止场景。建议将同一 batch 解析器复用到 editor 门（一次改动、同一机制），field 路径可暂缓——由你们决定是否并入本次最小集，本次指名的五个函数优先。

**明确不做**：放宽歧义判据、回退旧几何、调低惯性、重写渲染器/协议、扩大 hilog 扫描、修改 `fresh_hilog_rows`/`gesture_terminal_fence` 语义。
