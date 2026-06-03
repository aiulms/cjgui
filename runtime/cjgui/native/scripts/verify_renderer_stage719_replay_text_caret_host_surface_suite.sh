#!/usr/bin/env zsh
#
# Focused suite for stage719 replay text/caret host surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE719_TMPDIR:-/private/tmp/cjgui-stage717-stage720/stage719}"
SUITE_PACKET="$TMP_DIR/stage719-replay-text-caret-host-surface-suite.packet"
STAGE718_SUITE_PACKET="${CJGUI_STAGE719_INPUT_PACKET:-${CJGUI_STAGE718_REPLAY_STYLE_FOCUS_RESOLVER_SUITE_PACKET:-/private/tmp/cjgui-stage717-stage720/stage718/stage718-replay-style-focus-resolver-suite.packet}}"
STAGE718_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage718_replay_style_focus_resolver_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage719_replay_text_caret_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage719-replay-text-caret-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage719 replay text/caret host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE718_SUITE_PACKET" ]]; then
  zsh "$STAGE718_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage718_replay_style_focus_resolver_consumed=true" \
  "shared_replay_text_caret_model_materialized=true" \
  "replay_text_selection_ledger_materialized=true" \
  "replay_caret_position_ledger_materialized=true" \
  "replay_composition_placeholder_ledger_materialized=true" \
  "replay_demo_host_inspection_surface_materialized=true" \
  "stage720_replay_visual_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage718_replay_style_focus_resolver_suite_version=1" \
  "shared_replay_style_resolver_dry_run_materialized=true" \
  "shared_replay_focus_manager_dry_run_materialized=true" \
  "stage719_replay_text_caret_host_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE718_SUITE_PACKET" "$fact"
done

{
  echo "stage719_replay_text_caret_host_surface_suite_version=1"
  echo "stage718_replay_style_focus_resolver_suite_packet=$STAGE718_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage719_replay_text_caret_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage719 replay text/caret host surface suite: route_classification=replay_text_caret_host_surface_ready"
echo "cjgui stage719 replay text/caret host surface suite: suite_packet_path=$SUITE_PACKET"
