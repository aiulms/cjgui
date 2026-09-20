# 大阶段：通用剪贴板、拖放与人机共同数据导入

原任务 Terra/xhigh 协调 Luna/high，在原目录完整实施；不提交推送。目标是仓颉高性能自绘GUI框架的通用数据交换能力，应用开发者决定格式和业务，不内置Agent或聊天产品。

## 2026-09-19 指导复核：功能分项接受，整阶段待补证

后续安排已合并进[数据交换可靠性收尾与鸿蒙自绘通道验证](2026-09-19-transfer-closure-harmonyos-channel-milestone.md)：下方缺口作为必要旧项一并承接，不单独执行完后停工。当前指派和执行主体以 ACTIVE 与新提示词为准。

本节优先于下方历史状态和执行方“全绿/收口”报告。指导只读源码、脚本、原始日志与产物，未重跑构建、测试或桌面输入；不恢复旧 Codex 自动化或旧执行任务。外部执行 AI 的本次工作已交付报告，以下是下一次完整收尾任务的依据，文档存在不等于启动执行。

### 已接受，不重复重做

- run-16 的 legacy、128B/4KiB/512KiB payload、overflow、双事件 drain、队列压力均有原始绿色输出。生产 `shared_text_document.cj` 确有 512KiB 文档总量上限；近上限改整文档替换、拒绝轮不推进期望是合理的探针修正。队列压力的 21 次 owner 接受包括同内容替换的 no-op，实际内容为 Qx、版本为 1，不称 21 次不同内容写入。
- 正常 bundle 的合成 CGEvent 经系统跨窗拖动到公开目标回调，原始 `/private/tmp/cjgui-composable-data-transfer-cross-window/probe.log` 为 `drops=1 payload=DRAG9 passed=true`。现行脚本内嵌的消费者只有接收计数与 payload，证明系统拖动到应用回调，不单独证明文档 owner/外部读回或渲染呈现；另一个未被该脚本使用的 `composable_data_transfer_cross_window_probe.cj` 不能拼为本次证据。它不是人工物理输入，也不证明 combinedSessionState 是唯一可用方式。
- 文档六步正常窗口/公开 UDS 接续的原始 `cjgui-shared-document-transfer-chain/chain.log` 有逐步精确内容检查与 `PASSED all steps`。规则传输归因有执行方记录，完整原始输出路径应补齐供复查。
- 正式导出 khfDY2 的 manifest/运行日志存在；指导逐字节比较 ui/window/host/session/native m/h 六项与当前工作区相同，consumer 指纹也与 manifest 相同。该导出证明 clipboard，运行标记仍为 `platform_drop=false`；跨窗系统拖动是另一个独立正常消费者的证据。core 51/51、规则 8/8、文档 9/9 原始测试日志已读，不声称指导重跑。

### 确认的缺口与下一次完整收尾工作包

1. **先修验收脚本的实例隔离和清理。** `verify_composable_data_transfer_cross_window.sh` 按 `CJGUIUiOnlyStarter` 名称查窗口并 `pkill -f CJGUIUiOnlyStarter`；`verify_shared_document_transfer_chain.sh` 同样按 `CJGUISharedDocument` 名称操作和关闭。这会误命中用户/其他测试实例，违反既有实例归属边界。改为每轮唯一临时目录、bundle identity/标题与准确 PID，定位、发送事件、等待和退出都绑定同一实例；启动失败、定位失败、超时和正常完成使用同一个幂等 cleanup。先在可辨识的自有同名对照实例上验证只清理本轮 PID，不拿用户实例试验。不运行现有危险清理命令。系统剪贴板快照先于首次修改、每轮文件独立；保留 change-count 条件恢复及失败日志，不猜测恢复已经丢失的原内容。
2. **补足 transfer 性能与生命周期证据，而非只改结论。** 当前 `hoverPure` 仅断言无业务动作/hover 清理，没有对 128 次 hover 前后的读取、解析、build/layout 做差值约束。加入相应断言和计时外正确性检查。`otherWindowProgressed` 在传输完成后才手动 refresh/pump，且允许 sceneVersion 相等；不能证明系统 drag tracking 期间另一窗口/公开调用推进。沿已成功的真实拖动驱动延长有界 tracking 时段，记录起止与期间另一窗口具体动作/授权请求的进入及完成时间、真实字段读回，区分“期间完成”和“松手后恢复”。不在 native callback 中递归 pump；若发现调度结构阻塞，带运行模式/调用路径咨询 Terra 后再修。
3. **资源量与释放分开验证。** native test stats 当前通过 NSString 转 UTF-8 后求和，记录 source/accepted/candidate/FIFO 的逻辑字节及各自峰值；它们不是总分配峰值，也可能因共享对象重复计数。`close_converged` 使用关闭前持有量、占用 session 数和 invalid token，尚不能证明关闭后的对象释放。复用现有统计，补关键 payload/容器生命周期的可观察释放证据或有界重复创建/传输/取消/关闭的实际分配收敛证据；写清采样范围、ARC/autorelease/仓颉 GC 边界。优先窄测试观察，禁止仅为统计加入生产缓存或公共 API。现有每尺寸单样本 elapsed 含测试统计/受控驱动，保留原口径，不宣称生产吞吐或端到端时延。
4. **把剩余失效覆盖做实。** 现有 legacy 的 cancel/旧 node/重绑/disabled/关闭分项可复用；在 transfer 实际入口补 modal、已入队后身份/scene 过期、drag 期间目标换绑/关闭等尚未对应原始证据的边界，检查拒绝后 owner/队列/视觉状态，无需重跑无关历史矩阵。不能以另一阶段普通鼠标用例代替 transfer。外部文本实拖已有工具失败记录，可保留环境未验，不反复折腾 TextEdit；说明同进程文本成功不能证明外部源实际派发。
5. **一次集成收尾。** 保留现有功能绿色证据；只有生产代码/消费者改变才重跑受影响验证、刷新最终导出。仅脚本变更不重建全部框架。补脚本/产物/原始日志指纹与规则窗口读回证据，更新唯一当前状态；最终报告分别列实际完成、受控完成、未验及原因，不用“阶段内可做项完成”隐藏上述可实施缺口。

