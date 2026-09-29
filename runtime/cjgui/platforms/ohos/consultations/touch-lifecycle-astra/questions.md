# H 触摸机制第二次接续：聚焦只读裁决请求

## 背景
OHOS 自绘 GUI：ArkTS XComponent → C++ bridge（有界触摸队列）→ renderer（手势状态机：
pending→viewport-scroll / pointer-drag / editor-hold）→ 仓颉核心窗口（scroll 意图进共享
viewport，指针相位进 capture，ACTIVATE/FOCUS 进控制器）。单指；活动手指由 bridge 过滤。

## 确定反例（宿主对生产函数实测）
1. 压缩丢跨阈值事实：BEGIN(60,120)→MOVE(60,150)→MOVE(60,120)→END(60,120)。
   未压缩真值 activate=0/scroll=1（到过 150 距起点 30>12 阈值后回到起点）；
   现压缩（只保留最新 MOVE 60,120）后 activate=1/scroll=0。
2. 满载删唯一 MOVE：同手势仅 1 条 MOVE 时再加边界事件造成 256 压力（现策略满载丢
   最旧 MOVE），结果 overloadCancels=0/activate=1——滑动退化成点击。
3. END 尾段丢失：scroll 手势 BEGIN y100→MOVE y80→END y50，END 只量化旧余量，
   actual=20 expected=50（END.y−lastY 未入累计）。
4. 场景版本当绑定身份：激活事件冻结"按下时刻 projectionVersion=100"，下一帧
   同绑定（节点/资源/动作/几何全同）场景版本=101，核心 resolveInput 严格比版本
   → 同绑定换帧后点击被拒。现 R3 只断言发出旧版本，未同时证"换绑拒绝"与
   "同绑定存活"。
5. 旧 CANCEL 反馈取消新手势：A 的 BEGIN/MOVE/CANCEL 与 B 的 BEGIN/MOVE 交错；
   核心消费 A CANCEL 后调用 native cancelPointerCapture()（该调用无身份参数），
   把当前 B 的捕获也取消了。宿主实测 new_gesture_active_before=1 after=0。
6. snapshot 窗口 flushPendingSemanticFocus 只核 node/semantic/resourceId，缺主核心
   已有的 semanticIncarnation/fieldId/actionName/operationActionName 校验：旧 A 请求
   在同槽新字段 B 上也能聚焦。

## 现有接缝（摘要）
- bridge 队列：TouchRecord{action,x,y,generation(surface 代次)}；同身份 MOVE 压缩
  （无条件，替换最新坐标）；满载丢最旧 MOVE；相位边界满载→队首代次整组移除+队首
  注入 CANCEL。无 pointerId 字段（bridge 已过滤副指，但队列记录不含 id）。
- renderer 手势：TouchGesture{targetNodeId/targetResourceId/targetNodeKind/
  targetProjectionVersion(冻结), scrollAccumY(浮点余量), pointerStreamOpen/Ended,
  hasViewport(viewportNodeId/ResourceId)}。激活事件目前携带冻结版本。
- 核心窗口：resolveInput(nodeId, resourceId, nodeKind, projectionVersion) 严格等于
  当前场景版本才接受；另有 resolveLocalTextContinuation 对 kind=28 文本续写宽容。
  指针捕获：pointerCaptureActive/Node/OwnerVersion/ModalLayerId，kind=40 无条件清捕获。
  语义焦点 pending 携带完整 LayoutNode（含 incarnation/field/action/operation），
  flush 全字段校验（macOS 主核心已如此）。
- 核心布局节点有 semanticIncarnation（同一 owner 绑定的代次）、fieldId、actionName、
  operationActionName；renderer 的 pod 无这些字段（只有 nodeId/resourceId/kind/
  projectionVersion/label/value/semanticId）。

## 请裁决的问题（按优先级）
Q1 压缩等价条件：有界队列保留什么才能使"阈值跨越、方向转换、viewport 逐次夹紧"
   与未压缩序列可判定等价？给出最小充分集（例如：跨阈值不可逆闰 + 方向转折样本 +
   最新坐标 + END），以及在 renderer 差分累计语义下的具体队列形态。
Q2 满载协议：当压缩后仍满，应取消谁、保留谁？给出按手势代次（而非 surface 代次）
   的受害者选择与注入 CANCEL 的位置，使唯一 MOVE 不被删、新手势可恢复。
Q3 绑定身份：renderer pod 无 incarnation/field/action。激活冻结用什么才能既拒绝
   真换绑又不误杀同绑定换帧？（可否由核心在 flush 后按"节点存在+绑定字段哈希"
   二次校验激活事件？或 pod 需要新增 bindingEpoch 字段？评估两条路的契约代价。）
Q4 取消方向：native→核心的"平台通知取消"与核心→native 的"主动取消"如何携带/校验
   capture 代次，使 A 的终结不触碰 B？给出最小字段与两侧规则。
Q5 END 尾差与反向夹紧：MOVE/END 共用累计入口时，viewport 夹紧（offset 上下限）
   应在哪一层逐次应用才能使 -30,+30 @offset=0 的结果为 30 而非 0？
