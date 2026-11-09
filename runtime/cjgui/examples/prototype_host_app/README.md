# CJGUI 通用原型宿主（macOS，experimental）

一个普通 CJGUI macOS 应用：**同一个二进制**打开不同领域的原型项目。字段、数据、动作、界面
文件与资源都来自项目声明；模型通过公开 descriptor 发现和编辑界面，人在窗口里正常输入和操作。

## 运行

```sh
cd /path/to/cangjie/runtime/cjgui/examples/prototype_host_app
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
./run.sh --build-only
./run.sh --project "$PWD/projects/settings"
```

`--project` 必须是**绝对路径**（项目根是界面/会话/资源路径的唯一锚点）。启动后打印：

```
CJGUI_PROTOTYPE_HOST_READY project=<id> root=<abs> fields=<n> records=<n> view=<form|list|cards>
CJGUI_PROTOTYPE_HOST_DESCRIPTOR <descriptor path>
```

descriptor 是本次进程的私有本地连接；关闭窗口后失效，重开必须用新 descriptor。
不带 `--project` 时按用法拒绝（不猜项目）。

其他诊断参数：`--diagnose-window` 打印 accepted 场景的节点 bounds（只读）、
`--self-check` 只构建一次场景树（无窗口）、`--minimal` 最小控制器（验证宿主链）、
`--no-connection` 不发布 descriptor、`--clip-probe <N>` 用 N 层嵌套 `clipsContent` 容器复现
裁剪约束上限（正常入口不打印生命周期 trace，只有该参数或 `--diagnose-window` 打开）。

## 运行期声明扩展（不重启、不重编译）

编辑项目 `prototype.json` 增加字段/动作，点窗口里「重载声明」：项目声明、能力目录、真实
owner、校验与绑定一起更新；同 id 同类型字段保留 draft/applied/fieldVersion，新字段用声明
默认值初始化。支持范围：**新增字段 + 新增动作 + 标题变化**；视图/记录集/主题/窗口/分组、
既有字段规则与既有动作的变化会以具名原因整体拒绝（保留旧项目），不做部分更新。新字段不会
自动出现在界面结构里：模型通过公开 capabilities 发现它，再用编辑计划生成对应节点。

## 项目切换（同一进程）

「项目」输入另一个项目绝对路径后点「打开」：新会话（声明/owner/目录/界面文档会话）先在
内存里完整建立，成功后才替换并关闭旧会话；外部连接是一个稳定的桥，切换后它与窗口都指向
新 owner（descriptor 不变）。若旧项目有未应用草稿或未保存界面，第一次点击只提示，再次
点击同一路径才作为明确确认放弃；失败（路径不合法/会话构建失败/场景刷新未空闲）一律保留
旧项目。切换后窗口标题仍是启动时的标题（当前窗口标题不支持运行期变更，已记录）。

## 会话文件（v2）

`session.json` 使用 `cjgui.prototype-host.session.v2`：按**稳定字段 ID**保存/恢复 draft、
applied 与 fieldVersion，并保存字段身份清单；恢复前整体校验（字段集合/类型/对象集合/版本），
任何不匹配都整体拒绝，不按数组位置猜测、不部分写入。旧 v1 会话文件（没有字段身份）在启动时
以 `legacy_preserved` 保留为 `session.json.v1.bak`，当前会话改用项目默认值，不静默删除。

## 项目目录

```text
projects/<name>/
  prototype.json        # 声明：id/title/view/theme/window/groups/fields/actions/records
  data/<file>.json      # records 声明指向的数据文件（内联数组也可）
  ui/main.json          # cjgui.ui-document v1（模型生成后 ui-export 写入；启动自动载入）
  assets/               # 项目相对资源（图片等）
  session.json          # 可选：原型业务草稿（公共 CjguiComposableUiWorkSession 格式）
```

`prototype.json` 字段：`id`、`title`、`view`（form/list/cards）、`theme`（目前 hig）、
`window.{width,height,minimumWidth}`、`groups[]`、`fields[]`（kind: text/integer/boolean/select，
`sourceField` 指向数据属性）、`actions[]`（项目级动作，当前语义为恢复声明默认值）、
`records.{file,titleField,filterField,imageProperty,tagsProperty,statusProperty}`。
界面结构**不**来自这个文件——它只描述业务与项目清单，界面仍由 `cjgui.ui-document` 承载。

## 模型侧（公开入口，无私有钩子）

```sh
cd /path/to/cangjie/runtime/cjgui/shared_operation_core
python3 cjgui_generated_edit.py "$DESCRIPTOR" capabilities      # 发现组件/字段/动作/选项/预算
python3 cjgui_generated_edit.py "$DESCRIPTOR" show              # 当前 accepted 结构
python3 cjgui_generated_edit.py "$DESCRIPTOR" init structure.json
python3 cjgui_generated_edit.py "$DESCRIPTOR" preview plan.json  # 本地预检，不提交
python3 cjgui_generated_edit.py "$DESCRIPTOR" apply plan.json    # 一次候选 + 精确读回
python3 cjgui_generated_edit.py "$DESCRIPTOR" ui-export "$PROJECT/ui/main.json"
```

