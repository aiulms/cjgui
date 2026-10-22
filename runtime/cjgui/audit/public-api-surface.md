# CJGUI 公共组件工厂 API 面

> 数据快照：HEAD `dc27dff`；未提交改动 **239** 条；快照时间 `2026-10-21T04:42:43Z`。
> **本审计基于未提交改动的工作区，提交后数字会变。**

## 0. 结论

- 工厂：**66 条 public func 声明**，归并为 **61 个唯一函数名**；其中 5 组重载（`Text`、`Button`、`TextInput`、`ScrollArea`、`CommandToolbar`）各占 2 行。
- 文档：**45 条有 `///` 文档 / 21 条无**（按声明计；同一重载组可能只有一个重载有文档）。
- 测试：**35 条在 `src/*_test.cj` 有直接引用 / 31 条无**。
- 示例消费者：**55 条在 `examples/` 有直接调用 / 11 条无**。
- 按唯一函数名去重（61 个）计：**44 个**至少一个有 `///` 文档、**30 个**有测试、**50 个**有示例消费。
- **无测试且无消费者：4 条**。其中 2 条是直接 API 空档（`cjguiComposableSplitView`、`cjguiComposableSelectableListRow`），另 2 条是接口回调（`CjguiGeneratedUiCollection.buildComposite`、`CjguiComposableUiInspectorPanel.buildUi`），属于“直接检索为空、经接口间接消费”，见第 5 节。

## 1. 划界方法

**范围**：只读 `runtime/cjgui/src/*.cj`（不含子目录、`platforms/ohos/snapshot/` 副本、`examples/`、`probe/`、`templates/`）；纯静态检索，未构建、未运行。

**计数基线**：`rg 'public func ' src/*.cj` 共 **2120** 处（含类方法）；行首 `^public func` 的顶层函数 **120** 个；行首 `^public func cjguiComposable` **61** 条声明。

**纳入**（满足全部三条）：

1. 是 `public func`（顶层或 public 组件类上的 public 方法；不含 `public init` 构造器）；
2. 主要职责是**构造/挂载一个组件节点**，或构造一个供组件装配使用的组件模型/规格；
3. 返回 `CjguiComposableUiNode`，或 `CjguiGeneratedUiComponentSpec`、`CjguiCommandToolbarPlacement`、`CjguiContextCommandMenuProjection` 这类组件模型。

**具体构成**：

- 顶层 `cjguiComposable*` 节点工厂 **43** 条：61 条顶层 `cjguiComposable*` 声明中，扣除 18 条非构造助手；
- public 组件类上的节点构造/挂载方法 **20** 条：`build`/`buildMessage`/`buildRow`/`buildHeader`/`buildUi`/`buildNode`/`buildComposite`/`buildRefreshNode`/`buildAccepted`/`attachTo`；
- 顶层组件模型/规格工厂 **3** 条：`cjguiGeneratedSliderComponent`、`cjguiCommandToolbarPlacement`、`cjguiContextCommandMenuProjection`。

**排除**（宁缺勿滥）：

- 18 条顶层 `cjguiComposable*` 非构造助手：样式 5（`UiPaintOverlay`、`UiStyleWithPaint`、`UiStyleWithTranslation`、`FormValidationStyle`、`SliderInteractionStyle`）、token 编解码 10（`UiColorToken`、`Parse*Token`、`*Token`）、几何/命中 2（`ContextMenuBounds`、`HitMayTakeOver`）、帮助文案 1（`FormFieldHelp`）；
- 216 个 `public init` 构造器（单位是 `public func`；控制器/面板主要经构造器创建，见第 3 节边界）；
- 非 public 类/私有类上的同名方法（如 `CjguiCompositeMissingFactory`、`CjguiInspectorRows`、`CjguiGeneratedCollectionRows`），以及测试类里的 `buildUi`/`buildRow`；
- 样式/主题工厂（`CjguiComposableUiTheme.beaconDark`、`CjguiCommandToolbarStyle.themed`、`*Appearance.fromTheme` 等）、事件分发、状态读写、诊断/编码/几何函数。

**与“约 89”的差异**：89 是“名字含组件词”的数量级粗扫，会把 18 条样式/token/几何助手、内部/私有类方法和部分控制器状态方法一起算入（同一粗扫在本树可得 93 行，其中包含 `setScrollPhysicsPolicy` 等非工厂）。本表按“组件/控件工厂或组件控制器”语义收敛，得到 **66 条声明 / 61 个名字**。

