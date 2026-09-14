# 大阶段：通用自绘图元与有序场景合成

2026-09-13，指导下发，Terra/xhigh、原目录。前阶段[框架预览消费](2026-09-13-framework-consumption-preview-milestone.md)按实际证据接受；本轮推进可复用的绘制、分层合成与提交效率，不继续给协作任务板添加业务。

## 目标与取舍

开发者用公开仓颉组件/样式声明一个含文字、图片、半透明背景、圆角面板及重叠浮层的普通窗口，得到顺序正确、裁剪一致的画面；输入仍命中对应组件，外部仍操作真实内容。整个能力可从正常 Host 与导出的本地预览消费，不为每个样例写 native 绘图。

六主线判断：组件布局、资源调度、共同操作和普通包消费已建立实际链路；自绘目前仍主要是矩形/图片的逐次绘制加独立文字覆盖层，复杂重叠与混合缺少共同验收。因此优先推进通用渲染合成，长文本尾部热点与系统交互集成继续明确承接，避免只追最近缺陷。仓颉、自绘/GPU、macOS 与窄平台桥接路线不变，GPUI 仅为参照。

指导源码依据，尚未运行新场景验证：

- `native/cjgui_internal_renderer.m` 的 `CjguiEncodeComposableNodes` 逐节点提交矩形、图片及四条边框；矩形 pipeline 没有像图片 pipeline 那样显式配置混合。先验证半透明重叠，不仅看最终 alpha 字段。
- 同文件 `CJGuiInternalComposableSceneOverlay.drawRect` 在独立 AppKit 子视图中遍历文字、选区和光标；Metal 先绘制其余节点。这种拆分需要证明较后图片/面板能正确遮挡较前文字，以及半透明覆盖能正确合成。源码结构提示风险，不能代替真实失败复现。
- `CjguiComposableUiStyle` 已有 RGBA、边框、布局与字体，尚无通用圆角表达；裁剪、命中和语义由既有 resolved scene 派生。不能为了新外观再造一棵布局树。

