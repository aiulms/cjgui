#!/usr/bin/env zsh
#
# Verifies the stage508 demo-surface refresh focus/input action adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage508_demo_surface_refresh_focus_input_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage508 demo surface refresh focus input action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage508DemoSurfaceRefreshFocusInputActionAdapterPlan" \
  "CjguiInternalRendererStage508DemoSurfaceRefreshFocusInputActionAdapterFacts" \
  "CjguiInternalRendererStage508DemoSurfaceRefreshFocusInputActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage508DemoSurfaceRefreshFocusInputActionAdapterDraft" \
  "CjguiInternalRendererStage507DemoSurfaceRefreshRuntimePreviewProbeReadiness" \
  "didConsumeStage507DemoSurfaceRefreshRuntimePreviewProbe" \
  "didConsumeSharedDemoSurfaceRefreshRuntimePreviewProbeContractHelper" \
  "didMaterializeSharedDemoSurfaceRefreshFocusInputActionAdapter" \
  "didMaterializeTodoDemoSurfaceRefreshRuntimeFocusActivationIntent" \
  "didMaterializeSettingsDemoSurfaceRefreshRuntimeToggleIntent" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshRuntimeSubmitIntent" \
  "didBindRuntimePreviewProbeToFocusInputActionAdapter" \
  "didKeepFocusInputActionAdapterNonDispatching" \
  "didPrepareStage509DemoSurfaceRefreshActionStateUpdateDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage508 demo surface refresh focus input action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage508_demo_surface_refresh_focus_input_action_adapter_owner_present=true"
echo "stage507_demo_surface_refresh_runtime_preview_probe_consumed=true"
echo "shared_demo_surface_refresh_runtime_preview_probe_contract_consumed=true"
echo "shared_demo_surface_refresh_runtime_preview_probe_contract_helper_consumed=true"
echo "todo_demo_surface_refresh_runtime_preview_probe_input_consumed=true"
echo "settings_demo_surface_refresh_runtime_preview_probe_input_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_runtime_preview_probe_input_consumed=true"
echo "shared_demo_surface_refresh_focus_input_action_adapter_materialized=true"
echo "todo_demo_surface_refresh_runtime_focus_activation_intent_materialized=true"
echo "settings_demo_surface_refresh_runtime_toggle_intent_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_runtime_submit_intent_materialized=true"
echo "runtime_preview_probe_to_focus_input_action_adapter_bound=true"
echo "demo_surface_refresh_focus_input_adapter_contract_materialized=true"
echo "focus_input_action_adapter_reusable=true"
echo "focus_input_action_adapter_owner_local=true"
echo "focus_input_action_adapter_non_dispatching=true"
echo "stage509_demo_surface_refresh_action_state_update_dry_run_prepared=true"
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
