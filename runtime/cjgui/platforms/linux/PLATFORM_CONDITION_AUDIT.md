# Linux 平台条件审计（runtime/cjgui/src）

更新：2026-10-18。作者：linux-cangjie（task-1）。范围：`runtime/cjgui/src/*.cj` 全部 `@When` 平台条件，
重点是会让 Linux 落进「非此即彼」兜底的三类否定式条件。

## 0. 摘要

### 0.1 条件清单（改动前 → 改动后）

| 条件形态 | 改动前 | 改动后 |
| --- | --- | --- |
| `os != "macOS"` | 101 | 88 |
| `os != "Windows"` | 25 | 24 |
| `os != "macOS" && os != "Windows"` | 16 | **0** |
| （新增）残留支：再排除 Linux 的 `!=` 组合 | 0 | 30 |
| （新增）显式 Linux 并列支：`os == "Linux"` 25 / `os == "Windows" \|\| os == "Linux"` 7 / `os == "macOS" \|\| os == "Windows" \|\| os == "Linux"` 2 | 0 | **34** |

否定式条件的**总数守恒在 142**（88 + 24 + 30 = 142，与原 101 + 25 + 16 相同）：本轮没有删除任何一支，
只把 Linux 从「非此即彼」里摘出来给它自己的落点。消费者文件另有 6 条 Linux 并列支（不计入本表）。

| 处理 | 数 |
| --- | --- |
| `src/*.cj` 否定式条件总数（含 131 处在命名闭包内；另 11 处见 §1 末） | **142** |
| 写集内、已加显式 Linux 支 + 残留支排除 Linux | 30 |
| 写集内、保留原条件（Linux 落点 = 既有具名拒绝/共享真实现，逐条记录理由） | 62 |
| 写集外（只记录 + 建议条件，未改，避免与 E/H/W 在飞改动冲突） | 50 |
| 消费者 `examples/range_text_window_app/src/main.cj` 否定式条件（全部已改） | 5（另新增 1 个 Linux 专属宿主工厂） |

### 0.2 三条真正会挡住第一阶段验收的落点（已修）

1. **`internalRendererSelectionBackgroundVersion()` 在 Linux 返回 0 → 窗口画面起不来**（§3.1，硬失败）。
2. **`rangeTextPreviewSelectionRuns` 在 Linux 落空数组 → 选区底色不画**（§4.1）。
3. **`internalRendererComposableDisplayValue` 在 Linux 落 macOS 支 → 焦点文本框正文变空串**（§3.7，硬失败风险）。

### 0.3 编译验收（真实消费者闭包）

真实 Linux 编译闭包 = `native/scripts/lib_cjgui_source_set.sh` 的命名集合，**共 49 个 `.cj`**
（39 个框架文件 + 2 个生成文件 + §6.1 的 8 个补齐文件；Lead 已把该 8 个写进集合，`linux_guest.sh sync`
现在直接产出这 49 个文件）。下列结果用 `./linux_guest.sh sync` 后的**规范工作目录** `~/cjgui-linux` 复现：

| 目标 | 结果 |
| --- | --- |
| `cjgui` 库 `cjpm build --skip-script -j8` | **exit=0，0 error**，496 warnings，`cjpm build success` |
| `examples/range_text_window_app` 仓颉编译 | **0 error**（无 undeclared / syntax / 类型错） |
| 示例链接 | 失败（native sidecar 未完成）：未定义 native 符号的**精确计数由 Lead 的 report-all 探针出数**；本轮交叉核对为 123 个，逐个核对无一处来自 `.cj` |

> 历史更正：早前一轮用 `src/` 整目录（481 个 `.cj`）构建，链接期报 378 个符号——那 255 个差额是
> 不该编进来的 macOS 专用 Metal 桥源码（`cjgui_native_bridge_*`）。**378 作废**。
> 修正闭包后的未定义符号精确清单由 Lead 的 `--unresolved-symbols=report-all` 探针出数（本任务不重复出数）。

### 0.4 本阶段「具名拒绝 / 未实现能力」清单与**消费方表现**（Lead 要求，直接进最终报告）

区分两类后果：**功能禁用/降级**（消费方还能跑完整链路，只是少了某条优化或某个诊断） vs **硬失败**
（操作被拒或整场被拒，用户能看出来）。逐条给消费点行号。

| # | 未实现能力 / 具名拒绝 | Linux 落点 | 消费方表现 | 性质 |
| --- | --- | --- | --- | --- |
| 1 | **选区背景能力版本** | 已改为 native 探针（返回 1） | 版本为 0 时 `composable_ui_window.cj:9324-9329` **拒绝整个候选场景**，窗口起不来 | **硬失败（已修）** |
| 2 | **显示值空串代理协议** | 已改为并入 Windows 支（送真实正文） | 落在 macOS 支时焦点文本框正文变空串 → 文字不可见 | **硬失败（已修，Lead 已批准）** |
| 3 | **已消费指针 FIFO** | 显式全零（具名拒绝） | 主树示例：消费点 1/2/4 不参与判定或自我拒绝，**无影响**；同时实现 `PointerCaptureVersionProvider` + `SliderCaptureProvider` 的消费者：`rejectPointerBegin` → **滑块拖不动（功能禁用）** | 条件触发的硬失败 |
| 4 | **私有准备图 reuse batch** | 具名拒绝 + reused 恒 0 | `composable_ui_window.cj:10144-10159` 回落完整槽位路径 | 性能降级（安全 cache miss） |
| 5 | **私有准备图 batch 桥** | 显式并入逐节点 scalar 真实现 | 逐节点上传，deadline/已成功前缀语义相同（§3.3） | 性能降级，非禁用 |
| 6 | **installed range 家族** | 8 处具名拒绝 + 能力门 `false` | `focusNativeStatus` 走普通 focus（`:12057-12060`）；`registerInstalledRangeForNativeFocus` 提前返回（`:12096-12099`）；`carriesInstalledSource=false`（`:22310`）。**编辑与选择仍可用**：示例挂了 owner budget → 选择恢复走 `install_owned_source_selection`（`:22380`）；无 budget 时走 `restore_composable_selection`（`:22384`） | 功能降级（无区间安装/增量回执） |
| 7 | **source range / source-handoff** | 能力门 `false`（§3.5） | 消费点提前返回，不进入 source-owned 链 | 功能禁用（优化链） |
| 8 | **跨选择 transfer** | 能力门 `false` + 20+4 处具名拒绝 | `nativeIdentity` 恒 0 → `:20384/:21841` 完成票据门全假，整族惰性；选择提交走 restore 路径 | 功能禁用（跨节点 transfer） |
| 9 | **owner handoff** | 能力门 `false` + 8 处具名拒绝 | 消费者接缝 `main.cj:2366-2371` 在门为假时**直接执行事务**（正典本来就走这一步） | 功能禁用但有等价路径 |
| 10 | **macOS pointer BEGIN origin 认证** | 4 处显式 false/None | `requiresBeginOrigin` 恒假（`:16618`）→ 走普通 pointer BEGIN 守卫链；`publishMacTextPointerBeginFrame` 直接返回 | 功能禁用（认证协议） |
| 11 | **macOS 文本捕获接续 / 拖拽边缘滚动** | `SCENE_STALE` / 空操作 | 写入路径先自我拒绝（§3.4 表第 4 行） | 功能禁用 |
| 12 | **选择绘制代理 / 分段装饰** | 两个谓词均 false（写集外，**建议保留**） | `supportsProxySelectionPaint()` false → **消费者必须自己发布选区**；消费者若不画则**选区不可见** | 可见缺陷风险（消费者责任，非硬失败） |
| 13 | **owner trace / 调度计量 / workload 计数** | no-op / 0 | `finishRangeTextOwnerScheduling` 空操作（`main.cj:2413-2426`）；`RANGE_TEXT_WORKLOAD` 行显示 0 | 诊断禁用 |

第一阶段验收链路（建窗 → 自绘文字与控件 → 键鼠改共同状态 → 外部调用改同一状态 → 正常关闭）**不落在**
本表第 1、2、3 项以外的任何硬失败上；而第 1、2 项已经在本轮修掉（§0.2 是「已修落点」清单，
本表是「未实现能力」清单，两者编号各自独立）。第 3 项示例不进入（控制器不实现滑块接口）；
第 12 项由示例自己的 `selectionBackground` run 覆盖（§4.1 第 2 项）。

## 1. 方法与验证

- 清单来自 `grep -rn '@When' src/*.cj` 的机械枚举（脚本按 `@When[...]` 提取 + 取紧随其后的 `func` 名），
  不是抽样；本文所有行号由同一脚本在**改动后**的文件上重新生成，可直接核对。
- 判定方法：对每个否定式条件，先找它的**正条件配对支**（同一函数名的另一 `@When`），再看三个问题——
  (a) 该能力的**门谓词**（`internalRendererXxxSupported()`）在 Linux 是什么；(b) 消费点是否被该门守住；
  (c) 若被守住，Linux 走的是哪条真实路径。只有第 (c) 步落到空实现且消费点仍进入时才判「硬失败」。
- 关键结论都有消费点行号，不靠符号名相似推断。指针 FIFO 这一项按任务要求**不猜**：逐个消费点读守卫（§3.4）。
- 环境：宿主 macOS（不能编 Linux 目标）；验证在来宾 `oeuser@10.211.55.4`。
  同步用 `platforms/linux/scripts/linux_guest.sh sync`；闭包缺文件期间另用
  `~/cjgui-linux-verify`（`~/cjgui-linux` 的副本 + §6.1 的 8 个文件）取证，不改动权威脚本与工作目录。
- **审计范围与编译范围的关系**：142 处里有 **11 处不在命名闭包内**：
  `composable_ui_command_completion.cj` 3、`composable_ui_mac_resident_source.cj` 3、
  `composable_ui_selection_observation.cj` 2、`composable_ui_windows_selection_gesture.cj` 1
  （这 9 处随 §6.1 的 8 个文件补进闭包后即进入编译范围），以及
  `composable_ui_preparation_reuse_integration_test.cj` 2（测试文件，Linux 从不编它，
  按 `linux_guest.sh` 的命名集合排除；这 2 处只做记录，不构成 Linux 行为）。
  5 个文件都在 §5 的建议表里。

