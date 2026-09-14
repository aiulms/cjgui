# 大阶段：连续指针交互与共同操作控件

## 已执行指导补证：键盘路由与最终产物

坐标拖动/UDS交错已有执行结果；键盘不能仅由AX/公开值未变推断“未到scene且不是源码问题”。受控 direct keyDown 成功不覆盖 NSApplication/NSWindow responder 分发，因此补充了最小事件观测。实际 application route 现已验证，详见下节；桌面工具事件来源仍未观测，不把它归因到工具或源码。

最终报告已补当前隔离 bundle 的 PID/指纹、原始 GUI/UDS 混合证据入口，并因 native 生产修改重新导出/构建最终消费。ACTIVE 已将本阶段合并为单一当前结论；本节保留为已执行的指导依据。

## 当前结论：当前隔离实例、键盘路由与混合负载

### 2026-09-14 已验证结果与未替代边界

已在不触碰用户旧 PID 的前提下，以独立 bundle ID、临时数据与 descriptor 启动当前源码的两个普通消费者。坐标实际拖动后经真实公开读回：文档滑块 `128 → 外部 352 → 人工 192`，规则分隔条 `436 → 外部 416 → 人工 452`；二者的正常源码包均重新构建。这里的“人工”仅指桌面工具发出的坐标鼠标输入，不能替代物理键盘或呈现验收。

同一 `CjguiMacosApplication.pumpOneTurn` 中的真实 UDS caller 与预先入队的指针更新已交错：无关 B owner 的 `SET_PREVIEW_LIMIT=256` 保持 A capture，A 正常 end，B scene `1 → 2`；同 owner A 的 `SET_PREVIEW_LIMIT=416` 取消 capture，遗留 move/end 均返回 `99`，最终值仍为外部值。两个阶段各有 `overlap=true`、有界 pointer queue 高水位 `2`，transport `ready_high_water=1`。这证明受控 native/真实外部调用的同调度重叠，不宣称物理输入延迟或完整前台体验。

此前桌面自动化的 `Right` 后 AX/公开值不变（小写 `right` 也被工具拒绝），这本身不区分工具投递、目标 window、responder 或源码。受控对照现分别执行 direct responder 与真实 `NSApplication sendEvent`：二者状态均为 `0`、focused node `9101`；application route flags `31`（application、target key window、app key window 一致、overlay first responder、overlay receipt），owner adjustment 由 `1` 到 `2`。原始记录为 `/private/tmp/cjgui-pointer-capture-app-route-final/probe.log`；它证明生产 responder 链在这些条件下可用，但不等同 CUA 或物理键盘事件。物理键盘、系统 IME、VoiceOver、安装、公证、发布仍未验。

当前 normal document/rule bundle 已在 native 修正后重建；document executable SHA-256 为 `86c71876ae50f7605aa21fb1c526a389488ad37837b1a13d25dfe657c27c97b6`，rule executable SHA-256 为 `872f80e38e3d1e3306a561c0fd2cd67392e2235e36bdf2c12cdeae79dc9ee519`。隔离 document bundle `/private/tmp/cjgui-pointer-keyboard-manual.HlDZxQ/CJGUISharedDocumentKeyboardCheck.app`（PID `89253`，改写 bundle metadata 后 SHA-256 `688801b43c7e32bdfcc1171ce5dcb34500d9645db04dc05381907d226714c8dc`）已由 CUA Raise、坐标拖动建立 pointer focus 后发送 `Right`；AX 读回 slider 与对应状态文本从 `160` 同步到 `192`。这证明当前桌面自动化的键盘链路，不能替代另行未跑的物理键盘或系统 IME。该 GUI 观察来自当前任务的 CUA AX/screenshot 流，未伪造为本地日志。真实 UDS 交错 probe 的临时 descriptor 为 `/private/tmp/tmpDirnzOqv3/connection.cjgui`（进程结束后不再有效），原始 native/调度日志为 `/private/tmp/cjgui-pointer-public-interleave-app-route-final/probe.log`、公共外部 client 回包为同目录 `public-calls.log`。当前导出在含空格目录的 source/preview payload 同为 `56df3bd50a5065c8f7f6002a82d58517962e60a09bf671e1a31842cbb0cbcc8a`，三消费者成功构建，根为 `/private/tmp/cjgui-framework-preview-consumption.Gki9VN`。

