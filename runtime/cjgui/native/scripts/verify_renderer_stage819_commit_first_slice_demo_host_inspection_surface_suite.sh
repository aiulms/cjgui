#!/usr/bin/env zsh
#
# Focused suite for stage819. It consumes stage818 and records five demo-host
# inspection/result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE819_TMPDIR:-/private/tmp/cjgui-stage817-stage820/stage819}"
SUITE_PACKET="$TMP_DIR/stage819-commit-first-slice-demo-host-inspection-surface-suite.packet"
STAGE818_SUITE_PACKET="${CJGUI_STAGE819_INPUT_PACKET:-${CJGUI_STAGE818_COMMIT_FIRST_SLICE_INSPECTION_FILTER_CONTROLLER_SUITE_PACKET:-/private/tmp/cjgui-stage817-stage820/stage818/stage818-commit-first-slice-inspection-filter-controller-suite.packet}}"
STAGE818_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage818_commit_first_slice_inspection_filter_controller_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage819_commit_first_slice_demo_host_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage819-commit-first-slice-demo-host-inspection-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage819 commit first-slice demo-host inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE818_SUITE_PACKET" ]] || ! grep -F "stage818_commit_first_slice_inspection_filter_controller_suite_passed=true" "$STAGE818_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE818_TMPDIR="$TMP_DIR/stage818" zsh "$STAGE818_SUITE_SCRIPT" >/dev/null
  STAGE818_SUITE_PACKET="$TMP_DIR/stage818/stage818-commit-first-slice-inspection-filter-controller-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage818_commit_first_slice_inspection_filter_controller_consumed=true" \
  "todo_commit_first_slice_inspection_surface_materialized=true" \
  "settings_commit_first_slice_inspection_surface_materialized=true" \
  "ai_generated_settings_commit_first_slice_inspection_surface_materialized=true" \
  "chat_composer_commit_first_slice_inspection_surface_materialized=true" \
  "file_browser_commit_first_slice_inspection_surface_materialized=true" \
  "commit_first_slice_host_inspection_result_surface_materialized=true" \
  "commit_first_slice_demo_surfaces_bound_to_stage818_filter_controller=true" \
  "stage820_commit_first_slice_host_inspection_runtime_presenter_prepared=true" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage818_commit_first_slice_inspection_filter_controller_suite_passed=true" \
  "commit_first_slice_demo_host_query_contract_materialized=true" \
  "commit_first_slice_rollback_proof_route_materialized=true"; do
  require_file_fact "$STAGE818_SUITE_PACKET" "$fact"
done

{
  echo "stage819_commit_first_slice_demo_host_inspection_surface_suite_version=1"
  echo "stage818_suite_packet=$STAGE818_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage819_commit_first_slice_demo_host_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage819 commit first-slice demo-host inspection surface suite: route_classification=commit_demo_host_inspection_surface"
echo "cjgui stage819 commit first-slice demo-host inspection surface suite: suite_packet_path=$SUITE_PACKET"
