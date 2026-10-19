**裁决：保留“窗口拥有活动”和“候选携带请求代次”两条主线；拒绝仅靠 `liveStamp` 判断活动存活、用 `changed || active` 请求刷新，以及保留可变全局启用开关。** P4 还必须区分“初始速度”和“区间起点速度”。

本次只读核对了当前主树、snapshot、宿主和本地 Flutter，并复算公式；未修改文件、运行构建或操作设备。下述实验是实施时的判别要求，尚未执行。

## Q1：活动归属与生命周期

**判定：窗口拥有活动正确；“所有权桶＋liveStamp”不足以直接作为活动注册表。**

主树已经有 `ownedViewStateViewports`、`reconcileOwnedViewStateAfterAcceptance` 和统一释放入口，可以复用所有权机制。但必须另有一份很小的 **accepted 滚动绑定记录**，原因有三点：

1. **对象仍被拥有，不代表当前参与布局。** 所有权收集递归遍历声明树；隐藏 Tab 页保留子树，但布局不输出其内部 viewport。直接遍历所有权列表会继续推进隐藏页。登记活动应依据当前 accepted 布局中的 scroll binding，隐藏时停止活动，保留其视图状态。见[所有权收集](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:11127)与[隐藏页布局规则](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui.cj:7816)。
2. **`liveStamp` 不能识别换绑。** 同一对象留在树里，但其 node/resource/语义绑定已经改变，旧活动仍须失效。反过来，自身滚动接受新帧时 `liveStamp` 会变化，活动不能因此被杀。
3. **当前绑定键不包含 viewport 对象身份。** 保持 node/resource/语义不变，只替换 viewport 对象，当前 `acceptedBindingEpoch` 可能保持不变。仅在活动记录里增加 viewport ID，只能阻止旧 tick，不能阻止旧 END 在新对象上启动活动。应把 viewport 身份纳入滚动绑定比较，并让这类变化退出“同画面免 native 提交”分支。见[绑定键](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:6436)和[场景等价比较](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:7874)。

**最小机制：注册表留在窗口，`nativeInputScene` 提供 accepted 绑定事实。** 不把可变活动塞进场景快照，也不另建通用动效系统。

```text
ScrollBinding = {
  windowLifetime, viewportIdentity,
  nodeIdentity, resourceId, acceptedBindingEpoch
}

Activity = {
  binding, activityGeneration,
  integrator
}

onAcceptedScene:
  next = 当前 accepted 场景的唯一 scroll bindings
  终结绑定消失或改变的活动
  保留绑定相同的活动
  acceptedScrollBindings = next
```

按 viewport 身份去重；同一 mutable viewport 被两个独立 scrollArea 使用时，应拒绝歧义绑定，不能靠重复 step 解决。

**最小终止入口集合如下。**

| 入口 | 必须做的事 |
|---|---|
| 合法 raw touch BEGIN | 在点击/滚动仲裁前，终结其包含 viewport 的活动；先验证事件身份 |
| 显式定位、显式 reveal | 接管活动代次；以实际 accepted 为起点，替换旧活动的未接受目标 |
| accepted 绑定移除、换绑、隐藏 | 接受成功后终结；候选失败不影响旧活动 |
| close 意图、Surface 退役、宿主停机 | 立即停止推进；所有权仍按既有 native 销毁/结算规则释放 |
| `releaseOwner` | 校验 owner 后执行幂等终止，作为最终兜底 |

其中有两个现成接缝不能直接照用：

- **只在 `dispatchPointerEvent(BEGIN)` 停止不够。** OHOS raw BEGIN 目前主要冻结手势状态；普通滚动、空白区域触摸不会立即产生该指针事件。需要一个携完整 GestureKey 和冻结 viewport binding 的内部触摸接管通知，不应伪造控件的 POINTER_BEGIN。见[raw BEGIN 路径](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:4045)。
- snapshot 的停止调用位于绑定检查之前，顺序应反过来，否则旧绑定事件可能停止当前活动。见[现有停止位置](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj:5333)。

