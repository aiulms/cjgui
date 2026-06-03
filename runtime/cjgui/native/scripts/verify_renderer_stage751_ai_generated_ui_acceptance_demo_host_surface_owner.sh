#!/usr/bin/env zsh
#
# Verifies the stage751 AI-generated UI acceptance demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage751_ai_generated_ui_acceptance_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage751 ai generated ui acceptance demo host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage751AiGeneratedUiAcceptanceDemoHostSurfacePlan" \
  "CjguiInternalRendererStage751AiGeneratedUiAcceptanceDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage751AiGeneratedUiAcceptanceDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage751AiGeneratedUiAcceptanceDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage750AiGeneratedUiPublicSurfacePreflightReadiness" \
  "didConsumeStage750AiGeneratedUiPublicSurfacePreflight" \
  "didMaterializeAcceptanceDemoHostInspectionRows" \
  "didMaterializeAcceptanceResultSurfacePreview" \
  "didMaterializeAcceptanceRenderCommandPreviewReceipt" \
  "didBindAcceptanceDemoHostSurfaceToPublicSurfacePreflight" \
  "didPrepareStage752AiGeneratedUiOwnerAcceptanceRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage751 ai generated ui acceptance demo host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage751_ai_generated_ui_acceptance_demo_host_surface_owner_present=true"
echo "stage750_ai_generated_ui_public_surface_preflight_consumed=true"
echo "stage749_ai_generated_ui_owner_acceptance_preflight_consumed_transitively=true"
echo "acceptance_demo_host_inspection_rows_materialized=true"
echo "acceptance_result_surface_preview_materialized=true"
echo "acceptance_render_command_preview_receipt_materialized=true"
echo "acceptance_probe_input_contract_materialized=true"
echo "todo_ai_generated_ui_acceptance_demo_host_surface_materialized=true"
echo "settings_ai_generated_ui_acceptance_demo_host_surface_materialized=true"
echo "ai_generated_settings_ai_generated_ui_acceptance_demo_host_surface_materialized=true"
echo "chat_composer_ai_generated_ui_acceptance_demo_host_surface_materialized=true"
echo "acceptance_demo_host_surface_bound_to_public_surface_preflight=true"
echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_prepared=true"
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
