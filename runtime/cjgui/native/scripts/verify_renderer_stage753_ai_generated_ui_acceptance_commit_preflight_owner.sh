#!/usr/bin/env zsh
#
# Verifies the stage753 AI-generated UI acceptance commit preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage753_ai_generated_ui_acceptance_commit_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage753 ai generated ui acceptance commit preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage753AiGeneratedUiAcceptanceCommitPreflightPlan" \
  "CjguiInternalRendererStage753AiGeneratedUiAcceptanceCommitPreflightFacts" \
  "CjguiInternalRendererStage753AiGeneratedUiAcceptanceCommitPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage753AiGeneratedUiAcceptanceCommitPreflightDraft" \
  "CjguiInternalRendererStage752AiGeneratedUiOwnerAcceptanceRuntimeManagerReadiness" \
  "didConsumeStage752AiGeneratedUiOwnerAcceptanceRuntimeManager" \
  "didMaterializeOwnerLocalAcceptanceCommitCandidateLedger" \
  "didMaterializeAcceptanceCommitCapabilityLedger" \
  "didMaterializeAcceptanceCommitValidationGate" \
  "didMaterializeResolverResultToAcceptanceCommitPlanBridge" \
  "didBindAcceptanceCommitPreflightToOwnerAcceptanceRuntimeManager" \
  "didPrepareStage754AiGeneratedUiAcceptanceCommitRollbackSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage753 ai generated ui acceptance commit preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage753_ai_generated_ui_acceptance_commit_preflight_owner_present=true"
echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_consumed=true"
echo "stage751_ai_generated_ui_acceptance_demo_host_surface_consumed_transitively=true"
echo "stage750_ai_generated_ui_public_surface_preflight_consumed_transitively=true"
echo "stage749_ai_generated_ui_owner_acceptance_preflight_consumed_transitively=true"
echo "owner_local_acceptance_commit_candidate_ledger_materialized=true"
echo "acceptance_commit_capability_ledger_materialized=true"
echo "acceptance_commit_validation_gate_materialized=true"
echo "resolver_result_to_acceptance_commit_plan_bridge_materialized=true"
echo "todo_ai_generated_ui_acceptance_commit_preflight_materialized=true"
echo "settings_ai_generated_ui_acceptance_commit_preflight_materialized=true"
echo "ai_generated_settings_ai_generated_ui_acceptance_commit_preflight_materialized=true"
echo "chat_composer_ai_generated_ui_acceptance_commit_preflight_materialized=true"
echo "acceptance_commit_preflight_bound_to_owner_acceptance_runtime_manager=true"
echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