本工作包整体交付，不逐脚本停工。由外部执行 AI 主导，Terra CLI 只在交接提示词规定的结构疑难或聚焦风险复核时介入，旧 Codex Terra/Luna 与定时继续暂停。此前历史失败不因换模型清零；不为阶段名称重新开发传输或重跑全部测试。

六主线取舍：组件与布局、仓颉自绘/GPU、文字系统集成沿已验资产保留；本次只收尾数据交换的资源/调度、语义入口及普通开发者验证可复用性。鸿蒙验证为下一候选独立技术阶段，先确认工具链→仓颉代码→系统绘图表面→输入/外部操作同一状态的通道，不立即大规模迁移，不以它覆盖本阶段欠项。

## 场景与当前缺口

人在窗口中复制一条规则，粘贴为新记录，或把文本拖到另一个编辑区域；外部智能系统通过已授权的结构化动作提交同类内容。两条入口调用同一应用业务操作，校验、版本和结果一致，人能看到修改并继续编辑。复制不是移动，拖动取消不会删除源内容。

指导抽查现有native仅发现文本代理的系统剪贴板和test-only复制粘贴验收，未发现通用NSDragging目标/源接入；此判断以当前搜索范围为限。Terra先查已有相关实现，存在的直接复用，不重复造新机制。参考[设计意图导航](DESIGN_INTENT_INDEX.md)、[人机共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)和[框架避坑](../research/gui-framework-pitfalls-intelligence.md)：平台回调重入、主线程阻塞、数据双真相及失效目标是本阶段重点。

复用composable_ui/window中的稳定身份、唯一命中/布局、输入scope、候选提交与interaction style；复用macos_application_host生命周期、既有command声明、文本代理的Cmd-C/X/V和系统输入、shared_operation_core的真实动作/参数/授权/CAS及client discovery。不要重建transport、observer、身份表或剪贴板常驻监控器。首轮只支持有界UTF-8文本和应用声明的一种自定义结构化字节/文本格式、copy语义；文件拖放、promise、远程加载、大文件流、move/delete语义另待需求，不扩为通用对象数据库或交换标准。

六主线取舍：本轮推进通用组件交互及语义数据交换，显示反馈沿现有GPU/样式，文字沿现有系统集成，资源调度只增加有限payload生命周期。普通开发者消费必须无需新增native业务分支。上一轮热点为nextDrawable，指导已接受不改变生产同步/节流；不继续为0.2ms的仓颉解析添加缓存。

## 完整交付范围

1. **仓颉公共声明与唯一业务入口。** 提供最小experimental transfer offer/accept/result或等效公共表达：格式、尺寸上限、源/目标身份、copy操作及可解释拒绝。应用声明支持的格式及接收处理，框架负责平台适配和生命周期；禁止native内识别规则字段或执行业务。结构化payload由应用解析校验，格式标识不是执行指令。普通UI-only应用可单独使用，不强制启用外部端点。
2. **剪贴板与命令。** 自定义组件可复制选中数据、从剪贴板粘贴到当前有效目标；输入框仍优先走既有系统编辑/IME语义，不偷走文本Cmd-C/X/V。实际copy/paste由明确人类命令或测试调用触发，不后台读取用户剪贴板。不可支持/超限/格式错误不修改owner。剪贴板仅是传输媒介，缓存/descriptor/原生对象不进入公共payload。测试优先独立pasteboard；若正常入口验收需要系统剪贴板，使用临时内容并条件恢复，不能覆盖用户在期间新复制的数据。
3. **macOS正常拖放。** 为声明的组件接入系统拖动源和目标，至少同应用跨区域/同进程跨窗口，并支持普通文本的外部拖入接收。拖入预览反馈复用interaction paint、正常命中和scope；坐标转换、裁剪、模态/disabled、离开/取消、source或target销毁有明确结果。最终drop再核对当前目标/owner前提，旧hover可接受不等于最终授权或永久有效。平台drag会涉及嵌套事件处理；native回调只做有界协商/复制/排队，业务修改经既有仓颉执行入口，不能在系统回调里嵌套运行另一套owner/pump。资源和临时payload在完成/取消/关闭时释放且有界，不能无限持有原生拖动对象。
4. **人和外部系统同业务接收。** 两个既有正常消费者以不同数据和布局使用公共能力，例如规则集复制/导入与文档插入文本，应用侧可增加必要领域操作，但不复制runtime。至少一个消费者的人类paste/drop和外部已授权invoke共享同一业务校验/修改函数；发现的格式/参数对应真实入口，外部不必模拟拖动也不能绕过授权/CAS。成功读回具体字段；非法payload或stale预期不产生半条记录/半段文本。领域支持的撤销由其既有owner负责，不新建框架业务undo栈。
5. **当前桌面与失效验证。** 当前屏幕可用性现场检查；正常bundle中完成一次复制/粘贴、一次真实拖放、取消以及同A人类操作→外部读写→人类接手的接续。工具合成输入、系统拖放回调受控probe和人工物理操作分开标记，不把直接invoke当真实drag。锁屏/工具限制保留精确未验，继续独立代码工作，不擅改安全设置。需要临时文本/记录只用自有测试数据，保留用户实例。
6. **性能与可迁移消费。** 高频drag hover同一目标不重复解析payload、不每像素重建布局或业务；在小、中、接近已支持规模的场景覆盖一次与重复交换、无效/超限、目标失效、另一窗口输入和失败恢复。测实际工作量/耗时及payload峰值/收敛，不沿用无关旧耗时当基线，不为追数字关闭平台同步。相关core/native/窗口/命令与文本回归、runtime build、FFI/公共声明/diff检查按影响运行，同target构建串行。最终一次含空格正式导出，独立公共消费者实际编译运行transfer能力，文档说明支持格式、ownership、限制和稳定性，不只把源码复制进去。

