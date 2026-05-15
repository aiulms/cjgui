# P1 AI-native Generated UI / Semantic UI Spec 北极星 intake

日期：2026-05-15

性质：docs-only / north-star intake / future opening registry / no implementation

状态：完成；不改变当前 Renderer / native bridge next opening

## 1. 文档定位

本文件记录 CJGUI 的一个长期北极星方向：

> CJGUI 不只让 AI 读取和操作 UI，也应长期支持 AI 在受约束的语义空间内生成、预览、修改和解释 UI。

这里的 “AI 生成 UI” 不表示当前实现 AI provider、prompt runtime、widget generator 或 public DSL。

它表示未来框架设计时应持续保留一条路线：

- 人类定义 owner、truth、permission、schema 和业务意图。
- AI 在有限、类型化、可组合的 UI spec / widget schema / action schema 空间内生成候选界面。
- 系统可以 preview、diff、reject、explain 和 rollback。
- 生成结果必须回到 app owner / Action Router / semantic projection / renderer pipeline 的受控路径，不能绕过 owner 直接改状态。

本文件只做方向登记，避免该想法只留在聊天记录中。

## 2. 核心判断

当前已有 AI-native 文档已经覆盖三条基础路线：

- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md) 记录 AI-readable / Agent-operable UI、semantic projection、Action Router 和语义树不能成为第二真相源。
- [AI_ACTION_PROTOCOL_EXPERIMENT.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md) 记录 AI-authored action command 的协议实验与 zero-trust gateway 分层。
- [ai-native-gui-runtime-architecture-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/ai-native-gui-runtime-architecture-intake.md) 已记录 “面向 AI 生成，而不是只面向人类手写” 的长期 contract 思路。

本文件新增的价值，是把更产品化的北极星表述显式固定：

```text
人类看见 pixels
AI 读取 semantics
AI 提交 structured UI / action intent
系统 preview / diff / reject / explain
owner 决定是否接受
renderer 只消费被接受后的 truth projection
```

这更接近：

- 所想即所得：人类用意图描述界面，AI 生成候选 UI spec。
- 所见可解释：界面不是只剩像素，而是保留 semantic projection、action eligibility 和 evidence。
- 所改可审计：AI 修改不是直接改运行时 truth，而是提交可 diff、可拒绝、可回滚的结构化 patch。

## 3. 未来能力轮廓

### Semantic UI Spec

未来可以评估一层结构化 UI spec。

它不是任意代码字符串，也不是让 AI 直接写 runtime internals。

候选属性：

- stable node id / generation；
- role / label / state；
- bounds / layout intent / grouping；
- action binding / owner reference；
- permission / capability requirement；
- validation rule；
- render hint；
- semantic projection hint；
- audit label。

该 spec 必须编译或展开为已有 owner truth / projection / renderer input path，不能成为第二 truth source。

### AI-generated UI patch

AI 未来不应直接修改 app state 或 renderer cache。

更合理的路径是：

```text
AI proposal
-> typed UI / action patch
-> schema validation
-> owner / permission validation
-> preview / dry-run
-> diff / explanation
-> human or app owner accept
-> committed owner truth
```

这条链路和当前 owner / fact / readiness / blocked report 风格一致。

### AI-native WYSIWYG

传统 WYSIWYG 主要回答 “视觉上看到什么，就编辑什么”。

CJGUI 的长期目标可以更进一步：

```text
human intent
-> AI-generated structured UI proposal
-> live preview
-> semantic diff
-> owner-approved commit
```

因此更准确的口径不是简单复刻 Markdown 或传统设计器，而是 AI-native WYSIWYG：

- 所想即所得；
- 所见可解释；
- 所改可审计；
- 所生成可拒绝。

## 4. 与现有架构的关系

本方向依赖但不替代以下长期基础：

- Single app state / owner truth。
- Semantic projection。
- Action Router zero-trust gateway。
- State snapshot / controller handle 双轨。
- Physical operability / interaction stability。
- Layout-derived semantic association。
- Scene / DisplayList / renderer handoff。

如果未来 UI spec 生成绕过这些路径，它就不是 AI-native，而是新的后门。

## 5. Future openings

以下 openings 被登记为 future candidates，但不自动开启。

### `P1 AI-native semantic UI spec north-star preflight`

用途：

- 冻结 UI spec 是否作为 future public surface 或 internal authoring surface。
- 明确 spec 与 app owner truth、semantic projection、layout、renderer input 的关系。
- 明确 spec 不能成为第二 truth source。

不得直接实现 public DSL、widget generator、semantic tree 或 runtime code generation。

### `P1 AI-generated UI preview / diff / reject loop preflight`

用途：

- 冻结 AI 生成 UI patch 的 preview、dry-run、diff、explanation 和 rollback 口径。
- 明确 human / app owner 如何接受或拒绝 AI proposal。
- 明确 blocked report 如何反馈给 AI 进行修正。

不得直接实现 AI provider、prompt runtime、IPC server、public API 或 real action side effect。

### `P1 AI-authored widget schema capability gate preflight`

用途：

- 评估 AI 在有限 widget schema 空间内组合 UI 的权限边界。
- 明确 capability、owner、action binding 和 validation rule 如何挂接。
- 防止 AI 通过 widget schema 获得超出人类或 app owner 的权限。

不得直接实现控件库、声明式 DSL、layout engine、Text / IME / Accessibility 或 public semantic API。

## 6. Stop-line

本文件不批准：

- semantic tree implementation；
- Action Router 新能力；
- AI provider / prompt runtime；
- external agent runtime；
- public AI API；
- public semantic DSL；
- AST / widget generator；
- `@ai_prompt` 或等价 prompt schema；
- UI spec parser / compiler；
- preview / diff / patch runtime；
- layout / widget / text / IME / accessibility implementation；
- renderer implementation permission；
- production native bridge permission；
- public C ABI / public runtime API expansion。

当前 Renderer / native bridge next opening 仍以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 Renderer topic manifest 为准。

## 7. 与索引的关系

本文件挂接到 [AI-native semantic / action gateway topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/ai-native-semantic-action-gateway.md)。

后续开启 semantic projection、AI action protocol、AI generation contract、semantic UI spec、widget schema、AI-native WYSIWYG 或 generated UI preview / diff / reject loop 前，应读取：

- 本文件；
- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)；
- [AI_ACTION_PROTOCOL_EXPERIMENT.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md)；
- [ai-native-gui-runtime-architecture-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/ai-native-gui-runtime-architecture-intake.md)；
- [AI-native operability / foreign surface risk intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md)。

## 8. 设计意图出口自检

- 本轮改变主题状态：是，AI-native semantic / action gateway 主题新增 generated UI / semantic UI spec north-star future radar。
- 本轮改变 canonical tail / endpoint：否。
- 本轮改变 owner / truth / stop-line：是，只在 docs-only 层新增 future truth / stop-line，不改变 runtime owner。
- 本轮改变唯一 next opening：否，当前 Renderer next opening 不变。
- 是否同步 topic manifest：是，已同步 `docs/plans/topic-manifests/ai-native-semantic-action-gateway.md`。
