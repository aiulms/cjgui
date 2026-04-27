# AI 原生 UI 语义方向

最后更新：2026-04-26

## 1. 文档定位

本文件记录仓颉 GUI 框架的一个长期方向：

> 不只做 GPU 自绘 UI，而是做 AI-readable / Agent-operable 的 GUI。

这里的 “AI 原生” 不表示框架内置一个 AI 模型，也不表示每个应用都必须接入 AI。

它表示：

- UI 框架给人输出像素、窗口、控件和动画。
- UI 框架同时给 AI / 无障碍 / 测试工具输出语义树、状态、可执行动作和上下文证据。

本文件只作为方向记录和未来接口预留依据，不批准当前实现。

## 2. 为什么这件事重要

传统 GUI 框架的主要目标是把 UI 变成像素。

这对人类足够，但对 AI 不够。AI 如果只能拿截图，就只能猜测：

- 哪个区域是按钮
- 哪个文本是状态
- 哪个操作是危险动作
- 哪些信息是只读证据
- 当前页面为什么处于这个状态

现有生态有一些近亲能力：

- Web 的 DOM / ARIA
- Flutter 的 Semantics
- macOS / Windows 的 Accessibility API
- Playwright / UI 自动化选择器

但这些能力大多是为无障碍、测试、自动化准备的，不是为 “AI 协作者理解应用” 从一开始设计的。

本项目可以把 AI 可理解性作为长期一等目标，而不是事后补丁。

## 3. 核心架构口径

长期目标可以描述为：

```text
App State Truth
-> Element Tree
-> Scene / Renderer -> Pixels 给人看
-> Semantic Tree -> AI / 无障碍 / 测试看
-> Action Router -> AI 可以请求执行动作
```

关键原则：

- App state 是真相。
- Element tree 消费 app state。
- Scene / Renderer 是像素投影。
- Semantic tree 是语义投影。
- Action router 只能把动作请求送回真正 owner。
- AI 不能绕过应用 owner 直接改状态。

## 4. 一个最小语义例子

一个按钮未来不应该只被渲染成矩形和文字。

它还可以投影出类似这样的语义信息：

```text
id: mission.release
role: button
label: 发布 Mission
enabled: true
state: requires_approval
actions: invoke
bounds: x/y/w/h
evidence:
  - current mission is planned
  - approval gate is satisfied
```

这样 AI 不需要根据截图猜测 “右下角蓝色块是什么”，而是能知道：

- 它是一个按钮。
- 它的语义是发布 Mission。
- 它当前可以触发。
- 它触发的是受 owner 管理的 action。
- 它不是直接修改状态的后门。

## 5. 与 CLI / API 后门模式的区别

传统 “应用 + CLI/API” 模式是后门：

```text
人类走 GUI
AI 走 CLI / API
```

这种方式可用，但 GUI 和 AI 通道经常分裂：

- AI 不知道人类当前看到什么。
- GUI 的空间上下文和视觉状态不自动进入 AI。
- 应用开发者要额外维护一套后门 API。
- 小应用很难承担这种额外成本。

AI 原生 UI 的目标不是取消 API，而是让正门本身可理解：

```text
人类看到 pixels
AI 读取 semantics
两者来自同一份 UI truth
```

## 6. 与无障碍的关系

AI-readable UI 和 Accessibility 有重叠，但不等价。

共同点：

- 都需要 role / label / bounds / state。
- 都需要明确控件层级。
- 都不能只依赖像素。

差异：

- 无障碍首先服务人类辅助技术。
- AI-readable UI 还需要任务上下文、动作意图、证据来源、风险语义和可审计动作。
- AI 动作必须经过 action router 和应用 owner，不应该拥有隐藏特权。

未来正确路线应当尽量复用同一份 semantic projection，不要为 AI 和无障碍各造一套第二真相。

## 7. 与测试自动化的关系

AI semantic tree 也可以帮助测试自动化。

长期看，它可以让测试通过语义定位元素，而不是依赖脆弱坐标：

