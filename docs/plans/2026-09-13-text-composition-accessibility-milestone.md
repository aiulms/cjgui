# 大阶段：文字组合输入与无障碍接续

2026-09-13；原任务01a08f82-b682-73c0-a9b0-25a27bc5ffd8，Terra/xhigh，原目录。指导复核/规划，执行实现。

## 完整目标与依据

使普通CJGUI应用中的单行/多行编辑，在输入法组合、选择、滚动、焦点切换、外部修改和辅助功能操作中保持一致可用。复用当前自绘文字与AppKit TextKit/inputProxy，不改成原生控件产品，不新造完整文字排版引擎，也不做富文本功能扩张。

[设计导航](DESIGN_INTENT_INDEX.md)的文字/输入/共同操作与[历史避坑](../research/gui-framework-pitfalls-intelligence.md)第4节指出：文字不是drawText，组合态不能只剩最终字符串，无障碍与AI不能各造真相。此前旧禁止实施语句不生效。宿主与普通包消费已取得独立消费者、实际生命周期和60秒成本证据；如今优先这条人侧主线，语义观察/渲染/调度成果复用，物理未验不靠其他测试消除。

## 实施范围

1. 沿composable_ui_window、native composable overlay/inputProxy、共享文档和表单owner梳理组合态归属。pending marked text、selection、committed content分清；画面、AX和外部接口从真实owner/交互状态投影。现有setNodesFromProjection在hasLocalText/hasMarkedText时保留proxy内容，需验证外部同对象变更时不会静默丢远端更新或用旧preedit覆盖新文本。
2. 实现/修复完整组合周期：开始、更新、选候选、提交、取消；提交仅形成一次预期领域修改/撤销单元。焦点移动、Tab、Escape、节点删除/禁用/只读/换绑、关闭/取消关闭时，组合态有明确结果，不串到新对象。外部同对象变更并行时明确冲突/重新定位或取消规则，不能擅自提交未完成文字；无关对象的外部动作不因组合态被全局阻塞。沿既有授权，不因输入法额外索取用户批准。
3. 字符与位置正确：中文、emoji代理对/ZWJ、组合音标、换行的鼠标选择/方向键/退格/删除、UTF16与公共UTF8范围转换，拒绝切断无效边界。候选框rect随真实排版、滚动、窗口尺寸/DPI/焦点变化更新，不以固定字符宽度计算。复用TextKit测量和缓存，错误可恢复。
4. 补普通系统无障碍消费：当前只给interactive节点AX action，检查静态文字、只读内容、标签关系、role/value、焦点/选择和动态变化通知，至少让可见关键内容能读、可编辑文本能按允许能力修改、按钮/开关能操作。动作走原真实输入/业务路径，尊重禁用、只读、层遮挡；关闭或节点移除后旧AX对象不能操作新身份。避免每次焦点/输入重建整树，不以AX树存在声称VoiceOver整体完成。
5. 规则集与文档两个正常宿主应用共同消费，独立普通消费者验证无需改native即可使用这些能力。修复应落通用框架，示例仅作消费。保留当前显示进度和交互授权分离，不泄露无权读取的内容。

## 验收与成本

先建立最相关实际失败的生产路径回归，再修复；不为每个helper重复全套检查。native主线程探针可驱动真实NSTextInputClient组合调用、读取selection/rect/领域变化，但必须称程序化输入法路径，不冒称物理IME。桌面可用时以Cua在两个正常窗口实际使用系统输入法：组合期间更新候选、提交/取消、跨行选择、外部修改后继续编辑；只能看到最终粘贴文字时不能标输入法通过。不能使用用户剪贴板/文件作测试负载；必要paste工具应恢复原剪贴板，不改系统安全/睡眠配置。

稳定回归覆盖组合并发外部变更、删除换绑、只读、撤销、候选框随滚动、Unicode边界及AX旧对象失效。已支持的普通窗口关闭/拒绝关闭通过宿主消费验证，不能只发SIGTERM。

使用相同产物/文本规模/预热测单行、可复现长文档编辑/滚动，记录排版次数、CPU/RSS、事件处理/提交成本，确认组合每次更新没有全量业务编码或无谓GPUreadback。性能测试使用可关闭诊断；不宣称富文本、完整国际化或人眼presented。

安排无实现上下文的独立Luna/Terra按公开说明验证正常消费者的可读/可编辑/只读/焦点与外部接续，真实输入工具不可用则列一次确切错误、继续AX与native生产路径和成本工作；不能锁屏时整阶段停工，也不能直接把程序化测试升级为物理验收。最终列已实现通用能力、两应用消费、实际物理/程序化/AX各自证据与欠项。

## 边界与执行

