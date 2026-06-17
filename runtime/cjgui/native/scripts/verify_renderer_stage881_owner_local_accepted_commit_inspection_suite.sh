#!/usr/bin/env zsh
#
# Focused suite for stage881. It consumes stage880 and records the accepted
# commit inspection gate without granting or publishing acceptance.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE881_TMPDIR:-/private/tmp/cjgui-stage881-stage884/stage881}"
SUITE_PACKET="$TMP_DIR/stage881-owner-local-accepted-commit-inspection-suite.packet"
STAGE880_SUITE_PACKET="${CJGUI_STAGE881_INPUT_PACKET:-${CJGUI_STAGE880_OWNER_LOCAL_COMMIT_ACCEPTANCE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage877-stage880/stage880/stage880-owner-local-commit-acceptance-runtime-manager-suite.packet}}"
STAGE880_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage880_owner_local_commit_acceptance_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage881_owner_local_accepted_commit_inspection_owner.sh"
OWNER_LOG="$TMP_DIR/stage881-owner-local-accepted-commit-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage881 owner-local accepted commit inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE880_SUITE_PACKET" ]] || ! grep -F "stage880_owner_local_commit_acceptance_runtime_manager_suite_passed=true" "$STAGE880_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE880_TMPDIR="$TMP_DIR/stage880" zsh "$STAGE880_SUITE_SCRIPT" >/dev/null
  STAGE880_SUITE_PACKET="$TMP_DIR/stage880/stage880-owner-local-commit-acceptance-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage880_owner_local_commit_acceptance_runtime_manager_suite_passed=true" \
  "stage881_owner_local_accepted_commit_inspection_prepared=true" \
  "shared_owner_local_commit_acceptance_runtime_manager_materialized=true" \
  "common_owner_local_commit_acceptance_executor_materialized=true"; do
  require_file_fact "$STAGE880_SUITE_PACKET" "$fact"
done

for fact in \
  "stage880_owner_local_commit_acceptance_runtime_manager_consumed=true" \
  "owner_local_accepted_commit_inspection_gate_materialized=true" \
  "accepted_commit_candidate_lens_materialized=true" \
  "accepted_commit_decision_replay_boundary_materialized=true" \
  "accepted_commit_patch_preview_ledger_materialized=true" \
  "accepted_commit_inspection_bound_to_acceptance_runtime=true" \
  "stage882_owner_local_accepted_commit_application_plan_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage881_owner_local_accepted_commit_inspection_suite_version=1"
  echo "stage880_suite_packet=$STAGE880_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage882_owner_local_accepted_commit_application_plan_after_stage881"
  echo "stage881_owner_local_accepted_commit_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage881 owner-local accepted commit inspection suite: route_classification=accepted_commit_inspection_gate"
echo "cjgui stage881 owner-local accepted commit inspection suite: suite_packet_path=$SUITE_PACKET"
