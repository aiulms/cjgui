#!/usr/bin/env zsh
#
# Focused suite for stage885. It consumes stage884 and records the accepted
# commit publication preflight boundary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE885_TMPDIR:-/private/tmp/cjgui-stage885-stage888/stage885}"
SUITE_PACKET="$TMP_DIR/stage885-owner-local-accepted-commit-publication-preflight-suite.packet"
STAGE884_SUITE_PACKET="${CJGUI_STAGE885_INPUT_PACKET:-${CJGUI_STAGE884_OWNER_LOCAL_ACCEPTED_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage881-stage884/stage884/stage884-owner-local-accepted-commit-runtime-manager-suite.packet}}"
STAGE884_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage884_owner_local_accepted_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage885_owner_local_accepted_commit_publication_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage885-owner-local-accepted-commit-publication-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage885 owner-local accepted commit publication preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE884_SUITE_PACKET" ]] || ! grep -F "stage884_owner_local_accepted_commit_runtime_manager_suite_passed=true" "$STAGE884_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE884_TMPDIR="$TMP_DIR/stage884" zsh "$STAGE884_SUITE_SCRIPT" >/dev/null
  STAGE884_SUITE_PACKET="$TMP_DIR/stage884/stage884-owner-local-accepted-commit-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage884_owner_local_accepted_commit_runtime_manager_suite_passed=true" \
  "shared_owner_local_accepted_commit_runtime_manager_materialized=true" \
  "stage885_owner_local_accepted_commit_publication_preflight_prepared=true"; do
  require_file_fact "$STAGE884_SUITE_PACKET" "$fact"
done

for fact in \
  "stage884_owner_local_accepted_commit_runtime_manager_consumed=true" \
  "owner_local_accepted_commit_publication_preflight_materialized=true" \
  "accepted_commit_publication_candidate_ledger_materialized=true" \
  "accepted_commit_visibility_predicate_ledger_materialized=true" \
  "accepted_commit_state_store_write_denylist_materialized=true" \
  "publication_preflight_bound_to_stage884_runtime_manager=true" \
  "stage886_owner_local_accepted_commit_publication_boundary_prepared=true" \
  "visibility_publication_admitted=false" \
  "state_store_write_executed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage885_owner_local_accepted_commit_publication_preflight_suite_version=1"
  echo "stage884_suite_packet=$STAGE884_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage886_owner_local_accepted_commit_publication_boundary_after_stage885"
  echo "stage885_owner_local_accepted_commit_publication_preflight_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage885 owner-local accepted commit publication preflight suite: route_classification=accepted_commit_publication_preflight"
echo "cjgui stage885 owner-local accepted commit publication preflight suite: suite_packet_path=$SUITE_PACKET"
