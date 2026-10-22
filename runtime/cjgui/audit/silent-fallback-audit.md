# 静默 fallback 审计（包 B）

数据快照：HEAD `dc27dff`；未提交改动 239 条；快照时间 2026-10-21T04:42:43Z。
本报告基于未提交改动的工作区。源码只读，未运行构建/测试/应用。

原料：`audit/evidence/when-inventory.tsv`（458 条 `@When`）。先按条件筛选，再逐条回源码读分支体与消费点。引用行号为当前工作区行号（与清单一致），引用的代码行已截断到 120 字符以内。

结论摘要：三类共审阅 151 个分支，筛出 41 条静默 fallback（按分支计，去重后 32 个函数实现）：影响可见功能 5 条、影响诊断 14 条、仅影响极端路径 22 条、待确认 0 条。最集中的是 owner trace 家族（10 条诊断缺口）与 selection-paint/pointer-FIFO 两个可见缺口。

## 口径

- **静默 fallback**：分支体只返回成功类/默认值（`OK`、`true`、`0`、`false`、`None`、空数组、全零结构）、或只做空实现，调用方从这次调用里无法知道本平台没有该能力。
- **不计入静默**（单独计数，见各节“未计入”）：
  - 具名错误码（`CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED`、`SCENE_STALE`、`INVALID_ARGUMENT`、`INTERNAL_ERROR`、`-2` 等），调用方能感知失败；
  - 能力门（`*Supported()` / `*Version()` 返回 `false`/`0`），调用方本就据此分支；
  - 真实实现、委托给真实实现；
  - 语义上正确的空操作（例如没有对象可释放、没有前缀可取消、没有待处理输入），不构成功能损失；
  - 主树无调用者、且将来也不会被间接调用的空桩（只在“排除”里点名）。
- **`os != "macOS"` 的实际含义**：本清单里所有 `os != "macOS"` 兜底都只与 `@When[os == "macOS"]` 真实现成对出现（否则同一平台会重复定义）。因此 Windows、Linux 以及第四平台都会落进该兜底；不是只影响 Linux/OHOS。
- **OHOS 口径**：主树 `os != "macOS" && os != "Windows" && os != "Linux"` 分支当前不参与 OHOS HAP 编译（`platforms/ohos/scripts/sync_platform.sh` 从 `platforms/ohos/snapshot/src` 取源码，快照不含 `@When`）。第一节的后果按“主树直接编译第四平台（含未来 OHOS 主树 target）”计，不是当前 OHOS HAP 的已发生缺陷。第四平台目前也不是完整 target：`src/application_host.cj` 没有第四平台的宿主工厂/停止入口，主树直接出该 target 会先编译失败；本节只评已存在的兜底分支本身，不把“能编译”当前提。
- **同函数多平台分支分别计数**：例如 `internalRendererConsumedPointerFifo` 在 Linux 与第四平台各有一条静默落点，统计里算 2 条，但只对应 1 个函数。

## 一、`os != "macOS" && os != "Windows" && os != "Linux"`（OHOS/第四平台兜底）

清单 22 条；静默 14 条，其余 8 条见节末。

### `src/composable_ui_mac_retirement.cj:25` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L27 `return (CJGUI_INTERNAL_RENDERER_OK, true)`
- 消费者会看到什么后果：准备阶段永远得到“没有真实回收可等，可以开始”，不会因为私有准备图还没退休而推迟；如果该平台将来有退休队列，内存压力下的准入背压被静默关掉。
- 严重度：仅影响极端路径

### `src/owner_turn_budget.cj:19` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L20 `func cjguiSchedulingWorkRevision(): UInt64 { return 0u64 }`
- 消费者会看到什么后果：`CjguiOwnerTurnBudget.begin` 记录的工作修订恒 0；依赖“修订变了 = 有新工作”的等待逻辑永远认为没有新工作。
- 严重度：仅影响极端路径

### `src/owner_turn_budget.cj:41` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L42 `func cjguiWaitSchedulingWork(revision: UInt64, deadline: UInt64): Int64 { return 0 }`
- 消费者会看到什么后果：`finishScheduling` 立即返回 0 idle；消费者若按 macOS 模式调用，本回合的“等原生工作”变成不等，可能忙轮询到下一轮。
- 严重度：仅影响极端路径

