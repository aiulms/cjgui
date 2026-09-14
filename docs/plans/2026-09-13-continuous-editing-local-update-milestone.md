# 大阶段：连续编辑与局部更新

2026-09-13；指导下发，原执行任务 Terra/xhigh 负责阶段交付，直接调用 Luna/high。原目录，不新建工作目录或分支。

## 交付目标与取舍

开发者使用现有公开文本组件和正常 Host，即可连续输入、选择、滚动，与外部系统接续编辑同一内容。一次局部修改的内容接受、排版失效和可见文字资源准备按明确状态衔接，避免为相同内容与外观重复栅格/上传；需要的中间反馈、正文版本与失败恢复仍正确。这是通用框架更新路径的交付，不给规则集样例添加业务。

前阶段[通用有序合成](2026-09-13-ordered-gpu-composition-milestone.md)按证据范围接受：形状/图片/单多行有序合成、裁剪、可见文字资源、失败重试、合法合批及最终导出已有对应结果。合法7矩形对照只证明提交由7次减为3次、像素相同，CPU同为208us，不说明提速。文字普通/256场景每次单行输入3–4次栅格、多行3次、滚动1次尚未归因；受控失败8/9ms各为一次样本，不能代替持续输入分位数。新的文字纹理路径还需要刷新历史长文本成本基线。

六主线判断：组件布局、资源加载、语义动作和公开消费已有基础；本阶段优先连通文字输入与自绘提交的局部失效，承接100KB尾部/长单段的已知热点。物理系统IME/VoiceOver、实际显示器呈现、多平台仍明确保留，不混入本阶段扩张；输入法仅系统集成。依据[设计导航](DESIGN_INTENT_INDEX.md)及其失效/状态归属教训，仓颉、自绘、窄桥接和模型无关接口不变。

## 复用与旧问题

- 复用 `composable_ui_window.cj` 的 refresh transaction、owner确认与稳定身份，`cjgui_internal_renderer.m` 的唯一活动 TextKit graph、派生 tile、场景 COW 和已有重试；不新建正文或第二套调度真相。
- 复用 `shared_text_document.cj` 的 UTF-8 范围、原子批次、版本与有界撤销；本地/外部修改都仍进入现有领域入口。不为性能跳过权限、CAS、Unicode边界或业务校验。
- 复用 AppKit text/controller/scene probes 的实际输入和 raster/upload/encoder 计数、正式 Host、公开 client、最终导出指纹绑定。先扩展已有观测，不另建审计系统。
- [历史文字布局阶段](2026-09-13-incremental-text-layout-milestone.md)保留100KB尾部约71ms、长单段约77–79ms的旧条件证据。直接改proxy storage、共享第二图、观察器SIGBUS和把成本挪到后续draw的旧失败不重复猜测；旧数值不是当前实现的新基线。不得仅把字体属性写入移出回调便宣称全链路更快。

## 完整实施范围

