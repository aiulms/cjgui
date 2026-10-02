# CJGUI runtime 与样例

更新：2026-10-01。状态：[ACTIVE_DIRECTION.md](ACTIVE_DIRECTION.md)。本页说明已有 API 与使用入口，不另定义项目定位、架构或当前任务；规范归属见[文档导航](../../docs/README.md)。
仓颉包当前名为 cjgui，版本 0.0.0，输出 static；不承诺稳定公共 API。

## 当前目录

- src/：runtime、窗口投影和 demo_support；部分旧模块仍是摘要模型，需读源码确认。
- shared_operation_core/：不链接 renderer/AppKit/Metal 的普通 core 包，包含通用契约、socket transport、列表消费者和公开客户端。
- native/：平台桥接与 AppKit/Metal 自绘后端；原生接口内部使用，普通应用经公开仓颉宿主/组件入口消费。
- demo/：程序化状态/harness 样例，目前不能当作窗口应用。
- examples/shared_operation_window_app/：正常启动的 macOS 共同操作窗口；人类窗口输入和受授权的本地外部操作进入同一列表。
- examples/shared_operation_second_consumer/：只消费 core 的列表命令行消费者，使用不同数据和授权范围。
- examples/backup_rule_config_consumer/：不同领域的无窗口配置消费者，含消费者专属字段和动作。
- examples/rule_set_application/：纯仓颉、多记录、稳定 ID、草稿/撤销和版本化本地规则集文件领域。
- examples/rule_set_window_app/：普通 macOS bundle 消费者，组合通用列表/详情窗口；`zsh run.sh --build-only` 只构建并签名，不构成 GUI 验收。
- examples/rule_set_second_consumer/：不依赖 renderer 的独立规则集消费者，真实 socket 验收动态创建、草稿应用和有界变化读取。
- probe/：针对性探针，不是正常库消费的替代品。
- native/scripts/：相关验证入口。

## Experimental：定义可组合窗口

当前是通用主链初版，API 仍为 experimental。文字/资源、多行文档、通用鼠标选择、键盘焦点/动作与动态绑定生命周期已有针对性实现和当前窗口验证；完整边界见 [ACTIVE_DIRECTION.md](ACTIVE_DIRECTION.md)。

普通 macOS app 不再复制 sample launcher、native 编译或 bundle 过程；请用
[Experimental macOS 应用宿主](MACOS_APPLICATION_HOST.md) 的
`CjguiMacosApplicationHost`、`cjgui_macos_app.sh` 与统一 runner。两个现有窗口
消费者是这个入口的兼容实例，而非新应用的 native 依赖。

新建应用优先使用 `scripts/create_macos_application.sh ui-only|collaboration`；需要在临时目录证明
没有隐式连接当前工作区时，使用 `scripts/export_framework_preview.sh` 导出源码预览后再创建。runner 的
`source_origin`/`resource_origin` 日志用于核对实际预览来源；验证时清除继承的
`CJGUI_NATIVE_SOURCE_DIR`，但不删除开发者的显式覆盖能力。完整的工具链选择、路径依赖、资源和预览边界见
[Experimental macOS 应用宿主](MACOS_APPLICATION_HOST.md)。

`src/composable_ui.cj` 与 `src/composable_ui_window.cj` 是当前的实验性
开发者入口。应用在仓颉中构造纵向/横向容器、文字、按钮、文本/整数/布尔
编辑器和滚动区，并为节点提供稳定 `nodeId`、资源 ID、动作名及样式；布局器
一次计算的 bounds/clip 同时供 Metal 矩形、命中、焦点、无障碍和事件版本校验
使用。原生层只接收这一份通用场景，不能增加领域字段或页面排列分支。

一个普通窗口消费者实现 `CjguiComposableUiController`：

1. `buildUi()` 从领域快照构造组件树；当前公开消费主要在仓颉代码中声明
   页面顺序、分组、间距、颜色和动作。这描述当前入口，不限定界面只能手写。
2. `uiSceneVersion()` 是全部渲染可见声明的廉价失效提示，而不只是领域内容版本：内容、
   树层级、样式、资源和本地 UI 状态变化都必须推进它；窗口另行分配投影身份，并在同一已显示快照上
   清空 FIFO 后才重投影。事件以节点 ID（数组 index 仅作诊断）和投影身份解析；
   原目标已经移除时调用 `rejectUiEvent()` 显示未应用原因，而不是重定向输入。
3. `applyUiEvent()` 把稳定节点的资源/动作交给已有领域入口，不在窗口或 native
   层保存业务真相；`rejectUiEvent()` 显示失效目标；`requestWindowClose()` 保留领域的关闭决策。

输入节点的有效目标是 `nodeId`、`resourceId`、节点种类与投影版本的组合。正常同对象刷新保留
正在进行的本地编辑；删节点、换绑资源/类型、禁用或转为只读会拒绝旧事件。Tab/Shift-Tab 遍历
文本、按钮与布尔节点；Space/Return 激活按钮或切换布尔值。`cjguiComposableMultilineTextInput`
默认把 Tab 用作导航，只有显式 `tabInsertsText: true` 才插入制表符。窗口可用
`bindCommand("save"|"undo"|"redo", nodeId)` 把 Command 快捷键映射到已有语义按钮，而非向
native 写业务规则。

### accepted 文字位置、选择恢复与上下文菜单（experimental）

窗口 hit/caret/水平/垂直导航共用 accepted 排版中的 `CjguiAcceptedTextPosition`，以 layout lease/stop ID 保留真实行及 primary/alternate 分支；byte+affinity 为兼容投影。重新排版使旧位置失效，查询失败须按具名结果处理。应用完成 SourceMap 转换后，使用窗口 `freezeAcceptedSelection`／`commitAcceptedSelection`提交完整票与源／代理范围；选择在精确 native 安装和 session 提交后一次发布。

模式切换或代理重建使用 `requestAcceptedSelectionRestore`／`requestTextSelectionRestore`及 `selectionRestoreState`。请求由框架持有，首次拒绝保留待办，安装确认才终结；同语义菜单关闭保留待安装映射，新用户选择／换绑会使旧请求失效。`CjguiTextSession.sourceRangeForSelectionTicket`只供准备 SourceMap 映射，不能充当输入授权或 native 安装确认。

