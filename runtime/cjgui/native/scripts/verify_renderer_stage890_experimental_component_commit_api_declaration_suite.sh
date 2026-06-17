#!/usr/bin/env zsh
#
# Focused suite for stage890. It consumes stage889 and verifies the one-symbol
# experimental public component commit API declaration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE890_TMPDIR:-/private/tmp/cjgui-stage889-stage892/stage890}"
SUITE_PACKET="$TMP_DIR/stage890-experimental-component-commit-api-declaration-suite.packet"
STAGE889_SUITE_PACKET="${CJGUI_STAGE890_INPUT_PACKET:-${CJGUI_STAGE889_MINIMAL_PUBLIC_COMPONENT_COMMIT_API_READINESS_SUITE_PACKET:-/private/tmp/cjgui-stage889-stage892/stage889/stage889-minimal-public-component-commit-api-readiness-suite.packet}}"
STAGE889_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage889_minimal_public_component_commit_api_readiness_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage890_experimental_component_commit_api_declaration_owner.sh"
OWNER_LOG="$TMP_DIR/stage890-experimental-component-commit-api-declaration-owner.log"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage890_experimental_component_commit_api_declaration.cj"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage890 experimental component commit api declaration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE889_SUITE_PACKET" ]] || ! grep -F "stage889_minimal_public_component_commit_api_readiness_suite_passed=true" "$STAGE889_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE889_TMPDIR="$TMP_DIR/stage889" zsh "$STAGE889_SUITE_SCRIPT" >/dev/null
  STAGE889_SUITE_PACKET="$TMP_DIR/stage889/stage889-minimal-public-component-commit-api-readiness-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage889_minimal_public_component_commit_api_readiness_consumed=true" \
  "experimental_component_commit_readiness_api_materialized=true" \
  "public_surface_cjguiExperimentalComponentCommitApiReady_materialized=true" \
  "only_cjguiExperimentalComponentCommitApiReady_exposed_as_new_surface=true" \
  "public_commit_api_bound_to_stage889_readiness=true" \
  "public_commit_api_stable_compatibility_unpromised=true" \
  "stage891_component_commit_api_demo_consumption_prepared=true" \
  "new_public_surface_added=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage889_minimal_public_component_commit_api_readiness_suite_passed=true" \
  "component_commit_api_compatibility_ledger_materialized=true" \
  "component_commit_api_not_published_receipt_materialized=true" \
  "stable_public_api_added=false"; do
  require_file_fact "$STAGE889_SUITE_PACKET" "$fact"
done

if ! sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E '^public[[:space:]]+func[[:space:]]+cjguiExperimentalComponentCommitApiReady\(\):[[:space:]]+Bool' >/dev/null 2>&1; then
  echo "cjgui stage890 experimental component commit api declaration suite: missing exact public component commit function" >&2
  exit 10
fi

{
  echo "stage890_experimental_component_commit_api_declaration_suite_version=1"
  echo "stage889_suite_packet=$STAGE889_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage890_public_declaration_scan=cjguiExperimentalComponentCommitApiReady"
  echo "stage890_experimental_component_commit_api_declaration_suite_passed=true"
  echo "next_route=stage891_component_commit_api_demo_consumption_after_stage890"
} > "$SUITE_PACKET"

echo "cjgui stage890 experimental component commit api declaration suite: route_classification=experimental_public_commit_api_declaration"
echo "cjgui stage890 experimental component commit api declaration suite: suite_packet_path=$SUITE_PACKET"
