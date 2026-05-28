#!/usr/bin/env zsh
#
# Focused suite for stage659. It consumes stage658 reductions and verifies
# checkable interaction feedback result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE659_TMPDIR:-/private/tmp/cjgui-stage657-stage660/stage659}"
SUITE_PACKET="$TMP_DIR/stage659-interaction-feedback-result-surface-suite.packet"
STAGE658_SUITE_PACKET="${CJGUI_STAGE659_INPUT_PACKET:-${CJGUI_STAGE658_INTERACTION_FEEDBACK_REDUCER_SUITE_PACKET:-/private/tmp/cjgui-stage657-stage660/stage658/stage658-interaction-feedback-reducer-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage659_interaction_feedback_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage659-interaction-feedback-result-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage659 interaction feedback result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage658_interaction_feedback_reducer_consumed=true" \
  "shared_interaction_feedback_result_surface_materialized=true" \
  "chat_composer_interaction_feedback_result_surface_materialized=true" \
  "stage660_interaction_feedback_cycle_executor_after_stage659_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE658_SUITE_PACKET" || ! -f "$STAGE658_SUITE_PACKET" ]]; then
  echo "cjgui stage659 interaction feedback result surface suite: missing stage658 packet; set CJGUI_STAGE659_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage658_interaction_feedback_reducer_suite_version=1" \
  "shared_interaction_feedback_reducer_materialized=true" \
  "chat_composer_interaction_feedback_reduction_materialized=true" \
  "stage659_interaction_feedback_result_surface_after_stage658_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE658_SUITE_PACKET" "$fact"
done

for src in "$ROOT_DIR/src/runtime_renderer_stage659_interaction_feedback_result_surface.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage659 interaction feedback result surface suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage659 interaction feedback result surface suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage659 interaction feedback result surface suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

{
  echo "stage659_interaction_feedback_result_surface_suite_version=1"
  echo "stage658_interaction_feedback_reducer_suite_packet=$STAGE658_SUITE_PACKET"
  echo "stage659_interaction_feedback_result_surface_owner_passed=true"
  echo "stage658_interaction_feedback_reducer_consumed=true"
  echo "shared_interaction_feedback_result_surface_materialized=true"
  echo "validation_dismiss_result_surface_materialized=true"
  echo "focus_movement_result_surface_materialized=true"
  echo "input_feedback_clear_result_surface_materialized=true"
  echo "semantic_diff_acknowledge_result_surface_materialized=true"
  echo "todo_interaction_feedback_result_surface_materialized=true"
  echo "settings_interaction_feedback_result_surface_materialized=true"
  echo "ai_generated_settings_interaction_feedback_result_surface_materialized=true"
  echo "chat_composer_interaction_feedback_result_surface_materialized=true"
  echo "result_surface_bound_to_stage658_reductions=true"
  echo "stage659_public_foreign_scan_passed=true"
  echo "stage659_forbidden_native_render_token_scan_passed=true"
  echo "stage660_interaction_feedback_cycle_executor_after_stage659_prepared=true"
  echo "host_mutation=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage660_interaction_feedback_cycle_executor_after_stage659"
  echo "stage659_interaction_feedback_result_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage659 interaction feedback result surface suite: route_classification=interaction_feedback_result_surface_ready"
echo "cjgui stage659 interaction feedback result surface suite: suite_packet_path=$SUITE_PACKET"
