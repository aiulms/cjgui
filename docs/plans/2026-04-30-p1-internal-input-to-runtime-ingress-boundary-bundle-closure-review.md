# P1 Internal Input-To-Runtime Ingress Boundary Bundle Closure Review

日期：2026-04-30

## Landed Scope

实际修改文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-internal-input-to-runtime-ingress-boundary-bundle-closure-review.md`

新增 internal ingress symbols：

- `CjguiInternalInputRuntimeIngress`
- `cjguiInternalBuildInputRuntimeIngress(routing, stateTransition)`
- `cjguiInternalExecuteDefaultInputRuntimeIngressDraft()`

## Ingress Acceptance Semantics

`CjguiInternalInputRuntimeIngress` 只组合 `CjguiInternalInputRoutingResult` 与 `CjguiInternalRuntimeStateStoreTransition`。

- open：routing 是 preserved runtime ingress candidate，且 state transition 已 open，且双方无 defer / blocked。
- defer：routing 或 state transition 是 defer-only，且双方没有 blocked / inconsistent flags。
- blocked：routing blocked、state transition blocked，或任何 inconsistent flags，全部 fail-closed blocked。
- `didPreserveRuntimeIngressCandidate` 只表示 dehydrated input candidate 与 runtime state boundary context 被一起携带为 value，不表示 enqueue、dispatch、scheduler tick、runtime cycle execution 或 state write。

Default executor 只调用：

- `cjguiInternalExecuteDefaultInputRoutingDraft()`
- `cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft()`
- `cjguiInternalBuildInputRuntimeIngress(...)`

它不直接或间接新增 `cjguiInternalExecuteRuntimeCycle` 调用点，不执行第二个 cycle，不写 queue，不写 global state。

## Boundary

本轮不是 platform event object、queue、event loop、scheduler 或 runtime cycle execution。

继续禁止：

- public runtime API / public C ABI
- platform object / native handle / raw pointer
- AppKit / Metal / Objective-C 新接入
- event loop / queue / drain / scheduler
- runtime cycle execution 或新的 `cjguiInternalExecuteRuntimeCycle` 调用点
- runtime global state write / global mutable singleton
- Request + Report 双层
- 五件套 sanity helper
- replay / admission / dry-run / outcome wrapper 回潮

## GitNexus Impact

- `CjguiInternalInputRoutingResult`：UNKNOWN / not found。
- `cjguiInternalExecuteDefaultInputRoutingDraft`：UNKNOWN / not found。
- `CjguiInternalRuntimeStateStoreTransition`：UNKNOWN / not found。
- `cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft`：UNKNOWN / not found。
- fallback `runtime_state.cj` file-level upstream impact：LOW；direct callers 0；affected processes 0；no HIGH / CRITICAL。

## Verification

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-input-to-runtime-ingress-boundary-target --skip-script`：通过；仅保留既有 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- forbidden files：未修改 `runtime/cjgui/cjpm.toml`、`labs/macos_bridge_smoke` tracked source、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。

未触发 `CANGJIE_ISSUE_LEDGER` 更新。

## Next Opening

`P1 internal input-to-runtime ingress closure / next runtime ingress boundary decision`

下一轮应做 docs-only boundary decision：封账 input-to-runtime ingress acceptance，并决定 ingress 后是否进入 ingress-to-cycle preparation、input scheduler intent，或先做 ingress manifest / stabilization。仍不得直接进入平台事件、queue、event loop、scheduler、runtime cycle execution 或 global state write。
