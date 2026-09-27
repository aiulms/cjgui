#!/usr/bin/env zsh

# This retains a normal-bundle receipt so an AppKit stop caused by a broken
# standard Quit path cannot be confused with a passing shell process.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/probe/application_command_menu_exit_native_app"
export CJGUI_NATIVE_CLANG_FLAGS_APPEND='-DCJGUI_INTERNAL_TESTING'
RESULT_ROOT="${CJGUI_APPLICATION_COMMAND_MENU_EXIT_NATIVE_RESULTS_DIR:-/private/tmp/cjgui-command-menu-exit-native-runs}"
mkdir -p "$RESULT_ROOT"
RESULT_DIRECTORY="$(mktemp -d "$RESULT_ROOT/run.XXXXXX")"
RESULT_PATH="$RESULT_DIRECTORY/result"
RUN_LOG="$RESULT_DIRECTORY/run.log"
MANIFEST="$RESULT_DIRECTORY/manifest.txt"
record_digest() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    print -r -- "$label=$(/usr/bin/shasum -a 256 "$path" | /usr/bin/awk '{print $1}')" >> "$MANIFEST"
  else
    print -r -- "$label=missing:$path" >> "$MANIFEST"
  fi
}
{
  print -r -- "started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  print -r -- "workspace=$RUNTIME_DIR"
  print -r -- 'launch_services=1'
  print -r -- "result_path=$RESULT_PATH"
} > "$MANIFEST"
set +e
OUTPUT="$(CJGUI_USE_LAUNCH_SERVICES=1 zsh "$APP_DIR/run.sh" --result-path "$RESULT_PATH" 2>&1)"
RUN_STATUS=$?
set -e
print -r -- "$OUTPUT" > "$RUN_LOG"
print -r -- "$OUTPUT"
print -r -- "runner_status=$RUN_STATUS" >> "$MANIFEST"
record_digest "source_macos_application_host_sha256" "$RUNTIME_DIR/src/macos_application_host.cj" "$RUNTIME_DIR/src/composable_ui_platform_state.cj"
record_digest "source_composable_ui_window_sha256" "$RUNTIME_DIR/src/composable_ui_window.cj"
record_digest "source_renderer_session_sha256" "$RUNTIME_DIR/src/runtime_renderer_session.cj"
record_digest "source_native_renderer_sha256" "$RUNTIME_DIR/native/cjgui_internal_renderer.m"
record_digest "source_probe_sha256" "$APP_DIR/src/main.cj"
record_digest "bundle_binary_sha256" "$APP_DIR/target/release/CJGUIApplicationCommandMenuExitNativeProbe.app/Contents/MacOS/CJGUIApplicationCommandMenuExitNativeProbe"
if [[ -f "$RESULT_PATH" ]]; then
  print -r -- "result_sha256=$(/usr/bin/shasum -a 256 "$RESULT_PATH" | /usr/bin/awk '{print $1}')" >> "$MANIFEST"
else
  print -r -- "result_sha256=missing" >> "$MANIFEST"
fi
if [[ ! -f "$RESULT_PATH" || "$(head -n 1 "$RESULT_PATH")" != 'verdict=passed' ]]; then
  print -u2 -- "cjgui application-exit native probe did not produce a passing LaunchServices receipt (runner_status=$RUN_STATUS artifact_root=$RESULT_DIRECTORY)"
  exit 1
fi
print -r -- "CJGUI_APPLICATION_EXIT_NATIVE_ARTIFACT_ROOT=$RESULT_DIRECTORY"
cat "$RESULT_PATH"
