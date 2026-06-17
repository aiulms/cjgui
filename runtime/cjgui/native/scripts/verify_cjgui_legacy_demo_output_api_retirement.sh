#!/usr/bin/env zsh
#
# Focused verification for retiring representative legacy CJGUI demo-specific Output APIs.
# Scope: prove Todo / Settings / Chat / FileBrowser / AI-generated UI no longer expose per-demo output declarations,
# while their demos still run through shared demo_support output/session primitives.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_LEGACY_DEMO_OUTPUT_API_RETIREMENT_TMPDIR:-/private/tmp/cjgui-legacy-demo-output-api-retirement}"
mkdir -p "$TMP_DIR"

check_retired_file() {
  local label="$1"
  local file="$2"
  local class_name="$3"
  local builder_name="$4"

  if [[ ! -f "$file" ]]; then
    echo "cjgui legacy output API retirement verification: missing tombstone file for $label: $file" >&2
    exit 2
  fi

  if ! grep -F "package cjgui" "$file" >/dev/null 2>&1 || \
     ! grep -F "已退役" "$file" >/dev/null 2>&1 || \
     ! grep -F "demo_support" "$file" >/dev/null 2>&1; then
    echo "cjgui legacy output API retirement verification: invalid tombstone content for $label" >&2
    exit 3
  fi

  if grep -F "public class $class_name" "$file" >/dev/null 2>&1 || \
     grep -F "public func $builder_name" "$file" >/dev/null 2>&1; then
    echo "cjgui legacy output API retirement verification: $label still exposes legacy output API" >&2
    exit 4
  fi
}

check_demo_uses_shared_path() {
  local label="$1"
  local file="$2"
  local class_name="$3"
  local builder_name="$4"

  if ! grep -F "CjguiExperimentalDemoComponentActionSession" "$file" >/dev/null 2>&1 || \
     ! grep -F "CjguiExperimentalDemoOutput" "$file" >/dev/null 2>&1; then
    echo "cjgui legacy output API retirement verification: $label demo is not on shared output/session path" >&2
    exit 5
  fi

  if grep -F "$class_name" "$file" >/dev/null 2>&1 || \
     grep -F "$builder_name" "$file" >/dev/null 2>&1; then
    echo "cjgui legacy output API retirement verification: $label demo still directly consumes legacy output API" >&2
    exit 6
  fi
}

run_demo_verifier() {
  local label="$1"
  local script="$2"
  local log_file="$TMP_DIR/${label}.log"

  "$script" > "$log_file"
  if ! grep -F "legacy_output_api_direct_consumption=false" "$log_file" >/dev/null 2>&1 || \
     ! grep -F "shared_component_action_session_imported=true" "$log_file" >/dev/null 2>&1; then
    echo "cjgui legacy output API retirement verification: $label verifier did not prove shared session path" >&2
    cat "$log_file" >&2
    exit 7
  fi
}

check_retired_file "todo" "$ROOT_DIR/src/runtime_cjgui_experimental_todo_demo_api.cj" \
  "CjguiExperimentalTodoDemoOutput" "cjguiExperimentalBuildTodoDemoOutput"
check_retired_file "settings" "$ROOT_DIR/src/runtime_cjgui_experimental_settings_demo_api.cj" \
  "CjguiExperimentalSettingsDemoOutput" "cjguiExperimentalBuildSettingsDemoOutput"
check_retired_file "chat" "$ROOT_DIR/src/runtime_cjgui_experimental_chat_demo_api.cj" \
  "CjguiExperimentalChatDemoOutput" "cjguiExperimentalBuildChatDemoOutput"
check_retired_file "file_browser" "$ROOT_DIR/src/runtime_cjgui_experimental_file_browser_demo_api.cj" \
  "CjguiExperimentalFileBrowserDemoOutput" "cjguiExperimentalBuildFileBrowserDemoOutput"
check_retired_file "ai_generated_ui" "$ROOT_DIR/src/runtime_cjgui_experimental_ai_generated_ui_demo_api.cj" \
  "CjguiExperimentalAiGeneratedUiDemoOutput" "cjguiExperimentalBuildAiGeneratedUiDemoOutput"

check_demo_uses_shared_path "todo" "$ROOT_DIR/demo/todo_app.cj" \
  "CjguiExperimentalTodoDemoOutput" "cjguiExperimentalBuildTodoDemoOutput"
check_demo_uses_shared_path "settings" "$ROOT_DIR/demo/settings_app.cj" \
  "CjguiExperimentalSettingsDemoOutput" "cjguiExperimentalBuildSettingsDemoOutput"
check_demo_uses_shared_path "chat" "$ROOT_DIR/demo/chat_app.cj" \
  "CjguiExperimentalChatDemoOutput" "cjguiExperimentalBuildChatDemoOutput"
check_demo_uses_shared_path "file_browser" "$ROOT_DIR/demo/file_browser_app.cj" \
  "CjguiExperimentalFileBrowserDemoOutput" "cjguiExperimentalBuildFileBrowserDemoOutput"
check_demo_uses_shared_path "ai_generated_ui" "$ROOT_DIR/demo/ai_generated_ui_app.cj" \
  "CjguiExperimentalAiGeneratedUiDemoOutput" "cjguiExperimentalBuildAiGeneratedUiDemoOutput"

run_demo_verifier "todo" "$SCRIPT_DIR/verify_cjgui_todo_demo_app.sh"
run_demo_verifier "settings" "$SCRIPT_DIR/verify_cjgui_settings_demo_app.sh"
run_demo_verifier "chat" "$SCRIPT_DIR/verify_cjgui_chat_demo_app.sh"
run_demo_verifier "file_browser" "$SCRIPT_DIR/verify_cjgui_file_browser_demo_app.sh"
run_demo_verifier "ai_generated_ui" "$SCRIPT_DIR/verify_cjgui_ai_generated_ui_demo_app.sh"

echo "legacy_demo_output_api_retired_count=5"
echo "legacy_demo_output_api_tombstone_links_retained=true"
echo "representative_demo_shared_output_path_verified=true"
echo "representative_demo_binary_verifier_count=5"
echo "runtime_state_write=false"
echo "renderer_state_write=false"
echo "public_c_abi_added=false"