1. **建立当前生产路径的归因与基线。** 给同一编辑/投影/资源准备关联稳定对象、内容版本、失效原因和实际准备次数，区分文本、选区/光标、样式/宽度/scale/clip、candidate admission、owner确认和失败重试。先说明3–4次栅格中哪些像素相同、哪些反馈必要。诊断为有界test-only标量或临时记录，不把完整正文或逐字符日志常驻生产。输入开始到其正确owner与派生资源/场景接受的总区间单独计时，不能相加嵌套区间，也不把工具等待计入用户输入成本。
2. **实现通用的局部失效与准备复用。** Terra 依据归因确定同一真实内容与外观如何跨本地反馈、owner确认、candidate接受复用派生结果，明确接受前后及重试边界。只合并可丢弃的中间视觉准备，不吞业务操作、改撤销粒度或复用未授权/陈旧内容。相同最终像素状态不重复上传，无关组件更新不重置活动文本；变化确实影响文字时必须更新。不能为减少次数隐藏选区/光标、延迟到失焦才刷新，或取消业务版本检查。缓存键/版本避免无必要的全文重复构造，同时保留完整失效条件。
3. **连续输入和人机交错正确性。** 验同一对象多次输入、选择替换/删除、快速输入后Apply、焦点切换、对象删除/重绑、外部同对象与其他对象修改、拒绝与undo/redo。前轮自动化的陈旧控件拒绝先区分工具对象过期和真实输入遗漏；有效输入不丢，实际陈旧/冲突仍拒绝，不能放宽整个事件版本规则。中文、emoji/组合字符及程序化preedit提交/取消沿系统服务验证，不自研IME。失败保留正确旧资源，后续有界恢复，关闭后不再提交。
4. **长文本持续成本在新路径下接通。** 使用现有10KB/100KB多段与长单段首/中/尾样本，复核正文差异、字体准备、范围布局、候选/选择、栅格、上传和controller成本。先移除证明确属框架的重复工作；若热点仍是TextKit范围扩张，Terra给有区分力的系统路径诊断，保留全局文本/选区/候选映射。需要第二排版图、正文分片所有权或改变公共范围契约时立即升级指导，不静默扩大方案。不能仅重新测出历史限制就结束整个阶段；局部更新能力仍须实现并完成消费。平台残余的无法消除成本有证据后单列，不宣称任意长度/位置常数时间。
5. **资源与调度保持有界。** 沿用8MiB/文字资源、24MiB/已接受scene等已声明限制，不为性能测量反复提高常数。说明临时CPU、candidate/COW和在途GPU不同范围；选择/滚动/外部更新后资源收敛，idle无无谓准备或提交。只有真实需要才引入额外缓存/异步任务，遵守主线程、晚完成、代际和关闭边界。
6. **两个正常消费者与最终产物一起交付。** 文档Host和规则集或另一现有文本Host消费同一框架能力。隔离正常窗口经GUI输入→公开client读回/授权局部修改→同窗继续输入并读回，涵盖单行与多行受影响路径、滚动/resize及正常关闭。程序化probe与GUI操作分开标记；锁屏只挂起依赖桌面的验收，继续独立工作。最后相关公开文档更新、正式导出/生成器消费绑定最终源码与bundle，不继承旧指纹。

## 验收与交付边界

- 当前基线与最终结果用相同数据、窗口、scale、输入路径和冷/热条件；以小普通窗口及既有约256混合场景为主，不增加960矩阵。热点用现有10KB/100KB，预热后每关键相位30有效样本，报告p50/p95/max、事件/版本一致性和实际栅格/上传工作量。基线保留后不无原因重跑。
- 对已确认同像素的重复准备给消除证据，并证明正常输入总时延无回退；不要求为了好看固定“一键一次栅格”。热点改善须超过测量噪声；确实没有收益就撤回复杂优化并升级具体取舍，不能以日志数量代替能力交付。GPU duration/显示器呈现不可得照实写明。
- 相关core/controller/native回归按风险做一次最终集成；`runtime/cjgui`实际包根的1.1.3 build、diff/未跟踪改动空白、公开声明/FFI影响、两正常消费者与最终导出证据。普通测试绿色不代替实际输入/外部接续。必要原始日志、源码指纹和产物身份写入本页，缺项不能标完成。

## Terra与Luna的执行安排

Terra/xhigh先完成原因归属和方案判断，Luna/high可以并行准备既有场景的基线采样、明确的test-only观测及证据归档，写集分开。方案明确后，成块实现/回归可交回Luna；持续涉及owner、事务、TextKit时序或资源生命周期的部分Terra亲自实现。整个阶段一并推进，不逐文件停工。复用可用子代理，默认一个；必要工作允许并行，不为省额度削弱思考/验证，也不让两模型重复做同一套工作。

沿用AGENTS跨模型两次失败→K3、有效讨论失败升级指导的规则，已有环境无响应不当有效建议。Luna有结构疑点提前回Terra；Terra无独立工作时等待完成通知，不反复输出等待说明。Terra集中审衔接后将阶段完成/实质阻塞回报指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。不stage/commit/push/安装发布，不触碰用户既有实例或凭据。
## 本轮来源归因与当前基线（Luna/high，2026-09-13）

