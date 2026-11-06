# 公共布局原语（experimental，macOS 已验证）

滚动区 `cjguiComposableScrollArea` 只接受零个或一个直接内容子节点；多项内容先
放入普通 Vertical/Horizontal，再把该容器加入 ScrollArea。多个直接子节点会使
整场候选以 `scroll_area_requires_at_most_one_child` 拒绝，保留上一 accepted 场景，
不再静默只显示第一项。viewport 由调用方持久持有，内容容器通常按自然高度测量。

本页说明手写树和运行时生成式界面共用的四个布局原语：`Stack`、横向
`Wrap`、`AspectRatio`、`Spacer`。它们由仓颉核心的
`CjguiComposableUiLayoutEngine` 统一测量、约束、布局、复用和命中，不另建
私有布局引擎，也不是 CSS/Flutter 布局体系的完整复刻。

## 最小用法

```cangjie
// 普通节点共享同一内容区；子节点用自身 alignX/alignY 定位。
let beaconCard = cjguiComposableStack(3410, "detail-beacon-card",
    CjguiComposableUiStyle(fixedWidth: 128, fixedHeight: 96, clipsContent: true))
let beaconFrame = cjguiComposableAspectRatio(3411, "detail-beacon-frame", 4, 3,
    CjguiComposableUiStyle(fixedWidth: 128, fixedHeight: 96))
beaconFrame.add(cjguiComposableImage(3412, "detail-beacon-image", beacon.rasterPath,
    CjguiComposableUiStyle(fixedWidth: 128, fixedHeight: 96),
    imageResourceId: beacon.key, imageResourceVersion: beacon.version))
beaconCard.add(beaconFrame)
beaconCard.add(cjguiComposableButton(3413, "detail-beacon-edit", "编辑", "OPEN_EDIT_DIALOG", -1,
    CjguiComposableUiStyle(fixedWidth: 44, fixedHeight: 22,
        alignX: CJGUI_COMPOSABLE_UI_ALIGN_END, alignY: CJGUI_COMPOSABLE_UI_ALIGN_START, zIndex: 2),
    operationActionName: "OPEN_EDIT_DIALOG"))

// 横向换行：按实际可用宽度断行，行高取该行最高子项。
let tags = cjguiComposableWrap(3401, "detail-tags",
    CjguiComposableUiStyle(growX: 1, gap: 6), rowGap: 4)
let tagStyle = CjguiComposableUiStyle(fixedHeight: 20, padding: 4, fontSize: 10.5)
tags.add(cjguiComposableText(3402, "detail-tag-applied", "已应用 v1", tagStyle))
tags.add(cjguiComposableText(3403, "detail-tag-draft", "草稿 v4", tagStyle))
tags.add(cjguiComposableText(3404, "detail-tag-view", "视图 list", tagStyle))

// Spacer 只包装既有 grow/min-size 分配；不引入第二套 flex 算法。
let actions = cjguiComposableHorizontal(3500, "draft-actions",
    CjguiComposableUiStyle(growX: 1, gap: 8))
actions.add(cjguiComposableSpacer(3501, "draft-actions-spacer"))
actions.add(cjguiComposableButton(3502, "draft-apply", "应用草稿", "APPLY_DRAFT", -1))
```

## 三栏工作区与剩余高度

普通容器即可组合三栏：外层纵向依次声明标题、唯一 `growY` 工作区和按需
出现的底面板；工作区横向声明左右栏与中间编辑区。以下片段中 `bodyText`、
`showBottom`、`leftViewport` 和 `rightViewport` 由应用提供；viewport 应作为
窗口的长期视图状态保存，不要在每次重建树时重置。每个节点 ID 在同一树中唯一。

