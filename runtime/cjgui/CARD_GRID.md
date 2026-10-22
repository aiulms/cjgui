# 公共虚拟卡片网格

更新时间：2026-10-19。实现：[composable_ui_card_grid.cj](src/composable_ui_card_grid.cj)。正常消费样例：[rule_set_window_app](examples/rule_set_window_app/src/main.cj)、[rule_set_card_grid.cj](examples/rule_set_window_app/src/rule_set_card_grid.cj)。

## 它是什么

`CjguiComposableUiCardGridSource` 是现有可变高度虚拟列表上的**适配器**，不是第二套集合、滚动器或布局引擎：

- 业务数据仍由调用方的 `CjguiComposableUiVariableHeightListSource` 提供。
- 网格把业务项按当前可用宽度排成“行”，每行再拆成固定宽度、等高卡片。
- 行通过现有 `CjguiComposableUiVariableHeightListState` 物化、滚动和揭示；只构建可见行加列表已有的有界 overscan。
- 卡片内容、动作、选中/焦点绘制由调用方通过 `buildCard` 和现有选择对象提供。
- 组件不创建业务模型、选择状态机、第二套滚动状态或图片/下载服务。

## 公共接口

```cangjie
public class CjguiComposableUiCardGridSpec {
    public init(minimumCardWidth: Int64, cardHeight: Int64,
        columnGap!: Int64 = 10, rowGap!: Int64 = 10)
}

public class CjguiComposableUiCardGridSource <: CjguiComposableUiVariableHeightListSource {
    public init(base: CjguiComposableUiVariableHeightListSource, instanceKey: String,
        spec: CjguiComposableUiCardGridSpec,
        buildCard: (VariableHeightListItem, CardGridCardContext) -> Node,
        actionOf!: ?(Item -> TableRowAction) = None,
        selectedOf!: ?(String -> Bool) = None,
        focusedKeyOf!: ?(() -> String) = None)

    public func setAvailableWidth(width: Int64): Bool
    public func columns(): Int64
    public func cardWidth(): Int64
    public func rowCount(): Int64
    public func indexForKey(key: String): Int64
    public func rowKeyForItem(itemKey: String): String
    public func lastIdentityIssue(): String
    public func identityIssueForKey(itemKey: String): String
    public func itemKeyForRowStart(rowIndex: Int64): String
}

public class CjguiComposableUiCardGridIdentity {
    public static let MAXIMUM_ITEM_KEY_BYTES: Int64 = 48
    public static let MAXIMUM_TOKEN_CHARS: Int64 = 96
    public static let ISSUE_KEY_EMPTY: String
    public static let ISSUE_KEY_TOO_LONG: String
    public static func tokenForItem(itemKey: String): ?String
    public static func issueForItem(itemKey: String): String
}

public class CjguiComposableUiCardGridNavigation {
    public static func targetKey(order: CjguiComposableUiCollectionOrder, focusKey: String,
        command: String, columns: Int64): String
}
```

`setAvailableWidth` 使用与 Flutter `SliverGridDelegateWithMaxCrossAxisExtent` 相同的横轴分配思路（仅借鉴，无依赖）：先按 `minimumCardWidth + columnGap` 求列数，再把剩余宽度均分；宽度不足一张卡时退化为 1 列。只在列数或卡宽实际变化时返回 `true` 并推进测量代。

`indexForKey` **只解析内部行 key**，供虚拟列表的 live-key 检查使用；业务 key 不传给这个入口。`rowKeyForItem` 直接从 base source 的 `indexForKey` 查业务位置，再按当前列数计算行，**不调用网格的 `indexForKey`**。因此业务 key 即使字符串恰好等于某个内部行 key（例如 `cjgui.grid.<instance>.row.1`），仍按 base 位置映射，不会被行号语法截走。

`CardGridCardContext` 提供：

| 字段 | 含义 |
| --- | --- |
| `key` / `resourceId` | 原业务项身份，不是行/列号 |
| `cardWidth` / `cardHeight` / `columns` | 本帧几何 |
| `rowIndex` / `columnIndex` | 仅用于布局/调试，不作为身份 |
| `selected` / `focused` | 由 `selectedOf` / `focusedKeyOf` 投影；调用方也可在卡片内使用同一业务选择 |
| `identity` | `instanceKey/cards/<稳定 itemKey token>`，列数变化时保持 |
| `actionName` / `actionResourceId` | `actionOf` 返回的既有动作；空/-1 为纯展示 |