## 必要旧项与阶段边界

- 前一[交互调度阶段](2026-09-14-interaction-scheduling-efficiency-milestone.md)按直接计时和当前focused有界重叠范围接受。最终QChXnf六项ui/window/host/session/native m/h与工作区一致，payload为eebdb44bfe1c3afe67e15c12cfd94e8800b0dc12d917c5a36f6ef9c36bc54c86。导出日志实际为UI/document仅build，collaboration有公开handoff、另三项有运行；不能笼统说六个全部运行验收。
- locked计时sample20缺字段是合并stderr切行，原始 `/private/tmp/cjgui-interaction-scheduling-native-cost-locked/result` 含完整wait=0，指导已核对，无需重跑。
- 完整90轮current重跑第23条connection closed仍未归因。保留原失败路径，不把锁屏当确定根因、不把历史90绿替代current。此非已确认生产回归，不阻塞独立transfer设计；本阶段两窗口/外部接续若再复现，先定位连接退出源及host/session状态，不无限重新跑旧90矩阵。涉及同一owner/连接生命周期的功能验收在真实故障解决前不可报绿，重复失败按现有累计升级。
- 上轮正常同A可见接续并入本阶段正常窗口验证；系统IME/VoiceOver/实际GPU呈现/安装公证发布不额外扩张，不宣称完成。文字粘贴不是系统IME候选验收。

## 协作与收口

Terra/xhigh亲自确定平台拖放回调与仓颉owner的生命周期/重入契约、跨层实现和审阅；Luna/high承担公开值层、两个消费者与验证/导出等方案明确的完整工作包。默认一个，复用已有代理，写集明确、同target串行。Luna通过原生协作消息发实际父Terra、final自动回报，不用send_message_to_thread把例行进展发指导。没有独立工作时等待通知，不重复读码/重测。

整体包含代码、两类实际消费、相关验收和文档，不按单个接口停工；先修依赖旧问题但独立新能力继续。K3禁用，3次有效失败升级指导给方案。完成/实质阻塞主动报告指导任务01a08f0f-e1ce-71c1-9a6e-4eee08308d61。原目录不切分支、不建worktree、不stage/commit/push，自有临时窗口整轮复用、结束统一关闭并保留证据。

## 本轮执行记录（2026-09-17）

- 已实现 experimental 纯值传输契约：UTF-8 文本或应用声明结构化格式、copy、来源 kind/identity/id、目标
  identity、可解释拒绝和 512 KiB 单项上限。payload 仍是 UTF-8 字节；`仓颉🙂` 的 10-byte 边界已由测试
  固定。native 不识别规则字段、不保存业务回调或可写数据。
- composable scene 将完整 transfer declaration 与节点/命令同一候选提交；纯 hover/press/focus repaint 会重绑
  已接受 declaration，避免旧 node/version 留在 native。非文本声明节点支持显式 Cmd-C/V 与 AppKit dragging
  source/destination，文本输入继续走现有系统编辑/IME。source provenance 以有界私有 pasteboard metadata
  随 declared format 传递；它不是授权，接收 owner 仍做格式、payload、目标与 CAS 校验。
- 规则集把“复制”声明为 `cjgui.rule.record` source、“新增”为 target；同 identity/payload 回到既有
  `COPY_RECORD`，外来 offer 回到既有 `CREATE_RECORD`。共享文档以“复制选区/粘贴到选区”声明 UTF-8
  source/target，并回到既有 `REPLACE_RANGE`。core 中外部 transfer 分别沿既有 external CAS/请求幂等路径；
  规则集已有测试覆盖应用、同 request 重放和 stale conflict，文档已有测试覆盖 external range CAS 与 stale
  rejection。
- RED 先出现于缺失 transfer ABI；随后 native probe、core、两消费者转绿。当前证据：
  `verify_composable_data_transfer_native.sh` 创建真实窗口并通过 copy、外部 paste、超限、取消与来源读回；
  `shared_operation_core cjpm test --skip-script` 51/51；`rule_set_window_app` 7/7；
  `shared_document_window_app` 8/8；runtime 和两个应用 `cjpm build --skip-script` 均通过。构建仅有既存
  `chmod`/`allowedFileTypes` deprecation 警告。
- `verify_framework_preview_consumption.sh` 已在含空格的临时路径导出、搬迁并从 exported preview 重建。
  新的独立 `Data Transfer Consumer` 只导入公开 `cjgui` 与 `cjgui_shared_operation_core` 包，实际启动普通
  应用宿主，并通过文本 copy/paste、结构化 copy/drop 读回 `hello` 与 `record-42`；导出 payload 和该消费者均
  不含 native 私有符号。临时导出树已由验证入口清理。
- 正常规则集 bundle 已从当前源码重新构建并启动，窗口和自有临时数据可见。桌面自动化执行一次坐标 drag，未
  观察到任何 owner 事件或状态改变；该工具动作不能证明系统 drag callback，因此真实 bundle 的 copy/paste、
  drag、cancel 与“人类→外部→人类”连续链均保持 `not_run`。不得用直接 controller invoke 或 native probe
  替代该桌面证据。自有窗口在本轮结束时关闭。

### 复核闭环更新（2026-09-17，阶段仍继续）

- 旧的独立导出用例确实曾在 application 内直接调用 `owner.applyDataTransfer`，因此已改为仅由普通双窗口
  `CjguiMacosApplication` 的 pump 消费平台 FIFO；consumer 源码扫描拒绝 `.applyDataTransfer(` 和 private native/test
  seam。该静态约束仅防绕过，行为证据由下项独立保留。
