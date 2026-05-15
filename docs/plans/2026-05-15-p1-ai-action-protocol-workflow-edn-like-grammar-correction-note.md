# P1 AI Action Protocol workflow / EDN-like grammar 纠偏记录

日期：2026-05-15

性质：docs-only correction note / future protocol guard / no implementation

状态：已登记；不批准当前实现

## 背景

本 note 记录一次 AI-native workflow / EDN-like grammar 讨论后的纠偏口径。外部建议里有可吸收的方向，例如 workflow proposal、action graph、audit trail、S-expression / EDN-like 数据形状，但也容易把 workflow layer、Action Gateway 和 AI-authored surface 的权限边界混在一起。

当前结论是：这些建议值得作为 future protocol guard 记录，但不能升级为当前 runtime、Renderer、native bridge、Action Router 或 public DSL 实现任务。

## 纠偏结论

### Workflow layer 的法定位置

Workflow layer 未来可以是受控 proposal producer / adapter / requestor，而不是 UI truth owner，也不是可以绕过 Action Gateway 的下游执行权力中心。

它可以消费 semantic snapshot、ActionResult、owner-visible state 或用户意图 evidence，并生成候选 workflow proposal。但任何原子动作必须被解析成 typed `ActionRequest`，经过 owner-controlled Action Gateway，再由 App Owner accept / reject / defer / needs confirmation。

禁止误读：

- Workflow layer 不能直接改 UI truth、renderer state、semantic tree、scene cache 或 native resource。
- Workflow layer 不能批量强制批准 action chain。
- Workflow layer 不能把 rollback、side effect、notification、file operation 或 UI patch 当成已授权动作。
- Workflow layer 不能替代 Action Gateway 的 scope / generation / target / evidence 校验。

### Workflow proposal 只能是未来候选形状

未来可以评估的 proposal shape 包括 action chain、diff proposal、semantic fork、reversible action graph 和 audit trail。它们只是一种 AI-friendly planning surface。

落地前必须满足：

- 每个 step 都可拆成独立 typed `ActionRequest`。
- 每个 `ActionRequest` 都有明确 scope、generation、target、evidence 和 owner boundary。
- 依赖 step 只能影响排队和失效策略，不能绕过 admission。
- rollback action 也必须重新过 Gateway。
- audit trail 必须来自 admission / owner result 记录，而不是 AI 事后自述。

### S-expression / EDN-like grammar 的口径

[AI Action Protocol Experiment](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md) 已将 Lisp-style S-expression 登记为 AI-authored Action Command 的 preferred north-star candidate。本 note 补充：未来可以评估 restricted S-expression / EDN-like data grammar，但不得默认采纳完整 Clojure EDN 或任意 Lisp 能力。

推荐口径：

> CJGUI restricted S-expression / EDN-like data grammar.

这表示它可以吸收 EDN 的数据表达优点，例如关键字、向量式参数、map-like metadata 或更稳定的 literal shape；但必须保留受限 AST、固定 allowlist、fail-closed parser 和 owner-controlled Gateway。

明确禁止：

- `eval`。
- macro。
- user-defined function。
- reader extension。
- tagged literal。
- arbitrary symbol execution。
- runtime reflection execution。
- 通过 symbol 拼接调用内部函数。
- AI-authored macro 或 AI-authored grammar extension。

可信 compiler / expander 未来可以作为内部实现细节被评估，但它不能成为 AI-authored public surface，也不能让 AI 定义新语义。

## 当前不做的预埋

当前 Renderer / native bridge 物理层不应为了未来 workflow 提前加入 `submitToGateway()` 之类调用点。现在的主线仍在 Renderer / native bridge 的 platform object、Metal resource、visible-window harness 和 draw runway 上，过早把 Action Gateway hook 接入物理层会污染 owner 边界。

正确顺序仍是：

1. 先稳定 semantic / input / action gate 的 owner truth。
2. 再定义 restricted grammar 与 typed `ActionRequest`。
3. 再评估 workflow proposal producer。
4. 最后才讨论 owner-controlled queue / executor / rollback / audit integration。

## Stop-line

本 note 不批准：

- parser / compiler implementation。
- workflow runtime。
- public DSL。
- AI provider / prompt runtime。
- semantic tree implementation。
- Action Router 新 capability。
- renderer / native bridge / runtime code change。
- `submitToGateway()` hook。
- public API / public C ABI。
- current Renderer next opening change。

## Future openings

可选 future openings：

- `P1 AI action protocol restricted S-expression / EDN-like grammar preflight`
- `P1 workflow proposal producer / Action Gateway adapter preflight`

这两个 opening 只在 semantic snapshot、owner-controlled Action Gateway、typed `ActionRequest` 和 audit record 的最小边界足够清楚后再打开。

## 设计意图出口自检

- 本轮改变主题状态：是，AI-native semantic / action gateway 主题新增 workflow / grammar correction guard。
- 本轮改变 canonical tail / endpoint：否。
- 本轮改变 runtime owner / truth / stop-line：否，docs-only。
- 本轮改变当前 Renderer 唯一 next opening：否。
- 已同步 topic manifest：`docs/plans/topic-manifests/ai-native-semantic-action-gateway.md`。