## 2. 分组清单

说明：MD 表里参数超过 6 项时只列前 5 项并标总数，**完整参数、全部测试文件和全部消费者目录以 `evidence/public-api-surface.tsv` 为准**；“测试”列只给文件数，示例消费者只列前 3 个目录。

### 2.1 布局（9）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableGrid` | nodeId: Int64, semanticId: String, spec: CjguiGridSpec, style: CjguiComposableUiStyle, cellStyle: CjguiComposableUiStyle …（共 10 项） | `CjguiComposableUiNode` | 有 | 有 (2) | 无 |
| `cjguiComposableVertical` | nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle, inputScopeId: String, layoutReuseKey: String, identity: ?CjguiComposableUiIdentity | `CjguiComposableUiNode` | 无 | 有 (49) | 有 (14): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableHorizontal` | nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle, inputScopeId: String, layoutReuseKey: String, identity: ?CjguiComposableUiIdentity | `CjguiComposableUiNode` | 无 | 有 (5) | 有 (14): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableStack` | nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle, inputScopeId: String, layoutReuseKey: String, identity: ?CjguiComposableUiIdentity | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `cjguiComposableWrap` | nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle, rowGap: Int64 = 0, inputScopeId: String …（共 7 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `cjguiComposableAspectRatio` | nodeId: Int64, semanticId: String, aspectWidth: Int64, aspectHeight: Int64, style: CjguiComposableUiStyle …（共 8 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `cjguiComposableSpacer` | nodeId: Int64, semanticId: String, axis: Int64 = CjguiComposableUiSplitAxis.HORIZONTAL, grow: Int64 = 1, minimumSize: Int64 = 0 | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `cjguiComposableSplitView` | nodeId: Int64, semanticId: String, first: CjguiComposableUiNode, second: CjguiComposableUiNode, axis: Int64 …（共 13 项） | `CjguiComposableUiNode` | 有 | 无 | 无 |
| `cjguiComposableScopedSplitView` | scope: CjguiComposableUiIdentityScope, semanticId: String, first: CjguiComposableUiNode, second: CjguiComposableUiNode, axis: Int64 …（共 14 项） | `CjguiComposableUiNode` | 有 | 有 (3) | 有 (2): adaptive_layout_public_consumer, rule_set_window_app |

### 2.2 输入（12）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableTextInput` | nodeId: Int64, semanticId: String, label: String, value: String, resourceId: Int64 …（共 14 项） | `CjguiComposableUiNode` | 无 | 有 (7) | 有 (9): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableTextInput` | nodeId: Int64, semanticId: String, label: String, value: String, resourceId: Int64 …（共 13 项） | `CjguiComposableUiNode` | 有 | 有 (7) | 有 (9): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableIntegerInput` | nodeId: Int64, semanticId: String, label: String, value: String, resourceId: Int64 …（共 14 项） | `CjguiComposableUiNode` | 无 | 有 (1) | 有 (1): rule_set_window_app |
| `cjguiComposableMultilineTextInput` | nodeId: Int64, semanticId: String, label: String, value: String, resourceId: Int64 …（共 15 项） | `CjguiComposableUiNode` | 有 | 有 (6) | 有 (4): generated_collection, generated_panel_consumer, range_text_window_app 等 |
| `cjguiComposableBooleanInput` | nodeId: Int64, semanticId: String, label: String, value: Bool, resourceId: Int64 …（共 13 项） | `CjguiComposableUiNode` | 无 | 无 | 有 (6): adaptive_layout_public_consumer, generated_panel_consumer, linux_mixed_form_app 等 |
| `cjguiComposableSlider` | nodeId: Int64, semanticId: String, value: Int64, minimum: Int64, maximum: Int64 …（共 15 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (2): generated_collection, shared_document_window_app |
| `cjguiComposableBoundFormField` | containerNodeId: Int64, containerSemanticId: String, editorNodeId: Int64, validationNodeId: Int64, descriptor: CjguiSharedFormFieldDescriptor …（共 20 项） | `CjguiComposableUiNode` | 无 | 有 (1) | 有 (2): generated_collection, rule_set_window_app |
| `cjguiComposableFormFeedbackSummary` | nodeId: Int64, semanticId: String, feedback: CjguiFormFeedbackProjection, actionName: String, style: CjguiFormFeedbackSummaryStyle, copy: CjguiFormFeedbackCopy | `CjguiComposableUiNode` | 有 | 无 | 有 (2): generated_collection, settings_form_window_app |
| `cjguiComposableBoundFormGroups` | nodeId: Int64, semanticId: String, placement: CjguiComposableFormPlacement, feedback: CjguiFormFeedbackProjection, editorStyle: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 32, fontSize: 15.0, growX: 1) …（共 14 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): settings_form_window_app |
| `cjguiComposableFieldSlider` | nodeId: Int64, semanticId: String, field: CjguiGeneratedUiFieldSpec, provider: CjguiGeneratedUiBindingProvider, style: CjguiComposableUiStyle …（共 8 项） | `CjguiComposableUiNode` | 无 | 无 | 有 (1): generated_collection |
| `CjguiNumericStepper.build` | binding: CjguiNumericStepperBinding, presets: ArrayList<CjguiNumericStepperPreset>, style: CjguiNumericStepperStyle | `CjguiComposableUiNode` | 有 | 无 | 有 (2): notification_threshold_window_app, rule_set_window_app |
| `CjguiChoiceGroup.build` | nodeId: Int64, semanticId: String, optionsNodeId: Int64, options: ArrayList<CjguiChoiceOption>, currentValue: String …（共 8 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |

