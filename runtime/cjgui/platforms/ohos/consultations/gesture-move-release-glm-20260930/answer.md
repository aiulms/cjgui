# 咨询结论：归因核查与最小机制修复

## 一、证据（逐条可复核）

**宿主侧（ohos_renderer.cpp，生产代码）**
1. 视口内**任何** raw BEGIN 都入队 `takeover:` kind30（4492–4509），`stampTouchEvent` 盖完整 GestureKey（3961–3968）。不限空白/只读——命中交互控件也先发这条。
2. MOVE 经 `consumeScrollSampleLocked → appendScrollIntentLocked` 入队 `by:<-whole>` kind30，**同一 gestureEpoch**（4260、4286–4289、4301–4302）。
3. END 在 RLOGI 打出速度估计（4709–4711），随后经身份门（4714–4719）入队 `fling:%.3f` kind30，同一 epoch（4724–4734）。
4. **注意**：`fling velocity=` 日志行在身份门**之前**（4710），日志只证明估计发生，不单独证明 fling 事件入队（见第四节残留不确定性）。
5. 本文件**不存在** wheel/axis 类滚轮生产者（grep `"up"|"down"|wheel|axis` 零命中）——OHOS 宿主上带非零 epoch 的 `by:` 只来自活动触摸手势；"epoch0 显式步"目前无 OHOS 生产者，属跨平台接缝语义。

**窗口侧（composable_ui_window.cj，生产代码）**
6. `takeover:` 分支：`scrollReleaseTicket = nativeEvent.gestureEpoch`（2201–2207）；POINTER_BEGIN 分支同样发同一 epoch（5588–5595）。两臂互不冲突。
7. `applyViewportScrollStep`：fling 门（4105–4108）之后，**一切非 fling 意图无条件 `takeOverScrollActivity(viewport)`**（4122）→ `scrollReleaseTicket = 0u64`（6921–6924）。发生在 `by:` 分支**之前**。
8. 票据的写点全集：2206、5594（发）、6916（停机）、6924（接管）；读点唯一：4105。成功 fling **不消费**票据（4113–4118 无清零）。
9. 速度阈值 `inertialStopVelocityPxPerMs = 0.01`（composable_ui.cj 1607）、τ=325ms、上限 2500ms（1609–1611）——0.045–0.051 全部在可启动区间。

**时序产物**
10. normal_terminal.raw.txt：5 个手势（epoch 1–5），velocity 0.045–0.051，whole=-90/-100/-40，无尾。
11. fixture 已含新测试 `ohosCurrentGestureMovesPreserveTheReleaseForInertia`（期望 MOVE 保票、fling 成功），与生产现状矛盾；`production-red.exit = 1` 与"E线正在修改、当前红"一致。
12. py harness 逐字抽取 `applyViewportScrollStep`（WINDOW_METHODS 第 62 行）——生产修复自动流入 harness；必名清单（415–421）**尚未**收录新测试名。

## 二、归因核查：你的怀疑成立，两处需精确化

**成立**。完整因果链（每环都是静态代码路径，无时序竞态）：

```
BEGIN(视口内) → takeover:/POINTER_BEGIN → 票据=epoch E        （证据1/6）
首个整像素 MOVE → by:<dy>(E) → takeOverScrollActivity → 票据=0 （证据2/7）
END → fling:0.05(E) → E≠0(当前票据) → inertia_release_ticket_stale → 无惯性
```

"accepted 增量严格 100、无尾"与该链完全自洽：`by:` 走 `viewport.scrollBy` 交付位移，活动从未 `beginInertialScroll`，自然无尾。macOS 侧 `pumpOneTurn` 每回合 `stepWindowActivities`（macos_application_host.cj 894–910），调度无问题——**故障在准入，不在推进**。

**需精确化两处**：
- "或POINTER_BEGIN"：两臂都会发，但空白/只读拖动只有 `takeover:` 臂；POINTER_BEGIN 臂是命中交互控件时的冗余一致发码。均可作根因载体，非"或"关系上的分歧。
- 你的怀疑句说"每个相同epoch MOVE…清零该票"——实际**第一个**整像素 MOVE 段就清零了（appendScrollIntentLocked 的尾合并不影响此结论）。

## 三、区分实验（关闭残留不确定性）

日志只到速度估计。两个备择解释与判别：
- **A（主因，代码证明）**：fling 到达窗口但被票据门拒 → 窗口侧 `lastNativeFailure == "inertia_release_ticket_stale"`。
- **B（备择）**：END 前 viewport 绑定 ABA（4715–4719 身份门失败），fling 根本未入队 → 无具名失败。
- **C（备择）**：fling 被接受但活动从未被步进 → 检查 WINDOW_VIEWPORT 流是否有 beginInertialScroll 后的 requestedOffset 增长请求。

判别：读窗口侧具名失败（或 pump trace 中 kind30 `fling:` 文本是否交付）。B 需要"最后 by: 被接受后、END 前发生换绑"，与"增量严格 100 且毫秒级间隔"不符，概率极低。**即使 B 成立，第七条的无条件清零仍是使每个正常拖动 fling 必死的确定性缺陷**，修复无论如何需要。另：`hand_interleaving_r1/result.json` 与 `generated_interleaving_r1/result.json` 不在本仓树内（find 无命中），我只能采信 request.md 转述的 -40/offset 40 结论。

## 四、最小机制修复（只动 `applyViewportScrollStep`，不动积分/Astra 裁决）

