#!/usr/bin/env zsh
#
# Focused suite for stage821. It consumes stage820 and records an owner review
# gate over the shared host inspection presenter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE821_TMPDIR:-/private/tmp/cjgui-stage821-stage824/stage821}"
SUITE_PACKET="$TMP_DIR/stage821-commit-first-slice-owner-review-gate-suite.packet"
STAGE820_SUITE_PACKET="${CJGUI_STAGE821_INPUT_PACKET:-${CJGUI_STAGE820_COMMIT_FIRST_SLICE_HOST_INSPECTION_RUNTIME_PRESENTER_SUITE_PACKET:-/private/tmp/cjgui-stage817-stage820/stage820/stage820-commit-first-slice-host-inspection-runtime-presenter-suite.packet}}"
STAGE820_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage820_commit_first_slice_host_inspection_runtime_presenter_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage821_commit_first_slice_owner_review_gate_owner.sh"
OWNER_LOG="$TMP_DIR/stage821-commit-first-slice-owner-review-gate-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage821 commit first-slice owner review gate suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE820_SUITE_PACKET" ]] || ! grep -F "stage820_commit_first_slice_host_inspection_runtime_presenter_suite_passed=true" "$STAGE820_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE820_TMPDIR="$TMP_DIR/stage820" zsh "$STAGE820_SUITE_SCRIPT" >/dev/null
  STAGE820_SUITE_PACKET="$TMP_DIR/stage820/stage820-commit-first-slice-host-inspection-runtime-presenter-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage820_commit_first_slice_host_inspection_runtime_presenter_consumed=true" \
  "commit_first_slice_owner_review_gate_materialized=true" \
  "commit_first_slice_acceptability_review_route_materialized=true" \
  "commit_first_slice_request_changes_review_route_materialized=true" \
  "commit_first_slice_reject_reason_review_route_materialized=true" \
  "commit_first_slice_owner_review_gate_bound_to_stage820_presenter=true" \
  "stage822_commit_first_slice_review_decision_router_prepared=true" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage820_commit_first_slice_host_inspection_runtime_presenter_suite_passed=true" \
  "shared_commit_host_inspection_runtime_presenter_materialized=true" \
  "stage821_commit_first_slice_owner_review_gate_after_stage820_prepared=true"; do
  require_file_fact "$STAGE820_SUITE_PACKET" "$fact"
done

{
  echo "stage821_commit_first_slice_owner_review_gate_suite_version=1"
  echo "stage820_suite_packet=$STAGE820_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage821_commit_first_slice_owner_review_gate_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage821 commit first-slice owner review gate suite: route_classification=commit_owner_review_gate"
echo "cjgui stage821 commit first-slice owner review gate suite: suite_packet_path=$SUITE_PACKET"
