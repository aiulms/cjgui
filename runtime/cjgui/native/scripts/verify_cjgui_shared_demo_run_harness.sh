#!/usr/bin/env zsh
#
# Focused verification for the shared CJGUI demo_support demo run harness.
# Scope: verify representative runnable demos consume the same run/result support API.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_HARNESS_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj"
TODO_DEMO_SRC="$ROOT_DIR/demo/todo_app.cj"
SETTINGS_DEMO_SRC="$ROOT_DIR/demo/settings_app.cj"
CHAT_DEMO_SRC="$ROOT_DIR/demo/chat_app.cj"
FILE_BROWSER_DEMO_SRC="$ROOT_DIR/demo/file_browser_app.cj"
AI_GENERATED_UI_DEMO_SRC="$ROOT_DIR/demo/ai_generated_ui_app.cj"
SHARED_DEMO_HARNESS_SRC="$ROOT_DIR/demo/shared_demo_harness_app.cj"
SHARED_MULTI_DEMO_HARNESS_SRC="$ROOT_DIR/demo/shared_multi_demo_harness_app.cj"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_SRC="$ROOT_DIR/demo/shared_layout_style_input_focus_contract_app.cj"
AI_GENERATED_UI_SHARED_CONTRACT_SRC="$ROOT_DIR/demo/ai_generated_ui_shared_contract_app.cj"
REUSABLE_COMPONENT_CONTRACT_SRC="$ROOT_DIR/demo/reusable_component_contract_app.cj"
TODO_VERIFIER="$SCRIPT_DIR/verify_cjgui_todo_demo_app.sh"
SETTINGS_VERIFIER="$SCRIPT_DIR/verify_cjgui_settings_demo_app.sh"
CHAT_VERIFIER="$SCRIPT_DIR/verify_cjgui_chat_demo_app.sh"
FILE_BROWSER_VERIFIER="$SCRIPT_DIR/verify_cjgui_file_browser_demo_app.sh"
AI_GENERATED_UI_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_demo_app.sh"
SHARED_DEMO_HARNESS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_demo_harness_app.sh"
SHARED_MULTI_DEMO_HARNESS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_multi_demo_harness_app.sh"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_layout_style_input_focus_contract_app.sh"
AI_GENERATED_UI_SHARED_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_shared_contract_app.sh"
REUSABLE_COMPONENT_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_reusable_component_contract_app.sh"
TMP_DIR="${CJGUI_SHARED_DEMO_RUN_TMPDIR:-/private/tmp/cjgui-shared-demo-run-harness}"
TODO_LOG="$TMP_DIR/todo.log"
SETTINGS_LOG="$TMP_DIR/settings.log"
CHAT_LOG="$TMP_DIR/chat.log"
FILE_BROWSER_LOG="$TMP_DIR/file-browser.log"
AI_GENERATED_UI_LOG="$TMP_DIR/ai-generated-ui.log"
SHARED_DEMO_HARNESS_LOG="$TMP_DIR/shared-demo-harness.log"
SHARED_MULTI_DEMO_HARNESS_LOG="$TMP_DIR/shared-multi-demo-harness.log"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG="$TMP_DIR/shared-layout-style-input-focus.log"
AI_GENERATED_UI_SHARED_CONTRACT_LOG="$TMP_DIR/ai-generated-ui-shared-contract.log"
REUSABLE_COMPONENT_CONTRACT_LOG="$TMP_DIR/reusable-component-contract.log"

mkdir -p "$TMP_DIR"
: > "$TODO_LOG"
: > "$SETTINGS_LOG"
: > "$CHAT_LOG"
: > "$FILE_BROWSER_LOG"
: > "$AI_GENERATED_UI_LOG"
: > "$SHARED_DEMO_HARNESS_LOG"
: > "$SHARED_MULTI_DEMO_HARNESS_LOG"
: > "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG"
: > "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
: > "$REUSABLE_COMPONENT_CONTRACT_LOG"

require_line() {
  local expected="$1"
  local log_file="$2"
  if ! grep -F "$expected" "$log_file" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: missing line '$expected' in $log_file" >&2
    echo "cjgui shared demo run harness verification: full log follows" >&2
    cat "$log_file" >&2
    exit 10
  fi
}

require_run_harness_lines() {
  local prefix="$1"
  local log_file="$2"
  require_line "${prefix}_shared_run_harness_imported=true" "$log_file"
  require_line "${prefix}_shared_run_harness=CjguiExperimentalDemoRunHarness" "$log_file"
  require_line "${prefix}_shared_run_result=CjguiExperimentalDemoRunResult" "$log_file"
  require_line "${prefix}_shared_run_readback=true" "$log_file"
  require_line "${prefix}_shared_run_not_published=true" "$log_file"
}