### `src/owner_turn_budget.cj:57` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L59 `value: UInt64, managedId: UInt64): Unit {}`
- 消费者会看到什么后果：owner trace 的阶段边界一条都不落；trace 里没有阶段耗时与前后关系。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:141` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L143 `startedNs: UInt64): Unit {}`
- 消费者会看到什么后果：legacy span 不记录；旧格式的 owner 阶段数据整段缺失。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:158` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L161 `return 0u64`
- 消费者会看到什么后果：owner trace 记录恒返回 0；`exportOwnerTrace()` 导出的记录里没有这些条目。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:172` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L173 `func cjguiOwnerTraceSetTurn(turn: UInt64): Unit {}`
- 消费者会看到什么后果：`CjguiOwnerTurnBudget.begin/end` 调用的回合号设置不落任何 trace；trace 记录无法关联到回合。结合同文件的 record no-op，owner 回合在 trace 里根本不存在。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:183` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L184 `func cjguiOwnerTraceExport(): Unit {}`
- 消费者会看到什么后果：`window.exportOwnerTrace()` 没有任何输出，调用方只能得到空结果。
- 严重度：影响诊断

### `src/runtime_renderer_session.cj:2128` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L2130 `return CjguiMacSliderPointerFifo(0u64, 0u64, 0u64, 0u64, 0u64, 0u32)`
- 消费者会看到什么后果：已消费指针 FIFO 恒全零；`CjguiMacSliderPointerFifo.follows()` 要求 `generation != 0`，于是恒假。实现 `CjguiComposableUiSliderCaptureProvider` 的消费者，在 lifetime/owner/binding 前置门都通过后，滑块 BEGIN 仍会在 FIFO 这关被 `freezeMacSliderCapture` 拒绝，滑块拖不动。
- 严重度：影响可见功能（条件触发：需消费者同时实现 `CjguiComposableUiPointerCaptureVersionProvider` 与 `CjguiComposableUiSliderCaptureProvider`；`examples/generated_collection/src/main.cj:105` 与 `templates/macos_application/mixed_form/src/main.cj:9-10` 正是此形态且含 slider。当前 Linux 验收消费者 `RangeTextWindowController` 只实现前者，不触发）

### `src/runtime_renderer_session.cj:3037` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L3038 `func internalRendererInstalledRangeReceipt(session: UInt64, nonce: UInt64): ?CjguiInternalInstalledRangeReceipt { None }`
- 消费者会看到什么后果：已安装区间回执永远读不到；依赖回执的完成票据无法成立。当前被 `internalRendererSourceRangeSupported()` 的 `false` 挡在前面，主树消费点不进入。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:3048` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L3050 `?CjguiInternalInstalledRangeReceipt { None }`
- 消费者会看到什么后果：活动区间回执同样恒 `None`；依赖它确认“当前安装的是哪一段”的路径拿不到凭据。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:3079` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L3080 `func internalRendererCancelInstalledRange(session: UInt64, nonce: UInt64): Unit {}`
- 消费者会看到什么后果：取消已安装区间不通知任何原生；该平台没有已安装区间时语义上无事可做，调用方无法区分“取消了”与“本来就没有”。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:3148` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L3149 `func internalRendererReleaseInstalledRange(session: UInt64, document: UInt64, binding: UInt64): Unit {}`
- 消费者会看到什么后果：释放已安装区间是空操作；没有原生持有可释放时无害，但也无法据此判断平台是否支持区间安装。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:3208` — `os != "macOS" && os != "Windows" && os != "Linux"`
- 返回：L3210 `binding: UInt64, scene: UInt64): (Bool, ?InternalRendererInstalledRangeClaim) { (false, None) }`
- 消费者会看到什么后果：事件 51 的已安装区间永远领不到，只能走普通事件路由；编辑仍可用，但没有区间安装的增量回执。
- 严重度：仅影响极端路径

