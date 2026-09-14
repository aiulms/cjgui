# 大阶段：低延迟编辑与文字资源增量复用

2026-09-13，指导下发；Terra/xhigh负责完整交付并复用Luna/high，原目录。

## 目标与选择

把当前正确的自绘文字路径推进为低开销的连续编辑路径：修改一个字符或移动选区，尽量只更新真正受影响的派生文字/交互资源，正文、版本、权限和系统文本服务仍完整工作。不是只减少日志、计数或把计算推迟到失焦，也不是为样例添加功能。仓颉核心、自绘/GPU、macOS窄桥接与人机共用真实状态的方向不变。

用户明确把高性能作为核心目标。已有100KB多段约16–17ms只是上一实现/测试条件下的中位数，不是行业中位或最终标准；长单段首/中约171–179ms继续是欠项。120Hz整帧约8.3ms，框架同步输入应留出绘制/呈现余量；普通热输入以低个位数毫秒为优化方向，不把未经同条件测量的Zed“2ms”设成等价保证。报告p50和尾部，不用最佳单次或异步返回冒充输入到正确场景完成。

六主线选择：组件布局、共享语义、正式包和窗口方向/比例已有按范围证据；当前优先文字输入与GPU派生资源的实际成本，并保护资源/调度的公平和空闲开销。系统IME/VoiceOver、物理多屏/呈现仍按条件单列，不等待用户在场才做独立实现。生成UI和新业务样例不在本阶段。

## 复用与边界

- 依据[设计导航](DESIGN_INTENT_INDEX.md)与[运行架构研究](../research/ai-native-gui-runtime-architecture-intake.md)，复用内容变更与局部视觉反馈分工；共享内容/操作是真实入口，不因优化分裂人和外部的状态。
- 复用 `composable_ui_window.cj` 的owner确认和刷新事务、`shared_text_document.cj` 的Unicode范围/CAS/撤销，以及 `cjgui_internal_renderer.m` 的唯一活动TextKit graph、派生文字纹理、稳定身份、相对tile/clip键和已修复的文本专用V方向。系统提供字形与排版，不自研shaping或输入法。
- [窗口显示/输入/缩放](2026-09-13-window-display-input-scale-milestone.md)的方向修复、比例事件和导出依赖闭包按当前证据接受；保持正常窗口截图、同正文UTF8/UTF16换算和文本/图片方向分离。标签重复显示为已观察到的非阻塞可见问题：在当前写集涉及文字取值时区分label/value语义并处理，不为它单开阶段。
- 复用现有工作量、callback trace、场景/控制器probe和正常Host/正式preview消费。此前混写日志不伪装30样本；现在verbose glyph诊断默认关闭，不能直接将新数字与含大量诊断开销的旧数字称同条件加速。保留历史对照，不无限重建历史。

## 完整实施范围

1. **建立可信的当前成本基线并选定方案。** 在当前方向/scale修复后的生产等价路径，用同一正文/窗口/scale、预热和无verbose条件分别测普通单行、多行及100KB多段。分清正文接受、范围排版、纹理绘制/内存分配/上传、选区光标、场景提交及主线程等待；总区间用单独起止，不累加嵌套计时。每关键条件至少30个完整样本，stderr单独保存，限制观测开销。Terra据结果选择一项能解释主要成本的通用实现，不先锁死glyph atlas或固定数量tile。
2. **实现局部派生资源复用。** 当前每次修改仍可重做整个可见文字bitmap。优先根据系统排版得出的受影响行/范围，复用未变化的文字像素或资源，并分清文字内容与光标/选区覆盖的失效范围；只有证据支持时才引入行/块粒度缓存或字形资源方案。行后移、换行、字体fallback、标记文本、clip/alpha/scale变化都要保持正确，不能把受影响行之外的重排漏掉。布局坐标仍来自同一系统graph，不另外估算一套行位置；外部内容变化仍走真实owner及CAS。
3. **GPU与事务正确性一起交付。** 资源若原地更新必须解释已接受scene、candidate、在途GPU谁读哪些字节；不得覆写GPU仍在读取的纹理来伪造低拷贝。需要COW/局部上传时保住失败原子性、有界重试、代际和关闭。沿用8MiB/单文字资源、24MiB/已接受scene容量；新的分块不能通过改名绕过总预算。分别记录CPU临时、候选和在途范围，编辑/选择/滚动后资源收敛。没有安全方案时升级指导，不不断试共享对象。
4. **连续编辑和共享状态验收。** 正常内容的键入、删除、选区移动/替换、换行、滚动、字体或scale失效、失焦再聚焦、外部同对象和无关对象更新，以及失败后恢复，均不得把节省开销变成丢事件/错字形/旧选区。多行中英文/emoji及系统组合适配沿已有验证，物理IME与工具输入分开。已知长单段热点只处理此次方案覆盖的同根因工作，不额外扩第二排版图或分裂正文所有权；需要结构方案则带证据升级。
5. **测出收益并完成真实消费。** 与本阶段已保存的同条件基线比较p50/p95/max、总区间和实际准备/上传量；普通窗口与256混合场景不能因缓存管理退化，无变化与闲置不额外工作。至少一个主要受影响场景有超出测量噪声的实际收益；没有收益的复杂优化不能作为完成成果，撤回或带具体取舍升级指导。不保证显示器呈现值，不把GPU完成当物理显示。最终在文档多行与另一单行正常Host完成适用GUI→公开读回/授权修改→GUI接续及关闭，保存可读的最终窗口证据。相关生产改动后一次完成正式导出与三消费者依赖/资源来源验证，指纹绑定最终源码，不继承旧产物。

