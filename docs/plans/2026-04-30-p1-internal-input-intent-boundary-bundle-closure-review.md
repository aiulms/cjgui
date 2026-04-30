# P1 Internal Input Intent Boundary Bundle Closure Review

日期：2026-04-30

## Landed Scope

- 修改 `runtime/cjgui/src/runtime_state.cj`，新增 dehydrated internal input intent ingress model。
- 修改 `runtime/cjgui/README.md`，记录 source / kind / present / admission 语义和 stop-line。
- 更新 `GUI_TASK_TRACKER.md` 与 `docs/plans/README.md`，把 next opening 收束到 input routing decision。

## New Internal Symbols

- `CjguiInternalInputIntentSource`
- `CjguiInternalInputIntentKind`
- `CjguiInternalInputIntent`
- `CjguiInternalInputIntentAdmission`
- `cjguiInternalDefaultInputIntentSource()`
- `cjguiInternalDefaultInputIntentKind()`
- `cjguiInternalBuildInputIntent(source, kind, isInputIntentPresent)`
- `cjguiInternalInputIntentSourceIsValid(source)`
- `cjguiInternalInputIntentKindIsValid(kind)`
- `cjguiInternalEvaluateInputIntentAdmission(intent)`
- `cjguiInternalExecuteDefaultInputIntentAdmissionDraft()`

## Behavior

- Source is valid only when exactly one of synthetic / platform-origin / user-origin is true.
- Kind is valid only when exactly one of activation / text / pointer / lifecycle is true.
- Absent intent defers.
- Present intent with valid source and kind can be admitted.
- Invalid source or kind fails closed as blocked.
- Default admission uses synthetic activation present and opens.

## Boundary

- This is a dehydrated internal ingress value, not a platform event object.
- It stores no native handle, raw pointer, platform callback, AppKit object, Metal object, or Objective-C object.
- It does not write queue / event loop / scheduler state.
- It does not execute a runtime cycle, does not call `cjguiInternalExecuteRuntimeCycle`, and does not write global runtime state.
- It does not add public runtime API / public C ABI, Request + Report double layer, five-piece sanity helper, or replay / admission / dry-run / outcome wrapper revival.

## GitNexus Impact

- `CjguiInternalRuntimeStateStoreTransition`: UNKNOWN / not found.
- `cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft`: UNKNOWN / not found.
- `runtime_state.cj` file-level upstream fallback: LOW risk, direct callers 0, affected processes 0, impacted count 0.
- No HIGH / CRITICAL impact was reported.

## Verification

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-internal-input-intent-boundary-target --skip-script`: passed with existing unused warnings only.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed.
- `git diff --check`: passed.
- Forbidden scope check: passed.
- `CANGJIE_ISSUE_LEDGER` update: not triggered.

## Next Opening

`P1 internal input intent boundary closure / next input routing decision`
