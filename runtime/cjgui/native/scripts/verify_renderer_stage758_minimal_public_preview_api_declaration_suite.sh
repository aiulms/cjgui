#!/usr/bin/env zsh
#
# Focused suite for stage758. It consumes stage757 and verifies the one-symbol
# experimental public preview API declaration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE758_TMPDIR:-/private/tmp/cjgui-stage757-stage760/stage758}"
SUITE_PACKET="$TMP_DIR/stage758-minimal-public-preview-api-declaration-suite.packet"
STAGE757_SUITE_PACKET="${CJGUI_STAGE758_INPUT_PACKET:-${CJGUI_STAGE757_MINIMAL_PUBLIC_PREVIEW_API_DESCRIPTOR_SUITE_PACKET:-/private/tmp/cjgui-stage757-stage760/stage757/stage757-minimal-public-preview-api-descriptor-suite.packet}}"
STAGE757_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage757_minimal_public_preview_api_descriptor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage758_minimal_public_preview_api_declaration_owner.sh"
OWNER_LOG="$TMP_DIR/stage758-minimal-public-preview-api-declaration-owner.log"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage758_minimal_public_preview_api_declaration.cj"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage758 minimal public preview api declaration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE757_SUITE_PACKET" ]] || ! grep -F "stage757_minimal_public_preview_api_descriptor_suite_passed=true" "$STAGE757_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE757_TMPDIR="$TMP_DIR/stage757" zsh "$STAGE757_SUITE_SCRIPT" >/dev/null
  STAGE757_SUITE_PACKET="$TMP_DIR/stage757/stage757-minimal-public-preview-api-descriptor-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage757_minimal_public_preview_api_descriptor_consumed=true" \
  "experimental_component_preview_readiness_api_materialized=true" \
  "public_surface_cjguiExperimentalComponentPreviewApiReady_materialized=true" \
  "public_component_api_added=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "public_preview_api_stable_compatibility_unpromised=true" \
  "stage759_minimal_public_preview_api_demo_consumption_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage757_minimal_public_preview_api_descriptor_suite_passed=true" \
  "minimal_public_preview_component_descriptor_materialized=true" \
  "preview_compatibility_ledger_materialized=true" \
  "stage758_minimal_public_preview_api_declaration_prepared=true"; do
  require_file_fact "$STAGE757_SUITE_PACKET" "$fact"
done

if ! sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E '^public[[:space:]]+func[[:space:]]+cjguiExperimentalComponentPreviewApiReady\(\):[[:space:]]+Bool' >/dev/null 2>&1; then
  echo "cjgui stage758 minimal public preview api declaration suite: missing exact public preview function" >&2
  exit 10
fi

{
  echo "stage758_minimal_public_preview_api_declaration_suite_version=1"
  echo "stage757_minimal_public_preview_api_descriptor_suite_packet=$STAGE757_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage758_public_declaration_scan=cjguiExperimentalComponentPreviewApiReady"
  echo "stage758_minimal_public_preview_api_declaration_suite_passed=true"
  echo "next_route=stage759_minimal_public_preview_api_demo_consumption_after_stage758"
} > "$SUITE_PACKET"

echo "cjgui stage758 minimal public preview api declaration suite: route_classification=preview_api_public_declaration_ready"
echo "cjgui stage758 minimal public preview api declaration suite: suite_packet_path=$SUITE_PACKET"