原目录、不worktree/分支、不stage/commit/push、不发布。公共/native/FFI跨模块分析优先CodeLattice，图不足用源码和真实构建/行为补证。相关core/client/文档/规则测试、native输入与宿主探针、正常app构建/运行、root build --skip-script与diff检查按风险一次完成。先前K3无效咨询不计有效轮次；同一问题两次实际修复失败使用确切kimi-code/k3只读咨询，两轮有效方案仍失败立即给指导诊断，环境不可用不反复重试。不要设置/保存凭据。

阶段应交付输入/无障碍/共同编辑/成本的完整链路，不按一个AX属性或一个候选rect修复停工。完整或实质升级回报指导01a08f0f-e1ce-71c1-9a6e-4eee08308d61，更新ACTIVE与本页。下一候选由结果决定为长文本布局效率或控件布局组合完善，不预先增加无关功能。

## 交付区

2026-09-13 本轮已完成通用输入、AX 和共享文档 owner 的实质接续；物理 IME 仍是明确未验项。

- `CJGuiInternalComposableInputProxy` 现在保存组合前的 committed string/selection。焦点离开、Escape、节点删除、禁用、只读、重绑与同对象外部投影变更都会取消 marked text，而不是把旧 preedit 隐式提交到旧/新对象。外部同对象替换先成为新的 committed 基线；其后的新组合只形成一次普通 text-change 领域事件。
- `CjguiTextDocument.replaceProjectionTextFromHuman` 及 workspace 入口将一次已提交原生投影收敛为保守 UTF-8 边界下的最小替换和一次 human undo。共享文档普通窗口已消费该入口，不再用整篇可见文本构造业务 `REPLACE_RANGE`；marked 更新不进入领域 owner。它当前不是完整 UAX #29 extended-grapheme 实现：接受/拒绝规则已明确限定为 UTF-8 标量、CRLF、常见 combining/variation/skin-tone、ZWJ 相邻和成对 RI。
- 共享 composable AX 现包含静态文字与只读/禁用的可见控件，并从 live 节点取得 role、label/value、focus 和 selection。可编辑文本、按钮和开关仍通过既有 focus/FIFO/controller 路径操作；只读、禁用、layer scope 与已移除节点均不能绕过。结构相同的 refresh 保留 AX 对象，替换/关闭后的旧对象不再操作新节点。
- UTF-16 选择到公共 UTF-8、emoji/ZWJ/组合音标/CRLF/连续 RI 的保守边界，以及 TextKit 候选框的多行滚动和实际 `NSWindow` resize 已由探针覆盖。CRLF 中点与旗帜对中点的核心红测先失败后通过；原生 TextKit 仍是平台选择位置的权威。候选框来自自绘文本布局并转换到屏幕坐标；本机探针记录到 2x drawable。多显示器 DPI 切换未实测。
- 新增“已提交本地文本已入 FIFO、owner 尚未处理 → 版本正确的外部同对象替换 → 正常 drain”的生产链回归：旧投影事件由既有 identity/projection-version 解析拒绝，TextKit proxy 读回外部基线，下一次 marked commit 只将外部基线加一个字符写入真正 `CjguiTextDocument`。同一探针对该提交做 undo/redo 读回；原有 marked 未提交→外部替换路径仍取消旧 preedit。没有猜测或扩展事件 ABI。

本轮验证：

