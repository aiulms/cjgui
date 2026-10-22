# 可排序表格投影（CjguiComposableUiTableSource）

公共实现：[composable_ui_table.cj](../../src/composable_ui_table.cj)、[composable_ui_table_layout.cj](../../src/composable_ui_table_layout.cj)。不同列定义的独立消费者见 [table_layout_consumer](../table_layout_consumer/README.md)。它不复制业务记录，也不接管 owner 的校验、写入、Apply/Cancel；只在既有 `CjguiComposableUiFilteredListSource` 的稳定 key 行上生成一条可排序的可见顺序。多选、批量与列表/表格共享选择见 [COLLECTION_SELECTION.md](COLLECTION_SELECTION.md)。

## 组成

- `CjguiComposableUiTableColumn`：`key/title/fieldId/width/sortActionName/valueOf/compare`。`width <= 0` 表示唯一可伸缩列（通常是名称），其余为固定宽度。
- `CjguiComposableUiTableStyle`：表头与行共用同一份行高、内边距、字体和颜色。
- `CjguiComposableUiTableRowAction`：调用方为一行声明的激活值。`actionName` 为空表示展示行；`none()` 等价于 `("", -1)`。
- `CjguiComposableUiTableColumnLayout`：按稳定列 key 保存宽度、显隐和顺序；表头与正文读取同一实例。旧构造方式不传 layout 时由表格内部创建，行为与之前一致。
- `CjguiComposableUiTableSource`：包装 filtered source，提供 `buildHeader()`、`buildRow()`、`updatePresentation(style)`、`setSort(columnKey)`（同列再调用切换升/降）、`clearSort()`、`sortIndicator(columnKey)`、`itemCount/itemAt/indexForKey`、`measurementGeneration()`、`layout()/layoutRevision()`。

## 列布局与交互

稳定列 key 是唯一身份；宽度、显隐和顺序只在 `CjguiComposableUiTableColumnLayout` 中保存一次：

```cangjie
let columns = CjguiRuleSetTableColumns.create(domain)
let layout = CjguiComposableUiTableColumnLayout(columns)
let table = CjguiComposableUiTableSource(filteredListSource, "rule-set-table",
    columns, style, layout: layout)

layout.setWidth("retention", 120)   // 固定宽度，自动 clamp 到列声明的 min/max
layout.nudgeWidth("retention", 16)  // 菜单/键盘步进
layout.setVisible("excluded", false)
layout.move("retention", -1)
let state = layout.encodeState()    // TABLE_COLUMNS 1 | key:width:visible:min:max
```