同一当前 document CUA AX/screenshot 还显示中文正文和 `emoji 🙂 不会被拆开。`，且列表项、编辑区及状态预览三处一致。这是 CJK/emoji 当前可见渲染证据。解锁后，正常 document 窗口通过原生编辑控件粘贴 CJK/emoji 文本至 v12，再经公开 `REPLACE_RANGE(expected=v12, UTF-8 63..63)` 追加 `CAS 追加：已核验。` 至 v13；AX 三处投影和公开 read-range 同时读回完整内容，故 CJK GUI（粘贴）→CAS→GUI 已通过。CUA 直接 `typeText` 同一 CJK 输入只留下 ASCII，不能声称 CJK 键入已通过；物理键盘与系统 IME 仍未跑。

用户随后确认是其手动关闭原先仅作保护性观察的规则 PID `13539` 与文档 PID `18369`，并授权重启。按原 normal bundle 已重启为规则 PID `9726` 与带 `--with-connection` 的文档 PID `9728`；重启本身未写入用户数据。随后 CJK/CAS 验收仅改动了默认文档的未保存内存状态，未传入 `--file`、未保存到文件。重启不替代当前源码 GUI 验收，也不以历史截图或日志补作该证据。

- 已执行授权范围：用户旧 PID 保持；临时数据、独立 bundle ID/标题/descriptor 的当前源码普通应用完成坐标拖动、公开读回、外部设值和继续操作。AX/截图能力仅用于记录其实际观察，未把自动化的无变化按键当作输入投递结论。
- 在同一个 application 调度中，让真实 public UDS caller 与 pointer burst 重叠；只测 idle B 没重绘不能证明 B 获得服务。分别覆盖无关 owner 写入保留捕获、相同 owner 写入取消旧捕获且最终旧 move/up 不能覆盖新值；让 B 有一个独立实际事件/动作并验证它前进。记录有界队列、执行顺序/版本、end/cancel、CAS结果及相关scene，避免先顺序完成两批工作再称并发。复用已有低频/突发probe，不无故重跑全套已过矩阵。
- Terra负责交错/捕获正确性，Luna承担明确混合负载和消费证据包；前台操作只保留一个执行者。生产若修复则更新对应回归/最终导出，若只补验不重建无关产物。源码与受控报告不替代整阶段，完成即主动报告指导。

2026-09-14 指导授权立即实施；原执行任务 Terra/xhigh，复用 Luna/high，原目录，无新工作树，无提交安装发布。

## 为什么推进与最终能力

当前点击、键盘/快捷键、滚动、文字拖选已有真实实现；native mouseDragged 主要服务活动文字选区。新增通用连续指针交互，让开发者通过公共仓颉组件组合可拖动分隔区域与数值滑块。鼠标按下后移出原控件仍可连续拖动，松开或取消后干净结束；外部系统可以按已有授权直接设置同一个尺寸/数值，读回语义和界面结果，随后人继续操作。AI 不需要模拟鼠标轨迹。

这是输入/组件/语义三条主线的通用交付；不做白板产品、IDE、窗口停靠系统、跨应用文件拖放、多点触摸或新的 Agent runtime。布局复用阶段已由指导抽查最后报告、binary hash 和正式导出绑定，按已有工作量/耗时/公共消费范围接受。显式区域 warm/local 有收益，完整失效有开销；不继续无限优化该缓存。GUI/IME旧欠项继续承接。

## 复用已有资产

复用 [通用窗口事件与命令](../../runtime/cjgui/src/composable_ui_window.cj)、[组件及唯一布局结果](../../runtime/cjgui/src/composable_ui.cj)、[native 窄适配](../../runtime/cjgui/native/cjgui_internal_renderer.m)中的 hit-test、clip、session/scene 身份、bounded event FIFO、文字拖选及系统焦点，和现有 shared_operation_core 的动作授权/状态读回。

按[设计导航](DESIGN_INTENT_INDEX.md)及已有避坑研究的事件重入、关闭、局部视觉更新分工处理：native 只归一化事件/坐标和平台捕获，仓颉负责目标/阶段/状态决策；不另开 nested loop、不把 NSEvent/原生对象暴露到公共层，不将高频移动扩成每事件全量语义序列化。现有文字拖选/系统组合输入保持原负责模块，不强行迁入新手势体系。

## 完整交付范围