本节未计入（8 条）：
- `src/owner_turn_budget.cj:28` — `cjguiCommonSchedulingEnabled` 返回 `false`，能力门，调用方据此选择等待策略。
- `src/runtime_renderer_session.cj:2143` — 选区背景版本返回 `0`；下游 `composable_ui_window.cj:9952-9956` 以 `reason: "selection_background_backend_unsupported"` 具名拒绝整个候选场景，不是静默。
- `src/runtime_renderer_session.cj:2640` — `internalRendererSourceRangeSupported` 返回 `false`，能力门。
- `src/runtime_renderer_session.cj:3026` / `:3070` / `:3159` — `TEXT_SERVICE_UNSUPPORTED`，具名错误。
- `src/runtime_renderer_session.cj:3420` — 委托 `internalRendererPrepareComposableNodeBatchScalar`，真实实现。
- `src/runtime_renderer_session.cj:3460` — 返回 `(TEXT_SERVICE_UNSUPPORTED, 0u32)`，具名错误。

## 二、`os != "macOS"`（macOS-only 能力，Windows/Linux/第四平台同落点）

清单 105 条；静默 17 条。其余 88 条中：具名错误 57、能力门 7、真实现/委托/无后果 24，节末列代表项。

### `src/composable_ui_font_resource.cj:289` — `os != "macOS"`
- 返回：L291 `return [0u64, 0u64, 0u64, 0u64, 0u64]`
- 消费者会看到什么后果：字体诊断恒全 0，看起来像“从未注册、从未命中”；无法区分“平台不支持字体资源”与“支持但没有活动”。
- 严重度：影响诊断

### `src/composable_ui_mac_edge_scroll.cj:55` — `os != "macOS"`
- 返回：L58 `return CJGUI_INTERNAL_RENDERER_OK`
- 消费者会看到什么后果：拖拽边缘的视口 ACK 报告成功，但没有调用任何原生。`composable_ui_window.cj:6557` 会据此建立等待票据；该票据之后只能靠 `terminate` 清掉。
- 严重度：仅影响极端路径

### `src/composable_ui_mac_edge_scroll.cj:69` — `os != "macOS"`
- 返回：L71 `return CJGUI_INTERNAL_RENDERER_OK`
- 消费者会看到什么后果：失败边缘请求的“终止”报告成功，但没有通知原生；清理路径以为自己收尾了。
- 严重度：仅影响极端路径

### `src/composable_ui_preparation_reuse_integration_test.cj:211` — `os != "macOS"`
- 返回：L212 `private func preparedActualLegacyFrameCheckCount(window: CjguiComposableUiWindow): UInt64 { return 0u64 }`
- 消费者会看到什么后果：测试探针恒 0；非 macOS 构建里“帧资源检查次数”没有真实基准值。
- 严重度：影响诊断

### `src/composable_ui_preparation_reuse_integration_test.cj:219` — `os != "macOS"`
- 返回：L220 `private func assertPreparedLegacyFrameChecksUnchanged(window: CjguiComposableUiWindow, before: UInt64): Unit {}`
- 消费者会看到什么后果：断言是空操作；“帧资源检查次数不变”在非 macOS 上根本没验，测试仍然绿。
- 严重度：影响诊断

### `src/composable_ui_selection_paint.cj:143` — `os != "macOS"`
- 返回：L145 `return CJGUI_INTERNAL_RENDERER_OK`
- 消费者会看到什么后果：选区安装完成被当作“已发布 owner”，但 Windows/Linux 没有原生代理发布。后续链路按已发布继续；选区要可见，只能靠消费者自己用 `selectionBackground` run 画。
- 严重度：影响可见功能

### `src/composable_ui_selection_paint.cj:160` — `os != "macOS"`
- 返回：L162 `proxyOnly: Bool): (Int32, Bool) { return (CJGUI_INTERNAL_RENDERER_OK, false) }`
- 消费者会看到什么后果：`finish` 报告成功且“不需要额外刷新”；Linux 上实际没有任何原生绘制，选区保持不可见，除非消费者自行投影。
- 严重度：影响可见功能