### 本仓「兜底」的两种既有形态（读表前需要知道）

- **具名拒绝**：返回 `CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED` / `None` / `false` / 空操作，
  且几乎总有配对的 `internalRendererXxxSupported()` 门谓词让消费点提前返回。这类落在 Linux 上**不是缺陷**。
- **共享真实现**：否定支本身是可用的真实实现（`PrepareComposableNodeBatch` 的逐节点 scalar 循环、
  `RestoreComposableSelectionForPaint` 委托给跨平台函数、`RequestCloseBeforeDestroy` 调 `RequestClose`）。
  这类落在 Linux 上同样不是缺陷，但**必须记录**，否则将来有人以为它只是空桩而重写。

本轮的改动规则因此是：**Linux 落点需要「决定」的地方加显式 `os == "Linux"` 支并把残留支改成排除 Linux**；
落点已经是具名拒绝且被门谓词守住的地方保留条件、在本文记录理由。这样既满足「Linux 不靠非此即彼兜底」，
又不制造 100 处无行为差异的机械改动（`AGENTS.md` 要求按影响范围验证、不做低收益重复动作）。

## 2. 全部 142 处否定式条件逐条落点

「Linux 新落点」列写明是**已改**（本轮加了显式 Linux 支）还是**未改**（保留原条件，Linux 落点已核实为具名拒绝或共享真实现）。