1. **公开指针事件与捕获生命周期。** Terra 明确纯仓颉事件数据、begin/update/end/cancel、目标/会话身份及捕获责任。坐标单位和转换必须清楚，同最终布局/clip命中一致。只有合法命中和组件接受才开始；移动出控件继续发给捕获目标，不能改发下面的控件。释放、Escape取消、窗口失焦/关闭、目标删除/禁用/换绑、上层模态阻挡均按明确策略结束，不遗留捕获。键盘可用性不能依赖鼠标。框架只保必要交互状态，不能复制应用可写内容。
2. **刷新中的连续性与冲突。** 拖动会改变 scene，不能每刷新一次就误判自身事件失效；用稳定目标、窗口代际及当前语义绑定验证可继续范围。真正换对象/关闭重开后拒绝旧事件。外部修改同值发生在拖动中，采用明确可解释的取消/重基准/版本冲突之一，默认不能在下一次旧 move/up 覆盖外部已接受结果；外部修改无关对象不打断拖动。业务拒绝与取消策略清楚，取消是否回退由组件/owner契约决定，不能悄悄撤掉其他参与者的更新。把当前多窗口生命周期与事件预算直接复用。
3. **两个可复用控件真实消费。** 提供可组合 split view（至少一种方向，min/max与窗口变小行为明确）及 slider（范围/步长/键盘调整）。控件由同一公共交互机制实现，不能在 native 写样例专用逻辑。分隔区保持子树正确布局/命中，数值遵守范围与业务约束；窗口最小尺寸冲突、越界移动、零可用长度、快速反向都不产生非法几何/数值。至少一个现有普通消费者采用分隔区、另一个组合消费滑块，业务示例仅作验证，不扩备份功能。若同一消费者同时展示两者，也须有独立公共使用片段证明可组合。
4. **人和外部系统操作同一状态。** 开发者明确 pane size/value 的 owner 与作用域（窗口局部或共享业务），公开语义含当前值、范围、可用动作和精确窗口归属。外部设置进入同一仓颉操作与校验路径；不为 AI 建第二可写状态，不要求每次模拟 begin/move/end。复用已有授权/动作注册和 target reads，仅在对应应用启用，不把所有窗口全局开放。验证人事件→读回值、授权外部设值→scene对应→人继续，含 stale/拒绝/拖动交错；程序化 native 事件与实际人工输入分别标记。
5. **连续负载可用性与安全整合。** 允许合并同目标的连续 move，但不能丢 end/cancel、混合不同窗口或跨语义边界合并；有界队列/单轮工作，繁忙拖动不饿死外部调用和另一个窗口。记录等量事件输入、实际处理/合并数、owner结果、相关scene、无关窗口工作量和释放后状态。用固定 binary 分别测低频与突发更新的实际阶段时间/工作量，每主要条件30有效样本；若计时口径仅接收或submit，明确不等于物理呈现。不追虚构帧率，不用全量重绘掩盖捕获错误。

## 验收与分工

先复现生命周期/交错反例，再实现；覆盖移出后松开、取消、目标消失、刷新继续、外部同值冲突、多窗口独立与关闭重开、范围/尺寸边界。规范布局仍是真相，缓存不能让拖动后命中旧位置。保留文字拖选、正常点击、滚动和相关键盘回归；IME只做相关系统集成不自研。

普通bundle通过公共API运行两类控件和外部真实调用；前台可用则实际拖动/键盘及旧中文/滚动/多窗场景合并验证，锁屏只记GUI not_run，继续受控事件与代码工作。生产修改稳定后一次相关测试、根构建、声明/FFI影响检查、diff检查及最新导出含空格路径真实消费，保存原始证据和指纹，不重跑无关文字/缓存大矩阵。

Terra 亲自确定捕获、失效、并发/业务交错及native边界；接口明确后给 Luna 一个完整的公共控件/消费者/针对性验证包，写集隔离，不把两个模型放在同一文件盲写。复用已有子代理，完成通知直接给Terra，由它整合；不为频繁进展消息反复唤醒指导。**同一 cjpm target 的 build/test 串行**：上一阶段已确认并行写产物会产生伪造的构造器/模块错误，写集隔离不代表构建目录隔离；无需为此复制工作树。

必要旧问题和本阶段新能力一起做，按AGENTS累计失败/K3升级；长期workaround沿既有反馈入口记录，未经授权不发上游issue。完整阶段交付或重大阻塞主动给指导任务 01a08f0f-e1ce-71c1-9a6e-4eee08308d61 报原始证据、边界与下一建议；不要完成一个控件或一项probe就停工。
