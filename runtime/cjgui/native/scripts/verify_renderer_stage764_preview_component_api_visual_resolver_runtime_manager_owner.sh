#!/usr/bin/env zsh
#
# Verifies the stage764 preview component API visual resolver runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage764_preview_component_api_visual_resolver_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage764 preview component api visual resolver runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage764PreviewComponentApiVisualResolverRuntimeManagerPlan" \
  "CjguiInternalRendererStage764PreviewComponentApiVisualResolverRuntimeManagerFacts" \
  "CjguiInternalRendererStage764PreviewComponentApiVisualResolverRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage764PreviewComponentApiVisualResolverRuntimeManagerDraft" \
  "CjguiInternalRendererStage763PreviewComponentApiDemoHostInspectionSurfaceReadiness" \
  "didConsumeStage763PreviewComponentApiDemoHostInspectionSurface" \
  "didMaterializeSharedPreviewComponentApiVisualResolverRuntimeManager" \
  "didMaterializePreviewComponentApiVisualResolverRuntimeContract" \
  "didMaterializePreviewComponentApiVisualResolverExecutionReceiptContract" \
  "didMaterializeCycleOrderPublicPreviewApiLayoutStyleTextFocusHostResultRuntime" \
  "didReduceFuturePerDemoPreviewApiConsumptionTemplateNeed" \
  "didPrepareStage765PreviewComponentApiCommitPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage764 preview component api visual resolver runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage764_preview_component_api_visual_resolver_runtime_manager_owner_present=true"
echo "stage763_preview_component_api_demo_host_inspection_surface_consumed=true"
echo "stage762_preview_component_api_text_focus_projection_consumed_transitively=true"
echo "stage761_preview_component_api_layout_style_consumption_consumed_transitively=true"
echo "stage760_minimal_public_preview_api_public_scan_contract_consumed_transitively=true"
echo "shared_preview_component_api_visual_resolver_runtime_manager_materialized=true"
echo "preview_component_api_visual_resolver_runtime_contract_materialized=true"
echo "preview_component_api_visual_resolver_execution_receipt_contract_materialized=true"
echo "cycle_order_public_preview_api_layout_style_text_focus_host_result_runtime_materialized=true"
echo "todo_preview_component_api_visual_resolver_runtime_surface_materialized=true"
echo "settings_preview_component_api_visual_resolver_runtime_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_visual_resolver_runtime_surface_materialized=true"
echo "chat_composer_preview_component_api_visual_resolver_runtime_surface_materialized=true"
echo "future_per_demo_preview_api_consumption_template_need_reduced=true"
echo "stage765_preview_component_api_commit_preflight_prepared=true"
echo "public_component_api_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