| # | 文件:行 | 原条件 | 函数 | Linux 新落点 | 理由 | 保持兜底的后果 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `composable_ui_command_completion.cj:79` | `os != "macOS"` | `internalRendererOwnerCommandReceiptSupported` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerCommandReceiptSupported()=false | 无影响：消费点不进入 |
| 2 | `composable_ui_command_completion.cj:90` | `os != "macOS"` | `internalRendererAcceptOwnerCommandReceipt` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerCommandReceiptSupported()=false | 无影响：消费点不进入 |
| 3 | `composable_ui_command_completion.cj:99` | `os != "macOS"` | `internalRendererRetireOwnerCommandPresentation` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerCommandReceiptSupported()=false | 无影响：消费点不进入 |
| 4 | `composable_ui_mac_caret_edit.cj:16` | `os != "macOS"` | `internalRendererMarkCaretEditApplied` | 未改：Linux 落=具名拒绝 | macOS 插入符编辑回执 | 无影响：消费点不进入 |
| 5 | `composable_ui_mac_edge_scroll.cj:41` | `os != "macOS"` | `internalRendererRetireReversedDragEdgeRequest` | 未改：Linux 落=SCENE_STALE / OK | 只有 macOS 有 ack_drag_edge_viewport 原生协议 | 无影响：probe 先行自我拒绝；即便通过，retire 返回 SCENE_STALE（§3.4） |
| 6 | `composable_ui_mac_edge_scroll.cj:55` | `os != "macOS"` | `internalRendererAckDragEdgeViewport` | 未改：Linux 落=SCENE_STALE / OK | 只有 macOS 有 ack_drag_edge_viewport 原生协议 | 无影响：probe 先行自我拒绝；即便通过，retire 返回 SCENE_STALE（§3.4） |
| 7 | `composable_ui_mac_edge_scroll.cj:69` | `os != "macOS"` | `internalRendererTerminateDragEdgeRequest` | 未改：Linux 落=SCENE_STALE / OK | 只有 macOS 有 ack_drag_edge_viewport 原生协议 | 无影响：probe 先行自我拒绝；即便通过，retire 返回 SCENE_STALE（§3.4） |
| 8 | `composable_ui_mac_owner_handoff.cj:46` | `os != "macOS"` | `internalRendererOwnerHandoffSupported` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 9 | `composable_ui_mac_owner_handoff.cj:58` | `os != "macOS"` | `internalRendererHasParkedTextFocus` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 10 | `composable_ui_mac_owner_handoff.cj:84` | `os != "macOS"` | `internalRendererBeginOwnerHandoff` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 11 | `composable_ui_mac_owner_handoff.cj:98` | `os != "macOS"` | `internalRendererSealOwnerHandoff` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 12 | `composable_ui_mac_owner_handoff.cj:109` | `os != "macOS"` | `internalRendererBindOwnerHandoff` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 13 | `composable_ui_mac_owner_handoff.cj:122` | `os != "macOS"` | `internalRendererCompleteOwnerHandoff` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 14 | `composable_ui_mac_owner_handoff.cj:138` | `os != "macOS"` | `internalRendererOwnerHandoffState` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 15 | `composable_ui_mac_owner_handoff.cj:143` | `os != "macOS"` | `internalRendererAbortOwnerHandoff` | 未改：Linux 落=false / 具名拒绝 | 能力门 OwnerHandoffSupported()=false | 无影响：消费者接缝在门为假时直接执行事务（§3.5、§4.2） |
| 16 | `composable_ui_mac_resident_source.cj:16` | `os != "macOS"` | `internalRendererResidentTextSourceSupported` | 未改：Linux 落=false / 具名拒绝 | 能力门 ResidentTextSourceSupported()=false | 无影响：消费点不进入 |
| 17 | `composable_ui_mac_resident_source.cj:30` | `os != "macOS"` | `internalRendererStageResidentTextSource` | 未改：Linux 落=false / 具名拒绝 | 能力门 ResidentTextSourceSupported()=false | 无影响：消费点不进入 |
| 18 | `composable_ui_mac_resident_source.cj:58` | `os != "macOS"` | `internalRendererResidentCaretSource` | 未改：Linux 落=false / 具名拒绝 | 能力门 ResidentTextSourceSupported()=false | 无影响：消费点不进入 |
| 19 | `composable_ui_mac_retirement.cj:25` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererDrainComposableRetirement` | 已改：显式 Linux 支 =(OK, true) | Linux 没有真实退休队列，「无真实回收可等」就是结论 | 无影响：不伪报已回收（§3.3） |
| 20 | `composable_ui_mac_text_continuation.cj:74` | `os != "macOS"` | `internalRendererOfferTextCaptureContinuation` | 未改：Linux 落=SCENE_STALE / 空操作 | macOS 文本捕获的跨场景接续票据 | 无影响：Linux 不进入 macOS 式捕获接续链（§3.4） |
| 21 | `composable_ui_mac_text_continuation.cj:89` | `os != "macOS"` | `internalRendererCompleteTextCaptureContinuation` | 未改：Linux 落=SCENE_STALE / 空操作 | macOS 文本捕获的跨场景接续票据 | 无影响：Linux 不进入 macOS 式捕获接续链（§3.4） |
| 22 | `composable_ui_mac_text_continuation.cj:97` | `os != "macOS"` | `internalRendererDiscardTextCaptureContinuation` | 未改：Linux 落=SCENE_STALE / 空操作 | macOS 文本捕获的跨场景接续票据 | 无影响：Linux 不进入 macOS 式捕获接续链（§3.4） |
| 23 | `composable_ui_preparation_reuse_integration_test.cj:211` | `os != "macOS"` | `preparedActualLegacyFrameCheckCount` | 未改：Linux 落=0 / 空操作 | macOS 测试专用探针 | 无影响：测试文件不同步到 Linux（linux_guest.sh 排除 *_test.cj） |
| 24 | `composable_ui_preparation_reuse_integration_test.cj:219` | `os != "macOS"` | `assertPreparedLegacyFrameChecksUnchanged` | 未改：Linux 落=0 / 空操作 | macOS 测试专用探针 | 无影响：测试文件不同步到 Linux（linux_guest.sh 排除 *_test.cj） |
| 25 | `composable_ui_selection_observation.cj:133` | `os != "Windows"` | `cjguiRevealAcceptedSelectionNative` | 未改：Linux 落=空/无增强 | Windows 有原生选择几何读回 | 少功能（诊断/几何）：Linux 走普通读回；示例的几何观察只在 RANGE_TEXT_SELECTION_GEOMETRY=1 时用 |
| 26 | `composable_ui_selection_observation.cj:168` | `os != "Windows"` | `cjguiReadSelectionGeometryNative` | 未改：Linux 落=空/无增强 | Windows 有原生选择几何读回 | 少功能（诊断/几何）：Linux 走普通读回；示例的几何观察只在 RANGE_TEXT_SELECTION_GEOMETRY=1 时用 |
| 27 | `composable_ui_selection_paint.cj:143` | `os != "macOS"` | `internalRendererPublishInstalledSelectionOwner` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 28 | `composable_ui_selection_paint.cj:160` | `os != "macOS"` | `internalRendererFinishSelectionPaint` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 29 | `composable_ui_selection_paint.cj:173` | `os != "macOS"` | `internalRendererStageSelectionPaint` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 30 | `composable_ui_selection_paint.cj:191` | `os != "Windows"` | `internalRendererClearPreviewSelectionDecoration` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 31 | `composable_ui_selection_paint.cj:229` | `os != "Windows"` | `internalRendererStagePreviewSelectionPaint` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 32 | `composable_ui_selection_paint.cj:287` | `os != "Windows"` | `internalRendererStagePreviewSelectionDecoration` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 33 | `composable_ui_selection_paint.cj:294` | `os != "Windows"` | `internalRendererStagePreviewSelectionDecorationForCurrentOwner` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 34 | `composable_ui_selection_paint.cj:308` | `os != "macOS"` | `internalRendererSupportsProxySelectionPaint` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 35 | `composable_ui_selection_paint.cj:321` | `os != "Windows"` | `internalRendererSupportsStagedPreviewSelectionPaint` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 36 | `composable_ui_selection_paint.cj:515` | `os != "macOS"` | `internalRendererStageAcceptedSelectionDecoration` | 未改：Linux 落=false 或具名拒绝 | 只有 Darwin 在原生代理上画选区；只有 Windows 能分段装饰 | 无影响且是正确落点：消费者用自己的场景投影画选区（本仓示例用 selectionBackground run） |
| 37 | `composable_ui_source_recovery.cj:82` | `os != "Windows"` | `internalRendererPeekSourceInstallRecovery` | 未改：Linux 落=None / OK | Windows 的 source install 恢复记录 | 无影响：能力门为假，调用点不进入 |
| 38 | `composable_ui_source_recovery.cj:91` | `os != "Windows"` | `internalRendererAckSourceInstallRecovery` | 未改：Linux 落=None / OK | Windows 的 source install 恢复记录 | 无影响：能力门为假，调用点不进入 |
| 39 | `composable_ui_window.cj:2425` | `os != "macOS"` | `preparationCorrelationThread` | 未改：Linux 落=UInt64.Max / false / 空结果 | macOS 专属关联线程与调度回合 | 少功能（诊断）：示例的 workload 计数在 Linux 读回空结果 |
| 40 | `composable_ui_window.cj:2584` | `os != "macOS"` | `hasActiveOwnerSchedulingRound` | 未改：Linux 落=UInt64.Max / false / 空结果 | macOS 专属关联线程与调度回合 | 少功能（诊断）：示例的 workload 计数在 Linux 读回空结果 |
| 41 | `composable_ui_window.cj:6849` | `os != "macOS"` | `readWorkloadAttemptCounts` | 未改：Linux 落=UInt64.Max / false / 空结果 | macOS 专属关联线程与调度回合 | 少功能（诊断）：示例的 workload 计数在 Linux 读回空结果 |
| 42 | `composable_ui_window.cj:7602` | `os != "Windows"` | `restageAcceptedPreviewSelectionDecoration` | 未改：Linux 落=空操作 | Windows 分段装饰恢复 | 无影响：门谓词 false |
| 43 | `composable_ui_window.cj:9751` | `os != "Windows"` | `traceSmallDisplayTransport` | 未改：Linux 落=空操作 | Windows 专属诊断 | 无影响：仅日志 |
| 44 | `composable_ui_window.cj:15465` | `os != "Windows"` | `traceWindowsSliderBeginRefusal` | 未改：Linux 落=空操作 | Windows 专属诊断 | 无影响：仅日志 |
| 45 | `composable_ui_window.cj:20546` | `os != "Windows"` | `finishWindowsSelectionGestureDecision` | 未改：Linux 落=空操作 | Windows 专属诊断 | 无影响：仅日志 |
| 46 | `composable_ui_window.cj:20623` | `os != "Windows"` | `freezeCandidateSelectionObservation` | 未改：Linux 落=None / 恒等 | Windows 选择几何增强 | 无影响：观察缺省即不发布几何 |
| 47 | `composable_ui_window.cj:20689` | `os != "Windows"` | `semanticSelectionGeometryVersion` | 未改：Linux 落=None / 恒等 | Windows 选择几何增强 | 无影响：观察缺省即不发布几何 |
| 48 | `composable_ui_window.cj:22678` | `os != "Windows"` | `certifySliderBeforeParticipantCommit` | 未改：Linux 落=空操作 | Windows 滑块提交认证 | 无影响：macSliderCapture 在 Linux 为 None（§3.4） |
| 49 | `composable_ui_window.cj:22686` | `os != "Windows"` | `certifySliderAfterParticipantCommit` | 未改：Linux 落=空操作 | Windows 滑块提交认证 | 无影响：macSliderCapture 在 Linux 为 None（§3.4） |
| 50 | `composable_ui_windows_selection_gesture.cj:24` | `os != "Windows"` | `cjguiWindowsSelectionGestureNative` | 未改：Linux 落=[] | Windows 专属原生手势 | 无影响：调用点由 Windows 门控 |
| 51 | `macos_application_cleanup.cj:23` | `os != "macOS"` | `cjguiRunMacosApplication` | 未改：Linux 落=直接执行 body | macOS AppKit 清理票据 | 无影响：非 macOS 身份直通，Linux 不需要该票据 |
| 52 | `owner_turn_budget.cj:19` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiSchedulingWorkRevision` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 53 | `owner_turn_budget.cj:28` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiCommonSchedulingEnabled` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 54 | `owner_turn_budget.cj:41` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiWaitSchedulingWork` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 55 | `owner_turn_budget.cj:57` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiOwnerTraceBoundary` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 56 | `owner_turn_budget.cj:129` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiOwnerTraceLegacySpan` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 57 | `owner_turn_budget.cj:146` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiOwnerTraceRecord` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 58 | `owner_turn_budget.cj:160` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiOwnerTraceSetTurn` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 59 | `owner_turn_budget.cj:171` | `os != "macOS" && os != "Windows" && os != "Linux"` | `cjguiOwnerTraceExport` | 已改：显式 Linux 支 = 与 Windows 同（0/false/no-op） | Linux 本阶段无 owner 诊断原生通道 | 少功能（诊断）：trace 不记录、调度不计量；预算责任仍在 begin/pump/end（§3.8） |
| 60 | `runtime_renderer_session.cj:2003` | `os != "macOS" && os != "Linux"` | `internalRendererSupportsPointerBeginOrigin` | 已改：显式 Linux 支 = false/None/UNSUPPORTED | Linux 与 Windows 并列，都没有 macOS 的 begin-origin 票据 | 无影响：消费点 requiresBeginOrigin 恒假，走普通 pointer BEGIN 守卫链（§3.4） |
| 61 | `runtime_renderer_session.cj:2012` | `os != "macOS" && os != "Linux"` | `internalRendererPointerBeginFrameRetained` | 已改：显式 Linux 支 = false/None/UNSUPPORTED | Linux 与 Windows 并列，都没有 macOS 的 begin-origin 票据 | 无影响：消费点 requiresBeginOrigin 恒假，走普通 pointer BEGIN 守卫链（§3.4） |
| 62 | `runtime_renderer_session.cj:2023` | `os != "macOS" && os != "Linux"` | `internalRendererPublishPointerBeginSource` | 已改：显式 Linux 支 = false/None/UNSUPPORTED | Linux 与 Windows 并列，都没有 macOS 的 begin-origin 票据 | 无影响：消费点 requiresBeginOrigin 恒假，走普通 pointer BEGIN 守卫链（§3.4） |
| 63 | `runtime_renderer_session.cj:2037` | `os != "macOS" && os != "Linux"` | `internalRendererConsumePointerBeginOrigin` | 已改：显式 Linux 支 = false/None/UNSUPPORTED | Linux 与 Windows 并列，都没有 macOS 的 begin-origin 票据 | 无影响：消费点 requiresBeginOrigin 恒假，走普通 pointer BEGIN 守卫链（§3.4） |
| 64 | `runtime_renderer_session.cj:2065` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererConsumedPointerFifo` | 已改：显式 Linux 支 = 全零 FIFO（具名拒绝） | Linux 无 owner 指针流原生票据；不靠「非 macOS 非 Windows」兜底 | 按消费点不同：见 §3.4 四点核实，验收消费者不触发 |
| 65 | `runtime_renderer_session.cj:2080` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererSelectionBackgroundVersion` | 已改：Linux → 1（native 探针） | 硬事实：场景含选区背景且版本非 1/2 会整场拒绝候选 | **硬失败**：版本 0 时窗口画面起不来（§3.1） |
| 66 | `runtime_renderer_session.cj:2152` | `os != "macOS"` | `internalRendererOwnerPumpHasUnconsumedInput` | 未改：Linux 落=空/错误状态/false | macOS-only 诊断入口 | 无影响：示例仅用于 workload 计数（status!=ok 时保留上次值） |
| 67 | `runtime_renderer_session.cj:2277` | `os != "macOS"` | `internalRendererSetComposableCommandCompletionPolicy` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 68 | `runtime_renderer_session.cj:2288` | `os != "macOS"` | `internalRendererSetComposableCommandIdentity` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 69 | `runtime_renderer_session.cj:2305` | `os != "macOS"` | `internalRendererConsumedCommandCompletionPolicy` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 70 | `runtime_renderer_session.cj:2318` | `os != "macOS"` | `internalRendererOwnerConsumedCommandSource` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 71 | `runtime_renderer_session.cj:2332` | `os != "macOS"` | `internalRendererAdmitCommandTextContext` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 72 | `runtime_renderer_session.cj:2346` | `os != "macOS"` | `internalRendererFinishCommandTextContextAdmission` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 73 | `runtime_renderer_session.cj:2358` | `os != "macOS"` | `internalRendererCommitInstalledSelectionCommands` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 74 | `runtime_renderer_session.cj:2369` | `os != "macOS"` | `internalRendererBindCaretSelectionTransfer` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 75 | `runtime_renderer_session.cj:2381` | `os != "macOS"` | `internalRendererBindCaretProjectionTransfer` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 76 | `runtime_renderer_session.cj:2398` | `os != "macOS"` | `internalRendererFinishCaretInput` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 77 | `runtime_renderer_session.cj:2411` | `os != "macOS"` | `internalRendererCaretInputWasRetired` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 78 | `runtime_renderer_session.cj:2476` | `os != "macOS"` | `internalRendererPeekCaretRecovery` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 79 | `runtime_renderer_session.cj:2487` | `os != "macOS"` | `internalRendererFinishCaretRecovery` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 80 | `runtime_renderer_session.cj:2497` | `os != "macOS"` | `internalRendererCancelCaretPrefix` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 81 | `runtime_renderer_session.cj:2510` | `os != "macOS"` | `internalRendererConsumedActivationPrefix` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 82 | `runtime_renderer_session.cj:2552` | `os != "macOS" && os != "Linux"` | `internalRendererConsumedInputProvenance` | 已改：显式 Linux 支 = 全零 provenance | 与 Windows 并列；无 macOS provenance 票据 | 无影响：owner 完成票据守卫具名拒绝，不伪造已消费输入 |
| 83 | `runtime_renderer_session.cj:2563` | `os != "macOS" && os != "Linux"` | `internalRendererInstalledRangeSupported` | 已改（源码范围）/ 未改（Windows 结算） | Linux 的落点是显式 false，不是「非 macOS」兜底 | 少功能：消费方走普通路径或具名拒绝，见 §3.5 / §3.6 |
| 84 | `runtime_renderer_session.cj:2577` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererSourceRangeSupported` | 已改（源码范围）/ 未改（Windows 结算） | Linux 的落点是显式 false，不是「非 macOS」兜底 | 少功能：消费方走普通路径或具名拒绝，见 §3.5 / §3.6 |
| 85 | `runtime_renderer_session.cj:2589` | `os != "macOS" && os != "Linux"` | `internalRendererSelectionTransferSupported` | 已改（源码范围）/ 未改（Windows 结算） | Linux 的落点是显式 false，不是「非 macOS」兜底 | 少功能：消费方走普通路径或具名拒绝，见 §3.5 / §3.6 |
| 86 | `runtime_renderer_session.cj:2596` | `os != "Windows"` | `internalRendererWindowsSourceSettlementSupported` | 未改：Linux 落=false | 只有 Windows 有 `finish_source_install` 结算；Linux 与 macOS 并列 | 无影响：调用点由该门在运行期排除，不进入结算 |
| 87 | `runtime_renderer_session.cj:2611` | `os != "Windows"` | `internalRendererSourceInstallReceipt` | 未改：Linux 落=零值桩 | 只有 Windows 有 finish_source_install 结算 | 无影响：调用点由 WindowsSourceSettlementSupported() 运行期排除 |
| 88 | `runtime_renderer_session.cj:2625` | `os != "Windows"` | `internalRendererFinishSourceInstall` | 未改：Linux 落=零值桩 | 只有 Windows 有 finish_source_install 结算 | 无影响：调用点由 WindowsSourceSettlementSupported() 运行期排除 |
| 89 | `runtime_renderer_session.cj:2645` | `os != "Windows"` | `internalRendererSourceInstallGateState` | 未改：Linux 落=零值桩 | 只有 Windows 有 finish_source_install 结算 | 无影响：调用点由 WindowsSourceSettlementSupported() 运行期排除 |
| 90 | `runtime_renderer_session.cj:2661` | `os != "macOS"` | `internalRendererCreateSelectionTransfer` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 91 | `runtime_renderer_session.cj:2670` | `os != "macOS"` | `internalRendererPublishSelectionTransferPending` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 92 | `runtime_renderer_session.cj:2679` | `os != "macOS"` | `internalRendererBeginSelectionTransferFinalizing` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 93 | `runtime_renderer_session.cj:2688` | `os != "macOS"` | `internalRendererRequestSelectionTransferCancel` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 94 | `runtime_renderer_session.cj:2697` | `os != "macOS"` | `internalRendererCommitSelectionTransfer` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 95 | `runtime_renderer_session.cj:2706` | `os != "macOS"` | `internalRendererFinishSelectionTransferAbort` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 96 | `runtime_renderer_session.cj:2715` | `os != "macOS"` | `internalRendererBlockSelectionTransferRecovery` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 97 | `runtime_renderer_session.cj:2729` | `os != "macOS"` | `internalRendererSelectionTransferState` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 98 | `runtime_renderer_session.cj:2740` | `os != "macOS"` | `internalRendererAdmitSelectionTransferInput` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 99 | `runtime_renderer_session.cj:2749` | `os != "macOS"` | `internalRendererRetainSelectionTransfer` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 100 | `runtime_renderer_session.cj:2758` | `os != "macOS"` | `internalRendererReleaseSelectionTransfer` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 101 | `runtime_renderer_session.cj:2783` | `os != "macOS"` | `internalRendererCaptureSelectionTransferCandidate` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 102 | `runtime_renderer_session.cj:2824` | `os != "macOS"` | `internalRendererCaptureSelectionTransferA` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 103 | `runtime_renderer_session.cj:2864` | `os != "macOS"` | `internalRendererCaptureCurrentSelectionTransfer` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 104 | `runtime_renderer_session.cj:2879` | `os != "macOS"` | `internalRendererPrepareSelectionTransferB` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 105 | `runtime_renderer_session.cj:2895` | `os != "macOS"` | `internalRendererInstallSelectionTransferB` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 106 | `runtime_renderer_session.cj:2909` | `os != "macOS"` | `internalRendererVerifySelectionTransferB` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 107 | `runtime_renderer_session.cj:2920` | `os != "macOS"` | `internalRendererRestoreSelectionTransferA` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 108 | `runtime_renderer_session.cj:2929` | `os != "macOS"` | `internalRendererReplaySelectionTransferInput` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 109 | `runtime_renderer_session.cj:2938` | `os != "macOS"` | `internalRendererDiscardSelectionTransferCapsule` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 110 | `runtime_renderer_session.cj:2966` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererArmInstalledRange` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 111 | `runtime_renderer_session.cj:2979` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererInstalledRangeReceipt` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 112 | `runtime_renderer_session.cj:2993` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererActiveInstalledRangeReceipt` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 113 | `runtime_renderer_session.cj:3005` | `os != "macOS"` | `internalRendererUnchangedCaptureReceipt` | 未改：Linux 落=具名拒绝 | 跨选择 transfer 只有 macOS 有完整原生实现 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 114 | `runtime_renderer_session.cj:3018` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererActivateInstalledRange` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 115 | `runtime_renderer_session.cj:3029` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererCancelInstalledRange` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 116 | `runtime_renderer_session.cj:3054` | `os != "macOS"` | `internalRendererArmSourceHandoff` | 未改：Linux 落=具名拒绝 | 跨选择 transfer 只有 macOS 有完整原生实现 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 117 | `runtime_renderer_session.cj:3066` | `os != "macOS"` | `internalRendererConfirmSourceHandoffSelection` | 未改：Linux 落=具名拒绝 | 跨选择 transfer 只有 macOS 有完整原生实现 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 118 | `runtime_renderer_session.cj:3075` | `os != "macOS"` | `internalRendererActivateSourceHandoff` | 未改：Linux 落=具名拒绝 | 跨选择 transfer 只有 macOS 有完整原生实现 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 119 | `runtime_renderer_session.cj:3083` | `os != "macOS"` | `internalRendererFinishSourceHandoff` | 未改：Linux 落=具名拒绝 | 跨选择 transfer 只有 macOS 有完整原生实现 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 120 | `runtime_renderer_session.cj:3090` | `os != "macOS"` | `internalRendererCancelSourceHandoff` | 未改：Linux 落=具名拒绝 | 跨选择 transfer 只有 macOS 有完整原生实现 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 121 | `runtime_renderer_session.cj:3100` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererReleaseInstalledRange` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 122 | `runtime_renderer_session.cj:3114` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererAckInstalledRange` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 123 | `runtime_renderer_session.cj:3166` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererClaimInstalledRange` | 已改：显式 Linux 支 = 具名拒绝/空操作 | 任务要求显式落点，不假装支持 | 无影响：能力门 false 使消费点提前返回（§3.5） |
| 124 | `runtime_renderer_session.cj:3188` | `os != "macOS"` | `internalRendererPrepareFrameResources` | 未改：Linux 落=(OK, true) | 非 macOS 后端无 macOS 的准备票据 | 无影响：与 Windows 同支 |
| 125 | `runtime_renderer_session.cj:3217` | `os != "Windows"` | `internalRendererPreparationDiagnosticScalar` | 未改：Linux 落=0 | 只有 Windows 有该调试入口 | 无影响：诊断字段读回 0，不伪报已回收 |
| 126 | `runtime_renderer_session.cj:3239` | `os != "Windows" && os != "Linux"` | `internalRendererComposableDisplayValue` | 已改：Linux 并入 Windows 支 = 送真实正文 | 判据是代码自述的后端事实：自绘冻结场景值、无空串代理协议 | **硬失败风险**：留在 macOS 支会让焦点文本框正文变空串（§3.7） |
| 127 | `runtime_renderer_session.cj:3349` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererPrepareComposableNodeBatch` | 已改：Linux 显式并入逐节点 scalar 真实现 / reuse 具名拒绝 | 兜底是真实现（非空实现），reuse 是可接受的安全 cache miss | 无影响：§3.3 逐项核实结论 |
| 128 | `runtime_renderer_session.cj:3389` | `os != "macOS" && os != "Windows" && os != "Linux"` | `internalRendererReuseComposableNodeBatch` | 已改：Linux 显式并入逐节点 scalar 真实现 / reuse 具名拒绝 | 兜底是真实现（非空实现），reuse 是可接受的安全 cache miss | 无影响：§3.3 逐项核实结论 |
| 129 | `runtime_renderer_session.cj:3812` | `os != "macOS"` | `internalRendererDiagnosticScalarSnapshot` | 未改：Linux 落=空/错误状态/false | macOS-only 诊断入口 | 无影响：示例仅用于 workload 计数（status!=ok 时保留上次值） |
| 130 | `runtime_renderer_session.cj:3870` | `os != "macOS"` | `internalRendererPublishedComposableDisplayProgress` | 未改：Linux 落=共享实现 | 委托给跨平台函数 | 无影响 |
| 131 | `runtime_renderer_session.cj:3933` | `os != "Windows"` | `internalRendererRestoreComposableSelectionForPaint` | 未改：Linux 落=共享 restore 真实现 | Linux 没有 Windows 的分段装饰恢复 | 无影响：走 ordinary native restore（native 需实现 restore_composable_selection） |
| 132 | `runtime_renderer_session.cj:4823` | `os != "macOS"` | `internalRendererRequestCloseBeforeDestroy` | 未改：Linux 落=与 Windows 同（预关闭 / 不停新 owner 工作） | 非 macOS 后端共用同一预关闭协议 | 无影响：与 Windows 行为一致 |
| 133 | `runtime_renderer_session.cj:4833` | `os != "macOS"` | `internalRendererCloseStopsNewOwnerWork` | 未改：Linux 落=与 Windows 同（预关闭 / 不停新 owner 工作） | 非 macOS 后端共用同一预关闭协议 | 无影响：与 Windows 行为一致 |
| 134 | `runtime_renderer_session.cj:5002` | `os != "macOS"` | `internalRendererAcceptedCaretValue` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 135 | `runtime_renderer_session.cj:5022` | `os != "macOS"` | `internalRendererStageCandidateCaret` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 136 | `runtime_renderer_session.cj:5055` | `os != "macOS"` | `internalRendererCaptureCandidateSelection` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 137 | `runtime_renderer_session.cj:5067` | `os != "macOS"` | `internalRendererPrepareCandidateSelection` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 138 | `runtime_renderer_session.cj:5077` | `os != "macOS"` | `internalRendererCandidateSelectionReceipt` | 未改：Linux 落=具名拒绝/空操作 | macOS 原生命令完成票据与插入符恢复票据 | 无影响：门谓词为 false，消费点不进入 |
| 139 | `runtime_renderer_session.cj:5111` | `os != "macOS"` | `internalRendererFreezePointerSelectionDispatch` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 140 | `runtime_renderer_session.cj:5118` | `os != "macOS"` | `internalRendererBindPointerSelectionDispatch` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 141 | `runtime_renderer_session.cj:5131` | `os != "macOS"` | `internalRendererCompletePointerSelectionDispatch` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |
| 142 | `runtime_renderer_session.cj:5138` | `os != "macOS"` | `internalRendererRefusePointerSelectionDispatch` | 未改：Linux 落=具名拒绝（TEXT_SERVICE_UNSUPPORTED） | 能力门 SelectionTransferSupported()=false 使消费点不进入 | 无影响：Linux 的 nativeIdentity 恒 0，完成票据守卫全为假（§3.6） |

