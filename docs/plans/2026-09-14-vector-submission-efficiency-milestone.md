# 大阶段：矢量 GPU 提交效率与正常应用接续

2026-09-14。Terra/xhigh 协调 Luna/high，原目录实施完整阶段，不提交推送。

## 目标与已有依据

让开发者在普通应用里组合数百个图形并持续修改其中一个时，不把所有缓存几何展开成大量重复顶点和小 draw；人和外部接口也能在真正导出的应用中接续修改同一图形对象。重点是通用渲染提交能力与普通应用消费，不增加更多图形种类或白板功能。

[前阶段](2026-09-14-composable-vector-graphics-milestone.md)的公开几何、真实像素、COW geometry准备缓存、无矢量1x路径、受控同owner命中按证据范围接受。最终 MeEyLO Preview 的两份vector源、composable_ui/window、host及native m/h七项与工作区相同，指导未重跑测试。仍欠真正导出应用的同对象输入接续、已有正常应用复用，以及整体尺寸/几何更新后的缓存边界证明，随本阶段明确承接。

真实热点入口 `/private/tmp/cjgui-composable-vector-scale-final/`：16/128/480 ellipse各30次局部paint更新，指导按原始样本重算 `stage_submit` p50为7.768/6.113/18.54ms，p95为8.88/7.288/19.765ms；480组记录encoder batches=10240、vertex bytes=32440320、encoder CPU=16583us、prepared geometry=3440640B。stage_submit包含native提交及可能等待，不是纯GPU时间；这组数据不证明规模越小越快。先核对批次/字节计数是单帧还是累计，以及它们和实际draw/upload的对应，不能直接用计数名字推导硬件行为。

六主线取舍：本轮优先处理有实证的自绘/GPU提交热点，组件和语义借正常消费补齐；文字排版、图片域、菜单、虚拟集合的既有路径继续复用，不为每轮重跑历史矩阵。长单段文字、物理输入/IME/VoiceOver和跨平台边界保留，不扩张本轮。沿 [设计意图导航](DESIGN_INTENT_INDEX.md)、[GPU有序合成](2026-09-13-ordered-gpu-composition-milestone.md)、[资源效率](2026-09-13-render-resource-efficiency-milestone.md) 和 [避坑原文](../research/gui-framework-pitfalls-intelligence.md) 的有序绘制、资源在途寿命与无谓重绘教训，复用prepared geometry和单一scene owner；不复活旧display-list审计链。

## 完整工作包

1. **有界GPU几何与批次提交。** 沿当前 `CjguiAppendMetalVectorShape`→通用顶点批次→encoder 查明176-byte逐顶点属性复制、4KiB小块提交与draw数量之间的实际关系。优先复用已准备几何，使用生命周期明确的Metal buffer/索引或实例数据，把不变拓扑与paint/布局/clip分离；选择最小兼容方案，不另造renderer。禁止仅增大setVertexBytes块越过API限制、丢三角形/降低质量、跨文字图片遮挡顺序重排、用反复光栅化贴图掩盖成本。若分析型椭圆等专用路径明显更合适，可在相同几何/抗锯齿与命中语义下采用，其他已支持形状不能回退。
2. **局部更新与资源寿命。** 同一对象的paint、几何、layout/clip、resize和1x/4x切换明确失效边界；更改单个对象不重新准备不相关几何和图片/文字资源。GPU buffer/缓存有明确容量、回收与在途引用，失败候选保留旧scene，关闭或晚完成不能访问已释放内存；不靠每帧waitUntilCompleted规避资源复用。把原先仅30次paint的验证扩为实际几何修改和整体尺寸变化，沿已有节点/COW更新，不引入第二业务状态。
3. **修正导出消费验收的实际缺口。** 当前公开 `framework_preview_vector_consumer.cj` 的 TEST_VARIANT_BEGIN 默认段调用 `chartWindow.invokeCommand("chart.input")`，只修改B窗口计数；`human_readback`直接读取A仍为外写后的true，`chart_pointer`也来自该命令。它不能证明人接续修改A，标记必须修正。受控native variant中A的真实命中可保留为单独证据，但不能被无条件写入最终public manifest。生产消费者应保留正常可操作事件循环和A图形动作；正式导出构建运行后通过实际窗口输入操作A，外部读A、写A、再输入A，逐步检查同一owner值/版本/几何和画面，不拷私有renderer或改生产源码插入测试行为。前台受限时先保留导出/外部写入通过与桌面接续not_run，不造与之无关的计数假绿；必要受控事件注入只能作为独立、如实命名的证据。至少在一个已有正常应用复用矢量组件与动作，不只新增孤立probe。
4. **同条件成本与一次最终包。** 沿用16/128/480及30次样本与场景，保存本阶段优化前真实基线；改变布局/尺寸/采样质量要对齐，不比较不同工作。输出实际draw/上传量、CPU准备/encoder/stage耗时分位数、GPU时间（可用时）、资源容量/在途/清理。目标是减少重复顶点展开/上传和小draw，且观察到相应CPU提交改善；只有计数改善而时间不变要定位瓶颈、说明取舍，不宣称端到端提速。普通无矢量文字/表单做必要同条件回归，1x/无额外MSAA附件保持。A局部图形外写与B真实输入交错，证实公平性与停止后的idle/资源收敛。最后完成相关runtime/native测试与build、正式含空格导出，保留最终产物/源码/原始日志，源码变化后不套用旧二进制结果。

