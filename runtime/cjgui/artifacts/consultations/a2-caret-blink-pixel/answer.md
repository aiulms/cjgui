## 只读结论

当前文件的 SHA-256 与给定值一致。本轮没有修改文件、运行构建或操作桌面。

**普通 input 的四次全白采样，首先有一个确定的取样错误。** 探针查询的是 display byte `0`，得到标签起点 `x=7`，随后在该点采样。[探针](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/probe/text_caret_geometry_probe.cj:544) 但聚焦路径把 `"phase"` 的选区放在**值末尾**；绘制 caret 时还会加上 `"Blink field "` 前缀。[聚焦实现](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:10022)、[装饰位置计算](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:12327) 对此固定 ASCII 样例，实际插入点对应 display byte `17`。所以 `x=7` 的白像素不能证明普通 input 的 caret 没画出来；byte `17` 的 drawable 像素尚未采过。

原始日志还与问题摘要有一处冲突：[run.log](/private/tmp/cjgui-caret-blink-consumer-build/run.log:77) 记录 `started=0/1/1`，字段依次为 status、visible、hasRect。即本次 `action=0` 当场报告**可见**，而非摘要中的 `visible=0`。`stop` 的隐藏态及后续几何稳定有证据；本次日志不支持单独修“reset 后仍隐藏”。时钟钩子只观察 overlay 目标节点，不能证明该状态已进入被编码的 drawable。

| 假设 | 当前直接证据与边界 |
| --- | --- |
| accepted node 与 view 副本不同步 | accepted 几何查询读 `overlay.nodes`，Metal 读 `view.composableNodes`。[几何查询](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:18551)、[编码入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:6953) 接受时数组是浅拷贝，源码倾向于共享节点对象，但日志没有同帧对象身份或 view 节点的 hidden/rect，尚不能排除后续换版。 |
| Metal 漏绘 | painter 有“未隐藏才追加 caret、正文纹理之后提交”的路径。[绘制分支](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:7054) 已有 drawable 帧与成功像素读回，但没有该帧 caret 顶点数或正确插入点的像素，故仍未证实绘出。 |
| 采样或坐标 | 普通 input 的 byte `0` 错位已由源码确定。旧声明 caret 探针另将小数 `x` 向下取整；注释称取整点“一定在条内”，与实际使用未取整 `rect` 生成形状的代码不符。[取样函数](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/probe/text_caret_geometry_probe.cj:378)、[形状生成](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:4965) |

旧声明 caret 还有一条**独立的生产回归路径**：A2 将所有非 `caretBlinkTarget` 的已有 caret 置为隐藏，而该 target 只接受当前聚焦的可编辑 input；旧用例是未聚焦的 owner 声明 `TEXT` caret。[目标筛选与门控](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:8653) 其全白也受小数取样影响，不能仅凭该像素判定门控就是唯一原因；但接受后全局隐藏声明 caret 的行为应单独纠正。

## 两个判别实验

1. **复用普通消费者和现有 TESTING 接口。** 保持同一焦点、场景和四相位顺序，记录实际选区；对此样例查询 display byte `17`，按返回矩形与 2× scale 计算矩形**内部的像素中心**，用现有 precise drawable readback 取样，同时记录每次 `frameIndex`、时钟结果、[encoder stats](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:19873) 和六个正文计数。若正确点按可见→隐藏→可见变色，普通 input 的本轮失败就是取样假阴性；若可见帧比隐藏帧多一个矩形的六个顶点而像素仍白，再查 clip、画序与读回坐标；若顶点不变，进入实验 2。旧用例也改为按实际矩形内像素中心采样，不能继续用 `floor(x)` 作绘制判据。

2. **仅在 TESTING 内作同帧节点快照。** 在时钟动作后及 Metal encode 前，按 `nodeId/index/resourceId/projectionVersion` 记录 `overlay.nodes`、`session.composableNodes`、`view.composableNodes` 的对象身份、`textCaretRect`、`textCaretHidden`、`textCaretIsDeclared`，并关联提交帧号。overlay 可见而 view 隐藏或对象不同时，修接受同步；三者一致且可见、却无 caret 顶点时，查 painter 的进入条件；顶点已提交仍无正确点像素时，查 clip、覆盖与 readback。用同一快照看旧 `TEXT` 用例，能直接验证非目标声明 caret 是否被 A2 隐藏。无需增加 public API。

## 修复与验收边界

先修探针的显示偏移和小数像素中心，再根据上述同帧结果决定普通 input 是否需要生产修复。**声明 caret 的全局隐藏回归应另修**：闪烁只管理它拥有的活动 input caret；owner 声明 caret 保持原有显示及显式撤回语义。不要为了全白像素改正文布局、纹理键或盲调 painter。当前日志不支持先改 phase reset；若另一次同版本原始日志确有 `action=0` 后 `visible=0, hasRect=1`，先核对二进制身份和同帧节点快照，再作为独立状态故障处理。

接受修复至少要有：普通 input 在真实 Metal drawable 上可见→隐藏→再可见，失焦后旧定时回调不再提交闪烁帧；各相位 accepted 几何不变，六个正文 raster/upload 计数不变；旧 owner 声明 caret 在正常窗口可见且撤回后消失。还需保留一次正文编辑使计数增加的反向对照，并覆盖提交失败后不能把未呈现的相位记作像素成功。现有 fake-clock 通过和这次全白 readback 都**不是** Metal/普通消费者验收通过。