### `src/composable_ui_selection_paint.cj:173` — `os != "macOS"`
- 返回：L175 `scene: UInt64): Int32 { return CJGUI_INTERNAL_RENDERER_OK }`
- 消费者会看到什么后果：`stage` 报告成功但没有 stage 任何绘制。Linux 上通常走不到（`selectionPaint` 为 `None`）；Windows 由分段装饰路径另画，所以这条主要是“假成功”的隐患。
- 严重度：仅影响极端路径

### `src/composable_ui_window.cj:2666` — `os != "macOS"`
- 返回：L2667 `private func preparationCorrelationThread(): UInt64 { return UInt64.Max }`
- 消费者会看到什么后果：准备关联诊断行里的线程恒为 `unknown`；无法把一次准备关联到具体线程，跨线程问题无法从 trace 判断。
- 严重度：影响诊断

### `src/runtime_renderer_session.cj:2215` — `os != "macOS"`
- 返回：L2216 `func internalRendererOwnerPumpHasUnconsumedInput(session: UInt64): Bool { return false }`
- 消费者会看到什么后果：刷新不会因为队列里还有未消费输入而推迟；Windows/Linux 上可能在输入尚未消费完时继续投影。该平台没有 macOS 那套 owner pump 计数，只能按“没有待处理输入”处理。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:2340` — `os != "macOS"`
- 返回：L2343 `CJGUI_INTERNAL_RENDERER_OK`
- 消费者会看到什么后果：命令完成策略没有下发，但调用方收到成功；命令仍按旧严格输入路径执行，managed completion policy 在 Windows/Linux 不生效。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:2351` — `os != "macOS"`
- 返回：L2354 `CJGUI_INTERNAL_RENDERER_OK`
- 消费者会看到什么后果：命令 origin identity 没有下发，但调用方收到成功；`nativeBoundCommandDispatch` 拿不到 origin 绑定，命令只能走通用分发。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:2381` — `os != "macOS"`
- 返回：L2383 `None`
- 消费者会看到什么后果：已消费命令来源票据恒 `None`；`nativeBoundCommandDispatch` 直接放弃并回落通用分发。命令仍能执行，但没有 origin/声明 token 的绑定校验。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:3230` — `os != "macOS"`
- 返回：L3232 `deadlineNs: UInt64): (Int32, Bool) { (CJGUI_INTERNAL_RENDERER_OK, true) }`
- 消费者会看到什么后果：准备阶段立即报告帧资源已就绪，不等待任何原生资源；如果后端在提交时才申请资源，准备/提交两阶段退化为一步，提交阶段可能阻塞。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:3247` — `os != "macOS"`
- 返回：L3249 `projectionVersion: UInt64): (Int32, Bool) { (CJGUI_INTERNAL_RENDERER_OK, true) }`
- 消费者会看到什么后果：可绘制对象立即报告已预留，不等待 native lease；若 native 在提交时才取 drawable，预留语义名存实亡。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:5061` — `os != "macOS"`
- 返回：L5062 `func internalRendererCloseStopsNewOwnerWork(closePending: Bool, retryPending: Bool): Bool { return false }`
- 消费者会看到什么后果：关闭意图待定时仍返回 `false`（不停新工作）；Windows/Linux 的关闭走异步 dispatcher，关闭过程中可能多做一轮刷新/动画。
- 严重度：仅影响极端路径

### `src/runtime_renderer_session.cj:5384` — `os != "macOS"`
- 返回：L5386 `nodeIndex: UInt32, help: String): Int32 { return CJGUI_INTERNAL_RENDERER_OK }`
- 消费者会看到什么后果：语义帮助文本不会送到任何原生无障碍服务，调用方以为设置成功；Windows/Linux 当前也没有语义帮助的原生运输通道。
- 严重度：影响可见功能（辅助功能）