TOTAL 142

## 3. 深度核实

### 3.1 选区背景能力版本（唯一的**整场拒绝**硬失败）

链路（三处，全部读过）：

- `runtime_renderer_session.cj` 的 FFI 声明 `cjgui_internal_renderer_selection_background_version` 原为
  `@When[os == "macOS" || os == "Windows"]`，Linux 不声明 → 不产生符号引用。
- 同文件 `internalRendererSelectionBackgroundVersion()` 原为
  `@When[os == "macOS" || os == "Windows"]`（走 native）+ `@When[os != "macOS" && os != "Windows"]`（恒 `0u32`）
  → **Linux 落 0**。
- `composable_ui_window.cj:9321-9329`：
  ```cj
  let selectionBackgroundVersion = if (scene.hasSelectionBackground) {
      internalRendererSelectionBackgroundVersion()
  } else { 0u32 }
  if ((scene.hasSelectionBackground && selectionBackgroundVersion != 1u32 &&
      selectionBackgroundVersion != 2u32) ||
      (scene.hasPlatformSelectionBackground && selectionBackgroundVersion != 2u32)) {
      return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED,
          reason: "selection_background_backend_unsupported")
  }
  ```
  这不是「少画一层背景」，是**整个候选场景被拒**，窗口起不来。