- 最终公开导出使用 `CJGUI_PREVIEW_CONSUMPTION_KEEP_TMPDIR=1` 成功，证据根为
  `/private/tmp/cjgui-framework-preview-consumption.Ltv5Bp`，transfer manifest 为该目录
  `data-transfer-preview.manifest`。原始 run 输出明确为 `mode=clipboard`、`platform_drop=false`，并报告
  `platform_copy=true`、`external_text_paste=true`、`fifo_dispatch=true`、`target_projection=true`、`text_value=external-text`、
  `structured_value=record-42`、`rejected=0`，且 source/target 为两个不同的公开窗口 session。外部驱动先以
  System Events 的 `AXRaise`/`AXMain` 确认真正 key window，再点击控件并发出 Cmd-C/V；这是一条受控桌面自动化
  窗口→AppKit→FIFO→仓颉校验→owner→公开读回链，不是人工物理键盘证明。
- 此前 structured copy 的 RED 原因是任意 MIME 被直接当作 `NSPasteboardType`，例如
  `application/vnd.cjgui.preview.transfer.record` 不是有效 UTI。native 现将非 `text/plain` 的有界 ASCII format
  无损映射为带 UTF-8 字节十六进制后缀的私有 `org.cangjie.cjgui.transfer.*` UTI，并仍随 metadata 传递原 format；
  structured native probe 已用自定义 format 从 RED 转绿。非文本 Cmd-C/V 还只在当前 scope 声明该 shortcut 时进入
  command FIFO，未声明的 C/V 才交给 transfer；文本 responder 继续优先，并保留 disabled scope 的一次拒绝。
- native probe 可以证明真实 AppKit source drag session 的 `mouseDown → threshold → beginDraggingSession`，但尚未
  证明 source 到另一窗口 target 的 `draggingEntered/performDragOperation`。当前 CUA 桌面尝试也已实际触发这三个
  source 边界；目标未收到 entered/drop，按 Esc 后可再次启动，故暂归为自动化坐标/跨窗目标未解析，不能写成 drop 成功。
  受控 native probe 已新增三组 RED→GREEN 边界：生产 `draggingEntered → prepareForDragOperation →
  performDragOperation` 以 test-owned dragging info/pasteboard 接收有界 structured payload 后，FIFO 依次发出 hover enter、
  drop、hover leave，并由 native probe 读回相同 format/payload；该 probe 尚未进入 Cangjie window 或业务 owner，
  只是 destination callback→FIFO 的受控证据，不是跨窗 AppKit 派发。另有生产 `draggingExited` 后仅有 hover enter/leave、随后 FIFO 无 PASTE/DROP；hover 后提交删除 target
  的新 scene 会清 native hover slot，旧 target 的 paste fail-closed。它们都不是人工或跨窗 target callback 证据。新增的
  exported public RED→GREEN 用例还确认：声明存在而 endpoint 初始 disabled，
  或已接受 endpoint 在普通刷新后变为 disabled，均不会令整个 window/projection 失败；后者会撤销该 generation 的
  transfer binding。其 `data-transfer-disabled-binding.log` 与 manifest 的 `disabled_endpoint_rebind=true` 位于上述证据根。
  同一公开窗口随后以真实 AppKit Cmd-V 验证禁用期 `0` 次 owner event、启用后 `1` 次 owner event；原始
  `data-transfer-disabled-platform.log`/driver log 与 `disabled_endpoint_platform_paste_rejected=true` 共同保留。
  普通双窗口 Cmd-C/V driver 也使用同一保护：外部文本粘贴后先检查 clipboard 的完整内容与 change-count，只有仍为
  测试值才执行结构化 source copy；随后仅在 general pasteboard 仍精确等于该测试 source item 时恢复完整快照。
  最新两段 driver 都报告 `cjgui_clipboard_guard restored=true`；遇到用户期间复制则放弃后续 source copy 或恢复而不覆盖它。
  这仍不是 disabled 状态下 drop 的通过。下一步仍须完成同进程跨窗口 drop、外部文本 drag/drop、modal、目标关闭与过期
  identity 拒绝，以及小/中/近上限 payload hover 的重复工作、释放和另一窗口推进。规则集/共享文档也仍需用真实窗口
  输入与已授权外部调用共同读回既有业务 executor；当前 core/domain tests 不替代这条接续。


## 指导复核与继续实施（2026-09-17）

### 13:51 UTC 锁屏后的继续实施

本轮结束不能把锁屏变成全阶段停工条件。指导只读查看 destination probe 和 trace：native probe 的受控 drop 目前止于 native FIFO 的 event/format/payload 读回，没有进入真实仓颉业务 owner；trace 已有 target entered/node 14，而无 prepare/perform。无 release/drop 回调只能说明未观察到完成派发，尚不能确定是工具没投递 mouse-up，须保留这一归因边界。共享文档 v1→窗口改动 v2→公开外写 v3 是执行报告的分项进展，最后窗口接手仍未验；不因补写文档改变该状态。

继续同一完整阶段，桌面依赖项挂起，其余明确交付现在推进：Terra 完成受控 destination→FIFO→仓颉窗口→实际 owner→公开读回的连通及 modal/关闭/目标换绑/过期事件拒绝，检查队列满和部分副作用的失败语义；不再仅在 native probe 手动取出 event 就声称业务接受。Luna/high 复用独立工作包，测实际 transfer 路径的小/中/512KiB payload、重复 hover 的读取/解析与 build/layout 次数、一次接收、队列/accepted/candidate/source 持有量及 drain/cancel/close 后收敛；先有针对性复现，确有缺陷才最小修复，不新增业务容量或第二缓存。两者同 target 构建串行，系统拖动 tracking 公平性与受控队列公平性分别报告。

