#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_AND_RUN="$ROOT_DIR/scripts/build_and_run.sh"
LOG="${CJGUI_VERIFY_LOG:-/tmp/cjgui-p1-auto-close-verify.log}"

if [ ! -x "$BUILD_AND_RUN" ]; then
  echo "cjgui verify: missing executable: $BUILD_AND_RUN" >&2
  exit 1
fi

rm -f "$LOG"

echo "cjgui verify: running auto-close smoke"
echo "cjgui verify: log: $LOG"

set +e
CJGUI_AUTOCLOSE_SECONDS=1 "$BUILD_AND_RUN" 2>&1 | tee "$LOG"
pipeline_status=("${PIPESTATUS[@]}")
set -e

run_status="${pipeline_status[0]}"
tee_status="${pipeline_status[1]}"

if [ "$run_status" -ne 0 ]; then
  echo "cjgui verify: build/run failed with exit code $run_status" >&2
  echo "cjgui verify: log: $LOG" >&2
  exit "$run_status"
fi

if [ "$tee_status" -ne 0 ]; then
  echo "cjgui verify: tee failed with exit code $tee_status" >&2
  exit "$tee_status"
fi

expected_logs=(
  "cjgui: using SDKROOT="
  "cjgui: bridge init"
  "cjgui: capability check: metal device ok"
  "cjgui: capability check: command queue ok"
  "cjgui: window created"
  "cjgui: metal setup complete"
  "cjgui: first frame rendered"
  "cjgui: frame metadata:"
  "index=1"
  "drawable="
  "scale="
  "pixel_format=BGRA8Unorm"
  "clear_color="
  "submitted=true"
  "committed=unknown"
  "attempts=1"
  "success=true"
  "degraded=none"
  "cjgui: metal readback:"
  "requested=true"
  "command_buffer_completed=true"
  "source=clear_color_probe"
  "clear_color_match=true"
  "cjgui: metal readback: success=true degraded=none"
  "cjgui: post close request"
  "cjgui: main-thread drain"
  "cjgui: close requested"
  "cjgui: destroy complete"
  "cjgui: event loop exited"
  "Cangjie: cjgui_app_run returned 0"
)

missing=0
for needle in "${expected_logs[@]}"; do
  if ! grep -F "$needle" "$LOG" >/dev/null; then
    echo "missing expected log: $needle" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "cjgui verify: auto-close log assertions failed" >&2
  echo "cjgui verify: log: $LOG" >&2
  exit 1
fi

echo "cjgui verify: auto-close log assertions passed"
echo "cjgui verify: this is not user-visible window verification"
