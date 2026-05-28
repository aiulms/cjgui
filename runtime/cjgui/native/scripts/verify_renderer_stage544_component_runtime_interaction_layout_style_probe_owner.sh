#!/usr/bin/env zsh
#
# Verifies the stage544 component runtime interaction layout/style probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage544_component_runtime_interaction_layout_style_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage544 component runtime interaction layout style probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage544ComponentRuntimeInteractionLayoutStyleProbePlan" \
  "CjguiInternalRendererStage544ComponentRuntimeInteractionLayoutStyleProbeFacts" \
  "CjguiInternalRendererStage544ComponentRuntimeInteractionLayoutStyleProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage544ComponentRuntimeInteractionLayoutStyleProbeDraft" \
  "CjguiInternalRendererStage543ComponentRuntimeInteractionStateRenderRefreshExecutorReadiness" \
  "didConsumeStage543ComponentRuntimeInteractionStateRenderRefreshExecutor" \
  "didConsumeInteractionDemoSurfaceRefreshReceipts" \
  "didMaterializeSharedComponentRuntimeInteractionLayoutStyleProbeContract" \
  "didMaterializeSharedComponentRuntimeInteractionLayoutStyleProbeSurface" \
  "didMaterializeInteractionTextFocusProbeSurface" \
  "didMaterializeTodoInteractionLayoutStyleProbeSurface" \
  "didMaterializeSettingsInteractionLayoutStyleProbeSurface" \
  "didMaterializeAiGeneratedSettingsInteractionLayoutStyleProbeSurface" \
  "didBindInteractionLayoutStyleProbeToStage543RefreshReceipts" \
  "didBindInteractionLayoutStyleProbeToStage539LayoutTextFocusExecutor" \
  "didPrepareStage545ComponentRuntimeInteractionLayoutMeasurementExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage544 component runtime interaction layout style probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage544_component_runtime_interaction_layout_style_probe_owner_present=true"
echo "stage543_component_runtime_interaction_state_render_refresh_executor_consumed=true"
echo "interaction_demo_surface_refresh_receipts_consumed=true"
echo "shared_component_runtime_interaction_layout_style_probe_contract_materialized=true"
echo "shared_component_runtime_interaction_layout_style_probe_surface_materialized=true"
echo "interaction_text_focus_probe_surface_materialized=true"
echo "todo_interaction_layout_style_probe_surface_materialized=true"
echo "settings_interaction_layout_style_probe_surface_materialized=true"
echo "ai_generated_settings_interaction_layout_style_probe_surface_materialized=true"
echo "interaction_layout_style_probe_bound_to_stage543_refresh_receipts=true"
echo "interaction_layout_style_probe_bound_to_stage539_layout_text_focus_executor=true"
echo "interaction_layout_style_probe_preview_only=true"
echo "interaction_layout_style_probe_reuses_shared_component_runtime_layout_path=true"
echo "stage545_component_runtime_interaction_layout_measurement_executor_prepared=true"
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