复用[设计导航](DESIGN_INTENT_INDEX.md)的自绘、样式资源、输入及平台边界资产；相关避坑见[渲染与失效](../research/gui-framework-pitfalls-intelligence.md#2-rendering--invalidation)、[状态归属](../research/gui-framework-pitfalls-intelligence.md#3-layout--state-ownership)。复用 `composable_ui.cj`、`composable_ui_window.cj`、`runtime_renderer_session.cj`、当前 COW 场景事务、资源准备/缓存、通用 Host、导出/生成器及既有图像像素探针。旧 opening 禁令与 Bool 审计链不恢复；旧文本双图实验不照搬。

## 完整实施范围

1. **先建立生产路径的混合与遮挡对照，再实现。** 用很小的确定性场景覆盖不透明/半透明矩形重叠、透明图片与背景、文字被后置图片/面板部分覆盖、浮层上文字、滚动区域裁剪。用真实渲染结果区分混合错误、绘制顺序错误与裁剪错误；保留旧路径和新路径可对应的证据。普通窗口的输入/焦点层级也须对应，不把“隐藏整块底层文字”当成部分透明合成。
2. **补齐可复用绘制表达。** 在现有实验公开样式和场景中增加必要的圆角矩形/边框及明确的裁剪表达，让 RGBA 背景、边框、图片的混合约定一致，处理零尺寸、大半径、边框夹角、Retina 边缘。圆角装饰和裁剪子内容是不同语义，应明确选择而非暗中混用；本阶段包括可消费的圆角面板及其图片/文字裁剪。公共层只传值，不暴露 Metal/AppKit 对象。无需引入任意矢量路径、SVG 解析、模糊阴影、渐变编辑器或动画系统来完成本阶段。
3. **让同一场景的绘制顺序覆盖文字、图片与形状。** 以已接受场景的顺序和裁剪为依据，解决“文字统一最后画”的跨类型重叠边界。执行可在当前 native 组织内选择有序绘制段或有界文字栅格资源等方案，但必须覆盖半透明叠层，不能靠全局按纹理排序破坏 painter order、盖住整片文字或只支持不透明浮层。复用系统 TextKit 的 shaping/排版与现有输入代理，不自研文字引擎，不把整窗改回原生控件或 AppKit 背景绘制。若使用文字缓存，键包含实际文本/字体/几何/scale/选区与组合等相关状态，明确失效、预算、活动资源与关闭回收；不每帧整窗栅格化，不创建第二个可写正文或第二张共享 TextKit layout graph。
4. **保持视觉、输入与更新的一致性。** 同一 resolved bounds/clip 服务 GPU、文字、命中、焦点与 AX。显式裁剪之外不能点中被裁掉的内容；装饰圆角本身不擅自改变业务权限。浮层输入作用域、焦点恢复、文本选区/光标、组合输入代理与外部改写仍走现有 owner/事务。新绘制资源创建失败、提交失败、resize/scale 变化与关闭晚完成按现有事务和生命周期处理，不能发布半新场景或成功语义配旧输入映射。系统 IME 仅集成，相关行为回归不扩张为自研输入法。
5. **把逐图元提交成本收敛为可测的通用路径。** 对相邻且兼容的绘制命令合批/复用 buffer 或采用等效方案，保持裁剪、混合与顺序边界。不以全部重排为代价减少 draw call，也不每帧重建 GPU pipeline。用改动前后的相同普通场景证明工作量变化，同时测实际 CPU 提交、可得的 GPU 时间、输入更新与 idle；局部更新/无变化不能退化成全窗重复创建文字/纹理。不能只报 draw call 下降便宣称端到端提速。若量测表明某项合批无益，保留数据并在此页说明实现取舍，不引入无收益复杂度。
6. **普通消费与交付一起完成。** 用至少两个现有正常 Host 消费不同布局与内容：一个无外部连接的组件/图像/叠层窗口，一个带文本编辑和公开共同操作的窗口。复用已有模板或样例，应用只声明业务和样式；不造另一个演示专用 renderer。最终从清单化预览用正式生成器创建消费应用，必要公开源/native/资源随清单导出，正常构建与启动。相关 README 中过时的文字始终覆盖层、同步图片失败即拒绝和应用手工 pump 教学，按最终实际入口更新；不通仓重写文档。

## 执行交付（2026-09-13）

以下为执行首轮交付；指导复核后整体仍在实施，剩余项见后文接续。`CjguiComposableUiStyle` 增加公开值语义的 `cornerRadius` 与
`clipsContent`，resolved scene 将本节点装饰半径和子内容 clip 分开传给 native；形状、图片、
单行静态文字、按钮及单行输入状态按已接受 scene 的原顺序合成。单行文本由 AppKit shaping 后形成
节点持有的 Metal 纹理，活动字段的文本、选区、光标和 marked range 只派生自唯一 `inputProxy`；多行
仍由原 TextKit layout graph 绘制可见 viewport。文字纹理无跨场景全局缓存，随最多 1,024 个已接受/COW
节点生命周期释放；图片缓存维持 8 项、32 MiB、4 个 in-flight 和 16 个 pending 的既有边界。

形状 pipeline 已采用 source-alpha / one-minus-source-alpha 混合；连续兼容形状在不跨越图片或文字纹理
的前提下合批。生产 drawable 像素探针覆盖半透明矩形、透明图片、后置形状遮挡静态及活动文字、后置图片
遮挡文字、圆角边框和嵌套 clip。圆角 clip 也进入命中、滚动和多行 TextKit 裁剪；新增回归先证明透明圆角
仍会误命中，再确认角落拒绝、内部命中。所有处理保留同一场景/输入 owner，不暴露 Metal/AppKit 对象给公共
仓颉 API。

当前源码指纹 `90c48badb066e804069f98bc5549f7e962232ef7f2c551045e795841617007da` 的规模报告覆盖
32、256、960 节点和 local-color、增删、重排、图片替换、resize 五种操作各 30 次，15 组 idle 都是零
重建/零提交，15 组强制失败恢复均保留旧场景并恢复。256 节点混合场景包含形状、图片和文字；其 local-color
commit p50/p95 为 542/667 us，image-replace 为 208/250 us；重排和 resize 仍分别复制 254 节点，不能称
稀疏更新。960 节点 local-color 与 image-replace p50 各复制 1 个节点，重排/resize 各 958；所有
configure、setter、commit 与 Cangjie wall-time 指标相互独立，未相加伪称端到端时延。产物位于
`/private/tmp/cjgui-ordered-composition-scale/`，包含二进制、raw log 和 source/binary SHA-256。

普通消费方面，隔离生成的 UI-only Host 实窗已输入 `ordered note` 并触发按钮，AX 状态读回为
“已点击 3 次；注释：ordered note”；截图确认圆角面板、图片、浮层、字段和按钮同窗显示，随后正常关闭。
正式 `verify_framework_preview_consumption.sh` 从清空 native override 的导出源码、迁移到含空格目录后重建
UI-only 与 collaboration 两个模板；协作模板通过公开空标题写入、陈旧版本拒绝和 Host normal-close endpoint
回收。此项不声称物理中文 IME、VoiceOver、最终显示器呈现、安装/公证/发布或稳定 ABI 已验。

本轮针对性命令均通过：`verify_composable_scene_renderer.sh`、
`verify_composable_ui_layout.sh`、`verify_framework_preview_consumption.sh` 和 1.1.3
`cjpm build --skip-script`。前两个 native 构建仍显示既有 `allowedFileTypes` deprecation；Cangjie 构建还显示
既有 `chmod` 及 probe unused 警告，本阶段没有将其伪装为已修复。

## 指导复核与同阶段接续（2026-09-13）

指导抽查实际源码与规模原始日志，未运行构建、测试或窗口。接受上述单行、图元和预览证据所覆盖的范围；以下是原定能力中的缺口及新实现带来的边界，不另开补丁阶段，不扩张输入法或长文本排版研究。

1. **多行有序合成尚未接通。** native 的 `CjguiComposableNodeUsesGpuText`（1146–1151 行）排除 multiline，overlay 的 `drawRect`（3126–3133 行）仍最后绘制它。复用当前唯一 TextKit graph 的可见 glyph/selection/caret 输出，将多行纳入同一场景顺序；可用可见视口派生纹理/有序绘制段，但不能再建排版图、遮掉整个文字框或把 glyph 不出现误作遮挡成功。先复现多行文字被后置不透明/半透明形状和图片覆盖，再验证滚动、选区、光标、外部改写与浮层的正确更新。保持全局文本范围和候选几何来自同一图，不为了本轮追求解决历史 100KB 尾部排版热点。
2. **圆角裁剪需保留原始形状与全部祖先约束。** `composable_ui.cj:1129–1143` 先把父矩形与子 bounds 相交，再附上父半径；进入下一个 clipsContent 时又换成子半径。矩形相交后附半径不等于原始圆角的交集：完全位于父中心的矩形子节点可能被额外切角，位于祖先圆角内的下级方形 clip 又可能丢掉祖先限制。先用这两个普通嵌套布局复现。采用有界、只读的原始 clip 几何链或等效准确表示，从同一 resolved scene 给 GPU、文字和命中/滚动；可在能证明等价时折叠矩形约束，不用简单 min/max 半径替代空间关系。覆盖祖先角、中心子节点、不同偏移/半径与滚动后的对应点。
3. **新增文字纹理需要可见范围、预算和失败安全。** `CjguiRasterComposableTextTexture`（1173–1177 行）直接按完整节点 width×height×scale 创建两份 CPU 位图与 GPU 纹理；仅完全裁掉时跳过，不构成字节或单纹理尺寸预算。对尺寸乘法/设备尺寸和分配做边界处理，文字栅格工作量按实际可见范围或有界块控制，并说明可见/活动/COW/in-flight 与临时 CPU 内存。应在普通长标签滚动和高 scale 窗口中验证，不制造 OOM。`CjguiComposableTextTexture`（1271 行）先覆盖原 texture；提交前 prepare 会遍历共享 COW 节点（5001 行），活动刷新（3101 行）又忽略失败。候选资源准备与接受分开，失败保留对应旧纹理/场景及准确 pending/error，不能 nil 掉已接受资源仍继续成功。用注入单次分配/prepare 失败证明旧画面和输入保留、重试恢复、移除/关闭释放；不能用一次普通 present 失败替代该路径。
4. **性能和实际消费随上述功能一次收口。** 当前 15×30 报告证明场景复制、提交与 idle/恢复范围，但没有取代原定的合批前后 draw/pipeline/上传、文字栅格和资源成本对照。优先保留一个小正常场景与 256 混合场景，覆盖静态、活动单行/多行、局部改值和滚动，记录实际 draw、上传/栅格字节、CPU 提交、可得的 GPU 时间、输入接续及 idle。同条件基线若确实无保留则明确缺失，允许针对相邻形状合批用同一生产路径的对照开关，不伪造旧端到端基线；不继续追加 960 规模矩阵以替代缺项。最终正常 Host 同时验多行叠层、人→外部→人、裁剪和关闭，受影响导出预览与文档统一更新。

下一阶段暂不启动；完成本轮原范围或遇到实质方案阻塞及时回报。两次同一场景实际修复失败按既定 K3 规则，次数不因本次复核清零；条件未触发则正常实现，不额外增加咨询闸门。

### 接续调试记录（2026-09-13）

- 用独立临时目录编译同一 `composable_scene_probe`，直接 TTY 运行正常场景在 0.728 秒内以 0 退出；此前非 TTY 调用残留的 shell/probe 观测不能作为 native 死锁证据。
- 活动多行场景已改为复用唯一 `inputProxy` 的 TextKit 图，以离屏纹理参加 scene 顺序；真实像素断言仍失败：模型值为一个 `█`，glyph range 为 `0:1`，TextKit content/visible rect 为 `{7,6 186x128}`，字体为 96pt 洋红色，但离屏位图只有右下角光标范围（约 `380,236–383,263`），预期字形内点仍是底色。静态多行纹理路径不出现这个现象。
- 已撤回颜色/alpha 兜底，不能把“没有字形像素”伪装成后置节点遮挡成功。先后检验的两项实际修复假设均未改变该失败：离屏 `NSGraphicsContext` 的保存/恢复顺序，以及临时令 `inputProxy.alphaValue = 1`；后者已撤回。依 K3 规则暂停第三项生产渲染假设，待指导复核该最小复现。
- 当时资源 prepare 的 COW/失败注入回归尚未接入 probe main；后续执行结果见下一节。完整节点尺寸分配仍未满足可见范围/有界块要求，256 节点性能、Host 人机外部闭环和导出预览复验亦尚未开始。

### 同图字体回退与安全 prepare（2026-09-13）

- 上述 `█` 失败不是离屏 CGContext、CTM 或 clip 丢失：目标 bitmap 与 current CGContext 相同，glyph 设备范围与 clip 相交；但 `.AppleSystemUIFont` 对 `█`、`中` 和 `🙂` 给出 `glyph=0/property=1`。`CTFontCreateForString` 同时给出 Helvetica Neue、PingFang UI 和 Apple Color Emoji 候选，证明系统服务存在可绘字形而原 TextKit 属性没有采用它。
- 现有唯一 `inputProxy.textStorage` 在编辑事务返回后的安全主线程 prepare 中，按**组合字符**写入系统候选字体 run；`A中🙂B` 的 run 为 system/PingFang/AppleColorEmoji/system，`👩‍💻` 为一个 AppleColorEmoji run，布局中首 glyph 可绘、其余 UTF-16 续单元按 TextKit 规则标为 not-shown。选择、真实 insert、画面纹理与后置形状遮挡在该同图路径通过；没有硬编码字体清单或新正文/layout graph。
- 生产 `textDidChange` 不再同步 setAttributes/layout/raster：它记录局部替换范围并投递安全主线程 prepare。连续编辑先将既有 dirty range 映射到新 UTF-16 坐标，再在新 storage 上扩展左右组合字符；零长删除也覆盖两侧，`👩‍💻` 整簇替换/删除有针对性回归。基础字体来自 resolved node/style，不能由当前选区的 fallback run 反向决定；字号/样式或外部整体替换仍标记全值。系统 attribute fixing/整段属性覆盖的时序对照尚未单列试验，不把候选字体存在夸大为更广泛根因结论。
- 文字栅格现在以 resolved node∩clip 的逻辑矩形为 tile：缓存键包含 tile/scale，位图仍按原节点宽度排版后平移进 tile，避免裁剪移动造成换行或选区重排。单节点、场景总量和 CPU 位图尺寸均继续经过 checked byte budget；活动多行替换也纳入同一场景预算。`composable_scene_probe` 用 3000×3000 逻辑文本配 200×140 clip 验证旧全节点路径本会越界/超预算而新路径成功，test-only 标量记录的资源矩形/字节仅为可见 tile 且实际字形像素位置不变。
- 已将候选 scene 与活动多行的资源失败都接入 `composable_scene_probe`：候选 prepare 失败保留已接受 scene/input，重试恢复；活动纹理单次失败保留旧 tile，测试标量显示 pending/一次有界 retry，并在没有新输入的下一 main-loop turn 恢复。直接 TTY 编译/运行通过。
- 文字 tile 的单节点上限保持 4 MiB。合计 12 MiB 的首次 256 节点 resize 矩阵在第 8 个有效样本失败，未把这个局部失败隐藏为成功；调整为 24 MiB 后，以同一 32/256/960 节点、local-color/component-add-remove/reorder/image-replace/resize、每组 30 样本完整重跑。报告 `runner_exit=0`、15 组均有 30 样本、15 组 idle 均零 build/layout/clone/allocation/submit、15 组强制失败均保留旧 scene 并恢复。256 混合场景 local-color commit p50/p95 为 542/708 us、image-replace 为 291/334 us、resize 为 11125/13792 us；`metal_gpu_us` 不可得，未将 CPU 区间称为 GPU 或端到端时间。证据在 `/private/tmp/cjgui-scene-submission-scale-evidence/`。
- `verify_composable_scene_renderer.sh` 在本轮 native 修改后通过，涵盖跨类型像素、CJK/emoji/ZWJ、可见 tile、活动失败保留/自动恢复；`verify_composable_ui_window_controller.sh` 以 1.1.3 构建实际 Cangjie Host，并经生产 FIFO 验证文字 intent 先于 Apply intent 到达 controller；`verify_composable_ui_appkit_text.sh` 也在本轮 native 修改后通过，走生产 NSTextView delegate（其固定脚本工具链为 1.1.0）。根项目 `cjpm build --skip-script` 通过（调用环境为 1.1.0）；导出预览验收以 1.1.3 运行，UI-only 和 collaboration 模板在清空 native override、迁移到含空格目录后均构建，协作模板实际完成公开空标题、陈旧版本拒绝和 normal-close endpoint 清理。它们不是物理中文 IME、VoiceOver、人工显示器呈现、安装或发布验证。

### 第二轮指导复核（2026-09-13）

指导只读抽查源码和 `/private/tmp/cjgui-scene-submission-scale-evidence/scene_submission_scale.raw.log`，未运行测试或操纵窗口。接受可见 tile、局部字体准备、候选/活动失败恢复的已报告范围，整体继续实施。源码和当前证据仍有以下原范围缺口，集中完成，不另开小补丁阶段：

1. **普通大视口仍会被预算拒绝。** 当前一个节点仍只持有一个 tile，`CjguiCheckedComposableTextTextureBytes` 将整个 node∩clip 限为 4 MiB；1000×400pt、2x 的完整可见编辑区域需要 6,400,000 字节，仍会失败。3000×3000 节点配 200×140 clip 的通过仅证明小视口裁剪。先验证普通窗口 resize 复现，再选择同图的有界分块或有证据的预算方案，允许普通大编辑区域；保留明确设备/总量边界，不只为通过一次规模测试不断加大常数。说明 accepted、candidate/COW、临时位图和在途资源的不同内存范围。
2. **纹理键与资源失败须覆盖全部新路径。** 静态键记录绝对 tile 矩形，但栅格使用 tile 相对 node 的偏移：固定祖先 clip、节点在其下移动而 tile 绝对矩形不变时，需验证缓存是否错用旧像素。活动多行还在栅格时应用原始圆角链，需检查 clip 形状改变但交集矩形不变时的失效。按实际像素依赖修键或调整裁剪归属，不无条件全部失效。活动单行仍直接调用纹理函数并忽略 nil，未采用多行的合计预算/有界重试；补同类失败与恢复边界。保留同一真实输入 owner 和场景事务。
3. **补原定性能证据，停止用规模矩阵替代。** 当前原始样本只有 clone/allocation、configure/setter/commit、提交帧/已完成帧和不可得的 GPU 时间，没有 draw/pipeline、上传/栅格字节及普通输入至延后 prepare/场景完成。用小正常窗口与约 256 混合场景补这些指标，包含活动单行/多行、局部改值、滚动和 idle；合批用同条件生产路径对照即可，不要求追造旧实现。GPU 时间不可得可以保留，CPU 与实际工作量不可省略。已有完整规模结果保留，除相关变更使之失效外不重复 960 全矩阵。
4. **完成最终正式入口验证并纠正版本标签。** controller FIFO 测试是程序化输入顺序证据，不是原定正常 Host 实际输入、叠层、裁剪、滚动/resize、人→公开外部→人回显与正常关闭。在两个隔离正常 Host 上验受影响能力，再对应最终导出；锁屏则标记桌面未验，先做独立工作。当前根 build 报告明确为 1.1.0，不能在 ACTIVE 写成 1.1.3 项目构建；执行补正式目标工具链的相关构建并保留实际路径/版本，已有效的 1.1.3 controller/导出证据不抹掉。中文/emoji 的 owner 字符串读回和 selection 通过也应与字形像素断言分别标记。

完成上述完整交付再报告，或在实质阻塞时升级指导。系统属性修复时序尚未单独对照的事实保留；不为补齐研究无限扩张字体/输入法范围，不要求本阶段解决历史长文本尾部热点。

## 验收与停止边界

- 最小像素证据覆盖已复现的半透明合成、跨类型遮挡、圆角/边框、嵌套裁剪及图片与文字边缘。选稳定内点和允许误差的边缘，不能用整窗截图哈希消灭系统字体差异；测试侧 fixture 允许确定性生成，生产不得硬编码验收色块。Metal readback 若不含最终文字合成层，不能独自证明完整窗口，要另有实际最终路径对应的视觉证据。
- 正常窗口实测叠层打开/关闭、滚动与 resize、文本输入/选择/光标、公开授权改写后的实际值与画面、旧版本拒绝；保留 UI-only 无外部连接能力。物理 IME/VoiceOver 和显示器呈现按实测分别标记，不因组合/AX probe 通过就补绿。
- 性能至少保留小型普通窗口与一个约 256 节点混合场景，修改前后相同数据/窗口/scale，多次有效样本给 p50/p95/max、draw/pipeline/上传工作量、缓存/活动资源与 idle 收敛。已有 960 节点压力只在改动或失败需要时复用，不发明更多规模阶梯；若超出既有容量须说明，不偷偷缩小测试。采样从真实输入或 owner 修改到实际场景接受，异步时间不能藏到测量窗外。无证据不声称 GPUI 同级或稳定帧率。
- 按 AGENTS 检查公共 API/native/FFI/渲染提交影响、有关的 controller/core 与 native 回归、1.1.3 `cjpm build --skip-script`、最终受影响 bundle/导出消费及 diff/文档链接。代码图不可访问时用源码链路与构建补证；不用旧索引或未知项无限阻塞。
- 整个绘制表达、合成正确性、成本与普通消费完成后再报告阶段交付。若跨层方案暴露影响正文/输入所有权的实质新风险，立即带方案和复现升级指导，继续独立工作，不自行换路线。必要旧问题仅阻塞依赖项；长文本尾部、全部系统集成、多平台、稳定 ABI、安装发布不要求在本轮清零。

原执行任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`，gpt-5.6-terra/xhigh、原目录。可复用既有独立消费者任务做最终公开消费，写集隔离；不要重复新建任务。两次实际修复失败与 K3 升级按 AGENTS；已知 CLI 无响应不算有效咨询或代码失败。锁屏先跳过桌面验证继续代码/无桌面工作，不解锁或改变系统设置；保护用户 RuleSet，使用隔离实例和临时数据。不 worktree、不切分支、不 stage/commit/push/发布。

完成或实质阻塞主动报告指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。下一候选保留长文本持续热点或系统输入/无障碍接入，结合本阶段真实消费结果选择；不预定更多渲染压力小阶段。

### 第二轮执行结果（2026-09-13）

- **普通视口与内存界限。** 先新增 1100×500 正常 AppKit 窗口中的 1000×400pt 静态编辑区域回归：旧 4 MiB 单 tile 上限使 `ordinary_large_visible_editor_is_admitted` 失败；2x 位图实际为 6,400,000 字节。将单节点上限定为 8 MiB、保持已接受 scene 总量 24 MiB 后通过。这个限制覆盖单次 CPU BGRA 位图和节点持有的 GPU 纹理；候选/COW 只在 prepare 成功后替换，活动派生纹理在总预算内替换，关闭/替换释放。它不是对任意尺寸的承诺。
- **失效与失败安全。** 固定祖先 clip、节点移动而绝对 tile 相同的静态像素回归先显示旧字形；键补入 tile 相对 node 偏移后恢复正确像素。活动多行的相同位移以及“交集矩形相同、radius 70→0”的角落字形回归均通过；后者验证的是接受投影后的实际重派生，而非无条件全局失效。活动单行失败注入先证明它没有消费失败 seam；现与多行共享 24 MiB admission、旧纹理保留和下一 main-loop turn 至多一次 retry，注入后在无新输入时恢复。所有这些仍只派生自唯一 `inputProxy`/TextKit 图。
- **实际工作量（本机 2x，30 个有效样本/相位）。** 新 test-only 标量把离屏 AppKit 位图+归一化记为 raster，把随后 `replaceRegion` 记为 upload，二者不相加为端到端时间，也不等同 GPU duration。普通 6 节点与 root、两多行、单行、布尔、按钮及 250 静态文字组成的 256 节点混合 Host，都走生产 NSTextView delegate、Cangjie controller 和延后 prepare。256 节点单行 insert 的 raster p50/p95=2751/3125us、upload=249/291us；多行 insert=2957/3208us、250/334us；多行 scroll=1166/1291us、125/167us。每一相位的 raster/upload 字节和计数匹配；两个 Host 的最终 `refreshIfNeeded` 均为零增量。GPU 时间不可得；没有旧实现的同条件端到端基线，故未伪造比较。原始 stdout/stderr 分离保存于 `/private/tmp/cjgui-render-work-cost.stdout` 和 `.stderr`。
- **正式入口与版本证据。** `verify_composable_ui_appkit_text.sh` 以隔离正常窗口走实际 NSTextView 输入、选择、组合取消、多行滚动、resize、域 owner 的外部替换及拒绝关闭后续写；`verify_composable_ui_window_controller.sh` 以 1.1.3 通过 controller 事务/回读。清空 native override 的 1.1.3 `verify_framework_preview_consumption.sh` 在迁移到含空格的临时目录后构建 UI-only 和 collaboration 两个独立 bundle；collaboration 公共客户端动态发现 `SET_TITLE`，验证写入、清空、旧版本冲突和另一独立正常关闭的 endpoint 清理。它们分别证明正常输入 owner 与公开协议/关闭；本轮没有把它们误报为同一进程中的“真人输入→公开 client→真人续写”观测。`runtime/cjgui`（实际包根）以 Cangjie Project Manager 1.1.3 执行 `cjpm build --skip-script` 成功；仓库顶层没有 `cjpm.toml`，不再把它称为根包构建。
- **完成范围和未验项。** `verify_composable_scene_renderer.sh`、两个正常窗口 probe、256 工作量 probe、1.1.3 包构建和最终导出预览均在本轮修改后通过。物理中文 IME、VoiceOver、真实人工显示器呈现、安装/公证/发布、GPU duration 以及同一公开协作 Host 的真人续写观察仍是明确未验项；不以程序化组合、AX、像素读回或公开 socket 单独补绿。

### 指导接受范围与最后接续

指导只读抽查新源码、`CJGUI_RENDER_WORK_SAMPLE` 原始输出及 `exerciseRendererWorkCost`。接受普通大区域的已声明 8 MiB/节点方案、相对位移键和单行恢复的当前验证范围，不要求为任意尺寸继续提高预算。8 MiB、24 MiB 分别是资源/已接受场景界限，不是整个进程、候选与在途 GPU 资源峰值承诺。

- 新的实际风险在 `CjguiEncodeComposableNodes` 的 `flushShapeBatch`：整个连续批次直接调用 `setVertexBytes:length:atIndex:`，只有遇到纹理或结束才 flush，没有字节阈值。Apple [接口说明](https://developer.apple.com/documentation/metal/mtlrendercommandencoder/setvertexbytes(_:length:index:))要求超过 4 KB 使用 MTLBuffer。先记录真实 sizeof/连续批次长度，在隔离小场景用验证层和实际像素复现；按容量正确分批或使用有明确在途生命周期的 buffer，保持 painter order，不把 mixed_256 每个文字节点都 flush 的通过当长形状批次已验。此项与原合批能力同属本阶段。
- 复用已有 encoder stats 与工作量 probe，补有边界的同条件合批对照、实际 draw/顶点上传及 CPU 编码区间。现有文字 raster/upload 标量保留。补从输入动作开始到其延后 prepare 和对应场景接受的单调时钟总区间、目标版本/内容和资源 pending 状态；不能把 input_mutation_us 与若干可能嵌套区间相加，也不能仅 pump 返回就假定未来异步准备已完成。GPU/显示器时间不可得照实保留。用小窗口与现有约256场景即可，不扩规模矩阵，不要求本轮优化每次输入观察到的3–4次栅格，但把它作为下一阶段是否存在重复工作的证据。
- 同一个隔离、正常启动的公开协作 Host，执行 AI 经 GUI 点击/键入具体内容，公开 client 发现并读回该字段、授权改写，再在同一窗口观察实际字段并继续键入，公开读回最终内容，最后正常关闭。使用现有正常模板/应用与工具，不测试钩子写入或直接调用 owner 代替 GUI 输入；不要求用户亲自操作，不将工具驱动 GUI 称为真人物理 IME。原定 UI-only 正常消费保留。锁屏/工具不可用记具体阻塞，继续上述独立工作。

这三项集中完成或实质受阻时报告；已有已验项不重复整套跑。当前大阶段仍是通用有序合成，不启动输入法研究或样例功能扩张。

### 第三轮集中补齐结果（2026-09-13）

- **4 KB 顶点上传边界，先红后绿。** `composable_scene_probe` 新增 7 个不被纹理边界打断的连续矩形。修复前，它记录 `nodes=7 batches=1 total_vertex_bytes=7392`，因此真实生产调用会把 7,392 B 交给一次 `setVertexBytes`，超过 Apple 对该接口的 4 KB 限制。`CjguiEncodeComposableNodes` 现依实际 `CJGuiInternalMetalVertex` stride 计算每批可容纳的完整 6 顶点矩形，并在同一 painter order 内分批；不借此创建有生命周期负担的保留 `MTLBuffer`。修复后的 Metal readback 绿例为 `vertex_stride=176 total_vertex_bytes=7392 max_batch_vertex_bytes=3168 set_vertex_bytes_limit=4096`，同时断言多批、单批不超过 4 KB 和末尾像素正确。
- **同条件编码工作量与总接受时钟。** `--renderer-work-cost` 在真实 `NSTextView` delegate、Cangjie controller 和生产 scene 提交上跑普通 6 节点与混合 256 节点各 30 个单行插入、多行插入和多行滚动样本。每次提交的纹理 draw 分别是 5 与 21；这两个文字工作负载的形状节点/批次/顶点字节均为 0，故不能把它们冒充为形状合批对照，4 KB 合批由上项专用形状像素 probe 覆盖。测试标量记录 encoder CPU 区间（只包住 `CjguiEncodeComposableNodes`，不含 GPU/显示器）：普通 p50/p95=0/42us、256 混合 p50/p95=41/42us，已体现微秒时钟量化。受控的第一次文字资源准备失败后，从真实 `NSTextView` 插入开始，到精确 target UTF-8 值、owner `target_version=32`、已提交 scene、资源 retry 状态清零且 `pending=none`，普通/混合分别为 8ms/9ms、2 turns；并没有把嵌套的 mutation/raster/upload 区间相加，也没有把 pump 返回单独当作接受。两者的最终 idle 均为零 raster/upload 增量。
- **下一阶段的重复栅格观察。** 单行插入实际为 3 或 4 次 raster/upload，多行插入为 3 次，滚动为 1 次；当前 probe 只计数，尚未逐次归因。代码层已记录下一步排序候选：`inputProxy` 的文本/选区/光标改变进入 active texture key，scene candidate admission 调用 `CjguiPrepareComposableTextResources`，滚动改变可见 tile 矩形，受控失败会触发一次延后 retry。应在下一阶段逐项打点后再优化，不能仅凭这些计数删除必要的 owner/scene 边界。
- **同一隔离公开 Host 的完整接续。** 未触碰用户已有 `CJGUI 规则集编辑器`；另起正常 `CJGUIRuleSet113Isolation` 后，经 GUI 创建记录并键入 `新规则 1P`。公开 `SharedOperationClient` 从该 Host 的 `connection.cjgui` 动态发现目标，读回 label 后以其 `expectedDraftVersion=1` 写入 `external-public`。同窗 AX 随即显示该值；经 GUI 再次聚焦并键入 `Q`，公开读回为 `external-publicQ`、`draftVersion=3`、`accepted/submitted/overlay=5` 与 `pending=none`。随后从 GUI 应用草稿、保存至新的隔离临时文件并用正常关闭路径退出；endpoint 和 descriptor 均不存在。该链路是工具驱动的 GUI 点击/键盘事件，不是物理 IME 或人工显示器观察；一次快速多字符自动化遇到原控件已刷新/移除的陈旧事件拒绝，未用它补写输入法结论。生产 FIFO probe 另覆盖同一已展示快照的三字符内容收敛及外部替换后的陈旧事件拒绝。
- **本轮验证。** 修改后 `verify_composable_scene_renderer.sh`、`verify_composable_ui_appkit_text.sh --renderer-work-cost`、`verify_composable_ui_appkit_text.sh`、Cangjie 1.1.3 的 `verify_composable_ui_window_controller.sh` 和 `runtime/cjgui` 包根 `cjpm build --skip-script` 均以 0 退出；构建仍有既存 deprecated/unused 警告。`git diff --check` 及本轮未跟踪 runtime 文件的 `/dev/null` no-index 检查无空白错误。没有重跑无关 960 节点矩阵；GPU duration、物理 IME、VoiceOver、人工可见呈现、安装/公证/发布和原截图应用的修复仍未验证。

### 最终证据核对与未收口项

指导已读取 `/private/tmp/cjgui-render-work-final.stdout`：180 条工作量样本、两条 `CJGUI_TEXT_ACCEPTANCE_TOTAL`、两条 idle。最终编码/总时钟结论仅对应此文件；旧 `cjgui-render-work-cost.*` 和 `cjgui-render-work-new.*` 不替代它。8/9ms 各为一次受控失败恢复样本，不是30次普通输入的总延迟分位数。形状绿例原始输出为 `/private/tmp/cjgui-shape-batch-final.stdout`；红例仅保存在执行任务工具回显，未另存文件。正常文本/控制器输出为 `/private/tmp/cjgui-appkit-final.{stdout,stderr}`、`/private/tmp/cjgui-window-controller-final.{stdout,stderr}`，控制器 stdout 只有构建成功字样，不能仅凭该字样推断所有运行断言。

同一 RuleSet Host 的公开 JSON、AX 与正常关闭证据按执行报告保存在该任务的 CUA/terminal 回显，没有独立持久日志。临时保存文件不是客户端/AX证据，已删除的 endpoint 不可重取历史状态；本次指导未重跑该窗口，也不声称已独立复看所有回显。

在启动本次最终收口前，执行已明确：本轮最终 native 修改后未重跑导出预览，不存在与最终源码绑定的导出指纹；原导出通过仅保留为前轮。当前形状证据是非法大批次到合法分批的正确性修复，没有合法逐形状与合法分批的同条件成本对照。以下补充已完成这两项；保留这段是为了说明它们的发现依据，不把它继续读作当前欠项，也不借机扩大测试规模或重新开发已通过内容。

### 本轮最终源码收口补充（2026-09-13）

- **合法合批成本对照，测试接线 RED 后 GREEN。** 在同一真实 7 个连续矩形场景、同一 2x drawable、同一 Metal/readback 路径下，先加入 test-only 模式选择断言；RED 原始链接失败为 `/private/tmp/cjgui-shape-cost-red.stderr`（缺少 `cjgui_internal_renderer_test_set_composable_shape_submission_mode`）。它只证明新增对照的测试接线尚未实现，**不是**生产 renderer 行为复现；生产越过 4 KB 的红例仍单列在前面的 7 形状复现。随后仅加入 test-only 选择器：逐形状模式在每个完整 6 顶点矩形后提交，容量模式沿用生产 4 KiB 边界分批，未引入保留 `MTLBuffer` 或改变 painter order。GREEN 原始输出为 `/private/tmp/cjgui-shape-cost-green.stdout`：`individual_draws=7 individual_uploads=7 individual_vertex_bytes=7392 individual_cpu_encode_us=208`，`capacity_draws=3 capacity_uploads=3 capacity_vertex_bytes=7392 capacity_cpu_encode_us=208`，最大单次上传分别为 1,056 B 与 3,168 B，均 `<=4096`，`pixels_equal=true`。这里的 uploads/draws 是实际 `setVertexBytes`/`drawPrimitives` 计数；CPU 区间只包 `CjguiEncodeComposableNodes`，不等同 GPU 或显示器完成时间，也没有旧非法无界调用作为基线。
- **最终源码导出消费绑定。** 以 Cangjie 1.1.3 `/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3` 从当前 checkout 导出，清空 native override，迁移到含空格路径后分别构建 UI-only 与 collaboration bundle，并实际执行 collaboration 公共 client 的空标题写入、陈旧版本拒绝和 normal-close endpoint 清理。原始结果 `/private/tmp/cjgui-preview-final.stdout`，临时导出/runner/bundle 目录保留在 `/private/tmp/cjgui-framework-preview-consumption.Y1G0Fh`；source 与 preview payload SHA-256 均为 `3d5caaf269b8c99a6ec27b7a25f2145fde92d63f9e07d7c61dbfdbc268720f33`，runner 为 `cb62665ce388f4690e2661d45a8771c5b5a0180cf32af8de64c493c63e5322c6`，UI-only bundle 为 `f429a0b26c62a62880e03d17cc8e3723f90dd56b407e03af7e974c7dd6c2baae`，collaboration bundle 为 `c7b24909558e079b24a00a3b6bc61ff8bad73943fb14b1f428d093991f036744`。绑定脚本现在明确记录 exporter/source/preview/runner/bundle 指纹，且不会把前轮输出继承为本轮证据。

### 指导收口

指导已抽查最终形状对照及导出原始输出，结合Terra关键衔接审阅，接受本阶段所列实现、正确性、工作量与消费范围。合法对照没有证明CPU提速；两个总接受时钟是单次失败恢复，不作输入分位数。未验的物理IME/VoiceOver、GPU duration/人工呈现、安装发布继续保留。下一完整阶段为[连续编辑与局部更新](2026-09-13-continuous-editing-local-update-milestone.md)，不重复本阶段已满足验收。