本节未计入（88 条）：
- 具名错误 57 条：主要是 selection transfer 家族（`internalRendererCreateSelectionTransfer` 到 `internalRendererDiscardSelectionTransferCapsule` 等 24 条）、source-handoff 5 条、owner handoff 6 条、installed-range 3 条、caret/modal/command-context 若干；均返回 `TEXT_SERVICE_UNSUPPORTED` 或 `SCENE_STALE`。
- 能力门 7 条：`internalRendererOwnerCommandReceiptSupported`、`internalRendererOwnerHandoffSupported`、`internalRendererResidentTextSourceSupported`、`internalRendererSupportsProxySelectionPaint`、`cjguiStyledTextSupportVersion`、`cjguiFontResourceSupportVersion`、`internalRendererAtomicModalReturnSupported`。
- 真实现/委托/无后果 24 条：包括 `internalRendererCommitInstalledSelectionCommands`（委托共同命令菜单提交）、`internalRendererRequestCloseBeforeDestroy`（委托 `RequestClose`）、`native_text_typography` 的 4 个真实测量入口，以及被能力门短路、主树没有调用者的 `CaretInputWasRetired`/`CancelCaretPrefix`/`ConsumedActivationPrefix`/`FreezePointerSelectionDispatch` 等。

## 三、`os == "Linux"`（含 `Windows || Linux` 并列支）

清单 18 条 `os == "Linux"`，另查 6 条 `os == "Windows" || os == "Linux"` 的 owner 计量/诊断并列支（第 7 条 `internalRendererComposableDisplayValue` 在第四节核实为真实现）；共 24 条。静默 10 条，其余 14 条见节末。

### `src/composable_ui_mac_retirement.cj:20` — `os == "Linux"`
- 返回：L22 `return (CJGUI_INTERNAL_RENDERER_OK, true)`
- 消费者会看到什么后果：Linux 的准备阶段永远“可以开始”，不等私有准备图退休；Linux 当前没有退休队列，所以结论正确，但调用方无法从返回值知道“没有队列”与“队列已排空”的区别。
- 严重度：仅影响极端路径

### `src/owner_turn_budget.cj:16` — `os == "Windows" || os == "Linux"`
- 返回：L17 `func cjguiSchedulingWorkRevision(): UInt64 { return 0u64 }`
- 消费者会看到什么后果：Linux 的 owner 工作修订恒 0；`CjguiOwnerTurnBudget.begin` 记录 0，调度计量不可用。
- 严重度：仅影响极端路径

### `src/owner_turn_budget.cj:38` — `os == "Windows" || os == "Linux"`
- 返回：L39 `func cjguiWaitSchedulingWork(revision: UInt64, deadline: UInt64): Int64 { return 0 }`
- 消费者会看到什么后果：Linux 的 `finishScheduling` 立即返回 0 idle；调用方若照 macOS 习惯调用，会立刻进入下一轮而不等待。
- 严重度：仅影响极端路径