### 2.3 文本（2）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableText` | nodeId: Int64, semanticId: String, value: String, style: CjguiComposableUiStyle, resourceId: Int64 …（共 14 项） | `CjguiComposableUiNode` | 无 | 有 (39) | 有 (15): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableText` | nodeId: Int64, semanticId: String, value: String, boundStyle: CjguiComposableUiBoundStyle, resourceId: Int64 …（共 12 项） | `CjguiComposableUiNode` | 有 | 有 (39) | 有 (15): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |

### 2.4 集合/列表（13）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableTabs` | scope: CjguiComposableUiIdentityScope, semanticId: String, pages: ArrayList<CjguiComposableUiTabPage>, state: CjguiComposableUiTabsState, style: CjguiComposableUiStyle …（共 9 项） | `CjguiComposableUiNode` | 有 | 有 (3) | 有 (3): adaptive_layout_public_consumer, rule_set_window_app, tree_outline_consumer |
| `cjguiComposableSelectableListRow` | nodeId: Int64, semanticId: String, item: CjguiComposableUiVirtualListItem, actionName: String, normalStyle: CjguiComposableUiStyle …（共 10 项） | `CjguiComposableUiNode` | 有 | 无 | 无 |
| `cjguiComposableScrollArea` | nodeId: Int64, semanticId: String, scrollOffset: Int64, style: CjguiComposableUiStyle, enabled: Bool = true | `CjguiComposableUiNode` | 无 | 有 (17) | 有 (10): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableScrollArea` | nodeId: Int64, semanticId: String, viewport: CjguiComposableUiScrollViewport, style: CjguiComposableUiStyle, enabled: Bool = true | `CjguiComposableUiNode` | 有 | 有 (17) | 有 (10): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableVirtualList` | nodeId: Int64, semanticId: String, contentNodeId: Int64, source: CjguiComposableUiVirtualListSource, state: CjguiComposableUiVirtualListState …（共 10 项） | `CjguiComposableUiNode` | 有 | 有 (1) | 有 (1): rule_set_window_app |
| `cjguiComposableVariableHeightList` | nodeId: Int64, semanticId: String, contentNodeId: Int64, source: CjguiComposableUiVariableHeightListSource, state: CjguiComposableUiVirtualListState …（共 10 项） | `CjguiComposableUiNode` | 有 | 有 (1) | 有 (2): rule_set_window_app, shared_document_window_app |
| `cjguiComposableTree` | nodeId: Int64, semanticId: String, contentNodeId: Int64, source: CjguiComposableUiTreeListSource, state: CjguiComposableUiVirtualListState …（共 10 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (2): adaptive_layout_public_consumer, tree_outline_consumer |
| `CjguiComposableUiCardGridSource.buildRow` | item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool | `CjguiComposableUiNode` | 无 | 无 | 有 (1): rule_set_window_app |
| `CjguiComposableUiFilteredListSource.buildRow` | item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool | `CjguiComposableUiNode` | 无 | 有 (1) | 有 (2): rule_set_window_app, table_layout_consumer |
| `CjguiComposableUiTableSource.buildRow` | item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool | `CjguiComposableUiNode` | 无 | 有 (1) | 有 (2): rule_set_window_app, table_layout_consumer |
| `CjguiComposableUiTableSource.buildHeader` | — | `CjguiComposableUiNode` | 有 | 有 (1) | 有 (2): rule_set_window_app, table_layout_consumer |
| `CjguiComposableUiTreeListSource.buildRow` | item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool | `CjguiComposableUiNode` | 无 | 有 (1) | 无 |
| `CjguiSearchableSelectionPanel.buildRow` | item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool | `CjguiComposableUiNode` | 无 | 有 (1) | 无 |

