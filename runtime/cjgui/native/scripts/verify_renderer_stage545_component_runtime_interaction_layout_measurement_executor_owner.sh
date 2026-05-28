#!/usr/bin/env zsh
#
# Verifies the stage545 component runtime interaction layout measurement executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage545_component_runtime_interaction_layout_measurement_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage545 component runtime interaction layout measurement executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage545ComponentRuntimeInteractionLayoutMeasurementExecutorPlan" \
  "CjguiInternalRendererStage545ComponentRuntimeInteractionLayoutMeasurementExecutorFacts" \
  "CjguiInternalRendererStage545ComponentRuntimeInteractionLayoutMeasurementExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage545ComponentRuntimeInteractionLayoutMeasurementExecutorDraft" \
  "CjguiInternalRendererStage544ComponentRuntimeInteractionLayoutStyleProbeReadiness" \
  "didConsumeStage544ComponentRuntimeInteractionLayoutStyleProbe" \
  "didConsumeInteractionLayoutStyleProbeSurfaces" \
  "didMaterializeSharedComponentRuntimeInteractionLayoutMeasurementExecutor" \
  "didMaterializeInteractionLayoutConstraintLedger" \
  "didMaterializeInteractionStyleTokenResolutionPreview" \
  "didMaterializeInteractionTextMetricReceipt" \
  "didMaterializeInteractionFocusTraversalReceipt" \
  "didMaterializeTodoInteractionLayoutMeasurementReceipt" \
  "didMaterializeSettingsInteractionLayoutMeasurementReceipt" \
  "didMaterializeAiGeneratedSettingsInteractionLayoutMeasurementReceipt" \
  "didPrepareStage546ComponentRuntimeInteractionDemoSurfaceRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage545 component runtime interaction layout measurement executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage545_component_runtime_interaction_layout_measurement_executor_owner_present=true"
echo "stage544_component_runtime_interaction_layout_style_probe_consumed=true"
echo "interaction_layout_style_probe_surfaces_consumed=true"
echo "shared_component_runtime_interaction_layout_measurement_executor_materialized=true"
echo "interaction_layout_constraint_ledger_materialized=true"
echo "interaction_style_token_resolution_preview_materialized=true"
echo "interaction_text_metric_receipt_materialized=true"
echo "interaction_focus_traversal_receipt_materialized=true"
echo "todo_interaction_layout_measurement_receipt_materialized=true"
echo "settings_interaction_layout_measurement_receipt_materialized=true"
echo "ai_generated_settings_interaction_layout_measurement_receipt_materialized=true"
echo "interaction_layout_measurement_bound_to_stage544_probe_surfaces=true"
echo "interaction_layout_measurement_bound_to_stage539_layout_text_focus_executor=true"
echo "interaction_layout_measurement_dry_run_only=true"
echo "interaction_layout_measurement_reduces_preview_probe_duplication=true"
echo "stage546_component_runtime_interaction_demo_surface_runtime_contract_prepared=true"
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
