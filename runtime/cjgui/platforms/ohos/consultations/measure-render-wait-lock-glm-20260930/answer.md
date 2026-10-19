# 结论先行

**锁循环是真的，但要精确命名：它不是永久死锁，而是「队列中介的等待环 + 2 秒有界反转停顿」**。owner 在 `g_sessions.lock` 内同步 `waitFor()`（有 2000ms 上限），渲染线程 FIFO 队首若是需要 Session 锁的 Redraw/CaretHit/Present，就互相等：owner 等 MeasureJob 出队，渲染线程等 owner 放锁。`waitFor` 超时打破了环，代价是：全渲染线程停摆 2 秒（期间所有 present/redraw/IME 回调/pump 全被 Session 锁拖住）+ measure 拿到误导性的 `DRAWABLE_UNAVAILABLE(7)`。拟议的最小修复方向正确，且与文件内 present/hit_test 已有模式同构，不改变测量/销毁/Session 合同。

---

## 1. 证据链（全部来自 `host/ohos_renderer.cpp`，行号为当前源码）

**owner 侧持锁等待（唯二违规点）：**
- `cjgui_internal_renderer_measure_composable_text`（6452–6478）：`std::lock_guard g(g_sessions.lock)`（6459）的作用域覆盖 `g_render.post(jobRef)`（6469）和 `job->waitFor()`（6471）。
- `cjgui_internal_renderer_measure_composable_multiline_natural_height`（6480–6501）：同样结构（6486 / 6496 / 6497）。
- `kRenderWaitTimeout = 2000ms`（~332 行）——这就是环的自破上界。

**渲染线程侧在 job 执行中取 Session 锁：**
- `run()` 出队后在**不持** `RenderThread::lock` 的状态下 `execute()`（2578–2606：`g.unlock(); execute(job.get()); g.lock()`）。因此两把锁没有嵌套序，环是**时间序 + FIFO** 造成的，不是经典 AB 锁序环。
- 队列严格 FIFO（`jobs.push_back` / `jobs.front()+pop_front`）。
- `executeRedraw → drawNodeText`：3741 处进入任何文本类节点就 `lock_guard(g_sessions.lock)`（3751），**不需要节点处于编辑态**。
- `executeCaretHitTest`：2971 取 `g_sessions.lock`（前置条件是 paintedLayout 可用）。
- `executePresent` 真实路径也走 `drawNodeText`（3106 起）——这就是"existingdraw 就有这条风险"的出处：**Measure 前面排着 Present 同样触发**。

**环的形成条件（推断，但每一步都有源码依据）：** owner 持 S → post M（M 排在队尾）→ waitFor 阻塞；渲染线程正在执行队首 R（Redraw/Hit/Present），R 阻塞在 S 上；M 在 R 之后永不出队；2 秒后 owner 超时放锁，R 才能继续。

**合法路径对照（证明纪律本已存在，measure 是漏网）：**
- present：7300 短锁快照 → 出作用域 → post（7347）→ waitFor（7349）→ 重锁结算（7354/7387）。
- pump 的 caret 命中：8026 `g.unlock()` → `postCaretHitAfterRedraw`（8039）→ waitFor（8041）→ `g.lock()` 复核（8050 起）。命中 job 只带值身份（text 副本、node pod 副本、contextId），不带 native 对象——与你的描述一致。
- pump 的 blink：8180 `g.unlock()` → `postCaretBlink` → `g.lock()`。
- `waitFor()` 调用点全查过：只有两个 measure 在锁内，其余三处（hit_test 6580、present 7349、pump 8041）都在锁外。**最小 scope 恰好覆盖全部违规类。**

**新 blink 放大机制（推断）：** `postCaretBlink` 有 `caretBlinkRedrawQueued` 合并，但同时有多个不合并的 Redraw 生产者：IME insert/preview/composition/set_selection 回调在持 S 下 post Redraw（5324 起、8555、8598、8670），caret 命中 post Redraw+Hit 两个 job（2494–2507），图片完成通知 post Redraw（4180 后）。编辑态下这些事件与 core 的 relayout/measure（每次文本变更都量）天然同窗，blink 让"无输入时队列也周期性出现 Redraw"。

## 2. 触发后的具体症状（可区分实验）

- 签名日志：`measure_composable_text failed status=7`（6473）伴随其后 ~2s 内没有 `redraw frame ok` / `present frame ok`，超时后连发——一条日志链即可定性。
- **区分点**：`kCaretHitTestFailureWindow` 计数增长不是本 bug（pump 的 hit 等待在锁外）；只有 measure 的 status=7 超时才是。设备复现配方：聚焦多行编辑节点（blink 激活）+ 输入触发 IME Redraw 与 relayout measure 同窗；或 blink 期间 resize 触发整树 measure。
- 反向证据（支持"非永久死锁"）：超时后系统自愈，因此表现为**间歇性 2 秒冻结 + 布局失败**，而非挂死。

