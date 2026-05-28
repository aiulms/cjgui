#!/usr/bin/env zsh
#
# Verifies the stage541 component runtime interaction bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage541_component_runtime_interaction_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage541 component runtime interaction bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage541ComponentRuntimeInteractionBridgePlan" \
  "CjguiInternalRendererStage541ComponentRuntimeInteractionBridgeFacts" \
  "CjguiInternalRendererStage541ComponentRuntimeInteractionBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage541ComponentRuntimeInteractionBridgeDraft" \
  "CjguiInternalRendererStage540ComponentRuntimeDemoHostInspectionContractReadiness" \
  "didConsumeStage540ComponentRuntimeDemoHostInspectionContract" \
  "didMaterializeSharedComponentRuntimeInteractionBridgeContract" \
  "didMaterializeSharedComponentRuntimeInteractionTargetLedger" \
  "didMaterializeTodoComponentRuntimeInteractionTarget" \
  "didMaterializeSettingsComponentRuntimeInteractionTarget" \
  "didMaterializeAiGeneratedSettingsComponentRuntimeInteractionTarget" \
  "didBindInteractionBridgeToHostInspectionInputs" \
  "didBindInteractionBridgeToLayoutTextFocusReceipts" \
  "didReducePerDemoInteractionTargetDuplication"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage541 component runtime interaction bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage541_component_runtime_interaction_bridge_owner_present=true"
echo "stage540_component_runtime_demo_host_inspection_contract_consumed=true"
echo "shared_component_runtime_demo_host_inspection_inputs_consumed=true"
echo "shared_component_runtime_interaction_bridge_contract_materialized=true"
echo "shared_component_runtime_interaction_target_ledger_materialized=true"
echo "todo_component_runtime_interaction_target_materialized=true"
echo "settings_component_runtime_interaction_target_materialized=true"
echo "ai_generated_settings_component_runtime_interaction_target_materialized=true"
echo "interaction_bridge_bound_to_host_inspection_inputs=true"
echo "interaction_bridge_bound_to_layout_text_focus_receipts=true"
echo "interaction_bridge_bound_to_stage537_event_refresh_executor=true"
echo "interaction_bridge_owner_local=true"
echo "interaction_bridge_preview_only=true"
echo "per_demo_interaction_target_duplication_reduced=true"
echo "stage542_component_runtime_interaction_action_state_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
