# CJGUI 当前方向与实施状态

更新：2026-10-19。方向保持“仓颉核心、高性能自绘 GUI、人和 AI 共同理解/操作/生成界面”；具体能力按正常消费者证据分层，不以某个编辑器样例替代框架完整度。

**阅读与更新：** 执行者读 [AGENTS](../../AGENTS.md)、本页自己这一线和当前任务，再查直接相关源码；不默认读历史全文。每线只替换下面一段当前摘要，原则上不超过600字；逐笔原数、哈希清单与过程写既有阶段页/证据目录，不继续扩长摘要。指导规划另看[共同源码与资产导航](../../docs/plans/DESIGN_INTENT_INDEX.md#shared-code-entrypoints)。

**共享优先：** 按 [共同实现与平台复用](../../AGENTS.md#shared-implementation)，先复用主树与已接通消费者，平台只补必要差异。主树、OHOS snapshot、Windows 冻结包尚未宣称全量同版；本任务记录实际输入源和共同回接边界，禁止整树覆盖并行改动或再造同一套 owner/交接规则。

**咨询与授权：** 已取消默认/强制 Pi→GLM5.3 及自动换顾问；向指导升级不等于外部咨询。只有用户当前明确授权才调用，见 [唯一咨询规则](../../AGENTS.md#independent-model-consultation)。此次文档收束不启动、恢复或暂停任何执行线。

**空间与保护：** 复用工作目录、默认每线新增保留≤10GiB、峰后宿主至少20GiB，具体已批准的更严限制/例外见各线；实际驱动落实限量与收尾，见[容量规则](../../AGENTS.md#artifact-space-budget)。旧存量、其他线及用户资源不清理，未经要求不 stage/commit/push。

## 当前阶段与执行状态

### E · macOS

**2026-10-18可搜索面板（Sol，本簇已交付）：** Mac候选9436dd53/冻结源c0c70186。公共实验组件复用输入、虚拟列表、scoped身份/命令、主题及弹层；Pharos已接⌘P元数据快速打开与⇧⌘P同声明命令。正常鼠标打开→模式命令→源码X/取消Y→可视取消V/Z→23B公开/文件逐字一致→保存/关闭0；普通通知消费者选择/Apply与最终取消后选区输入/关闭0通过。源码候选目标、TEXT/INPUT光标责任和native声明复用接缝已闭合，原拒绝门保留。884文件基底+差量可重构，201回接一致，构建后源漂移0；启动器迁移到含空格目录已验。旧轻微顿挫/未知帧/严格门维持，未扩GiB或其他平台。留存10.746/10.75GiB，实释457.6MiB，宿主余295.50GiB；峰11.5未连测。自有临时产物已收尾。护H/W/L与用户资源，无Git写。[交付与证据](../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md)。

### H · HarmonyOS

**2026-10-17当前任务：** DeepSeek执行深诊断成本簇，有限交付待审。754a/08c8冻结1007项，默认off前门、事实/FIFO/private/反馈保留；三模式同语义，4native+Cj撤回红，P6218/T5a02构建0。SDK97314/P4246/T10375均关；原64MiB/source990/20单投，20Layout/20转交，全文67109137B/a699一致，双消费功能及关闭过。完整反馈113–228ms/中位141，100ms0/20；RSS421→902/峰1179/HWM1247MiB。严格画面未过、锁屏录像未跑。准备期真实选择入队已定位；下步验证FIFO/候选交接，不吞选择。整H13.748/14GiB、宿主134.84GiB；退重325.77MiB保全原件。100ms/RSS/画面/冷控/GiB门仍开；无顾问/代理/Git写，保护E/W。[证据](../../artifacts/h-bounded-large-20261008/continuation/focus-window-handoff-current/PREIME_POSTMERGE_ROUND_REPORT.md#h-runtime-diagnostics-default-off-candidate-20261017)。

### W · Windows

**当前摘要（2026-10-18，候选81，用户决定收口）：** W交付完成，未证项按用户决定保留。**交付**`delivery/Pharos Windows Preview 81.zip`（sha 28a35e3b…，8,016,927B；EXE 1fd5530d…；源 046f7e00…）。**四项验收在 81 上实跑为绿**：发布包开箱运行、连续操作链（保存252035B/v23/`82df1664…`→新PID续写）、真实系统IME外部改版（failures=0）、设备恢复（failures=0）。**用户决定（2026-10-18）**：屏幕像素100ms门保持未证（呈现104ms；本机几何仪器分辨不出），主树三特性移植暂不进行。主树已回接`refreshIfNeeded`门并经独立消费者验证；三特性闭包、补丁与清单留在 evidence/…/W-BACKPORT-TO-MAIN-TREE.md。固定15GiB；无咨询/Git写。

### L · Linux（X11 + Vulkan 第一阶段实施中）

**2026-10-18系统输入与剪贴板收口：** 共同层撤销无 owner 的通用 caret 钳位（`selection_rebase_unavailable`），accepted 镜像刷新改为同时核来源字节与版本；整值字段“旧版本→新值末尾”策略留在通知桥。Linux XIM/XIC 接通 ibus-libpinyin：预编辑/候选/提交/取消，提交走 owner 单笔路径，失焦/关窗取消组合，提交载荷不受 8 B 限制；候选位用同一份 caret 几何写 XNSpotLocation。剪贴板改异步 CLIPBOARD、64 KiB 载荷，超限/不支持具名拒绝保旧，复制/粘贴/剪切可用。**已验**：一条链完成组字 `中文`→候选 `你好吗`→取消→IME 替换 `选`→587 B 外部多行粘贴（605 B）→外部读回→超限/PNG 拒绝→剪切恢复→外部写后直接续写 `继续`、同字节版本推进 `邦`→读回 28 B→exit 0；失焦/关窗均取消无提交；native 双会话+16 槽饱和全过；range 短回归 `abZ#` 191 B、decisions=5、exit 0。**边界**：仅 X11/XIM 文本剪贴板，64 KiB；Wayland/emoji/硬件性能未做。无 Git 写，保护 E/H/W。[状态页](platforms/linux/STATUS.md)

### V · 跨平台视觉能力（2026-10-19 收口）

普通入口 `runtime/cjgui/examples/range_text_window_app`：点击验证 translate 可见命中、zIndex 顶/同值后写者命中、组 0.45/0.65 隔离合成、tint 乘色、1.5×+20° 与恢复。修 macOS 首帧纹理竞态（补一次 completion+snapshot），首帧即出图。effectGroup 含组自身 `[i,i+count)`，OHOS 两端改齐用 SaveLayer；OHOS translate 命中/tint MODULATE 已接；macOS effect hash 含 scale、输出范围按旋转包络；局部快路遇组内非单位 scale/非零 rotation 退出到通用路径，纯平移复用保留。非等比 2×/0.5×+45°、3×/0.5×+90° 确认 macOS 先 scale 后 rotate，恢复后复用正控通过；OHOS/Windows/Linux 未跑该组合，不写四端同序。Windows 仅 mingw 语法编译，R7 未动，来宾未跑；OHOS 新计数/交互/双素材未真机重验，HAP 构建受既有 ArkTS 错误阻塞。[阶段页与证据](platforms/ohos/evidence/visual-capabilities-20261018/README.md)。

## 已接受的交付

既有功能、各版本正常链和RED/GREEN只按原范围复用；本页E/H的“整包未完成”不撤销其已验子集，W原R7交付也不使后续拖选性能自动通过。精确构建身份和原件以各线当前链接为准，不混用不同版本汇成一次最终验收。

其他通用框架资产（样式、动效、材质、图片、语义与诊断）保留于[能力路线与阶段入口](../../docs/plans/2026-09-26-framework-capability-roadmap.md)。F5的实际VoiceOver及性能边界仍按[原复核](../../docs/plans/2026-09-26-framework-capability-roadmap.md#f-accessibility-consumption-review)留开，本次不恢复旧执行线。

## 保留边界与下一步

- 每次阶段接续同时检查通用框架能力、平台接入和真实产品体验；先解决影响当前使用的共同缺陷，再安排同一任务簇中的新增能力，不无限延长验证脚手架工程。
- 手写/生成/混合界面、人和AI共同操作、资源与性能、系统输入及语义仍属完整目标。缺口留在对应阶段与[设计导航](../../docs/plans/DESIGN_INTENT_INDEX.md)，不用“平台各自实现”或样例全绿代替。
- 首页滚动Metal资源增长的用户反馈仍随E线接续：已有局部纹理复用成果及收益未证边界见E当前证据；历史四轮峰值与静置回落保留于[原诊断](../../artifacts/scroll-memory-20261011/summary.json)，不据此称内存泄漏或承诺降幅。
- [收束前完整历史快照](DIRECTION_HISTORY_20261013.md)保留所有旧轮次、失败累计、咨询事实和原件链接。它不是另一份当前状态；仅在查具体旧问题时定位读取，旧“在途/阻塞/下一步”不自动恢复。
