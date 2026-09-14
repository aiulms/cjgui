# 大阶段：高效刷新与可追踪显示

日期：2026-09-12。原任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`、Terra / xhigh、原目录 `/Users/jiangxuanyang/Desktop/cangjie`。指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`（host local）。

## 完整交付

应用空闲、外部连续读取、人在控件间移动焦点时，不无故反复重建和排版整幅界面；内容或样式真正变化时可靠刷新。外部调用者和开发者能够分辨“应用内容已改变、窗口投影已接受、原生提交及实际绘制推进到哪里”，遇到暂时显示失败能保留有效工作并恢复。文档和规则集两个正常消费者直接复用此能力。

这是 GUI 框架的更新机制、自绘运行效率与开发者诊断能力，不增加专用应用功能，不建立新的审计状态机。物理中文 IME 等独立未验项继续承接，不以清零全部遗留为前提。

## 复核基础与复用

依据 [设计导航](DESIGN_INTENT_INDEX.md)、[当前共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md) 和 [高频交互研究](../research/ai-native-gui-runtime-architecture-intake.md) 中内容修改与局部视觉更新分工。研究中的旧阶段禁令不恢复。

- [通用窗口](../../runtime/cjgui/src/composable_ui_window.cj) 已有 FIFO 批量处理、sameRenderedScene/组件树比较、语义与 native 输入快照分离；复用这些正确性边界。当前 refresh 仍先 buildUi 和完整布局，再判断相等；普通消费者在外部 connection pump 后调用 refresh，读取也可能重复这些工作。
- [组件](../../runtime/cjgui/src/composable_ui.cj) 的投影 builder 仍固定 submission=-1、presented=unavailable；[native renderer](../../runtime/cjgui/native/cjgui_internal_renderer.m) 实际提交 Metal，文字由 AppKit overlay 绘制。接实际读数，不能直接把函数返回 OK 或 GPU 完成改名为人已看见。
- 多行缓存容量 16 已有实现，但 key 包含整幅 projectionVersion，其他控件更新会使原文档缓存失效；active 节点收到投影也会再次写相同文本并标记全文排版。改为稳定身份加实际内容/样式/宽度失效，不弱化输入事件版本保护。
- 原生输入代理将所有 Command 键交给 overlay，而 overlay 只识别保存/撤销，其他交给其 super。存在截获复制/粘贴/全选/文本导航的风险；先走真实事件路径复现并修正为明确已处理才消费。只读可选可复制的承诺必须保持。
- 窗口 pump 当前在 syncProjection 失败后直接 discardSession；暂时测量/绘制不可用可能导致整个窗口销毁。区分可恢复失败与真实关闭/失效，不把保留旧场景的注释当运行保证。
- 前置 [输入阶段](2026-09-12-general-input-dynamic-components-milestone.md) 已有跨行拖选、外部替换、人续写、Cmd-Z/Cmd-S/重开，30 行滚动及第二表单键盘/客户端读回证据。指导仅静态复核，未重跑测试；接受 core 23/23、Python 5/5 与探针/build 的执行范围。不同表单的无实现上下文 Agent 身份和调用记录尚需明确，动态 ID 客户端本身不等于独立模型验收。

## 连续实施

### 一、正确且轻量的刷新入口

提供可复用、兼容的刷新/失效机制，把内容、结构、布局尺寸和样式变化与只读观察、局部焦点/选择区分；集中合并同一轮有效变化。消费者显式通知或框架提供可靠的变更结果均可，具体最小 API 由执行 AI 决定。不能只拿业务 content version 当全部 UI 版本，主题、资源、层级-only 和窗口 resize 必须仍刷新。原 refresh 保守语义如需改变，迁移说明和消费者必须一起更新。

只读 GET 和变化读取不制造投影版本，不使排队输入失效；重复无变化请求应避免 buildUi/布局/native 重交。焦点与选区独立更新仍对外可读。缓存按实际依赖复用，原生回收有界，普通无变化绘制不能不断写回同一全文。先提供简单确定的正确性与工作量证据，不做全仓性能重写。

### 二、真实显示进度与有限诊断

从当前 window/session/native 的真实路径提供实验性只读状态：窗口/会话身份、当前投影与最后接受/提交版本，能够观测的 Metal 完成与 overlay 绘制版本、最近失败/待刷新原因。按实际需要最小化字段，不复制文档真相或构造层层 Bool 摘要。已有 submission 字段只能承载对应事实，不能混淆业务版本、语义版本和帧序号。

Metal 完成不等于 overlay 已画，更不等于用户肉眼看见。若平台没有可信的整体呈现观测，继续保留 presented=unavailable，并明确已知的各部分进度。不得为了把标签变绿引入截图推断。层级-only 更新可不重交像素，明确它与已提交图像的对应关系。异步回调要携带所属会话/提交身份，关闭后不能访问已释放对象或污染重开窗口；晚到回调不能覆盖新版本进度。

