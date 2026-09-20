#!/usr/bin/env zsh

# A focused regression for the effective platform-menu projection. The
# controller advances only an unrelated scene label; command identity,
# accepted target, effective focus scope and key-window identity remain fixed.
# The expected result is no NSApp.mainMenu rebuild.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_APP="$RUNTIME_DIR/probe/application_command_menu_native_app"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
RESULT_ROOT="${CJGUI_APPLICATION_COMMAND_MENU_EFFECTIVE_PROJECTION_RESULTS_DIR:-/private/tmp/cjgui-command-menu-effective-projection-runs}"
mkdir -p "$RESULT_ROOT"
RUN_DIRECTORY="$(mktemp -d "$RESULT_ROOT/run.XXXXXX")"
APP_STAGING="$(mktemp -d "$RUNTIME_DIR/probe/.effective-projection-app.XXXXXX")"
RESULT_PATH="$RUN_DIRECTORY/result"
RUN_LOG="$RUN_DIRECTORY/run.log"
MANIFEST="$RUN_DIRECTORY/manifest.txt"

cleanup() {
  if [[ -d "$APP_STAGING" ]]; then rm -rf "$APP_STAGING"; fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' HUP INT TERM

if [[ ! -d "$SDKROOT_PATH" ]]; then
  print -u2 -- "cjgui effective command-menu projection: unavailable SDKROOT=$SDKROOT_PATH"
  exit 2
fi

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export CJGUI_NATIVE_CLANG_FLAGS_APPEND='-DCJGUI_INTERNAL_TESTING'

# Reuse the normal bundled application host and dependency graph, replacing
# only the probe entry point in an exact temporary app directory. This keeps
# the check on the ordinary LaunchServices/AppKit path without editing the
# existing native integration consumer.
ln -s "$SOURCE_APP/cjpm.toml" "$APP_STAGING/cjpm.toml"
ln -s "$SOURCE_APP/cjpm.lock" "$APP_STAGING/cjpm.lock"
ln -s "$SOURCE_APP/cjgui_macos_app.sh" "$APP_STAGING/cjgui_macos_app.sh"
ln -s "$SOURCE_APP/run.sh" "$APP_STAGING/run.sh"
mkdir "$APP_STAGING/src"
cp "$RUNTIME_DIR/probe/application_command_menu_effective_projection_probe.cj" "$APP_STAGING/src/main.cj"

{
  print -r -- "started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  print -r -- "runtime=$RUNTIME_DIR"
  print -r -- "probe=$RUNTIME_DIR/probe/application_command_menu_effective_projection_probe.cj"
  print -r -- "app_staging=$APP_STAGING"
  print -r -- "launch_services=1"
  print -r -- "result_path=$RESULT_PATH"
} > "$MANIFEST"

set +e
OUTPUT="$(CJGUI_USE_LAUNCH_SERVICES=1 zsh "$APP_STAGING/run.sh" --result-path "$RESULT_PATH" 2>&1)"
RUN_STATUS=$?
set -e
print -r -- "$OUTPUT" > "$RUN_LOG"
print -r -- "$OUTPUT"
print -r -- "runner_status=$RUN_STATUS" >> "$MANIFEST"

record_digest() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    print -r -- "$label=$(/usr/bin/shasum -a 256 "$path" | /usr/bin/awk '{print $1}')" >> "$MANIFEST"
  else
    print -r -- "$label=missing:$path" >> "$MANIFEST"
  fi
}
record_digest "source_probe_sha256" "$RUNTIME_DIR/probe/application_command_menu_effective_projection_probe.cj"
record_digest "source_window_sha256" "$RUNTIME_DIR/src/composable_ui_window.cj"
record_digest "source_renderer_session_sha256" "$RUNTIME_DIR/src/runtime_renderer_session.cj"
record_digest "source_native_renderer_sha256" "$RUNTIME_DIR/native/cjgui_internal_renderer.m"
record_digest "source_runner_sha256" "$RUNTIME_DIR/scripts/run_macos_application.sh"
if [[ -f "$RESULT_PATH" ]]; then
  record_digest "result_sha256" "$RESULT_PATH"
  cat "$RESULT_PATH"
else
  print -u2 -- "cjgui effective command-menu projection: missing result (artifact_root=$RUN_DIRECTORY)"
  print -r -- "result_sha256=missing" >> "$MANIFEST"
fi

print -r -- "artifact_root=$RUN_DIRECTORY"
if [[ ! -f "$RESULT_PATH" || "$(head -n 1 "$RESULT_PATH")" != 'verdict=passed' ]]; then
  print -u2 -- "cjgui effective command-menu projection RED: scene-only refresh rebuilt the effective menu or did not produce a normal receipt (artifact_root=$RUN_DIRECTORY)"
  exit 1
fi
print -r -- "CJGUI_COMMAND_MENU_EFFECTIVE_PROJECTION_ARTIFACT_ROOT=$RUN_DIRECTORY"
