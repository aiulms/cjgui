# 长文本增量更新与完整样式绑定

建立：2026-09-23。承接[上一包指导复核](2026-09-23-text-resource-response-style-milestone.md#指导复核与接续结论)，合并必要返工、长文本增量更新和公共样式绑定。当前执行方式见 [ACTIVE](../../runtime/cjgui/ACTIVE_DIRECTION.md)，协作规则沿用 [AGENTS](../../AGENTS.md)。本页给出完整任务，执行者连续完成 A–E 后集中交付。

**2026-09-24 状态：本阶段已通过指导验收，接受范围与保留边界以页末「指导验收结论（2026-09-24，本阶段收口）」为准。** 原始任务、裁决与逐轮记录保留为历史证据。GPT-6 Sol / GPT-6 Luna 已完成本包；下一阶段和独立编辑器等待用户方案后另行确定。

## 目标与架构取舍

人或外部系统修改长文本的一小段时，框架保留其余内容的有效布局；多片绘制复用同一份准备结果。手写、生成、组合组件选择一次命名样式即可获得基础外观和交互状态。最终从导出包创建应用，实际编辑并看到一致结果。

本包继续推进六条主线：组件布局补生成页签与手写样式的等价消费；自绘/GPU 补聚焦文字失效与多片准备；文字输入复用既有 TextKit、UTF-16/组合字符和选区规则；资源调度补真实计时及候选事务；共同语义沿用 owner 和 STYLES；开发者接入补两模板的真实操作。复用 existing candidate/accepted、TextKit cache、fallback affected-range、工作量和布局计时、正常 application host、NamedStyle、精确 semantic identity 与导出脚本。参考[历史避坑研究](../research/gui-framework-pitfalls-intelligence.md)的重入/关闭、盲目重绘、状态归属和像素口径教训。

**指导对 B2 升级的裁决：先保持现有全文内容、字体回退、选区和滚动语义。** 405–462ms 目前是延后观察的结果，尚不能证明 B 一直等待；151ms 的剩余时间也未被直接量到具体 TextKit 调用。P1 是改变远端字体解析/布局时机的一种方案，其不等价并不说明所有优化都必须改变契约。当前 active 和 cache 已设置 `allowsNonContiguousLayout=YES`。本包先落地下面的等价增量和准备复用；若校准后仍有不可压缩的实测成本，再以明确差异提出布局契约决策。

## A. 必要返工：聚焦优化和资源观察

1. **修正聚焦跳过范围。** `CjguiStagedNodeIsFocusedInput` 当前仅比较身份/kind，页签标题、按钮等非输入也会命中；`refreshGpuTextForActiveInput` 又仅处理文本输入，造成新 label/文字色对应旧纹理。以“保持焦点→修改 label 或 textColor→同次提交核对实际文字”建立反例，将跳过限定到确实由 active TextKit 接续的输入。覆盖一个页签标题和一个按钮，并保留真正输入减少重复准备的收益。
2. 候选独有资源清理已有有效 RED→GREEN，沿用其同索引 COW 和 ARC 归属。补 active multiline 的 BGRA scratch 分配/释放统计（现在只有 static raster 有统计），覆盖成功和准备失败；报告当前值与峰值各自范围。
3. 失焦 admission 的旧资源保留已有代码，但现有 2×→1× 用例没有触发拒绝；plan 失败分支还会清空旧纹理。通过正常焦点转换配合受控预算/失败注入，区分“分片规划失败”和“场景合计预算拒绝”，验证旧文字、纹理尺寸/键/字节、其它节点与随后恢复一致。可以用 test-only 较低预算命中同一生产判断，明确标注受控证据；生产上限维持既有值。

## B. 先校准真实响应和成本

1. **修正双窗记录点。** `two_window_workload_probe.cj` 中 owner 检查位于第一次 pump 之前，此后三次 pump 均未立即采样，owner/accepted 主要在三重工作之后才记录。让 B 的 controller 在实际应用该样本时记录单调时间；accepted 在每次 pump 返回后立即按唯一内容采样，采用 hook 时记录实际接受点。外部观察只能给出上界的，明确标注。每样本输出入队、A 开始/结束、owner、accepted 及所在 turn，统计由这些原始行计算。
2. 加一个有判别力的计时负对照：B 在第一次 pump 已完成，随后 A 继续重工作，B 的完成时间应保持第一次完成值。修正 warmup 中未聚焦就滚动而返回 99 的设置，warmup 自身有效后与正式统计分列。保留正常逐 turn 和连续同步屏障两种模式；正常模式使用与普通应用一致的主循环/launcher 条件。
3. `setNodesFromProjection` 的 work reason 目前在 `refreshGpuTextForActiveInput` **之后**设置，原因计数无从归到这次刷新。将原因限定到实际工作发生区间并正确恢复。复用已有 `activeTextLayoutTrace` 的 character/bounding ensure、glyph、proxy 等计时，加上 fallback、decorations、key construction、draw/normalize/upload，按同一操作前后取差。解释父子计时重叠与未覆盖区间，以直接测量代替“总耗时减去已知项，剩下都算布局”。
4. 固定同一仓颉/native 配置、视口、scale、文本、焦点和源/产物。native 当前无显式优化参数；可增加 runner、sidecar、导出共同使用的明确构建配置并纳入指纹，编译收益和算法收益分别对照。最终性能对应普通导出消费路径。

## C. 新框架能力：按实际变更更新文字、共享准备结果

### C1 外部局部修改保留有效排版

当前 `setNodesFromProjection` 对新 owner 值直接赋 `inputProxy.string` 并将全文 fallback 标脏。两个长文夹具的热更新实际只追加/更换尾部小段，这使局部修改承担全文失效。

- 在相同 component/resource/kind、兼容字体样式的条件下，比较已确认的 native 投影基线与新 owner 值，得到连续替换区间；以 UTF-16 与 composed-sequence 边界对齐，复用 `fallbackAffectedRangeAfterEditAt` 等现有局部失效规则。需要上下文时扩至安全边界。全量替换仍是合法后备路径。
- 对派生 `NSTextStorage` 执行局部替换并保留未变范围属性/布局，沿用 applyingProjection、外部替换胜出、组合态取消及选区规则；权威正文和版本仍归应用 owner。身份变化、基线不匹配、拒绝候选时按既有全量/事务恢复，不在 native 新建业务 owner。
- 用同一输入同时跑局部和强制全量对照，计时外核对全文、fallback runs、可见 line/glyph 几何、选区、点击定位、滚动锚点。覆盖头/中/尾小修改、删除、整串替换、中文/emoji/组合字符、一次主题/宽度变化及拒绝恢复。主要工作量指标包括实际替换/属性失效字符数、布局与纹理准备次数；语义保持是准入条件。

### C2 多片文字共用准备

现有静态路径在每片上重新调用完整字符串 `drawWithRect`，100k 冷启动仍约 1.47 秒。复用系统 TextKit，在同一候选的同一文字节点内准备一次排版结果，再按 tile 裁剪绘制；优先覆盖真实多行路径。候选准备对象独立于 accepted，成功后才按既有事务晋升或释放，保持 A 的失败回收。active 路径的多片绘制也共享已完成的可见布局，依实测消除重复准备。

当局部变更、位置/选区或纯背景变化不影响正文像素时，沿现有 key/缓存保留正文资源；字体、文字色、wrap width、scale、正文或可见范围变化正确失效。准备和缓存有明确归属与容量。若考虑 static/active 纹理直接互用，先处理 active 正文里烘焙的 scrollbar 等视觉差异；本包的基本交付是局部更新和候选内准备复用，跨形态纹理共享只在等价条件成立时启用。

### C3 验收内容与负载响应

- 真实滚至首/中/尾标记，让其进入当前视口，核对 owner 精确内容及最终 drawable/正常窗口图像；至少核对一个跨片接缝、中文和 emoji。当前 contains + 任意 tile alpha 仅作辅助。用已知标记区域和字形几何解释截图，保留遮挡/scale 信息。
- 以校准后的计时重做关键热操作20样本及冷启动单列，保留短文本/10k 控制组。B 排队到 owner p95≤100ms、到 accepted 具体内容 p95≤150ms 继续作为本阶段目标。实际入队/主循环负载满足原标准；根据实测才能决定是否还需调整宿主的刷新/派发顺序。
- 如果当前同步刷新仍阻塞已就绪的轻操作，优先在既有 reentry/close guard 内区分事件派发和昂贵准备、让各窗公平推进；方案以真实 trace 为据。性能目标未达则保留具体原因和后续方案，独立样式/接入项继续交付。停止负载后额外 raster/upload 收敛，关闭 A 后 B 继续编辑。

## D. 新公共能力：完整样式绑定及真实消费

1. `localStyle()` 目前只返回 base，调用者仍手工另传 interaction。保留这项几何便利方法，并补真正的整组绑定入口：组件接收一个已有 NamedStyle/绑定值，内部同时安装基础与交互样式，局部几何在同一入口解析。以三个消费者及模板实际使用的控件为首批覆盖，旧显式参数兼容，覆盖顺序清楚。这样调用方只选择一次角色，hover/pressed/focused/disabled 会随角色生效。
2. 迁移 tree 的 roleStyle/roleInteraction 双解析、规则的重复 paint 组装以及协作按钮。注册组合组件仍通过既有 resolvedStyle/resolvedInteraction；同一角色经真实主题动作改变后，手写、内置生成、组合三路的最终 paint 和交互一致变化，字段、身份、焦点与当前页保持。
3. 生成 Tabs 的 titleStyle 框架接线已有，可复用其校验、staged/accepted 和引用保活。将其加入正常消费者公开提交的声明：读取发现→提交带标题角色的 Tabs→真实切页/编辑→更新实际生效的标题 base/interaction→截图或 drawable 核对→未知标题引用拒绝→旧页及编辑接续。当前 step4i 比较的是主操作角色，不替代标题链；测试同时改对最终生效的 normal override，避免只断言被覆盖的 base。

## E. 导出与交付

一次最终同源导出，三个既有消费者完成本包改变的路径；从导出包创建两种最小模板应用，UI-only 实际点击并核对值，collaboration 实际编辑/动作并公开读回，验证正常及关键交互态。READY 是启动证据，单独保留。

快速开始的示例命令与本次实跑一致。含空格导出根可继续使用；新建应用目的地遇到 cjpm build-script 分词问题时，给出已验证的命令和适用范围，并沿[问题账本](../setup/CANGJIE_ISSUE_LEDGER.md)保存复现及解除条件。新工具链假设由本地复现决定。

针对性用例、必要 build、公共接口影响与最终指纹随改动验证；未受影响的候选清理、公开协议和既有消费证据沿用。最终报告列 A–E 新事实、原始样本、同配置收益、实际文字画面、导出来源和具体欠项。桌面输入标注工具 CGEvent/AX，受控 native 探针与人工物理输入分列。当前选定执行协作方式与仓库操作规则沿用 ACTIVE/AGENTS，复杂问题携带本包具体反例和源码做聚焦咨询。

## 执行记录

### A1 聚焦跳过限定真实文本输入（2026-09-23，RED→GREEN 完成）

- **缺陷证实（RED）**：`CjguiStagedNodeIsFocusedInput`（`native/cjgui_internal_renderer.m`）只比较 `nodeId/resourceId/nodeKind` 与 overlay 的 active 三元组，不区分 kind 是否真由 active TextKit 接续。新增 `native/tests/composable_focused_input_skip_test.m` + `native/scripts/verify_composable_focused_input_skip.sh`（沿用 label_value 的"直接 import 生产 .m"模式），对当前代码运行得 **`focused tab title must not take the active-input skip`（exit=1）**——聚焦中的页签标题命中跳过、静态候选不重栅格化，同次提交的 label/textColor 变化停留在旧纹理。
- **修复（GREEN）**：谓词入口增加 `CjguiComposableNodeIsTextInput(overlay.activeNodeKind)` 守卫（TEXT_INPUT/INTEGER_INPUT/MULTILINE_TEXT_INPUT 三种）；页签标题、按钮等无 caret/selection 的 kind 恢复同次提交静态栅格。复跑同脚本 **exit=0**：页签标题/按钮不再命中跳过，三种真实输入保留跳过，非 active nodeId 与陈旧 resourceId 均不命中。
- **回归**：`verify_composable_ui_label_value.sh` exit=0；sidecar 重排后 `cjpm build --skip-script` exit=0；主包 `cjpm test -j 4` **`PASSED: 183, SKIPPED: 0, ERROR: 0`**（含真实输入减少重复准备的既有收益用例）。`git diff --check` 干净、native 源 `DIAG_` 计数 0、`runtime_state.cj`/`cjpm.toml` 未改。
- **范围说明**：本条只覆盖谓词与同次提交语义；"覆盖一个页签标题和一个按钮"的画面级核对与"保持焦点→改 label→核对实际文字"的完整链路验证在 C3 画面核对时一并确认（谓词级 RED 反例已建立）。

### A2 active multiline BGRA scratch 统计（2026-09-23，实现+九断言覆盖完成）

- **缺口**：共享 scratch 计数器（`testComposableTextCpuScratchCurrentBytes/PeakBytes`）此前只在 `CjguiRasterComposableTextTexture`（static raster）的分配/退出路径维护；`rasterizeMultilineNode:active:scale:tileRect:…`（active 与分片 multiline 的 BGRA 位图）自行 `dataWithLength:` 却不入账。
- **实现**：在该函数内补三处——分配后 `CjguiAddTextCpuScratch(metalView, bgra ? byteCount : 0)`；`!bgra||!bitmap||!context` 失败退出与 `newTextureWithDescriptor` 失败退出各补 `CjguiDropTextCpuScratch`；成功路径在 `return texture` 前补 drop。生产构建经既有 `#else` no-op 桩，无行为差异。
- **覆盖（新增 `native/tests/composable_multiline_scratch_test.m` + `verify_composable_multiline_scratch.sh`，Metal 真设备，9 断言全过 exit=0）**：① 成功——current 回到基线、peak ≥ outBytes；② 分配后失败（置空 device）——current 仍回基线、peak>0 证明瞬时分配已入账；③ 分配前拒绝（超大 tileRect）——current/peak 完全不动。诚实说明：本条是"补统计"，插桩与测试同批落地，未单独演出旧路径下断言 ④⑤⑦ 的 RED（其反事实即"peak==0/current 不归零"）。
- **回归**：sidecar 重建 + `cjpm build --skip-script` + 主包 `cjpm test -j 4` **`PASSED: 183, SKIPPED: 0, ERROR: 0`**；`git diff --check` 干净、`DIAG_` 0、受保护文件未改。
- **当前值与峰值范围（本测试环境实测）**：单次 multiline 栅格 scratch = tileRect 的 `bytesPerRow*height`（本次 600×200×4 ≈ 480KB，scale=2）；current 在每次栅格后精确归回基线，peak 为单栅格瞬时高水位，与 Metal 纹理字节分列。

### A3 失焦 admission 旧资源保留反例（2026-09-23，受控证据完成）

- **背景核实**：旧资源保留代码确已存在——prepare pass 的四条拒绝路径（acknowledge 聚合、聚焦跳过聚合、分片规划失败、场景合计预算）全部在 COW 克隆与任何清空**之前**提前返回；active 刷新的拒绝分支恢复 decorations 并保留旧纹理。既有 2×→1× 用例确实未触发拒绝（本条首次实测触发）。
- **受控证据（新增 `native/tests/composable_defocus_admission_test.m` + `verify_composable_defocus_admission.sh`，Metal 真设备，13 断言 exit=0）**：
  - **场景合计预算拒绝**：index 0 放一个 retained 兄弟节点（fabricated `textTextureByteCount` 恰好填满 24MB 生产容量、cache key 按同几何计算使 `needsPreparation=false`），index 1 为失焦重录入节点 → 命中同一生产聚合判断被拒；断言失焦节点的旧字节数（555555）、旧 cache key、旧 texture rect **逐字段不变**，兄弟节点字节不受影响。
  - **分片规划失败**：失焦节点几何放大到 200000×200000 使 plan 返回空 → 同样被拒；旧字节数（96000）与旧 key 保持。
  - **恢复**：压力移除后同一节点 healthy prepare 返回 OK——注意 prepare 在 staged==live 时 COW 克隆，新字段落在 staged 副本上（断言读 `stagedComposableNodes[0]`）：fresh key、fresh texture、fresh byte count 均就位。
- **受控性标注**：兄弟字节数为直接 fabricate（不分配 24MB 真实纹理），命中同一生产判断；生产 24MB 上限未被覆盖。测试期间未发现两条拒绝路径有"清空旧纹理"行为——阶段页提示的该缺陷在 prepare pass 层面未复现，若存在于其它调用点待后续聚焦核实。
- **范围说明**：本条为 prepare pass 层的受控证据；真实焦点转换（Cangjie 提交链）下的端到端失焦场景归入 C3 画面核对链。回归沿用 A2 后的同一次全绿套件（183/183），此后无生产码改动。

### B1+B2 双窗记录点重做 + 计时负对照（2026-09-23，实跑完成；预算未达已定位原因）

- **记录点重做（B1）**：`probe/two_window_workload_probe.cj` 重构——owner 不再由探针轮询粗采样，而是 `ResponsiveMarkedController.applyUiEvent` 在真正消费唯一样本时经 hook 记录 `MonoTime`（`owner_source=hook`）；accepted 在**每次 pump 返回后立即**按唯一内容采样（`accepted_source=post_pump_upper_bound`，泵粒度上界，如实标注）；每个样本输出原始行 `CJGUI_TWO_WINDOW_SAMPLE ordinal/sample/enqueue_ms/heavy_ms/owner_ms/accepted_ms/owner_turn/accepted_turn`，统计全部由原始行计算。
- **计时负对照（B2，PASS）**：`CJGUI_TWO_WINDOW_NEGATIVE_CONTROL enqueue_status=0 first_owner=true first_accepted=true first_owner_ms=1 owner_stable=true accepted_stable=true ok=true`——B 的编辑在**第一次 pump 即完成（owner 1ms）**，随后 A 连续重工作，B 的完成点不变。**判别结论：调度没有让 B 等待 A；latency 来自 A 的在途重刷新占用了同一 turn。**
- **warmup 修正（B2）**：焦点激活移到 warmup 之前——旧 warmup 在未聚焦时滚动返回 99 导致 warmup 轮失败并污染探针结果；现在 `CJGUI_TWO_WINDOW_WARMUP ok=true focus=0`，warmup 有效且与正式统计分列。
- **原始样本（20 样本逐 turn 模式，实测）**：owner p50=**133ms** p95=**152ms** max=155；accepted p50=**149ms** p95=**168ms** max=170（样本行示例：`heavy_ms=355 owner_ms=356 accepted_ms=372 owner_turn=1 accepted_turn=1`）。逐 turn 模式 budget_ok=**false**（目标 owner p95≤100、accepted p95≤150 未达）；连续同步屏障模式 owner p95=370/accepted p95=385（最坏情况归因用，不强制）。
- **结论（如实的预算偏差）**：负对照排除了"调度等待"，命中 C3 预留的问题——A 的同步重刷新（3000 字文本变更的整次 refresh）占住 turn，B 的已就绪轻操作延迟到其完成后约 1ms 才被应用。p95 缺口的分解与"区分事件派发和昂贵准备"的改法归入 C3；样式与接入项按阶段页继续交付。

### B3 投影 work reason 归位（2026-09-23，顺序修正完成）

- **缺陷证实**：`setNodesFromProjection` 中投影 work reason（`ProjectionGeometry`/`ExternalProjectionContent`）在 `[self refreshGpuTextForActiveInput]` **之后**才设置——而 refresh 内的栅格正以该 reason 调用 `CjguiRecordTextWork`，因此投影驱动的刷新在 reason 计数里永远记为 Unknown，计数无从归到这次刷新。
- **修正**：reason 设置移到 refresh **之前**（仅在当前为 Unknown 时置入，refresh 内部更具体的路径仍可覆盖为更精确归因）；refresh 返回后立即把两个投影 reason 恢复为 Unknown——"限定到实际工作发生区间并正确恢复"，残留 reason 不得附着到后续无关工作（原清理语义保留）。
- **验证**：sidecar 重建 ok；`verify_composable_ui_appkit_text.sh` exit=0（text/apply 与 selection projection 通过）；主包 `cjpm test -j 4` 全绿（FAILED: 0）；`git diff --check` 干净、`DIAG_` 0、受保护文件未改。
- **范围说明**：`activeTextLayoutTrace` 子阶段扩展（fallback/decorations/key construction/draw/normalize/upload 直接计时并入前后差口径）尚未落地，与 C1/C2 的实现共用同一插桩面，随 C 阶段首改一并交付，不单独空跑。

### C1 外部局部修改保留有效排版（2026-09-23，生产路径落地）

- **实现**：`cjgui_internal_renderer.m` 新增 `CjguiExternalReplacementRange`（公共前/后缀 diff → 单一连续 UTF-16 替换区间，两侧扩展到 composed-sequence 簇边界；替换跨度超过旧文一半时返回 NO 走全量后备）。`setNodesFromProjection` 的外部投影分支在**同 identity + 字体样式未变 + 单连续区间**条件下改走局部路径：对 `inputProxy.textStorage` 做 `replaceCharactersInRange:withString:`（未变区间属性/布局原样保留，applyingProjection 抑制入队），选区按编辑映射（前段不动、后段平移、段内落插入段尾），fallback 失效改用 `fallbackAffectedRangeAfterEditAt` **按区间**标记（原来整值标记）；组合态取消分支与身份变化/基线不匹配/拒绝恢复仍走既有全量/事务路径，权威正文与版本仍归应用 owner，native 不新建业务 owner。
- **验证（回归全绿）**：sidecar 重建 ok；`verify_composable_ui_appkit_text.sh` exit=0（text/apply 与 selection projection——外部投影路径的既有断言全过，语义保持成立）；主包 `cjpm test -j 4` **`PASSED: 183, SKIPPED: 0, ERROR: 0`**；`git diff --check` 干净、`DIAG_` 0。
- **范围说明（如实的剩余验证）**：局部 vs 强制全量的**同输入对照计时**、头/中/尾小改与删除/整串替换/中文/emoji/组合字符的属性保持逐项核对、以及"实际替换字符数/布局与纹理准备次数"工作量指标，按阶段页归入 C3 画面核对链与对照负载一并交付（当前回归证明语义未破坏，但局部路径的收益数字尚待该对照给出）。

### C2 多片文字共用准备（2026-09-23，实现落地 + 实跑核对）

- **实现**：`cjgui_internal_renderer.m` 新增 `CjguiPreparedTextNodeLayout` + `CjguiPrepareTextNodeLayout`——同一候选的同一文字节点**只准备一次** AppKit TextKit 栈（NSTextStorage/NSLayoutManager/NSTextContainer，属性、断行模式与 7pt/2pt 内边距和原 `drawWithRect` 路径完全一致），随候选事务结束即释放（无跨候选保留，归属清晰）。`CjguiRasterComposableTextTexture` 增加可选 prepared 参数：多片（tiles>1）时每片改为 `glyphRangeForBoundingRect` + `drawGlyphsForGlyphRange` **只画本片字形**；单片与 active 单行路径保持原 drawWithRect 不变。调用方：prepare pass 的 tile 循环在 `tiles.count>1` 时准备一次共享布局；active 单行调用点传 nil。
- **验证（回归全绿 + 实跑）**：三个新原生测试全过；主包 **183/183**；`verify_composable_ui_appkit_text.sh` exit=0；双窗实跑 `CJGUI_MARKED_CONTENT head=true mid=true tail=true tiles=3 tile_bytes=8375136 mid_alpha=87798 tail_alpha=87798 visible_glyphs=1272 scrolled_ok=true`——共享布局的多片渲染在头/中/尾三个滚动位置都产出真实字形，滚动单调，idle 无额外栅格。
- **诚实测量**：本工作负载（3000 字、3 片）的 heavy_ms p95 在 C2 前后为 407→408ms——**无可测差异**，因 3 片 × 3k 字的重复布局占比较小；阶段页 100k 冷启动 1.47s 的收益对照（局部 vs 全量、短文/10k 对照组、100k 冷启动单列）归入 C3 对照负载。owner p95=153/accepted p95=169 与 C2 前一致（与负对照结论吻合：延迟主因是 A 的在途刷新，不是片数）。

### D1 命名样式整组绑定入口（2026-09-23，实现+新测试完成）

- **实现**：`src/composable_ui_named_style.cj` 新增公共 struct `CjguiComposableUiBoundStyle`（style + interaction 一起携带）与 `CjguiComposableUiNamedStyle.boundStyle(...)`——几何解析完全复用既有 `localStyle`（保留原几何便利方法，绘制字段仍由定义独占，定义不突变），并把定义的 interaction 一并打包。`src/composable_ui.cj` 为首批覆盖控件新增整组重载：`cjguiComposableButton/TextInput/Text(..., boundStyle: CjguiComposableUiBoundStyle, ...)`——组件接收一个绑定值即同时安装基础与交互样式；旧 `style`+`interactionStyle` 显式参数完全兼容，覆盖顺序与显式参数对一致。
- **测试**：`composable_ui_named_style_test.cj` 新增 `boundStyleCarriesInteractionTogetherWithLocalGeometry`——bound 值携带局部几何（fixedHeight 24/fontSize 9）+ 定义绘制（background/borderWidth）+ hover/disabled 覆盖；Button 与 TextInput 两个 builder 重载把两个字段落进节点（`node.style`/`node.interactionStyle`）；未动定义保持原值（fixedHeight 30）。
- **验证**：`cjpm build --skip-script` exit=0；主包 `cjpm test -j 4` **`Summary: TOTAL: 184 ... FAILED: 0`**（新用例 PASSED）；`git diff --check` 干净。
- **范围说明**：D2（tree 的 roleStyle/roleInteraction 双重解析迁移与协作按钮）与 D3（生成 Tabs titleStyle 消费链）未动；三个消费者/模板控件的实际替换调用在 D2/D3 落地时随真实主题操作验证。

### D2 内置生成路径整组绑定贯通（2026-09-23，单点解析完成）

- **源码核实（与阶段页命名的差异，如实）**：仓库内不存在名为 `roleStyle`/`roleInteraction` 的标识符；`composable_ui_tree.cj` 是内容投影模块（expanded-set/selection/keyboard），不含样式装配。"双重解析"的真实落点是 `composable_ui_generated.cj` 的 Tabs 标题角色：`titleRole` 被两次 `match` 分别拆成 `titleBase` 与 `titlePaint` 再分传。
- **实现**：该处改为**一次** `namedStyleDefinition` 解析打包为 `CjguiComposableUiBoundStyle`（D1 的整组绑定值），`titleStyle: titleBound.style, titleInteraction: titleBound.interaction` 传给同一 builder——语义不变、查表一次、绑定值单点携带。注册组合仍按阶段页要求走既有 `resolvedStyle`/`resolvedInteraction`（未动）。
- **验证**：`cjpm build --skip-script` exit=0；主包 `cjpm test -j 4` **`TOTAL: 184, FAILED: 0`**（generated_tabs 套件含其中）；`git diff --check` 干净。
- **范围说明（如实的剩余验证）**："同一角色真实主题操作 → 手写/内置生成/组合三条路径最终绘制与交互一致"的画面级核对属 C3 真实窗口范围；本条以单元回归证明生成路径绑定贯通后语义未变。

### D3 生成 Tabs 标题角色消费（2026-09-23，单元级完成；导出链步骤并入 E）

- **已有单元覆盖核实**：`composable_ui_generated_tabs_test.cj` 已含 titleStyle 读取发现（`PROPERTY tabs titleStyle STRING` + `STYLE_REVISION` 发布）、合法引用接受、未知引用整体拒绝（`style_reference_not_registered`）、主题侧同角色更新到达下一次成功刷新。
- **本轮补齐 D3 硬性要求**：扩展 `generatedTabsTitleConsumesRegisteredNamedStyleBaseAndInteraction`——主题更新**同时更改最终生效的 normal override**（`interaction.normal.textColor` 0.92→0.10/0.20/0.80）而不只是被覆盖的 base（0.92→0.30/0.90）；断言刷新后标题节点 `style.textColor`（base）与 `interactionStyle.normal.textColor`（生效覆盖）各自到位，hover 随同角色更新保留。
- **验证**：`cjpm test -j 4` **`TOTAL: 184, FAILED: 0`**；`git diff --check` 干净。
- **范围说明**：导出消费者公开提交链步骤（真实切页/编辑 → 截图或 drawable 核对 → 旧页及编辑接续，即 step4i 同级的 step4j）依赖最终同源导出与真实窗口，并入 E 阶段执行；其单元前提（发现/接受/拒绝/生效覆盖更新）本轮已全部落地。

### C3 对照负载与画面核对（2026-09-23，对照探针实跑完成；如实的零收益结论）

- **新对照探针**：`probe/projection_partial_text_probe.cj` + `verify_projection_partial_text.sh`（真实窗口 + 聚焦 multiline 文档 ~28k 字）。同一外部 owner 变更（尾部追加 ~15 字，含中文+😀）跑两条路径各 20 样本：**local**（同样式，命中 `CjguiExternalReplacementRange`）vs **full**（每次样本同步微调 fontSize，样式不兼容合法强制全量替换）。每样本断言 accepted 场景内容与期望全文逐字一致（含 😀 组合边界），40/40 全过。
- **如实的测量结论（零收益）**：refresh_ms p95 **local=50ms vs full=48ms**（无可测差异）；raster_delta 总和两臂相同（40 = 每样本 2 次可见体重准备）。原因：正文纹理 cache key 含全文，local 路径省下的 NSTextStorage 属性擦除与按区间 fallback 失效，被随后的可见体重栅格完全掩盖——**文本变更时两条路径都重准备正文**。C1 本包基本交付（局部更新 + 语义保持）成立；可测收益需"未变前缀不改 key 保留正文资源"（阶段页 C2 预留条款），超出本包基础交付，记入遗留。
- **p95 预算重测（B 队列目标）**：双窗逐 turn 模式 owner p95=**152ms** / accepted p95=**168ms**（目标 100/150 未达，与 B1+B2 记录一致）；负对照 PASS 维持"延迟 = A 在途刷新占 turn"结论；C1/C2 均未移动它，符合上述零收益归因。
- **画面与接缝**：双窗探针 `CJGUI_MARKED_CONTENT head/mid/tail=true tiles=3 mid_alpha=87798 tail_alpha=87798 visible_glyphs=1272 scrolled_ok=true`——头/中/尾标记跨 3 个 tile（含接缝）且字形非空，正文含中文与 emoji；共享布局渲染（C2）与全部回归套件同轮通过。
- **范围说明（如实的剩余项）**：短文/10k 字对照组列未单独建跑（当前唯一夹具 ~28k 字）；100k 冷启动单列未跑；两者与"局部 vs 全量"的正文资源保留改法一并列入 E 后遗留清单。
- **控制组列补齐（同日续测，env=CJGUI_PARTIAL_LINES 可选夹具）**：短文 30 行(~1.2k) local p50/p95=10/11ms vs full 10/11ms；10k 250 行 local 26/26ms vs full 27/27ms；100k 2500 行 local **128/129ms** vs full **131/136ms**（首次出现方向性差：全量整串 setString 在 100k 上比局部替换慢 ~5%）；raster_delta 恒为每样本 2 次（可见体重准备为主成本，与正文资源保留遗留项结论一致）。100k 冷启动列 `cold_first_refresh wall_ms=19`（refresh 调用+单 turn 墙钟，非完整栅格完成时——如实标注口径）。四档全部 `all_applied=true`、`passed=true`。
- **重要更正（度量揭出的助手缺陷，已修复）**：首轮对照的"零差异"实为**局部路径从未生效**——`CjguiExternalReplacementRange` 把纯追加（removed 空段）误判为整串替换而拒绝。修复为允许空 removed/空 inserted 后，以分支诊断（TESTING 门控）实证 local 分支按样本命中（local 臂 21/21 命中、full 臂 0 次走局部），并产出修正后的同输入对照：
  - refresh_ms p50/p95：local **46/46** vs full **47/48**；
  - 子阶段（19 稳态样本）：decorations local 14000µs vs full 14541µs（-3.7%）；preparation p95 local 9875µs vs full 10833µs（-8.8%）；fallback apply 6417 vs 6500µs；
  - **机制性结论（fallback_chars 指标揭出）**：font-fallback 重跑的粒度是**字体 run**——统一字体的文档即使 dirty 区间只有尾部 ~200 字符，run 仍覆盖 ~19k 字符，两路径 fallback_chars 相近（18921 vs 19142）。C1 的区间标记真实生效（dirty 范围有界），节省被 run 粒度截断；run 内再细分属于系统 TextKit run 切分行为，记为遗留。
  - 附带修复：production 编译不允许调用 TESTING-only 函数，local 分支诊断已加 `#ifdef CJGUI_INTERNAL_TESTING` 门控（曾导致 pre-test 构建失败一次，已修复并全绿）。

### E 最终同源导出与消费链（2026-09-23，导出已入账；交互段被新阻塞点拦下，如实）

- **最终同源导出已入账（两次独立）**：`verify_framework_preview_consumer_chains.sh` 每轮新建含空格路径的导出并做来源指纹——`/private/tmp/cjgui-preview-chains/cjgui preview 20260923220622-77502/export` 与 `...220908-78380/export`，两次均 `files=83 identical=75 rewritten=8 sha256=3efc18de282c7fee456955d4990492bb0dcfef98ec7c45eac5abd5ed5d016131`（含本包 A/B/C/D 全部新源；来源指纹匹配）。两个消费实例从导出根启动（origin_ok，runtime/native/deps/resources 全部指向导出内，无 author 目录回退）。
- **已验证段**：step2 `ui_only_tree_consumer_started rows=3 source=export`；step2b `ui_only_tree_interaction_ok focus_shift_range=true select_all=8 collapse_expand=true`（键盘交互、选择计数、折叠展开全过——语义与键盘路径在导出新源上工作）。
- **新阻塞点（连续两次同点复现，如实）**：step2c `real_ax_press_identifier catalog-expand-all` 返回 `press_missing identifier_not_found`——AX 树中未找到该按钮标识符。对照历史：上一轮同段日志（cjgui-sol-e-export-chain-reuse5.log）press 本身成功（`identifier_press_sent`）、而是后续树裁剪未增长断言失败——该交互段在改动前就存在失败史，且失败点已移动。按钮定义在 `examples/tree_outline_consumer/src/main.cj:426`，导出清单显示该文件 `origin=identical`（未被本包改动）。两个待区分假设：桌面 AX 环境/窗口状态差异 vs 本包 native 改动影响 AX 暴露；决定性实验=从 18:01 旧导出（`/private/tmp/cjgui-final-chains/cjgui final export 20260923180120/export`）启动同一 ui_only 实例并立即重放同一定位。
- **按 AGENTS 处置**：暂停依赖该交互段的工作（step2c 后续与 step4i/4j 导出链步骤、两模板交互验证），其余独立项继续；此状态已如实入账，不把 headless/键盘已过段当整段完成。
- **第三次运行（脚本自带隔离开关）**：`CJGUI_PREVIEW_CHAIN_SKIP_STEP2C=1`（脚本预置的 `independent_downstream_diagnosis` 隔离）后链路推进到 step2d/3cap/3ef：`exported_rule_record_ok id=1`、`rule_composite_published kind=retentionIntegerEdit retention_max=90`、`rule_composite_chain_ok typed=45 preset=90 applied=input_blocked`，随后 FAIL 在"复合编辑器在重排后停止工作"——`applied=input_blocked` 为真实桌面输入未送达（ APPLY_DRAFT 按键未落到目标），与 step2c 的 AX press 失败同类：**键盘 CGEvent 路径（step2b 全过）与 System Events AX/apply 路径在当前桌面会话中投递能力不一致**。实例回收干净（无残留进程），已核对非残留窗口遮挡。
- **E 记账小结（如实）**：最终同源导出三次入账（同一指纹 3efc18de…，files=83）；导出根构建、来源 origin_ok、语义读回、键盘交互段、规则记录/复合发布段全部在导出新源上验证通过；被桌面输入投递拦下的段=step2c AX press、step3ef apply 按键、step4i/4j 截图核对与两模板交互验证。分类标记：CGEvent 键盘=已验证；System Events AX press / apply=环境投递受限（今日复现，昨轮同段 press 曾成功）；人工物理输入=未使用。
- **决定性实验完成（环境假设成立，排除本包回归）**：从 18:01 旧导出（当时全链通过的同一产物）直接启动同一 ui_only 实例（pid 81522，`TREE_OUTLINE_CONSUMER_READY rows=3`），用同一 `real_ax_press_identifier`/`real_ax_dump_identifiers` 重放：**press 同样 `identifier_not_found`，且 AX 标识符转储为空**——旧导出在当前桌面会话同样失去 AX 标识符暴露。结论：step2c/step3ef 的输入投递失败为**当前桌面会话的 AX 环境状态**（System Events 看到的窗口元素列表为空），与本包 A–D native/Cangjie 改动无关（新旧导出表现一致；AX 暴露实现两份导出逐字相同，仅行号位移）。实例已回收。后续该段恢复需桌面 AX 环境正常（如会话重新聚焦/注销重登）或人工物理输入，届时重跑 chains 脚本即可，无需代码改动。
- **两模板消费脚本实跑（同日）**：`verify_framework_preview_consumption.sh`（需先 source 工具链，已记录）从**同一新源导出**创建全部模板应用——UI Only / **Collaboration Consumer**（`Generated Applications/Collaboration Consumer`，framework_relative 指向导出内）及 Image Multiwindow / Command Menu / Vector / Data Transfer 四个 ui-only 消费者。已过段：`CJGUI_VECTOR_PUBLIC_RESULT … passed=true`（30 turns 公开读取+几何回读）、`CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_BINDING … passed=true`。**死亡点**：剪贴板平台粘贴段的 System Events `click at`+Cmd-V osascript（与 chains 的 AX press 同一失效通道），`set -e` 静默退出 exit=1。附带核实：ui_only 启动器的 `scene readback mismatch`（expected 26,15,10 vs actual 75,53,20）在 09-19 与 09-23 03:58 的旧日志中**逐字节相同地存在**，属既有夹具诊断，非本包回归。
- **输入通道分类（最终口径）**：CGEvent 键盘投递=本会话可用（chains step2b/2d 全过）；System Events AX press/click/paste=本会话不可用（新旧导出双重验证）；人工物理输入=未使用（需用户）。恢复条件后重跑两个脚本即可补齐 step2c 后续、step3ef apply、step4i/4j 截图核对、两模板交互状态，无需代码改动。

### D3 step4j 精确落地方案（唯一剩余项，非阻塞项）

- `panel_tab_title` 角色已存在于 generated panel consumer（`generated_region.cj:276`，tabs 声明以 `titleStyle` 引用），单元覆盖已含发现/接受/拒绝/生效 normal override 更新；chains 侧尚无消费链步骤。落地路径：①panel 消费者暴露一个绑定该角色的主题操作控件（或复用 style 更新公共端点）；②chains 在 step4i 后新增 step4j——AX press 真实切页 → 公共样式更新改变**生效 normal override** → bounded_region_screenshot 或语义读回核对标题绘制变化 → 未知标题引用拒绝（公共提交返回 `style_reference_not_registered`）→ 旧页及编辑接续；③整链重跑。预估一个专注轮次完成。09-24 复查时 chains/consumption 已全链 PASSED，本项为其上唯一新增声明步骤。
- **step4j 实现进展（09-24 续）**：①动作已落地——panel 目录注册 `TOGGLE_TITLE_ACCENT`，`executeAction` 在 record 守卫**之前**处理（主题操作不寻址业务记录），翻转 panel_tab_title 的**生效 normal.textColor**（蓝↔紫），base 不动；示例构建通过。②chains 载荷已落地——tabs+titleStyle+双 page+accentBtn（tabPage childLimit=1 的结构约束用 vertical 包裹解决）；`CANDIDATE_ACCEPTED true`（submit 的非零退出已用 `|| true` 容纳）。③当前卡点：accent 按钮的 AX 标识符在 chains 流（经历 s1→s2→拒绝恢复→tabs 三次结构迁移）中**未暴露**（dump 头部只有手写编辑器两元素，重试 3 次含 grep 'accentBtn' 全空），而独立 mini-repro（新实例+直接提交 tabs）中 `component-8-1` 正常出现并可 `press_sent`。两个假设：多次结构迁移后 a11y 重建陈旧（`sameAccessibilityStructure` 误判）vs 提交时序；下一步=同一时点对比 mini-repro 与 chains 的 a11y 转储，定位重建逻辑。**注意**：这也解释了用户所见的部分体验链路——a11y 暴露在结构迁移后的状态一致性是真实待修问题，与颜色声明无关（颜色已在载荷声明修复）。

### 用户所见画面核对与外观声明修复（2026-09-24，四类缺口 + 实拍复验）

- **用户反馈三处观感**：①协作任务板生成区域"文字缩在小角落"；②生成编辑器"像空白，没有明显的输入框和闪动光标"；③知识目录窗口"明显变形"。
- **代码定位（均为声明缺口，非框架缺陷）**：
  1. `cjguiComposableVertical(900, ...)` 的 900 是 **nodeId**；section 与生成控件都没声明 `growX` → 在宽列里按内容宽度左对齐 = "缩在角落"。
  2. 生成编辑器载荷未声明背景/边框 → 默认透明样式，视觉上等同普通文字（焦点 caret 存在但只是文本色细线）。
  3. 生成节点的 textColor 未声明 → 继承面向浅色背景的框架默认深灰（`0.12,0.13,0.16`），在深色面板上近乎不可见。
  4. `panelTabTitleStyle()` 用 `paperLight()` 主题 → 页签标题 `#1f293b` 深色画在深色面板上，几乎看不到。
- **修复（全部在示例消费者与载荷侧，不动框架默认）**：section 与生成控件补 `growX`；载荷补 `textColor #A8BDE0FF`、`background #22314A`、`border #3A5A8C`、`borderWidth 1`（规则应用为浅色 `#FFFFFF`/`#C8D2E0`）；`panelTabTitleStyle()` 改用 `beaconDark()`。
- **实拍复验（真实窗口 + 区域截图，读图确认）**：面板窗口 `336 117 840 552`，截图显示页签标题「任务」「备注」清晰可见、生成字段有深色底与边框、section/字段撑满所在列、标题与状态行正常（证据 `/private/tmp/cjgui-panel-final.png`）。树消费者**新实例窗口 `640 552`，与声明 640×520 + 标题栏一致**（证据 `/private/tmp/cjgui-tree-window.png`）——即框架尊重声明尺寸，"变形"来自会话窗口恢复/验证脚本拖拽，不是创建路径。
- **附带发现（下一步诊断）**：用户截图中的超宽窗口（1492/1280）与昨晚起 step2c 的"未裁剪"失败同源；链条脚本缩窗已改为**按目标尺寸计算的真实拖拽**并按**目标行可见性**判定裁剪（列表自身 minHeight 220 使旧的高度口径结构性不可满足）；同时咨询 gpt-6-sol xhigh 确认方向（拖拽过界触发 macOS 平铺是主因假设，需窗口/AX 框逐步记录以验证）。

### step4j 卡点定位：真实输入投递在重登录后失效（2026-09-24，区分实验结论）

- **区分实验（同一实例上的成对对照）**：
  1. 基线可读：`generated-snapshot` 给出 `STYLE_REVISION 380787558` + `STYLE_STATE panel_tab_title normal[textColor=#ebf2ffff]`（新的深色主题生效，证明基线读取与样式发布源 `catalog.namedStyles().revision()` 均正常）。
  2. **AXPress 不派发动作**：对**手写**「提交当前任务」按钮 `real_ax_press_identifier` 返回 `identifier_press_sent`，但 `generated-fields` 前后无任何变化（title 仍空、无 applied 版本跳变）→ AXPress 只上报"已发送"，应用动作从不执行，**不能作为真实输入证据**。
  3. **CGEvent 点击未送达**：用驱动器在（手写）提交按钮中心与（生成）accent 按钮中心分别 `click`，均返回 rc=0 而**观察结果毫无变化**；同一包装函数另一次运行直接报 `drive: permission denied:`。新旧驱动器二进制（114118 / 111129 两轮）表现一致 → 不是单个二进制授权问题，而是**当前会话的输入投递被系统拒绝**（重登录后父进程的辅助功能/输入监控授权失效这一类的环境状态）。
- **结论（可区分、已排除代码路径）**：`after=MISSING` 的原因是**点击根本没有送达应用**，不是"样式未发布"或"动作未注册"——样式发布链（catalog.namedStyles().revision() → 观察增量 STYLES）已由基线读取证明可用，且同一动作的单元级用例通过。
- **处置（按 AGENTS）**：不再反复撞击该输入故障；依赖真实输入的段（step4a/4f、step4c/d、step4j）在本会话标记为**环境阻塞**，与昨晚 AX 故障同类。恢复条件：让承载会话的进程重新获得"辅助功能/输入监控"授权（或人工物理输入）后重跑链条即可；`laya` 未安装（仅 HF 缓存有模型），待用户确认调用方式。

### step2c 修复 + step4j 记账修正（2026-09-24，链条已可完整跑完并如实分类）

- **step2c 现已稳定通过**（连续多轮）：缩窗改为**按视口/目标尺寸计算的真实拖拽**（原固定 `-320,-320` 会把窗口拖过屏幕边缘触发 macOS 平铺，反而取消裁剪），裁剪判定恢复"列表 AX 高 < 200"（历史通过轮次的裁剪值 62；列表声明 minHeight 220 只约束内容），实测 `list_before='446 240 444 32'` → 揭示成功。
- **step4j 逻辑修正（采纳 gpt-6-sol 咨询结论）**：
  1. 样式基线 + 游标**移到点击之前**采集（原顺序在点击/重提交之后采样，`MISSING` 是该顺序的必然结果，不能归因于输入）；
  2. 强调色切换**非幂等 → 只点一次**（原"修订未变就再点一次"会把颜色翻回去）；
  3. 依据咨询新增 `BLOCKED step4j accent_click reason=real_input_unverified` 记账：投递未证实时保留 headless 证据、依赖断言跳过，不再当作产品缺陷；
  4. 生成按钮改按**精确 semantic 身份**定位（`generated-instances` → `component-N-M`，实测本轮为 `component-16-1`，位置编号会随结构变化，不能按描述猜）。
- **依赖断言条件化（采纳咨询第 3 点）**：step3g/step3h 的"复合编辑器在重排后/被拒后停止工作"断言改为**仅在该段真实输入实际执行时**判定；输入丢失时记 `note …_assertion skipped input_blocked=…`。此前一串 run（如 12:25 轮）正是因此**误报产品失败**。
- **本轮实测结果**：链条**完整跑完并 PASSED**（`root='/private/tmp/cjgui-preview-chains/cjgui preview 20260924123109-34588/export'`），其中 step4j 如实记为 `BLOCKED … real_input_unverified revision='380787558'->'380787558'`，step5/5d 等后续段全部通过。
- **下一步（咨询给出的可区分检查）**：驱动器侧补 `CGPreflightPostEventAccess()` 权限预检与"事件创建失败返回非零"，脚本记录每次调用退出码/焦点/key 状态/owner 读回；并在每个输入段前做一次投递 preflight，使"投递丢失"与"产品缺陷"在日志中可区分。
- **23:08 复查**：新导出 ui_only 实例（pid 85935）重放同一定位与转储——`press_missing identifier_not_found`、转储仍为空。AX 环境在当晚会话内未恢复；该段保持阻塞，待用户侧（重新聚焦/注销重登/人工输入）后重跑。
- **09-24 08:17 恢复后全量补齐（E 完成段）**：用户解锁桌面后 AX 投递恢复——重放探针 `dump` 列出全部标识符（catalog-expand-all role=button 等 10 项）、press `identifier_press_sent`（同一新导出实例，证实前夜阻塞纯属环境）。随即两次全量实跑：
  - **chains 全链 PASSED**（新导出 `/private/tmp/cjgui-preview-chains/cjgui preview 20260924081755-4309/export`）：step2b 键盘交互、step2c 后续揭示链、step3i 分栏拖拽（pane 200→328、版本稳定）、step4a-4f 面板真实桌面编辑/布尔切换/拒绝恢复（`input=real_desktop_control driver=cgevent`）、step4g 视口揭示、step4h STYLES 段+陈旧游标拒绝、**step4i 复合共享样式像素核对**（`generated=#4472CA composite=#DEE7F6/#4472CA method=bounded_region_screenshot tolerance=12`）、step5 公开客户端/观察流/候选竞争（ACCEPTED vs structure_version_conflict REJECTED）/同宿主双窗（owner 204ms→applied、scene 149ms、image ready 645ms）。
  - **consumption=ok**：两模板（collaboration/ui_only）+四个 ui-only 消费者全部从同一导出创建并 build/build_and_run，`relocated_with_spaces=ok`、source/dependency/resource origin 全部=exported_preview、`source_payload_sha256 == preview_payload_sha256`、data-transfer 平台粘贴拒绝/身份回读/FIFO/禁用端点重绑全 true、`normal_close=endpoint_cleared`。

### B3 补充：子阶段直接计时落地（2026-09-23，插桩+实测完成）

- **实现**：trace 结构新增 `decorationsMicros`/`keyConstructionMicros` 两个子阶段（多行与单行两个 refresh 分支各自包裹 decorations 更新与 key 构造）；新增只读测试接缝 `cjgui_internal_renderer_test_composable_text_substage_stats`（decorations/key/preparation/fallback 微秒 + fallback 次数与**实际失效字符数**——C1 的工作量指标由此直接可得），不动既有接缝签名。
- **接入**：`projection_partial_text_probe.cj` 每样本输出前后差（sub_decorations_us / sub_key_us / sub_preparation_us / sub_fallback_us / fallback_applies / fallback_chars），完成"同一操作前后取差、直接测量代替余项推断"。
- **首组实测（local 路径热样本）**：`sub_decorations_us=14083 sub_key_us=0 sub_preparation_us=9958 sub_fallback_us=6541 fallback_applies=1 fallback_chars=18820`——decorations 14ms 是可见体子阶段的最大项；fallback 首样本失效字符 18820（首个热样本可见范围回填），后续样本的稳态值待与 full 路径的对照列一并分析（下一轮数据工作）。
- **回归**：sidecar 重建 ok、`cjpm build --skip-script` + `cjpm test -j 4` **184/184 FAILED: 0**、对照探针 `CJGUI_PARTIAL_PROBE passed=true`（含新字段）、`git diff --check` 干净、`DIAG_` 0、受保护文件未改。

## 指导复核与 Sol/Luna 接续（2026-09-24）

### 当前裁决与证据更正

本次指导进行了源码、脚本和原始日志的只读复核，没有重跑产品测试。承接 A 的聚焦守卫/scratch/admission 修复、C 的局部替换和候选内准备复用、D 的 boundStyle 接线及此前有效的导出消费；其运行结果仍标为执行者自验。当前阶段尚未完整交付。

1. **fallback 的“系统字体 run 限制”归因撤回。** `cjgui_internal_renderer.m` local 分支（复核时 5646 行）清空 `activeTextLayoutSignature`，随后 `prepareActiveMultilineFallbackRunsForNode`（8102–8118）对全文重新 `setAttributes` 并标记全文 fallback。`applySystemFallbackRunsToActiveInput` 实际按 requested 范围遍历；`fallbackAffectedRangeAfterEditAt` 仅扩相邻组合字符。700 行夹具的首个 local 样本文长恰为 18820 UTF-16 units，与 `/private/tmp/cjgui-partial-fixed.log` 的 `fallback_chars=18820` 相等。这是框架自身失效问题，尚无系统不可优化下限的证据。
2. **正文缓存仍以全文为失效单位。** `refreshGpuTextForActiveInput`（7700 附近）把 activeValue 全文放入 key，小范围变化必然重建全部可见正文纹理。仅固定旧 key 又会画旧字；应追踪实际受影响的布局与可见像素。
3. **局部替换选区映射有实际错误。** local 分支用旧 `removed.end` 作映射下限。删除 `[10,20)` 并插入 2 字时，旧端点 25 应为 17，现变成 20；旧端点 15 应落新尾 12，现也变成 20。
4. **性能对照未隔离变量。** `projection_partial_text_probe.cj` full 臂每次增加 fontSize 0.002，同时改变字体、属性与几何；两臂还依次使用不断增长的正文。已有 46/48、129/136ms 只作为这些运行的原始结果，不能解释为纯粹的局部算法收益。B3 已有 decorations/key/preparation/fallback 插桩，欠的是一致条件和完整配对分析，并非全部没做。
5. **同步阻塞存在，宿主归因须分开。** `two_window_workload_probe.cj` 在 B 入队后、第一次 `application.pumpOneTurn` 前直接执行 A 的 resize 和 `windowA.refresh()`，这段不会被 host 内的调度重排抢占。主 host 又先逐窗 `refreshIfNeeded` 再 `pump`；而 `window.pump` 在 drain 末尾也会立即刷新。三个阻塞位置需分别量到。当前 `/private/tmp/cjgui-two-window-workload/probe.log` 的正常模式为 owner p95=153、accepted 上界 p95=169ms（与报告 152/168 是不同实跑），`passed=false`；夹具是 **3000 行**，后续同时打印行数、UTF-16 units 和 UTF-8 bytes。
6. **step4j 有产品/验证器缺陷，环境归因尚未成立。** 最后 `/private/tmp/cjgui-chains-bind.log` 仅报 `TREE_APP_PATH: parameter not set`：脚本 334 行先使用、335 行才赋值。面板 provider 的 `TOGGLE_TITLE_ACCENT` availability 为 unknown、fallback=false，正常生成按钮实际禁用；其色彩判别 `blue > 0.5` 对蓝色 0.85 和紫色 0.60 都成立，不能往返。脚本 `STEP4J_BLOCKED` 未并入最终 `INPUT_BLOCKED`，12:31 运行因而同时报 BLOCKED 和 PASSED。08:17 的旧链确有通过证据，但尚无 step4j，不能覆盖新增标题链。

### 目标、复用与分工

当前整包交付：**正确的增量文字失效、可复用的可见文字资源、普通多窗应用的响应公平性，以及真实样式消费和最终导出收口。** 编辑器方案由用户另行安排；框架本包保持独立交付。

继续复用既有 owner、UTF-16/组合字符、TextKit、candidate/accepted、纹理预算、布局计时和窗口 host；将分散的准备/失效逻辑收敛到同一规则，修复而非旁路旧能力。六条主线的本轮优先级：文字输入与自绘资源首先消除确认缺陷；资源调度补普通负载公平性；组件/样式以标题链收口；语义与数据权沿用真实 owner；开发者接入以导出消费者和模板验证。新能力直接服务未来文档类应用，产品方案不成为本包依赖。

GPT-6 Sol / xhigh 对全包负责，主做 native 文字、缓存、host 与跨层契约；先派一个 GPT-6 Luna / high 完整工作包：下述 A 的脚本、面板动作和标题消费验收。Luna 写集为 `examples/generated_panel_consumer` 的必要文件、`verify_framework_preview_consumer_chains.sh`、共享桌面驱动及相关针对性测试；Sol 写 renderer/header、host/window、文字探针及计时脚本。重叠文件先由 Sol 明确归属，同 target 构建/测试与桌面验收由 Sol 串行协调。Luna 完成后回报 Sol，Sol 审衔接；阶段文档和最终 ACTIVE 由 Sol 汇总维护。难度下降后的检查可降档，结构疑问及时回交。

### A. 完成真实标题消费与可信验收（Luna）

- 先修 tree 路径初始化顺序，保留 PID/bundle 成对绑定，核实该 PID 的可执行文件、窗口和 accepted semantic identity 对应。缺失身份直接报具体失败。
- 给主题动作声明准确可用性，由同一应用动作实现更新；实现确定的两态往返并保留该角色的 selected/checked 等其它覆盖。新增反例证明正常生成按钮可用且两个独立动作能往返，避免只单测直接调用 `executeAction`。
- 在同一实例做 D3 短链：发现/提交 titleStyle → 切页并编辑 → 精确定位的可用按钮真实点击一次 → 公开 STYLES 与标题最终 paint 一致变化 → 再次独立点击验证往返 → 未知标题引用拒绝 → 旧页/草稿/控件继续编辑。以 accepted 状态和读回等待，截图或 drawable 核对实际生效色。
- 汇总所有必需段的 FAIL/BLOCKED/NOT_RUN；只有必需段全部完成才整链 exit 0。加入阻塞 step4j 的负对照，证明它不能再产生整链 PASSED。权限 preflight 仅证明投递权限，动作未变时还要核对 enabled、目标归属、事件到达与应用拒绝原因。

### B. 修正增量文本的正确性与失效边界（Sol）

- 先复现“尾部追加却全文属性写入/fallback”及删除选区映射错误。兼容身份和属性环境的 local edit 保留有效签名，只给新增/受影响范围初始化正确属性、重算字体；未变属性原样保留。沿既有 helper 先映射未完成 dirty 范围，再与本次实际 affected 范围合并。
- 选区端点分段映射：替换前保持，替换区间内落新插入尾，旧尾及之后按 delta 平移，最后 clamp/组合边界校验；纯插入边界亲和性沿现有约定。滚动锚点同样通过编辑映射，不能仍指向旧字符序号。
- 集中梳理 prepare/decorations/draw 三处签名处理：身份、字体/段落属性、颜色、wrap width、内容 dirty 和选区/组合态分别失效。当前 draw 中的宽度特判无法抵消更早 prepare 的全文属性重置；宽度变化重排所需范围，字体变化重算字体，纯选择变化只更新装饰。正确性优先，无法判定的范围用明确安全后备。
- 反例覆盖前/中/尾插删与缩短替换、跨修改选区、emoji/ZWJ/组合字符、换行与一段很长的软换行、宽度/主题变化、拒绝恢复及关闭。逐项比对全文、实际字体 runs、选区和可见 glyph/line 几何；UTF-16 工作量与 UTF-8 传输字节分列。

### C. 让可见正文资源真正按影响范围复用（Sol）

- 将一次更新的准备结果集中持有：有效属性环境、布局失效范围、可见行/字形范围和几何，供 decorations、各 tile draw 和提交共同使用；trace 应证明没有在三个入口重复完成同一准备。
- 第一条可判别快路径：修改位于已知可见布局依赖之后的完整后续段落，且 wrap/字体/颜色/scale/clip/可见锚点未变，复用现有可见正文纹理。可见范围内修改只失效相交片段；修改影响前序换行/双向排布或可见锚点时，从安全段落/布局边界向后失效，确认几何收敛后才复用后续片段。相同坐标或相同 nodeId 本身不足以证明像素相同。
- 缓存键表达实际依赖：稳定组件身份、属性/布局代际、已确认可见片段与几何、像素比例；正文版本用于校验和 dirty 映射，而非无条件使所有纹理失效。当前全文前后缀 diff 仍是 O(N)，单独计时；本包不宣称整条文本更新已 O(改动量)。
- active 正文目前还烘焙 scrollbar。保留纹理前必须处理内容高度/scrollbar 变化：优先用已有装饰层单独绘制，或将对应像素纳入实际依赖；不能冻结旧滚动条。候选/接受纹理沿现有预算与失败保留事务，晚到/被替代准备结果按身份和版本作废。
- 验收既看工作量也看画面：尾部离屏小改后可见正文 raster/upload 零增量；滚至改动处能读到新字；可见改动/宽度/字体变化确实重绘；拒绝保留旧图、恢复后前进。复用已有首中尾与接缝工具，检查明确标记区域及 glyph 位置，而非只有 contains/非零 alpha。

### D. 普通应用多窗响应（Sol，基于 B/C 修正后的实测）

- 先分列三条时间线：直接同步刷新压力、正常 host 事件驱动、native 输入回调内准备。保留旧同步屏障样本作对照，新增 A/B 都经正常应用入口的负载，B 在 A 工作前及持续负载期间分别入队；记录 ready、真实 owner 应用、具体内容 accepted 和 A 每段工作起止。accepted 仍用 post-pump 时明确是上界。
- 需要改宿主时，在原 reentry/关闭保护内拆成“有界派发各窗已就绪事件 → 合并各窗失效 → 轮转处理昂贵准备/提交”。`window.pump` 自己会刷新，因此只交换 host 两行不足以分离；增加内部 drain/deferred-refresh 接缝，保留公共同步调用语义、FIFO 的原场景身份和一次批量发布。持续 A 负载下 B 必须前进，A 也不能被永久推迟。
- turn budget 只能在可让出的边界生效，不能中断一个已经执行中的 TextKit 调用。若 B/C 后仍有单次调用超过预算，用实际子阶段 trace 决定段落/片段的分步准备和版本化提交；期间保留完整 accepted 快照，owner 与准备中状态分别表达。AppKit/TextKit 的现有线程归属保持明确，分步结果成功后才原子晋升。若此处需要改变全文/滚动/组合态的公开语义，带剩余调用成本与具体差异回报指导，独立 A/E 继续。
- 既有 owner p95≤100ms、accepted p95≤150ms 是本包验收目标，分别报告正常应用负载与同步压力结果。B 在繁忙 A 下完成后，停止负载应收敛，关闭 A 后 B 可继续；采样/测试钩子不能人为优先派发 B 来制造达标。

### E. 等价对照、导出与集中交付

- full/local 对照改为 TESTING-only 一次性开关，仅选择局部/完整替换算法；两臂相同初值、编辑序列、字体、视口、scale、焦点/选区和缓存条件，交错或平衡执行次序。真实字号变化留作独立正确性场景。
- 短文/10k/100k、首中尾小修改、可见/离屏、resize 分别记录首轮冷准备与至少 20 个热样本。B3 输出同操作差值的属性写入、实际 affected/fallback 范围、布局调用、decorations、正文准备、raster/upload、总时间；父子计时的包含关系写清。冷启动从实际首次准备到约定接受/资源就绪边界，已有 19ms 的部分 refresh 不能替代。构建配置及源码/产物哈希与普通导出路径一致，编译优化与算法收益分开。
- 沿用未受本包影响的有效测试；针对性反例、native 探针与相关包构建/回归通过后，从最终同源导出做标题短链、改动消费者、两模板的实际输入/动作与读回。生产性能路径也在导出版本核实；83 项是旧清单数量，最终按真实 payload 重新指纹。
- 集中报告修复前后原始样本、选区/字体/实际画面对应、预算结论、导出根/指纹、真实欠项。ACTIVE 同步为真实状态；CGEvent/AX、受控探针、drawable 读回与人工物理输入分别标注。整包完成或实质升级时主动向指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61` 汇报。


### D 补充裁决：进行中到达的输入与分步文字准备（指导，2026-09-24）

Sol 报告 B/C 后，B 预先入队的正常 host 路径 owner p95=2ms、accepted post-pump 上界20ms；A 首次 resize 仍有约142ms native阶段，其中3 tile的 raster合计约120ms。指导已读当前源码与相关日志，未重跑。**认可在本包内扩展内部准备契约；预先入队通过只接受该场景，进行中到达的公平性仍需完成。** 按下列顺序实施，保持公开同步入口与接受语义。

1. **先直接量每片成本，消除重复工作。** 当前 `rasterizeMultilineNode` 的 raster计时包含位图分配、绘制、逐像素unpremultiply和测试alpha边界扫描，不能把120ms全部归给TextKit。`drawMultilineNode` 仍每次求整块visibleLayoutRect的glyph range，每tile只依赖bitmap裁剪。补 per-tile 的 layout/draw、normalize、allocation、upload计时及字形/像素数，使用实际tile交集和必要字形外延绘制，共享一次已准备的可见布局。普通构建与TESTING计数额外扫描的成本分开；优化逐像素路径时维持当前alpha和shader混合约定。同条件验证后若同步块已在预算内，保留最小方案；否则接下述分步。
2. **分步必须发生在发布之前。** 当前 `CjguiCommitComposableSceneOnMain` 先修改ctx版本/nodes，随后 `setNodesFromProjection` 改AX、命中和inputProxy并触发active raster。直接让这个tile循环跨turn不满足原子接受。将候选准备前移到发布边界之前，内部采用 begin/advance/ready/commit/cancel 状态；pending是未接受的工作，不作成功或产品失败。原有显式同步refresh/present可同步耗尽同一准备过程；正常host使用分步入口，只有ready后执行不中断的提交及既有present失败回滚。
3. **job拥有稳定输入和资源。** job携带窗口会话代际、候选版本、节点/资源身份、正文及编辑代际、属性/宽度/scale/clip/scroll等像素依赖。逐片使用该候选拥有的冻结正文、属性/布局及几何，不能跨turn继续读可变inputProxy。这只是派生渲染快照，业务owner保持原归属；对快照复制与初始布局本身也测耗时。改正文、resize、换绑、组合态变化或关窗时按依赖取消/替换，完成时再次核对，避免旧job覆盖随后输入。
4. **接受事实一起发布。** 等全部必要纹理成功且版本有效后，原子更新文字/装饰、场景几何、AX、命中和相关菜单/数据传输投影，并同步仓颉holder/布局/视图状态的commit；准备期间旧accepted继续完整可用，公开查询区分owner已应用与scene待准备。现有局部输入/组合态继续沿原协议处理，不把延迟准备变成锁住输入或重放旧正文。准备失败/替代/关窗释放本job独有资源，保留仍在使用的accepted；计数明确区分accepted、pending、scratch，沿既有预算预留并限制每窗在途job数量。
5. **让出点是主循环边界。** 一个advance只做有界片段，返回host后先派发已就绪事件，再轮转各窗准备；不在raster内部嵌套runloop。3片总量不能证明单片有界，先测每片最大值；若首片独占超预算，再拆其重准备或更细的绘制片段。准备/派发/绘制共享一个真实时间预算，持续输入和resize下轻窗及重窗都要进展，重复失效合并为最新待处理版本。
6. **决定性验收是A开始后B才到达。** 独立发起方在A第一片开始后投递B输入，分别记录producer ready/post、native入队、owner应用、accepted；覆盖工作早段/中段/末段，不能只在让出之后开始计时。按既有owner p95≤100ms、accepted上界p95≤150ms目标统计至少20样本，同时记录A总完成时间/工作量与最大不可让出段。若优化后同步完成A再派发B已稳定达标，允许以该最小方案交付；若采用分步方案，则额外证明B能在A完整候选完成前响应，验证让出机制确实有效。中途编辑/resize/替换、关闭、准备失败、提交失败、预算拒绝验证随实际实现覆盖：无混版本tile，无语义先行发布，输入不丢，资源回收，随后合法候选可恢复。停止后idle收敛。先前同步压力与预入队结果分别保留。

这是原D范围内的具体方案授权。Sol按实测选择最小能覆盖“进行中到达”的实现，A/E独立继续；若公开同步返回含义、全文/滚动或系统组合输入语义需要改变，带具体差异再升级。阶段完成不能只根据2/20ms预入队数据判定。


实现时特别注意两项归属：job校验使用独立candidate epoch与真实输入/组合态revision，不能仅靠sceneVersion或用于离屏复用的bodyGeneration；同值A→B→A也须识别旧任务。取消job释放其自持对象，不能扫描已被新候选替换的当前staged。最终present失败时只恢复紧邻提交之前的快照，不能把跨turn开始时捕获的旧快照恢复回来、覆盖期间的新编辑。


#### D 后续澄清：诊断开销与最小方案（指导，2026-09-24）

Sol 后续定位到 TESTING 的 `CjguiLogMultilineGlyphDrawingState` 在 verbose关闭时仍格式化全文UTF-16、遍历font runs与字体查询；将guard前移后，当前日志resize前4样本的native_stage为51/37/34/35ms，首样本3tile raster为25166us。指导已核对guard源码及这些日志，未重跑；这更正了先前把约120ms当成生产栅格固有成本的判断，普通导出仍待同路径核实。

第1条“满足预算可保留最小方案”优先；第2–5条及job归属规则适用于实际采用分步机制时。第6条已澄清：同步A完成后再派发B，只要“进行中到达”的端到端100/150ms预算稳定通过，即可收口本项，无需为顺序本身建立新状态机。采用分步机制时才附加“B早于完整A完成”的机制性证明。

补证要让计入重负载的样本真的发生重准备：独立投递覆盖A工作早/中/末段；通过不同有效宽度/内容使需测的resize样本产生实际raster，冷热分列，避免少数重样本被大量cache hit掩盖。记录最大完整不可让出区间（同步方案不是单tile时长）、B的raw ready/post到owner/accepted及A自身完成时间，持续事件负载下双方有进展。普通导出验证与受控探针分列。此项是当前多窗响应预算，不推导帧率或每帧16.7ms已达标；余下可见resize成本按实测保留。

### Sol/Luna 本轮执行记录（2026-09-24；最终桌面验收待续）

- **A（Luna 实现，Sol 集成检查）**：生成面板标题动作改由真实 provider 报可用，并在接受状态内两态切换生效 normal 色；step4j 的初始化、精确语义目标与 BLOCKED 汇总已修。`CJGUI_PREVIEW_CHAIN_CLASSIFICATION_SELF_TEST=1` 得 `PASSED classification_negative_control step4j_blocked_exit=3`；同源导出中的 generated_panel_consumer build-only 通过。标题完整 CGEvent/AX 点击、公开 STYLES 读回与最终像素往返仍未验，不能以逻辑用例或构建替代。
- **B/C（受控 native 探针）**：局部编辑保留兼容的属性环境和有效 TextKit 状态；修正删除/缩短替换的选区端点与滚动锚点映射。离屏完整后续段落更改经布局依赖判断可保留可见正文纹理；可见短 ASCII 段落等高局部替换只重绘相交 tile；软换行、Unicode 等不确定区域走安全全量后备。正文纹理 key 不再无条件含全文，滚动条单独作为装饰画。`verify_projection_partial_text.sh` 通过，选区 after/inside/cross/emoji-ZWJ 和 20 个可见 tile 替换各通过；可见 tile 样本每次 `raster_delta=1`。这仍是内容/栅格计数及局部几何证据，真实像素和滚动后的新字待窗口复验。
- **等价对照（TESTING，20 热样本/臂，平衡两种顺序）**：380 行正文 10150 UTF-16 units/16230 UTF-8 bytes，3700 行 102490/161690。最终源码上的 3700 行 head 局部 p95 约 9–10ms、强制 full p95 129–137ms，两臂均 40 次正文重栅格；mid/tail 局部 p95 0ms、重栅格 0，full p95 约 131–139ms、40 次。380 行 head 约 9–10ms 对 22–23ms，mid/tail 同样局部 0 次/full 40 次。每样本 accepted 全文一致、字体和初始正文一致，冷开窗单列在 `/private/tmp/cjgui-sol-final-partial-{head,mid,tail}-{380,3700}.log`。full 是 TESTING-only 强制替换对照，数字不可称为发布版或真实键鼠延迟。
- **D（受控 native 投递）**：关闭 verbose 时仍做全文 glyph 诊断的额外工作已加 guard；每 tile 分列栅格子阶段。`verify_two_window_workload.sh` 的正常 host 预入队 20 样本 owner p95=2ms、accepted post-pump 上界 p95=20ms；独立定时生产者在 A 实际工作早/中/末段发出 B，20/20 `post_during_a=true` 且每次 A `raster_delta=2`，owner p95=18ms、accepted 上界 p95=36ms，A 完整不可让出段最大20ms。故按指导后续澄清保留同步发布，无跨 turn job；这些是受控投递，不证明普通导出 CGEvent/AX 性能或帧率。`verify_interaction_scheduling_efficiency.sh` 亦通过。原始样本 `/private/tmp/cjgui-two-window-workload/probe.log`。
- **截图可读性**：`CJGUI Partial Text` 原有深色 clear color 与 emoji/数字/中文压力正文是探针布置；正文沿用近黑默认前景导致对比不足，是未处理好的探针样式。探针现显式设置 `(0.92,0.95,1.0,1.0)` 浅色前景，accepted scene 的 `readable_style=true`，双窗重负载探针同步设置。因本轮桌面会话锁定，修正后的实际窗口截图与画面像素尚未取得。
- **最终同源导出与本地回归**：`cjpm build --skip-script`、`cjpm test -j 4` 184/184、生产 native `clang -fsyntax-only`、`verify_large_text_window.sh`（含 10k/100k 字窗口）、`verify_composable_ui_appkit_text.sh`（delegate 的正文/选区投影）、`git diff --check` 均通过；受保护 `runtime_state.cj`、`cjpm.toml` 未写。导出根 `/private/tmp/cjgui-sol-final-20260924141035/cjgui preview/export`，83 文件 `identical=75 rewritten=8`，payload SHA-256 `73cbc1e800bb9346281527760de5a7b8fdafad69473287ba1931500278aac98d`，指纹负对照 4 个修改拒绝、2 个 rewrite 入哈希。两个最小模板和 generated_panel_consumer 的 build-only 均显示 source_origin 为该导出根；未把 build-only 说成实际输入/外部读回。
- **剩余阶段验收**：真实窗口修正文字画面/像素、滚至修改位置、标题两次真实点击与公开状态/像素往返、两模板实际输入和真实外部调用、普通导出双窗时延。当前锁屏，按照 AGENTS 的锁屏跳过规则暂停前台探测；最终 export 消费链此前在 step2c AX 标识符缺失，现脚本对明确锁屏分类为 `BLOCKED` exit 3，未宣称整链通过。旧实例与用户桌面保持不动，待解锁后复验并清理本轮临时实例。

### Sol 桌面解锁后的接续证据（2026-09-24）

- **原截图判定与实拍**：`CJGUI Partial Text` 的深色背景、emoji、中文和数字是长文本/混合字符压力探针布置；近黑正文未显式设置前景色，导致深色底上的低对比，是探针样式缺陷。探针已声明浅色前景并在 accepted scene 校验。解锁后运行自有临时窗口，实拍 `/private/tmp/cjgui-sol-partial-light-local.png`：浅色正文和 emoji 在深色底上可读；探针 `CJGUI_PARTIAL_PROBE passed=true`，临时窗口退出码 0。实拍属于受控探针的真实窗口画面，不把它称为生产应用或人工物理键鼠验收。
- **A 的真实消费中发现并修复两处契约问题**：首次导出链的 tabs 容器没有声明 key 对应的 accepted semantic identity；为 `cjguiComposableTabs` 增加可选 `containerNodeId`，生成路径传入已有保留 ID，手写路径沿用原 scoped identity。生成动作按钮的公开 `acceptedInstances.actionName` 原暴露内部 `GENERATED_ACTION`，而非声明的 `TOGGLE_TITLE_ACCENT`；补 RED 回归后让普通生成动作投影解析 accepted holder 声明。生成面板测试 34/34、主包 184/184、`cjpm build --skip-script` 均通过。复合动作的公开投影仍需单独覆盖，不据此宣称所有复合动作绑定已验证。
- **验收脚本的实测反例**：同一导出链先因滚轮窗口非 key 而不能移动；显式激活/聚焦自有目标后真实滚轮偏移 `199→0`。标题真实点击已使 `STYLE_REVISION 380787558→1984873254`，但 macOS `sed` 对原 BRE 颜色表达式未匹配，空颜色是脚本解析缺陷；改用精确 `normal[textColor=#RRGGBBAA]` 解析并以原始状态、蓝色、紫色做正例。三点中心截图采样均落在页签文字间空白；改为只截该 AX 页签边框并扫描目标字色，合成图正负对照通过。两处脚本错误未被记作产品渲染失败。
- **最终同源导出与真实输入**：导出根 `/private/tmp/cjgui-sol-title-pixel-final-20260924/cjgui preview 20260924152945-22312/export`，83 文件（75 identical、8 rewritten）payload SHA-256 `84593eda4a3699c3d160f28536ded7964155e11cbb1f954e1dcba99c282fee1d`。`verify_framework_preview_consumer_chains.sh` 最终 exit 0，`PASSED exported consumer chains`。规则与生成面板的实际输入为授权 CGEvent/AX，业务值通过公开 owner 读回；step4j 两次真实点击使公开标题色分别为 `#1A4DD9FF`、`#8C2699FF`，局部截图各有 517/551 个匹配字色像素，截图为该导出轮的 `title-paint-1A4DD9FF.png`、`title-paint-8C2699FF.png`。未知标题引用被拒后旧 notes 控件仍可真实编辑。
- **两最小模板从同一导出根实际消费**：在 `/private/tmp/cjgui-sol-final-templates-20260924` 创建独立 bundle ID 的 ui-only 与 collaboration 模板，两者 build-only 的 source/native/dependency/resource origin 均指向上述导出根。ui-only 窗口用 CGEvent 输入 `template-note-20260924` 并点击计数，AX 读回 `已点击 1 次；注释：template-note-20260924`。collaboration 窗口用 CGEvent 输入 `template-shared-20260924` 并点击提交，AX 与公开 GET_CONTEXT 同见已提交、共享版本 25；经已授权公开 `SET_TITLE` 调用改为 `external-template-20260924`，公开结果 `APPLIED true`、版本 26，AX 摘要同步变更。自有 ui-only 进程按精确身份终止；collaboration 用本窗 close button 正常关闭，进程与 descriptor 清除。未触碰旧用户实例。
- **证据边界与当时余项**：最终导出链的同机两个独立应用段有一次功能样本，B 的公开 owner enqueue→applied 为 206ms、applied→scene 为 139ms，A 的提交→accepted 为 129ms；该段以图片/生成结构为负载，含公开调用与读回，不是受控 D 的重文字工作中投递 20 样本，不能拿单样本证明 100/150ms 预算，也不能将受控 D 结果推广为普通导出键鼠性能。该记录时，局部正文修改后滚至该位置的真实窗口 glyph/像素尚未单独验收；后续补证见下文。`git diff --check`、脚本语法、颜色解析/区域扫描正负夹具通过；`runtime_state.cj` 与 `cjpm.toml` 未写，未 stage/commit/push。


### 最后两项验收范围裁决（指导，2026-09-24，解锁接续后）

已读取最终导出链原始日志：step4j真实点击、公开色值、局部标题像素和拒绝后续写，以及最终exit 0均有记录；两模板交互按执行者报告保留，指导未重跑。剩余C的离屏修改后滚动到新字、E的普通导出生产路径性能均属已下发范围，继续完成；其它已有效验收沿用。

**补正双窗证据归属。** `verify_framework_preview_consumer_chains.sh` 的step5d分别启动rule_set_window_app与generated_panel_consumer，有独立PID/descriptor/运行入口。这里same-host表示同一台机器，不是一个CjguiMacosApplication/主循环。其206ms+139ms是单次公开命令/查询观测，不直接与D受控native投递的18/35ms比较，也不足以判定同进程调度失败；脚本与报告应明确标为同机两应用功能证据。

最后采用一个有界的普通导出消费者完成两项，优先复用既有长文本controller/host结构与桌面驱动：

1. **可见结果闭环。** 顶部可见时，经正常owner入口修改离屏尾部的唯一标记；随后用系统滚轮/键盘移到该处，记录owner精确值、实际滚动位置/可见glyph范围和局部窗口图像，检查新标记及中文/emoji可读、旧标记已替换。再在可见位置编辑一次并读回；必要时返回顶部检查旧前缀仍一致。仅contains或非零alpha不够；可在同一轮完成，不重跑整个矩阵。
2. **普通导出同进程双窗。** 用导出框架、普通launcher/native构建，在同一个CjguiMacosApplication中打开A长文与B轻输入窗口（同PID、不同窗口身份）。A做实际改变有效宽度的重准备，B由独立发起方在A工作开始后通过正常系统输入或公开授权入口操作，完成至少20个有效重叠样本，早/中/末段覆盖，冷热分列。每样本核对A确实发生目标重准备、B唯一内容实际owner应用与场景接受；保存producer ready/post、入口、owner、accepted的原始时间和观察上界。使用现有只读计时即可；必要的观测不改变派发分支、不通过TESTING队列注入制造普通入口证据。若选公开调用，使用常驻客户端和单调时钟，进程启动/序列化/轮询成本单列，不能事后直接从总数里猜测扣除。

系统输入和公开调用不是同一种时延，报告明确本次选定入口；至少保留同一普通实例的真实控件编辑与窗口反馈。无需20轮人工物理键鼠，也无需重做已有两模板链。两项可共用一个消费者和最终导出，普通路径与受控D保持相同文本规模、布局/scale与构建配置关系。沿既定100/150ms预算验收选择的普通入口；若公开读回仅能提供较粗上界而超标，先用实际owner/accepted时序区分测量开销与生产延迟，不能单凭粗轮询下性能结论。停止负载后收敛、关闭A后B继续的已有场景一并有界检查。

若只添加验证消费者/脚本且导出payload未变，复核指纹后复用本次最终导出；生产源码再变时刷新导出并重跑受影响路径。阶段收口如实列出正常生产和受控证据，图片/结构双应用样本不替代文字双窗；没有新疑点时不重复整套历史回归。

### Sol 补齐 C 的普通导出可见结果（2026-09-24）

- **RED 与根因**：普通导出长文应用中，owner 接受了离屏尾部文本，实际滚轮到达多行输入控件，TextKit 滚动 offset 和可见 glyph 范围前进，但截图仍停在第 0 行，native `frame metadata` 仍为第 2 帧。`scrollActiveMultiline` 只刷新衍生文字纹理并使 `CAMetalLayer` 宿主 view 失效，未提交下一 Metal 帧；这不是滚轮路由或 owner 值问题。隔离诊断 native 复制件直接调用现有 `present_clear` 后，实拍行号从 0 前进到 126，确认缺少提交这一原因；诊断复制件未作为正式导出证据。
- **正式修复与同源消费**：生产 `cjgui_internal_renderer.m` 在 native-only 滚动完成纹理准备后，按 session token/generation 和 overlay 身份，在主线程下一轮合并提交已接受场景；资源重试成功时也安排提交，不晋升 staged candidate。新导出 `/private/tmp/cjgui-sol-scroll-present-export-20260924/cjgui preview/export` 有 83 文件，renderer 源码 SHA-256 与工作区同为 `011715a9b380deecf479bfec4e2e7fd21e5ac9594a86db67c0852d232c34f796`。普通 launcher/native 构建的临时消费者使用该导出；没有 `CJGUI_INTERNAL_TESTING` 事件路径。`clang -fsyntax-only`、`verify_large_text_window.sh`、`cjpm build --skip-script`、`git diff --check` 均通过。
- **GREEN 实际画面与 owner**：同一普通消费者启动时 accepted 值含 `OLD-MARKER-ABC123`；owner 更新后 `old_before=true accepted_tail=true old_after=false`，场景版本为 2。窗口顶部初见第 0 行；真实桌面滚轮后 native 新增第 3 帧、scene version 仍为 2，截图 `/private/tmp/cjgui-sol-scroll-present-export-20260924/replaced-tail-visible.png` 可见第 699 行、中文、emoji 和 `尾部新增 END-MARKER-XYZ987`。Apple Vision 对该真实窗口截图识别出新标记并给出归一化字框 `(0.00872, 0.04150, 0.29506, 0.02798)`；旧标记不在 accepted 值。随后在可见尾行点击输入 `EDIT-OK`，owner 最终 revision 10 读回 `tail=true edit=true`，scene version 3；截图 `/private/tmp/cjgui-sol-scroll-present-export-20260924/replaced-tail-after-edit.png` 的 OCR 分别定位新标记与 `EDIT-OK`。这是系统桌面输入、正常应用 owner 与窗口像素的闭环；D 的普通同进程双窗 20 样本仍待独立补证。


### D 普通布局全文测量阻塞裁决（指导，2026-09-24）

Sol 的普通导出同进程双窗暴露了受控 native 路径未覆盖的实际瓶颈：3700 行、102490 UTF-16 / 161690 UTF-8，A 两次刷新墙钟约 17.7/17.3 秒。指导只读核对 `/private/tmp/cjgui-sol-two-window-production-20260924/profile-a.txt`：4193/4193 主线程样本停在 `CjguiMeasureComposableTextOnMain → NSString boundingRectWithSize → CoreText`；`layoutVertical → preferredHeight(multiline)` 先同步全文测量再 growth/shrink，父容器最终尺寸已确定时仍做了不影响结果的工作。原受控约 20ms 与本次普通布局不是同条路径，不能相互覆盖。日志原 `mono_ns` 实际为微秒的错误须更正并保留旧记录。

**裁决：fixedHeight 只作区分实验；实施保持现有尺寸语义的框架约束剪枝，原无 fixedHeight 消费者必须复验。** 本项由 Sol 负责生产实现，Luna 可并行承担确定性布局反例与消费脚本，构建/桌面仍串行。

1. **先消掉可证明无用的 intrinsic 测量。** 在已得到 definite bounds 的 `layoutVertical` 分配入口，若唯一 child 有 growY>0、没有 fixedHeight/布局覆盖、min/max 合法，旧 preferredHeight→growth→shrink 的结果恒为父 inner.height 经 min/max 限制后的高度。直接分配该结果，沿原 cross-axis/clip/scene 路径继续，文字长度不再参与外框高度。可推广为唯一弹性 child + 其它全 fixedHeight 的兄弟，剩余空间扣除固定尺寸和 gap；先验证溢出/min/max/取整完全等价。嵌套容器只在各自收到确定 bounds 后按同一规则处理。普通 growY 的多个非固定兄弟保留旧算法：前兄弟 intrinsic200、min0、grow0，后 editor grow1，父高300，editor intrinsic100 与500 的最终分配不同；不能用通用剩余空间替代。`naturalHeight` 的无约束查询不能看到 growY 就截断。若实现 idealHeight/idealWidth 早返回，同样按 constrainedLength 的现有优先级与 min/max 推导，不能扩大公开语义。
2. **精确全文测量单独处理。** 真正内容自适应的 Text/Multiline、scroll 内容 extent 等仍保留精确高度，不能把估值标成精确、固定返回72或把 maxHeight 当成目标高度。对当前 NSString 全文测量做一次有界同条件归因对照：同正文/宽度/字体，比较现有路径与复用现有字体解析及 TextKit 度量资产的独立测量路径；短文、100k 多段、单长段及中文/emoji/组合字符检查尺寸、换行/尾行和实际绘制一致，区分 font fallback 与行布局成本。不共享/修改活动 inputProxy 的排版状态。仅当语义等价且成本改善有证据时纳入替换；否则带该路径的成本和可验证方案升级，保持此缺口打开，不能据填满窗口路径变快宣称全部自动高度已解决。本项不是增加编辑器功能。
3. **判别与验收。** 保留原无 fixedHeight RED（栈、源码/产物、样本规模），新增确定性布局等价与测量计数检查：唯一弹性、固定兄弟、min/max/ideal、窄/零空间、嵌套、真实 auto-height、多非固定兄弟反例。应跳过的正文测量为零，需要 intrinsic 的布局仍保真；短文/长文几何和 accepted 内容对应。计时外验证正确性。生产修复后刷新正式导出，用原普通同进程双窗、原无 fixedHeight 配置完成至少20个 A 真工作中到达 B 的有效样本（owner p95≤100ms、accepted观察上界p95≤150ms），启动/冷热、入口投递开销分列；同时保留 A 自己完成、停止收敛与关A后B继续。驱动启动/查询耗时不混为产品耗时或猜测扣除。已通过的 C 可见滚动、标题与模板链沿用，只有新改动影响时才复跑相关段。

这是当前 D/E 交付内的具体实施裁决。局部剪枝成功不等于一般 intrinsic 测量性能问题自动关闭；最终报告分别给出约束布局结果、真实全文测量结果和未解决边界。


**同次裁决补充：实际宽度与正常投递。** 只读审查发现 vertical 当前先按父 inner.width 测孩子高度，之后才求孩子的 fixed/max/align 实际宽度；对仍需 intrinsic 的分支应先解析孩子最终宽度再测高，沿 horizontal 已有顺序，补父宽900/子宽540折行反例。此为同一尺寸求解链正确性，不以“优化等价”为由保留错误测高。

Sol 的 fixedHeight 区分实验已上报：A 同规模普通构建约94–96ms，相比17秒证明全文测量是主因；当前只接受该对照，不替代原声明。D 主量化入口裁决采用**常驻公开授权客户端**，沿既有公开操作/应用事件队列进入 B 的真实 owner。client 在 A 工作开始信号后发唯一值；统一可比的单调时钟、保存发送开始/完成、服务器到达/入队（可观测时）、owner、accepted；至少20个请求确在 A 实际准备区间到达的有效样本，错过窗口的样本明示不计。启动客户端、CUA调用和查询轮询成本单列，不能用CUA返回时间替代投递时刻。主表按producer发送开始到owner/accepted的实际或严格观察上界验100/150ms，同时列正常入口的分段值。受控/新增测试投递不能替代普通公开路径；允许临时消费应用使用已有授权/owner接口，不为基准给框架加专用生产写入口。另保留同一普通实例真实键鼠编辑成功的功能证据，CUA百毫秒往返不要求凑20轮。


### D 单片/多片绘制分歧裁决（指导，2026-09-24）

Sol 已报告 definite 布局反例转绿、189 测试通过；普通导出无 fixedHeight 在首行小改+宽度变化时，A仍有约21/200ms双峰。指导读取 `/private/tmp/cjgui-sol-definite-two-window-20260924/run/{consumer-events.log,resident-client.jsonl}` 及当前 native 源码：慢宽540/574/608/760/557，快宽779/817/798。`CjguiComposableTextTexture` 当前仅 tiles.count>1 才创建共享 TextKit，单片走 NSString.drawWithRect；若scale2、高680，8MiB阈值约宽771，与全部样本吻合。这是强可验证假设，仍须实际tile/scale/分支日志确认，未把源码推导当运行归因。fixture只先开A后开B，没有文本focus操作：B key window与文字active身份分开记录，不能套用active TextKit旧探针结论。

**最小路线：先确认分支，再统一多行候选的文字准备；保持内存分片仅影响分配与裁剪，不决定排版算法。**

1. 每个A样本记录实际scale、textureRect、plannedBytes、tileCount、activeNodeId/kind/keyWindow、shared/NSString分支和cache命中。分开 stack准备、glyph-range/layout/draw、normalize/upload时间，低开销只读观测；避免再用采样器严重干扰后的数值做性能结论。固定原540宽/正文/视口做单变量对照：仅让单片multiline也消费既有候选独占的共享TextKit路径；实际drawWithRect大耗时消失才确认根因，随后恢复完整宽度序列。其它小控件的路径保持按需。
2. 共享路径先修几何一致性再推广。当前prepared.container未显式设lineFragmentPadding，而active inputProxy为0；按现有7/6节点inset明确同一零额外padding及相同word-wrap/字体/行距。tileInContainer应从scene textureRect转换为node-local再减textRect.origin，审查并补齐node.x/y；bitmap变换、glyph-range查询和最终绘制坐标分别写清。用非零节点原点、祖先裁剪、1x/2x、单片/多片、中文/emoji/组合字符、长软换行、聚焦/失焦切换与tile接缝验证：同一几何下测试用强制分片只改变纹理分块，文字位置/换行/选择定位/有效像素不随分片策略改变。必要像素边缘容差需具体说明，不能以contains/alpha非零冒充。prepared按候选拥有，准备失败沿原预算与accepted保留；不得因扩展到单片吞掉TextKit准备失败后继续另一排版路径。
3. 这项修复与**精确intrinsic替换**分开。已读取独立对照README：100k多段TextKit约59ms而NSString约17s，但长单段高度/性能、默认padding与绘制有反例，因此不整体替换measure_composable_text。本次规范单/多片multiline绘制为同一现有控件契约，可校正其已存在的不一致；不把这个规范当作其它Text/auto-height的自动验收。精确intrinsic欠项仍按上一裁决保留。
4. D保留既定100/150ms预算、普通公开入口和原宽度序列，不调大256ms READY deadline来代替修复。该deadline是等待请求的claim/cancel边界；诊断约742ms的整篇改写压力时允许单列其拒绝事实，不能将过期请求延后应用或重试为另一次成功。原全行改写与首行小改应分别记录，后者通过不覆盖前者；修复后至少做一次原全行改写区分复验，再据实际最大同步段选择已授权的分步准备方案。
5. 当前consumer把B_OWNER时间记在buildUi首次观察document.version处，本质是owner-observed上界（JSONL已称owner_upper），报告与marker名称应统一；需要排除测量开销时补实际owner提交或响应产生时刻，不能把观察时间冒称提交点。A_END同样区分refresh结束与post-pump观测，正文hash/大诊断移到计时区间之外；正常用户可见入口和owner写入逻辑保持原路径。准备分支通过后完成20个有效重叠样本、A自身前进/停止收敛/关闭后B继续；按真实A工作窗选择早中末投递，错过工作窗的样本保留但不计。最终导出需包含新生产修复。

Sol继续当前整包，Luna可接非零原点/分片几何反例与验收脚本；共享renderer由Sol统一写入。若上述同分支对照不成立，带两组原始子阶段结果升级，不继续围绕假设盲改。一般准确intrinsic测量仍单列，当前D不可仅以快宽样本或较长deadline收口。

### Sol/Luna：D 普通双窗与分片几何接续证据（2026-09-24）

- **布局 RED→GREEN**：原无 `fixedHeight`、3700 行、102490 UTF-16/161690 UTF-8 的普通双窗，A 刷新约 17.3–17.7 秒；主线程采样 4193/4193 落在 `layoutVertical → preferredHeight → NSString boundingRect`。只改成 `fixedHeight` 的区分实验约 94–96ms，未当成修复。生产 `composable_ui.cj` 在确定父尺寸、唯一 growY 子项的可证明路径跳过无用 intrinsic；仍需测量的子项按实际分配宽度测高。新增五项布局反例先 RED 后 GREEN；包测试 189/189，`cjpm build --skip-script` 通过。真实 auto-height 和多非固定子项保留精确测量；100k 多段 TextKit/NSString 的独立成本对照不能证明所有文本的高度与换行等价，故一般 intrinsic 性能缺口继续开放。
- **单片慢分支 RED→GREEN**：原普通导出首行小改加宽度变动，scale 2、高 680pt 时 540/574/608/760/557pt 等单片约 200ms，779/817/798pt 等双片约 20ms；临时 native 分支日志证实 tile count 与 `drawWithRect`/prepared TextKit 对应。生产 renderer 统一多行候选的单片/多片为同一个候选独占 TextKit 布局，设置 `lineFragmentPadding=0`，tile 查询坐标减去 node 原点与 text inset；小单片控件仍走原路径。准备在非空文字区域失败时拒绝候选，不静默转回逐片 `drawWithRect`；空 inset 仍允许空图。生产 Objective-C 语法检查通过。
- **几何测试的真正口径**：新增 native 反例在非零 node 原点/clip、1x/2x、ASCII 与中文/emoji/组合字符覆盖首末字带、接缝和单/多片。旧源码的 2x 首片可见字带比直接参考宽 117px（RED）；坐标/padding 修复后旧反例 GREEN。进一步用相同 node、正文、scale 2 和同一 prepared 对象，强制一片及上下两片并重组成一个 *scene* 平面。原始位图 `upperRaw||lowerRaw` 的差异是错误拼接方向：生产纹理绘制逐片翻行；按实际 scene 行序，各片翻行后依位置拼接，ASCII 与 Unicode 均 `scene_pixel_diff_bytes=0`、行 mask 差 0，接缝一致。原始失败与更正后的退出码、glyph range 在 `/private/tmp/cjgui-shared-text-tile-partition-diagnostics-20260924/`；显式全文 `ensureLayout` 的临时单变量对照与现状相同，不作为生产修复。仍不把这一局部 bitmap 对照称为窗口 GPU 完成或所有祖先裁剪证明。
- **普通同进程出口**：新同源导出 `/private/tmp/cjgui-sol-shared-multiline-export-20260924` 构建的一个 `CjguiMacosApplication`、A/B 两窗、同 PID 的普通消费者，通过公开授权 `REPLACE_RANGE` 的常驻独立客户端在 A 真刷新工作早/中/末段投递；28/28 有效，其中首个为预热后首次重叠、27 个热样本。A 每次实际变宽、刷新并接受 3700 行内容；27 个热样本 A 同步段 p95=22.014ms，B 从发送开始到 owner 在 `buildUi` 首次观察的上界 p95=25.269ms，到 accepted 画面状态观察的上界 p95=42.433ms，最大分别 22.325/25.345/42.825ms，低于 100/150ms 预算。启动/预热 195.033ms 独列；`B_OWNER` 不是精确提交时间，`A_START..A_END` 包含回调及 pump 后观察。原始 `resident-client.jsonl`、`consumer-events.log` 在 `/private/tmp/cjgui-sol-shared-two-window-20260924/run/`。另外整篇 3700 行每行改写的单次区分复验 A=18.420ms、B owner 观察上界 21.927ms、accepted 上界 39.586ms，见 `/private/tmp/cjgui-sol-shared-full-rewrite-20260924/`，单次不称分布。旧约 742ms 拒绝样本作为先前压力基线保留。
- **停止与关窗**：当前 renderer 的受控双窗脚本 20 个中途投递样本 owner p95=17ms、accepted 观察上界 p95=35ms、A 最大同步段 20ms；负载停止后同 session `raster=314→314, upload=314→314`，见 `/private/tmp/cjgui-sol-two-window-idle-20260924/probe.log`。普通消费者完成第 29 帧后，到约 29 秒后真实 B 编辑前无新增提交帧；该普通日志无 raster/upload 计数，故两者分列。关闭 A 后 B 窗与公开 connection 仍在，同实例真实键鼠编辑 `B-PROD-28` 被 owner 接受并在窗口显示，截图 `/private/tmp/cjgui-sol-shared-two-window-20260924/run/b-after-a-close-human-edit.png`。精确临时 PID 正常退出，descriptor/socket 清除。
- **最终导出及偶发探针**：补上 shared-layout 准备 nil 的失败守卫后，新导出 `/private/tmp/cjgui-sol-shared-final-20260924` 的 83 文件指纹 `f37b8cffa8746ad8bec3e6cc53f01b418a63ebe20f722c0fbd5c05c424a76046`，75 byte-identical/8 约定重写；守卫后的正式 `verify_projection_partial_text.sh` 和 `verify_two_window_workload.sh` 均 exit 0，`git diff --check` 通过。曾有一次当前 native 的 `full→local` tail 探针在第 4–18 样本额外 raster 2–6、断言失败；精确旧 native 单次通过，但加入 refresh/pump 分段计数后当前源码连续六次独立进程通过且无法复现。因此尚不能归因于 shared layout，也不能宣称偶发风险已消除；失败原始日志 `/private/tmp/cjgui-sol-partial-shared-20260924/probe.log` 保留。新最终导出包含守卫，普通 27 热样本取自守卫前导出；守卫仅改变 shared-layout 非空准备失败分支，不能将前次性能数值称作新导出的重测。

### 指导集中复核与剩余接续（2026-09-24，普通双窗达标后）

指导本次只读审查生产源码、消费者、测试与原始日志，并运行导出指纹比较和 `git diff --check`，未重跑产品测试。确认两份性能被测源码与对应导出逐字节相等；28 条发送时间均落在 A 工作区间，热 27 条最近秩 p95 重算为 A 22.014ms、B owner-observed 上界 25.269ms、accepted 观察上界 42.433ms。**接受该普通双窗负载的预算交付**，195ms 启动/预热及全行改写单次结果另列。确认最终 83 项指纹为上述 `f37b8cff…`；末次 nil 守卫未改变成功绘制路径，旧成功性能证据可以沿用并标明版本，不要求为同一事实重复整套测试。分片原始数组的 RED 属测试行序错误，归一到生产 scene 平面的 ASCII/Unicode 原始结果均为零像素差。

当前仍在同一阶段：保留已交付 A–E 成果，完成以下两个相互独立的工作包。文字/布局性能与真实输入是优先主线；资源调度沿用已通过的双窗预算，语义与真实 owner、样式及开发者接入沿用现有链。编辑器与 GB 文档引擎由用户另外规划。

**1. 绘制与输入衔接收尾（Luna 实施，Sol 集成）。**

- 复核时正式 `compareForcedPartition` 的 Unicode 分支只断言行 mask，仍可放过字形像素变化。Sol 随后已补与 ASCII 相同的 `sceneDiffBytes == 0` 强断言，指导核对新源码与 `/private/tmp/cjgui-sol-shared-tile-final-run.log`，同 prepared、同 scale、同几何正例通过。补一次定点像素变造的负对照即可，避免重跑既有正例矩阵。直接 NSString 与 TextKit 的其它比较另列，不能混入此严格同路径断言。
- 对新共享多行路径补一条有界聚焦→失焦→重新聚焦链：非零原点、实际裁剪、中文/emoji/组合字符和软换行，比较同一可见标记及选区/插入点几何，随后真实控件输入并由 owner 精确读回。可复用已有窗口与测试 seam；分别记录状态、纹理/画面与工具输入证据。单/多片分片等价已证明的部分沿用；只比较正文时明确排除光标/选择高亮等本应改变的装饰。
- 真实准备失败的 nil 守卫与合法空 inset 边界须有针对性验证，保证拒绝保留原 accepted，随后合法候选恢复。保持现有候选/纹理预算事务。

**2. 精确全文测量的剩余性能问题（Sol 主责）。**

**段落实验已完成，以下裁决取代“与旧四指标完全相等才接入”的试验分支。** 独立夹具短例相等，但重复行从 365 增到 366（10248 UTF-16 单位）后，整篇 NSString 宽为 265.398669291，逐段为 267.023669291，取整 266/268；高度相同。大样本约 16.6s/36ms 是两种不同结果的成本，不能称等价加速。最小反例在 `/private/tmp/cjgui-sol-paragraph-measure-threshold3-20260924.log`，实现仍在独立实验中。指导核对源码与原始记录，未重跑实验；系统内部阈值成因尚未证明。

指导确认现有契约缺口：通用测量入口统一 char-wrap，而多行输入框的静态共享绘制与 active input 使用 word-wrap、零 line-fragment padding。下一步授权 **已解析内容宽度的多行输入框自然高度查询**，让这一角色的测量与实际绘制/输入遵循同一文字布局规则。旧通用 `measure` 的 width/height/lineHeight/baseline 及原 FFI 保持原语义，不用两个不同布局算法的结果强行判等。

- **最小接缝。** 在 measurer 增加可选的多行自然高度能力，`preferredHeight(multiline)` 按最终内容宽度调用；原自定义 measurer 未实现时仍消费它的原 `measure(...).height`。布局包装器必须传递该能力；高度查询与旧完整测量缓存分开或显式加入 role/query-kind，覆盖宽度、字体、内容、策略版本及既有环境失效条件，只缓存成功值。新入口失败继续设置 measurementStatus 并拒绝发布估算场景。需要公开的新增接口标为预览能力，只传平台无关值；原生返回标量，不暴露 TextKit 对象。未知角色不按文本是否含换行猜测。
- **高度的依据。** 原生复用/提取现有多行 TextKit 配置：相同字体与 fallback、word-wrap、零 fragment padding、内容宽度，外框的水平 7+7 与垂直 6+6 inset 只计算一次。精确 auto-height 在独立测量布局中完成所需全文排版后，依据实际 line fragments 的占用范围返回自然内容高度；空文和尾换行须容纳合法插入行，结合 `extraLineFragment` 明确处理。现有外层 minHeight=72、约束和取整仍由布局层负责。`usedRect` 本身不触发布局，不能把未排完的局部范围当全文高度。测量对象与可变 active input 分离，复用的是规则而非修改当前编辑状态。
- **正确性验收。** 先固定 char-wrap/word-wrap 分歧的小反例，再以实际生产多行绘制/输入的 line ranges、行矩形和末尾插入点为依据，验证同内容宽度下自然高度足够且 inset 未重复。覆盖空/尾空行、LF/CRLF/Unicode 分隔符、中文/emoji/组合字符/双向文本、tab、临界换行宽度，以及 365/366 行、100k 单长段和多段。保留旧 API 的原值测试；新角色预期变化须同时有实际布局证据，不能只改数字。新增能力未实现的自定义 measurer、相同文本/样式的两种查询缓存隔离、测量失败保留 accepted 与合法恢复，都要有区分用例。补嵌套 auto-height vertical → fixedWidth 多行子节点：`naturalHeight` 的 vertical 分支仍直接传父 availableWidth，须让自然高度和最终布局使用同一已解析子宽度（含容器 padding/约束），先红后修，避免只修顶层 `layoutVertical`。沿用 Luna 对聚焦/失焦画面与输入的独立检查，若 fallback 或行几何不一致，定位同一配置源后修正。
- **成本与实际消费。** 优先复用当前普通双窗消费者，A 使用真实 auto-height、给定宽度且没有固定/填满高度绕行，B 经公开入口在 A 工作期间送达。分别记录测量、构建、提交与 B owner/accepted 观察上界，冷启动另列；至少 20 个有效热样本与工作停止后的收敛。目标沿用 100/150ms，未达则按实际耗时阶段升级，不将实验 36ms 当产品值。既有短文和 100k 单长段列新旧成本，精确配置变化与性能取舍分开说明。全高查询仍需全文工作；不据此宣称 GB 规模恒定成本。
- **范围如实保留。** 该接缝解决有确定内容宽度的 multiline 自然高度。`preferredWidth` 无约束完整测量及普通 TEXT 的旧 NSString 路径仍可能昂贵，必须在 ACTIVE/报告标出，不宣称通用全文测量全部解决。先在实际消费中记录是否意外触发这些旧路径；若它们阻塞同一必需链，带实际调用者与尺寸需求升级，不能偷偷替换四指标或改消费者固定尺寸掩盖。

Apple 接口依据：[usedRect 不触发布局](https://developer.apple.com/documentation/uikit/nslayoutmanager/usedrect%28for%3A%29?language=objc)、[显式完成容器布局](https://developer.apple.com/documentation/uikit/nslayoutmanager/ensurelayout%28for%3A%29?language=objc)。以上是指导方案，是否交付以 Sol 的当前源码与原始验证为准。

尾部偶发额外 raster 维持“有一次失败、未定位”记录。保留 refresh/pump 的分段观测；新生产变化触及复用时运行相关反例，重新出现后在 cache miss 处按实际变动的依赖定位。多次绿色不是修复证据，也无需持续盲跑制造更多绿色。

实现收尾后按实际生产变更刷新导出，复验被影响的测量/文字与输入路径并集中报告；标题、模板和已确认普通双窗结果无新影响时沿用。阶段不因普通双窗达标而抹去 auto-height 欠项，也不因该项尚需裁决否定已交付成果。

**后续编辑器验证方向（用户 2026-09-24 确认）。** 独立编辑器用真实文件检验框架，重点区分首屏出现、持续滚动/输入、随机跳转、全文搜索/保存与峰值内存；文件规模、长行/多行、编码及冷热缓存分别记录。GB 文档采用有限视口与按范围取数、增量索引/布局的方案另行设计，不能把整个文件当一个要求立即精确全文高度的普通字段。这里记录后续验收方向，编辑器文件夹和实现仍等待用户另行提供方案。

**指导复核新自然高度普通消费（2026-09-24）。** 指导只读检查 `/private/tmp/cjgui-sol-autoheight-two-window-20260924/consumer/src/main.cj`、依赖实际指向新导出 `/private/tmp/cjgui-sol-autoheight-export-20260924/framework/cjgui`、最终二进制包含新的 natural-height FFI 入口，并从原 `run/resident-client.jsonl`（现保留为 `run-performance-without-final-input/resident-client.jsonl`）的纳秒时序重新计算：28/28 样本 send_start/send_end 均在 A_START/A_END 内，公开请求均 APPLIED，首个重叠另列；27 热样本 A p95=68.946792ms，B send→owner-observed p95=72.008291ms、send→accepted-observed p95=88.995416ms。早/中/晚热样本为 8/9/10，实际送达在 A 段的 1.37–2.36% / 34.45–41.26% / 67.06–73.63%。A 为 3700 行、102490 UTF-16 / 161690 UTF-8，scroll 内的 multiline 没有 fixedHeight/growY 绕过自然高度，每轮宽度与正文确实变化、accepted 精确读回。`BOOT_START→BOOT_END=243.822333ms` 属冷预热，不能把 sample0 当冷启动。owner 仍是 buildUi 观察点，accepted 包含 pump 后检查，均为上界；接受本负载满足 100/150ms，未宣称精确 owner 提交点或 GPU 实际呈现。指导未重跑产品测试。

同轮 `CJGUI_PROBE_COMPLETE all_valid=true` 及 `CLOSE_A ... b_still_open=true connection_alive=true` 成立；最终 `CJGUI_HUMAN_FINAL accepted=false turns=6000`，故整链未通过。指导发现该临时消费者 `LightController.applyUiEvent` 把 `event.text == B-PROD-${expectedSample}` 写入应用接纳条件，正常逐字编辑/删除的中间值将被拒绝。应让目标控件的合法 TEXT_CHANGED 进入 document owner，把最终字符串精确相等留在验收断言；工具弹窗/AX 与事件是否送达、控制器拒绝分别判别。无需重做已有效 28 条性能统计；可用同源码/同负载的有界代表运行验证关闭 A 后同实例 B 连续输入，再保留两组运行的对应关系。既有输入证据可作基线，不顶替该未完成段。失败恢复与 Luna 聚焦/失焦链继续原包，集中交付。

随后 Sol 交回独立聚焦链：`/private/tmp/cjgui-shared-focus-input-20260924/app-launch.log` 与 `driver-actions.log`。指导读取原始日志，PID 27330 的修正启动器实例通过两次聚焦、一次失焦及选区几何，23 个连续 owner 文字事件后 `accepted_exact=true input_token=true passed=true`，窗口自行销毁。输入为定向系统 CGEvent，不标成人工物理输入或 CUA 截图验收。该运行 renderer 指纹由执行方记录为 `b5d0...`、早于自然高度改动，证据只对应其共享绘制/输入路径；新的 auto-height 双窗输入收尾仍按上一段补证，避免用跨实例历史结果覆盖失败。

**代表轮输入补证已闭合（2026-09-24）。** 修正 `LightController.applyUiEvent` 后，正确 nodeId=71 的所有合法 TEXT_CHANGED 均进入文档 owner，最终验收再比较目标全文。相同导出、相同 3700 行 auto-height 负载的代表运行在 `/private/tmp/cjgui-sol-autoheight-two-window-20260924/run/`：1/1 A 工作内的公开 B 写入成立，随后 `CLOSE_A closed=true b_still_open=true connection_alive=true`；精确 PID 29706/独立 bundle/B 窗核对后，系统 CGEvent 点击、全选、逐字键入 B-PROD-1，文档版本 1→9，`HUMAN_FINAL accepted=true`、FINISH。执行方报告 CUA AX 与截图同值、exit0、descriptor_removed；指导本次核对消费者源码和原始 marker，没有重做输入或目视验收。原 28 条/27 热性能分布保存在 `run-performance-without-final-input/`，指导确认数量、重叠条件及三个 p95 不变；本次单样本不充当新分布。旧失败记录保留为已发现的夹具接纳条件缺陷与当次桌面干扰，不作为框架输入回归。此项无需再等待同实例输入，余下边界证据与最终导出由 Sol 集中交付。

**指导核对最终边界与导出（2026-09-24）。** 本次读取当前源码和原始日志，重做只读导出指纹比较，没有重跑产品测试。接受以下有界结果：

- `/private/tmp/cjgui-sol-autoheight-shared-boundary-run.log` 的 ASCII/Unicode 同 prepared、同几何 scene 平面均为 `scene_pixel_diff_bytes=0`；正式断言检查完整字节，Unicode 定点一字节变造得到 `diff_bytes=1 rejected=1`。native 准备边界实测 `reject_status=99 accepted_retained=1 recovery_status=0 recovery_accepted=1`，源码验证的是旧 accepted 对象/纹理保留，以及新候选随后重新准备成功；日志里的 recovery_accepted 不等于已执行窗口 commit/present。空 inset 无文字绘制区域、透明纹理有合法分配。与此前窗口事务/输入证据分别记，不提升为显示器呈现证明。
- 普通窗口 `--natural-height-failure-only` 日志 `/private/tmp/cjgui-sol-autoheight-window-failure-only-final.log` 中 `forced=0 retained=true failed_measure_calls=2 recovered=true`：0 是故障注入调用成功状态；断言覆盖刷新失败、旧 accepted 版本及实际内容不变，下一次刷新接受新内容。完整脚本仍在后续 scope-remap 命令注册处 exit109，故局部通过不代表综合探针通过。
- `/private/tmp/cjgui-sol-autoheight-large-text-final.log`、`...-partial-final.log`、`...-appkit-final.log` 分别记录正式大文字、局部文字投影（含 20 条可见 tile 更新）及 AppKit 文字路径通过。原偶发 tail 额外 raster 尚无首因，继续保留，不由这次通过清零。
- 最终导出 `/private/tmp/cjgui-sol-autoheight-final-export-20260924` 与当前作者树 83 项比对通过（75 identical/8 rewritten），指纹 `fe0544e304b2101240d424500f589c38f280148052a9b26dd9b0158b27c2274d`。`/private/tmp/cjgui-sol-autoheight-final-fingerprint.log` 的四个变造拒绝、两个重写项计入负对照通过。其 `composable_ui.cj`、`runtime_renderer_session.cj`、renderer 分别为 `63ce74db…`、`6c5fd63d…`、`16181ba8…`，与已接受 auto-height 性能导出相同；沿用原分布与代表输入链，不重新称为末次导出的全量桌面重测。

**末次回归接续裁决（执行前）：scope-remap exit109。** 指导源码检查发现一个可直接区分的假设：`ScopeRemapController` 的目标 9406 在 layer `scope-remap-target` 内；`declareCommand` 的声明未传 `focusScopeId`，默认空串，而生产 `commandTargetIsDeclared` 要求 node.inputScopeId 与声明相等。先记录 accepted 目标是否存在、action、inputScope、命令 focusScope 及返回边界，再决定修正。CodeLattice 此次返回 live root `path_denied`，该假设来自源码，未把图查询失败当产品证据。

若确认是探针声明不符合现行作用域契约，给正确声明显式传目标 scope，并保留错误空 scope 被拒绝的反例；继续证明正确作用域的新鲜快捷键能够触发目标、旧场景排队快捷键在作用域重映射后被拒，以及同层 Tab 仍走到正确兄弟。后两条不能因快捷键根本不可用而空过。修正后运行该完整 controller 探针一次；若暴露后续相关夹具/产品问题，沿原验收意图定位，不按退出码换名字收口。若实测并非 scope 不匹配，提供 declareCommand 的具体失败分支和 accepted/native 状态，再作下一方案。跳过新增高度测试仍 exit109，只能排除新增测试自身的运行干扰，不能据此宣称与所有生产改动无关。

Sol 继续负责此项根因及最小修改，Luna 可独立核对作用域正反例和证据口径，统一协调构建。只改探针时保持当前导出；若必须改生产，检查实际受影响契约并刷新对应导出及相关验证。其余已接受成果按对应版本保留，完成后集中报告并对齐 ACTIVE。此项是当前整阶段回归收尾；编辑器与 GB 引擎仍等待用户方案。


### 指导验收结论（2026-09-24，本阶段收口）

**接受本阶段 A–E 在已约定应用负载和明确适用域内完成。** 指导读取生产/探针源码及原始证据，重算前述性能分位数、重新核对最终导出，没有重跑产品测试。聚焦资源与样式绑定、局部文字更新和绘制复用、正常双窗响应、精确内容宽度下的 multiline 自然高度、真实 owner/控件输入与同源预览交付均按前述对应版本验收。此结论不把一般全文测量或 GB 文档性能改名成已完成。

末次 scope-remap 的 RED 记录 `/private/tmp/cjgui-sol-scope-remap-red.log` 显示目标 9406 的 action=`STABLE_SCOPE`、inputScope=`scope-remap-target`，命令声明的 focusScope 为空。生产严格匹配作用域正确拒绝注册，exit109 的具体首因已证明。修正探针显式 scope 后，保留错误空 scope 拒绝，并新增正确快捷键的正向应用检查；生产作用域校验没有放宽。

**最终以 `/private/tmp/cjgui-sol-scope-remap-focused-both.log` 为准**，该完整 controller 脚本由执行方实跑 exit0，指导核对以下同轮原始行与对应断言：

- `REGISTRATION target_declared=true invalid_rejected=true valid_registered=true`。
- scene1 入队前和 scene2 发新键前，分别通过 native 聚焦与队列 focus intent 建立 `focused='scope-remap-stable'`；不是只在新场景补焦点。旧事件 `queued_scene=1 accepted_scene=2 rejected=true`；新 Cmd-K `fresh_status=0 fresh_focused=9406 fresh_applied=true controller_applied=true`；Tab `focused=9407`。这些是受控原生输入队列/窗口控制器证据，未称人工键鼠操作。
- 后续 exit165/82 来自旧探针对重开图片的假设。原应用仍有活跃窗口，native 资源域挂在同一 NSApplication/Metal device 上，命中纹理缓存直接 ready，解码计数仅归实际发起加载的 session。因此重开本夹具得到 `loaded=2 cache_entries=1 decodes=0`、`submitted=1 completed=1` 有源码与实测依据；初次冷会话仍断言 decode=1。新会话有界 pump 后必须仍 submitted/completed=1 且 failure=-1，保留旧代不能推进新代计数的检查，不把计数修改当作修复产品。
- 此次只改 `probe/composable_ui_window_controller_probe.cj` 和其编译脚本（named_style 编译输入及定向参数透传）；指导重新比较产品导出仍是 83 项、`fe0544e304b2101240d424500f589c38f280148052a9b26dd9b0158b27c2274d`，无需重建同内容产品预览。`runtime_state.cj`/`cjpm.toml` 没有改动；git 差异检查与脚本语法检查通过。

本次接续至此结束。无约束 preferredWidth 与普通 TEXT 旧测量的成本、一次 tail 额外 raster 的未定位偶发记录继续保留；新多行自然高度接口为 preview 能力，按其已明确的输入布局语义消费。正常双窗数值为 owner/accepted 的观察上界，分片像素与 native frame completion 不等于显示器物理呈现，工具 CGEvent/AX 不等于人工物理输入。用户拟用独立编辑器检验 GB 文档，尚待方案和新阶段指派；不自动启动编辑器或恢复旧定时任务。
