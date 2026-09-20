#!/usr/bin/env zsh

# Public normal-application path for image ownership.  The app issues its
# existing private descriptor; this script only uses the generic shared-
# operation client to reject an unauthorized action and apply SET_MARKED on
# resource 7101.  The adaptive consumer projects that durable field into the
# blue/coral PNG declaration and its explicit image version.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/adaptive_layout_public_consumer"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_APPLICATION_IMAGE_PUBLIC_TMPDIR:-/private/tmp/cjgui-application-image-resource-public}"
APP_BUNDLE="$APP_DIR/target/release/AdaptiveLayoutPublicConsumer.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/AdaptiveLayoutPublicConsumer"
APP_LOG="$OUTPUT_DIR/application.stdout.log"
APP_ERR="$OUTPUT_DIR/application.stderr.log"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui application-image public consumer: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi
if [[ ! -f "$CLIENT" ]]; then
  echo "cjgui application-image public consumer: missing generic client" >&2
  exit 2
fi
mkdir -p "$OUTPUT_DIR"
rm -f "$APP_LOG" "$APP_ERR" "$OUTPUT_DIR/manifest"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

(
  cd "$APP_DIR"
  CJGUI_CANGJIE_HOME="$CANGJIE_HOME" CJ_GUI_SDKROOT="$SDKROOT_PATH" zsh ./run.sh --build-only
) >"$OUTPUT_DIR/build.log" 2>&1

if [[ ! -x "$APP_BINARY" ]]; then
  echo 'cjgui application-image public consumer: normal bundle executable missing' >&2
  exit 2
fi

"$APP_BINARY" >"$APP_LOG" 2>"$APP_ERR" &
APP_PID=$!
cleanup() {
  if [[ -n "${APP_PID:-}" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    for _ in {1..30}; do
      kill -0 "$APP_PID" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT HUP INT TERM
if [[ "$APP_PID" == "9726" || "$APP_PID" == "9728" ]]; then
  echo "cjgui application-image public consumer: refused to manage protected PID $APP_PID" >&2
  exit 2
fi

DESCRIPTOR=""
for _ in {1..120}; do
  if [[ -s "$APP_LOG" ]]; then
    DESCRIPTOR="$(sed -n 's/.*ADAPTIVE_LAYOUT_READY DESCRIPTOR_PATH //p' "$APP_LOG" | head -1)"
  fi
  [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]] && break
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo 'cjgui application-image public consumer: app exited before descriptor' >&2
    cat "$APP_LOG" >&2 || true
    cat "$APP_ERR" >&2 || true
    exit 1
  fi
  sleep 0.1
done
if [[ -z "$DESCRIPTOR" || ! -f "$DESCRIPTOR" ]]; then
  echo 'cjgui application-image public consumer: descriptor timeout' >&2
  exit 1
fi

json_value() {
  python3 - "$1" "$2" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
name = sys.argv[2]
for entry in payload.get("entries", []):
    if entry.get("name") == name:
        print(" ".join(str(value) for value in entry.get("values", [])))
        raise SystemExit(0)
raise SystemExit(1)
PY
}

run_client() {
  python3 "$CLIENT" "$DESCRIPTOR" --json "$@"
}

INITIAL_JSON="$OUTPUT_DIR/initial.json"
run_client get >"$INITIAL_JSON"
INITIAL_VERSION="$(json_value "$INITIAL_JSON" VERSION)"
PROGRESS_BEFORE="$OUTPUT_DIR/progress-before.json"
# The normal public consumer owns one window, so use its existing generic
# progress provider.  Target enumeration belongs to CjguiMacosApplication's
# explicit multi-window host and must not be advertised by this host wrapper.
run_client window-progress >"$PROGRESS_BEFORE"
SCENE_BEFORE="$(json_value "$PROGRESS_BEFORE" WINDOW_SCENE_VERSION)"

# SET_TITLE is deliberately not in the issued capability.  Keep its failure
# as evidence rather than treating a generic non-zero status as success.
set +e
run_client invoke "$INITIAL_VERSION" SET_TITLE --target 7101 --arg title=STRING:unauthorized >"$OUTPUT_DIR/unauthorized.json"
UNAUTHORIZED_STATUS=$?
set -e
if [[ "$UNAUTHORIZED_STATUS" -eq 0 ]] || ! rg -q 'unauthorized_action|unauthorized' "$OUTPUT_DIR/unauthorized.json"; then
  echo 'cjgui application-image public consumer: authorization rejection was not observed' >&2
  exit 1
fi

ACCEPTED_JSON="$OUTPUT_DIR/accepted-coral.json"
run_client invoke "$INITIAL_VERSION" SET_MARKED --target 7101 --arg isMarked=BOOLEAN:1 >"$ACCEPTED_JSON"
ACCEPTED_VERSION="$(json_value "$ACCEPTED_JSON" VERSION_AFTER)"
if [[ "$ACCEPTED_VERSION" -le "$INITIAL_VERSION" ]]; then
  echo 'cjgui application-image public consumer: accepted version did not advance' >&2
  exit 1
fi

CORAL_JSON="$OUTPUT_DIR/coral-context.json"
CORAL_PROGRESS="$OUTPUT_DIR/progress-coral.json"
CORAL_SEEN=0
for _ in {1..100}; do
  run_client get >"$CORAL_JSON"
  marked="$(python3 - "$CORAL_JSON" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
for entry in payload.get("entries", []):
    if entry.get("name") == "FIELD" and len(entry.get("values", [])) >= 4:
        values = entry["values"]
        if values[0] == "7101" and values[1] == "isMarked":
            print(values[-1])
            raise SystemExit(0)
print("0")
PY
  )"
  run_client window-progress >"$CORAL_PROGRESS"
  if [[ "$marked" == "1" ]]; then CORAL_SEEN=1; break; fi
  sleep 0.05
done
if [[ "$CORAL_SEEN" -ne 1 ]]; then
  echo 'cjgui application-image public consumer: external accepted state did not reach window owner' >&2
  exit 1
fi
SCENE_CORAL="$(json_value "$CORAL_PROGRESS" WINDOW_SCENE_VERSION)"
if [[ "$SCENE_CORAL" -le "$SCENE_BEFORE" ]]; then
  echo "cjgui application-image public consumer: accepted image did not advance scene before=$SCENE_BEFORE after=$SCENE_CORAL" >&2
  exit 1
fi

BLUE_JSON="$OUTPUT_DIR/accepted-blue.json"
run_client invoke "$ACCEPTED_VERSION" SET_MARKED --target 7101 --arg isMarked=BOOLEAN:0 >"$BLUE_JSON"
BLUE_VERSION="$(json_value "$BLUE_JSON" VERSION_AFTER)"
if [[ "$BLUE_VERSION" -le "$ACCEPTED_VERSION" ]]; then
  echo 'cjgui application-image public consumer: second accepted version did not advance' >&2
  exit 1
fi
BLUE_CONTEXT="$OUTPUT_DIR/blue-context.json"
BLUE_PROGRESS="$OUTPUT_DIR/progress-blue.json"
BLUE_SEEN=0
for _ in {1..100}; do
  run_client get >"$BLUE_CONTEXT"
  run_client window-progress >"$BLUE_PROGRESS"
  marked="$(python3 - "$BLUE_CONTEXT" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
for entry in payload.get("entries", []):
    if entry.get("name") == "FIELD" and len(entry.get("values", [])) >= 4:
        values = entry["values"]
        if values[0] == "7101" and values[1] == "isMarked":
            print(values[-1])
            raise SystemExit(0)
print("1")
PY
  )"
  if [[ "$marked" == "0" ]]; then BLUE_SEEN=1; break; fi
  sleep 0.05
