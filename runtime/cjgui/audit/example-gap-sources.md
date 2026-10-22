# CJGUI 示例缺口：11 个组件的可抄调用来源

## 数据快照

- HEAD：`dc27dff`
- 未提交改动：`247`（`git status --porcelain | wc -l`）
- 快照时间：`2026-10-21T07:40:16Z`
- 本规格基于未提交改动的工作区，提交后数字会变。
- 本轮为纯静态检索，未运行构建、测试或应用；所有行号来自本轮 `rg`/`sed` 输出。

## 口径

- a：完整签名，含全部参数与默认值，取自 `sed` 的真实行段。
- b：`src/*_test.cj` 中的直接调用；方法类同时记录测试里的实例化行。
- c：`src/` 中非测试文件的框架内部调用。
- d：`runtime/cjgui/probe/` 或 `runtime/cjgui/examples/*/export_check/` 中的调用。
- `examples/` 下其他目录属于示例消费者，已计入上一轮审计，不在 b/c/d 范围内；其中与本表有关的复用点单列在“口径外发现”。
- `tests/`、`native/`、`templates/` 不在本次五项口径内；`templates/` 中与本表直接相关的调用单列在“口径外发现”。
- 本表唯一 `export_check` 目录是 `examples/tree_outline_consumer/export_check/`。其中 `buildRow` 命中是该示例自定义 source 的方法定义，不是本表 11 个组件的调用。

## 总表

| 组件 | 签名位置 | 测试调用 | 内部调用 | probe 或 export_check | 结论 |
| --- | --- | --- | --- | --- | --- |
| `cjguiComposableGrid` | `src/composable_grid.cj:77-81` | `composable_grid_test.cj:22,62,75,86`；`composable_grid_scroll_test.cj:21` | 无 | 无 | 可抄 |
| `cjguiComposableSplitView` | `src/composable_ui.cj:5497-5500` | 无 | 无 | `probe/pointer_controls_consumer_probe.cj:34` | 可抄 |
| `cjguiComposableSelectableListRow` | `src/composable_ui.cj:6020-6031` | 无 | 无 | 无 | 只能按签名推 |
| `CjguiComposableUiTreeListSource.buildRow` | `src/composable_ui_tree.cj:732-733` | `composable_ui_generated_perf_test.cj:114`（直接）；另 3 处构造 | `composable_ui.cj:8976,9193`（接口分发） | `probe/composable_ui_keyboard_navigation_probe.cj:100`（仅构造） | 可抄 |
| `CjguiSearchableSelectionPanel.buildRow` | `src/composable_ui_search_panel.cj:418` | `composable_ui_command_checked_test.cj:138,142`（直接）；另 3 处构造 | `composable_ui.cj:8976,9193`；`composable_ui_command_toolbar.cj:550`（构造） | 无 | 可抄 |
| `cjguiComposableContextCommandMenuLayer` | `src/composable_ui_context_command_menu.cj:291-295` | `composable_ui_context_command_menu_test.cj` 共 10 处 | `composable_ui_context_command_menu.cj:552` | 无 | 可抄 |
| `cjguiContextCommandMenuProjection` | `src/composable_ui_context_command_menu.cj:136-138` | `composable_ui_context_command_menu_test.cj` 共 10 处 | `composable_ui_command_toolbar.cj:371`；`composable_ui_context_command_menu.cj:463,515` | 无 | 可抄 |
| `cjguiComposableDialogLayer` | `src/composable_ui.cj:6193-6194` | `composable_ui_backdrop_identity_test.cj:83` | 无（仅定义） | 4 个 probe，见下节 | 可抄 |
| `CjguiComposableUiInspectorPanel.buildUi` | `src/composable_ui_inspector.cj:191` | 无 | `composable_ui_inspector.cj:619`（构造）；`composable_ui_window.cj:9721`（接口分发） | 无 | 不可推 |
| `CjguiGeneratedUiStructureHolder.buildAccepted` | `src/composable_ui_generated.cj:3382` | 6 处直接调用，分属 4 个测试文件 | 无 | `composable_ui_generated_commit_probe.cj:245`（直接）；2 处构造 | 可抄 |
| `CjguiGeneratedUiCollection.buildComposite` | `src/composable_ui_generated_collection.cj:56` | 无（测试中的 `buildComposite` 是测试工厂实现） | `composable_ui_generated.cj:4247`（接口分发） | 无 | 不可推 |