```text
find role=button label="发布 Mission"
invoke action=mission.release
assert state=requires_approval
```

但测试只是受益者之一，不是唯一目标。

## 8. 语义树的真相纪律

最重要的铁律：

> 语义树不能成为第二真相源。

禁止：

- 语义树自己保存 UI 状态。
- 语义树绕过 app state 修改业务状态。
- AI action 直接改渲染缓存。
- AI action 绕过应用 owner。
- 语义投影和像素投影分别解释同一个状态。

允许：

- 语义树投影当前 UI 状态。
- 语义树暴露可执行 action 的描述。
- Action router 把请求交还给应用 owner。
- 应用 owner 决定执行、拒绝、要求确认或记录审计。

## 9. 已识别盲点

这些盲点不推翻 AI-native UI 方向，但会显著提高未来实现难度。

### 9.1 物理可见性与可操作性

`enabled: true` 不等于人类当前可点击。

未来语义系统必须区分：

- 元素是否在 ScrollView 可视范围内
- 元素是否被 Modal / Popover / Overlay 遮挡
- 元素是否透明、不可见或被裁剪
- 元素是否只是语义存在，但当前物理不可操作

如果 AI 可以调用不可见或被遮挡元素的 action，它就获得了人类没有的 “隔山打牛” 特权。

如果框架拒绝这类 action，那么语义系统必须能拿到 layout、clip、z-order、occlusion 等物理结果。

这意味着未来 semantic projection 不能只看 app state，也必须谨慎接入布局和场景投影的可见性证据。但这种接入仍不能让 semantic tree 成为第二真相源。

### 9.2 时序同步与动画残影

AI 的动作速度可能远快于 UI 渲染、动画和人类反应。

未来必须处理：

- transition 中的元素
- loading / pending 状态
- 还未到下一帧的状态变化
- 连续 action 造成的 race condition
- 需要等待 UI stable 的交互序列

因此 semantic projection 或 action gateway 未来可能需要暴露局部或全局的：

```text
busy / transitioning / stable / stale
```

但这类状态必须来自明确 owner，不能让语义树自己发明。

### 9.3 空间邻近性与语义绑定断裂

人类可以通过视觉邻近性理解关系，比如一行里的 `删除` 文本和旁边的 checkbox 属于同一项。

AI 如果只看到扁平语义树，可能无法理解这些关系。

未来可能需要：

- `label_for`
- `described_by`
- `controls`
- `owns`
- row / group / section 语义
- bounds 和相对空间关系

但不能把开发者负担拉到 “到处手写 ARIA” 的程度。

长期理想是：

- 框架从 Element / Layout 结构中自动推导常见关系。
- 复杂关系允许显式补充。
- 缺失语义时保持诚实 degraded，而不是假装 AI 已理解。

### 9.4 Action Router 的零信任边界

AI action 不是可信 OS 输入。

未来 Action Router 必须按 zero-trust gateway 设计：

- action id 必须存在
- action 必须属于当前可操作语义节点
- action 参数必须校验
- action 必须满足 owner policy
- action 必须能被拒绝、要求确认或审计
- action 不能绕过权限、状态机或业务 owner

这意味着 Action Router 不能只是回调转发器。

它更接近一个本地 UI action gateway。

协议方向补充：

- [AI_ACTION_PROTOCOL_EXPERIMENT.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md) 记录了一次 RPN / JSON / Lisp-style S-expression 的 action command 格式实验。
- 当前结论是：RPN rejected；JSON 不作为复杂 AI-authored action DSL 的默认首选；Lisp-style S-expression 是未来 AI-authored Action Command 的 preferred north-star candidate。
- 这不是完整协议冻结，也不批准当前实现 Action Router。
- S-expression 在本项目中必须是 data grammar，不是 executable Lisp；禁止 `eval`、macro、user-defined function、arbitrary symbol execution。
- 未来正确路径应是：S-expression surface syntax -> restricted AST -> typed ActionRequest -> zero-trust Action Gateway -> application owner。

