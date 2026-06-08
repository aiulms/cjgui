#!/usr/bin/env zsh
#
# Focused suite for stage826. It consumes stage825 and records rollback-safe
# visibility rehearsal ledgers without publishing visibility.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE826_TMPDIR:-/private/tmp/cjgui-stage825-stage828/stage826}"
SUITE_PACKET="$TMP_DIR/stage826-commit-first-slice-publication-visibility-rehearsal-suite.packet"
STAGE825_SUITE_PACKET="${CJGUI_STAGE826_INPUT_PACKET:-${CJGUI_STAGE825_COMMIT_FIRST_SLICE_PUBLICATION_GATE_SUITE_PACKET:-/private/tmp/cjgui-stage825-stage828/stage825/stage825-commit-first-slice-publication-gate-suite.packet}}"
STAGE825_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage825_commit_first_slice_publication_gate_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage826_commit_first_slice_publication_visibility_rehearsal_owner.sh"
OWNER_LOG="$TMP_DIR/stage826-commit-first-slice-publication-visibility-rehearsal-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage826 commit first-slice publication visibility rehearsal suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE825_SUITE_PACKET" ]] || ! grep -F "stage825_commit_first_slice_publication_gate_suite_passed=true" "$STAGE825_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE825_TMPDIR="$TMP_DIR/stage825" zsh "$STAGE825_SUITE_SCRIPT" >/dev/null
  STAGE825_SUITE_PACKET="$TMP_DIR/stage825/stage825-commit-first-slice-publication-gate-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage825_commit_first_slice_publication_gate_consumed=true" \
  "visibility_publication_rehearsal_ledger_materialized=true" \
  "rollback_visibility_snapshot_materialized=true" \
  "owner_approval_publication_hold_materialized=true" \
  "not_published_visibility_receipt_materialized=true" \
  "visibility_rehearsal_bound_to_stage825_publication_gate=true" \
  "stage827_commit_first_slice_publication_demo_host_surface_prepared=true" \
  "state_store_commit_published=false" \
  "visibility_published=false" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage825_commit_first_slice_publication_gate_suite_passed=true" \
  "owner_local_publication_gate_materialized=true" \
  "visibility_publication_predicate_ledger_materialized=true"; do
  require_file_fact "$STAGE825_SUITE_PACKET" "$fact"
done

{
  echo "stage826_commit_first_slice_publication_visibility_rehearsal_suite_version=1"
  echo "stage825_suite_packet=$STAGE825_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage826_commit_first_slice_publication_visibility_rehearsal_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage826 commit first-slice publication visibility rehearsal suite: route_classification=commit_publication_visibility_rehearsal"
echo "cjgui stage826 commit first-slice publication visibility rehearsal suite: suite_packet_path=$SUITE_PACKET"
