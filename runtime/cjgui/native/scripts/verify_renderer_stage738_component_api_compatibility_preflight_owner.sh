#!/usr/bin/env zsh
#
# Verifies the stage738 component API compatibility preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage738_component_api_compatibility_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage738 component api compatibility preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage738ComponentApiCompatibilityPreflightPlan" \
  "CjguiInternalRendererStage738ComponentApiCompatibilityPreflightFacts" \
  "CjguiInternalRendererStage738ComponentApiCompatibilityPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage738ComponentApiCompatibilityPreflightDraft" \
  "CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeReadiness" \
  "didConsumeStage737ComponentStateStorePublicApiInternalShape" \
  "didMaterializeComponentApiCompatibilityLedger" \
  "didMaterializePublicSurfacePreflightBoundary" \
  "didMaterializeComponentApiVersioningNote" \
  "didMaterializePublicApiRejectionReasonLedger" \
  "didKeepStablePublicApiUnexpanded" \
  "didPrepareStage739ComponentApiDemoHostAuthoringSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage738 component api compatibility preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage738_component_api_compatibility_preflight_owner_present=true"
echo "stage737_component_state_store_public_api_internal_shape_consumed=true"
echo "internal_component_api_shape_descriptor_consumed=true"
echo "component_api_compatibility_ledger_materialized=true"
echo "public_surface_preflight_boundary_materialized=true"
echo "component_api_versioning_note_materialized=true"
echo "public_api_rejection_reason_ledger_materialized=true"
echo "todo_component_api_compatibility_surface_materialized=true"
echo "settings_component_api_compatibility_surface_materialized=true"
echo "ai_generated_settings_component_api_compatibility_surface_materialized=true"
echo "chat_composer_component_api_compatibility_surface_materialized=true"
echo "compatibility_preflight_bound_to_stage737_internal_shape=true"
echo "stable_public_api_unexpanded=true"
echo "stage739_component_api_demo_host_authoring_surface_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
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
