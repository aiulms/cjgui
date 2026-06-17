#!/usr/bin/env zsh
#
# Focused suite for stage887. It consumes stage886 and records demo-host
# publication inspection surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE887_TMPDIR:-/private/tmp/cjgui-stage885-stage888/stage887}"
SUITE_PACKET="$TMP_DIR/stage887-owner-local-accepted-commit-publication-demo-surface-suite.packet"
STAGE886_SUITE_PACKET="${CJGUI_STAGE887_INPUT_PACKET:-${CJGUI_STAGE886_OWNER_LOCAL_ACCEPTED_COMMIT_PUBLICATION_BOUNDARY_SUITE_PACKET:-/private/tmp/cjgui-stage885-stage888/stage886/stage886-owner-local-accepted-commit-publication-boundary-suite.packet}}"
STAGE886_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage886_owner_local_accepted_commit_publication_boundary_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage887_owner_local_accepted_commit_publication_demo_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage887-owner-local-accepted-commit-publication-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage887 owner-local accepted commit publication demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE886_SUITE_PACKET" ]] || ! grep -F "stage886_owner_local_accepted_commit_publication_boundary_suite_passed=true" "$STAGE886_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE886_TMPDIR="$TMP_DIR/stage886" zsh "$STAGE886_SUITE_SCRIPT" >/dev/null
  STAGE886_SUITE_PACKET="$TMP_DIR/stage886/stage886-owner-local-accepted-commit-publication-boundary-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage886_owner_local_accepted_commit_publication_boundary_suite_passed=true" \
  "accepted_commit_publication_not_published_receipt_materialized=true" \
  "stage887_owner_local_accepted_commit_publication_demo_surface_prepared=true"; do
  require_file_fact "$STAGE886_SUITE_PACKET" "$fact"
done

for fact in \
  "stage886_owner_local_accepted_commit_publication_boundary_consumed=true" \
  "todo_accepted_commit_publication_inspection_surface_materialized=true" \
  "settings_accepted_commit_publication_inspection_surface_materialized=true" \
  "ai_generated_settings_accepted_commit_publication_inspection_surface_materialized=true" \
  "chat_composer_accepted_commit_publication_inspection_surface_materialized=true" \
  "file_browser_accepted_commit_publication_inspection_surface_materialized=true" \
  "accepted_commit_publication_boundary_rows_materialized=true" \
  "accepted_commit_publication_surface_bound_to_boundary=true" \
  "stage888_owner_local_accepted_commit_publication_runtime_manager_prepared=true" \
  "visibility_published=false" \
  "state_store_write_executed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage887_owner_local_accepted_commit_publication_demo_surface_suite_version=1"
  echo "stage886_suite_packet=$STAGE886_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage888_owner_local_accepted_commit_publication_runtime_manager_after_stage887"
  echo "stage887_owner_local_accepted_commit_publication_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage887 owner-local accepted commit publication demo surface suite: route_classification=accepted_commit_publication_demo_surface"
echo "cjgui stage887 owner-local accepted commit publication demo surface suite: suite_packet_path=$SUITE_PACKET"