锁屏影响的系统 drop、外部来源拖入、规则窗口和文档末次接手仅保留精确人工/桌面欠项；不能为它们改系统设置、放宽生产入口或重复撞工具。已有 clipboard 证据继续保留，当前阶段代码与必要验证完成后再一次正式导出。只有独立工作也全部完成或有具体阻塞时才停止，并主动报告指导；不再只要求用户解锁就结束尚有可做工作的执行轮次。

### 12:57 UTC 接续决定

执行轮次结束但阶段未完成。指导在本次接续开始时只读核对 `Ltv5Bp` 的 manifest、普通双窗口与 disabled 原始运行日志：clipboard 路径读回 `external-text`/`record-42`，禁用期 owner events=0、启用后=1；当时导出 ui/window/host/session/native m/h 六项与工作区逐字节一致。接受这些分项证据，不重跑已通过的全套导出，也不接受整阶段完成。下面首次复核的直接回调、快捷键不可达和证据树删除是历史发现，已由上面的新实现与当前产物覆盖；drop、业务接续与成本欠项继续有效。

本次继续完成同一个完整阶段，分两条独立工作包：Terra 负责跨窗拖放平台路由、失效/生命周期及主线程推进；Luna 负责规则/文档正常窗口与真实公开调用的共同编辑接续，再完成方案明确的 payload 成本与最终消费整理。不要让 Luna 等跨窗 drop 才开始可独立验证的 paste/公开调用业务链，也不要因一个检查通过就结束整轮。

拖放诊断必须从当前断点分叉定位：source session 已启动但 target callback 未出现，还不能归因为坐标或自动化。先在同一自有双窗正常实例记录源/目标窗口号和可见区域、实际鼠标屏幕位置/坐标换算、拖动 pasteboard types、目标 view 已注册 types、回调入口计数及 tracking 时段调度进展。日志在回调入口、命中/类型过滤前记录，以区分完全未派发和派发后拒绝。用同一目标做独立外部文本拖入对照，再核查同进程 source 的传输类型及 driver 是否持续投递 drag/up。受控 target callback→FIFO→window→owner 可独立证明接收路径，必须标注受控，不能代替系统跨窗派发。若证据表明 tracking 嵌套循环使唯一 owner pump 无法推进，先上报具体调用栈/运行模式和最小复现，由指导定方案，不在 callback 里临时递归 pump。失败累计不因轮次重置。

当前 trace 复现使用自有临时 current-source bundle `/private/tmp/cjgui-data-transfer-trace.GrFRax/app`，原始
`drop-trace.log` 保留。`CJGUI_DATA_TRANSFER_TRACE=1` 记录 target 注册、source 鼠标/屏幕坐标和所有 target callback
的过滤前入口；初始两个 native window 都是 frame `546,540,420×252`，即重叠。一次 CUA source drag 记录 source
`begin` 的屏幕点 `(337,535)`、`ended` 的 `(1156,660)`、`operation=0`，且没有 `target entered/prepare/perform` 行。
因此当前精确结论只是：该 CUA 坐标转换没有把当前 drag 投递到已注册 target，不能据此判定 destination 路由、类型过滤或
owner pump 已失败。trace 是 current production 源码新增的环境门控诊断，故 `Ltv5Bp` 只保留为接续前 clipboard 分项证据，
不再声称等同 trace 后源码；本阶段最终导出应重新绑定当前源码。

后续 native RED→GREEN 先修正了可复现的普通多窗口遮挡：同一小尺寸配置的第二个 visible window 现在优先占用首窗相邻、
完整可见且不相交的屏幕 slot，拥挤或大窗口仍保留 centered fallback；不增加公共坐标 API。`/private/tmp/cjgui-data-transfer-window-layout-red.log`
保留旧 `disjoint_window_frames` RED，`/private/tmp/cjgui-data-transfer-window-layout-green.log` 以两个 native session 转绿。
在这版源码重建的同一自有 bundle 中，source/target frame 分别为 `546,540,420×252` 和 `990,540,420×252`，详见
`/private/tmp/cjgui-data-transfer-trace.GrFRax/drop-trace-layout.log`。一次 CUA structured drag 现真实进入 target 的
`draggingEntered`：target 收到正确 private structured UTI 与 metadata type，并在过滤前命中 node 14；因此此前“没有
进入目标”的断点已关闭。但 CUA `drag` 没有令 native source 收到 `ended`，也没有出现 `prepare/perform`，target 在 90 秒
自有 probe 期间重复 entered 后超时；这只能标为未观察到 release 后的完成派发，尚不能归因于工具是否投递 mouse-up，不能称实际跨窗 drop 或 owner 写入成功。

另外，`/private/tmp/cjgui-data-transfer-controlled-drop-red.log` 保存 helper 未实现的链接 RED，
`/private/tmp/cjgui-data-transfer-controlled-drop-green.log` 现证明 production `draggingEntered → prepareForDragOperation →
performDragOperation` 经 test-owned dragging info/pasteboard 发出 hover enter、DROP、hover leave，并由 native FIFO probe 读回
同 format/payload；它没有给 Cangjie owner 读回。它仅拆解 destination callback→FIFO，不代替上述跨窗 AppKit dispatch。

### 受控正常窗口至真实文档 owner（当前源码）

新增 `native/scripts/verify_composable_data_transfer_window_integration.sh` 与其 test-only probe；它将 renderer 仅以
`CJGUI_INTERNAL_TESTING` 重新链接，生产 Cangjie window、native FIFO、binding/format 校验和 `CjguiTextDocumentWorkspace`
仍走原实现，公开消费者与导出不含该符号。`/private/tmp/cjgui-controlled-window-chain-green.log` 的
`CJGUI_CONTROLLED_DROP_WINDOW_CHAIN first=true cancel=true rebind_old=true rebind_new=true disabled=true closed=true ... passed=true`
证明：受控 destination callback 的 DROP 经 window `pump` 写入既有 range owner；同一 owner 由已授权的
`READ_RANGE` wire-protocol dispatcher 精确读回。`draggingExited` 仅留下 hover 生命周期而不再写入；旧 node、禁用 target
在 native 入 FIFO 前拒绝，换绑后的新 node 才能再由同一 owner 接收，关闭后 Cangjie session token 为 `0` 且 `pump` 不再打开。
此 readback 是进程内公开协议 dispatcher，不是新的 Unix-socket/desktop 行为证明；此整段仍是 test-owned dragging info，
不代替系统跨窗 `NSDraggingSession` 派发、物理输入或最终人工 drop。