`requestOffset` 也不能简单统一加 `stop()`：当前惯性经 `scrollBy → requestOffset` 写入，会把自己停止。应拆开“显式接管”与“内部请求写入”：

```text
explicitJump / explicitReveal:
  校验目标
  retireActivityAndAdvanceGeneration()
  从 accepted 计算目标
  writeRequested(target, Explicit)

inertialTick(ticket):
  校验 binding + activityGeneration
  writeRequested(target, Inertia(ticket))
```

`revealAcceptedNodeIfNeeded` 当前把 requested 传给 planner 作为偏好。显式 reveal 接管惯性时，不能继续偏好旧惯性的 pending 目标；应使用 accepted 偏好。已有同一 reveal 的重试可以保留自己的目标，但不能每次焦点恢复、每次接受都重新执行接管。见[reveal 入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:6578)。

还须给释放准入保留一个可消费一次的手势票据：**绑定 epoch 相同不代表旧 END 仍有启动权。** 新 BEGIN 或显式定位使旧票据失效，旧 END 不能重新启动已取消的活动。

Flutter 的 `jumpTo` 也是先结束活动，再判断位置是否变化；这个生命周期原则可借鉴，但其直接写 pixels 不能替代 CJGUI 的接受事务。[本地参考](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/scroll_position_with_single_context.dart:197>)

**可区分实验：**

- 惯性中按住空白内容，不移动：下一活动推进前停止。
- 陈旧 BEGIN 到达：当前活动不被停止。
- 同对象换语义、同语义换对象、移除再插入：旧 tick/END 都无效；普通自身刷新继续。
- 切到另一 Tab：隐藏 viewport 停止，已接受位置保留。
- accepted=100、惯性 requested=140，显式定位到100：即使没有即时可见位移，也必须取消旧活动。
- close 遇到 PENDING：允许结算原票据，禁止继续产生惯性请求。

## Q2：请求代次与有界待决

**判定：P3 的核心比较正确，但“stage 时读取当前代次”只有在读取请求到 stage 之间不可交错时才成立；还漏了其他写入口和刷新保活。**

候选应冻结的是：

```text
CandidateViewportFact = {
  candidateId,
  requestGenerationUsed,
  solvedOffset,
  contentExtent,
  viewportExtent
}
```

`requestGenerationUsed` 必须与布局实际读取的 requested 值来自同一次快照。否则存在：

```text
布局读取 A.offset
B 到达并推进 requestGeneration
stage 把 B.generation 标给 A.offset
commit 误认已确认 B
```

当前单 owner、单候选门可以让 viewport 内的 staged 单槽继续使用，**前提是该槽在原候选结算前不可被其他 solve 覆盖**。若无法保证，就采用类似现有 split track fact 的不可变候选记录；不需要请求队列。

最小提交逻辑：

```text
commit(A):
  accepted = A 的完整布局事实

  if currentRequest.generation == A.requestGenerationUsed:
    requested = accepted.offset
  else:
    requested = clamp(currentRequest.offset, A 的新合法范围)
    保留其后续请求身份，不将它记作 A 已确认

  清除 A 的 staged 事实
  根据剩余 requested 与 accepted 的差异安排后续投影
```

**A/B 判别例：**

初始 accepted=0、最大偏移300。

| 操作 | accepted | requested |
|---|---:|---:|
| A：请求80，代次g；候选新最大偏移120 | 0 | 80 |
| B：请求180，代次g+1 | 0 | 180 |
| 接受A | **80** | **120，仍属于B** |
| 接受后续B候选 | 120 | 120 |

这同时满足推进 A、保留 B、按新范围夹紧 B。

各路径必须统一处理：

