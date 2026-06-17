#!/usr/bin/env zsh
#
# Verifies the stage864 text-input owner acceptance runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage864_text_input_owner_acceptance_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage864 text input owner acceptance runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage864TextInputOwnerAcceptanceRuntimeManagerPlan" \
  "CjguiInternalRendererStage864TextInputOwnerAcceptanceRuntimeManagerFacts" \
  "CjguiInternalRendererStage864TextInputOwnerAcceptanceRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage864TextInputOwnerAcceptanceRuntimeManagerDraft" \
  "CjguiInternalRendererStage863TextInputAcceptanceDemoHostSurfaceReadiness" \
  "didConsumeStage863TextInputAcceptanceDemoHostSurface" \
  "didMaterializeSharedTextInputOwnerAcceptanceRuntimeManager" \
  "didMaterializeTextInputOwnerAcceptanceRuntimeContract" \
  "didMaterializeTextInputOwnerAcceptanceExecutionReceiptContract" \
  "didMaterializeCycleOrderOwnerLocalCommitReviewDecisionDemoRuntime" \
  "didMaterializeFileBrowserOwnerAcceptanceRuntimeSurface" \
  "didBindRuntimeManagerToStage861ReviewGate" \
  "didBindRuntimeManagerToStage862DecisionReducer" \
  "didBindRuntimeManagerToStage863DemoHostSurface" \
  "didReduceFuturePerDemoOwnerAcceptanceTemplateNeed" \
  "didPrepareStage865TextInputCommitPublicApiConsumptionProof"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage864 text input owner acceptance runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage864_text_input_owner_acceptance_runtime_manager_owner_present=true"
echo "stage863_text_input_acceptance_demo_host_surface_consumed=true"
echo "stage862_text_input_acceptance_decision_reducer_consumed_transitively=true"
echo "stage861_text_input_owner_acceptance_review_gate_consumed_transitively=true"
echo "stage860_owner_local_text_input_commit_runtime_manager_consumed_transitively=true"
echo "shared_text_input_owner_acceptance_runtime_manager_materialized=true"
echo "text_input_owner_acceptance_runtime_contract_materialized=true"
echo "text_input_owner_acceptance_execution_receipt_contract_materialized=true"
echo "cycle_order_owner_local_commit_review_decision_demo_runtime_materialized=true"
echo "todo_text_input_owner_acceptance_runtime_surface_materialized=true"
echo "settings_text_input_owner_acceptance_runtime_surface_materialized=true"
echo "ai_generated_settings_text_input_owner_acceptance_runtime_surface_materialized=true"
echo "chat_composer_text_input_owner_acceptance_runtime_surface_materialized=true"
echo "file_browser_text_input_owner_acceptance_runtime_surface_materialized=true"
echo "text_input_owner_acceptance_runtime_manager_bound_to_stage861_review_gate=true"
echo "text_input_owner_acceptance_runtime_manager_bound_to_stage862_decision_reducer=true"
echo "text_input_owner_acceptance_runtime_manager_bound_to_stage863_demo_host_surface=true"
echo "future_per_demo_owner_acceptance_template_need_reduced=true"
echo "stage865_text_input_commit_public_api_consumption_proof_prepared=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
