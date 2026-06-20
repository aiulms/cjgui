#!/usr/bin/env zsh
#
# Focused verification for the shared CJGUI demo_support demo run harness.
# Scope: verify representative runnable demos consume the same run/result support API.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_HARNESS_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj"
CHAT_VERIFIER="$SCRIPT_DIR/verify_cjgui_chat_demo_app.sh"
FILE_BROWSER_VERIFIER="$SCRIPT_DIR/verify_cjgui_file_browser_demo_app.sh"
AI_GENERATED_UI_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_demo_app.sh"
TMP_DIR="${CJGUI_SHARED_DEMO_RUN_TMPDIR:-/private/tmp/cjgui-shared-demo-run-harness}"
CHAT_LOG="$TMP_DIR/chat.log"
FILE_BROWSER_LOG="$TMP_DIR/file-browser.log"
AI_GENERATED_UI_LOG="$TMP_DIR/ai-generated-ui.log"

mkdir -p "$TMP_DIR"
: > "$CHAT_LOG"
: > "$FILE_BROWSER_LOG"
: > "$AI_GENERATED_UI_LOG"

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

if [[ ! -f "$RUN_HARNESS_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing run harness source $RUN_HARNESS_SRC" >&2
  exit 2
fi

if ! grep -F "public class CjguiExperimentalDemoRunResult" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoRunHarness" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "notPublished" "$RUN_HARNESS_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected run harness declarations" >&2
  exit 3
fi

CJGUI_CHAT_DEMO_TMPDIR="$TMP_DIR/chat-tmp" "$CHAT_VERIFIER" > "$CHAT_LOG"
CJGUI_FILE_BROWSER_DEMO_TMPDIR="$TMP_DIR/file-browser-tmp" "$FILE_BROWSER_VERIFIER" > "$FILE_BROWSER_LOG"
CJGUI_AI_GENERATED_UI_DEMO_TMPDIR="$TMP_DIR/ai-generated-ui-tmp" "$AI_GENERATED_UI_VERIFIER" > "$AI_GENERATED_UI_LOG"

require_line "chat_shared_run_harness_imported=true" "$CHAT_LOG"
require_line "chat_shared_run_harness=CjguiExperimentalDemoRunHarness" "$CHAT_LOG"
require_line "chat_shared_run_result=CjguiExperimentalDemoRunResult" "$CHAT_LOG"
require_line "chat_shared_run_readback=true" "$CHAT_LOG"
require_line "chat_shared_run_not_published=true" "$CHAT_LOG"
require_line "file_browser_shared_run_harness_imported=true" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_run_harness=CjguiExperimentalDemoRunHarness" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_run_result=CjguiExperimentalDemoRunResult" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_run_readback=true" "$FILE_BROWSER_LOG"
require_line "file_browser_shared_run_not_published=true" "$FILE_BROWSER_LOG"
require_line "ai_generated_ui_shared_run_harness_imported=true" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_run_harness=CjguiExperimentalDemoRunHarness" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_run_result=CjguiExperimentalDemoRunResult" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_run_readback=true" "$AI_GENERATED_UI_LOG"
require_line "ai_generated_ui_shared_run_not_published=true" "$AI_GENERATED_UI_LOG"

echo "cjgui_shared_demo_run_harness_verified=true"
echo "cjgui_shared_demo_run_harness=CjguiExperimentalDemoRunHarness"
echo "cjgui_shared_demo_run_result=CjguiExperimentalDemoRunResult"
echo "cjgui_shared_demo_run_demo_count=3"
echo "cjgui_shared_demo_run_demos=chat,file_browser,ai_generated_ui"
echo "cjgui_shared_demo_run_binary_execution=true"
echo "cjgui_shared_demo_run_readback=true"
echo "cjgui_shared_demo_run_not_published=true"
echo "cjgui_shared_demo_run_runtime_state_write=false"
echo "cjgui_shared_demo_run_renderer_state_write=false"
echo "cjgui_shared_demo_run_public_c_abi_added=false"
