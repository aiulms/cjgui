# 首版能力缺口（2026-10-22 修正版）

本文修正同日口头清单中的 6 项误判，作为派工依据。**不要按口头清单执行**，照单执行会重复建设已有能力。

误判来源：只用小写 `cjguiComposable*` 工厂名检索 `src/*.cj`，漏掉了大写 `Cjgui*` 开头的类型、`CjguiComposableUi*` 中间带 `Ui` 的类，以及 `feedback` / `field_controls` / `form_groups` / `table` / `search_panel` / `filtered_list` / `context_command_menu` 整批文件。另外用单个 consumer（`table_layout_consumer`）代替组件本体，也是错的。

## 一、已存在，直接复用，不得重建

| 能力 | 入口 | 现状与已有边界 |
| --- | --- | --- |
| 表格 | `src/composable_ui_table.cj`、`composable_ui_table_layout.cj` | 表头、列宽（min/max clamp）、对齐、排序升降与指示、列显隐、列重排、拖动调宽（复用 SPLIT_HANDLE 指针阶段）、键盘步进、`encodeState`、外部 `SET_TABLE_COLUMN_WIDTH` / `SET_TABLE_COLUMN_VISIBLE` / `MOVE_TABLE_COLUMN` / `RESET_TABLE_COLUMNS`。缺冻结列、合并单元格、横向滚动引擎 |
| 复选框 | `cjguiComposableBooleanInput`（`src/composable_ui.cj:6030`） | `semanticRole = SEMANTIC_CHECKBOX`，绘制与操作链在 |
| 数字步进 | `CjguiNumericStepper`（`src/composable_ui_field_controls.cj:152`） | 含 preset / binding / style |
| 单选组 | `CjguiChoiceGroup`（`src/composable_ui_field_controls.cj:291`） | 按钮表达选中。缺的是专用 radio 语义，不是单选功能 |
| 进度 | `CjguiProgressFeedback`（`src/composable_ui_feedback.cj:255`） | 确定进度条已实现。忙碌态现为静态文字，不是动画 |
| 状态 / 空态 / 错误态 | `CjguiStatusFeedback`、`CjguiContentFeedback`（同文件 70 / 141） | 含 spec 与 style |
| 可搜索面板 | `CjguiSearchableSelectionPanel`（`src/composable_ui_search_panel.cj:51`） | 实现虚拟列表 source |
| 筛选列表 | `CjguiComposableUiFilteredListSource`（`src/composable_ui_filtered_list.cj:30`） | 稳定 key 行 |
| 表单组与校验 | `composable_ui_form_groups.cj`、`composable_ui_form_feedback.cj` | 含 bound form groups、反馈投影、焦点解析、字段帮助 |
| 上下文命令菜单 | `CjguiContextCommandMenu`（`src/composable_ui_context_command_menu.cj:410`） | 增量投影、命令激活、锚点定位 `cjguiComposableContextMenuBounds` |
| **应用原生菜单** | `menuGroup` 声明 → `native/cjgui_internal_renderer.m:35549` | native 按 `menuGroup` 建子菜单、同步 enabled/checked、配快捷键。`autoenablesItems = NO` 只是不自动启用，**不限制应用新增菜单项** |
| 图片 | `cjguiComposableImage`、`cjguiComposableImageFromTransfer` | 生成资源目录限 PNG；普通本地图片走另一条加载路径 |
| 矢量 | `composable_vector_graphics_component.cj` | 含 cap/join/viewBox/自交/退化等 path 校验 |
| 文本滚动指示 | `node.textScrollbarRect`（`native/cjgui_internal_renderer.m:31574`） | 仅文本编辑区，2pt 指示 |
| 组合组件 | `composable_ui_composite_component.cj`、`composable_ui_component_instance.cj` | 编译期注册的 composite + 组件身份事务（begin/prepare/commit/rollback） |

布局基线另有 Vertical / Horizontal / Stack / Wrap / Grid / AspectRatio / Spacer / ScrollArea / SplitView / LayerHost / Tabs / Tree / VirtualList / VariableHeightList / Slider / Button / TextInput / MultilineTextInput / IntegerInput / Text。

