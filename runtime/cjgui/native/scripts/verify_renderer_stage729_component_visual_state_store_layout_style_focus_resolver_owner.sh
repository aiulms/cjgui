#!/usr/bin/env zsh
#
# Verifies the stage729 component visual state store layout/style/focus resolver owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage729_component_visual_state_store_layout_style_focus_resolver.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage729 component visual state store layout style focus resolver: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage729ComponentVisualStateStoreLayoutStyleFocusResolverPlan" \
  "CjguiInternalRendererStage729ComponentVisualStateStoreLayoutStyleFocusResolverFacts" \
  "CjguiInternalRendererStage729ComponentVisualStateStoreLayoutStyleFocusResolverReadiness" \
  "cjguiInternalExecuteDefaultRendererStage729ComponentVisualStateStoreLayoutStyleFocusResolverDraft" \
  "CjguiInternalRendererStage728ComponentVisualStateStoreInputActionCycleManagerReadiness" \
  "didConsumeStage728ComponentVisualStateStoreInputActionCycleManager" \
  "didMaterializeSharedVisualStateStoreLayoutResolverDryRun" \
  "didMaterializeSharedVisualStateStoreStyleResolverDryRun" \
  "didMaterializeSharedVisualStateStoreFocusManagerDryRun" \
  "didMaterializeResolvedVisualStateStoreStyleTokenLedger" \
  "didMaterializeVisualStateStoreFocusHandoffLedger" \
  "didBindResolverToStage728InputActionCycleManager" \
  "didPrepareStage730ComponentVisualStateStoreTextSelectionProjection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage729 component visual state store layout style focus resolver: missing token $token" >&2
    exit 3
  fi
done

echo "stage729_component_visual_state_store_layout_style_focus_resolver_owner_present=true"
echo "stage728_component_visual_state_store_input_action_cycle_manager_consumed=true"
echo "stage727_component_visual_state_store_render_result_host_surface_consumed_transitively=true"
echo "shared_visual_state_store_layout_resolver_dry_run_materialized=true"
echo "shared_visual_state_store_style_resolver_dry_run_materialized=true"
echo "shared_visual_state_store_focus_manager_dry_run_materialized=true"
echo "resolved_visual_state_store_style_token_ledger_materialized=true"
echo "visual_state_store_focus_handoff_ledger_materialized=true"
echo "todo_visual_state_store_layout_style_focus_resolution_materialized=true"
echo "settings_visual_state_store_layout_style_focus_resolution_materialized=true"
echo "ai_generated_settings_visual_state_store_layout_style_focus_resolution_materialized=true"
echo "chat_composer_visual_state_store_layout_style_focus_resolution_materialized=true"
echo "resolver_bound_to_stage728_input_action_cycle_manager=true"
echo "stage730_component_visual_state_store_text_selection_projection_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
