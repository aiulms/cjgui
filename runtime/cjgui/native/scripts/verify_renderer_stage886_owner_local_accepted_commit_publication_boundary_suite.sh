#!/usr/bin/env zsh
#
# Focused suite for stage886. It consumes stage885 and records rollback /
# not-published publication boundary facts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE886_TMPDIR:-/private/tmp/cjgui-stage885-stage888/stage886}"
SUITE_PACKET="$TMP_DIR/stage886-owner-local-accepted-commit-publication-boundary-suite.packet"
STAGE885_SUITE_PACKET="${CJGUI_STAGE886_INPUT_PACKET:-${CJGUI_STAGE885_OWNER_LOCAL_ACCEPTED_COMMIT_PUBLICATION_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage885-stage888/stage885/stage885-owner-local-accepted-commit-publication-preflight-suite.packet}}"
STAGE885_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage885_owner_local_accepted_commit_publication_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage886_owner_local_accepted_commit_publication_boundary_owner.sh"
OWNER_LOG="$TMP_DIR/stage886-owner-local-accepted-commit-publication-boundary-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage886 owner-local accepted commit publication boundary suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE885_SUITE_PACKET" ]] || ! grep -F "stage885_owner_local_accepted_commit_publication_preflight_suite_passed=true" "$STAGE885_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE885_TMPDIR="$TMP_DIR/stage885" zsh "$STAGE885_SUITE_SCRIPT" >/dev/null
  STAGE885_SUITE_PACKET="$TMP_DIR/stage885/stage885-owner-local-accepted-commit-publication-preflight-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage885_owner_local_accepted_commit_publication_preflight_suite_passed=true" \
  "owner_local_accepted_commit_publication_preflight_materialized=true" \
  "stage886_owner_local_accepted_commit_publication_boundary_prepared=true"; do
  require_file_fact "$STAGE885_SUITE_PACKET" "$fact"
done

for fact in \
  "stage885_owner_local_accepted_commit_publication_preflight_consumed=true" \
  "accepted_commit_publication_rollback_snapshot_materialized=true" \
  "accepted_commit_publication_rollback_token_materialized=true" \
  "accepted_commit_publication_not_published_receipt_materialized=true" \
  "visibility_publication_not_published_boundary_materialized=true" \
  "state_store_write_denied_receipt_materialized=true" \
  "stage887_owner_local_accepted_commit_publication_demo_surface_prepared=true" \
  "visibility_published=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage886_owner_local_accepted_commit_publication_boundary_suite_version=1"
  echo "stage885_suite_packet=$STAGE885_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage887_owner_local_accepted_commit_publication_demo_surface_after_stage886"
  echo "stage886_owner_local_accepted_commit_publication_boundary_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage886 owner-local accepted commit publication boundary suite: route_classification=accepted_commit_publication_boundary"
echo "cjgui stage886 owner-local accepted commit publication boundary suite: suite_packet_path=$SUITE_PACKET"