## 分工和结束条件

Terra先作根因/粒度/所有权判断，持续涉及TextKit、FFI、GPU在途生命周期的部分亲自处理；Luna负责明确的完整基线/回归包和确定方案后的实现，按写集隔离，默认一个并复用。Luna向Terra报告，不把指导任务当逐补丁中转。必要分析和验证的消耗可以接受；不重复整套检查、不轮询刷消息。工具链显式Cangjie1.1.3，实际包根runtime/cjgui。

当前阶段不以一份性能表或局部测试结束：交付已接通的通用增量能力、同条件实际收益、正确性/资源恢复和最终正常消费；无法安全达成则明确带根因/尝试/选项升级，不宣告完成。同场景失败按AGENTS跨阶段累计并用K3规则，环境不可用不伪称有效建议。阶段完成/实质阻塞主动报告指导 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。原目录，不stage/commit/push、安装发布或修改用户实例；锁屏跳过桌面依赖，继续独立代码与受控验证，保留GUI欠项。

## 指导复核与原阶段接续（2026-09-14）

执行报告的核心实现是把selection/marked/caret拆为同clip链下的瞬态Metal几何，正文纹理保持不可变；失败候选须克隆共享节点再清除装饰。指导已只读抽查源码与`/private/tmp/cjgui-low-latency-text-final.QSsevA/selection-final.stdout`，60个受控样本的正文raster/upload为0有证据；这不是全部编辑耗时为0，也不能将插入仍约16ms称为本轮输入加速。`selection.stdout`本身也已经是0准备的实现，不是有效修复前延迟基线。

正式preview日志有三消费者构建及来源/公开CAS/关闭成功，payload为`b8100d574d9e439845c58813f873ded9dbba9fd5ddee672bcfaeabdeec8bd97b`。正常Host的`normal-host-workload.json`明确是公开协议驱动且没有前台输入/人工呈现主张；业务帧2→6或1→2不能替代范围第5项的人机接续。指导没有运行开发测试或操作窗口。阶段整体仍需完成原范围：

- 复用已有原始记录，给同语义/同观测条件下选区或光标变化开始至正确资源/场景提交的总区间前后对照，连同实际工作量；若缺旧可执行基线，不反复重建整段历史，先说明可以建立的最小等价对照及局限。仅末次selection callback计时或消除raster计数不替代实际延迟收益。当前插入16ms可作为明确残余，不要求因为它尚未下降而否定已有选区复用能力。
- 对最后生产改动后的单多行正常Host完成适用GUI操作、可见选区/光标、公开读取/授权修改和GUI接续及关闭，保留最终可复查窗口证据。尤其检查正文之上/下的几何顺序、失焦恢复、选区替换/组合取消和clip/scale；已有针对性测试继续复用，不重复整套。锁屏就明确挂起真实桌面项目，不能通过改成公开协议探针来标完成。
- 将实现、实际对照、来源指纹、原始证据与未验边界一次整合回本页及ACTIVE。方案明确的补证与消费由Luna完整承接，Terra只审关键风险；不另开阶段/执行卡、不无新变更重跑全部build/preview。完成原阶段上述闭环后主动报告指导。

## 乱码升级后的指导方案（2026-09-14）

指导已核对真实截图：追加ASCII `Z` 后原有汉字变成其他字形，英文仍可读。结合owner/AX正确和切换文档恢复，优先检查字体属性、字形生成与实际绘制字体的一致性，不能定性为UTF8损坏、输入法故障或上游SDK缺陷。全量fallback、延后刷新、全量glyph失效的失败方案不重复；保留选择几何/COW成果。

