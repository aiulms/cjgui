# 核验结论（只读咨询）

## 1. 因果链核验 —— 证据与推断分开

**证据（日志 + 源码逐行对上）：**

| 环节 | 证据 |
|---|---|
| ctx 5→6 + req3 排队 | hilog 3054/3058：`ime context reconcile old=5 new=6 base=19`；`proxy restore armed request=3 ctx=6 v=19 sel=14:14` |
| **reconcile 先于 restore 下发**（pump 内分支顺序：reconcile 7716–7741 在 restore-armed 7780 之前） | 3059/3060：`ime reconcile notification` 先于 `ime proxy restore notification request=3` |
| 平台端同步退旧 mount → restore 到达时 active=0 | 3062–3069：`proxy retired for external reconcile ctx=5` → `ime restore ignored ctx=6 active=0 req=3` → `ack ... ok=false reason=stale_context` → native `terminated reason=platform_install_failed code=2`。源码：Index.ets `onProxyRestore` 781–783（imeCtx 尚未切到 6 即具名回 stale_context）；renderer 4054（`PROXY_RESTORE_NOT_INSTALLED`，即“具名 NOT_INSTALLED”的实体） |
| ~10ms 后 mount6 + 初始回声 14:14 | 3092 `ime proxy mounted ctx=6`；3123 `ime selection observation forwarded ctx=6 sel=14:14 native_changed=0`。此回声**能**转发（reconcile 分支 7729–7731 已把 `selForwardedValid=false`），但窗口取不了 seq3：3127 `human anchor mismatch: identity seq=3`——锚冻结在 v17 代身份，事件带 v19 身份，`take_human_selection_anchor`（6568–6596）按身份逐位拒绝，**这是守卫按设计工作，不是 bug** |
| 两本账被 14:14 饱和 | reconcile 分支对齐 `selPlatform=14:14`（7729–7731）；ime_set_selection_ctx 回声再写 `selPlatform=14:14` 且 `rememberForwardedSelectionLocked` 置 `selForwardedValid=14:14`（8234–8236、4919–4925） |
| 人点正文末尾 → 无通知、无观测 | 3360–3361：`caret hit applied ... caret=14` + `human anchor recorded seq=4 sel=14:14`，其后**直到文件末尾没有任何** `ime caret notification` / `ime selection observation forwarded` / `human anchor taken`。源码因果：pump 推送条件 `!restoreLive && (a != selPlatformStart || b != selPlatformEnd)`（7749）对 14:14 判 false → 不发；即便平台再回声 14:14，`selectionObservationNeedsForwarding`（4916）也判 false → 不转发 |
| 窗口解锁路径被饿死 | 窗口侧唯一解锁：`adoptOwnedTextSelection` flag 分支内 `canAnchorHumanSelection16` → `internalRendererTakeHumanSelectionAnchor` → `anchorHumanSelection16`（snapshot composable_ui_window.cj 6280–6296；text_session.cj 554–583 置 `selectionNeedsNativeRestore=false`）。无 kind-33 → 无解锁 → `selection_native_alignment_required` 继续挡输入 |

**结论：请求中的归因成立。** 死点不是“锚没冻结”（seq4 已冻结且身份与未来事件本可逐位命中），而是**同值双重去重**把“安装通知”和“安装观测”各吞了一次。seq2 正常路径（2460–2474：通知→setter→12ms 回声→forwarded→taken）证明观测闭环本身是好的，只在同值时断。

## 2. 拟议机制评审

### 2.1 强制一笔 caret 安装通知（新 native flag 或 target-ledger 失效一次）

**推荐显式 one-shot flag，不用“账本失效”**：`selPlatformStart/End` 是裸 uint32，做“失效”表示最终还是等价于一个 valid 位，且 flag 语义（“待强制安装”）与账本语义（“平台已知值”）不混账——这正是 1183–1191 注释里二者必须分开的纪律。