公开客户端可读这些状态，并提供有超时、明确目标身份/版本的等待入口（如适合现有 API），区分 pending、failed、closed、timeout；不忙轮询、不无限等待、不把读状态变成刷新画面的隐式命令。不得暴露私有 capability、原生指针或整份文档到诊断。

### 三、暂时失败与接续恢复

对已打开窗口的暂时测量失败、drawable 暂不可用或受控提交失败，保留最后有效输入/画面快照和领域内容，显示或返回清楚状态并有界重试/显式触发恢复。避免每次失败销毁窗口，也避免立即无限重试。永久失效、真实用户关闭与正常资源销毁走明确终止路径。

候选场景必须先完成验证才更新有效快照；不能出现语义宣称新画面、输入仍映射旧对象却没有版本说明的混合状态。期间已执行的业务操作不能伪造回滚；外部按领域版本观察新内容，显示进度诚实落后。恢复后显示最新有效内容，旧排队输入依身份规则拒绝或处理，不静默挪用。

### 四、正常消费、可复现性能与回归

在文档和规则集消费者接入通用刷新机制，保留默认无外部连接的正常使用。用受控数据给出空闲、连续只读查询、选择移动、局部内容改动、字体/resize、层级-only 变化的 build/layout/native-submit/TextKit 重排计数和测量环境；报告前后实际差异及仍需全文工作的情况，不承诺固定 FPS。计数读取应是正常诊断接口的轻量消费，不能另建报告驱动开发体系。

暂时失败、延迟完成、关闭后回调、较新提交先完成等用针对性可控 seam 验证生产路径；探针与真实 GUI 证据分开。完成正常窗口的外部批量修改→状态读回/进度等待→人接续编辑，验证 Cmd-A/C/X/V、只读复制、Command 文本导航与保存/撤销的优先级；测试剪贴板使用临时内容并保护用户原内容。

前置物理中文 IME 若桌面和输入源可用，可补实际候选/组合/提交/删除/粘贴；不可用保留待验，不反复撞锁屏。补第二表单独立消费：可让无实现上下文 Luna/Terra 使用公开帮助、客户端和 descriptor 执行动态发现/调用并返回具体证据，不能预填业务请求答案。

按 AGENTS.md 做受影响 core/客户端/窗口/原生探针及 root build --skip-script、差异/公共声明检查。公共 API 和 native/跨模块检查影响；已知 CodeLattice/GitNexus 覆盖不足用源码和运行证据补足，不反复重建索引。协议字段演进及空 UTF-8 的 `-` token 写清兼容规则，不能把未知状态误当成功。

## 执行与回报

不新 worktree、不切分支、不 stage/commit/push；指导只做文档、复核和指派。必要时按阶段最小调整 runtime_state/cjpm，不恢复旧 stage 审计链。锁屏时继续刷新/缓存、失败回归、生命周期、协议与构建，GUI 单列待验。

两次实际修复失败后按 AGENTS.md 请 Kimi Code CLI 的 kimi-code/k3 只读讨论；两轮有效建议实施验证仍失败立即回报指导，由指导给方法、执行实现。前置 selector 问题已按报告解决，请在旧阶段补简短 Kimi 会话标识与验证入口即可，无需重做讨论或新台账。

完成整个阶段或实质升级时更新 ACTIVE_DIRECTION.md 与下方交付区，主动回报指导任务。报告保留前置成果、兼容迁移、真实进度含义、性能测量及未验边界；不按单个 helper 停工。物理 IME、稳定 API、完整富文本、多平台和发布没有证据就不标完成。

## 交付区

### 2026-09-12 执行交付

实现以现有 `CjguiComposableUiWindow -> CjguiInternalRenderer -> shared operation transport` 为唯一主链，没有增加应用专属刷新状态机。消费者以完整的 `uiSceneVersion()` 声明内容、样式、资源、树和本地 UI 的可见失效，外部成功 `INVOKE` 通过 transport 的一次性 refresh signal 标记；普通循环改为 `requestRefresh()` 后的 `refreshIfNeeded()`。后者只有显式请求、声明 revision 变化或 native resize 才 build/layout/提交，`GET_CONTEXT`、`GET_CHANGES`、空闲循环和选区读取不制造投影或提交。相同像素场景不会重投 native；树/绑定-only 变化仍更新仓颉投影而不虚报 GPU 工作。