### 2.5 命令面（10）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableButton` | nodeId: Int64, semanticId: String, label: String, actionName: String, resourceId: Int64 …（共 11 项） | `CjguiComposableUiNode` | 有 | 有 (17) | 有 (14): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableButton` | nodeId: Int64, semanticId: String, label: String, actionName: String, resourceId: Int64 …（共 14 项） | `CjguiComposableUiNode` | 无 | 有 (17) | 有 (14): adaptive_layout_public_consumer, generated_collection, generated_panel_consumer 等 |
| `cjguiComposableCommandToolbar` | nodeId: Int64, semanticId: String, placement: CjguiCommandToolbarPlacement, style: CjguiCommandToolbarStyle, searchLabel: String = "搜索命令" …（共 7 项） | `CjguiComposableUiNode` | 有 | 有 (3) | 有 (3): linux_mixed_form_app, notification_threshold_window_app, settings_form_window_app |
| `cjguiComposableCommandToolbar` | scope: CjguiComposableUiIdentityScope, semanticId: String, placement: CjguiCommandToolbarPlacement, style: CjguiCommandToolbarStyle, searchLabel: String = "搜索命令" …（共 7 项） | `CjguiComposableUiNode` | 有 | 有 (3) | 有 (3): linux_mixed_form_app, notification_threshold_window_app, settings_form_window_app |
| `cjguiComposableContextMenuLayer` | nodeId: Int64, semanticId: String, layerId: String, ownerSemanticId: String, ownerNodeId: Int64 …（共 10 项） | `CjguiComposableUiNode` | 有 | 有 (1) | 有 (1): range_text_window_app |
| `cjguiComposableContextCommandMenuLayer` | scope: CjguiComposableUiIdentityScope, semanticId: String, request: CjguiComposableUiContextMenuRequest, projection: CjguiContextCommandMenuProjection, ownerSemanticId: String …（共 7 项） | `CjguiComposableUiNode` | 有 | 有 (1) | 无 |
| `CjguiCommandPalette.attachTo` | base: CjguiComposableUiNode, currentTheme: CjguiComposableUiTheme | `CjguiComposableUiNode` | 无 | 无 | 有 (2): linux_mixed_form_app, settings_form_window_app |
| `CjguiContextCommandMenu.attachTo` | host: CjguiComposableUiNode | `CjguiComposableUiNode` | 有 | 无 | 有 (3): linux_mixed_form_app, notification_threshold_window_app, settings_form_window_app |
| `cjguiCommandToolbarPlacement` | commands: ArrayList<CjguiComposableUiCommand>, metadata: ArrayList<CjguiCommandToolbarMetadata>, searchCommandId: String | `CjguiCommandToolbarPlacement` | 有 | 有 (3) | 有 (1): settings_form_window_app |
| `cjguiContextCommandMenuProjection` | request: CjguiComposableUiContextMenuRequest, commands: ArrayList<CjguiComposableUiCommand>, metadata: ArrayList<CjguiCommandToolbarMetadata>, searchCommandId: String | `CjguiContextCommandMenuProjection` | 有 | 有 (1) | 无 |