**必要的最小守卫（防错误账本/重入）：**
- **flag 必须在 `clearHumanSelectionAnchorLocked` 里一并清**（4153–4156）。否则 rebind/退役后残留的 flag 会把 one-shot 烧在新上下文的同值推送上。锚随身份退场，安装意图也必须随锚退场。
- **只在 sink 真正拿到 payload 时消费**（现有差分推送即使 sink==null 也先写 selPlatform——7749–7752 的既有行为；强制位不要沿用这一点，否则一次空投递烧掉唯一一次机会）。
- 消费点在推送分支内、`g.unlock()` 前，与现有 `selPlatform=a,b` 同临界区；无重入（sink 在锁外调用，ArkTS 端同步回调 `imeSetSelection` 重入 native 时 `g_sessions.lock` 空闲，无递归锁问题——已核对 8207–8211 取锁点）。
- 三处 `recordHumanSelectionAnchorLocked` 调用点（7694 caret_hit、4397/4770 长按全选）都是**人手势原生路径**，不是平台回声路径——无条件置 flag 是安全的；长按全选时值通常异于 selPlatform，推送本来就发，flag 只是保证同值全选也可发，**仍只发一次**（同一 pump 迭代推送分支只走一遍）。
- `restoreLive` 让路语义保持：锚记录本身会就地终结在途票据（4138 `human_anchor_supersedes`），所以正常时序下推送不被挡；若票据在记录与推送之间被窗口重签发，flag 保留至票据终结后发出——有 deadline，不悬挂。

### 2.2 同时打破 selForwarded 去重一次

在 `recordHumanSelectionAnchorLocked` 里置 `selForwardedValid=false` 是对的：窗口需要的不是“平台又报了一次 14:14”，而是“**锚存在之后**的一次 14:14 观测”。风险检查：
- 抢跑风险（无关回声先消费 one-shot）：转发值若为锚值 → 窗口直接取锚（等价达成）；若为异值 → 记 selForwarded=异值，锚值的回声仍会转发（按值判重）→ 不丢。**不构成错误账本**。
- 自激风险：无。kind-33 只流向窗口，不回流 native 选区；`selPlatform` 由推送自身写回。
- 取锚的最终防线在窗口（身份+值逐位、一次性 consumed、`adoptedHumanAnchorSeq` 防重放），native 侧多转发一条最坏只是 NAMED_STALE 噪声。

### 2.3 ArkTS 薄壳 setter 后主动 getSelection 收口（productIndex.ets 1190 一带）

现有 `installProxySelection`（1186–1222）的**唯一**观测源是 `onTextSelectionChange` 回声；同值程序化 set（`caretPosition(14)` 时组件已在 14）恰恰是最可能不回声的场景——这正是 3123 初始回声之后同值静默的机制。主动 get 是必要补齐，且 getter 语义已有成熟范本（restore 路径 `observeSelection` 865–918，请求中“getter 已可用”属实）。

**守卫（请求中已列，逐条确认并补边界）：**
- 只在 `proxySelMount===mount && proxyRegistry.isCurrent(mount) && this.proxyFocused` 时做主动收口；非聚焦挂载保持原 onFocus 重装路径（1153–1159 那条），不得用 get 提前宣布成功。
- `getSelection()` 返回 `undefined/null`、`start/end` 缺位、或 throw —— 一律“无观测”，**不得当 0（0 是合法落点）**，不关 `proxySelMount`、不转发、不重置 retry，继续原 3 次有界重投。getter 异常 ≠ 成功。
- **只在 actual==target 时转发 actual 并关账**；actual≠target 时不转发不关（转发异值会写错观测账本——虽然 onTextSelectionChange 582 行本就无条件转发异值回声，那是既有语义，主动路径不应扩大它）。
- “旧 mount 不得转发”是三重既有防线：ArkTS `isCurrent(m)`（562–568、1188）→ `imeSetSelection(m.key.contextId)` 冻结旧 ctx → native `takeEditingContextLocked` stale 拒绝 return 1（8209–8210）。新代码不得绕过其中任何一层（尤其不要改用“当前 imeCtx”代替 `m.key.contextId` 去转发）。
- 收口后 `proxySelMount=null`，onFocus 的重装分支（478–481）因守卫失效自然不再抢——无新增竞态。
- 与回声路径的**恰好一次**：两路都汇到 `ime_set_selection_ctx`，第一路消费 `selForwardedValid` 重置后第二路被按值去重 → 恰好一条 kind-33。主动转发发生在 sink 回调（onProxyCaret）栈内，native 侧锁空闲，无死锁/重入锁。

### 2.4 残余风险（如实列出，不假装为零）
- 强制通知被平台吞（TextArea 未挂稳/setter throw）：走既有 bounded retry → “never observed” 记账；下一次人锚重开一轮。liveness 依赖“平台最终能装”，与修复前相同，未恶化。
- `proxyFocused` 标志滞后（onBlur 迟到）：主动 get 会在已失焦组件上读值——读到 target 也只是把“平台确在其位”这一事实如实回报，窗口仍按锚核验；风险可接受，不需新增焦点仲裁。

## 3. 可区分 RED（三层，各自能钉死一个根因假设）