## 使用示例

```cangjie
let grid = CjguiComposableUiCardGridSource(tableSource, "rule-set-cards",
    CjguiComposableUiCardGridSpec(190, 118, columnGap: 10, rowGap: 10),
    { item, context => renderCard(item, context) },
    actionOf: { item => TableRowAction("SELECT_RECORD", item.resourceId) },
    selectedOf: { key => selection.isSelected(key) },
    focusedKeyOf: { => selection.focus() })

let state = CjguiComposableUiVirtualListState()
let _ = grid.setAvailableWidth(contentWidth)
let node = cjguiComposableVariableHeightList(21, "card-scroll", 22,
    grid, state, grid.spec().cardHeight, grid.spec().rowGap, 2,
    CjguiComposableUiStyle(growX: 1))
```

卡片子树应使用 `context.identity.local(...)`（例如 `slot`、`title`、`action`），不要用 `rowIndex/columnIndex` 拼身份。

## 身份编码与长度限制

卡片身份仍由既有 `CjguiComposableUiIdentityScope` 解析：`instanceKey/cards/<hex itemKey>`。hex 是可逆编码，不使用 `hashCode`，因此不同业务 key 不会因哈希碰撞得到同一身份。IdentityScope 的单个 segment 上限是 96 个 ASCII 字符，hex 每字节占 2 字符，所以：

- 业务 key 的 UTF-8 长度 ≤48 字节：接受，token 长度 ≤96。
- 空 key：`tokenForItem` 返回 `None`；`buildRow` 按缺失槽位处理，不建立业务身份。
- >48 字节：`tokenForItem` 返回 `None`，`issueForItem` / `identityIssueForKey` 返回 `card_grid_identity_key_too_long`；`buildRow` 不构建该卡片，保持矩形空槽，并把原因写入 `lastIdentityIssue()`。

调用方应在数据入口用 `identityIssueForKey` 预检并拒绝超长 key；不要截短或哈希业务 key，以免改变业务身份。公共层不建立哈希身份、身份分配器或第二套 key 映射。超长 key 的槽位携带**无效身份**，由既有 `CjguiComposableUiIdentityRegistry.resolveCandidate` 拒绝整个候选，上一份 accepted 界面保持不变；不会用合法空槽伪装成功。

## 重排锚点

列数变化时，阅读位置由调用方在**改宽前**取当前物化起始行的业务 key，改宽后用 `rowKeyForItem` 映射到新行，再交给现有 `revealKey`：

```cangjie
let anchor = grid.itemKeyForRowStart(state.materializedStart())
if (grid.setAvailableWidth(newWidth)) {
    let rowKey = grid.rowKeyForItem(anchor)
    if (rowKey.size > 0) {
        let _ = state.revealKey(grid, rowKey)
    }
}
```

`rowKeyForItem` 是必须的：虚拟列表的 live-key 检查比较 `itemAt(index).key`，而网格的 `itemAt` 暴露的是行 key。业务 key 仍用于选择、动作和卡片身份，只在交给列表状态揭示/聚焦时映射成当前行 key。这样不建立第二套滚动权威，也不把行号变成身份。

## 键盘与多选

- 显示顺序来自现有 `CjguiComposableUiFilteredListSource` / `CjguiComposableUiTableSource` 投影。
- 左右移动按当前显示顺序 ±1；上下按**当前列数** ±columns；Shift 扩选仍交给 `CjguiComposableUiCollectionSelection.moveFocus(target, true, order)`。
- 目标业务 key 映射为 `rowKeyForItem(target)` 后设置列表焦点并 `revealKey`；屏幕外目标会被现有列表滚入视口。
- 筛选隐藏的选中项保留在 `CollectionSelection`，由现有 `hiddenCount(order)` 报告；网格不额外清理。

## 边界

- 等高卡片；不做瀑布流、卡片拖拽排序、图片下载/缩略图服务。
- 不做第二套滚动容器、布局引擎或选择状态机。
- 不横向虚拟化；卡片宽度受内容宽度约束，超长内容由卡片自身截断/省略。
- 卡片数超过可视范围时只物化可见行加列表 overscan，不能把“所有数据节点都建树”当成卡片网格。
- 业务 key 的卡片身份编码上限为 48 UTF-8 字节；超长 key 明确拒绝，不哈希、不自动分配替代身份。
- 不同业务内容可复用本组件；规则集应用只是一个正常消费者。