### 2.6 面板/层（7）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableLayerHost` | nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle | `CjguiComposableUiNode` | 有 | 有 (2) | 有 (10): adaptive_layout_public_consumer, generated_collection, linux_composite_form_app 等 |
| `cjguiComposableAnchoredLayer` | nodeId: Int64, semanticId: String, layerId: String, layerKind: String, ownerSemanticId: String …（共 7 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (3): adaptive_layout_public_consumer, rule_set_window_app, shared_document_window_app |
| `cjguiComposableAnchoredLayerWithReference` | nodeId: Int64, semanticId: String, layerId: String, layerKind: String, ownerSemanticId: String …（共 7 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (2): rule_set_window_app, shared_document_window_app |
| `cjguiComposableDialogLayer` | nodeId: Int64, semanticId: String, layerId: String, ownerSemanticId: String, ownerNodeId: Int64 …（共 7 项） | `CjguiComposableUiNode` | 有 | 有 (1) | 无 |
| `cjguiComposableDialogLayerWithReference` | nodeId: Int64, semanticId: String, layerId: String, ownerSemanticId: String, owner: CjguiComposableUiNodeReference …（共 7 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (3): generated_collection, rule_set_window_app, shared_document_window_app |
| `CjguiSearchableSelectionPanel.attachTo` | base: CjguiComposableUiNode, currentTheme: CjguiComposableUiTheme | `CjguiComposableUiNode` | 有 | 无 | 有 (2): notification_threshold_window_app, rule_set_window_app |
| `CjguiComposableUiInspectorPanel.buildUi` | — | `CjguiComposableUiNode` | 无 | 无 | 无 |

### 2.7 其他（13）

| 工厂 | 参数（精简） | 返回 | `///` 文档 | 测试 | 示例消费者 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableScopedActionRow` | scope: CjguiComposableUiIdentityScope, semanticId: String, items: ArrayList<CjguiComposableUiActionItem>, style: CjguiComposableUiStyle | `CjguiComposableUiNode` | 有 | 无 | 有 (2): rule_set_window_app, shared_document_window_app |
| `cjguiComposableImage` | nodeId: Int64, semanticId: String, localRasterPath: String, style: CjguiComposableUiStyle, contentMode: Int64 = 1 …（共 9 项） | `CjguiComposableUiNode` | 无 | 无 | 有 (9): adaptive_layout_public_consumer, generated_panel_consumer, linux_composite_form_app 等 |
| `cjguiComposableImageFromTransfer` | nodeId: Int64, semanticId: String, offer: CjguiSharedOperationTransferOffer, style: CjguiComposableUiStyle, contentMode: Int64 = 1 | `CjguiComposableUiNode` | 无 | 有 (1) | 有 (2): adaptive_layout_public_consumer, generated_panel_consumer |
| `cjguiComposableVectorGraphic` | nodeId: Int64, semanticId: String, geometry: CjguiComposableUiVectorGeometry, style: CjguiComposableUiStyle, interactive: Bool = false …（共 12 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): adaptive_layout_public_consumer |
| `CjguiStatusFeedback.buildMessage` | nodeId: Int64, semanticId: String, chipNodeId: Int64, textNodeId: Int64, actionNodeId: Int64 …（共 7 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `CjguiContentFeedback.build` | nodeId: Int64, semanticId: String, titleNodeId: Int64, detailNodeId: Int64, actionNodeId: Int64 …（共 7 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `CjguiProgressFeedback.build` | nodeId: Int64, semanticId: String, labelNodeId: Int64, trackNodeId: Int64, fillNodeId: Int64 …（共 9 项） | `CjguiComposableUiNode` | 有 | 无 | 有 (1): rule_set_window_app |
| `CjguiGeneratedUiStructureHolder.buildRefreshNode` | provider: CjguiGeneratedUiBindingProvider, feedback: ?CjguiGeneratedUiFormFeedback | `CjguiComposableUiNode` | 有 | 有 (15) | 有 (4): generated_collection, generated_panel_consumer, notification_threshold_window_app 等 |
| `CjguiGeneratedUiStructureHolder.buildAccepted` | provider: CjguiGeneratedUiBindingProvider, feedback: ?CjguiGeneratedUiFormFeedback | `CjguiComposableUiNode` | 有 | 有 (4) | 无 |
| `CjguiGeneratedUiCollection.buildComposite` | context: CjguiCompositeBuildContext | `CjguiComposableUiNode` | 无 | 无 | 无 |
| `CjguiGeneratedUiCollection.buildNode` | nodeId: Int64, semanticId: String, contentId: Int64, contentSemanticId: String, presentation: String, style: CjguiComposableUiStyle | `CjguiComposableUiNode` | 有 | 无 | 有 (1): generated_collection |
| `CjguiGeneratedUiWindowRegion.buildNode` | feedback: ?CjguiGeneratedUiFormFeedback | `CjguiComposableUiNode` | 无 | 有 (1) | 有 (6): generated_collection, linux_mixed_form_app, notification_threshold_window_app 等 |
| `cjguiGeneratedSliderComponent` | — | `CjguiGeneratedUiComponentSpec` | 有 | 无 | 有 (1): generated_collection |

## 3. 口径与限制

- **文档**：只看声明上方连续的 `///` 注释块（允许中间夹 `//` 续行，允许 `@` 属性行）。同一重载组按声明分别计；例如 `cjguiComposableText` 的 `style` 重载无文档、`boundStyle` 重载有；`cjguiComposableButton` 反之。
- **参数**：去掉 Cangjie 命名实参的 `!`；默认值只保留会影响行为的布尔/枚举/数值/非空字符串/语义样式；`None`、`""`、`-1`、默认构造的样式和空数组不记。
- **测试**：`src/*_test.cj` 直接标识符命中；方法用 `Class.method`（`build` 类）或 `Class` + `.method(`（`buildRow`/`buildUi`/`buildNode`/`buildComposite`/`attachTo` 类）限定，避免通用名误匹配。未检查 `tests/`、`native/`、`probe/`、`templates/`、`demo/`。
- **消费者**：`examples/**/*.cj` 递归直接调用，目录名取 `examples/` 下第一级；示例目录内的 `*_test.cj` 也算（仍是正常 import 的公共 API 消费），未区分应用主路径与示例内测试。
- **未纳入构造器**：`src/*.cj` 有 216 个 `public init`。控制器/面板（`CjguiCommandPalette`、`CjguiSearchableSelectionPanel`、`CjguiContextCommandMenu`、`CjguiComposableUiInspectorPanel`、`CjguiComposableUiCollectionViewState` 等）主要靠构造器创建；若下一包要审“控制器/面板类型”的完整公共面，应单列构造器，不要把它们混进本表的 `func` 计数。
- **未纳入接口回调/私有类**：`CjguiCompositeComponentFactory.buildComposite`、`CjguiInspectorRows.buildRow`、`CjguiInspectorCommandRows.buildRow`、`CjguiGeneratedCollectionRows.buildRow` 等，调用方是框架或私有实现，不是外部构造入口；直接按名字检索会误报“无消费者”。
- **源码身份**：本审计只读工作区，未验证编译；`platforms/ohos/snapshot/src/` 是另一份副本，未合并计数。

