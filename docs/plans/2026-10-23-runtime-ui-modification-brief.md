# 运行时修改 UI：现状、改不了的六类边界、待调研问题

> **2026-10-23 指导复核：本页保留为问题材料，不是执行指令或新的架构硬边界。** 64实例限制与生成 split 缺轴已核实；“64不能提高就放弃整窗”“未注册必属权限”“人的意图普遍高于AI”“更换key必然丢业务草稿”等推论不能作为结论。region结构查询不等于全部业务上下文查询，缺少专用候选校验回调也不等于应用无法通过公开 provider 介入。后文八问及“硬边界”中的方案假设不覆盖[项目方向](../core/GUI_PROJECT_DIRECTION.md)；按[最新运行时迭代校准](2026-09-26-framework-capability-roadmap.md#runtime-ui-iteration-20261023)判断真实缺口与投入，不自动启动八项调研。

> 收件人：开发 AI。本文自包含，不需要读其他对话或文档。
> 任务性质：**调研与方案评估，不要求写实现代码。**
> 代码基线：`runtime/cjgui`，2026-10-23 工作区。

---

## 0. 一句话背景

CJGUI 是用仓颉写的自绘 GUI 框架（共同层约 302K 行 + 四个平台后端：macOS 5.6 万 / OHOS 2.6 万 / Windows 2 万 / Linux 2 万）。

它与主流 UI 框架的核心差异只有一条：**应用在运行期可以接受一份外部提交的界面结构**，经过校验、进候选槽、按身份对账、最后接受或整份拒绝。提交方可以是 AI，也可以是任何外部系统。提交不需要模拟鼠标或键盘事件。

由此产生一个产品设想，也是本文要调研的命题：

> 用户对着一个正在运行的应用说「把左边的导航栏挪到右边」，AI 改完，界面变了，而用户的焦点、未提交的草稿、滚动位置都还在。同时有些东西不该被改。

---

## 1. 现状：一次修改要走完的六步

| 步骤 | 入口 | 实际行为 |
|---|---|---|
| 1. 读能力 | `GET_GENERATED_UI_CAPABILITIES` | 纯文本行协议。`SURFACE` / `BOUNDS` / `COMPONENT` / `PROPERTY` / `FIELD` / `ACTION` / `COMPOSITE` / `IMAGE_RESOURCE` / `SUPPORT`。由 `CjguiGeneratedUiCapabilityCatalog` 编码，`composable_ui_generated.cj:5960+` |
| 2. 提交 | `SUBMIT_GENERATED_UI <base_version>` | `GENERATED_UI_STRUCTURE 1` + `NODE <depth> <key> <kind> [field=] [action=]` + `PROPERTY <depth> <key> <name> <value>` + `END` |
| 3. 校验 | `CjguiGeneratedUiValidator`，`composable_ui_generated.cj:1878-2417` | 38 条以上具名拒绝：`unknown_component` / `unknown_property` / `duplicate_key` / `max_depth_exceeded` / `split_requires_two_children` / `tabs_require_two_or_three_pages` / `nested_scroll_not_supported` / `semantic_parent_cycle` / `field_binding_required` / `field_editor_kind_mismatch` / `action_not_allowed` 等 |
| 4. 候选槽 | `CjguiGeneratedUiStructureHolder` | `accepted` 与 `candidate` 双槽。候选**物理不可见**，界面一像素不变，直到窗口 `commitCandidateRefresh` |
| 5. 按 key 对账 | `component_instance.commitTransaction()`，`composable_ui_component_instance.cj:250` | 集合差：新结构里没有的旧 key → `destroy()`；同 key 保留实例。`nodeIdForKey` 的用途注释写明：保住同一身份才能让 focus/selection/drafts 继续 |
| 6. 观察 | 六分区 `FIELDS/STRUCTURE/INSTANCES/STYLES/EFFECTS/PLATFORM` + 十余个 revision | 光标不符回 `SNAPSHOT_REVISION_CHANGED`，调用方只重读变化的那一节 |

### 关键：按 key 对账，位置无关

`NODE` 行的第一个数字是**缩进层级（depth），不是索引**。兄弟节点谁先谁后，由**行的出现顺序**决定。

因此「把导航栏挪到右边」在协议层的行为是：**把两棵子树的 NODE 行块前后对调，depth 保持不变。** key 全不变 → 实例全部保留 → 人的状态延续。

这一条说明：**换边这件事本身，现有协议已经支持，不需要新语法。**

### 关键：生成式是「区域」级，不是「窗口」级

```cangjie
// examples/generated_collection/src/main.cj:240-283（结构示意）
panels.add(view)      // view  = region.buildNode()   ← AI 能改的范围到此为止
panels.add(detail)    // detail = 手写的详情栏         ← AI 看不到
root.add(panels)      // 手写代码决定这两个怎么摆       ← AI 看不到
```

- 区域类型：`CjguiGeneratedUiWindowRegion(catalog, binding, rootScopeName)`，`composable_ui_generated_region.cj:31`
- 产出节点：`buildNode(feedback!)`，`:135`
- 结构序列化范围：`acceptedStructurePayload()` → `holder.acceptedStructure()`，`:573`，**只覆盖该 region 内部**
- 提交入口：`submitStructure(candidatePayload, expectedVersion)`，`:611`
- 初始结构：应用硬编码一份文本常量，启动时提交一次。见 `examples/generated_panel_consumer/src/main.cj:735`
- 一个窗口可以挂多个 region（不同 `rootScopeName` 即不同身份域）

**结论：AI 的视野和权限都止于 region 边界。窗口骨架、区域之间的排布、原生视图层，全部在它看不到也写不到的地方。**

---

## 2. 当前的真实尺寸（数字与直觉不符，必须先看）

| 项目 | 实际值 | 位置 |
|---|---|---|
| catalog 默认限额 | depth 12 / nodes **512** / props 8 / string 256 | `composable_ui_generated.cj:903` 构造默认参数 |
| **实际生效的节点上限** | **64** | `:925` 把 `maxNodes` 夹到 `CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY`（`:152` = 64）；`:1918` 另有一道独立检查 |
| decode 硬顶（框架兜底） | depth 32 / nodes 4096 / props 32 / string 4096 / 256 KiB | `:5909-5913` |
| AI 实际看到的 BOUNDS 行 | `BOUNDS 12 64 8 256` | `:5968` 由 catalog 字段拼出 |

**注意这条：消费者尝试过调大（`maxNodes: 128` / `96` / `80`），全部被夹到 64。**

后果：一个带左侧导航（6 项）+ 会话列表 + 消息流的界面，**装不进一个 region**。这是「整窗交给 AI」当前最硬的物理障碍，不是设计取舍。

---

## 3. 「改不了」分六类 —— 本文核心

产品侧的说法是「有些能改，有些应该改不了」。这句话在工程上必须拆开，因为六类的原因完全不同，**混淆会导致做错决定**：把该补的当成不该做，或把不该动的当成缺口去补。

| # | 类别 | 现象 | 拒绝方式 | 判断 |
|---|---|---|---|---|
| 1 | **权限外** | 应用没注册这个组件 / 没声明这个属性 / 值不在枚举内 | `unknown_component` / `unknown_property` / 值域拒绝 | **设计**。这是应用主动设的墙，不该绕过 |
| 2 | **数据外** | AI 能说「这里有个输入框」，不能说「框里写着 2000 字」 | `field_binding_required` / `field_editor_kind_mismatch` / `field_not_allowed` | **架构**。业务值在 owner，结构里只有 `fieldId` 引用。改了这条整套机制就散了 |
| 3 | **表达外** | 分栏不能改成上下；区域之间不能重排；不能直接写坐标 | 协议里没有这个词（无拒绝，因为写不出来） | **缺口**。可以补，属于能力面 |
| 4 | **能力外** | 声明合法，但后端画不出（Linux 无 shadow / effectMask / effectGroup / vector） | `SUPPORT state=unavailable\|fallback\|unverified` | **平台债**。按平台补，不是协议问题 |
| 5 | **语义外** | 改 key 名不等于改名，等于删除+新建（丢焦点/草稿/滚动）；语义父子成环；split 不是正好 2 子 | 对账行为 + `semantic_parent_cycle` / `split_requires_two_children` | **正确性**。不该动，动了系统会撒谎 |
| 6 | **范围外** | 看不到自己 region 之外：手写骨架、别的 region、原生视图层 | 无拒绝，因为读不到 | **设计**。但可讨论是否要扩 |

### 第 3 类里已经查明的具体项

- **分栏方向写死**：生成式 `split` 渲染时传死 `CjguiComposableUiSplitAxis.HORIZONTAL`（`composable_ui_generated.cj:4239`），属性表 `splitContentProperties()` 只有 `firstSize / firstMinimum / secondMinimum`（`:387`），**没有 axis**。
  手写侧的 `cjguiComposableScopedSplitView(..., axis, ...)`（`composable_ui.cj:5786`）**是有 axis 的**。能力在，只是没暴露给生成式。
- **区域之间的排布是手写代码**：这正是「导航栏换边」落在的那一层。

---

## 4. 待调研的八个问题

每条请给出：现状确认 / 可选方案 / 代价 / 建议（做 / 不做 / 待定），并标明依据的代码位置。**不要写实现代码。**

### Q1 区域之间的排布能否变成可提交的结构
设想是「布局壳 + 插槽」两级结构：一个很薄的 region 只放插槽，插槽按顺序决定各内容区的相对位置；每个内容区各自一个独立 region。
「挪到右边」就变成改布局壳里插槽的顺序，而不是重写整棵内容树。
- 调研点：现在 region 能否嵌套（一个 region 的节点里 add 另一个 region 的 `buildNode()`）？节点树层面显然可以，但**声明层没有「插槽」这个概念**——AI 提交的结构里无法引用另一个 region。
- 需要评估：加一个插槽 kind 的代价；插槽的 key 与对账、与四类视图状态（scroll/split/tabs）如何共存。

### Q2 64 节点上限能否提高，代价是什么
`maxNodes` 被夹在 `CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY = 64`，注释给的理由是「一个节点一个组件实例，受 per-controller registry 限制；报更大的界等于承诺一个必然失败的尺寸」。
- 调研点：这个 registry 容量是数组大小还是逻辑上限？提到 512 会引入什么（内存、每帧遍历、对账复杂度）？
- 这一条直接决定「整窗交给 AI」是否可能。**如果 64 提不上去，整窗路线应当直接放弃，只做区域级。**

### Q3 生成式 split 是否该暴露 axis
成本看起来很小（加一个 `values=["horizontal","vertical"]` 属性 + 渲染分支）。要评估的是：换轴之后 `firstSize` 的语义（现在按主轴长度解释）、`splitState` 的兼容、以及是否会出现「横竖切换后人的拖动值无意义」。

### Q4 是否需要节点级 freeze，而非只有属性级白名单
现在的粒度是「注册了就能改，没注册整个改不了」。产品真正想要的可能是「这个节点可以挪、可以调宽，但文字和动作不许换」。
- 调研点：现有 `CjguiGeneratedUiPropertySpec.stability`（如 `experimental`）能否承担这个语义，还是它只用于能力披露？
- 是否需要一个独立的「不可变节点」标记，与能力目录分开（因为能力目录是全局的，freeze 是逐节点/逐区域的）。

### Q5 应用侧是否需要候选校验钩子
目前应用**没有**介入候选校验的位置。`CjguiGeneratedUiRegionBinding`（`composable_ui_generated_region.cj:14`）只有 `ownerRevision / applyFieldIntent / appliedBoolean / draftSource` 四个方法，全与字段读写有关。
框架的 38 条校验能挡「非法」，挡不住「合法但业务上不该这么改」（例如把付费墙移出首屏、把确认按钮藏起来）。
- 调研点：加一个应用侧钩子的位置在哪（decode 后 / 校验后 / 提交前）？钩子能返回什么（拒绝 + 原因码，还是改写候选）？如果允许改写，"AI 提交了什么"与"被接受了什么"之间会不会失去可追溯性？

### Q6 是否需要比「整树重写」更小的改动单位
现在只有「整棵树重写」或「不动」，没有「把这棵子树移到那个位置」。
对 AI 的负担是实打实的：挪一个导航栏要重算整棵树几百行文本，一个字错整份被拒（好在是整份，不会改坏一半）。
- 调研点：加局部操作（move / reparent / reorder）与现有「整树提交 + 乐观并发 + 整份拒绝」的事务语义是否冲突？如果局部操作也要先合成一份完整结构再校验，收益还剩多少？

### Q7 AI 是否需要看到区域之外的布局
现在 `acceptedStructurePayload()` 只序列化 region 内部。如果用户说「把导航栏挪到右边」而这个导航栏在 region 外，AI 根本无法定位。
- 调研点：是否可以只读地暴露外层骨架（脱敏后的结构摘要，不含手写节点的业务细节）？还是应该让「可改范围」和「可见范围」严格一致（看不到就不去想）？
- 后者更保守，但要评估：AI 在视野受限时，会不会更容易给出错误的定位判断。

### Q8 人的意图与 AI 的声明冲突时，谁赢
已有一个明确的设计：`splitState` 按 key 存在窗口实例上，注释写死「instance's OWN view state wins over the declaration, so a human drag is never reset by re-submitting the same structure」。
后果：人拖过分隔条之后，AI 提交的 `firstSize` 会被人的值压过去。换边成功了，但宽度不是 AI 算的那个。
- 调研点：这个默认是否正确？是否需要「本次提交覆盖人的视图状态」的显式声明（谁有权、如何避免来回打）？
- 注意：这不是 bug，是「人的手比 AI 的声明更权威」在起作用。要评估的是**是否需要例外通道**，以及例外会不会破坏「重提交不重置人状态」这条保证。

---

## 5. 硬边界（调研时不得越过）

1. **不改业务写入路径**。生成结构里不许出现业务值，只允许 `fieldId` / `actionName` 引用。这是「人机同源写入」的地基。
2. **不动整份拒绝的事务语义**。候选要么全接受，要么整份丢弃；不接受「部分生效」。
3. **不动按 key 对账**。key 是身份，不是标签。改名等于删除+新建，这个语义不能软化。
4. **不引入 HTML / Web 引擎**。这条路线已经在别处讨论过，与本次调研无关。
5. **不为「整窗交给 AI」而让应用改用文本协议写界面**。若 Q2 结论是 64 提不上去，直接给「区域级是终局」的结论，不要硬凑方案。
6. **不新增治理文档**。输出一份调研结论即可。

---

## 6. 已经存在的能力，不得当成缺口上报

这一节是为了防止重复建设。以下全部已有实现，请先读代码再判断：

| 能力 | 位置 |
|---|---|
| 表格（表头 / 列宽 clamp / 排序 / 列显隐 / 重排 / 拖动调宽 / 键盘步进 / encodeState） | `src/composable_ui_table.cj`、`examples/rule_set_window_app/TABLE_COMPONENT.md` |
| 复选框语义 | `BooleanInput`，`src/composable_ui.cj:6030` |
| 进度条与忙碌反馈 | `CjguiProgressFeedback`，`src/composable_ui_feedback.cj:255` |
| 单选组 | `CjguiChoiceGroup`，`src/composable_ui_field_controls.cj:291` |
| 应用自定义原生菜单 | `menuGroup` → native 建子菜单并同步 enabled/checked，`native/cjgui_internal_renderer.m:35549` |
| 可搜索面板 / 过滤列表 / 表单组 / 上下文命令菜单 | `src/composable_ui_search_panel.cj`、`composable_ui_filtered_list.cj`、`composable_ui_form_groups.cj`、`composable_ui_context_command_menu.cj` |
| 锚点浮层（有 layer，缺通用 Popover 入口） | `CjguiComposableLayerHost` / `DialogLayer` / `ContextMenuLayer` |
| 文本编辑区滚动指示 | `node.textScrollbarRect`，`native/cjgui_internal_renderer.m:31574` |
| 矢量 / 阴影 / 渐变 / effectMask / effectGroup（macOS） | `native/cjgui_internal_renderer.m`，命中数分别 683 / 90 / 58 / 38 / 46 |

**检索提示（这一点很关键，之前已犯过两次错）**：本仓库组件命名有两种前缀——`cjguiComposable*`（小写 c 开头）与 `Cjgui*`（大写的类，如 `CjguiComposableUiTableSource`）。
只搜小写前缀会漏掉一半组件。正确顺序是：先 `ls src/` 看组件相关文件名（`table` / `feedback` / `field_controls` / `form_groups` / `search_panel` / `filtered_list` 都在），再按 `CJGUI_COMPOSABLE_UI_*` 节点类型常量与 `public class Cjgui*` 双前缀清点。

---

## 7. 期望输出

一份调研结论，按 Q1–Q8 逐条回答，每条包含：

1. **现状确认**：代码事实，带文件与行号。凡与本文所述不一致，以代码为准并明确指出。
2. **可选方案**：至少两个，含「不做什么」这个选项。
3. **代价**：改动面（哪些文件/层）、对现有事务语义的影响、对已有消费者的兼容性。
4. **建议**：做 / 不做 / 待定，并给出理由。

最后加一节**总体判断**，回答一个问题：

> 在现有机制上，要支持「用户对运行中的应用说一句话就改变布局，并且改不坏」，最小的一组改动是什么？如果最小改动集仍然不可接受，明确说明这条路应该停在区域级。

不要写实现代码。不要新增文档以外的文件。