本轮只增加 test-only 观测，没有改变生产缓存键、TextKit owner、提交顺序、像素或资源释放。观测在真实成功的 AppKit raster 与 `MTLTexture replaceRegion` 配对点递增；六个有界原因槽为 `unknown`、`static_candidate`、`active_content`、`selection_caret`、`visible_tile_scroll`、`retry`。原因不确定时保留 `unknown`，不从时间或日志猜测。每个槽的 raster/upload 计数必须分别与既有聚合计数相等；末次 projection/content 标量只证明最后一次被准入工作的终端对齐，不是每个事件的版本表。

### TDD 红/绿

- RED：先在 probe 声明并调用 `cjgui_internal_renderer_test_composable_text_work_reason_stats`，尚无 native 实现；`zsh runtime/cjgui/native/scripts/verify_composable_ui_appkit_text.sh --renderer-work-cost` 返回 `1`，原始 `/private/tmp/cjgui-continuous-reason-red.stdout`、`/private/tmp/cjgui-continuous-reason-red.stderr`，stderr 为 `ld64.lld: error: undefined symbol: _cjgui_internal_renderer_test_composable_text_work_reason_stats`。
- GREEN：补上 test-only 计数及事件边界标记后，同一真实窗口/输入路径的 `--renderer-work-cost` 返回 `0`，原始 `/private/tmp/cjgui-continuous-reason-green2.stdout`、`/private/tmp/cjgui-continuous-reason-green2.stderr`。包含 normal=6 与 mixed_256=256 各 30 个 `single_insert`、`multiline_insert`、`multiline_scroll` 样本（共 180 行）；每个样本的 raster/upload bytes 相等，`encoder_max_batch_bytes` 仍不超过 4096，延迟失败→重试的两个 acceptance 均为 `accepted=true`。

### 原因计数与基线

GREEN 末次汇总（raster 与 upload 完全相同）为：

```
normal nodes=6: unknown=90 static_candidate=95 active_content=60 selection_caret=91 visible_tile_scroll=30 retry=1; last_projection=63 last_content_utf8_bytes=414; owner_version=32 owner_content_utf8_bytes=414
mixed_256 nodes=256: unknown=90 static_candidate=111 active_content=60 selection_caret=91 visible_tile_scroll=30 retry=1; last_projection=63 last_content_utf8_bytes=414; owner_version=32 owner_content_utf8_bytes=414
```

`static_candidate` 表示 Cangjie 候选资源准备；mixed 场景还包含 250 个静态文本节点，不能由候选计数反推出节点数。`active_content` 来自真实输入/内容变更边界，`selection_caret` 来自真实选区/光标边界，`visible_tile_scroll` 来自真实多行滚动，`retry` 仅在相同 retry key 且已有失败计数时标记。`unknown` 是当前仍无法严格归因的初始/未标记刷新，不声称它是冗余。`last_projection=63` 与 owner 的 `version=32` 不相等是不同投影计数域，不能互相替代；末次内容 UTF-8 字节数对齐为 414。

按 30 个样本聚合的真实工作量（`/private/tmp/cjgui-continuous-reason-green2.stdout`）：normal 和 mixed_256 的 `multiline_insert` 均为 90 raster/90 upload（每样本 3），`multiline_scroll` 均为 30/30（每样本 1）；`single_insert` 均为 119/119（平均每样本 3.97）。normal 的 `single_insert` 平均输入 mutation 为 980.5us，mixed_256 为 604.2us；这只是本轮当前基线，未作优化结论。

