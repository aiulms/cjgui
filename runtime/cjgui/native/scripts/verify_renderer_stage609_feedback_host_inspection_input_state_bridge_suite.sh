#!/usr/bin/env zsh
#
# Focused suite for stage609. It consumes the stage608 runtime contract packet
# and verifies the shared feedback host inspection input-state bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE609_TMPDIR:-/private/tmp/cjgui-stage609-stage612/stage609}"
SUITE_PACKET="$TMP_DIR/stage609-feedback-host-inspection-input-state-bridge-suite.packet"
STAGE608_SUITE_PACKET="${CJGUI_STAGE609_INPUT_PACKET:-${CJGUI_STAGE608_FEEDBACK_HOST_INSPECTION_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage605-stage608/stage608/stage608-feedback-host-inspection-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage609_feedback_host_inspection_input_state_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage609-feedback-host-inspection-input-state-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage609 feedback host inspection input-state bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage609 feedback host inspection input-state bridge suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage608_feedback_host_inspection_runtime_contract_consumed=true" \
  "shared_feedback_host_inspection_input_state_bridge_materialized=true" \
  "validation_input_state_delta_dry_run_materialized=true" \
  "chat_composer_feedback_host_inspection_input_state_delta_materialized=true" \
  "stage610_feedback_host_inspection_state_render_refresh_bridge_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE608_SUITE_PACKET" || ! -f "$STAGE608_SUITE_PACKET" ]]; then
  echo "cjgui stage609 feedback host inspection input-state bridge suite: missing stage608 packet; set CJGUI_STAGE609_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage608_feedback_host_inspection_runtime_contract_suite_version=1" \
  "shared_feedback_host_inspection_runtime_contract_materialized=true" \
  "chat_composer_checkable_feedback_host_inspection_runtime_surface_materialized=true" \
  "stage609_feedback_host_inspection_input_state_bridge_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE608_SUITE_PACKET" "$fact"
done

src="$ROOT_DIR/src/runtime_renderer_stage609_feedback_host_inspection_input_state_bridge.cj"
if [[ ! -f "$src" ]]; then
  echo "cjgui stage609 feedback host inspection input-state bridge suite: missing source $src" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
  echo "cjgui stage609 feedback host inspection input-state bridge suite: public or foreign declaration found in $src" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage609 feedback host inspection input-state bridge suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage609_feedback_host_inspection_input_state_bridge_suite_version=1"
  echo "stage608_feedback_host_inspection_runtime_contract_suite_packet=$STAGE608_SUITE_PACKET"
  echo "stage609_feedback_host_inspection_input_state_bridge_owner_passed=true"
  echo "stage608_feedback_host_inspection_runtime_contract_consumed=true"
  echo "shared_feedback_host_inspection_input_state_bridge_materialized=true"
  echo "validation_input_state_delta_dry_run_materialized=true"
  echo "input_feedback_state_delta_dry_run_materialized=true"
  echo "focus_transition_state_delta_dry_run_materialized=true"
  echo "todo_feedback_host_inspection_input_state_delta_materialized=true"
  echo "settings_feedback_host_inspection_input_state_delta_materialized=true"
  echo "ai_generated_settings_feedback_host_inspection_input_state_delta_materialized=true"
  echo "chat_composer_feedback_host_inspection_input_state_delta_materialized=true"
  echo "input_state_bridge_bound_to_stage608_runtime_surfaces=true"
  echo "stage610_feedback_host_inspection_state_render_refresh_bridge_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage609_feedback_host_inspection_input_state_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage609 feedback host inspection input-state bridge suite: route_classification=input_state_bridge_ready"
echo "cjgui stage609 feedback host inspection input-state bridge suite: suite_packet_path=$SUITE_PACKET"
