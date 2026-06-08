#!/usr/bin/env zsh
#
# Focused suite for stage827. It consumes stage826 and records publication
# preview/result surfaces across five demo hosts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE827_TMPDIR:-/private/tmp/cjgui-stage825-stage828/stage827}"
SUITE_PACKET="$TMP_DIR/stage827-commit-first-slice-publication-demo-host-surface-suite.packet"
STAGE826_SUITE_PACKET="${CJGUI_STAGE827_INPUT_PACKET:-${CJGUI_STAGE826_COMMIT_FIRST_SLICE_PUBLICATION_VISIBILITY_REHEARSAL_SUITE_PACKET:-/private/tmp/cjgui-stage825-stage828/stage826/stage826-commit-first-slice-publication-visibility-rehearsal-suite.packet}}"
STAGE826_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage826_commit_first_slice_publication_visibility_rehearsal_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage827_commit_first_slice_publication_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage827-commit-first-slice-publication-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage827 commit first-slice publication demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE826_SUITE_PACKET" ]] || ! grep -F "stage826_commit_first_slice_publication_visibility_rehearsal_suite_passed=true" "$STAGE826_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE826_TMPDIR="$TMP_DIR/stage826" zsh "$STAGE826_SUITE_SCRIPT" >/dev/null
  STAGE826_SUITE_PACKET="$TMP_DIR/stage826/stage826-commit-first-slice-publication-visibility-rehearsal-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage826_commit_first_slice_publication_visibility_rehearsal_consumed=true" \
  "todo_commit_first_slice_publication_preview_surface_materialized=true" \
  "settings_commit_first_slice_publication_preview_surface_materialized=true" \
  "ai_generated_settings_commit_first_slice_publication_preview_surface_materialized=true" \
  "chat_composer_commit_first_slice_publication_preview_surface_materialized=true" \
  "file_browser_commit_first_slice_publication_preview_surface_materialized=true" \
  "commit_first_slice_publication_result_surface_materialized=true" \
  "publication_demo_surfaces_bound_to_stage826_visibility_rehearsal=true" \
  "stage828_commit_first_slice_publication_runtime_manager_prepared=true" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage826_commit_first_slice_publication_visibility_rehearsal_suite_passed=true" \
  "visibility_publication_rehearsal_ledger_materialized=true" \
  "not_published_visibility_receipt_materialized=true"; do
  require_file_fact "$STAGE826_SUITE_PACKET" "$fact"
done

{
  echo "stage827_commit_first_slice_publication_demo_host_surface_suite_version=1"
  echo "stage826_suite_packet=$STAGE826_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage827_commit_first_slice_publication_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage827 commit first-slice publication demo-host surface suite: route_classification=commit_publication_demo_host_surface"
echo "cjgui stage827 commit first-slice publication demo-host surface suite: suite_packet_path=$SUITE_PACKET"
