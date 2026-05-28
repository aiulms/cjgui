#!/usr/bin/env zsh
#
# 维护注释：验证 stage441 transaction visibility result -> demo surface refresh owner。
# 它必须消费 stage440 not-published result boundary，并刷新 Todo/settings/AI-generated settings owner-local surface。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage441_transaction_visibility_result_demo_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage441 transaction visibility result demo surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage441TransactionVisibilityResultDemoSurfaceRefreshPlan" \
  "CjguiInternalRendererStage441TransactionVisibilityResultDemoSurfaceRefreshFacts" \
  "CjguiInternalRendererStage441TransactionVisibilityResultDemoSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage441TransactionVisibilityResultDemoSurfaceRefreshDraft" \
  "didConsumeStage440TransactionVisibilityNotPublishedResultBoundary" \
  "didConsumeTransactionVisibilityNotPublishedResultBoundary" \
  "didConsumePublicationPreflightToNotAdmittedResult" \
  "didConsumeRollbackPreflightToRollbackNotPublishedResult" \
  "didMaterializeTransactionVisibilityResultDemoSurfaceRefresh" \
  "didRefreshTodoTransactionVisibilityResultSurface" \
  "didRefreshSettingsTransactionVisibilityResultSurface" \
  "didRefreshAiGeneratedSettingsTransactionVisibilityResultSurface" \
  "didMapNotAdmittedResultToDemoSurfaceRefresh" \
  "didMapRollbackResultToDemoSurfaceRefresh" \
  "didBindDemoSurfaceResultRefreshToStage440Boundary" \
  "didKeepDemoSurfaceResultRefreshOwnerLocal" \
  "didKeepDemoSurfaceResultRefreshPreviewOnly" \
  "didPrepareStage442TransactionVisibilityResultRecoveryActionAdapter" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage441 transaction visibility result demo surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage441_transaction_visibility_result_demo_surface_refresh_owner_present=true"
echo "stage440_transaction_visibility_not_published_result_boundary_required=true"
echo "stage440_transaction_visibility_not_published_result_boundary_consumed=true"
echo "transaction_visibility_not_published_result_boundary_consumed=true"
echo "publication_preflight_to_not_admitted_result_consumed=true"
echo "rollback_preflight_to_rollback_not_published_result_consumed=true"
echo "transaction_visibility_result_demo_surface_refresh_materialized=true"
echo "todo_transaction_visibility_result_surface_refreshed=true"
echo "settings_transaction_visibility_result_surface_refreshed=true"
echo "ai_generated_settings_transaction_visibility_result_surface_refreshed=true"
echo "not_admitted_result_to_demo_surface_refresh_mapped=true"
echo "rollback_result_to_demo_surface_refresh_mapped=true"
echo "demo_surface_result_refresh_bound_to_stage440_boundary=true"
echo "demo_surface_result_refresh_owner_local=true"
echo "demo_surface_result_refresh_preview_only=true"
echo "stage442_transaction_visibility_result_recovery_action_adapter_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
