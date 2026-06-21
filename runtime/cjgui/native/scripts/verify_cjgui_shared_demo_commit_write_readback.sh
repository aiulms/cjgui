#!/usr/bin/env zsh
#
# Focused verification for the shared CJGUI demo_support owner-local commit primitive.
# Scope: verify multiple independent demo apps consume the same commit/readback support API.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMIT_SESSION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj"
TODO_VERIFIER="$SCRIPT_DIR/verify_cjgui_todo_demo_app.sh"
SETTINGS_VERIFIER="$SCRIPT_DIR/verify_cjgui_settings_demo_app.sh"
CHAT_VERIFIER="$SCRIPT_DIR/verify_cjgui_chat_demo_app.sh"
FILE_BROWSER_VERIFIER="$SCRIPT_DIR/verify_cjgui_file_browser_demo_app.sh"
AI_GENERATED_UI_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_demo_app.sh"
SHARED_DEMO_HARNESS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_demo_harness_app.sh"
SHARED_MULTI_DEMO_HARNESS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_multi_demo_harness_app.sh"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_layout_style_input_focus_contract_app.sh"
AI_GENERATED_UI_SHARED_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_shared_contract_app.sh"
REUSABLE_COMPONENT_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_reusable_component_contract_app.sh"
TMP_DIR="${CJGUI_SHARED_DEMO_COMMIT_TMPDIR:-/private/tmp/cjgui-shared-demo-commit-write-readback}"
TODO_LOG="$TMP_DIR/todo.log"
SETTINGS_LOG="$TMP_DIR/settings.log"
CHAT_LOG="$TMP_DIR/chat.log"
FILE_BROWSER_LOG="$TMP_DIR/file-browser.log"
AI_GENERATED_UI_LOG="$TMP_DIR/ai-generated-ui.log"
SHARED_DEMO_HARNESS_LOG="$TMP_DIR/shared-demo-harness.log"
SHARED_MULTI_DEMO_HARNESS_LOG="$TMP_DIR/shared-multi-demo-harness.log"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG="$TMP_DIR/shared-layout-style-input-focus-contract.log"
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
: > "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG"
: > "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
: > "$REUSABLE_COMPONENT_CONTRACT_LOG"

require_line() {
  local expected="$1"
  local log_file="$2"
  if ! grep -F "$expected" "$log_file" >/dev/null 2>&1; then
    echo "cjgui shared demo commit verification: missing line '$expected' in $log_file" >&2
    echo "cjgui shared demo commit verification: full log follows" >&2
    cat "$log_file" >&2
    exit 10
  fi
}

reject_line() {
  local unexpected="$1"
  local log_file="$2"
  if grep -F "$unexpected" "$log_file" >/dev/null 2>&1; then
    echo "cjgui shared demo commit verification: unexpected legacy evidence line '$unexpected' in $log_file" >&2
    echo "cjgui shared demo commit verification: full log follows" >&2
    cat "$log_file" >&2
    exit 11
  fi
}

require_commit_harness_evidence() {
  local prefix="$1"
  local log_file="$2"
  require_line "${prefix}_shared_commit_harness_internal_primitive_present=true" "$log_file"
  require_line "${prefix}_shared_commit_harness_internal_primitive_name=CjguiExperimentalDemoOwnerLocalCommitSession" "$log_file"
  reject_line "${prefix}_shared_commit_session_imported=true" "$log_file"
  reject_line "${prefix}_shared_commit_session_name=CjguiExperimentalDemoOwnerLocalCommitSession" "$log_file"
}

if [[ ! -f "$COMMIT_SESSION_SRC" ]]; then
  echo "cjgui shared demo commit verification: missing commit session source $COMMIT_SESSION_SRC" >&2
  exit 2
fi

if ! grep -F "public class CjguiExperimentalDemoCommitResult" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoCommitActionRoute" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoCommitActionRouteCatalog" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoOwnerLocalCommitSession" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoCommitHarness" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoCommitReadbackExpectation" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoCommitReadbackAssertion" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func commitComponentAction" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func commitComponentActionRoute" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func resultMatches" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func resultMatchesRoute" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func assertCommitReadbackRoute" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func isSatisfied" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func componentIdValue" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func actionValue" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func routeValue" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "not_published" "$COMMIT_SESSION_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo commit verification: missing expected commit support declarations" >&2
  exit 3
fi