现有长文本入口也按原脚本执行一次：`zsh runtime/cjgui/native/scripts/verify_composable_ui_appkit_text.sh --cost` 返回 `23`，原始 `/private/tmp/cjgui-continuous-reason-cost.stdout`、`/private/tmp/cjgui-continuous-reason-cost.stderr`。在既有后续 cache 断言失败前已经输出并保存：多段 10,250 bytes、102,400 bytes；单段 10,258 bytes、102,419 bytes；连续编辑 102,400 bytes（各 `local_edits=3`，连续项 `owner_edits=3`）。该入口的失败是既有 `hasBoundedMultilineLayoutCache` 返回码 23，不把这次部分输出标为通过，也未为本轮修改该断言。

### 校验与边界

- 当前源码指纹（sha256）：`cjgui_internal_renderer.m` `f9ff64eb53ccc8aa0f7385caa067ef92e377fe6bf94f7bbe2d0143bcaf342e64`；`.h` `3a297ad27b604332c262cfae597de2544be94f4e11935b089d632973a9a67412`；`composable_ui_appkit_text_probe.cj` `21f28d5987388c9ff1f65eebc45a388cc982b1b274434ced7b7e85e0a54bcd4d`；验证脚本 `0d0a43f4f298f75a32fd451e328187585c0d0af1e4ed0edebc2f9e4cb51400dd`。本次 GREEN 生成的 probe `/private/tmp/cjgui-composable-ui-appkit-text/composable_ui_appkit_text_probe` sha256 为 `b4359159ec57394589a00d9e5b9ec64952ad7b89c27d8a32f384d17142db4f7f`。
- `runtime/cjgui` 根目录以 Cangjie 1.1.3 执行 `cjpm build --skip-script` 返回 0；原始 `/private/tmp/cjgui-continuous-cjpm-build.stdout`、`/private/tmp/cjgui-continuous-cjpm-build.stderr`，仅有既存 `chmod` 弃用警告。native renderer 非 testing 编译也返回 0，原始 `/private/tmp/cjgui-continuous-renderer-production.stderr` 仅有既存 `allowedFileTypes` 弃用警告。
- 本轮没有遇到 GPU 生命周期、FFI 契约或 transaction/active TextKit owner 阻塞；没有生产优化，也没有声称已消除任何重复栅格/上传。导出消费和两个正常消费者不属于本轮写集，仍按阶段总验收单独核验。

## 阶段实现与最终验收（Terra/xhigh，2026-09-13）

### 修复范围与边界

- 真实 RED：同一单行 owner 确认额外产生 2 次、978,944 bytes 的 raster/upload（`/private/tmp/cjgui-continuous-owner-ack-red.stdout`）。根因是确认投影在同一活跃身份上携带空值，但 native prepare 先清除了已接受的本地派生纹理，随后活跃 TextKit 再为同一文字重做一次。
- `CjguiComposableTextResourceAcknowledgesActiveLocalInput` 现在只接受同一 node/resource/kind 且 staged value 为空的窄确认包；保留 COW 资源并纳入原有每文字资源8MiB、已接受scene合计24MiB的预算。任何非空外部值仍走正常替换。没有改 owner、CAS、undo、事件版本或公共 ABI。
- 后续场景 RED 表明仅按身份复用会漏掉相对 tile 位移；又验证了圆角 clip 仅变化也必须更新像素。文字资源键现包含相对 tile 偏移与完整 clip 链签名；`verify_composable_scene_renderer.sh` 在这两类红测后通过，不能把复用扩大为忽略几何或裁剪。
- 焦点切换时，旧活动输入现在立即变成无光标的静态派生资源；它是焦点工作，而非下一次另一输入的 owner 确认工作。仍只有一个活动 TextKit graph；inactive cache 的条目/高水位均为 0。没有恢复第二个 TextKit cache。

### 最终受控输入证据

`zsh runtime/cjgui/native/scripts/verify_composable_ui_appkit_text.sh --renderer-work-cost` 返回 0（`/private/tmp/cjgui-continuous-reasons-final.stdout`）。normal=6 与 mixed_256=256 各含 30 个 single_insert、multiline_insert、multiline_scroll 样本，共 180 个操作样本：每个样本均为 1 raster/1 upload；插入后的 owner pump 增量均为 0；scroll 保留自己必要的 1 raster/1 upload。shape batch 上限仍为 4096 bytes，normal 的 texture draws 为 5、mixed_256 为 21。