源码有具体待证冲突：初始化 `inputProxy.richText = NO`，但 `applySystemFallbackRunsToActiveInput` 给各字符设置不同字体；`positionInputProxyForNode` 又以 `inputProxy.font` 和节点base font比较并可能调用全局字体setter。装饰更新和正文绘制还各有签名变化后的全量属性写入，未像prepare路径一样标记fallback失效。苹果[纯文本与富文本说明](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextUILayer/Tasks/PlainRichText.html)规定纯文本对象使用统一属性；这支持优先查属性归一化，但不是根因证明，也不意味着产品要做富文本编辑器。

1. **定位首次分歧。** 固定三行中英文/emoji、窗口/scale、选区、滚动和二进制；记录初次激活正确、追加Z、owner确认、切换回来正确四状态。只跟踪未改动前缀少量字符的UTF16、storage实际font/range、typing/base/proxy font、glyph到character映射、布局签名和属性写入来源。在super insert前后、position的font setter前后、fallback完成及实际draw前做有界观测。检查准备好的fallback是否被后续position/setAttributes再次清除。诊断不得遍历100KB正文，不将verbose耗时混入性能。
2. **区分排版与GPU。** 保存上传前正文CPU bitmap，与最终同区域截图对照，排除光标/选区和新增Z区域；不能只凭整图签名变化判错。若CPU已错，检查实际绘制时的字体与对应glyph，而不是只读storage第一字符字体；必要时在测试布局管理器绘制入口观测实际font/glyph。若CPU正确而GPU错，转查纹理身份、代际、候选提交及在途持有，不改TextKit。切换恢复状态是同一最终正文的正确对照，不引入第二套生产排版器。
3. **据证据修属性责任。** 若position全局字体setter或签名分支改坏未编辑字体run，将几何定位与样式变更分离，base样式按节点身份/真实样式版本判断，统一属性失效与fallback准备；不能从当前字符fallback字体反推控件样式改变。若纯文本编辑归一化是首个分歧，可单变量比较系统自动fallback与允许内部字体run的代理配置；后者必须保持公开纯字符串、禁止附件/格式导入、保持仓颉撤销owner，不开放富文本能力。先证因再选正确且成本可控的方案，不同时改多路径，不靠每次输入重建整个图掩盖错误。以上是阶段内授权的内部方案选择，无需再等指导批准。
4. **连续完成原阶段。** 保留真实事件顺序回归，验证追加/删除/替换、点击选区、外部CAS后接手续写、失焦恢复及适用系统组合适配；不穷举输入法。修复后继续总延迟对照、资源失败/COW边界、正常单多行消费和最终源码绑定导出，不能修完乱码就停止。仍无因时带首次分歧原始记录立即回报指导并继续独立工作，不重试此前不可用K3环境、不把环境失败算有效咨询。
5. **独立工作包。** Terra亲自做跨层判断，复用Luna完成固定二进制、同条件选区/光标总区间前后对照和原始证据整理。Luna不写native生产文件，不把正在变化的源码当固定基线；核对已有baseline各样本指纹，不混合并发重建产物。有稳定二进制直接复用，缺有效旧对照则提出最小等价方案及限制，不反复重建历史。不得抢Terra复现所用桌面或并行运行影响计时的负载，测量串行协调。最终生产改动稳定后做必要消费，不重复整套验收。

继续原阶段，不另开小阶段。指导收到实质升级后及时给方法并唤醒执行任务；30分钟heartbeat用于漏报和接续检查，不能让明确待处理的报告一直等下次提醒。锁屏跳过前台依赖，继续受控诊断、代码及独立证据工作，不改系统锁屏设置。

## 执行记录：fallback 根因、受控对照与最终消费（2026-09-14）

### 已完成的生产修复

真实三行CJK/emoji窗口在本地追加ASCII `Z` 并由仓颉owner确认后，AX/owner文字正确而自绘前缀乱码。测试编译的有界font/run观察确认：`positionInputProxyForNode` 从 `NSTextView.font` 读取首字符的resolved fallback，却把它误判为节点base样式变化，随后再次写入全局 `font`，清除了逐composed-character的fallback runs。

修复不改变公开字符串、owner、TextKit graph或GPU正文所有权。renderer现在保存最后一次主动写入proxy的base font；只有active multiline、非空storage、active layout base与该已写入base都匹配时，才保留现有fallback runs。首次focus、清空、resource rebind和真实样式变化都仍走正常全局赋值。新增test-only scalar检查以CTFont resolver逐composed-character比对storage run；CJK/emoji外部建立→TextKit focus→本地输入→owner确认、清空→外部恢复→再次确认均通过。现有rebind路径继续运行；没有开放富文本或泄露native对象。

