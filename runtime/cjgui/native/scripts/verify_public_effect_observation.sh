#!/usr/bin/env zsh
# One normal generated-panel window plus the exported AF_UNIX client: accepted
# blur request, committed transparent-root fallback, recovery and EFFECTS delta.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/generated_panel_consumer"
OUTPUT_DIR="${CJGUI_PUBLIC_EFFECT_TMPDIR:-/private/tmp/cjgui-public-effect}"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
source "$SCRIPT_DIR/lib_cjgui_instance.sh"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
ROUND_DIR="$WORK/round-app"
GATE="$WORK/release-fallback"
LOG="$WORK/app.log"
mkdir -p "$WORK"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" \
  "CJGUICollaborationStarter" "Effect${RUN_TAG}" "org.example.cjgui.collaboration-starter"
ROUND_EXEC="$ROUND_DIR/target/release/CJGUICollaborationStarterEffect${RUN_TAG}.app/Contents/MacOS/CJGUICollaborationStarterEffect${RUN_TAG}"
APP_PID=""
DESCRIPTOR=""
cleanup() {
  cjgui_terminate_owned "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || true
}
trap cleanup EXIT

STARTED="$(date +%s)"
( cd "$ROUND_DIR" && nohup zsh run.sh --verify-effect-fallback "$GATE" \
    --instance-token "$RUN_TAG" > "$LOG" 2>&1 & )
DESCRIPTOR="$(cjgui_wait_descriptor "$LOG" "CJGUI_COLLABORATION_READY DESCRIPTOR_PATH" 120)"
[[ -f "$DESCRIPTOR" ]] || { cat "$LOG"; exit 1; }
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$STARTED")"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR"

python3 "$APP_DIR/verify_public_effect_observation.py" "$DESCRIPTOR" "$GATE"
grep 'CJGUI_EFFECT_PROBE phase=' "$LOG" || true
print -r -- "CJGUI_PUBLIC_EFFECT_ARTIFACT work=$WORK descriptor=$DESCRIPTOR appPid=$APP_PID"