### 9.5 IPC 的隐性复杂度

如果 Agent 是外部进程或服务，它如何读取 semantic tree、发送 action、订阅变化，都需要边界。

可能路径包括：

- 进程内 API
- Unix Domain Socket
- WebSocket
- 本地 TCP
- 文件 / snapshot
- 共享内存

但 IPC 不应该被塞进 GUI 框架核心默认路径。

长期更合理的边界是：

- GUI framework 提供可选 semantic provider / action gateway 抽象。
- 应用或适配层选择是否暴露 IPC。
- 默认轻量路径不启动任何 AI server。

否则会与 “极致轻量的通用 GUI 框架” 目标冲突。

## 10. 对当前阶段的影响

当前阶段不实现 AI 原生 UI。

但当前阶段需要在思想上预留四个口子：

1. 未来 `Element` 不只会 render，也可能 expose semantics。
2. 未来 `Scene` 不应该成为唯一输出，semantic projection 也要从同一 UI truth 生成。
3. 未来 action 不能等同于回调乱飞，必须回到 owner boundary。
4. 未来节点至少应允许携带稳定 `id` / `tag` / debug label 这类非绘制属性，但不在 P1 生成 semantic tree。
5. 未来如果需要 AI-authored action command，优先从 S-expression 作为 surface syntax 候选开始 preflight，但必须先 parse 成受限 AST / typed ActionRequest。

这意味着早期设计不要写死成：

```text
Widget -> draw pixels only
```

更合理的长期想象是：

```text
Element
-> render(scene)
-> semantics(tree)
-> actions(router)
```

注意：这只是长期方向，不是 P0/P1 的代码要求。

对 P1 的额外约束：

- 可以考虑为未来 Element / RenderCommand 保留稳定 ID 或 tag 的位置。
- 不做 semantic tree。
- 不做 action router。
- 不做 IPC。
- 不实现 S-expression action protocol。
- 不让 AI action 与 mouse / keyboard 形成第二套状态机。
- 未来若进入 action 设计，AI action 和鼠标键盘事件应能进入同一 owner-controlled event queue，而不是开后门。

## 11. 与当前 GUI 路线的关系

本方向不改变当前路线：

- 仍然先做 macOS 单平台。
- 仍然先做窗口、事件循环、基础 GPU 绘制。
- 仍然先做最小 Scene / Renderer 输入。
- 仍然不做输入框、IME、无障碍、富文本、完整控件库。

它只是补充长期特色：

> 仓颉 GUI 不只是轻量 GPU 自绘框架，也可以逐步成为 AI 可理解、Agent 可协作的 GUI 框架。

## 12. 推荐进入时机

不建议现在实现 semantic tree。

更合理的进入时机：

1. 已经有稳定 Element tree。
2. 已经有基础事件模型。
3. 已经有少量核心控件。
4. 已经能从 UI 状态稳定生成 Scene。
5. 再开始设计 Semantic projection first slice。

第一个 semantic first slice 可以非常小：

- 一个按钮
- 一个 label
- 一个 bounds
- 一个 role
- 一个 enabled state
- 一个 invoke action 描述

但这必须等到控件和事件边界更清楚之后。

## 13. Stop-line

本文件不批准：

- 现在实现 semantic tree
- 现在实现 action router
- 现在引入 AI runtime
- 现在做无障碍系统
- 现在做测试自动化框架
- 现在为语义树设计完整公共 API
- 现在设计 IPC server
- 现在实现 S-expression action protocol
- 让 AI 绕过 app owner 直接修改状态

本文件只批准：

- 把 AI-readable / Agent-operable UI 记录为长期方向
- 在未来 Element / Scene / Renderer 设计中保留语义投影空间
- 把 “语义树不能成为第二真相源” 写入长期治理原则
- 把物理可见性、时序稳定、空间语义、zero-trust action、IPC 边界列为 future semantic first slice 的必答问题
- 把 S-expression 记录为未来 AI-authored action command 的 preferred north-star candidate，而不是当前实现任务