保留 `Ltv5Bp`，只在后续生产变更或新增消费者需要时验证受影响部分；阶段收尾再保留最终对应产物。当前 ACTIVE 的最新路径应与本节一致。完成或带精确证据的结构阻塞主动报告；仅工具不可用时继续独立工作，不要求用户重复授权。

本轮有可复用代码进展，但**完整阶段未完成**。指导只读确认transfer值契约、窗口候选声明与native剪贴板/drag source/destination源码、两类owner适配已存在；未亲自重跑执行报告的51/51、7/7、8/8，具体原始日志由执行补入。阶段继续由原Terra/Luna组合交付，不再加一套新API或换新方向。

### 业务消费者与 payload 成本接续证据（2026-09-17）

- 共享文档消费者已完成一次真实正常窗口接续：同一个运行实例先通过公开 UDS `invoke 0 INSERT_TEXT --target 7101` 写入 `external-seed`，再用公开 `get --target 7101` 读回 `documentVersion=1`、`byteLength=150`、`selectionStart=0`、`selectionEnd=13`；随后在真实窗口文本框执行选区复制、点击“粘贴到选区”并发送 Cmd-V，窗口状态读回“已接收传输文本：v1”。粘贴的是同一选区，故这次验证刻意不宣称文档版本或内容发生二次变化；它证明正常窗口事件进入既有 transfer owner，而非测试侧直接调用 owner。外部调用原始输出保留在本轮运行记录中。
- 共享文档的 128 B、4 KiB、512 KiB 一次交换和 128 次空闲 `refreshIfNeeded()` 的针对性成本探针通过：`CJGUI_DOCUMENT_TRANSFER_COST sizes=128,4096,524288 repeats=128 idle_build_delta=0 idle_layout_delta=0 idle_submit_delta=0 elapsed_ms=2 passed=true`。规则集消费者同样通过其结构化记录小/中/近上限 fixture（payload 98/325/583 B）和 128 次空闲刷新：`CJGUI_RULE_TRANSFER_COST sizes=98,325,583 repeats=128 idle_build_delta=0 idle_layout_delta=0 idle_submit_delta=0 elapsed_ms=2 passed=true`。这两条只证明 offer 尺寸、重复空闲投影和窗口提交计数边界，不把 `elapsed_ms` 当端到端输入延迟，也不把规则集 fixture 的 583 B 误写成通用 512 KiB 上限。
- 可复查原始日志：文档测试 `/private/tmp/cjgui-document-transfer-cost-test.log`、规则测试 `/private/tmp/cjgui-rule-transfer-cost-test-final.log`；构建 `/private/tmp/cjgui-document-transfer-cost-build.log`、`/private/tmp/cjgui-rule-transfer-cost-build.log`；成本运行 `/private/tmp/cjgui-document-transfer-cost-run.log`、`/private/tmp/cjgui-rule-transfer-cost-run.log`。两消费者测试分别为 9/9、8/8，构建成功，`git diff --check` 通过；本轮未运行正式 preview export。
- 规则集尚未补真实正常窗口的 paste 事件读回；两消费者均未验证同进程跨窗口系统 drop、外部文本 drag/drop、人工物理输入、modal/close/过期 identity、payload 峰值分配/释放以及另一窗口在系统 tracking 期间的推进。因此本节不改变“完整阶段未完成”，也不解决跨窗口 drop。

### 共享文档的当前正常窗口接续（2026-09-17，桌面自动化）

- 旧的“同一选区复制/粘贴”只证明 copy acknowledgement，不能证明一次不同目标的 owner 变更；本条以当前源码的自有内存文档窗口替代该不足。公开 UDS 先以 `INSERT_TEXT` 在 `7101` 的 `v0`、UTF-8 byte `0` 写入 `E2E-SEED|`，返回 `v1`；公开 `read-range 7101 0 9 1` 精确读回该值，窗口 AX 同步显示 `v1` 与 `0..9` 选区。
- CUA 随后使用真实画布指针拖选而非 AX 写选区：源端选择 `0..8`，在“复制选区”端点使用 Cmd-C；再以指针选择不同的 `12..24` 目标范围，在“粘贴到选区”端点使用 Cmd-V。窗口 AX 显示 `已接收传输文本：v2`，公开 `get` 的 documentVersion 为 `2`、byteLength 为 `142`，`read-range 7101 0 142 2` 读回含 `E2E-SEED|第E2E-SEED实际输入…` 的实际替换内容。这是 normal window → AppKit clipboard → native FIFO → Cangjie transfer provider → 既有 range owner → 公开读回，不是 test seam 或直接 `applyDataTransfer`。
- 同一实例又经公开 `INSERT_TEXT` 以 expected `v2` 在 byte `142` 写入 `|EXT2`，返回 `v3`，公开 `read-range 7101 142 147 3` 读回 `|EXT2`；窗口 AX 同步显示 `v3`、`142..147` 与可见后缀。原定用窗口替换这段后缀、再公开读回的“人工再次接手”步骤遇到 macOS 锁屏，CUA 不能自动解锁，故明确为 `not_run`，不以此前的窗口 paste 替代。整个窗口由本轮启动且没有 `--file`，未写入用户文件；退出后进程已结束，原运行目录的 Unix socket 已不在，唯一临时连接目录已移入废纸篓。

### 2026-09-19 接续执行记录（外部执行 AI）