诊断为已有 `WINDOW_*` projection 的扩展：公开的是 `cjgui_window_N` 会话身份、当前/accepted/submitted scene、submitted frame、仅在真实 readback 完成时推进的 Metal completion、overlay `drawRect` 记录的 scene、pending/failure 及 build/layout/submission 计数。不公开 native token、capability、指针或文档正文。Metal completion 和 overlay draw 都不被等同于人眼呈现，故始终保持 `WINDOW_PRESENTATION_STATE unavailable`。Python `client.py wait-window SESSION VERSION --phase accepted|submitted|overlay --timeout-ms --poll-ms` 是固定间隔、只读且有界的等待入口，返回 `completed`、`pending_failure`、`closed` 或 `timeout`；超时为 exit 7。

原生临时失败不再使已打开窗口直接 `discardSession()`：候选场景先测量/验证，失败时保留最后有效 Cangjie 场景、native 输入映射和领域内容，报告 `refresh_<reason>`；空闲循环不自动重试。`retryPendingRefresh()`、一次新变更、resize 或人机事件可做下一次显式尝试。提交后只有 readback 失败时保留新提交但如实报告失败；无 drawable/encoder 等没有可用替换帧时 native 与 Cangjie 一并回退，避免新旧映射混杂。多行 TextKit 缓存改为稳定 node/resource/kind 加实际 text、字体/颜色与宽度，活动编辑器只有这些依赖变化才触发全文 layout；投影版本仍只用于输入身份检查。

输入根因已复现：input proxy 曾把所有 Command 交给 overlay，而 overlay 实际只拥有 save/undo/redo。现改为只有 Cmd-S/Z 被窗口路由消费；Cmd-A/C/X/V 在真实 `NSTextView` 上执行，其他组合（含 Cmd-Left）交给其标准 responder。AppKit 探针保存每种现有 general-pasteboard 项，使用临时内容验证复制、剪切、粘贴和导航；无并发变更时逐类型恢复，若检测到更新过的剪贴板则不覆盖它，且不读取或记录用户剪贴板。

验证（当前工作树）：

- `runtime/cjgui/shared_operation_core`: `cjpm test --no-color`，23/23；`python3 -m unittest test_client.py`，6/6。
- `runtime/cjgui`: `cjpm build --skip-script`；`verify_composable_ui_layout.sh`、`verify_composable_scene_renderer.sh`、`verify_composable_ui_window_controller.sh`、`verify_composable_ui_appkit_text.sh` 全部通过。控制器探针覆盖空闲零增量、受控测量失败保留旧 scene/pending、显式恢复、真实 readback/overlay 读数和 selection 不重建。
- 当前源码重新构建后的文档窗口：初始 work counts `1 1 1`，三次外部 `GET_CONTEXT` 保持不变；外部 `REPLACE_RANGE` 后 `scene/accepted/submitted/overlay=2`，`wait-window ... --phase overlay` 为 `completed`，counts 为 `2 2 2`。
- 当前源码重新构建后的规则集窗口：公开发现后 `CREATE_RECORD` 成功；随后 `scene/accepted/submitted/overlay=2`、`wait-window ... --phase overlay=completed`、counts 为 `2 2 2`，外部 projection 包含新增规则及其 draft 字段。

GitNexus 对 `CjguiComposableUiWindow` 返回 `UNKNOWN/not found`，变更检测只覆盖到 28 files/3 README symbols，不能用作影响范围或运行成功证据；已以源码、构建、四个原生探针、core/客户端测试和两个真实端点补证。`git diff --check` 通过。当前工作树大量相关源码本来就是未跟踪，未 stage、commit、push、切分支或清理。

未验边界：最后一次当前二进制的 CUA 肉眼窗口/Cmd-A 复验因 macOS 再次锁屏而无法读取 UI；物理中文 IME 的候选、组合、提交/删除、稳定 API、发布及多平台仍无证据。此前窗口验收不能替代这些项。


### 指导复核与接续

指导静态审阅窗口失效/失败条件、会话身份、客户端等待与当前规则列表构造，未重跑测试。接受上述 core 23/23、Python 6/6、四探针/build、两个窗口端点 work counts 与进度推进的执行范围；最终当前二进制肉眼/快捷键和物理 IME 未验保持。

恢复保证需修正：失败只清 refreshRequested，lastControllerSceneVersion/lastViewportResizeVersion 未更新为已尝试条件，下一次 refreshIfNeeded 仍可能因版本差进入同步；现有失败→显式恢复测试不足以证明连续空闲不重试。对象内会话计数会使多个新窗口都出现 cjgui_window_1，需验证等待归属。等待把未知响应归为 closed，固定 2 秒 socket timeout 不服从较短总 deadline，需补分类与边界。

接续[通用长列表与屏外共同操作](2026-09-12-virtual-collections-offscreen-operations-milestone.md)，必要正确性修正与虚拟列表、稳定导航、屏外批量真实操作一起交付。当前规则窗口全量构造行按钮，不能以已做裁剪推定大集合效率已完成。
