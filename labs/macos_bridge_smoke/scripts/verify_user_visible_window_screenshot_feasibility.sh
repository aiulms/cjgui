#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_AND_RUN="$ROOT_DIR/scripts/build_and_run.sh"
LOG_PATH="${CJGUI_SCREENSHOT_FEASIBILITY_LOG:-/tmp/cjgui-p1-user-visible-window-screenshot-feasibility.log}"
PROBE_ERR_PATH="${CJGUI_SCREENSHOT_FEASIBILITY_PROBE_ERR:-/tmp/cjgui-p1-user-visible-window-screenshot-feasibility.err}"
READY_TIMEOUT_SECONDS="${CJGUI_SCREENSHOT_FEASIBILITY_READY_TIMEOUT_SECONDS:-10}"
AUTOCLOSE_SECONDS="${CJGUI_SCREENSHOT_FEASIBILITY_AUTOCLOSE_SECONDS:-5}"

SMOKE_PID=""

log_line() {
  echo "$1" | tee -a "$LOG_PATH"
}

cleanup() {
  if [[ -n "${SMOKE_PID:-}" ]] && kill -0 "$SMOKE_PID" 2>/dev/null; then
    kill "$SMOKE_PID" 2>/dev/null || true
    wait "$SMOKE_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT

emit_summary() {
  local requested="$1"
  local image_created="$2"
  local success="$3"
  local reason="$4"

  log_line "cjgui screenshot feasibility: requested=$requested"
  log_line "cjgui screenshot feasibility: image_created=$image_created"
  log_line "cjgui screenshot feasibility: success=$success reason=$reason"
}

wait_for_readiness() {
  local deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
  local needles=(
    "cjgui: window created"
    "cjgui: metal setup complete"
    "cjgui: first frame rendered"
  )

  while (( SECONDS < deadline )); do
    local missing=0
    local needle
    for needle in "${needles[@]}"; do
      if ! grep -F "$needle" "$LOG_PATH" >/dev/null 2>&1; then
        missing=1
        break
      fi
    done

    if [[ "$missing" -eq 0 ]]; then
      return 0
    fi

    if [[ -n "$SMOKE_PID" ]] && ! kill -0 "$SMOKE_PID" 2>/dev/null; then
      break
    fi

    sleep 0.1
  done

  return 1
}

classify_capture_failure() {
  local detail
  detail="$(tr '[:upper:]' '[:lower:]' < "$PROBE_ERR_PATH" 2>/dev/null || true)"

  if [[ "$detail" == *"could not create image from display"* ]]; then
    echo "display_unavailable"
  elif [[ "$detail" == *"screen recording"* ]] || \
       [[ "$detail" == *"privacy"* ]] || \
       [[ "$detail" == *"permission"* ]] || \
       [[ "$detail" == *"not authorized"* ]] || \
       [[ "$detail" == *"denied"* ]] || \
       [[ "$detail" == *"not allowed"* ]]; then
    echo "permission_denied"
  elif [[ "$detail" == *"no display"* ]] || \
       [[ "$detail" == *"display unavailable"* ]] || \
       [[ "$detail" == *"cannot create image from display"* ]]; then
    echo "display_unavailable"
  elif [[ "$detail" == *"window not found"* ]]; then
    echo "window_not_found"
  elif [[ "$detail" == *"window not visible"* ]]; then
    echo "window_not_visible"
  elif [[ -n "$detail" ]]; then
    echo "capture_failed"
  else
    echo "unknown"
  fi
}

run_screenshot_probe() {
  : > "$PROBE_ERR_PATH"

  log_line "cjgui screenshot feasibility: requested=true"

  if ! command -v osascript >/dev/null 2>&1; then
    log_line "cjgui screenshot feasibility: image_created=false"
    log_line "cjgui screenshot feasibility: success=false reason=capture_failed"
    return 0
  fi

  set +e
  osascript -l JavaScript \
    -e 'ObjC.import("CoreGraphics"); var image = $.CGWindowListCreateImage($.CGRectInfinite, $.kCGWindowListOptionOnScreenOnly, 0, $.kCGWindowImageDefault); if (image) { "image_created"; } else { throw new Error("nil image"); }' \
    >/dev/null 2>"$PROBE_ERR_PATH"
  local status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    log_line "cjgui screenshot feasibility: image_created=true"
    log_line "cjgui screenshot feasibility: success=true reason=none"
  else
    local reason
    reason="$(classify_capture_failure)"
    log_line "cjgui screenshot feasibility: image_created=false"
    log_line "cjgui screenshot feasibility: success=false reason=$reason"
  fi
}

rm -f "$LOG_PATH" "$PROBE_ERR_PATH"
touch "$LOG_PATH" "$PROBE_ERR_PATH"

log_line "cjgui screenshot feasibility: log=$LOG_PATH"
log_line "cjgui screenshot feasibility: probe_error_log=$PROBE_ERR_PATH"

CJGUI_AUTOCLOSE_SECONDS="$AUTOCLOSE_SECONDS" "$BUILD_AND_RUN" > >(tee -a "$LOG_PATH") 2>&1 &
SMOKE_PID=$!

if ! wait_for_readiness; then
  emit_summary "false" "false" "false" "render_not_ready"
  exit 0
fi

run_screenshot_probe

set +e
wait "$SMOKE_PID"
SMOKE_STATUS=$?
set -e
SMOKE_PID=""

if [[ "$SMOKE_STATUS" -ne 0 ]]; then
  log_line "cjgui screenshot feasibility: smoke_exit_status=$SMOKE_STATUS"
fi

exit 0
