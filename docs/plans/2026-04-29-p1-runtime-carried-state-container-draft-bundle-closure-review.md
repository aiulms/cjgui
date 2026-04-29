# P1 Runtime Carried State Container Draft Bundle Closure Review

## Scope Closed

This bundle adds the first internal-only runtime carried state container draft on top of runtime state carry-forward.

New runtime-owned types:

- `CjguiInternalRuntimeCarriedStateContainerRequest`
- `CjguiInternalRuntimeCarriedStateContainer`

New runtime-owned functions:

- `cjguiInternalBuildRuntimeCarriedStateContainerRequest`
- `cjguiInternalEvaluateRuntimeCarriedStateContainer`
- `cjguiInternalExecuteRuntimeCarriedStateContainerDraft`
- `cjguiInternalExecuteDefaultRuntimeCarriedStateContainerDraft`
- `cjguiInternalRuntimeCarriedStateContainerOpenSanity`
- `cjguiInternalRuntimeCarriedStateContainerRuntimeBlockedSanity`
- `cjguiInternalRuntimeCarriedStateContainerInputBlockedSanity`
- `cjguiInternalRuntimeCarriedStateContainerShutdownBlockedSanity`
- `cjguiInternalRuntimeCarriedStateContainerCancellationBlockedSanity`

## Behavior Boundary

Carried state container consumes only `CjguiInternalRuntimeStateCarryForwardReport`.

The carried app/window states come only from `carryForwardReport.nextAppStateCandidate` and `carryForwardReport.nextWindowStateCandidate`. The evaluator maps carry-forward flags to `didCarryAppState`, `didCarryWindowState`, `shouldDeferCarriedState`, and `shouldReportCarriedStateBlocked`.

It does not read PublicationReport, OutcomeReport, MutationReport, ApplyReport, or lower-level facts. It does not write runtime global state, publicize state, perform a new mutation, call platform code, touch queues, or run an event loop.

## Verification

- `cjpm build --target-dir /tmp/cjgui-runtime-carried-state-container-draft-bundle-target --skip-script` passed after sourcing the local Cangjie envsetup; only existing unused warnings remain.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed.
- `git diff --check` passed.

## Stop Line

This is an internal carried state container draft only. It is not committed runtime state, not public state publication, and not a runtime global state store.

## Next Opening

`P1 runtime carried state container draft bundle closure / next runtime behavior decision`