## 3. 拟议修复评估：正确，且有一个顺序细节必须写死

```
{ 短锁：lookupSessionLocked(session) 非空，否则 INVALID_SESSION }   // 入口核身
构造 MeasureJob（参数全为不可变副本，现状即如此，6462–6467）
g_render.post(jobRef); job->waitFor();                              // 全程无 S
{ 短锁：再次 lookupSessionLocked(session) 非空，否则 INVALID_SESSION }
*outMeasurement / *outHeight = job->measurement;  return OK;
```

- **释放必须发生在 `post` 之前，不只是 `waitFor` 之前**：`post → ensureStarted` 里可能 `thread.join()` 旧线程（2397–2446 段）。在 S 内 join 是又一个"持锁阻塞等待"类，虽然目前可能不可达，规则上应一并消除。
- **MeasureJob 本身零 Session 引用**（2151–2159：只有 text/font/width/measurement），destroy 后迟到执行无 UAF；超时后遗留的 Cancelled job 被 `executeMeasure` 照常计算但 `finish()` 被忽略（2054–2062：Cancelled/Done 不改写）——无害，可选微加固是给 `executeMeasure` 加 `consumeCancelIfRequested()` 早退（非必需）。
- **合同影响分析**：
  - 测量值：纯函数于入参，修复不可能改变数值。
  - 销毁：今天 destroy 会因 measure 持锁被拖最长 2s；修复后立即可行。等待窗内被 destroy → 返回 `INVALID_SESSION(11)`，恰是头文件对死会话的规定状态（2233–2237 行注释），**没有削弱任何既有保证**。
  - Session：token 单调不复用（5608 `nextToken` 递增），重查 token 即身份重查；与 hit_test 等待后重查（6583–6588）同构。
  - **拒绝的替代方案**：等待后不重查、直接返值。技术上安全（纯值），但会让"core 已 discard 的会话"测量成功，在停机/重启竞态下复活陈旧布局；重查保持 measure 隶属于会话生命周期。你提议的重查是对的。

## 4. 验收测试：`scripts/test_render_measure_lock_native.py` 已在位，评估其可靠性

该脚本摘**真实生产函数体**（`extract_decl` 按定义摘取，738–756，现两函数均为定义、marker 匹配），配真实 `std::mutex` + 真实工作线程 + 200ms 缩放等待。worker 先取 Session 锁（建模"排在前面的 Redraw"）再完成 MeasureJob。

- **负控成立**：原版代码下两个测试都返回 1（test1 status=99 超时、test2 同样超时而非 INVALID_SESSION）——这正是"原版 wait 返回超时错误"的可执行反例。
- **变体判别力**：test2（retire → 必须 INVALID_SESSION）能区分"带重查"与"不带重查"两种修复——不带重查的变体会返 OK+42 而 fail。这是好的区分反例。
- **保真度缺口（如实声明，均不削弱结论）**：① 建模队列是单 worker，不显式建模 FIFO——可接受，反例只需一个锁需求 job 排前；② 超时返回 99/200ms 而非生产 7/2000ms，判别不依赖具体码值，若想对齐可把枚举改名为 7；③ 未覆盖 destroy-before-post、`stopping` 拒收路径、遗留 Cancelled job 迟到执行——超出最小 scope，可作为后续。④ 测试在当前 HEAD 必红，必须与修复同变更落地，不能先合测试。

## 5. 未覆盖与边界

- 我只读了直接相关的两 C ABI、RenderThread（post/run/execute 家族）、drawNodeText、executeCaretHitTest、present、pump、WaitableJob、destroy、头部合同与测试脚本；未审 scene/IME 业务正确性（你已声明 Context/scene 无变化，源码上 measure 也确实不触碰它们）。
- "新 blink 使触发机会更高"是机制推断（生产者频度），非运行统计证据；定性上成立因为单实例即足以成环。
- 普通编译 scope 问题按约定未混入。

**一句话裁决**：环真实、有界（2s/次）、症状是全渲染停顿 + measure 误报 status=7；修复 = 两处把「持锁跨 post/waitFor」改成「入口短锁核身 → 锁外 post/wait → 出口短锁重查 token」，释放点放在 `post` 之前；配已存在的 `test_render_measure_lock_native.py` 双测试（含退休命名测试）作验收，原版必红即负控。