- **受控窗口链转绿并扩覆盖。** `verify_composable_data_transfer_window_integration.sh` 全绿
  （run-10、run-16：`/private/tmp/cjgui-controlled-window-payload-run-{10,16}.log`）。三个 RED 的根因都是
  探针断言与生产契约不符，不是生产缺陷：① near-limit 512 KiB drop 被 owner 以 `document_too_large`
  fail-closed 拒绝（workspace 文档总量上限 = 512 KiB，`shared_text_document.cj:6`），探针改为整文档替换
  （0..len → payload，结果恰在边界）；② 双事件 drain 的断言"一 pump 一事件"错误——drain 预算 64，
  单 pump 排空整个队列，改为断言单 pump 内 accepted+2、FIFO 清空、公开读回尾部 `queue-b`@v5；
  ③ overflow 的内容期望在拒绝轮也被推进（级联），改为仅 accepted 后推进。retention 断言修正为
  "close 前仅存活声明"（source=current payload、candidate==accepted），Luna 独立探针的
  `source/accepted/candidate==0` 原断言不可满足。
- **队列满覆盖补齐。** 65 个 drop 竞争 64 槽 FIFO：21 个 drop（enter+drop 对）入队并被 owner 逐一应用、
  44 个在原生目标边界拒绝（状态 15）、queue-full notice 在排空后送达且恰一次 reject、FIFO 事件与字节收敛 0、
  内容恰为 "Qx"。探针控制器 `documentId` 参数化；`contentIs` 补 documentId 形参（原硬编码 7301 在压力文档
  上恒 false）。
- **Luna 探针整合。** `composable_data_transfer_payload_probe.cj` 与其脚本删除：其 readback 从 0 读全文会
  超 READ_RANGE 64 KiB 协议上限（集成探针读变化后缀），唯一增量（close 后 retention）已并入集成探针。
- **文档消费者真实窗口完整链（脚本化、全绿）。** 新增
  `native/scripts/verify_shared_document_transfer_chain.sh`：同一实例六步——外部授权 INSERT（v0→v1，公开
  读回 139 字节）→窗口真实点击编辑器+全选+剪贴板粘贴（v1→v2，公开读回）→外部 REPLACE（v2→v3）→
  窗口 AX 证实显示外部改动后窗口再编辑（v3→v4）→声明端点传输：全选+复制选区+Cmd-C、光标折叠到末尾+
  粘贴到选区+Cmd-V（v4→v5 "W4W4"，公开读回）→外部 REPLACE（v5→v6）且窗口 AX 显示。剪贴板守卫
  （快照+条件恢复）全程保护。要点：方向键用 `key code`（`keystroke "Up"` 会触发 Cmd+P 打印面板）、
  粘贴优于键击（中文输入法组合会吞按键/变形标点）、真实点击用 CGEvent（System Events 元素 click 仅 AXPress）。
- **规则消费者。** 公开 UDS `CREATE_RECORD`（label=外部E2E 等 5 参）APPLIED，GET_CONTEXT 出现 resource 1
  外部E2E；窗口复制/新增按钮兼作直接业务命令，窗口侧传输的产物归因未隔离（复制走 COPY_RECORD 直改），
  记录为待办。
- **当前源码回归。** shared_operation_core 51/51、rule_set_window_app 8/8、shared_document_window_app 9/9、
  根 `cjpm build --skip-script` 通过（日志 `/private/tmp/cjgui-{soc,rule,doc}-test-current.log`、
  `cjgui-root-build-current.log`）。
- **跨窗系统拖放仍未打通。** 新增 `verify_composable_data_transfer_cross_window.sh` + 双窗 bundle 应用
  （CjguiMacosApplication 两窗、源/目标声明齐全，AX 可见、布局不相交）；CGEvent HID 拖动
  （60 步 20ms/步）未触发 NSDraggingSession（trace 零 source begin），与 09-17 CUA 现象同族。
  工具与脚本保留可重试。
- 权限事件：本机中途授予辅助功能（此前 osascript 被 TCC 拒绝 -25211）。截图权限仍缺。

### 2026-09-19 第二轮：跨窗拖动打通 + 规则归因隔离

- **同进程跨窗口系统拖放打通（此前 09-17 起的最大欠项）。**
  `verify_composable_data_transfer_cross_window.sh` 从模板生成双窗 bundle 应用
  （`CjguiMacosApplication` 两窗，A 声明源 "DRAG9"、B 声明目标），run.sh 构建启动，
  AX 定位两窗按钮，CGEvent combinedSessionState 真实鼠标拖动
  （down→60 步 dragged→up），目标 owner 收到 `drops=1 payload=DRAG9 passed=true`
  （`/private/tmp/cjgui-composable-data-transfer-cross-window/probe.log`）。
  打通要诀：裸可执行对 AX 不可见必须打包成 bundle；System Events 元素 click 仅 AXPress
  启动不了拖动；CGEventSource 必须用 combinedSessionState；拖前先 click 一次激活。
  该脚本从生成到验证一条命令可复现。
- **规则窗口侧传输归因隔离。** 干净实例：外部 CREATE_RECORD "TRANSP1"→APPLIED；
  窗口链 选择→复制→Cmd-C→新增→Cmd+V 后公开上下文出现 4 条记录：id1 TRANSP1（外部）、
  id2 "副本 2"（复制按钮直接业务复制）、id3 "新规则 3"（新增按钮直接创建）、
  **id4 "副本 2"（Cmd+V 传输粘贴创建，标签等于 Cmd-C 时复制的记录，与直接新增命名
  "新规则 N" 规则不同）**——传输产物与业务直改可区分，归因成立。
- 文档消费者六步链、受控窗口链、队列满压力、当前源码回归（51/51、8/8、9/9、根构建）
  均见上一节与 2026-09-19 第一轮记录。

### 2026-09-19 第二轮收口：正式导出完成