判据补充（为什么 Linux 必须是 1 而不是 2）：

- `hasPlatformSelectionBackground` 由文本 run 是否使用 `CjguiComposableUiTextStyleRun.platformSelectionBackground`
  决定（`composable_ui.cj:6577-6582,6639-6640`）。该 run 表示「用平台（AppKit）自己的选区色」，
  Linux 没有这种平台色；`version == 2` 只对 macOS 成立。
- `hasSelectionBackground` 由显式选区色 run（`selectionBackground`）决定。示例消费者用的正是显式色
  （`main.cj` 的 `rangeTextPreviewSelectionRuns`），Linux 给 1 即可通过。

**改动**：FFI 声明与实现支都加上 Linux；Linux 侧由 native 实现 `cjgui_internal_renderer_selection_background_version`
并返回 `1`（与 Windows 同值）。残留支改成 `os != "macOS" && os != "Windows" && os != "Linux"` 恒 0。
未在仓颉侧写死常量：能力事实归 native，仓颉侧只声明依赖（否则 macOS 的 2 与 Linux 的 1 会在仓颉里分叉）。

**依赖**：native 未实现该符号前，示例可链接失败——这是预期，见 §6。

### 3.2 「少功能」与「硬失败」的分界

本轮把 142 处按后果分成三类，只有第 3 类必须改：

| 类 | 判据 | 例 | Linux 处理 |
| --- | --- | --- | --- |
| 无影响 | 具名拒绝 + 门谓词让消费点提前返回 | owner handoff、installed range、跨选择 transfer | 保留条件 + 本文记录 |
| 少功能（可接受） | 落点牺牲的是诊断/优化，正常连续操作仍走真实现 | owner trace、workload 计数、reuse cache miss | 保留或加显式支 + 记录 |
| **硬失败** | 消费点仍进入，结果是被拒绝的一条操作或被拒的整场 | 选区背景版本、空串显示值、滑块 FIFO（条件触发） | 改（§3.1、§3.7、§3.4） |

### 3.3 私有准备图：prepare batch / reuse batch / 退休队列

任务要求核实的三项，结论如下。

**`internalRendererPrepareComposableNodeBatch`（现 `runtime_renderer_session.cj:3349` 残留支）**

- 兜底是**真实现**：逐个节点调 `internalRendererPrepareComposableNode`（scalar 路径），
  deadline 是同一个绝对预算（用 `cjgui_internal_renderer_owner_clock_ns()`），到点返回**已完成的成功前缀**而不是整体失败。
- 消费点 `composable_ui_window.cj:10154/10175`：批量 API 失败会 `cancelNativePreparation` +
  `packet.syncFallback = true` 回落到有界完整声明上传（`:10180-10184`）。也就是说 scalar 路径不是「降级」，是本阶段的目标路径之一。
- **足够性结论（第一阶段）**：够用。理由是它调用的 `internalRendererPrepareComposableNode` 正是
  `cjgui_internal_renderer_prepare_composable_node`（native 必须实现，见 §6），逐节点上传与批量上传在**同一份 POD/字符串契约**上；
  批量桥省的是每节点一次 FFI 调用的开销，不改变正确性。本阶段验收（单窗口、单文本框、900x620）节点数量级下开销可接受。
  **不足的边界**：大文档/多节点场景会放大每节点 FFI 的开销，且 `reuse` 关闭意味着每次刷新都是完整声明上传（见下）；这两项属性能项，不是本阶段的验收项。
- **改动**：把 scalar 循环抽成 `internalRendererPrepareComposableNodeBatchScalar`，Linux 与残留平台各有一个
  **显式**调用支，Linux 不再靠「非 macOS 非 Windows」继承这份实现。

**`internalRendererReuseComposableNodeBatch`（现 `:3389` 残留支）**

- 返回 `(CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, 0u32)`：具名、有界、不消耗 deadline、reused 恒 0。
  消费点 `composable_ui_window.cj:10144` 命中 `reused == 0` → 走完整槽位路径（`:10146-10159`）。
- **结论**：可接受的安全 cache miss。它只损失复用优化，不伪报复用。Linux 显式支保留同一具名拒绝。

**`internalRendererDrainComposableRetirement`（`composable_ui_mac_retirement.cj:25` 残留支）**

- 返回 `(CJGUI_INTERNAL_RENDERER_OK, true)` = 「无真实回收可等，可以开始」。这是该文件自己声明的语义
  （「没有该责任的平台按'无真实回收可等'返回可以开始，而不是伪装已回收」）。
- Linux 没有私有准备图退休队列，所以这个结论对 Linux 正确。**改动**：加显式 `os == "Linux"` 支，残留支排除 Linux。

### 3.4 输入与指针家族（任务点名，逐个消费点读守卫，不猜）

**`internalRendererConsumedPointerFifo`（现 `:2065` 残留支）**：Linux 落点为**全零 FIFO**（具名拒绝）。
四个消费点逐个核实：

| # | 消费点 | 守卫 | Linux 会走到吗 | 后果 |
| --- | --- | --- | --- | --- |
| 1 | `composable_ui_window.cj:6789` `consumedPointerTraceIdentity` | 无（public 诊断函数） | 只有外部调用者会调；**本仓无调用者**（`grep` 全仓 0 处引用） | 返回 `""`（未知）。纯诊断，无影响 |
| 2 | `composable_ui_window.cj:15844` `applyCapturedTextPointerEvent` | `capture.isSome()` && `revokedReason==""` && (`POINTER_BEGIN` \|\| `pointerCaptureActive`)，且 `ownedTextSession.isSome()`、`sourceSelectionSnapshot().isSome()` | **会**（示例实现 `CjguiComposableUiPointerCaptureVersionProvider`，点击文本即进入） | 无影响：`fifo` 只写进 `CjguiMacTextPointerSelectionDispatch.originFifo`；该字段全仓**只被写入、从不被读取**（`grep originFifo` 只有构造点）。同处的 `nativeIdentity` 来自 `internalRendererFreezePointerSelectionDispatch`，非 macOS 恒 `0u64`（`:5111`），于是 `nativeIdentity != 0` 的全部完成票据门恒假 → 整族惰性 |
| 3 | `composable_ui_window.cj:16310` `consumedMacSliderFifo` | `isMacSliderCaptureTarget`（`:16319-16324`）= `gestureEpoch==0` && `nodeKind==SLIDER` && 控制器实现 `PointerCaptureVersionProvider` **且** 实现 `SliderCaptureProvider` | **条件触发**：示例控制器只实现前者（`main.cj:1212`），故示例**不会**走到；但任何同时实现两个接口的消费者会走到 | **硬失败（条件触发）**：`freezeMacSliderCapture` 的 `fifo.follows(...)` 恒假 → 返回 `None` → `:16714` `sliderTarget && frozenSlider.isNone()` → `rejectPointerBegin`，滑块拖不动。本仓 `examples/` 无此形态消费者，主树示例不受影响 |
| 4 | `composable_ui_window.cj:23747` `retireReversedDragEdgeRequest` | `macDragEdgeAwaitedViewport.isSome()`（`:23732`）；该值只在 `:6225-6233` 写入，且要求 `macTextCapture.scroll` 存在 + `internalRendererAckDragEdgeViewport` 返回 OK | **会走到函数但自我拒绝**：写入路径要求 `facts.gestureEpoch != 0`（`freezeMacTextCaptureTarget` 对非 publication 要求 `gesture != 0`），故 `ticket.gesture != 0`，而 Linux 的 `fifo.binding == 0` → `:23748` 立即 `return` | 无影响。即便越过该行，`internalRendererRetireReversedDragEdgeRequest` 在非 macOS 恒返回 `CJGUI_INTERNAL_RENDERER_SCENE_STALE`（`composable_ui_mac_edge_scroll.cj:41-45`），什么都不改 |