同一示例消费者还修正了辅助状态投影：外部owner把文档从v1推进v2时，正文/selection此前已正确但状态会保留“文档已更新：v1”。状态现在只记录上次本地动作的owner版本，版本不同时从当前owner snapshot派生“已同步外部文档：v2”，本地续写v3后恢复“文档已更新：v3”。这不是第二状态机。

### 当前二进制的受控机制对照

历史固定probe虽然有稳定SHA，缺少对应的源码manifest，而且旧计时不包含完整selection/caret区间，故不能作为严格before。新增test-only one-shot mode在同一候选binary中只把下一次真实selection callback送入现有的完整正文rasterize/upload/COW/失败路径；默认生产仍复用正文资源。两支保持同一TextKit、fallback修复、文档、窗口、selection geometry、candidate读回和提交，不使用sleep、伪计数或第二排版图。

以同一binary `9bffe01bf966d2af01556d4b69124d88ed9c83330216e4f8f53e4d37354dff09` 按 `reuse → full → full → reuse` 串行运行。每模式共有720个`valid=true`样本：正常与256混合各一轮、开头/中部/末尾×光标/范围各30次并重复两轮，即每位置条件120个。每个样本从真实`selectRange`前的外层时钟开始，直到正常pump、projection selection、candidate rect和提交读回；内部callback字段不相加。

| 模式 | 正文工作 | 总区间 p50 / p95 / max | 结论 |
| --- | --- | --- | --- |
| `reuse_body` | 720/720为0 raster、0 upload | 0ms / 0ms / 6ms | 时钟为毫秒粒度；0只表示低于此分辨率，不是零延迟 |
| `full_body` | 720/720为1 raster、1 upload，各1,468,416 bytes | 14ms / 15ms / 19ms | 强制现有真实正文准备，作为当前机制受控对照 |

对照只能解释本次“selection/caret复用正文资源”在该受控窗口/正文/scale下的成本差异；不能宣传为历史版本加速、插入延迟、物理呈现、IME、VoiceOver或用户感知延迟。原始manifest、两轮reuse/full stdout/stderr、AppKit/scene回归和preview日志均在`/private/tmp/cjgui-selection-ab-final.BEBjz7`。

### 当前验证和剩余前台尾项

- `verify_composable_ui_appkit_text.sh`：通过；包含本次fallback clear/restore回归。
- `verify_composable_scene_renderer.sh`：通过。
- `verify_framework_preview_consumption.sh`：在显式Cangjie 1.1.3环境通过；UI-only、Collaboration、Document三消费者均从exported preview构建，source/preview payload相同为`e090f6e71d3cb75575548bc7bdfe547da1b8a4a75aa07063c7490a6295f4c026`，原始成功尾行在上述根目录的`preview-consumption.stdout`。
- 无测试flag的`CJGUISharedDocument.app`已从当前源码重新构建、发出descriptor并启动；其初始frame仍报既有`scene_color_mismatch`，不将该readback称绿。随后macOS锁屏，CUA不能读取或操作此窗口，因此最后一轮当前binary的GUI输入→外部CAS→GUI续写/关闭尚未重做。此前版本的同链路已成功，但不冒充为当前binary截图。

解锁后只需在已启动的隔离源码窗口复查：CJK/emoji本地输入与可见选区、外部版本化追加和stale conflict、状态v2投影、重新聚焦后的本地续写与关闭；不得触碰用户的`CJGUISharedOperation`实例。之后更新本页/ACTIVE并回报指导。安装、公证、发布、物理IME/VoiceOver/多显示器/presented继续保持未验。

### 指导复核及锁屏期间接续

指导只读重算四轮日志得到每模式720条valid样本及相同p50/p95/max，核对binary SHA与manifest一致；已查看受控开关只进入既有正文准备路径及preview三消费者成功尾行。接受这些证据的上述限定结论，不要求为了毫秒粒度再重跑已足以证明差异的矩阵。最终前台验证仍待条件恢复。

当前还有可独立推进的实际代码问题：首帧 `scene_color_mismatch`。源码 `CjguiComposableSafeOpaqueProbeNode` 把非图片、不透明节点中心当fill颜色；`CjguiComposableNodeMayAffectVisiblePoint` 和 `CjguiComposableSceneHasPotentialMetalDraw` 仅考虑fill/border/image，未纳入已进入Metal有序合成的正文纹理和selection/marked/caret。因此“safe”点可能被同节点文字或更上层文字/装饰覆盖。另一待查点是选点用整数中心，而实际blit用半宽浮点乘scale，奇数尺寸/非整数scale可能不取同一像素。它们是明确待证假设，不直接把所有mismatch标为误报。

