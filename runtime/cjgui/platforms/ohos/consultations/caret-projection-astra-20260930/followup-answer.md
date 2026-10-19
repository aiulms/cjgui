**保活方案成立；需要把“成功绘制的对象”与“允许用于 accepted 命中”分开判断。**推荐一份 `lastPaintLayout` 加一份帧内 candidate，不需要第二套 Typography 缓存或公共协议。

本次源码指纹为 `f2dac3164c27…`。r9 已补足尾空行指标和 affinity 的平台证据；本轮未写源码、构建或操作设备。

1. **缓存保留实际对象，来源身份补上 Present ticket。**

   最小字段建议：

   | 类别 | 字段与用途 |
   |---|---|
   | 对象所有权 | move-only Typography 所有者、Measured 数值、实际 paint origin |
   | 绘制来源 | `renderEpoch/session/basePresentTicket/projectionVersion/paintSerial` |
   | surface 身份 | `window/generation/geometryRevision`，以及实际 density、尺寸 |
   | 节点与布局 | node/resource/kind、bindingEpoch、实际字体和布局参数、节点几何、精确可见正文 |
   | 输入身份 | paint 时的 context；命中请求另带当前 context，供执行及回泵复核 |

   **caret、selection、blink 相位不属于排版匹配条件**；它们变化不应让相同文字布局失去命中资格。`paintSerial` 用于标明查询实际用了哪一帧，不要求请求预先猜中它，否则普通 blink 换帧就会造成拒答。

   空正文需要同时记录“逻辑正文为空”和“实际排版用了占位空格”，避免把占位字符偏移返回给编辑协议。

   所有者只在 render thread 内移动和销毁。Job、Session、pump 只携带值，不携带 Typography 所有权。稳态一份缓存、绘制期间一份 candidate，目标对象峰值为两份；保留旧成功对象并允许新候选失败，本来就需要这一个临时重叠。

