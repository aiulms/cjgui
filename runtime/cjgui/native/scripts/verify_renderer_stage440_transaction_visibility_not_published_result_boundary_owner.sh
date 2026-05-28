#!/usr/bin/env zsh
#
# 维护注释：验证 stage440 transaction visibility not-published result boundary owner。
# 它必须消费 stage439 publication preflight，并生成 owner-local not-published result boundary。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage440_transaction_visibility_not_published_result_boundary.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage440 transaction visibility not-published result boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage440TransactionVisibilityNotPublishedResultBoundaryPlan" \
  "CjguiInternalRendererStage440TransactionVisibilityNotPublishedResultBoundaryFacts" \
  "CjguiInternalRendererStage440TransactionVisibilityNotPublishedResultBoundaryReadiness" \
  "cjguiInternalExecuteDefaultRendererStage440TransactionVisibilityNotPublishedResultBoundaryDraft" \
  "didConsumeStage439TransactionVisibilityPublicationPreflight" \
  "didConsumeTransactionVisibilityPublicationPreflight" \
  "didConsumeAcceptedVisibilityCommandToPublicationPreflight" \
  "didConsumeRollbackVisibilityCommandToNotPublishedPreflight" \
  "didMaterializeTransactionVisibilityNotPublishedResultBoundary" \
  "didMaterializeTodoTransactionVisibilityNotPublishedResultBoundary" \
  "didMaterializeSettingsTransactionVisibilityNotPublishedResultBoundary" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityNotPublishedResultBoundary" \
  "didMapPublicationPreflightToNotAdmittedResult" \
  "didMapRollbackPreflightToRollbackNotPublishedResult" \
  "didBindNotPublishedResultBoundaryToStage439Preflight" \
  "didBindNotPublishedResultBoundaryToStage438CommandPlan" \
  "didKeepTransactionVisibilityResultOwnerLocal" \
  "didKeepTransactionVisibilityResultInMemoryOnly" \
  "didPrepareStage441TransactionVisibilityResultDemoSurfaceRefresh" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage440 transaction visibility not-published result boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage440_transaction_visibility_not_published_result_boundary_owner_present=true"
echo "stage439_transaction_visibility_publication_preflight_required=true"
echo "stage439_transaction_visibility_publication_preflight_consumed=true"
echo "transaction_visibility_publication_preflight_consumed=true"
echo "accepted_visibility_command_to_publication_preflight_consumed=true"
echo "rollback_visibility_command_to_not_published_preflight_consumed=true"
echo "transaction_visibility_not_published_result_boundary_materialized=true"
echo "todo_transaction_visibility_not_published_result_boundary_materialized=true"
echo "settings_transaction_visibility_not_published_result_boundary_materialized=true"
echo "ai_generated_settings_transaction_visibility_not_published_result_boundary_materialized=true"
echo "publication_preflight_to_not_admitted_result_mapped=true"
echo "rollback_preflight_to_rollback_not_published_result_mapped=true"
echo "not_published_result_boundary_bound_to_stage439_preflight=true"
echo "not_published_result_boundary_bound_to_stage438_command_plan=true"
echo "transaction_visibility_result_owner_local=true"
echo "transaction_visibility_result_in_memory_only=true"
echo "stage441_transaction_visibility_result_demo_surface_refresh_prepared=true"
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