if [[ ! -f "$RUN_HARNESS_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing run harness source $RUN_HARNESS_SRC" >&2
  exit 2
fi

if ! grep -F "public class CjguiExperimentalDemoRunResult" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoRunHarness" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishCommittedSessionRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoComponentActionSession" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "notPublished" "$RUN_HARNESS_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected run harness declarations" >&2
  exit 3
fi

for demo_src in \
  "$TODO_DEMO_SRC" \
  "$SETTINGS_DEMO_SRC" \
  "$CHAT_DEMO_SRC" \
  "$FILE_BROWSER_DEMO_SRC" \
  "$AI_GENERATED_UI_DEMO_SRC" \
  "$SHARED_DEMO_HARNESS_SRC" \
  "$SHARED_MULTI_DEMO_HARNESS_SRC" \
  "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_SRC" \
  "$AI_GENERATED_UI_SHARED_CONTRACT_SRC" \
  "$REUSABLE_COMPONENT_CONTRACT_SRC"; do
  if grep -F "func buildRunResult(" "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local buildRunResult wrapper remains in $demo_src" >&2
    exit 4
  fi
done

CJGUI_TODO_DEMO_TMPDIR="$TMP_DIR/todo-tmp" "$TODO_VERIFIER" > "$TODO_LOG"
CJGUI_SETTINGS_DEMO_TMPDIR="$TMP_DIR/settings-tmp" "$SETTINGS_VERIFIER" > "$SETTINGS_LOG"
CJGUI_CHAT_DEMO_TMPDIR="$TMP_DIR/chat-tmp" "$CHAT_VERIFIER" > "$CHAT_LOG"
CJGUI_FILE_BROWSER_DEMO_TMPDIR="$TMP_DIR/file-browser-tmp" "$FILE_BROWSER_VERIFIER" > "$FILE_BROWSER_LOG"
CJGUI_AI_GENERATED_UI_DEMO_TMPDIR="$TMP_DIR/ai-generated-ui-tmp" "$AI_GENERATED_UI_VERIFIER" > "$AI_GENERATED_UI_LOG"
CJGUI_SHARED_DEMO_HARNESS_TMPDIR="$TMP_DIR/shared-demo-harness-tmp" "$SHARED_DEMO_HARNESS_VERIFIER" > "$SHARED_DEMO_HARNESS_LOG"
CJGUI_SHARED_MULTI_DEMO_HARNESS_TMPDIR="$TMP_DIR/shared-multi-demo-harness-tmp" "$SHARED_MULTI_DEMO_HARNESS_VERIFIER" > "$SHARED_MULTI_DEMO_HARNESS_LOG"
CJGUI_SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_TMPDIR="$TMP_DIR/shared-layout-style-input-focus-tmp" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_VERIFIER" > "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG"
CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_TMPDIR="$TMP_DIR/ai-generated-ui-shared-contract-tmp" "$AI_GENERATED_UI_SHARED_CONTRACT_VERIFIER" > "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
CJGUI_REUSABLE_COMPONENT_CONTRACT_TMPDIR="$TMP_DIR/reusable-component-contract-tmp" "$REUSABLE_COMPONENT_CONTRACT_VERIFIER" > "$REUSABLE_COMPONENT_CONTRACT_LOG"

require_run_harness_lines "todo" "$TODO_LOG"
require_run_harness_lines "settings" "$SETTINGS_LOG"
require_run_harness_lines "chat" "$CHAT_LOG"
require_run_harness_lines "file_browser" "$FILE_BROWSER_LOG"
require_run_harness_lines "ai_generated_ui" "$AI_GENERATED_UI_LOG"
require_run_harness_lines "shared_demo_harness" "$SHARED_DEMO_HARNESS_LOG"
require_run_harness_lines "shared_multi_demo_harness" "$SHARED_MULTI_DEMO_HARNESS_LOG"
require_run_harness_lines "shared_layout_style_input_focus_contract" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG"
require_run_harness_lines "ai_generated_ui_shared_contract" "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
require_run_harness_lines "reusable_component_contract" "$REUSABLE_COMPONENT_CONTRACT_LOG"

echo "cjgui_shared_demo_run_harness_verified=true"
echo "cjgui_shared_demo_run_harness=CjguiExperimentalDemoRunHarness"
echo "cjgui_shared_demo_run_result=CjguiExperimentalDemoRunResult"
echo "cjgui_shared_demo_run_demo_count=10"
echo "cjgui_shared_demo_run_demos=todo,settings,chat,file_browser,ai_generated_ui,shared_demo_harness,shared_multi_demo_harness,shared_layout_style_input_focus_contract,ai_generated_ui_shared_contract,reusable_component_contract"
echo "cjgui_shared_demo_run_binary_execution=true"
echo "cjgui_shared_demo_run_readback=true"
echo "cjgui_shared_demo_run_not_published=true"
echo "cjgui_shared_demo_run_harness_boilerplate_reduced=true"
echo "cjgui_shared_demo_run_session_api=finishCommittedSessionRun"
echo "cjgui_shared_demo_run_runtime_state_write=false"
echo "cjgui_shared_demo_run_renderer_state_write=false"
echo "cjgui_shared_demo_run_public_c_abi_added=false"