commit_action_route_usage_count="$(grep -R "commitHarness.commitComponentActionRoute" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
commit_readback_assertion_usage_count="$(grep -R "commitHarness.assertCommitReadbackRoute" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
commit_readback_expectation_usage_count="$(grep -R "CjguiExperimentalDemoCommitReadbackExpectation(" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
commit_action_route_match_direct_usage_count="$({ grep -R "commitHarness.resultMatchesRoute" "$ROOT_DIR/demo" || true; } | wc -l | tr -d ' ')"
commit_action_route_catalog_usage_count="$(grep -R "commitRouteCatalog\\." "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
if [ "$commit_action_route_usage_count" -lt 10 ] || \
   [ "$commit_readback_assertion_usage_count" -lt 10 ] || \
   [ "$commit_readback_expectation_usage_count" -lt 10 ] || \
   [ "$commit_action_route_catalog_usage_count" -lt 10 ]; then
  echo "cjgui shared demo commit verification: commit readback assertion contract is not shared across expected demos" >&2
  exit 4
fi

if [ "$commit_action_route_match_direct_usage_count" -ne 0 ]; then
  echo "cjgui shared demo commit verification: demo-local direct commit resultMatchesRoute call remains" >&2
  exit 4
fi

if grep -R "commitHarness.commitComponentAction(" "$ROOT_DIR/demo" >/dev/null 2>&1; then
  echo "cjgui shared demo commit verification: demo-local direct commit component/action string call remains" >&2
  exit 4
fi

CJGUI_TODO_DEMO_TMPDIR="$TMP_DIR/todo-tmp" "$TODO_VERIFIER" > "$TODO_LOG"
CJGUI_SETTINGS_DEMO_TMPDIR="$TMP_DIR/settings-tmp" "$SETTINGS_VERIFIER" > "$SETTINGS_LOG"
CJGUI_CHAT_DEMO_TMPDIR="$TMP_DIR/chat-tmp" "$CHAT_VERIFIER" > "$CHAT_LOG"
CJGUI_FILE_BROWSER_DEMO_TMPDIR="$TMP_DIR/file-browser-tmp" "$FILE_BROWSER_VERIFIER" > "$FILE_BROWSER_LOG"
CJGUI_AI_GENERATED_UI_DEMO_TMPDIR="$TMP_DIR/ai-generated-ui-tmp" "$AI_GENERATED_UI_VERIFIER" > "$AI_GENERATED_UI_LOG"
CJGUI_SHARED_DEMO_HARNESS_TMPDIR="$TMP_DIR/shared-demo-harness-tmp" "$SHARED_DEMO_HARNESS_VERIFIER" > "$SHARED_DEMO_HARNESS_LOG"
CJGUI_SHARED_MULTI_DEMO_HARNESS_TMPDIR="$TMP_DIR/shared-multi-demo-harness-tmp" "$SHARED_MULTI_DEMO_HARNESS_VERIFIER" > "$SHARED_MULTI_DEMO_HARNESS_LOG"
CJGUI_SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_TMPDIR="$TMP_DIR/shared-layout-style-input-focus-contract-tmp" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_VERIFIER" > "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG"
CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_TMPDIR="$TMP_DIR/ai-generated-ui-shared-contract-tmp" "$AI_GENERATED_UI_SHARED_CONTRACT_VERIFIER" > "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
CJGUI_REUSABLE_COMPONENT_CONTRACT_TMPDIR="$TMP_DIR/reusable-component-contract-tmp" "$REUSABLE_COMPONENT_CONTRACT_VERIFIER" > "$REUSABLE_COMPONENT_CONTRACT_LOG"

require_commit_harness_evidence "todo" "$TODO_LOG"
require_line "todo_shared_commit_harness_imported=true" "$TODO_LOG"
require_line "todo_shared_commit_readback=true" "$TODO_LOG"
require_line "todo_shared_commit_not_published=true" "$TODO_LOG"
require_commit_harness_evidence "settings" "$SETTINGS_LOG"
require_line "settings_shared_commit_harness_imported=true" "$SETTINGS_LOG"
require_line "settings_shared_commit_readback=true" "$SETTINGS_LOG"
require_line "settings_shared_commit_not_published=true" "$SETTINGS_LOG"
require_commit_harness_evidence "chat" "$CHAT_LOG"
require_line "chat_shared_commit_harness_imported=true" "$CHAT_LOG"
require_line "chat_shared_commit_readback=true" "$CHAT_LOG"
require_line "chat_shared_commit_not_published=true" "$CHAT_LOG"
require_commit_harness_evidence "file_browser" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_commit_harness_imported=true" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_commit_readback=true" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_commit_not_published=true" "$FILE_BROWSER_LOG"
require_commit_harness_evidence "ai_generated_ui" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_commit_harness_imported=true" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_commit_readback=true" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_commit_not_published=true" "$AI_GENERATED_UI_LOG"
require_commit_harness_evidence "shared_demo_harness" "$SHARED_DEMO_HARNESS_LOG"
require_line "shared_demo_harness_shared_commit_harness_imported=true" "$SHARED_DEMO_HARNESS_LOG"
require_line "shared_demo_harness_shared_commit_readback=true" "$SHARED_DEMO_HARNESS_LOG"
require_line "shared_demo_harness_shared_commit_not_published=true" "$SHARED_DEMO_HARNESS_LOG"
require_commit_harness_evidence "shared_multi_demo_harness" "$SHARED_MULTI_DEMO_HARNESS_LOG"
require_line "shared_multi_demo_harness_shared_commit_harness_imported=true" "$SHARED_MULTI_DEMO_HARNESS_LOG"
require_line "shared_multi_demo_harness_shared_commit_readback=true" "$SHARED_MULTI_DEMO_HARNESS_LOG"
require_line "shared_multi_demo_harness_shared_commit_not_published=true" "$SHARED_MULTI_DEMO_HARNESS_LOG"
require_commit_harness_evidence "shared_layout_style_input_focus_contract" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG"
require_line "shared_layout_style_input_focus_contract_shared_commit_harness_imported=true" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG"
require_line "shared_layout_style_input_focus_contract_shared_commit_readback=true" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG"
require_line "shared_layout_style_input_focus_contract_shared_commit_not_published=true" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_LOG"
require_commit_harness_evidence "ai_generated_ui_shared_contract" "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
require_line "ai_generated_ui_shared_contract_shared_commit_harness_imported=true" "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
require_line "ai_generated_ui_shared_contract_shared_commit_readback=true" "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
require_line "ai_generated_ui_shared_contract_shared_commit_not_published=true" "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
require_commit_harness_evidence "reusable_component_contract" "$REUSABLE_COMPONENT_CONTRACT_LOG"
require_line "reusable_component_contract_shared_commit_harness_imported=true" "$REUSABLE_COMPONENT_CONTRACT_LOG"
require_line "reusable_component_contract_shared_commit_readback=true" "$REUSABLE_COMPONENT_CONTRACT_LOG"
require_line "reusable_component_contract_shared_commit_not_published=true" "$REUSABLE_COMPONENT_CONTRACT_LOG"

echo "cjgui_shared_demo_commit_write_readback_verified=true"
echo "cjgui_shared_demo_commit_harness_internal_primitive=CjguiExperimentalDemoOwnerLocalCommitSession"
echo "cjgui_shared_demo_commit_harness=CjguiExperimentalDemoCommitHarness"
echo "cjgui_shared_demo_commit_result=CjguiExperimentalDemoCommitResult"
echo "cjgui_shared_demo_commit_readback_expectation=CjguiExperimentalDemoCommitReadbackExpectation"
echo "cjgui_shared_demo_commit_readback_assertion=CjguiExperimentalDemoCommitReadbackAssertion"
echo "cjgui_shared_demo_commit_action_route_model=CjguiExperimentalDemoCommitActionRoute"
echo "cjgui_shared_demo_commit_action_route_catalog=CjguiExperimentalDemoCommitActionRouteCatalog"
echo "cjgui_shared_demo_commit_action_route_usage_count=$commit_action_route_usage_count"
echo "cjgui_shared_demo_commit_readback_assertion_usage_count=$commit_readback_assertion_usage_count"
echo "cjgui_shared_demo_commit_readback_expectation_usage_count=$commit_readback_expectation_usage_count"
echo "cjgui_shared_demo_direct_commit_result_matches_route_call_retired=true"
echo "cjgui_shared_demo_commit_action_route_catalog_usage_count=$commit_action_route_catalog_usage_count"
echo "cjgui_shared_demo_direct_commit_component_action_string_call_retired=true"
echo "cjgui_shared_demo_commit_demo_count=10"
echo "cjgui_shared_demo_commit_demos=todo,settings,chat,file_browser,ai_generated_ui,shared_demo_harness,shared_multi_demo_harness,shared_layout_style_input_focus_contract,ai_generated_ui_shared_contract,reusable_component_contract"
echo "cjgui_shared_demo_commit_demo_output_harness_only=true"
echo "cjgui_shared_demo_commit_runtime_state_write=false"
echo "cjgui_shared_demo_commit_renderer_state_write=false"
echo "cjgui_shared_demo_commit_public_c_abi_added=false"
