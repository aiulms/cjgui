# AI-native 语义与 Action Router gateway 主题 manifest

状态：docs-only / topic manifest / future radar

## 主题定位

本主题记录 Scene / Renderer input、RenderCommand command shape、material / batching hints、Action Router、AI-native semantic future direction，以及 AI 生成 UI / semantic UI spec / AI-native WYSIWYG 的长期北极星。

## 当前状态

当前已落地 Scene / Renderer input、RenderCommand command shape、material / batching hint 和 Action Router 的 internal value facts。它们为未来 semantic projection、AI action eligibility、AI-generated UI proposal 和 renderer handoff 留下审计位置，但不实现 semantic tree、layout、hit-test、dirty-region、IME、A11y、AI provider、widget generator、public DSL 或 action side effect。

## 已落地现实

- `CjguiInternalRendererInputPacket` / `cjguiInternalExecuteDefaultSceneRendererInputDraft()` 表达 Scene / Renderer input dehydrated facts。
- `CjguiInternalRenderCommandPacket` / `cjguiInternalExecuteDefaultRenderCommandShapeDraft()` 表达 RenderCommand / DisplayList command shape。
- material / batching hint manifest 固定 material key、z-order、clip、batch key hint、ordering hint 和 backend-agnostic batching packet。
- Action Router 是 zero-trust gateway，AI action 不得绕过 App Owner。
- AI-native generated UI 北极星已登记：未来 AI 应在有限、类型化、可组合的 UI spec / widget schema / action schema 空间中生成 proposal，并通过 preview / diff / reject / explain 回到 owner-controlled path。

## 未落地与明确禁止

- 尚未实现 semantic tree、layout tree、Widget tree、Text system、IME system 或 Accessibility system。
- 尚未实现 dirty region、diff、patch、incremental render、真实 draw op、真实 GPU batching 或 renderer state write。
- 尚未实现 AI provider、prompt、external agent、UI spec parser / compiler、widget generator、preview / diff runtime、真实 action side effect 或 public AI API。

## 当前 owner 链摘要

Scene / Renderer input 与 RenderCommand 链只提供 dehydrated renderer facts；Action Router 链提供 action intent / admission / routing / guarded handoff facts。未来 AI-native semantic layer 必须消费 layout / scene / hit-test / Action Router 的 owner facts，不能自建第二 truth。

未来 AI-generated UI proposal 同样必须消费 owner truth、schema、capability 与 Action Router facts；它只能生成可验证 proposal，不能成为 UI truth、renderer truth 或 app state truth。

## 关键文档链

- [Scene / Renderer input manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-scene-renderer-input-manifest.md)
- [RenderCommand / DisplayList command shape manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-display-list-command-shape-manifest.md)
- [RenderCommand material / batching hint manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)
- [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)
- [AI-native generated UI / semantic UI spec north-star intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-ai-native-generated-ui-semantic-spec-north-star-intake.md)
- [AI-native operability / foreign surface intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md)
- [doc language guard stabilization](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)

## 下次开 gate 前必须读取

开 semantic projection、AI action eligibility、AI generation contract、semantic UI spec、widget schema、AI-native WYSIWYG、generated UI preview / diff / reject loop、physical operability、stable / pending、layout-derived semantics、dirty region、IME cursor rect 或 A11y semantic projection gate 前，必须读取本 manifest、AI-native generated UI north-star intake、AI-native operability intake、Action Router manifest 和 Scene / Renderer input manifest。

## 推荐下一步

当前多数内容是 future radar，不是当前 renderer implementation permission。可选 future openings 包括 AI-native semantic UI spec north-star preflight、AI-generated UI preview / diff / reject loop preflight、AI-authored widget schema capability gate preflight、physical operability / occlusion gate preflight、interaction stability / pending gate preflight、layout-derived semantic association preflight。

## 禁止误读点

- 物理可见性 / 可操作性必须融合 layout、clip、z-order、occlusion、hit-test、viewport 和 modal gate。
- stable / pending 机制必须来自明确 owner，避免 AI 连点导致竞态。
- 空间邻近关系可由 layout / group / section 自动推导，但缺失证据时必须降级。
- AI 生成 UI 只能生成可验证 proposal / patch，不能绕过 owner truth、Action Router、schema validation 或 human / app owner acceptance。
- semantic UI spec 不能成为第二 truth source，也不能被误读为当前 public DSL、widget generator、prompt runtime 或 AI provider permission。
- 自绘路线未来要关注 dirty region、IME cursor rect 和 A11y semantic projection，但这些都不是当前 Renderer permission。

## 维护备注

若未来新增 semantic owner、action gateway owner、semantic UI spec owner 或 generated UI proposal owner，应在本 manifest 中记录 runtime input、canonical endpoint、zero-trust gate、schema / capability boundary 和 App Owner 关系。
