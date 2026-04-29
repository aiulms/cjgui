# P1 Lifecycle Mutation Apply / Commit Gate Model Normalization Closure Review

## Scope

This W2 behavior-preserving refactor slice inspected only the lifecycle mutation commit gate and apply draft neighborhood. It did not change app/window state shape, owner mutation semantics, request/report nesting, owner boundaries, public API, C ABI, platform callback, queue, or event loop behavior.

## Scan Result

- Commit gate candidates found: always-true stored `didBuildMutationCommitGate` and stored aggregate `canEnterLifecycleMutationCommit`.
- Apply candidates found: always-true stored `didBuildMutationApply` and stored aggregate `shouldApplyLifecycleMutation`.
- Owner draft shapes in `app_lifecycle.cj` and `window_lifecycle.cj` had no low-risk redundant field to remove without changing owner-facing fact shape.

## Normalization

- Removed `didBuildMutationCommitGate` and `didBuildMutationApply`.
- Removed stored aggregate `canEnterLifecycleMutationCommit`.
- Removed stored aggregate `shouldApplyLifecycleMutation`.
- Added `cjguiInternalLifecycleMutationCommitGateCanEnterBothOwners(...)` for derived commit-gate both-owner checks.
- Added `cjguiInternalLifecycleMutationApplyShouldApplyBothOwners(...)` for derived apply both-owner checks.
- Updated constructors, evaluators, and sanity helpers to use owner facts or derived helpers.

## Retained

- Retained `shouldDeferLifecycleMutationCommit` / `shouldReportLifecycleMutationCommitBlocked`.
- Retained `shouldDeferLifecycleMutationApply` / `shouldReportLifecycleMutationApplyBlocked`.
- Retained request/report traceability nesting.
- Retained app/window owner draft fields because they are owner-facing facts, not runtime aggregate duplication.

The defer / blocked summary fields remain stored because they are cross-owner blocked-report facts and mirror the outcome layer's retained blocked reporting summary.

## Verification

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-lifecycle-mutation-apply-commit-normalization-target --skip-script` passed with existing unused warnings.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed.
- `git diff --check` passed.

## Stop-Line

This slice is behavior-preserving. It does not execute lifecycle mutation, does not modify app/window state, does not call state-changing transition functions, does not move owner boundaries, and does not add public API / C ABI.

## Next Opening

`P1 lifecycle mutation apply / commit gate normalization closure / next runtime behavior decision`