原因槽在最终运行中 raster/upload 分别完全相等：normal 为 `unknown=0, static_candidate=65, active_content=30, selection_caret=151, visible_tile_scroll=30, retry=1`；mixed_256 为 `unknown=0, static_candidate=81, active_content=30, selection_caret=151, visible_tile_scroll=30, retry=1`。其中 static_candidate 包含启动及 60 次焦点切换的旧输入降级，已在每次输入基线之前结算；它不是 owner ack 的隐藏工作。`unknown=0` 只覆盖这两个受控 workload，不外推为全应用的原因完备性。

受控失败→有界重试仍走现有真实文本准备路径，并在两个 workload 中各得到 `accepted=true`；旧资源在第一次失败时保留，下一主队列续作后才接收新资源。`verify_composable_ui_appkit_text.sh`（普通交互/冲突/组合取消/Apply）、`--cost`、`--steady-cost` 均返回 0；后者为 10KB/100KB、多段/单段、首/中/尾 12 组各 30 个 insert/delete 样本。当前 100KB 的典型值仍揭示平台热点：多段 insert input p50/p95 为 91–97/92–98ms；长单段 start/middle insert 为 176/178ms、171/173ms，tail 为 97/98ms；单段 start/middle delete 仍为 79/80ms、77/78ms。它们是当前测量，不与旧机时数做改善声明，也不称任意长度或位置为常数时间。`--cost` 的连续多段 100KB 3 次编辑为 input 292ms、pump 7ms，且 `inactive_cache_entries=0`、`inactive_cache_high_water=0`。

### 集成、消费者与产物边界

- `verify_composable_scene_renderer.sh`、`verify_composable_ui_window_controller.sh`、普通 AppKit probe、`runtime/cjgui` 中 Cangjie 1.1.3 的 `cjpm build --skip-script` 均在最终源码返回 0，原始输出均位于 `/private/tmp/cjgui-continuous-*-final.{stdout,stderr}`。
- 当前源码启动了隔离 bundle `org.cangjie.cjgui.rule-set.continuous-acceptance`，未触碰用户已安装实例。公开 client 经 `EDIT_DRAFT_TEXT` 获得 `APPLIED true`，GUI 读到 `external-final`；同窗 GUI 自动化键盘（非物理键盘）续写为 `external-final + GUI` 并应用。client 最终读回同一资源的 label 与 `WINDOW_FIELD_VALUE`（UTF-8 hex `65787465726E616C2D66696E616C202B20475549`），并确认 `EDIT_DRAFT_TEXT` / `APPLY_DRAFT` 均在授权范围；保存后经标准关闭按钮正常退出。
- `verify_framework_preview_consumption.sh` 从最终源码导出并在含空格的迁移目录构建 UI Only 与 Collaboration 两个正常消费者，公开 handoff 的空标题被接受、陈旧版本被拒绝、endpoint 正常关闭清理。source/preview payload SHA-256 同为 `89024ebd9c5f8842e7509d4fabe70ac898f24c924fe8d8de664f4fc8b4b12edf`；两个 bundle 指纹见 `/private/tmp/cjgui-continuous-preview-final.stdout`。这证明最终导出消费，不等于安装、签名、公证或发布。

原截图中已安装的 `CJGUISharedOperation` 打不开这一外部实例没有被操作、重装或复测；本阶段不把上述隔离源码/Host 验收表述为它已修复。物理中文 IME、VoiceOver、真实人工呈现、安装包与发布仍未验。

## 指导复核与原阶段接续（2026-09-13）

指导仅抽查源码和原始输出，未重跑测试。受控重复准备消除、相对tile/clip失效和当前导出指纹有对应证据；仓颉端确认包同时要求待确认事件的内容完全相等及仍聚焦同一身份，并非仅按native身份跳过外部修改。以上按范围接受，阶段整体尚需完成以下原有要求；不另开小阶段、不重做已通过矩阵。

