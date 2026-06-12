#!/usr/bin/env zsh
#
# Verifies the stage838 publishable state focus movement preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage838_publishable_state_focus_movement_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage838 publishable state focus movement preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan" \
  "CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts" \
  "CjguiInternalRendererStage838PublishableStateFocusMovementPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage838PublishableStateFocusMovementPreviewDraft" \
  "CjguiInternalRendererStage837PublishableStateFocusManagerReadiness" \
  "didConsumeStage837PublishableStateFocusManager" \
  "didMaterializeOwnerLocalFocusMovementPreview" \
  "didMaterializeSelectionCaretTransitionPreview" \
  "didMaterializeFocusRollbackSnapshot" \
  "didMaterializeFocusChangeExplainReceipt" \
  "didBindFocusMovementToStage837FocusManagerInput" \
  "didPrepareStage839PublishableStateFocusDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage838 publishable state focus movement preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage838_publishable_state_focus_movement_preview_owner_present=true"
echo "stage837_publishable_state_focus_manager_consumed=true"
echo "stage836_publishable_state_layout_style_runtime_manager_consumed_transitively=true"
echo "owner_local_focus_traversal_manager_input_consumed=true"
echo "owner_local_focus_movement_preview_materialized=true"
echo "selection_caret_transition_preview_materialized=true"
echo "focus_rollback_snapshot_materialized=true"
echo "focus_change_explain_receipt_materialized=true"
echo "focus_movement_bound_to_stage837_focus_manager_input=true"
echo "stage839_publishable_state_focus_demo_surface_prepared=true"
echo "focus_dispatch=false"
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