Terra在原阶段内承接根因确认与方案；清晰复现/实现包可交Luna，写集互斥。保留实际失败scene，记录candidate、最终drawable采样坐标、实际覆盖命令与期望/实际像素；确认是oracle陈旧还是生产合成错误。复用现有painter order、resolved clip、正文textureRect及瞬态几何判覆盖，不造第二套渲染器。可确定干净不透明点才比较；文字/半透明等无法可靠推算的点保守换点或明确no_deterministic_scene_pixel，不能跳过整个类别掩盖真实错误，也不能单凭绘制成功宣称像素通过。真实干净色块的故意错误仍应报mismatch；文字覆盖/同节点文字/选择装饰与奇数尺寸scale至少覆盖实际根因。修正后走现有必要场景回归与源码绑定消费，不重测不受影响的1440性能样本。不得改变生产画面来迎合探针，不新增每帧GPU同步或全屏读回。锁屏下运行条件不足就完成源码和可运行受控验证，保留真实窗口欠项；不反复解锁、改锁屏设置或使用历史密码。

### 锁屏期间完成：首帧颜色 oracle（2026-09-14）

先以真实 AppKit/Metal scene 建立红色复现，而非把普通源码窗口的字符串日志当作结论。`verify_readback_probe_rejects_gpu_text_coverage` 让不透明底层候选 `(70,80)` 被后续透明填充的 `█` 正文texture覆盖；修复前首个 present 返回 `READBACK_FAILED`，日志为 `scene_color_mismatch`。`verify_readback_probe_rejects_self_gpu_text_coverage` 再覆盖同一个不透明文字节点的fill后纹理。两者都用显式drawable单像素读回确认最终仍是magenta glyph，故不能把绘制漏掉或改变画面伪装成通过。

生产修正仍保留单次首帧readback：候选先按实际drawable的texel坐标取样，再由该texel中心反推统一的logical判定点；不再用整数中心判可见、浮点中心乘scale读另一个像素。候选自身的border、正文texture、selection/marked/caret，以及上层同类命令都沿既有节点resolved clip链判为覆盖。它们不从public fill推导颜色，而是明确成为`no_deterministic_scene_pixel`；有确定不透明fill且无覆盖的原有clip/overlap回归仍实际匹配。`CjguiComposableSceneHasPotentialMetalDraw`亦纳入文字和即时装饰，避免把存在绘制误写成clear-color成功。

该判断没有增加第二渲染图、逐帧GPU等待、全屏读回或任何公共/生产测试ABI。仅当原有one-shot readback已被请求时仍等待同一单像素blit；选区、marked和caret的实际有序绘制继续由既有AppKit文本回归覆盖。若剩余真正的干净色块发生mismatch，原失败路径仍返回`READBACK_FAILED`，并在生产日志记录candidate index/id/kind、logical与drawable sample、node/clip、expected/actual BGRA，供区分oracle陈旧和合成错误。

当前独立验证：修复后的`verify_composable_scene_renderer.sh`通过（`/private/tmp/cjgui-scene-oracle-final.stdout`、`.stderr`），`verify_composable_ui_appkit_text.sh`通过（`/private/tmp/cjgui-appkit-text-oracle-final.stdout`、`.stderr`）。这不重跑不受影响的1440个A/B样本，也不替代最后生产源码的preview消费或解锁后的真实窗口链路；后二者仍为阶段尾项。

随后用显式 Cangjie 1.1.3 重跑`verify_framework_preview_consumption.sh`，UI-only、Collaboration、Document三消费者均从本次exported preview构建，source/preview payload同为`d15a8c634d611bbb3e850d975d031a98920ca41abfd7dc3b82948121263b4cf0`（`/private/tmp/cjgui-preview-consumption-oracle-final.stdout`、`.stderr`）。正常无测试flag的`CJGUISharedDocument.app`亦由本次native源码重建，日志为`/private/tmp/cjgui-shared-document-oracle-build.stdout`、`.stderr`，并扫描确认不存在`CJGUI_INTERNAL_TESTING`、`selection_resource_cost`或`multiline glyph-draw`字符串。此前仍在运行的隔离示例进程来自旧bundle，不能作为这次源码的GUI证据；系统仍锁屏，解锁后须先关闭它、启动新bundle，再完成GUI→公开CAS→GUI续写与关闭。
