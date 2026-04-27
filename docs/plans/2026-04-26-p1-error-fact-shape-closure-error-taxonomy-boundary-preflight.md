# P1 Error Fact Shape Closure / Error Taxonomy Boundary Preflight

日期：2026-04-26

性质：docs-only preflight / error fact shape closure / error taxonomy boundary gate / no runtime code

状态：完成；不批准直接实现

范围：复盘 `P1 error fact shape first slice` 是否可以封账，并冻结 future error taxonomy 的边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime code，不修改 `CjguiInternalErrorFact`。

## 1. 本轮依据

直接依据：

- [P1 error fact shape closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
- [P1 error fact shape execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
- [P1 first internal runtime type closure / error fact shape boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)
- [P1 first internal runtime type closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
- [P1 error strategy surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)
- [P1 error strategy boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)
- [P1 runtime visibility / internal symbol boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)
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

## 2. `hasNativePayload: Bool = false` 证明了什么

`hasNativePayload: Bool = false` 证明：

- `CjguiInternalErrorFact` 可以承载一枚默认 internal、不可变、脱水的 `Bool` fact。
- 该 fact 可以表达当前 error fact 不携带 native payload。
- `runtime/cjgui` 可以在不引入 import、函数、方法、显式 init、public API、public C ABI 或 runtime behavior 的情况下通过 build。
- 最小 error fact shape 可以存在于 `runtime/cjgui/src/error.cj`，并继续保持 `cjgui` package 内部边界。

可封账 truth：

```text
error_fact_shape_refined=true
added_field_name=hasNativePayload
added_field_type=Bool
added_field_default=false
default_internal=true
native_payload_present=false
```

## 3. 它不证明什么

`hasNativePayload: Bool = false` 不证明：

- error strategy 已经存在。
- error taxonomy 已经存在。
- severity / category / code 已经存在。
- error enum 可以打开。
- `Result` type 可以打开。
- exception-like mechanism 可以打开。
- public runtime API 或 public C ABI 可以打开。
- app lifecycle、window lifecycle 或 platform adapter 已经能产生 / 消费 error facts。
- diagnostics / logs 可以成为 runtime state truth。
- smoke `last_error` 可以迁移。

当前 non-truth：

```text
error_strategy_present=false
error_taxonomy_present=false
error_enum_present=false
result_type_present=false
diagnostics_truth_system_present=false
```

## 4. `CjguiInternalErrorFact` 当前是否已经是 Error Strategy

结论：否。

`CjguiInternalErrorFact` 当前只是默认 internal 的 error facts boundary type。它只有一枚脱水 Bool 字段，不分类错误，不决定 recoverability，不推进 app/window/platform state，不提供查询入口，不提供 propagation model，也不执行 fail-closed policy。

因此当前必须保持：

```text
CjguiInternalErrorFact != error_strategy
error_strategy_implemented=false
```

## 5. 当前是否已经存在 Error Taxonomy

结论：否。

当前存在的是一个事实字段：

```text
hasNativePayload=false
```

它只表达“是否携带 native payload”。它不是 code、category、severity、source module、recoverability、message key、diagnostics id 或 serialization schema。

当前必须保持：

```text
taxonomy_defined=false
taxonomy_status=absent / not yet defined
```

## 6. 为什么不能直接定义 Error Enum

不能直接定义 error enum，因为：

- enum 会立即冻结 closed set 或部分 closed set。
- enum case 名称会成为长期 taxonomy precedent。
- enum 会迫使 severity、recoverability、source module、invalid usage、platform failure、stale target 等边界同步定型。
- enum 可能被误读为 public error API，即使未显式 `public`。
- app lifecycle、window lifecycle、platform adapter 尚未实现真实错误产生路径。
- 当前没有 execution card 授权 error enum。

因此：

```text
error_enum_allowed=false
```

## 7. 为什么不能直接定义 Result Type

不能直接定义 `Result` type，因为：

- `Result` 会冻结调用返回模型和错误传播模型。
- `Result` 会牵动函数签名，但当前仍禁止函数签名。
- `Result` 会过早决定 recoverable / fatal / degraded 如何被调用方处理。
- `Result` 容易变成 public runtime API 或 public C ABI 的影子契约。
- 当前 app/window/platform surface 仍没有行为实现。

因此：

```text
result_type_allowed=false
```

## 8. 为什么不能直接定义 Severity / Category / Code 字段

不能直接给 `CjguiInternalErrorFact` 添加 severity / category / code 字段，因为：

- severity 会冻结 fatal / recoverable / degraded 的分层语义。
- category 会冻结 closed / open taxonomy 的分组方式。
- code 会冻结编号、稳定性、serialization、diagnostics 和兼容策略。
- 字段类型若选 `String` / `Int` / enum / struct，会分别引入不同长期承诺。
- 字段出现后会暗示 app/window/platform 已经能产生这些分类，但当前没有该行为。
- message ownership、source module、correlation id、lifetime、threading、serialization、privacy 仍未冻结。

因此：

```text
severity_field_allowed=false
category_field_allowed=false
code_field_allowed=false
```

## 9. Future Taxonomy 的 Owner

如果未来定义 taxonomy，owner 倾向属于：

> `runtime/cjgui` error strategy module

该 owner 只负责错误分类语义和脱水 error fact 的 taxonomy 边界，不拥有 app state、window state、platform object ownership、diagnostics truth、public API 或 public C ABI。

owner 需要先回答：

- taxonomy 是 closed set 还是 open set。
- taxonomy 是否分层：fatal / recoverable / degraded、invalid usage、platform capability missing、stale handle / stale message。
- taxonomy 与 source module 是否解耦。
- taxonomy 是否可序列化。
- taxonomy 是否允许长期兼容承诺。
- taxonomy 是否只保持 internal。

当前只冻结 owner 倾向，不实现 owner。

## 10. Taxonomy 与 App / Window / Platform 的关系

app lifecycle 关系：

- app lifecycle 未来拥有 run、request quit、shutdown、queue acceptance 等 app-level policy。
- taxonomy 可以分类 app lifecycle 汇报的脱水 failure / degraded fact。
- taxonomy 不拥有 app state，不推进 app state transition。

window lifecycle 关系：

- window lifecycle 未来拥有 create、request close、destroy / release、stale target classification。
- taxonomy 可以分类 window lifecycle 汇报的 stale / invalid target / operation failure fact。
- taxonomy 不拥有 window identity、handle table、generation 或 destroyed state。

platform adapter 关系：

- platform adapter 未来拥有 native failure detail、platform object ownership 和 capability probing。
- taxonomy 只能消费 platform adapter 输出的脱水 readiness / failure / capability fact。
- taxonomy 不持有 AppKit、Metal、Objective-C、raw event、native handle、opaque native error object 或 callback truth。

## 11. Taxonomy 与 Diagnostics / Logs 的关系

diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。

边界：

```text
diagnostics_are_evidence=true
diagnostics_are_state_truth=false
logs_are_state_truth=false
taxonomy_is_state_truth=false
```

taxonomy 未来可以帮助 diagnostics 输出结构化 evidence，但不能让 log text、diagnostics field、artifact path 或 harness output 反向成为 runtime state truth。

AI / harness 可以读取 diagnostics 作为封账证据，但不能把 diagnostics 字段当成 public runtime contract。

## 12. Smoke `last_error` 为什么仍不能迁移为 Taxonomy

smoke `last_error` 仍不能迁移成 runtime error taxonomy，因为：

- 它是实验期全局错误槽，不是调用关联模型。
- 它不表达 source module、operation、window target、generation 或 queue / drain 关联。
- 它无法支撑多线程、async request 或未来多窗口。
- 它会被后续调用覆盖，不具备并发安全。
- 它容易把错误字符串或 diagnostics 文本误升格为 runtime state truth。
- 它属于 `labs/macos_bridge_smoke` 的证据，不属于 `runtime/cjgui` 的 taxonomy owner。

可迁移的是经验：

- 错误不能静默吞掉。
- platform readiness / failure 必须可观察。
- fatal / recoverable / degraded 倾向需要区分。
- native detail 必须脱水后才能进入 core。

不能迁移的是 `last_error` 形态、C ABI、全局状态或字符串 taxonomy。

## 13. Taxonomy 是否允许 Public / Public C ABI

当前结论：

```text
taxonomy_public_allowed=false
taxonomy_public_c_abi_allowed=false
```

理由：

- taxonomy 尚未冻结 closed / open set。
- public 会把内部分类变成兼容承诺。
- public C ABI 会要求稳定 layout、编号、生命周期和跨语言语义。
- 当前没有 public runtime API policy。
- 当前 smoke C ABI 已明确不得迁移。

未来若需要 public taxonomy，必须另开 public API / C ABI preflight，不能从本线顺手打开。

## 14. Taxonomy 禁止内容

future taxonomy 当前不允许包含：

- platform object。
- raw pointer。
- native handle。
- opaque native error object。
- stack trace blob。
- global `last_error`。
- thread-local `last_error`。
- AppKit / Metal / Objective-C identity。
- runloop truth。
- callback ownership。
- diagnostics log path 作为 truth。
- screenshot / hash / baseline / pixel diff evidence。

这些内容属于 platform adapter 内部、diagnostics evidence 或其他 future boundary，不属于 taxonomy first slice。

## 15. Taxonomy 应该如何表达

本轮只讨论，不实现。

候选表达方式包括：

- string key。
- integer code。
- enum。
- sealed type。
-默认 internal struct。

当前不选定具体形式。原因：

- string key 容易变成无约束字符串 taxonomy。
- integer code 需要编号空间、兼容策略和 serialization policy。
- enum 会冻结 closed set。
- sealed type 需要查证仓颉语法、visibility 和 module 约束。
- internal struct 仍需要字段 shape、owner、serialization 和 privacy 边界。

因此本轮倾向继续 docs-only。下一步如果要继续，只能先创建 `P1 error taxonomy boundary execution card`，并要求未来 first slice 在动代码前查证 CangjieSkills / 本地官方文档。

## 16. 定义 Taxonomy 前必须冻结的问题

定义 taxonomy 前至少必须冻结：

- owner：taxonomy owner 是否只属于 error strategy module。
- closed / open set：taxonomy 是否封闭，是否允许扩展。
- severity：fatal / recoverable / degraded 是否是 taxonomy 的一部分。
- recoverability：是否独立于 severity。
- source module：app lifecycle / window lifecycle / platform adapter / error strategy 如何标识。
- message ownership：human message、developer message、localization、redaction 谁负责。
- correlation id：是否需要 call-associated id / operation id。
- serialization：是否允许写入 diagnostics，格式是否稳定。
- privacy：是否允许包含路径、窗口标题、用户输入、native message。
- threading：taxonomy fact 是否可跨线程传递，是否不可变。
- lifetime：error fact 谁创建、谁消费、何时失效。
- compatibility：internal taxonomy 何时可以升级为 public，升级前需要哪些 gate。

这些未冻结前，不应新增 severity / category / code 字段。

## 17. 本轮 Stop-line

本轮保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不修改 harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`。
- 不新增字段。
- 不新增 type、function 或 import。
- 不定义 error enum。
- 不定义 `Result` type。
- 不定义 severity / category / code 字段。
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

## 18. 结论与 Next Opening

结论：

- `P1 error fact shape first slice` 可以封账。
- `hasNativePayload: Bool = false` 只证明最小脱水 fact 字段可编译。
- 当前仍没有 error taxonomy。
- 当前不能直接实现 error enum、`Result` type、severity / category / code 字段、public runtime API、public C ABI 或 error strategy。

推荐下一篇 docs-only opening：

`P1 error taxonomy boundary execution card`

该 execution card 仍不应授权完整 error strategy；最多只能为未来一个极窄 internal taxonomy marker / placeholder 做边界，并继续禁止 public API、public C ABI、Result type、exception-like mechanism、smoke `last_error` 迁移和 platform object 泄露。