done
if [[ "$BLUE_SEEN" -ne 1 ]]; then
  echo 'cjgui application-image public consumer: second accepted state did not reach window owner' >&2
  exit 1
fi
SCENE_BLUE="$(json_value "$BLUE_PROGRESS" WINDOW_SCENE_VERSION)"
if [[ "$SCENE_BLUE" -le "$SCENE_CORAL" ]]; then
  echo "cjgui application-image public consumer: second image version did not advance scene coral=$SCENE_CORAL blue=$SCENE_BLUE" >&2
  exit 1
fi

# These are emitted by the normal bundle's renderer only after each resource
# has been decoded and committed.  Together with the descriptor-mediated
# state read and scene advancement above, they bind the authorized operation
# to the actual bundle resource reference rather than a controller-local flag.
rg -q 'composable image preparation ready path=.*Resources/composable-beacon-coral\.png' "$APP_ERR"
rg -q 'composable image preparation ready path=.*Resources/composable-beacon\.png' "$APP_ERR"

BLUE_HASH="$(shasum -a 256 "$RUNTIME_DIR/resources/composable-beacon.png" | awk '{print $1}')"
CORAL_HASH="$(shasum -a 256 "$RUNTIME_DIR/resources/composable-beacon-coral.png" | awk '{print $1}')"
BINARY_HASH="$(shasum -a 256 "$APP_BINARY" | awk '{print $1}')"
{
  echo 'format=1'
  echo 'consumer=adaptive_layout_public_consumer'
  echo "app_pid=$APP_PID"
  echo "descriptor=$DESCRIPTOR"
  echo "initial_version=$INITIAL_VERSION"
  echo "accepted_coral_version=$ACCEPTED_VERSION"
  echo "accepted_blue_version=$BLUE_VERSION"
  echo "scene_before=$SCENE_BEFORE"
  echo "scene_coral=$SCENE_CORAL"
  echo "scene_blue=$SCENE_BLUE"
  echo 'bundle_blue_resource_ready=true'
  echo 'bundle_coral_resource_ready=true'
  echo "unauthorized_status=$UNAUTHORIZED_STATUS"
  echo "blue_fixture_sha256=$BLUE_HASH"
  echo "coral_fixture_sha256=$CORAL_HASH"
  echo "binary_sha256=$BINARY_HASH"
  echo "app_log=$APP_LOG"
  echo "app_err=$APP_ERR"
  echo "progress_before=$PROGRESS_BEFORE"
  echo "progress_coral=$CORAL_PROGRESS"
  echo "progress_blue=$BLUE_PROGRESS"
} >"$OUTPUT_DIR/manifest"
echo "CJGUI_APPLICATION_IMAGE_PUBLIC_CONSUMER passed=true initial_version=$INITIAL_VERSION coral_version=$ACCEPTED_VERSION blue_version=$BLUE_VERSION unauthorized_status=$UNAUTHORIZED_STATUS manifest=$OUTPUT_DIR/manifest"