```cangjie
let root = cjguiComposableVertical(100, "workspace", CjguiComposableUiStyle(gap: 8))
root.add(cjguiComposableText(101, "title", "工作区", CjguiComposableUiStyle()))

let columns = cjguiComposableHorizontal(102, "columns",
    CjguiComposableUiStyle(growX: 1, growY: 1, gap: 8))
let left = cjguiComposableScrollArea(103, "navigation", leftViewport,
    CjguiComposableUiStyle(fixedWidth: 180, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
let leftContent = cjguiComposableVertical(104, "navigation-content", CjguiComposableUiStyle(gap: 8))
leftContent.add(cjguiComposableText(105, "navigation-label", "目录", CjguiComposableUiStyle()))
left.add(leftContent)

let editor = cjguiComposableVertical(106, "editor-column",
    CjguiComposableUiStyle(growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, gap: 8))
editor.add(cjguiComposableText(107, "editor-title", "正文", CjguiComposableUiStyle()))
editor.add(cjguiComposableMultilineTextInput(108, "editor", "正文", bodyText, 108,
    CjguiComposableUiStyle(growY: 1)))

let right = cjguiComposableScrollArea(109, "inspector", rightViewport,
    CjguiComposableUiStyle(fixedWidth: 180, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
let rightContent = cjguiComposableVertical(110, "inspector-content", CjguiComposableUiStyle(gap: 8))
rightContent.add(cjguiComposableText(111, "inspector-label", "属性", CjguiComposableUiStyle()))
right.add(rightContent)
columns.add(left)
columns.add(editor)
columns.add(right)
root.add(columns)

if (showBottom) {
    let bottom = cjguiComposableVertical(112, "bottom-panel", CjguiComposableUiStyle(padding: 8))
    bottom.add(cjguiComposableText(113, "bottom-message", "消息", CjguiComposableUiStyle()))
    root.add(bottom)
}
```

把 `root` 交给正常窗口布局后，不需要用窗口高度手算编辑器高度；编辑器的
正文、写入和焦点仍由应用现有 owner 与输入路径负责。可拖动分栏时，把对应
子树交给现有 `cjguiComposableSplitView` / `cjguiComposableScopedSplitView`；
它们不是新的三栏状态机。

注意主轴与交叉轴：竖排用 `growY` 分配剩余高度，横排用 `growX` 分配剩余宽度。
横排中的侧栏要铺满高度，显式设置侧栏自己的 `alignY: STRETCH`；只写 `growY`
不能代替横排的交叉轴定位。上例三栏均已声明该伸展，容器的 align 不会自动传给孩子。

- 普通纵向容器没有内部高度覆盖、且有**恰好一个**非固定高度的 `growY` 子项时，先测量其他兄弟的
  自然高度及间距，再把剩余高度给该子项，并应用它的 `minHeight` / `maxHeight`。
  因此长编辑正文不会挤掉标题或底面板；有多个 grow 子项时仍按既有自然尺寸、
  增长和收缩规则分配，不应假定它们各占相同面积。
- `fixedWidth` / `fixedHeight` 和显式最小尺寸不会因父容器太小而被悄悄缩小；
  它们以及间距的总和超过可用区域时可能溢出。上例左右栏各 180 点，窗口太窄时
  应由应用选择最小窗口尺寸、折叠栏或其他响应式组合；不要把溢出当作已适配。
  非 stretch 的自然宽度受父宽约束，但显式固定宽和最小宽仍可能超过父宽。
- `alignX` / `alignY` 描述**节点在父区域中的位置或伸展**，不是文字在控件
  内的对齐。上例横向栏的 `alignY: STRETCH` 让它们使用行的高度。
- 滚动区使用其首个内容子树的自然高度计算滚动范围；长内容放进该子树，复用
  同一个 viewport 处理滚动与 reveal。可滚动内容超出视口是正常几何，不能仅凭
  这一事实判为布局错误。需要填充余量的编辑器应放在有确定高度的普通容器中，
  不靠滚动内容的自然高度模拟填充。
- 没有底面板时不要创建固定高度的空占位节点；需要空状态时明确声明有内容的
  空状态节点。空文本节点仍参与自己的尺寸和容器间距，不能自动视作不存在。

## 规则与约束

- **同一引擎、同一节点类型。** `Stack` 和 `AspectRatio` 使用普通
  `VERTICAL` 节点，`Wrap` 使用普通 `HORIZONTAL` 节点；布局意图记录在
  `CjguiComposableUiLayoutSpec`，不新增节点 kind、原生 ABI 或平台调用。