### `src/owner_turn_budget.cj:53` — `os == "Windows" || os == "Linux"`
- 返回：L55 `value: UInt64, managedId: UInt64): Unit {}`
- 消费者会看到什么后果：Linux 的 owner trace 阶段边界不落记录；trace 里看不到阶段耗时。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:137` — `os == "Linux"`
- 返回：L139 `startedNs: UInt64): Unit {}`
- 消费者会看到什么后果：Linux 的 legacy span 不记录；旧格式 owner 阶段数据缺失。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:152` — `os == "Linux"`
- 返回：L155 `return 0u64`
- 消费者会看到什么后果：Linux 的 owner trace 记录恒 0；导出的 trace 没有这些记录。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:169` — `os == "Windows" || os == "Linux"`
- 返回：L170 `func cjguiOwnerTraceSetTurn(turn: UInt64): Unit {}`
- 消费者会看到什么后果：Linux 的预算 `begin/end` 设置的回合号不落到任何 trace；trace 里没有回合边界，记录无法按回合归组。
- 严重度：影响诊断

### `src/owner_turn_budget.cj:180` — `os == "Windows" || os == "Linux"`
- 返回：L181 `func cjguiOwnerTraceExport(): Unit {}`
- 消费者会看到什么后果：Linux 上 `exportOwnerTrace()` 没有输出；诊断导出为空。
- 严重度：影响诊断

### `src/runtime_renderer_session.cj:2123` — `os == "Linux"`
- 返回：L2125 `return CjguiMacSliderPointerFifo(0u64, 0u64, 0u64, 0u64, 0u64, 0u32)`
- 消费者会看到什么后果：已消费指针 FIFO 恒全零，`follows()` 恒假。同时实现 `PointerCaptureVersionProvider` 与 `SliderCaptureProvider` 的消费者在 Linux 上过了前置门后仍会在 FIFO 关被拒，滑块拖不动。`examples/generated_collection/src/main.cj:105` 与 `templates/macos_application/mixed_form/src/main.cj:9-10` 是此形态；当前 Linux 验收消费者 `RangeTextWindowController` 不实现 slider capture，不触发。
- 严重度：影响可见功能（条件触发）

### `src/runtime_renderer_session.cj:2610` — `os == "Linux"`
- 返回：L2612 `return InternalRendererInputProvenance(0u64, 0u64, 0u64, 0u32)`
- 消费者会看到什么后果：所有 pumped 事件的 provenance 全零，`inputSequence` 为 0；依赖非零 sequence 的 macOS 式插入符路由与驻留文本意图链整段跳过，事件改走普通分发。正文编辑仍走 installed-range/共享路径。
- 严重度：仅影响极端路径

本节未计入（14 条）：
- 能力门 5 条：`internalRendererSupportsPointerBeginOrigin`、`internalRendererPointerBeginFrameRetained`、`internalRendererInstalledRangeSupported`、`internalRendererSelectionTransferSupported`、`cjguiCommonSchedulingEnabled`（`os == "Windows" || os == "Linux"`）。
- 具名错误 2 条：`internalRendererPublishPointerBeginSource`（`TEXT_SERVICE_UNSUPPORTED`）、`internalRendererReuseComposableNodeBatch`（`TEXT_SERVICE_UNSUPPORTED, 0`）。
- 真实现/委托 4 条：`cjguiCreatePlatformApplicationHost`、`cjguiStopApplicationLoop`、`internalRendererSourceRangeSupported`（Linux `true`，native 已有 installed_range 生产端）、`internalRendererPrepareComposableNodeBatch`（委托 scalar 真实现）。
- 结构/无后果 3 条：`CjguiLinuxApplicationHost` 空扩展、类声明、`internalRendererConsumePointerBeginOrigin` 的 `None`（被 `SupportsPointerBeginOrigin=false` 短路）。

## 四、并列/互补分支抽查

- **三平台并列支没有“Linux 空实现”。** 清单里 19 条 `os == "macOS" || os == "Windows" || os == "Linux"` 全部是 foreign 声明、native 探针调用或委托（installed-range 8 处、selection background version、prepare/reuse batch 等）；Linux 落在真实现上，空值只出现在第四平台兜底。
- **`internalRendererComposableDisplayValue` 的空串协议不是缺陷。** `src/runtime_renderer_session.cj:3302`（`Windows || Linux`，送真实正文）与 `:3310`（`!= Windows && != Linux`，`preserve` 时送 `""`）成对。`""` 支覆盖 macOS 与 OHOS：macOS 的 AppKit 代理按空串协议保留原生正文；OHOS `platforms/ohos/host/ohos_renderer.cpp:13389` 也明确按 `preservesActiveLocalText + 空值` 判定本地延续，`platforms/ohos/snapshot/src/composable_ui_window.cj:5564` 的 `stagedDisplayValue` 同样返回 `""`。因此不能把它收成 OHOS 静默丢字。
- **`internalRendererConsumedPointerFifo` 是唯一“Linux 有具名支但仍是空值”的并列落点。** `macOS || Windows` 真实现（`:2105`）、Linux 全零（`:2123`）、第四平台全零（`:2128`）；没有“Windows 有、Linux 漏掉”的第三种形态。
- **`internalRendererSelectionBackgroundVersion` 在第四平台是整场拒绝，不是静默。** `:2136`（`macOS || Windows || Linux` 调 native 探针）、`:2143`（第四平台 `0`）；`composable_ui_window.cj:9952-9956` 对 `hasSelectionBackground` 且版本非 1/2 的候选返回 `reason: "selection_background_backend_unsupported"`，整个候选场景被拒。严重度比静默更高，但调用方能感知。
- **`internalRendererSourceRangeSupported` 与 `InstalledRangeSupported` 在 Linux 上取值不同不是缺陷。** Linux `SourceRangeSupported=true`（`:2637`）打开普通 source-range 生产链；`InstalledRangeSupported=false`（`:2623`）只关掉 source-handoff 预处理（`composable_ui_window.cj:19014`、`:22480` 等），跨选择 handoff 本来就是 macOS-only。
- **成对示例落点（不在 src 统计内）：** `examples/range_text_window_app/src/main.cj:1166` 的 `os != "macOS" && os != "Windows" && os != "Linux"` 仍返回空数组；Linux 已在 `:1156` 并入真实现，第四平台（含未来 OHOS 主树）上选区底色仍不会画。

## 五、调用方忽略具名拒绝的接缝

以下调用的返回值被 `let _ =` 或裸调用丢弃。它们返回 `TEXT_SERVICE_UNSUPPORTED`，因此不属于“静默 fallback 分支”，但调用方确实感知不到失败：

- `internalRendererAbortOwnerHandoff` — `composable_ui_window.cj:21224` 裸调用丢弃；非 macOS 恒 `UNSUPPORTED`，owner handoff 已被能力门关闭，abort 无对象可撤。
- `internalRendererAdmitSelectionTransferInput` — `:11152`、`:21986`、`:22042`、`:22885` 均 `let _ =`；非 macOS transfer 路径被能力门短路。
- `internalRendererBlockSelectionTransferRecovery` — `:22034`、`:22038`、`:22059` 均 `let _ =`；同上。
- `internalRendererCancelSourceHandoff` — `:13456`、`:13564`、`:13586` 均 `let _ =`；source-handoff 为 macOS-only。
- `internalRendererReleaseSelectionTransfer` — `:11153`、`:11154`、`:11249`、`:21882` 均 `let _ =`；同上。
- `internalRendererFinishCommandTextContextAdmission` — `:6411` `let _ =`；非 macOS 恒 `UNSUPPORTED`，且同一路径的 `internalRendererAdmitCommandTextContext` 在 `:15579` 已先返回 `UNSUPPORTED` 并被折算成 `0`，所以这只是清理一个从未发生的准入。macOS 上该返回值也被丢弃，属于既有写法，不新增平台差异。

未发现“具名拒绝被忽略后造成可见状态错误”的接缝；以上六处当前都被能力门或同一路径的前置拒绝挡住。

## 六、统计

| 类别 | 审阅分支 | 静默 | 具名错误/拒绝 | 能力门 | 真实现/无后果 | 待确认 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 一、`!= macOS && != Windows && != Linux` | 22 | 14 | 5 | 2 | 1 | 0 |
| 二、`!= macOS` | 105 | 17 | 57 | 7 | 24 | 0 |
| 三、Linux（含 Windows+Linux 并列支） | 24 | 10 | 2 | 5 | 7 | 0 |
| 合计 | 151 | 41 | 64 | 14 | 32 | 0 |

静默 fallback 的严重度分组（按分支计）：

| 严重度 | 类别一 | 类别二 | 类别三 | 合计 |
| --- | ---: | ---: | ---: | ---: |
| 影响可见功能 | 1 | 3 | 1 | 5 |
| 影响诊断 | 5 | 4 | 5 | 14 |
| 仅影响极端路径 | 8 | 10 | 4 | 22 |
| 待确认 | 0 | 0 | 0 | 0 |
| 合计 | 14 | 17 | 10 | 41 |

- 41 条按分支计；去重后对应 32 个函数实现（类别一与类别三在 owner trace、调度、退休队列、pointer FIFO 上重叠 9 个）。
- 影响可见功能的 5 条：pointer FIFO 全零（类别一、类别三各 1 条）、selection paint 的 publish/finish（类别二 2 条）、semantic help（类别二 1 条）。
- 影响诊断的 14 条：owner trace 家族 10 条（类别一 5 + 类别三 5）、字体诊断 1 条、测试探针 2 条、准备关联线程 1 条。
- 待确认 0 条：没有“写不出后果”的条目；主树无调用者的空桩已放入“未计入/无后果”，没有用严重度冒充结论。
