# 只读架构咨询请求：Windows 文本输入来源/安装交接 + 线程归属

只读分析，不修改文件、不运行构建、不操作桌面。可读仓库内任意文件核对事实。
请质疑本文的既有归因（尤其“重盖掩盖了来源”“M:N 迁移”两条），不要把它们当前提；
给出机制方案、区分实验与验收反例。两节相对独立，请分别作答。

## 0. 背景与不变量

- 同一个 Pharos 编辑器（Cangjie 产品 + CJGUI 框架）接 Windows 后端：Win32 + D3D11/DXGI +
  DirectWrite + IMM32 + WIC。Windows native renderer 在
  `runtime/cjgui/platforms/windows/native/cjgui_windows_renderer.c`（当前 sha256
  6bb6dc61e51453292bac1e70eb6047940079221df930cd44fdaa86e362b81c16）。
- 框架侧消费在 `runtime/cjgui/src/composable_ui_window.cj` 与
  `runtime/cjgui/src/text_session.cj`（E 的现行契约；E/H 有在途改动，不能大改共享头/契约）。
- 不变量：accepted 场景版本、binding epoch、owner 串行、具名拒绝不污染正文/历史、
  输入恰一次、不静默丢字符/导航/IME 终态。
- 已确认必须返工（复核 `docs/plans/2026-10-05-windows-pharos-editor-package.md`
  的 windows-input-pump-review-20261006 节）：
  1) present 成功后把 FIFO 中 kind 28/51/52/33 的 projectionVersion（及几何槽）无条件
     重盖成新 scene；2) source-install 门只计数、直接丢弃字符/导航/组合开始，
     IME RESULTSTR 在门挂起时被消费但无 owner 事务；3) `pump_windows_messages`
     在 FIFO 空且 remaining==0 时先返回、未 PeekMessageW；4) 线程失配证据不足。

## 1. 输入来源与安装交接（主问题）

### 1.1 机制反例原件（已归档，可直接读）

- `artifacts/windows-pharos-20261005/guidance-review-20261006/replay_native_input_seams.py`
  与 `..._result.json`：从当前源码抽取的生产分支在 host clang 执行。
  关键观察：
  - `restamp_and_clear_pending`：kind 28/51/52/33 的事件 scene 41→42（几何同改），
    binding_epoch=5、range_start=2 保留，清 pending shadow 后 FIFO 仍有 5 条；
    kind 35 不受影响。
  - `ime_result_gate_pending`：门挂起时 IME RESULTSTR `handled=1/freed=1/
    update=0/terminal=0/successor=0/queueFull=0`；无门正控 update/terminal 各 1。
    → 用户组合结果被消费但没有任何 owner 事务或可恢复载荷。
- 背景：Windows renderer 在 `queue_owned_range_replace`（含 pendingOwnedInput* 影子链）、
  `handle_windows_ime_composition`、`source_install_gate_holds_input` 三处涉及本问题；
  `cjgui_internal_renderer_set_source_install_gate` 由框架在选区恢复（
  `armSourceSelectionInstallGate`/`finishSelectionRestore`）时挂起/解除。

### 1.2 当前生产者字段（Windows renderer 实际产生的）

事件 POD（`runtime/cjgui/native/cjgui_internal_renderer.h`）在 Windows 侧被填的字段：
kind、nodeId、projectionVersion（= 推送时 acceptedScene.version）、resourceId、nodeKind、
selectionStart/End（UTF-16）、replacementStart16/Length16、bindingEpoch
（= ownedTextSessionBindingEpoch）、acceptedBindingEpoch（当前恒 0，从未填充）、
pointerX/pointerY（逻辑坐标）、gesturePointerId/gestureEpoch（文本路径恒 0/-1）、
payload（插入文本 UTF-8）、dataTransferEventId 等。

pending shadow（本地已推未结算链）：pendingOwnedInputBase/Value（链起点/最新值）、
pendingOwnedInputSceneVersion（首笔推送时的 scene）、pendingOwnedInputBindingEpoch/
NodeId/ResourceId/NodeKind、pendingOwnedInputEventCount。语义：同一链的后续字符
以链值为 base 追加；`synchronize_owned_proxy_after_presentation` 在场景接受时若
“accepted 值 == pending 链值”则清链，否则重置选区并清链。

安装门：sourceInstallPending/BindingEpoch/RequestId；`qorr`、导航、组合开始
在此门下直接返回未消费（计数 +1），无延期队列；IME RESULTSTR 路径在门下
仍标记 handled 并释放结果。

### 1.3 框架消费门（现行契约，请以源码为准）

- 事件身份解析：`resolvePointerTarget/resolveInput/resolveSelection` 要求
  `projectionVersion == nativeInputScene.version`（严格相等，旧版本即 missing）。
- 前缀门 `activationPrefixGate.admit`（Windows 生产者从不产生 activation prefix）。
- kind 51 路由：`routeOwnedTextSessionRangeEdit` → `session.replaceRange16` →
  `submitRange16`；写入路径要求 `selectionCoordinatesMatchMirror()`（会话选区版本==
  内容版本、字节跨度可映射）且 `!selectionNeedsNativeRestore`，否则
  `selection_native_alignment_required` 具名拒绝。
- kind 33 路由：`resolveSelection` 后按 paced/非 paced 路径更新会话选区；
  `needsNativeSelectionRestore` 由选择移动/外部改版置位，经
  `confirmNativeSelectionRestored`/`confirmProxyRestored` 清除。
- kind 27/45/46 的 press-lease：lease 需 `currentAcceptedBindingEpoch(resolved)!=0`、
  连续性只看绑定身份（`pressLeaseIsContinuous`），不受版本推进影响。

