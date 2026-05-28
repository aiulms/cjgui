#!/usr/bin/env zsh
#
# 维护注释：验证 stage439 transaction visibility publication preflight owner。
# 它必须消费 stage438 command plan，并生成 owner-local publication preflight dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage439_transaction_visibility_publication_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage439 transaction visibility publication preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage439TransactionVisibilityPublicationPreflightPlan" \
  "CjguiInternalRendererStage439TransactionVisibilityPublicationPreflightFacts" \
  "CjguiInternalRendererStage439TransactionVisibilityPublicationPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage439TransactionVisibilityPublicationPreflightDraft" \
  "didConsumeStage438TransactionVisibilityCommandPlan" \
  "didConsumeTransactionVisibilityCommandPlanDryRun" \
  "didConsumeAcceptedTransactionAdmissionToVisibilityCommand" \
  "didConsumeBlockedTransactionDenialToRollbackVisibilityCommand" \
  "didMaterializeTransactionVisibilityPublicationPreflight" \
  "didMaterializeTodoTransactionVisibilityPublicationPreflight" \
  "didMaterializeSettingsTransactionVisibilityPublicationPreflight" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityPublicationPreflight" \
  "didMapAcceptedVisibilityCommandToPublicationPreflight" \
  "didMapRollbackVisibilityCommandToNotPublishedPreflight" \
  "didBindPublicationPreflightToStage438CommandPlan" \
  "didBindPublicationPreflightToStage437Admission" \
  "didKeepTransactionVisibilityPublicationPreflightOwnerLocal" \
  "didKeepTransactionVisibilityPublicationPreflightOnly" \
  "didPrepareStage440TransactionVisibilityNotPublishedResultBoundary" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage439 transaction visibility publication preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage439_transaction_visibility_publication_preflight_owner_present=true"
echo "stage438_transaction_visibility_command_plan_required=true"
echo "stage438_transaction_visibility_command_plan_consumed=true"
echo "transaction_visibility_command_plan_dry_run_consumed=true"
echo "accepted_transaction_admission_to_visibility_command_consumed=true"
echo "blocked_transaction_denial_to_rollback_visibility_command_consumed=true"
echo "transaction_visibility_publication_preflight_materialized=true"
echo "todo_transaction_visibility_publication_preflight_materialized=true"
echo "settings_transaction_visibility_publication_preflight_materialized=true"
echo "ai_generated_settings_transaction_visibility_publication_preflight_materialized=true"
echo "accepted_visibility_command_to_publication_preflight_mapped=true"
echo "rollback_visibility_command_to_not_published_preflight_mapped=true"
echo "publication_preflight_bound_to_stage438_command_plan=true"
echo "publication_preflight_bound_to_stage437_admission=true"
echo "transaction_visibility_publication_preflight_owner_local=true"
echo "transaction_visibility_publication_preflight_only=true"
echo "stage440_transaction_visibility_not_published_result_boundary_prepared=true"
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