fling 门原文不动（不放宽旧 END 判据）；`takeOverScrollActivity`/`stopWindowActivities`/reveal 守卫/reveal 祖母函数全部不动（保住 py RED_GUARDS 锚点与逐字抽取）。在 4122 前按票据身份分流：

```text
非 fling 意图（by:/step）：
  releaseTicket != 0 && releaseTicket == scrollReleaseTicket
      → 同手势 MOVE：直接 scrollBy/step；不接管、不清票、不停活动
        （BEGIN 已停过旧活动；票是对"未来释放"的持有权，手势未完不得被自己中段撤销）
  releaseTicket == 0
      → 显式定位（滚轮/键盘/程序化，无手势身份）：现行为不变
        （takeOverScrollActivity + scrollBy；"真实定位接管"这一 Astra 判决保留）
  releaseTicket != 0 && releaseTicket != scrollReleaseTicket
      → 具名拒绝（如 "scroll_move_gesture_stale"）：不移位、不接管、不动当前票
        （与 H1-C"拒绝换绑前入队的旧增量"同一判决族）
fling 成功（beginInertialScroll 返回 true）→ scrollReleaseTicket = 0u64 一次性消费
```

**票据消费矩阵（逐项理由）**

| 事件 | 票据动作 | 为何 |
|---|---|---|
| BEGIN（takeover:/POINTER_BEGIN） | **发放** =epoch，复位 reveal 守卫 | 释放权自新触摸夺取视口一刻归属它 |
| 同手势 MOVE（非零精确票） | **不消费、不清零** | 本 bug 的根因；MOVE 是同一意图链的中段，不是定位 |
| 旧 MOVE（非零失配） | **不消费、具名拒** | 消费=旧帧可剥夺新手势释放权，正是票据要防的形状；移位则等同旧增量污染（H1-C 先例） |
| 旧 END（fling 零/失配） | 不消费、具名拒 `inertia_release_ticket_stale` | 现行为，不动 |
| 同值 reveal | 首次接管+清零；重试不重复（lastRevealTakeoverNodeId） | "活动100、reveal 同100 不得续跑"与"重试不得误杀新手势"都是既有 Astra 判决，原样保留 |
| 成功 END（fling 精确票） | **一次性消费**（清零） | 一次释放权只行使一次；防同 epoch 重放 fling 重启/二次加速。这也是"MOVE 不清票"的必要补面：成功释放后，同 epoch 残余 by: 自动落入"旧 MOVE"被拒，而非被当作同手势 |

## 五、生产摘录反例（针对现存确定性 test 的形状）

`ohosExplicitScrollIntentTakesOverAndInvalidatesTheTicket` 与 `ohosBlankAreaTakeoverIntentStopsInertiaAndIssuesTheTicket` 的负控，都把**带非零票的 `by:`** 钉成"显式定位要求清零"。生产摘录反例：

- OHOS 宿主上**不存在**任何以非零 gestureEpoch 发 `by:` 的显式定位生产者（证据5）；非零 epoch `by:` 的唯一来源是活动触摸手势的位移采样（证据2）。
- 因此"by:40 + 票8 = 显式接管"钉的是生产不可达输入；生产可达的形状恰是 normal_terminal.raw.txt 的 takeover:E → by:E → fling:E，而该形状在旧判据下**必死**——即旧测试钉死了本 bug 本身。
- 修正形状而非删判据：显式接管判决改钉在 `by:40, 0u64`（跨平台显式步无手势身份）；同手势形状由新测试 `ohosCurrentGestureMovesPreserveTheReleaseForInertia` 钉住（它已按生产时间线写好：takeover:8 → by:40 → fling:1.0 == true）。

## 六、随修复的最小测试改动（非整文件覆盖）

1. fixture：`ohosExplicitScrollIntentTakesOverAndInvalidatesTheTicket` 中 `by:40, 8u64` → `0u64`（断言全保）；负控 `by:25, epoch11` → 改 `epoch 0` 或改钉为具名拒；新增旧 MOVE 拒绝测试（offset 不变、票据不变）。
2. fixture（新测试内补强）：fling 成功后 `ticket()==0`、重放 `fling:1.0(8)` 被拒。
3. py：docstring 第 8–9 行判据改写为分流语义；必名清单加 `ohosCurrentGestureMovesPreserveTheReleaseForInertia`；RED_GUARDS 新增一条针对新分流条件的变异（如 `releaseTicket == scrollReleaseTicket` → `false`，期望新测试红）——现有 `takeover-ticket` 变异只守 `takeOverScrollActivity` 函数体，**守不住**"MOVE 重新无条件接管"的回归。

## 七、验收建议（normal 真机序列 + 反例）

在 sha93beb… HAP 上，uitest 驱动：
1. **拖动→惯性**：drag -100 后 WINDOW_VIEWPORT 最终 requestedOffset **超过** 100（指数尾，τ=325ms、≤2500ms、v<0.01 停止）；"增量恰等于拖动量"是 bug 签名，必须消失。
2. **触摸停止**：尾段中 new BEGIN → 尾立即止、新 by: 以新 epoch 交付、新 fling 可启动。
3. **reveal**：尾段中 Tab 到裁剪外节点 → 即使 reveal 不产生新 offset 活动也停、旧手势迟后 fling 被具名拒。
4. **显式/公开写入**：尾段中程序化 by:(epoch 0) 或公开字段写入 → 接管生效、尾止、offset 保留、写入正常接受。
5. RED/反例：py `--selftest` 下新 RED 变异必须使新测试失败、clean 全绿；窗口侧具名失败日志确认第四节 A/B 之分。
