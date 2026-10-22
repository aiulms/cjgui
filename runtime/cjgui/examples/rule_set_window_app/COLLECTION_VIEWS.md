# 集合视图预设与偏好恢复

更新时间：2026-10-19。公共实现：[composable_ui_collection_view.cj](../../src/composable_ui_collection_view.cj)、[composable_ui_table_layout.cj](../../src/composable_ui_table_layout.cj)、[composable_ui_table.cj](../../src/composable_ui_table.cj)。应用接入：[main.cj](src/main.cj)、[rule_set_view_preferences.cj](src/rule_set_view_preferences.cj)。

## 公共能力

`CjguiComposableUiCollectionViewState` 是一个类型化的演示视图状态，组合现有对象而不复制它们：

- 模式 token：调用方声明 `list` / `table` 等合法值，公共层不硬编码业务组合。
- 查询：委托现有 `CjguiComposableUiFilteredListSource`。
- 排序：通过 `CjguiComposableUiTableSource.setSortState(key, ascending)` 设置明确目标，不靠重复“切换排序”。人类的表头点击仍用 `toggleSort`。
- 列布局：稳定列 key 的宽度、显隐、顺序，复用 `CjguiComposableUiTableColumnLayout`。
- 视图 revision：只随模式/查询/排序/恢复/列布局编辑推进，不是文档版本。通过公共 layout 直接改列宽/显隐/顺序的调用方，在提交后调用 `notePresentationChanged()`，让同一 revision 反映这次编辑；应用列菜单、键盘调宽和拖动已这样做。

快照格式为一行、带版本号的文本：

```
CJGUI_COLLECTION_VIEW 1 | MODE <hex> | QUERY <hex|-> | SORT <NONE | keyHex A|D> | COL <keyHex> <width> <0|1> ...
```

`CjguiComposableUiCollectionViewCodec.encodeChecked/decode` 提供往返；两者使用同一组上限：整条快照 ≤65536 B，模式/列 key ≤64 B，查询 ≤8192 B，至少一列、key 唯一、宽度非负。`decode` 对非法结构、未知版本、重复列、负宽度一律返回 `None` 和具名原因；`encodeChecked` 对同一组违规返回具名失败，`encode` 失败时抛出而不是返回不可读文本。状态对象的 `encodedSnapshotChecked()` 暴露该结果，`encodedSnapshot()` 在不可编码时返回空串。快照不包含记录、草稿、选择、pointer capture、平台节点号或拖动中间态。

### 恢复语义

`applySnapshot` / `restoreEncoded` 先完成所有校验，再一次性提交：

1. 模式必须是调用方声明的合法值，否则拒绝。
2. 快照中的未知列 key 被忽略；当前声明新增、快照缺失的列追加在末尾，使用声明默认宽度并可见。
3. 宽度 0 取声明宽度；正宽度按当前 min/max clamp。
4. 排序 key 已被删除时清除排序（结果 `sortCleared=true`）。
5. 全部列隐藏、重复 key、负宽度、非法格式或未知版本都拒绝；当前视图完全不变，不会只恢复一半。

`resetToDefault()` 恢复声明默认：默认模式、空查询、无排序、所有声明列按声明宽度可见。

## 应用预设

规则集应用在表头工具栏增加“视图预设”入口：

- 输入名称 → “保存当前视图”保存命名预设。
- 点击已有预设切换；`●` 标记当前预设。
- “恢复默认视图”恢复默认视图，保存的预设仍保留。
- “保存偏好”显式写入偏好文件。

预设与偏好属于应用，不属于记录/草稿/选择。切换预设不调用 Apply/Cancel，不改业务版本；稳定 key 选择保持，筛选隐藏选中项继续由 `hiddenCount` 报告。

### 卡片模式

本应用声明 `list` / `table` / `grid` 三种模式。`grid` 使用公共[虚拟卡片网格](../../CARD_GRID.md)：卡片复用同一规则源、同一筛选/排序顺序、同一 `CollectionSelection` 和同一草稿。工具栏“卡片视图”在 `list ↔ grid` 间切换；切到 `grid`/`table` 时若左栏过窄，沿用现有 `SET_SPLIT_SIZE` 把左栏放宽到 520（这是应用演示布局，不是网格必需条件）。

列数由左栏实际内容宽度和卡片最小宽度计算；缩窄/放宽窗口会重排，并通过现有列表 `revealKey` 重锚到改宽前顶部业务项。每张卡的稳定身份是 `instanceKey/cards/<itemKey>`，不是行/列号；`resourceId < 0` 的展示项仍会渲染。键盘左右按显示顺序、上下按当前列数移动，Shift 扩选和隐藏选中项语义继续由 `CollectionSelection` 提供。

外部客户端通过同一视图状态入口切换：

