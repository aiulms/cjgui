#!/usr/bin/env zsh
#
# Focused suite for stage657. It consumes stage656 host runtime facts and
# verifies the execution-feedback owner plus stop-line facts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE657_TMPDIR:-/private/tmp/cjgui-stage657-stage660/stage657}"
SUITE_PACKET="$TMP_DIR/stage657-interaction-execution-feedback-suite.packet"
STAGE656_SUITE_PACKET="${CJGUI_STAGE657_INPUT_PACKET:-${CJGUI_STAGE656_INTERACTION_FEEDBACK_HOST_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage653-stage656/stage656/stage656-interaction-feedback-host-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage657_interaction_execution_feedback_owner.sh"
OWNER_LOG="$TMP_DIR/stage657-interaction-execution-feedback-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage657 interaction execution feedback suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage656_interaction_feedback_host_runtime_contract_consumed=true" \
  "shared_interaction_execution_feedback_materialized=true" \
  "chat_composer_interaction_execution_feedback_materialized=true" \
  "stage658_interaction_feedback_reducer_after_stage657_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE656_SUITE_PACKET" || ! -f "$STAGE656_SUITE_PACKET" ]]; then
  echo "cjgui stage657 interaction execution feedback suite: missing stage656 packet; set CJGUI_STAGE657_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage656_interaction_feedback_host_runtime_contract_suite_version=1" \
  "shared_interaction_feedback_host_runtime_contract_materialized=true" \
  "chat_composer_interaction_feedback_host_runtime_surface_materialized=true" \
  "stage657_component_host_input_result_surface_interaction_execution_feedback_after_stage656_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE656_SUITE_PACKET" "$fact"
done

for src in "$ROOT_DIR/src/runtime_renderer_stage657_interaction_execution_feedback.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage657 interaction execution feedback suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage657 interaction execution feedback suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage657 interaction execution feedback suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

{
  echo "stage657_interaction_execution_feedback_suite_version=1"
  echo "stage656_interaction_feedback_host_runtime_contract_suite_packet=$STAGE656_SUITE_PACKET"
  echo "stage657_interaction_execution_feedback_owner_passed=true"
  echo "stage656_interaction_feedback_host_runtime_contract_consumed=true"
  echo "shared_interaction_execution_feedback_materialized=true"
  echo "validation_dismiss_execution_feedback_materialized=true"
  echo "focus_movement_execution_feedback_materialized=true"
  echo "input_feedback_clear_execution_feedback_materialized=true"
  echo "semantic_diff_acknowledge_execution_feedback_materialized=true"
  echo "todo_interaction_execution_feedback_materialized=true"
  echo "settings_interaction_execution_feedback_materialized=true"
  echo "ai_generated_settings_interaction_execution_feedback_materialized=true"
  echo "chat_composer_interaction_execution_feedback_materialized=true"
  echo "execution_feedback_bound_to_stage656_host_runtime=true"
  echo "stage657_public_foreign_scan_passed=true"
  echo "stage657_forbidden_native_render_token_scan_passed=true"
  echo "stage658_interaction_feedback_reducer_after_stage657_prepared=true"
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
  echo "next_route=stage658_interaction_feedback_reducer_after_stage657"
  echo "stage657_interaction_execution_feedback_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage657 interaction execution feedback suite: route_classification=interaction_execution_feedback_ready"
echo "cjgui stage657 interaction execution feedback suite: suite_packet_path=$SUITE_PACKET"