| 路径 | 修正要求 |
|---|---|
| `requestOffset`、惯性/拖动内部写入 | 有效请求变化推进代次 |
| `requestInitialOffset` | 当前直接赋值；限定初始化使用并计代次，或至少让所有有效写入计代次 |
| `clampToAccepted` | 若在提交外改变请求，必须推进请求修订，不能成为无代次写入口 |
| 内容缩小 | accepted 使用候选事实；较新的请求独立夹紧 |
| `discardStagedExtents` | 只丢对应候选，不改 accepted、不回滚较新请求 |
| 明确接管但数值相同 | 活动代次仍必须失效，不能被位置变化判断吞掉 |

`acceptedRequestGeneration` 可以用于诊断，但不能代替候选捕获的 generation。单看当前 requested/accepted 两个代次，无法知道 A 实际布局用了哪个请求。

另一个容易漏掉的问题是：**保住 B 的字段，不等于 B 一定还会被提交。** 正常接受路径已有 `refreshRequestEpoch` 保护，但同画面的接受分支仍会无条件清掉刷新标记；所有接受出口都要在消费原刷新请求后保留后续请求造成的 dirty 状态。[同画面接受分支](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:5551)

若 B 夹紧后恰好等于 A，保留 B 的请求身份即可，无需重复提交相同位置；不能仅因 generation 不同无限刷新，也不能把 A 的 native 接受记成 B 的接受。

**可区分实验：**

- 上表分别走同步接受、PENDING 后接受和拒绝后恢复。
- 首次布局后、接受前调用 `requestInitialOffset`，验证不会被旧候选覆盖。
- 候选扩大范围，但提交前 `clampToAccepted` 改变请求，验证旧候选不能吞掉这次变化。
- 在接受回调中产生 B，特别覆盖“同画面”分支：B 不仅留在字段中，还能获得后续投影。
- 连续失败期间检查：至多一个在途候选和一个最新请求，不累计逐帧队列，也不因 retained dirty 无限重建。

## Q3：`changed`／`active` 契约

**判定：拒绝 `changed || active` 用于 `requestRefresh()`。刷新与下一次唤醒必须分开。**

最小结果：

```text
ActivityStepResult {
  changed: Bool  // 本次是否改变 requested 位置
  active: Bool   // 本次结束后是否还需未来推进
}
```

精确返回表：

| 本次结果 | changed | active | 请求刷新 | 安排未来 tick |
|---|---:|---:|---:|---:|
| 活动继续，有整数位置变化 | true | true | 是 | 是 |
| 活动继续，仅累计亚像素 | false | true | 否 | 是 |
| 本次停止，有位置变化，包括部分移动后触边 | true | false | **是，交付末帧** | 否 |
| 本次停止，无位置变化 | false | false | 否 | 否 |
| 重复时间，原活动仍有效 | false | true | **否** | 是 |
| 时钟倒退 | false | false | 否 | 否 |
| 已停止后再次调用 | false | false | 否 | 否 |

时钟倒退按现有约定终结活动，不制造位移，也不回滚先前已经产生的请求。

```text
r = window.stepWindowActivities(now)
if r.changed:
  window.requestRefresh()
if r.active:
  保证下一次有界宿主唤醒
```

OHOS 当前循环本来持续 pump，因此短期若必须保留 Bool，**让 Bool 只表示 changed**，另提供只读 `hasActiveWindowActivities()` 即可。共同宿主若可能长睡，则用 active 缩短等待或登记下一唤醒，不能靠无变化的完整刷新维持活动。

自然结束后保留末次请求，由普通接受事务提交；后续 step 返回 false。提交失败后的恢复属于请求/事务调度，不能靠把停止状态反复报告成 changed。

宿主日志改为读取此次结果或只读状态，删除日志中第二次 step。[现有副作用日志](/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cjgui_app/entry/src/main/cangjie/ohos_app.cj:616)

**可区分实验：** `v=0.02` 首步250ms必须返回 `(true,false)`；相同时间连调十次不增加刷新请求；触边末帧只标记一次；随后推进不再增加 scene 提交。

## Q4：截止积分与时间域

