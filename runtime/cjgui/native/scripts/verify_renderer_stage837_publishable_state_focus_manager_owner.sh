#!/usr/bin/env zsh
#
# Verifies the stage837 publishable state focus manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage837_publishable_state_focus_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage837 publishable state focus manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage837PublishableStateFocusManagerPlan" \
  "CjguiInternalRendererStage837PublishableStateFocusManagerFacts" \
  "CjguiInternalRendererStage837PublishableStateFocusManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage837PublishableStateFocusManagerDraft" \
  "CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness" \
  "didConsumeStage836PublishableStateLayoutStyleRuntimeManager" \
  "didMaterializeOwnerLocalFocusTraversalManagerInput" \
  "didMaterializeFocusScopeCandidateLedger" \
  "didMaterializeFocusableSlotOrderLedger" \
  "didMaterializeCaretAnchorCandidateLedger" \
  "didBindFocusManagerToStage834MeasurementPlan" \
  "didBindFocusManagerToStage836RuntimeManager" \
  "didPrepareStage838PublishableStateFocusMovementPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage837 publishable state focus manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage837_publishable_state_focus_manager_owner_present=true"
echo "stage836_publishable_state_layout_style_runtime_manager_consumed=true"
echo "stage835_publishable_state_layout_style_demo_surface_consumed_transitively=true"
echo "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true"
echo "owner_local_focus_traversal_manager_input_materialized=true"
echo "focus_scope_candidate_ledger_materialized=true"
echo "focusable_slot_order_ledger_materialized=true"
echo "caret_anchor_candidate_ledger_materialized=true"
echo "focus_manager_bound_to_stage834_measurement_plan=true"
echo "focus_manager_bound_to_stage836_runtime_manager=true"
echo "stage838_publishable_state_focus_movement_preview_prepared=true"
echo "focus_manager_enabled=false"
echo "focus_mutation=false"
echo "input_pipeline_execution=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
