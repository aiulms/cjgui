# 公共集合多选（CjguiComposableUiCollectionSelection）

公共实现：[composable_ui_collection_selection.cj](../../src/composable_ui_collection_selection.cj)。树、平面列表和表格共用这一份稳定 key 选择内核；树只保留展开/父子导航适配，平面视图不伪造业务树。

选择模块只保存稳定 key、焦点、锚点、版本，不做业务写入。记录、草稿、批量事务仍由应用 owner 负责。

## 类型

| 类型 | 作用 |
| --- | --- |
| `CjguiComposableUiCollectionOrder` | 当前视图顺序：`count`、`keyAt`、`indexOfKey`、`isSelectableAt`。实现方每次从权威投影回答，选择模块不缓存显示行号。 |
| `CjguiComposableUiFlatCollectionOrder` | 把既有 `CjguiComposableUiVariableHeightListSource` 适配成顺序；`selectable` 谓词由调用方给出。 |
| `CjguiComposableUiCollectionSelection` | 多选、焦点、锚点、范围操作与版本。列表和表格必须共享同一个实例。 |
| `CjguiComposableUiCollectionSelectionSnapshot` | `keys/focus/anchor/selectionVersion/viewVersion` 的只读快照。 |
| `CjguiComposableUiCollectionNavigationResult` | 键盘导航是否改变了选择及新的焦点 key。 |

## 最短用法

```cangjie
// 一次创建，列表与表格共用。
let selection = CjguiComposableUiCollectionSelection()

// 每个视图把自己的当前顺序适配进来；谓词决定哪些行可选。
let listOrder = CjguiComposableUiFlatCollectionOrder(filteredListSource,
    { item => item.resourceId >= 0 })
let tableOrder = CjguiComposableUiFlatCollectionOrder(tableSource,
    { item => item.resourceId >= 0 })

// 行点击：单击替换，Command 增减，Shift 按当前顺序扩选。
// 修饰键取真实激活事件（ACTIVATE，27）的 flags；鼠标按下先到的
// FOCUS（31）不带修饰键，不能在那里结算第二次点击。
selection.click(item.key, commandPressed, shiftPressed, currentOrder)

// 键盘：up/down/page_up/page_down/home/end/select_all。
let _ = selection.navigate(command, shiftPressed, currentOrder)

// 全选当前顺序（包含屏幕外行），不预建屏幕外 UI。
selection.selectAll(currentOrder)
selection.clearSelection()

// 筛选/排序/换视图后，把焦点修到当前顺序里；选中 key 不动。
let _ = selection.ensureFocusInOrder(currentOrder)

// 对外快照。
let snapshot = selection.snapshot(viewVersion)
let hidden = selection.hiddenCount(currentOrder)
```

## 选择语义

- **身份只有稳定 key。** 显示位置、排序位置、过滤位置都不进入选择状态；排序或列表/表格切换后，选中的业务 key 原样保留。
- **范围永远按当前顺序解释。** Shift+点击、Shift+上下键、Home/End 都读取调用方本次传入的 order。正向和反向区间都取闭区间。
- **隐藏锚点有明确回退。** 锚点不在当前顺序时，点击或键盘扩选从本次手势目标重新开始并重置锚点，不沿用旧显示行号。键盘首次扩选从当前焦点开始。
- **隐藏与删除分开。**
  - `hiddenCount(order)` 只统计被当前筛选/排序投影暂时隐藏的已选 key。
  - `pruneToEligible(keys)` 只在记录真的消失或失去选择资格时移除 key；筛选隐藏的 key 保留。
  - 实验重载 `pruneToEligible(originalOrder)` 接收同一原始、未筛选的资格顺序，只扫描到选择／焦点／锚点已全部找到的位置；无待维护 key 时不读记录，缺失 key 最多扫描全部。其最坏成本仍为 O(n)，原数组重载保持兼容。不能传入当前过滤顺序来删除隐藏选择。规则集消费者复用原始列表源，不复制记录或资格状态。
  - `prune(existingKeys)` 用于“逻辑存在集”，`pruneToSelectable(order)` 用于“只允许当前物化行”的消费方。无变化时版本不前进。
- **焦点修复不改变选择。** `ensureFocusInOrder` 优先保留原焦点；不可见时退回仍可用的锚点，再退回第一条可选行。隐藏的选中 key 不会被顺带清掉。
- **全选覆盖整个当前顺序。** `selectAll` 遍历 order 的 `count`，跳过不可选行；它不要求屏幕外行有节点身份，也不构建屏幕外 UI。
- **版本。** 每次选择、清除、范围或导航命令都会推进 `selectionVersion`；`ensureFocusInOrder` 和 `prune*` 在确实没有变化时不推进。`viewVersion` 是调用方传入的当前投影修订，用于说明快照是在哪份投影上取得的；它必须覆盖数据、筛选、排序和视图顺序变化。`rule_set` 直接复用既有控制器场景修订 `uiSceneVersion()`，不用 `domain.version()` 冒充投影版本。

## rule_set 接入

- `main.cj` 创建唯一的 `collectionSelection`，过滤后的列表源和表格源分别包装成 `CjguiComposableUiFlatCollectionOrder`，用 `currentCollectionOrder()` 在两种视图间切换。
- 列表行高亮由共享选择提供，虚拟列表原来的单 key 高亮只在没有集合选择时使用；表格通过调用方提供的 `rowSelected` 谓词绘制多行高亮。
- 批量入口按选中 key 解析 `rule_<id>`，一次调用既有 `BATCH_SET_ENABLED`，由 owner 校验版本、授权、草稿冲突和事务；UI 不逐行写。
- 批量前界面显示“已选 N 项，其中隐藏 M 项”；隐藏的选中记录同样在本次事务目标内。
- 详情面板继续显示 owner 的活动记录；选择、筛选、排序、换视图都不自动应用或丢弃该记录的草稿。
- 树形面板通过既有 `CjguiSharedOperationTreeSelectionProvider` 暴露选择：`rule_*` key 路由到集合选择，树 key 仍走原树选择；没有新增 RPC 或第二份业务存储。外部选择命令只有在成功后才会把集合设为当前表面；过期版本、未知 key 或未知命令被拒时，原选择、原表面及后续无 key 命令的路由保持不变。

## 稳定性与边界

- 这是随 CJGUI 源码演进的公共 API，当前没有独立版本号。选择语义、快照字段和 order 契约按本文件描述使用；`advanceSelectionVersion`、`setFocusWithoutVersionChange` 是包内辅助，不属于对外契约。
- 选择模块不解析资源 id、不读写记录、不生成节点身份、不拥有草稿。业务对象解析和批量事务必须留在 owner。
- 一次 range 只遍历当前 order 的可选区间；`selectAll` 只遍历 order 的 `count`。两者都不要求 UI 物化屏幕外行，但调用方要保证 `count/keyAt/isSelectableAt` 来自权威投影。
- 未覆盖：跨多个 owner 文档的选择合并、拖拽选择、多列排序后的选择组、持久化选择集。当前快照是内存事实，不写入文档。