1. **正常消费者接续。** 已报规则集窗口和导出模板不替代范围第6项的文档Host多行实窗。先定位已有最终源码的工具证据；不存在就用隔离正常文档入口完成GUI输入、公开client读具体正文、授权修改、同窗续写与读回，包含滚动/resize/关闭。程序化事件、GUI工具键盘、物理键盘和系统IME分别表述。锁屏则明确挂起这一项，继续成本诊断。
2. **完整输入区间与热点解释。** 现有工作量行主要记录mutation/raster/upload，不能直接证明普通输入到owner及正确资源/scene接受的总时延。优先复用已有边界和原始日志，补有界总区间采样，不把嵌套耗时相加。旧基线产物若不再可用，不重造整段历史或虚称同条件分位数；保留已证工作量减少和现有长文本cost成对数据，说明未证的范围。
3. **Terra主导有区分力的诊断与必要实现。** 当前steady日志中100KB多段start的mutation约95ms，而selection约0.6ms、character/bounding ensure各约1ms；因此“全部是范围布局热点”证据不足。先在现有输入调用边界分清NSTextView内部编辑/属性修复、框架fallback与整段属性写入、同步回调、纹理准备，使用有界test-only计时或一次采样栈。检查同一签名下是否重复全文处理；只修证实的框架成本，不通过取消系统属性修复或降级Unicode/候选/选择正确性换速度。现有standalone生命周期不同，只用于提出假设；无同条件证据不宣称系统下限。当前cost基线已有单段start/middle input180/173ms，最终176/170ms，不能误报本轮造成新的170ms回退。
4. **闭环和停止条件。** 原阶段必要正确性验收包含owner确认同时伴随样式/clip/geometry变化及准备失败的接受/重试边界：先查已有覆盖，缺失才补针对性验证，不预判源码有bug。完成两消费者、总区间说明、成本归因及证实问题的必要修复后一次整体回报。若归因只剩平台内部且不能在当前owner/单图路线安全优化，带证据和具体取舍升级指导，不不断换参数重试。Luna负责明确的消费者/观测工作包，Terra负责归因、事务风险和整合；不两人重跑整套检查。

当前缺口集中在文字输入与自绘反馈的真实衔接，组件/布局、资源调度、语义和包消费仍承接已有效证据。本轮不新增业务功能、输入法引擎或治理台账。只在源码发生相关变化时重建对应最终产物；仅补证不反复全套构建。

## 原阶段接续执行记录（Terra/xhigh，2026-09-13）

### 100KB 输入根因、修复和正确性

本轮先补 test-only 的同次编辑边界记录，而非将嵌套时间相加。RED 是仅有声明、未提供 native 实现的 callback-trace C ABI：`--input-callback-trace` 链接失败，原始输出为 `/private/tmp/cjgui-input-callback-trace-red.stdout`。随后在 `CJGUI_INTERNAL_TESTING` 下记录 `super insertText`、临时容器模式切换、text/selection 回调、同步 refresh/preparation、整段属性写和 fallback；默认生产路径不启用该记录。

同一 100KiB 多段起点在修复前的一次受控 trace 为 `input_ms=99`、`total_ms=122`、`mode_change_count=2`、`refresh_us=95041`。两次切换来自 `CJGuiInternalComposableInputProxy.insertText` 在调用 `super` 前临时设置单行/截尾（`maximumNumberOfLines=1`、`NSLineBreakByTruncatingTail`），selection reveal/position 随后才恢复多行 wrap。该切换使同一活动 TextKit graph 发生大范围同步 refresh；并非 owner ack、整段属性写或 fallback 处理。实现仅移除生产输入路径里的这两项临时切换；测试控制仍可显式打开，以便与默认多行路径比较。没有修改文本真相、UTF-8/Unicode、marked text、候选映射、selection、CAS/undo 或公共 ABI。