**结论**：不要求 native 侧实现 `owner_consumed_pointer_fifo`。理由不是「路径不会走到」（消费点 2 会走到、
消费点 3 对特定消费者会走到），而是：走到的地方 FIFO **不参与任何判定**（消费点 1/2/4），或者
**需要它参与判定的是 macOS 专有的滑块捕获语义**（消费点 3，且它在 Linux 上不成立是正确结论——
Linux 没有 `ack`/`fifo` 这套原生指针流协议）。**交给 Lead 的决定点**：若将来要让 Linux 支持
「滑块捕获 + 已消费指针流对齐」语义，需要 native 实现 `cjgui_internal_renderer_owner_consumed_pointer_fifo`
并返回 1；在那之前保留具名拒绝，不假装有流。已在代码注释里写清这一点（现 `:2065` 前注释）。

**pointer BEGIN origin 家族（4 处，`runtime_renderer_session.cj:2003/2012/2023/2037`）**

- 门谓词 `internalRendererSupportsPointerBeginOrigin()` 在 Linux/Windows 恒 `false`（已加显式 Linux 支）。
- 消费点：`composable_ui_window.cj:16618` 的 `requiresBeginOrigin`、`:15586` 的 `publishMacTextPointerBeginFrame`。
  前者恒假 → Linux 走「普通 pointer BEGIN 守卫链」（`strictBegin` / `reanchorStalePointerBegin`），
  后者直接 `return`。两条都是 macOS 的 pointer-capture 认证协议，Linux 不进入。
- **结论**：具名拒绝正确，无影响。

**`internalRendererConsumedInputProvenance`（现 `:2552` 残留支）**：Linux 全零 provenance。
消费点是 owner 完成票据的守卫，全零让它们具名拒绝；不伪造「一条已消费输入」。已加显式 Linux 支。

**拖拽边缘滚动（`composable_ui_mac_edge_scroll.cj:41/55/69`，写集外）**：Linux 落 `SCENE_STALE`/`OK`。
写入路径要求 macOS 的 `ack_drag_edge_viewport` 原生协议，Linux 的 probe 先行自我拒绝（§3.4 表第 4 行）。
**建议条件**：`os == "Windows" || os == "Linux"`（保留现值），并在 Windows 侧确认是否也要这套语义——
本阶段不动，属写集外。

### 3.5 owner handoff 与 installed range 家族（本阶段**未实现**，显式记录）

**installed range（8 处，全部已加显式 Linux 支）**：`internalRendererArmInstalledRange` / `InstalledRangeReceipt` /
`ActiveInstalledRangeReceipt` / `ActivateInstalledRange` / `CancelInstalledRange` / `ReleaseInstalledRange` /
`AckInstalledRange` / `ClaimInstalledRange`。Linux 落点 = 具名拒绝（`TEXT_SERVICE_UNSUPPORTED` / `None` / `(false, None)` / 空操作）。

消费方表现（逐点核实）：

- 门谓词 `internalRendererSourceRangeSupported()`（`:2577`）与 `internalRendererInstalledRangeSupported()`（`:2563`）在 Linux 显式 `false`。
- `composable_ui_window.cj:12057` `focusNativeStatus`：`sourceOwned = false` → 走 `internalRendererFocusComposableNode`
  （普通聚焦，native 必须实现，见 §6）。**键盘编辑在 Linux 上仍有真实路径**，只是不走「原生区间安装 + 增量回执」这条优化链。
- `composable_ui_window.cj:12096` `registerInstalledRangeForNativeFocus`：提前 `return`，不注册任何 installed range。
- `composable_ui_window.cj:22310` `carriesInstalledSource = false`。注意 `:22317` 的 `sourceInstall` 还接受
  `ownerTurnBudget.isSome()`——示例**确实挂了 owner budget**（`main.cj:2601-2602`），所以选择恢复走的是
  `internalRendererInstallOwnedSourceSelection`（`:22380`，跨平台 FFI，非本次改动），而不是 installed-range 家族。
  该符号在 Linux 是被真实引用的（见 §6），属共享实现，**不是未实现能力**。
- `composable_ui_window.cj:22384` 另一半走 `internalRendererRestoreComposableSelectionForPaint`（非 Windows 共享实现，
  委托 `internalRendererRestoreComposableSelection`），Linux 同样有真实路径。

**结论**：installed-range 家族在 Linux 是「本阶段未实现的能力」，消费方**有可用的替代路径**，
不是硬失败。**不要假装支持**：native 侧不需要实现 `installed_range_arm/receipt/activate/cancel/release/ack/claim`——
验证过它们在 Linux 的未定义符号清单里**为 0**（`arm_installed_range` 不在 378 个符号中）。

**owner handoff（`composable_ui_mac_owner_handoff.cj` 8 处，写集外）**：`OwnerHandoffSupported()=false`，
`HasParkedTextFocus` false，其余具名拒绝。消费者接缝 `rangeTextOwnerSelectionTransaction` 在门为假时
直接执行事务（§4.2）。**建议条件**：`os == "Windows" || os == "Linux"`。本阶段不动。

**source-handoff（`runtime_renderer_session.cj:3054-3090` 5 处，未改）**：只有 macOS 有完整原生实现，
消费点由 `internalRendererSelectionTransferSupported()` / `InstalledRangeSupported()` 守住。

### 3.6 跨选择 transfer 与选择绘制

- **跨选择 transfer（`runtime_renderer_session.cj` 20 处 + pointer selection dispatch 4 处，未改）**：
  门谓词 `internalRendererSelectionTransferSupported()`（`:2589`，已加显式 Linux 支 = false）。
  Linux 上 `nativeIdentity` 恒 0（`internalRendererFreezePointerSelectionDispatch` 非 macOS 返回 0），
  于是 `composable_ui_window.cj:20384/21841` 的 `if (original.nativeIdentity != 0u64)` 全部不成立 →
  这条族在 Linux **结构上惰性**，不会半途进入。结论：具名拒绝正确。
- **选择绘制（`composable_ui_selection_paint.cj` 10 处，写集外）**：
  `internalRendererSupportsProxySelectionPaint()`（`:308`）= 只有 Darwin 在原生代理上画；
  `internalRendererSupportsStagedPreviewSelectionPaint()`（`:321`）= 只有 Windows 能分段装饰。
  Linux 两个都 false → `CjguiComposableUiWindow.supportsProxySelectionPaint()`（`composable_ui_window.cj:17003-17006`）为 false
  → 消费者**必须自己发布选区**（不能只发装饰然后跳过场景发布）。这正是示例用
  `rangeTextPreviewSelectionRuns` 的 `selectionBackground` run 表达选区的原因。
  **所以 Linux 在这个谓词上落 false 不是缺陷，是正确落点**——但前提是 §4.1 的第 2 项改动到位，
  否则「框架不画 + 消费者也不画」会变成选区不可见。**建议条件**：保留现值（`os == "Windows" || os == "Linux"` 会错），
  两个谓词是**后端形态**判定，不是平台判定。

### 3.7 显示值编码：空串代理协议（本轮第二个硬失败风险）

`internalRendererComposableDisplayValue(value, preserve)` 原为：

- `@When[os == "Windows"]` → `return value`（代码注释：「Windows draws the frozen scene value and has no empty-string proxy protocol」）
- `@When[os != "Windows"]` → `return if (preserve) { "" } else { value }` → **Linux 落这一支**

`preserve` 在什么条件下为真：`mayPreserveActiveLocalText`（`composable_ui_window.cj:9686-9703`）=
`preservesRecentLocalText || preservesOwnerStableText`。其中 `preservesOwnerStableText`（`:9775-9777`）
要求 `node.nodeId == focusedNodeId` 且 owner 版本未变、`previous.value == candidate.value`——
**「焦点文本框 + 正文未变」这个常态**。此时发给 native 的正文被替换成空串。

为什么 macOS 上是对的、Linux 上是硬失败：

- macOS 有 AppKit text proxy，正文由代理持有，`(preservesActiveLocalText==1 && value=="")` 是**明确的协议编码**
  （native 侧 `native/cjgui_internal_renderer.m:35935` 正是按这一对判定的），空串表示「别动原生已有正文」。
- Linux（X11 + Vulkan）与 Windows 一样是**自绘冻结场景值**的渲染器，没有这条代理协议。
  空串就是「这个节点没有正文」→ 焦点文本框在打字/聚焦时正文消失。

**改动**：Linux 显式并入 Windows 支（送真实正文），`preserve` 的连续性提示仍由
`nativeNode.preservesActiveLocalText` 字段承载（该字段对 Linux 照发）。已在被改支加注释说明。
**需要 Lead / native 确认的一点**：若 Linux native 计划实现 macOS 那套 `(preserve && value=="")` 代理协议，
这一支应当回退；按当前任务书「自绘文字」的描述，Linux 不属于该形态。这是一个**语义决定**，
不是纯机械的平台并列，故在此单列。

### 3.8 owner 调度与诊断（`owner_turn_budget.cj` 8 处，全部已加显式 Linux 支）

- 调度族：`cjguiSchedulingWorkRevision`（0）、`cjguiCommonSchedulingEnabled`（false）、`cjguiWaitSchedulingWork`（0）。
  Linux 与 Windows 并列。少功能（调度不计量），不伪报空步骤；预算责任仍由
  `begin → pumpOneTurn → end` 承担，消费者的 `finishRangeTextOwnerScheduling` 在 Linux 是显式空操作（§4.2）。