- 传入的 layout 必须由同一组列声明构造；表格按 layout 的稳定 key 投影，layout 中不存在的声明列不会被展示。未传 layout 时表格用传入列自动创建。
- `width <= 0` 仍是声明的弹性列；弹性列没有已解析宽度，因此不渲染拖动手柄，`beginResize`/`nudgeWidth` 返回 false。调用方可以先用 `setWidth` 给它一个固定宽度。
- 固定列的表头尾部有一个 6pt 的分隔手柄。手柄复用现有 `CJGUI_COMPOSABLE_UI_SPLIT_HANDLE` 节点和 37/38/39/40 指针阶段，但没有绑定 split state；控制器把阶段接到列布局的 `beginResize/updateResize/endResizeAt/cancelResize`，不会误改分栏宽度。
- END 先按该原手势的最终 `pointerX` 更新宽度，再结束；CANCEL 没有坐标重载，普通取消恢复起始宽度。
- 独立修改同列（`setWidth/resetWidth/nudgeWidth/move`）、隐藏目标或 `reset()` 会使当前拖动失效；之后的旧 UPDATE/END/CANCEL 都是 no-op，不会覆盖新状态。`resizeCaptureVersion()` 在正常更新时保持稳定，只在拖动被独立修改失效时推进，供应用既有的 pointer-capture provider 复用；没有独立修改的普通取消仍恢复起始宽度。
- 宽度由列声明的 `minWidth/maxWidth`（默认 56/480）约束；最后一个可见列不能被隐藏。
- `table.minimumContentWidth(): Int64`（experimental）只读求和当前可见固定列宽与弹性列的声明最小宽。表头和正文使用同一最小值，宿主可据此安排集合与详情，而不修改列偏好。行、表头及表头单元格复用公共 `clipsContent`，超出自身列/行边界的绘制和命中一起裁剪。
- 规则窗口在集合最小可读宽度＋详情260pt＋分隔8pt容不下时，把原表格与原详情上下排列；恢复宽窗后沿用分栏偏好。模式、排序、选择、字段/列身份和草稿不会随窗口宽度改变。默认列和普通16pt宽度步进可在620窗口使用。
- 全部固定列拉到很宽、连整个窗口也容不下时，保留这些偏好并显示“列宽超出当前空间”；仍可用列设置缩窄、显隐或恢复默认。本组件没有新增横向滚动引擎，也不静默删列或自动改写列宽。
- 列菜单复用现有 anchored layer 和普通按钮：显隐、左右换序、−/+ 宽度、恢复默认。按钮可 Tab 聚焦、Enter/Space 激活；表头手柄获得键盘焦点时左右键也走同一 `nudgeWidth`。
- 表头单元格是容器（保留原 `header-cell-<key>` 身份），排序按钮和拖动手柄各有子身份。行/单元格身份、排序、筛选、多选和 owner 草稿都不随列状态变化。
- 列状态是窗口视图状态，不写入规则文件；外部通过既有 `get --target 8000` 读取资源字段 `tableColumns` / `tableColumnsRevision`，通过既有 `INVOKE` 动作 `SET_TABLE_COLUMN_WIDTH`、`SET_TABLE_COLUMN_VISIBLE`、`MOVE_TABLE_COLUMN`、`RESET_TABLE_COLUMNS` 修改。外部和人类操作调用同一个 layout 对象；期望版本是 `tableColumnsRevision`，不是文档版本。列动作的目标必须恰为规则集资源 8000（复用 `isRuleSetTarget` 的同一规则）；空目标、多目标和错误目标明确拒绝，列状态与 revision 保持不变。

## 身份与引用

表格不再生成哈希节点号，也不再暴露 `headerNodeId()/rowNodeId()/cellNodeId()` 一类数值身份。每个节点声明现有的 `CjguiComposableUiIdentity`，由窗口的 `CjguiComposableUiIdentityRegistry` 统一分配和复用 scoped 节点号：

| 节点 | 作用域（相对 `instanceKey`） | 身份 |
| --- | --- | --- |
| 表头容器 | `instance` | `instance/header` |
| 表头单元格 | `instance/header` | `instance/header/<columnKey>` |
| 正文行 | `instance/rows` | `instance/rows/<rowKey>` |
| 正文单元格 | `instance/cells/<rowKey>` | `instance/cells/<rowKey>/<columnKey>` |

- 业务身份仍由稳定 `rowKey` 决定；排序只改变投影位置，不改行/单元格身份。已接受的映射在下一候选树中复用同一节点号。
- 表头、正文行、单元格是分开的命名空间；列 key 与行 key 不会拼成一个身份串。
- key 必须满足现有 scope 契约：1–96 字节 ASCII 字母/数字/`_`/`-`，子路径 ≤256，完整身份 key ≤384。非法或超长 key 由注册表明确拒绝为 `identity_invalid_scope_or_key`，不会静默丢行、截断 key 或扩大哈希范围。空 key 在既有虚拟列表契约中本就不是可物化行。`instanceKey` 是身份根作用域，也必须是合法的 scope 段；表格不替换或清洗调用方给的名字。同一候选树中两个表格实例必须使用不同 `instanceKey`，否则共享注册表会按现有规则报告重复身份。
- `headerReference()`、`headerCellReference(columnKey)`、`rowReference(rowKey)`、`cellReference(rowKey, columnKey)` 返回 `CjguiComposableUiNodeReference.scoped(...)`，可直接用于现有 layer/focus 引用。正文引用只对当前候选已物化的可见行成立；屏幕外行不会为取得身份而被提前构建，引用不到时由注册表按现有规则拒绝候选。
- scoped 身份数量受注册表现有上限 1024 约束。表格只给当前可见窗口的行/单元格声明身份，不遍历全量数据，因此 240/400 行投影仍只占用可见行数量的身份。

