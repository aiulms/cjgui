# P1 First Internal Runtime Type Closure / Error Fact Shape Boundary Preflight

日期：2026-04-26

性质：docs-only preflight / first internal runtime type closure / error fact shape boundary gate / no runtime code

状态：完成；不批准直接实现

范围：复盘 `P1 first internal runtime type first slice` 是否可以封账，并冻结未来 `CjguiInternalErrorFact` 什么时候可以长出 shape、哪些 shape 当前必须禁止。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime code，不修改 `CjguiInternalErrorFact`。

## 1. 本轮依据

直接依据：

- [P1 first internal runtime type closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
- [P1 first internal runtime type execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)
- [P1 runtime internal symbol closure / first internal type boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)
- [P1 runtime internal symbol boundary closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md)
- [P1 runtime visibility / internal symbol boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)
- [P1 error strategy surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)
- [P1 error strategy boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)
- [P1 runtime build/package metadata closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)
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

## 2. `CjguiInternalErrorFact` 当前证明了什么

`CjguiInternalErrorFact` 当前证明：

- `runtime/cjgui` 可以承载第一枚有语义但无行为的默认 internal runtime type。
- 该 type 可以与现有 `package cjgui`、`cjpm.toml`、`output-type = "static"` 一起通过 `cjpm build`。
- 该 type 可以作为 future internal error facts boundary 的 compile-level placeholder。
- 当前 runtime source 可以在不新增 `public`、`import`、function、public runtime API、public C ABI、platform object wrapper 或 runtime behavior 的情况下继续推进。

当前可封账 truth：

```text
first_internal_error_fact_type_present=true
default_internal_type_buildable=true
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
import_present=false
error_enum_present=false
result_type_present=false
platform_object_wrapper_present=false
```

## 3. 它不证明什么

`CjguiInternalErrorFact` 不证明：

- error strategy 已实现。
- error fact shape 已冻结。
- error code taxonomy 已存在。
- error message ownership 已冻结。
- app lifecycle / window lifecycle / platform adapter 已经能产生或消费 error facts。
- diagnostics / logs 已经是 runtime error system。
- `last_error` 可以迁移。
- enum / Result type / exception-like mechanism 可以打开。
- public runtime API 或 public C ABI 可以打开。
- handle table / generation、多窗口或 async target message 可以打开。
- Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer 可以打开。

简化 non-truth：

```text
CjguiInternalErrorFact != error_strategy
CjguiInternalErrorFact != error_taxonomy
CjguiInternalErrorFact != diagnostics_truth
CjguiInternalErrorFact != public_api
```

## 4. 它当前是否是 Error Strategy

结论：否。

`CjguiInternalErrorFact` 当前只是一个默认 internal、空 struct、无行为的 first internal error facts boundary type。它不分类错误，不携带错误字段，不定义返回模型，不提供查询入口，不拥有 app/window/platform state，也不执行 fail-closed policy。

因此它可以封账为：

```text
error_strategy_present=false
error_fact_boundary_placeholder_present=true
```

## 5. 它当前是否允许携带字段

结论：当前不允许。

理由：

- 字段会立即冻结 shape precedent。
- 字段名会暗示 future error taxonomy、message ownership、source module、correlation id 或 serialization policy。
- 字段类型会迫使 visibility、privacy、threading、lifetime 和 diagnostics relationship 同步冻结。
- 当前还没有 execution card 授权修改 `CjguiInternalErrorFact`。
- 当前还没有冻结 error fact 是否允许被 app lifecycle、window lifecycle 或 platform adapter 直接构造、传递或存储。

所以当前必须保持：

```text
error_fact_fields_allowed=false
field_shape_authority_present=false
```

未来如果要新增字段，必须先创建受限 execution card。

## 6. 未来可能承载的脱水 Error Facts

未来 `CjguiInternalErrorFact` 可以考虑承载的只应是脱水 facts，而不是状态真相或平台对象。候选包括：

- error code 或 category，但必须先冻结 taxonomy。
- severity / recoverability，例如 fatal、recoverable、degraded，但必须先冻结分类语义。
- source module，例如 app lifecycle、window lifecycle、platform adapter、error strategy，但必须先冻结 owner 关系。
- operation 或 call site summary，但必须先冻结调用关联方式。
- correlation id / request id，但必须先冻结 lifetime、threading 和隐私策略。
- sanitized message key 或 diagnostic label，但必须先冻结 message ownership 和 localization / privacy 规则。
- platform capability missing summary，但必须由 platform adapter 输出脱水 fact，不能携带平台对象。
- stale handle / stale message summary，但必须等 handle / lifecycle boundary 冻结。

这些都只是 future candidates，不是当前批准字段。

## 7. 当前仍不允许进入的 Facts

当前不允许进入 `CjguiInternalErrorFact` 的内容：

- AppKit / Metal / Objective-C platform object。
- raw pointer、native handle、opaque native error object。
- global `last_error`。
- thread-local `last_error`。
- smoke C ABI error slot。
- stack trace blob。
- raw event object。
- runloop truth、callback truth、delegate identity。
- runtime state truth。
- app lifecycle state。
- window lifecycle state。
- platform adapter object ownership。
- diagnostics log path 或 artifact path。
- screenshot / raw bytes / hash / baseline / pixel diff evidence。

理由：

- error facts 必须是脱水、调用关联、结构化、非全局、并发安全的 future boundary。
- 平台对象和 raw native details 属于 platform adapter 内部边界。
- diagnostics 和 logs 只能作为 evidence，不能成为第二状态真相源。

## 8. Error Enum / Result Type / Exception-like Mechanism

当前结论：

```text
error_enum_allowed=false
result_type_allowed=false
exception_like_mechanism_allowed=false
```

原因：

- error enum 会过早冻结 taxonomy。
- Result type 会过早冻结调用 contract 和 public / internal API shape。
- exception-like mechanism 会过早冻结控制流、传播模型和 recoverability policy。
- 当前 app lifecycle、window lifecycle、platform adapter 仍没有行为实现或错误产生路径。
- 当前只允许讨论 first internal error fact shape，不允许实现完整 error strategy。

## 9. Public API / Public C ABI

当前结论：

```text
public_runtime_api_allowed=false
public_c_abi_allowed=false
```

`CjguiInternalErrorFact` 必须继续保持默认 internal，不得变成 public symbol，不得被包装成 public runtime API，不得映射为 C ABI，不得成为 smoke bridge migration path。

## 10. Error Facts 与 Diagnostics / Logs 的关系

error facts 未来可以为 diagnostics / logs 提供结构化 evidence，但 diagnostics / logs 不能反过来成为 runtime state truth。

边界：

```text
diagnostics_are_evidence=true
diagnostics_are_state_truth=false
logs_are_state_truth=false
```

具体要求：

- diagnostics 可以帮助 closure review 说明发生了什么。
- diagnostics 不能替代 app lifecycle state、window lifecycle state 或 platform adapter truth。
- logs 不能成为“最近一次错误”的唯一持有处。
- AI / harness 可以读取 diagnostics 作证据，但不能把 diagnostics 字段当作 public runtime contract。

## 11. Error Facts 与 App / Window / Platform 的关系

app lifecycle 关系：

- app lifecycle 未来拥有 run、request quit、shutdown、queue acceptance 等 app-level policy。
- error facts 只能记录 app lifecycle 汇报的脱水 failure / degraded summary。
- error facts 不拥有 app state，不推进 app state transition。

window lifecycle 关系：

- window lifecycle 未来拥有 create、request close、destroy / release、stale target classification。
- error facts 只能记录 window lifecycle 汇报的脱水 stale / invalid target / operation failure summary。
- error facts 不拥有 window identity、handle table、generation 或 destroyed state。

platform adapter 关系：

- platform adapter 未来拥有 native failure details、platform object ownership 和 platform capability probing。
- error facts 只能接收 platform adapter 输出的脱水 readiness / failure / capability summary。
- error facts 不持有 AppKit、Metal、Objective-C、raw event、native handle 或 callback truth。

## 12. Smoke `last_error` 为什么仍不能迁移

smoke `last_error` 仍不能迁移为 runtime error system，因为：

- 它是实验期全局错误槽，不是调用关联模型。
- 它不表达 app operation、window target、future generation 或 queue / drain 关联。
- 它不适合多线程、async request 或未来多窗口。
- 它容易被后续调用覆盖，不能并发安全地表达具体失败。
- 它可能把错误字符串、日志或 diagnostics 误升格为 runtime state truth。
- 它属于 `labs/macos_bridge_smoke` 的证据，不是 `runtime/cjgui` 的 public API。

可迁移的是经验：

- 错误不能静默吞掉。
- platform readiness / failure 需要可观察。
- fatal / recoverable / degraded 倾向需要区分。
- native details 必须脱水后才能进入 core。

不能迁移的是 `last_error` 形态本身。

## 13. 未来添加字段前必须冻结的问题

如果未来要给 `CjguiInternalErrorFact` 添加字段，必须先冻结：

- code taxonomy：code/category 从哪里来，是否 enum，是否 string key。
- message ownership：谁拥有 human message、developer message、localization 和 redaction。
- source module：app/window/platform/error source 如何表达，是否允许跨 module。
- correlation id：是否需要 call-associated id、request id 或 operation id。
- lifetime：error fact 谁创建，谁消费，是否可缓存，何时失效。
- threading：是否可跨线程传递，是否不可变，是否并发安全。
- serialization：是否允许写入 diagnostics，格式如何，是否稳定。
- privacy：是否允许包含路径、窗口标题、用户输入、native message。
- platform detail policy：native code / native domain 是否允许脱水后进入 core。
- fail-closed policy：unknown category 或 incomplete fact 如何处理。
- diagnostics relationship：哪些字段可被 harness / AI 读取，哪些不能成为 state truth。
- visibility：是否仍保持默认 internal，是否禁止 public re-export。
- test boundary：未来如何测试 internal fact shape，是否需要另开 test preflight。

没有上述冻结，不应给 `CjguiInternalErrorFact` 添加字段。

## 14. 本轮 Stop-line

本轮明确不做：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke/`。
- 不修改 harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime code。
- 不修改 `CjguiInternalErrorFact`。
- 不新增字段。
- 不新增 type、function 或 import。
- 不定义 error enum。
- 不定义 Result type。
- 不定义 exception-like mechanism。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error strategy。
- 不迁移 smoke `last_error`。
- 不实现 app lifecycle、window lifecycle 或 platform adapter behavior。
- 不进入 handle table / generation、多窗口或 async target message。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 15. 结论

当前 `CjguiInternalErrorFact` 可以封账。

封账含义：

- 它是第一枚默认 internal、最小语义 runtime type。
- 它只证明 runtime package 可以承载一个有语义但无行为的 internal error facts boundary type。
- 它不是 error strategy。
- 它没有字段。
- 它没有 public API / public C ABI。
- 它没有行为。
- 它不迁移 smoke `last_error`。

下一步如果继续，应创建 docs-only execution card：

> `P1 error fact shape execution card`

该 execution card 仍不应直接实现完整 error strategy。它最多只能授权一个极窄的 internal error fact shape first slice，并且必须继续禁止 public API、public C ABI、error enum、Result type、exception-like mechanism、platform object、smoke migration、runtime behavior 和 diagnostics-as-state-truth。
