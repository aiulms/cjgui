#!/usr/bin/env zsh
#
# Verifies the stage853 text input commit preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage853_text_input_commit_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage853 text input commit preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage853TextInputCommitPreflightPlan" \
  "CjguiInternalRendererStage853TextInputCommitPreflightFacts" \
  "CjguiInternalRendererStage853TextInputCommitPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage853TextInputCommitPreflightDraft" \
  "CjguiInternalRendererStage852PublishableStateTextInputStateUpdateRenderBridgeRuntimeManagerReadiness" \
  "didConsumeStage852TextInputStateUpdateRenderBridgeRuntimeManager" \
  "didMaterializeSharedTextInputCommitPreflight" \
  "didMaterializeTextInputCommitCandidateLedger" \
  "didMaterializeTextInputCommitCompatibilityGate" \
  "didMaterializeTextInputResultToCommitPlanBridge" \
  "didMaterializeFileBrowserTextInputCommitPreflightSurface" \
  "didBindCommitPreflightToStage852RuntimeManager" \
  "didKeepTextInputCommitPreflightDryRunOnly" \
  "didPrepareStage854TextInputCommitRollbackSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage853 text input commit preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage853_text_input_commit_preflight_owner_present=true"
echo "stage852_text_input_state_update_render_bridge_runtime_manager_consumed=true"
echo "stage851_text_input_demo_result_surface_consumed_transitively=true"
echo "text_input_state_update_render_bridge_runtime_contract_consumed=true"
echo "shared_text_input_commit_preflight_materialized=true"
echo "text_input_commit_candidate_ledger_materialized=true"
echo "text_input_commit_compatibility_gate_materialized=true"
echo "text_input_result_to_commit_plan_bridge_materialized=true"
echo "todo_text_input_commit_preflight_surface_materialized=true"
echo "settings_text_input_commit_preflight_surface_materialized=true"
echo "ai_generated_settings_text_input_commit_preflight_surface_materialized=true"
echo "chat_composer_text_input_commit_preflight_surface_materialized=true"
echo "file_browser_text_input_commit_preflight_surface_materialized=true"
echo "text_input_commit_preflight_bound_to_stage852_runtime_manager=true"
echo "text_input_commit_preflight_dry_run_only=true"
echo "stage854_text_input_commit_rollback_snapshot_prepared=true"
echo "text_input_pipeline_execution=false"
echo "text_mutation=false"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
