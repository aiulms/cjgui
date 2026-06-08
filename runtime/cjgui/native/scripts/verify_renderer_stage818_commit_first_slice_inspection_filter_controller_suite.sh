#!/usr/bin/env zsh
#
# Focused suite for stage818. It consumes stage817 and records the shared
# inspection filter / rollback proof controller.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE818_TMPDIR:-/private/tmp/cjgui-stage817-stage820/stage818}"
SUITE_PACKET="$TMP_DIR/stage818-commit-first-slice-inspection-filter-controller-suite.packet"
STAGE817_SUITE_PACKET="${CJGUI_STAGE818_INPUT_PACKET:-${CJGUI_STAGE817_COMMIT_FIRST_SLICE_HOST_INSPECTION_LENS_SUITE_PACKET:-/private/tmp/cjgui-stage817-stage820/stage817/stage817-commit-first-slice-host-inspection-lens-suite.packet}}"
STAGE817_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage817_commit_first_slice_host_inspection_lens_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage818_commit_first_slice_inspection_filter_controller_owner.sh"
OWNER_LOG="$TMP_DIR/stage818-commit-first-slice-inspection-filter-controller-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage818 commit first-slice inspection filter controller suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE817_SUITE_PACKET" ]] || ! grep -F "stage817_commit_first_slice_host_inspection_lens_suite_passed=true" "$STAGE817_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE817_TMPDIR="$TMP_DIR/stage817" zsh "$STAGE817_SUITE_SCRIPT" >/dev/null
  STAGE817_SUITE_PACKET="$TMP_DIR/stage817/stage817-commit-first-slice-host-inspection-lens-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage817_commit_first_slice_host_inspection_lens_consumed=true" \
  "commit_first_slice_inspection_filter_controller_materialized=true" \
  "commit_first_slice_rollback_proof_route_materialized=true" \
  "commit_first_slice_denied_write_set_filter_materialized=true" \
  "commit_first_slice_not_published_boundary_filter_materialized=true" \
  "commit_first_slice_demo_host_query_contract_materialized=true" \
  "commit_first_slice_inspection_filter_controller_bound_to_stage817_lens=true" \
  "stage819_commit_first_slice_demo_host_inspection_surface_prepared=true" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage817_commit_first_slice_host_inspection_lens_suite_passed=true" \
  "commit_first_slice_write_set_inspection_rows_materialized=true" \
  "commit_first_slice_denial_ledger_inspection_rows_materialized=true"; do
  require_file_fact "$STAGE817_SUITE_PACKET" "$fact"
done

{
  echo "stage818_commit_first_slice_inspection_filter_controller_suite_version=1"
  echo "stage817_suite_packet=$STAGE817_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage818_commit_first_slice_inspection_filter_controller_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage818 commit first-slice inspection filter controller suite: route_classification=commit_inspection_filter_controller"
echo "cjgui stage818 commit first-slice inspection filter controller suite: suite_packet_path=$SUITE_PACKET"
