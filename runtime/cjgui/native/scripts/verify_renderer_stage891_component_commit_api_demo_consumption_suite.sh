#!/usr/bin/env zsh
#
# Focused suite for stage891. It consumes stage890 and verifies five demo
# surfaces can inspect the experimental public component commit API.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE891_TMPDIR:-/private/tmp/cjgui-stage889-stage892/stage891}"
SUITE_PACKET="$TMP_DIR/stage891-component-commit-api-demo-consumption-suite.packet"
STAGE890_SUITE_PACKET="${CJGUI_STAGE891_INPUT_PACKET:-${CJGUI_STAGE890_EXPERIMENTAL_COMPONENT_COMMIT_API_DECLARATION_SUITE_PACKET:-/private/tmp/cjgui-stage889-stage892/stage890/stage890-experimental-component-commit-api-declaration-suite.packet}}"
STAGE890_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage890_experimental_component_commit_api_declaration_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage891_component_commit_api_demo_consumption_owner.sh"
OWNER_LOG="$TMP_DIR/stage891-component-commit-api-demo-consumption-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage891 component commit api demo consumption suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE890_SUITE_PACKET" ]] || ! grep -F "stage890_experimental_component_commit_api_declaration_suite_passed=true" "$STAGE890_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE890_TMPDIR="$TMP_DIR/stage890" zsh "$STAGE890_SUITE_SCRIPT" >/dev/null
  STAGE890_SUITE_PACKET="$TMP_DIR/stage890/stage890-experimental-component-commit-api-declaration-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage890_experimental_component_commit_api_declaration_consumed=true" \
  "cjguiExperimentalComponentCommitApiReady_consumed=true" \
  "todo_component_commit_api_demo_surface_materialized=true" \
  "settings_component_commit_api_demo_surface_materialized=true" \
  "ai_generated_settings_component_commit_api_demo_surface_materialized=true" \
  "chat_composer_component_commit_api_demo_surface_materialized=true" \
  "file_browser_component_commit_api_demo_surface_materialized=true" \
  "demo_consumption_bound_to_experimental_commit_api=true" \
  "demo_consumption_bound_to_stage888_publication_runtime_manager_transitively=true" \
  "stage892_component_commit_api_runtime_manager_prepared=true" \
  "new_public_surface_added=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage890_experimental_component_commit_api_declaration_suite_passed=true" \
  "public_surface_cjguiExperimentalComponentCommitApiReady_materialized=true" \
  "new_public_surface_added=true" \
  "stable_public_api_added=false"; do
  require_file_fact "$STAGE890_SUITE_PACKET" "$fact"
done

{
  echo "stage891_component_commit_api_demo_consumption_suite_version=1"
  echo "stage890_suite_packet=$STAGE890_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage891_component_commit_api_demo_consumption_suite_passed=true"
  echo "next_route=stage892_component_commit_api_runtime_manager_after_stage891"
} > "$SUITE_PACKET"

echo "cjgui stage891 component commit api demo consumption suite: route_classification=component_commit_api_demo_consumption"
echo "cjgui stage891 component commit api demo consumption suite: suite_packet_path=$SUITE_PACKET"