节点语义 id 是展示/定位辅助，不是业务身份：`<instanceKey>-header`、`<instanceKey>-header-cell-<columnKey>`、`<instanceKey>-row-<rowKey>`、`<instanceKey>-cell-<rowKey>-<columnKey>`。

## 行激活

公共表格不写死 `SELECT_RECORD`。调用方通过构造参数提供行激活行为：

```cangjie
let tableSource = CjguiComposableUiTableSource(filteredListSource, "rule-set-table",
    columns, style, rowAction: { item =>
        if (item.resourceId >= 0) {
            CjguiComposableUiTableRowAction("SELECT_RECORD", item.resourceId)
        } else {
            CjguiComposableUiTableRowAction.none()
        }
    })
```

- 有动作：每个单元格是按钮，携带调用方给出的 `actionName`/`resourceId`，并同步声明 `operationActionName`/`operationResourceId`。
- 无动作或未提供 provider：单元格是静态文本，保留 `item.resourceId` 仅作为展示资源，不发出业务操作；`resourceId=-1` 的合法行正常显示。
- 未声明 `sortActionName` 的表头列同样是静态文本，不合成动作。
- 本应用适配层仍在 `main.cj` 中声明 `SELECT_RECORD`；公共组件不新增命令或 owner 状态机。
- 多行高亮由调用方提供可选 `rowSelected: (String) -> Bool` 谓词（按稳定 row key 回答）。表格不保存选择状态，也不把同一行的多个动作合并成新的选择模型。

## 样式与测量

`updatePresentation(style)` 只把行高、单元格内边距、字号、字体族视为几何输入。几何变化使 `measurementGeneration()` 前进一次，既有虚拟列表据此清空自己派生出的稀薄测量缓存并重新测量；颜色、背景、表头高度等纯绘制变化不推进 generation，不会触发重排或无必要测量。源自身的 measurement generation 变化也会被合并进返回值，但没有清空全量缓存或另造测量通道。

## 接入

1. 已有稳定 key 的列表源（本应用为 `filteredListSource`）保持不变：
   ```cangjie
   let tableSource = CjguiComposableUiTableSource(filteredListSource, "rule-set-table",
       columns, style, rowAction: ...)
   ```
2. 每次重建界面时刷新展示与数据版本，查询走同一个 filtered source：
   ```cangjie
   tableSource.updatePresentation(style)
   tableSource.dataChanged(domain.version())
   let _ = tableSource.setQuery(listFilter)   // 空查询直接委托，不扫描
   ```
3. 表头放入列容器，正文复用原有虚拟列表，选择/焦点仍用同一个 `CjguiComposableUiVirtualListState`：
   ```cangjie
   pane.add(tableSource.buildHeader())
   pane.add(cjguiComposableVariableHeightList(..., tableSource, listState, ...))
   ```
   `CjguiComposableUiTableSource` 使用 scoped identity，所在候选树必须带 `CjguiComposableUiIdentityRegistry` 布局（正常窗口入口已具备）；只读测试也要走同一路径。
4. 表头点击动作由列声明的 `sortActionName` 带入应用；应用把它映射回列 key：
   ```cangjie
   if (event.eventKind != 27) { return false }
   if (node.actionName == "TABLE_SORT_NAME") { tableSource.setSort("name") }
   ```
   `setSort` 只在排序列/方向真的改变时使顺序失效，并返回是否发生变化。
5. 键盘移动使用当前视图的源（列表或表格），不能固定用 filtered 列表：
   ```cangjie
   listState.moveFocus(currentListSource(), direction)
   ```

列内容仍由调用方通过 `valueOf(item)` 从 owner 读取。本应用中的列声明见 [rule_set_table_columns.cj](src/rule_set_table_columns.cj)：名称 flex、启用 68、保留天数 78、排除类型 96；数字列的比较器读取 `Int64`，不按字符串比较。