- **Stack**：所有普通子节点共享容器的内容矩形。先按 `stretch`、父约束和
  首选尺寸确定每个子项的实际宽度，再用该宽度测量高度，与自然高度分支
  同一口径；`alignX/alignY` 决定位置，`zIndex` 决定绘制顺序，`clipsContent`
  和既有裁剪约束照常生效，命中按现有层级规则处理。它不是模态 `LayerHost`，
  不捕获焦点或指针。
- **Wrap**：仅横向。断行条件是
  `当前行已用宽度 + gap + 子项宽度 > 可用宽度`；子项宽度来自其实际测量
  结果，行高取该行最高子项，容器高度为
  `Σ行高 + rowGap × (行数 - 1)`。测量和放置调用同一 `wrapPlan` 算法并按
  相同输入分别求值，得到一致分行；不宣称只计算一次，也不缓存该临时 plan。单个子项宽于可用宽度时钳到该行宽度并
  只测量一次。`rowGap` 为 0 时使用 `style.gap`。
- **AspectRatio**：只接受一个内容子节点。父宽可用时以宽为主；
  推导高度超过父高时改由高度约束并反推宽度；父宽不可用但父高可用时由高度
  反推宽度；两者都不可用时为 0×0，调用方应为比例框提供至少一个维度。
  无效比例（任一项 ≤ 0 或 > 1,000,000）整场拒绝为 `invalid_aspect_ratio`，
  不会以零尺寸成功。图片资源与 `fit` 沿用既有实现。
- **Spacer**：横向默认 `growX`，纵向使用 `axis! =
  CjguiComposableUiSplitAxis.VERTICAL`；`grow`/`weight` 和 `minimumSize`
  直接落到普通 grow/min-size 属性，不执行额外分配算法。
- **失效与复用**：布局模式和参数进入既有布局复用签名；宽度/比例/模式变化
  会使相关节点重新测量布局，不是只在首帧正确。
- **生成式同名消费**：公开组件名为 `stack`、`wrap`、`aspectRatio`、
  `spacer`。属性为 `wrap.rowGap`、`aspectRatio.aspectWidth/aspectHeight`、
  `spacer.axis/minimum/weight`；`stack` 复用 box 样式并发布 padding，共享
  区域不发布 `gap`。省略比例项时使用 16:9，显式 0 或超范围仍拒绝。手写和
  生成使用同一构造器和同一布局引擎。
- **候选拒绝**：生成式结构中的非法属性、未知属性、比例错误、子节点数量
  错误都走既有候选事务；拒绝时保留上一份 accepted 界面、业务身份与草稿。

## 固定与变高虚拟列表的共享视口

固定行和变高列表保留原有构造器，并提供绑定调用方
`CjguiComposableUiScrollViewport` 的 experimental overload。两个构造器的完整
参数分别为：

```cangjie
cjguiComposableVirtualList(nodeId: Int64, semanticId: String, contentNodeId: Int64,
    viewport: CjguiComposableUiScrollViewport, source: CjguiComposableUiVirtualListSource,
    state: CjguiComposableUiVirtualListState, rowHeight: Int64, rowGap: Int64,
    overscan: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true)
cjguiComposableVariableHeightList(nodeId: Int64, semanticId: String, contentNodeId: Int64,
    viewport: CjguiComposableUiScrollViewport, source: CjguiComposableUiVariableHeightListSource,
    state: CjguiComposableUiVirtualListState, estimatedRowHeight: Int64, rowGap: Int64,
    overscan: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true)
```

`viewport` 必须是同一窗口滚动区、滚动条、列表和定向 reveal 共用的那个对象；
不要从当前偏移另造第二份状态。变高列表的 `estimatedRowHeight` 只估计尚未测量
行；被显露的行走普通子树测量、布局和渲染路径。

`CjguiComposableUiWindow.revealVirtualListItem(semanticId, itemKey, viewport)`
只请求把当前列表源中稳定 key 对应的行显露。`true` 表示请求被接受，不表示该
key 已进入 accepted scene、当前可见或已呈现；窗口进度、同语义 viewport 的
accepted 偏移、accepted 行身份/几何和应用自己的 owner 读回是不同证据。公开
`GET_WINDOW_INTERACTION` 最多返回四条 `WINDOW_VIEWPORT`：其中 `offset` 是请求
偏移，`accepted` 是已接受偏移，并带 `content`、`viewport`、`pending`、`solves`；
该摘要不包含目标 key，不能只用偏移推断某行可见。