修复后的同一受控 trace（`/private/tmp/cjgui-input-default-green.stdout`）为：

```
mode=production: input_ms=21 total_ms=26 super_insert_us=4333 mode_change_count=0
  text_callback_count=1 selection_callback_count=1 refresh_us=17417
  whole_attribute_writes=0 fallback_apply_count=1 candidate_mapped=true scroll_mapped=true
  owner_version_delta=1 accepted_build_delta=1 accepted_layout_delta=1 accepted_submit_delta=1
mode=bounded_test_control: input_ms=96 total_ms=102 mode_change_count=2 refresh_us=95500
mode=multiline_test_control: input_ms=17 total_ms=20 mode_change_count=0 refresh_us=17041
```

这是一对同进程、同数据和同 owner 的受控样本，不把它伪称为持续输入的分位数。最终 `--diagnostic`（`/private/tmp/cjgui-input-default-diagnostic-final.stdout`）也得到 `position_changed_mask=0`，tail insert 的 `input_mutation_us=20459`、`selection_us=167`、三次 character ensure 合计 `208us`，candidate/viewport 映射仍通过。

`--cost` 的同轮 100KB 单点结果（`/private/tmp/cjgui-input-default-cost-final.stdout`）显示多段 start/middle/tail input 分别为 17/16/17ms；长单段 start/middle/tail 仍为 175/169/18ms。该残余是长无换行段落的 TextKit 编辑/光标几何路径证据，不是已证明的不可消除平台下限，也不宣称任意长度或位置为常数时间；本阶段不在无第二排版图方案的情况下擅自扩大架构。

`--steady-cost` 原始 stdout 与原生 stderr 串行混写，造成每桶 1--3 行破碎。因此仅对完整行计算中位数，不报伪造的 30 样本或 p95：

| 100KB 数据 | 位置 | 完整样本 n | input p50 | turn p50 | owner p50 | pump p50 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 多段 | start | 29 | 16ms | 19ms | 2ms | 3ms |
| 多段 | middle | 27 | 17ms | 19ms | 1ms | 2ms |
| 多段 | tail | 28 | 17ms | 19ms | 1ms | 2ms |
| 长单段 | start | 27 | 179ms | 182ms | 2ms | 3ms |
| 长单段 | middle | 28 | 171ms | 175ms | 2ms | 3ms |
| 长单段 | tail | 28 | 18ms | 22ms | 2ms | 3ms |

完整行筛选产物为 `/private/tmp/cjgui-input-default-steady-clean.tsv`；原始日志为 `/private/tmp/cjgui-input-default-steady-final.stdout`。`selection_us` 是末次 selection callback，layout trace 可累计多个 callback，二者不能相减归因。

### 失效、重试与受控回归

- 新增直接 scene RED/GREEN：同一活动本地文字、同一 tile、仅文字颜色变化，重投影像素必须从洋红变为绿色；最终 `verify_composable_scene_renderer.sh` 通过（`/private/tmp/cjgui-input-default-scene-final.stdout`）。已有直接验证继续覆盖相对 tile 位移、圆角 clip 改变和准备失败后的接受/重试，不能因 owner local acknowledge 而复用陈旧样式、几何或 clip。
- 正常 AppKit probe、window controller probe、callback trace、`--cost`、`--steady-cost`、`--renderer-work-cost`、scene probe 与 `runtime/cjgui` 的 Cangjie 1.1.3 `cjpm build --skip-script` 均在最终源码返回 0。对应本轮输出均以 `/private/tmp/cjgui-input-default-*-final.stdout` 命名；build 原始输出为 `/private/tmp/cjgui-input-default-cjpm-final.stdout`，仅有已知 `chmod` 弃用警告。
- 最新 `--renderer-work-cost`（`/private/tmp/cjgui-input-default-renderer-work-final.stdout`）在 mixed_256 的闲置帧为 `raster_count=0/upload_count=0`；插入与滚动各仅重栅格、上传一个文字资源，受控 retry 记录一次且最终 `accepted=true`。这是该 workload 的工作量证据，不等于显示器已经呈现。
- 最终生产 sidecar 重新编译返回 0（`/private/tmp/cjgui-input-default-sidecar-final.stdout`，仅既存 `allowedFileTypes` 弃用警告）；随后 `cjpm build --skip-script` 再次返回 0（`/private/tmp/cjgui-input-default-cjpm-final-2.stdout`，仅既存 `chmod` 弃用警告）。本接续源码 SHA-256 为 renderer `55b27a014777ab245b7c7090f1c39a8468d18620fc3824f7175173b0d558c397`、header `f01e29a3249b8b13025a406125ac732b01e814181daf3019aa59cc3e8a67d6b8`、AppKit probe `48784837751feefb0b0dafda1b00cbf04fafc6f6e70d4e73cbfece9586a8cb46`、scene probe `62cc5e01c057a96eb8a1e48313e32b3725506af1931d6b6478be32bbb49c18c2`、验证脚本 `48c3808753e664c78eb2deaec9845b7625ca6a32ee2b1086b187883766fb06bf`。`git diff --check`、脚本语法与本接续文件尾随空白扫描均通过。

