# P1 Internal Input Routing Boundary Bundle Closure Review

日期：2026-04-30

## Landed Scope

- 修改 `runtime/cjgui/src/runtime_state.cj`，新增 dehydrated internal input routing boundary。
- 修改 `runtime/cjgui/README.md`，记录 routing result、preserve intent 与 stop-line。
- 更新 `GUI_TASK_TRACKER.md` 与 `docs/plans/README.md`，把 next opening 收束到 input-to-runtime ingress decision。

## New Internal Symbols

- `CjguiInternalInputRoutingResult`
- `cjguiInternalRouteInputIntentAdmission(admission)`
- `cjguiInternalExecuteDefaultInputRoutingDraft()`

## Routing Semantics

- Routing consumes only `CjguiInternalInputIntentAdmission`.
- Admitted admission with no defer / block becomes a future runtime ingress candidate.
- Defer-only admission stays deferred.
- Blocked or inconsistent admission fails closed as blocked.
- `didPreserveInputIntent` means the dehydrated intent is carried forward as a candidate; it does not mean enqueue, event dispatch, scheduler tick, runtime step, or runtime cycle execution.

## Boundary

- This is not a platform event object and does not store native handle / raw pointer / callback.
- It does not write queue / event loop / scheduler state.
- It does not execute a runtime cycle, does not call `cjguiInternalExecuteRuntimeCycle`, and does not write global runtime state.
- It does not add public runtime API / public C ABI, Request + Report double layer, five-piece sanity helper, or replay / admission / dry-run / outcome wrapper revival.

## GitNexus Impact

- `CjguiInternalInputIntentAdmission`: UNKNOWN / not found.
- `cjguiInternalEvaluateInputIntentAdmission`: UNKNOWN / not found.
- `cjguiInternalExecuteDefaultInputIntentAdmissionDraft`: UNKNOWN / not found.
- `runtime_state.cj` file-level upstream fallback: LOW risk, direct callers 0, affected processes 0, impacted count 0.
- No HIGH / CRITICAL impact was reported.

## Verification

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-internal-input-routing-boundary-target --skip-script`: passed with existing unused warnings only.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed.
- `git diff --check`: passed.
- Closure link check: passed.
- Forbidden scope check: passed.
- `CANGJIE_ISSUE_LEDGER` update: not triggered.

## Next Opening

`P1 internal input routing closure / next input-to-runtime ingress decision`