### 1.4 观测到的最小失败（Windows 运行）

- 连发两个字符（无间隔）时，第一笔被接受后应用重发布新 scene；第二笔事件携带
  旧 scene（链上 pending 版本）在消费侧被 `resolvePointerTarget` 版本相等拒绝；
  当前以“present 后重盖”绕过——复核判定为掩盖来源，必须撤掉。
- 单字符 + 真实节奏可落 owner（owner 全文可核）；连发丢第二笔。
- 选区恢复（install gate 窗口 ~100-300ms）内到达的字符被门丢弃（计数），
  用户可见丢字。
- IME：门挂起期间 RESULTSTR 被消费无事务（上节反例）。

### 1.5 需要你裁决的问题（第 1 节）

1. **最小来源与交接契约**：撤掉重盖后，要让“正常同绑定短暂安装后的输入按 FIFO
   恰一次兑现”，生产侧（Windows renderer）与消费侧（框架）各需哪些最小字段/
   队列归属/顺序保证？请给出可直接实现的方案（字段清单 + 状态机 + 终态定义），
   并区分四类来源的处理：同绑定纯刷新（scene 变、文本/绑定不变）、本人前一笔
   提交后像（pending 链自身的推进）、外部正文改版（owner 变、需锚点/具名拒绝）、
   换绑/ABA（binding 变）。
2. **重盖撤除后的等价机制**：第二笔旧 scene 事件被消费侧严格版本门拒绝——
   正解应是消费侧对“已证来源”的接续，还是生产侧不携带旧 scene（例如推送时
   取最新已接受版本并在链上标注链起点版本）？哪个更符合现有契约、改动更小？
   给出区分实验（同一输入在两类实现下的期望轨迹与反例）。
3. **门下的输入交接**：安装门期间到达的字符/导航/IME RESULTSTR 的最小有界
   交接（容量、顺序、来源、终态）应归生产侧还是消费侧？如何保证“安装完成后
   恰一次兑现、换绑/冲突不重放到新目标、满载明确失败且保全用户输入”？
   IME RESULTSTR 在门下应延期还是具名拒绝并保留可恢复载荷？给出可执行的
   反例（连发、自动重复、代理对、组合提交）与期望结果。
4. **与 E 的边界**：上述修复哪些必须动共享框架（列出受影响函数与最小 diff 面），
   哪些可以留在 Windows 窄平台层？不得放宽共同旧事件守卫。

## 2. 线程归属（第二问题，已有首次真实失败证据）

### 2.1 证据

- renderer 的 `require_owner_thread` 在首个拒绝点记录（bounded 12 条）：
  `mismatch expected=13452 actual=17580 token=1` ×12（持续、同 session、同值），
  实际返回码 = NOT_MAIN_THREAD(1)。owner=13452 是 `cjgui_internal_renderer_create`
  时的 OS tid（= HWND 创建线程）；actual=17580 是此后调用泵/start_viewport 的
  OS tid。两次真实故障形态：a) 启动期 `start_viewport_not_main_thread`（scene=0
  从未接受，spin 9.9 万回合）；b) 交互中 turn≈290 起 `refresh_not_main_thread`。
  另有 5 轮对照（含 cjProcessorNum=1 三轮）未复现——非确定性。
- Cangjie 运行时文档明示：“仓颉线程可能被调度到不同 OS 线程”（CFFI 约束节）、
  “M:N 线程模型”。运行时 DLL 暴露的环境变量候选：cjProcessorNum（范围
  (0, 2*hardware_concurrency]）、cjStackSize、cjHeapSize、cjSingleModeThread/
  cjSingleModeThreadList（后者在字符串上下文中更像内部符号）。
- Windows 侧约束：HWND 的消息队列绑定创建线程；D3D11 对象有线程规则；renderer
  的 guard 是“创建线程 == 当前线程”，不删、不动态改 ownerThreadId（复核要求）。

### 2.2 需要你裁决的问题（第 2 节）

1. 在 Cangjie M:N 运行时下，Windows renderer 的正确线程架构是什么？
   请比较并推荐最小可行方案：
   a) 运行时限线程（如 cjProcessorNum=1）——能否阻止主 cjthread 迁移？
      有无文档/机制依据？副作用（spawn 的视觉解析线程与主循环串行化）？
   b) renderer 自持一个专用 OS 线程（窗口 + 消息循环 + 工作项），所有 API 从
      任意 cjthread 汇集到该线程执行并同步返回（marshaling）——改动面与风险；
   c) 失配时在调用线程重建窗口/交换链并迁移（re-home）——语义与资源风险；
   d) 其他。
2. 若选 b)，最小实现边界：哪些 API 必须 marshal（pump/present/焦点/文本会话/
   探针），哪些可保持直调（纯读诊断）？如何保持 owner 串行与回调归属（
   WndProc 事件推入 FIFO 的顺序与可见性）？给出状态机与失败/关闭路径。
3. 区分实验：如何用最小实验区分“主 cjthread 迁移”与“不同 cjthread 跑循环”？
   （可在 renderer 侧加什么一次性证据；运行时选项是否可作对照。）
4. 若需动共享层（Cangjie host），最小面在哪里、如何不触碰 E/H 在途写集？

## 3. 输出要求

- 每节给：结论、最小方案（字段/状态机/接口）、区分实验（可执行）、验收反例
  （期望 PASS/FAIL）、需要与 E/H 对齐的点。
- 明确列出你不同意的既有归因及依据；不确定处标注“需实测”。
- 不要给泛泛建议；按当前源码符号与文件定位。