**判定：截止积分方向正确，但 P4 把全程初始速度和区间起点速度混用了。**

令全程初始速度为 \(v_s\)，阈值为 \(\epsilon\)：

\[
T=\min\left(2500,\ \tau\ln\frac{|v_s|}{\epsilon}\right)
\]

仅在有限且 \(|v_s|>\epsilon\) 时启动。等于阈值时截止时间为0，最小契约是直接不启动。

设已积分到 \(t_0\)，当前真实年龄为 \(a=\text{now}-\text{start}\)，则：

\[
t_1=\min(a,T)
\]

\[
\Delta x=v_s\tau
\left(e^{-t_0/\tau}-e^{-t_1/\tau}\right)
\]

也可以使用区间起点速度：

\[
v(t_0)\tau(1-e^{-(t_1-t_0)/\tau})
\]

**不能每段都用全程初始 \(v_s\) 乘后一公式。** 同样，如果用当前速度计算剩余阈值时间，就不能再把它当全程 `t_cross` 减去 \(t_0\)。

建议的最小伪码：

```text
begin:
  start = lastObserved = now
  integratedTime = 0
  stopTime = min(Tmax, tau * log(abs(initialVelocity) / threshold))

step:
  校验活动票据
  now < lastObserved: 终结，返回(false, false)
  now == lastObserved: 返回(false, active)

  t1 = min(ageSinceStart(now), stopTime)
  积分 [integratedTime, t1]
  累计亚像素，量化并写 requested
  integratedTime = t1
  lastObserved = now

  active = t1 < stopTime 且未触及运动方向上的边界
  返回(actualPositionChanged, active)
```

**`inertialElapsedNs` 的裁决：若继续用它作为积分起点，就必须表示“已积分时间”，截断到截止点。** 真实观察时间由 `start/lastObserved` 单独表达。不要让同一字段同时承担真实年龄和积分年龄。

例如首次调用发生在2600ms：

- 真实年龄是2600ms；
- 积分终点是1496.680310ms；
- 余下时间不再积分；
- 活动终结，不把余下时间转入下一活动。

最好直接从绝对年龄计算终点，避免逐步换算、累加和取整带来的漂移。

**独立复算期望值：**

以下范围充足，采用现有“累计位移向零取整”规则。

| 输入/时间安排 | 正确连续累计位移 | 整数交付 | 终态 |
|---|---:|---:|---|
| \(v_s=1\)，10ms分步直到结束 | 321.75px | **321px** | 停止 |
| \(v_s=1\)，首步2000ms | 321.75px | **321px** | 停止 |
| \(v_s=1\)，首步2600ms | 321.75px | **321px** | 停止 |
| \(v_s=-1\)，首步2600ms | −321.75px | **−321px** | 停止 |
| \(v_s=0.02\)，首步250ms | 3.25px | **3px** | 停止 |

其中：

- \(v_s=1\) 的阈值时刻为 **1496.680310446ms**。
- 旧2000ms积分为324.309280px，所以得到324；它越过了固定阈值时刻。
- 旧2600ms得到0，是积分前上界判断丢掉了整段。
- \(v_s=0.02\) 的阈值时刻为225.272834ms。

`t_max` 先到也使用同一公式。例如 \(v_s=100\)，2500ms时仍高于阈值，但必须截止；累计32485.169473px，整数交付32485px。

其他边界：

- 负速度只改变位移符号，阈值计算使用绝对值。
- 若上次只积分到1000ms，本次到2000ms，只积分1000→1496.680310ms。
- 到边界时，即使本次发生部分移动，也应立即返回 `(true,false)`，不能等下一次“移动失败”才停止。
- 量化的是**累计位移**，不是绝对位置；否则反向运动会引入不同取整规则。
- 有限速度也可能造成整数转换溢出。现有 `abs(v) <= 1e300` 并不足以保证安全；应在浮点转整数前按剩余合法距离截断，或实施明确的有限速度准入上限。

