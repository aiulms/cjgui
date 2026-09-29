我核对了所给两份源码的 SHA-256。**当前最早的未证实环节是 blink target 的资格，不是 Metal painter。** 时钟接口的 `hasCaretRect` 实际计算为“找到 [caretBlinkTarget](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:8653) 且该节点有装饰矩形”；`action=0` 即使找不到 target，也会设置下一次 deadline。因此 `started=0/0/0 deadline=5530000` 不能表示可见相位已进入绘制。[accepted geometry 查询](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:18551)则独立读取持留排版，能返回 byte 17 的矩形而无需焦点或装饰矩形。

**先做一次 `--blink-only` 运行，记录两个同主线程快照：** 一个紧接 native `focusNode` 返回、尚未进入第二段 `settle`；另一个放在现有 TESTING clock 的 `action=3` 入口，并把 `action=0` 的现有结果关联到相同的 scene version/frame index。用只读的 TESTING 日志或内部快照即可，不改 public API、不增加 pump。每份快照记录：

- Cangjie focus 返回路径（直接 native 或待 reveal）、native status；`makeFirstResponder` 返回值。
- `key / visible / miniaturized / appActive`、`firstResponder == inputProxy`、`editable`、proxy selection 的 location/length，以及是否有 marked text。
- active `(nodeId,index,resourceId,kind,projectionVersion)`；overlay 中 node 32 的对应身份、interactive/readOnly、`textCaretRect` 和 hidden；view 中 node 32 的对象身份及矩形；accepted scene version、frame index、`caretBlinkTarget == node32`。

这些值须在各检查点一次读取。[focusCommittedNodeId](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:9850) 返回成功只证明找到了节点并调用 `focusNode`；[focusNode](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:9944)没有检查 `makeFirstResponder` 的返回值。Cangjie 的 [focusAcceptedSemanticNode](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/composable_ui_window.cj:6148) 还存在“先 reveal、稍后聚焦”的成功返回路径，故应记录走了哪条路径。

| 同次快照结果 | 首先定位到 |
| --- | --- |
| 焦点调用后 active 未设定，或 responder 不是 proxy | 焦点取得失败；若当时成功、`settle` 后丢失，则查期间的 key/responder 生命周期 |
| key、可见性、appActive 任一不满足 | 窗口资格失败；`window.start()` 发出激活请求不等于检查点时仍为 key |
| active 与 overlay node 32 的 index/resource/kind/version 不同 | 焦点目标与已接受投影失配 |
| 身份匹配、responder 正确，但 selection 非折叠、不可编辑或节点装饰矩形为空 | 选择/装饰准备链；预期 proxy selection 是 **`(5,0)`**，显示 byte 17 是加上标签前缀后的坐标 |
| overlay 有合格矩形，但 view 对象或矩形不同 | 再查 accepted→view 同步 |
| target 合格、hidden 随相位切换且确有对应新 frame，读回仍不完成或完成后像素不变 | 此时才查 present/readback、装饰绘制及矩形坐标对应关系 |

旧运行的 `0/1/1` 说明**当时 target 确实合格**，只是 byte 0 取样不能验证末尾插入点。改为 byte 17 的 geometry 查询和像素中心取样本身不改变焦点；新全量和单窗口运行均为 `0/0/0`，更值得核对激活、responder 或投影在 focus 后至 clock 前是否变化。仅凭现有输出，不能断定是窗口顺序；`focusNode` 在新聚焦时将 `"phase"` 的选择置于末尾且长度为零，probe 也没有输入操作，所以 selection-at-end 和组合态目前都没有直接反例支持。[单行装饰生成](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:12327)尤其依赖真实 first responder，值得在首个快照优先核对。

本次 `read=99` 表示[读回尚未完成](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.m:19774)，不是白色像素；声明式 caret 的红色正控仍应保留。六个正文计数不变只证明未新增正文工作，不能证明 blink 帧已提交。修复前应先得到上述门槛反例；最终仍须在普通 TextInput 上看到真实 drawable 的可见→隐藏→可见、几何和正文计数不变，以及失焦后停止定时帧。本次只读分析没有运行构建或桌面操作。