- 诊断族：`cjguiOwnerTraceBoundary` / `cjguiOwnerTraceLegacySpan` / `cjguiOwnerTraceRecord` / `cjguiOwnerTraceSetTurn` /
  `cjguiOwnerTraceExport` → no-op / 0。
  影响：Linux 不产出 owner trace，`window.exportOwnerTrace()` 无输出；属诊断能力缺口，不影响主链路。
  接通需 native 实现 `owner_trace_boundary` / `owner_trace_managed_record` / `owner_trace_export`
  （验证过它们当前**不在** Linux 的未定义符号清单里，即 Linux 侧本阶段不引用）。
- `runtime_renderer_session.cj:3217 internalRendererPreparationDiagnosticScalar`（写集内、未改）：只有 Windows 有该调试入口，
  Linux 读回 0，不伪装「已回收」。`composable_ui_window.cj` 的 workload 计数在 Linux 是空结果，
  示例的 `RANGE_TEXT_WORKLOAD` 行会显示 0 计数——属预期，不是失败。

## 4. 消费者接缝（`examples/range_text_window_app/src/main.cj`）

### 4.1 本期改动的两处（任务必须做）

1. **选区底色（原 `:1153/:1161`，现 `:1156/:1166`）**：`rangeTextPreviewSelectionRuns` 原
   `@When[os == "macOS" || os == "Windows"]`（真实现）+ `@When[os != "macOS" && os != "Windows"]`（空数组）
   → Linux 落空数组，选区底色不画。现把 Linux 并入真实现支，残留支排除 Linux。
   这是与 §3.1 配套的**两半**：框架给出 `version == 1` 的能力，消费者真的用显式选区色 run 表达选区。
2. **宿主工厂（原 `:2486` 附近，现新增在 Windows 分支之后）**：新增
   `@When[os == "Linux"] private func rangeTextCreateHost(...)` → `CjguiLinuxApplicationHost(controller,
   configuration: CjguiMacosApplicationWindowConfiguration(title, 900u32, 620u32, rangeTextEditDeltaDelivery: true))`，
   与 Windows 分支**同参数**。消费者主流程不按平台分叉：`main()` 仍是
   `cjguiRunMacosApplication { runRangeTextApplication(args) }`（该入口在非 macOS 是身份直通），
   `host` 仍只使用公共面 `CjguiApplicationHost` 的五个方法（`window/start/pumpOneTurn/isOpen/close`）。

### 4.2 其余接缝逐条确认（任务要求的第 5 项）

| 接缝 | 原条件 | Linux 落点 | 判定 |
| --- | --- | --- | --- |
| `rangeTextOwnerSelectionTransaction` | `os != "macOS"` → 直接执行 `change()[0]` | 已改显式并入 Windows 支 | **合理**：`OwnerHandoffSupported()` 在 Linux 为 false，正典在同样条件下本来就走「直接执行事务」；不是消费者自造行为 |
| `rangeTextInitialFocus` | `os != "macOS"` → 空 | 已改显式并入 Windows 支 | **合理**：`requestInitialOwnedTextFocusRestore` 是 AppKit 首响应者意图；Windows 消费者同样为空且是已工作平台，Linux 与之并列。焦点来自普通点击/framework focus 路径 |
| `rangeTextOwnerSelectionMove` | `os != "macOS"` → move + `requestOwnedSelectionRestore` + `requestRefresh` | 已改显式并入 Windows 支 | **合理**：两条公共调用都不是 macOS 专属，Linux 上语义完整 |
| `finishRangeTextOwnerScheduling` | `os != "macOS"` → 空 | 已改显式并入 Windows 支 | **合理**：`budget.finishScheduling()` 依赖 `cjguiSchedulingWorkRevision`/`WaitSchedulingWork`，二者在 Linux 显式 0（§3.8）；不伪造空步骤 |
| `extend PlainRangeTextStore <: CjguiRangeTextSelectionEditSink` | `os == "macOS"` | **不动** | **不该改**：这是 macOS 的原生文本代理选区替换链。Linux 上商店不 conform → `applySelectedSourceEdit` 返回具名拒绝 `source_selection_edit_unavailable`（`range_text.cj:726-743`），而唯一调用点 `text_session.cj:3106` 在 `submitPreparedSourceRange` 内，由 installed-range/来源接续链驱动，Linux 不进入（§3.5）。若给 Linux 也 conform，会声明一条 Linux 没有的原生写回能力 |
| `extend RangeTextWindowController <: CjguiComposableUiCandidateSelectionProvider` | `os == "macOS"` | **不动** | **不该改**：候选选区是 macOS 原生代理族（`internalRendererCandidateSelectionReceipt` 等均 macOS-only） |

`main.cj:1156` 的注释已更新为「macOS、Windows 与 Linux 共用真实实现」，并写明它依赖框架的能力版本为 1，
避免后来者只改一侧。

## 5. 写集外的 50 处：为什么没改 + 建议条件

写集限定为 `linux_application_host.cj` / `application_host.cj` / `runtime_renderer_session.cj` /
`composable_ui_mac_retirement.cj` / `owner_turn_budget.cj` / 消费者 `main.cj` / 本文档。
下列文件有 E/H/W 在飞未提交改动，本轮**不改**（避免覆盖或回退别线），逐条给出建议条件：

| 文件 | 处数 | 建议条件 | 依据 |
| --- | --- | --- | --- |
| `composable_ui_selection_paint.cj` | 10 | **保留现值**（`os != "macOS"` / `os != "Windows"`） | 这两个谓词判的是**后端形态**（原生代理 / 分段装饰），不是平台；Linux 落 false 是正确落点（§3.6） |
| `composable_ui_window.cj` | 11 | **保留现值** | 全部是 Windows/macOS 专属诊断钩子、探针与认证；Linux 落空操作/恒等/None，且都有门谓词或 `macSliderCapture == None` 前提前置（逐条见表） |
| `composable_ui_mac_owner_handoff.cj` | 8 | `os == "Windows" \|\| os == "Linux"` | owner handoff 只有 macOS 有；Linux 与 Windows 并列（§3.5） |
| `composable_ui_mac_edge_scroll.cj` | 3 | `os == "Windows" \|\| os == "Linux"` | 同上，`ack_drag_edge_viewport` 是 macOS 协议（§3.4） |
| `composable_ui_mac_resident_source.cj` | 3 | `os == "Windows" \|\| os == "Linux"` | 常驻文本来源 macOS-only，门谓词 `ResidentTextSourceSupported()=false` |
| `composable_ui_mac_text_continuation.cj` | 3 | `os == "Windows" \|\| os == "Linux"` | macOS 文本捕获接续 |
| `composable_ui_command_completion.cj` | 3 | `os == "Windows" \|\| os == "Linux"` | macOS owner 命令票据 |
| `composable_ui_selection_observation.cj` | 2 | `os == "macOS" \|\| os == "Linux"`（注意：**不是**并入 Windows） | Windows 有原生选择几何读回增强；Linux 与 macOS 一样走普通读回 |
| `composable_ui_source_recovery.cj` | 2 | `os == "macOS" \|\| os == "Linux"` | Windows 的 source install 恢复记录 |
| `composable_ui_mac_caret_edit.cj` | 1 | `os == "Windows" \|\| os == "Linux"` | macOS 插入符编辑回执 |
| `composable_ui_windows_selection_gesture.cj` | 1 | `os == "macOS" \|\| os == "Linux"` | Windows 专属原生手势 |
| `macos_application_cleanup.cj` | 1 | `os == "Windows" \|\| os == "Linux"` | 非 macOS 身份直通；**只改条件名不改语义**，且该文件不在写集 |
| `composable_ui_preparation_reuse_integration_test.cj` | 2 | 不改 | 测试文件；`linux_guest.sh sync` 已 `--exclude '_test.cj'`，Linux 构建根本不编它 |

**另一条更彻底的可选方案**（本轮未采用，留给 Lead 决策）：把「平台集合」提成 cfg 键
（本仓已有先例：`platforms/ohos` 的 `@When[cjgui_transport_verify == "on"]` + `cjpm.toml` 的 `--cfg=`），
用 `@When[cjgui_platform_self_drawn_text == "on"]` 之类的**能力名**取代平台名。
好处是表达力对的（§3.6/§3.7 的两个反例都是「后端形态」而非平台）；
代价是要动 `cjpm.toml` 与各平台 toml 生成（`linux_guest.sh` 的 `apply_platform_toml`），
超出本任务写集，且需三平台同时验证。本轮先用「显式平台并列 + 注释写判据」的方式达到同等可审性。

### 5.1 「实际是 Windows 语义」的支：并入 Linux 时必须写依据，不能靠「Linux 也没别的实现」

Lead 要求补的规则。这条规则的危险形态是「看着像 Windows 语义就并过去」——而本仓大量
`os != "macOS"` 支**并不是** Windows 语义（它们只是「非 macOS」），所以必须写成硬规则：
把一个 `os != "macOS"` 支里的 Linux 并进 **Windows** 支时，依据必须是**代码自带的判据**
（注释里写明的后端事实、或可指到行的谓词/消费点），**不能**是「反正 Linux 没有别的实现，
跟 Windows 一起最省事」。**反例同样重要**：§3.6 的两个选择绘制谓词、§5 表里
`composable_ui_selection_observation.cj` 的读回增强、`composable_ui_source_recovery.cj` 的恢复记录——
它们看起来都长成「Windows 有、别的平台没有」，但实际判的是 **Windows 的原生能力**，
Linux 与该能力无关，只能落到「没有」那一支；并错了就会去声明一条 Linux 没有的能力。

本轮实际发生的「并入 Windows」以及各自依据：