## 行为约束

- 排序是稳定归并排序，同值保持过滤源顺序；单列升/降，再次点击同列切换方向。
- 顺序只在 `setQuery`、`setSort`、`dataChanged`（版本变化）或 `invalidate()` 后重建，不在布局/绘制每帧扫描。
- `projected(item)` 把布局版本标记为 `revision*4+2`，避免与同 key 列表行复用高度缓存；排序位置不进入版本。
- 表头与正文都用同一列宽/内边距/字体声明，窗口缩放后保持对齐。
- 行/单元格身份和引用来自共享身份机制；公共表格不保存屏幕外行的身份映射。

## 已知限制

- 不做冻结列、合并单元格或横向滚动；只有声明的弹性列可伸缩。固定列宽度有 min/max 约束，多个固定列同时拉宽可超过当前面板宽度（布局会裁剪，不产生横向滚动条）。
- 列布局不持久化到规则文件；重开窗口回到声明默认值。桌面真实鼠标拖动受本机 foreign-window base-readback 边界影响时未复核，37/38/39/40 指针阶段由 controller 用例覆盖。
- 文本比较器决定文本顺序。当前规则名称按 UTF-8/码点顺序，所以带数字后缀的名称会得到 `1, 101, 11…` 的顺序；数字列由列比较器按数值排序。
- 排序状态是窗口视图状态，不写入文件，也不随文档恢复。
- 虚拟列表在重排后会保持原来置顶稳定 key；需要看排序后的第一行时按 Home（或滚动到顶）。这不是排序错误。
- `compare` 由调用方提供；公共组件不猜测字段类型，也不做多列排序。
- 屏幕外行既没有节点身份也没有引用；需要长期定位时由调用方以稳定 `rowKey` 重新声明引用，而不是缓存旧节点号。

## 运行与定向测试

```sh
cd runtime/cjgui/examples/rule_set_window_app
zsh ./run.sh --retention-range 1 100 --seed-table-rows 240
```

公共布局用例在核心包运行：

```sh
cd runtime/cjgui
cjpm test --filter 'tableColumnLayoutSharesHeaderBodyWidthsAndKeepsOldConstructor'
cjpm test --filter 'tableColumnLayoutHidesAndReordersWithoutChangingRowIdentity'
cjpm test --filter 'tableColumnLayoutDragClampsAndCancelRestores'
cjpm test --filter 'tableColumnLayoutLeavesSortFilterAndSelectionUntouched'
cjpm test --filter 'tableDifferentColumnDefinitionsUseTheSameLayout'
```

应用集成与旧回归在示例包运行：

```sh
cd runtime/cjgui/examples/rule_set_window_app
cjpm test --filter 'tableSortKeepsStableKeysDuplicatesAndNumericOrder'
cjpm test --filter 'tableHeaderAndRowsShareColumnConstraintsAndOnlyVisibleRowsBuild'
cjpm test --filter 'tableViewAndSortKeepOwnerSelectionAndUncommittedDraft'
cjpm test --filter 'tableIdentityUsesScopedNamespacesAndStaysStableAcrossSort'
cjpm test --filter 'tableIdentityRejectsInvalidBusinessKeysExplicitly'
cjpm test --filter 'tableRowActionsComeFromCallerAndDisplayRowsStayInert'
cjpm test --filter 'tableGeometryChangesInvalidateMeasurementButPaintDoesNot'
cjpm test --filter 'tableColumnLayoutHumanAndExternalShareStateAndKeepOwnerData'
```

身份用例验证表头/行/单元格分段、排序前后行与单元格节点号不变、非法及超长 key 明确拒绝且行内容仍存在；动作用例验证调用方动作、无动作展示行和静态表头；几何用例在同一虚拟列表状态上验证 30→44 重新测量，并确认只改颜色不推进 generation。最后一个旧用例走真实 controller/owner：切表格、按名称/保留天数排序、切换视图后确认同一业务记录和未提交草稿，再由 owner 路径应用。
