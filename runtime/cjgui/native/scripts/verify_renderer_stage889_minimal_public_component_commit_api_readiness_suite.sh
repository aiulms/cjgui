#!/usr/bin/env zsh
#
# Focused suite for stage889. It consumes stage888 and records readiness for a
# minimal experimental public component commit API.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE889_TMPDIR:-/private/tmp/cjgui-stage889-stage892/stage889}"
SUITE_PACKET="$TMP_DIR/stage889-minimal-public-component-commit-api-readiness-suite.packet"
STAGE888_SUITE_PACKET="${CJGUI_STAGE889_INPUT_PACKET:-${CJGUI_STAGE888_OWNER_LOCAL_ACCEPTED_COMMIT_PUBLICATION_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage885-stage888/stage888/stage888-owner-local-accepted-commit-publication-runtime-manager-suite.packet}}"
STAGE888_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage888_owner_local_accepted_commit_publication_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage889_minimal_public_component_commit_api_readiness_owner.sh"
OWNER_LOG="$TMP_DIR/stage889-minimal-public-component-commit-api-readiness-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage889 minimal public component commit api readiness suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE888_SUITE_PACKET" ]] || ! grep -F "stage888_owner_local_accepted_commit_publication_runtime_manager_suite_passed=true" "$STAGE888_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE888_TMPDIR="$TMP_DIR/stage888" zsh "$STAGE888_SUITE_SCRIPT" >/dev/null
  STAGE888_SUITE_PACKET="$TMP_DIR/stage888/stage888-owner-local-accepted-commit-publication-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage888_owner_local_accepted_commit_publication_runtime_manager_consumed=true" \
  "minimal_public_component_commit_api_readiness_materialized=true" \
  "experimental_component_commit_api_descriptor_materialized=true" \
  "component_commit_api_compatibility_ledger_materialized=true" \
  "component_commit_api_rollback_boundary_materialized=true" \
  "component_commit_api_not_published_receipt_materialized=true" \
  "component_commit_api_readiness_bound_to_publication_runtime_manager=true" \
  "stage890_experimental_component_commit_api_declaration_prepared=true" \
  "new_public_surface_added=false" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "state_store_write_executed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage888_owner_local_accepted_commit_publication_runtime_manager_suite_passed=true" \
  "shared_owner_local_accepted_commit_publication_runtime_manager_materialized=true" \
  "stage889_minimal_public_component_commit_api_readiness_prepared=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE888_SUITE_PACKET" "$fact"
done

{
  echo "stage889_minimal_public_component_commit_api_readiness_suite_version=1"
  echo "stage888_suite_packet=$STAGE888_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage889_minimal_public_component_commit_api_readiness_suite_passed=true"
  echo "next_route=stage890_experimental_component_commit_api_declaration_after_stage889"
} > "$SUITE_PACKET"

echo "cjgui stage889 minimal public component commit api readiness suite: route_classification=public_component_commit_api_readiness"
echo "cjgui stage889 minimal public component commit api readiness suite: suite_packet_path=$SUITE_PACKET"
