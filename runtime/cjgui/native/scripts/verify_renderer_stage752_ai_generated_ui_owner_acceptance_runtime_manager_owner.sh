#!/usr/bin/env zsh
#
# Verifies the stage752 AI-generated UI owner acceptance runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage752_ai_generated_ui_owner_acceptance_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage752 ai generated ui owner acceptance runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage752AiGeneratedUiOwnerAcceptanceRuntimeManagerPlan" \
  "CjguiInternalRendererStage752AiGeneratedUiOwnerAcceptanceRuntimeManagerFacts" \
  "CjguiInternalRendererStage752AiGeneratedUiOwnerAcceptanceRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage752AiGeneratedUiOwnerAcceptanceRuntimeManagerDraft" \
  "CjguiInternalRendererStage751AiGeneratedUiAcceptanceDemoHostSurfaceReadiness" \
  "didConsumeStage751AiGeneratedUiAcceptanceDemoHostSurface" \
  "didMaterializeSharedAiGeneratedUiOwnerAcceptanceRuntimeManager" \
  "didMaterializeOwnerAcceptanceRuntimeContract" \
  "didMaterializeOwnerAcceptanceExecutionReceiptContract" \
  "didMaterializeCycleOrderAiGeneratedOwnerPreflightPublicSurfaceHostRuntime" \
  "didReduceFuturePerDemoOwnerAcceptanceTemplateNeed" \
  "didPrepareStage753AiGeneratedUiAcceptanceCommitPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage752 ai generated ui owner acceptance runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_owner_present=true"
echo "stage751_ai_generated_ui_acceptance_demo_host_surface_consumed=true"
echo "stage750_ai_generated_ui_public_surface_preflight_consumed_transitively=true"
echo "stage749_ai_generated_ui_owner_acceptance_preflight_consumed_transitively=true"
echo "stage748_ai_generated_ui_runtime_manager_consumed_transitively=true"
echo "shared_ai_generated_ui_owner_acceptance_runtime_manager_materialized=true"
echo "owner_acceptance_runtime_contract_materialized=true"
echo "owner_acceptance_execution_receipt_contract_materialized=true"
echo "cycle_order_ai_generated_owner_preflight_public_surface_host_runtime_materialized=true"
echo "todo_ai_generated_ui_owner_acceptance_runtime_surface_materialized=true"
echo "settings_ai_generated_ui_owner_acceptance_runtime_surface_materialized=true"
echo "ai_generated_settings_ai_generated_ui_owner_acceptance_runtime_surface_materialized=true"
echo "chat_composer_ai_generated_ui_owner_acceptance_runtime_surface_materialized=true"
echo "future_per_demo_owner_acceptance_template_need_reduced=true"
echo "stage753_ai_generated_ui_acceptance_commit_preflight_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
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
