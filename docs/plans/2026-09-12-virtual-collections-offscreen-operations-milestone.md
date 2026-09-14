# 大阶段：通用长列表与屏外共同操作

日期：2026-09-12。原目录、原执行任务 `01a08f82-b682-73c0-a9b0-25a27bc5ffd8`，gpt-5.6-terra / xhigh。指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`（host local）。

## 完整交付

开发者用可复用集合组件展示上千条记录，框架只构造/布局/提交视口附近的行。人能滚动、选择、键盘导航，在列表变化后继续操作正确对象；外部系统能在已有授权内发现并批量修改屏幕之外的记录，不需要逐条滚动。可见行随后显示实际更新结果，人的未提交编辑与选择按现有领域规则保留或明确冲突。

同时修正前置刷新恢复与等待边界，以可靠底座承载大集合。本阶段不做专用规则管理产品，不引入数据库、聊天或全套表格；固定行高的可组合列表即可形成完整框架能力。

## 复核与复用

依据 [设计导航](DESIGN_INTENT_INDEX.md)、[共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)、[前置刷新阶段](2026-09-12-efficient-refresh-display-progress-milestone.md)。

- [当前布局](../../runtime/cjgui/src/composable_ui.cj)、[窗口](../../runtime/cjgui/src/composable_ui_window.cj)已有裁剪、滚动区、稳定输入身份、失效合并与显示进度。复用这些能力，保留 native 场景节点上限，不靠无限提高上限解决长列表。
- [规则集窗口](../../runtime/cjgui/examples/rule_set_window_app/src/main.cj)当前对 `collection.allItems()` 每项构造按钮，全部进入组件树；只裁剪像素不能减少全量创建/布局。用通用集合入口替代此路径，native 不得识别规则字段或集合业务类型。
- [规则领域](../../runtime/cjgui/examples/rule_set_application/src/rule_set_editing.cj)已有 `BATCH_SET_ENABLED`、稳定资源 ID、草稿冲突与版本保护。直接复用屏外批量能力，不另造批次真相或跳过授权；公开客户端已可动态发现调用。
- [文档窗口](../../runtime/cjgui/examples/shared_document_window_app/)及其工作区可作为不同数据/行内容的集合消费者，或选择现有合适的普通窗口组合；用两个不同消费例证明组件复用，不以无窗口模型测试替代第二个组件消费者。
- 前置报告 core 23/23、Python 6/6、四探针/build，两个当前窗口端点的只读 work counts 不增、外部改动后进度推进均接受其执行范围。最终当前二进制 CUA 肉眼/快捷键与物理 IME 仍未验。指导本轮静态复核，未重跑这些验证。

## 必要旧问题与诊断方法

这些修正阻塞依赖它们的恢复/等待验收，不阻塞集合接口与布局实施。

1. **失败重试条件：** `noteRefreshFailure` 只清 refreshRequested，失败时 lastControllerSceneVersion/lastViewportResizeVersion 仍是上次成功值；`refreshIfNeeded` 又因版本差异进入同步。用成功 v1→声明 v2→一次受控测量失败→连续无新变化 refreshIfNeeded/pump 验证 build/layout/failure 次数是否停止。resize 失败同测。区分最后成功状态与最后已尝试的失效原因/版本；显式 retry、真正新变更或 resize 才重试，不能把失败候选标成成功来消除差异。
2. **会话身份：** 当前 windowSessionGeneration 是每个对象从 0 开始，多个窗口实例首开都可能是 cjgui_window_1。检验同进程两个窗口、销毁后新对象、重启/重新绑定 endpoint 时是否可误满足旧等待。使用真正不混淆的非敏感会话身份，并在等待中验证所属上下文；不得暴露 native token。
3. **等待结果与截止时间：** 目前未知/缺失进度字段或非 SNAPSHOT 被归成 closed，socket 单次 timeout 固定 2 秒，不跟 wait-window 总 deadline。用缺字段、拒绝响应、连接关闭、延迟响应分别检验错误分类；等待预算应约束连接/读取与重试总耗时，未知不能冒充关闭或成功。固定间隔读取可以保留，不引入推送服务器。层级-only 更新不产生对应像素提交时，应明确等待哪个等价图像版本，不能让默认等待无解释地超时。

这些是静态发现的具体路径，先复现；不把注释或 helper 测试当真实恢复证据。Metal completion 当前只随 readback 观测更新，继续如实说明，不必本轮扩展为全帧异步回调系统。

## 新框架能力

### 一、可组合虚拟列表

提供实验性、无业务字段的集合数据访问与行构造入口：集合总数、稳定 item key、按范围读取/构造、行高和行间距、视口及少量缓冲区。只为可见范围及缓冲区创建行节点，滚动范围按总数计算；嵌入已有布局、自绘、主题和资源主链。边界包含空列表、一行、首尾、极小视口、resize、快速跳转和大偏移溢出检查。

领域拥有记录，组件只拥有显示范围/滚动锚点等交互信息。不要通过先生成全部组件再切片伪装虚拟化。如消费者领域快照仍需全量扫描，明确剩余成本；用范围访问减少框架的节点/布局/提交开销即可，不宣称整个数据管道已 O(visible)。

### 二、稳定选择、键盘与动态数据

选中项、焦点项和滚动锚点按稳定 key 关联，不能用当前行索引替代身份。方向键/PageUp/PageDown/Home/End 等集合导航在列表拥有焦点时生效，不能截获详情文本的编辑命令；移到未物化行时按需显露并绑定有效节点。外部操作屏外对象无需改变人的滚动位置，应用显式 reveal 才定位。

增删、重排、过滤、行复用、同一位置换资源后，不串输入/选区/详情。选中行删除与焦点离开物化范围采取明确策略，拖动/排队事件按已有身份失效规则处理。滚动只改变视口，不生成领域内容版本。一个有界导航/锚点 API 足够，不引入完整表格选择或排序产品。

### 三、外部理解与屏外操作

区分逻辑集合与当前物化的窗口节点。对外提供集合身份、总数、当前窗口范围和选中 key 等必要上下文，已有领域接口负责授权对象发现和实际动作；视口外不伪造可见节点、焦点或绘制进度，也不删除其合法操作资格。若需要分页发现，分页必须受授权范围及版本约束，结果有界。

用现有 BATCH_SET_ENABLED 或等价现有领域批次，在一次授权调用中修改至少 100 条非当前屏幕记录；验证读回、版本、未授权目标/旧版本拒绝、人的不相关草稿保留。随后人滚动到目标查看正确内容并继续编辑。不要为了验收扩大授权、模拟鼠标滚动 100 次，或把验证写到应用业务分支。

## 验收与交付

正常规则集窗口消费组件，第二个不同领域普通窗口也消费同一 API。使用临时数据，框架布局验证至少 2,000 项；普通领域若有合法容量限制，在其限制内验证上千条/至少 100 条屏外批次，不为数量盲目提高领域上限。比较不同总数下的实际构造节点数、布局数、native 提交大小与缓存，证明受可见行及缓冲区约束；列明控制器扫描/协议全量读取的剩余成本。

实际窗口验证滚动首尾、resize、键盘导航、选择后外部增删/更新、节点复用与详情接续；公开客户端独立发现对象，批量改屏外记录并读回，然后窗口显露目标。允许一个无实现上下文 Luna/Terra 用公开 docs/help/API/descriptor 进行验收，报告是否真实 Agent 参与，不能把执行 AI 手写请求当独立模型证据。

按 AGENTS.md 验证公共 API/跨模块/native 影响、相关领域与 core、客户端等待、布局/窗口/渲染探针和 root build --skip-script、差异与声明。前置不受影响的成果不每小步全量复跑。继续保留 presented=unavailable 的整体呈现边界，不能用其阻塞正常工作，也不能改标签假装完成。

锁屏只跳过具体 GUI，推进集合模型、范围布局、交互身份、失败恢复与等待测试、构建和公开示例；不反复尝试解锁。两次实际修复失败及两轮 K3 后升级按 AGENTS.md 跨阶段累计。保持原目录、Terra/xhigh，不 stage/commit/push/切分支；指导只复核规划。

完成完整阶段或实质升级时更新 ACTIVE_DIRECTION.md 和下方交付报告，主动回报指导任务。报告包含必要旧问题结果、新 API 两消费者、屏外真实调用、工作量与遗留；物理 IME、稳定 API、发布、多平台仍无证据不标绿。

## 交付区

### 2026-09-12 执行交付

已在原目录、原任务完成本阶段，不建 worktree、不切分支、不 stage/commit/push。

- 前置缺口：`CjguiComposableUiWindow` 现在独立保存最后成功和最后尝试的声明/resize 条件。控制器探针先复现旧 v1→v2 测量失败后空闲重复提交（旧退出 44），再验证同一失败条件不重试；真实 AppKit resize 的失败路径同样验证。会话标识改为进程 nonce 加单调窗口代际，同进程并存/关闭重开均不同且没有 native token。Python wait 使用总 deadline，8 个测试覆盖 delayed timeout、ERROR、非 SNAPSHOT、连接关闭和 hierarchy-only accepted。
- 框架 API：新增固定行高 `CjguiComposableUiVirtualListSource`、稳定 key 状态及 `cjguiComposableVirtualList`。2,000 项探针只构造首屏 7 行，直接跳至 1,500 与末项仍为小范围；另覆盖空/单行/极小视口、resize、饱和大偏移及异常大视口。虚拟行上限 128，保留 native 1,024 节点上限而非提高它。逻辑范围通过 `WINDOW_COLLECTION` 投影，总数、当前 materialized range 和 selected/focused key 与 `WINDOW_NODE` 明确分离；只有完整 `GET_CONTEXT` 授权能读该元数据。
- 两消费者：规则集窗口已不用 `collection.allItems()` 建按钮，直接以 range domain 取行；共享文档窗口是第二个实际普通窗口消费者。两窗均已构建，后者在真实窗口中从说明切换至笔记。规则集真实窗口接受 End 键，列表从首屏转至 94–100，并显示 7 个具体按钮。
- 屏外实际调用：运行中规则集的公开 descriptor 发现 101 项。公开客户端一次 `BATCH_SET_ENABLED` 对 1–100 个 target 生效；错误 capability exit 5、陈旧版本 exit 4、成功结果 `batch_applied`。读回第 1/100 条为 enabled，真实窗口中第 100 条为 on 并可把保留天数草稿编辑为 9；未在批次中的第 101 条人类草稿 `human_draft_101` 仍在窗口。`wait-window --phase accepted` 返回 completed。此为执行端公开客户端，不宣称独立模型/Agent 验收。
- 验证：shared core `cjpm test` 24/24；rule-set application `cjpm test` 12/12；Python 客户端 8/8；layout 与 window-controller native probes；规则集/共享文档当前 bundle build 与实际 UI；根 `runtime/cjgui` `cjpm build --skip-script` 均通过（macOS 15.4 SDK）。`git diff --check` 未覆盖未跟踪源文件，改以相关写集的尾随空白、`allItems()` 和退役 stage 扫描补证。现有 GitNexus 索引对新增符号返回 UNKNOWN/0 affected，故未将其当作通过依据。

遗留：虚拟化保证的是框架的构造/布局/提交，而非完整 GET_CONTEXT 序列化或导航时的领域 range 扫描；物理中文 IME、整体 presented、稳定 API、发布、多平台未验。两个真实窗口保持运行以保留临时未保存验收状态。


### 指导复核与接续

指导静态复核范围构造、锚点状态、失败条件与客户端等待，未重跑测试。接受上方针对性执行范围；失败最后尝试条件与会话/等待修正有实际实现，2,000项是布局探针，普通规则窗口为101项。

锚点key尚未在布局中用于动态重定位；空key item被跳过会使纵向子行压缩，注释的“空洞”并未建立。固定高度/重复身份及部分行overscan=0需要补验。实际在显示94–100时修改1–100，不足以证明100条全部屏外；错误capability也不替代有效capability中未授权目标的检查。独立Agent未跑，报告已正确区分执行客户端。

这些修正与[可组合浮层、菜单与对话框](2026-09-12-composable-layers-menus-dialogs-milestone.md)一起推进，保留前置真实成果，不重做已通过的同类修复或抹掉缺口。