还有一个独立时间口径：snapshot 目前在消费 fling 时传 `MonoTime.now()`，并非 END 原始时刻。上述修正解决“启动后的掉帧”；若验收要求整条轨迹不受 END 排队延迟影响，还须把释放时间转换到经验证的同一单调时间域，不能直接混减 native 时间戳和 `MonoTime`。

**可区分实验：** 对相同初值采用10ms、60Hz、120Hz、2000ms单步、2600ms单步及混合重复时间序列；正反方向最终整数位移一致。另分别覆盖阈值先到、上界先到、部分触边及 END 排队延迟。

## Q5：策略声明与 macOS 单次消费

**判定：保留共享、不可变的策略定义；拒绝保留可变全局启用状态。把写全局变量的位置挪进窗口构造函数，仍会跨窗口串扰。**

最小 API 可以是：

```text
ScrollPhysicsPolicy {
  PlatformDefault,
  ExperimentalExponential
}

window.configureScrollPhysics(policy: Optional<ScrollPhysicsPolicy>)
    -> Result

window.scrollPhysicsInfo()
    -> { declared, effective, support, specification }
```

统一 specification 至少包含：

| 项目 | 契约 |
|---|---|
| 默认值 | `PlatformDefault`：共同核心不合成额外惯性 |
| 实验策略 | 固定指数衰减，experimental |
| 单位 | viewport 逻辑 px、px/ms、ms |
| 参数 | τ=325ms、阈值0.01px/ms、上界2500ms |
| 清除 | `None` 恢复默认，终结本窗口活动并使旧票据失效 |
| 非法配置 | 具名拒绝，原配置和活动保持 |
| 平台支持 | 单独公布声明值与实际支持状态 |

清除时取消旧活动尚未接受的目标，按接管规则回到 accepted；不能清掉后来显式请求，也不能伪称已撤销正在 native 结算的候选。

手写与公开生成应走同一策略 token、校验和发现入口。首包可以让全部 scrollArea 继承所属窗口策略，不必增加逐 viewport 参数；但只增加 Cangjie getter、生成发现协议看不到策略，仍未满足共同声明。若策略来自候选描述，其生效也必须随候选接受，非法候选不能改变旧窗口策略。当前生成 scroll 属性入口尚无该策略。[生成属性准入](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_generated.cj:470)

**P5 的默认关闭是必要条件，不是完整保障。** 还应保证：

- macOS 系统滚轮/惯性事件继续走原消费路径，不据此再合成 fling。
- 实验惯性只接受支持后端的合法 raw-touch release，不能只凭 `"fling:"` 文本启动。
- 无 GestureKey、旧释放票据、已被显式定位取消的释放，都不能启动。
- macOS 未支持实验策略时，显式配置应拒绝保旧，不能静默叠加。

当前 macOS `scrollWheel` 将事件交给既有滚动路径；保留这条单次消费即可。[macOS 入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:10980)

**可区分实验：**

- 两窗口分别启用/关闭，互不影响；关闭启用窗口不改变另一窗口。
- 清除后旧 tick、旧 END 无效，重开使用默认策略。
- 非法 token、NaN/Inf、阈值以下和极端有限速度分别检验拒绝/安全截断契约。
- 同策略下，手写与公开生成 viewport 都由窗口推进。
- macOS 系统惯性序列只消费原事件，人工活动启动次数为0。

**最小实施顺序：**

1. 固化本答中的数学、A/B 接受、raw BEGIN 缺失、隐藏页和同画面刷新反例。
2. 修请求快照/代次、提交与丢弃，以及所有接受出口的后续 dirty 保留。
3. 修截止积分、安全量化和 `changed/active` 返回契约。
4. 接窗口 accepted 绑定记录、生命周期终止、合法 BEGIN 通知及释放票据；保持严格 ABI/绑定校验。
5. 接每窗口共同策略与发现协议，宿主只调窗口推进；移除样例枚举和诊断 step，最小同步 snapshot 后再做正常消费验收。

