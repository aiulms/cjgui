# H 惯性接续：共同窗口活动与接受事务的聚焦只读裁决请求

只读分析：不修改任何文件、不运行构建、不操作设备。请独立反驳下述方案，给出根因级判断、可区分实验与最小实施顺序。

## 背景与当前事实（均已核对到符号）

CJGUI 是一个自绘 GUI 框架（仓颉核心 + 平台宿主）。OHOS 后端 = ArkTS 薄壳 + XComponent + C++ renderer；macOS 后端 = 原生桥。共享窗口/视口状态在 `runtime/cjgui/src/composable_ui.cj` 与 `src/composable_ui_window.cj`（**主树**），OHOS 交付副本在 `runtime/cjgui/platforms/ohos/snapshot/`（**snapshot**，由 sync_platform.sh 发布）。

惯性滚动包（r10）现状：

1. `CjguiComposableUiScrollViewport`（主树 composable_ui.cj:2111-2357）已有：
   - `requestOffset/scrollBy` 维护 `requestedOffsetValue`；`stageExtents/commitStagedExtents/discardStagedExtents` 由布局 solve 与窗口接受推进 accepted（2121-2474）。
   - 惯性活动：`beginInertialScroll(velocity, MonoTime)`（2247）、`stepInertialScroll(now)`（2276）、`stopInertialScroll()`（2343）、`isInertialScrollActive()`（2350）。解析衰减 v(t)=v0·e^(-t/τ)，τ=325ms，停止阈值 0.01px/ms，上界 2500ms，亚像素余量集中量化。
   - 全局实验开关 `cjguiComposableInertialScrollEnabled`（2109，默认 false）。
2. 活动目前**不由窗口拥有**：样例 settings（runtime/cjgui/examples/settings_counter_application/src/settings_counter.cj:347 的 `stepActiveInertialScrolls`）与 thermo（thermostat_application/src/thermostat_app.cj:267）各自 step 自己的手写视口；OHOS 宿主循环（labs 的 ohos_app.cj:600）逐 pump 调用样例的该方法。公开生成 region 的 scrollArea 视口无人推进。
3. fling 文本进普通滚动通道：OHOS renderer 在 END 时估计速度并发 kind30 事件 `"fling:<px/ms>"`；核心窗口 `applyViewportScrollStep` 解析并调用 `viewport.beginInertialScroll`（snapshot composable_ui_window.cj:3903-3935）。
4. `commitStagedExtents`（主树 2424-2450）在提交时**无条件** `requestedOffsetValue = acceptedOffsetValue`。
5. `stepInertialScroll` 现版本在 `inertialElapsedNs > 2500ms` 时**积分前归零**返回 false；速度耗尽判定用整段积分后的速度。
6. macOS 侧窗口不启用该活动（系统自带惯性），开关默认 false。

## r10 指导复核的必做要求（原文摘要）

- 「**让共同窗口真正拥有活动与提交。** 主 src 的窗口以 accepted viewport 注册并驱动有界活动，H snapshot 最小同步；手写和公开生成只声明同一 experimental 策略，沿原 C 落实默认值、单位、发现、严格准入及清除，撤掉两样例逐个枚举与全局开关的控制权。」
- 「活动绑定窗口/viewport/acceptedBindingEpoch/活动代次；新触摸、显式定位/reveal、移除换绑和停机统一终结，程序化定位从实际 accepted 接管。」
- 「为候选记录其请求代次：A 的接受只能确认 A，不能覆盖后来的 B；失败保留 accepted 和有界待决请求。」
- 「推进结果分清 `changed` 与 `active`（或等价语义），停止但位置变化也提交最后一帧，重复时间零变化不制造刷新。宿主诊断只查询，移除 `inertia check` 日志里再次 step 的副作用。macOS 既有系统惯性保持单次消费。」
- 数学反例（指导独立复算）：v0=1、τ=325、阈值0.01、范围充足：10 ms 分步为321 px，首步2000 ms为324 px，首步2600 ms为**0**（错）；固定阈值时刻应为 **1496.6803 ms、累计 321.75 px**。另 v0=0.02、首步 250 ms 已改 requested 约3 px 却返回 false，宿主不请求末帧。

## 我方拟议方案（请逐条反驳/修正）

### P1 窗口拥有活动
- 主树窗口在**接受**含视口的场景时注册该 viewport（登记桶：按 liveStamp 的代次清理，含 viewport 对象的稳定身份 viewStateIdentity）。
- 新增窗口 API：`stepWindowActivities(now: MonoTime): Bool`（或等价），内部遍历已注册视口并对活动中的调用 `stepInertialScroll`；有任何位移或活动仍在 → 返回 true（宿主据此 requestRefresh）。
- 样例的 `stepActiveInertialScrolls` 退役；OHOS 宿主改调窗口 API。
- 终止统一：窗口的新触摸 BEGIN、显式定位/reveal（`revealAcceptedNodeIfNeeded`/`requestOffset` 的显式定位路径）、视口移除/换绑、窗口关闭/停机 → 对相应视口 stop。

