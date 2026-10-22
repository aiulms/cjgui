# 公共布局原语（experimental，macOS 已验证）

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
