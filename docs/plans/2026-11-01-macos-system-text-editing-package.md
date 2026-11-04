# Mac 系统文本编辑与共享命令整包

2026-11-01正式下发；主执行仍为`01a18297-1b22-7f63-ad2d-e49f066db253`，实际使用`gpt-6.1-terra`与`gpt-6-luna`，按难度选择档位。主执行负责归因、集成、自验及整包交付，完成直接回指导`01a17207-04bc-76a2-90c3-99c8c5060423`。不等W/H，不恢复旧Sol/DS，不新建用户线程、监控或顾问。普通修复与独立工作持续推进，不逐文件停工。

## 目标、基线与已有资产

依据[首版范围](2026-09-26-framework-capability-roadmap.md#first-mature-version)、[共同定义与操作](../core/AI_NATIVE_UI_SEMANTICS.md)、[完整性视角](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)和[复用导航](DESIGN_INTENT_INDEX.md#shared-code-entrypoints)。集合导航与公开窗口观察刚已交付；本包推进普通文本字段和范围文字在系统选区、复制/剪切/粘贴、已声明编辑命令及外部改版后的连续使用，让手写和生成入口都能复用，不新造编辑器、输入法或业务历史。

起点是[上一包已接受范围](2026-11-01-macos-keyboard-public-interaction-package.md#guidance-keyboard-accepted-20261101)：SDK ad7935/632载荷/609输入、raw锁65ef736d；keyboard32e、Windowd50、generated a81，正常Rules c78a及Mixed9aad。它们只读保留。Source/Visual外部写入与退出的SDK741e既有绿证、系统中文输入的既有范围继续复用，不重新验证Pharos旧handoff环或性能B/C/D。

直接复用`text_session.cj`、`text_selection_authority.cj`、`composable_ui_window.cj`、`composable_ui_command_completion.cj`、`composable_ui_context_command_menu.cj`、现有shared text/form owner与macOS系统Edit/TextKit/剪贴板桥。普通消费者优先用`examples/range_text_window_app`及标准creator的mixed-form；模板既有命令声明、字段绑定和typed client保持单一业务来源，不另造一份AI字段/选择/撤销镜像。

W T11c的两处accepted-scene版本恢复及source-range recovery门**已在当前共同根中存在**，已局部对照；不是本包重新移植任务。复用其反例含义，不覆盖新Window、追旧17ee整树或启动Windows。现有系统命令路由已规定应用声明的Cmd-Z优先于标准Edit responder；该规则继续保留，不能因为系统入口可用就默认所有业务owner都有Undo。

## 连续完成的工作

1. **正常选区和系统剪贴板编辑。** 沿已有实现查清手写整值字段、生成字段及范围文字各自实际路径，再用一次能区分问题的正常操作定位未接通或错误边界。支持范围内的Cmd-A、键盘扩选、Cmd-C/X/V要作用于当前已接受的正确字段/owner；复制不改正文，剪切/粘贴只提交一次，Unicode和换行不能因UTF-8/UTF-16/字素换算被切坏。输入后的Apply/Cancel、外部改版后下一操作不得沿用旧版本或旧选区。先保真实RED再做最小共同/窄桥修复；已有正确路径复用，不为制造改动重写。只有实际接入缺口才增加窄helper，不能在应用里直接拼String模拟系统编辑。
2. **把编辑命令接到同一目标和完成规则。** 快捷键、系统Edit或既有上下文菜单按各自真实声明进入同一当前owner；能力、可用性及禁用原因跟随焦点、只读/禁用和owner更换。保持应用显式声明命令优先和completion/FIFO规则，不让一次快捷键同时命中应用命令与原生fallback。Undo/Redo只消费已经有权威历史的owner/应用命令；无此能力时沿原契约不可用，不新增全局或第二份撤销栈。外部仍使用应用已授予的字段/范围/命令入口及读回，不新增默认远程系统剪贴板权限。
3. **动态绑定和外部操作后能继续编辑。** 用同一owner的实际改版及一次已有生成重排/换绑，确认接受前后选区、字段与系统输入的对应关系。兼容更新保已提交正文和未应用草稿；旧owner、退休节点、过期版本/selection receipt和只读目标按原契约拒绝，不能靠重新聚焦、重放按键、合成最新mirror或放宽校准救绿。状态属于哪个window/owner/selection版本要明确，不能把字段的业务状态与native焦点、IME marked状态混为一体。
4. **普通建项可复用。** 将必要接线回到共同实现和现有公开模板/样例，用法说明支持的系统操作、业务Undo归属、授权与失效语义。开发者不应复制私有验收目录或给每个字段另写编辑状态机。Common仍experimental；已有入口满足要求就复用。共享库能力与应用自己的保存/业务规则分开，不硬编码Pharos或本轮控件ID。

通用状态归属/原生机制不明时按设计导航局部查GPUI/AppKit相关本地参考和现有反例；只借鉴实现思路，不引入外部GUI依赖。普通参数、编译、接线自行解决；若根因仍不明且连续实修低收益、存在重要并发/FFI/数据风险，再集中升级，不循环猜改。

## 分工与必要验收

Terra负责选区/installed receipt/版本恢复、命令完成和必要共同或Native修复完整块；Luna负责标准模板与公开消费接入、明确方案的反例/正常链完整块。主执行独占集成同一Window/native，明确源码写集，构建target和桌面串行。复用现有子代理；超长上下文确已妨碍执行时可用短上下文原生子代理替换，先结束旧工作，仍只向主执行报告，不建立第二主线。

先检查已存在的相关测试和正常证据，只增加能区分新缺陷的反例：非BMP/组合字符或换行的范围、同字节版本推进、真实新请求与旧receipt、readonly/retired拒绝、重复命令消费等按实际改动挑选，不能把这些词变成全量矩阵。源变化按AGENTS做对应build、声明/受保护路径扫描和diff-check；应用适配不能放宽生产断言。

汇合后集中完成两条短而完整的正常消费，源有变化则使用同一最终候选，避免逐补丁导包：

- **Mixed手写与生成字段**：沿现有双owner/30卡入口保另一owner脏草稿，在当前字段通过真实系统键盘选择、复制/剪切/粘贴已知短Unicode正文；一次生成重排或有效换绑后验证当前目标和旧目标拒绝；外部按已授权入口改版后直接继续原生编辑，完整读回owner/正文/字段与草稿版本，再Apply/Cancel及正常关闭。不要重复上一包1000项End或全套filter导航；本包新增的是系统编辑和绑定连续性。
- **既有范围文字消费者**：使用正常公开入口和可复算短文档，完成范围选择、剪贴板编辑、已有owner Undo/Redo或同等已声明命令、外部改版后接续、保存/正常关闭。没有实际历史能力的应用不可硬称Undo通过，应选现有真正有历史的消费者；不能新造测试窗替代普通消费。若本次共享改动未影响某条旧绿线，按来源复用，不再跑Source/Visual整包。

每条保必要原始输入与精确目标、完整内容/版本、少量原图/AX、构建/签名运行身份和自然退出。公开调用不能替代本轮系统键盘，AX本地值、callback、accepted标量不能替代正文与实际窗口；原图也不能冒充输入到呈现计时。启动前准备所有必留读回、保存/关闭及finally，长分析归档放退出后；原PID结束后不要用会重开空实例的取态确认退出。

系统输入源与用户剪贴板应按已有安全方法保全并恢复，不将用户原内容打印或带入证据。ASCII链先确认输入源，不能把IME预编辑当已提交失败；需要中文组合态接缝时仅补一条与本次改动相关的真实提交/取消及外部修改拒绝，复用已验中文范围，不重跑输入法矩阵。无法可靠恢复的用户剪贴板不猜覆盖，先换用已能保全的既有方法。VO旧正控没有实质新条件不重启；16/32ms、80事件、其他平台与GiB编辑不成为本包前置。

## 容量与集中交付

沿[容量规则](../../AGENTS.md#artifact-space-budget)和现有原累计。本包最多新增**128MiB留存额度**，E从15.4375到**15.5625GiB**，DS子范围从2.9375到**3.0625GiB**；E峰仍16.5GiB。为必要测试/正常构建和归档同时存在预留，DS峰从3.25到**3.5GiB**，五部临时从3到**3.25GiB**，不允许并行造两套完整图；宿主峰后至少20GiB。原占用不清零，不另加10GiB。起点五部2,907,168,768B、E16,571,105,280B、DS3,142,041,600B，指导实查宿主187,174,907,904B。高写盘前重新测量与预估，峰/留存分别受约束，不把临时峰额度当可永久保留额度。

一个复用构建工作目录、串行两个消费者；保护ad7935及最近可用交付、唯一RED。必要变化汇合后才导一个新SDK；没有载荷变化就不导包。身份清单/精确差分代替整树复制，失败可复盘原件保真后退役可再生产物；成功/失败/取消均准确收尾，保护他方实例、用户数据与W/H/Linux冻结包。不因旧目录看似无进程就猜删。

完成后集中报告实际修复及可复用入口、同源正常结果、真实未验边界、源/运行身份和空间账，直接回指导，不逐项停工或要求同义确认。若相关能力原本已满足，如实列复用结果，不为了凑改动扩功能。未完成就保具体剩余；不会因为本包结束而宣称整个Mac已成熟。无Git写、顾问、新用户线程或监控。

<a id="guidance-system-editing-accepted-20261101"></a>
## 指导复核与接续（2026-11-01）

本包按短文本、已声明命令和正常消费者范围接受，不要求同义收口或再跑窗口。[集中结果](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/system-text-editing/RESULT.md)与其原件为依据。指导本次只做源码差分、归档与正常原件核对，未构建、测试或投递GUI输入。

- 实际源码差分确为runner正则增加SHARED_DOCUMENT一项，SHA79f0f0cf…17960a，未改UID/mtime/socket身份和清理；保原不识别RED与修后parser GREEN。没有Cj/Native/模板修复，ad7935身份不变，复用此前已核的632载荷/609输入闭包，不导相同SDK。
- 文档PID61280、签名EXEc257e0a7…88699：独立从九份原RANGE响应解码UTF-8，并对照固定字面量、resource7101和文档版本0/0/0/1/2/3/4/5/7，全部对应；外改原RESULT为5→6且仅一次，后续原生!形成27B正文。实际保存文件及保存读回同独立预期，SHA87e56c49…7809fe28；抽看外改续写原图。23成员归档SHA4a52ae0e…96ffc6、签名EXE与manager一致，内含两份Cj逐字节等于公开example，normal provenance testing=false/verified=true。
- Mixed PID69091/EXE9aadc57d…a89f8沿用已接受App：核原全文与元数据，中Ω🙂𠮷为13B/6UTF16，重排后owner6302/选区4..6/focused保留，Right+x后14B、外改copies再原生!为15B；Apply8/8、Cancel10/10，A仍Pending A/1/0。选区结论限于这些读回及接续操作，不外推所有选区绘制/复杂组合。旧owner拒绝和新owner原件沿集中报告保留。业务30卡与生成候选30节点分别表述。
- 两份原manager日志SHA一致、exit0，descriptor/socket的两组left数组空；Mixed经过实际UI文档关闭守卫，不把首次Cmd-Q当已退出。原剪贴板条件恢复match、输入源恢复记录保留。旧forced/错误CAS/decoder轮次仍是方法失败，不能补成生产RED或GREEN。
- 回执的true/false误读及把aggregate13当document5，是现有私有driver/指导用法错误，不能倒推服务端有缺陷或改CAS救绿。新包把这一反复接入风险转成可复用公共客户端能力。
- 空间账沿原口径：五部2,938,609,664B、E16,602,546,176B、DS3,173,482,496B；净留存+31,440,896B，本轮实际退役263,835,648B，宿主同期变化不全归因本线。仍保原留存/峰值上限及唯一原件。

未新增全IME、VO、16/32ms、四类20、GiB、跨平台或Mixed业务撤销/跨启动业务持久化通过。Mac首版整体不宣称完成。按[首版开发接入方向](2026-09-26-framework-capability-roadmap.md#first-mature-version)直接进入[公共文档客户端与SDK接入整包](2026-11-01-macos-public-document-client-package.md)，同一主执行继续，不等外线、不回到逐按钮验收。

