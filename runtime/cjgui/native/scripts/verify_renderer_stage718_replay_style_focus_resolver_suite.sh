#!/usr/bin/env zsh
#
# Focused suite for stage718 replay style/focus resolver.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE718_TMPDIR:-/private/tmp/cjgui-stage717-stage720/stage718}"
SUITE_PACKET="$TMP_DIR/stage718-replay-style-focus-resolver-suite.packet"
STAGE717_SUITE_PACKET="${CJGUI_STAGE718_INPUT_PACKET:-${CJGUI_STAGE717_REPLAY_VISUAL_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage717-stage720/stage717/stage717-replay-visual-preview-suite.packet}}"
STAGE717_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage717_replay_visual_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage718_replay_style_focus_resolver_owner.sh"
OWNER_LOG="$TMP_DIR/stage718-replay-style-focus-resolver-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage718 replay style/focus resolver suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE717_SUITE_PACKET" ]]; then
  zsh "$STAGE717_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage717_replay_visual_preview_consumed=true" \
  "shared_replay_style_resolver_dry_run_materialized=true" \
  "shared_replay_focus_manager_dry_run_materialized=true" \
  "resolved_visual_style_ledger_materialized=true" \
  "focus_movement_ledger_materialized=true" \
  "validation_focus_handoff_ledger_materialized=true" \
  "stage719_replay_text_caret_host_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage717_replay_visual_preview_suite_version=1" \
  "shared_replay_layout_style_text_focus_preview_materialized=true" \
  "stage718_replay_style_focus_resolver_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE717_SUITE_PACKET" "$fact"
done

{
  echo "stage718_replay_style_focus_resolver_suite_version=1"
  echo "stage717_replay_visual_preview_suite_packet=$STAGE717_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage718_replay_style_focus_resolver_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage718 replay style/focus resolver suite: route_classification=replay_style_focus_resolver_ready"
echo "cjgui stage718 replay style/focus resolver suite: suite_packet_path=$SUITE_PACKET"
