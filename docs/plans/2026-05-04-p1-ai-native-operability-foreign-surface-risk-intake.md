# P1 AI-native Operability / Foreign Surface Risk Intake

日期：2026-05-04

性质：docs-only / architecture risk intake / future opening registry / no implementation

状态：完成；不改变当前 renderer / backend-readiness next opening

## 1. Scope

本文件接收一次关于 AI-native UI、物理可操作性、自绘路线和可选浏览器内核组件的架构讨论。

本轮只做风险登记和 future opening 命名，不批准当前实现：

- 不实现 semantic tree。
- 不实现 Action Router 新能力。
- 不实现 layout / widget / text / IME / accessibility。
- 不实现 dirty-region / invalidation。
- 不实现 browser kernel / WebView / Chromium / WebKit integration。
- 不改变当前 renderer backend-readiness branch 的 next opening。

本文件的作用是避免这些长期思路只留在聊天记录里。

## 2. Accepted Signals

这次讨论中有四类信号值得吸收。

### Physical Operability

AI 不能拥有比人类更宽的 UI 操作权限。`enabled: true` 只表示业务状态允许，不表示当前物理上可点击。

未来 semantic action eligibility 必须能引用：

- layout bounds；
- clip / viewport；
- z-order；
- modal / overlay；
- occlusion；
- hit-test result；
- visibility / opacity；
- stale target generation。

这不是让 semantic tree 成为第二真相源。正确方向是让 semantic projection 消费 layout / scene / hit-test 的脱水证据，并由 Action Router / owner gate 决定是否允许 action。

### Interaction Stability

AI action 速度远快于 UI 动画、layout settling 和 owner state transition。

未来必须显式表达：

- pending / loading；
- transitioning；
- layout unstable；
- action in-flight；
- owner busy；
- stable / ready for next action；
- stale target / stale generation。

这类状态必须来自明确 owner，不允许 semantic layer 自己发明。

### Layout-derived Semantic Association

传统 ARIA-style 手工标注会给开发者带来高负担。CJGUI 如果拥有 Element / Layout / Scene 的统一 truth，未来可以从常见结构中自动推导一部分语义关系。

候选关系包括：

- label / control relation；
- row item relation；
- group / section relation；
- described-by / controls relation；
- command and selection target relation；
- spatial neighborhood relation。

复杂关系仍允许显式声明。缺失时必须诚实降级，不让 AI 产生虚假的理解能力。

### Foreign Surface Containment

可选浏览器内核组件不是当前路线，也不是把 CJGUI 做成浏览器。

但作为远期能力，它可以被记录为 `foreign surface`：一个被 CJGUI 圈养的外部内容 surface，用于复杂富文本、Markdown preview、legacy SaaS 或 Web 文档场景。

正确口径：

- CJGUI 仍是 host / compositor / input / action owner。
- 浏览器内核只能是可选 component / plugin。
- 默认 runtime 不携带 browser kernel 重量。
- foreign surface 不直接拥有 app window。
- foreign surface 不直接接收 OS input。
- foreign surface 不直接暴露 DOM / accessibility tree 作为 CJGUI semantic truth。
- foreign surface 必须经过 Action Router / focus / IME / coordinate / sandbox boundary。

## 3. Future Openings

以下 openings 被登记为 future candidates，但不自动开启。

### `P1 semantic physical operability / occlusion gate preflight`

用途：

- 冻结 AI action eligibility 如何引用 layout / clip / z-order / occlusion / hit-test / viewport / modal gate。
- 明确 physical visible / semantic enabled / owner admitted 三者的区别。
- 防止 AI 拥有“隔山打牛”能力。

不得直接实现 semantic tree、hit-test engine、layout engine 或 Action Router side effect。

### `P1 semantic interaction stability / pending gate preflight`

用途：

- 冻结 pending / stable / transitioning / owner busy / stale generation facts。
- 明确 AI 连续 action 如何等待 UI stable。
- 防止动画残影、transition 未完成、loading 竞态和 stale target 操作。

不得直接实现 scheduler、animation runtime、frame loop 或 action execution。

### `P1 layout-derived semantic association preflight`

用途：

- 评估是否从 Element / Layout / Row / Group / Section 自动推导 label / control / row item / described-by / controls 等关系。
- 明确哪些关系可自动推导，哪些必须由 app owner 显式声明。
- 明确缺失关系时的 degraded 行为。

不得在没有 Element / Layout owner truth 前实现自动语义推导。

### `P1 foreign surface / browser-kernel containment preflight`

用途：

- 评估可选 browser kernel / WebView / Chromium / WebKit 作为 foreign surface 的远期可行性。
- 冻结 sandbox process、texture handoff、input proxy、focus / IME cursor rect sync、semantic projection gate、IPC failure 和 teardown owner。
- 明确 browser kernel 不能成为 host、window owner、input owner、semantic truth owner 或 default runtime dependency。

不得实现 browser kernel integration、WebView widget、Chromium / WebKit embedding、external process IPC、texture sharing 或 DOM semantic bridge。

## 4. Foreign Surface Stop-line

如果未来重新打开 browser-kernel 方向，必须先回答：

- backend / compositor 如何接收外部 texture，而不让外部 surface 拥有窗口；
- input 如何先进入 CJGUI Action Router / focus owner，再转发给 foreign surface；
- IME candidate / cursor rect 如何在 CJGUI layout 与 foreign content 坐标之间同步；
- foreign surface 的 semantic projection 如何降权、过滤和标注 provenance；
- foreign surface 崩溃、hang、IPC timeout、GPU resource loss 如何 fail closed；
- browser kernel 是否按需加载，如何避免默认 runtime 重量膨胀；
- sandbox / permission / storage / network policy 由谁拥有；
- browser DOM / accessibility tree 如何避免成为第二语义真相源。

## 5. Relationship To Existing Guardrails

本 intake 与已有文档的关系：

- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md) 已记录 semantic tree、Action Router、物理可见性、stable / pending、空间语义和 zero-trust action 的长期方向。
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 已记录 AI semantic tree 热路径、过度重绘、IME cursor rect、accessibility semantic bridge 和 action protocol 风险。
- [2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md) 已记录 dirty-region、IME cursor rect sync 和 accessibility semantic bridge future slots。
- [2026-05-01-p1-ai-native-architecture-radar-future-plan.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-ai-native-architecture-radar-future-plan.md) 已记录 Scene / DisplayList、ECS、CRDT、Effect Handler 等未来雷达。

本 intake 的新增价值是把 physical operability、interaction stability、layout-derived semantics 和 foreign surface containment 显式命名为 future openings。

## 6. Current Next Opening

当前 renderer / backend-readiness 主线不变。

继续以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 的当前 recommended next opening 为准。

本文件不批准：

- 真实 browser kernel / WebView；
- 真实 semantic tree；
- 真实 Action Router side effect；
- 真实 layout / hit-test / occlusion；
- 真实 dirty-region / invalidation；
- 真实 IME / accessibility bridge；
- public API / C ABI expansion。