2. **Flush→accepted 窗口用两个事实表达，不复制对象。**

   建议给 Session 增加一个纯内部的 `acceptedPaintTicketId`，在现有两处 accepted 晋升临界区同步记录：

   - [`present_composable_scene` 同步成功路径](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:7222)。
   - [`settlePendingTicketLocked` 延迟成功路径](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:7068)。

   它只是现有成功票据的身份记录，不改变票据裁决或 owner。失败、ACK 回收、Redraw 都不推进它。

   | 时点 | 对象与命中资格 |
   |---|---|
   | Paint 完成、尚未成功 Flush | 仅帧内 candidate，不可命中 |
   | Flush 成功且后验检查通过，owner 尚未 accepted | 发布并保活对象，记录来源 ticket；命中返回 `paint_pending_acceptance` |
   | Session accepted 来源 ticket 与缓存来源相同 | 再核对绑定、正文、布局、surface；满足后查询同一个对象，无需重排或再 Flush |

   **必须使用 ticket，不能只比较 projectionVersion。**当前 [`configure_composable_scene()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:6848) 没保证传入版本唯一，版本相等不能证明是同一次成功提交。

   Redraw 的 `basePresentTicket` 必须继承 `lastNodes` 所属 Present，不能取绘制当时 Session 的 accepted ticket。反例是：B 已 Flush、A 仍 accepted，此时一次 Redraw 绘制的是 B 的 `lastNodes`；把它标成 A 会让未 accepted 的 B 冒充 A。

   草稿仍按既有合同处理：基础场景和绑定来自 accepted，缓存正文记录实际绘制的 composedText；不要求草稿等于 owner 已提交正文，否则组合输入期间会全部拒答。

3. **发布点正确，但“失败保留旧缓存”需要分情况。**

   [`drawNodeText()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:3634) 应把**传给 `TypographyPaint` 的那个对象**交给本帧 candidate，不能再创建一个参数相同的对象。caret、高亮继续查询本次对象。

   一个易漏点是当前 caret 几何失败分支在正文 Paint 后销毁 Typography 并返回。引入缓存后，**caret 拒答不应抹掉已经绘制的正文对象**；该对象仍可随真实成功 Flush 发布。

   [`executePresent()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:3120) 和 [`executeRedraw()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:2861) 都在现有 Flush 返回值与后验 lease/geometry 检查通过后执行：

   `lastPaintLayout = move(frameCandidate)`

   **这里必须允许 candidate 为空。**成功的新帧若没有绘制目标节点——移除、完全裁剪、目标布局失败——应清掉旧缓存，不能保留旧对象继续提供“当前画面”的几何。

   失败边界建议：

   - **尚未 Flush，且 surface 未变、旧 accepted 仍有效：**销毁 candidate，旧成功缓存仍可按旧身份使用。
   - **Flush 返回失败：**可保留旧对象，但先撤销命中资格，直到下一次成功绘制。本机头文件没有提供“失败一定没有呈现副作用”的保证，不能仅凭旧对象还在就宣称它仍对应当前画面。
   - **surface 句柄重建，包括同代 resize：**清布局缓存；既有 `lastNodes` 可保留供真实 Redraw，不能给旧布局改写 geometryRevision。
   - **terminal teardown/Shutdown：**在 render thread 中释放，早于 GPU context 销毁。调用方的 `shutdownAndJoin()` 收尾只确认已清空，不在那里销毁 Typography。

   [`executeCaretHitTest()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:2893) 删除临时 `layoutText/computeTextGeometry`，只查询合格缓存。当前 tap 是节点内坐标，应减去缓存的**节点内文本原点**；不要直接减绝对 origin，也不要重新计算居中原点。

4. **“已有 Redraw 一定在 hit 前面”目前不成立，严格 key 会影响首次点击。**

   当前普通短点击先 [`beginEditingOnNodeLocked()` 并置 tap pending](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:4550)，随后 pump 在 7815 处处理 hit；blink Redraw 到 7985 之后才投递。只有长按分支在这里提前排了 Redraw。

   因此，仅缓存编辑节点、严格比较 context、缺失即拒答，会使正常首击无法定位。草稿也有类似窗口：[`preview_text_ctx()`](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:8354) 先解锁发布新正文，再投递 Redraw，pump 可能抢在投递之前排 hit。

   **推荐最小接线：在 pump 排 hit 前，先提交新焦点或待绘制正文变化原本需要的正常 Redraw。**它必须真实 Paint、Flush，再让后面的 hit 消费缓存。命中函数本身仍不补排、不重试；前置绘制失败就具名拒答。不要等首次 blink 调度来补这个顺序。

   若要减少纯 context 变化导致的重绘，可采用更小的匹配范围：context 留在请求授权及回泵守卫中，布局匹配只比较实际节点绑定、正文、布局和 surface。只有旧对象确实绘制了完全相同目标时才可复用，保留原 paint context 作为来源，不把它改名成新 context。**缓存根本没有目标节点时，这种放宽无效，仍须先真实绘制。**

   空正文也要接通：当前 hit 函数及 pump 的 `!composed.empty()` 门槛应改为缓存可用性判断；查询实际占位布局后映射到唯一合法偏移 0。

需要补的反例可限制在这条缓存链：

| 反例 | 必须成立 |
|---|---|
| 实际 Paint 对象 A，随后命中 | 查询对象就是 A；hit 中 Typography 创建/Layout 调用数为 0。用对象序号取证，避免地址复用误判 |
| B 成功 Flush，暂停 accepted；期间插入 Redraw | 命中具名拒答；Redraw 仍归 B ticket；接受 B 后无需再排版即可使用原对象 |
| 同 projectionVersion、不同 ticket；同步与延迟接受分别执行 | 不按版本号误认来源，两条 accepted 路径资格一致 |
| 候选失败；成功新帧无目标；同代 resize；STOP | 旧缓存保留、禁用或清除符合上述边界；所有对象仅在 render thread 恰好释放一次 |
| 无编辑缓存的首次短点击、A→B 字段切换；暂停 preview 的锁外投递 | 明确验证 Redraw→Flush→hit 顺序；失败不得造 human anchor 或更改选区 |
| 空正文、emoji 第二行、尾空行、纯 blink 换帧 | 消费实际 Paint 对象，坐标与 affinity 往返正确；相位变化不造成无意义 stale |

本机 [TextPainter 的命中查询](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/painting/text_painter.dart:1735>)确实直接消费保留的 paragraph；CJGUI 还需要上述 ticket/accepted 身份衔接。

最终只需在修后 normal HAP 补这条新链的真实点击证据：`Paint 对象序号 → 成功 Flush → accepted ticket → Hit 同对象 → pump 采纳`。已有 phase/geometry/anchor 针对性测试不代替它，也无需因此重审 N1–N4。