---

## 1. `cjguiComposableGrid`

### a. 签名

`src/composable_grid.cj:77-81`

```cangjie
public func cjguiComposableGrid(nodeId: Int64, semanticId: String, spec: CjguiGridSpec,
    style: CjguiComposableUiStyle, cellStyle: CjguiComposableUiStyle,
    separatorStyle: CjguiComposableUiStyle, ruleStyle: CjguiComposableUiStyle,
    caretNodeId!: Int64 = -1, caretOffset!: Int64 = -1,
    caretColor!: CjguiComposableUiColor = CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

`composable_grid_test.cj` 的 4 行命中：

```text
composable_grid_test.cj:22:     let grid = cjguiComposableGrid(1000, "table", spec, CjguiComposableUiStyle(),
composable_grid_test.cj:62:     let grid = cjguiComposableGrid(2000, "table", spec, CjguiComposableUiStyle(),
composable_grid_test.cj:75:     let grid = cjguiComposableGrid(3000, "table", spec, CjguiComposableUiStyle(),
composable_grid_test.cj:86:     let node = cjguiComposableGrid(7001, "grid-height-contract", spec,
```

`composable_grid_scroll_test.cj:21`：

```text
composable_grid_scroll_test.cj:21:     let grid = cjguiComposableGrid(2000, "table", spec, CjguiComposableUiStyle(),
```

同一测试文件中可直接抄的 `spec` 形态（`composable_grid_test.cj:17-18`）：

```text
    let spec = CjguiGridSpec([80, 40, 120],
        [["名称", "数量", "说明"], ["苹果", "3", "水果"], ["x"]])
```

调用把四个位置参数样式都写成 `CjguiComposableUiStyle()`，其余使用默认值。

### c. `src/` 框架内部调用

无。全 `src/` 非测试文件只有定义行 `composable_grid.cj:77` 和注释中的示例文本 `composable_grid.cj:95`。

### d. probe / export_check

无。`probe/` 与 `examples/tree_outline_consumer/export_check/` 均无 `cjguiComposableGrid` 命中。

### e. 结论

**可抄。** 5 处测试调用给出完整参数顺序、`CjguiGridSpec` 的两层数组构造和四个样式位置；没有 probe/示例消费，但不影响写示例。

---

## 2. `cjguiComposableSplitView`

### a. 签名

`src/composable_ui.cj:5497-5500`

```cangjie
public func cjguiComposableSplitView(nodeId: Int64, semanticId: String, first: CjguiComposableUiNode,
    second: CjguiComposableUiNode, axis: Int64, firstSize: Int64, minFirst: Int64, minSecond: Int64,
    style: CjguiComposableUiStyle, operationActionName!: String = "SET_SPLIT_SIZE", operationResourceId!: Int64 = -1,
    handleNodeId!: Int64 = -1, handleThickness!: Int64 = 8): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

无（`rg 'cjguiComposableSplitView\(' --glob '*_test.cj'` 为 0 命中）。

### c. `src/` 框架内部调用

无。全 `src/` 非测试文件只有定义行 `composable_ui.cj:5497`，没有框架内复用。

### d. probe / export_check

`probe/pointer_controls_consumer_probe.cj:34`：

```text
    let split = cjguiComposableSplitView(100, "rule-set-split", first, second,
        CjguiComposableUiSplitAxis.HORIZONTAL, 180, 120, 160,
        CjguiComposableUiStyle(growX: 1, growY: 1), operationResourceId: 8000)
```

这是真实调用，包含两个子节点、轴、三段尺寸、样式和 `operationResourceId` 命名参数。

### e. 结论

**可抄。** 测试侧仍为空，但 probe 提供了完整、可运行的调用形态；上一轮审计也注明该 probe 属于审计口径外。除 probe 外没有示例消费者。

---

## 3. `cjguiComposableSelectableListRow`

### a. 签名

`src/composable_ui.cj:6020-6031`

```cangjie
public func cjguiComposableSelectableListRow(
    nodeId: Int64,
    semanticId: String,
    item: CjguiComposableUiVirtualListItem,
    actionName: String,
    normalStyle: CjguiComposableUiStyle,
    selectedStyle: CjguiComposableUiStyle,
    isSelected: Bool,
    isFocused: Bool,
    enabled!: Bool = true,
    operationActionName!: String = ""
): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

无（0 命中）。

### c. `src/` 框架内部调用

无。除定义外，`src/` 内没有其他引用。

### d. probe / export_check

无。`probe/` 与唯一 `export_check` 目录均无命中。

### 全仓补充

排除本文件定义、OHOS snapshot 副本和 Linux evidence 副本后，全仓没有调用；`README.md:391` 只有说明性文字，没有代码调用。`CjguiComposableUiVirtualListItem` 是简单三字段公开构造器（`composable_ui.cj:1655-1662`），样式类型也是公开普通构造器，没有隐藏接口。

### e. 结论

**只能按签名推。** 没有任何真实调用可抄。签名本身可自洽拼出：调用方需自行决定 `actionName`/`operationActionName` 的关系，以及 `normalStyle`/`selectedStyle` 的取值；`item` 可用 `CjguiComposableUiVirtualListItem(key, resourceId, title)` 直接构造。由于依赖类型都是公开普通类型，不构成“不可推”。

---

## 4. `CjguiComposableUiTreeListSource.buildRow`

### a. 签名

`src/composable_ui_tree.cj:732-733`

```cangjie
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
                         isFocused: Bool): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

直接调用 1 处，`composable_ui_generated_perf_test.cj:114`：

```text
composable_ui_generated_perf_test.cj:114:                 let row = listSource.buildRow(item, false, false)
```

测试中的实例化（3 处）：

```text
composable_ui_generated_perf_test.cj:94:     let listSource = CjguiComposableUiTreeListSource(projection, selection,
composable_ui_tree_test.cj:760:     let listSource = CjguiComposableUiTreeListSource(projection, selection,
composable_ui_window_perf_test.cj:255:             CjguiComposableUiTreeListSource(projection, selection,
```

### c. `src/` 框架内部调用

虚拟列表统一接口分发：

```text
composable_ui.cj:8976:                         let row = source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
composable_ui.cj:9193:                 let row = source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
```

`cjguiComposableTree` 只把 source 接到虚拟列表（`composable_ui_tree.cj:764-768`），没有直接调用 `buildRow`。

### d. probe / export_check

`probe/composable_ui_keyboard_navigation_probe.cj:100`：

```text
        let listSource = CjguiComposableUiTreeListSource(projection, selection,
```

该 probe 只构造 source 并做导航/reveal，没有直接调用 `.buildRow`。`export_check` 无命中。

### e. 结论

**可抄。** 测试既有完整构造（projection、selection、builder lambda），也有直接 `buildRow(item, false, false)` 调用；框架通过虚拟列表接口消费。上一轮“无示例消费者”指的是 `examples/**` 没有直接 `.buildRow` 调用，但示例确实构造了这个 source（见“口径外发现”）。

---

## 5. `CjguiSearchableSelectionPanel.buildRow`

### a. 签名

`src/composable_ui_search_panel.cj:418`

```cangjie
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

直接调用 2 处，`composable_ui_command_checked_test.cj:138,142`：

```text
composable_ui_command_checked_test.cj:138:     let row = panel.buildRow(panel.itemAt(0), false, false)
composable_ui_command_checked_test.cj:142:     let highlighted = panel.buildRow(panel.itemAt(0), true, false)
```

测试中的实例化（3 处）：

```text
composable_ui_command_checked_test.cj:114:     let panel = CjguiSearchableSelectionPanel("checked-panel")
composable_ui_command_scope_test.cj:243:     let panel = CjguiSearchableSelectionPanel("dynamic-panel")
composable_ui_command_scope_test.cj:298:     let emptyPanel = CjguiSearchableSelectionPanel("empty-only-panel")
```

### c. `src/` 框架内部调用

构造器在命令工具栏内部使用：

```text
composable_ui_command_toolbar.cj:550:         this.panel = CjguiSearchableSelectionPanel(scopeKey)
```

`buildRow` 经虚拟列表接口分发：

```text
composable_ui.cj:8976:                         let row = source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
composable_ui.cj:9193:                 let row = source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
```

### d. probe / export_check

无。`probe/` 与 `export_check` 均无 `CjguiSearchableSelectionPanel` 或 `.buildRow` 命中。

### e. 结论

**可抄。** 测试直接调用 `panel.buildRow(panel.itemAt(0), false/true, false)`，并覆盖选中与未选中两种状态；构造函数只需要一个 scope key。审计中的“无示例消费者”仅指 `.buildRow` 没有在 `examples/**` 直接调用；示例实际使用的是 `attachTo`（见“口径外发现”）。

---

## 6. `cjguiComposableContextCommandMenuLayer`

### a. 签名

`src/composable_ui_context_command_menu.cj:291-295`

```cangjie
public func cjguiComposableContextCommandMenuLayer(scope: CjguiComposableUiIdentityScope,
    semanticId: String, request: CjguiComposableUiContextMenuRequest,
    projection: CjguiContextCommandMenuProjection, ownerSemanticId: String,
    style!: CjguiContextCommandMenuStyle = CjguiContextCommandMenuStyle(),
    scrollViewport!: ?CjguiComposableUiScrollViewport = None): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

均在 `composable_ui_context_command_menu_test.cj`，共 10 处：

```text
composable_ui_context_command_menu_test.cj:162:     let layerA = cjguiComposableContextCommandMenuLayer(scopeA.child("context-menu"), "context-menu-a", requestA,
composable_ui_context_command_menu_test.cj:164:     let layerB = cjguiComposableContextCommandMenuLayer(scopeB.child("context-menu"), "context-menu-b", requestB,
composable_ui_context_command_menu_test.cj:240:         let _ = cjguiComposableContextCommandMenuLayer(scope, "context-menu-empty", request,
composable_ui_context_command_menu_test.cj:253:         let _ = cjguiComposableContextCommandMenuLayer(scope, "context-menu-mismatch", other,
composable_ui_context_command_menu_test.cj:272:     let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-k",
composable_ui_context_command_menu_test.cj:312:     let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-d",
composable_ui_context_command_menu_test.cj:358:     let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-s",
composable_ui_context_command_menu_test.cj:374:         let _ = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-s2",
composable_ui_context_command_menu_test.cj:400:     let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-l",
composable_ui_context_command_menu_test.cj:470:     let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-t",
```

测试覆盖正常投影、空投影、request/projection 不匹配和禁用项等分支。

### c. `src/` 框架内部调用

`composable_ui_context_command_menu.cj:552`，在既有 `CjguiContextCommandMenu.attachTo` 内部：

```text
composable_ui_context_command_menu.cj:552:         host.add(cjguiComposableContextCommandMenuLayer(menuScope, semanticId, request, projection,
```

### d. probe / export_check

无。

### e. 结论

**可抄。** 测试直接给出 `scope.child("context-menu")`、`semanticId`、`request`、`projection`、`ownerSemanticId` 的完整组合；内部 `attachTo` 还给出了带 `style`/`scrollViewport` 的接法。

---

## 7. `cjguiContextCommandMenuProjection`

### a. 签名

`src/composable_ui_context_command_menu.cj:136-138`

```cangjie
public func cjguiContextCommandMenuProjection(request: CjguiComposableUiContextMenuRequest,
    commands: ArrayList<CjguiComposableUiCommand>, metadata: ArrayList<CjguiCommandToolbarMetadata>,
    searchCommandId!: String = ""): CjguiContextCommandMenuProjection {
```

### b. `src/*_test.cj` 直接调用

均在 `composable_ui_context_command_menu_test.cj`，共 10 处：

```text
composable_ui_context_command_menu_test.cj:71:     let projection = cjguiContextCommandMenuProjection(request, commands, metadata,
composable_ui_context_command_menu_test.cj:105:     let projection = cjguiContextCommandMenuProjection(requestA,
composable_ui_context_command_menu_test.cj:151:     let projectionA = cjguiContextCommandMenuProjection(requestA,
composable_ui_context_command_menu_test.cj:154:     let projectionB = cjguiContextCommandMenuProjection(requestB,
composable_ui_context_command_menu_test.cj:247:     let projection = cjguiContextCommandMenuProjection(request,
composable_ui_context_command_menu_test.cj:267:     let projection = cjguiContextCommandMenuProjection(request, commands, metadata,
composable_ui_context_command_menu_test.cj:310:     let projection = cjguiContextCommandMenuProjection(request, commands, metadata)
composable_ui_context_command_menu_test.cj:353:     let projection = cjguiContextCommandMenuProjection(request,
composable_ui_context_command_menu_test.cj:399:     let projection = cjguiContextCommandMenuProjection(request, commands, metadata)
composable_ui_context_command_menu_test.cj:469:     let projection = cjguiContextCommandMenuProjection(request, commands, metadata)
```

### c. `src/` 框架内部调用

```text
composable_ui_command_toolbar.cj:371:         return cjguiContextCommandMenuProjection(request, commands, metadata,
composable_ui_context_command_menu.cj:463:         let projection = cjguiContextCommandMenuProjection(request, commands, metadata,
composable_ui_context_command_menu.cj:515:         let current = cjguiContextCommandMenuProjection(request, commands, metadata,
```

### d. probe / export_check

无。

### e. 结论

**可抄。** 测试既覆盖带 `searchCommandId` 的调用，也覆盖省略默认值的调用；内部命令工具栏和 context menu 类还给出实际接线。

---

## 8. `cjguiComposableDialogLayer`

### a. 签名

`src/composable_ui.cj:6193-6194`

```cangjie
public func cjguiComposableDialogLayer(nodeId: Int64, semanticId: String, layerId: String, ownerSemanticId: String,
    ownerNodeId: Int64, style: CjguiComposableUiStyle, initialFocusNodeId!: Int64 = -1): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

`composable_ui_backdrop_identity_test.cj:83`：

```text
composable_ui_backdrop_identity_test.cj:83:     let dialog = cjguiComposableDialogLayer(9, "search-panel-settings-commands",
```

完整调用跨 83-85 行：`9`、`"search-panel-settings-commands"`、同名 layerId、owner semantic、`2`、`CjguiComposableUiStyle(fixedWidth: 500, fixedHeight: 300)`，省略 `initialFocusNodeId`。

### c. `src/` 框架内部调用

无。`src/` 非测试文件只有定义 `composable_ui.cj:6193` 和同族 `cjguiComposableDialogLayerWithReference` 定义 `composable_ui.cj:6204`，没有内部调用。

### d. probe / export_check

4 个 probe：

```text
probe/composable_ui_window_controller_probe.cj:495:             let dialog = cjguiComposableDialogLayer(9004, "layer-dialog", "layer-input-dialog", "layer-input-base", 9002,
probe/pointer_capture_lifecycle_probe.cj:88:             let dialog = cjguiComposableDialogLayer(9103, "pointer-capture-dialog", "pointer-capture-modal",
probe/composable_ui_layout_probe.cj:2269:     let dialog = cjguiComposableDialogLayer(1206, "layer-dialog", "dialog-1", "rule-detail", 1202,
probe/composable_ui_interaction_style_native_probe.cj:130:             let dialog = cjguiComposableDialogLayer(9910, "press-boundary-dialog", "press-boundary-modal",
```

其中 `composable_ui_window_controller_probe.cj:495`、`composable_ui_layout_probe.cj:2269` 和 `composable_ui_interaction_style_native_probe.cj:130` 带 `initialFocusNodeId`；`pointer_capture_lifecycle_probe.cj:88` 省略。`export_check` 无命中。

### e. 结论

**可抄。** 测试给出最小调用，4 个 probe 给出带初始焦点、嵌套内容和不同 owner 的完整用法；`templates/application/ui_only/src/main.cj:104` 还有一份精确调用（见“口径外发现”）。

---

## 9. `CjguiComposableUiInspectorPanel.buildUi`

### a. 签名

`src/composable_ui_inspector.cj:191`

```cangjie
    public func buildUi(): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

无。`rg 'CjguiComposableUiInspectorPanel' --glob '*_test.cj'` 为 0 命中。

### c. `src/` 框架内部调用

构造发生在既有 macOS inspector 窗口中：

```text
composable_ui_inspector.cj:619:         let candidate = CjguiComposableUiInspectorPanel(source, collectCosts: collectCosts)
composable_ui_inspector.cj:620:         let result = application.openWindow(candidate,
```

`buildUi` 由窗口控制器接口统一分发：

```text
composable_ui_window.cj:9721:             let declaredRoot = controller.buildUi()
```

接口声明为 `CjguiComposableUiController.buildUi()`（`composable_ui_window.cj:734-740`），构造器签名是 `public init(source: CjguiComposableUiWindow, collectCosts!: Bool = false)`（`composable_ui_inspector.cj:32`）。

### d. probe / export_check

无。

### e. 结论

**不可推。** 卡点不是 `buildUi` 的参数（它无参数），而是组件入口依赖运行中的 `CjguiComposableUiWindow`：`buildUi` 是 `CjguiComposableUiController` 的接口回调，只在窗口构建路径 `composable_ui_window.cj:9721` 被调用；面板本身只在 `composable_ui_inspector.cj:619` 由 `CjguiMacosInspector.open` 构造并交给 `application.openWindow`。测试、probe、`export_check` 都没有直接调用。要写示例只能经 `CjguiMacosInspector` 做集成示例，无法写成不依赖运行中窗口的最小示例。

---

## 10. `CjguiGeneratedUiStructureHolder.buildAccepted`

### a. 签名

`src/composable_ui_generated.cj:3382`

```cangjie
    public func buildAccepted(provider: CjguiGeneratedUiBindingProvider, feedback!: ?CjguiGeneratedUiFormFeedback = None): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

6 处，分属 4 个测试文件：

```text
composable_ui_composite_test.cj:437:     let builtWithGap = holder.buildAccepted(provider)
composable_ui_composite_test.cj:446:     let builtBare = holder.buildAccepted(provider)
composable_ui_tree_test.cj:512:     let built = holder.buildAccepted(GeneratedTestProvider())
composable_ui_tree_test.cj:529:     let built = holder.buildAccepted(provider)
composable_ui_generated_perf_test.cj:329:         let node = holder.buildAccepted(provider)
composable_ui_generated_motion_test.cj:90:     let oldScene = holder.buildAccepted(provider)
```

测试中 `CjguiGeneratedUiStructureHolder(catalog)` 等构造共 83 行，代表行：

```text
composable_ui_composite_test.cj:208:     let holder = CjguiGeneratedUiStructureHolder(catalog)
```

### c. `src/` 框架内部调用

无。全 `src/` 非测试文件没有 `.buildAccepted(` 调用。

### d. probe / export_check

probe 中的构造：

```text
probe/generated_ui_image_lifecycle_probe.cj:95:         this.holder = CjguiGeneratedUiStructureHolder(catalog,
probe/composable_ui_generated_commit_probe.cj:44:         this.holder = CjguiGeneratedUiStructureHolder(catalog,
```

probe 中的直接调用：

```text
probe/composable_ui_generated_commit_probe.cj:245:     let rebuilt = holder.buildAccepted(CommitProbeProvider())
```

`export_check` 无命中。

### e. 结论

**可抄。** 测试和 probe 都直接调用 `buildAccepted(provider)`，测试还覆盖 `feedback` 缺省路径；构造 side 也有大量 `CjguiGeneratedUiStructureHolder(catalog)` 先例。上一轮“无示例消费者”仅指 `.buildAccepted` 未在 `examples/**` 直接调用（示例只构造 holder）。

---

## 11. `CjguiGeneratedUiCollection.buildComposite`

### a. 签名

`src/composable_ui_generated_collection.cj:56`

```cangjie
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
```

### b. `src/*_test.cj` 直接调用

无。`rg 'CjguiGeneratedUiCollection' --glob '*_test.cj'` 为 0 命中。

测试中出现的 `buildComposite` 都是测试工厂自己实现接口，不是对本组件的调用：

```text
composable_ui_composite_test.cj:49:     public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
composable_ui_composite_test.cj:394:     public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
composable_ui_encoding_test.cj:27:     public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
composable_ui_style_test.cj:22:     public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
```

### c. `src/` 框架内部调用

框架在展开生成结构时构造 context 并调用工厂：

```text
composable_ui_generated.cj:4244:         let context = CjguiCompositeBuildContext(spec.key, properties, bindings, children: children,
composable_ui_generated.cj:4247:         let built = factory.buildComposite(context)
```

接口声明为 `CjguiCompositeComponentFactory.buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode`（`composable_ui_composite_component.cj:275-277`）；`CjguiCompositeBuildContext` 是公开类（`composable_ui_composite_component.cj:204`），但其 `elements`、`properties`、`children` 由生成结构展开过程填充（`composable_ui_generated.cj:4232-4247`）。

### d. probe / export_check

无。

### e. 结论

**不可推。** `buildComposite` 是 `CjguiCompositeComponentFactory` 的接口回调，不是应用直接调用的构造入口；`CjguiCompositeBuildContext` 由框架在生成结构展开时按 spec/instance 组装，测试/probe/`export_check` 没有直接调用，也没有可直接抄的 context 拼装样例。应用侧现有形态是 `collection.register(catalog)`（`examples/generated_collection/src/main.cj:196`），由生成面间接触发；可以据此写注册型示例，但无法写成只靠一个独立 context 的最小示例，因为需要自行构造 `elements`/`bindings` 并复现生成结构的展开约定。

---

## 口径外发现（与审计基线的关系）

1. **`cjguiComposableSplitView` 不是完全空白。** 上一轮审计已注明 `probe/pointer_controls_consumer_probe.cj` 有调用；本轮确认行号是 `34`，且调用完整，因此归为“可抄”。

2. **`CjguiComposableUiTreeListSource` 类本身在示例中有构造。** 虽然 `examples/**` 没有直接 `.buildRow`，以下示例构造了该 source 并传入 builder lambda：
   - `examples/adaptive_layout_public_consumer/src/main.cj:810`
   - `examples/tree_outline_consumer/src/main.cj:518`
   - `examples/rule_set_window_app/src/rule_set_tree.cj:652`

3. **`CjguiSearchableSelectionPanel` 类本身在示例中有构造和 `attachTo`。**
   - `examples/notification_threshold_window_app/src/main.cj:17`（构造），`examples/notification_threshold_window_app/src/main.cj:449`（`channelPanel.attachTo`）
   - `examples/rule_set_window_app/src/main.cj:344`（构造），`examples/rule_set_window_app/src/main.cj:1566`（`recordSearchPanel.attachTo`）

4. **`CjguiGeneratedUiStructureHolder` 类本身在示例中有构造，但没有 `.buildAccepted` 直接调用。**
   - `examples/generated_panel_consumer/src/generated_region.cj:372`
   - `examples/rule_set_window_app/src/rule_set_generated.cj:65`

5. **`CjguiGeneratedUiCollection` 在示例中有构造和注册，但 `buildComposite` 仍只由框架调用。**
   - `examples/generated_collection/src/main.cj:190`（构造）
   - `examples/generated_collection/src/main.cj:196`（`collection.register(catalog)`）
   - `examples/generated_collection/src/collection_checks.cj:80`（第二个实例）

6. **`CjguiComposableUiInspectorPanel` 在示例中只用了静态 `metric`，但间接入口 `CjguiMacosInspector` 被多处使用。**
   - `examples/generated_collection/src/inspector_checks.cj:17-19`（静态 `metric`）
   - `examples/generated_collection/src/main.cj:484`
   - `examples/settings_form_window_app/src/main.cj:1166`
   - `templates/macos_application/command_surface/src/main.cj:346`
   - `templates/macos_application/mixed_form/src/main.cj:646`

7. **`cjguiComposableDialogLayer` 的精确函数在模板中有直接调用。** `templates/application/ui_only/src/main.cj:104`；`examples/` 下实际使用的是同族 `cjguiComposableDialogLayerWithReference`（例如 `examples/rule_set_window_app/src/main.cj:1420`），不是被审计的精确函数。

8. **`cjguiComposableSelectableListRow` 是 11 项里唯一全仓零真实调用的一项。** 除定义、OHOS snapshot 副本、Linux evidence 副本和 README 说明文字外，没有测试、probe、示例或框架内部调用。

## 结论统计

- **可抄（8）**：`cjguiComposableGrid`、`cjguiComposableSplitView`、`CjguiComposableUiTreeListSource.buildRow`、`CjguiSearchableSelectionPanel.buildRow`、`cjguiComposableContextCommandMenuLayer`、`cjguiContextCommandMenuProjection`、`cjguiComposableDialogLayer`、`CjguiGeneratedUiStructureHolder.buildAccepted`。
- **只能按签名推（1）**：`cjguiComposableSelectableListRow`。
- **不可推（2）**：`CjguiComposableUiInspectorPanel.buildUi`（需运行中的窗口/控制器接口）、`CjguiGeneratedUiCollection.buildComposite`（接口回调，context 由框架生成结构展开时组装）。
