# P1 Input-To-Runtime Ingress Manifest

日期：2026-04-30

## Ingress Mainline

- `CjguiInternalInputIntentSource` / `CjguiInternalInputIntentKind` / `CjguiInternalInputIntent`：脱水 input facts，不持有平台对象。
- `CjguiInternalInputIntentAdmission`：判断 present intent 是否可作为 internal input admission。
- `CjguiInternalInputRoutingResult`：把 admitted input intent 标记为 future runtime ingress candidate。
- `CjguiInternalInputRuntimeIngress`：组合 input routing result 与 runtime state boundary context。
- `CjguiInternalRuntimeStateStoreTransition`：提供当前 value-style runtime state store transition context。

Default path:

- `cjguiInternalExecuteDefaultInputIntentAdmissionDraft()`
- `cjguiInternalExecuteDefaultInputRoutingDraft()`
- `cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft()`
- `cjguiInternalExecuteDefaultInputRuntimeIngressDraft()`

## Acceptance Semantics

- admitted routing + open state transition => `canEnterRuntimeIngress = true`。
- defer-only routing 或 defer-only state transition => defer。
- blocked 或 inconsistent routing / state transition => fail-closed blocked。
- preserve input intent 只表示 carried dehydrated candidate，不是 enqueue、dispatch、scheduler tick、runtime cycle execution 或 state write。

## Owner / Truth Boundary

- `runtime_state.cj` 当前仍 owns dehydrated ingress model。
- 这不是 platform adapter fact。
- 这不是 app/window lifecycle mutation。
- 这不是 queue / event loop / scheduler。
- 这不是 public runtime API 或 public C ABI。

## Stop Lines

- no platform object / native handle / raw pointer
- no queue / event loop / scheduler
- no runtime cycle execution
- no global state write
- no public API / C ABI
- no Request + Report layer
- no five-piece sanity
- no behavior wrapper revival

## File-Size Warning

`runtime_state.cj` 当前约 `10065` 行，处于 `>8000` critical warning 区间。下一次 code-bearing prompt 如果允许修改该文件，必须先做 file-size / owner split check，并说明：

- 当前行数与档位。
- 为什么必须继续触碰 critical 文件。
- 是否新增 owner / subsystem / truth 边界。
- 为什么暂不先做 module extraction。
- 后续 split / module extraction 候选。

优先候选包括 input ingress symbols、legacy diagnostics tail、execution commit tail、state store transition tail 的 owner split 或 module extraction。

## Next Reasonable Boundary

`P1 internal input-to-runtime ingress stabilization closure / next scheduler-or-action-router decision`

下一轮应做 docs-only boundary decision：封账 ingress stabilization，并判断是进入 scheduler tick intent、Action Router 前置 decision，还是先做 owner split / module extraction。
