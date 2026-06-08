#!/usr/bin/env zsh
#
# Focused suite for stage825. It consumes stage824 and records an owner-local
# publication gate without admitting visibility publication.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE825_TMPDIR:-/private/tmp/cjgui-stage825-stage828/stage825}"
SUITE_PACKET="$TMP_DIR/stage825-commit-first-slice-publication-gate-suite.packet"
STAGE824_SUITE_PACKET="${CJGUI_STAGE825_INPUT_PACKET:-${CJGUI_STAGE824_COMMIT_FIRST_SLICE_OWNER_REVIEW_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage821-stage824/stage824/stage824-commit-first-slice-owner-review-runtime-manager-suite.packet}}"
STAGE824_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage824_commit_first_slice_owner_review_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage825_commit_first_slice_publication_gate_owner.sh"
OWNER_LOG="$TMP_DIR/stage825-commit-first-slice-publication-gate-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage825 commit first-slice publication gate suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE824_SUITE_PACKET" ]] || ! grep -F "stage824_commit_first_slice_owner_review_runtime_manager_suite_passed=true" "$STAGE824_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE824_TMPDIR="$TMP_DIR/stage824" zsh "$STAGE824_SUITE_SCRIPT" >/dev/null
  STAGE824_SUITE_PACKET="$TMP_DIR/stage824/stage824-commit-first-slice-owner-review-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage824_commit_first_slice_owner_review_runtime_manager_consumed=true" \
  "owner_local_publication_gate_materialized=true" \
  "commit_slot_publication_allowlist_materialized=true" \
  "rollback_safe_publication_policy_materialized=true" \
  "visibility_publication_predicate_ledger_materialized=true" \
  "publication_gate_bound_to_stage824_owner_review_runtime=true" \
  "stage826_commit_first_slice_publication_visibility_rehearsal_prepared=true" \
  "state_store_commit_published=false" \
  "visibility_publication_admitted=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage824_commit_first_slice_owner_review_runtime_manager_suite_passed=true" \
  "shared_owner_review_runtime_manager_materialized=true" \
  "stage825_commit_first_slice_publication_gate_after_stage824_prepared=true"; do
  require_file_fact "$STAGE824_SUITE_PACKET" "$fact"
done

{
  echo "stage825_commit_first_slice_publication_gate_suite_version=1"
  echo "stage824_suite_packet=$STAGE824_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage825_commit_first_slice_publication_gate_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage825 commit first-slice publication gate suite: route_classification=commit_publication_gate"
echo "cjgui stage825 commit first-slice publication gate suite: suite_packet_path=$SUITE_PACKET"
