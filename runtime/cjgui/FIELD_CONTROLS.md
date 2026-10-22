# 公共字段控件与状态反馈（experimental，macOS 已验证）

本页说明普通应用可直接复用的数值步进、单选组、状态消息、内容状态和
进度投影。它们由现有可组合节点、布局、稳定身份、交互样式和动作通道组成；
不新增原生控件、定时器、轮询线程或第二套业务状态。

## 数值步进

公共实现位于 `src/composable_ui_field_controls.cj`：

- `CjguiNumericStepper.resolve(currentText, direction, minimum, maximum, step)`
  是唯一的步进值判断；`CjguiSharedNumericStep` 提供同一纯函数给应用 owner。
- `CjguiNumericStepper.build(binding, presets:, style:)` 生成整数输入、减/加
  按钮和可选预设按钮。输入使用既有 `cjguiComposableIntegerInput`，按钮使用
  既有动作/owner 通道。
- `CjguiNumericStepperBinding` 携带所有节点 ID、标签、当前值、上下限、步长、
  writer、绑定资源和 owner 目标；`CjguiNumericStepperPreset` 携带预设
  key/节点/标签/值/动作。
- 非法当前值、非法 step、低于下限、高于上限和目标越过 Int64 表示范围都返回
  明确 issue；`step_overflow` 保留当前文本，不做饱和后成功。边界点击会交给
  owner 拒绝并显示反馈，或由调用方在步进前自行处理。
- `enabled`/`readOnly`/owner 缺失会禁用输入或按钮；组件不自行保存值。

最小用法：

```cangjie
let binding = CjguiNumericStepperBinding(
    rootNodeId, "retention-stepper", rowNodeId, presetsNodeId,
    inputNodeId, "retention-input", downNodeId, "retention-down",
    upNodeId, "retention-up", "保留天数", draft, 1, 100, 1,
    "retentionCount", "EDIT_DRAFT_TEXT", fieldResourceId, recordId,
    "STEP_RETENTION_DOWN", "STEP_RETENTION_UP")
let preset = CjguiNumericStepperPreset("max", presetNodeId, "设为 100", "100",
    actionName: "APPLY_RETENTION_PRESET", writerOperation: "EDIT_DRAFT_TEXT",
    bindingResourceId: fieldResourceId, ownerTargetResourceId: recordId)
let node = CjguiNumericStepper.build(binding,
    presets: ArrayList<CjguiNumericStepperPreset>([preset]))
```

规则集在标准/紧凑详情和编辑对话框都消费这个构建器；生成式的
`retentionIntegerEdit` 也由同一个构建器装配。减/加动作由应用 owner 读取当前
草稿，经 `CjguiSharedNumericStep` 解析后调用既有 draft writer，不保存第二份值。

## 单选组

公共实现位于同一文件：

- `CjguiChoiceOption` 有稳定 `key`、显示 `label`、业务 `value`、动作名和可选
  writer/owner 绑定；`CjguiChoiceGroup.issue` 拒绝空 key/label/value、重复 key
  和重复 value。
- `CjguiChoiceGroup.build(...)` 按 `value` 选择当前项，不按数组下标；重排后
  选择和身份保持。当前值不存在时显示明确的“未匹配选项：<值>”，不会自动
  写第一项。禁用项不可操作，选中项使用既有 `ownerInteractionState: SELECTED`
  和 interaction paint。
- 选项按 `key` 生成稳定语义 ID；调用方提供稳定节点 ID。生成式复合组件通过
  声明动作元素复用同一构建器。

规则集用详情布局的“标准/紧凑”作为真实单选消费者；生成式的
`detailLayoutChoice` 使用同一实现。

## 状态消息、内容状态与进度

公共实现位于 `src/composable_ui_feedback.cj`：

- `CjguiStatusFeedback.buildMessage(...)` 支持 `info`、`success`、`warning`、
  `error`，始终带文本 kind 标记（如 `[错误]`），不只靠颜色。可选动作按钮只
  调用调用方声明的动作，组件不重试业务。正文默认按实际宽度自然测高，长文案
  会换行；调用方显式设置 `fixedHeight` 时仍使用固定高度。
- `CjguiContentFeedback.build(...)` 支持 loading/empty/error/ready；empty 通过
  `CJGUI_EMPTY_NO_DATA` 与 `CJGUI_EMPTY_NO_MATCH` 区分“没有数据”和
  “筛选没有结果”。builder 只生成投影，是否替换或保留旧内容由调用方决定；
  它不清选择、草稿，也不发起请求。ready 由调用方放置真实内容。标题和详情默认
  也按实际宽度自然测高，显式固定高度仍生效。