- `runtime/cjgui/native/scripts/verify_composable_ui_appkit_text.sh` 通过：真实 AppKit `NSTextInputClient` 的程序化组合调用、已入队本地提交与外部同对象替换的时序、真正 document owner 的 version/undo/redo 读回、一次真实 controller close 拒绝后继续编辑、焦点/Escape/只读/禁用取消、一次提交、16 行多行滚动、缓存复用与 resize 后 candidate rect。它不是物理中文 IME 验收。
- `runtime/cjgui/native/scripts/verify_composable_scene_renderer.sh` 通过：真实 AppKit/Metal 场景中的 Unicode 删除、静态/只读/禁用 AX、button focus、旧 AX 身份失效和真实 FIFO 路由。
- `shared_operation_core` 的 Unicode 定向红测后通过；以当前源完整 core 40/40、root 5/5、root `cjpm build --skip-script`、native text/scene probe、两 bundle rebuild 和两独立第二消费者均已复跑通过。已知工具链/旧代码 warnings 仍如实保留，未被抑制。
- 两个正常 bundle 均由当前 native 源重建。`/tmp/cjgui-text-composition-window-baseline-20260913.json` 的 5 秒预热后运行中，文档 external replacement/readback/CAS conflict 和后续 Metal frame 均通过；规则集与文档均从正常 host 生命周期退出 0。文档 edit 的 41 次 paced public reads p50/p95 为 12.798/24.648 ms，进程 CPU 为 2.0--2.7%，RSS 96,096--101,808 KiB；这只是当前产物的短时成本快照，不外推为长期内存或物理输入延迟。
- 当前源再次生成的 `/tmp/cjgui-text-composition-final-normal-hosts.json` 分别启动正常文档与规则集 bundle：文档 external replace/readback/CAS conflict 后 scene/frame 1→2；规则集 100 项批处理、CAS、定向读回与后续 frame 1→102 均通过，二者各 11 个样本、退出 0。它们证明两个正常 Host 对真实 owner/公开 external path 的消费，而非本地 TextKit 输入或物理呈现。
- `shared_document_second_consumer` 以公开 descriptor 动态发现并验证 range read、写入、版本冲突和拒绝未授权范围；测试修正为接受 CLI 对预期 conflict/permission-denied 的语义退出码，完整黑盒验收通过。
- 独立 Luna 的只读公开消费者复核确认：公开 CLI/API 只暴露 descriptor 下的 `describe/get/read-range/changes/observe/invoke`，版本冲突与授权拒绝保持语义退出码，`IDS` scope 不泄露 focus/selection/layer；本次没有运行 descriptor/socket、桌面或 IME，故仅是静态公开契约复核。
- 长文档诊断以同一真实 AppKit controller → `CjguiTextDocument` owner 路径产生 10,250 与 102,400 UTF-8 字节（含 emoji、组合音标、CRLF）文本，各先预热再在首/中/尾三处通过真实 selection+TextKit insert 编辑并滚动；每次确认为 3 次 owner 版本推进、3 次 build/layout/submission。当前源三次稳定进程样本的峰值 RSS 为 133,008–133,472 KiB，峰值 CPU 100.0–100.3%。102,400 字节的 owner delta 为 1–2 ms；TextKit/自绘 input turn 为首 89–90 ms、中 95 ms、尾 151–152 ms（10,250 字节为首 11–13 ms、中 15–17 ms、尾 17–18 ms）。通用路径已启用 non-contiguous visible layout：首/中从原约155–159 ms降到上述区间，尾部定位和实际滚动仍会完成整篇布局；因此不宣称长文本局部编辑或滚动已低成本，下一阶段应以增量/分块布局作为明确性能问题继续，而不是归咎于 document owner。

未完成/不能外推：本轮 CUA 查询仍明确返回 “The Mac is locked and automatic unlock could not unlock it”，因此未运行两个正常窗口中的物理中文 IME、候选窗肉眼观察、真实跨行键盘选择或 VoiceOver 全程；没有修改系统安全或解锁设置。完整富文本、完整国际化、多显示器 DPI、安装/公证/发布也不在本轮结论内。


### 指导复核与原阶段接续

接受39/39、程序化NSTextInputClient与native AX探针的针对性范围；物理IME确有工具阻塞，保持未验。但5秒外部替换/读取没有完成原定长文档本地编辑/滚动成本，shared_document_second_consumer脚本不等于独立AI按公共说明使用人侧能力。继续本阶段完整交付。

- `replaceProjectionTextFromHuman`虽生成较小替换，仍toArray两份全文并扫描公共前后缀；不要宣称输入处理已局部复杂度。用至少两个明确文字规模（如1万/10万字符且含Unicode）、多位置编辑和滚动，经过正常controller/owner测处理耗时、排版/提交计数、CPU/RSS及撤销成本，给足预热和稳定样本。若发现热点，按证据优化通用路径；不为一个读请求短测标完成。
- 该human入口未携带expectedVersion，native队列的旧投影文本可能与随后外部修改交错；请用本地已提交文本排队但owner未处理→外部同对象修改→正常drain，以及未提交组合→外部修改两类明确时序验证。沿已有投影身份/版本拒绝或重同步，不能把旧全文diff到最新内容而抹掉外部修改；无关对象仍正常推进。复现结果决定是否需新参数，不凭代码猜测直接改ABI。
- 当前isTextClusterBoundary是手工范围规则，缺完整分段语义，区域指示符一律相邻不分也不等同成对规则。明确公共支持边界并补CRLF、连续旗帜、组合字符等与native TextKit位置边界的对照。需要语言/Unicode依据时查本地标准库或官方规则，不拿少数emoji用例宣称完整grapheme-safe。用户输入不能切坏UTF8或静默扩到非预期文本；尽量复用可解释的分段能力而非不断追加特判。
- 补组合提交/取消的真实领域version与undo读回，不仅native事件数量；包括焦点转移、只读/删除换绑、拒绝关闭继续编辑、AX旧对象、外部变化后本地再次输入。两正常宿主应用分别消费，native生产路径在锁屏可做；物理操作和程序化输入分别报告。
- 独立Luna/Terra只读公开说明对普通消费者做静态/只读内容读取、允许编辑、禁用/层限制和外部接续；Cua锁屏可记录并转入不依赖物理桌面的公共/AX接口实际消费，不能把脚本独立进程改称独立Agent。无需反复解锁或重试同一错误。

完整阶段继续，保留已有成绩与物理IME欠项，不切成只修一条边界；两次实际失败/K3有效轮次规则累计。给稳定成本与剩余真实环境限制后再决定长文本优化/控件组合下一阶段。
