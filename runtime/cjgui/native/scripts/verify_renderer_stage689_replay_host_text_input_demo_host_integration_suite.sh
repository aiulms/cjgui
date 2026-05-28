#!/usr/bin/env zsh
#
# Focused suite for stage689. It consumes stage688 and emits demo-host integration evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE689_TMPDIR:-/private/tmp/cjgui-stage689-stage692/stage689}"
SUITE_PACKET="$TMP_DIR/stage689-replay-host-text-input-demo-host-integration-suite.packet"
STAGE688_SUITE_PACKET="${CJGUI_STAGE689_INPUT_PACKET:-${CJGUI_STAGE688_REPLAY_HOST_TEXT_INPUT_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage685-stage688/stage688/stage688-replay-host-text-input-runtime-contract-suite.packet}}"
STAGE688_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage688_replay_host_text_input_runtime_contract_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage689_replay_host_text_input_demo_host_integration_owner.sh"
OWNER_LOG="$TMP_DIR/stage689-replay-host-text-input-demo-host-integration-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage689 replay host text input demo-host integration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE688_SUITE_PACKET" ]]; then
  zsh "$STAGE688_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage688_replay_host_text_input_runtime_contract_consumed=true" \
  "shared_replay_host_text_input_demo_host_integration_materialized=true" \
  "replay_host_text_input_host_slot_ledger_materialized=true" \
  "text_edit_commit_host_slot_materialized=true" \
  "validation_dismiss_host_slot_materialized=true" \
  "focus_move_host_slot_materialized=true" \
  "submit_host_slot_materialized=true" \
  "chat_composer_replay_host_text_input_demo_host_integration_materialized=true" \
  "stage690_replay_host_text_input_host_event_adapter_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage688_replay_host_text_input_runtime_contract_suite_version=1" \
  "shared_replay_host_text_input_runtime_contract_materialized=true" \
  "stage689_replay_host_text_input_demo_host_integration_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE688_SUITE_PACKET" "$fact"
done

{
  echo "stage689_replay_host_text_input_demo_host_integration_suite_version=1"
  echo "stage688_replay_host_text_input_runtime_contract_suite_packet=$STAGE688_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage689_replay_host_text_input_demo_host_integration_suite_passed=true"
  echo "next_route=stage690_replay_host_text_input_host_event_adapter_after_stage689"
} > "$SUITE_PACKET"

echo "cjgui stage689 replay host text input demo-host integration suite: route_classification=text_input_demo_host_integration_ready"
echo "cjgui stage689 replay host text input demo-host integration suite: suite_packet_path=$SUITE_PACKET"