### P2 策略声明
- 保留 `cjguiComposableInertialScrollEnabled` 语义作为「滚动物理策略」的框架级 experimental 开关，但把「启用」从两个样例 init 的控制移到**窗口级策略声明**（如窗口构造/`configureScrollPhysics`），样例只消费不自持全局。默认值、单位（px/ms）、阈值与上界作为框架常量公开可查询（discovery）；严格准入（NaN/Inf、非有限、低于阈值）保持。

### P3 请求代次与有界待决
- viewport 增 `requestGeneration`：`requestOffset` 实际改变 requested 时 +1。
- `stageExtents` 记录 `stagedRequestGeneration = requestGeneration`；`commitStagedExtents` 只在 `stagedRequestGeneration == requestGeneration` 时把 requested 收敛为 accepted；否则保留新的 pending requested（并 clamp 到新 extents）。`discardStagedExtents` 保留 pending。
- 每个 viewport 至多一个 pending 请求（现状即单槽），不引入队列；「有界待决」= 该单槽 + 不在 commit 时被清。

### P4 时间域
- `stepInertialScroll` 改为绝对时间截止积分：
  - 令已耗 `t0 = inertialElapsedNs/1e6`，本步 `ΔtReq = elapsed`（自上次 tick）。
  - 阈值交点 `t_cross = τ·ln(|v0|/threshold)`（|v0|>threshold 时才存在）；上界 `t_max = 2500ms`。
  - `ΔtEff = min(ΔtReq, t_cross - t0, t_max - t0)`（若任一为负则活动已应在上一刻终结）。
  - 位移 = v0·τ·(1-e^(-ΔtEff/τ))，新 v = v0·e^(-ΔtEff/τ)；`inertialElapsedNs += ΔtEff`（注意：未消费的时间不累计？还是按真实时间累计？——**这处需裁决**）。
  - 到达 t_cross 或 t_max 后：活动置停，但若本步有整数位移交付 → 返回 changed=true 让宿主提交末帧；无位移交付 → 返回 false。
- 返回语义：`changed || active` 为 true（宿主请求刷新）。重复时间（Δt=0）返回当前 active 而不制造刷新（保持现有：返回 true 但无位移时宿主不应重复提交——**此处需确认宿主契约**）。

### P5 macOS 单次惯性
- 策略开关默认 false；macOS 窗口不声明该策略 → 不会叠加人工惯性。

## 请裁决的问题

Q1（活动归属与生命周期）：P1 的「窗口注册桶 + liveStamp 代次清理」是否为最小正确机制？还是应把注册表放在 `nativeInputScene`/场景接受路径的其他位置？「显式定位/reveal 终结活动」的具体触发点应选哪些既有函数（主树 `revealAcceptedNodeIfNeeded`、`requestOffset` 的调用方、`releaseOwner`）才不会误杀同帧惯性推进？给出最小集合与理由。

Q2（请求代次）：P3 的「stage 时记录代次、commit 比对」是否覆盖 A/B 竞争的所有路径（含 `clampToAccepted`、内容缩小、`discardStagedExtents`、`requestInitialOffset`）？有无更小的等价机制（例如 requested 与 accepted 各自带代次比对）？请给反例检验：候选 A（对应请求代次 g）在接受前，请求 B（代次 g+1）到达；A 的 commit 必须(a)把 accepted 推进到 A 的值、(b)保留 B 为 pending、(c) clamps B 到新 extents。

Q3（changed/active 契约）：宿主循环当前语义是 `if (step(...)) requestRefresh()`。停止但位置变化的末帧如何在不引入「停止后重复帧」的前提下交付？重复时间 Δt=0 时返回什么才不制造刷新？请给出精确返回值表（活动继续/停止有位移/停止无位移/重复时间/时钟倒退）。

Q4（时间域）：P4 的截止积分公式在 v0<0（反向）、t_cross 在区间外、t_max 先到、以及「上一次 step 未消费完 t_cross 时刻」等边界是否都正确？`inertialElapsedNs` 应累计真实经过时间还是已积分时间（截断到 min 后两者不同）？按指导给出的反例（首步 2000ms→324px、首步 2600ms→0、固定阈值时刻 1496.6803ms/321.75px）逐一给期望值以校验我的实现口径。

Q5（策略与窗口声明）：P2 把「启用」从样例移到窗口，但保持单一可查询的框架开关，是否满足「撤掉两样例逐个枚举与全局开关的控制权」且不破坏 macOS 单次消费？若窗口需要每实例策略，给出最小 API 形状（含默认值、单位、清除语义）。

## 参考

- 本地 Flutter（只借思路，不引入依赖）：`/Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/scroll_activity.dart`、`scroll_position_with_single_context.dart`、`gestures/velocity_tracker.dart`。
- 关键源码：主树 `runtime/cjgui/src/composable_ui.cj:2100-2474`、`src/composable_ui_window.cj`（`applyViewportScrollStep`/`commitStagedExtents` 调用点 10997、reveal 6552、活动停止点）；snapshot 同名路径。

请按 Q1–Q5 分节作答，每节给：判定、理由、最小接口/伪码、可区分实验、若拒绝我方方案请给替代机制。