## 二、真正需要新增或接入

按用户 2026-10-22 指定的三线顺序。

### Sol：普通窗口连续质量（最高优先级）

| 项 | 依据 | 算够的标准 |
| --- | --- | --- |
| 尺寸变化链长阻塞 | 取消布局最大样本 Mixed 507.438ms / 33 次、Rules 694.745ms / 71 次，发生在尺寸变化链（`artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md:1790`） | 同一负载与硬件下该链取消布局不再出现百毫秒级；给出分段耗时，不只给总数 |
| 16/32ms 门 | 未整体通过 | 声明负载下连续交互达 32ms，并向 16ms 说明差距来源 |
| 输入 / 模态返回 / 资源生命周期 | 当前仍分包交付 | 一条正常会话内输入、模态返回、外部更新、关闭可接续；资源在退出后可解释 |

**测量口径修正：** 冷首帧 GPU 36.045ms 是单次冷样本，**不能推导持续 28fps**。帧率结论必须来自连续负载分段测量，不是冷帧外推。

### DS：公共组件接入与统一 SDK

| 项 | 依据 | 算够的标准 |
| --- | --- | --- |
| Select / Dropdown | `src/*.cj` 全库零命中（仅测试里一个字符串 "Select"） | 有公共声明入口、展开态、键盘选择、选中回写、无障碍语义 |
| Tooltip | 全库零命中 | 悬停/焦点触发、延迟、边界避让，走既有 layer |
| Popover | 有 ContextMenuLayer 与锚点 bounds，缺通用锚点浮层 | 任意内容、自动翻转、箭头、外点关闭，复用既有 layer 与焦点作用域 |
| 通用滚动反馈 | 列表与 ScrollArea 无可见滚动条；文本区已有 `textScrollbarRect` 可作参考 | 可见且可拖动的滚动指示，复用文本区已有形态与指针阶段 |
| 忙碌动画指示 | 现为静态文字 | 不影响空闲 0 帧的前提下有进行中反馈 |
| Switch 外观 | 有 checkbox 语义，无独立开关外观 | 独立于 checkbox 的开关视觉与语义 |
| JPEG 公共支持 | 生成资源目录 `contentType == "PNG"`（`src/composable_ui_generated.cj:281`） | JPEG 经正式公共入口可用，不靠私有路径 |
| SVG 文件导入 | 有矢量绘制与 path 校验，无 SVG 文件解析入口 | 文件导入后走同一矢量管线 |
| 公共子集与兼容规则 | README 版本 0.0.0，全部 experimental | 划定首版公共子集、破坏性变更定义、其余标 internal；进入唯一 SDK 出口 |

### Linux：同一公共能力的第二平台消费

| 项 | 依据 | 算够的标准 |
| --- | --- | --- |
| 矢量 | macOS 683 处 / Linux 1 处 | 矢量图标可在 Linux 正常绘制 |
| 阴影 / effectGroup / effectMask | 90 / 46 / 38 处 → 0（仅注释） | 按声明子集实现，不做全量追平 |
| 无障碍 | macOS 386 / Linux 0 | 按支持子集接入，明示未实现部分 |
| 同一消费者双端 | Linux r29/r30 已到普通编辑链 | 同一应用源码在两端编译使用，差异限于宿主、系统服务、渲染、构建 |

## 三、不做进首版

DatePicker、Toast / Banner / Drawer / Accordion、完整 SVG 规范、Sidebar / Badge / Divider 单独立项（属布局与样式组合）、原生 sheet / alert（可先用自绘对话框）、Linux 全量追平。

## 四、判断口径

首版状态是：**已有相当一部分组件与底层能力，欠连续使用质量、少数常用组件的完整接入，以及一个开发者能独立使用的统一版本。**

既不是「只差承诺」，也不是「工具箱才刚开头」。凡是按组件名逐个新建之前，先在上表第一节查一遍。