应用应先在当前筛选/排序后的活动 source 中解析稳定 key，再使用当前
`semanticId` 和同一 viewport 调用 reveal。显露本身不选择该行、不 Apply、不编辑
owner，也不推进业务版本；选择/编辑仍走已有行操作和业务 writer。未知 key、
不匹配的滚动语义或 viewport、已退役的列表句柄都应明确拒绝。消费者随后等待
实际 accepted scene，再独立确认目标行及其有效几何，才允许人继续点选或输入。

上述 overload 与 reveal 接缝仍为 experimental；当前实现与正常应用消费的最终
范围以对应源码锁和消费者结果为准，其他平台及通用可见性保证未验。

## 支持与已知边界

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| Stack 叠放、对齐、zIndex、裁剪 | experimental | macOS 已验；其他后端未验 |
| 横向 Wrap、按实际宽度换行 | experimental | macOS 已验；仅横向，不是虚拟列表替代品 |
| AspectRatio 单内容比例 | experimental | macOS 已验；仅一个内容子节点 |
| Spacer 横向/纵向剩余空间 | experimental | 复用既有 grow/min-size |
| 生成式四个组件与属性发现 | experimental | 与手写共用实现；公开目录已发布 |

手写 `AspectRatio` 由调用方保证只添加一个内容子节点（布局只使用第一个）；
生成式声明在候选校验阶段强制恰好一个子节点。无效比例、未知属性和超限属性
均由既有候选事务拒绝并保留旧界面。

未包含：纵向 Wrap、masonry、瀑布流、断点 DSL、动画系统、拖拽设计器、
完整热重载、横向虚拟化、复杂排版。布局实现按需求解，不引入每帧全量扫描或
重复测量循环；单次 GET 的 `WINDOW_MEASUREMENT_CALL_COUNT` /
`WINDOW_LAYOUT_REUSE` 只描述该次观测，不能据此推断整个空闲期间无轮询。

## 构建与运行

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
cd runtime/cjgui/examples/rule_set_window_app
cjpm build --skip-script
./target/release/bin/main --retention-range 1 100 --open <rules.json>
```

样例窗口即 `rule_set_window_app`：详情头部使用 `Wrap` 标签栏和
`Stack`/`AspectRatio` 图片卡（含真实 `OPEN_EDIT_DIALOG` 角标），草稿操作行
使用 `Spacer`。公开结构更新通过既有 `SUBMIT_GENERATED_UI` 入口提交；
`shared_operation_core/client.py` 只是脚本客户端消费，不是另一套协议。

定向测试：

```bash
cd runtime/cjgui/examples/rule_set_window_app
./target/release/unittest_bin/cjgui_rule_set_window_app --no-color \
  --filter='*wrapMeasures*,*aspectRatioHonors*,*stackShares*,*stackMeasures*,*spacerUses*,*generatedLayoutPrimitives*,*layoutSpecChanges*,*generatedLayoutVocabulary*'
```

测试覆盖：文本/按钮混排与混合宽度换行、测量与放置一致、超宽单项钳制、比例冲突/缺少父约束/非法比例、
Stack 实际宽度测量/叠放/内边距/裁剪/命中、Spacer 横向/纵向增长、布局声明变化使 keyed 复用失效、
公开目录词表/默认值/上下限一致、公开生成结构与手写共用几何、同 key 重排/更新保留
字段身份和草稿并在布局变化后继续编辑、非法候选保留上一版。

## 相关实现

- `src/composable_ui.cj`：`CjguiComposableUiLayoutSpec`、四个构造器、
  `layoutStack` / `wrapPlan` / `layoutWrap` / `aspectContentSize` /
  `layoutAspectRatio`，以及复用签名。
- `src/composable_ui_generated.cj`：生成式组件注册、属性校验和构造器映射。
- `examples/rule_set_window_app/src/main.cj`：手写消费。
- `examples/rule_set_window_app/src/rule_set_generated.cj`：公开目录注册。
- `examples/rule_set_window_app/src/layout_primitives_test.cj`：布局原语测试。
- `examples/rule_set_window_app/src/candidate_rejection_observability_test.cj`：
  公开生成结构、同 key 身份/草稿与非法候选测试。
