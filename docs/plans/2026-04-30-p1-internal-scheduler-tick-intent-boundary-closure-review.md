# P1 Internal Scheduler Tick Intent Boundary Closure Review

日期：2026-04-30

## Scope

本轮完成 `P1 internal scheduler tick intent boundary bundle implementation`，新增第一个 internal-only / dehydrated scheduler tick intent owner。它是 future event loop / cycle pacing 的前置事实模型，不是 scheduler implementation。

实际修改文件：

- [runtime_scheduler.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scheduler.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [2026-04-30-p1-internal-scheduler-tick-intent-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-internal-scheduler-tick-intent-boundary-closure-review.md)

## Landed Symbols

新增 owner 文件：[runtime_scheduler.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scheduler.cj)。

新增 scheduler tick symbols：

- `CjguiInternalSchedulerTickSource`
- `CjguiInternalSchedulerTickKind`
- `CjguiInternalSchedulerTickIntent`
- `CjguiInternalSchedulerTickAdmission`
- `cjguiInternalDefaultSchedulerTickSource()`
- `cjguiInternalDefaultSchedulerTickKind()`
- `cjguiInternalBuildSchedulerTickIntent(source, kind, isSchedulerTickPresent)`
- `cjguiInternalSchedulerTickSourceIsValid(source)`
- `cjguiInternalSchedulerTickKindIsValid(kind)`
- `cjguiInternalEvaluateSchedulerTickAdmission(intent)`
- `cjguiInternalExecuteDefaultSchedulerTickAdmissionDraft()`

Admission / validation 语义：

- source 必须在 synthetic / frame-pacing / deferred-work 中 exactly one。
- kind 必须在 cycle-preparation / render-preparation / idle-maintenance 中 exactly one。
- absent tick => defer。
- invalid source / kind => fail-closed blocked。
- default draft 使用 synthetic + cycle-preparation + present，结果为 admitted。

## Owner Split Guard

`runtime_state.cj` 当前 10065 行，处于 `>8000` critical warning 区间。本轮执行 owner split guard：

- 没有修改 `runtime_state.cj`。
- 没有把 scheduler subsystem 继续塞进 `runtime_state.cj`。
- 新增 `runtime_scheduler.cj` 作为 scheduler tick owner 文件。
- 新文件没有既有 GitNexus symbol impact history；本轮未编辑既有 symbol，因此未触发 HIGH / CRITICAL impact。
- 后续 scheduler-to-runtime integration 若需要连接 `runtime_state.cj`，必须重新执行 file-size / owner split check，并说明是否继续拆分。

## Stop Lines

本轮不是：

- event loop。
- queue / drain。
- scheduler implementation。
- platform timer / callback。
- AppKit / Metal / Objective-C bridge。
- runtime cycle execution。
- process-wide runtime global state write。
- public runtime API / public C ABI。
- Request + Report 双层。
- 五件套 sanity helper。

`runtime_scheduler.cj` 只保存脱水 value-style scheduler tick facts，不保存 native handle、raw pointer、runloop source 或 callback。

## Verification

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui && source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-scheduler-tick-intent-boundary-target --skip-script`：通过，仅有既有 unused warnings 与新 internal skeleton unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `cd /Users/jiangxuanyang/Desktop/cangjie && git diff --check`：通过。
- closure 可从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 与 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。
- Markdown 绝对链接检查：通过。
- forbidden 文件检查：未修改 `runtime/cjgui/cjpm.toml`、`labs/macos_bridge_smoke` tracked source、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- 未新增 platform timer / callback、native handle / raw pointer、queue / event loop / scheduler implementation、runtime cycle execution、public API / C ABI、Request + Report 双层或五件套 sanity bundle。

## Cangjie Issue Ledger

未触发 `CANGJIE_ISSUE_LEDGER` 更新。

## Next Opening

`P1 internal scheduler tick intent boundary closure / next scheduler-to-runtime ingress decision`