```
INVOKE <collectionViewRevision> SET_COLLECTION_VIEW_MODE 1 1
ID 8000
ARG mode STRING <bytes> <hex>     # list / table / grid
```

成功返回 `view_mode_set` 或 `view_mode_unchanged`；未知模式返回 `unknown_view_mode`，空模式返回 `invalid_view_mode`，不改变当前视图。

## 偏好文件

偏好文件与规则文件分开，默认路径：

- 有 `--open PATH` 时：`PATH.cjgui-views`
- 只有 `--save-as PATH` 时：`PATH.cjgui-views`
- 显式 `--view-preferences PATH` 优先

格式：

```
CJGUI_RULE_SET_VIEWS 1
ACTIVE <nameHex|->
VIEW <nameHex> <snapshotHex>
END
```

只有“保存偏好”动作写盘。过滤、排序、切换、拖动和每帧刷新都不写盘。写入使用同目录临时文件 + rename；读取遇到不支持版本、坏格式或非法快照时整文件拒绝并保留内存中的旧预设目录。启动时应用 `ACTIVE` 预设；旧配置里的已删除列/新列按公共恢复规则处理。

保存前先计算实际编码载荷，并按读取契约检查：载荷超过 262144 B 时明确拒绝 `view_preferences_too_large`，旧文件和 dirty 状态都保留；每个预设加入目录前也经过 `encodeChecked`，不会被保存成不可重开的内容。合法载荷保存后可被新实例读取。

偏好目标写入前还会与“当前规则文档”和“当前另存为输入路径”比较。比较在应用层使用普通相对/绝对路径归一（相对路径以当前目录为基准，存在时再 canonicalize），相同则拒绝 `view_preferences_conflicts_with_document`，规则文件与偏好文件都不变；不同路径继续正常保存。该检查在每次显式保存时读取当前路径，不依赖启动参数。这些拒绝通过现有 INVOKE 结果返回 `view_preferences_too_large`、`view_preferences_conflicts_with_document` 或 `invalid_view_snapshot`，不新增错误通道。

## 外部接口

复用现有 `GET_CONTEXT` / `INVOKE`，没有新 RPC 或授权体系。规则集资源（8000）新增字段：

- `collectionView`：当前视图的 `CJGUI_COLLECTION_VIEW 1 | ...` 文本。
- `collectionViews`：`CJGUI_COLLECTION_VIEWS 1 | ACTIVE <hex|-> | NAME <hex> ...`。
- `collectionViewRevision`：当前视图 revision，作为 `SELECT_COLLECTION_VIEW` / `RESET_COLLECTION_VIEW` 的 expected version。
- `collectionViewsRevision`：预设目录 revision，作为 `SAVE_COLLECTION_VIEW` / `SAVE_COLLECTION_VIEW_PREFERENCES` 的 expected version。
- `collectionViewDirty`：偏好是否有未保存修改。

新增动作：

```
INVOKE <collectionViewsRevision> SAVE_COLLECTION_VIEW 1 1
ID 8000
ARG name STRING <bytes> <hex>

INVOKE <collectionViewRevision> SELECT_COLLECTION_VIEW 1 1
ID 8000
ARG name STRING <bytes> <hex>

INVOKE <collectionViewRevision> RESET_COLLECTION_VIEW 1 1
ID 8000

INVOKE <collectionViewRevision> SET_COLLECTION_VIEW_MODE 1 1
ID 8000
ARG mode STRING <bytes> <hex>

INVOKE <collectionViewsRevision> SAVE_COLLECTION_VIEW_PREFERENCES 1 1
ID 8000
```

人类按钮和外部 INVOKE 都进入 `executeFromHuman` / `executeFromExternal` → `CjguiRuleSetViewStateHost.applyViewStateAction` 同一入口。目标、expected version 和失败保旧规则一致。

## 启动与验证

```zsh
cd runtime/cjgui/examples/rule_set_window_app
zsh run.sh --open /tmp/rules.json --view-preferences /tmp/rules.cjgui-views
```

就绪输出新增：

```
CJGUI_RULE_SET_READY VIEW_PREFERENCES /tmp/rules.cjgui-views
CJGUI_RULE_SET_READY VIEW_ACTIVE A
```

窗口画面、`GET_CONTEXT` 字段、以及重开后的同一预设应一致。重开只恢复已保存的视图偏好，不恢复未提交草稿。

## 边界

- 不做云同步、冻结列、多列排序、列合并或完整工作区恢复。
- 不做配置迁移框架；列声明变化只有上述忽略/追加/clamp 规则。
- 偏好文件只在本应用显式保存时写入；没有自动保存或每帧/每拖动写盘。
- 外部动作沿用现有本地 descriptor 与授权，不新增权限模型。
- 真实桌面鼠标拖列仍未在本机桌面通道复核；本轮不重新开启鼠标驱动排查。