## 4. 证据文件

- `runtime/cjgui/audit/evidence/public-api-surface.tsv`：66 条数据行（另含 4 行 `#` 快照注释和 1 行表头），列为 `name / params / returns / has_doc / test_files / example_consumers`；`-` 表示无，多个文件/目录用 `;` 分隔。
- 本文所有数字均可由该 TSV 重新计数；源码定位见第 5 节及各行函数定义。

## 5. 无测试且无消费者的工厂

口径：`src/*_test.cj` 中无该函数名（方法用 `类名.方法` 或 `类名` + `.方法(` 限定），且 `examples/**/*.cj` 中无直接调用。**这是直接名字检索结果，不等于没有间接消费**；接口回调和控制器入口会在“说明”里标出。

| 工厂 | 位置 | 说明 |
| --- | --- | --- |
| `cjguiComposableSplitView` | `src/composable_ui.cj:5497` | 无直接测试、无示例调用、框架内无复用；`probe/pointer_controls_consumer_probe.cj` 有调用（审计口径外）。属于公开 API 的真实空档。 |
| `cjguiComposableSelectableListRow` | `src/composable_ui.cj:6020` | 无测试、无示例、框架内无复用；除本文件与 OHOS snapshot 副本外全仓无调用。**本组最高风险**。 |
| `CjguiGeneratedUiCollection.buildComposite` | `src/composable_ui_generated_collection.cj:56` | `CjguiCompositeComponentFactory` 接口实现；`examples/generated_collection` 通过 `collection.register(catalog)` 间接消费，无直接调用/专属测试。风险偏低但缺直接回归。 |
| `CjguiComposableUiInspectorPanel.buildUi` | `src/composable_ui_inspector.cj:191` | `CjguiComposableUiController` 接口实现；检查器窗口经控制器接口间接调用；示例只用了同类静态 `metric`。无直接调用/专属测试。 |

补充：**无示例消费者、但有测试**的有 7 条：`cjguiComposableGrid`、`cjguiComposableDialogLayer`、`cjguiComposableContextCommandMenuLayer`、`cjguiContextCommandMenuProjection`、`CjguiGeneratedUiStructureHolder.buildAccepted`、`CjguiSearchableSelectionPanel.buildRow`、`CjguiComposableUiTreeListSource.buildRow`。它们不是“无测试且无消费者”，但示例侧没有正向消费证据。