- `CjguiProgressFeedback.build(...)` 支持确定进度和静态忙碌状态。确定进度需要
  调用方给出 value/total/trackWidth；非法值显示明确 issue，不伪造百分比或完成
  状态。0% 的填充是零宽，`0 < value < total` 但整数比例不足 1pt 时显示 1pt；
  `trackWidth * value` 的中间乘法溢出使用宽整数求精确比例，合法大值不会崩溃或
  画错。忙碌状态只是文字投影，不创建定时器或动画；不新增 native 渲染类型。
- 生成式复合组件 `ruleStatus`、`ruleContentState`、`ruleProgress` 使用相同
  builder；属性分别为 kind/text、kind/emptyReason/title/detail、
  busy/value/total/label/trackWidth。外部结构提交只声明状态数据，不是任务完成
  通知。

规则集详情状态和空结果使用这些组件；空结果筛选状态带“清除筛选”动作，
调用已有 `CLEAR_RULE_FILTER`，恢复列表但保留选择与草稿。

## 生成式接入与消费者

- `rule_set_window_app`：公共数值步进、单选组、状态/内容/进度均已在手写和
  generatedRegion 中实际消费。生成式公开更新经既有 `SUBMIT_GENERATED_UI`
  候选事务；非法结构仍由原事务拒绝并保留旧界面。
- `notification_threshold_window_app`：用同一 `CjguiNumericStepper` 构建
  `triggerThreshold` 字段（不同 fieldId、资源、动作和上下限），证明组件未写死
  retention、规则集资源或动作名。其运行/构建入口仍是该样例的 `run.sh`。

2026-10-20 真实验证（980×652，同一候选）：保留天数步进 12→13 → 紧凑单选 →
设为 100 后点 `+`，显示 `[错误] 保留天数步进被拒：above_maximum` 且值保持
100 → 改为 14 → 筛选 `zzz` 空结果 → 清除后选择/草稿保留 → 公开生成 v1（错误
状态、3/10 进度、紧凑选中）→ 继续改为 15 → 应用/保存（保存文件
`RECORD 2 retention=15`）→ 正常关闭 destroy。补充：直接点击“设为 100”预设
写入 100，再点 `+` 被 owner 拒绝；同 key 生成重排 v2 接受后草稿仍为 100，
继续步进 99；620×700 下长状态文案完整换行，不只靠颜色。代表性更新序列
增量构建/布局各 11 次、原生提交 34 次、RSS +32KiB。通知阈值实例 70→71，
已应用基线保持 70。10 项定向测试 PASSED，旧交付二进制 `ea9d27dd…`；细节见
[证据目录](artifacts/field-controls-20261020/README.md)。

2026-10-20 有限收尾（公共默认修复，新构建 `c41eab0b…`）：进度 0% 填充实测 0 宽、
亚像素正比例取 1pt、9e8 轨道配 12e9/20e9 值走宽整数精确比例；状态正文与内容态
标题/详情在窄宽度下按实际几何换行，显式 `fixedHeight` 仍生效；步进正负越过 Int64
返回 `step_overflow` 并保留当前文本。8 项定向用例 PASSED（含受影响的旧用例）。
同一轮 620×885 短画面没有把生成区域滚入视口，未用截图冒充通过；620 宽筛选框被
压到约 8px 与生成区滚动受限记录为后续普通窗口布局整合项。旧的 980/620 长链证据
属于 `ea9d27…`，没有用新构建重跑。

## 构建与启动

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
cd runtime/cjgui/examples/rule_set_window_app
cjpm build --skip-script
./target/release/bin/main --retention-range 1 100 --open <rules.json>
```

通知样例：

```bash
cd runtime/cjgui/examples/notification_threshold_window_app
zsh run.sh --build-only
```

## 稳定性与已知限制

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| 数值步进、边界/owner 拒绝反馈 | experimental | macOS 已验；值由 owner 拥有 |
| 稳定 key 单选组 | experimental | macOS 已验；不新增原生 Radio |
| 状态消息/内容状态 | experimental | 文本 kind + 动作；不执行任务 |
| 确定/忙碌进度 | experimental | 调用方给值；无动画/定时器 |
| 手写/生成式共用构建器 | experimental | 公开复合组件与登记已接通 |

未包含：下拉窗口、搜索选择器、新原生 Radio ABI、Toast 队列、后台任务框架、
进度动画、自定义重试策略、全平台验证。单次 GET 的零计数只描述该次观测，不能
据此宣称整个空闲期无轮询。既有原生窗口生成测试失败保留，不冒充通过。
