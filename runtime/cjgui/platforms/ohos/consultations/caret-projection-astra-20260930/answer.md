**方案方向成立，但还需补齐几个局部守卫才能实施收口。**完整 grapheme 查询、同一排版对象的行指标、Session 内 500ms 相位，以及现有 render thread 都可以保留；无需改变 owner、编辑协议或整体架构。

本轮只读审阅，目标源码前后哈希均为 `b91ee9fd40cc…`，未构建、未操作设备。以下区分已见源码问题与待验证风险。

1. **锁序可沿用；资源安全仍由现有 permit 链负责。**

   当前 [`run()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:2405) 释放 `renderer.lock` 后才执行任务。因此，现存 `sessions.lock → post()` 本身不能直接判为死锁。新增路径应坚持：Session 锁内决策、复制不可变请求，释放后投递；队列锁内只处理接单、去重和出队，不查 Session、不查宿主 lease、不等待任务或 join。

   唯一责任方应保持清楚：

   | 状态 | 唯一负责方 |
   |---|---|
   | blink 相位、截止时间、reset 消费 | pump，受 `sessions.lock` 保护 |
   | queued 标记、接单状态、运行代号 | RenderThread，受 `renderer.lock` 保护 |
   | Typography、Canvas、surface、缓存帧 | render thread |
   | lease 退役、NativeWindow 引用归还 | host；收到实际拆除确认后归还 |

   `leaseValid()` 是准入观察，**资源保活靠 host 引用与 renderer permit**；`busyGeneration` 没覆盖 redraw，不能用它证明 blink 已静默。[宿主实现](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/cjgui_host_bridge.cpp:933)

   同代 resize 可以继续 `teardownSurface(false) → ensureSurface()`；退役或换代才走终结确认。当前 [`executeRedraw()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:2677) 忽略 Flush 返回值，也没有 Flush 后复核。建议补具名失败及 lease/geometry 后检查，但不推进 accepted 或任何票据。已经进入平台调用的任务靠 permit 收敛，不能声称一次前置检查消除了所有 retire 竞态。

   另须挡住：**旧 pump 在锁外暂停 → STOP/START → `postIfRunning()` 看到新线程正在运行而误接旧请求**。请求应携带运行代号，入队时验证；仅清 queued 位不足以防止这种情况。