## 分工和停靠边界

Terra负责提交表示、FFI/Metal资源寿命和性能方案；接口确定后让Luna/high承担完整的正常应用接入、真实同对象导出验收、性能样本/解析及README工作包。可复用旧子代理，原生消息直接回Terra；源码/target/前台由Terra统一协调。阶段范围内所需exporter、manifest、消费者脚本可最小改动，无须逐文件升级；不要在指导与子代理之间反复转发等待或构建预约。

完成前对照实际交付，不把export manifest里的固定true当测试。指导审原始采样、对应实现与产物，不重复整套测试。若缺陷三次有效修复未解决或涉及不明生命周期，带证据升级；不使用K3。锁屏只跳过桌面部分，独立代码/受控性能继续。自有临时窗口整轮复用、结束统一回收，保护用户实例。完整阶段结束或重大阻塞主动报告指导 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`；不按单个补丁停工，不stage/commit/push、切分支或建worktree。

## 执行完成记录（2026-09-14）

- **计数语义和提交表示。** `encoder_batches` 是每帧实际 `setVertexBytes + drawPrimitives` 的次数，不是跨样本累计；旧480场景的10240正是同一帧把缓存三角形重新展开成176-byte通用顶点、按最大3168B块反复提交的结果。实现保留既有scene和painter order，在每个vector node上缓存16-byte local Metal vertex buffer；fill/stroke、layout和clip只在每次draw上传小uniform。vector node前先flush已有通用批次，完成后恢复通用pipeline，因此文字、图片和形状不会跨越矢量节点重排。
- **容量、COW与失效边界。** 已接受node克隆时retain buffer；`present_clear`保留accepted node数组到command completion，旧buffer不会在GPU在途时释放。几何拓扑变化清除该node buffer，paint/layout/clip、resize和scale只复用它；候选失败仍由既有accepted scene回滚。最大单node为16KiB，现有1024 node上限使额外驻留最多16MiB。`/private/tmp/cjgui-vector-submission-native-final/result` 证明5个node的容量2→6→12每步只有1次上传、另4次复用（864/1440/3120B，resident 10032/10608/12288B）；1x→2x→1x两帧均为5 draw、0 upload、5 reuse、12,288B resident。line/polyline/concave polygon/overlap/ellipse的RGBA、几何命中、clip和4x MSAA保持通过，vector为4x附件，普通无vector路径保持1x/0额外附件。
- **同条件测量。** 当前源码30次样本在`/private/tmp/cjgui-vector-submission-scale-final/`，renderer SHA-256为`cc26e1b4bd58c1f16003032b3843cebde221062f89d7e280787c73c4fdbbfc30`。16/128/480均为generic nodes/batches/vertex bytes=0；首帧上传16/128/480个buffer，随后30帧上传0、复用16/128/480。480的上传为2,949,120B、常驻同量、encoder CPU=250us，`stage_submit` p50/p95=1.611/2.029ms；16为8.149/8.268ms、128为6.255/6.380ms。它包含提交和可能等待，不能解释为GPU完成或物理呈现；相较阶段开头记录的480 18.54/19.765ms，当前同场景的提交阶段明显降低，但小规模受调度噪声影响不作普遍加速承诺。最初基线的`result`在一次误用输出环境变量的RED尝试中被覆盖，故其原始逐样本文件不再作为保留产物；本页开头的当时重算数值才是可追溯的基线记录，不能虚称该旧路径仍保存原始日志。
- **消费者与真实输入边界。** 生产`--verify-vector`已去除对B窗口`chart.input`的伪人操作，固定输出`human_action=false`/`human_readback=false`；受控native生成变体仍独立验证命中，`/private/tmp/cjgui-vector-submission-consumers-3/manifest`。已有`Adaptive Layout Public Consumer`新增可点击`adaptive-vector-beacon`，调用既有`TOGGLE_RESOURCE`并由同一个domain `isMarked`驱动图片与vector；它的normal bundle外部0→1→2读回通过，证据为`/private/tmp/cjgui-adaptive-vector-normal-1/manifest`。
- **导出与桌面自动化。** 最终含空格导出根为`/private/tmp/cjgui-framework-preview-consumption.tp8mzk`，vector bundle/public source SHA分别见其`vector-preview.manifest`；public验证通过外部颜色/几何写入、窗口投影与idle收敛，但manifest明确为`human_action_after_external=not_run`和`interactive_a_same_owner_input=not_run`。另从导出bundle启动`--run-vector`，以 CUA AX click 操作A：初次点击读到v1/coral/center130,85，公开`SET_MARKED=false`读到v2/blue/center80,55，再次点击读到v3/coral/center130,85；两个临时窗口正常关闭且descriptor已清理，记录于`/private/tmp/cjgui-vector-interactive-desktop-final/manifest`。这是桌面自动化输入，不声称物理人工输入。
- **完成检查。** `verify_composable_vector_graphics_native.sh`、`verify_composable_vector_render_path_contract.sh`、`verify_composable_vector_scale.sh`、消费者contract/生成变体、Adaptive normal bundle和最终Preview均通过；仅保留上述物理输入/IME/VoiceOver、GPU completed、安装/公证/发布边界。