**RED-N（native，扩展 `test_human_selection_anchor_native.py` / `test_ohos_ime_selection_event.py` 风格）**
1. 预饱和双账：置 `selPlatform == T`、`selForwarded == T`（模拟 3123 后状态）→ 触发 caret_hit 人锚（值 = T，同值）。断言：恰好 **1** 条 `action=caret` sink 调用（ctx=当前、sel=T）；随后喂一条 `ime_set_selection_ctx(T,T)` 回声 → 恰好 **1** 条 kind-33（身份+值与锚逐位相同）；`take_human_selection_anchor` 返回 1 **恰好一次**，第二次返回 0。修复前：0 条通知 → RED。
2. 去重仍在的反例：无新人锚时同值回声**不得**再转发（证明只破一次，不是拆掉去重）。
3. 换绑守卫反例：锚记录后立即 rebind/retire → 强制推送**不得**对新上下文发同值通知（旧 mount/旧意图不得转发）。
4. one-shot 消费语义：sink 未注册时不消费 flag，注册后仍能发一次。

**RED-S（ArkTS 薄壳，mock controller）**
5. 组件当前 selection 已 == target 且 `onTextSelectionChange` 不触发：断言 setter 后调用了 `getSelection`；返回 target → 恰好一次 `imeSetSelection(actual)` 且 `proxySelMount` 关闭；返回异值 → 不转发不关闭、attempt 推进（不重置预算）；getSelection throw/undefined → **不**成功、不转发伪造值。修复前：只等回声 → 超时“never observed” → RED。
6. 非聚焦 mount：不得主动收口（仍走 focus 重装路径）。

**RED-E2E（复放失败场景，钉“顺序修不修”的裁决）**
7. 活跃编辑 + 外部换版（ctx bump）+ restore 抢跑 mount → NOT_INSTALLED 终态 → **无后续人输入前**无任何解锁；然后人点同值落点 → 恰好一通知/一观测/锚 ADOPTED/`needsNativeSelectionRestore=false`，**下一键入不再 `selection_native_alignment_required`**。修复前最后一步 RED。这一条同时证明：不修 reconcile→mount→restore 顺序，N1 语义与解锁仍成立。

## 4. 是否必须同时修 reconcile→mount→restore 顺序

**不必，且有一条前提需要更正：**

- **N1 本身**：同一运行里 N1（非空拒绝→restore 0:23→下一替换）在顺序缺陷存在的情况下已 PASS——缺陷只在“外部换版撞活跃编辑上下文”这一后置场景显形。N1 不依赖顺序修复。
- **“无自动恢复重签发”的前提不准确**：`restoreOwnedTextSelectionAfterAcceptedScene`（snapshot composable_ui_window.cj 6364 起，A1 接受链收尾调用）在每次 accepted 场景、门未解时重签发——req3 本身就是 v19 接受时签出的证据（3058）。失败场景里没有重签发，是因为**没有后续场景到达**，不是机制缺失。
- **真死锁判定（源码模型层面）**：不存在永久死锁。解锁有两条独立路：(a) 下一次 accepted 场景重签发 restore（稳态下 mount 已在，如 req1/req2 都 observed_installed）；(b) 人锚采纳（`anchorHumanSelection16` 直接清 `selectionNeedsNativeRestore`）。观测到的“死”是 一一被同值去重斩断，正是本次要修的。修好后 无后续场景也活。
- **但顺序缺陷有真实代价，值得单独跟进**：每次活跃编辑期外部换版都会白烧一张票据、产出一个 spurious `NOT_INSTALLED` 终态、窗口的有界重试预算被无效消耗（04:17 事故注释里那种 8 次预算烧法）。若改顺序（平台端把 restore 推迟到新 mount live，或 native 端 mount 完成后再 arm），需自带 RED：换版场景 restore ack 必须是 `observed_installed` 而非 `stale_context`。**建议与本次同值修复解耦、先后分批**，避免一次改动同时触碰两条证据链。

## 5. 边界声明

- 以上为源码模型级论证 + 本份 hilog 的单次观测；**不构成**所有路径证明（请求纪律）。特别地，“无永久死锁”依赖“平台最终可安装”这一前提，无法在本仓库内穷举 TextArea 全部失败模式。
- 未验证窗口侧 `restoreOwnedTextSelectionAfterAcceptedScene` 的全部调用时序分支，仅确认其在接受链上的存在与 req3 的实证。
- normal 段日志（req1/req2 成功、seq2 采纳）只用于证明机制存在，不用于证明所有路径正常。
