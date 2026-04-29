# P1 Runtime State Carry-Forward Draft Bundle Closure Review

## Scope Closed

This bundle adds the first internal-only runtime state carry-forward draft on top of lifecycle mutated state publication.

New runtime-owned types:

- `CjguiInternalRuntimeStateCarryForwardRequest`
- `CjguiInternalRuntimeStateCarryForwardReport`

New runtime-owned functions:

- `cjguiInternalBuildRuntimeStateCarryForwardRequest`
- `cjguiInternalEvaluateRuntimeStateCarryForward`
- `cjguiInternalExecuteRuntimeStateCarryForwardDraft`
- `cjguiInternalExecuteDefaultRuntimeStateCarryForwardDraft`
- `cjguiInternalRuntimeStateCarryForwardOpenSanity`
- `cjguiInternalRuntimeStateCarryForwardRuntimeBlockedSanity`
- `cjguiInternalRuntimeStateCarryForwardInputBlockedSanity`
- `cjguiInternalRuntimeStateCarryForwardShutdownBlockedSanity`
- `cjguiInternalRuntimeStateCarryForwardCancellationBlockedSanity`

## Behavior Boundary

Carry-forward consumes only `CjguiInternalLifecycleMutatedStatePublicationReport`.

The candidate app/window states come only from `publicationReport.appState` and `publicationReport.windowState`. The evaluator maps publication flags to `shouldCarryForwardAppState`, `shouldCarryForwardWindowState`, `shouldDeferCarryForward`, and `shouldReportCarryForwardBlocked`.

It does not read OutcomeReport, MutationReport, ApplyReport, CommitGateReport, or lower-level facts. It does not write runtime global state, publicize state, perform a new mutation, call platform code, touch queues, or run an event loop.

## Verification

- `cjpm build --target-dir /tmp/cjgui-runtime-state-carry-forward-draft-bundle-target --skip-script` passed after sourcing the local Cangjie envsetup; only existing unused warnings remain.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed.
- `git diff --check` passed.

## Stop Line

This is an internal carry-forward candidate summary only. It is not committed runtime state, not public state publication, and not a runtime global state store.

## Next Opening

`P1 runtime state carry-forward draft bundle closure / next runtime behavior decision`