### 正常文档 Host 接续

没有接触、重装或复测用户截图中的 `CJGUISharedOperation`。独立临时 Host 位于 `/private/tmp/cjgui-document-host-acceptance.OM7Ona/SharedDocument`，bundle id 为 `org.cangjie.cjgui.document-acceptance`，关闭后 descriptor 已清理且无残留进程。它完成了：同窗 GUI 工具键盘（非物理键盘）输入→公开 `get` 读回→授权 `REPLACE_RANGE`（version 26→27）→同窗继续输入→公开读回 version 33；随后公开多行写入到 version 35，并对窗口执行编辑器滚动和约 980×620→820×560 resize 后正常关闭。原始公开证据为：

- `/private/tmp/cjgui-document-host-acceptance-get-gui.txt`：GUI 后 documentVersion/byteLength/selection 均为 26，且 scene/submission 均为 9；
- `/private/tmp/cjgui-document-host-acceptance-public-write.txt`：`APPLIED=true`、`CONFLICT=false`、26→27；
- `/private/tmp/cjgui-document-host-acceptance-get-final.txt`：同窗续写后 version 33、191 bytes、selection 191，且 accepted/submitted frame 均为 13；
- `/private/tmp/cjgui-document-host-acceptance-get-before-close.txt`：长多行路径的 version 35、1765 bytes，selection 1325，scene/submission 为 17。

保存的 Host 产物不含原始 CUA 截图或被拒绝的中文工具事件。因此 GUI 工具键盘不等同于物理键盘/系统中文 IME；“中文输入被拒绝”和“截图中反向文字观感”均未能从本轮可复查原始物料复现或归因，不能将 ASCII/emoji 的公开读回扩大为中文 IME 或人工视觉像素验收，也不能据此盲改 renderer。物理 IME、VoiceOver、真实人工呈现、安装包、公证与发布仍未验。

### 接续结论

原阶段实现、受控回归、两个正常消费者的框架接续与最终文档记录已完成，现提交指导复核；这不是对用户既有安装实例的修复或发布声明。残余为长单段 start/middle 的有界性能热点，以及上段明确列出的系统输入/人工视觉/安装发布验收边界。


指导接续决定：已只读核对最终renderer/header指纹、生产移除临时模式切换及同进程trace，按实现与受控回归范围接受。上面的“两个正常消费者已完成”仅覆盖其实际执行时的产物；最后输入修复后的导出/正常Host绑定，以及已报告视觉/Unicode疑点仍未闭合，不作为原阶段整体绿色。由[正常窗口显示、输入与缩放一致性阶段](2026-09-13-window-display-input-scale-milestone.md)连同通用比例变化能力一起继续交付。长单段首/中热点明确保留，缺少旧截图不代表异常已排除。指导未重跑开发测试。
