# P1 Error Taxonomy Marker Closure / Recoverability Boundary Preflight

日期：2026-04-26

性质：docs-only preflight / taxonomy marker closure / recoverability boundary gate / no runtime code

状态：完成；不批准直接实现

范围：复盘 `P1 error taxonomy marker first slice` 是否可以封账，并冻结 future recoverability boundary。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime code，不修改 `CjguiInternalErrorFact`，不修改 `CjguiInternalErrorTaxonomyMarker`。

## 1. 本轮依据

直接依据：

- [P1 error taxonomy marker closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
- [P1 error taxonomy boundary execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)
- [P1 error fact shape closure / error taxonomy boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)
- [P1 error fact shape closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
- [P1 error fact shape execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
- [P1 first internal runtime type closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
- [P1 error strategy surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)
- [P1 error strategy boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

当前 runtime package 只读确认：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)

## 2. `CjguiInternalErrorTaxonomyMarker` 证明了什么

`CjguiInternalErrorTaxonomyMarker` 证明：

- `runtime/cjgui` 可以承载一枚默认 internal 的 taxonomy marker / placeholder type。
- 该 marker 可在不使用 `public`、不写 import、不定义字段、不定义函数 / 方法 / 显式 init、不实现 runtime behavior 的情况下通过 build。
- taxonomy boundary 可以作为 internal compile-level placeholder 被标记出来。
- marker 可以诚实表达：taxonomy boundary exists but taxonomy is not yet defined。

可封账 truth：

```text
taxonomy_marker_added=true
taxonomy_marker_name=CjguiInternalErrorTaxonomyMarker
taxonomy_marker_default_internal=true
taxonomy_marker_has_fields=false
taxonomy_boundary_exists=true
taxonomy_defined=false
```

## 3. 它不证明什么

`CjguiInternalErrorTaxonomyMarker` 不证明：

- error taxonomy 已经存在。
- recoverability policy 已经存在。
- fatal / recoverable / degraded 已经成为 enum 或字段。
- severity / category / code 已经存在。
- `Result` type 可以打开。
- exception-like mechanism 可以打开。
- error strategy 已经实现。
- public runtime API 或 public C ABI 可以打开。
- app lifecycle、window lifecycle 或 platform adapter 已经能产生 / 消费 recoverability facts。
- diagnostics / logs 可以成为 runtime state truth。
- smoke `last_error` 可以迁移。

当前 non-truth：

```text
taxonomy_defined=false
recoverability_policy_present=false
severity_field_present=false
category_field_present=false
code_field_present=false
result_type_present=false
error_strategy_implemented=false
```

## 4. 当前是否已经存在 Error Taxonomy

结论：否。

当前只有两个 error-side internal type：

- `CjguiInternalErrorFact`：包含一枚脱水 Bool fact，表示当前不携带 native payload。
- `CjguiInternalErrorTaxonomyMarker`：空 marker，只表示 taxonomy boundary exists but taxonomy is not yet defined。

它们都不定义 closed set、open set、severity、recoverability、category、code、source module、message ownership、correlation id、serialization 或 public error API。

必须继续保持：

```text
error_taxonomy_present=false
taxonomy_defined=false
```

## 5. 当前是否已经存在 Recoverability Policy

结论：否。

当前文档中出现的 fatal / recoverable / degraded 仍只是 future vocabulary 和错误处理哲学，不是仓颉 enum、字段、type、function、policy table、state transition 或 public API。

当前不存在：

- recoverable / fatal / degraded enum。
- recoverability field。
- retry policy。
- degraded mode contract。
- caller responsibility model。
- lifecycle state transition rule。

必须继续保持：

```text
recoverability_policy_present=false
recoverability_enum_present=false
recoverability_field_present=false
```

## 6. Recoverability 与 Taxonomy 的关系

recoverability 是 taxonomy 的一个 future 维度候选，但不能等同于 taxonomy 本身。

可能关系：

- taxonomy 可描述错误的身份或类别。
- recoverability 可描述调用方 / lifecycle owner 是否可以继续、重试、降级或必须 fail closed。
- severity 可描述影响程度。
- code 可描述稳定识别符。

这些维度可能重叠，但不能在没有 owner、closed / open set、serialization、privacy 和 caller responsibility 之前混写成一个字段或 enum。

当前边界：

```text
recoverability_may_be_taxonomy_dimension=true
recoverability_is_defined_taxonomy=false
recoverability_is_public_contract=false
```

## 7. Recoverability 与 Error Strategy 的关系

recoverability 是 future error strategy 可能使用的分类维度，但当前不是 error strategy implementation。

future error strategy 可能需要回答：

- 哪些错误必须 fail closed。
- 哪些错误允许 caller retry。
- 哪些错误允许 degraded continuation。
- 哪些错误表示 invalid usage / contract violation。
- 哪些错误来自 platform capability missing。
- 哪些错误表示 stale handle / stale message。

当前仍禁止：

- 定义 recoverability enum。
- 定义 `Result` type。
- 定义 error propagation model。
- 定义 public API。
- 让 diagnostics 字段成为 strategy truth。

## 8. Recoverability 与 App / Window / Platform 的关系

app lifecycle 关系：

- app lifecycle 未来拥有 run、quit、shutdown、queue acceptance 和 app-level state transition。
- recoverability 未来可以辅助分类 app lifecycle 报告的脱水 failure。
- recoverability 不拥有 app state，不决定 state transition。

window lifecycle 关系：

- window lifecycle 未来拥有 create、request close、destroy / release、stale target classification。
- recoverability 未来可以辅助分类 stale message、duplicate close、destroy after release 等 window failure。
- recoverability 不拥有 window identity、handle table、generation 或 destroyed state。

platform adapter 关系：

- platform adapter 未来拥有 native failure detail、capability probing 和平台对象。
- recoverability 未来只能消费 adapter 输出的脱水 capability / readiness / failure facts。
- recoverability 不持有 AppKit、Metal、Objective-C、native handle、raw pointer、runloop truth 或 native error object。

## 9. Recoverability 与 Diagnostics / Logs 的关系

diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。

future recoverability 可以帮助 diagnostics 输出更清楚的 evidence，例如某个 operation 被分类为 degraded candidate 或 fail-closed candidate。但 diagnostics field、log text、artifact path、harness output 不能反向定义 runtime state、taxonomy 或 recoverability policy。

必须继续保持：

```text
diagnostics_are_evidence=true
diagnostics_are_state_truth=false
logs_are_state_truth=false
recoverability_diagnostics_truth_system=false
```

## 10. 是否可以现在定义 Recoverable / Fatal / Degraded Enum

结论：否。

不能现在定义 recoverable / fatal / degraded enum，因为：

- enum 会冻结 closed set。
- fatal / recoverable / degraded 可能是 severity、recoverability、policy 或 diagnostics vocabulary，边界尚未分清。
- app lifecycle、window lifecycle、platform adapter 尚未产生真实错误路径。
- caller retry、degraded continuation、fail-closed transition 仍未冻结。
- enum case 名称会成为长期 precedent。
- 当前没有 execution card 授权 recoverability enum。

必须继续保持：

```text
recoverability_enum_allowed=false
fatal_recoverable_degraded_enum_allowed=false
```

## 11. 是否可以现在定义 Severity / Category / Code 字段

结论：否。

不能现在定义 severity / category / code 字段，因为：

- severity 会过早冻结影响分层。
- category 会过早冻结 closed / open taxonomy 分组方式。
- code 会要求编号空间、稳定性、兼容、serialization 和 privacy policy。
- 字段一旦进入 `CjguiInternalErrorFact`，会暗示 app/window/platform 已经能产生这些分类。
- 字段一旦进入 taxonomy marker，会把 marker 从 placeholder 升级成实际 taxonomy shape。

必须继续保持：

```text
severity_field_allowed=false
category_field_allowed=false
code_field_allowed=false
```

## 12. 是否可以现在定义 Result Type

结论：否。

不能现在定义 `Result` type，因为：

- `Result` 会冻结调用返回模型。
- `Result` 会牵动函数签名，但当前不允许新增函数。
- `Result` 会把 recoverability 与调用方责任绑定得过早。
- `Result` 容易成为 public runtime API 或 public C ABI 的影子契约。
- 当前 app/window/platform 行为都还未实现。

必须继续保持：

```text
result_type_allowed=false
```

## 13. 是否可以修改 `CjguiInternalErrorFact` 或 Taxonomy Marker

结论：否。

本轮不能修改：

- `CjguiInternalErrorFact`
- `CjguiInternalErrorTaxonomyMarker`

原因：

- `CjguiInternalErrorFact` 的唯一字段 `hasNativePayload: Bool = false` 已经封账为最小脱水 shape，不代表 taxonomy 或 recoverability 已打开。
- `CjguiInternalErrorTaxonomyMarker` 是空 marker，目的正是防止“marker 被误读成 taxonomy 已定义”。
- recoverability 需要先执行卡冻结，不能在 closure / preflight 中顺手变成字段或 enum。

## 14. Public API / Public C ABI

当前结论：

```text
recoverability_public_api_allowed=false
recoverability_public_c_abi_allowed=false
```

理由：

- recoverability policy 尚未存在。
- public API 会把内部错误哲学变成兼容承诺。
- public C ABI 会要求稳定 layout、编号、生命周期、跨语言语义和 threading contract。
- smoke C ABI 明确不能迁移。
- 当前 `runtime/cjgui` 仍没有 public runtime API policy。

## 15. Smoke `last_error` 迁移

结论：不允许。

smoke `last_error` 不能迁移为 recoverability，因为：

- 它是全局 mutable last-error，不是调用关联模型。
- 它没有 operation、target、generation、threading 或 lifecycle transition context。
- 它无法表达 stale message、queue / drain、multi-window 或 async request。
- 它会被后续调用覆盖，不并发安全。
- 它容易把字符串 / diagnostics 文本误升格为 state truth。

可迁移的仍只是经验：

- 错误需要可观察。
- platform readiness / failure 不能静默吞掉。
- fatal / recoverable / degraded 倾向需要未来区分。
- native detail 必须脱水。

## 16. Recoverability 禁止内容

future recoverability 当前不允许包含：

- platform object。
- raw pointer。
- native handle。
- native error object。
- opaque native error object。
- stack trace blob。
- global `last_error`。
- thread-local `last_error`。
- AppKit / Metal / Objective-C identity。
- runloop truth。
- callback ownership。
- diagnostics log path 作为 truth。
- screenshot / hash / baseline / pixel diff evidence。

这些属于 platform adapter 内部、diagnostics evidence 或其他 future boundary，不属于 recoverability first slice。

## 17. Future Recoverability Owner

future recoverability owner 倾向属于：

> `runtime/cjgui` error strategy module

但该 owner 仍不是当前实现。它未来只负责 recoverability 语义边界，不拥有 app state、window state、platform object ownership、diagnostics truth、public API 或 public C ABI。

owner 需要先回答：

- recoverability 是独立维度，还是 taxonomy 的子维度。
- recoverability set 是 closed 还是 open。
- fatal / recoverable / degraded 与 severity 的关系。
- recoverable 是否意味着 retry allowed。
- degraded 是否意味着 operation success with reduced guarantee。
- fatal 是否一定触发 app / window lifecycle transition。
- caller responsibility 如何表达。

## 18. 定义 Recoverability 前必须冻结的问题

定义 recoverability 前至少必须冻结：

- owner：recoverability 是否只属于 error strategy module。
- closed / open set：recoverability 值是否封闭。
- retry semantics：recoverable 是否允许重试、由谁重试、何时重试。
- degraded semantics：degraded 是否允许继续、如何暴露 diagnostics、是否影响 state truth。
- fatal semantics：fatal 是否总是 fail closed、是否触发 shutdown 或 target destruction。
- caller responsibility：调用方看到 recoverable / degraded / fatal 后必须做什么。
- lifecycle state transition：app / window 是否因 recoverability 推进 state。
- serialization：recoverability 是否写入 diagnostics，是否稳定。
- privacy：recoverability 是否可能间接暴露用户输入、路径、窗口标题或 native message。
- threading：recoverability fact 是否可跨线程传递，是否不可变。
- lifetime：recoverability fact 谁创建、谁消费、何时失效。

这些未冻结前，不应新增 enum、字段、`Result` type 或 public surface。

## 19. 本轮 Stop-line

本轮保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不修改 harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`。
- 不修改 `CjguiInternalErrorTaxonomyMarker`。
- 不新增字段。
- 不新增 type、function 或 import。
- 不定义 recoverability enum。
- 不定义 fatal / recoverable / degraded enum。
- 不定义 severity / category / code 字段。
- 不定义 `Result` type。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error strategy。
- 不迁移 smoke `last_error`。
- 不实现 app lifecycle、window lifecycle 或 platform adapter behavior。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 20. 结论与 Next Opening

结论：

- `P1 error taxonomy marker first slice` 可以封账。
- `CjguiInternalErrorTaxonomyMarker` 只证明 taxonomy boundary marker 可构建。
- 当前仍没有 error taxonomy。
- 当前仍没有 recoverability policy。
- 当前不能直接定义 recoverable / fatal / degraded enum、severity / category / code 字段、`Result` type、public runtime API、public C ABI 或 error strategy。
- 当前不能修改 `CjguiInternalErrorFact` 或 `CjguiInternalErrorTaxonomyMarker`。

推荐下一篇 docs-only opening：

`P1 error recoverability boundary execution card`

该 execution card 仍不应授权完整 error strategy；最多只能为未来一个极窄 internal recoverability marker / placeholder 做边界，并继续禁止 public API、public C ABI、Result type、recoverability enum、severity / category / code 字段、smoke `last_error` 迁移和 platform object 泄露。