controller 实现 `CjguiComposableUiContextMenuRequestHandler`提供内容，框架从现有事件队列生成右键请求并保持选择。用 `cjguiComposableContextMenuBounds`／`cjguiComposableContextMenuLayer`按请求点击点声明弹层，再以 `declareContextMenuCommand`／`invokeContextMenuCommand`接已有公共命令；失效目标被拒绝，Esc／外部点击关闭和焦点恢复归统一窗口机制。普通消费者见 [range_text_window_app](examples/range_text_window_app/src/main.cj)；真实右键验收入口为 `native/scripts/verify_range_text_window_app_context_menu.sh`。独立位置输入验收入口为 `native/scripts/verify_range_text_window_app_position.sh`。

`positionWorkCounts()`提供正常构建的 process-local prepares、queries、line-builds、cache-hits；计时未启用时标 unavailable。macOS 原件与未扩展范围见 [E 最终证据](</Users/jiangxuanyang/Desktop/cangjie/artifacts/e-macos-position-20260930/evidence-index.json>)，签名／指纹见 [产品 H 最小契约](</Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/e-text-position-20260929/m1-m2-overnight/README.md#h-可消费最小契约不要求-h-追逐在途文件>)；本节不承诺稳定 API 或 OHOS V1。

### 树形数据与多选（experimental）

`composable_ui_tree.cj` 提供与既有虚拟列表共用的树入口，应用只实现数据来源：

    public class CatalogSource <: CjguiComposableUiTreeDataSource {
        public func childCount(parentKey: String): Int64 { ... }   // 根用 ""
        public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode { ... }
    }

    let projection = CjguiComposableUiTreeProjection(source)   // 构造即建一次 O(N) 索引
    let selection = CjguiComposableUiTreeSelection(projection)
    projection.setExpandedBatch(projection.groupKeys(), true)  // 一次集合修改、一次重建
    selection.click("record-12", command: true, shift: false)  // Cmd 切换；Shift 走 moveFocus(extendSelection)

    // 只物化视口+overscan：把投影接到既有固定行虚拟列表
    let listSource = CjguiComposableUiTreeListSource(projection, selection) { row, isSelected, isFocused =>
        ... // row 带真实稳定 key/depth/group/expanded，禁止从文案或 resourceId 猜 key
    }
    cjguiComposableVirtualList(nodeId, "tree", contentNodeId, listSource, listState, 30, 4, 6, style)

`CjguiComposableUiTreeSelection.snapshot()` 返回 keys/focus/anchor/选择与投影版本；窗口控件点击事件带
`modifierFlags`（AppKit 位，见 `CJGUI_UI_MODIFIER_*`），消费者据此实现普通点击/Cmd/Shift 语义。

### 运行时生成式接入（experimental，已接通公开闭环）

应用注册能力目录（组件/属性/动作/字段 + 深度/节点/属性/字符串上限），外部经既有连接提交受限结构描述，
经校验与既有组件展开后进入同一场景接受链；字段、草稿与动作仍在原业务 owner。

    let catalog = CjguiGeneratedUiCapabilityCatalog()
    catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput", properties, false))
    catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿"))
    catalog.registerField("label")

    let holder = CjguiGeneratedUiStructureHolder(catalog)
    // App 实现 CjguiGeneratedUiBindingProvider：实时草稿/生效值、动作可执行性、
    // fieldResourceId（共享字段资源）与 fieldOperationResourceId（当前 owner 目标，无则 -1 → 输入禁用）
    let result = holder.submit(decodedCandidate, provider)   // 拒绝时保留上一份已接受结构与路由
    section.add(holder.buildAccepted(provider))

公开入口（`experimental`，客户端见 `shared_operation_core/client.py`）：

    client.py DESCRIPTOR generated-capabilities        # 能力目录（含 bounds）
    client.py DESCRIPTOR generated-structure           # 已接受结构 + 结构版本
    client.py DESCRIPTOR generated-fields              # 字段实时投影（draft/applied/错误/焦点/选区）
    client.py DESCRIPTOR generated-submit --structure-version N --payload-file candidate.txt
    client.py DESCRIPTOR tree-selection                # 共享选择快照
    client.py DESCRIPTOR tree-select --selection-version N --selection-command replace|toggle|range|select-all|clear|expand|collapse --key record-1

`generated-capabilities` 的每个字段行发布调用方需要的契约（类型、共享资源、owner 写操作、
声明约束与当前可执行性），外部调用者不需要猜字段名对应哪个操作：

    FIELD <fieldId> <editorKind> resource=<shared-resource-id> writer=<owner-operation|none> required=<0|1> min=<n> max=<n> callable=<0|1>

`writer` 来自应用自己的字段定义（不同领域可不同，例如草稿操作或即时 owner 操作）；`required` 与
`min`/`max` 也来自同一份 `CjguiSharedFormFieldDescriptor`，手写表单、生成编辑器与外部查询读的是
同一份声明。旧的两段式 `FIELD <id>` 行已扩展为该契约行。

候选文本格式（可替换编码；值模型为契约核心，`CjguiGeneratedUiEncoding` 为薄适配）：

    GENERATED_UI_STRUCTURE 1
    NODE 0 panel vertical
    NODE 1 nameField textInput field=label
    PROPERTY 1 nameField label 生成输入框
    NODE 1 applyBtn action action=APPLY_DRAFT
    PROPERTY 1 applyBtn label 应用草稿
    END

拒绝族（每项带具体位置与原因，且保留旧界面）：unknown_component / unknown_property / duplicate_key /
unknown_action / unknown_field / max_depth_exceeded / max_nodes_exceeded / property_too_long /
structure_version_conflict / malformed_node。参见[生成契约](../../docs/core/AI_NATIVE_UI_SEMANTICS.md#运行时生成与修改界面)与
[生成式阶段方案](../../docs/plans/2026-09-19-runtime-generated-ui-milestone.md)。

### 运行时生成式接入（原规划说明）

框架方向包含手写、运行时生成及混合界面。应用注册可用组件、字段与动作，外部提交受限结构描述，
经校验后进入同一 `buildUi()`/候选场景/自绘链；结构变化需与稳定身份、焦点、草稿、事件及资源生命周期
一起处理。现有动态组件基础可复用，旧 `demo/ai_generated_ui_app.cj` 的内存状态演示不能算接入完成。
参见[生成契约](../../docs/core/AI_NATIVE_UI_SEMANTICS.md#运行时生成与修改界面)与
[生成式阶段方案](../../docs/plans/2026-09-19-runtime-generated-ui-milestone.md)。是否已实施以 ACTIVE 为准；这不要求应用接模型或聊天运行时。

### 数据传输（experimental）

`cjgui_shared_operation_core` 提供纯值的
`CjguiSharedOperationTransferFormat`、`CjguiSharedOperationTransferOffer`、
`CjguiSharedOperationTransferAcceptRequest` 和
`CjguiSharedOperationTransferResult`。格式必须声明为 UTF-8 文本或应用自定义的结构化标识；payload、
格式标识和来源身份都有边界，当前单项最多 512 KiB。它们不携带 `NSPasteboard`、drag object、业务回调
或领域对象。

可组合窗口的 controller 可以额外实现
`CjguiComposableUiDataTransferProvider`：为一个稳定 `semanticId` 声明 source offer 或 target format，
并在 `applyDataTransfer(...)` 中把已重验节点的 immutable offer 交给已有领域入口。native 只暂存已接受
的格式、字节、来源标量和节点身份；scene commit 与纯 interaction repaint 都会重绑该表。复制/拖放后的
来源 metadata 只用于恢复 offer 的 source kind/identity/id，绝不是授权凭据；接收方仍须验证格式、payload、
目标和 CAS。

声明为 source/target 的非文本控件支持显式 Cmd-C、Cmd-V 及 macOS drag/drop；hover 复用既有
interaction paint。输入框仍优先保留系统文本编辑、IME 和 Cmd-A/C/X/V。没有声明的节点不会读取剪贴板，
取消、超限、格式不匹配、已失效/只读目标均不会调用领域修改。当前仅支持 copy、有界 UTF-8 文本和应用
声明的一个结构化文本格式；不支持 move/delete、文件 promise、文件/大流传输或后台剪贴板监控。

```text
zsh runtime/cjgui/native/scripts/verify_composable_data_transfer_native.sh
zsh runtime/cjgui/native/scripts/verify_composable_data_transfer_window_integration.sh
zsh runtime/cjgui/native/scripts/verify_shared_document_transfer_chain.sh
zsh runtime/cjgui/native/scripts/verify_composable_data_transfer_cross_window.sh
```

该探针真实创建 macOS 窗口，覆盖显式 copy、外部 text paste、64-byte 超限拒绝、来源 metadata 与取消无
owner event；测试会条件恢复其读到的剪贴板内容。它是受控 AppKit 验证，不等同于人工物理拖放。窗口集成
探针另覆盖 128B/4KiB/512KiB（文档总量边界）payload、队列满压力与 close 后保留收敛；文档消费者链在真实
bundle 窗口上串起外部授权调用与窗口编辑/复制粘贴；跨窗脚本以真实鼠标拖动验证同进程跨窗口 drop。
这些同样是自动化验证，不等同于人工物理输入。

### 交互状态与主题（experimental）

`CjguiComposableUiInteractionStyle` 是 `CjguiComposableUiStyle` 的可选 paint 覆盖：它只接受
`background`、`border`、`textColor` 与 `borderWidth`，所以 hover 等状态不能改变 padding、尺寸、字体或
布局。组件可通过各 helper 的 `interactionStyle:` 使用它；`CjguiComposableUiTheme.beaconDark()` 和
`paperLight()` 均提供 input/primaryAction 的完整状态样式，应用仍选择自己的主题和基础 Style。

```cangjie
let theme = CjguiComposableUiTheme.beaconDark()
root.add(cjguiComposableButton(42, "publish", "发布", "PUBLISH", resourceId,
    theme.primaryAction, interactionStyle: theme.primaryActionInteraction,
    ownerInteractionState: if (isSelected) { CjguiComposableUiInteractionState.SELECTED } else { 0 }))
```

解析顺序固定为 `base → normal → selected → checked → focused → hover → pressed → disabled`；后一个
状态仅覆盖它明确给出的 paint 字段。应用只能声明 `selected`/`checked`，并且应从已有领域快照投影；
`hover`、`pressed`、`focused` 与 `disabled` 分别由窗口的命中/press/focus/`enabled` 声明推导。native
只保存短暂路由身份和最终颜色，不保存业务颜色、选择或 checked 状态。

鼠标按下先显示 press，只有在同一仍有效目标上释放才进入已有 `applyUiEvent()` 动作；移出、窗口/焦点
取消、disabled、删除、换绑或 modal 覆盖后的释放都不改写替代对象。键盘焦点使用相同 focus paint，
而 AX 语义 Press 仍直接进入同一个动作，不伪造物理鼠标序列。滑块/分隔条继续走既有 pointer capture，
文本框继续复用系统输入代理和组合态。

纯 hover/press/focus 更新会从已接受的 Cangjie layout snapshot 生成 copy-on-write paint scene；不会调用
`buildUi()`、layout 或 TextKit 测量，也不会写领域/CAS 版本。由于 native scene 与 command-menu generation
原子提交，窗口会在同一 paint generation 暂存原有命令声明；这不是菜单或业务状态的第二个 owner。主题切换
属于应用声明改变，应用须推进 `uiSceneVersion()`，因此会进行一次正常整窗投影，随后 idle 不持续重绘。

针对性受控验证：

```text
zsh runtime/cjgui/native/scripts/verify_composable_ui_interaction_style_values.sh
zsh runtime/cjgui/native/scripts/verify_composable_ui_interaction_style_native.sh
zsh runtime/cjgui/native/scripts/verify_composable_ui_interaction_style_scale.sh
```

后一个入口通过实际 native overlay 的 press lifecycle 验证 enter/press 的像素、移出取消不动作、同点释放仅
一次动作，以及纯 paint 更新的 build/layout 计数不变。它是受控 AppKit/Metal 验证，不等同于物理鼠标、
VoiceOver、系统 IME、安装/公证或发布验收。

scale 入口保留 8、128、960 个控件各 30 次跨控件 hover 的原始单调时钟样本；每项要求一次提交、恰好两个
节点 paint 更新、零 build/layout/文本测量增量。它用于检测局部更新回退，不把 `pump_ns` 解释成 GPU 完成、
物理呈现或人工输入延迟。

### 效果组与 alpha 遮罩（experimental，macOS）

`CjguiComposableUiStyle(effectGroup: Some(CjguiComposableUiEffectGroup(...)))` 把节点背景、阴影、文字、
图片、控件及其子树先按原绘制顺序合成，再对整个结果施加可选 `CjguiComposableUiLinearAlphaMask` 和组
`opacity`，最后以 `normal` 或 `multiply` 合入此前已绘制的父背景。嵌套组逐层结算；组 opacity 与每个
节点自身的 paint opacity 分开。mask 使用组布局矩形内的归一化坐标、2–4 个位置和 alpha 均为 0..1
的 stop；域外全透明，重复位置在准确采样点取最后声明的 stop。mask 只改变画面，命中、enabled、焦点、
AX 和业务 owner 继续使用原几何与身份。

手写与命名样式共用此声明；生成目录的 `effectGroup` 属性使用
`opacityPercent,mode,maskOrNone(sx,sy,ex,ey,pos:alpha|...)`，例如
`70,multiply,0,0,0,100,0:0|100:100`；wire 数值为 0..100 的整数百分比，入场后转换为归一化值。
属性缺席继承命名样式，`none` 或空字符串明确清除。非法候选
会以稳定原因和属性 path 整份拒绝，旧 accepted 场景保留。生成外部客户端、手写应用和导出预览分别见
`examples/generated_panel_consumer/`、`examples/adaptive_layout_public_consumer/` 与
`scripts/export_framework_preview.sh`。

macOS 使用非 sRGB 格式 `BGRA8Unorm`，按现有 sRGB 数值分量合成，不宣称线性光运算。组离屏目标存
预乘 RGB；`normal` 以预乘 source-over 回写，`multiply` 取组之前的父目标内容，不采样未来兄弟。
每个目标边长最多 4096 像素、面积最多 4,194,304 像素；同时最多 16 组、嵌套深度最多 4，总存活
离屏目标预算 96 MiB，含 accepted、候选和 GPU 在途代次。超限拒绝候选并保留旧场景；静态内容和仅改
组 opacity 可复用内容目标。OHOS 后端尚无此能力的 accepted snapshot，目录按
`macos:supported,ohos:unpublished_snapshot` 发布，不把公共声明当成跨平台绘制证明。

组 opacity 动画通过 `window.animateEffectGroupOpacity(identityKey, target, spec:, atTime:)` 显式启动，
`animatedEffectGroupOpacity` / `animatedEffectGroupOpacityTarget` 可读当前值和目标，
`cancelEffectGroupOpacityAnimation` 可停止并恢复 accepted 声明。它只接受当前 accepted 场景中声明了
`effectGroup` 的节点，并支持 `acceptedToken` 拒绝旧代异步请求。现有 `animateNodeOpacity` 保持节点 paint
语义，单独缩放该节点的背景、边框、文字、阴影和渐变；增加或清除中性组声明不会改变该通道的目标。
两个通道共享窗口单调时钟和调度，但分别投影：节点 paint 通道只改本节点 paint alpha，组通道只改组的
绝对 opacity，由 renderer 一次作用于该组展平后的子树。

应用内部背景模糊在同一实验声明上设置
`backdropBlurRadiusPoints: 1..16`（默认 `0` 关闭）和固定的
`backdropBlurFallback: "unblurred"`。生成 token 保持原三段前缀，启用时追加
`;blur=8,unblurred`；旧 token 的含义不变。首片 macOS 后端每个场景只准一个未嵌在其他
效果组内的背景模糊组；普通效果组仍可嵌套。非法半径、未知 fallback、嵌套或第二个模糊组
拒绝候选，不把它们静默当作成功。OHOS snapshot 尚未发布该能力，目录单列
`backdrop_blur=macos:experimental_supported,ohos:unpublished_snapshot`。

模糊采样的是该组在根画面 painter 顺序之前的已接受内容：以组布局矩形和继承 clip 的交集为
输出区域，向外取 Gaussian halo 后重放此前节点到私有目标，先横向后纵向滤波，最后把模糊
背景放在透明组内容之后，对整体只施加一次组 opacity/mask，再按 normal/multiply 合入现场
画面。标准差为 `radiusPoints × backingScale / 2`，离散核截到 `ceil(3σ)` 并归一化；
屏幕边缘采样 clamp 到 drawable，输出继续服从组矩形和完整圆角 clip chain。缓存依赖采样区内
此前节点的实际绘制资源、文字装饰、clear 色、drawable/scale、MSAA 和核参数；组自身内容或
后序兄弟的普通 paint 不使它失效，后序兄弟若改变整帧 MSAA 则会失效。只有 GPU 成功完成的
模糊目标可供后续帧缓存命中。前景光标不进入背景键；背景区内此前节点的光标几何进入。

当前重放要求根 clear 为不透明；透明 clear 按同一回退策略处理。前景目标、背景结果、
整帧重放目标、滤波中间目标及在途旧代同计入上述 96 MiB 效果预算。
全帧重放的尺寸/像素上限及 48 设备像素的核半径上限为首片资源边界；分配或滤波编码失败
时，以新的命令缓冲正常绘制原组但省略背景模糊，按声明的 `unblurred` 回退。该能力是应用
内部内容采样，不采样系统候选窗或其他 AppKit/window-server 覆盖物，也不是系统窗口材质。

实际呈现状态由窗口 `windowProgress()` 和公开 `GET_WINDOW_PROGRESS` 的 `WINDOW_EFFECT_*`
字段读取；生成界面的 `EFFECTS` 快照/增量节从同一次窗口进度采样得到对应 `EFFECT_*` 字段。
`REQUESTED_RADIUS_POINTS` 属当前 accepted 声明；`SUBMITTED_SCENE_VERSION`、`SUBMITTED_FRAME_INDEX`
和 `SUBMITTED_MODE` 属已 commit 的帧，`COMPLETION` 再区分 `pending/succeeded/failed`。
`SUBMITTED_MODE` 为 `none/blurred/unblurred/unavailable`，回退原因是稳定码
`empty_roi/non_opaque_clear/kernel_limit/resource_budget/allocation_failed/pipeline_unavailable/encode_failed`；
正常关闭模糊为 `not_requested`。客户端应同时核对 session、accepted scene 与提交 scene/frame，
不能把 accepted `blur=8` 当成该帧实际完成了 blur。

### 表单与选择列表组合（experimental）

`cjguiComposableBoundFormField(...)` 接收已有 core 的
`CjguiSharedFormFieldDescriptor` 与 `CjguiSharedFormFieldProjection`，并生成标签、文本/整数/布尔编辑器及
可见校验提示。调用者仍提供自己的 container/editor/validation node ID、主题样式与 selected
`operationResourceId`；字段值、校验和版本继续属于领域 owner。helper 会验证 descriptor/projection 的
resource/field 对应关系，不能以不匹配的 projection 静默渲染。常见 required/range/format 错误会变成可读
文案（例如“请填写保留天数”），未知领域错误只显示通用提示而不泄漏内部错误码。

`cjguiComposableSelectableListRow(...)` 把 `CjguiComposableUiVirtualListItem` 的稳定资源、可访问标签、选中/
焦点样式和 action relation 组合为一个普通按钮节点。它不拥有列表选择；controller 仍通过 `applyUiEvent()` 调用
已有领域入口。两个 helper 写入同一节点的 `fieldId`、`operationActionName` 与 `operationResourceId`，所以人侧
编辑、AX 投影和 shared-operation 外部字段/动作关系不会各自维护一份映射。

文本事件默认严格按投影版本解析。只有紧接一代、同一仍聚焦的可编辑文本节点，且当前领域投影仍等于上一笔本地
已接受文本时，才会接住在 replacement projection 构造期间抵达的本地续写；删除、换资源/种类、禁用/只读或外部
改值仍调用 `rejectUiEvent()`。这处理连续键入的宿主时序，不是陈旧事件的通用豁免。

### 重复组件实例与命令生命周期（experimental）

`CjguiComposableUiComponentRegistry` 是每个 controller 持有的有界（64 个 live
实例）仓颉构建上下文。列表重排不能用数组下标当 key；实例提供 `nodeId(localKey)`、
`semanticId(localKey)` 和 `focusScopeId()`，所以一个字段组/编辑器函数不必再预留全局数字段。
同一候选轮重复 `use(key)` 返回 `duplicate_component_key`；临时隐藏请调用 `retain(key)`，恢复时
保留原实例身份。注册表没有进程级实例表；每个实例最多 64 个局部 key，超限显式失败。

动态组件 controller 应同时实现 `CjguiComposableUiSceneRefreshParticipant`：其
`beginSceneRefresh()`、`prepareSceneRefresh()`、`candidateSceneCommands()`、`commitSceneRefresh()` 和
`rollbackSceneRefresh()`直接委托给 registry。窗口在一次 refresh 中依次构造候选组件/scene/command，
校验并交给 native staging；只有 native present 被接受后才同步提交组件身份与命令。测量、布局、逐节点
setter、present 或命令校验失败都会丢弃候选，继续保留旧 scene、旧命令和旧 live 实例；相同重试不会反复
生成候选身份。旧 `begin()`/`finish()` 仍保留给低层兼容调用，但普通应用不应在 `buildUi()` 中提前销毁实例。

组件的公开窗口投影 `semanticId` 是 generation/slot 组成的 opaque 安全令牌（例如
`component-12-2`），不是业务 key 的可解析编码；业务 key 仅由 controller 内的 registry
持有。这样公共空白分隔协议保持严格，不会让任意 local key、分隔符或换行进入 transport。

`cjguiComposableVertical(..., inputScopeId: instance.focusScopeId())` 可把一个组件根设为普通
焦点范围，不会创建 native layer。上述 participant 路径会自动替换已接受 scene 的完整命令集合，应用
不应在每个 `pumpOneTurn()` 后无条件调用 `replaceCommands()`；低层 `replaceCommands(commands)` 仍只接收
当前已提交 scene 中有效 target 的完整新集合，失败保留原集合；`revokeCommand(id)` 用于独立撤销。相同 Command
快捷键可用于不同 scope，但同一 scope 的冲突会失败。键盘先取当前 focus scope 的声明；没有
scope 时才可取 global fallback，因此顶层 layer/另一个编辑器不能穿透到 base command。Cmd-A/C/X/V
和 marked text 仍由原生文本服务优先；无快捷键菜单动作应走自己的 Cangjie 菜单/动作调用，不要填造
一个快捷键。实例/命令 API 是仓颉公共实验接口；native 可短暂保存已接受的稳定 command id
以回投 FIFO，但不解释业务、不保存 callback 或 action name。

### 可组合矢量图形（experimental）

`src/composable_vector_graphics.cj` 提供不携带 Metal/AppKit 对象的纯值描述：
`CjguiComposableUiVectorPoint(x, y)`、`CjguiComposableUiVectorColor(red, green, blue, alpha)`、
`CjguiComposableUiVectorPaint(fill, stroke, strokeWidth, cap, join)` 和
`CjguiComposableUiVectorGeometry`。几何工厂为：

```cangjie
let geometry = CjguiComposableUiVectorGeometry.ellipse(
    160.0, 110.0, CjguiComposableUiVectorPoint(80.0, 55.0), 42.0, 30.0, paint)
if (let Some(value) <- geometry) {
    root.add(cjguiComposableVectorGraphic(22, "status-graphic", value,
        CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 220)))
}
```

`line`、`polyline`、`ellipse` 和 `simplePolygon` 均返回 `?CjguiComposableUiVectorGeometry`；
工厂返回 `None` 时，调用者必须保留旧场景或显示明确失败，不能截断点数组或用矩形替代。
点和椭圆边界使用 geometry 的 `viewBoxWidth/viewBoxHeight` 逻辑坐标，组件 layout bounds 负责缩放；
命中也在同一几何坐标中进行，而不是把整个节点外接矩形当作命中区域。`cjguiComposableVectorGraphic`
的 `interactive` 默认为 `false`，只有声明 action 后才进入既有 composable 事件/授权 owner。

本阶段限制为最多 12 个点：line/polyline 需要 2–12 个点，simple polygon 需要 3–12 个点；
凹的简单闭合多边形受支持，洞和自交被拒绝。所有点和椭圆边界必须落在正的有限 viewBox 内，
相邻重复点、零长度、零面积、非有限值、容量超限和不可见画笔都会显式失败。颜色 RGBA 必须在
`0..1`；fill/stroke 至少一个 alpha 大于零；透明 stroke 可使用宽度 0，非透明 stroke 必须宽度大于零。
端点 `BUTT/ROUND/SQUARE` 与连接 `MITER/BEVEL/ROUND` 仅描述描边，不改变填充几何。
这些 API 当前为 experimental，耳切、GPU 合批、布局缩放和几何命中由框架主链负责，不在消费者内创建
第二个 canvas/runtime。

两个 public-only 消费场景位于 [framework_preview_vector_consumer.cj](probe/framework_preview_vector_consumer.cj)：
纯 UI 图表组合 line、polyline 和带填充/描边的简单多边形；共同操作窗口把已有
`CjguiSharedOperationList` 的 `isMarked` 作为 durable owner，通过 `SET_MARKED` 外部授权写入投影颜色，
再由同一 controller 的人侧 action 切回并读回状态。消费者只读取 controller/window projection 的字段，
不读取 native/test seam。验证入口为 `native/scripts/verify_composable_vector_graphics_consumers.sh`。

### 应用命令、菜单与快捷键（experimental）

窗口消费者可以用公开的 `CjguiComposableUiCommand` 把一个稳定命令声明为现有按钮的语义入口：

```cangjie
let scope = CjguiComposableUiIdentityScope("editor")
let command = CjguiComposableUiCommand(
    "editor.publish",
    CjguiComposableUiNodeReference.scoped(scope, "publish"),
    "发布",
    CjguiComposableUiShortcut("p"),
    "Editor", 0, isEnabled, isChecked
)
```

命令由实现 `CjguiComposableUiSceneRefreshParticipant` 的 Cangjie owner 在每次候选 scene 中返回；`scope.local("publish")` 是稳定目标，不能用列表下标或 native 对象替代。`CjguiComposableUiShortcut` 的快捷键是可选的：带快捷键的声明进入平台菜单投影，不带快捷键的声明仍可被仓颉拥有的自绘菜单通过 `window.invokeCommand("editor.publish")` 调用。`focusScopeId` 可将同一个命令 vocabulary 限定到当前焦点范围；相同 scope 的重复命令或快捷键冲突会使候选失败。

`isEnabled` 和 `isChecked` 是当前已接受 Cangjie 声明的投影。disabled 命令、目标已移除、目标换绑、候选 scene 未被 native 接受，都会 fail closed：调用返回 `false`，保留上一份 accepted scene/命令集合，不静默重定向到另一个按钮。命令处理仍进入 owner 的 `applyUiEvent()`；按钮、平台菜单和自绘菜单因此共享同一动作与领域状态。结果可用 `window.windowProjection().fieldValues` 读回，但这只是 owner 状态的只读投影，不是第二个真相源。

native 只保存当前 accepted scene 的菜单标题、分组、可选快捷键和 enabled/checked 投影，并在输入到达时回到 Cangjie target；它不解释业务 `command id`，不保存 callback/action name，也不拥有资源、权限或版本。菜单和快捷键仅在 macOS bridge 的平台边界内成立；Cmd-A/C/X/V、marked text 和输入法继续由系统文本服务优先处理。其他平台或没有平台菜单的宿主应使用同一个 Cangjie command declaration 和自绘 surface，不能假定 AppKit 菜单存在。

macOS 的标准 **Quit** 仍由 Application 菜单的 `terminate:` 发起，但 bridge 只将其合并为一个退出意图；正常应用回合调用既有的 `CjguiMacosApplicationExitDecisionProvider`，再由已有 `requestApplicationExit()` 统一关闭窗口、外部连接和主循环。native 不保存或执行保存/退出业务决策，也不会在主线程同步等待 Cangjie。拒绝退出会保留应用可继续编辑；同一轮重复 Quit 只产生一个待处理意图。

当当前 Cangjie owner 声明 `command+z` 或 `shift+command+z`，其命令优先于标准 Edit responder：平台仍保留 Undo/Redo 条目，但会移除该条目的 key equivalent，使实际键盘事件只进入当前 owner。顶层 layer 或 disabled owner 的同一声明同样保留该快捷键，避免静默回退为文本 undo/redo；只有没有任何已声明 owner 的快捷键才由标准文本 responder 处理。该规则不创建第二套 undo 栈，也不改变 Cmd-A/C/X/V、剪贴板或系统组合输入。

平台菜单更新比较的是有效投影，而不是任意 scene 版本：当前 accepted 命令集合、enabled/checked、有效 `focusScopeId` 和当前 key-window 身份都没有变化时，普通 scene 内容（例如说明文字或布局版本）的刷新不会重新创建 `NSApp.mainMenu`。切换 key window、焦点范围或命令菜单投影本身变化时才更新平台菜单；这不改变 Cangjie owner 对按钮、菜单和 `window.invokeCommand(...)` 的单一动作归属。

以上 API 目前仍为 experimental。导出预览的公共消费验收为：

```text
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
CJGUI_PREVIEW_CONSUMPTION_KEEP_TMPDIR=1 \
  zsh runtime/cjgui/native/scripts/verify_framework_preview_consumption.sh
```

该检查会把 [framework_preview_command_menu_consumer.cj](probe/framework_preview_command_menu_consumer.cj) 复制到含空格的导出目录，构建并运行两个不同 owner 的命令窗口，验证稳定 target、按钮/菜单同一 action、projection readback 与 disabled 拒绝。成功行包含 `command_menu=build_and_run`、`command_owners=2`、`command_projection_readback=true`，并给出 `command_manifest`、`command-menu-preview-run.log`、source/bundle SHA-256 和 `evidence_tmp_root`；设置 `CJGUI_PREVIEW_CONSUMPTION_KEEP_TMPDIR=1` 才保留这些临时证据。

同一检查还会把 [framework_preview_vector_consumer.cj](probe/framework_preview_vector_consumer.cj) 复制到导出框架，迁移到含空格路径后构建并运行图表消费者和共同操作消费者。成功行包含 `vector=build_and_run`、`vector_chart_consumer=true`、`vector_external_color_write=true`、`vector_window_projection_readback=true` 和 `vector_human_action_after_external=not_run`，并给出 `vector_manifest`、source/bundle SHA-256 与 `evidence_tmp_root`；它故意不在生产消费者内注入输入。若要验证桌面输入接续，应运行 `--run-vector` 并把真实窗口操作、公开连接读写和窗口投影逐项记录为独立证据。这项检查证明的是导出源码、正常宿主、授权外部修改和窗口字段读回，不等同于桌面输入、完整 GPU completed、安装、公证或发布。

多行文字仍由 AppKit TextKit 负责组合、选择与字形排版，仓颉 document owner 只接收已提交
投影。它的公共 UTF-8 边界当前是保守 profile：拒绝 UTF-8 标量内部、CRLF、常见组合标记/变体
选择器/肤色/ZWJ 相邻位置，并按连续区域指示符成对处理；这不是“已实现全部 Unicode extended
grapheme segmentation”的承诺。原生 TextKit 的位置与公共 UTF-8 转换分别验证；消费者不得把被
拒绝的公开范围静默取整到另一段文字。

可参考两个布局不同、但共享同一渲染/输入主线的正常入口：

- `examples/adaptive_layout_public_consumer/`：并列的两个可组合组件以稳定业务 key
  声明普通 scope，并可在运行时隐藏、恢复和替换同 chord 的 scoped command；
  `zsh run.sh --build-only` 只重建/签名，`zsh run.sh` 启动窗口。它的可授权
  `SET_MARKED` 外部写入会由同一 controller 的下一轮投影读回，不把外部连接另作内容 owner。
- `examples/rule_set_window_app/`：命令行、可滚动规则列表、详情草稿和文件动作；
  `zsh run.sh --build-only` 只重建/签名，`zsh run.sh` 启动窗口。
- `examples/notification_threshold_window_app/`：卡片式通知通道/阈值/开关配置；
  当前草稿、草稿版本与已应用基线都由 `notification_threshold_application/` 所有，
  外部可读取/编辑草稿，旧基线应用会返回 `stale_draft`，而
  `notification_threshold_consumer/` 仍可在不启动 renderer 的情况下使用同一领域。

所有上述 API 仍为 experimental：不是稳定控件库，也不承诺完整 IME、富文本或
多平台行为。一次 `layout` 只在本次递归求解内复用相同的文本、完整 style 和约束宽度
请求，容量上限 1,024，调用结束即丢弃；它不保存第二份组件树，也没有开发者维护的脏标记。
`layoutWithMetrics(..., reuseMeasurements: false)` 是用于测试差分的实验性无复用参考入口，
返回同一 canonical scene 与本次只读测量/递归工作计数，不能作为第二个运行时状态 owner。
生产窗口通过 `CjguiInternalRendererTextMeasurer` 调用与绘制相同的 AppKit 字体服务，按字号、
字重、字体族和约束宽度得到字形 bounds、行高和基线；其跨刷新 scalar 缓存键包含这些实际影响项，
容量限制为 128。生产测量失败会令本轮投影失败、保留旧场景并给出
非 OK 状态，不能静默当作真实测量成功。

预览版 `CjguiComposableUiMultilineNaturalHeightMeasurer` 是多行输入框的可选高度查询：布局在解析出
最终内容宽度后，用与绘制/输入一致的 TextKit word-wrap 和零行片段 padding 求全文自然高度；
未实现该接口的自定义 measurer 仍走原 `measure(...).height`。两种查询按角色分别缓存，原四指标
`measure` 的 char-wrap 语义不变。该高度查询需要完成全文布局，不承诺任意规模文本的恒定耗时。

单行静态文字、按钮及文本/整数/布尔字段的可见文本由
TextKit/AppKit 完成 shaping 后，在场景提交前栅格成节点持有的 Metal 纹理；形状、图片和这些
文字纹理严格按同一已接受 scene 的 painter order 合成。活动单行字段把唯一 `inputProxy` 的文本、
选区、光标和 marked range 作为派生纹理状态；TextKit 仍是 IME、候选和选择的唯一 owner。多行字段
同样复用该唯一 TextKit layout graph 的可见 glyph、选择、光标和候选几何，但将其离屏结果作为有序
scene 纹理提交，不再有置顶的正文覆盖层；因此这不是自研文字引擎或第二份可写正文。文字纹理没有
跨场景的全局缓存：它随已接受/COW 场景的节点（最多 1,024 个）存活，key 包含实际文本、字体、原始
几何、resolved 可见 tile、tile 相对 node 的偏移、scale、选区和组合状态。tile 保留原布局宽度而只栅格
node∩clip；单节点最多 8 MiB、已接受 scene 合计最多 24 MiB，资源失败保留旧场景/旧派生纹理并按声明的
重试边界处理；
完全裁掉、替换或关闭时释放。首次帧的 GPU readback 是诊断，不会因每次正常编辑而同步执行，也没有
另建领域状态或透明原生控件覆盖页面。

`CjguiComposableUiStyle` 提供字号、字重、`system`/`monospaced` 字体族、最小/期望/最大
尺寸与横纵对齐，以及独立的 `cornerRadius` 与 `clipsContent`；前者只修饰本节点的边框/背景，后者才将
圆角传为子内容、Metal、TextKit、命中和滚动共用的 resolved clip。row/column 先保留 fixed/min 约束，增长子项触及 max 后把剩余空间继续交给
仍可增长的同级项，整数余量按声明顺序稳定分配。横向子项的自然高度使用它已分配的宽度测量，
而不是把行高当作文字宽度。空间仍不足时只按既有父 clip 裁剪，不悄悄破坏 fixed/min。
未知字体族归一为 `system`。`CjguiComposableUiTheme.beaconDark()` 和
`paperLight()` 提供两个可复用主题，局部样式仍可覆盖。`cjguiComposableImage` 用逻辑资源
ID、版本、路径和缩放模式声明 PNG；native session 私有地以三者为键用 `MTKTextureLoader`
解码 Metal 纹理，只保留活跃资源，并将可复用缓存限制为 8 项、32 MiB。资源缺失或无效会拒绝该次场景投影；
同 ID 的版本/路径更新、移除和关闭都会走受控失效与回收。样例 `run.sh --build-only` 会把
蓝色 `composable-beacon.png` 与珊瑚 `composable-beacon-coral.png` 放入 bundle 的
`Contents/Resources`；正常 bundle 消费者应传入文件名等 bundle-relative 路径，不应把
源码树前缀传给运行时资源解析。

节点可显式声明 `displayValueRole`（例如 `draft`、`applied`）；外部投影同时输出直接可解析的
`WINDOW_FIELD_VALUE node resource field role value_source typed_value`，不要求消费者拆解关系
目标 ID。普通循环应在真实外部 `INVOKE` 后调用 `requestRefresh()`，随后调用
`refreshIfNeeded()`；后者只比较 Cangjie UI revision 与 native resize revision，空闲和
`GET_CONTEXT`/`GET_CHANGES` 不会执行 `buildUi`、布局或 native 重交。兼容的 `refresh()`
仍是一次显式保守重建。相同候选场景不配置或提交 native 场景，测量命中缓存时也不重复跨 FFI；
仅层级/绑定变化会刷新仓颉语义投影而不强制 GPU 提交。多行 TextKit 缓存按稳定节点/资源身份、
实际文本、字体/颜色和宽度失效，不会因整幅 projectionVersion 变化而作废。通用的透明图片首帧诊断若
无法安全比对源像素会标记 `image_pixel_unverified`，不冒充绘制失败或像素相等；原生场景探针
已以测试侧生成、非方形的已知 RGBA fixture 对生产 drawable 逐像素验证 FIT/FILL、裁剪、
完全透明和半透明合成，并有省略图片节点的负对照。节点还能声明 `enabled`，文本/整数字段
可声明 `readOnly`：禁用节点不再获得焦点或事件；只读文本仍允许聚焦、选择和复制，但不能进入
编辑领域事件。物理中文 IME 的候选、提交、删除和粘贴尚未实测，不能由程序化 Unicode
输入替代。`WINDOW_*` 诊断把 session、当前/accepted/submitted scene、Metal readback
completion、多行 TextKit tile prepare、pending/failure 和 build/layout/submission 计数分开；
`WINDOW_WORK_TIMING_MS` 是最近一次真实 projection 的 build、layout、实际 native
text measurement、native staging/present 四项单调时钟诊断，`WINDOW_MEASUREMENT_CALL_COUNT`
是该轮越过 production measurer cache 的调用数。`0` 表示小于当前毫秒分辨率或该阶段未发生，
不能解释为端到端延迟为零；它们不是业务延迟、GPU 完成或人眼可见证明。Metal completion 与 overlay
绘制都不等于用户肉眼看见，故 `presentationState` 仍为
`unavailable`。临时测量或 drawable/encoder 不可用会保留上一有效场景和输入映射，标记
`refresh_*` pending，等待一次显式 `retryPendingRefresh()`、真实外部变更、resize 或人机事件；
不会在空闲循环无限重试。

## 开发者诊断（experimental，macOS）

普通窗口可调用 `window.diagnosticSnapshot(maximumNodes: 128)` 读取有界只读值，
用 `window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
selectedIdentityKey: "semantic:..."))` 显示布局、祖先裁剪、效果输出与实际背景采样框；
传入 `CjguiComposableUiDiagnosticOverlayOptions(false)` 关闭。叠加层默认隐藏，
位于原生业务画面和文字之上，不建立业务节点或 AX 元素，不参与命中、焦点与背景采样。

快照分页上限为每次 256 个可见节点，携带窗口 session 与 accepted scene version；
后续页传入 `expectedSessionIdentity`、`expectedAcceptedSceneVersion`，过期返回
`stale_accepted` 和空节点。节点只含身份、几何、有效祖先裁剪及同版本原生几何，
不复制正文值。`acceptedSceneVersion` 与 `submittedFrameIndex`、`completedFrameIndex`
分别表示声明接受、提交与异步 GPU 完成，不能混读；最近一次 build/layout/submit
时长属于刷新尝试，可能来自被拒候选。后端尚未发布的 raster/upload、效果 pass、
缓存命中及在途字节返回 `-1`，不解释为零。当前叠加层仍随整幅场景重绘，
开启或关闭诊断自身不要求 GPU 提交。

## 已有检查入口

以下命令是当前工作树的针对性复核入口；通过它们不等同于 API 稳定、打包发布或第三方模型兼容。
工具链及 SDK 以实际机器为准，遇到问题再查 [构建资料](../../docs/setup/BUILD_FROM_ZERO.md)。

在仓库根目录：

    unset SDKROOT CJ_GUI_SDKROOT
    source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
    zsh runtime/cjgui/native/scripts/verify_internal_renderer_clear_window.sh
    zsh labs/macos_bridge_smoke/scripts/verify_auto_close.sh

在 runtime/cjgui 目录：

    cjpm test --parallel 1 --no-progress
    cjpm build --skip-script
    cd shared_operation_core && cjpm test --no-color
    cd ../examples/shared_operation_second_consumer && zsh test.sh
    cd ../backup_rule_config_consumer && zsh test.sh
    cd ../rule_set_application && cjpm test --no-color
    cd ../rule_set_second_consumer && zsh test.sh
    cd ../rule_set_window_app && zsh run.sh --build-only
    cd ../notification_threshold_window_app && zsh run.sh --build-only
    cd ../.. && zsh native/scripts/verify_composable_ui_layout.sh
    zsh native/scripts/verify_composable_scene_renderer.sh
    zsh native/scripts/verify_composable_ui_window_controller.sh
    zsh native/scripts/verify_composable_ui_appkit_text.sh

根包的普通 `cjpm test` 会先运行 `build.cj`，生成并链接内部 AppKit/Metal/MetalKit
sidecar；`cjpm build --skip-script` 只在该 archive 已存在时用于复核源码构建。此机器的
1.1.3 默认路径使用 `xcrun` 选择的 SDK；如需针对旧 1.1.0 或兼容性回退，可显式设置
`CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。R1 verifier 将 wrapper
与 probe 放在同一临时 package 编译；它成功不代表 API 稳定、发布完成或第三方环境兼容。
窗口样例迁移后的构建与已完成的 GUI 验收见
[shared_operation_window_app](examples/shared_operation_window_app/README.md)；纯 core 列表与备份规则消费者的
独立 AF_UNIX 验收见 [shared_operation_second_consumer](examples/shared_operation_second_consumer/README.md) 和
[backup_rule_config_consumer](examples/backup_rule_config_consumer/README.md)。

共同操作为 experimental：应用开发者定义资源类型、上下文、资源字段、动作描述、typed 参数、目标集合与业务结果；领域自身拥有版本和修改真相。共享 transport 只处理私有 descriptor、分片 frame、作用域和声明校验，随后调用领域的外部入口；人类入口调用同一个领域处理器。外部 `GET_CONTEXT`、`GET_CHANGES` 与动态 `INVOKE` 使用稳定 ID 和刚读到的版本；增量游标过期时必须全量重同步。不要把固定 socket、分隔符协议、单次读取或 UI 投影当作业务真相。

## 相关入口

[项目方向](../../docs/core/GUI_PROJECT_DIRECTION.md) · [架构契约](../../docs/core/AI_NATIVE_UI_SEMANTICS.md) · [当前任务与交付状态](ACTIVE_DIRECTION.md) · [验收标准](../../docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)

[有序 GPU 合成阶段](../../docs/plans/2026-09-13-ordered-gpu-composition-milestone.md)为历史交付参考，不是当前任务。

旧长篇阶段记录见 [历史快照](../../docs/archive/2026-09-11-direction-governance/README.md)。