字段读回用 `evidence/model-chain/readback.py`（`GeneratedUiSession` typed client）。

## 本阶段已知边界

- 生成式字段需要在结构里声明 `style: "input"` 才呈现为输入框；`action` 节点需要
  `fixedWidth`，**它所在的横向行也要声明 fixedWidth（=子项宽+间距）**，否则行被测量为很窄、
  子项溢出到可视区外（见 `work/prototype-host-20261108/evidence/feedback/`）。
- 生成式字段行做「外部标签列 + 控件」时用 `labelVisible: false`：控件只隐藏可见标签，
  声明的 `label` 仍是 AX 名称；不再使用 U+200B。
- 生成式 `segmented` / `radioGroup` 选项已接回统一选择入口（R4），点击写 owner；settings
  的 appearance/accent 使用 segmented，assets/materials 仍用 select。
- 嵌套裁剪上限 4 层（含窗口内容根）：超限整场候选回滚，reason 仍是 `clip_constraint_capacity`；
  `--clip-probe 3` 额外输出 `layoutDiagnostic`（节点/深度/上限/裁剪链）。容量未扩展。
- 启动载入界面文档后需要空闲边界结算（宿主已内部处理 `workspace.finish()`）才能保存。
- 运行期声明扩展只支持新增字段/动作；其他声明变化以具名原因拒绝。
- 项目切换后窗口标题不随项目变化；旧连接/旧结构候选会被新区域拒绝（版本/节点未知）。
- 只消费 checkout，未导出 SDK；本机候选不是正式发布。

## 整数步进（R9）

生成式 `integerInput` 可声明 `stepper: true`：复用 `CjguiNumericStepper` 构建输入 + ± 按钮，
输入与按钮共用字段草稿/校验/Apply；越界按声明 min/max 拒绝（不 clamp）。settings 的提醒间隔
实际使用。快速连续点击按“同一刷新代一次”去重，自动化连点会合并为一步。


## 整窗原型：先选择承载配方（H4）

业务视图仍来自 `prototype.json` 的 `view`。列表—详情默认采用 `projects/assets/ui/main.json`
的有界工作区；短设置表单、卡片详情可以保留内容自适应。宿主只看生成根的既有 `growY` 意图：

- **内容自适应（缺省兼容）**：根不声明 `growY`。宿主保留外层 ScrollArea，文档按自然高度滚动；
  表单不必为填空拉高控件。settings/materials 原文档沿用这一用法。
- **填充工作区**：根声明 `growX: 1`、`growY: 1`，宿主把根直接放进有界剩余区域。
  根/card 沿纵向传递 `growY: 1`；card 中只有内容 ScrollArea 增高，操作行是其普通兄弟。
  不把整份文档再包一层自然高度 ScrollArea，不设一个猜测窗口高度的 fixedHeight。

默认列表配方已经实际这样组织（完整可导入文档见 assets，不需要新协议）：

```text
vertical root (growX=1, growY=1)
  label heading
  vertical card (style=card, growX=1, growY=1, padding=16, gap=12)
    scrollArea content (growX=1, growY=1)
      vertical content (growX=1，承接视口宽度)
        vertical form (growX=1, maxWidth=720, alignX=stretch, gap=16)
          字段行 / 说明，控件保持自然高度
    horizontal actions (fixedWidth=318, alignX=end, gap=8)
      恢复默认(96) / 取消(96) / 应用(110)
```

短内容的余量归内容视口，底部操作位置稳定；长内容只在内容视口内滚动，操作不被挤出。
ScrollArea的首个内容节点承接视口宽度，最大阅读宽720放在它里面的普通form容器上；
form在普通纵排中用stretch承接可用宽度并受maxWidth约束；center会选择自然宽度，不能替代这个承载。
标签列160，余宽给输入；720窄窗复用原有列表折叠入口，不叠加固定侧栏宽度。
左侧列表仍复用同一 viewport/虚拟列表并独立滚动。面板和字段沿现有 `card`/`input`/动作主题角色。
这些是宿主组合选择，不改变框架自然高度语义或默认主题。

模型从正常公开入口发现能力，选择对应完整配方，再按字段 key 续改布局：

```sh
python3 cjgui_generated_edit.py "$DESCRIPTOR" capabilities --json
python3 cjgui_generated_edit.py "$DESCRIPTOR" ui-import "$HOST/projects/assets/ui/main.json" --save-import-plan import.json --apply --json
# 对已接受配方使用 preview/apply plan，保留 field、action 和 owner 路由。
python3 cjgui_generated_edit.py "$DESCRIPTOR" ui-export "$PROJECT/ui/main.json" --json
```

导出后正常保存会话、关闭重开，继续沿同一草稿/owner工作；布局改动不隐式Apply。
旧项目仅增加根growY不足以保证长内容可达，选填充时应同时采用内部内容滚动与兄弟操作行的结构。
诊断可加 `--observe-layout`：只在accepted场景变化时输出真实 `window.contentBounds()` 和有界布局快照；
不打开性能测量、不写布局或业务状态。