- 最终含空格正式导出成功（KEEP_TMPDIR=1）：证据根
  `/private/tmp/cjgui-framework-preview-consumption.khfDY2`，汇总
  `cjgui_framework_preview_consumption=ok`，六消费者
  ui_only/collaboration/document=build，image_multiwindow/command_menu/vector/
  **data_transfer=build_and_run**；`relocated_with_spaces=ok`；
  data_transfer 标记 platform_window/external_text/structured/fifo/
  identity_readback/disabled_endpoint_rebind/disabled_endpoint_platform_paste_rejected
  全 true 且 `native_private_copy=false`；source 与 preview payload 同为
  `426ea3c7…871eee`（transfer manifest 与 run/driver 日志在该目录）。
- 本轮新增可复现脚本：`verify_shared_document_transfer_chain.sh`（文档消费者六步链）、
  `verify_composable_data_transfer_cross_window.sh`（双窗应用+CGEvent 拖动）、
  探针新增队列满压力段与 retention 收敛断言。
- 外部应用文本拖入：已尝试 TextEdit（选中 EXT-DRAG-TEXT，两轮调参 CGEvent 拖入目标按钮）未在其侧
  建立拖动会话；目标侧代码路径（读 public.utf8-plain-text）与同进程跨窗一致，此项如实保留为
  "支持已实现、外部源实拖未演示（工具受限）"。仍未验边界照旧：人工物理输入、系统 IME/VoiceOver、
  实际 GPU 呈现时延、安装/公证/发布。

### 确定的验收缺口

1. `probe/framework_preview_data_transfer_consumer.cj` 的verifyDataTransferConsumer直接构造layout node与DataTransferEvent，再调用owner.applyDataTransfer四次。因此只证明公开类型可消费和业务回调有效，不能标为正式窗口的copy/paste/drop传输成功；启动application不会把这些直接回调变成平台输入。保留该值/回调用例，但另接正常窗口入口，至少受控系统回调→native FIFO→Cangjie窗口匹配/校验→owner→公开读回，不绕过window直接调用owner。导出应用不能依赖私有native符号；受控驱动可在外部测试侧，应用仅用公开API。真实桌面结果单列。
2. 当前native probe明确位于Cangjie业务边界以下，不能和上述直接owner回调拼接成已经打通的端到端。两正常应用与真实UDS接续需同一进程内具体字段/对象前后读回，不能只引用domain unit tests。人paste/drop与外部CREATE_RECORD/REPLACE_RANGE等实际发布动作是否共用业务校验和执行器，用公开调用证明，无需为此发明第二传输协议。
3. 桌面坐标drag没有owner事件，根因未定；不能归为必需真人鼠标。Terra在正常入口做有界追踪：mouseDown命中与按压身份→mouseDragged阈值→offer/系统drag session启动→target entered/updated→performDrop→入队结果→pump接受/拒绝→owner。先区分工具事件没到、坐标/窗口遮挡、声明未绑定/代际失效、平台拖放与runloop模式问题，不能不断换坐标或放宽身份检查。若工具确实无法触发系统拖放，保留工具证据和最小人工步骤，同时把受控完整窗口链路做通。仅此环境欠项不阻塞独立代码/消费者工作。
4. 最终导出树已被cleanup删除，不能复查当时payload与实际消费者。已有driver日志如还在先保留并引用，不为丢失产物立即反复导出。当前代码和入口修复完成后，用现有 `CJGUI_PREVIEW_CONSUMPTION_KEEP_TMPDIR=1` 保留一次最终导出、manifest、build/run日志和源码/二进制指纹；清理实例和endpoint，不清验收证据。不能再把删除的路径写为可复查当前产物。

### 本阶段其余工作一并完成

09-17 后续指导只读确认：native `keyDown` 在非文本 transfer 分支前调用 `handleWindowCommandKeyDown`，其归一化接受 Cmd+C/V，FIFO 入队成功后提前返回，导致后面的 transfer 快捷键路径正常情况下不可达。Terra 负责统一路由与声明命令/文本 responder 的优先级，不能仅无条件提前 C/V；精确修饰键、disabled/scope、一次派发和失败边界均需保留。Luna 补正常 window/responder→FIFO→仓颉校验→owner 的完整消费验证。禁止直接回调的静态扫描只能防绕过，不能替代行为证据；当前 RED 不属于通过。此项属于本阶段继续实施，独立拖放与消费者工作不停止。

- 按原范围补普通同进程跨窗口、外部文本拖入、leave/cancel、disabled/modal、drag期间目标删除/换绑/close和过期scene拒绝，确保取消不改变owner；已有用例查到真实对应证据则不重跑。重点核查平台drag嵌套事件阶段视觉hover是否实际显示、是否使另一个窗口/公开调用永久饿死。禁止在平台回调里另跑owner或形成双状态机。
- 原要求小中大场景的drag hover重复工作、payload峰值与释放、实际计时尚未见报告。沿当前实现给有针对性证据：同目标hover不重复读取/解析payload、不逐像素build/layout；drop才一次接收，异常/关闭释放有界，另一窗口推进。不得用此前普通hover的样本代替新transfer payload路径，也不无故重跑所有历史矩阵。
- 正常copy/paste可独立于系统drag先验证；不因为drag工具失败就把全部桌面行为一起留空。文本Cmd-C/X/V优先、选区/IME保持只按已有系统集成边界回归。至少一个已有应用完成同A窗口→公开外写→窗口接手，若确实受环境限制，记录精确阻塞并给受控完整链路。
- 失败边界、构建、声明/FFI扫描和最终公共导出一起收口。不修一处回调就停、不只补文档。Terra负责平台生命周期/普通窗口事件路径判断，Luna负责明确的两类业务消费者/完整窗口链路验证和导出证据包；同target串行，原生父子消息，不把Luna常规进度发指导。阶段内验收已授权，无需逐次求批准。三次有效失败或结构问题按现行规则升级，禁K3。