2. **队列去重之外，确实需要 Session 与缓存帧身份守卫。**

   当前有两个确定的源码缺口：

   - [`drawNodeText()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:3503) 按 `nodeId/resourceId` 遍历全部 Session；正文、选区与 caret 又分两次加锁读取。可混入另一会话，或形成“旧正文＋新 caret”。GLM 用平台选区和 accepted 日志排除这一可能，证据不充分。
   - [`lastNodes` 更新处](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:3020) 没保存所属 Session 和 surface 代次；terminal teardown 也不清缓存帧。存在“旧 G 帧缓存 → H surface 已创建 → H 的 Present 失败 → redraw 把 G 内容画到 H”的静态可达路径。

   最小修法是：缓存帧连同 Session token、surface 身份保存；Present 明确使用 `job->session`，Redraw 明确使用缓存帧所属 Session。一次锁内复制 composed 正文、caret、选区、context、blink 状态及绑定身份，随后排版和绘制只用该快照。节点匹配须覆盖 kind 和既有 binding 连续性，保留 `preservesActiveLocalText` 的合法延续。

   **不要直接增加 `lastProjectionVersion == acceptedProjectionVersion` 的硬门槛。**缓存帧在成功 Flush 后更新，而 accepted 在后续票据结算时晋升，两者存在合法时间窗；blink 不应介入结算。

   queued 位应在 **对应任务出队时、仍持 renderer 锁期间清除**，随后才读取绘制快照。这样允许“一笔执行中＋至多一笔排队”，不会吞掉绘制期间的新失效请求。普通 Redraw 不得清掉另一笔 blink 的标记，旧任务结束也不得再次清位。

   推荐把合并任务定义为“重绘当前有效帧”的唤醒，执行时读取最新相位，不保存排队时的可见性。若任务绑定具体 Session/context，跨身份请求不能因为一个全局 bool 而被吞掉，必须替换待处理请求或保留重投意图。

3. **blink 方案还缺“输入首帧”和“失焦擦除”两个条件。**

   仅在回调里置 `resetPending` 不够：当前 preview 回调立即排 Redraw，它可能先于下一次 pump 执行，首个输入帧仍读取旧暗相。

   保持 pump 唯一管理时钟的最小办法是：快照绘制条件使用  
   `eligible && (resetPending || caretBlinkVisible)`；绘制只读 pending，不消费、不计算时钟。pump 消费 reset 后设亮，并令 `nextDue = now + 500ms`。同轮 reset 优先于到期翻转。

   活动条件还应包括当前前台状态和有效绘制目标。仅 `editing && editingContextLive && !retired && collapsed` 不能证明应用仍在前台；现成 `foregroundLevel` 可以复用。

   失焦、非空选区或停用时，应撤销截止时间，并产生一次擦除失效。**不能因执行时已经不 eligible 就直接丢弃这笔擦除。**retired 缓冲仍可能承担文字延续，保留正文绘制与停止 caret 必须分开。

   reset 的来源应是实际输入/预览变化、上下文切换、实际选区变化和新 human anchor。相同落点的人类新锚可以 reset；同值平台回声不 reset，也不能因此取消原本必要的 selection 转发。[现有回声分流](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:8208)

   签名不能只比较长度，也不要纳入 projectionVersion、转发账本或恢复 ACK；否则等长替换漏 reset，或正常回声造成常亮。逾期只翻一次、下一截止取 `now + 500ms` 合理；16ms pump 等待上限不是端到端呈现延迟保证。

4. **几何方案成立，但完整簇查询还不等于完整 caret 定位。**

   已读[实际探针](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/platform-delete-probe/typography-r7c/typography.txt:1)：半簇空盒、完整簇有第二行盒，与当前 `[caret-1, caret)` 和首行 fallback 路径吻合。应删除该 fallback，而非再退到“前一簇近似位置”。

   具体边界建议如下：

   - 对**同一可见正文快照**调用纯 `cjgui_internal_renderer_grapheme_cluster_range`。不要调用带编辑上下文验证的 `_ctx` 包装，它会重新读状态，并拒绝某些 preview/restore 情况。
   - UTF-16→UTF-8 只做编码映射；上游查询遇低代理项时先定位所属 scalar，再交 ICU 求完整簇。不得切半个代理对构造前缀。
   - 如果公共选区落在 grapheme 内部，不能悄悄改 owner/选区，也不能画到簇尾却声称对应原偏移；无法确定时给内部具名“无 caret”结果。
   - 硬换行之后优先取下游簇。尾空行、连续空行使用同一 Typography 的实际行指标；空正文的占位排版也只服务绘制。禁止用平均行高乘行号、上一行盒或 whole-prefix 宽度猜位置。
   - 检查坐标有限且高度有效；零宽盒不等于错误，探针中负的 tight-box top 也不能直接判错。多盒、方向或行归属不明确时，不可一律取“最后盒 right”。

   本机 `GetLineMetricsAt` 明确为 API12，可用于本次 API24 下限；GLM 的“保持 API11”建议不适用。它必须在同一对象完成 Layout 后调用。[本机声明](/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/native_drawing/drawing_text_typography.h:2759)、[华为接口说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/drawing__text__typography_8h-V14)

   **尾空行指标仍是待补证项**：现有探针只有 lineCount 和 range boxes，没有该空行的 `x/y/height/startIndex/endIndex`。应补采这些字段，确定实际索引语义；拒答时无 caret 是正确失败行为，但不能据此宣布尾空行已修复。

   命中往返还有一个局部缺口：[`executeCaretHitTest()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:2773) 丢弃了系统返回的 affinity。软换行处同一偏移可对应两个视觉位置。最小方案是把 affinity 留在 native 的 HitTestJob/Session 私有状态，不改公共编辑协议；同值平台回声不要抹掉它。命中任务返回后也应复核 token/context/绑定及文本、排版签名，当前仅复核 nodeId 不足以挡住等待期间的替换。

最小确定性反例建议固定为以下几组，先保留旧实现失败结果：

| 反例 | 必须观察到的结果 |
|---|---|
| `a\n😀`、combining、ZWJ、skin、flag，以及原 58B/28UTF16 正文 | 半簇假查询拒答；修后 caret 查询完整簇，矩形对应真实第二行 |
| 空串、`\n`、`a\n`、`a\n\n`、换行后仍有正文、窄宽软折行 | 行首、尾空行正确；指标失败具名无 caret；软折行往返保留视觉行 |
| 复制正文后暂停，修改 caret/context；两个 Session 复用 node/resource 数字 | 单帧始终来自一个快照、一个 Session |
| G 成功帧后 H 创建成功但 Present 失败，再触发 blink；同指针同尺寸只变 geometry revision | 不把 G 缓存画到 H；resize 按 revision 校验，许可不泄漏 |
| 假时钟：0、499、500、2300ms；暗相输入后让 redraw 先于 pump；持续同值回声 | 到期单次翻转，2300 后截止为2800；输入首帧亮，回声不能延长亮相 |
| 暂停 renderer，反复触发到期/输入/失焦；再 STOP/START 放行旧请求 | 至多一笔 queued；最新失效不丢；擦除后无 blink 帧；旧运行请求不进入新实例 |

当前[几何假模型](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/test_text_geometry_native.py:203) 对相交码元就给盒，不能复现这次故障，需按实际簇拒答行为补强。另应删除 GLM 的 `caretX != longestLine` 判据：文末位于最长行时，两者可能正确地相等；应比较目标簇边缘和所在行。

最终 normal 汇合应使用**同一修后源码指纹的产品包与独立消费者**，分别绑定 HAP、PID、Session/context、surface generation/geometry revision。每个进程内完成真实输入→owner 精确字节/平台与核心选区读回→caret 正确行→亮暗连续变化→点击往返后续写→失焦擦除与停帧。仅 blink 期间 owner、projection、输入事件和 restore 票据保持不变。

帧证据必须覆盖实际 redraw Flush 及画面亮暗；当前 `submittedFrames` 只在 Present 增长，不能证明 blink 有帧或失焦停帧。旧探针 PID17216 与缺陷包 PID6213 是反例依据，不能拼接成修后验收。