| 位置 | 并入动作 | 依据（可核对） | 若依据不成立的后果 |
| --- | --- | --- | --- |
| `runtime_renderer_session.cj` `internalRendererComposableDisplayValue` | Linux 并入 Windows 支（送真实正文） | 该支原注释自述的后端事实：「Windows draws the frozen scene value and has no empty-string proxy protocol」；macOS 的配对编码在 `native/cjgui_internal_renderer.m:35935` 按 `(preservesActiveLocalText && value.length == 0)` 判定；Linux 侧无 AppKit text proxy、走自绘正文（`native/` 侧是 X11+Vulkan 渲染器） | 焦点文本框正文变成空串 → 主验收项「自绘文字/中文正确显示」硬失败（§3.7） |
| `owner_turn_budget.cj` 调度/诊断 8 处 | Linux 并入 Windows 支（0 / false / no-op） | 两支都只依赖 macOS 的 `cjgui_internal_renderer_owner_*` 原生通道；`runtime_renderer_session.cj:3217 internalRendererPreparationDiagnosticScalar` 已经是「只有 Windows 有调试入口」的既有形态 | 伪造出 Linux 并不存在的调度计量/owner trace；下游 `finishScheduling` 会对空通道做无意义调用（§3.8） |
| `examples/.../main.cj` `rangeTextOwnerSelectionTransaction` / `rangeTextInitialFocus` / `rangeTextOwnerSelectionMove` / `finishRangeTextOwnerScheduling` | Linux 并入 Windows 支 | 四个接缝在 macOS 支调用的都是 AppKit/原生票据入口（`performTextOwnerSelectionChange`、`requestInitialOwnedTextFocusRestore`、`finishScheduling`）；Windows 是已工作平台且取同一支；`rangeTextOwnerSelectionTransaction` 的注释已写明「不支持的平台走正典在同样条件下本来就走的那一步」 | 声明 Linux 没有的原生能力；`finishScheduling` 还会空转到不存在的通道（§4.2） |
| `composable_ui_mac_retirement.cj` `internalRendererDrainComposableRetirement` | **不并**，Linux 单独一支 | 该文件自述的语义：「没有该责任的平台按'无真实回收可等'返回可以开始，而不是伪装已回收」；Linux 没有私有准备图退休队列 | 若并入 macOS/Windows 支会声明并等待一条不存在的回收队列 |

**判据形式化的建议**（留给后续）：这三类「依据」其实都是**后端形态**而不是平台名——
有没有 text proxy、有没有私有准备图/退休队列、有没有原生命令票据通道。§5 末尾提到的
cfg 能力键方案能把这层表达出来；在没做之前，至少按本表把依据写在代码注释里（本轮已做）。

## 6. 需要 native 侧配合的符号（Linux 仓颉侧真实引用）

### 6.1 编译闭包曾缺 8 个文件（已由 Lead 补齐）

`native/scripts/lib_cjgui_source_set.sh` 的命名集合是 Linux 消费者编译闭包的正确来源
（Windows 冻结包同源）。但只用这 41 个文件时 `cjpm build` **编不过**：闭包内的
`composable_ui_window.cj` 等文件引用了集合外的声明。逐个人工补入并以「去掉就再报错」验证过的
**最小补充集恰好 8 个**：

| 文件 | 补它的编译错误依据 |
| --- | --- |
| `composable_ui_scroll_owner_rebase.cj` | `undeclared type name 'CjguiScrollOriginSourceContext'` / `'CjguiComposableUiScrollOriginOwnerRebase'` |
| `composable_ui_command_completion.cj` | `undeclared type name 'CjguiOwnerCommandReceipt'` |
| `composable_ui_candidate_selection.cj` | `'CjguiCandidateSelectionDeclaration'` / `'CjguiComposableUiCandidateSelectionProjection'` |
| `composable_ui_selection_observation.cj` | `'CjguiSelectionGeometryRequest'` |
| `composable_ui_preparation_dependency.cj` | `'CjguiComposableUiPreparationDependencyProvider'` |
| `composable_ui_installed_text_intent.cj` | `'CjguiComposableUiInstalledTextIntentProvider'` / `'CjguiInstalledTextIntentProof'` |
| `composable_ui_windows_selection_gesture.cj` | `undeclared identifier 'cjguiWindowsSelectionGestureNative'` |
| `composable_ui_mac_resident_source.cj` | `'internalRendererResidentTextSourceSupported'` / `'StageResidentTextSource'` / `'ResidentCaretSource'` |

它们与集合里已有的「平台替身文件」同类（`composable_ui_mac_owner_handoff.cj` /
`_mac_edge_scroll.cj` / `_mac_text_continuation.cj` / `_mac_retirement.cj` / `_mac_caret_edit.cj`
那一段注释说明的正是这个坑）。**处置**：已按流程报给 Lead（该文件不在本任务写集），
Lead 已把 8 个文件写进 `lib_cjgui_source_set.sh` 并附依据注释；49 文件闭包下 `cjgui` 包
`cjpm build` exit=0 / 0 error。本节的错误信息保留为**依据留痕**（谁要再缩这个集合，会看到它为什么缩不动）。
**注意**：这 8 个文件里的 4 个（`command_completion` / `mac_resident_source` / `selection_observation` /
`windows_selection_gesture`）承载了 §1 提到的 11 处「闭包外否定式条件」中的 9 处；
补进闭包后它们才进入编译范围（余下 2 处在测试文件里，Linux 不编）。

### 6.2 同步脚本的一个真 bug（已报 Lead，已修复）

`linux_guest.sh do_sync` 用 `rsync -az --delete --files-from=<闭包清单>`。rsync 在
`--files-from` 模式下 `--delete` **只作用于清单里出现过的目标路径**，清单外的既有文件不会被删；
所以从「整目录同步」切到「命名集合同步」后，来宾 `src/` 仍留着 481 个 `.cj`（实测），
闭包实际上没变、构建行为与之前一致。修法是回收目录拥有权：
`rm -rf "$GUEST_ROOT/runtime/cjgui/src"` 后再 `rsync --files-from`。**处置**：已报 Lead，Lead 已在
`do_sync` 加 `ssh_run "rm -rf '$GUEST_ROOT/runtime/cjgui/src' && mkdir -p ..."`（目录由脚本完全拥有），
并加了来宾构建锁 `flock -w 1800 /tmp/cjgui-guest-build.lock` 解决并发构建互踩。

### 6.3 闭包修正后的符号账

来源：49 文件闭包下示例包的链接失败清单（本轮交叉核对 123 个符号；**最终数字以 Lead 的
`--unresolved-symbols=report-all` 探针为准**，本任务不重复出数，只做「我的落点有没有偷偷变成硬需求」这一步核对）。
与本轮改动直接相关的：

| 符号 | 要求 | 不实现的后果 |
| --- | --- | --- |
| `cjgui_internal_renderer_selection_background_version` | **必须实现，返回 1**（Lead 已认领） | 示例永远链接不上；即便链上，场景含选区背景时整场被拒（§3.1） |

本轮改动**没有**新增对下列符号的引用（逐个在未定义清单里核对为 **0**），
即 Linux 的落点确实是「具名拒绝」而非「偷偷要求实现」：

`cjgui_internal_renderer_owner_consumed_pointer_fifo`、`cjgui_internal_renderer_prepare_composable_node_batch`、
`cjgui_internal_renderer_reuse_composable_node_batch`、`cjgui_internal_renderer_drain_composable_retirement`、
`cjgui_internal_renderer_installed_range_*`、`cjgui_internal_renderer_source_handoff_*`、
`cjgui_internal_renderer_owner_trace_managed_record`、`cjgui_internal_renderer_selection_transfer_*`。

被真实引用的（Linux 主链路依赖，属 native sidecar 已规划范围，逐个核对存在）：

`..._create` / `..._destroy` / `..._configure_composable_scene` / `..._present_composable_scene` /
`..._prepare_composable_node` / `..._focus_composable_node` / `..._restore_composable_selection` /
`..._install_owned_source_selection` / `..._set_composable_owned_text_session` / `..._owner_clock_ns` /
`..._coordinate_lifetime` / `..._request_application_stop` / `..._has_unkeyed_application_exit_request` /
`..._set_window_title`（完整清单由 Lead 的探针产出）。

## 7. 未完成项与风险

1. **native 侧 `selection_background_version` 未实现前，示例不可链接**（预期，非本轮失败；Lead 已认领实现）。
2. ~~编译闭包缺 8 个文件~~ **已解决**（§6.1，Lead 已补齐到 49 文件；规范目录 `./linux_guest.sh sync` 即可复现 0 error）。
3. ~~同步脚本不会清理清单外文件~~ **已解决**（§6.2，Lead 已改为清空目录后再放闭包，并加了来宾构建锁）。
4. **§3.7 的显示值是语义决定**，需 Lead 确认 Linux 不属于「空串代理协议」形态；
   若判断相反，回退该支即可（改动是单点、可逆）。**已获 Lead 批准保留**，native 侧按自绘正文实现。
5. **滑块捕获在 Linux 仍不可用**（消费点 3，§3.4）。示例不受影响；任何同时实现
   `CjguiComposableUiPointerCaptureVersionProvider` 与 `CjguiComposableUiSliderCaptureProvider` 的 Linux 消费者
   会得到 `rejectPointerBegin`。要支持需 native 实现 `owner_consumed_pointer_fifo`。
6. **installed-range / owner handoff / 跨选择 transfer / macOS 文本捕获链在 Linux 全部未实现**，
   本阶段不假装支持；消费方有可用替代路径（§3.5、§3.6）。带 `RANGE_TEXT_SELECTION_GEOMETRY=1`、
   `RANGE_TEXT_TWO_PANE=1` 等增强诊断开关的路径在 Linux 只能得到普通读回。
7. **owner trace / 调度计量 / workload 计数在 Linux 无输出**（§3.8）。诊断能力缺口，不影响验收链路。
8. **写集外 50 处**仅记录未改（§5），其中 45 处（不含测试文件）建议在 E/H/W 落定后按表批量改条件；
   涉及 `composable_ui_window.cj` 与 `composable_ui_selection_paint.cj` 的 21 处建议**保留现值**并补一句注释说明判据。
9. **本轮未验证**：Linux 上的真实窗口、中文渲染、键鼠连续操作、外部调用改状态、缩放与关闭
   ——都要等 native sidecar 链接成功后在 X11 会话里跑，属第一阶段后续验收。
